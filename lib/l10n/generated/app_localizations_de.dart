// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Benachrichtigung über Busverkehr.';

  @override
  String get adapterErrorBufferFull =>
      'Der Puffer des Adapters ist übergelaufen.';

  @override
  String get adapterErrorBus =>
      'Busfehler; möglicherweise liegt die Ursache in der Verkabelung.';

  @override
  String get adapterErrorBusBusy => 'Der Bus ist belegt.';

  @override
  String get adapterErrorBusInit =>
      'Die Bus-Initialisierung ist fehlgeschlagen.';

  @override
  String get adapterErrorCan => 'CAN-Bus-Fehler.';

  @override
  String get adapterErrorData => 'Die eingegangenen Daten sind nicht korrekt.';

  @override
  String get adapterErrorFeedback => 'Signal-Rückkopplungsfehler.';

  @override
  String get adapterErrorInternal => 'Interner Fehler des Adapters.';

  @override
  String get adapterErrorLowPowerAlert =>
      'Der Adapter wechselt in Kürze in den Energiesparmodus.';

  @override
  String get adapterErrorLowVoltageReset =>
      'Eine zu niedrige Spannung hat den Adapter zurückgesetzt.';

  @override
  String get adapterErrorNoData =>
      'Es ist keine Antwort eingegangen – dies kann vorübergehende Stille sein, oder das Fahrzeug unterstützt diese Funktion möglicherweise nicht.';

  @override
  String get adapterErrorStopped => 'Die Übertragung wurde unterbrochen.';

  @override
  String get adapterErrorUnableToConnect =>
      'Die ECU ist nicht erreichbar. Prüfen Sie, ob die Zündung eingeschaltet ist.';

  @override
  String get adapterErrorUnknownCommand =>
      'Der Adapter unterstützt diesen Befehl nicht.';

  @override
  String get appTagline => 'Echtzeit-Fahrzeugtelemetrie';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Darstellung';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Die vorherige Verbindung wird beendet, einen Moment bitte…';

  @override
  String get connectAnswerBleWithClassic =>
      'Wählen Sie Bluetooth LE. Eine vorherige Kopplung ist nicht nötig – suchen Sie in der App danach. Auch wenn das Gerät in der Bluetooth-Kopplungsliste des Systems auftaucht, koppeln Sie es nicht; dieser Weg funktioniert nicht. Findet die Suche nichts, war die 4.0 auf der Verpackung nur die Chip-Angabe – verwenden Sie stattdessen Bluetooth Classic.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Wählen Sie Bluetooth LE. Eine vorherige Kopplung ist nicht nötig – suchen Sie in der App danach. Auch wenn das Gerät in der Bluetooth-Kopplungsliste des Systems auftaucht, koppeln Sie es nicht; dieser Weg funktioniert nicht. Findet die Suche nichts, prüfen Sie, ob der Adapter Strom hat, oder versuchen Sie es mit Wi‑Fi; dieser Host bietet kein Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Wählen Sie „Bluetooth Classic“ aus. Stellen Sie zunächst in den Systemeinstellungen eine Kopplung her; die App kann dies nicht für Sie übernehmen. Der Code lautet in der Regel 1234 oder 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Wählen Sie „Wi-Fi“ aus. Verbinden Sie dieses Gerät zunächst mit diesem Netzwerk und geben Sie anschließend die Adresse ein.';

  @override
  String get connectAnswerWifiPhone =>
      'Wählen Sie „Wi-Fi“ aus. Verbinden Sie sich zunächst mit diesem Netzwerk auf Ihrem Smartphone und geben Sie anschließend die Adresse ein.';

  @override
  String get connectBleBody =>
      'Ein BLE-Adapter muss nicht erst gekoppelt werden. Suchen Sie nach Ihrem Gerät und wählen Sie es anschließend aus – gängige Bezeichnungen sind OBDII, V-LINK, Vgate oder IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'Die Suche ist beendet, ohne einen BLE-Adapter zu finden. Prüfen Sie der Reihe nach: Leuchtet die Anzeige am Adapter – die meisten OBD-Buchsen sind erst mit Zündung auf ON stromführend; danach die Reichweite, setzen Sie sich also vor der Suche ins Auto. $next Ein BLE-Adapter braucht keine Kopplung in den Systemeinstellungen und sollte auch keine haben; dieser Weg funktioniert nicht.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Prüfen Sie zuletzt die Angabe auf der Verpackung: Steht dort 2.0 oder 3.0, ist es Bluetooth Classic, das in dieser Liste nie erscheint – verwenden Sie stattdessen oben Bluetooth Classic.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Überprüfen Sie abschließend die Angaben auf der Verpackung: Falls dort „2.0/3.0“ oder nur „Wi‑Fi“ angegeben ist, versuchen Sie es stattdessen mit „Wi‑Fi“ (dieser Host bietet „Bluetooth Classic“ nicht an).';

  @override
  String get connectBlePermissionDeniedForever =>
      'Die Berechtigung „Bluetooth“ wird dauerhaft verweigert. Das System wird nicht erneut danach fragen; aktivieren Sie diese daher bitte in den App-Einstellungen.';

  @override
  String get connectBlePermissionNeeded =>
      'Für die Suche ist die Berechtigung „Bluetooth“ erforderlich.';

  @override
  String get connectBleScan => 'Nach BLE-Geräten suchen';

  @override
  String get connectBleScanning => 'Wird gesucht…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE ist auf diesem Host noch nicht verfügbar';

  @override
  String get connectBluetoothOff =>
      'Bluetooth ist deaktiviert. Aktivieren Sie Bluetooth zunächst in den Systemeinstellungen.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'Die Berechtigung „Bluetooth“ wird dauerhaft verweigert. Aktivieren Sie diese in den Systemeinstellungen und versuchen Sie es anschließend erneut.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Zum Auflisten gekoppelter Adapter ist die Berechtigung „Bluetooth“ erforderlich.';

  @override
  String get connectBody =>
      'Schließen Sie einen ELM327-Adapter an und schalten Sie die Zündung ein, oder verwenden Sie den integrierten Simulator.';

  @override
  String get connectCancel => 'Abbrechen';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Es wurde kein serieller Bluetooth-Port (/dev/rfcomm*) gefunden. Koppeln Sie den ELM327 zuerst mit BlueZ, legen Sie dann mit rfcomm bind (oder gleichwertig) ein RFCOMM-TTY an und versuchen Sie es erneut.';

  @override
  String get connectClassicEmptyPaired =>
      'Es wurde kein gekoppelter Adapter gefunden. Koppeln Sie ihn bitte zunächst in den Systemeinstellungen von Bluetooth (der Code lautet bei den meisten ELM327-Geräten 1234 oder 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Es wurde kein serieller Bluetooth-Port (COMx) gefunden. Koppeln Sie den ELM327 zuerst in den Bluetooth-Einstellungen von Windows und prüfen Sie, ob der Geräte-Manager „Standardmäßig serielle Verbindung über Bluetooth“ anzeigt.';

  @override
  String get connectClassicListLinuxPort =>
      'Hier stehen die seriellen Bluetooth-Ports, die BlueZ gebunden hat (/dev/rfcomm* oder gleichwertig). Eine leere Liste heißt, dass das System noch keinen RFCOMM-Knoten angelegt hat – nicht, dass die App defekt ist.';

  @override
  String get connectClassicListPaired =>
      'Hier werden alle mit dem System gekoppelten Geräte aufgelistet – einschließlich Kopfhörer und Lautsprecher –, wobei diejenigen, die wie Adapter aussehen, an erster Stelle stehen. Sollten Sie das falsche Gerät auswählen, drücken Sie bitte auf „Abbrechen“, anstatt abzuwarten, bis der Vorgang fehlschlägt; Sie können dann sofort ein anderes Gerät auswählen.';

  @override
  String get connectClassicListWindowsPort =>
      'Hier werden die COM-Anschlüsse aufgelistet, die mit Bluetooth verknüpft sind („Standard-Seriell über Bluetooth-Verbindung“). Eine leere Liste bedeutet, dass das System noch keinen virtuellen seriellen Anschluss erstellt hat – nicht, dass die Anwendung fehlerhaft ist.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) ist derzeit für Android, macOS (IOBluetooth, RFCOMM), Windows (COM) und Linux (/dev/rfcomm*) verfügbar.';

  @override
  String get connectClassicUnavailableIos =>
      'iOS öffnet Bluetooth SPP nicht für Apps von Drittanbietern';

  @override
  String get connectConnect => 'Verbinden';

  @override
  String get connectDemoBody =>
      'Simuliert einen 2,0-Liter-Vierzylinder-Turbomotor in den Betriebsphasen Leerlauf, Beschleunigung, Konstantfahrt und Verzögerung, wobei die Signale physikalisch aufeinander abgestimmt bleiben (die Motordrehzahl sinkt beim Gangwechsel, während die Fahrgeschwindigkeit weiter ansteigt). Fehlercodes, VIN-Abfragen und fastMode-Batch-Abfragen funktionieren uneingeschränkt.';

  @override
  String get connectDemoStart => 'Simulator starten';

  @override
  String get connectHandshakeTitle => 'ELM327-Initialisierung';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'ELM327-Initialisierung (letzter Versuch)';

  @override
  String get connectHeadline => 'Wählen Sie eine Verbindung aus';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'Der Adapter hat die Verbindung akzeptiert, aber nicht rechtzeitig geantwortet. In der Regel ist er noch nicht mit Strom versorgt – die meisten OBD-Steckdosen liefern erst bei eingeschalteter Zündung Strom – oder eine andere App ist bereits mit ihm verbunden; in diesem Fall schließen Sie diese bitte und versuchen Sie es erneut.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'Der Adapter hat den Reset-Befehl ($command) nicht beantwortet. Möglicherweise handelt es sich bei diesem Gerät nicht um einen ELM327-Adapter, oder die Verbindung wurde zu einem falschen Gerät hergestellt.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'Der Adapter reagiert nicht mehr und die Verbindung wurde unterbrochen.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'Der Verbindungsaufbau ist fehlgeschlagen. Bitte überprüfen Sie, ob der Adapter mit Strom versorgt wird und sich in der Nähe befindet, und versuchen Sie es dann erneut. Der vollständige Fehlertext ist im folgenden Protokoll vermerkt.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'Die Initialisierung war nicht erfolgreich. Der Adapter ist möglicherweise nicht kompatibel.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'Die Initialisierung ist bei $command ($reason) fehlgeschlagen. Bitte überprüfen Sie, ob der Adapter richtig eingesteckt ist und die Zündung des Fahrzeugs eingeschaltet ist.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'Die vorherige Verbindung wird noch beendet, und der Adapter wurde noch nicht freigegeben. Bitte warten Sie einige Sekunden und versuchen Sie es erneut.';

  @override
  String get connectLastAdapterConnect => 'Jetzt verbinden';

  @override
  String get connectLastAdapterForget => 'Vergessen';

  @override
  String get connectLastAdapterTitle => 'Zuletzt verwendeter Adapter';

  @override
  String get connectOpenAppSettings => 'App-Einstellungen öffnen';

  @override
  String get connectOpenSystemSettings => 'Systemeinstellungen öffnen';

  @override
  String get connectOpeningConnection => 'Verbindung wird hergestellt…';

  @override
  String get connectPairedPill => 'Gekoppelt';

  @override
  String get connectQuestionBle =>
      'Ist auf der Verpackung, im Shop-Eintrag oder im Gerätenamen „BLE“, „4.0“ oder „5.0“ angegeben?';

  @override
  String get connectQuestionClassic =>
      'Weder noch – ein älteres Modell, auf dessen Verpackung „2.0“ oder „3.0“ aufgedruckt ist?';

  @override
  String get connectQuestionWifiDesktop =>
      'Gibt es in der Wi-Fi-Liste des Systems ein neues Netzwerk (etwa V-LINK oder WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      'Gibt es in der Wi-Fi-Liste auf dem Telefon ein neues Netzwerk (etwa V-LINK oder WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Erneut suchen';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Signalstärke $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'Das vollständige Protokoll dieses Versuchs wurde aufbewahrt. Dies vorzulegen ist hilfreicher als eine einzeilige Nachricht.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART – ein neuerer Low-Energy-Adapter';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP – die gängigsten preisgünstigen ELM327-Modelle';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Eine eingebaute simulierte ECU – die ganze App ohne Hardware';

  @override
  String get connectTransportDemoTitle => 'Demo-Simulator';

  @override
  String get connectTransportWifiDescription =>
      'Ein TCP-Port, in der Regel 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'Beachten Sie die Bezeichnungen „SPP“ und „GATT“ nicht. Orientieren Sie sich stattdessen daran, wie sich Ihr Adapter verhält, sobald er angeschlossen ist:';

  @override
  String get connectWhichNoteGuessing =>
      'Falsches Raten kostet nichts – wenn die Verbindung nicht zustande kommt, versuchen Sie es einfach noch einmal mit einer anderen Option. Sollten Sie wirklich nicht weiterkommen, nutzen Sie den Demo-Simulator unten auf der Seite, um zu überprüfen, ob die App selbst funktioniert.';

  @override
  String get connectWhichNoteIos =>
      'Ein iPhone kann nur Wi-Fi oder BLE verwenden – ein gewöhnlicher Bluetooth-ELM327 funktioniert unter iOS gar nicht. Das ist eine Grenze des Betriebssystems, und keine andere App umgeht sie.';

  @override
  String get connectWhichTitle =>
      'Sind Sie sich nicht sicher, welche Sie wählen sollen?';

  @override
  String get connectWifiHostLabel => 'IP-Adresse';

  @override
  String get connectWifiHostRequired =>
      'Geben Sie die IP-Adresse des Adapters ein.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Verbinden Sie diesen Computer zuerst mit dem Wi-Fi-Hotspot, den der Adapter aussendet, und geben Sie dann dessen Adresse ein. Warnt das System, dass das Netzwerk kein Internet erreicht, bleiben Sie darauf. Desktop-Systeme behandeln den Hotspot in der Regel als Standardroute; die Wi-Fi-Routenbindung von Android wird hier nicht gebraucht.';

  @override
  String get connectWifiInstructionsPhone =>
      'Verbinden Sie sich zunächst über Ihr Smartphone mit dem Wi-Fi-Hotspot, den der Adapter ausstrahlt, und geben Sie anschließend dessen Adresse ein. Falls das System Sie fragt, ob Sie in einem Wi-Fi-Netzwerk verbleiben möchten, das keinen Zugang zum Internet hat, entscheiden Sie sich dafür, darin zu verbleiben. Unter Android versucht „Telltale“, seinen Datenverkehr während der Verbindung an die „Wi-Fi“-Route zu binden, damit er nicht über das mobile Datennetz umgeleitet wird.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '„$value“ ist kein gültiger Port. Der Bereich lautet $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Port';

  @override
  String connectWifiPortRequired(int port) {
    return 'Geben Sie den Port ein (die meisten Adapter verwenden $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Gebündelte Abfrage';

  @override
  String get dashboardBatchingEnabled => 'Batch-Verarbeitung aktiviert';

  @override
  String get dashboardChoosePids => 'PIDs auswählen';

  @override
  String get dashboardEmptyBody =>
      'Wählen Sie auf der PID-Seite die Signale aus, die Sie beobachten möchten; diese werden dann hier angezeigt.';

  @override
  String get dashboardEmptyTitle => 'Das Dashboard ist leer';

  @override
  String get dashboardGenericObd => 'Generisches OBD';

  @override
  String get dashboardLocalRecordings => 'Lokale Aufzeichnungen';

  @override
  String get dashboardNotConnected => 'Nicht verbunden';

  @override
  String get dashboardPollingModeHelpAction => 'Über den Abfragemodus';

  @override
  String get dashboardPollingModeHelpBatching =>
      'Ist die Batching-Funktion aktiviert, kann Telltale PID-Anfragen zu einem Austausch zusammenfassen, um die Anzahl der Hin- und Rückläufe zu reduzieren: Gruppierte Versuche sind zulässig, und die Gruppierung wurde nicht deaktiviert. Es handelt sich hierbei weiterhin um eine Berechtigung und nicht um eine Messung, da es auch davon abhängt, welche PIDs das Fahrzeug bestätigt hat und wie viele noch ausstehen, ob bei einem bestimmten Austausch etwas gruppiert wurde.';

  @override
  String get dashboardPollingModeHelpObserved =>
      'Gebündelte Abfrage bedeutet, dass in dieser Verbindung ein Mode-01-Befehl tatsächlich mehr als eine PID mitgeführt hat. Das ist die Aufzeichnung dieses Austauschs, kein Versprechen, dass der nächste ebenfalls gruppiert, und keine Aussage über den Durchsatz.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s ist ein Wert, der in der letzten Sekunde gemessen wurde, und stellt keine Zusicherung hinsichtlich Latenz, Aktualität oder Genauigkeit dar. Er hängt vom Adapter, vom Bus, vom ECU, von den von Ihnen ausgewählten PIDs, von der Größe der einzelnen Antworten sowie von etwaigen Fehlern ab.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'Einzelanforderungsmodus heißt, dass jede Mode 01-PID einzeln gelesen wird. Telltale nutzt ihn, wenn der Bus gruppierte Anfragen überhaupt nicht annimmt, also bei jedem Nicht-CAN-Fahrzeug; solange noch kein Unterstützungsblock geantwortet hat, weil das Gruppieren von PIDs, die das Fahrzeug nicht bestätigt hat, eine zu kurze Antwort erzeugt; und nachdem eine gruppierte Anfrage nicht in einer Form zurückkam, die sich wieder auftrennen lässt – abgeschnitten, abgelehnt, weil der Adapter seinen Puffer als voll meldete, oder unbeantwortet. Die Messwerte werden weiter aktualisiert, und für sich genommen ist das kein Verbindungsfehler.';

  @override
  String get dashboardPollingModeHelpTitle => 'Polling-Modus';

  @override
  String get dashboardSingleRequestMode => 'Einzelanforderungsmodus';

  @override
  String get dashboardVinRead => 'VIN gelesen';

  @override
  String get dashboardWorkspaceGauges => 'Instrumente';

  @override
  String get dashboardWorkspaceTrends => 'Trends';

  @override
  String get datumBadgeCommunityDecode => 'Community-Entschlüsselung';

  @override
  String get datumBadgeDemo => 'Simuliert';

  @override
  String get datumBadgeEstimated => 'Geschätzt';

  @override
  String get datumBadgeExperimental => 'Experimentell';

  @override
  String get datumBadgeFieldVerified => 'In der Praxis verifiziert';

  @override
  String get datumBadgeInvalid => 'Ungültig';

  @override
  String get datumBadgeJustUpdated => 'Soeben aktualisiert';

  @override
  String get datumBadgeOutOfReferenceRange => 'Außerhalb des Bereichs';

  @override
  String get datumBadgePartial => 'Teilweise';

  @override
  String get datumBadgeStale => 'Veraltet';

  @override
  String get datumBadgeTentativeDecode => 'Vorläufige Dekodierung';

  @override
  String get datumBadgeUnverified => 'Unverifiziert';

  @override
  String get datumBadgeUnverifiedOnThisVehicle =>
      'An diesem Fahrzeug nicht verifiziert';

  @override
  String get datumBadgeUserSupplied => 'Vom Benutzer bereitgestellt';

  @override
  String get datumGapModelYearUnknown => 'Modelljahr unbekannt';

  @override
  String get datumGapNoCatalogMatch => 'Keine Übereinstimmung im Katalog';

  @override
  String get datumGapVinNotRead => 'VIN nicht gelesen';

  @override
  String get datumNextStepEstimateOnly =>
      'Dies betrifft nur die Schätzung; die übrigen Messwerte behalten ihre Gültigkeit.';

  @override
  String get datumNextStepGenericObd =>
      'Sie können mit generischem OBD weitermachen oder das Fahrzeug von Hand auswählen und die Parameter eintragen.';

  @override
  String get datumNextStepOtherReadings =>
      'Der Fehler betrifft nur diesen Wert; die anderen Messwerte behalten ihre Gültigkeit.';

  @override
  String get datumNextStepRawOnly =>
      'Die Rohantwort und der Fehler können überprüft werden; keines von beiden darf als normaler Wert interpretiert werden.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'Die Annahmen sind unbestätigt; es wird weiterhin eine Schätzung angezeigt.';

  @override
  String get datumReasonBusError => 'Busfehler.';

  @override
  String get datumReasonFormulaError => 'Formelfehler.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'Für die Kraftstoffverbrauchsschätzung fehlt eine erforderliche Eingabe.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'Der Header stimmt nicht mit dem Bus überein, den dieses Fahrzeug verwendet.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'Für die Schätzung der PS-Leistung fehlt eine erforderliche Eingabe.';

  @override
  String get datumReasonMalformedPacket =>
      'Fehlerhaftes Paket; es kann nur die Rohantwort überprüft werden.';

  @override
  String get datumReasonNoAnswer =>
      'Keine Antwort – die App versucht es in etwa einer Minute erneut.';

  @override
  String get datumReasonNoReadingYet => 'Noch kein Messwert.';

  @override
  String get datumReasonNonFiniteValue => 'Keine endliche Zahl.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Außerhalb des üblichen Referenzbereichs; der Messwert wurde unverändert beibehalten.';

  @override
  String get datumReasonPidUnsupported =>
      'Dieses Fahrzeug unterstützt diese PID nicht.';

  @override
  String get datumReasonUnsafeService =>
      'Dieser Dienst ist keine reine Leseabfrage.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Dieser Dienst ist keine reine Leseabfrage, deshalb wurde er nicht gesendet.';

  @override
  String get datumStatusAssumptions => 'Annahmen';

  @override
  String get datumStatusClose => 'Schließen';

  @override
  String get datumStatusFollowsData => 'Der Status richtet sich nach den Daten';

  @override
  String get datumStatusFormula => 'Formel';

  @override
  String get derivedAirflow => 'Luftstrom';

  @override
  String get derivedEcuFuelTitle => 'ECU-Kraftstoffdaten';

  @override
  String get derivedEcuReported => 'Von der ECU gemeldet';

  @override
  String get derivedEngineHorsepower => 'Motorleistung';

  @override
  String get derivedEstimatedFuelTitle => 'Geschätzter Kraftstoffverbrauch';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Formeln und Annahmen für die Schätzung';

  @override
  String get derivedEstimatesTitle => 'Geschätzte Werte';

  @override
  String get derivedFuelUse => 'Kraftstoffverbrauch';

  @override
  String get derivedTorque => 'Drehmoment';

  @override
  String get derivedUnavailableMessage =>
      'Die Leistung in PS kann erst geschätzt werden, sobald Daten zur Fahrzeuggeschwindigkeit und zur Beschleunigung vorliegen.';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'Das Fahrzeug hat die Abfrage Mode $mode nicht beantwortet, und Mode 03 hat ebenfalls nicht geantwortet – es lässt sich also nicht sagen, ob dem Fahrzeug die Unterstützung fehlt oder diese Verbindung sie schlicht nicht gelesen hat.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Ein Fehler im Zusammenhang mit $category';
  }

  @override
  String get dtcClear => 'Löschen';

  @override
  String get dtcClearCancel => 'Abbrechen';

  @override
  String get dtcClearConfirm => 'Diese löschen';

  @override
  String get dtcClearDialogBody =>
      'Dadurch werden gespeicherte und ausstehende Fehlercodes gelöscht und die Fehleranzeige erlischt; außerdem wird die Emissionsbereitschaft zurückgesetzt – das Fahrzeug muss erneut einen vollständigen Selbstdiagnosezyklus durchlaufen, bevor es eine Abnahme bestehen kann. Permanente Fehlercodes (Mode 0A) können nicht gelöscht werden.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Dieser Scan hat keinen Freeze-Frame gelesen – das heißt nicht, dass das Fahrzeug keinen hat. Scannen Sie zuerst erneut und entscheiden Sie dann, ob gelöscht wird.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'Der Freeze-Frame für $codes wird mitgelöscht – die ganze Aufzeichnung von Motordrehzahl, Kühlmitteltemperatur und Last im Moment des Fehlers – und kann erst wieder gelesen werden, wenn der Fehler erneut auftritt.';
  }

  @override
  String get dtcClearDialogTitle => 'Fehlercodes löschen?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Kategorien in diesem Scan haben nicht vollständig geantwortet',
      one: 'Eine Kategorie in diesem Scan hat nicht vollständig geantwortet',
    );
    return '$_temp0 ($categories), es kann also Fehlercodes geben, die Sie nicht gesehen haben. Nach einem Löschvorgang sind sie nie wieder lesbar.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'Der Löschvorgang wurde abgebrochen, bevor ein Befehl die App verlassen hat. Führen Sie einen erneuten Scan durch und versuchen Sie es erneut, falls Sie den Löschvorgang weiterhin durchführen möchten.';

  @override
  String get dtcClearConfirmed => 'Der Löschbefehl wurde gesendet.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Möglicherweise wurde bereits ein Löschvorgang am Fahrzeug durchgeführt. Führen Sie keinen weiteren durch – ein zweiter globaler Löschvorgang kann die Emissionsbereitschaft an einem Steuergerät zurücksetzen, bei dem der Löschvorgang möglicherweise bereits abgeschlossen ist. Führen Sie einen erneuten Scan durch, um zu überprüfen, welche Fehler noch vorhanden sind.';

  @override
  String get dtcClearFailureGeneric =>
      'Der Löschvorgang wurde nicht abgeschlossen. Führen Sie einen erneuten Scan durch, um die aktuellen Fehlercodes anzuzeigen, bevor Sie entscheiden, ob Sie es erneut versuchen möchten.';

  @override
  String get dtcClearNotAccepted =>
      'Das Löschen ist fehlgeschlagen; kein Steuergerät hat den Befehl angenommen. Sie können es erneut versuchen.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Mindestens ein Steuergerät hat das Löschen als abgeschlossen gemeldet, bei den übrigen ließ es sich nicht bestätigen. Senden Sie keinen weiteren Löschbefehl – eine Wiederholung setzt die Emissionsbereitschaft bei den Steuergeräten zurück, die bereits fertig sind. Scannen Sie erneut, um das Ergebnis zu sehen.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Eine frühere Verbindung hat einen Löschbefehl gesendet, dessen Ergebnis nicht bestätigt wurde. Scannen Sie zuerst erneut, sehen Sie nach, welche Codes übrig sind, und entscheiden Sie dann über das Löschen.';

  @override
  String get dtcClearRescanSettled =>
      'Der vorherige Löschvorgang ließ sich nicht vollständig bestätigen. Was folgt, ist der tatsächliche Stand nach diesem erneuten Scan.';

  @override
  String get dtcClearSentUnconfirmed =>
      'Der Löschbefehl wurde gesendet, aber die Antwort wurde unterwegs beschädigt, deshalb ist nicht bekannt, ob das Fahrzeug gelöscht hat. Scannen Sie erneut, um das zu prüfen; senden Sie keinen weiteren Löschbefehl – war er bereits erfolgreich, setzt eine Wiederholung die Emissionsbereitschaft zurück.';

  @override
  String get dtcClearTimeout =>
      'Nach dem Senden des Löschbefehls kam keine Antwort, deshalb ist nicht bekannt, ob das Fahrzeug gelöscht hat. Scannen Sie erneut, um das zu prüfen. Senden Sie nicht blind einen weiteren Löschbefehl.';

  @override
  String get dtcClearUnexpected =>
      'Das Löschen ist fehlgeschlagen, deshalb ist nicht bekannt, ob das Fahrzeug gelöscht hat. Scannen Sie erneut, um das zu prüfen. Senden Sie nicht blind einen weiteren Löschbefehl.';

  @override
  String get dtcClearing => 'Wird gelöscht…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'Die Verbindung wurde während des Scans unterbrochen, sodass dieser Scan nicht abgeschlossen wurde.';

  @override
  String get dtcScanInterrupted =>
      'Der Scan wurde unterbrochen (möglicherweise wurde die App in den Hintergrund verschoben oder die Verbindung hat sich geändert), sodass kein vollständiges Ergebnis vorliegt. Führen Sie den Scan erneut durch.';

  @override
  String get dtcCompleteCleanBody =>
      'Das heißt, dass jedes Steuergerät, das geantwortet hat, keinen Fehlercode gemeldet hat. Es heißt nicht, dass jedes Modul im Fahrzeug gefragt wurde.';

  @override
  String get dtcCompleteCleanTitle =>
      'Keines der Steuergeräte, die geantwortet haben, hat einen Fehlercode gemeldet.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Steuergerät $controller';
  }

  @override
  String get dtcDismiss => 'Schließen';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'Die Werte, die dieses Steuergerät zum Zeitpunkt der Bestätigung von $code aufgezeichnet hat. Durch das Löschen der Fehlercodes wird diese Aufzeichnung ebenfalls gelöscht.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Dieses Steuergerät hat einen Freeze-Frame, hat aber die Abfrage nach dessen Inhalt nicht beantwortet, sodass der Inhalt nicht gelesen werden konnte. Ein erneuter Scan kann helfen.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Dieses Steuergerät hat einen Freeze-Frame, aber keiner der darin enthaltenen Einträge lässt sich von dieser App dekodieren.';

  @override
  String get dtcFreezeFrameTitle => 'Das Fahrzeug im Moment des Fehlers';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count weitere Einträge in diesem Freeze-Frame haben in dieser App keine Umrechnungsformel und werden deshalb nicht aufgeführt.',
      one: 'Ein weiterer Eintrag in diesem Freeze-Frame hat in dieser App keine Umrechnungsformel und wird deshalb nicht aufgeführt.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Einträge kamen diesmal nicht zurück (womöglich war zu wenig Zeit, oder das Steuergerät hat nicht geantwortet). Ein erneuter Scan kann sie lesen.',
      one: 'Ein Eintrag kam diesmal nicht zurück (womöglich war zu wenig Zeit, oder das Steuergerät hat nicht geantwortet). Ein erneuter Scan kann ihn lesen.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Bei diesem Scan wurde kein Freeze-Frame ausgelesen – das bedeutet jedoch nicht, dass das Fahrzeug keinen aufweist. Führen Sie zunächst einen erneuten Scan durch und entscheiden Sie dann, ob Sie die Fehlercodes löschen möchten, da durch das Löschen die Aufzeichnung des Zeitpunkts des Fehlers dauerhaft vernichtet wird. Sollte jeder Scan das gleiche Ergebnis liefern, stellt dieses Fahrzeug möglicherweise keinen Freeze-Frame zur Verfügung.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Fehlercodes';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Herstellerspezifischer Code – bitte sehen Sie im Wartungshandbuch für dieses Fahrzeug nach';

  @override
  String get dtcMilOff => 'Die Fehleranzeige leuchtet nicht';

  @override
  String get dtcMilOn => 'Die Fehleranzeige leuchtet';

  @override
  String get dtcMonitorBoostPressure => 'Ladedruck';

  @override
  String get dtcMonitorCatalyst => 'Katalysator';

  @override
  String get dtcMonitorComponents => 'Umfassende Komponenten';

  @override
  String get dtcMonitorEgr => 'EGR-/VVT-System';

  @override
  String get dtcMonitorEvaporative => 'Verdunstungssystem';

  @override
  String get dtcMonitorExhaustSensor => 'Abgassensor';

  @override
  String get dtcMonitorFuelSystem => 'Kraftstoffsystem';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Benzinpartikelfilter (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Beheizter Katalysator';

  @override
  String get dtcMonitorMisfire => 'Zündaussetzer';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC-Katalysator';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR-Nachbehandlung';

  @override
  String get dtcMonitorOxygenSensor => 'Sauerstoffsensor';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Heizung der Lambdasonde';

  @override
  String get dtcMonitorParticulateFilter => 'Partikelfilter';

  @override
  String get dtcMonitorSecondaryAir => 'Sekundärluftsystem';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem – Diese App verfügt über keine detaillierte Beschreibung für diesen Code';
  }

  @override
  String get dtcNotConnectedBody =>
      'Zum Auslesen von Fehlercodes ist ein angeschlossener ELM327-Adapter erforderlich oder der Simulator muss ausgeführt werden.';

  @override
  String get dtcNotConnectedTitle => 'Nicht verbunden';

  @override
  String get dtcNotScanned => 'Noch nicht gescannt';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Steuergeräten',
      one: 'einem Steuergerät',
    );
    return 'Alle drei Kategorien wurden vollständig abgefragt. Bei $_temp0 ($controllers) sind weder ausstehende noch permanente Fehlercodes umgesetzt – bei vielen Fahrzeugen normal, und zugleich der Grund, warum sich daraus kein fehlerfreies Fahrzeug erklären lässt.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'Die Kategorien, die geantwortet haben, meldeten keine Fehlercodes.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories haben nicht geantwortet, ihr Zustand lässt sich also nicht bestätigen – das ist nicht dasselbe wie ein Fahrzeug ohne Problem.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fehlercodes wurden gelesen',
      one: 'Ein Fehlercode wurde gelesen',
    );
    return '$_temp0, bevor diese Kategorie abbrach, doch die Abdeckung ist unvollständig:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Nur einige Steuergeräte dieser Kategorie haben geantwortet, die übrigen haben nicht geantwortet; daher kann dies nicht als Ergebnis für das gesamte Fahrzeug gewertet werden. $message';
  }

  @override
  String get dtcReadFailed => 'Lesefehler';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Alle Bereitschaftsprüfungen, für die dieses Steuergerät zuständig ist, sind abgeschlossen.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Prüfungen sind noch nicht abgeschlossen',
      one: '1 Prüfung ist noch nicht abgeschlossen',
    );
    return '$_temp0 – eine Abnahme kann jetzt scheitern.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Dieses Steuergerät hat überhaupt keine Bereitschaftsprüfungen gemeldet – es ist womöglich nicht für die Emissionsüberwachung zuständig, und das heißt nicht, dass es bereit ist.';

  @override
  String get dtcReadinessTitle => 'Emissionsbereitschaft';

  @override
  String get dtcRescanFirst => 'Zuerst erneut scannen';

  @override
  String get dtcRetry => 'Wiederholen';

  @override
  String get dtcScanBody =>
      'Liest gespeicherte Fehlercodes Mode 03, ausstehende Fehlercodes Mode 07 und dauerhafte Fehlercodes Mode 0A aus.';

  @override
  String get dtcScanTitle => 'Fahrzeug auf Fehlercodes scannen';

  @override
  String get dtcScanning => 'Wird gescannt…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dieses Steuergerät meldet selbst $count bestätigte Fehlercodes.',
      one: 'Dieses Steuergerät meldet selbst 1 bestätigten Fehlercode.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Dieses Steuergerät meldet selbst keine bestätigten Fehlercodes.';

  @override
  String get dtcSilentCategoryHeadline =>
      'Diese Kategorie hat nicht geantwortet';

  @override
  String get dtcSilentPendingDetail =>
      'Ausstehende Fehlercodes (Mode 07) haben nicht geantwortet. Diese ECU setzt den Dienst womöglich nicht um, oder er wurde diesmal schlicht nicht gelesen – eine fehlende Antwort kann beides nicht unterscheiden und darf nicht heißen, dass keine ausstehenden Fehler vorliegen. Das Ergebnis der gespeicherten Fehlercodes bleibt davon unberührt.';

  @override
  String get dtcSilentPermanentDetail =>
      'Permanente Fehlercodes (Mode 0A) wurden nicht zurückgemeldet. Diese Kategorie wurde mit der OBD-II-Generation um das Jahr 2010 eingeführt, sodass ältere Fahrzeuge diese nicht immer unterstützen – eine fehlende Rückmeldung kann jedoch ebenso bedeuten, dass der Code diesmal einfach nicht ausgelesen wurde, und diese beiden Fälle lassen sich nicht voneinander unterscheiden. Das Ergebnis des gespeicherten Fehlercodes bleibt davon unberührt.';

  @override
  String get dtcStartScan => 'Scan starten';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'Das Fahrzeug hat die Abfrage Mode $mode nicht beantwortet, deshalb lässt sich nicht bestätigen, ob gespeicherte Fehlercodes vorliegen. Das ist nicht dasselbe wie keine Fehlercodes.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Codes',
      one: '1 Code',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => 'Kann nicht bestätigt werden';

  @override
  String get dtcUnknownError => 'Unbekannter Fehler';

  @override
  String get dtcUnknownMonitor => 'Unbekannter Monitor';

  @override
  String get dtcVerdictCompleteClean =>
      'Keine Fehlercodes von den Steuergeräten, die geantwortet haben';

  @override
  String get dtcVerdictPartialClean => 'Teilweise unbestätigt';

  @override
  String get fieldEventBody =>
      'Drücken Sie diese Taste nur, wenn das Fahrzeug vollständig zum Stillstand gekommen ist – entweder durch einen Fahrgast oder durch einen Bediener, der das Fahrzeug geparkt hat. Die Ereignisse werden auf derselben Zeitachse wie die OBD-Rohdaten erfasst, und es wird versucht, die Daten sofort zu speichern.';

  @override
  String get fieldEventEngineStarted => 'Motor gestartet';

  @override
  String get fieldEventHeading => 'Ereignismarken im Feld';

  @override
  String get fieldEventIgnitionOn => 'Zündung ein';

  @override
  String get fieldEventMemoryOnly =>
      'In dieser Sitzung aufgezeichnet, doch die automatische Speicherung ist fehlgeschlagen – exportieren Sie das Protokoll nun.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Erfasst und gespeichert: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Probefahrt begonnen';

  @override
  String get fieldEventThrottleBlip => 'Gasstoß';

  @override
  String get fieldEventUnavailable =>
      'Es besteht keine Live-Verbindung zu einem Fahrzeug, anhand derer die Aufzeichnung erfolgen könnte.';

  @override
  String get gaugeNoData => 'Keine Daten';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Keine Daten – $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (Daten sind veraltet)';
  }

  @override
  String get gaugeUnsupportedByVehicle =>
      'Von diesem Fahrzeug nicht unterstützt';

  @override
  String get handshakeNoteAborted =>
      'Der Vorgang wurde abgebrochen, nachdem ein früherer Schritt fehlgeschlagen war.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'Die ECU hat die Abfrage der unterstützten PIDs abgelehnt (negative Antwort).';

  @override
  String get handshakeNoteEcuSilent => 'Die ECU hat nicht geantwortet.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'Der Adapter hat diesen Befehl nicht bestätigt.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'Die Antwort ist keine positive Mode 01-Antwort.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'Die Antwort gibt eine andere PID wieder als die, die angefordert wurde.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'Die Antwort auf die Unterstützungsabfrage ist zu kurz; 41 00 und vier weitere Bytes sind nötig.';

  @override
  String get handshakeNoteTimedOut => 'Zeitüberschreitung.';

  @override
  String get handshakeStepAdapterVersion => 'Adapterversion lesen';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Adaptives Timing einschalten, die vom Datenblatt empfohlene Einstellung';

  @override
  String get handshakeStepBatteryVoltage => 'Batteriespannung lesen';

  @override
  String get handshakeStepDeviceIdentity =>
      'Gerätekennung als Zeichenfolge lesen';

  @override
  String get handshakeStepEchoOff => 'Befehls-Echo deaktivieren';

  @override
  String get handshakeStepLinefeedsOff => 'Zeilenvorschübe deaktivieren';

  @override
  String get handshakeStepMemoryOff => 'Speicherschreibvorgänge deaktivieren';

  @override
  String get handshakeStepNoReason => 'keine Antwort';

  @override
  String get handshakeStepProtocolAuto => 'Busprotokoll automatisch erkennen';

  @override
  String get handshakeStepProtocolDescription => 'Protokollbeschreibung lesen';

  @override
  String get handshakeStepProtocolNumber => 'Protokollnummer lesen';

  @override
  String get handshakeStepReset => 'Adapter per Software zurücksetzen';

  @override
  String get handshakeStepResponseTimeout =>
      'Antwort-Timeout auf etwa 408 ms setzen';

  @override
  String get handshakeStepSpacesOff =>
      'Leerzeichen abschalten, das spart ein Drittel des Datenverkehrs';

  @override
  String get handshakeStepSupportProbe =>
      'Abfragen, welche PIDs die ECU unterstützt – der Nachweis, dass ein Fahrzeug geantwortet hat';

  @override
  String get languageSaveFailed =>
      'Die Sprache konnte nicht gespeichert werden. Bitte versuchen Sie es erneut.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navDtc => 'Fehlercodes';

  @override
  String get navPerformance => 'Zeitmessung';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get performanceArm => 'Den Timer aktivieren';

  @override
  String get performanceDisclaimer =>
      'Die Zeiten stammen aus dem OBD-Fahrgeschwindigkeitssignal. Die meisten Fahrzeuge zeigen auf dem eigenen Tacho 1–3 km/h zu viel, und das Signal wird nur etwa 10–20 Mal pro Sekunde aktualisiert; ein Ergebnis hier ist deshalb nur ein Anhaltspunkt – es ersetzt keine professionelle Messtechnik.';

  @override
  String get performanceHeadline => 'Beschleunigungstest';

  @override
  String get performanceNoSpeedSignal =>
      'Derzeit liegt kein gültiges Fahrgeschwindigkeitssignal vor (PID 010D). Ohne dieses Signal kann der Beschleunigungstest die Laufzeit eines Durchlaufs nicht messen.';

  @override
  String get performanceNotConnectedBody =>
      'Für den Beschleunigungstest ist die tatsächliche Fahrgeschwindigkeit erforderlich. Schließen Sie einen Adapter an oder starten Sie den integrierten Simulator.';

  @override
  String get performanceNotConnectedTitle => 'Nicht verbunden';

  @override
  String get performancePeakSpeed => 'Höchstgeschwindigkeit';

  @override
  String get performanceReset => 'Zurücksetzen';

  @override
  String get performanceSecondsUnit => 'Sekunden';

  @override
  String get performanceSpeedGaugeLabel => 'Geschwindigkeit';

  @override
  String get performanceSpeedTraceHeading => 'Geschwindigkeitsverlauf';

  @override
  String get performanceSplitsHeading => 'Splits';

  @override
  String get performanceStateAborted =>
      'Das Geschwindigkeitssignal wurde unterbrochen – dieser Lauf wurde nicht abgeschlossen; nachstehend finden Sie die Aufzeichnung, die vor dem Abbruch erfasst wurde';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'Warten auf ein Geschwindigkeitssignal';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Halten Sie zunächst vollständig an – jetzt $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return 'Fertig 0 → $target km/h';
  }

  @override
  String get performanceStateIdle =>
      'Wählen Sie eine Zielgeschwindigkeit aus und starten Sie dann';

  @override
  String get performanceStateRunning => 'Zeitmessung läuft';

  @override
  String get performanceStateStaged =>
      'Auf die Plätze – die Zeit läuft, sobald Sie losfahren';

  @override
  String get performanceSubhead =>
      'Ein zeitlich gemessener Lauf vom Stand bis zu einer Zielgeschwindigkeit';

  @override
  String get performanceTargetSpeedHeading => 'Sollgeschwindigkeit';

  @override
  String get pidActionCancel => 'Abbrechen';

  @override
  String get pidActionDelete => 'Löschen';

  @override
  String get pidArrangeBody =>
      'Zum Ändern der Reihenfolge ziehen. Das Dashboard wird von links nach rechts und von oben nach unten gefüllt, sodass das, was an erster Stelle steht, zuerst angezeigt wird.';

  @override
  String get pidArrangeEmptyMessage =>
      'Aktivieren Sie zunächst einige Elemente in der Liste und kehren Sie dann zurück, um sie zu sortieren.';

  @override
  String get pidArrangeEmptyTitle => 'Noch keine PID aktiviert';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Die $count bestätigten hinzufügen';
  }

  @override
  String get pidBulkActionAllActive => 'Alle sind bereits aktiviert';

  @override
  String get pidBulkActionIncomplete => 'Die Scandaten sind unvollständig';

  @override
  String get pidBulkActionLocked =>
      'Während der Aufnahme können keine Änderungen vorgenommen werden';

  @override
  String get pidBulkActionPending => 'Warten auf die Untersuchungsergebnisse';

  @override
  String get pidBulkActionZero => 'Keine bestätigten unterstützten PIDs';

  @override
  String pidBulkAddCount(int count) {
    return '$count hinzufügen';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '$count bestätigte unterstützte PIDs hinzufügen?';
  }

  @override
  String pidBulkAdded(int count) {
    return '$count bestätigte unterstützte PIDs hinzugefügt.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count Unterstützungsblöcke sind noch unbestätigt – hinzugefügt werden nur die Einträge mit positivem Nachweis.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Fügt $count hinzu. Je mehr PIDs aktiv sind, desto seltener wird jede einzelne womöglich aktualisiert.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed bestätigt';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Noch keine zusammenhängende Abdeckung';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Zusammenhängende Abdeckung 01–$through (Ende erreicht)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Zusammenhängende Abdeckung 01–$through (jenseits davon unbekannt)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Dieser Support-Scan wurde abgeschlossen';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'Der Support-Scan wurde unterbrochen';

  @override
  String get pidCapabilityPhaseNotStarted =>
      'Der Scan wurde noch nicht gestartet';

  @override
  String get pidCapabilityPhaseRunning =>
      'Überprüfung der von diesem Fahrzeug unterstützten Funktionen';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'Vom Fahrzeug unterstützte PIDs. $phase. $confirmed bestätigt. $unknown unbekannte Blöcke.';
  }

  @override
  String get pidCapabilityTitle => 'Vom Fahrzeug unterstützte PIDs';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown unbekannte Blöcke';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Eine benutzerdefinierte PID nutzt diese Kombination bereits ($name). Verwenden Sie eine andere Kombination aus Mode + PID, einen anderen Header oder einen anderen Namenszusatz.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'Die Definition für „$name“ wird entfernt, ihre Anzeige verschwindet vom Dashboard, und das lässt sich nicht rückgängig machen.';
  }

  @override
  String get pidEditorDeleteTitle => 'Soll diese PID gelöscht werden?';

  @override
  String get pidEditorDiscard => 'Verwerfen';

  @override
  String get pidEditorDiscardBody =>
      'Die Änderungen an diesem PID wurden nicht gespeichert; wenn Sie die Seite verlassen, gehen sie verloren.';

  @override
  String get pidEditorDiscardTitle =>
      'Sollen nicht gespeicherte Änderungen verworfen werden?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N stehen für die Antwortbytes; SIGNED(), ABS(), LOG10(), $valSyntax und BARO stehen zur Verfügung';
  }

  @override
  String get pidEditorFieldEquation => 'Ausdruck';

  @override
  String get pidEditorFieldHeader => 'CAN-Header';

  @override
  String get pidEditorFieldMax => 'Maximal';

  @override
  String get pidEditorFieldMin => 'Mindestwert';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorFieldName => 'Name';

  @override
  String get pidEditorFieldSample => 'Test-Antwortbytes';

  @override
  String get pidEditorFieldShortName => 'Kurzname (auf der Anzeige)';

  @override
  String get pidEditorFieldUnits => 'Einheiten';

  @override
  String get pidEditorHeaderHelper => '7E0 = Motor';

  @override
  String get pidEditorKeepEditing => 'Weiter bearbeiten';

  @override
  String get pidEditorModeAndPidHelper => 'Beispielsweise 010C oder 221101';

  @override
  String get pidEditorSampleHelper =>
      'Geben Sie einen Hexadezimalwert ein, um das Ergebnis während der Eingabe in der Vorschau anzuzeigen';

  @override
  String get pidEditorSave => 'Speichern';

  @override
  String get pidEditorSectionFormula => 'Formel';

  @override
  String get pidEditorSectionIdentity => 'Identität';

  @override
  String get pidEditorSectionQuery => 'Abfrage';

  @override
  String get pidEditorSectionRangeAndPriority => 'Messbereich und Priorität';

  @override
  String get pidEditorTitleEdit => 'PID bearbeiten';

  @override
  String get pidEditorTitleNew => 'Neuer benutzerdefinierter PID';

  @override
  String pidExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get pidExportNoCustomPids =>
      'Es sind keine benutzerdefinierten PIDs zum Exportieren vorhanden.';

  @override
  String get pidImportNothingToImport =>
      'Es sind keine Definitionen zu importieren.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count benutzerdefinierte PIDs importiert.',
      one: '1 benutzerdefinierte PID importiert.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge importiert, $notes.',
      one: '1 Eintrag importiert, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bei $count Zeilen gab es Probleme, sie wurden übersprungen',
      one: 'Bei 1 Zeile gab es Probleme, sie wurde übersprungen',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen haben den Standard-Messbereich verwendet',
      one: '1 Zeile hat den Standard-Messbereich verwendet',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge haben bestehende Definitionen ersetzt',
      one: '1 Eintrag hat eine bestehende Definition ersetzt',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Zeilen waren Duplikate anderer Zeilen in der Datei und wurden übersprungen',
      one: '1 Zeile war das Duplikat einer anderen Zeile in der Datei und wurde übersprungen',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed =>
      'Die Dateiauswahl konnte nicht geöffnet werden.';

  @override
  String get pidImportReadFailed => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Nur aktiviert';

  @override
  String get pidManagerAdd => 'Neu';

  @override
  String get pidManagerArrangeDashboard => 'Dashboard anordnen';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active aktiviert · $total verfügbar';
  }

  @override
  String get pidManagerExportCsv => 'Benutzerdefinierte PIDs exportieren';

  @override
  String get pidManagerExportTorqueCsv =>
      'Torque-kompatible CSV-Datei exportieren';

  @override
  String get pidManagerExportHumanReport =>
      'Menschenlesbaren PID-Bericht exportieren';

  @override
  String get pidManagerHeadline => 'PID-Manager';

  @override
  String get pidManagerImportCsv => 'CSV importieren';

  @override
  String get pidManagerMoreActions => 'Mehr';

  @override
  String get pidManagerNoMatchMessage =>
      'Versuchen Sie es mit einem anderen Suchbegriff oder erstellen Sie eine benutzerdefinierte PID.';

  @override
  String get pidManagerNoMatchTitle => 'Keine übereinstimmende PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => 'Antriebsbatterie-Katalog';

  @override
  String get pidManagerSearchHint => 'Suche nach Name oder PID-Code…';

  @override
  String get pidPickCsvDialogTitle =>
      'Wählen Sie eine CSV-Datei mit PID-Definitionen aus';

  @override
  String get pidPillCustom => 'Benutzerdefiniert';

  @override
  String get pidPillUnsupported => 'Nicht unterstützt';

  @override
  String get pidPreviewCannotEvaluate => 'Kann nicht ausgewertet werden';

  @override
  String get pidPreviewResultLabel => 'Ergebnis';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'Die Vorschau setzt $valueString für $dependencies ein; der echte Wert kommt nach dem Verbinden von dieser PID.';
  }

  @override
  String get pidPreviewTitle => 'Live-Vorschau';

  @override
  String get pidPriorityHigh => 'Hoch';

  @override
  String get pidPriorityLow => 'Niedrig';

  @override
  String get pidPriorityMedium => 'Mittel';

  @override
  String get pidPriorityVeryLow => 'Sehr niedrig';

  @override
  String get pidRowEdit => 'Bearbeiten';

  @override
  String pidRowShowOnDashboard(String name) {
    return '$name auf dem Dashboard anzeigen';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · veraltet';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Die Batteriesignale für $profile sind für diese Verbindung aktiviert.';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Konnte nicht aktiviert werden: $reason';
  }

  @override
  String get powertrainCancel => 'Abbrechen';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profile: $profiles · Experimentelle Einmal-Lesevorgänge: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'Die Integritätsprüfung war nicht erfolgreich, daher werden keine Fahrzeugdaten angezeigt oder installiert.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Der Offline-Katalog konnte nicht geladen werden';

  @override
  String get powertrainCatalogNotVerified =>
      'Der Katalog hat die Überprüfung nicht bestanden, daher kann nichts installiert werden.';

  @override
  String get powertrainCatalogRevalidate => 'Erneut prüfen';

  @override
  String get powertrainCatalogScopeNote =>
      'Der Katalog ist umfangreich, doch „wir haben Daten gefunden“ bedeutet nicht, dass „Ihr Fahrzeug unterstützt wird“. Einträge, die ausschließlich zu Forschungszwecken dienen, enthalten niemals einen Befehl; experimental-Einträge lesen weiterhin jeweils einen Befehl nach dem anderen ein, wobei jeder Befehl nach einer eigenen Bestätigung folgt.';

  @override
  String get powertrainCatalogSearchHint =>
      'Suchen Sie nach Marke, Modell, Variante oder Markt…';

  @override
  String get powertrainCatalogTitle => 'Antriebsbatterie-Katalog';

  @override
  String get powertrainChooseCommandNote =>
      'Ein Befehl pro Versuch: kein Scan, kein Batch, kein automatischer Wiederholungsversuch.';

  @override
  String get powertrainChooseCommandTitle =>
      'Wählen Sie eine angeheftete, nur lesende Abfrage aus';

  @override
  String get powertrainClose => 'Schließen';

  @override
  String get powertrainConfirmAccept => 'Das ist das Fahrzeug';

  @override
  String get powertrainConfirmBody =>
      'Die Signale eines installierten Profils werden erst gelesen, nachdem Sie bestätigt haben, dass dieses Fahrzeug das betreffende Modell ist; die Bestätigung gilt nur für diese Verbindung.';

  @override
  String get powertrainConfirmButton => 'Fahrzeug bestätigen';

  @override
  String get powertrainConfirmDialogBody =>
      'Sobald dieses Profil bestätigt ist, werden die nur lesenden Batterieabfragen dieses Profils für die restliche Dauer dieser Verbindung abgefragt. Ein falsches Profil kann Zahlen liefern, die plausibel erscheinen, aber falsch sind – brechen Sie den Vorgang ab, wenn Sie sich nicht sicher sind.';

  @override
  String get powertrainConfirmDialogTitle =>
      'Bestätigen Sie das verbundene Fahrzeug';

  @override
  String get powertrainConfirmTitle =>
      'Signale der Fahrzeugbatterie müssen noch bestätigt werden';

  @override
  String get powertrainConnectFirst =>
      'Stellen Sie zunächst eine Verbindung her; die experimental-Autorisierung wird niemals über Verbindungen hinweg beibehalten.';

  @override
  String get powertrainConnectionChanged =>
      'Die Verbindung hat sich geändert – bestätigen Sie das Fahrzeug erneut für die neue Verbindung.';

  @override
  String get powertrainEnableLabInSettings =>
      'Aktivieren Sie zunächst in den Einstellungen das experimental-Batterielabor.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Projektfahrzeug';

  @override
  String get powertrainEvidenceSourceBacked => 'Quelldaten';

  @override
  String get powertrainEvidenceSyntheticRig => 'Synthetischer Prüfstand';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Hierbei handelt es sich um einen von den Autoren der Quelle gekennzeichneten Messwert, nicht um eine Sicherheitsgarantie des Herstellers oder modellübergreifend; ELM327 leitet den Befehl lediglich weiter. Der Rohbefehl und die Antwort verbleiben im lokalen Diagnoseprotokoll und werden durch diese Funktion nicht automatisch hochgeladen; dekodierte Werte werden niemals als PID installiert oder einer Anzeige hinzugefügt. Ein Abbruch hat keine Auswirkungen auf die regulären OBD-Funktionen.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Einmalige Bestätigung für einen nur lesenden experimental-Zugriff';

  @override
  String get powertrainExperimentalIdentityAck =>
      'Ich habe den Markt, das Modell und das Modelljahr, die der Quelle bekannt sind, überprüft und akzeptiere die unbestätigten Angaben';

  @override
  String get powertrainExperimentalParkedAck =>
      'Das Fahrzeug ist sicher geparkt; mir ist klar, dass hier einmal gelesen wird und der Wert trotzdem nicht zutreffen kann';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Akzeptiert ausschließlich RX $responder, Nutzdatenlänge $bytes Bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Markt';

  @override
  String get powertrainFieldModel => 'Modell';

  @override
  String get powertrainFieldModelYear => 'Modelljahr';

  @override
  String get powertrainFieldVariant => 'Variante';

  @override
  String get powertrainFilterAll => 'Alle';

  @override
  String get powertrainIdentityEvidenceExact => 'direkter Nachweis';

  @override
  String get powertrainIdentityEvidenceNone => 'keine';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'teilweiser Nachweis';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Nachweis der Quellenidentität: $fields\nUnbestätigte Felder: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'unbekannt';

  @override
  String get powertrainInstallButton => 'Batteriesignale installieren';

  @override
  String get powertrainInstallConfirm => 'Installieren';

  @override
  String get powertrainInstallDialogTitle =>
      'Batteriesignale dieses Modells installieren';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Durch die Installation werden lediglich nur lesende Batterie-PIDs zur PID-Verwaltung hinzugefügt. Bevor eine Messung beginnt, werden Sie bei jeder Verbindung aufgefordert, auf dem Dashboard zu bestätigen, dass es sich bei diesem Fahrzeug um das angegebene Modell handelt. Die Daten stammen aus community-Quellen und wurden unabhängig überprüft; es handelt sich jedoch nicht um eine Herstellergarantie.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Durch die Installation werden lediglich nur lesende Batterie-PIDs zur PID-Verwaltung hinzugefügt. Bevor eine Messung beginnt, werden Sie bei jeder Verbindung aufgefordert, auf dem Dashboard zu bestätigen, dass es sich bei diesem Fahrzeug um das angegebene Modell handelt. Es handelt sich hierbei um eine experimental-Auswertung ohne die Notwendigkeit einer unabhängigen Bestätigung, die für dieses Fahrzeug nicht verifiziert wurde und nach wie vor keine Herstellergarantie darstellt.';

  @override
  String get powertrainInstallDisclosureReady =>
      'Durch die Installation werden lediglich nur lesende Batterie-PIDs zur PID-Verwaltung hinzugefügt. Bevor eine Messung beginnt, werden Sie bei jeder Verbindung aufgefordert, auf dem Dashboard zu bestätigen, dass es sich bei diesem Fahrzeug um das angegebene Modell handelt. Die Quelldaten sind umfassender; es handelt sich jedoch nach wie vor nicht um eine Herstellergarantie.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Durch die Installation werden lediglich nur lesende Batterie-PIDs zur PID-Verwaltung hinzugefügt. Bevor eine Messung beginnt, werden Sie bei jeder Verbindung aufgefordert, auf dem Dashboard zu bestätigen, dass es sich bei diesem Fahrzeug um das angegebene Modell handelt. Dieser Eintrag dient ausschließlich Forschungszwecken und sollte nicht installiert werden.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'Installation nicht möglich: Dieser Katalog-Snapshot verfügt über keinen verifizierten SHA-256-Hash, daher kann keinem darin enthaltenen Element vertraut werden.';

  @override
  String get powertrainInstallPersistFailed =>
      'Installation nicht möglich: Die Liste der installierten Profile konnte nicht gespeichert werden. Bitte versuchen Sie es erneut; es wurden keine Einträge zur PID-Verwaltung hinzugefügt.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'Installation nicht möglich: Dieses Profil ist nicht im verifizierten Katalog enthalten.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'Installation nicht möglich: Dieses Profil befindet sich nicht in einem Zustand, in dem PIDs live geschaltet werden können.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'Installation nicht möglich: Das Modelljahr liegt außerhalb des für dieses Profil dokumentierten Jahresbereichs.';

  @override
  String get powertrainInstallIdentityAck =>
      'Mein Fahrzeug entspricht dem oben genannten Markt, Modell und Modelljahr';

  @override
  String get powertrainInstalledRemoveButton =>
      'Installiert · Signale entfernen';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Signale installiert. Fügen Sie sie über die PID-Seite zum Dashboard hinzu; jede Verbindung braucht eine Fahrzeugbestätigung.',
      one: '1 Signal installiert. Fügen Sie es über die PID-Seite zum Dashboard hinzu; jede Verbindung braucht eine Fahrzeugbestätigung.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Geben Sie einen Marken- oder Modellnamen ein oder wählen Sie einen anderen Antriebstyp aus.';

  @override
  String get powertrainNoMatchTitle => 'Kein passendes Fahrzeug';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'In dieser Version nicht installierbar';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Primärquelle: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Die Prüfungen hinsichtlich Responder, Echo, exakter Länge, Formel und Bereich wurden bestanden.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Stellen Sie eine Verbindung für eine einmalige, nur lesende Abfrage her';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Verbinden, um zuerst einen Lesevorgang zu versuchen';

  @override
  String get powertrainProbeDidNotFinish =>
      'Die einmalige Abfrage wurde nicht abgeschlossen; es wurde kein Wert veröffentlicht oder gespeichert.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Aktivieren Sie zunächst das Labor in den Einstellungen';

  @override
  String get powertrainProbeInProgress => 'Wird einmal gelesen…';

  @override
  String get powertrainProbeNoValuePublished =>
      'Es wurde kein Wert veröffentlicht; ein Struktur- oder Dekodierungsfehler wird in Quarantäne gesetzt, bis Sie die Verbindung erneut herstellen.';

  @override
  String get powertrainProbeOnceButton => 'Nur einmal lesen';

  @override
  String get powertrainProbePassedTitle =>
      'Einmalige Abfrage erfolgreich durchgeführt';

  @override
  String get powertrainProbePickOneRead => 'Einen Befehl wählen, einmal lesen';

  @override
  String get powertrainProbeReconnectFirst =>
      'Stellen Sie die Verbindung erneut her und versuchen Sie es dann noch einmal';

  @override
  String get powertrainProbeRefusedTitle => 'Einmalige Abfrage abgelehnt';

  @override
  String get powertrainProbeTryOnceFirst => 'Zuerst einmal lesen';

  @override
  String get powertrainProfileNotVerified =>
      'Das Profil ist nicht im verifizierten Katalog enthalten';

  @override
  String get powertrainQuarantinedPill => 'In Quarantäne · Erneut verbinden';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'Nicht autorisiert: Der Integritäts-Hash des Katalogs ist ungültig, daher kann nichts daraus gelesen werden.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'Nicht autorisiert: Dieser Befehl gehört nicht zu den Befehlen dieses verifizierten Profils.';

  @override
  String get powertrainRefusedLabClosed =>
      'Das experimental-Batterielabor wurde ausgeschaltet, bevor dieser Lesevorgang autorisiert werden konnte.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'Nicht zulässig: Dieses Profil hat die Katalogvalidierung für das von Ihnen ausgewählte Modelljahr nicht bestanden.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'Nicht autorisiert: Dieses Profil ist nicht im verifizierten Katalog enthalten.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'Nicht autorisiert: Dieses Profil kann nicht einmalig experimentell ausgelesen werden.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'Für diese Verbindung in Quarantäne: Ein früherer Einmal-Lesevorgang hat die Strukturprüfungen nicht bestanden. Verbinden Sie neu, bevor Sie es erneut versuchen.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'Der einmalige Lesevorgang wurde nicht gestartet: Es besteht keine Verbindung, oder die App befand sich nicht im Vordergrund.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'Der Einmal-Lesevorgang wurde nicht gestartet: Es liegt keine Einmal-Berechtigung vor. Es wurde keine erteilt, oder sie ist abgelaufen, befindet sich in der Abkühlphase oder wurde unter Quarantäne gestellt.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'Die Verbindung oder der Vordergrundstatus hat sich während der Ausführung des einmaligen Lesevorgangs geändert, sodass dessen Ergebnis verworfen und nicht angezeigt wurde. Es ist kein Fehler aufgetreten, und es wurden keine Daten gespeichert.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'Für diese Verbindung in Quarantäne: Derselbe Befehl wurde bereits $attemptCap Mal versucht. Verbinden Sie neu, bevor Sie es erneut versuchen.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Nur Recherche – keine Abfragen';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Bei der Wiederherstellung früherer Installationen ist ein Speicherfehler aufgetreten. Der Vorgang wurde neu geplant – bitte versuchen Sie es erneut.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Unabhängige Bestätigung: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Signale: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'SHA-256-Hash der Quelldatei: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Community · unbestätigt';

  @override
  String get powertrainStatusExperimental => 'Experimentell · ungeprüft';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimentell · einmal lesen';

  @override
  String get powertrainStatusReady => 'Ausführlichere Quelldaten';

  @override
  String get powertrainStatusResearchOnly => 'Nur zu Forschungszwecken';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Die installierten Signale für $name wurden entfernt.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Modelljahr: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Modelljahr';

  @override
  String get recommendedPurchaseDisclosure =>
      'Dies ist ein Partnerlink des Betreibers; bei einem qualifizierten Kauf erhält der Betreiber möglicherweise eine Provision. Es handelt sich hierbei weder um eine Adapter-Zertifizierung noch um eine Kaufgarantie. Der Inhalt der Auflistung und die Hardware-Revisionen können sich ändern; überprüfen Sie daher vor dem Kauf die vollständige Modellnummer und die NCC-Nummer. Es steht Ihnen außerdem frei, selbst nach anderen Anbietern zu suchen.';

  @override
  String get recommendedPurchaseHeading => 'Empfohlener Adapter';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Modell $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'Sie haben noch keinen Adapter? Sehen Sie sich den empfohlenen Adapter bei $store an.';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Der Link „$store“ konnte nicht geöffnet werden.';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Vollständige Offenlegung in den Einstellungen';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Dies ist ein Affiliate-Link und keine Adapter-Zertifizierung.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Auf $store anzeigen';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Dies sind Stellen, an denen die Angaben des Messgeräts nicht übereinstimmen – kein Beweis dafür, dass es das Fahrzeug falsch gemessen hat. Die einzige Möglichkeit, einen Wert zu bestätigen, ist eine zweite unabhängige Messung (siehe Feldhandbuch).';

  @override
  String get settingsAdapterNoContradictions =>
      'Es wurden keine Widersprüche in der Selbstbeschreibung festgestellt. Das bedeutet lediglich, dass die Angaben zu sich selbst konsistent sind – es ist weder ein Beweis dafür, dass der Chip echt ist, noch ein Beweis dafür, dass die von ihm gemeldeten Zahlen korrekt sind. Bei einem Klon handelt es sich bei der Versionszeichenfolge lediglich um Text, den jemand ausgewählt hat.';

  @override
  String get settingsAdapterNoVersion => '(keine Version angegeben)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'Was der Adapter über sich selbst angibt';

  @override
  String get settingsBatteryLabDialogBody =>
      'Es handelt sich hierbei um durch Reverse Engineering ermittelte mögliche Quellen, nicht um Herstellerdokumentation und auch nicht um Telltale-Unterstützung für Ihr Fahrzeug. Selbst eine nur lesende Abfrage kann einen Steuergerät aus dem Ruhezustand wecken; eine entschlüsselte Nummer mag plausibel erscheinen und dennoch nicht zutreffen.';

  @override
  String get settingsBatteryLabDialogTitle =>
      'Schalten Sie das Batterielabor ein';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'Das Batterielabor ist bei diesem Durchlauf deaktiviert, doch die Einstellung konnte nicht gespeichert werden; beim nächsten Start wird das Labor möglicherweise wieder angezeigt, und jede Abfrage muss weiterhin einzeln bestätigt werden.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Die Einstellung für das Batterielabor konnte nicht gespeichert werden; sie bleibt deaktiviert.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Mir ist bewusst, dass die Quelldaten und die simulierten Tests nicht belegen, dass dies auf mein eigenes Fahrzeug zutrifft';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Zeigt ausschließlich einmalige, nur lesende Abfragen an, deren Quellen vollständig und hashgebunden sind. Es werden keine PIDs installiert, keine Abfragen durchgeführt, keine Messanzeigen hinzugefügt und Forschungsdaten nicht als Support behandelt.';

  @override
  String get settingsBatteryLabSwitchTitle => 'Batterielabor (experimental)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Nur einmalige, nur lesende Abfragen freigeben';

  @override
  String get settingsBatteryLabWireAck =>
      'Meines Wissens nach ermöglicht dies lediglich einmalige Abfragen an festen Mode 21/22-Adressen aus dem Katalog – kein Scannen, keine Diagnosesitzung, kein Sicherheitszugriff, kein Schreiben, keine Steuerung';

  @override
  String get settingsCancel => 'Abbrechen';

  @override
  String get settingsCatalogChoose =>
      'Wählen Sie aus dem offiziellen Katalog aus';

  @override
  String get settingsCatalogCorrupt =>
      'Der offizielle Offline-Katalog ist beschädigt oder konnte nicht geladen werden; es wurde nichts angewendet.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Diese offizielle Konfiguration enthält kein Feld, das sicher auf die aktuellen Formeln angewendet werden kann; das bestehende Profil bleibt unverändert.';

  @override
  String get settingsCatalogScope =>
      'Der beigefügte Snapshot enthält die offiziellen U.S. EPA Find-a-Car-Daten; er deckt lediglich den jeweiligen Markt und die im Snapshot enthaltenen Konfigurationen ab, nicht jedoch alle Marken oder Modelljahre weltweit.';

  @override
  String get settingsCatalogVerifying => 'Der Offline-Katalog wird überprüft…';

  @override
  String get settingsClose => 'Schließen';

  @override
  String get settingsConnectionSection => 'Verbindung';

  @override
  String get settingsDiagnosticsSection => 'Diagnoseprotokoll';

  @override
  String get settingsDisconnect => 'Trennen';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Getriebewirkungsgrad $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '$count offizielle Felder anwenden';
  }

  @override
  String get settingsEpaChooseExact =>
      'Wählen Sie eine genaue Konfiguration aus';

  @override
  String get settingsEpaCloseNoFields => 'Schließen (keine anwendbaren Felder)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA-Konfiguration $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count Zylinder';
  }

  @override
  String get settingsEpaDriveUnknown => 'Antrieb unbekannt';

  @override
  String get settingsEpaFuelUnknown => 'Kraftstoff unbekannt';

  @override
  String get settingsEpaMake => 'EPA-Hersteller';

  @override
  String get settingsEpaModel => 'Modell';

  @override
  String get settingsEpaNoConfigurations =>
      'Für dieses Modell sind keine Konfigurationen verfügbar';

  @override
  String get settingsEpaNoSafeFields =>
      'Diese Konfiguration enthält kein Feld, das sicher auf die aktuellen Formeln angewendet werden kann; es werden keine Annahmen getroffen.';

  @override
  String get settingsEpaPickInOrder =>
      'Wählen Sie nacheinander das Modelljahr, die Marke und das Modell aus';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Nur Konfigurationen des US-Markt-Snapshots für die Modelljahre $firstYear–$lastYear. Modelle mit gleichem Namen brauchen zur Unterscheidung weiterhin Modelljahr, Getriebe, Kraftstoff und EPA-ID.';
  }

  @override
  String get settingsEpaPickerTitle => 'Offizieller U.S. EPA-Fahrzeugkatalog';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Es wird nur $fields angewendet. Masse, VE, Cd, Stirnfläche, Crr und Getriebewirkungsgrad bleiben ungeklärt.';
  }

  @override
  String get settingsEpaYear => 'Modelljahr';

  @override
  String get settingsExperimentalSection => 'Experimentell';

  @override
  String get settingsFieldDisplacement => 'Hubraum';

  @override
  String get settingsFieldDragCoefficient => 'Luftwiderstandsbeiwert Cd';

  @override
  String get settingsFieldDrivetrain => 'Antriebsstrang';

  @override
  String get settingsFieldFrontalArea => 'Stirnfläche';

  @override
  String get settingsFieldFuel => 'Kraftstoff';

  @override
  String get settingsFieldMass => 'Masse';

  @override
  String get settingsFieldMassWithDriver => 'Masse (mit Fahrer)';

  @override
  String get settingsFieldRollingResistance => 'Rollwiderstand Crr';

  @override
  String get settingsFieldVolumetricEfficiency =>
      'Volumetrischer Wirkungsgrad VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Luft-Kraftstoff-Verhältnis $afr · Dichte $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection =>
      'Kraftstoff und Antriebsstrang';

  @override
  String get settingsFuelTypeLabel => 'Kraftstoffart';

  @override
  String get settingsGaugeSkinBody =>
      'Nicht nur ein Farbwechsel – jede hat ein anderes Zifferblatt, einen anderen Zeiger und eine andere Bewegung. Alle funktionieren auf dunklem und auf hellem Hintergrund.';

  @override
  String get settingsGaugeSkinTitle => 'Anzeigestil';

  @override
  String get settingsGoToConnect => 'Weiter zu „Verbinden“';

  @override
  String get settingsHeadline => 'Einstellungen';

  @override
  String get settingsLicenseLegalese =>
      'Quellen, Umformungen und Weiterverwendungsbedingungen der Antriebsbatterie-Daten sind in dieser App enthalten.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Senden Sie einen Befehl direkt an den Adapter – zum Beispiel ATI, ATDPN, 0100. Dieser wird in dieselbe Warteschlange eingefügt wie bei der normalen Abfrage und springt nicht vor.';

  @override
  String get settingsManualCommandFieldLabel => 'Befehl';

  @override
  String get settingsManualCommandNoContent => '(kein Antwortinhalt)';

  @override
  String get settingsManualCommandSend => 'Senden';

  @override
  String get settingsManualCommandTitle => 'Manueller Befehl';

  @override
  String get settingsNotConnected => 'Nicht verbunden';

  @override
  String get settingsOpenSourceLicenses => 'Open-Source- und Datenlizenzen';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Verbinden, um dieses Fahrzeug zu bestätigen';

  @override
  String get settingsProfileConfirmButton =>
      'Dieses Fahrzeug für diese Verbindung bestätigen';

  @override
  String get settingsProfileConfirmedButton => 'Für diese Verbindung bestätigt';

  @override
  String get settingsProfileConfirmedDetail =>
      'Das Profil wurde für diese Verbindung bestätigt. Wenn Sie einen Wert ändern oder die Verbindung neu herstellen, müssen Sie die Bestätigung erneut vornehmen.';

  @override
  String get settingsProfileEstimatesIntro =>
      'Aus diesen Parametern werden Leistung, Drehmoment und Kraftstoffverbrauch geschätzt; je näher diese Werte an den tatsächlichen Fahrzeugdaten liegen, desto aussagekräftiger sind die Schätzungen.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Ein Markenname oder eine VIN allein belegt weder Masse noch Luftwiderstand, VE oder Getriebewirkungsgrad.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Für diese Verbindung nicht bestätigt. Gemessene OBD-Werte werden weiterhin angezeigt, aus Masse, VE und Luftwiderstand geschätzte Werte nicht.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Stellen Sie vor der Bestätigung eine Verbindung zu diesem Fahrzeug her. Die Bestätigung erlischt bei jeder erneuten Verbindung, sodass das Profil eines Fahrzeugs niemals auf das nächste übertragen wird.';

  @override
  String get settingsProvenanceNoneExact =>
      'Für dieses Fahrzeug wurde kein Feld eindeutig zugeordnet; generische, manuell eingegebene und ältere Quellwerte müssen noch bestätigt werden.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Felder mit einer eindeutigen offiziellen Quelle: $fields. Alle übrigen Felder müssen noch einzeln bestätigt werden.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Herkunft: offiziell oder Hersteller $official / $total Felder · vom Benutzer eingegeben $user / $total · generischer Standard $generic / $total · wissenschaftliches Modell $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Quellen: $publishers';
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
    return 'Klärung: offiziell exakt $exact / $total Felder · in dieser Sitzung bestätigt $sessionConfirmed / $total · ungeklärt $unresolved / $total · mehrdeutig $ambiguous / $total · widersprüchlich $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'Die OBD2-Implementierung dieser App entspricht öffentlichen Standards, darunter SAE J1979 und dem ELM327-Datenblatt; jede Formel und jeder AT-Befehl, der das Verhalten der Hardware beeinflusst, wird mehrfach überprüft, und die Ergebnisse werden in der Datei „docs/protocol-deviations.zh-TW.md“ festgehalten. Diese App steht in keiner Verbindung zu Torque oder Torque Pro.';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeSystem => 'System folgen';

  @override
  String get settingsVehicleProfileSection => 'Fahrzeugprofil';

  @override
  String get settingsVinConflict => 'VIN-Konflikt';

  @override
  String get settingsVinConflictDetail =>
      'Steuergeräte haben unterschiedliche VIN gemeldet, deshalb lässt sich die Fahrzeugidentität nicht bestätigen; jeder Kandidat wurde verworfen.';

  @override
  String get settingsVinNotRead => 'VIN wurde noch nicht gelesen';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Die VIN (Mode 09) kann jetzt aus dem Fahrzeug gelesen werden; die Identität wird nur für diese Verbindung behalten. Das rohe Diagnoseprotokoll kann die VIN weiterhin enthalten.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Nach dem Verbinden lässt sich die VIN lesen, die das Fahrzeug über sich selbst meldet; die Identität wird nicht in die nächste Verbindung übernommen. Das rohe Diagnoseprotokoll kann die VIN weiterhin enthalten.';

  @override
  String get settingsVinRead => 'VIN lesen';

  @override
  String get settingsVinReading => 'Wird gelesen…';

  @override
  String get settingsVinReportedDetail =>
      'Eine VIN ist das, was das Fahrzeug über sich selbst meldet; sie belegt nicht die technischen Daten des Modells. Die Identität wird nicht über Verbindungen hinweg übernommen; das Diagnoseprotokoll kann die VIN weiterhin enthalten.';

  @override
  String get settingsVinSimulatorReported => 'Vom Simulator gemeldete VIN';

  @override
  String get settingsVinUnavailable => 'VIN nicht verfügbar';

  @override
  String get settingsVinUnavailableDetail =>
      'Das Fahrzeug bietet womöglich keine, die Antwort war womöglich unvollständig, oder sie wurde bei dieser Verbindung nicht gelesen; es wird nichts geraten und kein Zeichen ergänzt.';

  @override
  String get settingsVinVehicleReported => 'Vom Fahrzeug gemeldete VIN';

  @override
  String get startupCannotComplete =>
      'Die Startprüfungen können nicht abgeschlossen werden';

  @override
  String get startupChecking =>
      'Überprüfung des lokalen Freigabecaches und der Telemetriedaten';

  @override
  String get startupRestartHint =>
      'Der lokale Freigabecache oder die Telemetriedaten konnten nicht überprüft werden. Beenden Sie Telltale vollständig und starten Sie das Programm erneut, damit die falsche Datei nicht überschrieben, gelöscht oder freigegeben wird.';

  @override
  String get startupRestartRequired =>
      'Ein Neustart ist erforderlich, um sicher fortfahren zu können';

  @override
  String get startupRetry => 'Erneut versuchen';

  @override
  String get startupRetryHint =>
      'Lassen Sie Telltale im Vordergrund laufen und versuchen Sie es erneut, sobald die Bearbeitung anderer Dateien abgeschlossen ist. Die Funktionen „Aufnahme“, „Wiedergabe“, „Export“ und „Löschen“ bleiben deaktiviert, bis der Startvorgang abgeschlossen ist.';

  @override
  String get telemetryArtifactRestartRequired =>
      'Der Stand der lokalen Dateivorgänge lässt sich nicht bestätigen. Beenden Sie Telltale vollständig und öffnen Sie es neu, bevor Sie weitermachen';

  @override
  String get telemetryBlockedByRecorder =>
      'Beenden und speichern Sie zuerst die Aufzeichnung';

  @override
  String get telemetryCancel => 'Abbrechen';

  @override
  String get telemetryDamagedCollision =>
      'Eine fertige und eine unfertige Datei teilen sich diese ID – keine der beiden wurde ausgewählt';

  @override
  String get telemetryDamagedCorrupt =>
      'Die Aufzeichnung ist beschädigt und kann nicht sicher gelesen werden.';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Dateizeit $time';
  }

  @override
  String get telemetryDelete => 'Löschen';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Dadurch wird $id (Dateizeit $time) gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.';
  }

  @override
  String get telemetryDeleteDamagedTitle =>
      'Diese beschädigte Aufzeichnung löschen?';

  @override
  String get telemetryDeleteDamagedTooltip =>
      'Beschädigte Aufzeichnung löschen';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'Der Löschvorgang wurde nicht abgeschlossen: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Bitte bestätigen Sie zunächst diese Löschung';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Dadurch wird die Aufzeichnung aus $time gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.';
  }

  @override
  String get telemetryDeleteSessionTitle =>
      'Diese lokale Aufzeichnung löschen?';

  @override
  String get telemetryDemoData => 'Daten des integrierten Simulators';

  @override
  String get telemetryDismissNotice => 'Schließen';

  @override
  String get telemetryEndedByBackground =>
      'Der Vorgang wurde angehalten, als Telltale in den Hintergrund wechselte';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'Die PID-Auswahl hat sich geändert';

  @override
  String get telemetryEndedByDisconnect =>
      'Wurde angehalten, als die Verbindung unterbrochen wurde';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Das $minutes Minuten-Limit wurde erreicht';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Der lokale Speicher für Aufzeichnungen ist voll';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Nach der letzten Unterbrechung wiederhergestellt';

  @override
  String get telemetryEndedBySessionReplacement =>
      'Die Verbindungssitzung wurde ersetzt';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Diese Aufzeichnung hat ihre Größenbeschränkung erreicht';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'Der Speicher kam nicht hinterher';

  @override
  String get telemetryEndedByStorageFailure =>
      'Das Speichern ist fehlgeschlagen';

  @override
  String get telemetryEndedByUser => 'Von Ihnen angehalten';

  @override
  String get telemetryExport => 'Exportieren';

  @override
  String get telemetryExportCsv => 'Als CSV exportieren';

  @override
  String telemetryExportFailed(String reason) {
    return 'Der Export wurde nicht abgeschlossen: $reason';
  }

  @override
  String get telemetryExportJson => 'JSON exportieren';

  @override
  String get telemetryExportSheetTitle =>
      'Eine lokale Aufzeichnung exportieren';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lücken',
      one: '1 Lücke',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count gespeicherte Gruppen – offline wiedergeben und exportieren',
      one: '1 gespeicherte Gruppe – offline wiedergeben und exportieren',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit Gruppen';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Gruppen werden nicht angezeigt',
      one: '1 weitere Gruppe wird nicht angezeigt',
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
    return 'Lokaler Speicher: $groups von $groupLimit Gruppen, $used von $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => 'Nicht verbunden';

  @override
  String get telemetryOfflineSampledReplay => 'Offline-Wiedergabe, abgetastet';

  @override
  String get telemetryOpenHistory => 'Lokale Aufzeichnungen öffnen';

  @override
  String get telemetryPause => 'Pause';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Dieser Prozess hält den Vorgang weiterhin aufrecht. Sollte er hier verharren, beenden Sie Telltale vollständig und starten Sie es erneut.';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Abspielen';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Zeichnet nur die OBD-Signale auf, die Sie aktiviert haben – keine Standort-, VIN- oder Kontodaten. Trends zeigen höchstens $laneLimit Signale; eine Aufzeichnung behält alle $activeCount aktivierten Signale und ergänzt geschätzte Leistung und geschätzten Kraftstoffverbrauch, die auf den Fahrzeugannahmen beruhen.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Aufzeichnung – noch keine Werte';

  @override
  String get telemetryRecorderPhaseCompleted => 'Aufzeichnung gespeichert';

  @override
  String get telemetryRecorderPhaseFailed =>
      'Das Speichern der Aufzeichnung ist fehlgeschlagen';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Speichern der Aufnahme';

  @override
  String get telemetryRecorderPhaseIdle =>
      'Lokale Aufzeichnung nur im Vordergrund';

  @override
  String get telemetryRecorderPhasePreparing => 'Vorbereitung der Aufnahme';

  @override
  String get telemetryRecorderPhaseRecording => 'Aufnahme';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Aufzeichnung $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count unvollständige Dateien ohne gültige Werte wurden bereinigt',
      one: '1 unvollständige Datei ohne gültige Werte wurde bereinigt',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count beschädigte oder widersprüchliche Dateien blieben unverändert',
      one: '1 beschädigte oder widersprüchliche Datei blieb unverändert',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Beschädigte Inhalte werden niemals für die Wiedergabe oder den Export verwendet und können nur manuell gelöscht werden, solange dies gefahrlos möglich ist.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unterbrochene Aufzeichnungen wurden sicher abgeschlossen',
      one: '1 unterbrochene Aufzeichnung wurde sicher abgeschlossen',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Die Startprüfung der Aufzeichnungen ist abgeschlossen';

  @override
  String get telemetryReload => 'Neu laden';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Unterbrechungen',
      one: '1 Unterbrechung',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed =>
      'Die Aufzeichnung konnte nicht geladen werden';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Wiedergabeposition $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abgetastete Punkte',
      one: '1 abgetasteter Punkt',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Wiedergabe der Aufzeichnung';

  @override
  String get telemetryReplayUnreadable =>
      'Die Aufzeichnung ist beschädigt oder kann nicht gelesen werden';

  @override
  String get telemetryRestartToRepairSave =>
      'Das Speichern wurde nicht abgeschlossen – starten Sie Telltale neu, um die Aufzeichnungen wiederherzustellen';

  @override
  String get telemetryRestartToRepairStartup =>
      'Die Startbereinigung wurde nicht abgeschlossen – starten Sie Telltale neu, um die Aufzeichnungen zu reparieren';

  @override
  String get telemetryReturnToTrends => 'Zurück zu den Trends';

  @override
  String get telemetryRigData => 'Daten vom Prüfstand';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Beschädigte Aufnahmedateien';

  @override
  String get telemetrySessionsEmpty =>
      'Noch keine lokalen Aufzeichnungen\nBitte stellen Sie eine Verbindung her und beginnen Sie dann mit der Aufzeichnung';

  @override
  String get telemetrySessionsLoadFailed =>
      'Konnte nicht geladen werden – bitte erneut versuchen';

  @override
  String get telemetrySessionsReplayable =>
      'Aufnahmen, die Sie erneut abspielen können';

  @override
  String get telemetrySessionsTitle => 'Lokale Aufzeichnungen';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Signale',
      one: '1 Signal',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Eine andere Aufzeichnung oder ein anderer Dateivorgang ist noch nicht abgeschlossen';

  @override
  String get telemetryStartCannotCreateFile =>
      'Die Aufnahmedatei konnte nicht erstellt werden';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Diese PID-Auswahl kann nicht sicher erfasst werden – bitte überprüfen Sie die Definitionen';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale wurde in den Hintergrund verschoben – es wurde keine Aufzeichnung gestartet';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'Die Verbindung wurde unterbrochen – es wurde keine Aufzeichnung gestartet';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'Die Verbindungssitzung wurde ersetzt – es wurde keine Aufzeichnung gestartet';

  @override
  String get telemetryStartLibraryByteLimit =>
      'Nicht genügend Speicherplatz für eine Aufzeichnung – exportieren oder löschen Sie zunächst einige davon';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Die lokalen Aufzeichnungen haben das Limit von $limit erreicht – exportieren oder löschen Sie zunächst einige davon';
  }

  @override
  String get telemetryStartMoving => 'Parken Sie das Fahrzeug zunächst';

  @override
  String get telemetryStartNeedsActivePid =>
      'Aktivieren Sie zunächst mindestens eine PID';

  @override
  String get telemetryStartNeedsConnection =>
      'Stellen Sie vor Beginn einer Aufnahme eine Verbindung her';

  @override
  String get telemetryStartNeedsForeground =>
      'Bringen Sie Telltale in den Vordergrund, bevor Sie eine Aufnahme starten';

  @override
  String get telemetryStartRecording => 'Die Aufzeichnung wurde gestartet';

  @override
  String get telemetryStartRecordingButton => 'Aufnahme starten';

  @override
  String get telemetryStartSpeedUnknown =>
      'Es lässt sich nicht bestätigen, dass das Fahrzeug angehalten hat – bitte zuerst die Verbindung trennen';

  @override
  String get telemetryStartTooManyPids =>
      'Eine Aufzeichnung behält die Spalten für geschätzte Leistung und geschätzten Verbrauch – schalten Sie zuerst einige PIDs ab';

  @override
  String get telemetryStarting => 'Wird gestartet';

  @override
  String get telemetryStatusBusError => 'Busfehler';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Statuswerte',
      one: '1 Status',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Formelfehler';

  @override
  String get telemetryStatusHeaderMismatch =>
      'Der Header passt nicht zu diesem Bus';

  @override
  String get telemetryStatusNoAnswer =>
      'Keine Antwort – es wird erneut versucht';

  @override
  String get telemetryStatusStale => 'Die Daten sind veraltet';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Keine reine Leseabfrage – es wurde nichts gesendet';

  @override
  String get telemetryStatusUnsupported =>
      'Das Steuergerät hat geantwortet, dass es dies nicht unterstützt';

  @override
  String get telemetryStopAndSave => 'Beenden und speichern';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gültige Werte',
      one: '1 gültiger Wert',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Löschen';

  @override
  String get transcriptDeleteBusy =>
      'Ein weiterer Dateivorgang ist noch nicht abgeschlossen.';

  @override
  String get transcriptDeleteFailed =>
      'Das Protokoll der vorherigen Verbindung konnte nicht gelöscht werden.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'Die aktuelle Geschwindigkeit oder der aktuelle Verbindungsstatus lassen das Löschen des Protokolls nicht zu.';

  @override
  String get transcriptExport => 'Exportieren';

  @override
  String get transcriptExportButton => 'Protokoll exportieren';

  @override
  String get transcriptExportExplanation =>
      'Diese Verbindung behält den einleitenden Handshake und den zuletzt übertragenen Rohverkehr; fällt bei einer langen Verbindung die Mitte weg, steht das in der Datei. Wenn am Fahrzeug etwas nicht lesbar ist, bringt es weit mehr, das Protokoll zu exportieren und mitzubringen, als eine einzelne Meldung auf dem Bildschirm.';

  @override
  String transcriptExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get transcriptExportWithHex => 'Mit Hex';

  @override
  String get transcriptNothingToExport =>
      'Es gibt kein Protokoll, das exportiert werden könnte.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Zurückgelassen um $timestamp, $size. Es hat überstanden, dass das System Telltale beendet hat oder das Telefon die Stromversorgung verloren hat.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'Das Protokoll der vorherigen Verbindung hat sich geändert – überprüfen Sie es bitte erneut.';

  @override
  String get transcriptRecoveredTitle => 'Protokoll der vorherigen Verbindung';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes Bytes',
      one: '1 Byte',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => 'Jetzt';

  @override
  String get trendChooseSignals => 'Signale auswählen';

  @override
  String get trendLiveData => 'Echtzeitdaten';

  @override
  String get trendNoSignalsBody =>
      'Aktivieren Sie zunächst auf der PID-Seite die Signale, die Sie überwachen möchten.';

  @override
  String get trendNoSignalsTitle => 'Es liegen keine Trendsignale vor';

  @override
  String get trendNoUnits => 'Keine Einheiten';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Vergleichen Sie bis zu $limit Signale. Das ändert nicht, welche PIDs abgefragt werden.';
  }

  @override
  String get trendPickSignalsTitle => 'Trendsignale auswählen';

  @override
  String trendRemoveSignal(String name) {
    return '$name entfernen';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Die Auswahl für die Trendanzeige konnte nicht gespeichert werden';

  @override
  String trendSheetBody(int limit) {
    return 'Wählen Sie höchstens $limit aus. Dies wirkt sich lediglich auf die grafische Darstellung aus, nicht jedoch auf die PID-Abfrage oder eine laufende Aufzeichnung.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Fertig · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Eines dieser Signale befindet sich nicht mehr auf der PID-Beobachtungsliste';

  @override
  String get trendSignalsHeading => 'Trendsignale';

  @override
  String trendTooManySelected(int limit) {
    return 'Wählen Sie höchstens $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Anzeige der letzten $seconds Sekunden';
  }

  @override
  String get wearBack => 'Zurück';

  @override
  String get wearBatteryVoltageLabel => 'Batterie';

  @override
  String get wearBleAdapters => 'BLE-Adapter';

  @override
  String get wearCancel => 'Abbrechen';

  @override
  String get wearConfirmVehicle => 'Fahrzeug bestätigen';

  @override
  String get wearConfirmVehicleAccept => 'Ja, dieses Fahrzeug';

  @override
  String get wearConfirmVehicleBody =>
      'Nach der Bestätigung werden die nur lesenden Batterieabfragen für dieses Modell für die restliche Dauer dieser Verbindung abgefragt. Bei einem falschen Modell kann ein plausibler, aber falscher Wert zurückgegeben werden – brechen Sie den Vorgang ab, wenn Sie sich nicht sicher sind.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Verbindung konnte nicht hergestellt werden: $adapter';
  }

  @override
  String get wearConnecting => 'Wird verbunden…';

  @override
  String get wearDemoSimulator => 'Demo-Simulator';

  @override
  String get wearDisconnect => 'Trennen';

  @override
  String get wearDisconnectQuestion => 'Trennen?';

  @override
  String get wearNoDevicesFound => 'Es wurden keine Geräte gefunden';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Standort';

  @override
  String get wearScanAgain => 'Erneut scannen';

  @override
  String get wearScanFailed =>
      'Der Scan ist fehlgeschlagen – bitte versuchen Sie es erneut';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'Zum Suchen wird die Berechtigung „$permission“ gebraucht';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'Die Berechtigung „$permission“ wird dauerhaft verweigert – aktivieren Sie sie in den Systemeinstellungen und versuchen Sie es dann erneut';
  }

  @override
  String get wearScanning => 'Wird gescannt…';

  @override
  String get telemetryRecorderNotRecording => 'Keine Aufzeichnung';

  @override
  String get dtcKindStored => 'Gespeichert';

  @override
  String get dtcKindPending => 'Ausstehend';

  @override
  String get dtcKindPermanent => 'Permanent';

  @override
  String get dtcKindStoredExplanation =>
      'Ein bestätigter Fehler; die Fehleranzeige im Armaturenbrett leuchtet in der Regel.';

  @override
  String get dtcKindPendingExplanation =>
      'Einmal erkannt und hat den Bestätigungsschwellenwert noch nicht erreicht.';

  @override
  String get dtcKindPermanentExplanation =>
      'Lässt sich mit einem Diagnosegerät nicht löschen. Die ECU löscht ihn selbst, und zwar erst, wenn sie die Reparatur bestätigt hat.';

  @override
  String get dtcSystemPowertrain => 'Antriebsstrang';

  @override
  String get dtcSystemChassis => 'Fahrwerk';

  @override
  String get dtcSystemBody => 'Karosserie';

  @override
  String get dtcSystemNetwork => 'Netzwerk';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Kraftstoff- und Luftdosierung sowie zusätzliche Emissionskontrollsysteme';

  @override
  String get dtcSubsystemFuelAirMetering => 'Kraftstoff- und Luftdosierung';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Kraftstoff- und Luftdosierung (Einspritzkreis)';

  @override
  String get dtcSubsystemIgnitionOrMisfire => 'Zündanlage oder Zündaussetzer';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Zusätzliche Emissionsminderungsmaßnahmen';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'System zur Regelung der Fahrzeuggeschwindigkeit und des Leerlaufs';

  @override
  String get dtcSubsystemComputerOutputCircuit => 'Computer-Ausgangsschaltung';

  @override
  String get dtcSubsystemTransmission => 'Getriebe';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Steuermodule, Ein- und Ausgangssignale';

  @override
  String get dtcDescriptionB0001 =>
      'Fehler bei der Steuerung der Auslösung des Fahrerairbags';

  @override
  String get dtcDescriptionP0011 =>
      'Nockenwellenposition A – Steuerzeit zu weit vorverstellt oder Systemleistung (Bank 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Nockenwellenposition B – Steuerzeit zu weit vorverstellt oder Systemleistung (Bank 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Korrelation zwischen Kurbelwellen- und Nockenwellenposition (Bank 1, Sensor A)';

  @override
  String get dtcDescriptionP0087 =>
      'Der Druck in der Kraftstoffverteilerleitung bzw. im Kraftstoffsystem ist zu niedrig';

  @override
  String get dtcDescriptionP0088 =>
      'Der Druck in der Kraftstoffverteilerleitung bzw. im Kraftstoffsystem ist zu hoch';

  @override
  String get dtcDescriptionP0100 =>
      'Fehlfunktion der Schaltung des Luftmassenmessers (MAF)';

  @override
  String get dtcDescriptionP0101 =>
      'Problem mit dem Messbereich bzw. der Leistung des Luftmassenmessers';

  @override
  String get dtcDescriptionP0102 =>
      'Niedriger Eingangssignalpegel der Schaltung des Luftmassenmessers';

  @override
  String get dtcDescriptionP0103 =>
      'Hoher Eingangspegel in der Schaltung des Luftmassenmessers';

  @override
  String get dtcDescriptionP0105 =>
      'Fehlfunktion im Schaltkreis des Saugrohrdruck-/Umgebungsdrucksensors';

  @override
  String get dtcDescriptionP0106 =>
      'Saugrohrdrucksensor: Problem mit Messbereich oder Leistung';

  @override
  String get dtcDescriptionP0107 =>
      'Schaltkreis des Saugrohrdrucksensors: niedriger Eingang';

  @override
  String get dtcDescriptionP0108 =>
      'Schaltkreis des Saugrohrdrucksensors: hoher Eingang';

  @override
  String get dtcDescriptionP0110 =>
      'Fehlfunktion der Schaltung des Ansauglufttemperatursensors';

  @override
  String get dtcDescriptionP0111 =>
      'Problem mit dem Messbereich bzw. der Leistung des Ansauglufttemperatursensors';

  @override
  String get dtcDescriptionP0112 =>
      'Schaltkreis des Ansauglufttemperatursensors: niedriger Eingang';

  @override
  String get dtcDescriptionP0113 =>
      'Schaltkreis des Ansauglufttemperatursensors: hoher Eingang';

  @override
  String get dtcDescriptionP0115 =>
      'Fehlfunktion der Schaltung des Motorkühlmitteltemperatursensors';

  @override
  String get dtcDescriptionP0116 =>
      'Problem mit dem Messbereich bzw. der Leistung des Motorkühlmitteltemperatursensors';

  @override
  String get dtcDescriptionP0117 =>
      'Schaltkreis des Motorkühlmitteltemperatursensors: zu niedriger Eingangspegel';

  @override
  String get dtcDescriptionP0118 =>
      'Schaltkreis des Motorkühlmitteltemperatursensors: hoher Eingang';

  @override
  String get dtcDescriptionP0120 =>
      'Fehlfunktion der Schaltung des Drosselklappensensors';

  @override
  String get dtcDescriptionP0121 =>
      'Problem mit dem Messbereich bzw. der Leistung des Drosselklappensensors';

  @override
  String get dtcDescriptionP0122 =>
      'Schaltkreis des Drosselklappensensors: niedriger Eingang';

  @override
  String get dtcDescriptionP0123 =>
      'Schaltkreis des Drosselklappensensors: Hoher Eingangspegel';

  @override
  String get dtcDescriptionP0125 =>
      'Unzureichende Kühlmitteltemperatur für die Kraftstoffregelung im geschlossenen Regelkreis';

  @override
  String get dtcDescriptionP0128 =>
      'Kühlmitteltemperatur unterhalb der Thermostat-Regelungstemperatur';

  @override
  String get dtcDescriptionP0130 =>
      'Fehlfunktion der LAM-Schaltung (Bank 1, Sensor 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Niedrige Spannung in der Schaltung des Sauerstoffsensors (Bank 1, Sensor 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Hochspannung im Schaltkreis des Lambdasensors (Bank 1, Sensor 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Langsame Ansprechzeit der Lambdasonden-Schaltung (Bank 1, Sonde 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Keine Aktivität im Sauerstoffsensor-Schaltkreis festgestellt (Bank 1, Sensor 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Fehlfunktion der Heizschaltung des Lambdasensors (Bank 1, Sensor 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Fehlfunktion der Sauerstoffsensorschaltung (Bank 1, Sensor 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Niedrige Spannung im Schaltkreis des Lambdasensors (Bank 1, Sensor 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Hochspannung im Schaltkreis des Lambdasensors (Bank 1, Sensor 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Keine Aktivität im Sauerstoffsensor-Schaltkreis festgestellt (Bank 1, Sensor 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Fehlfunktion der Heizschaltung des Lambdasensors (Bank 1, Sensor 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Fehlfunktion der Sauerstoffsensorschaltung (Bank 2, Sensor 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Fehlfunktion der Heizschaltung des Lambdasensors (Bank 2, Sensor 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Fehlfunktion der Sauerstoffsensorschaltung (Bank 2, Sensor 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Fehlfunktion der Heizschaltung des Lambdasensors (Bank 2, Sensor 2)';

  @override
  String get dtcDescriptionP0170 => 'Störung der Kraftstofftrimmung (Bank 1)';

  @override
  String get dtcDescriptionP0171 => 'System zu mager (Bank 1)';

  @override
  String get dtcDescriptionP0172 => 'System zu fett (Bank 1)';

  @override
  String get dtcDescriptionP0173 => 'Störung der Kraftstoffanpassung (Bank 2)';

  @override
  String get dtcDescriptionP0174 => 'System zu mager (Bank 2)';

  @override
  String get dtcDescriptionP0175 => 'System zu fett (Bank 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Fehlfunktion der Schaltung des Kraftstoffleitungsdrucksensors';

  @override
  String get dtcDescriptionP0201 =>
      'Störung oder Unterbrechung in der Einspritzschaltung – Zylinder 1';

  @override
  String get dtcDescriptionP0202 =>
      'Fehlfunktion oder Unterbrechung der Einspritzschaltung – Zylinder 2';

  @override
  String get dtcDescriptionP0203 =>
      'Fehlfunktion oder Unterbrechung der Einspritzschaltung – Zylinder 3';

  @override
  String get dtcDescriptionP0204 =>
      'Fehlfunktion oder Unterbrechung der Einspritzschaltung – Zylinder 4';

  @override
  String get dtcDescriptionP0217 => 'Überhitzung des Motors';

  @override
  String get dtcDescriptionP0221 =>
      'Problem mit dem Drehzahl-/Pedalstellungssensor B: Reichweite/Leistung';

  @override
  String get dtcDescriptionP0222 =>
      'Gaspedal-/Pedalstellungssensor B: niedriger Eingang';

  @override
  String get dtcDescriptionP0223 =>
      'Eingangsspannung zu hoch im Schaltkreis des Drosselklappen-/Pedalstellungssensors B';

  @override
  String get dtcDescriptionP0234 =>
      'Überladungszustand des Turboladers/Kompressors';

  @override
  String get dtcDescriptionP0299 =>
      'Turbolader/Kompressor: Ein Zustand mit Unterdruck';

  @override
  String get dtcDescriptionP0300 =>
      'Es wurde eine zufällige oder eine Fehlzündung an mehreren Zylindern festgestellt';

  @override
  String get dtcDescriptionP0301 => 'Fehlzündung in Zylinder 1 festgestellt';

  @override
  String get dtcDescriptionP0302 => 'Fehlzündung in Zylinder 2 festgestellt';

  @override
  String get dtcDescriptionP0303 => 'Fehlzündung in Zylinder 3 festgestellt';

  @override
  String get dtcDescriptionP0304 => 'Fehlzündung in Zylinder 4 festgestellt';

  @override
  String get dtcDescriptionP0305 => 'Fehlzündung in Zylinder 5 festgestellt';

  @override
  String get dtcDescriptionP0306 => 'Fehlzündung in Zylinder 6 festgestellt';

  @override
  String get dtcDescriptionP0307 => 'Fehlzündung in Zylinder 7 festgestellt';

  @override
  String get dtcDescriptionP0308 => 'Fehlzündung in Zylinder 8 festgestellt';

  @override
  String get dtcDescriptionP0316 =>
      'Unmittelbar nach dem Start wurde eine Fehlzündung festgestellt';

  @override
  String get dtcDescriptionP0325 =>
      'Fehlfunktion der Klopfsensorschaltung (Bank 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Problem mit dem Messbereich/der Leistung des Klopfsensors (Bank 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Klopfsensor-Schaltung: niedriger Eingang (Bank 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Klopfsensor-Schaltung: Hoher Eingang (Bank 1)';

  @override
  String get dtcDescriptionP0330 =>
      'Fehlfunktion der Klopfsensorschaltung (Bank 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Fehlfunktion der Schaltung des Kurbelwellenpositionsgebers';

  @override
  String get dtcDescriptionP0336 =>
      'Problem mit dem Messbereich bzw. der Leistung des Kurbelwellenpositionssensors';

  @override
  String get dtcDescriptionP0340 =>
      'Fehlfunktion der Schaltung des Nockenwellenpositionssensors';

  @override
  String get dtcDescriptionP0341 =>
      'Problem mit dem Messbereich bzw. der Leistung des Nockenwellenpositionssensors';

  @override
  String get dtcDescriptionP0351 =>
      'Zündspule: Störung im Primär-/Sekundärkreis';

  @override
  String get dtcDescriptionP0352 =>
      'Fehler im Primär-/Sekundärkreis der Zündspule B';

  @override
  String get dtcDescriptionP0353 =>
      'Fehler im Primär-/Sekundärkreis der Zündspule C';

  @override
  String get dtcDescriptionP0354 =>
      'Fehler im Primär-/Sekundärkreis der Zündspule D';

  @override
  String get dtcDescriptionP0355 =>
      'Fehler im Primär-/Sekundärkreis der Zündspule E';

  @override
  String get dtcDescriptionP0356 =>
      'Fehler im Primär-/Sekundärkreis der Zündspule F';

  @override
  String get dtcDescriptionP0400 =>
      'Fehler im Durchfluss der Abgasrückführung (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Unzureichender Durchfluss der Abgasrückführung (EGR)';

  @override
  String get dtcDescriptionP0402 =>
      'Zu hoher Durchfluss bei der Abgasrückführung (EGR)';

  @override
  String get dtcDescriptionP0403 =>
      'Fehlfunktion der Regelstrecke für die Abgasrückführung (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Problem mit dem Regelbereich bzw. der Leistung des Regelkreises für die Abgasrückführung (EGR)';

  @override
  String get dtcDescriptionP0410 => 'Störung des Sekundärluftzufuhrsystems';

  @override
  String get dtcDescriptionP0411 =>
      'Im Sekundärluftzufuhrsystem wurde ein fehlerhafter Durchfluss festgestellt';

  @override
  String get dtcDescriptionP0412 =>
      'Umschaltventil des Sekundärluftzufuhrsystems – Eine Störung im Schaltkreis';

  @override
  String get dtcDescriptionP0420 =>
      'Effizienz des Katalysatorsystems unterhalb des Schwellenwerts (Bank 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Effizienz des Katalysatorsystems unterhalb des Schwellenwerts (Bank 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Fehlfunktion des Systems zur Kontrolle der Verdunstungsemissionen';

  @override
  String get dtcDescriptionP0441 =>
      'Falscher Spülstrom im Verdunstungsemissionssystem';

  @override
  String get dtcDescriptionP0442 =>
      'Leck im Verdunstungsemissionssystem festgestellt (kleines Leck)';

  @override
  String get dtcDescriptionP0443 =>
      'Fehlfunktion des Regelkreises des Spülventils des Verdunstungsemissionssystems';

  @override
  String get dtcDescriptionP0446 =>
      'Fehlfunktion der Regelungsschaltung für die Entlüftung des Verdunstungsemissionssystems';

  @override
  String get dtcDescriptionP0447 =>
      'Schaltkreis zur Steuerung der Entlüftung des Verdunstungsemissionssystems offen';

  @override
  String get dtcDescriptionP0449 =>
      'Fehlfunktion des Entlüftungsventils bzw. des Magnetventilkreises des Verdunstungsemissionssystems';

  @override
  String get dtcDescriptionP0451 =>
      'Problem mit dem Messbereich bzw. der Leistung des Drucksensors des Verdunstungsemissionssystems';

  @override
  String get dtcDescriptionP0452 =>
      'Schaltkreis des Drucksensors des Verdunstungsemissionssystems: niedriger Eingang';

  @override
  String get dtcDescriptionP0453 =>
      'Schaltkreis des Drucksensors des Verdunstungsemissionssystems – hoher Eingang';

  @override
  String get dtcDescriptionP0455 =>
      'Leck im Verdunstungsemissionssystem festgestellt (großes Leck)';

  @override
  String get dtcDescriptionP0456 =>
      'Es wurde ein Leck im Verdunstungsemissionssystem festgestellt (sehr kleines Leck)';

  @override
  String get dtcDescriptionP0480 =>
      'Fehlfunktion der Steuerungsschaltung für Lüfter 1';

  @override
  String get dtcDescriptionP0500 =>
      'Fehlfunktion des Fahrzeuggeschwindigkeitssensors';

  @override
  String get dtcDescriptionP0505 => 'Fehlfunktion des Leerlaufregelsystems';

  @override
  String get dtcDescriptionP0506 =>
      'Drehzahl des Leerlaufregelsystems liegt unter den Erwartungen';

  @override
  String get dtcDescriptionP0507 =>
      'Drehzahl des Leerlaufregelsystems höher als erwartet';

  @override
  String get dtcDescriptionP0508 =>
      'Schaltkreis des Leerlaufregelsystems – niedriger Wert';

  @override
  String get dtcDescriptionP0509 =>
      'Schaltkreis des Leerlaufregelsystems – Spannung zu hoch';

  @override
  String get dtcDescriptionP0560 => 'Störung der Systemspannung';

  @override
  String get dtcDescriptionP0562 => 'Systemspannung zu niedrig';

  @override
  String get dtcDescriptionP0563 => 'Systemspannung zu hoch';

  @override
  String get dtcDescriptionP0603 =>
      'Fehler im Keep-Alive-Speicher (KAM) des internen Steuermoduls';

  @override
  String get dtcDescriptionP0605 =>
      'Fehler im Nur-Lese-Speicher (ROM) des internen Steuermoduls';

  @override
  String get dtcDescriptionP0606 => 'Fehler des ECM/PCM-Prozessors';

  @override
  String get dtcDescriptionP0700 =>
      'Das Getriebesteuergerät hat die Fehleranzeige ausgelöst – der Fehlercode selbst befindet sich im Getriebesteuergerät und muss separat ausgelesen werden';

  @override
  String get dtcDescriptionP0701 =>
      'Problem mit der Reichweite/Leistung des Getriebesteuerungssystems';

  @override
  String get dtcDescriptionP0702 =>
      'Elektrischer Fehler im Getriebesteuerungssystem';

  @override
  String get dtcDescriptionP0705 =>
      'Fehlfunktion der Schaltbereichssensor-Schaltung';

  @override
  String get dtcDescriptionP0715 =>
      'Fehlfunktion der Schaltung für den Eingangs-/Turbinendrehzahlsensor';

  @override
  String get dtcDescriptionP0720 =>
      'Fehlfunktion der Schaltung des Drehzahlsensors';

  @override
  String get dtcDescriptionP0730 => 'Falsches Übersetzungsverhältnis';

  @override
  String get dtcDescriptionP0740 =>
      'Fehlfunktion der Torque-Konverterkupplungsschaltung';

  @override
  String get dtcDescriptionP0741 =>
      'Torque-Wandlerkupplung bleibt in der Aus-Stellung hängen';

  @override
  String get dtcDescriptionP0750 => 'Störung des Schaltmagneten A';

  @override
  String get dtcDescriptionP0755 => 'Störung des Schaltmagneten B';

  @override
  String get dtcDescriptionP2135 =>
      'Spannungskorrelation der Drosselklappensensoren A und B';

  @override
  String get dtcDescriptionU0100 =>
      'Die Verbindung zu ECM/PCM ist unterbrochen';

  @override
  String get dtcDescriptionU0101 =>
      'Die Kommunikation mit dem Getriebesteuergerät ist unterbrochen';

  @override
  String get dtcDescriptionU0121 =>
      'Die Kommunikation mit dem ABS-Steuergerät ist unterbrochen';

  @override
  String get dtcDescriptionU0140 =>
      'Die Kommunikation mit dem Karosseriesteuergerät ist unterbrochen';

  @override
  String get dtcDescriptionU0155 =>
      'Die Kommunikation mit dem Steuermodul des Armaturenbretts ist unterbrochen';

  @override
  String get gaugeSkinCluster => 'Cluster';

  @override
  String get gaugeSkinClusterDescription =>
      'Sieht aus wie ein serienmäßiges Kombiinstrument. Zeiger, 270-Grad-Skala, vertiefte Zifferblattfläche.';

  @override
  String get gaugeSkinMinimal => 'Minimal';

  @override
  String get gaugeSkinMinimalDescription =>
      'Ein halber Bogen, keine Nadel, keine Teilstriche. Der Wert entspricht dem, was Sie ablesen, nicht der Bewegung.';

  @override
  String get gaugeSkinTrack => 'Titel';

  @override
  String get gaugeSkinTrackDescription =>
      'Segmentierter Balken, keine Glättung. Der Wert liegt genau dort, wo er liegt, ohne Zwischenwerte.';

  @override
  String get gaugeSkinClassic => 'Klassiker';

  @override
  String get gaugeSkinClassicDescription =>
      'Bedrucktes Zifferblatt, durchgehende Ziffern, ein Zeiger, der sich langsam wie bei einer mechanischen Uhr einpendelt.';

  @override
  String get gaugeSkinNight => 'Nacht';

  @override
  String get gaugeSkinNightDescription =>
      'Für das Fahren bei Dunkelheit. Geringe Helligkeit, ein flacher Lichtbogen, keine Animationen – damit Ihre Aufmerksamkeit so wenig wie möglich abgelenkt wird.';

  @override
  String get derivedAirflowSourceMaf => 'MAF-Sensor';

  @override
  String get derivedAirflowSourceSpeedDensity =>
      'Schätzung der Geschwindigkeitsdichte';

  @override
  String get derivedAirflowSourceUnavailable => 'Luftmasse nicht verfügbar';

  @override
  String get derivedFuelSourceStoichiometric => 'Stoichiometrische Schätzung';

  @override
  String get derivedFuelSourceUnavailable => 'Verbrauchsdaten nicht verfügbar';

  @override
  String get telemetrySourceDemo => 'Integrierter Simulator';

  @override
  String get telemetrySourceRig => 'Prüfstand';

  @override
  String get telemetrySourceFieldApp => 'Verbindung der Feld-App';

  @override
  String get fuelTypeGasoline => 'Benzin';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'LPG';

  @override
  String get fuelTypeEthanolE85 => 'E85-Ethanol';

  @override
  String get drivetrainFwd => 'Vorderradantrieb';

  @override
  String get drivetrainRwd => 'Hinterradantrieb';

  @override
  String get drivetrainAwd => 'Allradantrieb';

  @override
  String get assumptionFieldMass => 'Masse';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Stirnbereich';

  @override
  String get assumptionFieldRollingResistance => 'Rollwiderstand';

  @override
  String get assumptionFieldDrivetrainEfficiency =>
      'Antriebsstrangwirkungsgrad';

  @override
  String get assumptionFieldFuelType => 'Kraftstoff';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Dichte';

  @override
  String get assumptionFieldDisplacement => 'Hubraum';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'allgemeiner Standardwert';

  @override
  String get vehicleFieldOriginUserEntered => 'von Ihnen eingegeben';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'amtliches Register';

  @override
  String get vehicleFieldOriginManufacturerPublication => 'Herstellerangaben';

  @override
  String get vehicleFieldOriginScientificModel => 'Modellkoeffizient';

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
      'L/h = (MAF g/s) / (AFR × Kraftstoffdichte g/L) × 3600; MAF ist entweder PID 0110 oder die Drehzahl-Dichte (RPM × MAP × Hubraum × VE / T_K); L/100 km = (L/h) / Geschwindigkeit_km/h × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'Die Schätzung basiert auf den Fahrzeugeinstellungen, wie sie zum Zeitpunkt der Aufzeichnung vorlagen.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Gibt die Firmware-Version v$version an, die nie veröffentlicht wurde';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics hat diese Version nie veröffentlicht, daher entspricht die Firmware dieses Adapters nicht der angegebenen. Viele dieser Adapter funktionieren zwar noch – doch der Angaben des Herstellers kann man nicht trauen, und man sollte zunächst einen Verdacht hegen, wenn ein Gerät nicht gelesen werden kann.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Behauptet v$version, kennt jedoch ATPPS nicht, was in v1.1 noch vorhanden war';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'Die Übersicht über die programmierbaren Parameter (ATPPS) gibt es bereits seit ELM327 v1.1, und selbst High-End-Adapter wie OBDLink unterstützen sie. Die angegebene Version und die tatsächlich implementierten Befehle stimmen jedoch nicht überein.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Beantwortet den Befehl „AT@1“ (Gerätekennung) aus der ersten Version nicht';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Dieser Befehl existiert bereits seit ELM327 v1.0. Wird er nicht beantwortet, bedeutet dies, dass dieser Chip einen kleineren Befehlssatz implementiert als jede offizielle Firmware.';

  @override
  String get telemetryReplaySampled =>
      'Die Vorschau ist eine Stichprobe; beim Export werden alle aufgezeichneten Ereignisse beibehalten.';

  @override
  String get telemetryExportDisclosure =>
      'Der Export enthält Signalnamen, Werte, Beobachtungs- und Quellzeiten, Transportart, Protokoll, festgelegte PID-Bezeichnungen, Einheiten und Formeln sowie die Annahmen für die Schätzung (Masse, Luftwiderstand, Hubraum, Kraftstoff und ähnliche Parameter). Die JSON-Datei kann zudem Ihre eigenen benutzerdefinierten Bezeichnungen, Einheiten, Formeln und vollständigen festgelegten Definitionen enthalten. Der Export enthält weder die VIN, GPS-Daten, ein Konto, die Adapteradresse, das vollständige Fahrzeugprofil noch den Rohdatenverkehr der Diagnose.';

  @override
  String get connectTransportCancelled =>
      'Der Verbindungsversuch wurde vorzeitig abgebrochen.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'Das Telefon ist nicht mit einem Wi-Fi-Netzwerk verbunden, daher besteht keine Verbindung zum Adapter. Stellen Sie eine Verbindung zum Wi-Fi-Hotspot des Adapters her und versuchen Sie es dann erneut.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'Das Telefon ist mit mehr als einem Wi-Fi-Netzwerk verbunden, und keines davon ist eindeutig das des Adapters, sodass keines ausgewählt wurde. Trennen Sie die Verbindungen, die nicht zum Adapter gehören, und versuchen Sie es dann erneut.';

  @override
  String get connectTransportWifiRouteRefused =>
      'Das System hat die Herstellung dieser Verbindung über Wi-Fi verweigert. Das Telefon ist auf Wi-Fi verbunden; dessen Nutzung für diesen Zweck war nicht zulässig.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'Das System hat die Anforderung, diese Verbindung über Wi-Fi herzustellen, nicht beantwortet. Bitte warten Sie einige Sekunden und versuchen Sie es erneut.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'Die Verbindung konnte nicht über Wi-Fi hergestellt werden, aus einem vom System nicht näher bezeichneten Grund. Der vollständige Fehler ist im nachstehenden Protokoll festgehalten.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Unter dieser Adresse wurde keine Antwort erhalten. Überprüfen Sie, ob das Telefon mit dem Hotspot „Wi-Fi“ des Adapters verbunden ist – falls das System Sie gefragt hat, ob die Verbindung ohne Internet bestehen bleiben soll, wählen Sie „Ja“. Es kann auch hilfreich sein, die mobilen Daten zu deaktivieren.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Unter dieser Adresse kam nicht rechtzeitig eine Antwort.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'Die Verbindung wurde hergestellt, doch das Netzwerk-Routing des Telefons konnte nicht wiederhergestellt werden, sodass die Verbindung unterbrochen wurde, anstatt die geänderten Einstellungen beizubehalten. Starten Sie die App neu und versuchen Sie es erneut.';

  @override
  String get connectTransportBleLinkFailed =>
      'Die Verbindung zum Adapter konnte nicht hergestellt werden. Bitte überprüfen Sie, ob der Adapter mit Strom versorgt wird und sich in Reichweite befindet.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'Das Gerät wurde angeschlossen, es wurde jedoch kein serieller Anschluss daran gefunden, sodass es sich möglicherweise nicht um einen ELM327-Adapter handelt.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Es konnte keine Verbindung zum Adapter hergestellt werden. Koppeln Sie ihn zunächst in den Systemeinstellungen des Bluetooth und vergewissern Sie sich, dass er bei eingeschalteter Zündung an die OBD-Buchse angeschlossen ist.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'Die Verbindung zum Adapter ist nach Ablauf der Zeitüberschreitung abgebrochen. Möglicherweise antwortet er noch – warten Sie bitte einige Sekunden, anstatt es sofort erneut zu versuchen.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Die serielle Schnittstelle konnte nicht geöffnet werden. Bitte überprüfen Sie, ob das System eine solche für diesen Adapter angelegt hat (COMx unter Windows, /dev/rfcomm* unter Linux) und ob die Zündung eingeschaltet ist.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'Die serielle Schnittstelle wurde geöffnet und sofort wieder geschlossen.';

  @override
  String get settingsManualCommandNotConnected =>
      'Es besteht keine Verbindung, daher wurde der Befehl nicht gesendet.';

  @override
  String get settingsManualCommandLinkDropped =>
      'Die Verbindung zum Adapter wurde unterbrochen, während dieser Befehl noch übertragen wurde, sodass keine Antwort darauf erfolgte. Es ist nicht bekannt, ob der Adapter den Befehl empfangen hat.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'Die App hat die Verbindung unterbrochen, während dieser Befehl noch übertragen wurde, sodass keine Antwort darauf erfolgte. Weder am Adapter noch am Fahrzeug liegt ein Fehler vor.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'Die Antworten des Adapters waren nicht mehr mit den an ihn gesendeten Befehlen synchron, und er reagierte nicht auf die Überprüfung, die diese Synchronisation wiederhergestellt hätte, sodass die Verbindung unterbrochen wurde. Stellen Sie die Verbindung erneut her, bevor Sie es erneut versuchen.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Vom Adapter kam so lange kein Signal, bis die Verbindung unterbrochen wurde. Möglicherweise wird er noch mit Strom versorgt; fest steht nur die Stille.';

  @override
  String get settingsManualCommandWriteFailed =>
      'Der Befehl konnte nicht an die Verbindung des Adapters weitergeleitet werden. Inwieweit er den Adapter erreicht hat, ist nicht bekannt.';

  @override
  String get settingsManualCommandTimedOut =>
      'Innerhalb der Frist ging keine Antwort ein. Bitte überprüfen Sie, ob der Adapter angeschlossen ist und die Zündung eingeschaltet ist.';

  @override
  String get settingsManualCommandOperationRetired =>
      'Diese Sitzung wurde beendet oder in den Hintergrund verschoben, sodass der Befehl nicht gesendet wurde.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Diese Anfrage kann auf dem Bus, den dieses Fahrzeug nutzt, nicht bearbeitet werden, daher wurde sie nicht gesendet. Ein erneuter Versuch wird daran nichts ändern.';

  @override
  String get manualCommandRefusedEmpty =>
      'Es wurde nichts eingegeben, daher wurde auch nichts gesendet.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Dieser Text enthält einen Zeilenumbruch oder ein anderes Steuerzeichen, wodurch mehrere Befehle gleichzeitig gesendet werden. Der Adapter trennt die Befehle anhand des Zeilenumbruchs, sodass der zweite Befehl alle hier durchgeführten Prüfungen überspringen würde – einschließlich derjenigen, die das Löschen von Fehlercodes verhindert. Senden Sie jeweils nur einen Befehl.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'In dieses Feld können Sie Fragen eingeben, jedoch keine Befehle, die die Eigenschaften des Adapters ändern. „$command“ würde den Status des Adapters ändern, während das Modell des Adapters in der App unverändert bliebe – die darauf folgenden Messwerte könnten von einem anderen Controller stammen, ohne dass dies auf dem Bildschirm erkennbar wäre.\nMögliche Abfragen: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Um Fehlercodes zu löschen, verwenden Sie die Schaltfläche „Löschen“ auf dem Fehlercode-Bildschirm. Bei einer Ausführung von hier aus würden die Bestätigung, die Abdeckungsprüfung und die Antwortvalidierung übersprungen, und der Vorgang würde nur den aktuell ausgewählten Regler betreffen.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'Der Befehl „$command“ enthält Zeichen, die in einem OBD-Befehl niemals vorkommen. Dieses Feld akzeptiert hexadezimale Servicecodes und Parameter – 0100, 03, 2211A6 – oder eine Adapterabfrage, die mit „AT“ beginnt.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '„$command“ ist kein Befehl, den dieses Feld kennt. Es nimmt reine Leseabfragen (Mode $allowed) und Adapterabfragen an.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'Der Adapter weigerte sich, diese Anfrage an den Controller $header weiterzuleiten, sodass sie nicht gesendet wurde. Wäre die Anfrage an die Adresse gesendet worden, die der Adapter tatsächlich belegt, wäre die Antwort von einem Controller zurückgekommen, der gar nicht angefragt worden war.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'Der Adapter weigerte sich, auf die Adresse $address umzuschalten, über die eine an das gesamte Fahrzeug gerichtete Anfrage gesendet werden muss. Ohne diese Adresse können die Antworten nicht den Steuerungen zugeordnet werden, von denen sie gesendet wurden; daher wurde die Anfrage nicht gestellt.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Bei diesem Fahrzeug handelt es sich um einen älteren Bus ohne Standardadresse, der alle Steuerungen erreicht, und der Adapter ist derzeit auf die Steuerung $installed eingestellt. Ein Scan hätte ausschließlich diese eine Steuerung erfasst, wäre jedoch als das gesamte Fahrzeug dargestellt worden; daher wurde er nicht gesendet. Stellen Sie die Verbindung erneut her und führen Sie dann einen erneuten Scan durch.';
  }

  @override
  String get pidFormulaEmpty => 'Die Formel ist leer.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Ein Teil der Formel ist leer – ein Operator, dem nichts folgt, oder Klammern, die leer sind.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'Die Klammern passen nicht zusammen: Jedes „(“ benötigt ein schließendes „)“.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '„$term“ ist weder eine Zahl noch ein Operator noch ein Name, den dieser Editor versteht.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() und SQRT() sind zu tief verschachtelt, um ausgewertet werden zu können. Vereinfachen Sie die Formel.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'Die Klammern sind zu tief verschachtelt, um ausgewertet werden zu können. Vereinfachen Sie die Formel.';

  @override
  String get pidFormulaDivisionByZero =>
      'Die Formel enthält eine Division durch Null.';

  @override
  String get pidFormulaModuloByZero =>
      'Die Formel berechnet den Rest der Division durch Null.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 benötigt ein Argument größer als 0, und dieses lautete $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG benötigt ein Argument größer als 0, und dieses wurde als $argument ausgegeben.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT benötigt ein Argument von 0 oder größer, und dieses wurde als $argument ausgegeben.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'Die Berechnung ergab keine brauchbare Zahl, daher gibt es keinen Wert, der angezeigt werden könnte.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'Die Formel bezieht sich auf das Byte $letter, die Antwort enthielt jedoch nur $count Bytes.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '„BARO“ lässt sich hier nicht verwenden, weil nicht bekannt ist, welches Steuergerät mit dem Umgebungsdruck gemeint ist.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Da beide Definitionen den Umgebungsdruck angeben, könnte der Wert bei beiden „eins“ sein, sodass keine der beiden verwendet werden kann. Entfernen Sie eines der Messgeräte, das den Umgebungsdruck misst.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'Der Umgebungsdruck wurde noch nicht erfasst, daher kann dieser Wert nicht berechnet werden.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'Der gemessene Umgebungsdruck ist veraltet, sodass dieser Wert nicht berechnet werden kann.';

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '„$reference“ lässt sich hier nicht auflösen, weil nicht bekannt ist, zu welchem Steuergerät diese PID gehört.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Zwei Definitionen interpretieren beide „$key“ auf dieselbe Weise, sodass der Wert beides sein könnte und keine der beiden verwendet werden kann. Ändern Sie eine der beiden Definitionen in einen anderen Mode + PID. Hinweis: Die für die Schätzungen benötigten PIDs (010B, 010C, 010D) werden stets ausgelesen; das Entfernen einer Anzeige aus dem Armaturenbrett führt daher nicht zu deren Unterbrechung.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Für $key wurde noch kein verwertbarer Wert ausgelesen.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Diese Formel kann nicht ausgewertet werden, und dem Editor liegt hierfür kein genauerer Grund vor.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'Ungültiger Modus+PID: Es sind ausschließlich hexadezimale Zeichen in ganzen Byte-Paaren zulässig.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'Der Dienst $service ist keine reine Leseabfrage und darf nicht immer wieder an das Fahrzeug gesendet werden. Zulässig sind nur $services – aktuelle Daten, Freeze-Frame, Fahrzeuginformationen und ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Eine Freeze-Frame-Abfrage benötigt zwei Bytes: die PID und die Frame-Nummer – zum Beispiel 020500 (PID 05, Frame 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier benötigt eine zwei Byte lange Kennung – zum Beispiel 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Eine $service Abfrage an einen Dienst erfordert eine $bytes Byte-Kennung.';
  }

  @override
  String get pidRejectionNameRequired => 'Geben Sie einen Namen ein.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '„$text“ ist kein gültiger Header: 3 Ziffern für 11-Bit-CAN, 6 für die älteren Protokolle, 8 für 29-Bit-CAN.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Geben Sie beide Endpunkte des Messbereichs an.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'Die Untergrenze „$text“ ist keine gültige Zahl.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'Die Obergrenze „$text“ ist keine gültige Zahl.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'Die untere Grenze muss eine endliche Zahl sein.';

  @override
  String get pidRejectionMaxNotFinite =>
      'Die Obergrenze muss eine endliche Zahl sein.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'Der Redline-Anfang „$text“ ist keine gültige Zahl.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'Der Startpunkt der Redline muss eine endliche Zahl sein.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'Die Obergrenze muss größer sein als die Untergrenze.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Diese Datei konnte nicht als CSV gelesen werden: $detail';
  }

  @override
  String get pidImportNoRows => 'Die Datei enthält keine Zeilen.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'In der Kopfzeile wird dieselbe Spalte zweimal benannt: $columns. Da sich nicht feststellen lässt, welche Bezeichnung verwendet werden soll, korrigieren Sie bitte zunächst die Datei.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'In der Kopfzeile fehlen erforderliche Spalten: $columns und $required sind alle erforderlich.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Zeile $line: zu wenige Zellen – Name, Kurzname, PID und Formel sind das Minimum.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Zeile $line: „$text“ ist kein gültiger Modus+PID (nur hexadezimale Zeichen, in ganzen Byte-Paaren).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Zeile $line Die Formelzelle ist leer.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Zeile $line: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Zeile $line Da der Messbereich leer war, wurde $min–$max angewendet. Bitte überprüfen Sie, ob diese Skalierung für diesen Sensor geeignet ist.';
  }

  @override
  String get pidImportNothingImportable =>
      'Die Datei enthält Zeilen, aber keine davon ist eine PID-Definition.';

  @override
  String get dtcCategoryNoAnswer =>
      'Diese Kategorie hat nicht geantwortet. Bitte erneut scannen.';

  @override
  String get dtcCategoryError =>
      'Diese Kategorie konnte nicht gelesen werden. Der vollständige Fehler ist im Protokoll vermerkt.';

  @override
  String get dtcCategoryDisconnected =>
      'Die Verbindung wurde unterbrochen, während diese Kategorie gelesen wurde.';

  @override
  String get dtcCategoryPending =>
      'Ein Steuergerät hat die Anfrage erhalten und bearbeitet sie derzeit noch. Bitte warten Sie und versuchen Sie es dann erneut – dies ist keine Ablehnung.';

  @override
  String get dtcCategoryUnattributed =>
      'Es kamen Codes zurück, aber die Antwort-Header waren aus, deshalb ist nicht bekannt, welche Steuergeräte geantwortet haben. Behandeln Sie das als unvollständig.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '$count Steuergerät(e) haben diese Abfrage nicht beantwortet ($controllers). Die Antworten, die kamen, sind gültig, dies ist aber kein Ergebnis für das ganze Fahrzeug.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return 'Die $count Antwort(en) konnten keinem Steuergerät ($addresses) zugeordnet werden. Die ausgelesenen Codes sind weiterhin gültig, dies kann jedoch nicht als Ergebnis für das gesamte Fahrzeug gewertet werden. Führen Sie den Scan erneut durch.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '$count Steuergerät(e) arbeiten noch an dieser Anfrage ($answered haben bereits geantwortet). Das Ergebnis ist unvollständig. Bitte warten und erneut scannen.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '$refused Steuergerät(e) haben die Anfrage abgelehnt ($answered hat geantwortet). Dieser Scan kann nicht das gesamte Fahrzeug erfassen.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return 'Die Antwort(en) von $count konnten nicht gelesen werden ($answered hat geantwortet). Der Rest ist weiterhin gültig, doch dieser Scan ist unvollständig.';
  }

  @override
  String get connectPairedListFailed =>
      'Die Liste des gekoppelten Bluetooth konnte nicht gelesen werden. Bitte überprüfen Sie, ob Bluetooth eingeschaltet ist, und versuchen Sie es dann erneut.';

  @override
  String get connectBleScanUnavailable =>
      'Bluetooth ist derzeit nicht verfügbar. Bitte warten Sie einen Moment und versuchen Sie es dann erneut.';

  @override
  String get connectBleScanBluez =>
      'Es wurde kein verwendbarer BlueZ/D-Bus-Bluetooth-Dienst gefunden. Installieren und starten Sie den Bluetooth-Dienst und versuchen Sie es anschließend erneut.';

  @override
  String get connectBleScanUnclassified =>
      'Die Suche nach „BLE“ ist fehlgeschlagen.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller hat das Löschen abgelehnt, da der Fahrzeugzustand dies nicht zulässt. Die meisten Steuergeräte lassen ein Löschen bei laufendem Motor nicht zu. Schalten Sie die Zündung bei ausgeschaltetem Motor ein und versuchen Sie es dann erneut.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller unterstützt die Funktion „Mode 04 clear“ nicht. Möglicherweise sind Geräte des Herstellers oder Händlers erforderlich.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller ist gerade beschäftigt. Bitte warten Sie und versuchen Sie es später erneut.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller erfordert einen Sicherheitszugang, bevor die Anzeige gelöscht werden kann. Hierfür ist eine Ausrüstung des Herstellers oder Händlers erforderlich.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller hat den Löschvorgang abgelehnt (Fehlercode $code). Bitte warten Sie und versuchen Sie es anschließend erneut.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '$count Steuergerät(e) haben nicht auf den Löschbefehl geantwortet ($controllers). Die Steuergeräte, die geantwortet haben, sind gelöscht; die anderen können noch Fehlercodes enthalten. Führen Sie einen erneuten Scan durch. Senden Sie keinen weiteren Löschbefehl.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return 'Die $count Antwort(en) dieses Scans konnten nicht zugeordnet werden ($addresses), daher ist nicht bekannt, welche Steuerungen ein Löschbefehl erreichen würde. Führen Sie den Scan erneut durch; sollte diese Adresse nicht erneut erscheinen, stellen Sie die Verbindung erneut her, bevor Sie es erneut versuchen.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return 'Die $count Antwort(en) auf den Löschbefehl konnten nicht zugeordnet werden ($addresses). Senden Sie keinen weiteren Löschbefehl. Führen Sie einen erneuten Scan durch, um festzustellen, welche Fehlercodes noch vorhanden sind.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller hat das Löschen abgelehnt, da der Fahrzeugzustand dies nicht zulässt. Die meisten Steuergeräte führen bei laufendem Motor kein Löschen durch. Schalten Sie die Zündung bei ausgeschaltetem Motor ein und führen Sie anschließend einen erneuten Scan durch, um festzustellen, welche Fehlercodes noch vorhanden sind. Senden Sie keinen weiteren globalen Löschbefehl – ein zweiter Befehl kann die Emissionsbereitschaft eines Steuergeräts zurücksetzen, bei dem der Löschvorgang möglicherweise bereits abgeschlossen wurde.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller unterstützt das Löschen von Mode 04 nicht. Möglicherweise sind Geräte des Herstellers oder des Händlers erforderlich. Senden Sie kein weiteres globales Löschen – ein zweites Löschen kann den Emissionsbereitschaftsstatus eines Steuergeräts zurücksetzen, bei dem die Fehlercodes möglicherweise bereits gelöscht wurden. Führen Sie einen erneuten Scan durch, um festzustellen, welche Fehlercodes noch vorhanden sind.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller ist beschäftigt. Senden Sie keinen weiteren globalen Löschbefehl – ein zweiter Befehl kann die Emissionsbereitschaft eines Steuergeräts zurücksetzen, das möglicherweise bereits gelöscht wurde. Führen Sie einen erneuten Scan durch, um festzustellen, welche Fehlercodes noch vorhanden sind.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller erfordert einen Sicherheitszugriff, bevor der Löschvorgang durchgeführt werden kann. Hierfür ist eine Ausrüstung des Herstellers oder Händlers erforderlich. Senden Sie keinen weiteren globalen Löschbefehl – ein zweiter Befehl kann die Emissionsbereitschaft eines Steuergeräts zurücksetzen, bei dem der Löschvorgang möglicherweise bereits abgeschlossen ist.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller hat das Löschen abgelehnt (Fehlercode $code). Senden Sie kein weiteres globales Löschen – ein zweites Löschen kann die Emissionsbereitschaft eines Steuergeräts zurücksetzen, das möglicherweise bereits gelöscht wurde. Führen Sie einen erneuten Scan durch, um festzustellen, welche Fehlercodes noch vorhanden sind.';
  }

  @override
  String get sharePolicyDenied =>
      'Der aktuelle Verbindungs- oder Betriebszustand lässt keinen Export zu.';

  @override
  String get shareSafetyChanged =>
      'Der Status hat sich während der Vorbereitung des Exports geändert, sodass die Freigabe nicht erfolgt ist.';

  @override
  String get shareSizeLimit =>
      'Der Export überschreitet die Grenze von 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Eine zuvor freigegebene Datei befindet sich noch in der Aufbewahrungsfrist. Bitte versuchen Sie es später erneut.';

  @override
  String get shareCleanupRequired =>
      'Der Share-Staging-Bereich muss nach einem Neustart überprüft werden.';

  @override
  String get shareSpaceUnknown =>
      'Der für die Freigabedatei benötigte freie Speicherplatz konnte nicht bestätigt werden.';

  @override
  String get shareNoSpace =>
      'Es ist nicht genügend Speicherplatz vorhanden, um die Freigabedatei vorzubereiten.';

  @override
  String get shareHandoffFailed =>
      'Die Datei ist bereit, aber das System-Freigabefenster konnte nicht geöffnet werden.';

  @override
  String get shareStorageFailure =>
      'Bei der Vorbereitung oder Aufzeichnung der Freigabe ist ein Speicherfehler aufgetreten.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Lokaler OBD-Datensatz $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale-Transportprotokoll $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Telltale-Transportprotokoll (letzte Verbindung)';

  @override
  String get sharePidCsvSubject =>
      'Benutzerdefinierte PID-Definitionen für Telltale';

  @override
  String get shareTorqueSubsetCsvSubject =>
      'Torque-kompatible PID-Definitionen';

  @override
  String get shareHumanReportCsvSubject =>
      'Menschenlesbarer PID-Bericht für Telltale';

  @override
  String get transcriptExportUnidentified => 'Der Export ist fehlgeschlagen.';

  @override
  String get handshakeNoteUnexpected =>
      'Dieser Schritt ist mit einem unerwarteten Fehler fehlgeschlagen. Der vollständige Fehlertext wird im Protokoll festgehalten.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term ist eine Torque-Funktion, die in diesem Dialekt nicht implementiert ist, sodass die Formel hier nicht ausgewertet werden kann.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Zeile $line: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Kehren Sie zu Telltale zurück, bevor Sie fortfahren.';

  @override
  String get telemetrySessionPolicyChanged =>
      'Der Betriebs- oder Verbindungsstatus hat sich während dieses Vorgangs geändert.';

  @override
  String get telemetrySessionInvalidId =>
      'Diese Aufzeichnungs-ID ist ungültig.';

  @override
  String get telemetrySessionNotFound =>
      'Dieser lokale Datensatz wurde nicht gefunden.';

  @override
  String get telemetrySessionStorageFailed =>
      'Ein lokaler Speichervorgang ist fehlgeschlagen.';

  @override
  String get telemetrySessionShareFailed =>
      'Die Freigabe konnte nicht vorbereitet oder geöffnet werden.';

  @override
  String get pidMutationPersistFailed =>
      'Die Liste der benutzerdefinierten PIDs konnte nicht gespeichert werden. Es wurden keine Änderungen vorgenommen.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'Das Modelljahr liegt außerhalb des für dieses Profil dokumentierten Jahresbereichs.';

  @override
  String get connectionLayerTransport => 'Verbindungsweg';

  @override
  String get connectionLayerProtocol => 'Protokoll';

  @override
  String get connectionLayerEcu => 'Steuergerät-Antworten';

  @override
  String get connectionLayerEvidence => 'Nachweis';

  @override
  String get connectionLayerUnknown => 'Unbekannt';

  @override
  String get connectionLayerNotObserved => 'Nicht beobachtet';

  @override
  String get connectionLayerObserved => 'Beobachtet';

  @override
  String get connectionLayerAnswered => 'Beantwortet';

  @override
  String get connectionLayerSoftware => 'Programm';

  @override
  String get connectionLayerDemo => 'Simulator';

  @override
  String get connectionLayerBle => 'Bluetooth Low Energy';

  @override
  String get connectionLayerClassic => 'klassisches Bluetooth';

  @override
  String get connectionLayerWifi => 'WLAN';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return 'angefordert $requested, gemessen $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-Baud und Fast nicht unterscheidbar';
}
