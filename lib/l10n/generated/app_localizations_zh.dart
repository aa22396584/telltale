// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Telltale';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get settingsHeadline => '設定';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcDismiss => '關閉';

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code 被確認的那一刻，這個控制器記下的數值。清除故障碼會一併銷毀這份紀錄。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '這個控制器有凍結幀，但沒有回應「裡面有哪些項目」的查詢，所以讀不到內容。可以重新掃描再試一次。';

  @override
  String get dtcFreezeFrameNothingDecodable => '這個控制器有凍結幀，但其中沒有本 App 能解讀的項目。';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcListSeparator => '、';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Telltale';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get settingsHeadline => '設定';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcDismiss => '關閉';

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code 被確認的那一刻，這個控制器記下的數值。清除故障碼會一併銷毀這份紀錄。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '這個控制器有凍結幀，但沒有回應「裡面有哪些項目」的查詢，所以讀不到內容。可以重新掃描再試一次。';

  @override
  String get dtcFreezeFrameNothingDecodable => '這個控制器有凍結幀，但其中沒有本 App 能解讀的項目。';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcListSeparator => '、';
}
