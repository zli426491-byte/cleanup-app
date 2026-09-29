import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../models/photo_asset.dart' show formatBytes;
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import '../scanner/asset_thumbnail.dart';
import '../settings/settings_view.dart';
import '../v2/category_intro_view.dart';
import '../v2/cleanup_category.dart';
import '../v2/ui_kit.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  StorageInfo _storage = StorageInfo.unknown;
  bool _checkingInitialPreview = false;
  bool _startedInitialPreview = false;
  bool _startedOriginalCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startPreviewWithExistingAccess());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_refreshAccessAndPreview());
      unawaited(_loadStorage());
    }
  }

  Future<void> _refreshAccessAndPreview() async {
    await context.read<PhotoScannerService>().refreshPhotoAccess();
    if (mounted) await _startPreviewWithExistingAccess();
  }

  bool _hasScanState(PhotoScannerService scanner) =>
      scanner.isScanning ||
      scanner.isDeleting ||
      scanner.wasCancelled ||
      scanner.hasCompletedScan ||
      scanner.scannedAssetCount > 0 ||
      scanner.scanResult.allAssets.isNotEmpty ||
      scanner.lastError != null;

  /// A granted Photos permission starts the preview scan without another tap.
  /// Never reopen the permission dialog or restart a cancelled/partial scan.
  Future<void> _startPreviewWithExistingAccess() async {
    if (!mounted || _checkingInitialPreview || _startedInitialPreview) return;
    final scanner = context.read<PhotoScannerService>();
    if (_hasScanState(scanner)) return;
    _checkingInitialPreview = true;
    try {
      final permission = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
      if (!mounted || !permission.hasAccess || _hasScanState(scanner)) return;
      _startedInitialPreview = true;
      unawaited(scanner.startContinuousScan());
    } catch (_) {
      // The manual scan action remains available if the permission check fails.
    } finally {
      _checkingInitialPreview = false;
    }
  }

  /// Once every item is indexed, confirm exact duplicates and file sizes from
  /// the originals in the background, so Duplicates and "Space to Clean"
  /// fill in without the user asking. Runs at most once per launch.
  void _maybeCheckOriginals(PhotoScannerService scanner) {
    if (_startedOriginalCheck ||
        scanner.isScanning ||
        scanner.isDeleting ||
        scanner.wasCancelled ||
        !scanner.nativeOriginalAnalysisAvailable) {
      return;
    }
    final total = scanner.availableAssetCount;
    if (total == null || total == 0 || scanner.scannedAssetCount < total) {
      return;
    }
    // A paused or deadline-limited preview keeps its checkpoint; the user
    // continues it explicitly before originals are checked. Previews that
    // were tried but wait for iCloud do not hold the originals back.
    if (!_previewsSettled(scanner)) return;
    if (scanner.pendingHashAssetCount <= 0 &&
        scanner.pendingSizeAssetCount <= 0) {
      return;
    }
    _startedOriginalCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(scanner.verifyOriginals());
    });
  }

  Future<void> _loadStorage() async {
    final info = await StorageInfo.current();
    if (mounted) setState(() => _storage = info);
  }

  @override
  Widget build(BuildContext context) {
    context.select<PhotoScannerService, Object>(
      (scanner) => (
        scanner.scanResult,
        scanner.isScanning,
        scanner.isDeleting,
        scanner.hasCompletedScan,
        scanner.permissionDenied,
        scanner.scannedAssetCount,
        scanner.wasCancelled,
        scanner.pendingAnalysisCount,
        scanner.availableAssetCount,
        scanner.pendingHashAssetCount,
        scanner.pendingSizeAssetCount,
        scanner.attemptedAnalysisCount,
      ),
    );
    final scanner = context.read<PhotoScannerService>();
    _maybeCheckOriginals(scanner);
    final isPro = context.select<SubscriptionManager, bool>((sub) => sub.isPro);
    final index = CategoryIndex.of(scanner.scanResult);
    final notStarted = !_hasScanState(scanner) && !scanner.permissionDenied;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(isPro: isPro),
            _SpaceToClean(bytes: sumBytes(index.suggested), storage: _storage),
            Expanded(
              child: CustomScrollView(
                key: const PageStorageKey('home-scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: _OptimizeBanner(
                      onTap: () => openOptimizeStorage(context),
                    ),
                  ),
                  if (scanner.permissionDenied && !scanner.isScanning)
                    SliverToBoxAdapter(child: _PermissionCard(scanner))
                  else if (notStarted)
                    SliverToBoxAdapter(child: _StartScanCard(scanner))
                  else if (scanner.isScanning)
                    SliverToBoxAdapter(child: _ScanStatus(scanner))
                  else if (_isPaused(scanner) ||
                      (_startedOriginalCheck && _originalsPending(scanner)))
                    SliverToBoxAdapter(child: _ScanPaused(scanner)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _CategoryWall(index: index),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Previews are complete but some originals still need their exact-copy or
/// size check (each round is time-bounded on large libraries).
bool _originalsPending(PhotoScannerService scanner) {
  if (scanner.isScanning || scanner.isDeleting) return false;
  if (!scanner.nativeOriginalAnalysisAvailable) return false;
  final total = scanner.availableAssetCount;
  if (total == null || scanner.scannedAssetCount < total) return false;
  if (!_previewsSettled(scanner)) return false;
  return scanner.pendingHashAssetCount > 0 || scanner.pendingSizeAssetCount > 0;
}

/// Every photo preview was tried at least once. Some may still wait for
/// iCloud; those are retried from the paused card, not before originals.
bool _previewsSettled(PhotoScannerService scanner) =>
    scanner.pendingAnalysisCount == 0 ||
    scanner.attemptedAnalysisCount >= scanner.totalPhotoCount;

/// A cancelled scan, one stopped by its time budget, or a partial index can
/// be continued from its checkpoint.
bool _isPaused(PhotoScannerService scanner) {
  if (scanner.isScanning || scanner.isDeleting) return false;
  if (scanner.wasCancelled) return true;
  if (scanner.scannedAssetCount == 0) return false;
  final total = scanner.availableAssetCount;
  return scanner.pendingAnalysisCount > 0 ||
      (total != null && scanner.scannedAssetCount < total);
}

// ── Header: "✦ App name"  [★ PRO] [⚙] ──
class _Header extends StatelessWidget {
  const _Header({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppTheme.textTitle,
            size: 26,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.heading1,
            ),
          ),
          if (!isPro)
            Material(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.r50),
              // An upgrade action, not a claim that this account is Pro.
              child: Semantics(
                button: true,
                label: l10n.settingsUpgrade,
                excludeSemantics: true,
                child: InkWell(
                  key: const ValueKey('home-pro'),
                  borderRadius: BorderRadius.circular(AppTheme.r50),
                  onTap: () =>
                      PaywallView.showUnlock(context, source: 'home_pro'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.homeProBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            key: const ValueKey('home-settings'),
            tooltip: l10n.settingsTitle,
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textTitle,
              size: 28,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── "23.7 MB Space to Clean" + usage bar ──
class _SpaceToClean extends StatelessWidget {
  const _SpaceToClean({required this.bytes, required this.storage});
  final int bytes;
  final StorageInfo storage;

  @override
  Widget build(BuildContext context) {
    final known = !storage.isEstimate && storage.totalSpace > 0;
    final usedFraction = known ? storage.usedPercentage : 0.0;
    final cleanFraction = known
        ? (bytes / storage.totalSpace).clamp(0.0, usedFraction)
        : 0.0;
    return Padding(
      key: const ValueKey('home-space-to-clean'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatBytes(bytes),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textTitle,
                  ),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: context.l10n.v2SpaceToClean,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: known
                      ? context.l10n.v2StorageUsedOf(
                          storage.usedSpaceFormatted,
                          storage.totalSpaceFormatted,
                        )
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: LayoutBuilder(
                        builder: (context, c) => Stack(
                          children: [
                            Container(color: AppTheme.divider),
                            Container(
                              width: c.maxWidth * (known ? usedFraction : 1),
                              color: known
                                  ? AppTheme.danger
                                  : AppTheme.danger.withValues(alpha: 0.25),
                            ),
                            if (cleanFraction > 0)
                              PositionedDirectional(
                                start:
                                    c.maxWidth * (usedFraction - cleanFraction),
                                child: Container(
                                  width: c.maxWidth * cleanFraction,
                                  height: 8,
                                  color: const Color(0xFFFFB020),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              for (final color in const [
                Color(0xFFFF9F0A),
                Color(0xFFFFCC00),
                Color(0xFF8E8E93),
              ]) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Full-width blue "Optimize Storage" banner ──
class _OptimizeBanner extends StatelessWidget {
  const _OptimizeBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      child: Ink(
        decoration: const BoxDecoration(gradient: AppTheme.bannerGradient),
        child: InkWell(
          key: const ValueKey('home-optimize-storage'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.v2OptimizeTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.v2OptimizeSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Scan states ──
class _ScanStatus extends StatelessWidget {
  const _ScanStatus(this.scanner);
  final PhotoScannerService scanner;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: scanner,
    builder: (context, _) {
      final total = scanner.availableAssetCount;
      final verifying = scanner.isVerifyingOriginals;
      final indexing = total == null || scanner.scannedAssetCount < total;
      // Show the stage that is actually moving: originals, index, analysis.
      final done = verifying
          ? scanner.originalRoundProcessed
          : indexing
          ? scanner.scannedAssetCount
          : scanner.attemptedAnalysisCount;
      final stageTotal = verifying
          ? scanner.originalRoundTotal
          : indexing
          ? total
          : scanner.totalPhotoCount;
      final progress = stageTotal == null || stageTotal == 0
          ? null
          : (done / stageTotal).clamp(0.0, 1.0);
      return Padding(
        key: const ValueKey('home-scan-progress'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verifying
                        ? context.l10n.v2CheckingDuplicates
                        : context.l10n.v2Scanning,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textTitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (stageTotal != null && stageTotal > 0)
                  Text(
                    context.l10n.v2ScanningCount(done, stageTotal),
                    style: AppTheme.small,
                  ),
                IconButton(
                  key: const ValueKey('home-scan-pause'),
                  tooltip: context.l10n.v2PauseScan,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: scanner.cancelScan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ScanPaused extends StatelessWidget {
  const _ScanPaused(this.scanner);
  final PhotoScannerService scanner;

  @override
  Widget build(BuildContext context) {
    final total = scanner.availableAssetCount;
    final indexed = total != null && scanner.scannedAssetCount >= total;
    // Once previews are done, "continue" resumes the originals check.
    final originals = _originalsPending(scanner);
    final hashPending = scanner.pendingHashAssetCount > 0;
    final done = originals
        ? (hashPending
              ? scanner.verifiedHashAssetCount
              : scanner.knownSizeAssetCount)
        : indexed
        ? scanner.attemptedAnalysisCount
        : scanner.scannedAssetCount;
    final of = originals
        ? (hashPending ? scanner.totalPhotoCount : scanner.scannedAssetCount)
        : indexed
        ? scanner.totalPhotoCount
        : total;
    return Padding(
      key: const ValueKey('home-scan-paused'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TintCard(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
        child: Row(
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    originals
                        ? context.l10n.v2CheckPaused
                        : context.l10n.v2ScanPaused,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textTitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (of != null && of > 0)
                    Text(
                      context.l10n.v2ScanningCount(done, of),
                      style: AppTheme.small,
                    ),
                ],
              ),
            ),
            Flexible(
              child: TextButton(
                key: const ValueKey('home-scan-continue'),
                onPressed: () => originals
                    ? scanner.verifyOriginals()
                    : scanner.startContinuousScan(resume: true),
                child: Text(
                  context.l10n.v2ContinueScan,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartScanCard extends StatelessWidget {
  const _StartScanCard(this.scanner);
  final PhotoScannerService scanner;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: TintCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.v2PermissionTitle, style: AppTheme.heading2),
          const SizedBox(height: 6),
          Text(
            context.l10n.v2PermissionBody(context.l10n.appName),
            style: AppTheme.caption,
          ),
          const SizedBox(height: 16),
          BigButton(
            key: const ValueKey('home-scan-start'),
            label: context.l10n.v2ScanStart,
            onPressed: scanner.isDeleting
                ? null
                : () => scanner.startContinuousScan(),
          ),
        ],
      ),
    ),
  );
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard(this.scanner);
  final PhotoScannerService scanner;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: TintCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.v2PermissionTitle, style: AppTheme.heading2),
          const SizedBox(height: 6),
          Text(
            context.l10n.v2PermissionBody(context.l10n.appName),
            style: AppTheme.caption,
          ),
          const SizedBox(height: 16),
          BigButton(
            key: const ValueKey('open-photo-settings'),
            label: context.l10n.v2OpenSettings,
            onPressed: () async {
              final opened = await scanner.openPhotoSettings();
              if (!context.mounted || opened) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.homePermissionDescription)),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// ── Category wall ──
class _CategoryWall extends StatelessWidget {
  const _CategoryWall({required this.index});
  final CategoryIndex index;

  @override
  Widget build(BuildContext context) {
    final wide = <Widget>[];
    final tiles = <CategoryContent>[];
    for (final category in CleanupCategory.values) {
      final content = index[category];
      if (category.isGrouped) {
        wide.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WideCategoryCard(content: content),
          ),
        );
      } else {
        tiles.add(content);
      }
    }
    return Column(
      children: [
        ...wide,
        LayoutBuilder(
          builder: (context, constraints) {
            // Two columns on iPhone; iPad adds columns instead of huge tiles.
            final columns = (constraints.maxWidth / 210).floor().clamp(2, 5);
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final content in tiles)
                  SizedBox(
                    width: width,
                    height: width * 1.2,
                    child: _CategoryTile(content: content),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

String _pillDetail(CategoryContent content) =>
    content.bytes > 0 ? formatBytes(content.bytes) : '';

/// Similars / Duplicates: a slim row when empty, a two-photo card when not.
class _WideCategoryCard extends StatelessWidget {
  const _WideCategoryCard({required this.content});
  final CategoryContent content;

  @override
  Widget build(BuildContext context) {
    final category = content.category;
    final title = category.title(context);
    final countLabel = category.countLabel(context, content.count);
    if (content.isEmpty) {
      return Semantics(
        button: true,
        label: '$title, $countLabel',
        excludeSemantics: true,
        child: TintCard(
          key: ValueKey('home-category-${category.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          onTap: () => openCategory(context, category),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(countLabel, style: AppTheme.small),
            ],
          ),
        ),
      );
    }
    final preview = content.groups.first.assets.take(2).toList();
    return Semantics(
      button: true,
      label: '$title, $countLabel',
      excludeSemantics: true,
      child: TintCard(
        key: ValueKey('home-category-${category.id}'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        onTap: () => openCategory(context, category),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2, bottom: 10),
              child: Text(title, style: AppTheme.heading2),
            ),
            SizedBox(
              height: 170,
              child: Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < preview.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            // The whole card opens the category, even when a
                            // thumbnail shows its reload control.
                            child: IgnorePointer(
                              child: SizedBox.expand(
                                child: AssetThumbnail(
                                  key: ValueKey(
                                    'home-preview-${preview[i].id}',
                                  ),
                                  asset: preview[i],
                                  previewSize: 300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  PositionedDirectional(
                    end: 8,
                    bottom: 8,
                    child: InfoPill(
                      text: countLabel,
                      detail: _pillDetail(content).isEmpty
                          ? null
                          : _pillDetail(content),
                      chevron: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column category tile: title, cover photo and a count pill.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.content});
  final CategoryContent content;

  @override
  Widget build(BuildContext context) {
    final category = content.category;
    final title = category.title(context);
    final countLabel = category.countLabel(context, content.count);
    final cover = content.cover;
    return Semantics(
      button: true,
      label: '$title, $countLabel',
      excludeSemantics: true,
      child: TintCard(
        key: ValueKey('home-category-${category.id}'),
        padding: EdgeInsets.zero,
        onTap: () => openCategory(context, category),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.heading2.copyWith(
                  fontSize: 18,
                  color: cover == null
                      ? AppTheme.textMuted.withValues(alpha: 0.7)
                      : AppTheme.textTitle,
                  fontWeight: cover == null ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: cover == null
                  ? Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMuted.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              category.icon,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 12,
                          bottom: 10,
                          child: Text(countLabel, style: AppTheme.small),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          child: AssetThumbnail(
                            key: ValueKey('home-cover-${category.id}'),
                            asset: cover,
                            previewSize: 300,
                          ),
                        ),
                        PositionedDirectional(
                          start: 8,
                          end: 8,
                          bottom: 8,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: InfoPill(
                              text: countLabel,
                              detail: _pillDetail(content).isEmpty
                                  ? null
                                  : _pillDetail(content),
                              chevron: true,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
