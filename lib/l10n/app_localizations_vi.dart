// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get onboardingSmartTitle => 'Dọn dẹp thông minh';

  @override
  String get onboardingSmartSubtitle =>
      'Quét ảnh và video bạn cho phép truy cập\nXem trước rồi chọn giữ lại hoặc xóa';

  @override
  String get onboardingPhotosTitle => 'Sắp xếp ảnh';

  @override
  String get onboardingPhotosSubtitle =>
      'So sánh ảnh trùng và ảnh tương tự theo nội dung\nKiểm tra từng ảnh được đề xuất giữ lại';

  @override
  String get onboardingSwipeTitle => 'Vuốt để sắp xếp';

  @override
  String get onboardingSwipeSubtitle =>
      'Vuốt để chọn giữ lại hoặc xóa\nXác nhận mọi lựa chọn khi hoàn tất';

  @override
  String get onboardingChoiceTitle => 'Bạn là người quyết định';

  @override
  String get onboardingChoiceSubtitle =>
      'Quét và xem trước ảnh miễn phí\nXóa và nén video cần Pro. Bản gốc không bao giờ bị xóa tự động.';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingPreparing => 'Đang chuẩn bị…';

  @override
  String get onboardingContinue => 'Tiếp tục';

  @override
  String get onboardingGetStarted => 'Bắt đầu';

  @override
  String get paywallTitle => 'Cleanup Pro';

  @override
  String get paywallClose => 'Đóng';

  @override
  String get paywallDescription =>
      'Mở khóa tính năng dọn dẹp ảnh và video. Xem trước rồi chọn mục cần xóa.';

  @override
  String get paywallReloadPlans => 'Tải lại các gói';

  @override
  String get paywallNotConfigured => 'Hiện chưa thể đăng ký';

  @override
  String get paywallContinue => 'Tiếp tục';

  @override
  String get paywallStoreNotice =>
      'Giao dịch được thực hiện qua App Store. Quản lý hoặc hủy đăng ký trong cài đặt Apple ID.';

  @override
  String get paywallRestorePurchases => 'Khôi phục giao dịch';

  @override
  String get paywallPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get paywallTerms => 'Điều khoản sử dụng';

  @override
  String get paywallPurchaseIncomplete =>
      'Giao dịch chưa hoàn tất. Vui lòng thử lại sau.';

  @override
  String get paywallRestored => 'Đã khôi phục quyền sử dụng Pro.';

  @override
  String get paywallRestoreNotFound => 'Không tìm thấy giao dịch để khôi phục.';

  @override
  String get paywallWeeklyPlan => 'Đăng ký theo tuần';

  @override
  String get paywallYearlyPlan => 'Đăng ký theo năm';

  @override
  String get paywallYearlySubtitle => 'Sắp xếp ảnh và video suốt cả năm';

  @override
  String get paywallWeeklySubtitle => 'Cho một đợt dọn dẹp ảnh ngắn';

  @override
  String get paywallPhotoFeature =>
      'Nhóm ảnh trùng và tương tự, rồi kiểm tra từng ảnh';

  @override
  String get paywallVideoFeature => 'Nén video, xem trước và lưu bản sao';

  @override
  String get paywallSwipeFeature => 'Sắp xếp nhanh bằng thao tác vuốt';

  @override
  String get paywallPlansUnavailable =>
      'Không tải được các gói đăng ký. Kiểm tra kết nối rồi tải lại.';

  @override
  String get paywallBestValue => 'Tiết kiệm nhất';

  @override
  String get videoTitle => 'Nén video';

  @override
  String get videoDescription =>
      'Nén sẽ giảm chất lượng và tạo một bản sao mới. Kiểm tra hình ảnh, âm thanh và hướng trước khi lưu vào Ảnh. Bản gốc được giữ lại.';

  @override
  String get videoProRequired =>
      'Tính năng này cần Pro. Quay lại trang dọn dẹp để xem các gói.';

  @override
  String get videoSaving => 'Đang lưu vào Ảnh. Vui lòng chờ đến khi hoàn tất.';

  @override
  String get videoCancelCompression => 'Hủy nén';

  @override
  String get videoLoadingPreview => 'Đang tải bản xem trước video…';

  @override
  String get videoCreatePreview => 'Tạo bản xem trước đã nén';

  @override
  String get videoStorageNotice =>
      'Lưu bản sao tạm thời dùng thêm dung lượng. Sau khi xóa bản gốc và dọn sạch Đã xóa gần đây, hãy kiểm tra dung lượng trống thực tế trong hệ thống.';

  @override
  String get videoViewOriginal => 'Xem bản gốc';

  @override
  String get videoViewCopy => 'Xem bản sao đã nén';

  @override
  String get videoSaved =>
      'Đã lưu bản sao vào Ảnh và giữ lại bản gốc. Quét lại từ Trang chủ, rồi chọn có xóa bản gốc hay không.';

  @override
  String get videoConfirmSave => 'Xác nhận bản sao và lưu vào Ảnh';

  @override
  String get videoPreviewUnavailable =>
      'Không phát được bản xem trước. Hãy thử lại. Bản gốc được giữ lại.';

  @override
  String get videoPlaybackUnavailable =>
      'Hiện không phát được video. Hãy tải lại bản xem trước.';

  @override
  String get videoOperationIncomplete =>
      'Thao tác chưa hoàn tất. Bản gốc được giữ lại. Kiểm tra quyền truy cập Ảnh và dung lượng trống, rồi thử lại.';

  @override
  String get videoPauseOriginal => 'Bản gốc: Tạm dừng';

  @override
  String get videoPlayOriginal => 'Bản gốc: Phát';

  @override
  String get videoPauseCopy => 'Bản sao đã nén: Tạm dừng';

  @override
  String get videoPlayCopy => 'Bản sao đã nén: Phát';

  @override
  String onboardingStep(int current, int total) {
    return '$current/$total';
  }

  @override
  String paywallBuild(String build) {
    return 'Bản dựng $build';
  }

  @override
  String videoCompressionProgress(int percent) {
    return 'Đang chuẩn bị / nén video $percent%';
  }

  @override
  String videoOriginalSize(String size) {
    return 'Bản gốc: $size';
  }

  @override
  String videoCopySize(String size) {
    return 'Bản sao: $size';
  }

  @override
  String videoSizeDifference(String size) {
    return 'Chênh lệch kích thước tệp: $size';
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
      'Kiểm tra dung lượng thiết bị trong Cài đặt iPhone. Tại đây, bạn có thể sắp xếp ảnh và video có thể truy cập.';

  @override
  String get homeViewIndexedPhotos => 'Xem ảnh đã đọc';

  @override
  String get homeViewIndexedScreenshots => 'Xem ảnh chụp màn hình đã đọc';

  @override
  String get homeCleanupTools => 'Công cụ dọn dẹp';

  @override
  String get homeQuickActions => 'Thao tác nhanh';

  @override
  String get homeAppName => 'Dọn dẹp';

  @override
  String get homeSubtitle => 'Xem trước rồi sắp xếp ảnh và video';

  @override
  String get homeProBadge => 'PRO';

  @override
  String get homeStorageUsed => 'Đã dùng';

  @override
  String get homeUsedLegend => 'Đã dùng';

  @override
  String get homeAvailableLegend => 'Còn trống';

  @override
  String get homeStartScanHint => 'Chưa quét. Chạm bên dưới để bắt đầu.';

  @override
  String get homeScanning => 'Đang quét…';

  @override
  String get homeDeleting => 'Đang xóa…';

  @override
  String get homeResumeScan => 'Tiếp tục quét và giữ tiến độ';

  @override
  String get homeScanAll => 'Quét tất cả ảnh và video có thể truy cập';

  @override
  String get homePreviewOrganize => 'Xem trước và sắp xếp';

  @override
  String get homeVerifyOriginals =>
      'Xác minh bản gốc trên máy: ảnh trùng hoàn toàn và kích thước';

  @override
  String get homeRetryPending => 'Tiếp tục quét / thử lại mục đang chờ';

  @override
  String get homeExactDuplicates => 'Ảnh trùng hoàn toàn';

  @override
  String get homeSimilarPhotos => 'Ảnh tương tự về hình ảnh';

  @override
  String get homeNotScanned => 'Chưa quét';

  @override
  String get homePendingAnalysis => 'Chờ phân tích hình ảnh';

  @override
  String get homeNoneAnalyzed => 'Không tìm thấy trong các mục đã phân tích';

  @override
  String get homeScreenshots => 'Ảnh chụp màn hình';

  @override
  String get homeLargeFiles => 'Tệp lớn';

  @override
  String get homeNoneFound => 'Không tìm thấy';

  @override
  String get homePendingVerification => 'Chờ xác minh bản gốc';

  @override
  String get homeNoneVerified => 'Không tìm thấy trong các mục đã xác minh';

  @override
  String get homeNeedsReview => 'Cần kiểm tra';

  @override
  String get homeCanReview => 'Kiểm tra';

  @override
  String get homeScanStatus => 'Quét';

  @override
  String get homeDoneStatus => 'Hoàn tất ✓';

  @override
  String get homePreviewPhotos => 'Xem trước ảnh';

  @override
  String get homeChooseKeep => 'Chọn mục giữ lại';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navClean => 'Dọn dẹp';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLoading => 'Đang tải…';

  @override
  String get settingsProPlan => 'Cleanup Pro';

  @override
  String get settingsFreePlan => 'Gói miễn phí';

  @override
  String get settingsUpgrade => 'Nâng cấp';

  @override
  String get settingsStorage => 'Dung lượng';

  @override
  String get settingsStorageTotal => 'Tổng';

  @override
  String get settingsStorageUsed => 'Đã dùng';

  @override
  String get settingsStorageAvailable => 'Còn trống';

  @override
  String get settingsGeneral => 'Chung';

  @override
  String get settingsProcessingSubscription => 'Đang xử lý đăng ký…';

  @override
  String get settingsRestorePurchases => 'Khôi phục giao dịch';

  @override
  String get settingsRestoredPro => 'Đã khôi phục đăng ký Pro.';

  @override
  String get settingsPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get settingsTerms => 'Điều khoản sử dụng';

  @override
  String get settingsRateApp => 'Đánh giá ứng dụng';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsVersion => 'Phiên bản';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsChooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get settingsSystemLanguage => 'Theo ngôn ngữ hệ thống';

  @override
  String homeUsedPercent(int percent) {
    return '$percent%';
  }

  @override
  String homeStorageTotal(String size) {
    return 'Tổng $size';
  }

  @override
  String homeIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đọc $count mục',
      one: 'Đã đọc 1 mục',
    );
    return '$_temp0';
  }

  @override
  String homeIndexedCountWithTotal(int count, int total) {
    return 'Đã đọc $count trong $total mục có thể truy cập';
  }

  @override
  String homeAnalysisSummary(int analyzed, int verified) {
    return 'Đã phân tích hình ảnh: $analyzed. Đã xác minh bản gốc: $verified. Bạn có thể hủy đề xuất giữ lại và tự quyết định mục cần xóa.';
  }

  @override
  String homePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
      one: '1 ảnh',
    );
    return '$_temp0';
  }

  @override
  String homePhotoCountPartial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh (kết quả một phần)',
      one: '1 ảnh (kết quả một phần)',
    );
    return '$_temp0';
  }

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
      one: '1 mục',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedPhotosPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xác minh $count ảnh; vẫn còn ảnh đang chờ',
      one: 'Đã xác minh 1 ảnh; vẫn còn ảnh đang chờ',
    );
    return '$_temp0';
  }

  @override
  String homeVerifiedItemsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xác minh $count mục; vẫn còn mục đang chờ',
      one: 'Đã xác minh 1 mục; vẫn còn mục đang chờ',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageSaveError =>
      'Không lưu được ngôn ngữ. Vui lòng thử lại.';

  @override
  String get scanSmartTitle => 'Dọn dẹp thông minh';

  @override
  String get scanCancelKeepProgress => 'Hủy quét và giữ tiến độ';

  @override
  String get scanSwipeCleanup => 'Dọn dẹp bằng thao tác vuốt';

  @override
  String get scanSortFileSize => 'Kích thước tệp';

  @override
  String get scanSortNewest => 'Mới nhất';

  @override
  String get scanStartAlbumTitle => 'Bắt đầu quét thư viện';

  @override
  String get scanIncompleteTitle => 'Quét chưa hoàn tất';

  @override
  String get scanStartAlbumDescription =>
      'Quét tất cả ảnh và video có thể truy cập. Xác minh nội dung bản gốc và phân tích hình ảnh giúp bạn kiểm tra trước khi quyết định.';

  @override
  String get scanContinue => 'Tiếp tục quét';

  @override
  String get scanStart => 'Bắt đầu quét';

  @override
  String get scanPreviewWhileRunning =>
      'Bạn có thể xem trước ảnh và ảnh chụp màn hình. Việc chọn, xóa và nén video tạm dừng trong khi quét.';

  @override
  String get scanExactDescription =>
      'Ảnh trùng hoàn toàn chỉ gồm các mục đã xác minh tài nguyên gốc. Bạn có thể hủy đề xuất giữ lại.';

  @override
  String get scanSimilarDescription =>
      'Các ảnh có thể tương tự xuất hiện khi bản xem trước trên máy được phân tích. Nội dung có thể khác nhau; đề xuất giữ lại chỉ để tham khảo.';

  @override
  String get scanLargeDescription =>
      'Sắp xếp theo kích thước tài nguyên đã xác minh. Kích thước tệp và dung lượng thực sự thu hồi có thể khác nhau; hệ thống quyết định dung lượng thu hồi.';

  @override
  String get scanManualDeleteDescription =>
      'Chỉ xóa những mục bạn tự chọn và xác nhận.';

  @override
  String get scanVerifyOriginals =>
      'Xác minh bản gốc trên máy: ảnh trùng hoàn toàn và kích thước';

  @override
  String get scanResumePending => 'Tiếp tục quét / thử lại mục đang chờ';

  @override
  String get scanKeepReasonDefault =>
      'Đây là ảnh được đề xuất giữ lại trong nhóm này.';

  @override
  String get scanRestoreKeepSuggestion => 'Hiện lại đề xuất giữ lại';

  @override
  String get scanDismissKeepSuggestion => 'Hủy đề xuất giữ lại';

  @override
  String get scanKeepManualHint =>
      'Đề xuất không tự động chọn mục. Chạm vào ảnh thu nhỏ để đánh dấu xóa.';

  @override
  String get scanEmptyUnverified =>
      'Một số tài nguyên gốc vẫn cần xác minh. Chưa thể xác định ảnh trùng hoàn toàn và tệp lớn. Bạn có thể xem trước ảnh và ảnh chụp màn hình.';

  @override
  String get scanEmptyVisualPending =>
      'Một số bản xem trước vẫn cần phân tích. Các ảnh có thể tương tự sẽ xuất hiện dần; bạn có thể xem trước ảnh và ảnh chụp màn hình.';

  @override
  String get scanEmptyIndexing =>
      'Thư viện vẫn đang được lập chỉ mục. Danh mục này sẽ cập nhật theo tiến độ.';

  @override
  String get scanEmptyCategory =>
      'Không có mục nào trong danh mục này thuộc các mục hiện đã phân tích hoặc xác minh.';

  @override
  String get scanKeepBadge => 'Đề xuất giữ lại';

  @override
  String get scanZoomPreview => 'Phóng to bản xem trước';

  @override
  String get scanCompressVideo => 'Nén video này';

  @override
  String get scanContentPending => 'Chờ phân tích nội dung';

  @override
  String get scanBackToCompare => 'Quay lại so sánh';

  @override
  String get scanConfirmDeleteTitle => 'Xóa các mục đã chọn này?';

  @override
  String get scanCancel => 'Hủy';

  @override
  String get scanNoItemsDeleted =>
      'Không có mục nào bị xóa. Thao tác có thể đã bị hủy hoặc thất bại.';

  @override
  String get scanConfirmDelete => 'Xác nhận xóa';

  @override
  String get scanCategoryPhotos => 'Ảnh';

  @override
  String get scanCategoryExact => 'Trùng hoàn toàn';

  @override
  String get scanCategorySimilar => 'Ảnh có thể tương tự';

  @override
  String get scanCategoryScreenshots => 'Ảnh chụp màn hình';

  @override
  String get scanCategoryVideos => 'Video';

  @override
  String get scanCategoryLarge => 'Tệp lớn';

  @override
  String scanExactGroupCount(int count) {
    return 'Trùng hoàn toàn: $count ảnh';
  }

  @override
  String scanSimilarGroupCount(int count) {
    return 'Ảnh có thể tương tự: $count ảnh';
  }

  @override
  String scanRecommendedKeep(String reason) {
    return 'Đề xuất giữ lại: $reason';
  }

  @override
  String scanSelectedCount(int count) {
    return 'Mục đã chọn: $count';
  }

  @override
  String scanPreviewDeleteCount(int count) {
    return 'Xem trước và xóa $count mục';
  }

  @override
  String scanConfirmDeleteDescription(int count) {
    return 'Đã chọn $count mục. Kiểm tra lựa chọn và đề xuất giữ lại trước khi xóa. Dung lượng thu hồi do hệ thống quyết định.';
  }

  @override
  String scanItemsDeleted(int count) {
    return 'Đã xóa $count mục.';
  }

  @override
  String get scanIndexingTitle => 'Đang lập chỉ mục thư viện ảnh';

  @override
  String get scanVerifyingTitle =>
      'Đang xác minh bản gốc để tìm ảnh trùng hoàn toàn';

  @override
  String get scanAnalyzingTitle => 'Đang phân tích bản xem trước ảnh trên máy';

  @override
  String get scanSlowOperationHint =>
      'Thao tác này đang mất nhiều thời gian hơn. Bạn có thể hủy, giữ tiến độ và tiếp tục sau.';

  @override
  String get scanProgressPreviewHint =>
      'Bạn có thể xem ảnh và ảnh chụp màn hình đã lập chỉ mục. Mục đang chờ tải xuống hoặc phân tích thất bại không bao giờ được coi là trùng hoàn toàn.';

  @override
  String get scanCountConfirming => 'Đang kiểm tra';

  @override
  String scanIndexedCount(int indexed, String total) {
    return 'Đã lập chỉ mục $indexed / $total mục';
  }

  @override
  String scanPreviewAttemptCount(int attempted, int total) {
    return 'Bản xem trước ảnh đã xử lý: $attempted / $total';
  }

  @override
  String scanOriginalAttemptCount(int attempted, int total) {
    return 'Tài nguyên gốc đã xử lý: $attempted / $total';
  }

  @override
  String scanVisualSuccessCount(int count) {
    return 'Phân tích hình ảnh hoàn tất: $count';
  }

  @override
  String scanOriginalVerifiedCount(int count) {
    return 'Bản gốc đã xác minh: $count';
  }

  @override
  String scanCloudPendingCount(int count) {
    return 'Chờ tải xuống: $count';
  }

  @override
  String scanStageRemainingCount(int count) {
    return 'Chưa xử lý trong giai đoạn này: $count';
  }

  @override
  String scanOperationWait(String operation, int seconds) {
    return '$operation · Đã chờ $seconds giây';
  }

  @override
  String get swipeKeep => 'Giữ lại';

  @override
  String get swipeDelete => 'Xóa';

  @override
  String get swipeReviewComplete => 'Kiểm tra hoàn tất!';

  @override
  String get swipeRecoveredSpaceHint =>
      'Dung lượng thu hồi do hệ thống quyết định.';

  @override
  String get swipeUndoChoice => 'Hoàn tác lựa chọn cuối';

  @override
  String get swipeBack => 'Quay lại';

  @override
  String get swipeConfirmDeleteTitle => 'Xóa những ảnh đã đánh dấu xóa?';

  @override
  String get swipeCancel => 'Hủy';

  @override
  String get swipeConfirmDelete => 'Xác nhận xóa';

  @override
  String get swipeNoPhotosDeleted =>
      'Không có ảnh nào bị xóa. Thao tác có thể đã bị hủy hoặc thất bại.';

  @override
  String get swipeExitTitle => 'Thoát phần kiểm tra này?';

  @override
  String get swipeContinueReview => 'Tiếp tục kiểm tra';

  @override
  String get swipeLeave => 'Thoát';

  @override
  String get swipeSkipRemainingTitle => 'Bỏ qua ảnh còn lại?';

  @override
  String get swipeDone => 'Xong';

  @override
  String swipeDoneCount(int count) {
    return 'Xong ($count)';
  }

  @override
  String swipeProgressCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String swipeDeleteCount(int count) {
    return 'Xóa: $count';
  }

  @override
  String swipeKeepCount(int count) {
    return 'Giữ lại: $count';
  }

  @override
  String swipeReviewSummary(int deleteCount, int keepCount) {
    return 'Xóa $deleteCount ảnh · Giữ lại $keepCount ảnh';
  }

  @override
  String swipeDeletePhotos(int count) {
    return 'Xóa $count ảnh';
  }

  @override
  String swipeConfirmDeleteDescription(int count) {
    return 'Xóa $count ảnh đã kiểm tra. Đảm bảo các mục bạn muốn giữ đã được chọn đúng.';
  }

  @override
  String swipePartialDeleted(int count) {
    return 'Đã xóa $count ảnh. Các ảnh còn lại chưa bị xóa.';
  }

  @override
  String swipeExitDescription(int count) {
    return 'Bạn đã đánh dấu $count ảnh để xóa. Thoát sẽ không xóa chúng.';
  }

  @override
  String swipeSkipRemainingDescription(int remaining, int deleteCount) {
    return 'Còn $remaining ảnh chưa kiểm tra. Kết thúc kiểm tra và xác nhận $deleteCount ảnh đã đánh dấu xóa?';
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
  String get assetReloadPreview => 'Tải lại bản xem trước';

  @override
  String get assetSizeUnknown => 'Không rõ kích thước';

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
  String get appName => 'Bậc thầy dọn dẹp';

  @override
  String get nativePhotoRead =>
      'Truy cập ảnh và video bạn cho phép để bạn xem trước, sắp xếp và xác nhận mục cần xóa.';

  @override
  String get nativePhotoAdd =>
      'Lưu bản sao video đã nén vào Ảnh khi bạn xác nhận. Bản gốc được giữ lại.';

  @override
  String get nativeContacts =>
      'Truy cập danh bạ để giúp sắp xếp thông tin liên hệ trùng lặp.';

  @override
  String get nativeTracking =>
      'Cho phép theo dõi để cá nhân hóa trải nghiệm và cải thiện dịch vụ.';

  @override
  String get serviceSubscriptionsUnavailable =>
      'Hiện chưa thể đăng ký. Vui lòng thử lại sau.';

  @override
  String get serviceSubscriptionInitFailed =>
      'Không thể kết nối dịch vụ đăng ký. Vui lòng thử lại sau.';

  @override
  String get serviceNoPlans =>
      'Hiện không có gói đăng ký khả dụng. Vui lòng thử lại sau.';

  @override
  String get servicePlansLoadFailed =>
      'Không tải được các gói. Kiểm tra kết nối rồi thử lại.';

  @override
  String get servicePurchaseUnavailable =>
      'Hiện chưa thể mua. Vui lòng thử lại sau.';

  @override
  String get servicePurchaseFailed =>
      'Giao dịch chưa hoàn tất. Vui lòng thử lại sau.';

  @override
  String get serviceRestoreUnavailable =>
      'Hiện chưa thể khôi phục giao dịch. Vui lòng thử lại sau.';

  @override
  String get serviceNoSubscription =>
      'Không tìm thấy đăng ký Pro đang hoạt động.';

  @override
  String get serviceRestoreFailed =>
      'Không khôi phục được giao dịch. Kiểm tra kết nối rồi thử lại.';

  @override
  String get servicePurchaseCancelled => 'Đã hủy giao dịch.';

  @override
  String get serviceScanPaused =>
      'Đã tạm dừng. Kết quả đã đọc và phân tích được giữ lại. Bạn có thể tiếp tục quét.';

  @override
  String get serviceLimitedLibrary =>
      'Chỉ gồm ảnh bạn cho phép, không phải toàn bộ thư viện.';

  @override
  String get serviceNativeAnalysisUnavailable =>
      'Thiết bị này không hỗ trợ phân tích tệp gốc. Kích thước và ảnh trùng hoàn toàn chưa được xác minh.';

  @override
  String get serviceOriginalVerificationNeeded =>
      'Xác minh bản gốc trên máy để xác nhận kích thước tệp và ảnh trùng hoàn toàn. Mục lớn hoặc trên đám mây có thể vẫn đang chờ; kích thước chưa xác minh không được ước tính.';

  @override
  String get serviceReadingIndex => 'Đang đọc chỉ mục thư viện';

  @override
  String get servicePhotoPermission =>
      'Chưa được phép truy cập ảnh. Cho phép truy cập trong Cài đặt rồi thử lại.';

  @override
  String get serviceOriginalRoundLimit =>
      'Lượt xác minh này đã đạt 60 giây. Kết quả được giữ lại; xác minh tiếp để ưu tiên mục chưa thử.';

  @override
  String get servicePreviewRoundLimit =>
      'Lượt xem trước này đã đạt 30 giây. Kết quả được giữ lại; tiếp tục để ưu tiên ảnh chưa thử.';

  @override
  String get serviceReadTimeout =>
      'Một số lượt đọc đã hết thời gian. Kết quả hiện tại được giữ lại; bạn có thể tiếp tục quét.';

  @override
  String get serviceReadInterrupted =>
      'Một số lượt đọc thư viện bị gián đoạn. Kết quả hiện tại được giữ lại; bạn có thể tiếp tục quét.';

  @override
  String get serviceVerifyingOriginals => 'Đang xác minh bản gốc trên máy';

  @override
  String get serviceGroupingSimilar => 'Đang nhóm các ảnh có thể tương tự';

  @override
  String get serviceQualityLowDetail =>
      'Bản xem trước có quá ít chi tiết để đề xuất dựa trên chất lượng';

  @override
  String get serviceQualityDecodeFailed =>
      'Không giải mã được bản xem trước; chưa đánh giá chất lượng';

  @override
  String get serviceQualityLowInformation =>
      'Thông tin hình ảnh không đủ để đề xuất dựa trên chất lượng';

  @override
  String get serviceQualityClearEdges => 'Đường nét bản xem trước rõ hơn';

  @override
  String get serviceQualityLessDetail =>
      'Đường nét bản xem trước ít chi tiết hơn';

  @override
  String get serviceQualityDark => 'Ảnh có vẻ tối';

  @override
  String get serviceQualityBright => 'Ảnh có vẻ sáng';

  @override
  String get serviceQualityBalanced => 'Độ sáng tổng thể cân bằng';

  @override
  String get serviceKeepExact =>
      'Tài nguyên gốc và đã chỉnh sửa khớp hoàn toàn. Đây là bản sao được đề xuất giữ lại.';

  @override
  String get serviceKeepHigherResolution =>
      'Độ phân giải cao hơn trong nhóm này. Đề xuất giữ lại; hãy kiểm tra nội dung ảnh.';

  @override
  String get serviceVideoMissing => 'Không tìm thấy video. Hãy quét lại.';

  @override
  String get serviceVideoCloud =>
      'Video ở trên iCloud. Tải bản gốc trong Ảnh rồi thử lại.';

  @override
  String get serviceVideoUnreadable => 'Không đọc được video này.';

  @override
  String get serviceVideoPreviousBusy =>
      'Lần nén trước vẫn đang kết thúc. Hãy thử lại trong chốc lát.';

  @override
  String get serviceVideoTemporaryUnavailable =>
      'Không chuẩn bị được nơi lưu video tạm thời.';

  @override
  String get serviceVideoUnsupported => 'Thiết bị này không hỗ trợ nén video.';

  @override
  String get serviceVideoOutputInvalid =>
      'Vị trí đầu ra không hợp lệ. Bản gốc được giữ lại.';

  @override
  String get serviceVideoSaveUnknown =>
      'Không xác nhận được bản sao đã lưu. Kiểm tra Ảnh trước khi thử lại.';

  @override
  String get serviceVideoCancelled => 'Đã hủy nén.';

  @override
  String get serviceVideoOperationBusy =>
      'Hoàn tất thao tác video hiện tại trước.';

  @override
  String get serviceVideoEmpty => 'Bản gốc trống nên không thể nén.';

  @override
  String get serviceVideoEncodeFailed =>
      'Nén chưa hoàn tất. Bản gốc được giữ lại.';

  @override
  String get serviceVideoNoCopy =>
      'Nén không tạo ra bản sao riêng. Bản gốc được giữ lại.';

  @override
  String get serviceVideoNotSmaller =>
      'Video đã nén không nhỏ hơn. Bản gốc được giữ lại.';

  @override
  String get serviceVideoDurationMismatch =>
      'Thời lượng video đã nén không khớp. Bản gốc được giữ lại.';

  @override
  String get serviceVideoValidationFailed =>
      'Không xác minh được video. Bản gốc được giữ lại.';

  @override
  String get serviceVideoPreviewFirst =>
      'Hoàn tất nén và kiểm tra bản xem trước trước tiên.';

  @override
  String get serviceVideoSaveFailed =>
      'Không lưu được bản sao. Bản gốc được giữ lại. Hãy thử lại.';

  @override
  String get serviceVideoGenericFailed =>
      'Thao tác chưa hoàn tất. Bản gốc được giữ lại. Kiểm tra quyền truy cập ảnh và dung lượng trống, rồi thử lại.';

  @override
  String get serviceOperationFailed =>
      'Không thể hoàn tất thao tác. Vui lòng thử lại.';

  @override
  String serviceIndexReadCount(int read, int total) {
    return 'Đã đọc $read / $total mục có thể truy cập.';
  }

  @override
  String servicePhotosPending(int count) {
    return '$count ảnh vẫn cần phân tích hình ảnh. Tiếp tục để ưu tiên ảnh chưa thử. Bản gốc trên đám mây không được tải tự động.';
  }

  @override
  String serviceReadingPreviews(int count) {
    return 'Đang đọc bản xem trước trên máy ($count)';
  }

  @override
  String serviceAnalyzingPreviews(int count) {
    return 'Đang phân tích bản xem trước trên máy ($count)';
  }

  @override
  String serviceQualitySummary(String reasons) {
    return '$reasons; đề xuất chỉ để tham khảo';
  }

  @override
  String get scanSwipeIntro =>
      'Vuốt trái để đánh dấu xóa, vuốt phải để giữ. Chỉ xóa sau khi xác nhận.';

  @override
  String get scanSwipeStart => 'Bắt đầu sắp xếp bằng vuốt';

  @override
  String get scanDetails => 'Chi tiết quét';

  @override
  String get scanVerificationNeeded => 'Chưa kiểm tra tệp gốc';

  @override
  String scanVerificationProgress(int verified, int total) {
    return 'Đã kiểm tra $verified / $total mục';
  }

  @override
  String get scanVerificationExplanation =>
      'Kiểm tra nội dung và dung lượng tệp trước để tìm bản trùng hoàn toàn và tệp lớn. Các mục trên đám mây có thể xử lý sau.';

  @override
  String get scanVerifyNow => 'Kiểm tra bản trùng và tệp lớn';

  @override
  String get scanBrowsePhotos => 'Sắp xếp ảnh trước';

  @override
  String get scanSelectAll => 'Chọn tất cả trong danh mục này';

  @override
  String get scanClearSelection => 'Bỏ chọn tất cả';

  @override
  String get scanKeepOneSelectOthers => 'Giữ ảnh này, chọn các ảnh khác';

  @override
  String get scanSelectOthersHint =>
      'Xem trước ảnh được đề xuất giữ, rồi chọn các ảnh còn lại trong nhóm cùng lúc.';

  @override
  String get scanNotChecked => 'Chờ kiểm tra';

  @override
  String scanPendingCheckCount(int count) {
    return '$count mục chờ kiểm tra';
  }

  @override
  String get swipeGestureTitle => 'Sắp xếp nhanh bằng vuốt';

  @override
  String get swipeGestureDelete => 'Vuốt trái để đánh dấu xóa';

  @override
  String get swipeGestureKeep => 'Vuốt phải để giữ';

  @override
  String get swipeGestureSafety =>
      'Ảnh được đưa vào danh sách chờ xóa trước. Chỉ xóa sau khi bạn nhấn Xong và xác nhận.';

  @override
  String get swipeGestureHelp => 'Cách sắp xếp bằng vuốt';

  @override
  String get homeSwipeDescription =>
      'Vuốt từng ảnh để sắp xếp nhanh hơn so với chạm vào ảnh thu nhỏ.';
}
