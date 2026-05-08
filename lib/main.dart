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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsManager.instance.configure();
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  // Initialize subscription manager safely (handles placeholder keys)
  final subscriptionManager = SubscriptionManager();
  try {
    await subscriptionManager.init(isIos: Platform.isIOS);
  } catch (e) {
    debugPrint('SubscriptionManager init failed (safe): $e');
  }

  runApp(CleanupApp(
    hasCompletedOnboarding: hasCompletedOnboarding,
    subscriptionManager: subscriptionManager,
  ));
}

class CleanupApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  final SubscriptionManager subscriptionManager;
  const CleanupApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.subscriptionManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: subscriptionManager),
        ChangeNotifierProvider(create: (_) => PhotoScannerService()),
        ChangeNotifierProvider(create: (_) => ContactsCleanupService()),
        ChangeNotifierProvider(create: (_) => SecretSpaceService()),
      ],
      child: MaterialApp(
        title: 'Cleanup',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: hasCompletedOnboarding
            ? const MainTabView()
            : const OnboardingView(),
      ),
    );
  }
}
