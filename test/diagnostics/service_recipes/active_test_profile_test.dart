import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';

void main() {
  group('ActiveTestProfile schema and descriptor validation', () {
    ActiveTestProfile createValidMode08Profile({
      String profileId = 'synthetic_mode08_evap_01',
      int schemaVersion = 1,
      String version = '1.0.0',
      String standard = 'SAE J1979:2014',
      String sourceUrl = 'https://standards.sae.org/j1979_201408/',
      String documentSection = 'Section 8.4 Mode 08',
      RedistributionRights rights = RedistributionRights.syntheticFixtureOnly,
      ProvenanceKind provenance = ProvenanceKind.syntheticFixture,
      TransportAddressing addressing = const TransportAddressing(
        busType: BusAddressingType.can11Bit,
        targetEcuHeader: '7E0',
        expectedResponseHeader: '7E8',
      ),
      EcuApplicability applicability = const EcuApplicability(
        make: 'Synthetic',
        model: 'BenchSim',
        targetEcuName: 'ECM',
        softwareVersions: ['SIM_V1'],
      ),
      DiagnosticSessionType sessionType = DiagnosticSessionType.defaultSession,
      int? securityLevel,
      ServiceDescriptor serviceDescriptor = const Mode08Descriptor(
        testId: 0x01,
        expectedResponseBytes: 1,
      ),
      List<PreconditionRule> preconditions = const [
        PreconditionRule(
          parameterName: 'vehicleSpeedKmh',
          minValue: 0,
          maxValue: 0,
          maxAgeMs: 1000,
        ),
      ],
      ExecutionConstraints constraints = const ExecutionConstraints(
        maxCommands: 2,
        minCommandIntervalMs: 200,
        stepTimeoutMs: 2000,
        overallTimeoutMs: 5000,
      ),
      RecoverySpecification recovery = const RecoverySpecification(
        releaseCommandDescription: 'Automatic return upon completion or timeout',
        lossOfClientBehavior: 'ECU returns control to normal mode after 1000ms',
        watchdogTimeoutMs: 1000,
      ),
      List<PostconditionRule> postconditions = const [],
      EvidenceQualificationTier evidenceTier =
          EvidenceQualificationTier.syntheticFixture,
      bool isRevoked = false,
      String? revocationReason,
    }) {
      final unhashed = ActiveTestProfile(
        profileId: profileId,
        schemaVersion: schemaVersion,
        version: version,
        standard: standard,
        sourceUrl: sourceUrl,
        documentSection: documentSection,
        redistributionRights: rights,
        provenanceKind: provenance,
        addressing: addressing,
        applicability: applicability,
        sessionType: sessionType,
        requiredSecurityLevel: securityLevel,
        serviceDescriptor: serviceDescriptor,
        preconditions: preconditions,
        constraints: constraints,
        recovery: recovery,
        postconditions: postconditions,
        evidenceTier: evidenceTier,
        isRevoked: isRevoked,
        revocationReason: revocationReason,
        canonicalHash: '',
      );
      final hash = unhashed.computeCanonicalHash();
      return ActiveTestProfile(
        profileId: profileId,
        schemaVersion: schemaVersion,
        version: version,
        standard: standard,
        sourceUrl: sourceUrl,
        documentSection: documentSection,
        redistributionRights: rights,
        provenanceKind: provenance,
        addressing: addressing,
        applicability: applicability,
        sessionType: sessionType,
        requiredSecurityLevel: securityLevel,
        serviceDescriptor: serviceDescriptor,
        preconditions: preconditions,
        constraints: constraints,
        recovery: recovery,
        postconditions: postconditions,
        evidenceTier: evidenceTier,
        isRevoked: isRevoked,
        revocationReason: revocationReason,
        canonicalHash: hash,
      );
    }

    test('valid Mode 08 profile passes validation and round-trips JSON', () {
      final profile = createValidMode08Profile();
      expect(profile.isValid, isTrue);
      expect(profile.validate(), isEmpty);
      expect(profile.verifyCanonicalHash(), isTrue);

      final json = profile.toJson();
      final reconstituted = ActiveTestProfile.fromJson(json);
      expect(reconstituted.profileId, profile.profileId);
      expect(reconstituted.canonicalHash, profile.canonicalHash);
      expect(reconstituted.isValid, isTrue);
    });

    test('tampered profile is rejected with hashMismatch', () {
      final profile = createValidMode08Profile();
      final tampered = ActiveTestProfile(
        profileId: profile.profileId,
        schemaVersion: profile.schemaVersion,
        version: profile.version,
        standard: profile.standard,
        sourceUrl: profile.sourceUrl,
        documentSection: profile.documentSection,
        redistributionRights: profile.redistributionRights,
        provenanceKind: profile.provenanceKind,
        addressing: profile.addressing,
        applicability: profile.applicability,
        sessionType: profile.sessionType,
        serviceDescriptor: const Mode08Descriptor(testId: 0x02), // Tampered TID!
        preconditions: profile.preconditions,
        constraints: profile.constraints,
        recovery: profile.recovery,
        evidenceTier: profile.evidenceTier,
        canonicalHash: profile.canonicalHash, // Old hash retained
      );

      expect(tampered.verifyCanonicalHash(), isFalse);
      final errors = tampered.validate();
      expect(errors, contains(ProfileValidationReason.hashMismatch));
      expect(tampered.isValid, isFalse);
    });

    test('rejects missing source URL and unreviewed rights', () {
      final profileNoSource = createValidMode08Profile(sourceUrl: '');
      expect(profileNoSource.validate(),
          contains(ProfileValidationReason.missingSourceUrl));

      final profileUnreviewedRights = createValidMode08Profile(
        rights: RedistributionRights.unreviewed,
      );
      expect(profileUnreviewedRights.validate(),
          contains(ProfileValidationReason.unreviewedRedistributionRights));
    });

    test('rejects unsupported schema version', () {
      final profileOldSchema = createValidMode08Profile(schemaVersion: 2);
      expect(profileOldSchema.validate(),
          contains(ProfileValidationReason.unknownSchemaVersion));
    });

    test('rejects wildcard ECU applicability', () {
      final profileWildcardMake = createValidMode08Profile(
        applicability: const EcuApplicability(
          make: '*',
          model: 'Prius',
          targetEcuName: 'ECM',
          softwareVersions: ['V1'],
        ),
      );
      expect(profileWildcardMake.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileWildcardModel = createValidMode08Profile(
        applicability: const EcuApplicability(
          make: 'Toyota',
          model: 'ALL',
          targetEcuName: 'ECM',
          softwareVersions: ['V1'],
        ),
      );
      expect(profileWildcardModel.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileWildcardEcu = createValidMode08Profile(
        applicability: const EcuApplicability(
          make: 'Toyota',
          model: 'Prius',
          targetEcuName: 'ANY',
          softwareVersions: ['V1'],
        ),
      );
      expect(profileWildcardEcu.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));
    });

    test('rejects wildcard or broadcast addressing', () {
      final profileBroadcastHeader = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7DF', // Broadcast request header!
          expectedResponseHeader: '7E8',
        ),
      );
      expect(profileBroadcastHeader.validate(),
          contains(ProfileValidationReason.wildcardAddressing));

      final profileWildcardHeader = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '*',
          expectedResponseHeader: '7E8',
        ),
      );
      expect(profileWildcardHeader.validate(),
          contains(ProfileValidationReason.wildcardAddressing));
    });

    test('rejects missing preconditions', () {
      final profileNoPreconditions = createValidMode08Profile(
        preconditions: const [],
      );
      expect(profileNoPreconditions.validate(),
          contains(ProfileValidationReason.missingPreconditions));
    });

    test('rejects out of range Mode 08 TID and invalid parameters', () {
      final profileZeroTid = createValidMode08Profile(
        serviceDescriptor: const Mode08Descriptor(testId: 0x00),
      );
      expect(profileZeroTid.validate(),
          contains(ProfileValidationReason.outOfRangeParameter));

      final profileOversizeTid = createValidMode08Profile(
        serviceDescriptor: const Mode08Descriptor(testId: 0xFF),
      );
      expect(profileOversizeTid.validate(),
          contains(ProfileValidationReason.outOfRangeParameter));
    });

    test('valid UDS 0x2F IO control profile passes and validates return control',
        () {
      const unhashed = ActiveTestProfile(
        profileId: 'synthetic_uds_2f_fan_control',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 11.2 InputOutputControlByIdentifier',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7E0',
          expectedResponseHeader: '7E8',
        ),
        applicability: EcuApplicability(
          make: 'Synthetic',
          model: 'BenchSim',
          targetEcuName: 'ECM',
          softwareVersions: ['SIM_V1'],
        ),
        sessionType: DiagnosticSessionType.extendedDiagnosticSession,
        serviceDescriptor: UdsIoControlDescriptor(
          dataIdentifier: 0x0112,
          controlParameter: UdsIoControlParameter.shortTermAdjustment,
          controlStates: [
            ActiveTestParameterDefinition(
              name: 'fanSpeedDutyCycle',
              byteOffset: 0,
              byteLength: 1,
              minPhysicalValue: 0,
              maxPhysicalValue: 100,
              unit: '%',
            ),
          ],
          returnControlParameter: UdsIoControlParameter.returnControlToECU,
        ),
        preconditions: [
          PreconditionRule(
            parameterName: 'vehicleSpeedKmh',
            minValue: 0,
            maxValue: 0,
          ),
          PreconditionRule(
            parameterName: 'engineRpm',
            minValue: 0,
            maxValue: 0,
          ),
        ],
        constraints: ExecutionConstraints(
          maxCommands: 3,
          minCommandIntervalMs: 100,
          stepTimeoutMs: 2000,
          overallTimeoutMs: 8000,
        ),
        recovery: RecoverySpecification(
          releaseCommandDescription: 'Send 2F 01 12 00 (returnControlToECU)',
          lossOfClientBehavior: 'ECU resets to automatic fan control after 2000ms',
          watchdogTimeoutMs: 2000,
        ),
        evidenceTier: EvidenceQualificationTier.syntheticFixture,
        canonicalHash: '',
      );

      final hash = unhashed.computeCanonicalHash();
      final profile = ActiveTestProfile(
        profileId: unhashed.profileId,
        schemaVersion: unhashed.schemaVersion,
        version: unhashed.version,
        standard: unhashed.standard,
        sourceUrl: unhashed.sourceUrl,
        documentSection: unhashed.documentSection,
        redistributionRights: unhashed.redistributionRights,
        provenanceKind: unhashed.provenanceKind,
        addressing: unhashed.addressing,
        applicability: unhashed.applicability,
        sessionType: unhashed.sessionType,
        serviceDescriptor: unhashed.serviceDescriptor,
        preconditions: unhashed.preconditions,
        constraints: unhashed.constraints,
        recovery: unhashed.recovery,
        evidenceTier: unhashed.evidenceTier,
        canonicalHash: hash,
      );

      expect(profile.isValid, isTrue);
      expect(profile.verifyCanonicalHash(), isTrue);
    });

    test('valid UDS 0x31 routine descriptor passes and validates stop command',
        () {
      const unhashed = ActiveTestProfile(
        profileId: 'synthetic_uds_31_pump_routine',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 12.2 RoutineControl',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7E0',
          expectedResponseHeader: '7E8',
        ),
        applicability: EcuApplicability(
          make: 'Synthetic',
          model: 'BenchSim',
          targetEcuName: 'ECM',
          softwareVersions: ['SIM_V1'],
        ),
        sessionType: DiagnosticSessionType.extendedDiagnosticSession,
        serviceDescriptor: UdsRoutineDescriptor(
          routineIdentifier: 0x0201,
          supportedSubfunctions: [
            UdsRoutineControlType.startRoutine,
            UdsRoutineControlType.stopRoutine,
            UdsRoutineControlType.requestRoutineResults,
          ],
          hasDocumentedStop: true,
        ),
        preconditions: [
          PreconditionRule(
            parameterName: 'vehicleSpeedKmh',
            minValue: 0,
            maxValue: 0,
          ),
        ],
        constraints: ExecutionConstraints(
          maxCommands: 4,
          minCommandIntervalMs: 150,
          stepTimeoutMs: 3000,
          overallTimeoutMs: 10000,
        ),
        recovery: RecoverySpecification(
          releaseCommandDescription: 'Send 31 02 02 01 (stopRoutine)',
          lossOfClientBehavior: 'ECU stops pump after 1500ms watchdog expiry',
          watchdogTimeoutMs: 1500,
        ),
        evidenceTier: EvidenceQualificationTier.syntheticFixture,
        canonicalHash: '',
      );

      final hash = unhashed.computeCanonicalHash();
      final profile = ActiveTestProfile(
        profileId: unhashed.profileId,
        schemaVersion: unhashed.schemaVersion,
        version: unhashed.version,
        standard: unhashed.standard,
        sourceUrl: unhashed.sourceUrl,
        documentSection: unhashed.documentSection,
        redistributionRights: unhashed.redistributionRights,
        provenanceKind: unhashed.provenanceKind,
        addressing: unhashed.addressing,
        applicability: unhashed.applicability,
        sessionType: unhashed.sessionType,
        serviceDescriptor: unhashed.serviceDescriptor,
        preconditions: unhashed.preconditions,
        constraints: unhashed.constraints,
        recovery: unhashed.recovery,
        evidenceTier: unhashed.evidenceTier,
        canonicalHash: hash,
      );

      expect(profile.isValid, isTrue);
      expect(profile.verifyCanonicalHash(), isTrue);
    });

    test('rejects UDS routine without start subfunction or stop recovery', () {
      const unhashedNoStart = ActiveTestProfile(
        profileId: 'synthetic_uds_31_no_start',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 12.2',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7E0',
          expectedResponseHeader: '7E8',
        ),
        applicability: EcuApplicability(
          make: 'Synthetic',
          model: 'BenchSim',
          targetEcuName: 'ECM',
          softwareVersions: ['SIM_V1'],
        ),
        sessionType: DiagnosticSessionType.extendedDiagnosticSession,
        serviceDescriptor: UdsRoutineDescriptor(
          routineIdentifier: 0x0201,
          supportedSubfunctions: [
            UdsRoutineControlType.requestRoutineResults, // Missing startRoutine!
          ],
          hasDocumentedStop: true,
        ),
        preconditions: [
          PreconditionRule(
            parameterName: 'vehicleSpeedKmh',
            minValue: 0,
            maxValue: 0,
          ),
        ],
        constraints: ExecutionConstraints(),
        recovery: RecoverySpecification(
          releaseCommandDescription: 'stop',
          lossOfClientBehavior: 'timeout',
          watchdogTimeoutMs: 1000,
        ),
        evidenceTier: EvidenceQualificationTier.syntheticFixture,
        canonicalHash: '',
      );
      final hash = unhashedNoStart.computeCanonicalHash();
      final profile = ActiveTestProfile(
        profileId: unhashedNoStart.profileId,
        schemaVersion: unhashedNoStart.schemaVersion,
        version: unhashedNoStart.version,
        standard: unhashedNoStart.standard,
        sourceUrl: unhashedNoStart.sourceUrl,
        documentSection: unhashedNoStart.documentSection,
        redistributionRights: unhashedNoStart.redistributionRights,
        provenanceKind: unhashedNoStart.provenanceKind,
        addressing: unhashedNoStart.addressing,
        applicability: unhashedNoStart.applicability,
        sessionType: unhashedNoStart.sessionType,
        serviceDescriptor: unhashedNoStart.serviceDescriptor,
        preconditions: unhashedNoStart.preconditions,
        constraints: unhashedNoStart.constraints,
        recovery: unhashedNoStart.recovery,
        evidenceTier: unhashedNoStart.evidenceTier,
        canonicalHash: hash,
      );

      expect(profile.validate(),
          contains(ProfileValidationReason.missingServiceDescriptor));
    });
  });
}
