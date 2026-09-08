// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get adapterErrorActivityAlert => '匯流排活動警示';

  @override
  String get adapterErrorBufferFull => '轉接器緩衝區溢位';

  @override
  String get adapterErrorBus => '匯流排錯誤，可能是接線問題';

  @override
  String get adapterErrorBusBusy => '匯流排忙碌';

  @override
  String get adapterErrorBusInit => '匯流排初始化失敗';

  @override
  String get adapterErrorCan => 'CAN 匯流排錯誤';

  @override
  String get adapterErrorData => '收到的資料不正確';

  @override
  String get adapterErrorFeedback => '訊號回授錯誤';

  @override
  String get adapterErrorInternal => '轉接器內部錯誤';

  @override
  String get adapterErrorLowPowerAlert => '轉接器即將進入低功耗模式';

  @override
  String get adapterErrorLowVoltageReset => '電壓過低導致轉接器重置';

  @override
  String get adapterErrorNoData => '沒有收到回應（可能是暫時無回應，或車輛不支援）';

  @override
  String get adapterErrorStopped => '傳輸被中斷';

  @override
  String get adapterErrorUnableToConnect => '無法與 ECU 通訊，請確認電門已開啟';

  @override
  String get adapterErrorUnknownCommand => '轉接器不支援此指令';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectActivityAbortingPreviousConnection => '正在中止上一個連線，請稍候…';

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
  String get connectIssueAdapterAcceptedThenSilent =>
      '轉接器接受了連線，但在時限內沒有回應。通常是它還沒通電 —— 多數 OBD 插座要電門轉到 ON 才供電；也可能是它正被另一個 App 連著，先關掉那個再試。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '轉接器沒有回應重置指令（$command）。這個裝置可能不是 ELM327 轉接器，或是連到了錯誤的裝置。';
  }

  @override
  String get connectIssueAdapterStoppedResponding => '轉接器停止回應，連線已中斷。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '連線在建立過程中失敗了。請確認轉接器已通電、就在附近，然後再試一次。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectIssueHandshakeIncomplete => '初始化未通過，轉接器可能不相容。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初始化在 $command 失敗（$reason）。請確認轉接器已插好、車輛電門已開啟。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '上一個連線仍在中止中，轉接器還沒有釋放。請等幾秒再試一次。';

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
  String get connectTransportBleDescription => 'GATT UART — 較新的低功耗轉接器';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最常見的平價 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription => '內建模擬 ECU，無需硬體即可完整體驗';

  @override
  String get connectTransportDemoTitle => 'Demo 模擬器';

  @override
  String get connectTransportWifiDescription => 'TCP 通訊埠，多為 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

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
  String get dashboardBatchingEnabled => '已啟用批次';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardPollingModeHelpAction => '關於讀取模式';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「已啟用批次」代表 Telltale 可以把多個 PID 請求併成一次交握，以減少來回次數：這條匯流排允許嘗試併批，而且併批沒有被關掉。它仍然是授權而不是量測，因為某一次交握到底有沒有併起來，還要看這輛車確認支援哪些 PID，以及當下排了幾筆。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s 是過去一秒觀測到的速率，不是對延遲、新鮮度或準確度的保證。它會隨轉接器、匯流排、ECU、你選的 PID、每次回覆的大小以及錯誤而變動。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「單筆模式」代表每個 Mode 01 PID 各自讀取。三種情況會用到它：匯流排根本不接受併批請求（所有非 CAN 車輛都是如此）；還沒有任何支援區塊回應過，因為把車輛尚未確認的 PID 併起來問，正是回覆會過短的原因；以及併批的請求沒有回來成一份能拆回各 PID 的答覆（被截斷、轉接器回報緩衝區已滿，或根本沒有回應）。讀數仍會持續更新，這本身不等於連線失敗。';

  @override
  String get dashboardPollingModeHelpTitle => '讀取模式';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get datumBadgeCommunityDecode => '社群解碼';

  @override
  String get datumBadgeDemo => '示範';

  @override
  String get datumBadgeEstimated => '估算';

  @override
  String get datumBadgeExperimental => '實驗';

  @override
  String get datumBadgeFieldVerified => '已驗證';

  @override
  String get datumBadgeInvalid => '無效';

  @override
  String get datumBadgeJustUpdated => '剛更新';

  @override
  String get datumBadgeOutOfReferenceRange => '異常';

  @override
  String get datumBadgePartial => '部分';

  @override
  String get datumBadgeStale => '過期';

  @override
  String get datumBadgeTentativeDecode => '暫定解碼';

  @override
  String get datumBadgeUnverified => '未驗證';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '本車未驗證';

  @override
  String get datumBadgeUserSupplied => '使用者提供';

  @override
  String get datumGapModelYearUnknown => '年式未知';

  @override
  String get datumGapNoCatalogMatch => '型錄無匹配';

  @override
  String get datumGapVinNotRead => 'VIN 未讀到';

  @override
  String get datumNextStepEstimateOnly => '只影響此估算，其他讀值照用';

  @override
  String get datumNextStepGenericObd => '可繼續通用 OBD，或手動選車、補參數';

  @override
  String get datumNextStepOtherReadings => '失敗只影響此項，其他讀值照用';

  @override
  String get datumNextStepRawOnly => '可看 raw / error，不可當成正常數值';

  @override
  String get datumReasonAssumptionsUnconfirmed => '假設尚未確認，仍可估算';

  @override
  String get datumReasonBusError => '匯流排錯誤';

  @override
  String get datumReasonFormulaError => '公式錯誤';

  @override
  String get datumReasonFuelEstimateMissingInputs => '油耗缺少必要輸入';

  @override
  String get datumReasonHeaderNotOnThisBus => '標頭不符本車匯流排';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs => '馬力缺少必要輸入';

  @override
  String get datumReasonMalformedPacket => '壞封包，只可查看原文';

  @override
  String get datumReasonNoAnswer => '無回應，稍後重試';

  @override
  String get datumReasonNoReadingYet => '尚無讀值';

  @override
  String get datumReasonNonFiniteValue => '非有限數值';

  @override
  String get datumReasonOutOfReferenceRangeKept => '超出一般參考範圍，已保留';

  @override
  String get datumReasonPidUnsupported => '此車輛不支援這個 PID';

  @override
  String get datumReasonUnsafeService => '此服務不是唯讀查詢';

  @override
  String get datumReasonUnsafeServiceStopped => '此服務不是唯讀查詢，已停止發送';

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusFormula => '公式';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

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
  String get dtcClearCancelledBeforeSend => '清除已取消，指令還沒送出到車上。可以重新掃描後再試一次。';

  @override
  String get dtcClearConfirmed => '已送出清除指令。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '清除指令可能已經送到車上。不要再送一次 —— 第二次全車清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認還剩下什麼。';

  @override
  String get dtcClearFailureGeneric => '清除沒有完成。請先重新掃描，看目前的故障碼，再決定要不要再試。';

  @override
  String get dtcClearNotAccepted => '清除失敗，沒有控制器接受指令。可以再試一次。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '已有控制器回報清除完成，但其餘控制器無法確認。不要再送一次清除 —— 重複清除會讓已完成的控制器再一次重置排放就緒狀態。請重新掃描確認結果。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '上一次連線送出過清除指令，結果沒有確認。請先重新掃描，確認哪些故障碼還在，再決定要不要清除。';

  @override
  String get dtcClearRescanSettled => '上一次清除的結果無法完全確認，以下是重新掃描後的實際狀況。';

  @override
  String get dtcClearSentUnconfirmed =>
      '清除指令已送出，但回應在傳輸過程中損毀，無法確認車輛是否已清除。請重新掃描確認結果，不要直接再清除一次 —— 如果其實已經清除成功，再清一次會重置排放就緒狀態。';

  @override
  String get dtcClearTimeout => '清除指令送出後沒有回應，無法確認是否已清除。請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearUnexpected => '清除失敗，無法確認車輛是否已清除，請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcScanDisconnectedMidScan => '連線在掃描途中中斷，這次掃描沒有完成。';

  @override
  String get dtcScanInterrupted =>
      '掃描在中途被中斷（可能是切換到其他 App 或連線變更），沒有得到完整結果。請重新掃描。';

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
  String get dtcMonitorBoostPressure => '增壓壓力';

  @override
  String get dtcMonitorCatalyst => '觸媒轉換器';

  @override
  String get dtcMonitorComponents => '綜合元件監控';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 系統';

  @override
  String get dtcMonitorEvaporative => '蒸發排放系統';

  @override
  String get dtcMonitorExhaustSensor => '排氣感知器';

  @override
  String get dtcMonitorFuelSystem => '燃油系統監控';

  @override
  String get dtcMonitorGasolineParticulateFilter => '汽油微粒濾清器（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '觸媒加熱';

  @override
  String get dtcMonitorMisfire => '失火監控';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 觸媒';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 後處理';

  @override
  String get dtcMonitorOxygenSensor => '含氧感知器';

  @override
  String get dtcMonitorOxygenSensorHeater => '含氧感知器加熱';

  @override
  String get dtcMonitorParticulateFilter => '微粒濾清器';

  @override
  String get dtcMonitorSecondaryAir => '二次空氣噴射';

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
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get handshakeNoteAborted => '已中止';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECU 拒絕了支援度查詢（negative response）';

  @override
  String get handshakeNoteEcuSilent => 'ECU 沒有回應';

  @override
  String get handshakeNoteNotAcknowledged => '轉接器未確認此指令';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '回應不是 Mode 01 的正向回覆';

  @override
  String get handshakeNotePidEchoMismatch => '回應的 PID 與查詢不符';

  @override
  String get handshakeNoteSupportMaskTooShort => '支援度回應過短（需要 41 00 加四個位元組）';

  @override
  String get handshakeNoteTimedOut => '逾時';

  @override
  String get handshakeStepAdapterVersion => '讀取轉接器版本';

  @override
  String get handshakeStepAdaptiveTiming => '啟用自適應計時（datasheet 建議值）';

  @override
  String get handshakeStepBatteryVoltage => '讀取電瓶電壓';

  @override
  String get handshakeStepDeviceIdentity => '讀取裝置識別字串';

  @override
  String get handshakeStepEchoOff => '關閉指令回音';

  @override
  String get handshakeStepLinefeedsOff => '關閉換行字元';

  @override
  String get handshakeStepMemoryOff => '關閉記憶體寫入';

  @override
  String get handshakeStepNoReason => '無回應';

  @override
  String get handshakeStepProtocolAuto => '自動偵測匯流排協定';

  @override
  String get handshakeStepProtocolDescription => '讀取協定描述';

  @override
  String get handshakeStepProtocolNumber => '讀取協定編號';

  @override
  String get handshakeStepReset => '軟體重置轉接器';

  @override
  String get handshakeStepResponseTimeout => '設定回應逾時 ~408ms';

  @override
  String get handshakeStepSpacesOff => '關閉空白字元，減少 33% 傳輸量';

  @override
  String get handshakeStepSupportProbe => '查詢 ECU 支援的 PID（確認車輛已回應）';

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
  String get performanceArm => '準備計時';

  @override
  String get performanceDisclaimer =>
      '成績以 OBD 車速訊號為準。多數車輛的車速表本身有 1–3 km/h 的正偏差，且訊號更新率約每秒 10–20 次，因此結果僅供參考，不等同於專業測試設備。';

  @override
  String get performanceHeadline => '加速測試';

  @override
  String get performanceNoSpeedSignal => '目前沒有有效的車速訊號（PID 010D）。加速測試需要它才能計時。';

  @override
  String get performanceNotConnectedBody => '加速測試需要即時車速資料，請先連線或啟動模擬器。';

  @override
  String get performanceNotConnectedTitle => '尚未連線';

  @override
  String get performancePeakSpeed => '最高車速';

  @override
  String get performanceReset => '重置';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '車速';

  @override
  String get performanceSpeedTraceHeading => '速度軌跡';

  @override
  String get performanceSplitsHeading => '分段成績';

  @override
  String get performanceStateAborted => '車速訊號中斷 — 這次計時未完成，以下為中斷前的紀錄';

  @override
  String get performanceStateAwaitingSpeedSignal => '等待車速訊號';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '請先完全停車 — 目前 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '完成 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => '選擇目標車速後開始';

  @override
  String get performanceStateRunning => '計時中';

  @override
  String get performanceStateStaged => '已就緒 — 起步即開始計時';

  @override
  String get performanceSubhead => '由靜止起步計時至目標車速';

  @override
  String get performanceTargetSpeedHeading => '目標車速';

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
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
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
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

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
  String get powertrainInstallCatalogShaMissing =>
      '無法安裝：這份目錄快照沒有已驗證的 SHA-256，因此其中任何內容都不能信任。';

  @override
  String get powertrainInstallPersistFailed =>
      '無法安裝：已安裝設定檔清單無法寫入。請再試一次；PID 管理沒有新增任何項目。';

  @override
  String get powertrainInstallProfileNotInCatalog => '無法安裝：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '無法安裝：這個設定檔目前不能變成實際的 PID。';

  @override
  String get powertrainInstallYearOutOfRange => '無法安裝：該年式不在這個設定檔記載的年份範圍內。';

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
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '未授權：這個指令不屬於這份已驗證設定檔本身的指令。';

  @override
  String get powertrainRefusedLabClosed => '在這次讀取取得授權之前，大電池證據實驗室已被關閉。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。';

  @override
  String get powertrainRefusedProfileNotInCatalog => '未授權：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainRefusedProfileNotProbeable => '未授權：這個設定檔不是可以單次實驗讀取的設定檔。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '這次單次讀取沒有開始：目前沒有連線，或 App 不在前景。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '這次單次讀取沒有開始：目前沒有持有單次授權。授權不存在、已過期、冷卻中或已被隔離。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '單次讀取進行中，連線或前景狀態改變了，因此它的結果被丟棄而沒有顯示。沒有任何失敗，也沒有保留任何結果。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '本次連線已隔離：同一個指令已經嘗試 $attemptCap 次。請重新連線後再試。';
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
  String get semanticsFieldSeparator => '，';

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
  String get telemetryCancel => '取消';

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryDismissNotice => '關閉提示';

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
  String get telemetryExport => '匯出';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

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
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryPause => '暫停';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String get telemetryPlay => '播放';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
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
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String get telemetryReload => '重新載入';

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

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
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

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

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

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

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get wearBack => '返回';

  @override
  String get wearBatteryVoltageLabel => '電瓶';

  @override
  String get wearBleAdapters => 'BLE 轉接器';

  @override
  String get wearCancel => '取消';

  @override
  String get wearConfirmVehicle => '確認車輛';

  @override
  String get wearConfirmVehicleAccept => '就是這台車';

  @override
  String get wearConfirmVehicleBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String wearConnectFailed(String adapter) {
    return '連線失敗：$adapter';
  }

  @override
  String get wearConnecting => '連線中…';

  @override
  String get wearDemoSimulator => 'Demo 模擬器';

  @override
  String get wearDisconnect => '中斷';

  @override
  String get wearDisconnectQuestion => '中斷連線？';

  @override
  String get wearNoDevicesFound => '沒有找到裝置';

  @override
  String get wearPermissionBluetooth => '藍牙';

  @override
  String get wearPermissionLocation => '位置';

  @override
  String get wearScanAgain => '重新掃描';

  @override
  String get wearScanFailed => '掃描失敗，請再試一次';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '需要$permission權限才能掃描';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission權限已被永久拒絕，請到系統設定開啟後再試';
  }

  @override
  String get wearScanning => '掃描中…';

  @override
  String get telemetryRecorderNotRecording => '未錄製';

  @override
  String get dtcKindStored => '已儲存';

  @override
  String get dtcKindPending => '待確認';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '已確認的故障，儀表板故障燈通常亮起';

  @override
  String get dtcKindPendingExplanation => '偵測到一次，尚未達到確認門檻';

  @override
  String get dtcKindPermanentExplanation => '無法用診斷儀清除，需修復後由 ECU 自行確認';

  @override
  String get dtcSystemPowertrain => '動力系統';

  @override
  String get dtcSystemChassis => '底盤';

  @override
  String get dtcSystemBody => '車身';

  @override
  String get dtcSystemNetwork => '網路';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃油與空氣計量、輔助排放控制';

  @override
  String get dtcSubsystemFuelAirMetering => '燃油與空氣計量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit => '燃油與空氣計量（噴油嘴迴路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '點火系統或失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '輔助排放控制';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '車速控制與怠速系統';

  @override
  String get dtcSubsystemComputerOutputCircuit => '電腦輸出迴路';

  @override
  String get dtcSubsystemTransmission => '變速箱';

  @override
  String get dtcSubsystemControlModuleSignals => '控制模組輸入／輸出訊號';

  @override
  String get dtcDescriptionB0001 => '駕駛座安全氣囊裝置故障';

  @override
  String get dtcDescriptionP0011 => '「A」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0014 => '「B」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0016 => '曲軸與凸輪軸位置訊號不同步（Bank 1 感知器 A）';

  @override
  String get dtcDescriptionP0087 => '燃油軌／系統壓力過低';

  @override
  String get dtcDescriptionP0088 => '燃油軌／系統壓力過高';

  @override
  String get dtcDescriptionP0100 => '空氣流量感知器 (MAF) 電路故障';

  @override
  String get dtcDescriptionP0101 => '空氣流量感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0102 => '空氣流量感知器電路輸入過低';

  @override
  String get dtcDescriptionP0103 => '空氣流量感知器電路輸入過高';

  @override
  String get dtcDescriptionP0105 => '進氣歧管絕對壓力／大氣壓力感知器電路故障';

  @override
  String get dtcDescriptionP0106 => '進氣歧管絕對壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0107 => '進氣歧管絕對壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0108 => '進氣歧管絕對壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0110 => '進氣溫度感知器電路故障';

  @override
  String get dtcDescriptionP0111 => '進氣溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0112 => '進氣溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0113 => '進氣溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0115 => '冷卻液溫度感知器電路故障';

  @override
  String get dtcDescriptionP0116 => '冷卻液溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0117 => '冷卻液溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0118 => '冷卻液溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0120 => '節氣門位置感知器電路故障';

  @override
  String get dtcDescriptionP0121 => '節氣門位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0122 => '節氣門位置感知器電路輸入過低';

  @override
  String get dtcDescriptionP0123 => '節氣門位置感知器電路輸入過高';

  @override
  String get dtcDescriptionP0125 => '冷卻液溫度不足以進入閉迴路燃油控制';

  @override
  String get dtcDescriptionP0128 => '冷卻液溫度低於節溫器調節溫度';

  @override
  String get dtcDescriptionP0130 => '含氧感知器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 => '含氧感知器電路電壓過低 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 => '含氧感知器電路電壓過高 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 => '含氧感知器反應過慢 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 => '含氧感知器無活性訊號 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 => '含氧感知器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 => '含氧感知器電路電壓過低 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 => '含氧感知器電路電壓過高 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 => '含氧感知器無活性訊號 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 => '含氧感知器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 => '含氧感知器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => '燃油修正異常 (Bank 1)';

  @override
  String get dtcDescriptionP0171 => '混合比過稀 (Bank 1)';

  @override
  String get dtcDescriptionP0172 => '混合比過濃 (Bank 1)';

  @override
  String get dtcDescriptionP0173 => '燃油修正異常 (Bank 2)';

  @override
  String get dtcDescriptionP0174 => '混合比過稀 (Bank 2)';

  @override
  String get dtcDescriptionP0175 => '混合比過濃 (Bank 2)';

  @override
  String get dtcDescriptionP0190 => '燃油軌壓力感知器電路故障';

  @override
  String get dtcDescriptionP0201 => '噴油嘴電路故障／開路 — 第 1 缸';

  @override
  String get dtcDescriptionP0202 => '噴油嘴電路故障／開路 — 第 2 缸';

  @override
  String get dtcDescriptionP0203 => '噴油嘴電路故障／開路 — 第 3 缸';

  @override
  String get dtcDescriptionP0204 => '噴油嘴電路故障／開路 — 第 4 缸';

  @override
  String get dtcDescriptionP0217 => '引擎過熱';

  @override
  String get dtcDescriptionP0221 => '節氣門／油門踏板位置感知器 B 範圍或效能異常';

  @override
  String get dtcDescriptionP0222 => '節氣門／油門踏板位置感知器 B 電路輸入過低';

  @override
  String get dtcDescriptionP0223 => '節氣門／油門踏板位置感知器 B 電路輸入過高';

  @override
  String get dtcDescriptionP0234 => '渦輪／機械增壓過壓';

  @override
  String get dtcDescriptionP0299 => '渦輪／機械增壓「A」增壓不足';

  @override
  String get dtcDescriptionP0300 => '偵測到隨機/多缸失火';

  @override
  String get dtcDescriptionP0301 => '第 1 缸失火';

  @override
  String get dtcDescriptionP0302 => '第 2 缸失火';

  @override
  String get dtcDescriptionP0303 => '第 3 缸失火';

  @override
  String get dtcDescriptionP0304 => '第 4 缸失火';

  @override
  String get dtcDescriptionP0305 => '第 5 缸失火';

  @override
  String get dtcDescriptionP0306 => '第 6 缸失火';

  @override
  String get dtcDescriptionP0307 => '第 7 缸失火';

  @override
  String get dtcDescriptionP0308 => '第 8 缸失火';

  @override
  String get dtcDescriptionP0316 => '起動後隨即偵測到失火';

  @override
  String get dtcDescriptionP0325 => '爆震感知器電路故障 (Bank 1)';

  @override
  String get dtcDescriptionP0326 => '爆震感知器範圍/效能異常 (Bank 1)';

  @override
  String get dtcDescriptionP0327 => '爆震感知器電路輸入過低 (Bank 1)';

  @override
  String get dtcDescriptionP0328 => '爆震感知器電路輸入過高 (Bank 1)';

  @override
  String get dtcDescriptionP0330 => '爆震感知器電路故障 (Bank 2)';

  @override
  String get dtcDescriptionP0335 => '曲軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0336 => '曲軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0340 => '凸輪軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0341 => '凸輪軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0351 => '點火線圈 A 一次/二次電路故障';

  @override
  String get dtcDescriptionP0352 => '點火線圈 B 一次/二次電路故障';

  @override
  String get dtcDescriptionP0353 => '點火線圈 C 一次/二次電路故障';

  @override
  String get dtcDescriptionP0354 => '點火線圈 D 一次/二次電路故障';

  @override
  String get dtcDescriptionP0355 => '點火線圈 E 一次/二次電路故障';

  @override
  String get dtcDescriptionP0356 => '點火線圈 F 一次/二次電路故障';

  @override
  String get dtcDescriptionP0400 => '廢氣再循環 (EGR) 流量故障';

  @override
  String get dtcDescriptionP0401 => '廢氣再循環 (EGR) 流量不足';

  @override
  String get dtcDescriptionP0402 => '廢氣再循環 (EGR) 流量過大';

  @override
  String get dtcDescriptionP0403 => '廢氣再循環 (EGR) 控制電路故障';

  @override
  String get dtcDescriptionP0404 => '廢氣再循環 (EGR) 控制電路範圍/效能異常';

  @override
  String get dtcDescriptionP0410 => '二次空氣噴射系統故障';

  @override
  String get dtcDescriptionP0411 => '二次空氣噴射系統流量不正確';

  @override
  String get dtcDescriptionP0412 => '二次空氣噴射切換閥 A 電路故障';

  @override
  String get dtcDescriptionP0420 => '觸媒轉換器效率低於門檻 (Bank 1)';

  @override
  String get dtcDescriptionP0430 => '觸媒轉換器效率低於門檻 (Bank 2)';

  @override
  String get dtcDescriptionP0440 => '蒸發排放控制系統故障';

  @override
  String get dtcDescriptionP0441 => '蒸發排放系統清除流量不正確';

  @override
  String get dtcDescriptionP0442 => '蒸發排放系統偵測到小漏氣';

  @override
  String get dtcDescriptionP0443 => '蒸發排放清除閥控制電路故障';

  @override
  String get dtcDescriptionP0446 => '蒸發排放通風控制電路故障';

  @override
  String get dtcDescriptionP0447 => '蒸發排放通風控制電路開路';

  @override
  String get dtcDescriptionP0449 => '蒸發排放通風閥/電磁閥電路故障';

  @override
  String get dtcDescriptionP0451 => '蒸發排放壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0452 => '蒸發排放壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0453 => '蒸發排放壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0455 => '蒸發排放系統偵測到大漏氣';

  @override
  String get dtcDescriptionP0456 => '蒸發排放系統偵測到極小漏氣';

  @override
  String get dtcDescriptionP0480 => '冷卻風扇 1 控制電路故障';

  @override
  String get dtcDescriptionP0500 => '車速感知器故障';

  @override
  String get dtcDescriptionP0505 => '怠速控制系統故障';

  @override
  String get dtcDescriptionP0506 => '怠速轉速低於預期';

  @override
  String get dtcDescriptionP0507 => '怠速轉速高於預期';

  @override
  String get dtcDescriptionP0508 => '怠速控制電路輸入過低';

  @override
  String get dtcDescriptionP0509 => '怠速控制電路輸入過高';

  @override
  String get dtcDescriptionP0560 => '系統電壓故障';

  @override
  String get dtcDescriptionP0562 => '系統電壓過低';

  @override
  String get dtcDescriptionP0563 => '系統電壓過高';

  @override
  String get dtcDescriptionP0603 => '控制模組內部記憶體（KAM）錯誤';

  @override
  String get dtcDescriptionP0605 => '控制模組內部唯讀記憶體（ROM）錯誤';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 處理器故障';

  @override
  String get dtcDescriptionP0700 => '變速箱控制模組要求點亮故障燈 —— 故障碼在變速箱模組裡，請另外讀取';

  @override
  String get dtcDescriptionP0701 => '變速箱控制系統範圍/效能異常';

  @override
  String get dtcDescriptionP0702 => '變速箱控制系統電氣故障';

  @override
  String get dtcDescriptionP0705 => '排檔位置感知器電路故障';

  @override
  String get dtcDescriptionP0715 => '輸入軸／渦輪轉速感知器電路故障';

  @override
  String get dtcDescriptionP0720 => '輸出軸轉速感知器電路故障';

  @override
  String get dtcDescriptionP0730 => '檔位比不正確';

  @override
  String get dtcDescriptionP0740 => '扭力轉換器離合器電路故障';

  @override
  String get dtcDescriptionP0741 => '扭力轉換器離合器卡在未鎖定狀態';

  @override
  String get dtcDescriptionP0750 => '換檔電磁閥 A 故障';

  @override
  String get dtcDescriptionP0755 => '換檔電磁閥 B 故障';

  @override
  String get dtcDescriptionP2135 => '節氣門位置感知器 A/B 電壓不一致';

  @override
  String get dtcDescriptionU0100 => '與 ECM/PCM 失去通訊';

  @override
  String get dtcDescriptionU0101 => '與變速箱控制模組失去通訊';

  @override
  String get dtcDescriptionU0121 => '與 ABS 控制模組失去通訊';

  @override
  String get dtcDescriptionU0140 => '與車身控制模組失去通訊';

  @override
  String get dtcDescriptionU0155 => '與儀表板控制模組失去通訊';

  @override
  String get gaugeSkinCluster => '儀表艙';

  @override
  String get gaugeSkinClusterDescription => '車廠儀表板的樣子。指針、270 度刻度盤、凹陷的面盤。';

  @override
  String get gaugeSkinMinimal => '極簡';

  @override
  String get gaugeSkinMinimalDescription => '半圓弧、沒有指針、沒有刻度。要看的是數字，不是動作。';

  @override
  String get gaugeSkinTrack => '賽道';

  @override
  String get gaugeSkinTrackDescription => '分段燈條、無平滑動畫。數值到哪就是哪，不做過渡。';

  @override
  String get gaugeSkinClassic => '經典';

  @override
  String get gaugeSkinClassicDescription => '印刷式面盤、整圈數字、指針像機械錶一樣慢慢定位。';

  @override
  String get gaugeSkinNight => '夜視';

  @override
  String get gaugeSkinNightDescription => '夜間駕駛用。低亮度、淺弧、不做動畫，盡量不搶走注意力。';

  @override
  String get derivedAirflowSourceMaf => 'MAF 感測器';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density 推算';

  @override
  String get derivedAirflowSourceUnavailable => '進氣量無法取得';

  @override
  String get derivedFuelSourceStoichiometric => '化學計量比推算';

  @override
  String get derivedFuelSourceUnavailable => '油耗無法取得';

  @override
  String get telemetrySourceDemo => '內建模擬';

  @override
  String get telemetrySourceRig => '測試馬具';

  @override
  String get telemetrySourceFieldApp => '一般 field App 連線';

  @override
  String get fuelTypeGasoline => '汽油';

  @override
  String get fuelTypeDiesel => '柴油';

  @override
  String get fuelTypeLpg => '液化石油氣 (LPG)';

  @override
  String get fuelTypeEthanolE85 => 'E85 酒精汽油';

  @override
  String get drivetrainFwd => '前輪驅動';

  @override
  String get drivetrainRwd => '後輪驅動';

  @override
  String get drivetrainAwd => '四輪驅動';

  @override
  String get assumptionFieldMass => '車重';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '迎風面積';

  @override
  String get assumptionFieldRollingResistance => '滾動阻力';

  @override
  String get assumptionFieldDrivetrainEfficiency => '傳動效率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排氣量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '通用預設';

  @override
  String get vehicleFieldOriginUserEntered => '手動輸入';

  @override
  String get vehicleFieldOriginOfficialRegistry => '官方型錄';

  @override
  String get vehicleFieldOriginManufacturerPublication => '原廠資料';

  @override
  String get vehicleFieldOriginScientificModel => '模型係數';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value（$origin）';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '；';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF 可為 PID 0110 或 speed-density（RPM×MAP×排氣量×VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '估算使用記錄當下的車輛設定';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '回報的韌體版本 v$version 官方從未發行';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return '自稱 v$version，卻不認得 v1.1 就有的 ATPPS 指令';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '可程式參數摘要（ATPPS）從 ELM327 v1.1 起就存在，連 OBDLink 這類高階轉接器也支援。自稱的版本與實際實作的指令對不起來。';

  @override
  String get adapterConcernNoIdentitySummary => '不回應 AT@1（第一版就有的裝置識別指令）';

  @override
  String get adapterConcernNoIdentityDetail =>
      '這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。';

  @override
  String get telemetryReplaySampled => '預覽已抽樣；匯出保留完整已記錄事件';

  @override
  String get telemetryExportDisclosure =>
      '匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。';

  @override
  String get connectTransportCancelled => '連線嘗試在完成前被停止了。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '手機沒有連上任何 Wi-Fi 網路，沒有通往轉接器的路由。請先連上轉接器的 Wi-Fi 熱點再試一次。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '手機同時連著多個 Wi-Fi，無法判斷哪一個通往轉接器，所以沒有選任何一個。請先關閉不是轉接器的那些連線再試一次。';

  @override
  String get connectTransportWifiRouteRefused =>
      '系統拒絕讓這個連線走 Wi-Fi。手機是連著 Wi-Fi 的，只是不被允許用於這個連線。';

  @override
  String get connectTransportWifiRouteTimeout =>
      '系統沒有回應「讓這個連線走 Wi-Fi」的請求。請等幾秒再試一次。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '這個連線無法走 Wi-Fi，而系統沒有說明原因。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectTransportWifiHostUnreachable =>
      '那個位址沒有回應。請確認手機已連上轉接器的 Wi-Fi 熱點 —— 若系統問過「無法連上網際網路，是否繼續使用」，要選繼續使用。關閉行動數據也可能有幫助。';

  @override
  String get connectTransportWifiConnectTimeout => '那個位址在時限內沒有任何回應。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '連線本身成功了，但手機的網路路由無法恢復，所以連線被中斷，而不是把它改過的狀態留著。請重新開啟 App 再試一次。';

  @override
  String get connectTransportBleLinkFailed => '無法連線到轉接器。請確認它已通電且在範圍內。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '裝置連上了，但在它身上沒有找到序列埠，可能不是 ELM327 轉接器。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '無法連線到轉接器。請先在系統藍牙設定完成配對，並確認它已插上 OBD 埠且電門已開啟。';

  @override
  String get connectTransportClassicConnectTimeout =>
      '連線到轉接器逾時。它可能仍在回應中 —— 請等幾秒再試，不要立刻重試。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '無法開啟序列埠。請確認系統已為這個轉接器建立序列埠（Windows COMx / Linux /dev/rfcomm*），且電門已開啟。';

  @override
  String get connectTransportSerialDroppedOnOpen => '序列埠開啟後立刻又關閉了。';

  @override
  String get settingsManualCommandNotConnected => '目前沒有連線，這條指令沒有送出。';

  @override
  String get settingsManualCommandLinkDropped =>
      '這條指令還在等待回應時，與轉接器的連線中斷了，所以沒有任何回應。轉接器是否收到這條指令並不確定。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '這條指令還在等待回應時，App 主動關閉了連線，所以沒有任何回應。轉接器與車輛都沒有問題。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '轉接器的回應已經和送出的指令對不上，而它也沒有回應用來重新對齊的檢查，所以連線已中斷。請重新連線後再試一次。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '轉接器安靜得夠久，連線已被中斷。它可能仍有電；能確定的只有這段沉默。';

  @override
  String get settingsManualCommandWriteFailed =>
      '這條指令無法交給轉接器的連線。有多少內容送達轉接器並不確定。';

  @override
  String get settingsManualCommandOperationRetired => '這個工作階段已經結束或退到背景，指令沒有送出。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '這條要求在這輛車使用的匯流排上無法定址，因此沒有送出。再試一次也不會改變。';

  @override
  String get manualCommandRefusedEmpty => '沒有輸入指令。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '指令裡有換行或控制字元，這樣會一次送出多個指令。轉接器以換行分隔指令，所以第二個指令不會經過這裡的任何檢查 —— 包括禁止清除故障碼的那一項。請一次只輸入一個指令。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '手動指令只接受查詢，不接受會改變轉接器設定的指令。「$command」會改動轉接器狀態，而 App 對轉接器的認知不會跟著更新 —— 接下來的讀數可能來自另一個控制器，而畫面上看不出來。\n可用的查詢：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '清除故障碼請用故障碼畫面的「清除」按鈕。從這裡送出會跳過確認、覆蓋率檢查與回應驗證，而且只會清到目前選中的那一個控制器。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '指令「$command」含有 OBD 指令不會出現的字元。這裡只接受十六進位的服務碼與參數（例如 0100、03、2211A6），或 AT 開頭的轉接器查詢。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '不認得的指令「$command」。這裡只接受唯讀查詢（Mode $allowed）與轉接器查詢指令。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '轉接器拒絕將這條要求對準到控制器 $header，因此它沒有送出。如果留在轉接器實際持有的位址上，回應會來自沒有人詢問的控制器。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '轉接器拒絕切換到 $address 這個位址，而向全車提出的問題必須從它送出。沒有它，回應就無法對應到送出它們的控制器，因此這個要求沒有送出。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '這輛車使用的舊式匯流排沒有能觸及每個控制器的標準位址，而轉接器目前指定在控制器 $installed。掃描只會涵蓋那一個控制器，卻會被當成全車結果呈現，因此沒有送出。請重新連線後再掃描一次。';
  }

  @override
  String get pidFormulaEmpty => '公式是空的。';

  @override
  String get pidFormulaEmptySubExpression => '公式有一段是空的 —— 運算子後面沒有東西，或括號裡沒有內容。';

  @override
  String get pidFormulaUnbalancedParentheses => '括號沒有配對：每一個 ( 都需要一個對應的 )。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」不是數值、運算子，也不是這個編輯器認得的名稱。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS() 與 LOG10() 巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaParenthesisNestingTooDeep => '括號巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaDivisionByZero => '公式除以零。';

  @override
  String get pidFormulaModuloByZero => '公式對零取餘數。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String get pidFormulaResultNotFinite => '這串運算沒有得出可用的數值，因此沒有讀數可顯示。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '公式參照位元組 $letter，但回應只有 $count 個位元組。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '這裡無法使用 BARO，因為無法判斷指的是哪一個控制器的大氣壓力。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。請移除其中一個測量大氣壓力的錶。';

  @override
  String get pidFormulaBaroNotYetMeasured => '尚未取得大氣壓力量測值，無法計算。';

  @override
  String get pidFormulaBaroMeasurementStale => '大氣壓力量測值已過期，無法計算。';

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '這裡無法解析 $reference，因為無法判斷那個 PID 屬於哪一個控制器。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '有兩個定義同時解讀 $key，數值可能是其中任何一個，因此無法採用。請讓其中一個改用不同的模式+PID。注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，把面板上的錶移掉不會停止讀取它們。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '尚未取得相依 PID $key 的有效數值。';
  }

  @override
  String get pidFormulaUnidentified => '這個公式無法求值，而編輯器沒有更具體的原因可顯示。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '服務 $service 不是唯讀查詢，不能週期性發送到車上。只允許 $services（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '凍結幀查詢需要 PID 與幀編號兩個位元組，例如 020500（PID 05、第 0 幀）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier 需要兩個位元組的識別碼，例如 221101。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '服務 $service 的查詢需要 $bytes 個位元組的識別碼。';
  }

  @override
  String get pidRejectionNameRequired => '請輸入名稱。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」不是有效的標頭（11-bit CAN 為 3 碼、舊協定為 6 碼、29-bit CAN 為 8 碼）。';
  }

  @override
  String get pidRejectionBoundsRequired => '請填寫量程的上下限。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '量程下限「$text」不是有效的數值。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '量程上限「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionMinNotFinite => '量程下限必須是有限的數值。';

  @override
  String get pidRejectionMaxNotFinite => '量程上限必須是有限的數值。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '紅線起點「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionRedlineNotFinite => '紅線起點必須是有限的數值。';

  @override
  String get pidRejectionMaxNotAboveMin => '量程上限必須大於下限。';

  @override
  String pidImportMalformedCsv(String detail) {
    return '這個檔案無法以 CSV 讀取：$detail';
  }

  @override
  String get pidImportNoRows => '檔案沒有任何資料列。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '標題列有重複的欄位名稱：$columns。無法判斷該用哪一欄，請先修正檔案。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '標題列缺少必要欄位：$columns。$required 都是必要的。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '第 $line 行：欄位不足，至少需要名稱、簡稱、PID、公式。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '第 $line 行：「$text」不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '第 $line 行：公式為空。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '第 $line 行：量程留空，已套用預設 $min–$max。請確認這個刻度適合這個感測器。';
  }

  @override
  String get pidImportNothingImportable => '檔案裡有資料列，但沒有任何一列是 PID 定義。';

  @override
  String get dtcCategoryNoAnswer => '這個類別沒有回應。請重新掃描。';

  @override
  String get dtcCategoryError => '這個類別讀取失敗。完整錯誤保留在紀錄裡。';

  @override
  String get dtcCategoryDisconnected => '讀取這個類別時連線中斷。';

  @override
  String get dtcCategoryPending => '控制器已收到請求、仍在處理中。請稍候再掃描一次——這不是拒絕。';

  @override
  String get dtcCategoryUnattributed =>
      '有讀到故障碼，但回應標頭是關閉的，因此不知道是哪些控制器回答。這是部分結果，不是車輛正常。';

  @override
  String get connectPairedListFailed => '無法讀取已配對的藍牙清單。請確認藍牙已開啟後再試。';

  @override
  String get connectBleScanUnavailable => '藍牙目前無法使用。請稍後再搜尋。';

  @override
  String get connectBleScanBluez =>
      '找不到可用的 BlueZ／D-Bus 藍牙服務。請確認系統已安裝並啟動 bluetooth 服務後再試。';

  @override
  String get connectBleScanUnclassified => 'BLE 搜尋失敗。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，然後再試一次。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 目前忙碌中。請稍候再試一次。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。請稍候再試一次。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應清除指令（$controllers）。已回應的控制器已清除，其餘可能仍有故障碼。請重新掃描，不要再送一次清除。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，再重新掃描確認哪些故障碼還在。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 目前忙碌中。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String get sharePolicyDenied => '目前的連線或行車狀態不允許匯出。';

  @override
  String get shareSafetyChanged => '準備匯出期間狀態已改變，未開啟分享。';

  @override
  String get shareSizeLimit => '匯出檔超過 32 MiB 上限。';

  @override
  String get shareStagingBusy => '先前的分享檔仍在保留期內，請稍後再試。';

  @override
  String get shareCleanupRequired => '分享暫存區需要在重新啟動後檢查。';

  @override
  String get shareSpaceUnknown => '無法確認分享檔所需的可用空間。';

  @override
  String get shareNoSpace => '儲存空間不足，無法準備分享檔。';

  @override
  String get shareHandoffFailed => '檔案已準備完成，但系統分享介面無法開啟。';

  @override
  String get shareStorageFailure => '準備或記錄分享結果時發生儲存錯誤。';

  @override
  String get transcriptExportUnidentified => '匯出失敗。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get adapterErrorActivityAlert => '匯流排活動警示';

  @override
  String get adapterErrorBufferFull => '轉接器緩衝區溢位';

  @override
  String get adapterErrorBus => '匯流排錯誤，可能是接線問題';

  @override
  String get adapterErrorBusBusy => '匯流排忙碌';

  @override
  String get adapterErrorBusInit => '匯流排初始化失敗';

  @override
  String get adapterErrorCan => 'CAN 匯流排錯誤';

  @override
  String get adapterErrorData => '收到的資料不正確';

  @override
  String get adapterErrorFeedback => '訊號回授錯誤';

  @override
  String get adapterErrorInternal => '轉接器內部錯誤';

  @override
  String get adapterErrorLowPowerAlert => '轉接器即將進入低功耗模式';

  @override
  String get adapterErrorLowVoltageReset => '電壓過低導致轉接器重置';

  @override
  String get adapterErrorNoData => '沒有收到回應（可能是暫時無回應，或車輛不支援）';

  @override
  String get adapterErrorStopped => '傳輸被中斷';

  @override
  String get adapterErrorUnableToConnect => '無法與 ECU 通訊，請確認電門已開啟';

  @override
  String get adapterErrorUnknownCommand => '轉接器不支援此指令';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectActivityAbortingPreviousConnection => '正在中止上一個連線，請稍候…';

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
  String get connectIssueAdapterAcceptedThenSilent =>
      '轉接器接受了連線，但在時限內沒有回應。通常是它還沒通電 —— 多數 OBD 插座要電門轉到 ON 才供電；也可能是它正被另一個 App 連著，先關掉那個再試。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '轉接器沒有回應重置指令（$command）。這個裝置可能不是 ELM327 轉接器，或是連到了錯誤的裝置。';
  }

  @override
  String get connectIssueAdapterStoppedResponding => '轉接器停止回應，連線已中斷。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '連線在建立過程中失敗了。請確認轉接器已通電、就在附近，然後再試一次。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectIssueHandshakeIncomplete => '初始化未通過，轉接器可能不相容。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初始化在 $command 失敗（$reason）。請確認轉接器已插好、車輛電門已開啟。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '上一個連線仍在中止中，轉接器還沒有釋放。請等幾秒再試一次。';

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
  String get connectTransportBleDescription => 'GATT UART — 較新的低功耗轉接器';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最常見的平價 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription => '內建模擬 ECU，無需硬體即可完整體驗';

  @override
  String get connectTransportDemoTitle => 'Demo 模擬器';

  @override
  String get connectTransportWifiDescription => 'TCP 通訊埠，多為 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

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
  String get dashboardBatchingEnabled => '已啟用批次';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardPollingModeHelpAction => '關於讀取模式';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「已啟用批次」代表 Telltale 可以把多個 PID 請求併成一次交握，以減少來回次數：這條匯流排允許嘗試併批，而且併批沒有被關掉。它仍然是授權而不是量測，因為某一次交握到底有沒有併起來，還要看這輛車確認支援哪些 PID，以及當下排了幾筆。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s 是過去一秒觀測到的速率，不是對延遲、新鮮度或準確度的保證。它會隨轉接器、匯流排、ECU、你選的 PID、每次回覆的大小以及錯誤而變動。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「單筆模式」代表每個 Mode 01 PID 各自讀取。三種情況會用到它：匯流排根本不接受併批請求（所有非 CAN 車輛都是如此）；還沒有任何支援區塊回應過，因為把車輛尚未確認的 PID 併起來問，正是回覆會過短的原因；以及併批的請求沒有回來成一份能拆回各 PID 的答覆（被截斷、轉接器回報緩衝區已滿，或根本沒有回應）。讀數仍會持續更新，這本身不等於連線失敗。';

  @override
  String get dashboardPollingModeHelpTitle => '讀取模式';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get datumBadgeCommunityDecode => '社群解碼';

  @override
  String get datumBadgeDemo => '示範';

  @override
  String get datumBadgeEstimated => '估算';

  @override
  String get datumBadgeExperimental => '實驗';

  @override
  String get datumBadgeFieldVerified => '已驗證';

  @override
  String get datumBadgeInvalid => '無效';

  @override
  String get datumBadgeJustUpdated => '剛更新';

  @override
  String get datumBadgeOutOfReferenceRange => '異常';

  @override
  String get datumBadgePartial => '部分';

  @override
  String get datumBadgeStale => '過期';

  @override
  String get datumBadgeTentativeDecode => '暫定解碼';

  @override
  String get datumBadgeUnverified => '未驗證';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '本車未驗證';

  @override
  String get datumBadgeUserSupplied => '使用者提供';

  @override
  String get datumGapModelYearUnknown => '年式未知';

  @override
  String get datumGapNoCatalogMatch => '型錄無匹配';

  @override
  String get datumGapVinNotRead => 'VIN 未讀到';

  @override
  String get datumNextStepEstimateOnly => '只影響此估算，其他讀值照用';

  @override
  String get datumNextStepGenericObd => '可繼續通用 OBD，或手動選車、補參數';

  @override
  String get datumNextStepOtherReadings => '失敗只影響此項，其他讀值照用';

  @override
  String get datumNextStepRawOnly => '可看 raw / error，不可當成正常數值';

  @override
  String get datumReasonAssumptionsUnconfirmed => '假設尚未確認，仍可估算';

  @override
  String get datumReasonBusError => '匯流排錯誤';

  @override
  String get datumReasonFormulaError => '公式錯誤';

  @override
  String get datumReasonFuelEstimateMissingInputs => '油耗缺少必要輸入';

  @override
  String get datumReasonHeaderNotOnThisBus => '標頭不符本車匯流排';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs => '馬力缺少必要輸入';

  @override
  String get datumReasonMalformedPacket => '壞封包，只可查看原文';

  @override
  String get datumReasonNoAnswer => '無回應，稍後重試';

  @override
  String get datumReasonNoReadingYet => '尚無讀值';

  @override
  String get datumReasonNonFiniteValue => '非有限數值';

  @override
  String get datumReasonOutOfReferenceRangeKept => '超出一般參考範圍，已保留';

  @override
  String get datumReasonPidUnsupported => '此車輛不支援這個 PID';

  @override
  String get datumReasonUnsafeService => '此服務不是唯讀查詢';

  @override
  String get datumReasonUnsafeServiceStopped => '此服務不是唯讀查詢，已停止發送';

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusFormula => '公式';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

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
  String get dtcClearCancelledBeforeSend => '清除已取消，指令還沒送出到車上。可以重新掃描後再試一次。';

  @override
  String get dtcClearConfirmed => '已送出清除指令。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '清除指令可能已經送到車上。不要再送一次 —— 第二次全車清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認還剩下什麼。';

  @override
  String get dtcClearFailureGeneric => '清除沒有完成。請先重新掃描，看目前的故障碼，再決定要不要再試。';

  @override
  String get dtcClearNotAccepted => '清除失敗，沒有控制器接受指令。可以再試一次。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '已有控制器回報清除完成，但其餘控制器無法確認。不要再送一次清除 —— 重複清除會讓已完成的控制器再一次重置排放就緒狀態。請重新掃描確認結果。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '上一次連線送出過清除指令，結果沒有確認。請先重新掃描，確認哪些故障碼還在，再決定要不要清除。';

  @override
  String get dtcClearRescanSettled => '上一次清除的結果無法完全確認，以下是重新掃描後的實際狀況。';

  @override
  String get dtcClearSentUnconfirmed =>
      '清除指令已送出，但回應在傳輸過程中損毀，無法確認車輛是否已清除。請重新掃描確認結果，不要直接再清除一次 —— 如果其實已經清除成功，再清一次會重置排放就緒狀態。';

  @override
  String get dtcClearTimeout => '清除指令送出後沒有回應，無法確認是否已清除。請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearUnexpected => '清除失敗，無法確認車輛是否已清除，請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcScanDisconnectedMidScan => '連線在掃描途中中斷，這次掃描沒有完成。';

  @override
  String get dtcScanInterrupted =>
      '掃描在中途被中斷（可能是切換到其他 App 或連線變更），沒有得到完整結果。請重新掃描。';

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
  String get dtcMonitorBoostPressure => '增壓壓力';

  @override
  String get dtcMonitorCatalyst => '觸媒轉換器';

  @override
  String get dtcMonitorComponents => '綜合元件監控';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 系統';

  @override
  String get dtcMonitorEvaporative => '蒸發排放系統';

  @override
  String get dtcMonitorExhaustSensor => '排氣感知器';

  @override
  String get dtcMonitorFuelSystem => '燃油系統監控';

  @override
  String get dtcMonitorGasolineParticulateFilter => '汽油微粒濾清器（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '觸媒加熱';

  @override
  String get dtcMonitorMisfire => '失火監控';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 觸媒';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 後處理';

  @override
  String get dtcMonitorOxygenSensor => '含氧感知器';

  @override
  String get dtcMonitorOxygenSensorHeater => '含氧感知器加熱';

  @override
  String get dtcMonitorParticulateFilter => '微粒濾清器';

  @override
  String get dtcMonitorSecondaryAir => '二次空氣噴射';

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
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get handshakeNoteAborted => '已中止';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECU 拒絕了支援度查詢（negative response）';

  @override
  String get handshakeNoteEcuSilent => 'ECU 沒有回應';

  @override
  String get handshakeNoteNotAcknowledged => '轉接器未確認此指令';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '回應不是 Mode 01 的正向回覆';

  @override
  String get handshakeNotePidEchoMismatch => '回應的 PID 與查詢不符';

  @override
  String get handshakeNoteSupportMaskTooShort => '支援度回應過短（需要 41 00 加四個位元組）';

  @override
  String get handshakeNoteTimedOut => '逾時';

  @override
  String get handshakeStepAdapterVersion => '讀取轉接器版本';

  @override
  String get handshakeStepAdaptiveTiming => '啟用自適應計時（datasheet 建議值）';

  @override
  String get handshakeStepBatteryVoltage => '讀取電瓶電壓';

  @override
  String get handshakeStepDeviceIdentity => '讀取裝置識別字串';

  @override
  String get handshakeStepEchoOff => '關閉指令回音';

  @override
  String get handshakeStepLinefeedsOff => '關閉換行字元';

  @override
  String get handshakeStepMemoryOff => '關閉記憶體寫入';

  @override
  String get handshakeStepNoReason => '無回應';

  @override
  String get handshakeStepProtocolAuto => '自動偵測匯流排協定';

  @override
  String get handshakeStepProtocolDescription => '讀取協定描述';

  @override
  String get handshakeStepProtocolNumber => '讀取協定編號';

  @override
  String get handshakeStepReset => '軟體重置轉接器';

  @override
  String get handshakeStepResponseTimeout => '設定回應逾時 ~408ms';

  @override
  String get handshakeStepSpacesOff => '關閉空白字元，減少 33% 傳輸量';

  @override
  String get handshakeStepSupportProbe => '查詢 ECU 支援的 PID（確認車輛已回應）';

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
  String get performanceArm => '準備計時';

  @override
  String get performanceDisclaimer =>
      '成績以 OBD 車速訊號為準。多數車輛的車速表本身有 1–3 km/h 的正偏差，且訊號更新率約每秒 10–20 次，因此結果僅供參考，不等同於專業測試設備。';

  @override
  String get performanceHeadline => '加速測試';

  @override
  String get performanceNoSpeedSignal => '目前沒有有效的車速訊號（PID 010D）。加速測試需要它才能計時。';

  @override
  String get performanceNotConnectedBody => '加速測試需要即時車速資料，請先連線或啟動模擬器。';

  @override
  String get performanceNotConnectedTitle => '尚未連線';

  @override
  String get performancePeakSpeed => '最高車速';

  @override
  String get performanceReset => '重置';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '車速';

  @override
  String get performanceSpeedTraceHeading => '速度軌跡';

  @override
  String get performanceSplitsHeading => '分段成績';

  @override
  String get performanceStateAborted => '車速訊號中斷 — 這次計時未完成，以下為中斷前的紀錄';

  @override
  String get performanceStateAwaitingSpeedSignal => '等待車速訊號';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '請先完全停車 — 目前 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '完成 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => '選擇目標車速後開始';

  @override
  String get performanceStateRunning => '計時中';

  @override
  String get performanceStateStaged => '已就緒 — 起步即開始計時';

  @override
  String get performanceSubhead => '由靜止起步計時至目標車速';

  @override
  String get performanceTargetSpeedHeading => '目標車速';

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
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
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
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

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
  String get powertrainInstallCatalogShaMissing =>
      '無法安裝：這份目錄快照沒有已驗證的 SHA-256，因此其中任何內容都不能信任。';

  @override
  String get powertrainInstallPersistFailed =>
      '無法安裝：已安裝設定檔清單無法寫入。請再試一次；PID 管理沒有新增任何項目。';

  @override
  String get powertrainInstallProfileNotInCatalog => '無法安裝：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '無法安裝：這個設定檔目前不能變成實際的 PID。';

  @override
  String get powertrainInstallYearOutOfRange => '無法安裝：該年式不在這個設定檔記載的年份範圍內。';

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
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '未授權：這個指令不屬於這份已驗證設定檔本身的指令。';

  @override
  String get powertrainRefusedLabClosed => '在這次讀取取得授權之前，大電池證據實驗室已被關閉。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。';

  @override
  String get powertrainRefusedProfileNotInCatalog => '未授權：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainRefusedProfileNotProbeable => '未授權：這個設定檔不是可以單次實驗讀取的設定檔。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '這次單次讀取沒有開始：目前沒有連線，或 App 不在前景。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '這次單次讀取沒有開始：目前沒有持有單次授權。授權不存在、已過期、冷卻中或已被隔離。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '單次讀取進行中，連線或前景狀態改變了，因此它的結果被丟棄而沒有顯示。沒有任何失敗，也沒有保留任何結果。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '本次連線已隔離：同一個指令已經嘗試 $attemptCap 次。請重新連線後再試。';
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
  String get semanticsFieldSeparator => '，';

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
  String get telemetryCancel => '取消';

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryDismissNotice => '關閉提示';

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
  String get telemetryExport => '匯出';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

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
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryPause => '暫停';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String get telemetryPlay => '播放';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
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
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String get telemetryReload => '重新載入';

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

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
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

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

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

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

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get wearBack => '返回';

  @override
  String get wearBatteryVoltageLabel => '電瓶';

  @override
  String get wearBleAdapters => 'BLE 轉接器';

  @override
  String get wearCancel => '取消';

  @override
  String get wearConfirmVehicle => '確認車輛';

  @override
  String get wearConfirmVehicleAccept => '就是這台車';

  @override
  String get wearConfirmVehicleBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String wearConnectFailed(String adapter) {
    return '連線失敗：$adapter';
  }

  @override
  String get wearConnecting => '連線中…';

  @override
  String get wearDemoSimulator => 'Demo 模擬器';

  @override
  String get wearDisconnect => '中斷';

  @override
  String get wearDisconnectQuestion => '中斷連線？';

  @override
  String get wearNoDevicesFound => '沒有找到裝置';

  @override
  String get wearPermissionBluetooth => '藍牙';

  @override
  String get wearPermissionLocation => '位置';

  @override
  String get wearScanAgain => '重新掃描';

  @override
  String get wearScanFailed => '掃描失敗，請再試一次';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '需要$permission權限才能掃描';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission權限已被永久拒絕，請到系統設定開啟後再試';
  }

  @override
  String get wearScanning => '掃描中…';

  @override
  String get telemetryRecorderNotRecording => '未錄製';

  @override
  String get dtcKindStored => '已儲存';

  @override
  String get dtcKindPending => '待確認';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '已確認的故障，儀表板故障燈通常亮起';

  @override
  String get dtcKindPendingExplanation => '偵測到一次，尚未達到確認門檻';

  @override
  String get dtcKindPermanentExplanation => '無法用診斷儀清除，需修復後由 ECU 自行確認';

  @override
  String get dtcSystemPowertrain => '動力系統';

  @override
  String get dtcSystemChassis => '底盤';

  @override
  String get dtcSystemBody => '車身';

  @override
  String get dtcSystemNetwork => '網路';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃油與空氣計量、輔助排放控制';

  @override
  String get dtcSubsystemFuelAirMetering => '燃油與空氣計量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit => '燃油與空氣計量（噴油嘴迴路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '點火系統或失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '輔助排放控制';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '車速控制與怠速系統';

  @override
  String get dtcSubsystemComputerOutputCircuit => '電腦輸出迴路';

  @override
  String get dtcSubsystemTransmission => '變速箱';

  @override
  String get dtcSubsystemControlModuleSignals => '控制模組輸入／輸出訊號';

  @override
  String get dtcDescriptionB0001 => '駕駛座安全氣囊裝置故障';

  @override
  String get dtcDescriptionP0011 => '「A」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0014 => '「B」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0016 => '曲軸與凸輪軸位置訊號不同步（Bank 1 感知器 A）';

  @override
  String get dtcDescriptionP0087 => '燃油軌／系統壓力過低';

  @override
  String get dtcDescriptionP0088 => '燃油軌／系統壓力過高';

  @override
  String get dtcDescriptionP0100 => '空氣流量感知器 (MAF) 電路故障';

  @override
  String get dtcDescriptionP0101 => '空氣流量感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0102 => '空氣流量感知器電路輸入過低';

  @override
  String get dtcDescriptionP0103 => '空氣流量感知器電路輸入過高';

  @override
  String get dtcDescriptionP0105 => '進氣歧管絕對壓力／大氣壓力感知器電路故障';

  @override
  String get dtcDescriptionP0106 => '進氣歧管絕對壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0107 => '進氣歧管絕對壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0108 => '進氣歧管絕對壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0110 => '進氣溫度感知器電路故障';

  @override
  String get dtcDescriptionP0111 => '進氣溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0112 => '進氣溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0113 => '進氣溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0115 => '冷卻液溫度感知器電路故障';

  @override
  String get dtcDescriptionP0116 => '冷卻液溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0117 => '冷卻液溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0118 => '冷卻液溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0120 => '節氣門位置感知器電路故障';

  @override
  String get dtcDescriptionP0121 => '節氣門位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0122 => '節氣門位置感知器電路輸入過低';

  @override
  String get dtcDescriptionP0123 => '節氣門位置感知器電路輸入過高';

  @override
  String get dtcDescriptionP0125 => '冷卻液溫度不足以進入閉迴路燃油控制';

  @override
  String get dtcDescriptionP0128 => '冷卻液溫度低於節溫器調節溫度';

  @override
  String get dtcDescriptionP0130 => '含氧感知器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 => '含氧感知器電路電壓過低 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 => '含氧感知器電路電壓過高 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 => '含氧感知器反應過慢 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 => '含氧感知器無活性訊號 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 => '含氧感知器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 => '含氧感知器電路電壓過低 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 => '含氧感知器電路電壓過高 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 => '含氧感知器無活性訊號 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 => '含氧感知器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 => '含氧感知器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => '燃油修正異常 (Bank 1)';

  @override
  String get dtcDescriptionP0171 => '混合比過稀 (Bank 1)';

  @override
  String get dtcDescriptionP0172 => '混合比過濃 (Bank 1)';

  @override
  String get dtcDescriptionP0173 => '燃油修正異常 (Bank 2)';

  @override
  String get dtcDescriptionP0174 => '混合比過稀 (Bank 2)';

  @override
  String get dtcDescriptionP0175 => '混合比過濃 (Bank 2)';

  @override
  String get dtcDescriptionP0190 => '燃油軌壓力感知器電路故障';

  @override
  String get dtcDescriptionP0201 => '噴油嘴電路故障／開路 — 第 1 缸';

  @override
  String get dtcDescriptionP0202 => '噴油嘴電路故障／開路 — 第 2 缸';

  @override
  String get dtcDescriptionP0203 => '噴油嘴電路故障／開路 — 第 3 缸';

  @override
  String get dtcDescriptionP0204 => '噴油嘴電路故障／開路 — 第 4 缸';

  @override
  String get dtcDescriptionP0217 => '引擎過熱';

  @override
  String get dtcDescriptionP0221 => '節氣門／油門踏板位置感知器 B 範圍或效能異常';

  @override
  String get dtcDescriptionP0222 => '節氣門／油門踏板位置感知器 B 電路輸入過低';

  @override
  String get dtcDescriptionP0223 => '節氣門／油門踏板位置感知器 B 電路輸入過高';

  @override
  String get dtcDescriptionP0234 => '渦輪／機械增壓過壓';

  @override
  String get dtcDescriptionP0299 => '渦輪／機械增壓「A」增壓不足';

  @override
  String get dtcDescriptionP0300 => '偵測到隨機/多缸失火';

  @override
  String get dtcDescriptionP0301 => '第 1 缸失火';

  @override
  String get dtcDescriptionP0302 => '第 2 缸失火';

  @override
  String get dtcDescriptionP0303 => '第 3 缸失火';

  @override
  String get dtcDescriptionP0304 => '第 4 缸失火';

  @override
  String get dtcDescriptionP0305 => '第 5 缸失火';

  @override
  String get dtcDescriptionP0306 => '第 6 缸失火';

  @override
  String get dtcDescriptionP0307 => '第 7 缸失火';

  @override
  String get dtcDescriptionP0308 => '第 8 缸失火';

  @override
  String get dtcDescriptionP0316 => '起動後隨即偵測到失火';

  @override
  String get dtcDescriptionP0325 => '爆震感知器電路故障 (Bank 1)';

  @override
  String get dtcDescriptionP0326 => '爆震感知器範圍/效能異常 (Bank 1)';

  @override
  String get dtcDescriptionP0327 => '爆震感知器電路輸入過低 (Bank 1)';

  @override
  String get dtcDescriptionP0328 => '爆震感知器電路輸入過高 (Bank 1)';

  @override
  String get dtcDescriptionP0330 => '爆震感知器電路故障 (Bank 2)';

  @override
  String get dtcDescriptionP0335 => '曲軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0336 => '曲軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0340 => '凸輪軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0341 => '凸輪軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0351 => '點火線圈 A 一次/二次電路故障';

  @override
  String get dtcDescriptionP0352 => '點火線圈 B 一次/二次電路故障';

  @override
  String get dtcDescriptionP0353 => '點火線圈 C 一次/二次電路故障';

  @override
  String get dtcDescriptionP0354 => '點火線圈 D 一次/二次電路故障';

  @override
  String get dtcDescriptionP0355 => '點火線圈 E 一次/二次電路故障';

  @override
  String get dtcDescriptionP0356 => '點火線圈 F 一次/二次電路故障';

  @override
  String get dtcDescriptionP0400 => '廢氣再循環 (EGR) 流量故障';

  @override
  String get dtcDescriptionP0401 => '廢氣再循環 (EGR) 流量不足';

  @override
  String get dtcDescriptionP0402 => '廢氣再循環 (EGR) 流量過大';

  @override
  String get dtcDescriptionP0403 => '廢氣再循環 (EGR) 控制電路故障';

  @override
  String get dtcDescriptionP0404 => '廢氣再循環 (EGR) 控制電路範圍/效能異常';

  @override
  String get dtcDescriptionP0410 => '二次空氣噴射系統故障';

  @override
  String get dtcDescriptionP0411 => '二次空氣噴射系統流量不正確';

  @override
  String get dtcDescriptionP0412 => '二次空氣噴射切換閥 A 電路故障';

  @override
  String get dtcDescriptionP0420 => '觸媒轉換器效率低於門檻 (Bank 1)';

  @override
  String get dtcDescriptionP0430 => '觸媒轉換器效率低於門檻 (Bank 2)';

  @override
  String get dtcDescriptionP0440 => '蒸發排放控制系統故障';

  @override
  String get dtcDescriptionP0441 => '蒸發排放系統清除流量不正確';

  @override
  String get dtcDescriptionP0442 => '蒸發排放系統偵測到小漏氣';

  @override
  String get dtcDescriptionP0443 => '蒸發排放清除閥控制電路故障';

  @override
  String get dtcDescriptionP0446 => '蒸發排放通風控制電路故障';

  @override
  String get dtcDescriptionP0447 => '蒸發排放通風控制電路開路';

  @override
  String get dtcDescriptionP0449 => '蒸發排放通風閥/電磁閥電路故障';

  @override
  String get dtcDescriptionP0451 => '蒸發排放壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0452 => '蒸發排放壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0453 => '蒸發排放壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0455 => '蒸發排放系統偵測到大漏氣';

  @override
  String get dtcDescriptionP0456 => '蒸發排放系統偵測到極小漏氣';

  @override
  String get dtcDescriptionP0480 => '冷卻風扇 1 控制電路故障';

  @override
  String get dtcDescriptionP0500 => '車速感知器故障';

  @override
  String get dtcDescriptionP0505 => '怠速控制系統故障';

  @override
  String get dtcDescriptionP0506 => '怠速轉速低於預期';

  @override
  String get dtcDescriptionP0507 => '怠速轉速高於預期';

  @override
  String get dtcDescriptionP0508 => '怠速控制電路輸入過低';

  @override
  String get dtcDescriptionP0509 => '怠速控制電路輸入過高';

  @override
  String get dtcDescriptionP0560 => '系統電壓故障';

  @override
  String get dtcDescriptionP0562 => '系統電壓過低';

  @override
  String get dtcDescriptionP0563 => '系統電壓過高';

  @override
  String get dtcDescriptionP0603 => '控制模組內部記憶體（KAM）錯誤';

  @override
  String get dtcDescriptionP0605 => '控制模組內部唯讀記憶體（ROM）錯誤';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 處理器故障';

  @override
  String get dtcDescriptionP0700 => '變速箱控制模組要求點亮故障燈 —— 故障碼在變速箱模組裡，請另外讀取';

  @override
  String get dtcDescriptionP0701 => '變速箱控制系統範圍/效能異常';

  @override
  String get dtcDescriptionP0702 => '變速箱控制系統電氣故障';

  @override
  String get dtcDescriptionP0705 => '排檔位置感知器電路故障';

  @override
  String get dtcDescriptionP0715 => '輸入軸／渦輪轉速感知器電路故障';

  @override
  String get dtcDescriptionP0720 => '輸出軸轉速感知器電路故障';

  @override
  String get dtcDescriptionP0730 => '檔位比不正確';

  @override
  String get dtcDescriptionP0740 => '扭力轉換器離合器電路故障';

  @override
  String get dtcDescriptionP0741 => '扭力轉換器離合器卡在未鎖定狀態';

  @override
  String get dtcDescriptionP0750 => '換檔電磁閥 A 故障';

  @override
  String get dtcDescriptionP0755 => '換檔電磁閥 B 故障';

  @override
  String get dtcDescriptionP2135 => '節氣門位置感知器 A/B 電壓不一致';

  @override
  String get dtcDescriptionU0100 => '與 ECM/PCM 失去通訊';

  @override
  String get dtcDescriptionU0101 => '與變速箱控制模組失去通訊';

  @override
  String get dtcDescriptionU0121 => '與 ABS 控制模組失去通訊';

  @override
  String get dtcDescriptionU0140 => '與車身控制模組失去通訊';

  @override
  String get dtcDescriptionU0155 => '與儀表板控制模組失去通訊';

  @override
  String get gaugeSkinCluster => '儀表艙';

  @override
  String get gaugeSkinClusterDescription => '車廠儀表板的樣子。指針、270 度刻度盤、凹陷的面盤。';

  @override
  String get gaugeSkinMinimal => '極簡';

  @override
  String get gaugeSkinMinimalDescription => '半圓弧、沒有指針、沒有刻度。要看的是數字，不是動作。';

  @override
  String get gaugeSkinTrack => '賽道';

  @override
  String get gaugeSkinTrackDescription => '分段燈條、無平滑動畫。數值到哪就是哪，不做過渡。';

  @override
  String get gaugeSkinClassic => '經典';

  @override
  String get gaugeSkinClassicDescription => '印刷式面盤、整圈數字、指針像機械錶一樣慢慢定位。';

  @override
  String get gaugeSkinNight => '夜視';

  @override
  String get gaugeSkinNightDescription => '夜間駕駛用。低亮度、淺弧、不做動畫，盡量不搶走注意力。';

  @override
  String get derivedAirflowSourceMaf => 'MAF 感測器';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density 推算';

  @override
  String get derivedAirflowSourceUnavailable => '進氣量無法取得';

  @override
  String get derivedFuelSourceStoichiometric => '化學計量比推算';

  @override
  String get derivedFuelSourceUnavailable => '油耗無法取得';

  @override
  String get telemetrySourceDemo => '內建模擬';

  @override
  String get telemetrySourceRig => '測試馬具';

  @override
  String get telemetrySourceFieldApp => '一般 field App 連線';

  @override
  String get fuelTypeGasoline => '汽油';

  @override
  String get fuelTypeDiesel => '柴油';

  @override
  String get fuelTypeLpg => '液化石油氣 (LPG)';

  @override
  String get fuelTypeEthanolE85 => 'E85 酒精汽油';

  @override
  String get drivetrainFwd => '前輪驅動';

  @override
  String get drivetrainRwd => '後輪驅動';

  @override
  String get drivetrainAwd => '四輪驅動';

  @override
  String get assumptionFieldMass => '車重';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '迎風面積';

  @override
  String get assumptionFieldRollingResistance => '滾動阻力';

  @override
  String get assumptionFieldDrivetrainEfficiency => '傳動效率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排氣量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '通用預設';

  @override
  String get vehicleFieldOriginUserEntered => '手動輸入';

  @override
  String get vehicleFieldOriginOfficialRegistry => '官方型錄';

  @override
  String get vehicleFieldOriginManufacturerPublication => '原廠資料';

  @override
  String get vehicleFieldOriginScientificModel => '模型係數';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value（$origin）';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '；';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF 可為 PID 0110 或 speed-density（RPM×MAP×排氣量×VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '估算使用記錄當下的車輛設定';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '回報的韌體版本 v$version 官方從未發行';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return '自稱 v$version，卻不認得 v1.1 就有的 ATPPS 指令';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '可程式參數摘要（ATPPS）從 ELM327 v1.1 起就存在，連 OBDLink 這類高階轉接器也支援。自稱的版本與實際實作的指令對不起來。';

  @override
  String get adapterConcernNoIdentitySummary => '不回應 AT@1（第一版就有的裝置識別指令）';

  @override
  String get adapterConcernNoIdentityDetail =>
      '這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。';

  @override
  String get telemetryReplaySampled => '預覽已抽樣；匯出保留完整已記錄事件';

  @override
  String get telemetryExportDisclosure =>
      '匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。';

  @override
  String get connectTransportCancelled => '連線嘗試在完成前被停止了。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '手機沒有連上任何 Wi-Fi 網路，沒有通往轉接器的路由。請先連上轉接器的 Wi-Fi 熱點再試一次。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '手機同時連著多個 Wi-Fi，無法判斷哪一個通往轉接器，所以沒有選任何一個。請先關閉不是轉接器的那些連線再試一次。';

  @override
  String get connectTransportWifiRouteRefused =>
      '系統拒絕讓這個連線走 Wi-Fi。手機是連著 Wi-Fi 的，只是不被允許用於這個連線。';

  @override
  String get connectTransportWifiRouteTimeout =>
      '系統沒有回應「讓這個連線走 Wi-Fi」的請求。請等幾秒再試一次。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '這個連線無法走 Wi-Fi，而系統沒有說明原因。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectTransportWifiHostUnreachable =>
      '那個位址沒有回應。請確認手機已連上轉接器的 Wi-Fi 熱點 —— 若系統問過「無法連上網際網路，是否繼續使用」，要選繼續使用。關閉行動數據也可能有幫助。';

  @override
  String get connectTransportWifiConnectTimeout => '那個位址在時限內沒有任何回應。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '連線本身成功了，但手機的網路路由無法恢復，所以連線被中斷，而不是把它改過的狀態留著。請重新開啟 App 再試一次。';

  @override
  String get connectTransportBleLinkFailed => '無法連線到轉接器。請確認它已通電且在範圍內。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '裝置連上了，但在它身上沒有找到序列埠，可能不是 ELM327 轉接器。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '無法連線到轉接器。請先在系統藍牙設定完成配對，並確認它已插上 OBD 埠且電門已開啟。';

  @override
  String get connectTransportClassicConnectTimeout =>
      '連線到轉接器逾時。它可能仍在回應中 —— 請等幾秒再試，不要立刻重試。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '無法開啟序列埠。請確認系統已為這個轉接器建立序列埠（Windows COMx / Linux /dev/rfcomm*），且電門已開啟。';

  @override
  String get connectTransportSerialDroppedOnOpen => '序列埠開啟後立刻又關閉了。';

  @override
  String get settingsManualCommandNotConnected => '目前沒有連線，這條指令沒有送出。';

  @override
  String get settingsManualCommandLinkDropped =>
      '這條指令還在等待回應時，與轉接器的連線中斷了，所以沒有任何回應。轉接器是否收到這條指令並不確定。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '這條指令還在等待回應時，App 主動關閉了連線，所以沒有任何回應。轉接器與車輛都沒有問題。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '轉接器的回應已經和送出的指令對不上，而它也沒有回應用來重新對齊的檢查，所以連線已中斷。請重新連線後再試一次。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '轉接器安靜得夠久，連線已被中斷。它可能仍有電；能確定的只有這段沉默。';

  @override
  String get settingsManualCommandWriteFailed =>
      '這條指令無法交給轉接器的連線。有多少內容送達轉接器並不確定。';

  @override
  String get settingsManualCommandOperationRetired => '這個工作階段已經結束或退到背景，指令沒有送出。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '這條要求在這輛車使用的匯流排上無法定址，因此沒有送出。再試一次也不會改變。';

  @override
  String get manualCommandRefusedEmpty => '沒有輸入指令。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '指令裡有換行或控制字元，這樣會一次送出多個指令。轉接器以換行分隔指令，所以第二個指令不會經過這裡的任何檢查 —— 包括禁止清除故障碼的那一項。請一次只輸入一個指令。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '手動指令只接受查詢，不接受會改變轉接器設定的指令。「$command」會改動轉接器狀態，而 App 對轉接器的認知不會跟著更新 —— 接下來的讀數可能來自另一個控制器，而畫面上看不出來。\n可用的查詢：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '清除故障碼請用故障碼畫面的「清除」按鈕。從這裡送出會跳過確認、覆蓋率檢查與回應驗證，而且只會清到目前選中的那一個控制器。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '指令「$command」含有 OBD 指令不會出現的字元。這裡只接受十六進位的服務碼與參數（例如 0100、03、2211A6），或 AT 開頭的轉接器查詢。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '不認得的指令「$command」。這裡只接受唯讀查詢（Mode $allowed）與轉接器查詢指令。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '轉接器拒絕將這條要求對準到控制器 $header，因此它沒有送出。如果留在轉接器實際持有的位址上，回應會來自沒有人詢問的控制器。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '轉接器拒絕切換到 $address 這個位址，而向全車提出的問題必須從它送出。沒有它，回應就無法對應到送出它們的控制器，因此這個要求沒有送出。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '這輛車使用的舊式匯流排沒有能觸及每個控制器的標準位址，而轉接器目前指定在控制器 $installed。掃描只會涵蓋那一個控制器，卻會被當成全車結果呈現，因此沒有送出。請重新連線後再掃描一次。';
  }

  @override
  String get pidFormulaEmpty => '公式是空的。';

  @override
  String get pidFormulaEmptySubExpression => '公式有一段是空的 —— 運算子後面沒有東西，或括號裡沒有內容。';

  @override
  String get pidFormulaUnbalancedParentheses => '括號沒有配對：每一個 ( 都需要一個對應的 )。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」不是數值、運算子，也不是這個編輯器認得的名稱。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS() 與 LOG10() 巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaParenthesisNestingTooDeep => '括號巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaDivisionByZero => '公式除以零。';

  @override
  String get pidFormulaModuloByZero => '公式對零取餘數。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String get pidFormulaResultNotFinite => '這串運算沒有得出可用的數值，因此沒有讀數可顯示。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '公式參照位元組 $letter，但回應只有 $count 個位元組。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '這裡無法使用 BARO，因為無法判斷指的是哪一個控制器的大氣壓力。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。請移除其中一個測量大氣壓力的錶。';

  @override
  String get pidFormulaBaroNotYetMeasured => '尚未取得大氣壓力量測值，無法計算。';

  @override
  String get pidFormulaBaroMeasurementStale => '大氣壓力量測值已過期，無法計算。';

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '這裡無法解析 $reference，因為無法判斷那個 PID 屬於哪一個控制器。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '有兩個定義同時解讀 $key，數值可能是其中任何一個，因此無法採用。請讓其中一個改用不同的模式+PID。注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，把面板上的錶移掉不會停止讀取它們。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '尚未取得相依 PID $key 的有效數值。';
  }

  @override
  String get pidFormulaUnidentified => '這個公式無法求值，而編輯器沒有更具體的原因可顯示。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '服務 $service 不是唯讀查詢，不能週期性發送到車上。只允許 $services（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '凍結幀查詢需要 PID 與幀編號兩個位元組，例如 020500（PID 05、第 0 幀）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier 需要兩個位元組的識別碼，例如 221101。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '服務 $service 的查詢需要 $bytes 個位元組的識別碼。';
  }

  @override
  String get pidRejectionNameRequired => '請輸入名稱。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」不是有效的標頭（11-bit CAN 為 3 碼、舊協定為 6 碼、29-bit CAN 為 8 碼）。';
  }

  @override
  String get pidRejectionBoundsRequired => '請填寫量程的上下限。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '量程下限「$text」不是有效的數值。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '量程上限「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionMinNotFinite => '量程下限必須是有限的數值。';

  @override
  String get pidRejectionMaxNotFinite => '量程上限必須是有限的數值。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '紅線起點「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionRedlineNotFinite => '紅線起點必須是有限的數值。';

  @override
  String get pidRejectionMaxNotAboveMin => '量程上限必須大於下限。';

  @override
  String pidImportMalformedCsv(String detail) {
    return '這個檔案無法以 CSV 讀取：$detail';
  }

  @override
  String get pidImportNoRows => '檔案沒有任何資料列。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '標題列有重複的欄位名稱：$columns。無法判斷該用哪一欄，請先修正檔案。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '標題列缺少必要欄位：$columns。$required 都是必要的。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '第 $line 行：欄位不足，至少需要名稱、簡稱、PID、公式。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '第 $line 行：「$text」不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '第 $line 行：公式為空。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '第 $line 行：量程留空，已套用預設 $min–$max。請確認這個刻度適合這個感測器。';
  }

  @override
  String get pidImportNothingImportable => '檔案裡有資料列，但沒有任何一列是 PID 定義。';

  @override
  String get dtcCategoryNoAnswer => '這個類別沒有回應。請重新掃描。';

  @override
  String get dtcCategoryError => '這個類別讀取失敗。完整錯誤保留在紀錄裡。';

  @override
  String get dtcCategoryDisconnected => '讀取這個類別時連線中斷。';

  @override
  String get dtcCategoryPending => '控制器已收到請求、仍在處理中。請稍候再掃描一次——這不是拒絕。';

  @override
  String get dtcCategoryUnattributed =>
      '有讀到故障碼，但回應標頭是關閉的，因此不知道是哪些控制器回答。這是部分結果，不是車輛正常。';

  @override
  String get connectPairedListFailed => '無法讀取已配對的藍牙清單。請確認藍牙已開啟後再試。';

  @override
  String get connectBleScanUnavailable => '藍牙目前無法使用。請稍後再搜尋。';

  @override
  String get connectBleScanBluez =>
      '找不到可用的 BlueZ／D-Bus 藍牙服務。請確認系統已安裝並啟動 bluetooth 服務後再試。';

  @override
  String get connectBleScanUnclassified => 'BLE 搜尋失敗。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，然後再試一次。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 目前忙碌中。請稍候再試一次。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。請稍候再試一次。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應清除指令（$controllers）。已回應的控制器已清除，其餘可能仍有故障碼。請重新掃描，不要再送一次清除。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，再重新掃描確認哪些故障碼還在。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 目前忙碌中。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String get sharePolicyDenied => '目前的連線或行車狀態不允許匯出。';

  @override
  String get shareSafetyChanged => '準備匯出期間狀態已改變，未開啟分享。';

  @override
  String get shareSizeLimit => '匯出檔超過 32 MiB 上限。';

  @override
  String get shareStagingBusy => '先前的分享檔仍在保留期內，請稍後再試。';

  @override
  String get shareCleanupRequired => '分享暫存區需要在重新啟動後檢查。';

  @override
  String get shareSpaceUnknown => '無法確認分享檔所需的可用空間。';

  @override
  String get shareNoSpace => '儲存空間不足，無法準備分享檔。';

  @override
  String get shareHandoffFailed => '檔案已準備完成，但系統分享介面無法開啟。';

  @override
  String get shareStorageFailure => '準備或記錄分享結果時發生儲存錯誤。';

  @override
  String get transcriptExportUnidentified => '匯出失敗。';
}
