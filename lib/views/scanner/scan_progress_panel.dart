import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/photo_scanner_service.dart';
import '../../utils/app_theme.dart';

/// Only this small panel listens to per-second wait updates. List pages listen
/// to result snapshots so a heartbeat does not filter or sort a large library.
class ScanProgressPanel extends StatelessWidget {
  final PhotoScannerService scanner;
  final bool compact;
  const ScanProgressPanel({
    super.key,
    required this.scanner,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: scanner,
    builder: (context, _) => _panel(context),
  );

  Widget _panel(BuildContext context) {
    final indexing = scanner.currentPhase == ScanPhase.fetchingAssets;
    final verifying = scanner.isVerifyingOriginals;
    final total = scanner.availableAssetCount;
    final indexed = scanner.scannedAssetCount;
    final attempted = scanner.attemptedAnalysisCount;
    final totalPhotos = scanner.totalPhotoCount;
    final attemptedResources = scanner.attemptedResourceCount;
    final visual = scanner.analyzedAssetCount;
    final verified = scanner.verifiedOriginalCount;
    final denominator = indexing
        ? total
        : verifying
        ? indexed
        : totalPhotos;
    final numerator = indexing
        ? indexed
        : verifying
        ? attemptedResources
        : attempted;
    final ratio = denominator == null || denominator == 0
        ? null
        : (numerator / denominator).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indexing
                ? '讀取相簿目錄'
                : verifying
                ? '驗證原始素材，確認真重複'
                : '分析本機照片畫面',
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio,
            color: AppTheme.primary,
            backgroundColor: AppTheme.primaryLight,
          ),
          const SizedBox(height: 10),
          Text('已讀取 $indexed / ${total ?? '確認中'} 個項目'),
          Text('照片畫面已處理 $attempted / $totalPhotos 張'),
          if (verifying) Text('原始素材已處理 $attemptedResources / $indexed 個項目'),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text('視覺分析成功 $visual 個'),
              Text('原始素材已驗證 $verified 個'),
              Text('待下載 ${scanner.cloudPendingCount} 個'),
              Text('本階段尚未處理 ${math.max(0, (denominator ?? 0) - numerator)} 個'),
            ],
          ),
          if (scanner.currentOperation != null) ...[
            const SizedBox(height: 8),
            Text(
              '${scanner.currentOperation} · 已等待 ${scanner.currentWaitSeconds} 秒',
              key: const ValueKey('current-scan-operation'),
              style: AppTheme.caption,
            ),
          ],
          if (scanner.currentWaitSeconds >= 10)
            const Text('此項目讀取較慢，可先取消並保留進度，稍後續掃。', style: AppTheme.caption),
          if (!compact) ...[
            const SizedBox(height: 8),
            const Text(
              '已讀取的照片與截圖可先查看。待下載或未成功分析的項目不會被當成真重複。',
              style: AppTheme.caption,
            ),
            TextButton.icon(
              onPressed: scanner.isScanning ? scanner.cancelScan : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('取消掃描並保留進度'),
            ),
          ],
        ],
      ),
    );
  }
}
