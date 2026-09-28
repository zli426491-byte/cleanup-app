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

Future<void> _mount(
  WidgetTester tester,
  PhotoScannerService scanner, {
  ValueChanged<String>? onOpenReview,
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
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
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
        await tester.tap(
          find.descendant(of: hero, matching: find.text('整理已載入照片')),
        );
        expect(opened, category);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
