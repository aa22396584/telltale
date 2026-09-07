# Translation glossary

Every pairing below is one this project **already made** somewhere in the tree, not a
preference invented for this file. The Evidence column names where, so a reviewer can
check a translation against the repository instead of against taste.

`test/l10n/glossary_evidence_test.dart` reads this file and fails when a cited file no
longer contains the Chinese term. That is deliberate: a glossary nobody can verify decays
into folklore, and this one is checked on every run.

**Status.** `evidenced` means both languages appear together at the cited place — the same
file, or the two language versions of one document. On a `T3` row the "English" is usually a
Dart identifier rather than shipped English copy: `無回應，稍後重試 / no answer` is evidenced
by `PidFault.noAnswer`, and the app has never rendered the string "no answer". That is a
convention this project already uses, not a loophole, but it is worth knowing which kind of
artefact you are looking at.

`inferred` means both languages exist in the tree but were never written side by side, so
the pairing is this glossary's reasoning rather than the project's own.

`proposed` means **the English has not been confirmed by a maintainer**. It is a statement
about review, not about the repository. An earlier draft of this file claimed the status was
"written by hand, never computed", which was both unfalsifiable and untrue in effect: the
`proposed` rows were exactly the rows the test could not evidence. Two rows make the point —
`化學計量比推算 / stoichiometric estimate` counts as evidenced and `Speed-Density 推算 /
Speed-Density estimate` does not, purely because one enum is spelled `stoichiometricEstimate`
and the other `speedDensity`. Same Chinese head word, same English word, opposite status. So
`proposed` may disagree with what the test can prove, in either direction, and a maintainer
moving a row to `evidenced` without changing the code is a legitimate act. The status is written by
hand, never computed — a generator that marked rows using the same rule the test checks
would only be agreeing with itself.

**How to read Evidence.** `T1` means the same sentence appears in both `README.md` and
`README.zh-TW.md`. `T2` means the same table row. `T3` means a Dart identifier sitting
next to its Chinese label in `lib/`. Anything else names the file directly.

**Traditional Chinese only.** Simplified Chinese is not shipped
(`lib/l10n/locale_resolution.dart`), so no entry here has a zh-Hans form and none should
be added.


See also [do-not-translate.md](do-not-translate.md) and [hedge-register.md](hedge-register.md).

## OBD2 and protocol

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| Demo ECU | Demo ECU | README.md:55 ↔ README.zh-TW.md:49 (T1 — unchanged in zh) | evidenced | Kept English on both sides. But see 內建模擬器 and 'Demo 模擬器' (docs/field-guide.zh-TW.md:27) — three renderings of one feature. |
| Flow Control | flow control | docs/protocol-deviations.zh-TW.md:83 '停住等一個永遠不會送出的 Flow Control 幀' (T1 — kept English inside zh prose) | evidenced | DO NOT translate to 流量控制. The zh doc deliberately keeps the ELM327 datasheet term; 幀 is appended as the classifier. |
| MAF 感測器 | MAF sensor | lib/l10n/app_en.arb:2759 ↔ lib/l10n/app_zh_Hant.arb:910 (T1 same ARB key) | evidenced | INCONSISTENCY: this uses 感測器 while the readiness monitor label uses 感知器 for oxygen sensor (lib/l10n/app_zh_Hant.arb:177 '含氧感知器', dtcMonitorOxygenSensor). Both ship. Label moved out of AirflowSource.label into the ARBs so lib/obd stays Flutter-free; the enum still carries the identity. |
| OBD2 故障診斷 | OBD2 fault diagnosis | README.md:11 ↔ README.zh-TW.md:11 (T1 same sentence) | evidenced |  |
| Speed-Density 推算 | Speed-density estimate | lib/l10n/app_en.arb:2763 ↔ lib/l10n/app_zh_Hant.arb:911 (T1 same ARB key) | evidenced | Was proposed while the label lived in physics_engine.dart, which had no English at all. The English now ships and says estimate — the load-bearing half, because this figure is computed from RPM, MAP and IAT rather than read off a sensor. |
| transports | transports | README.md:174 ↔ README.zh-TW.md:148 (T1 — unchanged in zh) | evidenced | INCONSISTENCY: kept English in the repo-layout table and at README.md:124, whose zh counterpart README.zh-TW.md:103-104 renders it '轉接器列表'; the user-facing concept is '連線方式' (app_zh_Hant.arb:9, store/README.md:26). Engineering doc = transports; UI = 連線方式. |
| 二次空氣噴射 | secondary air | lib/l10n/app_en.arb:2701 ↔ lib/l10n/app_zh_Hant.arb:180 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.secondaryAir into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 內建模擬器 | built-in simulator | lib/l10n/app_en.arb:83 ↔ lib/l10n/app_zh_Hant.arb:42 (T1 same ARB key) | evidenced | The in-app label is 'Demo 模擬器' (docs/field-guide.zh-TW.md:27); the ARB says 內建模擬器; README says Demo ECU. Pick per surface, do not unify silently. |
| 公式錯誤 | formula error | lib/l10n/app_en.arb:799 ↔ lib/l10n/app_zh_Hant.arb:121 (T1 same ARB key) | evidenced |  |
| 凍結幀 | freeze frame | README.md:56 'freeze frames' ↔ README.zh-TW.md:50 '凍結幀' (T1); docs/field-guide.zh-TW.md:213 heading | evidenced |  |
| 動力系統 | powertrain | lib/l10n/app_en.arb:1253 ↔ lib/l10n/app_zh_Hant.arb:750 (T1 same ARB key) | evidenced | Distinct from '大電池' used for 'powertrain battery' at README.md:58 ↔ README.zh-TW.md:52. Same English word, two zh renderings by domain. |
| 化學計量比推算 | Stoichiometric estimate | lib/l10n/app_en.arb:2771 ↔ lib/l10n/app_zh_Hant.arb:913 (T1 same ARB key) | evidenced |  |
| 匯流排 | bus | lib/obd/elm327_client.dart:82 Elm327ErrorCode.canError ↔ 'CAN 匯流排錯誤' (T3); :86 busBusy ↔ '匯流排忙碌'; :87 busError ↔ '匯流排錯誤' | evidenced |  |
| 協定 | protocol | README.md:174 'ELM327 protocol' ↔ README.zh-TW.md:148 'ELM327 協定' (T1); docs/protocol-deviations.zh-TW.md:152 '各種匯流排協定' | evidenced |  |
| 即時 PID 儀表 | Live PID dashboards | README.md:56 ↔ README.zh-TW.md:50 (T1) | evidenced | INCONSISTENCY: 'dashboard' is '儀表板' at README.md:21/README.zh-TW.md:20 and store/README.md:27, but 'PID dashboards' is 儀表 here and 'BMS gauges' is also '儀表' (README.md:64 ↔ README.zh-TW.md:57). 儀表 does double duty for gauge and dashboard-of-gauges. |
| 含氧感知器 | oxygen sensor | lib/l10n/app_en.arb:614 ↔ lib/l10n/app_zh_Hant.arb:177 (T1 same ARB key `dtcMonitorOxygenSensor`) | evidenced | 感知器 (TW) not 傳感器 (CN). Label moved out of ReadinessMonitor.oxygenSensor into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 增壓壓力 | boost pressure | lib/l10n/app_en.arb:566 ↔ lib/l10n/app_zh_Hant.arb:165 (T1 same ARB key `dtcMonitorBoostPressure`) | evidenced | Label moved out of ReadinessMonitor.boostPressure into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 多幀 | multi-frame | docs/verification/review-log.md:41 '### C2 · 多幀長度行被當成資料' + :43 naming `_parse` ↔ lib/obd/elm327_client.dart:4 'multi-frame reassembly' and :2433 "a multi-frame envelope's total length" (T3, same named function) | inferred | zh at docs/verification/review-log.md:41; en at lib/obd/elm327_client.dart:4. Both are this project's words, never written side by side. |
| 失火監控 | misfire | lib/l10n/app_en.arb:2591 ↔ lib/l10n/app_zh_Hant.arb:174 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.misfire into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 定址 | addressing | docs/protocol-deviations.zh-TW.md:101 '正確定址被丟掉了' ↔ docs/protocol-deviations.zh-TW.md:107 names `lib/obd/addressing.dart:1` and 'addressing' (T3) | evidenced | 'functional addressing' = 功能定址 (field-guide:211); 'physical header' = 實體標頭 (protocol-deviations:107). |
| 已儲存 | stored | lib/l10n/app_en.arb:457 ↔ lib/l10n/app_zh_Hant.arb:744 (T1 same ARB key) | evidenced | Moved out of DtcKind when lib/obd/ stopped carrying screen copy. The enum still holds 已儲存 as `transcriptLabel`, which is export copy and stays Chinese in every locale — do not cite that as the UI translation. |
| 底盤 | chassis | lib/l10n/app_en.arb:2573 ↔ lib/l10n/app_zh_Hant.arb:751 (T1 same ARB key `dtcSystemChassis`) | evidenced |  |
| 待確認 | pending | lib/l10n/app_en.arb:457 ↔ lib/l10n/app_zh_Hant.arb:745 (T1 same ARB key) | evidenced | Not 'detected' and not 'confirmed': a Mode 07 code has been seen once and has not reached the confirmation threshold. |
| 微粒濾清器 | particulate filter | lib/l10n/app_en.arb:594 ↔ lib/l10n/app_zh_Hant.arb:179 (T1 same ARB key) | evidenced |  |
| 批次 | batch | README.md:87 'no identifier scan, batch, automatic retry' ↔ README.zh-TW.md:73 '不掃描 identifier、不批次、不自動重試' (T1); docs/protocol-deviations.zh-TW.md:83 'fastMode 批次查詢' | evidenced |  |
| 排放就緒 | readiness | README.md:56 'readiness' ↔ README.zh-TW.md:50 '排放就緒' (T1); docs/field-guide.zh-TW.md:238 '排放就緒狀態' | evidenced | zh adds 排放 (emissions) that bare English 'readiness' omits; keep it — the field guide relies on the emissions sense. |
| 排氣感知器 | exhaust sensor | lib/l10n/app_en.arb:586 ↔ lib/l10n/app_zh_Hant.arb:170 (T1 same ARB key `dtcMonitorExhaustSensor`) | evidenced | Label moved out of ReadinessMonitor.exhaustSensor into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 控制器 | controller | lib/state/dtc_scan.dart:47 'Controllers that gave this category a terminal answer.' ↔ same file :581 '控制器 … 回報…' (T3 same file); docs/field-guide.zh-TW.md:206 | inferred | zh at lib/state/dtc_scan.dart:581; en at :47 of the same file, 534 lines away — not one place. |
| 故障碼 | fault code | README.md:56 'fault codes' ↔ README.zh-TW.md:50 '故障碼' (T1) | evidenced | DTC as an acronym stays English (see doNotTranslate); the spelled-out concept is 故障碼. |
| 標頭 | header | lib/l10n/app_en.arb:33 ↔ lib/l10n/app_zh_Hant.arb:123 (T1 same ARB key) | evidenced |  |
| 故障燈 | MIL | lib/obd/polling_engine.dart:2875 (T3) | inferred | The app ships 故障燈 in Chinese prose and MIL only inside an English PID name (`Distance Travelled With MIL On`); no place writes both, so the pairing is this glossary's. Spell it out on first mention in English if the audience may not know the acronym |
| 永久 | permanent | lib/l10n/app_en.arb:2553 ↔ lib/l10n/app_zh_Hant.arb:746 (T1 same ARB key) | evidenced | A permanent code is NOT clearable, and English copy must never imply that pressing Clear removes it. dtcKindPermanentExplanation (lib/l10n/app_en.arb:2565 ↔ lib/l10n/app_zh_Hant.arb:749) carries 無法用診斷儀清除，需修復後由 ECU 自行確認 and its English; dtcClearDialogBody (lib/l10n/app_en.arb:457 ↔ lib/l10n/app_zh_Hant.arb:142) repeats it beside the Clear button. #45 names this explicitly |
| 汽油微粒濾清器（GPF） | gasoline particulate filter (GPF) | lib/l10n/app_en.arb:594 ↔ lib/l10n/app_zh_Hant.arb:172 (T1 same ARB key `dtcMonitorGasolineParticulateFilter`) | evidenced | LOAD-BEARING: field-guide:247-249 says many OBD tables mistranslate this bit as 空調冷媒 (A/C refrigerant) and that is wrong. Keep GPF in the string. |
| 無回應，稍後重試 | no answer | lib/l10n/app_en.arb:728 ↔ lib/l10n/app_zh_Hant.arb:126 (T1 same ARB key) | evidenced |  |
| 燃油系統監控 | fuel system | lib/l10n/app_en.arb:590 ↔ lib/l10n/app_zh_Hant.arb:171 (T1 same ARB key `dtcMonitorFuelSystem`) | evidenced | Label moved out of ReadinessMonitor.fuelSystem into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 監控項目 | readiness monitor | lib/obd/readiness.dart:1 'The emissions readiness monitors' + enum `ReadinessMonitor` :41 ↔ docs/field-guide.zh-TW.md:240,243-245 '監控項目' (T3 identifier ↔ zh prose) | inferred | zh at docs/field-guide.zh-TW.md:240; en at lib/obd/readiness.dart:1. Assembled from two documents. |
| 綜合元件監控 | components | lib/l10n/app_en.arb:574 ↔ lib/l10n/app_zh_Hant.arb:167 (T1 same ARB key) | evidenced |  |
| 網路 | network | lib/l10n/app_en.arb:52 ↔ lib/l10n/app_zh_Hant.arb:753 (T1 same ARB key) | evidenced |  |
| 自訂 PID | custom PID | README.md:56 'custom PIDs' ↔ README.zh-TW.md:50 '自訂 PID' (T1) | evidenced |  |
| 蒸發排放系統 | evaporative | lib/l10n/app_en.arb:584 ↔ lib/l10n/app_zh_Hant.arb:169 (T1 same ARB key) | evidenced | The English ships as "Evaporative system" — the evaporative emission system, not the exhaust. Label moved out of ReadinessMonitor.evaporative into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 觸媒轉換器 | catalyst | lib/l10n/app_en.arb:598 ↔ lib/l10n/app_zh_Hant.arb:166 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.catalyst into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 診斷紀錄 | diagnostic transcript | README.md:57 ↔ README.zh-TW.md:51 (T1); also README.md:95 ↔ README.zh-TW.md:79; docs/field-guide.zh-TW.md:122,289 UI path 設定 → 診斷紀錄 | evidenced |  |
| 車身 | body | lib/l10n/app_en.arb:2577 ↔ lib/l10n/app_zh_Hant.arb:752 (T1 same ARB key) | evidenced |  |
| 車輛即時遙測 | Live vehicle telemetry | lib/l10n/app_en.arb:30 ↔ lib/l10n/app_zh_Hant.arb:18 (T1 same ARB key) | evidenced | Also the Google Play store name suffix. Use verbatim for appTagline. |
| 輪詢 | polling | README.md:87 'scheduled polling' ↔ README.zh-TW.md:73 '排程輪詢' (T1); README.md:159 'idle polling' ↔ README.zh-TW.md:134 '閒置輪詢' | evidenced |  |
| 轉接器 | adapter | README.md:11 'ELM327-compatible adapter' ↔ README.zh-TW.md:10 'ELM327 相容轉接器' (T1); lib/l10n/app_en.arb:44 ↔ lib/l10n/app_zh_Hant.arb:26 | evidenced | Never 適配器/配接器. 轉接器 is used throughout README.zh-TW, field-guide and lib/. |
| 選擇連線方式 | Choose a connection | lib/l10n/app_en.arb:110 ↔ lib/l10n/app_zh_Hant.arb:57 (T1 same ARB key) | evidenced |  |
| 電門 | ignition | lib/l10n/app_en.arb:58 ↔ lib/l10n/app_zh_Hant.arb:31 (T1 same ARB key) | evidenced | 電門 (not 點火/鑰匙門). Reused throughout docs/field-guide.zh-TW.md:59,145,146,267,298. |


## Hardware and transport

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| Bluetooth Classic | Bluetooth Classic | README.md:52 ↔ README.zh-TW.md:46 (T1 — unchanged) | evidenced | Transport product names stay English; generic 'bluetooth' becomes 藍牙 (docs/field-guide.zh-TW.md:21 '系統藍牙設定', :66 '藍牙配對清單'). Context rule, not one pair. |
| Bluetooth LE | Bluetooth LE | README.md:53 ↔ README.zh-TW.md:47 (T1 — unchanged); docs/field-guide.zh-TW.md:23 'App 裡選 Bluetooth LE' | evidenced |  |
| GATT UART service | GATT UART service | README.md:53 'a GATT UART service' ↔ README.zh-TW.md:47 '（GATT UART service）' (T1 — unchanged) | evidenced |  |
| RFCOMM/SPP | RFCOMM/SPP | README.md:52 ↔ README.zh-TW.md:46 (T1 — unchanged) | evidenced |  |
| Wi-Fi 轉接器 | Wi-Fi adapter | README.md:54 'Wi-Fi adapters using a local TCP connection' ↔ README.zh-TW.md:48 'Wi-Fi 轉接器的區域 TCP 連線' (T1) | evidenced |  |
| 區域 TCP 連線 | local TCP connection | README.md:54 ↔ README.zh-TW.md:48 (T1) | evidenced |  |
| 工作階段 | session | README.md:118 'session dated 2026-08-27' ↔ README.zh-TW.md:99 '復原工作階段紀錄' (T1); README.md:156 ↔ README.zh-TW.md:132-133 | evidenced | Not 會話/場次. lib/obd/session_evidence.dart:138 ships '# Telltale 實車證據 v1'. |
| 已實車連線的轉接器 | Field-tested adapter | README.md:113 '## Field-tested adapter' ↔ README.zh-TW.md:94 '## 已實車連線的轉接器' (T1 heading) | evidenced | zh deliberately says 'has connected to a real car', weaker than English 'field-tested'. Preserve the weaker claim. |
| 社群簽章 | community-signed | README.md:42 'community-signed APK' ↔ README.zh-TW.md:38 '社群簽章 APK' (T1); README.md:46 'community signing key' ↔ README.zh-TW.md:41 '使用社群簽章' | evidenced |  |
| 解除安裝 | uninstall | README.md:47-48 'requires uninstalling Telltale' ↔ README.zh-TW.md:42 '必須先解除安裝' (T1) | evidenced |  |
| 轉接器緩衝區溢位 | buffer full | lib/obd/elm327_client.dart:85 Elm327ErrorCode.bufferFull => '轉接器緩衝區溢位' (T3) | evidenced |  |
| 電壓過低導致轉接器重置 | low voltage reset | lib/obd/elm327_client.dart:90 Elm327ErrorCode.lowVoltageReset (T3) | evidenced |  |


## Interface

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| App 截圖與實車示範 | Screenshots and vehicle demo | README.md:17 ↔ README.zh-TW.md:16 (T1 heading) | evidenced |  |
| Language / 語言 | Language / 語言 | lib/l10n/app_en.arb:885 ↔ lib/l10n/app_zh_Hant.arb:250 (T1 same ARB key) | evidenced | DO NOT localize. app_en.arb:10 description: 'Bilingual label for the language picker. Options use self-names.' |
| 主打圖片（feature graphic） | feature graphic | store/README.md:25 '主打圖片（feature graphic）' (T1 — the project's own inline gloss) | evidenced |  |
| 儀表 | gauge | README.md:64 'read-only BMS gauges' ↔ README.zh-TW.md:57 '唯讀 BMS 儀表' (T1) | evidenced | See the 即時 PID 儀表 note: 儀表 renders both 'gauge' and 'PID dashboard'. |
| 儀表板 | dashboard | README.md:21 alt 'Telltale live telemetry dashboard' ↔ README.zh-TW.md:20 alt 'Telltale 即時遙測儀表板' (T1); store/README.md:27 | evidenced |  |
| 刪除 | delete | lib/l10n/app_en.arb:1951 ↔ lib/l10n/app_zh_Hant.arb:278 (T1 same ARB key) | evidenced |  |
| 匯出 | export | lib/l10n/app_en.arb:2032 ↔ lib/l10n/app_zh_Hant.arb:593 (T1); README.md:57 'export' ↔ README.zh-TW.md:51 '匯出' | evidenced |  |
| 回放 | replay | lib/l10n/app_en.arb:1954 ↔ lib/l10n/app_zh_Hant.arb:566 (T1 same ARB key) | evidenced |  |
| 外觀 | Appearance | lib/l10n/app_en.arb:35 ↔ lib/l10n/app_zh_Hant.arb:23 (T1 same ARB key) | evidenced |  |
| 性能量測 | performance | store/README.md:29 '`05-performance.png` … 手機截圖：性能量測' (T1) | evidenced |  |
| 應用程式圖示 | app icon | store/README.md:24 '`icon-512.png` … 應用程式圖示' (T1) | proposed | English has no source in the tree; the cited file is Chinese-only |
| 手機截圖 | phone screenshot | store/README.md:26-30 (T1 table, paired with the English PNG filenames) | proposed | English has no source in the tree; the cited file is Chinese-only |
| 設定 | Settings | lib/l10n/app_en.arb:45 settingsHeadline ↔ lib/l10n/app_zh_Hant.arb:27 (T1) | evidenced |  |
| 設定頁 | Settings | README.md:123 'Settings shows the full disclosure card' ↔ README.zh-TW.md:103 '設定頁是完整揭露卡' (T1) | evidenced | context: screen |
| 連線頁 | Connect | README.md:124 'Connect keeps a secondary text link' ↔ README.zh-TW.md:103-104 '連線頁只在轉接器列表下方放次要文字連結' (T1) | evidenced | context: screen |
| 重試 | Retry | lib/l10n/app_en.arb:704 ↔ lib/l10n/app_zh_Hant.arb:197 (T1 same ARB key) | evidenced |  |
| 面盤外觀 | skins | store/README.md:30 '`06-skins.png` … 手機截圖：語言與面盤外觀' (T1 filename ↔ zh gloss in the same table row) | evidenced | 面盤 = the dial face. Related: README.md:64 'BMS gauges' ↔ README.zh-TW.md:57 'BMS 儀表'. |


## Data, evidence and status

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| 資料已過期 | stale | lib/l10n/app_en.arb:305 ↔ lib/l10n/app_zh_Hant.arb:663 (T1 same ARB key) | evidenced | #45 names this explicitly: stale ≠ live. A reading that stopped updating is not a current one, and must never render as though it were |
| ECU 回報 | ECU reported | lib/l10n/app_en.arb:419 ↔ lib/l10n/app_zh_Hant.arb:721 (T1 same ARB key, `derivedEcuReported`) | evidenced | The identifier for the fuel case says `measured`; both shipped strings say the ECU reported it. #44 forbids rendering 推算/estimate as measured, and using the bare word for the true case invites exactly that slip, so the English names the reporter rather than the act of measuring. `derivedFuelSourceEcu` briefly held a second, byte-identical copy of this sentence and was merged away. |
| VE | VE | README.md:75 ↔ README.zh-TW.md:65 (T1 — unchanged); spelled out as 容積效率 in lib/obd/session_evidence.dart:205 'volumetricEfficiency' | evidenced |  |
| make／廠牌（製造商部門） | make label | README.md:73 '146 make labels' ↔ README.zh-TW.md:64 '146 個 make／廠牌（製造商部門）標籤' (T1 — the project's own inline gloss) | evidenced | zh keeps the English token AND glosses it, because EPA 'make' means a manufacturer division, not a brand. Keep both halves. |
| 來源 | provenance | README.md:189 'evidence, provenance, and real-vehicle limits' ↔ README.zh-TW.md:163 '證據、來源與實車限制' (T2) | evidenced |  |
| 來源 revision | source revision | README.md:91-92 ↔ README.zh-TW.md:77 (T1 — 'revision' kept English) | evidenced |  |
| 傳動效率 | transmission efficiency | README.md:75 ↔ README.zh-TW.md:65 (T1) | evidenced |  |
| 原廠資料 | manufacturer data | lib/l10n/app_en.arb:2838 ↔ lib/l10n/app_zh_Hant.arb:938 (T1 same ARB key) | evidenced | The English was 'manufacturer publication' here while nothing shipped it. What ships is 'manufacturer data': shorter, and 'publication' invites the reader to expect a document they can go and read. |
| 大電池目錄 | powertrain-battery catalog | README.md:58 'powertrain-battery catalog' ↔ README.zh-TW.md:52 '大電池目錄' (T1) | evidenced |  |
| 大電池車型設定 | powertrain battery profiles | README.md:189 doc table ↔ README.zh-TW.md:163 doc table (T2 same table row) | evidenced |  |
| 官方型錄 | official registry | lib/l10n/app_en.arb:2834 ↔ lib/l10n/app_zh_Hant.arb:937 (T1 same ARB key) | evidenced | The strongest of the five origins. It must not be worded so as to sound like a measurement of this car — it is a record about this model. |
| 容積效率 | volumetric efficiency | lib/obd/session_evidence.dart:205 'volumetricEfficiency' => '容積效率' (T3) | evidenced |  |
| 實驗室 | laboratory | README.md:69 'the one-shot laboratory' ↔ README.zh-TW.md:59 '單次實驗室' (T1); README.md:81-82 ↔ README.zh-TW.md:70 | evidenced |  |
| 年式 | model year | README.md:73 'model years 1984–2027' ↔ README.zh-TW.md:64 '年式 1984–2027' (T1); README.md:85 'selected year' ↔ README.zh-TW.md:72 '所選年式' | evidenced |  |
| 快照 | snapshot | README.md:72 'EPA Find-a-Car snapshot' ↔ README.zh-TW.md:63 'EPA Find-a-Car 快照' (T1); README.md:179 ↔ README.zh-TW.md:153 | evidenced |  |
| 手動輸入 | entered by you | lib/l10n/app_en.arb:2830 ↔ lib/l10n/app_zh_Hant.arb:936 (T1 same ARB key) | evidenced | 'user entered' was the glossary's own coinage and read like a database column. The shipped English addresses the reader, because the point of the word is that the app did not check this number — they typed it. |
| 扭力 | torque | README.md:75 ↔ README.zh-TW.md:65 (T1); README.md:77 ↔ README.zh-TW.md:67 | evidenced | 扭力 (TW) not 扭矩 (CN). Distinct from the Torque/Torque Pro product name at README.md:216 ↔ README.zh-TW.md:181 'Torque / Torque Pro', which is never translated. |
| 排氣量 | displacement | lib/obd/session_evidence.dart:203 'displacementL' => '排氣量' (T3 key ↔ label); docs/field-guide.zh-TW.md:164 | evidenced |  |
| 正面投影面積 | frontal area | lib/obd/session_evidence.dart:209 'frontalAreaM2' => '正面投影面積' (T3) | evidenced |  |
| 油耗 | fuel estimate | README.md:77-78 ↔ README.zh-TW.md:67 (T1); docs/field-guide.zh-TW.md:163 '推算數值（馬力、扭力、油耗）' | evidenced |  |
| 滾動阻力係數 | rolling resistance | lib/obd/session_evidence.dart:210 'rollingResistance' => '滾動阻力係數' (T3) | evidenced |  |
| 燃料種類 | fuel type | lib/obd/session_evidence.dart:206 'fuelType' => '燃料種類' (T3) | evidenced |  |
| 經完整性檢查 | integrity-checked | README.md:58 ↔ README.zh-TW.md:52 (T1); README.md:72 ↔ README.zh-TW.md:63 | evidenced |  |
| 車輛設定 | vehicle profile | README.md:76 'every configured vehicle profile' ↔ README.zh-TW.md:66 '每組車輛設定' (T1) | evidenced | INCONSISTENCY: 'profile' is 車輛設定 here, 'profiles' ↔ '車型設定' at README.md:189 ↔ README.zh-TW.md:163, and kept as bare `profile` at README.zh-TW.md:77. Three renderings. |
| 車重 | mass | README.md:75 'does not infer mass, torque, drag, VE' ↔ README.zh-TW.md:65 '不推測車重、扭力、風阻、VE' (T1); lib/obd/session_evidence.dart:204 'massKg' => '車重' | evidenced |  |
| 通用預設 | generic default | lib/l10n/app_en.arb:2826 ↔ lib/l10n/app_zh_Hant.arb:935 (T1 same ARB key) | evidenced | The weakest of the five origins, and the one a reader most needs to spot: it means the estimate is about a car, not about their car. |
| 模型係數 | model coefficient | lib/l10n/app_en.arb:2842 ↔ lib/l10n/app_zh_Hant.arb:939 (T1 same ARB key) | evidenced | A number from a physical model rather than from this vehicle. Never 'measured' and never 'official' — #44's rule about 推算 applies to it directly. |
| 雜湊 | hash | README.md:91 'verified catalog hash' ↔ README.zh-TW.md:77 '已驗證的目錄雜湊' (T1); README.md:188 'hashes' ↔ README.zh-TW.md:162 '雜湊' | evidenced |  |
| 風阻 | drag | README.md:75 ↔ README.zh-TW.md:65 (T1); lib/obd/session_evidence.dart:208 'dragCoefficient' => '風阻係數' | evidenced |  |
| 馬力 | horsepower | README.md:77 'profile-derived horsepower, torque, and fuel estimates' ↔ README.zh-TW.md:67 '實車的馬力、扭力或油耗' (T1) | evidenced |  |
| 驅動方式 | drivetrain | lib/obd/session_evidence.dart:207 'drivetrain' => '驅動方式' (T3); README.zh-TW.md:66 '風阻與驅動方式' | evidenced |  |


## Safety and refusal

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| cooldown | cooldown | README.md:93 'a five-second cooldown' ↔ README.zh-TW.md:78 '五秒 cooldown' (T1 — kept English) | evidenced |  |
| single-flight | single-flight | README.md:94 ↔ README.zh-TW.md:78 (T1 — kept English) | evidenced |  |
| 一次性同意 | one-use consent | README.md:91 'The one-use consent is bound to…' ↔ README.zh-TW.md:77 '一次性同意會綁定…' (T1) | evidenced |  |
| 同意規則 | consent rules | README.md:99 ↔ README.zh-TW.md:81 (T1) | evidenced |  |
| 唯讀 | read-only | README.md:64 'read-only BMS gauges' ↔ README.zh-TW.md:57 '唯讀 BMS 儀表' (T1); README.md:70 ↔ README.zh-TW.md:61; docs/field-guide.zh-TW.md:333 '只接受唯讀查詢' | evidenced |  |
| 大電池證據實驗室 | battery laboratory | README.md:81 'The experimental battery laboratory is off by default.' ↔ README.zh-TW.md:70 '大電池證據實驗室預設關閉。' (T1) | evidenced |  |
| 清除 | clear | README.md:202 'before clearing DTCs' ↔ README.zh-TW.md:174 '清除 DTC 前' (T1); docs/field-guide.zh-TW.md:251 '### 清除' | evidenced | context: DTCs |
| 確認 | acknowledgement | README.md:65 'install-time identity acknowledgement' ↔ README.zh-TW.md:58 '安裝時需確認車輛身分' (T1); README.md:84 ↔ README.zh-TW.md:72 | evidenced |  |
| 證據 | evidence | README.md:96 'as evidence' ↔ README.zh-TW.md:80 '作為證據' (T1); README.md:185 ↔ README.zh-TW.md:159 | evidenced |  |
| 證據邊界 | evidence boundary | README.md:129-130 'for the evidence boundary' ↔ README.zh-TW.md:108 '證據邊界見' (T1) | evidenced |  |
| 車輛已安全停妥 | safely parked vehicle | README.md:85 'a safely parked vehicle' ↔ README.zh-TW.md:72 '車輛已安全停妥' (T1) | evidenced | Safety-critical. docs/field-guide.zh-TW.md:301 '只在車輛完全停妥時操作，行進中交給乘客。' |
| 連線世代 | connection generation | README.md:92 'connection generation' ↔ README.zh-TW.md:77-78 '連線世代' (T1) | evidenced |  |
| 閘門 | gate | README.md:189 'install gates' ↔ README.zh-TW.md:163 '安裝閘門' (T1); README.md:102 'public compile gates' ↔ README.zh-TW.md:85 '公開編譯閘門' | evidenced |  |
| 隔離 | quarantine | README.md:94 'structural-mismatch quarantine' ↔ README.zh-TW.md:79 '結構錯誤隔離' (T1) | evidenced | Same zh word also renders 'isolated' at README.md:148 ↔ README.zh-TW.md:126 ('isolated `rig` flavor' / '隔離的 `rig` flavor'). |
| 驗證邊界 | verification boundary | README.md:150 '## Verification boundary' ↔ README.zh-TW.md:128 '## 驗證邊界' (T1 heading); README.md:99 'validation boundary' ↔ README.zh-TW.md:81 '驗證邊界' | evidenced |  |


## Licence, store and disclosure

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| 佣金 | commission | README.md:122 'may pay the maintainer a commission' ↔ README.zh-TW.md:102 '可能讓維護者取得佣金' (T1) | evidenced | Keep the modal: 'may pay' / '可能…取得', never 'will'. |
| 來源與重用聲明 | source and reuse notices | README.md:218 ↔ README.zh-TW.md:182-183 (T1) | evidenced |  |
| 授權與聲明 | Licence and disclaimer | README.md:212 '## Licence and disclaimer' ↔ README.zh-TW.md:178 '## 授權與聲明' (T1 heading) | evidenced | British 'Licence' in prose (README.md:99,212); the SPDX id GPL-3.0 and the LICENSE filename stay as-is. |
| 推廣分潤連結 | affiliate link | README.md:120-121 'this is a maintainer affiliate link' ↔ README.zh-TW.md:101-102 '這是維護者的推廣分潤連結' (T1) | evidenced | Disclosure copy — regulated. Do not shorten to 推薦連結. |
| 揭露卡 | disclosure card | README.md:123 'the full disclosure card' ↔ README.zh-TW.md:103 '完整揭露卡' (T1) | evidenced |  |
| 版本紀錄 | Changelog | README.md:190 doc table ↔ README.zh-TW.md:164 (T2) | evidenced |  |
| 社群互動規範 | community expectations | README.md:204 'for community expectations' ↔ README.zh-TW.md:175-176 '社群互動規範見' (T1) | evidenced | also written: Code of Conduct |
| 第三方來源聲明 | third-party notices | README.md:219-220 'separate third-party notices' ↔ README.zh-TW.md:183-184 '另有第三方來源聲明' (T1) | evidenced |  |
| 自行承擔使用風險 | at your own risk | README.md:220-221 'Use the app at your own risk' ↔ README.zh-TW.md:184 '請自行承擔使用風險' (T1) | evidenced |  |
| 貢獻指南 | Contributing | README.md:191 doc table ↔ README.zh-TW.md:165 (T2); README.md:214 'the contributor guide' ↔ README.zh-TW.md:180 '貢獻指南' | evidenced | also written: contributor guide |
| 隱私權政策 | privacy policy | README.md:199 'published privacy policy' ↔ README.zh-TW.md:172 '已發布的隱私權政策' (T1) | evidenced |  |
| 隱私與安全使用 | Privacy and safe use | README.md:193 heading ↔ README.zh-TW.md:167 heading (T1) | evidenced |  |


## Build, release and tooling

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| flavor | flavor | README.md:148 'The `field` flavor … the isolated `rig` flavor' ↔ README.zh-TW.md:125-126 (T1 — unchanged) | evidenced |  |
| 協定差異 | Protocol deviations | README.md:187 doc table ↔ README.zh-TW.md:161 (T2); the zh doc's own H1 is '公式與 AT 指令的交叉驗證記錄' (docs/protocol-deviations.zh-TW.md:1) | evidenced |  |
| 可重現的模擬器 | deterministic simulators | README.md:177 ↔ README.zh-TW.md:151 (T1) | evidenced |  |
| 契約 | contract | README.md:175 'Unit, contract, parser, and widget tests' ↔ README.zh-TW.md:149 '單元、契約、parser 與 widget 測試' (T1) | evidenced | 'parser' and 'widget' stay English inside the zh row; 'unit' and 'contract' are translated.; context: test |
| 實車指南 | Field guide | README.md:186 doc table ↔ README.zh-TW.md:160 (T2); the zh doc's own H1 is '上車前速查' (docs/field-guide.zh-TW.md:1) | evidenced | The doc's H1 (上車前速查) and its table label (實車指南) differ on purpose. Do not unify. |
| 專案目錄 | Repository layout | README.md:170 heading ↔ README.zh-TW.md:144 heading (T1) | evidenced |  |
| 工具鏈 | toolchain | README.md:134 'Use the pinned Flutter 3.47.0 toolchain' ↔ README.zh-TW.md:112 '使用固定的 Flutter 3.47.0 工具鏈' (T1) | evidenced |  |
| 平台整合 | platform integration | README.md:178 ↔ README.zh-TW.md:152 (T1) | evidenced |  |
| 文件索引 | Documentation index | README.md:185 doc table ↔ README.zh-TW.md:159 (T2) | evidenced |  |
| 測試證據 | test evidence | README.md:165 'Start with [test evidence]' ↔ README.zh-TW.md:140 '[測試證據]' (T1) | evidenced |  |
| 裝置驗證 | device verification | README.md:166 ↔ README.zh-TW.md:141 (T1) | evidenced |  |
| 車輛資料來源 | Vehicle data sources | README.md:188 doc table ↔ README.zh-TW.md:162 (T2) | evidenced |  |
| 驗證馬具矩陣 | verification rig matrix | README.md:167-168 'verification rig matrix' ↔ README.zh-TW.md:142 '驗證馬具矩陣' (T1) | evidenced | 'rig' = 馬具 in prose but stays `rig` as a flavor/identifier (README.zh-TW.md:126,150). |

## Known gaps

One concept this project relies on has **no Traditional Chinese term anywhere in the
tree**, and inventing one inside a translation PR would put a coined term in front of users
without anybody deciding it.

| Concept | English | Status |
|---|---|---|
| A component that refuses rather than guesses when it cannot confirm something | fail-closed | **no established Chinese** |

`安全確認流程` at `README.zh-TW.md:66` is sometimes mistaken for the equivalent. It is not:
it names one specific confirmation flow, while *fail-closed* is a property the whole app is
built on — the transport, the clear-DTC gate, the startup checks and the freeze-frame gate
all fail closed. Translating the property as the name of one flow would shrink it.

A translator who needs it must coin a term, use it consistently, and flag it for
maintainer sign-off in the pull request rather than settling it in review comments.
