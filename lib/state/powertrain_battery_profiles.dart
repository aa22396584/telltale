/// Session-only authorization for vehicle-specific battery polling.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../obd/pid/pid.dart';
import '../obd/powertrain_battery/powertrain_battery_catalog.dart';
import '../obd/powertrain_battery/profile_catalog_validator.dart';
import '../obd/powertrain_battery/profile_wire_contract.dart';
import 'pid_registry.dart';
import 'powertrain_battery_experiments.dart';

typedef PowertrainBatteryCatalogLoader =
    Future<PowertrainBatteryCatalogSnapshot> Function();

final powertrainBatteryCatalogLoaderProvider =
    Provider<PowertrainBatteryCatalogLoader>(
      (ref) =>
          () => PowertrainBatteryCatalogAsset.load(),
    );

final class PowertrainProfileAuthorization {
  const PowertrainProfileAuthorization({
    required this.vehicleYear,
    required this.sourceRevision,
    required this.connectionGeneration,
  });

  final int vehicleYear;
  final String sourceRevision;
  final int connectionGeneration;

  @override
  bool operator ==(Object other) =>
      other is PowertrainProfileAuthorization &&
      vehicleYear == other.vehicleYear &&
      sourceRevision == other.sourceRevision &&
      connectionGeneration == other.connectionGeneration;

  @override
  int get hashCode =>
      Object.hash(vehicleYear, sourceRevision, connectionGeneration);
}

class PowertrainProfileAuthorizations
    extends Notifier<Map<String, PowertrainProfileAuthorization>> {
  @override
  Map<String, PowertrainProfileAuthorization> build() => const {};

  /// Validates a request and, when every installable gate passes, grants
  /// polling for exactly this connection.
  ///
  /// The profile is named by id and resolved from the verified [snapshot] —
  /// the same snapshot-bound authority the one-shot probe consents use — so
  /// a caller-built profile object cannot smuggle its own wire contract into
  /// a grant. The grant is in-memory only, bound to [connectionGeneration]
  /// and the canonical profile's source revision, and cleared at every
  /// vehicle boundary. A failed re-authorization also revokes any grant the
  /// profile held: a profile the validator no longer accepts must not keep
  /// polling on the strength of an earlier answer.
  ///
  /// Returns null when the profile is not in the verified catalog.
  PowertrainBatteryProfileValidation? authorize({
    required PowertrainBatteryCatalogSnapshot snapshot,
    required String profileId,
    required int vehicleYear,
    required int connectionGeneration,
  }) {
    if (!isPowertrainCatalogSha256(snapshot.catalogSha256)) {
      revoke(profileId);
      return null;
    }
    final profile = snapshot.catalog.profiles
        .where((candidate) => candidate.id == profileId)
        .firstOrNull;
    if (profile == null) {
      revoke(profileId);
      return null;
    }
    final validation = const PowertrainBatteryProfileCatalogValidator()
        .validateProfile(profile, vehicleYear: vehicleYear);
    if (validation.canInstall) {
      state = Map.unmodifiable({
        ...state,
        profile.id: PowertrainProfileAuthorization(
          vehicleYear: vehicleYear,
          sourceRevision: profile.source.revision,
          connectionGeneration: connectionGeneration,
        ),
      });
    } else {
      revoke(profileId);
    }
    return validation;
  }

  void revoke(String profileId) {
    if (!state.containsKey(profileId)) return;
    final next = {...state}..remove(profileId);
    state = Map.unmodifiable(next);
  }

  void invalidateForVehicleBoundary() {
    if (state.isEmpty) return;
    state = const {};
  }

  bool isAuthorized(String profileId) => state.containsKey(profileId);
}

final powertrainProfileAuthorizationsProvider =
    NotifierProvider<
      PowertrainProfileAuthorizations,
      Map<String, PowertrainProfileAuthorization>
    >(PowertrainProfileAuthorizations.new);

final class PowertrainExperimentalProbeConsent {
  const PowertrainExperimentalProbeConsent({
    required this.profileId,
    required this.sourceRevision,
    required this.catalogSha256,
    required this.commandKey,
    required this.vehicleYear,
    required this.connectionGeneration,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String profileId;
  final String sourceRevision;
  final String catalogSha256;
  final String commandKey;
  final int vehicleYear;
  final int connectionGeneration;
  final DateTime issuedAt;
  final DateTime expiresAt;

  String get key => '$profileId\u0000$commandKey';
}

/// Why a one-shot experimental probe was refused, as an identifier.
///
/// The engine names the refusal; `lib/ui/screens/pids/powertrain_battery_copy.dart`
/// owns the words. Until this became an enum the notifier returned a
/// Traditional Chinese sentence and the screen wrapped it in a localized
/// frame, so an English reader was refused with
/// `Not authorized: 目錄完整性雜湊無效` — a localized frame around a sentence
/// no localization could reach.
///
/// The two quarantine arms report a decision taken *earlier*: the quarantine
/// itself was recorded when the attempt cap was hit or when a probe answer was
/// rejected, and this is the tap that runs into it.
enum PowertrainProbeRefusal {
  /// The laboratory was switched off between the screen's check and this one.
  labClosed,

  /// The snapshot carries no verified catalog SHA-256.
  catalogHashInvalid,

  /// No profile in the verified catalog has this id.
  profileNotInCatalog,

  /// The profile is structurally clean but its tier is not probe-eligible.
  profileNotProbeable,

  /// The profile did not pass validation against the chosen model year.
  profileFailedValidation,

  /// The command is not one of the verified profile's own commands.
  commandNotInProfile,

  /// Quarantined because the same command reached its per-connection cap.
  quarantinedAtAttemptCap,

  /// Quarantined because an earlier answer failed its structural checks.
  quarantinedAfterRejectedRead,
}

/// The refusals that may be *recorded* as a per-connection quarantine.
///
/// A quarantine outlives the tap that caused it, so the record has to name
/// which of the two it was. Nothing else may be stored as one: a quarantine
/// saying `labClosed` would survive turning the laboratory back on.
const Set<PowertrainProbeRefusal> kPowertrainQuarantineRefusals = {
  PowertrainProbeRefusal.quarantinedAtAttemptCap,
  PowertrainProbeRefusal.quarantinedAfterRejectedRead,
};

final class PowertrainExperimentalConsentDecision {
  const PowertrainExperimentalConsentDecision.accepted()
    : accepted = true,
      refusal = null,
      attemptCap = PowertrainExperimentalProbeConsents.maxAttemptsPerCommand;

  /// Every refusal names its identifier. There is no constructor that omits
  /// one, so a refusal path added later cannot reach the screen carrying
  /// nothing the screen can translate.
  const PowertrainExperimentalConsentDecision.refused(
    PowertrainProbeRefusal this.refusal, {
    this.attemptCap = PowertrainExperimentalProbeConsents.maxAttemptsPerCommand,
  }) : accepted = false;

  final bool accepted;

  /// Null exactly when [accepted].
  final PowertrainProbeRefusal? refusal;

  /// The per-command attempt cap this decision was judged against.
  ///
  /// Only [PowertrainProbeRefusal.quarantinedAtAttemptCap] renders it, but
  /// every decision carries it so no caller has to supply a default for a
  /// number the policy already owns.
  final int attemptCap;
}

final class PowertrainExperimentalProbeLease {
  const PowertrainExperimentalProbeLease._(this.consent);

  final PowertrainExperimentalProbeConsent consent;
}

/// One-use, in-memory consent and quarantine for experimental probes.
class PowertrainExperimentalProbeConsents
    extends Notifier<Map<String, PowertrainExperimentalProbeConsent>> {
  static const Duration consentLifetime = Duration(minutes: 2);
  static const Duration commandCooldown = Duration(seconds: 5);
  static const int maxAttemptsPerCommand = 3;

  final Map<String, PowertrainProbeRefusal> _quarantines = {};
  final Map<String, int> _attempts = {};
  final Map<String, DateTime> _lastAttemptAt = {};
  PowertrainExperimentalProbeLease? _inFlightLease;

  @override
  Map<String, PowertrainExperimentalProbeConsent> build() => const {};

  PowertrainExperimentalConsentDecision authorize({
    required PowertrainBatteryCatalogSnapshot snapshot,
    required String profileId,
    required String commandKey,
    required int vehicleYear,
    required int connectionGeneration,
    DateTime? now,
  }) {
    if (!ref.read(powertrainBatteryExperimentalAccessProvider)) {
      return const PowertrainExperimentalConsentDecision.refused(
        PowertrainProbeRefusal.labClosed,
      );
    }
    if (!isPowertrainCatalogSha256(snapshot.catalogSha256)) {
      return const PowertrainExperimentalConsentDecision.refused(
        PowertrainProbeRefusal.catalogHashInvalid,
      );
    }
    final profile = snapshot.catalog.profiles
        .where((candidate) => candidate.id == profileId)
        .firstOrNull;
    if (profile == null) {
      return const PowertrainExperimentalConsentDecision.refused(
        PowertrainProbeRefusal.profileNotInCatalog,
      );
    }
    final validation = const PowertrainBatteryProfileCatalogValidator()
        .validateProfile(profile, vehicleYear: vehicleYear);
    if (!validation.canProbe) {
      // Two different refusals, and they used to be one. An empty issue list
      // means the profile is structurally clean and simply not a probe-
      // eligible tier; a non-empty one used to put the validator's own
      // English developer diagnostic on the screen. That diagnostic names a
      // JSON path, which is worth nothing to a driver and is not copy anyone
      // could translate.
      return PowertrainExperimentalConsentDecision.refused(
        validation.issues.isEmpty
            ? PowertrainProbeRefusal.profileNotProbeable
            : PowertrainProbeRefusal.profileFailedValidation,
      );
    }
    if (!profile.commands.any((command) => command.wireKey == commandKey)) {
      return const PowertrainExperimentalConsentDecision.refused(
        PowertrainProbeRefusal.commandNotInProfile,
      );
    }
    final quarantine = _quarantines[profileId];
    if (quarantine != null) {
      return PowertrainExperimentalConsentDecision.refused(quarantine);
    }

    final issuedAt = (now ?? DateTime.now()).toUtc();
    final consent = PowertrainExperimentalProbeConsent(
      profileId: profile.id,
      sourceRevision: profile.source.revision,
      catalogSha256: snapshot.catalogSha256,
      commandKey: commandKey,
      vehicleYear: vehicleYear,
      connectionGeneration: connectionGeneration,
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(consentLifetime),
    );
    state = Map.unmodifiable({...state, consent.key: consent});
    return const PowertrainExperimentalConsentDecision.accepted();
  }

  PowertrainExperimentalProbeLease? take({
    required PowertrainBatteryCatalogSnapshot snapshot,
    required String profileId,
    required String commandKey,
    required int vehicleYear,
    required int connectionGeneration,
    DateTime? now,
  }) {
    if (!ref.read(powertrainBatteryExperimentalAccessProvider) ||
        _inFlightLease != null ||
        _quarantines.containsKey(profileId)) {
      return null;
    }
    final key = '$profileId\u0000$commandKey';
    final consent = state[key];
    if (consent == null) return null;
    final takenAt = (now ?? DateTime.now()).toUtc();
    final canonical = snapshot.catalog.profiles
        .where((profile) => profile.id == profileId)
        .firstOrNull;
    final canonicalCommand = canonical?.commands
        .where((command) => command.wireKey == commandKey)
        .firstOrNull;
    if (consent.vehicleYear != vehicleYear) {
      _remove(key);
      return null;
    }
    if (canonical == null ||
        canonicalCommand == null ||
        consent.catalogSha256 != snapshot.catalogSha256 ||
        consent.sourceRevision != canonical.source.revision ||
        consent.connectionGeneration != connectionGeneration ||
        takenAt.isBefore(consent.issuedAt) ||
        !takenAt.isBefore(consent.expiresAt)) {
      _remove(key);
      return null;
    }
    final attempts = _attempts[key] ?? 0;
    if (attempts >= maxAttemptsPerCommand) {
      quarantine(profileId, PowertrainProbeRefusal.quarantinedAtAttemptCap);
      return null;
    }
    final last = _lastAttemptAt[key];
    if (last != null && takenAt.difference(last) < commandCooldown) return null;

    _remove(key);
    _attempts[key] = attempts + 1;
    _lastAttemptAt[key] = takenAt;
    final lease = PowertrainExperimentalProbeLease._(consent);
    _inFlightLease = lease;
    return lease;
  }

  /// Ends the in-flight lease, quarantining the profile when the probe's own
  /// failure policy says the answer makes it unsafe to try again.
  ///
  /// A bool, not a string. It used to take the probe's `detail` — English
  /// developer prose such as `decoder invariant failed; this profile is
  /// quarantined`, falling back to the raw enum name — and that text was then
  /// rendered to the driver as the reason. Which failure it was is already on
  /// screen in the probe result dialog at the moment it happens; what a later
  /// tap needs to know is only that this connection has stopped trusting the
  /// profile.
  void complete(
    PowertrainExperimentalProbeLease lease, {
    bool quarantineProfile = false,
  }) {
    if (!identical(_inFlightLease, lease)) return;
    _inFlightLease = null;
    if (quarantineProfile) {
      quarantine(
        lease.consent.profileId,
        PowertrainProbeRefusal.quarantinedAfterRejectedRead,
      );
    }
  }

  void quarantine(String profileId, PowertrainProbeRefusal cause) {
    assert(
      kPowertrainQuarantineRefusals.contains(cause),
      'a quarantine outlives the tap that caused it, so only the two '
      'quarantine refusals may be recorded as one',
    );
    _quarantines[profileId] = cause;
    final next = {...state}
      ..removeWhere((_, consent) => consent.profileId == profileId);
    state = Map.unmodifiable(next);
  }

  /// Why this profile is quarantined for this connection, or null.
  PowertrainProbeRefusal? quarantineReason(String profileId) =>
      _quarantines[profileId];

  void invalidateForVehicleBoundary() {
    state = const {};
    _quarantines.clear();
    _attempts.clear();
    _lastAttemptAt.clear();
    _inFlightLease = null;
  }

  /// Revokes unused consent without resetting connection-scoped safeguards.
  ///
  /// A consumed lease stays marked in flight until its caller unwinds. This
  /// prevents a pause/resume or off/on cycle from overlapping a second probe
  /// with an older command that may already be on the adapter wire.
  void revokeAll() {
    state = const {};
  }

  void _remove(String key) {
    if (!state.containsKey(key)) return;
    final next = {...state}..remove(key);
    state = Map.unmodifiable(next);
  }
}

final powertrainExperimentalProbeConsentsProvider =
    NotifierProvider<
      PowertrainExperimentalProbeConsents,
      Map<String, PowertrainExperimentalProbeConsent>
    >(PowertrainExperimentalProbeConsents.new);

/// Keeps a catalog-derived PID only under a live, matching authorization.
///
/// A profile PID passes when its owner holds an authorization for exactly
/// this connection generation whose source revision matches the PID's own —
/// so a grant from a previous connection, another vehicle, or a catalog that
/// has since changed underneath the install authorizes nothing. Ordinary and
/// user-authored PIDs pass untouched.
List<Pid> filterAuthorizedPowertrainPids(
  Iterable<Pid> pids,
  Map<String, PowertrainProfileAuthorization> authorizations, {
  required int connectionGeneration,
}) => List.unmodifiable([
  for (final pid in pids)
    if (pid.ownerProfileId == null)
      pid
    else if (isLivePowertrainAuthorization(
      authorizations[pid.ownerProfileId],
      connectionGeneration: connectionGeneration,
      sourceRevision: pid.sourceRevision,
    ))
      pid,
]);

/// The one definition of "this grant is live for that definition, now".
///
/// Shared by the polling filter and the dashboard confirmation banner so the
/// two can never disagree: a grant the poller refuses (stale generation or a
/// catalog revision that changed under the install) must make the banner ask
/// again, not hide the row over dark gauges.
bool isLivePowertrainAuthorization(
  PowertrainProfileAuthorization? authorization, {
  required int connectionGeneration,
  required String? sourceRevision,
}) =>
    authorization != null &&
    authorization.connectionGeneration == connectionGeneration &&
    sourceRevision != null &&
    authorization.sourceRevision == sourceRevision;

/// The verified catalog snapshot, shared by every screen that needs it.
///
/// Loading through one provider keeps the integrity check in one place; a
/// catalog that fails verification surfaces here as an error state rather
/// than as partially loaded data somewhere. Riverpod's automatic retry is
/// disabled: an integrity failure is deterministic — the bundled bytes will
/// not change between attempts — and the catalog screen offers an explicit
/// re-verify action instead.
final powertrainBatteryCatalogSnapshotProvider =
    FutureProvider<PowertrainBatteryCatalogSnapshot>(
      retry: (retryCount, error) => null,
      (ref) => ref.watch(powertrainBatteryCatalogLoaderProvider)(),
    );

/// Rebuilds installed profile PIDs from the verified bundled catalog.
///
/// Watched once at app start; until it completes, installed profiles simply
/// have no runtime PIDs, which fails closed. A catalog that fails its
/// integrity check restores nothing.
final installedPowertrainProfilesRestoreProvider = FutureProvider<void>(
  // A catalog-integrity failure is deterministic — the bundled bytes will
  // not change between attempts — so retrying it is noise. A storage
  // failure inside the restore itself is not: locking a whole session out
  // of installation because one preferences write failed once would turn a
  // transient hiccup into a restart-only recovery.
  retry: (retryCount, error) {
    if (error is PowertrainBatteryCatalogAssetException) return null;
    if (retryCount >= 5) return null;
    return Duration(milliseconds: 200 * (1 << retryCount));
  },
  (ref) async {
    final snapshot = await ref.watch(
      powertrainBatteryCatalogSnapshotProvider.future,
    );
    await ref
        .read(pidRegistryProvider.notifier)
        .restoreInstalledProfiles(snapshot.catalog);
  },
);
