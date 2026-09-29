import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '41',
      buildSignature: '',
    );
  });

  for (final size in [const Size(320, 568), const Size(1024, 768)]) {
    for (final language in [const Locale('en'), const Locale('ar')]) {
      testWidgets(
        '$size ${language.languageCode}: navigation exposes selection, touch size and keyboard actions',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final sub = SubscriptionManager();
          final locales = LocaleController(initialLocale: language);
          await tester.pumpWidget(
            CleanupApp(
              hasCompletedOnboarding: true,
              subscriptionManager: sub,
              localeController: locales,
            ),
          );
          await tester.pump();
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          expect(
            tester
                .getSemantics(find.byKey(const ValueKey('main-tab-0')))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          expect(
            tester
                .getSemantics(find.byKey(const ValueKey('main-tab-1')))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isFalse,
          );
          // Extras is hidden until its features are complete.
          expect(find.byKey(const ValueKey('main-tab-2')), findsNothing);

          // Keyboard focus and Enter must switch tabs, not just mouse/touch input.
          final tab = find.byKey(const ValueKey('main-tab-1'));
          final label = find
              .descendant(of: tab, matching: find.byType(Text))
              .first;
          Focus.of(tester.element(label)).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(
            tester
                .getSemantics(tab)
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          expect(
            tester
                .getSemantics(find.byKey(const ValueKey('main-tab-0')))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isFalse,
          );
          expect(tester.takeException(), isNull);
          semantics.dispose();
          await tester.pumpWidget(const SizedBox());
          sub.dispose();
        },
      );
    }
  }

  testWidgets(
    'light pages and transparent app bars request dark status icons',
    (tester) async {
      final sub = SubscriptionManager();
      await tester.pumpWidget(
        CleanupApp(hasCompletedOnboarding: true, subscriptionManager: sub),
      );
      await tester.pump();
      final overlays = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(overlays, isNotEmpty);
      for (final overlay in overlays) {
        expect(overlay.value.statusBarBrightness, Brightness.light);
        expect(overlay.value.statusBarIconBrightness, Brightness.dark);
      }
      final appBar = AppTheme.lightTheme.appBarTheme.systemOverlayStyle!;
      expect(appBar.statusBarBrightness, Brightness.light);
      expect(appBar.statusBarIconBrightness, Brightness.dark);
      await tester.pumpWidget(const SizedBox());
      sub.dispose();
    },
  );

  test('shared normal-text and action colors maintain readable contrast', () {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return first > second
          ? (first + 0.05) / (second + 0.05)
          : (second + 0.05) / (first + 0.05);
    }

    for (final foreground in [
      AppTheme.primary,
      AppTheme.danger,
      AppTheme.warning,
      AppTheme.textSecondary,
      AppTheme.textMuted,
    ]) {
      for (final background in [AppTheme.cardBg, AppTheme.bg]) {
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      }
    }
    for (final gradient in [
      AppTheme.primaryGradient,
      AppTheme.dangerGradient,
    ]) {
      for (final color in gradient.colors) {
        expect(contrast(Colors.white, color), greaterThanOrEqualTo(4.5));
      }
    }
  });
}
