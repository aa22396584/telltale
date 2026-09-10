/// Observed Mode 01 grouping, not scheduler permission.
///
/// `TelemetrySnapshot.fastModeEnabled` is true from construction. The pill
/// used to have no other number, so "Batching enabled" was the strongest
/// claim the UI could make. #94.B needs a record of the last Mode 01 command
/// that actually went on the wire: how many PIDs it packed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import 'support/fake_elm327.dart';

Map<String, List<int>> _physicsReplies() => {
  '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
  '0120': [0x41, 0x20, 0x80, 0x00, 0x00, 0x01],
  '0140': [0x41, 0x40, 0x40, 0x00, 0x00, 0x00],
  '010C': [0x41, 0x0C, 0x1A, 0xF8],
  '010D': [0x41, 0x0D, 0x3C],
  '0110': [0x41, 0x10, 0x0A, 0xF0],
  '010B': [0x41, 0x0B, 0x64],
  '010F': [0x41, 0x0F, 0x50],
  '015E': [0x41, 0x5E, 0x0B, 0xB8],
};

Future<PollingEngine> _connect(FakeElm327 transport) async {
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 200),
    responsePendingTimeout: const Duration(milliseconds: 280),
  );
  expect(await client.connect(), isTrue);
  return PollingEngine(client);
}

void main() {
  test('010C is one PID; 010C0D is two; Mode 09 is not Mode 01', () {
    expect(mode01PidCountOnWire('010C'), 1);
    expect(mode01PidCountOnWire('01 0C 0D'), 2);
    expect(mode01PidCountOnWire('010C0D05'), 3);
    expect(mode01PidCountOnWire('0902'), isNull);
    expect(mode01PidCountOnWire('03'), isNull);
    expect(mode01PidCountOnWire(''), isNull);
    expect(mode01PidCountOnWire('ATZ'), isNull);
  });

  test('a CAN session that sends a grouped Mode 01 command records the count', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverSupportedPids();
    engine.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
    expect(
      engine.current.lastMode01PidCount,
      isNull,
      reason: 'nothing Mode 01 has been polled yet',
    );
    engine.start();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await engine.stop();

    final batched = transport.commandLog
        .where((c) => c.toUpperCase().startsWith('01') && c.length > 4)
        .where((c) => c != '0100' && c != '0120' && c != '0140')
        .toList();
    expect(
      batched,
      isNotEmpty,
      reason:
          'this fixture must actually group Mode 01 PIDs. '
          'Commands: ${transport.commandLog}',
    );
    expect(
      engine.current.lastMode01PidCount,
      greaterThanOrEqualTo(2),
      reason:
          'the snapshot must keep the grouped Mode 01 packing even if a '
          'later singleton was the last command. Commands: ${transport.commandLog}',
    );
    await engine.dispose();
  });

  test('ISO 9141 never records a grouped Mode 01 command', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.iso9141,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverSupportedPids();
    engine.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
    engine.start();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await engine.stop();

    final count = engine.current.lastMode01PidCount;
    expect(
      count,
      anyOf(isNull, equals(1)),
      reason:
          'a non-CAN bus cannot pack Mode 01 PIDs. '
          'count=$count commands=${transport.commandLog}',
    );
    expect(
      transport.commandLog.any(
        (c) =>
            c.toUpperCase().startsWith('01') &&
            c.length > 4 &&
            c != '0100' &&
            c != '0120' &&
            c != '0140',
      ),
      isFalse,
      reason:
          'no multi-PID Mode 01 command on ISO 9141. '
          'Commands: ${transport.commandLog}',
    );
    await engine.dispose();
  });

  test('stop then start on the same engine keeps the observation', () async {
    // `_resumeNow` restarts this engine. Clearing the count here is how
    // backgrounding forgot a grouped Mode 01 command that had already gone
    // out on this connection.
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverSupportedPids();
    engine.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
    engine.start();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await engine.stop();
    expect(engine.current.lastMode01PidCount, greaterThanOrEqualTo(2));
    engine.start();
    expect(
      engine.current.lastMode01PidCount,
      greaterThanOrEqualTo(2),
      reason: 'lifecycle resume is not a new connection',
    );
    await engine.stop();
    await engine.dispose();
  });

  test('a new engine does not inherit another connection\'s count', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
        ),
      ],
    );
    final first = await _connect(transport);
    await first.discoverSupportedPids();
    first.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
    first.start();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await first.stop();
    expect(first.current.lastMode01PidCount, greaterThanOrEqualTo(2));
    await first.dispose();

    final second = PollingEngine(
      Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
        responsePendingTimeout: const Duration(milliseconds: 280),
      ),
    );
    expect(
      second.current.lastMode01PidCount,
      isNull,
      reason: 'replacing the engine is a new connection',
    );
    await second.dispose();
  });

  test('a retired send before the PID write does not claim a batch', () async {
    // sendAddressed can throw OperationRetiredException before ATSH or the
    // query. Counting before the client method would let the dashboard say
    // Batched polling for a command that never reached the bus.
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverSupportedPids();
    engine.client.mayTransmit = (_) => false;
    engine.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
    engine.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await engine.stop();
    expect(
      engine.current.lastMode01PidCount,
      isNull,
      reason:
          'nothing Mode 01 was written after discovery. '
          'Commands: ${transport.commandLog}',
    );
    await engine.dispose();
  });

  test(
    'a grouped Mode 01 write whose reply times out is still observed',
    () async {
      // sendAddressed / sendGlobal can throw after the PID query has left.
      // Counting only a parsed success would drop Batched polling for a
      // command that did go on the wire. Discovery 0100/0120/0140 still
      // get a prompt; only grouped Mode 01 commands lose `>`.
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        faults: const AdapterFaults(swallowGroupedMode01: true),
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: _physicsReplies(),
          ),
        ],
      );
      final engine = await _connect(transport);
      await engine.discoverSupportedPids();
      engine.setActivePids([PidLibrary.engineRpm, PidLibrary.vehicleSpeed]);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await engine.stop();

      final batched = transport.commandLog
          .where((c) => c.toUpperCase().startsWith('01') && c.length > 4)
          .where((c) => c != '0100' && c != '0120' && c != '0140')
          .toList();
      expect(
        batched,
        isNotEmpty,
        reason:
            'this fixture must write a grouped Mode 01 command even though '
            'the prompt never arrives. Commands: ${transport.commandLog}',
      );
      expect(
        engine.current.lastMode01PidCount,
        greaterThanOrEqualTo(2),
        reason:
            'a timeout after the PID write is still an observed batch. '
            'Commands: ${transport.commandLog}',
      );
      await engine.dispose();
    },
  );
}
