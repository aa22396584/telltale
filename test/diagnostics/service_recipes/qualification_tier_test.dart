import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';

void main() {
  ActiveTestProfile createProfile({
    required String id,
    required ProvenanceKind provenance,
    required RedistributionRights rights,
    required EvidenceQualificationTier tier,
    bool isRevoked = false,
  }) {
    final unhashed = ActiveTestProfile(
      profileId: id,
      schemaVersion: 1,
      version: '1.0.0',
      standard: 'SAE J1979:2014',
      sourceUrl: 'https://standards.sae.org/j1979_201408/',
      documentSection: 'Section 8.4',
      redistributionRights: rights,
      provenanceKind: provenance,
      addressing: const TransportAddressing(
        busType: BusAddressingType.can11Bit,
        targetEcuHeader: '7E0',
        expectedResponseHeader: '7E8',
      ),
      applicability: EcuApplicability(
        make: 'Toyota',
        model: 'Prius',
        targetEcuName: 'ECM',
        softwareVersions: const ['V1'],
      ),
      sessionType: DiagnosticSessionType.defaultSession,
      serviceDescriptor: Mode08Descriptor(testId: 0x01),
      preconditions: const [
        PreconditionRule(
          parameterName: 'vehicleSpeedKmh',
          minValue: 0,
          maxValue: 0,
        ),
      ],
      constraints: const ExecutionConstraints(),
      recovery: const RecoverySpecification(
        releaseCommandDescription: 'release',
        lossOfClientBehavior: 'timeout',
        watchdogTimeoutMs: 1000,
      ),
      evidenceTier: tier,
      isRevoked: isRevoked,
      canonicalHash: '',
    );
    final hash = unhashed.computeCanonicalHash();
    return ActiveTestProfile(
      profileId: id,
      schemaVersion: unhashed.schemaVersion,
      version: unhashed.version,
      standard: unhashed.standard,
      sourceUrl: unhashed.sourceUrl,
      documentSection: unhashed.documentSection,
      redistributionRights: rights,
      provenanceKind: provenance,
      addressing: unhashed.addressing,
      applicability: unhashed.applicability,
      sessionType: unhashed.sessionType,
      serviceDescriptor: unhashed.serviceDescriptor,
      preconditions: unhashed.preconditions,
      constraints: unhashed.constraints,
      recovery: unhashed.recovery,
      evidenceTier: tier,
      isRevoked: isRevoked,
      canonicalHash: hash,
    );
  }

  group('ActiveTestEligibilityGate fail-closed qualification preview gates', () {
    test('production profile passes preview when fully qualified and consented',
        () {
      final officialProfile = createProfile(
        id: 'official_evap_test_01',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdict = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );

      expect(verdict, ActiveTestEligibilityVerdict.eligible);
    });

    test('synthetic fixture is STRICTLY BLOCKED from live vehicle execution',
        () {
      final syntheticProfile = createProfile(
        id: 'synthetic_fixture_01',
        provenance: ProvenanceKind.syntheticFixture,
        rights: RedistributionRights.syntheticFixtureOnly,
        tier: EvidenceQualificationTier.syntheticFixture,
      );

      // Even if everything else is true (ECU support, bench, consent, preconditions)
      final verdict = ActiveTestEligibilityGate.previewEligibility(
        profile: syntheticProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );

      expect(verdict, ActiveTestEligibilityVerdict.blockedSyntheticFixture);
    });

    test('ECU reporting support NEVER grants permission without definition/qualification',
        () {
      // 1. No definition
      final verdictNoDef = ActiveTestEligibilityGate.previewEligibility(
        profile: null,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictNoDef, ActiveTestEligibilityVerdict.blockedNoDefinition);

      // 2. Definition exists, but not hardware qualified
      final officialProfile = createProfile(
        id: 'official_evap_02',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.needsBench,
      );
      final verdictNotQualified = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: false,
        vehicleQualified: false,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictNotQualified,
          ActiveTestEligibilityVerdict.blockedNotBenchOrVehicleQualified);
    });

    test('ECU unknown support (silence/NO DATA) blocks execution as unknown', () {
      final officialProfile = createProfile(
        id: 'official_evap_03',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdictUnknown = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.unknown, // Silence / timeout / no data
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(
          verdictUnknown, ActiveTestEligibilityVerdict.blockedEcuSupportUnknown);
    });

    test('ECU unsupported affirmatively blocks execution', () {
      final officialProfile = createProfile(
        id: 'official_evap_04',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdictUnsupported = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.unsupported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictUnsupported,
          ActiveTestEligibilityVerdict.blockedEcuNotSupported);
    });

    test('revoked profile is blocked', () {
      final revokedProfile = createProfile(
        id: 'revoked_evap_05',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
        isRevoked: true,
      );

      final verdictRevoked = ActiveTestEligibilityGate.previewEligibility(
        profile: revokedProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictRevoked, ActiveTestEligibilityVerdict.blockedRevoked);
    });

    test('failed preconditions or missing consent blocks preview', () {
      final officialProfile = createProfile(
        id: 'official_evap_06',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdictNoPre = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: false, // Vehicle speed > 0 or engine running
        operatorConsentGranted: true,
      );
      expect(verdictNoPre,
          ActiveTestEligibilityVerdict.blockedPreconditionsNotMet);

      final verdictNoConsent = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: false, // Operator did not arm/confirm
      );
      expect(
          verdictNoConsent, ActiveTestEligibilityVerdict.blockedMissingConsent);
    });

    test('ExecutionTargetScope strictly separates bench from live vehicle execution',
        () {
      final officialProfile = createProfile(
        id: 'official_evap_08',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.benchQualified,
      );

      // Bench qualified ONLY, attempting execution on vehicle: MUST BE BLOCKED!
      final verdictVehicle = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: false,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        targetScope: ExecutionTargetScope.vehicle,
      );
      expect(verdictVehicle,
          ActiveTestEligibilityVerdict.blockedNotVehicleQualified);

      // Bench qualified executing in bench target scope: PASSES
      final verdictBench = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: false,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        targetScope: ExecutionTargetScope.bench,
      );
      expect(verdictBench, ActiveTestEligibilityVerdict.eligible);

      // Not bench qualified executing in bench target scope: BLOCKED
      final verdictBenchBlocked = ActiveTestEligibilityGate.previewEligibility(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: false,
        vehicleQualified: false,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        targetScope: ExecutionTargetScope.bench,
      );
      expect(verdictBenchBlocked,
          ActiveTestEligibilityVerdict.blockedNotBenchQualified);
    });
  });

  group('ActiveTestAuthorizationIssuer and ActiveTestExecutionGate enforcement', () {
    final officialProfile = createProfile(
      id: 'official_evap_gate_01',
      provenance: ProvenanceKind.officialStandard,
      rights: RedistributionRights.openPublicStandard,
      tier: EvidenceQualificationTier.vehicleQualified,
    );

    final syntheticBenchProfile = createProfile(
      id: 'synthetic_bench_fixture_01',
      provenance: ProvenanceKind.syntheticFixture,
      rights: RedistributionRights.syntheticFixtureOnly,
      tier: EvidenceQualificationTier.syntheticFixture,
    );

    const validParamsHash = 'param_hash_abc123';
    final now = DateTime.utc(2026, 9, 13, 10, 0, 0);

    test('default/missing capability is strictly rejected at execution boundary', () {
      final issuer = ActiveTestAuthorizationIssuer();

      final verdictNull = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: null,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );

      expect(verdictNull,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);
    });

    test('unissued/forged capability is strictly rejected', () {
      final issuer = ActiveTestAuthorizationIssuer();

      // Forged capability not present in issuer's registry
      final forgedCap = ActiveTestExecutionCapability.forTesting(
        capabilityId: 'forged_cap_001',
        recipeHash: officialProfile.canonicalHash,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        targetEcuHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        expiresAt: now.add(const Duration(minutes: 5)),
      );

      final verdictForged = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: forgedCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );

      expect(verdictForged,
          ActiveTestEligibilityVerdict.blockedInvalidCapability);
    });

    test('duplicate / replay execution is atomically blocked', () {
      final issuer = ActiveTestAuthorizationIssuer();

      final capability = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);

      // First consumption: SUCCESS
      final verdict1 = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdict1, ActiveTestEligibilityVerdict.eligible);

      // Second consumption with same capability: REJECTED fail-closed
      final verdict2 = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now.add(const Duration(seconds: 1)),
      );
      expect(verdict2,
          ActiveTestEligibilityVerdict.blockedCapabilityAlreadyConsumed);
    });

    test('concurrent consumption attempts permit at most one dispatch',
        () async {
      final issuer = ActiveTestAuthorizationIssuer();

      final capability = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);

      final results = await Future.wait([
        Future.microtask(() => ActiveTestExecutionGate.verifyAndConsume(
              issuer: issuer,
              capability: capability,
              expectedRecipeHash: officialProfile.canonicalHash,
              expectedSelectedParametersHash: validParamsHash,
              expectedOperation: ActiveTestOperation.start,
              expectedTargetCanHeader:
                  officialProfile.addressing.targetEcuHeader,
              currentConnectionGeneration: 1,
              currentLifecycleEpoch: 0,
              currentTargetScope: ExecutionTargetScope.vehicle,
              now: now,
            )),
        Future.microtask(() => ActiveTestExecutionGate.verifyAndConsume(
              issuer: issuer,
              capability: capability,
              expectedRecipeHash: officialProfile.canonicalHash,
              expectedSelectedParametersHash: validParamsHash,
              expectedOperation: ActiveTestOperation.start,
              expectedTargetCanHeader:
                  officialProfile.addressing.targetEcuHeader,
              currentConnectionGeneration: 1,
              currentLifecycleEpoch: 0,
              currentTargetScope: ExecutionTargetScope.vehicle,
              now: now,
            )),
      ]);

      final eligibleCount = results
          .where((v) => v == ActiveTestEligibilityVerdict.eligible)
          .length;
      final consumedCount = results
          .where((v) =>
              v == ActiveTestEligibilityVerdict.blockedCapabilityAlreadyConsumed)
          .length;

      expect(eligibleCount, 1);
      expect(consumedCount, 1);
    });

    test('modified parameters / ECU / generation / epoch / scope are blocked',
        () {
      final issuer = ActiveTestAuthorizationIssuer();

      final capability = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);

      // 1. Modified parameters hash
      final verdictWrongParams = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: 'tampered_parameters_hash',
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictWrongParams,
          ActiveTestEligibilityVerdict.blockedContextMismatch);

      // 2. Modified ECU header
      final verdictWrongEcu = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: '7E1', // Different ECU!
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictWrongEcu,
          ActiveTestEligibilityVerdict.blockedContextMismatch);

      // 3. Modified connection generation (e.g. reconnect occurred)
      final verdictWrongGen = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 2, // New connection generation!
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictWrongGen,
          ActiveTestEligibilityVerdict.blockedContextMismatch);

      // 4. Modified lifecycle epoch
      final verdictWrongEpoch = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 5, // Different epoch!
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictWrongEpoch,
          ActiveTestEligibilityVerdict.blockedContextMismatch);

      // 5. Modified target scope
      final verdictWrongScope = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.bench, // Issued for vehicle!
        now: now,
      );
      expect(verdictWrongScope,
          ActiveTestEligibilityVerdict.blockedContextMismatch);
    });

    test('exact boundary expiry (now == expiresAt) and past-expiry are blocked',
        () {
      final issuer = ActiveTestAuthorizationIssuer();

      final capability = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(seconds: 30),
        now: now,
      );
      expect(capability, isNotNull);

      // EXACT boundary: now == expiresAt MUST BE REJECTED
      final verdictBoundary = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: capability!.expiresAt,
      );
      expect(verdictBoundary,
          ActiveTestEligibilityVerdict.blockedExpiredCapability);

      // Past expiry: now > expiresAt MUST BE REJECTED
      final verdictExpired = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: capability.expiresAt.add(const Duration(seconds: 1)),
      );
      expect(verdictExpired,
          ActiveTestEligibilityVerdict.blockedExpiredCapability);
    });

    test('retirement on reconnect invalidates issued capability', () {
      final issuer = ActiveTestAuthorizationIssuer();

      final capability = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);

      // Session reset / reconnect retires all previously issued capabilities
      issuer.retireAll();

      final verdictRetired = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictRetired,
          ActiveTestEligibilityVerdict.blockedInvalidCapability);
    });

    test('positive synthetic dispatch in bench scope succeeds and consumes atomically',
        () {
      final issuer = ActiveTestAuthorizationIssuer();

      // Synthetic fixture is permitted in BENCH target scope if bench qualified
      final capability = issuer.issueCapability(
        profile: syntheticBenchProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: false,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.bench,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);

      final verdict = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: syntheticBenchProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader:
            syntheticBenchProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.bench,
        now: now,
      );
      expect(verdict, ActiveTestEligibilityVerdict.eligible);
    });

    test('recovery capability is restricted strictly to stop operation', () {
      final issuer = ActiveTestAuthorizationIssuer();

      // Attempting to issue recovery capability with start operation throws ArgumentError
      expect(
        () => issuer.issueCapability(
          profile: officialProfile,
          ecuSupport: EcuSupportStatus.supported,
          benchQualified: true,
          vehicleQualified: true,
          preconditionsSatisfied: true,
          operatorConsentGranted: true,
          selectedParametersHash: validParamsHash,
          operation: ActiveTestOperation.start,
          connectionGeneration: 1,
          lifecycleEpoch: 0,
          targetScope: ExecutionTargetScope.vehicle,
          validityDuration: const Duration(minutes: 5),
          now: now,
          isRecovery: true,
        ),
        throwsArgumentError,
      );

      // Issue genuine start capability first
      final startCap = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(startCap, isNotNull);

      // Issuing recovery capability via dedicated method enforces stop operation bound to parent
      final recoveryCap = issuer.issueRecoveryCapability(
        profile: officialProfile,
        authorizedStartCapability: startCap!,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(recoveryCap, isNotNull);
      expect(recoveryCap!.operation, ActiveTestOperation.stop);
      expect(recoveryCap.isRecovery, isTrue);
      expect(recoveryCap.parentCapabilityId, startCap.capabilityId);

      // Attempting to consume recovery capability for start operation is blocked
      final verdictStart = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: recoveryCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start, // Prohibited for recovery!
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictStart,
          ActiveTestEligibilityVerdict.blockedRecoveryStartNotPermitted);

      // Consuming recovery capability for stop operation succeeds
      final verdictStop = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: recoveryCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.stop,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
      );
      expect(verdictStop, ActiveTestEligibilityVerdict.eligible);
    });

    test(
        'two issuers minting at same timestamp: same-ID foreign capability is rejected and genuine capability is not consumed',
        () {
      final issuerA = ActiveTestAuthorizationIssuer();
      final issuerB = ActiveTestAuthorizationIssuer();

      final fixedTimestamp = DateTime(2026, 9, 13, 10, 0, 0);

      final capA = issuerA.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: fixedTimestamp,
      );

      final capB = issuerB.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: fixedTimestamp,
      );

      expect(capA, isNotNull);
      expect(capB, isNotNull);
      // Both issuers produced the exact same ID!
      expect(capA!.capabilityId, capB!.capabilityId);
      expect(identical(capA, capB), isFalse);

      // Present foreign capB to issuerA: MUST BE REJECTED fail-closed
      final verdictForeign = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuerA,
        capability: capB,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: fixedTimestamp,
      );
      expect(verdictForeign,
          ActiveTestEligibilityVerdict.blockedInvalidCapability);

      // Crucial: Rejecting foreign capB MUST NOT consume genuine capA!
      final verdictGenuine = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuerA,
        capability: capA,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: fixedTimestamp,
      );
      expect(verdictGenuine, ActiveTestEligibilityVerdict.eligible);

      // Second consumption of genuine capA fails as already consumed
      final verdictReplay = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuerA,
        capability: capA,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: fixedTimestamp.add(const Duration(seconds: 1)),
      );
      expect(verdictReplay,
          ActiveTestEligibilityVerdict.blockedCapabilityAlreadyConsumed);
    });

    test(
        'same-ID altered object cannot consume genuine token or extend expired token',
        () {
      final issuer = ActiveTestAuthorizationIssuer();
      final fixedTimestamp = DateTime(2026, 9, 13, 10, 0, 0);

      final genuineCap = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(seconds: 30),
        now: fixedTimestamp,
      );
      expect(genuineCap, isNotNull);

      // 1. Same-ID forged object with altered parameters
      final alteredParamsCap = ActiveTestExecutionCapability.forTesting(
        capabilityId: genuineCap!.capabilityId,
        recipeHash: genuineCap.recipeHash,
        selectedParametersHash: 'malicious_tampered_parameters',
        operation: ActiveTestOperation.start,
        targetEcuHeader: genuineCap.targetEcuHeader,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        expiresAt: fixedTimestamp.add(const Duration(seconds: 30)),
      );

      final verdictAltered = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: alteredParamsCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: 'malicious_tampered_parameters',
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: fixedTimestamp,
      );
      // Must reject the non-identical object
      expect(verdictAltered,
          ActiveTestEligibilityVerdict.blockedInvalidCapability);

      // Genuine token was NOT consumed
      final afterAlteredTime = fixedTimestamp.add(const Duration(seconds: 5));
      final verdictGenuine = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: genuineCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: afterAlteredTime,
      );
      expect(verdictGenuine, ActiveTestEligibilityVerdict.eligible);

      // 2. Expired genuine capability cannot be replaced with a forged object having extended expiry
      final issuer2 = ActiveTestAuthorizationIssuer();
      final shortLivedCap = issuer2.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(seconds: 10),
        now: fixedTimestamp,
      );
      expect(shortLivedCap, isNotNull);

      // After 15 seconds, genuineCap is expired
      final expiredNow = fixedTimestamp.add(const Duration(seconds: 15));

      // Forged object with same ID but with a 2-hour extended expiry
      final extendedExpiryCap = ActiveTestExecutionCapability.forTesting(
        capabilityId: shortLivedCap!.capabilityId,
        recipeHash: shortLivedCap.recipeHash,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        targetEcuHeader: shortLivedCap.targetEcuHeader,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        expiresAt: fixedTimestamp.add(const Duration(hours: 2)),
      );

      final verdictExtended = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer2,
        capability: extendedExpiryCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: expiredNow,
      );
      // Forged replacement is rejected fail-closed
      expect(verdictExtended,
          ActiveTestEligibilityVerdict.blockedInvalidCapability);

      // And genuine object check at expiredNow returns blockedExpiredCapability
      final verdictExpired = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer2,
        capability: shortLivedCap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: expiredNow,
      );
      expect(verdictExpired,
          ActiveTestEligibilityVerdict.blockedExpiredCapability);
    });

    test('bus type mismatch fails context check and does not consume capability',
        () {
      final issuer = ActiveTestAuthorizationIssuer();
      final capability = issuer.issueCapability(
        profile: officialProfile, // busType is can11Bit
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(capability, isNotNull);
      expect(capability!.busType, BusAddressingType.can11Bit);

      // Caller expects can29Bit bus type: MUST fail context mismatch
      final verdictBusMismatch = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
        busType: BusAddressingType.can29Bit, // Mismatch!
      );
      expect(verdictBusMismatch,
          ActiveTestEligibilityVerdict.blockedContextMismatch);

      // Capability was NOT consumed by the failed check
      final verdictCorrectBus = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: capability,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: now,
        busType: BusAddressingType.can11Bit,
      );
      expect(verdictCorrectBus, ActiveTestEligibilityVerdict.eligible);
    });

    test(
        'recovery capability binds to parent start operation and cannot be minted for unissued or foreign operation',
        () {
      final issuerA = ActiveTestAuthorizationIssuer();
      final issuerB = ActiveTestAuthorizationIssuer();

      final startCapA = issuerA.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(startCapA, isNotNull);

      // 1. Foreign start capability cannot mint recovery on issuerB
      final foreignRecovery = issuerB.issueRecoveryCapability(
        profile: officialProfile,
        authorizedStartCapability: startCapA!,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(foreignRecovery, isNull);

      // 2. Different profile recipe cannot mint recovery
      final otherProfile = createProfile(
        id: 'other_routine_01',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );
      final mismatchedProfileRecovery = issuerA.issueRecoveryCapability(
        profile: otherProfile,
        authorizedStartCapability: startCapA,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(mismatchedProfileRecovery, isNull);

      // 3. Genuine start capability mints valid recovery capability bound to parent
      final recoveryCap = issuerA.issueRecoveryCapability(
        profile: officialProfile,
        authorizedStartCapability: startCapA,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(recoveryCap, isNotNull);
      expect(recoveryCap!.operation, ActiveTestOperation.stop);
      expect(recoveryCap.isRecovery, isTrue);
      expect(recoveryCap.parentCapabilityId, startCapA.capabilityId);
      expect(recoveryCap.connectionGeneration, startCapA.connectionGeneration);
      expect(recoveryCap.lifecycleEpoch, startCapA.lifecycleEpoch);
      expect(recoveryCap.targetScope, startCapA.targetScope);
      expect(recoveryCap.targetEcuHeader, startCapA.targetEcuHeader);

      // Cannot chain recovery on a recovery capability
      final chainRecovery = issuerA.issueRecoveryCapability(
        profile: officialProfile,
        authorizedStartCapability: recoveryCap,
        validityDuration: const Duration(minutes: 5),
        now: now,
      );
      expect(chainRecovery, isNull);
    });

    test(
        'monotonic elapsed TTL rejects execution even if caller-provided wall-clock time is rewound',
        () {
      int mockElapsedMicros = 1000000; // 1s
      final issuer = ActiveTestAuthorizationIssuer(
        elapsedMicrosecondsProvider: () => mockElapsedMicros,
      );

      final fixedTimestamp = DateTime(2026, 9, 13, 10, 0, 0);

      final cap = issuer.issueCapability(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        selectedParametersHash: validParamsHash,
        operation: ActiveTestOperation.start,
        connectionGeneration: 1,
        lifecycleEpoch: 0,
        targetScope: ExecutionTargetScope.vehicle,
        validityDuration: const Duration(seconds: 10), // 10s TTL
        now: fixedTimestamp,
      );
      expect(cap, isNotNull);

      // Advance monotonic elapsed time by 11 seconds (TTL exceeded)
      mockElapsedMicros += 11 * 1000000;

      // Even if caller fraudulently supplies a wall-clock time in the past (e.g. 1 second after issue):
      final rewoundNow = fixedTimestamp.add(const Duration(seconds: 1));
      final verdict = ActiveTestExecutionGate.verifyAndConsume(
        issuer: issuer,
        capability: cap,
        expectedRecipeHash: officialProfile.canonicalHash,
        expectedSelectedParametersHash: validParamsHash,
        expectedOperation: ActiveTestOperation.start,
        expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
        currentConnectionGeneration: 1,
        currentLifecycleEpoch: 0,
        currentTargetScope: ExecutionTargetScope.vehicle,
        now: rewoundNow,
      );

      // Monotonic timer owned by issuer fails closed!
      expect(
          verdict, ActiveTestEligibilityVerdict.blockedExpiredCapability);
    });

    test('legacy ActiveTestAuthorizationToken strictly rejects exact expiry boundary',
        () {
      // Direct unit test of legacy token boundary check
      final token = ActiveTestAuthorizationToken(
        tokenId: 'leg_tok_001',
        recipeHash: officialProfile.canonicalHash,
        targetCanHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        expiresAt: now,
      );

      // At exact boundary (now == expiresAt), must return false
      expect(
        token.isValidFor(
          expectedRecipeHash: officialProfile.canonicalHash,
          expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
          currentConnectionGeneration: 1,
          now: now,
        ),
        isFalse,
      );

      // 1 second before expiry, returns true
      expect(
        token.isValidFor(
          expectedRecipeHash: officialProfile.canonicalHash,
          expectedTargetCanHeader: officialProfile.addressing.targetEcuHeader,
          currentConnectionGeneration: 1,
          now: now.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
