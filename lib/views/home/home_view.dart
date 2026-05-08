import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/photo_scanner_service.dart';
import '../../models/storage_info.dart';
import '../../utils/app_theme.dart';
import '../tools/charging_animation_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  StorageInfo? _storage;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _loadStorage();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _loadStorage() async {
    final info = await StorageInfo.current();
    if (mounted) setState(() => _storage = info);
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<PhotoScannerService>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.s20),
            if (_storage != null) _buildStorageCard(_storage!),
            const SizedBox(height: AppTheme.s16),
            _buildScanButton(scanner),
            if (scanner.isScanning) ...[const SizedBox(height: AppTheme.s12), _buildProgress(scanner)],
            if (scanner.scanResult.allAssets.isNotEmpty) ...[const SizedBox(height: AppTheme.s16), _buildResults(scanner)],
            const SizedBox(height: AppTheme.s24),
            _buildSectionHeader('清理工具'),
            const SizedBox(height: AppTheme.s10),
            _buildToolList(scanner),
            const SizedBox(height: AppTheme.s16),
            _buildSectionHeader('快速操作'),
            const SizedBox(height: AppTheme.s10),
            _buildQuickActions(),
          ]),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() => Row(
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('清理大師', style: AppTheme.heading1),
        const SizedBox(height: 2),
        Text('讓手機保持最佳狀態', style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.r50),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium_rounded, color: AppTheme.primary, size: 13),
          const SizedBox(width: 3),
          Text('PRO', style: AppTheme.label.copyWith(color: AppTheme.primary, fontSize: 10, letterSpacing: 0.8)),
        ]),
      ),
    ],
  );

  // ── Storage Card ──
  Widget _buildStorageCard(StorageInfo info) {
    final pct = info.usedPercentage.clamp(0.0, 1.0);
    final ringColor = pct > 0.85 ? AppTheme.danger : pct > 0.6 ? AppTheme.warning : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.s20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: [
        Row(children: [
          // Donut chart
          SizedBox(
            width: 90, height: 90,
            child: CustomPaint(
              painter: _DonutPainter(pct, ringColor),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ringColor)),
                Text('已使用', style: AppTheme.small.copyWith(fontSize: 10)),
              ])),
            ),
          ),
          const SizedBox(width: AppTheme.s20),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.usedSpaceFormatted, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textTitle)),
            Text('共 ${info.totalSpaceFormatted}${info.estimateLabel}', style: AppTheme.caption),
            const SizedBox(height: AppTheme.s12),
            Row(children: [
              _legend(ringColor, '已用'),
              const SizedBox(width: AppTheme.s12),
              _legend(AppTheme.success, '可用'),
            ]),
          ])),
        ]),
        const SizedBox(height: AppTheme.s16),
        // Bottom hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12, vertical: AppTheme.s8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.r8),
          ),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
            const SizedBox(width: AppTheme.s8),
            Text('尚未掃描，點擊下方按鈕開始', style: AppTheme.small.copyWith(color: AppTheme.primary)),
          ]),
        ),
      ]),
    );
  }

  Widget _legend(Color c, String t) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(t, style: AppTheme.small),
  ]);

  // ── Scan Button ──
  Widget _buildScanButton(PhotoScannerService s) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) {
      final scale = s.isScanning ? 1.0 : 1.0 - _pulse.value * 0.015;
      return Transform.scale(
        scale: scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Material(color: Colors.transparent, child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.r16),
            onTap: s.isScanning ? null : () => s.startFullScan(),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (s.isScanning)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(s.isScanning ? '掃描中...' : '智慧掃描', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              if (!s.isScanning) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppTheme.r50)),
                  child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          )),
        ),
      );
    },
  );

  // ── Progress ──
  Widget _buildProgress(PhotoScannerService s) {
    final names = {'fetchingAssets':'讀取照片','computingHashes':'分析照片','findingDuplicates':'尋找重複照片','findingSimilar':'尋找相似照片','collectingScreenshots':'偵測截圖','findingLargeFiles':'尋找大檔','scanningVideos':'掃描影片','done':'完成'};
    return Container(
      padding: const EdgeInsets.all(AppTheme.s14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(AppTheme.r12),
        border: Border.all(color: AppTheme.border, width: 0.5)),
      child: Row(children: [
        SizedBox(width: 28, height: 28, child: CircularProgressIndicator(value: s.scanProgress, strokeWidth: 3, color: AppTheme.primary, backgroundColor: AppTheme.primaryLight)),
        const SizedBox(width: AppTheme.s12),
        Expanded(child: Text(names[s.currentPhase.name] ?? '掃描中...', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
        Text('${(s.scanProgress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
      ]),
    );
  }

  // ── Results ──
  Widget _buildResults(PhotoScannerService s) => Container(
    padding: const EdgeInsets.all(AppTheme.s16),
    decoration: BoxDecoration(color: AppTheme.accentLight, borderRadius: BorderRadius.circular(AppTheme.r16),
      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15))),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
      const SizedBox(width: AppTheme.s10),
      Text('預估可釋放 ', style: AppTheme.body.copyWith(color: AppTheme.textBody)),
      Text(_fmt(s.scanResult.totalSavingsEstimate), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.accent)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(AppTheme.r50)),
        child: const Text('清理', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  // ── Section Header ──
  Widget _buildSectionHeader(String t) => Text(t, style: AppTheme.heading3.copyWith(fontSize: 16));

  // ── Tool List ──
  Widget _buildToolList(PhotoScannerService s) {
    final hasScanned = s.scanResult.allAssets.isNotEmpty;
    final td = s.scanResult.duplicateGroups.fold<int>(0, (a, g) => a + g.assets.length);
    final ts = s.scanResult.similarGroups.fold<int>(0, (a, g) => a + g.assets.length);
    final blurry = s.scanResult.blurryPhotos.length;
    final dark = s.scanResult.darkPhotos.length;
    final items = [
      _Tool(Icons.copy_rounded, '重複照片', _photoCountLabel(td, hasScanned), td > 0 ? _Status.warn : hasScanned ? _Status.done : _Status.scan, const Color(0xFFE5484D)),
      _Tool(Icons.photo_library_rounded, '相似照片', _photoCountLabel(ts, hasScanned), ts > 0 ? _Status.warn : hasScanned ? _Status.done : _Status.scan, const Color(0xFFF0997B)),
      _Tool(Icons.screenshot_rounded, '螢幕截圖', _photoCountLabel(s.scanResult.screenshots.length, hasScanned), s.scanResult.screenshots.isNotEmpty ? _Status.minor : hasScanned ? _Status.done : _Status.scan, const Color(0xFF1D9E75)),
      _Tool(Icons.blur_on_rounded, '模糊照片', _photoCountLabel(blurry, hasScanned), blurry > 0 ? _Status.warn : hasScanned ? _Status.done : _Status.scan, const Color(0xFF9D6AFF)),
      _Tool(Icons.dark_mode_rounded, '過暗照片', _photoCountLabel(dark, hasScanned), dark > 0 ? _Status.warn : hasScanned ? _Status.done : _Status.scan, const Color(0xFF6366F1)),
      _Tool(Icons.compress_rounded, '大型檔案', _itemCountLabel(s.scanResult.largeFiles.length, hasScanned), s.scanResult.largeFiles.isNotEmpty ? _Status.minor : hasScanned ? _Status.done : _Status.scan, const Color(0xFFE5A31A)),
    ];

    return Container(
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(AppTheme.r12),
        border: Border.all(color: AppTheme.border, width: 0.5)),
      child: Column(children: items.asMap().entries.map((e) {
        final i = e.key; final t = e.value;
        return Column(children: [
          _buildToolRow(t),
          if (i < items.length - 1) const Divider(indent: 60),
        ]);
      }).toList()),
    );
  }

  String _photoCountLabel(int count, bool hasScanned) {
    if (!hasScanned) return '尚未掃描';
    return count > 0 ? '$count 張' : '未發現';
  }

  String _itemCountLabel(int count, bool hasScanned) {
    if (!hasScanned) return '尚未掃描';
    return count > 0 ? '$count 個' : '未發現';
  }

  Widget _buildToolRow(_Tool t) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('切換到「${t.title}」'), behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      borderRadius: BorderRadius.circular(AppTheme.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.s14, vertical: AppTheme.s12),
        child: Row(children: [
          // Icon container
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: t.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.r8)),
            child: Icon(t.icon, color: t.color, size: 18)),
          const SizedBox(width: AppTheme.s12),
          // Text
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
            Text(t.subtitle, style: AppTheme.small),
          ])),
          // Status tag
          _buildStatusTag(t.status),
        ]),
      ),
    );
  }

  Widget _buildStatusTag(_Status status) {
    switch (status) {
      case _Status.critical:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.dangerLight, borderRadius: BorderRadius.circular(AppTheme.r50)),
          child: Text('建議清理', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.danger)),
        );
      case _Status.warn:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(AppTheme.r50)),
          child: Text('可清理', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.warning)),
        );
      case _Status.minor:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(AppTheme.r50)),
          child: Text('可清理', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        );
      case _Status.scan:
        return Text('掃描 ›', style: AppTheme.small.copyWith(color: AppTheme.textMuted));
      case _Status.done:
        return Text('已完成 ✓', style: AppTheme.small.copyWith(color: AppTheme.textMuted));
    }
  }

  // ── Quick Actions ──
  Widget _buildQuickActions() => Container(
    decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(AppTheme.r12),
      border: Border.all(color: AppTheme.border, width: 0.5)),
    child: Column(children: [
      _buildQRow(Icons.email_rounded, '清理信箱', '即將推出', const Color(0xFF1D9E75),
        onTap: () => _showComingSoonDialog('信箱清理')),
      const Divider(indent: 60),
      _buildQRow(Icons.calendar_month_rounded, '清理行事曆', '即將推出', const Color(0xFFF0997B),
        onTap: () => _showComingSoonDialog('行事曆清理')),
      const Divider(indent: 60),
      _buildQRow(Icons.bolt_rounded, '充電動畫', '自訂充電畫面', const Color(0xFFE5A31A),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargingAnimationView()))),
    ]),
  );

  Widget _buildQRow(IconData ic, String t, String st, Color c, {required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTheme.r12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.s14, vertical: AppTheme.s12),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppTheme.r8)),
          child: Icon(ic, color: c, size: 18)),
        const SizedBox(width: AppTheme.s12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
          Text(st, style: AppTheme.small),
        ])),
        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
      ]),
    ),
  );

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.construction_rounded, color: AppTheme.warning, size: 24),
          const SizedBox(width: 8),
          const Text('即將推出'),
        ]),
        content: Text('「$featureName」功能正在開發中，敬請期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1073741824).toStringAsFixed(1)} GB';
  }
}

// ── Status Enum ──
enum _Status { critical, warn, minor, scan, done }

// ── Tool Data ──
class _Tool {
  final IconData icon; final String title, subtitle; final _Status status; final Color color;
  _Tool(this.icon, this.title, this.subtitle, this.status, this.color);
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
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFF0F0EC));

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
  bool shouldRepaint(covariant _DonutPainter old) => old.pct != pct || old.color != color;
}
