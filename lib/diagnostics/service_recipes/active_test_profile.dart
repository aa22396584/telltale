/// Versioned, declarative, immutable active-test profile schema and descriptors.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25.
///
/// Designed to fail closed:
/// - Rejects missing source URL or unreviewed redistribution rights.
/// - Rejects unknown schema versions.
/// - Rejects wildcard ECU or addressing patterns.
/// - Rejects out-of-range parameters or unbounded steps.
/// - Rejects undocumented recovery specifications.
/// - Rejects canonical hash tampering.
/// - Rejects synthetic/demo fixtures from production execution.
library;

import 'dart:convert';

import '../../obd/powertrain_battery/powertrain_battery_catalog.dart';

/// Supported diagnostic standards for active test recipes.
enum StandardFamily {
  saeJ1979,
  iso14229Uds,
  custom,
}

/// Physical bus addressing type.
enum BusAddressingType {
  can11Bit,
  can29Bit,
  iso9141Kwp,
}

/// Legal redistribution and usage rights review status.
enum RedistributionRights {
  openPublicStandard,
  oemAuthorizedRedistribution,
  syntheticFixtureOnly,
  unreviewed,
}

/// Provenance of the active test specification.
enum ProvenanceKind {
  officialStandard,
  oemDocumentation,
  syntheticFixture,
}

/// Diagnostic session required on the ECU before executing.
enum DiagnosticSessionType {
  defaultSession(0x01),
  programmingSession(0x02),
  extendedDiagnosticSession(0x03),
  safetySystemDiagnosticSession(0x04);

  const DiagnosticSessionType(this.typeByte);
  final int typeByte;
}

/// Rules governing provenance of precondition measurements.
enum PreconditionSourceRule {
  /// Must be fresh live ECU data, never synthetic/demo/replayed/user-entered.
  liveEcuOnly,
}

/// Qualification tier for active test evidence.
enum EvidenceQualificationTier {
  /// Pure synthetic fixture for simulation/testing only.
  syntheticFixture,

  /// Lacks reviewed authoritative source document or redistribution rights.
  needsSource,

  /// Source reviewed, but requires physical bench qualification.
  needsBench,

  /// Qualified on a physical test bench.
  benchQualified,

  /// Qualified on an identified physical vehicle.
  vehicleQualified,
}

/// UDS 0x2F InputOutputControlParameter definitions.
enum UdsIoControlParameter {
  returnControlToECU(0x00),
  resetToDefault(0x01),
  freezeCurrentState(0x02),
  shortTermAdjustment(0x03);

  const UdsIoControlParameter(this.parameterByte);
  final int parameterByte;

  static UdsIoControlParameter? fromByte(int byte) {
    for (final val in values) {
      if (val.parameterByte == byte) return val;
    }
    return null;
  }
}

/// UDS 0x31 RoutineControlType subfunctions.
enum UdsRoutineControlType {
  startRoutine(0x01),
  stopRoutine(0x02),
  requestRoutineResults(0x03);

  const UdsRoutineControlType(this.subfunctionByte);
  final int subfunctionByte;

  static UdsRoutineControlType? fromByte(int byte) {
    for (final val in values) {
      if (val.subfunctionByte == byte) return val;
    }
    return null;
  }
}

/// Actionable reasons why an active-test profile fails schema validation.
enum ProfileValidationReason {
  missingProfileId,
  missingStandard,
  missingSourceUrl,
  unreviewedRedistributionRights,
  unknownSchemaVersion,
  wildcardEcuMatch,
  wildcardAddressing,
  outOfRangeParameter,
  unboundedSteps,
  undocumentedRecovery,
  hashMismatch,
  missingPreconditions,
  missingServiceDescriptor,
  invalidParameterDefinition,
  invalidTimeout,
  disallowedSyntheticInProduction,
}

/// Physical CAN/bus addressing parameters for an active test.
final class TransportAddressing {
  const TransportAddressing({
    required this.busType,
    required this.targetEcuHeader,
    required this.expectedResponseHeader,
  });

  factory TransportAddressing.fromJson(Map<String, dynamic> json) {
    return TransportAddressing(
      busType: BusAddressingType.values.byName(json['bus_type'] as String),
      targetEcuHeader: (json['target_ecu_header'] as String).trim(),
      expectedResponseHeader:
          (json['expected_response_header'] as String).trim(),
    );
  }

  final BusAddressingType busType;
  final String targetEcuHeader;
  final String expectedResponseHeader;

  bool get isWildcard {
    final t = targetEcuHeader.toUpperCase();
    final r = expectedResponseHeader.toUpperCase();
    if (t.isEmpty || r.isEmpty) return true;
    if (t == '*' || r == '*') return true;
    if (t == 'ANY' || r == 'ANY') return true;
    if (t == 'BROADCAST' || r == 'BROADCAST') return true;
    if (t == '7DF') return true; // Standard OBD broadcast request header
    return false;
  }

  Map<String, dynamic> toJson() => {
        'bus_type': busType.name,
        'target_ecu_header': targetEcuHeader,
        'expected_response_header': expectedResponseHeader,
      };
}

/// Exact ECU and software applicability specification.
final class EcuApplicability {
  const EcuApplicability({
    required this.make,
    required this.model,
    required this.targetEcuName,
    required this.softwareVersions,
  });

  factory EcuApplicability.fromJson(Map<String, dynamic> json) {
    return EcuApplicability(
      make: (json['make'] as String).trim(),
      model: (json['model'] as String).trim(),
      targetEcuName: (json['target_ecu_name'] as String).trim(),
      softwareVersions: (json['software_versions'] as List<dynamic>)
          .map((e) => (e as String).trim())
          .toList(growable: false),
    );
  }

  final String make;
  final String model;
  final String targetEcuName;
  final List<String> softwareVersions;

  bool get hasWildcard {
    if (make.isEmpty || model.isEmpty || targetEcuName.isEmpty) return true;
    final m = make.toUpperCase();
    final mod = model.toUpperCase();
    final ecu = targetEcuName.toUpperCase();
    if (m == '*' || m == 'ALL' || m == 'ANY') return true;
    if (mod == '*' || mod == 'ALL' || mod == 'ANY') return true;
    if (ecu == '*' || ecu == 'ALL' || ecu == 'ANY') return true;
    for (final sw in softwareVersions) {
      final s = sw.toUpperCase();
      if (s == '*' || s == 'ALL' || s == 'ANY') return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'target_ecu_name': targetEcuName,
        'software_versions': softwareVersions,
      };
}

/// Typed parameter definition within a command payload.
final class ActiveTestParameterDefinition {
  const ActiveTestParameterDefinition({
    required this.name,
    required this.byteOffset,
    required this.byteLength,
    this.minPhysicalValue,
    this.maxPhysicalValue,
    this.unit,
    this.allowedDiscreteValues,
  });

  factory ActiveTestParameterDefinition.fromJson(Map<String, dynamic> json) {
    return ActiveTestParameterDefinition(
      name: json['name'] as String,
      byteOffset: json['byte_offset'] as int,
      byteLength: json['byte_length'] as int,
      minPhysicalValue: json['min_physical_value'] as num?,
      maxPhysicalValue: json['max_physical_value'] as num?,
      unit: json['unit'] as String?,
      allowedDiscreteValues:
          (json['allowed_discrete_values'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList(growable: false),
    );
  }

  final String name;
  final int byteOffset;
  final int byteLength;
  final num? minPhysicalValue;
  final num? maxPhysicalValue;
  final String? unit;
  final List<int>? allowedDiscreteValues;

  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (byteOffset < 0 || byteLength <= 0 || byteLength > 8) return false;
    if (minPhysicalValue != null &&
        maxPhysicalValue != null &&
        minPhysicalValue! > maxPhysicalValue!) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'byte_offset': byteOffset,
        'byte_length': byteLength,
        if (minPhysicalValue != null) 'min_physical_value': minPhysicalValue,
        if (maxPhysicalValue != null) 'max_physical_value': maxPhysicalValue,
        if (unit != null) 'unit': unit,
        if (allowedDiscreteValues != null)
          'allowed_discrete_values': allowedDiscreteValues,
      };
}

/// Sealed service descriptor for active test commands.
sealed class ServiceDescriptor {
  const ServiceDescriptor();

  factory ServiceDescriptor.fromJson(Map<String, dynamic> json) {
    final type = json['descriptor_type'] as String;
    switch (type) {
      case 'mode08':
        return Mode08Descriptor.fromJson(json);
      case 'uds_io_control':
        return UdsIoControlDescriptor.fromJson(json);
      case 'uds_routine':
        return UdsRoutineDescriptor.fromJson(json);
      default:
        throw FormatException('Unknown service descriptor type: $type');
    }
  }

  Map<String, dynamic> toJson();
  List<ProfileValidationReason> validate();
}

/// Mode 08 descriptor for standardized OBD on-board system control.
final class Mode08Descriptor extends ServiceDescriptor {
  const Mode08Descriptor({
    required this.testId,
    this.parameters = const [],
    this.expectedResponseBytes = 1,
  });

  factory Mode08Descriptor.fromJson(Map<String, dynamic> json) {
    return Mode08Descriptor(
      testId: json['test_id'] as int,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ActiveTestParameterDefinition.fromJson(
                  e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      expectedResponseBytes: json['expected_response_bytes'] as int? ?? 1,
    );
  }

  final int testId;
  final List<ActiveTestParameterDefinition> parameters;
  final int expectedResponseBytes;

  @override
  List<ProfileValidationReason> validate() {
    final errors = <ProfileValidationReason>[];
    if (testId <= 0x00 || testId >= 0xFF) {
      errors.add(ProfileValidationReason.outOfRangeParameter);
    }
    for (final param in parameters) {
      if (!param.isValid) {
        errors.add(ProfileValidationReason.invalidParameterDefinition);
      }
    }
    if (expectedResponseBytes < 0 || expectedResponseBytes > 64) {
      errors.add(ProfileValidationReason.outOfRangeParameter);
    }
    return errors;
  }

  @override
  Map<String, dynamic> toJson() => {
        'descriptor_type': 'mode08',
        'test_id': testId,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'expected_response_bytes': expectedResponseBytes,
      };
}

/// UDS 0x2F InputOutputControlByIdentifier descriptor.
final class UdsIoControlDescriptor extends ServiceDescriptor {
  const UdsIoControlDescriptor({
    required this.dataIdentifier,
    required this.controlParameter,
    this.controlStates = const [],
    this.controlEnableMask,
    required this.returnControlParameter,
  });

  factory UdsIoControlDescriptor.fromJson(Map<String, dynamic> json) {
    return UdsIoControlDescriptor(
      dataIdentifier: json['data_identifier'] as int,
      controlParameter: UdsIoControlParameter.values
          .byName(json['control_parameter'] as String),
      controlStates: (json['control_states'] as List<dynamic>?)
              ?.map((e) => ActiveTestParameterDefinition.fromJson(
                  e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      controlEnableMask: json['control_enable_mask'] as int?,
      returnControlParameter: UdsIoControlParameter.values
          .byName(json['return_control_parameter'] as String),
    );
  }

  final int dataIdentifier;
  final UdsIoControlParameter controlParameter;
  final List<ActiveTestParameterDefinition> controlStates;
  final int? controlEnableMask;
  final UdsIoControlParameter returnControlParameter;

  @override
  List<ProfileValidationReason> validate() {
    final errors = <ProfileValidationReason>[];
    if (dataIdentifier < 0x0000 || dataIdentifier > 0xFFFF) {
      errors.add(ProfileValidationReason.outOfRangeParameter);
    }
    if (returnControlParameter != UdsIoControlParameter.returnControlToECU &&
        returnControlParameter != UdsIoControlParameter.resetToDefault) {
      errors.add(ProfileValidationReason.undocumentedRecovery);
    }
    for (final cs in controlStates) {
      if (!cs.isValid) {
        errors.add(ProfileValidationReason.invalidParameterDefinition);
      }
    }
    return errors;
  }

  @override
  Map<String, dynamic> toJson() => {
        'descriptor_type': 'uds_io_control',
        'data_identifier': dataIdentifier,
        'control_parameter': controlParameter.name,
        'control_states': controlStates.map((cs) => cs.toJson()).toList(),
        if (controlEnableMask != null)
          'control_enable_mask': controlEnableMask,
        'return_control_parameter': returnControlParameter.name,
      };
}

/// UDS 0x31 RoutineControl descriptor.
final class UdsRoutineDescriptor extends ServiceDescriptor {
  const UdsRoutineDescriptor({
    required this.routineIdentifier,
    required this.supportedSubfunctions,
    this.startOptionParameters = const [],
    required this.hasDocumentedStop,
  });

  factory UdsRoutineDescriptor.fromJson(Map<String, dynamic> json) {
    return UdsRoutineDescriptor(
      routineIdentifier: json['routine_identifier'] as int,
      supportedSubfunctions: (json['supported_subfunctions'] as List<dynamic>)
          .map((e) => UdsRoutineControlType.values.byName(e as String))
          .toList(growable: false),
      startOptionParameters: (json['start_option_parameters']
                  as List<dynamic>?)
              ?.map((e) => ActiveTestParameterDefinition.fromJson(
                  e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      hasDocumentedStop: json['has_documented_stop'] as bool,
    );
  }

  final int routineIdentifier;
  final List<UdsRoutineControlType> supportedSubfunctions;
  final List<ActiveTestParameterDefinition> startOptionParameters;
  final bool hasDocumentedStop;

  @override
  List<ProfileValidationReason> validate() {
    final errors = <ProfileValidationReason>[];
    if (routineIdentifier < 0x0000 || routineIdentifier > 0xFFFF) {
      errors.add(ProfileValidationReason.outOfRangeParameter);
    }
    if (!supportedSubfunctions.contains(UdsRoutineControlType.startRoutine)) {
      errors.add(ProfileValidationReason.missingServiceDescriptor);
    }
    if (!hasDocumentedStop &&
        !supportedSubfunctions.contains(UdsRoutineControlType.stopRoutine)) {
      errors.add(ProfileValidationReason.undocumentedRecovery);
    }
    for (final param in startOptionParameters) {
      if (!param.isValid) {
        errors.add(ProfileValidationReason.invalidParameterDefinition);
      }
    }
    return errors;
  }

  @override
  Map<String, dynamic> toJson() => {
        'descriptor_type': 'uds_routine',
        'routine_identifier': routineIdentifier,
        'supported_subfunctions':
            supportedSubfunctions.map((s) => s.name).toList(),
        'start_option_parameters':
            startOptionParameters.map((p) => p.toJson()).toList(),
        'has_documented_stop': hasDocumentedStop,
      };
}

/// Measurable precondition rule that must hold before actuation.
final class PreconditionRule {
  const PreconditionRule({
    required this.parameterName,
    this.minValue,
    this.maxValue,
    this.expectedDiscreteValue,
    this.maxAgeMs = 2000,
    this.sourceRule = PreconditionSourceRule.liveEcuOnly,
  });

  factory PreconditionRule.fromJson(Map<String, dynamic> json) {
    return PreconditionRule(
      parameterName: json['parameter_name'] as String,
      minValue: json['min_value'] as num?,
      maxValue: json['max_value'] as num?,
      expectedDiscreteValue: json['expected_discrete_value'],
      maxAgeMs: json['max_age_ms'] as int? ?? 2000,
      sourceRule: PreconditionSourceRule.values
          .byName(json['source_rule'] as String? ?? 'liveEcuOnly'),
    );
  }

  final String parameterName;
  final num? minValue;
  final num? maxValue;
  final dynamic expectedDiscreteValue;
  final int maxAgeMs;
  final PreconditionSourceRule sourceRule;

  bool get isValid {
    if (parameterName.trim().isEmpty) return false;
    if (maxAgeMs <= 0 || maxAgeMs > 10000) return false;
    if (minValue != null && maxValue != null && minValue! > maxValue!) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'parameter_name': parameterName,
        if (minValue != null) 'min_value': minValue,
        if (maxValue != null) 'max_value': maxValue,
        if (expectedDiscreteValue != null)
          'expected_discrete_value': expectedDiscreteValue,
        'max_age_ms': maxAgeMs,
        'source_rule': sourceRule.name,
      };
}

/// Independently observable postcondition rule after actuation finishes.
final class PostconditionRule {
  const PostconditionRule({
    required this.parameterName,
    this.expectedMinValue,
    this.expectedMaxValue,
    this.expectedValue,
    required this.verificationDescription,
  });

  factory PostconditionRule.fromJson(Map<String, dynamic> json) {
    return PostconditionRule(
      parameterName: json['parameter_name'] as String,
      expectedMinValue: json['expected_min_value'] as num?,
      expectedMaxValue: json['expected_max_value'] as num?,
      expectedValue: json['expected_value'],
      verificationDescription: json['verification_description'] as String,
    );
  }

  final String parameterName;
  final num? expectedMinValue;
  final num? expectedMaxValue;
  final dynamic expectedValue;
  final String verificationDescription;

  bool get isValid {
    if (parameterName.trim().isEmpty) return false;
    if (verificationDescription.trim().isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'parameter_name': parameterName,
        if (expectedMinValue != null) 'expected_min_value': expectedMinValue,
        if (expectedMaxValue != null) 'expected_max_value': expectedMaxValue,
        if (expectedValue != null) 'expected_value': expectedValue,
        'verification_description': verificationDescription,
      };
}

/// Bounded execution constraints preventing runaway loops or unbounded waits.
final class ExecutionConstraints {
  const ExecutionConstraints({
    this.maxCommands = 5,
    this.minCommandIntervalMs = 100,
    this.stepTimeoutMs = 2000,
    this.overallTimeoutMs = 10000,
  });

  factory ExecutionConstraints.fromJson(Map<String, dynamic> json) {
    return ExecutionConstraints(
      maxCommands: json['max_commands'] as int? ?? 5,
      minCommandIntervalMs: json['min_command_interval_ms'] as int? ?? 100,
      stepTimeoutMs: json['step_timeout_ms'] as int? ?? 2000,
      overallTimeoutMs: json['overall_timeout_ms'] as int? ?? 10000,
    );
  }

  final int maxCommands;
  final int minCommandIntervalMs;
  final int stepTimeoutMs;
  final int overallTimeoutMs;

  bool get isValid {
    if (maxCommands <= 0 || maxCommands > 20) return false;
    if (minCommandIntervalMs < 50) return false;
    if (stepTimeoutMs <= 0 || stepTimeoutMs > 10000) return false;
    if (overallTimeoutMs <= 0 || overallTimeoutMs > 60000) return false;
    if (stepTimeoutMs > overallTimeoutMs) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'max_commands': maxCommands,
        'min_command_interval_ms': minCommandIntervalMs,
        'step_timeout_ms': stepTimeoutMs,
        'overall_timeout_ms': overallTimeoutMs,
      };
}

/// Documented release, stop, and loss-of-client recovery specification.
final class RecoverySpecification {
  const RecoverySpecification({
    required this.releaseCommandDescription,
    required this.lossOfClientBehavior,
    required this.watchdogTimeoutMs,
  });

  factory RecoverySpecification.fromJson(Map<String, dynamic> json) {
    return RecoverySpecification(
      releaseCommandDescription:
          (json['release_command_description'] as String).trim(),
      lossOfClientBehavior:
          (json['loss_of_client_behavior'] as String).trim(),
      watchdogTimeoutMs: json['watchdog_timeout_ms'] as int,
    );
  }

  final String releaseCommandDescription;
  final String lossOfClientBehavior;
  final int watchdogTimeoutMs;

  bool get isValid {
    if (releaseCommandDescription.isEmpty) return false;
    if (lossOfClientBehavior.isEmpty) return false;
    if (watchdogTimeoutMs <= 0 || watchdogTimeoutMs > 30000) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'release_command_description': releaseCommandDescription,
        'loss_of_client_behavior': lossOfClientBehavior,
        'watchdog_timeout_ms': watchdogTimeoutMs,
      };
}

/// Immutable, declarative active-test profile.
final class ActiveTestProfile {
  const ActiveTestProfile({
    required this.profileId,
    this.schemaVersion = 1,
    required this.version,
    required this.standard,
    required this.sourceUrl,
    required this.documentSection,
    required this.redistributionRights,
    required this.provenanceKind,
    required this.addressing,
    required this.applicability,
    required this.sessionType,
    this.requiredSecurityLevel,
    required this.serviceDescriptor,
    required this.preconditions,
    required this.constraints,
    required this.recovery,
    this.postconditions = const [],
    required this.evidenceTier,
    this.isRevoked = false,
    this.revocationReason,
    required this.canonicalHash,
  });

  factory ActiveTestProfile.fromJson(Map<String, dynamic> json) {
    return ActiveTestProfile(
      profileId: (json['profile_id'] as String).trim(),
      schemaVersion: json['schema_version'] as int? ?? 1,
      version: (json['version'] as String).trim(),
      standard: (json['standard'] as String).trim(),
      sourceUrl: (json['source_url'] as String).trim(),
      documentSection: (json['document_section'] as String).trim(),
      redistributionRights: RedistributionRights.values
          .byName(json['redistribution_rights'] as String),
      provenanceKind:
          ProvenanceKind.values.byName(json['provenance_kind'] as String),
      addressing: TransportAddressing.fromJson(
          json['addressing'] as Map<String, dynamic>),
      applicability: EcuApplicability.fromJson(
          json['applicability'] as Map<String, dynamic>),
      sessionType: DiagnosticSessionType.values
          .byName(json['session_type'] as String),
      requiredSecurityLevel: json['required_security_level'] as int?,
      serviceDescriptor: ServiceDescriptor.fromJson(
          json['service_descriptor'] as Map<String, dynamic>),
      preconditions: (json['preconditions'] as List<dynamic>)
          .map((e) => PreconditionRule.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      constraints: ExecutionConstraints.fromJson(
          json['constraints'] as Map<String, dynamic>),
      recovery: RecoverySpecification.fromJson(
          json['recovery'] as Map<String, dynamic>),
      postconditions: (json['postconditions'] as List<dynamic>?)
              ?.map((e) =>
                  PostconditionRule.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      evidenceTier: EvidenceQualificationTier.values
          .byName(json['evidence_tier'] as String),
      isRevoked: json['is_revoked'] as bool? ?? false,
      revocationReason: json['revocation_reason'] as String?,
      canonicalHash: (json['canonical_hash'] as String).trim(),
    );
  }

  final String profileId;
  final int schemaVersion;
  final String version;
  final String standard;
  final String sourceUrl;
  final String documentSection;
  final RedistributionRights redistributionRights;
  final ProvenanceKind provenanceKind;
  final TransportAddressing addressing;
  final EcuApplicability applicability;
  final DiagnosticSessionType sessionType;
  final int? requiredSecurityLevel;
  final ServiceDescriptor serviceDescriptor;
  final List<PreconditionRule> preconditions;
  final ExecutionConstraints constraints;
  final RecoverySpecification recovery;
  final List<PostconditionRule> postconditions;
  final EvidenceQualificationTier evidenceTier;
  final bool isRevoked;
  final String? revocationReason;
  final String canonicalHash;

  /// Validates profile against all safety and schema invariants.
  List<ProfileValidationReason> validate() {
    final errors = <ProfileValidationReason>[];

    if (profileId.isEmpty) {
      errors.add(ProfileValidationReason.missingProfileId);
    }
    if (schemaVersion != 1) {
      errors.add(ProfileValidationReason.unknownSchemaVersion);
    }
    if (standard.isEmpty) {
      errors.add(ProfileValidationReason.missingStandard);
    }
    if (sourceUrl.isEmpty) {
      errors.add(ProfileValidationReason.missingSourceUrl);
    }
    if (redistributionRights == RedistributionRights.unreviewed) {
      errors.add(ProfileValidationReason.unreviewedRedistributionRights);
    }
    if (addressing.isWildcard) {
      errors.add(ProfileValidationReason.wildcardAddressing);
    }
    if (applicability.hasWildcard) {
      errors.add(ProfileValidationReason.wildcardEcuMatch);
    }
    if (preconditions.isEmpty) {
      errors.add(ProfileValidationReason.missingPreconditions);
    }
    for (final pre in preconditions) {
      if (!pre.isValid) {
        errors.add(ProfileValidationReason.invalidParameterDefinition);
      }
    }
    if (!constraints.isValid) {
      errors.add(ProfileValidationReason.unboundedSteps);
    }
    if (!recovery.isValid) {
      errors.add(ProfileValidationReason.undocumentedRecovery);
    }
    for (final post in postconditions) {
      if (!post.isValid) {
        errors.add(ProfileValidationReason.invalidParameterDefinition);
      }
    }

    errors.addAll(serviceDescriptor.validate());

    if (!verifyCanonicalHash()) {
      errors.add(ProfileValidationReason.hashMismatch);
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Serializes into a canonical map without the hash itself.
  Map<String, dynamic> toCanonicalMap() => {
        'profile_id': profileId,
        'schema_version': schemaVersion,
        'version': version,
        'standard': standard,
        'source_url': sourceUrl,
        'document_section': documentSection,
        'redistribution_rights': redistributionRights.name,
        'provenance_kind': provenanceKind.name,
        'addressing': addressing.toJson(),
        'applicability': applicability.toJson(),
        'session_type': sessionType.name,
        if (requiredSecurityLevel != null)
          'required_security_level': requiredSecurityLevel,
        'service_descriptor': serviceDescriptor.toJson(),
        'preconditions': preconditions.map((p) => p.toJson()).toList(),
        'constraints': constraints.toJson(),
        'recovery': recovery.toJson(),
        'postconditions': postconditions.map((p) => p.toJson()).toList(),
        'evidence_tier': evidenceTier.name,
        'is_revoked': isRevoked,
        if (revocationReason != null) 'revocation_reason': revocationReason,
      };

  /// Computes canonical SHA-256 hash over canonical JSON encoding.
  String computeCanonicalHash() {
    final canonicalJson = jsonEncode(toCanonicalMap());
    return PowertrainBatteryCatalogAsset.sha256Hex(utf8.encode(canonicalJson));
  }

  /// Verifies that canonicalHash matches computed hash.
  bool verifyCanonicalHash() {
    return computeCanonicalHash() == canonicalHash;
  }

  Map<String, dynamic> toJson() => {
        ...toCanonicalMap(),
        'canonical_hash': canonicalHash,
      };
}
