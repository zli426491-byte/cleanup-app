import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/views/scanner/delete_review.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';
import 'package:cleanup_app/views/scanner/smart_clean_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';

class ProSubscription extends SubscriptionManager {
  @override
  bool get isPro => true;
}

class GridScanner extends PhotoScannerService {
  GridScanner(this.assets) {
    _publish();
  }
  List<PhotoAsset> assets;
  late ScanResult _result;
  @override
  ScanResult get scanResult => _result;
  void _publish() {
    _result = ScanResult(
      allAssets: assets,
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

  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> toDelete) async {
    final ids = toDelete.map((asset) => asset.id).toSet();
    assets = assets.where((asset) => !ids.contains(asset.id)).toList();
    _publish();
    notifyListeners();
    return ids;
  }
}

class _ScanningGridScanner extends GridScanner {
  _ScanningGridScanner(super.assets);

  bool scanning = true;
  int cancelRequests = 0;
  int originalVerificationRequests = 0;

  @override
  bool get isScanning => scanning;

  @override
  bool get nativeOriginalAnalysisAvailable => true;

  @override
  int get scannedAssetCount => assets.length;

  @override
  int? get availableAssetCount => assets.length;

  @override
  int get totalPhotoCount => assets.length;

  @override
  int get pendingHashAssetCount => assets.length;

  @override
  int get pendingSizeAssetCount => assets.length;

  @override
  void cancelScan() {
    cancelRequests++;
    scanning = false;
    notifyListeners();
  }

  @override
  Future<void> verifyOriginals({
    OriginalVerificationTarget target = OriginalVerificationTarget.all,
  }) async {
    originalVerificationRequests++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const photosChannel = MethodChannel('com.fluttercandies/photo_manager');
  const pathsChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final thumbnail = img.encodePng(img.Image(width: 8, height: 8));
  late Directory checkpointDirectory;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    checkpointDirectory = Directory.systemTemp.createTempSync(
      'cleanup-smart-test-',
    );
    messenger.setMockMethodCallHandler(pathsChannel, (call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return checkpointDirectory.path;
      }
      throw StateError('Unexpected path API ${call.method}');
    });
    messenger.setMockMethodCallHandler(photosChannel, (call) async {
      final id = (call.arguments as Map)['id'] as String;
      switch (call.method) {
        case 'fetchEntityProperties':
          return {'id': id, 'type': 1, 'width': 100, 'height': 100};
        case 'getThumb':
          return thumbnail;
        default:
          throw StateError('Unexpected photo API ${call.method}');
      }
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(photosChannel, null);
    messenger.setMockMethodCallHandler(pathsChannel, null);
    checkpointDirectory.deleteSync(recursive: true);
  });

  testWidgets('partial preview scan can pause into a stable review snapshot', (
    tester,
  ) async {
    final scanner = _ScanningGridScanner([
      PhotoAsset(
        id: 'partial-photo',
        width: 100,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
      ),
    ]);
    final subscription = ProSubscription();
    addTearDown(scanner.dispose);
    addTearDown(subscription.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: const MaterialApp(
          home: SmartCleanView(initialCategory: 'photos'),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('scan-pause-review-card')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('select-current-category')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('scan-pause-review-action')));
    await tester.pump();
    expect(scanner.cancelRequests, 1);
    expect(find.byKey(const ValueKey('scan-pause-review-card')), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('select-current-category')),
          )
          .onPressed,
      isNotNull,
    );
    expect(scanner.originalVerificationRequests, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pausing on a resource tab does not start original checks', (
    tester,
  ) async {
    final scanner = _ScanningGridScanner([
      PhotoAsset(
        id: 'resource-pending',
        width: 100,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
      ),
    ]);
    final subscription = ProSubscription();
    addTearDown(scanner.dispose);
    addTearDown(subscription.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: const MaterialApp(
          home: SmartCleanView(initialCategory: 'duplicates'),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('尚有原始素材待驗證'), findsOneWidget);
    expect(find.textContaining('照片預覽掃描完成後'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scan-pause-review-action')));
    await tester.pump();
    await tester.pump();
    expect(scanner.cancelRequests, 1);
    expect(scanner.originalVerificationRequests, 0);
    expect(
      find.byKey(const ValueKey('resource-pending-state')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('swipe deletion clears matching grid selection when returning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cleanup.swipe.first_use_guide.v1': true,
    });
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final pixel = img.encodePng(img.Image(width: 8, height: 8));
    messenger.setMockMethodCallHandler(channel, (call) async {
      final id = (call.arguments as Map)['id'] as String;
      switch (call.method) {
        case 'fetchEntityProperties':
          return {'id': id, 'type': 1, 'width': 100, 'height': 100};
        case 'getThumb':
          return pixel;
        default:
          throw StateError('Unexpected photo API ${call.method}');
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final scanner = GridScanner(
      List.generate(
        2,
        (index) => PhotoAsset(
          id: 'grid-$index',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: AssetType.image,
        ),
      ),
    );
    final subscription = ProSubscription();
    addTearDown(scanner.dispose);
    addTearDown(subscription.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: const MaterialApp(home: SmartCleanView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('容量未取得'), findsNothing);
    expect(find.byTooltip('重新載入預覽'), findsNothing);
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(
          image.image,
          tester.element(find.byType(SmartCleanView)),
        );
      }
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AssetThumbnail).first);
    await tester.pump();
    expect(find.text('已選擇 1 個項目'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('start-category-swipe')),
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('start-category-swipe')));
      await tester.pump(const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 400));
    final continueReview = find.widgetWithText(FilledButton, '繼續審核');
    if (continueReview.evaluate().isNotEmpty) {
      await tester.ensureVisible(continueReview);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(continueReview);
      await tester.pump(const Duration(milliseconds: 400));
    }
    final swipeDelete = find.byTooltip('刪除');
    final deleteInk = find.descendant(
      of: swipeDelete,
      matching: find.byType(InkWell),
    );
    for (
      var i = 0;
      i < 20 && tester.widget<InkWell>(deleteInk).onTap == null;
      i++
    ) {
      final previews = tester
          .widgetList<Image>(
            find.descendant(
              of: find.byType(SwipeCleanView),
              matching: find.byType(Image),
            ),
          )
          .toList();
      final previewContext = tester.element(find.byType(SwipeCleanView));
      await tester.runAsync(() async {
        for (final preview in previews) {
          await precacheImage(preview.image, previewContext);
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.widget<InkWell>(deleteInk).onTap, isNotNull);
    await tester.ensureVisible(swipeDelete);
    await tester.tap(swipeDelete);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final swipeKeep = find.byTooltip('保留');
    await tester.ensureVisible(swipeKeep);
    await tester.tap(swipeKeep);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DeleteReview), findsOneWidget);
    final confirm = find.widgetWithText(
      FilledButton,
      appStringsOf().reviewConfirmCount(1),
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(find.text(appStringsOf().reviewConfirmCount(1)));
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 30 && scanner.assets.length != 1; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(scanner.assets.single.id, 'grid-1');
    expect(find.text('已選擇 1 個項目'), findsNothing);
    expect(find.text('預覽並刪除 1 個項目'), findsNothing);
  });
}
