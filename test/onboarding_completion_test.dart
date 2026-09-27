import 'dart:ui' show SemanticsAction;

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

class _PushObserver extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  const channel = MethodChannel('app_tracking_transparency');
  late int attRequests;
  late SubscriptionManager subscription;
  late PhotoScannerService scanner;
  late LocaleController locales;
  late _PushObserver observer;

  setUp(() {
    attRequests = 0;
    subscription = SubscriptionManager();
    scanner = PhotoScannerService();
    locales = LocaleController();
    observer = _PushObserver();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '43',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          attRequests++;
          return 3;
        });
  });

  tearDown(() {
    subscription.dispose();
    scanner.dispose();
    locales.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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
          navigatorObservers: [observer],
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

  Future<void> verifyFinished(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool('hasCompletedOnboarding'),
      isTrue,
    );
    expect(find.byType(MainTabView), findsOneWidget);
    expect(find.byType(PaywallView), findsNothing);
    expect(attRequests, 0);
    expect(observer.pushes, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('skip saves completion and opens the app immediately', (
    tester,
  ) async {
    await mount(tester);
    final semantics = tester.ensureSemantics();
    final skip = find.widgetWithText(TextButton, '跳過');
    final node = tester.getSemantics(skip);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await verifyFinished(tester);
    semantics.dispose();
  });

  testWidgets(
    'start free double activation navigates once without ATT or paywall',
    (tester) async {
      await mount(tester);
      for (var page = 1; page < 4; page++) {
        await tester.tap(find.text('繼續'));
        await tester.pumpAndSettle();
      }
      expect(find.text('4/4'), findsOneWidget);
      final button = tester.widget<InkWell>(find.byType(InkWell).last);
      button.onTap!();
      button.onTap!();
      await verifyFinished(tester);
    },
  );
}
