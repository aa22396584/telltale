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
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個實驗單次唯讀';
  }

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令；實驗項目也只能逐次確認後讀一條。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainCancel => '取消';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return '本次連線已隔離：$reason';
  }

  @override
  String powertrainNotAuthorized(String reason) {
    return '未授權：$reason';
  }

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainInstallFailed(String reason) {
    return '無法安裝：$reason';
  }

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }
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
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個實驗單次唯讀';
  }

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令；實驗項目也只能逐次確認後讀一條。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainCancel => '取消';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return '本次連線已隔離：$reason';
  }

  @override
  String powertrainNotAuthorized(String reason) {
    return '未授權：$reason';
  }

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainInstallFailed(String reason) {
    return '無法安裝：$reason';
  }

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }
}
