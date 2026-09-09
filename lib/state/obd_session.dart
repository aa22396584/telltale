/// Connection lifecycle and live telemetry.
///
/// One controller owns the whole chain — transport → [Elm327Client] →
/// [PollingEngine] — because their lifetimes are identical and splitting them
/// across providers would mean three places that each have to know when the
/// other two are valid.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/elapsed_realtime.dart';
import '../core/field_evidence/evidence_text.dart';
import '../core/field_evidence/platform_metadata.dart';
import '../core/network/android_wifi_route_binder.dart';
import '../core/serial/spp_serial_platform.dart';
import '../obd/dtc/dtc.dart';
import '../obd/elapsed_clock.dart';
import '../obd/elm327_client.dart';
import '../obd/pid/pid.dart';
import '../obd/freeze_frame.dart';
import '../obd/polling_engine.dart';
import '../obd/powertrain_battery/powertrain_battery_catalog.dart';
import '../obd/powertrain_battery/powertrain_battery_probe.dart';
import '../obd/session_boundary.dart';
import '../obd/session_evidence.dart';
import '../obd/transcript_store.dart';
import '../obd/telemetry.dart';
import '../obd/transcript.dart';
import '../obd/transport/ble_transport.dart';
import '../obd/transport/classic_transport.dart';
import '../obd/transport/demo_transport.dart';
import '../obd/transport/obd_transport.dart';
import '../obd/transport/serial_transport.dart';
import '../obd/transport/wifi_transport.dart';
import 'manual_command_refusal.dart';
import 'pid_registry.dart';
import 'powertrain_battery_profiles.dart';
import 'powertrain_battery_experiments.dart';
import 'settings.dart';
import 'transcript_store_runtime.dart';
import 'vehicle_identity.dart';

enum ConnectionPhase {
  disconnected,
  connecting,
  handshaking,
  connected,
  failed,
}

/// Physical events a passenger can stamp into the same timeline as OBD bytes.
///
/// These are intentionally presets rather than free text: one large tap while
/// parked is safer and less error-prone than typing beside a running vehicle.
enum FieldEventMarker {
  ignitionOn('電門 ON'),
  engineStarted('引擎發動'),
  throttleBlip('輕踩油門'),
  roadTestStarted('道路測試開始');

  const FieldEventMarker(this.label);

  final String label;
}

/// Why a connection attempt ended, as an identifier the screen can translate.
///
/// [ObdConnectionState.error] keeps its sentence: `_failAttempt` writes it into
/// the attempt transcript, and a record whose language follows a phone setting
/// is one nobody can compare with anybody else's. This says the same thing
/// without the words.
///
/// Nothing here covers a [TransportException]: those sentences are authored by
/// the four transports and are still passed through as text.
enum ObdConnectionIssue {
  /// No step reported a failure, so there is nothing more specific to say.
  handshakeIncomplete,

  /// The very first command went unanswered. This is a different diagnosis
  /// from a later step failing: it usually means the paired device is not an
  /// ELM327 at all, rather than that the vehicle is asleep.
  adapterSilentOnReset,

  /// A named step failed. Which one it was is the whole value of the message.
  handshakeStepFailed,

  /// The link came up and then nothing answered — most often an adapter that
  /// is not powered, because most OBD sockets are dead until the ignition is
  /// on.
  adapterAcceptedThenSilent,

  connectionSetupFailed,
  previousConnectionStillAborting,
  adapterStoppedResponding,
}

/// What a busy connection is waiting for, as an identifier.
enum ObdConnectionActivity { abortingPreviousConnection }

enum FieldEventRecordResult { persisted, memoryOnly, unavailable }

class ObdConnectionState {
  final ConnectionPhase phase;
  final TransportKind? kind;
  final String deviceName;
  final String protocol;

  /// What the connection is waiting on right now, for the phase where nothing
  /// else moves — the transport's own attempt, before any handshake step has
  /// been sent.
  final String detail;

  /// Adapter supply voltage at the handshake, or null if it was never read.
  ///
  /// Nullable for the reason `TelemetrySnapshot` gives for the same quantity:
  /// zero volts is a *claim* about the battery, and an unread value is the
  /// absence of one. It was a non-nullable double defaulting to 0 — no current
  /// consumer was misled, because the dashboard reads the snapshot's value,
  /// and that is exactly the shape a future one falls into.
  final double? batteryVoltage;
  final String? error;

  /// The same fact as [error], as an identifier. Null where the sentence came
  /// from a transport rather than from this file.
  final ObdConnectionIssue? issue;

  /// The step [ObdConnectionIssue.handshakeStepFailed] is about.
  final InitProgress? issueStep;

  /// The same fact as [error] when the sentence came from a transport.
  ///
  /// [issue] covers what this file diagnoses; this covers what the four
  /// transports diagnose. They are never both set: a given failure is authored
  /// in one place or the other, and the screen asks for them in that order.
  final TransportIssue? transportIssue;

  /// The same fact as [detail], as an identifier.
  final ObdConnectionActivity? activity;

  /// Handshake steps observed so far, in order, for the wizard's live list.
  final List<InitProgress> initSteps;

  const ObdConnectionState({
    this.phase = ConnectionPhase.disconnected,
    this.kind,
    this.deviceName = '',
    this.protocol = '',
    this.detail = '',
    this.batteryVoltage,
    this.error,
    this.issue,
    this.issueStep,
    this.transportIssue,
    this.activity,
    this.initSteps = const [],
  });

  bool get isConnected => phase == ConnectionPhase.connected;
  bool get isBusy =>
      phase == ConnectionPhase.connecting ||
      phase == ConnectionPhase.handshaking;

  ObdConnectionState copyWith({
    ConnectionPhase? phase,
    TransportKind? kind,
    String? deviceName,
    String? protocol,
    String? detail,
    double? batteryVoltage,
    String? error,
    ObdConnectionIssue? issue,
    InitProgress? issueStep,
    TransportIssue? transportIssue,
    ObdConnectionActivity? activity,
    bool clearError = false,
    List<InitProgress>? initSteps,
  }) {
    return ObdConnectionState(
      phase: phase ?? this.phase,
      kind: kind ?? this.kind,
      deviceName: deviceName ?? this.deviceName,
      protocol: protocol ?? this.protocol,
      detail: detail ?? this.detail,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      error: clearError ? null : (error ?? this.error),
      // The identifier travels with the sentence, in both directions. Clearing
      // one and keeping the other would leave the screen rendering the reason
      // for a failure that is no longer being reported.
      issue: clearError ? null : (issue ?? this.issue),
      issueStep: clearError ? null : (issueStep ?? this.issueStep),
      transportIssue: clearError
          ? null
          : (transportIssue ?? this.transportIssue),
      // Likewise for the busy line: a caller that sets `detail` and not
      // `activity` is replacing the line, not annotating the old one. Without
      // this, a Bluetooth Classic tier notice inherited "aborting the previous
      // connection" and the screen kept saying it for the rest of the attempt.
      activity: detail != null ? activity : (activity ?? this.activity),
      initSteps: initSteps ?? this.initSteps,
    );
  }
}

/// Wire-owner token for a consented experimental read.
///
/// Unlike the polling engine's integer lifecycle epoch, this also survives an
/// experimental-access off/on cycle: turning the laboratory off retires every
/// already-consumed lease even if it is re-enabled before a queued command
/// reaches the adapter.
final class _PowertrainProbeWireOwner {
  const _PowertrainProbeWireOwner({
    required this.pauseEpoch,
    required this.connectionGeneration,
    required this.experimentalAccessEpoch,
  });

  final int pauseEpoch;
  final int connectionGeneration;
  final int experimentalAccessEpoch;
}

/// Turns an exception thrown while connecting into a sentence for a driver.
///
/// `'$e'` used to reach the screen directly. Measured on a phone, 2026-08-20,
/// against a BLE peripheral that accepts a GATT connection and then answers
/// nothing:
///
///     TimeoutException after 0:00:10.000000: Future not completed
///
/// One branch away, a failed handshake says 轉接器可能不相容 — something a
/// person at a car can act on. This path had no equivalent, so anything that
/// was not a `TransportException` arrived verbatim.
///
/// The raw text is not discarded: `_failAttempt` writes it into the transcript,
/// which is where a maintainer reads it. This decides only what the driver sees.
String describeConnectException(Object error) {
  if (error is TimeoutException) {
    return 'The adapter accepted the connection but answered nothing in time. '
        'Usually it is not powered yet — most OBD sockets only supply power '
        'with the ignition on — or another app is already connected to it, '
        'in which case close that one and try again.';
  }
  return 'The connection failed while it was being established. Check that '
      'the adapter has power and is nearby, then try again. The full error '
      'is kept in the log below.';
}

/// The identifier for the sentence [describeConnectException] chose.
ObdConnectionIssue connectExceptionIssue(Object error) =>
    error is TimeoutException
    ? ObdConnectionIssue.adapterAcceptedThenSilent
    : ObdConnectionIssue.connectionSetupFailed;

class ObdSession extends Notifier<ObdConnectionState> {
  Elm327Client? _client;
  PollingEngine? _engine;

  /// Build provenance is compile-time in production and injectable only so
  /// unit tests can lock the safety boundary without launching an APK.
  @visibleForTesting
  bool testRigBuild = isObdTestRigBuild;

  /// Frozen into [_sessionEvidence] when an attempt starts. The exact Android
  /// application ID is authoritative. Only the exact production Android ID is
  /// field eligible; every other Android ID fails closed as simulated.
  @visibleForTesting
  PlatformMetadata platformMetadata = platformMetadataCache.value;

  bool get _currentSessionIsTestRig =>
      _sessionEvidence?.testRig ??
      (testRigBuild || platformMetadata.requiresSimulatedEvidence);

  /// Narrow provenance seam for recording/export labels.
  ///
  /// `false` means only that this production app connection is eligible for
  /// field evidence; it is never a claim that a physical vehicle was proven.
  bool get requiresSimulatedEvidence => _currentSessionIsTestRig;

  StreamSubscription<InitProgress>? _initSub;
  StreamSubscription<TelemetrySnapshot>? _snapshotSub;

  final _telemetry = StreamController<TelemetrySnapshot>.broadcast();
  final _sessionBoundaries = StreamController<ObdSessionBoundary>.broadcast(
    sync: true,
  );
  final _foregroundChanges = StreamController<bool>.broadcast(sync: true);

  @override
  ObdConnectionState build() {
    // Absence of a binding lifecycle sample is not evidence that the app is
    // visible. The first resumed edge will open the foreground gate.
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    transcriptStore = ref.read(obdTranscriptStoreProvider);
    // Keep the running poller in step with the user's PID selection. Without
    // this the polling set is frozen at whatever it was when the session
    // connected: a gauge added from the PID manager shows dashes forever, and
    // one removed keeps consuming bus bandwidth.
    ref.listen(activePidsProvider, (previous, next) => syncActivePids(next));
    ref.listen(powertrainProfileAuthorizationsProvider, (previous, next) {
      if (previous != next) syncActivePids(ref.read(activePidsProvider));
    });
    ref.listen(powertrainBatteryExperimentalAccessProvider, (previous, next) {
      if (!next) {
        _experimentalAccessEpoch++;
        ref
            .read(powertrainExperimentalProbeConsentsProvider.notifier)
            .revokeAll();
      }
    });
    // A confirmed profile opens the MAP/MAF inputs used by speed-density and
    // power estimates. Editing it closes that lane again immediately; only
    // the ECU's measured fuel rate and speed remain as supplemental inputs.
    ref.listen(vehicleProfileProvider, (previous, next) {
      if (previous?.isConfirmed != next.isConfirmed) {
        syncActivePids(ref.read(activePidsProvider));
      }
      if (previous == null ||
          SessionEvidenceMetadata.vehicleProfileSnapshotJson(previous) ==
              SessionEvidenceMetadata.vehicleProfileSnapshotJson(next)) {
        return;
      }
      final client = _client;
      final transcript = _attemptTranscript;
      if (client == null ||
          transcript == null ||
          !identical(client.transcript, transcript) ||
          _sessionEvidenceGeneration != _generation) {
        return;
      }
      transcript.recordPinnedNote(
        SessionEvidenceMetadata.vehicleProfileChangeNote(
          next,
          recordedAt: DateTime.now().toUtc(),
        ),
      );
    });

    // A vehicle session is foreground-only, and saying so explicitly is the
    // fix for two problems at once: the app must stop putting traffic on a
    // car's bus while the user is elsewhere, and it must not present values
    // captured before the interruption as current when they come back.
    _lifecycle = AppLifecycleListener(
      onHide: _onAppPaused,
      onPause: _onAppPaused,
      onResume: () => unawaited(_onAppResumed()),
    );

    ref.onDispose(() {
      // First, so anything still in flight is already superseded.
      //
      // A resume probe outlives the provider: it is a three-second `ATRV` on
      // an unawaited chain, and if the container is disposed while it is out
      // there, its failure path used to run against a dead `Ref` and throw
      // "Cannot use the Ref … after it has been disposed" out of a zone
      // nobody catches. The generation counter is exactly the token for "this
      // session is over"; disposal is the strongest form of that and was the
      // one case not stamping it.
      _generation++;
      _lifecycle?.dispose();
      _lifecycle = null;
      unawaited(_teardown());
      unawaited(_telemetry.close());
      unawaited(_sessionBoundaries.close());
      unawaited(_foregroundChanges.close());
    });
    return const ObdConnectionState();
  }

  AppLifecycleListener? _lifecycle;

  /// True when the poller was stopped by the app going to the background,
  /// as opposed to by the user or a failure.
  bool _pausedByLifecycle = false;

  /// True between a lifecycle resume edge and a successful ATRV (or an
  /// explicit abort). Keeps [isForeground] closed so driving-safety cannot
  /// authorize record/share/history on pre-pause telemetry while `_pauseNow`
  /// is still draining or the link probe has not finished.
  bool _awaitingResumeValidation = false;

  /// Whether the app is in the foreground *now*.
  ///
  /// Tracked separately from [_pausedByLifecycle] and from whether an engine
  /// exists. `_onAppPaused` used to return early when `_engine == null`, so a
  /// connection still running its protocol search — up to 25 seconds — would
  /// finish in the background, install an engine and start polling with no
  /// record that the app had ever been backgrounded. The next resume then saw
  /// nothing to recover and skipped revalidation entirely.
  /// How long the census fired at connect may take before it gives up.
  ///
  /// Generous — it competes with the first poll and a slow adapter's four
  /// commands — but finite, which is the point.
  static const Duration censusBudget = Duration(seconds: 20);

  // Fake sessions used by provider-level tests can override [build] entirely.
  // Real sessions always overwrite this in [build] from the binding lifecycle,
  // where a null lifecycle remains fail-closed.
  bool _foreground = true;

  /// Whether the app is in the foreground.
  ///
  /// Public because the poll loop is not the only thing that talks to the
  /// vehicle. A fault-code scan spans three code classes and a VIN, support
  /// discovery runs its own command chain, and a protocol search can hold one
  /// for twenty-five seconds — none of which `_onAppPaused` was stopping. The
  /// app's foreground-only policy has to cover every producer, or the comments
  /// claiming the session is parked are describing one of them.
  bool get isForeground => _foreground;

  /// Synchronous lifecycle edge for root-owned artifact controllers.
  Stream<bool> get foregroundChanges => _foregroundChanges.stream;

  /// Serialises lifecycle transitions.
  ///
  /// Pause and resume had independent asynchronous owners: `_pauseNow` ran
  /// unawaited, so a quick resume could complete its `ATRV` probe and start a
  /// new polling loop before the old `stop()` had returned. The old stop then
  /// reset the acceleration baseline and formula cache belonging to the *new*
  /// loop, and the pause's empty snapshot landed after it had begun
  /// publishing. One chain means a resume cannot overtake the pause it
  /// follows.
  Future<void> _lifecycleChain = Future<void>.value();

  /// How many times the app has been backgrounded this session.
  ///
  /// `isForeground` is a *sample*, and a scan checking it at each checkpoint
  /// cannot see a suspension that began and ended between two of them — every
  /// check passes and the verdict is assembled across a gap nobody owned,
  /// which is the exact reason the check was added. A counter cannot miss it:
  /// the interruption leaves a mark whether or not anyone was looking.
  int _pauseEpoch = 0;

  /// Advances whenever the laboratory is disabled so an already-consumed
  /// lease cannot become live again after an off/on cycle.
  int _experimentalAccessEpoch = 0;

  /// The value a long operation should capture and re-compare.
  int get pauseEpoch => _pauseEpoch;

  /// Monotonic owner token for session-only experimental consent.
  int get connectionGeneration => _generation;

  void _onAppPaused() {
    // Android/iOS commonly emit hidden followed by paused. Desktop may emit
    // hidden without paused. One synchronous edge must cover both without
    // double-counting the same suspension.
    //
    // Also count a suspension that arrives while resume validation still has
    // the safety gate closed (`_awaitingResumeValidation`): foreground is
    // already false there, but the user did leave again mid-ATRV.
    if (!_foreground && !_awaitingResumeValidation) return;
    // Snapshot first, before anything else this method does.
    //
    // `onPause` is the last callback Android reliably delivers before it is
    // free to kill the process, and a session killed in a car park is exactly
    // the one somebody would want to read afterwards — it went wrong in a way
    // the user could not sit and watch. Unawaited because the freeze can begin
    // as soon as this returns; a write that does not finish leaves the
    // previous snapshot intact, which is the whole reason it is staged and
    // renamed rather than written in place.
    _client?.transcript.recordNote('App 進入背景');
    unawaited(_saveTranscriptSnapshot());
    _pauseEpoch++;
    _awaitingResumeValidation = false;
    final wasForeground = _foreground;
    _foreground = false;
    ref.read(powertrainExperimentalProbeConsentsProvider.notifier).revokeAll();
    if (wasForeground && !_foregroundChanges.isClosed) {
      _foregroundChanges.add(false);
    }
    // Synchronously, and before anything is queued. The freeze can start at
    // any moment after this callback returns, and the watchdog's next tick
    // will be delivered after it against a wall clock that moved on — so the
    // flag has to be set now, not by whatever the lifecycle chain gets round
    // to.
    _client?.suspendLiveness();
    final engine = _engine;
    if (engine == null || !engine.isRunning) return;
    _pausedByLifecycle = true;
    _lifecycleChain = _lifecycleChain.then((_) => _pauseNow(engine));
  }

  /// Stops the poller, then says so on screen.
  ///
  /// In that order. Publishing the empty snapshot first left it to be
  /// overwritten by whichever full snapshot the still-running loop had in
  /// flight — so the gauges went blank and then repopulated with pre-pause
  /// values at full opacity, and `isStale` could not tell because both
  /// timestamps came from the same source.
  Future<void> _pauseNow(PollingEngine engine) async {
    await engine.stop();
    // Everything on screen describes a moment that has passed. Publishing an
    // empty snapshot is what makes the gauges say so instead of holding their
    // last numbers at full opacity.
    //
    // Unless the app came back while the stop was draining — announcing a
    // pause over a session that is already live again is its own wrong
    // answer, and the resumed loop would have to overwrite it.
    //
    // The condition was inverted, which reversed both halves: the empty
    // snapshot was withheld on an ordinary pause (so returning to the app
    // showed pre-pause values at full brightness until the first new reading)
    // and published on the one occasion it should not have been.
    if (_foreground) return;
    if (!_telemetry.isClosed) _telemetry.add(const TelemetrySnapshot());
  }

  Future<void> _onAppResumed() {
    if (_foreground) return Future<void>.value();
    _client?.transcript.recordNote('App 回到前景');
    // First thing, and unconditionally. Timers that came due while the process
    // was frozen are delivered now, in expiry order, and the watchdog's is
    // among them; `_resumeNow` is queued behind the pause still unwinding and
    // is far too late to beat it.
    _client?.markAlive();
    if (!_pausedByLifecycle) {
      _openForegroundAfterResumeValidation();
      return Future<void>.value();
    }
    // Keep the safety/foreground gate closed until ATRV revalidates the link.
    // Opening it here while `_pauseNow` was still awaiting `engine.stop()`
    // left pre-pause stopped-speed readings authoritative for 2–10s, so
    // record/share/history could mint permits on stale authority. Clear the
    // retained snapshot immediately; `_pauseNow` will also emit empty when it
    // finishes because foreground is still closed.
    _awaitingResumeValidation = true;
    if (!_telemetry.isClosed) _telemetry.add(const TelemetrySnapshot());
    // Queued behind whatever pause is still unwinding.
    _lifecycleChain = _lifecycleChain.then((_) => _resumeNow());
    return _lifecycleChain;
  }

  Future<void> _resumeNow() async {
    final client = _client;
    final engine = _engine;
    if (client == null || engine == null) {
      _pausedByLifecycle = false;
      _openForegroundAfterResumeValidation();
      return;
    }

    // Time passed with nothing running to receive bytes. That is not the
    // adapter going quiet, but the watchdog compares against a wall clock and
    // cannot tell the difference — every resume would otherwise tear down a
    // healthy link.
    client.markAlive();

    // Prove the link before showing live numbers again. A user who plugged the
    // adapter into a different car, or drove out of Bluetooth range while the
    // app was backgrounded, should not see the old vehicle's values resume.
    final generation = _generation;
    try {
      final probe = await client.send(
        'ATRV',
        timeout: const Duration(seconds: 3),
      );
      if (_superseded(generation)) {
        _awaitingResumeValidation = false;
        return;
      }
      if (!probe.isSuccess) {
        _openForegroundAfterResumeValidation();
        _handleConnectionLost(generation);
        return;
      }
    } on Object {
      if (_superseded(generation)) {
        _awaitingResumeValidation = false;
        return;
      }
      _openForegroundAfterResumeValidation();
      _handleConnectionLost(generation);
      return;
    }

    if (_superseded(generation)) {
      _awaitingResumeValidation = false;
      return;
    }
    // Backgrounded again while the probe was in flight. Starting here would
    // poll the vehicle from the background — and because the flag used to be
    // cleared on entry rather than here, the next resume would see nothing to
    // recover and skip the link check altogether.
    if (!_awaitingResumeValidation) return;

    _openForegroundAfterResumeValidation();
    _pausedByLifecycle = false;
    engine.start();

    // Discovery is interrupted by a pause rather than answered by one, and
    // nothing else would ever ask again — `_connectInner` fires it once. An
    // incomplete capability map keeps batching shut, so leaving it incomplete
    // costs the session its throughput for no reason.
    if (!engine.supportDiscoveryComplete) {
      unawaited(engine.discoverSupportedPids());
      // The responder census, taken once against the vehicle actually attached.
      // A fault-code scan can tell who answered but not who should have, and a
      // controller that stays silent shows up in no count at all.
      // Bounded, because nothing else bounds it. Fired unawaited, this had no
      // deadline at all — and a scan starting a moment later joined it, so the
      // census the scan was blocked on could outlive the scan's own budget.
      unawaited(
        engine.discoverResponders(deadline: DateTime.now().add(censusBudget)),
      );
    }
  }

  /// Opens the foreground/safety gate only after resume validation completes
  /// (or when no lifecycle-paused engine needs an ATRV check).
  void _openForegroundAfterResumeValidation() {
    _awaitingResumeValidation = false;
    if (_foreground) return;
    _foreground = true;
    if (!_foregroundChanges.isClosed) _foregroundChanges.add(true);
  }

  Stream<TelemetrySnapshot> get telemetryStream => _telemetry.stream;

  PollingEngine? get engine => _engine;

  /// The live client, for the two things that talk to the adapter directly:
  /// the transcript export and the manual command box.
  Elm327Client? get client => _client;

  /// This attempt's record, created at the tap rather than at the handshake.
  ObdTranscript? _attemptTranscript;

  /// The last session's traffic, kept after the client is gone.
  ObdTranscript? _lastTranscript;
  String _lastTranscriptHeader = '';

  /// Facts frozen for the attempt whose bytes are in [_attemptTranscript].
  ///
  /// Kept beside the transcript rather than rebuilt at export: by then the
  /// user may have changed vehicle settings or selected another adapter, and a
  /// plausible header describing the wrong session is worse than no header.
  SessionEvidenceMetadata? _sessionEvidence;
  int? _sessionEvidenceGeneration;
  int _evidenceSequence = 0;

  /// The transcript worth exporting right now: the live one if there is a
  /// session, otherwise the last one that ended.
  ///
  /// Never null once anything has been attempted, which is the property that
  /// matters — a failed connection is exactly when somebody needs this and
  /// exactly when there is no client to hang it off.
  ObdTranscript? get exportableTranscript =>
      _client?.transcript ?? _attemptTranscript ?? _lastTranscript;

  /// The header for [exportableTranscript].
  String get exportableTranscriptHeader => exportableRecord?.header ?? '';

  /// The transcript and the header that describes it, read together.
  ///
  /// Two accessors could not be used safely: the export reads the transcript,
  /// awaits a temporary directory, and only then reads the header — and a
  /// connection begun in that gap gives it the *new* session's adapter,
  /// protocol and bus over the *old* session's bytes. A record whose heading
  /// describes a different car is worse than no record, because nothing in it
  /// looks wrong.
  ///
  /// Also fixes which header a live attempt gets. The old rule keyed on
  /// `_client`, so a failure before the client exists — a refused Wi-Fi
  /// socket, a Bluetooth cascade that timed out — exported this attempt's
  /// bytes under the *previous* session's heading. `transcriptHeader` renders
  /// from the attempt's own cached connection facts and is right with or
  /// without a client; only a fall back to `_lastTranscript` wants the stored
  /// one.
  ({ObdTranscript transcript, String header})? get exportableRecord {
    final current = _client?.transcript ?? _attemptTranscript;
    if (current != null && !current.isEmpty) {
      return (transcript: current, header: transcriptHeader);
    }
    final last = _lastTranscript;
    if (last != null && !last.isEmpty) {
      return (transcript: last, header: _lastTranscriptHeader);
    }
    return null;
  }

  /// Whether there is anything to export at all.
  bool get hasTranscript => exportableRecord != null;

  /// A one-line description of what produced a transcript.
  ///
  /// A record with no idea what made it is most of the way to useless — the
  /// first question anybody asks of a log is which adapter and which protocol.
  /// Connection facts kept outside `state`.
  ///
  /// The header is rendered during teardown, and teardown can run from
  /// `ref.onDispose`, where reading `state` throws "Cannot use Ref … inside
  /// life-cycles". Caching the three strings as they are set costs nothing and
  /// keeps the one render that matters — the one for a session that is ending
  /// — out of that trap.
  String _sessionKind = '';

  /// Which transport this recording came off, cached alongside the header's
  /// other facts.
  ///
  /// Read from the cache rather than from `state`, and that is not a
  /// preference: `_saveTranscriptSnapshot` runs from `dispose` and from the
  /// app-pause handler, and Riverpod asserts on reading a notifier's `state`
  /// inside a life-cycle callback. Doing it the obvious way took out fifty
  /// tests at once with an assertion nowhere near the cause.
  TransportKind? _sessionTransport;
  String _sessionDevice = '';
  String _sessionProtocol = '';

  static String _evidenceHeaderValue(
    String value, {
    required String whenEmpty,
  }) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? whenEmpty : escapeEvidenceText(trimmed);
  }

  String get transcriptHeader {
    final c = _client;
    final evidence = _sessionEvidence;
    final buffer = StringBuffer();
    if (evidence == null) {
      buffer
        ..writeln('# Telltale 傳輸紀錄')
        ..writeln(
          '# 連線方式：${_evidenceHeaderValue(_sessionKind, whenEmpty: '未連線')}',
        )
        ..writeln(
          '# 裝置：${_evidenceHeaderValue(_sessionDevice, whenEmpty: '—')}',
        );
    } else if (evidence.transportMetadataCompleted) {
      buffer.write(evidence.renderHeader());
    } else {
      buffer.write(
        evidence.renderHeader(
          latestTransportMetadata: c?.transport.diagnosticMetadata ?? const {},
        ),
      );
    }
    buffer.writeln(
      '# 協定：${_evidenceHeaderValue(_sessionProtocol, whenEmpty: 'unknown')}',
    );
    if (c != null) {
      buffer
        ..writeln(
          '# 轉接器回報：${_evidenceHeaderValue(c.deviceVersion, whenEmpty: '—')}',
        )
        ..writeln(
          '# ATDPN：${_evidenceHeaderValue(c.protocolNumber, whenEmpty: '—')}',
        )
        ..writeln(
          '# 匯流排：${c.addressing.family.name}，'
          '標頭 ${c.addressing.headerHexDigits} 位，'
          '接收寬度 ${c.addressing.acceptedReceiveWidths.join('/')}',
        );
      // Whether the adapter's account of itself holds together.
      //
      // In the log rather than on a gauge, deliberately. `v1.5` is printed on
      // a very large share of the adapters people actually buy and most of
      // them work — so this is a fact about the device for whoever reads the
      // transcript afterwards, not a verdict to put in front of a driver. It
      // also cannot say anything about whether the *readings* are true, and a
      // note that looked like it could would be worse than none.
      final identity = c.adapterIdentity;
      buffer.writeln('# 轉接器自述：${escapeEvidenceText(identity.summaryLine)}');
      for (final concern in identity.concerns) {
        buffer.writeln('#   ⚠ ${escapeEvidenceText(concern.exportSummary)}');
      }
    }
    return buffer.toString();
  }

  /// Sends one command exactly as typed.
  ///
  /// Goes through the ordinary command chain rather than around it. A manual
  /// command that bypassed the chain would interleave with the polling loop's
  /// traffic and produce replies neither side could attribute — which is the
  /// failure this whole codebase is organised against, arriving through the
  /// one screen meant for diagnosing it.
  Future<String> sendManualCommand(String command) async {
    final c = _client;
    if (c == null) {
      // The one refusal here that IS a transport fact, and the identifier for
      // it already existed. The half of its doc this line can stand behind is
      // "provably unsent": nothing has been handed to a transport, so the
      // adapter owes nothing. Its other half, "no link is open", is what a
      // reader would reach for and is not quite the same claim — `_client` is
      // assigned before `connect()` returns, so there is a window in which a
      // socket exists and this field is still null. Nothing acts on that
      // difference; the sentence a reader is shown is about the command.
      throw const TransportException(
        '尚未連線',
        issue: TransportIssue.notConnected,
      );
    }
    final trimmed = command.trim();
    // Not a second rule. `manualCommandRefusal('')` answers this, and the two
    // answering differently is how a box came to have one sentence for empty
    // input and a different one for whitespace.
    final refusal = manualCommandRefusal(trimmed);
    if (refusal != null) throw ManualCommandRefusedException(refusal);
    c.transcript.recordNote('手動送出：$trimmed');
    final response = await c.send(trimmed);
    return response.rawLines.join('\n');
  }

  /// Adds a passenger-entered physical event and persists it immediately.
  Future<FieldEventRecordResult> recordFieldEvent(
    FieldEventMarker marker,
  ) async {
    final client = _client;
    if (!state.isConnected ||
        client == null ||
        _sessionTransport == TransportKind.demo ||
        _currentSessionIsTestRig) {
      return FieldEventRecordResult.unavailable;
    }
    client.transcript.recordPinnedNote('實車事件：${marker.label}');
    final persisted = await _saveTranscriptSnapshot();
    return persisted
        ? FieldEventRecordResult.persisted
        : FieldEventRecordResult.memoryOnly;
  }

  /// Starts the built-in simulator. Needs no permissions and no hardware, so
  /// it is also what the app falls back to when the user just wants to look
  /// around.
  Future<bool> connectDemo() => _connect(DemoTransport(), TransportKind.demo);

  /// Connects an arbitrary transport. Tests only.
  ///
  /// The seam exists because two whole classes of defect live *above* the
  /// engine and had no way to be reached: the scan's cross-check against the
  /// vehicle's own PID 01 summary, and the ordering between the census and the
  /// first category read. Both are notifier behaviour, and every notifier test
  /// had to go through `connectDemo`, whose simulator derives its PID 01 count
  /// from its own Mode 03 list and therefore cannot disagree with itself.
  ///
  /// Reviewers named that gap in two consecutive rounds. A seam this thin is a
  /// smaller price than a rule nothing can test.
  @visibleForTesting
  Future<bool> connectForTest(ObdTransport transport, TransportKind kind) =>
      _connect(transport, kind);

  Future<bool> connectWifi({String? host, int? port}) => _connect(
    WifiTransport(
      host: host ?? WifiTransport.defaultHost,
      port: port ?? WifiTransport.defaultPort,
      // Only Android reroutes sockets away from an internet-less Wi-Fi, so
      // only Android gets a binder. dart:io Platform, not
      // defaultTargetPlatform: the flutter_test harness pretends every host
      // is Android, and a host-run test must not acquire a phantom lease.
      routeBinder: Platform.isAndroid ? AndroidWifiRouteBinder() : null,
    ),
    TransportKind.wifi,
  );

  Future<bool> connectClassic(DiscoveredDevice device) {
    // Windows/Linux Classic is SPP serial (COM / rfcomm) — not the Android /
    // macOS RFCOMM path. Using ClassicTransport here would call
    // connect(channel:) / paired MAC APIs that are wrong for COMx /
    // /dev/rfcomm* identifiers and can mislead as "supported".
    if (sppSerialHostSupported) {
      return _connect(
        SerialTransport(portName: device.id, displayLabel: device.name),
        TransportKind.bluetoothClassic,
      );
    }
    // Self-referencing, so the callback can ask whether the transport it
    // belongs to is still the one being connected.
    //
    // The generation number cannot answer that here: this runs *before*
    // `_connect` bumps it, so a closure over `generation` reads the getter and
    // compares the field with itself — always false, a guard that compiles and
    // checks nothing. Identity is the fact actually available at this point.
    late final ClassicTransport transport;
    transport = ClassicTransport(
      address: device.id,
      name: device.name,
      // Published so the screen can say what the wait is for. Three tiers
      // of up to twelve seconds each is a long time to show nothing.
      onAttempt: (tier) {
        // A cascade the user abandoned goes on announcing its tiers until the
        // tier in flight ends. Both destinations belong to whoever is current:
        // the wizard showed 未加密 SPP 連線 for a device nobody was connecting
        // to any more, and the note landed in the *next* attempt's transcript,
        // which is the one record that has to be trustworthy afterwards.
        if (!identical(_inFlightTransport, transport)) return;
        _attemptTranscript?.recordNote(tier);
        if (state.isBusy) state = state.copyWith(detail: tier);
      },
    );
    return _connect(transport, TransportKind.bluetoothClassic);
  }

  Future<bool> connectBle(BleAdapterHandle device) =>
      _connect(BleTransport(device), TransportKind.bluetoothLe);

  /// Guards against overlapping connect attempts.
  ///
  /// Set synchronously, before the first `await`. Two quick taps on a device
  /// row would otherwise both reach `_teardown()`, and the second would dispose
  /// the client the first is still handshaking through, leaving `_client` and
  /// `_engine` pointing at different sessions.
  bool _connecting = false;

  /// The attempt currently unwinding or in flight, so a later tap can wait for
  /// it rather than be refused by it.
  Future<bool>? _inFlight;

  /// The transport that attempt is using, for callbacks that have to ask
  /// whether they still speak for the current connection.
  ObdTransport? _inFlightTransport;

  /// How long an abandoned attempt is given to unwind before the new one gives
  /// up on waiting for it.
  ///
  /// Sized from the transports' own ceilings rather than picked: a Bluetooth
  /// Classic tier is capped at 12 seconds, a Wi-Fi socket at 8, and a BLE
  /// connect at 15 — and the BLE one is cut short in practice because
  /// `device.disconnect()` aborts an in-flight connect. Twenty leaves margin
  /// over the slowest of those without being a wait anybody would sit through
  /// twice.
  /// Overridable so a test can put a slow teardown *inside* the budget.
  ///
  /// The number itself was pinned by nothing: the cancellation tests unwind in
  /// milliseconds, so moving the stopwatch back below `_teardown()` — which is
  /// the bug this budget was introduced to fix — left the suite green.
  @visibleForTesting
  static Duration abandonTimeout = const Duration(seconds: 20);

  /// Incremented by every connect, disconnect and link loss.
  ///
  /// The `_connecting` flag only stops two connects overlapping. It does
  /// nothing about a link dropping, or the user tapping disconnect, *while* a
  /// handshake is still running: `_teardown()` would dispose the client and the
  /// older path would carry on, install an engine and publish `connected`,
  /// leaving a session whose client no longer exists. Async work therefore
  /// captures the generation and re-checks it after every await before
  /// installing anything.
  int _generation = 0;

  /// Identifies the current connection.
  ///
  /// Public because a multi-step operation that outlives a single await — a
  /// fault-code scan reads three classes and then a VIN — has to be able to
  /// tell that the car it started on is still the car it is talking to.
  int get generation => _generation;

  /// Synchronous broadcast used by recorders to close acceptance before any
  /// disconnect/replacement teardown can yield to the event loop.
  Stream<ObdSessionBoundary> get sessionBoundaries => _sessionBoundaries.stream;

  void _publishSessionBoundary(ObdSessionBoundaryReason reason) {
    _engine?.interruptCapabilityDiscovery();
    if (_sessionBoundaries.isClosed) return;
    _sessionBoundaries.add(
      ObdSessionBoundary(
        generation: _generation,
        observedAtUtc: DateTime.now().toUtc(),
        reason: reason,
      ),
    );
  }

  /// How many times a *new connection* has been started.
  ///
  /// [generation] answers "is the work I started still the current work", and
  /// is bumped by anything that invalidates in-flight work — including losing
  /// the link. That makes it the wrong token for "is the screen still about
  /// the same vehicle", and using it for that suppressed the one message a
  /// dropped clear exists to show: the drop *is* a generation change, so the
  /// clear's own continuation refused to publish 清除指令送出後連線中斷 and the
  /// user was left with a blank panel and a live button over a controller that
  /// may already have erased its memory.
  ///
  /// This counter moves only when somebody starts connecting to something. A
  /// clear whose link died still describes the car it was sent to; a clear
  /// that finishes after the user has connected to a different one does not.
  int get connectEpoch => _connectEpoch;
  int _connectEpoch = 0;

  Future<bool> _connect(ObdTransport transport, TransportKind kind) async {
    // A tap that arrives while another attempt is running used to be dropped
    // on the floor: `return false`, no state change, no message.
    //
    // That is the wizard's worst failure, because of who hits it. The bonded
    // device list is the phone's, so it holds headphones, a car stereo and a
    // laptop beside the adapter, and tapping the wrong row is the ordinary
    // mistake. 取消 invalidated the attempt but could not stop it — so for up
    // to three twelve-second tiers afterwards the *correct* adapter did
    // nothing when tapped, silently, on the app's first screen. The reasonable
    // reading is that the app is broken, and the reasonable response is to
    // force-quit it.
    //
    // Clearing `_connecting` here instead — which is the obvious fix — is
    // worse than the bug. Two native connects would then race for one adapter,
    // and an ELM327 accepts exactly one link: the loser wedges the winner. So
    // the attempts stay serialised, and what changes is that the new one
    // *cancels and waits for* its predecessor instead of being refused by it.
    if (_connecting) {
      // Synchronously, before any await: from this instant every older attempt
      // is superseded and can publish nothing, whatever it goes on to
      // discover. Kept, because it is also this caller's claim on being the
      // one the user is waiting for.
      _connectEpoch++;
      _publishSessionBoundary(ObdSessionBoundaryReason.sessionReplacement);
      final mine = ++_generation;
      // Said out loud, because the wait is the part that looks broken.
      //
      // 取消 returns the screen to idle, so a tap during the abandoned tier's
      // remaining seconds produced nothing at all on screen until it ended —
      // the same silence the cancel was supposed to end, moved a few seconds
      // later. Naming the device makes it clear the tap registered and which
      // one it was for.
      state = ObdConnectionState(
        phase: ConnectionPhase.connecting,
        kind: kind,
        deviceName: transport.displayName,
        detail: 'Stopping the previous connection, one moment…',
        activity: ObdConnectionActivity.abortingPreviousConnection,
      );
      // Reaches the transport. `_teardown` disposes the client, and
      // `Elm327Client.dispose()` disconnects its transport — which is where a
      // Bluetooth Classic cascade learns to stop at the end of the tier it is
      // in rather than walking the remaining two.
      // One budget for the whole handover, not one per await.
      //
      // The bound used to start *after* the teardown, and a teardown has no
      // deadline of its own: it awaits stream cancellations, `engine.dispose`,
      // and a transport disconnect that on Bluetooth Classic reaches the
      // platform. So the twenty seconds this promises could be preceded by an
      // unbounded wait, and the number in the refusal was not the number the
      // user experienced.
      final clock = Stopwatch()..start();
      Duration remaining() {
        final left = abandonTimeout - clock.elapsed;
        return left.isNegative ? Duration.zero : left;
      }

      try {
        await _teardown().timeout(remaining());
      } on Object {
        // Not waiting for it any longer is the whole point; whether it
        // finished is answered by `_connecting` below.
      }
      // Waited for in a loop, and the loop is the point.
      //
      // Three taps in quick succession — A wrong, B wrong, C the adapter —
      // used to connect **B**. A single wait meant B and C both queued behind
      // A; A finished, B woke first and took the link, and C woke to find
      // somebody connecting and was refused. The user's last tap lost to the
      // one they had already changed their mind about, and the app ended up
      // talking to a device they had rejected.
      //
      // So each caller records its claim, and a caller that finds a newer
      // claim stands down: whoever tapped last is the one being waited for.
      // Standing down publishes nothing, which is right here and only here —
      // the newer tap is already showing its own progress on the same screen.
      while (true) {
        if (_generation != mine) return false;
        if (!_connecting) break;
        final inFlight = _inFlight;
        if (inFlight == null) break;
        try {
          await inFlight.timeout(remaining());
        } on Object {
          // Whether it unwound cleanly is not this attempt's business; the
          // only question is whether the link is free, and that is what the
          // checks below answer.
          break;
        }
      }
      if (_generation != mine) return false;
      // Bounded waits end whether or not the thing they waited for did. A
      // silent `false` here would be the same defect one level down, so
      // the refusal says what happened and what to do about it.
      if (_connecting) {
        state = state.copyWith(
          phase: ConnectionPhase.failed,
          error:
              'The previous connection is still being stopped and the adapter '
              'has not been released yet. Wait a few seconds and try again.',
          issue: ObdConnectionIssue.previousConnectionStillAborting,
        );
        return false;
      }
    }
    if (_connecting) return false;
    _connecting = true;
    _inFlightTransport = transport;
    _connectEpoch++;
    _publishSessionBoundary(ObdSessionBoundaryReason.sessionReplacement);
    final attempt = _connectInner(transport, kind, ++_generation);
    _inFlight = attempt;
    try {
      return await attempt;
    } finally {
      _connecting = false;
      // Only if nothing has replaced it, so a successor's handle is not
      // cleared by its predecessor finishing late.
      if (identical(_inFlight, attempt)) _inFlight = null;
      if (identical(_inFlightTransport, transport)) _inFlightTransport = null;
    }
  }

  /// True when this attempt has been superseded and must publish nothing.
  bool _superseded(int generation) => generation != _generation;

  /// Ends a failed attempt, publishing only if it is still the current one.
  ///
  /// The three failure paths all wrote `failed` unconditionally, and the state
  /// they overwrote was whatever had replaced them. Concretely: the user taps
  /// 取消 on a Wi-Fi attempt, the screen returns to idle, and eight seconds
  /// later the abandoned socket's own timeout repaints it as
  /// 連線失敗 — an error about a connection the user had already walked away
  /// from, on a screen they had moved on from. Nothing distinguishes it from a
  /// failure of whatever they did next.
  ///
  /// The record is written either way. A cancelled attempt is exactly the kind
  /// somebody wants to look at afterwards, and the transcript belongs to the
  /// attempt rather than to the screen.
  Future<bool> _failAttempt(
    int generation,
    Elm327Client client,
    String why, {
    String prefix = 'Connection failed',
    String? detail,
    ObdConnectionIssue? issue,
    InitProgress? issueStep,
    TransportIssue? transportIssue,
  }) async {
    _completeEvidence(client, outcome: 'failed');
    // Before the teardown reads it. The sentence on screen is what the user
    // gets; this is what somebody can act on afterwards.
    _attemptTranscript?.recordNote('$prefix: ${detail ?? why}');
    if (_superseded(generation)) {
      // This attempt's own client, not the shared teardown: whoever superseded
      // it has already torn down and published, and `_teardown()` here would
      // reach into a session that is no longer this one's to end.
      await client.dispose();
      return false;
    }
    state = state.copyWith(
      phase: ConnectionPhase.failed,
      error: why,
      issue: issue,
      issueStep: issueStep,
      transportIssue: transportIssue,
    );
    await _teardown();
    return false;
  }

  Future<bool> _connectInner(
    ObdTransport transport,
    TransportKind kind,
    int generation,
  ) async {
    await _teardown();
    if (_superseded(generation)) {
      await transport.disconnect();
      return false;
    }

    // A remembered adapter is not a vehicle identity. Every new connection
    // could be a different car, so profile-derived figures remain closed until
    // the driver confirms the assumptions for this exact session.
    await ref
        .read(vehicleProfileProvider.notifier)
        .invalidateForVehicleBoundary();
    ref
        .read(powertrainProfileAuthorizationsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref
        .read(powertrainExperimentalProbeConsentsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref.read(vehicleIdentityProvider.notifier).reset();
    if (_superseded(generation)) {
      await transport.disconnect();
      return false;
    }

    _sessionKind = kind.label;
    _sessionTransport = kind;
    _sessionDevice = transport.displayName;
    _sessionProtocol = '';
    final startedAt = DateTime.now().toUtc();
    _sessionEvidence = SessionEvidenceMetadata(
      sessionId: _nextEvidenceSessionId(startedAt),
      startedAt: startedAt,
      platform: platformMetadata,
      vehicleProfile: ref.read(vehicleProfileProvider),
      transportKind: kind.label,
      deviceName: transport.displayName,
      // Demo never crosses a physical adapter or ECU. Freeze that provenance
      // into the evidence itself so its export cannot carry a field header,
      // even when it runs inside the exact production Android package.
      testRig: testRigBuild || kind == TransportKind.demo,
      initialTransportMetadata: transport.diagnosticMetadata,
    );
    _sessionEvidenceGeneration = generation;
    _attemptTranscript = ObdTranscript()
      ..recordNote(
        'Starting connection: ${transport.displayName} (${kind.label})',
      );
    state = ObdConnectionState(
      phase: ConnectionPhase.connecting,
      kind: kind,
      deviceName: transport.displayName,
    );

    // The transcript is the *attempt's*, not the client's.
    //
    // A Wi-Fi socket that is refused and a Bluetooth cascade that times out
    // both fail before a single OBD byte exists, and the export was therefore
    // empty for exactly the failures a person most needs explained. Starting
    // the record at the tap means even those attempts come back with
    // something: which transport, which address, which tier, and how long each
    // one waited.
    final elapsedCache = NativeElapsedCache(
      readMs: Platform.isAndroid
          ? ElapsedRealtimePlatform.elapsedRealtimeMs
          : null,
    );
    await elapsedCache.sync();
    final client = Elm327Client(
      transport,
      transcript: _attemptTranscript!,
      elapsed: () => elapsedCache.elapsed,
      agingElapsed: () => elapsedCache.agingElapsed,
    );
    _client = client;

    final steps = <InitProgress>[];
    _initSub = client.initProgress.listen((progress) {
      // Replace the in-flight entry for a step rather than appending, so the
      // wizard shows one row per command that mutates from running → ok.
      final existing = steps.indexWhere((s) => s.index == progress.index);
      if (existing >= 0) {
        steps[existing] = progress;
      } else {
        steps.add(progress);
      }
      // Only advance the phase while the handshake is genuinely in flight.
      // These events are delivered asynchronously off a broadcast stream, so
      // the last few land *after* `connect()` has returned and the phase has
      // moved to connected — writing `handshaking` unconditionally would clobber
      // it, leaving the session live but permanently reporting itself offline.
      final stillHandshaking =
          state.phase == ConnectionPhase.connecting ||
          state.phase == ConnectionPhase.handshaking;
      state = state.copyWith(
        phase: stillHandshaking ? ConnectionPhase.handshaking : null,
        initSteps: List.unmodifiable(steps),
      );
    });

    // Bound to the generation that built this client, so a transport dying
    // after the user has moved on cannot speak for whatever session is current
    // by then.
    client.onConnectionLost = () => _handleConnectionLost(generation);

    try {
      final ok = await client.connect();
      if (_superseded(generation)) {
        // Disconnected or dropped while the handshake ran. Tear down what this
        // attempt built and publish nothing — the state now on screen belongs
        // to whatever superseded it.
        await client.dispose();
        return false;
      }
      if (!ok) {
        final failure = _describeHandshakeFailure(steps);
        return await _failAttempt(
          generation,
          client,
          failure.message,
          prefix: 'Handshake failed',
          issue: failure.issue,
          issueStep: failure.step,
        );
      }
    } on TransportException catch (e) {
      // The sentence still goes to the transcript; the identifier is what the
      // screen renders, so a Wi-Fi route refusal stops being told to connect to
      // a hotspot it is already on. Nested cause/detail (native platform
      // prose) is transcript-only — interpolating it into [e.message] would
      // put it back on the screen.
      return _failAttempt(
        generation,
        client,
        e.message,
        detail: e.cause == null ? e.message : '${e.message} (${e.cause})',
        transportIssue: e.issue,
      );
    } on Object catch (e) {
      // The sentence and the evidence go to different readers: the driver gets
      // something to act on, the transcript keeps the exception verbatim.
      return _failAttempt(
        generation,
        client,
        describeConnectException(e),
        detail: '$e',
        issue: connectExceptionIssue(e),
      );
    }

    if (_superseded(generation)) {
      await client.dispose();
      return false;
    }

    _completeEvidence(client, outcome: 'connected');

    final engine = PollingEngine(client, elapsedClock: elapsedCache);
    engine.shouldContinue = () => _foreground && !_superseded(generation);
    // The same question, asked where the bytes actually leave. `shouldContinue`
    // guards the loop's decisions; this guards the wire, which is the only
    // place that sees a queued Mode 04 arriving after the screen has gone.
    // `owner` is an operation's lease; see `Elm327Client.mayTransmit`. The
    // foreground flag alone answers "right now", and a resume makes it true
    // again for work the user abandoned before backgrounding — including a
    // Mode 04 clear, which erases fault memory and cannot be taken back. The
    // pause epoch only ever advances, so a lease taken before the pause can
    // never match after it.
    client.mayTransmit = (owner) {
      if (_superseded(generation)) return false;
      // Resume ATRV must run while the safety/foreground gate is still closed.
      // Only the unleased probe may talk in that window — leased Mode 04 and
      // similar work stay refused until validation opens the gate.
      if (_awaitingResumeValidation) return owner == null;
      if (!_foreground) return false;
      return switch (owner) {
        null => true,
        int epoch => epoch == _pauseEpoch,
        _PowertrainProbeWireOwner lease =>
          lease.pauseEpoch == _pauseEpoch &&
              lease.connectionGeneration == generation &&
              lease.experimentalAccessEpoch == _experimentalAccessEpoch &&
              ref.read(powertrainBatteryExperimentalAccessProvider),
        _ => false,
      };
    };
    // And what the *operation* owns, which is a different question. The gate
    // above is a sample of now; this lets a long operation notice that the
    // interruption it slept through happened at all.
    engine.lifecycleEpoch = () => _pauseEpoch;
    _engine = engine;
    _snapshotSub = engine.snapshots.listen((snapshot) {
      if (!_telemetry.isClosed) _telemetry.add(snapshot);
    });

    syncActivePids(ref.read(activePidsProvider));
    // A protocol search can take 25 seconds, and the user may well have put
    // the phone down during it. Starting to poll from the background is both
    // rude and unsafe — an OS freeze mid-command splits a request from its
    // reply — so the session is left parked for the next resume to recover.
    if (_foreground) {
      engine.start();
    } else {
      _pausedByLifecycle = true;
      if (!_telemetry.isClosed) _telemetry.add(const TelemetrySnapshot());
    }

    // Support discovery runs in the background: it is useful for greying out
    // PIDs the car does not have, but nothing should wait on it.
    unawaited(engine.discoverSupportedPids());
    // Who is on this bus, asked once against the vehicle actually attached.
    // A fault-code scan establishes who answered and never who should have,
    // so a controller that stays silent appears in no count and the engine's
    // clean reply stands for the whole car.
    // Bounded, because nothing else bounds it. Fired unawaited, this had no
    // deadline at all — and a scan starting a moment later joined it, so the
    // census the scan was blocked on could outlive the scan's own budget.
    unawaited(
      engine.discoverResponders(deadline: DateTime.now().add(censusBudget)),
    );

    _sessionProtocol = client.protocolDescription.isEmpty
        ? client.protocolNumber
        : client.protocolDescription;
    state = state.copyWith(
      phase: ConnectionPhase.connected,
      deviceName: transport.displayName,
      protocol: _sessionProtocol,
      batteryVoltage: client.batteryVoltage,
      clearError: true,
    );
    _startPeriodicSnapshots();
    return true;
  }

  String _nextEvidenceSessionId(DateTime startedAt) {
    _evidenceSequence++;
    final utc = startedAt.toUtc().toIso8601String().replaceAll(
      RegExp(r'[-:.]'),
      '',
    );
    return '$utc-${_evidenceSequence.toRadixString(36)}';
  }

  void _completeEvidence(Elm327Client client, {required String outcome}) {
    final evidence = _sessionEvidence;
    if (evidence == null || evidence.transportMetadataCompleted) return;
    _sessionEvidence = evidence.completeTransportMetadata({
      ...client.transport.diagnosticMetadata,
      'connectionOutcome': outcome,
    });
  }

  /// Turns a failed handshake into something the driver can act on.
  ///
  /// "Initialisation failed" tells nobody anything. Which command died, and
  /// whether it died on the very first one, separates "this is not an ELM327"
  /// from "the adapter is fine but the ignition is off".
  static ({String message, ObdConnectionIssue issue, InitProgress? step})
  _describeHandshakeFailure(List<InitProgress> steps) {
    final failed = steps.where((s) => s.status == InitStatus.failed).toList();
    if (failed.isEmpty) {
      return (
        message:
            'Initialisation did not pass. The adapter may not be compatible.',
        issue: ObdConnectionIssue.handshakeIncomplete,
        step: null,
      );
    }

    final first = failed.first;
    // Silence on ATZ is a different diagnosis from an unexpected exception
    // on ATZ. The latter already has a note the screen can say; calling it
    // "the adapter did not answer reset" tells the driver the device is not
    // an ELM327, which is the one thing this path has not established.
    if (first.index == 0 && first.note != InitNote.unexpected) {
      return (
        message:
            'The adapter did not answer the reset command '
            '(${first.step.command}). This device may not be an ELM327 '
            'adapter, or the connection may have gone to the wrong device.',
        issue: ObdConnectionIssue.adapterSilentOnReset,
        step: first,
      );
    }
    // `first.detail` is never null for a classified failure — `InitProgress`
    // derives it from the note or the adapter's error code — so 無回應 stands
    // only for a step that failed with nothing to say about why.
    return (
      message:
          'Initialisation failed at ${first.step.command} '
          '(${first.detail ?? 'no response'}). Check that the adapter is '
          'seated properly and the vehicle\'s ignition is on.',
      issue: ObdConnectionIssue.handshakeStepFailed,
      step: first,
    );
  }

  /// Reports the link lost — unless the session it was about is already gone.
  ///
  /// [generation] is the session this conclusion belongs to. The success paths
  /// all check `_superseded` and this one did not, which cost two things. A
  /// user who tapped 中斷連線 during the resume probe watched the probe fail
  /// against its own disposed client and got 轉接器停止回應，連線已中斷 over a
  /// disconnect they had asked for. Worse, the bare `_generation++` invalidated
  /// whatever session was current *by then*: disconnect, immediately connect to
  /// another adapter, and the previous session's dying probe bumped the counter
  /// so the new attempt's next ownership check aborted it and disposed a client
  /// it had just built. The reconnect failed silently because a corpse lost a
  /// race.
  void _handleConnectionLost(int generation) {
    if (_superseded(generation)) return;
    _client?.transcript.recordNote('Connection event: adapter link dropped');
    _publishSessionBoundary(ObdSessionBoundaryReason.linkLoss);
    _generation++;
    unawaited(
      ref.read(vehicleProfileProvider.notifier).invalidateForVehicleBoundary(),
    );
    ref
        .read(powertrainProfileAuthorizationsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref
        .read(powertrainExperimentalProbeConsentsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref.read(vehicleIdentityProvider.notifier).reset();
    state = state.copyWith(
      phase: ConnectionPhase.failed,
      error:
          'The adapter stopped responding and the connection has been dropped.',
      issue: ObdConnectionIssue.adapterStoppedResponding,
    );
    unawaited(_teardown());
  }

  /// Pushes a changed PID selection into the running loop.
  ///
  /// The engine receives the authorized profile PID ids alongside the
  /// filtered set: filtering alone tells it nothing about *why* a profile PID
  /// is present, and its sink guard must be able to distinguish a
  /// session-authorized definition from forged queued work.
  void syncActivePids(List<Pid> pids) {
    final filtered = filterAuthorizedPowertrainPids(
      pids,
      ref.read(powertrainProfileAuthorizationsProvider),
      connectionGeneration: _generation,
    );
    _engine?.setActivePids(
      filtered,
      includeProfileDerivedInputs: true,
      authorizedProfilePidIds: {
        for (final pid in filtered)
          if (pid.ownerProfileId != null) pid.id,
      },
    );
  }

  /// Performs one consent-bound experimental read outside the polling queue.
  ///
  /// The lease is consumed before any bytes are sent. There is no automatic
  /// retry, no persisted PID, and no result is published after a lifecycle or
  /// connection boundary.
  Future<PowertrainBatteryProbeResult> probePowertrainBatteryCommand({
    required PowertrainBatteryCatalogSnapshot snapshot,
    required String profileId,
    required String commandKey,
    required int vehicleYear,
  }) async {
    final client = _client;
    if (client == null || !state.isConnected || !_foreground) {
      throw const PowertrainProbeRefusedException(
        PowertrainProbeRefusal.notConnectedOrNotInForeground,
      );
    }
    final generation = _generation;
    final pauseEpoch = _pauseEpoch;
    final experimentalAccessEpoch = _experimentalAccessEpoch;
    final wireOwner = _PowertrainProbeWireOwner(
      pauseEpoch: pauseEpoch,
      connectionGeneration: generation,
      experimentalAccessEpoch: experimentalAccessEpoch,
    );
    final consents = ref.read(
      powertrainExperimentalProbeConsentsProvider.notifier,
    );
    final lease = consents.take(
      snapshot: snapshot,
      profileId: profileId,
      commandKey: commandKey,
      vehicleYear: vehicleYear,
      connectionGeneration: generation,
    );
    if (lease == null) {
      throw const PowertrainProbeRefusedException(
        PowertrainProbeRefusal.noLiveAuthorization,
      );
    }

    PowertrainBatteryProbeResult? result;
    try {
      result = await PowertrainBatteryProbe.run(
        client: client,
        snapshot: snapshot,
        profileId: profileId,
        commandKey: commandKey,
        lifecycleOwner: wireOwner,
        deadline: lease.consent.expiresAt,
      );
      if (_generation != generation ||
          _pauseEpoch != pauseEpoch ||
          _experimentalAccessEpoch != experimentalAccessEpoch ||
          !_foreground ||
          !ref.read(powertrainBatteryExperimentalAccessProvider) ||
          !identical(_client, client)) {
        throw const PowertrainProbeRefusedException(
          PowertrainProbeRefusal.discardedAtLifecycleBoundary,
        );
      }
      return result;
    } finally {
      final failure = result?.failure;
      consents.complete(
        lease,
        quarantineProfile: failure?.requiresConnectionQuarantine ?? false,
      );
    }
  }

  /// Throws when the link is gone rather than answering with an empty list.
  ///
  /// Returning `[]` for "not executed" is how a mid-scan disconnect became a
  /// green no-faults result: the screen cannot tell an unanswered question
  /// from a clean answer once both are the same value.
  /// Makes sure the responder census has been attempted before a scan.
  ///
  /// Fired unawaited at connect for speed; this is how a caller that actually
  /// depends on it waits.
  Future<void> ensureResponderCensus({DateTime? deadline}) async {
    final engine = _engine;
    if (engine == null || engine.responders != null) return;
    await engine.discoverResponders(deadline: deadline);
  }

  Future<List<Dtc>> readDtcs(DtcKind kind, {DateTime? deadline}) async {
    final engine = _engine;
    if (engine == null) {
      throw const DtcReadException(
        'The connection is down',
        kind: DtcReadFailure.disconnected,
      );
    }
    return engine.readDtcs(kind, deadline: deadline);
  }

  Future<ClearOutcome> clearDtcs() async {
    final engine = _engine;
    if (engine == null) {
      throw const DtcReadException(
        'The connection is down',
        kind: DtcReadFailure.disconnected,
      );
    }
    // One clear at a time, decided here rather than by whoever is on screen.
    //
    // The screen's own guard lived in widget state, so switching tabs while a
    // clear was in flight rebuilt it cleared: tap 清除, glance at the
    // dashboard, come back, tap again, and a second functional `04` queued
    // behind the first. The second one reaches the controller the first just
    // finished and resets its readiness monitors again.
    //
    // A UI guard is still worth having — it is what greys the button — but it
    // cannot be the only one, because it is the one that does not survive the
    // screen.
    if (_clearInFlight) {
      throw const DtcReadException(
        'A clear is already in progress. Wait for it to finish.',
        kind: DtcReadFailure.error,
      );
    }
    _clearInFlight = true;
    try {
      return await engine.clearDtcs();
    } finally {
      _clearInFlight = false;
    }
  }

  /// Whether a Mode 04 is on the wire right now. See [clearDtcs].
  bool _clearInFlight = false;

  Future<String?> readVin({DateTime? deadline}) async {
    final engine = _engine;
    if (engine == null) {
      throw const DtcReadException(
        'The connection is down',
        kind: DtcReadFailure.disconnected,
      );
    }
    return engine.readVin(deadline: deadline);
  }

  /// Reads the current vehicle's self-reported VIN into session-only identity
  /// state without turning an optional identity read into a connection failure.
  ///
  /// This identity state is never persisted across a connection boundary. The
  /// raw ELM327 exchange can still remain in the diagnostic transcript under
  /// the existing privacy contract. Two controllers reporting different
  /// complete VINs is represented as a conflict and neither candidate is kept
  /// as identity state.
  Future<VehicleIdentity> refreshVehicleIdentity({DateTime? deadline}) async {
    final identity = ref.read(vehicleIdentityProvider.notifier);
    final engine = _engine;
    final generation = _generation;
    if (engine == null) {
      identity.markUnavailable();
      return ref.read(vehicleIdentityProvider);
    }

    bool stillOwnsSession() =>
        !_superseded(generation) && identical(_engine, engine);

    try {
      final vin = await engine.readVin(deadline: deadline);
      if (stillOwnsSession()) identity.reportVin(vin);
    } on VinIdentityConflictException {
      if (stillOwnsSession()) identity.reportConflict();
    } on DtcReadException {
      // Identity is useful context, not a prerequisite for raw OBD telemetry.
      // An unsupported Mode 09 response must not make this helper claim an
      // identity or throw through the settings screen. The ownership check is
      // equally important on failure: a retired request commonly completes
      // only after disconnect has disposed its client.
      if (stillOwnsSession()) identity.markUnavailable();
    } on TimeoutException {
      if (stillOwnsSession()) identity.markUnavailable();
    } on TransportException {
      if (stillOwnsSession()) identity.markUnavailable();
    }
    return ref.read(vehicleIdentityProvider);
  }

  /// The vehicle's own fault-lamp summary, or null if it could not be read.
  Future<MilStatus?> readMilStatus({DateTime? deadline}) async =>
      _engine?.readMilStatus(deadline: deadline);

  /// Throws when there is no session to ask with, for the reason [readDtcs]
  /// gives: an empty list for "not executed" is how a mid-scan disconnect
  /// becomes an affirmative statement about the vehicle.
  Future<FreezeFrameRead> readFreezeFrames({DateTime? deadline}) async {
    final engine = _engine;
    if (engine == null) {
      throw const DtcReadException(
        'The connection dropped before freeze frames were read, so none were retrieved.',
        kind: DtcReadFailure.disconnected,
      );
    }
    return engine.readFreezeFrames(deadline: deadline);
  }

  Future<void> disconnect() async {
    // Invalidates any handshake still in flight, so a connect the user has
    // just abandoned cannot finish and publish itself as live.
    _client?.transcript.recordNote('Connection event: the user disconnected');
    _publishSessionBoundary(ObdSessionBoundaryReason.userDisconnect);
    _generation++;
    await _teardown();
    await ref
        .read(vehicleProfileProvider.notifier)
        .invalidateForVehicleBoundary();
    ref
        .read(powertrainProfileAuthorizationsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref
        .read(powertrainExperimentalProbeConsentsProvider.notifier)
        .invalidateForVehicleBoundary();
    ref.read(vehicleIdentityProvider.notifier).reset();
    state = const ObdConnectionState();
  }

  /// Tears the current session down.
  ///
  /// Every handle is detached into a local **before** the first await. The
  /// previous shape re-read the shared fields after awaiting, so a teardown
  /// started by a dropped link could still be running when the user reconnected
  /// and would then dispose the *new* client it found there.
  /// A teardown that is still unwinding, if any.
  ///
  /// `_handleConnectionLost` starts one without awaiting it, so a user who
  /// taps reconnect the moment the watchdog gives up begins a new connection
  /// while the old chain is still draining. That chain ends at a BLE
  /// disconnect, and the BLE layer keys devices by their platform id — the
  /// same physical adapter — so it is the *new* connection that gets dropped,
  /// seconds after appearing to succeed.
  ///
  /// A second `_teardown()` could not prevent it. The first detaches the
  /// handles synchronously, so the second found nothing left to wait for and
  /// returned immediately. Teardowns therefore chain: the one a connection
  /// awaits does not complete until every earlier one has.
  Future<void>? _teardownDraining;

  Future<void> _teardown() {
    // Every way a session ends passes through here — a failed connect, a
    // deliberate disconnect, a link that dropped, the provider being disposed.
    // The recording is worth keeping in all of them, and this is the one place
    // that does not have to enumerate them.
    _stopPeriodicSnapshots();
    unawaited(_saveTranscriptSnapshot());
    final chained = _drainTeardown(_teardownDraining);
    _teardownDraining = chained;
    return chained;
  }

  /// Writes the current recording where it can outlive this process.
  ///
  /// Reads through `exportableRecord`, so the file gets exactly what the
  /// export button would have produced — the same bytes under the same
  /// heading, rather than a second rendering that could disagree with it.
  /// Queues a snapshot the way the pause and teardown handlers do.
  @visibleForTesting
  Future<void> saveTranscriptSnapshotForTest() async {
    await _saveTranscriptSnapshot();
  }

  @visibleForTesting
  Future<bool> savePeriodicSnapshotForTest() => _savePeriodicSnapshotIfNeeded();

  @visibleForTesting
  Future<void> drainTranscriptSnapshotsForTest() => _savingSnapshot;

  Future<bool> _saveTranscriptSnapshot() {
    final record = exportableRecord;
    if (record == null) return Future<bool>.value(false);
    // Both reads happen now, before anything is awaited, so a save queued
    // behind another one still writes the session it was asked about rather
    // than whatever has since connected.
    final liveTranscript = record.transcript;
    final transcript = liveTranscript.frozenCopy();
    final header = record.header;
    // The simulator is a session with no vehicle in it. It may be saved — it
    // is still the last thing that happened — but it may not replace a
    // recording that came off an adapter.
    final fromRealHardware =
        _sessionTransport != TransportKind.demo && !_currentSessionIsTestRig;
    final recordedAtTrigger = liveTranscript.recorded;

    // Serialised, the same way teardown already is.
    //
    // Two saves can genuinely overlap: the watchdog declaring the link dead at
    // the moment the app is backgrounded runs the pause handler and the
    // teardown handler together. They opened the same staging file and wrote a
    // few hundred kilobytes each across many syscalls, so the two could
    // interleave into a file that is neither — and the rename then installed
    // the wreckage. Worse than losing one save: `load()` returns null on a
    // corrupt file, and the guard that stops a simulator overwriting hardware
    // asks `load()` first, so a corrupted recording silently withdrew its own
    // protection.
    final operation = _savingSnapshot.then((_) async {
      final saved = await transcriptStore.save(
        transcript,
        header,
        fromRealHardware: fromRealHardware,
      );
      if (saved) {
        _lastSavedTranscript = liveTranscript;
        _lastSavedMark = recordedAtTrigger;
      }
      return saved;
    });
    _savingSnapshot = operation.then<void>((_) {});
    return operation;
  }

  /// The tail of the snapshot queue. `TranscriptStore.save` never throws, so
  /// this cannot be poisoned by a failed write.
  Future<void> _savingSnapshot = Future<void>.value();

  /// How often a live session writes its recording to disk.
  ///
  /// Thirty seconds is the answer to a measurement rather than a guess. On a
  /// Pixel 9, 2026-08-20: backgrounding the app and then force-stopping it left
  /// the recording intact, because `onPause` ran — but `am crash` from the
  /// foreground left **nothing**, because no handler runs at all. The app
  /// crashing in a car is precisely the session somebody needs to send back,
  /// and it was the one with no record. So the snapshot is no longer only a
  /// farewell: during normal foreground operation, each successful write
  /// bounds the unsaved tail to roughly one interval.
  ///
  /// Not shorter, because the file is a few hundred kilobytes and this runs
  /// while the same phone is driving gauges off a 20 Hz stream. Not longer,
  /// because thirty seconds of a fault-code scan is most of the scan.
  Duration snapshotInterval = const Duration(seconds: 30);

  Timer? _snapshotTimer;

  /// Transcript identity and [ObdTranscript.recorded] as of the last write, so
  /// a tick with nothing new to say writes nothing. Both are required: a slow
  /// save from the previous session may complete after the next one begins,
  /// and equal entry counts do not make those two transcripts the same state.
  /// Updated by every path that saves, not just the timer's — otherwise the
  /// first tick after a pause rewrites what the pause handler already put there.
  ObdTranscript? _lastSavedTranscript;
  int _lastSavedMark = -1;

  void _startPeriodicSnapshots() {
    _snapshotTimer?.cancel();
    // A new session has a new transcript counting from zero, and the mark left
    // by the previous session's final save is a number from a different count.
    // They are very unlikely to collide, and "very unlikely" is a worse reason
    // to skip a write than "impossible" is.
    _lastSavedTranscript = null;
    _lastSavedMark = -1;
    _snapshotTimer = Timer.periodic(
      snapshotInterval,
      (_) => unawaited(_savePeriodicSnapshotIfNeeded()),
    );
  }

  Future<bool> _savePeriodicSnapshotIfNeeded() {
    // The background is the pause handler's job, and it has already written
    // once. A backgrounded session is also not adding anything.
    if (!_foreground) return Future<bool>.value(false);
    final record = exportableRecord;
    if (record == null) return Future<bool>.value(false);
    if (identical(record.transcript, _lastSavedTranscript) &&
        record.transcript.recorded == _lastSavedMark) {
      return Future<bool>.value(false);
    }
    return _saveTranscriptSnapshot();
  }

  void _stopPeriodicSnapshots() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
  }

  /// Where a recording goes so it survives the app being killed.
  @visibleForTesting
  TranscriptStore transcriptStore = TranscriptStore();

  Future<void> _drainTeardown(Future<void>? previous) async {
    final snapshotSub = _snapshotSub;
    final initSub = _initSub;
    final engine = _engine;
    final client = _client;

    // Detached first and synchronously, so nothing started after this point
    // can find them.
    // The transcript outlives the client that made it.
    //
    // This is the whole point of recording. Every connect failure ends in a
    // teardown, the teardown nulled the client, and the export read the
    // transcript *off* the client — so the one session whose bytes somebody
    // actually needs was the one session whose bytes were deleted, by the
    // code written to keep them. The header is rendered now rather than
    // lazily, because it reads live client state that is about to be gone.
    final record = client?.transcript ?? _attemptTranscript;
    if (record != null && !record.isEmpty) {
      _lastTranscript = record;
      _lastTranscriptHeader = transcriptHeader;
    }

    _snapshotSub = null;
    _initSub = null;
    _engine = null;
    _client = null;

    // A session ending must clear the display. Otherwise the last car's
    // readings sit on the gauges while the next connection is being made, and
    // for a few seconds the app shows one vehicle's data labelled as another's.
    if (!_telemetry.isClosed) _telemetry.add(const TelemetrySnapshot());

    if (previous != null) {
      // Bounded, because a wedged native disconnect must not make reconnecting
      // impossible — only ordered.
      try {
        await previous.timeout(const Duration(seconds: 5));
      } on Object {
        // An earlier teardown's failure is not this one's to report.
      }
    }

    await snapshotSub?.cancel();
    await initSub?.cancel();
    await engine?.dispose();
    await client?.dispose();
  }
}

final obdSessionProvider = NotifierProvider<ObdSession, ObdConnectionState>(
  ObdSession.new,
);

/// The current connection's immutable capability evidence.
///
/// Watching the session state retires this subscription when the connection
/// changes. The engine stream then makes scan phases and direct-answer
/// promotions visible without waiting for an unrelated telemetry repaint.
final obdCapabilitySummaryProvider = StreamProvider<ObdCapabilitySummary>((
  ref,
) {
  ref.watch(obdSessionProvider);
  final engine = ref.read(obdSessionProvider.notifier).engine;
  if (engine == null) {
    return Stream<ObdCapabilitySummary>.value(
      ObdCapabilitySummary.notStarted(),
    );
  }
  final controller = StreamController<ObdCapabilitySummary>();
  controller.add(engine.capabilitySummary);
  final subscription = engine.capabilitySummaries.listen(
    controller.add,
    onError: controller.addError,
  );
  ref.onDispose(() {
    unawaited(subscription.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

/// Live telemetry. Replays the engine's current snapshot before subscribing, so
/// a screen opened mid-drive paints real values on its first frame rather than
/// a row of dashes.
/// How often the UI re-asks the engine what it currently knows.
///
/// Staleness is a statement about *now*, and the screens only re-evaluated it
/// when a new snapshot arrived — which stops happening in exactly the
/// situations staleness exists for: the polling loop's exception path returns
/// without publishing, a protocol re-search runs silent for 25 seconds, a
/// wedged adapter answers nothing at all. Verified on a device: the gauges held
/// pre-freeze values at full brightness for three minutes, and the only thing
/// that dimmed them was switching tabs, because that forced a rebuild.
///
/// Anchoring the model to a wall clock, as the previous round did, fixed the
/// answer and not the question. Something has to ask again.
const Duration kTelemetryHeartbeat = Duration(seconds: 1);

/// Whether this session's bus can group PID requests at all.
///
/// Not the same question as `TelemetrySnapshot.fastModeEnabled`, and the
/// difference is the whole reason this exists. That flag is permission the
/// scheduler grants itself: `true` from construction, reset `true` on every
/// connection, and only ever withdrawn by `handleCorruptionEvent`.
/// `PriorityScheduler.canBatch` is whether grouping is possible — the engine
/// recomputes it before every command as "the detected addressing is CAN, and
/// at least one support block has actually answered".
///
/// On a non-CAN vehicle that is `false` for the entire session, and before
/// capability discovery lands it is `false` on CAN too, while the flag stays
/// `true` throughout. A screen reading the flag alone therefore announces that
/// grouping is enabled in sessions where `popBatch` can never group anything.
///
/// Engine state rather than snapshot state, because [TelemetrySnapshot] is
/// built in `lib/obd` and this slice does not change that library. It is
/// re-read on every snapshot, which is the same cadence as the widget that
/// consumes it, so the two cannot describe different moments by more than one
/// frame.
///
/// **Watch it; do not read it cold.** Like any `Provider` it caches, and its
/// dependency on [telemetryProvider] only invalidates it while something is
/// listening. A bare `container.read` before anything watches computes once
/// against `engine == null`, answers `false`, and can go on answering `false`
/// after a CAN session has come up — measured, on a Demo session whose
/// `canBatch` was `true` at the time. Under `ref.watch` in a widget the value
/// tracks the engine correctly, which is the only way production uses it. A
/// test that wants the live value must hold a listener open, and the tests for
/// this provider assert through the rendered label for that reason.
final busGroupsRequestsProvider = Provider<bool>((ref) {
  ref.watch(telemetryProvider);
  final session = ref.watch(obdSessionProvider.notifier);
  return session.engine?.scheduler.canBatch ?? false;
});

final telemetryProvider = StreamProvider<TelemetrySnapshot>((ref) {
  final session = ref.watch(obdSessionProvider.notifier);
  final controller = StreamController<TelemetrySnapshot>();

  final current = session.engine?.current;
  if (current != null) controller.add(current);

  final sub = session.telemetryStream.listen(
    controller.add,
    onError: controller.addError,
  );

  // Re-reads `engine.current` rather than replaying the last snapshot, so the
  // figures that age on the client — adapter voltage, throughput — are
  // recomputed too rather than being frozen scalars copied at publish time.
  final heartbeat = Timer.periodic(kTelemetryHeartbeat, (_) {
    if (controller.isClosed) return;
    // Only a foreground session with a running loop may be re-read.
    //
    // Without those two conditions the heartbeat undid the pause it was
    // supposed to complement, within one second. `_pauseNow` publishes an
    // empty snapshot when the app is backgrounded; `stop()` deliberately
    // retains the last readings so a resume has something to show while it
    // re-establishes. A heartbeat that reads `engine.current` regardless
    // therefore republished a stopped engine's retained 6000 rpm one second
    // after the screen had been cleared — and if the user came back while the
    // three-second voltage probe was still pending, that old number was on
    // screen looking entirely live before the link had been re-established.
    //
    // The state this exists for is different and is still covered: a *running*
    // loop whose link has gone silent, where nothing publishes because nothing
    // answers. There the values age on screen because something keeps asking.
    final engine = session.engine;
    if (engine == null || !engine.isRunning || !session.isForeground) return;
    controller.add(engine.current);
  });

  ref.onDispose(() {
    heartbeat.cancel();
    unawaited(sub.cancel());
    unawaited(controller.close());
  });

  return controller.stream;
});
