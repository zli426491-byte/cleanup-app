import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:cleanup_app/views/scanner/swipe_clean_view.dart';

class TestSubscription extends SubscriptionManager {
  TestSubscription(this.pro);
  final bool pro;
  @override
  bool get isPro => pro;
}

class TestScanner extends PhotoScannerService {
  int deletionRequests = 0;
  @override
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    deletionRequests++;
    return {};
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
  );

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
    await tester.tap(find.byIcon(Icons.close_rounded).first);
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
}
