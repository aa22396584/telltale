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

  /// No description provided for @dtcClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing…'**
  String get dtcClearing;

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

  /// No description provided for @pidImportPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker: {error}'**
  String pidImportPickerFailed(String error);

  /// No description provided for @pidImportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file: {error}'**
  String pidImportReadFailed(String error);

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

  /// {reason} is a technical message raised by the installer, not copy this screen owns.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: {reason}'**
  String powertrainInstallFailed(String reason);

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

  /// No description provided for @powertrainNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: {reason}'**
  String powertrainNotAuthorized(String reason);

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

  /// {reason} is produced by the consent notifier, not by this screen.
  ///
  /// In en, this message translates to:
  /// **'Quarantined for this connection: {reason}'**
  String powertrainQuarantinedSnack(String reason);

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
