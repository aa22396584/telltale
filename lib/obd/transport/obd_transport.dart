/// Transport abstraction over the four physical links Torque supports:
/// Bluetooth Classic RFCOMM, Bluetooth LE, Wi-Fi TCP, plus a built-in
/// simulator.
///
/// Transports deal only in bytes. Prompt framing, the AT handshake and the
/// error matrix all live in `Elm327Client`, so every link shares one
/// implementation of the tricky parts.
library;

import 'dart:async';

enum TransportKind {
  bluetoothClassic('Bluetooth Classic'),
  bluetoothLe('Bluetooth LE'),
  wifi('Wi-Fi'),
  demo('Demo 模擬器');

  const TransportKind(this.label);

  /// The transport's identity **in an exported artifact**, not its tile title.
  ///
  /// This string is written into the evidence header (`# 連線方式：`, via
  /// `SessionEvidenceMetadata.transportKind`) and into the transcript notes
  /// that go out with it. Two people compare those files against each other, weeks
  /// apart, on different phones; an evidence field whose language depends on a
  /// phone setting is one nobody can diff. So it stays fixed, and the screen
  /// gets its own copy from the ARBs.
  ///
  /// **Do not put this in a `Text` widget.** The connect screen's tile title
  /// and the "last adapter used" line come from `transportKindTitle` in
  /// lib/ui/screens/connect/transport_kind_copy.dart, which answers in the
  /// driver's language. `test/l10n/l03_connect_l10n_test.dart` fails if this
  /// one reaches the screen again.
  final String label;

  /// Bluetooth Classic SPP: Android RFCOMM cascade, or Windows Bluetooth COM.
  /// iOS has no third-party SPP; macOS/Linux remain product-gated.
  bool get isClassicHostLimited => this == TransportKind.bluetoothClassic;
}

/// A link the user can pick in the connection wizard.
class DiscoveredDevice {
  final String id;
  final String name;
  final TransportKind kind;

  /// Signal strength in dBm where the link reports it, else null.
  final int? rssi;

  /// True when the OS already has a bond with this device.
  final bool isPaired;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.kind,
    this.rssi,
    this.isPaired = false,
  });

  /// Rough 0–4 bar strength from RSSI, or null when there is no RSSI to judge.
  ///
  /// Null rather than four. This returned *full strength* for a device with no
  /// signal reading at all — and a bonded Classic device has none until
  /// something scans, which is most of the list most of the time. Unknown
  /// rendered as best is the failure this whole codebase is arranged against,
  /// arriving in the one place it would be dismissed as cosmetic: it is the
  /// bar somebody uses to pick which of five similarly-named devices is the
  /// one in the car in front of them.
  ///
  /// Thresholds are the conventional Wi-Fi/BLE ones: −55 excellent, −67 good,
  /// −78 fair, −90 the edge of usable.
  int? get signalBars {
    final value = rssi;
    if (value == null) return null;
    if (value >= -55) return 4;
    if (value >= -67) return 3;
    if (value >= -78) return 2;
    if (value >= -90) return 1;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveredDevice && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);
}

/// Why a link-level attempt failed, as an identifier the screen can translate.
///
/// [TransportException.message] stays Traditional Chinese and keeps going into
/// the attempt transcript, for the same reason `ObdConnectionIssue` leaves
/// `ObdConnectionState.error` alone: a record whose language follows a phone
/// setting is one nobody can compare with anybody else's. This says the same
/// thing without the words, so the screen can say it in the reader's language.
///
/// Those two names are written as text rather than as doc links on purpose:
/// they live in `lib/state/`, and this file is engine code that must not import
/// it. A link here would be the first step of the dependency going the wrong
/// way.
///
/// Nothing here is a verdict. `bleNoSerialCharacteristic` says what was not
/// found, not that the device is the wrong kind; `classicAllTiersRefused` says
/// what is missing, not that the adapter is broken.
enum TransportIssue {
  /// The attempt was abandoned before it finished -- the user backed out, or a
  /// newer attempt superseded it. Not a failure of the adapter or the link.
  cancelled,

  /// Android could not bind the socket to Wi-Fi because the phone is on no
  /// Wi-Fi network at all. The only one of the route failures for which
  /// "connect to the adapter's hotspot first" is the right remedy.
  wifiRouteNoNetwork,

  /// More than one Wi-Fi network is equally plausible, so none was chosen
  /// rather than guessing which one reaches the adapter.
  wifiRouteAmbiguous,

  /// The system refused to bind the route. Distinct from having no network:
  /// there is one, and it was not allowed.
  wifiRouteRefused,

  /// The platform channel did not answer in time. The bind may still land
  /// afterwards, which is why the transport releases it regardless.
  wifiRouteTimeout,

  /// The bind failed for a reason the binder could not classify. Kept separate
  /// so an unrecognised platform code never borrows another one's remedy.
  wifiRouteUnclassified,

  /// The socket was refused or unreachable at that address and port.
  wifiHostUnreachable,

  /// The socket neither connected nor refused within the budget.
  wifiConnectTimeout,

  /// The link came up, but the process-wide route could not be put back, so
  /// the connection was dropped rather than left with the phone's networking
  /// in a state this app changed and could not undo.
  wifiRouteRestoreFailed,

  /// The BLE link itself never came up.
  bleLinkFailed,

  /// The link is up, but no notify/write characteristic pair was found. The
  /// device may not be an ELM327 at all.
  bleNoSerialCharacteristic,

  /// Every Bluetooth Classic tier was refused.
  ///
  /// Named for what was established, not for the likeliest cause. It was
  /// `classicPairingRequired`, which is the diagnosis rather than the
  /// observation -- and this enum's own doc says nothing here is a verdict.
  /// Unpaired is by far the most common reason, and the copy says so; the
  /// identifier does not.
  classicAllTiersRefused,

  /// A Bluetooth Classic tier timed out. The adapter may still be answering,
  /// so retrying immediately tends to make it worse.
  classicConnectTimeout,

  /// The serial port could not be opened. On desktop this usually means the
  /// system has not created one for the adapter yet.
  serialPortOpenFailed,

  /// The serial port opened and dropped straight away.
  serialDroppedOnOpen,

  /// A write failed on an already-open link.
  ///
  /// Not a connect failure. The screen it reaches is the settings manual
  /// command panel; `lib/ui/screens/settings/manual_command_copy.dart` says it.
  /// That file is no longer the settings panel's alone -- the fault-code screen
  /// renders command failures through the same table -- but this identifier is
  /// thrown from `write()` and the manual panel is where it arrives.
  writeFailed,

  // ------- the command path: failures of a link that is already open -------
  //
  // Everything above happens while a link is being established and is rendered
  // by the connect screen. Everything below happens to a command, on a link
  // that came up, and is rendered by the command-failure table in
  // `lib/ui/screens/settings/manual_command_copy.dart` -- from the manual
  // command panel, and from the fault-code screen for the three a scan can
  // raise. A clear and a VIN read raise them too and carry them nowhere; that
  // file's header says which routes are wired and which are not, and why. The
  // split is not stylistic: a connect failure is answered by trying again, and
  // a command failure is answered by reading what the adapter did.

  /// The transport reported that the link went away without being asked to.
  ///
  /// An adapter pulled out of the OBD socket, or a radio that dropped. The
  /// command in flight is failed because nothing is going to answer it.
  ///
  /// Deliberately not the same identifier as [disconnectedByApp], which
  /// carries the same sentence today. One says something happened to the
  /// adapter; the other says the app closed the link on purpose. Told the
  /// first when the second is true, a reader goes looking for a fault in a car
  /// that has none.
  linkDroppedMidSession,

  /// The app closed the link itself, so a command still in flight was failed.
  ///
  /// The outcome of the command is unknown -- it may have been transmitted --
  /// but nothing is wrong with the link or the vehicle.
  disconnectedByApp,

  /// A command was refused before any byte left the app, because no link is
  /// open. Provably unsent: the adapter owes nothing.
  notConnected,

  /// The adapter never answered the resynchronisation probe.
  ///
  /// The client had lost track of which reply belongs to which command, could
  /// not recover the alignment, and tore the link down rather than go on
  /// attributing answers it cannot attribute.
  adapterSilentOnResync,

  /// The adapter refused `ATSH` while aiming one query at one controller.
  ///
  /// `?` is how an ELM327 declines a header the current bus cannot take. The
  /// query is not sent: on whatever header the adapter really holds, the reply
  /// would come back from a controller nobody asked.
  ///
  /// Named for the method that was refused rather than for the kind of
  /// address, because `sendGlobal` also installs a physical header on its
  /// per-controller retry -- so "physical" would not separate the two.
  queryHeaderRefused,

  /// The adapter refused the `ATSH` a request *about the vehicle* needed.
  ///
  /// Separate from [queryHeaderRefused] because what is lost is different: a
  /// fault-code scan, a clear or a VIN read is a question the whole emissions
  /// system answers, and without the header its replies cannot be attributed
  /// to the controllers that sent them. One unavailable sensor reading and an
  /// unattributable whole-vehicle answer are not the same failure.
  ///
  /// The address is not always the functional broadcast one: the same code
  /// path pursues a named controller when the scan retries the ones that
  /// stayed silent. The Chinese message still says 功能定址 in both cases,
  /// which is pre-existing and inaccurate on the retry; the identifier does
  /// not repeat the claim.
  wholeVehicleHeaderRefused,

  /// A whole-vehicle scan was deliberately abandoned before it was sent.
  ///
  /// The bus is a legacy one, which has no single documented broadcast address
  /// for OBD, and a physical header is currently installed. The scan would
  /// therefore have gone to exactly one controller while the screen presented
  /// the answer as the whole vehicle -- a clean result for a car nobody
  /// finished checking. Nothing failed; the app refused.
  legacyScanWouldBePartial,

  /// Nothing arrived from the adapter within the watchdog's budget, so the
  /// link was torn down. Distinct from [linkDroppedMidSession]: the transport
  /// still believes it is connected, and the silence is what is known.
  linkStoppedResponding,

  /// The session that would have sent this command has ended or gone to the
  /// background, so the bytes never left. Not a failure of the link or the
  /// vehicle: the app stopped asking.
  operationRetired,

  /// The request cannot be addressed on this bus. Retrying will not help:
  /// there is no header that would reach the controller it names.
  requestUnaddressable,
}

/// Raised for link-level failures.
///
/// [message] is Traditional Chinese and goes to the transcript verbatim.
/// [issue] is what the screen renders, through
/// `lib/ui/screens/connect/handshake_copy.dart` for a connect failure and
/// `lib/ui/screens/settings/manual_command_copy.dart` for a command failure.
/// Both describe the same failure; the guard in
/// `test/l10n/transport_issue_guard_test.dart` is what keeps a new throw from
/// carrying only one of them.
class TransportException implements Exception {
  final String message;
  final Object? cause;

  /// Null only where the failure cannot reach a screen. The guard names the
  /// files where it may not be null.
  final TransportIssue? issue;

  /// The one value the identifier's sentence has to name, carried as data.
  ///
  /// Three of the identifiers are about a specific address -- the header the
  /// adapter refused, or the one it is stuck on -- and a sentence that cannot
  /// say which one is a sentence nobody can act on. The value therefore has to
  /// travel beside the identifier rather than inside it: an identifier per
  /// header would be an unbounded enum, and interpolating it into [message]
  /// would put it only in the Chinese sentence the screen no longer renders.
  ///
  /// A plain `String?` rather than a payload class, because there is exactly
  /// one such value per failure and every one of them so far is a header
  /// address. What keeps it honest is not the type but the guard: the scan in
  /// `test/l10n/transport_issue_guard_test.dart` fails a throw that names one
  /// of those three identifiers without also passing this. A payload class
  /// would need the same guard and buy nothing else.
  final String? issueDetail;

  /// Both named, and [issue] required.
  ///
  /// It was `[this.cause, this.issue]`. `cause` is `Object?`, so putting the
  /// identifier in the cause slot -- `TransportException('...',
  /// TransportIssue.cancelled)` -- was legal Dart: it analysed clean, the guard
  /// passed, `issue` came out null, the screen fell back to the Chinese
  /// sentence, and `toString()` prints only `message`, so nothing anywhere
  /// showed that the identifier had gone into the wrong slot. Found by review,
  /// by doing it.
  ///
  /// Required rather than defaulted because a throw with no identifier should
  /// have to write `issue: null` and mean it.
  ///
  /// Where that is still allowed is a mechanical question, not a number. The
  /// scan in `test/l10n/transport_issue_guard_test.dart` walks `lib/obd/` and
  /// `lib/state/` and fails any direct construction that settles for null;
  /// what it cannot see is the subclasses below that still bake it into
  /// their own constructors and are held by a written roster in the same file.
  ///
  /// This sentence used to carry a count of the throws still to be migrated.
  /// It drifted three times — fourteen, then eight, then six — and is now
  /// zero, which is exactly how long a number in a doc comment stays true.
  const TransportException(
    this.message, {
    this.cause,
    required this.issue,
    this.issueDetail,
  });

  @override
  String toString() => 'TransportException: $message';
}

/// The transport refused a write before any byte left the app.
///
/// Every transport opens `write` with the same precondition — no socket, no
/// characteristic, no connection — and it is the one point in the stack where
/// "nothing was transmitted" is a fact rather than an inference. Everything
/// deeper has already handed bytes to an OS buffer, a GATT queue or an RFCOMM
/// stream, and a failure there says nothing about whether the adapter saw
/// them.
///
/// The distinction is not academic. `PollingEngine.clearDtcs` decides from the
/// write audit whether repeating a global Mode 04 could reach a controller
/// that has already erased its memory. Without this type the audit had to
/// record the command *before* calling `write`, so a write rejected at the
/// guard was reported as "sent, do not retry" — locking the button on a clear
/// that had provably not happened, and stranding somebody who could safely
/// have tapped it again.
///
/// Recording before the write stays the default, because that is the
/// conservative direction: an unknown failure must read as possibly-sent. This
/// only subtracts the cases where the transport itself says otherwise.
class WriteRefusedException extends TransportException {
  /// [TransportIssue.notConnected]: nothing was transmitted, because no link
  /// is open. The clear-DTC audit still keys off the type; the manual-command
  /// panel keys off the identifier.
  const WriteRefusedException(super.message)
    : super(issue: TransportIssue.notConnected);
}

/// The request cannot be addressed on this bus, and retrying will not help.
///
/// Separate from its parent because the polling loop treats a
/// [TransportException] as a timeout — yield, let the watchdog recover, try
/// again — which is right for a link that dropped and wrong for a structural
/// condition. Retried silently, this one produces a gauge that is dark forever
/// with nothing on screen to say why, which is the failure it was raised to
/// prevent.
/// The operation's owner expired before its bytes went out.
///
/// A distinct type because it is not a failure of the link or the vehicle:
/// nothing was transmitted and nothing is wrong. Callers that would otherwise
/// mark a PID faulty or a scan broken should recognise it as "the app stopped
/// asking", which is what it is.
class OperationRetiredException extends TransportException {
  /// [TransportIssue.operationRetired]: the app stopped asking. The polling
  /// loop still keys off the type so it does not mark a PID faulty; the
  /// manual-command panel keys off the identifier.
  const OperationRetiredException(super.message)
    : super(issue: TransportIssue.operationRetired);

  @override
  String toString() => 'OperationRetiredException: $message';
}

class UnaddressableRequestException extends TransportException {
  /// [TransportIssue.requestUnaddressable]: no header on this bus reaches the
  /// named controller. The polling loop still keys off the type so it records
  /// a fault instead of retrying forever; the copy layer keys off the
  /// identifier if the exception ever reaches a panel.
  const UnaddressableRequestException(super.message)
    : super(issue: TransportIssue.requestUnaddressable);

  @override
  String toString() => 'UnaddressableRequestException: $message';
}

abstract class ObdTransport {
  TransportKind get kind;

  /// Human-readable identity of what we are connected to.
  String get displayName;

  /// Stable, read-only facts already known about this transport.
  ///
  /// Implementations must not perform I/O to populate this projection. Keys
  /// are emitted in a deterministic order so exported diagnostics remain
  /// readable and diffable. Device identifiers are verbatim platform values,
  /// not anonymized identifiers.
  Map<String, Object> get diagnosticMetadata;

  bool get isConnected;

  /// Raw bytes as they arrive. Chunk boundaries are arbitrary — BLE in
  /// particular splits replies across notifications — so consumers must
  /// reassemble rather than assume one chunk is one reply.
  Stream<List<int>> get incoming;

  /// Emits false when the link drops so the UI can react without polling.
  Stream<bool> get connectionChanges;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> write(List<int> data);
}

/// Shared plumbing: broadcast controllers and connection bookkeeping that all
/// four transports need identically.
abstract class BaseObdTransport implements ObdTransport {
  final _incoming = StreamController<List<int>>.broadcast();
  final _connectionChanges = StreamController<bool>.broadcast();
  bool _connected = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Stream<bool> get connectionChanges => _connectionChanges.stream;

  @override
  bool get isConnected => _connected;

  /// Test and simulator transports have no link-specific metadata by default.
  @override
  Map<String, Object> get diagnosticMetadata => const {};

  /// Publishes received bytes to listeners.
  void emitBytes(List<int> data) {
    if (!_incoming.isClosed && data.isNotEmpty) _incoming.add(data);
  }

  /// Records a connection state change, ignoring no-op transitions.
  void setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connectionChanges.isClosed) _connectionChanges.add(value);
  }

  /// Releases the controllers. Subclasses must call this from [disconnect]
  /// only when the transport is being discarded, not on a transient drop.
  Future<void> disposeStreams() async {
    await _incoming.close();
    await _connectionChanges.close();
  }
}
