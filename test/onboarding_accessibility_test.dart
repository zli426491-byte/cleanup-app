import 'dart:ui' show SemanticsAction;

import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  testWidgets(
    'skip is a trailing button with at least a 44 point touch target',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingView()),
      );
      await tester.pump();
      final skip = find.widgetWithText(TextButton, '跳過');
      final rect = tester.getRect(skip);
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(rect.right, closeTo(390 - 24, 1));
      final skipData = tester.getSemantics(skip).getSemanticsData();
      expect(skipData.flagsCollection.isButton, isTrue);
      expect(skipData.hasAction(SemanticsAction.tap), isTrue);
      final indicator = find.byType(SmoothPageIndicator);
      expect(
        find.ancestor(of: indicator, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );

  testWidgets(
    'reduced motion stops artwork and live changes restart or stop it',
    (tester) async {
      final reduced = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: value),
              child: child!,
            ),
          ),
          home: const OnboardingView(),
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(find.text('繼續'));
      await tester.pump();
      expect(find.text('2/4'), findsOneWidget);
      await tester.pumpAndSettle();

      reduced.value = false;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      reduced.value = true;
      await tester.pump();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text('2/4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      reduced.dispose();
    },
  );

  testWidgets(
    'long skip label remains trailing at 200% text on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const OnboardingView(),
        ),
      );
      await tester.pump();
      final skip = find.widgetWithText(TextButton, 'Überspringen');
      final rect = tester.getRect(skip);
      expect(rect.right, closeTo(320 - 24, 1));
      expect(rect.height, greaterThanOrEqualTo(44));
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2/4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
