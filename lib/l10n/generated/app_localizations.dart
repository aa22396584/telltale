import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App name shown in window titles and the connect header.
  ///
  /// In en, this message translates to:
  /// **'Telltale'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Live vehicle telemetry'**
  String get appTagline;

  /// Bilingual label for the language picker. Options use self-names.
  ///
  /// In en, this message translates to:
  /// **'Language / 語言'**
  String get languageSectionTitle;

  /// No description provided for @connectHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a connection'**
  String get connectHeadline;

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'Plug in an ELM327 adapter and switch the ignition on, or use the built-in simulator.'**
  String get connectBody;

  /// No description provided for @settingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeadline;

  /// No description provided for @startupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking local share cache and telemetry records'**
  String get startupChecking;

  /// Retryable startup failure title. Distinct from startupChecking (in-progress) and startupRestartRequired (must quit).
  ///
  /// In en, this message translates to:
  /// **'Cannot finish startup checks'**
  String get startupCannotComplete;

  /// No description provided for @startupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get startupRetry;

  /// No description provided for @startupRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart required to continue safely'**
  String get startupRestartRequired;

  /// No description provided for @startupRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Keep Telltale in the foreground, then retry after other file work finishes. Recording, replay, export and delete stay closed until startup completes.'**
  String get startupRetryHint;

  /// No description provided for @startupRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.'**
  String get startupRestartHint;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Try again.'**
  String get languageSaveFailed;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// A live reading that has stopped updating. Not an error and not a fresh value.
  ///
  /// In en, this message translates to:
  /// **'Data is stale'**
  String get telemetryStatusStale;

  /// Distinct from no answer: the ECU replied, and the reply said unsupported.
  ///
  /// In en, this message translates to:
  /// **'The controller answered that it does not support this'**
  String get telemetryStatusUnsupported;

  /// Silence, not a refusal. Must never read as unsupported.
  ///
  /// In en, this message translates to:
  /// **'No answer — will retry'**
  String get telemetryStatusNoAnswer;

  /// No description provided for @telemetryStatusFormulaError.
  ///
  /// In en, this message translates to:
  /// **'Formula error'**
  String get telemetryStatusFormulaError;

  /// No description provided for @telemetryStatusBusError.
  ///
  /// In en, this message translates to:
  /// **'Bus error'**
  String get telemetryStatusBusError;

  /// No description provided for @telemetryStatusHeaderMismatch.
  ///
  /// In en, this message translates to:
  /// **'Header does not match this bus'**
  String get telemetryStatusHeaderMismatch;

  /// The app refused to transmit. Says what did NOT happen.
  ///
  /// In en, this message translates to:
  /// **'Not a read-only query — nothing was sent'**
  String get telemetryStatusUnsafeServiceRefusal;

  /// No description provided for @telemetryEndedByUser.
  ///
  /// In en, this message translates to:
  /// **'Stopped by you'**
  String get telemetryEndedByUser;

  /// No description provided for @telemetryEndedByDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Stopped when the connection dropped'**
  String get telemetryEndedByDisconnect;

  /// No description provided for @telemetryEndedBySessionReplacement.
  ///
  /// In en, this message translates to:
  /// **'The connection session was replaced'**
  String get telemetryEndedBySessionReplacement;

  /// No description provided for @telemetryEndedByBackground.
  ///
  /// In en, this message translates to:
  /// **'Stopped when Telltale went to the background'**
  String get telemetryEndedByBackground;

  /// {minutes} comes from telemetryRecorderDurationLimit; never spell the number in the copy.
  ///
  /// In en, this message translates to:
  /// **'Reached the {minutes}-minute limit'**
  String telemetryEndedByDurationLimit(int minutes);

  /// No description provided for @telemetryEndedBySessionSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'This recording reached its size limit'**
  String get telemetryEndedBySessionSizeLimit;

  /// No description provided for @telemetryEndedByLibrarySizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recording storage is full'**
  String get telemetryEndedByLibrarySizeLimit;

  /// No description provided for @telemetryEndedByStorageBackpressure.
  ///
  /// In en, this message translates to:
  /// **'Storage could not keep up'**
  String get telemetryEndedByStorageBackpressure;

  /// No description provided for @telemetryEndedByConfigurationChanged.
  ///
  /// In en, this message translates to:
  /// **'The PID selection changed'**
  String get telemetryEndedByConfigurationChanged;

  /// No description provided for @telemetryEndedByStorageFailure.
  ///
  /// In en, this message translates to:
  /// **'Saving failed'**
  String get telemetryEndedByStorageFailure;

  /// No description provided for @telemetryEndedByRecoveredAfterInterruption.
  ///
  /// In en, this message translates to:
  /// **'Recovered after the last interruption'**
  String get telemetryEndedByRecoveredAfterInterruption;

  /// No description provided for @telemetryStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get telemetryStartRecording;

  /// No description provided for @telemetryStartNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect before starting a recording'**
  String get telemetryStartNeedsConnection;

  /// No description provided for @telemetryStartNeedsForeground.
  ///
  /// In en, this message translates to:
  /// **'Bring Telltale to the foreground before starting a recording'**
  String get telemetryStartNeedsForeground;

  /// Refuses on unknown speed. Absence of a speed reading is not evidence of a parked car.
  ///
  /// In en, this message translates to:
  /// **'Cannot confirm the vehicle is stopped — disconnect first'**
  String get telemetryStartSpeedUnknown;

  /// No description provided for @telemetryStartMoving.
  ///
  /// In en, this message translates to:
  /// **'Park the vehicle first'**
  String get telemetryStartMoving;

  /// No description provided for @telemetryStartInvalidatedBackground.
  ///
  /// In en, this message translates to:
  /// **'Telltale went to the background — no recording started'**
  String get telemetryStartInvalidatedBackground;

  /// No description provided for @telemetryStartInvalidatedDisconnect.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped — no recording started'**
  String get telemetryStartInvalidatedDisconnect;

  /// No description provided for @telemetryStartInvalidatedSessionReplacement.
  ///
  /// In en, this message translates to:
  /// **'The connection session was replaced — no recording started'**
  String get telemetryStartInvalidatedSessionReplacement;

  /// {limit} comes from TelemetryQuota.groupLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recordings reached the limit of {limit} — export or delete some first'**
  String telemetryStartLibraryGroupLimit(int limit);

  /// No description provided for @telemetryStartLibraryByteLimit.
  ///
  /// In en, this message translates to:
  /// **'Not enough local storage for a recording — export or delete some first'**
  String get telemetryStartLibraryByteLimit;

  /// No description provided for @telemetryStartInvalidConfiguration.
  ///
  /// In en, this message translates to:
  /// **'This PID selection cannot be recorded safely — check the definitions'**
  String get telemetryStartInvalidConfiguration;

  /// No description provided for @telemetryStartCannotCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Could not create the recording file'**
  String get telemetryStartCannotCreateFile;

  /// No description provided for @telemetryStartBusy.
  ///
  /// In en, this message translates to:
  /// **'Another recording or file operation has not finished'**
  String get telemetryStartBusy;

  /// Also the startOutcome for restartRequired; one sentence, one key.
  ///
  /// In en, this message translates to:
  /// **'Startup cleanup did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairStartup;

  /// No description provided for @telemetryRestartToRepairSave.
  ///
  /// In en, this message translates to:
  /// **'Saving did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairSave;

  /// No description provided for @telemetryPendingOwnerRecovery.
  ///
  /// In en, this message translates to:
  /// **'This process still holds the operation. If it stays here, quit Telltale completely and reopen it'**
  String get telemetryPendingOwnerRecovery;

  /// No description provided for @telemetryStartNeedsActivePid.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one PID first'**
  String get telemetryStartNeedsActivePid;

  /// Refers to DerivedEstimates.maxLiveSignals. 'estimated' must never read as 'measured'.
  ///
  /// In en, this message translates to:
  /// **'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first'**
  String get telemetryStartTooManyPids;

  /// No description provided for @telemetryBlockedByRecorder.
  ///
  /// In en, this message translates to:
  /// **'Stop and save the recording first'**
  String get telemetryBlockedByRecorder;

  /// No description provided for @telemetryDeleteNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm this delete first'**
  String get telemetryDeleteNeedsConfirmation;

  /// No description provided for @telemetryArtifactRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing'**
  String get telemetryArtifactRestartRequired;

  /// Settings section heading above the current-connection panel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionSection;

  /// No description provided for @settingsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// No description provided for @settingsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// Button that leaves Settings for the Connect screen.
  ///
  /// In en, this message translates to:
  /// **'Go to Connect'**
  String get settingsGoToConnect;

  /// No description provided for @settingsVehicleProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle profile'**
  String get settingsVehicleProfileSection;

  /// 'estimated' is load-bearing: these numbers are never measured.
  ///
  /// In en, this message translates to:
  /// **'Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.'**
  String get settingsProfileEstimatesIntro;

  /// VE stays VE in both languages.
  ///
  /// In en, this message translates to:
  /// **'A brand name or a VIN alone does not establish mass, drag, VE or transmission efficiency.'**
  String get settingsProfileNameProvesNothing;

  /// No description provided for @settingsCatalogVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying the offline catalog…'**
  String get settingsCatalogVerifying;

  /// No description provided for @settingsCatalogChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from the official catalog'**
  String get settingsCatalogChoose;

  /// Scopes the catalog. Must not read as global coverage.
  ///
  /// In en, this message translates to:
  /// **'The bundled snapshot is the official U.S. EPA Find-a-Car data; it covers only that market and the configurations inside the snapshot, not every brand or model year worldwide.'**
  String get settingsCatalogScope;

  /// Says what did NOT happen: no partial application.
  ///
  /// In en, this message translates to:
  /// **'The official offline catalog is damaged or could not be loaded; nothing was applied.'**
  String get settingsCatalogCorrupt;

  /// No description provided for @settingsCatalogNothingApplicable.
  ///
  /// In en, this message translates to:
  /// **'This official configuration has no field that can be applied safely to the current formulas; the existing profile is unchanged.'**
  String get settingsCatalogNothingApplicable;

  /// No description provided for @settingsFieldDisplacement.
  ///
  /// In en, this message translates to:
  /// **'Displacement'**
  String get settingsFieldDisplacement;

  /// No description provided for @settingsFieldMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get settingsFieldMass;

  /// No description provided for @settingsFieldMassWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Mass (with driver)'**
  String get settingsFieldMassWithDriver;

  /// VE is a symbol, not a word; it stays VE in both languages.
  ///
  /// In en, this message translates to:
  /// **'Volumetric efficiency VE'**
  String get settingsFieldVolumetricEfficiency;

  /// Cd is a symbol, not a word; it stays Cd in both languages.
  ///
  /// In en, this message translates to:
  /// **'Drag coefficient Cd'**
  String get settingsFieldDragCoefficient;

  /// No description provided for @settingsFieldFrontalArea.
  ///
  /// In en, this message translates to:
  /// **'Frontal area'**
  String get settingsFieldFrontalArea;

  /// Crr is a symbol, not a word; it stays Crr in both languages.
  ///
  /// In en, this message translates to:
  /// **'Rolling resistance Crr'**
  String get settingsFieldRollingResistance;

  /// No description provided for @settingsFieldFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get settingsFieldFuel;

  /// No description provided for @settingsFieldDrivetrain.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get settingsFieldDrivetrain;

  /// No description provided for @settingsFuelAndDrivetrainSection.
  ///
  /// In en, this message translates to:
  /// **'Fuel and drivetrain'**
  String get settingsFuelAndDrivetrainSection;

  /// No description provided for @settingsFuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get settingsFuelTypeLabel;

  /// Both values come from the selected FuelType. Units never change with language.
  ///
  /// In en, this message translates to:
  /// **'Air-fuel ratio {afr} · density {density} g/L'**
  String settingsFuelAfrAndDensity(double afr, int density);

  /// {percent} comes from Drivetrain.efficiency; never spell it into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Transmission efficiency {percent} %'**
  String settingsDrivetrainEfficiency(int percent);

  /// No description provided for @settingsProfileConfirmedButton.
  ///
  /// In en, this message translates to:
  /// **'Confirmed for this connection'**
  String get settingsProfileConfirmedButton;

  /// No description provided for @settingsProfileConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm this vehicle for this connection'**
  String get settingsProfileConfirmButton;

  /// No description provided for @settingsProfileConfirmAfterConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to confirm this vehicle'**
  String get settingsProfileConfirmAfterConnect;

  /// No description provided for @settingsDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic transcript'**
  String get settingsDiagnosticsSection;

  /// No description provided for @settingsManualCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual command'**
  String get settingsManualCommandTitle;

  /// ATI, ATDPN and 0100 are wire commands and must stay byte-identical.
  ///
  /// In en, this message translates to:
  /// **'Send one command straight to the adapter — for example ATI, ATDPN, 0100. It joins the same queue as normal polling and does not jump ahead.'**
  String get settingsManualCommandBody;

  /// No description provided for @settingsManualCommandFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get settingsManualCommandFieldLabel;

  /// No description provided for @settingsManualCommandSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get settingsManualCommandSend;

  /// The adapter answered, and the answer was empty. Not an error, and not a reading.
  ///
  /// In en, this message translates to:
  /// **'(no response content)'**
  String get settingsManualCommandNoContent;

  /// No description provided for @settingsExperimentalSection.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get settingsExperimentalSection;

  /// No description provided for @settingsBatteryLabSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery laboratory (experimental)'**
  String get settingsBatteryLabSwitchTitle;

  /// The switch reveals the laboratory; it never trusts a vehicle. 'Only reveals' is load-bearing.
  ///
  /// In en, this message translates to:
  /// **'Only reveals one-shot read-only queries whose sources are complete and hash-bound. It does not install PIDs, poll, add gauges, or treat research data as support.'**
  String get settingsBatteryLabSwitchSubtitle;

  /// No description provided for @settingsBatteryLabDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on the battery laboratory'**
  String get settingsBatteryLabDialogTitle;

  /// A safety boundary. Three claims must survive translation: reverse-engineered candidates rather than manufacturer documentation; a read-only query can still wake a controller; a decoded number can look plausible and not apply.
  ///
  /// In en, this message translates to:
  /// **'These are reverse-engineered candidate sources, not manufacturer documentation, and not Telltale support for your vehicle. Even a read-only query can wake a controller; a decoded number may look plausible and still not apply.'**
  String get settingsBatteryLabDialogBody;

  /// No description provided for @settingsBatteryLabEvidenceAck.
  ///
  /// In en, this message translates to:
  /// **'I understand that the source data and the synthetic tests do not prove this applies to my own vehicle'**
  String get settingsBatteryLabEvidenceAck;

  /// States exactly what consent does and does not unlock. Mode 21/22 stay byte-identical. The five refusals are enumerated on purpose.
  ///
  /// In en, this message translates to:
  /// **'I understand this unlocks only one-shot queries at fixed Mode 21/22 addresses from the catalog — not scanning, not a diagnostic session, not security access, not writing, not control'**
  String get settingsBatteryLabWireAck;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsBatteryLabUnlockReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unlock one-shot read-only queries only'**
  String get settingsBatteryLabUnlockReadOnly;

  /// No description provided for @settingsBatteryLabEnableNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Could not save the battery laboratory setting; it stays off.'**
  String get settingsBatteryLabEnableNotSaved;

  /// Off now, possibly back next launch, and per-query consent is unaffected. All three halves are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'The battery laboratory is off for this run, but the setting could not be saved; the next launch may show the laboratory again, and every query still needs its own confirmation.'**
  String get settingsBatteryLabDisableNotSaved;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsThemeSystem;

  /// No description provided for @settingsGaugeSkinTitle.
  ///
  /// In en, this message translates to:
  /// **'Gauge style'**
  String get settingsGaugeSkinTitle;

  /// No description provided for @settingsGaugeSkinBody.
  ///
  /// In en, this message translates to:
  /// **'Not just a colour change — each one has a different dial face, needle and motion. All of them work on dark and light backgrounds.'**
  String get settingsGaugeSkinBody;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source and data licences'**
  String get settingsOpenSourceLicenses;

  /// applicationLegalese on the bundled licence page.
  ///
  /// In en, this message translates to:
  /// **'Powertrain battery sources, transformations, and reuse terms are bundled with this app.'**
  String get settingsLicenseLegalese;

  /// SAE J1979, ELM327, the file name and the Torque product names stay byte-identical.
  ///
  /// In en, this message translates to:
  /// **'This app\'s OBD2 implementation follows public standards including SAE J1979 and the ELM327 datasheet; every formula and AT command that affects hardware behaviour is cross-verified, and the results are recorded in docs/protocol-deviations.zh-TW.md. This app is not affiliated with Torque or Torque Pro.'**
  String get settingsStandardsFooter;

  /// No description provided for @settingsEpaPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Official U.S. EPA vehicle catalog'**
  String get settingsEpaPickerTitle;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// Both years come from the loaded catalog, never from the prose.
  ///
  /// In en, this message translates to:
  /// **'U.S.-market snapshot configurations for {firstYear}–{lastYear} only. Models that share a name still need the model year, transmission, fuel and EPA ID to tell them apart.'**
  String settingsEpaPickerScope(int firstYear, int lastYear);

  /// No description provided for @settingsEpaYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get settingsEpaYear;

  /// EPA 'make' is a manufacturer division, not a brand; both languages keep the EPA qualifier.
  ///
  /// In en, this message translates to:
  /// **'EPA make'**
  String get settingsEpaMake;

  /// No description provided for @settingsEpaModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsEpaModel;

  /// No description provided for @settingsEpaPickInOrder.
  ///
  /// In en, this message translates to:
  /// **'Choose model year, make and model in order'**
  String get settingsEpaPickInOrder;

  /// No description provided for @settingsEpaNoConfigurations.
  ///
  /// In en, this message translates to:
  /// **'No configurations available for this model'**
  String get settingsEpaNoConfigurations;

  /// No description provided for @settingsEpaFuelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Fuel unknown'**
  String get settingsEpaFuelUnknown;

  /// No description provided for @settingsEpaDriveUnknown.
  ///
  /// In en, this message translates to:
  /// **'Drive unknown'**
  String get settingsEpaDriveUnknown;

  /// No description provided for @settingsEpaNoSafeFields.
  ///
  /// In en, this message translates to:
  /// **'This configuration has no field that can be applied safely to the current formulas; nothing is guessed.'**
  String get settingsEpaNoSafeFields;

  /// Names what is NOT applied. VE, Cd and Crr stay as symbols.
  ///
  /// In en, this message translates to:
  /// **'Only {fields} will be applied. Mass, VE, Cd, frontal area, Crr and transmission efficiency stay unresolved.'**
  String settingsEpaWillApplyOnly(String fields);

  /// No description provided for @settingsEpaChooseExact.
  ///
  /// In en, this message translates to:
  /// **'Choose an exact configuration'**
  String get settingsEpaChooseExact;

  /// No description provided for @settingsEpaCloseNoFields.
  ///
  /// In en, this message translates to:
  /// **'Close (no fields to apply)'**
  String get settingsEpaCloseNoFields;

  /// {count} is the number of fields that survived verification.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} official fields'**
  String settingsEpaApplyFields(int count);

  /// No description provided for @settingsEpaCylinders.
  ///
  /// In en, this message translates to:
  /// **'{count} cyl'**
  String settingsEpaCylinders(int count);

  /// Fallback title when a configuration lists no displacement, cylinder count or transmission. The EPA ID is data.
  ///
  /// In en, this message translates to:
  /// **'EPA configuration {epaId}'**
  String settingsEpaConfiguration(int epaId);

  /// Every count is derived from the profile's own field map. The five states are distinct and must not be merged.
  ///
  /// In en, this message translates to:
  /// **'Resolution: official exact {exact} / {total} fields · confirmed this session {sessionConfirmed} / {total} · unresolved {unresolved} / {total} · ambiguous {ambiguous} / {total} · conflicting {conflict} / {total}'**
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  );

  /// Counts by VehicleFieldOrigin. A generic default is not a measurement.
  ///
  /// In en, this message translates to:
  /// **'Provenance: official or manufacturer {official} / {total} fields · user entered {user} / {total} · generic default {generic} / {total} · scientific model {scientific} / {total}'**
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  );

  /// No description provided for @settingsProvenanceNoneExact.
  ///
  /// In en, this message translates to:
  /// **'No field has been resolved exactly to this vehicle; generic, hand-entered and older source values all still need confirming.'**
  String get settingsProvenanceNoneExact;

  /// The enumeration is the claim: only these fields are exact.
  ///
  /// In en, this message translates to:
  /// **'Fields with an exact official source: {fields}. Every other field still needs confirming one by one.'**
  String settingsProvenanceOnlyExact(String fields);

  /// Publisher names are data and pass through untranslated.
  ///
  /// In en, this message translates to:
  /// **'Sources: {publishers}'**
  String settingsProvenancePublishers(String publishers);

  /// Joins the label lists this screen builds at runtime. Chinese uses the enumeration comma; English uses a comma and a space.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get settingsListSeparator;

  /// Not read is not unavailable. Must stay distinct from settingsVinUnavailable.
  ///
  /// In en, this message translates to:
  /// **'VIN not read yet'**
  String get settingsVinNotRead;

  /// The privacy half — the transcript may still hold the VIN — must survive.
  ///
  /// In en, this message translates to:
  /// **'Mode 09 VIN can be read from the vehicle now; the identity is kept only for this connection. The raw diagnostic transcript may still contain the VIN.'**
  String get settingsVinNotReadConnectedDetail;

  /// No description provided for @settingsVinNotReadDisconnectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Once connected, the VIN the vehicle reports about itself can be read; the identity does not carry into the next connection. The raw diagnostic transcript may still contain the VIN.'**
  String get settingsVinNotReadDisconnectedDetail;

  /// Must not read as a vehicle-reported VIN.
  ///
  /// In en, this message translates to:
  /// **'Simulator-reported VIN'**
  String get settingsVinSimulatorReported;

  /// No description provided for @settingsVinVehicleReported.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-reported VIN'**
  String get settingsVinVehicleReported;

  /// Self-reported is not verified. Never let this read as a confirmed profile.
  ///
  /// In en, this message translates to:
  /// **'A VIN is what the vehicle reports about itself; it does not verify the model\'s specifications. The identity does not cross connections; the diagnostic transcript may still contain the VIN.'**
  String get settingsVinReportedDetail;

  /// No description provided for @settingsVinUnavailable.
  ///
  /// In en, this message translates to:
  /// **'VIN unavailable'**
  String get settingsVinUnavailable;

  /// Three innocent explanations plus the refusal to guess. Do not compress.
  ///
  /// In en, this message translates to:
  /// **'The vehicle may not offer one, the reply may have been incomplete, or it was not read on this connection; nothing is guessed and no characters are filled in.'**
  String get settingsVinUnavailableDetail;

  /// No description provided for @settingsVinConflict.
  ///
  /// In en, this message translates to:
  /// **'VIN conflict'**
  String get settingsVinConflict;

  /// Discarded, not 'one was picked'.
  ///
  /// In en, this message translates to:
  /// **'Controllers reported different VINs, so the vehicle identity cannot be confirmed; every candidate was discarded.'**
  String get settingsVinConflictDetail;

  /// No description provided for @settingsVinReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get settingsVinReading;

  /// No description provided for @settingsVinRead.
  ///
  /// In en, this message translates to:
  /// **'Read VIN'**
  String get settingsVinRead;

  /// No description provided for @settingsProfileConfirmedDetail.
  ///
  /// In en, this message translates to:
  /// **'The profile is confirmed for this connection. Changing any value, or reconnecting, means confirming again.'**
  String get settingsProfileConfirmedDetail;

  /// Measured and estimated are two different things and must stay two different words.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed on this connection. Measured OBD readings are still shown, but values estimated from mass, VE and drag are not.'**
  String get settingsProfileUnconfirmedConnectedDetail;

  /// No description provided for @settingsProfileUnconfirmedDisconnectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Connect to this vehicle before confirming. Confirmation expires on every reconnect, so one car\'s profile is never applied to the next.'**
  String get settingsProfileUnconfirmedDisconnectedDetail;

  /// No description provided for @settingsAdapterSelfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'What the adapter says about itself'**
  String get settingsAdapterSelfReportTitle;

  /// No description provided for @settingsAdapterNoVersion.
  ///
  /// In en, this message translates to:
  /// **'(no version reported)'**
  String get settingsAdapterNoVersion;

  /// Consistency is not a clean bill of health. Both negations are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'No self-description contradictions found. That only means it is consistent about itself — it is not evidence that the chip is genuine, and not evidence that the numbers it reports are correct. On a clone, the version string is just text somebody chose.'**
  String get settingsAdapterNoContradictions;

  /// Distinguishes a self-description mismatch from a wrong reading.
  ///
  /// In en, this message translates to:
  /// **'These are places where the adapter\'s account of itself does not add up, not evidence that it misread the car. The only way to confirm a value is a second independent measurement (see the field guide).'**
  String get settingsAdapterConcernsFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
