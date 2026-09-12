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
      EcuApplicability applicability = const EcuApplicability.constant(
        make: 'Synthetic',
        model: 'BenchSim',
        targetEcuName: 'ECM',
        softwareVersions: ['SIM_V1'],
      ),
      DiagnosticSessionType sessionType = DiagnosticSessionType.defaultSession,
      int? securityLevel,
      ServiceDescriptor serviceDescriptor = const Mode08Descriptor.constant(
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
        serviceDescriptor: Mode08Descriptor(testId: 0x02), // Tampered TID!
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
        applicability: EcuApplicability(
          make: '*',
          model: 'Prius',
          targetEcuName: 'ECM',
          softwareVersions: const ['V1'],
        ),
      );
      expect(profileWildcardMake.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileWildcardModel = createValidMode08Profile(
        applicability: EcuApplicability(
          make: 'Toyota',
          model: 'ALL',
          targetEcuName: 'ECM',
          softwareVersions: const ['V1'],
        ),
      );
      expect(profileWildcardModel.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileWildcardEcu = createValidMode08Profile(
        applicability: EcuApplicability(
          make: 'Toyota',
          model: 'Prius',
          targetEcuName: 'ANY',
          softwareVersions: const ['V1'],
        ),
      );
      expect(profileWildcardEcu.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileEmptySoftware = createValidMode08Profile(
        applicability: EcuApplicability(
          make: 'Toyota',
          model: 'Prius',
          targetEcuName: 'ECM',
          softwareVersions: const [],
        ),
      );
      expect(profileEmptySoftware.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));

      final profileEmptyVersionString = createValidMode08Profile(
        applicability: EcuApplicability(
          make: 'Toyota',
          model: 'Prius',
          targetEcuName: 'ECM',
          softwareVersions: const [''],
        ),
      );
      expect(profileEmptyVersionString.validate(),
          contains(ProfileValidationReason.wildcardEcuMatch));
    });

    test('rejects wildcard or broadcast addressing', () {
      final profileBroadcastHeader = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7DF', // Broadcast request header (11-bit)!
          expectedResponseHeader: '7E8',
        ),
      );
      expect(profileBroadcastHeader.validate(),
          contains(ProfileValidationReason.wildcardAddressing));

      final profileBroadcast29Bit = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can29Bit,
          targetEcuHeader: '18DB33F1', // Standard 29-bit functional broadcast request header!
          expectedResponseHeader: '18DAF110',
        ),
      );
      expect(profileBroadcast29Bit.validate(),
          contains(ProfileValidationReason.wildcardAddressing));

      final profileIdenticalHeaders = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7E0',
          expectedResponseHeader: '7E0', // Same arbitration ID!
        ),
      );
      expect(profileIdenticalHeaders.validate(),
          contains(ProfileValidationReason.identicalArbitrationIdConflict));

      final profileNonHexHeader = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: 'XYZ',
          expectedResponseHeader: '7E8',
        ),
      );
      expect(profileNonHexHeader.validate(),
          contains(ProfileValidationReason.wildcardAddressing));

      final profileOutOfRange11Bit = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '800', // > 0x7FF
          expectedResponseHeader: '7E8',
        ),
      );
      expect(profileOutOfRange11Bit.validate(),
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

    test('rejects missing or invalid preconditions and postconditions', () {
      final profileNoPreconditions = createValidMode08Profile(
        preconditions: const [],
      );
      expect(profileNoPreconditions.validate(),
          contains(ProfileValidationReason.missingPreconditions));

      // Precondition with no condition values
      final profileEmptyPreconditionRule = createValidMode08Profile(
        preconditions: const [
          PreconditionRule(parameterName: 'vehicleSpeedKmh'),
        ],
      );
      expect(profileEmptyPreconditionRule.validate(),
          contains(ProfileValidationReason.invalidParameterDefinition));

      // Precondition with inverted min > max
      final profileInvertedPreconditionRule = createValidMode08Profile(
        preconditions: const [
          PreconditionRule(
            parameterName: 'vehicleSpeedKmh',
            minValue: 100,
            maxValue: 10,
          ),
        ],
      );
      expect(profileInvertedPreconditionRule.validate(),
          contains(ProfileValidationReason.invalidParameterDefinition));

      // Postcondition with no expected values
      final profileEmptyPostconditionRule = createValidMode08Profile(
        postconditions: const [
          PostconditionRule(
            parameterName: 'fanSpeedRpm',
            verificationDescription: 'Fan must spin',
          ),
        ],
      );
      expect(profileEmptyPostconditionRule.validate(),
          contains(ProfileValidationReason.invalidParameterDefinition));

      // Postcondition with inverted min > max
      final profileInvertedPostconditionRule = createValidMode08Profile(
        postconditions: const [
          PostconditionRule(
            parameterName: 'fanSpeedRpm',
            expectedMinValue: 2000,
            expectedMaxValue: 1000,
            verificationDescription: 'Fan must spin in range',
          ),
        ],
      );
      expect(profileInvertedPostconditionRule.validate(),
          contains(ProfileValidationReason.invalidParameterDefinition));
    });

    test('rejects whitespace-only profile metadata fields', () {
      final profileWhitespaceId = createValidMode08Profile(profileId: '   ');
      expect(profileWhitespaceId.validate(),
          contains(ProfileValidationReason.missingProfileId));

      final profileWhitespaceStandard = createValidMode08Profile(standard: '   ');
      expect(profileWhitespaceStandard.validate(),
          contains(ProfileValidationReason.missingStandard));

      final profileWhitespaceSource = createValidMode08Profile(sourceUrl: '   ');
      expect(profileWhitespaceSource.validate(),
          contains(ProfileValidationReason.missingSourceUrl));

      final profileWhitespaceSection = createValidMode08Profile(documentSection: '   ');
      expect(profileWhitespaceSection.validate(),
          contains(ProfileValidationReason.missingSourceUrl));
    });

    test('rejects UDS 0x2F shortTermAdjustment without controlStates defined', () {
      final profileNoStates = createValidMode08Profile(
        serviceDescriptor: UdsIoControlDescriptor(
          dataIdentifier: 0x0112,
          controlParameter: UdsIoControlParameter.shortTermAdjustment,
          controlStates: const [],
          returnControlParameter: UdsIoControlParameter.returnControlToECU,
        ),
      );
      expect(profileNoStates.validate(),
          contains(ProfileValidationReason.invalidParameterDefinition));
    });

    test('rejects out of range Mode 08 TID and invalid parameters', () {
      final profileZeroTid = createValidMode08Profile(
        serviceDescriptor: Mode08Descriptor(testId: 0x00),
      );
      expect(profileZeroTid.validate(),
          contains(ProfileValidationReason.outOfRangeParameter));

      final profileOversizeTid = createValidMode08Profile(
        serviceDescriptor: Mode08Descriptor(testId: 0xFF),
      );
      expect(profileOversizeTid.validate(),
          contains(ProfileValidationReason.outOfRangeParameter));
    });

    test('valid UDS 0x2F IO control profile passes and validates return control',
        () {
      final unhashed = ActiveTestProfile(
        profileId: 'synthetic_uds_2f_fan_control',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 11.2 InputOutputControlByIdentifier',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: const TransportAddressing(
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
        preconditions: const [
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
        constraints: const ExecutionConstraints(
          maxCommands: 3,
          minCommandIntervalMs: 100,
          stepTimeoutMs: 2000,
          overallTimeoutMs: 8000,
        ),
        recovery: const RecoverySpecification(
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
      final unhashed = ActiveTestProfile(
        profileId: 'synthetic_uds_31_pump_routine',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 12.2 RoutineControl',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: const TransportAddressing(
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
        preconditions: const [
          PreconditionRule(
            parameterName: 'vehicleSpeedKmh',
            minValue: 0,
            maxValue: 0,
          ),
        ],
        constraints: const ExecutionConstraints(
          maxCommands: 4,
          minCommandIntervalMs: 150,
          stepTimeoutMs: 3000,
          overallTimeoutMs: 10000,
        ),
        recovery: const RecoverySpecification(
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
      final unhashedNoStart = ActiveTestProfile(
        profileId: 'synthetic_uds_31_no_start',
        schemaVersion: 1,
        version: '1.0.0',
        standard: 'ISO 14229-1:2013',
        sourceUrl: 'https://iso.org/standard/55283.html',
        documentSection: 'Section 12.2',
        redistributionRights: RedistributionRights.syntheticFixtureOnly,
        provenanceKind: ProvenanceKind.syntheticFixture,
        addressing: const TransportAddressing(
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

    test('normalizes CAN arbitration headers (7E0 vs 07E0) and evaluates equality', () {
      expect(
        TransportAddressing.areHeadersEquivalent(
            '7E0', '07E0', BusAddressingType.can11Bit),
        isTrue,
      );
      expect(
        TransportAddressing.areHeadersEquivalent(
            '07E0', '7E0', BusAddressingType.can11Bit),
        isTrue,
      );
      expect(
        TransportAddressing.areHeadersEquivalent(
            '18DA10F1', '018DA10F1', BusAddressingType.can29Bit),
        isTrue,
      );

      const addr1 = TransportAddressing(
        busType: BusAddressingType.can11Bit,
        targetEcuHeader: '7E0',
        expectedResponseHeader: '7E8',
      );
      const addr2 = TransportAddressing(
        busType: BusAddressingType.can11Bit,
        targetEcuHeader: '07E0',
        expectedResponseHeader: '07E8',
      );

      // Value equality holds across differently-padded representations
      expect(addr1 == addr2, isTrue);
      expect(addr1.hashCode, addr2.hashCode);
      expect(addr1.matchesTarget('07E0'), isTrue);
      expect(addr1.matchesResponse('07E8'), isTrue);

      // Rejects identical CAN arbitration IDs even when padded differently
      final addrSameId = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '7E0',
          expectedResponseHeader: '07E0', // Same physical ID!
        ),
      );
      expect(addrSameId.validate(),
          contains(ProfileValidationReason.identicalArbitrationIdConflict));
      expect(addrSameId.addressing.hasIdenticalArbitrationId, isTrue);
      expect(addrSameId.addressing.isWildcard, isFalse);

      // Rejects broadcast header with leading zeros (07DF)
      final addrPaddedBroadcast = createValidMode08Profile(
        addressing: const TransportAddressing(
          busType: BusAddressingType.can11Bit,
          targetEcuHeader: '07DF',
          expectedResponseHeader: '7E8',
        ),
      );
      expect(addrPaddedBroadcast.validate(),
          contains(ProfileValidationReason.wildcardAddressing));
      expect(addrPaddedBroadcast.addressing.hasIdenticalArbitrationId, isFalse);
      expect(addrPaddedBroadcast.addressing.isWildcard, isTrue);
    });

    test('creates defensive immutable ServiceRecipeSnapshot immune to drift during execution', () {
      final mutableSwVersions = ['SIM_V1'];
      final mutablePreconditions = [
        const PreconditionRule(
          parameterName: 'vehicleSpeedKmh',
          minValue: 0,
          maxValue: 0,
          maxAgeMs: 1000,
        ),
      ];

      final profile = createValidMode08Profile(
        applicability: EcuApplicability(
          make: 'Synthetic',
          model: 'BenchSim',
          targetEcuName: 'ECM',
          softwareVersions: mutableSwVersions,
        ),
        preconditions: mutablePreconditions,
      );

      // Take defensive snapshot before active test execution
      final snapshot = profile.toSnapshot();
      expect(snapshot.profileId, profile.profileId);
      expect(snapshot.canonicalHash, profile.canonicalHash);

      // Modifying original external list after snapshot creation has ZERO effect
      mutableSwVersions.add('MALICIOUS_V2');
      expect(snapshot.profile.applicability.softwareVersions, ['SIM_V1']);
      // Original profile was also defensively copied on creation
      expect(profile.applicability.softwareVersions, ['SIM_V1']);

      // Attempting indexed mutation throws UnsupportedError
      expect(
        () => (profile.applicability.softwareVersions as dynamic)[0] = 'MUTATED',
        throwsUnsupportedError,
      );
      expect(
        () => (profile.preconditions as dynamic)[0] = const PreconditionRule(parameterName: 'mutated'),
        throwsUnsupportedError,
      );

      // Collections in snapshot are strictly unmodifiable and cannot drift during execution
      expect(
        () => (snapshot.preconditions as dynamic).add(
          const PreconditionRule(parameterName: 'hacked'),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (snapshot.profile.applicability.softwareVersions as dynamic).add('drift'),
        throwsUnsupportedError,
      );
      expect(
        () => (snapshot.postconditions as dynamic).add(
          const PostconditionRule(
            parameterName: 'test',
            verificationDescription: 'desc',
          ),
        ),
        throwsUnsupportedError,
      );

      // Snapshot profile remains completely valid and untampered
      expect(snapshot.profile.isValid, isTrue);
      expect(snapshot.profile.verifyCanonicalHash(), isTrue);
    });
  });
}
