import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../analytics/analytics_manager.dart';
import '../../models/storage_info.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../paywall/paywall_view.dart';
import '../v2/ui_kit.dart';

/// Welcome → Photos permission → three feature steps → trial teaser →
/// onboarding paywall. Closing the paywall completes onboarding.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _stepCount = 3;

  /// -1 = welcome, 0.._stepCount-1 = feature steps.
  int _step = -1;
  bool _busy = false;
  StorageInfo _storage = StorageInfo.unknown;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.track(AnalyticsEvent.onboardingStarted.name);
    StorageInfo.current().then((info) {
      if (mounted) setState(() => _storage = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: _step < 0
                  ? _Welcome(
                      key: const ValueKey('onboarding-welcome'),
                      storage: _storage,
                      busy: _busy,
                      onStart: _requestAccess,
                    )
                  : _FeatureStep(
                      key: ValueKey('onboarding-step-$_step'),
                      step: _step,
                      count: _stepCount,
                      busy: _busy,
                      onNext: _next,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestAccess() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final state = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;
      if (state.hasAccess) {
        // Start finding clutter while the user reads the next steps, so the
        // trial page and home screen already show real counts.
        unawaited(context.read<PhotoScannerService>().startContinuousScan());
      }
    } catch (_) {
      // Home keeps a manual scan action and a Settings shortcut.
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _step = 0;
        });
      }
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    AnalyticsManager.instance.track(AnalyticsEvent.onboardingCompleted.name);
    final sub = context.read<SubscriptionManager>();
    // Same plan the paywall preselects, never the longest trial on offer.
    final trialDays = PaywallView.leadingTrialDays(sub);
    if (trialDays != null) {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, _, _) => _TrialTeaser(days: trialDays),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      if (!mounted) return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PaywallView(fromOnboarding: true),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    super.key,
    required this.storage,
    required this.busy,
    required this.onStart,
  });

  final StorageInfo storage;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final known = !storage.isEstimate && storage.totalSpace > 0;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Column(
              children: [
                Text(
                  l10n.v2WelcomeTitle(l10n.appName),
                  textAlign: TextAlign.center,
                  style: AppTheme.heading1.copyWith(fontSize: 34, height: 1.15),
                ),
                const SizedBox(height: 48),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _AppTile(
                      icon: Icons.photo_library_rounded,
                      label: l10n.scanCategoryPhotos,
                      colors: const [Color(0xFFFFB347), Color(0xFFFF5E62)],
                    ),
                    _AppTile(
                      icon: Icons.video_library_rounded,
                      label: l10n.v2CatVideos,
                      colors: const [Color(0xFF5AC8FA), Color(0xFF0A7AFF)],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Unknown capacity: a neutral bar with no progress value,
                  // so VoiceOver never reads a made-up percentage.
                  child: known
                      ? LinearProgressIndicator(
                          value: storage.usedPercentage,
                          minHeight: 16,
                          color: AppTheme.danger,
                          backgroundColor: AppTheme.primaryLight,
                        )
                      : const ExcludeSemantics(
                          child: SizedBox(
                            height: 16,
                            width: double.infinity,
                            child: ColoredBox(color: AppTheme.primaryLight),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                if (known)
                  Text(
                    l10n.v2StorageUsedOf(
                      storage.usedSpaceFormatted,
                      storage.totalSpaceFormatted,
                    ),
                    style: AppTheme.heading2.copyWith(fontSize: 22),
                  ),
                const SizedBox(height: 40),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.v2WelcomeAccess(l10n.appName)} ',
                        style: const TextStyle(color: AppTheme.textTitle),
                      ),
                      TextSpan(text: l10n.v2WelcomePrivacy),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
        BottomAction(
          child: BigButton(
            key: const ValueKey('onboarding-get-started'),
            label: l10n.v2GetStarted,
            loading: busy,
            onPressed: onStart,
          ),
        ),
        const _LegalLinks(),
      ],
    );
  }
}

class _FeatureStep extends StatelessWidget {
  const _FeatureStep({
    super.key,
    required this.step,
    required this.count,
    required this.busy,
    required this.onNext,
  });

  final int step;
  final int count;
  final bool busy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body, art) = switch (step) {
      0 => (
        l10n.v2OnbDupTitle,
        l10n.v2OnbDupBody,
        const _StackedPhotos() as Widget,
      ),
      1 => (l10n.v2OnbSwipeTitle, l10n.v2OnbSwipeBody, const _SwipeArt()),
      _ => (l10n.v2OnbVideoTitle, l10n.v2OnbVideoBody, const _VideoArt()),
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Semantics(
            container: true,
            label: l10n.onboardingStep(step + 1, count),
            child: Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? AppTheme.primary
                            : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 16),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.heading1.copyWith(fontSize: 32, height: 1.15),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),
                FittedBox(fit: BoxFit.scaleDown, child: art),
              ],
            ),
          ),
        ),
        BottomAction(
          child: BigButton(
            key: const ValueKey('onboarding-next'),
            label: l10n.v2Next,
            loading: busy,
            onPressed: onNext,
          ),
        ),
        const _LegalLinks(),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      color: AppTheme.textSecondary,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
            child: Text(context.l10n.paywallPrivacyPolicy, style: style),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
            child: Text(context.l10n.paywallTerms, style: style),
          ),
        ],
      ),
    );
  }
}

/// Full-screen "Try N days / For free!" moment before the trial paywall.
class _TrialTeaser extends StatefulWidget {
  const _TrialTeaser({required this.days});
  final int days;

  @override
  State<_TrialTeaser> createState() => _TrialTeaserState();
}

class _TrialTeaserState extends State<_TrialTeaser> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFFDDEBFF), Colors.white],
          radius: 0.8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF7FB3FF),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.v2TryDays(widget.days),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2EA8FF),
              ),
            ),
            Text(
              context.l10n.v2ForFree,
              style: AppTheme.heading1.copyWith(fontSize: 46),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Illustrations (shapes only, no bitmap assets) ──

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(icon, size: 56, color: Colors.white),
        ),
      ),
      const SizedBox(height: 10),
      Text(label, style: AppTheme.heading3.copyWith(fontSize: 17)),
    ],
  );
}

Widget _photoCard(List<Color> colors, IconData icon, {double w = 150}) =>
    Container(
      width: w,
      height: w * 0.78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 54),
    );

class _StackedPhotos extends StatelessWidget {
  const _StackedPhotos();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      children: [
        _photoCard(
          const [Color(0xFFB8D8FF), Color(0xFF5B8DEF)],
          Icons.landscape_rounded,
        ),
        const SizedBox(height: 10),
        _photoCard(
          const [Color(0xFFFFD39B), Color(0xFFF08A5D)],
          Icons.face_rounded,
        ),
        const SizedBox(height: 10),
        _photoCard(
          const [Color(0xFFE3E7EE), Color(0xFFA7B1C2)],
          Icons.pets_rounded,
        ),
      ],
    ),
  );
}

class _SwipeArt extends StatelessWidget {
  const _SwipeArt();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-70, 20),
            child: Transform.rotate(
              angle: -0.18,
              child: _photoCard(
                const [Color(0xFFFFC2C2), Color(0xFFE5302A)],
                Icons.delete_outline_rounded,
                w: 160,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(70, -10),
            child: Transform.rotate(
              angle: 0.16,
              child: _photoCard(
                const [Color(0xFFBFF0CF), Color(0xFF1FA84F)],
                Icons.check_rounded,
                w: 160,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VideoArt extends StatelessWidget {
  const _VideoArt();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _photoCard(
          const [Color(0xFF9CC7FF), Color(0xFF0A7AFF)],
          Icons.play_arrow_rounded,
          w: 140,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: AppTheme.primary,
            size: 32,
          ),
        ),
        _photoCard(
          const [Color(0xFF9CC7FF), Color(0xFF0A7AFF)],
          Icons.play_arrow_rounded,
          w: 96,
        ),
      ],
    ),
  );
}
