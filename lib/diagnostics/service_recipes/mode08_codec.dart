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

import '../../obd/addressing.dart';
import '../../obd/elm327_client.dart';
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

  /// Per-ECU parsed outcomes (keyed by ECU identifier such as '7E8', '7E9').
  Map<String, Mode08ParseResult> get ecuResults => const {};

  /// Anonymous parsed outcomes that lacked a trusted CAN source identifier.
  List<Mode08ParseResult> get anonymousResponses => const [];

  /// Capability support status represented by this parsed response.
  EcuSupportStatus get supportStatus;
}

/// Successfully decoded supported TID bitmask.
final class Mode08SupportSuccess extends Mode08ParseResult {
  Mode08SupportSuccess({
    required this.baseTid,
    required this.bitmask,
    required Iterable<int> supportedTids,
    required this.hasNextBlock,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  }) : supportedTids = Set.unmodifiable(supportedTids);

  const Mode08SupportSuccess.constant({
    required this.baseTid,
    required this.bitmask,
    required this.supportedTids,
    required this.hasNextBlock,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  });

  final int baseTid;
  final int bitmask;
  final Set<int> supportedTids;

  /// Whether bit 0 is set indicating TIDs in the subsequent block may be supported.
  final bool hasNextBlock;

  @override
  final Map<String, Mode08ParseResult> ecuResults;

  @override
  final List<Mode08ParseResult> anonymousResponses;

  @override
  EcuSupportStatus get supportStatus => EcuSupportStatus.supported;

  bool isTidSupported(int tid) => supportedTids.contains(tid);
}

/// Successfully decoded Mode 08 active test execution response.
final class Mode08ExecutionSuccess extends Mode08ParseResult {
  Mode08ExecutionSuccess({
    required this.testId,
    required Iterable<int> dataBytes,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  }) : dataBytes = List.unmodifiable(dataBytes);

  const Mode08ExecutionSuccess.constant({
    required this.testId,
    required this.dataBytes,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  });

  final int testId;
  final List<int> dataBytes;

  @override
  final Map<String, Mode08ParseResult> ecuResults;

  @override
  final List<Mode08ParseResult> anonymousResponses;

  @override
  EcuSupportStatus get supportStatus => EcuSupportStatus.unknown;
}

/// Negative response returned by ECU (e.g. 7F 08 11, 7F 08 12, 7F 08 22, 7F 08 31).
final class Mode08NegativeResponse extends Mode08ParseResult {
  const Mode08NegativeResponse({
    required this.originalSid,
    required this.nrc,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  });

  final int originalSid;
  final int nrc;

  @override
  final Map<String, Mode08ParseResult> ecuResults;

  @override
  final List<Mode08ParseResult> anonymousResponses;

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
  @override
  EcuSupportStatus get supportStatus =>
      isUnsupported ? EcuSupportStatus.unsupported : EcuSupportStatus.unknown;
}

/// No response from ECU (silence, NO DATA, BUS ERROR, timeout).
final class Mode08NoResponse extends Mode08ParseResult {
  const Mode08NoResponse({
    required this.reason,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  });

  final String reason;

  @override
  final Map<String, Mode08ParseResult> ecuResults;

  @override
  final List<Mode08ParseResult> anonymousResponses;

  /// CRITICAL: Silence or NO DATA is unknown, NOT unsupported.
  @override
  EcuSupportStatus get supportStatus => EcuSupportStatus.unknown;
}

/// Malformed response (corrupted bytes, wrong echo, invalid length).
final class Mode08MalformedResponse extends Mode08ParseResult {
  const Mode08MalformedResponse({
    required this.reason,
    required this.rawResponse,
    this.ecuResults = const {},
    this.anonymousResponses = const [],
  });

  final Mode08MalformedReason reason;
  final String rawResponse;

  @override
  final Map<String, Mode08ParseResult> ecuResults;

  @override
  final List<Mode08ParseResult> anonymousResponses;

  @override
  EcuSupportStatus get supportStatus => EcuSupportStatus.unknown;
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

  /// Parses an [ObdResponse] directly, preserving adapter error codes, ISO-TP frames,
  /// observed frames, and attributed ECU sources.
  static Mode08ParseResult parseObdResponse(
    ObdResponse response, {
    required int expectedBaseTid,
  }) {
    if (!validBaseTids.contains(expectedBaseTid)) {
      throw ProhibitedActiveProbeException(expectedBaseTid);
    }

    // 1. Structured reassembled frames if available
    if (response.frames.isNotEmpty) {
      final perEcu = <String, Mode08ParseResult>{};
      final anonymousResults = <Mode08ParseResult>[];
      for (var i = 0; i < response.frames.length; i++) {
        final frame = response.frames[i];
        final rawSource = frame.sourceId;
        final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
        final body = frame.payload ?? frame.bytes;
        final hexBody = body
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join('');
        final parsed = _parseSinglePayload(
          hexBody,
          expectedBaseTid: expectedBaseTid,
          originalRaw: hexBody,
          sourceId: isTrusted ? rawSource : null,
        );
        if (isTrusted) {
          perEcu[rawSource] = parsed;
        } else {
          anonymousResults.add(parsed);
        }
      }

      // Check observed frames for peer damage or unreassembled responses
      for (final obs in response.observedFrames) {
        final obsSource = obs.sourceId;
        final isTrusted = obsSource != null && BusAddressing.isLegalCanId(obsSource);
        if (isTrusted) {
          if (!perEcu.containsKey(obsSource)) {
            if (obs.payload != null) {
              final hexBody = obs.payload!
                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join('');
              perEcu[obsSource] = _parseSinglePayload(
                hexBody,
                expectedBaseTid: expectedBaseTid,
                originalRaw: hexBody,
                sourceId: obsSource,
              );
            } else {
              perEcu[obsSource] = Mode08MalformedResponse(
                reason: Mode08MalformedReason.truncated,
                rawResponse: obs.bytes
                    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                    .join(' '),
              );
            }
          }
        } else {
          // Untrusted / unheadered observed frame not in reassembled frames
          if (obs.payload != null) {
            final hexBody = obs.payload!
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join('');
            final parsed = _parseSinglePayload(
              hexBody,
              expectedBaseTid: expectedBaseTid,
              originalRaw: hexBody,
              sourceId: null,
            );
            final alreadyAdded = anonymousResults.any((r) =>
                r.runtimeType == parsed.runtimeType);
            if (!alreadyAdded) {
              anonymousResults.add(parsed);
            }
          } else {
            final malformed = Mode08MalformedResponse(
              reason: Mode08MalformedReason.truncated,
              rawResponse: obs.bytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join(' '),
            );
            final alreadyAdded = anonymousResults.any((r) =>
                r is Mode08MalformedResponse &&
                r.rawResponse == malformed.rawResponse);
            if (!alreadyAdded) {
              anonymousResults.add(malformed);
            }
          }
        }
      }

      // Include attributed sources that did not yield a valid frame
      for (final src in response.attributedSources) {
        if (!perEcu.containsKey(src)) {
          perEcu[src] = (response.errorCode == Elm327ErrorCode.dataError)
              ? const Mode08MalformedResponse(
                  reason: Mode08MalformedReason.invalidHex,
                  rawResponse: '',
                )
              : Mode08NoResponse(reason: 'NO DATA from $src');
        }
      }

      // Preserve unattributed damage and transaction-level error codes
      _captureUnattributedDamageAndErrors(
        response,
        perEcu,
        expectedBaseTid: expectedBaseTid,
        anonymousResults: anonymousResults,
      );

      return _aggregateEcuResults(
        perEcu,
        anonymousResponses: anonymousResults,
        expectedBaseTid: expectedBaseTid,
        defaultNoResponseReason: 'NO DATA across all nodes',
      );
    }

    // 2. Observed frames if reassembled frames are empty (e.g. dataError or partial damage)
    if (response.observedFrames.isNotEmpty) {
      final perEcu = <String, Mode08ParseResult>{};
      final anonymousResults = <Mode08ParseResult>[];
      for (var i = 0; i < response.observedFrames.length; i++) {
        final obs = response.observedFrames[i];
        final rawSource = obs.sourceId;
        final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
        if (obs.payload != null) {
          final hexBody = obs.payload!
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join('');
          final parsed = _parseSinglePayload(
            hexBody,
            expectedBaseTid: expectedBaseTid,
            originalRaw: hexBody,
            sourceId: isTrusted ? rawSource : null,
          );
          if (isTrusted) {
            perEcu[rawSource] = parsed;
          } else {
            anonymousResults.add(parsed);
          }
        } else {
          final malformed = Mode08MalformedResponse(
            reason: Mode08MalformedReason.truncated,
            rawResponse: obs.bytes
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(' '),
          );
          if (isTrusted) {
            perEcu[rawSource] = malformed;
          } else {
            anonymousResults.add(malformed);
          }
        }
      }

      for (final src in response.attributedSources) {
        if (!perEcu.containsKey(src)) {
          perEcu[src] = (response.errorCode == Elm327ErrorCode.dataError)
              ? const Mode08MalformedResponse(
                  reason: Mode08MalformedReason.invalidHex,
                  rawResponse: '',
                )
              : Mode08NoResponse(reason: 'NO DATA from $src');
        }
      }

      // Preserve unattributed damage and transaction-level error codes
      _captureUnattributedDamageAndErrors(
        response,
        perEcu,
        expectedBaseTid: expectedBaseTid,
        anonymousResults: anonymousResults,
      );

      return _aggregateEcuResults(
        perEcu,
        anonymousResponses: anonymousResults,
        expectedBaseTid: expectedBaseTid,
        defaultNoResponseReason: 'NO DATA across all nodes',
      );
    }

    // 3. Check if rawLines has candidate response lines that should be parsed
    final hasCandidateLines = response.rawLines.any((l) {
      final u = l.trim().toUpperCase();
      return u.isNotEmpty &&
          u != 'NO DATA' &&
          u != 'NODATA' &&
          u != '?' &&
          u != 'SEARCHING' &&
          u != 'SEARCHING...' &&
          u != 'OK' &&
          u != 'STOPPED' &&
          !u.startsWith('AT') &&
          !u.startsWith('BUS INIT') &&
          !u.startsWith('ELM327');
    });
    if (hasCandidateLines) {
      return parseResponse(
        response.rawLines.join('\n'),
        expectedBaseTid: expectedBaseTid,
      );
    }

    // 4. Adapter-level error code classifications
    final perEcuFromAttributed = <String, Mode08ParseResult>{};
    switch (response.errorCode) {
      case Elm327ErrorCode.noData:
        for (final src in response.attributedSources) {
          perEcuFromAttributed[src] = const Mode08NoResponse(reason: 'NO DATA');
        }
        return Mode08NoResponse(
          reason: 'NO DATA',
          ecuResults: perEcuFromAttributed.isNotEmpty
              ? Map.unmodifiable(perEcuFromAttributed)
              : const {},
        );
      case Elm327ErrorCode.canError:
      case Elm327ErrorCode.busError:
      case Elm327ErrorCode.busBusy:
      case Elm327ErrorCode.busInitError:
      case Elm327ErrorCode.unableToConnect:
      case Elm327ErrorCode.stopped:
        for (final src in response.attributedSources) {
          perEcuFromAttributed[src] =
              Mode08NoResponse(reason: response.errorCode.name.toUpperCase());
        }
        return Mode08NoResponse(
          reason: response.errorCode.name.toUpperCase(),
          ecuResults: perEcuFromAttributed.isNotEmpty
              ? Map.unmodifiable(perEcuFromAttributed)
              : const {},
        );
      case Elm327ErrorCode.dataError:
        for (final src in response.attributedSources) {
          perEcuFromAttributed[src] = Mode08MalformedResponse(
            reason: Mode08MalformedReason.invalidHex,
            rawResponse: response.rawLines.join('\n'),
          );
        }
        if (perEcuFromAttributed.isEmpty) {
          perEcuFromAttributed['unattributed'] = Mode08MalformedResponse(
            reason: Mode08MalformedReason.invalidHex,
            rawResponse: response.rawLines.join('\n'),
          );
        }
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: response.rawLines.join('\n'),
          ecuResults: perEcuFromAttributed.isNotEmpty
              ? Map.unmodifiable(perEcuFromAttributed)
              : const {},
        );
      case Elm327ErrorCode.none:
        break;
      default:
        for (final src in response.attributedSources) {
          perEcuFromAttributed[src] =
              Mode08NoResponse(reason: response.errorCode.name.toUpperCase());
        }
        if (perEcuFromAttributed.isEmpty) {
          perEcuFromAttributed['unattributed'] =
              Mode08NoResponse(reason: response.errorCode.name.toUpperCase());
        }
        return Mode08NoResponse(
          reason: response.errorCode.name.toUpperCase(),
          ecuResults: perEcuFromAttributed.isNotEmpty
              ? Map.unmodifiable(perEcuFromAttributed)
              : const {},
        );
    }

    // 4. Fall back to raw response lines
    return parseResponse(
      response.rawLines.join('\n'),
      expectedBaseTid: expectedBaseTid,
    );
  }

  static void _captureUnattributedDamageAndErrors(
    ObdResponse response,
    Map<String, Mode08ParseResult> perEcu, {
    required int expectedBaseTid,
    List<Mode08ParseResult>? anonymousResults,
  }) {
    // 1. Transaction-level adapter error codes
    if (response.errorCode == Elm327ErrorCode.dataError) {
      if (!perEcu.containsKey('unattributed')) {
        final malformed = Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: response.rawLines.join('\n'),
        );
        perEcu['unattributed'] = malformed;
        anonymousResults?.add(malformed);
      }
    } else if (response.errorCode != Elm327ErrorCode.none) {
      if (!perEcu.containsKey('unattributed')) {
        final noResp = Mode08NoResponse(
          reason: response.errorCode == Elm327ErrorCode.noData
              ? 'NO DATA'
              : response.errorCode.name.toUpperCase(),
        );
        perEcu['unattributed'] = noResp;
        anonymousResults?.add(noResp);
      }
    }

    // 2. Scan raw lines for unattributed damaged / malformed content (ignoring adapter echoes / prompts)
    final commandEcho = '08${expectedBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    for (final line in response.rawLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final upper = trimmed.toUpperCase();
      if (upper == commandEcho ||
          upper == '>' ||
          upper == 'OK' ||
          upper == 'SEARCHING' ||
          upper == 'SEARCHING...' ||
          upper == 'STOPPED' ||
          upper.startsWith('AT') ||
          upper.startsWith('BUS INIT') ||
          upper.startsWith('ELM327')) {
        continue;
      }
      final extracted = _extractPayloadAndSource(trimmed);
      if (extracted.payload == 'INVALID_HEX' ||
          extracted.payload == 'INVALID_FRAMING') {
        final rawSource = extracted.sourceId;
        final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
        final src = isTrusted ? rawSource : 'unattributed';
        if (!perEcu.containsKey(src) || perEcu[src] is! Mode08MalformedResponse) {
          final malformed = Mode08MalformedResponse(
            reason: extracted.payload == 'INVALID_HEX'
                ? Mode08MalformedReason.invalidHex
                : Mode08MalformedReason.truncated,
            rawResponse: trimmed,
          );
          perEcu[src] = malformed;
          if (!isTrusted) {
            anonymousResults?.add(malformed);
          }
        }
      } else {
        final rawSource = extracted.sourceId;
        final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
        final parsed = _parseSinglePayload(
          extracted.payload,
          expectedBaseTid: expectedBaseTid,
          originalRaw: trimmed,
          sourceId: isTrusted ? rawSource : null,
        );
        if (parsed is Mode08MalformedResponse) {
          final src = isTrusted ? rawSource : 'unattributed';
          if (!perEcu.containsKey(src) || perEcu[src] is! Mode08SupportSuccess) {
            perEcu[src] = parsed;
          }
          if (!isTrusted) {
            final alreadyAdded = anonymousResults != null &&
                anonymousResults.any((r) =>
                    r is Mode08MalformedResponse &&
                    r.rawResponse == trimmed);
            if (!alreadyAdded) {
              anonymousResults?.add(parsed);
            }
          }
        } else if (parsed is Mode08NoResponse) {
          final src = isTrusted ? rawSource : 'unattributed';
          if (!perEcu.containsKey(src)) {
            perEcu[src] = parsed;
          }
          if (!isTrusted) {
            final alreadyAdded = anonymousResults != null &&
                anonymousResults.any((r) =>
                    r is Mode08NoResponse && r.reason == parsed.reason);
            if (!alreadyAdded) {
              anonymousResults?.add(parsed);
            }
          }
        } else if (parsed is Mode08NegativeResponse) {
          if (isTrusted) {
            if (!perEcu.containsKey(rawSource)) {
              perEcu[rawSource] = parsed;
            }
          } else {
            final alreadyAdded = anonymousResults != null &&
                anonymousResults.any((r) =>
                    r is Mode08NegativeResponse && r.nrc == parsed.nrc);
            if (!alreadyAdded) {
              anonymousResults?.add(parsed);
            }
          }
        } else if (isTrusted) {
          if (!perEcu.containsKey(rawSource)) {
            perEcu[rawSource] = parsed;
          }
        } else if (parsed is Mode08SupportSuccess) {
          final alreadyAdded = anonymousResults != null &&
              anonymousResults.any((r) =>
                  r is Mode08SupportSuccess &&
                  r.bitmask == parsed.bitmask);
          if (!alreadyAdded) {
            anonymousResults?.add(parsed);
          }
        }
      }
    }
  }

  /// Parses raw ECU response string for a supported TID query.
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
        .where((l) {
          final upper = l.toUpperCase();
          return upper != 'SEARCHING...' &&
              upper != 'SEARCHING' &&
              !upper.startsWith('BUS INIT') &&
              upper != 'OK' &&
              upper != 'STOPPED' &&
              !upper.startsWith('ELM327');
        })
        .toList();

    if (lines.isEmpty) {
      return const Mode08NoResponse(reason: 'EMPTY');
    }

    if (lines.length > 1) {
      final perEcu = <String, Mode08ParseResult>{};
      final anonymousResults = <Mode08ParseResult>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final extracted = _extractPayloadAndSource(line);
        final rawSource = extracted.sourceId;
        final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
        final parsed = _parseSinglePayload(
          extracted.payload,
          expectedBaseTid: expectedBaseTid,
          originalRaw: line,
          sourceId: isTrusted ? rawSource : null,
        );
        if (isTrusted) {
          perEcu[rawSource] = parsed;
        } else {
          anonymousResults.add(parsed);
        }
      }
      return _aggregateEcuResults(
        perEcu,
        anonymousResponses: anonymousResults,
        expectedBaseTid: expectedBaseTid,
        defaultNoResponseReason: 'NO DATA across all nodes',
      );
    }

    final singleLine = lines.first;
    final extracted = _extractPayloadAndSource(singleLine);
    final rawSource = extracted.sourceId;
    final isTrusted = rawSource != null && BusAddressing.isLegalCanId(rawSource);
    final parsed = _parseSinglePayload(
      extracted.payload,
      expectedBaseTid: expectedBaseTid,
      originalRaw: singleLine,
      sourceId: isTrusted ? rawSource : null,
    );
    if (isTrusted) {
      return parsed;
    }
    return _aggregateEcuResults(
      const {},
      anonymousResponses: [parsed],
      expectedBaseTid: expectedBaseTid,
      defaultNoResponseReason: 'NO DATA across all nodes',
    );
  }

  /// Extracts application payload and optional ECU source ID from [line].
  ///
  /// Enforces:
  /// - Complete headerless payloads (e.g. 12 hex digits for 0x48, 6 for 0x7F) are never misclassified as CAN headers.
  /// - CAN headers must strictly be legal CAN IDs per [BusAddressing.isLegalCanId].
  /// - Non-hex characters fail-closed immediately as 'INVALID_HEX'.
  /// - ISO-TP PCI bytes are validated for Single Frame length contract.
  static ({String? sourceId, String payload}) _extractPayloadAndSource(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return (sourceId: null, payload: '');
    }

    final cleanedNoSpaces = trimmed.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (cleanedNoSpaces == 'NODATA' ||
        cleanedNoSpaces == 'BUSERROR' ||
        cleanedNoSpaces == 'ERROR' ||
        cleanedNoSpaces == 'CANERROR' ||
        cleanedNoSpaces == 'TIMEOUT' ||
        cleanedNoSpaces == '?' ||
        cleanedNoSpaces == 'UNABLETOCONNECT') {
      return (sourceId: null, payload: trimmed);
    }

    if (trimmed.contains(' ')) {
      final tokens = trimmed.split(RegExp(r'\s+'));
      if (tokens.isEmpty) return (sourceId: null, payload: '');

      // Check for non-hex characters in tokens
      for (final t in tokens) {
        if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(t)) {
          return (sourceId: null, payload: 'INVALID_HEX');
        }
      }

      // Check if first token is already an OBD SID (48 or 7F) -> unheadered
      final firstUpper = tokens[0].toUpperCase();
      if (firstUpper == '48' || firstUpper == '7F') {
        return (sourceId: null, payload: tokens.join(''));
      }

      // Check if line begins with a legal CAN ID (11-bit or 29-bit)
      if (BusAddressing.isLegalCanId(tokens[0])) {
        final sourceId = tokens[0].toUpperCase();
        if (tokens.length >= 3) {
          // DLC digit at tokens[1] (length 1) + PCI at tokens[2]
          if (tokens[1].length == 1 &&
              tokens.length >= 4 &&
              tokens[2].length == 2 &&
              tokens[2].startsWith('0')) {
            final dlc = int.tryParse(tokens[1], radix: 16);
            final declaredLen = int.tryParse(tokens[2].substring(1, 2), radix: 16) ?? 0;
            if (dlc != null &&
                dlc <= 8 &&
                declaredLen > 0 &&
                declaredLen <= 7 &&
                dlc >= 1 + declaredLen &&
                tokens.length - 2 <= dlc &&
                tokens.length - 2 >= 1 + declaredLen) {
              final payloadTokens = tokens.sublist(3);
              return (
                sourceId: sourceId,
                payload: payloadTokens.take(declaredLen).join(''),
              );
            }
          }

          // Single Frame ISO-TP PCI byte at tokens[1] (e.g. 06 or 03)
          if (tokens[1].length == 2 && tokens[1].startsWith('0')) {
            final declaredLen = int.tryParse(tokens[1].substring(1, 2), radix: 16) ?? 0;
            if (declaredLen > 0 && declaredLen <= 7) {
              final payloadTokens = tokens.sublist(2);
              if (payloadTokens.length >= declaredLen) {
                return (
                  sourceId: sourceId,
                  payload: payloadTokens.take(declaredLen).join(''),
                );
              }
            }
          }

          // Raw unformatted frames without PCI byte
          if (tokens[1].toUpperCase() == '48' || tokens[1].toUpperCase() == '7F') {
            return (sourceId: sourceId, payload: tokens.sublist(1).join(''));
          }
        }
        return (sourceId: sourceId, payload: 'INVALID_FRAMING');
      }

      return (sourceId: null, payload: tokens.join(''));
    }

    // Compact string (no spaces)
    final upper = trimmed.toUpperCase();
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(upper)) {
      return (sourceId: null, payload: 'INVALID_HEX');
    }

    // 1. Exclude complete headerless payloads first:
    // Mode 08 supported TID query positive response is 12 hex digits (48 <tid> <4 bytes bitmask>)
    if (upper.startsWith('48') && upper.length == 12) {
      return (sourceId: null, payload: upper);
    }
    // Negative response is 6 hex digits (7F 08 <nrc>)
    if (upper.startsWith('7F08') && upper.length == 6) {
      return (sourceId: null, payload: upper);
    }

    // 2. Check 11-bit CAN header: 3 hex chars ID + 2 hex chars PCI
    if (upper.length >= 5 && BusAddressing.isLegalCanId(upper.substring(0, 3))) {
      final id = upper.substring(0, 3);
      final pciHigh = upper.substring(3, 4);
      final declaredLen = int.tryParse(upper.substring(4, 5), radix: 16) ?? 0;
      if (pciHigh == '0' && declaredLen > 0 && declaredLen <= 7) {
        final expectedTotal = 3 + 2 + declaredLen * 2;
        if (upper.length >= expectedTotal) {
          return (sourceId: id, payload: upper.substring(5, expectedTotal));
        }
      }
    }

    // 3. Check 29-bit CAN header: 8 hex chars ID + 2 hex chars PCI
    if (upper.length >= 10 && BusAddressing.isLegalCanId(upper.substring(0, 8))) {
      final id = upper.substring(0, 8);
      final pciHigh = upper.substring(8, 9);
      final declaredLen = int.tryParse(upper.substring(9, 10), radix: 16) ?? 0;
      if (pciHigh == '0' && declaredLen > 0 && declaredLen <= 7) {
        final expectedTotal = 8 + 2 + declaredLen * 2;
        if (upper.length >= expectedTotal) {
          return (sourceId: id, payload: upper.substring(10, expectedTotal));
        }
      }
    }

    return (sourceId: null, payload: upper);
  }

  static Mode08ParseResult _parseSinglePayload(
    String payload, {
    required int expectedBaseTid,
    required String originalRaw,
    String? sourceId,
  }) {
    if (payload == 'INVALID_HEX') {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.invalidHex,
        rawResponse: originalRaw,
        ecuResults: sourceId != null
            ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: originalRaw)}
            : const {},
      );
    }
    if (payload == 'INVALID_FRAMING') {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: originalRaw,
        ecuResults: sourceId != null
            ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: originalRaw)}
            : const {},
      );
    }

    final rawUpper = payload.trim().toUpperCase();
    final cleaned = payload.replaceAll(' ', '').trim().toUpperCase();

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
      final noResp = Mode08NoResponse(reason: rawUpper.isEmpty ? 'EMPTY' : rawUpper);
      return Mode08NoResponse(
        reason: noResp.reason,
        ecuResults: sourceId != null ? {sourceId: noResp} : const {},
      );
    }

    // Negative response (7F 08 <NRC>)
    if (cleaned.startsWith('7F')) {
      if (cleaned.length < 6) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: originalRaw)}
              : const {},
        );
      }
      if (cleaned.length != 6 || !RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidNegativeResponse, rawResponse: originalRaw)}
              : const {},
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
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidNegativeResponse, rawResponse: originalRaw)}
              : const {},
        );
      }
      final neg = Mode08NegativeResponse(originalSid: sid, nrc: nrc);
      return Mode08NegativeResponse(
        originalSid: sid,
        nrc: nrc,
        ecuResults: sourceId != null ? {sourceId: neg} : const {},
      );
    }

    // Positive response: 48 <baseTid> <4 bytes bitmask>
    if (cleaned.startsWith('48')) {
      if (cleaned.length < 12) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: originalRaw)}
              : const {},
        );
      }
      if (cleaned.length != 12) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidBitmaskLength,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidBitmaskLength, rawResponse: originalRaw)}
              : const {},
        );
      }
      if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: originalRaw)}
              : const {},
        );
      }

      final echoedTid = int.tryParse(cleaned.substring(2, 4), radix: 16);
      if (echoedTid != expectedBaseTid) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.wrongBaseTidEcho,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.wrongBaseTidEcho, rawResponse: originalRaw)}
              : const {},
        );
      }

      final bitmask = int.tryParse(cleaned.substring(4, 12), radix: 16);
      if (bitmask == null) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: originalRaw,
          ecuResults: sourceId != null
              ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: originalRaw)}
              : const {},
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
      final success = Mode08SupportSuccess(
        baseTid: expectedBaseTid,
        bitmask: bitmask,
        supportedTids: supportedTids,
        hasNextBlock: hasNextBlock,
      );
      return Mode08SupportSuccess(
        baseTid: expectedBaseTid,
        bitmask: bitmask,
        supportedTids: supportedTids,
        hasNextBlock: hasNextBlock,
        ecuResults: sourceId != null ? {sourceId: success} : const {},
      );
    }

    if (cleaned.length < 2) {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: originalRaw,
        ecuResults: sourceId != null
            ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: originalRaw)}
            : const {},
      );
    }
    return Mode08MalformedResponse(
      reason: Mode08MalformedReason.invalidSid,
      rawResponse: originalRaw,
      ecuResults: sourceId != null
          ? {sourceId: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidSid, rawResponse: originalRaw)}
          : const {},
    );
  }

  /// Aggregates per-ECU results with strict permutation order invariance.
  ///
  /// Rules:
  /// 1. If any ECU affirmatively supports Mode 08, the overall response is [Mode08SupportSuccess]
  ///    containing the union of all supported TIDs across all responding ECUs.
  /// 2. If no positive support is present:
  ///    a. If any ECU response is malformed / corrupted, the aggregate cannot be determined unsupported
  ///       and returns [Mode08MalformedResponse].
  ///    b. If any ECU returns a negative response where `!isUnsupported` (e.g. conditionsNotCorrect 0x22,
  ///       busy 0x21, security 0x33, pending 0x78), the vehicle CANNOT be declared unsupported;
  ///       the aggregate returns [Mode08NegativeResponse] with sound [EcuSupportStatus.unknown].
  ///    c. Only when ALL responding ECUs returned affirmative negative responses (0x11, 0x12, 0x31)
  ///       does the aggregate return [Mode08NegativeResponse] with [EcuSupportStatus.unsupported].
  ///    d. Deterministic tie-breaking is enforced by sorting so arrival order never affects the verdict.
  static Mode08ParseResult _aggregateEcuResults(
    Map<String, Mode08ParseResult> perEcu, {
    List<Mode08ParseResult> anonymousResponses = const [],
    required int expectedBaseTid,
    required String defaultNoResponseReason,
  }) {
    if (perEcu.isEmpty && anonymousResponses.isEmpty) {
      return const Mode08NoResponse(reason: 'EMPTY');
    }

    final successes = <String, Mode08SupportSuccess>{};
    final negatives = <String, Mode08NegativeResponse>{};
    final malformed = <String, Mode08MalformedResponse>{};
    final noResponses = <String, Mode08NoResponse>{};

    for (final entry in perEcu.entries) {
      switch (entry.value) {
        case Mode08SupportSuccess s:
          successes[entry.key] = s;
        case Mode08NegativeResponse n:
          negatives[entry.key] = n;
        case Mode08MalformedResponse m:
          malformed[entry.key] = m;
        case Mode08NoResponse nr:
          noResponses[entry.key] = nr;
        case Mode08ExecutionSuccess _:
          break;
      }
    }

    final anonymousSuccesses = <Mode08SupportSuccess>[];
    final anonymousNegatives = <Mode08NegativeResponse>[];
    final anonymousMalformed = <Mode08MalformedResponse>[];
    final anonymousNoResponses = <Mode08NoResponse>[];

    for (final anon in anonymousResponses) {
      switch (anon) {
        case Mode08SupportSuccess s:
          anonymousSuccesses.add(s);
        case Mode08NegativeResponse n:
          anonymousNegatives.add(n);
        case Mode08MalformedResponse m:
          anonymousMalformed.add(m);
        case Mode08NoResponse nr:
          anonymousNoResponses.add(nr);
        case Mode08ExecutionSuccess _:
          break;
      }
    }

    // 1. Affirmative support across any ECU or anonymous response takes precedence
    if (successes.isNotEmpty || anonymousSuccesses.isNotEmpty) {
      final allTids = <int>{};
      bool hasNextBlock = false;
      for (final s in successes.values) {
        allTids.addAll(s.supportedTids);
        if (s.hasNextBlock) hasNextBlock = true;
      }
      for (final s in anonymousSuccesses) {
        allTids.addAll(s.supportedTids);
        if (s.hasNextBlock) hasNextBlock = true;
      }
      var aggregateBitmask = 0;
      for (final tid in allTids) {
        final offset = tid - expectedBaseTid - 1;
        if (offset >= 0 && offset < 32) {
          aggregateBitmask |= (1 << (31 - offset));
        }
      }
      if (hasNextBlock) aggregateBitmask |= 1;

      return Mode08SupportSuccess(
        baseTid: expectedBaseTid,
        bitmask: aggregateBitmask,
        supportedTids: allTids,
        hasNextBlock: hasNextBlock,
        ecuResults: Map.unmodifiable(perEcu),
        anonymousResponses: List.unmodifiable(anonymousResponses),
      );
    }

    // 2. Corrupted data prevents determining unsupported status
    if (malformed.isNotEmpty || anonymousMalformed.isNotEmpty) {
      if (malformed.isNotEmpty) {
        final sortedKeys = malformed.keys.toList()..sort();
        final chosen = malformed[sortedKeys.first]!;
        return Mode08MalformedResponse(
          reason: chosen.reason,
          rawResponse: chosen.rawResponse,
          ecuResults: Map.unmodifiable(perEcu),
          anonymousResponses: List.unmodifiable(anonymousResponses),
        );
      } else {
        final chosen = anonymousMalformed.first;
        return Mode08MalformedResponse(
          reason: chosen.reason,
          rawResponse: chosen.rawResponse,
          ecuResults: Map.unmodifiable(perEcu),
          anonymousResponses: List.unmodifiable(anonymousResponses),
        );
      }
    }

    // 3. Negative responses: conditionsNotCorrect/busy/unknown take precedence over unsupported
    if (negatives.isNotEmpty || anonymousNegatives.isNotEmpty) {
      final allNegatives = [...negatives.values, ...anonymousNegatives];
      final unknownNegatives =
          allNegatives.where((n) => !n.isUnsupported).toList();
      if (unknownNegatives.isNotEmpty) {
        unknownNegatives.sort((a, b) => a.nrc.compareTo(b.nrc));
        final chosen = unknownNegatives.first;
        return Mode08NegativeResponse(
          originalSid: chosen.originalSid,
          nrc: chosen.nrc,
          ecuResults: Map.unmodifiable(perEcu),
          anonymousResponses: List.unmodifiable(anonymousResponses),
        );
      }

      // If any ECU or anonymous response had no response (silence, timeout, NO DATA), that node's capability is unknown.
      // A vehicle where one node says unsupported but another node was silent CANNOT be declared unsupported!
      if (noResponses.isNotEmpty || anonymousNoResponses.isNotEmpty) {
        if (noResponses.isNotEmpty) {
          final sortedKeys = noResponses.keys.toList()..sort();
          final chosen = noResponses[sortedKeys.first]!;
          return Mode08NoResponse(
            reason: chosen.reason,
            ecuResults: Map.unmodifiable(perEcu),
            anonymousResponses: List.unmodifiable(anonymousResponses),
          );
        } else {
          final chosen = anonymousNoResponses.first;
          return Mode08NoResponse(
            reason: chosen.reason,
            ecuResults: Map.unmodifiable(perEcu),
            anonymousResponses: List.unmodifiable(anonymousResponses),
          );
        }
      }

      // All responding ECUs returned affirmative unsupported NRCs (0x11, 0x12, 0x31)
      allNegatives.sort((a, b) => a.nrc.compareTo(b.nrc));
      final chosen = allNegatives.first;
      return Mode08NegativeResponse(
        originalSid: chosen.originalSid,
        nrc: chosen.nrc,
        ecuResults: Map.unmodifiable(perEcu),
        anonymousResponses: List.unmodifiable(anonymousResponses),
      );
    }

    if (noResponses.isNotEmpty || anonymousNoResponses.isNotEmpty) {
      if (noResponses.isNotEmpty) {
        final sortedKeys = noResponses.keys.toList()..sort();
        final chosen = noResponses[sortedKeys.first]!;
        return Mode08NoResponse(
          reason: chosen.reason,
          ecuResults: Map.unmodifiable(perEcu),
          anonymousResponses: List.unmodifiable(anonymousResponses),
        );
      } else {
        final chosen = anonymousNoResponses.first;
        return Mode08NoResponse(
          reason: chosen.reason,
          ecuResults: Map.unmodifiable(perEcu),
          anonymousResponses: List.unmodifiable(anonymousResponses),
        );
      }
    }

    return Mode08NoResponse(
      reason: defaultNoResponseReason,
      ecuResults: Map.unmodifiable(perEcu),
      anonymousResponses: List.unmodifiable(anonymousResponses),
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
    final extracted = _extractPayloadAndSource(rawResponse);
    if (extracted.payload == 'INVALID_HEX') {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.invalidHex,
        rawResponse: rawResponse,
        ecuResults: extracted.sourceId != null
            ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: rawResponse)}
            : const {},
      );
    }
    if (extracted.payload == 'INVALID_FRAMING') {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: rawResponse,
        ecuResults: extracted.sourceId != null
            ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: rawResponse)}
            : const {},
      );
    }

    final rawUpper = extracted.payload.trim().toUpperCase();
    final cleaned = extracted.payload.replaceAll(' ', '').trim().toUpperCase();

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
      return Mode08NoResponse(
        reason: rawUpper.isEmpty ? 'EMPTY' : rawUpper,
        ecuResults: extracted.sourceId != null
            ? {extracted.sourceId!: Mode08NoResponse(reason: rawUpper.isEmpty ? 'EMPTY' : rawUpper)}
            : const {},
      );
    }

    // Check for negative response (7F 08 <NRC>)
    if (cleaned.startsWith('7F')) {
      if (cleaned.length < 6) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: rawResponse,
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: rawResponse)}
              : const {},
        );
      }
      if (cleaned.length != 6 || !RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidNegativeResponse,
          rawResponse: rawResponse,
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidNegativeResponse, rawResponse: rawResponse)}
              : const {},
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
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidNegativeResponse, rawResponse: rawResponse)}
              : const {},
        );
      }
      final neg = Mode08NegativeResponse(originalSid: sid, nrc: nrc);
      return Mode08NegativeResponse(
        originalSid: sid,
        nrc: nrc,
        ecuResults: extracted.sourceId != null ? {extracted.sourceId!: neg} : const {},
      );
    }

    // Positive response: 48 <echoedTestId> [dataBytes...]
    if (cleaned.startsWith('48')) {
      if (cleaned.length < 4) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.truncated,
          rawResponse: rawResponse,
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: rawResponse)}
              : const {},
        );
      }
      if (cleaned.length.isOdd || !RegExp(r'^[0-9A-F]+$').hasMatch(cleaned)) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.invalidHex,
          rawResponse: rawResponse,
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: rawResponse)}
              : const {},
        );
      }

      final echoedTid = int.tryParse(cleaned.substring(2, 4), radix: 16);
      if (echoedTid != expectedTestId) {
        return Mode08MalformedResponse(
          reason: Mode08MalformedReason.wrongTestIdEcho,
          rawResponse: rawResponse,
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.wrongTestIdEcho, rawResponse: rawResponse)}
              : const {},
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
            ecuResults: extracted.sourceId != null
                ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidHex, rawResponse: rawResponse)}
                : const {},
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
          ecuResults: extracted.sourceId != null
              ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.wrongResponseLength, rawResponse: rawResponse)}
              : const {},
        );
      }

      final execSuccess = Mode08ExecutionSuccess(
        testId: echoedTid!,
        dataBytes: dataBytes,
      );
      return Mode08ExecutionSuccess(
        testId: echoedTid,
        dataBytes: dataBytes,
        ecuResults: extracted.sourceId != null
            ? {extracted.sourceId!: execSuccess}
            : const {},
      );
    }

    if (cleaned.length < 2) {
      return Mode08MalformedResponse(
        reason: Mode08MalformedReason.truncated,
        rawResponse: rawResponse,
        ecuResults: extracted.sourceId != null
            ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.truncated, rawResponse: rawResponse)}
            : const {},
      );
    }
    return Mode08MalformedResponse(
      reason: Mode08MalformedReason.invalidSid,
      rawResponse: rawResponse,
      ecuResults: extracted.sourceId != null
          ? {extracted.sourceId!: Mode08MalformedResponse(reason: Mode08MalformedReason.invalidSid, rawResponse: rawResponse)}
          : const {},
    );
  }
}
