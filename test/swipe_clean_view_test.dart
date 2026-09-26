import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';

class TestSubscription extends SubscriptionManager {
  TestSubscription(this.pro);
  final bool pro;
  @override
  bool get isPro => pro;
}

class TestScanner extends PhotoScannerService {
  int deletionRequests = 0;
  Completer<Set<String>>? pendingDeletion;
  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    deletionRequests++;
    return pendingDeletion?.future ?? {};
  }
}

void main() {
  late TestScanner scanner;
  late TestSubscription subscription;
  final asset = PhotoAsset(
    id: 'swipe-gate-test',
    width: 100,
    height: 100,
    size: 0,
    createDate: DateTime(2026),
    type: AssetType.image,
    thumbnail: Uint8List.fromList(
      img.encodePng(img.Image(width: 8, height: 8)),
    ),
  );

  Future<void> waitForDecodedPreview(WidgetTester tester) async {
    final context = tester.element(find.byType(SwipeCleanView));
    final images = tester
        .widgetList<Image>(
          find.descendant(
            of: find.byType(SwipeCleanView),
            matching: find.byType(Image),
          ),
        )
        .toList();
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> reviewForDeletion(
    WidgetTester tester, {
    required bool pro,
  }) async {
    scanner = TestScanner();
    subscription = TestSubscription(pro);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
          ChangeNotifierProvider<SubscriptionManager>.value(
            value: subscription,
          ),
        ],
        child: MaterialApp(
          home: SwipeCleanView(assets: [asset], title: '照片'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await waitForDecodedPreview(tester);
    await tester.tap(find.byTooltip('刪除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('審核完成！'), findsOneWidget);
  }

  tearDown(() {
    scanner.dispose();
    subscription.dispose();
  });

  testWidgets('free swipe cleanup opens the paywall without deleting photos', (
    tester,
  ) async {
    await reviewForDeletion(tester, pro: false);
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallView), findsOneWidget);
    expect(scanner.deletionRequests, 0);
  });

  testWidgets(
    'native cancellation leaves reviewed photos available for retry',
    (tester) async {
      await reviewForDeletion(tester, pro: true);
      await tester.tap(find.text('刪除 1 張照片'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('確認刪除'));
      await tester.pumpAndSettle();
      expect(scanner.deletionRequests, 1);
      expect(find.byType(SwipeCleanView), findsOneWidget);
      expect(find.text('刪除 1 張照片'), findsOneWidget);
      expect(find.text('未刪除任何照片，可能已取消或刪除未成功。'), findsOneWidget);
    },
  );

  Future<void> mountReview(
    WidgetTester tester,
    List<PhotoAsset> assets, {
    bool reduceMotion = false,
    bool settle = true,
  }) async {
    scanner = TestScanner();
    subscription = TestSubscription(true);
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
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SwipeCleanView(assets: assets, title: '照片'),
                  ),
                ),
                child: const Text('open review'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open review'));
    if (settle) {
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('undo after skipping restores the last actually reviewed photo', (
    tester,
  ) async {
    final photos = List.generate(
      3,
      (index) => PhotoAsset(
        id: 'review-$index',
        width: 100 + index,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
        thumbnail: asset.thumbnail,
      ),
    );
    await mountReview(tester, photos);
    await tester.tap(find.byTooltip('刪除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成 (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('撤回上一個選擇'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('0 刪除'), findsOneWidget);
    expect(find.text('100 × 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending and failed previews cannot be marked for deletion', (
    tester,
  ) async {
    final response = Completer<Uint8List?>();
    bool retrySucceeds = false;
    int thumbnailRequests = 0;
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'fetchEntityProperties':
          return {
            'id': 'pending-review',
            'type': 1,
            'width': 100,
            'height': 100,
          };
        case 'getThumb':
          thumbnailRequests++;
          return retrySucceeds ? asset.thumbnail : response.future;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final pendingAsset = PhotoAsset(
      id: 'pending-review',
      width: 100,
      height: 100,
      size: 0,
      createDate: DateTime(2026),
      type: AssetType.image,
    );
    // Avoid pumpAndSettle while the intentional preview spinner is running.
    await mountReview(tester, [pendingAsset], settle: false);
    await tester.drag(find.byType(AssetThumbnail), const Offset(-180, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('完成 (0)'), findsOneWidget);
    response.complete(null);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(AssetThumbnail), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('完成 (0)'), findsOneWidget);
    expect(scanner.deletionRequests, 0);
    retrySucceeds = true;
    await tester.tap(find.byTooltip('重新載入預覽'));
    await tester.pumpAndSettle();
    await waitForDecodedPreview(tester);
    expect(thumbnailRequests, 2);
    expect(find.byType(Image), findsOneWidget);
    final deleteTap = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byTooltip('刪除'),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(deleteTap.onTap, isNotNull);
    await tester.tap(find.byTooltip('刪除'));
    await tester.pumpAndSettle();
    expect(find.text('審核完成！'), findsOneWidget);
  });

  testWidgets('system back confirms exit and deletion blocks every exit path', (
    tester,
  ) async {
    await mountReview(tester, [asset]);
    await tester.tap(find.byTooltip('刪除'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('確定離開？'), findsOneWidget);
    await tester.tap(find.text('繼續審核'));
    await tester.pumpAndSettle();
    scanner.pendingDeletion = Completer<Set<String>>();
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認刪除'));
    await tester.pumpAndSettle();
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(SwipeCleanView), findsOneWidget);
    expect(find.text('確定離開？'), findsNothing);
    final close = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close_rounded),
    );
    expect(close.onPressed, isNull);
    scanner.pendingDeletion!.complete({'swipe-gate-test'});
    await tester.pumpAndSettle();
    expect(find.byType(SwipeCleanView), findsNothing);
    expect(find.text('open review'), findsOneWidget);
  });

  testWidgets('reduce motion advances the review without a flying animation', (
    tester,
  ) async {
    await mountReview(tester, [asset], reduceMotion: true);
    await tester.tap(find.byTooltip('刪除'));
    await tester.pump();
    expect(find.text('審核完成！'), findsOneWidget);
  });

  testWidgets(
    'large-text review scrolls vertically over the photo and still swipes horizontally',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      scanner = TestScanner();
      subscription = TestSubscription(true);
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
            home: SwipeCleanView(assets: [asset], title: '照片'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.drag(
        find.byType(AssetThumbnail).first,
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(100));
      expect(find.text('審核完成！'), findsNothing);
      expect(scanner.deletionRequests, 0);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(AssetThumbnail).first,
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('審核完成！'), findsOneWidget);
      expect(find.text('刪除 1 張照片'), findsOneWidget);
      expect(scanner.deletionRequests, 0);
    },
  );
}
