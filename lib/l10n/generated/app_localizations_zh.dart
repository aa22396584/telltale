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
  String get pidManagerHeadline => 'PID 管理';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String pidImportPickerFailed(String error) {
    return '無法開啟檔案選擇器：$error';
  }

  @override
  String pidImportReadFailed(String error) {
    return '讀取檔案失敗：$error';
  }

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
  }

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAdded(int count) {
    return '已加入 $count 項已確認支援 PID。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '仍有 $count 個支援區塊未確認，這次只加入已有正面證據的項目。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '將加入 $count 項。啟用越多 PID，單項資料的更新頻率可能降低。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidListSeparator => '、';
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
  String get pidManagerHeadline => 'PID 管理';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String pidImportPickerFailed(String error) {
    return '無法開啟檔案選擇器：$error';
  }

  @override
  String pidImportReadFailed(String error) {
    return '讀取檔案失敗：$error';
  }

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
  }

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAdded(int count) {
    return '已加入 $count 項已確認支援 PID。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '仍有 $count 個支援區塊未確認，這次只加入已有正面證據的項目。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '將加入 $count 項。啟用越多 PID，單項資料的更新頻率可能降低。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidListSeparator => '、';
}
