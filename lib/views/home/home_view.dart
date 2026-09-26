import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../utils/app_theme.dart';
import '../scanner/smart_clean_view.dart';
import '../scanner/scan_progress_panel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  StorageInfo? _storage;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _loadStorage();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
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
                  '裝置容量請至 iPhone 設定查看；此處整理可存取的照片與影片。',
                  style: AppTheme.caption,
                ),
              const SizedBox(height: AppTheme.s16),
              _buildScanButton(scanner),
              if (scanner.isScanning) ...[
                const SizedBox(height: AppTheme.s12),
                _buildProgress(scanner),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _openReview('photos'),
                      child: const Text('查看已讀取照片'),
                    ),
                    TextButton(
                      onPressed: () => _openReview('screenshots'),
                      child: const Text('查看已讀取截圖'),
                    ),
                  ],
                ),
              ],
              if (scanner.hasCompletedScan) ...[
                const SizedBox(height: AppTheme.s16),
                _buildResults(scanner),
              ],
              const SizedBox(height: AppTheme.s24),
              _buildSectionHeader('清理工具'),
              const SizedBox(height: AppTheme.s10),
              _buildToolList(scanner),
              const SizedBox(height: AppTheme.s16),
              _buildSectionHeader('快速操作'),
              const SizedBox(height: AppTheme.s10),
              _buildQuickActions(),
            ],
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
            const Text('清理大師', style: AppTheme.heading1),
            const SizedBox(height: 2),
            Text(
              '先預覽，再整理照片與影片',
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
                'PRO',
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
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ringColor,
                          ),
                        ),
                        Text(
                          '已使用',
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
                      '共 ${info.totalSpaceFormatted}${info.estimateLabel}',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.s12),
                    Row(
                      children: [
                        _legend(ringColor, '已用'),
                        const SizedBox(width: AppTheme.s12),
                        _legend(AppTheme.success, '可用'),
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
                Text(
                  '尚未掃描，點擊下方按鈕開始',
                  style: AppTheme.small.copyWith(color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
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

  // ── Scan Button ──
  Widget _buildScanButton(PhotoScannerService s) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) {
      final scale = s.isScanning ? 1.0 : 1.0 - _pulse.value * 0.015;
      return Transform.scale(
        scale: scale,
        child: Container(
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
                  : () => s.startFullScan(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                            ? '掃描中...'
                            : s.isDeleting
                            ? '刪除中...'
                            : '掃描全部可存取照片與影片',
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
        ),
      );
    },
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
          '已讀取 ${s.scanResult.allAssets.length} 個項目${s.availableAssetCount == null ? '' : '，可存取共 ${s.availableAssetCount} 個'}',
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          s.scanNotice ??
              '視覺分析成功 ${s.analyzedAssetCount} 個，原始素材已驗證 ${s.verifiedOriginalCount} 個。保留建議可撤回，刪除由你決定。',
          style: AppTheme.small,
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _openReview, child: const Text('預覽並整理')),
        if (!s.isScanning && s.pendingResourceCount > 0)
          TextButton(
            onPressed: s.isDeleting ? null : s.verifyOriginals,
            child: const Text('驗證本機原始素材：確認真重複與容量'),
          ),
        if (s.wasCancelled || s.pendingAnalysisCount > 0)
          TextButton(
            onPressed: s.isDeleting ? null : s.resumeScan,
            child: const Text('繼續掃描／重試待處理項目'),
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
        '真重複照片',
        _resourceCountLabel(
          duplicateCount,
          s.pendingResourceCount,
          hasScanned,
          '張',
        ),
        duplicateCount > 0
            ? _Status.warn
            : hasScanned && s.pendingResourceCount == 0
            ? _Status.done
            : _Status.scan,
        AppTheme.primary,
      ),
      _Tool(
        'similar',
        Icons.photo_library_rounded,
        '視覺相似照片',
        !hasScanned
            ? '尚未掃描'
            : s.pendingAnalysisCount > 0
            ? ts > 0
                  ? '$ts 張（部分結果）'
                  : '尚待畫面分析'
            : ts > 0
            ? '$ts 張'
            : '已分析項目中未發現',
        ts > 0
            ? _Status.warn
            : hasScanned && s.pendingAnalysisCount == 0
            ? _Status.done
            : _Status.scan,
        const Color(0xFFF0997B),
      ),
      _Tool(
        'screenshots',
        Icons.screenshot_rounded,
        '螢幕截圖',
        _photoCountLabel(s.scanResult.screenshots.length, hasScanned),
        s.scanResult.screenshots.isNotEmpty
            ? _Status.minor
            : hasScanned
            ? _Status.done
            : _Status.scan,
        const Color(0xFF1D9E75),
      ),
      _Tool(
        'largeFiles',
        Icons.photo_size_select_large_rounded,
        '大型檔案',
        _resourceCountLabel(
          s.scanResult.largeFiles.length,
          s.pendingResourceCount,
          hasScanned,
          '個',
        ),
        s.scanResult.largeFiles.isNotEmpty
            ? _Status.minor
            : hasScanned && s.pendingResourceCount == 0
            ? _Status.done
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
              if (i < items.length - 1) const Divider(indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _photoCountLabel(int count, bool hasScanned) {
    if (!hasScanned) return '尚未掃描';
    return count > 0 ? '$count 張' : '未發現';
  }

  String _resourceCountLabel(
    int count,
    int pending,
    bool hasScanned,
    String unit,
  ) {
    if (!hasScanned) return '尚未掃描';
    if (pending > 0) return count > 0 ? '已確認 $count $unit，仍有待驗證' : '尚待原始素材驗證';
    return count > 0 ? '$count $unit' : '已驗證項目中未發現';
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
            _buildStatusTag(t.status),
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
            '待確認',
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
            '可檢視',
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
            '可檢視',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        );
      case _Status.scan:
        return Text(
          '掃描 ›',
          style: AppTheme.small.copyWith(color: AppTheme.textMuted),
        );
      case _Status.done:
        return Text(
          '已完成 ✓',
          style: AppTheme.small.copyWith(color: AppTheme.textMuted),
        );
    }
  }

  // ── Quick Actions ──
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
          '預覽照片',
          '選擇要保留的項目',
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
            Icons.chevron_right_rounded,
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
enum _Status { critical, warn, minor, scan, done }

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
