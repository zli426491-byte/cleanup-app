import 'dart:ui' show SemanticsAction;

import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({Locale? locale, bool reduceMotion = false, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: const OnboardingView(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // Photos access is declined; onboarding continues to the feature steps.
  setUp(() => messenger.setMockMethodCallHandler(photos, (call) async => 2));
  tearDown(() => messenger.setMockMethodCallHandler(photos, null));

  testWidgets('primary actions are 44 point buttons exposed to VoiceOver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(locale: const Locale('en')));
    await tester.pump();

    final start = find.byKey(const ValueKey('onboarding-get-started'));
    final rect = tester.getRect(start);
    expect(rect.height, greaterThanOrEqualTo(44));
    final data = tester.getSemantics(start).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.label, 'Get started');

    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The segmented progress bar announces the step; artwork is decorative.
    expect(find.bySemanticsLabel('1/3'), findsOneWidget);
    final next = find.byKey(const ValueKey('onboarding-next'));
    expect(tester.getSemantics(next).getSemanticsData().label, 'Next');
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('reduced motion switches steps without animation frames', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byKey(const ValueKey('onboarding-step-1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('long German labels stay on screen at 200% on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(locale: const Locale('de'), reduceMotion: true, scale: 2),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-get-started')));
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('onboarding-next'));
    final rect = tester.getRect(next);
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.height, greaterThanOrEqualTo(44));
    expect(find.text('Weiter'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
