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
  String get settingsConnectionSection => '連線';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogScope =>
      '目前內建美國 EPA Find-a-Car 官方快照；只代表該市場與快照內的配置，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String get settingsClose => '關閉';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return '解析：官方精確 $exact / $total 欄 · 本次確認 $sessionConfirmed / $total 欄 · 未解析 $unresolved / $total 欄 · 歧義 $ambiguous / $total 欄 · 衝突 $conflict / $total 欄';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '來源：官方／原廠 $official / $total 欄 · 手動 $user / $total 欄 · 通用 $generic / $total 欄 · 科學模型 $scientific / $total 欄';
  }

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
  }

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';
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
  String get settingsConnectionSection => '連線';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogScope =>
      '目前內建美國 EPA Find-a-Car 官方快照；只代表該市場與快照內的配置，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String get settingsClose => '關閉';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return '解析：官方精確 $exact / $total 欄 · 本次確認 $sessionConfirmed / $total 欄 · 未解析 $unresolved / $total 欄 · 歧義 $ambiguous / $total 欄 · 衝突 $conflict / $total 欄';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '來源：官方／原廠 $official / $total 欄 · 手動 $user / $total 欄 · 通用 $generic / $total 欄 · 科學模型 $scientific / $total 欄';
  }

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
  }

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';
}
