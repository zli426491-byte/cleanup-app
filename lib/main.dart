import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/subscription_manager.dart';
import 'services/photo_scanner_service.dart';
import 'services/contacts_service.dart';
import 'services/secret_space_service.dart';
import 'analytics/analytics_manager.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/home/main_tab_view.dart';
import 'utils/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsManager.instance.configure();
  final prefs = await SharedPreferences.getInstance();
  final localeController = await LocaleController.load(prefs);
  final hasCompletedOnboarding =
      prefs.getBool('hasCompletedOnboarding') ?? false;

  final subscriptionManager = SubscriptionManager();
  launchCleanupApp(
    hasCompletedOnboarding: hasCompletedOnboarding,
    subscriptionManager: subscriptionManager,
    isIos: Platform.isIOS,
    localeController: localeController,
  );
}

/// Photo review remains available while the store initializes or is offline.
void launchCleanupApp({
  required bool hasCompletedOnboarding,
  required SubscriptionManager subscriptionManager,
  required bool isIos,
  LocaleController? localeController,
}) {
  runApp(
    CleanupApp(
      hasCompletedOnboarding: hasCompletedOnboarding,
      subscriptionManager: subscriptionManager,
      localeController: localeController,
    ),
  );
  unawaited(_initializeSubscriptions(subscriptionManager, isIos: isIos));
}

Future<void> _initializeSubscriptions(
  SubscriptionManager subscriptionManager, {
  required bool isIos,
}) async {
  try {
    await subscriptionManager.init(isIos: isIos);
  } catch (e) {
    debugPrint('SubscriptionManager init failed (safe): $e');
  }
}

class CleanupApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  final SubscriptionManager subscriptionManager;
  final LocaleController? localeController;
  const CleanupApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.subscriptionManager,
    this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => localeController ?? LocaleController(),
        ),
        ChangeNotifierProvider.value(value: subscriptionManager),
        ChangeNotifierProvider(create: (_) => PhotoScannerService()),
        ChangeNotifierProvider(create: (_) => ContactsCleanupService()),
        ChangeNotifierProvider(create: (_) => SecretSpaceService()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, languages, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          locale: languages.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocaleController.supportedLocales,
          localeListResolutionCallback: LocaleController.resolve,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: hasCompletedOnboarding
              ? const MainTabView()
              : const OnboardingView(),
        ),
      ),
    );
  }
}
