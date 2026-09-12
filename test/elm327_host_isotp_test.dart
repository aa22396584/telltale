/// Host-visible `ATCAF0` ISO-TP: apply, restore, and bounded reassembly.
///
/// Fixtures are hand-typed ELM lines. The fake is the wire oracle. This is
/// not a copy of a SocketCAN / vcan suite.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_host_isotp.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/fake_elm327.dart';

/// Datasheet VIN example as ATH0 + ATCAF0 PCI lines (no `N:` prefix).
const _vinCaf0Lines = [
  '10 14 49 02 01 31 44 34',
  '21 47 50 30 30 52 35 35',
  '22 42 31 32 33 34 35 36',
];

/// Same VIN with 11-bit headers on.
const _vinHeadered7e8 = [
  '7E8 10 14 49 02 01 31 44 34',
  '7E8 21 47 50 30 30 52 35 35',
  '7E8 22 42 31 32 33 34 35 36',
];

Map<String, List<int>> _physicsReplies() => {
      '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      '0105': [0x41, 0x05, 0x7B],
      '010C': [0x41, 0x0C, 0x1A, 0xF8],
    };

FakeElm327 _can({
  AdapterFaults faults = const AdapterFaults(),
  Map<String, List<String>> literals = const {},
}) =>
    FakeElm327(
      protocol: BusProtocol.can11,
      faults: faults,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
          literalResponses: literals,
        ),
      ],
    );

Future<Elm327Client> _connect(
  FakeElm327 transport, {
  Duration commandTimeout = const Duration(milliseconds: 200),
}) async {
  final client = Elm327Client(transport, commandTimeout: commandTimeout);
  expect(
    await client.connect(),
    isTrue,
    reason: 'handshake must succeed before the case under test',
  );
  return client;
}

void main() {
  test('a fresh client can apply host-visible ISO-TP and starts auto-format',
      () {
    final client = Elm327Client(_can());
    expect(client.supportsHostVisibleIsoTp, isTrue);
    expect(client.hostVisibleIsoTp, isFalse);
    expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
    expect(client.supportsExtendedAddressing, isTrue);
    expect(client.supportsCanPriority, isTrue);
    expect(client.supportsCanReceiveFilter, isTrue);
  });

  test(
    'ordinary CAN polling does not send ATCAF0, ATCFC0 or ATCRA',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      final rpm = await client.send('010C');
      final coolant = await client.send('0105');
      expect(rpm.isSuccess, isTrue);
      expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
      expect(coolant.isSuccess, isTrue);
      expect(coolant.bytes, [0x41, 0x05, 0x7B]);
      expect(transport.commandLog, isNot(contains('ATCAF0')));
      expect(transport.commandLog, isNot(contains('ATCAF1')));
      expect(transport.commandLog, isNot(contains('ATCFC0')));
      expect(transport.commandLog, isNot(contains('ATCRA')));
      expect(transport.autoFormatMode, 1);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('ATCAF0 is accepted and ATCAF1 restores auto-format', () async {
    final transport = _can();
    final client = await _connect(transport);
    final applied = await client.applyHostVisibleIsoTp();
    expect(applied.result, ElmHostIsoTpResult.applied);
    expect(applied.producedMeasurement, isTrue);
    expect(applied.refusalIssue, isNull);
    expect(applied.hostVisible, isTrue);
    expect(client.hostVisibleIsoTp, isTrue);
    expect(transport.autoFormatMode, 0);
    expect(transport.commandLog, contains('ATCAF0'));
    final rpm = await client.send('010C');
    expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    expect(transport.commandLog, contains('02010C'));
    expect(transport.commandLog, isNot(contains('010C')));

    final restored = await client.restoreHostVisibleIsoTp();
    expect(restored.result, ElmHostIsoTpResult.restored);
    expect(restored.hostVisible, isFalse);
    expect(client.hostVisibleIsoTp, isFalse);
    expect(transport.autoFormatMode, 1);
    expect(transport.commandLog, contains('ATCAF1'));
    final coolant = await client.send('0105');
    expect(coolant.bytes, [0x41, 0x05, 0x7B]);
    expect(transport.commandLog, contains('0105'));
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('rejected ATCAF0 is rawIsoTpModeUnavailable with zero decoded value',
      () async {
    final transport = _can(faults: const AdapterFaults(refuseCaf: true));
    final client = await _connect(transport);
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.rejectedUnknownCommand);
    expect(outcome.producedMeasurement, isFalse);
    expect(outcome.refusalIssue, TransportIssue.rawIsoTpModeUnavailable);
    expect(outcome.hostVisible, isFalse);
    expect(client.hostVisibleIsoTp, isFalse);
    expect(transport.autoFormatMode, 1);
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('unknown ATCAF0 reply is the same named unavailable refusal', () async {
    final transport = _can();
    final client = await _connect(transport);
    transport.forceReply('ATCAF0', 'ERR');
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.rejectedUnknownCommand);
    expect(outcome.producedMeasurement, isFalse);
    expect(outcome.refusalIssue, TransportIssue.rawIsoTpModeUnavailable);
    expect(client.hostVisibleIsoTp, isFalse);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('single-frame 010C under ATCAF0 strips PCI and yields the PID',
      () async {
    final transport = _can(
      literals: {
        '010C': ['04 41 0C 1A F8 00 00 00'],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    expect(rpm.errorCode, Elm327ErrorCode.none);
    expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    expect(rpm.bytes, isNot(contains(0x04)));
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('headerless multi-frame under ATCAF0 is unavailable without ATH1',
      () async {
    final transport = _can(literals: {'0902': _vinCaf0Lines});
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('headered ATCAF0 VIN is attributed to 7E8', () async {
    final transport = _can(literals: {'0902': _vinHeadered7e8});
    final client = await _connect(transport);
    expect((await client.send('ATH1')).isSuccess, isTrue);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.isSuccess, isTrue);
    expect(vin.frames.single.sourceId, '7E8');
    expect(String.fromCharCodes(vin.bytes.skip(3)), '1D4GP00R55B123456');
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('wrong PCI is dataError with empty bytes', () async {
    final transport = _can(
      literals: {
        '010C': ['50 41 0C 1A F8 00 00 00'],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isFalse);
    expect(rpm.errorCode, Elm327ErrorCode.dataError);
    expect(rpm.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('First Frame length that fits a Single Frame is unavailable', () async {
    final transport = _can(
      literals: {
        '010C': ['10 04 41 0C 1A F8 00 00'],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final rpm = await client.send('010C');
    expect(rpm.errorCode, Elm327ErrorCode.dataError);
    expect(rpm.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('missing Consecutive Frame is unavailable, not a short VIN', () async {
    final transport = _can(
      literals: {
        '0902': [
          '10 14 49 02 01 31 44 34',
          '21 47 50 30 30 52 35 35',
        ],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    expect(vin.hexPayload, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('duplicate Consecutive Frame is unavailable', () async {
    final transport = _can(
      literals: {
        '0902': [
          '10 14 49 02 01 31 44 34',
          '21 47 50 30 30 52 35 35',
          '21 47 50 30 30 52 35 35',
          '22 42 31 32 33 34 35 36',
        ],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('out-of-order Consecutive Frame is unavailable', () async {
    final transport = _can(
      literals: {
        '0902': [
          '10 14 49 02 01 31 44 34',
          '22 42 31 32 33 34 35 36',
          '21 47 50 30 30 52 35 35',
        ],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('Flow Control WAIT is unavailable', () async {
    final transport = _can(
      literals: {
        '0902': ['31 01 00'],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('Flow Control overflow is unavailable', () async {
    final transport = _can(
      literals: {
        '0902': ['32 00 00'],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('wrong-source Consecutive Frame does not yield a mixed PDU', () async {
    final transport = _can(
      literals: {
        '0902': [
          '7E8 10 14 49 02 01 31 44 34',
          '7E9 21 47 50 30 30 52 35 35',
          '7E8 22 42 31 32 33 34 35 36',
        ],
      },
    );
    final client = await _connect(transport);
    expect((await client.send('ATH1')).isSuccess, isTrue);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('mixed 11/29-bit identifiers are unavailable', () async {
    final transport = _can(
      literals: {
        '0902': [
          '7E8 10 14 49 02 01 31 44 34',
          '18DAF110 21 47 50 30 30 52 35 35',
          '7E8 22 42 31 32 33 34 35 36',
        ],
      },
    );
    final client = await _connect(transport);
    expect((await client.send('ATH1')).isSuccess, isTrue);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('CAF1-shaped N: envelope under ATCAF0 is unavailable', () async {
    final transport = _can(
      literals: {
        '0902': [
          '014',
          '0: 49 02 01 31 44 34',
          '1: 47 50 30 30 52 35 35',
          '2: 42 31 32 33 34 35 36',
        ],
      },
    );
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final vin = await client.send('0902');
    expect(vin.errorCode, Elm327ErrorCode.dataError);
    expect(vin.bytes, isEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('incomplete reassembly that times out yields no payload', () async {
    final transport = _can();
    final client = await _connect(
      transport,
      commandTimeout: const Duration(milliseconds: 80),
    );
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    transport.goSilent = true;
    await expectLater(client.send('0902'), throwsA(isA<TimeoutException>()));
    transport.goSilent = false;
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('disconnect during ATCAF0 is disconnected with auto-format unclaimed',
      () async {
    final transport = _can();
    final client = await _connect(transport);
    transport.dropLinkAfterWritingFor = {'ATCAF0'};
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.disconnected);
    expect(outcome.hostVisible, isFalse);
    expect(outcome.producedMeasurement, isFalse);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('disconnect during reassembly does not publish a short PDU', () async {
    final transport = _can(literals: {'0902': _vinCaf0Lines});
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    transport.dropLinkAfterWritingFor = {'020902'};
    await expectLater(
      client.send('0902'),
      throwsA(anyOf(isA<TimeoutException>(), isA<TransportException>())),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCAF1 restore failure sticks and later send is unavailable', () async {
    final transport = _can(faults: const AdapterFaults(refuseCafRestore: true));
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    final restored = await client.restoreHostVisibleIsoTp();
    expect(restored.result, ElmHostIsoTpResult.restoreFailed);
    expect(restored.producedMeasurement, isFalse);
    expect(restored.refusalIssue, TransportIssue.rawIsoTpModeUnavailable);
    expect(client.hostVisibleIsoTpRestoreFailed, isTrue);
    await expectLater(
      client.send('010C'),
      throwsA(
        isA<TransportException>().having(
          (e) => e.issue,
          'issue',
          TransportIssue.rawIsoTpModeUnavailable,
        ),
      ),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('retired apply never writes ATCAF0', () async {
    final transport = _can();
    final client = await _connect(transport);
    client.mayTransmit = (_) => false;
    await expectLater(
      client.applyHostVisibleIsoTp(owner: 'retired'),
      throwsA(isA<OperationRetiredException>()),
    );
    expect(transport.commandLog, isNot(contains('ATCAF0')));
    expect(client.hostVisibleIsoTp, isFalse);
    client.mayTransmit = null;
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a new client after reconnect does not inherit ATCAF0', () async {
    final firstTransport = _can();
    final first = await _connect(firstTransport);
    expect(
      (await first.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    expect(first.hostVisibleIsoTp, isTrue);
    await first.disconnect();

    final secondTransport = _can();
    final second = await _connect(secondTransport);
    expect(second.hostVisibleIsoTp, isFalse);
    expect(secondTransport.autoFormatMode, 1);
    expect(secondTransport.commandLog, isNot(contains('ATCAF0')));
    final rpm = await second.send('010C');
    expect(rpm.isSuccess, isTrue);
    await second.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCAF0 timeout after the write is timedOut, not restored', () async {
    final transport = _can();
    final client = await _connect(
      transport,
      commandTimeout: const Duration(milliseconds: 80),
    );
    transport.slowCommands['ATCAF0'] = const Duration(seconds: 3);
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.timedOut);
    expect(outcome.producedMeasurement, isFalse);
    expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
    expect(transport.commandLog, contains('ATCAF1'));
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('redundant ATCAF1 native write error does not sticky-fail later polling',
      () async {
    final transport = _can();
    final client = await _connect(transport);
    transport.failWriteAfterAcceptingWithNativeErrorFor = {'ATCAF1'};
    expect(client.hostVisibleIsoTp, isFalse);
    final outcome = await client.restoreHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.unconfirmedWrite);
    expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
    expect(client.hostVisibleIsoTp, isFalse);
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('redundant ATCAF1 timeout does not sticky-fail later polling', () async {
    final transport = _can();
    final client = await _connect(
      transport,
      commandTimeout: const Duration(milliseconds: 80),
    );
    transport.slowCommands['ATCAF1'] = const Duration(seconds: 3);
    expect(client.hostVisibleIsoTp, isFalse);
    final outcome = await client.restoreHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.timedOut);
    expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test(
    'redundant ATCAF1 over-budget reply does not sticky-fail later polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(client.hostVisibleIsoTp, isFalse);
      transport.forceReply('ATCAF1', 'OK\r${'Z' * 260}');
      final outcome = await client.restoreHostVisibleIsoTp();
      expect(outcome.result, ElmHostIsoTpResult.budgetExceeded);
      expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
      expect(client.hostVisibleIsoTp, isFalse);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'resync budget miss while CAF0 is active is budgetExceeded, not sticky',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      expect(
        (await client.applyHostVisibleIsoTp()).result,
        ElmHostIsoTpResult.applied,
      );
      transport.slowCommands['02010C'] = const Duration(milliseconds: 400);
      await expectLater(
        client.send('010C'),
        throwsA(isA<TimeoutException>()),
      );
      const budget = Duration(milliseconds: 40);
      final reapply = client.applyHostVisibleIsoTp(budget: budget);
      await Future<void>.delayed(budget);
      transport.emitBytes(const [0x4F, 0x4B, 0x0D, 0x3E]);
      final outcome = await reapply;
      expect(outcome.result, ElmHostIsoTpResult.budgetExceeded);
      expect(outcome.hostVisible, isTrue);
      expect(client.hostVisibleIsoTp, isTrue);
      expect(client.hostVisibleIsoTpRestoreFailed, isFalse);
      expect(
        transport.commandLog.where((c) => c == 'ATCAF0').length,
        1,
      );
      final coolant = await client.send('0105');
      expect(coolant.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('DemoTransport refuses ATCAF0 so apply cannot break demo polling',
      () async {
    final transport = DemoTransport(responseLatency: Duration.zero);
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(seconds: 2),
    );
    expect(await client.connect(), isTrue);
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.rejectedUnknownCommand);
    expect(outcome.producedMeasurement, isFalse);
    expect(outcome.refusalIssue, TransportIssue.rawIsoTpModeUnavailable);
    expect(client.hostVisibleIsoTp, isFalse);
    final rpm = await client.send('010C');
    expect(rpm.isSuccess, isTrue);
    expect(rpm.bytes, isNotEmpty);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCAF0 on ISO 9141 is rawIsoTpModeUnavailable and writes nothing',
      () async {
    final transport = FakeElm327(
      protocol: BusProtocol.iso9141,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '6C10F1',
          responseId: '486B10',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
          },
        ),
      ],
    );
    final client = await _connect(transport);
    expect(client.addressing.isCan, isFalse);
    final outcome = await client.applyHostVisibleIsoTp();
    expect(outcome.result, ElmHostIsoTpResult.rejectedUnknownCommand);
    expect(outcome.producedMeasurement, isFalse);
    expect(outcome.refusalIssue, TransportIssue.rawIsoTpModeUnavailable);
    expect(transport.commandLog, isNot(contains('ATCAF0')));
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATZ after ATCAF0 restores auto-format on a live client', () async {
    final transport = _can();
    final client = await _connect(transport);
    expect(
      (await client.applyHostVisibleIsoTp()).result,
      ElmHostIsoTpResult.applied,
    );
    await client.send('ATZ');
    expect(client.hostVisibleIsoTp, isFalse);
    expect(transport.autoFormatMode, 1);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
