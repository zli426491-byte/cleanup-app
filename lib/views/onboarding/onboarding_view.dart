import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../analytics/analytics_manager.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;
  bool _reduceMotion = false;
  late AnimationController _pulseController;

  List<_PageData> get _pages => [
    _PageData(
      Icons.auto_awesome_rounded,
      context.l10n.onboardingSmartTitle,
      context.l10n.onboardingSmartSubtitle,
      const Color(0xFF4F6EF7),
      const Color(0xFF7B93FF),
    ),
    _PageData(
      Icons.photo_library_rounded,
      context.l10n.onboardingPhotosTitle,
      context.l10n.onboardingPhotosSubtitle,
      const Color(0xFFFFAA33),
      const Color(0xFFFFD700),
    ),
    _PageData(
      Icons.swipe_rounded,
      context.l10n.onboardingSwipeTitle,
      context.l10n.onboardingSwipeSubtitle,
      const Color(0xFF00D68F),
      const Color(0xFF00F5A0),
    ),
    _PageData(
      Icons.check_circle_outline_rounded,
      context.l10n.onboardingChoiceTitle,
      context.l10n.onboardingChoiceSubtitle,
      const Color(0xFF9D6AFF),
      const Color(0xFFC084FC),
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.track(AnalyticsEvent.onboardingStarted.name);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _pulseController.stop();
      _pulseController.value = 0;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background gradient blobs
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Stack(
              children: [
                Positioned(
                  top: -60 + _pulseController.value * 20,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          page.c1.withValues(alpha: 0.12),
                          page.c1.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100 - _pulseController.value * 15,
                  left: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          page.c2.withValues(alpha: 0.1),
                          page.c2.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Step indicator
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                context.l10n.onboardingStep(
                                  _currentPage + 1,
                                  _pages.length,
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (_currentPage < _pages.length - 1)
                            Flexible(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  foregroundColor: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  if (_reduceMotion) {
                                    _controller.jumpToPage(_pages.length - 1);
                                  } else {
                                    _controller.animateToPage(
                                      _pages.length - 1,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                child: Text(
                                  context.l10n.onboardingSkip,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Pages
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: _pages.length,
                        itemBuilder: (ctx, i) => _buildPage(_pages[i]),
                      ),
                    ),

                    // Bottom section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                      child: Column(
                        children: [
                          ExcludeSemantics(
                            child: SmoothPageIndicator(
                              controller: _controller,
                              count: _pages.length,
                              effect: ExpandingDotsEffect(
                                dotHeight: 6,
                                dotWidth: 6,
                                expansionFactor: 4,
                                activeDotColor: page.c1,
                                dotColor: const Color(0xFFE2E8F0),
                                spacing: 5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // CTA
                          _buildButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_PageData page) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Triple ring icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final scale = 1.0 + _pulseController.value * 0.03;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: page.c1.withValues(alpha: 0.06),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: page.c1.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [page.c1, page.c2],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.c1.withValues(alpha: 0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.7,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isCompleting ? null : _onNext,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _isCompleting
                        ? context.l10n.onboardingPreparing
                        : _currentPage < _pages.length - 1
                        ? context.l10n.onboardingContinue
                        : context.l10n.onboardingGetStarted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isCompleting)
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
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (_isCompleting || !mounted) return;
    if (_currentPage < _pages.length - 1) {
      if (_reduceMotion) {
        _controller.jumpToPage(_currentPage + 1);
      } else {
        _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      setState(() => _isCompleting = true);
      try {
        AnalyticsManager.instance.track(
          AnalyticsEvent.onboardingCompleted.name,
        );
        await AnalyticsManager.instance.requestATT();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaywallView(fromOnboarding: true),
          ),
        );
      } finally {
        if (mounted) setState(() => _isCompleting = false);
      }
    }
  }
}

class _PageData {
  final IconData icon;
  final String title, subtitle;
  final Color c1, c2;
  const _PageData(this.icon, this.title, this.subtitle, this.c1, this.c2);
}
