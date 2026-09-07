// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Bus activity alert.';

  @override
  String get adapterErrorBufferFull => 'The adapter\'s buffer overflowed.';

  @override
  String get adapterErrorBus => 'Bus error; the wiring may be the cause.';

  @override
  String get adapterErrorBusBusy => 'The bus is busy.';

  @override
  String get adapterErrorBusInit => 'Bus initialisation failed.';

  @override
  String get adapterErrorCan => 'CAN bus error.';

  @override
  String get adapterErrorData => 'The data that arrived is not correct.';

  @override
  String get adapterErrorFeedback => 'Signal feedback error.';

  @override
  String get adapterErrorInternal => 'Adapter internal error.';

  @override
  String get adapterErrorLowPowerAlert =>
      'The adapter is about to enter low-power mode.';

  @override
  String get adapterErrorLowVoltageReset => 'Low voltage reset the adapter.';

  @override
  String get adapterErrorNoData =>
      'No reply arrived — it may be temporary silence, or the vehicle may not support this.';

  @override
  String get adapterErrorStopped => 'The transfer was interrupted.';

  @override
  String get adapterErrorUnableToConnect =>
      'Cannot reach the ECU. Check that the ignition is on.';

  @override
  String get adapterErrorUnknownCommand =>
      'The adapter does not support this command.';

  @override
  String get appTagline => 'Live vehicle telemetry';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Stopping the previous connection, one moment…';

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
  String get connectIssueAdapterAcceptedThenSilent =>
      'The adapter accepted the connection but answered nothing in time. Usually it is not powered yet — most OBD sockets only supply power with the ignition on — or another app is already connected to it, in which case close that one and try again.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'The adapter did not answer the reset command ($command). This device may not be an ELM327 adapter, or the connection may have gone to the wrong device.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'The adapter stopped responding and the connection has been dropped.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'The connection failed while it was being established. Check that the adapter has power and is nearby, then try again. The full error is kept in the log below.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'Initialisation did not pass. The adapter may not be compatible.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'Initialisation failed at $command ($reason). Check that the adapter is seated properly and the vehicle\'s ignition is on.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'The previous connection is still being stopped and the adapter has not been released yet. Wait a few seconds and try again.';

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
  String get connectTransportBleDescription =>
      'GATT UART — a newer low-energy adapter';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — the most common budget ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'A built-in simulated ECU — the whole app with no hardware';

  @override
  String get connectTransportDemoTitle => 'Demo simulator';

  @override
  String get connectTransportWifiDescription =>
      'A TCP port, usually 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

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
  String get dashboardChoosePids => 'Choose PIDs';

  @override
  String get dashboardEmptyBody =>
      'Pick the signals you want to watch on the PID page and they will appear here.';

  @override
  String get dashboardEmptyTitle => 'The dashboard is empty';

  @override
  String get dashboardGenericObd => 'Generic OBD';

  @override
  String get dashboardLocalRecordings => 'Local recordings';

  @override
  String get dashboardNotConnected => 'Not connected';

  @override
  String get dashboardSingleRequestMode => 'Single request mode';

  @override
  String get dashboardVinRead => 'VIN read';

  @override
  String get dashboardWorkspaceGauges => 'Gauges';

  @override
  String get dashboardWorkspaceTrends => 'Trends';

  @override
  String get datumBadgeCommunityDecode => 'Community decode';

  @override
  String get datumBadgeDemo => 'Simulated';

  @override
  String get datumBadgeEstimated => 'Estimated';

  @override
  String get datumBadgeExperimental => 'Experimental';

  @override
  String get datumBadgeFieldVerified => 'Field-verified';

  @override
  String get datumBadgeInvalid => 'Invalid';

  @override
  String get datumBadgeJustUpdated => 'Just updated';

  @override
  String get datumBadgeOutOfReferenceRange => 'Out of range';

  @override
  String get datumBadgePartial => 'Partial';

  @override
  String get datumBadgeStale => 'Stale';

  @override
  String get datumBadgeTentativeDecode => 'Tentative decode';

  @override
  String get datumBadgeUnverified => 'Unverified';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => 'Unverified on this vehicle';

  @override
  String get datumBadgeUserSupplied => 'User-supplied';

  @override
  String get datumGapModelYearUnknown => 'Model year unknown';

  @override
  String get datumGapNoCatalogMatch => 'No catalog match';

  @override
  String get datumGapVinNotRead => 'VIN not read';

  @override
  String get datumNextStepEstimateOnly =>
      'This affects only the estimate; the other readings still apply.';

  @override
  String get datumNextStepGenericObd =>
      'You can carry on with generic OBD, or choose the vehicle by hand and fill in the parameters.';

  @override
  String get datumNextStepOtherReadings =>
      'The failure affects only this item; the other readings still apply.';

  @override
  String get datumNextStepRawOnly =>
      'The raw reply and the error can be inspected; neither may be read as a normal value.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'The assumptions are unconfirmed; an estimate is still shown.';

  @override
  String get datumReasonBusError => 'Bus error.';

  @override
  String get datumReasonFormulaError => 'Formula error.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'The fuel-use estimate is missing a required input.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'The header does not match the bus this vehicle uses.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'The horsepower estimate is missing a required input.';

  @override
  String get datumReasonMalformedPacket =>
      'Malformed packet; only the raw reply can be inspected.';

  @override
  String get datumReasonNoAnswer =>
      'No answer — the app retries in about a minute.';

  @override
  String get datumReasonNoReadingYet => 'No reading yet.';

  @override
  String get datumReasonNonFiniteValue => 'Not a finite number.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Outside the usual reference range; kept as it was read.';

  @override
  String get datumReasonPidUnsupported =>
      'This vehicle does not support this PID.';

  @override
  String get datumReasonUnsafeService =>
      'This service is not a read-only query.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'This service is not a read-only query, so it was not sent.';

  @override
  String get datumStatusAssumptions => 'Assumptions';

  @override
  String get datumStatusClose => 'Close';

  @override
  String get datumStatusFollowsData => 'Status follows the data';

  @override
  String get datumStatusFormula => 'Formula';

  @override
  String get derivedAirflow => 'Airflow';

  @override
  String get derivedEcuFuelTitle => 'ECU fuel data';

  @override
  String get derivedEcuReported => 'ECU reported';

  @override
  String get derivedEngineHorsepower => 'Engine power';

  @override
  String get derivedEstimatedFuelTitle => 'Estimated fuel use';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Estimate formulas and assumptions';

  @override
  String get derivedEstimatesTitle => 'Estimated values';

  @override
  String get derivedFuelUse => 'Fuel use';

  @override
  String get derivedTorque => 'Torque';

  @override
  String get derivedUnavailableMessage =>
      'Horsepower can only be estimated once vehicle speed and acceleration data arrive';

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
  String get dtcMonitorBoostPressure => 'Boost pressure';

  @override
  String get dtcMonitorCatalyst => 'Catalyst';

  @override
  String get dtcMonitorComponents => 'Comprehensive components';

  @override
  String get dtcMonitorEgr => 'EGR / VVT system';

  @override
  String get dtcMonitorEvaporative => 'Evaporative system';

  @override
  String get dtcMonitorExhaustSensor => 'Exhaust sensor';

  @override
  String get dtcMonitorFuelSystem => 'Fuel system';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Gasoline particulate filter (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Heated catalyst';

  @override
  String get dtcMonitorMisfire => 'Misfire';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC catalyst';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR aftertreatment';

  @override
  String get dtcMonitorOxygenSensor => 'Oxygen sensor';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Oxygen sensor heater';

  @override
  String get dtcMonitorParticulateFilter => 'Particulate filter';

  @override
  String get dtcMonitorSecondaryAir => 'Secondary air system';

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
  String get gaugeUnsupportedByVehicle => 'Not supported by this vehicle';

  @override
  String get handshakeNoteAborted => 'Stopped after an earlier step failed.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'The ECU refused the support query (negative response).';

  @override
  String get handshakeNoteEcuSilent => 'The ECU did not answer.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'The adapter did not acknowledge this command.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'The reply is not a Mode 01 positive response.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'The reply echoes a different PID from the one that was asked for.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'The support reply is too short; 41 00 and four more bytes are required.';

  @override
  String get handshakeNoteTimedOut => 'Timed out.';

  @override
  String get handshakeStepAdapterVersion => 'Read the adapter version';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Enable adaptive timing, the setting the datasheet recommends';

  @override
  String get handshakeStepBatteryVoltage => 'Read the battery voltage';

  @override
  String get handshakeStepDeviceIdentity => 'Read the device identifier string';

  @override
  String get handshakeStepEchoOff => 'Turn off command echo';

  @override
  String get handshakeStepLinefeedsOff => 'Turn off linefeeds';

  @override
  String get handshakeStepMemoryOff => 'Turn off memory writes';

  @override
  String get handshakeStepNoReason => 'no response';

  @override
  String get handshakeStepProtocolAuto =>
      'Detect the bus protocol automatically';

  @override
  String get handshakeStepProtocolDescription =>
      'Read the protocol description';

  @override
  String get handshakeStepProtocolNumber => 'Read the protocol number';

  @override
  String get handshakeStepReset => 'Software-reset the adapter';

  @override
  String get handshakeStepResponseTimeout =>
      'Set the response timeout to about 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Turn off spaces, cutting a third of the traffic';

  @override
  String get handshakeStepSupportProbe =>
      'Ask which PIDs the ECU supports, proving a vehicle answered';

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
  String get performanceArm => 'Arm the timer';

  @override
  String get performanceDisclaimer =>
      'Times come from the OBD road-speed signal. Most vehicles read 1–3 km/h high on their own speedometer, and the signal updates only about 10–20 times a second, so a result here is indicative only — not equivalent to professional test equipment.';

  @override
  String get performanceHeadline => 'Acceleration test';

  @override
  String get performanceNoSpeedSignal =>
      'There is no valid road-speed signal right now (PID 010D). The acceleration test cannot time a run without it.';

  @override
  String get performanceNotConnectedBody =>
      'The acceleration test needs live road speed. Connect an adapter, or start the built-in simulator.';

  @override
  String get performanceNotConnectedTitle => 'Not connected';

  @override
  String get performancePeakSpeed => 'Peak speed';

  @override
  String get performanceReset => 'Reset';

  @override
  String get performanceSecondsUnit => 'seconds';

  @override
  String get performanceSpeedGaugeLabel => 'Speed';

  @override
  String get performanceSpeedTraceHeading => 'Speed trace';

  @override
  String get performanceSplitsHeading => 'Splits';

  @override
  String get performanceStateAborted =>
      'The speed signal stopped — this run was not completed; below is what was recorded before it went';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'Waiting for a speed signal';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Come to a complete stop first — now $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return 'Finished 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => 'Pick a target speed, then start';

  @override
  String get performanceStateRunning => 'Timing';

  @override
  String get performanceStateStaged =>
      'Ready — the clock starts when you move off';

  @override
  String get performanceSubhead =>
      'A timed run from a standing start to a target speed';

  @override
  String get performanceTargetSpeedHeading => 'Target speed';

  @override
  String get pidActionCancel => 'Cancel';

  @override
  String get pidActionDelete => 'Delete';

  @override
  String get pidArrangeBody =>
      'Drag to reorder. The dashboard fills left to right and top to bottom, so whatever is first is seen first.';

  @override
  String get pidArrangeEmptyMessage =>
      'Enable a few in the list first, then come back to order them.';

  @override
  String get pidArrangeEmptyTitle => 'No PID is enabled yet';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Add the $count confirmed';
  }

  @override
  String get pidBulkActionAllActive => 'All already enabled';

  @override
  String get pidBulkActionIncomplete => 'Scan data is incomplete';

  @override
  String get pidBulkActionLocked => 'Cannot change while recording';

  @override
  String get pidBulkActionPending => 'Waiting for scan results';

  @override
  String get pidBulkActionZero => 'No confirmed supported PIDs';

  @override
  String pidBulkAddCount(int count) {
    return 'Add $count';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return 'Add $count confirmed supported PIDs?';
  }

  @override
  String pidBulkAdded(int count) {
    return 'Added $count confirmed supported PIDs.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count support blocks are still unconfirmed — this adds only the items with positive evidence.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Will add $count. The more PIDs are enabled, the less often each one may refresh.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confirmed';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'No contiguous coverage established yet';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Contiguous coverage 01–$through (reached the end)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Contiguous coverage 01–$through (unknown beyond)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => 'This support scan finished';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'The support scan was interrupted';

  @override
  String get pidCapabilityPhaseNotStarted => 'Scan not started';

  @override
  String get pidCapabilityPhaseRunning =>
      'Confirming what this vehicle supports';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'Vehicle-supported PIDs. $phase. $confirmed confirmed. $unknown unknown blocks.';
  }

  @override
  String get pidCapabilityTitle => 'Vehicle-supported PIDs';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown unknown blocks';
  }

  @override
  String pidEditorCollision(String name) {
    return 'A custom PID already uses this combination ($name). Use a different mode + PID, header, or name suffix.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'The definition for “$name” is removed, its gauge disappears from the dashboard, and this cannot be undone.';
  }

  @override
  String get pidEditorDeleteTitle => 'Delete this PID?';

  @override
  String get pidEditorDiscard => 'Discard';

  @override
  String get pidEditorDiscardBody =>
      'The changes to this PID have not been saved, and leaving loses them.';

  @override
  String get pidEditorDiscardTitle => 'Discard unsaved changes?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N map to the response bytes; SIGNED(), ABS(), LOG10(), $valSyntax and BARO are available';
  }

  @override
  String get pidEditorFieldEquation => 'Expression';

  @override
  String get pidEditorFieldHeader => 'CAN header';

  @override
  String get pidEditorFieldMax => 'Maximum';

  @override
  String get pidEditorFieldMin => 'Minimum';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorFieldName => 'Name';

  @override
  String get pidEditorFieldSample => 'Test response bytes';

  @override
  String get pidEditorFieldShortName => 'Short name (shown on the gauge)';

  @override
  String get pidEditorFieldUnits => 'Units';

  @override
  String get pidEditorHeaderHelper => '7E0 = engine';

  @override
  String get pidEditorKeepEditing => 'Keep editing';

  @override
  String get pidEditorModeAndPidHelper => 'For example 010C or 221101';

  @override
  String get pidEditorSampleHelper =>
      'Enter hex to preview the result as you type';

  @override
  String get pidEditorSave => 'Save';

  @override
  String get pidEditorSectionFormula => 'Formula';

  @override
  String get pidEditorSectionIdentity => 'Identity';

  @override
  String get pidEditorSectionQuery => 'Query';

  @override
  String get pidEditorSectionRangeAndPriority => 'Gauge range and priority';

  @override
  String get pidEditorTitleEdit => 'Edit PID';

  @override
  String get pidEditorTitleNew => 'New custom PID';

  @override
  String pidExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get pidExportNoCustomPids => 'There are no custom PIDs to export.';

  @override
  String get pidImportNothingToImport => 'No definitions to import.';

  @override
  String pidImportPickerFailed(String error) {
    return 'Could not open the file picker: $error';
  }

  @override
  String pidImportReadFailed(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Enabled only';

  @override
  String get pidManagerAdd => 'New';

  @override
  String get pidManagerArrangeDashboard => 'Arrange dashboard';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active enabled · $total available';
  }

  @override
  String get pidManagerExportCsv => 'Export custom PIDs';

  @override
  String get pidManagerHeadline => 'PID manager';

  @override
  String get pidManagerImportCsv => 'Import CSV';

  @override
  String get pidManagerMoreActions => 'More';

  @override
  String get pidManagerNoMatchMessage =>
      'Try another keyword, or create a custom PID.';

  @override
  String get pidManagerNoMatchTitle => 'No matching PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => 'Powertrain-battery catalog';

  @override
  String get pidManagerSearchHint => 'Search by name or PID code…';

  @override
  String get pidPickCsvDialogTitle => 'Choose a PID definition CSV';

  @override
  String get pidPillCustom => 'Custom';

  @override
  String get pidPillUnsupported => 'Unsupported';

  @override
  String get pidPreviewCannotEvaluate => 'Cannot evaluate';

  @override
  String get pidPreviewResultLabel => 'Result';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'The preview substitutes $valueString for $dependencies; the real value comes from that PID once connected.';
  }

  @override
  String get pidPreviewTitle => 'Live preview';

  @override
  String get pidPriorityHigh => 'High';

  @override
  String get pidPriorityLow => 'Low';

  @override
  String get pidPriorityMedium => 'Medium';

  @override
  String get pidPriorityVeryLow => 'Very Low';

  @override
  String get pidRowEdit => 'Edit';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Show $name on the dashboard';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · stale';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Battery signals for $profile are on for this connection';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Could not enable: $reason';
  }

  @override
  String get powertrainCancel => 'Cancel';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profiles: $profiles · Experimental one-shot reads: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'Integrity verification did not pass, so no vehicle data is shown or installed.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Offline catalog could not load';

  @override
  String get powertrainCatalogNotVerified =>
      'The catalog has not passed verification, so nothing can be installed.';

  @override
  String get powertrainCatalogRevalidate => 'Verify again';

  @override
  String get powertrainCatalogScopeNote =>
      'The catalog is wide, but “we found data” is not “your car is supported”. Research-only entries never carry a command; experimental entries still read one command at a time, each after its own confirmation.';

  @override
  String get powertrainCatalogSearchHint =>
      'Search make, model, variant or market…';

  @override
  String get powertrainCatalogTitle => 'Powertrain battery catalog';

  @override
  String get powertrainChooseCommandNote =>
      'One command per attempt: no scan, no batch, no automatic retry.';

  @override
  String get powertrainChooseCommandTitle =>
      'Choose one pinned read-only query';

  @override
  String get powertrainClose => 'Close';

  @override
  String get powertrainConfirmAccept => 'This is the car';

  @override
  String get powertrainConfirmBody =>
      'Installed profile signals are read only after you confirm this car is that model, and the confirmation lasts for this connection alone.';

  @override
  String get powertrainConfirmButton => 'Confirm vehicle';

  @override
  String get powertrainConfirmDialogBody =>
      'Once confirmed, this profile\'s read-only battery queries are polled for the rest of this connection. The wrong profile can produce numbers that look plausible and are wrong — cancel if you are not sure.';

  @override
  String get powertrainConfirmDialogTitle => 'Confirm the connected vehicle';

  @override
  String get powertrainConfirmTitle =>
      'Vehicle battery signals await confirmation';

  @override
  String get powertrainConnectFirst =>
      'Connect first; experimental authorization is never kept across connections.';

  @override
  String get powertrainConnectionChanged =>
      'The connection changed — confirm the vehicle again for the new connection.';

  @override
  String get powertrainEnableLabInSettings =>
      'Turn on the experimental battery laboratory in Settings first.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Project vehicle';

  @override
  String get powertrainEvidenceSourceBacked => 'Source data';

  @override
  String get powertrainEvidenceSyntheticRig => 'Synthetic rig';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'This is a candidate read labelled by the source\'s authors, not a manufacturer or cross-model safety guarantee; ELM327 only forwards the command. The raw command and reply stay in the local diagnostic transcript and are not uploaded automatically by this feature; decoded values are never installed as a PID or added to a gauge. Cancelling does not affect ordinary OBD functions.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'One-shot experimental read-only confirmation';

  @override
  String get powertrainExperimentalIdentityAck =>
      'I have checked the market, model and model year the source knows, and I accept the unconfirmed fields';

  @override
  String get powertrainExperimentalParkedAck =>
      'The vehicle is safely parked; I understand this reads once and the number may still not apply';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Accepts RX $responder only, payload length $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Market';

  @override
  String get powertrainFieldModel => 'Model';

  @override
  String get powertrainFieldModelYear => 'Model year';

  @override
  String get powertrainFieldVariant => 'Variant';

  @override
  String get powertrainFilterAll => 'All';

  @override
  String get powertrainIdentityEvidenceExact => 'direct evidence';

  @override
  String get powertrainIdentityEvidenceNone => 'none';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'partial evidence';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Source identity evidence: $fields\nUnconfirmed fields: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'unknown';

  @override
  String get powertrainInstallButton => 'Install battery signals';

  @override
  String get powertrainInstallConfirm => 'Install';

  @override
  String get powertrainInstallDialogTitle =>
      'Install this model\'s battery signals';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The data comes from community sources and has been independently corroborated; it is still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This is an experimental decode with no independent-corroboration requirement, unverified on this vehicle, and still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureReady =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The source data is fuller; it is still not a manufacturer guarantee.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This entry is for research only and should not be installed.';

  @override
  String powertrainInstallFailed(String reason) {
    return 'Cannot install: $reason';
  }

  @override
  String get powertrainInstallIdentityAck =>
      'My vehicle matches the market, model and model year above';

  @override
  String get powertrainInstalledRemoveButton => 'Installed · remove signals';

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
  String get powertrainNoMatchBody =>
      'Try a make or model name, or switch to another powertrain type.';

  @override
  String get powertrainNoMatchTitle => 'No matching vehicle';

  @override
  String powertrainNotAuthorized(String reason) {
    return 'Not authorized: $reason';
  }

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Not installable in this release';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Primary source: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Passed the responder, echo, exact length, formula and range checks.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Connect for a one-shot read-only query';

  @override
  String get powertrainProbeConnectToTryOnce => 'Connect to try one read first';

  @override
  String get powertrainProbeDidNotFinish =>
      'The one-shot query did not finish; no value was published or kept.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Turn on the laboratory in Settings first';

  @override
  String get powertrainProbeInProgress => 'Reading once…';

  @override
  String get powertrainProbeNoValuePublished =>
      'No value was published; a structural or decode error is quarantined until you reconnect.';

  @override
  String get powertrainProbeOnceButton => 'Read once only';

  @override
  String get powertrainProbePassedTitle => 'One-shot query passed';

  @override
  String get powertrainProbePickOneRead => 'Pick one command, read once';

  @override
  String get powertrainProbeReconnectFirst => 'Reconnect, then try again';

  @override
  String get powertrainProbeRefusedTitle => 'One-shot query refused';

  @override
  String get powertrainProbeTryOnceFirst => 'Try one read first';

  @override
  String get powertrainProfileNotVerified =>
      'The profile is not in the verified catalog';

  @override
  String get powertrainQuarantinedPill => 'Quarantined · reconnect';

  @override
  String powertrainQuarantinedSnack(String reason) {
    return 'Quarantined for this connection: $reason';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Research only — never queries';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'A storage error happened while restoring earlier installs. It has been rescheduled — try again.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Independent corroboration: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Signals: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'Source file SHA-256: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Community · unverified';

  @override
  String get powertrainStatusExperimental => 'Experimental · unverified';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimental · read once';

  @override
  String get powertrainStatusReady => 'Fuller source data';

  @override
  String get powertrainStatusResearchOnly => 'Research only';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Removed the installed signals for $name.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Model year: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Model year';

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
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'These are places where the adapter\'s account of itself does not add up, not evidence that it misread the car. The only way to confirm a value is a second independent measurement (see the field guide).';

  @override
  String get settingsAdapterNoContradictions =>
      'No self-description contradictions found. That only means it is consistent about itself — it is not evidence that the chip is genuine, and not evidence that the numbers it reports are correct. On a clone, the version string is just text somebody chose.';

  @override
  String get settingsAdapterNoVersion => '(no version reported)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'What the adapter says about itself';

  @override
  String get settingsBatteryLabDialogBody =>
      'These are reverse-engineered candidate sources, not manufacturer documentation, and not Telltale support for your vehicle. Even a read-only query can wake a controller; a decoded number may look plausible and still not apply.';

  @override
  String get settingsBatteryLabDialogTitle => 'Turn on the battery laboratory';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'The battery laboratory is off for this run, but the setting could not be saved; the next launch may show the laboratory again, and every query still needs its own confirmation.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Could not save the battery laboratory setting; it stays off.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'I understand that the source data and the synthetic tests do not prove this applies to my own vehicle';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Only reveals one-shot read-only queries whose sources are complete and hash-bound. It does not install PIDs, poll, add gauges, or treat research data as support.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Battery laboratory (experimental)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Unlock one-shot read-only queries only';

  @override
  String get settingsBatteryLabWireAck =>
      'I understand this unlocks only one-shot queries at fixed Mode 21/22 addresses from the catalog — not scanning, not a diagnostic session, not security access, not writing, not control';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsCatalogChoose => 'Choose from the official catalog';

  @override
  String get settingsCatalogCorrupt =>
      'The official offline catalog is damaged or could not be loaded; nothing was applied.';

  @override
  String get settingsCatalogNothingApplicable =>
      'This official configuration has no field that can be applied safely to the current formulas; the existing profile is unchanged.';

  @override
  String get settingsCatalogScope =>
      'The bundled snapshot is the official U.S. EPA Find-a-Car data; it covers only that market and the configurations inside the snapshot, not every brand or model year worldwide.';

  @override
  String get settingsCatalogVerifying => 'Verifying the offline catalog…';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsConnectionSection => 'Connection';

  @override
  String get settingsDiagnosticsSection => 'Diagnostic transcript';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Transmission efficiency $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return 'Apply $count official fields';
  }

  @override
  String get settingsEpaChooseExact => 'Choose an exact configuration';

  @override
  String get settingsEpaCloseNoFields => 'Close (no fields to apply)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA configuration $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cyl';
  }

  @override
  String get settingsEpaDriveUnknown => 'Drive unknown';

  @override
  String get settingsEpaFuelUnknown => 'Fuel unknown';

  @override
  String get settingsEpaMake => 'EPA make';

  @override
  String get settingsEpaModel => 'Model';

  @override
  String get settingsEpaNoConfigurations =>
      'No configurations available for this model';

  @override
  String get settingsEpaNoSafeFields =>
      'This configuration has no field that can be applied safely to the current formulas; nothing is guessed.';

  @override
  String get settingsEpaPickInOrder =>
      'Choose model year, make and model in order';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'U.S.-market snapshot configurations for $firstYear–$lastYear only. Models that share a name still need the model year, transmission, fuel and EPA ID to tell them apart.';
  }

  @override
  String get settingsEpaPickerTitle => 'Official U.S. EPA vehicle catalog';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Only $fields will be applied. Mass, VE, Cd, frontal area, Crr and transmission efficiency stay unresolved.';
  }

  @override
  String get settingsEpaYear => 'Model year';

  @override
  String get settingsExperimentalSection => 'Experimental';

  @override
  String get settingsFieldDisplacement => 'Displacement';

  @override
  String get settingsFieldDragCoefficient => 'Drag coefficient Cd';

  @override
  String get settingsFieldDrivetrain => 'Drivetrain';

  @override
  String get settingsFieldFrontalArea => 'Frontal area';

  @override
  String get settingsFieldFuel => 'Fuel';

  @override
  String get settingsFieldMass => 'Mass';

  @override
  String get settingsFieldMassWithDriver => 'Mass (with driver)';

  @override
  String get settingsFieldRollingResistance => 'Rolling resistance Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Volumetric efficiency VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Air-fuel ratio $afr · density $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => 'Fuel and drivetrain';

  @override
  String get settingsFuelTypeLabel => 'Fuel type';

  @override
  String get settingsGaugeSkinBody =>
      'Not just a colour change — each one has a different dial face, needle and motion. All of them work on dark and light backgrounds.';

  @override
  String get settingsGaugeSkinTitle => 'Gauge style';

  @override
  String get settingsGoToConnect => 'Go to Connect';

  @override
  String get settingsHeadline => 'Settings';

  @override
  String get settingsLicenseLegalese =>
      'Powertrain battery sources, transformations, and reuse terms are bundled with this app.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Send one command straight to the adapter — for example ATI, ATDPN, 0100. It joins the same queue as normal polling and does not jump ahead.';

  @override
  String get settingsManualCommandFieldLabel => 'Command';

  @override
  String get settingsManualCommandNoContent => '(no response content)';

  @override
  String get settingsManualCommandSend => 'Send';

  @override
  String get settingsManualCommandTitle => 'Manual command';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsOpenSourceLicenses => 'Open source and data licences';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Connect to confirm this vehicle';

  @override
  String get settingsProfileConfirmButton =>
      'Confirm this vehicle for this connection';

  @override
  String get settingsProfileConfirmedButton => 'Confirmed for this connection';

  @override
  String get settingsProfileConfirmedDetail =>
      'The profile is confirmed for this connection. Changing any value, or reconnecting, means confirming again.';

  @override
  String get settingsProfileEstimatesIntro =>
      'Horsepower, torque and fuel use are estimated from these parameters; the closer they are to the actual vehicle, the more the estimates mean.';

  @override
  String get settingsProfileNameProvesNothing =>
      'A brand name or a VIN alone does not establish mass, drag, VE or transmission efficiency.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Not confirmed on this connection. Measured OBD readings are still shown, but values estimated from mass, VE and drag are not.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Connect to this vehicle before confirming. Confirmation expires on every reconnect, so one car\'s profile is never applied to the next.';

  @override
  String get settingsProvenanceNoneExact =>
      'No field has been resolved exactly to this vehicle; generic, hand-entered and older source values all still need confirming.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Fields with an exact official source: $fields. Every other field still needs confirming one by one.';
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
  String settingsProvenancePublishers(String publishers) {
    return 'Sources: $publishers';
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
  String get settingsStandardsFooter =>
      'This app\'s OBD2 implementation follows public standards including SAE J1979 and the ELM327 datasheet; every formula and AT command that affects hardware behaviour is cross-verified, and the results are recorded in docs/protocol-deviations.zh-TW.md. This app is not affiliated with Torque or Torque Pro.';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsVehicleProfileSection => 'Vehicle profile';

  @override
  String get settingsVinConflict => 'VIN conflict';

  @override
  String get settingsVinConflictDetail =>
      'Controllers reported different VINs, so the vehicle identity cannot be confirmed; every candidate was discarded.';

  @override
  String get settingsVinNotRead => 'VIN not read yet';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Mode 09 VIN can be read from the vehicle now; the identity is kept only for this connection. The raw diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Once connected, the VIN the vehicle reports about itself can be read; the identity does not carry into the next connection. The raw diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinRead => 'Read VIN';

  @override
  String get settingsVinReading => 'Reading…';

  @override
  String get settingsVinReportedDetail =>
      'A VIN is what the vehicle reports about itself; it does not verify the model\'s specifications. The identity does not cross connections; the diagnostic transcript may still contain the VIN.';

  @override
  String get settingsVinSimulatorReported => 'Simulator-reported VIN';

  @override
  String get settingsVinUnavailable => 'VIN unavailable';

  @override
  String get settingsVinUnavailableDetail =>
      'The vehicle may not offer one, the reply may have been incomplete, or it was not read on this connection; nothing is guessed and no characters are filled in.';

  @override
  String get settingsVinVehicleReported => 'Vehicle-reported VIN';

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
  String get telemetryCancel => 'Cancel';

  @override
  String get telemetryDamagedCollision =>
      'A finished and an unfinished file share this id — neither was chosen';

  @override
  String get telemetryDamagedCorrupt =>
      'The recording is damaged and cannot be read safely';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'File time $time';
  }

  @override
  String get telemetryDelete => 'Delete';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'This deletes $id (file time $time). It cannot be undone.';
  }

  @override
  String get telemetryDeleteDamagedTitle => 'Delete this damaged recording?';

  @override
  String get telemetryDeleteDamagedTooltip => 'Delete damaged recording';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'Delete did not finish: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => 'Confirm this delete first';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'This deletes the recording from $time. It cannot be undone.';
  }

  @override
  String get telemetryDeleteSessionTitle => 'Delete this local recording?';

  @override
  String get telemetryDemoData => 'Built-in simulator data';

  @override
  String get telemetryDismissNotice => 'Dismiss';

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
  String get telemetryExport => 'Export';

  @override
  String get telemetryExportCsv => 'Export CSV';

  @override
  String telemetryExportFailed(String reason) {
    return 'Export did not finish: $reason';
  }

  @override
  String get telemetryExportJson => 'Export JSON';

  @override
  String get telemetryExportSheetTitle => 'Export a local recording';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gaps',
      one: '1 gap',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved groups — replay and export offline',
      one: '1 saved group — replay and export offline',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit groups';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more groups not shown',
      one: '1 more group not shown',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return 'Local storage: $groups of $groupLimit groups, $used of $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => 'Not connected';

  @override
  String get telemetryOfflineSampledReplay => 'Offline sampled replay';

  @override
  String get telemetryOpenHistory => 'Open local recordings';

  @override
  String get telemetryPause => 'Pause';

  @override
  String get telemetryPendingOwnerRecovery =>
      'This process still holds the operation. If it stays here, quit Telltale completely and reopen it';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Play';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Records only the OBD signals you have enabled — no location, VIN, or account data. Trends show at most $laneLimit signals; a recording keeps all $activeCount enabled signals and adds estimated horsepower and estimated fuel rate, which rest on the vehicle assumptions.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Recording — no values yet';

  @override
  String get telemetryRecorderPhaseCompleted => 'Recording saved';

  @override
  String get telemetryRecorderPhaseFailed => 'Saving the recording failed';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Saving the recording';

  @override
  String get telemetryRecorderPhaseIdle => 'Foreground local recording';

  @override
  String get telemetryRecorderPhasePreparing => 'Preparing to record';

  @override
  String get telemetryRecorderPhaseRecording => 'Recording';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Recording $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unfinished files with no valid values were cleaned up',
      one: '1 unfinished file with no valid values was cleaned up',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count damaged or conflicting files were left unchanged',
      one: '1 damaged or conflicting file was left unchanged',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Damaged content is never used for replay or export, and can only be deleted by hand while it is safe to do so.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interrupted recordings were safely sealed',
      one: '1 interrupted recording was safely sealed',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Startup check of the recordings finished';

  @override
  String get telemetryReload => 'Reload';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count breaks',
      one: '1 break',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => 'Could not load the recording';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Replay position $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sampled points',
      one: '1 sampled point',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Recording replay';

  @override
  String get telemetryReplayUnreadable =>
      'The recording is damaged or cannot be read';

  @override
  String get telemetryRestartToRepairSave =>
      'Saving did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryRestartToRepairStartup =>
      'Startup cleanup did not finish — restart Telltale to repair the recordings';

  @override
  String get telemetryReturnToTrends => 'Back to trends';

  @override
  String get telemetryRigData => 'Test rig data';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Damaged recording files';

  @override
  String get telemetrySessionsEmpty =>
      'No local recordings yet\nConnect, then start recording';

  @override
  String get telemetrySessionsLoadFailed => 'Could not load — retry';

  @override
  String get telemetrySessionsReplayable => 'Recordings you can replay';

  @override
  String get telemetrySessionsTitle => 'Local recordings';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signals',
      one: '1 signal',
    );
    return '$_temp0';
  }

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
  String get telemetryStartRecordingButton => 'Start recording';

  @override
  String get telemetryStartSpeedUnknown =>
      'Cannot confirm the vehicle is stopped — disconnect first';

  @override
  String get telemetryStartTooManyPids =>
      'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first';

  @override
  String get telemetryStarting => 'Starting';

  @override
  String get telemetryStatusBusError => 'Bus error';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statuses',
      one: '1 status',
    );
    return '$_temp0';
  }

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

  @override
  String get telemetryStopAndSave => 'Stop and save';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valid values',
      one: '1 valid value',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Delete';

  @override
  String get transcriptDeleteBusy => 'Another file operation has not finished.';

  @override
  String get transcriptDeleteFailed =>
      'Could not delete the previous connection\'s transcript.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'The current speed or connection state does not allow deleting the transcript.';

  @override
  String get transcriptExport => 'Export';

  @override
  String get transcriptExportButton => 'Export transcript';

  @override
  String get transcriptExportExplanation =>
      'This connection keeps the opening handshake and the most recent raw traffic; if a long connection drops the middle, the file says so. When something will not read on the car, exporting the transcript and bringing it back is worth far more than one message on screen.';

  @override
  String transcriptExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get transcriptExportWithHex => 'With hex';

  @override
  String get transcriptNothingToExport => 'There is no transcript to export.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Left at $timestamp, $size. It survived the system killing Telltale or the phone losing power.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'The previous connection\'s transcript has changed — check it again.';

  @override
  String get transcriptRecoveredTitle =>
      'Transcript from the previous connection';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes bytes',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => 'Now';

  @override
  String get trendChooseSignals => 'Choose signals';

  @override
  String get trendLiveData => 'Live data';

  @override
  String get trendNoSignalsBody =>
      'Enable the signals you want to watch on the PID page first.';

  @override
  String get trendNoSignalsTitle => 'No trend signals available';

  @override
  String get trendNoUnits => 'No units';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Compare up to $limit signals. This does not change which PIDs are polled.';
  }

  @override
  String get trendPickSignalsTitle => 'Choose trend signals';

  @override
  String trendRemoveSignal(String name) {
    return 'Remove $name';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Could not save the trend display selection';

  @override
  String trendSheetBody(int limit) {
    return 'Choose at most $limit. This only changes the chart, not PID polling or a recording in progress.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Done · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'One of those signals is no longer in the PID watch list';

  @override
  String get trendSignalsHeading => 'Trend signals';

  @override
  String trendTooManySelected(int limit) {
    return 'Choose at most $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Showing the last $seconds seconds';
  }

  @override
  String get wearBack => 'Back';

  @override
  String get wearBatteryVoltageLabel => 'Battery';

  @override
  String get wearBleAdapters => 'BLE adapters';

  @override
  String get wearCancel => 'Cancel';

  @override
  String get wearConfirmVehicle => 'Confirm vehicle';

  @override
  String get wearConfirmVehicleAccept => 'Yes, this car';

  @override
  String get wearConfirmVehicleBody =>
      'Once confirmed, the read-only battery queries for this model are polled for the rest of this connection. The wrong model can return a plausible but wrong number — cancel if you are not sure.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Could not connect: $adapter';
  }

  @override
  String get wearConnecting => 'Connecting…';

  @override
  String get wearDemoSimulator => 'Demo simulator';

  @override
  String get wearDisconnect => 'Disconnect';

  @override
  String get wearDisconnectQuestion => 'Disconnect?';

  @override
  String get wearNoDevicesFound => 'No devices found';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Location';

  @override
  String get wearScanAgain => 'Rescan';

  @override
  String get wearScanFailed => 'Scan failed — try again';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'Scanning needs $permission permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission permission is permanently denied — turn it on in system settings, then try again';
  }

  @override
  String get wearScanning => 'Scanning…';

  @override
  String get telemetryRecorderNotRecording => 'Not recording';

  @override
  String get dtcKindStored => 'Stored';

  @override
  String get dtcKindPending => 'Pending';

  @override
  String get dtcKindPermanent => 'Permanent';

  @override
  String get dtcKindStoredExplanation =>
      'A confirmed fault; the dashboard fault lamp is usually lit.';

  @override
  String get dtcKindPendingExplanation =>
      'Detected once, and has not yet reached the confirmation threshold.';

  @override
  String get dtcKindPermanentExplanation =>
      'Cannot be cleared with a scan tool. The ECU clears it itself, and only once it has confirmed the repair.';

  @override
  String get dtcSystemPowertrain => 'Powertrain';

  @override
  String get dtcSystemChassis => 'Chassis';

  @override
  String get dtcSystemBody => 'Body';

  @override
  String get dtcSystemNetwork => 'Network';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Fuel and air metering, and auxiliary emission controls';

  @override
  String get dtcSubsystemFuelAirMetering => 'Fuel and air metering';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Fuel and air metering (injector circuit)';

  @override
  String get dtcSubsystemIgnitionOrMisfire => 'Ignition system or misfire';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Auxiliary emission controls';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Vehicle speed control and idle control system';

  @override
  String get dtcSubsystemComputerOutputCircuit => 'Computer output circuit';

  @override
  String get dtcSubsystemTransmission => 'Transmission';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Control modules, input and output signals';

  @override
  String get dtcDescriptionB0001 => 'Driver airbag deployment control fault';

  @override
  String get dtcDescriptionP0011 =>
      'Camshaft position A — timing over-advanced or system performance (Bank 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Camshaft position B — timing over-advanced or system performance (Bank 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Crankshaft position – camshaft position correlation (Bank 1 Sensor A)';

  @override
  String get dtcDescriptionP0087 => 'Fuel rail/system pressure too low';

  @override
  String get dtcDescriptionP0088 => 'Fuel rail/system pressure too high';

  @override
  String get dtcDescriptionP0100 =>
      'Mass air flow (MAF) sensor circuit malfunction';

  @override
  String get dtcDescriptionP0101 =>
      'Mass air flow sensor range/performance problem';

  @override
  String get dtcDescriptionP0102 => 'Mass air flow sensor circuit low input';

  @override
  String get dtcDescriptionP0103 => 'Mass air flow sensor circuit high input';

  @override
  String get dtcDescriptionP0105 =>
      'Manifold absolute pressure/barometric pressure sensor circuit malfunction';

  @override
  String get dtcDescriptionP0106 =>
      'Manifold absolute pressure sensor range/performance problem';

  @override
  String get dtcDescriptionP0107 =>
      'Manifold absolute pressure sensor circuit low input';

  @override
  String get dtcDescriptionP0108 =>
      'Manifold absolute pressure sensor circuit high input';

  @override
  String get dtcDescriptionP0110 =>
      'Intake air temperature sensor circuit malfunction';

  @override
  String get dtcDescriptionP0111 =>
      'Intake air temperature sensor range/performance problem';

  @override
  String get dtcDescriptionP0112 =>
      'Intake air temperature sensor circuit low input';

  @override
  String get dtcDescriptionP0113 =>
      'Intake air temperature sensor circuit high input';

  @override
  String get dtcDescriptionP0115 =>
      'Engine coolant temperature sensor circuit malfunction';

  @override
  String get dtcDescriptionP0116 =>
      'Engine coolant temperature sensor range/performance problem';

  @override
  String get dtcDescriptionP0117 =>
      'Engine coolant temperature sensor circuit low input';

  @override
  String get dtcDescriptionP0118 =>
      'Engine coolant temperature sensor circuit high input';

  @override
  String get dtcDescriptionP0120 =>
      'Throttle position sensor circuit malfunction';

  @override
  String get dtcDescriptionP0121 =>
      'Throttle position sensor range/performance problem';

  @override
  String get dtcDescriptionP0122 =>
      'Throttle position sensor circuit low input';

  @override
  String get dtcDescriptionP0123 =>
      'Throttle position sensor circuit high input';

  @override
  String get dtcDescriptionP0125 =>
      'Insufficient coolant temperature for closed-loop fuel control';

  @override
  String get dtcDescriptionP0128 =>
      'Coolant temperature below thermostat regulating temperature';

  @override
  String get dtcDescriptionP0130 =>
      'Oxygen sensor circuit malfunction (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Oxygen sensor circuit low voltage (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Oxygen sensor circuit high voltage (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Oxygen sensor circuit slow response (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Oxygen sensor circuit no activity detected (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Oxygen sensor heater circuit malfunction (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Oxygen sensor circuit malfunction (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Oxygen sensor circuit low voltage (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Oxygen sensor circuit high voltage (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Oxygen sensor circuit no activity detected (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Oxygen sensor heater circuit malfunction (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Oxygen sensor circuit malfunction (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Oxygen sensor heater circuit malfunction (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Oxygen sensor circuit malfunction (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Oxygen sensor heater circuit malfunction (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => 'Fuel trim malfunction (Bank 1)';

  @override
  String get dtcDescriptionP0171 => 'System too lean (Bank 1)';

  @override
  String get dtcDescriptionP0172 => 'System too rich (Bank 1)';

  @override
  String get dtcDescriptionP0173 => 'Fuel trim malfunction (Bank 2)';

  @override
  String get dtcDescriptionP0174 => 'System too lean (Bank 2)';

  @override
  String get dtcDescriptionP0175 => 'System too rich (Bank 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Fuel rail pressure sensor circuit malfunction';

  @override
  String get dtcDescriptionP0201 =>
      'Injector circuit malfunction or open — cylinder 1';

  @override
  String get dtcDescriptionP0202 =>
      'Injector circuit malfunction or open — cylinder 2';

  @override
  String get dtcDescriptionP0203 =>
      'Injector circuit malfunction or open — cylinder 3';

  @override
  String get dtcDescriptionP0204 =>
      'Injector circuit malfunction or open — cylinder 4';

  @override
  String get dtcDescriptionP0217 => 'Engine over-temperature condition';

  @override
  String get dtcDescriptionP0221 =>
      'Throttle/pedal position sensor B range/performance problem';

  @override
  String get dtcDescriptionP0222 =>
      'Throttle/pedal position sensor B circuit low input';

  @override
  String get dtcDescriptionP0223 =>
      'Throttle/pedal position sensor B circuit high input';

  @override
  String get dtcDescriptionP0234 =>
      'Turbocharger/supercharger overboost condition';

  @override
  String get dtcDescriptionP0299 =>
      'Turbocharger/supercharger A underboost condition';

  @override
  String get dtcDescriptionP0300 =>
      'Random or multiple cylinder misfire detected';

  @override
  String get dtcDescriptionP0301 => 'Cylinder 1 misfire detected';

  @override
  String get dtcDescriptionP0302 => 'Cylinder 2 misfire detected';

  @override
  String get dtcDescriptionP0303 => 'Cylinder 3 misfire detected';

  @override
  String get dtcDescriptionP0304 => 'Cylinder 4 misfire detected';

  @override
  String get dtcDescriptionP0305 => 'Cylinder 5 misfire detected';

  @override
  String get dtcDescriptionP0306 => 'Cylinder 6 misfire detected';

  @override
  String get dtcDescriptionP0307 => 'Cylinder 7 misfire detected';

  @override
  String get dtcDescriptionP0308 => 'Cylinder 8 misfire detected';

  @override
  String get dtcDescriptionP0316 =>
      'Misfire detected immediately after startup';

  @override
  String get dtcDescriptionP0325 => 'Knock sensor circuit malfunction (Bank 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Knock sensor range/performance problem (Bank 1)';

  @override
  String get dtcDescriptionP0327 => 'Knock sensor circuit low input (Bank 1)';

  @override
  String get dtcDescriptionP0328 => 'Knock sensor circuit high input (Bank 1)';

  @override
  String get dtcDescriptionP0330 => 'Knock sensor circuit malfunction (Bank 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Crankshaft position sensor circuit malfunction';

  @override
  String get dtcDescriptionP0336 =>
      'Crankshaft position sensor range/performance problem';

  @override
  String get dtcDescriptionP0340 =>
      'Camshaft position sensor circuit malfunction';

  @override
  String get dtcDescriptionP0341 =>
      'Camshaft position sensor range/performance problem';

  @override
  String get dtcDescriptionP0351 =>
      'Ignition coil A primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0352 =>
      'Ignition coil B primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0353 =>
      'Ignition coil C primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0354 =>
      'Ignition coil D primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0355 =>
      'Ignition coil E primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0356 =>
      'Ignition coil F primary/secondary circuit malfunction';

  @override
  String get dtcDescriptionP0400 =>
      'Exhaust gas recirculation (EGR) flow malfunction';

  @override
  String get dtcDescriptionP0401 =>
      'Exhaust gas recirculation (EGR) flow insufficient';

  @override
  String get dtcDescriptionP0402 =>
      'Exhaust gas recirculation (EGR) flow excessive';

  @override
  String get dtcDescriptionP0403 =>
      'Exhaust gas recirculation (EGR) control circuit malfunction';

  @override
  String get dtcDescriptionP0404 =>
      'Exhaust gas recirculation (EGR) control circuit range/performance problem';

  @override
  String get dtcDescriptionP0410 =>
      'Secondary air injection system malfunction';

  @override
  String get dtcDescriptionP0411 =>
      'Secondary air injection system incorrect flow detected';

  @override
  String get dtcDescriptionP0412 =>
      'Secondary air injection system switching valve A circuit malfunction';

  @override
  String get dtcDescriptionP0420 =>
      'Catalyst system efficiency below threshold (Bank 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Catalyst system efficiency below threshold (Bank 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Evaporative emission control system malfunction';

  @override
  String get dtcDescriptionP0441 =>
      'Evaporative emission system incorrect purge flow';

  @override
  String get dtcDescriptionP0442 =>
      'Evaporative emission system leak detected (small leak)';

  @override
  String get dtcDescriptionP0443 =>
      'Evaporative emission system purge control valve circuit malfunction';

  @override
  String get dtcDescriptionP0446 =>
      'Evaporative emission system vent control circuit malfunction';

  @override
  String get dtcDescriptionP0447 =>
      'Evaporative emission system vent control circuit open';

  @override
  String get dtcDescriptionP0449 =>
      'Evaporative emission system vent valve/solenoid circuit malfunction';

  @override
  String get dtcDescriptionP0451 =>
      'Evaporative emission system pressure sensor range/performance problem';

  @override
  String get dtcDescriptionP0452 =>
      'Evaporative emission system pressure sensor circuit low input';

  @override
  String get dtcDescriptionP0453 =>
      'Evaporative emission system pressure sensor circuit high input';

  @override
  String get dtcDescriptionP0455 =>
      'Evaporative emission system leak detected (large leak)';

  @override
  String get dtcDescriptionP0456 =>
      'Evaporative emission system leak detected (very small leak)';

  @override
  String get dtcDescriptionP0480 => 'Cooling fan 1 control circuit malfunction';

  @override
  String get dtcDescriptionP0500 => 'Vehicle speed sensor malfunction';

  @override
  String get dtcDescriptionP0505 => 'Idle control system malfunction';

  @override
  String get dtcDescriptionP0506 =>
      'Idle control system RPM lower than expected';

  @override
  String get dtcDescriptionP0507 =>
      'Idle control system RPM higher than expected';

  @override
  String get dtcDescriptionP0508 => 'Idle control system circuit low';

  @override
  String get dtcDescriptionP0509 => 'Idle control system circuit high';

  @override
  String get dtcDescriptionP0560 => 'System voltage malfunction';

  @override
  String get dtcDescriptionP0562 => 'System voltage low';

  @override
  String get dtcDescriptionP0563 => 'System voltage high';

  @override
  String get dtcDescriptionP0603 =>
      'Internal control module keep-alive memory (KAM) error';

  @override
  String get dtcDescriptionP0605 =>
      'Internal control module read-only memory (ROM) error';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM processor fault';

  @override
  String get dtcDescriptionP0700 =>
      'The transmission control module asked for the fault lamp — the fault code itself is in the transmission module and has to be read separately';

  @override
  String get dtcDescriptionP0701 =>
      'Transmission control system range/performance problem';

  @override
  String get dtcDescriptionP0702 =>
      'Transmission control system electrical fault';

  @override
  String get dtcDescriptionP0705 =>
      'Transmission range sensor circuit malfunction';

  @override
  String get dtcDescriptionP0715 =>
      'Input/turbine speed sensor circuit malfunction';

  @override
  String get dtcDescriptionP0720 => 'Output speed sensor circuit malfunction';

  @override
  String get dtcDescriptionP0730 => 'Incorrect gear ratio';

  @override
  String get dtcDescriptionP0740 =>
      'Torque converter clutch circuit malfunction';

  @override
  String get dtcDescriptionP0741 => 'Torque converter clutch stuck off';

  @override
  String get dtcDescriptionP0750 => 'Shift solenoid A malfunction';

  @override
  String get dtcDescriptionP0755 => 'Shift solenoid B malfunction';

  @override
  String get dtcDescriptionP2135 =>
      'Throttle position sensor A/B voltage correlation';

  @override
  String get dtcDescriptionU0100 => 'Lost communication with ECM/PCM';

  @override
  String get dtcDescriptionU0101 =>
      'Lost communication with the transmission control module';

  @override
  String get dtcDescriptionU0121 =>
      'Lost communication with the ABS control module';

  @override
  String get dtcDescriptionU0140 =>
      'Lost communication with the body control module';

  @override
  String get dtcDescriptionU0155 =>
      'Lost communication with the instrument panel control module';

  @override
  String get gaugeSkinCluster => 'Cluster';

  @override
  String get gaugeSkinClusterDescription =>
      'Looks like a factory instrument cluster. Needle, 270-degree dial, recessed face.';

  @override
  String get gaugeSkinMinimal => 'Minimal';

  @override
  String get gaugeSkinMinimalDescription =>
      'Half an arc, no needle, no ticks. The number is what you read, not the movement.';

  @override
  String get gaugeSkinTrack => 'Track';

  @override
  String get gaugeSkinTrackDescription =>
      'Segmented bar, no smoothing. The value lands where it lands, with nothing in between.';

  @override
  String get gaugeSkinClassic => 'Classic';

  @override
  String get gaugeSkinClassicDescription =>
      'Printed dial, numbers all the way round, a needle that settles slowly like a mechanical watch.';

  @override
  String get gaugeSkinNight => 'Night';

  @override
  String get gaugeSkinNightDescription =>
      'For driving after dark. Low brightness, a shallow arc, no animation — as little of your attention as possible.';

  @override
  String get derivedAirflowSourceMaf => 'MAF sensor';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-density estimate';

  @override
  String get derivedAirflowSourceUnavailable => 'Air mass unavailable';

  @override
  String get derivedFuelSourceStoichiometric => 'Stoichiometric estimate';

  @override
  String get derivedFuelSourceUnavailable => 'Fuel rate unavailable';

  @override
  String get telemetrySourceDemo => 'Built-in simulator';

  @override
  String get telemetrySourceRig => 'Test rig';

  @override
  String get telemetrySourceFieldApp => 'Field app connection';

  @override
  String get fuelTypeGasoline => 'Petrol';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'LPG';

  @override
  String get fuelTypeEthanolE85 => 'E85 ethanol';

  @override
  String get drivetrainFwd => 'Front-wheel drive';

  @override
  String get drivetrainRwd => 'Rear-wheel drive';

  @override
  String get drivetrainAwd => 'All-wheel drive';

  @override
  String get assumptionFieldMass => 'Mass';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Frontal area';

  @override
  String get assumptionFieldRollingResistance => 'Rolling resistance';

  @override
  String get assumptionFieldDrivetrainEfficiency => 'Drivetrain efficiency';

  @override
  String get assumptionFieldFuelType => 'Fuel';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Density';

  @override
  String get assumptionFieldDisplacement => 'Displacement';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'generic default';

  @override
  String get vehicleFieldOriginUserEntered => 'entered by you';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'official registry';

  @override
  String get vehicleFieldOriginManufacturerPublication => 'manufacturer data';

  @override
  String get vehicleFieldOriginScientificModel => 'model coefficient';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value ($origin)';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '; ';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF is either PID 0110 or speed-density (RPM × MAP × displacement × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'The estimate uses the vehicle settings as they were when this was recorded.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Reports firmware v$version, which was never released';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics never published this version, so the firmware on this adapter is not the one it claims. Many of these still work — but its description of itself cannot be trusted, and it is worth suspecting first when something will not read.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Claims v$version, yet does not know ATPPS, which v1.1 had';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'The programmable-parameter summary (ATPPS) has existed since ELM327 v1.1, and even high-end adapters such as OBDLink support it. The version it claims and the commands it actually implements do not line up.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Does not answer AT@1, the device-identity command from the first release';

  @override
  String get adapterConcernNoIdentityDetail =>
      'This command has existed since ELM327 v1.0. Not answering it means this chip implements a smaller command set than any official firmware.';

  @override
  String get telemetryReplaySampled =>
      'The preview is sampled; the export keeps every recorded event.';

  @override
  String get telemetryExportDisclosure =>
      'The export contains signal names, values, observation and source times, transport kind, protocol, frozen PID labels, units and formulas, and the estimate assumptions (mass, drag, displacement, fuel and similar parameters). JSON may also contain your own custom labels, units, formulas and complete frozen definitions. The export does not contain the VIN, GPS, an account, the adapter address, the full vehicle profile, or raw diagnostic traffic.';

  @override
  String get connectTransportCancelled =>
      'The connection attempt was stopped before it finished.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'The phone is not on any Wi-Fi network, so there is no route to the adapter. Connect to the adapter\'s Wi-Fi hotspot, then try again.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'The phone is on more than one Wi-Fi network and none of them is clearly the adapter\'s, so none was chosen. Disconnect the ones that are not the adapter\'s, then try again.';

  @override
  String get connectTransportWifiRouteRefused =>
      'The system refused to send this connection over Wi-Fi. The phone is on Wi-Fi; it was not allowed to be used for this.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'The system did not answer the request to send this connection over Wi-Fi. Wait a few seconds and try again.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'The connection could not be sent over Wi-Fi, for a reason the system did not name. The full error is kept in the log below.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Nothing answered at that address. Check the phone is on the adapter\'s Wi-Fi hotspot — if the system asked whether to stay connected without internet, choose to stay. Turning mobile data off can also help.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Nothing answered at that address in time.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'The connection worked, but the phone\'s network routing could not be put back, so the connection was dropped rather than left changed. Restart the app and try again.';

  @override
  String get connectTransportBleLinkFailed =>
      'Could not connect to the adapter. Check that it has power and is within range.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'The device connected, but no serial port was found on it, so it may not be an ELM327 adapter.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Could not connect to the adapter. Pair it in the system Bluetooth settings first, and check that it is plugged into the OBD socket with the ignition on.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'Connecting to the adapter timed out. It may still be answering — wait a few seconds rather than retrying straight away.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Could not open the serial port. Check that the system has created one for this adapter (COMx on Windows, /dev/rfcomm* on Linux) and that the ignition is on.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'The serial port opened and closed again immediately.';

  @override
  String get settingsManualCommandNotConnected =>
      'Nothing is connected, so the command was not sent.';

  @override
  String get settingsManualCommandLinkDropped =>
      'The connection to the adapter dropped while this command was in flight, so nothing answered it. Whether the adapter received the command is not known.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'The app closed the connection while this command was in flight, so nothing answered it. Nothing is wrong with the adapter or the vehicle.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'The adapter\'s replies had fallen out of step with the commands sent to it, and it did not answer the check that would have put them back in step, so the connection was dropped. Connect again before retrying.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Nothing arrived from the adapter for long enough that the connection was dropped. It may still have power; what is known is the silence.';

  @override
  String get settingsManualCommandWriteFailed =>
      'The command could not be handed to the adapter\'s connection. How much of it reached the adapter is not known.';

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'The adapter refused to aim this request at controller $header, so it was not sent. Left on whatever address the adapter is really holding, the reply would have come back from a controller nobody asked.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'The adapter refused to switch to address $address, which is what a question asked of the whole vehicle has to go out on. Without it, replies cannot be matched to the controllers that sent them, so the request was not made.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'This vehicle uses an older bus with no standard address that reaches every controller, and the adapter is currently set to controller $installed. A scan would have covered that one controller alone while being presented as the whole vehicle, so it was not sent. Reconnect, then scan again.';
  }
}
