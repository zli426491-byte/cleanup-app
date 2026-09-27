// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Limpeza inteligente';

  @override
  String get onboardingSmartSubtitle =>
      'Analise as fotos e vídeos aos quais permite acesso\nVeja a prévia e escolha o que guardar ou eliminar';

  @override
  String get onboardingPhotosTitle => 'Organizar fotos';

  @override
  String get onboardingPhotosSubtitle =>
      'Compare o conteúdo de fotos duplicadas e semelhantes\nReveja cada foto sugerida para guardar';

  @override
  String get onboardingSwipeTitle => 'Deslizar para organizar';

  @override
  String get onboardingSwipeSubtitle =>
      'Deslize para escolher o que guardar ou eliminar\nConfirme todas as escolhas no fim';

  @override
  String get onboardingChoiceTitle => 'A decisão é sua';

  @override
  String get onboardingChoiceSubtitle =>
      'A análise e as prévias de fotos são gratuitas\nA eliminação e compressão de vídeos exigem Pro. Os originais nunca são eliminados automaticamente.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingPreparing => 'A preparar…';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Fechar';

  @override
  String get paywallDescription =>
      'Desbloqueie a limpeza de fotos e vídeos. Veja os itens antes de escolher o que eliminar.';

  @override
  String get paywallReloadPlans => 'Recarregar planos';

  @override
  String get paywallNotConfigured => 'Subscrições indisponíveis';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallStoreNotice =>
      'As compras são feitas pela App Store. Pode gerir ou cancelar subscrições nas definições do seu Apple ID.';

  @override
  String get paywallRestorePurchases => 'Restaurar compras';

  @override
  String get paywallPrivacyPolicy => 'Política de privacidade';

  @override
  String get paywallTerms => 'Termos de utilização';

  @override
  String get paywallPurchaseIncomplete =>
      'A compra não foi concluída. Tente novamente mais tarde.';

  @override
  String get paywallRestored => 'Acesso Pro restaurado.';

  @override
  String get paywallRestoreNotFound =>
      'Não foram encontradas compras para restaurar.';

  @override
  String get paywallWeeklyPlan => 'Subscrição semanal';

  @override
  String get paywallYearlyPlan => 'Subscrição anual';

  @override
  String get paywallYearlySubtitle =>
      'Organize fotos e vídeos durante todo o ano';

  @override
  String get paywallWeeklySubtitle =>
      'Para uma sessão breve de limpeza de fotos';

  @override
  String get paywallPhotoFeature =>
      'Agrupe fotos duplicadas e semelhantes e reveja cada item';

  @override
  String get paywallVideoFeature =>
      'Comprima vídeos, veja a prévia e guarde cópias';

  @override
  String get paywallSwipeFeature =>
      'Organize rapidamente com gestos de deslizar';

  @override
  String get paywallPlansUnavailable =>
      'Não foi possível carregar os planos. Verifique a ligação e recarregue.';

  @override
  String get paywallBestValue => 'Melhor valor';

  @override
  String get videoTitle => 'Compressão de vídeo';

  @override
  String get videoDescription =>
      'A compressão reduz a qualidade e cria uma cópia. Verifique a imagem, o som e a orientação antes de guardar em Fotografias. O original é mantido.';

  @override
  String get videoProRequired =>
      'Esta função exige Pro. Volte à página de limpeza para ver os planos.';

  @override
  String get videoSaving => 'A guardar em Fotografias. Aguarde a conclusão.';

  @override
  String get videoCancelCompression => 'Cancelar compressão';

  @override
  String get videoLoadingPreview => 'A carregar a prévia do vídeo…';

  @override
  String get videoCreatePreview => 'Criar prévia comprimida';

  @override
  String get videoStorageNotice =>
      'Guardar uma cópia ocupa temporariamente mais espaço. Depois de eliminar o original e esvaziar “Apagados recentemente”, consulte o sistema para saber o espaço disponível real.';

  @override
  String get videoViewOriginal => 'Ver original';

  @override
  String get videoViewCopy => 'Ver cópia comprimida';

  @override
  String get videoSaved =>
      'A cópia foi guardada em Fotografias e o original foi mantido. Analise novamente no início e escolha se quer eliminar o original.';

  @override
  String get videoConfirmSave => 'Confirmar cópia e guardar em Fotografias';

  @override
  String get videoPreviewUnavailable =>
      'Não foi possível reproduzir a prévia. Tente novamente. O original é mantido.';

  @override
  String get videoPlaybackUnavailable =>
      'Não é possível reproduzir o vídeo agora. Recarregue a prévia.';

  @override
  String get videoOperationIncomplete =>
      'A operação não terminou. O original é mantido. Verifique a permissão de acesso a Fotografias e o espaço disponível e tente novamente.';

  @override
  String get videoPauseOriginal => 'Original: pausar';

  @override
  String get videoPlayOriginal => 'Original: reproduzir';

  @override
  String get videoPauseCopy => 'Cópia comprimida: pausar';

  @override
  String get videoPlayCopy => 'Cópia comprimida: reproduzir';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Versão $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'A preparar / comprimir vídeo $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Original: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Cópia: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Diferença de tamanho: $size';
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
      'Consulte o armazenamento nas definições do iPhone. Aqui pode organizar fotos e vídeos acessíveis.';

  @override
  String get homeViewIndexedPhotos => 'Ver fotos já lidas';

  @override
  String get homeViewIndexedScreenshots => 'Ver capturas de ecrã já lidas';

  @override
  String get homeCleanupTools => 'Ferramentas de limpeza';

  @override
  String get homeQuickActions => 'Ações rápidas';

  @override
  String get homeAppName => 'Cleanup';

  @override
  String get homeSubtitle => 'Veja a prévia e organize fotos e vídeos';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Utilizado';

  @override
  String get homeUsedLegend => 'Utilizado';

  @override
  String get homeAvailableLegend => 'Disponível';

  @override
  String get homeStartScanHint =>
      'Ainda não analisado. Toque abaixo para começar.';

  @override
  String get homeScanning => 'A analisar…';

  @override
  String get homeDeleting => 'A eliminar…';

  @override
  String get homeResumeScan => 'Continuar análise e manter progresso';

  @override
  String get homeScanAll => 'Analisar todas as fotos e vídeos acessíveis';

  @override
  String get homePreviewOrganize => 'Pré-visualizar e organizar';

  @override
  String get homeVerifyOriginals =>
      'Verificar originais locais para duplicados exatos e tamanhos';

  @override
  String get homeRetryPending => 'Continuar análise / tentar itens pendentes';

  @override
  String get homeExactDuplicates => 'Fotos exatamente duplicadas';

  @override
  String get homeSimilarPhotos => 'Fotos visualmente semelhantes';

  @override
  String get homeNotScanned => 'Ainda não analisado';

  @override
  String get homePendingAnalysis => 'Análise visual pendente';

  @override
  String get homeNoneAnalyzed => 'Nenhum encontrado entre os itens analisados';

  @override
  String get homeScreenshots => 'Capturas de ecrã';

  @override
  String get homeLargeFiles => 'Ficheiros grandes';

  @override
  String get homeNoneFound => 'Nenhum encontrado';

  @override
  String get homePendingVerification => 'Verificação de originais pendente';

  @override
  String get homeNoneVerified => 'Nenhum encontrado entre os itens verificados';

  @override
  String get homeNeedsReview => 'Requer revisão';

  @override
  String get homeCanReview => 'Rever';

  @override
  String get homeScanStatus => 'Analisar';

  @override
  String get homeDoneStatus => 'Concluído ✓';

  @override
  String get homePreviewPhotos => 'Pré-visualizar fotos';

  @override
  String get homeChooseKeep => 'Escolher o que guardar';

  @override
  String get navHome => 'Início';

  @override
  String get navClean => 'Limpar';

  @override
  String get navSettings => 'Definições';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsLoading => 'A carregar…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Plano gratuito';

  @override
  String get settingsUpgrade => 'Mudar para Pro';

  @override
  String get settingsStorage => 'Armazenamento';

  @override
  String get settingsStorageTotal => 'Total';

  @override
  String get settingsStorageUsed => 'Utilizado';

  @override
  String get settingsStorageAvailable => 'Disponível';

  @override
  String get settingsGeneral => 'Geral';

  @override
  String get settingsProcessingSubscription => 'A processar subscrição…';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsRestoredPro => 'Subscrição Pro restaurada.';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidade';

  @override
  String get settingsTerms => 'Termos de utilização';

  @override
  String get settingsRateApp => 'Avaliar a app';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsChooseLanguage => 'Escolher idioma';

  @override
  String get settingsSystemLanguage => 'Usar idioma do sistema';

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
      other: '$count itens',
      one: '1 item',
    );
    return 'Lidos: $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Lidos $count de $total itens acessíveis';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Análises visuais: $analyzed. Originais verificados: $verified. As sugestões são reversíveis; decide o que eliminar.';
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
      other: '$count fotos (resultados parciais)',
      one: '1 foto (resultados parciais)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos verificadas; outras pendentes',
      one: '1 foto verificada; outras pendentes',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens verificados; outros pendentes',
      one: '1 item verificado; outros pendentes',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Não foi possível guardar o idioma. Tente novamente.';

  @override
  String get scanSmartTitle => 'Limpeza inteligente';

  @override
  String get scanCancelKeepProgress => 'Cancelar análise e manter progresso';

  @override
  String get scanSwipeCleanup => 'Limpeza por deslize';

  @override
  String get scanSortFileSize => 'Tamanho do ficheiro';

  @override
  String get scanSortNewest => 'Mais recentes';

  @override
  String get scanStartAlbumTitle => 'Começar a análise da biblioteca';

  @override
  String get scanIncompleteTitle => 'Análise incompleta';

  @override
  String get scanStartAlbumDescription =>
      'Analise todas as fotos e vídeos acessíveis. A verificação dos originais e a análise visual ajudam a revê-los antes de decidir.';

  @override
  String get scanContinue => 'Continuar análise';

  @override
  String get scanStart => 'Iniciar análise';

  @override
  String get scanPreviewWhileRunning =>
      'Pode ver fotos e capturas de ecrã. A seleção, eliminação e compressão de vídeos ficam suspensas durante a análise.';

  @override
  String get scanExactDescription =>
      'Os duplicados exatos incluem apenas itens com recursos originais verificados. As sugestões para guardar podem ser dispensadas.';

  @override
  String get scanSimilarDescription =>
      'As sugestões visuais aparecem à medida que as prévias locais são analisadas. O conteúdo pode diferir; as recomendações são apenas uma orientação.';

  @override
  String get scanLargeDescription =>
      'Ordenados pelo tamanho verificado dos recursos. O tamanho do ficheiro pode diferir do espaço recuperado, que é determinado pelo sistema.';

  @override
  String get scanManualDeleteDescription =>
      'Só serão eliminados os itens selecionados manualmente e confirmados.';

  @override
  String get scanVerifyOriginals =>
      'Verificar originais locais: duplicados exatos e tamanho';

  @override
  String get scanResumePending => 'Continuar análise / tentar itens pendentes';

  @override
  String get scanKeepReasonDefault =>
      'Esta foto é sugerida para guardar neste grupo.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Mostrar novamente a sugestão para guardar';

  @override
  String get scanDismissKeepSuggestion => 'Dispensar sugestão para guardar';

  @override
  String get scanKeepManualHint =>
      'As recomendações nunca selecionam itens automaticamente. Toque numa miniatura para a marcar para eliminação.';

  @override
  String get scanEmptyUnverified =>
      'Alguns recursos originais ainda precisam de verificação. Ainda não é possível determinar duplicados exatos e ficheiros grandes. Pode ver fotos e capturas de ecrã.';

  @override
  String get scanEmptyVisualPending =>
      'Algumas prévias ainda precisam de análise. As sugestões visuais aparecerão progressivamente; pode ver fotos e capturas de ecrã.';

  @override
  String get scanEmptyIndexing =>
      'A biblioteca ainda está a ser indexada. Esta categoria será atualizada à medida que avançar.';

  @override
  String get scanEmptyCategory =>
      'Nenhum item nesta categoria entre os já analisados ou verificados.';

  @override
  String get scanKeepBadge => 'Sugestão para guardar';

  @override
  String get scanZoomPreview => 'Ampliar prévia';

  @override
  String get scanCompressVideo => 'Comprimir este vídeo';

  @override
  String get scanContentPending => 'Análise de conteúdo pendente';

  @override
  String get scanBackToCompare => 'Voltar à comparação';

  @override
  String get scanConfirmDeleteTitle => 'Eliminar os itens selecionados?';

  @override
  String get scanCancel => 'Cancelar';

  @override
  String get scanNoItemsDeleted =>
      'Nenhum item foi eliminado. A operação pode ter sido cancelada ou ter falhado.';

  @override
  String get scanConfirmDelete => 'Confirmar eliminação';

  @override
  String get scanCategoryPhotos => 'Fotos';

  @override
  String get scanCategoryExact => 'Duplicados exatos';

  @override
  String get scanCategorySimilar => 'Sugestões visuais';

  @override
  String get scanCategoryScreenshots => 'Capturas de ecrã';

  @override
  String get scanCategoryVideos => 'Vídeos';

  @override
  String get scanCategoryLarge => 'Ficheiros grandes';

  @override
  String scanExactGroupCount(int count) {
    return 'Duplicados exatos: $count fotos';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Sugestões visuais: $count fotos';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Sugestão para guardar: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Itens selecionados: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Ver e eliminar $count itens';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count itens selecionados. Reveja a seleção e as recomendações antes de eliminar. O espaço recuperado é determinado pelo sistema.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Itens eliminados: $count.';
  }

  @override
  String get scanIndexingTitle => 'A indexar a biblioteca';

  @override
  String get scanVerifyingTitle =>
      'A verificar originais para duplicados exatos';

  @override
  String get scanAnalyzingTitle => 'A analisar prévias locais';

  @override
  String get scanSlowOperationHint =>
      'Esta operação está a demorar. Pode cancelar, manter o progresso e continuar mais tarde.';

  @override
  String get scanProgressPreviewHint =>
      'Pode ver fotos e capturas de ecrã indexadas. Downloads pendentes ou análises sem sucesso nunca são tratados como duplicados exatos.';

  @override
  String get scanCountConfirming => 'A verificar';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '$indexed / $total itens indexados';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Prévias processadas: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Recursos originais processados: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Análises visuais concluídas: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Originais verificados: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Downloads pendentes: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Ainda não processados nesta fase: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · A aguardar há $seconds segundos';
  }

  @override
  String get swipeKeep => 'Guardar';

  @override
  String get swipeDelete => 'Eliminar';

  @override
  String get swipeReviewComplete => 'Revisão concluída!';

  @override
  String get swipeRecoveredSpaceHint =>
      'O espaço recuperado é determinado pelo sistema.';

  @override
  String get swipeUndoChoice => 'Anular última escolha';

  @override
  String get swipeBack => 'Voltar';

  @override
  String get swipeConfirmDeleteTitle =>
      'Eliminar as fotos marcadas para eliminação?';

  @override
  String get swipeCancel => 'Cancelar';

  @override
  String get swipeConfirmDelete => 'Confirmar eliminação';

  @override
  String get swipeNoPhotosDeleted =>
      'Nenhuma foto foi eliminada. A operação pode ter sido cancelada ou ter falhado.';

  @override
  String get swipeExitTitle => 'Sair desta revisão?';

  @override
  String get swipeContinueReview => 'Continuar revisão';

  @override
  String get swipeLeave => 'Sair';

  @override
  String get swipeSkipRemainingTitle => 'Saltar as fotos restantes?';

  @override
  String get swipeDone => 'Concluído';

  @override
  String swipeDoneCount(int count) {
    return 'Concluído ($count)';
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
    return 'Guardar: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount fotos para eliminar · $keepCount fotos para guardar';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Eliminar $count fotos';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Elimine $count fotos revistas. Verifique se selecionou corretamente os itens que quer guardar.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '$count fotos eliminadas. As fotos restantes não foram eliminadas.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Marcou $count fotos para eliminação. Sair não as elimina.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '$remaining fotos não foram revistas. Terminar a revisão e confirmar as $deleteCount fotos já marcadas para eliminação?';
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
  String get assetReloadPreview => 'Recarregar prévia';

  @override
  String get assetSizeUnknown => 'Tamanho indisponível';

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
      'Aceda às fotos e vídeos que permite para os ver, organizar e confirmar o que eliminar.';

  @override
  String get nativePhotoAdd =>
      'Guarde uma cópia comprimida do vídeo em Fotografias após confirmar. O original é mantido.';

  @override
  String get nativeContacts =>
      'Aceda aos contactos para organizar dados de contacto duplicados.';

  @override
  String get nativeTracking =>
      'Permita o rastreio para personalizar a experiência e melhorar o serviço.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'As subscrições estão indisponíveis. Tente novamente mais tarde.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Não foi possível ligar ao serviço de subscrições. Tente novamente mais tarde.';

  @override
  String get serviceNoPlans =>
      'Não há planos de subscrição disponíveis agora. Tente novamente mais tarde.';

  @override
  String get servicePlansLoadFailed =>
      'Não foi possível carregar os planos. Verifique a ligação e tente novamente.';

  @override
  String get servicePurchaseUnavailable =>
      'As compras estão indisponíveis agora. Tente novamente mais tarde.';

  @override
  String get servicePurchaseFailed =>
      'A compra não foi concluída. Tente novamente mais tarde.';

  @override
  String get serviceRestoreUnavailable =>
      'O restauro de compras está indisponível agora. Tente novamente mais tarde.';

  @override
  String get serviceNoSubscription =>
      'Não foi encontrada uma subscrição Pro ativa.';

  @override
  String get serviceRestoreFailed =>
      'Não foi possível restaurar as compras. Verifique a ligação e tente novamente.';

  @override
  String get servicePurchaseCancelled => 'Compra cancelada.';

  @override
  String get serviceScanPaused =>
      'Em pausa. Os resultados lidos e analisados são mantidos. Pode continuar a análise.';

  @override
  String get serviceLimitedLibrary =>
      'Só são incluídas as fotos permitidas, não toda a biblioteca.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'A análise de ficheiros originais não está disponível neste dispositivo. Tamanhos e duplicados exatos não estão verificados.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Verifique os originais locais para confirmar tamanhos e duplicados exatos. Itens grandes ou na nuvem podem ficar pendentes; tamanhos não verificados não são estimados.';

  @override
  String get serviceReadingIndex => 'A ler o índice da biblioteca';

  @override
  String get servicePhotoPermission =>
      'O acesso às fotos não é permitido. Autorize-o nas definições e tente novamente.';

  @override
  String get serviceOriginalRoundLimit =>
      'Esta verificação atingiu 60 segundos. Os resultados são mantidos; verifique novamente para processar primeiro os itens ainda não tentados.';

  @override
  String get servicePreviewRoundLimit =>
      'Esta análise de prévias atingiu 30 segundos. Os resultados são mantidos; continue para processar primeiro as fotos ainda não tentadas.';

  @override
  String get serviceReadTimeout =>
      'Algumas leituras excederam o tempo limite. Os resultados atuais são mantidos; pode continuar a análise.';

  @override
  String get serviceReadInterrupted =>
      'Algumas leituras da biblioteca foram interrompidas. Os resultados atuais são mantidos; pode continuar a análise.';

  @override
  String get serviceVerifyingOriginals => 'A verificar originais locais';

  @override
  String get serviceGroupingSimilar =>
      'A agrupar sugestões visualmente semelhantes';

  @override
  String get serviceQualityLowDetail =>
      'A prévia tem poucos detalhes para uma recomendação de qualidade';

  @override
  String get serviceQualityDecodeFailed =>
      'Não foi possível descodificar a prévia; a qualidade não foi avaliada';

  @override
  String get serviceQualityLowInformation =>
      'Informação da imagem insuficiente para recomendar pela qualidade';

  @override
  String get serviceQualityClearEdges => 'Contornos mais nítidos na prévia';

  @override
  String get serviceQualityLessDetail => 'Contornos menos detalhados na prévia';

  @override
  String get serviceQualityDark => 'A imagem parece escura';

  @override
  String get serviceQualityBright => 'A imagem parece clara';

  @override
  String get serviceQualityBalanced => 'Luminosidade geral equilibrada';

  @override
  String get serviceKeepExact =>
      'Os recursos originais e editados coincidem exatamente. Cópia sugerida para guardar.';

  @override
  String get serviceKeepHigherResolution =>
      'Maior resolução neste grupo. Sugestão para guardar; verifique o conteúdo da foto.';

  @override
  String get serviceVideoMissing => 'Vídeo não encontrado. Analise novamente.';

  @override
  String get serviceVideoCloud =>
      'O vídeo está no iCloud. Descarregue o original em Fotografias e tente novamente.';

  @override
  String get serviceVideoUnreadable => 'Não foi possível ler este vídeo.';

  @override
  String get serviceVideoPreviousBusy =>
      'A compressão anterior ainda está a terminar. Tente novamente em breve.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Não foi possível preparar o armazenamento temporário do vídeo.';

  @override
  String get serviceVideoUnsupported =>
      'A compressão de vídeo não está disponível neste dispositivo.';

  @override
  String get serviceVideoOutputInvalid =>
      'O destino de saída é inválido. O original é mantido.';

  @override
  String get serviceVideoSaveUnknown =>
      'Não foi possível confirmar a cópia guardada. Verifique Fotografias antes de tentar novamente.';

  @override
  String get serviceVideoCancelled => 'Compressão cancelada.';

  @override
  String get serviceVideoOperationBusy =>
      'Termine primeiro a operação de vídeo atual.';

  @override
  String get serviceVideoEmpty =>
      'O original está vazio e não pode ser comprimido.';

  @override
  String get serviceVideoEncodeFailed =>
      'A compressão não terminou. O original é mantido.';

  @override
  String get serviceVideoNoCopy =>
      'A compressão não criou uma cópia separada. O original é mantido.';

  @override
  String get serviceVideoNotSmaller =>
      'O vídeo comprimido não é menor. O original é mantido.';

  @override
  String get serviceVideoDurationMismatch =>
      'A duração do vídeo comprimido não coincide. O original é mantido.';

  @override
  String get serviceVideoValidationFailed =>
      'Não foi possível verificar o vídeo. O original é mantido.';

  @override
  String get serviceVideoPreviewFirst =>
      'Termine a compressão e reveja primeiro a prévia.';

  @override
  String get serviceVideoSaveFailed =>
      'Não foi possível guardar a cópia. O original é mantido. Tente novamente.';

  @override
  String get serviceVideoGenericFailed =>
      'A operação não foi concluída. O original é mantido. Verifique o acesso às fotos e o espaço livre e tente novamente.';

  @override
  String get serviceOperationFailed =>
      'Não foi possível concluir esta operação. Tente novamente.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Lidos $read / $total itens acessíveis.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count fotos ainda precisam de análise visual. Continue para processar primeiro as fotos ainda não tentadas. Os originais na nuvem não são descarregados automaticamente.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'A ler prévias locais ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'A analisar prévias locais ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; apenas orientação sugerida';
  }

  @override
  String get scanSwipeIntro =>
      'Deslize para a esquerda para marcar para eliminar e para a direita para manter. Só se elimina após confirmar.';

  @override
  String get scanSwipeStart => 'Começar a organizar deslizando';

  @override
  String get scanDetails => 'Detalhes da análise';

  @override
  String get scanVerificationNeeded =>
      'Ficheiros originais ainda não verificados';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '$verified / $total itens verificados';
  }

  @override
  String get scanVerificationExplanation =>
      'Verifique primeiro o conteúdo e o tamanho dos ficheiros para encontrar duplicados exatos e ficheiros grandes. Os itens na nuvem podem esperar.';

  @override
  String get scanVerifyNow => 'Verificar duplicados e ficheiros grandes';

  @override
  String get scanBrowsePhotos => 'Organizar primeiro as fotos';

  @override
  String get scanSelectAll => 'Selecionar tudo nesta categoria';

  @override
  String get scanClearSelection => 'Limpar seleção';

  @override
  String get scanKeepOneSelectOthers =>
      'Manter esta foto, selecionar as outras';

  @override
  String get scanSelectOthersHint =>
      'Veja a foto sugerida para manter e selecione as restantes do grupo de uma só vez.';

  @override
  String get scanNotChecked => 'Por verificar';

  @override
  String scanPendingCheckCount(int count) {
    return '$count itens por verificar';
  }

  @override
  String get swipeGestureTitle => 'Organizar rapidamente deslizando';

  @override
  String get swipeGestureDelete =>
      'Deslizar para a esquerda para marcar para eliminar';

  @override
  String get swipeGestureKeep => 'Deslizar para a direita para manter';

  @override
  String get swipeGestureSafety =>
      'As fotos entram primeiro numa lista para eliminar. Só são eliminadas depois de tocar em Concluir e confirmar.';

  @override
  String get swipeGestureHelp => 'Como organizar deslizando';

  @override
  String get homeSwipeDescription =>
      'Deslize foto a foto para organizar mais depressa do que tocando nas miniaturas.';
}
