import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/semantics.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/review_checkpoint_service.dart';

class TestSubscription extends SubscriptionManager {
  TestSubscription(this.pro);
  final bool pro;
  @override
  bool get isPro => pro;
}

class TestScanner extends PhotoScannerService {
  ScanResult result = ScanResult.empty;
  void setAssets(List<PhotoAsset> assets) => result = ScanResult(
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
  @override
  ScanResult get scanResult => result;
  int deletionRequests = 0;
  List<String> lastRequested = const [];
  Completer<Set<String>>? pendingDeletion;
  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    deletionRequests++;
    lastRequested = [for (final asset in assets) asset.id];
    return pendingDeletion?.future ?? {};
  }
}

/// Widget tests exercise review interactions without a filesystem plugin.
/// Durable checkpoints and migration have separate real-file service tests.
class MemoryCheckpoint extends ReviewCheckpointService {
  final Map<String, Map<String, List<String>>> _choices = {};
  bool recovered = false;

  @override
  bool recoveredFromCorruption(String category) => recovered;

  @override
  Future<Map<String, String>> load(
    String category,
    List<PhotoAsset> assets,
  ) async {
    final rows = _choices.putIfAbsent(category, () => {});
    final versions = {
      for (final asset in assets)
        asset.id: ReviewCheckpointService.version(asset),
    };
    for (final id in versions.keys) {
      if (rows[id] != null && rows[id]![0] != versions[id]) rows.remove(id);
    }
    return {
      for (final entry in rows.entries)
        if (versions[entry.key] == entry.value[0]) entry.key: entry.value[1],
    };
  }

  @override
  void record(String category, PhotoAsset asset, String? decision) {
    final rows = _choices.putIfAbsent(category, () => {});
    if (decision == null) {
      rows.remove(asset.id);
    } else {
      rows[asset.id] = [ReviewCheckpointService.version(asset), decision];
    }
  }

  @override
  Future<void> clear(String category) async {
    _choices[category] = {};
  }

  @override
  Future<void> flush(String category) async {}
}

void main() {
  late TestScanner scanner;
  late TestSubscription subscription;
  late PhotoAsset asset;
  late MemoryCheckpoint checkpoint;
  final baseAsset = PhotoAsset(
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

  setUp(() {
    asset = baseAsset.copyWith();
    checkpoint = MemoryCheckpoint();
    SharedPreferences.setMockInitialValues({
      'cleanup.swipe.first_use_guide.v1': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fluttercandies/photo_manager'),
          (call) async {
            final args = call.arguments as Map;
            if (call.method == 'fetchEntityProperties') {
              return {'id': args['id'], 'type': 1, 'width': 100, 'height': 100};
            }
            if (call.method == 'getThumb') {
              return asset.thumbnail;
            }
            return null;
          },
        );
  });

  Future<void> waitForDecodedPreview(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1));
    final context = tester.element(find.byType(SwipeCleanView));
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
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
    scanner.setAssets([asset]);
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
          home: SwipeCleanView(
            assets: [asset],
            title: '照片',
            checkpointService: checkpoint,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await waitForDecodedPreview(tester);
    await tester.ensureVisible(find.byTooltip('刪除'));
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
      expect(scanner.deletionRequests, 1);
      expect(scanner.lastRequested, ['swipe-gate-test']);
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
    String? categoryId,
  }) async {
    scanner = TestScanner();
    scanner.setAssets(assets);
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
                    builder: (_) => SwipeCleanView(
                      assets: assets,
                      title: '照片',
                      categoryId: categoryId,
                      checkpointService: checkpoint,
                    ),
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

  testWidgets('revoked assets cannot become a stale deletion request', (
    tester,
  ) async {
    await reviewForDeletion(tester, pro: true);
    scanner.setAssets([]);
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pumpAndSettle();
    expect(scanner.deletionRequests, 0);
    expect(find.text('確認刪除 · 1 個'), findsNothing);
    expect(find.text(appStringsOf().scanReviewChanged), findsOneWidget);
  });

  testWidgets('an edit to a reviewed photo rejects its deletion', (
    tester,
  ) async {
    await reviewForDeletion(tester, pro: true);
    scanner.setAssets([asset.copyWith(modifiedDate: DateTime(2027))]);
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pumpAndSettle();
    expect(scanner.deletionRequests, 0);
    expect(find.text(appStringsOf().scanReviewChanged), findsOneWidget);
  });

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
    await tester.ensureVisible(find.byTooltip('刪除'));
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

  testWidgets(
    'restored review resumes and undo never executes saved deletion',
    (tester) async {
      final photos = List.generate(
        3,
        (i) => PhotoAsset(
          id: 'resume-$i',
          width: 100 + i,
          height: 100,
          size: 0,
          modifiedDate: DateTime(2026),
          createDate: DateTime(2026),
          type: AssetType.image,
          thumbnail: asset.thumbnail,
        ),
      );
      final store = checkpoint;
      await store.load('photos', photos);
      store.record('photos', photos[0], 'delete');
      store.record('photos', photos[1], 'keep');
      await store.flush('photos');
      await mountReview(tester, photos, reduceMotion: true);
      await tester.tap(find.byKey(const ValueKey('resume-review-checkpoint')));
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('1 刪除'), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      await tester.ensureVisible(find.byTooltip('撤回上一個選擇'));
      await tester.tap(find.byTooltip('撤回上一個選擇'));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(await checkpoint.load('photos', photos), {'resume-0': 'delete'});
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('damaged checkpoint warns without preselecting deletion', (
    tester,
  ) async {
    checkpoint.recovered = true;
    await mountReview(tester, [asset]);
    expect(find.text(appStringsOf().swipeCheckpointRecovered), findsOneWidget);
    expect(find.text(appStringsOf().swipeDeleteCount(0)), findsOneWidget);
    expect(scanner.deletionRequests, 0);
  });

  testWidgets(
    'batch choice limits current review and reset clears saved decisions',
    (tester) async {
      final photos = List.generate(
        120,
        (i) => PhotoAsset(
          id: 'batch-$i',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026, i < 60 ? 2 : 1),
          type: AssetType.image,
          thumbnail: asset.thumbnail,
        ),
      );
      await mountReview(tester, photos, reduceMotion: true);
      await tester.tap(find.byTooltip(appStringsOf().swipeReviewBatch));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButton<DateTime?>>(
            find.byWidgetPredicate((w) => w is DropdownButton<DateTime?>),
          )
          .onChanged!(DateTime(2026, 2));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, appStringsOf().scanContinue),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/60'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('保留'));
      await tester.tap(find.byTooltip('保留'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(appStringsOf().swipeReviewBatch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset-review-checkpoint')));
      await tester.pumpAndSettle();
      expect(find.text('1/120'), findsOneWidget);
      expect(await checkpoint.load('photos', photos), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'short flick advances but a slow short drag safely springs back',
    (tester) async {
      await mountReview(tester, [asset]);
      await tester.fling(
        find.byType(AssetThumbnail),
        const Offset(-60, 0),
        150,
      );
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('完成 (0)'), findsOneWidget);
      await tester.fling(
        find.byType(AssetThumbnail),
        const Offset(-60, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('審核完成！'), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
    final deleteTap = tester.widget<InkWell>(
      find.descendant(of: find.byTooltip('刪除'), matching: find.byType(InkWell)),
    );
    expect(deleteTap.onTap, isNotNull);
    await tester.ensureVisible(find.byTooltip('刪除'));
    await tester.tap(find.byTooltip('刪除'));
    await tester.pumpAndSettle();
    expect(find.text('審核完成！'), findsOneWidget);
  });

  testWidgets('system back confirms exit and deletion blocks every exit path', (
    tester,
  ) async {
    await mountReview(tester, [asset]);
    await tester.ensureVisible(find.byTooltip('刪除'));
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
    await tester.pump(const Duration(milliseconds: 100));
    await navigator.maybePop();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SwipeCleanView), findsOneWidget);
    expect(find.text('確定離開？'), findsNothing);
    final close = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.close_rounded),
    );
    expect(close.onPressed, isNull);
    scanner.pendingDeletion!.complete({'swipe-gate-test'});
    await tester.pumpAndSettle();
    // A completed deletion celebrates first, then leaves the review.
    await tester.tap(find.byKey(const ValueKey('congrats-great')));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeCleanView), findsNothing);
    expect(find.text('open review'), findsOneWidget);
  });

  testWidgets('reduce motion advances the review without a flying animation', (
    tester,
  ) async {
    await mountReview(tester, [asset], reduceMotion: true);
    await tester.ensureVisible(find.byTooltip('刪除'));
    await tester.tap(find.byTooltip('刪除'));
    await tester.pump();
    expect(find.text('審核完成！'), findsOneWidget);
  });

  testWidgets('VoiceOver tap activates keep undo and delete actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final photos = List.generate(
      3,
      (i) => PhotoAsset(
        id: 'accessible-$i',
        width: 100,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
        thumbnail: asset.thumbnail,
      ),
    );
    await mountReview(tester, photos, reduceMotion: true);
    Future<void> activate(String label) async {
      final finder = find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.label == label && w.excludeSemantics,
      );
      final node = tester.getSemantics(finder);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
    }

    await activate('保留');
    expect(find.text('2/3'), findsOneWidget);
    await activate('撤回上一個選擇');
    expect(find.text('1/3'), findsOneWidget);
    await activate('刪除');
    expect(find.text('2/3'), findsOneWidget);
    expect(scanner.deletionRequests, 0);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets(
    'directions safety and visible action labels introduce swipe review',
    (tester) async {
      await mountReview(tester, [asset]);
      expect(find.textContaining('左滑標記刪除', findRichText: true), findsOneWidget);
      expect(find.textContaining('右滑保留', findRichText: true), findsOneWidget);
      expect(find.text('照片會先加入待刪清單；按完成並確認後才刪除。'), findsOneWidget);
      expect(find.text('刪除'), findsOneWidget);
      expect(find.text('保留'), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      await tester.tap(find.byTooltip('如何滑動整理'));
      await tester.pumpAndSettle();
      expect(find.text('快速滑動整理'), findsOneWidget);
      await tester.tap(find.text('繼續審核'));
      await tester.pumpAndSettle();
      expect(find.text('快速滑動整理'), findsNothing);
      await tester.ensureVisible(find.byTooltip('保留'));
      await tester.tap(find.byTooltip('保留'));
      await tester.pumpAndSettle();
      expect(find.text('0 張要刪除 · 1 張保留'), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first review teaches physical swipe directions once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await mountReview(tester, [asset]);
    expect(find.text(appStringsOf().swipeGestureTitle), findsOneWidget);
    expect(find.text(appStringsOf().swipeGestureDelete), findsWidgets);
    expect(find.text(appStringsOf().swipeGestureKeep), findsWidgets);
    expect(find.text(appStringsOf().swipeGestureSafety), findsWidgets);
    expect(scanner.deletionRequests, 0);
    await tester.tap(
      find.widgetWithText(FilledButton, appStringsOf().swipeContinueReview),
    );
    await tester.pumpAndSettle();
    expect(find.text(appStringsOf().swipeGestureTitle), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('cleanup.swipe.first_use_guide.v1'), isTrue);
    await tester.tap(find.byTooltip(appStringsOf().swipeGestureHelp));
    await tester.pumpAndSettle();
    expect(find.text(appStringsOf().swipeGestureTitle), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    scanner.dispose();
    subscription.dispose();
    await mountReview(tester, [asset]);
    expect(find.text(appStringsOf().swipeGestureTitle), findsNothing);
  });

  testWidgets('first-use lesson offers the faster multi-select route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await mountReview(tester, [asset]);
    await tester.tap(find.byKey(const ValueKey('swipe-help-select-many')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('swipe-select-loaded')), findsOneWidget);
    expect(scanner.deletionRequests, 0);
  });

  testWidgets(
    'bulk grid marks only decoded previews, then Undo restores the last choice',
    (tester) async {
      final photos = [
        asset,
        PhotoAsset(
          id: 'loaded-batch',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: AssetType.image,
          thumbnail: asset.thumbnail,
        ),
        PhotoAsset(
          id: 'unavailable-batch',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: AssetType.image,
        ),
      ];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.fluttercandies/photo_manager'),
        (call) async {
          final args = call.arguments as Map;
          if (call.method == 'fetchEntityProperties') {
            return {'id': args['id'], 'type': 1, 'width': 100, 'height': 100};
          }
          if (call.method == 'getThumb' && args['id'] == 'unavailable-batch') {
            return null;
          }
          return asset.thumbnail;
        },
      );
      await mountReview(tester, photos, reduceMotion: true);
      await tester.tap(find.byKey(const ValueKey('swipe-select-many')));
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
      final unavailable = tester.widget<InkWell>(
        find.byKey(const ValueKey('swipe-batch-unavailable-batch')),
      );
      expect(unavailable.onTap, isNull);
      await tester.tap(find.byKey(const ValueKey('swipe-select-loaded')));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().scanSelectedCount(2)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('swipe-mark-selected')));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().swipeDeleteCount(2)), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      await tester.tap(find.byTooltip(appStringsOf().swipeUndoChoice));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().swipeDeleteCount(1)), findsOneWidget);
      expect(scanner.deletionRequests, 0);
    },
  );

  testWidgets(
    'one long drag marks only visible decoded photos and still requires review',
    (tester) async {
      final photos = List.generate(
        4,
        (index) => PhotoAsset(
          id: 'paint-$index',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: AssetType.image,
          thumbnail: index == 2 ? null : asset.thumbnail,
        ),
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.fluttercandies/photo_manager'),
        (call) async {
          final args = call.arguments as Map;
          if (call.method == 'fetchEntityProperties') {
            return {'id': args['id'], 'type': 1, 'width': 100, 'height': 100};
          }
          if (call.method == 'getThumb' && args['id'] == 'paint-2') {
            return null;
          }
          return asset.thumbnail;
        },
      );
      await mountReview(tester, photos, reduceMotion: true);
      await tester.tap(find.byKey(const ValueKey('swipe-select-many')));
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
      expect(find.text(appStringsOf().swipeDragSelectHint), findsOneWidget);

      Offset center(int index) => tester.getCenter(
        find.byKey(ValueKey('swipe-batch-preview-paint-$index')),
      );
      final gesture = await tester.startGesture(center(0));
      await tester.pump(const Duration(milliseconds: 600));
      // One pointer update skips two tile centres. Both crossed thumbnails
      // must be considered, but the failed preview in between stays excluded.
      await gesture.moveTo(center(3));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().scanSelectedCount(3)), findsOneWidget);
      expect(scanner.deletionRequests, 0);

      await tester.tap(find.byKey(const ValueKey('swipe-mark-selected')));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().swipeDeleteCount(3)), findsOneWidget);
      expect(scanner.deletionRequests, 0);
      await tester.tap(find.text(appStringsOf().swipeDoneCount(3)));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().swipeSkipRemainingTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TextButton, appStringsOf().swipeDone).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(appStringsOf().swipeDeletePhotos(3)));
      await tester.pumpAndSettle();
      // Only the three decoded photos reach the system deletion request.
      expect(scanner.deletionRequests, 1);
      expect(scanner.lastRequested, ['paint-0', 'paint-1', 'paint-3']);
    },
  );

  testWidgets('ordinary vertical drag still scrolls the bulk grid', (
    tester,
  ) async {
    final photos = List.generate(
      45,
      (index) => PhotoAsset(
        id: 'scroll-paint-$index',
        width: 100,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
        thumbnail: asset.thumbnail,
      ),
    );
    await mountReview(tester, photos, reduceMotion: true);
    await tester.tap(find.byKey(const ValueKey('swipe-select-many')));
    await tester.pumpAndSettle();
    await waitForDecodedPreview(tester);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).last,
    );
    expect(scrollable.position.pixels, 0);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('swipe-mark-selected')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'offscreen bulk selections stay ready in the final deletion review',
    (tester) async {
      final photos = List.generate(
        30,
        (index) => PhotoAsset(
          id: 'bulk-$index',
          width: 100,
          height: 100,
          size: 0,
          createDate: DateTime(2026),
          type: AssetType.image,
          thumbnail: asset.thumbnail,
        ),
      );
      await mountReview(tester, photos, reduceMotion: true);
      await tester.tap(find.byKey(const ValueKey('swipe-select-many')));
      await tester.pumpAndSettle();

      final grid = find.byType(CustomScrollView);
      for (var index = 0; index < 6; index++) {
        await waitForDecodedPreview(tester);
        await tester.drag(grid, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
      await waitForDecodedPreview(tester);
      await tester.drag(grid, const Offset(0, 1500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('swipe-select-loaded')));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().scanSelectedCount(30)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('swipe-mark-selected')));
      await tester.pumpAndSettle();
      expect(find.text(appStringsOf().swipeDeletePhotos(30)), findsOneWidget);
      expect(scanner.deletionRequests, 0);

      await tester.tap(find.text(appStringsOf().swipeDeletePhotos(30)));
      await tester.pumpAndSettle();
      // Offscreen selections stay decoded, so all 30 are requested together.
      expect(scanner.deletionRequests, 1);
      expect(scanner.lastRequested, hasLength(30));
    },
  );

  testWidgets('bulk choices are discarded if the library changes mid-review', (
    tester,
  ) async {
    final photos = [
      asset,
      PhotoAsset(
        id: 'another-bulk-photo',
        width: 100,
        height: 100,
        size: 0,
        createDate: DateTime(2026),
        type: AssetType.image,
        thumbnail: asset.thumbnail,
      ),
    ];
    await mountReview(tester, photos, reduceMotion: true);
    await tester.tap(find.byKey(const ValueKey('swipe-select-many')));
    await tester.pumpAndSettle();
    await waitForDecodedPreview(tester);
    await tester.tap(find.byKey(const ValueKey('swipe-select-loaded')));
    await tester.pumpAndSettle();

    scanner.setAssets([photos.first]);
    await tester.tap(find.byKey(const ValueKey('swipe-mark-selected')));
    await tester.pumpAndSettle();

    expect(find.text(appStringsOf().swipeDeleteCount(0)), findsOneWidget);
    expect(find.text(appStringsOf().scanReviewChanged), findsOneWidget);
    expect(scanner.deletionRequests, 0);
  });

  testWidgets('group reviews do not offer unsafe select-all deletion', (
    tester,
  ) async {
    await mountReview(tester, [asset], categoryId: 'duplicates');
    expect(find.byKey(const ValueKey('swipe-select-many')), findsNothing);
    expect(scanner.deletionRequests, 0);
  });

  testWidgets(
    'all locale action footers remain visible at 200 percent on a small phone',
    (tester) async {
      const viewport = Size(320, 568);
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      scanner = TestScanner();
      subscription = TestSubscription(true);
      checkpoint.recovered = true;
      for (final locale in AppLocalizations.supportedLocales) {
        final photo = asset.copyWith();
        scanner.setAssets([photo]);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PhotoScannerService>.value(value: scanner),
              ChangeNotifierProvider<SubscriptionManager>.value(
                value: subscription,
              ),
            ],
            child: MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: SwipeCleanView(
                assets: [photo],
                title: 'photos',
                checkpointService: checkpoint,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await waitForDecodedPreview(tester);
        final strings = lookupAppLocalizations(locale);
        expect(
          find.text(strings.swipeCheckpointRecovered),
          findsOneWidget,
          reason: locale.toLanguageTag(),
        );
        for (final label in [
          strings.swipeDelete,
          strings.swipeUndoChoice,
          strings.swipeKeep,
        ]) {
          final action = find.byTooltip(label);
          expect(
            action.hitTestable(),
            findsOneWidget,
            reason: '$locale $label',
          );
          final bounds = tester.getRect(action);
          expect(bounds.top, greaterThanOrEqualTo(0), reason: '$locale $label');
          expect(
            bounds.bottom,
            lessThanOrEqualTo(viewport.height),
            reason: '$locale $label',
          );
        }
        // Scrolling content must never move the operation footer away.
        final before = tester.getRect(
          find.byKey(const ValueKey('swipe-fixed-actions')),
        );
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('swipe-fixed-actions'))),
          before,
          reason: locale.toLanguageTag(),
        );
        expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );
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
            home: SwipeCleanView(
              assets: [asset],
              title: '照片',
              checkpointService: checkpoint,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await waitForDecodedPreview(tester);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byType(AssetThumbnail).first);
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
      await tester.ensureVisible(find.byType(AssetThumbnail).first);
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
