import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import 'delete_flow.dart' show FreeCleanupQuota;
import 'ui_kit.dart';

/// Shown when a free user's selection does not fit today's free deletions:
/// "You've reached your daily removal limit" with a way to see Pro plans.
class DailyLimitSheet extends StatelessWidget {
  const DailyLimitSheet({
    super.key,
    required this.source,
    required this.remaining,
  });

  final String source;

  /// Free deletions still available today (0 when the limit is reached).
  final int remaining;

  static Future<void> show(
    BuildContext context, {
    required String source,
    required int remaining,
  }) => showDialog<void>(
    context: context,
    builder: (_) => DailyLimitSheet(source: source, remaining: remaining),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      key: const ValueKey('daily-limit'),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const ValueKey('daily-limit-close'),
                  tooltip: l10n.paywallClose,
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 44,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.v2DailyLimitTitle,
                textAlign: TextAlign.center,
                style: AppTheme.heading2.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                remaining > 0
                    ? l10n.v2DailyLimitRemaining(remaining)
                    : l10n.v2DailyLimitBody(FreeCleanupQuota.dailyLimit),
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              BigButton(
                key: const ValueKey('daily-limit-pro'),
                label: l10n.v2SeeProOptions,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await PaywallView.showUnlock(context, source: '${source}_limit');
                  if (navigator.mounted) navigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
