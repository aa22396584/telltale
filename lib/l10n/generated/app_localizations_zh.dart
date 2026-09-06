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
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '正在錄製';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '未錄製';

  @override
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get semanticsFieldSeparator => '，';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSelectionSaveFailed => '無法儲存趨勢顯示選擇';

  @override
  String trendSheetBody(int limit) {
    return '最多選擇 $limit 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完成 · $selected/$limit';
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
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '正在錄製';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '未錄製';

  @override
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get semanticsFieldSeparator => '，';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSelectionSaveFailed => '無法儲存趨勢顯示選擇';

  @override
  String trendSheetBody(int limit) {
    return '最多選擇 $limit 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完成 · $selected/$limit';
  }
}
