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
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signals',
      one: '1 signal',
    );
    return '$_temp0';
  }

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valid values',
      one: '1 valid value',
    );
    return '$_temp0';
  }

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statuses',
      one: '1 status',
    );
    return '$_temp0';
  }

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gaps',
      one: '1 gap',
    );
    return '$_temp0';
  }

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsTitle => 'Local recordings';

  @override
  String get telemetryReload => 'Reload';

  @override
  String get telemetrySessionsLoadFailed => 'Could not load — retry';

  @override
  String get telemetrySessionsEmpty =>
      'No local recordings yet\nConnect, then start recording';

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return 'Local storage: $groups of $groupLimit groups, $used of $byteLimit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit groups';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more groups not shown',
      one: '1 more group not shown',
    );
    return '$_temp0';
  }

  @override
  String get telemetrySessionsReplayable => 'Recordings you can replay';

  @override
  String get telemetrySessionsDamaged => 'Damaged recording files';

  @override
  String get telemetryDeleteDamagedTooltip => 'Delete damaged recording';

  @override
  String get telemetryDeleteDamagedTitle => 'Delete this damaged recording?';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'This deletes $id (file time $time). It cannot be undone.';
  }

  @override
  String get telemetryDamagedCollision =>
      'A finished and an unfinished file share this id — neither was chosen';

  @override
  String get telemetryDamagedCorrupt =>
      'The recording is damaged and cannot be read safely';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'File time $time';
  }

  @override
  String get telemetryCancel => 'Cancel';

  @override
  String get telemetryDelete => 'Delete';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'Delete did not finish: $reason';
  }

  @override
  String get telemetryReplayTitle => 'Recording replay';

  @override
  String get telemetryReplayLoadFailed => 'Could not load the recording';

  @override
  String get telemetryReplayUnreadable =>
      'The recording is damaged or cannot be read';

  @override
  String get telemetryDeleteSessionTitle => 'Delete this local recording?';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'This deletes the recording from $time. It cannot be undone.';
  }

  @override
  String telemetryExportFailed(String reason) {
    return 'Export did not finish: $reason';
  }

  @override
  String get telemetryOfflineSampledReplay => 'Offline sampled replay';

  @override
  String get telemetryPlay => 'Play';

  @override
  String get telemetryPause => 'Pause';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Replay position $percent%';
  }

  @override
  String get telemetryExport => 'Export';

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sampled points',
      one: '1 sampled point',
    );
    return '$_temp0';
  }

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count breaks',
      one: '1 break',
    );
    return '$_temp0';
  }

  @override
  String get telemetryExportSheetTitle => 'Export a local recording';

  @override
  String get telemetryExportCsv => 'Export CSV';

  @override
  String get telemetryExportJson => 'Export JSON';

  @override
  String get telemetryRecorderPhaseIdle => 'Foreground local recording';

  @override
  String get telemetryRecorderPhasePreparing => 'Preparing to record';

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Recording — no values yet';

  @override
  String get telemetryRecorderPhaseRecording => 'Recording';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Saving the recording';

  @override
  String get telemetryRecorderPhaseCompleted => 'Recording saved';

  @override
  String get telemetryRecorderPhaseFailed => 'Saving the recording failed';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Recording $duration';
  }

  @override
  String get telemetryOpenHistory => 'Open local recordings';

  @override
  String get telemetryDismissNotice => 'Dismiss';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Records only the OBD signals you have enabled — no location, VIN, or account data. Trends show at most $laneLimit signals; a recording keeps all $activeCount enabled signals and adds estimated horsepower and estimated fuel rate, which rest on the vehicle assumptions.';
  }

  @override
  String get telemetryStarting => 'Starting';

  @override
  String get telemetryStartRecordingButton => 'Start recording';

  @override
  String get telemetryStopAndSave => 'Stop and save';

  @override
  String get telemetryReturnToTrends => 'Back to trends';

  @override
  String get telemetryRecoveryTitle =>
      'Startup check of the recordings finished';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interrupted recordings were safely sealed',
      one: '1 interrupted recording was safely sealed',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unfinished files with no valid values were cleaned up',
      one: '1 unfinished file with no valid values was cleaned up',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count damaged or conflicting files were left unchanged',
      one: '1 damaged or conflicting file was left unchanged',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Damaged content is never used for replay or export, and can only be deleted by hand while it is safe to do so.';

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved groups — replay and export offline',
      one: '1 saved group — replay and export offline',
    );
    return '$_temp0';
  }

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes bytes',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get transcriptNothingToExport => 'There is no transcript to export.';

  @override
  String transcriptExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get transcriptExportExplanation =>
      'This connection keeps the opening handshake and the most recent raw traffic; if a long connection drops the middle, the file says so. When something will not read on the car, exporting the transcript and bringing it back is worth far more than one message on screen.';

  @override
  String get transcriptExportButton => 'Export transcript';

  @override
  String get transcriptExportWithHex => 'With hex';

  @override
  String get transcriptExport => 'Export';

  @override
  String get transcriptDelete => 'Delete';

  @override
  String get transcriptRecoveredTitle =>
      'Transcript from the previous connection';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Left at $timestamp, $size. It survived the system killing Telltale or the phone losing power.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'The previous connection\'s transcript has changed — check it again.';

  @override
  String get transcriptDeleteBusy => 'Another file operation has not finished.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'The current speed or connection state does not allow deleting the transcript.';

  @override
  String get transcriptDeleteFailed =>
      'Could not delete the previous connection\'s transcript.';

  @override
  String get powertrainConfirmTitle =>
      'Vehicle battery signals await confirmation';

  @override
  String get powertrainConfirmBody =>
      'Installed profile signals are read only after you confirm this car is that model, and the confirmation lasts for this connection alone.';

  @override
  String get powertrainConfirmButton => 'Confirm vehicle';

  @override
  String get powertrainConfirmDialogTitle => 'Confirm the connected vehicle';

  @override
  String get powertrainConfirmDialogBody =>
      'Once confirmed, this profile\'s read-only battery queries are polled for the rest of this connection. The wrong profile can produce numbers that look plausible and are wrong — cancel if you are not sure.';

  @override
  String get powertrainCancel => 'Cancel';

  @override
  String get powertrainConfirmAccept => 'This is the car';

  @override
  String get powertrainConnectionChanged =>
      'The connection changed — confirm the vehicle again for the new connection.';

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Battery signals for $profile are on for this connection';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Could not enable: $reason';
  }

  @override
  String get powertrainProfileNotVerified =>
      'The profile is not in the verified catalog';
}
