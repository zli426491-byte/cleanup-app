import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/home/home_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:cleanup_app/views/v2/category_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _IndexedScanner extends PhotoScannerService {
  _IndexedScanner({this.scanning = false});
  final bool scanning;
  @override
  bool get isScanning => scanning;
  @override
  bool get hasCompletedScan => !scanning;
  @override
  int get scannedAssetCount => 2;
  @override
  int? get availableAssetCount => 2;
  @override
  ScanResult get scanResult => ScanResult(
    allAssets: [
      for (final type in [AssetType.image, AssetType.video])
        PhotoAsset(
          id: type.name,
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: type,
          thumbnail: Uint8List.fromList(
            img.encodePng(img.Image(width: 8, height: 8)),
          ),
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
}

class _AutoPreviewScanner extends PhotoScannerService {
  _AutoPreviewScanner({this.cancelled = false});
  final bool cancelled;
  int starts = 0;
  bool? lastResume;
  bool scanning = false;

  @override
  bool get isScanning => scanning;
  @override
  bool get wasCancelled => cancelled;
  @override
  bool get hasCompletedScan => false;
  @override
  Future<void> startContinuousScan({bool resume = false}) async {
    starts++;
    lastResume = resume;
    scanning = true;
    notifyListeners();
  }

  void finishWithoutResult() {
    scanning = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('authorized empty Home starts one preview automatically', (
    tester,
  ) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getPermissionState') {
        return PermissionState.authorized.index;
      }
      throw StateError('Unexpected Photos method ${call.method}');
    });
    final scanner = _AutoPreviewScanner();
    final subscription = SubscriptionManager();
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      scanner.dispose();
      subscription.dispose();
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
    await tester.pump();
    await tester.pump();
    expect(scanner.starts, 1);
    scanner.finishWithoutResult();
    await tester.pump();
    await tester.pump();
    expect(scanner.starts, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Home does not auto-prompt without Photos permission', (
    tester,
  ) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getPermissionState') {
        return PermissionState.denied.index;
      }
      throw StateError('Unexpected Photos method ${call.method}');
    });
    final scanner = _AutoPreviewScanner();
    final subscription = SubscriptionManager();
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      scanner.dispose();
      subscription.dispose();
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
    await tester.pump();
    expect(scanner.starts, 0);
    expect(find.byKey(const ValueKey('home-scan-start')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-scan-start')));
    await tester.pump();
    expect(scanner.starts, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelled empty Home offers Continue and never restarts itself', (
    tester,
  ) async {
    final scanner = _AutoPreviewScanner(cancelled: true);
    final subscription = SubscriptionManager();
    addTearDown(() {
      scanner.dispose();
      subscription.dispose();
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
    await tester.pump();
    expect(scanner.starts, 0);
    await tester.tap(find.byKey(const ValueKey('home-scan-continue')));
    await tester.pump();
    expect(scanner.starts, 1);
    expect(scanner.lastResume, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  for (final scanning in [false, true]) {
    testWidgets(
      'tapping a photo in Other opens swipe review there',
      (tester) async {
        SharedPreferences.setMockInitialValues({'v2.intro.other': true});
        final scanner = _IndexedScanner(scanning: scanning);
        final subscriptions = SubscriptionManager();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscriptions,
              ),
            ],
            child: MaterialApp(
              locale: const Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeView(),
            ),
          ),
        );
        await tester.pump();
        final other = find.byKey(const ValueKey('home-category-other'));
        await tester.ensureVisible(other);
        await tester.pump();
        await tester.tap(other);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CategoryGridView), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('grid-tile-image')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final review = tester.widget<SwipeCleanView>(
          find.byType(SwipeCleanView),
        );
        expect(review.assets.map((asset) => asset.id), ['image']);
        expect(review.categoryId, 'other');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        scanner.dispose();
        subscriptions.dispose();
      },
    );
  }
}