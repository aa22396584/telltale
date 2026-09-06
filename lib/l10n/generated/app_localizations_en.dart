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
  String get powertrainCatalogTitle => 'Powertrain battery catalog';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Offline catalog could not load';

  @override
  String get powertrainCatalogLoadFailedBody =>
      'Integrity verification did not pass, so no vehicle data is shown or installed.';

  @override
  String get powertrainCatalogRevalidate => 'Verify again';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profiles: $profiles · Experimental one-shot reads: $probeable';
  }

  @override
  String get powertrainCatalogScopeNote =>
      'The catalog is wide, but “we found data” is not “your car is supported”. Research-only entries never carry a command; experimental entries still read one command at a time, each after its own confirmation.';

  @override
  String get powertrainCatalogSearchHint =>
      'Search make, model, variant or market…';

  @override
  String get powertrainFilterAll => 'All';

  @override
  String get powertrainNoMatchTitle => 'No matching vehicle';

  @override
  String get powertrainNoMatchBody =>
      'Try a make or model name, or switch to another powertrain type.';

  @override
  String get powertrainStatusReady => 'Fuller source data';

  @override
  String get powertrainStatusCommunity => 'Community · unverified';

  @override
  String get powertrainStatusExperimental => 'Experimental · unverified';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimental · read once';

  @override
  String get powertrainStatusResearchOnly => 'Research only';

  @override
  String get powertrainEvidenceSourceBacked => 'Source data';

  @override
  String get powertrainEvidenceSyntheticRig => 'Synthetic rig';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Project vehicle';

  @override
  String get powertrainQuarantinedPill => 'Quarantined · reconnect';

  @override
  String powertrainSignalCount(int count) {
    return 'Signals: $count';
  }

  @override
  String get powertrainInstallButton => 'Install battery signals';

  @override
  String get powertrainInstalledRemoveButton => 'Installed · remove signals';

  @override
  String get powertrainProbeReconnectFirst => 'Reconnect, then try again';

  @override
  String get powertrainProbeConnectToTryOnce => 'Connect to try one read first';

  @override
  String get powertrainProbeInProgress => 'Reading once…';

  @override
  String get powertrainProbeTryOnceFirst => 'Try one read first';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Turn on the laboratory in Settings first';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Connect for a one-shot read-only query';

  @override
  String get powertrainProbePickOneRead => 'Pick one command, read once';

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Research only — never queries';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Not installable in this release';

  @override
  String get powertrainInstallDialogTitle =>
      'Install this model\'s battery signals';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Primary source: $name ($license)';
  }

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Independent corroboration: $name ($license)';
  }

  @override
  String get powertrainVehicleYearLabel => 'Model year';

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Model year: $year';
  }

  @override
  String get powertrainInstallIdentityAck =>
      'My vehicle matches the market, model and model year above';

  @override
  String get powertrainCancel => 'Cancel';

  @override
  String get powertrainInstallConfirm => 'Install';

  @override
  String get powertrainInstallDisclosureReady =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The source data is fuller; it is still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The data comes from community sources and has been independently corroborated; it is still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This is an experimental decode with no independent-corroboration requirement, unverified on this vehicle, and still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This entry is for research only and should not be installed.';

  @override
  String get powertrainChooseCommandTitle =>
      'Choose one pinned read-only query';

  @override
  String get powertrainChooseCommandNote =>
      'One command per attempt: no scan, no batch, no automatic retry.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'One-shot experimental read-only confirmation';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Accepts RX $responder only, payload length $bytes bytes';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'Source file SHA-256: $hash…';
  }

  @override
  String get powertrainExperimentalDataDisclosure =>
      'This is a candidate read labelled by the source\'s authors, not a manufacturer or cross-model safety guarantee; ELM327 only forwards the command. The raw command and reply stay in the local diagnostic transcript and are not uploaded automatically by this feature; decoded values are never installed as a PID or added to a gauge. Cancelling does not affect ordinary OBD functions.';

  @override
  String get powertrainExperimentalIdentityAck =>
      'I have checked the market, model and model year the source knows, and I accept the unconfirmed fields';

  @override
  String get powertrainExperimentalParkedAck =>
      'The vehicle is safely parked; I understand this reads once and the number may still not apply';

  @override
  String get powertrainProbeOnceButton => 'Read once only';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Source identity evidence: $fields\nUnconfirmed fields: $unconfirmed';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Market';

  @override
  String get powertrainFieldModelYear => 'Model year';

  @override
  String get powertrainFieldModel => 'Model';

  @override
  String get powertrainFieldVariant => 'Variant';

  @override
  String get powertrainIdentityEvidenceExact => 'direct evidence';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'partial evidence';

  @override
  String get powertrainIdentityEvidenceUnknown => 'unknown';

  @override
  String get powertrainIdentityEvidenceNone => 'none';

  @override
  String get powertrainProbePassedTitle => 'One-shot query passed';

  @override
  String get powertrainProbeRefusedTitle => 'One-shot query refused';

  @override
  String get powertrainProbeChecksPassed =>
      'Passed the responder, echo, exact length, formula and range checks.';

  @override
  String get powertrainProbeNoValuePublished =>
      'No value was published; a structural or decode error is quarantined until you reconnect.';

  @override
  String get powertrainClose => 'Close';

  @override
  String get powertrainEnableLabInSettings =>
      'Turn on the experimental battery laboratory in Settings first.';

  @override
  String get powertrainConnectFirst =>
      'Connect first; experimental authorization is never kept across connections.';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return 'Quarantined for this connection: $reason';
  }

  @override
  String powertrainNotAuthorized(String reason) {
    return 'Not authorized: $reason';
  }

  @override
  String get powertrainProbeDidNotFinish =>
      'The one-shot query did not finish; no value was published or kept.';

  @override
  String get powertrainCatalogNotVerified =>
      'The catalog has not passed verification, so nothing can be installed.';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'A storage error happened while restoring earlier installs. It has been rescheduled — try again.';

  @override
  String powertrainInstallFailed(String reason) {
    return 'Cannot install: $reason';
  }

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Installed $count signals. Add them to the dashboard from the PID page; every connection needs a vehicle confirmation.',
      one: 'Installed 1 signal. Add it to the dashboard from the PID page; every connection needs a vehicle confirmation.',
    );
    return '$_temp0';
  }

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Removed the installed signals for $name.';
  }
}
