import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class _PhaseScanner extends PhotoScannerService {
  ScanPhase phase = ScanPhase.fetchingAssets;
  bool verifying = false;
  int attempted = 0;
  int processed = 0;
  int cancels = 0;

  @override
  bool get isScanning => true;
  @override
  ScanPhase get currentPhase => phase;
  @override
  ScanResult get scanResult => ScanResult.empty;
  @override
  int get scannedAssetCount => 42683;
  @override
  int? get availableAssetCount => 42683;
  @override
  int get totalPhotoCount => 42682;
  @override
  int get attemptedAnalysisCount => attempted;
  @override
  bool get isVerifyingOriginals => verifying;
  @override
  OriginalVerificationTarget? get originalVerificationTarget =>
      verifying ? OriginalVerificationTarget.exactPhotos : null;
  @override
  int get originalRoundProcessed => processed;
  @override
  int? get originalRoundTotal => verifying ? 42682 : null;
  @override
  String? get currentOperation => '讀取本機預覽';
  @override
  int get currentWaitSeconds => 15;
  @override
  void cancelScan() => cancels++;
}

class _PairScanner extends PhotoScannerService {
  _PairScanner({required this.withExact}) {
    final thumbnail = img.encodePng(img.Image(width: 8, height: 8));
    PhotoAsset photo(String id) => PhotoAsset(
      id: id,
      width: 100,
      height: 100,
      size: 100,
      createDate: DateTime(2026),
      type: AssetType.image,
      thumbnail: thumbnail,
    );
    final unrelated = photo('unrelated');
    final a = photo('pair-a');
    final b = photo('pair-b');
    result = ScanResult(
      allAssets: [unrelated, a, b],
      duplicateGroups: withExact
          ? [
              DuplicateGroup(
                hash: 'exact',
                assets: [a, b],
                bestAssetId: a.id,
                bestReason: 'verified',
              ),
            ]
          : [],
      similarGroups: [
        SimilarGroup(
          assets: [a, b],
          hammingDistance: 1,
          bestAssetId: a.id,
          bestReason: 'preview',
        ),
      ],
      screenshots: [],
      largeFiles: [],
      videos: [],
      blurryPhotos: [],
      darkPhotos: [],
      overexposedPhotos: [],
      totalSavingsEstimate: 0,
    );
  }

  final bool withExact;
  late final ScanResult result;
  @override
  ScanResult get scanResult => result;
  @override
  bool get hasCompletedScan => true;
  @override
  int get scannedAssetCount => result.allAssets.length;
  @override
  int? get availableAssetCount => result.allAssets.length;
}

class _LocalizedScanningPair extends _PairScanner {
  _LocalizedScanningPair() : super(withExact: true);

  @override
  bool get isScanning => true;
  @override
  bool get hasCompletedScan => false;
  @override
  ScanPhase get currentPhase => ScanPhase.computingHashes;
  @override
  int get totalPhotoCount => 3;
  @override
  int get attemptedAnalysisCount => 1;
  @override
  int get pendingAnalysisCount => 2;
  @override
  int get pendingHashAssetCount => 2;
  @override
  int get pendingSizeAssetCount => 2;
}

Future<void> _mount(
  WidgetTester tester,
  PhotoScannerService scanner, {
  ValueChanged<String>? onOpenReview,
  Locale? locale,
  double textScale = 1,
}) async {
  final subscription = SubscriptionManager();
  addTearDown(scanner.dispose);
  addTearDown(subscription.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        locale:
            locale ??
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeView(onOpenReview: onOpenReview),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'home shows advancing analysis and verification after 42k indexing',
    (tester) async {
      final scanner = _PhaseScanner();
      await _mount(tester, scanner);
      final strip = find.byKey(const ValueKey('home-scan-progress'));
      expect(
        find.descendant(of: strip, matching: find.text('讀取相簿目錄')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('讀取相簿目錄')).dy,
        lessThan(tester.getTopLeft(find.text('已讀取 42683 / 42683 個項目')).dy),
        reason: 'The changing phase should lead before the fixed index total.',
      );

      scanner.phase = ScanPhase.computingHashes;
      scanner.attempted = 17;
      scanner.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: strip, matching: find.text('分析本機照片畫面')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.text('照片畫面已處理 17 / 42682 張')),
        findsOneWidget,
      );
      final previewProgress = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: strip,
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(previewProgress.value, closeTo(17 / 42682, .000001));
      scanner.attempted = 18;
      scanner.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: strip, matching: find.text('照片畫面已處理 18 / 42682 張')),
        findsOneWidget,
      );

      scanner.verifying = true;
      scanner.processed = 20;
      scanner.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: strip, matching: find.text('正在檢查真重複照片')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.text('已處理 20 / 42682')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.textContaining('已等待 15 秒')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: strip, matching: find.text('取消掃描並保留進度')),
      );
      expect(scanner.cancels, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final withExact in [true, false]) {
    testWidgets(
      'home hero displays a real ${withExact ? 'exact' : 'similar'} pair and opens its category',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final scanner = _PairScanner(withExact: withExact);
        String? opened;
        await _mount(tester, scanner, onOpenReview: (value) => opened = value);
        final category = withExact ? 'duplicates' : 'similar';
        final hero = find.byKey(ValueKey('home-photo-hero-$category'));
        expect(hero, findsOneWidget);
        expect(
          find.descendant(
            of: hero,
            matching: find.byKey(const ValueKey('home-photo-preview-pair-a')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: hero,
            matching: find.byKey(const ValueKey('home-photo-preview-pair-b')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: hero,
            matching: find.byKey(
              const ValueKey('home-photo-preview-unrelated'),
            ),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: hero,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label?.contains(
                        withExact ? '真重複照片' : '視覺相似照片',
                      ) ==
                      true &&
                  widget.properties.onTap != null,
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(of: hero, matching: find.text('整理已載入照片')),
        );
        expect(opened, category);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }

  for (final viewport in [const Size(390, 844), const Size(1180, 820)]) {
    testWidgets('home keeps photos first and adapts cards to $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, _PairScanner(withExact: true));
      final hero = find.byKey(const ValueKey('home-photo-hero-duplicates'));
      final swipe = find.byKey(const ValueKey('home-swipe-entry'));
      final tools = find.byKey(const ValueKey('home-category-duplicates'));
      expect(tester.getTopLeft(hero).dy, lessThan(tester.getTopLeft(swipe).dy));
      expect(
        tester.getTopLeft(swipe).dy,
        lessThan(tester.getTopLeft(tools).dy),
      );
      final preview = find.byKey(
        const ValueKey('home-tool-preview-duplicates'),
      );
      expect(
        tester.getSize(preview).width,
        viewport.width < 540 ? 112 : greaterThan(200),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('home-photo-preview-pair-a')))
            .height,
        viewport.width < 540 ? greaterThan(140) : greaterThan(250),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final viewport in [const Size(390, 844), const Size(768, 1024)]) {
      testWidgets('home scan and cards fit $locale at $viewport', (
        tester,
      ) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          _LocalizedScanningPair(),
          locale: locale,
          textScale: 1.2,
        );
        expect(
          find.byKey(const ValueKey('home-scan-progress')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home-photo-hero-duplicates')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('home-category-largeFiles')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
