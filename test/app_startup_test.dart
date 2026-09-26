import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';

class _DelayedSubscriptionManager extends SubscriptionManager {
  final initialization = Completer<void>();
  bool initializationStarted = false;

  @override
  Future<void> init({required bool isIos}) {
    initializationStarted = true;
    return initialization.future;
  }
}

void main() {
  testWidgets('dark system appearance keeps the supported light color scheme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final subscriptions = _DelayedSubscriptionManager();
    launchCleanupApp(
      hasCompletedOnboarding: false,
      subscriptionManager: subscriptions,
      isIos: true,
    );
    await tester.pump();

    final theme = Theme.of(tester.element(find.byType(OnboardingView)));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppTheme.bg);

    subscriptions.initialization.complete();
    await tester.pumpWidget(const SizedBox());
    subscriptions.dispose();
  });

  testWidgets(
    'the first screen appears while store initialization is pending',
    (tester) async {
      final subscriptions = _DelayedSubscriptionManager();
      launchCleanupApp(
        hasCompletedOnboarding: false,
        subscriptionManager: subscriptions,
        isIos: true,
      );
      await tester.pump();

      expect(subscriptions.initializationStarted, isTrue);
      expect(subscriptions.initialization.isCompleted, isFalse);
      expect(find.byType(OnboardingView), findsOneWidget);
      expect(find.text('繼續'), findsOneWidget);

      subscriptions.initialization.complete();
      await tester.pumpWidget(const SizedBox());
      subscriptions.dispose();
    },
  );

  testWidgets(
    'failed background store initialization leaves the screen usable',
    (tester) async {
      final subscriptions = _DelayedSubscriptionManager();
      launchCleanupApp(
        hasCompletedOnboarding: false,
        subscriptionManager: subscriptions,
        isIos: true,
      );
      await tester.pump();
      subscriptions.initialization.completeError(StateError('offline'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(OnboardingView), findsOneWidget);
      await tester.tap(find.text('繼續'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('2/4'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      subscriptions.dispose();
    },
  );
}
