import 'dart:async';
import 'dart:convert';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photos = MethodChannel('com.fluttercandies/photo_manager');
  const resources = MethodChannel('cleanup/photo_resources');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final png = img.encodePng(img.Image(width: 32, height: 32));
  final digest = sha256
      .convert(utf8.encode('identical-original-fixture'))
      .toString();
  late PhotoScannerService scanner;
  late SubscriptionManager subscriptions;
  late List<Map<String, Object>> library;
  late List<Map> inspections;
  Completer<int>? permissionResponse;
  Completer<Map<String, Object>>? originalResponse;
  var originalsUnavailable = false;
  var previewsUnavailable = false;

  Map<String, Object> asset(String id, {int type = 1}) => {
    'id': id,
    'type': type,
    'width': 2000,
    'height': 1500,
    'createDt': 1700000000,
    'modifiedDt': 1700000000,
    'title': '$id.jpg',
  };

  setUp(() {
    scanner = PhotoScannerService(supportsNativeResources: true);
    subscriptions = SubscriptionManager();
    library = [asset('original-a'), asset('original-b')];
    inspections = [];
    permissionResponse = null;
    originalResponse = null;
    originalsUnavailable = false;
    previewsUnavailable = false;
    messenger.setMockMethodCallHandler(photos, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          return permissionResponse?.future ?? PermissionState.authorized.index;
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
        case 'fetchEntityProperties':
          final id = (call.arguments as Map)['id'];
          return library.firstWhere((item) => item['id'] == id);
        case 'getThumb':
          return png;
        default:
          throw StateError('Unexpected Photos request ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(resources, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'cancelInspections') return null;
      if (call.method == 'inspectPreviews') {
        return {
          'assets': [
            for (final id in args['assetIds'] as List)
              {
                'assetId': id,
                'status': previewsUnavailable ? 'not_local' : 'local',
                if (!previewsUnavailable) 'thumbnail': png,
              },
          ],
        };
      }
      expect(call.method, 'inspectAsset');
      inspections.add(Map.of(args));
      if (originalResponse != null) return originalResponse!.future;
      if (originalsUnavailable) {
        return {'complete': false, 'sizeKnown': false};
      }
      final includeHash = args['includeHash'] == true;
      return {
        'complete': true,
        'sizeComplete': true,
        'sizeKnown': true,
        'size': 12 * 1024 * 1024,
        'hashComplete': includeHash,
        if (includeHash) 'hash': digest,
      };
    });
  });
  tearDown(() {
    scanner.dispose();
    subscriptions.dispose();
    messenger.setMockMethodCallHandler(photos, null);
    messenger.setMockMethodCallHandler(resources, null);
  });

  Future<void> mount(
    WidgetTester tester,
    String category, {
    bool active = true,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscriptions,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SmartCleanView(initialCategory: category, isActive: active),
        ),
      ),
    );
  }

  Future<void> finish(WidgetTester tester, bool Function() ready) async {
    for (var frame = 0; frame < 100 && !ready(); frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(
      ready(),
      isTrue,
      reason:
          'Real scanner result: scanning=${scanner.isScanning}, phase=${scanner.currentPhase}, indexed=${scanner.scannedAssetCount}, known=${scanner.knownSizeAssetCount}, hash=${scanner.verifiedHashAssetCount}, calls=${inspections.length}, error=${scanner.lastError}',
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'initial exact category starts real original inspections and renders SHA group',
    (tester) async {
      await mount(tester, 'duplicates');
      await finish(
        tester,
        () =>
            !scanner.isScanning &&
            scanner.scanResult.duplicateGroups.isNotEmpty,
      );
      expect(inspections, hasLength(2));
      expect(inspections.every((args) => args['includeHash'] == true), isTrue);
      expect(scanner.verifiedHashAssetCount, 2);
      expect(find.text('Exact duplicates: 2 photos'), findsOneWidget);
      expect(
        find.byKey(ValueKey('keep-suggested-duplicate:$digest')),
        findsOneWidget,
      );
      expect(find.textContaining('Selected items:'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'entering large category after preview sends size-only work and renders video',
    (tester) async {
      library = [asset('original-a'), asset('local-video', type: 2)];
      await tester.runAsync(scanner.startFullScan);
      expect(
        inspections,
        isEmpty,
        reason: 'Ordinary preview scanning still does not hash original files.',
      );
      await mount(tester, 'photos');
      await tester.pumpAndSettle();
      expect(inspections, isEmpty);
      final strings = AppLocalizations.of(
        tester.element(find.byType(SmartCleanView)),
      );
      final category = find.text(strings.scanCategoryLarge).first;
      await tester.ensureVisible(category);
      await tester.pump();
      await tester.tap(category);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.scanResult.largeFiles.isNotEmpty,
      );
      expect(inspections, isNotEmpty);
      expect(inspections.every((args) => args['includeHash'] == false), isTrue);
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(
        scanner.scanResult.largeFiles.map((a) => a.id),
        contains('local-video'),
      );
      expect(find.text('12.0 MB'), findsWidgets);
      expect(find.byKey(const ValueKey('select-local-video')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  void useNarrowPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder largeChip() => find.ancestor(
    of: find.text('Large files').first,
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.key is GlobalKey,
    ),
  );

  void expectLargeChipVisible(WidgetTester tester) {
    final chip = largeChip();
    expect(chip, findsOneWidget);
    final bounds = tester.getRect(chip);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    expect(
      find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        ),
      ),
      findsOneWidget,
    );
  }

  testWidgets(
    'automatic size verification restores the complete selected chip after reindexing',
    (tester) async {
      useNarrowPhone(tester);
      library = [
        ...List.generate(100, (index) => asset('photo-$index')),
        ...List.generate(20, (index) => asset('video-$index', type: 2)),
      ];
      await tester.runAsync(scanner.startFullScan);
      expect(scanner.scannedAssetCount, 120);
      permissionResponse = Completer<int>();
      await mount(tester, 'largeFiles');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      expect(scanner.isVerifyingOriginals, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      permissionResponse!.complete(PermissionState.authorized.index);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.knownSizeAssetCount == 120,
      );
      // Do not ensureVisible here: the production completion must restore it.
      expectLargeChipVisible(tester);
      expect(inspections, hasLength(120));
      expect(inspections.every((args) => args['includeHash'] == false), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'manual size retry restores the selected chip after clearing and restoring counts',
    (tester) async {
      useNarrowPhone(tester);
      library = [
        ...List.generate(100, (index) => asset('photo-$index')),
        ...List.generate(20, (index) => asset('video-$index', type: 2)),
      ];
      await tester.runAsync(scanner.startFullScan);
      originalsUnavailable = true;
      await mount(tester, 'largeFiles');
      await finish(
        tester,
        () => !scanner.isScanning && inspections.length == 120,
      );
      originalsUnavailable = false;
      permissionResponse = Completer<int>();
      final retry = find.byKey(const ValueKey('verify-originals-cta'));
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      expect(scanner.isVerifyingOriginals, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      permissionResponse!.complete(PermissionState.authorized.index);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.knownSizeAssetCount == 120,
      );
      expectLargeChipVisible(tester);
      expect(inspections, hasLength(240));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelled original verification reveals the selected chip and ignores late data',
    (tester) async {
      useNarrowPhone(tester);
      library = [
        ...List.generate(100, (index) => asset('photo-$index')),
        ...List.generate(20, (index) => asset('video-$index', type: 2)),
      ];
      await tester.runAsync(scanner.startFullScan);
      permissionResponse = Completer<int>();
      originalResponse = Completer<Map<String, Object>>();
      await mount(tester, 'largeFiles');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      expect(scanner.scanResult.allAssets, isEmpty);
      permissionResponse!.complete(PermissionState.authorized.index);
      for (var frame = 0; frame < 100 && inspections.isEmpty; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(inspections, hasLength(1));
      expect(scanner.scannedAssetCount, 120);
      scanner.cancelScan();
      await finish(tester, () => !scanner.isScanning);
      expectLargeChipVisible(tester);
      expect(scanner.wasCancelled, isTrue);
      originalResponse!.complete({
        'complete': true,
        'sizeKnown': true,
        'size': 12 * 1024 * 1024,
      });
      await tester.pump();
      expect(scanner.knownSizeAssetCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'completion does not reveal a category the user has left while checking',
    (tester) async {
      useNarrowPhone(tester);
      library = [
        ...List.generate(100, (index) => asset('photo-$index')),
        ...List.generate(20, (index) => asset('video-$index', type: 2)),
      ];
      await tester.runAsync(scanner.startFullScan);
      permissionResponse = Completer<int>();
      await mount(tester, 'largeFiles');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      final photosCategory = find.text('Photos').first;
      await tester.ensureVisible(photosCategory);
      await tester.pump();
      await tester.tap(photosCategory);
      await tester.pump();
      await tester.pump();
      final horizontal = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      await tester.drag(horizontal, const Offset(-200, 0));
      await tester.pump(const Duration(milliseconds: 200));
      final position = Scrollable.of(tester.element(largeChip())).position;
      expect(position.pixels, greaterThan(150));
      permissionResponse!.complete(PermissionState.authorized.index);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.knownSizeAssetCount == 120,
      );
      // Preserve the user's subsequent horizontal browsing instead of forcing
      // either the previous Large Files category or the selected Photos chip.
      expect(position.pixels, greaterThan(150));
      expect(
        find.ancestor(
          of: photosCategory,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected == true,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'loading more photos preserves confirmed capacities and allows returning to large files',
    (tester) async {
      useNarrowPhone(tester);
      library = [
        ...List.generate(100, (index) => asset('photo-$index')),
        ...List.generate(20, (index) => asset('video-$index', type: 2)),
      ];
      previewsUnavailable = true;
      await tester.runAsync(scanner.startFullScan);
      expect(scanner.pendingAnalysisCount, 100);
      await mount(tester, 'largeFiles');
      await finish(
        tester,
        () => !scanner.isScanning && scanner.knownSizeAssetCount == 120,
      );
      expectLargeChipVisible(tester);
      final verifiedSizes = {
        for (final photo in scanner.scanResult.allAssets) photo.id: photo.size,
      };
      final originalCalls = inspections.length;
      previewsUnavailable = false;
      permissionResponse = Completer<int>();
      final strings = AppLocalizations.of(
        tester.element(find.byType(SmartCleanView)),
      );
      await tester.ensureVisible(find.text('Photos').first);
      await tester.tap(find.text('Photos').first);
      await tester.pumpAndSettle();
      final resume = find.text(strings.scanPreviewMore);
      expect(resume, findsOneWidget);
      await tester.ensureVisible(resume);
      await tester.pump();
      await tester.tap(resume);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      expect(scanner.isScanning, isTrue);
      expect(scanner.isVerifyingOriginals, isFalse);
      expect(scanner.scanResult.allAssets, isEmpty);
      permissionResponse!.complete(PermissionState.authorized.index);
      await finish(
        tester,
        () => !scanner.isScanning && scanner.pendingAnalysisCount == 0,
      );
      await tester.ensureVisible(find.text('Large files').first);
      await tester.tap(find.text('Large files').first);
      await tester.pumpAndSettle();
      expectLargeChipVisible(tester);
      expect(inspections, hasLength(originalCalls));
      expect(scanner.knownSizeAssetCount, 120);
      expect({
        for (final photo in scanner.scanResult.allAssets) photo.id: photo.size,
      }, verifiedSizes);
      expect(scanner.scanResult.largeFiles, hasLength(120));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'an inactive cleanup tab waits until opened before checking originals',
    (tester) async {
      await tester.runAsync(scanner.startFullScan);
      await mount(tester, 'duplicates', active: false);
      await tester.pumpAndSettle();
      expect(inspections, isEmpty);
      expect(scanner.isScanning, isFalse);
      await mount(tester, 'duplicates');
      await finish(
        tester,
        () => !scanner.isScanning && scanner.verifiedHashAssetCount == 2,
      );
      expect(inspections, hasLength(2));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
