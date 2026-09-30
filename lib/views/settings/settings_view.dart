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

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sub.isPro
                                ? context.l10n.settingsProPlan
                                : !sub.hasCheckedSubscription
                                ? (sub.isLoading
                                      ? context
                                            .l10n
                                            .settingsCheckingSubscription
                                      : context
                                            .l10n
                                            .settingsSubscriptionUnknown)
                                : context.l10n.settingsFreePlan,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (!sub.isPro) ...[
                      const SizedBox(height: 12),
                      if (!sub.hasCheckedSubscription && !sub.isPlaceholder)
                        TextButton.icon(
                          onPressed: sub.isLoading ? null : sub.retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.paywallReloadPlans),
                        ),
                      if (sub.hasCheckedSubscription)
                        OutlinedButton(
                          onPressed: sub.isLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaywallView(),
                                  ),
                                ),
                          child: Text(context.l10n.settingsUpgrade),
                        ),
                    ],
                  ],
                ),
              ),
              const Divider(),

              if (_storage != null && !_storage!.isEstimate) ...[
                _settingsHeader(context.l10n.settingsStorage),
                _settingsRow(
                  context.l10n.settingsStorageTotal,
                  _storage!.totalSpaceFormatted,
                ),
                _settingsRow(
                  context.l10n.settingsStorageUsed,
                  _storage!.usedSpaceFormatted,
                ),
                _settingsRow(
                  context.l10n.settingsStorageAvailable,
                  _storage!.freeSpaceFormatted,
                  valueColor: AppTheme.success,
                ),
                const Divider(),
              ],

              _settingsHeader(context.l10n.settingsGeneral),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.settingsLanguage),
                subtitle: Text(
                  localeController.locale == null
                      ? context.l10n.settingsSystemLanguage
                      : localeController.localeLabel,
                ),
                onTap: () => _chooseLanguage(localeController),
              ),
              ListTile(
                key: const ValueKey('settings-manage-subscription'),
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(context.l10n.settingsManageSubscription),
                onTap: _manageSubscription,
              ),
              ListTile(
                title: Text(
                  sub.isLoading
                      ? context.l10n.settingsProcessingSubscription
                      : context.l10n.settingsRestorePurchases,
                ),
                onTap: sub.isLoading
                    ? null
                    : () async {
                        final restored = await sub.restorePurchases();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              restored
                                  ? context.l10n.settingsRestoredPro
                                  : context.localizeServiceMessage(
                                      sub.statusMessage,
                                    ),
                            ),
                          ),
                        );
                      },
              ),
              ListTile(
                title: Text(context.l10n.settingsPrivacyPolicy),
                onTap: () =>
                    launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
              ),
              ListTile(
                title: Text(context.l10n.settingsTerms),
                onTap: () => launchUrl(Uri.parse(AppConstants.termsUrl)),
              ),
              ListTile(
                title: Text(context.l10n.settingsRateApp),
                onTap: () async {
                  final review = InAppReview.instance;
                  if (await review.isAvailable()) review.requestReview();
                },
              ),
              const Divider(),

              _settingsHeader(context.l10n.settingsAbout),
              _settingsRow(
                context.l10n.settingsVersion,
                _version ?? context.l10n.settingsLoading,
              ),
            ],
          ),
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

  Widget _settingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {Color? valueColor}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(color: valueColor ?? Colors.grey[600]),
      ),
    );
  }
}
