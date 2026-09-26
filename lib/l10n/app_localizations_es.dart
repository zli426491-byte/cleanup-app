// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Limpieza inteligente';

  @override
  String get onboardingSmartSubtitle =>
      'Analiza las fotos y vídeos a los que permites acceso\nRevísalos y elige qué conservar o eliminar';

  @override
  String get onboardingPhotosTitle => 'Organizar fotos';

  @override
  String get onboardingPhotosSubtitle =>
      'Compara el contenido de las fotos duplicadas y similares\nRevisa cada foto recomendada para conservar';

  @override
  String get onboardingSwipeTitle => 'Deslizar para organizar';

  @override
  String get onboardingSwipeSubtitle =>
      'Desliza para elegir qué conservar o eliminar\nConfirma todas tus decisiones al terminar';

  @override
  String get onboardingChoiceTitle => 'Tú decides';

  @override
  String get onboardingChoiceSubtitle =>
      'El análisis y las vistas previas son gratis\nEliminar y comprimir vídeos requiere Pro. Los originales nunca se eliminan automáticamente.';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingPreparing => 'Preparando…';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingGetStarted => 'Empezar';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Cerrar';

  @override
  String get paywallDescription =>
      'Desbloquea la limpieza de fotos y vídeos. Revisa los elementos antes de elegir qué eliminar.';

  @override
  String get paywallReloadPlans => 'Recargar planes';

  @override
  String get paywallNotConfigured => 'Suscripciones no disponibles';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallStoreNotice =>
      'Las compras se realizan mediante el App Store. Gestiona o cancela las suscripciones en los ajustes de tu Apple ID.';

  @override
  String get paywallRestorePurchases => 'Restaurar compras';

  @override
  String get paywallPrivacyPolicy => 'Política de privacidad';

  @override
  String get paywallTerms => 'Condiciones de uso';

  @override
  String get paywallPurchaseIncomplete =>
      'La compra no se ha completado. Inténtalo más tarde.';

  @override
  String get paywallRestored => 'Acceso Pro restaurado.';

  @override
  String get paywallRestoreNotFound =>
      'No se han encontrado compras para restaurar.';

  @override
  String get paywallWeeklyPlan => 'Suscripción semanal';

  @override
  String get paywallYearlyPlan => 'Suscripción anual';

  @override
  String get paywallYearlySubtitle =>
      'Organiza fotos y vídeos durante todo el año';

  @override
  String get paywallWeeklySubtitle =>
      'Para una sesión breve de limpieza de fotos';

  @override
  String get paywallPhotoFeature =>
      'Agrupa fotos duplicadas y similares y revisa cada elemento';

  @override
  String get paywallVideoFeature =>
      'Comprime vídeos, revísalos y guarda copias';

  @override
  String get paywallSwipeFeature => 'Organiza rápidamente deslizando';

  @override
  String get paywallPlansUnavailable =>
      'No se han podido cargar los planes. Comprueba la conexión y vuelve a cargarlos.';

  @override
  String get paywallBestValue => 'Mejor oferta';

  @override
  String get videoTitle => 'Compresión de vídeo';

  @override
  String get videoDescription =>
      'La compresión reduce la calidad y crea una copia. Comprueba la imagen, el sonido y la orientación antes de guardar en Fotos. El original se conserva.';

  @override
  String get videoProRequired =>
      'Esta función requiere Pro. Vuelve a la página de limpieza para ver los planes.';

  @override
  String get videoSaving => 'Guardando en Fotos. Espera a que termine.';

  @override
  String get videoCancelCompression => 'Cancelar compresión';

  @override
  String get videoLoadingPreview => 'Cargando vista previa del vídeo…';

  @override
  String get videoCreatePreview => 'Crear vista previa comprimida';

  @override
  String get videoStorageNotice =>
      'Guardar una copia ocupa temporalmente más espacio. Tras eliminar el original y vaciar «Eliminado recientemente», consulta el espacio disponible real en el sistema.';

  @override
  String get videoViewOriginal => 'Ver original';

  @override
  String get videoViewCopy => 'Ver copia comprimida';

  @override
  String get videoSaved =>
      'La copia se ha guardado en Fotos y el original se conserva. Vuelve a analizar desde Inicio y decide si quieres eliminar el original.';

  @override
  String get videoConfirmSave => 'Confirmar copia y guardar en Fotos';

  @override
  String get videoPreviewUnavailable =>
      'No se ha podido reproducir la vista previa. Inténtalo de nuevo. El original se conserva.';

  @override
  String get videoPlaybackUnavailable =>
      'El vídeo no se puede reproducir ahora. Recarga la vista previa.';

  @override
  String get videoOperationIncomplete =>
      'La operación no ha terminado. El original se conserva. Comprueba el permiso de Fotos y el espacio disponible e inténtalo de nuevo.';

  @override
  String get videoPauseOriginal => 'Original: pausar';

  @override
  String get videoPlayOriginal => 'Original: reproducir';

  @override
  String get videoPauseCopy => 'Copia comprimida: pausar';

  @override
  String get videoPlayCopy => 'Copia comprimida: reproducir';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Versión $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Preparando / comprimiendo vídeo $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Original: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Copia: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Diferencia de tamaño: $size';
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
      'Consulta el almacenamiento en los ajustes del iPhone. Aquí puedes organizar las fotos y vídeos accesibles.';

  @override
  String get homeViewIndexedPhotos => 'Ver fotos ya leídas';

  @override
  String get homeViewIndexedScreenshots => 'Ver capturas ya leídas';

  @override
  String get homeCleanupTools => 'Herramientas de limpieza';

  @override
  String get homeQuickActions => 'Acciones rápidas';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Revisa primero y organiza fotos y vídeos';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Usado';

  @override
  String get homeUsedLegend => 'Usado';

  @override
  String get homeAvailableLegend => 'Disponible';

  @override
  String get homeStartScanHint =>
      'Sin analizar todavía. Toca abajo para empezar.';

  @override
  String get homeScanning => 'Analizando…';

  @override
  String get homeDeleting => 'Eliminando…';

  @override
  String get homeResumeScan => 'Continuar el análisis y conservar el progreso';

  @override
  String get homeScanAll => 'Analizar todas las fotos y vídeos accesibles';

  @override
  String get homePreviewOrganize => 'Revisar y organizar';

  @override
  String get homeVerifyOriginals =>
      'Verificar originales locales para duplicados exactos y tamaños';

  @override
  String get homeRetryPending =>
      'Continuar análisis / reintentar elementos pendientes';

  @override
  String get homeExactDuplicates => 'Fotos duplicadas exactas';

  @override
  String get homeSimilarPhotos => 'Fotos visualmente similares';

  @override
  String get homeNotScanned => 'Sin analizar todavía';

  @override
  String get homePendingAnalysis => 'Análisis visual pendiente';

  @override
  String get homeNoneAnalyzed => 'Ninguno entre los elementos analizados';

  @override
  String get homeScreenshots => 'Capturas de pantalla';

  @override
  String get homeLargeFiles => 'Archivos grandes';

  @override
  String get homeNoneFound => 'Ninguno encontrado';

  @override
  String get homePendingVerification => 'Verificación de originales pendiente';

  @override
  String get homeNoneVerified => 'Ninguno entre los elementos verificados';

  @override
  String get homeNeedsReview => 'Requiere revisión';

  @override
  String get homeCanReview => 'Revisar';

  @override
  String get homeScanStatus => 'Analizar';

  @override
  String get homeDoneStatus => 'Listo ✓';

  @override
  String get homePreviewPhotos => 'Vista previa de fotos';

  @override
  String get homeChooseKeep => 'Elegir qué conservar';

  @override
  String get navHome => 'Inicio';

  @override
  String get navClean => 'Limpiar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLoading => 'Cargando…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Plan gratuito';

  @override
  String get settingsUpgrade => 'Pasar a Pro';

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String get settingsStorageTotal => 'Total';

  @override
  String get settingsStorageUsed => 'Usado';

  @override
  String get settingsStorageAvailable => 'Disponible';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsProcessingSubscription => 'Procesando suscripción…';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsRestoredPro => 'Suscripción Pro restaurada.';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTerms => 'Condiciones de uso';

  @override
  String get settingsRateApp => 'Valorar la app';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsChooseLanguage => 'Elegir idioma';

  @override
  String get settingsSystemLanguage => 'Usar idioma del sistema';

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
      other: '$count elementos',
      one: '1 elemento',
    );
    return 'Leídos: $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Leídos $count de $total elementos accesibles';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Análisis visuales: $analyzed. Originales verificados: $verified. Las recomendaciones se pueden descartar; tú decides qué eliminar.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos (resultados parciales)',
      one: '1 foto (resultados parciales)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos verificadas; otras pendientes',
      one: '1 foto verificada; otras pendientes',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos verificados; otros pendientes',
      one: '1 elemento verificado; otros pendientes',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'No se ha podido guardar el idioma. Inténtalo de nuevo.';

  @override
  String get scanSmartTitle => 'Limpieza inteligente';

  @override
  String get scanCancelKeepProgress => 'Cancelar análisis y conservar progreso';

  @override
  String get scanSwipeCleanup => 'Limpieza deslizando';

  @override
  String get scanSortFileSize => 'Tamaño del archivo';

  @override
  String get scanSortNewest => 'Más recientes';

  @override
  String get scanStartAlbumTitle => 'Empezar a analizar la fototeca';

  @override
  String get scanIncompleteTitle => 'Análisis incompleto';

  @override
  String get scanStartAlbumDescription =>
      'Analiza todas las fotos y vídeos accesibles. La verificación de los originales y el análisis visual te ayudan a revisarlos antes de decidir.';

  @override
  String get scanContinue => 'Continuar análisis';

  @override
  String get scanStart => 'Iniciar análisis';

  @override
  String get scanPreviewWhileRunning =>
      'Puedes revisar fotos y capturas. La selección, la eliminación y la compresión de vídeo están pausadas durante el análisis.';

  @override
  String get scanExactDescription =>
      'Los duplicados exactos solo incluyen elementos con recursos originales verificados. Puedes descartar las recomendaciones de conservación.';

  @override
  String get scanSimilarDescription =>
      'Los candidatos visuales aparecen al analizar las vistas previas locales. Su contenido puede variar; las recomendaciones solo son orientativas.';

  @override
  String get scanLargeDescription =>
      'Ordenados por tamaño verificado de los recursos. El tamaño puede diferir del espacio realmente recuperado, que determina el sistema.';

  @override
  String get scanManualDeleteDescription =>
      'Solo se eliminarán los elementos que selecciones y confirmes manualmente.';

  @override
  String get scanVerifyOriginals =>
      'Verificar originales locales: duplicados exactos y tamaño';

  @override
  String get scanResumePending =>
      'Continuar análisis / reintentar elementos pendientes';

  @override
  String get scanKeepReasonDefault =>
      'Esta foto se recomienda para conservar en este grupo.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Mostrar de nuevo la recomendación de conservación';

  @override
  String get scanDismissKeepSuggestion =>
      'Descartar recomendación de conservación';

  @override
  String get scanKeepManualHint =>
      'Las recomendaciones nunca seleccionan elementos automáticamente. Toca una miniatura para marcarla para eliminar.';

  @override
  String get scanEmptyUnverified =>
      'Algunos recursos originales necesitan verificación. Aún no se pueden determinar duplicados exactos ni archivos grandes. Puedes revisar fotos y capturas.';

  @override
  String get scanEmptyVisualPending =>
      'Algunas vistas previas necesitan análisis. Los candidatos visuales aparecerán progresivamente; puedes revisar fotos y capturas.';

  @override
  String get scanEmptyIndexing =>
      'La fototeca aún se está indexando. Esta categoría se actualizará a medida que avance.';

  @override
  String get scanEmptyCategory =>
      'Ningún elemento en esta categoría entre los ya analizados o verificados.';

  @override
  String get scanKeepBadge => 'Conservación sugerida';

  @override
  String get scanZoomPreview => 'Ampliar vista previa';

  @override
  String get scanCompressVideo => 'Comprimir este vídeo';

  @override
  String get scanContentPending => 'Análisis de contenido pendiente';

  @override
  String get scanBackToCompare => 'Volver a la comparación';

  @override
  String get scanConfirmDeleteTitle => '¿Eliminar los elementos seleccionados?';

  @override
  String get scanCancel => 'Cancelar';

  @override
  String get scanNoItemsDeleted =>
      'No se ha eliminado ningún elemento. Puede que la operación se haya cancelado o haya fallado.';

  @override
  String get scanConfirmDelete => 'Confirmar eliminación';

  @override
  String get scanCategoryPhotos => 'Fotos';

  @override
  String get scanCategoryExact => 'Duplicados exactos';

  @override
  String get scanCategorySimilar => 'Candidatos visuales';

  @override
  String get scanCategoryScreenshots => 'Capturas de pantalla';

  @override
  String get scanCategoryVideos => 'Vídeos';

  @override
  String get scanCategoryLarge => 'Archivos grandes';

  @override
  String scanExactGroupCount(int count) {
    return 'Duplicados exactos: $count fotos';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Candidatos visuales: $count fotos';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Conservación sugerida: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Elementos seleccionados: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Revisar y eliminar $count elementos';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count elementos seleccionados. Revisa la selección y las recomendaciones antes de eliminar. El sistema determina el espacio recuperado.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Elementos eliminados: $count.';
  }

  @override
  String get scanIndexingTitle => 'Indexando la fototeca';

  @override
  String get scanVerifyingTitle =>
      'Verificando originales para duplicados exactos';

  @override
  String get scanAnalyzingTitle => 'Analizando vistas previas locales';

  @override
  String get scanSlowOperationHint =>
      'Esta operación está tardando más. Puedes cancelar, conservar el progreso y continuar después.';

  @override
  String get scanProgressPreviewHint =>
      'Puedes ver fotos y capturas indexadas. Las descargas pendientes o los análisis fallidos nunca se consideran duplicados exactos.';

  @override
  String get scanCountConfirming => 'Comprobando';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '$indexed / $total elementos indexados';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Vistas previas procesadas: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Recursos originales procesados: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Análisis visuales completados: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originales verificados: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Descargas pendientes: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Sin procesar en esta fase: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Esperando $seconds segundos';
  }

  @override
  String get swipeKeep => 'Conservar';

  @override
  String get swipeDelete => 'Eliminar';

  @override
  String get swipeReviewComplete => '¡Revisión completada!';

  @override
  String get swipeRecoveredSpaceHint =>
      'El sistema determina el espacio recuperado.';

  @override
  String get swipeUndoChoice => 'Deshacer última decisión';

  @override
  String get swipeBack => 'Atrás';

  @override
  String get swipeConfirmDeleteTitle =>
      '¿Eliminar las fotos marcadas para eliminar?';

  @override
  String get swipeCancel => 'Cancelar';

  @override
  String get swipeConfirmDelete => 'Confirmar eliminación';

  @override
  String get swipeNoPhotosDeleted =>
      'No se ha eliminado ninguna foto. Puede que la operación se haya cancelado o haya fallado.';

  @override
  String get swipeExitTitle => '¿Salir de esta revisión?';

  @override
  String get swipeContinueReview => 'Continuar revisión';

  @override
  String get swipeLeave => 'Salir';

  @override
  String get swipeSkipRemainingTitle => '¿Omitir las fotos restantes?';

  @override
  String get swipeDone => 'Listo';

  @override
  String swipeDoneCount(int count) {
    return 'Listo ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Eliminar: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Conservar: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount fotos para eliminar · $keepCount fotos para conservar';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Eliminar $count fotos';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Elimina $count fotos revisadas. Comprueba que has seleccionado correctamente los elementos que quieres conservar.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '$count fotos eliminadas. Las fotos restantes no se han eliminado.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Has marcado $count fotos para eliminar. Salir no las eliminará.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return 'Quedan $remaining fotos sin revisar. ¿Terminar la revisión y confirmar las $deleteCount fotos ya marcadas para eliminar?';
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
  String get assetReloadPreview => 'Recargar vista previa';

  @override
  String get assetSizeUnknown => 'Tamaño no disponible';

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
    return '$count octetos';
  }

  @override
  String get appName => 'Cleanup Master';

  @override
  String get nativePhotoRead =>
      'Accede a las fotos y vídeos permitidos para revisarlos, organizarlos y confirmar qué eliminar.';

  @override
  String get nativePhotoAdd =>
      'Guarda una copia comprimida del vídeo en Fotos al confirmar. El original se conserva.';

  @override
  String get nativeContacts =>
      'Accede a tus contactos para organizar los datos duplicados.';

  @override
  String get nativeTracking =>
      'Permite el seguimiento para personalizar tu experiencia y mejorar el servicio.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Las suscripciones no están disponibles ahora. Inténtalo más tarde.';

  @override
  String get serviceSubscriptionInitFailed =>
      'No se ha podido conectar con el servicio de suscripciones. Inténtalo más tarde.';

  @override
  String get serviceNoPlans =>
      'No hay planes de suscripción disponibles ahora. Inténtalo más tarde.';

  @override
  String get servicePlansLoadFailed =>
      'No se han podido cargar los planes. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get servicePurchaseUnavailable =>
      'Las compras no están disponibles ahora. Inténtalo más tarde.';

  @override
  String get servicePurchaseFailed =>
      'La compra no se ha completado. Inténtalo más tarde.';

  @override
  String get serviceRestoreUnavailable =>
      'La restauración de compras no está disponible ahora. Inténtalo más tarde.';

  @override
  String get serviceNoSubscription =>
      'No se ha encontrado una suscripción Pro activa.';

  @override
  String get serviceRestoreFailed =>
      'No se han podido restaurar las compras. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get servicePurchaseCancelled => 'Compra cancelada.';

  @override
  String get serviceScanPaused =>
      'En pausa. Los resultados leídos y analizados se conservan. Puedes continuar el análisis.';

  @override
  String get serviceLimitedLibrary =>
      'Solo se incluyen las fotos permitidas, no toda la fototeca.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'El análisis de archivos originales no está disponible en este dispositivo. Los tamaños y duplicados exactos no están verificados.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Verifica los originales locales para confirmar tamaños y duplicados exactos. Los elementos grandes o en la nube pueden quedar pendientes; los tamaños sin verificar no se estiman.';

  @override
  String get serviceReadingIndex => 'Leyendo el índice de la fototeca';

  @override
  String get servicePhotoPermission =>
      'El acceso a las fotos no está permitido. Permítelo en Ajustes e inténtalo de nuevo.';

  @override
  String get serviceOriginalRoundLimit =>
      'Esta ronda de verificación ha llegado a 60 segundos. Los resultados se conservan; verifica de nuevo para procesar primero los elementos aún no intentados.';

  @override
  String get servicePreviewRoundLimit =>
      'Esta ronda de vistas previas ha llegado a 30 segundos. Los resultados se conservan; continúa para procesar primero las fotos aún no intentadas.';

  @override
  String get serviceReadTimeout =>
      'Algunas lecturas han agotado el tiempo límite. Los resultados actuales se conservan; puedes continuar el análisis.';

  @override
  String get serviceReadInterrupted =>
      'Se han interrumpido algunas lecturas de la fototeca. Los resultados actuales se conservan; puedes continuar el análisis.';

  @override
  String get serviceVerifyingOriginals => 'Verificando originales locales';

  @override
  String get serviceGroupingSimilar =>
      'Agrupando candidatos visualmente similares';

  @override
  String get serviceQualityLowDetail =>
      'La vista previa tiene pocos detalles para recomendar según la calidad';

  @override
  String get serviceQualityDecodeFailed =>
      'No se ha podido decodificar la vista previa; no se ha evaluado la calidad';

  @override
  String get serviceQualityLowInformation =>
      'Información de imagen insuficiente para recomendar según la calidad';

  @override
  String get serviceQualityClearEdges =>
      'Bordes más nítidos en la vista previa';

  @override
  String get serviceQualityLessDetail =>
      'Bordes menos detallados en la vista previa';

  @override
  String get serviceQualityDark => 'La imagen parece oscura';

  @override
  String get serviceQualityBright => 'La imagen parece clara';

  @override
  String get serviceQualityBalanced => 'Brillo general equilibrado';

  @override
  String get serviceKeepExact =>
      'Los recursos originales y editados coinciden exactamente. Copia sugerida para conservar.';

  @override
  String get serviceKeepHigherResolution =>
      'Mayor resolución en este grupo. Se recomienda conservarla; revisa el contenido de la foto.';

  @override
  String get serviceVideoMissing => 'Vídeo no encontrado. Vuelve a analizar.';

  @override
  String get serviceVideoCloud =>
      'El vídeo está en iCloud. Descarga el original en Fotos e inténtalo de nuevo.';

  @override
  String get serviceVideoUnreadable => 'No se ha podido leer este vídeo.';

  @override
  String get serviceVideoPreviousBusy =>
      'La compresión anterior aún está terminando. Inténtalo en unos instantes.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'No se ha podido preparar el almacenamiento temporal del vídeo.';

  @override
  String get serviceVideoUnsupported =>
      'La compresión de vídeo no está disponible en este dispositivo.';

  @override
  String get serviceVideoOutputInvalid =>
      'La ubicación de salida no es válida. El original se conserva.';

  @override
  String get serviceVideoSaveUnknown =>
      'No se ha podido confirmar la copia guardada. Comprueba Fotos antes de intentarlo de nuevo.';

  @override
  String get serviceVideoCancelled => 'Compresión cancelada.';

  @override
  String get serviceVideoOperationBusy =>
      'Termina primero la operación de vídeo actual.';

  @override
  String get serviceVideoEmpty =>
      'El original está vacío y no se puede comprimir.';

  @override
  String get serviceVideoEncodeFailed =>
      'La compresión no ha terminado. El original se conserva.';

  @override
  String get serviceVideoNoCopy =>
      'La compresión no ha creado una copia independiente. El original se conserva.';

  @override
  String get serviceVideoNotSmaller =>
      'El vídeo comprimido no ocupa menos espacio. El original se conserva.';

  @override
  String get serviceVideoDurationMismatch =>
      'La duración del vídeo comprimido no coincide. El original se conserva.';

  @override
  String get serviceVideoValidationFailed =>
      'No se ha podido verificar el vídeo. El original se conserva.';

  @override
  String get serviceVideoPreviewFirst =>
      'Termina la compresión y revisa primero la vista previa.';

  @override
  String get serviceVideoSaveFailed =>
      'No se ha podido guardar la copia. El original se conserva. Inténtalo de nuevo.';

  @override
  String get serviceVideoGenericFailed =>
      'Operación no completada. El original se conserva. Comprueba el acceso a las fotos y el espacio libre e inténtalo de nuevo.';

  @override
  String get serviceOperationFailed =>
      'No se ha podido completar esta operación. Inténtalo de nuevo.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Leídos $read / $total elementos accesibles.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count fotos necesitan análisis visual. Continúa para procesar primero las fotos aún no intentadas. Los originales en la nube no se descargan automáticamente.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Leyendo vistas previas locales ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Analizando vistas previas locales ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; solo orientación';
  }
}
