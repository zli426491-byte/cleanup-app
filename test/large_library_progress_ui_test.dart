import 'dart:collection';
import 'package:cleanup_app/l10n/l10n.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class _TrackingAssets extends ListBase<PhotoAsset> {
  _TrackingAssets(this.items);
  final List<PhotoAsset> items;
  int reads = 0;
  @override
  int get length => items.length;
  @override
  set length(int value) => throw UnsupportedError('fixed');
  @override
  PhotoAsset operator [](int index) {
    reads++;
    return items[index];
  }

  @override
  void operator []=(int index, PhotoAsset value) =>
      throw UnsupportedError('fixed');
}

class _LargeScanner extends PhotoScannerService {
  _LargeScanner() {
    assets = _TrackingAssets(
      List.generate(
        42683,
        (i) => PhotoAsset(
          id: 'library-$i',
          width: 3000,
          height: 2000,
          size: 0,
          createDate: DateTime(2026),
          type: i == 42682 ? AssetType.video : AssetType.image,
        ),
      ),
    );
    result = ScanResult(
      allAssets: assets,
      duplicateGroups: [],
      similarGroups: [],
      screenshots: assets.items.take(2).toList(),
      largeFiles: [],
      videos: [assets.items.last],
      blurryPhotos: [],
      darkPhotos: [],
      overexposedPhotos: [],
      totalSavingsEstimate: 0,
    );
  }
  late final _TrackingAssets assets;
  late final ScanResult result;
  bool scanning = true;
  bool cancelled = false;
  int waitSeconds = 15;
  bool verifying = false;
  int resourceAttempts = 0;
  int roundProcessed = 0;
  int roundTotal = 0;
  OriginalVerificationTarget target = OriginalVerificationTarget.exactPhotos;
  int cancelRequests = 0;
  @override
  ScanResult get scanResult => result;
  @override
  bool get isScanning => scanning;
  @override
  bool get hasCompletedScan => !scanning;
  @override
  bool get wasCancelled => cancelled;
  @override
  int? get availableAssetCount => 42683;
  @override
  int get scannedAssetCount => 42683;
  @override
  int get attemptedAnalysisCount => 0;
  @override
  int get totalPhotoCount => 42682;
  @override
  int get attemptedResourceCount => resourceAttempts;
  @override
  int get originalRoundProcessed => roundProcessed;
  @override
  int? get originalRoundTotal => roundTotal;
  @override
  OriginalVerificationTarget? get originalVerificationTarget => target;
  @override
  int get analyzedAssetCount => 0;
  @override
  int get verifiedOriginalCount => 0;
  @override
  int get cloudPendingCount => 7;
  @override
  int get pendingResourceCount => 42683;
  @override
  int get pendingAnalysisCount => 42683;
  @override
  String? get scanNotice => null;
  @override
  String? get currentOperation => scanning ? '讀取本機縮圖' : null;
  @override
  int get currentWaitSeconds => waitSeconds;
  @override
  bool get isVerifyingOriginals => verifying;
  @override
  ScanPhase get currentPhase => ScanPhase.computingHashes;
  @override
  double get scanProgress => .45;
  @override
  void cancelScan() {
    cancelRequests++;
    scanning = false;
    cancelled = true;
    notifyListeners();
  }

  void tickWait() {
    waitSeconds++;
    notifyListeners();
  }
}

Future<void> _mount(
  WidgetTester tester,
  _LargeScanner scanner,
  Widget child, {
  double scale = 1,
}) async {
  final subscription = SubscriptionManager();
  addTearDown(subscription.dispose);
  addTearDown(scanner.dispose);
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          (_) async => null,
        ),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          null,
        ),
  );

  testWidgets(
    '42k slow first item reports the actual stage and cancels immediately',
    (tester) async {
      final scanner = _LargeScanner();
      await _mount(
        tester,
        scanner,
        const SmartCleanView(initialCategory: 'screenshots'),
      );
      await tester.tap(find.byTooltip('掃描詳情'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('已讀取 42683 / 42683 個項目'), findsOneWidget);
      expect(find.text('照片畫面已處理 0 / 42682 張'), findsOneWidget);
      expect(find.text('視覺分析成功 0 個'), findsNWidgets(2));
      expect(find.text('原始素材已驗證 0 個'), findsNWidgets(2));
      expect(find.text('待下載 7 個'), findsOneWidget);
      expect(find.textContaining('已等待 15 秒'), findsNWidgets(2));
      expect(find.text('45%'), findsNothing);
      final progress = tester.widget<LinearProgressIndicator>(
        find
            .descendant(
              of: find.byKey(const ValueKey('scan-details-3')),
              matching: find.byType(LinearProgressIndicator),
            )
            .first,
      );
      expect(progress.value, 0);
      scanner.tickWait();
      await tester.pump();
      expect(find.textContaining('已等待 16 秒'), findsNWidgets(2));
      Navigator.of(tester.element(find.byType(SmartCleanView))).pop();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('取消掃描並保留進度'));
      expect(scanner.cancelRequests, 1);
      expect(scanner.isScanning, isFalse);
      await tester.pump();
      expect(find.byTooltip('取消掃描並保留進度'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'indexed screenshots can be enlarged during analysis and heartbeat never re-filters 42k assets',
    (tester) async {
      final scanner = _LargeScanner();
      await _mount(
        tester,
        scanner,
        const SmartCleanView(initialCategory: 'screenshots'),
      );
      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byTooltip('放大預覽').first,
        200,
        scrollable: scrollable,
      );
      await tester.pump();
      expect(find.byType(AssetThumbnail), findsWidgets);
      final thumbnail = tester.widget<AssetThumbnail>(
        find.byType(AssetThumbnail).first,
      );
      scanner.assets.reads = 0;
      scanner.tickWait();
      await tester.pump();
      expect(
        scanner.assets.reads,
        0,
        reason: 'A wait heartbeat must not rebuild/filter the library page.',
      );
      expect(
        identical(
          thumbnail,
          tester.widget<AssetThumbnail>(find.byType(AssetThumbnail).first),
        ),
        isTrue,
      );
      expect(find.textContaining('預覽並刪除'), findsNothing);
      final selection = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('select-library-0')),
      );
      expect(selection.onTap, isNull);
      await tester.tap(find.byTooltip('放大預覽').first);
      await tester.pump();
      expect(find.text('返回繼續比較'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'home exposes indexed photos before the first analysis finishes',
    (tester) async {
      final scanner = _LargeScanner();
      await _mount(tester, scanner, const HomeView());
      expect(find.text('尚待原始素材驗證'), findsNWidgets(2));
      expect(find.text('尚待畫面分析'), findsOneWidget);
      expect(find.text('已完成 ✓'), findsNothing);
      await tester.ensureVisible(find.text('整理已載入照片'));
      await tester.pump();
      await tester.tap(find.text('整理已載入照片'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SmartCleanView), findsOneWidget);
      expect(
        tester
            .widget<SmartCleanView>(find.byType(SmartCleanView))
            .initialCategory,
        'photos',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'original verification progress counts failed attempts separately from verified success',
    (tester) async {
      final scanner = _LargeScanner()
        ..verifying = true
        ..resourceAttempts = 42683
        ..roundProcessed = 20
        ..roundTotal = 42682;
      await _mount(
        tester,
        scanner,
        const SmartCleanView(initialCategory: 'duplicates'),
      );
      await tester.tap(find.byTooltip('掃描詳情'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('已處理 20 / 42682'), findsOneWidget);
      expect(find.text(appStringsOf().scanCheckingExactTitle), findsOneWidget);
      expect(find.text('原始素材已驗證 0 個'), findsOneWidget);
      expect(find.textContaining('真重複僅包括已完成原始素材驗證'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find
            .descendant(
              of: find.byKey(const ValueKey('scan-details-1')),
              matching: find.byType(LinearProgressIndicator),
            )
            .first,
      );
      expect(progress.value, closeTo(20 / 42682, .000001));
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final viewport in [const Size(320, 568), const Size(1366, 1024)]) {
    testWidgets('42k progress and preview support $viewport with large text', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        _LargeScanner(),
        const SmartCleanView(initialCategory: 'screenshots'),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('取消掃描並保留進度'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
