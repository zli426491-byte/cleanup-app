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
import '../l10n/l10n.dart';
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

/// A small drawn landscape (sky, sun, hills, water) so previews and store
/// screenshots show photo-like thumbnails without using anyone's photos.
/// Nearby seeds (seed ~/ 3) share a scene with a slight shift, like a burst
/// of similar shots.
Uint8List _swatch(int seed, {int w = 180, int h = 240}) {
  final scene = math.Random(seed ~/ 3 * 7919 + 13);
  final shift = (seed % 3) * 4;
  final image = img.Image(width: w, height: h);
  const palettes = [
    // sky top, sky bottom, far hill, near hill, ground
    [[70, 130, 220], [180, 215, 245], [95, 140, 120], [55, 110, 80], [60, 120, 70]],
    [[245, 140, 90], [255, 210, 150], [150, 100, 120], [95, 70, 100], [70, 60, 90]],
    [[30, 60, 130], [120, 160, 220], [60, 90, 130], [35, 60, 95], [30, 70, 120]],
    [[120, 190, 235], [225, 240, 250], [170, 180, 190], [120, 130, 140], [210, 200, 170]],
    [[255, 175, 120], [255, 230, 190], [200, 120, 90], [150, 85, 70], [60, 110, 150]],
    [[90, 170, 200], [200, 235, 240], [80, 150, 110], [40, 110, 70], [50, 140, 170]],
  ];
  final pal = palettes[scene.nextInt(palettes.length)];
  final horizon = (h * (0.52 + scene.nextDouble() * 0.12)).round();
  final water = scene.nextBool();
  int mix(int a, int b, double t) => (a + (b - a) * t).round();
  for (var y = 0; y < h; y++) {
    final t = (y / horizon).clamp(0.0, 1.0);
    for (var x = 0; x < w; x++) {
      image.setPixelRgb(x, y, mix(pal[0][0], pal[1][0], t),
          mix(pal[0][1], pal[1][1], t), mix(pal[0][2], pal[1][2], t));
    }
  }
  // Sun or moon.
  img.fillCircle(image,
      x: (w * (0.2 + scene.nextDouble() * 0.6)).round() + shift,
      y: (horizon * (0.25 + scene.nextDouble() * 0.3)).round(),
      radius: (w * 0.09).round(),
      color: img.ColorRgb8(255, 246, 220));
  // Two layers of hills.
  void hills(List<int> c, double base, double amp, double freq, double phase) {
    for (var x = 0; x < w; x++) {
      final top = (horizon - base * h +
              amp * h * math.sin((x + shift) * freq / w * math.pi * 2 + phase))
          .round();
      for (var y = top.clamp(0, h); y < h; y++) {
        image.setPixelRgb(x, y, c[0], c[1], c[2]);
      }
    }
  }
  hills(pal[2], 0.10, 0.05, 1.3, scene.nextDouble() * 6);
  hills(pal[3], 0.02, 0.04, 2.1, scene.nextDouble() * 6);
  // Ground or water with a soft gradient.
  final g = pal[4];
  for (var y = horizon; y < h; y++) {
    final t = (y - horizon) / (h - horizon);
    for (var x = 0; x < w; x++) {
      final ripple = water && (y + x ~/ 9) % 7 == 0 ? 18 : 0;
      image.setPixelRgb(x, y, mix(g[0], g[0] ~/ 2, t) + ripple,
          mix(g[1], g[1] ~/ 2, t) + ripple, mix(g[2], g[2] ~/ 2, t) + ripple);
    }
  }
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
          // `?shot=...` renders full screen for App Store screenshots;
          // otherwise a phone-sized frame so the layout reads like the app.
          builder: (context, child) => Uri.base.queryParameters
                  .containsKey('shot')
              ? child!
              : ColoredBox(
                  color: const Color(0xFFE9ECF2),
                  child: Center(
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
  // Localized titles so store screenshots match each language.
  'duplicates' => Builder(
    builder: (context) => GroupReviewView(
      title: CleanupCategory.duplicates.title(context),
      sections: const [CleanupCategory.duplicates],
    ),
  ),
  'similar' => Builder(
    builder: (context) => GroupReviewView(
      title: CleanupCategory.similars.title(context),
      sections: const [CleanupCategory.similars],
    ),
  ),
  'optimize' => Builder(
    builder: (context) => GroupReviewView(
      title: context.l10n.v2OptimizeTitle,
      sections: const [CleanupCategory.duplicates, CleanupCategory.similars],
    ),
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
