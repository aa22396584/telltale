/// Mode 08 capability discovery codec and response parser.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25.
///
/// Normative references:
/// - SAE J1979 / ISO 15031-5: Diagnostic Services, Service $08
///   ("Request control of on-board system, test or component").
///
/// SAFETY CONTRACT:
/// - Supported-test discovery emits ONLY the independently documented non-actuating
///   query for supported Test IDs (TIDs $00, $20, $40, $60, $80, $A0, $C0, $E0).
/// - Probing runnable TIDs (e.g. TID 01) to "discover" support is STRICTLY PROHIBITED
///   and throws [ProhibitedActiveProbeException].
/// - Unsupported, malformed, and no-response outcomes remain distinct.
/// - Silence / NO DATA is unknown, never unsupported.
library;

import 'active_test_profile.dart';
import 'qualification_tier.dart';

/// Exception thrown if any caller attempts to probe runnable TIDs as discovery.
final class ProhibitedActiveProbeException implements Exception {
  const ProhibitedActiveProbeException(this.attemptedTid);
  final int attemptedTid;

  @override
  String toString() =>
      'ProhibitedActiveProbeException: Mode 08 capability discovery only permits '
      'standard base TIDs (0x00, 0x20, ...), never runnable TID 0x${attemptedTid.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

/// Reason for a malformed Mode 08 response.
enum Mode08MalformedReason {
  truncated,
  invalidHex,
  invalidSid,
  wrongBaseTidEcho,
  wrongTestIdEcho,
  invalidBitmaskLength,
  wrongResponseLength,
  invalidNegativeResponse,
}

/// Sealed result of parsing a Mode 08 response.
sealed class Mode08ParseResult {
  const Mode08ParseResult();
}

/// Successfully decoded supported TID bitmask.
final class Mode08SupportSuccess extends Mode08ParseResult {
  Mode08SupportSuccess({
    required this.baseTid,
    required this.bitmask,
    required Iterable<int> supportedTids,
    required this.hasNextBlock,
  }) : supportedTids = Set.unmodifiable(supportedTids);

  const Mode08SupportSuccess.constant({
    required this.baseTid,
    required this.bitmask,
    required this.supportedTids,
    required this.hasNextBlock,
  });

  final int baseTid;
  final int bitmask;
  final Set<int> supportedTids;

  /// Whether bit 0 is set indicating TIDs in the subsequent block may be supported.
  final bool hasNextBlock;

  bool isTidSupported(int tid) => supportedTids.contains(tid);
}

/// Successfully decoded Mode 08 active test execution response.
final class Mode08ExecutionSuccess extends Mode08ParseResult {
  Mode08ExecutionSuccess({
    required this.testId,
    required Iterable<int> dataBytes,
  }) : dataBytes = List.unmodifiable(dataBytes);

  const Mode08ExecutionSuccess.constant({
    required this.testId,
    required this.dataBytes,
  });

  final int testId;
  final List<int> dataBytes;
}

/// Negative response returned by ECU (e.g. 7F 08 11, 7F 08 12, 7F 08 22, 7F 08 31).
final class Mode08NegativeResponse extends Mode08ParseResult {
  const Mode08NegativeResponse({
    required this.originalSid,
    required this.nrc,
  });

  final int originalSid;
  final int nrc;

  /// Whether the NRC affirmatively indicates that the service, subfunction, or TID is unsupported.
  ///
  /// Standard SAE J1979 / ISO 15031-5 and UDS:
  /// - 0x11: serviceNotSupported
  /// - 0x12: subFunctionNotSupported
  /// - 0x31: requestOutOfRange
  bool get isUnsupported => nrc == 0x11 || nrc == 0x12 || nrc == 0x31;

  /// Whether the NRC indicates temporary conditions prevented execution (e.g. vehicle speed, engine running).
  ///
  /// - 0x22: conditionsNotCorrect
  bool get isConditionsNotCorrect => nrc == 0x22;

  /// Whether the NRC indicates ECU is busy (0x21).
  bool get isBusy => nrc == 0x21;

  /// Whether the NRC indicates security access is denied (0x33).
  bool get isSecurityAccessDenied => nrc == 0x33;

  /// Whether the NRC indicates responsePending (0x78).
  bool get isResponsePending => nrc == 0x78;

  /// Support status with sound fallback:
  /// 0x11, 0x12, 0x31 confirm the feature/TID is [EcuSupportStatus.unsupported].
  /// 0x22 (conditionsNotCorrect), 0x21 (busy), 0x33 (security), 0x78 (pending),
  /// and other unexpected NRCs fallback to [EcuSupportStatus.unknown]
  /// because the service itself may exist on the ECU.
  EcuSupportStatus get supportStatus =>
      isUnsupported ? EcuSupportStatus.unsupported : EcuSupportStatus.unknown;
}

/// No response from ECU (silence, NO DATA, BUS ERROR, timeout).
final class Mode08NoResponse extends Mode08ParseResult {
  const Mode08NoResponse({required this.reason});
  final String reason;

  /// CRITICAL: Silence or NO DATA is unknown, NOT unsupported.
  EcuSupportStatus get supportStatus => EcuSupportStatus.unknown;
}

/// Malformed response (corrupted bytes, wrong echo, invalid length).
final class Mode08MalformedResponse extends Mode08ParseResult {
  const Mode08MalformedResponse({
    required this.reason,
    required this.rawResponse,
  });

  final Mode08MalformedReason reason;
  final String rawResponse;
}

/// Non-actuating Mode 08 discovery codec.
final class Mode08DiscoveryCodec {
  const Mode08DiscoveryCodec._();

  /// Standard base TIDs allocated by SAE J1979 / ISO 15031-5 for supported TID bitmasks.
  static const Set<int> validBaseTids = {
    0x00,
    0x20,
    0x40,
    0x60,
    0x80,
    0xA0,
    0xC0,
    0xE0,
  };

  /// Recognised NRCs for OBD-II Mode 08 (SAE J1979:2014 Section 8.8 / ISO 15031-5:2015 Clause 8.8).
  static bool isRecognizedMode08Nrc(int nrc) {
    return nrc == 0x11 || // serviceNotSupported
        nrc == 0x12 || // subFunctionNotSupported
        nrc == 0x13 || // incorrectMessageLengthOrInvalidFormat
        nrc == 0x21 || // busyRepeatRequest
        nrc == 0x22 || // conditionsNotCorrect
        nrc == 0x31 || // requestOutOfRange
        nrc == 0x33 || // securityAccessDenied
        nrc == 0x78; // responsePending
  }

  /// Constructs the non-actuating command string to query supported TIDs.
  ///
  /// Strictly requires [baseTid] to be in [validBaseTids].
  /// Throws [ProhibitedActiveProbeException] for any runnable TID!
  static String createSupportedTidCommand(int baseTid) {
    if (!validBaseTids.contains(baseTid)) {
      throw ProhibitedActiveProbeException(baseTid);
    }
    final tidHex = baseTid.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '08$tidHex';
  }

  /// Parses raw ECU response for a supported TID query.
  static Mode08ParseResult parseResponse(
    String rawResponse, {
    required int expectedBaseTid,
  }) {
    if (!validBaseTids.contains(expectedBaseTid)) {
      throw ProhibitedActiveProbeException(expectedBaseTid);
    }

    final lines = rawResponse
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length > 1) {
      return _parseMultiLineResponse(
        lines,
        expectedBaseTid: expectedBaseTid,
        originalRaw: rawResponse,
      );
    }

    return _parseSingleLineResponse(
      lines.isEmpty ? '' : lines.first,
      expectedBaseTid: expectedBaseTid,
      originalRaw: rawResponse,
    );
  }

  static Mode08ParseResult _parseMultiLineResponse(
    List<String> lines, {
    required int expectedBaseTid,
    required String originalRaw,
  }) {
    final successTids = <int>{};
    bool hasNextBlock = false;
    bool hasSuccess = false;
    Mode08NegativeResponse? firstNegative;
    Mode08MalformedResponse? firstMalformed;
    int noResponseCount = 0;

    for (final line in lines) {
      final upper = line.trim().toUpperCase();
      if (upper == 'SEARCHING...' ||
          upper == 'SEARCHING' ||
          upper.startsWith('BUS INIT') ||
          upper == 'OK' ||
          upper == 'STOPPED' ||
          upper.startsWith('ELM327')) {
        continue;
      }

      final parsed = _parseSingleLineResponse(
        line,
        expectedBaseTid: expectedBaseTid,
        originalRaw: line,
      );

      switch (parsed) {
        case Mode08SupportSuccess success:
          hasSuccess = true;
          successTids.addAll(success.supportedTids);
          if (success.hasNextBlock) {
            hasNextBlock = true;
          }
        case Mode08NegativeResponse negative:
          firstNegative ??= negative;
        case Mode08NoResponse _:
          noResponseCount++;
        case Mode08MalformedResponse malformed:
          firstMalformed ??= malformed;
        case Mode08ExecutionSuccess _:
          break;
      }
    }

    if (hasSuccess) {
      var aggregateBitmask = 0;
      for (final tid in successTids) {
        final offset = tid - expectedBaseTid - 1;
        if (offset >= 0 && offset < 32) {
          aggregateBitmask |= (1 << (31 - offset));
        }
      }
      if (hasNextBlock) {
        aggregateBitmask |= 1;
      }

      return Mode08SupportSuccess(
        baseTid: expectedBaseTid,
        bitmask: aggregateBitmask,
        supportedTids: successTids,
        hasNextBlock: hasNextBlock,
      );
    }

    if (firstNegative != null) {
      return firstNegative;
    }

    if (firstMalformed != null) {
      return firstMalformed;
    }

    return Mode08NoResponse(
      reason: noResponseCount > 0 ? 'NO DATA across all nodes' : 'EMPTY',
    );
  }

  static String _stripCanHeader(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.contains(' ')) {
      final tokens = trimmed.split(RegExp(r'\s+'));
      if (tokens.length >= 4) {
        final is11Bit = RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(tokens[0]);
        final is29Bit = RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(tokens[0]);
        if (is11Bit || is29Bit) {
          if (tokens.length >= 3 &&
              tokens[1].length == 2 &&
              (tokens[2].toUpperCase() == '48' || tokens[2].toUpperCase() == '7F')) {
            return tokens.sublist(2).join(' ');
          }
          if (tokens[1].toUpperCase() == '48' || tokens[1].toUpperCase() == '7F') {
            return tokens.sublist(1).join(' ');
          }
        }
      }
      return trimmed;
    }

    final upper = trimmed.toUpperCase();
    final match11 = RegExp(r'^[0-9A-F]{3}([0-9A-F]{2})?(48[0-9A-F]*|7F08[0-9A-F]*)$').firstMatch(upper);
    if (match11 != null && match11.group(2) != null) {
      return match11.group(2)!;
    }

    final match29 = RegExp(r'^[0-9A-F]{8}([0-9A-F]{2})?(48[0-9A-F]*|7F08[0-9A-F]*)$').firstMatch(upper);
    if (match29 != null && match29.group(2) != null) {
      return match29.group(2)!;
    }

    return trimmed;
  }

  static Mode08ParseResult _parseSingleLineResponse(
    String line, {
    required int expectedBaseTid,
    required String originalRaw,
  }) {
    final stripped = _stripCanHeader(line);
    final rawUpper = stripped.trim().toUpperCase();
    final cleaned = stripped.replaceAll(' ', '').trim().toUpperCase();

    // Check for silence / no response / bus errors
    if (cleaned.isEmpty ||
        cleaned == 'NODATA' ||
        rawUpper.contains('NO DATA') ||
        rawUpper.contains('CAN ERROR') ||
        rawUpper.contains('BUS ERROR') ||
        cleaned == 'BUSERROR' ||
        cleaned == 'CANERROR' ||
        cleaned == 'TIMEOUT' ||
        cleaned == '?') {
      return Mode08NoResponse(reason: rawUpper.isEmpty ? 'EMPTY' : rawUpper);
    }

    // Check for negative response (7F 08 <NRC>)
    if (cleaned.startsWith('7F')) {
      if (cleaned.length < 6) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: originalRaw,
        );
      }
      if (cleaned.length != 6 ||
          !RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: originalRaw,
        );
      }
      final sidHex = cleaned.substring(2, 4);
      final nrcHex = cleaned.substring(4, 6);
      final sid = int.tryParse(sidHex, radix: 16);
      final nrc = int.tryParse(nrcHex, radix: 16);
      if (sid == null || sid != 0x08 || nrc == null || !isRecognizedMode08Nrc(nrc)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: originalRaw,
        );
      }
      return Mode08NegativeResponse(originalSid: sid, nrc: nrc);
    }

    // Positive response: 48 <baseTid> <4 bytes bitmask>
    // Total hex chars: 2 (SID) + 2 (TID) + 8 (bitmask) = 12 hex chars (6 bytes).
    if (cleaned.startsWith('48')) {
      if (cleaned.length < 12) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: originalRaw,
        );
      }
      if (cleaned.length != 12) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidBitmaskLength,
          rawResponse: originalRaw,
        );
      }
      if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: originalRaw,
        );
      }

      final echoedTid = int.tryParse(cleaned.substring(2, 4), radix: 16);
      if (echoedTid != expectedBaseTid) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.wrongBaseTidEcho,
          rawResponse: originalRaw,
        );
      }

      final bitmask = int.tryParse(cleaned.substring(4, 12), radix: 16);
      if (bitmask == null) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: originalRaw,
        );
      }

      final supportedTids = <int>{};
      for (var i = 0; i < 32; i++) {
        final shift = 31 - i;
        if ((bitmask & (1 << shift)) != 0) {
          supportedTids.add(expectedBaseTid + 1 + i);
        }
      }

      final hasNextBlock = (bitmask & 0x01) != 0;

      return Mode08SupportSuccess(
        baseTid: expectedBaseTid,
        bitmask: bitmask,
        supportedTids: supportedTids,
        hasNextBlock: hasNextBlock,
      );
    }

    // Response has invalid or unhandled SID
    if (cleaned.length < 2) {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: originalRaw,
      );
    }
    return Mode08MalformedResponse(
      reason: Mode08MalformedReason.invalidSid,
      rawResponse: originalRaw,
    );
  }

  /// Parses raw ECU response for a Mode 08 active test execution command.
  ///
  /// Response format: `48 <echoedTestId> [dataBytes...]`
  /// Enforces:
  /// - Exact echoed test ID matching [expectedTestId].
  /// - Response length matching [expectedResponseBytes] or [descriptor.expectedResponseBytes].
  /// - Negative response handling with sound NRC fallback.
  static Mode08ParseResult parseExecutionResponse(
    String rawResponse, {
    required int expectedTestId,
    int? expectedResponseBytes,
    Mode08Descriptor? descriptor,
  }) {
    final stripped = _stripCanHeader(rawResponse);
    final rawUpper = stripped.trim().toUpperCase();
    final cleaned = stripped.replaceAll(' ', '').trim().toUpperCase();

    // Check for silence / no response / bus errors
    if (cleaned.isEmpty ||
        cleaned == 'NODATA' ||
        rawUpper.contains('NO DATA') ||
        rawUpper.contains('CAN ERROR') ||
        rawUpper.contains('BUS ERROR') ||
        cleaned == 'BUSERROR' ||
        cleaned == 'CANERROR' ||
        cleaned == 'TIMEOUT' ||
        cleaned == '?') {
      return Mode08NoResponse(reason: rawUpper.isEmpty ? 'EMPTY' : rawUpper);
    }

    // Check for negative response (7F 08 <NRC>)
    if (cleaned.startsWith('7F')) {
      if (cleaned.length < 6) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: rawResponse,
        );
      }
      if (cleaned.length != 6 ||
          !RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: rawResponse,
        );
      }
      final sidHex = cleaned.substring(2, 4);
      final nrcHex = cleaned.substring(4, 6);
      final sid = int.tryParse(sidHex, radix: 16);
      final nrc = int.tryParse(nrcHex, radix: 16);
      if (sid == null || sid != 0x08 || nrc == null || !isRecognizedMode08Nrc(nrc)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: rawResponse,
        );
      }
      return Mode08NegativeResponse(originalSid: sid, nrc: nrc);
    }

    // Positive response: 48 <echoedTestId> [dataBytes...]
    if (cleaned.startsWith('48')) {
      if (cleaned.length < 4) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: rawResponse,
        );
      }
      if (cleaned.length.isOdd || !RegExp(r'^[0-9A-F]+$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: rawResponse,
        );
      }

      final echoedTid = int.tryParse(cleaned.substring(2, 4), radix: 16);
      if (echoedTid != expectedTestId) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.wrongTestIdEcho,
          rawResponse: rawResponse,
        );
      }

      final dataHex = cleaned.substring(4);
      final dataBytes = <int>[];
      for (var i = 0; i < dataHex.length; i += 2) {
        final b = int.tryParse(dataHex.substring(i, i + 2), radix: 16);
        if (b == null) {
          return Mode08MalformedResponse(
            reason: Mode08MalformedReason.invalidHex,
            rawResponse: rawResponse,
          );
        }
        dataBytes.add(b);
      }

      final targetExpectedBytes =
          expectedResponseBytes ?? descriptor?.expectedResponseBytes;
      if (targetExpectedBytes != null &&
          dataBytes.length != targetExpectedBytes) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.wrongResponseLength,
          rawResponse: rawResponse,
        );
      }

      return Mode08ExecutionSuccess(
        testId: echoedTid!,
        dataBytes: dataBytes,
      );
    }

    if (cleaned.length < 2) {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: rawResponse,
      );
    }
    return Mode08MalformedResponse(
      reason: Mode08MalformedReason.invalidSid,
      rawResponse: rawResponse,
    );
  }
}
