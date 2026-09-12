/// Bounded UDS active-test codecs for Service 0x2F and Service 0x31.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25.
///
/// Normative references:
/// - ISO 14229-1: Road vehicles — Unified diagnostic services (UDS)
///   - Service 0x2F: InputOutputControlByIdentifier
///   - Service 0x31: RoutineControl
///
/// SAFETY CONTRACT:
/// - Bounded encoding/parsing for explicitly configured 0x2F and 0x31 only.
/// - NO DID/RID enumeration.
/// - NO generic "SID + 0x40 = completed" rule: positive responses must match
///   the exact expected DID/RID, subfunction/control parameter, and length.
/// - NRC 0x78 (responsePending) is handled explicitly as a pending state,
///   distinct from terminal failure.
/// - Truncation, wrong echo, wrong SID, and corrupted bytes fail closed as malformed.
library;

import 'active_test_profile.dart';

/// Reasons why a UDS response is rejected as malformed.
enum UdsMalformedReason {
  truncated,
  invalidHex,
  invalidSid,
  wrongOriginalSid,
  wrongDidEcho,
  wrongRidEcho,
  wrongControlParameterEcho,
  wrongRoutineTypeEcho,
  wrongResponseLength,
  invalidNrc,
}

/// Sealed base class for UDS 0x2F parsing results.
sealed class UdsIoControlParseResult {
  const UdsIoControlParseResult();
}

/// Positive response for UDS 0x2F (SID 0x6F).
final class UdsIoControlSuccess extends UdsIoControlParseResult {
  const UdsIoControlSuccess({
    required this.did,
    required this.controlParameter,
    required this.controlStatusRecord,
  });

  final int did;
  final UdsIoControlParameter controlParameter;
  final List<int> controlStatusRecord;
}

/// Negative response for UDS 0x2F (`7F 2F <NRC>`).
final class UdsIoControlNegative extends UdsIoControlParseResult {
  const UdsIoControlNegative({
    required this.nrc,
    required this.isResponsePending,
  });

  final int nrc;

  /// Whether NRC is 0x78 (responsePending), requiring continued reception without re-sending.
  final bool isResponsePending;
}

/// Malformed response for UDS 0x2F.
final class UdsIoControlMalformed extends UdsIoControlParseResult {
  const UdsIoControlMalformed({
    required this.reason,
    required this.rawResponse,
  });

  final UdsMalformedReason reason;
  final String rawResponse;
}

/// Sealed base class for UDS 0x31 parsing results.
sealed class UdsRoutineParseResult {
  const UdsRoutineParseResult();
}

/// Positive response for UDS 0x31 (SID 0x71).
final class UdsRoutineSuccess extends UdsRoutineParseResult {
  const UdsRoutineSuccess({
    required this.controlType,
    required this.routineIdentifier,
    required this.routineStatusRecord,
  });

  final UdsRoutineControlType controlType;
  final int routineIdentifier;
  final List<int> routineStatusRecord;
}

/// Negative response for UDS 0x31 (`7F 31 <NRC>`).
final class UdsRoutineNegative extends UdsRoutineParseResult {
  const UdsRoutineNegative({
    required this.nrc,
    required this.isResponsePending,
  });

  final int nrc;

  /// Whether NRC is 0x78 (responsePending).
  final bool isResponsePending;
}

/// Malformed response for UDS 0x31.
final class UdsRoutineMalformed extends UdsRoutineParseResult {
  const UdsRoutineMalformed({
    required this.reason,
    required this.rawResponse,
  });

  final UdsMalformedReason reason;
  final String rawResponse;
}

/// Bounded UDS active-test protocol codecs.
final class UdsActiveCodec {
  const UdsActiveCodec._();

  static const int sidIoControl = 0x2F;
  static const int sidIoControlPositive = 0x6F;
  static const int sidRoutineControl = 0x31;
  static const int sidRoutineControlPositive = 0x71;
  static const int sidNegativeResponse = 0x7F;
  static const int nrcResponsePending = 0x78;

  // ---------------------------------------------------------------------------
  // Service 0x2F: InputOutputControlByIdentifier
  // ---------------------------------------------------------------------------

  /// Encodes a UDS 0x2F request into bytes.
  ///
  /// Control state and control mask byte lengths are decoupled and governed
  /// by [descriptor] if provided. They are not required to have identical lengths.
  static List<int> encodeIoControlRequest({
    required int did,
    required UdsIoControlParameter parameter,
    List<int> controlState = const [],
    List<int> controlMask = const [],
    UdsIoControlDescriptor? descriptor,
  }) {
    if (did < 0x0000 || did > 0xFFFF) {
      throw ArgumentError.value(did, 'did', 'DID must be 16-bit unsigned (0x0000..0xFFFF)');
    }
    for (final b in controlState) {
      if (b < 0 || b > 0xFF) {
        throw ArgumentError.value(b, 'controlState', 'Control state bytes must be 0x00..0xFF');
      }
    }
    for (final b in controlMask) {
      if (b < 0 || b > 0xFF) {
        throw ArgumentError.value(b, 'controlMask', 'Control mask bytes must be 0x00..0xFF');
      }
    }

    if (descriptor != null) {
      if (descriptor.totalControlStateBytes > 0 &&
          controlState.isNotEmpty &&
          controlState.length != descriptor.totalControlStateBytes) {
        throw ArgumentError(
          'Control state length (${controlState.length}) does not match descriptor expected length (${descriptor.totalControlStateBytes})',
        );
      }
      if (descriptor.controlMaskByteLength != null &&
          controlMask.isNotEmpty &&
          controlMask.length != descriptor.controlMaskByteLength) {
        throw ArgumentError(
          'Control mask length (${controlMask.length}) does not match descriptor expected length (${descriptor.controlMaskByteLength})',
        );
      }
    }

    final bytes = <int>[
      sidIoControl,
      (did >> 8) & 0xFF,
      did & 0xFF,
      parameter.parameterByte,
      ...controlState,
      ...controlMask,
    ];
    return bytes;
  }

  /// Encodes a UDS 0x2F request into an ASCII hex command string.
  static String encodeIoControlCommand({
    required int did,
    required UdsIoControlParameter parameter,
    List<int> controlState = const [],
    List<int> controlMask = const [],
    UdsIoControlDescriptor? descriptor,
  }) {
    final bytes = encodeIoControlRequest(
      did: did,
      parameter: parameter,
      controlState: controlState,
      controlMask: controlMask,
      descriptor: descriptor,
    );
    return _toHex(bytes);
  }

  /// Parses a raw response string for a UDS 0x2F request.
  ///
  /// Enforces exact DID and control parameter echo checks.
  /// Generic "SID + 0x40" responses with wrong DID or truncated payloads are rejected.
  static UdsIoControlParseResult parseIoControlResponse(
    String rawResponse, {
    required int expectedDid,
    required UdsIoControlParameter expectedParameter,
    int? expectedResponseBytes,
    UdsIoControlDescriptor? descriptor,
  }) {
    final bytes = _parseHex(rawResponse);
    if (bytes == null) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.invalidHex,
        rawResponse: rawResponse,
      );
    }

    if (bytes.isEmpty) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.truncated,
        rawResponse: rawResponse,
      );
    }

    // Negative response: 7F 2F <NRC>
    if (bytes[0] == sidNegativeResponse) {
      if (bytes.length < 3) {
        return UdsIoControlMalformed(
          reason: UdsMalformedReason.truncated,
          rawResponse: rawResponse,
        );
      }
      if (bytes.length != 3) {
        return UdsIoControlMalformed(
          reason: UdsMalformedReason.invalidNrc,
          rawResponse: rawResponse,
        );
      }
      if (bytes[1] != sidIoControl) {
        return UdsIoControlMalformed(
          reason: UdsMalformedReason.wrongOriginalSid,
          rawResponse: rawResponse,
        );
      }
      final nrc = bytes[2];
      if (nrc == 0x00) {
        return UdsIoControlMalformed(
          reason: UdsMalformedReason.invalidNrc,
          rawResponse: rawResponse,
        );
      }
      return UdsIoControlNegative(
        nrc: nrc,
        isResponsePending: nrc == nrcResponsePending,
      );
    }

    // Positive response: 6F <DID-high> <DID-low> <controlParameter> [controlStatusRecord...]
    if (bytes[0] != sidIoControlPositive) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.invalidSid,
        rawResponse: rawResponse,
      );
    }

    if (bytes.length < 4) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.truncated,
        rawResponse: rawResponse,
      );
    }

    final echoedDid = (bytes[1] << 8) | bytes[2];
    if (echoedDid != expectedDid) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.wrongDidEcho,
        rawResponse: rawResponse,
      );
    }

    final echoedParamByte = bytes[3];
    final echoedParam = UdsIoControlParameter.fromByte(echoedParamByte);
    if (echoedParam == null || echoedParam != expectedParameter) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.wrongControlParameterEcho,
        rawResponse: rawResponse,
      );
    }

    final statusRecord = bytes.length > 4 ? bytes.sublist(4) : const <int>[];

    // Enforce profile response length contract
    final targetExpectedBytes =
        expectedResponseBytes ?? descriptor?.expectedResponseBytes;
    if (targetExpectedBytes != null &&
        statusRecord.length != targetExpectedBytes) {
      return UdsIoControlMalformed(
        reason: UdsMalformedReason.wrongResponseLength,
        rawResponse: rawResponse,
      );
    }

    return UdsIoControlSuccess(
      did: echoedDid,
      controlParameter: echoedParam,
      controlStatusRecord: statusRecord,
    );
  }

  // ---------------------------------------------------------------------------
  // Service 0x31: RoutineControl
  // ---------------------------------------------------------------------------

  /// Encodes a UDS 0x31 request into bytes.
  static List<int> encodeRoutineRequest({
    required UdsRoutineControlType controlType,
    required int routineIdentifier,
    List<int> optionRecord = const [],
  }) {
    if (routineIdentifier < 0x0000 || routineIdentifier > 0xFFFF) {
      throw ArgumentError.value(
        routineIdentifier,
        'routineIdentifier',
        'Routine ID must be 16-bit unsigned (0x0000..0xFFFF)',
      );
    }
    for (final b in optionRecord) {
      if (b < 0 || b > 0xFF) {
        throw ArgumentError.value(b, 'optionRecord', 'Option record bytes must be 0x00..0xFF');
      }
    }
    return <int>[
      sidRoutineControl,
      controlType.subfunctionByte,
      (routineIdentifier >> 8) & 0xFF,
      routineIdentifier & 0xFF,
      ...optionRecord,
    ];
  }

  /// Encodes a UDS 0x31 request into an ASCII hex command string.
  static String encodeRoutineCommand({
    required UdsRoutineControlType controlType,
    required int routineIdentifier,
    List<int> optionRecord = const [],
  }) {
    final bytes = encodeRoutineRequest(
      controlType: controlType,
      routineIdentifier: routineIdentifier,
      optionRecord: optionRecord,
    );
    return _toHex(bytes);
  }

  /// Parses a raw response string for a UDS 0x31 request.
  ///
  /// Enforces exact RID and routine control type echo checks.
  /// Generic "SID + 0x40" responses with wrong RID or truncated payloads are rejected.
  static UdsRoutineParseResult parseRoutineResponse(
    String rawResponse, {
    required UdsRoutineControlType expectedType,
    required int expectedRoutineIdentifier,
    int? expectedResponseBytes,
    UdsRoutineDescriptor? descriptor,
  }) {
    final bytes = _parseHex(rawResponse);
    if (bytes == null) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.invalidHex,
        rawResponse: rawResponse,
      );
    }

    if (bytes.isEmpty) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.truncated,
        rawResponse: rawResponse,
      );
    }

    // Negative response: 7F 31 <NRC>
    if (bytes[0] == sidNegativeResponse) {
      if (bytes.length < 3) {
        return UdsRoutineMalformed(
          reason: UdsMalformedReason.truncated,
          rawResponse: rawResponse,
        );
      }
      if (bytes.length != 3) {
        return UdsRoutineMalformed(
          reason: UdsMalformedReason.invalidNrc,
          rawResponse: rawResponse,
        );
      }
      if (bytes[1] != sidRoutineControl) {
        return UdsRoutineMalformed(
          reason: UdsMalformedReason.wrongOriginalSid,
          rawResponse: rawResponse,
        );
      }
      final nrc = bytes[2];
      if (nrc == 0x00) {
        return UdsRoutineMalformed(
          reason: UdsMalformedReason.invalidNrc,
          rawResponse: rawResponse,
        );
      }
      return UdsRoutineNegative(
        nrc: nrc,
        isResponsePending: nrc == nrcResponsePending,
      );
    }

    // Positive response: 71 <routineControlType> <RID-high> <RID-low> [statusRecord...]
    if (bytes[0] != sidRoutineControlPositive) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.invalidSid,
        rawResponse: rawResponse,
      );
    }

    if (bytes.length < 4) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.truncated,
        rawResponse: rawResponse,
      );
    }

    final echoedTypeByte = bytes[1];
    final echoedType = UdsRoutineControlType.fromByte(echoedTypeByte);
    if (echoedType == null || echoedType != expectedType) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.wrongRoutineTypeEcho,
        rawResponse: rawResponse,
      );
    }

    final echoedRid = (bytes[2] << 8) | bytes[3];
    if (echoedRid != expectedRoutineIdentifier) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.wrongRidEcho,
        rawResponse: rawResponse,
      );
    }

    final statusRecord = bytes.length > 4 ? bytes.sublist(4) : const <int>[];

    // Enforce profile response length contract
    final targetExpectedBytes =
        expectedResponseBytes ?? descriptor?.expectedResponseBytes;
    if (targetExpectedBytes != null &&
        statusRecord.length != targetExpectedBytes) {
      return UdsRoutineMalformed(
        reason: UdsMalformedReason.wrongResponseLength,
        rawResponse: rawResponse,
      );
    }

    return UdsRoutineSuccess(
      controlType: echoedType,
      routineIdentifier: echoedRid,
      routineStatusRecord: statusRecord,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  static String _toHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  static List<int>? _parseHex(String raw) {
    final cleaned = raw.replaceAll(' ', '').trim().toUpperCase();
    if (cleaned.length.isOdd) return null;
    if (!RegExp(r'^[0-9A-F]*$').hasMatch(cleaned)) return null;
    final bytes = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      final b = int.tryParse(cleaned.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      bytes.add(b);
    }
    return bytes;
  }
}
