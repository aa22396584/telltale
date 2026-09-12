# Architecture Decision: Active-Test Profile Schema, Codecs, and Capability Discovery

- **Parent**: #25
- **Issue**: #131 ([ACTIVE-01])
- **Namespace**: `lib/diagnostics/service_recipes/`, `assets/service_recipes/`, `test/diagnostics/service_recipes/`
- **Date**: 2026-09-12
- **Status**: Implemented / In Review (Software baseline: 0 live candidates qualified)

---

## 1. Context and Problem Statement

Community feedback requested active/bidirectional diagnostic capabilities (Mode 08 on-board system control and UDS IO/routine control). However, bidirectional actuation presents significant vehicle safety, legal, and operational risks:
1. Actuation must never occur through arbitrary raw commands, unchecked scripts, or unreviewed downloads.
2. Capability discovery must never send actuation requests to probe whether an ECU supports a routine.
3. Silence or `NO DATA` must never be conflated with "unsupported" or "safe to probe".
4. A positive acknowledgment (`SID + 0x40`) does not prove execution, completion, or safe return of control to the ECU.
5. Generic vehicle profiles must never be invented from unreviewed sources or read PIDs.

---

## 2. Normative Protocol References

1. **SAE J1979:2014-08 / ISO 15031-5:2015 (OBD-II Service $08)**:
   - *Title*: "Request control of on-board system, test or component".
   - *Normative Clauses*: SAE J1979:2014-08 Section 8.8, ISO 15031-5:2015 Clause 8.8.
   - *Message Structure*: SAE J1979 Table 16 (Request format `08 <TID> [data...]`, Positive response `48 <TID> [data...]`).
   - *Supported TID Query & Bitmask*: SAE J1979 Table 17. Base TIDs `0x00`, `0x20`, `0x40`, `0x60`, `0x80`, `0xA0`, `0xC0`, `0xE0`. Positive response contains SID `0x48`, echoed base TID, followed by exactly 4 data bytes (32-bit big-endian bitmask).
   - *Discovery Safety Gate*: Mode 08 capability discovery emits ONLY standard base TID queries. Probing runnable TIDs (e.g. TID 01) to discover support is strictly prohibited and rejected fail-closed with `ProhibitedActiveProbeException`.
   - *Negative Responses*: Format `7F 08 <NRC>`. NRC `0x11` (serviceNotSupported), `0x12` (subFunctionNotSupported), and `0x31` (requestOutOfRange) confirm unsupported status. NRC `0x22` (conditionsNotCorrect), `0x21` (busyRepeatRequest), `0x33` (securityAccessDenied), and `0x78` (responsePending) must fallback to `unknown` support because the function may exist on the ECU. Non-standard or reserved NRCs (e.g. `0x00`, `0x05`) fail closed as malformed.

2. **ISO 14229-1:2013 / ISO 14229-1:2020 (UDS Service $2F - InputOutputControlByIdentifier)**:
   - *Normative Clauses*: Section 12.2 (InputOutputControlByIdentifier service).
   - *Request Message Flow*: Table 372 (Request `0x2F`, 2-byte DID, 1-byte InputOutputControlParameter, optional controlState, optional controlMask).
   - *Parameter Definitions*: Table 373:
     - `0x00`: `returnControlToECU` (releases external override).
     - `0x01`: `resetToDefault` (resets system to default calibrate).
     - `0x02`: `freezeCurrentState` (freezes output at current value).
     - `0x03`: `shortTermAdjustment` (temporarily overrides output with requested parameter value).
   - *Positive Response*: Table 374 (SID `0x6F`, echoed 16-bit DID, echoed 1-byte controlParameter, optional controlStatusRecord).
   - *Negative Response*: Table 375 (`7F 2F <NRC>`). Valid UDS NRCs include `0x13`, `0x22`, `0x31`, `0x33`, `0x78`. Generic `SID + 0x40` rule is rejected; responses must strictly echo DID and control parameter.

3. **ISO 14229-1:2013 / ISO 14229-1:2020 (UDS Service $31 - RoutineControl)**:
   - *Normative Clauses*: Section 13.2 (RoutineControl service).
   - *Request Message Flow*: Table 387 (Request `0x31`, 1-byte routineControlType, 2-byte routineIdentifier, optional routineControlOptionRecord).
   - *Subfunction Definitions*: Table 388:
     - `0x01`: `startRoutine`
     - `0x02`: `stopRoutine`
     - `0x03`: `requestRoutineResults`
   - *Positive Response*: Table 389 (SID `0x71`, echoed 1-byte routineControlType, echoed 16-bit routineIdentifier, optional routineStatusRecord).
   - *Negative Response*: Table 390 (`7F 31 <NRC>`). Valid UDS NRCs include `0x12`, `0x13`, `0x22`, `0x24`, `0x31`, `0x33`, `0x72`, `0x78`.

4. **ISO 14229-1:2013 / 2020 Annex A (Negative Response Codes)**:
   - *NRC 0x78 (requestCorrectlyReceived-ResponsePending)*: Signals request acceptance and active processing. The client MUST wait without retransmitting the trigger command within P2* timeout.
   - *NRC 0x22 (conditionsNotCorrect)*: Environmental precondition failed.
   - *NRC 0x31 (requestOutOfRange)*: DID/RID or parameter not supported.
   - *Reserved NRCs*: Byte values not defined in Table A.1 (e.g. `0x00`, `0x05`, `0xFF`) are rejected fail-closed as malformed responses.

---

## 3. Architecture and Safeguards

### A. Immutable, Declarative Profile Schema
- Descriptors: Typed `Mode08Descriptor`, `UdsIoControlDescriptor`, and `UdsRoutineDescriptor`.
- Metadata: Immutable profile ID, schema version, normative standard reference, source URL, redistribution rights, exact ECU/software applicability, physical addressing, session requirements, measurable preconditions, execution constraints, recovery specifications, and canonical SHA-256 hash.
- Collections: All list and set members across profiles, descriptors, and applicability records are strictly immutable (`List.unmodifiable` / `Set.unmodifiable`). Deep copies and defensive snapshots prevent execution-time reference drift or external mutation.
- Fail-Closed Validation (`ProfileValidationReason`):
  - Rejects missing source URL or unreviewed redistribution rights.
  - Rejects unknown schema versions.
  - Rejects wildcard ECU matches (`*`, `ALL`, `ANY`) and wildcard addressing (`*`, `7DF`, broadcast).
  - Rejects identical arbitration ID conflict between target request and expected response (`7E0` vs `07E0`).
  - Rejects out-of-range parameters and unbounded steps.
  - Rejects undocumented recovery (missing release command or loss-of-client watchdog).
  - Rejects hash tampering.

### B. Separation of Qualification Tiers and Execution Scopes
The model strictly separates distinct qualification gates:
1. `ecuReportsSupport`: `supported` | `unsupported` | `unknown` (silence/timeout/no-data is `unknown`, never `unsupported`).
2. `definitionAvailable`: valid, reviewed, untampered profile loaded.
3. `benchQualified`: physically verified on test bench hardware.
4. `vehicleQualified`: physically verified on target production vehicle.
5. `targetScope`: `bench` vs `vehicle`.
   - Bench qualification NEVER grants permission to execute on a live production vehicle (`blockedNotVehicleQualified`).
   - Vehicle execution strictly demands affirmative vehicle qualification.
6. `authorizationToken`: Opaque, cryptographically bound token verified for recipe hash, target CAN header, connection generation, and expiry before execution. Unverified strings alone are never trusted.

### C. Synthetic Fixture Isolation
- Synthetic fixtures (`assets/service_recipes/`) are strictly marked with `provenance_kind: syntheticFixture` and `evidence_tier: syntheticFixture`.
- The eligibility gate (`ActiveTestEligibilityGate`) **rejects** synthetic fixtures from live vehicle execution fail-closed, even if an ECU reports support or parameters match.

### D. Current Candidate Matrix Status
- `liveCandidateCount`: **0**
- `hasLiveCandidates`: **false**
- All 3 bundled fixtures (`synthetic_mode08_evap_fixture.json`, `synthetic_uds_2f_io_control_fixture.json`, `synthetic_uds_31_routine_fixture.json`) are categorized as `simulationReady`.
- No live vehicle profiles are claimed or enabled in this baseline.

---

## 4. Unchanged Boundaries and Regressions
1. Manual command console (`lib/state/manual_command_refusal.dart`): Mode 08, 0x2F, and 0x31 remain excluded from `kManualCommandReadOnlyServices` and continue to be refused.
2. Operation risk (`lib/diagnostics/availability.dart`): Mode 04 clear and bounded reads retain existing risk and consent gating.
3. PID/CSV imports, background polling, and external telemetry APIs remain strictly read-only.

---

## 5. Normative Literal Test Vectors (7 Groups)

The following literal vectors verify encoding, decoding, length contracts, and NRC classifications against the standards:

### Group 1: Mode 08 Supported TIDs Query & Bitmask Response (SAE J1979 Section 8.8 / Table 17)
- **Request Command**: `08 00` (ASCII hex: `0800`). Non-actuating query for supported TIDs 0x01..0x20.
- **Positive Response 1A**: `48 00 80 00 00 00` (6 bytes).
  - *Decode*: SID `0x48`, base TID `0x00`, bitmask `0x80000000` (Bit 31 set).
  - *Result*: TID `0x01` is supported; `hasNextBlock: false`.
- **Positive Response 1B**: `48 00 80 00 00 01` (6 bytes).
  - *Decode*: SID `0x48`, base TID `0x00`, bitmask `0x80000001` (Bits 31 and 0 set).
  - *Result*: TID `0x01` and TID `0x20` supported; `hasNextBlock: true` (indicates block 0x20 is present).

### Group 2: Mode 08 Negative Response with NRC 0x22 conditionsNotCorrect (ISO 15031-5 Clause 8.8)
- **Request Command**: `08 01` (EVAP system test execution).
- **Raw Response**: `7F 08 22` (3 bytes).
  - *Decode*: SID `0x7F`, original SID `0x08`, NRC `0x22` (`conditionsNotCorrect`).
  - *Result*: `Mode08NegativeResponse(originalSid: 0x08, nrc: 0x22)`.
  - *Safety Contract*: Fallback to `EcuSupportStatus.unknown` (NOT `unsupported`), because environmental conditions (e.g. engine running, speed > 0) temporarily prevented execution, but the routine exists on the ECU.

### Group 3: Mode 08 Negative Response with NRC 0x12 subFunctionNotSupported (SAE J1979 Section 8.8)
- **Request Command**: `08 05`.
- **Raw Response**: `7F 08 12` (3 bytes).
  - *Decode*: SID `0x7F`, original SID `0x08`, NRC `0x12` (`subFunctionNotSupported`).
  - *Result*: `Mode08NegativeResponse(originalSid: 0x08, nrc: 0x12)`.
  - *Safety Contract*: Confirms `EcuSupportStatus.unsupported`.

### Group 4: Mode 08 Malformed Non-standard / Reserved NRC (SAE J1979 Section 8.8)
- **Raw Responses**: `7F 08 00`, `7F 08 05`, `7F 08 FF`.
  - *Decode*: NRC `0x00` (positive response in negative envelope), `0x05` (reserved), or `0xFF` (reserved).
  - *Result*: `Mode08MalformedResponse(reason: Mode08MalformedReason.invalidNegativeResponse)`.
  - *Safety Contract*: Non-standard negative responses fail closed as malformed; never treated as valid negative response.

### Group 5: UDS Service 0x2F InputOutputControlByIdentifier (ISO 14229-1:2020 Section 12.2)
- **Request Command**: `2F 01 12 03 64 FF` (6 bytes).
  - *Encoding*: SID `0x2F`, DID `0x0112`, controlParameter `0x03` (`shortTermAdjustment`), controlState `[0x64]` (100% duty cycle), controlMask `[0xFF]`.
- **Positive Response**: `6F 01 12 03 64` (5 bytes).
  - *Decode*: SID `0x6F`, echoed DID `0x0112`, echoed controlParameter `0x03`, controlStatusRecord `[0x64]`.
  - *Safety Contract*: Response must strictly match expected DID and control parameter; wrong echo or wrong length fails closed as `UdsIoControlMalformed`.

### Group 6: UDS Service 0x31 RoutineControl startRoutine (ISO 14229-1:2020 Section 13.2)
- **Request Command**: `31 01 02 01 10` (5 bytes).
  - *Encoding*: SID `0x31`, routineControlType `0x01` (`startRoutine`), routineIdentifier `0x0201`, routineControlOptionRecord `[0x10]`.
- **Positive Response**: `71 01 02 01 00` (5 bytes).
  - *Decode*: SID `0x71`, echoed routineControlType `0x01`, echoed routineIdentifier `0x0201`, routineStatusRecord `[0x00]` (success status).
  - *Safety Contract*: Rejects generic `SID + 0x40` matching without exact subfunction and RID echo.

### Group 7: UDS NRC 0x78 responsePending Handling (ISO 14229-1:2020 Annex A Table A.1)
- **Raw Response**: `7F 31 78` (or `7F 2F 78`).
  - *Decode*: SID `0x7F`, original SID `0x31`, NRC `0x78` (`requestCorrectlyReceived-ResponsePending`).
  - *Result*: `UdsRoutineNegative(nrc: 0x78, isResponsePending: true)`.
  - *Safety Contract*: The client transitions to a waiting state within P2* timeout and does NOT abort, fail the test, or re-send the start actuation command.

