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
  /// **'Group duplicate and similar photos, then review each item'**
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
  /// **'Check device storage in iPhone Settings. Here, you can organize accessible photos and videos.'**
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
  /// **'Read {count} of {total} accessible items'**
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
  /// **'Scan all accessible photos and videos. Original content verification and visual analysis help you review them before deciding.'**
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
  /// **'Exact duplicates: {count} photos'**
  String scanExactGroupCount(int count);

  /// No description provided for @scanSimilarGroupCount.
  ///
  /// In en, this message translates to:
  /// **'Visual candidates: {count} photos'**
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
  /// **'Preview and delete {count} items'**
  String scanPreviewDeleteCount(int count);

  /// No description provided for @scanConfirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected. Review your selection and keep recommendations before deleting. Recovered storage is determined by the system.'**
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
  /// **'Verifying originals for exact duplicates'**
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
  /// **'{deleteCount} photos to delete · {keepCount} photos to keep'**
  String swipeReviewSummary(int deleteCount, int keepCount);

  /// No description provided for @swipeDeletePhotos.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} photos'**
  String swipeDeletePhotos(int count);

  /// No description provided for @swipeConfirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} reviewed photos. Make sure the items you wish to keep have been selected correctly.'**
  String swipeConfirmDeleteDescription(int count);

  /// No description provided for @swipePartialDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} photos deleted. Remaining photos have not been deleted.'**
  String swipePartialDeleted(int count);

  /// No description provided for @swipeExitDescription.
  ///
  /// In en, this message translates to:
  /// **'You marked {count} photos for deletion. Leaving will not delete them.'**
  String swipeExitDescription(int count);

  /// No description provided for @swipeSkipRemainingDescription.
  ///
  /// In en, this message translates to:
  /// **'{remaining} photos are not reviewed. Finish reviewing and confirm the {deleteCount} photos already marked for deletion?'**
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
  /// **'{count} bytes'**
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
  /// **'{count} photos still need visual analysis. Continue to process untried photos first. Cloud originals are not downloaded automatically.'**
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
