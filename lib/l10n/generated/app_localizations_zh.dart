// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectAnswerBleWithClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，那盒子上的 4.0 只是晶片規格，改用 Bluetooth Classic。';

  @override
  String get connectAnswerBleWithoutClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，先確認轉接器有通電，或改試 Wi‑Fi；此主機未開放 Bluetooth Classic。';

  @override
  String get connectAnswerClassic =>
      '選 Bluetooth Classic。先在系統設定裡配對完成，App 不能代替你配對。配對碼多半是 1234 或 0000。';

  @override
  String get connectAnswerWifiDesktop => '選 Wi-Fi。先把這台裝置連上那個網路，再回來輸入位址。';

  @override
  String get connectAnswerWifiPhone => '選 Wi-Fi。先把手機連上那個網路，再回來輸入位址。';

  @override
  String get connectBleBody =>
      'BLE 轉接器不需事先配對。搜尋後選擇你的裝置即可，常見名稱為 OBDII、V-LINK、Vgate 或 IOS-Vlink。';

  @override
  String connectBleEmptyScan(String next) {
    return '搜尋結束，沒有找到 BLE 轉接器。依序確認：轉接器的燈有沒有亮 —— 多數 OBD 插座要電門轉到 ON 才供電；再來是距離，先坐進車裡再搜尋；${next}BLE 轉接器不需要、也不應該在系統設定裡配對，那條路走不通。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最後看盒子上的規格，如果寫的是 2.0 或 3.0，那是 Bluetooth Classic，不會出現在這份清單裡，請改用上面的 Bluetooth Classic。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最後看盒子上的規格：若寫的是 2.0／3.0 或只有 Wi‑Fi，請改試 Wi‑Fi（此主機未開放 Bluetooth Classic）。';

  @override
  String get connectBlePermissionDeniedForever =>
      '藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。';

  @override
  String get connectBlePermissionNeeded => '需要藍牙權限才能搜尋。';

  @override
  String get connectBleScan => '搜尋 BLE 裝置';

  @override
  String get connectBleScanning => '搜尋中…';

  @override
  String get connectBleUnavailableHost => 'Bluetooth LE 在此主機尚不可用';

  @override
  String get connectBluetoothOff => '藍牙未開啟，請先在系統設定開啟藍牙。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '藍牙權限已被永久拒絕，請到系統設定開啟後再試。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '需要藍牙權限才能列出已配對的轉接器。';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get connectCancel => '取消';

  @override
  String get connectClassicEmptyLinuxPort =>
      '找不到藍牙序列埠（/dev/rfcomm*）。請先以 BlueZ 配對 ELM327，再用 rfcomm bind（或等效）建立 RFCOMM TTY 後重試。';

  @override
  String get connectClassicEmptyPaired =>
      '找不到已配對的轉接器。請先到系統藍牙設定完成配對（多數 ELM327 的配對碼為 1234 或 0000）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      '找不到藍牙序列埠（COMx）。請先在 Windows 藍牙設定配對 ELM327，確認裝置管理員出現「Standard Serial over Bluetooth link」。';

  @override
  String get connectClassicListLinuxPort =>
      '這裡列出 BlueZ 已綁定的藍牙序列埠（/dev/rfcomm* 或等效）。空清單代表系統尚未建立 RFCOMM 節點，不是 App 壞掉。';

  @override
  String get connectClassicListPaired =>
      '這裡列出系統上所有已配對的裝置 — 耳機、喇叭也會在內，看起來像轉接器的排在前面。選錯了就按「取消」，不必等它自己失敗，取消後可以馬上改選別的。';

  @override
  String get connectClassicListWindowsPort =>
      '這裡列出與藍牙關聯的 COM 埠（「Standard Serial over Bluetooth link」）。空清單代表系統尚未建立虛擬序列埠，不是 App 壞掉。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）目前在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）與 Linux（/dev/rfcomm*）可用';

  @override
  String get connectClassicUnavailableIos => 'iOS 不開放第三方 App 使用藍牙 SPP';

  @override
  String get connectConnect => '連線';

  @override
  String get connectDemoBody =>
      '模擬一具 2.0L 渦輪四缸引擎，含怠速、加速、巡航與減速循環，訊號彼此物理相關（換檔時轉速下降但車速續增）。故障碼、VIN 讀取與 fastMode 批次查詢皆可完整操作。';

  @override
  String get connectDemoStart => '啟動模擬器';

  @override
  String get connectHandshakeTitle => 'ELM327 初始化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初始化（上次嘗試）';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectLastAdapterConnect => '直接連線';

  @override
  String get connectLastAdapterForget => '忘記';

  @override
  String get connectLastAdapterTitle => '上次用的轉接器';

  @override
  String get connectOpenAppSettings => '開啟應用程式設定';

  @override
  String get connectOpenSystemSettings => '開啟系統設定';

  @override
  String get connectOpeningConnection => '建立連線中…';

  @override
  String get connectPairedPill => '已配對';

  @override
  String get connectQuestionBle => '盒子、賣場標題或裝置名稱上有 BLE、4.0、5.0 這些字？';

  @override
  String get connectQuestionClassic => '都不是 —— 比較舊、盒子上寫 2.0 或 3.0？';

  @override
  String get connectQuestionWifiDesktop =>
      '系統的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectQuestionWifiPhone =>
      '手機的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectSearchAgain => '重新搜尋';

  @override
  String connectSignalStrength(int bars, int total) {
    return '訊號強度 $bars/$total';
  }

  @override
  String get connectTranscriptKept => '這次嘗試的完整往返紀錄留著了。帶回來比一句訊息有用。';

  @override
  String get connectWhichIntro => '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：';

  @override
  String get connectWhichNoteGuessing =>
      '猜錯不會怎麼樣 —— 連不上就退回來換另一個試。真的卡住，先用最下面的「Demo 模擬器」確認 App 本身正常。';

  @override
  String get connectWhichNoteIos =>
      'iPhone 只能用 Wi-Fi 或 BLE —— 一般的藍牙 ELM327 在 iOS 上完全不能用，這是系統限制，換 App 也一樣。';

  @override
  String get connectWhichTitle => '不確定要選哪一個？';

  @override
  String get connectWifiHostLabel => 'IP 位址';

  @override
  String get connectWifiHostRequired => '請輸入轉接器的 IP 位址。';

  @override
  String get connectWifiInstructionsDesktop =>
      '請先將這台電腦連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若提示此網路無法連上網際網路，請選擇繼續使用。桌面系統通常會把熱點當預設路由；不需要 Android 那套 Wi-Fi 路由綁定。';

  @override
  String get connectWifiInstructionsPhone =>
      '請先將手機連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若問「此 Wi-Fi 無法連上網際網路，是否繼續使用」，選繼續使用。在 Android 上，App 連線時會嘗試把流量固定在 Wi-Fi 路由，避免被行動數據搶走。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」不是有效的通訊埠，範圍是 $min–$max。';
  }

  @override
  String get connectWifiPortLabel => '埠';

  @override
  String connectWifiPortRequired(int port) {
    return '請輸入通訊埠（多數轉接器為 $port）。';
  }

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusFormula => '公式';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String get dtcDismiss => '關閉';

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
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get fieldEventBody =>
      '只在車輛完全停妥時，由乘客或停車中的操作人員按下。事件會與 OBD 原始資料使用同一條時間軸並嘗試立即保存。';

  @override
  String get fieldEventEngineStarted => '引擎發動';

  @override
  String get fieldEventHeading => '實車事件標記';

  @override
  String get fieldEventIgnitionOn => '電門 ON';

  @override
  String get fieldEventMemoryOnly => '已記在目前工作階段，但自動保存失敗；請立刻匯出紀錄。';

  @override
  String fieldEventRecorded(String marker) {
    return '已記錄並保存：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '道路測試開始';

  @override
  String get fieldEventThrottleBlip => '輕踩油門';

  @override
  String get fieldEventUnavailable => '目前沒有可記錄的實車連線。';

  @override
  String get gaugeNoData => '無資料';

  @override
  String gaugeNoDataBecause(String reason) {
    return '無資料 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（資料已過期）';
  }

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navDtc => '故障碼';

  @override
  String get navPerformance => '性能';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '設定';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
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
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String pidImportPickerFailed(String error) {
    return '無法開啟檔案選擇器：$error';
  }

  @override
  String pidImportReadFailed(String error) {
    return '讀取檔案失敗：$error';
  }

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerHeadline => 'PID 管理';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String get powertrainCancel => '取消';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個實驗單次唯讀';
  }

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令；實驗項目也只能逐次確認後讀一條。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String powertrainInstallFailed(String reason) {
    return '無法安裝：$reason';
  }

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String powertrainNotAuthorized(String reason) {
    return '未授權：$reason';
  }

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return '本次連線已隔離：$reason';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String get recommendedPurchaseDisclosure =>
      '這是維護者的推廣分潤連結；符合條件的購買可能產生佣金。不是轉接器認證或購買保證。賣場內容與硬體版本可能變更，購買前請核對完整型號與 NCC 號碼。你也可以自行搜尋其他通路。';

  @override
  String get recommendedPurchaseHeading => '推薦轉接器';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型號 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '還沒有轉接器？在$store看推薦款';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '無法開啟$store連結';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '完整說明在設定';

  @override
  String get recommendedPurchaseShortDisclosureLead => '這是推廣分潤連結，不是轉接器認證。';

  @override
  String get recommendedPurchaseStoreShopee => '蝦皮';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '在$store查看';
  }

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsCatalogScope =>
      '目前內建美國 EPA Find-a-Car 官方快照；只代表該市場與快照內的配置，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsClose => '關閉';

  @override
  String get settingsConnectionSection => '連線';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsHeadline => '設定';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
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
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
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
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectAnswerBleWithClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，那盒子上的 4.0 只是晶片規格，改用 Bluetooth Classic。';

  @override
  String get connectAnswerBleWithoutClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，先確認轉接器有通電，或改試 Wi‑Fi；此主機未開放 Bluetooth Classic。';

  @override
  String get connectAnswerClassic =>
      '選 Bluetooth Classic。先在系統設定裡配對完成，App 不能代替你配對。配對碼多半是 1234 或 0000。';

  @override
  String get connectAnswerWifiDesktop => '選 Wi-Fi。先把這台裝置連上那個網路，再回來輸入位址。';

  @override
  String get connectAnswerWifiPhone => '選 Wi-Fi。先把手機連上那個網路，再回來輸入位址。';

  @override
  String get connectBleBody =>
      'BLE 轉接器不需事先配對。搜尋後選擇你的裝置即可，常見名稱為 OBDII、V-LINK、Vgate 或 IOS-Vlink。';

  @override
  String connectBleEmptyScan(String next) {
    return '搜尋結束，沒有找到 BLE 轉接器。依序確認：轉接器的燈有沒有亮 —— 多數 OBD 插座要電門轉到 ON 才供電；再來是距離，先坐進車裡再搜尋；${next}BLE 轉接器不需要、也不應該在系統設定裡配對，那條路走不通。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最後看盒子上的規格，如果寫的是 2.0 或 3.0，那是 Bluetooth Classic，不會出現在這份清單裡，請改用上面的 Bluetooth Classic。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最後看盒子上的規格：若寫的是 2.0／3.0 或只有 Wi‑Fi，請改試 Wi‑Fi（此主機未開放 Bluetooth Classic）。';

  @override
  String get connectBlePermissionDeniedForever =>
      '藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。';

  @override
  String get connectBlePermissionNeeded => '需要藍牙權限才能搜尋。';

  @override
  String get connectBleScan => '搜尋 BLE 裝置';

  @override
  String get connectBleScanning => '搜尋中…';

  @override
  String get connectBleUnavailableHost => 'Bluetooth LE 在此主機尚不可用';

  @override
  String get connectBluetoothOff => '藍牙未開啟，請先在系統設定開啟藍牙。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '藍牙權限已被永久拒絕，請到系統設定開啟後再試。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '需要藍牙權限才能列出已配對的轉接器。';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get connectCancel => '取消';

  @override
  String get connectClassicEmptyLinuxPort =>
      '找不到藍牙序列埠（/dev/rfcomm*）。請先以 BlueZ 配對 ELM327，再用 rfcomm bind（或等效）建立 RFCOMM TTY 後重試。';

  @override
  String get connectClassicEmptyPaired =>
      '找不到已配對的轉接器。請先到系統藍牙設定完成配對（多數 ELM327 的配對碼為 1234 或 0000）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      '找不到藍牙序列埠（COMx）。請先在 Windows 藍牙設定配對 ELM327，確認裝置管理員出現「Standard Serial over Bluetooth link」。';

  @override
  String get connectClassicListLinuxPort =>
      '這裡列出 BlueZ 已綁定的藍牙序列埠（/dev/rfcomm* 或等效）。空清單代表系統尚未建立 RFCOMM 節點，不是 App 壞掉。';

  @override
  String get connectClassicListPaired =>
      '這裡列出系統上所有已配對的裝置 — 耳機、喇叭也會在內，看起來像轉接器的排在前面。選錯了就按「取消」，不必等它自己失敗，取消後可以馬上改選別的。';

  @override
  String get connectClassicListWindowsPort =>
      '這裡列出與藍牙關聯的 COM 埠（「Standard Serial over Bluetooth link」）。空清單代表系統尚未建立虛擬序列埠，不是 App 壞掉。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）目前在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）與 Linux（/dev/rfcomm*）可用';

  @override
  String get connectClassicUnavailableIos => 'iOS 不開放第三方 App 使用藍牙 SPP';

  @override
  String get connectConnect => '連線';

  @override
  String get connectDemoBody =>
      '模擬一具 2.0L 渦輪四缸引擎，含怠速、加速、巡航與減速循環，訊號彼此物理相關（換檔時轉速下降但車速續增）。故障碼、VIN 讀取與 fastMode 批次查詢皆可完整操作。';

  @override
  String get connectDemoStart => '啟動模擬器';

  @override
  String get connectHandshakeTitle => 'ELM327 初始化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初始化（上次嘗試）';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectLastAdapterConnect => '直接連線';

  @override
  String get connectLastAdapterForget => '忘記';

  @override
  String get connectLastAdapterTitle => '上次用的轉接器';

  @override
  String get connectOpenAppSettings => '開啟應用程式設定';

  @override
  String get connectOpenSystemSettings => '開啟系統設定';

  @override
  String get connectOpeningConnection => '建立連線中…';

  @override
  String get connectPairedPill => '已配對';

  @override
  String get connectQuestionBle => '盒子、賣場標題或裝置名稱上有 BLE、4.0、5.0 這些字？';

  @override
  String get connectQuestionClassic => '都不是 —— 比較舊、盒子上寫 2.0 或 3.0？';

  @override
  String get connectQuestionWifiDesktop =>
      '系統的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectQuestionWifiPhone =>
      '手機的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectSearchAgain => '重新搜尋';

  @override
  String connectSignalStrength(int bars, int total) {
    return '訊號強度 $bars/$total';
  }

  @override
  String get connectTranscriptKept => '這次嘗試的完整往返紀錄留著了。帶回來比一句訊息有用。';

  @override
  String get connectWhichIntro => '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：';

  @override
  String get connectWhichNoteGuessing =>
      '猜錯不會怎麼樣 —— 連不上就退回來換另一個試。真的卡住，先用最下面的「Demo 模擬器」確認 App 本身正常。';

  @override
  String get connectWhichNoteIos =>
      'iPhone 只能用 Wi-Fi 或 BLE —— 一般的藍牙 ELM327 在 iOS 上完全不能用，這是系統限制，換 App 也一樣。';

  @override
  String get connectWhichTitle => '不確定要選哪一個？';

  @override
  String get connectWifiHostLabel => 'IP 位址';

  @override
  String get connectWifiHostRequired => '請輸入轉接器的 IP 位址。';

  @override
  String get connectWifiInstructionsDesktop =>
      '請先將這台電腦連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若提示此網路無法連上網際網路，請選擇繼續使用。桌面系統通常會把熱點當預設路由；不需要 Android 那套 Wi-Fi 路由綁定。';

  @override
  String get connectWifiInstructionsPhone =>
      '請先將手機連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若問「此 Wi-Fi 無法連上網際網路，是否繼續使用」，選繼續使用。在 Android 上，App 連線時會嘗試把流量固定在 Wi-Fi 路由，避免被行動數據搶走。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」不是有效的通訊埠，範圍是 $min–$max。';
  }

  @override
  String get connectWifiPortLabel => '埠';

  @override
  String connectWifiPortRequired(int port) {
    return '請輸入通訊埠（多數轉接器為 $port）。';
  }

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusFormula => '公式';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String get dtcDismiss => '關閉';

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
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get fieldEventBody =>
      '只在車輛完全停妥時，由乘客或停車中的操作人員按下。事件會與 OBD 原始資料使用同一條時間軸並嘗試立即保存。';

  @override
  String get fieldEventEngineStarted => '引擎發動';

  @override
  String get fieldEventHeading => '實車事件標記';

  @override
  String get fieldEventIgnitionOn => '電門 ON';

  @override
  String get fieldEventMemoryOnly => '已記在目前工作階段，但自動保存失敗；請立刻匯出紀錄。';

  @override
  String fieldEventRecorded(String marker) {
    return '已記錄並保存：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '道路測試開始';

  @override
  String get fieldEventThrottleBlip => '輕踩油門';

  @override
  String get fieldEventUnavailable => '目前沒有可記錄的實車連線。';

  @override
  String get gaugeNoData => '無資料';

  @override
  String gaugeNoDataBecause(String reason) {
    return '無資料 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（資料已過期）';
  }

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navDtc => '故障碼';

  @override
  String get navPerformance => '性能';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '設定';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
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
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String pidImportPickerFailed(String error) {
    return '無法開啟檔案選擇器：$error';
  }

  @override
  String pidImportReadFailed(String error) {
    return '讀取檔案失敗：$error';
  }

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerHeadline => 'PID 管理';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String get powertrainCancel => '取消';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個實驗單次唯讀';
  }

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令；實驗項目也只能逐次確認後讀一條。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String powertrainInstallFailed(String reason) {
    return '無法安裝：$reason';
  }

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String powertrainNotAuthorized(String reason) {
    return '未授權：$reason';
  }

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return '本次連線已隔離：$reason';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String get recommendedPurchaseDisclosure =>
      '這是維護者的推廣分潤連結；符合條件的購買可能產生佣金。不是轉接器認證或購買保證。賣場內容與硬體版本可能變更，購買前請核對完整型號與 NCC 號碼。你也可以自行搜尋其他通路。';

  @override
  String get recommendedPurchaseHeading => '推薦轉接器';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型號 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '還沒有轉接器？在$store看推薦款';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '無法開啟$store連結';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '完整說明在設定';

  @override
  String get recommendedPurchaseShortDisclosureLead => '這是推廣分潤連結，不是轉接器認證。';

  @override
  String get recommendedPurchaseStoreShopee => '蝦皮';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '在$store查看';
  }

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsCatalogScope =>
      '目前內建美國 EPA Find-a-Car 官方快照；只代表該市場與快照內的配置，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsClose => '關閉';

  @override
  String get settingsConnectionSection => '連線';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsHeadline => '設定';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
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
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
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
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';
}
