import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';

void main() {
  group('ActiveTestEligibilityGate fail-closed qualification gates', () {
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

    test('production profile passes all gates when fully qualified and authorized',
        () {
      final officialProfile = createProfile(
        id: 'official_evap_test_01',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdict = ActiveTestEligibilityGate.evaluate(
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
      final verdict = ActiveTestEligibilityGate.evaluate(
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
      final verdictNoDef = ActiveTestEligibilityGate.evaluate(
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
      final verdictNotQualified = ActiveTestEligibilityGate.evaluate(
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

      final verdictUnknown = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.unknown, // Silence / timeout / no data
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictUnknown, ActiveTestEligibilityVerdict.blockedEcuSupportUnknown);
    });

    test('ECU unsupported affirmatively blocks execution', () {
      final officialProfile = createProfile(
        id: 'official_evap_04',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdictUnsupported = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.unsupported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(
          verdictUnsupported, ActiveTestEligibilityVerdict.blockedEcuNotSupported);
    });

    test('revoked profile is blocked', () {
      final revokedProfile = createProfile(
        id: 'revoked_evap_05',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
        isRevoked: true,
      );

      final verdictRevoked = ActiveTestEligibilityGate.evaluate(
        profile: revokedProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
      );
      expect(verdictRevoked, ActiveTestEligibilityVerdict.blockedRevoked);
    });

    test('failed preconditions or missing consent blocks execution', () {
      final officialProfile = createProfile(
        id: 'official_evap_06',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final verdictNoPre = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: false, // Vehicle speed > 0 or engine running
        operatorConsentGranted: true,
      );
      expect(
          verdictNoPre, ActiveTestEligibilityVerdict.blockedPreconditionsNotMet);

      final verdictNoConsent = ActiveTestEligibilityGate.evaluate(
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

    test('opaque authorization token requirement blocks execution when token missing or empty', () {
      final officialProfile = createProfile(
        id: 'official_evap_07',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      // Blocked when requireOpaqueToken: true and token is null
      final verdictNullToken = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireOpaqueToken: true,
      );
      expect(verdictNullToken,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      // Blocked when requireOpaqueToken: true and token is whitespace
      final verdictEmptyToken = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireOpaqueToken: true,
        opaqueAuthorizationToken: '   ',
      );
      expect(verdictEmptyToken,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      // Unverified raw string alone is NEVER trusted to execute
      final verdictRawStringOnly = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireOpaqueToken: true,
        opaqueAuthorizationToken: 'unverified_raw_string',
      );
      expect(verdictRawStringOnly,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      final now = DateTime.utc(2026, 9, 12, 12, 0);
      final validToken = ActiveTestAuthorizationToken(
        tokenId: 'auth_tok_sec_132_live_xyz',
        recipeHash: officialProfile.canonicalHash,
        targetCanHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        expiresAt: now.add(const Duration(minutes: 5)),
      );

      // Passes when verified, cryptographically bound authorization token provided
      final verdictValidToken = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireAuthorizationToken: true,
        authorizationToken: validToken,
        currentConnectionGeneration: 1,
        currentTime: now,
      );
      expect(verdictValidToken, ActiveTestEligibilityVerdict.eligible);

      // Blocked when token is expired
      final expiredToken = ActiveTestAuthorizationToken(
        tokenId: 'auth_tok_expired',
        recipeHash: officialProfile.canonicalHash,
        targetCanHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );
      final verdictExpired = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireAuthorizationToken: true,
        authorizationToken: expiredToken,
        currentConnectionGeneration: 1,
        currentTime: now,
      );
      expect(verdictExpired,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      // Blocked when token is already used
      final usedToken = ActiveTestAuthorizationToken(
        tokenId: 'auth_tok_used',
        recipeHash: officialProfile.canonicalHash,
        targetCanHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        expiresAt: now.add(const Duration(minutes: 5)),
        isUsed: true,
      );
      final verdictUsed = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireAuthorizationToken: true,
        authorizationToken: usedToken,
        currentConnectionGeneration: 1,
        currentTime: now,
      );
      expect(verdictUsed,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      // Blocked when recipe hash does not match
      final wrongHashToken = ActiveTestAuthorizationToken(
        tokenId: 'auth_tok_wrong_hash',
        recipeHash: 'tampered_or_different_recipe_hash',
        targetCanHeader: officialProfile.addressing.targetEcuHeader,
        connectionGeneration: 1,
        expiresAt: now.add(const Duration(minutes: 5)),
      );
      final verdictWrongHash = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireAuthorizationToken: true,
        authorizationToken: wrongHashToken,
        currentConnectionGeneration: 1,
        currentTime: now,
      );
      expect(verdictWrongHash,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);

      // Blocked when connection generation does not match (session reset)
      final verdictWrongConnGen = ActiveTestEligibilityGate.evaluate(
        profile: officialProfile,
        ecuSupport: EcuSupportStatus.supported,
        benchQualified: true,
        vehicleQualified: true,
        preconditionsSatisfied: true,
        operatorConsentGranted: true,
        requireAuthorizationToken: true,
        authorizationToken: validToken,
        currentConnectionGeneration: 2, // New connection generation!
        currentTime: now,
      );
      expect(verdictWrongConnGen,
          ActiveTestEligibilityVerdict.blockedMissingAuthorizationToken);
    });

    test('ExecutionTargetScope strictly separates bench from live vehicle execution', () {
      final officialProfile = createProfile(
        id: 'official_evap_08',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.benchQualified,
      );

      // Bench qualified ONLY, attempting execution on vehicle: MUST BE BLOCKED!
      final verdictVehicle = ActiveTestEligibilityGate.evaluate(
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
      final verdictBench = ActiveTestEligibilityGate.evaluate(
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
      final verdictBenchBlocked = ActiveTestEligibilityGate.evaluate(
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
}
