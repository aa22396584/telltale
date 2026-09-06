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
  String get settingsConnectionSection => 'Connection';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String get settingsGoToConnect => 'Go to Connect';

  @override
  String get settingsVehicleProfileSection => 'Vehicle profile';

  @override
  String get settingsProfileEstimatesIntro =>
      'Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.';

  @override
  String get settingsProfileNameProvesNothing =>
      'A brand name or a VIN alone does not establish mass, drag, VE or transmission efficiency.';

  @override
  String get settingsCatalogVerifying => 'Verifying the offline catalog…';

  @override
  String get settingsCatalogChoose => 'Choose from the official catalog';

  @override
  String get settingsCatalogScope =>
      'The bundled snapshot is the official U.S. EPA Find-a-Car data; it covers only that market and the configurations inside the snapshot, not every brand or model year worldwide.';

  @override
  String get settingsCatalogCorrupt =>
      'The official offline catalog is damaged or could not be loaded; nothing was applied.';

  @override
  String get settingsCatalogNothingApplicable =>
      'This official configuration has no field that can be applied safely to the current formulas; the existing profile is unchanged.';

  @override
  String get settingsFieldDisplacement => 'Displacement';

  @override
  String get settingsFieldMass => 'Mass';

  @override
  String get settingsFieldMassWithDriver => 'Mass (with driver)';

  @override
  String get settingsFieldVolumetricEfficiency => 'Volumetric efficiency VE';

  @override
  String get settingsFieldDragCoefficient => 'Drag coefficient Cd';

  @override
  String get settingsFieldFrontalArea => 'Frontal area';

  @override
  String get settingsFieldRollingResistance => 'Rolling resistance Crr';

  @override
  String get settingsFieldFuel => 'Fuel';

  @override
  String get settingsFieldDrivetrain => 'Drivetrain';

  @override
  String get settingsFuelAndDrivetrainSection => 'Fuel and drivetrain';

  @override
  String get settingsFuelTypeLabel => 'Fuel type';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Air-fuel ratio $afr · density $density g/L';
  }

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Transmission efficiency $percent %';
  }

  @override
  String get settingsProfileConfirmedButton => 'Confirmed for this connection';

  @override
  String get settingsProfileConfirmButton =>
      'Confirm this vehicle for this connection';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Connect to confirm this vehicle';

  @override
  String get settingsDiagnosticsSection => 'Diagnostic transcript';

  @override
  String get settingsManualCommandTitle => 'Manual command';

  @override
  String get settingsManualCommandBody =>
      'Send one command straight to the adapter — for example ATI, ATDPN, 0100. It joins the same queue as normal polling and does not jump ahead.';

  @override
  String get settingsManualCommandFieldLabel => 'Command';

  @override
  String get settingsManualCommandSend => 'Send';

  @override
  String get settingsManualCommandNoContent => '(no response content)';

  @override
  String get settingsExperimentalSection => 'Experimental';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Battery laboratory (experimental)';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Only reveals one-shot read-only queries whose sources are complete and hash-bound. It does not install PIDs, poll, add gauges, or treat research data as support.';

  @override
  String get settingsBatteryLabDialogTitle => 'Turn on the battery laboratory';

  @override
  String get settingsBatteryLabDialogBody =>
      'These are reverse-engineered candidate sources, not manufacturer documentation, and not Telltale support for your vehicle. Even a read-only query can wake a controller; a decoded number may look plausible and still not apply.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'I understand that the source data and the synthetic tests do not prove this applies to my own vehicle';

  @override
  String get settingsBatteryLabWireAck =>
      'I understand this unlocks only one-shot queries at fixed Mode 21/22 addresses from the catalog — not scanning, not a diagnostic session, not security access, not writing, not control';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Unlock one-shot read-only queries only';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Could not save the battery laboratory setting; it stays off.';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'The battery laboratory is off for this run, but the setting could not be saved; the next launch may show the laboratory again, and every query still needs its own confirmation.';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsGaugeSkinTitle => 'Gauge style';

  @override
  String get settingsGaugeSkinBody =>
      'Not just a colour change — each one has a different dial face, needle and motion. All of them work on dark and light backgrounds.';

  @override
  String get settingsOpenSourceLicenses => 'Open source and data licences';

  @override
  String get settingsLicenseLegalese =>
      'Powertrain battery sources, transformations, and reuse terms are bundled with this app.';

  @override
  String get settingsStandardsFooter =>
      'This app\'s OBD2 implementation follows public standards including SAE J1979 and the ELM327 datasheet; every formula and AT command that affects hardware behaviour is cross-verified, and the results are recorded in docs/protocol-deviations.zh-TW.md. This app is not affiliated with Torque or Torque Pro.';

  @override
  String get settingsEpaPickerTitle => 'Official U.S. EPA vehicle catalog';

  @override
  String get settingsClose => 'Close';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'U.S.-market snapshot configurations for $firstYear–$lastYear only. Models that share a name still need the model year, transmission, fuel and EPA ID to tell them apart.';
  }

  @override
  String get settingsEpaYear => 'Model year';

  @override
  String get settingsEpaMake => 'EPA make';

  @override
  String get settingsEpaModel => 'Model';

  @override
  String get settingsEpaPickInOrder =>
      'Choose model year, make and model in order';

  @override
  String get settingsEpaNoConfigurations =>
      'No configurations available for this model';

  @override
  String get settingsEpaFuelUnknown => 'Fuel unknown';

  @override
  String get settingsEpaDriveUnknown => 'Drive unknown';

  @override
  String get settingsEpaNoSafeFields =>
      'This configuration has no field that can be applied safely to the current formulas; nothing is guessed.';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Only $fields will be applied. Mass, VE, Cd, frontal area, Crr and transmission efficiency stay unresolved.';
  }

  @override
  String get settingsEpaChooseExact => 'Choose an exact configuration';

  @override
  String get settingsEpaCloseNoFields => 'Close (no fields to apply)';

  @override
  String settingsEpaApplyFields(int count) {
    return 'Apply $count official fields';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cyl';
  }

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA configuration $epaId';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return 'Resolution: official exact $exact / $total fields · confirmed this session $sessionConfirmed / $total · unresolved $unresolved / $total · ambiguous $ambiguous / $total · conflicting $conflict / $total';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Provenance: official or manufacturer $official / $total fields · user entered $user / $total · generic default $generic / $total · scientific model $scientific / $total';
  }

  @override
  String get settingsProvenanceNoneExact =>
      'No field has been resolved exactly to this vehicle; generic, hand-entered and older source values all still need confirming.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Fields with an exact official source: $fields. Every other field still needs confirming one by one.';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Sources: $publishers';
  }

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsVinNotRead => 'VIN not read yet';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Mode 09 VIN can be read from the vehicle now; the identity is kept only for this connection. The raw diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Once connected, the VIN the vehicle reports about itself can be read; the identity does not carry into the next connection. The raw diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinSimulatorReported => 'Simulator-reported VIN';

  @override
  String get settingsVinVehicleReported => 'Vehicle-reported VIN';

  @override
  String get settingsVinReportedDetail =>
      'A VIN is what the vehicle reports about itself; it does not verify the model\'s specifications. The identity does not cross connections; the diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinUnavailable => 'VIN unavailable';

  @override
  String get settingsVinUnavailableDetail =>
      'The vehicle may not offer one, the reply may have been incomplete, or it was not read on this connection; nothing is guessed and no characters are filled in.';

  @override
  String get settingsVinConflict => 'VIN conflict';

  @override
  String get settingsVinConflictDetail =>
      'Controllers reported different VINs, so the vehicle identity cannot be confirmed; every candidate was discarded.';

  @override
  String get settingsVinReading => 'Reading…';

  @override
  String get settingsVinRead => 'Read VIN';

  @override
  String get settingsProfileConfirmedDetail =>
      'The profile is confirmed for this connection. Changing any value, or reconnecting, means confirming again.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Not confirmed on this connection. Measured OBD readings are still shown, but values estimated from mass, VE and drag are not.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Connect to this vehicle before confirming. Confirmation expires on every reconnect, so one car\'s profile is never applied to the next.';

  @override
  String get settingsAdapterSelfReportTitle =>
      'What the adapter says about itself';

  @override
  String get settingsAdapterNoVersion => '(no version reported)';

  @override
  String get settingsAdapterNoContradictions =>
      'No self-description contradictions found. That only means it is consistent about itself — it is not evidence that the chip is genuine, and not evidence that the numbers it reports are correct. On a clone, the version string is just text somebody chose.';

  @override
  String get settingsAdapterConcernsFooter =>
      'These are places where the adapter\'s account of itself does not add up, not evidence that it misread the car. The only way to confirm a value is a second independent measurement (see the field guide).';
}
