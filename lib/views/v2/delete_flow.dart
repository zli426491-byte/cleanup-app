import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart' show AssetType;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/constants.dart';
import '../paywall/paywall_view.dart';
import 'cleanup_category.dart' show sumBytes;
import 'congratulations_view.dart';
import 'daily_limit_sheet.dart';

/// Free users may delete [AppConstants.maxFreeDeletes] items per calendar day
/// (photos and videos together), like the reference app. The count resets at
/// local midnight.
class FreeCleanupQuota {
  static const _countKey = 'v2.freeDeletes.count';
  static const _dayKey = 'v2.freeDeletes.day';

  /// Replaces the count write in tests to simulate a storage failure.
  @visibleForTesting
  static Future<bool> Function(String key, int value)? debugSetInt;

  /// Clock used for the daily reset; tests move it to another day.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static int get dailyLimit => AppConstants.maxFreeDeletes;

  static String _today() {
    final d = now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static int _usedToday(SharedPreferences prefs) =>
      prefs.getString(_dayKey) == _today()
      ? (prefs.getInt(_countKey) ?? 0).clamp(0, dailyLimit)
      : 0;

  static Future<bool> _write(SharedPreferences prefs, int used) async {
    if (!await prefs.setString(_dayKey, _today())) return false;
    return debugSetInt?.call(_countKey, used) ??
        prefs.setInt(_countKey, used);
  }

  static Future<int> remaining() async {
    final prefs = await SharedPreferences.getInstance();
    return dailyLimit - _usedToday(prefs);
  }

  /// Spends [items] of today's allowance *before* PhotoKit is asked, so a
  /// storage failure can never grant unlimited free deletions. Returns false
  /// when the allowance is too small or the reservation could not be saved.
  static Future<bool> reserve(int items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = _usedToday(prefs);
      if (items <= 0 || used + items > dailyLimit) return false;
      return await _write(prefs, used + items);
    } catch (error) {
      debugPrint('Could not reserve free deletions: $error');
      return false;
    }
  }

  /// Returns [items] that were reserved but not deleted (cancelled or failed).
  /// Retries once; returns false when the refund could not be saved, so the
  /// caller can tell the user instead of silently losing free deletions.
  static Future<bool> refund(int items) async {
    if (items <= 0) return true;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final used = _usedToday(prefs);
        if (used <= 0) return true;
        if (await _write(prefs, (used - items).clamp(0, dailyLimit))) {
          return true;
        }
      } catch (error) {
        debugPrint('Could not refund free deletions: $error');
      }
    }
    return false;
  }
}

/// Shared "Delete N" pipeline for every cleanup screen:
/// soft paywall → pause scanning → iOS system confirmation → congratulations.
///
/// Returns the identifiers PhotoKit actually deleted (empty when the user
/// cancels at any step).
/// Only one delete flow may use the shared free quota at a time. The lock is
/// tied to the screen that started the flow: if that screen is gone (for
/// example it was removed while the paywall was open and the flow never
/// resumed), the lock is stale and cannot block later deletions.
class DeleteFlow {
  static BuildContext? _owner;

  static Future<Set<String>> run(
    BuildContext context,
    List<PhotoAsset> assets, {
    required String source,
  }) async {
    final owner = _owner;
    if (assets.isEmpty || (owner != null && owner.mounted)) return const {};
    _owner = context;
    try {
      return await _run(context, assets, source: source);
    } finally {
      if (identical(_owner, context)) _owner = null;
    }
  }

  static Future<Set<String>> _run(
    BuildContext context,
    List<PhotoAsset> assets, {
    required String source,
  }) async {
    final scanner = context.read<PhotoScannerService>();
    final sub = context.read<SubscriptionManager>();

    final itemCount = {for (final a in assets) a.id}.length;
    var usesFreeCleanup = false;
    if (!sub.isPro) {
      // Like the reference app: every free delete shows the unlock offer;
      // closing it continues within today's free allowance.
      final remaining = await FreeCleanupQuota.remaining();
      if (!context.mounted) return const {};
      if (remaining <= 0) {
        await DailyLimitSheet.show(context, source: source, remaining: 0);
      } else {
        await PaywallView.showUnlock(context, source: source);
        if (!context.mounted) return const {};
        final left = await FreeCleanupQuota.remaining();
        if (!context.mounted) return const {};
        if (!sub.isPro && itemCount > left) {
          await DailyLimitSheet.show(context, source: source, remaining: left);
          if (!sub.isPro) return const {};
        }
      }
      if (!context.mounted) return const {};
      if (!sub.isPro) {
        if (await FreeCleanupQuota.remaining() < itemCount) return const {};
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

    // Keep the versions the user actually saw. Never replace them by ID with
    // newer objects after the paywall or scanner pause. The service repeats
    // this check just before PhotoKit receives the request.
    final currentById = {
      for (final asset in scanner.scanResult.allAssets) asset.id: asset,
    };
    final selected = {
      for (final asset in assets) asset.id: asset,
    }.values.toList();
    if (selected.any((asset) {
      final current = currentById[asset.id];
      return current == null || !_sameAssetVersion(asset, current);
    })) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.scanReviewChanged)));
      }
      return const {};
    }
    if (usesFreeCleanup && !await FreeCleanupQuota.reserve(selected.length)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.serviceOperationFailed)),
        );
      }
      return const {};
    }
    final deleted = await scanner.deleteAssetsWithResult(selected);
    // Items the user cancelled in the system dialog go back to the allowance.
    final unused = selected.length - deleted.length;
    if (usesFreeCleanup &&
        unused > 0 &&
        !await FreeCleanupQuota.refund(unused) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serviceOperationFailed)),
      );
    }
    if (deleted.isEmpty) return deleted;

    final removed = selected.where((a) => deleted.contains(a.id)).toList();
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

  static bool _sameAssetVersion(PhotoAsset a, PhotoAsset b) =>
      a.id == b.id &&
      a.modifiedDate == b.modifiedDate &&
      a.createDate == b.createDate &&
      a.width == b.width &&
      a.height == b.height &&
      a.type == b.type;
}
