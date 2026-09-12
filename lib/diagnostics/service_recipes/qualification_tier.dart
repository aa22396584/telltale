/// Qualification tiers and fail-closed eligibility gate for active tests.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25.
///
/// Strict rules enforced:
/// 1. Separate:
///    - ECU reports support (supported, unsupported, unknown)
///    - definition available (valid reviewed profile loaded)
///    - bench qualified (physical bench verification)
///    - vehicle qualified (physical vehicle verification)
///    - eligible now (conjunction of all gates + live preconditions + explicit consent)
/// 2. Silence / NO DATA / Timeout is UNKNOWN, never unsupported.
/// 3. A supported ID NEVER grants execute permission on its own.
/// 4. Never infer active-test IDs from read PID definitions or model names.
/// 5. Synthetic/demo/replay provenance is strictly rejected from production eligibility.
library;

import 'active_test_profile.dart';

/// Support status reported by the vehicle/ECU.
enum EcuSupportStatus {
  /// ECU affirmatively reported that this ID/routine is supported.
  supported,

  /// ECU affirmatively reported that this ID/routine is NOT supported.
  unsupported,

  /// ECU timed out, returned NO DATA, BUS ERROR, or silence.
  ///
  /// CRITICAL: Silence or NO DATA is UNKNOWN, never unsupported.
  unknown,
}

/// Actionable verdict returned by the active-test eligibility gate.
enum ActiveTestEligibilityVerdict {
  /// All qualification, safety, and consent gates passed; eligible for execution.
  eligible,

  /// Blocked: No reviewed definition exists or schema validation failed.
  blockedNoDefinition,

  /// Blocked: Profile is a synthetic or demo fixture; strictly prohibited on live vehicle.
  blockedSyntheticFixture,

  /// Blocked: Profile has been revoked.
  blockedRevoked,

  /// Blocked: ECU affirmatively reported that this test is unsupported.
  blockedEcuNotSupported,

  /// Blocked: ECU support status is unknown (silence, NO DATA, or unprobed).
  blockedEcuSupportUnknown,

  /// Blocked: Profile has not been qualified on physical bench or vehicle.
  blockedNotBenchOrVehicleQualified,

  /// Blocked: Required live ECU preconditions are not met or stale.
  blockedPreconditionsNotMet,

  /// Blocked: Required operator one-time explicit consent is missing.
  blockedMissingConsent,

  /// Blocked: Required opaque authorization token is missing or invalid.
  blockedMissingAuthorizationToken,
}

/// Snapshot of the live qualification and support state for an active test.
final class ActiveTestSupportSnapshot {
  const ActiveTestSupportSnapshot({
    required this.profileId,
    required this.ecuSupport,
    required this.definitionAvailable,
    required this.benchQualified,
    required this.vehicleQualified,
    required this.provenanceKind,
    this.isRevoked = false,
  });

  final String profileId;
  final EcuSupportStatus ecuSupport;
  final bool definitionAvailable;
  final bool benchQualified;
  final bool vehicleQualified;
  final ProvenanceKind provenanceKind;
  final bool isRevoked;

  /// Whether this profile is qualified on either bench or vehicle.
  bool get isHardwareQualified => benchQualified || vehicleQualified;
}

/// Fail-closed eligibility gate evaluator.
final class ActiveTestEligibilityGate {
  const ActiveTestEligibilityGate._();

  /// Evaluates whether an active test profile is eligible to run right now.
  ///
  /// Evaluates in strict fail-closed order.
  static ActiveTestEligibilityVerdict evaluate({
    required ActiveTestProfile? profile,
    required EcuSupportStatus ecuSupport,
    required bool benchQualified,
    required bool vehicleQualified,
    required bool preconditionsSatisfied,
    required bool operatorConsentGranted,
    String? opaqueAuthorizationToken,
    bool requireOpaqueToken = false,
  }) {
    if (profile == null || !profile.isValid) {
      return ActiveTestEligibilityVerdict.blockedNoDefinition;
    }

    if (profile.isRevoked) {
      return ActiveTestEligibilityVerdict.blockedRevoked;
    }

    // Synthetic fixtures are strictly prohibited in production/live execution,
    // even if an ECU reports support or an ID matches!
    if (profile.provenanceKind == ProvenanceKind.syntheticFixture ||
        profile.redistributionRights == RedistributionRights.syntheticFixtureOnly ||
        profile.evidenceTier == EvidenceQualificationTier.syntheticFixture) {
      return ActiveTestEligibilityVerdict.blockedSyntheticFixture;
    }

    // ECU support check: affirmative support is required.
    switch (ecuSupport) {
      case EcuSupportStatus.unsupported:
        return ActiveTestEligibilityVerdict.blockedEcuNotSupported;
      case EcuSupportStatus.unknown:
        return ActiveTestEligibilityVerdict.blockedEcuSupportUnknown;
      case EcuSupportStatus.supported:
        break; // Continue to remaining gates.
    }

    // Hardware qualification gate: must have bench or vehicle qualification.
    if (!benchQualified && !vehicleQualified) {
      return ActiveTestEligibilityVerdict.blockedNotBenchOrVehicleQualified;
    }

    // Precondition gate: live ECU prerequisites must be met.
    if (!preconditionsSatisfied) {
      return ActiveTestEligibilityVerdict.blockedPreconditionsNotMet;
    }

    // Consent gate: explicit operator consent must be given.
    if (!operatorConsentGranted) {
      return ActiveTestEligibilityVerdict.blockedMissingConsent;
    }

    // Authorization token gate (F6 / #132): opaque token must be verified before execution.
    if (requireOpaqueToken &&
        (opaqueAuthorizationToken == null ||
            opaqueAuthorizationToken.trim().isEmpty)) {
      return ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken;
    }

    return ActiveTestEligibilityVerdict.eligible;
  }
}
