import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';

void main() {
  group('CandidateMatrix qualification categorization and live candidate gating', () {
    ActiveTestProfile makeProfile({
      required String id,
      required ProvenanceKind provenance,
      required RedistributionRights rights,
      required EvidenceQualificationTier tier,
      String sourceUrl = 'https://standards.sae.org/',
    }) {
      final unhashed = ActiveTestProfile(
        profileId: id,
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'SAE J1979:2014',
        sourceUrl: sourceUrl,
        documentSection: 'Section 8',
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
          releaseCommandDescription: 'stop',
          lossOfClientBehavior: 'timeout',
          watchdogTimeoutMs: 1000,
        ),
        evidenceTier: tier,
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
        canonicalHash: hash,
      );
    }

    test('categorizes synthetic fixtures as simulationReady and never live candidates', () {
      final synMode08 = makeProfile(
        id: 'syn_mode08_01',
        provenance: ProvenanceKind.syntheticFixture,
        rights: RedistributionRights.syntheticFixtureOnly,
        tier: EvidenceQualificationTier.syntheticFixture,
      );
      final synUds2F = makeProfile(
        id: 'syn_uds_2f_01',
        provenance: ProvenanceKind.syntheticFixture,
        rights: RedistributionRights.syntheticFixtureOnly,
        tier: EvidenceQualificationTier.syntheticFixture,
      );

      final matrix = CandidateMatrix.fromProfiles([synMode08, synUds2F]);

      expect(matrix.entries.length, 2);
      expect(matrix.simulationReadyEntries.length, 2);
      expect(matrix.hasLiveCandidates, isFalse);
      expect(matrix.liveCandidateCount, 0);
    });

    test('categorizes unreviewed sources as needsSource', () {
      final unreviewed = makeProfile(
        id: 'prop_unreviewed',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.unreviewed,
        tier: EvidenceQualificationTier.needsSource,
      );
      final matrix = CandidateMatrix.fromProfiles([unreviewed]);
      expect(matrix.needsSourceEntries.length, 1);
      expect(matrix.hasLiveCandidates, isFalse);
    });

    test('categorizes needsBench profiles accurately', () {
      final benchPending = makeProfile(
        id: 'prop_needs_bench',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.needsBench,
      );
      final matrix = CandidateMatrix.fromProfiles([benchPending]);
      expect(matrix.needsBenchEntries.length, 1);
      expect(matrix.hasLiveCandidates, isFalse);
    });

    test('delivers an explicit NO LIVE CANDIDATE result when all profiles are synthetic or unverified', () {
      final syn1 = makeProfile(
        id: 'syn_1',
        provenance: ProvenanceKind.syntheticFixture,
        rights: RedistributionRights.syntheticFixtureOnly,
        tier: EvidenceQualificationTier.syntheticFixture,
      );
      final unrev = makeProfile(
        id: 'unrev_1',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.unreviewed,
        tier: EvidenceQualificationTier.needsSource,
      );
      final bench = makeProfile(
        id: 'bench_1',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.needsBench,
      );

      final matrix = CandidateMatrix.fromProfiles([syn1, unrev, bench]);

      // Acceptance criterion: explicit no-live-candidate result
      expect(matrix.liveCandidateCount, 0);
      expect(matrix.hasLiveCandidates, isFalse);
    });

    test('qualified non-synthetic profile counts as live candidate', () {
      final qualified = makeProfile(
        id: 'qualified_pilot_01',
        provenance: ProvenanceKind.officialStandard,
        rights: RedistributionRights.openPublicStandard,
        tier: EvidenceQualificationTier.vehicleQualified,
      );

      final matrix = CandidateMatrix.fromProfiles([qualified]);
      expect(matrix.liveCandidateCount, 1);
      expect(matrix.hasLiveCandidates, isTrue);
      expect(matrix.qualifiedEntries.length, 1);
      expect(matrix.qualifiedEntries.first.isLiveCandidate, isTrue);
    });
  });
}
