/// Qualification tiers and fail-closed eligibility gate for active tests.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25, Follow-up: Issue #132.
///
/// Strict rules enforced:
/// 1. Separate:
///    - ECU reports support (supported, unsupported, unknown)
///    - definition available (valid reviewed profile loaded)
///    - bench qualified (physical bench verification)
///    - vehicle qualified (physical vehicle verification)
///    - eligible preview (conjunction of all gates + live preconditions + explicit consent)
///    - execution authorization (issued [ActiveTestExecutionCapability] consumed atomically)
/// 2. Silence / NO DATA / Timeout is UNKNOWN, never unsupported.
/// 3. A supported ID NEVER grants execute permission on its own.
/// 4. Never infer active-test IDs from read PID definitions or model names.
/// 5. Synthetic/demo/replay provenance is strictly rejected from live production execution.
/// 6. Eligibility preview NEVER produces or grants execution dispatch authority.
/// 7. Execution boundary strictly requires an issued, unexpired, matching capability,
///    atomically consumed at dispatch. Replay, unissued tokens, and context mismatches
///    are rejected fail-closed.
library;

import 'package:flutter/foundation.dart';

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

/// Actionable verdict returned by the active-test eligibility and execution gates.
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

  /// Blocked: Required authorization capability/token is missing or null.
  blockedMissingAuthorizationToken,

  /// Blocked: Capability is foreign, forged, unissued, or has been retired.
  blockedInvalidCapability,

  /// Blocked: Capability has expired (strictly rejects now >= expiresAt).
  blockedExpiredCapability,

  /// Blocked: Capability has already been consumed (replay / duplicate dispatch blocked).
  blockedCapabilityAlreadyConsumed,

  /// Blocked: Execution context mismatch (recipe, parameter hash, header, generation, epoch, or scope).
  blockedContextMismatch,

  /// Blocked: Recovery capability cannot be used for a start operation.
  blockedRecoveryStartNotPermitted,
}

/// Permitted active test operations.
enum ActiveTestOperation {
  /// Initiate active actuation or routine start.
  start,

  /// Cease active actuation, release control to ECU, or stop routine.
  stop,
}

/// Opaque, non-constructible execution capability strictly bound to an execution context.
///
/// Ref: Issue #132.
///
/// Can ONLY be issued by [ActiveTestAuthorizationIssuer] after explicit operator consent
/// and preconditions are satisfied. Callers cannot instantiate this class directly.
final class ActiveTestExecutionCapability {
  ActiveTestExecutionCapability._({
    required this.capabilityId,
    required this.recipeHash,
    required this.selectedParametersHash,
    required this.operation,
    required this.targetEcuHeader,
    required this.busType,
    required this.connectionGeneration,
    required this.lifecycleEpoch,
    required this.targetScope,
    required this.expiresAt,
    required this.validityDuration,
    required this.issuedElapsedMicros,
    this.parentCapabilityId,
    this.recoveryDescriptorHash,
    this.isRecovery = false,
  });

  /// Factory strictly for testing unissued/forged capabilities against the issuer.
  @visibleForTesting
  factory ActiveTestExecutionCapability.forTesting({
    required String capabilityId,
    required String recipeHash,
    required String selectedParametersHash,
    required ActiveTestOperation operation,
    required String targetEcuHeader,
    required int connectionGeneration,
    required int lifecycleEpoch,
    required ExecutionTargetScope targetScope,
    required DateTime expiresAt,
    Duration validityDuration = const Duration(minutes: 5),
    int issuedElapsedMicros = 0,
    String? parentCapabilityId,
    String? recoveryDescriptorHash,
    BusAddressingType busType = BusAddressingType.can11Bit,
    bool isRecovery = false,
  }) {
    return ActiveTestExecutionCapability._(
      capabilityId: capabilityId,
      recipeHash: recipeHash,
      selectedParametersHash: selectedParametersHash,
      operation: operation,
      targetEcuHeader: targetEcuHeader,
      busType: busType,
      connectionGeneration: connectionGeneration,
      lifecycleEpoch: lifecycleEpoch,
      targetScope: targetScope,
      expiresAt: expiresAt,
      validityDuration: validityDuration,
      issuedElapsedMicros: issuedElapsedMicros,
      parentCapabilityId: parentCapabilityId,
      recoveryDescriptorHash: recoveryDescriptorHash,
      isRecovery: isRecovery,
    );
  }

  /// Unique identifier of this capability.
  final String capabilityId;

  /// Canonical SHA-256 hash of the active test profile recipe.
  final String recipeHash;

  /// Cryptographic hash of the operator-selected actuation parameters.
  final String selectedParametersHash;

  /// The exact authorized operation (start vs stop).
  final ActiveTestOperation operation;

  /// Expected CAN arbitration ID header of the target ECU.
  final String targetEcuHeader;

  /// Bus addressing format.
  final BusAddressingType busType;

  /// The specific connection generation for which this capability was issued.
  final int connectionGeneration;

  /// The specific lifecycle epoch for which this capability was issued.
  final int lifecycleEpoch;

  /// The target execution scope (bench vs vehicle).
  final ExecutionTargetScope targetScope;

  /// Monotonic expiration deadline. Equality (!now.isBefore(expiresAt)) is rejected.
  final DateTime expiresAt;

  /// Authorized elapsed validity duration (TTL).
  final Duration validityDuration;

  /// Monotonic elapsed microseconds at the time of issuance.
  final int issuedElapsedMicros;

  /// The identifier of the parent start capability for recovery operations.
  final String? parentCapabilityId;

  /// Hash of the documented recovery descriptor.
  final String? recoveryDescriptorHash;

  /// Whether this is a recovery capability (strictly restricted to [ActiveTestOperation.stop]).
  final bool isRecovery;
}

/// Internal tracking record for issued execution capabilities.
final class _CapabilityRecord {
  _CapabilityRecord({required this.capability});

  final ActiveTestExecutionCapability capability;
  bool isConsumed = false;
  bool isRetired = false;
  DateTime? consumedAt;
}

/// Trusted in-process issuer and single-use registry for active test execution capabilities.
///
/// Ref: Issue #132.
///
/// Owns the issuance, retirement, and atomic consumption of capabilities.
/// Replay, unissued tokens, cross-issuer forgery, and context mismatches are rejected fail-closed.
final class ActiveTestAuthorizationIssuer {
  ActiveTestAuthorizationIssuer({
    Stopwatch? stopwatch,
    int Function()? elapsedMicrosecondsProvider,
  })  : _stopwatch = (stopwatch ?? Stopwatch())..start(),
        _elapsedProvider = elapsedMicrosecondsProvider;

  final Stopwatch _stopwatch;
  final int Function()? _elapsedProvider;
  final Map<String, _CapabilityRecord> _registry = {};
  int _counter = 0;

  int get _currentElapsedMicros =>
      _elapsedProvider != null ? _elapsedProvider() : _stopwatch.elapsedMicroseconds;

  /// Issues a single-use execution capability for the given profile and context.
  ///
  /// Fails closed (returns null) if preview eligibility fails, or if context is invalid.
  ActiveTestExecutionCapability? issueCapability({
    required ActiveTestProfile profile,
    required EcuSupportStatus ecuSupport,
    required bool benchQualified,
    required bool vehicleQualified,
    required bool preconditionsSatisfied,
    required bool operatorConsentGranted,
    required String selectedParametersHash,
    required ActiveTestOperation operation,
    required int connectionGeneration,
    required int lifecycleEpoch,
    required ExecutionTargetScope targetScope,
    required Duration validityDuration,
    required DateTime now,
    bool isRecovery = false,
  }) {
    if (selectedParametersHash.trim().isEmpty) return null;
    if (connectionGeneration <= 0) return null;
    if (lifecycleEpoch < 0) return null;
    if (validityDuration <= Duration.zero) return null;

    if (isRecovery && operation == ActiveTestOperation.start) {
      throw ArgumentError('Recovery capability cannot grant start operation');
    }

    // Eligibility preview must affirmatively pass
    final previewVerdict = ActiveTestEligibilityGate.previewEligibility(
      profile: profile,
      ecuSupport: ecuSupport,
      benchQualified: benchQualified,
      vehicleQualified: vehicleQualified,
      preconditionsSatisfied: preconditionsSatisfied,
      operatorConsentGranted: operatorConsentGranted,
      targetScope: targetScope,
    );

    if (previewVerdict != ActiveTestEligibilityVerdict.eligible) {
      return null;
    }

    _counter++;
    final capabilityId = 'cap_${now.microsecondsSinceEpoch}_$_counter';
    final expiresAt = now.add(validityDuration);
    final issuedElapsedMicros = _currentElapsedMicros;

    final capability = ActiveTestExecutionCapability._(
      capabilityId: capabilityId,
      recipeHash: profile.canonicalHash,
      selectedParametersHash: selectedParametersHash.trim(),
      operation: operation,
      targetEcuHeader: profile.addressing.targetEcuHeader,
      busType: profile.addressing.busType,
      connectionGeneration: connectionGeneration,
      lifecycleEpoch: lifecycleEpoch,
      targetScope: targetScope,
      expiresAt: expiresAt,
      validityDuration: validityDuration,
      issuedElapsedMicros: issuedElapsedMicros,
      isRecovery: isRecovery,
    );

    _registry[capabilityId] = _CapabilityRecord(capability: capability);
    return capability;
  }

  /// Issues a recovery capability restricted strictly to [ActiveTestOperation.stop]
  /// and immutably bound to a previously authorized [authorizedStartCapability].
  ActiveTestExecutionCapability? issueRecoveryCapability({
    required ActiveTestProfile profile,
    required ActiveTestExecutionCapability authorizedStartCapability,
    required Duration validityDuration,
    required DateTime now,
  }) {
    if (validityDuration <= Duration.zero) return null;

    // Must bind to an existing, non-retired, start capability issued by this issuer
    final startRecord = _registry[authorizedStartCapability.capabilityId];
    if (startRecord == null ||
        !identical(startRecord.capability, authorizedStartCapability)) {
      return null;
    }
    if (startRecord.isRetired) return null;
    if (authorizedStartCapability.operation != ActiveTestOperation.start) {
      return null;
    }
    if (authorizedStartCapability.isRecovery) {
      return null;
    }

    // Must match the profile recipe and have a valid documented recovery descriptor
    if (profile.canonicalHash.trim() !=
        authorizedStartCapability.recipeHash.trim()) {
      return null;
    }
    if (!profile.recovery.isValid) {
      return null;
    }

    _counter++;
    final capabilityId = 'rec_cap_${now.microsecondsSinceEpoch}_$_counter';
    final expiresAt = now.add(validityDuration);
    final issuedElapsedMicros = _currentElapsedMicros;

    final capability = ActiveTestExecutionCapability._(
      capabilityId: capabilityId,
      recipeHash: authorizedStartCapability.recipeHash,
      selectedParametersHash: authorizedStartCapability.selectedParametersHash,
      operation: ActiveTestOperation.stop,
      targetEcuHeader: authorizedStartCapability.targetEcuHeader,
      busType: authorizedStartCapability.busType,
      connectionGeneration: authorizedStartCapability.connectionGeneration,
      lifecycleEpoch: authorizedStartCapability.lifecycleEpoch,
      targetScope: authorizedStartCapability.targetScope,
      expiresAt: expiresAt,
      validityDuration: validityDuration,
      issuedElapsedMicros: issuedElapsedMicros,
      parentCapabilityId: authorizedStartCapability.capabilityId,
      recoveryDescriptorHash:
          profile.recovery.releaseCommandDescription.hashCode.toRadixString(16),
      isRecovery: true,
    );

    _registry[capabilityId] = _CapabilityRecord(capability: capability);
    return capability;
  }

  /// Retires all issued capabilities (e.g., on transport disconnection or session reset).
  void retireAll() {
    for (final record in _registry.values) {
      record.isRetired = true;
    }
  }

  /// Atomically verifies and consumes [capability] for dispatch.
  ///
  /// Can only be consumed once. A second call with the same capability fails closed
  /// with [ActiveTestEligibilityVerdict.blockedCapabilityAlreadyConsumed].
  ActiveTestEligibilityVerdict verifyAndConsume({
    required ActiveTestExecutionCapability? capability,
    required String expectedRecipeHash,
    required String expectedSelectedParametersHash,
    required ActiveTestOperation expectedOperation,
    required String expectedTargetCanHeader,
    required int currentConnectionGeneration,
    required int currentLifecycleEpoch,
    required ExecutionTargetScope currentTargetScope,
    required DateTime now,
    BusAddressingType busType = BusAddressingType.can11Bit,
  }) {
    if (capability == null) {
      return ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken;
    }

    final record = _registry[capability.capabilityId];
    if (record == null) {
      // Foreign, unissued, or forged capability
      return ActiveTestEligibilityVerdict.blockedInvalidCapability;
    }

    // Exact issued object identity verification:
    // Must be identical to the exact instance issued by this issuer.
    // Replaced/counterfeit objects with identical ID are rejected fail-closed
    // without consuming the genuine token!
    if (!identical(record.capability, capability)) {
      return ActiveTestEligibilityVerdict.blockedInvalidCapability;
    }

    if (record.isRetired) {
      return ActiveTestEligibilityVerdict.blockedInvalidCapability;
    }

    if (record.isConsumed) {
      // Replay or duplicate dispatch attempt
      return ActiveTestEligibilityVerdict.blockedCapabilityAlreadyConsumed;
    }

    // Authoritative registered capability payload
    final authoritative = record.capability;

    // Strict expiration check on wall-clock audit time: reject equality (!now.isBefore(expiresAt))
    if (!now.isBefore(authoritative.expiresAt)) {
      return ActiveTestEligibilityVerdict.blockedExpiredCapability;
    }

    // Monotonic elapsed-time TTL check: owned by trusted issuer's monotonic timer
    final elapsedMicros =
        _currentElapsedMicros - authoritative.issuedElapsedMicros;
    if (elapsedMicros < 0 ||
        elapsedMicros >= authoritative.validityDuration.inMicroseconds) {
      return ActiveTestEligibilityVerdict.blockedExpiredCapability;
    }

    // Context bindings verification against authoritative registered object
    if (authoritative.recipeHash.trim() != expectedRecipeHash.trim()) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (authoritative.selectedParametersHash.trim() !=
        expectedSelectedParametersHash.trim()) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (authoritative.isRecovery &&
        expectedOperation == ActiveTestOperation.start) {
      return ActiveTestEligibilityVerdict.blockedRecoveryStartNotPermitted;
    }
    if (authoritative.operation != expectedOperation) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    // Strict bus type match
    if (authoritative.busType != busType) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (!TransportAddressing.areHeadersEquivalent(
        authoritative.targetEcuHeader, expectedTargetCanHeader, busType)) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (authoritative.connectionGeneration != currentConnectionGeneration) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (authoritative.lifecycleEpoch != currentLifecycleEpoch) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }
    if (authoritative.targetScope != currentTargetScope) {
      return ActiveTestEligibilityVerdict.blockedContextMismatch;
    }

    // Atomic single-use consumption transition!
    record.isConsumed = true;
    record.consumedAt = now;

    return ActiveTestEligibilityVerdict.eligible;
  }
}

/// Legacy authorization token (Issue #132).
///
/// Deprecated: Replaced by [ActiveTestExecutionCapability] issued by
/// [ActiveTestAuthorizationIssuer] with atomic consumption.
@Deprecated('Use ActiveTestExecutionCapability and ActiveTestAuthorizationIssuer')
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
    // Strict expiry check: exact equality is rejected!
    if (!now.isBefore(expiresAt)) return false;
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

/// Fail-closed eligibility gate evaluator for read-only preview.
final class ActiveTestEligibilityGate {
  const ActiveTestEligibilityGate._();

  /// Evaluates whether an active test profile satisfies qualification, support,
  /// and precondition gates for an informational preview.
  ///
  /// CRITICAL: This is an informational PREVIEW only and NEVER produces or grants
  /// execution dispatch authority. To execute, an [ActiveTestExecutionCapability]
  /// must be issued by [ActiveTestAuthorizationIssuer] and atomically verified and
  /// consumed via [ActiveTestExecutionGate.verifyAndConsume].
  static ActiveTestEligibilityVerdict previewEligibility({
    required ActiveTestProfile? profile,
    required EcuSupportStatus ecuSupport,
    required bool benchQualified,
    required bool vehicleQualified,
    required bool preconditionsSatisfied,
    required bool operatorConsentGranted,
    ExecutionTargetScope targetScope = ExecutionTargetScope.vehicle,
  }) {
    if (profile == null || !profile.isValid) {
      return ActiveTestEligibilityVerdict.blockedNoDefinition;
    }

    if (profile.isRevoked) {
      return ActiveTestEligibilityVerdict.blockedRevoked;
    }

    // Synthetic fixtures are strictly prohibited from live vehicle execution,
    // even if an ECU reports support or an ID matches!
    if (targetScope == ExecutionTargetScope.vehicle &&
        (profile.provenanceKind == ProvenanceKind.syntheticFixture ||
            profile.redistributionRights ==
                RedistributionRights.syntheticFixtureOnly ||
            profile.evidenceTier == EvidenceQualificationTier.syntheticFixture)) {
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

    return ActiveTestEligibilityVerdict.eligible;
  }

  /// Deprecated alias to [previewEligibility].
  @Deprecated('Use previewEligibility for read-only preview')
  static ActiveTestEligibilityVerdict evaluate({
    required ActiveTestProfile? profile,
    required EcuSupportStatus ecuSupport,
    required bool benchQualified,
    required bool vehicleQualified,
    required bool preconditionsSatisfied,
    required bool operatorConsentGranted,
    ExecutionTargetScope targetScope = ExecutionTargetScope.vehicle,
  }) {
    return previewEligibility(
      profile: profile,
      ecuSupport: ecuSupport,
      benchQualified: benchQualified,
      vehicleQualified: vehicleQualified,
      preconditionsSatisfied: preconditionsSatisfied,
      operatorConsentGranted: operatorConsentGranted,
      targetScope: targetScope,
    );
  }
}

/// Fail-closed execution gate enforcing mandatory capability verification and atomic consumption.
final class ActiveTestExecutionGate {
  const ActiveTestExecutionGate._();

  /// Enforces mandatory capability verification and atomic single-use consumption.
  ///
  /// Fails closed if capability is missing, unissued, expired, context-mismatched,
  /// or already consumed.
  static ActiveTestEligibilityVerdict verifyAndConsume({
    required ActiveTestAuthorizationIssuer issuer,
    required ActiveTestExecutionCapability? capability,
    required String expectedRecipeHash,
    required String expectedSelectedParametersHash,
    required ActiveTestOperation expectedOperation,
    required String expectedTargetCanHeader,
    required int currentConnectionGeneration,
    required int currentLifecycleEpoch,
    required ExecutionTargetScope currentTargetScope,
    required DateTime now,
    BusAddressingType busType = BusAddressingType.can11Bit,
  }) {
    return issuer.verifyAndConsume(
      capability: capability,
      expectedRecipeHash: expectedRecipeHash,
      expectedSelectedParametersHash: expectedSelectedParametersHash,
      expectedOperation: expectedOperation,
      expectedTargetCanHeader: expectedTargetCanHeader,
      currentConnectionGeneration: currentConnectionGeneration,
      currentLifecycleEpoch: currentLifecycleEpoch,
      currentTargetScope: currentTargetScope,
      now: now,
      busType: busType,
    );
  }
}
