import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;

  static const _pages = [
    _PageData(Icons.auto_awesome_rounded, '智慧清理',
        '自動偵測並刪除重複、相似照片\n一鍵釋放大量儲存空間',
        Color(0xFF4F6EF7), Color(0xFF7B93FF)),
    _PageData(Icons.photo_library_rounded, '照片整理',
        '精準找出佔用空間的截圖\n相似照片和大型檔案',
        Color(0xFFFFAA33), Color(0xFFFFD700)),
    _PageData(Icons.people_rounded, '聯絡人清理',
        '智慧合併重複聯絡人\n自動識別不完整條目',
        Color(0xFF00D68F), Color(0xFF00F5A0)),
    _PageData(Icons.shield_rounded, '私密空間',
        '軍事級加密保護\n你的私密照片和影片',
        Color(0xFF9D6AFF), Color(0xFFC084FC)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: -60 + _pulseController.value * 20,
                  right: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [page.c1.withValues(alpha: 0.12), page.c1.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100 - _pulseController.value * 15,
                  left: -60,
                  child: Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [page.c2.withValues(alpha: 0.1), page.c2.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Step indicator
                      Text('${_currentPage + 1}/${_pages.length}',
                          style: const TextStyle(color: AppTheme.textMuted,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_currentPage < _pages.length - 1)
                        GestureDetector(
                          onTap: () => _controller.animateToPage(
                              _pages.length - 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut),
                          child: const Text('跳過',
                              style: TextStyle(color: AppTheme.textMuted,
                                  fontSize: 14, fontWeight: FontWeight.w600)),
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
                      SmoothPageIndicator(
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
                      const SizedBox(height: 32),
                      // CTA
                      _buildButton(page),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_PageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Triple ring icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final scale = 1.0 + _pulseController.value * 0.03;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: page.c1.withValues(alpha: 0.06), width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: page.c1.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Center(
                        child: Container(
                          width: 80, height: 80,
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
                          child: Icon(page.icon, size: 36, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(page.title,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.1)),
          const SizedBox(height: 16),
          Text(page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.7,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }

  Widget _buildButton(_PageData page) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [page.c1, page.c2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: page.c1.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onNext,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentPage < _pages.length - 1 ? '繼續' : '開始使用',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      // Navigate to PaywallView; onboarding completion happens when PaywallView is dismissed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallView(fromOnboarding: true)),
      );
    }
  }
}

class _PageData {
  final IconData icon;
  final String title, subtitle;
  final Color c1, c2;
  const _PageData(this.icon, this.title, this.subtitle, this.c1, this.c2);
}
