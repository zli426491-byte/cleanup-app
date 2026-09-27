import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../utils/app_theme.dart';
import '../scanner/smart_clean_view.dart';
import '../scanner/scan_progress_panel.dart';
import '../scanner/swipe_clean_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  StorageInfo? _storage;

  @override
  void initState() {
    super.initState();
    _loadStorage();
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
      ),
    );
    final scanner = context.read<PhotoScannerService>();
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
                  const SizedBox(height: AppTheme.s20),
                  if (_storage != null && !_storage!.isEstimate)
                    _buildStorageCard(_storage!)
                  else
                    Text(
                      context.l10n.homeStorageUnavailable,
                      style: AppTheme.caption,
                    ),
                  const SizedBox(height: AppTheme.s16),
                  _buildScanButton(scanner),
                  if (!scanner.isScanning ||
                      scanner.scanResult.allAssets.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.s16),
                    _buildSwipeEntry(scanner),
                  ],
                  if (scanner.isScanning) ...[
                    const SizedBox(height: AppTheme.s12),
                    _buildProgress(scanner),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _openReview('photos'),
                          child: Text(context.l10n.homeViewIndexedPhotos),
                        ),
                        TextButton(
                          onPressed: () => _openReview('screenshots'),
                          child: Text(context.l10n.homeViewIndexedScreenshots),
                        ),
                      ],
                    ),
                  ],
                  if (!scanner.isScanning &&
                      (scanner.hasCompletedScan ||
                          scanner.scannedAssetCount > 0 ||
                          scanner.wasCancelled ||
                          scanner.lastError != null)) ...[
                    const SizedBox(height: AppTheme.s16),
                    _buildResults(scanner),
                  ],
                  const SizedBox(height: AppTheme.s24),
                  _buildSectionHeader(context.l10n.homeCleanupTools),
                  const SizedBox(height: AppTheme.s10),
                  _buildToolList(scanner),
                  const SizedBox(height: AppTheme.s16),
                  _buildSectionHeader(context.l10n.homeQuickActions),
                  const SizedBox(height: AppTheme.s10),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    padding: const EdgeInsets.all(AppTheme.s16),
    decoration: BoxDecoration(
      color: AppTheme.accentLight,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.availableAssetCount == null
              ? context.l10n.homeIndexedCount(s.scanResult.allAssets.length)
              : context.l10n.homeIndexedCountWithTotal(
                  s.scanResult.allAssets.length,
                  s.availableAssetCount!,
                ),
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          s.scanNotice == null
              ? context.l10n.homeAnalysisSummary(
                  s.analyzedAssetCount,
                  s.verifiedOriginalCount,
                )
              : context.localizeServiceMessage(s.scanNotice!),
          style: AppTheme.small,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _openReview,
          child: Text(context.l10n.homePreviewOrganize),
        ),
        if (!s.isScanning && s.pendingResourceCount > 0)
          TextButton(
            onPressed: s.isDeleting ? null : s.verifyOriginals,
            child: Text(context.l10n.homeVerifyOriginals),
          ),
        if (!s.isScanning && _shouldResume(s))
          TextButton(
            onPressed: s.isDeleting ? null : s.resumeScan,
            child: Text(context.l10n.homeRetryPending),
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
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          return Column(
            children: [
              _buildToolRow(t),
              if (i < items.length - 1)
                Divider(
                  indent: Directionality.of(context) == TextDirection.rtl
                      ? 0
                      : 60,
                  endIndent: Directionality.of(context) == TextDirection.rtl
                      ? 60
                      : 0,
                ),
            ],
          );
        }).toList(),
      ),
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

  Widget _buildToolRow(_Tool t) {
    return InkWell(
      onTap: () => _openReview(t.category),
      borderRadius: BorderRadius.circular(AppTheme.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s14,
          vertical: AppTheme.s12,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.r8),
              ),
              child: Icon(t.icon, color: t.color, size: 18),
            ),
            const SizedBox(width: AppTheme.s12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(t.subtitle, style: AppTheme.small),
                ],
              ),
            ),
            // Status tag
            Flexible(child: _buildStatusTag(t.status)),
          ],
        ),
      ),
    );
  }

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
    final photos = scanner.scanResult.allAssets
        .where((asset) => asset.type == AssetType.image)
        .toList();
    return Container(
      key: const ValueKey('home-swipe-entry'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.swipe_rounded, color: AppTheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(context.l10n.scanSwipeCleanup, style: AppTheme.heading3),
          const SizedBox(height: 6),
          Text(context.l10n.homeSwipeDescription, style: AppTheme.body),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: scanner.isScanning || scanner.isDeleting
                ? null
                : photos.isEmpty
                ? () => _openReview('photos')
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SwipeCleanView(
                        assets: photos,
                        title: context.l10n.scanCategoryPhotos,
                        categoryId: 'photos',
                      ),
                    ),
                  ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              photos.isEmpty
                  ? context.l10n.scanStart
                  : context.l10n.scanSwipeStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() => Container(
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(AppTheme.r12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(
      children: [
        _buildQRow(
          Icons.photo_library_rounded,
          context.l10n.homePreviewPhotos,
          context.l10n.homeChooseKeep,
          AppTheme.primary,
          onTap: _openReview,
        ),
      ],
    ),
  );

  Widget _buildQRow(
    IconData ic,
    String t,
    String st,
    Color c, {
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTheme.r12),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s14,
        vertical: AppTheme.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.r8),
            ),
            child: Icon(ic, color: c, size: 18),
          ),
          const SizedBox(width: AppTheme.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(st, style: AppTheme.small),
              ],
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
            size: 18,
          ),
        ],
      ),
    ),
  );

  void _openReview([String category = 'photos']) {
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
  _Tool(
    this.category,
    this.icon,
    this.title,
    this.subtitle,
    this.status,
    this.color,
  );
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
