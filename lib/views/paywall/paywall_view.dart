import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../analytics/analytics_manager.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../home/main_tab_view.dart';

class PaywallView extends StatefulWidget {
  final bool fromOnboarding;

  const PaywallView({super.key, this.fromOnboarding = false});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  _PlanOption? _selectedPlan;
  bool _isPurchasing = false;
  bool _hasTrackedClose = false;
  String? _buildNumber;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.track(
      AnalyticsEvent.paywallShown.name,
      properties: {'source': widget.fromOnboarding ? 'onboarding' : 'in_app'},
    );
    _loadBuildNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();
    final plans = _sortedPlans(sub);
    final canPurchase = !sub.isPlaceholder &&
        _selectedPlan != null &&
        !sub.isLoading &&
        !_isPurchasing;

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _dismiss(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cleanup Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              if (_buildNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  'TestFlight Build $_buildNumber',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '解鎖完整清理工具，快速找出可釋放的照片、影片與檔案空間。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (sub.statusMessage.isNotEmpty) ...[
                _StatusBanner(message: sub.statusMessage),
                const SizedBox(height: 16),
              ],
              ..._features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(feature.icon, color: feature.color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(feature.label)),
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (plans.isEmpty)
                _EmptyPlans(isLoading: sub.isLoading)
              else
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlanCard(
                      title: _titleFor(plan),
                      subtitle: _subtitleFor(plan),
                      price: plan.product.priceString,
                      isSelected:
                          plan.product.identifier == _selectedPlan?.product.identifier,
                      isBestValue:
                          plan.product.identifier == AppConstants.yearlyProductId,
                      onTap: () => setState(() => _selectedPlan = plan),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _PurchaseButton(
                isEnabled: canPurchase,
                isLoading: sub.isLoading || _isPurchasing,
                label: sub.isPlaceholder ? '訂閱尚未設定' : '繼續',
                onTap: () => _purchase(sub),
              ),
              const SizedBox(height: 16),
              Text(
                '購買會透過 App Store 完成，訂閱可在 Apple ID 設定中管理或取消。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed:
                        sub.isPlaceholder || sub.isLoading ? null : () => _restore(sub),
                    child: const Text('恢復購買', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://zli426491-byte.github.io/cleanup-app/'),
                    ),
                    child: const Text('隱私權政策', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://zli426491-byte.github.io/cleanup-app/'),
                    ),
                    child: const Text('使用條款', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    final sub = context.read<SubscriptionManager>();
    if (sub.availablePackages.isEmpty && sub.storeProducts.isEmpty) {
      await sub.loadProducts();
    }
    if (!mounted) return;
    final plans = _sortedPlans(sub);
    if (plans.isNotEmpty) {
      setState(() => _selectedPlan ??= plans.first);
    }
  }

  Future<void> _loadBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _buildNumber = packageInfo.buildNumber);
  }

  Future<void> _purchase(SubscriptionManager sub) async {
    final plan = _selectedPlan;
    if (plan == null || sub.isPlaceholder || _isPurchasing) return;

    setState(() => _isPurchasing = true);
    final didPurchase = plan.package == null
        ? await sub.purchaseStoreProduct(plan.product)
        : await sub.purchase(plan.package!);
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (didPurchase) {
      if (plan.product.introductoryPrice != null) {
        AnalyticsManager.instance.track(AnalyticsEvent.trialStarted.name);
      }
      AnalyticsManager.instance.track(
        AnalyticsEvent.subscriptionStarted.name,
        properties: {'product_id': plan.product.identifier},
      );
      AnalyticsManager.instance.trackRevenue(
        plan.product.identifier,
        plan.product.price,
        plan.product.currencyCode,
      );
      _dismiss(context);
    } else {
      _showMessage(
        sub.statusMessage.isNotEmpty ? sub.statusMessage : '購買未完成，請稍後再試。',
      );
    }
  }

  Future<void> _restore(SubscriptionManager sub) async {
    final restored = await sub.restorePurchases();
    if (!mounted) return;

    if (restored) {
      _showMessage('已恢復 Pro 權限。');
      _dismiss(context);
    } else {
      _showMessage(
        sub.statusMessage.isNotEmpty ? sub.statusMessage : '找不到可恢復的購買紀錄。',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _dismiss(BuildContext context) async {
    if (!_hasTrackedClose) {
      _hasTrackedClose = true;
      AnalyticsManager.instance.track(
        AnalyticsEvent.paywallClosed.name,
        properties: {'source': widget.fromOnboarding ? 'onboarding' : 'in_app'},
      );
    }

    if (widget.fromOnboarding) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainTabView()),
          (route) => false,
        );
      }
    } else if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static List<_PlanOption> _sortedPlans(SubscriptionManager sub) {
    final options = <_PlanOption>[];
    for (final package in sub.availablePackages) {
      options.add(_PlanOption(product: package.storeProduct, package: package));
    }
    if (options.isEmpty) {
      for (final product in sub.storeProducts) {
        options.add(_PlanOption(product: product));
      }
    }

    options.sort((a, b) => _rank(a.product).compareTo(_rank(b.product)));
    return options;
  }

  static int _rank(StoreProduct product) {
    return switch (product.identifier) {
      AppConstants.yearlyProductId => 0,
      AppConstants.weeklyProductId => 1,
      _ => 2,
    };
  }

  static String _titleFor(_PlanOption plan) {
    return switch (plan.product.identifier) {
      AppConstants.weeklyProductId => '週訂閱',
      AppConstants.yearlyProductId => '年訂閱',
      _ => plan.product.title,
    };
  }

  static String _subtitleFor(_PlanOption plan) {
    return switch (plan.product.identifier) {
      AppConstants.yearlyProductId => '最適合長期清理與壓縮照片影片',
      AppConstants.weeklyProductId => '短期整理相簿時使用',
      _ => plan.product.identifier,
    };
  }

  static const _features = [
    _PaywallFeature(Icons.copy, '重複與相似照片整理', AppTheme.danger),
    _PaywallFeature(Icons.photo_library, '截圖、大型照片與影片篩選', AppTheme.warning),
    _PaywallFeature(Icons.compress, '影片壓縮節省空間', AppTheme.accent),
    _PaywallFeature(Icons.people, '聯絡人清理工具', AppTheme.primary),
    _PaywallFeature(Icons.lock, '私密空間保護重要照片', AppTheme.success),
    _PaywallFeature(Icons.swipe, '滑動式快速清理體驗', Colors.teal),
  ];
}

class _PlanOption {
  final StoreProduct product;
  final Package? package;

  const _PlanOption({required this.product, this.package});
}

class _PaywallFeature {
  final IconData icon;
  final String label;
  final Color color;

  const _PaywallFeature(this.icon, this.label, this.color);
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  final bool isLoading;

  const _EmptyPlans({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: const Text(
        '目前沒有可顯示的訂閱方案。請確認 RevenueCat 產品 ID 與 App Store Connect 產品一致。',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.isEnabled,
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isEnabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final bool isBestValue;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isBestValue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '最佳價值',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
