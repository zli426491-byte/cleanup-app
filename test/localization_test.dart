import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:cleanup_app/l10n/service_messages.dart';
import 'package:cleanup_app/main.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/app_theme.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/home/main_tab_view.dart';
import 'package:cleanup_app/views/onboarding/onboarding_view.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:cleanup_app/views/components/video_compression_view.dart';
import 'package:cleanup_app/views/settings/settings_view.dart';
import 'package:cleanup_app/views/v2/daily_limit_sheet.dart';
import 'package:cleanup_app/views/v2/category_grid_view.dart';
import 'package:cleanup_app/views/v2/category_intro_view.dart';
import 'package:cleanup_app/views/v2/cleanup_category.dart';
import 'package:cleanup_app/views/v2/congratulations_view.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:cleanup_app/views/v2/optimize_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final previewBytes = img.encodePng(img.Image(width: 8, height: 12));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '41',
      buildSignature: '',
    );
    // Full previews intentionally bypass embedded grid thumbnails. Exercise the
    // actual native request path with a completed, decodable fixture response.
    messenger.setMockMethodCallHandler(photos, (call) async {
      final arguments = call.arguments as Map?;
      switch (call.method) {
        case 'fetchEntityProperties':
          return {'id': arguments!['id'], 'type': 1, 'width': 8, 'height': 12};
        case 'getThumb':
          return previewBytes;
        default:
          throw MissingPluginException('Unexpected Photos call ${call.method}');
      }
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(photos, null));

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
        final subscriptions = _LocalizedProducts();
        final rtl = const ['ar', 'he'].contains(option.locale.languageCode);
        for (final viewport in [const Size(320, 568), const Size(1366, 1024)]) {
          tester.view.physicalSize = viewport;
          for (final screen in <Widget>[
            const OnboardingView(),
            const MainTabView(),
            const HomeView(),
            const OptimizeTabView(),
            const SmartCleanView(),
            const PaywallView(),
            const PaywallView(fromOnboarding: true),
            const Scaffold(body: DailyLimitSheet(source: 'l10n', remaining: 0)),
            const Scaffold(body: DailyLimitSheet(source: 'l10n', remaining: 3)),
            const SettingsView(),
            CategoryIntroView(
              title: 'Duplicates',
              body: 'Intro',
              grouped: true,
              onContinue: (_) async {},
            ),
            CategoryIntroView(
              title: 'Videos',
              body: 'Intro',
              onContinue: (_) async {},
            ),
            const CategoryGridView(category: CleanupCategory.videos),
            const CategoryGridView(category: CleanupCategory.screenshots),
            const GroupReviewView(
              title: 'Duplicates',
              sections: [CleanupCategory.duplicates],
            ),
            const GroupReviewView(
              title: 'Optimize',
              sections: [CleanupCategory.duplicates, CleanupCategory.similars],
            ),
            const VideoCompressListView(),
            const CongratulationsView(
              deletedCount: 128,
              deletedBytes: 3 * 1024 * 1024 * 1024,
            ),
            SwipeCleanView(
              assets: [
                PhotoAsset(
                  id: 'localization-photo',
                  width: 3024,
                  height: 4032,
                  size: 0,
                  createDate: DateTime(2026, 9, 27),
                  type: AssetType.image,
                  thumbnail: previewBytes,
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
            await tester.runAsync(() async {
              for (final image in tester.widgetList<Image>(
                find.byType(Image),
              )) {
                await precacheImage(image.image, context);
              }
            });
            await tester.pump();
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
      final subscriptions = _LocalizedProducts();
      final controller = LocaleController();
      await tester.pumpWidget(
        CleanupApp(
          hasCompletedOnboarding: false,
          subscriptionManager: subscriptions,
          localeController: controller,
        ),
      );
      await tester.pump();
      expect(find.text('開始使用'), findsOneWidget);
      final state = tester.state(find.byType(OnboardingView));
      dispatcher.localesTestValue = const [Locale('zh', 'CN')];
      await tester.pump();
      expect(find.text('开始使用'), findsOneWidget);
      expect(tester.state(find.byType(OnboardingView)), same(state));
      await controller.setLocale(const Locale('en'));
      dispatcher.localesTestValue = const [Locale('ar')];
      await tester.pump();
      expect(find.text('Get started'), findsOneWidget);
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
    final subscriptions = _LocalizedProducts();
    final controller = LocaleController(initialLocale: const Locale('en'));
    await tester.pumpWidget(
      CleanupApp(
        hasCompletedOnboarding: true,
        subscriptionManager: subscriptions,
        localeController: controller,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
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
              of: find.byType(MainTabView, skipOffstage: false),
              matching: find.byType(IndexedStack, skipOffstage: false),
              skipOffstage: false,
            ),
          )
          .index,
      0,
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

// Show real plan card layouts without invoking StoreKit or asynchronous SDK
// retries; subscription behavior is covered separately by transaction tests.
class _LocalizedProducts extends SubscriptionManager {
  @override
  bool get isPlaceholder => false;
  @override
  bool get isInitializing => false;
  @override
  bool get isLoading => false;
  @override
  bool get hasCheckedSubscription => true;
  @override
  SubscriptionOperation get operation => SubscriptionOperation.idle;
  @override
  Future<void> init({required bool isIos}) async {}
  @override
  Future<void> retry() async {}
  @override
  Future<List<Package>> loadProducts() async => const [];
  @override
  List<StoreProduct> get storeProducts => const [
    StoreProduct(
      AppConstants.yearlyProductId,
      'Annual cleanup',
      'Annual',
      990,
      'NT\$990',
      'TWD',
    ),
    StoreProduct(
      AppConstants.weeklyProductId,
      'Weekly cleanup',
      'Weekly',
      90,
      'NT\$90',
      'TWD',
      introductoryPrice: IntroductoryPrice(0, 'NT\$0', 'P1W', 1, PeriodUnit.week, 1),
    ),
  ];
  @override
  int? freeTrialDays(StoreProduct product) =>
      product.introductoryPrice == null ? null : 7;
}

PhotoAsset _fixtureAsset(String id, AssetType type, {bool screenshot = false}) =>
    PhotoAsset(
      id: id,
      width: 3024,
      height: 4032,
      size: 48 * 1024 * 1024,
      sizeKnown: true,
      createDate: DateTime(2026, 9, 27),
      type: type,
      isScreenshot: screenshot,
      thumbnail: img.encodePng(img.Image(width: 8, height: 12)),
    );

final _fixtureResult = () {
  final a = _fixtureAsset('dup-a', AssetType.image);
  final b = _fixtureAsset('dup-b', AssetType.image);
  final c = _fixtureAsset('sim-a', AssetType.image);
  final d = _fixtureAsset('sim-b', AssetType.image);
  final e = _fixtureAsset('sim-c', AssetType.image);
  final video = _fixtureAsset('video-a', AssetType.video);
  final shot = _fixtureAsset('shot-a', AssetType.image, screenshot: true);
  return ScanResult(
    allAssets: [a, b, c, d, e, video, shot],
    duplicateGroups: [
      DuplicateGroup(hash: 'h', assets: [a, b], bestAssetId: 'dup-a'),
    ],
    similarGroups: [
      SimilarGroup(assets: [c, d, e], hammingDistance: 4, bestAssetId: 'sim-b'),
    ],
    screenshots: [shot],
    largeFiles: [a, video],
    videos: [video],
    blurryPhotos: const [],
    darkPhotos: const [],
    overexposedPhotos: const [],
    totalSavingsEstimate: 0,
  );
}();

class _ScanningFixture extends PhotoScannerService {
  @override
  ScanResult get scanResult => _fixtureResult;
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
