import 'dart:async';

import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class _PushObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

void main() {
  const channel = MethodChannel('app_tracking_transparency');
  late Completer<int> att;
  late int requests;
  late SubscriptionManager subscription;
  late _PushObserver observer;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    requests = 0;
    subscription = SubscriptionManager();
    observer = _PushObserver();
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '37',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'requestTrackingAuthorization');
          requests++;
          return att.future;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    subscription.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> lastPage(WidgetTester tester) async {
    att = Completer<int>();
    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionManager>.value(
        value: subscription,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const OnboardingView(),
        ),
      ),
    );
    await tester.tap(find.text('跳過'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('4/4'), findsOneWidget);
  }

  testWidgets('double tap waits for one ATT request and pushes one paywall', (
    tester,
  ) async {
    await lastPage(tester);
    await tester.tap(find.text('開始使用'));
    await tester.tap(find.text('開始使用'));
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
    expect(requests, 1);
    expect(find.text('正在準備…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    att.complete(3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(observer.pushes, 2); // Initial page plus one paywall.
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'leaving onboarding during ATT does not navigate after disposal',
    (tester) async {
      await lastPage(tester);
      await tester.tap(find.text('開始使用'));
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox.shrink());
      att.complete(3);
      await tester.pump();
      expect(observer.pushes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
