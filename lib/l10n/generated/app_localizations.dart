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

  /// No description provided for @settingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeadline;

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

  /// No description provided for @telemetryDeleteNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm this delete first'**
  String get telemetryDeleteNeedsConfirmation;

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

  /// No description provided for @telemetryPendingOwnerRecovery.
  ///
  /// In en, this message translates to:
  /// **'This process still holds the operation. If it stays here, quit Telltale completely and reopen it'**
  String get telemetryPendingOwnerRecovery;

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

  /// No description provided for @telemetryStatusBusError.
  ///
  /// In en, this message translates to:
  /// **'Bus error'**
  String get telemetryStatusBusError;

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
