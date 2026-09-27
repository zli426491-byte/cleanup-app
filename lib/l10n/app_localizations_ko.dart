// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get onboardingSmartTitle => '스마트 정리';

  @override
  String get onboardingSmartSubtitle =>
      '접근을 허용한 사진과 동영상을 스캔해요\n먼저 미리 본 뒤 보관하거나 삭제할 항목을 선택하세요';

  @override
  String get onboardingPhotosTitle => '사진 정리';

  @override
  String get onboardingPhotosSubtitle =>
      '내용을 비교해 중복 사진과 비슷한 사진을 찾아요\n보관 추천 사진도 한 장씩 확인하세요';

  @override
  String get onboardingSwipeTitle => '스와이프로 정리';

  @override
  String get onboardingSwipeSubtitle =>
      '스와이프하여 보관하거나 삭제할 사진을 선택해요\n마지막에 모든 선택을 확인하세요';

  @override
  String get onboardingChoiceTitle => '결정은 직접 하세요';

  @override
  String get onboardingChoiceSubtitle =>
      '스캔과 사진 미리보기는 무료예요\n삭제와 동영상 압축에는 Pro가 필요합니다. 원본은 자동으로 삭제되지 않습니다.';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingPreparing => '준비 중…';

  @override
  String get onboardingContinue => '계속';

  @override
  String get onboardingGetStarted => '시작하기';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => '닫기';

  @override
  String get paywallDescription =>
      '사진과 동영상 정리 기능을 이용하세요. 먼저 미리 본 뒤 삭제할 항목을 선택하세요.';

  @override
  String get paywallReloadPlans => '요금제 다시 불러오기';

  @override
  String get paywallNotConfigured => '현재 구독할 수 없습니다';

  @override
  String get paywallContinue => '계속';

  @override
  String get paywallStoreNotice =>
      '구매는 App Store에서 진행됩니다. Apple ID 설정에서 구독을 관리하거나 취소할 수 있습니다.';

  @override
  String get paywallRestorePurchases => '구매 복원';

  @override
  String get paywallPrivacyPolicy => '개인정보 처리방침';

  @override
  String get paywallTerms => '이용약관';

  @override
  String get paywallPurchaseIncomplete => '구매가 완료되지 않았습니다. 나중에 다시 시도하세요.';

  @override
  String get paywallRestored => 'Pro 이용 권한을 복원했습니다.';

  @override
  String get paywallRestoreNotFound => '복원할 구매 내역이 없습니다.';

  @override
  String get paywallWeeklyPlan => '주간 구독';

  @override
  String get paywallYearlyPlan => '연간 구독';

  @override
  String get paywallYearlySubtitle => '일 년 내내 사진과 동영상 정리';

  @override
  String get paywallWeeklySubtitle => '짧은 기간 동안 사진을 정리할 때';

  @override
  String get paywallPhotoFeature => '선택한 사진과 동영상을 확인 후 삭제';

  @override
  String get paywallVideoFeature => '동영상을 압축하고 미리 본 뒤 사본 저장';

  @override
  String get paywallSwipeFeature => '스와이프 동작으로 빠르게 정리';

  @override
  String get paywallPlansUnavailable =>
      '구독 요금제를 불러오지 못했습니다. 연결을 확인하고 다시 불러오세요.';

  @override
  String get paywallBestValue => '가장 경제적';

  @override
  String get videoTitle => '동영상 압축';

  @override
  String get videoDescription =>
      '압축하면 화질이 낮아지고 새 사본이 만들어집니다. 화면, 소리, 방향을 확인한 뒤 사진 앱에 저장하세요. 원본은 유지됩니다.';

  @override
  String get videoProRequired => '이 기능에는 Pro가 필요합니다. 정리 페이지에서 요금제를 확인하세요.';

  @override
  String get videoSaving => '사진 앱에 저장 중입니다. 완료될 때까지 기다려 주세요.';

  @override
  String get videoCancelCompression => '압축 취소';

  @override
  String get videoLoadingPreview => '동영상 미리보기 불러오는 중…';

  @override
  String get videoCreatePreview => '압축 미리보기 만들기';

  @override
  String get videoStorageNotice =>
      '사본을 저장하면 일시적으로 저장 공간이 더 필요합니다. 원본을 삭제하고 ‘최근 삭제된 항목’을 비운 뒤 시스템에서 실제 사용 가능한 공간을 확인하세요.';

  @override
  String get videoViewOriginal => '원본 보기';

  @override
  String get videoViewCopy => '압축 사본 보기';

  @override
  String get videoSaved =>
      '사본을 사진 앱에 저장했고 원본은 유지했습니다. 홈에서 다시 스캔한 뒤 원본을 삭제할지 선택하세요.';

  @override
  String get videoConfirmSave => '사본을 확인하고 사진 앱에 저장';

  @override
  String get videoPreviewUnavailable =>
      '미리보기를 재생할 수 없습니다. 다시 시도하세요. 원본은 유지됩니다.';

  @override
  String get videoPlaybackUnavailable => '지금 동영상을 재생할 수 없습니다. 미리보기를 다시 불러오세요.';

  @override
  String get videoOperationIncomplete =>
      '작업이 완료되지 않았습니다. 원본은 유지됩니다. 사진 접근 권한과 여유 공간을 확인한 뒤 다시 시도하세요.';

  @override
  String get videoPauseOriginal => '원본: 일시 정지';

  @override
  String get videoPlayOriginal => '원본: 재생';

  @override
  String get videoPauseCopy => '압축 사본: 일시 정지';

  @override
  String get videoPlayCopy => '압축 사본: 재생';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return '빌드 $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return '동영상 준비 / 압축 중 $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return '원본: $size';
  }

  @override
  String videoCopySize(String size) {
    return '사본: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return '파일 크기 차이: $size';
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
      '기기 저장 공간은 설정에서 확인하세요. 여기에서는 접근 가능한 사진과 동영상을 정리할 수 있습니다.';

  @override
  String get homeViewIndexedPhotos => '읽은 사진 보기';

  @override
  String get homeViewIndexedScreenshots => '읽은 스크린샷 보기';

  @override
  String get homeCleanupTools => '정리 도구';

  @override
  String get homeQuickActions => '빠른 작업';

  @override
  String get homeAppName => '클린업';

  @override
  String get homeSubtitle => '먼저 미리 보고 사진과 동영상을 정리하세요';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => '사용 중';

  @override
  String get homeUsedLegend => '사용 중';

  @override
  String get homeAvailableLegend => '사용 가능';

  @override
  String get homeStartScanHint => '아직 스캔하지 않았습니다. 아래를 눌러 시작하세요.';

  @override
  String get homeScanning => '스캔 중…';

  @override
  String get homeDeleting => '삭제 중…';

  @override
  String get homeResumeScan => '진행 상황을 유지하고 스캔 계속';

  @override
  String get homeScanAll => '접근 가능한 모든 사진과 동영상 스캔';

  @override
  String get homePreviewOrganize => '미리 보고 정리';

  @override
  String get homeVerifyOriginals => '기기 내 원본 검증: 완전 중복과 파일 크기';

  @override
  String get homeRetryPending => '스캔 계속 / 대기 항목 재시도';

  @override
  String get homeExactDuplicates => '완전히 중복된 사진';

  @override
  String get homeSimilarPhotos => '시각적으로 비슷한 사진';

  @override
  String get homeNotScanned => '아직 스캔하지 않음';

  @override
  String get homePendingAnalysis => '시각 분석 대기 중';

  @override
  String get homeNoneAnalyzed => '분석한 항목에서 찾지 못함';

  @override
  String get homeScreenshots => '스크린샷';

  @override
  String get homeLargeFiles => '대용량 파일';

  @override
  String get homeNoneFound => '찾지 못함';

  @override
  String get homePendingVerification => '원본 검증 대기 중';

  @override
  String get homeNoneVerified => '검증한 항목에서 찾지 못함';

  @override
  String get homeNeedsReview => '확인 필요';

  @override
  String get homeCanReview => '확인';

  @override
  String get homeScanStatus => '스캔';

  @override
  String get homeDoneStatus => '완료 ✓';

  @override
  String get homePreviewPhotos => '사진 미리보기';

  @override
  String get homeChooseKeep => '보관할 항목 선택';

  @override
  String get navHome => '홈';

  @override
  String get navClean => '정리';

  @override
  String get navSettings => '설정';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLoading => '불러오는 중…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => '무료 요금제';

  @override
  String get settingsUpgrade => '업그레이드';

  @override
  String get settingsStorage => '저장 공간';

  @override
  String get settingsStorageTotal => '전체';

  @override
  String get settingsStorageUsed => '사용 중';

  @override
  String get settingsStorageAvailable => '사용 가능';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsProcessingSubscription => '구독 처리 중…';

  @override
  String get settingsRestorePurchases => '구매 복원';

  @override
  String get settingsRestoredPro => 'Pro 구독을 복원했습니다.';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsRateApp => '평가하기';

  @override
  String get settingsAbout => '앱 정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsChooseLanguage => '언어 선택';

  @override
  String get settingsSystemLanguage => '시스템 언어 사용';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return '총 $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개 읽음',
      one: '항목 1개 읽음',
    );
    return '$_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return '불러온 접근 가능한 항목: $count / $total';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return '시각 분석: $analyzed개. 원본 검증: $verified개. 보관 추천은 취소할 수 있으며, 삭제 여부는 직접 결정합니다.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장',
      one: '사진 1장',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장 (일부 결과)',
      one: '사진 1장 (일부 결과)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개',
      one: '항목 1개',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사진 $count장 검증됨; 추가 검증 대기 중',
      one: '사진 1장 검증됨; 추가 검증 대기 중',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개 검증됨; 추가 검증 대기 중',
      one: '항목 1개 검증됨; 추가 검증 대기 중',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError => '언어를 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get scanSmartTitle => '스마트 정리';

  @override
  String get scanCancelKeepProgress => '진행 상황을 유지하고 스캔 취소';

  @override
  String get scanSwipeCleanup => '스와이프 정리';

  @override
  String get scanSortFileSize => '파일 크기';

  @override
  String get scanSortNewest => '최신순';

  @override
  String get scanStartAlbumTitle => '사진 보관함 스캔 시작';

  @override
  String get scanIncompleteTitle => '스캔 미완료';

  @override
  String get scanStartAlbumDescription =>
      '먼저 미리 보기를 분석해 비슷한 사진을 확인합니다. 완전 중복과 대용량 파일은 해당 카테고리를 열면 별도로 검사합니다. 자동으로 삭제되지 않습니다.';

  @override
  String get scanContinue => '스캔 계속';

  @override
  String get scanStart => '스캔 시작';

  @override
  String get scanPreviewWhileRunning =>
      '사진과 스크린샷은 미리 볼 수 있습니다. 스캔 중에는 선택, 삭제, 동영상 압축이 일시 중지됩니다.';

  @override
  String get scanExactDescription =>
      '완전 중복에는 원본 리소스가 검증된 항목만 포함됩니다. 보관 추천은 취소할 수 있습니다.';

  @override
  String get scanSimilarDescription =>
      '기기 내 미리보기가 분석되면 시각적으로 비슷한 후보가 나타납니다. 내용은 다를 수 있으며, 보관 추천은 참고용입니다.';

  @override
  String get scanLargeDescription =>
      '검증된 리소스 크기순으로 정렬합니다. 파일 크기와 실제 확보되는 공간은 다를 수 있으며, 확보되는 공간은 시스템이 결정합니다.';

  @override
  String get scanManualDeleteDescription => '직접 선택하고 확인한 항목만 삭제됩니다.';

  @override
  String get scanVerifyOriginals => '기기 내 원본 검증: 완전 중복과 크기';

  @override
  String get scanResumePending => '스캔 계속 / 대기 항목 재시도';

  @override
  String get scanKeepReasonDefault => '이 그룹에서 보관하도록 추천된 사진입니다.';

  @override
  String get scanRestoreKeepSuggestion => '보관 추천 다시 표시';

  @override
  String get scanDismissKeepSuggestion => '보관 추천 취소';

  @override
  String get scanKeepManualHint =>
      '추천으로 항목이 자동 선택되지는 않습니다. 썸네일을 눌러 삭제할 항목으로 표시하세요.';

  @override
  String get scanEmptyUnverified =>
      '아직 검증할 원본 리소스가 있어 완전 중복과 대용량 파일을 판단할 수 없습니다. 사진과 스크린샷은 미리 볼 수 있습니다.';

  @override
  String get scanEmptyVisualPending =>
      '아직 분석할 사진 미리보기가 있습니다. 시각적으로 비슷한 후보는 차례로 나타나며, 사진과 스크린샷은 미리 볼 수 있습니다.';

  @override
  String get scanEmptyIndexing =>
      '아직 사진 보관함 색인을 만드는 중입니다. 진행 상황에 따라 이 카테고리가 업데이트됩니다.';

  @override
  String get scanEmptyCategory => '현재 분석하거나 검증한 항목 중 이 카테고리에 해당하는 항목이 없습니다.';

  @override
  String get scanKeepBadge => '보관 추천';

  @override
  String get scanZoomPreview => '미리보기 확대';

  @override
  String get scanCompressVideo => '이 동영상 압축';

  @override
  String get scanContentPending => '내용 분석 대기 중';

  @override
  String get scanBackToCompare => '비교로 돌아가기';

  @override
  String get scanConfirmDeleteTitle => '선택한 항목을 삭제할까요?';

  @override
  String get scanCancel => '취소';

  @override
  String get scanNoItemsDeleted => '삭제된 항목이 없습니다. 작업이 취소되었거나 실패했을 수 있습니다.';

  @override
  String get scanConfirmDelete => '삭제 확인';

  @override
  String get scanCategoryPhotos => '사진';

  @override
  String get scanCategoryExact => '완전 중복';

  @override
  String get scanCategorySimilar => '시각적 유사 후보';

  @override
  String get scanCategoryScreenshots => '스크린샷';

  @override
  String get scanCategoryVideos => '동영상';

  @override
  String get scanCategoryLarge => '대용량 파일';

  @override
  String scanExactGroupCount(int count) {
    return '완전 중복: 사진 $count장';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return '시각적 유사 후보: 사진 $count장';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return '보관 추천: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return '선택한 항목: $count개';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return '항목 $count개 미리 보기 및 삭제';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return '항목 $count개를 선택했습니다. 선택 내용과 보관 추천을 확인한 뒤 삭제하세요. 확보되는 저장 공간은 시스템이 결정합니다.';
  }

  @override
  String scanItemsDeleted(int count) {
    return '항목 $count개를 삭제했습니다.';
  }

  @override
  String get scanIndexingTitle => '사진 보관함 색인 생성 중';

  @override
  String get scanVerifyingTitle => '원본 파일 확인 중';

  @override
  String get scanAnalyzingTitle => '기기 내 사진 미리보기 분석 중';

  @override
  String get scanSlowOperationHint =>
      '작업이 오래 걸리고 있습니다. 취소하고 진행 상황을 유지한 뒤 나중에 계속할 수 있습니다.';

  @override
  String get scanProgressPreviewHint =>
      '색인에 추가된 사진과 스크린샷을 볼 수 있습니다. 다운로드 대기 중이거나 분석에 실패한 항목은 완전 중복으로 처리되지 않습니다.';

  @override
  String get scanCountConfirming => '확인 중';

  @override
  String scanIndexedCount(int indexed, String total) {
    return '색인 생성: $indexed / $total개';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return '처리한 사진 미리보기: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return '처리한 원본 리소스: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return '시각 분석 완료: $count개';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return '원본 검증 완료: $count개';
  }

  @override
  String scanCloudPendingCount(int count) {
    return '다운로드 대기: $count개';
  }

  @override
  String scanStageRemainingCount(int count) {
    return '이 단계에서 아직 처리하지 않은 항목: $count개';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · $seconds초 대기 중';
  }

  @override
  String get swipeKeep => '보관';

  @override
  String get swipeDelete => '삭제';

  @override
  String get swipeReviewComplete => '확인 완료!';

  @override
  String get swipeRecoveredSpaceHint => '확보되는 저장 공간은 시스템이 결정합니다.';

  @override
  String get swipeUndoChoice => '마지막 선택 취소';

  @override
  String get swipeBack => '뒤로';

  @override
  String get swipeConfirmDeleteTitle => '삭제할 항목으로 표시한 사진을 삭제할까요?';

  @override
  String get swipeCancel => '취소';

  @override
  String get swipeConfirmDelete => '삭제 확인';

  @override
  String get swipeNoPhotosDeleted => '삭제된 사진이 없습니다. 작업이 취소되었거나 실패했을 수 있습니다.';

  @override
  String get swipeExitTitle => '사진 확인을 종료할까요?';

  @override
  String get swipeContinueReview => '계속 확인';

  @override
  String get swipeLeave => '나가기';

  @override
  String get swipeSkipRemainingTitle => '남은 사진을 건너뛸까요?';

  @override
  String get swipeDone => '완료';

  @override
  String swipeDoneCount(int count) {
    return '완료 ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return '삭제: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return '보관: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return '삭제할 사진 $deleteCount장 · 보관할 사진 $keepCount장';
  }

  @override
  String swipeDeletePhotos(int count) {
    return '사진 $count장 삭제';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return '삭제할 사진: $count장. 보관할 사진은 삭제 목록에서 제외하세요.';
  }

  @override
  String swipePartialDeleted(int count) {
    return '사진 $count장을 삭제했습니다. 남은 사진은 삭제하지 않았습니다.';
  }

  @override
  String swipeExitDescription(int count) {
    return '사진 $count장을 삭제 대상으로 표시했습니다. 나가도 삭제되지 않습니다.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return '아직 확인하지 않은 사진이 $remaining장 있습니다. 확인을 마치고 이미 삭제 대상으로 표시한 $deleteCount장을 확인할까요?';
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
  String get assetReloadPreview => '미리보기 다시 불러오기';

  @override
  String get assetSizeUnknown => '크기 확인 불가';

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
    return '$count바이트';
  }

  @override
  String get appName => '클린업 마스터';

  @override
  String get nativePhotoRead =>
      '허용한 사진과 동영상에 접근하여 미리 보고 정리한 뒤 삭제할 항목을 확인할 수 있습니다.';

  @override
  String get nativePhotoAdd => '확인하면 압축한 동영상 사본을 사진 앱에 저장합니다. 원본은 유지됩니다.';

  @override
  String get nativeContacts => '연락처에 접근하여 중복된 연락처 정보를 정리하는 데 도움을 줍니다.';

  @override
  String get nativeTracking => '맞춤형 경험을 제공하고 서비스를 개선하기 위해 추적을 허용합니다.';

  @override
  String get serviceSubscriptionsUnavailable =>
      '현재 구독을 이용할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get serviceSubscriptionInitFailed =>
      '구독 서비스에 연결할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get serviceNoPlans => '현재 이용 가능한 구독 요금제가 없습니다. 나중에 다시 시도하세요.';

  @override
  String get servicePlansLoadFailed => '요금제를 불러올 수 없습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get servicePurchaseUnavailable => '현재 구매할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get servicePurchaseFailed => '구매가 완료되지 않았습니다. 나중에 다시 시도하세요.';

  @override
  String get serviceRestoreUnavailable => '현재 구매를 복원할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get serviceNoSubscription => '유효한 Pro 구독을 찾지 못했습니다.';

  @override
  String get serviceRestoreFailed => '구매를 복원할 수 없습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get servicePurchaseCancelled => '구매를 취소했습니다.';

  @override
  String get serviceScanPaused =>
      '일시 중지했습니다. 읽거나 분석한 결과는 유지됩니다. 스캔을 계속할 수 있습니다.';

  @override
  String get serviceLimitedLibrary => '허용한 사진만 포함되며 전체 사진 보관함을 대상으로 하지 않습니다.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      '이 기기에서는 원본 파일 분석을 이용할 수 없습니다. 크기와 완전 중복 여부는 검증되지 않았습니다.';

  @override
  String get serviceOriginalVerificationNeeded =>
      '기기 내 원본을 검증하여 파일 크기와 완전 중복을 확인하세요. 대용량 또는 클라우드 항목은 계속 대기 상태일 수 있습니다. 검증되지 않은 크기는 추정하지 않습니다.';

  @override
  String get serviceReadingIndex => '사진 보관함 색인 읽는 중';

  @override
  String get servicePhotoPermission =>
      '사진 접근이 허용되지 않았습니다. 설정에서 접근을 허용한 뒤 다시 시도하세요.';

  @override
  String get serviceOriginalRoundLimit =>
      '이번 검증이 60초에 도달했습니다. 결과는 유지됩니다. 다시 검증하면 아직 시도하지 않은 항목부터 처리합니다.';

  @override
  String get servicePreviewRoundLimit =>
      '이번 미리보기 처리가 30초에 도달했습니다. 결과는 유지됩니다. 계속하면 아직 시도하지 않은 사진부터 처리합니다.';

  @override
  String get serviceReadTimeout =>
      '일부 읽기 시간이 초과되었습니다. 현재 결과는 유지되며 스캔을 계속할 수 있습니다.';

  @override
  String get serviceReadInterrupted =>
      '사진 보관함 읽기가 일부 중단되었습니다. 현재 결과는 유지되며 스캔을 계속할 수 있습니다.';

  @override
  String get serviceVerifyingOriginals => '기기 내 원본 검증 중';

  @override
  String get serviceGroupingSimilar => '시각적으로 비슷한 후보 그룹화 중';

  @override
  String get serviceQualityLowDetail => '미리보기의 세부 정보가 부족하여 화질을 기준으로 추천할 수 없음';

  @override
  String get serviceQualityDecodeFailed => '미리보기를 디코딩하지 못해 화질을 평가하지 않음';

  @override
  String get serviceQualityLowInformation => '이미지 정보가 부족하여 화질을 기준으로 추천할 수 없음';

  @override
  String get serviceQualityClearEdges => '미리보기의 윤곽이 더 선명함';

  @override
  String get serviceQualityLessDetail => '미리보기 윤곽의 세부 정보가 적음';

  @override
  String get serviceQualityDark => '이미지가 어두워 보임';

  @override
  String get serviceQualityBright => '이미지가 밝아 보임';

  @override
  String get serviceQualityBalanced => '전체적인 밝기가 균형 잡힘';

  @override
  String get serviceKeepExact => '원본과 편집된 리소스가 완전히 일치합니다. 보관할 사본으로 추천합니다.';

  @override
  String get serviceKeepHigherResolution =>
      '이 그룹에서 해상도가 더 높아 보관을 추천합니다. 사진 내용을 확인하세요.';

  @override
  String get serviceVideoMissing => '동영상을 찾지 못했습니다. 다시 스캔하세요.';

  @override
  String get serviceVideoCloud =>
      '동영상이 iCloud에 있습니다. 사진 앱에서 원본을 다운로드한 뒤 다시 시도하세요.';

  @override
  String get serviceVideoUnreadable => '이 동영상을 읽을 수 없습니다.';

  @override
  String get serviceVideoPreviousBusy => '이전 압축이 아직 종료 중입니다. 잠시 후 다시 시도하세요.';

  @override
  String get serviceVideoTemporaryUnavailable => '동영상 임시 저장 공간을 준비할 수 없습니다.';

  @override
  String get serviceVideoUnsupported => '이 기기에서는 동영상 압축을 이용할 수 없습니다.';

  @override
  String get serviceVideoOutputInvalid => '출력 위치가 올바르지 않습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoSaveUnknown =>
      '저장된 사본을 확인할 수 없습니다. 다시 시도하기 전에 사진 앱을 확인하세요.';

  @override
  String get serviceVideoCancelled => '압축을 취소했습니다.';

  @override
  String get serviceVideoOperationBusy => '진행 중인 동영상 작업을 먼저 완료하세요.';

  @override
  String get serviceVideoEmpty => '원본이 비어 있어 압축할 수 없습니다.';

  @override
  String get serviceVideoEncodeFailed => '압축이 완료되지 않았습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoNoCopy => '압축으로 별도의 사본이 만들어지지 않았습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoNotSmaller => '압축한 동영상의 크기가 더 작지 않습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoDurationMismatch =>
      '압축한 동영상의 재생 시간이 일치하지 않습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoValidationFailed => '동영상을 검증할 수 없습니다. 원본은 유지됩니다.';

  @override
  String get serviceVideoPreviewFirst => '압축을 완료하고 먼저 미리보기를 확인하세요.';

  @override
  String get serviceVideoSaveFailed => '사본을 저장할 수 없습니다. 원본은 유지됩니다. 다시 시도하세요.';

  @override
  String get serviceVideoGenericFailed =>
      '작업이 완료되지 않았습니다. 원본은 유지됩니다. 사진 접근 권한과 여유 공간을 확인한 뒤 다시 시도하세요.';

  @override
  String get serviceOperationFailed => '작업을 완료할 수 없습니다. 다시 시도하세요.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return '접근 가능한 항목 $read / $total개 읽음.';
  }

  @override
  String servicePhotosPending(int count) {
    return '사진 $count장의 시각 분석이 아직 필요합니다. 계속하면 아직 시도하지 않은 사진부터 처리합니다. 클라우드 원본은 자동으로 다운로드하지 않습니다.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return '기기 내 미리보기 읽는 중 ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return '기기 내 미리보기 분석 중 ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; 추천은 참고용입니다';
  }

  @override
  String get scanSwipeIntro =>
      '왼쪽으로 밀면 삭제 후보, 오른쪽으로 밀면 보관합니다. 마지막 확인 후에만 삭제됩니다.';

  @override
  String get scanSwipeStart => '밀어서 정리 시작';

  @override
  String get scanDetails => '스캔 상세 정보';

  @override
  String get scanVerificationNeeded => '원본 파일 확인 전';

  @override
  String scanVerificationProgress(int verified, int total) {
    return '$verified / $total개 확인됨';
  }

  @override
  String get scanVerificationExplanation =>
      '파일 내용과 크기를 먼저 확인해야 완전히 같은 사진과 큰 파일을 볼 수 있습니다. 클라우드 항목은 나중에 처리해도 됩니다.';

  @override
  String get scanVerifyNow => '중복 및 큰 파일 확인';

  @override
  String get scanBrowsePhotos => '사진부터 정리';

  @override
  String get scanSelectAll => '이 분류 모두 선택';

  @override
  String get scanClearSelection => '선택 해제';

  @override
  String get scanKeepOneSelectOthers => '이 사진은 보관하고 나머지 선택';

  @override
  String get scanSelectOthersHint =>
      '보관 추천 사진을 미리 본 다음, 그룹의 나머지 사진을 한 번에 선택하세요.';

  @override
  String get scanNotChecked => '확인 대기';

  @override
  String scanPendingCheckCount(int count) {
    return '확인 대기 $count개';
  }

  @override
  String get swipeGestureTitle => '밀어서 빠르게 정리';

  @override
  String get swipeGestureDelete => '왼쪽으로 밀어 삭제 후보로 표시';

  @override
  String get swipeGestureKeep => '오른쪽으로 밀어 보관';

  @override
  String get swipeGestureSafety =>
      '사진은 먼저 삭제 후보 목록에 추가됩니다. 완료를 누르고 확인한 후에만 삭제됩니다.';

  @override
  String get swipeGestureHelp => '밀어서 정리하는 방법';

  @override
  String get homeSwipeDescription =>
      '사진을 한 장씩 좌우로 밀면 썸네일을 누르는 것보다 빠르게 정리할 수 있습니다.';

  @override
  String get scanCheckExactPhotos => '완전히 동일한 사진 확인';

  @override
  String get scanCheckFileSizes => '대용량 파일 크기 확인';

  @override
  String get reviewDeleteTitle => '삭제 항목 확인';

  @override
  String get reviewRemove => '삭제 목록에서 제외';

  @override
  String get reviewUnavailable => '미리 보기를 사용할 수 없습니다. 다시 시도하거나 이 항목을 제외하세요.';

  @override
  String reviewUnseenCount(int count) {
    return '삭제 전에 확인할 항목: $count';
  }

  @override
  String get reviewAllVersions => '그룹의 모든 사본이 선택되었습니다. 모두 삭제할까요?';

  @override
  String get reviewDeleteAllVersions => '모든 사본 삭제';

  @override
  String reviewConfirmCount(int count) {
    return '삭제 확인 · $count';
  }

  @override
  String swipeResumeReview(int count) {
    return '이전 확인 계속 · 확인한 항목 $count';
  }

  @override
  String get swipeResetReview => '처음부터 시작';

  @override
  String swipeBatchSize(int count) {
    return '한 번에 확인할 항목: $count';
  }

  @override
  String get swipeAllMonths => '모든 월';

  @override
  String get swipeReviewBatch => '월 또는 묶음 선택';

  @override
  String get assetVideoLoading => '원본 동영상 불러오는 중…';

  @override
  String get assetVideoUnavailable =>
      '원본 동영상을 사용할 수 없습니다. 사진 앱에서 다운로드한 뒤 다시 시도하세요.';

  @override
  String get homePermissionTitle => '사진 접근 권한이 필요해요';

  @override
  String get homePermissionDescription =>
      '설정에서 사진 접근을 허용하면 스캔하고 확인할 수 있습니다. 자동으로 삭제되지 않습니다.';

  @override
  String get homeOpenSettings => '설정 열기';

  @override
  String get homeManagePhotoAccess => '사진 접근 관리';

  @override
  String get homeReviewReady => '사용 가능한 사진 확인';

  @override
  String get homeContinueAnalysis => '사진 분석 계속';

  @override
  String get homeScanDetails => '스캔 상세 정보';

  @override
  String get scanCheckingExactTitle => '완전히 같은 사진 확인 중';

  @override
  String get scanCheckingSizesTitle => '파일 크기 확인 중';

  @override
  String scanRoundProgress(int total, int completed) {
    return '처리 완료 $completed / $total';
  }

  @override
  String get scanPauseReview => '검사 일시 중지 후 확인';

  @override
  String get scanSelectionHint => '체크하면 삭제 목록에 추가됩니다. 미리 보기를 눌러 내용을 확인하세요.';

  @override
  String get scanPreviewNotReady => '미리 보기를 불러온 뒤 선택하세요';

  @override
  String scanUnreadableExcluded(int count) {
    return '미리 보기를 불러오지 못해 선택에서 제외: $count';
  }

  @override
  String get scanKeepThis => '이 사진 보관';

  @override
  String get scanPreviewMore => '사진 더 불러오기';

  @override
  String homeKnownLibrarySize(int count, String size) {
    return '확인된 파일 크기: $size · 확인한 항목: $count';
  }

  @override
  String homePendingSizes(int count) {
    return '아직 크기를 확인하지 못한 항목: $count';
  }

  @override
  String get scanReviewChanged => '사진 또는 권한이 변경되었습니다. 삭제 목록을 다시 확인하세요.';

  @override
  String get paywallFreePreviewNote =>
      '사진 그룹화, 미리 보기, 스와이프 표시는 무료입니다. 확인 후 삭제와 동영상 압축에는 Pro가 필요합니다.';

  @override
  String paywallSubscribeWeekly(String price) {
    return '주간 구독 · $price';
  }

  @override
  String paywallSubscribeYearly(String price) {
    return '연간 구독 · $price';
  }

  @override
  String get paywallSubscribe => '구독하기';

  @override
  String paywallWeeklyRenewal(String price) {
    return '취소하지 않으면 매주 $price에 자동 갱신됩니다. 최종 조건은 App Store에서 확인하세요.';
  }

  @override
  String paywallYearlyRenewal(String price) {
    return '취소하지 않으면 매년 $price에 자동 갱신됩니다. 최종 조건은 App Store에서 확인하세요.';
  }

  @override
  String get paywallRenewalGeneric =>
      '취소하지 않으면 자동 갱신됩니다. 확인 전에 App Store에서 청구 기간과 금액을 확인하세요.';

  @override
  String get paywallLoadingPlans => '구독 요금제 불러오는 중…';

  @override
  String get paywallWaitingForStore => 'App Store 확인 대기 중…';

  @override
  String get paywallRestoring => '구매 복원 중…';

  @override
  String get settingsCheckingSubscription => '구독 확인 중…';

  @override
  String get settingsSubscriptionUnknown => '구독 상태를 확인할 수 없습니다';

  @override
  String get settingsManageSubscription => '구독 관리';

  @override
  String get settingsManageUnavailable =>
      '구독 관리를 열지 못했습니다. 스토어 계정 설정에서 구독을 여세요.';

  @override
  String get onboardingStartFree => '무료로 시작';

  @override
  String get swipeCheckpointSaveError =>
      '진행 상황을 저장하지 못했습니다. 계속 확인할 수 있지만 다음에 이어서 확인하지 못할 수 있습니다.';

  @override
  String swipeCheckpointLimit(int count) {
    return '이 기기에 보관하는 최근 선택: 최대 $count개';
  }

  @override
  String get scanSelectLoaded => '불러온 미리 보기 선택';

  @override
  String get homePhotoScopeChanged =>
      '사진 접근 범위가 바뀌었을 수 있습니다. 다시 스캔해 사용 가능한 사진을 갱신하세요.';
}
