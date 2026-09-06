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

  /// Performance screen title. The screen times a run; it never states a vehicle's rated performance.
  ///
  /// In en, this message translates to:
  /// **'Acceleration test'**
  String get performanceHeadline;

  /// Says what the number is: one timed run beginning at rest. Not a manufacturer figure, not a rating.
  ///
  /// In en, this message translates to:
  /// **'A timed run from a standing start to a target speed'**
  String get performanceSubhead;

  /// No description provided for @performanceNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get performanceNotConnectedTitle;

  /// No description provided for @performanceNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'The acceleration test needs live road speed. Connect an adapter, or start the built-in simulator.'**
  String get performanceNotConnectedBody;

  /// No description provided for @performanceSpeedGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get performanceSpeedGaugeLabel;

  /// No description provided for @performanceStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Pick a target speed, then start'**
  String get performanceStateIdle;

  /// {speed} is the live road speed, already formatted by the caller. Units never change with language.
  ///
  /// In en, this message translates to:
  /// **'Come to a complete stop first — now {speed} km/h'**
  String performanceStateAwaitingStandstill(String speed);

  /// No speed reading at all. Distinct from a reading that says the car is moving — the app cannot tell yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a speed signal'**
  String get performanceStateAwaitingSpeedSignal;

  /// No description provided for @performanceStateStaged.
  ///
  /// In en, this message translates to:
  /// **'Ready — the clock starts when you move off'**
  String get performanceStateStaged;

  /// No description provided for @performanceStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get performanceStateRunning;

  /// {target} is the selected target speed from the screen's own list, never spelled into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Finished 0 → {target} km/h'**
  String performanceStateFinished(int target);

  /// An incomplete run whose partial evidence is kept. Must never read as a finished time.
  ///
  /// In en, this message translates to:
  /// **'The speed signal stopped — this run was not completed; below is what was recorded before it went'**
  String get performanceStateAborted;

  /// No description provided for @performanceSecondsUnit.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get performanceSecondsUnit;

  /// No description provided for @performanceTargetSpeedHeading.
  ///
  /// In en, this message translates to:
  /// **'Target speed'**
  String get performanceTargetSpeedHeading;

  /// No description provided for @performanceSpeedTraceHeading.
  ///
  /// In en, this message translates to:
  /// **'Speed trace'**
  String get performanceSpeedTraceHeading;

  /// No description provided for @performanceSplitsHeading.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get performanceSplitsHeading;

  /// No description provided for @performancePeakSpeed.
  ///
  /// In en, this message translates to:
  /// **'Peak speed'**
  String get performancePeakSpeed;

  /// No description provided for @performanceArm.
  ///
  /// In en, this message translates to:
  /// **'Arm the timer'**
  String get performanceArm;

  /// No description provided for @performanceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get performanceReset;

  /// PID 010D is an adapter-facing token and stays byte-identical in every language.
  ///
  /// In en, this message translates to:
  /// **'There is no valid road-speed signal right now (PID 010D). The acceleration test cannot time a run without it.'**
  String get performanceNoSpeedSignal;

  /// Load-bearing hedge. Both halves must survive translation: indicative only, AND not equivalent to professional test equipment. The ranges describe vehicles and adapters, not a constant this app enforces, so they stay in the prose.
  ///
  /// In en, this message translates to:
  /// **'Times come from the OBD road-speed signal. Most vehicles read 1–3 km/h high on their own speedometer, and the signal updates only about 10–20 times a second, so a result here is indicative only — not equivalent to professional test equipment.'**
  String get performanceDisclaimer;

  /// Wear connect button for the built-in simulator. Kept short for a 454px round face.
  ///
  /// In en, this message translates to:
  /// **'Demo simulator'**
  String get wearDemoSimulator;

  /// No description provided for @wearBleAdapters.
  ///
  /// In en, this message translates to:
  /// **'BLE adapters'**
  String get wearBleAdapters;

  /// No description provided for @wearConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get wearConnecting;

  /// No description provided for @wearScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get wearScanning;

  /// Nothing answered the scan. Not a claim that no adapter exists.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get wearNoDevicesFound;

  /// No description provided for @wearBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wearBack;

  /// Shares a row with wearBack on a 227dp-wide watch face; keep it to one short word.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get wearScanAgain;

  /// No description provided for @wearScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed — try again'**
  String get wearScanFailed;

  /// {adapter} is the device name the adapter advertised, or its id when the name is empty. Passed through, never translated.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {adapter}'**
  String wearConnectFailed(String adapter);

  /// No description provided for @wearPermissionBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get wearPermissionBluetooth;

  /// No description provided for @wearPermissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wearPermissionLocation;

  /// {permission} is wearPermissionBluetooth or wearPermissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Scanning needs {permission} permission'**
  String wearScanPermissionNeeded(String permission);

  /// A refusal the app cannot re-ask for. States the only remedy.
  ///
  /// In en, this message translates to:
  /// **'{permission} permission is permanently denied — turn it on in system settings, then try again'**
  String wearScanPermissionPermanentlyDenied(String permission);

  /// No description provided for @wearCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wearCancel;

  /// No description provided for @wearDisconnectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Disconnect?'**
  String get wearDisconnectQuestion;

  /// No description provided for @wearDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get wearDisconnect;

  /// No description provided for @wearConfirmVehicle.
  ///
  /// In en, this message translates to:
  /// **'Confirm vehicle'**
  String get wearConfirmVehicle;

  /// Affirms the identity shown above it. Must stay short enough for a watch dialog action.
  ///
  /// In en, this message translates to:
  /// **'Yes, this car'**
  String get wearConfirmVehicleAccept;

  /// Load-bearing: read-only, and the plausible-but-wrong-number warning. Neither may be dropped for length.
  ///
  /// In en, this message translates to:
  /// **'Once confirmed, the read-only battery queries for this model are polled for the rest of this connection. The wrong model can return a plausible but wrong number — cancel if you are not sure.'**
  String get wearConfirmVehicleBody;

  /// The 12V battery reading on the watch numbers grid. Not the powertrain battery, which has its own page.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get wearBatteryVoltageLabel;
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
