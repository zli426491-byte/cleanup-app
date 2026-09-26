import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

PhotoAsset _photo(
  String id, {
  bool known = true,
  AssetType type = AssetType.image,
}) => PhotoAsset(
  id: id,
  width: 3000,
  height: 2000,
  size: known ? 8 * 1048576 : 0,
  sizeKnown: known,
  analysisPending: !known,
  createDate: DateTime(2026),
  type: type,
);

class _Scanner extends PhotoScannerService {
  _Scanner({this.scanning = false});
  bool scanning;
  bool cancelled = false;
  int resumeRequests = 0;
  final photos = [
    _photo('same-a'),
    _photo('same-b'),
    _photo('similar-a'),
    _photo('similar-b'),
    _photo('cloud', known: false),
  ];
  final video = _photo('video', type: AssetType.video);

  @override
  bool get isScanning => scanning;
  @override
  bool get hasCompletedScan => !scanning;
  @override
  bool get wasCancelled => cancelled;
  @override
  int? get availableAssetCount => 6000;
  @override
  int get scannedAssetCount => 1200;
  @override
  int get analyzedAssetCount => 1000;
  @override
  int get pendingAnalysisCount => 200;
  @override
  double get scanProgress => .2;
  @override
  ScanPhase get currentPhase => ScanPhase.computingHashes;
  @override
  String? get scanNotice => null;
  @override
  void cancelScan() {
    scanning = false;
    cancelled = true;
    notifyListeners();
  }

  @override
  Future<void> resumeScan() async {
    resumeRequests++;
  }

  @override
  ScanResult get scanResult => ScanResult(
    allAssets: [...photos, video],
    duplicateGroups: [
      DuplicateGroup(
        hash: 'content-hash',
        assets: photos.take(2).toList(),
        bestAssetId: 'same-a',
        bestReason: '解析度與品質較佳',
      ),
    ],
    similarGroups: [
      SimilarGroup(
        assets: photos.skip(2).take(2).toList(),
        hammingDistance: 3,
        bestAssetId: 'similar-b',
        bestReason: '清晰度較佳',
      ),
    ],
    screenshots: [],
    largeFiles: [photos.first, video],
    videos: [video],
    blurryPhotos: [],
    darkPhotos: [],
    overexposedPhotos: [],
    totalSavingsEstimate: 0,
  );
}

Future<void> _mount(
  WidgetTester tester,
  PhotoScannerService scanner,
  Widget view, {
  double textScale = 1,
}) async {
  final subscriptions = SubscriptionManager();
  addTearDown(subscriptions.dispose);
  addTearDown(scanner.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: subscriptions),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: view,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          (call) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          null,
        );
  });

  testWidgets(
    'confirmed duplicates and visual similarity remain distinct and suggestions never select',
    (tester) async {
      await _mount(
        tester,
        _Scanner(),
        const SmartCleanView(initialCategory: 'duplicates'),
      );
      expect(find.text('2 張真重複照片'), findsOneWidget);
      expect(find.text('建議保留'), findsOneWidget);
      expect(find.textContaining('解析度與品質較佳'), findsOneWidget);
      expect(find.textContaining('已選擇'), findsNothing);
      await tester.tap(find.text('撤回保留建議'));
      await tester.pump();
      expect(find.text('建議保留'), findsNothing);
      expect(find.textContaining('已選擇'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('select-same-b')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('select-same-b')),
          matching: find.byIcon(Icons.circle_outlined),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      expect(find.text('已選擇 1 個項目'), findsOneWidget);
      await tester.tap(find.text('視覺相似'));
      await tester.pump();
      expect(find.text('2 張視覺相似照片'), findsOneWidget);
      expect(find.textContaining('清晰度較佳'), findsOneWidget);
      expect(find.textContaining('已選擇'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('known file sizes and cloud pending items have truthful labels', (
    tester,
  ) async {
    await _mount(tester, _Scanner(), const SmartCleanView());
    expect(find.text('8.0 MB'), findsWidgets);
    expect(find.text('容量未取得'), findsOneWidget);
    expect(find.text('內容待分析'), findsOneWidget);
    expect(find.text('0.0 MB'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'full scan progress shows counts, cancellation and resumable work',
    (tester) async {
      final scanner = _Scanner(scanning: true);
      await _mount(tester, scanner, const SmartCleanView());
      expect(find.text('已讀取 1200 / 6000 個項目'), findsOneWidget);
      expect(find.text('內容分析已完成 1000 個 · 待處理 200 個'), findsOneWidget);
      expect(find.textContaining('900'), findsNothing);
      await tester.tap(find.text('取消掃描並保留進度'));
      await tester.pump();
      expect(scanner.cancelled, isTrue);
      await tester.tap(find.text('繼續掃描／重試待處理項目'));
      expect(scanner.resumeRequests, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('free account compression entry opens paywall', (tester) async {
    await _mount(
      tester,
      _Scanner(),
      const SmartCleanView(initialCategory: 'videos'),
    );
    await tester.tap(find.byTooltip('壓縮此影片'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PaywallView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final viewport in [const Size(320, 568), const Size(1366, 1024)]) {
    for (final category in ['duplicates', 'photos', 'videos']) {
      testWidgets('$viewport $category supports larger text without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          _Scanner(),
          SmartCleanView(initialCategory: category),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        if (category == 'duplicates') {
          await tester.ensureVisible(find.byTooltip('放大預覽').first);
          await tester.pump();
          await tester.tap(find.byTooltip('放大預覽').first);
          await tester.pump();
          expect(find.text('返回繼續比較'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
    testWidgets(
      '$viewport swipe review supports larger text without overflow',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          _Scanner(),
          SwipeCleanView(assets: [_photo('swipe')], title: '照片'),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
