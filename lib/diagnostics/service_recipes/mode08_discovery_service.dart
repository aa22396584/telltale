/// Non-actuating Mode 08 capability discovery service.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25, Follow-up: Issue #132.
///
/// SAFETY CONTRACT:
/// - Discovers supported Test IDs using ONLY standard base TIDs (0x00, 0x20, etc.).
/// - Probing runnable TIDs is strictly prohibited and throws [ProhibitedActiveProbeException].
/// - Executes queries via atomic composite transaction ([Elm327Client.sendTransacted]),
///   guaranteeing header restoration and isolating the query from concurrent operations.
/// - Unanswered or ambiguous responses remain [EcuSupportStatus.unknown], never unsupported.
library;

import 'dart:async';

import '../../obd/elm327_client.dart';
import '../../obd/transport/obd_transport.dart';
import 'mode08_codec.dart';
import 'qualification_tier.dart';

/// Immutable result of a non-actuating Mode 08 supported TIDs discovery query.
final class Mode08DiscoveryResult {
  const Mode08DiscoveryResult({
    required this.isSupported,
    required this.supportStatus,
    required this.supportedTids,
    required this.queriedBlocks,
    required this.discoveredAt,
    this.isComplete = true,
    this.unqueriedBlocks = const [],
    this.ecuResults = const {},
    this.perEcuBlockResults = const {},
    this.failureReason,
    this.nrc,
  });

  /// Factory for a failed or refused discovery attempt.
  factory Mode08DiscoveryResult.failure({
    required EcuSupportStatus supportStatus,
    required String reason,
    int? nrc,
    DateTime? discoveredAt,
    List<int> queriedBlocks = const [],
    List<int> unqueriedBlocks = const [],
    Map<String, Mode08ParseResult> ecuResults = const {},
    Map<String, Map<int, Mode08ParseResult>> perEcuBlockResults = const {},
  }) =>
      Mode08DiscoveryResult(
        isSupported: false,
        supportStatus: supportStatus,
        supportedTids: const {},
        queriedBlocks: queriedBlocks,
        unqueriedBlocks: unqueriedBlocks,
        discoveredAt: discoveredAt ?? DateTime.now().toUtc(),
        isComplete: false,
        failureReason: reason,
        nrc: nrc,
        ecuResults: ecuResults,
        perEcuBlockResults: perEcuBlockResults,
      );

  /// Whether Mode 08 is affirmatively supported by the ECU.
  final bool isSupported;

  /// Strict protocol classification: [EcuSupportStatus.supported], [EcuSupportStatus.unsupported], or [EcuSupportStatus.unknown].
  final EcuSupportStatus supportStatus;

  /// Set of all supported test IDs (TIDs) decoded from 32-bit bitmasks.
  final Set<int> supportedTids;

  /// Base TIDs queried during this discovery session (e.g. `[0x00, 0x20]`).
  final List<int> queriedBlocks;

  /// Whether the full discovery sequence ran to completion without interruption.
  final bool isComplete;

  /// Uncompleted or unqueried blocks if discovery was interrupted or aborted early.
  final List<int> unqueriedBlocks;

  /// Per-ECU response breakdown.
  final Map<String, Mode08ParseResult> ecuResults;

  /// Internal per-ECU, per-block outcome map (ECU -> block -> outcome).
  final Map<String, Map<int, Mode08ParseResult>> perEcuBlockResults;

  /// Timestamp when discovery was performed.
  final DateTime discoveredAt;

  /// Diagnostic failure or refusal reason if discovery was unsuccessful.
  final String? failureReason;

  /// Raw negative response code (NRC) if returned by the ECU.
  final int? nrc;

  /// Whether a specific TID is in the discovered supported set.
  bool containsTid(int tid) => supportedTids.contains(tid);
}

/// Service executing non-actuating Mode 08 supported TID discovery over [Elm327Client].
abstract final class Mode08DiscoveryService {
  static const Duration defaultDiscoveryTimeout = Duration(seconds: 2);
  static const Duration defaultTotalBudget = Duration(seconds: 6);

  /// Discovers supported Mode 08 test IDs by querying standard base TIDs (0x00, 0x20, ...).
  ///
  /// Uses [Elm327Client.sendTransacted] to execute each non-actuating query atomically,
  /// preserving header safety and isolating adapter state.
  static Future<Mode08DiscoveryResult> discoverSupportedTids({
    required Elm327Client client,
    String? targetHeader,
    Duration timeout = defaultDiscoveryTimeout,
    Duration budget = defaultTotalBudget,
    DateTime? deadline,
    Object? owner,
    bool Function()? isSessionValid,
  }) async {
    final now = DateTime.now().toUtc();

    if (!client.addressing.isCan || !client.addressing.supportsObd2) {
      return Mode08DiscoveryResult.failure(
        supportStatus: EcuSupportStatus.unknown,
        reason: 'Mode 08 capability discovery requires a resolved OBD-II CAN bus',
        discoveredAt: now,
      );
    }

    final header = targetHeader ?? client.addressing.functionalHeader;
    final allSupportedTids = <int>{};
    final queriedBlocks = <int>[];
    final uncompletedBlocks = <int>{};
    final perEcuBlockResults = <String, Map<int, Mode08ParseResult>>{};
    final ecuExpectedNextBlocks = <String, int>{};
    bool isComplete = true;
    String? overallFailureReason;
    int currentBaseTid = 0x00;
    int? previousBlockAnonymousCount;
    bool hadMultipleAnonymousResponses = false;

    final stopwatch = Stopwatch()..start();

    while (currentBaseTid <= 0xE0) {
      if (isSessionValid?.call() == false || !client.transport.isConnected) {
        if (allSupportedTids.isNotEmpty) {
          uncompletedBlocks.add(currentBaseTid);
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            isComplete: false,
            unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
            failureReason: 'Session disconnected or superseded during discovery',
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Session disconnected or superseded during discovery',
          discoveredAt: now,
          queriedBlocks: List.unmodifiable(queriedBlocks),
          unqueriedBlocks: [currentBaseTid],
          ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
          perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
        );
      }

      final remainingBudget = budget - stopwatch.elapsed;
      if (remainingBudget <= Duration.zero) {
        if (allSupportedTids.isNotEmpty) {
          uncompletedBlocks.add(currentBaseTid);
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            isComplete: false,
            unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
            failureReason: 'Discovery budget reached before all blocks queried',
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Discovery budget exceeded',
          discoveredAt: now,
          unqueriedBlocks: [currentBaseTid],
          ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
          perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
        );
      }

      final queryCommand = Mode08DiscoveryCodec.createSupportedTidCommand(currentBaseTid);
      final ObdResponse response;
      try {
        response = await client.sendTransacted(
          queryCommand,
          header: header,
          restoreHeader: true,
          timeout: timeout,
          budget: remainingBudget,
          deadline: deadline,
          owner: owner,
        );
      } on TimeoutException {
        if (allSupportedTids.isNotEmpty) {
          uncompletedBlocks.add(currentBaseTid);
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            isComplete: false,
            unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
            failureReason: 'Query timed out for block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Mode 08 query timed out',
          discoveredAt: now,
          unqueriedBlocks: [currentBaseTid],
          ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
          perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
        );
      } on TransportException catch (e) {
        if (allSupportedTids.isNotEmpty) {
          uncompletedBlocks.add(currentBaseTid);
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            isComplete: false,
            unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
            failureReason: 'Transport failed during block query: $e',
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Mode 08 transport failed: $e',
          discoveredAt: now,
          unqueriedBlocks: [currentBaseTid],
          ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
          perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
        );
      } catch (e) {
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Internal error during Mode 08 discovery: $e',
          discoveredAt: now,
          unqueriedBlocks: [currentBaseTid],
          ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
          perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
        );
      }

      queriedBlocks.add(currentBaseTid);
      final parseResult = Mode08DiscoveryCodec.parseObdResponse(
        response,
        expectedBaseTid: currentBaseTid,
      );

      final blockEcuResults = parseResult.ecuResults;
      final blockAnonymous = parseResult.anonymousResponses;

      for (final entry in blockEcuResults.entries) {
        if (entry.key != 'unattributed') {
          perEcuBlockResults.putIfAbsent(entry.key, () => {})[currentBaseTid] = entry.value;
        }
      }

      // Check if any ECU that was expected to respond in this block is missing
      for (final expectedEcu in ecuExpectedNextBlocks.keys.toList()) {
        if (ecuExpectedNextBlocks[expectedEcu] == currentBaseTid) {
          if (!blockEcuResults.containsKey(expectedEcu)) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'ECU $expectedEcu missing on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}';
            perEcuBlockResults.putIfAbsent(expectedEcu, () => {})[currentBaseTid] =
                Mode08NoResponse(
                  reason: 'NO DATA from $expectedEcu on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                );
          }
        }
      }

      // Check anonymous responses tracking
      if (blockAnonymous.length > 1) {
        hadMultipleAnonymousResponses = true;
      }
      if (previousBlockAnonymousCount != null && previousBlockAnonymousCount > 0) {
        if (blockAnonymous.length < previousBlockAnonymousCount) {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'Anonymous response missing on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} (expected $previousBlockAnonymousCount, received ${blockAnonymous.length})';
        }
      }
      previousBlockAnonymousCount = blockAnonymous.length;

      // Check if any responding node in this block had an unknown/damaged/unattributed outcome
      for (final entry in blockEcuResults.entries) {
        final ecuRes = entry.value;
        if (entry.key == 'unattributed') {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'Unattributed response or transaction damage on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}';
        } else if (ecuRes is Mode08MalformedResponse) {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'Malformed response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} from ${entry.key}: ${ecuRes.reason}';
        } else if (ecuRes is Mode08NoResponse) {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'No response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} from ${entry.key}: ${ecuRes.reason}';
        } else if (ecuRes is Mode08NegativeResponse) {
          if (!ecuRes.isUnsupported) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'Negative response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} from ${entry.key} (NRC 0x${ecuRes.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()})';
          }
        }
      }

      for (final anon in blockAnonymous) {
        if (anon is Mode08MalformedResponse) {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'Malformed anonymous response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${anon.reason}';
        } else if (anon is Mode08NoResponse) {
          isComplete = false;
          uncompletedBlocks.add(currentBaseTid);
          overallFailureReason ??=
              'No response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${anon.reason}';
        } else if (anon is Mode08NegativeResponse) {
          if (!anon.isUnsupported) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'Negative response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} (NRC 0x${anon.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()})';
          }
        }
      }

      // Update ECU pending next blocks: clear current block expectations, then record any new declarations
      ecuExpectedNextBlocks.removeWhere((_, expectedTid) => expectedTid == currentBaseTid);
      for (final entry in blockEcuResults.entries) {
        if (entry.key != 'unattributed' && entry.value is Mode08SupportSuccess) {
          final succ = entry.value as Mode08SupportSuccess;
          if (succ.hasNextBlock && currentBaseTid < 0xE0) {
            ecuExpectedNextBlocks[entry.key] = currentBaseTid + 0x20;
          }
        }
      }

      switch (parseResult) {
        case Mode08SupportSuccess success:
          allSupportedTids.addAll(success.supportedTids);
          if (success.hasNextBlock && currentBaseTid < 0xE0) {
            currentBaseTid += 0x20;
          } else {
            // No further blocks declared in aggregate
            if (ecuExpectedNextBlocks.isNotEmpty) {
              isComplete = false;
              uncompletedBlocks.addAll(ecuExpectedNextBlocks.values);
              overallFailureReason ??=
                  'Unqueried blocks announced by ECUs: ${ecuExpectedNextBlocks.values.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ')}';
            }
            if (hadMultipleAnonymousResponses && queriedBlocks.length > 1) {
              isComplete = false;
              overallFailureReason ??=
                  '來源歸因與覆蓋完整度未確認（無標頭回應無法建立跨區塊 ECU 身分）';
            }
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              isComplete: isComplete,
              unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
              failureReason: isComplete ? null : overallFailureReason,
              ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
              perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
            );
          }

        case Mode08NegativeResponse negative:
          if (allSupportedTids.isNotEmpty) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'Negative response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} (NRC 0x${negative.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()})';
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              isComplete: false,
              unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
              failureReason: overallFailureReason,
              nrc: negative.nrc,
              ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
              perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: negative.supportStatus,
            reason: 'ECU returned negative response: NRC 0x${negative.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            nrc: negative.nrc,
            discoveredAt: now,
            queriedBlocks: List.unmodifiable(queriedBlocks),
            unqueriedBlocks: [currentBaseTid],
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );

        case Mode08NoResponse noResponse:
          if (allSupportedTids.isNotEmpty) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'No response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${noResponse.reason}';
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              isComplete: false,
              unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
              failureReason: overallFailureReason,
              ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
              perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: noResponse.supportStatus,
            reason: 'No response from ECU for Mode 08: ${noResponse.reason}',
            discoveredAt: now,
            queriedBlocks: List.unmodifiable(queriedBlocks),
            unqueriedBlocks: [currentBaseTid],
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );

        case Mode08MalformedResponse malformed:
          if (allSupportedTids.isNotEmpty) {
            isComplete = false;
            uncompletedBlocks.add(currentBaseTid);
            overallFailureReason ??=
                'Malformed response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${malformed.reason}';
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              isComplete: false,
              unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
              failureReason: overallFailureReason,
              ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
              perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: EcuSupportStatus.unknown,
            reason: 'Malformed Mode 08 response: ${malformed.reason}',
            discoveredAt: now,
            queriedBlocks: List.unmodifiable(queriedBlocks),
            unqueriedBlocks: [currentBaseTid],
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );

        case Mode08ExecutionSuccess _:
          return Mode08DiscoveryResult.failure(
            supportStatus: EcuSupportStatus.unknown,
            reason: 'Unexpected execution response for supported TID query',
            discoveredAt: now,
            queriedBlocks: List.unmodifiable(queriedBlocks),
            unqueriedBlocks: [currentBaseTid],
            ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
            perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
          );
      }
    }

    if (ecuExpectedNextBlocks.isNotEmpty) {
      isComplete = false;
      uncompletedBlocks.addAll(ecuExpectedNextBlocks.values);
      overallFailureReason ??=
          'Unqueried blocks announced by ECUs: ${ecuExpectedNextBlocks.values.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ')}';
    }

    if (hadMultipleAnonymousResponses && queriedBlocks.length > 1) {
      isComplete = false;
      overallFailureReason ??=
          '來源歸因與覆蓋完整度未確認（無標頭回應無法建立跨區塊 ECU 身分）';
    }

    return Mode08DiscoveryResult(
      isSupported: allSupportedTids.isNotEmpty,
      supportStatus: allSupportedTids.isNotEmpty
          ? EcuSupportStatus.supported
          : EcuSupportStatus.unknown,
      supportedTids: Set.unmodifiable(allSupportedTids),
      queriedBlocks: List.unmodifiable(queriedBlocks),
      discoveredAt: now,
      isComplete: isComplete,
      unqueriedBlocks: List.unmodifiable(uncompletedBlocks.toList()..sort()),
      failureReason: isComplete ? null : overallFailureReason,
      ecuResults: _buildAggregatedEcuResults(perEcuBlockResults),
      perEcuBlockResults: _deepUnmodifiablePerEcuBlockResults(perEcuBlockResults),
    );
  }

  static Map<String, Mode08ParseResult> _buildAggregatedEcuResults(
    Map<String, Map<int, Mode08ParseResult>> perEcuBlockResults,
  ) {
    final aggregated = <String, Mode08ParseResult>{};
    for (final ecuId in perEcuBlockResults.keys) {
      final blocksForEcu = perEcuBlockResults[ecuId]!;
      final ecuTids = <int>{};
      bool hadSuccess = false;
      bool lastHasNextBlock = false;
      int lowestBaseTid = 0xFF;
      Mode08MalformedResponse? firstMalformed;
      Mode08NegativeResponse? firstNegativeUnknown;
      Mode08NegativeResponse? firstNegativeUnsupported;
      Mode08NoResponse? firstNoResponse;

      final sortedBlockKeys = blocksForEcu.keys.toList()..sort();
      for (final baseTid in sortedBlockKeys) {
        final outcome = blocksForEcu[baseTid]!;
        switch (outcome) {
          case Mode08SupportSuccess s:
            hadSuccess = true;
            ecuTids.addAll(s.supportedTids);
            lastHasNextBlock = s.hasNextBlock;
            if (baseTid < lowestBaseTid) lowestBaseTid = baseTid;
          case Mode08MalformedResponse m:
            firstMalformed ??= m;
          case Mode08NegativeResponse n:
            if (!n.isUnsupported) {
              firstNegativeUnknown ??= n;
            } else {
              firstNegativeUnsupported ??= n;
            }
          case Mode08NoResponse nr:
            firstNoResponse ??= nr;
          case Mode08ExecutionSuccess _:
            break;
        }
      }

      if (hadSuccess) {
        aggregated[ecuId] = Mode08SupportSuccess(
          baseTid: lowestBaseTid == 0xFF ? 0x00 : lowestBaseTid,
          bitmask: 0,
          supportedTids: ecuTids,
          hasNextBlock: lastHasNextBlock,
        );
      } else if (firstMalformed != null) {
        aggregated[ecuId] = firstMalformed;
      } else if (firstNegativeUnknown != null) {
        aggregated[ecuId] = firstNegativeUnknown;
      } else if (firstNegativeUnsupported != null) {
        aggregated[ecuId] = firstNegativeUnsupported;
      } else if (firstNoResponse != null) {
        aggregated[ecuId] = firstNoResponse;
      }
    }
    return Map.unmodifiable(aggregated);
  }

  static Map<String, Map<int, Mode08ParseResult>> _deepUnmodifiablePerEcuBlockResults(
    Map<String, Map<int, Mode08ParseResult>> input,
  ) {
    final copy = <String, Map<int, Mode08ParseResult>>{};
    for (final entry in input.entries) {
      copy[entry.key] = Map.unmodifiable(entry.value);
    }
    return Map.unmodifiable(copy);
  }
}
