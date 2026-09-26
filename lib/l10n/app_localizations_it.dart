// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Pulizia intelligente';

  @override
  String get onboardingSmartSubtitle =>
      'Analizza le foto e i video a cui consenti l’accesso\nGuarda l’anteprima, poi scegli cosa tenere o eliminare';

  @override
  String get onboardingPhotosTitle => 'Organizza le foto';

  @override
  String get onboardingPhotosSubtitle =>
      'Confronta il contenuto di foto duplicate e simili\nControlla ogni foto consigliata da tenere';

  @override
  String get onboardingSwipeTitle => 'Scorri per organizzare';

  @override
  String get onboardingSwipeSubtitle =>
      'Scorri per scegliere cosa tenere o eliminare\nConferma tutte le scelte alla fine';

  @override
  String get onboardingChoiceTitle => 'Decidi tu';

  @override
  String get onboardingChoiceSubtitle =>
      'L’analisi e le anteprime delle foto sono gratuite\nEliminazione e compressione video richiedono Pro. Gli originali non vengono mai eliminati automaticamente.';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingPreparing => 'Preparazione…';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String get onboardingGetStarted => 'Inizia';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Chiudi';

  @override
  String get paywallDescription =>
      'Sblocca la pulizia di foto e video. Guarda l’anteprima prima di scegliere cosa eliminare.';

  @override
  String get paywallReloadPlans => 'Ricarica i piani';

  @override
  String get paywallNotConfigured => 'Abbonamenti non disponibili';

  @override
  String get paywallContinue => 'Continua';

  @override
  String get paywallStoreNotice =>
      'Gli acquisti vengono effettuati tramite l’App Store. Gestisci o annulla gli abbonamenti nelle impostazioni del tuo Apple ID.';

  @override
  String get paywallRestorePurchases => 'Ripristina acquisti';

  @override
  String get paywallPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get paywallTerms => 'Termini di utilizzo';

  @override
  String get paywallPurchaseIncomplete =>
      'Acquisto non completato. Riprova più tardi.';

  @override
  String get paywallRestored => 'Accesso Pro ripristinato.';

  @override
  String get paywallRestoreNotFound => 'Nessun acquisto da ripristinare.';

  @override
  String get paywallWeeklyPlan => 'Abbonamento settimanale';

  @override
  String get paywallYearlyPlan => 'Abbonamento annuale';

  @override
  String get paywallYearlySubtitle => 'Organizza foto e video tutto l’anno';

  @override
  String get paywallWeeklySubtitle =>
      'Per una breve sessione di pulizia delle foto';

  @override
  String get paywallPhotoFeature =>
      'Raggruppa foto duplicate e simili, poi controlla ogni elemento';

  @override
  String get paywallVideoFeature => 'Comprimi i video, guardali e salva copie';

  @override
  String get paywallSwipeFeature =>
      'Organizza rapidamente con gesti di scorrimento';

  @override
  String get paywallPlansUnavailable =>
      'Impossibile caricare i piani. Controlla la connessione e ricarica.';

  @override
  String get paywallBestValue => 'Più conveniente';

  @override
  String get videoTitle => 'Compressione video';

  @override
  String get videoDescription =>
      'La compressione riduce la qualità e crea una copia. Controlla immagine, audio e orientamento prima di salvare in Foto. L’originale viene conservato.';

  @override
  String get videoProRequired =>
      'Questa funzione richiede Pro. Torna alla pagina di pulizia per vedere i piani.';

  @override
  String get videoSaving => 'Salvataggio in Foto. Attendi il completamento.';

  @override
  String get videoCancelCompression => 'Annulla compressione';

  @override
  String get videoLoadingPreview => 'Caricamento anteprima video…';

  @override
  String get videoCreatePreview => 'Crea un’anteprima compressa';

  @override
  String get videoStorageNotice =>
      'Salvare una copia occupa temporaneamente più spazio. Dopo aver eliminato l’originale e svuotato “Eliminati di recente”, controlla lo spazio disponibile nel sistema.';

  @override
  String get videoViewOriginal => 'Vedi originale';

  @override
  String get videoViewCopy => 'Vedi copia compressa';

  @override
  String get videoSaved =>
      'La copia è stata salvata in Foto e l’originale conservato. Ripeti l’analisi dalla pagina iniziale, poi scegli se eliminare l’originale.';

  @override
  String get videoConfirmSave => 'Conferma la copia e salva in Foto';

  @override
  String get videoPreviewUnavailable =>
      'Impossibile riprodurre l’anteprima. Riprova. L’originale è conservato.';

  @override
  String get videoPlaybackUnavailable =>
      'Il video non può essere riprodotto ora. Ricarica l’anteprima.';

  @override
  String get videoOperationIncomplete =>
      'Operazione non completata. L’originale è conservato. Controlla l’accesso a Foto e lo spazio disponibile, poi riprova.';

  @override
  String get videoPauseOriginal => 'Originale: pausa';

  @override
  String get videoPlayOriginal => 'Originale: riproduci';

  @override
  String get videoPauseCopy => 'Copia compressa: pausa';

  @override
  String get videoPlayCopy => 'Copia compressa: riproduci';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Versione $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Preparazione / compressione video $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Originale: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Copia: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Differenza di dimensione: $size';
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
      'Controlla lo spazio nelle impostazioni dell’iPhone. Qui puoi organizzare le foto e i video accessibili.';

  @override
  String get homeViewIndexedPhotos => 'Vedi le foto già lette';

  @override
  String get homeViewIndexedScreenshots => 'Vedi gli screenshot già letti';

  @override
  String get homeCleanupTools => 'Strumenti di pulizia';

  @override
  String get homeQuickActions => 'Azioni rapide';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Guarda l’anteprima, poi organizza foto e video';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Utilizzato';

  @override
  String get homeUsedLegend => 'Utilizzato';

  @override
  String get homeAvailableLegend => 'Disponibile';

  @override
  String get homeStartScanHint =>
      'Non ancora analizzato. Tocca sotto per iniziare.';

  @override
  String get homeScanning => 'Analisi…';

  @override
  String get homeDeleting => 'Eliminazione…';

  @override
  String get homeResumeScan => 'Continua l’analisi mantenendo i progressi';

  @override
  String get homeScanAll => 'Analizza tutte le foto e i video accessibili';

  @override
  String get homePreviewOrganize => 'Anteprima e organizzazione';

  @override
  String get homeVerifyOriginals =>
      'Verifica gli originali locali per duplicati esatti e dimensioni';

  @override
  String get homeRetryPending =>
      'Continua l’analisi / riprova gli elementi in attesa';

  @override
  String get homeExactDuplicates => 'Foto duplicate esatte';

  @override
  String get homeSimilarPhotos => 'Foto visivamente simili';

  @override
  String get homeNotScanned => 'Non ancora analizzato';

  @override
  String get homePendingAnalysis => 'Analisi visiva in attesa';

  @override
  String get homeNoneAnalyzed => 'Nessun risultato tra gli elementi analizzati';

  @override
  String get homeScreenshots => 'Screenshot';

  @override
  String get homeLargeFiles => 'File di grandi dimensioni';

  @override
  String get homeNoneFound => 'Nessun risultato';

  @override
  String get homePendingVerification => 'Verifica originali in attesa';

  @override
  String get homeNoneVerified => 'Nessun risultato tra gli elementi verificati';

  @override
  String get homeNeedsReview => 'Da controllare';

  @override
  String get homeCanReview => 'Controlla';

  @override
  String get homeScanStatus => 'Analizza';

  @override
  String get homeDoneStatus => 'Completato ✓';

  @override
  String get homePreviewPhotos => 'Anteprima foto';

  @override
  String get homeChooseKeep => 'Scegli cosa tenere';

  @override
  String get navHome => 'Inizio';

  @override
  String get navClean => 'Pulisci';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLoading => 'Caricamento…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Piano gratuito';

  @override
  String get settingsUpgrade => 'Passa a Pro';

  @override
  String get settingsStorage => 'Spazio';

  @override
  String get settingsStorageTotal => 'Totale';

  @override
  String get settingsStorageUsed => 'Utilizzato';

  @override
  String get settingsStorageAvailable => 'Disponibile';

  @override
  String get settingsGeneral => 'Generali';

  @override
  String get settingsProcessingSubscription => 'Elaborazione abbonamento…';

  @override
  String get settingsRestorePurchases => 'Ripristina acquisti';

  @override
  String get settingsRestoredPro => 'Abbonamento Pro ripristinato.';

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsTerms => 'Termini di utilizzo';

  @override
  String get settingsRateApp => 'Valutaci';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsChooseLanguage => 'Scegli la lingua';

  @override
  String get settingsSystemLanguage => 'Usa la lingua di sistema';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return 'Totale $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return 'Letti: $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Letti $count di $total elementi accessibili';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Analisi visive: $analyzed. Originali verificati: $verified. I consigli sono reversibili; decidi tu cosa eliminare.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto (risultati parziali)',
      one: '1 foto (risultati parziali)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto verificate; altre in attesa',
      one: '1 foto verificata; altre in attesa',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi verificati; altri in attesa',
      one: '1 elemento verificato; altri in attesa',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Impossibile salvare la lingua. Riprova.';

  @override
  String get scanSmartTitle => 'Pulizia intelligente';

  @override
  String get scanCancelKeepProgress =>
      'Annulla l’analisi e mantieni i progressi';

  @override
  String get scanSwipeCleanup => 'Pulizia con scorrimento';

  @override
  String get scanSortFileSize => 'Dimensione file';

  @override
  String get scanSortNewest => 'Più recenti';

  @override
  String get scanStartAlbumTitle => 'Inizia l’analisi della libreria';

  @override
  String get scanIncompleteTitle => 'Analisi incompleta';

  @override
  String get scanStartAlbumDescription =>
      'Analizza tutte le foto e i video accessibili. La verifica degli originali e l’analisi visiva ti aiutano a controllarli prima di decidere.';

  @override
  String get scanContinue => 'Continua l’analisi';

  @override
  String get scanStart => 'Avvia analisi';

  @override
  String get scanPreviewWhileRunning =>
      'Puoi vedere foto e screenshot. Durante l’analisi, selezione, eliminazione e compressione video sono sospese.';

  @override
  String get scanExactDescription =>
      'I duplicati esatti includono solo elementi con risorse originali verificate. Puoi ignorare i consigli su cosa tenere.';

  @override
  String get scanSimilarDescription =>
      'I possibili simili appaiono durante l’analisi delle anteprime locali. Il contenuto può differire; i consigli sono solo una guida.';

  @override
  String get scanLargeDescription =>
      'Ordinati per dimensione verificata delle risorse. La dimensione e lo spazio realmente liberato possono differire; lo spazio recuperato è determinato dal sistema.';

  @override
  String get scanManualDeleteDescription =>
      'Verranno eliminati solo gli elementi selezionati e confermati manualmente.';

  @override
  String get scanVerifyOriginals =>
      'Verifica originali locali: duplicati esatti e dimensioni';

  @override
  String get scanResumePending =>
      'Continua l’analisi / riprova gli elementi in attesa';

  @override
  String get scanKeepReasonDefault =>
      'Questa foto è suggerita da tenere in questo gruppo.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Mostra di nuovo il consiglio su cosa tenere';

  @override
  String get scanDismissKeepSuggestion => 'Ignora il consiglio su cosa tenere';

  @override
  String get scanKeepManualHint =>
      'I consigli non selezionano mai elementi automaticamente. Tocca una miniatura per segnarla da eliminare.';

  @override
  String get scanEmptyUnverified =>
      'Alcune risorse originali devono ancora essere verificate. Non è ancora possibile determinare duplicati esatti e file grandi. Puoi vedere foto e screenshot.';

  @override
  String get scanEmptyVisualPending =>
      'Alcune anteprime devono ancora essere analizzate. I possibili simili appariranno progressivamente; puoi vedere foto e screenshot.';

  @override
  String get scanEmptyIndexing =>
      'La libreria è ancora in fase di indicizzazione. Questa categoria si aggiornerà man mano.';

  @override
  String get scanEmptyCategory =>
      'Nessun elemento in questa categoria tra quelli già analizzati o verificati.';

  @override
  String get scanKeepBadge => 'Consigliata da tenere';

  @override
  String get scanZoomPreview => 'Ingrandisci anteprima';

  @override
  String get scanCompressVideo => 'Comprimi questo video';

  @override
  String get scanContentPending => 'Analisi contenuto in attesa';

  @override
  String get scanBackToCompare => 'Torna al confronto';

  @override
  String get scanConfirmDeleteTitle => 'Eliminare gli elementi selezionati?';

  @override
  String get scanCancel => 'Annulla';

  @override
  String get scanNoItemsDeleted =>
      'Nessun elemento eliminato. L’operazione potrebbe essere stata annullata o non riuscita.';

  @override
  String get scanConfirmDelete => 'Conferma eliminazione';

  @override
  String get scanCategoryPhotos => 'Foto';

  @override
  String get scanCategoryExact => 'Duplicati esatti';

  @override
  String get scanCategorySimilar => 'Possibili simili';

  @override
  String get scanCategoryScreenshots => 'Screenshot';

  @override
  String get scanCategoryVideos => 'Video';

  @override
  String get scanCategoryLarge => 'File grandi';

  @override
  String scanExactGroupCount(int count) {
    return 'Duplicati esatti: $count foto';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Possibili simili: $count foto';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Consigliata da tenere: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Elementi selezionati: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Vedi ed elimina $count elementi';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count elementi selezionati. Controlla la selezione e i consigli prima di eliminare. Lo spazio recuperato è determinato dal sistema.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Elementi eliminati: $count.';
  }

  @override
  String get scanIndexingTitle => 'Indicizzazione della libreria';

  @override
  String get scanVerifyingTitle => 'Verifica originali per duplicati esatti';

  @override
  String get scanAnalyzingTitle => 'Analisi delle anteprime locali';

  @override
  String get scanSlowOperationHint =>
      'Questa operazione richiede più tempo. Puoi annullare, conservare i progressi e continuare più tardi.';

  @override
  String get scanProgressPreviewHint =>
      'Puoi vedere foto e screenshot indicizzati. Download in attesa e analisi non riuscite non vengono mai trattati come duplicati esatti.';

  @override
  String get scanCountConfirming => 'Verifica';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '$indexed / $total elementi indicizzati';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Anteprime elaborate: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Risorse originali elaborate: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Analisi visive completate: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originali verificati: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Download in attesa: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Non ancora elaborati in questa fase: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Attesa: $seconds secondi';
  }

  @override
  String get swipeKeep => 'Tieni';

  @override
  String get swipeDelete => 'Elimina';

  @override
  String get swipeReviewComplete => 'Revisione completata!';

  @override
  String get swipeRecoveredSpaceHint =>
      'Lo spazio recuperato è determinato dal sistema.';

  @override
  String get swipeUndoChoice => 'Annulla l’ultima scelta';

  @override
  String get swipeBack => 'Indietro';

  @override
  String get swipeConfirmDeleteTitle =>
      'Eliminare le foto segnate per l’eliminazione?';

  @override
  String get swipeCancel => 'Annulla';

  @override
  String get swipeConfirmDelete => 'Conferma eliminazione';

  @override
  String get swipeNoPhotosDeleted =>
      'Nessuna foto eliminata. L’operazione potrebbe essere stata annullata o non riuscita.';

  @override
  String get swipeExitTitle => 'Uscire dalla revisione?';

  @override
  String get swipeContinueReview => 'Continua la revisione';

  @override
  String get swipeLeave => 'Esci';

  @override
  String get swipeSkipRemainingTitle => 'Saltare le foto rimanenti?';

  @override
  String get swipeDone => 'Fine';

  @override
  String swipeDoneCount(int count) {
    return 'Fine ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Da eliminare: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Da tenere: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount foto da eliminare · $keepCount foto da tenere';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Elimina $count foto';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Elimina $count foto controllate. Assicurati di aver selezionato correttamente gli elementi da tenere.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '$count foto eliminate. Le foto rimanenti non sono state eliminate.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Hai segnato $count foto da eliminare. Uscendo non verranno eliminate.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '$remaining foto non sono state controllate. Terminare la revisione e confermare le $deleteCount foto già segnate da eliminare?';
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
  String get assetReloadPreview => 'Ricarica anteprima';

  @override
  String get assetSizeUnknown => 'Dimensione non disponibile';

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
    return '$count byte';
  }

  @override
  String get appName => 'Cleanup Master';

  @override
  String get nativePhotoRead =>
      'Accedi alle foto e ai video consentiti per vederli, organizzarli e confermare cosa eliminare.';

  @override
  String get nativePhotoAdd =>
      'Salva una copia video compressa in Foto dopo la conferma. L’originale è conservato.';

  @override
  String get nativeContacts =>
      'Accedi ai contatti per organizzare i dati duplicati.';

  @override
  String get nativeTracking =>
      'Consenti il tracciamento per personalizzare l’esperienza e migliorare il servizio.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Gli abbonamenti non sono disponibili al momento. Riprova più tardi.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Impossibile connettersi al servizio abbonamenti. Riprova più tardi.';

  @override
  String get serviceNoPlans =>
      'Nessun piano di abbonamento disponibile al momento. Riprova più tardi.';

  @override
  String get servicePlansLoadFailed =>
      'Impossibile caricare i piani. Controlla la connessione e riprova.';

  @override
  String get servicePurchaseUnavailable =>
      'Gli acquisti non sono disponibili al momento. Riprova più tardi.';

  @override
  String get servicePurchaseFailed =>
      'Acquisto non completato. Riprova più tardi.';

  @override
  String get serviceRestoreUnavailable =>
      'Il ripristino acquisti non è disponibile al momento. Riprova più tardi.';

  @override
  String get serviceNoSubscription => 'Nessun abbonamento Pro attivo trovato.';

  @override
  String get serviceRestoreFailed =>
      'Impossibile ripristinare gli acquisti. Controlla la connessione e riprova.';

  @override
  String get servicePurchaseCancelled => 'Acquisto annullato.';

  @override
  String get serviceScanPaused =>
      'In pausa. I risultati letti e analizzati sono conservati. Puoi continuare l’analisi.';

  @override
  String get serviceLimitedLibrary =>
      'Sono incluse solo le foto consentite, non l’intera libreria.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'L’analisi dei file originali non è disponibile su questo dispositivo. Dimensioni e duplicati esatti non sono verificati.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Verifica gli originali locali per confermare dimensioni e duplicati esatti. Elementi grandi o nel cloud possono restare in attesa; le dimensioni non verificate non vengono stimate.';

  @override
  String get serviceReadingIndex => 'Lettura dell’indice della libreria';

  @override
  String get servicePhotoPermission =>
      'L’accesso alle foto non è consentito. Autorizzalo nelle impostazioni e riprova.';

  @override
  String get serviceOriginalRoundLimit =>
      'Questa verifica ha raggiunto 60 secondi. I risultati sono conservati; ripeti la verifica per elaborare prima gli elementi non ancora tentati.';

  @override
  String get servicePreviewRoundLimit =>
      'Questa analisi delle anteprime ha raggiunto 30 secondi. I risultati sono conservati; continua per elaborare prima le foto non ancora tentate.';

  @override
  String get serviceReadTimeout =>
      'Alcune letture hanno superato il tempo limite. I risultati attuali sono conservati; puoi continuare l’analisi.';

  @override
  String get serviceReadInterrupted =>
      'Alcune letture della libreria sono state interrotte. I risultati attuali sono conservati; puoi continuare l’analisi.';

  @override
  String get serviceVerifyingOriginals => 'Verifica degli originali locali';

  @override
  String get serviceGroupingSimilar => 'Raggruppamento dei possibili simili';

  @override
  String get serviceQualityLowDetail =>
      'L’anteprima ha troppo pochi dettagli per un consiglio sulla qualità';

  @override
  String get serviceQualityDecodeFailed =>
      'Impossibile decodificare l’anteprima; qualità non valutata';

  @override
  String get serviceQualityLowInformation =>
      'Informazioni sull’immagine insufficienti per un consiglio sulla qualità';

  @override
  String get serviceQualityClearEdges => 'Bordi più nitidi nell’anteprima';

  @override
  String get serviceQualityLessDetail =>
      'Bordi meno dettagliati nell’anteprima';

  @override
  String get serviceQualityDark => 'L’immagine appare scura';

  @override
  String get serviceQualityBright => 'L’immagine appare chiara';

  @override
  String get serviceQualityBalanced => 'Luminosità complessiva equilibrata';

  @override
  String get serviceKeepExact =>
      'Le risorse originali e modificate coincidono esattamente. Copia consigliata da tenere.';

  @override
  String get serviceKeepHigherResolution =>
      'Risoluzione più alta in questo gruppo. Consigliata da tenere; controlla il contenuto della foto.';

  @override
  String get serviceVideoMissing => 'Video non trovato. Ripeti l’analisi.';

  @override
  String get serviceVideoCloud =>
      'Il video è in iCloud. Scarica l’originale in Foto e riprova.';

  @override
  String get serviceVideoUnreadable => 'Impossibile leggere questo video.';

  @override
  String get serviceVideoPreviousBusy =>
      'La compressione precedente sta ancora terminando. Riprova tra poco.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Impossibile preparare lo spazio temporaneo per il video.';

  @override
  String get serviceVideoUnsupported =>
      'La compressione video non è disponibile su questo dispositivo.';

  @override
  String get serviceVideoOutputInvalid =>
      'La destinazione non è valida. L’originale è conservato.';

  @override
  String get serviceVideoSaveUnknown =>
      'Impossibile confermare la copia salvata. Controlla Foto prima di riprovare.';

  @override
  String get serviceVideoCancelled => 'Compressione annullata.';

  @override
  String get serviceVideoOperationBusy =>
      'Completa prima l’operazione video in corso.';

  @override
  String get serviceVideoEmpty =>
      'L’originale è vuoto e non può essere compresso.';

  @override
  String get serviceVideoEncodeFailed =>
      'Compressione non completata. L’originale è conservato.';

  @override
  String get serviceVideoNoCopy =>
      'La compressione non ha creato una copia separata. L’originale è conservato.';

  @override
  String get serviceVideoNotSmaller =>
      'Il video compresso non è più piccolo. L’originale è conservato.';

  @override
  String get serviceVideoDurationMismatch =>
      'La durata del video compresso non corrisponde. L’originale è conservato.';

  @override
  String get serviceVideoValidationFailed =>
      'Impossibile verificare il video. L’originale è conservato.';

  @override
  String get serviceVideoPreviewFirst =>
      'Completa la compressione e controlla prima l’anteprima.';

  @override
  String get serviceVideoSaveFailed =>
      'Impossibile salvare la copia. L’originale è conservato. Riprova.';

  @override
  String get serviceVideoGenericFailed =>
      'Operazione non completata. L’originale è conservato. Controlla l’accesso alle foto e lo spazio libero, poi riprova.';

  @override
  String get serviceOperationFailed =>
      'Impossibile completare l’operazione. Riprova.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Letti $read / $total elementi accessibili.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count foto richiedono ancora l’analisi visiva. Continua per elaborare prima le foto non ancora tentate. Gli originali nel cloud non vengono scaricati automaticamente.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Lettura anteprime locali ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Analisi anteprime locali ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; indicazioni solo orientative';
  }
}
