// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Smart cleanup';

  @override
  String get onboardingSmartSubtitle =>
      'Scan photos and videos you allow access to\nPreview first, then choose what to keep or delete';

  @override
  String get onboardingPhotosTitle => 'Organize photos';

  @override
  String get onboardingPhotosSubtitle =>
      'Compare duplicate and similar photos by content\nReview every suggested photo to keep';

  @override
  String get onboardingSwipeTitle => 'Swipe to organize';

  @override
  String get onboardingSwipeSubtitle =>
      'Swipe to choose what to keep or delete\nConfirm all your choices when you finish';

  @override
  String get onboardingChoiceTitle => 'You decide';

  @override
  String get onboardingChoiceSubtitle =>
      'Scanning and photo previews are free\nDeleting and video compression require Pro. Originals are never deleted automatically.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPreparing => 'Getting ready…';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Close';

  @override
  String get paywallDescription =>
      'Unlock photo and video cleanup. Preview items before choosing what to delete.';

  @override
  String get paywallReloadPlans => 'Reload plans';

  @override
  String get paywallNotConfigured => 'Subscriptions unavailable';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallStoreNotice =>
      'Purchases are completed through the App Store. Manage or cancel subscriptions in your Apple ID settings.';

  @override
  String get paywallRestorePurchases => 'Restore purchases';

  @override
  String get paywallPrivacyPolicy => 'Privacy policy';

  @override
  String get paywallTerms => 'Terms of use';

  @override
  String get paywallPurchaseIncomplete =>
      'Purchase not completed. Please try again later.';

  @override
  String get paywallRestored => 'Pro access restored.';

  @override
  String get paywallRestoreNotFound => 'No purchases found to restore.';

  @override
  String get paywallWeeklyPlan => 'Weekly subscription';

  @override
  String get paywallYearlyPlan => 'Yearly subscription';

  @override
  String get paywallYearlySubtitle =>
      'Organize photos and videos throughout the year';

  @override
  String get paywallWeeklySubtitle => 'For a short photo cleanup session';

  @override
  String get paywallPhotoFeature =>
      'Delete the photos and videos you select after confirmation';

  @override
  String get paywallVideoFeature =>
      'Compress videos, preview them, and save copies';

  @override
  String get paywallSwipeFeature => 'Organize quickly with swipe gestures';

  @override
  String get paywallPlansUnavailable =>
      'Subscription plans could not be loaded. Check your connection and reload.';

  @override
  String get paywallBestValue => 'Best value';

  @override
  String get videoTryAnotherPreset => 'Try another quality';

  @override
  String get videoPresetTitle => 'Compression quality';

  @override
  String get videoPresetSmaller => 'Smaller file';

  @override
  String get videoPresetBalanced => 'Balanced';

  @override
  String get videoPresetHigherQuality => 'Higher quality';

  @override
  String get videoPresetNotice =>
      'The preset guides encoding. Actual file size is shown after the preview is created. The original is kept.';

  @override
  String get serviceContinuousScanLimit =>
      'This continuous scan reached its time limit. Progress was saved; you can resume later.';

  @override
  String get swipeCheckpointRecovered =>
      'Some saved review choices were damaged and could not be restored. Please review these photos again; nothing was deleted.';

  @override
  String get videoTitle => 'Video compression';

  @override
  String get videoDescription =>
      'Compression reduces quality and creates a new copy. Check the picture, sound, and orientation before saving to Photos. The original is kept.';

  @override
  String get videoProRequired =>
      'This feature requires Pro. Return to the cleanup page to view plans.';

  @override
  String get videoSaving => 'Saving to Photos. Please wait until it finishes.';

  @override
  String get videoCancelCompression => 'Cancel compression';

  @override
  String get videoLoadingPreview => 'Loading video preview…';

  @override
  String get videoCreatePreview => 'Create a compressed preview';

  @override
  String get videoStorageNotice =>
      'Saving a copy temporarily uses more storage. After deleting the original and emptying Recently Deleted, check the system for actual available space.';

  @override
  String get videoViewOriginal => 'View original';

  @override
  String get videoViewCopy => 'View compressed copy';

  @override
  String get videoSaved =>
      'The copy was saved to Photos and the original was kept. Scan again from Home, then choose whether to delete the original.';

  @override
  String get videoConfirmSave => 'Confirm the copy and save to Photos';

  @override
  String get videoPreviewUnavailable =>
      'The preview could not be played. Try again. The original is kept.';

  @override
  String get videoPlaybackUnavailable =>
      'The video cannot play right now. Reload the preview.';

  @override
  String get videoOperationIncomplete =>
      'The operation did not finish. The original is kept. Check Photos permission and available storage, then try again.';

  @override
  String get videoPauseOriginal => 'Original: Pause';

  @override
  String get videoPlayOriginal => 'Original: Play';

  @override
  String get videoPauseCopy => 'Compressed copy: Pause';

  @override
  String get videoPlayCopy => 'Compressed copy: Play';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Build $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Preparing / compressing video $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Original: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Copy: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'File size difference: $size';
  }

  @override
  String videoSizeGb(String size) {
    return '$size GB';
  }

  @override
  String videoSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get homeStorageUnavailable =>
      'Check device storage in Settings. Here, you can organize accessible photos and videos.';

  @override
  String get homeViewIndexedPhotos => 'View photos read so far';

  @override
  String get homeViewIndexedScreenshots => 'View screenshots read so far';

  @override
  String get homeCleanupTools => 'Cleaning tools';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Preview first, then organize photos and videos';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Used';

  @override
  String get homeUsedLegend => 'Used';

  @override
  String get homeAvailableLegend => 'Available';

  @override
  String get homeStartScanHint => 'Not scanned yet. Tap below to start.';

  @override
  String get homeScanning => 'Scanning…';

  @override
  String get homeDeleting => 'Deleting…';

  @override
  String get homeResumeScan => 'Continue scanning and keep progress';

  @override
  String get homeScanAll => 'Scan all accessible photos and videos';

  @override
  String get homePreviewOrganize => 'Preview and organize';

  @override
  String get homeVerifyOriginals =>
      'Verify local originals for exact duplicates and file sizes';

  @override
  String get homeRetryPending => 'Continue scanning / retry pending items';

  @override
  String get homeExactDuplicates => 'Exact duplicate photos';

  @override
  String get homeSimilarPhotos => 'Visually similar photos';

  @override
  String get homeNotScanned => 'Not scanned yet';

  @override
  String get homePendingAnalysis => 'Visual analysis pending';

  @override
  String get homeNoneAnalyzed => 'None found among analyzed items';

  @override
  String get homeScreenshots => 'Screenshots';

  @override
  String get homeLargeFiles => 'Large files';

  @override
  String get homeNoneFound => 'None found';

  @override
  String get homePendingVerification => 'Original verification pending';

  @override
  String get homeNoneVerified => 'None found among verified items';

  @override
  String get homeNeedsReview => 'Needs review';

  @override
  String get homeCanReview => 'Review';

  @override
  String get homeScanStatus => 'Scan';

  @override
  String get homeDoneStatus => 'Done ✓';

  @override
  String get homePreviewPhotos => 'Preview photos';

  @override
  String get homeChooseKeep => 'Choose what to keep';

  @override
  String get navHome => 'Home';

  @override
  String get navClean => 'Clean';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLoading => 'Loading…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Free plan';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsStorageTotal => 'Total';

  @override
  String get settingsStorageUsed => 'Used';

  @override
  String get settingsStorageAvailable => 'Available';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsProcessingSubscription => 'Processing subscription…';

  @override
  String get settingsRestorePurchases => 'Restore purchases';

  @override
  String get settingsRestoredPro => 'Pro subscription restored.';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsRateApp => 'Rate us';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsChooseLanguage => 'Choose language';

  @override
  String get settingsSystemLanguage => 'Follow system language';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return 'Total $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Read $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Accessible items read: $count / $total';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Visually analyzed: $analyzed. Originals verified: $verified. Retention suggestions are reversible; you decide what to delete.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos (partial results)',
      one: '1 photo (partial results)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos verified; more pending',
      one: '1 photo verified; more pending',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items verified; more pending',
      one: '1 item verified; more pending',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Could not save the language. Please try again.';

  @override
  String get scanSmartTitle => 'Smart cleanup';

  @override
  String get scanCancelKeepProgress => 'Cancel scan and keep progress';

  @override
  String get scanSwipeCleanup => 'Swipe cleanup';

  @override
  String get scanSortFileSize => 'File size';

  @override
  String get scanSortNewest => 'Newest';

  @override
  String get scanStartAlbumTitle => 'Start scanning your library';

  @override
  String get scanIncompleteTitle => 'Scan incomplete';

  @override
  String get scanStartAlbumDescription =>
      'Scan photo previews first to review similar pictures. Exact duplicates and large files are checked separately when you open those categories. Nothing is deleted automatically.';

  @override
  String get scanContinue => 'Continue scan';

  @override
  String get scanStart => 'Start scan';

  @override
  String get scanPreviewWhileRunning =>
      'You can preview photos and screenshots. Selection, deletion and video compression are paused during scanning.';

  @override
  String get scanExactDescription =>
      'Exact duplicates include only items with verified original resources. Keep recommendations can be dismissed.';

  @override
  String get scanSimilarDescription =>
      'Visual candidates appear as local previews are analyzed. Their content may differ; keep recommendations are only a guide.';

  @override
  String get scanLargeDescription =>
      'Sorted by verified resource size. File size and storage actually recovered may differ; the system determines recovered space.';

  @override
  String get scanManualDeleteDescription =>
      'Only items you manually select and confirm will be deleted.';

  @override
  String get scanVerifyOriginals =>
      'Verify local originals: exact duplicates and size';

  @override
  String get scanResumePending => 'Continue scan / retry pending items';

  @override
  String get scanKeepReasonDefault =>
      'This photo is a suggested item to keep in this group.';

  @override
  String get scanRestoreKeepSuggestion => 'Show keep recommendation again';

  @override
  String get scanDismissKeepSuggestion => 'Dismiss keep recommendation';

  @override
  String get scanKeepManualHint =>
      'Recommendations never select items automatically. Tap a thumbnail to mark it for deletion.';

  @override
  String get scanEmptyUnverified =>
      'Some original resources still need verification. Exact duplicates and large files cannot yet be determined. You can preview photos and screenshots.';

  @override
  String get scanEmptyVisualPending =>
      'Some photo previews still need analysis. Visual candidates will appear progressively; you can preview photos and screenshots.';

  @override
  String get scanEmptyIndexing =>
      'The library is still being indexed. This category will update as indexing progresses.';

  @override
  String get scanEmptyCategory =>
      'No items in this category among the currently analyzed or verified items.';

  @override
  String get scanKeepBadge => 'Suggested keep';

  @override
  String get scanZoomPreview => 'Enlarge preview';

  @override
  String get scanCompressVideo => 'Compress this video';

  @override
  String get scanContentPending => 'Content analysis pending';

  @override
  String get scanBackToCompare => 'Back to comparison';

  @override
  String get scanConfirmDeleteTitle => 'Delete these selected items?';

  @override
  String get scanCancel => 'Cancel';

  @override
  String get scanNoItemsDeleted =>
      'No items were deleted. The operation may have been canceled or failed.';

  @override
  String get scanConfirmDelete => 'Confirm deletion';

  @override
  String get scanCategoryPhotos => 'Photos';

  @override
  String get scanCategoryExact => 'Exact duplicates';

  @override
  String get scanCategorySimilar => 'Visual candidates';

  @override
  String get scanCategoryScreenshots => 'Screenshots';

  @override
  String get scanCategoryVideos => 'Videos';

  @override
  String get scanCategoryLarge => 'Large files';

  @override
  String scanExactGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return 'Exact duplicates: $_temp0';
  }

  @override
  String scanSimilarGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return 'Visual candidates: $_temp0';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Suggested keep: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Selected items: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return 'Preview and delete $_temp0';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '$count item selected',
    );
    return '$_temp0. Review your selection and keep recommendations before deleting. Recovered storage is determined by the system.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Items deleted: $count.';
  }

  @override
  String get scanIndexingTitle => 'Indexing photo library';

  @override
  String get scanVerifyingTitle => 'Checking original files';

  @override
  String get scanAnalyzingTitle => 'Analyzing local photo previews';

  @override
  String get scanSlowOperationHint =>
      'This operation is taking longer. You can cancel, keep progress and continue later.';

  @override
  String get scanProgressPreviewHint =>
      'You can view indexed photos and screenshots. Pending downloads or unsuccessful analyses are never treated as exact duplicates.';

  @override
  String get scanCountConfirming => 'Checking';

  @override
  String scanIndexedCount(int indexed, String total) {
    return 'Indexed $indexed / $total items';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Photo previews processed: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Original resources processed: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Visual analyses completed: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originals verified: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Pending download: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Not yet processed in this stage: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Waiting $seconds seconds';
  }

  @override
  String get swipeKeep => 'Keep';

  @override
  String get swipeDelete => 'Delete';

  @override
  String get swipeReviewComplete => 'Review complete!';

  @override
  String get swipeRecoveredSpaceHint =>
      'Recovered storage is determined by the system.';

  @override
  String get swipeUndoChoice => 'Undo last choice';

  @override
  String get swipeBack => 'Back';

  @override
  String get swipeConfirmDeleteTitle =>
      'Delete the photos marked for deletion?';

  @override
  String get swipeCancel => 'Cancel';

  @override
  String get swipeConfirmDelete => 'Confirm deletion';

  @override
  String get swipeNoPhotosDeleted =>
      'No photos were deleted. The operation may have been canceled or failed.';

  @override
  String get swipeExitTitle => 'Leave this review?';

  @override
  String get swipeContinueReview => 'Continue review';

  @override
  String get swipeLeave => 'Leave';

  @override
  String get swipeSkipRemainingTitle => 'Skip remaining photos?';

  @override
  String get swipeDone => 'Done';

  @override
  String swipeDoneCount(int count) {
    return 'Done ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Delete: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Keep: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    String _temp0 = intl.Intl.pluralLogic(
      deleteCount,
      locale: localeName,
      other: '$deleteCount photos',
      one: '$deleteCount photo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      keepCount,
      locale: localeName,
      other: '$keepCount photos',
      one: '$keepCount photo',
    );
    return '$_temp0 to delete · $_temp1 to keep';
  }

  @override
  String swipeDeletePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return 'Delete $_temp0';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Photos selected for deletion: $count. Remove any photos you want to keep from the deletion list.';
  }

  @override
  String swipePartialDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0 deleted. Remaining photos have not been deleted.';
  }

  @override
  String swipeExitDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return 'You marked $_temp0 for deletion. Leaving will not delete them.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return 'Unreviewed photos: $remaining. Finish reviewing and confirm the photos already marked for deletion ($deleteCount)?';
  }

  @override
  String assetDimensions(int width, int height) {
    return '$width × $height';
  }

  @override
  String assetPreviewDetails(int width, int height, String size) {
    return '$width × $height · $size';
  }

  @override
  String get assetReloadPreview => 'Reload preview';

  @override
  String get assetSizeUnknown => 'Size unavailable';

  @override
  String assetSizeGigabytes(String value) {
    return '$value GB';
  }

  @override
  String assetSizeMegabytes(String value) {
    return '$value MB';
  }

  @override
  String assetSizeKilobytes(String value) {
    return '$value KB';
  }

  @override
  String assetSizeBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bytes',
      one: '$count byte',
    );
    return '$_temp0';
  }

  @override
  String get appName => 'Cleanup Master';

  @override
  String get nativePhotoRead =>
      'Access the photos and videos you allow so you can preview, organize, and confirm what to delete.';

  @override
  String get nativePhotoAdd =>
      'Save a compressed video copy to Photos when you confirm. The original is kept.';

  @override
  String get nativeContacts =>
      'Access your contacts to help organize duplicate contact details.';

  @override
  String get nativeTracking =>
      'Allow tracking to personalize your experience and improve the service.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Subscriptions are currently unavailable. Please try again later.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Unable to connect to the subscription service. Please try again later.';

  @override
  String get serviceNoPlans =>
      'No subscription plans are available right now. Please try again later.';

  @override
  String get servicePlansLoadFailed =>
      'Unable to load plans. Check your connection and try again.';

  @override
  String get servicePurchaseUnavailable =>
      'Purchases are currently unavailable. Please try again later.';

  @override
  String get servicePurchaseFailed =>
      'Purchase not completed. Please try again later.';

  @override
  String get serviceRestoreUnavailable =>
      'Restoring purchases is currently unavailable. Please try again later.';

  @override
  String get serviceNoSubscription => 'No active Pro subscription was found.';

  @override
  String get serviceRestoreFailed =>
      'Unable to restore purchases. Check your connection and try again.';

  @override
  String get servicePurchaseCancelled => 'Purchase cancelled.';

  @override
  String get serviceScanPaused =>
      'Paused. Read and analyzed results are kept. You can continue scanning.';

  @override
  String get serviceLimitedLibrary =>
      'Only the photos you allowed are included, not your entire library.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'Original-file analysis is unavailable on this device. Sizes and exact duplicates are unverified.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Verify local originals to confirm file sizes and exact duplicates. Large or cloud items may remain pending; unverified sizes are not estimated.';

  @override
  String get serviceReadingIndex => 'Reading library index';

  @override
  String get servicePhotoPermission =>
      'Photo access is not allowed. Allow access in Settings and try again.';

  @override
  String get serviceOriginalRoundLimit =>
      'This verification round reached 60 seconds. Results are kept; verify again to process untried items first.';

  @override
  String get servicePreviewRoundLimit =>
      'This preview round reached 30 seconds. Results are kept; continue to process untried photos first.';

  @override
  String get serviceReadTimeout =>
      'Some reads timed out. Current results are kept; you can continue scanning.';

  @override
  String get serviceReadInterrupted =>
      'Some library reads were interrupted. Current results are kept; you can continue scanning.';

  @override
  String get serviceVerifyingOriginals => 'Verifying local originals';

  @override
  String get serviceGroupingSimilar => 'Grouping visually similar candidates';

  @override
  String get serviceQualityLowDetail =>
      'Preview has too little detail for a quality recommendation';

  @override
  String get serviceQualityDecodeFailed =>
      'Preview could not be decoded; quality was not evaluated';

  @override
  String get serviceQualityLowInformation =>
      'Insufficient image information for a quality recommendation';

  @override
  String get serviceQualityClearEdges => 'Clearer preview edges';

  @override
  String get serviceQualityLessDetail => 'Less preview edge detail';

  @override
  String get serviceQualityDark => 'Image appears dark';

  @override
  String get serviceQualityBright => 'Image appears bright';

  @override
  String get serviceQualityBalanced => 'Balanced overall brightness';

  @override
  String get serviceKeepExact =>
      'Original and edited resources match exactly. Suggested copy to keep.';

  @override
  String get serviceKeepHigherResolution =>
      'Higher resolution within this group. Suggested to keep; check the photo content.';

  @override
  String get serviceVideoMissing => 'Video not found. Scan again.';

  @override
  String get serviceVideoCloud =>
      'The video is in iCloud. Download the original in Photos and try again.';

  @override
  String get serviceVideoUnreadable => 'Unable to read this video.';

  @override
  String get serviceVideoPreviousBusy =>
      'The previous compression is still ending. Try again shortly.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Unable to prepare temporary video storage.';

  @override
  String get serviceVideoUnsupported =>
      'Video compression is unavailable on this device.';

  @override
  String get serviceVideoOutputInvalid =>
      'The output location is invalid. The original is kept.';

  @override
  String get serviceVideoSaveUnknown =>
      'Unable to confirm the saved copy. Check Photos before trying again.';

  @override
  String get serviceVideoCancelled => 'Compression cancelled.';

  @override
  String get serviceVideoOperationBusy =>
      'Finish the current video operation first.';

  @override
  String get serviceVideoEmpty =>
      'The original is empty and cannot be compressed.';

  @override
  String get serviceVideoEncodeFailed =>
      'Compression did not finish. The original is kept.';

  @override
  String get serviceVideoNoCopy =>
      'Compression did not create a separate copy. The original is kept.';

  @override
  String get serviceVideoNotSmaller =>
      'The compressed video is not smaller. The original is kept.';

  @override
  String get serviceVideoDurationMismatch =>
      'The compressed video duration does not match. The original is kept.';

  @override
  String get serviceVideoValidationFailed =>
      'Unable to verify the video. The original is kept.';

  @override
  String get serviceVideoPreviewFirst =>
      'Finish compression and review the preview first.';

  @override
  String get serviceVideoSaveFailed =>
      'Unable to save the copy. The original is kept. Try again.';

  @override
  String get serviceVideoGenericFailed =>
      'Operation not completed. The original is kept. Check photo access and free space, then try again.';

  @override
  String get serviceOperationFailed =>
      'Unable to complete this operation. Please try again.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Read $read / $total accessible items.';
  }

  @override
  String servicePhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos still need',
      one: '$count photo still needs',
    );
    return '$_temp0 visual analysis. Continue to process untried photos first. Cloud originals are not downloaded automatically.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Reading local previews ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Analyzing local previews ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; suggested guidance only';
  }

  @override
  String get scanSwipeIntro =>
      'Swipe left to mark for deletion, right to keep. Delete only after confirming.';

  @override
  String get scanSwipeStart => 'Start swipe cleanup';

  @override
  String get scanDetails => 'Scan details';

  @override
  String get scanVerificationNeeded => 'Original files not checked yet';

  @override
  String scanVerificationProgress(int verified, int total) {
    return 'Checked $verified / $total items';
  }

  @override
  String get scanVerificationExplanation =>
      'Check file contents and sizes first to find exact duplicates and large files. Cloud items can wait.';

  @override
  String get scanOriginalsAfterPreview =>
      'Exact duplicates and large files are checked after the photo preview scan. Pause now to review found items.';

  @override
  String get scanVerifyNow => 'Check duplicates and large files';

  @override
  String get scanBrowsePhotos => 'Organize photos first';

  @override
  String get scanSelectAll => 'Select all in this category';

  @override
  String get scanClearSelection => 'Clear selection';

  @override
  String get scanKeepOneSelectOthers =>
      'Keep this, select other photos with loaded previews';

  @override
  String scanGroupReadyOthers(int ready, int total) {
    return 'Other photos ready to select: $ready of $total';
  }

  @override
  String get scanSelectOthersHint =>
      'Preview the suggested photo to keep, then select the rest of this group in one go.';

  @override
  String get scanNotChecked => 'To check';

  @override
  String scanPendingCheckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to check',
      one: '$count item to check',
    );
    return '$_temp0';
  }

  @override
  String get swipeMultiSelectTitle => 'Select multiple items';

  @override
  String get swipeDragSelectHint =>
      'Hold and drag across thumbnails to select loaded previews.';

  @override
  String swipeMarkSelectedForDeletion(int count) {
    return 'Mark $count for deletion';
  }

  @override
  String get swipeGestureTitle => 'Quick swipe cleanup';

  @override
  String get swipeGestureDelete => 'Swipe left to mark for deletion';

  @override
  String get swipeGestureKeep => 'Swipe right to keep';

  @override
  String get swipeGestureSafety =>
      'Photos go to a deletion list first. They are deleted only after you tap Done and confirm.';

  @override
  String get swipeGestureHelp => 'How to swipe';

  @override
  String get homeSwipeDescription =>
      'Swipe through photos one by one for faster cleanup than tapping thumbnails.';

  @override
  String get scanCheckExactPhotos => 'Check exact duplicates';

  @override
  String get scanCheckFileSizes => 'Check large-file sizes';

  @override
  String get reviewDeleteTitle => 'Review deletion';

  @override
  String get reviewRemove => 'Remove from deletion';

  @override
  String get reviewUnavailable =>
      'Preview unavailable. Retry or remove this item.';

  @override
  String reviewUnseenCount(int count) {
    return 'Items needing preview before deletion: $count';
  }

  @override
  String get reviewAllVersions =>
      'All versions in a group are selected. Delete every version?';

  @override
  String get reviewDeleteAllVersions => 'Delete every version';

  @override
  String reviewConfirmCount(int count) {
    return 'Confirm deletion · $count';
  }

  @override
  String swipeResumeReview(int count) {
    return 'Continue previous review · $count reviewed';
  }

  @override
  String get swipeResetReview => 'Start over';

  @override
  String swipeBatchSize(int count) {
    return 'Items per batch: $count';
  }

  @override
  String get swipeAllMonths => 'All months';

  @override
  String get swipeReviewBatch => 'Choose a month or batch';

  @override
  String get assetVideoLoading => 'Loading original video…';

  @override
  String get assetVideoUnavailable =>
      'Original video unavailable. Download it in Photos, then retry.';

  @override
  String get homePermissionTitle => 'Photo access needed';

  @override
  String get homePermissionDescription =>
      'Allow photo access in Settings to scan and review. Nothing is deleted automatically.';

  @override
  String get homeOpenSettings => 'Open Settings';

  @override
  String get homeManagePhotoAccess => 'Manage photo access';

  @override
  String get homeReviewReady => 'Review available photos';

  @override
  String get homeContinueAnalysis => 'Continue photo analysis';

  @override
  String get homeScanDetails => 'Scan details';

  @override
  String get scanCheckingExactTitle => 'Checking exact duplicate photos';

  @override
  String get scanCheckingSizesTitle => 'Checking file sizes';

  @override
  String scanRoundProgress(int total, int completed) {
    return 'Processed $completed / $total';
  }

  @override
  String get scanPauseReview => 'Pause checking and review';

  @override
  String get scanSelectionHint =>
      'Check items to mark for deletion. Tap Preview to view their content.';

  @override
  String get scanPreviewNotReady => 'Load the preview before selecting';

  @override
  String scanUnreadableExcluded(int count) {
    return 'Previews not loaded and excluded from selection: $count';
  }

  @override
  String get scanKeepThis => 'Keep this photo';

  @override
  String get scanPreviewMore => 'Load more photos';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return 'Confirmed file sizes: $size · Checked: $count';
  }

  @override
  String homePendingSizes(int count) {
    return 'Items with size still unknown: $count';
  }

  @override
  String get scanReviewChanged =>
      'Photos or permissions have changed. Review your deletion list again.';

  @override
  String get paywallFreePreviewNote =>
      'Photo grouping, previews and swipe marking are free. Pro unlocks confirmed deletion and video compression.';

  @override
  String paywallSubscribeWeekly(String price) {
    return 'Subscribe weekly · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return 'Subscribe yearly · $price';
  }

  @override
  String get paywallSubscribe => 'Subscribe';

  @override
  String paywallWeeklyRenewal(String price) {
    return 'Renews automatically at $price each week unless canceled. Review the final terms in the App Store.';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return 'Renews automatically at $price each year unless canceled. Review the final terms in the App Store.';
  }

  @override
  String get paywallRenewalGeneric =>
      'Renews automatically unless canceled. Review the billing period and amount in the App Store before confirming.';

  @override
  String get paywallLoadingPlans => 'Loading subscription plans…';

  @override
  String get paywallWaitingForStore => 'Waiting for App Store confirmation…';

  @override
  String get paywallRestoring => 'Restoring purchases…';

  @override
  String get settingsCheckingSubscription => 'Checking subscription…';

  @override
  String get settingsSubscriptionUnknown => 'Subscription status unavailable';

  @override
  String get settingsManageSubscription => 'Manage subscription';

  @override
  String get settingsManageUnavailable =>
      'Could not open subscription management. Open subscriptions in your store account settings.';

  @override
  String get onboardingStartFree => 'Start for free';

  @override
  String get swipeCheckpointSaveError =>
      'Could not save review progress. You can keep reviewing, but it may not resume next time.';

  @override
  String swipeCheckpointLimit(int count) {
    return 'Recent review choices kept on this device: up to $count';
  }

  @override
  String get scanSelectLoaded => 'Select loaded previews';

  @override
  String get homePhotoScopeChanged =>
      'Photo access may have changed. Scan again to refresh available photos.';

  @override
  String get navOptimize => 'Optimize';

  @override
  String get navExtras => 'Extras';

  @override
  String get v2Before => 'Before';

  @override
  String get v2After => 'After';

  @override
  String get v2Best => 'Best';

  @override
  String get v2Cancel => 'Cancel';

  @override
  String get v2Select => 'Select';

  @override
  String get v2SelectAll => 'Select All';

  @override
  String get v2DeselectAll => 'Deselect All';

  @override
  String v2SelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get v2CatSimilars => 'Similar';

  @override
  String get v2CatDuplicates => 'Duplicates';

  @override
  String get v2CatVideos => 'Videos';

  @override
  String get v2CatScreenshots => 'Screenshots';

  @override
  String get v2CatBlurred => 'Blurred';

  @override
  String get v2CatLarge => 'Large Files';

  @override
  String get v2CatOther => 'Other';

  @override
  String v2PhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Photos',
      one: '1 Photo',
    );
    return '$_temp0';
  }

  @override
  String v2VideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Videos',
      one: '1 Video',
    );
    return '$_temp0';
  }

  @override
  String v2ItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count Items',
      one: 'Delete 1 Item',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count Videos',
      one: 'Delete 1 Video',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteSize(String size) {
    return 'Delete $size';
  }

  @override
  String v2FreeCleanupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free cleanups left',
      one: '1 free cleanup left',
    );
    return '$_temp0';
  }

  @override
  String get v2SpaceToClean => 'Space to Clean';

  @override
  String v2StorageUsedOf(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get v2OptimizeTitle => 'Optimize Storage';

  @override
  String get v2OptimizeSubtitle => 'Free up space from your files quickly';

  @override
  String get v2Scanning => 'Scanning your library…';

  @override
  String v2ScanningCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String get v2CheckingDuplicates => 'Checking duplicates…';

  @override
  String get v2ScanStart => 'Scan my photos';

  @override
  String get v2PermissionTitle => 'Allow access to Photos';

  @override
  String v2PermissionBody(String appName) {
    return '$appName needs access to your photos to find duplicates and free up storage. Your photos stay on your device.';
  }

  @override
  String get v2OpenSettings => 'Open Settings';

  @override
  String get v2IntroLeft => 'Left';

  @override
  String get v2IntroToDelete => 'to Delete';

  @override
  String get v2IntroRight => 'Right';

  @override
  String get v2IntroToKeep => 'to Keep';

  @override
  String get v2LetsGo => 'Let\'s go';

  @override
  String get v2IntroSimilars =>
      'Similar shots are grouped together. We keep the best one and select the rest for you.';

  @override
  String get v2IntroDuplicates =>
      'Exact copies of the same photo. Keep one and delete the rest in one tap.';

  @override
  String get v2IntroVideos =>
      'Review all your videos. Sort them by size or date to see the ones that take the most space.';

  @override
  String get v2IntroScreenshots =>
      'Old screenshots pile up fast. Swipe through them and clear the ones you no longer need.';

  @override
  String get v2IntroBlurred =>
      'Blurry and out-of-focus shots you probably don\'t want to keep.';

  @override
  String get v2IntroLarge =>
      'Your biggest photos and videos. Deleting a few of them frees the most space.';

  @override
  String get v2IntroOther =>
      'Photos that don\'t belong to any category. Sort them by size or date and say goodbye to the ones you don\'t need.';

  @override
  String get v2IntroOptimize =>
      'Finds duplicate and similar photos, keeps the best ones and selects the rest. Free up space in seconds.';

  @override
  String get v2SortLargest => 'Largest';

  @override
  String get v2SortNewest => 'Newest';

  @override
  String get v2EmptyCategory => 'Nothing to clean here';

  @override
  String get v2EmptyCategoryBody => 'This category is already clean.';

  @override
  String get v2VideoCompress => 'Video Compress';

  @override
  String get v2VideoCompressSubtitle => 'Tap to start the process';

  @override
  String get v2VideoCompressBody =>
      'Compress videos into smaller copies to save storage.';

  @override
  String get v2CongratsTitle => 'Congratulations!';

  @override
  String get v2CongratsDeleted => 'You have deleted';

  @override
  String v2CongratsSaved(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Saved about $minutes minutes',
      one: 'Saved about 1 minute',
    );
    return '$_temp0';
  }

  @override
  String v2CongratsUsing(String appName) {
    return 'using $appName';
  }

  @override
  String v2CongratsRecentlyDeleted(String size) {
    return 'These items stay in “Recently Deleted” for 30 days. Delete them there to free up an estimated $size; iPhone Storage shows the actual amount.';
  }

  @override
  String get v2Great => 'Great';

  @override
  String get v2UnlockTitle => 'Unlock Unlimited Access';

  @override
  String get v2UnlockFeature1 => 'Instantly find similar photos';

  @override
  String get v2UnlockFeature2 => 'No limits on cleanup';

  @override
  String get v2UnlockFeature3 => 'Save both storage and time';

  @override
  String get v2PrivacyLine =>
      'Your photos are analyzed on your device and never uploaded.';

  @override
  String v2PerWeek(String price) {
    return '$price/week, cancel anytime';
  }

  @override
  String v2PerYear(String price) {
    return '$price/year';
  }

  @override
  String v2SavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String v2FreeTrialDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day free trial',
      one: '1-day free trial',
    );
    return '$_temp0';
  }

  @override
  String v2StartFreeTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Start my $days-day free trial',
      one: 'Start my 1-day free trial',
    );
    return '$_temp0';
  }

  @override
  String v2FreeThen(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Free for $days days, then $price',
      one: 'Free for 1 day, then $price',
    );
    return '$_temp0';
  }

  @override
  String get v2TrialEnabled => 'Free trial enabled';

  @override
  String get v2DueToday => 'Due today';

  @override
  String v2DueOn(String date) {
    return 'Due $date';
  }

  @override
  String v2DaysFree(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days free',
      one: '1 day free',
    );
    return '$_temp0';
  }

  @override
  String get v2TryFree => 'Try Free';

  @override
  String get v2CleanYourStorage => 'Clean your Storage';

  @override
  String get v2GetRidOf => 'Get rid of what you don\'t need';

  @override
  String get v2ProFeatures => 'Smart cleanup, video compression and no limits.';

  @override
  String v2WelcomeTitle(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String v2WelcomeAccess(String appName) {
    return '$appName needs access to your Photos to free up storage.';
  }

  @override
  String get v2WelcomePrivacy =>
      'Your photos are analyzed on your device and never uploaded to our servers.';

  @override
  String get v2GetStarted => 'Get started';

  @override
  String get v2Next => 'Next';

  @override
  String get v2OnbDupTitle => 'Delete Duplicate Photos';

  @override
  String get v2OnbDupBody =>
      'Find duplicate photos in seconds and reclaim your storage.';

  @override
  String get v2OnbSwipeTitle => 'Swipe to Clean';

  @override
  String get v2OnbSwipeBody =>
      'Swipe left to delete, right to keep. Cleaning up has never been this quick.';

  @override
  String get v2OnbVideoTitle => 'Compress Videos';

  @override
  String get v2OnbVideoBody => 'Shrink large videos and keep your memories.';

  @override
  String v2TryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Try $days days',
      one: 'Try 1 day',
    );
    return '$_temp0';
  }

  @override
  String get v2ForFree => 'For free!';

  @override
  String get v2ExtrasTitle => 'Extra Tools';

  @override
  String get v2ExtrasUtilities => 'Utilities';

  @override
  String get v2ExtrasPrivate => 'Private';

  @override
  String get v2ChargingTitle => 'Charging Animation';

  @override
  String get v2ChargingBody => 'Personalize your charging screen';

  @override
  String get v2SecretTitle => 'Secret Library';

  @override
  String get v2SecretBody => 'Protect your private photos';

  @override
  String get v2ScanPaused => 'Scan paused';

  @override
  String get v2ContinueScan => 'Continue';

  @override
  String get v2PauseScan => 'Pause scan';

  @override
  String v2ContinueFreeCleanup(int count) {
    return 'Continue free cleanup ($count remaining)';
  }

  @override
  String get v2DailyLimitTitle => 'You\'ve reached your daily removal limit';

  @override
  String v2DailyLimitBody(int limit) {
    return 'You can delete $limit items a day with the free version. Unlock Pro to remove the limit.';
  }

  @override
  String v2DailyLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You can delete $count more items today for free. Select fewer items or unlock Pro.',
      one:
          'You can delete 1 more item today for free. Select fewer items or unlock Pro.',
    );
    return '$_temp0';
  }

  @override
  String get v2SeeProOptions => 'See Pro Options';

  @override
  String get v2SelectionOverLimitTitle => 'Too many items for today';

  @override
  String get v2CheckPaused => 'Duplicate check paused';

  @override
  String get v2StillChecking => 'Still checking your photos';

  @override
  String get v2StillCheckingBody =>
      'Results appear here as the scan continues on Home.';
}
