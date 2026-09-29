import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @onboardingSmartTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart cleanup'**
  String get onboardingSmartTitle;

  /// No description provided for @onboardingSmartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan photos and videos you allow access to\nPreview first, then choose what to keep or delete'**
  String get onboardingSmartSubtitle;

  /// No description provided for @onboardingPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize photos'**
  String get onboardingPhotosTitle;

  /// No description provided for @onboardingPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare duplicate and similar photos by content\nReview every suggested photo to keep'**
  String get onboardingPhotosSubtitle;

  /// No description provided for @onboardingSwipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to organize'**
  String get onboardingSwipeTitle;

  /// No description provided for @onboardingSwipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to choose what to keep or delete\nConfirm all your choices when you finish'**
  String get onboardingSwipeSubtitle;

  /// No description provided for @onboardingChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'You decide'**
  String get onboardingChoiceTitle;

  /// No description provided for @onboardingChoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning and photo previews are free\nDeleting and video compression require Pro. Originals are never deleted automatically.'**
  String get onboardingChoiceSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready…'**
  String get onboardingPreparing;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Pro'**
  String get paywallTitle;

  /// No description provided for @paywallClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get paywallClose;

  /// No description provided for @paywallDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlock photo and video cleanup. Preview items before choosing what to delete.'**
  String get paywallDescription;

  /// No description provided for @paywallReloadPlans.
  ///
  /// In en, this message translates to:
  /// **'Reload plans'**
  String get paywallReloadPlans;

  /// No description provided for @paywallNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions unavailable'**
  String get paywallNotConfigured;

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallStoreNotice.
  ///
  /// In en, this message translates to:
  /// **'Purchases are completed through the App Store. Manage or cancel subscriptions in your Apple ID settings.'**
  String get paywallStoreNotice;

  /// No description provided for @paywallRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @paywallPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get paywallPrivacyPolicy;

  /// No description provided for @paywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get paywallTerms;

  /// No description provided for @paywallPurchaseIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Purchase not completed. Please try again later.'**
  String get paywallPurchaseIncomplete;

  /// No description provided for @paywallRestored.
  ///
  /// In en, this message translates to:
  /// **'Pro access restored.'**
  String get paywallRestored;

  /// No description provided for @paywallRestoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'No purchases found to restore.'**
  String get paywallRestoreNotFound;

  /// No description provided for @paywallWeeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly subscription'**
  String get paywallWeeklyPlan;

  /// No description provided for @paywallYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly subscription'**
  String get paywallYearlyPlan;

  /// No description provided for @paywallYearlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize photos and videos throughout the year'**
  String get paywallYearlySubtitle;

  /// No description provided for @paywallWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'For a short photo cleanup session'**
  String get paywallWeeklySubtitle;

  /// No description provided for @paywallPhotoFeature.
  ///
  /// In en, this message translates to:
  /// **'Delete the photos and videos you select after confirmation'**
  String get paywallPhotoFeature;

  /// No description provided for @paywallVideoFeature.
  ///
  /// In en, this message translates to:
  /// **'Compress videos, preview them, and save copies'**
  String get paywallVideoFeature;

  /// No description provided for @paywallSwipeFeature.
  ///
  /// In en, this message translates to:
  /// **'Organize quickly with swipe gestures'**
  String get paywallSwipeFeature;

  /// No description provided for @paywallPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans could not be loaded. Check your connection and reload.'**
  String get paywallPlansUnavailable;

  /// No description provided for @paywallBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get paywallBestValue;

  /// No description provided for @videoTryAnotherPreset.
  ///
  /// In en, this message translates to:
  /// **'Try another quality'**
  String get videoTryAnotherPreset;

  /// No description provided for @videoPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Compression quality'**
  String get videoPresetTitle;

  /// No description provided for @videoPresetSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller file'**
  String get videoPresetSmaller;

  /// No description provided for @videoPresetBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get videoPresetBalanced;

  /// No description provided for @videoPresetHigherQuality.
  ///
  /// In en, this message translates to:
  /// **'Higher quality'**
  String get videoPresetHigherQuality;

  /// No description provided for @videoPresetNotice.
  ///
  /// In en, this message translates to:
  /// **'The preset guides encoding. Actual file size is shown after the preview is created. The original is kept.'**
  String get videoPresetNotice;

  /// No description provided for @serviceContinuousScanLimit.
  ///
  /// In en, this message translates to:
  /// **'This continuous scan reached its time limit. Progress was saved; you can resume later.'**
  String get serviceContinuousScanLimit;

  /// No description provided for @swipeCheckpointRecovered.
  ///
  /// In en, this message translates to:
  /// **'Some saved review choices were damaged and could not be restored. Please review these photos again; nothing was deleted.'**
  String get swipeCheckpointRecovered;

  /// No description provided for @videoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video compression'**
  String get videoTitle;

  /// No description provided for @videoDescription.
  ///
  /// In en, this message translates to:
  /// **'Compression reduces quality and creates a new copy. Check the picture, sound, and orientation before saving to Photos. The original is kept.'**
  String get videoDescription;

  /// No description provided for @videoProRequired.
  ///
  /// In en, this message translates to:
  /// **'This feature requires Pro. Return to the cleanup page to view plans.'**
  String get videoProRequired;

  /// No description provided for @videoSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving to Photos. Please wait until it finishes.'**
  String get videoSaving;

  /// No description provided for @videoCancelCompression.
  ///
  /// In en, this message translates to:
  /// **'Cancel compression'**
  String get videoCancelCompression;

  /// No description provided for @videoLoadingPreview.
  ///
  /// In en, this message translates to:
  /// **'Loading video preview…'**
  String get videoLoadingPreview;

  /// No description provided for @videoCreatePreview.
  ///
  /// In en, this message translates to:
  /// **'Create a compressed preview'**
  String get videoCreatePreview;

  /// No description provided for @videoStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'Saving a copy temporarily uses more storage. After deleting the original and emptying Recently Deleted, check the system for actual available space.'**
  String get videoStorageNotice;

  /// No description provided for @videoViewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get videoViewOriginal;

  /// No description provided for @videoViewCopy.
  ///
  /// In en, this message translates to:
  /// **'View compressed copy'**
  String get videoViewCopy;

  /// No description provided for @videoSaved.
  ///
  /// In en, this message translates to:
  /// **'The copy was saved to Photos and the original was kept. Scan again from Home, then choose whether to delete the original.'**
  String get videoSaved;

  /// No description provided for @videoConfirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm the copy and save to Photos'**
  String get videoConfirmSave;

  /// No description provided for @videoPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The preview could not be played. Try again. The original is kept.'**
  String get videoPreviewUnavailable;

  /// No description provided for @videoPlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The video cannot play right now. Reload the preview.'**
  String get videoPlaybackUnavailable;

  /// No description provided for @videoOperationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The operation did not finish. The original is kept. Check Photos permission and available storage, then try again.'**
  String get videoOperationIncomplete;

  /// No description provided for @videoPauseOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original: Pause'**
  String get videoPauseOriginal;

  /// No description provided for @videoPlayOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original: Play'**
  String get videoPlayOriginal;

  /// No description provided for @videoPauseCopy.
  ///
  /// In en, this message translates to:
  /// **'Compressed copy: Pause'**
  String get videoPauseCopy;

  /// No description provided for @videoPlayCopy.
  ///
  /// In en, this message translates to:
  /// **'Compressed copy: Play'**
  String get videoPlayCopy;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @paywallBuild.
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String paywallBuild(String build);

  /// No description provided for @videoCompressionProgress.
  ///
  /// In en, this message translates to:
  /// **'Preparing / compressing video {percent}%'**
  String videoCompressionProgress(int percent);

  /// No description provided for @videoOriginalSize.
  ///
  /// In en, this message translates to:
  /// **'Original: {size}'**
  String videoOriginalSize(String size);

  /// No description provided for @videoCopySize.
  ///
  /// In en, this message translates to:
  /// **'Copy: {size}'**
  String videoCopySize(String size);

  /// No description provided for @videoSizeDifference.
  ///
  /// In en, this message translates to:
  /// **'File size difference: {size}'**
  String videoSizeDifference(String size);

  /// No description provided for @videoSizeGb.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String videoSizeGb(String size);

  /// No description provided for @videoSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String videoSizeMb(String size);

  /// No description provided for @homeStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check device storage in Settings. Here, you can organize accessible photos and videos.'**
  String get homeStorageUnavailable;

  /// No description provided for @homeViewIndexedPhotos.
  ///
  /// In en, this message translates to:
  /// **'View photos read so far'**
  String get homeViewIndexedPhotos;

  /// No description provided for @homeViewIndexedScreenshots.
  ///
  /// In en, this message translates to:
  /// **'View screenshots read so far'**
  String get homeViewIndexedScreenshots;

  /// No description provided for @homeCleanupTools.
  ///
  /// In en, this message translates to:
  /// **'Cleaning tools'**
  String get homeCleanupTools;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeAppName.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get homeAppName;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview first, then organize photos and videos'**
  String get homeSubtitle;

  /// No description provided for @homeProBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get homeProBadge;

  /// No description provided for @homeStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get homeStorageUsed;

  /// No description provided for @homeUsedLegend.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get homeUsedLegend;

  /// No description provided for @homeAvailableLegend.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get homeAvailableLegend;

  /// No description provided for @homeStartScanHint.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet. Tap below to start.'**
  String get homeStartScanHint;

  /// No description provided for @homeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get homeScanning;

  /// No description provided for @homeDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get homeDeleting;

  /// No description provided for @homeResumeScan.
  ///
  /// In en, this message translates to:
  /// **'Continue scanning and keep progress'**
  String get homeResumeScan;

  /// No description provided for @homeScanAll.
  ///
  /// In en, this message translates to:
  /// **'Scan all accessible photos and videos'**
  String get homeScanAll;

  /// No description provided for @homePreviewOrganize.
  ///
  /// In en, this message translates to:
  /// **'Preview and organize'**
  String get homePreviewOrganize;

  /// No description provided for @homeVerifyOriginals.
  ///
  /// In en, this message translates to:
  /// **'Verify local originals for exact duplicates and file sizes'**
  String get homeVerifyOriginals;

  /// No description provided for @homeRetryPending.
  ///
  /// In en, this message translates to:
  /// **'Continue scanning / retry pending items'**
  String get homeRetryPending;

  /// No description provided for @homeExactDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicate photos'**
  String get homeExactDuplicates;

  /// No description provided for @homeSimilarPhotos.
  ///
  /// In en, this message translates to:
  /// **'Visually similar photos'**
  String get homeSimilarPhotos;

  /// No description provided for @homeNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get homeNotScanned;

  /// No description provided for @homePendingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Visual analysis pending'**
  String get homePendingAnalysis;

  /// No description provided for @homeNoneAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'None found among analyzed items'**
  String get homeNoneAnalyzed;

  /// No description provided for @homeScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get homeScreenshots;

  /// No description provided for @homeLargeFiles.
  ///
  /// In en, this message translates to:
  /// **'Large files'**
  String get homeLargeFiles;

  /// No description provided for @homeNoneFound.
  ///
  /// In en, this message translates to:
  /// **'None found'**
  String get homeNoneFound;

  /// No description provided for @homePendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Original verification pending'**
  String get homePendingVerification;

  /// No description provided for @homeNoneVerified.
  ///
  /// In en, this message translates to:
  /// **'None found among verified items'**
  String get homeNoneVerified;

  /// No description provided for @homeNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get homeNeedsReview;

  /// No description provided for @homeCanReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get homeCanReview;

  /// No description provided for @homeScanStatus.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get homeScanStatus;

  /// No description provided for @homeDoneStatus.
  ///
  /// In en, this message translates to:
  /// **'Done ✓'**
  String get homeDoneStatus;

  /// No description provided for @homePreviewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Preview photos'**
  String get homePreviewPhotos;

  /// No description provided for @homeChooseKeep.
  ///
  /// In en, this message translates to:
  /// **'Choose what to keep'**
  String get homeChooseKeep;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get navClean;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get settingsLoading;

  /// No description provided for @settingsProPlan.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Pro'**
  String get settingsProPlan;

  /// No description provided for @settingsFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get settingsFreePlan;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsStorageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get settingsStorageTotal;

  /// No description provided for @settingsStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get settingsStorageUsed;

  /// No description provided for @settingsStorageAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get settingsStorageAvailable;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsProcessingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Processing subscription…'**
  String get settingsProcessingSubscription;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsRestoredPro.
  ///
  /// In en, this message translates to:
  /// **'Pro subscription restored.'**
  String get settingsRestoredPro;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTerms;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get settingsRateApp;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow system language'**
  String get settingsSystemLanguage;

  /// No description provided for @homeUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String homeUsedPercent(int percent);

  /// No description provided for @homeStorageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {size}'**
  String homeStorageTotal(String size);

  /// No description provided for @homeIndexedCount.
  ///
  /// In en, this message translates to:
  /// **'Read {count, plural, one{1 item} other{{count} items}}'**
  String homeIndexedCount(int count);

  /// No description provided for @homeIndexedCountWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Accessible items read: {count} / {total}'**
  String homeIndexedCountWithTotal(int count, int total);

  /// No description provided for @homeAnalysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Visually analyzed: {analyzed}. Originals verified: {verified}. Retention suggestions are reversible; you decide what to delete.'**
  String homeAnalysisSummary(int analyzed, int verified);

  /// No description provided for @homePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo} other{{count} photos}}'**
  String homePhotoCount(int count);

  /// No description provided for @homePhotoCountPartial.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo (partial results)} other{{count} photos (partial results)}}'**
  String homePhotoCountPartial(int count);

  /// No description provided for @homeItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item} other{{count} items}}'**
  String homeItemCount(int count);

  /// No description provided for @homeVerifiedPhotosPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo verified; more pending} other{{count} photos verified; more pending}}'**
  String homeVerifiedPhotosPending(int count);

  /// No description provided for @homeVerifiedItemsPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item verified; more pending} other{{count} items verified; more pending}}'**
  String homeVerifiedItemsPending(int count);

  /// No description provided for @settingsLanguageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Please try again.'**
  String get settingsLanguageSaveError;

  /// No description provided for @scanSmartTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart cleanup'**
  String get scanSmartTitle;

  /// No description provided for @scanCancelKeepProgress.
  ///
  /// In en, this message translates to:
  /// **'Cancel scan and keep progress'**
  String get scanCancelKeepProgress;

  /// No description provided for @scanSwipeCleanup.
  ///
  /// In en, this message translates to:
  /// **'Swipe cleanup'**
  String get scanSwipeCleanup;

  /// No description provided for @scanSortFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get scanSortFileSize;

  /// No description provided for @scanSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get scanSortNewest;

  /// No description provided for @scanStartAlbumTitle.
  ///
  /// In en, this message translates to:
  /// **'Start scanning your library'**
  String get scanStartAlbumTitle;

  /// No description provided for @scanIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan incomplete'**
  String get scanIncompleteTitle;

  /// No description provided for @scanStartAlbumDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan photo previews first to review similar pictures. Exact duplicates and large files are checked separately when you open those categories. Nothing is deleted automatically.'**
  String get scanStartAlbumDescription;

  /// No description provided for @scanContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue scan'**
  String get scanContinue;

  /// No description provided for @scanStart.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get scanStart;

  /// No description provided for @scanPreviewWhileRunning.
  ///
  /// In en, this message translates to:
  /// **'You can preview photos and screenshots. Selection, deletion and video compression are paused during scanning.'**
  String get scanPreviewWhileRunning;

  /// No description provided for @scanExactDescription.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicates include only items with verified original resources. Keep recommendations can be dismissed.'**
  String get scanExactDescription;

  /// No description provided for @scanSimilarDescription.
  ///
  /// In en, this message translates to:
  /// **'Visual candidates appear as local previews are analyzed. Their content may differ; keep recommendations are only a guide.'**
  String get scanSimilarDescription;

  /// No description provided for @scanLargeDescription.
  ///
  /// In en, this message translates to:
  /// **'Sorted by verified resource size. File size and storage actually recovered may differ; the system determines recovered space.'**
  String get scanLargeDescription;

  /// No description provided for @scanManualDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Only items you manually select and confirm will be deleted.'**
  String get scanManualDeleteDescription;

  /// No description provided for @scanVerifyOriginals.
  ///
  /// In en, this message translates to:
  /// **'Verify local originals: exact duplicates and size'**
  String get scanVerifyOriginals;

  /// No description provided for @scanResumePending.
  ///
  /// In en, this message translates to:
  /// **'Continue scan / retry pending items'**
  String get scanResumePending;

  /// No description provided for @scanKeepReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'This photo is a suggested item to keep in this group.'**
  String get scanKeepReasonDefault;

  /// No description provided for @scanRestoreKeepSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Show keep recommendation again'**
  String get scanRestoreKeepSuggestion;

  /// No description provided for @scanDismissKeepSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Dismiss keep recommendation'**
  String get scanDismissKeepSuggestion;

  /// No description provided for @scanKeepManualHint.
  ///
  /// In en, this message translates to:
  /// **'Recommendations never select items automatically. Tap a thumbnail to mark it for deletion.'**
  String get scanKeepManualHint;

  /// No description provided for @scanEmptyUnverified.
  ///
  /// In en, this message translates to:
  /// **'Some original resources still need verification. Exact duplicates and large files cannot yet be determined. You can preview photos and screenshots.'**
  String get scanEmptyUnverified;

  /// No description provided for @scanEmptyVisualPending.
  ///
  /// In en, this message translates to:
  /// **'Some photo previews still need analysis. Visual candidates will appear progressively; you can preview photos and screenshots.'**
  String get scanEmptyVisualPending;

  /// No description provided for @scanEmptyIndexing.
  ///
  /// In en, this message translates to:
  /// **'The library is still being indexed. This category will update as indexing progresses.'**
  String get scanEmptyIndexing;

  /// No description provided for @scanEmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in this category among the currently analyzed or verified items.'**
  String get scanEmptyCategory;

  /// No description provided for @scanKeepBadge.
  ///
  /// In en, this message translates to:
  /// **'Suggested keep'**
  String get scanKeepBadge;

  /// No description provided for @scanZoomPreview.
  ///
  /// In en, this message translates to:
  /// **'Enlarge preview'**
  String get scanZoomPreview;

  /// No description provided for @scanCompressVideo.
  ///
  /// In en, this message translates to:
  /// **'Compress this video'**
  String get scanCompressVideo;

  /// No description provided for @scanContentPending.
  ///
  /// In en, this message translates to:
  /// **'Content analysis pending'**
  String get scanContentPending;

  /// No description provided for @scanBackToCompare.
  ///
  /// In en, this message translates to:
  /// **'Back to comparison'**
  String get scanBackToCompare;

  /// No description provided for @scanConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete these selected items?'**
  String get scanConfirmDeleteTitle;

  /// No description provided for @scanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scanCancel;

  /// No description provided for @scanNoItemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'No items were deleted. The operation may have been canceled or failed.'**
  String get scanNoItemsDeleted;

  /// No description provided for @scanConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get scanConfirmDelete;

  /// No description provided for @scanCategoryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get scanCategoryPhotos;

  /// No description provided for @scanCategoryExact.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicates'**
  String get scanCategoryExact;

  /// No description provided for @scanCategorySimilar.
  ///
  /// In en, this message translates to:
  /// **'Visual candidates'**
  String get scanCategorySimilar;

  /// No description provided for @scanCategoryScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get scanCategoryScreenshots;

  /// No description provided for @scanCategoryVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get scanCategoryVideos;

  /// No description provided for @scanCategoryLarge.
  ///
  /// In en, this message translates to:
  /// **'Large files'**
  String get scanCategoryLarge;

  /// No description provided for @scanExactGroupCount.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicates: {count, plural, one{{count} photo} other{{count} photos}}'**
  String scanExactGroupCount(int count);

  /// No description provided for @scanSimilarGroupCount.
  ///
  /// In en, this message translates to:
  /// **'Visual candidates: {count, plural, one{{count} photo} other{{count} photos}}'**
  String scanSimilarGroupCount(int count);

  /// No description provided for @scanRecommendedKeep.
  ///
  /// In en, this message translates to:
  /// **'Suggested keep: {reason}'**
  String scanRecommendedKeep(String reason);

  /// No description provided for @scanSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected items: {count}'**
  String scanSelectedCount(int count);

  /// No description provided for @scanPreviewDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Preview and delete {count, plural, one{{count} item} other{{count} items}}'**
  String scanPreviewDeleteCount(int count);

  /// No description provided for @scanConfirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item selected} other{{count} items selected}}. Review your selection and keep recommendations before deleting. Recovered storage is determined by the system.'**
  String scanConfirmDeleteDescription(int count);

  /// No description provided for @scanItemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Items deleted: {count}.'**
  String scanItemsDeleted(int count);

  /// No description provided for @scanIndexingTitle.
  ///
  /// In en, this message translates to:
  /// **'Indexing photo library'**
  String get scanIndexingTitle;

  /// No description provided for @scanVerifyingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking original files'**
  String get scanVerifyingTitle;

  /// No description provided for @scanAnalyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing local photo previews'**
  String get scanAnalyzingTitle;

  /// No description provided for @scanSlowOperationHint.
  ///
  /// In en, this message translates to:
  /// **'This operation is taking longer. You can cancel, keep progress and continue later.'**
  String get scanSlowOperationHint;

  /// No description provided for @scanProgressPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'You can view indexed photos and screenshots. Pending downloads or unsuccessful analyses are never treated as exact duplicates.'**
  String get scanProgressPreviewHint;

  /// No description provided for @scanCountConfirming.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get scanCountConfirming;

  /// No description provided for @scanIndexedCount.
  ///
  /// In en, this message translates to:
  /// **'Indexed {indexed} / {total} items'**
  String scanIndexedCount(int indexed, String total);

  /// No description provided for @scanPreviewAttemptCount.
  ///
  /// In en, this message translates to:
  /// **'Photo previews processed: {attempted} / {total}'**
  String scanPreviewAttemptCount(int attempted, int total);

  /// No description provided for @scanOriginalAttemptCount.
  ///
  /// In en, this message translates to:
  /// **'Original resources processed: {attempted} / {total}'**
  String scanOriginalAttemptCount(int attempted, int total);

  /// No description provided for @scanVisualSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Visual analyses completed: {count}'**
  String scanVisualSuccessCount(int count);

  /// No description provided for @scanOriginalVerifiedCount.
  ///
  /// In en, this message translates to:
  /// **'Originals verified: {count}'**
  String scanOriginalVerifiedCount(int count);

  /// No description provided for @scanCloudPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending download: {count}'**
  String scanCloudPendingCount(int count);

  /// No description provided for @scanStageRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'Not yet processed in this stage: {count}'**
  String scanStageRemainingCount(int count);

  /// No description provided for @scanOperationWait.
  ///
  /// In en, this message translates to:
  /// **'{operation} · Waiting {seconds} seconds'**
  String scanOperationWait(String operation, int seconds);

  /// No description provided for @swipeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get swipeKeep;

  /// No description provided for @swipeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get swipeDelete;

  /// No description provided for @swipeReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete!'**
  String get swipeReviewComplete;

  /// No description provided for @swipeRecoveredSpaceHint.
  ///
  /// In en, this message translates to:
  /// **'Recovered storage is determined by the system.'**
  String get swipeRecoveredSpaceHint;

  /// No description provided for @swipeUndoChoice.
  ///
  /// In en, this message translates to:
  /// **'Undo last choice'**
  String get swipeUndoChoice;

  /// No description provided for @swipeBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get swipeBack;

  /// No description provided for @swipeConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the photos marked for deletion?'**
  String get swipeConfirmDeleteTitle;

  /// No description provided for @swipeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get swipeCancel;

  /// No description provided for @swipeConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get swipeConfirmDelete;

  /// No description provided for @swipeNoPhotosDeleted.
  ///
  /// In en, this message translates to:
  /// **'No photos were deleted. The operation may have been canceled or failed.'**
  String get swipeNoPhotosDeleted;

  /// No description provided for @swipeExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this review?'**
  String get swipeExitTitle;

  /// No description provided for @swipeContinueReview.
  ///
  /// In en, this message translates to:
  /// **'Continue review'**
  String get swipeContinueReview;

  /// No description provided for @swipeLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get swipeLeave;

  /// No description provided for @swipeSkipRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip remaining photos?'**
  String get swipeSkipRemainingTitle;

  /// No description provided for @swipeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get swipeDone;

  /// No description provided for @swipeDoneCount.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String swipeDoneCount(int count);

  /// No description provided for @swipeProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String swipeProgressCount(int current, int total);

  /// No description provided for @swipeDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete: {count}'**
  String swipeDeleteCount(int count);

  /// No description provided for @swipeKeepCount.
  ///
  /// In en, this message translates to:
  /// **'Keep: {count}'**
  String swipeKeepCount(int count);

  /// No description provided for @swipeReviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{deleteCount, plural, one{{deleteCount} photo} other{{deleteCount} photos}} to delete · {keepCount, plural, one{{keepCount} photo} other{{keepCount} photos}} to keep'**
  String swipeReviewSummary(int deleteCount, int keepCount);

  /// No description provided for @swipeDeletePhotos.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, one{{count} photo} other{{count} photos}}'**
  String swipeDeletePhotos(int count);

  /// No description provided for @swipeConfirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Photos selected for deletion: {count}. Remove any photos you want to keep from the deletion list.'**
  String swipeConfirmDeleteDescription(int count);

  /// No description provided for @swipePartialDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}} deleted. Remaining photos have not been deleted.'**
  String swipePartialDeleted(int count);

  /// No description provided for @swipeExitDescription.
  ///
  /// In en, this message translates to:
  /// **'You marked {count, plural, one{{count} photo} other{{count} photos}} for deletion. Leaving will not delete them.'**
  String swipeExitDescription(int count);

  /// No description provided for @swipeSkipRemainingDescription.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed photos: {remaining}. Finish reviewing and confirm the photos already marked for deletion ({deleteCount})?'**
  String swipeSkipRemainingDescription(int remaining, int deleteCount);

  /// No description provided for @assetDimensions.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height}'**
  String assetDimensions(int width, int height);

  /// No description provided for @assetPreviewDetails.
  ///
  /// In en, this message translates to:
  /// **'{width} × {height} · {size}'**
  String assetPreviewDetails(int width, int height, String size);

  /// No description provided for @assetReloadPreview.
  ///
  /// In en, this message translates to:
  /// **'Reload preview'**
  String get assetReloadPreview;

  /// No description provided for @assetSizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Size unavailable'**
  String get assetSizeUnknown;

  /// No description provided for @assetSizeGigabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String assetSizeGigabytes(String value);

  /// No description provided for @assetSizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String assetSizeMegabytes(String value);

  /// No description provided for @assetSizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String assetSizeKilobytes(String value);

  /// No description provided for @assetSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} byte} other{{count} bytes}}'**
  String assetSizeBytes(int count);

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Master'**
  String get appName;

  /// No description provided for @nativePhotoRead.
  ///
  /// In en, this message translates to:
  /// **'Access the photos and videos you allow so you can preview, organize, and confirm what to delete.'**
  String get nativePhotoRead;

  /// No description provided for @nativePhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Save a compressed video copy to Photos when you confirm. The original is kept.'**
  String get nativePhotoAdd;

  /// No description provided for @nativeContacts.
  ///
  /// In en, this message translates to:
  /// **'Access your contacts to help organize duplicate contact details.'**
  String get nativeContacts;

  /// No description provided for @nativeTracking.
  ///
  /// In en, this message translates to:
  /// **'Allow tracking to personalize your experience and improve the service.'**
  String get nativeTracking;

  /// No description provided for @serviceSubscriptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are currently unavailable. Please try again later.'**
  String get serviceSubscriptionsUnavailable;

  /// No description provided for @serviceSubscriptionInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the subscription service. Please try again later.'**
  String get serviceSubscriptionInitFailed;

  /// No description provided for @serviceNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No subscription plans are available right now. Please try again later.'**
  String get serviceNoPlans;

  /// No description provided for @servicePlansLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans. Check your connection and try again.'**
  String get servicePlansLoadFailed;

  /// No description provided for @servicePurchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are currently unavailable. Please try again later.'**
  String get servicePurchaseUnavailable;

  /// No description provided for @servicePurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase not completed. Please try again later.'**
  String get servicePurchaseFailed;

  /// No description provided for @serviceRestoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases is currently unavailable. Please try again later.'**
  String get serviceRestoreUnavailable;

  /// No description provided for @serviceNoSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active Pro subscription was found.'**
  String get serviceNoSubscription;

  /// No description provided for @serviceRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore purchases. Check your connection and try again.'**
  String get serviceRestoreFailed;

  /// No description provided for @servicePurchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get servicePurchaseCancelled;

  /// No description provided for @serviceScanPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused. Read and analyzed results are kept. You can continue scanning.'**
  String get serviceScanPaused;

  /// No description provided for @serviceLimitedLibrary.
  ///
  /// In en, this message translates to:
  /// **'Only the photos you allowed are included, not your entire library.'**
  String get serviceLimitedLibrary;

  /// No description provided for @serviceNativeAnalysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original-file analysis is unavailable on this device. Sizes and exact duplicates are unverified.'**
  String get serviceNativeAnalysisUnavailable;

  /// No description provided for @serviceOriginalVerificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Verify local originals to confirm file sizes and exact duplicates. Large or cloud items may remain pending; unverified sizes are not estimated.'**
  String get serviceOriginalVerificationNeeded;

  /// No description provided for @serviceReadingIndex.
  ///
  /// In en, this message translates to:
  /// **'Reading library index'**
  String get serviceReadingIndex;

  /// No description provided for @servicePhotoPermission.
  ///
  /// In en, this message translates to:
  /// **'Photo access is not allowed. Allow access in Settings and try again.'**
  String get servicePhotoPermission;

  /// No description provided for @serviceOriginalRoundLimit.
  ///
  /// In en, this message translates to:
  /// **'This verification round reached 60 seconds. Results are kept; verify again to process untried items first.'**
  String get serviceOriginalRoundLimit;

  /// No description provided for @servicePreviewRoundLimit.
  ///
  /// In en, this message translates to:
  /// **'This preview round reached 30 seconds. Results are kept; continue to process untried photos first.'**
  String get servicePreviewRoundLimit;

  /// No description provided for @serviceReadTimeout.
  ///
  /// In en, this message translates to:
  /// **'Some reads timed out. Current results are kept; you can continue scanning.'**
  String get serviceReadTimeout;

  /// No description provided for @serviceReadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Some library reads were interrupted. Current results are kept; you can continue scanning.'**
  String get serviceReadInterrupted;

  /// No description provided for @serviceVerifyingOriginals.
  ///
  /// In en, this message translates to:
  /// **'Verifying local originals'**
  String get serviceVerifyingOriginals;

  /// No description provided for @serviceGroupingSimilar.
  ///
  /// In en, this message translates to:
  /// **'Grouping visually similar candidates'**
  String get serviceGroupingSimilar;

  /// No description provided for @serviceQualityLowDetail.
  ///
  /// In en, this message translates to:
  /// **'Preview has too little detail for a quality recommendation'**
  String get serviceQualityLowDetail;

  /// No description provided for @serviceQualityDecodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview could not be decoded; quality was not evaluated'**
  String get serviceQualityDecodeFailed;

  /// No description provided for @serviceQualityLowInformation.
  ///
  /// In en, this message translates to:
  /// **'Insufficient image information for a quality recommendation'**
  String get serviceQualityLowInformation;

  /// No description provided for @serviceQualityClearEdges.
  ///
  /// In en, this message translates to:
  /// **'Clearer preview edges'**
  String get serviceQualityClearEdges;

  /// No description provided for @serviceQualityLessDetail.
  ///
  /// In en, this message translates to:
  /// **'Less preview edge detail'**
  String get serviceQualityLessDetail;

  /// No description provided for @serviceQualityDark.
  ///
  /// In en, this message translates to:
  /// **'Image appears dark'**
  String get serviceQualityDark;

  /// No description provided for @serviceQualityBright.
  ///
  /// In en, this message translates to:
  /// **'Image appears bright'**
  String get serviceQualityBright;

  /// No description provided for @serviceQualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced overall brightness'**
  String get serviceQualityBalanced;

  /// No description provided for @serviceKeepExact.
  ///
  /// In en, this message translates to:
  /// **'Original and edited resources match exactly. Suggested copy to keep.'**
  String get serviceKeepExact;

  /// No description provided for @serviceKeepHigherResolution.
  ///
  /// In en, this message translates to:
  /// **'Higher resolution within this group. Suggested to keep; check the photo content.'**
  String get serviceKeepHigherResolution;

  /// No description provided for @serviceVideoMissing.
  ///
  /// In en, this message translates to:
  /// **'Video not found. Scan again.'**
  String get serviceVideoMissing;

  /// No description provided for @serviceVideoCloud.
  ///
  /// In en, this message translates to:
  /// **'The video is in iCloud. Download the original in Photos and try again.'**
  String get serviceVideoCloud;

  /// No description provided for @serviceVideoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this video.'**
  String get serviceVideoUnreadable;

  /// No description provided for @serviceVideoPreviousBusy.
  ///
  /// In en, this message translates to:
  /// **'The previous compression is still ending. Try again shortly.'**
  String get serviceVideoPreviousBusy;

  /// No description provided for @serviceVideoTemporaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare temporary video storage.'**
  String get serviceVideoTemporaryUnavailable;

  /// No description provided for @serviceVideoUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Video compression is unavailable on this device.'**
  String get serviceVideoUnsupported;

  /// No description provided for @serviceVideoOutputInvalid.
  ///
  /// In en, this message translates to:
  /// **'The output location is invalid. The original is kept.'**
  String get serviceVideoOutputInvalid;

  /// No description provided for @serviceVideoSaveUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm the saved copy. Check Photos before trying again.'**
  String get serviceVideoSaveUnknown;

  /// No description provided for @serviceVideoCancelled.
  ///
  /// In en, this message translates to:
  /// **'Compression cancelled.'**
  String get serviceVideoCancelled;

  /// No description provided for @serviceVideoOperationBusy.
  ///
  /// In en, this message translates to:
  /// **'Finish the current video operation first.'**
  String get serviceVideoOperationBusy;

  /// No description provided for @serviceVideoEmpty.
  ///
  /// In en, this message translates to:
  /// **'The original is empty and cannot be compressed.'**
  String get serviceVideoEmpty;

  /// No description provided for @serviceVideoEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Compression did not finish. The original is kept.'**
  String get serviceVideoEncodeFailed;

  /// No description provided for @serviceVideoNoCopy.
  ///
  /// In en, this message translates to:
  /// **'Compression did not create a separate copy. The original is kept.'**
  String get serviceVideoNoCopy;

  /// No description provided for @serviceVideoNotSmaller.
  ///
  /// In en, this message translates to:
  /// **'The compressed video is not smaller. The original is kept.'**
  String get serviceVideoNotSmaller;

  /// No description provided for @serviceVideoDurationMismatch.
  ///
  /// In en, this message translates to:
  /// **'The compressed video duration does not match. The original is kept.'**
  String get serviceVideoDurationMismatch;

  /// No description provided for @serviceVideoValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the video. The original is kept.'**
  String get serviceVideoValidationFailed;

  /// No description provided for @serviceVideoPreviewFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish compression and review the preview first.'**
  String get serviceVideoPreviewFirst;

  /// No description provided for @serviceVideoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the copy. The original is kept. Try again.'**
  String get serviceVideoSaveFailed;

  /// No description provided for @serviceVideoGenericFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation not completed. The original is kept. Check photo access and free space, then try again.'**
  String get serviceVideoGenericFailed;

  /// No description provided for @serviceOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this operation. Please try again.'**
  String get serviceOperationFailed;

  /// No description provided for @serviceIndexReadCount.
  ///
  /// In en, this message translates to:
  /// **'Read {read} / {total} accessible items.'**
  String serviceIndexReadCount(int read, int total);

  /// No description provided for @servicePhotosPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo still needs} other{{count} photos still need}} visual analysis. Continue to process untried photos first. Cloud originals are not downloaded automatically.'**
  String servicePhotosPending(int count);

  /// No description provided for @serviceReadingPreviews.
  ///
  /// In en, this message translates to:
  /// **'Reading local previews ({count})'**
  String serviceReadingPreviews(int count);

  /// No description provided for @serviceAnalyzingPreviews.
  ///
  /// In en, this message translates to:
  /// **'Analyzing local previews ({count})'**
  String serviceAnalyzingPreviews(int count);

  /// No description provided for @serviceQualitySummary.
  ///
  /// In en, this message translates to:
  /// **'{reasons}; suggested guidance only'**
  String serviceQualitySummary(String reasons);

  /// No description provided for @scanSwipeIntro.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to mark for deletion, right to keep. Delete only after confirming.'**
  String get scanSwipeIntro;

  /// No description provided for @scanSwipeStart.
  ///
  /// In en, this message translates to:
  /// **'Start swipe cleanup'**
  String get scanSwipeStart;

  /// No description provided for @scanDetails.
  ///
  /// In en, this message translates to:
  /// **'Scan details'**
  String get scanDetails;

  /// No description provided for @scanVerificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Original files not checked yet'**
  String get scanVerificationNeeded;

  /// Number of original resources checked out of the total indexed items.
  ///
  /// In en, this message translates to:
  /// **'Checked {verified} / {total} items'**
  String scanVerificationProgress(int verified, int total);

  /// No description provided for @scanVerificationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Check file contents and sizes first to find exact duplicates and large files. Cloud items can wait.'**
  String get scanVerificationExplanation;

  /// No description provided for @scanOriginalsAfterPreview.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicates and large files are checked after the photo preview scan. Pause now to review found items.'**
  String get scanOriginalsAfterPreview;

  /// No description provided for @scanVerifyNow.
  ///
  /// In en, this message translates to:
  /// **'Check duplicates and large files'**
  String get scanVerifyNow;

  /// No description provided for @scanBrowsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Organize photos first'**
  String get scanBrowsePhotos;

  /// No description provided for @scanSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all in this category'**
  String get scanSelectAll;

  /// No description provided for @scanClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get scanClearSelection;

  /// No description provided for @scanKeepOneSelectOthers.
  ///
  /// In en, this message translates to:
  /// **'Keep this, select other photos with loaded previews'**
  String get scanKeepOneSelectOthers;

  /// No description provided for @scanGroupReadyOthers.
  ///
  /// In en, this message translates to:
  /// **'Other photos ready to select: {ready} of {total}'**
  String scanGroupReadyOthers(int ready, int total);

  /// No description provided for @scanSelectOthersHint.
  ///
  /// In en, this message translates to:
  /// **'Preview the suggested photo to keep, then select the rest of this group in one go.'**
  String get scanSelectOthersHint;

  /// No description provided for @scanNotChecked.
  ///
  /// In en, this message translates to:
  /// **'To check'**
  String get scanNotChecked;

  /// Number of original resources waiting to be checked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item to check} other{{count} items to check}}'**
  String scanPendingCheckCount(int count);

  /// No description provided for @swipeMultiSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select multiple items'**
  String get swipeMultiSelectTitle;

  /// No description provided for @swipeDragSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag across thumbnails to select loaded previews.'**
  String get swipeDragSelectHint;

  /// No description provided for @swipeMarkSelectedForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Mark {count} for deletion'**
  String swipeMarkSelectedForDeletion(int count);

  /// No description provided for @swipeGestureTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick swipe cleanup'**
  String get swipeGestureTitle;

  /// No description provided for @swipeGestureDelete.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to mark for deletion'**
  String get swipeGestureDelete;

  /// No description provided for @swipeGestureKeep.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to keep'**
  String get swipeGestureKeep;

  /// No description provided for @swipeGestureSafety.
  ///
  /// In en, this message translates to:
  /// **'Photos go to a deletion list first. They are deleted only after you tap Done and confirm.'**
  String get swipeGestureSafety;

  /// No description provided for @swipeGestureHelp.
  ///
  /// In en, this message translates to:
  /// **'How to swipe'**
  String get swipeGestureHelp;

  /// No description provided for @homeSwipeDescription.
  ///
  /// In en, this message translates to:
  /// **'Swipe through photos one by one for faster cleanup than tapping thumbnails.'**
  String get homeSwipeDescription;

  /// Action to verify complete original hashes of photos only.
  ///
  /// In en, this message translates to:
  /// **'Check exact duplicates'**
  String get scanCheckExactPhotos;

  /// Action to check exact resource sizes without computing photo hashes.
  ///
  /// In en, this message translates to:
  /// **'Check large-file sizes'**
  String get scanCheckFileSizes;

  /// No description provided for @reviewDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Review deletion'**
  String get reviewDeleteTitle;

  /// No description provided for @reviewRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from deletion'**
  String get reviewRemove;

  /// No description provided for @reviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable. Retry or remove this item.'**
  String get reviewUnavailable;

  /// No description provided for @reviewUnseenCount.
  ///
  /// In en, this message translates to:
  /// **'Items needing preview before deletion: {count}'**
  String reviewUnseenCount(int count);

  /// No description provided for @reviewAllVersions.
  ///
  /// In en, this message translates to:
  /// **'All versions in a group are selected. Delete every version?'**
  String get reviewAllVersions;

  /// No description provided for @reviewDeleteAllVersions.
  ///
  /// In en, this message translates to:
  /// **'Delete every version'**
  String get reviewDeleteAllVersions;

  /// No description provided for @reviewConfirmCount.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion · {count}'**
  String reviewConfirmCount(int count);

  /// No description provided for @swipeResumeReview.
  ///
  /// In en, this message translates to:
  /// **'Continue previous review · {count} reviewed'**
  String swipeResumeReview(int count);

  /// No description provided for @swipeResetReview.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get swipeResetReview;

  /// No description provided for @swipeBatchSize.
  ///
  /// In en, this message translates to:
  /// **'Items per batch: {count}'**
  String swipeBatchSize(int count);

  /// No description provided for @swipeAllMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get swipeAllMonths;

  /// No description provided for @swipeReviewBatch.
  ///
  /// In en, this message translates to:
  /// **'Choose a month or batch'**
  String get swipeReviewBatch;

  /// No description provided for @assetVideoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading original video…'**
  String get assetVideoLoading;

  /// No description provided for @assetVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original video unavailable. Download it in Photos, then retry.'**
  String get assetVideoUnavailable;

  /// No description provided for @homePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo access needed'**
  String get homePermissionTitle;

  /// No description provided for @homePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access in Settings to scan and review. Nothing is deleted automatically.'**
  String get homePermissionDescription;

  /// No description provided for @homeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get homeOpenSettings;

  /// No description provided for @homeManagePhotoAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage photo access'**
  String get homeManagePhotoAccess;

  /// No description provided for @homeReviewReady.
  ///
  /// In en, this message translates to:
  /// **'Review available photos'**
  String get homeReviewReady;

  /// No description provided for @homeContinueAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Continue photo analysis'**
  String get homeContinueAnalysis;

  /// No description provided for @homeScanDetails.
  ///
  /// In en, this message translates to:
  /// **'Scan details'**
  String get homeScanDetails;

  /// No description provided for @scanCheckingExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking exact duplicate photos'**
  String get scanCheckingExactTitle;

  /// No description provided for @scanCheckingSizesTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking file sizes'**
  String get scanCheckingSizesTitle;

  /// No description provided for @scanRoundProgress.
  ///
  /// In en, this message translates to:
  /// **'Processed {completed} / {total}'**
  String scanRoundProgress(int total, int completed);

  /// No description provided for @scanPauseReview.
  ///
  /// In en, this message translates to:
  /// **'Pause checking and review'**
  String get scanPauseReview;

  /// No description provided for @scanSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Check items to mark for deletion. Tap Preview to view their content.'**
  String get scanSelectionHint;

  /// No description provided for @scanPreviewNotReady.
  ///
  /// In en, this message translates to:
  /// **'Load the preview before selecting'**
  String get scanPreviewNotReady;

  /// No description provided for @scanUnreadableExcluded.
  ///
  /// In en, this message translates to:
  /// **'Previews not loaded and excluded from selection: {count}'**
  String scanUnreadableExcluded(int count);

  /// No description provided for @scanKeepThis.
  ///
  /// In en, this message translates to:
  /// **'Keep this photo'**
  String get scanKeepThis;

  /// No description provided for @scanPreviewMore.
  ///
  /// In en, this message translates to:
  /// **'Load more photos'**
  String get scanPreviewMore;

  /// No description provided for @homeKnownLibrarySize.
  ///
  /// In en, this message translates to:
  /// **'Confirmed file sizes: {size} · Checked: {count}'**
  String homeKnownLibrarySize(int count, String size);

  /// No description provided for @homePendingSizes.
  ///
  /// In en, this message translates to:
  /// **'Items with size still unknown: {count}'**
  String homePendingSizes(int count);

  /// No description provided for @scanReviewChanged.
  ///
  /// In en, this message translates to:
  /// **'Photos or permissions have changed. Review your deletion list again.'**
  String get scanReviewChanged;

  /// No description provided for @paywallFreePreviewNote.
  ///
  /// In en, this message translates to:
  /// **'Photo grouping, previews and swipe marking are free. Pro unlocks confirmed deletion and video compression.'**
  String get paywallFreePreviewNote;

  /// No description provided for @paywallSubscribeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe weekly · {price}'**
  String paywallSubscribeWeekly(String price);

  /// No description provided for @paywallSubscribeYearly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe yearly · {price}'**
  String paywallSubscribeYearly(String price);

  /// No description provided for @paywallSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get paywallSubscribe;

  /// No description provided for @paywallWeeklyRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically at {price} each week unless canceled. Review the final terms in the App Store.'**
  String paywallWeeklyRenewal(String price);

  /// No description provided for @paywallYearlyRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically at {price} each year unless canceled. Review the final terms in the App Store.'**
  String paywallYearlyRenewal(String price);

  /// No description provided for @paywallRenewalGeneric.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically unless canceled. Review the billing period and amount in the App Store before confirming.'**
  String get paywallRenewalGeneric;

  /// No description provided for @paywallLoadingPlans.
  ///
  /// In en, this message translates to:
  /// **'Loading subscription plans…'**
  String get paywallLoadingPlans;

  /// No description provided for @paywallWaitingForStore.
  ///
  /// In en, this message translates to:
  /// **'Waiting for App Store confirmation…'**
  String get paywallWaitingForStore;

  /// No description provided for @paywallRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases…'**
  String get paywallRestoring;

  /// No description provided for @settingsCheckingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Checking subscription…'**
  String get settingsCheckingSubscription;

  /// No description provided for @settingsSubscriptionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Subscription status unavailable'**
  String get settingsSubscriptionUnknown;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get settingsManageSubscription;

  /// No description provided for @settingsManageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open subscription management. Open subscriptions in your store account settings.'**
  String get settingsManageUnavailable;

  /// No description provided for @onboardingStartFree.
  ///
  /// In en, this message translates to:
  /// **'Start for free'**
  String get onboardingStartFree;

  /// No description provided for @swipeCheckpointSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save review progress. You can keep reviewing, but it may not resume next time.'**
  String get swipeCheckpointSaveError;

  /// No description provided for @swipeCheckpointLimit.
  ///
  /// In en, this message translates to:
  /// **'Recent review choices kept on this device: up to {count}'**
  String swipeCheckpointLimit(int count);

  /// No description provided for @scanSelectLoaded.
  ///
  /// In en, this message translates to:
  /// **'Select loaded previews'**
  String get scanSelectLoaded;

  /// No description provided for @homePhotoScopeChanged.
  ///
  /// In en, this message translates to:
  /// **'Photo access may have changed. Scan again to refresh available photos.'**
  String get homePhotoScopeChanged;

  /// No description provided for @navOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get navOptimize;

  /// No description provided for @navExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get navExtras;

  /// No description provided for @v2Before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get v2Before;

  /// No description provided for @v2After.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get v2After;

  /// No description provided for @v2Best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get v2Best;

  /// No description provided for @v2Cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get v2Cancel;

  /// No description provided for @v2Select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get v2Select;

  /// No description provided for @v2SelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get v2SelectAll;

  /// No description provided for @v2DeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get v2DeselectAll;

  /// No description provided for @v2SelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String v2SelectedCount(int count);

  /// No description provided for @v2CatSimilars.
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get v2CatSimilars;

  /// No description provided for @v2CatDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get v2CatDuplicates;

  /// No description provided for @v2CatVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get v2CatVideos;

  /// No description provided for @v2CatScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get v2CatScreenshots;

  /// No description provided for @v2CatBlurred.
  ///
  /// In en, this message translates to:
  /// **'Blurred'**
  String get v2CatBlurred;

  /// No description provided for @v2CatLarge.
  ///
  /// In en, this message translates to:
  /// **'Large Files'**
  String get v2CatLarge;

  /// No description provided for @v2CatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get v2CatOther;

  /// No description provided for @v2PhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Photo} other{{count} Photos}}'**
  String v2PhotoCount(int count);

  /// No description provided for @v2VideoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 Video} other{{count} Videos}}'**
  String v2VideoCount(int count);

  /// No description provided for @v2ItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item} other{{count} items}}'**
  String v2ItemCount(int count);

  /// No description provided for @v2DeleteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete 1 Item} other{Delete {count} Items}}'**
  String v2DeleteCount(int count);

  /// No description provided for @v2DeleteVideos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete 1 Video} other{Delete {count} Videos}}'**
  String v2DeleteVideos(int count);

  /// No description provided for @v2DeleteSize.
  ///
  /// In en, this message translates to:
  /// **'Delete {size}'**
  String v2DeleteSize(String size);

  /// No description provided for @v2FreeCleanupsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 free cleanup left} other{{count} free cleanups left}}'**
  String v2FreeCleanupsLeft(int count);

  /// No description provided for @v2SpaceToClean.
  ///
  /// In en, this message translates to:
  /// **'Space to Clean'**
  String get v2SpaceToClean;

  /// No description provided for @v2StorageUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String v2StorageUsedOf(String used, String total);

  /// No description provided for @v2OptimizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize Storage'**
  String get v2OptimizeTitle;

  /// No description provided for @v2OptimizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up space from your files quickly'**
  String get v2OptimizeSubtitle;

  /// No description provided for @v2Scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning your library…'**
  String get v2Scanning;

  /// No description provided for @v2ScanningCount.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String v2ScanningCount(int done, int total);

  /// No description provided for @v2CheckingDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Checking duplicates…'**
  String get v2CheckingDuplicates;

  /// No description provided for @v2ScanStart.
  ///
  /// In en, this message translates to:
  /// **'Scan my photos'**
  String get v2ScanStart;

  /// No description provided for @v2PermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow access to Photos'**
  String get v2PermissionTitle;

  /// No description provided for @v2PermissionBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} needs access to your photos to find duplicates and free up storage. Your photos stay on your device.'**
  String v2PermissionBody(String appName);

  /// No description provided for @v2OpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get v2OpenSettings;

  /// No description provided for @v2IntroLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get v2IntroLeft;

  /// No description provided for @v2IntroToDelete.
  ///
  /// In en, this message translates to:
  /// **'to Delete'**
  String get v2IntroToDelete;

  /// No description provided for @v2IntroRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get v2IntroRight;

  /// No description provided for @v2IntroToKeep.
  ///
  /// In en, this message translates to:
  /// **'to Keep'**
  String get v2IntroToKeep;

  /// No description provided for @v2LetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get v2LetsGo;

  /// No description provided for @v2IntroSimilars.
  ///
  /// In en, this message translates to:
  /// **'Similar shots are grouped together. We keep the best one and select the rest for you.'**
  String get v2IntroSimilars;

  /// No description provided for @v2IntroDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Exact copies of the same photo. Keep one and delete the rest in one tap.'**
  String get v2IntroDuplicates;

  /// No description provided for @v2IntroVideos.
  ///
  /// In en, this message translates to:
  /// **'Review all your videos. Sort them by size or date to see the ones that take the most space.'**
  String get v2IntroVideos;

  /// No description provided for @v2IntroScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Old screenshots pile up fast. Swipe through them and clear the ones you no longer need.'**
  String get v2IntroScreenshots;

  /// No description provided for @v2IntroBlurred.
  ///
  /// In en, this message translates to:
  /// **'Blurry and out-of-focus shots you probably don\'t want to keep.'**
  String get v2IntroBlurred;

  /// No description provided for @v2IntroLarge.
  ///
  /// In en, this message translates to:
  /// **'Your biggest photos and videos. Deleting a few of them frees the most space.'**
  String get v2IntroLarge;

  /// No description provided for @v2IntroOther.
  ///
  /// In en, this message translates to:
  /// **'Photos that don\'t belong to any category. Sort them by size or date and say goodbye to the ones you don\'t need.'**
  String get v2IntroOther;

  /// No description provided for @v2IntroOptimize.
  ///
  /// In en, this message translates to:
  /// **'Finds duplicate and similar photos, keeps the best ones and selects the rest. Free up space in seconds.'**
  String get v2IntroOptimize;

  /// No description provided for @v2SortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get v2SortLargest;

  /// No description provided for @v2SortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get v2SortNewest;

  /// No description provided for @v2EmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean here'**
  String get v2EmptyCategory;

  /// No description provided for @v2EmptyCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'This category is already clean.'**
  String get v2EmptyCategoryBody;

  /// No description provided for @v2VideoCompress.
  ///
  /// In en, this message translates to:
  /// **'Video Compress'**
  String get v2VideoCompress;

  /// No description provided for @v2VideoCompressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to start the process'**
  String get v2VideoCompressSubtitle;

  /// No description provided for @v2VideoCompressBody.
  ///
  /// In en, this message translates to:
  /// **'Compress videos into smaller copies to save storage.'**
  String get v2VideoCompressBody;

  /// No description provided for @v2CongratsTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get v2CongratsTitle;

  /// No description provided for @v2CongratsDeleted.
  ///
  /// In en, this message translates to:
  /// **'You have deleted'**
  String get v2CongratsDeleted;

  /// No description provided for @v2CongratsSaved.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{Saved about 1 minute} other{Saved about {minutes} minutes}}'**
  String v2CongratsSaved(int minutes);

  /// No description provided for @v2CongratsUsing.
  ///
  /// In en, this message translates to:
  /// **'using {appName}'**
  String v2CongratsUsing(String appName);

  /// No description provided for @v2CongratsRecentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Estimated original file size: {size}. Check iPhone Storage for the space actually freed; Recently Deleted may still use storage.'**
  String v2CongratsRecentlyDeleted(String size);

  /// No description provided for @v2Great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get v2Great;

  /// No description provided for @v2UnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Unlimited Access'**
  String get v2UnlockTitle;

  /// No description provided for @v2UnlockFeature1.
  ///
  /// In en, this message translates to:
  /// **'Instantly find similar photos'**
  String get v2UnlockFeature1;

  /// No description provided for @v2UnlockFeature2.
  ///
  /// In en, this message translates to:
  /// **'No limits on cleanup'**
  String get v2UnlockFeature2;

  /// No description provided for @v2UnlockFeature3.
  ///
  /// In en, this message translates to:
  /// **'Save both storage and time'**
  String get v2UnlockFeature3;

  /// No description provided for @v2PrivacyLine.
  ///
  /// In en, this message translates to:
  /// **'Your photos are analyzed on your device and never uploaded.'**
  String get v2PrivacyLine;

  /// No description provided for @v2PerWeek.
  ///
  /// In en, this message translates to:
  /// **'{price}/week, cancel anytime'**
  String v2PerWeek(String price);

  /// No description provided for @v2PerYear.
  ///
  /// In en, this message translates to:
  /// **'{price}/year'**
  String v2PerYear(String price);

  /// No description provided for @v2SavePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String v2SavePercent(int percent);

  /// No description provided for @v2FreeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1-day free trial} other{{days}-day free trial}}'**
  String v2FreeTrialDays(int days);

  /// No description provided for @v2StartFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Start my 1-day free trial} other{Start my {days}-day free trial}}'**
  String v2StartFreeTrial(int days);

  /// No description provided for @v2FreeThen.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Free for 1 day, then {price}} other{Free for {days} days, then {price}}}'**
  String v2FreeThen(int days, String price);

  /// No description provided for @v2TrialEnabled.
  ///
  /// In en, this message translates to:
  /// **'Free trial enabled'**
  String get v2TrialEnabled;

  /// No description provided for @v2DueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get v2DueToday;

  /// No description provided for @v2DueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String v2DueOn(String date);

  /// No description provided for @v2DaysFree.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day free} other{{days} days free}}'**
  String v2DaysFree(int days);

  /// No description provided for @v2TryFree.
  ///
  /// In en, this message translates to:
  /// **'Try Free'**
  String get v2TryFree;

  /// No description provided for @v2CleanYourStorage.
  ///
  /// In en, this message translates to:
  /// **'Clean your Storage'**
  String get v2CleanYourStorage;

  /// No description provided for @v2GetRidOf.
  ///
  /// In en, this message translates to:
  /// **'Get rid of what you don\'t need'**
  String get v2GetRidOf;

  /// No description provided for @v2ProFeatures.
  ///
  /// In en, this message translates to:
  /// **'Smart cleanup, video compression, secret space and no limits.'**
  String get v2ProFeatures;

  /// No description provided for @v2WelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String v2WelcomeTitle(String appName);

  /// No description provided for @v2WelcomeAccess.
  ///
  /// In en, this message translates to:
  /// **'{appName} needs access to your Photos to free up storage.'**
  String v2WelcomeAccess(String appName);

  /// No description provided for @v2WelcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your photos are analyzed on your device and never uploaded to our servers.'**
  String get v2WelcomePrivacy;

  /// No description provided for @v2GetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get v2GetStarted;

  /// No description provided for @v2Next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get v2Next;

  /// No description provided for @v2OnbDupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Duplicate Photos'**
  String get v2OnbDupTitle;

  /// No description provided for @v2OnbDupBody.
  ///
  /// In en, this message translates to:
  /// **'Find duplicate photos in seconds and reclaim your storage.'**
  String get v2OnbDupBody;

  /// No description provided for @v2OnbSwipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Clean'**
  String get v2OnbSwipeTitle;

  /// No description provided for @v2OnbSwipeBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to delete, right to keep. Cleaning up has never been this quick.'**
  String get v2OnbSwipeBody;

  /// No description provided for @v2OnbVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress Videos'**
  String get v2OnbVideoTitle;

  /// No description provided for @v2OnbVideoBody.
  ///
  /// In en, this message translates to:
  /// **'Shrink large videos and keep your memories.'**
  String get v2OnbVideoBody;

  /// No description provided for @v2TryDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Try 1 day} other{Try {days} days}}'**
  String v2TryDays(int days);

  /// No description provided for @v2ForFree.
  ///
  /// In en, this message translates to:
  /// **'For free!'**
  String get v2ForFree;

  /// No description provided for @v2ExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra Tools'**
  String get v2ExtrasTitle;

  /// No description provided for @v2ExtrasUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get v2ExtrasUtilities;

  /// No description provided for @v2ExtrasPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get v2ExtrasPrivate;

  /// No description provided for @v2ChargingTitle.
  ///
  /// In en, this message translates to:
  /// **'Charging Animation'**
  String get v2ChargingTitle;

  /// No description provided for @v2ChargingBody.
  ///
  /// In en, this message translates to:
  /// **'Personalize your charging screen'**
  String get v2ChargingBody;

  /// No description provided for @v2SecretTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Library'**
  String get v2SecretTitle;

  /// No description provided for @v2SecretBody.
  ///
  /// In en, this message translates to:
  /// **'Protect your private photos'**
  String get v2SecretBody;

  /// No description provided for @v2ScanPaused.
  ///
  /// In en, this message translates to:
  /// **'Scan paused'**
  String get v2ScanPaused;

  /// No description provided for @v2ContinueScan.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get v2ContinueScan;

  /// No description provided for @v2PauseScan.
  ///
  /// In en, this message translates to:
  /// **'Pause scan'**
  String get v2PauseScan;

  /// No description provided for @v2ContinueFreeCleanup.
  ///
  /// In en, this message translates to:
  /// **'Continue free cleanup ({count} remaining)'**
  String v2ContinueFreeCleanup(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'he',
    'id',
    'it',
    'ja',
    'ko',
    'pl',
    'pt',
    'ro',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
