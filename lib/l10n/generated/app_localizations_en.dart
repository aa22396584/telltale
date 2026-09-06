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
  String get pidManagerHeadline => 'PID manager';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active enabled · $total available';
  }

  @override
  String get pidManagerAdd => 'New';

  @override
  String get pidManagerMoreActions => 'More';

  @override
  String get pidManagerArrangeDashboard => 'Arrange dashboard';

  @override
  String get pidManagerImportCsv => 'Import CSV';

  @override
  String get pidManagerExportCsv => 'Export custom PIDs';

  @override
  String get pidManagerSearchHint => 'Search by name or PID code…';

  @override
  String get pidManagerActiveOnly => 'Enabled only';

  @override
  String get pidManagerPowertrainBatteryCatalog => 'Powertrain-battery catalog';

  @override
  String get pidManagerNoMatchTitle => 'No matching PID';

  @override
  String get pidManagerNoMatchMessage =>
      'Try another keyword, or create a custom PID.';

  @override
  String get pidPickCsvDialogTitle => 'Choose a PID definition CSV';

  @override
  String pidImportPickerFailed(String error) {
    return 'Could not open the file picker: $error';
  }

  @override
  String pidImportReadFailed(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String get pidImportNothingToImport => 'No definitions to import.';

  @override
  String get pidExportNoCustomPids => 'There are no custom PIDs to export.';

  @override
  String pidExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return 'Add $count confirmed supported PIDs?';
  }

  @override
  String pidBulkAddCount(int count) {
    return 'Add $count';
  }

  @override
  String pidBulkAdded(int count) {
    return 'Added $count confirmed supported PIDs.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count support blocks are still unconfirmed — this adds only the items with positive evidence.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Will add $count. The more PIDs are enabled, the less often each one may refresh.';
  }

  @override
  String get pidCapabilityTitle => 'Vehicle-supported PIDs';

  @override
  String get pidCapabilityPhaseNotStarted => 'Scan not started';

  @override
  String get pidCapabilityPhaseRunning =>
      'Confirming what this vehicle supports';

  @override
  String get pidCapabilityPhaseAttemptFinished => 'This support scan finished';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'The support scan was interrupted';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'Vehicle-supported PIDs. $phase. $confirmed confirmed. $unknown unknown blocks.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confirmed';
  }

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown unknown blocks';
  }

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Contiguous coverage 01–$through (reached the end)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Contiguous coverage 01–$through (unknown beyond)';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'No contiguous coverage established yet';

  @override
  String get pidBulkActionPending => 'Waiting for scan results';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Add the $count confirmed';
  }

  @override
  String get pidBulkActionIncomplete => 'Scan data is incomplete';

  @override
  String get pidBulkActionZero => 'No confirmed supported PIDs';

  @override
  String get pidBulkActionAllActive => 'All already enabled';

  @override
  String get pidBulkActionLocked => 'Cannot change while recording';

  @override
  String get pidPillCustom => 'Custom';

  @override
  String get pidPillUnsupported => 'Unsupported';

  @override
  String pidRowStaleUnits(String units) {
    return '$units · stale';
  }

  @override
  String get pidRowEdit => 'Edit';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Show $name on the dashboard';
  }

  @override
  String get pidArrangeBody =>
      'Drag to reorder. The dashboard fills left to right and top to bottom, so whatever is first is seen first.';

  @override
  String get pidArrangeEmptyTitle => 'No PID is enabled yet';

  @override
  String get pidArrangeEmptyMessage =>
      'Enable a few in the list first, then come back to order them.';

  @override
  String get pidActionCancel => 'Cancel';

  @override
  String get pidActionDelete => 'Delete';

  @override
  String get pidEditorTitleNew => 'New custom PID';

  @override
  String get pidEditorTitleEdit => 'Edit PID';

  @override
  String get pidEditorDiscardTitle => 'Discard unsaved changes?';

  @override
  String get pidEditorDiscardBody =>
      'The changes to this PID have not been saved, and leaving loses them.';

  @override
  String get pidEditorKeepEditing => 'Keep editing';

  @override
  String get pidEditorDiscard => 'Discard';

  @override
  String get pidEditorDeleteTitle => 'Delete this PID?';

  @override
  String pidEditorDeleteBody(String name) {
    return 'The definition for “$name” is removed, its gauge disappears from the dashboard, and this cannot be undone.';
  }

  @override
  String pidEditorCollision(String name) {
    return 'A custom PID already uses this combination ($name). Use a different mode + PID, header, or name suffix.';
  }

  @override
  String get pidEditorSectionIdentity => 'Identity';

  @override
  String get pidEditorFieldName => 'Name';

  @override
  String get pidEditorFieldShortName => 'Short name (shown on the gauge)';

  @override
  String get pidEditorFieldUnits => 'Units';

  @override
  String get pidEditorSectionQuery => 'Query';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorModeAndPidHelper => 'For example 010C or 221101';

  @override
  String get pidEditorFieldHeader => 'CAN header';

  @override
  String get pidEditorHeaderHelper => '7E0 = engine';

  @override
  String get pidEditorSectionFormula => 'Formula';

  @override
  String get pidEditorFieldEquation => 'Expression';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N map to the response bytes; SIGNED(), ABS(), LOG10(), $valSyntax and BARO are available';
  }

  @override
  String get pidEditorFieldSample => 'Test response bytes';

  @override
  String get pidEditorSampleHelper =>
      'Enter hex to preview the result as you type';

  @override
  String get pidEditorSectionRangeAndPriority => 'Gauge range and priority';

  @override
  String get pidEditorFieldMin => 'Minimum';

  @override
  String get pidEditorFieldMax => 'Maximum';

  @override
  String get pidEditorSave => 'Save';

  @override
  String get pidPreviewTitle => 'Live preview';

  @override
  String get pidPreviewCannotEvaluate => 'Cannot evaluate';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'The preview substitutes $valueString for $dependencies; the real value comes from that PID once connected.';
  }

  @override
  String get pidPreviewResultLabel => 'Result';

  @override
  String get pidPriorityVeryLow => 'Very Low';

  @override
  String get pidPriorityLow => 'Low';

  @override
  String get pidPriorityMedium => 'Medium';

  @override
  String get pidPriorityHigh => 'High';

  @override
  String get pidListSeparator => ', ';
}
