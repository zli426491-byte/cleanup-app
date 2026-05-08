import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionManager extends ChangeNotifier {
  // RevenueCat public SDK keys are intended to be embedded in client apps.
  // CI can still override them with --dart-define when needed.
  static const _defaultRevenueCatIosApiKey =
      'app1_nttjJtbdotLvIoxrLhIiTpMtivA';
  static const _revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: 'YOUR_REVENUECAT_ANDROID_API_KEY',
  );
  static const _revenueCatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: _defaultRevenueCatIosApiKey,
  );
  static const _proEntitlement = 'pro';
  static const _revenueCatTimeout = Duration(seconds: 12);

  bool _isPro = false;
  bool _isLoading = false;
  bool _showPaywall = false;
  bool _isPlaceholder = true;
  String _statusMessage = '';
  List<Package> _availablePackages = [];

  bool get isPro => _isPlaceholder ? false : _isPro;
  bool get isLoading => _isLoading;
  bool get showPaywall => _showPaywall;
  bool get isPlaceholder => _isPlaceholder;
  String get statusMessage => _statusMessage;
  List<Package> get availablePackages => List.unmodifiable(_availablePackages);

  set showPaywall(bool value) {
    _showPaywall = value;
    notifyListeners();
  }

  static bool _isPlaceholderKey(String key) =>
      key.trim().isEmpty || key.startsWith('YOUR_');

  Future<void> init({required bool isIos}) async {
    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final apiKey = isIos ? _revenueCatApiKeyIos : _revenueCatApiKeyAndroid;

      if (_isPlaceholderKey(apiKey)) {
        _isPlaceholder = true;
        _isPro = false;
        _availablePackages = [];
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

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      final customerInfo =
          await Purchases.getCustomerInfo().timeout(_revenueCatTimeout);
      _updateProStatus(customerInfo);

      await loadProducts();
    } catch (e) {
      debugPrint('SubscriptionManager.init error: $e');
      _statusMessage = '訂閱系統初始化失敗，請稍後再試。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Package>> loadProducts() async {
    if (_isPlaceholder) {
      _availablePackages = [];
      return _availablePackages;
    }

    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final offerings = await Purchases.getOfferings().timeout(
        _revenueCatTimeout,
      );
      final current = offerings.current ??
          (offerings.all.isNotEmpty ? offerings.all.values.first : null);

      if (current == null) {
        _availablePackages = [];
        _statusMessage =
            '找不到 RevenueCat Offering，請確認 default offering 已設為 Current。';
      } else {
        _availablePackages = current.availablePackages;
        _statusMessage = _availablePackages.isEmpty
            ? 'RevenueCat Offering 沒有可購買方案，請確認 weekly/yearly 產品已加入 default offering。'
            : '';
      }

      debugPrint(
        'SubscriptionManager: loaded ${_availablePackages.length} packages',
      );
    } catch (e) {
      debugPrint('SubscriptionManager.loadProducts error: $e');
      _availablePackages = [];
      _statusMessage =
          '訂閱方案載入失敗，請檢查 RevenueCat、App Store Connect 產品與網路狀態。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _availablePackages;
  }

  Future<bool> purchase(Package package) async {
    if (_isPlaceholder) {
      _statusMessage = '尚未設定 RevenueCat API Key，無法購買。';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final customerInfo = await Purchases.purchasePackage(package).timeout(
        _revenueCatTimeout,
      );
      _updateProStatus(customerInfo);
      return _isPro;
    } on PurchasesErrorCode catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _statusMessage = '購買未完成，請稍後再試。';
      return false;
    } catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _statusMessage = '購買未完成，請稍後再試。';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    if (_isPlaceholder) {
      _statusMessage = '尚未設定 RevenueCat API Key，無法恢復購買。';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _statusMessage = '';
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases().timeout(
        _revenueCatTimeout,
      );
      _updateProStatus(customerInfo);
      return _isPro;
    } catch (e) {
      debugPrint('SubscriptionManager.restorePurchases error: $e');
      _statusMessage = '找不到可恢復的購買紀錄。';
      return false;
    } finally {
      _isLoading = false;
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
    _updateProStatus(info);
    notifyListeners();
  }

  void _updateProStatus(CustomerInfo info) {
    _isPro = info.entitlements.active.containsKey(_proEntitlement);
  }
}
