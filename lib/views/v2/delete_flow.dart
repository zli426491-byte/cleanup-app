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

  /// Spends one free cleanup *before* PhotoKit is asked, so a storage failure
  /// can never grant unlimited free deletions. Returns false when no cleanup
  /// is left or the reservation could not be saved.
  static Future<bool> reserve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = (prefs.getInt(_key) ?? 0).clamp(
        0,
        AppConstants.maxFreeDeletes,
      );
      if (used >= AppConstants.maxFreeDeletes) return false;
      return await prefs.setInt(_key, used + 1);
    } catch (error) {
      debugPrint('Could not reserve a free cleanup: $error');
      return false;
    }
  }

  /// Returns a reservation when nothing was deleted (cancelled or failed).
  static Future<void> refund() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getInt(_key) ?? 0;
      if (used > 0) await prefs.setInt(_key, used - 1);
    } catch (error) {
      debugPrint('Could not refund a free cleanup: $error');
    }
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

    var usesFreeCleanup = false;
    if (!sub.isPro) {
      final remaining = await FreeCleanupQuota.remaining();
      if (!context.mounted) return const {};
      final outcome = await PaywallView.showUnlock(
        context,
        source: source,
        freeCleanupsLeft: remaining,
      );
      if (!context.mounted) return const {};
      if (outcome == PaywallUnlockResult.cancelled) return const {};
      if (outcome == PaywallUnlockResult.purchased && !sub.isPro) {
        return const {};
      }
      if (!sub.isPro) {
        if (outcome != PaywallUnlockResult.continueFree ||
            await FreeCleanupQuota.remaining() <= 0) {
          return const {};
        }
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
    if (usesFreeCleanup && !await FreeCleanupQuota.reserve()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.serviceOperationFailed)),
        );
      }
      return const {};
    }
    final deleted = await scanner.deleteAssetsWithResult(selected);
    if (deleted.isEmpty) {
      if (usesFreeCleanup) await FreeCleanupQuota.refund();
      return deleted;
    }

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
