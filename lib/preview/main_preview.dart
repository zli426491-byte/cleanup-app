// Desktop/web design preview with sample data. Not part of the iOS app:
//   flutter build web -t lib/preview/main_preview.dart
// Photos, StoreKit and deletion are simulated so every screen can be viewed
// in a browser. Nothing here touches a real library or purchase.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart' show AssetType;
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../services/photo_scanner_service.dart';
import '../services/subscription_manager.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../views/home/main_tab_view.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/paywall/paywall_view.dart';
import '../views/v2/category_grid_view.dart';
import '../views/v2/category_intro_view.dart';
import '../views/v2/cleanup_category.dart';
import '../views/v2/congratulations_view.dart';
import '../views/v2/daily_limit_sheet.dart';
import '../views/v2/extras_view.dart';
import '../views/v2/group_review_view.dart';
import '../views/v2/optimize_view.dart';

void main() {
  runApp(const _PreviewApp());
}

Uint8List _swatch(int seed, {int w = 60, int h = 80}) {
  final rnd = math.Random(seed);
  final image = img.Image(width: w, height: h);
  final c1 = [rnd.nextInt(200) + 40, rnd.nextInt(200) + 40, rnd.nextInt(200) + 40];
  final c2 = [rnd.nextInt(200) + 40, rnd.nextInt(200) + 40, rnd.nextInt(200) + 40];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = (x + y) / (w + h);
      image.setPixelRgb(
        x,
        y,
        (c1[0] * (1 - t) + c2[0] * t).round(),
        (c1[1] * (1 - t) + c2[1] * t).round(),
        (c1[2] * (1 - t) + c2[2] * t).round(),
      );
    }
  }
  // A simple "subject" so similar shots look alike.
  img.fillCircle(
    image,
    x: w ~/ 2 + (seed % 3) - 1,
    y: h ~/ 2,
    radius: w ~/ 4,
    color: img.ColorRgb8(250, 250, 245),
  );
  return img.encodePng(image);
}

PhotoAsset _asset(
  String id,
  int seed, {
  int mb = 4,
  AssetType type = AssetType.image,
  bool screenshot = false,
  bool blurry = false,
  int daysAgo = 0,
}) => PhotoAsset(
  id: id,
  width: 3024,
  height: 4032,
  size: mb * 1024 * 1024 + seed * 37000,
  sizeKnown: true,
  analysisPending: false,
  analysisAttempted: true,
  createDate: DateTime(2026, 9, 28).subtract(Duration(days: daysAgo)),
  type: type,
  durationSeconds: type == AssetType.video ? 42 : 0,
  thumbnail: _swatch(seed),
  isScreenshot: screenshot,
  isBlurry: blurry,
);

class _PreviewScanner extends PhotoScannerService {
  _PreviewScanner() : super(supportsNativeResources: false) {
    _result = _build();
  }

  late ScanResult _result;

  static ScanResult _build() {
    final dupes = [
      for (var g = 0; g < 4; g++)
        [
          for (var i = 0; i < 2 + g % 2; i++)
            _asset('dup-$g-$i', 10 + g, mb: 3 + g, daysAgo: g * 3),
        ],
    ];
    final similars = [
      for (var g = 0; g < 5; g++)
        [
          for (var i = 0; i < 3; i++)
            _asset('sim-$g-$i', 40 + g * 3 + i % 2, mb: 2 + i, daysAgo: g),
        ],
    ];
    final videos = [
      for (var i = 0; i < 6; i++)
        _asset('vid-$i', 90 + i, mb: 60 + i * 25, type: AssetType.video, daysAgo: i),
    ];
    final shots = [
      for (var i = 0; i < 9; i++)
        _asset('shot-$i', 120 + i, mb: 1, screenshot: true, daysAgo: i * 2),
    ];
    final blurred = [
      for (var i = 0; i < 4; i++)
        _asset('blur-$i', 150 + i, mb: 3, blurry: true, daysAgo: i * 5),
    ];
    final other = [
      for (var i = 0; i < 24; i++) _asset('other-$i', 200 + i, mb: 2 + i % 5, daysAgo: i),
    ];
    final all = [
      ...dupes.expand((g) => g),
      ...similars.expand((g) => g),
      ...videos,
      ...shots,
      ...blurred,
      ...other,
    ];
    return ScanResult(
      allAssets: all,
      duplicateGroups: [
        for (var g = 0; g < dupes.length; g++)
          DuplicateGroup(hash: 'h$g', assets: dupes[g], bestAssetId: dupes[g].first.id),
      ],
      similarGroups: [
        for (final g in similars)
          SimilarGroup(assets: g, hammingDistance: 4, bestAssetId: g[1].id),
      ],
      screenshots: shots,
      largeFiles: [...videos.take(3)],
      videos: videos,
      blurryPhotos: blurred,
      darkPhotos: const [],
      overexposedPhotos: const [],
      totalSavingsEstimate: 0,
    );
  }

  @override
  ScanResult get scanResult => _result;
  @override
  bool get hasCompletedScan => true;
  @override
  int get scannedAssetCount => _result.allAssets.length;
  @override
  int? get availableAssetCount => _result.allAssets.length;
  @override
  int get totalPhotoCount => _result.allAssets.length;
  @override
  int get attemptedAnalysisCount => _result.allAssets.length;
  @override
  Future<void> startContinuousScan({bool resume = false}) async {}
  @override
  Future<void> refreshPhotoAccess() async {}

  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    final ids = {for (final a in assets) a.id};
    List<PhotoAsset> keep(List<PhotoAsset> list) =>
        [for (final a in list) if (!ids.contains(a.id)) a];
    _result = ScanResult(
      allAssets: keep(_result.allAssets),
      duplicateGroups: [
        for (final g in _result.duplicateGroups)
          if (keep(g.assets).length > 1)
            DuplicateGroup(hash: g.hash, assets: keep(g.assets), bestAssetId: g.bestAssetId),
      ],
      similarGroups: [
        for (final g in _result.similarGroups)
          if (keep(g.assets).length > 1)
            SimilarGroup(assets: keep(g.assets), hammingDistance: 4, bestAssetId: g.bestAssetId),
      ],
      screenshots: keep(_result.screenshots),
      largeFiles: keep(_result.largeFiles),
      videos: keep(_result.videos),
      blurryPhotos: keep(_result.blurryPhotos),
      darkPhotos: const [],
      overexposedPhotos: const [],
      totalSavingsEstimate: 0,
    );
    notifyListeners();
    return ids;
  }
}

class _PreviewStore extends SubscriptionManager {
  @override
  bool get isPlaceholder => false;
  @override
  bool get isLoading => false;
  @override
  bool get isInitializing => false;
  @override
  bool get hasCheckedSubscription => true;
  @override
  Future<void> init({required bool isIos}) async {}
  @override
  Future<List<Package>> loadProducts() async => const [];
  @override
  List<StoreProduct> get storeProducts => const [
    StoreProduct(AppConstants.yearlyProductId, 'Yearly', 'Yearly', 29.99, r'$29.99', 'USD'),
    StoreProduct(
      AppConstants.weeklyProductId,
      'Weekly',
      'Weekly',
      7.99,
      r'$7.99',
      'USD',
      introductoryPrice: IntroductoryPrice(0, r'$0.00', 'P1W', 1, PeriodUnit.week, 1),
    ),
  ];
  @override
  int? freeTrialDays(StoreProduct product) =>
      product.introductoryPrice == null ? null : 7;
  @override
  Future<bool> purchaseStoreProduct(StoreProduct product) async => false;
  @override
  Future<bool> restorePurchases() async => false;
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final _locales = LocaleController();
  final _scanner = _PreviewScanner();
  final _store = _PreviewStore();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locales),
        ChangeNotifierProvider<PhotoScannerService>.value(value: _scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: _store),
      ],
      child: Consumer<LocaleController>(
        builder: (context, languages, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: languages.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocaleController.supportedLocales,
          localeListResolutionCallback: LocaleController.resolve,
          theme: AppTheme.lightTheme,
          builder: (context, child) => ColoredBox(
            color: const Color(0xFFE9ECF2),
            child: Center(
              // Phone-sized frame so the layout reads like the iPhone app.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(width: 390, height: 844, child: child),
              ),
            ),
          ),
          home: _screenFor(Uri.base.fragment),
        ),
      ),
    );
  }
}

/// Deep links such as `#home` or `#paywall-b` open one screen directly, so
/// each page can be reviewed without navigating through transitions.
Widget _screenFor(String fragment) => switch (fragment) {
  'home' => const MainTabView(),
  'onboarding' => const OnboardingView(),
  'paywall-a' => const PaywallView(variant: PaywallVariant.trial),
  'paywall-b' => const PaywallView(),
  'limit' => const Scaffold(
    backgroundColor: Colors.black54,
    body: Center(child: DailyLimitSheet(source: 'preview', remaining: 0)),
  ),
  'congrats' => const CongratulationsView(
    deletedCount: 128,
    deletedBytes: 2400 * 1024 * 1024,
  ),
  'duplicates' => const GroupReviewView(
    title: '重複照片',
    sections: [CleanupCategory.duplicates],
  ),
  'optimize' => const GroupReviewView(
    title: '最佳化儲存空間',
    sections: [CleanupCategory.duplicates, CleanupCategory.similars],
  ),
  'videos' => const CategoryGridView(category: CleanupCategory.videos),
  'other' => const CategoryGridView(category: CleanupCategory.other),
  'intro' => CategoryIntroView(
    title: '影片',
    body: '檢視所有影片，依大小或日期排序，找出最佔空間的影片。',
    onContinue: (_) async {},
  ),
  'optimize-tab' => const OptimizeTabView(),
  'extras' => const ExtrasView(),
  _ => const _PreviewMenu(),
};

class _PreviewMenu extends StatelessWidget {
  const _PreviewMenu();

  @override
  Widget build(BuildContext context) {
    Widget item(String label, WidgetBuilder builder) => ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('UI v2 preview')),
      body: ListView(
        children: [
          item('App (Home / Optimize / Extras)', (_) => const MainTabView()),
          item('Onboarding', (_) => const OnboardingView()),
          item('Paywall A (trial)', (_) => const PaywallView(variant: PaywallVariant.trial)),
          item('Paywall B (unlock)', (_) => const PaywallView()),
          item(
            'Daily limit',
            (_) => const Scaffold(
              backgroundColor: Colors.black54,
              body: Center(child: DailyLimitSheet(source: 'preview', remaining: 0)),
            ),
          ),
          item(
            'Congratulations',
            (_) => const CongratulationsView(
              deletedCount: 128,
              deletedBytes: 2400 * 1024 * 1024,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sample data only. Deleting in the preview removes sample items '
              'from memory; no real photos or purchases are involved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
