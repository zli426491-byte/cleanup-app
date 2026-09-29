import 'dart:async';
import 'package:cleanup_app/l10n/l10n.dart';

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/v2/category_grid_view.dart';
import 'package:cleanup_app/views/v2/category_intro_view.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

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
  int resumes = 0;
  @override
  ScanResult get scanResult => result;
  @override
  int get scannedAssetCount => result.allAssets.length;
  @override
  bool get hasCompletedScan => true;
  @override
  int? get availableAssetCount => 5000;
  @override
  Future<void> startContinuousScan({bool resume = false}) async {
    if (resume) resumes++;
  }
}

class _ProSubscription extends SubscriptionManager {
  @override
  bool get isPro => true;
}

Widget _home(
  PhotoScannerService scanner,
  SubscriptionManager subscription, {
  double textScale = 1,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
    ChangeNotifierProvider<SubscriptionManager>.value(value: subscription),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const HomeView(),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '46',
      buildSignature: '',
    );
  });

  testWidgets('small iPhone home supports enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scanner = _PartialScanner();
    final subscription = SubscriptionManager();
    await tester.pumpWidget(_home(scanner, subscription, textScale: 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    scanner.dispose();
    subscription.dispose();
  });

  for (final category in {
    'duplicates': GroupReviewView,
    'similar': GroupReviewView,
    'videos': CategoryGridView,
    'screenshots': CategoryGridView,
    'blurred': CategoryGridView,
    'largeFiles': CategoryGridView,
    'other': CategoryGridView,
  }.entries) {
    testWidgets(
      'home ${category.key} shows its intro once, then opens the category',
      (tester) async {
        final scanner = _PartialScanner();
        final subscription = SubscriptionManager();
        await tester.pumpWidget(_home(scanner, subscription));
        await tester.pump();
        final card = find.byKey(ValueKey('home-category-${category.key}'));
        await tester.ensureVisible(card);
        await _settle(tester);
        await tester.tap(card);
        await _settle(tester);
        expect(find.byType(CategoryIntroView), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('intro-lets-go')));
        await _settle(tester);
        expect(find.byType(category.value), findsOneWidget);
        expect(find.byType(CategoryIntroView), findsNothing);

        // The explainer is shown only on the first visit.
        await tester.pageBack();
        await _settle(tester);
        await tester.tap(card);
        await _settle(tester);
        expect(find.byType(CategoryIntroView), findsNothing);
        expect(find.byType(category.value), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        scanner.dispose();
        subscription.dispose();
      },
    );
  }

  testWidgets('free home offers PRO as an upgrade action, Pro hides it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final scanner = _PartialScanner();
    final free = SubscriptionManager();
    await tester.pumpWidget(_home(scanner, free));
    await tester.pump();
    final pro = find.byKey(const ValueKey('home-pro'));
    expect(pro, findsOneWidget);
    expect(find.bySemanticsLabel('Upgrade'), findsOneWidget);
    await tester.tap(pro);
    await tester.pumpAndSettle();
    expect(find.byType(PaywallView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    final paid = _ProSubscription();
    await tester.pumpWidget(_home(scanner, paid));
    await tester.pump();
    expect(find.byKey(const ValueKey('home-pro')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    scanner.dispose();
    free.dispose();
    paid.dispose();
    semantics.dispose();
  });

  for (final device in {
    'iPhone': const Size(390, 844),
    'iPad': const Size(1024, 1366),
  }.entries) {
    testWidgets(
      '${device.key}: a partial index is disclosed and can be continued',
      (tester) async {
        tester.view.physicalSize = device.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scanner = _PartialScanner();
        final subscription = SubscriptionManager();
        await tester.pumpWidget(_home(scanner, subscription));
        await tester.pump();
        final strings = tester.element(find.byType(HomeView)).l10n;
        expect(find.text(strings.v2ScanPaused), findsOneWidget);
        expect(find.text(strings.v2ScanningCount(1, 5000)), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('home-scan-continue')));
        await tester.pump();
        expect(scanner.resumes, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        scanner.dispose();
        subscription.dispose();
      },
    );
  }

  testWidgets(
    'deadline partial results continue from the checkpoint without re-measuring',
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
          case 'getPermissionState':
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
        if (call.method == 'deviceStorage') return null;
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
      await tester.pumpWidget(_home(scanner, subscription));
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
      final continueScan = find.byKey(const ValueKey('home-scan-continue'));
      expect(continueScan, findsOneWidget);

      final processed = scanner.attemptedAnalysisCount;
      blockPreview = true;
      final before = batches.length;
      await tester.ensureVisible(continueScan);
      await tester.tap(continueScan);
      await pumpUntil(() => batches.length > before);
      expect(batches.last.first, 'photo-$processed');
      expect(
        scanner.verifiedOriginalCount,
        1,
        reason:
            'A full restart would erase the previously measured video checkpoint.',
      );
      expect(scanner.attemptedAnalysisCount, processed);

      // Pausing from the home status keeps the snapshot and offers Continue.
      await tester.tap(find.byKey(const ValueKey('home-scan-pause')));
      await tester.pump();
      blockedPreview.complete({'assets': []});
      await pumpUntil(() => !scanner.isScanning);
      await tester.pump();
      expect(find.byKey(const ValueKey('home-scan-continue')), findsOneWidget);
      expect(scanner.verifiedOriginalCount, 1);
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
        if (call.method == 'getPermissionState') {
          return PermissionState.notDetermined.index;
        }
        if (call.method == 'getAssetPathList') return {'data': []};
        throw StateError('Unexpected Photos method ${call.method}');
      });
      addTearDown(() {
        scanner.dispose();
        subscription.dispose();
        messenger.setMockMethodCallHandler(photos, null);
      });
      await tester.pumpWidget(_home(scanner, subscription));
      await tester.pump();
      final start = find.byKey(const ValueKey('home-scan-start'));
      expect(start, findsOneWidget);
      await tester.tap(start);
      await tester.pump();
      expect(scanner.isScanning, isTrue);
      await tester.tap(find.byKey(const ValueKey('home-scan-pause')));
      await tester.pump();
      expect(scanner.isScanning, isFalse);
      expect(scanner.scannedAssetCount, 0);
      final continueScan = find.byKey(const ValueKey('home-scan-continue'));
      expect(continueScan, findsOneWidget);
      await tester.tap(continueScan);
      await tester.pump();
      expect(scanner.isScanning, isTrue);
      expect(permissionCalls, 2);
      permission.complete(PermissionState.authorized.index);
      for (var i = 0; i < 30 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.isScanning, isFalse);
      expect(scanner.scannedAssetCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

/// The partial scan keeps an honest "still checking" spinner running on
/// empty categories, so these tests pump route transitions explicitly.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
