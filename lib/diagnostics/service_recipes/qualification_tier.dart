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

/// Target execution environment scope.
enum ExecutionTargetScope {
  /// Test bench or hardware-in-the-loop environment.
  bench,

  /// Production physical motor vehicle.
  vehicle,
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

  /// Blocked: Profile has not been qualified on physical bench.
  blockedNotBenchQualified,

  /// Blocked: Profile has not been qualified on target physical vehicle.
  blockedNotVehicleQualified,

  /// Blocked: Profile has not been qualified on bench or vehicle (legacy fallback).
  blockedNotBenchOrVehicleQualified,

  /// Blocked: Required live ECU preconditions are not met or stale.
  blockedPreconditionsNotMet,

  /// Blocked: Required operator one-time explicit consent is missing.
  blockedMissingConsent,

  /// Blocked: Required opaque authorization token is missing or invalid.
  blockedMissingAuthorizationToken,
}

/// Opaque authorization token strictly bound to an execution context (Issue #132).
final class ActiveTestAuthorizationToken {
  const ActiveTestAuthorizationToken({
    required this.tokenId,
    required this.recipeHash,
    required this.targetCanHeader,
    required this.connectionGeneration,
    required this.expiresAt,
    this.isUsed = false,
  });

  final String tokenId;
  final String recipeHash;
  final String targetCanHeader;
  final int connectionGeneration;
  final DateTime expiresAt;
  final bool isUsed;

  /// Verifies that this authorization token is valid and matches all active context bindings.
  bool isValidFor({
    required String expectedRecipeHash,
    required String expectedTargetCanHeader,
    required int currentConnectionGeneration,
    required DateTime now,
    BusAddressingType busType = BusAddressingType.can11Bit,
  }) {
    if (isUsed) return false;
    if (tokenId.trim().isEmpty) return false;
    if (now.isAfter(expiresAt)) return false;
    if (recipeHash.trim() != expectedRecipeHash.trim()) return false;
    if (!TransportAddressing.areHeadersEquivalent(
        targetCanHeader, expectedTargetCanHeader, busType)) {
      return false;
    }
    if (connectionGeneration != currentConnectionGeneration) return false;
    return true;
  }
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
    ExecutionTargetScope targetScope = ExecutionTargetScope.vehicle,
    ActiveTestAuthorizationToken? authorizationToken,
    bool requireAuthorizationToken = false,
    int? currentConnectionGeneration,
    DateTime? currentTime,
    @Deprecated('Use authorizationToken instead')
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

    // Hardware qualification gate: strictly separated by target environment scope.
    // Bench qualification NEVER grants execution on a live vehicle!
    switch (targetScope) {
      case ExecutionTargetScope.bench:
        if (!benchQualified) {
          return ActiveTestEligibilityVerdict.blockedNotBenchQualified;
        }
      case ExecutionTargetScope.vehicle:
        if (!benchQualified && !vehicleQualified) {
          return ActiveTestEligibilityVerdict.blockedNotBenchOrVehicleQualified;
        }
        if (!vehicleQualified) {
          return ActiveTestEligibilityVerdict.blockedNotVehicleQualified;
        }
    }

    // Precondition gate: live ECU prerequisites must be met.
    if (!preconditionsSatisfied) {
      return ActiveTestEligibilityVerdict.blockedPreconditionsNotMet;
    }

    // Consent gate: explicit operator consent must be given.
    if (!operatorConsentGranted) {
      return ActiveTestEligibilityVerdict.blockedMissingConsent;
    }

    // Authorization token gate (F6 / #132):
    // Token must be present, not used, not expired, and bound to recipe hash,
    // CAN header, and connection generation.
    final mustVerifyToken = requireAuthorizationToken || requireOpaqueToken;
    if (mustVerifyToken) {
      if (authorizationToken == null) {
        return ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken;
      }
      final now = currentTime ?? DateTime.now();
      final connGen = currentConnectionGeneration ?? 1;
      if (!authorizationToken.isValidFor(
        expectedRecipeHash: profile.canonicalHash,
        expectedTargetCanHeader: profile.addressing.targetEcuHeader,
        currentConnectionGeneration: connGen,
        now: now,
        busType: profile.addressing.busType,
      )) {
        return ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken;
      }
    }

    return ActiveTestEligibilityVerdict.eligible;
  }
}
