import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart' show AssetType;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/constants.dart';
import '../paywall/paywall_view.dart';
import 'cleanup_category.dart' show sumBytes;
import 'congratulations_view.dart';

/// Free users can finish a limited number of cleanups after dismissing the
/// paywall, so the first experience ends with real freed space.
class FreeCleanupQuota {
  static const _key = 'v2.freeCleanupsUsed';

  static Future<int> remaining() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_key) ?? 0;
    return (AppConstants.maxFreeDeletes - used).clamp(
      0,
      AppConstants.maxFreeDeletes,
    );
  }

  static Future<void> consume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, (prefs.getInt(_key) ?? 0) + 1);
  }
}

/// Shared "Delete N" pipeline for every cleanup screen:
/// soft paywall → pause scanning → iOS system confirmation → congratulations.
///
/// Returns the identifiers PhotoKit actually deleted (empty when the user
/// cancels at any step).
/// Callers guard against double activation themselves; no global lock is kept,
/// so an abandoned flow can never block later deletions.
class DeleteFlow {
  static Future<Set<String>> run(
    BuildContext context,
    List<PhotoAsset> assets, {
    required String source,
  }) async {
    if (assets.isEmpty) return const {};
    return _run(context, assets, source: source);
  }

  static Future<Set<String>> _run(
    BuildContext context,
    List<PhotoAsset> assets, {
    required String source,
  }) async {
    final scanner = context.read<PhotoScannerService>();
    final sub = context.read<SubscriptionManager>();

    var usesFreeCleanup = false;
    if (!sub.isPro) {
      final remaining = await FreeCleanupQuota.remaining();
      if (!context.mounted) return const {};
      await PaywallView.showUnlock(
        context,
        source: source,
        freeCleanupsLeft: remaining,
      );
      if (!context.mounted) return const {};
      if (!sub.isPro) {
        if (remaining <= 0) return const {};
        usesFreeCleanup = true;
      }
    }

    // PhotoKit deletion is refused while a scan round owns the library.
    if (scanner.isContinuousScanning) {
      await scanner.pauseContinuousScan();
    } else if (scanner.isScanning) {
      scanner.cancelScan();
    }
    for (var i = 0; i < 50 && scanner.isScanning; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!context.mounted || scanner.isScanning) return const {};

    // Resolve against the current snapshot so the service's version guard
    // compares like with like.
    final wanted = {for (final a in assets) a.id};
    final current = [
      for (final a in scanner.scanResult.allAssets)
        if (wanted.contains(a.id)) a,
    ];
    if (current.isEmpty) return const {};
    final deleted = await scanner.deleteAssetsWithResult(current);
    if (deleted.isEmpty) return deleted;
    if (usesFreeCleanup) unawaited(FreeCleanupQuota.consume());

    final removed = current.where((a) => deleted.contains(a.id)).toList();
    if (!context.mounted) return deleted;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CongratulationsView(
          deletedCount: removed.length,
          deletedBytes: sumBytes(removed),
          videosOnly: removed.every((a) => a.type == AssetType.video),
        ),
      ),
    );
    return deleted;
  }
}
