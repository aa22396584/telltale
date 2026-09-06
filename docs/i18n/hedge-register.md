# Hedge register

A hedge is a sentence whose job is to stop a reader believing something the evidence does
not support. This project is built on one: *a plausible wrong number is worse than no
number.* Every entry below is load-bearing product copy, and a translation that softens,
shortens, or drops one produces the prose equivalent of a plausible wrong number.

**A translation of a hedge is reviewed against this file, not against fluency.** If the
English reads a little heavier than a native writer would choose, that is the correct
outcome. Weakening a qualifier to improve rhythm is a defect.

Entries marked **proposed** have no established English in the tree yet; the English is a
reviewer's invention and needs maintainer sign-off before it ships.

26 entries.

### 1. 一個看起來合理的錯數字，比沒有數字更糟。

**繁體中文** — 一個看起來合理的錯數字，比沒有數字更糟。

**English** — A plausible wrong number is worse than no number.

**Why it is load-bearing.** THE TAGLINE. README.zh-TW.md:14 ↔ README.md:15 (T1), both blockquoted and bold; docs/index.html:113 (zh) ↔ :150 (en) carries the same pair on the published site. CONTRIBUTING.md:165 calls it 'the organising principle'; docs/protocol-deviations.zh-TW.md:12 applies it ('把「看起來合理的錯數字」直接印在錶上'), and lib/obd/addressing.dart:216, lib/obd/polling_engine.dart:970 and lib/obd/elm327_client.dart:3117 all invoke it in English as a design constraint. Translate as a standalone aphorism — never soften 更糟/'worse' to 'less useful', and never drop the comparison to *no* number.

### 2. 這是該組合的實測證據，不代表所有手機、轉接器或車輛都相容。

**繁體中文** — 這是該組合的實測證據，不代表所有手機、轉接器或車輛都相容。

**English** — the demo is evidence for that observed setup, not a universal compatibility claim.

**Why it is load-bearing.** README.zh-TW.md:27-28 ↔ README.md:28-30 (T1). Scopes the YouTube demo to one phone+adapter+car. Load-bearing negation: 'evidence for X, NOT a claim about all X'. Dropping 不代表/'not a universal claim' converts an observation into a compatibility promise.

### 3. 這只代表一組轉接器、手機與車輛的實際觀察，不是認證，也不保證同一賣場的所有版本、所有手機、車輛、PID 或韌體行為相同。

**繁體中文** — 這只代表一組轉接器、手機與車輛的實際觀察，不是認證，也不保證同一賣場的所有版本、所有手機、車輛、PID 或韌體行為相同。

**English** — This is one observed adapter/phone/vehicle combination, not certification or a promise that every listing variant, phone, vehicle, PID, or firmware behaves the same.

**Why it is load-bearing.** README.zh-TW.md:106-107 ↔ README.md:126-128 (T1). Sits directly under an affiliate link, so it is also a commercial-disclosure hedge. Both negations (不是認證 / 也不保證) must survive; the enumeration of what is NOT covered is deliberate.

### 4. 這項觀察**不代表**已認證轉接器韌體、PID 準確度、DTC 涵蓋率、道路負載行為或所有 GT86。

**繁體中文** — 這項觀察**不代表**已認證轉接器韌體、PID 準確度、DTC 涵蓋率、道路負載行為或所有 GT86。

**English** — the observation does **not** certify adapter firmware, PID accuracy, DTC coverage, loaded-road behaviour, or general GT86 support.

**Why it is load-bearing.** README.zh-TW.md:136-137 ↔ README.md:161-162 (T1). The bold on 不代表/**not** is in the source and must be kept — it is the only visual cue that the preceding paragraph of positive evidence is bounded.

### 5. 驗證文件只描述有邊界的證據，不是認證或安全保證。

**繁體中文** — 驗證文件只描述有邊界的證據，不是認證或安全保證。

**English** — Verification reports describe bounded evidence, not certification or a safety guarantee.

**Why it is load-bearing.** README.zh-TW.md:139 ↔ README.md:164-165 (T1). Also stated at docs/README.md:3-5 ('they are **not** certifications of an adapter, diagnosis, repair, vehicle, or safety outcome'). 有邊界/'bounded' is the operative word; 'detailed'/'thorough' would invert the meaning.

### 6. Settings 的持久開關只會顯示實驗入口，不代表信任任何車輛。

**繁體中文** — Settings 的持久開關只會顯示實驗入口，不代表信任任何車輛。

**English** — Its persistent Settings switch only reveals the laboratory; it never trusts a vehicle.

**Why it is load-bearing.** README.zh-TW.md:70-71 ↔ README.md:81-82 (T1). Separates 'UI is visible' from 'data is trusted' for the experimental battery lab. 只會/'only' and 不代表信任/'never trusts' are both load-bearing; a user who reads this as 'enabling it enables the feature' will over-trust decoded BMS values.

### 7. 合成馬具或手機 transport 測試不等於實車 PID 或解碼正確性證明。

**繁體中文** — 合成馬具或手機 transport 測試不等於實車 PID 或解碼正確性證明。

**English** — a synthetic rig or phone transport test does not prove that a real vehicle exposes or correctly decodes that PID.

**Why it is load-bearing.** README.zh-TW.md:80 ↔ README.md:96-97 (T1). The project's standing rule that a passing test is not vehicle evidence. 不等於…證明 / 'does not prove' — not 'may not fully prove'.

### 8. 任何診斷結果都不保證車輛可安全行駛。

**繁體中文** — 任何診斷結果都不保證車輛可安全行駛。

**English** — no diagnostic result guarantees that a vehicle is safe to operate.

**Why it is load-bearing.** README.zh-TW.md:185 ↔ README.md:215-216 (T1). Final sentence of the README in both languages. Absolute negation (任何…都不 / 'no…guarantees'); any hedge-softening here is a liability change, not a style change.

### 9. 請只在停妥時操作，或交由乘客操作。清除 DTC 前先保存診斷證據，也不要以本 App 取代專業檢查。

**繁體中文** — 請只在停妥時操作，或交由乘客操作。清除 DTC 前先保存診斷證據，也不要以本 App 取代專業檢查。

**English** — Use the app only while parked or as a passenger. Save diagnostic evidence before clearing DTCs, and do not treat this app as a substitute for professional inspection.

**Why it is load-bearing.** README.zh-TW.md:174-175 ↔ README.md:201-203 (T1). Three safety imperatives in one breath. 只在/'only' scopes the first; the clear-before-save ordering is causal (clearing destroys the freeze frame — docs/field-guide.zh-TW.md:235); 取代/'substitute' must stay.

### 10. Telltale 不會主動上傳資料。

**繁體中文** — Telltale 不會主動上傳資料。

**English** — Telltale proactively uploads nothing.

**Why it is load-bearing.** README.zh-TW.md:169 ↔ README.md:195 (T1). 主動/'proactively' is the entire hedge — the app does not upload on its own, but the user CAN export and share, and OS backup may copy app data (README.zh-TW.md:169-170 ↔ README.md:196-198). Dropping 主動 turns a scoped claim into a false absolute.

### 11. 這次沒有讀到凍結幀 —— 不代表車上沒有。

**繁體中文** — 這次沒有讀到凍結幀 —— 不代表車上沒有。

**English** — NO PROJECT ENGLISH — proposed: This scan did not read a freeze frame — that does not mean the vehicle has none.

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:353 (also :89 and lib/obd/polling_engine.dart:3053 '凍結幀沒有讀到 —— 這不代表車上沒有。'). Explained at docs/field-guide.zh-TW.md:226-228. Distinguishes a READ FAILURE from an ABSENT freeze frame; the field guide tells users to rescan rather than clear, because clearing destroys an unread frame permanently. Collapsing this into 'no freeze frame' causes irreversible evidence loss.

### 12. 這個控制器沒有儲存凍結幀 —— 故障碼可能是清除後重新出現的，或是由不記錄凍結幀的模組所報告。

**繁體中文** — 這個控制器沒有儲存凍結幀 —— 故障碼可能是清除後重新出現的，或是由不記錄凍結幀的模組所報告。

**English** — NO PROJECT ENGLISH — proposed: This controller has stored no freeze frame — the code may have reappeared after a clear, or been reported by a module that does not record freeze frames.

**Why it is load-bearing.** lib/obd/freeze_frame.dart:125-126, which as of the
engine-layer l10n wave is an unused constant — no screen reads it, so this hedge is
currently a rule about a sentence the app does not ship. Wiring it up means giving it an
ARB entry first. The complement of the previous hedge: a CONFIRMED absence, with its two innocent explanations. The two strings must stay distinguishable in translation (docs/field-guide.zh-TW.md:223-228 teaches users to tell them apart).

### 13. 已回應的控制器都沒有故障碼。

**繁體中文** — 已回應的控制器都沒有故障碼。

**English** — NO PROJECT ENGLISH — proposed: None of the controllers that answered reported a fault code.

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:408. Glossed at docs/field-guide.zh-TW.md:206: '有回覆的模組都說沒事。**不代表車上每個模組都被問到了。**' The qualifier 已回應的/'that answered' is the whole hedge — it must never be rendered as 'no fault codes' or 'your car is fine'. Compare lib/state/dtc_scan.dart:593 '可能有控制器不在這次查詢的範圍內。請以車輛儀表為準，並洽維修廠。'

### 14. 部分未確認 / 無法確認

**繁體中文** — 部分未確認 / 無法確認

**English** — NO PROJECT ENGLISH — proposed: partially unconfirmed / cannot confirm

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:173 (ScanVerdict.partialClean => '部分未確認'). docs/field-guide.zh-TW.md:207-208 defines them: 部分未確認 = 'some categories could not be read, the verdict is incomplete'; 無法確認 = '**do not read this as "no problem"**'. These are verdict states, not prose — keep them short, distinct, and never merge into a single 'unknown'.

### 15. 請先重新掃描

**繁體中文** — 請先重新掃描

**English** — NO PROJECT ENGLISH — proposed: Rescan first

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:202 (the disabled clear-button label), :354, lib/state/dtc_scan.dart:336. docs/field-guide.zh-TW.md:275-278: the button IS the verdict of the last clear. Greyed + '請先重新掃描' means something may already have been cleared, so re-sending a global clear would reset a completed controller's readiness and cost the user another drive cycle. The imperative must stay an imperative.

### 16. 此車輛不支援這個 PID

**繁體中文** — 此車輛不支援這個 PID

**English** — NO PROJECT ENGLISH — proposed: This vehicle does not support this PID

**Why it is load-bearing.** lib/diagnostics/availability.dart:312 (PidFault.unsupported). Deliberately an assertion ABOUT THE CAR, which is why lib/obd/telemetry.dart:75,88 and lib/obd/polling_engine.dart:838,927,3743 all warn against reaching it on thin evidence — docs/protocol-deviations.zh-TW.md:117-119 records that ATAT2 would make one missed window read as 此車輛不支援 for the whole session. Must stay distinguishable from PidFault.noAnswer ('無回應，稍後重試', availability.dart:313), which is temporary.

### 17. 另有 N 個項目在這份凍結幀裡，本 App 沒有對應的換算公式

**繁體中文** — 另有 N 個項目在這份凍結幀裡，本 App 沒有對應的換算公式

**English** — NO PROJECT ENGLISH — proposed: N further items in this freeze frame have no conversion formula in this app

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:941. docs/field-guide.zh-TW.md:229-233 contrasts it with '有 N 個項目這次沒有讀回來' (dtc_screen.dart:955): the first is an APP limitation that rescanning will not change, the second is a READ FAILURE that rescanning usually fixes. '這兩句話意思不一樣：前者重掃也不會變，後者會。' Merging them destroys the user's next action.

### 18. 假設尚未確認，仍可估算

**繁體中文** — 假設尚未確認，仍可估算

**English** — NO PROJECT ENGLISH — proposed: Assumption unconfirmed — an estimate is still shown

**Why it is load-bearing.** lib/diagnostics/availability.dart:518. The fail-closed derived-value label: raw PIDs stay visible but profile-derived horsepower/torque/fuel are marked as resting on unconfirmed inputs (README.md:76-79 ↔ README.zh-TW.md:66-68). Both halves are required — 尚未確認 alone reads as an error, 仍可估算 alone reads as a validated number.

### 19. 無法確認車輛已停止；請先中斷連線

**繁體中文** — 無法確認車輛已停止；請先中斷連線

**English** — NO PROJECT ENGLISH — proposed: Cannot confirm the vehicle is stopped; disconnect first

**Why it is load-bearing.** lib/state/telemetry_sessions.dart:44 (TelemetryHistoryAccess.speedUnknown). A refusal gate, not a warning: unknown speed is treated as moving. Compare lib/state/app_share_coordinator.dart:160 ShareError.policyDenied => '目前的連線或行車狀態不允許匯出。' Translations must keep this as a refusal with a remedy, never as advice.

### 20. 目前無法完成啟動檢查 / 需要重新啟動才能安全繼續

**繁體中文** — 目前無法完成啟動檢查 / 需要重新啟動才能安全繼續

**English** — Cannot finish startup checks / Restart required to continue safely

**Why it is load-bearing.** lib/l10n/app_en.arb:16,21 ↔ lib/l10n/app_zh_Hant.arb:13,15 (T1). app_en.arb:18 description: 'Retryable startup failure title. Distinct from startupChecking (in-progress) and startupRestartRequired (must quit).' lib/l10n/startup_copy.dart:5-6: 'Loading, retryable failure, and restart-required are three states. They must not share copy.' Three states, three strings — a translator who merges any two breaks a documented invariant.

### 21. 本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。

**繁體中文** — 本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。

**English** — Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.

**Why it is load-bearing.** lib/l10n/app_en.arb:23 startupRestartHint ↔ lib/l10n/app_zh_Hant.arb:17 (T1). States the consequence (wrong file overwritten/deleted/SHARED) as the reason for the demand. The three-verb enumeration is the hedge — 'so nothing goes wrong' would delete the privacy half.

### 22. 無法儲存語言設定，請再試一次。

**繁體中文** — 無法儲存語言設定，請再試一次。

**English** — Could not save the language. Try again.

**Why it is load-bearing.** lib/l10n/app_en.arb:24 languageSaveFailed ↔ lib/l10n/app_zh_Hant.arb:18 (T1). The picker never silently claims success; a failed write is surfaced. Keep it a failure statement plus a remedy.

### 23. 不確定要選哪一個？

**繁體中文** — 不確定要選哪一個？

**English** — NO PROJECT ENGLISH — proposed: Not sure which to pick?

**Why it is load-bearing.** lib/ui/screens/connect/connect_screen.dart:1796; the body at :1808 says '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：' and the questions come from whichTransportGuidance() (:1814-1817). docs/field-guide.zh-TW.md:63-65: it asks three OBSERVABLE questions rather than requiring the user to know SPP/GATT. The uncertainty is the user's, and the copy is designed to accept it — a confident 'Choose your connection type' would defeat the purpose.

### 24. 猜錯不會怎麼樣 —— 連不上就退回來換另一個試。

**繁體中文** — 猜錯不會怎麼樣 —— 連不上就退回來換另一個試。

**English** — NO PROJECT ENGLISH — proposed: Guessing wrong costs nothing — if it will not connect, come back and try another.

**Why it is load-bearing.** lib/ui/screens/connect/connect_screen.dart:1830 (inside the 「不確定要選哪一個？」 disclosure). The in-code comment at :1826-1829 states the intent: 'the fear of picking wrong is what makes somebody close the app instead of tapping something. Nothing here is destructive and nothing is remembered until a handshake succeeds.' This is a permission-to-fail hedge; flattening it to 'Select a connection type' removes the reassurance it exists to give.

### 25. 尚無讀值

**繁體中文** — 尚無讀值

**English** — NO PROJECT ENGLISH — proposed: No reading yet

**Why it is load-bearing.** lib/diagnostics/availability.dart:318 (the null PidFault arm). 'Not yet read' — explicitly NOT 'zero' and NOT 'unsupported'. This is the app's baseline refusal to print a number it does not have; rendering it as '0' or '--' without the words reintroduces exactly the failure the tagline forbids.

### 26. 未知監控項目

**繁體中文** — 未知監控項目

**English** — NO PROJECT ENGLISH — proposed: Unknown monitor

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:1083 and :1091 (the readiness chip label). Explained at docs/field-guide.zh-TW.md:243-245: the vehicle reported a readiness monitor this app has no name for, and '它照樣會算進「還有 N 項沒有完成」—— 叫不出名字不等於可以當作已完成。' The hedge is that an UNNAMED monitor is still counted as INCOMPLETE; a translation that renders it 'N/A' or 'other' invites the reader to discount it.

### 27. 永久故障碼（Mode 0A）無法清除。

**繁體中文** — 永久故障碼（Mode 0A）無法清除。車輛需要重新完成一輪自我診斷才能通過驗車。

**English** — Permanent codes (Mode 0A) cannot be cleared. The vehicle has to complete a
fresh round of self-diagnosis before it will pass an inspection.

**Why it is load-bearing.** `dtcKindPermanentExplanation`
(`lib/l10n/app_en.arb:2172` ↔ `lib/l10n/app_zh_Hant.arb:638`) defines the category as
「無法用診斷儀清除，需修復後由 ECU 自行確認」— it lived on `DtcKind` in
`lib/obd/dtc/dtc.dart` until the engine stopped carrying screen copy — and
`dtcClearDialogBody` repeats it beside the Clear button. Issue #45 names this specific mistranslation: a
permanent code must never read as something Clear can remove. Somebody who believes it can
will press Clear, watch the stored and pending codes disappear, conclude the car is fixed,
and take it for an inspection it cannot pass — having also destroyed the freeze frame that
would have explained the fault. The whole point of the word is that this one does not go
away because you asked it to. **proposed** — the English above has not been confirmed by a
maintainer.
