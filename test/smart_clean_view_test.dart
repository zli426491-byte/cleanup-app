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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('swipe deletion clears matching grid selection when returning', (
    tester,
  ) async {
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
    await tester.tap(find.byKey(const ValueKey('start-category-swipe')));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    final continueReview = find.widgetWithText(FilledButton, '繼續審核');
    if (continueReview.evaluate().isNotEmpty) {
      await tester.tap(continueReview);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byIcon(Icons.close_rounded).first);
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byIcon(Icons.bookmark_rounded).last);
    await tester.tap(find.byIcon(Icons.bookmark_rounded).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('刪除 1 張照片'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteReview), findsOneWidget);
    await tester.tap(find.text(appStringsOf().reviewConfirmCount(1)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(scanner.assets.single.id, 'grid-1');
    expect(find.text('已選擇 1 個項目'), findsNothing);
    expect(find.text('預覽並刪除 1 個項目'), findsNothing);
  });
}
