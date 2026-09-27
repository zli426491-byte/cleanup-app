// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Nettoyage intelligent';

  @override
  String get onboardingSmartSubtitle =>
      'Analysez les photos et vidéos auxquelles vous autorisez l’accès\nPrévisualisez-les, puis choisissez quoi garder ou supprimer';

  @override
  String get onboardingPhotosTitle => 'Organiser les photos';

  @override
  String get onboardingPhotosSubtitle =>
      'Comparez le contenu des photos identiques et similaires\nVérifiez chaque suggestion de photo à garder';

  @override
  String get onboardingSwipeTitle => 'Balayer pour organiser';

  @override
  String get onboardingSwipeSubtitle =>
      'Balayez pour choisir quoi garder ou supprimer\nConfirmez tous vos choix à la fin';

  @override
  String get onboardingChoiceTitle => 'À vous de décider';

  @override
  String get onboardingChoiceSubtitle =>
      'L’analyse et les aperçus sont gratuits\nLa suppression et la compression vidéo nécessitent Pro. Les originaux ne sont jamais supprimés automatiquement.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingPreparing => 'Préparation…';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Fermer';

  @override
  String get paywallDescription =>
      'Débloquez le nettoyage des photos et vidéos. Prévisualisez les éléments avant de choisir quoi supprimer.';

  @override
  String get paywallReloadPlans => 'Recharger les offres';

  @override
  String get paywallNotConfigured => 'Abonnements indisponibles';

  @override
  String get paywallContinue => 'Continuer';

  @override
  String get paywallStoreNotice =>
      'Les achats se font via l’App Store. Gérez ou résiliez vos abonnements dans les réglages de votre identifiant Apple.';

  @override
  String get paywallRestorePurchases => 'Restaurer les achats';

  @override
  String get paywallPrivacyPolicy => 'Confidentialité';

  @override
  String get paywallTerms => 'Conditions d’utilisation';

  @override
  String get paywallPurchaseIncomplete =>
      'Achat non finalisé. Réessayez plus tard.';

  @override
  String get paywallRestored => 'Accès Pro restauré.';

  @override
  String get paywallRestoreNotFound => 'Aucun achat à restaurer.';

  @override
  String get paywallWeeklyPlan => 'Abonnement hebdomadaire';

  @override
  String get paywallYearlyPlan => 'Abonnement annuel';

  @override
  String get paywallYearlySubtitle =>
      'Organisez photos et vidéos toute l’année';

  @override
  String get paywallWeeklySubtitle => 'Pour un nettoyage ponctuel des photos';

  @override
  String get paywallPhotoFeature =>
      'Regroupez les photos identiques et similaires, puis vérifiez chaque élément';

  @override
  String get paywallVideoFeature =>
      'Compressez les vidéos, prévisualisez-les et enregistrez des copies';

  @override
  String get paywallSwipeFeature => 'Organisez rapidement par balayage';

  @override
  String get paywallPlansUnavailable =>
      'Impossible de charger les offres. Vérifiez votre connexion et rechargez-les.';

  @override
  String get paywallBestValue => 'Meilleur rapport qualité-prix';

  @override
  String get videoTitle => 'Compression vidéo';

  @override
  String get videoDescription =>
      'La compression réduit la qualité et crée une copie. Vérifiez l’image, le son et l’orientation avant l’enregistrement dans Photos. L’original est conservé.';

  @override
  String get videoProRequired =>
      'Cette fonction nécessite Pro. Revenez à la page de nettoyage pour voir les offres.';

  @override
  String get videoSaving =>
      'Enregistrement dans Photos. Patientez jusqu’à la fin.';

  @override
  String get videoCancelCompression => 'Annuler la compression';

  @override
  String get videoLoadingPreview => 'Chargement de l’aperçu vidéo…';

  @override
  String get videoCreatePreview => 'Créer un aperçu compressé';

  @override
  String get videoStorageNotice =>
      'Enregistrer une copie utilise temporairement plus d’espace. Après avoir supprimé l’original et vidé « Supprimées récemment », consultez le système pour connaître l’espace réellement disponible.';

  @override
  String get videoViewOriginal => 'Voir l’original';

  @override
  String get videoViewCopy => 'Voir la copie compressée';

  @override
  String get videoSaved =>
      'La copie est enregistrée dans Photos et l’original est conservé. Relancez l’analyse depuis l’accueil, puis choisissez si vous souhaitez supprimer l’original.';

  @override
  String get videoConfirmSave =>
      'Confirmer la copie et enregistrer dans Photos';

  @override
  String get videoPreviewUnavailable =>
      'Impossible de lire l’aperçu. Réessayez. L’original est conservé.';

  @override
  String get videoPlaybackUnavailable =>
      'La vidéo ne peut pas être lue pour le moment. Rechargez l’aperçu.';

  @override
  String get videoOperationIncomplete =>
      'L’opération n’a pas abouti. L’original est conservé. Vérifiez l’accès à Photos et l’espace disponible, puis réessayez.';

  @override
  String get videoPauseOriginal => 'Original : pause';

  @override
  String get videoPlayOriginal => 'Original : lire';

  @override
  String get videoPauseCopy => 'Copie compressée : pause';

  @override
  String get videoPlayCopy => 'Copie compressée : lire';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Version $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Préparation / compression vidéo $percent %';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Original : $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Copie : $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Différence de taille : $size';
  }

  @override
  String videoSizeGb(String size) {
    return '$size Go';
  }

  @override
  String videoSizeMb(String size) {
    return '$size Mo';
  }

  @override
  String get homeStorageUnavailable =>
      'Consultez le stockage dans les réglages de l’iPhone. Ici, vous pouvez organiser les photos et vidéos accessibles.';

  @override
  String get homeViewIndexedPhotos => 'Voir les photos déjà lues';

  @override
  String get homeViewIndexedScreenshots => 'Voir les captures déjà lues';

  @override
  String get homeCleanupTools => 'Outils de nettoyage';

  @override
  String get homeQuickActions => 'Actions rapides';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Prévisualisez, puis organisez photos et vidéos';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Utilisé';

  @override
  String get homeUsedLegend => 'Utilisé';

  @override
  String get homeAvailableLegend => 'Disponible';

  @override
  String get homeStartScanHint =>
      'Aucune analyse. Touchez ci-dessous pour commencer.';

  @override
  String get homeScanning => 'Analyse…';

  @override
  String get homeDeleting => 'Suppression…';

  @override
  String get homeResumeScan =>
      'Continuer l’analyse en conservant la progression';

  @override
  String get homeScanAll => 'Analyser toutes les photos et vidéos accessibles';

  @override
  String get homePreviewOrganize => 'Prévisualiser et organiser';

  @override
  String get homeVerifyOriginals =>
      'Vérifier les originaux locaux pour confirmer les doublons exacts et les tailles';

  @override
  String get homeRetryPending =>
      'Continuer l’analyse / réessayer les éléments en attente';

  @override
  String get homeExactDuplicates => 'Photos exactement identiques';

  @override
  String get homeSimilarPhotos => 'Photos visuellement similaires';

  @override
  String get homeNotScanned => 'Pas encore analysé';

  @override
  String get homePendingAnalysis => 'Analyse visuelle en attente';

  @override
  String get homeNoneAnalyzed => 'Aucun résultat parmi les éléments analysés';

  @override
  String get homeScreenshots => 'Captures d’écran';

  @override
  String get homeLargeFiles => 'Fichiers volumineux';

  @override
  String get homeNoneFound => 'Aucun résultat';

  @override
  String get homePendingVerification => 'Vérification des originaux en attente';

  @override
  String get homeNoneVerified => 'Aucun résultat parmi les éléments vérifiés';

  @override
  String get homeNeedsReview => 'À vérifier';

  @override
  String get homeCanReview => 'Vérifier';

  @override
  String get homeScanStatus => 'Analyser';

  @override
  String get homeDoneStatus => 'Terminé ✓';

  @override
  String get homePreviewPhotos => 'Prévisualiser les photos';

  @override
  String get homeChooseKeep => 'Choisir quoi garder';

  @override
  String get navHome => 'Accueil';

  @override
  String get navClean => 'Nettoyer';

  @override
  String get navSettings => 'Réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLoading => 'Chargement…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Offre gratuite';

  @override
  String get settingsUpgrade => 'Passer à Pro';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsStorageTotal => 'Total';

  @override
  String get settingsStorageUsed => 'Utilisé';

  @override
  String get settingsStorageAvailable => 'Disponible';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsProcessingSubscription => 'Traitement de l’abonnement…';

  @override
  String get settingsRestorePurchases => 'Restaurer les achats';

  @override
  String get settingsRestoredPro => 'Abonnement Pro restauré.';

  @override
  String get settingsPrivacyPolicy => 'Confidentialité';

  @override
  String get settingsTerms => 'Conditions d’utilisation';

  @override
  String get settingsRateApp => 'Nous évaluer';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsChooseLanguage => 'Choisir la langue';

  @override
  String get settingsSystemLanguage => 'Langue du système';

  @override
  String homeUsedPercent(int percent) {
    return '$percent %';
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
      other: '$count éléments',
      one: '1 élément',
    );
    return 'Lus : $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '$count éléments accessibles lus sur $total';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Analyses visuelles : $analyzed. Originaux vérifiés : $verified. Les suggestions peuvent être annulées ; vous décidez quoi supprimer.';
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
      other: '$count photos (résultats partiels)',
      one: '1 photo (résultats partiels)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos vérifiées ; d’autres en attente',
      one: '1 photo vérifiée ; d’autres en attente',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments vérifiés ; d’autres en attente',
      one: '1 élément vérifié ; d’autres en attente',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String get scanSmartTitle => 'Nettoyage intelligent';

  @override
  String get scanCancelKeepProgress =>
      'Annuler l’analyse et garder la progression';

  @override
  String get scanSwipeCleanup => 'Nettoyage par balayage';

  @override
  String get scanSortFileSize => 'Taille du fichier';

  @override
  String get scanSortNewest => 'Les plus récents';

  @override
  String get scanStartAlbumTitle => 'Commencer l’analyse de la photothèque';

  @override
  String get scanIncompleteTitle => 'Analyse incomplète';

  @override
  String get scanStartAlbumDescription =>
      'Analysez toutes les photos et vidéos accessibles. La vérification des originaux et l’analyse visuelle vous aident à les examiner avant de décider.';

  @override
  String get scanContinue => 'Continuer l’analyse';

  @override
  String get scanStart => 'Lancer l’analyse';

  @override
  String get scanPreviewWhileRunning =>
      'Vous pouvez prévisualiser les photos et captures. La sélection, la suppression et la compression vidéo sont suspendues pendant l’analyse.';

  @override
  String get scanExactDescription =>
      'Les doublons exacts ne comprennent que des éléments dont les originaux ont été vérifiés. Les suggestions de conservation peuvent être ignorées.';

  @override
  String get scanSimilarDescription =>
      'Les candidats apparaissent au fil de l’analyse des aperçus locaux. Leur contenu peut différer ; les suggestions de conservation ne sont qu’un guide.';

  @override
  String get scanLargeDescription =>
      'Triés par taille vérifiée des ressources. La taille des fichiers peut différer de l’espace réellement récupéré, qui est déterminé par le système.';

  @override
  String get scanManualDeleteDescription =>
      'Seuls les éléments sélectionnés manuellement et confirmés seront supprimés.';

  @override
  String get scanVerifyOriginals =>
      'Vérifier les originaux locaux : doublons exacts et taille';

  @override
  String get scanResumePending =>
      'Continuer l’analyse / réessayer les éléments en attente';

  @override
  String get scanKeepReasonDefault =>
      'Cette photo est suggérée comme élément à garder dans ce groupe.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Afficher à nouveau la suggestion de conservation';

  @override
  String get scanDismissKeepSuggestion =>
      'Ignorer la suggestion de conservation';

  @override
  String get scanKeepManualHint =>
      'Les suggestions ne sélectionnent jamais rien automatiquement. Touchez une miniature pour la marquer à supprimer.';

  @override
  String get scanEmptyUnverified =>
      'Certains originaux restent à vérifier. Les doublons exacts et les gros fichiers ne peuvent pas encore être déterminés. Vous pouvez prévisualiser les photos et captures.';

  @override
  String get scanEmptyVisualPending =>
      'Certains aperçus restent à analyser. Les candidats apparaîtront progressivement ; vous pouvez prévisualiser les photos et captures.';

  @override
  String get scanEmptyIndexing =>
      'L’indexation de la photothèque continue. Cette catégorie sera actualisée au fil de la progression.';

  @override
  String get scanEmptyCategory =>
      'Aucun élément dans cette catégorie parmi ceux déjà analysés ou vérifiés.';

  @override
  String get scanKeepBadge => 'À garder : suggestion';

  @override
  String get scanZoomPreview => 'Agrandir l’aperçu';

  @override
  String get scanCompressVideo => 'Compresser cette vidéo';

  @override
  String get scanContentPending => 'Analyse du contenu en attente';

  @override
  String get scanBackToCompare => 'Retour à la comparaison';

  @override
  String get scanConfirmDeleteTitle => 'Supprimer les éléments sélectionnés ?';

  @override
  String get scanCancel => 'Annuler';

  @override
  String get scanNoItemsDeleted =>
      'Aucun élément supprimé. L’opération a peut-être été annulée ou a échoué.';

  @override
  String get scanConfirmDelete => 'Confirmer la suppression';

  @override
  String get scanCategoryPhotos => 'Photos';

  @override
  String get scanCategoryExact => 'Doublons exacts';

  @override
  String get scanCategorySimilar => 'Candidats visuels';

  @override
  String get scanCategoryScreenshots => 'Captures d’écran';

  @override
  String get scanCategoryVideos => 'Vidéos';

  @override
  String get scanCategoryLarge => 'Fichiers volumineux';

  @override
  String scanExactGroupCount(int count) {
    return 'Doublons exacts : $count photos';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Candidats visuels : $count photos';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Suggestion à garder : $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Éléments sélectionnés : $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Prévisualiser et supprimer $count éléments';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count éléments sélectionnés. Vérifiez la sélection et les suggestions avant de supprimer. Le système détermine l’espace récupéré.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Éléments supprimés : $count.';
  }

  @override
  String get scanIndexingTitle => 'Indexation de la photothèque';

  @override
  String get scanVerifyingTitle =>
      'Vérification des originaux pour les doublons exacts';

  @override
  String get scanAnalyzingTitle => 'Analyse des aperçus locaux';

  @override
  String get scanSlowOperationHint =>
      'Cette opération prend plus de temps. Vous pouvez annuler, garder la progression et continuer plus tard.';

  @override
  String get scanProgressPreviewHint =>
      'Vous pouvez voir les photos et captures indexées. Les téléchargements en attente et les analyses échouées ne sont jamais traités comme des doublons exacts.';

  @override
  String get scanCountConfirming => 'Vérification';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '$indexed / $total éléments indexés';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Aperçus traités : $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Originaux traités : $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Analyses visuelles terminées : $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originaux vérifiés : $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Téléchargements en attente : $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Pas encore traités à cette étape : $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Attente : $seconds secondes';
  }

  @override
  String get swipeKeep => 'Garder';

  @override
  String get swipeDelete => 'Supprimer';

  @override
  String get swipeReviewComplete => 'Vérification terminée !';

  @override
  String get swipeRecoveredSpaceHint =>
      'Le système détermine l’espace récupéré.';

  @override
  String get swipeUndoChoice => 'Annuler le dernier choix';

  @override
  String get swipeBack => 'Retour';

  @override
  String get swipeConfirmDeleteTitle =>
      'Supprimer les photos marquées pour suppression ?';

  @override
  String get swipeCancel => 'Annuler';

  @override
  String get swipeConfirmDelete => 'Confirmer la suppression';

  @override
  String get swipeNoPhotosDeleted =>
      'Aucune photo supprimée. L’opération a peut-être été annulée ou a échoué.';

  @override
  String get swipeExitTitle => 'Quitter cette vérification ?';

  @override
  String get swipeContinueReview => 'Continuer la vérification';

  @override
  String get swipeLeave => 'Quitter';

  @override
  String get swipeSkipRemainingTitle => 'Passer les photos restantes ?';

  @override
  String get swipeDone => 'Terminé';

  @override
  String swipeDoneCount(int count) {
    return 'Terminé ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Supprimer : $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Garder : $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount photos à supprimer · $keepCount photos à garder';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Supprimer $count photos';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Supprimez $count photos vérifiées. Assurez-vous d’avoir correctement choisi celles à garder.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '$count photos supprimées. Les photos restantes n’ont pas été supprimées.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Vous avez marqué $count photos à supprimer. Quitter ne les supprimera pas.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '$remaining photos restent à vérifier. Terminer la vérification et confirmer les $deleteCount photos déjà marquées à supprimer ?';
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
  String get assetReloadPreview => 'Recharger l’aperçu';

  @override
  String get assetSizeUnknown => 'Taille indisponible';

  @override
  String assetSizeGigabytes(String value) {
    return '$value Go';
  }

  @override
  String assetSizeMegabytes(String value) {
    return '$value Mo';
  }

  @override
  String assetSizeKilobytes(String value) {
    return '$value Ko';
  }

  @override
  String assetSizeBytes(int count) {
    return '$count octets';
  }

  @override
  String get appName => 'Cleanup Master';

  @override
  String get nativePhotoRead =>
      'Accédez aux photos et vidéos autorisées pour les prévisualiser, les organiser et confirmer quoi supprimer.';

  @override
  String get nativePhotoAdd =>
      'Enregistrez une copie vidéo compressée dans Photos après confirmation. L’original est conservé.';

  @override
  String get nativeContacts =>
      'Accédez aux contacts pour organiser les coordonnées en double.';

  @override
  String get nativeTracking =>
      'Autorisez le suivi pour personnaliser votre expérience et améliorer le service.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Les abonnements sont indisponibles pour le moment. Réessayez plus tard.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Impossible de joindre le service d’abonnement. Réessayez plus tard.';

  @override
  String get serviceNoPlans =>
      'Aucune offre d’abonnement disponible pour le moment. Réessayez plus tard.';

  @override
  String get servicePlansLoadFailed =>
      'Impossible de charger les offres. Vérifiez votre connexion et réessayez.';

  @override
  String get servicePurchaseUnavailable =>
      'Les achats sont indisponibles pour le moment. Réessayez plus tard.';

  @override
  String get servicePurchaseFailed =>
      'Achat non finalisé. Réessayez plus tard.';

  @override
  String get serviceRestoreUnavailable =>
      'La restauration des achats est indisponible pour le moment. Réessayez plus tard.';

  @override
  String get serviceNoSubscription => 'Aucun abonnement Pro actif trouvé.';

  @override
  String get serviceRestoreFailed =>
      'Impossible de restaurer les achats. Vérifiez votre connexion et réessayez.';

  @override
  String get servicePurchaseCancelled => 'Achat annulé.';

  @override
  String get serviceScanPaused =>
      'Analyse suspendue. Les résultats lus et analysés sont conservés. Vous pouvez continuer.';

  @override
  String get serviceLimitedLibrary =>
      'Seules les photos autorisées sont incluses, pas toute la photothèque.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'L’analyse des fichiers originaux est indisponible sur cet appareil. Les tailles et doublons exacts ne sont pas vérifiés.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Vérifiez les originaux locaux pour confirmer les tailles et doublons exacts. Les éléments volumineux ou dans le cloud peuvent rester en attente ; les tailles non vérifiées ne sont pas estimées.';

  @override
  String get serviceReadingIndex => 'Lecture de l’index de la photothèque';

  @override
  String get servicePhotoPermission =>
      'L’accès aux photos n’est pas autorisé. Autorisez-le dans les réglages et réessayez.';

  @override
  String get serviceOriginalRoundLimit =>
      'Cette vérification a atteint 60 secondes. Les résultats sont conservés ; relancez-la pour traiter d’abord les éléments non essayés.';

  @override
  String get servicePreviewRoundLimit =>
      'Cette analyse des aperçus a atteint 30 secondes. Les résultats sont conservés ; continuez pour traiter d’abord les photos non essayées.';

  @override
  String get serviceReadTimeout =>
      'Certaines lectures ont expiré. Les résultats actuels sont conservés ; vous pouvez continuer l’analyse.';

  @override
  String get serviceReadInterrupted =>
      'Certaines lectures de la photothèque ont été interrompues. Les résultats actuels sont conservés ; vous pouvez continuer l’analyse.';

  @override
  String get serviceVerifyingOriginals => 'Vérification des originaux locaux';

  @override
  String get serviceGroupingSimilar =>
      'Regroupement des candidats visuellement similaires';

  @override
  String get serviceQualityLowDetail =>
      'L’aperçu manque de détails pour évaluer la qualité';

  @override
  String get serviceQualityDecodeFailed =>
      'L’aperçu n’a pas pu être décodé ; la qualité n’a pas été évaluée';

  @override
  String get serviceQualityLowInformation =>
      'Informations d’image insuffisantes pour évaluer la qualité';

  @override
  String get serviceQualityClearEdges => 'Contours plus nets dans l’aperçu';

  @override
  String get serviceQualityLessDetail =>
      'Contours moins détaillés dans l’aperçu';

  @override
  String get serviceQualityDark => 'L’image paraît sombre';

  @override
  String get serviceQualityBright => 'L’image paraît claire';

  @override
  String get serviceQualityBalanced => 'Luminosité globale équilibrée';

  @override
  String get serviceKeepExact =>
      'Les ressources originales et modifiées sont identiques. Copie suggérée à garder.';

  @override
  String get serviceKeepHigherResolution =>
      'Résolution plus élevée dans ce groupe. Suggestion à garder ; vérifiez le contenu.';

  @override
  String get serviceVideoMissing => 'Vidéo introuvable. Relancez l’analyse.';

  @override
  String get serviceVideoCloud =>
      'La vidéo est dans iCloud. Téléchargez l’original dans Photos et réessayez.';

  @override
  String get serviceVideoUnreadable => 'Impossible de lire cette vidéo.';

  @override
  String get serviceVideoPreviousBusy =>
      'La compression précédente se termine encore. Réessayez dans un instant.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Impossible de préparer le stockage vidéo temporaire.';

  @override
  String get serviceVideoUnsupported =>
      'La compression vidéo est indisponible sur cet appareil.';

  @override
  String get serviceVideoOutputInvalid =>
      'L’emplacement de sortie est invalide. L’original est conservé.';

  @override
  String get serviceVideoSaveUnknown =>
      'Impossible de confirmer la copie enregistrée. Vérifiez Photos avant de réessayer.';

  @override
  String get serviceVideoCancelled => 'Compression annulée.';

  @override
  String get serviceVideoOperationBusy =>
      'Terminez d’abord l’opération vidéo en cours.';

  @override
  String get serviceVideoEmpty =>
      'L’original est vide et ne peut pas être compressé.';

  @override
  String get serviceVideoEncodeFailed =>
      'La compression n’a pas abouti. L’original est conservé.';

  @override
  String get serviceVideoNoCopy =>
      'La compression n’a pas créé de copie distincte. L’original est conservé.';

  @override
  String get serviceVideoNotSmaller =>
      'La vidéo compressée n’est pas plus petite. L’original est conservé.';

  @override
  String get serviceVideoDurationMismatch =>
      'La durée de la vidéo compressée ne correspond pas. L’original est conservé.';

  @override
  String get serviceVideoValidationFailed =>
      'Impossible de vérifier la vidéo. L’original est conservé.';

  @override
  String get serviceVideoPreviewFirst =>
      'Terminez la compression et vérifiez d’abord l’aperçu.';

  @override
  String get serviceVideoSaveFailed =>
      'Impossible d’enregistrer la copie. L’original est conservé. Réessayez.';

  @override
  String get serviceVideoGenericFailed =>
      'L’opération n’a pas abouti. L’original est conservé. Vérifiez l’accès aux photos et l’espace libre, puis réessayez.';

  @override
  String get serviceOperationFailed =>
      'Impossible de terminer cette opération. Réessayez.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '$read / $total éléments accessibles lus.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count photos restent à analyser visuellement. Continuez pour traiter d’abord les photos non essayées. Les originaux dans le cloud ne sont pas téléchargés automatiquement.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Lecture des aperçus locaux ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Analyse des aperçus locaux ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons ; indications uniquement';
  }

  @override
  String get scanSwipeIntro =>
      'Glissez à gauche pour marquer à supprimer, à droite pour garder. Rien n’est supprimé sans confirmation.';

  @override
  String get scanSwipeStart => 'Trier en glissant';

  @override
  String get scanDetails => 'Détails de l’analyse';

  @override
  String get scanVerificationNeeded => 'Fichiers originaux non vérifiés';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '$verified / $total éléments vérifiés';
  }

  @override
  String get scanVerificationExplanation =>
      'Vérifiez le contenu et la taille des fichiers pour trouver les doublons exacts et les gros fichiers. Les éléments dans le cloud peuvent attendre.';

  @override
  String get scanVerifyNow => 'Vérifier doublons et gros fichiers';

  @override
  String get scanBrowsePhotos => 'Trier les photos d’abord';

  @override
  String get scanSelectAll => 'Tout sélectionner dans cette catégorie';

  @override
  String get scanClearSelection => 'Effacer la sélection';

  @override
  String get scanKeepOneSelectOthers =>
      'Garder cette photo, sélectionner les autres';

  @override
  String get scanSelectOthersHint =>
      'Prévisualisez la photo conseillée à garder, puis sélectionnez le reste du groupe en une fois.';

  @override
  String get scanNotChecked => 'À vérifier';

  @override
  String scanPendingCheckCount(int count) {
    return '$count éléments à vérifier';
  }

  @override
  String get swipeGestureTitle => 'Tri rapide par glissement';

  @override
  String get swipeGestureDelete => 'Glisser à gauche pour marquer à supprimer';

  @override
  String get swipeGestureKeep => 'Glisser à droite pour garder';

  @override
  String get swipeGestureSafety =>
      'Les photos vont d’abord dans une liste de suppression. Elles ne sont supprimées qu’après avoir appuyé sur Terminer et confirmé.';

  @override
  String get swipeGestureHelp => 'Comment trier en glissant';

  @override
  String get homeSwipeDescription =>
      'Glissez d’une photo à l’autre pour trier plus vite qu’en touchant les vignettes.';
}
