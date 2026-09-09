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

  /// No description provided for @adapterErrorActivityAlert.
  ///
  /// In en, this message translates to:
  /// **'Bus activity alert.'**
  String get adapterErrorActivityAlert;

  /// No description provided for @adapterErrorBufferFull.
  ///
  /// In en, this message translates to:
  /// **'The adapter\'s buffer overflowed.'**
  String get adapterErrorBufferFull;

  /// No description provided for @adapterErrorBus.
  ///
  /// In en, this message translates to:
  /// **'Bus error; the wiring may be the cause.'**
  String get adapterErrorBus;

  /// No description provided for @adapterErrorBusBusy.
  ///
  /// In en, this message translates to:
  /// **'The bus is busy.'**
  String get adapterErrorBusBusy;

  /// No description provided for @adapterErrorBusInit.
  ///
  /// In en, this message translates to:
  /// **'Bus initialisation failed.'**
  String get adapterErrorBusInit;

  /// The adapter answered CAN ERROR. The literal stays untranslated wherever the reply itself is quoted; this is the sentence written for a driver.
  ///
  /// In en, this message translates to:
  /// **'CAN bus error.'**
  String get adapterErrorCan;

  /// No description provided for @adapterErrorData.
  ///
  /// In en, this message translates to:
  /// **'The data that arrived is not correct.'**
  String get adapterErrorData;

  /// No description provided for @adapterErrorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Signal feedback error.'**
  String get adapterErrorFeedback;

  /// No description provided for @adapterErrorInternal.
  ///
  /// In en, this message translates to:
  /// **'Adapter internal error.'**
  String get adapterErrorInternal;

  /// No description provided for @adapterErrorLowPowerAlert.
  ///
  /// In en, this message translates to:
  /// **'The adapter is about to enter low-power mode.'**
  String get adapterErrorLowPowerAlert;

  /// No description provided for @adapterErrorLowVoltageReset.
  ///
  /// In en, this message translates to:
  /// **'Low voltage reset the adapter.'**
  String get adapterErrorLowVoltageReset;

  /// Elm327ErrorCode.noData. Deliberately NOT 'the vehicle does not support this': NO DATA is the adapter reporting that nothing arrived before its own timeout, and a busy ECU, a receive filter or one aggressive timing window produces it exactly as an absent sensor does. Both possibilities must survive translation.
  ///
  /// In en, this message translates to:
  /// **'No reply arrived — it may be temporary silence, or the vehicle may not support this.'**
  String get adapterErrorNoData;

  /// No description provided for @adapterErrorStopped.
  ///
  /// In en, this message translates to:
  /// **'The transfer was interrupted.'**
  String get adapterErrorStopped;

  /// Elm327ErrorCode.unableToConnect. The remedy is half the message: most OBD sockets are unpowered until the ignition is on.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the ECU. Check that the ignition is on.'**
  String get adapterErrorUnableToConnect;

  /// Elm327ErrorCode.unknownCommand. A statement about the ADAPTER, never about the vehicle.
  ///
  /// In en, this message translates to:
  /// **'The adapter does not support this command.'**
  String get adapterErrorUnknownCommand;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Live vehicle telemetry'**
  String get appTagline;

  /// App name shown in window titles and the connect header.
  ///
  /// In en, this message translates to:
  /// **'Telltale'**
  String get appTitle;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// ObdConnectionActivity.abortingPreviousConnection. Says the tap registered and what is being waited for; the wizard showed nothing at all here before.
  ///
  /// In en, this message translates to:
  /// **'Stopping the previous connection, one moment…'**
  String get connectActivityAbortingPreviousConnection;

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

  /// Classic SPP does need system pairing first. This must never tell a user to skip it.
  ///
  /// In en, this message translates to:
  /// **'Choose Bluetooth Classic. Pair it in system settings first; the app cannot pair it for you. The code is usually 1234 or 0000.'**
  String get connectAnswerClassic;

  /// No description provided for @connectAnswerWifiDesktop.
  ///
  /// In en, this message translates to:
  /// **'Choose Wi-Fi. Connect this device to that network first, then come back and enter the address.'**
  String get connectAnswerWifiDesktop;

  /// No description provided for @connectAnswerWifiPhone.
  ///
  /// In en, this message translates to:
  /// **'Choose Wi-Fi. Join that network on the phone first, then come back and enter the address.'**
  String get connectAnswerWifiPhone;

  /// A GATT device is not paired the way a Classic one is. This must never tell a user to pair a BLE adapter.
  ///
  /// In en, this message translates to:
  /// **'A BLE adapter does not need to be paired first. Search, then pick your device — common names are OBDII, V-LINK, Vgate or IOS-Vlink.'**
  String get connectBleBody;

  /// {next} is one whole sentence, either connectBleEmptyScanNextClassic or connectBleEmptyScanNextWifi, chosen by whether this host has Bluetooth Classic.
  ///
  /// In en, this message translates to:
  /// **'The scan finished without finding a BLE adapter. Check in order: is the light on the adapter lit — most OBD sockets are unpowered until the ignition is at ON; then range, so sit in the car before scanning. {next} A BLE adapter does not need, and should not have, pairing in system settings; that route does not work.'**
  String connectBleEmptyScan(String next);

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

  /// No description provided for @connectBleScan.
  ///
  /// In en, this message translates to:
  /// **'Search for BLE devices'**
  String get connectBleScan;

  /// No description provided for @connectBleScanning.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get connectBleScanning;

  /// No description provided for @connectBleUnavailableHost.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE is not available on this host yet'**
  String get connectBleUnavailableHost;

  /// No description provided for @connectBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn Bluetooth on in system settings first.'**
  String get connectBluetoothOff;

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

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'Plug in an ELM327 adapter and switch the ignition on, or use the built-in simulator.'**
  String get connectBody;

  /// No description provided for @connectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCancel;

  /// No description provided for @connectClassicEmptyLinuxPort.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth serial port (/dev/rfcomm*) found. Pair the ELM327 with BlueZ first, then create an RFCOMM TTY with rfcomm bind (or the equivalent) and try again.'**
  String get connectClassicEmptyLinuxPort;

  /// No description provided for @connectClassicEmptyPaired.
  ///
  /// In en, this message translates to:
  /// **'No paired adapter found. Pair it in the system Bluetooth settings first (the code for most ELM327s is 1234 or 0000).'**
  String get connectClassicEmptyPaired;

  /// No description provided for @connectClassicEmptyWindowsPort.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth serial port (COMx) found. Pair the ELM327 in the Windows Bluetooth settings first, and check that Device Manager shows “Standard Serial over Bluetooth link”.'**
  String get connectClassicEmptyWindowsPort;

  /// An empty port list is a system state, not an app fault. Serial hosts never list headphones.
  ///
  /// In en, this message translates to:
  /// **'This lists the Bluetooth serial ports BlueZ has bound (/dev/rfcomm* or the equivalent). An empty list means the system has not created an RFCOMM node yet, not that the app is broken.'**
  String get connectClassicListLinuxPort;

  /// No description provided for @connectClassicListPaired.
  ///
  /// In en, this message translates to:
  /// **'This lists every device paired with the system — headphones and speakers included, with the ones that look like adapters first. If you pick the wrong one, press Cancel rather than waiting for it to fail; you can pick another straight away.'**
  String get connectClassicListPaired;

  /// No description provided for @connectClassicListWindowsPort.
  ///
  /// In en, this message translates to:
  /// **'This lists the COM ports associated with Bluetooth (“Standard Serial over Bluetooth link”). An empty list means the system has not created a virtual serial port yet, not that the app is broken.'**
  String get connectClassicListWindowsPort;

  /// Why the Classic card is greyed out on a host with no SPP path. Keep currently: the host list changes.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Classic (SPP) is currently available on Android, macOS (IOBluetooth RFCOMM), Windows (COM) and Linux (/dev/rfcomm*)'**
  String get connectClassicUnavailableHost;

  /// iOS only. A permanent OS limit, not a missing feature.
  ///
  /// In en, this message translates to:
  /// **'iOS does not open Bluetooth SPP to third-party apps'**
  String get connectClassicUnavailableIos;

  /// No description provided for @connectConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectConnect;

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

  /// No description provided for @connectHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a connection'**
  String get connectHeadline;

  /// ObdConnectionIssue.adapterAcceptedThenSilent. Both causes are load-bearing: an unpowered socket and a second app holding the adapter look identical from here, and naming only one sends half the readers looking in the wrong place.
  ///
  /// In en, this message translates to:
  /// **'The adapter accepted the connection but answered nothing in time. Usually it is not powered yet — most OBD sockets only supply power with the ignition on — or another app is already connected to it, in which case close that one and try again.'**
  String get connectIssueAdapterAcceptedThenSilent;

  /// ObdConnectionIssue.adapterSilentOnReset. Failing on the very first command is a different diagnosis from failing later, and the command is named rather than described. {command} is an AT command and is never translated.
  ///
  /// In en, this message translates to:
  /// **'The adapter did not answer the reset command ({command}). This device may not be an ELM327 adapter, or the connection may have gone to the wrong device.'**
  String connectIssueAdapterSilentOnReset(String command);

  /// ObdConnectionIssue.adapterStoppedResponding. States what already happened, not a warning about what might.
  ///
  /// In en, this message translates to:
  /// **'The adapter stopped responding and the connection has been dropped.'**
  String get connectIssueAdapterStoppedResponding;

  /// ObdConnectionIssue.connectionSetupFailed. The raw exception text is deliberately not shown here; it is written to the transcript, which is where somebody can act on it.
  ///
  /// In en, this message translates to:
  /// **'The connection failed while it was being established. Check that the adapter has power and is nearby, then try again. The full error is kept in the log below.'**
  String get connectIssueConnectionSetupFailed;

  /// ObdConnectionIssue.handshakeIncomplete. No step reported a failure, so this is the least specific thing that is still true. It must stay a possibility, never a verdict on the adapter.
  ///
  /// In en, this message translates to:
  /// **'Initialisation did not pass. The adapter may not be compatible.'**
  String get connectIssueHandshakeIncomplete;

  /// ObdConnectionIssue.handshakeStepFailed. Which command died is the whole value of this message: it separates 'this is not an ELM327' from 'the adapter is fine but the ignition is off'. {command} is an AT command or a mode/PID and is never translated; {reason} is the step's own outcome.
  ///
  /// In en, this message translates to:
  /// **'Initialisation failed at {command} ({reason}). Check that the adapter is seated properly and the vehicle\'s ignition is on.'**
  String connectIssueHandshakeStepFailed(String command, String reason);

  /// ObdConnectionIssue.previousConnectionStillAborting. A refusal that says what happened and what to do about it; a silent false here was the defect this replaced.
  ///
  /// In en, this message translates to:
  /// **'The previous connection is still being stopped and the adapter has not been released yet. Wait a few seconds and try again.'**
  String get connectIssuePreviousConnectionStillAborting;

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

  /// No description provided for @connectLastAdapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Last adapter used'**
  String get connectLastAdapterTitle;

  /// No description provided for @connectOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get connectOpenAppSettings;

  /// No description provided for @connectOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get connectOpenSystemSettings;

  /// No description provided for @connectOpeningConnection.
  ///
  /// In en, this message translates to:
  /// **'Opening the connection…'**
  String get connectOpeningConnection;

  /// No description provided for @connectPairedPill.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get connectPairedPill;

  /// No description provided for @connectQuestionBle.
  ///
  /// In en, this message translates to:
  /// **'Does the box, the shop listing or the device name say BLE, 4.0 or 5.0?'**
  String get connectQuestionBle;

  /// No description provided for @connectQuestionClassic.
  ///
  /// In en, this message translates to:
  /// **'Neither — an older one, with 2.0 or 3.0 printed on the box?'**
  String get connectQuestionClassic;

  /// No description provided for @connectQuestionWifiDesktop.
  ///
  /// In en, this message translates to:
  /// **'Is there a new network in the Wi-Fi list on the system (something like V-LINK or WiFi_OBDII)?'**
  String get connectQuestionWifiDesktop;

  /// No description provided for @connectQuestionWifiPhone.
  ///
  /// In en, this message translates to:
  /// **'Is there a new network in the Wi-Fi list on the phone (something like V-LINK or WiFi_OBDII)?'**
  String get connectQuestionWifiPhone;

  /// No description provided for @connectSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get connectSearchAgain;

  /// Semantics label for the signal meter. {total} comes from the number of bars drawn, not from prose.
  ///
  /// In en, this message translates to:
  /// **'Signal strength {bars}/{total}'**
  String connectSignalStrength(int bars, int total);

  /// Says the transcript was kept, not that the connection succeeded.
  ///
  /// In en, this message translates to:
  /// **'The full transcript of this attempt was kept. Bringing that back helps more than a one-line message.'**
  String get connectTranscriptKept;

  /// Subtitle of the Bluetooth LE tile on the connect screen. GATT and UART are on docs/i18n/do-not-translate.md. Must NOT tell the driver to pair the adapter: a BLE adapter is discovered by scanning inside the app, and pairing it in system settings is the route that does not work (connectAnswerBleWithClassic says so at length).
  ///
  /// In en, this message translates to:
  /// **'GATT UART — a newer low-energy adapter'**
  String get connectTransportBleDescription;

  /// Title of the Bluetooth LE tile on the connect screen, and the transport name on the “last adapter used” line. A product name — byte-identical in both languages, per docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE'**
  String get connectTransportBleTitle;

  /// Subtitle of the Bluetooth Classic tile on the connect screen. RFCOMM, SPP and ELM327 are on docs/i18n/do-not-translate.md. Must NOT say pairing can be skipped: Classic is the one transport the app cannot pair for the driver (connectAnswerClassic and connectClassicEmptyPaired carry that instruction).
  ///
  /// In en, this message translates to:
  /// **'RFCOMM / SPP — the most common budget ELM327'**
  String get connectTransportClassicDescription;

  /// Title of the Bluetooth Classic tile on the connect screen, and the transport name on the “last adapter used” line. A product name — byte-identical in both languages, per docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Classic'**
  String get connectTransportClassicTitle;

  /// Subtitle of the Demo tile on the connect screen. ECU is on docs/i18n/do-not-translate.md. Scoped to the app deliberately: Demo crosses no radio, no socket and no vehicle, so it must not be described as evidence that a car will work (docs/field-guide.zh-TW.md:27-32).
  ///
  /// In en, this message translates to:
  /// **'A built-in simulated ECU — the whole app with no hardware'**
  String get connectTransportDemoDescription;

  /// Title of the Demo tile on the connect screen. Same English as wearDemoSimulator, which names the same feature on the watch face.
  ///
  /// In en, this message translates to:
  /// **'Demo simulator'**
  String get connectTransportDemoTitle;

  /// Subtitle of the Wi-Fi tile on the connect screen. The address is a literal on docs/i18n/do-not-translate.md and must stay byte-identical in both languages.
  ///
  /// In en, this message translates to:
  /// **'A TCP port, usually 192.168.0.10:35000'**
  String get connectTransportWifiDescription;

  /// Title of the Wi-Fi tile on the connect screen, and the transport name on the “last adapter used” line. A product name — byte-identical in both languages, per docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get connectTransportWifiTitle;

  /// No description provided for @connectWhichIntro.
  ///
  /// In en, this message translates to:
  /// **'Never mind the words SPP and GATT. Go by what your adapter does once it is plugged in:'**
  String get connectWhichIntro;

  /// Permission to fail. The fear of picking wrong is what makes somebody close the app instead of tapping something.
  ///
  /// In en, this message translates to:
  /// **'Guessing wrong costs nothing — if it will not connect, come back and try another. If you are really stuck, use the Demo simulator at the bottom to confirm the app itself is working.'**
  String get connectWhichNoteGuessing;

  /// No description provided for @connectWhichNoteIos.
  ///
  /// In en, this message translates to:
  /// **'An iPhone can only use Wi-Fi or BLE — an ordinary Bluetooth ELM327 does not work at all on iOS. That is an OS limit, and no other app gets around it.'**
  String get connectWhichNoteIos;

  /// Accepts the uncertainty rather than demanding a confident choice. Not Choose your connection type.
  ///
  /// In en, this message translates to:
  /// **'Not sure which to pick?'**
  String get connectWhichTitle;

  /// No description provided for @connectWifiHostLabel.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get connectWifiHostLabel;

  /// No description provided for @connectWifiHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the IP address of the adapter.'**
  String get connectWifiHostRequired;

  /// No description provided for @connectWifiInstructionsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Connect this computer to the Wi-Fi hotspot the adapter broadcasts first, then enter its address. If the system warns that the network cannot reach the internet, choose to stay on it. Desktop systems usually treat the hotspot as the default route; the Android Wi-Fi route binding is not needed.'**
  String get connectWifiInstructionsDesktop;

  /// No description provided for @connectWifiInstructionsPhone.
  ///
  /// In en, this message translates to:
  /// **'Join the Wi-Fi hotspot the adapter broadcasts on the phone first, then enter its address. If the system asks whether to stay on a Wi-Fi network that cannot reach the internet, choose to stay on it. On Android, Telltale tries to pin its traffic to the Wi-Fi route while connected, so mobile data does not take it away.'**
  String get connectWifiInstructionsPhone;

  /// {value} is what the user typed, echoed back. {min}/{max} come from the range the connect check enforces.
  ///
  /// In en, this message translates to:
  /// **'“{value}” is not a valid port. The range is {min}–{max}.'**
  String connectWifiPortInvalid(String value, int min, int max);

  /// No description provided for @connectWifiPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get connectWifiPortLabel;

  /// {port} is WifiTransport.defaultPort. Never spell the number into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Enter the port (most adapters use {port}).'**
  String connectWifiPortRequired(int port);

  /// Pill label while PriorityScheduler.fastModeEnabled AND canBatch are both true. Neither is a record that any exchange grouped anything: grouping also needs the PID confirmed batchable and more than one request queued. Says enabled, never active or verified.
  ///
  /// In en, this message translates to:
  /// **'Batching enabled'**
  String get dashboardBatchingEnabled;

  /// No description provided for @dashboardChoosePids.
  ///
  /// In en, this message translates to:
  /// **'Choose PIDs'**
  String get dashboardChoosePids;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the signals you want to watch on the PID page and they will appear here.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The dashboard is empty'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardGenericObd.
  ///
  /// In en, this message translates to:
  /// **'Generic OBD'**
  String get dashboardGenericObd;

  /// No description provided for @dashboardLocalRecordings.
  ///
  /// In en, this message translates to:
  /// **'Local recordings'**
  String get dashboardLocalRecordings;

  /// Stands in for an adapter name before anything is connected. A real device name is passed through untranslated.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get dashboardNotConnected;

  /// Accessible name of the button the polling-mode pill sits inside. It opens an explanation and sends nothing to the adapter.
  ///
  /// In en, this message translates to:
  /// **'About polling mode'**
  String get dashboardPollingModeHelpAction;

  /// Explains the enabled side of the pill, which is shown only when PriorityScheduler.fastModeEnabled and canBatch are both set. Must not claim that grouping was observed.
  ///
  /// In en, this message translates to:
  /// **'Batching enabled means Telltale may group PID requests into one exchange, to cut the number of round trips: grouped attempts are permitted and nothing has turned grouping off. It is still permission rather than a measurement, because whether a given exchange grouped anything also depends on which PIDs the vehicle has confirmed and on how many are waiting.'**
  String get dashboardPollingModeHelpBatching;

  /// Keeps the throughput pill separate from the polling mode. PIDs/s is on docs/i18n/do-not-translate.md and stays byte-identical in both languages.
  ///
  /// In en, this message translates to:
  /// **'PIDs/s is a rate observed over the last second, not a promise about latency, freshness or accuracy. It moves with the adapter, the bus, the ECU, the PIDs you selected, how large each reply is, and any errors.'**
  String get dashboardPollingModeHelpRate;

  /// Explains the fallback side of the pill, which covers three different states and cannot tell them apart: a bus that never groups (not CAN); a CAN bus where PollingEngine has not yet had a support block answered, so canBatch is still false and grouping is held back on purpose; and grouping withdrawn after a bad reply. The third names what the three paths into PriorityScheduler.handleCorruptionEvent share rather than only the truncated-frame one — an unanswered batch is silence, not a garbled reply, and this codebase does not let those be confused. Says Mode 01 because a powertrain profile response is drained as one batch either way.
  ///
  /// In en, this message translates to:
  /// **'Single request mode means each Mode 01 PID is read on its own. Telltale uses it when the bus does not take grouped requests at all, which is every non-CAN vehicle; while no support block has answered yet, because grouping PIDs the vehicle has not confirmed is what makes a reply come back short; and after a grouped request fails to come back in a form it can split apart again, whether truncated, refused because the adapter reported its buffer full, or unanswered. Readings carry on updating, and on its own this is not a connection failure.'**
  String get dashboardPollingModeHelpSingle;

  /// Title of the dialog behind the polling-mode pill.
  ///
  /// In en, this message translates to:
  /// **'Polling mode'**
  String get dashboardPollingModeHelpTitle;

  /// Pill label whenever PriorityScheduler.fastModeEnabled or canBatch is false. Either way popBatch stops grouping Mode 01 PIDs, so single-request is what the state proves rather than what it permits. The other side of the pill is dashboardBatchingEnabled, which needs both; the raw fastMode identifier stays in logs and code and is no longer rendered.
  ///
  /// In en, this message translates to:
  /// **'Single request mode'**
  String get dashboardSingleRequestMode;

  /// No description provided for @dashboardVinRead.
  ///
  /// In en, this message translates to:
  /// **'VIN read'**
  String get dashboardVinRead;

  /// No description provided for @dashboardWorkspaceGauges.
  ///
  /// In en, this message translates to:
  /// **'Gauges'**
  String get dashboardWorkspaceGauges;

  /// No description provided for @dashboardWorkspaceTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardWorkspaceTrends;

  /// EvidenceKind.community. A claim about the SOURCE of the decode, never about this car; it is always shown together with datumBadgeUnverifiedOnThisVehicle.
  ///
  /// In en, this message translates to:
  /// **'Community decode'**
  String get datumBadgeCommunityDecode;

  /// DatumOrigin.demo. The number came from Telltale's own simulator, not from a vehicle. This has to be unmistakable: a simulated reading that passes for a live one is the worst thing this app can do.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get datumBadgeDemo;

  /// DatumOrigin.calculated. Computed from a vehicle profile, never read off the bus. Estimated is not measured, and the two must stay two different words.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get datumBadgeEstimated;

  /// EvidenceKind.experimental. Always shown with datumBadgeUnverifiedOnThisVehicle.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get datumBadgeExperimental;

  /// EvidenceKind.fieldVerified. Verified on a real vehicle, which is why the English says field rather than just verified — a catalog entry passing validation is not this.
  ///
  /// In en, this message translates to:
  /// **'Field-verified'**
  String get datumBadgeFieldVerified;

  /// DatumQuality.invalid. The datum failed a structural check and may not be read as a value at all. Distinct from datumBadgeUnverified, which says nothing about the value.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get datumBadgeInvalid;

  /// The value arrived on the most recent poll. The opposite pole of datumBadgeStale; never render either as the other.
  ///
  /// In en, this message translates to:
  /// **'Just updated'**
  String get datumBadgeJustUpdated;

  /// DatumQuality.outOfReferenceRange. A check was run against the definition's own minimum and maximum and the value fell outside it. Not merely 'unusual' — a check failed, and the reading is kept rather than hidden.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get datumBadgeOutOfReferenceRange;

  /// DatumQuality.partial. Something was not read. Partial is not all clear and must never read as a completed or fault-free result.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get datumBadgePartial;

  /// DatumQuality.stale. The reading stopped updating. Stale is not live; a reading that stopped updating must never render as a current one.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get datumBadgeStale;

  /// DatumQuality.tentativeDecode. The bytes were decoded with a formula that is not confirmed for this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Tentative decode'**
  String get datumBadgeTentativeDecode;

  /// EvidenceKind.notTested and EvidenceKind.unknown. Nobody has checked this against a real vehicle. Unverified is not invalid and it is not verified; it is a statement about evidence, not about the number.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get datumBadgeUnverified;

  /// The second half of the community and experimental pairs. The source may be corroborated elsewhere; nobody has driven it on THIS car. Never shorten to 'unverified' — the scope is the whole point.
  ///
  /// In en, this message translates to:
  /// **'Unverified on this vehicle'**
  String get datumBadgeUnverifiedOnThisVehicle;

  /// DatumOrigin.userEntered and EvidenceKind.userSupplied. The definition came from the person holding the phone, so the app makes no claim about it.
  ///
  /// In en, this message translates to:
  /// **'User-supplied'**
  String get datumBadgeUserSupplied;

  /// DatumGap.modelYearUnknown. One of the optional identification gaps listed on the dashboard session chip. None of them blocks generic OBD.
  ///
  /// In en, this message translates to:
  /// **'Model year unknown'**
  String get datumGapModelYearUnknown;

  /// DatumGap.noCatalogMatch. The catalog holds no entry for this vehicle. Not a fault, and not a reason to stop reading generic OBD.
  ///
  /// In en, this message translates to:
  /// **'No catalog match'**
  String get datumGapNoCatalogMatch;

  /// DatumGap.vinNotRead. A read outcome, never a claim that the vehicle has no VIN. VIN is on docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'VIN not read'**
  String get datumGapVinNotRead;

  /// DatumNextStep.estimateOnlyOtherReadingsUnaffected. Scopes a failed estimate so nobody reads it as the session going wrong.
  ///
  /// In en, this message translates to:
  /// **'This affects only the estimate; the other readings still apply.'**
  String get datumNextStepEstimateOnly;

  /// DatumNextStep.genericObdContinues. Missing identification never blocks generic OBD, and this sentence is what says so.
  ///
  /// In en, this message translates to:
  /// **'You can carry on with generic OBD, or choose the vehicle by hand and fill in the parameters.'**
  String get datumNextStepGenericObd;

  /// DatumNextStep.otherReadingsUnaffected. One PID failing is not the session failing.
  ///
  /// In en, this message translates to:
  /// **'The failure affects only this item; the other readings still apply.'**
  String get datumNextStepOtherReadings;

  /// DatumNextStep.rawOnlyNeverANumber. The raw bytes stay available for diagnosis, and the sentence exists to stop somebody reading them as a measurement.
  ///
  /// In en, this message translates to:
  /// **'The raw reply and the error can be inspected; neither may be read as a normal value.'**
  String get datumNextStepRawOnly;

  /// DatumReason.assumptionsUnconfirmed. docs/i18n/hedge-register.md entry 18: both halves are required. 'Unconfirmed' alone reads as an error and 'an estimate is shown' alone reads as a validated number.
  ///
  /// In en, this message translates to:
  /// **'The assumptions are unconfirmed; an estimate is still shown.'**
  String get datumReasonAssumptionsUnconfirmed;

  /// PidFault.busError. A fault on the link, not a statement about the vehicle's capabilities.
  ///
  /// In en, this message translates to:
  /// **'Bus error.'**
  String get datumReasonBusError;

  /// PidFault.formulaError. The definition's own equation failed, so the fault is in the app or the imported PID, not in the car.
  ///
  /// In en, this message translates to:
  /// **'Formula error.'**
  String get datumReasonFormulaError;

  /// DatumReason.fuelEstimateMissingInputs. Says the estimate could not be made, never that the vehicle uses no fuel.
  ///
  /// In en, this message translates to:
  /// **'The fuel-use estimate is missing a required input.'**
  String get datumReasonFuelEstimateMissingInputs;

  /// PidFault.headerNotOnThisBus. A statement about the PID DEFINITION, deliberately kept apart from datumReasonPidUnsupported, which is a statement about the car. Merging them sends somebody looking at their vehicle for a problem that is in a field they can edit.
  ///
  /// In en, this message translates to:
  /// **'The header does not match the bus this vehicle uses.'**
  String get datumReasonHeaderNotOnThisBus;

  /// DatumReason.horsepowerEstimateMissingInputs. Says the estimate could not be made, never that the engine produced no power.
  ///
  /// In en, this message translates to:
  /// **'The horsepower estimate is missing a required input.'**
  String get datumReasonHorsepowerEstimateMissingInputs;

  /// The response did not parse. Nothing here may be shown as a number.
  ///
  /// In en, this message translates to:
  /// **'Malformed packet; only the raw reply can be inspected.'**
  String get datumReasonMalformedPacket;

  /// Shown in a datum's details dialog when a PID went unanswered. The app does retry, on the 60-second backoff in PollingEngine.noAnswerBackoff, so this must not tell the reader to act. It previously read 'try again shortly', which contradicted telemetryStatusNoAnswer — the same Chinese sentence, rendered one tap away on the tile itself, saying the app would retry.
  ///
  /// In en, this message translates to:
  /// **'No answer — the app retries in about a minute.'**
  String get datumReasonNoAnswer;

  /// docs/i18n/hedge-register.md entry 25. Explicitly not zero and not unsupported — the app's baseline refusal to print a number it does not have.
  ///
  /// In en, this message translates to:
  /// **'No reading yet.'**
  String get datumReasonNoReadingYet;

  /// The formula produced NaN or an infinity, so there is no value to show.
  ///
  /// In en, this message translates to:
  /// **'Not a finite number.'**
  String get datumReasonNonFiniteValue;

  /// DatumQuality.outOfReferenceRange. Both halves matter: a check failed, AND the reading was not silently discarded or clamped.
  ///
  /// In en, this message translates to:
  /// **'Outside the usual reference range; kept as it was read.'**
  String get datumReasonOutOfReferenceRangeKept;

  /// PidFault.unsupported, the only state that justifies an assertion about the CAR. docs/i18n/hedge-register.md entry 16: it must stay distinguishable from datumReasonNoAnswer, which is temporary.
  ///
  /// In en, this message translates to:
  /// **'This vehicle does not support this PID.'**
  String get datumReasonPidUnsupported;

  /// PidFault.refusedUnsafeService as a reason on a datum.
  ///
  /// In en, this message translates to:
  /// **'This service is not a read-only query.'**
  String get datumReasonUnsafeService;

  /// The same fact plus the action taken. The app refused to transmit; nothing was written to the vehicle.
  ///
  /// In en, this message translates to:
  /// **'This service is not a read-only query, so it was not sent.'**
  String get datumReasonUnsafeServiceStopped;

  /// No description provided for @datumStatusAssumptions.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get datumStatusAssumptions;

  /// No description provided for @datumStatusClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get datumStatusClose;

  /// Shown in the per-value details dialog when the datum carries no badge. It must never read as 'valid', 'OK' or 'normal' — it says only that nothing was flagged.
  ///
  /// In en, this message translates to:
  /// **'Status follows the data'**
  String get datumStatusFollowsData;

  /// No description provided for @datumStatusFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get datumStatusFormula;

  /// No description provided for @derivedAirflow.
  ///
  /// In en, this message translates to:
  /// **'Airflow'**
  String get derivedAirflow;

  /// Used when the vehicle reported its own fuel rate. Must never read as estimated.
  ///
  /// In en, this message translates to:
  /// **'ECU fuel data'**
  String get derivedEcuFuelTitle;

  /// No description provided for @derivedEcuReported.
  ///
  /// In en, this message translates to:
  /// **'ECU reported'**
  String get derivedEcuReported;

  /// Engine (crank) power, not wheel power - PhysicsEngine reports both and this cell shows engineHorsepower. Kept short so the cell does not ellipsise at large text scales.
  ///
  /// In en, this message translates to:
  /// **'Engine power'**
  String get derivedEngineHorsepower;

  /// Used when no ECU fuel rate was reported and the figure came from the vehicle profile. Must never read as measured.
  ///
  /// In en, this message translates to:
  /// **'Estimated fuel use'**
  String get derivedEstimatedFuelTitle;

  /// No description provided for @derivedEstimatesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate formulas and assumptions'**
  String get derivedEstimatesDetailsTitle;

  /// Heading of the derived panel. These figures are computed from a vehicle profile, never read off the bus, and 'estimated' is the whole reason the panel is separate.
  ///
  /// In en, this message translates to:
  /// **'Estimated values'**
  String get derivedEstimatesTitle;

  /// Neutral cell label: the same cell renders an ECU-reported rate and an estimated one, so it must not itself claim either.
  ///
  /// In en, this message translates to:
  /// **'Fuel use'**
  String get derivedFuelUse;

  /// No description provided for @derivedTorque.
  ///
  /// In en, this message translates to:
  /// **'Torque'**
  String get derivedTorque;

  /// A distinct state, not a row of zeroes: 'we cannot work this out yet' and 'your engine is producing no power' must not look alike.
  ///
  /// In en, this message translates to:
  /// **'Horsepower can only be estimated once vehicle speed and acceleration data arrive'**
  String get derivedUnavailableMessage;

  /// No description provided for @dtcBothSilentDetail.
  ///
  /// In en, this message translates to:
  /// **'The vehicle did not answer the Mode {mode} query, and Mode 03 did not answer either — so there is no telling whether the vehicle lacks support or this connection simply did not read it.'**
  String dtcBothSilentDetail(Object mode);

  /// No description provided for @dtcCategoryFault.
  ///
  /// In en, this message translates to:
  /// **'A fault related to {category}'**
  String dtcCategoryFault(Object category);

  /// No description provided for @dtcClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dtcClear;

  /// No description provided for @dtcClearCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dtcClearCancel;

  /// No description provided for @dtcClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear them'**
  String get dtcClearConfirm;

  /// The point of no return. Mode 0A permanent codes must never read as something this clear can remove.
  ///
  /// In en, this message translates to:
  /// **'This erases stored and pending fault codes and turns the fault lamp off, and it also resets emissions readiness — the vehicle has to complete a full round of self-diagnosis again before it can pass an inspection. Permanent fault codes (Mode 0A) cannot be cleared.'**
  String get dtcClearDialogBody;

  /// A read failure, not an absent frame. Collapsing the two causes irreversible evidence loss.
  ///
  /// In en, this message translates to:
  /// **'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear.'**
  String get dtcClearDialogFrameUnread;

  /// Fault codes come back if the fault recurs; the snapshot of the moment it first happened does not.
  ///
  /// In en, this message translates to:
  /// **'The freeze frame for {codes} goes with it — the whole record of engine speed, coolant temperature and load at the moment the fault happened — and it cannot be read back until the fault happens again.'**
  String dtcClearDialogFrames(Object codes);

  /// No description provided for @dtcClearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear fault codes?'**
  String get dtcClearDialogTitle;

  /// What the scan could not establish, said at the point of no return.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One category in this scan did not answer completely} other{{count} categories in this scan did not answer completely}} ({categories}), so there may be fault codes you have not seen. After a clear they can never be read again.'**
  String dtcClearDialogUnanswered(int count, Object categories);

  /// DtcClearNoticeKind.cancelledBeforeSend. The lease retired before the first write; a repeat cannot harm readiness.
  ///
  /// In en, this message translates to:
  /// **'The clear was cancelled before any command left the app. Rescan, then try again if you still want to clear.'**
  String get dtcClearCancelledBeforeSend;

  /// DtcClearNoticeKind.confirmed / ClearOutcome.confirmed. The only success sentence. Does not claim every controller erased its memory.
  ///
  /// In en, this message translates to:
  /// **'The clear command was sent.'**
  String get dtcClearConfirmed;

  /// DtcReadException on the clear path with repeatWouldHarm, when there is no TransportIssue. Names the harm, not the engine's Traditional Chinese sentence.
  ///
  /// In en, this message translates to:
  /// **'A clear may already have reached the vehicle. Do not send another — a second global clear can reset emissions readiness on a controller that may already have cleared. Rescan to see what is left.'**
  String get dtcClearFailureDoNotRepeat;

  /// DtcReadException on the clear path without repeatWouldHarm and without a TransportIssue. Does not invite a blind retry and does not interpolate the engine sentence.
  ///
  /// In en, this message translates to:
  /// **'The clear did not finish. Rescan to see the current codes before deciding whether to try again.'**
  String get dtcClearFailureGeneric;

  /// DtcClearNoticeKind.notAccepted / ClearOutcome.notAccepted. Retry is free because nothing was transmitted.
  ///
  /// In en, this message translates to:
  /// **'The clear failed; no controller accepted the command. You can try again.'**
  String get dtcClearNotAccepted;

  /// DtcClearNoticeKind.partiallyConfirmed / ClearOutcome.partiallyConfirmed. The load-bearing advice is not to send a second global 04.
  ///
  /// In en, this message translates to:
  /// **'At least one controller reported the clear finished, and the rest could not be confirmed. Do not send another clear — repeating it resets emissions readiness on controllers that already finished. Rescan to see the result.'**
  String get dtcClearPartiallyConfirmed;

  /// DtcClearNoticeKind.previousConnectionUnconfirmed. Survives reconnect so a live Clear is not offered over a controller that may already have erased its memory.
  ///
  /// In en, this message translates to:
  /// **'A previous connection sent a clear whose result was not confirmed. Rescan first, see which codes remain, then decide whether to clear.'**
  String get dtcClearPreviousConnectionUnconfirmed;

  /// DtcClearNoticeKind.rescanSettled. Replaces the pre-rescan 'do not press Clear' sentence once the button is live again.
  ///
  /// In en, this message translates to:
  /// **'The previous clear could not be fully confirmed. What follows is the actual state after this rescan.'**
  String get dtcClearRescanSettled;

  /// DtcClearNoticeKind.sentUnconfirmed / ClearOutcome.sentUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The clear command was sent, but the reply was damaged in transit, so it is not known whether the vehicle cleared. Rescan to check; do not send another clear — if it already succeeded, repeating it resets emissions readiness.'**
  String get dtcClearSentUnconfirmed;

  /// DtcClearNoticeKind.timeout. Conservative: an unknown clear must not invite a blind retry.
  ///
  /// In en, this message translates to:
  /// **'Nothing answered after the clear was sent, so it is not known whether the vehicle cleared. Rescan to check. Do not send another clear blindly.'**
  String get dtcClearTimeout;

  /// DtcClearNoticeKind.unexpected. Must not interpolate a Dart exception into the sentence a driver reads at a car.
  ///
  /// In en, this message translates to:
  /// **'The clear failed, so it is not known whether the vehicle cleared. Rescan to check. Do not send another clear blindly.'**
  String get dtcClearUnexpected;

  /// No description provided for @dtcClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing…'**
  String get dtcClearing;

  /// DtcScanBanner.disconnectedMidScan. A failed refresh must not leave a previous all-clear standing.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped during the scan, so this scan did not finish.'**
  String get dtcScanDisconnectedMidScan;

  /// DtcScanBanner.interrupted. An unnamed absence and a timeout look identical otherwise.
  ///
  /// In en, this message translates to:
  /// **'The scan was interrupted (the app may have been backgrounded, or the connection changed) and did not get a complete result. Scan again.'**
  String get dtcScanInterrupted;

  /// A controller whose reply is lost outright leaves nothing to count as missing, and the app has no inventory of who should have answered.
  ///
  /// In en, this message translates to:
  /// **'That means every controller that replied reported no fault code. It does not mean every module on the vehicle was asked.'**
  String get dtcCompleteCleanBody;

  /// 'that answered' is the whole hedge. Never render this as 'no fault codes' or 'your car is fine'.
  ///
  /// In en, this message translates to:
  /// **'None of the controllers that answered reported a fault code.'**
  String get dtcCompleteCleanTitle;

  /// Attribution for a reply that carried a header. Two modules reporting one code is two of them seeing the fault.
  ///
  /// In en, this message translates to:
  /// **'Controller {controller}'**
  String dtcControllerLabel(Object controller);

  /// Tooltip that closes the clear-outcome panel. Closing a message is not learning what happened; only a rescan is.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dtcDismiss;

  /// Names the code in the card itself: a car with three stored codes has a frame belonging to exactly one of them.
  ///
  /// In en, this message translates to:
  /// **'The values this controller recorded at the instant {code} was confirmed. Clearing fault codes destroys this record with them.'**
  String dtcFreezeFrameBody(Object code);

  /// 'It would not tell us' — worth another scan. Distinct from dtcFreezeFrameNothingDecodable, which is a limit of this app.
  ///
  /// In en, this message translates to:
  /// **'This controller has a freeze frame, but it did not answer the query asking which items are in it, so the contents could not be read. A rescan may work.'**
  String get dtcFreezeFrameContentsUnknown;

  /// No description provided for @dtcFreezeFrameNothingDecodable.
  ///
  /// In en, this message translates to:
  /// **'This controller has a freeze frame, but none of the items in it are ones this app can decode.'**
  String get dtcFreezeFrameNothingDecodable;

  /// The only view of the car while the fault was actually happening, and the one thing a clear destroys for good.
  ///
  /// In en, this message translates to:
  /// **'The vehicle at the moment of the fault'**
  String get dtcFreezeFrameTitle;

  /// An app limitation that rescanning will not change. Must stay distinct from dtcFreezeFrameUnreadItems, which rescanning usually fixes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A further item in this freeze frame has no conversion formula in this app, so it is not listed.} other{{count} further items in this freeze frame have no conversion formula in this app, so they are not listed.}}'**
  String dtcFreezeFrameUndecodable(int count);

  /// A read failure, not an app limitation. Rescanning usually fixes it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One item did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read it.} other{{count} items did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read them.}}'**
  String dtcFreezeFrameUnreadItems(int count);

  /// A controller with no stored frame shows nothing, which is exactly what a failed read shows. Saying so is the only thing standing between a Mode 02 timeout and a clear.
  ///
  /// In en, this message translates to:
  /// **'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear the fault codes, because clearing destroys the record of the moment of the fault permanently. If every scan looks the same, this vehicle may not provide one.'**
  String get dtcFreezeFrameUnreadPanel;

  /// Heading for one class of codes. {label} still comes from lib/obd/dtc/dtc.dart and is Chinese in both locales until the engine wave lands.
  ///
  /// In en, this message translates to:
  /// **'{label} (Mode {mode}) · {count}'**
  String dtcGroupHeader(Object label, Object mode, int count);

  /// Fault-code screen title.
  ///
  /// In en, this message translates to:
  /// **'Fault codes'**
  String get dtcHeadline;

  /// Joins fault codes, categories or controller ids in a sentence. Chinese uses the enumeration comma; English uses a comma and a space.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get dtcListSeparator;

  /// Shown instead of a description this app does not have. Never invent one.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer-specific code — check the service manual for this vehicle'**
  String get dtcManufacturerSpecific;

  /// No description provided for @dtcMilOff.
  ///
  /// In en, this message translates to:
  /// **'The fault lamp is not lit'**
  String get dtcMilOff;

  /// No description provided for @dtcMilOn.
  ///
  /// In en, this message translates to:
  /// **'The fault lamp is lit'**
  String get dtcMilOn;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Compression ignition (diesel) only.
  ///
  /// In en, this message translates to:
  /// **'Boost pressure'**
  String get dtcMonitorBoostPressure;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol).
  ///
  /// In en, this message translates to:
  /// **'Catalyst'**
  String get dtcMonitorCatalyst;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. A continuous monitor; J1979 calls it the comprehensive component monitor.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive components'**
  String get dtcMonitorComponents;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. EGR and VVT are on docs/i18n/do-not-translate.md; keep both acronyms and the slash.
  ///
  /// In en, this message translates to:
  /// **'EGR / VVT system'**
  String get dtcMonitorEgr;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol). The evaporative emission system, not the exhaust.
  ///
  /// In en, this message translates to:
  /// **'Evaporative system'**
  String get dtcMonitorEvaporative;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Compression ignition (diesel) only.
  ///
  /// In en, this message translates to:
  /// **'Exhaust sensor'**
  String get dtcMonitorExhaustSensor;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. A continuous monitor.
  ///
  /// In en, this message translates to:
  /// **'Fuel system'**
  String get dtcMonitorFuelSystem;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. LOAD-BEARING: many OBD reference tables name bit 4 of byte C an air-conditioning refrigerant monitor. That is wrong — the bit sat Reserved in J1979 for years and was recently defined as the gasoline particulate filter, and no car that sets it has an A/C refrigerant monitor at all. Keep GPF spelled out; never render this as refrigerant or air conditioning (docs/field-guide.zh-TW.md:247-250).
  ///
  /// In en, this message translates to:
  /// **'Gasoline particulate filter (GPF)'**
  String get dtcMonitorGasolineParticulateFilter;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol).
  ///
  /// In en, this message translates to:
  /// **'Heated catalyst'**
  String get dtcMonitorHeatedCatalyst;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. A continuous monitor.
  ///
  /// In en, this message translates to:
  /// **'Misfire'**
  String get dtcMonitorMisfire;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Compression ignition (diesel) only. NMHC is on docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'NMHC catalyst'**
  String get dtcMonitorNmhcCatalyst;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Compression ignition (diesel) only. NOx and SCR are on docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'NOx / SCR aftertreatment'**
  String get dtcMonitorNoxAftertreatment;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol).
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor'**
  String get dtcMonitorOxygenSensor;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol). The heater circuit, which is monitored separately from the sensor itself.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor heater'**
  String get dtcMonitorOxygenSensorHeater;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Compression ignition (diesel) only — the diesel particulate filter. Distinct from dtcMonitorGasolineParticulateFilter, which is the petrol bit.
  ///
  /// In en, this message translates to:
  /// **'Particulate filter'**
  String get dtcMonitorParticulateFilter;

  /// One of the SAE J1979 emissions readiness monitors, drawn as a chip under dtcReadinessTitle. Spark ignition (petrol).
  ///
  /// In en, this message translates to:
  /// **'Secondary air system'**
  String get dtcMonitorSecondaryAir;

  /// The subsystem the code's own third digit names. Says the app is missing the description rather than pretending to one.
  ///
  /// In en, this message translates to:
  /// **'{subsystem} — this app has no detailed description for this code'**
  String dtcNoDescriptionForSubsystem(Object subsystem);

  /// No description provided for @dtcNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Reading fault codes needs a connected ELM327 adapter, or the simulator running.'**
  String get dtcNotConnectedBody;

  /// No description provided for @dtcNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get dtcNotConnectedTitle;

  /// No description provided for @dtcNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get dtcNotScanned;

  /// Modes 07 and 0A are optional in SAE J1979. A vehicle that implements neither is compliant and fine; that is a different situation from a class nobody answered.
  ///
  /// In en, this message translates to:
  /// **'All three categories were queried to completion. {count, plural, =1{One controller} other{{count} controllers}} ({controllers}) implement neither pending nor permanent fault codes — normal on many vehicles, and also why this cannot be declared a fault-free vehicle.'**
  String dtcPartialCleanOptionalGaps(int count, Object controllers);

  /// No description provided for @dtcPartialCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'The categories that answered reported no fault codes.'**
  String get dtcPartialCleanTitle;

  /// No description provided for @dtcPartialCleanUnanswered.
  ///
  /// In en, this message translates to:
  /// **'{categories} did not answer, so their state cannot be confirmed — that is not the same as the vehicle having no problem.'**
  String dtcPartialCleanUnanswered(Object categories);

  /// Incomplete coverage is a reason to qualify a finding, never to hide it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One fault code was read} other{{count} fault codes were read}} before this category stopped, but the coverage is incomplete:'**
  String dtcPartialCodesRead(int count);

  /// {message} is the engine's own failure text and is still Chinese in both locales.
  ///
  /// In en, this message translates to:
  /// **'Only some controllers in this category answered and the rest did not reply, so this cannot stand as a result for the whole vehicle. {message}'**
  String dtcPartiallyAnsweredDetail(Object message);

  /// Two call sites, one sentence: the empty-state title after a failed scan, and the headline of a category whose read errored rather than went silent.
  ///
  /// In en, this message translates to:
  /// **'Read failed'**
  String get dtcReadFailed;

  /// No description provided for @dtcReadFailureDetail.
  ///
  /// In en, this message translates to:
  /// **'{label} (Mode {mode}): {message}'**
  String dtcReadFailureDetail(Object label, Object mode, Object message);

  /// No description provided for @dtcReadinessAllComplete.
  ///
  /// In en, this message translates to:
  /// **'Every readiness monitor this controller is responsible for is complete.'**
  String get dtcReadinessAllComplete;

  /// Counts monitors this app cannot name as well, so one left unfinished still blocks 'ready'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 monitor is still unfinished} other{{count} monitors are still unfinished}} — an inspection now may not pass.'**
  String dtcReadinessIncomplete(int count);

  /// A module outside emissions monitoring answers with all zeroes. Reading that as a clean bill of health turns silence into an answer.
  ///
  /// In en, this message translates to:
  /// **'This controller reported no readiness monitors at all — it may not be responsible for emissions monitoring, and that does not mean it is ready.'**
  String get dtcReadinessSaysNothing;

  /// No description provided for @dtcReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Emissions readiness'**
  String get dtcReadinessTitle;

  /// Label of the disabled clear button. The button IS the verdict of the last clear: something may already have been erased, so a second global Mode 04 would reset a completed controller's readiness. Keep it an imperative.
  ///
  /// In en, this message translates to:
  /// **'Rescan first'**
  String get dtcRescanFirst;

  /// Retries the fault-code scan. Deliberately not shared with startupRetry: the two screens are free to reword independently.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dtcRetry;

  /// The three classes are three different things and must stay distinguishable.
  ///
  /// In en, this message translates to:
  /// **'Reads Mode 03 stored, Mode 07 pending and Mode 0A permanent fault codes.'**
  String get dtcScanBody;

  /// No description provided for @dtcScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the vehicle for fault codes'**
  String get dtcScanTitle;

  /// No description provided for @dtcScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get dtcScanning;

  /// The controller's own claim, which can contradict what Mode 03 returned. Keep it attributed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This controller self-reports 1 confirmed fault code.} other{This controller self-reports {count} confirmed fault codes.}}'**
  String dtcSelfReportedCodes(int count);

  /// No description provided for @dtcSelfReportedNoCodes.
  ///
  /// In en, this message translates to:
  /// **'This controller self-reports no confirmed fault codes.'**
  String get dtcSelfReportedNoCodes;

  /// Not 'this vehicle does not provide the category'. NO DATA cannot tell an unimplemented service from a lost, filtered or late reply.
  ///
  /// In en, this message translates to:
  /// **'This category did not answer'**
  String get dtcSilentCategoryHeadline;

  /// Distinct from dtcSilentPermanentDetail on purpose. Telling a driver their 2004 car is too old for pending codes is simply wrong.
  ///
  /// In en, this message translates to:
  /// **'Pending fault codes (Mode 07) did not answer. This ECU may not implement the service, or it may simply not have been read this time — no answer cannot tell the two apart, and must not be taken to mean there are no pending faults. The stored fault-code result is unaffected.'**
  String get dtcSilentPendingDetail;

  /// Mode 07 and Mode 0A are not the same feature and must not share a sentence: pending codes date from 1996, permanent codes from around 2010.
  ///
  /// In en, this message translates to:
  /// **'Permanent fault codes (Mode 0A) did not answer. This category arrived with the OBD-II generation around 2010, so older vehicles do not always support it — but no answer can equally mean it simply was not read this time, and the two cannot be told apart. The stored fault-code result is unaffected.'**
  String get dtcSilentPermanentDetail;

  /// No description provided for @dtcStartScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get dtcStartScan;

  /// Mode 03 is mandatory, so silence here is never ordinary.
  ///
  /// In en, this message translates to:
  /// **'The vehicle did not answer the Mode {mode} query, so whether it has stored fault codes cannot be confirmed. That is not the same thing as having no fault codes.'**
  String dtcStoredSilentDetail(Object mode);

  /// Count of observed codes, including partial reads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code} other{{count} codes}}'**
  String dtcTotalCodes(int count);

  /// Two call sites, one sentence: the header subtitle for any other verdict, and the headline of a category that failed to answer. Must never be read as 'no problem'.
  ///
  /// In en, this message translates to:
  /// **'Cannot confirm'**
  String get dtcUnconfirmed;

  /// No description provided for @dtcUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get dtcUnknownError;

  /// A readiness monitor the vehicle reported and this app has no name for. It is still counted as unfinished — not being able to name it is not permission to discount it. Never 'N/A' or 'other'.
  ///
  /// In en, this message translates to:
  /// **'Unknown monitor'**
  String get dtcUnknownMonitor;

  /// Header subtitle for ScanVerdict.completeClean. The qualifier 'that answered' is the whole hedge: this is the line a glance lands on, and it must never read as 'this vehicle has no faults'.
  ///
  /// In en, this message translates to:
  /// **'No fault codes from the controllers that answered'**
  String get dtcVerdictCompleteClean;

  /// ScanVerdict.partialClean. Some categories could not be read, so the verdict is incomplete. Keep it short and distinct from dtcUnconfirmed; never merge the two into one 'unknown'.
  ///
  /// In en, this message translates to:
  /// **'Partially unconfirmed'**
  String get dtcVerdictPartialClean;

  /// Safety copy. 'attempted' is load-bearing: the save can fail, and fieldEventMemoryOnly is what the user sees when it does.
  ///
  /// In en, this message translates to:
  /// **'Press only when the vehicle is fully stopped, by a passenger or by an operator who is parked. Events share one timeline with the raw OBD data, and an immediate save is attempted.'**
  String get fieldEventBody;

  /// No description provided for @fieldEventEngineStarted.
  ///
  /// In en, this message translates to:
  /// **'Engine started'**
  String get fieldEventEngineStarted;

  /// No description provided for @fieldEventHeading.
  ///
  /// In en, this message translates to:
  /// **'Field event markers'**
  String get fieldEventHeading;

  /// No description provided for @fieldEventIgnitionOn.
  ///
  /// In en, this message translates to:
  /// **'Ignition on'**
  String get fieldEventIgnitionOn;

  /// Must not read as saved. The event exists only in memory, so the remedy is immediate and explicit.
  ///
  /// In en, this message translates to:
  /// **'Recorded in this session, but the automatic save failed — export the transcript now.'**
  String get fieldEventMemoryOnly;

  /// Both halves are claims: the event is in the session AND it reached storage.
  ///
  /// In en, this message translates to:
  /// **'Recorded and saved: {marker}'**
  String fieldEventRecorded(String marker);

  /// No description provided for @fieldEventRoadTestStarted.
  ///
  /// In en, this message translates to:
  /// **'Road test started'**
  String get fieldEventRoadTestStarted;

  /// No description provided for @fieldEventThrottleBlip.
  ///
  /// In en, this message translates to:
  /// **'Throttle blip'**
  String get fieldEventThrottleBlip;

  /// No description provided for @fieldEventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'There is no live vehicle connection to record against.'**
  String get fieldEventUnavailable;

  /// Spoken and shown when a dial has no value at all. Not zero, and not unsupported.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get gaugeNoData;

  /// A dial with no value leads with the reason, because that is the whole of what there is to say. {reason} is the footnote already on screen (formula error, bus error, no answer) and each stays distinct.
  ///
  /// In en, this message translates to:
  /// **'No data — {reason}'**
  String gaugeNoDataBecause(String reason);

  /// Screen-reader value for a dial whose number is real and whose age is the qualification. The number stays; the parenthetical says it stopped arriving.
  ///
  /// In en, this message translates to:
  /// **'{reading} (data is stale)'**
  String gaugeReadingStale(String reading);

  /// PidFault.unsupported only: the controller answered, and the answer said unsupported. Never use it for silence - that is telemetryStatusNoAnswer. It names the vehicle on purpose: the app's own refusal to transmit reads completely differently (telemetryStatusUnsafeServiceRefusal), and this tile must not be read as Telltale declining. It shares a square tile about 122dp wide with the availability badge, so anything longer needs re-measuring against test/l10n/dashboard_l10n_test.dart.
  ///
  /// In en, this message translates to:
  /// **'Not supported by this vehicle'**
  String get gaugeUnsupportedByVehicle;

  /// InitNote.aborted. The remaining steps were not attempted, which is not the same as their having failed.
  ///
  /// In en, this message translates to:
  /// **'Stopped after an earlier step failed.'**
  String get handshakeNoteAborted;

  /// InitNote.ecuRefusedSupportQuery. A refusal is an answer: something is on the bus. Distinct from handshakeNoteEcuSilent.
  ///
  /// In en, this message translates to:
  /// **'The ECU refused the support query (negative response).'**
  String get handshakeNoteEcuRefusedSupportQuery;

  /// InitNote.ecuSilent. 0100 is the only step that proves a vehicle is on the bus; every AT command answers happily with the ignition off.
  ///
  /// In en, this message translates to:
  /// **'The ECU did not answer.'**
  String get handshakeNoteEcuSilent;

  /// InitNote.notAcknowledged. The reply printed no error but never said OK either, and 'printed no error' is a much weaker claim than 'answered correctly'.
  ///
  /// In en, this message translates to:
  /// **'The adapter did not acknowledge this command.'**
  String get handshakeNoteNotAcknowledged;

  /// InitNote.notModeOnePositiveReply. Mode 01 is on docs/i18n/do-not-translate.md.
  ///
  /// In en, this message translates to:
  /// **'The reply is not a Mode 01 positive response.'**
  String get handshakeNoteNotModeOnePositiveReply;

  /// InitNote.pidEchoMismatch. Accepting it would build the supported-PID set out of bytes that answer a different question.
  ///
  /// In en, this message translates to:
  /// **'The reply echoes a different PID from the one that was asked for.'**
  String get handshakeNotePidEchoMismatch;

  /// InitNote.supportMaskTooShort. The hex bytes are wire values and are never translated.
  ///
  /// In en, this message translates to:
  /// **'The support reply is too short; 41 00 and four more bytes are required.'**
  String get handshakeNoteSupportMaskTooShort;

  /// InitNote.timedOut. Silence within the window, not a refusal and not a capability claim.
  ///
  /// In en, this message translates to:
  /// **'Timed out.'**
  String get handshakeNoteTimedOut;

  /// No description provided for @handshakeStepAdapterVersion.
  ///
  /// In en, this message translates to:
  /// **'Read the adapter version'**
  String get handshakeStepAdapterVersion;

  /// ATAT1. The app sends AT1 rather than the more aggressive AT2, which shortens the window an ECU has to answer; see docs/protocol-deviations.zh-TW.md.
  ///
  /// In en, this message translates to:
  /// **'Enable adaptive timing, the setting the datasheet recommends'**
  String get handshakeStepAdaptiveTiming;

  /// No description provided for @handshakeStepBatteryVoltage.
  ///
  /// In en, this message translates to:
  /// **'Read the battery voltage'**
  String get handshakeStepBatteryVoltage;

  /// No description provided for @handshakeStepDeviceIdentity.
  ///
  /// In en, this message translates to:
  /// **'Read the device identifier string'**
  String get handshakeStepDeviceIdentity;

  /// ATE0. An echoed command is valid hex that prepends bytes to a reading, which is why this step is critical.
  ///
  /// In en, this message translates to:
  /// **'Turn off command echo'**
  String get handshakeStepEchoOff;

  /// No description provided for @handshakeStepLinefeedsOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off linefeeds'**
  String get handshakeStepLinefeedsOff;

  /// No description provided for @handshakeStepMemoryOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off memory writes'**
  String get handshakeStepMemoryOff;

  /// Stands in when a failed step reported nothing at all about why. Not a claim that the vehicle lacks something — only that this step said nothing.
  ///
  /// In en, this message translates to:
  /// **'no response'**
  String get handshakeStepNoReason;

  /// ATSP0. Nothing downstream works without a protocol, which is why this step is critical.
  ///
  /// In en, this message translates to:
  /// **'Detect the bus protocol automatically'**
  String get handshakeStepProtocolAuto;

  /// No description provided for @handshakeStepProtocolDescription.
  ///
  /// In en, this message translates to:
  /// **'Read the protocol description'**
  String get handshakeStepProtocolDescription;

  /// No description provided for @handshakeStepProtocolNumber.
  ///
  /// In en, this message translates to:
  /// **'Read the protocol number'**
  String get handshakeStepProtocolNumber;

  /// No description provided for @handshakeStepReset.
  ///
  /// In en, this message translates to:
  /// **'Software-reset the adapter'**
  String get handshakeStepReset;

  /// ATST66. The figure is what the command means (0x66 timer units of 4 ms), not a constant the code enforces elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Set the response timeout to about 408 ms'**
  String get handshakeStepResponseTimeout;

  /// No description provided for @handshakeStepSpacesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off spaces, cutting a third of the traffic'**
  String get handshakeStepSpacesOff;

  /// 0100. The only step that proves a VEHICLE is there: every AT command answers with the ignition off and this one does not. Both halves of the sentence are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'Ask which PIDs the ECU supports, proving a vehicle answered'**
  String get handshakeStepSupportProbe;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Try again.'**
  String get languageSaveFailed;

  /// Bilingual label for the language picker. Options use self-names.
  ///
  /// In en, this message translates to:
  /// **'Language / 語言'**
  String get languageSectionTitle;

  /// Bottom-navigation and rail destination. On screen on every screen, in a five-tab bar; a label that does not fit is ellipsised by the framework, so keep it short enough to render whole at 360dp.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Navigation destination for the fault-code screen. 'Fault codes' is the spelled-out term the README and glossary use; DTC stays available as the acronym elsewhere. It measures inside the 72dp a fifth of a 360dp bar allows, so the long form ships.
  ///
  /// In en, this message translates to:
  /// **'Fault codes'**
  String get navDtc;

  /// Navigation destination for the acceleration-timing screen, which times 0 to a target speed. NOT 'Performance': measured in the shipped SpaceGrotesk at 12sp it wants 78.8dp against the 72dp a fifth of a 360dp bar allows, so it would render as 'Performanc…' — and a truncated label is worse than a shorter true one. 'Timing' is what the screen does.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get navPerformance;

  /// Navigation destination for the PID manager. PID is an SAE J1979 term and is not translated in either language.
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get navPid;

  /// Navigation destination for Settings. Separate from settingsHeadline: a tab label has a width budget a headline does not.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @performanceArm.
  ///
  /// In en, this message translates to:
  /// **'Arm the timer'**
  String get performanceArm;

  /// Load-bearing hedge. Both halves must survive translation: indicative only, AND not equivalent to professional test equipment. The ranges describe vehicles and adapters, not a constant this app enforces, so they stay in the prose.
  ///
  /// In en, this message translates to:
  /// **'Times come from the OBD road-speed signal. Most vehicles read 1–3 km/h high on their own speedometer, and the signal updates only about 10–20 times a second, so a result here is indicative only — not equivalent to professional test equipment.'**
  String get performanceDisclaimer;

  /// Performance screen title. The screen times a run; it never states a vehicle's rated performance.
  ///
  /// In en, this message translates to:
  /// **'Acceleration test'**
  String get performanceHeadline;

  /// PID 010D is an adapter-facing token and stays byte-identical in every language.
  ///
  /// In en, this message translates to:
  /// **'There is no valid road-speed signal right now (PID 010D). The acceleration test cannot time a run without it.'**
  String get performanceNoSpeedSignal;

  /// No description provided for @performanceNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'The acceleration test needs live road speed. Connect an adapter, or start the built-in simulator.'**
  String get performanceNotConnectedBody;

  /// No description provided for @performanceNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get performanceNotConnectedTitle;

  /// No description provided for @performancePeakSpeed.
  ///
  /// In en, this message translates to:
  /// **'Peak speed'**
  String get performancePeakSpeed;

  /// No description provided for @performanceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get performanceReset;

  /// No description provided for @performanceSecondsUnit.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get performanceSecondsUnit;

  /// No description provided for @performanceSpeedGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get performanceSpeedGaugeLabel;

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

  /// An incomplete run whose partial evidence is kept. Must never read as a finished time.
  ///
  /// In en, this message translates to:
  /// **'The speed signal stopped — this run was not completed; below is what was recorded before it went'**
  String get performanceStateAborted;

  /// No speed reading at all. Distinct from a reading that says the car is moving — the app cannot tell yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a speed signal'**
  String get performanceStateAwaitingSpeedSignal;

  /// {speed} is the live road speed, already formatted by the caller. Units never change with language.
  ///
  /// In en, this message translates to:
  /// **'Come to a complete stop first — now {speed} km/h'**
  String performanceStateAwaitingStandstill(String speed);

  /// {target} is the selected target speed from the screen's own list, never spelled into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Finished 0 → {target} km/h'**
  String performanceStateFinished(int target);

  /// No description provided for @performanceStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Pick a target speed, then start'**
  String get performanceStateIdle;

  /// No description provided for @performanceStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get performanceStateRunning;

  /// No description provided for @performanceStateStaged.
  ///
  /// In en, this message translates to:
  /// **'Ready — the clock starts when you move off'**
  String get performanceStateStaged;

  /// Says what the number is: one timed run beginning at rest. Not a manufacturer figure, not a rating.
  ///
  /// In en, this message translates to:
  /// **'A timed run from a standing start to a target speed'**
  String get performanceSubhead;

  /// No description provided for @performanceTargetSpeedHeading.
  ///
  /// In en, this message translates to:
  /// **'Target speed'**
  String get performanceTargetSpeedHeading;

  /// No description provided for @pidActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pidActionCancel;

  /// No description provided for @pidActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pidActionDelete;

  /// No description provided for @pidArrangeBody.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. The dashboard fills left to right and top to bottom, so whatever is first is seen first.'**
  String get pidArrangeBody;

  /// No description provided for @pidArrangeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable a few in the list first, then come back to order them.'**
  String get pidArrangeEmptyMessage;

  /// No description provided for @pidArrangeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No PID is enabled yet'**
  String get pidArrangeEmptyTitle;

  /// No description provided for @pidBulkActionAddConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Add the {count} confirmed'**
  String pidBulkActionAddConfirmed(int count);

  /// No description provided for @pidBulkActionAllActive.
  ///
  /// In en, this message translates to:
  /// **'All already enabled'**
  String get pidBulkActionAllActive;

  /// No description provided for @pidBulkActionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Scan data is incomplete'**
  String get pidBulkActionIncomplete;

  /// No description provided for @pidBulkActionLocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot change while recording'**
  String get pidBulkActionLocked;

  /// No description provided for @pidBulkActionPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for scan results'**
  String get pidBulkActionPending;

  /// Nothing was confirmed. Not a claim that the vehicle supports nothing.
  ///
  /// In en, this message translates to:
  /// **'No confirmed supported PIDs'**
  String get pidBulkActionZero;

  /// No description provided for @pidBulkAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String pidBulkAddCount(int count);

  /// No description provided for @pidBulkAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {count} confirmed supported PIDs?'**
  String pidBulkAddDialogTitle(int count);

  /// No description provided for @pidBulkAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} confirmed supported PIDs.'**
  String pidBulkAdded(int count);

  /// Both halves are load-bearing: still unconfirmed, AND only positively evidenced items are added.
  ///
  /// In en, this message translates to:
  /// **'{count} support blocks are still unconfirmed — this adds only the items with positive evidence.'**
  String pidBulkUnconfirmedBlocks(int count);

  /// 'may refresh less often' is a hedge; the scheduler makes no promise about a rate.
  ///
  /// In en, this message translates to:
  /// **'Will add {count}. The more PIDs are enabled, the less often each one may refresh.'**
  String pidBulkWillAdd(int count);

  /// No description provided for @pidCapabilityConfirmedCount.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} confirmed'**
  String pidCapabilityConfirmedCount(int confirmed);

  /// No description provided for @pidCapabilityCoverageNone.
  ///
  /// In en, this message translates to:
  /// **'No contiguous coverage established yet'**
  String get pidCapabilityCoverageNone;

  /// {through} is a hex PID number and is never localized.
  ///
  /// In en, this message translates to:
  /// **'Contiguous coverage 01–{through} (reached the end)'**
  String pidCapabilityCoverageThroughEnd(String through);

  /// Unknown beyond that point, not absent beyond it.
  ///
  /// In en, this message translates to:
  /// **'Contiguous coverage 01–{through} (unknown beyond)'**
  String pidCapabilityCoverageThroughUnknown(String through);

  /// Scoped to this attempt. Never 'scan complete', which would read as full coverage.
  ///
  /// In en, this message translates to:
  /// **'This support scan finished'**
  String get pidCapabilityPhaseAttemptFinished;

  /// No description provided for @pidCapabilityPhaseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The support scan was interrupted'**
  String get pidCapabilityPhaseInterrupted;

  /// No description provided for @pidCapabilityPhaseNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Scan not started'**
  String get pidCapabilityPhaseNotStarted;

  /// No description provided for @pidCapabilityPhaseRunning.
  ///
  /// In en, this message translates to:
  /// **'Confirming what this vehicle supports'**
  String get pidCapabilityPhaseRunning;

  /// Screen-reader summary of the capability panel. {phase} is one of the pidCapabilityPhase* strings.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-supported PIDs. {phase}. {confirmed} confirmed. {unknown} unknown blocks.'**
  String pidCapabilitySemantics(String phase, int confirmed, int unknown);

  /// No description provided for @pidCapabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-supported PIDs'**
  String get pidCapabilityTitle;

  /// Unknown, never unsupported: these blocks were not read at all.
  ///
  /// In en, this message translates to:
  /// **'{unknown} unknown blocks'**
  String pidCapabilityUnknownBlocks(int unknown);

  /// A refusal that names the reason and the remedy. A generic 'invalid' would be a regression.
  ///
  /// In en, this message translates to:
  /// **'A custom PID already uses this combination ({name}). Use a different mode + PID, header, or name suffix.'**
  String pidEditorCollision(String name);

  /// {name} is the user's own PID name and passes through untranslated.
  ///
  /// In en, this message translates to:
  /// **'The definition for “{name}” is removed, its gauge disappears from the dashboard, and this cannot be undone.'**
  String pidEditorDeleteBody(String name);

  /// No description provided for @pidEditorDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this PID?'**
  String get pidEditorDeleteTitle;

  /// No description provided for @pidEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get pidEditorDiscard;

  /// No description provided for @pidEditorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The changes to this PID have not been saved, and leaving loses them.'**
  String get pidEditorDiscardBody;

  /// No description provided for @pidEditorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get pidEditorDiscardTitle;

  /// {valSyntax} carries the literal VAL{PID} token, which cannot be written inline because ARB reads braces as a placeholder.
  ///
  /// In en, this message translates to:
  /// **'A..N map to the response bytes; SIGNED(), ABS(), LOG10(), {valSyntax} and BARO are available'**
  String pidEditorEquationHelper(String valSyntax);

  /// No description provided for @pidEditorFieldEquation.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get pidEditorFieldEquation;

  /// No description provided for @pidEditorFieldHeader.
  ///
  /// In en, this message translates to:
  /// **'CAN header'**
  String get pidEditorFieldHeader;

  /// No description provided for @pidEditorFieldMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get pidEditorFieldMax;

  /// No description provided for @pidEditorFieldMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get pidEditorFieldMin;

  /// No description provided for @pidEditorFieldModeAndPid.
  ///
  /// In en, this message translates to:
  /// **'Mode + PID'**
  String get pidEditorFieldModeAndPid;

  /// No description provided for @pidEditorFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pidEditorFieldName;

  /// No description provided for @pidEditorFieldSample.
  ///
  /// In en, this message translates to:
  /// **'Test response bytes'**
  String get pidEditorFieldSample;

  /// No description provided for @pidEditorFieldShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name (shown on the gauge)'**
  String get pidEditorFieldShortName;

  /// No description provided for @pidEditorFieldUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get pidEditorFieldUnits;

  /// 7E0 is a CAN id and stays byte-identical.
  ///
  /// In en, this message translates to:
  /// **'7E0 = engine'**
  String get pidEditorHeaderHelper;

  /// No description provided for @pidEditorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get pidEditorKeepEditing;

  /// Mode and PID numbers are never localized.
  ///
  /// In en, this message translates to:
  /// **'For example 010C or 221101'**
  String get pidEditorModeAndPidHelper;

  /// No description provided for @pidEditorSampleHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter hex to preview the result as you type'**
  String get pidEditorSampleHelper;

  /// No description provided for @pidEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pidEditorSave;

  /// No description provided for @pidEditorSectionFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get pidEditorSectionFormula;

  /// No description provided for @pidEditorSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get pidEditorSectionIdentity;

  /// No description provided for @pidEditorSectionQuery.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get pidEditorSectionQuery;

  /// No description provided for @pidEditorSectionRangeAndPriority.
  ///
  /// In en, this message translates to:
  /// **'Gauge range and priority'**
  String get pidEditorSectionRangeAndPriority;

  /// No description provided for @pidEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit PID'**
  String get pidEditorTitleEdit;

  /// No description provided for @pidEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New custom PID'**
  String get pidEditorTitleNew;

  /// No description provided for @pidExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String pidExportFailed(String error);

  /// No description provided for @pidExportNoCustomPids.
  ///
  /// In en, this message translates to:
  /// **'There are no custom PIDs to export.'**
  String get pidExportNoCustomPids;

  /// No description provided for @pidImportNothingToImport.
  ///
  /// In en, this message translates to:
  /// **'No definitions to import.'**
  String get pidImportNothingToImport;

  /// PidImportOutcome snack when every counted row landed and nothing was skipped, replaced, or defaulted. {count} is landed = inserted + replaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 custom PID.} other{Imported {count} custom PIDs.}}'**
  String pidImportLandedClean(int count);

  /// PidImportOutcome snack when at least one note is present. {notes} is pidListSeparator-joined clauses; never spell the clauses into this sentence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 item, {notes}.} other{Imported {count} items, {notes}.}}'**
  String pidImportLandedWithNotes(int count, String notes);

  /// No description provided for @pidImportNoteSkippedRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row had problems and was skipped} other{{count} rows had problems and were skipped}}'**
  String pidImportNoteSkippedRows(int count);

  /// No description provided for @pidImportNoteDefaultedRanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row used the default gauge range} other{{count} rows used the default gauge range}}'**
  String pidImportNoteDefaultedRanges(int count);

  /// No description provided for @pidImportNoteReplaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item replaced an existing definition} other{{count} items replaced existing definitions}}'**
  String pidImportNoteReplaced(int count);

  /// No description provided for @pidImportNoteDuplicatesInFile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row duplicated another row in the file and was skipped} other{{count} rows duplicated another row in the file and were skipped}}'**
  String pidImportNoteDuplicatesInFile(int count);

  /// No description provided for @pidImportPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker.'**
  String get pidImportPickerFailed;

  /// No description provided for @pidImportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file.'**
  String get pidImportReadFailed;

  /// Separator for an inline list of machine tokens. English uses a comma and a space; Chinese uses the enumeration comma.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get pidListSeparator;

  /// Filter chip label; must stay short enough for a chip.
  ///
  /// In en, this message translates to:
  /// **'Enabled only'**
  String get pidManagerActiveOnly;

  /// No description provided for @pidManagerAdd.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get pidManagerAdd;

  /// No description provided for @pidManagerArrangeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Arrange dashboard'**
  String get pidManagerArrangeDashboard;

  /// Counts come from the active list and the registry; never spell a number into the sentence.
  ///
  /// In en, this message translates to:
  /// **'{active} enabled · {total} available'**
  String pidManagerCounts(int active, int total);

  /// No description provided for @pidManagerExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export custom PIDs'**
  String get pidManagerExportCsv;

  /// Screen title of the PID manager.
  ///
  /// In en, this message translates to:
  /// **'PID manager'**
  String get pidManagerHeadline;

  /// The CSV column headers themselves are a machine format and are never localized.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get pidManagerImportCsv;

  /// Tooltip on the overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get pidManagerMoreActions;

  /// No description provided for @pidManagerNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword, or create a custom PID.'**
  String get pidManagerNoMatchMessage;

  /// No description provided for @pidManagerNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching PID'**
  String get pidManagerNoMatchTitle;

  /// No description provided for @pidManagerPowertrainBatteryCatalog.
  ///
  /// In en, this message translates to:
  /// **'Powertrain-battery catalog'**
  String get pidManagerPowertrainBatteryCatalog;

  /// No description provided for @pidManagerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or PID code…'**
  String get pidManagerSearchHint;

  /// No description provided for @pidPickCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PID definition CSV'**
  String get pidPickCsvDialogTitle;

  /// No description provided for @pidPillCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get pidPillCustom;

  /// Only for a PID the vehicle positively disclaimed. Silence is never this.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get pidPillUnsupported;

  /// No description provided for @pidPreviewCannotEvaluate.
  ///
  /// In en, this message translates to:
  /// **'Cannot evaluate'**
  String get pidPreviewCannotEvaluate;

  /// No description provided for @pidPreviewResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get pidPreviewResultLabel;

  /// {value} comes from the editor's own stand-in constant; never spell the number into the sentence. An estimate stands in for a measurement here, and the sentence must keep saying so.
  ///
  /// In en, this message translates to:
  /// **'The preview substitutes {value} for {dependencies}; the real value comes from that PID once connected.'**
  String pidPreviewSubstituted(double value, String dependencies);

  /// No description provided for @pidPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get pidPreviewTitle;

  /// No description provided for @pidPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get pidPriorityHigh;

  /// No description provided for @pidPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get pidPriorityLow;

  /// No description provided for @pidPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get pidPriorityMedium;

  /// No description provided for @pidPriorityVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get pidPriorityVeryLow;

  /// No description provided for @pidRowEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get pidRowEdit;

  /// Semantics label for the row switch. {name} is user-authored data and passes through untouched.
  ///
  /// In en, this message translates to:
  /// **'Show {name} on the dashboard'**
  String pidRowShowOnDashboard(String name);

  /// Stale, not live. {units} is the definition's own unit text and is never translated.
  ///
  /// In en, this message translates to:
  /// **'{units} · stale'**
  String pidRowStaleUnits(String units);

  /// The per-connection scope is part of the sentence, not a footnote.
  ///
  /// In en, this message translates to:
  /// **'Battery signals for {profile} are on for this connection'**
  String powertrainAuthorizationGranted(String profile);

  /// No description provided for @powertrainAuthorizationRefused.
  ///
  /// In en, this message translates to:
  /// **'Could not enable: {reason}'**
  String powertrainAuthorizationRefused(String reason);

  /// No description provided for @powertrainCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get powertrainCancel;

  /// Both counts are derived from the verified catalog; never spell a number into the copy. English uses a label form because neither count has a fixed plurality.
  ///
  /// In en, this message translates to:
  /// **'Profiles: {profiles} · Experimental one-shot reads: {probeable}'**
  String powertrainCatalogCounts(int profiles, int probeable);

  /// Fail-closed: says what did NOT happen. Never soften to 'try again later'.
  ///
  /// In en, this message translates to:
  /// **'Integrity verification did not pass, so no vehicle data is shown or installed.'**
  String get powertrainCatalogLoadFailedBody;

  /// No description provided for @powertrainCatalogLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline catalog could not load'**
  String get powertrainCatalogLoadFailedTitle;

  /// No description provided for @powertrainCatalogNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The catalog has not passed verification, so nothing can be installed.'**
  String get powertrainCatalogNotVerified;

  /// No description provided for @powertrainCatalogRevalidate.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get powertrainCatalogRevalidate;

  /// Load-bearing: separates 'a candidate exists' from 'this works on your car'. Never drop either half.
  ///
  /// In en, this message translates to:
  /// **'The catalog is wide, but “we found data” is not “your car is supported”. Research-only entries never carry a command; experimental entries still read one command at a time, each after its own confirmation.'**
  String get powertrainCatalogScopeNote;

  /// No description provided for @powertrainCatalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search make, model, variant or market…'**
  String get powertrainCatalogSearchHint;

  /// App bar of the vehicle-specific traction-battery catalog.
  ///
  /// In en, this message translates to:
  /// **'Powertrain battery catalog'**
  String get powertrainCatalogTitle;

  /// Mirrors README.md: 'no identifier scan, batch, automatic retry'. The three negations are the promise.
  ///
  /// In en, this message translates to:
  /// **'One command per attempt: no scan, no batch, no automatic retry.'**
  String get powertrainChooseCommandNote;

  /// No description provided for @powertrainChooseCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one pinned read-only query'**
  String get powertrainChooseCommandTitle;

  /// No description provided for @powertrainClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get powertrainClose;

  /// No description provided for @powertrainConfirmAccept.
  ///
  /// In en, this message translates to:
  /// **'This is the car'**
  String get powertrainConfirmAccept;

  /// Installing makes definitions available; it does not say the car on the wire is that vehicle. The per-connection scope is the point — plugging into a different car must never inherit the grant.
  ///
  /// In en, this message translates to:
  /// **'Installed profile signals are read only after you confirm this car is that model, and the confirmation lasts for this connection alone.'**
  String get powertrainConfirmBody;

  /// No description provided for @powertrainConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm vehicle'**
  String get powertrainConfirmButton;

  /// Carries this project's organising principle into product copy: a plausible wrong number is worse than no number. Never soften 'look plausible and are wrong'.
  ///
  /// In en, this message translates to:
  /// **'Once confirmed, this profile\'s read-only battery queries are polled for the rest of this connection. The wrong profile can produce numbers that look plausible and are wrong — cancel if you are not sure.'**
  String get powertrainConfirmDialogBody;

  /// No description provided for @powertrainConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the connected vehicle'**
  String get powertrainConfirmDialogTitle;

  /// No description provided for @powertrainConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle battery signals await confirmation'**
  String get powertrainConfirmTitle;

  /// No description provided for @powertrainConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect first; experimental authorization is never kept across connections.'**
  String get powertrainConnectFirst;

  /// The acceptance was a statement about the vehicle on the wire at prompt time; it cannot carry over.
  ///
  /// In en, this message translates to:
  /// **'The connection changed — confirm the vehicle again for the new connection.'**
  String get powertrainConnectionChanged;

  /// No description provided for @powertrainEnableLabInSettings.
  ///
  /// In en, this message translates to:
  /// **'Turn on the experimental battery laboratory in Settings first.'**
  String get powertrainEnableLabInSettings;

  /// PowertrainProfileEvidence.physicalVehicle: a retained run this project performed. Still bounded to the recorded market, variant, adapter and conditions.
  ///
  /// In en, this message translates to:
  /// **'Project vehicle'**
  String get powertrainEvidencePhysicalVehicle;

  /// PowertrainProfileEvidence.sourceBacked: an external source supports the mapping. NOT evidence produced by Telltale on a vehicle.
  ///
  /// In en, this message translates to:
  /// **'Source data'**
  String get powertrainEvidenceSourceBacked;

  /// PowertrainProfileEvidence.syntheticRig: a deterministic simulator exercised the path. Establishes nothing about a real ECU.
  ///
  /// In en, this message translates to:
  /// **'Synthetic rig'**
  String get powertrainEvidenceSyntheticRig;

  /// Four load-bearing claims: candidate not guarantee; the transcript keeps it locally; nothing is auto-uploaded; nothing is installed or shown on a gauge. Cancelling is safe. Dropping any clause changes what the driver is consenting to.
  ///
  /// In en, this message translates to:
  /// **'This is a candidate read labelled by the source\'s authors, not a manufacturer or cross-model safety guarantee; ELM327 only forwards the command. The raw command and reply stay in the local diagnostic transcript and are not uploaded automatically by this feature; decoded values are never installed as a PID or added to a gauge. Cancelling does not affect ordinary OBD functions.'**
  String get powertrainExperimentalDataDisclosure;

  /// No description provided for @powertrainExperimentalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot experimental read-only confirmation'**
  String get powertrainExperimentalDialogTitle;

  /// 'the source knows' is the hedge: the source's identity evidence, not a confirmed match.
  ///
  /// In en, this message translates to:
  /// **'I have checked the market, model and model year the source knows, and I accept the unconfirmed fields'**
  String get powertrainExperimentalIdentityAck;

  /// Safety-critical. Keep both halves: parked, and the value may not apply.
  ///
  /// In en, this message translates to:
  /// **'The vehicle is safely parked; I understand this reads once and the number may still not apply'**
  String get powertrainExperimentalParkedAck;

  /// RX, the CAN responder id and the unit 'bytes' are never translated.
  ///
  /// In en, this message translates to:
  /// **'Accepts RX {responder} only, payload length {bytes} bytes'**
  String powertrainExperimentalWireLine(String responder, int bytes);

  /// Joins the unconfirmed-field names. Chinese uses the enumeration comma U+3001, English a comma and a space; this is why it is a message and not a constant.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get powertrainFieldListSeparator;

  /// No description provided for @powertrainFieldMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get powertrainFieldMarket;

  /// No description provided for @powertrainFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get powertrainFieldModel;

  /// No description provided for @powertrainFieldModelYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get powertrainFieldModelYear;

  /// No description provided for @powertrainFieldVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get powertrainFieldVariant;

  /// The 'no powertrain filter' chip. The other chips are the acronyms PHEV, HEV, BEV, MHEV, REEV, FCEV and are never translated.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get powertrainFilterAll;

  /// PowertrainIdentityEvidenceLevel.exact. Evidence about the SOURCE record, not a match with the car in front of the driver.
  ///
  /// In en, this message translates to:
  /// **'direct evidence'**
  String get powertrainIdentityEvidenceExact;

  /// Fills 'Unconfirmed fields:' when every field has evidence. It says the LIST is empty, not that a field is unknown.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get powertrainIdentityEvidenceNone;

  /// PowertrainIdentityEvidenceLevel.sourcePartial. Partial is not confirmed; it must stay distinct from both exact and unknown.
  ///
  /// In en, this message translates to:
  /// **'partial evidence'**
  String get powertrainIdentityEvidenceSourcePartial;

  /// {fields} is a middle-dot list of 'field level' pairs; {unconfirmed} lists the fields the source could not establish, joined by powertrainFieldListSeparator.
  ///
  /// In en, this message translates to:
  /// **'Source identity evidence: {fields}\nUnconfirmed fields: {unconfirmed}'**
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed);

  /// PowertrainIdentityEvidenceLevel.unknown. The source said nothing about this field. Never render as 'not applicable' or 'none'.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get powertrainIdentityEvidenceUnknown;

  /// No description provided for @powertrainInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install battery signals'**
  String get powertrainInstallButton;

  /// No description provided for @powertrainInstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get powertrainInstallConfirm;

  /// No description provided for @powertrainInstallDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Install this model\'s battery signals'**
  String get powertrainInstallDialogTitle;

  /// PowertrainProfileStatus.community. 'Independently corroborated' is a claim about sources agreeing, never about this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The data comes from community sources and has been independently corroborated; it is still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureCommunity;

  /// PowertrainProfileStatus.experimental. Three separate hedges: experimental, no corroboration requirement, unverified on this vehicle. Dropping any one of them overstates the tier.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This is an experimental decode with no independent-corroboration requirement, unverified on this vehicle, and still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureExperimental;

  /// PowertrainProfileStatus.ready. Whole sentence, not a shared prefix plus a fragment: English word order will not survive concatenation. The closing 'still not a manufacturer guarantee' is load-bearing in all four variants.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The source data is fuller; it is still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureReady;

  /// PowertrainProfileStatus.researchOnly. Must never read as installable or supported.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This entry is for research only and should not be installed.'**
  String get powertrainInstallDisclosureResearchOnly;

  /// PowertrainProfileInstallIssue.catalogShaMissing. Whole sentence, not a frame around the exception message.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: this catalog snapshot has no verified SHA-256, so nothing in it can be trusted.'**
  String get powertrainInstallCatalogShaMissing;

  /// PowertrainProfileInstallIssue.persistFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: the list of installed profiles could not be saved. Try again; nothing was added to PID management.'**
  String get powertrainInstallPersistFailed;

  /// PowertrainProfileInstallIssue.profileNotInCatalog.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: that profile is not in the verified catalog.'**
  String get powertrainInstallProfileNotInCatalog;

  /// PowertrainProfileInstallIssue.profileNotInstallable. Validation detail stays on the exception for diagnostics; the screen must not interpolate it.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: this profile is not in a state that can become live PIDs.'**
  String get powertrainInstallProfileNotInstallable;

  /// PowertrainProfileInstallIssue.yearOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: that model year is outside this profile\'s documented year range.'**
  String get powertrainInstallYearOutOfRange;

  /// No description provided for @powertrainInstallIdentityAck.
  ///
  /// In en, this message translates to:
  /// **'My vehicle matches the market, model and model year above'**
  String get powertrainInstallIdentityAck;

  /// No description provided for @powertrainInstalledRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Installed · remove signals'**
  String get powertrainInstalledRemoveButton;

  /// Installing is not authorizing: the per-connection vehicle confirmation is still required, and the sentence must keep saying so.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Installed 1 signal. Add it to the dashboard from the PID page; every connection needs a vehicle confirmation.} other{Installed {count} signals. Add them to the dashboard from the PID page; every connection needs a vehicle confirmation.}}'**
  String powertrainInstalledSignalsSnack(int count);

  /// No description provided for @powertrainNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a make or model name, or switch to another powertrain type.'**
  String get powertrainNoMatchBody;

  /// No description provided for @powertrainNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching vehicle'**
  String get powertrainNoMatchTitle;

  /// No description provided for @powertrainNotInstallableInThisRelease.
  ///
  /// In en, this message translates to:
  /// **'Not installable in this release'**
  String get powertrainNotInstallableInThisRelease;

  /// Source names and licence identifiers are identifiers and are never translated.
  ///
  /// In en, this message translates to:
  /// **'Primary source: {name} ({license})'**
  String powertrainPrimarySource(String name, String license);

  /// Names exactly the checks that ran. It is not a statement that the value is correct for this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Passed the responder, echo, exact length, formula and range checks.'**
  String get powertrainProbeChecksPassed;

  /// No description provided for @powertrainProbeConnectForOneShot.
  ///
  /// In en, this message translates to:
  /// **'Connect for a one-shot read-only query'**
  String get powertrainProbeConnectForOneShot;

  /// No description provided for @powertrainProbeConnectToTryOnce.
  ///
  /// In en, this message translates to:
  /// **'Connect to try one read first'**
  String get powertrainProbeConnectToTryOnce;

  /// Says what did NOT happen. An unfinished probe must never read as a failed vehicle.
  ///
  /// In en, this message translates to:
  /// **'The one-shot query did not finish; no value was published or kept.'**
  String get powertrainProbeDidNotFinish;

  /// No description provided for @powertrainProbeEnableLabFirst.
  ///
  /// In en, this message translates to:
  /// **'Turn on the laboratory in Settings first'**
  String get powertrainProbeEnableLabFirst;

  /// No description provided for @powertrainProbeInProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading once…'**
  String get powertrainProbeInProgress;

  /// No description provided for @powertrainProbeNoValuePublished.
  ///
  /// In en, this message translates to:
  /// **'No value was published; a structural or decode error is quarantined until you reconnect.'**
  String get powertrainProbeNoValuePublished;

  /// No description provided for @powertrainProbeOnceButton.
  ///
  /// In en, this message translates to:
  /// **'Read once only'**
  String get powertrainProbeOnceButton;

  /// No description provided for @powertrainProbePassedTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot query passed'**
  String get powertrainProbePassedTitle;

  /// No description provided for @powertrainProbePickOneRead.
  ///
  /// In en, this message translates to:
  /// **'Pick one command, read once'**
  String get powertrainProbePickOneRead;

  /// Disabled probe button after a structural-mismatch quarantine.
  ///
  /// In en, this message translates to:
  /// **'Reconnect, then try again'**
  String get powertrainProbeReconnectFirst;

  /// No description provided for @powertrainProbeRefusedTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot query refused'**
  String get powertrainProbeRefusedTitle;

  /// No description provided for @powertrainProbeTryOnceFirst.
  ///
  /// In en, this message translates to:
  /// **'Try one read first'**
  String get powertrainProbeTryOnceFirst;

  /// No description provided for @powertrainProfileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The profile is not in the verified catalog'**
  String get powertrainProfileNotVerified;

  /// Scoped to this connection, not permanent, and reconnecting is what lifts it. Kept to the pill width at 360dp: 'Quarantined for this connection' overflowed the card header row.
  ///
  /// In en, this message translates to:
  /// **'Quarantined · reconnect'**
  String get powertrainQuarantinedPill;

  /// Refusal identifier PowertrainProbeRefusal.catalogHashInvalid. One whole sentence: this used to be a localized frame around an untranslated one.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: the catalog\'s integrity hash is not valid, so nothing in it can be read.'**
  String get powertrainRefusedCatalogHashInvalid;

  /// Refusal identifier PowertrainProbeRefusal.commandNotInProfile.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: that command is not one of this verified profile\'s own commands.'**
  String get powertrainRefusedCommandNotInProfile;

  /// Refusal identifier PowertrainProbeRefusal.labClosed. Reached only when the laboratory is turned off between the screen's check and the authorization, so it says what changed rather than repeating powertrainEnableLabInSettings.
  ///
  /// In en, this message translates to:
  /// **'The experimental battery laboratory was switched off before this read could be authorized.'**
  String get powertrainRefusedLabClosed;

  /// Refusal identifier PowertrainProbeRefusal.profileFailedValidation. It replaces the validator's own English developer diagnostic, which named a JSON path.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: this profile did not pass catalog validation with the model year you chose.'**
  String get powertrainRefusedProfileFailedValidation;

  /// Refusal identifier PowertrainProbeRefusal.profileNotInCatalog.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: this profile is not in the verified catalog.'**
  String get powertrainRefusedProfileNotInCatalog;

  /// Refusal identifier PowertrainProbeRefusal.profileNotProbeable. The profile is structurally sound; its review tier is what refuses.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: this profile is not one that can be read once experimentally.'**
  String get powertrainRefusedProfileNotProbeable;

  /// Refusal identifier PowertrainProbeRefusal.quarantinedAfterRejectedRead. Which check failed was already shown in the probe result dialog when it happened.
  ///
  /// In en, this message translates to:
  /// **'Quarantined for this connection: an earlier one-shot read did not pass its structural checks. Reconnect before trying again.'**
  String get powertrainRefusedQuarantinedAfterRejectedRead;

  /// Refusal identifier PowertrainProbeRefusal.notConnectedOrNotInForeground. One sentence for both conditions because the engine tests them in one expression and refuses both the same way.
  ///
  /// In en, this message translates to:
  /// **'The one-shot read was not started: nothing is connected, or the app was not in the foreground.'**
  String get powertrainRefusedNotConnectedOrNotInForeground;

  /// Refusal identifier PowertrainProbeRefusal.noLiveAuthorization. Which of the four it was is not knowable at this point; the sentence says so rather than picking one.
  ///
  /// In en, this message translates to:
  /// **'The one-shot read was not started: no single-use authorization is being held. None was given, or it has expired, gone into cooldown, or been quarantined.'**
  String get powertrainRefusedNoLiveAuthorization;

  /// Refusal identifier PowertrainProbeRefusal.discardedAtLifecycleBoundary. It must not read as a failure: a result was deliberately not published, which is the opposite of the sentence this path used to show.
  ///
  /// In en, this message translates to:
  /// **'The connection or the foreground state changed while the one-shot read was running, so its answer was discarded instead of shown. Nothing failed, and nothing was kept.'**
  String get powertrainRefusedDiscardedAtLifecycleBoundary;

  /// Refusal identifier PowertrainProbeRefusal.quarantinedAtAttemptCap. {attemptCap} is PowertrainExperimentalProbeConsents.maxAttemptsPerCommand, never spelled into the copy.
  ///
  /// In en, this message translates to:
  /// **'Quarantined for this connection: the same command has already been tried {attemptCap} times. Reconnect before trying again.'**
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap);

  /// The permanently disabled button on a researchOnly row. It states a refusal, not a temporary unavailability.
  ///
  /// In en, this message translates to:
  /// **'Research only — never queries'**
  String get powertrainResearchOnlyNeverQueries;

  /// Retryable, and says so. Distinct from powertrainCatalogNotVerified, which is not retryable.
  ///
  /// In en, this message translates to:
  /// **'A storage error happened while restoring earlier installs. It has been rescheduled — try again.'**
  String get powertrainRestoreStorageErrorRetry;

  /// No description provided for @powertrainSecondarySource.
  ///
  /// In en, this message translates to:
  /// **'Independent corroboration: {name} ({license})'**
  String powertrainSecondarySource(String name, String license);

  /// Rendered inside a middle-dot separated provenance line. Label form in English so it is correct at any count.
  ///
  /// In en, this message translates to:
  /// **'Signals: {count}'**
  String powertrainSignalCount(int count);

  /// A truncated identifier the reader may paste into a search. Never translated, never reformatted.
  ///
  /// In en, this message translates to:
  /// **'Source file SHA-256: {hash}…'**
  String powertrainSourceSha256(String hash);

  /// PowertrainProfileStatus.community. Cross-corroborated by independent sources, still never driven by this project. Both halves are required. Shortened from 'Community data · unverified', which overflowed the card header at 360dp — a shorter true phrase, not an ellipsis that hides the tier.
  ///
  /// In en, this message translates to:
  /// **'Community · unverified'**
  String get powertrainStatusCommunity;

  /// PowertrainProfileStatus.experimental on a profile that can also be installed.
  ///
  /// In en, this message translates to:
  /// **'Experimental · unverified'**
  String get powertrainStatusExperimental;

  /// PowertrainProfileStatus.experimental on a profile that can only be read once, never installed. Kept short because the pill shares the card header row with the profile name at 360dp; 'Experimental · one-shot read-only' overflowed it. A shorter true phrase, never an ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Experimental · read once'**
  String get powertrainStatusExperimentalProbeOnly;

  /// PowertrainProfileStatus.ready. A claim about the SOURCE, not about the vehicle: it must never read as 'verified on your car'.
  ///
  /// In en, this message translates to:
  /// **'Fuller source data'**
  String get powertrainStatusReady;

  /// PowertrainProfileStatus.researchOnly. Metadata index with no commands. Must never read as installable or supported.
  ///
  /// In en, this message translates to:
  /// **'Research only'**
  String get powertrainStatusResearchOnly;

  /// {name} is the profile display name from the catalog; it is data and is not translated.
  ///
  /// In en, this message translates to:
  /// **'Removed the installed signals for {name}.'**
  String powertrainUninstalledSignalsSnack(String name);

  /// Shown when the profile covers exactly one year, so there is nothing to choose.
  ///
  /// In en, this message translates to:
  /// **'Model year: {year}'**
  String powertrainVehicleYearFixed(int year);

  /// No description provided for @powertrainVehicleYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get powertrainVehicleYearLabel;

  /// Commercial disclosure. Every qualifier is regulated copy: 'may pay' never 'will pay', 'not an adapter certification', 'not a purchase guarantee', and the instruction to check the model and NCC number before buying. Shortening any clause is a compliance change, not a style change.
  ///
  /// In en, this message translates to:
  /// **'This is a maintainer affiliate link; a qualifying purchase may pay the maintainer a commission. It is not an adapter certification or a purchase guarantee. Listing contents and hardware revisions can change, so check the full model number and NCC number before buying. You are also free to look for other sellers yourself.'**
  String get recommendedPurchaseDisclosure;

  /// No description provided for @recommendedPurchaseHeading.
  ///
  /// In en, this message translates to:
  /// **'Recommended adapter'**
  String get recommendedPurchaseHeading;

  /// {model} and {approval} are printed on the hardware and never translated.
  ///
  /// In en, this message translates to:
  /// **'Model {model} · NCC {approval}'**
  String recommendedPurchaseModelLine(String model, String approval);

  /// No description provided for @recommendedPurchaseNoAdapterYet.
  ///
  /// In en, this message translates to:
  /// **'No adapter yet? See the recommended one on {store}'**
  String recommendedPurchaseNoAdapterYet(String store);

  /// The panel never pretends a failed launch succeeded.
  ///
  /// In en, this message translates to:
  /// **'Could not open the {store} link'**
  String recommendedPurchaseOpenFailed(String store);

  /// No description provided for @recommendedPurchaseShortDisclosureAction.
  ///
  /// In en, this message translates to:
  /// **'Full disclosure in Settings'**
  String get recommendedPurchaseShortDisclosureAction;

  /// No description provided for @recommendedPurchaseShortDisclosureLead.
  ///
  /// In en, this message translates to:
  /// **'This is an affiliate link, not an adapter certification.'**
  String get recommendedPurchaseShortDisclosureLead;

  /// The storefront's own name. Shopee publishes as 蝦皮 in Taiwan and Shopee elsewhere, so each language gets the name its reader can read.
  ///
  /// In en, this message translates to:
  /// **'Shopee'**
  String get recommendedPurchaseStoreShopee;

  /// No description provided for @recommendedPurchaseViewOnStore.
  ///
  /// In en, this message translates to:
  /// **'View on {store}'**
  String recommendedPurchaseViewOnStore(String store);

  /// Joins the fields of a composed semantics label. Chinese uses the fullwidth comma; English must not, or a screen reader announces a fullwidth character.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get semanticsFieldSeparator;

  /// Distinguishes a self-description mismatch from a wrong reading.
  ///
  /// In en, this message translates to:
  /// **'These are places where the adapter\'s account of itself does not add up, not evidence that it misread the car. The only way to confirm a value is a second independent measurement (see the field guide).'**
  String get settingsAdapterConcernsFooter;

  /// Consistency is not a clean bill of health. Both negations are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'No self-description contradictions found. That only means it is consistent about itself — it is not evidence that the chip is genuine, and not evidence that the numbers it reports are correct. On a clone, the version string is just text somebody chose.'**
  String get settingsAdapterNoContradictions;

  /// No description provided for @settingsAdapterNoVersion.
  ///
  /// In en, this message translates to:
  /// **'(no version reported)'**
  String get settingsAdapterNoVersion;

  /// No description provided for @settingsAdapterSelfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'What the adapter says about itself'**
  String get settingsAdapterSelfReportTitle;

  /// A safety boundary. Three claims must survive translation: reverse-engineered candidates rather than manufacturer documentation; a read-only query can still wake a controller; a decoded number can look plausible and not apply.
  ///
  /// In en, this message translates to:
  /// **'These are reverse-engineered candidate sources, not manufacturer documentation, and not Telltale support for your vehicle. Even a read-only query can wake a controller; a decoded number may look plausible and still not apply.'**
  String get settingsBatteryLabDialogBody;

  /// No description provided for @settingsBatteryLabDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on the battery laboratory'**
  String get settingsBatteryLabDialogTitle;

  /// Off now, possibly back next launch, and per-query consent is unaffected. All three halves are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'The battery laboratory is off for this run, but the setting could not be saved; the next launch may show the laboratory again, and every query still needs its own confirmation.'**
  String get settingsBatteryLabDisableNotSaved;

  /// No description provided for @settingsBatteryLabEnableNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Could not save the battery laboratory setting; it stays off.'**
  String get settingsBatteryLabEnableNotSaved;

  /// No description provided for @settingsBatteryLabEvidenceAck.
  ///
  /// In en, this message translates to:
  /// **'I understand that the source data and the synthetic tests do not prove this applies to my own vehicle'**
  String get settingsBatteryLabEvidenceAck;

  /// The switch reveals the laboratory; it never trusts a vehicle. 'Only reveals' is load-bearing.
  ///
  /// In en, this message translates to:
  /// **'Only reveals one-shot read-only queries whose sources are complete and hash-bound. It does not install PIDs, poll, add gauges, or treat research data as support.'**
  String get settingsBatteryLabSwitchSubtitle;

  /// No description provided for @settingsBatteryLabSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery laboratory (experimental)'**
  String get settingsBatteryLabSwitchTitle;

  /// No description provided for @settingsBatteryLabUnlockReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unlock one-shot read-only queries only'**
  String get settingsBatteryLabUnlockReadOnly;

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

  /// No description provided for @settingsCatalogChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from the official catalog'**
  String get settingsCatalogChoose;

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

  /// Scopes the catalog. Must not read as global coverage.
  ///
  /// In en, this message translates to:
  /// **'The bundled snapshot is the official U.S. EPA Find-a-Car data; it covers only that market and the configurations inside the snapshot, not every brand or model year worldwide.'**
  String get settingsCatalogScope;

  /// No description provided for @settingsCatalogVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying the offline catalog…'**
  String get settingsCatalogVerifying;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// Settings section heading above the current-connection panel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionSection;

  /// No description provided for @settingsDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic transcript'**
  String get settingsDiagnosticsSection;

  /// No description provided for @settingsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// {percent} comes from Drivetrain.efficiency; never spell it into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Transmission efficiency {percent} %'**
  String settingsDrivetrainEfficiency(int percent);

  /// {count} is the number of fields that survived verification.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} official fields'**
  String settingsEpaApplyFields(int count);

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

  /// Fallback title when a configuration lists no displacement, cylinder count or transmission. The EPA ID is data.
  ///
  /// In en, this message translates to:
  /// **'EPA configuration {epaId}'**
  String settingsEpaConfiguration(int epaId);

  /// No description provided for @settingsEpaCylinders.
  ///
  /// In en, this message translates to:
  /// **'{count} cyl'**
  String settingsEpaCylinders(int count);

  /// No description provided for @settingsEpaDriveUnknown.
  ///
  /// In en, this message translates to:
  /// **'Drive unknown'**
  String get settingsEpaDriveUnknown;

  /// No description provided for @settingsEpaFuelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Fuel unknown'**
  String get settingsEpaFuelUnknown;

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

  /// No description provided for @settingsEpaNoConfigurations.
  ///
  /// In en, this message translates to:
  /// **'No configurations available for this model'**
  String get settingsEpaNoConfigurations;

  /// No description provided for @settingsEpaNoSafeFields.
  ///
  /// In en, this message translates to:
  /// **'This configuration has no field that can be applied safely to the current formulas; nothing is guessed.'**
  String get settingsEpaNoSafeFields;

  /// No description provided for @settingsEpaPickInOrder.
  ///
  /// In en, this message translates to:
  /// **'Choose model year, make and model in order'**
  String get settingsEpaPickInOrder;

  /// Both years come from the loaded catalog, never from the prose.
  ///
  /// In en, this message translates to:
  /// **'U.S.-market snapshot configurations for {firstYear}–{lastYear} only. Models that share a name still need the model year, transmission, fuel and EPA ID to tell them apart.'**
  String settingsEpaPickerScope(int firstYear, int lastYear);

  /// No description provided for @settingsEpaPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Official U.S. EPA vehicle catalog'**
  String get settingsEpaPickerTitle;

  /// Names what is NOT applied. VE, Cd and Crr stay as symbols.
  ///
  /// In en, this message translates to:
  /// **'Only {fields} will be applied. Mass, VE, Cd, frontal area, Crr and transmission efficiency stay unresolved.'**
  String settingsEpaWillApplyOnly(String fields);

  /// No description provided for @settingsEpaYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get settingsEpaYear;

  /// No description provided for @settingsExperimentalSection.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get settingsExperimentalSection;

  /// No description provided for @settingsFieldDisplacement.
  ///
  /// In en, this message translates to:
  /// **'Displacement'**
  String get settingsFieldDisplacement;

  /// Cd is a symbol, not a word; it stays Cd in both languages.
  ///
  /// In en, this message translates to:
  /// **'Drag coefficient Cd'**
  String get settingsFieldDragCoefficient;

  /// No description provided for @settingsFieldDrivetrain.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get settingsFieldDrivetrain;

  /// No description provided for @settingsFieldFrontalArea.
  ///
  /// In en, this message translates to:
  /// **'Frontal area'**
  String get settingsFieldFrontalArea;

  /// No description provided for @settingsFieldFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get settingsFieldFuel;

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

  /// Crr is a symbol, not a word; it stays Crr in both languages.
  ///
  /// In en, this message translates to:
  /// **'Rolling resistance Crr'**
  String get settingsFieldRollingResistance;

  /// VE is a symbol, not a word; it stays VE in both languages.
  ///
  /// In en, this message translates to:
  /// **'Volumetric efficiency VE'**
  String get settingsFieldVolumetricEfficiency;

  /// Both values come from the selected FuelType. Units never change with language.
  ///
  /// In en, this message translates to:
  /// **'Air-fuel ratio {afr} · density {density} g/L'**
  String settingsFuelAfrAndDensity(double afr, int density);

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

  /// No description provided for @settingsGaugeSkinBody.
  ///
  /// In en, this message translates to:
  /// **'Not just a colour change — each one has a different dial face, needle and motion. All of them work on dark and light backgrounds.'**
  String get settingsGaugeSkinBody;

  /// No description provided for @settingsGaugeSkinTitle.
  ///
  /// In en, this message translates to:
  /// **'Gauge style'**
  String get settingsGaugeSkinTitle;

  /// Button that leaves Settings for the Connect screen.
  ///
  /// In en, this message translates to:
  /// **'Go to Connect'**
  String get settingsGoToConnect;

  /// No description provided for @settingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeadline;

  /// applicationLegalese on the bundled licence page.
  ///
  /// In en, this message translates to:
  /// **'Powertrain battery sources, transformations, and reuse terms are bundled with this app.'**
  String get settingsLicenseLegalese;

  /// Joins the label lists this screen builds at runtime. Chinese uses the enumeration comma; English uses a comma and a space.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get settingsListSeparator;

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

  /// The adapter answered, and the answer was empty. Not an error, and not a reading.
  ///
  /// In en, this message translates to:
  /// **'(no response content)'**
  String get settingsManualCommandNoContent;

  /// No description provided for @settingsManualCommandSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get settingsManualCommandSend;

  /// No description provided for @settingsManualCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual command'**
  String get settingsManualCommandTitle;

  /// No description provided for @settingsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source and data licences'**
  String get settingsOpenSourceLicenses;

  /// No description provided for @settingsProfileConfirmAfterConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to confirm this vehicle'**
  String get settingsProfileConfirmAfterConnect;

  /// No description provided for @settingsProfileConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm this vehicle for this connection'**
  String get settingsProfileConfirmButton;

  /// No description provided for @settingsProfileConfirmedButton.
  ///
  /// In en, this message translates to:
  /// **'Confirmed for this connection'**
  String get settingsProfileConfirmedButton;

  /// No description provided for @settingsProfileConfirmedDetail.
  ///
  /// In en, this message translates to:
  /// **'The profile is confirmed for this connection. Changing any value, or reconnecting, means confirming again.'**
  String get settingsProfileConfirmedDetail;

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

  /// Publisher names are data and pass through untranslated.
  ///
  /// In en, this message translates to:
  /// **'Sources: {publishers}'**
  String settingsProvenancePublishers(String publishers);

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

  /// SAE J1979, ELM327, the file name and the Torque product names stay byte-identical.
  ///
  /// In en, this message translates to:
  /// **'This app\'s OBD2 implementation follows public standards including SAE J1979 and the ELM327 datasheet; every formula and AT command that affects hardware behaviour is cross-verified, and the results are recorded in docs/protocol-deviations.zh-TW.md. This app is not affiliated with Torque or Torque Pro.'**
  String get settingsStandardsFooter;

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

  /// No description provided for @settingsVehicleProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle profile'**
  String get settingsVehicleProfileSection;

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

  /// No description provided for @settingsVinRead.
  ///
  /// In en, this message translates to:
  /// **'Read VIN'**
  String get settingsVinRead;

  /// No description provided for @settingsVinReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get settingsVinReading;

  /// Self-reported is not verified. Never let this read as a confirmed profile.
  ///
  /// In en, this message translates to:
  /// **'A VIN is what the vehicle reports about itself; it does not verify the model\'s specifications. The identity does not cross connections; the diagnostic transcript may still contain the VIN.'**
  String get settingsVinReportedDetail;

  /// Must not read as a vehicle-reported VIN.
  ///
  /// In en, this message translates to:
  /// **'Simulator-reported VIN'**
  String get settingsVinSimulatorReported;

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

  /// No description provided for @settingsVinVehicleReported.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-reported VIN'**
  String get settingsVinVehicleReported;

  /// Retryable startup failure title. Distinct from startupChecking (in-progress) and startupRestartRequired (must quit).
  ///
  /// In en, this message translates to:
  /// **'Cannot finish startup checks'**
  String get startupCannotComplete;

  /// No description provided for @startupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking local share cache and telemetry records'**
  String get startupChecking;

  /// No description provided for @startupRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.'**
  String get startupRestartHint;

  /// No description provided for @startupRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart required to continue safely'**
  String get startupRestartRequired;

  /// No description provided for @startupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get startupRetry;

  /// No description provided for @startupRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Keep Telltale in the foreground, then retry after other file work finishes. Recording, replay, export and delete stay closed until startup completes.'**
  String get startupRetryHint;

  /// No description provided for @telemetryArtifactRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing'**
  String get telemetryArtifactRestartRequired;

  /// No description provided for @telemetryBlockedByRecorder.
  ///
  /// In en, this message translates to:
  /// **'Stop and save the recording first'**
  String get telemetryBlockedByRecorder;

  /// No description provided for @telemetryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get telemetryCancel;

  /// The app refuses to guess which file is the real one. 'neither was chosen' must survive translation: picking one silently is the failure this reports.
  ///
  /// In en, this message translates to:
  /// **'A finished and an unfinished file share this id — neither was chosen'**
  String get telemetryDamagedCollision;

  /// Damaged, not empty. It is never replayed or exported.
  ///
  /// In en, this message translates to:
  /// **'The recording is damaged and cannot be read safely'**
  String get telemetryDamagedCorrupt;

  /// Filesystem modification time, not a recording timestamp — the file is unreadable, so it has none.
  ///
  /// In en, this message translates to:
  /// **'File time {time}'**
  String telemetryDamagedFileTime(String time);

  /// No description provided for @telemetryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get telemetryDelete;

  /// No description provided for @telemetryDeleteDamagedBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes {id} (file time {time}). It cannot be undone.'**
  String telemetryDeleteDamagedBody(String id, String time);

  /// No description provided for @telemetryDeleteDamagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this damaged recording?'**
  String get telemetryDeleteDamagedTitle;

  /// No description provided for @telemetryDeleteDamagedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete damaged recording'**
  String get telemetryDeleteDamagedTooltip;

  /// Says the delete did not complete, never that it failed harmlessly.
  ///
  /// In en, this message translates to:
  /// **'Delete did not finish: {reason}'**
  String telemetryDeleteFailed(String reason);

  /// No description provided for @telemetryDeleteNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm this delete first'**
  String get telemetryDeleteNeedsConfirmation;

  /// No description provided for @telemetryDeleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the recording from {time}. It cannot be undone.'**
  String telemetryDeleteSessionBody(String time);

  /// No description provided for @telemetryDeleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this local recording?'**
  String get telemetryDeleteSessionTitle;

  /// The figures came from Telltale's own simulator, not from a vehicle. Must stay unmistakable.
  ///
  /// In en, this message translates to:
  /// **'Built-in simulator data'**
  String get telemetryDemoData;

  /// No description provided for @telemetryDismissNotice.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get telemetryDismissNotice;

  /// No description provided for @telemetryEndedByBackground.
  ///
  /// In en, this message translates to:
  /// **'Stopped when Telltale went to the background'**
  String get telemetryEndedByBackground;

  /// No description provided for @telemetryEndedByConfigurationChanged.
  ///
  /// In en, this message translates to:
  /// **'The PID selection changed'**
  String get telemetryEndedByConfigurationChanged;

  /// No description provided for @telemetryEndedByDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Stopped when the connection dropped'**
  String get telemetryEndedByDisconnect;

  /// {minutes} comes from telemetryRecorderDurationLimit; never spell the number in the copy.
  ///
  /// In en, this message translates to:
  /// **'Reached the {minutes}-minute limit'**
  String telemetryEndedByDurationLimit(int minutes);

  /// No description provided for @telemetryEndedByLibrarySizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recording storage is full'**
  String get telemetryEndedByLibrarySizeLimit;

  /// No description provided for @telemetryEndedByRecoveredAfterInterruption.
  ///
  /// In en, this message translates to:
  /// **'Recovered after the last interruption'**
  String get telemetryEndedByRecoveredAfterInterruption;

  /// No description provided for @telemetryEndedBySessionReplacement.
  ///
  /// In en, this message translates to:
  /// **'The connection session was replaced'**
  String get telemetryEndedBySessionReplacement;

  /// No description provided for @telemetryEndedBySessionSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'This recording reached its size limit'**
  String get telemetryEndedBySessionSizeLimit;

  /// No description provided for @telemetryEndedByStorageBackpressure.
  ///
  /// In en, this message translates to:
  /// **'Storage could not keep up'**
  String get telemetryEndedByStorageBackpressure;

  /// No description provided for @telemetryEndedByStorageFailure.
  ///
  /// In en, this message translates to:
  /// **'Saving failed'**
  String get telemetryEndedByStorageFailure;

  /// No description provided for @telemetryEndedByUser.
  ///
  /// In en, this message translates to:
  /// **'Stopped by you'**
  String get telemetryEndedByUser;

  /// No description provided for @telemetryExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get telemetryExport;

  /// No description provided for @telemetryExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get telemetryExportCsv;

  /// No description provided for @telemetryExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export did not finish: {reason}'**
  String telemetryExportFailed(String reason);

  /// No description provided for @telemetryExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get telemetryExportJson;

  /// No description provided for @telemetryExportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Export a local recording'**
  String get telemetryExportSheetTitle;

  /// Breaks in the recorded stream. A gap is missing data, never a zero reading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 gap} other{{count} gaps}}'**
  String telemetryGapCount(int count);

  /// No description provided for @telemetryHistoryEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved group — replay and export offline} other{{count} saved groups — replay and export offline}}'**
  String telemetryHistoryEntrySubtitle(int count);

  /// {limit} is TelemetryQuota.libraryByteLimit in MiB. MiB is a unit and is not translated.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} MiB'**
  String telemetryLibraryBytes(String used, int limit);

  /// {limit} is TelemetryQuota.groupLimit.
  ///
  /// In en, this message translates to:
  /// **'{groups}/{limit} groups'**
  String telemetryLibraryGroupCount(int groups, int limit);

  /// Groups the index found but did not list. Not a claim that they are unreadable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more group not shown} other{{count} more groups not shown}}'**
  String telemetryLibraryOmitted(int count);

  /// Screen-reader form of the two quota chips. Both limits come from TelemetryQuota, never from the prose.
  ///
  /// In en, this message translates to:
  /// **'Local storage: {groups} of {groupLimit} groups, {used} of {byteLimit} MiB'**
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  );

  /// No live link right now. Distinct from a controller refusing a PID and from silence on the bus.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get telemetryNotConnected;

  /// Sampled, not the full recording. The exported file keeps every event; this preview does not.
  ///
  /// In en, this message translates to:
  /// **'Offline sampled replay'**
  String get telemetryOfflineSampledReplay;

  /// No description provided for @telemetryOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'Open local recordings'**
  String get telemetryOpenHistory;

  /// No description provided for @telemetryPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get telemetryPause;

  /// No description provided for @telemetryPendingOwnerRecovery.
  ///
  /// In en, this message translates to:
  /// **'This process still holds the operation. If it stays here, quit Telltale completely and reopen it'**
  String get telemetryPendingOwnerRecovery;

  /// Joins two phrases inside one screen-reader label. The separator is punctuation and differs by language; folding the list through this keeps it out of the Dart.
  ///
  /// In en, this message translates to:
  /// **'{first}. {second}'**
  String telemetryPhraseJoin(String first, String second);

  /// No description provided for @telemetryPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get telemetryPlay;

  /// {laneLimit} is maximumTelemetryTrendLanes, {activeCount} the enabled PID count. 'estimated' must never read as 'measured': these two columns are computed from vehicle assumptions the app cannot verify.
  ///
  /// In en, this message translates to:
  /// **'Records only the OBD signals you have enabled — no location, VIN, or account data. Trends show at most {laneLimit} signals; a recording keeps all {activeCount} enabled signals and adds estimated horsepower and estimated fuel rate, which rest on the vehicle assumptions.'**
  String telemetryRecorderDisclosure(int laneLimit, int activeCount);

  /// The recorder is running and nothing has arrived. Distinct from preparing (not started) and from recording (values are landing).
  ///
  /// In en, this message translates to:
  /// **'Recording — no values yet'**
  String get telemetryRecorderPhaseAwaitingValues;

  /// No description provided for @telemetryRecorderPhaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get telemetryRecorderPhaseCompleted;

  /// No description provided for @telemetryRecorderPhaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving the recording failed'**
  String get telemetryRecorderPhaseFailed;

  /// Shared by the recorder panel and the shell strip.
  ///
  /// In en, this message translates to:
  /// **'Saving the recording'**
  String get telemetryRecorderPhaseFinalizing;

  /// Idle title. Foreground-only is a property of the recorder, not a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Foreground local recording'**
  String get telemetryRecorderPhaseIdle;

  /// Shared by the recorder panel and the shell strip — one key, so the two surfaces cannot disagree about the phase.
  ///
  /// In en, this message translates to:
  /// **'Preparing to record'**
  String get telemetryRecorderPhasePreparing;

  /// No description provided for @telemetryRecorderPhaseRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get telemetryRecorderPhaseRecording;

  /// {duration} is the elapsed clock, already formatted.
  ///
  /// In en, this message translates to:
  /// **'Recording {duration}'**
  String telemetryRecorderStripRecording(String duration);

  /// Only files that held no valid value were removed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unfinished file with no valid values was cleaned up} other{{count} unfinished files with no valid values were cleaned up}}'**
  String telemetryRecoveryCleaned(int count);

  /// Left unchanged, not repaired and not deleted. The app never edits a file it cannot read.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 damaged or conflicting file was left unchanged} other{{count} damaged or conflicting files were left unchanged}}'**
  String telemetryRecoveryDamaged(int count);

  /// Both halves are load-bearing: never used, and deletable only under the safety gate.
  ///
  /// In en, this message translates to:
  /// **'Damaged content is never used for replay or export, and can only be deleted by hand while it is safe to do so.'**
  String get telemetryRecoveryDamagedNote;

  /// Sealed as they were found. Nothing was reconstructed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 interrupted recording was safely sealed} other{{count} interrupted recordings were safely sealed}}'**
  String telemetryRecoveryInstalled(int count);

  /// The check finished. It does not claim damaged data was repaired.
  ///
  /// In en, this message translates to:
  /// **'Startup check of the recordings finished'**
  String get telemetryRecoveryTitle;

  /// No description provided for @telemetryReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get telemetryReload;

  /// Discontinuities in this lane. The line is not drawn across them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 break} other{{count} breaks}}'**
  String telemetryReplayBreakCount(int count);

  /// No description provided for @telemetryReplayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recording'**
  String get telemetryReplayLoadFailed;

  /// No description provided for @telemetryReplayPositionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Replay position {percent}%'**
  String telemetryReplayPositionSemantics(int percent);

  /// Points kept by the downsampler for this lane's preview, not values recorded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sampled point} other{{count} sampled points}}'**
  String telemetryReplaySampleCount(int count);

  /// No description provided for @telemetryReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording replay'**
  String get telemetryReplayTitle;

  /// Two possibilities, both stated. Not 'empty'.
  ///
  /// In en, this message translates to:
  /// **'The recording is damaged or cannot be read'**
  String get telemetryReplayUnreadable;

  /// No description provided for @telemetryRestartToRepairSave.
  ///
  /// In en, this message translates to:
  /// **'Saving did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairSave;

  /// Also the startOutcome for restartRequired; one sentence, one key.
  ///
  /// In en, this message translates to:
  /// **'Startup cleanup did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairStartup;

  /// No description provided for @telemetryReturnToTrends.
  ///
  /// In en, this message translates to:
  /// **'Back to trends'**
  String get telemetryReturnToTrends;

  /// The figures came from a verification rig, not from a vehicle.
  ///
  /// In en, this message translates to:
  /// **'Test rig data'**
  String get telemetryRigData;

  /// Joins two complete sentences. Chinese uses the ideographic full stop, so the separator cannot be hard-coded.
  ///
  /// In en, this message translates to:
  /// **'{first}. {second}'**
  String telemetrySentenceJoin(String first, String second);

  /// No description provided for @telemetrySessionsDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged recording files'**
  String get telemetrySessionsDamaged;

  /// No description provided for @telemetrySessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No local recordings yet\nConnect, then start recording'**
  String get telemetrySessionsEmpty;

  /// No description provided for @telemetrySessionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load — retry'**
  String get telemetrySessionsLoadFailed;

  /// No description provided for @telemetrySessionsReplayable.
  ///
  /// In en, this message translates to:
  /// **'Recordings you can replay'**
  String get telemetrySessionsReplayable;

  /// Title of the saved-recordings screen and of the entry that opens it.
  ///
  /// In en, this message translates to:
  /// **'Local recordings'**
  String get telemetrySessionsTitle;

  /// Number of recorded signals in one session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 signal} other{{count} signals}}'**
  String telemetrySignalCount(int count);

  /// No description provided for @telemetryStartBusy.
  ///
  /// In en, this message translates to:
  /// **'Another recording or file operation has not finished'**
  String get telemetryStartBusy;

  /// No description provided for @telemetryStartCannotCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Could not create the recording file'**
  String get telemetryStartCannotCreateFile;

  /// No description provided for @telemetryStartInvalidConfiguration.
  ///
  /// In en, this message translates to:
  /// **'This PID selection cannot be recorded safely — check the definitions'**
  String get telemetryStartInvalidConfiguration;

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

  /// No description provided for @telemetryStartLibraryByteLimit.
  ///
  /// In en, this message translates to:
  /// **'Not enough local storage for a recording — export or delete some first'**
  String get telemetryStartLibraryByteLimit;

  /// {limit} comes from TelemetryQuota.groupLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recordings reached the limit of {limit} — export or delete some first'**
  String telemetryStartLibraryGroupLimit(int limit);

  /// No description provided for @telemetryStartMoving.
  ///
  /// In en, this message translates to:
  /// **'Park the vehicle first'**
  String get telemetryStartMoving;

  /// No description provided for @telemetryStartNeedsActivePid.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one PID first'**
  String get telemetryStartNeedsActivePid;

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

  /// No description provided for @telemetryStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get telemetryStartRecording;

  /// No description provided for @telemetryStartRecordingButton.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get telemetryStartRecordingButton;

  /// Refuses on unknown speed. Absence of a speed reading is not evidence of a parked car.
  ///
  /// In en, this message translates to:
  /// **'Cannot confirm the vehicle is stopped — disconnect first'**
  String get telemetryStartSpeedUnknown;

  /// Refers to DerivedEstimates.maxLiveSignals. 'estimated' must never read as 'measured'.
  ///
  /// In en, this message translates to:
  /// **'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first'**
  String get telemetryStartTooManyPids;

  /// No description provided for @telemetryStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get telemetryStarting;

  /// No description provided for @telemetryStatusBusError.
  ///
  /// In en, this message translates to:
  /// **'Bus error'**
  String get telemetryStatusBusError;

  /// Status events (no answer, unsupported, bus error) stored beside the values.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 status} other{{count} statuses}}'**
  String telemetryStatusCount(int count);

  /// No description provided for @telemetryStatusFormulaError.
  ///
  /// In en, this message translates to:
  /// **'Formula error'**
  String get telemetryStatusFormulaError;

  /// No description provided for @telemetryStatusHeaderMismatch.
  ///
  /// In en, this message translates to:
  /// **'Header does not match this bus'**
  String get telemetryStatusHeaderMismatch;

  /// Silence, not a refusal. Must never read as unsupported.
  ///
  /// In en, this message translates to:
  /// **'No answer — will retry'**
  String get telemetryStatusNoAnswer;

  /// A live reading that has stopped updating. Not an error and not a fresh value.
  ///
  /// In en, this message translates to:
  /// **'Data is stale'**
  String get telemetryStatusStale;

  /// The app refused to transmit. Says what did NOT happen.
  ///
  /// In en, this message translates to:
  /// **'Not a read-only query — nothing was sent'**
  String get telemetryStatusUnsafeServiceRefusal;

  /// Distinct from no answer: the ECU replied, and the reply said unsupported.
  ///
  /// In en, this message translates to:
  /// **'The controller answered that it does not support this'**
  String get telemetryStatusUnsupported;

  /// The button. Distinct from telemetryBlockedByRecorder, which is the refusal that names this action.
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get telemetryStopAndSave;

  /// Values the recorder actually wrote. Not the number of samples attempted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 valid value} other{{count} valid values}}'**
  String telemetryValueCount(int count);

  /// No description provided for @transcriptDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transcriptDelete;

  /// No description provided for @transcriptDeleteBusy.
  ///
  /// In en, this message translates to:
  /// **'Another file operation has not finished.'**
  String get transcriptDeleteBusy;

  /// No description provided for @transcriptDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the previous connection\'s transcript.'**
  String get transcriptDeleteFailed;

  /// A refusal, not advice.
  ///
  /// In en, this message translates to:
  /// **'The current speed or connection state does not allow deleting the transcript.'**
  String get transcriptDeleteRefusedBySafety;

  /// No description provided for @transcriptExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get transcriptExport;

  /// No description provided for @transcriptExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export transcript'**
  String get transcriptExportButton;

  /// The middle-omitted disclosure is load-bearing: a truncated transcript must announce its truncation.
  ///
  /// In en, this message translates to:
  /// **'This connection keeps the opening handshake and the most recent raw traffic; if a long connection drops the middle, the file says so. When something will not read on the car, exporting the transcript and bringing it back is worth far more than one message on screen.'**
  String get transcriptExportExplanation;

  /// No description provided for @transcriptExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String transcriptExportFailed(String error);

  /// No description provided for @transcriptExportWithHex.
  ///
  /// In en, this message translates to:
  /// **'With hex'**
  String get transcriptExportWithHex;

  /// No description provided for @transcriptNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'There is no transcript to export.'**
  String get transcriptNothingToExport;

  /// No description provided for @transcriptRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'Left at {timestamp}, {size}. It survived the system killing Telltale or the phone losing power.'**
  String transcriptRecoveredBody(String timestamp, String size);

  /// Refuses to export or delete bytes that are no longer the ones on screen.
  ///
  /// In en, this message translates to:
  /// **'The previous connection\'s transcript has changed — check it again.'**
  String get transcriptRecoveredChanged;

  /// Previous connection, not this one. Somebody looking at a working car must not mistake it for the log they are about to make.
  ///
  /// In en, this message translates to:
  /// **'Transcript from the previous connection'**
  String get transcriptRecoveredTitle;

  /// Below a kilobyte the exact byte count is shown, because a failed handshake is a few hundred bytes and '0 KB' reads as empty.
  ///
  /// In en, this message translates to:
  /// **'{bytes, plural, =1{1 byte} other{{bytes} bytes}}'**
  String transcriptSizeBytes(int bytes);

  /// No description provided for @trendAxisNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get trendAxisNow;

  /// No description provided for @trendChooseSignals.
  ///
  /// In en, this message translates to:
  /// **'Choose signals'**
  String get trendChooseSignals;

  /// The lane is connected and no status is outstanding. Never shown for a stale or unanswered reading.
  ///
  /// In en, this message translates to:
  /// **'Live data'**
  String get trendLiveData;

  /// No description provided for @trendNoSignalsBody.
  ///
  /// In en, this message translates to:
  /// **'Enable the signals you want to watch on the PID page first.'**
  String get trendNoSignalsBody;

  /// No description provided for @trendNoSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No trend signals available'**
  String get trendNoSignalsTitle;

  /// No description provided for @trendNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units'**
  String get trendNoUnits;

  /// {limit} comes from maximumTelemetryTrendLanes; never spell the number in the copy.
  ///
  /// In en, this message translates to:
  /// **'Compare up to {limit} signals. This does not change which PIDs are polled.'**
  String trendPickSignalsBody(int limit);

  /// No description provided for @trendPickSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose trend signals'**
  String get trendPickSignalsTitle;

  /// Delete-button tooltip on a signal chip. {name} is a PID name and is not translated here.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String trendRemoveSignal(String name);

  /// Says what did not happen. The chart still shows the selection for this session.
  ///
  /// In en, this message translates to:
  /// **'Could not save the trend display selection'**
  String get trendSelectionSaveFailed;

  /// {limit} comes from maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Choose at most {limit}. This only changes the chart, not PID polling or a recording in progress.'**
  String trendSheetBody(int limit);

  /// Confirm button. Both numbers come from the code: the current selection and maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Done · {selected}/{limit}'**
  String trendSheetDone(int selected, int limit);

  /// No description provided for @trendSignalNoLongerActive.
  ///
  /// In en, this message translates to:
  /// **'One of those signals is no longer in the PID watch list'**
  String get trendSignalNoLongerActive;

  /// No description provided for @trendSignalsHeading.
  ///
  /// In en, this message translates to:
  /// **'Trend signals'**
  String get trendSignalsHeading;

  /// {limit} comes from maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Choose at most {limit}'**
  String trendTooManySelected(int limit);

  /// Screen-reader only. {seconds} comes from telemetryTrendWindow.
  ///
  /// In en, this message translates to:
  /// **'Showing the last {seconds} seconds'**
  String trendWindowSemantics(int seconds);

  /// No description provided for @wearBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wearBack;

  /// The 12V battery reading on the watch numbers grid. Not the powertrain battery, which has its own page.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get wearBatteryVoltageLabel;

  /// No description provided for @wearBleAdapters.
  ///
  /// In en, this message translates to:
  /// **'BLE adapters'**
  String get wearBleAdapters;

  /// No description provided for @wearCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wearCancel;

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

  /// {adapter} is the device name the adapter advertised, or its id when the name is empty. Passed through, never translated.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {adapter}'**
  String wearConnectFailed(String adapter);

  /// No description provided for @wearConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get wearConnecting;

  /// Wear connect button for the built-in simulator. Kept short for a 454px round face.
  ///
  /// In en, this message translates to:
  /// **'Demo simulator'**
  String get wearDemoSimulator;

  /// No description provided for @wearDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get wearDisconnect;

  /// No description provided for @wearDisconnectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Disconnect?'**
  String get wearDisconnectQuestion;

  /// Nothing answered the scan. Not a claim that no adapter exists.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get wearNoDevicesFound;

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

  /// No description provided for @wearScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get wearScanning;

  /// Screen-reader state for the trend card: answers whether a recording is running, and therefore also covers completed and failed. Distinct from telemetryRecorderPhaseIdle, which is the recorder panel's section title and names what the recorder is rather than what it is doing.
  ///
  /// In en, this message translates to:
  /// **'Not recording'**
  String get telemetryRecorderNotRecording;

  /// Fault-code class read from Mode 03. One of three classes that must stay three distinguishable things; never merge with pending or permanent.
  ///
  /// In en, this message translates to:
  /// **'Stored'**
  String get dtcKindStored;

  /// Fault-code class read from Mode 07. A fault seen once that has not yet been confirmed — it is not a confirmed fault and must not read like one.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dtcKindPending;

  /// Fault-code class read from Mode 0A. Must never read as something the Clear button can remove.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get dtcKindPermanent;

  /// Explanation under the Mode 03 group header. Keep "usually": a stored code does not guarantee the lamp is lit.
  ///
  /// In en, this message translates to:
  /// **'A confirmed fault; the dashboard fault lamp is usually lit.'**
  String get dtcKindStoredExplanation;

  /// Explanation under the Mode 07 group header. "Detected once" and "has not reached the threshold" are both load-bearing — this is not yet a confirmed fault.
  ///
  /// In en, this message translates to:
  /// **'Detected once, and has not yet reached the confirmation threshold.'**
  String get dtcKindPendingExplanation;

  /// Explanation under the Mode 0A group header. Both halves are load-bearing: a scan tool cannot clear it, and the ECU clears it itself only after it has confirmed the repair. A translation that lets this read as clearable sends somebody to an inspection they cannot pass.
  ///
  /// In en, this message translates to:
  /// **'Cannot be cleared with a scan tool. The ECU clears it itself, and only once it has confirmed the repair.'**
  String get dtcKindPermanentExplanation;

  /// The system a DTC belongs to, read off its letter. P. The letter itself is never translated.
  ///
  /// In en, this message translates to:
  /// **'Powertrain'**
  String get dtcSystemPowertrain;

  /// The system a DTC belongs to, read off its letter. C.
  ///
  /// In en, this message translates to:
  /// **'Chassis'**
  String get dtcSystemChassis;

  /// The system a DTC belongs to, read off its letter. B.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get dtcSystemBody;

  /// The system a DTC belongs to, read off its letter. U.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get dtcSystemNetwork;

  /// SAE J2012 subsystem for the P00xx block. That block covers both areas, so the label names both rather than picking one.
  ///
  /// In en, this message translates to:
  /// **'Fuel and air metering, and auxiliary emission controls'**
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions;

  /// No description provided for @dtcSubsystemFuelAirMetering.
  ///
  /// In en, this message translates to:
  /// **'Fuel and air metering'**
  String get dtcSubsystemFuelAirMetering;

  /// No description provided for @dtcSubsystemFuelAirMeteringInjectorCircuit.
  ///
  /// In en, this message translates to:
  /// **'Fuel and air metering (injector circuit)'**
  String get dtcSubsystemFuelAirMeteringInjectorCircuit;

  /// No description provided for @dtcSubsystemIgnitionOrMisfire.
  ///
  /// In en, this message translates to:
  /// **'Ignition system or misfire'**
  String get dtcSubsystemIgnitionOrMisfire;

  /// No description provided for @dtcSubsystemAuxiliaryEmissionControls.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary emission controls'**
  String get dtcSubsystemAuxiliaryEmissionControls;

  /// No description provided for @dtcSubsystemSpeedAndIdleControl.
  ///
  /// In en, this message translates to:
  /// **'Vehicle speed control and idle control system'**
  String get dtcSubsystemSpeedAndIdleControl;

  /// No description provided for @dtcSubsystemComputerOutputCircuit.
  ///
  /// In en, this message translates to:
  /// **'Computer output circuit'**
  String get dtcSubsystemComputerOutputCircuit;

  /// No description provided for @dtcSubsystemTransmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get dtcSubsystemTransmission;

  /// SAE J2012 subsystem for the P09xx block, published as "control modules, input and output signals". Do not add a transmission clause: an earlier wording invented one.
  ///
  /// In en, this message translates to:
  /// **'Control modules, input and output signals'**
  String get dtcSubsystemControlModuleSignals;

  /// No description provided for @dtcDescriptionB0001.
  ///
  /// In en, this message translates to:
  /// **'Driver airbag deployment control fault'**
  String get dtcDescriptionB0001;

  /// No description provided for @dtcDescriptionP0011.
  ///
  /// In en, this message translates to:
  /// **'Camshaft position A — timing over-advanced or system performance (Bank 1)'**
  String get dtcDescriptionP0011;

  /// No description provided for @dtcDescriptionP0014.
  ///
  /// In en, this message translates to:
  /// **'Camshaft position B — timing over-advanced or system performance (Bank 1)'**
  String get dtcDescriptionP0014;

  /// No description provided for @dtcDescriptionP0016.
  ///
  /// In en, this message translates to:
  /// **'Crankshaft position – camshaft position correlation (Bank 1 Sensor A)'**
  String get dtcDescriptionP0016;

  /// No description provided for @dtcDescriptionP0087.
  ///
  /// In en, this message translates to:
  /// **'Fuel rail/system pressure too low'**
  String get dtcDescriptionP0087;

  /// No description provided for @dtcDescriptionP0088.
  ///
  /// In en, this message translates to:
  /// **'Fuel rail/system pressure too high'**
  String get dtcDescriptionP0088;

  /// No description provided for @dtcDescriptionP0100.
  ///
  /// In en, this message translates to:
  /// **'Mass air flow (MAF) sensor circuit malfunction'**
  String get dtcDescriptionP0100;

  /// No description provided for @dtcDescriptionP0101.
  ///
  /// In en, this message translates to:
  /// **'Mass air flow sensor range/performance problem'**
  String get dtcDescriptionP0101;

  /// No description provided for @dtcDescriptionP0102.
  ///
  /// In en, this message translates to:
  /// **'Mass air flow sensor circuit low input'**
  String get dtcDescriptionP0102;

  /// No description provided for @dtcDescriptionP0103.
  ///
  /// In en, this message translates to:
  /// **'Mass air flow sensor circuit high input'**
  String get dtcDescriptionP0103;

  /// No description provided for @dtcDescriptionP0105.
  ///
  /// In en, this message translates to:
  /// **'Manifold absolute pressure/barometric pressure sensor circuit malfunction'**
  String get dtcDescriptionP0105;

  /// No description provided for @dtcDescriptionP0106.
  ///
  /// In en, this message translates to:
  /// **'Manifold absolute pressure sensor range/performance problem'**
  String get dtcDescriptionP0106;

  /// No description provided for @dtcDescriptionP0107.
  ///
  /// In en, this message translates to:
  /// **'Manifold absolute pressure sensor circuit low input'**
  String get dtcDescriptionP0107;

  /// No description provided for @dtcDescriptionP0108.
  ///
  /// In en, this message translates to:
  /// **'Manifold absolute pressure sensor circuit high input'**
  String get dtcDescriptionP0108;

  /// No description provided for @dtcDescriptionP0110.
  ///
  /// In en, this message translates to:
  /// **'Intake air temperature sensor circuit malfunction'**
  String get dtcDescriptionP0110;

  /// No description provided for @dtcDescriptionP0111.
  ///
  /// In en, this message translates to:
  /// **'Intake air temperature sensor range/performance problem'**
  String get dtcDescriptionP0111;

  /// No description provided for @dtcDescriptionP0112.
  ///
  /// In en, this message translates to:
  /// **'Intake air temperature sensor circuit low input'**
  String get dtcDescriptionP0112;

  /// No description provided for @dtcDescriptionP0113.
  ///
  /// In en, this message translates to:
  /// **'Intake air temperature sensor circuit high input'**
  String get dtcDescriptionP0113;

  /// No description provided for @dtcDescriptionP0115.
  ///
  /// In en, this message translates to:
  /// **'Engine coolant temperature sensor circuit malfunction'**
  String get dtcDescriptionP0115;

  /// No description provided for @dtcDescriptionP0116.
  ///
  /// In en, this message translates to:
  /// **'Engine coolant temperature sensor range/performance problem'**
  String get dtcDescriptionP0116;

  /// No description provided for @dtcDescriptionP0117.
  ///
  /// In en, this message translates to:
  /// **'Engine coolant temperature sensor circuit low input'**
  String get dtcDescriptionP0117;

  /// No description provided for @dtcDescriptionP0118.
  ///
  /// In en, this message translates to:
  /// **'Engine coolant temperature sensor circuit high input'**
  String get dtcDescriptionP0118;

  /// No description provided for @dtcDescriptionP0120.
  ///
  /// In en, this message translates to:
  /// **'Throttle position sensor circuit malfunction'**
  String get dtcDescriptionP0120;

  /// No description provided for @dtcDescriptionP0121.
  ///
  /// In en, this message translates to:
  /// **'Throttle position sensor range/performance problem'**
  String get dtcDescriptionP0121;

  /// No description provided for @dtcDescriptionP0122.
  ///
  /// In en, this message translates to:
  /// **'Throttle position sensor circuit low input'**
  String get dtcDescriptionP0122;

  /// No description provided for @dtcDescriptionP0123.
  ///
  /// In en, this message translates to:
  /// **'Throttle position sensor circuit high input'**
  String get dtcDescriptionP0123;

  /// No description provided for @dtcDescriptionP0125.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coolant temperature for closed-loop fuel control'**
  String get dtcDescriptionP0125;

  /// No description provided for @dtcDescriptionP0128.
  ///
  /// In en, this message translates to:
  /// **'Coolant temperature below thermostat regulating temperature'**
  String get dtcDescriptionP0128;

  /// No description provided for @dtcDescriptionP0130.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit malfunction (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0130;

  /// No description provided for @dtcDescriptionP0131.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit low voltage (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0131;

  /// No description provided for @dtcDescriptionP0132.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit high voltage (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0132;

  /// No description provided for @dtcDescriptionP0133.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit slow response (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0133;

  /// No description provided for @dtcDescriptionP0134.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit no activity detected (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0134;

  /// No description provided for @dtcDescriptionP0135.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor heater circuit malfunction (Bank 1 Sensor 1)'**
  String get dtcDescriptionP0135;

  /// No description provided for @dtcDescriptionP0136.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit malfunction (Bank 1 Sensor 2)'**
  String get dtcDescriptionP0136;

  /// No description provided for @dtcDescriptionP0137.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit low voltage (Bank 1 Sensor 2)'**
  String get dtcDescriptionP0137;

  /// No description provided for @dtcDescriptionP0138.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit high voltage (Bank 1 Sensor 2)'**
  String get dtcDescriptionP0138;

  /// No description provided for @dtcDescriptionP0140.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit no activity detected (Bank 1 Sensor 2)'**
  String get dtcDescriptionP0140;

  /// No description provided for @dtcDescriptionP0141.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor heater circuit malfunction (Bank 1 Sensor 2)'**
  String get dtcDescriptionP0141;

  /// No description provided for @dtcDescriptionP0150.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit malfunction (Bank 2 Sensor 1)'**
  String get dtcDescriptionP0150;

  /// No description provided for @dtcDescriptionP0155.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor heater circuit malfunction (Bank 2 Sensor 1)'**
  String get dtcDescriptionP0155;

  /// No description provided for @dtcDescriptionP0156.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor circuit malfunction (Bank 2 Sensor 2)'**
  String get dtcDescriptionP0156;

  /// No description provided for @dtcDescriptionP0161.
  ///
  /// In en, this message translates to:
  /// **'Oxygen sensor heater circuit malfunction (Bank 2 Sensor 2)'**
  String get dtcDescriptionP0161;

  /// No description provided for @dtcDescriptionP0170.
  ///
  /// In en, this message translates to:
  /// **'Fuel trim malfunction (Bank 1)'**
  String get dtcDescriptionP0170;

  /// No description provided for @dtcDescriptionP0171.
  ///
  /// In en, this message translates to:
  /// **'System too lean (Bank 1)'**
  String get dtcDescriptionP0171;

  /// No description provided for @dtcDescriptionP0172.
  ///
  /// In en, this message translates to:
  /// **'System too rich (Bank 1)'**
  String get dtcDescriptionP0172;

  /// No description provided for @dtcDescriptionP0173.
  ///
  /// In en, this message translates to:
  /// **'Fuel trim malfunction (Bank 2)'**
  String get dtcDescriptionP0173;

  /// No description provided for @dtcDescriptionP0174.
  ///
  /// In en, this message translates to:
  /// **'System too lean (Bank 2)'**
  String get dtcDescriptionP0174;

  /// No description provided for @dtcDescriptionP0175.
  ///
  /// In en, this message translates to:
  /// **'System too rich (Bank 2)'**
  String get dtcDescriptionP0175;

  /// No description provided for @dtcDescriptionP0190.
  ///
  /// In en, this message translates to:
  /// **'Fuel rail pressure sensor circuit malfunction'**
  String get dtcDescriptionP0190;

  /// No description provided for @dtcDescriptionP0201.
  ///
  /// In en, this message translates to:
  /// **'Injector circuit malfunction or open — cylinder 1'**
  String get dtcDescriptionP0201;

  /// No description provided for @dtcDescriptionP0202.
  ///
  /// In en, this message translates to:
  /// **'Injector circuit malfunction or open — cylinder 2'**
  String get dtcDescriptionP0202;

  /// No description provided for @dtcDescriptionP0203.
  ///
  /// In en, this message translates to:
  /// **'Injector circuit malfunction or open — cylinder 3'**
  String get dtcDescriptionP0203;

  /// No description provided for @dtcDescriptionP0204.
  ///
  /// In en, this message translates to:
  /// **'Injector circuit malfunction or open — cylinder 4'**
  String get dtcDescriptionP0204;

  /// No description provided for @dtcDescriptionP0217.
  ///
  /// In en, this message translates to:
  /// **'Engine over-temperature condition'**
  String get dtcDescriptionP0217;

  /// No description provided for @dtcDescriptionP0221.
  ///
  /// In en, this message translates to:
  /// **'Throttle/pedal position sensor B range/performance problem'**
  String get dtcDescriptionP0221;

  /// No description provided for @dtcDescriptionP0222.
  ///
  /// In en, this message translates to:
  /// **'Throttle/pedal position sensor B circuit low input'**
  String get dtcDescriptionP0222;

  /// No description provided for @dtcDescriptionP0223.
  ///
  /// In en, this message translates to:
  /// **'Throttle/pedal position sensor B circuit high input'**
  String get dtcDescriptionP0223;

  /// No description provided for @dtcDescriptionP0234.
  ///
  /// In en, this message translates to:
  /// **'Turbocharger/supercharger overboost condition'**
  String get dtcDescriptionP0234;

  /// No description provided for @dtcDescriptionP0299.
  ///
  /// In en, this message translates to:
  /// **'Turbocharger/supercharger A underboost condition'**
  String get dtcDescriptionP0299;

  /// No description provided for @dtcDescriptionP0300.
  ///
  /// In en, this message translates to:
  /// **'Random or multiple cylinder misfire detected'**
  String get dtcDescriptionP0300;

  /// No description provided for @dtcDescriptionP0301.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 1 misfire detected'**
  String get dtcDescriptionP0301;

  /// No description provided for @dtcDescriptionP0302.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 2 misfire detected'**
  String get dtcDescriptionP0302;

  /// No description provided for @dtcDescriptionP0303.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 3 misfire detected'**
  String get dtcDescriptionP0303;

  /// No description provided for @dtcDescriptionP0304.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 4 misfire detected'**
  String get dtcDescriptionP0304;

  /// No description provided for @dtcDescriptionP0305.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 5 misfire detected'**
  String get dtcDescriptionP0305;

  /// No description provided for @dtcDescriptionP0306.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 6 misfire detected'**
  String get dtcDescriptionP0306;

  /// No description provided for @dtcDescriptionP0307.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 7 misfire detected'**
  String get dtcDescriptionP0307;

  /// No description provided for @dtcDescriptionP0308.
  ///
  /// In en, this message translates to:
  /// **'Cylinder 8 misfire detected'**
  String get dtcDescriptionP0308;

  /// No description provided for @dtcDescriptionP0316.
  ///
  /// In en, this message translates to:
  /// **'Misfire detected immediately after startup'**
  String get dtcDescriptionP0316;

  /// No description provided for @dtcDescriptionP0325.
  ///
  /// In en, this message translates to:
  /// **'Knock sensor circuit malfunction (Bank 1)'**
  String get dtcDescriptionP0325;

  /// No description provided for @dtcDescriptionP0326.
  ///
  /// In en, this message translates to:
  /// **'Knock sensor range/performance problem (Bank 1)'**
  String get dtcDescriptionP0326;

  /// No description provided for @dtcDescriptionP0327.
  ///
  /// In en, this message translates to:
  /// **'Knock sensor circuit low input (Bank 1)'**
  String get dtcDescriptionP0327;

  /// No description provided for @dtcDescriptionP0328.
  ///
  /// In en, this message translates to:
  /// **'Knock sensor circuit high input (Bank 1)'**
  String get dtcDescriptionP0328;

  /// No description provided for @dtcDescriptionP0330.
  ///
  /// In en, this message translates to:
  /// **'Knock sensor circuit malfunction (Bank 2)'**
  String get dtcDescriptionP0330;

  /// No description provided for @dtcDescriptionP0335.
  ///
  /// In en, this message translates to:
  /// **'Crankshaft position sensor circuit malfunction'**
  String get dtcDescriptionP0335;

  /// No description provided for @dtcDescriptionP0336.
  ///
  /// In en, this message translates to:
  /// **'Crankshaft position sensor range/performance problem'**
  String get dtcDescriptionP0336;

  /// No description provided for @dtcDescriptionP0340.
  ///
  /// In en, this message translates to:
  /// **'Camshaft position sensor circuit malfunction'**
  String get dtcDescriptionP0340;

  /// No description provided for @dtcDescriptionP0341.
  ///
  /// In en, this message translates to:
  /// **'Camshaft position sensor range/performance problem'**
  String get dtcDescriptionP0341;

  /// No description provided for @dtcDescriptionP0351.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil A primary/secondary circuit malfunction'**
  String get dtcDescriptionP0351;

  /// No description provided for @dtcDescriptionP0352.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil B primary/secondary circuit malfunction'**
  String get dtcDescriptionP0352;

  /// No description provided for @dtcDescriptionP0353.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil C primary/secondary circuit malfunction'**
  String get dtcDescriptionP0353;

  /// No description provided for @dtcDescriptionP0354.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil D primary/secondary circuit malfunction'**
  String get dtcDescriptionP0354;

  /// No description provided for @dtcDescriptionP0355.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil E primary/secondary circuit malfunction'**
  String get dtcDescriptionP0355;

  /// No description provided for @dtcDescriptionP0356.
  ///
  /// In en, this message translates to:
  /// **'Ignition coil F primary/secondary circuit malfunction'**
  String get dtcDescriptionP0356;

  /// No description provided for @dtcDescriptionP0400.
  ///
  /// In en, this message translates to:
  /// **'Exhaust gas recirculation (EGR) flow malfunction'**
  String get dtcDescriptionP0400;

  /// No description provided for @dtcDescriptionP0401.
  ///
  /// In en, this message translates to:
  /// **'Exhaust gas recirculation (EGR) flow insufficient'**
  String get dtcDescriptionP0401;

  /// No description provided for @dtcDescriptionP0402.
  ///
  /// In en, this message translates to:
  /// **'Exhaust gas recirculation (EGR) flow excessive'**
  String get dtcDescriptionP0402;

  /// No description provided for @dtcDescriptionP0403.
  ///
  /// In en, this message translates to:
  /// **'Exhaust gas recirculation (EGR) control circuit malfunction'**
  String get dtcDescriptionP0403;

  /// No description provided for @dtcDescriptionP0404.
  ///
  /// In en, this message translates to:
  /// **'Exhaust gas recirculation (EGR) control circuit range/performance problem'**
  String get dtcDescriptionP0404;

  /// No description provided for @dtcDescriptionP0410.
  ///
  /// In en, this message translates to:
  /// **'Secondary air injection system malfunction'**
  String get dtcDescriptionP0410;

  /// Secondary air injection, NOT evaporative emissions. The most-reposted fault-code table on the web has P0411 and P0441 the wrong way round; copying it sends somebody to check a fuel cap while an air pump fails.
  ///
  /// In en, this message translates to:
  /// **'Secondary air injection system incorrect flow detected'**
  String get dtcDescriptionP0411;

  /// No description provided for @dtcDescriptionP0412.
  ///
  /// In en, this message translates to:
  /// **'Secondary air injection system switching valve A circuit malfunction'**
  String get dtcDescriptionP0412;

  /// No description provided for @dtcDescriptionP0420.
  ///
  /// In en, this message translates to:
  /// **'Catalyst system efficiency below threshold (Bank 1)'**
  String get dtcDescriptionP0420;

  /// No description provided for @dtcDescriptionP0430.
  ///
  /// In en, this message translates to:
  /// **'Catalyst system efficiency below threshold (Bank 2)'**
  String get dtcDescriptionP0430;

  /// No description provided for @dtcDescriptionP0440.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission control system malfunction'**
  String get dtcDescriptionP0440;

  /// Evaporative emissions, NOT secondary air injection. See the note on dtcDescriptionP0411.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system incorrect purge flow'**
  String get dtcDescriptionP0441;

  /// No description provided for @dtcDescriptionP0442.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system leak detected (small leak)'**
  String get dtcDescriptionP0442;

  /// No description provided for @dtcDescriptionP0443.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system purge control valve circuit malfunction'**
  String get dtcDescriptionP0443;

  /// No description provided for @dtcDescriptionP0446.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system vent control circuit malfunction'**
  String get dtcDescriptionP0446;

  /// No description provided for @dtcDescriptionP0447.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system vent control circuit open'**
  String get dtcDescriptionP0447;

  /// No description provided for @dtcDescriptionP0449.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system vent valve/solenoid circuit malfunction'**
  String get dtcDescriptionP0449;

  /// No description provided for @dtcDescriptionP0451.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system pressure sensor range/performance problem'**
  String get dtcDescriptionP0451;

  /// No description provided for @dtcDescriptionP0452.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system pressure sensor circuit low input'**
  String get dtcDescriptionP0452;

  /// No description provided for @dtcDescriptionP0453.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system pressure sensor circuit high input'**
  String get dtcDescriptionP0453;

  /// No description provided for @dtcDescriptionP0455.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system leak detected (large leak)'**
  String get dtcDescriptionP0455;

  /// No description provided for @dtcDescriptionP0456.
  ///
  /// In en, this message translates to:
  /// **'Evaporative emission system leak detected (very small leak)'**
  String get dtcDescriptionP0456;

  /// No description provided for @dtcDescriptionP0480.
  ///
  /// In en, this message translates to:
  /// **'Cooling fan 1 control circuit malfunction'**
  String get dtcDescriptionP0480;

  /// No description provided for @dtcDescriptionP0500.
  ///
  /// In en, this message translates to:
  /// **'Vehicle speed sensor malfunction'**
  String get dtcDescriptionP0500;

  /// No description provided for @dtcDescriptionP0505.
  ///
  /// In en, this message translates to:
  /// **'Idle control system malfunction'**
  String get dtcDescriptionP0505;

  /// No description provided for @dtcDescriptionP0506.
  ///
  /// In en, this message translates to:
  /// **'Idle control system RPM lower than expected'**
  String get dtcDescriptionP0506;

  /// No description provided for @dtcDescriptionP0507.
  ///
  /// In en, this message translates to:
  /// **'Idle control system RPM higher than expected'**
  String get dtcDescriptionP0507;

  /// No description provided for @dtcDescriptionP0508.
  ///
  /// In en, this message translates to:
  /// **'Idle control system circuit low'**
  String get dtcDescriptionP0508;

  /// No description provided for @dtcDescriptionP0509.
  ///
  /// In en, this message translates to:
  /// **'Idle control system circuit high'**
  String get dtcDescriptionP0509;

  /// No description provided for @dtcDescriptionP0560.
  ///
  /// In en, this message translates to:
  /// **'System voltage malfunction'**
  String get dtcDescriptionP0560;

  /// No description provided for @dtcDescriptionP0562.
  ///
  /// In en, this message translates to:
  /// **'System voltage low'**
  String get dtcDescriptionP0562;

  /// No description provided for @dtcDescriptionP0563.
  ///
  /// In en, this message translates to:
  /// **'System voltage high'**
  String get dtcDescriptionP0563;

  /// No description provided for @dtcDescriptionP0603.
  ///
  /// In en, this message translates to:
  /// **'Internal control module keep-alive memory (KAM) error'**
  String get dtcDescriptionP0603;

  /// No description provided for @dtcDescriptionP0605.
  ///
  /// In en, this message translates to:
  /// **'Internal control module read-only memory (ROM) error'**
  String get dtcDescriptionP0605;

  /// No description provided for @dtcDescriptionP0606.
  ///
  /// In en, this message translates to:
  /// **'ECM/PCM processor fault'**
  String get dtcDescriptionP0606;

  /// The code is a pointer, not a fault in itself: the real fault code lives in the transmission module and needs a separate read. Keep that clause.
  ///
  /// In en, this message translates to:
  /// **'The transmission control module asked for the fault lamp — the fault code itself is in the transmission module and has to be read separately'**
  String get dtcDescriptionP0700;

  /// No description provided for @dtcDescriptionP0701.
  ///
  /// In en, this message translates to:
  /// **'Transmission control system range/performance problem'**
  String get dtcDescriptionP0701;

  /// No description provided for @dtcDescriptionP0702.
  ///
  /// In en, this message translates to:
  /// **'Transmission control system electrical fault'**
  String get dtcDescriptionP0702;

  /// No description provided for @dtcDescriptionP0705.
  ///
  /// In en, this message translates to:
  /// **'Transmission range sensor circuit malfunction'**
  String get dtcDescriptionP0705;

  /// No description provided for @dtcDescriptionP0715.
  ///
  /// In en, this message translates to:
  /// **'Input/turbine speed sensor circuit malfunction'**
  String get dtcDescriptionP0715;

  /// No description provided for @dtcDescriptionP0720.
  ///
  /// In en, this message translates to:
  /// **'Output speed sensor circuit malfunction'**
  String get dtcDescriptionP0720;

  /// No description provided for @dtcDescriptionP0730.
  ///
  /// In en, this message translates to:
  /// **'Incorrect gear ratio'**
  String get dtcDescriptionP0730;

  /// No description provided for @dtcDescriptionP0740.
  ///
  /// In en, this message translates to:
  /// **'Torque converter clutch circuit malfunction'**
  String get dtcDescriptionP0740;

  /// No description provided for @dtcDescriptionP0741.
  ///
  /// In en, this message translates to:
  /// **'Torque converter clutch stuck off'**
  String get dtcDescriptionP0741;

  /// No description provided for @dtcDescriptionP0750.
  ///
  /// In en, this message translates to:
  /// **'Shift solenoid A malfunction'**
  String get dtcDescriptionP0750;

  /// No description provided for @dtcDescriptionP0755.
  ///
  /// In en, this message translates to:
  /// **'Shift solenoid B malfunction'**
  String get dtcDescriptionP0755;

  /// No description provided for @dtcDescriptionP2135.
  ///
  /// In en, this message translates to:
  /// **'Throttle position sensor A/B voltage correlation'**
  String get dtcDescriptionP2135;

  /// No description provided for @dtcDescriptionU0100.
  ///
  /// In en, this message translates to:
  /// **'Lost communication with ECM/PCM'**
  String get dtcDescriptionU0100;

  /// No description provided for @dtcDescriptionU0101.
  ///
  /// In en, this message translates to:
  /// **'Lost communication with the transmission control module'**
  String get dtcDescriptionU0101;

  /// No description provided for @dtcDescriptionU0121.
  ///
  /// In en, this message translates to:
  /// **'Lost communication with the ABS control module'**
  String get dtcDescriptionU0121;

  /// No description provided for @dtcDescriptionU0140.
  ///
  /// In en, this message translates to:
  /// **'Lost communication with the body control module'**
  String get dtcDescriptionU0140;

  /// No description provided for @dtcDescriptionU0155.
  ///
  /// In en, this message translates to:
  /// **'Lost communication with the instrument panel control module'**
  String get dtcDescriptionU0155;

  /// No description provided for @gaugeSkinCluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get gaugeSkinCluster;

  /// No description provided for @gaugeSkinClusterDescription.
  ///
  /// In en, this message translates to:
  /// **'Looks like a factory instrument cluster. Needle, 270-degree dial, recessed face.'**
  String get gaugeSkinClusterDescription;

  /// No description provided for @gaugeSkinMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get gaugeSkinMinimal;

  /// No description provided for @gaugeSkinMinimalDescription.
  ///
  /// In en, this message translates to:
  /// **'Half an arc, no needle, no ticks. The number is what you read, not the movement.'**
  String get gaugeSkinMinimalDescription;

  /// No description provided for @gaugeSkinTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get gaugeSkinTrack;

  /// "No smoothing" is the point: a track readout must not interpolate a value the ECU never sent.
  ///
  /// In en, this message translates to:
  /// **'Segmented bar, no smoothing. The value lands where it lands, with nothing in between.'**
  String get gaugeSkinTrackDescription;

  /// No description provided for @gaugeSkinClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get gaugeSkinClassic;

  /// No description provided for @gaugeSkinClassicDescription.
  ///
  /// In en, this message translates to:
  /// **'Printed dial, numbers all the way round, a needle that settles slowly like a mechanical watch.'**
  String get gaugeSkinClassicDescription;

  /// No description provided for @gaugeSkinNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get gaugeSkinNight;

  /// No description provided for @gaugeSkinNightDescription.
  ///
  /// In en, this message translates to:
  /// **'For driving after dark. Low brightness, a shallow arc, no animation — as little of your attention as possible.'**
  String get gaugeSkinNightDescription;

  /// Provenance pill on the estimated-values panel: the air-mass figure came from the vehicle's own MAF sensor rather than being computed.
  ///
  /// In en, this message translates to:
  /// **'MAF sensor'**
  String get derivedAirflowSourceMaf;

  /// Provenance pill: air mass was computed from engine speed, manifold pressure and intake temperature. It is an estimate, and the word must say so.
  ///
  /// In en, this message translates to:
  /// **'Speed-density estimate'**
  String get derivedAirflowSourceSpeedDensity;

  /// Provenance pill: neither a MAF reading nor the full speed-density input set was available. Not the same as zero air flow, which would mean a stopped engine.
  ///
  /// In en, this message translates to:
  /// **'Air mass unavailable'**
  String get derivedAirflowSourceUnavailable;

  /// Provenance pill: fuel was derived from air mass assuming a stoichiometric mixture, so it is wrong by roughly the lambda the engine is running. Do not translate this as if it were a measurement.
  ///
  /// In en, this message translates to:
  /// **'Stoichiometric estimate'**
  String get derivedFuelSourceStoichiometric;

  /// Provenance pill: no fuel figure could be established, measured or estimated.
  ///
  /// In en, this message translates to:
  /// **'Fuel rate unavailable'**
  String get derivedFuelSourceUnavailable;

  /// Where a recorded telemetry session came from: the app's own simulated ECU. A reader must never mistake a simulated session for a drive.
  ///
  /// In en, this message translates to:
  /// **'Built-in simulator'**
  String get telemetrySourceDemo;

  /// Where a recorded telemetry session came from: a simulated hardware rig used in testing, not a vehicle.
  ///
  /// In en, this message translates to:
  /// **'Test rig'**
  String get telemetrySourceRig;

  /// Where a recorded telemetry session came from: an ordinary connection made by the field build to a real adapter.
  ///
  /// In en, this message translates to:
  /// **'Field app connection'**
  String get telemetrySourceFieldApp;

  /// Fuel type in the vehicle profile. British 'petrol' rather than American 'gas', because 'gas' also means LPG to many readers and this list contains LPG.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelTypeGasoline;

  /// No description provided for @fuelTypeDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelTypeDiesel;

  /// Liquefied petroleum gas. The abbreviation is the common name in English; do not expand it.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelTypeLpg;

  /// No description provided for @fuelTypeEthanolE85.
  ///
  /// In en, this message translates to:
  /// **'E85 ethanol'**
  String get fuelTypeEthanolE85;

  /// No description provided for @drivetrainFwd.
  ///
  /// In en, this message translates to:
  /// **'Front-wheel drive'**
  String get drivetrainFwd;

  /// No description provided for @drivetrainRwd.
  ///
  /// In en, this message translates to:
  /// **'Rear-wheel drive'**
  String get drivetrainRwd;

  /// No description provided for @drivetrainAwd.
  ///
  /// In en, this message translates to:
  /// **'All-wheel drive'**
  String get drivetrainAwd;

  /// A vehicle parameter an estimate rests on: the vehicle's mass including the driver.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get assumptionFieldMass;

  /// Drag coefficient. The symbol is the same in every language; do not translate or expand it.
  ///
  /// In en, this message translates to:
  /// **'Cd'**
  String get assumptionFieldDragCoefficient;

  /// No description provided for @assumptionFieldFrontalArea.
  ///
  /// In en, this message translates to:
  /// **'Frontal area'**
  String get assumptionFieldFrontalArea;

  /// No description provided for @assumptionFieldRollingResistance.
  ///
  /// In en, this message translates to:
  /// **'Rolling resistance'**
  String get assumptionFieldRollingResistance;

  /// No description provided for @assumptionFieldDrivetrainEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain efficiency'**
  String get assumptionFieldDrivetrainEfficiency;

  /// No description provided for @assumptionFieldFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get assumptionFieldFuelType;

  /// Stoichiometric air-fuel ratio. The abbreviation is standard; do not expand it.
  ///
  /// In en, this message translates to:
  /// **'AFR'**
  String get assumptionFieldStoichAfr;

  /// No description provided for @assumptionFieldFuelDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get assumptionFieldFuelDensity;

  /// No description provided for @assumptionFieldDisplacement.
  ///
  /// In en, this message translates to:
  /// **'Displacement'**
  String get assumptionFieldDisplacement;

  /// Volumetric efficiency. The abbreviation is standard; do not expand it.
  ///
  /// In en, this message translates to:
  /// **'VE'**
  String get assumptionFieldVolumetricEfficiency;

  /// Where an assumed parameter came from: nothing about this vehicle, just a value typical of cars. The weakest of the five, and the reader must be able to tell it apart from the others at a glance — it is the difference between an estimate about their car and an estimate about a car.
  ///
  /// In en, this message translates to:
  /// **'generic default'**
  String get vehicleFieldOriginGenericDefault;

  /// Where an assumed parameter came from: the reader typed it in. Not verified by the app, and must not be worded as if it were.
  ///
  /// In en, this message translates to:
  /// **'entered by you'**
  String get vehicleFieldOriginUserEntered;

  /// Where an assumed parameter came from: the bundled official vehicle registry data.
  ///
  /// In en, this message translates to:
  /// **'official registry'**
  String get vehicleFieldOriginOfficialRegistry;

  /// Where an assumed parameter came from: a figure the manufacturer published.
  ///
  /// In en, this message translates to:
  /// **'manufacturer data'**
  String get vehicleFieldOriginManufacturerPublication;

  /// Where an assumed parameter came from: a coefficient from a physical model rather than from this vehicle. An estimate, and the wording must not suggest a measurement.
  ///
  /// In en, this message translates to:
  /// **'model coefficient'**
  String get vehicleFieldOriginScientificModel;

  /// One line of the estimate-assumptions list. The brackets are ASCII here and fullwidth in Chinese; that punctuation is part of the translation, not decoration.
  ///
  /// In en, this message translates to:
  /// **'{field} {value} ({origin})'**
  String assumptionWithOrigin(String field, String value, String origin);

  /// One line of the estimate-assumptions list, for a parameter that follows from the fuel type and so has no separate origin.
  ///
  /// In en, this message translates to:
  /// **'{field} {value}'**
  String assumptionWithoutOrigin(String field, String value);

  /// Joins the assumption lines. English uses a semicolon and a space; Chinese uses the fullwidth semicolon and no space. Using the English one in Chinese, or the reverse, is a defect this project has shipped before.
  ///
  /// In en, this message translates to:
  /// **'; '**
  String get assumptionSeparator;

  /// The power estimate's formula, shown so a reader can check the working. Symbols and operators must not be translated; only the identifier words could be, and are better left as they are.
  ///
  /// In en, this message translates to:
  /// **'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency'**
  String get datumFormulaHorsepower;

  /// The fuel estimate's formula. Only the connecting words are translatable; PID 0110, MAF, MAP, VE and the units are not.
  ///
  /// In en, this message translates to:
  /// **'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF is either PID 0110 or speed-density (RPM × MAP × displacement × VE / T_K); L/100km = (L/h) / speed_kmh × 100'**
  String get datumFormulaFuelRate;

  /// Shown in the estimate details for a replayed session whose file did not store the parameter list. It must not imply the settings were verified, only that they are the ones in force at record time.
  ///
  /// In en, this message translates to:
  /// **'The estimate uses the vehicle settings as they were when this was recorded.'**
  String get datumAssumptionsFromRecording;

  /// Clone-adapter detection. Elm Electronics never shipped this version number, so the firmware is not the one the adapter says it is. Must not be softened into a compatibility note: the point is that the device's account of itself is unreliable.
  ///
  /// In en, this message translates to:
  /// **'Reports firmware v{version}, which was never released'**
  String adapterConcernFirmwareNeverReleasedSummary(String version);

  /// No description provided for @adapterConcernFirmwareNeverReleasedDetail.
  ///
  /// In en, this message translates to:
  /// **'Elm Electronics never published this version, so the firmware on this adapter is not the one it claims. Many of these still work — but its description of itself cannot be trusted, and it is worth suspecting first when something will not read.'**
  String get adapterConcernFirmwareNeverReleasedDetail;

  /// Clone-adapter detection: the claimed version and the implemented command set contradict each other. ATPPS and the version numbers are protocol tokens and are not translated.
  ///
  /// In en, this message translates to:
  /// **'Claims v{version}, yet does not know ATPPS, which v1.1 had'**
  String adapterConcernPpsRefusedSummary(String version);

  /// No description provided for @adapterConcernPpsRefusedDetail.
  ///
  /// In en, this message translates to:
  /// **'The programmable-parameter summary (ATPPS) has existed since ELM327 v1.1, and even high-end adapters such as OBDLink support it. The version it claims and the commands it actually implements do not line up.'**
  String get adapterConcernPpsRefusedDetail;

  /// No description provided for @adapterConcernNoIdentitySummary.
  ///
  /// In en, this message translates to:
  /// **'Does not answer AT@1, the device-identity command from the first release'**
  String get adapterConcernNoIdentitySummary;

  /// No description provided for @adapterConcernNoIdentityDetail.
  ///
  /// In en, this message translates to:
  /// **'This command has existed since ELM327 v1.0. Not answering it means this chip implements a smaller command set than any official firmware.'**
  String get adapterConcernNoIdentityDetail;

  /// Shown under a replayed session's chart, always. The chart a reader is looking at is not the whole recording, and this sentence is the only thing that says so — dropping or softening it lets somebody read a sampled curve as a complete one.
  ///
  /// In en, this message translates to:
  /// **'The preview is sampled; the export keeps every recorded event.'**
  String get telemetryReplaySampled;

  /// Shown on the export sheet. It is where the app tells the reader what leaves the device, and it is what the store listing's 'no personal data collected' rests on. Both halves are load-bearing: the enumeration of what IS included, and the enumeration of what is NOT. Do not shorten either.
  ///
  /// In en, this message translates to:
  /// **'The export contains signal names, values, observation and source times, transport kind, protocol, frozen PID labels, units and formulas, and the estimate assumptions (mass, drag, displacement, fuel and similar parameters). JSON may also contain your own custom labels, units, formulas and complete frozen definitions. The export does not contain the VIN, GPS, an account, the adapter address, the full vehicle profile, or raw diagnostic traffic.'**
  String get telemetryExportDisclosure;

  /// TransportIssue.cancelled. Not a failure of the adapter or the link, and it must not read like one: the user backed out, or a newer attempt replaced this one.
  ///
  /// In en, this message translates to:
  /// **'The connection attempt was stopped before it finished.'**
  String get connectTransportCancelled;

  /// TransportIssue.wifiRouteNoNetwork. The only one of the route failures where "connect to the hotspot" is the right remedy — the transport used to say it for all of them.
  ///
  /// In en, this message translates to:
  /// **'The phone is not on any Wi-Fi network, so there is no route to the adapter. Connect to the adapter\'s Wi-Fi hotspot, then try again.'**
  String get connectTransportWifiRouteNoNetwork;

  /// TransportIssue.wifiRouteAmbiguous. Plural: the platform reports how many networks were equally plausible and it can exceed two. Says why nothing was picked rather than guessing — picking one at random is how a connection goes to the wrong network and blames the adapter.
  ///
  /// In en, this message translates to:
  /// **'The phone is on more than one Wi-Fi network and none of them is clearly the adapter\'s, so none was chosen. Disconnect the ones that are not the adapter\'s, then try again.'**
  String get connectTransportWifiRouteAmbiguous;

  /// TransportIssue.wifiRouteRefused. Distinct from having no network, and the distinction is the whole message: telling someone to join a hotspot they are already on wastes the one thing they can act on.
  ///
  /// In en, this message translates to:
  /// **'The system refused to send this connection over Wi-Fi. The phone is on Wi-Fi; it was not allowed to be used for this.'**
  String get connectTransportWifiRouteRefused;

  /// TransportIssue.wifiRouteTimeout. States what did not happen, not what is wrong; the platform call may still complete afterwards, which is why the app releases the route regardless.
  ///
  /// In en, this message translates to:
  /// **'The system did not answer the request to send this connection over Wi-Fi. Wait a few seconds and try again.'**
  String get connectTransportWifiRouteTimeout;

  /// TransportIssue.wifiRouteUnclassified. An unrecognised platform code must never borrow another failure's remedy, so this one deliberately offers none.
  ///
  /// In en, this message translates to:
  /// **'The connection could not be sent over Wi-Fi, for a reason the system did not name. The full error is kept in the log below.'**
  String get connectTransportWifiRouteUnclassified;

  /// TransportIssue.wifiHostUnreachable. The "stay connected without internet" prompt is the most common cause and is invisible afterwards, so it is named rather than described.
  ///
  /// In en, this message translates to:
  /// **'Nothing answered at that address. Check the phone is on the adapter\'s Wi-Fi hotspot — if the system asked whether to stay connected without internet, choose to stay. Turning mobile data off can also help.'**
  String get connectTransportWifiHostUnreachable;

  /// TransportIssue.wifiConnectTimeout. Says nothing answered, not that an adapter is there: a timeout establishes silence, and someone who typed the wrong address would otherwise read a verdict on hardware they never reached. The address is in the log below.
  ///
  /// In en, this message translates to:
  /// **'Nothing answered at that address in time.'**
  String get connectTransportWifiConnectTimeout;

  /// TransportIssue.wifiRouteRestoreFailed. The connection is dropped on purpose: leaving the phone's routing altered by an app that could not undo it is worse than losing the session.
  ///
  /// In en, this message translates to:
  /// **'The connection worked, but the phone\'s network routing could not be put back, so the connection was dropped rather than left changed. Restart the app and try again.'**
  String get connectTransportWifiRouteRestoreFailed;

  /// TransportIssue.bleLinkFailed. The link never came up, so nothing is known about what the device is.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the adapter. Check that it has power and is within range.'**
  String get connectTransportBleLinkFailed;

  /// TransportIssue.bleNoSerialCharacteristic. What was not found, stated as what was not found. Some adapters expose the pair only after a delay, so "may not be" is the strongest claim available.
  ///
  /// In en, this message translates to:
  /// **'The device connected, but no serial port was found on it, so it may not be an ELM327 adapter.'**
  String get connectTransportBleNoSerialCharacteristic;

  /// TransportIssue.classicAllTiersRefused. Every Bluetooth Classic tier was refused; unpaired is the most common cause by a wide margin, which is why the copy names it while the identifier does not.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the adapter. Pair it in the system Bluetooth settings first, and check that it is plugged into the OBD socket with the ignition on.'**
  String get connectTransportClassicAllTiersRefused;

  /// TransportIssue.classicConnectTimeout. Retrying immediately tends to make this worse, which is why the wait is stated rather than implied.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the adapter timed out. It may still be answering — wait a few seconds rather than retrying straight away.'**
  String get connectTransportClassicConnectTimeout;

  /// TransportIssue.serialPortOpenFailed. Desktop only. The port is created by the operating system, not by this app, so the remedy is outside it.
  ///
  /// In en, this message translates to:
  /// **'Could not open the serial port. Check that the system has created one for this adapter (COMx on Windows, /dev/rfcomm* on Linux) and that the ignition is on.'**
  String get connectTransportSerialPortOpenFailed;

  /// TransportIssue.serialDroppedOnOpen. Distinct from failing to open: something answered, then went away.
  ///
  /// In en, this message translates to:
  /// **'The serial port opened and closed again immediately.'**
  String get connectTransportSerialDroppedOnOpen;

  /// TransportIssue.notConnected. Refused before any byte left the app, which is the one case where "not sent" is a fact rather than an inference, so it is stated flatly.
  ///
  /// In en, this message translates to:
  /// **'Nothing is connected, so the command was not sent.'**
  String get settingsManualCommandNotConnected;

  /// TransportIssue.linkDroppedMidSession. The link went away without being asked to. It must not claim the command was not sent: the bytes may already have left, and a manual command can be one that changes something.
  ///
  /// In en, this message translates to:
  /// **'The connection to the adapter dropped while this command was in flight, so nothing answered it. Whether the adapter received the command is not known.'**
  String get settingsManualCommandLinkDropped;

  /// TransportIssue.disconnectedByApp. Carries the same Chinese sentence in the engine as linkDroppedMidSession and must not read like it: told that their connection dropped when they closed it themselves, somebody goes looking for a fault in a car that has none.
  ///
  /// In en, this message translates to:
  /// **'The app closed the connection while this command was in flight, so nothing answered it. Nothing is wrong with the adapter or the vehicle.'**
  String get settingsManualCommandDisconnectedByApp;

  /// TransportIssue.adapterSilentOnResync. Says what the app could no longer do - tell which reply belongs to which command - rather than diagnosing the adapter. Carrying on would have attributed answers to the wrong questions, which is the failure this app is arranged against.
  ///
  /// In en, this message translates to:
  /// **'The adapter\'s replies had fallen out of step with the commands sent to it, and it did not answer the check that would have put them back in step, so the connection was dropped. Connect again before retrying.'**
  String get settingsManualCommandAdapterSilentOnResync;

  /// TransportIssue.linkStoppedResponding. A watchdog timeout establishes silence and nothing else, so it must not read as a verdict on the adapter. Distinct from linkDroppedMidSession, where the transport itself reported the link gone.
  ///
  /// In en, this message translates to:
  /// **'Nothing arrived from the adapter for long enough that the connection was dropped. It may still have power; what is known is the silence.'**
  String get settingsManualCommandLinkStoppedResponding;

  /// TransportIssue.writeFailed. Not a connect failure - it happens on an open link and reaches this panel, not the connect screen. The hedge is load-bearing: a write that failed part way has already put bytes on the wire.
  ///
  /// In en, this message translates to:
  /// **'The command could not be handed to the adapter\'s connection. How much of it reached the adapter is not known.'**
  String get settingsManualCommandWriteFailed;

  /// TransportIssue.operationRetired. The app stopped asking; nothing is wrong with the adapter or the vehicle. Distinct from notConnected: a link may still exist, but this command's owner expired before any byte left.
  ///
  /// In en, this message translates to:
  /// **'This session has ended or gone to the background, so the command was not sent.'**
  String get settingsManualCommandOperationRetired;

  /// TransportIssue.requestUnaddressable. Structural: no header on this bus reaches the named controller. Distinct from queryHeaderRefused, where the adapter declined ATSH, and from notConnected, where there is no link.
  ///
  /// In en, this message translates to:
  /// **'This request cannot be addressed on the bus this vehicle is using, so it was not sent. Trying again will not change that.'**
  String get settingsManualCommandRequestUnaddressable;

  /// ManualCommandRefusalReason.emptyCommand. The box refuses before the adapter is involved at all, so it must not read as a failure of anything.
  ///
  /// In en, this message translates to:
  /// **'Nothing was typed, so nothing was sent.'**
  String get manualCommandRefusedEmpty;

  /// ManualCommandRefusalReason.moreThanOneCommand. The mechanism is the message: 03\r04 is two requests and the second one erases the vehicle's fault memory. Saying only 'refused' would leave somebody retrying the same paste.
  ///
  /// In en, this message translates to:
  /// **'This text carries a line break or another control character, which sends more than one command at once. The adapter separates commands by line break, so the second one would skip every check made here — including the one that refuses to clear fault codes. Send one command at a time.'**
  String get manualCommandRefusedMoreThanOneCommand;

  /// ManualCommandRefusalReason.adapterStateWouldChange. {command} is the text as typed and {allowed} is manualCommandAdvertisedAtQueries joined with settingsListSeparator, never a list spelled into the sentence: copy that named seven queries while the set accepted more was a false statement about what this box takes, read by the one person whose command was just refused. No count here: it is what drifted.
  ///
  /// In en, this message translates to:
  /// **'This box accepts questions, not commands that change what the adapter is. “{command}” would change the adapter\'s state while the app\'s model of it stayed as it was — the readings after it could come from a different controller, with nothing on screen to say so.\nQueries you can send: {allowed}.'**
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  );

  /// ManualCommandRefusalReason.clearHasItsOwnButton. Mode 04. It names where to go rather than only refusing, because the thing the person wanted is available and safeguarded a screen away.
  ///
  /// In en, this message translates to:
  /// **'To clear fault codes, use the Clear button on the fault-code screen. Sent from here it would skip the confirmation, the coverage check and the response validation, and it would reach only the one controller currently selected.'**
  String get manualCommandRefusedClearHasItsOwnButton;

  /// ManualCommandRefusalReason.charactersNoObdCommandHas. A whitelist rather than a list of separators to keep complete: the cost of an incomplete blacklist here is a fault-code clear nobody asked for.
  ///
  /// In en, this message translates to:
  /// **'The command “{command}” contains characters an OBD command never has. This box takes hexadecimal service codes and parameters — 0100, 03, 2211A6 — or an adapter query beginning with AT.'**
  String manualCommandRefusedCharactersNoObdCommandHas(Object command);

  /// ManualCommandRefusalReason.notAReadOnlyQuery. {allowed} is manualCommandAdvertisedServices joined with settingsListSeparator. The list was once written out beside the set and the two had already drifted: Mode 05 was admitted and the sentence still omitted it.
  ///
  /// In en, this message translates to:
  /// **'“{command}” is not a command this box knows. It takes read-only queries (Mode {allowed}) and adapter queries.'**
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed);

  /// TransportIssue.queryHeaderRefused. The adapter answered ATSH with '?'. It must not read as a failure of the vehicle: nothing was asked of the vehicle at all. The address is interpolated because a reader who cannot see which controller was meant has nothing to act on.
  ///
  /// In en, this message translates to:
  /// **'The adapter refused to aim this request at controller {header}, so it was not sent. Left on whatever address the adapter is really holding, the reply would have come back from a controller nobody asked.'**
  String commandFailureQueryHeaderRefused(Object header);

  /// TransportIssue.wholeVehicleHeaderRefused. Separate from queryHeaderRefused because what is lost differs: a scan, a clear or a VIN read is answered by the whole emissions system, and an unattributable answer to it cannot be shown as a whole-vehicle result. Says what could not be established, not that the adapter is broken.
  ///
  /// In en, this message translates to:
  /// **'The adapter refused to switch to address {address}, which is what a question asked of the whole vehicle has to go out on. Without it, replies cannot be matched to the controllers that sent them, so the request was not made.'**
  String commandFailureWholeVehicleHeaderRefused(Object address);

  /// TransportIssue.legacyScanWouldBePartial. Nothing failed - the app refused. The sentence has to say that the result would have looked clean and complete, because a partial scan presented as a whole-vehicle one is the failure this app is arranged against.
  ///
  /// In en, this message translates to:
  /// **'This vehicle uses an older bus with no standard address that reaches every controller, and the adapter is currently set to controller {installed}. A scan would have covered that one controller alone while being presented as the whole vehicle, so it was not sent. Reconnect, then scan again.'**
  String commandFailureLegacyScanWouldBePartial(Object installed);

  /// FormulaIssue.emptyFormula. Nothing was typed at all.
  ///
  /// In en, this message translates to:
  /// **'The formula is empty.'**
  String get pidFormulaEmpty;

  /// FormulaIssue.emptySubExpression. Not the same as an empty formula: something was typed, and the remedy is to finish it rather than to write one.
  ///
  /// In en, this message translates to:
  /// **'Part of the formula is empty — an operator with nothing after it, or brackets with nothing in them.'**
  String get pidFormulaEmptySubExpression;

  /// FormulaIssue.unbalancedParentheses. The bracket characters are formula syntax and are the same in both languages.
  ///
  /// In en, this message translates to:
  /// **'The brackets do not match: every ( needs a closing ).'**
  String get pidFormulaUnbalancedParentheses;

  /// FormulaIssue.unparsableTerm. {term} is the fragment the reducer stopped on, quoted back exactly as it stands in the formula so the author can find it.
  ///
  /// In en, this message translates to:
  /// **'“{term}” is not a number, an operator, or a name this editor understands.'**
  String pidFormulaUnparsableTerm(String term);

  /// FormulaIssue.functionNestingTooDeep. Names the construct to simplify; the bracket depth limit has its own message.
  ///
  /// In en, this message translates to:
  /// **'ABS(), LOG10(), LOG() and SQRT() are nested too deeply to evaluate. Simplify the formula.'**
  String get pidFormulaFunctionNestingTooDeep;

  /// FormulaIssue.parenthesisNestingTooDeep. A different construct from the function limit, so a different sentence: the author has to find a different thing.
  ///
  /// In en, this message translates to:
  /// **'The brackets are nested too deeply to evaluate. Simplify the formula.'**
  String get pidFormulaParenthesisNestingTooDeep;

  /// FormulaIssue.divisionByZero. Separate from the modulo case: the character to look for is a different one.
  ///
  /// In en, this message translates to:
  /// **'The formula divides by zero.'**
  String get pidFormulaDivisionByZero;

  /// FormulaIssue.moduloByZero.
  ///
  /// In en, this message translates to:
  /// **'The formula takes a remainder modulo zero.'**
  String get pidFormulaModuloByZero;

  /// FormulaIssue.log10NonPositiveArgument. {argument} is the value the argument reduced to, never spelled into the sentence. Answering 0 for an impossible input is what this refusal exists to avoid.
  ///
  /// In en, this message translates to:
  /// **'LOG10 needs an argument greater than 0, and this one came out as {argument}.'**
  String pidFormulaLog10NonPositiveArgument(double argument);

  /// FormulaIssue.logNonPositiveArgument. Natural log, not LOG10. {argument} is the value the argument reduced to. Answering 0 for an impossible input is what this refusal exists to avoid.
  ///
  /// In en, this message translates to:
  /// **'LOG needs an argument greater than 0, and this one came out as {argument}.'**
  String pidFormulaLogNonPositiveArgument(double argument);

  /// FormulaIssue.sqrtNegativeArgument. {argument} is the value the argument reduced to. Zero is allowed; a negative argument has no real square root and must not become 0.
  ///
  /// In en, this message translates to:
  /// **'SQRT needs an argument of 0 or greater, and this one came out as {argument}.'**
  String pidFormulaSqrtNegativeArgument(double argument);

  /// FormulaIssue.resultNotFinite. Covers a non-finite intermediate as well as a non-finite result: both mean there is no reading, and rendering either as 0 is the failure this app is arranged against.
  ///
  /// In en, this message translates to:
  /// **'The arithmetic produced no usable number, so there is no reading to show.'**
  String get pidFormulaResultNotFinite;

  /// FormulaIssue.byteBeyondResponse. {letter} is A..N and is formula syntax, not a word. Substituting 0 for a byte the ECU did not send produces a confident wrong number, which is why this is a refusal.
  ///
  /// In en, this message translates to:
  /// **'The formula refers to byte {letter}, but the reply carried only {count} bytes.'**
  String pidFormulaByteBeyondResponse(String letter, int count);

  /// FormulaIssue.baroControllerUnknown. BARO is formula syntax and stays as written.
  ///
  /// In en, this message translates to:
  /// **'BARO cannot be used here, because which controller’s ambient pressure is meant is not known.'**
  String get pidFormulaBaroControllerUnknown;

  /// FormulaIssue.baroTwoDefinitions. The controller is known and it is the definitions that are ambiguous, which is why this is not the “which controller” message.
  ///
  /// In en, this message translates to:
  /// **'Two definitions both supply ambient pressure, so the value could be either one and neither can be used. Remove one of the gauges that measures ambient pressure.'**
  String get pidFormulaBaroTwoDefinitions;

  /// FormulaIssue.baroNotYetMeasured. Absent ambient pressure is not sea level; refusing is what turns “wrong by the altitude” into “unavailable”.
  ///
  /// In en, this message translates to:
  /// **'Ambient pressure has not been read yet, so this cannot be calculated.'**
  String get pidFormulaBaroNotYetMeasured;

  /// FormulaIssue.baroMeasurementStale. A different fact from never having read one, with a different remedy: the source has stopped answering rather than not yet started.
  ///
  /// In en, this message translates to:
  /// **'The ambient pressure reading is out of date, so this cannot be calculated.'**
  String get pidFormulaBaroMeasurementStale;

  /// FormulaIssue.dependencyControllerUnknown. {reference} is the whole VAL{...} token, composed in pid_formula_copy.dart rather than written here, because braces are ARB placeholder syntax and the token must stay byte-identical in both languages.
  ///
  /// In en, this message translates to:
  /// **'{reference} cannot be resolved here, because which controller that PID belongs to is not known.'**
  String pidFormulaDependencyControllerUnknown(String reference);

  /// FormulaIssue.dependencyTwoDefinitions. The last sentence is load-bearing and must not be dropped: “remove one of the gauges” is advice that can be followed exactly and change nothing, because PollingEngine merges the physics inputs into the active set whatever is on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Two definitions both decode {key}, so the value could be either one and neither can be used. Change one of them to a different mode+PID. Note: the PIDs the estimates need (010B, 010C, 010D) are always read, so taking a gauge off the dashboard does not stop them.'**
  String pidFormulaDependencyTwoDefinitions(String key);

  /// FormulaIssue.dependencyNotYetMeasured. Covers never-read and gone-stale alike; either way substituting zero would turn a boost formula into raw manifold pressure.
  ///
  /// In en, this message translates to:
  /// **'No usable value has been read for {key} yet.'**
  String pidFormulaDependencyNotYetMeasured(String key);

  /// Editor fallback when FormulaException carries no FormulaIssue. Must never fall back to the engine's Traditional Chinese sentence.
  ///
  /// In en, this message translates to:
  /// **'This formula cannot be evaluated, and the editor has no more specific reason for it.'**
  String get pidFormulaUnidentified;

  /// PidRejection.malformedModeAndPid. Deleting every non-hex character would turn a typo into a different, perfectly valid request, so this is a refusal rather than a repair.
  ///
  /// In en, this message translates to:
  /// **'Not a valid mode+PID: hexadecimal characters only, in whole byte pairs.'**
  String get pidRejectionMalformedModeAndPid;

  /// PidRejection.serviceNotReadOnly. {services} is PollableServices.allowed joined with pidListSeparator, never a list spelled into the sentence: the allowlist is a vehicle-safety boundary somebody may add to, and copy naming four services while the set holds five is a false statement about what this app transmits.
  ///
  /// In en, this message translates to:
  /// **'Service {service} is not a read-only query and must not be sent to the vehicle over and over. Only {services} are allowed — current data, freeze frame, vehicle information and ReadDataByIdentifier.'**
  String pidRejectionServiceNotReadOnly(String service, String services);

  /// PidRejection.freezeFrameNeedsFrame. The missing byte is a frame index rather than another PID byte, which is why this is not the generic wrong-length message.
  ///
  /// In en, this message translates to:
  /// **'A freeze-frame query needs two bytes, the PID and the frame number — for example 020500 (PID 05, frame 0).'**
  String get pidRejectionFreezeFrameNeedsFrame;

  /// PidRejection.identifierNeedsTwoBytes. ReadDataByIdentifier is the service’s name in ISO 14229 and stays in English in both.
  ///
  /// In en, this message translates to:
  /// **'ReadDataByIdentifier needs a two-byte identifier — for example 221101.'**
  String get pidRejectionIdentifierNeedsTwoBytes;

  /// PidRejection.identifierWrongLength. The fallback arm for an allowed service with no example of its own; unreachable while the allowlist is 01/02/09/22, and kept because that set can grow.
  ///
  /// In en, this message translates to:
  /// **'A service {service} query needs a {bytes}-byte identifier.'**
  String pidRejectionIdentifierWrongLength(String service, int bytes);

  /// PidRejection.nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get pidRejectionNameRequired;

  /// PidRejection.invalidHeader. {text} is what the author typed, quoted back unchanged. The three widths are bus facts, not preferences.
  ///
  /// In en, this message translates to:
  /// **'“{text}” is not a valid header: 3 digits for 11-bit CAN, 6 for the legacy protocols, 8 for 29-bit CAN.'**
  String pidRejectionInvalidHeader(String text);

  /// PidRejection.boundsRequired. The editor requires both; the importer treats a blank column as a default, which is the one place the two callers legitimately differ.
  ///
  /// In en, this message translates to:
  /// **'Fill in both ends of the gauge range.'**
  String get pidRejectionBoundsRequired;

  /// PidRejection.minNotANumber.
  ///
  /// In en, this message translates to:
  /// **'The lower bound “{text}” is not a valid number.'**
  String pidRejectionMinNotANumber(String text);

  /// PidRejection.maxNotANumber.
  ///
  /// In en, this message translates to:
  /// **'The upper bound “{text}” is not a valid number.'**
  String pidRejectionMaxNotANumber(String text);

  /// PidRejection.minNotFinite. Distinct from “not a number”: double.tryParse accepts NaN and Infinity, and a NaN bound pins the needle at full scale and then wedges jsonEncode on save.
  ///
  /// In en, this message translates to:
  /// **'The lower bound has to be a finite number.'**
  String get pidRejectionMinNotFinite;

  /// PidRejection.maxNotFinite.
  ///
  /// In en, this message translates to:
  /// **'The upper bound has to be a finite number.'**
  String get pidRejectionMaxNotFinite;

  /// PidRejection.redlineNotANumber. The redline has no field in the editor and arrives from an imported definition, so the value is quoted back.
  ///
  /// In en, this message translates to:
  /// **'The redline start “{text}” is not a valid number.'**
  String pidRejectionRedlineNotANumber(String text);

  /// PidRejection.redlineNotFinite.
  ///
  /// In en, this message translates to:
  /// **'The redline start has to be a finite number.'**
  String get pidRejectionRedlineNotFinite;

  /// PidRejection.maxNotAboveMin.
  ///
  /// In en, this message translates to:
  /// **'The upper bound has to be greater than the lower bound.'**
  String get pidRejectionMaxNotAboveMin;

  /// PidCsvIssue.malformedCsv. {detail} is the CSV decoder’s own complaint and is not translated; it names an offset in the file, which is what somebody needs to find the damage.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read as CSV: {detail}'**
  String pidImportMalformedCsv(String detail);

  /// PidCsvIssue.noRows. The file parsed and is empty, which is not the same as parsing to rows that yield nothing.
  ///
  /// In en, this message translates to:
  /// **'The file has no rows in it.'**
  String get pidImportNoRows;

  /// PidCsvIssue.duplicateHeaderColumns. {columns} is joined with pidListSeparator and spelled as the file spells them — somebody has to find the column in a spreadsheet. Taking the first occurrence would be a silent choice between two columns that both claim to be the equation.
  ///
  /// In en, this message translates to:
  /// **'The header row names the same column twice: {columns}. There is no way to tell which one to use, so fix the file first.'**
  String pidImportDuplicateHeaderColumns(String columns);

  /// PidCsvIssue.missingRequiredColumns. Both lists are joined with pidListSeparator and carried as data: {required} comes from PidCsv, so it cannot go stale against the importer the way a list written into this sentence would.
  ///
  /// In en, this message translates to:
  /// **'The header row is missing required columns: {columns}. {required} are all needed.'**
  String pidImportMissingRequiredColumns(String columns, String required);

  /// PidCsvIssue.rowTooFewColumns. {line} is the 1-based line as a spreadsheet numbers it. A row number is data; never spell one into the sentence.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: not enough cells — name, short name, PID and formula are the minimum.'**
  String pidImportRowTooFewColumns(int line);

  /// PidCsvIssue.rowInvalidModeAndPid. Quotes the offending cell back, which is what the bare PidRejection.malformedModeAndPid cannot do and why the importer keeps its own message here.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: “{text}” is not a valid mode+PID (hexadecimal characters only, in whole byte pairs).'**
  String pidImportRowInvalidModeAndPid(int line, String text);

  /// PidCsvIssue.rowEmptyEquation.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: the formula cell is empty.'**
  String pidImportRowEmptyEquation(int line);

  /// PidCsvIssue.rowDefinitionRejected. {reason} is a PidRejection already rendered by pid_rejection_copy.dart, so both halves are translated. The two call sites in pid_csv.dart differ only in which validator reached the row first.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: {reason}'**
  String pidImportRowRejected(int line, String reason);

  /// PidCsvIssue.rowRangeDefaulted. A warning, not a rejection: the row is in, drawn against a scale nobody chose, and a needle reads as authoritative against whatever bounds it is drawn on.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: the gauge range was blank, so {min}–{max} was applied. Check that this scale suits this sensor.'**
  String pidImportRowRangeDefaulted(int line, double min, double max);

  /// PidCsvIssue.nothingImportable. Distinct from an empty file: there was content, and it produced nothing.
  ///
  /// In en, this message translates to:
  /// **'The file has rows in it, but none of them is a PID definition.'**
  String get pidImportNothingImportable;

  /// DtcReadFailure.noAnswer on a category panel. Not a clean result.
  ///
  /// In en, this message translates to:
  /// **'This category did not answer. Scan again.'**
  String get dtcCategoryNoAnswer;

  /// DtcReadFailure.error, including unexpected Object catches. Screen must not interpolate failure.message.
  ///
  /// In en, this message translates to:
  /// **'This category could not be read. The full error is kept in the transcript.'**
  String get dtcCategoryError;

  /// No description provided for @dtcCategoryDisconnected.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped while this category was being read.'**
  String get dtcCategoryDisconnected;

  /// DtcReadFailure.pending (NRC 0x78). Waiting is the right next step.
  ///
  /// In en, this message translates to:
  /// **'A controller received the request and is still working on it. Wait, then scan again — this is not a refusal.'**
  String get dtcCategoryPending;

  /// No description provided for @dtcCategoryUnattributed.
  ///
  /// In en, this message translates to:
  /// **'Codes came back, but response headers were off so it is not known which controllers answered. Treat this as partial, not a clean result.'**
  String get dtcCategoryUnattributed;

  /// DtcReadException.silentSources on a category panel. Message stays transcript-only.
  ///
  /// In en, this message translates to:
  /// **'{count} controller(s) did not answer this query ({controllers}). Answers that did come back are valid, but this cannot stand as a whole-vehicle result.'**
  String dtcCategorySilentControllers(int count, String controllers);

  /// DtcReadException.unresolvedSources on a category panel.
  ///
  /// In en, this message translates to:
  /// **'{count} response(s) could not be attributed to a controller ({addresses}). Codes that were read are still valid, but this cannot stand as a whole-vehicle result. Scan again.'**
  String dtcCategoryUnresolvedSources(int count, String addresses);

  /// DtcReadException.pendingSources with an answered count. Not a refusal.
  ///
  /// In en, this message translates to:
  /// **'{count} controller(s) are still working on this request ({answered} already answered). The result is incomplete. Wait, then scan again.'**
  String dtcCategoryPendingControllers(int count, int answered);

  /// DtcReadException.refusedCount on a category panel.
  ///
  /// In en, this message translates to:
  /// **'{refused} controller(s) refused ({answered} answered). This scan cannot cover the whole vehicle.'**
  String dtcCategoryRefusedControllers(int refused, int answered);

  /// DtcReadException.unrecognisedCount on a category panel. Does not interpolate the decoder sentence.
  ///
  /// In en, this message translates to:
  /// **'{count} response(s) could not be read ({answered} answered). The rest is still valid, but this scan is incomplete.'**
  String dtcCategoryUnrecognisedResponses(int count, int answered);

  /// No description provided for @connectPairedListFailed.
  ///
  /// In en, this message translates to:
  /// **'The paired Bluetooth list could not be read. Check that Bluetooth is on, then try again.'**
  String get connectPairedListFailed;

  /// No description provided for @connectBleScanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is not usable right now. Wait a moment, then search again.'**
  String get connectBleScanUnavailable;

  /// No description provided for @connectBleScanBluez.
  ///
  /// In en, this message translates to:
  /// **'No usable BlueZ/D-Bus Bluetooth service was found. Install and start the bluetooth service, then try again.'**
  String get connectBleScanBluez;

  /// No description provided for @connectBleScanUnclassified.
  ///
  /// In en, this message translates to:
  /// **'BLE search failed.'**
  String get connectBleScanUnclassified;

  /// ISO 14229 NRC 0x22 on Mode 04 when repeatWouldHarm is false. Controller id is the raw sourceId.
  ///
  /// In en, this message translates to:
  /// **'{controller} refused the clear because the vehicle state does not allow it. Most controllers will not clear with the engine running. Turn the ignition ON with the engine stopped, then try again.'**
  String dtcClearNrcConditions(String controller);

  /// No description provided for @dtcClearNrcUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{controller} does not support Mode 04 clear. Manufacturer or dealer equipment may be required.'**
  String dtcClearNrcUnsupported(String controller);

  /// No description provided for @dtcClearNrcBusy.
  ///
  /// In en, this message translates to:
  /// **'{controller} is busy. Wait, then try again.'**
  String dtcClearNrcBusy(String controller);

  /// No description provided for @dtcClearNrcSecurity.
  ///
  /// In en, this message translates to:
  /// **'{controller} requires security access before it will clear. Manufacturer or dealer equipment is required.'**
  String dtcClearNrcSecurity(String controller);

  /// No description provided for @dtcClearNrcOther.
  ///
  /// In en, this message translates to:
  /// **'{controller} refused the clear (reason code {code}). Wait, then try again.'**
  String dtcClearNrcOther(String controller, String code);

  /// No description provided for @dtcClearSilentControllers.
  ///
  /// In en, this message translates to:
  /// **'{count} controller(s) did not answer the clear ({controllers}). Controllers that answered have cleared; others may still hold codes. Rescan. Do not send another clear.'**
  String dtcClearSilentControllers(int count, String controllers);

  /// Clear refused before send because identities from the scan are still unresolved.
  ///
  /// In en, this message translates to:
  /// **'{count} response(s) from this scan could not be attributed ({addresses}), so it is not known which controllers a clear would reach. Rescan; if that address does not appear again, reconnect before trying.'**
  String dtcClearUnresolvedSources(int count, String addresses);

  /// Clear reply carried unresolved identities after something may already have erased.
  ///
  /// In en, this message translates to:
  /// **'{count} response(s) in the clear reply could not be attributed ({addresses}). Do not send another clear. Rescan to see which codes remain.'**
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses);

  /// ISO 14229 NRC 0x22 on Mode 04 when another controller may already have cleared.
  ///
  /// In en, this message translates to:
  /// **'{controller} refused the clear because the vehicle state does not allow it. Most controllers will not clear with the engine running. Turn the ignition ON with the engine stopped, then rescan to see which codes remain. Do not send another global clear — a second one can reset emissions readiness on a controller that may already have cleared.'**
  String dtcClearNrcConditionsDoNotRepeat(String controller);

  /// No description provided for @dtcClearNrcUnsupportedDoNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'{controller} does not support Mode 04 clear. Manufacturer or dealer equipment may be required. Do not send another global clear — a second one can reset emissions readiness on a controller that may already have cleared. Rescan to see which codes remain.'**
  String dtcClearNrcUnsupportedDoNotRepeat(String controller);

  /// No description provided for @dtcClearNrcBusyDoNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'{controller} is busy. Do not send another global clear — a second one can reset emissions readiness on a controller that may already have cleared. Rescan to see which codes remain.'**
  String dtcClearNrcBusyDoNotRepeat(String controller);

  /// No description provided for @dtcClearNrcSecurityDoNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'{controller} requires security access before it will clear. Manufacturer or dealer equipment is required. Do not send another global clear — a second one can reset emissions readiness on a controller that may already have cleared.'**
  String dtcClearNrcSecurityDoNotRepeat(String controller);

  /// No description provided for @dtcClearNrcOtherDoNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'{controller} refused the clear (reason code {code}). Do not send another global clear — a second one can reset emissions readiness on a controller that may already have cleared. Rescan to see which codes remain.'**
  String dtcClearNrcOtherDoNotRepeat(String controller, String code);

  /// No description provided for @sharePolicyDenied.
  ///
  /// In en, this message translates to:
  /// **'The current connection or driving state does not allow export.'**
  String get sharePolicyDenied;

  /// No description provided for @shareSafetyChanged.
  ///
  /// In en, this message translates to:
  /// **'The state changed while preparing the export, so sharing was not opened.'**
  String get shareSafetyChanged;

  /// No description provided for @shareSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'The export exceeds the 32 MiB limit.'**
  String get shareSizeLimit;

  /// No description provided for @shareStagingBusy.
  ///
  /// In en, this message translates to:
  /// **'A previous share file is still in its retention period. Try again later.'**
  String get shareStagingBusy;

  /// No description provided for @shareCleanupRequired.
  ///
  /// In en, this message translates to:
  /// **'The share staging area needs to be checked after a restart.'**
  String get shareCleanupRequired;

  /// No description provided for @shareSpaceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the free space the share file needs.'**
  String get shareSpaceUnknown;

  /// No description provided for @shareNoSpace.
  ///
  /// In en, this message translates to:
  /// **'There is not enough storage to prepare the share file.'**
  String get shareNoSpace;

  /// No description provided for @shareHandoffFailed.
  ///
  /// In en, this message translates to:
  /// **'The file is ready, but the system share sheet could not be opened.'**
  String get shareHandoffFailed;

  /// No description provided for @shareStorageFailure.
  ///
  /// In en, this message translates to:
  /// **'A storage error occurred while preparing or recording the share.'**
  String get shareStorageFailure;

  /// Share-sheet subject for a telemetry CSV/JSON export. {sessionId} is the opaque session id.
  ///
  /// In en, this message translates to:
  /// **'Local OBD record {sessionId}'**
  String shareTelemetrySubject(String sessionId);

  /// Share-sheet subject for a live adapter transcript. {stamp} is local YYYYMMDD-HHMMSS.
  ///
  /// In en, this message translates to:
  /// **'Telltale transport log {stamp}'**
  String shareRawTranscriptSubject(String stamp);

  /// No description provided for @shareRecoveredTranscriptSubject.
  ///
  /// In en, this message translates to:
  /// **'Telltale transport log (last connection)'**
  String get shareRecoveredTranscriptSubject;

  /// No description provided for @sharePidCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'Telltale custom PID definitions'**
  String get sharePidCsvSubject;

  /// No description provided for @transcriptExportUnidentified.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get transcriptExportUnidentified;

  /// InitNote.unexpected. The exception text stays on the transcript; the screen must not interpolate the raw exception.
  ///
  /// In en, this message translates to:
  /// **'This step failed with an unexpected error. The full error is kept in the transcript.'**
  String get handshakeNoteUnexpected;

  /// FormulaIssue.unsupportedConstruct. {term} is the wiki function name (INT16, LOOKUP, BARO(), …). Distinct from an unparsable typo.
  ///
  /// In en, this message translates to:
  /// **'{term} is a Torque function this dialect does not implement, so the formula cannot be evaluated here.'**
  String pidFormulaUnsupportedConstruct(String term);

  /// PidCsvIssue.rowFormulaRejected. {line} is the 1-based spreadsheet line. {reason} is already-rendered formulaIssueText.
  ///
  /// In en, this message translates to:
  /// **'Row {line}: {reason}'**
  String pidImportRowFormulaRejected(int line, String reason);
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
