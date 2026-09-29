import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';

import '../../models/photo_asset.dart' show formatBytes;
import '../../utils/app_theme.dart';
import 'ui_kit.dart';

class CongratulationsView extends StatelessWidget {
  const CongratulationsView({
    super.key,
    required this.deletedCount,
    required this.deletedBytes,
    this.videosOnly = false,
  });

  final int deletedCount;
  final int deletedBytes;
  final bool videosOnly;

  /// Conservative estimate of manual review time: about five seconds to find
  /// and delete one item in the Photos app, at least one minute.
  int get minutesSaved => ((deletedCount * 5) / 60).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = videosOnly
        ? l10n.v2VideoCount(deletedCount)
        : l10n.v2ItemCount(deletedCount);
    final size = formatBytes(deletedBytes);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const _Confetti(),
                      const SizedBox(height: 28),
                      Text(
                        l10n.v2CongratsTitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.heading1.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 32),
                      _Line(
                        emoji: '✨',
                        children: [
                          TextSpan(text: '${l10n.v2CongratsDeleted}\n'),
                          TextSpan(
                            text: items,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (deletedBytes > 0) TextSpan(text: ' ($size)'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _Line(
                        emoji: '⏳',
                        children: [
                          TextSpan(
                            text: l10n.v2CongratsSaved(minutesSaved),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '\n${l10n.v2CongratsUsing(l10n.appName)}',
                          ),
                        ],
                      ),
                      if (deletedBytes > 0) ...[
                        const SizedBox(height: 32),
                        Text(
                          l10n.v2CongratsRecentlyDeleted(size),
                          textAlign: TextAlign.center,
                          style: AppTheme.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            BottomAction(
              child: BigButton(
                key: const ValueKey('congrats-great'),
                label: l10n.v2Great,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.emoji, required this.children});
  final String emoji;
  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ExcludeSemantics(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Text.rich(
          TextSpan(children: children),
          style: const TextStyle(
            fontSize: 18,
            height: 1.35,
            color: AppTheme.textTitle,
          ),
        ),
      ),
    ],
  );
}

/// Party popper drawn with shapes, so no bitmap asset is needed.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 150,
      height: 130,
      child: CustomPaint(painter: _ConfettiPainter()),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Cone
    final cone = Path()
      ..moveTo(size.width * 0.18, size.height * 0.95)
      ..lineTo(size.width * 0.42, size.height * 0.30)
      ..lineTo(size.width * 0.78, size.height * 0.62)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF5A8A), Color(0xFFFF8FB1)],
        ).createShader(Offset.zero & size),
    );
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.62),
      Offset(size.width * 0.55, size.height * 0.80),
      stripe,
    );
    // Opening
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.60, size.height * 0.46),
        width: size.width * 0.44,
        height: size.height * 0.22,
      ).shift(Offset.zero),
      Paint()..color = const Color(0xFF1C7CF5),
    );
    // Confetti bits
    const bits = [
      (0.72, 0.10, Color(0xFF1C7CF5)),
      (0.86, 0.22, Color(0xFFFFB020)),
      (0.60, 0.05, Color(0xFFFF5A8A)),
      (0.93, 0.40, Color(0xFF34C759)),
      (0.50, 0.14, Color(0xFFFFB020)),
    ];
    for (final (x, y, color) in bits) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
