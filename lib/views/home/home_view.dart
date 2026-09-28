import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../models/photo_asset.dart' show formatBytes;
import '../../utils/app_theme.dart';
import '../scanner/smart_clean_view.dart';
import '../scanner/scan_progress_panel.dart';
import '../scanner/swipe_clean_view.dart';
import '../scanner/asset_thumbnail.dart';

class HomeView extends StatefulWidget {
  final ValueChanged<String>? onOpenReview;
  const HomeView({super.key, this.onOpenReview});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  StorageInfo? _storage;
  ScanResult? _photoSource;
  int _photoCount = 0;
  List<PhotoAsset> _photoPreviews = const [];
  bool _checkingInitialPreview = false;
  bool _startedInitialPreview = false;

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

  /// A granted Photos permission can start a preview without another tap.
  /// Never reopen the permission dialog or restart a cancelled/partial scan.
  Future<void> _startPreviewWithExistingAccess() async {
    if (!mounted || _checkingInitialPreview || _startedInitialPreview) return;
    final scanner = context.read<PhotoScannerService>();
    if (scanner.isScanning ||
        scanner.isDeleting ||
        scanner.wasCancelled ||
        scanner.hasCompletedScan ||
        scanner.scannedAssetCount > 0 ||
        scanner.scanResult.allAssets.isNotEmpty ||
        scanner.lastError != null) {
      return;
    }
    _checkingInitialPreview = true;
    try {
      final permission = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
      if (!mounted || !permission.hasAccess) return;
      if (scanner.isScanning ||
          scanner.isDeleting ||
          scanner.wasCancelled ||
          scanner.hasCompletedScan ||
          scanner.scannedAssetCount > 0 ||
          scanner.scanResult.allAssets.isNotEmpty ||
          scanner.lastError != null) {
        return;
      }
      _startedInitialPreview = true;
      unawaited(scanner.startFullScan());
    } catch (_) {
      // The manual scan action remains available if the permission check fails.
    } finally {
      _checkingInitialPreview = false;
    }
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
        scanner.hasLimitedAccess,
        scanner.photoScopeChanged,
      ),
    );
    final scanner = context.read<PhotoScannerService>();
    if (!identical(_photoSource, scanner.scanResult)) {
      _photoSource = scanner.scanResult;
      _photoCount = 0;
      final previews = <PhotoAsset>[];
      for (final asset in scanner.scanResult.allAssets) {
        if (asset.type != AssetType.image) continue;
        _photoCount++;
        if (previews.length < 2) previews.add(asset);
      }
      _photoPreviews = previews;
    }
    final isPro = context.select<SubscriptionManager, bool>((sub) => sub.isPro);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isPro),
                  const SizedBox(height: AppTheme.s16),
                  if (_storage != null && !_storage!.isEstimate)
                    _buildStorageCard(_storage!)
                  else if (scanner.knownSizeAssetCount > 0)
                    Text(
                      context.l10n.homeKnownLibrarySize(
                        scanner.knownSizeAssetCount,
                        formatBytes(scanner.knownLibraryBytes),
                      ),
                      style: AppTheme.caption,
                    ),
                  if (scanner.photoScopeChanged &&
                      !scanner.permissionDenied) ...[
                    const SizedBox(height: AppTheme.s12),
                    Text(
                      context.l10n.homePhotoScopeChanged,
                      style: AppTheme.body,
                    ),
                  ],
                  if (scanner.permissionDenied && !scanner.isScanning) ...[
                    const SizedBox(height: AppTheme.s12),
                    _buildPermissionCard(scanner),
                  ] else ...[
                    if (scanner.isScanning ||
                        scanner.scannedAssetCount > 0) ...[
                      const SizedBox(height: AppTheme.s12),
                      _buildScanStrip(scanner),
                    ],
                    if (!scanner.isScanning &&
                        scanner.scanResult.allAssets.isEmpty) ...[
                      const SizedBox(height: AppTheme.s12),
                      _buildScanButton(scanner),
                    ],
                    if (_photoCount > 0) ...[
                      const SizedBox(height: AppTheme.s16),
                      _buildPhotoHero(scanner),
                    ] else if (!scanner.isScanning &&
                        scanner.scanResult.allAssets.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.s16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: scanner.isDeleting ? null : _openReview,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(context.l10n.homeReviewReady),
                        ),
                      ),
                    ],
                    if (!scanner.isScanning &&
                        scanner.scanResult.allAssets.isNotEmpty)
                      TextButton.icon(
                        onPressed: scanner.isDeleting
                            ? null
                            : _shouldResume(scanner)
                            ? scanner.resumeScan
                            : scanner.startFullScan,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          _shouldResume(scanner)
                              ? context.l10n.homeContinueAnalysis
                              : context.l10n.homeScanAll,
                        ),
                      ),
                    if (scanner.hasLimitedAccess)
                      TextButton.icon(
                        onPressed: scanner.isScanning || scanner.isDeleting
                            ? null
                            : () => _manageAccess(scanner),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(context.l10n.homeManagePhotoAccess),
                      ),
                    if (!scanner.isScanning ||
                        scanner.scanResult.allAssets.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.s12),
                      _buildSwipeEntry(scanner),
                    ],
                    const SizedBox(height: AppTheme.s20),
                    _buildSectionHeader(context.l10n.homeCleanupTools),
                    const SizedBox(height: AppTheme.s10),
                    _buildToolList(scanner),
                    if (scanner.isScanning) ...[
                      const SizedBox(height: AppTheme.s16),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(context.l10n.homeScanDetails),
                        children: [_buildProgress(scanner)],
                      ),
                    ],
                    if (!scanner.isScanning &&
                        (scanner.hasCompletedScan ||
                            scanner.scannedAssetCount > 0 ||
                            scanner.wasCancelled ||
                            scanner.lastError != null) &&
                        (scanner.scannedAssetCount == 0 ||
                            scanner.pendingSizeAssetCount > 0 ||
                            scanner.scanNotice != null)) ...[
                      const SizedBox(height: AppTheme.s16),
                      _buildResults(scanner),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manageAccess(PhotoScannerService scanner) async {
    try {
      await scanner.managePhotoAccess();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homePermissionDescription)),
      );
    }
  }

  Widget _buildPermissionCard(PhotoScannerService scanner) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.homePermissionTitle, style: AppTheme.heading3),
        const SizedBox(height: 8),
        Text(context.l10n.homePermissionDescription),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('open-photo-settings'),
          onPressed: () async {
            final opened = await scanner.openPhotoSettings();
            if (!mounted || opened) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.homePermissionDescription)),
            );
          },
          icon: const Icon(Icons.settings_outlined),
          label: Text(context.l10n.homeOpenSettings),
        ),
        TextButton(
          onPressed: scanner.startFullScan,
          child: Text(context.l10n.scanStart),
        ),
      ],
    ),
  );

  // ── Header ──
  Widget _buildHeader(bool isPro) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.homeAppName, style: AppTheme.heading1),
            const SizedBox(height: 2),
            Text(
              context.l10n.homeSubtitle,
              style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
      if (isPro)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.r50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.primary,
                size: 13,
              ),
              const SizedBox(width: 3),
              Text(
                context.l10n.homeProBadge,
                style: AppTheme.label.copyWith(
                  color: AppTheme.primary,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  // ── Storage Card ──
  Widget _buildStorageCard(StorageInfo info) {
    final pct = info.usedPercentage.clamp(0.0, 1.0);
    final ringColor = pct > 0.85
        ? AppTheme.danger
        : pct > 0.6
        ? AppTheme.warning
        : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.s20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutPainter(pct, ringColor),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.homeUsedPercent((pct * 100).toInt()),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ringColor,
                          ),
                        ),
                        Text(
                          context.l10n.homeStorageUsed,
                          style: AppTheme.small.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.s20),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.usedSpaceFormatted,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textTitle,
                      ),
                    ),
                    Text(
                      context.l10n.homeStorageTotal(info.totalSpaceFormatted),
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.s12),
                    Wrap(
                      spacing: AppTheme.s12,
                      runSpacing: 4,
                      children: [
                        _legend(ringColor, context.l10n.homeUsedLegend),
                        _legend(
                          AppTheme.success,
                          context.l10n.homeAvailableLegend,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s16),
          // Bottom hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.s12,
              vertical: AppTheme.s8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.r8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.s8),
                Expanded(
                  child: Text(
                    context.l10n.homeStartScanHint,
                    style: AppTheme.small.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(t, style: AppTheme.small),
    ],
  );

  Widget _buildScanStrip(PhotoScannerService scanner) => AnimatedBuilder(
    animation: scanner,
    builder: (context, _) {
      final total = scanner.availableAssetCount;
      final indexed = scanner.scannedAssetCount;
      return Container(
        key: const ValueKey('home-scan-progress'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.s14),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(AppTheme.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == null
                  ? context.l10n.homeIndexedCount(indexed)
                  : context.l10n.homeIndexedCountWithTotal(indexed, total),
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.s6),
            if (scanner.isScanning) ...[
              LinearProgressIndicator(
                value: scanner.scanProgress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppTheme.cardBg,
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.r8),
              ),
              const SizedBox(height: AppTheme.s6),
              Wrap(
                spacing: AppTheme.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.l10n.homeScanning, style: AppTheme.caption),
                  TextButton(
                    onPressed: scanner.cancelScan,
                    child: Text(context.l10n.scanCancelKeepProgress),
                  ),
                ],
              ),
            ] else
              Text(
                context.l10n.homeAnalysisSummary(
                  scanner.analyzedAssetCount,
                  scanner.verifiedOriginalCount,
                ),
                style: AppTheme.caption,
              ),
          ],
        ),
      );
    },
  );

  Widget _buildPhotoHero(PhotoScannerService scanner) {
    final preview = _photoPreviews;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.s14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.scanCategoryPhotos,
                  style: AppTheme.heading2,
                ),
              ),
              Text(
                context.l10n.homePhotoCount(_photoCount),
                style: AppTheme.caption.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s12),
          Row(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) const SizedBox(width: AppTheme.s8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.r12),
                    child: SizedBox(
                      height: 112,
                      child: AssetThumbnail(
                        key: ValueKey('home-photo-preview-${preview[i].id}'),
                        asset: preview[i],
                        previewSize: 220,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.s12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: scanner.isDeleting ? null : _openReview,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(context.l10n.homeReviewReady),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldResume(PhotoScannerService scanner) =>
      scanner.wasCancelled ||
      scanner.pendingAnalysisCount > 0 ||
      (scanner.scannedAssetCount > 0 && !scanner.hasCompletedScan);

  // ── Scan Button ──
  Widget _buildScanButton(PhotoScannerService s) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('home-scan-start'),
        borderRadius: BorderRadius.circular(AppTheme.r16),
        onTap: s.isScanning || s.isDeleting
            ? null
            : _shouldResume(s)
            ? s.resumeScan
            : s.startFullScan,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.isScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  s.isScanning
                      ? context.l10n.homeScanning
                      : s.isDeleting
                      ? context.l10n.homeDeleting
                      : _shouldResume(s)
                      ? context.l10n.homeResumeScan
                      : context.l10n.homeScanAll,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ── Progress ──
  Widget _buildProgress(PhotoScannerService s) => ScanProgressPanel(scanner: s);

  // ── Results ──
  Widget _buildResults(PhotoScannerService s) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppTheme.s16),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.scannedAssetCount == 0) ...[
          Text(
            s.availableAssetCount == null
                ? context.l10n.homeIndexedCount(0)
                : context.l10n.homeIndexedCountWithTotal(
                    0,
                    s.availableAssetCount!,
                  ),
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.s6),
        ],
        if (s.pendingSizeAssetCount > 0)
          Text(
            context.l10n.homePendingSizes(s.pendingSizeAssetCount),
            style: AppTheme.caption,
          ),
        if (s.scanNotice != null)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.l10n.homeScanDetails),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.localizeServiceMessage(s.scanNotice!),
                  style: AppTheme.caption,
                ),
              ),
            ],
          ),
      ],
    ),
  );

  // ── Section Header ──
  Widget _buildSectionHeader(String t) =>
      Text(t, style: AppTheme.heading3.copyWith(fontSize: 16));

  // ── Tool List ──
  Widget _buildToolList(PhotoScannerService s) {
    final hasScanned = s.hasCompletedScan || s.scannedAssetCount > 0;
    final indexComplete =
        s.availableAssetCount != null &&
        s.scannedAssetCount >= s.availableAssetCount!;
    final ts = s.scanResult.similarGroups.fold<int>(
      0,
      (a, g) => a + g.assets.length,
    );
    final duplicateCount = s.scanResult.duplicateGroups.fold<int>(
      0,
      (sum, group) => sum + group.assets.length,
    );
    final items = [
      _Tool(
        'duplicates',
        Icons.copy_all_rounded,
        context.l10n.homeExactDuplicates,
        _resourceCountLabel(
          duplicateCount,
          s.pendingHashAssetCount,
          hasScanned,
          photos: true,
        ),
        duplicateCount > 0
            ? _Status.warn
            : indexComplete && s.pendingHashAssetCount == 0
            ? _Status.done
            : s.pendingHashAssetCount > 0
            ? _Status.pending
            : _Status.scan,
        AppTheme.primary,
        preview: s.scanResult.duplicateGroups.isEmpty
            ? null
            : s.scanResult.duplicateGroups.first.assets.first,
      ),
      _Tool(
        'similar',
        Icons.photo_library_rounded,
        context.l10n.homeSimilarPhotos,
        !hasScanned
            ? context.l10n.homeNotScanned
            : s.pendingAnalysisCount > 0
            ? ts > 0
                  ? context.l10n.homePhotoCountPartial(ts)
                  : context.l10n.homePendingAnalysis
            : ts > 0
            ? context.l10n.homePhotoCount(ts)
            : !indexComplete
            ? context.l10n.scanEmptyIndexing
            : context.l10n.homeNoneAnalyzed,
        ts > 0
            ? _Status.warn
            : indexComplete && s.pendingAnalysisCount == 0
            ? _Status.done
            : _Status.scan,
        const Color(0xFFF0997B),
        preview: s.scanResult.similarGroups.isEmpty
            ? null
            : s.scanResult.similarGroups.first.assets.first,
      ),
      _Tool(
        'screenshots',
        Icons.screenshot_rounded,
        context.l10n.homeScreenshots,
        !indexComplete && s.scanResult.screenshots.isEmpty
            ? (hasScanned
                  ? context.l10n.scanEmptyIndexing
                  : context.l10n.homeNotScanned)
            : _photoCountLabel(s.scanResult.screenshots.length, hasScanned),
        s.scanResult.screenshots.isNotEmpty
            ? _Status.minor
            : indexComplete
            ? _Status.done
            : _Status.scan,
        const Color(0xFF1D9E75),
        preview: s.scanResult.screenshots.isEmpty
            ? null
            : s.scanResult.screenshots.first,
      ),
      _Tool(
        'videos',
        Icons.play_circle_outline_rounded,
        context.l10n.scanCategoryVideos,
        !indexComplete && s.scanResult.videos.isEmpty
            ? (hasScanned
                  ? context.l10n.scanEmptyIndexing
                  : context.l10n.homeNotScanned)
            : _photoCountLabel(s.scanResult.videos.length, hasScanned),
        s.scanResult.videos.isNotEmpty
            ? _Status.minor
            : indexComplete
            ? _Status.done
            : _Status.scan,
        AppTheme.primary,
        preview: s.scanResult.videos.isEmpty ? null : s.scanResult.videos.first,
      ),
      _Tool(
        'largeFiles',
        Icons.photo_size_select_large_rounded,
        context.l10n.homeLargeFiles,
        _resourceCountLabel(
          s.scanResult.largeFiles.length,
          s.pendingSizeAssetCount,
          hasScanned,
          photos: false,
        ),
        s.scanResult.largeFiles.isNotEmpty
            ? _Status.minor
            : indexComplete && s.pendingSizeAssetCount == 0
            ? _Status.done
            : s.pendingSizeAssetCount > 0
            ? _Status.pending
            : _Status.scan,
        const Color(0xFFE5A31A),
        preview: s.scanResult.largeFiles.isEmpty
            ? null
            : s.scanResult.largeFiles.first,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = textScale > 1.3
            ? 1
            : constraints.maxWidth >= 660
            ? 3
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppTheme.s10 * (columns - 1)) / columns;
        return Wrap(
          spacing: AppTheme.s10,
          runSpacing: AppTheme.s10,
          children: [
            for (final tool in items)
              SizedBox(width: width, child: _buildToolCard(tool)),
          ],
        );
      },
    );
  }

  String _photoCountLabel(int count, bool hasScanned) {
    if (!hasScanned) return context.l10n.homeNotScanned;
    return count > 0
        ? context.l10n.homePhotoCount(count)
        : context.l10n.homeNoneFound;
  }

  String _resourceCountLabel(
    int count,
    int pending,
    bool hasScanned, {
    required bool photos,
  }) {
    if (!hasScanned) return context.l10n.homeNotScanned;
    if (pending > 0) {
      if (count == 0) return context.l10n.homePendingVerification;
      return photos
          ? context.l10n.homeVerifiedPhotosPending(count)
          : context.l10n.homeVerifiedItemsPending(count);
    }
    if (count == 0) return context.l10n.homeNoneVerified;
    return photos
        ? context.l10n.homePhotoCount(count)
        : context.l10n.homeItemCount(count);
  }

  Widget _buildToolCard(_Tool t) => Material(
    key: ValueKey('home-category-${t.category}'),
    color: AppTheme.cardBg,
    borderRadius: BorderRadius.circular(AppTheme.r16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openReview(t.category),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: t.preview == null
                  ? ColoredBox(
                      color: t.color.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(t.icon, color: t.color, size: 38),
                      ),
                    )
                  : AssetThumbnail(
                      key: ValueKey('home-preview-${t.category}'),
                      asset: t.preview!,
                      previewSize: 220,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: AppTheme.heading3),
                  const SizedBox(height: AppTheme.s4),
                  Text(t.subtitle, style: AppTheme.caption),
                  const SizedBox(height: AppTheme.s8),
                  _buildStatusTag(t.status),
                  const SizedBox(height: AppTheme.s8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.homePreviewOrganize,
                          style: AppTheme.label.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStatusTag(_Status status) {
    switch (status) {
      case _Status.critical:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.dangerLight,
            borderRadius: BorderRadius.circular(AppTheme.r50),
          ),
          child: Text(
            context.l10n.homeNeedsReview,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.danger,
            ),
          ),
        );
      case _Status.warn:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.warningLight,
            borderRadius: BorderRadius.circular(AppTheme.r50),
          ),
          child: Text(
            context.l10n.homeCanReview,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.warning,
            ),
          ),
        );
      case _Status.minor:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.r50),
          ),
          child: Text(
            context.l10n.homeCanReview,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        );
      case _Status.scan:
        return Text(
          context.l10n.homeScanStatus,
          style: AppTheme.small.copyWith(color: AppTheme.textMuted),
        );
      case _Status.pending:
        return Text(
          context.l10n.scanNotChecked,
          style: AppTheme.small.copyWith(color: AppTheme.warning),
        );
      case _Status.done:
        return Text(
          context.l10n.homeDoneStatus,
          style: AppTheme.small.copyWith(color: AppTheme.textMuted),
        );
    }
  }

  // ── Quick Actions ──
  Widget _buildSwipeEntry(PhotoScannerService scanner) {
    return Container(
      key: const ValueKey('home-swipe-entry'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.s14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swipe_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.s8),
              Expanded(
                child: Text(
                  context.l10n.scanSwipeCleanup,
                  style: AppTheme.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s4),
          Text(context.l10n.homeSwipeDescription, style: AppTheme.caption),
          if (_photoCount > 0) ...[
            const SizedBox(height: AppTheme.s8),
            FilledButton.icon(
              onPressed: scanner.isScanning || scanner.isDeleting
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SwipeCleanView(
                          assets: scanner.scanResult.allAssets
                              .where((asset) => asset.type == AssetType.image)
                              .toList(),
                          title: context.l10n.scanCategoryPhotos,
                          categoryId: 'photos',
                        ),
                      ),
                    ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(context.l10n.scanSwipeStart),
            ),
          ],
        ],
      ),
    );
  }

  void _openReview([String category = 'photos']) {
    if (widget.onOpenReview != null) {
      widget.onOpenReview!(category);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartCleanView(initialCategory: category),
      ),
    );
  }
}

// ── Status Enum ──
enum _Status { critical, warn, minor, scan, pending, done }

// ── Tool Data ──
class _Tool {
  final String category;
  final IconData icon;
  final String title, subtitle;
  final _Status status;
  final Color color;
  final PhotoAsset? preview;
  _Tool(
    this.category,
    this.icon,
    this.title,
    this.subtitle,
    this.status,
    this.color, {
    this.preview,
  });
}

// ── Donut Chart Painter ──
class _DonutPainter extends CustomPainter {
  final double pct;
  final Color color;
  _DonutPainter(this.pct, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xFFF0F0EC),
    );

    // Progress arc
    final sweepAngle = 2 * pi * pct;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.pct != pct || old.color != color;
}
