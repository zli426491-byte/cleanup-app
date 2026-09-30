import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/subscription_manager.dart';
import '../../models/storage_info.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../paywall/paywall_view.dart';
import '../v2/ui_kit.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.controller});

  final LocaleController controller;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _selectedKey = GlobalKey();
  bool _choosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedKey.currentContext;
      if (mounted && selectedContext != null) {
        Scrollable.ensureVisible(selectedContext, alignment: 0.5);
      }
    });
  }

  Future<void> _choose(Locale? locale) async {
    if (_choosing) return;
    setState(() => _choosing = true);
    try {
      await widget.controller.setLocale(locale);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _choosing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsLanguageSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = LocaleController.languageOptions;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                context.l10n.settingsChooseLanguage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('settings-language-list'),
                child: Column(
                  children: List.generate(options.length + 1, (index) {
                    final option = index == 0 ? null : options[index - 1];
                    final locale = option?.locale;
                    final selected = widget.controller.locale == locale;
                    return ListTile(
                      key: selected ? _selectedKey : null,
                      selected: selected,
                      title: Text(
                        option?.nativeName ??
                            context.l10n.settingsSystemLanguage,
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      enabled: !_choosing,
                      onTap: () => _choose(locale),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsViewState extends State<SettingsView> {
  StorageInfo? _storage;
  String? _version;

  @override
  void initState() {
    super.initState();
    StorageInfo.current().then((s) {
      if (mounted) setState(() => _storage = s);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionManager>();
    final localeController = context.watch<LocaleController>();
    final l10n = context.l10n;
    final storage = _storage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const PageTopBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(l10n.settingsTitle, style: AppTheme.largeTitle),
                ),
                _PlanCard(sub: sub),
                if (storage != null && !storage.isEstimate)
                  _Section(
                    title: l10n.settingsStorage,
                    rows: [
                      _Row(
                        icon: Icons.storage_rounded,
                        title: l10n.settingsStorageTotal,
                        value: storage.totalSpaceFormatted,
                      ),
                      _Row(
                        icon: Icons.pie_chart_rounded,
                        title: l10n.settingsStorageUsed,
                        value: storage.usedSpaceFormatted,
                      ),
                      _Row(
                        icon: Icons.check_circle_rounded,
                        title: l10n.settingsStorageAvailable,
                        value: storage.freeSpaceFormatted,
                        valueColor: AppTheme.successText,
                      ),
                    ],
                  ),
                _Section(
                  title: l10n.settingsGeneral,
                  rows: [
                    _Row(
                      key: const ValueKey('settings-language'),
                      icon: Icons.language_rounded,
                      title: l10n.settingsLanguage,
                      value: localeController.locale == null
                          ? l10n.settingsSystemLanguage
                          : localeController.localeLabel,
                      onTap: () => _chooseLanguage(localeController),
                    ),
                    _Row(
                      key: const ValueKey('settings-manage-subscription'),
                      icon: Icons.manage_accounts_rounded,
                      title: l10n.settingsManageSubscription,
                      onTap: _manageSubscription,
                    ),
                    _Row(
                      icon: Icons.restore_rounded,
                      title: sub.isLoading
                          ? l10n.settingsProcessingSubscription
                          : l10n.settingsRestorePurchases,
                      onTap: sub.isLoading ? null : () => _restore(sub),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.settingsAbout,
                  rows: [
                    _Row(
                      icon: Icons.privacy_tip_rounded,
                      title: l10n.settingsPrivacyPolicy,
                      onTap: () =>
                          launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
                    ),
                    _Row(
                      icon: Icons.description_rounded,
                      title: l10n.settingsTerms,
                      onTap: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
                    ),
                    _Row(
                      icon: Icons.star_rounded,
                      title: l10n.settingsRateApp,
                      onTap: () async {
                        final review = InAppReview.instance;
                        if (await review.isAvailable()) review.requestReview();
                      },
                    ),
                    _Row(
                      icon: Icons.info_rounded,
                      title: l10n.settingsVersion,
                      value: _version ?? l10n.settingsLoading,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(SubscriptionManager sub) async {
    final restored = await sub.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? context.l10n.settingsRestoredPro
              : context.localizeServiceMessage(sub.statusMessage),
        ),
      ),
    );
  }

  Future<void> _chooseLanguage(LocaleController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LanguageSheet(controller: controller),
    );
  }

  Future<void> _manageSubscription() async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {
      // The localized recovery message also covers unavailable storefront apps.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsManageUnavailable)),
    );
  }
}

/// Blue plan banner: current plan and, for free users, the upgrade action.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.sub});
  final SubscriptionManager sub;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = sub.isPro
        ? l10n.settingsProPlan
        : !sub.hasCheckedSubscription
        ? (sub.isLoading
              ? l10n.settingsCheckingSubscription
              : l10n.settingsSubscriptionUnknown)
        : l10n.settingsFreePlan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.bannerGradient,
          borderRadius: BorderRadius.circular(AppTheme.r20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status,
                      style: AppTheme.heading2.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (!sub.isPro) ...[
                const SizedBox(height: 14),
                if (!sub.hasCheckedSubscription && !sub.isPlaceholder)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: sub.isLoading ? null : sub.retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.paywallReloadPlans),
                  ),
                if (sub.hasCheckedSubscription)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: sub.isLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaywallView(),
                              ),
                            ),
                      child: Text(
                        l10n.settingsUpgrade,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TintCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 52,
                    color: AppTheme.divider,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.body.copyWith(color: AppTheme.textTitle),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: AppTheme.caption.copyWith(
                      color: valueColor ?? AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
