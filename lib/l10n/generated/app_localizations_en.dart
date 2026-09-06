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
  String get connectBluetoothPermissionDeniedForever =>
      'Bluetooth permission is permanently denied. Turn it on in system settings, then try again.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Bluetooth permission is needed to list paired adapters.';

  @override
  String get connectBluetoothOff =>
      'Bluetooth is off. Turn Bluetooth on in system settings first.';

  @override
  String get connectWifiHostRequired => 'Enter the IP address of the adapter.';

  @override
  String connectWifiPortRequired(int port) {
    return 'Enter the port (most adapters use $port).';
  }

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value” is not a valid port. The range is $min–$max.';
  }

  @override
  String get connectTranscriptKept =>
      'The full transcript of this attempt was kept. Bringing that back helps more than a one-line message.';

  @override
  String get connectDemoBody =>
      'Simulates a 2.0 L turbocharged four-cylinder engine through idle, acceleration, cruise and deceleration cycles, with signals that stay physically related to each other (engine speed drops on a gearshift while road speed keeps rising). Fault codes, VIN reads and fastMode batch queries all work in full.';

  @override
  String get connectDemoStart => 'Start the simulator';

  @override
  String get connectWifiHostLabel => 'IP address';

  @override
  String get connectWifiPortLabel => 'Port';

  @override
  String get connectConnect => 'Connect';

  @override
  String get connectOpenSystemSettings => 'Open system settings';

  @override
  String get connectSearchAgain => 'Search again';

  @override
  String get connectPairedPill => 'Paired';

  @override
  String get connectBlePermissionDeniedForever =>
      'Bluetooth permission is permanently denied. The system will not ask again, so turn it on in app settings.';

  @override
  String get connectBlePermissionNeeded =>
      'Bluetooth permission is needed to search.';

  @override
  String get connectBleBody =>
      'A BLE adapter does not need to be paired first. Search, then pick your device — common names are OBDII, V-LINK, Vgate or IOS-Vlink.';

  @override
  String get connectOpenAppSettings => 'Open app settings';

  @override
  String get connectBleScanning => 'Searching…';

  @override
  String get connectBleScan => 'Search for BLE devices';

  @override
  String get connectOpeningConnection => 'Opening the connection…';

  @override
  String get connectHandshakeTitle => 'ELM327 initialisation';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'ELM327 initialisation (last attempt)';

  @override
  String get connectCancel => 'Cancel';

  @override
  String get connectLastAdapterTitle => 'Last adapter used';

  @override
  String get connectLastAdapterConnect => 'Connect now';

  @override
  String get connectLastAdapterForget => 'Forget';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Signal strength $bars/$total';
  }

  @override
  String get connectClassicUnavailableIos =>
      'iOS does not open Bluetooth SPP to third-party apps';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) is currently available on Android, macOS (IOBluetooth RFCOMM), Windows (COM) and Linux (/dev/rfcomm*)';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE is not available on this host yet';

  @override
  String get connectWifiInstructionsPhone =>
      'Join the Wi-Fi hotspot the adapter broadcasts on the phone first, then enter its address. If the system asks whether to stay on a Wi-Fi network that cannot reach the internet, choose to stay on it. On Android, Telltale tries to pin its traffic to the Wi-Fi route while connected, so mobile data does not take it away.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Connect this computer to the Wi-Fi hotspot the adapter broadcasts first, then enter its address. If the system warns that the network cannot reach the internet, choose to stay on it. Desktop systems usually treat the hotspot as the default route; the Android Wi-Fi route binding is not needed.';

  @override
  String get connectQuestionWifiPhone =>
      'Is there a new network in the Wi-Fi list on the phone (something like V-LINK or WiFi_OBDII)?';

  @override
  String get connectQuestionWifiDesktop =>
      'Is there a new network in the Wi-Fi list on the system (something like V-LINK or WiFi_OBDII)?';

  @override
  String get connectAnswerWifiPhone =>
      'Choose Wi-Fi. Join that network on the phone first, then come back and enter the address.';

  @override
  String get connectAnswerWifiDesktop =>
      'Choose Wi-Fi. Connect this device to that network first, then come back and enter the address.';

  @override
  String get connectQuestionBle =>
      'Does the box, the shop listing or the device name say BLE, 4.0 or 5.0?';

  @override
  String get connectAnswerBleWithClassic =>
      'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, the 4.0 on the box was only the chip spec — use Bluetooth Classic instead.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, check that the adapter has power, or try Wi‑Fi instead; this host does not offer Bluetooth Classic.';

  @override
  String get connectQuestionClassic =>
      'Neither — an older one, with 2.0 or 3.0 printed on the box?';

  @override
  String get connectAnswerClassic =>
      'Choose Bluetooth Classic. Pair it in system settings first; the app cannot pair it for you. The code is usually 1234 or 0000.';

  @override
  String get connectBleEmptyScanNextClassic =>
      'Last, check the spec on the box: if it says 2.0 or 3.0 that is Bluetooth Classic, which never appears in this list, so use Bluetooth Classic above instead.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Last, check the spec on the box: if it says 2.0/3.0, or Wi‑Fi only, try Wi‑Fi instead (this host does not offer Bluetooth Classic).';

  @override
  String connectBleEmptyScan(String next) {
    return 'The scan finished without finding a BLE adapter. Check in order: is the light on the adapter lit — most OBD sockets are unpowered until the ignition is at ON; then range, so sit in the car before scanning. $next A BLE adapter does not need, and should not have, pairing in system settings; that route does not work.';
  }

  @override
  String get connectClassicEmptyPaired =>
      'No paired adapter found. Pair it in the system Bluetooth settings first (the code for most ELM327s is 1234 or 0000).';

  @override
  String get connectClassicEmptyLinuxPort =>
      'No Bluetooth serial port (/dev/rfcomm*) found. Pair the ELM327 with BlueZ first, then create an RFCOMM TTY with rfcomm bind (or the equivalent) and try again.';

  @override
  String get connectClassicEmptyWindowsPort =>
      'No Bluetooth serial port (COMx) found. Pair the ELM327 in the Windows Bluetooth settings first, and check that Device Manager shows “Standard Serial over Bluetooth link”.';

  @override
  String get connectClassicListPaired =>
      'This lists every device paired with the system — headphones and speakers included, with the ones that look like adapters first. If you pick the wrong one, press Cancel rather than waiting for it to fail; you can pick another straight away.';

  @override
  String get connectClassicListLinuxPort =>
      'This lists the Bluetooth serial ports BlueZ has bound (/dev/rfcomm* or the equivalent). An empty list means the system has not created an RFCOMM node yet, not that the app is broken.';

  @override
  String get connectClassicListWindowsPort =>
      'This lists the COM ports associated with Bluetooth (“Standard Serial over Bluetooth link”). An empty list means the system has not created a virtual serial port yet, not that the app is broken.';

  @override
  String get connectWhichTitle => 'Not sure which to pick?';

  @override
  String get connectWhichIntro =>
      'Never mind the words SPP and GATT. Go by what your adapter does once it is plugged in:';

  @override
  String get connectWhichNoteIos =>
      'An iPhone can only use Wi-Fi or BLE — an ordinary Bluetooth ELM327 does not work at all on iOS. That is an OS limit, and no other app gets around it.';

  @override
  String get connectWhichNoteGuessing =>
      'Guessing wrong costs nothing — if it will not connect, come back and try another. If you are really stuck, use the Demo simulator at the bottom to confirm the app itself is working.';
}
