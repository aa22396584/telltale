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
    this.failureReason,
    this.nrc,
  });

  /// Factory for a failed or refused discovery attempt.
  factory Mode08DiscoveryResult.failure({
    required EcuSupportStatus supportStatus,
    required String reason,
    int? nrc,
    DateTime? discoveredAt,
  }) =>
      Mode08DiscoveryResult(
        isSupported: false,
        supportStatus: supportStatus,
        supportedTids: const {},
        queriedBlocks: const [],
        discoveredAt: discoveredAt ?? DateTime.now().toUtc(),
        failureReason: reason,
        nrc: nrc,
      );

  /// Whether Mode 08 is affirmatively supported by the ECU.
  final bool isSupported;

  /// Strict protocol classification: [EcuSupportStatus.supported], [EcuSupportStatus.unsupported], or [EcuSupportStatus.unknown].
  final EcuSupportStatus supportStatus;

  /// Set of all supported test IDs (TIDs) decoded from 32-bit bitmasks.
  final Set<int> supportedTids;

  /// Base TIDs queried during this discovery session (e.g. `[0x00, 0x20]`).
  final List<int> queriedBlocks;

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
    int currentBaseTid = 0x00;

    final stopwatch = Stopwatch()..start();

    while (currentBaseTid <= 0xE0) {
      if (stopwatch.elapsed >= budget) {
        if (allSupportedTids.isNotEmpty) {
          // Budget expired between blocks but earlier blocks succeeded
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            failureReason: 'Discovery budget reached before all blocks queried',
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Discovery budget exceeded',
          discoveredAt: now,
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
          budget: budget - stopwatch.elapsed,
          deadline: deadline,
          owner: owner,
        );
      } on TimeoutException {
        if (allSupportedTids.isNotEmpty) {
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            failureReason: 'Query timed out for block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Mode 08 query timed out',
          discoveredAt: now,
        );
      } on TransportException catch (e) {
        if (allSupportedTids.isNotEmpty) {
          return Mode08DiscoveryResult(
            isSupported: true,
            supportStatus: EcuSupportStatus.supported,
            supportedTids: Set.unmodifiable(allSupportedTids),
            queriedBlocks: List.unmodifiable(queriedBlocks),
            discoveredAt: now,
            failureReason: 'Transport failed during block query: $e',
          );
        }
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Mode 08 transport failed: $e',
          discoveredAt: now,
        );
      } catch (e) {
        return Mode08DiscoveryResult.failure(
          supportStatus: EcuSupportStatus.unknown,
          reason: 'Internal error during Mode 08 discovery: $e',
          discoveredAt: now,
        );
      }

      queriedBlocks.add(currentBaseTid);
      final rawResponse = response.rawLines.join('\n');
      final parseResult = Mode08DiscoveryCodec.parseResponse(
        rawResponse,
        expectedBaseTid: currentBaseTid,
      );

      switch (parseResult) {
        case Mode08SupportSuccess success:
          allSupportedTids.addAll(success.supportedTids);
          if (success.hasNextBlock && currentBaseTid < 0xE0) {
            currentBaseTid += 0x20;
          } else {
            // No further blocks to query
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
            );
          }

        case Mode08NegativeResponse negative:
          if (allSupportedTids.isNotEmpty) {
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              failureReason: 'Negative response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()} (NRC 0x${negative.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()})',
              nrc: negative.nrc,
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: negative.supportStatus,
            reason: 'ECU returned negative response: NRC 0x${negative.nrc.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            nrc: negative.nrc,
            discoveredAt: now,
          );

        case Mode08NoResponse noResponse:
          if (allSupportedTids.isNotEmpty) {
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              failureReason: 'No response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${noResponse.reason}',
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: noResponse.supportStatus,
            reason: 'No response from ECU for Mode 08: ${noResponse.reason}',
            discoveredAt: now,
          );

        case Mode08MalformedResponse malformed:
          if (allSupportedTids.isNotEmpty) {
            return Mode08DiscoveryResult(
              isSupported: true,
              supportStatus: EcuSupportStatus.supported,
              supportedTids: Set.unmodifiable(allSupportedTids),
              queriedBlocks: List.unmodifiable(queriedBlocks),
              discoveredAt: now,
              failureReason: 'Malformed response on block 0x${currentBaseTid.toRadixString(16).padLeft(2, '0').toUpperCase()}: ${malformed.reason}',
            );
          }
          return Mode08DiscoveryResult.failure(
            supportStatus: EcuSupportStatus.unknown,
            reason: 'Malformed Mode 08 response: ${malformed.reason}',
            discoveredAt: now,
          );

        case Mode08ExecutionSuccess _:
          // Execution responses cannot be returned for a supported-TIDs query
          return Mode08DiscoveryResult.failure(
            supportStatus: EcuSupportStatus.unknown,
            reason: 'Unexpected execution response for supported TID query',
            discoveredAt: now,
          );
      }
    }

    return Mode08DiscoveryResult(
      isSupported: allSupportedTids.isNotEmpty,
      supportStatus: allSupportedTids.isNotEmpty ? EcuSupportStatus.supported : EcuSupportStatus.unknown,
      supportedTids: Set.unmodifiable(allSupportedTids),
      queriedBlocks: List.unmodifiable(queriedBlocks),
      discoveredAt: now,
    );
  }
}
