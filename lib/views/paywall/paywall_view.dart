import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:photo_manager/photo_manager.dart' show AssetType;

import '../../analytics/analytics_manager.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../home/main_tab_view.dart';
import '../v2/ui_kit.dart';

/// A: after onboarding, framed around the free trial.
/// B: when a free user starts a Pro action ("Unlock Unlimited Access").
enum PaywallVariant { trial, unlock }

/// Explicit result from the in-app unlock offer. Closing the offer is never
/// consent to continue a pending deletion.
enum PaywallUnlockResult { cancelled, continueFree, purchased }

class PaywallView extends StatefulWidget {
  final bool fromOnboarding;
  final PaywallVariant variant;
  final String? source;

  /// Free cleanups available through the explicit continuation action (B only).
  final int? freeCleanupsLeft;

  const PaywallView({
    super.key,
    this.fromOnboarding = false,
    PaywallVariant? variant,
    this.source,
    this.freeCleanupsLeft,
  }) : variant =
           variant ??
           (fromOnboarding ? PaywallVariant.trial : PaywallVariant.unlock);

  /// Presents variant B and completes when it closes.
  static Future<PaywallUnlockResult> showUnlock(
    BuildContext context, {
    required String source,
    int? freeCleanupsLeft,
  }) async =>
      await Navigator.of(context).push<PaywallUnlockResult>(
        MaterialPageRoute<PaywallUnlockResult>(
          fullscreenDialog: true,
          builder: (_) => PaywallView(
            variant: PaywallVariant.unlock,
            source: source,
            freeCleanupsLeft: freeCleanupsLeft,
          ),
        ),
      ) ??
      PaywallUnlockResult.cancelled;

  /// Trial length of the plan this paywall preselects, so a teaser shown
  /// before it promises exactly what the next page offers.
  static int? leadingTrialDays(SubscriptionManager sub) {
    for (final plan in _PaywallViewState._sortedPlans(sub)) {
      final days = sub.freeTrialDays(plan.product);
      if (days != null) return days;
    }
    return null;
  }

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  _PlanOption? _selectedPlan;
  bool _userPickedPlan = false;
  bool _isPurchasing = false;
  bool _hasTrackedClose = false;
  bool _isDismissing = false;
  String? _buildNumber;

  bool get _pageIsActive =>
      mounted && !_isDismissing && (ModalRoute.of(context)?.isCurrent ?? true);

  String get _source =>
      widget.source ?? (widget.fromOnboarding ? 'onboarding' : 'in_app');

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.track(
      AnalyticsEvent.paywallShown.name,
      properties: {'source': _source, 'variant': widget.variant.name},
    );
    if (kDebugMode) _loadBuildNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();
    final plans = _sortedPlans(sub);
    if (plans.isEmpty) {
      _selectedPlan = null;
    } else if (!_userPickedPlan) {
      // Lead with a plan that really has a free trial for this customer.
      _selectedPlan = plans.firstWhere(
        (plan) => sub.freeTrialDays(plan.product) != null,
        orElse: () => plans.firstWhere(
          (plan) =>
              plan.product.identifier == _selectedPlan?.product.identifier,
          orElse: () => plans.first,
        ),
      );
    } else {
      _selectedPlan = plans.firstWhere(
        (plan) => plan.product.identifier == _selectedPlan?.product.identifier,
        orElse: () => plans.first,
      );
    }
    final canPurchase =
        !sub.isPlaceholder &&
        _selectedPlan != null &&
        !sub.isLoading &&
        !_isPurchasing;
    final trialDays = _selectedPlan == null
        ? null
        : sub.freeTrialDays(_selectedPlan!.product);

    final purchaseButton = _PurchaseButton(
      isEnabled: canPurchase,
      isLoading: sub.isLoading || _isPurchasing,
      label: sub.isPlaceholder
          ? context.l10n.paywallNotConfigured
          : trialDays != null
          ? (widget.variant == PaywallVariant.trial
                ? context.l10n.v2TryFree
                : context.l10n.v2StartFreeTrial(trialDays))
          : _purchaseLabel,
      loadingLabel: _loadingLabel(sub),
      onTap: () => _purchase(sub),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _isDismissing = true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _topBar(sub),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.variant == PaywallVariant.trial)
                            ..._trialHeader(sub, trialDays)
                          else
                            ..._unlockHeader(),
                          if (kDebugMode && _buildNumber != null)
                            Text(
                              context.l10n.paywallBuild(_buildNumber!),
                              textAlign: TextAlign.center,
                              style: AppTheme.small,
                            ),
                          if (sub.statusMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _StatusBanner(
                              message: context.localizeServiceMessage(
                                sub.statusMessage,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (plans.isEmpty) ...[
                            _EmptyPlans(isLoading: sub.isLoading),
                            TextButton.icon(
                              onPressed: sub.isLoading
                                  ? null
                                  : () => sub.retry(),
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.paywallReloadPlans),
                            ),
                          ] else if (widget.variant == PaywallVariant.unlock ||
                              trialDays == null)
                            ...plans.map(
                              (plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PlanCard(
                                  key: ValueKey(
                                    'paywall-plan-${plan.product.identifier}',
                                  ),
                                  title: _priceLine(plan),
                                  subtitle: _planSubtitle(sub, plan),
                                  badge: _savingsBadge(plan, plans),
                                  isSelected:
                                      plan.product.identifier ==
                                      _selectedPlan?.product.identifier,
                                  onTap: sub.isLoading || _isPurchasing
                                      ? null
                                      : () => setState(() {
                                          _userPickedPlan = true;
                                          _selectedPlan = plan;
                                        }),
                                ),
                              ),
                            )
                          else
                            _TrialTimeline(
                              days: trialDays,
                              price: _selectedPlan!.product.priceString,
                              dueToday:
                                  _selectedPlan!
                                      .product
                                      .introductoryPrice
                                      ?.priceString ??
                                  '',
                            ),
                          if (_selectedPlan != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                              child: Text(
                                _renewalNotice,
                                textAlign: TextAlign.center,
                                style: AppTheme.small.copyWith(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: purchaseButton,
                  ),
                  if (widget.variant == PaywallVariant.unlock &&
                      widget.freeCleanupsLeft != null &&
                      widget.freeCleanupsLeft! > 0 &&
                      !sub.isPro)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const ValueKey('paywall-continue-free'),
                          onPressed: _isPurchasing || _isDismissing
                              ? null
                              : () => _dismiss(
                                  context,
                                  result: PaywallUnlockResult.continueFree,
                                ),
                          child: Text(
                            context.l10n.v2ContinueFreeCleanup(
                              widget.freeCleanupsLeft!,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  _footer(sub),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(SubscriptionManager sub) {
    final close = IconButton(
      key: const ValueKey('paywall-close'),
      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
      tooltip: context.l10n.paywallClose,
      onPressed: () => _dismiss(context),
    );
    if (widget.variant == PaywallVariant.unlock) {
      return Align(alignment: AlignmentDirectional.centerStart, child: close);
    }
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: sub.isPlaceholder || sub.isLoading
                  ? null
                  : () => _restore(sub),
              child: Text(
                context.l10n.paywallRestorePurchases,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ),
        ),
        close,
      ],
    );
  }

  List<Widget> _trialHeader(SubscriptionManager sub, int? trialDays) {
    final l10n = context.l10n;
    final scanner = context.watch<PhotoScannerService>();
    var photos = 0;
    var videos = 0;
    for (final asset in scanner.scanResult.allAssets) {
      if (asset.type == AssetType.video) {
        videos++;
      } else {
        photos++;
      }
    }
    return [
      Text(
        l10n.v2CleanYourStorage,
        textAlign: TextAlign.center,
        style: AppTheme.heading1.copyWith(fontSize: 30),
      ),
      const SizedBox(height: 6),
      Text(
        l10n.v2GetRidOf,
        textAlign: TextAlign.center,
        style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 36,
        runSpacing: 16,
        children: [
          _BadgeIcon(
            icon: Icons.photo_library_rounded,
            label: l10n.scanCategoryPhotos,
            badge: photos,
            colors: const [Color(0xFFFFB347), Color(0xFFFF5E62)],
          ),
          _BadgeIcon(
            icon: Icons.video_library_rounded,
            label: l10n.v2CatVideos,
            badge: videos,
            colors: const [Color(0xFF5AC8FA), Color(0xFF0A7AFF)],
          ),
        ],
      ),
      const SizedBox(height: 24),
      TintCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.appName} Pro',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(l10n.v2ProFeatures, style: AppTheme.caption),
            if (trialDays != null && _selectedPlan != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.v2FreeThen(trialDays, _priceLine(_selectedPlan!)),
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
      if (trialDays != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.v2TrialEnabled, style: AppTheme.heading3),
              ),
              const Icon(Icons.verified_rounded, color: AppTheme.success),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _unlockHeader() {
    final l10n = context.l10n;
    final features = [
      (Icons.donut_large_rounded, l10n.v2UnlockFeature1),
      (Icons.all_inclusive_rounded, l10n.v2UnlockFeature2),
      (Icons.savings_rounded, l10n.v2UnlockFeature3),
    ];
    return [
      const SizedBox(height: 8),
      Text(
        l10n.v2UnlockTitle,
        textAlign: TextAlign.center,
        style: AppTheme.heading1.copyWith(fontSize: 32),
      ),
      const SizedBox(height: 24),
      for (final (icon, label) in features)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.v2PrivacyLine,
              textAlign: TextAlign.center,
              style: AppTheme.small,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _footer(SubscriptionManager sub) {
    final links = [
      TextButton(
        onPressed: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
        child: Text(
          context.l10n.paywallTerms,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ),
      if (widget.variant == PaywallVariant.trial)
        TextButton(
          onPressed: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
          child: Text(
            context.l10n.paywallPrivacyPolicy,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        )
      else
        TextButton(
          onPressed: sub.isPlaceholder || sub.isLoading
              ? null
              : () => _restore(sub),
          child: Text(
            context.l10n.paywallRestorePurchases,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(alignment: WrapAlignment.spaceBetween, children: links),
    );
  }

  String _priceLine(_PlanOption plan) => switch (plan.product.identifier) {
    AppConstants.weeklyProductId => context.l10n.v2PerWeek(
      plan.product.priceString,
    ),
    AppConstants.yearlyProductId => context.l10n.v2PerYear(
      plan.product.priceString,
    ),
    _ => '${_titleFor(plan)} · ${plan.product.priceString}',
  };

  String _planSubtitle(SubscriptionManager sub, _PlanOption plan) {
    final days = sub.freeTrialDays(plan.product);
    if (days != null) return context.l10n.v2FreeTrialDays(days);
    return _subtitleFor(plan);
  }

  /// "Save N%" on the yearly plan versus paying weekly for a year.
  String? _savingsBadge(_PlanOption plan, List<_PlanOption> plans) {
    if (plan.product.identifier != AppConstants.yearlyProductId) return null;
    final weekly = plans.where(
      (p) => p.product.identifier == AppConstants.weeklyProductId,
    );
    if (weekly.isEmpty) return null;
    final perYearWeekly = weekly.first.product.price * 52;
    if (perYearWeekly <= 0) return null;
    final percent = ((1 - plan.product.price / perYearWeekly) * 100).floor();
    return percent >= 5 ? context.l10n.v2SavePercent(percent) : null;
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
      _dismiss(context, result: PaywallUnlockResult.purchased);
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
      _dismiss(context, result: PaywallUnlockResult.purchased);
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

  Future<void> _dismiss(
    BuildContext context, {
    PaywallUnlockResult result = PaywallUnlockResult.cancelled,
  }) async {
    if (!_pageIsActive) return;
    _isDismissing = true;
    if (!_hasTrackedClose) {
      _hasTrackedClose = true;
      AnalyticsManager.instance.track(
        AnalyticsEvent.paywallClosed.name,
        properties: {'source': _source, 'variant': widget.variant.name},
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
        Navigator.pop(context, result);
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
}

class _PlanOption {
  final StoreProduct product;
  final Package? package;

  const _PlanOption({required this.product, this.package});
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
  final String? badge;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        enabled: onTap != null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: isSelected ? AppTheme.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTheme.small),
                    ],
                  ),
                ),
              ),
            ),
            if (badge != null)
              PositionedDirectional(
                end: 0,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rounded app icon with a red count badge (Photos / Videos).
class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.label,
    required this.badge,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final int badge;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
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
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  badge > 999 ? '999+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(label, style: AppTheme.heading3.copyWith(fontSize: 15)),
    ],
  );
}

/// "Due today – N days free – 0" / "Due (date) – price" for a trial plan.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({
    required this.days,
    required this.price,
    required this.dueToday,
  });
  final int days;
  final String price;

  /// The store-formatted introductory price (a zero amount in local currency).
  final String dueToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.now().add(Duration(days: days)));
    Widget row(String label, Widget trailing, {bool first = false}) => Row(
      children: [
        Icon(
          first ? Icons.radio_button_checked_rounded : Icons.circle,
          size: first ? 14 : 10,
          color: AppTheme.textTitle,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: trailing,
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        children: [
          row(
            l10n.v2DueToday,
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.v2DaysFree(days),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dueToday,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            first: true,
          ),
          const SizedBox(height: 14),
          row(
            l10n.v2DueOn(due),
            Text(
              price,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
