import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
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
  bool _isDismissing = false;
  String? _buildNumber;

  bool get _pageIsActive =>
      mounted && !_isDismissing && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.track(
      AnalyticsEvent.paywallShown.name,
      properties: {'source': widget.fromOnboarding ? 'onboarding' : 'in_app'},
    );
    if (kDebugMode) _loadBuildNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();
    final plans = _sortedPlans(sub);
    _selectedPlan = plans.isEmpty
        ? null
        : plans.firstWhere(
            (plan) =>
                plan.product.identifier == _selectedPlan?.product.identifier,
            orElse: () => plans.first,
          );
    final canPurchase =
        !sub.isPlaceholder &&
        _selectedPlan != null &&
        !sub.isLoading &&
        !_isPurchasing;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _isDismissing = true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const SizedBox(),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: context.l10n.paywallClose,
              onPressed: () => _dismiss(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
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
                    Text(
                      context.l10n.paywallTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (kDebugMode && _buildNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.paywallBuild(_buildNumber!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.paywallDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.paywallFreePreviewNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (sub.statusMessage.isNotEmpty) ...[
                      _StatusBanner(
                        message: context.localizeServiceMessage(
                          sub.statusMessage,
                        ),
                      ),
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
                    if (plans.isEmpty) ...[
                      _EmptyPlans(isLoading: sub.isLoading),
                      TextButton.icon(
                        onPressed: sub.isLoading ? null : () => sub.retry(),
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.paywallReloadPlans),
                      ),
                    ] else
                      ...plans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PlanCard(
                            key: ValueKey(
                              'paywall-plan-${plan.product.identifier}',
                            ),
                            title: _titleFor(plan),
                            subtitle: _subtitleFor(plan),
                            price: plan.product.priceString,
                            isSelected:
                                plan.product.identifier ==
                                _selectedPlan?.product.identifier,
                            onTap: sub.isLoading || _isPurchasing
                                ? null
                                : () => setState(() => _selectedPlan = plan),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _PurchaseButton(
                      isEnabled: canPurchase,
                      isLoading: sub.isLoading || _isPurchasing,
                      label: sub.isPlaceholder
                          ? context.l10n.paywallNotConfigured
                          : _purchaseLabel,
                      loadingLabel: _loadingLabel(sub),
                      onTap: () => _purchase(sub),
                    ),
                    if (_selectedPlan != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _renewalNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.paywallStoreNotice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: sub.isPlaceholder || sub.isLoading
                              ? null
                              : () => _restore(sub),
                          child: Text(
                            context.l10n.paywallRestorePurchases,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.privacyPolicyUrl),
                          ),
                          child: Text(
                            context.l10n.paywallPrivacyPolicy,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              launchUrl(Uri.parse(AppConstants.termsUrl)),
                          child: Text(
                            context.l10n.paywallTerms,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    final sub = context.read<SubscriptionManager>();
    if (!sub.isInitializing &&
        sub.availablePackages.isEmpty &&
        sub.storeProducts.isEmpty) {
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
    if (!_pageIsActive ||
        plan == null ||
        sub.isPlaceholder ||
        sub.isLoading ||
        _isPurchasing) {
      return;
    }

    setState(() => _isPurchasing = true);
    final didPurchase = plan.package == null
        ? await sub.purchaseStoreProduct(plan.product)
        : await sub.purchase(plan.package!);
    if (!mounted || !_pageIsActive) return;
    setState(() => _isPurchasing = false);

    if (didPurchase) {
      // A successful client flow confirms access, not trial eligibility or
      // money collected. RevenueCat transactions own lifecycle and revenue.
      AnalyticsManager.instance.track(
        AnalyticsEvent.purchaseCompleted.name,
        properties: {
          'product_id': plan.product.identifier,
          'pro_unlocked': true,
        },
      );
      _dismiss(context);
    } else {
      _showMessage(
        sub.statusMessage.isNotEmpty
            ? context.localizeServiceMessage(sub.statusMessage)
            : context.l10n.paywallPurchaseIncomplete,
      );
    }
  }

  Future<void> _restore(SubscriptionManager sub) async {
    if (!_pageIsActive || sub.isLoading) return;
    final restored = await sub.restorePurchases();
    if (!mounted || !_pageIsActive) return;

    if (restored) {
      _showMessage(context.l10n.paywallRestored);
      _dismiss(context);
    } else {
      _showMessage(
        sub.statusMessage.isNotEmpty
            ? context.localizeServiceMessage(sub.statusMessage)
            : context.l10n.paywallRestoreNotFound,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _dismiss(BuildContext context) async {
    if (!_pageIsActive) return;
    _isDismissing = true;
    if (!_hasTrackedClose) {
      _hasTrackedClose = true;
      AnalyticsManager.instance.track(
        AnalyticsEvent.paywallClosed.name,
        properties: {'source': widget.fromOnboarding ? 'onboarding' : 'in_app'},
      );
    }

    try {
      if (widget.fromOnboarding) {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setBool('hasCompletedOnboarding', true)) {
          throw StateError('Onboarding preference was not saved');
        }
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainTabView()),
            (route) => false,
          );
        }
      } else if (context.mounted &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _isDismissing = false;
        _showMessage(context.l10n.serviceOperationFailed);
      }
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

  String _titleFor(_PlanOption plan) {
    return switch (plan.product.identifier) {
      AppConstants.weeklyProductId => context.l10n.paywallWeeklyPlan,
      AppConstants.yearlyProductId => context.l10n.paywallYearlyPlan,
      _ => plan.product.title,
    };
  }

  String _subtitleFor(_PlanOption plan) {
    return switch (plan.product.identifier) {
      AppConstants.yearlyProductId => context.l10n.paywallYearlySubtitle,
      AppConstants.weeklyProductId => context.l10n.paywallWeeklySubtitle,
      _ => context.l10n.paywallDescription,
    };
  }

  String get _purchaseLabel => switch (_selectedPlan?.product.identifier) {
    AppConstants.yearlyProductId => context.l10n.paywallSubscribeYearly(
      _selectedPlan!.product.priceString,
    ),
    AppConstants.weeklyProductId => context.l10n.paywallSubscribeWeekly(
      _selectedPlan!.product.priceString,
    ),
    _ => context.l10n.paywallSubscribe,
  };

  String get _renewalNotice => switch (_selectedPlan?.product.identifier) {
    AppConstants.yearlyProductId => context.l10n.paywallYearlyRenewal(
      _selectedPlan!.product.priceString,
    ),
    AppConstants.weeklyProductId => context.l10n.paywallWeeklyRenewal(
      _selectedPlan!.product.priceString,
    ),
    _ => context.l10n.paywallRenewalGeneric,
  };

  String _loadingLabel(SubscriptionManager sub) => switch (sub.operation) {
    SubscriptionOperation.purchasing => context.l10n.paywallWaitingForStore,
    SubscriptionOperation.restoring => context.l10n.paywallRestoring,
    _ =>
      _isPurchasing
          ? context.l10n.paywallWaitingForStore
          : context.l10n.paywallLoadingPlans,
  };

  List<_PaywallFeature> get _features => [
    _PaywallFeature(
      Icons.copy,
      context.l10n.paywallPhotoFeature,
      AppTheme.danger,
    ),
    _PaywallFeature(
      Icons.compress,
      context.l10n.paywallVideoFeature,
      AppTheme.warning,
    ),
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
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Text(
        context.l10n.paywallPlansUnavailable,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final String label;
  final String loadingLabel;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.isEnabled,
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      liveRegion: isLoading,
      label: isLoading ? loadingLabel : label,
      onTap: isEnabled ? onTap : null,
      excludeSemantics: true,
      child: Opacity(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              loadingLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
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
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        enabled: onTap != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.05)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 8),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
