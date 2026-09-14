/// Workshop service recipes and Mode 08 capability discovery state management.
///
/// Ref: Issue #131 ([ACTIVE-01]), Issue #132, Parent: #25.
///
/// SAFETY CONTRACT:
/// - Candidate matrix enforces Zero Live Candidates (0 live vehicles qualified).
/// - Mode 08 discovery results are strictly connection-scoped and wiped on disconnect.
/// - Non-actuating discovery is restricted to OBD-II CAN bus sessions.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../diagnostics/service_recipes/active_test_profile.dart';
import '../diagnostics/service_recipes/candidate_matrix.dart';
import '../diagnostics/service_recipes/mode08_discovery_service.dart';
import '../diagnostics/service_recipes/qualification_tier.dart';
import 'obd_session.dart';

/// Function type for loading a [CandidateMatrix] from asset storage or fakes.
typedef CandidateMatrixLoader = Future<CandidateMatrix> Function();

/// Provider for loading the active-test candidate matrix.
final candidateMatrixLoaderProvider = Provider<CandidateMatrixLoader>((ref) {
  return () async {
    final profiles = <ActiveTestProfile>[];
    for (final path in BundledServiceRecipes.bundledAssetPaths) {
      final jsonString = await rootBundle.loadString(path);
      profiles.add(BundledServiceRecipes.parseProfileJson(jsonString));
    }
    return CandidateMatrix.fromProfiles(profiles);
  };
});

/// Future provider exposing the loaded [CandidateMatrix].
final serviceRecipesMatrixProvider = FutureProvider<CandidateMatrix>((ref) async {
  final loader = ref.watch(candidateMatrixLoaderProvider);
  return await loader();
});

/// Phase of the Mode 08 non-actuating discovery process.
enum Mode08DiscoveryPhase {
  idle,
  discovering,
  completed,
  failed,
  refused,
}

/// Immutable state for Mode 08 discovery.
final class Mode08DiscoveryState {
  const Mode08DiscoveryState._({
    required this.phase,
    this.result,
    this.message,
    this.nrc,
    this.startedAt,
  });

  const Mode08DiscoveryState.idle()
      : this._(phase: Mode08DiscoveryPhase.idle);

  const Mode08DiscoveryState.discovering({required DateTime startedAt})
      : this._(
          phase: Mode08DiscoveryPhase.discovering,
          startedAt: startedAt,
        );

  const Mode08DiscoveryState.completed({required Mode08DiscoveryResult result})
      : this._(
          phase: Mode08DiscoveryPhase.completed,
          result: result,
        );

  const Mode08DiscoveryState.failed({
    required String message,
    int? nrc,
  }) : this._(
          phase: Mode08DiscoveryPhase.failed,
          message: message,
          nrc: nrc,
        );

  const Mode08DiscoveryState.refused({required String reason})
      : this._(
          phase: Mode08DiscoveryPhase.refused,
          message: reason,
        );

  final Mode08DiscoveryPhase phase;
  final Mode08DiscoveryResult? result;
  final String? message;
  final int? nrc;
  final DateTime? startedAt;

  bool get isIdle => phase == Mode08DiscoveryPhase.idle;
  bool get isDiscovering => phase == Mode08DiscoveryPhase.discovering;
  bool get isCompleted => phase == Mode08DiscoveryPhase.completed;
  bool get isFailed => phase == Mode08DiscoveryPhase.failed;
  bool get isRefused => phase == Mode08DiscoveryPhase.refused;
}

/// Notifier managing the lifecycle of Mode 08 supported TID discovery.
class Mode08DiscoveryNotifier extends Notifier<Mode08DiscoveryState> {
  @override
  Mode08DiscoveryState build() {
    // Invalidate / reset discovery state when session connection changes
    ref.listen(obdSessionProvider, (previous, next) {
      if (previous?.isConnected == true && !next.isConnected) {
        state = const Mode08DiscoveryState.idle();
      }
    });

    return const Mode08DiscoveryState.idle();
  }

  /// Initiates non-actuating Mode 08 discovery against the connected vehicle/adapter.
  Future<void> runDiscovery({
    Duration timeout = Mode08DiscoveryService.defaultDiscoveryTimeout,
    Duration budget = Mode08DiscoveryService.defaultTotalBudget,
    DateTime? deadline,
  }) async {
    final connection = ref.read(obdSessionProvider);
    if (!connection.isConnected) {
      state = const Mode08DiscoveryState.refused(
        reason: 'OBD session is not connected',
      );
      return;
    }

    final client = ref.read(obdSessionProvider.notifier).client;
    if (client == null) {
      state = const Mode08DiscoveryState.refused(
        reason: 'OBD client is not available',
      );
      return;
    }

    if (!client.addressing.isCan || !client.addressing.supportsObd2) {
      state = const Mode08DiscoveryState.refused(
        reason: 'Mode 08 capability discovery requires an OBD-II CAN bus',
      );
      return;
    }

    state = Mode08DiscoveryState.discovering(startedAt: DateTime.now().toUtc());

    try {
      final discoveryResult = await Mode08DiscoveryService.discoverSupportedTids(
        client: client,
        timeout: timeout,
        budget: budget,
        deadline: deadline,
      );

      if (discoveryResult.supportStatus == EcuSupportStatus.supported ||
          discoveryResult.supportStatus == EcuSupportStatus.unsupported) {
        state = Mode08DiscoveryState.completed(result: discoveryResult);
      } else {
        state = Mode08DiscoveryState.failed(
          message: discoveryResult.failureReason ?? 'Mode 08 discovery inconclusive',
          nrc: discoveryResult.nrc,
        );
      }
    } catch (e) {
      state = Mode08DiscoveryState.failed(
        message: 'Unexpected discovery failure: $e',
      );
    }
  }

  /// Manually resets discovery state.
  void reset() {
    state = const Mode08DiscoveryState.idle();
  }
}

/// Provider managing Mode 08 discovery state.
final mode08DiscoveryStateProvider =
    NotifierProvider<Mode08DiscoveryNotifier, Mode08DiscoveryState>(
  Mode08DiscoveryNotifier.new,
);

/// Report summarizing safety status and Zero Live Candidates guarantee.
final class ServiceRecipesSafetyReport {
  const ServiceRecipesSafetyReport({
    required this.liveCandidateCount,
    required this.hasLiveCandidates,
    required this.totalProfilesCount,
    required this.simulationReadyCount,
    required this.liveExecutionProhibited,
  });

  final int liveCandidateCount;
  final bool hasLiveCandidates;
  final int totalProfilesCount;
  final int simulationReadyCount;
  final bool liveExecutionProhibited;
}

/// Provider evaluating and exposing the Zero Live Candidates safety report.
final serviceRecipesSafetyReportProvider =
    Provider<AsyncValue<ServiceRecipesSafetyReport>>((ref) {
  final matrixAsync = ref.watch(serviceRecipesMatrixProvider);
  return matrixAsync.whenData((matrix) {
    return ServiceRecipesSafetyReport(
      liveCandidateCount: matrix.liveCandidateCount,
      hasLiveCandidates: matrix.hasLiveCandidates,
      totalProfilesCount: matrix.entries.length,
      simulationReadyCount: matrix.simulationReadyEntries.length,
      liveExecutionProhibited: !matrix.hasLiveCandidates,
    );
  });
});
