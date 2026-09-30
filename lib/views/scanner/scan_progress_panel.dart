import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';

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
    final roundProcessed = scanner.originalRoundProcessed;
    final roundTotal = scanner.originalRoundTotal;
    final visual = scanner.analyzedAssetCount;
    final verified = scanner.verifiedOriginalCount;
    final denominator = indexing
        ? total
        : verifying
        ? roundTotal
        : totalPhotos;
    final numerator = indexing
        ? indexed
        : verifying
        ? roundProcessed
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
                ? context.l10n.scanIndexingTitle
                : verifying
                ? switch (scanner.originalVerificationTarget) {
                    OriginalVerificationTarget.exactPhotos =>
                      context.l10n.scanCheckingExactTitle,
                    OriginalVerificationTarget.fileSizes =>
                      context.l10n.scanCheckingSizesTitle,
                    _ => context.l10n.scanVerifyingTitle,
                  }
                : context.l10n.scanAnalyzingTitle,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio,
            color: AppTheme.primary,
            backgroundColor: AppTheme.primaryLight,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.scanIndexedCount(
              indexed,
              total?.toString() ?? context.l10n.scanCountConfirming,
            ),
          ),
          Text(context.l10n.scanPreviewAttemptCount(attempted, totalPhotos)),
          if (verifying)
            Text(
              roundTotal == null
                  ? context.l10n.scanCountConfirming
                  : context.l10n.scanRoundProgress(roundTotal, roundProcessed),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(context.l10n.scanVisualSuccessCount(visual)),
              Text(switch (scanner.originalVerificationTarget) {
                OriginalVerificationTarget.exactPhotos when verifying =>
                  context.l10n.scanVerificationProgress(
                    scanner.verifiedHashAssetCount,
                    totalPhotos,
                  ),
                OriginalVerificationTarget.fileSizes when verifying =>
                  context.l10n.scanVerificationProgress(
                    scanner.knownSizeAssetCount,
                    indexed,
                  ),
                _ => context.l10n.scanOriginalVerifiedCount(verified),
              }),
              Text(
                context.l10n.scanCloudPendingCount(scanner.cloudPendingCount),
              ),
              Text(
                context.l10n.scanStageRemainingCount(
                  math.max(0, (denominator ?? 0) - numerator),
                ),
              ),
            ],
          ),
          if (scanner.currentOperation != null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.scanOperationWait(
                context.localizeServiceMessage(scanner.currentOperation!),
                scanner.currentWaitSeconds,
              ),
              key: const ValueKey('current-scan-operation'),
              style: AppTheme.caption,
            ),
          ],
          if (scanner.currentWaitSeconds >= 10)
            Text(context.l10n.scanSlowOperationHint, style: AppTheme.caption),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(context.l10n.scanProgressPreviewHint, style: AppTheme.caption),
            TextButton.icon(
              onPressed: scanner.isScanning ? scanner.cancelScan : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(context.l10n.scanCancelKeepProgress),
            ),
          ],
        ],
      ),
    );
  }
}
