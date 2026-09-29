import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/main_tab_view.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tracking = MethodChannel('app_tracking_transparency');
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  late int attRequests;
  late int permissionRequests;
  late SubscriptionManager subscription;
  late PhotoScannerService scanner;
  late LocaleController locales;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    attRequests = 0;
    permissionRequests = 0;
    subscription = SubscriptionManager();
    scanner = PhotoScannerService();
    locales = LocaleController();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '46',
      buildSignature: '',
    );
    messenger.setMockMethodCallHandler(tracking, (call) async {
      attRequests++;
      return 3;
    });
    // Photos access is declined: onboarding must still continue.
    messenger.setMockMethodCallHandler(photos, (call) async {
      if (call.method == 'requestPermissionExtend') {
        permissionRequests++;
        return 2;
      }
      return null;
    });
  });

  tearDown(() {
    subscription.dispose();
    scanner.dispose();
    locales.dispose();
    messenger.setMockMethodCallHandler(tracking, null);
    messenger.setMockMethodCallHandler(photos, null);
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<LocaleController>.value(value: locales),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const OnboardingView(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reachPaywall(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await tester.pumpAndSettle();
    expect(permissionRequests, 1);
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(PaywallView), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('hasCompletedOnboarding'),
      isNull,
    );
  }

  testWidgets(
    'Get started asks for Photos once and the steps lead to the paywall',
    (tester) async {
      await mount(tester);
      await reachPaywall(tester);
      expect(attRequests, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'closing the onboarding paywall twice completes onboarding once',
    (tester) async {
      await mount(tester);
      await reachPaywall(tester);
      final close = tester.widget<IconButton>(
        find.byKey(const ValueKey('paywall-close')),
      );
      close.onPressed!();
      close.onPressed!();
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'hasCompletedOnboarding',
        ),
        isTrue,
      );
      expect(find.byType(MainTabView), findsOneWidget);
      expect(find.byType(PaywallView), findsNothing);
      expect(attRequests, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
