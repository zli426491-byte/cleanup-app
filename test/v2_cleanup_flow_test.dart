import 'dart:async' show unawaited;
import 'dart:ui' show Tristate;

import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/v2/cleanup_category.dart';
import 'package:cleanup_app/views/v2/congratulations_view.dart';
import 'package:cleanup_app/views/v2/delete_flow.dart';
import 'package:cleanup_app/views/v2/group_review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _pixel = img.encodePng(img.Image(width: 8, height: 8));

PhotoAsset _photo(String id, {int mb = 4, bool screenshot = false}) =>
    PhotoAsset(
      id: id,
      width: 100,
      height: 100,
      size: mb * 1024 * 1024,
      sizeKnown: true,
      createDate: DateTime(2026),
      type: AssetType.image,
      isScreenshot: screenshot,
      thumbnail: _pixel,
    );

ScanResult _result() {
  final a = _photo('a');
  final b = _photo('b');
  final c = _photo('c');
  final d = _photo('d');
  final shot = _photo('shot', mb: 1, screenshot: true);
  final loose = _photo('loose');
  return ScanResult(
    allAssets: [a, b, c, d, shot, loose],
    duplicateGroups: [
      DuplicateGroup(hash: 'h', assets: [a, b], bestAssetId: 'a'),
    ],
    // b is also visually similar, but it is already an exact duplicate.
    similarGroups: [
      SimilarGroup(assets: [b, c, d], hammingDistance: 3, bestAssetId: 'd'),
    ],
    screenshots: [shot],
    largeFiles: const [],
    videos: const [],
    blurryPhotos: const [],
    darkPhotos: const [],
    overexposedPhotos: const [],
    totalSavingsEstimate: 0,
  );
}

ScanResult _withModifiedAsset(ScanResult result, String id) => ScanResult(
  allAssets: [
    for (final asset in result.allAssets)
      asset.id == id
          ? asset.copyWith(modifiedDate: DateTime(2026, 1, 2))
          : asset,
  ],
  duplicateGroups: result.duplicateGroups,
  similarGroups: result.similarGroups,
  screenshots: result.screenshots,
  largeFiles: result.largeFiles,
  videos: result.videos,
  blurryPhotos: result.blurryPhotos,
  darkPhotos: result.darkPhotos,
  overexposedPhotos: result.overexposedPhotos,
  totalSavingsEstimate: result.totalSavingsEstimate,
);

class _Scanner extends PhotoScannerService {
  _Scanner(this.result);
  ScanResult result;
  bool scanning = false;
  bool continuous = false;
  int pauses = 0;
  List<String> requested = const [];
  final List<List<PhotoAsset>> deleteCalls = [];
  Set<String>? deleteResult;

  @override
  ScanResult get scanResult => result;
  @override
  bool get isScanning => scanning;
  @override
  bool get isContinuousScanning => continuous;
  @override
  Future<void> pauseContinuousScan() async {
    pauses++;
    scanning = false;
    continuous = false;
  }

  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    // PhotoKit must never be asked while a scan round owns the library.
    expectSync(scanning, isFalse);
    deleteCalls.add(List<PhotoAsset>.of(assets));
    requested = [for (final a in assets) a.id];
    return deleteResult ?? requested.toSet();
  }
}

class _Store extends SubscriptionManager {
  _Store({this.pro = false});
  final bool pro;
  @override
  bool get isPro => pro;
  @override
  bool get isPlaceholder => false;
  @override
  bool get isLoading => false;
  @override
  bool get isInitializing => false;
  @override
  List<StoreProduct> get storeProducts => const [];
  @override
  Future<List<Package>> loadProducts() async => const [];
}

Future<BuildContext> _host(
  WidgetTester tester,
  _Scanner scanner,
  SubscriptionManager store, {
  Widget? home,
}) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
        ChangeNotifierProvider<SubscriptionManager>.value(value: store),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home:
            home ??
            Builder(
              builder: (context) {
                hostContext = context;
                return const Scaffold(body: Text('host'));
              },
            ),
      ),
    ),
  );
  await tester.pump();
  return home == null ? hostContext : tester.element(find.byWidget(home));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '46',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          (call) async => call.method == 'getThumb' ? _pixel : null,
        );
  });

  group('CategoryIndex', () {
    test('similar groups skip photos already shown as exact duplicates', () {
      final index = CategoryIndex.of(_result());
      final exact = index[CleanupCategory.duplicates];
      expect(exact.groups.single.bestId, 'a');
      expect(exact.assets.map((a) => a.id), ['a', 'b']);
      final similar = index[CleanupCategory.similars];
      expect(similar.groups.single.assets.map((a) => a.id), ['c', 'd']);
      expect(similar.groups.single.bestId, 'd');
    });

    test('Space to Clean counts every suggestion once and never the best', () {
      final index = CategoryIndex.of(_result());
      expect(index.suggested.map((a) => a.id).toSet(), {'b', 'c', 'shot'});
      expect(sumBytes(index.suggested), (4 + 4 + 1) * 1024 * 1024);
    });

    test('Other holds only photos outside every category', () {
      final index = CategoryIndex.of(_result());
      expect(index[CleanupCategory.other].assets.map((a) => a.id), ['loose']);
    });

    test('results are memoized per snapshot', () {
      final result = _result();
      expect(
        identical(CategoryIndex.of(result), CategoryIndex.of(result)),
        isTrue,
      );
    });
  });

  group('DeleteFlow', () {
    testWidgets('Pro deletes directly, pausing a running scan first', (
      tester,
    ) async {
      final scanner = _Scanner(_result())
        ..scanning = true
        ..continuous = true;
      final store = _Store(pro: true);
      final context = await _host(tester, scanner, store);
      final run = DeleteFlow.run(context, [_photo('b')], source: 'test');
      await tester.pumpAndSettle();
      expect(scanner.pauses, 1);
      expect(scanner.requested, ['b']);
      expect(find.byType(PaywallView), findsNothing);
      expect(find.byType(CongratulationsView), findsOneWidget);
      expect(
        tester
            .widget<CongratulationsView>(find.byType(CongratulationsView))
            .deletedBytes,
        4 * 1024 * 1024,
      );
      await tester.tap(find.byKey(const ValueKey('congrats-great')));
      await tester.pumpAndSettle();
      expect(await run, {'b'});
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });

    testWidgets('a flow abandoned with its screen never blocks later deletes', (
      tester,
    ) async {
      final scanner = _Scanner(_result());
      final free = _Store();
      final context = await _host(tester, scanner, free);
      // The paywall stays open and the screen is torn down underneath it.
      unawaited(DeleteFlow.run(context, [_photo('c')], source: 'test'));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      final pro = _Store(pro: true);
      final next = await _host(tester, scanner, pro);
      final run = DeleteFlow.run(next, [_photo('b')], source: 'test');
      await tester.pumpAndSettle();
      expect(scanner.requested, ['b']);
      await tester.tap(find.byKey(const ValueKey('congrats-great')));
      await tester.pumpAndSettle();
      expect(await run, {'b'});
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      free.dispose();
      pro.dispose();
    });

    testWidgets(
      'closing the paywall cancels deletion and preserves free quota',
      (tester) async {
        final scanner = _Scanner(_result());
        final store = _Store();
        final context = await _host(tester, scanner, store);
        final run = DeleteFlow.run(context, [_photo('c')], source: 'test');
        await tester.pumpAndSettle();
        expect(find.byType(PaywallView), findsOneWidget);
        expect(scanner.requested, isEmpty);
        await tester.tap(find.byKey(const ValueKey('paywall-close')));
        await tester.pumpAndSettle();
        expect(await run, isEmpty);
        expect(scanner.deleteCalls, isEmpty);
        expect(find.byType(CongratulationsView), findsNothing);
        expect(await FreeCleanupQuota.remaining(), AppConstants.maxFreeDeletes);
        await tester.pumpWidget(const SizedBox());
        scanner.dispose();
        store.dispose();
      },
    );

    testWidgets('explicit free continuation deletes and spends one cleanup', (
      tester,
    ) async {
      final scanner = _Scanner(_result());
      final store = _Store();
      final context = await _host(tester, scanner, store);
      final selected = scanner.scanResult.allAssets.firstWhere(
        (a) => a.id == 'c',
      );
      final run = DeleteFlow.run(context, [selected], source: 'test');
      await tester.pumpAndSettle();
      expect(scanner.deleteCalls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('paywall-continue-free')));
      await tester.pumpAndSettle();
      expect(scanner.requested, ['c']);
      expect(identical(scanner.deleteCalls.single.single, selected), isTrue);
      expect(
        await FreeCleanupQuota.remaining(),
        AppConstants.maxFreeDeletes - 1,
      );
      await tester.tap(find.byKey(const ValueKey('congrats-great')));
      await tester.pumpAndSettle();
      expect(await run, {'c'});
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });

    testWidgets(
      'an asset modified while the paywall is open is never deleted',
      (tester) async {
        final scanner = _Scanner(_result());
        final store = _Store();
        final context = await _host(tester, scanner, store);
        final selected = scanner.scanResult.allAssets.firstWhere(
          (a) => a.id == 'c',
        );
        final run = DeleteFlow.run(context, [selected], source: 'test');
        await tester.pumpAndSettle();
        scanner.result = _withModifiedAsset(scanner.result, 'c');
        await tester.tap(find.byKey(const ValueKey('paywall-continue-free')));
        await tester.pumpAndSettle();
        expect(await run, isEmpty);
        expect(scanner.deleteCalls, isEmpty);
        expect(find.byType(CongratulationsView), findsNothing);
        expect(await FreeCleanupQuota.remaining(), AppConstants.maxFreeDeletes);
        await tester.pumpWidget(const SizedBox());
        scanner.dispose();
        store.dispose();
      },
    );

    testWidgets('simultaneous free delete requests spend only one quota', (
      tester,
    ) async {
      final scanner = _Scanner(_result());
      final store = _Store();
      final context = await _host(tester, scanner, store);
      final first = DeleteFlow.run(context, [_photo('b')], source: 'test');
      final second = DeleteFlow.run(context, [_photo('c')], source: 'test');
      await tester.pumpAndSettle();
      expect(await second, isEmpty);
      expect(scanner.deleteCalls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('paywall-continue-free')));
      await tester.pumpAndSettle();
      expect(scanner.deleteCalls.length, 1);
      expect(scanner.requested, ['b']);
      expect(
        await FreeCleanupQuota.remaining(),
        AppConstants.maxFreeDeletes - 1,
      );
      await tester.tap(find.byKey(const ValueKey('congrats-great')));
      await tester.pumpAndSettle();
      expect(await first, {'b'});
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });

    testWidgets('a free user cannot exceed five successful cleanups', (
      tester,
    ) async {
      final scanner = _Scanner(_result());
      final store = _Store();
      final context = await _host(tester, scanner, store);
      for (var i = 0; i < AppConstants.maxFreeDeletes; i++) {
        final selected = scanner.scanResult.allAssets[i];
        final run = DeleteFlow.run(context, [selected], source: 'test');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('paywall-continue-free')));
        await tester.pumpAndSettle();
        expect(scanner.deleteCalls.length, i + 1);
        expect(identical(scanner.deleteCalls.last.single, selected), isTrue);
        expect(
          await FreeCleanupQuota.remaining(),
          AppConstants.maxFreeDeletes - i - 1,
        );
        await tester.tap(find.byKey(const ValueKey('congrats-great')));
        await tester.pumpAndSettle();
        expect(await run, {selected.id});
      }
      final sixth = DeleteFlow.run(context, [
        scanner.scanResult.allAssets.last,
      ], source: 'test');
      await tester.pumpAndSettle();
      expect(find.byType(PaywallView), findsOneWidget);
      expect(find.byKey(const ValueKey('paywall-continue-free')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('paywall-close')));
      await tester.pumpAndSettle();
      expect(await sixth, isEmpty);
      expect(scanner.deleteCalls.length, AppConstants.maxFreeDeletes);
      expect(await FreeCleanupQuota.remaining(), 0);
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });

    testWidgets(
      'with no free cleanups left, closing the paywall deletes nothing',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'v2.freeCleanupsUsed': AppConstants.maxFreeDeletes,
        });
        final scanner = _Scanner(_result());
        final store = _Store();
        final context = await _host(tester, scanner, store);
        final run = DeleteFlow.run(context, [_photo('c')], source: 'test');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('paywall-close')));
        await tester.pumpAndSettle();
        expect(await run, isEmpty);
        expect(scanner.requested, isEmpty);
        expect(find.byType(CongratulationsView), findsNothing);
        await tester.pumpWidget(const SizedBox());
        scanner.dispose();
        store.dispose();
      },
    );

    testWidgets('a free cleanup reserved before a cancelled deletion is refunded', (
      tester,
    ) async {
      final scanner = _Scanner(_result())..deleteResult = {};
      final store = _Store();
      final context = await _host(tester, scanner, store);
      final selected = scanner.scanResult.allAssets.firstWhere(
        (a) => a.id == 'c',
      );
      final run = DeleteFlow.run(context, [selected], source: 'test');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paywall-continue-free')));
      await tester.pumpAndSettle();
      expect(scanner.requested, ['c']);
      expect(await run, isEmpty);
      expect(find.byType(CongratulationsView), findsNothing);
      expect(await FreeCleanupQuota.remaining(), AppConstants.maxFreeDeletes);
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });

    testWidgets('a cancelled system confirmation shows no celebration', (
      tester,
    ) async {
      final scanner = _Scanner(_result())..deleteResult = {};
      final store = _Store(pro: true);
      final context = await _host(tester, scanner, store);
      final deleted = DeleteFlow.run(context, [_photo('c')], source: 'test');
      await tester.pumpAndSettle();
      expect(await deleted, isEmpty);
      expect(find.byType(CongratulationsView), findsNothing);
      // A free cleanup is only spent when something was really deleted.
      expect(await FreeCleanupQuota.remaining(), AppConstants.maxFreeDeletes);
      await tester.pumpWidget(const SizedBox());
      scanner.dispose();
      store.dispose();
    });
  });

  testWidgets('group review keeps the best shot and preselects the rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scanner = _Scanner(_result());
    final store = _Store(pro: true);
    const view = GroupReviewView(
      title: 'Optimize',
      sections: [CleanupCategory.duplicates, CleanupCategory.similars],
    );
    await _host(tester, scanner, store, home: view);
    final context = tester.element(find.byType(GroupReviewView));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
    bool selected(String id) =>
        tester
            .getSemantics(find.byKey(ValueKey('group-tile-$id')))
            .getSemanticsData()
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(selected('a'), isFalse);
    expect(selected('d'), isFalse);
    expect(selected('b'), isTrue);
    expect(selected('c'), isTrue);
    // Two 4 MB suggestions are ready to delete.
    expect(find.text('Delete 8 MB'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-tile-c')));
    await tester.pump();
    expect(selected('c'), isFalse);
    expect(find.text('Delete 4 MB'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    scanner.dispose();
    store.dispose();
  });
}
