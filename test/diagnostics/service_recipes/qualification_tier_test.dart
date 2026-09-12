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
        applicability: const EcuApplicability(
          make: 'Toyota',
          model: 'Prius',
          targetEcuName: 'ECM',
          softwareVersions: ['V1'],
        ),
        sessionType: DiagnosticSessionType.defaultSession,
        serviceDescriptor: const Mode08Descriptor(testId: 0x01),
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
  });
}
