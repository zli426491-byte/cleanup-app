import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/constants.dart';

class SubscriptionManager extends ChangeNotifier {
  // RevenueCat public SDK keys are intended to be embedded in client apps.
  // CI can still override them with --dart-define when needed.
  static const _defaultRevenueCatIosApiKey = 'appl_nttijTbdotLvIoxrLhTiTPmTivA';
  static const _revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: 'YOUR_REVENUECAT_ANDROID_API_KEY',
  );
  static const _revenueCatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );
  static const _proEntitlements = {'pro', 'Cleanup App Pro'};
  static const _revenueCatTimeout = Duration(seconds: 12);

  bool _isPro = false;
  bool _isInitializing = false;
  bool _isLoadingProducts = false;
  bool _isTransactionInProgress = false;
  bool _isConfigured = false;
  bool _isDisposed = false;
  bool? _isIos;
  bool _showPaywall = false;
  bool _isPlaceholder = true;
  String _statusMessage = '';
  List<Package> _availablePackages = [];
  List<StoreProduct> _storeProducts = [];

  bool get isPro => _isPlaceholder ? false : _isPro;
  bool get isLoading =>
      _isInitializing || _isLoadingProducts || _isTransactionInProgress;
  bool get isInitializing => _isInitializing;
  bool get showPaywall => _showPaywall;
  bool get isPlaceholder => _isPlaceholder;
  String get statusMessage => _statusMessage;
  List<Package> get availablePackages => List.unmodifiable(_availablePackages);
  List<StoreProduct> get storeProducts => List.unmodifiable(_storeProducts);

  set showPaywall(bool value) {
    _showPaywall = value;
    notifyListeners();
  }

  static bool _isPlaceholderKey(String key) =>
      key.trim().isEmpty || key.startsWith('YOUR_');

  static String _apiKeyFor({required bool isIos}) {
    if (!isIos) return _revenueCatApiKeyAndroid;
    final key = _isPlaceholderKey(_revenueCatApiKeyIos)
        ? _defaultRevenueCatIosApiKey
        : _revenueCatApiKeyIos;
    return key.startsWith('app1_') ? 'appl_${key.substring(5)}' : key;
  }

  Future<void> init({required bool isIos}) async {
    if (_isDisposed || _isInitializing) return;
    _isIos = isIos;
    _isInitializing = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final apiKey = _apiKeyFor(isIos: isIos);

      if (_isPlaceholderKey(apiKey)) {
        _isPlaceholder = true;
        _isPro = false;
        _availablePackages = [];
        _storeProducts = [];
        _statusMessage = '尚未設定 RevenueCat API Key，訂閱功能暫時不可用。';
        debugPrint(
          'SubscriptionManager: placeholder API key detected. '
          'Pass REVENUECAT_*_API_KEY with --dart-define.',
        );
        return;
      }

      _isPlaceholder = false;

      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      ).timeout(_revenueCatTimeout);
      if (_isDisposed) return;
      _isConfigured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      final customerInfo = await Purchases.getCustomerInfo().timeout(
        _revenueCatTimeout,
      );
      _updateProStatus(customerInfo);

      await loadProducts();
    } catch (e) {
      debugPrint('SubscriptionManager.init error: $e');
      _statusMessage = '訂閱系統初始化失敗，請稍後再試。';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<List<Package>> loadProducts() async {
    if (_isDisposed || !_isConfigured || _isLoadingProducts) {
      return _availablePackages;
    }
    if (_isPlaceholder) {
      _availablePackages = [];
      _storeProducts = [];
      return _availablePackages;
    }

    _isLoadingProducts = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final offerings = await Purchases.getOfferings().timeout(
        _revenueCatTimeout,
      );
      final current =
          offerings.current ??
          (offerings.all.isNotEmpty ? offerings.all.values.first : null);

      if (current == null) {
        _availablePackages = [];
      } else {
        _availablePackages = current.availablePackages;
      }

      _storeProducts = _availablePackages
          .map((package) => package.storeProduct)
          .toList(growable: false);

      if (_storeProducts.isEmpty) {
        _storeProducts = await Purchases.getProducts(
          const [AppConstants.weeklyProductId, AppConstants.yearlyProductId],
          productCategory: ProductCategory.subscription,
        ).timeout(_revenueCatTimeout);
      }

      _statusMessage = _storeProducts.isEmpty
          ? '目前沒有可顯示的訂閱方案。請確認 RevenueCat 產品 ID 與 App Store Connect 產品一致。'
          : '';

      debugPrint(
        'SubscriptionManager: loaded ${_availablePackages.length} packages '
        'and ${_storeProducts.length} store products',
      );
    } catch (e) {
      debugPrint('SubscriptionManager.loadProducts error: $e');
      _availablePackages = [];
      _storeProducts = [];
      _statusMessage = '訂閱方案載入失敗，請檢查 RevenueCat、App Store Connect 產品與網路狀態。';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }

    return _availablePackages;
  }

  /// User-triggered recovery after a setup or product fetch failure.
  /// Do not retry automatically while StoreKit is handling another operation.
  Future<void> retry() async {
    if (_isDisposed || isLoading) return;
    if (_isConfigured) {
      await loadProducts();
    } else if (_isIos != null) {
      await init(isIos: _isIos!);
    }
  }

  Future<bool> purchase(Package package) async {
    if (_isDisposed || isLoading) return false;
    if (_isPlaceholder) {
      _statusMessage = '尚未設定 RevenueCat API Key，無法購買。';
      notifyListeners();
      return false;
    }

    _isTransactionInProgress = true;
    _statusMessage = '';
    notifyListeners();

    try {
      // Store confirmation and authentication can take longer than a fetch.
      // Keep waiting for the transaction's actual result.
      final customerInfo = await Purchases.purchasePackage(package);
      _updateProStatus(customerInfo);
      return _isPro;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _statusMessage = _purchaseErrorMessage(e);
      return false;
    } catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _statusMessage = '購買未完成，請稍後再試。';
      return false;
    } finally {
      _isTransactionInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseStoreProduct(StoreProduct product) async {
    if (_isDisposed || isLoading) return false;
    if (_isPlaceholder) {
      _statusMessage = '尚未設定 RevenueCat API Key，無法購買。';
      notifyListeners();
      return false;
    }

    _isTransactionInProgress = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final customerInfo = await Purchases.purchaseStoreProduct(product);
      _updateProStatus(customerInfo);
      return _isPro;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionManager.purchaseStoreProduct error: $e');
      _statusMessage = _purchaseErrorMessage(e);
      return false;
    } catch (e) {
      debugPrint('SubscriptionManager.purchaseStoreProduct error: $e');
      _statusMessage = '購買未完成，請稍後再試。';
      return false;
    } finally {
      _isTransactionInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    if (_isDisposed || isLoading) return false;
    if (_isPlaceholder) {
      _statusMessage = '尚未設定 RevenueCat API Key，無法恢復購買。';
      notifyListeners();
      return false;
    }

    _isTransactionInProgress = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      if (!_isPro) _statusMessage = '找不到有效的 Pro 訂閱紀錄。';
      return _isPro;
    } catch (e) {
      debugPrint('SubscriptionManager.restorePurchases error: $e');
      _statusMessage = '恢復購買失敗，請檢查網路後再試。';
      return false;
    } finally {
      _isTransactionInProgress = false;
      notifyListeners();
    }
  }

  bool requirePro() {
    if (_isPlaceholder) return false;
    if (_isPro) return true;
    _showPaywall = true;
    notifyListeners();
    return false;
  }

  void dismissPaywall() {
    _showPaywall = false;
    notifyListeners();
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    if (_isDisposed) return;
    _updateProStatus(info);
    notifyListeners();
  }

  void _updateProStatus(CustomerInfo info) {
    _isPro = info.entitlements.active.keys.any(_proEntitlements.contains);
  }

  @override
  void dispose() {
    _isDisposed = true;
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    super.dispose();
  }

  static String _purchaseErrorMessage(PlatformException error) {
    return PurchasesErrorHelper.getErrorCode(error) ==
            PurchasesErrorCode.purchaseCancelledError
        ? '已取消購買。'
        : '購買未完成，請稍後再試。';
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }
}
