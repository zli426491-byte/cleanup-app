// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get onboardingSmartTitle => '智能清理';

  @override
  String get onboardingSmartSubtitle => '扫描你允许访问的照片与视频\n先预览，再决定保留或删除';

  @override
  String get onboardingPhotosTitle => '照片整理';

  @override
  String get onboardingPhotosSubtitle => '依内容查看重复与相似照片\n保留建议仍需由你逐张确认';

  @override
  String get onboardingSwipeTitle => '滑动整理';

  @override
  String get onboardingSwipeSubtitle => '滑动选择保留或删除\n整理完成后统一确认';

  @override
  String get onboardingChoiceTitle => '由你决定';

  @override
  String get onboardingChoiceSubtitle => '扫描与照片预览免费使用\n删除与视频压缩需 Pro，原片不会自动删除';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingPreparing => '正在准备…';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => '关闭';

  @override
  String get paywallDescription => '解锁照片与视频整理，预览后选择要删除的项目。';

  @override
  String get paywallReloadPlans => '重新加载订阅方案';

  @override
  String get paywallNotConfigured => '目前无法订阅';

  @override
  String get paywallContinue => '继续';

  @override
  String get paywallStoreNotice => '购买会通过 App Store 完成，订阅可在 Apple ID 设置中管理或取消。';

  @override
  String get paywallRestorePurchases => '恢复购买';

  @override
  String get paywallPrivacyPolicy => '隐私政策';

  @override
  String get paywallTerms => '使用条款';

  @override
  String get paywallPurchaseIncomplete => '购买未完成，请稍后再试。';

  @override
  String get paywallRestored => '已恢复 Pro 权限。';

  @override
  String get paywallRestoreNotFound => '找不到可恢复的购买纪录。';

  @override
  String get paywallWeeklyPlan => '周订阅';

  @override
  String get paywallYearlyPlan => '年订阅';

  @override
  String get paywallYearlySubtitle => '全年整理照片与视频';

  @override
  String get paywallWeeklySubtitle => '适合短期照片整理';

  @override
  String get paywallPhotoFeature => '确认后删除你选择的照片与视频';

  @override
  String get paywallVideoFeature => '视频压缩、预览与另存副本';

  @override
  String get paywallSwipeFeature => '用滑动手势快速整理';

  @override
  String get paywallPlansUnavailable => '目前无法加载订阅方案，请确认网络后重新加载。';

  @override
  String get paywallBestValue => '最佳价值';

  @override
  String get videoTitle => '视频压缩';

  @override
  String get videoDescription => '压缩会降低画质并产生新副本。先检查画面、声音与方向，再另存至照片。原片会保留。';

  @override
  String get videoProRequired => '这项功能需要 Pro，请返回清理页查看方案。';

  @override
  String get videoSaving => '正在另存至照片，请等待完成。';

  @override
  String get videoCancelCompression => '取消压缩';

  @override
  String get videoLoadingPreview => '正在加载视频预览…';

  @override
  String get videoCreatePreview => '创建压缩预览';

  @override
  String get videoStorageNotice => '另存副本会暂时增加用量。删除原片及清空「最近删除」后，设备实际可用空间以系统为准。';

  @override
  String get videoViewOriginal => '查看原片';

  @override
  String get videoViewCopy => '查看压缩副本';

  @override
  String get videoSaved => '副本已另存至照片，原片保留。返回首页重新扫描后，可自行选择是否删除原片。';

  @override
  String get videoConfirmSave => '确认副本并另存至照片';

  @override
  String get videoPreviewUnavailable => '预览无法播放，请重试。原片已保留。';

  @override
  String get videoPlaybackUnavailable => '视频暂时无法播放，请重新加载预览。';

  @override
  String get videoOperationIncomplete => '操作未完成，原片已保留。请检查照片权限、可用空间后重试。';

  @override
  String get videoPauseOriginal => '原片：暂停';

  @override
  String get videoPlayOriginal => '原片：播放';

  @override
  String get videoPauseCopy => '压缩副本：暂停';

  @override
  String get videoPlayCopy => '压缩副本：播放';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return '版本 $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return '正在准备／压缩视频 $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return '原片：$size';
  }

  @override
  String videoCopySize(String size) {
    return '副本：$size';
  }

  @override
  String videoSizeDifference(String size) {
    return '文件大小差异：$size';
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
  String get homeStorageUnavailable => '设备容量请至设置查看；此处整理可访问的照片与视频。';

  @override
  String get homeViewIndexedPhotos => '查看已读取照片';

  @override
  String get homeViewIndexedScreenshots => '查看已读取截屏';

  @override
  String get homeCleanupTools => '清理工具';

  @override
  String get homeQuickActions => '快速操作';

  @override
  String get homeAppName => '清理大师';

  @override
  String get homeSubtitle => '先预览，再整理照片与视频';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => '已使用';

  @override
  String get homeUsedLegend => '已用';

  @override
  String get homeAvailableLegend => '可用';

  @override
  String get homeStartScanHint => '尚未扫描，点击下方按钮开始';

  @override
  String get homeScanning => '扫描中...';

  @override
  String get homeDeleting => '删除中...';

  @override
  String get homeResumeScan => '继续扫描并保留进度';

  @override
  String get homeScanAll => '扫描全部可访问照片与视频';

  @override
  String get homePreviewOrganize => '预览并整理';

  @override
  String get homeVerifyOriginals => '验证本机原始资源：确认完全重复和文件大小';

  @override
  String get homeRetryPending => '继续扫描／重试待处理项目';

  @override
  String get homeExactDuplicates => '完全重复照片';

  @override
  String get homeSimilarPhotos => '视觉相似照片';

  @override
  String get homeNotScanned => '尚未扫描';

  @override
  String get homePendingAnalysis => '尚待画面分析';

  @override
  String get homeNoneAnalyzed => '已分析项目中未发现';

  @override
  String get homeScreenshots => '屏幕截图';

  @override
  String get homeLargeFiles => '大型文件';

  @override
  String get homeNoneFound => '未发现';

  @override
  String get homePendingVerification => '尚待原始素材验证';

  @override
  String get homeNoneVerified => '已验证项目中未发现';

  @override
  String get homeNeedsReview => '待确认';

  @override
  String get homeCanReview => '可查看';

  @override
  String get homeScanStatus => '扫描';

  @override
  String get homeDoneStatus => '已完成 ✓';

  @override
  String get homePreviewPhotos => '预览照片';

  @override
  String get homeChooseKeep => '选择要保留的项目';

  @override
  String get navHome => '首页';

  @override
  String get navClean => '清理';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLoading => '读取中';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => '免费方案';

  @override
  String get settingsUpgrade => '升级';

  @override
  String get settingsStorage => '存储空间';

  @override
  String get settingsStorageTotal => '总计';

  @override
  String get settingsStorageUsed => '已使用';

  @override
  String get settingsStorageAvailable => '可用';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsProcessingSubscription => '正在处理订阅…';

  @override
  String get settingsRestorePurchases => '恢复购买';

  @override
  String get settingsRestoredPro => '已恢复 Pro 订阅。';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTerms => '使用条款';

  @override
  String get settingsRateApp => '给我们评分';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsChooseLanguage => '选择语言';

  @override
  String get settingsSystemLanguage => '跟随系统语言';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return '共 $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个项目',
      one: '1 个项目',
    );
    return '已读取 $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '已读取 $count / $total 个可访问项目';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return '视觉分析成功 $analyzed 个，原始素材已验证 $verified 个。保留建议可撤回，删除由你决定。';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片',
      one: '1 张照片',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片（部分结果）',
      one: '1 张照片（部分结果）',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个项目',
      one: '1 个项目',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已验证 $count 张照片；仍有待验证项目',
      one: '已验证 1 张照片；仍有待验证项目',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已验证 $count 个项目；仍有待验证项目',
      one: '已验证 1 个项目；仍有待验证项目',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError => '无法保存语言设置，请重试。';

  @override
  String get scanSmartTitle => '智能清理';

  @override
  String get scanCancelKeepProgress => '取消扫描并保留进度';

  @override
  String get scanSwipeCleanup => '滑动清理';

  @override
  String get scanSortFileSize => '文件大小';

  @override
  String get scanSortNewest => '最新';

  @override
  String get scanStartAlbumTitle => '开始扫描图库';

  @override
  String get scanIncompleteTitle => '扫描未完成';

  @override
  String get scanStartAlbumDescription =>
      '先分析预览，查看相似照片。进入完全重复或大文件分类时，再分别检查内容与容量。不会自动删除任何项目。';

  @override
  String get scanContinue => '继续扫描';

  @override
  String get scanStart => '开始扫描';

  @override
  String get scanPreviewWhileRunning => '照片与截屏可先预览；扫描期间暂停选取、删除及视频压缩。';

  @override
  String get scanExactDescription => '完全重复仅包括原始资源已验证的项目。保留建议可以撤回。';

  @override
  String get scanSimilarDescription => '分析本机预览后会逐步显示视觉相似候选，内容可能不同。保留建议仅供参考。';

  @override
  String get scanLargeDescription => '按已验证的资源大小排序。文件大小与实际释放的空间可能不同，释放空间以系统为准。';

  @override
  String get scanManualDeleteDescription => '只会删除你手动勾选并再次确认的项目。';

  @override
  String get scanVerifyOriginals => '验证本机原始资源：确认完全重复和文件大小';

  @override
  String get scanResumePending => '继续扫描／重试待处理项目';

  @override
  String get scanKeepReasonDefault => '这是本组中建议保留的照片。';

  @override
  String get scanRestoreKeepSuggestion => '重新显示保留建议';

  @override
  String get scanDismissKeepSuggestion => '撤回保留建议';

  @override
  String get scanKeepManualHint => '保留建议不会自动勾选；点击缩略图标记删除。';

  @override
  String get scanEmptyUnverified => '部分原始资源仍待验证，尚不能确定完全重复或大文件。你可以先预览照片与截图。';

  @override
  String get scanEmptyVisualPending => '照片画面仍有待处理项目，视觉相似结果会逐步整理。照片与截屏可先预览。';

  @override
  String get scanEmptyIndexing => '图库目录仍在读取，此分类将随读取进度更新。';

  @override
  String get scanEmptyCategory => '目前已完成分析或验证的项目中没有这个分类。';

  @override
  String get scanKeepBadge => '建议保留';

  @override
  String get scanZoomPreview => '放大预览';

  @override
  String get scanCompressVideo => '压缩此视频';

  @override
  String get scanContentPending => '内容待分析';

  @override
  String get scanBackToCompare => '返回继续比较';

  @override
  String get scanConfirmDeleteTitle => '确认要删除这些项目吗？';

  @override
  String get scanCancel => '取消';

  @override
  String get scanNoItemsDeleted => '未删除任何项目，可能已取消或删除未成功。';

  @override
  String get scanConfirmDelete => '确认删除';

  @override
  String get scanCategoryPhotos => '照片';

  @override
  String get scanCategoryExact => '完全重复';

  @override
  String get scanCategorySimilar => '视觉相似候选';

  @override
  String get scanCategoryScreenshots => '截屏';

  @override
  String get scanCategoryVideos => '视频';

  @override
  String get scanCategoryLarge => '大文件';

  @override
  String scanExactGroupCount(int count) {
    return '完全重复：$count 张照片';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return '视觉相似候选：$count 张照片';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return '建议保留：$reason';
  }

  @override
  String scanSelectedCount(int count) {
    return '已选择 $count 个项目';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '预览并删除 $count 个项目';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '共 $count 个项目。请确认选取内容与保留建议后再删除；实际回收空间以系统为准。';
  }

  @override
  String scanItemsDeleted(int count) {
    return '已删除 $count 个项目。';
  }

  @override
  String get scanIndexingTitle => '读取图库目录';

  @override
  String get scanVerifyingTitle => '正在检查原始文件';

  @override
  String get scanAnalyzingTitle => '分析本机照片画面';

  @override
  String get scanSlowOperationHint => '此项目读取较慢，可先取消并保留进度，稍后续扫。';

  @override
  String get scanProgressPreviewHint => '你可以查看已读取的照片与截图。待下载或分析失败的项目不会被视为完全重复。';

  @override
  String get scanCountConfirming => '确认中';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '已读取 $indexed / $total 个项目';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return '照片画面已处理 $attempted / $total 张';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return '原始素材已处理 $attempted / $total 个项目';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return '视觉分析成功 $count 个';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return '原始素材已验证 $count 个';
  }

  @override
  String scanCloudPendingCount(int count) {
    return '待下载 $count 个';
  }

  @override
  String scanStageRemainingCount(int count) {
    return '本阶段尚未处理 $count 个';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · 已等待 $seconds 秒';
  }

  @override
  String get swipeKeep => '保留';

  @override
  String get swipeDelete => '删除';

  @override
  String get swipeReviewComplete => '查看完成！';

  @override
  String get swipeRecoveredSpaceHint => '删除后的空间以系统为准';

  @override
  String get swipeUndoChoice => '撤回上一个选择';

  @override
  String get swipeBack => '返回';

  @override
  String get swipeConfirmDeleteTitle => '确认删除已标记的照片？';

  @override
  String get swipeCancel => '取消';

  @override
  String get swipeConfirmDelete => '确认删除';

  @override
  String get swipeNoPhotosDeleted => '未删除任何照片，可能已取消或删除未成功。';

  @override
  String get swipeExitTitle => '确定离开？';

  @override
  String get swipeContinueReview => '继续查看';

  @override
  String get swipeLeave => '离开';

  @override
  String get swipeSkipRemainingTitle => '跳过剩余照片？';

  @override
  String get swipeDone => '完成';

  @override
  String swipeDoneCount(int count) {
    return '完成 ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return '$count 删除';
  }

  @override
  String swipeKeepCount(int count) {
    return '$count 保留';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount 张要删除 · $keepCount 张保留';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '删除 $count 张照片';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return '已选择待删照片：$count 张。想保留的照片请移出待删清单。';
  }

  @override
  String swipePartialDeleted(int count) {
    return '已删除 $count 张，剩余照片尚未删除。';
  }

  @override
  String swipeExitDescription(int count) {
    return '你已标记 $count 张照片待删除，离开不会删除这些照片。';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '还有 $remaining 张照片未查看。结束查看并确认删除已标记的 $deleteCount 张照片？';
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
  String get assetReloadPreview => '重新加载预览';

  @override
  String get assetSizeUnknown => '文件大小未知';

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
    return '$count 字节';
  }

  @override
  String get appName => '清理大师';

  @override
  String get nativePhotoRead => '访问你允许的照片与视频，供预览、整理及由你确认后删除。';

  @override
  String get nativePhotoAdd => '经你确认后，将压缩视频副本另存至照片。原片会保留。';

  @override
  String get nativeContacts => '访问你的联系人，以协助整理重复的联系数据。';

  @override
  String get nativeTracking => '允许追踪，以提供个人化体验并改善服务。';

  @override
  String get serviceSubscriptionsUnavailable => '订阅功能暂时不可用，请稍后再试。';

  @override
  String get serviceSubscriptionInitFailed => '无法连接订阅服务，请稍后再试。';

  @override
  String get serviceNoPlans => '目前没有可用的订阅方案，请稍后再试。';

  @override
  String get servicePlansLoadFailed => '无法加载方案，请检查网络后再试。';

  @override
  String get servicePurchaseUnavailable => '目前无法购买，请稍后再试。';

  @override
  String get servicePurchaseFailed => '购买未完成，请稍后再试。';

  @override
  String get serviceRestoreUnavailable => '目前无法恢复购买，请稍后再试。';

  @override
  String get serviceNoSubscription => '找不到有效的 Pro 订阅纪录。';

  @override
  String get serviceRestoreFailed => '恢复购买失败，请检查网络后再试。';

  @override
  String get servicePurchaseCancelled => '已取消购买。';

  @override
  String get serviceScanPaused => '已暂停，已读取与分析的结果已保留，可继续扫描。';

  @override
  String get serviceLimitedLibrary => '仅整理你允许访问的照片，未读取整个图库。';

  @override
  String get serviceNativeAnalysisUnavailable => '此设备无法分析原始文件。文件大小和完全重复尚未验证。';

  @override
  String get serviceOriginalVerificationNeeded =>
      '请验证本机原始资源，以确认文件大小和完全重复。大文件或云端项目可能仍待处理；未验证的大小不会估算。';

  @override
  String get serviceReadingIndex => '读取图库索引';

  @override
  String get servicePhotoPermission => '尚未取得图库权限，请在设置中允许访问照片后重试。';

  @override
  String get serviceOriginalRoundLimit =>
      '本轮原始素材验证已达 60 秒，结果已保留；再次验证会先处理未尝试项目。';

  @override
  String get servicePreviewRoundLimit => '本轮本机预览分析已达 30 秒，结果已保留；继续扫描会先处理未尝试照片。';

  @override
  String get serviceReadTimeout => '部分读取超时，当前结果已保留，可以继续扫描。';

  @override
  String get serviceReadInterrupted => '部分图库读取中断，已保留目前结果，可继续扫描。';

  @override
  String get serviceVerifyingOriginals => '验证本机原始素材';

  @override
  String get serviceGroupingSimilar => '整理视觉相似候选';

  @override
  String get serviceQualityLowDetail => '缩略图较粗糙，未提供画面品质建议';

  @override
  String get serviceQualityDecodeFailed => '无法解码预览，未评估画面品质';

  @override
  String get serviceQualityLowInformation => '画面信息不足，不提供品质保留建议';

  @override
  String get serviceQualityClearEdges => '缩略图边缘较清楚';

  @override
  String get serviceQualityLessDetail => '缩略图边缘细节较少';

  @override
  String get serviceQualityDark => '整体画面偏暗';

  @override
  String get serviceQualityBright => '整体画面偏亮';

  @override
  String get serviceQualityBalanced => '整体亮度适中';

  @override
  String get serviceKeepExact => '已确认原始及编辑素材内容完全相同，建议保留这一份';

  @override
  String get serviceKeepHigherResolution => '此群组中分辨率较高，建议先保留；仍需确认照片内容';

  @override
  String get serviceVideoMissing => '找不到这段视频，请重新扫描。';

  @override
  String get serviceVideoCloud => '视频尚在 iCloud，请先在照片 App 下载原片后重试。';

  @override
  String get serviceVideoUnreadable => '视频无法读取。';

  @override
  String get serviceVideoPreviousBusy => '前一次压缩仍在结束，请稍后重试。';

  @override
  String get serviceVideoTemporaryUnavailable => '无法取得视频暂存位置。';

  @override
  String get serviceVideoUnsupported => '此设备尚未支持视频压缩。';

  @override
  String get serviceVideoOutputInvalid => '压缩输出位置不符，原片已保留。';

  @override
  String get serviceVideoSaveUnknown => '无法确认副本已保存，请先到照片应用检查，再决定是否重试。';

  @override
  String get serviceVideoCancelled => '已取消压缩。';

  @override
  String get serviceVideoOperationBusy => '请先完成目前的视频操作。';

  @override
  String get serviceVideoEmpty => '原片为空，无法压缩。';

  @override
  String get serviceVideoEncodeFailed => '压缩未完成，原片已保留。';

  @override
  String get serviceVideoNoCopy => '压缩未产生独立副本，原片已保留。';

  @override
  String get serviceVideoNotSmaller => '这段视频压缩后没有变小，原片已保留。';

  @override
  String get serviceVideoDurationMismatch => '压缩后长度不符，原片已保留。';

  @override
  String get serviceVideoValidationFailed => '无法验证视频内容，原片已保留。';

  @override
  String get serviceVideoPreviewFirst => '请先完成压缩与预览。';

  @override
  String get serviceVideoSaveFailed => '另存失败，原片已保留，请重试。';

  @override
  String get serviceVideoGenericFailed => '操作未完成，原片已保留。请检查照片权限、可用空间后重试。';

  @override
  String get serviceOperationFailed => '操作未完成，请重试。';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '已读取 $read / $total 个可访问项目。';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count 张照片仍待视觉分析；继续扫描会先处理尚未尝试的照片，不自动下载云端素材。';
  }

  @override
  String serviceReadingPreviews(int count) {
    return '读取本机预览（$count 张）';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return '分析本机预览（$count 张）';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons；仅供保留参考';
  }

  @override
  String get scanSwipeIntro => '左滑标记删除，右滑保留；最后确认才删除。';

  @override
  String get scanSwipeStart => '开始滑动整理';

  @override
  String get scanDetails => '扫描详情';

  @override
  String get scanVerificationNeeded => '尚未检查原始文件';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '已检查 $verified / $total 个';
  }

  @override
  String get scanVerificationExplanation =>
      '先检查文件内容与大小，才能显示真正重复和大文件。云端项目可稍后再处理。';

  @override
  String get scanOriginalsAfterPreview =>
      '照片预览扫描完成后，才会检查完全重复和大文件的原始素材；也可先暂停，整理已找到的项目。';

  @override
  String get scanVerifyNow => '检查真正重复与大文件';

  @override
  String get scanBrowsePhotos => '先整理照片';

  @override
  String get scanSelectAll => '全选本分类';

  @override
  String get scanClearSelection => '清除选择';

  @override
  String get scanKeepOneSelectOthers => '保留这张，选择其他已载入预览的照片';

  @override
  String scanGroupReadyOthers(int ready, int total) {
    return '本组其他照片已载入预览 $ready/$total 张';
  }

  @override
  String get scanSelectOthersHint => '先预览建议保留的照片，再一次选中这组其他照片。';

  @override
  String get scanNotChecked => '待检查';

  @override
  String scanPendingCheckCount(int count) {
    return '待检查 $count 个';
  }

  @override
  String get swipeMultiSelectTitle => '批量选择项目';

  @override
  String get swipeDragSelectHint => '长按并滑过缩略图，可批量选择已载入预览的照片。';

  @override
  String swipeMarkSelectedForDeletion(int count) {
    return '将 $count 张标记为待删除';
  }

  @override
  String get swipeGestureTitle => '快速滑动整理';

  @override
  String get swipeGestureDelete => '左滑标记删除';

  @override
  String get swipeGestureKeep => '右滑保留';

  @override
  String get swipeGestureSafety => '照片会先加入待删列表；点击完成并确认后才删除。';

  @override
  String get swipeGestureHelp => '如何滑动整理';

  @override
  String get homeSwipeDescription => '逐张左右滑动，比点选缩略图更快。';

  @override
  String get scanCheckExactPhotos => '检查真正重复照片';

  @override
  String get scanCheckFileSizes => '检查大文件容量';

  @override
  String get reviewDeleteTitle => '检查待删项目';

  @override
  String get reviewRemove => '移出待删清单';

  @override
  String get reviewUnavailable => '无法载入预览。请重试或移除此项目。';

  @override
  String reviewUnseenCount(int count) {
    return '删除前还需预览的项目：$count 个';
  }

  @override
  String get reviewAllVersions => '已选中这组的所有版本。确定全部删除吗？';

  @override
  String get reviewDeleteAllVersions => '删除所有版本';

  @override
  String reviewConfirmCount(int count) {
    return '确认删除 · $count 个';
  }

  @override
  String swipeResumeReview(int count) {
    return '继续上次整理 · 已查看 $count 个';
  }

  @override
  String get swipeResetReview => '重新开始';

  @override
  String swipeBatchSize(int count) {
    return '每批查看 $count 个';
  }

  @override
  String get swipeAllMonths => '所有月份';

  @override
  String get swipeReviewBatch => '选择月份或批次';

  @override
  String get assetVideoLoading => '正在载入原始视频…';

  @override
  String get assetVideoUnavailable => '无法载入原始视频。请先在照片中下载，再重试。';

  @override
  String get homePermissionTitle => '需要照片访问权限';

  @override
  String get homePermissionDescription => '请在设置中允许访问照片，才能扫描与查看。不会自动删除任何项目。';

  @override
  String get homeOpenSettings => '打开设置';

  @override
  String get homeManagePhotoAccess => '管理照片访问权限';

  @override
  String get homeReviewReady => '整理已载入照片';

  @override
  String get homeContinueAnalysis => '继续分析照片';

  @override
  String get homeScanDetails => '扫描详情';

  @override
  String get scanCheckingExactTitle => '正在检查完全重复照片';

  @override
  String get scanCheckingSizesTitle => '正在检查文件容量';

  @override
  String scanRoundProgress(int total, int completed) {
    return '已处理 $completed / $total';
  }

  @override
  String get scanPauseReview => '暂停检查，先整理';

  @override
  String get scanSelectionHint => '勾选加入待删；点击预览可查看内容。';

  @override
  String get scanPreviewNotReady => '请先载入预览再选择';

  @override
  String scanUnreadableExcluded(int count) {
    return '有 $count 个预览尚未载入，未加入选择';
  }

  @override
  String get scanKeepThis => '保留这张';

  @override
  String get scanPreviewMore => '载入更多照片';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return '已确认文件容量：$size · 已检查 $count 个项目';
  }

  @override
  String homePendingSizes(int count) {
    return '另有 $count 个项目容量待确认';
  }

  @override
  String get scanReviewChanged => '照片或权限已更新，请重新检查待删清单。';

  @override
  String get paywallFreePreviewNote => '照片分组、预览与滑动标记均免费。Pro 可确认删除项目及压缩视频。';

  @override
  String paywallSubscribeWeekly(String price) {
    return '每周订阅 · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return '每年订阅 · $price';
  }

  @override
  String get paywallSubscribe => '订阅';

  @override
  String paywallWeeklyRenewal(String price) {
    return '除非取消，否则每周以 $price 自动续订。请在 App Store 查看最终条款。';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return '除非取消，否则每年以 $price 自动续订。请在 App Store 查看最终条款。';
  }

  @override
  String get paywallRenewalGeneric => '除非取消，否则自动续订。确认前请在 App Store 查看收费周期与金额。';

  @override
  String get paywallLoadingPlans => '正在载入订阅方案…';

  @override
  String get paywallWaitingForStore => '正在等待 App Store 确认…';

  @override
  String get paywallRestoring => '正在恢复购买…';

  @override
  String get settingsCheckingSubscription => '正在检查订阅…';

  @override
  String get settingsSubscriptionUnknown => '无法确认订阅状态';

  @override
  String get settingsManageSubscription => '管理订阅';

  @override
  String get settingsManageUnavailable => '无法打开订阅管理。请在商店账户设置中打开订阅。';

  @override
  String get onboardingStartFree => '免费开始';

  @override
  String get swipeCheckpointSaveError => '无法保存整理进度。仍可继续整理，但下次可能无法接续。';

  @override
  String swipeCheckpointLimit(int count) {
    return '此设备最多保留最近 $count 个项目的整理选择';
  }

  @override
  String get scanSelectLoaded => '选择已载入预览';

  @override
  String get homePhotoScopeChanged => '可访问的照片范围可能已变更，请重新扫描。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get onboardingSmartTitle => '智能清理';

  @override
  String get onboardingSmartSubtitle => '扫描你允许访问的照片与视频\n先预览，再决定保留或删除';

  @override
  String get onboardingPhotosTitle => '照片整理';

  @override
  String get onboardingPhotosSubtitle => '依内容查看重复与相似照片\n保留建议仍需由你逐张确认';

  @override
  String get onboardingSwipeTitle => '滑动整理';

  @override
  String get onboardingSwipeSubtitle => '滑动选择保留或删除\n整理完成后统一确认';

  @override
  String get onboardingChoiceTitle => '由你决定';

  @override
  String get onboardingChoiceSubtitle => '扫描与照片预览免费使用\n删除与视频压缩需 Pro，原片不会自动删除';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingPreparing => '正在准备…';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => '关闭';

  @override
  String get paywallDescription => '解锁照片与视频整理，预览后选择要删除的项目。';

  @override
  String get paywallReloadPlans => '重新加载订阅方案';

  @override
  String get paywallNotConfigured => '目前无法订阅';

  @override
  String get paywallContinue => '继续';

  @override
  String get paywallStoreNotice => '购买会通过 App Store 完成，订阅可在 Apple ID 设置中管理或取消。';

  @override
  String get paywallRestorePurchases => '恢复购买';

  @override
  String get paywallPrivacyPolicy => '隐私政策';

  @override
  String get paywallTerms => '使用条款';

  @override
  String get paywallPurchaseIncomplete => '购买未完成，请稍后再试。';

  @override
  String get paywallRestored => '已恢复 Pro 权限。';

  @override
  String get paywallRestoreNotFound => '找不到可恢复的购买纪录。';

  @override
  String get paywallWeeklyPlan => '周订阅';

  @override
  String get paywallYearlyPlan => '年订阅';

  @override
  String get paywallYearlySubtitle => '全年整理照片与视频';

  @override
  String get paywallWeeklySubtitle => '适合短期照片整理';

  @override
  String get paywallPhotoFeature => '确认后删除你选择的照片与视频';

  @override
  String get paywallVideoFeature => '视频压缩、预览与另存副本';

  @override
  String get paywallSwipeFeature => '用滑动手势快速整理';

  @override
  String get paywallPlansUnavailable => '目前无法加载订阅方案，请确认网络后重新加载。';

  @override
  String get paywallBestValue => '最佳价值';

  @override
  String get videoTitle => '视频压缩';

  @override
  String get videoDescription => '压缩会降低画质并产生新副本。先检查画面、声音与方向，再另存至照片。原片会保留。';

  @override
  String get videoProRequired => '这项功能需要 Pro，请返回清理页查看方案。';

  @override
  String get videoSaving => '正在另存至照片，请等待完成。';

  @override
  String get videoCancelCompression => '取消压缩';

  @override
  String get videoLoadingPreview => '正在加载视频预览…';

  @override
  String get videoCreatePreview => '创建压缩预览';

  @override
  String get videoStorageNotice => '另存副本会暂时增加用量。删除原片及清空「最近删除」后，设备实际可用空间以系统为准。';

  @override
  String get videoViewOriginal => '查看原片';

  @override
  String get videoViewCopy => '查看压缩副本';

  @override
  String get videoSaved => '副本已另存至照片，原片保留。返回首页重新扫描后，可自行选择是否删除原片。';

  @override
  String get videoConfirmSave => '确认副本并另存至照片';

  @override
  String get videoPreviewUnavailable => '预览无法播放，请重试。原片已保留。';

  @override
  String get videoPlaybackUnavailable => '视频暂时无法播放，请重新加载预览。';

  @override
  String get videoOperationIncomplete => '操作未完成，原片已保留。请检查照片权限、可用空间后重试。';

  @override
  String get videoPauseOriginal => '原片：暂停';

  @override
  String get videoPlayOriginal => '原片：播放';

  @override
  String get videoPauseCopy => '压缩副本：暂停';

  @override
  String get videoPlayCopy => '压缩副本：播放';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return '版本 $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return '正在准备／压缩视频 $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return '原片：$size';
  }

  @override
  String videoCopySize(String size) {
    return '副本：$size';
  }

  @override
  String videoSizeDifference(String size) {
    return '文件大小差异：$size';
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
  String get homeStorageUnavailable => '设备容量请至设置查看；此处整理可访问的照片与视频。';

  @override
  String get homeViewIndexedPhotos => '查看已读取照片';

  @override
  String get homeViewIndexedScreenshots => '查看已读取截屏';

  @override
  String get homeCleanupTools => '清理工具';

  @override
  String get homeQuickActions => '快速操作';

  @override
  String get homeAppName => '清理大师';

  @override
  String get homeSubtitle => '先预览，再整理照片与视频';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => '已使用';

  @override
  String get homeUsedLegend => '已用';

  @override
  String get homeAvailableLegend => '可用';

  @override
  String get homeStartScanHint => '尚未扫描，点击下方按钮开始';

  @override
  String get homeScanning => '扫描中...';

  @override
  String get homeDeleting => '删除中...';

  @override
  String get homeResumeScan => '继续扫描并保留进度';

  @override
  String get homeScanAll => '扫描全部可访问照片与视频';

  @override
  String get homePreviewOrganize => '预览并整理';

  @override
  String get homeVerifyOriginals => '验证本机原始资源：确认完全重复和文件大小';

  @override
  String get homeRetryPending => '继续扫描／重试待处理项目';

  @override
  String get homeExactDuplicates => '完全重复照片';

  @override
  String get homeSimilarPhotos => '视觉相似照片';

  @override
  String get homeNotScanned => '尚未扫描';

  @override
  String get homePendingAnalysis => '尚待画面分析';

  @override
  String get homeNoneAnalyzed => '已分析项目中未发现';

  @override
  String get homeScreenshots => '屏幕截图';

  @override
  String get homeLargeFiles => '大型文件';

  @override
  String get homeNoneFound => '未发现';

  @override
  String get homePendingVerification => '尚待原始素材验证';

  @override
  String get homeNoneVerified => '已验证项目中未发现';

  @override
  String get homeNeedsReview => '待确认';

  @override
  String get homeCanReview => '可查看';

  @override
  String get homeScanStatus => '扫描';

  @override
  String get homeDoneStatus => '已完成 ✓';

  @override
  String get homePreviewPhotos => '预览照片';

  @override
  String get homeChooseKeep => '选择要保留的项目';

  @override
  String get navHome => '首页';

  @override
  String get navClean => '清理';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLoading => '读取中';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => '免费方案';

  @override
  String get settingsUpgrade => '升级';

  @override
  String get settingsStorage => '存储空间';

  @override
  String get settingsStorageTotal => '总计';

  @override
  String get settingsStorageUsed => '已使用';

  @override
  String get settingsStorageAvailable => '可用';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsProcessingSubscription => '正在处理订阅…';

  @override
  String get settingsRestorePurchases => '恢复购买';

  @override
  String get settingsRestoredPro => '已恢复 Pro 订阅。';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTerms => '使用条款';

  @override
  String get settingsRateApp => '给我们评分';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsChooseLanguage => '选择语言';

  @override
  String get settingsSystemLanguage => '跟随系统语言';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return '共 $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个项目',
      one: '1 个项目',
    );
    return '已读取 $_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '已读取 $count / $total 个可访问项目';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return '视觉分析成功 $analyzed 个，原始素材已验证 $verified 个。保留建议可撤回，删除由你决定。';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片',
      one: '1 张照片',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片（部分结果）',
      one: '1 张照片（部分结果）',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个项目',
      one: '1 个项目',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已验证 $count 张照片；仍有待验证项目',
      one: '已验证 1 张照片；仍有待验证项目',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已验证 $count 个项目；仍有待验证项目',
      one: '已验证 1 个项目；仍有待验证项目',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError => '无法保存语言设置，请重试。';

  @override
  String get scanSmartTitle => '智能清理';

  @override
  String get scanCancelKeepProgress => '取消扫描并保留进度';

  @override
  String get scanSwipeCleanup => '滑动清理';

  @override
  String get scanSortFileSize => '文件大小';

  @override
  String get scanSortNewest => '最新';

  @override
  String get scanStartAlbumTitle => '开始扫描图库';

  @override
  String get scanIncompleteTitle => '扫描未完成';

  @override
  String get scanStartAlbumDescription =>
      '先分析预览，查看相似照片。进入完全重复或大文件分类时，再分别检查内容与容量。不会自动删除任何项目。';

  @override
  String get scanContinue => '继续扫描';

  @override
  String get scanStart => '开始扫描';

  @override
  String get scanPreviewWhileRunning => '照片与截屏可先预览；扫描期间暂停选取、删除及视频压缩。';

  @override
  String get scanExactDescription => '完全重复仅包括原始资源已验证的项目。保留建议可以撤回。';

  @override
  String get scanSimilarDescription => '分析本机预览后会逐步显示视觉相似候选，内容可能不同。保留建议仅供参考。';

  @override
  String get scanLargeDescription => '按已验证的资源大小排序。文件大小与实际释放的空间可能不同，释放空间以系统为准。';

  @override
  String get scanManualDeleteDescription => '只会删除你手动勾选并再次确认的项目。';

  @override
  String get scanVerifyOriginals => '验证本机原始资源：确认完全重复和文件大小';

  @override
  String get scanResumePending => '继续扫描／重试待处理项目';

  @override
  String get scanKeepReasonDefault => '这是本组中建议保留的照片。';

  @override
  String get scanRestoreKeepSuggestion => '重新显示保留建议';

  @override
  String get scanDismissKeepSuggestion => '撤回保留建议';

  @override
  String get scanKeepManualHint => '保留建议不会自动勾选；点击缩略图标记删除。';

  @override
  String get scanEmptyUnverified => '部分原始资源仍待验证，尚不能确定完全重复或大文件。你可以先预览照片与截图。';

  @override
  String get scanEmptyVisualPending => '照片画面仍有待处理项目，视觉相似结果会逐步整理。照片与截屏可先预览。';

  @override
  String get scanEmptyIndexing => '图库目录仍在读取，此分类将随读取进度更新。';

  @override
  String get scanEmptyCategory => '目前已完成分析或验证的项目中没有这个分类。';

  @override
  String get scanKeepBadge => '建议保留';

  @override
  String get scanZoomPreview => '放大预览';

  @override
  String get scanCompressVideo => '压缩此视频';

  @override
  String get scanContentPending => '内容待分析';

  @override
  String get scanBackToCompare => '返回继续比较';

  @override
  String get scanConfirmDeleteTitle => '确认要删除这些项目吗？';

  @override
  String get scanCancel => '取消';

  @override
  String get scanNoItemsDeleted => '未删除任何项目，可能已取消或删除未成功。';

  @override
  String get scanConfirmDelete => '确认删除';

  @override
  String get scanCategoryPhotos => '照片';

  @override
  String get scanCategoryExact => '完全重复';

  @override
  String get scanCategorySimilar => '视觉相似候选';

  @override
  String get scanCategoryScreenshots => '截屏';

  @override
  String get scanCategoryVideos => '视频';

  @override
  String get scanCategoryLarge => '大文件';

  @override
  String scanExactGroupCount(int count) {
    return '完全重复：$count 张照片';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return '视觉相似候选：$count 张照片';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return '建议保留：$reason';
  }

  @override
  String scanSelectedCount(int count) {
    return '已选择 $count 个项目';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '预览并删除 $count 个项目';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '共 $count 个项目。请确认选取内容与保留建议后再删除；实际回收空间以系统为准。';
  }

  @override
  String scanItemsDeleted(int count) {
    return '已删除 $count 个项目。';
  }

  @override
  String get scanIndexingTitle => '读取图库目录';

  @override
  String get scanVerifyingTitle => '正在检查原始文件';

  @override
  String get scanAnalyzingTitle => '分析本机照片画面';

  @override
  String get scanSlowOperationHint => '此项目读取较慢，可先取消并保留进度，稍后续扫。';

  @override
  String get scanProgressPreviewHint => '你可以查看已读取的照片与截图。待下载或分析失败的项目不会被视为完全重复。';

  @override
  String get scanCountConfirming => '确认中';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '已读取 $indexed / $total 个项目';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return '照片画面已处理 $attempted / $total 张';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return '原始素材已处理 $attempted / $total 个项目';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return '视觉分析成功 $count 个';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return '原始素材已验证 $count 个';
  }

  @override
  String scanCloudPendingCount(int count) {
    return '待下载 $count 个';
  }

  @override
  String scanStageRemainingCount(int count) {
    return '本阶段尚未处理 $count 个';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · 已等待 $seconds 秒';
  }

  @override
  String get swipeKeep => '保留';

  @override
  String get swipeDelete => '删除';

  @override
  String get swipeReviewComplete => '查看完成！';

  @override
  String get swipeRecoveredSpaceHint => '删除后的空间以系统为准';

  @override
  String get swipeUndoChoice => '撤回上一个选择';

  @override
  String get swipeBack => '返回';

  @override
  String get swipeConfirmDeleteTitle => '确认删除已标记的照片？';

  @override
  String get swipeCancel => '取消';

  @override
  String get swipeConfirmDelete => '确认删除';

  @override
  String get swipeNoPhotosDeleted => '未删除任何照片，可能已取消或删除未成功。';

  @override
  String get swipeExitTitle => '确定离开？';

  @override
  String get swipeContinueReview => '继续查看';

  @override
  String get swipeLeave => '离开';

  @override
  String get swipeSkipRemainingTitle => '跳过剩余照片？';

  @override
  String get swipeDone => '完成';

  @override
  String swipeDoneCount(int count) {
    return '完成 ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return '$count 删除';
  }

  @override
  String swipeKeepCount(int count) {
    return '$count 保留';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount 张要删除 · $keepCount 张保留';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '删除 $count 张照片';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return '已选择待删照片：$count 张。想保留的照片请移出待删清单。';
  }

  @override
  String swipePartialDeleted(int count) {
    return '已删除 $count 张，剩余照片尚未删除。';
  }

  @override
  String swipeExitDescription(int count) {
    return '你已标记 $count 张照片待删除，离开不会删除这些照片。';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '还有 $remaining 张照片未查看。结束查看并确认删除已标记的 $deleteCount 张照片？';
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
  String get assetReloadPreview => '重新加载预览';

  @override
  String get assetSizeUnknown => '文件大小未知';

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
    return '$count 字节';
  }

  @override
  String get appName => '清理大师';

  @override
  String get nativePhotoRead => '访问你允许的照片与视频，供预览、整理及由你确认后删除。';

  @override
  String get nativePhotoAdd => '经你确认后，将压缩视频副本另存至照片。原片会保留。';

  @override
  String get nativeContacts => '访问你的联系人，以协助整理重复的联系数据。';

  @override
  String get nativeTracking => '允许追踪，以提供个人化体验并改善服务。';

  @override
  String get serviceSubscriptionsUnavailable => '订阅功能暂时不可用，请稍后再试。';

  @override
  String get serviceSubscriptionInitFailed => '无法连接订阅服务，请稍后再试。';

  @override
  String get serviceNoPlans => '目前没有可用的订阅方案，请稍后再试。';

  @override
  String get servicePlansLoadFailed => '无法加载方案，请检查网络后再试。';

  @override
  String get servicePurchaseUnavailable => '目前无法购买，请稍后再试。';

  @override
  String get servicePurchaseFailed => '购买未完成，请稍后再试。';

  @override
  String get serviceRestoreUnavailable => '目前无法恢复购买，请稍后再试。';

  @override
  String get serviceNoSubscription => '找不到有效的 Pro 订阅纪录。';

  @override
  String get serviceRestoreFailed => '恢复购买失败，请检查网络后再试。';

  @override
  String get servicePurchaseCancelled => '已取消购买。';

  @override
  String get serviceScanPaused => '已暂停，已读取与分析的结果已保留，可继续扫描。';

  @override
  String get serviceLimitedLibrary => '仅整理你允许访问的照片，未读取整个图库。';

  @override
  String get serviceNativeAnalysisUnavailable => '此设备无法分析原始文件。文件大小和完全重复尚未验证。';

  @override
  String get serviceOriginalVerificationNeeded =>
      '请验证本机原始资源，以确认文件大小和完全重复。大文件或云端项目可能仍待处理；未验证的大小不会估算。';

  @override
  String get serviceReadingIndex => '读取图库索引';

  @override
  String get servicePhotoPermission => '尚未取得图库权限，请在设置中允许访问照片后重试。';

  @override
  String get serviceOriginalRoundLimit =>
      '本轮原始素材验证已达 60 秒，结果已保留；再次验证会先处理未尝试项目。';

  @override
  String get servicePreviewRoundLimit => '本轮本机预览分析已达 30 秒，结果已保留；继续扫描会先处理未尝试照片。';

  @override
  String get serviceReadTimeout => '部分读取超时，当前结果已保留，可以继续扫描。';

  @override
  String get serviceReadInterrupted => '部分图库读取中断，已保留目前结果，可继续扫描。';

  @override
  String get serviceVerifyingOriginals => '验证本机原始素材';

  @override
  String get serviceGroupingSimilar => '整理视觉相似候选';

  @override
  String get serviceQualityLowDetail => '缩略图较粗糙，未提供画面品质建议';

  @override
  String get serviceQualityDecodeFailed => '无法解码预览，未评估画面品质';

  @override
  String get serviceQualityLowInformation => '画面信息不足，不提供品质保留建议';

  @override
  String get serviceQualityClearEdges => '缩略图边缘较清楚';

  @override
  String get serviceQualityLessDetail => '缩略图边缘细节较少';

  @override
  String get serviceQualityDark => '整体画面偏暗';

  @override
  String get serviceQualityBright => '整体画面偏亮';

  @override
  String get serviceQualityBalanced => '整体亮度适中';

  @override
  String get serviceKeepExact => '已确认原始及编辑素材内容完全相同，建议保留这一份';

  @override
  String get serviceKeepHigherResolution => '此群组中分辨率较高，建议先保留；仍需确认照片内容';

  @override
  String get serviceVideoMissing => '找不到这段视频，请重新扫描。';

  @override
  String get serviceVideoCloud => '视频尚在 iCloud，请先在照片 App 下载原片后重试。';

  @override
  String get serviceVideoUnreadable => '视频无法读取。';

  @override
  String get serviceVideoPreviousBusy => '前一次压缩仍在结束，请稍后重试。';

  @override
  String get serviceVideoTemporaryUnavailable => '无法取得视频暂存位置。';

  @override
  String get serviceVideoUnsupported => '此设备尚未支持视频压缩。';

  @override
  String get serviceVideoOutputInvalid => '压缩输出位置不符，原片已保留。';

  @override
  String get serviceVideoSaveUnknown => '无法确认副本已保存，请先到照片应用检查，再决定是否重试。';

  @override
  String get serviceVideoCancelled => '已取消压缩。';

  @override
  String get serviceVideoOperationBusy => '请先完成目前的视频操作。';

  @override
  String get serviceVideoEmpty => '原片为空，无法压缩。';

  @override
  String get serviceVideoEncodeFailed => '压缩未完成，原片已保留。';

  @override
  String get serviceVideoNoCopy => '压缩未产生独立副本，原片已保留。';

  @override
  String get serviceVideoNotSmaller => '这段视频压缩后没有变小，原片已保留。';

  @override
  String get serviceVideoDurationMismatch => '压缩后长度不符，原片已保留。';

  @override
  String get serviceVideoValidationFailed => '无法验证视频内容，原片已保留。';

  @override
  String get serviceVideoPreviewFirst => '请先完成压缩与预览。';

  @override
  String get serviceVideoSaveFailed => '另存失败，原片已保留，请重试。';

  @override
  String get serviceVideoGenericFailed => '操作未完成，原片已保留。请检查照片权限、可用空间后重试。';

  @override
  String get serviceOperationFailed => '操作未完成，请重试。';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '已读取 $read / $total 个可访问项目。';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count 张照片仍待视觉分析；继续扫描会先处理尚未尝试的照片，不自动下载云端素材。';
  }

  @override
  String serviceReadingPreviews(int count) {
    return '读取本机预览（$count 张）';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return '分析本机预览（$count 张）';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons；仅供保留参考';
  }

  @override
  String get scanSwipeIntro => '左滑标记删除，右滑保留；最后确认才删除。';

  @override
  String get scanSwipeStart => '开始滑动整理';

  @override
  String get scanDetails => '扫描详情';

  @override
  String get scanVerificationNeeded => '尚未检查原始文件';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '已检查 $verified / $total 个';
  }

  @override
  String get scanVerificationExplanation =>
      '先检查文件内容与大小，才能显示真正重复和大文件。云端项目可稍后再处理。';

  @override
  String get scanOriginalsAfterPreview =>
      '照片预览扫描完成后，才会检查完全重复和大文件的原始素材；也可先暂停，整理已找到的项目。';

  @override
  String get scanVerifyNow => '检查真正重复与大文件';

  @override
  String get scanBrowsePhotos => '先整理照片';

  @override
  String get scanSelectAll => '全选本分类';

  @override
  String get scanClearSelection => '清除选择';

  @override
  String get scanKeepOneSelectOthers => '保留这张，选择其他已载入预览的照片';

  @override
  String scanGroupReadyOthers(int ready, int total) {
    return '本组其他照片已载入预览 $ready/$total 张';
  }

  @override
  String get scanSelectOthersHint => '先预览建议保留的照片，再一次选中这组其他照片。';

  @override
  String get scanNotChecked => '待检查';

  @override
  String scanPendingCheckCount(int count) {
    return '待检查 $count 个';
  }

  @override
  String get swipeMultiSelectTitle => '批量选择项目';

  @override
  String get swipeDragSelectHint => '长按并滑过缩略图，可批量选择已载入预览的照片。';

  @override
  String swipeMarkSelectedForDeletion(int count) {
    return '将 $count 张标记为待删除';
  }

  @override
  String get swipeGestureTitle => '快速滑动整理';

  @override
  String get swipeGestureDelete => '左滑标记删除';

  @override
  String get swipeGestureKeep => '右滑保留';

  @override
  String get swipeGestureSafety => '照片会先加入待删列表；点击完成并确认后才删除。';

  @override
  String get swipeGestureHelp => '如何滑动整理';

  @override
  String get homeSwipeDescription => '逐张左右滑动，比点选缩略图更快。';

  @override
  String get scanCheckExactPhotos => '检查真正重复照片';

  @override
  String get scanCheckFileSizes => '检查大文件容量';

  @override
  String get reviewDeleteTitle => '检查待删项目';

  @override
  String get reviewRemove => '移出待删清单';

  @override
  String get reviewUnavailable => '无法载入预览。请重试或移除此项目。';

  @override
  String reviewUnseenCount(int count) {
    return '删除前还需预览的项目：$count 个';
  }

  @override
  String get reviewAllVersions => '已选中这组的所有版本。确定全部删除吗？';

  @override
  String get reviewDeleteAllVersions => '删除所有版本';

  @override
  String reviewConfirmCount(int count) {
    return '确认删除 · $count 个';
  }

  @override
  String swipeResumeReview(int count) {
    return '继续上次整理 · 已查看 $count 个';
  }

  @override
  String get swipeResetReview => '重新开始';

  @override
  String swipeBatchSize(int count) {
    return '每批查看 $count 个';
  }

  @override
  String get swipeAllMonths => '所有月份';

  @override
  String get swipeReviewBatch => '选择月份或批次';

  @override
  String get assetVideoLoading => '正在载入原始视频…';

  @override
  String get assetVideoUnavailable => '无法载入原始视频。请先在照片中下载，再重试。';

  @override
  String get homePermissionTitle => '需要照片访问权限';

  @override
  String get homePermissionDescription => '请在设置中允许访问照片，才能扫描与查看。不会自动删除任何项目。';

  @override
  String get homeOpenSettings => '打开设置';

  @override
  String get homeManagePhotoAccess => '管理照片访问权限';

  @override
  String get homeReviewReady => '整理已载入照片';

  @override
  String get homeContinueAnalysis => '继续分析照片';

  @override
  String get homeScanDetails => '扫描详情';

  @override
  String get scanCheckingExactTitle => '正在检查完全重复照片';

  @override
  String get scanCheckingSizesTitle => '正在检查文件容量';

  @override
  String scanRoundProgress(int total, int completed) {
    return '已处理 $completed / $total';
  }

  @override
  String get scanPauseReview => '暂停检查，先整理';

  @override
  String get scanSelectionHint => '勾选加入待删；点击预览可查看内容。';

  @override
  String get scanPreviewNotReady => '请先载入预览再选择';

  @override
  String scanUnreadableExcluded(int count) {
    return '有 $count 个预览尚未载入，未加入选择';
  }

  @override
  String get scanKeepThis => '保留这张';

  @override
  String get scanPreviewMore => '载入更多照片';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return '已确认文件容量：$size · 已检查 $count 个项目';
  }

  @override
  String homePendingSizes(int count) {
    return '另有 $count 个项目容量待确认';
  }

  @override
  String get scanReviewChanged => '照片或权限已更新，请重新检查待删清单。';

  @override
  String get paywallFreePreviewNote => '照片分组、预览与滑动标记均免费。Pro 可确认删除项目及压缩视频。';

  @override
  String paywallSubscribeWeekly(String price) {
    return '每周订阅 · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return '每年订阅 · $price';
  }

  @override
  String get paywallSubscribe => '订阅';

  @override
  String paywallWeeklyRenewal(String price) {
    return '除非取消，否则每周以 $price 自动续订。请在 App Store 查看最终条款。';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return '除非取消，否则每年以 $price 自动续订。请在 App Store 查看最终条款。';
  }

  @override
  String get paywallRenewalGeneric => '除非取消，否则自动续订。确认前请在 App Store 查看收费周期与金额。';

  @override
  String get paywallLoadingPlans => '正在载入订阅方案…';

  @override
  String get paywallWaitingForStore => '正在等待 App Store 确认…';

  @override
  String get paywallRestoring => '正在恢复购买…';

  @override
  String get settingsCheckingSubscription => '正在检查订阅…';

  @override
  String get settingsSubscriptionUnknown => '无法确认订阅状态';

  @override
  String get settingsManageSubscription => '管理订阅';

  @override
  String get settingsManageUnavailable => '无法打开订阅管理。请在商店账户设置中打开订阅。';

  @override
  String get onboardingStartFree => '免费开始';

  @override
  String get swipeCheckpointSaveError => '无法保存整理进度。仍可继续整理，但下次可能无法接续。';

  @override
  String swipeCheckpointLimit(int count) {
    return '此设备最多保留最近 $count 个项目的整理选择';
  }

  @override
  String get scanSelectLoaded => '选择已载入预览';

  @override
  String get homePhotoScopeChanged => '可访问的照片范围可能已变更，请重新扫描。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get onboardingSmartTitle => '智慧清理';

  @override
  String get onboardingSmartSubtitle => '掃描你允許存取的照片與影片\n先預覽，再決定保留或刪除';

  @override
  String get onboardingPhotosTitle => '照片整理';

  @override
  String get onboardingPhotosSubtitle => '依內容查看重複與相似照片\n保留建議仍需由你逐張確認';

  @override
  String get onboardingSwipeTitle => '滑動整理';

  @override
  String get onboardingSwipeSubtitle => '滑動選擇保留或刪除\n整理完成後統一確認';

  @override
  String get onboardingChoiceTitle => '由你決定';

  @override
  String get onboardingChoiceSubtitle => '掃描與照片預覽免費使用\n刪除與影片壓縮需 Pro，原片不會自動刪除';

  @override
  String get onboardingSkip => '跳過';

  @override
  String get onboardingPreparing => '正在準備…';

  @override
  String get onboardingContinue => '繼續';

  @override
  String get onboardingGetStarted => '開始使用';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => '關閉';

  @override
  String get paywallDescription => '解鎖照片與影片整理，預覽後選擇要刪除的項目。';

  @override
  String get paywallReloadPlans => '重新載入方案';

  @override
  String get paywallNotConfigured => '目前無法訂閱';

  @override
  String get paywallContinue => '繼續';

  @override
  String get paywallStoreNotice => '購買會透過 App Store 完成，訂閱可在 Apple ID 設定中管理或取消。';

  @override
  String get paywallRestorePurchases => '恢復購買';

  @override
  String get paywallPrivacyPolicy => '隱私權政策';

  @override
  String get paywallTerms => '使用條款';

  @override
  String get paywallPurchaseIncomplete => '購買未完成，請稍後再試。';

  @override
  String get paywallRestored => '已恢復 Pro 權限。';

  @override
  String get paywallRestoreNotFound => '找不到可恢復的購買紀錄。';

  @override
  String get paywallWeeklyPlan => '週訂閱';

  @override
  String get paywallYearlyPlan => '年訂閱';

  @override
  String get paywallYearlySubtitle => '全年整理照片與影片';

  @override
  String get paywallWeeklySubtitle => '短期整理相簿時使用';

  @override
  String get paywallPhotoFeature => '確認後刪除你選取的照片與影片';

  @override
  String get paywallVideoFeature => '影片壓縮、預覽與另存副本';

  @override
  String get paywallSwipeFeature => '滑動式快速清理體驗';

  @override
  String get paywallPlansUnavailable => '目前無法載入訂閱方案，請確認網路後重新載入。';

  @override
  String get paywallBestValue => '最佳價值';

  @override
  String get videoTitle => '影片壓縮';

  @override
  String get videoDescription => '壓縮會降低畫質並產生新副本。先檢查畫面、聲音與方向，再另存至照片。原片會保留。';

  @override
  String get videoProRequired => '這項功能需要 Pro，請返回清理頁查看方案。';

  @override
  String get videoSaving => '正在另存至照片，請等待完成。';

  @override
  String get videoCancelCompression => '取消壓縮';

  @override
  String get videoLoadingPreview => '正在載入影片預覽…';

  @override
  String get videoCreatePreview => '建立壓縮預覽';

  @override
  String get videoStorageNotice => '另存副本會暫時增加用量。刪除原片及清空「最近刪除」後，裝置實際可用空間以系統為準。';

  @override
  String get videoViewOriginal => '查看原片';

  @override
  String get videoViewCopy => '查看壓縮副本';

  @override
  String get videoSaved => '副本已另存至照片，原片保留。返回首頁重新掃描後，可自行選擇是否刪除原片。';

  @override
  String get videoConfirmSave => '確認副本並另存至照片';

  @override
  String get videoPreviewUnavailable => '預覽無法播放，請重試。原片已保留。';

  @override
  String get videoPlaybackUnavailable => '影片暫時無法播放，請重新載入預覽。';

  @override
  String get videoOperationIncomplete => '操作未完成，原片已保留。請檢查照片權限、可用空間後重試。';

  @override
  String get videoPauseOriginal => '原片：暫停';

  @override
  String get videoPlayOriginal => '原片：播放';

  @override
  String get videoPauseCopy => '壓縮副本：暫停';

  @override
  String get videoPlayCopy => '壓縮副本：播放';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return '版本 $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return '正在準備／壓縮影片 $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return '原片：$size';
  }

  @override
  String videoCopySize(String size) {
    return '副本：$size';
  }

  @override
  String videoSizeDifference(String size) {
    return '檔案差額：$size';
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
  String get homeStorageUnavailable => '裝置容量請至設定查看；此處整理可存取的照片與影片。';

  @override
  String get homeViewIndexedPhotos => '查看已讀取照片';

  @override
  String get homeViewIndexedScreenshots => '查看已讀取截圖';

  @override
  String get homeCleanupTools => '清理工具';

  @override
  String get homeQuickActions => '快速操作';

  @override
  String get homeAppName => '清理大師';

  @override
  String get homeSubtitle => '先預覽，再整理照片與影片';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => '已使用';

  @override
  String get homeUsedLegend => '已用';

  @override
  String get homeAvailableLegend => '可用';

  @override
  String get homeStartScanHint => '尚未掃描，點擊下方按鈕開始';

  @override
  String get homeScanning => '掃描中...';

  @override
  String get homeDeleting => '刪除中...';

  @override
  String get homeResumeScan => '繼續掃描並保留進度';

  @override
  String get homeScanAll => '掃描全部可存取照片與影片';

  @override
  String get homePreviewOrganize => '預覽並整理';

  @override
  String get homeVerifyOriginals => '驗證本機原始素材：確認真重複與容量';

  @override
  String get homeRetryPending => '繼續掃描／重試待處理項目';

  @override
  String get homeExactDuplicates => '真重複照片';

  @override
  String get homeSimilarPhotos => '視覺相似照片';

  @override
  String get homeNotScanned => '尚未掃描';

  @override
  String get homePendingAnalysis => '尚待畫面分析';

  @override
  String get homeNoneAnalyzed => '已分析項目中未發現';

  @override
  String get homeScreenshots => '螢幕截圖';

  @override
  String get homeLargeFiles => '大型檔案';

  @override
  String get homeNoneFound => '未發現';

  @override
  String get homePendingVerification => '尚待原始素材驗證';

  @override
  String get homeNoneVerified => '已驗證項目中未發現';

  @override
  String get homeNeedsReview => '待確認';

  @override
  String get homeCanReview => '可檢視';

  @override
  String get homeScanStatus => '掃描';

  @override
  String get homeDoneStatus => '已完成 ✓';

  @override
  String get homePreviewPhotos => '預覽照片';

  @override
  String get homeChooseKeep => '選擇要保留的項目';

  @override
  String get navHome => '首頁';

  @override
  String get navClean => '清理';

  @override
  String get navSettings => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLoading => '讀取中';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => '免費方案';

  @override
  String get settingsUpgrade => '升級';

  @override
  String get settingsStorage => '儲存空間';

  @override
  String get settingsStorageTotal => '總計';

  @override
  String get settingsStorageUsed => '已使用';

  @override
  String get settingsStorageAvailable => '可用';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsProcessingSubscription => '正在處理訂閱…';

  @override
  String get settingsRestorePurchases => '恢復購買';

  @override
  String get settingsRestoredPro => '已恢復 Pro 訂閱。';

  @override
  String get settingsPrivacyPolicy => '隱私權政策';

  @override
  String get settingsTerms => '使用條款';

  @override
  String get settingsRateApp => '給我們評分';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsChooseLanguage => '選擇語言';

  @override
  String get settingsSystemLanguage => '跟隨系統語言';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return '共 $size';
  }

  @override
  String homeIndexedCount(int count) {
    return '已讀取 $count 個項目';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '已讀取 $count / $total 個可存取項目';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return '視覺分析成功 $analyzed 個，原始素材已驗證 $verified 個。保留建議可撤回，刪除由你決定。';
  }

  @override
  String homePhotoCount(int count) {
    return '$count 張';
  }

  @override
  String homePhotoCountPartial(int count) {
    return '$count 張（部分結果）';
  }

  @override
  String homeItemCount(int count) {
    return '$count 個';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    return '已確認 $count 張，仍有待驗證';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    return '已確認 $count 個，仍有待驗證';
  }

  @override
  String get settingsLanguageSaveError => '無法儲存語言設定，請重試。';

  @override
  String get scanSmartTitle => '智慧清理';

  @override
  String get scanCancelKeepProgress => '取消掃描並保留進度';

  @override
  String get scanSwipeCleanup => '滑動清理';

  @override
  String get scanSortFileSize => '檔案容量';

  @override
  String get scanSortNewest => '最新';

  @override
  String get scanStartAlbumTitle => '開始掃描相簿';

  @override
  String get scanIncompleteTitle => '掃描未完成';

  @override
  String get scanStartAlbumDescription =>
      '先分析預覽，查看相似照片。進入真重複或大檔分類時，再分別檢查內容與容量。不會自動刪除任何項目。';

  @override
  String get scanContinue => '繼續掃描';

  @override
  String get scanStart => '開始掃描';

  @override
  String get scanPreviewWhileRunning => '照片與截圖可先預覽；掃描期間暫停選取、刪除及影片壓縮。';

  @override
  String get scanExactDescription => '真重複僅包括已完成原始素材驗證的項目，其餘不會推定重複。保留建議可撤回。';

  @override
  String get scanSimilarDescription => '視覺相似依已完成的本機畫面分析逐步整理，內容可能不同。保留建議僅供參考。';

  @override
  String get scanLargeDescription => '依已取得的原始檔案容量排序。這是檔案大小，實際回收空間以系統為準。';

  @override
  String get scanManualDeleteDescription => '只會刪除你手動勾選並再次確認的項目。';

  @override
  String get scanVerifyOriginals => '驗證本機原始素材：確認真重複與容量';

  @override
  String get scanResumePending => '繼續掃描／重試待處理項目';

  @override
  String get scanKeepReasonDefault => '此張照片在這組中較適合保留。';

  @override
  String get scanRestoreKeepSuggestion => '重新顯示保留建議';

  @override
  String get scanDismissKeepSuggestion => '撤回保留建議';

  @override
  String get scanKeepManualHint => '保留建議不會自動勾選；點選縮圖標記刪除。';

  @override
  String get scanEmptyUnverified => '尚有原始素材待驗證，目前不能判定是否有真重複或大型檔案。照片與截圖可先預覽。';

  @override
  String get scanEmptyVisualPending => '照片畫面仍有待處理項目，視覺相似結果會逐步整理。照片與截圖可先預覽。';

  @override
  String get scanEmptyIndexing => '相簿目錄仍在讀取，此分類將隨讀取進度更新。';

  @override
  String get scanEmptyCategory => '目前已完成分析或驗證的項目中沒有這個分類。';

  @override
  String get scanKeepBadge => '建議保留';

  @override
  String get scanZoomPreview => '放大預覽';

  @override
  String get scanCompressVideo => '壓縮此影片';

  @override
  String get scanContentPending => '內容待分析';

  @override
  String get scanBackToCompare => '返回繼續比較';

  @override
  String get scanConfirmDeleteTitle => '確認要刪除這些項目嗎？';

  @override
  String get scanCancel => '取消';

  @override
  String get scanNoItemsDeleted => '未刪除任何項目，可能已取消或刪除未成功。';

  @override
  String get scanConfirmDelete => '確認刪除';

  @override
  String get scanCategoryPhotos => '照片';

  @override
  String get scanCategoryExact => '真重複';

  @override
  String get scanCategorySimilar => '視覺相似';

  @override
  String get scanCategoryScreenshots => '截圖';

  @override
  String get scanCategoryVideos => '影片';

  @override
  String get scanCategoryLarge => '大檔';

  @override
  String scanExactGroupCount(int count) {
    return '$count 張真重複照片';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return '$count 張視覺相似照片';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return '建議保留：$reason';
  }

  @override
  String scanSelectedCount(int count) {
    return '已選擇 $count 個項目';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '預覽並刪除 $count 個項目';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '共 $count 個項目。請確認選取內容與保留建議後再刪除；實際回收空間以系統為準。';
  }

  @override
  String scanItemsDeleted(int count) {
    return '已刪除 $count 個項目。';
  }

  @override
  String get scanIndexingTitle => '讀取相簿目錄';

  @override
  String get scanVerifyingTitle => '正在檢查原始檔案';

  @override
  String get scanAnalyzingTitle => '分析本機照片畫面';

  @override
  String get scanSlowOperationHint => '此項目讀取較慢，可先取消並保留進度，稍後續掃。';

  @override
  String get scanProgressPreviewHint => '已讀取的照片與截圖可先查看。待下載或未成功分析的項目不會被當成真重複。';

  @override
  String get scanCountConfirming => '確認中';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '已讀取 $indexed / $total 個項目';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return '照片畫面已處理 $attempted / $total 張';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return '原始素材已處理 $attempted / $total 個項目';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return '視覺分析成功 $count 個';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return '原始素材已驗證 $count 個';
  }

  @override
  String scanCloudPendingCount(int count) {
    return '待下載 $count 個';
  }

  @override
  String scanStageRemainingCount(int count) {
    return '本階段尚未處理 $count 個';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · 已等待 $seconds 秒';
  }

  @override
  String get swipeKeep => '保留';

  @override
  String get swipeDelete => '刪除';

  @override
  String get swipeReviewComplete => '審核完成！';

  @override
  String get swipeRecoveredSpaceHint => '刪除後的空間以系統為準';

  @override
  String get swipeUndoChoice => '撤回上一個選擇';

  @override
  String get swipeBack => '返回';

  @override
  String get swipeConfirmDeleteTitle => '確認刪除已標記的照片？';

  @override
  String get swipeCancel => '取消';

  @override
  String get swipeConfirmDelete => '確認刪除';

  @override
  String get swipeNoPhotosDeleted => '未刪除任何照片，可能已取消或刪除未成功。';

  @override
  String get swipeExitTitle => '確定離開？';

  @override
  String get swipeContinueReview => '繼續審核';

  @override
  String get swipeLeave => '離開';

  @override
  String get swipeSkipRemainingTitle => '跳過剩餘照片？';

  @override
  String get swipeDone => '完成';

  @override
  String swipeDoneCount(int count) {
    return '完成 ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return '$count 刪除';
  }

  @override
  String swipeKeepCount(int count) {
    return '$count 保留';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '$deleteCount 張要刪除 · $keepCount 張保留';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '刪除 $count 張照片';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return '已選取待刪照片：$count 張。想保留的照片請移出待刪清單。';
  }

  @override
  String swipePartialDeleted(int count) {
    return '已刪除 $count 張，剩餘照片尚未刪除。';
  }

  @override
  String swipeExitDescription(int count) {
    return '你已標記 $count 張照片要刪除，離開將不會執行。';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '還有 $remaining 張未審核，要直接刪除已標記的 $deleteCount 張嗎？';
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
  String get assetReloadPreview => '重新載入預覽';

  @override
  String get assetSizeUnknown => '容量未取得';

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
    return '$count 位元組';
  }

  @override
  String get appName => '清理大師';

  @override
  String get nativePhotoRead => '存取你允許的照片與影片，供預覽、整理及由你確認後刪除。';

  @override
  String get nativePhotoAdd => '經你確認後，將壓縮影片副本另存至照片。原片會保留。';

  @override
  String get nativeContacts => '存取你的聯絡人，以協助整理重複的聯絡資料。';

  @override
  String get nativeTracking => '允許追蹤，以提供個人化體驗並改善服務。';

  @override
  String get serviceSubscriptionsUnavailable => '訂閱功能暫時不可用，請稍後再試。';

  @override
  String get serviceSubscriptionInitFailed => '無法連接訂閱服務，請稍後再試。';

  @override
  String get serviceNoPlans => '目前沒有可用的訂閱方案，請稍後再試。';

  @override
  String get servicePlansLoadFailed => '無法載入方案，請檢查網路後再試。';

  @override
  String get servicePurchaseUnavailable => '目前無法購買，請稍後再試。';

  @override
  String get servicePurchaseFailed => '購買未完成，請稍後再試。';

  @override
  String get serviceRestoreUnavailable => '目前無法恢復購買，請稍後再試。';

  @override
  String get serviceNoSubscription => '找不到有效的 Pro 訂閱紀錄。';

  @override
  String get serviceRestoreFailed => '恢復購買失敗，請檢查網路後再試。';

  @override
  String get servicePurchaseCancelled => '已取消購買。';

  @override
  String get serviceScanPaused => '已暫停，已讀取與分析的結果已保留，可繼續掃描。';

  @override
  String get serviceLimitedLibrary => '僅整理你允許存取的照片，未讀取整個相簿。';

  @override
  String get serviceNativeAnalysisUnavailable => '此裝置尚未提供本機原始素材分析，未確認容量與重複內容。';

  @override
  String get serviceOriginalVerificationNeeded =>
      '素材容量與完全重複另需驗證本機原始素材；大型或雲端素材可能仍待驗證，未驗證項目不估算容量。';

  @override
  String get serviceReadingIndex => '讀取相簿索引';

  @override
  String get servicePhotoPermission => '尚未取得相簿權限，請在設定中允許存取照片後重試。';

  @override
  String get serviceOriginalRoundLimit =>
      '本輪原始素材驗證已達 60 秒，結果已保留；再次驗證會先處理未嘗試項目。';

  @override
  String get servicePreviewRoundLimit => '本輪本機預覽分析已達 30 秒，結果已保留；繼續掃描會先處理未嘗試照片。';

  @override
  String get serviceReadTimeout => '部分讀取逾時，已保留目前結果，可繼續掃描。';

  @override
  String get serviceReadInterrupted => '部分相簿讀取中斷，已保留目前結果，可繼續掃描。';

  @override
  String get serviceVerifyingOriginals => '驗證本機原始素材';

  @override
  String get serviceGroupingSimilar => '整理視覺相似候選';

  @override
  String get serviceQualityLowDetail => '縮圖較粗糙，未提供畫面品質建議';

  @override
  String get serviceQualityDecodeFailed => '無法解碼預覽，未評估畫面品質';

  @override
  String get serviceQualityLowInformation => '畫面資訊不足，不提供品質保留建議';

  @override
  String get serviceQualityClearEdges => '縮圖邊緣較清楚';

  @override
  String get serviceQualityLessDetail => '縮圖邊緣細節較少';

  @override
  String get serviceQualityDark => '整體畫面偏暗';

  @override
  String get serviceQualityBright => '整體畫面偏亮';

  @override
  String get serviceQualityBalanced => '整體亮度適中';

  @override
  String get serviceKeepExact => '已確認原始及編輯素材內容完全相同，建議保留這一份';

  @override
  String get serviceKeepHigherResolution => '此群組中解析度較高，建議先保留；仍需確認照片內容';

  @override
  String get serviceVideoMissing => '找不到這段影片，請重新掃描。';

  @override
  String get serviceVideoCloud => '影片尚在 iCloud，請先在照片 App 下載原片後重試。';

  @override
  String get serviceVideoUnreadable => '影片無法讀取。';

  @override
  String get serviceVideoPreviousBusy => '前一次壓縮仍在結束，請稍後重試。';

  @override
  String get serviceVideoTemporaryUnavailable => '無法取得影片暫存位置。';

  @override
  String get serviceVideoUnsupported => '此裝置尚未支援影片壓縮。';

  @override
  String get serviceVideoOutputInvalid => '壓縮輸出位置不符，原片已保留。';

  @override
  String get serviceVideoSaveUnknown => '無法確認另存結果，請先到照片 App 檢查。';

  @override
  String get serviceVideoCancelled => '已取消壓縮。';

  @override
  String get serviceVideoOperationBusy => '請先完成目前的影片操作。';

  @override
  String get serviceVideoEmpty => '原片為空，無法壓縮。';

  @override
  String get serviceVideoEncodeFailed => '壓縮未完成，原片已保留。';

  @override
  String get serviceVideoNoCopy => '壓縮未產生獨立副本，原片已保留。';

  @override
  String get serviceVideoNotSmaller => '這段影片壓縮後沒有變小，原片已保留。';

  @override
  String get serviceVideoDurationMismatch => '壓縮後長度不符，原片已保留。';

  @override
  String get serviceVideoValidationFailed => '無法驗證影片內容，原片已保留。';

  @override
  String get serviceVideoPreviewFirst => '請先完成壓縮與預覽。';

  @override
  String get serviceVideoSaveFailed => '另存失敗，原片已保留，請重試。';

  @override
  String get serviceVideoGenericFailed => '操作未完成，原片已保留。請檢查照片權限、可用空間後重試。';

  @override
  String get serviceOperationFailed => '操作未完成，請重試。';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '已讀取 $read / $total 個可存取項目。';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count 張照片仍待視覺分析；繼續掃描會先處理尚未嘗試的照片，不自動下載雲端素材。';
  }

  @override
  String serviceReadingPreviews(int count) {
    return '讀取本機預覽（$count 張）';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return '分析本機預覽（$count 張）';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons；僅供保留參考';
  }

  @override
  String get scanSwipeIntro => '左滑標記刪除，右滑保留；最後確認才刪除。';

  @override
  String get scanSwipeStart => '開始滑動整理';

  @override
  String get scanDetails => '掃描詳情';

  @override
  String get scanVerificationNeeded => '尚未檢查原始檔案';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '已檢查 $verified / $total 個';
  }

  @override
  String get scanVerificationExplanation => '先檢查檔案內容與容量，才能顯示真重複和大檔。雲端項目可稍後再處理。';

  @override
  String get scanOriginalsAfterPreview =>
      '照片預覽掃描完成後，才會檢查真重複與大檔原始素材；也可先暫停，整理已找到的項目。';

  @override
  String get scanVerifyNow => '檢查真重複與大檔';

  @override
  String get scanBrowsePhotos => '先整理照片';

  @override
  String get scanSelectAll => '全選本分類';

  @override
  String get scanClearSelection => '清除選取';

  @override
  String get scanKeepOneSelectOthers => '保留這張，選取其他已載入預覽的照片';

  @override
  String scanGroupReadyOthers(int ready, int total) {
    return '本組其他照片已載入預覽 $ready／$total 張';
  }

  @override
  String get scanSelectOthersHint => '先預覽建議保留的照片，再一次選取這組其他照片。';

  @override
  String get scanNotChecked => '待檢查';

  @override
  String scanPendingCheckCount(int count) {
    return '待檢查 $count 個';
  }

  @override
  String get swipeMultiSelectTitle => '批量選取項目';

  @override
  String get swipeDragSelectHint => '長按並滑過縮圖，可批量選取已載入預覽的照片。';

  @override
  String swipeMarkSelectedForDeletion(int count) {
    return '將 $count 張標記為待刪';
  }

  @override
  String get swipeGestureTitle => '快速滑動整理';

  @override
  String get swipeGestureDelete => '左滑標記刪除';

  @override
  String get swipeGestureKeep => '右滑保留';

  @override
  String get swipeGestureSafety => '照片會先加入待刪清單；按完成並確認後才刪除。';

  @override
  String get swipeGestureHelp => '如何滑動整理';

  @override
  String get homeSwipeDescription => '逐張左右滑動，比點選縮圖更快。';

  @override
  String get scanCheckExactPhotos => '檢查真重複';

  @override
  String get scanCheckFileSizes => '檢查大檔容量';

  @override
  String get reviewDeleteTitle => '檢查待刪項目';

  @override
  String get reviewRemove => '移出待刪清單';

  @override
  String get reviewUnavailable => '無法載入預覽。請重試或移除此項目。';

  @override
  String reviewUnseenCount(int count) {
    return '刪除前還需預覽的項目：$count 個';
  }

  @override
  String get reviewAllVersions => '已選取這組的所有版本。確定全部刪除嗎？';

  @override
  String get reviewDeleteAllVersions => '刪除所有版本';

  @override
  String reviewConfirmCount(int count) {
    return '確認刪除 · $count 個';
  }

  @override
  String swipeResumeReview(int count) {
    return '繼續上次整理 · 已查看 $count 個';
  }

  @override
  String get swipeResetReview => '重新開始';

  @override
  String swipeBatchSize(int count) {
    return '每批查看 $count 個';
  }

  @override
  String get swipeAllMonths => '所有月份';

  @override
  String get swipeReviewBatch => '選擇月份或批次';

  @override
  String get assetVideoLoading => '正在載入原始影片…';

  @override
  String get assetVideoUnavailable => '無法載入原始影片。請先在照片中下載，再重試。';

  @override
  String get homePermissionTitle => '需要照片存取權限';

  @override
  String get homePermissionDescription => '請在設定中允許存取照片，才能掃描與查看。不會自動刪除任何項目。';

  @override
  String get homeOpenSettings => '開啟設定';

  @override
  String get homeManagePhotoAccess => '管理照片存取權限';

  @override
  String get homeReviewReady => '整理已載入照片';

  @override
  String get homeContinueAnalysis => '繼續分析照片';

  @override
  String get homeScanDetails => '掃描詳情';

  @override
  String get scanCheckingExactTitle => '正在檢查真重複照片';

  @override
  String get scanCheckingSizesTitle => '正在檢查檔案容量';

  @override
  String scanRoundProgress(int total, int completed) {
    return '已處理 $completed / $total';
  }

  @override
  String get scanPauseReview => '暫停檢查，先整理';

  @override
  String get scanSelectionHint => '勾選加入待刪；點預覽可查看內容。';

  @override
  String get scanPreviewNotReady => '請先載入預覽再選取';

  @override
  String scanUnreadableExcluded(int count) {
    return '有 $count 個預覽尚未載入，未加入選取';
  }

  @override
  String get scanKeepThis => '保留這張';

  @override
  String get scanPreviewMore => '載入更多照片';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return '已確認檔案容量：$size · 已檢查 $count 個項目';
  }

  @override
  String homePendingSizes(int count) {
    return '另有 $count 個項目容量待確認';
  }

  @override
  String get scanReviewChanged => '照片或權限已更新，請重新檢視待刪清單。';

  @override
  String get paywallFreePreviewNote => '照片分組、預覽與滑動標記皆免費。Pro 可確認刪除項目及壓縮影片。';

  @override
  String paywallSubscribeWeekly(String price) {
    return '每週訂閱 · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return '每年訂閱 · $price';
  }

  @override
  String get paywallSubscribe => '訂閱';

  @override
  String paywallWeeklyRenewal(String price) {
    return '除非取消，否則每週以 $price 自動續訂。請在 App Store 查看最終條款。';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return '除非取消，否則每年以 $price 自動續訂。請在 App Store 查看最終條款。';
  }

  @override
  String get paywallRenewalGeneric => '除非取消，否則自動續訂。確認前請在 App Store 查看收費週期與金額。';

  @override
  String get paywallLoadingPlans => '正在載入訂閱方案…';

  @override
  String get paywallWaitingForStore => '正在等待 App Store 確認…';

  @override
  String get paywallRestoring => '正在恢復購買…';

  @override
  String get settingsCheckingSubscription => '正在檢查訂閱…';

  @override
  String get settingsSubscriptionUnknown => '無法確認訂閱狀態';

  @override
  String get settingsManageSubscription => '管理訂閱';

  @override
  String get settingsManageUnavailable => '無法開啟訂閱管理。請在商店帳號設定中開啟訂閱。';

  @override
  String get onboardingStartFree => '免費開始';

  @override
  String get swipeCheckpointSaveError => '無法儲存整理進度。仍可繼續整理，但下次可能無法接續。';

  @override
  String swipeCheckpointLimit(int count) {
    return '此裝置最多保留最近 $count 個項目的整理選擇';
  }

  @override
  String get scanSelectLoaded => '選取已載入預覽';

  @override
  String get homePhotoScopeChanged => '可存取的照片範圍可能已變更，請重新掃描。';
}
