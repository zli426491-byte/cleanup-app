// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Умная очистка';

  @override
  String get onboardingSmartSubtitle =>
      'Сканируйте фото и видео, к которым вы разрешили доступ\nСначала просмотрите их, затем решите, что оставить или удалить';

  @override
  String get onboardingPhotosTitle => 'Порядок в фотографиях';

  @override
  String get onboardingPhotosSubtitle =>
      'Сравнивайте дубликаты и похожие фото по содержимому\nПроверьте каждую рекомендацию о сохранении';

  @override
  String get onboardingSwipeTitle => 'Разбор смахиванием';

  @override
  String get onboardingSwipeSubtitle =>
      'Смахивайте, чтобы выбрать, что оставить или удалить\nВ конце подтвердите все решения';

  @override
  String get onboardingChoiceTitle => 'Решение за вами';

  @override
  String get onboardingChoiceSubtitle =>
      'Сканирование и просмотр фото бесплатны\nДля удаления и сжатия видео нужен Pro. Оригиналы никогда не удаляются автоматически.';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingPreparing => 'Подготовка…';

  @override
  String get onboardingContinue => 'Продолжить';

  @override
  String get onboardingGetStarted => 'Начать';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Закрыть';

  @override
  String get paywallDescription =>
      'Откройте очистку фото и видео. Просмотрите файлы, прежде чем решать, что удалить.';

  @override
  String get paywallReloadPlans => 'Загрузить тарифы снова';

  @override
  String get paywallNotConfigured => 'Подписки недоступны';

  @override
  String get paywallContinue => 'Продолжить';

  @override
  String get paywallStoreNotice =>
      'Покупки оформляются через App Store. Управлять подписками и отменять их можно в настройках Apple ID.';

  @override
  String get paywallRestorePurchases => 'Восстановить покупки';

  @override
  String get paywallPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get paywallTerms => 'Условия использования';

  @override
  String get paywallPurchaseIncomplete =>
      'Покупка не завершена. Повторите попытку позже.';

  @override
  String get paywallRestored => 'Доступ Pro восстановлен.';

  @override
  String get paywallRestoreNotFound => 'Покупки для восстановления не найдены.';

  @override
  String get paywallWeeklyPlan => 'Недельная подписка';

  @override
  String get paywallYearlyPlan => 'Годовая подписка';

  @override
  String get paywallYearlySubtitle =>
      'Поддерживайте порядок в фото и видео круглый год';

  @override
  String get paywallWeeklySubtitle => 'Для короткого разбора фотографий';

  @override
  String get paywallPhotoFeature =>
      'Удаляйте выбранные фото и видео после подтверждения';

  @override
  String get paywallVideoFeature =>
      'Сжимайте видео, просматривайте результат и сохраняйте копии';

  @override
  String get paywallSwipeFeature => 'Быстро разбирайте фото смахиванием';

  @override
  String get paywallPlansUnavailable =>
      'Не удалось загрузить тарифы подписки. Проверьте подключение и загрузите их снова.';

  @override
  String get paywallBestValue => 'Выгоднее всего';

  @override
  String get videoTryAnotherPreset => 'Попробовать другое качество';

  @override
  String get videoPresetTitle => 'Качество сжатия';

  @override
  String get videoPresetSmaller => 'Меньший файл';

  @override
  String get videoPresetBalanced => 'Баланс';

  @override
  String get videoPresetHigherQuality => 'Выше качество';

  @override
  String get videoPresetNotice =>
      'Выбранный режим управляет сжатием. Фактический размер появится после создания предпросмотра. Оригинал сохраняется.';

  @override
  String get serviceContinuousScanLimit =>
      'Непрерывное сканирование достигло лимита времени. Прогресс сохранён; можно продолжить позже.';

  @override
  String get swipeCheckpointRecovered =>
      'Некоторые сохранённые варианты проверки были повреждены и не восстановились. Проверьте эти фото ещё раз; ничего не удалено.';

  @override
  String get videoTitle => 'Сжатие видео';

  @override
  String get videoDescription =>
      'Сжатие снижает качество и создаёт новую копию. Перед сохранением в Фото проверьте изображение, звук и ориентацию. Оригинал сохраняется.';

  @override
  String get videoProRequired =>
      'Для этой функции нужен Pro. Вернитесь на страницу очистки, чтобы посмотреть тарифы.';

  @override
  String get videoSaving => 'Сохранение в Фото. Дождитесь завершения.';

  @override
  String get videoCancelCompression => 'Отменить сжатие';

  @override
  String get videoLoadingPreview => 'Загрузка предпросмотра видео…';

  @override
  String get videoCreatePreview => 'Создать предпросмотр сжатой копии';

  @override
  String get videoStorageNotice =>
      'Сохранение копии временно занимает больше места. После удаления оригинала и очистки «Недавно удалённых» проверьте фактически доступное место в системе.';

  @override
  String get videoViewOriginal => 'Посмотреть оригинал';

  @override
  String get videoViewCopy => 'Посмотреть сжатую копию';

  @override
  String get videoSaved =>
      'Копия сохранена в Фото, оригинал оставлен. Запустите сканирование с главного экрана и решите, удалять ли оригинал.';

  @override
  String get videoConfirmSave => 'Проверить копию и сохранить в Фото';

  @override
  String get videoPreviewUnavailable =>
      'Не удалось воспроизвести предпросмотр. Повторите попытку. Оригинал сохранён.';

  @override
  String get videoPlaybackUnavailable =>
      'Сейчас видео не воспроизводится. Загрузите предпросмотр снова.';

  @override
  String get videoOperationIncomplete =>
      'Операция не завершена. Оригинал сохранён. Проверьте доступ к Фото и свободное место, затем повторите попытку.';

  @override
  String get videoPauseOriginal => 'Оригинал: пауза';

  @override
  String get videoPlayOriginal => 'Оригинал: воспроизвести';

  @override
  String get videoPauseCopy => 'Сжатая копия: пауза';

  @override
  String get videoPlayCopy => 'Сжатая копия: воспроизвести';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Сборка $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Подготовка / сжатие видео: $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Оригинал: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Копия: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Разница в размере файлов: $size';
  }

  @override
  String videoSizeGb(String size) {
    return '$size ГБ';
  }

  @override
  String videoSizeMb(String size) {
    return '$size МБ';
  }

  @override
  String get homeStorageUnavailable =>
      'Проверьте память устройства в Настройках. Здесь можно разбирать доступные фото и видео.';

  @override
  String get homeViewIndexedPhotos => 'Посмотреть прочитанные фотографии';

  @override
  String get homeViewIndexedScreenshots =>
      'Посмотреть прочитанные снимки экрана';

  @override
  String get homeCleanupTools => 'Инструменты очистки';

  @override
  String get homeQuickActions => 'Быстрые действия';

  @override
  String get homeAppName => 'Очистка';

  @override
  String get homeSubtitle =>
      'Сначала просмотрите, затем разберите фото и видео';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Занято';

  @override
  String get homeUsedLegend => 'Занято';

  @override
  String get homeAvailableLegend => 'Доступно';

  @override
  String get homeStartScanHint =>
      'Сканирование ещё не выполнялось. Нажмите ниже, чтобы начать.';

  @override
  String get homeScanning => 'Сканирование…';

  @override
  String get homeDeleting => 'Удаление…';

  @override
  String get homeResumeScan =>
      'Продолжить сканирование с сохранением прогресса';

  @override
  String get homeScanAll => 'Сканировать все доступные фото и видео';

  @override
  String get homePreviewOrganize => 'Просмотреть и разобрать';

  @override
  String get homeVerifyOriginals =>
      'Проверить локальные оригиналы: точные дубликаты и размеры файлов';

  @override
  String get homeRetryPending =>
      'Продолжить сканирование / повторить незавершённое';

  @override
  String get homeExactDuplicates => 'Точные дубликаты фото';

  @override
  String get homeSimilarPhotos => 'Визуально похожие фото';

  @override
  String get homeNotScanned => 'Ещё не сканировалось';

  @override
  String get homePendingAnalysis => 'Ожидается визуальный анализ';

  @override
  String get homeNoneAnalyzed => 'Среди проанализированных файлов не найдено';

  @override
  String get homeScreenshots => 'Снимки экрана';

  @override
  String get homeLargeFiles => 'Большие файлы';

  @override
  String get homeNoneFound => 'Не найдено';

  @override
  String get homePendingVerification => 'Ожидается проверка оригиналов';

  @override
  String get homeNoneVerified => 'Среди проверенных файлов не найдено';

  @override
  String get homeNeedsReview => 'Нужно проверить';

  @override
  String get homeCanReview => 'Просмотреть';

  @override
  String get homeScanStatus => 'Сканировать';

  @override
  String get homeDoneStatus => 'Готово ✓';

  @override
  String get homePreviewPhotos => 'Просмотреть фото';

  @override
  String get homeChooseKeep => 'Выбрать, что оставить';

  @override
  String get navHome => 'Главная';

  @override
  String get navClean => 'Очистка';

  @override
  String get navSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLoading => 'Загрузка…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Бесплатный тариф';

  @override
  String get settingsUpgrade => 'Перейти на Pro';

  @override
  String get settingsStorage => 'Память';

  @override
  String get settingsStorageTotal => 'Всего';

  @override
  String get settingsStorageUsed => 'Занято';

  @override
  String get settingsStorageAvailable => 'Доступно';

  @override
  String get settingsGeneral => 'Общие';

  @override
  String get settingsProcessingSubscription => 'Обработка подписки…';

  @override
  String get settingsRestorePurchases => 'Восстановить покупки';

  @override
  String get settingsRestoredPro => 'Подписка Pro восстановлена.';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsRateApp => 'Оценить приложение';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsChooseLanguage => 'Выбрать язык';

  @override
  String get settingsSystemLanguage => 'Язык системы';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return 'Всего $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return 'Прочитано: $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Прочитано доступных файлов: $count / $total';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Визуально проанализировано: $analyzed. Оригиналов проверено: $verified. Рекомендации о сохранении можно отменить; вы решаете, что удалить.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
      many: '$count фото',
      few: '$count фото',
      one: '$count фото',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото (частичные результаты)',
      many: '$count фото (частичные результаты)',
      few: '$count фото (частичные результаты)',
      one: '$count фото (частичные результаты)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото проверено; другие ожидают проверки',
      many: '$count фото проверено; другие ожидают проверки',
      few: '$count фото проверено; другие ожидают проверки',
      one: '$count фото проверено; другие ожидают проверки',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла проверены; другие ожидают проверки',
      many: '$count файлов проверено; другие ожидают проверки',
      few: '$count файла проверены; другие ожидают проверки',
      one: '$count файл проверен; другие ожидают проверки',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Не удалось сохранить язык. Повторите попытку.';

  @override
  String get scanSmartTitle => 'Умная очистка';

  @override
  String get scanCancelKeepProgress =>
      'Отменить сканирование и сохранить прогресс';

  @override
  String get scanSwipeCleanup => 'Разбор смахиванием';

  @override
  String get scanSortFileSize => 'Размер файла';

  @override
  String get scanSortNewest => 'Сначала новые';

  @override
  String get scanStartAlbumTitle => 'Начните сканирование медиатеки';

  @override
  String get scanIncompleteTitle => 'Сканирование не завершено';

  @override
  String get scanStartAlbumDescription =>
      'Сначала анализируются предпросмотры похожих фото. Идентичные фото и большие файлы проверяются отдельно при открытии этих категорий. Ничего не удаляется автоматически.';

  @override
  String get scanContinue => 'Продолжить сканирование';

  @override
  String get scanStart => 'Начать сканирование';

  @override
  String get scanPreviewWhileRunning =>
      'Можно просматривать фото и снимки экрана. Во время сканирования выбор, удаление и сжатие видео приостановлены.';

  @override
  String get scanExactDescription =>
      'Точные дубликаты включают только файлы с проверенными оригинальными ресурсами. Рекомендации о сохранении можно отменить.';

  @override
  String get scanSimilarDescription =>
      'Визуальные кандидаты появляются по мере анализа локальных предпросмотров. Их содержимое может различаться; рекомендации о сохранении служат лишь ориентиром.';

  @override
  String get scanLargeDescription =>
      'Сортировка по проверенному размеру ресурсов. Размер файла может отличаться от фактически освобождённого места; его определяет система.';

  @override
  String get scanManualDeleteDescription =>
      'Удаляются только файлы, которые вы выбрали вручную и подтвердили.';

  @override
  String get scanVerifyOriginals =>
      'Проверить локальные оригиналы: точные дубликаты и размер';

  @override
  String get scanResumePending =>
      'Продолжить сканирование / повторить незавершённое';

  @override
  String get scanKeepReasonDefault =>
      'Это фото рекомендуется оставить в данной группе.';

  @override
  String get scanRestoreKeepSuggestion =>
      'Снова показать рекомендацию о сохранении';

  @override
  String get scanDismissKeepSuggestion => 'Отменить рекомендацию о сохранении';

  @override
  String get scanKeepManualHint =>
      'Рекомендации никогда не выбирают файлы автоматически. Нажмите на миниатюру, чтобы отметить файл для удаления.';

  @override
  String get scanEmptyUnverified =>
      'Некоторые оригинальные ресурсы ещё требуют проверки. Точные дубликаты и большие файлы пока нельзя определить. Можно просматривать фото и снимки экрана.';

  @override
  String get scanEmptyVisualPending =>
      'Некоторые предпросмотры фото ещё требуют анализа. Визуальные кандидаты будут появляться постепенно; можно просматривать фото и снимки экрана.';

  @override
  String get scanEmptyIndexing =>
      'Индексация медиатеки продолжается. Эта категория будет обновляться по мере индексации.';

  @override
  String get scanEmptyCategory =>
      'Среди проанализированных или проверенных файлов в этой категории ничего нет.';

  @override
  String get scanKeepBadge => 'Рекомендуется оставить';

  @override
  String get scanZoomPreview => 'Увеличить предпросмотр';

  @override
  String get scanCompressVideo => 'Сжать это видео';

  @override
  String get scanContentPending => 'Ожидается анализ содержимого';

  @override
  String get scanBackToCompare => 'Вернуться к сравнению';

  @override
  String get scanConfirmDeleteTitle => 'Удалить выбранные файлы?';

  @override
  String get scanCancel => 'Отмена';

  @override
  String get scanNoItemsDeleted =>
      'Файлы не удалены. Операция могла быть отменена или завершиться ошибкой.';

  @override
  String get scanConfirmDelete => 'Подтвердить удаление';

  @override
  String get scanCategoryPhotos => 'Фото';

  @override
  String get scanCategoryExact => 'Точные дубликаты';

  @override
  String get scanCategorySimilar => 'Визуальные кандидаты';

  @override
  String get scanCategoryScreenshots => 'Снимки экрана';

  @override
  String get scanCategoryVideos => 'Видео';

  @override
  String get scanCategoryLarge => 'Большие файлы';

  @override
  String scanExactGroupCount(int count) {
    return 'Точные дубликаты: $count фото';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Визуальные кандидаты: $count фото';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Рекомендуется оставить: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Выбрано файлов: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Просмотреть и удалить файлы: $count';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return 'Выбрано файлов: $count. Перед удалением проверьте выбор и рекомендации о сохранении. Освобождённое место определяет система.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Удалено файлов: $count.';
  }

  @override
  String get scanIndexingTitle => 'Индексация медиатеки';

  @override
  String get scanVerifyingTitle => 'Проверка оригинальных файлов';

  @override
  String get scanAnalyzingTitle => 'Анализ локальных предпросмотров фото';

  @override
  String get scanSlowOperationHint =>
      'Операция занимает больше времени. Можно отменить её, сохранить прогресс и продолжить позже.';

  @override
  String get scanProgressPreviewHint =>
      'Можно просматривать проиндексированные фото и снимки экрана. Ожидающие загрузки или неуспешно проанализированные файлы никогда не считаются точными дубликатами.';

  @override
  String get scanCountConfirming => 'Проверка';

  @override
  String scanIndexedCount(int indexed, String total) {
    return 'Проиндексировано $indexed / $total файлов';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Обработано предпросмотров фото: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Обработано оригинальных ресурсов: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Визуальных анализов завершено: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Оригиналов проверено: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Ожидают загрузки: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Ещё не обработано на этом этапе: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Ожидание: $seconds сек.';
  }

  @override
  String get swipeKeep => 'Оставить';

  @override
  String get swipeDelete => 'Удалить';

  @override
  String get swipeReviewComplete => 'Просмотр завершён!';

  @override
  String get swipeRecoveredSpaceHint =>
      'Освобождённое место определяет система.';

  @override
  String get swipeUndoChoice => 'Отменить последнее решение';

  @override
  String get swipeBack => 'Назад';

  @override
  String get swipeConfirmDeleteTitle =>
      'Удалить фото, отмеченные для удаления?';

  @override
  String get swipeCancel => 'Отмена';

  @override
  String get swipeConfirmDelete => 'Подтвердить удаление';

  @override
  String get swipeNoPhotosDeleted =>
      'Фото не удалены. Операция могла быть отменена или завершиться ошибкой.';

  @override
  String get swipeExitTitle => 'Выйти из просмотра?';

  @override
  String get swipeContinueReview => 'Продолжить просмотр';

  @override
  String get swipeLeave => 'Выйти';

  @override
  String get swipeSkipRemainingTitle => 'Пропустить остальные фото?';

  @override
  String get swipeDone => 'Готово';

  @override
  String swipeDoneCount(int count) {
    return 'Готово ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Удалить: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Оставить: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return 'Удалить: $deleteCount фото · Оставить: $keepCount фото';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Удалить фото: $count';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Выбрано фото для удаления: $count. Уберите из списка фотографии, которые хотите оставить.';
  }

  @override
  String swipePartialDeleted(int count) {
    return 'Удалено фото: $count. Остальные фотографии не удалены.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Вы отметили для удаления фото: $count. При выходе они не будут удалены.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return 'Не просмотрено фото: $remaining. Завершить просмотр и подтвердить удаление уже отмеченных фото ($deleteCount)?';
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
  String get assetReloadPreview => 'Загрузить предпросмотр снова';

  @override
  String get assetSizeUnknown => 'Размер недоступен';

  @override
  String assetSizeGigabytes(String value) {
    return '$value ГБ';
  }

  @override
  String assetSizeMegabytes(String value) {
    return '$value МБ';
  }

  @override
  String assetSizeKilobytes(String value) {
    return '$value КБ';
  }

  @override
  String assetSizeBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count байта',
      many: '$count байт',
      few: '$count байта',
      one: '$count байт',
    );
    return '$_temp0';
  }

  @override
  String get appName => 'Мастер очистки';

  @override
  String get nativePhotoRead =>
      'Доступ к разрешённым вами фото и видео для просмотра, упорядочивания и подтверждения удаления.';

  @override
  String get nativePhotoAdd =>
      'Сохранение сжатой копии видео в Фото после вашего подтверждения. Оригинал сохраняется.';

  @override
  String get nativeContacts =>
      'Доступ к контактам для упорядочивания повторяющихся контактных данных.';

  @override
  String get nativeTracking =>
      'Разрешите отслеживание для персонализации и улучшения сервиса.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Подписки сейчас недоступны. Повторите попытку позже.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Не удалось подключиться к сервису подписок. Повторите попытку позже.';

  @override
  String get serviceNoPlans =>
      'Сейчас нет доступных тарифов подписки. Повторите попытку позже.';

  @override
  String get servicePlansLoadFailed =>
      'Не удалось загрузить тарифы. Проверьте подключение и повторите попытку.';

  @override
  String get servicePurchaseUnavailable =>
      'Покупки сейчас недоступны. Повторите попытку позже.';

  @override
  String get servicePurchaseFailed =>
      'Покупка не завершена. Повторите попытку позже.';

  @override
  String get serviceRestoreUnavailable =>
      'Восстановление покупок сейчас недоступно. Повторите попытку позже.';

  @override
  String get serviceNoSubscription => 'Активная подписка Pro не найдена.';

  @override
  String get serviceRestoreFailed =>
      'Не удалось восстановить покупки. Проверьте подключение и повторите попытку.';

  @override
  String get servicePurchaseCancelled => 'Покупка отменена.';

  @override
  String get serviceScanPaused =>
      'Приостановлено. Прочитанные и проанализированные результаты сохранены. Можно продолжить сканирование.';

  @override
  String get serviceLimitedLibrary =>
      'Включены только разрешённые вами фото, а не вся медиатека.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'Анализ оригинальных файлов недоступен на этом устройстве. Размеры и точные дубликаты не проверены.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Проверьте локальные оригиналы, чтобы подтвердить размеры файлов и точные дубликаты. Большие или облачные файлы могут остаться в ожидании; непроверенные размеры не оцениваются.';

  @override
  String get serviceReadingIndex => 'Чтение индекса медиатеки';

  @override
  String get servicePhotoPermission =>
      'Доступ к Фото не разрешён. Разрешите его в Настройках и повторите попытку.';

  @override
  String get serviceOriginalRoundLimit =>
      'Этот этап проверки достиг 60 секунд. Результаты сохранены; запустите проверку снова, чтобы сначала обработать файлы, которые ещё не проверялись.';

  @override
  String get servicePreviewRoundLimit =>
      'Этот этап предпросмотра достиг 30 секунд. Результаты сохранены; продолжите, чтобы сначала обработать фото, которые ещё не анализировались.';

  @override
  String get serviceReadTimeout =>
      'Время некоторых операций чтения истекло. Текущие результаты сохранены; можно продолжить сканирование.';

  @override
  String get serviceReadInterrupted =>
      'Некоторые операции чтения медиатеки прерваны. Текущие результаты сохранены; можно продолжить сканирование.';

  @override
  String get serviceVerifyingOriginals => 'Проверка локальных оригиналов';

  @override
  String get serviceGroupingSimilar =>
      'Группировка визуально похожих кандидатов';

  @override
  String get serviceQualityLowDetail =>
      'В предпросмотре слишком мало деталей для рекомендации по качеству';

  @override
  String get serviceQualityDecodeFailed =>
      'Не удалось декодировать предпросмотр; качество не оценивалось';

  @override
  String get serviceQualityLowInformation =>
      'Недостаточно данных изображения для рекомендации по качеству';

  @override
  String get serviceQualityClearEdges => 'Более чёткие контуры в предпросмотре';

  @override
  String get serviceQualityLessDetail =>
      'Меньше деталей контуров в предпросмотре';

  @override
  String get serviceQualityDark => 'Изображение выглядит тёмным';

  @override
  String get serviceQualityBright => 'Изображение выглядит светлым';

  @override
  String get serviceQualityBalanced => 'Сбалансированная общая яркость';

  @override
  String get serviceKeepExact =>
      'Оригинальные и отредактированные ресурсы полностью совпадают. Эту копию рекомендуется оставить.';

  @override
  String get serviceKeepHigherResolution =>
      'Более высокое разрешение в этой группе. Рекомендуется оставить; проверьте содержимое фото.';

  @override
  String get serviceVideoMissing =>
      'Видео не найдено. Выполните сканирование снова.';

  @override
  String get serviceVideoCloud =>
      'Видео находится в iCloud. Загрузите оригинал в Фото и повторите попытку.';

  @override
  String get serviceVideoUnreadable => 'Не удалось прочитать это видео.';

  @override
  String get serviceVideoPreviousBusy =>
      'Предыдущее сжатие ещё завершается. Повторите попытку чуть позже.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Не удалось подготовить временное хранилище видео.';

  @override
  String get serviceVideoUnsupported =>
      'Сжатие видео недоступно на этом устройстве.';

  @override
  String get serviceVideoOutputInvalid =>
      'Место сохранения результата недопустимо. Оригинал сохранён.';

  @override
  String get serviceVideoSaveUnknown =>
      'Не удалось подтвердить сохранение копии. Проверьте Фото перед повторной попыткой.';

  @override
  String get serviceVideoCancelled => 'Сжатие отменено.';

  @override
  String get serviceVideoOperationBusy =>
      'Сначала завершите текущую операцию с видео.';

  @override
  String get serviceVideoEmpty => 'Оригинал пуст и не может быть сжат.';

  @override
  String get serviceVideoEncodeFailed =>
      'Сжатие не завершено. Оригинал сохранён.';

  @override
  String get serviceVideoNoCopy =>
      'Сжатие не создало отдельную копию. Оригинал сохранён.';

  @override
  String get serviceVideoNotSmaller =>
      'Сжатое видео не стало меньше. Оригинал сохранён.';

  @override
  String get serviceVideoDurationMismatch =>
      'Продолжительность сжатого видео не совпадает. Оригинал сохранён.';

  @override
  String get serviceVideoValidationFailed =>
      'Не удалось проверить видео. Оригинал сохранён.';

  @override
  String get serviceVideoPreviewFirst =>
      'Сначала завершите сжатие и проверьте предпросмотр.';

  @override
  String get serviceVideoSaveFailed =>
      'Не удалось сохранить копию. Оригинал сохранён. Повторите попытку.';

  @override
  String get serviceVideoGenericFailed =>
      'Операция не завершена. Оригинал сохранён. Проверьте доступ к Фото и свободное место, затем повторите попытку.';

  @override
  String get serviceOperationFailed =>
      'Не удалось выполнить эту операцию. Повторите попытку.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Прочитано $read / $total доступных файлов.';
  }

  @override
  String servicePhotosPending(int count) {
    return 'Ещё $count фото требуют визуального анализа. Продолжите, чтобы сначала обработать ещё не анализировавшиеся фото. Облачные оригиналы не загружаются автоматически.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Чтение локальных предпросмотров ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Анализ локальных предпросмотров ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; только рекомендательные подсказки';
  }

  @override
  String get scanSwipeIntro =>
      'Смахните влево, чтобы отметить для удаления, вправо — чтобы сохранить. Удаление только после подтверждения.';

  @override
  String get scanSwipeStart => 'Начать разбор смахиванием';

  @override
  String get scanDetails => 'Подробности сканирования';

  @override
  String get scanVerificationNeeded => 'Оригинальные файлы ещё не проверены';

  @override
  String scanVerificationProgress(int verified, int total) {
    return 'Проверено: $verified / $total';
  }

  @override
  String get scanVerificationExplanation =>
      'Сначала проверьте содержимое и размер файлов, чтобы найти точные копии и большие файлы. Объекты в облаке можно проверить позже.';

  @override
  String get scanOriginalsAfterPreview =>
      'Точные дубликаты и большие файлы будут проверены после сканирования миниатюр. Можно приостановить сканирование и просмотреть найденное.';

  @override
  String get scanVerifyNow => 'Проверить копии и большие файлы';

  @override
  String get scanBrowsePhotos => 'Сначала разобрать фото';

  @override
  String get scanSelectAll => 'Выбрать всё в этой категории';

  @override
  String get scanClearSelection => 'Снять выделение';

  @override
  String get scanKeepOneSelectOthers =>
      'Оставить это фото и выбрать другие с загруженным предпросмотром';

  @override
  String scanGroupReadyOthers(int ready, int total) {
    return 'Другие фото группы, готовые к выбору: $ready из $total';
  }

  @override
  String get scanSelectOthersHint =>
      'Просмотрите фото, которое предложено сохранить, затем выберите остальные в группе одним действием.';

  @override
  String get scanNotChecked => 'Ожидает проверки';

  @override
  String scanPendingCheckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Проверить: $count файла',
      many: 'Проверить: $count файлов',
      few: 'Проверить: $count файла',
      one: 'Проверить: $count файл',
    );
    return '$_temp0';
  }

  @override
  String get swipeMultiSelectTitle => 'Выбрать несколько элементов';

  @override
  String get swipeDragSelectHint =>
      'Удерживайте и проведите по миниатюрам, чтобы выбрать загруженные превью.';

  @override
  String swipeMarkSelectedForDeletion(int count) {
    return 'Отметить $count фото для удаления';
  }

  @override
  String get swipeGestureTitle => 'Быстрый разбор смахиванием';

  @override
  String get swipeGestureDelete => 'Смахнуть влево — отметить для удаления';

  @override
  String get swipeGestureKeep => 'Смахнуть вправо — сохранить';

  @override
  String get swipeGestureSafety =>
      'Фото сначала попадают в список на удаление. Они удаляются только после нажатия «Готово» и подтверждения.';

  @override
  String get swipeGestureHelp => 'Как разбирать фото смахиванием';

  @override
  String get homeSwipeDescription =>
      'Смахивайте фото по одному — это быстрее, чем нажимать на миниатюры.';

  @override
  String get scanCheckExactPhotos => 'Проверить точные дубликаты';

  @override
  String get scanCheckFileSizes => 'Проверить размеры больших файлов';

  @override
  String get reviewDeleteTitle => 'Проверить удаление';

  @override
  String get reviewRemove => 'Убрать из списка удаления';

  @override
  String get reviewUnavailable =>
      'Предпросмотр недоступен. Повторите попытку или уберите этот файл.';

  @override
  String reviewUnseenCount(int count) {
    return 'Нужно просмотреть перед удалением: $count';
  }

  @override
  String get reviewAllVersions =>
      'Выбраны все версии в группе. Удалить их все?';

  @override
  String get reviewDeleteAllVersions => 'Удалить все версии';

  @override
  String reviewConfirmCount(int count) {
    return 'Подтвердить удаление · $count';
  }

  @override
  String swipeResumeReview(int count) {
    return 'Продолжить просмотр · просмотрено $count';
  }

  @override
  String get swipeResetReview => 'Начать заново';

  @override
  String swipeBatchSize(int count) {
    return 'Файлов за один раз: $count';
  }

  @override
  String get swipeAllMonths => 'Все месяцы';

  @override
  String get swipeReviewBatch => 'Выбрать месяц или набор';

  @override
  String get assetVideoLoading => 'Загрузка оригинального видео…';

  @override
  String get assetVideoUnavailable =>
      'Оригинальное видео недоступно. Загрузите его в Фото и повторите попытку.';

  @override
  String get homePermissionTitle => 'Нужен доступ к фото';

  @override
  String get homePermissionDescription =>
      'Разрешите доступ в Настройках для сканирования и просмотра. Ничего не удаляется автоматически.';

  @override
  String get homeOpenSettings => 'Открыть Настройки';

  @override
  String get homeManagePhotoAccess => 'Управление доступом к фото';

  @override
  String get homeReviewReady => 'Просмотреть доступные фото';

  @override
  String get homeContinueAnalysis => 'Продолжить анализ фото';

  @override
  String get homeScanDetails => 'Подробности сканирования';

  @override
  String get scanCheckingExactTitle => 'Проверка идентичных фото';

  @override
  String get scanCheckingSizesTitle => 'Проверка размеров файлов';

  @override
  String scanRoundProgress(int total, int completed) {
    return 'Обработано $completed / $total';
  }

  @override
  String get scanPauseReview => 'Приостановить и просмотреть';

  @override
  String get scanSelectionHint =>
      'Отметьте файлы для удаления. Нажмите «Просмотр», чтобы увидеть содержимое.';

  @override
  String get scanPreviewNotReady => 'Загрузите предпросмотр перед выбором';

  @override
  String scanUnreadableExcluded(int count) {
    return 'Предпросмотр не загружен, не выбрано: $count';
  }

  @override
  String get scanKeepThis => 'Оставить это фото';

  @override
  String get scanPreviewMore => 'Загрузить ещё фото';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return 'Подтверждённый размер: $size · Проверено: $count';
  }

  @override
  String homePendingSizes(int count) {
    return 'Файлы с неизвестным размером: $count';
  }

  @override
  String get scanReviewChanged =>
      'Фото или разрешения изменились. Проверьте список удаления снова.';

  @override
  String get paywallFreePreviewNote =>
      'Группировка, предпросмотр и отметки свайпом бесплатны. Pro открывает удаление после подтверждения и сжатие видео.';

  @override
  String paywallSubscribeWeekly(String price) {
    return 'Подписаться на неделю · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return 'Подписаться на год · $price';
  }

  @override
  String get paywallSubscribe => 'Подписаться';

  @override
  String paywallWeeklyRenewal(String price) {
    return 'Автопродление за $price в неделю, если не отменить. Проверьте окончательные условия в App Store.';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return 'Автопродление за $price в год, если не отменить. Проверьте окончательные условия в App Store.';
  }

  @override
  String get paywallRenewalGeneric =>
      'Продлевается автоматически, если не отменить. Перед подтверждением проверьте период и сумму в App Store.';

  @override
  String get paywallLoadingPlans => 'Загрузка планов подписки…';

  @override
  String get paywallWaitingForStore => 'Ожидание подтверждения App Store…';

  @override
  String get paywallRestoring => 'Восстановление покупок…';

  @override
  String get settingsCheckingSubscription => 'Проверка подписки…';

  @override
  String get settingsSubscriptionUnknown => 'Статус подписки недоступен';

  @override
  String get settingsManageSubscription => 'Управление подпиской';

  @override
  String get settingsManageUnavailable =>
      'Не удалось открыть управление. Откройте подписки в настройках учётной записи магазина.';

  @override
  String get onboardingStartFree => 'Начать бесплатно';

  @override
  String get swipeCheckpointSaveError =>
      'Не удалось сохранить прогресс. Можно продолжить, но в следующий раз он может не восстановиться.';

  @override
  String swipeCheckpointLimit(int count) {
    return 'Последних решений на этом устройстве: до $count';
  }

  @override
  String get scanSelectLoaded => 'Выбрать загруженные предпросмотры';

  @override
  String get homePhotoScopeChanged =>
      'Доступ к фото мог измениться. Сканируйте снова, чтобы обновить доступные фото.';

  @override
  String get navOptimize => 'Оптимизация';

  @override
  String get navExtras => 'Ещё';

  @override
  String get v2Before => 'До';

  @override
  String get v2After => 'После';

  @override
  String get v2Best => 'Лучшее';

  @override
  String get v2Cancel => 'Отмена';

  @override
  String get v2Select => 'Выбрать';

  @override
  String get v2SelectAll => 'Выбрать все';

  @override
  String get v2DeselectAll => 'Снять выбор';

  @override
  String v2SelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get v2CatSimilars => 'Похожие';

  @override
  String get v2CatDuplicates => 'Дубликаты';

  @override
  String get v2CatVideos => 'Видео';

  @override
  String get v2CatScreenshots => 'Скриншоты';

  @override
  String get v2CatBlurred => 'Размытые';

  @override
  String get v2CatLarge => 'Большие файлы';

  @override
  String get v2CatOther => 'Другие';

  @override
  String v2PhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
      many: '$count фото',
      few: '$count фото',
      one: '$count фото',
    );
    return '$_temp0';
  }

  @override
  String v2VideoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count видео',
      many: '$count видео',
      few: '$count видео',
      one: '$count видео',
    );
    return '$_temp0';
  }

  @override
  String v2ItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объекта',
      many: '$count объектов',
      few: '$count объекта',
      one: '$count объект',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count объекта',
      many: 'Удалить $count объектов',
      few: 'Удалить $count объекта',
      one: 'Удалить $count объект',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count видео',
      many: 'Удалить $count видео',
      few: 'Удалить $count видео',
      one: 'Удалить $count видео',
    );
    return '$_temp0';
  }

  @override
  String v2DeleteSize(String size) {
    return 'Удалить $size';
  }

  @override
  String v2FreeCleanupsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count бесплатной очистки',
      many: 'Осталось $count бесплатных очисток',
      few: 'Осталось $count бесплатные очистки',
      one: 'Осталась $count бесплатная очистка',
    );
    return '$_temp0';
  }

  @override
  String get v2SpaceToClean => 'Можно освободить';

  @override
  String v2StorageUsedOf(String used, String total) {
    return 'Занято $used из $total';
  }

  @override
  String get v2OptimizeTitle => 'Оптимизировать память';

  @override
  String get v2OptimizeSubtitle => 'Быстро освободите место';

  @override
  String get v2Scanning => 'Сканирование медиатеки…';

  @override
  String v2ScanningCount(int done, int total) {
    return '$done / $total';
  }

  @override
  String get v2CheckingDuplicates => 'Проверка дубликатов…';

  @override
  String get v2ScanStart => 'Сканировать фото';

  @override
  String get v2PermissionTitle => 'Разрешите доступ к Фото';

  @override
  String v2PermissionBody(String appName) {
    return '$appName нужен доступ к фото, чтобы найти дубликаты и освободить место. Фото остаются на вашем устройстве.';
  }

  @override
  String get v2OpenSettings => 'Открыть Настройки';

  @override
  String get v2IntroLeft => 'Влево';

  @override
  String get v2IntroToDelete => 'удалить';

  @override
  String get v2IntroRight => 'Вправо';

  @override
  String get v2IntroToKeep => 'оставить';

  @override
  String get v2LetsGo => 'Начать';

  @override
  String get v2IntroSimilars =>
      'Похожие снимки собраны в группы. Мы оставляем лучший и выбираем остальные за вас.';

  @override
  String get v2IntroDuplicates =>
      'Точные копии одного снимка. Оставьте один, а остальные удалите одним касанием.';

  @override
  String get v2IntroVideos =>
      'Просмотрите все видео. Отсортируйте по размеру или дате, чтобы найти самые тяжёлые.';

  @override
  String get v2IntroScreenshots =>
      'Старые скриншоты быстро копятся. Пролистайте их и удалите ненужные.';

  @override
  String get v2IntroBlurred =>
      'Смазанные и нечёткие снимки, которые вряд ли стоит хранить.';

  @override
  String get v2IntroLarge =>
      'Самые большие фото и видео. Удалив несколько, вы освободите больше всего места.';

  @override
  String get v2IntroOther =>
      'Фото вне категорий. Отсортируйте по размеру или дате и попрощайтесь с лишним.';

  @override
  String get v2IntroOptimize =>
      'Находит дубликаты и похожие фото, оставляет лучшие и выбирает остальные. Место — за секунды.';

  @override
  String get v2SortLargest => 'Крупные';

  @override
  String get v2SortNewest => 'Новые';

  @override
  String get v2EmptyCategory => 'Здесь нечего чистить';

  @override
  String get v2EmptyCategoryBody => 'В этой категории уже чисто.';

  @override
  String get v2VideoCompress => 'Сжатие видео';

  @override
  String get v2VideoCompressSubtitle => 'Нажмите, чтобы начать';

  @override
  String get v2VideoCompressBody =>
      'Сжимайте видео в копии поменьше, чтобы сэкономить место.';

  @override
  String get v2CongratsTitle => 'Поздравляем!';

  @override
  String get v2CongratsDeleted => 'Вы удалили';

  @override
  String v2CongratsSaved(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Сэкономлено около $minutes минуты',
      many: 'Сэкономлено около $minutes минут',
      few: 'Сэкономлено около $minutes минут',
      one: 'Сэкономлено около $minutes минуты',
    );
    return '$_temp0';
  }

  @override
  String v2CongratsUsing(String appName) {
    return 'с $appName';
  }

  @override
  String v2CongratsRecentlyDeleted(String size) {
    return 'Эти объекты хранятся в «Недавно удалённых» 30 дней. Удалите их там, чтобы освободить примерно $size (оценка); точный объём показывает «Хранилище iPhone».';
  }

  @override
  String get v2Great => 'Отлично';

  @override
  String get v2UnlockTitle => 'Откройте безлимитный доступ';

  @override
  String get v2UnlockFeature1 => 'Мгновенно находите похожие фото';

  @override
  String get v2UnlockFeature2 => 'Очистка без ограничений';

  @override
  String get v2UnlockFeature3 => 'Экономьте место и время';

  @override
  String get v2PrivacyLine =>
      'Фото анализируются на устройстве и никуда не загружаются.';

  @override
  String v2PerWeek(String price) {
    return '$price/неделя, отмена в любой момент';
  }

  @override
  String v2PerYear(String price) {
    return '$price/год';
  }

  @override
  String v2SavePercent(int percent) {
    return 'Скидка $percent%';
  }

  @override
  String v2FreeTrialDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня бесплатно',
      many: '$days дней бесплатно',
      few: '$days дня бесплатно',
      one: '$days день бесплатно',
    );
    return '$_temp0';
  }

  @override
  String v2StartFreeTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Начать: $days дня бесплатно',
      many: 'Начать: $days дней бесплатно',
      few: 'Начать: $days дня бесплатно',
      one: 'Начать: $days день бесплатно',
    );
    return '$_temp0';
  }

  @override
  String v2FreeThen(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня бесплатно, затем $price',
      many: '$days дней бесплатно, затем $price',
      few: '$days дня бесплатно, затем $price',
      one: '$days день бесплатно, затем $price',
    );
    return '$_temp0';
  }

  @override
  String get v2TrialEnabled => 'Бесплатный период включён';

  @override
  String get v2DueToday => 'К оплате сегодня';

  @override
  String v2DueOn(String date) {
    return 'К оплате $date';
  }

  @override
  String v2DaysFree(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня бесплатно',
      many: '$days дней бесплатно',
      few: '$days дня бесплатно',
      one: '$days день бесплатно',
    );
    return '$_temp0';
  }

  @override
  String get v2TryFree => 'Попробовать бесплатно';

  @override
  String get v2CleanYourStorage => 'Очистите память';

  @override
  String get v2GetRidOf => 'Избавьтесь от лишнего';

  @override
  String get v2ProFeatures => 'Умная очистка, сжатие видео и никаких лимитов.';

  @override
  String v2WelcomeTitle(String appName) {
    return 'Добро пожаловать в $appName';
  }

  @override
  String v2WelcomeAccess(String appName) {
    return '$appName нужен доступ к Фото, чтобы освободить место.';
  }

  @override
  String get v2WelcomePrivacy =>
      'Фото анализируются на устройстве и никогда не загружаются на наши серверы.';

  @override
  String get v2GetStarted => 'Начать';

  @override
  String get v2Next => 'Далее';

  @override
  String get v2OnbDupTitle => 'Удаляйте дубликаты фото';

  @override
  String get v2OnbDupBody =>
      'Находите дубликаты за секунды и возвращайте место.';

  @override
  String get v2OnbSwipeTitle => 'Смахивайте для очистки';

  @override
  String get v2OnbSwipeBody =>
      'Влево — удалить, вправо — оставить. Так быстро ещё не было.';

  @override
  String get v2OnbVideoTitle => 'Сжимайте видео';

  @override
  String get v2OnbVideoBody =>
      'Уменьшайте большие видео и сохраняйте воспоминания.';

  @override
  String v2TryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Попробуйте $days дня',
      many: 'Попробуйте $days дней',
      few: 'Попробуйте $days дня',
      one: 'Попробуйте $days день',
    );
    return '$_temp0';
  }

  @override
  String get v2ForFree => 'Бесплатно!';

  @override
  String get v2ExtrasTitle => 'Доп. инструменты';

  @override
  String get v2ExtrasUtilities => 'Утилиты';

  @override
  String get v2ExtrasPrivate => 'Личное';

  @override
  String get v2ChargingTitle => 'Анимация зарядки';

  @override
  String get v2ChargingBody => 'Настройте экран зарядки';

  @override
  String get v2SecretTitle => 'Тайная медиатека';

  @override
  String get v2SecretBody => 'Защитите личные фото';

  @override
  String get v2ScanPaused => 'Сканирование на паузе';

  @override
  String get v2ContinueScan => 'Продолжить';

  @override
  String get v2PauseScan => 'Приостановить';

  @override
  String v2ContinueFreeCleanup(int count) {
    return 'Продолжить бесплатную очистку (осталось $count)';
  }

  @override
  String get v2DailyLimitTitle => 'Достигнут дневной лимит удаления';

  @override
  String v2DailyLimitBody(int limit) {
    return 'В бесплатной версии можно удалять $limit объектов в день. Откройте Pro, чтобы снять лимит.';
  }

  @override
  String v2DailyLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Сегодня можно бесплатно удалить ещё $count объекта. Выберите меньше или откройте Pro.',
      many:
          'Сегодня можно бесплатно удалить ещё $count объектов. Выберите меньше или откройте Pro.',
      few:
          'Сегодня можно бесплатно удалить ещё $count объекта. Выберите меньше или откройте Pro.',
      one:
          'Сегодня можно бесплатно удалить ещё $count объект. Выберите меньше или откройте Pro.',
    );
    return '$_temp0';
  }

  @override
  String get v2SeeProOptions => 'Посмотреть Pro';

  @override
  String get v2SelectionOverLimitTitle => 'Слишком много объектов на сегодня';

  @override
  String get v2CheckPaused => 'Проверка дубликатов приостановлена';

  @override
  String get v2StillChecking => 'Фото ещё проверяются';

  @override
  String get v2StillCheckingBody =>
      'Результаты появятся здесь по мере сканирования на главном экране.';

  @override
  String get v2ContinueOnHome =>
      'Нажмите «Продолжить» на главном экране, чтобы найти больше.';
}
