import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks Welcome and every feature step. The last step's action leads to the
/// paywall, which is covered by onboarding_completion_test.
Future<void> _walkSteps(
  WidgetTester tester,
  Size size, {
  bool settle = true,
}) async {
  Future<void> advance() =>
      settle
      ? tester.pumpAndSettle()
      : tester.pump().then((_) => tester.pump(const Duration(seconds: 1)));

  final context = tester.element(find.byType(OnboardingView));
  final strings = context.l10n;
  final start = find.byKey(const ValueKey('onboarding-get-started'));
  expect(start, findsOneWidget);
  expect(tester.takeException(), isNull);
  final startRect = tester.getRect(start);
  expect(startRect.left, greaterThanOrEqualTo(0));
  expect(startRect.right, lessThanOrEqualTo(size.width));
  expect(startRect.bottom, lessThanOrEqualTo(size.height));
  await tester.tap(start);
  await advance();

  for (var step = 1; step <= 3; step++) {
    expect(
      find.bySemanticsLabel(strings.onboardingStep(step, 3)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final next = find.byKey(const ValueKey('onboarding-next'));
    final rect = tester.getRect(next);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.bottom, lessThanOrEqualTo(size.height));
    expect(rect.height, greaterThanOrEqualTo(44));
    if (step < 3) {
      await tester.tap(next);
      await advance();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // Photos access is declined; onboarding continues to the feature steps.
  setUp(() => messenger.setMockMethodCallHandler(photos, (call) async => 2));
  tearDown(() => messenger.setMockMethodCallHandler(photos, null));

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
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OnboardingView(),
          ),
        );
        await tester.pump();
        await _walkSteps(tester, device.value, settle: false);
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
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
          final semantics = tester.ensureSemantics();
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
          expect(
            Directionality.of(context),
            ['ar', 'he'].contains(locale.languageCode)
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          await _walkSteps(tester, size);
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        },
      );
    }
  }
}
