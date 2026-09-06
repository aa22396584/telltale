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

  /// Bonded-adapter list. Names Bluetooth: listing a bonded adapter never asks for location, so location can not be the permission that was refused here.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is permanently denied. Turn it on in system settings, then try again.'**
  String get connectBluetoothPermissionDeniedForever;

  /// No description provided for @connectBluetoothPermissionNeededForPairedList.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is needed to list paired adapters.'**
  String get connectBluetoothPermissionNeededForPairedList;

  /// No description provided for @connectBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn Bluetooth on in system settings first.'**
  String get connectBluetoothOff;

  /// No description provided for @connectWifiHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the IP address of the adapter.'**
  String get connectWifiHostRequired;

  /// {port} is WifiTransport.defaultPort. Never spell the number into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Enter the port (most adapters use {port}).'**
  String connectWifiPortRequired(int port);

  /// {value} is what the user typed, echoed back. {min}/{max} come from the range the connect check enforces.
  ///
  /// In en, this message translates to:
  /// **'“{value}” is not a valid port. The range is {min}–{max}.'**
  String connectWifiPortInvalid(String value, int min, int max);

  /// Says the transcript was kept, not that the connection succeeded.
  ///
  /// In en, this message translates to:
  /// **'The full transcript of this attempt was kept. Bringing that back helps more than a one-line message.'**
  String get connectTranscriptKept;

  /// No description provided for @connectDemoBody.
  ///
  /// In en, this message translates to:
  /// **'Simulates a 2.0 L turbocharged four-cylinder engine through idle, acceleration, cruise and deceleration cycles, with signals that stay physically related to each other (engine speed drops on a gearshift while road speed keeps rising). Fault codes, VIN reads and fastMode batch queries all work in full.'**
  String get connectDemoBody;

  /// No description provided for @connectDemoStart.
  ///
  /// In en, this message translates to:
  /// **'Start the simulator'**
  String get connectDemoStart;

  /// No description provided for @connectWifiHostLabel.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get connectWifiHostLabel;

  /// No description provided for @connectWifiPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get connectWifiPortLabel;

  /// No description provided for @connectConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectConnect;

  /// No description provided for @connectOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get connectOpenSystemSettings;

  /// No description provided for @connectSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get connectSearchAgain;

  /// No description provided for @connectPairedPill.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get connectPairedPill;

  /// No description provided for @connectBlePermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is permanently denied. The system will not ask again, so turn it on in app settings.'**
  String get connectBlePermissionDeniedForever;

  /// No description provided for @connectBlePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is needed to search.'**
  String get connectBlePermissionNeeded;

  /// A GATT device is not paired the way a Classic one is. This must never tell a user to pair a BLE adapter.
  ///
  /// In en, this message translates to:
  /// **'A BLE adapter does not need to be paired first. Search, then pick your device — common names are OBDII, V-LINK, Vgate or IOS-Vlink.'**
  String get connectBleBody;

  /// No description provided for @connectOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get connectOpenAppSettings;

  /// No description provided for @connectBleScanning.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get connectBleScanning;

  /// No description provided for @connectBleScan.
  ///
  /// In en, this message translates to:
  /// **'Search for BLE devices'**
  String get connectBleScan;

  /// No description provided for @connectOpeningConnection.
  ///
  /// In en, this message translates to:
  /// **'Opening the connection…'**
  String get connectOpeningConnection;

  /// No description provided for @connectHandshakeTitle.
  ///
  /// In en, this message translates to:
  /// **'ELM327 initialisation'**
  String get connectHandshakeTitle;

  /// Past tense, so a panel full of green rows cannot be read as the current connection.
  ///
  /// In en, this message translates to:
  /// **'ELM327 initialisation (last attempt)'**
  String get connectHandshakeTitleLastAttempt;

  /// No description provided for @connectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCancel;

  /// No description provided for @connectLastAdapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Last adapter used'**
  String get connectLastAdapterTitle;

  /// No description provided for @connectLastAdapterConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect now'**
  String get connectLastAdapterConnect;

  /// No description provided for @connectLastAdapterForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get connectLastAdapterForget;

  /// Semantics label for the signal meter. {total} comes from the number of bars drawn, not from prose.
  ///
  /// In en, this message translates to:
  /// **'Signal strength {bars}/{total}'**
  String connectSignalStrength(int bars, int total);

  /// iOS only. A permanent OS limit, not a missing feature.
  ///
  /// In en, this message translates to:
  /// **'iOS does not open Bluetooth SPP to third-party apps'**
  String get connectClassicUnavailableIos;

  /// Why the Classic card is greyed out on a host with no SPP path. Keep currently: the host list changes.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Classic (SPP) is currently available on Android, macOS (IOBluetooth RFCOMM), Windows (COM) and Linux (/dev/rfcomm*)'**
  String get connectClassicUnavailableHost;

  /// No description provided for @connectBleUnavailableHost.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE is not available on this host yet'**
  String get connectBleUnavailableHost;

  /// No description provided for @connectWifiInstructionsPhone.
  ///
  /// In en, this message translates to:
  /// **'Join the Wi-Fi hotspot the adapter broadcasts on the phone first, then enter its address. If the system asks whether to stay on a Wi-Fi network that cannot reach the internet, choose to stay on it. On Android, Telltale tries to pin its traffic to the Wi-Fi route while connected, so mobile data does not take it away.'**
  String get connectWifiInstructionsPhone;

  /// No description provided for @connectWifiInstructionsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Connect this computer to the Wi-Fi hotspot the adapter broadcasts first, then enter its address. If the system warns that the network cannot reach the internet, choose to stay on it. Desktop systems usually treat the hotspot as the default route; the Android Wi-Fi route binding is not needed.'**
  String get connectWifiInstructionsDesktop;

  /// No description provided for @connectQuestionWifiPhone.
  ///
  /// In en, this message translates to:
  /// **'Is there a new network in the Wi-Fi list on the phone (something like V-LINK or WiFi_OBDII)?'**
  String get connectQuestionWifiPhone;

  /// No description provided for @connectQuestionWifiDesktop.
  ///
  /// In en, this message translates to:
  /// **'Is there a new network in the Wi-Fi list on the system (something like V-LINK or WiFi_OBDII)?'**
  String get connectQuestionWifiDesktop;

  /// No description provided for @connectAnswerWifiPhone.
  ///
  /// In en, this message translates to:
  /// **'Choose Wi-Fi. Join that network on the phone first, then come back and enter the address.'**
  String get connectAnswerWifiPhone;

  /// No description provided for @connectAnswerWifiDesktop.
  ///
  /// In en, this message translates to:
  /// **'Choose Wi-Fi. Connect this device to that network first, then come back and enter the address.'**
  String get connectAnswerWifiDesktop;

  /// No description provided for @connectQuestionBle.
  ///
  /// In en, this message translates to:
  /// **'Does the box, the shop listing or the device name say BLE, 4.0 or 5.0?'**
  String get connectQuestionBle;

  /// Routing answer for BLE where this host also has Classic. Both halves are load-bearing: do not pair it, and what to do when a box marked 4.0 was only the chip spec.
  ///
  /// In en, this message translates to:
  /// **'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, the 4.0 on the box was only the chip spec — use Bluetooth Classic instead.'**
  String get connectAnswerBleWithClassic;

  /// Same answer on a host with no Classic path. Must not point at the greyed-out Classic card.
  ///
  /// In en, this message translates to:
  /// **'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, check that the adapter has power, or try Wi‑Fi instead; this host does not offer Bluetooth Classic.'**
  String get connectAnswerBleWithoutClassic;

  /// No description provided for @connectQuestionClassic.
  ///
  /// In en, this message translates to:
  /// **'Neither — an older one, with 2.0 or 3.0 printed on the box?'**
  String get connectQuestionClassic;

  /// Classic SPP does need system pairing first. This must never tell a user to skip it.
  ///
  /// In en, this message translates to:
  /// **'Choose Bluetooth Classic. Pair it in system settings first; the app cannot pair it for you. The code is usually 1234 or 0000.'**
  String get connectAnswerClassic;

  /// A Classic adapter can never appear in a BLE scan, so an empty result has to offer that branch.
  ///
  /// In en, this message translates to:
  /// **'Last, check the spec on the box: if it says 2.0 or 3.0 that is Bluetooth Classic, which never appears in this list, so use Bluetooth Classic above instead.'**
  String get connectBleEmptyScanNextClassic;

  /// No description provided for @connectBleEmptyScanNextWifi.
  ///
  /// In en, this message translates to:
  /// **'Last, check the spec on the box: if it says 2.0/3.0, or Wi‑Fi only, try Wi‑Fi instead (this host does not offer Bluetooth Classic).'**
  String get connectBleEmptyScanNextWifi;

  /// {next} is one whole sentence, either connectBleEmptyScanNextClassic or connectBleEmptyScanNextWifi, chosen by whether this host has Bluetooth Classic.
  ///
  /// In en, this message translates to:
  /// **'The scan finished without finding a BLE adapter. Check in order: is the light on the adapter lit — most OBD sockets are unpowered until the ignition is at ON; then range, so sit in the car before scanning. {next} A BLE adapter does not need, and should not have, pairing in system settings; that route does not work.'**
  String connectBleEmptyScan(String next);

  /// No description provided for @connectClassicEmptyPaired.
  ///
  /// In en, this message translates to:
  /// **'No paired adapter found. Pair it in the system Bluetooth settings first (the code for most ELM327s is 1234 or 0000).'**
  String get connectClassicEmptyPaired;

  /// No description provided for @connectClassicEmptyLinuxPort.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth serial port (/dev/rfcomm*) found. Pair the ELM327 with BlueZ first, then create an RFCOMM TTY with rfcomm bind (or the equivalent) and try again.'**
  String get connectClassicEmptyLinuxPort;

  /// No description provided for @connectClassicEmptyWindowsPort.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth serial port (COMx) found. Pair the ELM327 in the Windows Bluetooth settings first, and check that Device Manager shows “Standard Serial over Bluetooth link”.'**
  String get connectClassicEmptyWindowsPort;

  /// No description provided for @connectClassicListPaired.
  ///
  /// In en, this message translates to:
  /// **'This lists every device paired with the system — headphones and speakers included, with the ones that look like adapters first. If you pick the wrong one, press Cancel rather than waiting for it to fail; you can pick another straight away.'**
  String get connectClassicListPaired;

  /// An empty port list is a system state, not an app fault. Serial hosts never list headphones.
  ///
  /// In en, this message translates to:
  /// **'This lists the Bluetooth serial ports BlueZ has bound (/dev/rfcomm* or the equivalent). An empty list means the system has not created an RFCOMM node yet, not that the app is broken.'**
  String get connectClassicListLinuxPort;

  /// No description provided for @connectClassicListWindowsPort.
  ///
  /// In en, this message translates to:
  /// **'This lists the COM ports associated with Bluetooth (“Standard Serial over Bluetooth link”). An empty list means the system has not created a virtual serial port yet, not that the app is broken.'**
  String get connectClassicListWindowsPort;

  /// Accepts the uncertainty rather than demanding a confident choice. Not Choose your connection type.
  ///
  /// In en, this message translates to:
  /// **'Not sure which to pick?'**
  String get connectWhichTitle;

  /// No description provided for @connectWhichIntro.
  ///
  /// In en, this message translates to:
  /// **'Never mind the words SPP and GATT. Go by what your adapter does once it is plugged in:'**
  String get connectWhichIntro;

  /// No description provided for @connectWhichNoteIos.
  ///
  /// In en, this message translates to:
  /// **'An iPhone can only use Wi-Fi or BLE — an ordinary Bluetooth ELM327 does not work at all on iOS. That is an OS limit, and no other app gets around it.'**
  String get connectWhichNoteIos;

  /// Permission to fail. The fear of picking wrong is what makes somebody close the app instead of tapping something.
  ///
  /// In en, this message translates to:
  /// **'Guessing wrong costs nothing — if it will not connect, come back and try another. If you are really stuck, use the Demo simulator at the bottom to confirm the app itself is working.'**
  String get connectWhichNoteGuessing;
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
