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
              ListTile(
                leading: Icon(
                  sub.isPro
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: sub.isPro ? Colors.amber : Colors.grey,
                ),
                title: Text(
                  sub.isPro
                      ? context.l10n.settingsProPlan
                      : context.l10n.settingsFreePlan,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: sub.isPro
                    ? null
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.35,
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaywallView(),
                            ),
                          ),
                          child: Text(
                            context.l10n.settingsUpgrade,
                            textAlign: TextAlign.center,
                          ),
                        ),
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
    var choosing = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final options = LocaleController.languageOptions;
        Future<void> choose(Locale? locale) async {
          if (choosing) return;
          choosing = true;
          try {
            await controller.setLocale(locale);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          } catch (_) {
            choosing = false;
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(sheetContext.l10n.settingsLanguageSaveError),
                ),
              );
            }
          }
        }

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    sheetContext.l10n.settingsChooseLanguage,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length + 1,
                    itemBuilder: (_, index) {
                      final option = index == 0 ? null : options[index - 1];
                      final locale = option?.locale;
                      final selected = controller.locale == locale;
                      return ListTile(
                        selected: selected,
                        title: Text(
                          option?.nativeName ??
                              sheetContext.l10n.settingsSystemLanguage,
                        ),
                        trailing: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        onTap: () => choose(locale),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      trailing: Text(
        value,
        style: TextStyle(color: valueColor ?? Colors.grey[600]),
      ),
    );
  }
}
