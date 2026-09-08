/// Import → production parser → live status → record → export/replay.
///
/// #90: a user-authored decoder consuming ECU bytes is not a hand-entered
/// measurement. Constructing a [DatumStatus] directly cannot prove that.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_csv.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/telemetry/session/telemetry_export_codec.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';

import '../support/fake_elm327.dart';

List<int> _mode01Data(ObdResponse response, Pid pid) {
  final code = pid.pidByte;
  expect(code, isNotNull);
  final matching = <List<int>>[];
  for (final frame in response.frames) {
    final data = frame.bytes;
    if (data.length >= 2 && data[0] == 0x41 && data[1] == code) {
      matching.add(data.sublist(2));
    }
  }
  if (matching.isEmpty &&
      response.bytes.length >= 3 &&
      response.bytes[0] == 0x41 &&
      response.bytes[1] == code) {
    matching.add(response.bytes.sublist(2));
  }
  expect(
    matching,
    hasLength(1),
    reason: 'production single Mode 01 custom path needs one 41 <pid> frame',
  );
  return matching.single;
}

void main() {
  test(
    'imported custom decoder of ECU bytes is not a hand-entered measurement',
    () async {
      final imported = PidCsv.parse(
        'Name,ModeAndPID,Equation\r\nUser coolant,0105,A-40\r\n',
      );
      expect(imported.errors, isEmpty);
      final pid = imported.pids.single;
      expect(pid.isCustom, isTrue);
      expect(pid.modeAndPid, '0105');

      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
              '0105': [0x41, 0x05, 0x82],
            },
          ),
        ],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
      );
      expect(await client.connect(), isTrue);

      final response = await client.send('0105');
      expect(response.isSuccess, isTrue);
      expect(response.errorCode, Elm327ErrorCode.none);

      final data = _mode01Data(response, pid);
      expect(data, [0x82]);
      final value = FormulaEngine().evaluateBytes(
        pid.equation,
        data,
        requester: pid,
      );
      expect(value, 90);

      final now = DateTime.utc(2026, 9, 8, 12);
      final reading = Reading(
        pid: pid,
        value: value,
        rawBytes: data,
        timestamp: now,
      );
      final live = AvailabilityPolicy.forPid(pid: pid, reading: reading);
      expect(live.origin, DatumOrigin.ecuReported);
      expect(live.evidence, EvidenceKind.userSupplied);
      expect(live.origin, isNot(DatumOrigin.userEntered));

      final frozen = freezePidDefinition(pid);
      expect(frozen.definition.isCustom, isTrue);
      expect(frozen.definition.evidenceKind, 'userSupplied');

      final events = <TelemetryEvent>[];
      var elapsed = 0;
      final recorder = TelemetryRecorder(
        utcNow: () => now,
        elapsedUs: () => elapsed,
        onEvent: events.add,
      );
      final header = TelemetrySessionHeader(
        sessionId: '0123456789abcdef0123456789abcdef',
        startedAtUtc: now,
        source: TelemetrySource.simulatedRig,
        transport: TransportKind.wifi,
        protocol: 'ISO 15765-4 CAN',
        signals: [frozen],
      );
      expect(recorder.prepare(header), isTrue);
      expect(recorder.openAcceptance(), isTrue);
      elapsed = 1000;
      recorder.ingest(
        TelemetrySnapshot(readings: {pid.id: reading}, capturedAt: now),
      );
      recorder.stop();
      expect(events.where((e) => e.kind == TelemetryEventKind.value), isNotEmpty);

      final prefix = TelemetrySessionCodec.encodePrefix(header, events);
      final footer = recorder.complete(bytesBeforeFooter: prefix.length);
      final session = TelemetrySession(
        header: header,
        events: events,
        footer: footer,
      );

      final csv = TelemetryExportCodec.encodeCsv(session);
      expect(csv, contains('ecuReported'));
      expect(csv, isNot(contains('userEntered')));
      expect(csv, contains('userSupplied'));
      expect(csv, isNot(contains('fieldVerified')));

      final recorded = AvailabilityPolicy.forRecordedEvent(
        definition: frozen.definition,
        event: events.firstWhere((e) => e.kind == TelemetryEventKind.value),
        source: TelemetrySource.simulatedRig,
      );
      expect(recorded.origin, DatumOrigin.ecuReported);
      expect(recorded.evidence, EvidenceKind.userSupplied);

      final replayed = TelemetrySessionCodec.encode(session);
      expect(replayed, isNotEmpty);
      final replayedSession = TelemetrySession(
        header: header,
        events: events,
        footer: footer,
      );
      final replayStatus = AvailabilityPolicy.forRecordedEvent(
        definition: replayedSession.header.signals.single.definition,
        event: replayedSession.events.firstWhere(
          (e) => e.kind == TelemetryEventKind.value,
        ),
        source: replayedSession.header.source,
      );
      expect(replayStatus.origin, DatumOrigin.ecuReported);
      expect(replayStatus.evidence, isNot(EvidenceKind.fieldVerified));
    },
  );
}
