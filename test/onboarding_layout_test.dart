import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final device in {
    'iPhone landscape': const Size(844, 390),
    'iPad compact window': const Size(320, 480),
  }.entries) {
    testWidgets(
      '${device.key} can read every onboarding page without overflow',
      (tester) async {
        tester.view.physicalSize = device.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MaterialApp(home: OnboardingView()));
        await tester.pump();

        for (var page = 1; page <= 4; page++) {
          expect(find.text('$page/4'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final startLabel = tester
              .element(find.byType(OnboardingView))
              .l10n
              .onboardingStartFree;
          expect(find.text(page == 4 ? startLabel : '繼續'), findsOneWidget);
          if (page < 4) {
            await tester.tap(find.text('繼續'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final locale in LocaleController.supportedLocales) {
    for (final size in [const Size(320, 568), const Size(1024, 768)]) {
      testWidgets(
        '${locale.toLanguageTag()} all onboarding pages fit $size at 200%',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const OnboardingView(),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(OnboardingView));
          final strings = context.l10n;
          expect(
            Directionality.of(context),
            ['ar', 'he'].contains(locale.languageCode)
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          for (var page = 1; page <= 4; page++) {
            expect(find.text(strings.onboardingStep(page, 4)), findsOneWidget);
            expect(tester.takeException(), isNull);
            final action = find.text(
              page == 4
                  ? strings.onboardingStartFree
                  : strings.onboardingContinue,
            );
            expect(action, findsOneWidget);
            final rect = tester.getRect(action);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            if (page < 4) {
              await tester.tap(action);
              await tester.pumpAndSettle();
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
