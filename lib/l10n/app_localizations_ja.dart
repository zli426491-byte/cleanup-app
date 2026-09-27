// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get onboardingSmartTitle => 'スマート整理';

  @override
  String get onboardingSmartSubtitle =>
      '許可した写真と動画をスキャン\n先にプレビューして、残すものと削除するものを選べます';

  @override
  String get onboardingPhotosTitle => '写真を整理';

  @override
  String get onboardingPhotosSubtitle => '内容から重複・類似写真を比較\n残す候補も一枚ずつ確認してください';

  @override
  String get onboardingSwipeTitle => 'スワイプで整理';

  @override
  String get onboardingSwipeSubtitle => 'スワイプで残すか削除するかを選択\n最後にすべての選択を確認します';

  @override
  String get onboardingChoiceTitle => '決めるのはあなた';

  @override
  String get onboardingChoiceSubtitle =>
      'スキャンと写真のプレビューは無料\n削除と動画圧縮には Pro が必要です。オリジナルが自動で削除されることはありません。';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingPreparing => '準備中…';

  @override
  String get onboardingContinue => '続ける';

  @override
  String get onboardingGetStarted => '始める';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => '閉じる';

  @override
  String get paywallDescription => '写真と動画の整理機能を利用できます。プレビューしてから削除する項目を選んでください。';

  @override
  String get paywallReloadPlans => 'プランを再読み込み';

  @override
  String get paywallNotConfigured => '現在、登録できません';

  @override
  String get paywallContinue => '続ける';

  @override
  String get paywallStoreNotice =>
      '購入は App Store で行います。サブスクリプションの管理・解約は Apple ID の設定から行えます。';

  @override
  String get paywallRestorePurchases => '購入を復元';

  @override
  String get paywallPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get paywallTerms => '利用規約';

  @override
  String get paywallPurchaseIncomplete => '購入が完了しませんでした。後でもう一度お試しください。';

  @override
  String get paywallRestored => 'Pro の利用権を復元しました。';

  @override
  String get paywallRestoreNotFound => '復元できる購入が見つかりません。';

  @override
  String get paywallWeeklyPlan => '週額プラン';

  @override
  String get paywallYearlyPlan => '年額プラン';

  @override
  String get paywallYearlySubtitle => '一年を通して写真と動画を整理';

  @override
  String get paywallWeeklySubtitle => '短期間の写真整理に';

  @override
  String get paywallPhotoFeature => '重複・類似写真をグループ化し、一枚ずつ確認';

  @override
  String get paywallVideoFeature => '動画を圧縮・プレビューしてコピーを保存';

  @override
  String get paywallSwipeFeature => 'スワイプ操作で素早く整理';

  @override
  String get paywallPlansUnavailable => 'プランを読み込めませんでした。接続を確認して再読み込みしてください。';

  @override
  String get paywallBestValue => 'お得なプラン';

  @override
  String get videoTitle => '動画圧縮';

  @override
  String get videoDescription =>
      '圧縮すると画質が下がり、新しいコピーが作成されます。映像・音声・向きを確認してから「写真」に保存してください。オリジナルは残ります。';

  @override
  String get videoProRequired => 'この機能には Pro が必要です。整理ページに戻ってプランをご確認ください。';

  @override
  String get videoSaving => '「写真」に保存中です。完了するまでお待ちください。';

  @override
  String get videoCancelCompression => '圧縮をキャンセル';

  @override
  String get videoLoadingPreview => '動画プレビューを読み込み中…';

  @override
  String get videoCreatePreview => '圧縮プレビューを作成';

  @override
  String get videoStorageNotice =>
      'コピーの保存には一時的に追加の容量が必要です。オリジナルを削除し「最近削除した項目」を空にした後、実際の空き容量をシステムで確認してください。';

  @override
  String get videoViewOriginal => 'オリジナルを見る';

  @override
  String get videoViewCopy => '圧縮コピーを見る';

  @override
  String get videoSaved =>
      'コピーを「写真」に保存しました。オリジナルは残っています。ホームから再スキャンして、オリジナルを削除するか選んでください。';

  @override
  String get videoConfirmSave => 'コピーを確認して「写真」に保存';

  @override
  String get videoPreviewUnavailable =>
      'プレビューを再生できませんでした。もう一度お試しください。オリジナルは残っています。';

  @override
  String get videoPlaybackUnavailable => '現在、動画を再生できません。プレビューを再読み込みしてください。';

  @override
  String get videoOperationIncomplete =>
      '操作が完了しませんでした。オリジナルは残っています。写真へのアクセス許可と空き容量を確認して再試行してください。';

  @override
  String get videoPauseOriginal => 'オリジナル：一時停止';

  @override
  String get videoPlayOriginal => 'オリジナル：再生';

  @override
  String get videoPauseCopy => '圧縮コピー：一時停止';

  @override
  String get videoPlayCopy => '圧縮コピー：再生';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'ビルド $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return '動画を準備／圧縮中 $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'オリジナル：$size';
  }

  @override
  String videoCopySize(String size) {
    return 'コピー：$size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'ファイルサイズの差：$size';
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
      '端末の容量は iPhone の設定で確認してください。ここではアクセス可能な写真と動画を整理できます。';

  @override
  String get homeViewIndexedPhotos => '読み込み済みの写真を見る';

  @override
  String get homeViewIndexedScreenshots => '読み込み済みのスクリーンショットを見る';

  @override
  String get homeCleanupTools => '整理ツール';

  @override
  String get homeQuickActions => 'クイック操作';

  @override
  String get homeAppName => 'クリーンアップ';

  @override
  String get homeSubtitle => 'まずプレビュー、次に写真と動画を整理';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => '使用中';

  @override
  String get homeUsedLegend => '使用中';

  @override
  String get homeAvailableLegend => '空き';

  @override
  String get homeStartScanHint => 'まだスキャンしていません。下をタップして開始してください。';

  @override
  String get homeScanning => 'スキャン中…';

  @override
  String get homeDeleting => '削除中…';

  @override
  String get homeResumeScan => '進行状況を保持してスキャンを続ける';

  @override
  String get homeScanAll => 'アクセス可能な写真と動画をすべてスキャン';

  @override
  String get homePreviewOrganize => 'プレビューして整理';

  @override
  String get homeVerifyOriginals => '端末内のオリジナルを検証：完全重複とサイズ';

  @override
  String get homeRetryPending => 'スキャンを続ける／未処理項目を再試行';

  @override
  String get homeExactDuplicates => '完全重複の写真';

  @override
  String get homeSimilarPhotos => '見た目が似ている写真';

  @override
  String get homeNotScanned => '未スキャン';

  @override
  String get homePendingAnalysis => '画像解析待ち';

  @override
  String get homeNoneAnalyzed => '解析済みの項目では見つかりません';

  @override
  String get homeScreenshots => 'スクリーンショット';

  @override
  String get homeLargeFiles => '大きなファイル';

  @override
  String get homeNoneFound => '見つかりません';

  @override
  String get homePendingVerification => 'オリジナルの検証待ち';

  @override
  String get homeNoneVerified => '検証済みの項目では見つかりません';

  @override
  String get homeNeedsReview => '確認が必要';

  @override
  String get homeCanReview => '確認';

  @override
  String get homeScanStatus => 'スキャン';

  @override
  String get homeDoneStatus => '完了 ✓';

  @override
  String get homePreviewPhotos => '写真をプレビュー';

  @override
  String get homeChooseKeep => '残すものを選ぶ';

  @override
  String get navHome => 'ホーム';

  @override
  String get navClean => '整理';

  @override
  String get navSettings => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLoading => '読み込み中…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => '無料プラン';

  @override
  String get settingsUpgrade => 'アップグレード';

  @override
  String get settingsStorage => 'ストレージ';

  @override
  String get settingsStorageTotal => '合計';

  @override
  String get settingsStorageUsed => '使用中';

  @override
  String get settingsStorageAvailable => '空き';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsProcessingSubscription => 'サブスクリプションを処理中…';

  @override
  String get settingsRestorePurchases => '購入を復元';

  @override
  String get settingsRestoredPro => 'Pro サブスクリプションを復元しました。';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsRateApp => '評価する';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsChooseLanguage => '言語を選択';

  @override
  String get settingsSystemLanguage => 'システムの言語に合わせる';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return '合計 $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件読み込み済み',
      one: '1 件読み込み済み',
    );
    return '$_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'アクセス可能な $total 件中 $count 件を読み込み済み';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return '画像解析済み：$analyzed 件。オリジナル検証済み：$verified 件。残す候補の提案は取り消せます。削除するかはあなたが決めます。';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真 $count 枚',
      one: '写真 1 枚',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真 $count 枚（一部の結果）',
      one: '写真 1 枚（一部の結果）',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
      one: '1 件',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '写真 $count 枚を検証済み、ほかは検証待ち',
      one: '写真 1 枚を検証済み、ほかは検証待ち',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件を検証済み、ほかは検証待ち',
      one: '1 件を検証済み、ほかは検証待ち',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError => '言語を保存できませんでした。もう一度お試しください。';

  @override
  String get scanSmartTitle => 'スマート整理';

  @override
  String get scanCancelKeepProgress => '進行状況を保持してスキャンをキャンセル';

  @override
  String get scanSwipeCleanup => 'スワイプ整理';

  @override
  String get scanSortFileSize => 'ファイルサイズ';

  @override
  String get scanSortNewest => '新しい順';

  @override
  String get scanStartAlbumTitle => 'ライブラリのスキャンを開始';

  @override
  String get scanIncompleteTitle => 'スキャン未完了';

  @override
  String get scanStartAlbumDescription =>
      'アクセス可能な写真と動画をすべてスキャンします。オリジナルの内容検証と画像解析により、確認してから判断できます。';

  @override
  String get scanContinue => 'スキャンを続ける';

  @override
  String get scanStart => 'スキャン開始';

  @override
  String get scanPreviewWhileRunning =>
      '写真とスクリーンショットはプレビューできます。スキャン中は選択・削除・動画圧縮を一時停止します。';

  @override
  String get scanExactDescription =>
      '完全重複にはオリジナルのリソースを検証済みの項目だけが含まれます。残す候補の提案は取り消せます。';

  @override
  String get scanSimilarDescription =>
      '端末内のプレビューを解析すると、見た目が似た候補が表示されます。内容が異なる場合もあり、残す候補は参考の提案です。';

  @override
  String get scanLargeDescription =>
      '検証済みのリソースのサイズ順に表示します。ファイルサイズと実際に空く容量は異なる場合があります。回復する容量はシステムが決定します。';

  @override
  String get scanManualDeleteDescription => '手動で選択し、確認した項目だけを削除します。';

  @override
  String get scanVerifyOriginals => '端末内のオリジナルを検証：完全重複とサイズ';

  @override
  String get scanResumePending => 'スキャンを続ける／未処理項目を再試行';

  @override
  String get scanKeepReasonDefault => 'このグループで残す候補として提案された写真です。';

  @override
  String get scanRestoreKeepSuggestion => '残す候補を再表示';

  @override
  String get scanDismissKeepSuggestion => '残す候補の提案を取り消す';

  @override
  String get scanKeepManualHint =>
      '提案で項目が自動選択されることはありません。サムネイルをタップして削除対象に指定してください。';

  @override
  String get scanEmptyUnverified =>
      '検証待ちのオリジナルがあります。完全重複や大きなファイルはまだ判断できません。写真とスクリーンショットはプレビューできます。';

  @override
  String get scanEmptyVisualPending =>
      '解析待ちの写真プレビューがあります。似ている候補は順次表示されます。写真とスクリーンショットはプレビューできます。';

  @override
  String get scanEmptyIndexing => 'ライブラリの索引を作成中です。このカテゴリは進行状況に応じて更新されます。';

  @override
  String get scanEmptyCategory => '現在、解析または検証が完了した項目に、このカテゴリの項目はありません。';

  @override
  String get scanKeepBadge => '残す候補';

  @override
  String get scanZoomPreview => 'プレビューを拡大';

  @override
  String get scanCompressVideo => 'この動画を圧縮';

  @override
  String get scanContentPending => '内容解析待ち';

  @override
  String get scanBackToCompare => '比較に戻る';

  @override
  String get scanConfirmDeleteTitle => '選択した項目を削除しますか？';

  @override
  String get scanCancel => 'キャンセル';

  @override
  String get scanNoItemsDeleted => '項目は削除されていません。操作がキャンセルされたか、失敗した可能性があります。';

  @override
  String get scanConfirmDelete => '削除を確認';

  @override
  String get scanCategoryPhotos => '写真';

  @override
  String get scanCategoryExact => '完全重複';

  @override
  String get scanCategorySimilar => '似ている候補';

  @override
  String get scanCategoryScreenshots => 'スクリーンショット';

  @override
  String get scanCategoryVideos => '動画';

  @override
  String get scanCategoryLarge => '大きなファイル';

  @override
  String scanExactGroupCount(int count) {
    return '完全重複：写真 $count 枚';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return '似ている候補：写真 $count 枚';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return '残す候補：$reason';
  }

  @override
  String scanSelectedCount(int count) {
    return '選択済み：$count 件';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '$count 件をプレビューして削除';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '$count 件を選択しました。選択内容と残す候補を確認してから削除してください。回復する容量はシステムが決定します。';
  }

  @override
  String scanItemsDeleted(int count) {
    return '$count 件を削除しました。';
  }

  @override
  String get scanIndexingTitle => '写真ライブラリの索引を作成中';

  @override
  String get scanVerifyingTitle => 'オリジナルを検証して完全重複を確認中';

  @override
  String get scanAnalyzingTitle => '端末内の写真プレビューを解析中';

  @override
  String get scanSlowOperationHint =>
      'この操作に時間がかかっています。進行状況を保持してキャンセルし、後で続けられます。';

  @override
  String get scanProgressPreviewHint =>
      '索引作成済みの写真とスクリーンショットを確認できます。ダウンロード待ちや解析失敗の項目を完全重複とみなすことはありません。';

  @override
  String get scanCountConfirming => '確認中';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '索引作成済み $indexed / $total 件';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return '処理済みの写真プレビュー：$attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return '処理済みのオリジナルリソース：$attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return '画像解析完了：$count 件';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'オリジナル検証済み：$count 件';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'ダウンロード待ち：$count 件';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'この段階で未処理：$count 件';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · $seconds 秒待機中';
  }

  @override
  String get swipeKeep => '残す';

  @override
  String get swipeDelete => '削除';

  @override
  String get swipeReviewComplete => '確認完了！';

  @override
  String get swipeRecoveredSpaceHint => '回復する容量はシステムが決定します。';

  @override
  String get swipeUndoChoice => '直前の選択を取り消す';

  @override
  String get swipeBack => '戻る';

  @override
  String get swipeConfirmDeleteTitle => '削除対象にした写真を削除しますか？';

  @override
  String get swipeCancel => 'キャンセル';

  @override
  String get swipeConfirmDelete => '削除を確認';

  @override
  String get swipeNoPhotosDeleted => '写真は削除されていません。操作がキャンセルされたか、失敗した可能性があります。';

  @override
  String get swipeExitTitle => 'この確認を終了しますか？';

  @override
  String get swipeContinueReview => '確認を続ける';

  @override
  String get swipeLeave => '終了';

  @override
  String get swipeSkipRemainingTitle => '残りの写真をスキップしますか？';

  @override
  String get swipeDone => '完了';

  @override
  String swipeDoneCount(int count) {
    return '完了（$count）';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return '削除：$count';
  }

  @override
  String swipeKeepCount(int count) {
    return '残す：$count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '削除する写真 $deleteCount 枚 · 残す写真 $keepCount 枚';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '写真 $count 枚を削除';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return '確認済みの写真 $count 枚を削除します。残したい項目が正しく選択されているか確認してください。';
  }

  @override
  String swipePartialDeleted(int count) {
    return '写真 $count 枚を削除しました。残りの写真は削除していません。';
  }

  @override
  String swipeExitDescription(int count) {
    return '写真 $count 枚を削除対象に指定しました。終了しても削除されません。';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '未確認の写真が $remaining 枚あります。確認を終了し、削除対象にした $deleteCount 枚の削除を確認しますか？';
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
  String get assetReloadPreview => 'プレビューを再読み込み';

  @override
  String get assetSizeUnknown => 'サイズ不明';

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
    return '$count バイト';
  }

  @override
  String get appName => 'クリーンアップマスター';

  @override
  String get nativePhotoRead => '許可した写真と動画にアクセスして、プレビュー・整理し、削除するものを確認できます。';

  @override
  String get nativePhotoAdd => '確認後、圧縮動画のコピーを「写真」に保存します。オリジナルは残ります。';

  @override
  String get nativeContacts => '連絡先にアクセスして、重複する連絡先情報の整理をお手伝いします。';

  @override
  String get nativeTracking => '体験のカスタマイズとサービス改善のためにトラッキングを許可します。';

  @override
  String get serviceSubscriptionsUnavailable =>
      '現在、サブスクリプションを利用できません。後でもう一度お試しください。';

  @override
  String get serviceSubscriptionInitFailed =>
      'サブスクリプションサービスに接続できません。後でもう一度お試しください。';

  @override
  String get serviceNoPlans => '現在、利用可能なプランはありません。後でもう一度お試しください。';

  @override
  String get servicePlansLoadFailed => 'プランを読み込めません。接続を確認して再試行してください。';

  @override
  String get servicePurchaseUnavailable => '現在、購入できません。後でもう一度お試しください。';

  @override
  String get servicePurchaseFailed => '購入が完了しませんでした。後でもう一度お試しください。';

  @override
  String get serviceRestoreUnavailable => '現在、購入を復元できません。後でもう一度お試しください。';

  @override
  String get serviceNoSubscription => '有効な Pro サブスクリプションが見つかりません。';

  @override
  String get serviceRestoreFailed => '購入を復元できません。接続を確認して再試行してください。';

  @override
  String get servicePurchaseCancelled => '購入をキャンセルしました。';

  @override
  String get serviceScanPaused => '一時停止しました。読み込み・解析済みの結果は保持されています。スキャンを続けられます。';

  @override
  String get serviceLimitedLibrary => '許可した写真のみが対象です。ライブラリ全体ではありません。';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'この端末ではオリジナルファイルを解析できません。サイズと完全重複は未検証です。';

  @override
  String get serviceOriginalVerificationNeeded =>
      '端末内のオリジナルを検証してサイズと完全重複を確認してください。大きな項目やクラウド上の項目は未処理のままの場合があります。未検証のサイズは推定しません。';

  @override
  String get serviceReadingIndex => 'ライブラリの索引を読み込み中';

  @override
  String get servicePhotoPermission => '写真へのアクセスが許可されていません。設定で許可して再試行してください。';

  @override
  String get serviceOriginalRoundLimit =>
      '今回の検証は 60 秒に達しました。結果は保持されています。再検証すると未試行の項目から処理します。';

  @override
  String get servicePreviewRoundLimit =>
      '今回のプレビュー処理は 30 秒に達しました。結果は保持されています。続けると未試行の写真から処理します。';

  @override
  String get serviceReadTimeout =>
      '一部の読み込みがタイムアウトしました。現在の結果は保持されています。スキャンを続けられます。';

  @override
  String get serviceReadInterrupted =>
      'ライブラリの読み込みの一部が中断されました。現在の結果は保持されています。スキャンを続けられます。';

  @override
  String get serviceVerifyingOriginals => '端末内のオリジナルを検証中';

  @override
  String get serviceGroupingSimilar => '見た目が似た候補をグループ化中';

  @override
  String get serviceQualityLowDetail => 'プレビューの細部が不足しているため、画質に基づく提案はできません';

  @override
  String get serviceQualityDecodeFailed => 'プレビューを読み取れず、画質を評価していません';

  @override
  String get serviceQualityLowInformation => '画像情報が不足しているため、画質に基づく提案はできません';

  @override
  String get serviceQualityClearEdges => 'プレビューの輪郭がより鮮明';

  @override
  String get serviceQualityLessDetail => 'プレビューの輪郭の細部が少ない';

  @override
  String get serviceQualityDark => '画像が暗め';

  @override
  String get serviceQualityBright => '画像が明るめ';

  @override
  String get serviceQualityBalanced => '全体の明るさのバランスが良好';

  @override
  String get serviceKeepExact => 'オリジナルと編集済みのリソースが完全一致しています。残すコピーの候補です。';

  @override
  String get serviceKeepHigherResolution =>
      'このグループ内で解像度が高いため、残す候補です。写真の内容を確認してください。';

  @override
  String get serviceVideoMissing => '動画が見つかりません。再スキャンしてください。';

  @override
  String get serviceVideoCloud =>
      '動画は iCloud にあります。「写真」でオリジナルをダウンロードして再試行してください。';

  @override
  String get serviceVideoUnreadable => 'この動画を読み込めません。';

  @override
  String get serviceVideoPreviousBusy => '前の圧縮の終了処理中です。少し待って再試行してください。';

  @override
  String get serviceVideoTemporaryUnavailable => '動画の一時保存領域を準備できません。';

  @override
  String get serviceVideoUnsupported => 'この端末では動画圧縮を利用できません。';

  @override
  String get serviceVideoOutputInvalid => '出力先が無効です。オリジナルは残っています。';

  @override
  String get serviceVideoSaveUnknown => '保存したコピーを確認できません。再試行する前に「写真」を確認してください。';

  @override
  String get serviceVideoCancelled => '圧縮をキャンセルしました。';

  @override
  String get serviceVideoOperationBusy => '現在の動画操作を先に完了してください。';

  @override
  String get serviceVideoEmpty => 'オリジナルが空のため圧縮できません。';

  @override
  String get serviceVideoEncodeFailed => '圧縮が完了しませんでした。オリジナルは残っています。';

  @override
  String get serviceVideoNoCopy => '圧縮で別のコピーが作成されませんでした。オリジナルは残っています。';

  @override
  String get serviceVideoNotSmaller => '圧縮動画のサイズが小さくなりませんでした。オリジナルは残っています。';

  @override
  String get serviceVideoDurationMismatch => '圧縮動画の再生時間が一致しません。オリジナルは残っています。';

  @override
  String get serviceVideoValidationFailed => '動画を検証できません。オリジナルは残っています。';

  @override
  String get serviceVideoPreviewFirst => '圧縮を完了し、先にプレビューを確認してください。';

  @override
  String get serviceVideoSaveFailed => 'コピーを保存できません。オリジナルは残っています。再試行してください。';

  @override
  String get serviceVideoGenericFailed =>
      '操作が完了しませんでした。オリジナルは残っています。写真へのアクセスと空き容量を確認して再試行してください。';

  @override
  String get serviceOperationFailed => '操作を完了できません。もう一度お試しください。';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'アクセス可能な $read / $total 件を読み込み済み。';
  }

  @override
  String servicePhotosPending(int count) {
    return '写真 $count 枚が画像解析待ちです。続けると未試行の写真から処理します。クラウド上のオリジナルは自動ダウンロードしません。';
  }

  @override
  String serviceReadingPreviews(int count) {
    return '端末内のプレビューを読み込み中（$count）';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return '端末内のプレビューを解析中（$count）';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons；提案は参考用です';
  }

  @override
  String get scanSwipeIntro => '左にスワイプして削除候補、右にスワイプして残します。最後に確認するまで削除されません。';

  @override
  String get scanSwipeStart => 'スワイプで整理を開始';

  @override
  String get scanDetails => 'スキャンの詳細';

  @override
  String get scanVerificationNeeded => '元のファイルは未確認';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '$verified / $total 件を確認済み';
  }

  @override
  String get scanVerificationExplanation =>
      'ファイルの内容とサイズを確認すると、完全に同じ写真と大きなファイルが表示されます。クラウドの項目は後で処理できます。';

  @override
  String get scanVerifyNow => '重複と大きなファイルを確認';

  @override
  String get scanBrowsePhotos => '先に写真を整理';

  @override
  String get scanSelectAll => 'このカテゴリをすべて選択';

  @override
  String get scanClearSelection => '選択を解除';

  @override
  String get scanKeepOneSelectOthers => 'この写真を残して他を選択';

  @override
  String get scanSelectOthersHint => '残す候補の写真をプレビューしてから、グループの他の写真をまとめて選択します。';

  @override
  String get scanNotChecked => '未確認';

  @override
  String scanPendingCheckCount(int count) {
    return '未確認 $count 件';
  }

  @override
  String get swipeGestureTitle => 'スワイプでかんたん整理';

  @override
  String get swipeGestureDelete => '左にスワイプして削除候補に';

  @override
  String get swipeGestureKeep => '右にスワイプして残す';

  @override
  String get swipeGestureSafety => '写真はまず削除候補リストに入ります。「完了」を押して確認した後にだけ削除されます。';

  @override
  String get swipeGestureHelp => 'スワイプ整理の使い方';

  @override
  String get homeSwipeDescription => '写真を1枚ずつ左右にスワイプ。サムネイルをタップするより素早く整理できます。';

  @override
  String get scanCheckExactPhotos => '完全に同じ写真を確認';

  @override
  String get scanCheckFileSizes => '大きなファイルの容量を確認';
}
