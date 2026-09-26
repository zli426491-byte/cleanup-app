import 'dart:convert';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/l10n/service_messages.dart';
import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/home/main_tab_view.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:cleanup_app/views/components/video_compression_view.dart';
import 'package:cleanup_app/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test(
    '19 explicit languages distinguish both Chinese scripts and preferences',
    () {
      final supported = LocaleController.supportedLocales;
      expect(supported.toSet().length, 19);
      expect(
        LocaleController.resolve([
          const Locale('zh', 'TW'),
        ], supported).scriptCode,
        'Hant',
      );
      expect(
        LocaleController.resolve([
          const Locale('zh', 'HK'),
        ], supported).scriptCode,
        'Hant',
      );
      expect(
        LocaleController.resolve([
          const Locale('zh', 'CN'),
        ], supported).scriptCode,
        'Hans',
      );
      expect(
        LocaleController.resolve([
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'TW',
          ),
        ], supported).scriptCode,
        'Hans',
      );
      expect(
        LocaleController.resolve([
          const Locale('xx'),
          const Locale('fr', 'CA'),
        ], supported),
        const Locale('fr'),
      );
      expect(
        LocaleController.resolve([const Locale('xx')], supported),
        const Locale('en'),
      );
    },
  );

  test(
    'language choice survives restart; system choice clears preference',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = await LocaleController.load(preferences);
      final traditional = const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      );
      expect(controller.locale, isNull);
      await controller.setLocale(traditional);
      final restarted = await LocaleController.load(preferences);
      expect(restarted.locale, traditional);
      await restarted.setLocale(null);
      expect((await LocaleController.load(preferences)).locale, isNull);
      expect(preferences.containsKey(LocaleController.preferenceKey), isFalse);
      await expectLater(
        controller.setLocale(const Locale('xx')),
        throwsArgumentError,
      );
      controller.dispose();
      restarted.dispose();
    },
  );

  test('invalid saved language falls back to the system', () async {
    SharedPreferences.setMockInitialValues({
      LocaleController.preferenceKey: 'xx',
    });
    final controller = await LocaleController.load(
      await SharedPreferences.getInstance(),
    );
    expect(controller.locale, isNull);
    controller.dispose();
  });

  for (final option in LocaleController.languageOptions) {
    testWidgets(
      '${option.locale.toLanguageTag()}: current screens fit iPhone/iPad and respect direction',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = LocaleController(initialLocale: option.locale);
        final scanner = _ScanningFixture();
        final subscriptions = SubscriptionManager();
        final rtl = const ['ar', 'he'].contains(option.locale.languageCode);
        for (final viewport in [const Size(320, 568), const Size(1366, 1024)]) {
          tester.view.physicalSize = viewport;
          for (final screen in <Widget>[
            const OnboardingView(),
            const HomeView(),
            const SmartCleanView(),
            const PaywallView(),
            const SettingsView(),
            SwipeCleanView(
              assets: [
                PhotoAsset(
                  id: 'localization-photo',
                  width: 3024,
                  height: 4032,
                  size: 0,
                  createDate: DateTime(2026, 9, 27),
                  type: AssetType.image,
                  thumbnail: base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aG2kAAAAASUVORK5CYII=',
                  ),
                ),
              ],
              title: '',
              categoryId: 'photos',
            ),
            VideoCompressionView(
              asset: PhotoAsset(
                id: 'localization-video',
                width: 1920,
                height: 1080,
                size: 0,
                createDate: DateTime(2026, 9, 27),
                type: AssetType.video,
              ),
            ),
          ]) {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<LocaleController>.value(
                    value: controller,
                  ),
                  ChangeNotifierProvider<PhotoScannerService>.value(
                    value: scanner,
                  ),
                  ChangeNotifierProvider<SubscriptionManager>.value(
                    value: subscriptions,
                  ),
                ],
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  locale: option.locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: LocaleController.supportedLocales,
                  localeListResolutionCallback: LocaleController.resolve,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        viewport.width == 320 ? 1.4 : 2,
                      ),
                    ),
                    child: child!,
                  ),
                  home: screen,
                ),
              ),
            );
            await tester.pump();
            final context = tester.element(find.byWidget(screen));
            expect(
              Directionality.of(context),
              rtl ? TextDirection.rtl : TextDirection.ltr,
            );
            expect(
              context.l10n.localeName.replaceAll('-', '_'),
              option.locale.toLanguageTag().replaceAll('-', '_'),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${option.nativeName}: ${screen.runtimeType}',
            );
            await tester.pumpWidget(const SizedBox());
          }
        }
        scanner.dispose();
        subscriptions.dispose();
        controller.dispose();
      },
    );
  }

  testWidgets(
    'system language changes update existing screens; manual choice takes precedence',
    (tester) async {
      final dispatcher = tester.platformDispatcher;
      dispatcher.localesTestValue = const [Locale('zh', 'TW')];
      addTearDown(dispatcher.clearLocalesTestValue);
      final subscriptions = SubscriptionManager();
      final controller = LocaleController();
      await tester.pumpWidget(
        CleanupApp(
          hasCompletedOnboarding: false,
          subscriptionManager: subscriptions,
          localeController: controller,
        ),
      );
      await tester.pump();
      expect(find.text('繼續'), findsOneWidget);
      final state = tester.state(find.byType(OnboardingView));
      dispatcher.localesTestValue = const [Locale('zh', 'CN')];
      await tester.pump();
      expect(find.text('继续'), findsOneWidget);
      expect(tester.state(find.byType(OnboardingView)), same(state));
      await controller.setLocale(const Locale('en'));
      dispatcher.localesTestValue = const [Locale('ar')];
      await tester.pump();
      expect(find.text('Continue'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.ltr,
      );
      await tester.pumpWidget(const SizedBox());
      subscriptions.dispose();
    },
  );

  testWidgets('settings changes current app language and preserves the tab', (
    tester,
  ) async {
    final subscriptions = SubscriptionManager();
    final controller = LocaleController(initialLocale: const Locale('en'));
    await tester.pumpWidget(
      CleanupApp(
        hasCompletedOnboarding: true,
        subscriptionManager: subscriptions,
        localeController: controller,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.tap(find.text('Language'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final traditional = find.text('繁體中文');
    await tester.scrollUntilVisible(
      traditional,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(traditional);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('語言'), findsOneWidget);
    expect(controller.locale?.scriptCode, 'Hant');
    expect(preferenceTag(await SharedPreferences.getInstance()), 'zh-Hant');
    expect(
      tester
          .widget<IndexedStack>(
            find.descendant(
              of: find.byType(MainTabView),
              matching: find.byType(IndexedStack),
            ),
          )
          .index,
      2,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    subscriptions.dispose();
  });

  test(
    'retained service messages translate with the newly selected locale',
    () {
      final english = lookupAppLocalizations(const Locale('en'));
      final traditional = lookupAppLocalizations(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      const source = '已暫停，已讀取與分析的結果已保留，可繼續掃描。\n已讀取 123 / 456 個可存取項目。';
      expect(translateServiceMessage(english, source), contains('123 / 456'));
      expect(translateServiceMessage(english, source), contains('Paused'));
      expect(translateServiceMessage(traditional, source), contains('已暫停'));
      expect(translateServiceMessage(english, '讀取本機預覽（8 張）'), contains('(8)'));
      expect(
        translateServiceMessage(english, '縮圖邊緣較清楚、整體亮度適中；僅供保留參考'),
        contains('guidance only'),
      );
      expect(
        translateServiceMessage(english, '未來新增但尚未翻譯的錯誤'),
        english.serviceOperationFailed,
      );
    },
  );
}

String? preferenceTag(SharedPreferences preferences) =>
    preferences.getString(LocaleController.preferenceKey);

class _ScanningFixture extends PhotoScannerService {
  @override
  bool get isScanning => true;
  @override
  int get scannedAssetCount => 42683;
  @override
  int? get availableAssetCount => 42683;
  @override
  int get totalPhotoCount => 42683;
  @override
  int get attemptedAnalysisCount => 123;
  @override
  int get analyzedAssetCount => 120;
  @override
  int get cloudPendingCount => 3;
  @override
  ScanPhase get currentPhase => ScanPhase.computingHashes;
  @override
  String? get currentOperation => '讀取本機預覽（8 張）';
  @override
  int get currentWaitSeconds => 2;
}
