import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:cleanup_app/views/paywall/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _product = StoreProduct(
  AppConstants.yearlyProductId,
  'Yearly photo cleanup',
  'Yearly',
  990,
  'NT\$990',
  'TWD',
);

class _BackgroundSubscription extends SubscriptionManager {
  bool pending = true;
  int purchaseCalls = 0;
  int fetchCalls = 0;
  int retryCalls = 0;

  @override
  bool get isPlaceholder => false;
  @override
  bool get isInitializing => pending;
  @override
  bool get isLoading => pending;
  @override
  List<StoreProduct> get storeProducts => pending ? [] : [_product];

  @override
  Future<List<Package>> loadProducts() async {
    fetchCalls++;
    return [];
  }

  @override
  Future<void> retry() async {
    retryCalls++;
    finishStartup();
  }

  @override
  Future<bool> purchaseStoreProduct(StoreProduct product) async {
    expect(product.identifier, AppConstants.yearlyProductId);
    purchaseCalls++;
    return false;
  }

  void finishStartup() {
    pending = false;
    notifyListeners();
  }
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cleanup',
      packageName: 'com.cleanupapp.cleaner',
      version: '1.1.3',
      buildNumber: '37',
      buildSignature: '',
    );
  });
  testWidgets('late startup products become selected and purchasable', (
    tester,
  ) async {
    final subscription = _BackgroundSubscription();
    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionManager>.value(
        value: subscription,
        child: const MaterialApp(home: PaywallView()),
      ),
    );
    await tester.pump();
    expect(subscription.fetchCalls, 0);

    subscription.finishStartup();
    await tester.pump();
    expect(find.text('年訂閱'), findsOneWidget);
    await tester.ensureVisible(find.text('繼續'));
    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(subscription.purchaseCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    subscription.dispose();
  });

  testWidgets('paywall has an explicit product recovery action', (
    tester,
  ) async {
    // Keep the offering empty to reproduce a completed but failed fetch.
    final empty = _EmptySubscription();
    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionManager>.value(
        value: empty,
        child: const MaterialApp(home: PaywallView()),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('重新載入方案'));
    await tester.tap(find.text('重新載入方案'));
    await tester.pump();
    expect(empty.retryCalls, 1);
    expect(find.text('年訂閱'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    empty.dispose();
  });
}

class _EmptySubscription extends _BackgroundSubscription {
  bool recovered = false;
  @override
  bool get isInitializing => false;
  @override
  bool get isLoading => false;
  @override
  List<StoreProduct> get storeProducts => recovered ? [_product] : [];
  @override
  Future<void> retry() async {
    retryCalls++;
    recovered = true;
    notifyListeners();
  }
}
