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
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String get telemetryReload => '重新載入';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return '本機儲存 $groups / $groupLimit 組，$used / $byteLimit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryCancel => '取消';

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryPlay => '播放';

  @override
  String get telemetryPause => '暫停';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String get telemetryExport => '匯出';

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
  }

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryDismissNotice => '關閉提示';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    return '$count 組沒有有效值的未完成檔已清理';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    return '$count 組損壞或衝突檔未自動修改';
  }

  @override
  String get telemetryRecoveryDamagedNote => '損壞內容不會用於回放或匯出，只能在安全狀態下手動刪除。';

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainCancel => '取消';

  @override
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
  }

  @override
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';
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
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String get telemetryReload => '重新載入';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return '本機儲存 $groups / $groupLimit 組，$used / $byteLimit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryCancel => '取消';

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryPlay => '播放';

  @override
  String get telemetryPause => '暫停';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String get telemetryExport => '匯出';

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
  }

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryDismissNotice => '關閉提示';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    return '$count 組沒有有效值的未完成檔已清理';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    return '$count 組損壞或衝突檔未自動修改';
  }

  @override
  String get telemetryRecoveryDamagedNote => '損壞內容不會用於回放或匯出，只能在安全狀態下手動刪除。';

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainCancel => '取消';

  @override
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
  }

  @override
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';
}
