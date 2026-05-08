import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class SubscriptionManager extends ChangeNotifier {
  static const _revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: 'YOUR_REVENUECAT_ANDROID_API_KEY',
  );
  static const _revenueCatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: 'YOUR_REVENUECAT_IOS_API_KEY',
  );
  static const _proEntitlement = 'pro';

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

  // -----------------------------------------------------------------------
  // Initialisation
  // -----------------------------------------------------------------------

  /// Check if the API keys are placeholders (not yet configured).
  static bool _isPlaceholderKey(String key) =>
      key.trim().isEmpty || key.startsWith('YOUR_');

  /// Configure RevenueCat and check the current entitlement status.
  /// If API keys are placeholders, skip initialization safely.
  Future<void> init({required bool isIos}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiKey =
          isIos ? _revenueCatApiKeyIos : _revenueCatApiKeyAndroid;

      // Guard: skip RevenueCat if keys are not configured yet
      if (_isPlaceholderKey(apiKey)) {
        _isPlaceholder = true;
        _isPro = false;
        _availablePackages = [];
        _statusMessage = '訂閱功能尚未設定，請先加入 RevenueCat API Key。';
        debugPrint('SubscriptionManager: placeholder API key detected, '
            'skipping RevenueCat initialization. '
            'Pass REVENUECAT_*_API_KEY with --dart-define.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isPlaceholder = false;

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Listen for customer info changes.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Check initial status.
      final customerInfo = await Purchases.getCustomerInfo();
      _updateProStatus(customerInfo);

      await loadProducts();
    } catch (e) {
      debugPrint('SubscriptionManager.init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------
  // Products
  // -----------------------------------------------------------------------

  /// Fetch available products / packages from RevenueCat.
  Future<List<Package>> loadProducts() async {
    if (_isPlaceholder) {
      _availablePackages = [];
      return _availablePackages;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        _availablePackages = current.availablePackages;
        debugPrint('SubscriptionManager: loaded ${_availablePackages.length} packages');
      } else {
        _availablePackages = [];
        _statusMessage = '找不到可購買的訂閱方案，請檢查 RevenueCat Offering。';
      }
    } catch (e) {
      debugPrint('SubscriptionManager.loadProducts error: $e');
      _statusMessage = '訂閱方案載入失敗，請稍後再試。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _availablePackages;
  }

  // -----------------------------------------------------------------------
  // Purchasing
  // -----------------------------------------------------------------------

  /// Purchase a specific package. Returns true on success.
  /// If keys are placeholders, shows a "coming soon" message.
  Future<bool> purchase(Package package) async {
    if (_isPlaceholder) {
      _statusMessage = '訂閱功能尚未設定，請先加入 RevenueCat API Key。';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _updateProStatus(customerInfo);

      _isLoading = false;
      notifyListeners();
      return _isPro;
    } on PurchasesErrorCode catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('SubscriptionManager.purchase error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore previous purchases. Returns true if the user now has Pro.
  /// If keys are placeholders, shows a "coming soon" message.
  Future<bool> restorePurchases() async {
    if (_isPlaceholder) {
      _statusMessage = '訂閱功能尚未設定，請先加入 RevenueCat API Key。';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);

      _isLoading = false;
      notifyListeners();
      return _isPro;
    } catch (e) {
      debugPrint('SubscriptionManager.restorePurchases error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Pro gate
  // -----------------------------------------------------------------------

  /// Check whether the user has Pro access. If not, sets [showPaywall] to
  /// true so the UI can present the paywall. Returns true if the user is Pro.
  bool requirePro() {
    if (_isPlaceholder) return false;
    if (_isPro) return true;
    _showPaywall = true;
    notifyListeners();
    return false;
  }

  /// Dismiss the paywall without purchasing.
  void dismissPaywall() {
    _showPaywall = false;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updateProStatus(info);
    notifyListeners();
  }

  void _updateProStatus(CustomerInfo info) {
    _isPro = info.entitlements.active.containsKey(_proEntitlement);
  }
}
