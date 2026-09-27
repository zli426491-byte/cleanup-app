// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Intelligente Bereinigung';

  @override
  String get onboardingSmartSubtitle =>
      'Scanne Fotos und Videos, auf die du Zugriff erlaubst\nSieh sie dir an und entscheide, was du behältst oder löschst';

  @override
  String get onboardingPhotosTitle => 'Fotos organisieren';

  @override
  String get onboardingPhotosSubtitle =>
      'Vergleiche den Inhalt identischer und ähnlicher Fotos\nPrüfe jedes zum Behalten empfohlene Foto';

  @override
  String get onboardingSwipeTitle => 'Mit Wischen organisieren';

  @override
  String get onboardingSwipeSubtitle =>
      'Wische, um Fotos zu behalten oder zu löschen\nBestätige am Ende alle Entscheidungen';

  @override
  String get onboardingChoiceTitle => 'Du entscheidest';

  @override
  String get onboardingChoiceSubtitle =>
      'Scans und Fotovorschauen sind kostenlos\nLöschen und Videokomprimierung erfordern Pro. Originale werden nie automatisch gelöscht.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingPreparing => 'Vorbereitung…';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Schließen';

  @override
  String get paywallDescription =>
      'Schalte die Foto- und Videobereinigung frei. Sieh dir die Elemente an, bevor du sie zum Löschen auswählst.';

  @override
  String get paywallReloadPlans => 'Angebote neu laden';

  @override
  String get paywallNotConfigured => 'Abonnements nicht verfügbar';

  @override
  String get paywallContinue => 'Weiter';

  @override
  String get paywallStoreNotice =>
      'Käufe werden über den App Store abgewickelt. Verwalte oder kündige Abonnements in deinen Apple-ID-Einstellungen.';

  @override
  String get paywallRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get paywallPrivacyPolicy => 'Datenschutz';

  @override
  String get paywallTerms => 'Nutzungsbedingungen';

  @override
  String get paywallPurchaseIncomplete =>
      'Kauf nicht abgeschlossen. Versuche es später erneut.';

  @override
  String get paywallRestored => 'Pro-Zugriff wiederhergestellt.';

  @override
  String get paywallRestoreNotFound =>
      'Keine Käufe zum Wiederherstellen gefunden.';

  @override
  String get paywallWeeklyPlan => 'Wöchentliches Abo';

  @override
  String get paywallYearlyPlan => 'Jährliches Abo';

  @override
  String get paywallYearlySubtitle =>
      'Fotos und Videos das ganze Jahr organisieren';

  @override
  String get paywallWeeklySubtitle => 'Für eine kurze Fotobereinigung';

  @override
  String get paywallPhotoFeature =>
      'Identische und ähnliche Fotos gruppieren und einzeln prüfen';

  @override
  String get paywallVideoFeature =>
      'Videos komprimieren, ansehen und Kopien speichern';

  @override
  String get paywallSwipeFeature => 'Schnell mit Wischgesten organisieren';

  @override
  String get paywallPlansUnavailable =>
      'Abo-Angebote konnten nicht geladen werden. Prüfe deine Verbindung und lade sie erneut.';

  @override
  String get paywallBestValue => 'Bestes Angebot';

  @override
  String get videoTitle => 'Videokomprimierung';

  @override
  String get videoDescription =>
      'Die Komprimierung verringert die Qualität und erstellt eine Kopie. Prüfe Bild, Ton und Ausrichtung vor dem Speichern in Fotos. Das Original bleibt erhalten.';

  @override
  String get videoProRequired =>
      'Diese Funktion erfordert Pro. Kehre zur Bereinigungsseite zurück, um Angebote anzusehen.';

  @override
  String get videoSaving =>
      'Wird in Fotos gespeichert. Bitte warte, bis der Vorgang abgeschlossen ist.';

  @override
  String get videoCancelCompression => 'Komprimierung abbrechen';

  @override
  String get videoLoadingPreview => 'Videovorschau wird geladen…';

  @override
  String get videoCreatePreview => 'Komprimierte Vorschau erstellen';

  @override
  String get videoStorageNotice =>
      'Eine gespeicherte Kopie benötigt vorübergehend zusätzlichen Speicher. Lösche das Original und leere „Zuletzt gelöscht“. Den tatsächlich freien Speicher zeigt das System an.';

  @override
  String get videoViewOriginal => 'Original ansehen';

  @override
  String get videoViewCopy => 'Komprimierte Kopie ansehen';

  @override
  String get videoSaved =>
      'Die Kopie wurde in Fotos gespeichert. Das Original bleibt erhalten. Scanne auf der Startseite erneut und entscheide danach, ob du das Original löschst.';

  @override
  String get videoConfirmSave => 'Kopie bestätigen und in Fotos speichern';

  @override
  String get videoPreviewUnavailable =>
      'Die Vorschau kann nicht abgespielt werden. Versuche es erneut. Das Original bleibt erhalten.';

  @override
  String get videoPlaybackUnavailable =>
      'Das Video kann derzeit nicht abgespielt werden. Lade die Vorschau erneut.';

  @override
  String get videoOperationIncomplete =>
      'Der Vorgang wurde nicht abgeschlossen. Das Original bleibt erhalten. Prüfe den Fotozugriff und den freien Speicher und versuche es erneut.';

  @override
  String get videoPauseOriginal => 'Original: Pause';

  @override
  String get videoPlayOriginal => 'Original: Wiedergabe';

  @override
  String get videoPauseCopy => 'Komprimierte Kopie: Pause';

  @override
  String get videoPlayCopy => 'Komprimierte Kopie: Wiedergabe';

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
    return 'Video wird vorbereitet / komprimiert: $percent %';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Original: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Kopie: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Dateigrößenunterschied: $size';
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
      'Prüfe den Gerätespeicher in den iPhone-Einstellungen. Hier kannst du zugängliche Fotos und Videos organisieren.';

  @override
  String get homeViewIndexedPhotos => 'Bisher eingelesene Fotos ansehen';

  @override
  String get homeViewIndexedScreenshots =>
      'Bisher eingelesene Screenshots ansehen';

  @override
  String get homeCleanupTools => 'Bereinigungswerkzeuge';

  @override
  String get homeQuickActions => 'Schnellaktionen';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Erst ansehen, dann Fotos und Videos organisieren';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Belegt';

  @override
  String get homeUsedLegend => 'Belegt';

  @override
  String get homeAvailableLegend => 'Verfügbar';

  @override
  String get homeStartScanHint =>
      'Noch nicht gescannt. Tippe unten, um zu starten.';

  @override
  String get homeScanning => 'Wird gescannt…';

  @override
  String get homeDeleting => 'Wird gelöscht…';

  @override
  String get homeResumeScan => 'Scan fortsetzen und Fortschritt behalten';

  @override
  String get homeScanAll => 'Alle zugänglichen Fotos und Videos scannen';

  @override
  String get homePreviewOrganize => 'Ansehen und organisieren';

  @override
  String get homeVerifyOriginals =>
      'Lokale Originale auf exakte Duplikate und Dateigrößen prüfen';

  @override
  String get homeRetryPending =>
      'Scan fortsetzen / ausstehende Elemente erneut versuchen';

  @override
  String get homeExactDuplicates => 'Exakt identische Fotos';

  @override
  String get homeSimilarPhotos => 'Optisch ähnliche Fotos';

  @override
  String get homeNotScanned => 'Noch nicht gescannt';

  @override
  String get homePendingAnalysis => 'Visuelle Analyse ausstehend';

  @override
  String get homeNoneAnalyzed =>
      'Keine unter den analysierten Elementen gefunden';

  @override
  String get homeScreenshots => 'Screenshots';

  @override
  String get homeLargeFiles => 'Große Dateien';

  @override
  String get homeNoneFound => 'Keine gefunden';

  @override
  String get homePendingVerification => 'Originalprüfung ausstehend';

  @override
  String get homeNoneVerified => 'Keine unter den geprüften Elementen gefunden';

  @override
  String get homeNeedsReview => 'Prüfung erforderlich';

  @override
  String get homeCanReview => 'Prüfen';

  @override
  String get homeScanStatus => 'Scannen';

  @override
  String get homeDoneStatus => 'Fertig ✓';

  @override
  String get homePreviewPhotos => 'Fotos ansehen';

  @override
  String get homeChooseKeep => 'Auswählen, was du behältst';

  @override
  String get navHome => 'Start';

  @override
  String get navClean => 'Bereinigen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLoading => 'Wird geladen…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Kostenloser Tarif';

  @override
  String get settingsUpgrade => 'Auf Pro upgraden';

  @override
  String get settingsStorage => 'Speicher';

  @override
  String get settingsStorageTotal => 'Gesamt';

  @override
  String get settingsStorageUsed => 'Belegt';

  @override
  String get settingsStorageAvailable => 'Verfügbar';

  @override
  String get settingsGeneral => 'Allgemein';

  @override
  String get settingsProcessingSubscription => 'Abo wird verarbeitet…';

  @override
  String get settingsRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get settingsRestoredPro => 'Pro-Abo wiederhergestellt.';

  @override
  String get settingsPrivacyPolicy => 'Datenschutz';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsRateApp => 'App bewerten';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsChooseLanguage => 'Sprache auswählen';

  @override
  String get settingsSystemLanguage => 'Systemsprache verwenden';

  @override
  String homeUsedPercent(int percent) {
    return '$percent %';
  }

  @override
  String homeStorageTotal(String size) {
    return 'Gesamt $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return 'Eingelesen: $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '$count von $total zugänglichen Elementen eingelesen';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Visuell analysiert: $analyzed. Originale geprüft: $verified. Empfehlungen sind widerrufbar; du entscheidest, was du löschst.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos',
      one: '1 Foto',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos (Teilergebnisse)',
      one: '1 Foto (Teilergebnisse)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos geprüft; weitere ausstehend',
      one: '1 Foto geprüft; weitere ausstehend',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente geprüft; weitere ausstehend',
      one: '1 Element geprüft; weitere ausstehend',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Die Sprache konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get scanSmartTitle => 'Intelligente Bereinigung';

  @override
  String get scanCancelKeepProgress =>
      'Scan abbrechen und Fortschritt behalten';

  @override
  String get scanSwipeCleanup => 'Mit Wischen bereinigen';

  @override
  String get scanSortFileSize => 'Dateigröße';

  @override
  String get scanSortNewest => 'Neueste zuerst';

  @override
  String get scanStartAlbumTitle => 'Scan deiner Fotomediathek starten';

  @override
  String get scanIncompleteTitle => 'Scan unvollständig';

  @override
  String get scanStartAlbumDescription =>
      'Scanne alle zugänglichen Fotos und Videos. Die Prüfung der Originalinhalte und die visuelle Analyse helfen dir, sie vor deiner Entscheidung zu prüfen.';

  @override
  String get scanContinue => 'Scan fortsetzen';

  @override
  String get scanStart => 'Scan starten';

  @override
  String get scanPreviewWhileRunning =>
      'Du kannst Fotos und Screenshots ansehen. Auswahl, Löschen und Videokomprimierung sind während des Scans pausiert.';

  @override
  String get scanExactDescription =>
      'Exakte Duplikate umfassen nur Elemente mit geprüften Originalressourcen. Empfehlungen zum Behalten können verworfen werden.';

  @override
  String get scanSimilarDescription =>
      'Mögliche ähnliche Fotos erscheinen während der Analyse lokaler Vorschauen. Ihr Inhalt kann abweichen; Empfehlungen sind nur eine Orientierung.';

  @override
  String get scanLargeDescription =>
      'Nach geprüfter Ressourcengröße sortiert. Dateigröße und tatsächlich freigegebener Speicher können abweichen; der freigegebene Speicher wird vom System bestimmt.';

  @override
  String get scanManualDeleteDescription =>
      'Es werden nur Elemente gelöscht, die du manuell auswählst und bestätigst.';

  @override
  String get scanVerifyOriginals =>
      'Lokale Originale prüfen: exakte Duplikate und Größe';

  @override
  String get scanResumePending =>
      'Scan fortsetzen / ausstehende Elemente erneut versuchen';

  @override
  String get scanKeepReasonDefault =>
      'Dieses Foto wird in dieser Gruppe zum Behalten empfohlen.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Empfehlung zum Behalten erneut anzeigen';

  @override
  String get scanDismissKeepSuggestion => 'Empfehlung zum Behalten verwerfen';

  @override
  String get scanKeepManualHint =>
      'Empfehlungen wählen nie automatisch Elemente aus. Tippe auf ein Vorschaubild, um es zum Löschen zu markieren.';

  @override
  String get scanEmptyUnverified =>
      'Einige Originalressourcen müssen noch geprüft werden. Exakte Duplikate und große Dateien können noch nicht ermittelt werden. Fotos und Screenshots kannst du ansehen.';

  @override
  String get scanEmptyVisualPending =>
      'Einige Fotovorschauen müssen noch analysiert werden. Mögliche ähnliche Fotos erscheinen nach und nach; Fotos und Screenshots kannst du ansehen.';

  @override
  String get scanEmptyIndexing =>
      'Die Fotomediathek wird noch erfasst. Diese Kategorie wird währenddessen aktualisiert.';

  @override
  String get scanEmptyCategory =>
      'Keine Elemente in dieser Kategorie unter den bisher analysierten oder geprüften Elementen.';

  @override
  String get scanKeepBadge => 'Zum Behalten empfohlen';

  @override
  String get scanZoomPreview => 'Vorschau vergrößern';

  @override
  String get scanCompressVideo => 'Dieses Video komprimieren';

  @override
  String get scanContentPending => 'Inhaltsanalyse ausstehend';

  @override
  String get scanBackToCompare => 'Zurück zum Vergleich';

  @override
  String get scanConfirmDeleteTitle => 'Diese ausgewählten Elemente löschen?';

  @override
  String get scanCancel => 'Abbrechen';

  @override
  String get scanNoItemsDeleted =>
      'Es wurden keine Elemente gelöscht. Der Vorgang wurde möglicherweise abgebrochen oder ist fehlgeschlagen.';

  @override
  String get scanConfirmDelete => 'Löschen bestätigen';

  @override
  String get scanCategoryPhotos => 'Fotos';

  @override
  String get scanCategoryExact => 'Exakte Duplikate';

  @override
  String get scanCategorySimilar => 'Mögliche ähnliche Fotos';

  @override
  String get scanCategoryScreenshots => 'Screenshots';

  @override
  String get scanCategoryVideos => 'Videos';

  @override
  String get scanCategoryLarge => 'Große Dateien';

  @override
  String scanExactGroupCount(int count) {
    return 'Exakte Duplikate: $count Fotos';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Mögliche ähnliche Fotos: $count Fotos';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Zum Behalten empfohlen: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Ausgewählte Elemente: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '$count Elemente ansehen und löschen';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count Elemente ausgewählt. Prüfe deine Auswahl und die Empfehlungen vor dem Löschen. Das System bestimmt den freigegebenen Speicher.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Gelöschte Elemente: $count.';
  }

  @override
  String get scanIndexingTitle => 'Fotomediathek wird erfasst';

  @override
  String get scanVerifyingTitle =>
      'Originale werden auf exakte Duplikate geprüft';

  @override
  String get scanAnalyzingTitle => 'Lokale Fotovorschauen werden analysiert';

  @override
  String get scanSlowOperationHint =>
      'Dieser Vorgang dauert länger. Du kannst abbrechen, den Fortschritt behalten und später fortsetzen.';

  @override
  String get scanProgressPreviewHint =>
      'Erfasste Fotos und Screenshots kannst du ansehen. Ausstehende Downloads oder fehlgeschlagene Analysen gelten nie als exakte Duplikate.';

  @override
  String get scanCountConfirming => 'Wird geprüft';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '$indexed / $total Elemente erfasst';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Fotovorschauen verarbeitet: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Originalressourcen verarbeitet: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Visuelle Analysen abgeschlossen: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originale geprüft: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Downloads ausstehend: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'In dieser Phase noch nicht verarbeitet: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Wartezeit: $seconds Sekunden';
  }

  @override
  String get swipeKeep => 'Behalten';

  @override
  String get swipeDelete => 'Löschen';

  @override
  String get swipeReviewComplete => 'Prüfung abgeschlossen!';

  @override
  String get swipeRecoveredSpaceHint =>
      'Das System bestimmt den freigegebenen Speicher.';

  @override
  String get swipeUndoChoice => 'Letzte Auswahl rückgängig machen';

  @override
  String get swipeBack => 'Zurück';

  @override
  String get swipeConfirmDeleteTitle =>
      'Die zum Löschen markierten Fotos löschen?';

  @override
  String get swipeCancel => 'Abbrechen';

  @override
  String get swipeConfirmDelete => 'Löschen bestätigen';

  @override
  String get swipeNoPhotosDeleted =>
      'Es wurden keine Fotos gelöscht. Der Vorgang wurde möglicherweise abgebrochen oder ist fehlgeschlagen.';

  @override
  String get swipeExitTitle => 'Diese Prüfung verlassen?';

  @override
  String get swipeContinueReview => 'Prüfung fortsetzen';

  @override
  String get swipeLeave => 'Verlassen';

  @override
  String get swipeSkipRemainingTitle => 'Verbleibende Fotos überspringen?';

  @override
  String get swipeDone => 'Fertig';

  @override
  String swipeDoneCount(int count) {
    return 'Fertig ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Löschen: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Behalten: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount Fotos löschen · $keepCount Fotos behalten';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '$count Fotos löschen';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Lösche $count geprüfte Fotos. Stelle sicher, dass die zu behaltenden Elemente richtig ausgewählt sind.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '$count Fotos gelöscht. Die übrigen Fotos wurden nicht gelöscht.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Du hast $count Fotos zum Löschen markiert. Beim Verlassen werden sie nicht gelöscht.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '$remaining Fotos sind noch nicht geprüft. Die Prüfung beenden und die $deleteCount bereits zum Löschen markierten Fotos bestätigen?';
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
  String get assetReloadPreview => 'Vorschau neu laden';

  @override
  String get assetSizeUnknown => 'Größe nicht verfügbar';

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
    return '$count Byte';
  }

  @override
  String get appName => 'Cleanup Master';

  @override
  String get nativePhotoRead =>
      'Greife auf die von dir erlaubten Fotos und Videos zu, um sie anzusehen, zu organisieren und zu bestätigen, was gelöscht werden soll.';

  @override
  String get nativePhotoAdd =>
      'Speichere nach deiner Bestätigung eine komprimierte Videokopie in Fotos. Das Original bleibt erhalten.';

  @override
  String get nativeContacts =>
      'Greife auf deine Kontakte zu, um doppelte Kontaktdaten zu organisieren.';

  @override
  String get nativeTracking =>
      'Erlaube Tracking, um dein Erlebnis zu personalisieren und den Dienst zu verbessern.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Abonnements sind derzeit nicht verfügbar. Versuche es später erneut.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Keine Verbindung zum Abo-Dienst möglich. Versuche es später erneut.';

  @override
  String get serviceNoPlans =>
      'Derzeit sind keine Abo-Angebote verfügbar. Versuche es später erneut.';

  @override
  String get servicePlansLoadFailed =>
      'Angebote konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get servicePurchaseUnavailable =>
      'Käufe sind derzeit nicht verfügbar. Versuche es später erneut.';

  @override
  String get servicePurchaseFailed =>
      'Kauf nicht abgeschlossen. Versuche es später erneut.';

  @override
  String get serviceRestoreUnavailable =>
      'Käufe können derzeit nicht wiederhergestellt werden. Versuche es später erneut.';

  @override
  String get serviceNoSubscription => 'Kein aktives Pro-Abo gefunden.';

  @override
  String get serviceRestoreFailed =>
      'Käufe konnten nicht wiederhergestellt werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get servicePurchaseCancelled => 'Kauf abgebrochen.';

  @override
  String get serviceScanPaused =>
      'Pausiert. Eingelesene und analysierte Ergebnisse bleiben erhalten. Du kannst den Scan fortsetzen.';

  @override
  String get serviceLimitedLibrary =>
      'Es werden nur die von dir erlaubten Fotos berücksichtigt, nicht deine gesamte Mediathek.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'Die Analyse von Originaldateien ist auf diesem Gerät nicht verfügbar. Größen und exakte Duplikate sind ungeprüft.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Prüfe lokale Originale, um Größen und exakte Duplikate zu bestätigen. Große oder Cloud-Elemente können ausstehend bleiben; ungeprüfte Größen werden nicht geschätzt.';

  @override
  String get serviceReadingIndex => 'Mediathekindex wird eingelesen';

  @override
  String get servicePhotoPermission =>
      'Fotozugriff ist nicht erlaubt. Erlaube den Zugriff in den Einstellungen und versuche es erneut.';

  @override
  String get serviceOriginalRoundLimit =>
      'Diese Prüfrunde hat 60 Sekunden erreicht. Ergebnisse bleiben erhalten; prüfe erneut, um unversuchte Elemente zuerst zu verarbeiten.';

  @override
  String get servicePreviewRoundLimit =>
      'Diese Vorschaurunde hat 30 Sekunden erreicht. Ergebnisse bleiben erhalten; fahre fort, um unversuchte Fotos zuerst zu verarbeiten.';

  @override
  String get serviceReadTimeout =>
      'Einige Lesevorgänge haben das Zeitlimit erreicht. Die bisherigen Ergebnisse bleiben erhalten; du kannst den Scan fortsetzen.';

  @override
  String get serviceReadInterrupted =>
      'Einige Lesevorgänge der Mediathek wurden unterbrochen. Die bisherigen Ergebnisse bleiben erhalten; du kannst den Scan fortsetzen.';

  @override
  String get serviceVerifyingOriginals => 'Lokale Originale werden geprüft';

  @override
  String get serviceGroupingSimilar =>
      'Optisch ähnliche Fotos werden gruppiert';

  @override
  String get serviceQualityLowDetail =>
      'Die Vorschau enthält zu wenig Details für eine Qualitätsempfehlung';

  @override
  String get serviceQualityDecodeFailed =>
      'Die Vorschau konnte nicht dekodiert werden; die Qualität wurde nicht bewertet';

  @override
  String get serviceQualityLowInformation =>
      'Zu wenig Bildinformationen für eine Qualitätsempfehlung';

  @override
  String get serviceQualityClearEdges => 'Schärfere Kanten in der Vorschau';

  @override
  String get serviceQualityLessDetail =>
      'Weniger Kantendetails in der Vorschau';

  @override
  String get serviceQualityDark => 'Das Bild wirkt dunkel';

  @override
  String get serviceQualityBright => 'Das Bild wirkt hell';

  @override
  String get serviceQualityBalanced => 'Ausgewogene Gesamthelligkeit';

  @override
  String get serviceKeepExact =>
      'Originale und bearbeitete Ressourcen stimmen exakt überein. Diese Kopie wird zum Behalten empfohlen.';

  @override
  String get serviceKeepHigherResolution =>
      'Höhere Auflösung in dieser Gruppe. Zum Behalten empfohlen; prüfe den Bildinhalt.';

  @override
  String get serviceVideoMissing => 'Video nicht gefunden. Scanne erneut.';

  @override
  String get serviceVideoCloud =>
      'Das Video ist in iCloud. Lade das Original in Fotos herunter und versuche es erneut.';

  @override
  String get serviceVideoUnreadable =>
      'Dieses Video kann nicht gelesen werden.';

  @override
  String get serviceVideoPreviousBusy =>
      'Die vorherige Komprimierung wird noch beendet. Versuche es gleich erneut.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Temporärer Videospeicher konnte nicht vorbereitet werden.';

  @override
  String get serviceVideoUnsupported =>
      'Videokomprimierung ist auf diesem Gerät nicht verfügbar.';

  @override
  String get serviceVideoOutputInvalid =>
      'Der Ausgabeort ist ungültig. Das Original bleibt erhalten.';

  @override
  String get serviceVideoSaveUnknown =>
      'Die gespeicherte Kopie konnte nicht bestätigt werden. Prüfe Fotos, bevor du es erneut versuchst.';

  @override
  String get serviceVideoCancelled => 'Komprimierung abgebrochen.';

  @override
  String get serviceVideoOperationBusy =>
      'Beende zuerst den aktuellen Videovorgang.';

  @override
  String get serviceVideoEmpty =>
      'Das Original ist leer und kann nicht komprimiert werden.';

  @override
  String get serviceVideoEncodeFailed =>
      'Die Komprimierung wurde nicht abgeschlossen. Das Original bleibt erhalten.';

  @override
  String get serviceVideoNoCopy =>
      'Die Komprimierung hat keine separate Kopie erstellt. Das Original bleibt erhalten.';

  @override
  String get serviceVideoNotSmaller =>
      'Das komprimierte Video ist nicht kleiner. Das Original bleibt erhalten.';

  @override
  String get serviceVideoDurationMismatch =>
      'Die Dauer des komprimierten Videos stimmt nicht überein. Das Original bleibt erhalten.';

  @override
  String get serviceVideoValidationFailed =>
      'Das Video konnte nicht geprüft werden. Das Original bleibt erhalten.';

  @override
  String get serviceVideoPreviewFirst =>
      'Schließe die Komprimierung ab und prüfe zuerst die Vorschau.';

  @override
  String get serviceVideoSaveFailed =>
      'Die Kopie konnte nicht gespeichert werden. Das Original bleibt erhalten. Versuche es erneut.';

  @override
  String get serviceVideoGenericFailed =>
      'Vorgang nicht abgeschlossen. Das Original bleibt erhalten. Prüfe Fotozugriff und freien Speicher und versuche es erneut.';

  @override
  String get serviceOperationFailed =>
      'Dieser Vorgang konnte nicht abgeschlossen werden. Versuche es erneut.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '$read / $total zugängliche Elemente eingelesen.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count Fotos benötigen noch eine visuelle Analyse. Fahre fort, um unversuchte Fotos zuerst zu verarbeiten. Cloud-Originale werden nicht automatisch heruntergeladen.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Lokale Vorschauen werden gelesen ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Lokale Vorschauen werden analysiert ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; nur als Orientierung';
  }

  @override
  String get scanSwipeIntro =>
      'Nach links wischen zum Vormerken zum Löschen, nach rechts zum Behalten. Gelöscht wird erst nach Bestätigung.';

  @override
  String get scanSwipeStart => 'Fotos per Wischen sortieren';

  @override
  String get scanDetails => 'Scan-Details';

  @override
  String get scanVerificationNeeded => 'Originaldateien noch nicht geprüft';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '$verified / $total Elemente geprüft';
  }

  @override
  String get scanVerificationExplanation =>
      'Prüfe zuerst Inhalt und Größe der Dateien, um exakte Duplikate und große Dateien zu finden. Cloud-Inhalte können warten.';

  @override
  String get scanVerifyNow => 'Duplikate und große Dateien prüfen';

  @override
  String get scanBrowsePhotos => 'Zuerst Fotos sortieren';

  @override
  String get scanSelectAll => 'Alles in dieser Kategorie auswählen';

  @override
  String get scanClearSelection => 'Auswahl aufheben';

  @override
  String get scanKeepOneSelectOthers =>
      'Dieses Foto behalten, andere auswählen';

  @override
  String get scanSelectOthersHint =>
      'Sieh dir das zum Behalten empfohlene Foto an und wähle dann den Rest der Gruppe auf einmal aus.';

  @override
  String get scanNotChecked => 'Noch zu prüfen';

  @override
  String scanPendingCheckCount(int count) {
    return '$count Elemente noch zu prüfen';
  }

  @override
  String get swipeGestureTitle => 'Schnell per Wischen sortieren';

  @override
  String get swipeGestureDelete => 'Nach links zum Löschen vormerken';

  @override
  String get swipeGestureKeep => 'Nach rechts zum Behalten wischen';

  @override
  String get swipeGestureSafety =>
      'Fotos kommen zuerst auf eine Löschliste. Erst nach „Fertig“ und deiner Bestätigung werden sie gelöscht.';

  @override
  String get swipeGestureHelp => 'So sortierst du per Wischen';

  @override
  String get homeSwipeDescription =>
      'Wische Foto für Foto nach links oder rechts – schneller als das Antippen von Vorschaubildern.';

  @override
  String get scanCheckExactPhotos => 'Exakte Duplikate prüfen';

  @override
  String get scanCheckFileSizes => 'Größe großer Dateien prüfen';
}
