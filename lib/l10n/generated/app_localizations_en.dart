// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Telltale';

  @override
  String get appTagline => 'Live vehicle telemetry';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get connectHeadline => 'Choose a connection';

  @override
  String get connectBody =>
      'Plug in an ELM327 adapter and switch the ignition on, or use the built-in simulator.';

  @override
  String get settingsHeadline => 'Settings';

  @override
  String get startupChecking =>
      'Checking local share cache and telemetry records';

  @override
  String get startupCannotComplete => 'Cannot finish startup checks';

  @override
  String get startupRetry => 'Retry';

  @override
  String get startupRestartRequired => 'Restart required to continue safely';

  @override
  String get startupRetryHint =>
      'Keep Telltale in the foreground, then retry after other file work finishes. Recording, replay, export and delete stay closed until startup completes.';

  @override
  String get startupRestartHint =>
      'Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.';

  @override
  String get languageSaveFailed => 'Could not save the language. Try again.';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get telemetryStatusStale => 'Data is stale';

  @override
  String get telemetryStatusUnsupported =>
      'The controller answered that it does not support this';

  @override
  String get telemetryStatusNoAnswer => 'No answer — will retry';

  @override
  String get telemetryStatusFormulaError => 'Formula error';

  @override
  String get telemetryStatusBusError => 'Bus error';

  @override
  String get telemetryStatusHeaderMismatch => 'Header does not match this bus';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Not a read-only query — nothing was sent';

  @override
  String get telemetryEndedByUser => 'Stopped by you';

  @override
  String get telemetryEndedByDisconnect =>
      'Stopped when the connection dropped';

  @override
  String get telemetryEndedBySessionReplacement =>
      'The connection session was replaced';

  @override
  String get telemetryEndedByBackground =>
      'Stopped when Telltale went to the background';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Reached the $minutes-minute limit';
  }

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'This recording reached its size limit';

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Local recording storage is full';

  @override
  String get telemetryEndedByStorageBackpressure => 'Storage could not keep up';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'The PID selection changed';

  @override
  String get telemetryEndedByStorageFailure => 'Saving failed';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Recovered after the last interruption';

  @override
  String get telemetryStartRecording => 'Recording started';

  @override
  String get telemetryStartNeedsConnection =>
      'Connect before starting a recording';

  @override
  String get telemetryStartNeedsForeground =>
      'Bring Telltale to the foreground before starting a recording';

  @override
  String get telemetryStartSpeedUnknown =>
      'Cannot confirm the vehicle is stopped — disconnect first';

  @override
  String get telemetryStartMoving => 'Park the vehicle first';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale went to the background — no recording started';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'The connection dropped — no recording started';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'The connection session was replaced — no recording started';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Local recordings reached the limit of $limit — export or delete some first';
  }

  @override
  String get telemetryStartLibraryByteLimit =>
      'Not enough local storage for a recording — export or delete some first';

  @override
  String get telemetryStartInvalidConfiguration =>
      'This PID selection cannot be recorded safely — check the definitions';

  @override
  String get telemetryStartCannotCreateFile =>
      'Could not create the recording file';

  @override
  String get telemetryStartBusy =>
      'Another recording or file operation has not finished';

  @override
  String get telemetryRestartToRepairStartup =>
      'Startup cleanup did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryRestartToRepairSave =>
      'Saving did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryPendingOwnerRecovery =>
      'This process still holds the operation. If it stays here, quit Telltale completely and reopen it';

  @override
  String get telemetryStartNeedsActivePid => 'Enable at least one PID first';

  @override
  String get telemetryStartTooManyPids =>
      'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first';

  @override
  String get telemetryBlockedByRecorder => 'Stop and save the recording first';

  @override
  String get telemetryDeleteNeedsConfirmation => 'Confirm this delete first';

  @override
  String get telemetryArtifactRestartRequired =>
      'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing';

  @override
  String get dtcHeadline => 'Fault codes';

  @override
  String get dtcNotScanned => 'Not scanned yet';

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes',
      one: '1 code',
    );
    return '$_temp0';
  }

  @override
  String get dtcVerdictCompleteClean =>
      'No fault codes from the controllers that answered';

  @override
  String get dtcVerdictPartialClean => 'Partially unconfirmed';

  @override
  String get dtcUnconfirmed => 'Cannot confirm';

  @override
  String get dtcClear => 'Clear';

  @override
  String get dtcClearing => 'Clearing…';

  @override
  String get dtcRescanFirst => 'Rescan first';

  @override
  String get dtcDismiss => 'Dismiss';

  @override
  String get dtcClearDialogTitle => 'Clear fault codes?';

  @override
  String get dtcClearDialogBody =>
      'This erases stored and pending fault codes and turns the fault lamp off, and it also resets emissions readiness — the vehicle has to complete a full round of self-diagnosis again before it can pass an inspection. Permanent fault codes (Mode 0A) cannot be cleared.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'The freeze frame for $codes goes with it — the whole record of engine speed, coolant temperature and load at the moment the fault happened — and it cannot be read back until the fault happens again.';
  }

  @override
  String get dtcClearDialogFrameUnread =>
      'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear.';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories in this scan did not answer completely',
      one: 'One category in this scan did not answer completely',
    );
    return '$_temp0 ($categories), so there may be fault codes you have not seen. After a clear they can never be read again.';
  }

  @override
  String get dtcClearCancel => 'Cancel';

  @override
  String get dtcClearConfirm => 'Clear them';

  @override
  String get dtcNotConnectedTitle => 'Not connected';

  @override
  String get dtcNotConnectedBody =>
      'Reading fault codes needs a connected ELM327 adapter, or the simulator running.';

  @override
  String get dtcScanTitle => 'Scan the vehicle for fault codes';

  @override
  String get dtcScanBody =>
      'Reads Mode 03 stored, Mode 07 pending and Mode 0A permanent fault codes.';

  @override
  String get dtcReadFailed => 'Read failed';

  @override
  String get dtcScanning => 'Scanning…';

  @override
  String get dtcStartScan => 'Start scan';

  @override
  String get dtcRetry => 'Retry';

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear the fault codes, because clearing destroys the record of the moment of the fault permanently. If every scan looks the same, this vehicle may not provide one.';

  @override
  String get dtcCompleteCleanTitle =>
      'None of the controllers that answered reported a fault code.';

  @override
  String get dtcCompleteCleanBody =>
      'That means every controller that replied reported no fault code. It does not mean every module on the vehicle was asked.';

  @override
  String get dtcPartialCleanTitle =>
      'The categories that answered reported no fault codes.';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controllers',
      one: 'One controller',
    );
    return 'All three categories were queried to completion. $_temp0 ($controllers) implement neither pending nor permanent fault codes — normal on many vehicles, and also why this cannot be declared a fault-free vehicle.';
  }

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories did not answer, so their state cannot be confirmed — that is not the same as the vehicle having no problem.';
  }

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcManufacturerSpecific =>
      'Manufacturer-specific code — check the service manual for this vehicle';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — this app has no detailed description for this code';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'A fault related to $category';
  }

  @override
  String dtcControllerLabel(Object controller) {
    return 'Controller $controller';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fault codes were read',
      one: 'One fault code was read',
    );
    return '$_temp0 before this category stopped, but the coverage is incomplete:';
  }

  @override
  String get dtcSilentCategoryHeadline => 'This category did not answer';

  @override
  String get dtcSilentPermanentDetail =>
      'Permanent fault codes (Mode 0A) did not answer. This category arrived with the OBD-II generation around 2010, so older vehicles do not always support it — but no answer can equally mean it simply was not read this time, and the two cannot be told apart. The stored fault-code result is unaffected.';

  @override
  String get dtcSilentPendingDetail =>
      'Pending fault codes (Mode 07) did not answer. This ECU may not implement the service, or it may simply not have been read this time — no answer cannot tell the two apart, and must not be taken to mean there are no pending faults. The stored fault-code result is unaffected.';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'The vehicle did not answer the Mode $mode query, so whether it has stored fault codes cannot be confirmed. That is not the same thing as having no fault codes.';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Only some controllers in this category answered and the rest did not reply, so this cannot stand as a result for the whole vehicle. $message';
  }

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'The vehicle did not answer the Mode $mode query, and Mode 03 did not answer either — so there is no telling whether the vehicle lacks support or this connection simply did not read it.';
  }

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcUnknownError => 'Unknown error';

  @override
  String get dtcFreezeFrameTitle => 'The vehicle at the moment of the fault';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'The values this controller recorded at the instant $code was confirmed. Clearing fault codes destroys this record with them.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'This controller has a freeze frame, but it did not answer the query asking which items are in it, so the contents could not be read. A rescan may work.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'This controller has a freeze frame, but none of the items in it are ones this app can decode.';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count further items in this freeze frame have no conversion formula in this app, so they are not listed.',
      one: 'A further item in this freeze frame has no conversion formula in this app, so it is not listed.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read them.',
      one: 'One item did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read it.',
    );
    return '$_temp0';
  }

  @override
  String get dtcMilOn => 'The fault lamp is lit';

  @override
  String get dtcMilOff => 'The fault lamp is not lit';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This controller self-reports $count confirmed fault codes.',
      one: 'This controller self-reports 1 confirmed fault code.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'This controller self-reports no confirmed fault codes.';

  @override
  String get dtcReadinessTitle => 'Emissions readiness';

  @override
  String get dtcReadinessSaysNothing =>
      'This controller reported no readiness monitors at all — it may not be responsible for emissions monitoring, and that does not mean it is ready.';

  @override
  String get dtcReadinessAllComplete =>
      'Every readiness monitor this controller is responsible for is complete.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitors are still unfinished',
      one: '1 monitor is still unfinished',
    );
    return '$_temp0 — an inspection now may not pass.';
  }

  @override
  String get dtcUnknownMonitor => 'Unknown monitor';

  @override
  String get dtcListSeparator => ', ';
}
