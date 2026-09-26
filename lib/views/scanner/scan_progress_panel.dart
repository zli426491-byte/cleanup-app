import 'package:flutter/material.dart';

import '../../services/photo_scanner_service.dart';
import '../../utils/app_theme.dart';

class ScanProgressPanel extends StatelessWidget {
  final PhotoScannerService scanner;
  const ScanProgressPanel({super.key, required this.scanner});

  @override
  Widget build(BuildContext context) {
    final total = scanner.availableAssetCount;
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
            scanner.currentPhase == ScanPhase.fetchingAssets
                ? '讀取全部可存取項目'
                : '分析照片內容與檔案容量',
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: total == null ? null : scanner.scanProgress.clamp(0.0, 1.0),
            color: AppTheme.primary,
            backgroundColor: AppTheme.primaryLight,
          ),
          const SizedBox(height: 10),
          Text('已讀取 ${scanner.scannedAssetCount} / ${total ?? '確認中'} 個項目'),
          Text(
            '內容分析已完成 ${scanner.analyzedAssetCount} 個 · 待處理 ${scanner.pendingAnalysisCount} 個',
          ),
          const SizedBox(height: 6),
          const Text('雲端或暫時無法讀取的項目會標記待處理。掃描不會自動刪除照片。', style: AppTheme.caption),
          TextButton.icon(
            onPressed: scanner.cancelScan,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('取消掃描並保留進度'),
          ),
        ],
      ),
    );
  }
}
