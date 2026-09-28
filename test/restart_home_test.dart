import 'dart:async';
import 'package:cleanup_app/l10n/l10n.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

class _PartialScanner extends PhotoScannerService {
  final result = ScanResult(
    allAssets: [
      PhotoAsset(
        id: 'partial',
        width: 8,
        height: 8,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
        thumbnail: img.encodePng(img.Image(width: 8, height: 8)),
      ),
    ],
    duplicateGroups: [],
    similarGroups: [],
    screenshots: [],
    largeFiles: [],
    videos: [],
    blurryPhotos: [],
    darkPhotos: [],
    overexposedPhotos: [],
    totalSavingsEstimate: 0,
  );
  @override
  ScanResult get scanResult => result;
  @override
  int get scannedAssetCount => result.allAssets.length;
  @override
  bool get hasCompletedScan => true;

  @override
  int? get availableAssetCount => 5000;

  @override
  String? get scanNotice => '本次僅讀取部分項目，請預覽後再決定。';
}

void main() {
  testWidgets('small iPhone home supports enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scanner = _PartialScanner();
    final subscription = SubscriptionManager();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const HomeView(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    scanner.dispose();
    subscription.dispose();
  });

  for (final category in {
    '真重複照片': 'duplicates',
    '視覺相似照片': 'similar',
    '螢幕截圖': 'screenshots',
    '大型檔案': 'largeFiles',
  }.entries) {
    testWidgets('home ${category.key} opens its matching category', (
      tester,
    ) async {
      final scanner = _PartialScanner();
      final subscription = SubscriptionManager();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
            ChangeNotifierProvider<SubscriptionManager>.value(
              value: subscription,
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text(category.key));
      await tester.tap(find.text(category.key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<SmartCleanView>(find.byType(SmartCleanView))
            .initialCategory,
        category.value,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      scanner.dispose();
      subscription.dispose();
    });
  }

  testWidgets('home does not label a free account PRO', (tester) async {
    final scanner = _PartialScanner();
    final subscription = SubscriptionManager();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    expect(find.text('PRO'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    scanner.dispose();
    subscription.dispose();
  });

  for (final device in {
    'iPhone': const Size(390, 844),
    'iPad': const Size(1024, 1366),
  }.entries) {
    testWidgets(
      '${device.key}: partial scan is disclosed and preview opens a real review page',
      (tester) async {
        tester.view.physicalSize = device.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scanner = _PartialScanner();
        final subscription = SubscriptionManager();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscription,
              ),
            ],
            child: const MaterialApp(home: HomeView()),
          ),
        );
        await tester.pump();

        expect(
          find.text(appStringsOf().homeIndexedCountWithTotal(1, 5000)),
          findsOneWidget,
        );
        expect(find.textContaining('僅讀取部分項目'), findsNothing);
        await tester.ensureVisible(find.text(appStringsOf().homeScanDetails));
        await tester.tap(find.text(appStringsOf().homeScanDetails));
        await tester.pumpAndSettle();
        expect(find.textContaining('僅讀取部分項目'), findsOneWidget);
        expect(find.text('預估可釋放'), findsNothing);
        expect(find.text('模糊照片'), findsNothing);
        expect(find.text('清理信箱'), findsNothing);
        expect(find.text('清理行事曆'), findsNothing);

        await tester.ensureVisible(find.text(appStringsOf().homeReviewReady));
        await tester.tap(find.text(appStringsOf().homeReviewReady));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(SmartCleanView), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        scanner.dispose();
        subscription.dispose();
      },
    );
  }

  testWidgets(
    'deadline partial results expose one continuation action preserving checkpoints',
    (tester) async {
      const photos = MethodChannel('com.fluttercandies/photo_manager');
      const resources = MethodChannel('cleanup/photo_resources');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final scanner = PhotoScannerService(supportsNativeResources: true);
      final subscription = SubscriptionManager();
      List<Map<String, Object>> library = [
        {
          'id': 'verified-video',
          'type': 2,
          'width': 1920,
          'height': 1080,
          'createDt': 1700000000,
          'modifiedDt': 1700000000,
        },
      ];
      final batches = <List<String>>[];
      var blockPreview = false;
      final blockedPreview = Completer<Map<String, Object>>();
      messenger.setMockMethodCallHandler(photos, (call) async {
        switch (call.method) {
          case 'requestPermissionExtend':
            return PermissionState.authorized.index;
          case 'getAssetPathList':
            return {
              'data': [
                {
                  'id': 'all',
                  'name': 'All',
                  'isAll': true,
                  'assetCount': library.length,
                },
              ],
            };
          case 'getAssetCountFromPath':
            return library.length;
          case 'getAssetListRange':
            final args = call.arguments as Map;
            return {
              'data': library.sublist(args['start'] as int, args['end'] as int),
            };
          default:
            throw StateError('Unexpected Photos method ${call.method}');
        }
      });
      messenger.setMockMethodCallHandler(resources, (call) async {
        if (call.method == 'cancelInspections') return null;
        if (call.method == 'inspectAsset') {
          return {'complete': true, 'sizeKnown': true, 'size': 9000000};
        }
        final ids = List<String>.from(
          (call.arguments as Map)['assetIds'] as List,
        );
        batches.add(ids);
        if (blockPreview) return blockedPreview.future;
        await Future<void>.delayed(const Duration(seconds: 2));
        return {
          'assets': ids
              .map((id) => {'assetId': id, 'status': 'not_local'})
              .toList(),
        };
      });
      addTearDown(() {
        scanner.dispose();
        subscription.dispose();
        messenger.setMockMethodCallHandler(photos, null);
        messenger.setMockMethodCallHandler(resources, null);
      });
      Future<void> pumpUntil(bool Function() ready) async {
        for (var i = 0; i < 500 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 2));
        }
        expect(ready(), isTrue);
      }

      final initial = scanner.startFullScan();
      await pumpUntil(() => !scanner.isScanning);
      await initial;
      final verification = scanner.verifyOriginals();
      await pumpUntil(() => !scanner.isScanning);
      await verification;
      expect(scanner.verifiedOriginalCount, 1);
      library = [
        library.single,
        for (var i = 0; i < 800; i++)
          {
            'id': 'photo-$i',
            'type': 1,
            'width': 3000,
            'height': 2000,
            'createDt': 1700000000,
            'modifiedDt': 1700000000,
          },
      ];
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
            ChangeNotifierProvider<SubscriptionManager>.value(
              value: subscription,
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      final scan = scanner.resumeScan();
      await pumpUntil(() => batches.isNotEmpty);
      for (var i = 0; i < 17 && scanner.isScanning; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      await scan;
      await tester.pump();
      expect(scanner.hasCompletedScan, isFalse);
      expect(scanner.scannedAssetCount, 801);
      expect(scanner.pendingAnalysisCount, 800);
      expect(scanner.verifiedOriginalCount, 1);
      expect(
        find.text(appStringsOf().homeIndexedCountWithTotal(801, 801)),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text(appStringsOf().homeScanDetails));
      await tester.tap(find.text(appStringsOf().homeScanDetails));
      await tester.pumpAndSettle();
      expect(find.textContaining('已達 30 秒'), findsOneWidget);
      expect(find.text(appStringsOf().homeReviewReady), findsOneWidget);
      expect(find.text(appStringsOf().homeContinueAnalysis), findsOneWidget);
      final processed = scanner.attemptedAnalysisCount;
      blockPreview = true;
      final beforeSecondary = batches.length;
      await tester.ensureVisible(
        find.text(appStringsOf().homeContinueAnalysis),
      );
      await tester.tap(find.text(appStringsOf().homeContinueAnalysis));
      await pumpUntil(() => batches.length > beforeSecondary);
      expect(batches.last.first, 'photo-$processed');
      expect(scanner.verifiedOriginalCount, 1);
      expect(scanner.attemptedAnalysisCount, processed);
      scanner.cancelScan();
      await tester.pump();
      final beforePrimary = batches.length;
      await tester.ensureVisible(
        find.text(appStringsOf().homeContinueAnalysis),
      );
      await tester.tap(find.text(appStringsOf().homeContinueAnalysis));
      await pumpUntil(() => batches.length > beforePrimary);
      expect(batches.last.first, 'photo-$processed');
      expect(
        scanner.verifiedOriginalCount,
        1,
        reason:
            'A full restart would erase the previously measured video checkpoint.',
      );
      expect(scanner.attemptedAnalysisCount, processed);
      scanner.cancelScan();
      blockedPreview.complete({'assets': []});
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'home offers an initial scan and resumes a cancellation before any assets load',
    (tester) async {
      const photos = MethodChannel('com.fluttercandies/photo_manager');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final scanner = PhotoScannerService(supportsNativeResources: false);
      final subscription = SubscriptionManager();
      final permission = Completer<int>();
      var permissionCalls = 0;
      messenger.setMockMethodCallHandler(photos, (call) async {
        if (call.method == 'requestPermissionExtend') {
          permissionCalls++;
          return permission.future;
        }
        if (call.method == 'getAssetPathList') return {'data': []};
        throw StateError('Unexpected Photos method ${call.method}');
      });
      addTearDown(() {
        scanner.dispose();
        subscription.dispose();
        messenger.setMockMethodCallHandler(photos, null);
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
            ChangeNotifierProvider<SubscriptionManager>.value(
              value: subscription,
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      expect(find.text('掃描全部可存取照片與影片'), findsOneWidget);
      expect(find.text('繼續掃描並保留進度'), findsNothing);
      await tester.tap(find.text('掃描全部可存取照片與影片'));
      await tester.pump();
      expect(scanner.isScanning, isTrue);
      await tester.ensureVisible(find.text('取消掃描並保留進度'));
      await tester.tap(find.text('取消掃描並保留進度'));
      await tester.pump();
      expect(scanner.isScanning, isFalse);
      expect(scanner.scannedAssetCount, 0);
      await tester.ensureVisible(find.text(appStringsOf().homeScanDetails));
      await tester.tap(find.text(appStringsOf().homeScanDetails));
      await tester.pumpAndSettle();
      expect(find.textContaining('已暫停'), findsOneWidget);
      expect(find.text('繼續掃描並保留進度'), findsOneWidget);
      await tester.ensureVisible(find.text('繼續掃描並保留進度'));
      await tester.tap(find.text('繼續掃描並保留進度'));
      await tester.pump();
      expect(scanner.isScanning, isTrue);
      expect(permissionCalls, 2);
      permission.complete(PermissionState.authorized.index);
      for (var i = 0; i < 30 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.isScanning, isFalse);
      expect(scanner.scannedAssetCount, 0);
      expect(find.text('掃描全部可存取照片與影片'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
