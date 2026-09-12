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

1. **SAE J1979 / ISO 15031-5 (OBD-II Service $08)**:
   - *Title*: "Request control of on-board system, test or component".
   - *Supported TID Query*: Standard base Test IDs (`0x00`, `0x20`, `0x40`, `0x60`, `0x80`, `0xA0`, `0xC0`, `0xE0`).
   - *Positive Response*: SID `0x48`, echoed base TID, followed by 4 bytes (32-bit bitmask).
   - *Discovery Rule*: Mode 08 capability discovery emits ONLY standard base TID queries. Probing runnable TIDs (e.g. TID 01) is strictly prohibited.
2. **ISO 14229-1 (UDS Service $2F - InputOutputControlByIdentifier)**:
   - *SIDs*: Request `0x2F`, Positive Response `0x6F`, Negative Response `0x7F 0x2F <NRC>`.
   - *Parameters*: 16-bit DID, 1-byte control parameter (`0x00` returnControlToECU, `0x01` resetToDefault, `0x02` freezeCurrentState, `0x03` shortTermAdjustment), optional control state and mask.
   - *Validation*: Response must strictly match expected DID and control parameter; generic `SID + 0x40` matching is rejected.
3. **ISO 14229-1 (UDS Service $31 - RoutineControl)**:
   - *SIDs*: Request `0x31`, Positive Response `0x71`, Negative Response `0x7F 0x31 <NRC>`.
   - *Subfunctions*: `0x01` startRoutine, `0x02` stopRoutine, `0x03` requestRoutineResults.
   - *Parameters*: 16-bit RID, optional option/status records.
   - *Validation*: Response must strictly match expected subfunction and RID.
4. **NRC 0x78 (responsePending)**:
   - Signals that the ECU has accepted the request and is processing it.
   - Requires the client to wait within bounded P2* deadlines without retransmitting the start request.

---

## 3. Architecture and Safeguards

### A. Immutable, Declarative Profile Schema
- Descriptors: Typed `Mode08Descriptor`, `UdsIoControlDescriptor`, and `UdsRoutineDescriptor`.
- Metadata: Immutable profile ID, schema version, normative standard reference, source URL, redistribution rights, exact ECU/software applicability, physical addressing, session requirements, measurable preconditions, execution constraints, recovery specifications, and canonical SHA-256 hash.
- Fail-Closed Validation (`ProfileValidationReason`):
  - Rejects missing source URL or unreviewed redistribution rights.
  - Rejects unknown schema versions.
  - Rejects wildcard ECU matches (`*`, `ALL`, `ANY`) and wildcard addressing (`*`, `7DF`, broadcast).
  - Rejects out-of-range parameters and unbounded steps.
  - Rejects undocumented recovery (missing release command or loss-of-client watchdog).
  - Rejects hash tampering.

### B. Separation of Qualification Tiers
The model strictly separates five distinct statuses:
1. `ecuReportsSupport`: `supported` | `unsupported` | `unknown` (silence/timeout/no-data is `unknown`, never `unsupported`).
2. `definitionAvailable`: valid, reviewed, untampered profile loaded.
3. `benchQualified`: physically verified on test bench hardware.
4. `vehicleQualified`: physically verified on target production vehicle.
5. `eligibleNow`: conjunction of all safety gates, affirmative ECU support, hardware qualification, fresh live ECU preconditions, and explicit operator consent.

A supported ID from an ECU **never** grants execute permission by itself.

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
