import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_theme.dart';
import 'category_grid_view.dart';
import 'cleanup_category.dart';
import 'group_review_view.dart';
import 'ui_kit.dart';

/// Opens a category. The first visit shows a one-time explainer card.
Future<void> openCategory(BuildContext context, CleanupCategory category) =>
    _openWithIntro(
      context,
      introKey: category.id,
      title: category.title(context),
      body: category.introBody(context),
      grouped: category.isGrouped,
      destination: () => category.isGrouped
          ? GroupReviewView(
              title: category.title(context),
              sections: [category],
            )
          : CategoryGridView(category: category),
    );

/// Opens the combined "Optimize Storage" review of duplicates and similars.
Future<void> openOptimizeStorage(BuildContext context) => _openWithIntro(
  context,
  introKey: 'optimize',
  title: context.l10n.v2OptimizeTitle,
  body: context.l10n.v2IntroOptimize,
  grouped: true,
  destination: () => GroupReviewView(
    key: const ValueKey('optimize-storage'),
    title: context.l10n.v2OptimizeTitle,
    sections: const [CleanupCategory.duplicates, CleanupCategory.similars],
  ),
);

Future<void> _openWithIntro(
  BuildContext context, {
  required String introKey,
  required String title,
  required String body,
  required bool grouped,
  required Widget Function() destination,
}) async {
  final prefsKey = 'v2.intro.$introKey';
  var seen = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seen = prefs.getBool(prefsKey) ?? false;
  } catch (_) {}
  if (!context.mounted) return;
  final page = destination();
  if (seen) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CategoryIntroView(
        title: title,
        body: body,
        grouped: grouped,
        onContinue: (introContext) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(prefsKey, true);
          } catch (_) {}
          if (!introContext.mounted) return;
          await Navigator.pushReplacement(
            introContext,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    ),
  );
}

class CategoryIntroView extends StatelessWidget {
  const CategoryIntroView({
    super.key,
    required this.title,
    required this.body,
    required this.onContinue,
    this.grouped = false,
  });

  final String title;
  final String body;
  final bool grouped;
  final Future<void> Function(BuildContext context) onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageTopBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        grouped ? const _BeforeAfter() : const _SwipeDemo(),
                        const SizedBox(height: 36),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTheme.heading1.copyWith(
                                  fontSize: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: AppTheme.body.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            BottomAction(
              child: BigButton(
                key: const ValueKey('intro-lets-go'),
                label: context.l10n.v2LetsGo,
                onPressed: () => onContinue(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Left to Delete / Right to Keep" illustration with two tilted cards.
class _SwipeDemo extends StatelessWidget {
  const _SwipeDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Labels sit in the free corners so they never cover the cards:
    // "Right to Keep" above the kept card, "Left to Delete" below the other.
    // Swipes are physical (right keeps, left deletes) in every language, so
    // the demo uses physical left/right even in Arabic and Hebrew.
    return SizedBox(
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 28,
            top: 0,
            child: _DirectionLabel(
              arrowLeft: false,
              word: l10n.v2IntroRight,
              action: l10n.v2IntroToKeep,
              color: AppTheme.success,
            ),
          ),
          Positioned(
            left: -40,
            top: 40,
            child: Transform.rotate(
              angle: -0.14,
              child: const _DemoCard(
                colors: [Color(0xFF8EC5FF), Color(0xFF4F7BD9)],
                mark: _DemoMark(delete: true),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: 120,
            child: Transform.rotate(
              angle: 0.12,
              child: const _DemoCard(
                colors: [Color(0xFFFFD39B), Color(0xFFF08A5D)],
                mark: _DemoMark(delete: false),
                markAtStart: true,
              ),
            ),
          ),
          Positioned(
            left: 28,
            bottom: 0,
            child: _DirectionLabel(
              arrowLeft: true,
              word: l10n.v2IntroLeft,
              action: l10n.v2IntroToDelete,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  const _DirectionLabel({
    required this.arrowLeft,
    required this.word,
    required this.action,
    required this.color,
  });

  final bool arrowLeft;
  final String word;
  final String action;
  final Color color;

  // Swipes are physical, so the label (and its arrow, which Flutter would
  // otherwise mirror in Arabic and Hebrew) is laid out left-to-right.
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: _column(),
  );

  Widget _column() => Column(
    crossAxisAlignment: arrowLeft
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(arrowLeft ? math.pi : 0),
          child: const Icon(
            Icons.trending_flat_rounded,
            size: 40,
            color: AppTheme.textMuted,
          ),
        ),
      ),
      Text(
        word,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTitle,
        ),
      ),
      Text(
        action,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.colors,
    required this.mark,
    this.markAtStart = false,
  });
  final List<Color> colors;
  final Widget mark;
  final bool markAtStart;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 170,
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.landscape_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        PositionedDirectional(
          top: -14,
          start: markAtStart ? 16 : null,
          end: markAtStart ? null : 16,
          child: mark,
        ),
      ],
    ),
  );
}

class _DemoMark extends StatelessWidget {
  const _DemoMark({required this.delete});
  final bool delete;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: delete ? AppTheme.danger : AppTheme.success,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      delete ? Icons.delete_outline_rounded : Icons.check_rounded,
      color: Colors.white,
    ),
  );
}

/// Before (almost full) / After (space freed) illustration for grouped review.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 380,
        width: 320,
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 0,
              child: _StorageChip(
                label: context.l10n.v2Before,
                fill: 0.92,
                color: AppTheme.danger,
                background: AppTheme.dangerLight,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            Positioned(
              right: 20,
              bottom: 0,
              child: _StorageChip(
                label: context.l10n.v2After,
                fill: 0.45,
                color: AppTheme.success,
                background: AppTheme.successLight,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageChip extends StatelessWidget {
  const _StorageChip({
    required this.label,
    required this.fill,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final double fill;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF9CC7FF), Color(0xFF5B8DEF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 10,
            color: color,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
