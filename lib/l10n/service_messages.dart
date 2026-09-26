import 'app_localizations.dart';

// Translate service results at display time so retained scan state follows language changes.
String translateServiceMessage(AppLocalizations strings, String? message) {
  if (message == null || message.isEmpty) return '';
  return message
      .split('\n')
      .map((line) => _translateLine(strings, line))
      .join('\n');
}

String _translateLine(AppLocalizations s, String line) {
  switch (line) {
    case "尚未設定 RevenueCat API Key，訂閱功能暫時不可用。":
      return s.serviceSubscriptionsUnavailable;
    case "訂閱系統初始化失敗，請稍後再試。":
      return s.serviceSubscriptionInitFailed;
    case "目前沒有可顯示的訂閱方案。請確認 RevenueCat 產品 ID 與 App Store Connect 產品一致。":
      return s.serviceNoPlans;
    case "訂閱方案載入失敗，請檢查 RevenueCat、App Store Connect 產品與網路狀態。":
      return s.servicePlansLoadFailed;
    case "尚未設定 RevenueCat API Key，無法購買。":
      return s.servicePurchaseUnavailable;
    case "購買未完成，請稍後再試。":
      return s.servicePurchaseFailed;
    case "尚未設定 RevenueCat API Key，無法恢復購買。":
      return s.serviceRestoreUnavailable;
    case "找不到有效的 Pro 訂閱紀錄。":
      return s.serviceNoSubscription;
    case "恢復購買失敗，請檢查網路後再試。":
      return s.serviceRestoreFailed;
    case "已取消購買。":
      return s.servicePurchaseCancelled;
    case "已暫停，已讀取與分析的結果已保留，可繼續掃描。":
      return s.serviceScanPaused;
    case "僅整理你允許存取的照片，未讀取整個相簿。":
      return s.serviceLimitedLibrary;
    case "此裝置尚未提供本機原始素材分析，未確認容量與重複內容。":
      return s.serviceNativeAnalysisUnavailable;
    case "素材容量與完全重複另需驗證本機原始素材；大型或雲端素材可能仍待驗證，未驗證項目不估算容量。":
      return s.serviceOriginalVerificationNeeded;
    case "讀取相簿索引":
      return s.serviceReadingIndex;
    case "尚未取得相簿權限，請在設定中允許存取照片後重試。":
      return s.servicePhotoPermission;
    case "本輪原始素材驗證已達 60 秒，結果已保留；再次驗證會先處理未嘗試項目。":
      return s.serviceOriginalRoundLimit;
    case "本輪本機預覽分析已達 30 秒，結果已保留；繼續掃描會先處理未嘗試照片。":
      return s.servicePreviewRoundLimit;
    case "部分讀取逾時，已保留目前結果，可繼續掃描。":
      return s.serviceReadTimeout;
    case "部分相簿讀取中斷，已保留目前結果，可繼續掃描。":
      return s.serviceReadInterrupted;
    case "驗證本機原始素材":
      return s.serviceVerifyingOriginals;
    case "整理視覺相似候選":
      return s.serviceGroupingSimilar;
    case "縮圖較粗糙，未提供畫面品質建議":
      return s.serviceQualityLowDetail;
    case "無法解碼預覽，未評估畫面品質":
      return s.serviceQualityDecodeFailed;
    case "畫面資訊不足，不提供品質保留建議":
      return s.serviceQualityLowInformation;
    case "縮圖邊緣較清楚":
      return s.serviceQualityClearEdges;
    case "縮圖邊緣細節較少":
      return s.serviceQualityLessDetail;
    case "整體畫面偏暗":
      return s.serviceQualityDark;
    case "整體畫面偏亮":
      return s.serviceQualityBright;
    case "整體亮度適中":
      return s.serviceQualityBalanced;
    case "已確認原始及編輯素材內容完全相同，建議保留這一份":
      return s.serviceKeepExact;
    case "此群組中解析度較高，建議先保留；仍需確認照片內容":
      return s.serviceKeepHigherResolution;
    case "找不到這段影片，請重新掃描。":
      return s.serviceVideoMissing;
    case "影片尚在 iCloud，請先在照片 App 下載原片後重試。":
      return s.serviceVideoCloud;
    case "影片無法讀取。":
      return s.serviceVideoUnreadable;
    case "前一次壓縮仍在結束，請稍後重試。":
      return s.serviceVideoPreviousBusy;
    case "無法取得影片暫存位置。":
      return s.serviceVideoTemporaryUnavailable;
    case "此裝置尚未支援影片壓縮。":
      return s.serviceVideoUnsupported;
    case "壓縮輸出位置不符，原片已保留。":
      return s.serviceVideoOutputInvalid;
    case "無法確認另存結果，請先到照片 App 檢查。":
      return s.serviceVideoSaveUnknown;
    case "已取消壓縮。":
      return s.serviceVideoCancelled;
    case "請先完成目前的影片操作。":
      return s.serviceVideoOperationBusy;
    case "原片為空，無法壓縮。":
      return s.serviceVideoEmpty;
    case "壓縮未完成，原片已保留。":
      return s.serviceVideoEncodeFailed;
    case "壓縮未產生獨立副本，原片已保留。":
      return s.serviceVideoNoCopy;
    case "這段影片壓縮後沒有變小，原片已保留。":
      return s.serviceVideoNotSmaller;
    case "壓縮後長度不符，原片已保留。":
      return s.serviceVideoDurationMismatch;
    case "無法驗證影片內容，原片已保留。":
      return s.serviceVideoValidationFailed;
    case "請先完成壓縮與預覽。":
      return s.serviceVideoPreviewFirst;
    case "另存失敗，原片已保留，請重試。":
      return s.serviceVideoSaveFailed;
    case "操作未完成，原片已保留。請檢查照片權限、可用空間後重試。":
      return s.serviceVideoGenericFailed;
  }
  final match0 = RegExp(r'^已讀取 (\d+) / (\d+) 個可存取項目。$').firstMatch(line);
  if (match0 != null) {
    return s.serviceIndexReadCount(
      int.parse(match0.group(1)!),
      int.parse(match0.group(2)!),
    );
  }
  final match1 = RegExp(
    r'^(\d+) 張照片仍待視覺分析；繼續掃描會先處理尚未嘗試的照片，不自動下載雲端素材。$',
  ).firstMatch(line);
  if (match1 != null) {
    return s.servicePhotosPending(int.parse(match1.group(1)!));
  }
  final match2 = RegExp(r'^讀取本機預覽（(\d+) 張）$').firstMatch(line);
  if (match2 != null) {
    return s.serviceReadingPreviews(int.parse(match2.group(1)!));
  }
  final match3 = RegExp(r'^分析本機預覽（(\d+) 張）$').firstMatch(line);
  if (match3 != null) {
    return s.serviceAnalyzingPreviews(int.parse(match3.group(1)!));
  }
  const qualitySuffix = '；僅供保留參考';
  if (line.endsWith(qualitySuffix)) {
    final reasons = line
        .substring(0, line.length - qualitySuffix.length)
        .split('、');
    return s.serviceQualitySummary(
      reasons.map((reason) => _translateLine(s, reason)).join(' · '),
    );
  }
  // Unknown future results remain readable in the original language.
  if (s.localeName == 'zh_Hant' || s.localeName == 'zh') return line;
  return s.serviceOperationFailed;
}
