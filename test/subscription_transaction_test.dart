import 'dart:async';

import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _channel = MethodChannel('purchases_flutter');
const _product = StoreProduct(
  AppConstants.yearlyProductId,
  'Yearly photo cleanup',
  'Yearly',
  990,
  'NT\$990',
  'TWD',
);
const _package = Package(
  r'$rc_annual',
  PackageType.annual,
  _product,
  PresentedOfferingContext('default', null, null),
);

Map<String, dynamic> _customerInfo({bool pro = false}) {
  final entitlement = {
    'identifier': 'pro',
    'isActive': true,
    'willRenew': true,
    'latestPurchaseDate': '2026-09-26T00:00:00Z',
    'originalPurchaseDate': '2026-09-26T00:00:00Z',
    'productIdentifier': AppConstants.yearlyProductId,
    'isSandbox': true,
  };
  return {
    'originalAppUserId': 'transaction-test',
    'entitlements': {
      'all': pro ? {'pro': entitlement} : {},
      'active': pro ? {'pro': entitlement} : {},
    },
    'activeSubscriptions': pro ? [AppConstants.yearlyProductId] : [],
    'allExpirationDates': {},
    'allPurchasedProductIdentifiers': [],
    'firstSeen': '2026-09-26T00:00:00Z',
    'requestDate': '2026-09-26T00:00:00Z',
    'allPurchaseDates': {},
    'nonSubscriptionTransactions': [],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<Object?> Function(MethodCall call) transaction;
  late SubscriptionManager manager;

  setUp(() {
    manager = SubscriptionManager();
    transaction = (call) async => throw UnimplementedError(call.method);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          return switch (call.method) {
            'setupPurchases' => null,
            'getCustomerInfo' => _customerInfo(),
            'getOfferings' => {'all': {}, 'current': null},
            'getProductInfo' => [],
            _ => transaction(call),
          };
        });
  });

  tearDown(() {
    manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  final operations = <String, Future<bool> Function(SubscriptionManager)>{
    'purchasePackage': (manager) => manager.purchase(_package),
    'purchaseProduct': (manager) => manager.purchaseStoreProduct(_product),
    'restorePurchases': (manager) => manager.restorePurchases(),
  };

  for (final entry in operations.entries) {
    testWidgets('${entry.key} waits beyond 12 seconds for store confirmation', (
      tester,
    ) async {
      await tester.runAsync(() => manager.init(isIos: true));
      final response = Completer<Object?>();
      transaction = (call) {
        expect(call.method, entry.key);
        return response.future;
      };

      bool? completed;
      final result = entry.value(manager).then((value) {
        completed = value;
        return value;
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 13));

      expect(completed, isNull);
      expect(manager.isLoading, isTrue);
      expect(manager.isPro, isFalse);
      response.complete(
        entry.key == 'restorePurchases'
            ? _customerInfo(pro: true)
            : {'customerInfo': _customerInfo(pro: true)},
      );
      await tester.pump();

      expect(await result, isTrue);
      expect(manager.isPro, isTrue);
      expect(manager.isLoading, isFalse);
      expect(manager.statusMessage, isEmpty);
    });
  }

  testWidgets(
    'cancelled purchase keeps free access and gives cancellation text',
    (tester) async {
      await tester.runAsync(() => manager.init(isIos: true));
      transaction = (call) async => throw PlatformException(
        code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
      );

      expect(await manager.purchaseStoreProduct(_product), isFalse);
      expect(manager.isPro, isFalse);
      expect(manager.isLoading, isFalse);
      expect(manager.statusMessage, '已取消購買。');
    },
  );

  testWidgets('pending purchase prevents another purchase or restore', (
    tester,
  ) async {
    await tester.runAsync(() => manager.init(isIos: true));
    final response = Completer<Object?>();
    var transactionCalls = 0;
    transaction = (call) {
      transactionCalls++;
      return response.future;
    };
    final purchase = manager.purchase(_package);
    await tester.pump();

    expect(await manager.purchaseStoreProduct(_product), isFalse);
    expect(await manager.restorePurchases(), isFalse);
    expect(transactionCalls, 1);
    response.complete({'customerInfo': _customerInfo(pro: true)});
    await tester.pump();
    expect(await purchase, isTrue);
  });

  testWidgets('empty restore is distinguished from a network error', (
    tester,
  ) async {
    await tester.runAsync(() => manager.init(isIos: true));
    transaction = (call) async => _customerInfo();
    expect(await manager.restorePurchases(), isFalse);
    expect(manager.statusMessage, '找不到有效的 Pro 訂閱紀錄。');

    transaction = (call) async => throw PlatformException(
      code: PurchasesErrorCode.networkError.index.toString(),
    );
    expect(await manager.restorePurchases(), isFalse);
    expect(manager.statusMessage, '恢復購買失敗，請檢查網路後再試。');
    expect(manager.isPro, isFalse);
  });

  testWidgets('product refresh cannot unlock a pending restore transaction', (
    tester,
  ) async {
    await tester.runAsync(() => manager.init(isIos: true));
    final restoredInfo = Completer<Object?>();
    final transactionCalls = <String>[];
    transaction = (call) {
      transactionCalls.add(call.method);
      return call.method == 'restorePurchases'
          ? restoredInfo.future
          : Future.value({'customerInfo': _customerInfo()});
    };
    final restore = manager.restorePurchases();
    await tester.pump();

    // Opening the paywall with no cached products refreshes offerings while
    // StoreKit is still handling restore authentication.
    await manager.loadProducts();
    expect(manager.isLoading, isTrue);
    expect(await manager.purchase(_package), isFalse);
    expect(await manager.purchaseStoreProduct(_product), isFalse);
    expect(transactionCalls, ['restorePurchases']);

    restoredInfo.complete(_customerInfo(pro: true));
    await tester.pump();
    expect(await restore, isTrue);
    expect(manager.isLoading, isFalse);
  });

  testWidgets('background initialization keeps fetching behind SDK setup', (
    tester,
  ) async {
    final configured = Completer<Object?>();
    var offeringRequests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'setupPurchases':
              return configured.future;
            case 'getCustomerInfo':
              return _customerInfo();
            case 'getOfferings':
              offeringRequests++;
              return {'all': {}, 'current': null};
            case 'getProductInfo':
              return [];
            default:
              throw UnimplementedError(call.method);
          }
        });

    final initialized = manager.init(isIos: true);
    await tester.pump();
    expect(manager.isInitializing, isTrue);
    await manager.loadProducts();
    expect(offeringRequests, 0);
    expect(manager.isLoading, isTrue);
    expect(await manager.purchase(_package), isFalse);

    configured.complete(null);
    await tester.pump();
    await initialized;
    expect(offeringRequests, 1);
    expect(manager.isInitializing, isFalse);
    expect(manager.isLoading, isFalse);
  });

  testWidgets('explicit retry recovers SDK setup after a transient failure', (
    tester,
  ) async {
    var setupCalls = 0;
    var offeringRequests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'setupPurchases':
              setupCalls++;
              if (setupCalls == 1) {
                throw PlatformException(code: '10', message: 'Offline');
              }
              return null;
            case 'getCustomerInfo':
              return _customerInfo();
            case 'getOfferings':
              offeringRequests++;
              return {'all': {}, 'current': null};
            case 'getProductInfo':
              return [_product.toJson()];
            default:
              throw UnimplementedError(call.method);
          }
        });

    await tester.runAsync(() => manager.init(isIos: true));
    expect(manager.isLoading, isFalse);
    expect(manager.storeProducts, isEmpty);
    expect(manager.statusMessage, contains('初始化失敗'));
    await manager.loadProducts();
    expect(setupCalls, 1);
    expect(offeringRequests, 0);

    await tester.runAsync(() => manager.retry());
    expect(setupCalls, 2);
    expect(offeringRequests, 1);
    expect(manager.storeProducts.single.identifier, _product.identifier);
    expect(manager.statusMessage, isEmpty);
    expect(manager.isLoading, isFalse);
  });
}
