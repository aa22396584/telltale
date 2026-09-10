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

62 entries. Every entry that names a **Shipped as** key is checked against the shipped
English by `test/l10n/hedge_register_guard_test.dart`, so adding a hedge here adds a guard.
That count is read by the same file and compared with the headings below, because a number
in prose that nothing verifies goes stale, and this one had.
**Why exact, and not something cleverer.** Three guards were written for the
sentences below before this file was used for them, and each was defeated in a
way the previous one had not anticipated:

1. *Does the sentence contain the words?* — defeated by a translation that keeps
   every word and reverses the claim: "The export **contains** the VIN, GPS, an
   account and the adapter address. It does not contain signal names…".
2. *Do the words fall on the right side of the negation?* — defeated by
   qualification rather than reversal: "It **usually** does not contain…", which
   is what an otherwise reasonable translator adds.
3. *Are `preview`, `sampled` and `export` in that order?* — defeated by one
   word: 「預覽**未**抽樣」 and "the preview is **not** sampled" move no position
   at all.

Order, split-points and word lists are heuristics, and heuristics against
translation are an arms race that the translation wins, because there are more
ways to say a thing than to check it. Recording the sentence and comparing the
whole of it ends the game: every edit fails, including the correct ones, and
updating this file is the moment a person is looking at the sentence anyway.
That cost is the feature.

The comparison is **exact after whitespace folding**, and there is no opt-out. Both
sides have U+00A0 folded to a space and runs of whitespace collapsed, because a Markdown
file picks those up from editors without anybody deciding to. The consequence is stated
rather than hidden: whitespace-only drift in an ARB is invisible to this guard, and it is
*not* invisible on screen — Flutter's `Text` does not collapse runs the way Markdown does,
and a U+00A0 changes where a line breaks. One other thing is folded, on the register side
only: `**bold**` here is compared as `bold`, because emphasis belongs to this Markdown file
and not to the string the app ships. So bolding a word inside a recorded English sentence
is invisible to the guard too — and a shipped string that really does contain `**` is not,
because the folding is one-sided and a separate check names it. Everything else is compared
whole. There used to be an opt-out: an entry could
write `**English (clause)**` and record only the load-bearing fragment of a longer shipped
sentence, bounded by 'the shipped string may not have grown by more than one sentence'.
That bound counts sentence terminators, so punctuation that does not terminate carried as
much reversing text as anybody cared to add — *This scan did not read a freeze frame — that
does not mean the vehicle has none, but on most vehicles clearing now is safe.* satisfies
it against entry 11's clause, one sentence against one. No entry ever used the form, so it
was removed rather than repaired: an unused feature with a known hole is worse than no
feature. Writing it now fails by name.

Three rules about the shape of an entry, enforced by the same file. They are stated here
because this is where somebody about to break one is looking.

- **One key per Shipped-as line.** A second key on the same line reads as guarded and is
  not; entries 42, 43 and 44 exist because of three that were. The count control cannot see
  it either, because the line still parses and still counts once. A second key belongs in
  its own entry.
- **Every backticked span on a Shipped-as line is that key or a repository path.** Anything
  else — `l10n.someKey`, a snippet, a fragment of prose — looks like a key to a reader and
  is not one the parser took. A path has to look like one here: a `/` under `lib`, `test`,
  `docs` or a sibling, so that `dtcMilOff/dtcMilUnknown` and `dtcMilOff.arb` fall through
  and are reported rather than waved past.
- **A key written without backticks fails the same way.** Both forms are caught: the
  qualified `l10n.someKey`, and a bare identifier that `lib/l10n/app_en.arb` actually
  declares. Membership in the shipped key set is how the second one is recognised, so an
  identifier that is *not* a shipped key is not detectable — do not use one to name a key.
  It cuts the other way too, and only because of a naming convention: the prose on these
  lines contains ordinary words like *clear*, *panel*, *frame* and *dialog*, and the scan is
  quiet about them only because no ARB key is spelled like an ordinary English word. Every
  key this app ships is `<domain>CamelCase` with an internal capital, and the guard now pins
  that, so adding a key called `clear` fails there and says why rather than accusing two
  entries of hiding keys they do not hide.
- **An entry whose recorded sentence is verbatim a string this app ships must name its
  key.** Otherwise the entry reads as guarded and nothing checks it.

An entry is `proposed` when, and only when, it carries the line

    **Status** — proposed

on its own, shaped like the **Shipped as** line beside it. That is the single exemption
from the third rule, so it is the one thing here that must not be writable by accident.
It used to be a mention — `**proposed**` searched for anywhere in the entry, or the words
`NO PROJECT ENGLISH` opening the **English** line — and a reviewer wrote *A reviewer once
**proposed** softening this.* into a Why paragraph and watched an entry leave the census.
These paragraphs narrate what reviewers did on almost every page, so that sentence is
house style, not a contrivance. An attestation is a field, not a sentence.

Prose about a proposal stays prose, and entry 27 still ends with one. Where the **English**
line also opens `NO PROJECT ENGLISH`, that is for a person to read; the two readings are
required to agree, so writing it without the field fails rather than quietly leaving the
entry in the census.

**A proposed entry may not also carry a Shipped as line.** The field says the English is not
established and the key says the app ships it, and the exact comparison would be passing
against that same key on the same run — so one of the two is wrong, and while both stand the
entry is exempt from the third rule for copy that demonstrably ships. That is the state
entries 16, 18, 25 and 26 were in before this file was made executable, arrived at from the
other direction. When a proposal ships, delete the field and add the key. The three entries
that carry the field today — 12, 17 and 27 — name no key on a **Shipped as** line; entry 27
names two in its prose, which is a citation and not a declaration, and settling whether its
English should become one of them is a maintainer's wording decision rather than a
mechanical one.

Two further shapes are checked because the parsers here are line-anchored and simple. The
headings must be numbered exactly 1..n in order — the numbers are how every fault message
and half the prose in this file refer to an entry — and the register must contain no fenced
blocks in either fence character, ``` or `~~~`, because a `### 5.` or a `60 entries.` inside
one would be read as real while rendering as an example. An indented code block is fine and
is used above: it renders as code and is invisible to every parser here, because all of them
are anchored at the start of a line.

### 1. 一個看起來合理的錯數字，比沒有數字更糟。

**繁體中文** — 一個看起來合理的錯數字，比沒有數字更糟。

**English** — A plausible wrong number is worse than no number.

**Why it is load-bearing.** THE TAGLINE. README.zh-TW.md:14 ↔ README.md:15 (T1), both blockquoted and bold; docs/index.html:113 (zh) ↔ :150 (en) carries the same pair on the published site. CONTRIBUTING.md:165 calls it 'the organising principle'; docs/protocol-deviations.zh-TW.md:12 applies it ('把「看起來合理的錯數字」直接印在錶上'), and lib/obd/addressing.dart:216, lib/obd/polling_engine.dart:1038 and lib/obd/elm327_client.dart:3117 all invoke it in English as a design constraint. Translate as a standalone aphorism — never soften 更糟/'worse' to 'less useful', and never drop the comparison to *no* number.

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

**繁體中文** — 這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。

**English** — This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear.

**Shipped as** `dtcClearDialogFrameUnread` (lib/l10n/app_en.arb). The panel says more and is entry 45. The sentence appears in more than one place on purpose — the panel and the clear dialog both have to say it, and a reader who only sees one of them must still be told.

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:353 (also :89 and lib/obd/polling_engine.dart:3221 'This scan did not read a freeze frame — that does not mean the vehicle has none.'). Explained at docs/field-guide.zh-TW.md:226-228. Distinguishes a READ FAILURE from an ABSENT freeze frame; the field guide tells users to rescan rather than clear, because clearing destroys an unread frame permanently. Collapsing this into 'no freeze frame' causes irreversible evidence loss. The engine sentence is transcript-only English; the screen still ships the Traditional Chinese ARB hedge.

### 12. 這個控制器沒有儲存凍結幀 —— 故障碼可能是清除後重新出現的，或是由不記錄凍結幀的模組所報告。

**繁體中文** — 這個控制器沒有儲存凍結幀 —— 故障碼可能是清除後重新出現的，或是由不記錄凍結幀的模組所報告。

**English** — NO PROJECT ENGLISH — proposed: This controller has stored no freeze frame — the code may have reappeared after a clear, or been reported by a module that does not record freeze frames.

**Status** — proposed

**Why it is load-bearing.** lib/obd/freeze_frame.dart:125-126, which as of the
engine-layer l10n wave is an unused constant — no screen reads it, so this hedge is
currently a rule about a sentence the app does not ship. Wiring it up means giving it an
ARB entry first. The complement of the previous hedge: a CONFIRMED absence, with its two innocent explanations. The two strings must stay distinguishable in translation (docs/field-guide.zh-TW.md:223-228 teaches users to tell them apart).

### 13. 已回應的控制器都沒有故障碼。

**繁體中文** — 已回應的控制器都沒有故障碼。

**English** — None of the controllers that answered reported a fault code.

**Shipped as** `dtcCompleteCleanTitle` (lib/l10n/app_en.arb).

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:408. Glossed at docs/field-guide.zh-TW.md:206: '有回覆的模組都說沒事。**不代表車上每個模組都被問到了。**' The qualifier 已回應的/'that answered' is the whole hedge — it must never be rendered as 'no fault codes' or 'your car is fine'. Compare lib/state/dtc_scan.dart:593 '可能有控制器不在這次查詢的範圍內。請以車輛儀表為準，並洽維修廠。'

### 14. 部分未確認 / 無法確認

**繁體中文** — 部分未確認

**English** — Partially unconfirmed

**Shipped as** `dtcVerdictPartialClean` (lib/l10n/app_en.arb).

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:173 (ScanVerdict.partialClean => '部分未確認'). docs/field-guide.zh-TW.md:207-208 defines them: 部分未確認 = 'some categories could not be read, the verdict is incomplete'; 無法確認 = '**do not read this as "no problem"**'. These are verdict states, not prose — keep them short, distinct, and never merge into a single 'unknown'.

### 15. 請先重新掃描

**繁體中文** — 請先重新掃描

**English** — Rescan first

**Shipped as** `dtcRescanFirst` (lib/l10n/app_en.arb). An imperative on a disabled button, not the sentence that explains it — a matcher that went by wording alone paired this with the freeze-frame paragraph, which says something else entirely.

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:202 (the disabled clear-button label), :354, lib/state/dtc_scan.dart:336. docs/field-guide.zh-TW.md:275-278: the button IS the verdict of the last clear. Greyed + '請先重新掃描' means something may already have been cleared, so re-sending a global clear would reset a completed controller's readiness and cost the user another drive cycle. The imperative must stay an imperative.

### 16. 此車輛不支援這個 PID

**繁體中文** — 此車輛不支援這個 PID

**English** — This vehicle does not support this PID.

**Shipped as** `datumReasonPidUnsupported` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/status/datum_status_copy.dart:85` (`DatumReason.pidUnsupported`). This entry was written when the string lived on `lib/diagnostics/availability.dart:312` with no ARB key, and the note saying there was no project English outlived the wave that gave it one — an entry that says it is unguarded is read as harmlessly stale, which is why it stayed. Deliberately an assertion ABOUT THE CAR, which is why lib/obd/telemetry.dart:75,88 and lib/obd/polling_engine.dart:907,995,3801 all warn against reaching it on thin evidence — docs/protocol-deviations.zh-TW.md:117-119 records that ATAT2 would make one missed window read as 此車輛不支援 for the whole session. Must stay distinguishable from `datumReasonNoAnswer` (`datum_status_copy.dart:86`), which is temporary.

### 17. 另有 N 個項目在這份凍結幀裡，本 App 沒有對應的換算公式

**繁體中文** — 另有 N 個項目在這份凍結幀裡，本 App 沒有對應的換算公式

**English** — NO PROJECT ENGLISH — proposed: N further items in this freeze frame have no conversion formula in this app

**Status** — proposed

**Why it is load-bearing.** lib/ui/screens/dtc/dtc_screen.dart:941. docs/field-guide.zh-TW.md:229-233 contrasts it with '有 N 個項目這次沒有讀回來' (dtc_screen.dart:955): the first is an APP limitation that rescanning will not change, the second is a READ FAILURE that rescanning usually fixes. '這兩句話意思不一樣：前者重掃也不會變，後者會。' Merging them destroys the user's next action.

### 18. 假設尚未確認，仍可估算

**繁體中文** — 假設尚未確認，仍可估算

**English** — The assumptions are unconfirmed; an estimate is still shown.

**Shipped as** `datumReasonAssumptionsUnconfirmed` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/status/datum_status_copy.dart:96`, written when the string lived on `lib/diagnostics/availability.dart:518` and had no English. The fail-closed derived-value label: raw PIDs stay visible but profile-derived horsepower/torque/fuel are marked as resting on unconfirmed inputs (README.md:76-79 ↔ README.zh-TW.md:66-68). Both halves are required — 尚未確認 alone reads as an error, 仍可估算 alone reads as a validated number.

### 19. 無法確認車輛已停止；請先中斷連線

**繁體中文** — 無法確認車輛已停止；請先中斷連線

**English** — Cannot confirm the vehicle is stopped — disconnect first

**Shipped as** `telemetryStartSpeedUnknown` (lib/l10n/app_en.arb).

**Why it is load-bearing.** lib/state/telemetry_sessions.dart:44 (TelemetryHistoryAccess.speedUnknown). A refusal gate, not a warning: unknown speed is treated as moving. Compare lib/state/app_share_coordinator.dart:160 ShareError.policyDenied => '目前的連線或行車狀態不允許匯出。' Translations must keep this as a refusal with a remedy, never as advice.

### 20. 目前無法完成啟動檢查 / 需要重新啟動才能安全繼續

**繁體中文** — 目前無法完成啟動檢查 / 需要重新啟動才能安全繼續

**English** — Cannot finish startup checks / Restart required to continue safely

**Why it is load-bearing.** lib/l10n/app_en.arb:16,21 ↔ lib/l10n/app_zh_Hant.arb:13,15 (T1). app_en.arb:18 description: 'Retryable startup failure title. Distinct from startupChecking (in-progress) and startupRestartRequired (must quit).' lib/l10n/startup_copy.dart:5-6: 'Loading, retryable failure, and restart-required are three states. They must not share copy.' Three states, three strings — a translator who merges any two breaks a documented invariant.

### 21. 本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。

**繁體中文** — 本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。

**English** — Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.

**Shipped as** `startupRestartHint` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/app.dart:267`; lib/l10n/app_en.arb:1959 ↔ lib/l10n/app_zh_Hant.arb:563 (T1). States the consequence (wrong file overwritten/deleted/SHARED) as the reason for the demand. The three-verb enumeration is the hedge — 'so nothing goes wrong' would delete the privacy half.

### 22. 無法儲存語言設定，請再試一次。

**繁體中文** — 無法儲存語言設定，請再試一次。

**English** — Could not save the language. Try again.

**Shipped as** `languageSaveFailed` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/language_picker.dart:70`; lib/l10n/app_en.arb:892 ↔ lib/l10n/app_zh_Hant.arb:249 (T1). The picker never silently claims success; a failed write is surfaced. Keep it a failure statement plus a remedy.

### 23. 不確定要選哪一個？

**繁體中文** — 不確定要選哪一個？

**English** — Not sure which to pick?

**Shipped as** `connectWhichTitle` (lib/l10n/app_en.arb).

**Why it is load-bearing.** lib/ui/screens/connect/connect_screen.dart:1796; the body at :1808 says '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：' and the questions come from whichTransportGuidance() (:1814-1817). docs/field-guide.zh-TW.md:63-65: it asks three OBSERVABLE questions rather than requiring the user to know SPP/GATT. The uncertainty is the user's, and the copy is designed to accept it — a confident 'Choose your connection type' would defeat the purpose.

### 24. 猜錯不會怎麼樣 —— 連不上就退回來換另一個試。

**繁體中文** — 猜錯不會怎麼樣 —— 連不上就退回來換另一個試。真的卡住，先用最下面的「Demo 模擬器」確認 App 本身正常。

**English** — Guessing wrong costs nothing — if it will not connect, come back and try another. If you are really stuck, use the Demo simulator at the bottom to confirm the app itself is working.

**Shipped as** `connectWhichNoteGuessing` (lib/l10n/app_en.arb).

**Why it is load-bearing.** lib/ui/screens/connect/connect_screen.dart:1830 (inside the 「不確定要選哪一個？」 disclosure). The in-code comment at :1826-1829 states the intent: 'the fear of picking wrong is what makes somebody close the app instead of tapping something. Nothing here is destructive and nothing is remembered until a handshake succeeds.' This is a permission-to-fail hedge; flattening it to 'Select a connection type' removes the reassurance it exists to give.

### 25. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet.

**Shipped as** `datumReasonNoReadingYet` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/status/datum_status_copy.dart:90`, the null `PidFault` arm, formerly `lib/diagnostics/availability.dart:318`. 'Not yet read' — explicitly NOT 'zero' and NOT 'unsupported'. This is the app's baseline refusal to print a number it does not have; rendering it as '0' or '--' without the words reintroduces exactly the failure the tagline forbids.

### 26. 未知監控項目

**繁體中文** — 未知監控項目

**English** — Unknown monitor

**Shipped as** `dtcUnknownMonitor` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/dtc/dtc_screen.dart:1161` and `:1169`, the readiness chip label. Explained at docs/field-guide.zh-TW.md:243-245: the vehicle reported a readiness monitor this app has no name for, and '它照樣會算進「還有 N 項沒有完成」—— 叫不出名字不等於可以當作已完成。' The hedge is that an UNNAMED monitor is still counted as INCOMPLETE; a translation that renders it 'N/A' or 'other' invites the reader to discount it.

### 27. 永久故障碼（Mode 0A）無法清除。

**繁體中文** — 永久故障碼（Mode 0A）無法清除。車輛需要重新完成一輪自我診斷才能通過驗車。

**English** — Permanent codes (Mode 0A) cannot be cleared. The vehicle has to complete a
fresh round of self-diagnosis before it will pass an inspection.

**Status** — proposed

**Why it is load-bearing.** `dtcKindPermanentExplanation`
(`lib/l10n/app_en.arb:2180` ↔ `lib/l10n/app_zh_Hant.arb:638`) defines the category as
「無法用診斷儀清除，需修復後由 ECU 自行確認」— it lived on `DtcKind` in
`lib/obd/dtc/dtc.dart` until the engine stopped carrying screen copy — and
`dtcClearDialogBody` repeats it beside the Clear button. Issue #45 names this specific mistranslation: a
permanent code must never read as something Clear can remove. Somebody who believes it can
will press Clear, watch the stored and pending codes disappear, conclude the car is fixed,
and take it for an inspection it cannot pass — having also destroyed the freeze frame that
would have explained the fault. The whole point of the word is that this one does not go
away because you asked it to. **proposed** — the English above has not been confirmed by a
maintainer.

### 28. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `dtcMilOff` (lib/l10n/app_en.arb). Its opposite is entry 42.

**Why it is load-bearing.** `lib/ui/screens/dtc/dtc_screen.dart:1072` picks between the two with `summary.milOn ? … : …`, so the pair is one binary readout of a physical lamp. A reviewer inverted `dtcMilOff` to 'The fault lamp is lit' and the whole suite stayed green: both branches would have said the same thing, and a driver reading the screen instead of the dashboard would be told a warning lamp is on when it is not — or worse, off when it is. The negation is the entire content of this string.

### 29. 可看 raw / error，不可當成正常數值

**繁體中文** — 可看 raw / error，不可當成正常數值

**English** — The raw reply and the error can be inspected; neither may be read as a normal value.

**Shipped as** `datumNextStepRawOnly` (lib/l10n/app_en.arb).

**Why it is load-bearing.** This is entry 1's rule rendered into UI: it is the sentence that stands between a malformed packet and a reader treating its bytes as a sensor value. Dropping the 不可/'neither may' turns an explicit prohibition into an invitation. A reviewer inverted it to '…either may be read as a normal value' and nothing failed.

### 30. 我知道來源資料與合成測試不能證明我的實車適用

**繁體中文** — 我知道來源資料與合成測試不能證明我的實車適用

**English** — I understand that the source data and the synthetic tests do not prove this applies to my own vehicle

**Shipped as** `settingsBatteryLabEvidenceAck` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/settings/settings_screen.dart:218` — one of the two checkboxes gating the battery laboratory, which sends manufacturer-specific commands to a high-voltage battery controller. Its sibling `settingsBatteryLabWireAck` is guarded; this one was not, and inverting it to 'I confirm … prove' left the suite green. A consent checkbox that states the opposite of what the user is consenting to is not a weaker consent, it is a false record of one.

### 31. 進氣量無法取得

**繁體中文** — 進氣量無法取得

**English** — Air mass unavailable

**Shipped as** `derivedAirflowSourceUnavailable` (lib/l10n/app_en.arb). Entry 43 is the fuel half, for the same reason.

**Why it is load-bearing.** `lib/obd/physics/physics_engine.dart:26-27`: 'Neither was available. Not the same as zero air flow, which would mean a stopped engine.' A reviewer changed this to 'No air flow' and the whole suite — including the guard file written for these very keys — stayed green. Rendered beside a rev counter reading 3000 rpm, 'No air flow' is the text form of the defect `derived_provenance_test.dart:152-162` already exists to prevent: a confident statement that the engine is not breathing, from a car that is. The word must say *unavailable*, and the string must not be readable as a measurement. `engine_vocabulary_copy_test.dart` now checks both positively.

### 32. 品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。

**繁體中文** — 品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。

**English** — A brand name or a VIN alone does not establish mass, drag, VE or transmission efficiency.

**Shipped as** `settingsProfileNameProvesNothing` (lib/l10n/app_en.arb).

**Why it is load-bearing.** It is the sentence that stops a matched VIN from being read as a verified vehicle profile. Every power and fuel estimate rests on those four parameters, and the details dialog labels each one with an origin precisely because a name is not a measurement. Softening 不能證明 to 'may not fully describe' would leave the reader believing the numbers were looked up.

### 33. 壞封包，只可查看原文

**繁體中文** — 壞封包，只可查看原文

**English** — Malformed packet; only the raw reply can be inspected.

**Shipped as** `datumReasonMalformedPacket` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `docs/protocol-deviations.zh-TW.md` records what happens when a malformed reply is salvaged instead of refused: `DATA ERROR` becomes the two bytes `DA AE` and is read as a sensor value. The 只可/'only' is the restriction; without it the sentence describes a packet rather than forbidding a use of it.

### 34. 紀錄損壞，無法安全讀取

**繁體中文** — 紀錄損壞，無法安全讀取

**English** — The recording is damaged and cannot be read safely

**Shipped as** `telemetryDamagedCorrupt` (lib/l10n/app_en.arb).

**Why it is load-bearing.** A damaged telemetry file is evidence somebody may act on. 無法安全讀取/'cannot be read safely' refuses it outright; 'may be incomplete' would invite a reader to use the parts that survived, which is the same error as splicing a multi-frame response.

### 35. 藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。

**繁體中文** — 藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。

**English** — Bluetooth permission is permanently denied. The system will not ask again, so turn it on in app settings.

**Shipped as** `connectBlePermissionDeniedForever` (lib/l10n/app_en.arb).

**Why it is load-bearing.** The load-bearing half is 系統不會再顯示授權對話框/'will not ask again'. Without it a reader taps Connect repeatedly and concludes the adapter is broken, when the fix is two taps away in Settings. It is a hedge about the *platform's* behaviour rather than the vehicle's, and it is the only thing that turns a dead end into an instruction.

### 36. 可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。

**繁體中文** — 可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。

**English** — The vehicle may not offer one, the reply may have been incomplete, or it was not read on this connection; nothing is guessed and no characters are filled in.

**Shipped as** `settingsVinUnavailableDetail` (lib/l10n/app_en.arb).

**Why it is load-bearing.** 不會猜測或補字/'nothing is guessed and no characters are filled in' is a promise about the parser, and `vin_contract_test.dart` enforces it: a truncated reply is rejected rather than padded out, and letters a VIN may not contain are rejected rather than filtered. A VIN identifies a vehicle to a mechanic and to a registry. The sentence must keep both halves — the three reasons it may be missing, and the refusal to invent one.

### 37. 本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。

**繁體中文** — 本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。

**English** — Not confirmed on this connection. Measured OBD readings are still shown, but values estimated from mass, VE and drag are not.

**Shipped as** `settingsProfileUnconfirmedConnectedDetail` (lib/l10n/app_en.arb).

**Why it is load-bearing.** It draws the app's central line in one sentence: measured readings survive an unconfirmed profile, estimates do not. Softening 但不顯示/'but … are not' into 'may be less accurate' would restore exactly the behaviour this refuses — a plausible power figure computed from a mass nobody checked.

### 38. 只會套用：{fields}。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。

**繁體中文** — 只會套用：{fields}。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。

**English** — Only {fields} will be applied. Mass, VE, Cd, frontal area, Crr and transmission efficiency stay unresolved.

**Shipped as** `settingsEpaWillApplyOnly` (lib/l10n/app_en.arb).

**Why it is load-bearing.** Shown when a catalog match is about to be applied. The enumeration of what stays unresolved is the whole content: a reader who sees "matched from the official catalog" and not this list will believe the power estimate now rests on their car. Five of the six named parameters are the ones the horsepower formula uses.

### 39. 單次查詢沒有完成；沒有發布或保留數值。

**繁體中文** — 單次查詢沒有完成；沒有發布或保留數值。

**English** — The one-shot query did not finish; no value was published or kept.

**Shipped as** `powertrainProbeDidNotFinish` (lib/l10n/app_en.arb).

**Why it is load-bearing.** A battery-controller probe that did not finish must not leave a number on screen or in a recording. The second clause is a statement about what the app did with the partial data, not a description of the failure, and dropping it lets a reader assume a value shown elsewhere came from this probe.

### 40. PID 設定無法安全紀錄，請檢查定義

**繁體中文** — PID 設定無法安全紀錄，請檢查定義

**English** — This PID selection cannot be recorded safely — check the definitions

**Shipped as** `telemetryStartInvalidConfiguration` (lib/l10n/app_en.arb).

**Why it is load-bearing.** 無法安全紀錄/'cannot be recorded safely' refuses the recording outright. A recording made from definitions the app could not validate produces an evidence file whose numbers nobody can account for, which is worse than no recording — the file outlives the session that would have explained it.

### 41. 實驗 · 未驗證

**繁體中文** — 實驗 · 未驗證

**English** — Experimental · unverified

**Shipped as** `powertrainStatusExperimental` (lib/l10n/app_en.arb). Entry 44 sits beside it on the same screen.

**Why it is load-bearing.** Two words, both of them the point, on a screen that sends manufacturer-specific commands to a high-voltage battery controller. 未驗證/'unverified' is the same hedge as `DatumBadge.unverified` and must not be smoothed into 'beta' or 'preview', neither of which says that nobody has checked the results against a real vehicle.

### 42. 故障燈已亮

**繁體中文** — 故障燈亮著

**English** — The fault lamp is lit

**Shipped as** `dtcMilOn` (lib/l10n/app_en.arb).

**Why it is load-bearing.** The other half of entry 28's binary. It was written into that entry's `Shipped as` line as prose, which read as though it were guarded and was not — a reviewer hollowed it out to 'Warning lamp active', chosen to stay distinct from its partner so the must-differ pair test did not fire either, and the whole suite stayed green. Each key now carries its own English, because an entry holding two shipped sentences under one `**English**` line can only ever check one of them.

### 43. 油耗無法取得

**繁體中文** — 油耗無法取得

**English** — Fuel rate unavailable

**Shipped as** `derivedFuelSourceUnavailable` (lib/l10n/app_en.arb).

**Why it is load-bearing.** Entry 31's reasoning applies unchanged: an absence rendered as a number is the failure this app exists to prevent, and 'Fuel rate unavailable' is not 'no fuel used'. It was the second key on entry 31's `Shipped as` line and therefore invisible to the guard — one of the two keys this whole review round was about.

### 44. 此版本不可安裝

**繁體中文** — 此版本不可安裝

**English** — Not installable in this release

**Shipped as** `powertrainNotInstallableInThisRelease` (lib/l10n/app_en.arb).

**Why it is load-bearing.** A refusal, not a status. Inverted to 'Installable in this release' the suite stayed green, and a reader would be told they can install a manufacturer-specific profile onto a high-voltage battery controller that this build will not install.

### 45. 這次沒有讀到凍結幀 —— 不代表車上沒有。（面板全文）

**繁體中文** — 這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。

**English** — This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear the fault codes, because clearing destroys the record of the moment of the fault permanently. If every scan looks the same, this vehicle may not provide one.

**Shipped as** `dtcFreezeFrameUnreadPanel` (lib/l10n/app_en.arb). Entry 11 is the shorter form the clear dialog uses.

**Why it is load-bearing.** Entry 11's reasoning, plus two clauses the dialog has no room for: that clearing destroys the record permanently, and that a vehicle which never produces a frame is a possibility rather than a fault. It shared entry 11's `**English**` line as a clause, which meant the guard could only check that its first two sentences survived — a translation was free to append 'On most vehicles this is safe, so clearing now is fine', and a reviewer proved that passed everything. Recording the whole sentence is what makes the check a fence rather than a floor.

### 46. 預覽已抽樣；匯出保留完整已記錄事件

**繁體中文** — 預覽已抽樣；匯出保留完整已記錄事件

**English** — The preview is sampled; the export keeps every recorded event.

**Shipped as** `telemetryReplaySampled` (lib/l10n/app_en.arb).

**Why it is load-bearing.** The only sentence telling a reader that the chart in front of them is not the whole recording. A structural test guarded it first — preview before export, 'sampled' between them — and a reviewer defeated it with one word: 「預覽**未**抽樣」 and 'the preview is **not** sampled' leave all three positions unchanged. Recording the sentence verbatim here is what makes any edit, in any direction, fail.

### 47. 匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。

**繁體中文** — 匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。

**English** — The export contains signal names, values, observation and source times, transport kind, protocol, frozen PID labels, units and formulas, and the estimate assumptions (mass, drag, displacement, fuel and similar parameters). JSON may also contain your own custom labels, units, formulas and complete frozen definitions. The export does not contain the VIN, GPS, an account, the adapter address, the full vehicle profile, or raw diagnostic traffic.

**Shipped as** `telemetryExportDisclosure` (lib/l10n/app_en.arb).

**Why it is load-bearing.** Where the app says what leaves the device, and what the en-US listing's 'no ads, no tracking, no personal data collected' rests on. Both halves are load-bearing and neither may be qualified: a reviewer got 'It **usually** does not contain the VIN, GPS, an account or the adapter address' past a test that checked which side of the negation each token fell on. Qualification is what an otherwise reasonable translation introduces.

### 48. ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。

**繁體中文** — ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。

**English** — Elm Electronics never published this version, so the firmware on this adapter is not the one it claims. Many of these still work — but its description of itself cannot be trusted, and it is worth suspecting first when something will not read.

**Shipped as** `adapterConcernFirmwareNeverReleasedDetail` (lib/l10n/app_en.arb).

**Why it is load-bearing.** A very large share of *working* adapters report v1.5, so this must read as a statement of fact and not a verdict on the hardware. 「很多這種轉接器仍然可用」 / 'Many of these still work' is the half that keeps it honest, and 'its description of itself cannot be trusted' is the half that makes it useful. Dropping either turns a caution into either an accusation or nothing.

### 49. 這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。

**繁體中文** — 這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。

**English** — This command has existed since ELM327 v1.0. Not answering it means this chip implements a smaller command set than any official firmware.

**Shipped as** `adapterConcernNoIdentityDetail` (lib/l10n/app_en.arb).

**Why it is load-bearing.** This one is a verdict, and it is allowed to be one only because `IdentityProbe.refused` now gates it — a refusal is the device speaking about itself, where an absence was the link speaking about the moment. If the trigger is ever loosened back to an absence, this wording becomes a clone accusation assembled out of a dropped packet, so the two have to move together.

### 50. 已確認本次連線的設定。修改任一項或重新連線後都要再確認。

**繁體中文** — 已確認本次連線的設定。修改任一項或重新連線後都要再確認。

**English** — The profile is confirmed for this connection. Changing any value, or reconnecting, means confirming again.

**Shipped as** `settingsProfileConfirmedDetail` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/settings/settings_screen.dart:1238`, under the vehicle-profile confirmation. The scope is the hedge: the confirmation covers one connection, and two ordinary actions void it. Everything the app derives from these parameters — horsepower, torque, fuel use — is gated on their being confirmed for *this* vehicle on *this* connection, so a translation that renders it as 'the profile is confirmed' turns an expiring acknowledgement into a permanent one and the next session's estimates rest on numbers nobody looked at. Both voiding conditions must survive; 重新連線 / 'or reconnecting' is the easier half to lose and the one that matters when the adapter is moved to another car.

### 51. 馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。

**繁體中文** — 馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。

**English** — Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.

**Shipped as** `settingsProfileEstimatesIntro` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/settings/settings_screen.dart:388`, above the fields a user types their car into. Its own ARB description states the rule: 推算 / 'estimated' is load-bearing because these numbers are never measured. This is the only place that tells a reader the power figure on the dial is arithmetic over what they typed rather than something the vehicle reported. 'Calculated from' and 'based on' both read as derivation from measurement. The second clause, which puts the accuracy on the person filling the form, is what stops a careless entry producing a confident wrong number.

### 52. 請先連線；實驗授權不會跨連線保留。

**繁體中文** — 請先連線；實驗授權不會跨連線保留。

**English** — Connect first; experimental authorization is never kept across connections.

**Shipped as** `powertrainConnectFirst` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/pids/powertrain_battery_catalog_screen.dart:81`, shown when the battery catalogue is opened with nothing connected. Two statements, and the second is the hedge: consent to send manufacturer-specific commands to a high-voltage battery controller expires with the connection. Entry 6 records the same boundary for the Settings switch that reveals the laboratory. A translation that keeps only the imperative — 'Connect first' — leaves a user believing an authorisation granted once is still in force, which is the opposite of what the code does.

### 53. 完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。

**繁體中文** — 完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。

**English** — Integrity verification did not pass, so no vehicle data is shown or installed.

**Shipped as** `powertrainCatalogLoadFailedBody` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/pids/powertrain_battery_catalog_screen.dart:572`. Its ARB description states the rule: fail-closed, say what did NOT happen, never soften to 'try again later'. The sentence names the cause and then the consequence, and the consequence is the half a reader needs — nothing shown and nothing installed, so there is no partly-loaded catalogue to wonder about. 'Could not load the catalogue' says the same thing about the app and nothing about the state of the device.

### 54. 車輛電池訊號待確認

**繁體中文** — 車輛電池訊號待確認

**English** — Vehicle battery signals await confirmation

**Shipped as** `powertrainConfirmTitle` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/powertrain_profile_confirm_banner.dart:68`, the banner that sits above decoded high-voltage battery values. 待確認 / 'await confirmation' is a status about the signals, not an instruction to the reader: it says the decode is unconfirmed while the numbers are already on screen. Rendered as 'Confirm vehicle battery signals' it becomes a task, and a banner read as a to-do is one somebody clears without changing anything it was warning about.

### 55. 標頭不符本車匯流排

**繁體中文** — 標頭不符本車匯流排

**English** — The header does not match the bus this vehicle uses.

**Shipped as** `datumReasonHeaderNotOnThisBus` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/status/datum_status_copy.dart:89` (`DatumReason.headerNotOnThisBus`). Its ARB description says why it is kept apart from entry 16: this one is a statement about the PID DEFINITION, which the user can edit, and that one is a statement about the car, which they cannot. Merging them sends somebody looking at their vehicle for a problem that is in a field on their own screen. The subject of the sentence — the header, not the vehicle — is the entire content.

### 56. 非有限數值

**繁體中文** — 非有限數值

**English** — Not a finite number.

**Shipped as** `datumReasonNonFiniteValue` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/status/datum_status_copy.dart:80` (`DatumReason.nonFiniteValue`). The formula produced a NaN or an infinity, so there is no value, and this sentence stands where the value would have been. It is entry 1 in its narrowest form: a NaN rendered as 0, as '--', or as the last good reading is exactly a plausible wrong number. Softened to 'value unavailable' it loses the fact that an answer arrived and was rejected — which is what tells a reader to look at the PID definition rather than at the connection.

### 57. 直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。

**繁體中文** — 直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。

**English** — Send one command straight to the adapter — for example ATI, ATDPN, 0100. It joins the same queue as normal polling and does not jump ahead.

**Shipped as** `settingsManualCommandBody` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/settings/settings_screen.dart:611`, under the manual-command box. Two rules in one sentence. ATI, ATDPN and 0100 are wire commands and stay byte-identical in every language — its ARB description says so, and a translated or full-width form would be sent and refused. The queueing clause is the hedge: a user who believes a manual command pre-empts polling will read whatever the adapter says next as the answer to it, and attribute a reply belonging to a queued PID to the command just typed. 不會插隊 / 'does not jump ahead' is what prevents that.

### 58. 最多選擇 {limit} 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。

**繁體中文** — 最多選擇 {limit} 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。

**English** — Choose at most {limit}. This only changes the chart, not PID polling or a recording in progress.

**Shipped as** `trendSheetBody` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/widgets/telemetry/telemetry_lane_selector.dart:193`. It separates a view change from a data change, and both halves of that separation carry weight. A reader who takes lane selection for polling will believe deselecting a signal stopped it being read; one who takes it for recording will believe an export covers only the lanes left on. Both beliefs are wrong in the direction that matters — the recording is more complete than they think and the chart is less — and either produces confident conclusions from a file they have misread. `{limit}` is a placeholder and has to survive as one.

### 59. 清除故障碼？

**繁體中文** — 清除故障碼？

**English** — Clear fault codes?

**Shipped as** `dtcClearDialogTitle` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/dtc/dtc_screen.dart:117`, the title of the dialog entries 11 and 27 are both about. It must not gain scope: 'Clear all fault codes?' or 「清除所有故障碼？」 over-claims, because permanent codes (Mode 0A) are not cleared and `dtcClearDialogBody` says so a few lines below — a title is read first and remembered, and one that promises what the body withdraws is where entry 27's mistranslation gets its start. It must stay a question, and it must name what is destroyed: 'Clear?' or 'Reset' leaves the reader to guess whether the thing at the point of no return is the codes, the readiness monitors, or the recording.

### 60. KWP，5-baud 與 fast 無法分辨

**繁體中文** — KWP，5-baud 與 fast 無法分辨

**English** — KWP, 5-baud vs fast not distinguished

**Shipped as** `connectionLayerKwpSubtypeUnknown` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/connect/connection_layer_copy.dart:23`, the Connect protocol row when `ATDP` names ISO 14230-4 / KWP and `ATDPN` is not 4 or 5. The datasheet sentence can print KWP FAST; that is still not protocol 5. Softened to 'KWP' or 'ISO 14230-4' it looks like the init is known. 5-baud and fast stay those words in every language.

### 61. BARO() 是 Android 氣壓計／ECU 大氣壓（psi），這個方言沒有實作。要用快取的大氣壓力請寫不帶括號的 BARO。

**繁體中文** — BARO() 是 Android 氣壓計／ECU 大氣壓（psi），這個方言沒有實作。要用快取的大氣壓力請寫不帶括號的 BARO。

**English** — BARO() is the Android barometer / ECU baro in psi, which this dialect does not implement. Use BARO without parentheses for cached ambient pressure.

**Shipped as** `pidFormulaBaroParenFormUnsupported` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/pids/pid_formula_copy.dart:67`, the PID editor sentence when a formula writes `BARO()`. Softened to 'BARO is not supported' it hides that `A-BARO` still evaluates, and that the wiki form is psi not kPa. BARO(), BARO and psi stay those tokens in every language.

### 62. INT16 尚未被這個方言認領：wiki 寫可代替 (A*255)+B，那不是 (A*256)+B。請把其中一個等式直接寫進公式。

**繁體中文** — INT16 尚未被這個方言認領：wiki 寫可代替 (A*255)+B，那不是 (A*256)+B。請把其中一個等式直接寫進公式。

**English** — INT16 is unclaimed: the wiki says it can replace (A*255)+B, which is not (A*256)+B. Write one of those identities explicitly.

**Shipped as** `pidFormulaInt16Unclaimed` (lib/l10n/app_en.arb).

**Why it is load-bearing.** `lib/ui/screens/pids/pid_formula_copy.dart:69`, the PID editor sentence when a formula writes `INT16(A:B)`. Softened to 'INT16 is not supported' it hides that (A*255)+B and (A*256)+B are different numbers. INT16, (A*255)+B and (A*256)+B stay those tokens in every language. Not evaluated as either.
