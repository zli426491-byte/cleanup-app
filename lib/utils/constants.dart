class AppConstants {
  static const String appName = 'Cleanup';

  // RevenueCat API Keys
  static const String revenueCatAppleKey = 'YOUR_REVENUECAT_APPLE_KEY';
  static const String revenueCatGoogleKey = 'YOUR_REVENUECAT_GOOGLE_KEY';

  // Product IDs
  static const String weeklyProductId = 'com.cleanupapp.cleaner.weekly';
  static const String yearlyProductId = 'com.cleanupapp.cleaner.yearly';

  // Free tier limits
  static const int maxFreeDeletes = 5;
  static const int maxFreeCompression = 2;
  static const int maxFreeContactMerges = 3;

  // Scan thresholds
  static const int exactDuplicateThreshold = 3;
  static const int similarThreshold = 12;
  static const int largeFileThresholdBytes = 5000000; // 5MB

  // URLs
  static const String privacyPolicyUrl = 'https://zli426491-byte.github.io/cleanup-app/';
  static const String termsUrl = 'https://zli426491-byte.github.io/cleanup-app/';
}
