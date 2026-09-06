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
  String get dashboardEmptyTitle => 'The dashboard is empty';

  @override
  String get dashboardEmptyBody =>
      'Pick the signals you want to watch on the PID page and they will appear here.';

  @override
  String get dashboardChoosePids => 'Choose PIDs';

  @override
  String get dashboardWorkspaceGauges => 'Gauges';

  @override
  String get dashboardWorkspaceTrends => 'Trends';

  @override
  String get dashboardLocalRecordings => 'Local recordings';

  @override
  String get dashboardNotConnected => 'Not connected';

  @override
  String get dashboardGenericObd => 'Generic OBD';

  @override
  String get dashboardVinRead => 'VIN read';

  @override
  String get dashboardSingleRequestMode => 'Single request mode';

  @override
  String get gaugeUnsupportedByVehicle => 'Not supported by this vehicle';

  @override
  String get derivedEstimatesTitle => 'Estimated values';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Estimate formulas and assumptions';

  @override
  String get derivedAirflow => 'Airflow';

  @override
  String get derivedFuelUse => 'Fuel use';

  @override
  String get derivedEngineHorsepower => 'Engine power';

  @override
  String get derivedTorque => 'Torque';

  @override
  String get derivedEstimatedFuelTitle => 'Estimated fuel use';

  @override
  String get derivedEcuFuelTitle => 'ECU fuel data';

  @override
  String get derivedEcuReported => 'ECU reported';

  @override
  String get derivedUnavailableMessage =>
      'Horsepower can only be estimated once vehicle speed and acceleration data arrive';

  @override
  String get telemetryRecorderPhasePreparing => 'Preparing to record';

  @override
  String get telemetryRecorderPhaseRecording => 'Recording';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Saving the recording';

  @override
  String get telemetryRecorderPhaseIdle => 'Not recording';

  @override
  String get telemetryNotConnected => 'Not connected';

  @override
  String get telemetryDemoData => 'Built-in simulator data';

  @override
  String get telemetryRigData => 'Test rig data';

  @override
  String get trendSignalsHeading => 'Trend signals';

  @override
  String get trendNoSignalsTitle => 'No trend signals available';

  @override
  String get trendNoSignalsBody =>
      'Enable the signals you want to watch on the PID page first.';

  @override
  String get trendPickSignalsTitle => 'Choose trend signals';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Compare up to $limit signals. This does not change which PIDs are polled.';
  }

  @override
  String get trendLiveData => 'Live data';

  @override
  String get trendNoUnits => 'No units';

  @override
  String trendWindowSemantics(int seconds) {
    return 'Showing the last $seconds seconds';
  }

  @override
  String get trendAxisNow => 'Now';

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String trendRemoveSignal(String name) {
    return 'Remove $name';
  }

  @override
  String get trendChooseSignals => 'Choose signals';

  @override
  String trendTooManySelected(int limit) {
    return 'Choose at most $limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'One of those signals is no longer in the PID watch list';

  @override
  String get trendSelectionSaveFailed =>
      'Could not save the trend display selection';

  @override
  String trendSheetBody(int limit) {
    return 'Choose at most $limit. This only changes the chart, not PID polling or a recording in progress.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Done · $selected/$limit';
  }
}
