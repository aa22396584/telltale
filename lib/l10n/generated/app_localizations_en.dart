// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Live vehicle telemetry';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get connectAnswerBleWithClassic =>
      'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, the 4.0 on the box was only the chip spec — use Bluetooth Classic instead.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Choose Bluetooth LE. It does not need pairing first — scan for it inside the app. Even if it appears in the system Bluetooth pairing list, do not pair it; that route does not work. If the scan finds nothing, check that the adapter has power, or try Wi‑Fi instead; this host does not offer Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Choose Bluetooth Classic. Pair it in system settings first; the app cannot pair it for you. The code is usually 1234 or 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Choose Wi-Fi. Connect this device to that network first, then come back and enter the address.';

  @override
  String get connectAnswerWifiPhone =>
      'Choose Wi-Fi. Join that network on the phone first, then come back and enter the address.';

  @override
  String get connectBleBody =>
      'A BLE adapter does not need to be paired first. Search, then pick your device — common names are OBDII, V-LINK, Vgate or IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'The scan finished without finding a BLE adapter. Check in order: is the light on the adapter lit — most OBD sockets are unpowered until the ignition is at ON; then range, so sit in the car before scanning. $next A BLE adapter does not need, and should not have, pairing in system settings; that route does not work.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Last, check the spec on the box: if it says 2.0 or 3.0 that is Bluetooth Classic, which never appears in this list, so use Bluetooth Classic above instead.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Last, check the spec on the box: if it says 2.0/3.0, or Wi‑Fi only, try Wi‑Fi instead (this host does not offer Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'Bluetooth permission is permanently denied. The system will not ask again, so turn it on in app settings.';

  @override
  String get connectBlePermissionNeeded =>
      'Bluetooth permission is needed to search.';

  @override
  String get connectBleScan => 'Search for BLE devices';

  @override
  String get connectBleScanning => 'Searching…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE is not available on this host yet';

  @override
  String get connectBluetoothOff =>
      'Bluetooth is off. Turn Bluetooth on in system settings first.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'Bluetooth permission is permanently denied. Turn it on in system settings, then try again.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Bluetooth permission is needed to list paired adapters.';

  @override
  String get connectBody =>
      'Plug in an ELM327 adapter and switch the ignition on, or use the built-in simulator.';

  @override
  String get connectCancel => 'Cancel';

  @override
  String get connectClassicEmptyLinuxPort =>
      'No Bluetooth serial port (/dev/rfcomm*) found. Pair the ELM327 with BlueZ first, then create an RFCOMM TTY with rfcomm bind (or the equivalent) and try again.';

  @override
  String get connectClassicEmptyPaired =>
      'No paired adapter found. Pair it in the system Bluetooth settings first (the code for most ELM327s is 1234 or 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'No Bluetooth serial port (COMx) found. Pair the ELM327 in the Windows Bluetooth settings first, and check that Device Manager shows “Standard Serial over Bluetooth link”.';

  @override
  String get connectClassicListLinuxPort =>
      'This lists the Bluetooth serial ports BlueZ has bound (/dev/rfcomm* or the equivalent). An empty list means the system has not created an RFCOMM node yet, not that the app is broken.';

  @override
  String get connectClassicListPaired =>
      'This lists every device paired with the system — headphones and speakers included, with the ones that look like adapters first. If you pick the wrong one, press Cancel rather than waiting for it to fail; you can pick another straight away.';

  @override
  String get connectClassicListWindowsPort =>
      'This lists the COM ports associated with Bluetooth (“Standard Serial over Bluetooth link”). An empty list means the system has not created a virtual serial port yet, not that the app is broken.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) is currently available on Android, macOS (IOBluetooth RFCOMM), Windows (COM) and Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'iOS does not open Bluetooth SPP to third-party apps';

  @override
  String get connectConnect => 'Connect';

  @override
  String get connectDemoBody =>
      'Simulates a 2.0 L turbocharged four-cylinder engine through idle, acceleration, cruise and deceleration cycles, with signals that stay physically related to each other (engine speed drops on a gearshift while road speed keeps rising). Fault codes, VIN reads and fastMode batch queries all work in full.';

  @override
  String get connectDemoStart => 'Start the simulator';

  @override
  String get connectHandshakeTitle => 'ELM327 initialisation';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'ELM327 initialisation (last attempt)';

  @override
  String get connectHeadline => 'Choose a connection';

  @override
  String get connectLastAdapterConnect => 'Connect now';

  @override
  String get connectLastAdapterForget => 'Forget';

  @override
  String get connectLastAdapterTitle => 'Last adapter used';

  @override
  String get connectOpenAppSettings => 'Open app settings';

  @override
  String get connectOpenSystemSettings => 'Open system settings';

  @override
  String get connectOpeningConnection => 'Opening the connection…';

  @override
  String get connectPairedPill => 'Paired';

  @override
  String get connectQuestionBle =>
      'Does the box, the shop listing or the device name say BLE, 4.0 or 5.0?';

  @override
  String get connectQuestionClassic =>
      'Neither — an older one, with 2.0 or 3.0 printed on the box?';

  @override
  String get connectQuestionWifiDesktop =>
      'Is there a new network in the Wi-Fi list on the system (something like V-LINK or WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      'Is there a new network in the Wi-Fi list on the phone (something like V-LINK or WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Search again';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Signal strength $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'The full transcript of this attempt was kept. Bringing that back helps more than a one-line message.';

  @override
  String get connectWhichIntro =>
      'Never mind the words SPP and GATT. Go by what your adapter does once it is plugged in:';

  @override
  String get connectWhichNoteGuessing =>
      'Guessing wrong costs nothing — if it will not connect, come back and try another. If you are really stuck, use the Demo simulator at the bottom to confirm the app itself is working.';

  @override
  String get connectWhichNoteIos =>
      'An iPhone can only use Wi-Fi or BLE — an ordinary Bluetooth ELM327 does not work at all on iOS. That is an OS limit, and no other app gets around it.';

  @override
  String get connectWhichTitle => 'Not sure which to pick?';

  @override
  String get connectWifiHostLabel => 'IP address';

  @override
  String get connectWifiHostRequired => 'Enter the IP address of the adapter.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Connect this computer to the Wi-Fi hotspot the adapter broadcasts first, then enter its address. If the system warns that the network cannot reach the internet, choose to stay on it. Desktop systems usually treat the hotspot as the default route; the Android Wi-Fi route binding is not needed.';

  @override
  String get connectWifiInstructionsPhone =>
      'Join the Wi-Fi hotspot the adapter broadcasts on the phone first, then enter its address. If the system asks whether to stay on a Wi-Fi network that cannot reach the internet, choose to stay on it. On Android, Telltale tries to pin its traffic to the Wi-Fi route while connected, so mobile data does not take it away.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value” is not a valid port. The range is $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Port';

  @override
  String connectWifiPortRequired(int port) {
    return 'Enter the port (most adapters use $port).';
  }

  @override
  String get datumStatusAssumptions => 'Assumptions';

  @override
  String get datumStatusClose => 'Close';

  @override
  String get datumStatusFollowsData => 'Status follows the data';

  @override
  String get datumStatusFormula => 'Formula';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'The vehicle did not answer the Mode $mode query, and Mode 03 did not answer either — so there is no telling whether the vehicle lacks support or this connection simply did not read it.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'A fault related to $category';
  }

  @override
  String get dtcClear => 'Clear';

  @override
  String get dtcClearCancel => 'Cancel';

  @override
  String get dtcClearConfirm => 'Clear them';

  @override
  String get dtcClearDialogBody =>
      'This erases stored and pending fault codes and turns the fault lamp off, and it also resets emissions readiness — the vehicle has to complete a full round of self-diagnosis again before it can pass an inspection. Permanent fault codes (Mode 0A) cannot be cleared.';

  @override
  String get dtcClearDialogFrameUnread =>
      'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'The freeze frame for $codes goes with it — the whole record of engine speed, coolant temperature and load at the moment the fault happened — and it cannot be read back until the fault happens again.';
  }

  @override
  String get dtcClearDialogTitle => 'Clear fault codes?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories in this scan did not answer completely',
      one: 'One category in this scan did not answer completely',
    );
    return '$_temp0 ($categories), so there may be fault codes you have not seen. After a clear they can never be read again.';
  }

  @override
  String get dtcClearing => 'Clearing…';

  @override
  String get dtcCompleteCleanBody =>
      'That means every controller that replied reported no fault code. It does not mean every module on the vehicle was asked.';

  @override
  String get dtcCompleteCleanTitle =>
      'None of the controllers that answered reported a fault code.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Controller $controller';
  }

  @override
  String get dtcDismiss => 'Dismiss';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'The values this controller recorded at the instant $code was confirmed. Clearing fault codes destroys this record with them.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'This controller has a freeze frame, but it did not answer the query asking which items are in it, so the contents could not be read. A rescan may work.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'This controller has a freeze frame, but none of the items in it are ones this app can decode.';

  @override
  String get dtcFreezeFrameTitle => 'The vehicle at the moment of the fault';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count further items in this freeze frame have no conversion formula in this app, so they are not listed.',
      one: 'A further item in this freeze frame has no conversion formula in this app, so it is not listed.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read them.',
      one: 'One item did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read it.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear the fault codes, because clearing destroys the record of the moment of the fault permanently. If every scan looks the same, this vehicle may not provide one.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Fault codes';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Manufacturer-specific code — check the service manual for this vehicle';

  @override
  String get dtcMilOff => 'The fault lamp is not lit';

  @override
  String get dtcMilOn => 'The fault lamp is lit';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — this app has no detailed description for this code';
  }

  @override
  String get dtcNotConnectedBody =>
      'Reading fault codes needs a connected ELM327 adapter, or the simulator running.';

  @override
  String get dtcNotConnectedTitle => 'Not connected';

  @override
  String get dtcNotScanned => 'Not scanned yet';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controllers',
      one: 'One controller',
    );
    return 'All three categories were queried to completion. $_temp0 ($controllers) implement neither pending nor permanent fault codes — normal on many vehicles, and also why this cannot be declared a fault-free vehicle.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'The categories that answered reported no fault codes.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories did not answer, so their state cannot be confirmed — that is not the same as the vehicle having no problem.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fault codes were read',
      one: 'One fault code was read',
    );
    return '$_temp0 before this category stopped, but the coverage is incomplete:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Only some controllers in this category answered and the rest did not reply, so this cannot stand as a result for the whole vehicle. $message';
  }

  @override
  String get dtcReadFailed => 'Read failed';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Every readiness monitor this controller is responsible for is complete.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitors are still unfinished',
      one: '1 monitor is still unfinished',
    );
    return '$_temp0 — an inspection now may not pass.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'This controller reported no readiness monitors at all — it may not be responsible for emissions monitoring, and that does not mean it is ready.';

  @override
  String get dtcReadinessTitle => 'Emissions readiness';

  @override
  String get dtcRescanFirst => 'Rescan first';

  @override
  String get dtcRetry => 'Retry';

  @override
  String get dtcScanBody =>
      'Reads Mode 03 stored, Mode 07 pending and Mode 0A permanent fault codes.';

  @override
  String get dtcScanTitle => 'Scan the vehicle for fault codes';

  @override
  String get dtcScanning => 'Scanning…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This controller self-reports $count confirmed fault codes.',
      one: 'This controller self-reports 1 confirmed fault code.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'This controller self-reports no confirmed fault codes.';

  @override
  String get dtcSilentCategoryHeadline => 'This category did not answer';

  @override
  String get dtcSilentPendingDetail =>
      'Pending fault codes (Mode 07) did not answer. This ECU may not implement the service, or it may simply not have been read this time — no answer cannot tell the two apart, and must not be taken to mean there are no pending faults. The stored fault-code result is unaffected.';

  @override
  String get dtcSilentPermanentDetail =>
      'Permanent fault codes (Mode 0A) did not answer. This category arrived with the OBD-II generation around 2010, so older vehicles do not always support it — but no answer can equally mean it simply was not read this time, and the two cannot be told apart. The stored fault-code result is unaffected.';

  @override
  String get dtcStartScan => 'Start scan';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'The vehicle did not answer the Mode $mode query, so whether it has stored fault codes cannot be confirmed. That is not the same thing as having no fault codes.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes',
      one: '1 code',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => 'Cannot confirm';

  @override
  String get dtcUnknownError => 'Unknown error';

  @override
  String get dtcUnknownMonitor => 'Unknown monitor';

  @override
  String get dtcVerdictCompleteClean =>
      'No fault codes from the controllers that answered';

  @override
  String get dtcVerdictPartialClean => 'Partially unconfirmed';

  @override
  String get fieldEventBody =>
      'Press only when the vehicle is fully stopped, by a passenger or by an operator who is parked. Events share one timeline with the raw OBD data, and an immediate save is attempted.';

  @override
  String get fieldEventEngineStarted => 'Engine started';

  @override
  String get fieldEventHeading => 'Field event markers';

  @override
  String get fieldEventIgnitionOn => 'Ignition on';

  @override
  String get fieldEventMemoryOnly =>
      'Recorded in this session, but the automatic save failed — export the transcript now.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Recorded and saved: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Road test started';

  @override
  String get fieldEventThrottleBlip => 'Throttle blip';

  @override
  String get fieldEventUnavailable =>
      'There is no live vehicle connection to record against.';

  @override
  String get gaugeNoData => 'No data';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'No data — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (data is stale)';
  }

  @override
  String get languageSaveFailed => 'Could not save the language. Try again.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navDtc => 'Fault codes';

  @override
  String get navPerformance => 'Timing';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Settings';

  @override
  String get recommendedPurchaseDisclosure =>
      'This is a maintainer affiliate link; a qualifying purchase may pay the maintainer a commission. It is not an adapter certification or a purchase guarantee. Listing contents and hardware revisions can change, so check the full model number and NCC number before buying. You are also free to look for other sellers yourself.';

  @override
  String get recommendedPurchaseHeading => 'Recommended adapter';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Model $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'No adapter yet? See the recommended one on $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Could not open the $store link';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Full disclosure in Settings';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'This is an affiliate link, not an adapter certification.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'View on $store';
  }

  @override
  String get settingsHeadline => 'Settings';

  @override
  String get startupCannotComplete => 'Cannot finish startup checks';

  @override
  String get startupChecking =>
      'Checking local share cache and telemetry records';

  @override
  String get startupRestartHint =>
      'Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.';

  @override
  String get startupRestartRequired => 'Restart required to continue safely';

  @override
  String get startupRetry => 'Retry';

  @override
  String get startupRetryHint =>
      'Keep Telltale in the foreground, then retry after other file work finishes. Recording, replay, export and delete stay closed until startup completes.';

  @override
  String get telemetryArtifactRestartRequired =>
      'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing';

  @override
  String get telemetryBlockedByRecorder => 'Stop and save the recording first';

  @override
  String get telemetryDeleteNeedsConfirmation => 'Confirm this delete first';

  @override
  String get telemetryEndedByBackground =>
      'Stopped when Telltale went to the background';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'The PID selection changed';

  @override
  String get telemetryEndedByDisconnect =>
      'Stopped when the connection dropped';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Reached the $minutes-minute limit';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Local recording storage is full';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Recovered after the last interruption';

  @override
  String get telemetryEndedBySessionReplacement =>
      'The connection session was replaced';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'This recording reached its size limit';

  @override
  String get telemetryEndedByStorageBackpressure => 'Storage could not keep up';

  @override
  String get telemetryEndedByStorageFailure => 'Saving failed';

  @override
  String get telemetryEndedByUser => 'Stopped by you';

  @override
  String get telemetryPendingOwnerRecovery =>
      'This process still holds the operation. If it stays here, quit Telltale completely and reopen it';

  @override
  String get telemetryRestartToRepairSave =>
      'Saving did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryRestartToRepairStartup =>
      'Startup cleanup did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryStartBusy =>
      'Another recording or file operation has not finished';

  @override
  String get telemetryStartCannotCreateFile =>
      'Could not create the recording file';

  @override
  String get telemetryStartInvalidConfiguration =>
      'This PID selection cannot be recorded safely — check the definitions';

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
  String get telemetryStartLibraryByteLimit =>
      'Not enough local storage for a recording — export or delete some first';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Local recordings reached the limit of $limit — export or delete some first';
  }

  @override
  String get telemetryStartMoving => 'Park the vehicle first';

  @override
  String get telemetryStartNeedsActivePid => 'Enable at least one PID first';

  @override
  String get telemetryStartNeedsConnection =>
      'Connect before starting a recording';

  @override
  String get telemetryStartNeedsForeground =>
      'Bring Telltale to the foreground before starting a recording';

  @override
  String get telemetryStartRecording => 'Recording started';

  @override
  String get telemetryStartSpeedUnknown =>
      'Cannot confirm the vehicle is stopped — disconnect first';

  @override
  String get telemetryStartTooManyPids =>
      'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first';

  @override
  String get telemetryStatusBusError => 'Bus error';

  @override
  String get telemetryStatusFormulaError => 'Formula error';

  @override
  String get telemetryStatusHeaderMismatch => 'Header does not match this bus';

  @override
  String get telemetryStatusNoAnswer => 'No answer — will retry';

  @override
  String get telemetryStatusStale => 'Data is stale';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Not a read-only query — nothing was sent';

  @override
  String get telemetryStatusUnsupported =>
      'The controller answered that it does not support this';
}
