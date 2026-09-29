import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Previews are done; a bounded originals round left photos unchecked.
class _OriginalsScanner extends PhotoScannerService {
  _OriginalsScanner({this.cloudPending = 0});

  /// Photos whose preview was tried but still waits for iCloud.
  final int cloudPending;
  int verifyCalls = 0;
  int previewRetries = 0;
  int verified = 700;

  /// Originals that can be read locally; the rest are iCloud-only.
  int readable = 10007;

  @override
  bool get isScanning => false;
  @override
  bool get nativeOriginalAnalysisAvailable => true;
  @override
  ScanResult get scanResult => ScanResult.empty;
  @override
  int get scannedAssetCount => 10510;
  @override
  int? get availableAssetCount => 10510;
  @override
  int get totalPhotoCount => 10007;
  @override
  int get pendingAnalysisCount => cloudPending;
  @override
  int get attemptedAnalysisCount => totalPhotoCount;
  @override
  int get verifiedHashAssetCount => verified;
  @override
  int get pendingHashAssetCount => totalPhotoCount - verified;
  @override
  int get knownSizeAssetCount => 10510;
  @override
  int get pendingSizeAssetCount => 0;
  @override
  Future<void> verifyOriginals({
    OriginalVerificationTarget target = OriginalVerificationTarget.all,
  }) async {
    verifyCalls++;
    verified = (verified + 800).clamp(0, readable);
    notifyListeners();
  }

  @override
  Future<void> startContinuousScan({bool resume = false}) async {
    previewRetries++;
    notifyListeners();
  }
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
        locale: locale ?? const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeView(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'home shows advancing analysis and verification after 42k indexing',
    (tester) async {
      final scanner = _PhaseScanner();
      await _mount(tester, scanner);
      final strings = tester.element(find.byType(HomeView)).l10n;
      final strip = find.byKey(const ValueKey('home-scan-progress'));
      expect(
        find.descendant(of: strip, matching: find.text(strings.v2Scanning)),
        findsOneWidget,
      );

      scanner.phase = ScanPhase.computingHashes;
      scanner.attempted = 17;
      scanner.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(of: strip, matching: find.text('17 / 42682')),
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
        find.descendant(of: strip, matching: find.text('18 / 42682')),
        findsOneWidget,
      );

      scanner.verifying = true;
      scanner.processed = 20;
      scanner.notifyListeners();
      await tester.pump();
      expect(
        find.descendant(
          of: strip,
          matching: find.text(strings.v2CheckingDuplicates),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.text('20 / 42682')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home-scan-pause')));
      expect(scanner.cancels, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final cloudPending in [0, 30]) {
    testWidgets('home continues the originals check after a bounded round '
        '(iCloud previews waiting: $cloudPending)', (tester) async {
      final scanner = _OriginalsScanner(cloudPending: cloudPending);
      await _mount(tester, scanner);
      await tester.pump();
      // Home starts the first round on its own.
      expect(scanner.verifyCalls, 1);
      final strings = tester.element(find.byType(HomeView)).l10n;
      expect(find.text(strings.v2CheckPaused), findsOneWidget);
      expect(find.text('1500 / 10007'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-scan-continue')));
      await tester.pump();
      expect(scanner.verifyCalls, 2);
      expect(scanner.previewRetries, 0);
      expect(find.text('2300 / 10007'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a round that cannot read more originals retries previews', (
    tester,
  ) async {
    // 30 photos wait for iCloud: neither their previews nor originals are
    // local, so originals stop at 9977 of 10007.
    final scanner = _OriginalsScanner(cloudPending: 30)
      ..verified = 9977
      ..readable = 9977;
    await _mount(tester, scanner);
    await tester.pump();
    expect(scanner.verifyCalls, 1);
    final strings = tester.element(find.byType(HomeView)).l10n;
    // The automatic round added nothing, so Continue retries previews.
    expect(find.text(strings.v2ScanPaused), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-scan-continue')));
    await tester.pump();
    expect(scanner.previewRetries, 1);
    expect(scanner.verifyCalls, 1);
    // After a preview retry the next Continue checks originals again.
    expect(find.text(strings.v2CheckPaused), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-scan-continue')));
    await tester.pump();
    expect(scanner.verifyCalls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the check-paused card fits $locale at 320pt and 200% text', (
      tester,
    ) async {
      // Tall enough that 200% text keeps the card inside the first screen.
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scanner = _OriginalsScanner();
      await _mount(tester, scanner, locale: locale, textScale: 2);
      await tester.pump();
      final strings = tester.element(find.byType(HomeView)).l10n;
      expect(find.text(strings.v2CheckPaused), findsOneWidget);
      expect(find.byKey(const ValueKey('home-scan-continue')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final withExact in [true, false]) {
    testWidgets(
      'home card shows the real ${withExact ? 'exact' : 'similar'} pair and opens it',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'v2.intro.duplicates': true,
          'v2.intro.similar': true,
        });
        final semantics = tester.ensureSemantics();
        final scanner = _PairScanner(withExact: withExact);
        await _mount(tester, scanner);
        final strings = tester.element(find.byType(HomeView)).l10n;
        final category = withExact ? 'duplicates' : 'similar';
        final other = withExact ? 'similar' : 'duplicates';
        final card = find.byKey(ValueKey('home-category-$category'));
        expect(card, findsOneWidget);
        for (final id in ['pair-a', 'pair-b']) {
          expect(
            find.descendant(
              of: card,
              matching: find.byKey(ValueKey('home-preview-$id')),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(const ValueKey('home-preview-unrelated')),
          findsNothing,
        );
        // A pair confirmed as an exact duplicate is not repeated as similar.
        expect(
          find.descendant(
            of: find.byKey(ValueKey('home-category-$other')),
            matching: find.byKey(const ValueKey('home-preview-pair-a')),
          ),
          findsNothing,
        );
        final title = withExact
            ? strings.v2CatDuplicates
            : strings.v2CatSimilars;
        expect(
          find.bySemanticsLabel('$title, ${strings.v2PhotoCount(2)}'),
          findsOneWidget,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        final review = tester.widget<GroupReviewView>(
          find.byType(GroupReviewView),
        );
        expect(review.sections.single.id, category);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }

  for (final viewport in [const Size(390, 844), const Size(1180, 820)]) {
    testWidgets(
      'home keeps grouped photos first and adapts tiles to $viewport',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(tester, _PairScanner(withExact: true));
        final duplicates = find.byKey(
          const ValueKey('home-category-duplicates'),
        );
        final videos = find.byKey(const ValueKey('home-category-videos'));
        final other = find.byKey(const ValueKey('home-category-other'));
        expect(
          tester.getTopLeft(duplicates).dy,
          lessThan(tester.getTopLeft(videos).dy),
        );
        // Two columns on iPhone; iPad adds columns instead of stretching tiles.
        final tileWidth = tester.getSize(videos).width;
        expect(tileWidth, lessThanOrEqualTo(viewport.width / 2));
        expect(tileWidth, lessThan(260));
        expect(tester.getSize(other).width, tileWidth);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('home-preview-pair-a')))
              .height,
          greaterThan(140),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
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
          find.byKey(const ValueKey('home-category-duplicates')),
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
