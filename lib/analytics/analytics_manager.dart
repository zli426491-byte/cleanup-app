// =============================================================================
// Analytics Manager - Central analytics orchestration for the Cleanup app
// =============================================================================
//
// SETUP GUIDES
// ------------
//
// --- Firebase Analytics ---
//
//  1. Create a Firebase project at https://console.firebase.google.com
//  2. Add your Android app (package name from android/app/build.gradle)
//     and iOS app (bundle ID from ios/Runner.xcodeproj).
//  3. Download google-services.json -> android/app/
//     Download GoogleService-Info.plist -> ios/Runner/
//  4. In android/build.gradle add:
//       classpath 'com.google.gms:google-services:4.4.1'
//     In android/app/build.gradle add at the bottom:
//       apply plugin: 'com.google.gms.google-services'
//  5. pubspec.yaml:
//       firebase_core: ^2.27.0
//       firebase_analytics: ^10.10.0
//  6. Call Firebase.initializeApp() before AnalyticsManager.configure().
//
// --- Adjust SDK ---
//
//  1. Create an Adjust account at https://www.adjust.com
//  2. Register your app to get an APP_TOKEN.
//  3. pubspec.yaml:
//       adjust_sdk: ^5.0.2
//  4. In configure() below, uncomment the Adjust initialization block and
//     replace 'YOUR_ADJUST_APP_TOKEN' with your real token.
//  5. For each event you want to track in the Adjust dashboard, create an
//     event token and add it to the _adjustEventTokens map.
//
// --- Facebook App Events ---
//
//  1. Create an app at https://developers.facebook.com
//  2. pubspec.yaml:
//       facebook_app_events: ^0.19.0
//  3. Android: add your Facebook App ID to android/app/src/main/res/values/strings.xml
//     and reference it in AndroidManifest.xml.
//  4. iOS: add FacebookAppID and FacebookClientToken to ios/Runner/Info.plist.
//  5. Uncomment the Facebook blocks in configure() and track() below.
//
// --- App Tracking Transparency (ATT) - iOS 14.5+ ---
//
//  Strategy:
//    - Show a pre-permission screen BEFORE the native ATT dialog. Explain
//      the value ("help us keep the app free") so the user understands why.
//    - Request ATT after onboarding is complete but before the paywall.
//    - If the user denies, respect it -- do not re-prompt. Adjust and
//      Facebook SDKs will fall back to SKAdNetwork / aggregated events.
//
//  Implementation:
//    1. pubspec.yaml:
//         app_tracking_transparency: ^2.0.6
//    2. ios/Runner/Info.plist - add:
//         <key>NSUserTrackingUsageDescription</key>
//         <string>We use this identifier to show you relevant offers and
//         to measure campaign performance.</string>
//    3. Call requestATT() from this manager after your pre-permission screen.
//    4. Pass the result to Adjust via Adjust.requestAppTrackingAuthorization()
//       and to Facebook via setAdvertiserTracking(enabled: status == authorized).
//
// =============================================================================

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

// TODO: Uncomment when firebase_analytics is added to pubspec.yaml
// import 'package:firebase_analytics/firebase_analytics.dart';

// TODO: Uncomment when adjust_sdk is added to pubspec.yaml
// import 'package:adjust_sdk/adjust.dart';
// import 'package:adjust_sdk/adjust_config.dart';
// import 'package:adjust_sdk/adjust_event.dart';

// TODO: Uncomment when facebook_app_events is added to pubspec.yaml
// import 'package:facebook_app_events/facebook_app_events.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// -----------------------------------------------------------------------------
// Analytics event names
// -----------------------------------------------------------------------------

enum AnalyticsEvent {
  // Lifecycle
  appOpened('app_opened'),
  onboardingCompleted('onboarding_completed'),

  // Scan
  scanStarted('scan_started'),
  scanCompleted('scan_completed'),

  // Photos
  photosDeleted('photos_deleted'),
  photosCompressed('photos_compressed'),

  // Contacts
  contactsMerged('contacts_merged'),
  contactsScanCompleted('contacts_scan_completed'),

  // Monetisation
  paywallShown('paywall_shown'),
  paywallClosed('paywall_closed'),
  trialStarted('trial_started'),
  subscriptionStarted('subscription_started'),

  // Secret Space
  secretSpaceUnlocked('secret_space_unlocked'),
  secretSpaceItemAdded('secret_space_item_added');

  const AnalyticsEvent(this.name);

  /// The raw string sent to every analytics provider.
  final String name;
}

// -----------------------------------------------------------------------------
// AnalyticsManager (singleton)
// -----------------------------------------------------------------------------

class AnalyticsManager {
  AnalyticsManager._internal();

  static final AnalyticsManager _instance = AnalyticsManager._internal();

  /// Access the shared instance.
  factory AnalyticsManager() => _instance;

  /// Convenience alias so call-sites can write `AnalyticsManager.instance`.
  static AnalyticsManager get instance => _instance;

  bool _configured = false;

  // TODO: Uncomment when SDKs are added
  // late final FirebaseAnalytics _firebaseAnalytics;
  // late final FacebookAppEvents _facebookAppEvents;

  // Map Adjust event tokens to your dashboard-defined tokens.
  // ignore: unused_field
  // final Map<String, String> _adjustEventTokens = {
  //   'app_opened': 'abc123',
  //   'onboarding_completed': 'def456',
  //   'scan_started': 'ghi789',
  //   'scan_completed': 'jkl012',
  //   'photos_deleted': 'mno345',
  //   'photos_compressed': 'pqr678',
  //   'contacts_merged': 'stu901',
  //   'contacts_scan_completed': 'vwx234',
  //   'paywall_shown': 'yza567',
  //   'paywall_closed': 'bcd890',
  //   'trial_started': 'efg123',
  //   'subscription_started': 'hij456',
  //   'secret_space_unlocked': 'klm789',
  //   'secret_space_item_added': 'nop012',
  // };

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Call once at app startup, after Firebase.initializeApp().
  Future<void> configure() async {
    if (_configured) return;

    // --- Firebase Analytics ---
    // TODO: Uncomment after adding firebase_analytics to pubspec.yaml
    // _firebaseAnalytics = FirebaseAnalytics.instance;
    // await _firebaseAnalytics.setAnalyticsCollectionEnabled(true);

    // --- Adjust SDK ---
    // TODO: Uncomment after adding adjust_sdk to pubspec.yaml
    // final adjustConfig = AdjustConfig(
    //   'YOUR_ADJUST_APP_TOKEN',
    //   kReleaseMode ? AdjustEnvironment.production : AdjustEnvironment.sandbox,
    // );
    // adjustConfig.logLevel = kReleaseMode ? AdjustLogLevel.suppress : AdjustLogLevel.verbose;
    // Adjust.initSdk(adjustConfig);

    // --- Facebook App Events ---
    // TODO: Uncomment after adding facebook_app_events to pubspec.yaml
    // _facebookAppEvents = FacebookAppEvents();
    // await _facebookAppEvents.setAutoLogAppEventsEnabled(true);

    _configured = true;
    _log('AnalyticsManager configured');
  }

  // ---------------------------------------------------------------------------
  // ATT (iOS)
  // ---------------------------------------------------------------------------

  /// Request App Tracking Transparency permission.
  /// Call this after your custom pre-permission screen.
  Future<void> requestATT() async {
    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      _log('ATT status: $status');

      // TODO: Forward decision to Adjust when adjust_sdk is added
      // Adjust.requestAppTrackingAuthorization();

      // TODO: Forward decision to Facebook when facebook_app_events is added
      // final granted = status == TrackingStatus.authorized;
      // await _facebookAppEvents.setAdvertiserTracking(enabled: granted);
    } catch (e) {
      _log('ATT request failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Event tracking
  // ---------------------------------------------------------------------------

  /// Track a named event across all providers.
  ///
  /// Prefer calling with an [AnalyticsEvent] value:
  /// ```dart
  /// AnalyticsManager.instance.track(
  ///   AnalyticsEvent.scanCompleted.name,
  ///   properties: {'junk_size_mb': 342},
  /// );
  /// ```
  void track(String eventName, {Map<String, dynamic>? properties}) {
    _assertConfigured();

    // --- Firebase Analytics ---
    // TODO: Uncomment after adding firebase_analytics
    // _firebaseAnalytics.logEvent(
    //   name: eventName,
    //   parameters: properties?.map(
    //     (key, value) => MapEntry(key, value is String ? value : value.toString()),
    //   ),
    // );

    // --- Adjust ---
    // TODO: Uncomment after adding adjust_sdk
    // final token = _adjustEventTokens[eventName];
    // if (token != null) {
    //   final adjustEvent = AdjustEvent(token);
    //   properties?.forEach((key, value) {
    //     adjustEvent.addCallbackParameter(key, value.toString());
    //   });
    //   Adjust.trackEvent(adjustEvent);
    // }

    // --- Facebook App Events ---
    // TODO: Uncomment after adding facebook_app_events
    // _facebookAppEvents.logEvent(
    //   name: eventName,
    //   parameters: properties?.map(
    //     (key, value) => MapEntry(key, value.toString()),
    //   ),
    // );

    _log('EVENT: $eventName${properties != null ? ' $properties' : ''}');
  }

  // ---------------------------------------------------------------------------
  // Revenue tracking
  // ---------------------------------------------------------------------------

  /// Track a revenue event (purchase / subscription renewal).
  void trackRevenue(String productId, double price, String currency) {
    _assertConfigured();

    // --- Firebase Analytics ---
    // TODO: Uncomment after adding firebase_analytics
    // _firebaseAnalytics.logEvent(
    //   name: 'purchase',
    //   parameters: {
    //     'product_id': productId,
    //     'price': price,
    //     'currency': currency,
    //   },
    // );

    // --- Adjust ---
    // TODO: Uncomment after adding adjust_sdk
    // final token = _adjustEventTokens['subscription_started'];
    // if (token != null) {
    //   final adjustEvent = AdjustEvent(token);
    //   adjustEvent.setRevenue(price, currency);
    //   adjustEvent.productId = productId;
    //   Adjust.trackEvent(adjustEvent);
    // }

    // --- Facebook App Events ---
    // TODO: Uncomment after adding facebook_app_events
    // _facebookAppEvents.logPurchase(amount: price, currency: currency);

    _log('REVENUE: product=$productId price=$price $currency');
  }

  // ---------------------------------------------------------------------------
  // User properties
  // ---------------------------------------------------------------------------

  /// Set a user-level property across all providers.
  ///
  /// Examples: subscription tier, A/B test variant, device storage class.
  void setUserProperty(String key, String value) {
    _assertConfigured();

    // --- Firebase Analytics ---
    // TODO: Uncomment after adding firebase_analytics
    // _firebaseAnalytics.setUserProperty(name: key, value: value);

    // --- Adjust ---
    // TODO: Adjust uses session callback parameters for user-level data
    // Adjust.addGlobalCallbackParameter(key, value);

    // --- Facebook App Events ---
    // TODO: Uncomment after adding facebook_app_events
    // _facebookAppEvents.setUserData(
    //   // Facebook has predefined fields; for custom data use logEvent params.
    // );

    _log('USER PROPERTY: $key = $value');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _assertConfigured() {
    if (!_configured) {
      _log('WARNING: AnalyticsManager.configure() not called yet. '
          'Ignoring event. Call configure() at app startup.');
      return;
    }
  }

  /// Print to the debug console only in debug builds.
  void _log(String message) {
    if (kDebugMode) {
      developer.log('[Analytics] $message', name: 'AnalyticsManager');
    }
  }
}
