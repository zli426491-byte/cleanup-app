import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Subscription extends SubscriptionManager {
  bool confirmed = false;
  bool checking = false;
  @override
  bool get isPlaceholder => false;
  @override
  bool get hasCheckedSubscription => confirmed;
  @override
  bool get isLoading => checking;
}

void main() {
  const launcher = MethodChannel('plugins.flutter.io/url_launcher');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '43',
      buildSignature: '',
    );
  });

  Future<void> mount(
    WidgetTester tester,
    _Subscription sub,
    LocaleController locales, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SubscriptionManager>.value(value: sub),
          ChangeNotifierProvider<LocaleController>.value(value: locales),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locales.locale ?? const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SettingsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'settings distinguishes unknown, checking and confirmed free access',
    (tester) async {
      final sub = _Subscription();
      final locales = LocaleController();
      await mount(tester, sub, locales);
      final strings = tester.element(find.byType(SettingsView)).l10n;
      expect(find.text(strings.settingsSubscriptionUnknown), findsOneWidget);
      expect(find.text(strings.settingsFreePlan), findsNothing);
      expect(find.text(strings.settingsUpgrade), findsNothing);
      sub.checking = true;
      sub.notifyListeners();
      await tester.pump();
      expect(find.text(strings.settingsCheckingSubscription), findsOneWidget);
      sub.checking = false;
      sub.confirmed = true;
      sub.notifyListeners();
      await tester.pump();
      expect(find.text(strings.settingsFreePlan), findsOneWidget);
      expect(find.text(strings.settingsUpgrade), findsOneWidget);
      expect(find.text(strings.settingsSubscriptionUnknown), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      sub.dispose();
      locales.dispose();
    },
  );

  testWidgets(
    'subscription management opens external account page and reports failure',
    (tester) async {
      final sub = _Subscription();
      final locales = LocaleController();
      var succeeds = true;
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, (call) async {
            expect(call.method, 'launch');
            expect(
              call.arguments['url'],
              'https://apps.apple.com/account/subscriptions',
            );
            expect(call.arguments['useSafariVC'], isFalse);
            calls++;
            return succeeds;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(launcher, null),
      );
      await mount(tester, sub, locales);
      final management = find.byKey(
        const ValueKey('settings-manage-subscription'),
      );
      await tester.ensureVisible(management);
      await tester.tap(management);
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(SnackBar), findsNothing);
      succeeds = false;
      await tester.tap(management);
      await tester.pump();
      expect(calls, 2);
      expect(
        find.text(
          tester
              .element(find.byType(SettingsView))
              .l10n
              .settingsManageUnavailable,
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      sub.dispose();
      locales.dispose();
    },
  );

  for (final option in LocaleController.languageOptions) {
    for (final size in [const Size(320, 568), const Size(1024, 768)]) {
      testWidgets(
        '${option.locale.toLanguageTag()} selected language visible at $size and 200%',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final sub = _Subscription()..confirmed = true;
          final locales = LocaleController(initialLocale: option.locale);
          await mount(tester, sub, locales, scale: 2);
          final language = find.byKey(const ValueKey('settings-language'));
          // v2 rows are taller at 200% text; bring the row fully on screen.
          await tester.scrollUntilVisible(
            language,
            80,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(language);
          await tester.pumpAndSettle();
          await tester.tap(language);
          await tester.pumpAndSettle();
          final selected = find.descendant(
            of: find.byKey(const ValueKey('settings-language-list')),
            matching: find.widgetWithText(ListTile, option.nativeName),
          );
          expect(selected, findsOneWidget);
          final rect = tester.getRect(selected);
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(tester.widget<ListTile>(selected).selected, isTrue);
          expect(rect.height, greaterThanOrEqualTo(44));
          expect(
            Directionality.of(tester.element(selected)),
            ['ar', 'he'].contains(option.locale.languageCode)
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          sub.dispose();
          locales.dispose();
        },
      );
    }
  }
}
