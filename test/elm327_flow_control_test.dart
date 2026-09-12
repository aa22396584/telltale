/// Typed ELM327 custom flow control: apply, restore, and named refusals.
///
/// Every expectation is hand-typed. The fake is the oracle for what left the
/// wire; the client is the production path, not a hand-built exception.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/addressing.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_flow_control.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/settings/manual_command_copy.dart';

import 'support/cjk.dart';
import 'support/fake_elm327.dart';

BusAddressing get _can11 => BusAddressing.forProtocolNumber('6');
BusAddressing get _can29 => BusAddressing.forProtocolNumber('7');

const _fcData = [0x30, 0x00, 0x00, 0x00, 0x00];

ElmFlowControlConfig _sm1({
  String header = '7E0',
  List<int> data = _fcData,
  BusAddressing? addressing,
}) =>
    ElmFlowControlConfig.customHeaderAndData(
      header: header,
      data: data,
      addressing: addressing ?? _can11,
    );

ElmFlowControlConfig _sm2({
  List<int> data = _fcData,
  BusAddressing? addressing,
}) =>
    ElmFlowControlConfig.customDataKeepId(
      data: data,
      addressing: addressing ?? _can11,
    );

Map<String, List<int>> _physicsReplies() => {
      '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      '0105': [0x41, 0x05, 0x7B],
      '010C': [0x41, 0x0C, 0x1A, 0xF8],
    };

FakeElm327 _can({AdapterFaults faults = const AdapterFaults()}) => FakeElm327(
      protocol: BusProtocol.can11,
      faults: faults,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: _physicsReplies(),
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

List<String> _fcCommands(List<String> log) =>
    log.where((c) => c.startsWith('ATFC')).toList();

void main() {
  test('toAtCommands emits the reviewed compact spellings', () {
    expect(
      ElmFlowControlConfig.automatic().toAtCommands(),
      ['ATFCSM0'],
    );
    expect(
      _sm1().toAtCommands(),
      ['ATFCSH7E0', 'ATFCSD3000000000', 'ATFCSM1'],
    );
    expect(
      _sm2().toAtCommands(),
      ['ATFCSD3000000000', 'ATFCSM2'],
    );
    expect(
      _sm1(header: '18DA10F1', addressing: _can29).toAtCommands(),
      ['ATFCSH18DA10F1', 'ATFCSD3000000000', 'ATFCSM1'],
    );
    for (final commands in [
      ElmFlowControlConfig.automatic().toAtCommands(),
      _sm1().toAtCommands(),
      _sm2().toAtCommands(),
    ]) {
      expect(
        commands,
        isNot(anyOf(contains('ATCAF0'), contains('ATCFC0'), contains('ATCRA'))),
      );
    }
  });

  test('invalid config shapes throw', () {
    expect(
      () => ElmFlowControlConfig.customHeaderAndData(
        header: '7E00',
        data: _fcData,
        addressing: _can11,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmFlowControlConfig.customHeaderAndData(
        header: '7E0',
        data: const [1, 2, 3, 4, 5, 6],
        addressing: _can11,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmFlowControlConfig.customHeaderAndData(
        header: '7E0',
        data: _fcData,
        addressing: _can29,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmFlowControlConfig.customHeaderAndData(
        header: '7E0',
        data: const [],
        addressing: _can11,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('a fresh client starts automatic', () {
    final client = Elm327Client(_can());
    expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
    expect(client.supportsExtendedAddressing, isFalse);
    expect(client.supportsHostVisibleIsoTp, isTrue);
  });

  test(
    'apply SM1 then restore walks SH, SD, SM1 and ATFCSM0',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      final applied = await client.applyFlowControl(_sm1());
      expect(applied.result, ElmFlowControlResult.applied);
      expect(applied.producedMeasurement, isTrue);
      expect(applied.state, isA<ElmFlowControlCustom>());
      expect(_fcCommands(transport.commandLog), [
        'ATFCSH7E0',
        'ATFCSD3000000000',
        'ATFCSM1',
      ]);
      expect(transport.flowControlMode, 1);
      expect(transport.flowControlHeader, '7E0');
      expect(transport.flowControlData, _fcData);

      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restored);
      expect(restored.state, isA<ElmFlowControlAutomatic>());
      expect(_fcCommands(transport.commandLog), [
        'ATFCSH7E0',
        'ATFCSD3000000000',
        'ATFCSM1',
        'ATFCSM0',
      ]);
      expect(transport.flowControlMode, 0);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('apply SM2 sends SD then SM2 and no SH', () async {
    final transport = _can();
    final client = await _connect(transport);
    final applied = await client.applyFlowControl(_sm2());
    expect(applied.result, ElmFlowControlResult.applied);
    expect(applied.state, isA<ElmFlowControlCustom>());
    expect(_fcCommands(transport.commandLog), [
      'ATFCSD3000000000',
      'ATFCSM2',
    ]);
    expect(transport.flowControlMode, 2);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test(
    'AT reject on ATFCSH is rejectedUnknownCommand, not custom, restore attempted',
    () async {
      final transport = _can(
        faults: const AdapterFaults(refuseFlowControl: true),
      );
      final client = await _connect(transport);
      final outcome = await client.applyFlowControl(_sm1());
      expect(outcome.result, ElmFlowControlResult.rejectedUnknownCommand);
      expect(outcome.producedMeasurement, isFalse);
      expect(outcome.refusalIssue, TransportIssue.customFlowControlRejected);
      expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
      expect(_fcCommands(transport.commandLog), ['ATFCSH7E0', 'ATFCSM0']);
      expect(transport.flowControlMode, 0);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'reject on ATFCSM1 after SH/SD OK leaves unknown then restores',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      transport.forceReply('ATFCSM1', '?');
      final outcome = await client.applyFlowControl(_sm1());
      expect(outcome.result, ElmFlowControlResult.rejectedUnknownCommand);
      expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
      expect(_fcCommands(transport.commandLog), [
        'ATFCSH7E0',
        'ATFCSD3000000000',
        'ATFCSM1',
        'ATFCSM0',
      ]);
      expect(transport.flowControlMode, 0);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'timeout mid-apply is timedOut, resyncs, and does not claim custom',
    () async {
      final transport = _can(
        faults: const AdapterFaults(delayFlowControlReply: true),
      );
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      final outcome = await client.applyFlowControl(
        _sm1(),
        budget: const Duration(seconds: 4),
      );
      expect(outcome.result, ElmFlowControlResult.timedOut);
      expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
      expect(transport.commandLog, contains('ATFCSH7E0'));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a late over-budget ATFCSM1 reply drained by resync is restoreFailed not timedOut',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      transport.slowCommands['ATFCSM1'] = const Duration(milliseconds: 400);
      transport.forceReply('ATFCSM1', 'OK\r${'Z' * 260}');
      final outcome = await client.applyFlowControl(
        _sm1(),
        budget: const Duration(seconds: 4),
      );
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.commandLog, contains('ATFCSM1'));
      expect(transport.commandLog, isNot(contains('ATFCSM0')));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'ambiguous write after ATFCSM1 restores defaults and does not claim custom',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      transport.failWriteAfterAcceptingFor = {'ATFCSM1'};
      final outcome = await client.applyFlowControl(_sm1());
      expect(outcome.result, ElmFlowControlResult.unconfirmedWrite);
      expect(outcome.producedMeasurement, isFalse);
      expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
      expect(_fcCommands(transport.commandLog), [
        'ATFCSH7E0',
        'ATFCSD3000000000',
        'ATFCSM1',
        'ATFCSM0',
      ]);
      expect(transport.flowControlMode, 0);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'over-budget ATFCSM1 reply before native flush error is restoreFailed not restored',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      transport.failWriteAfterAcceptingWithNativeErrorFor = {'ATFCSM1'};
      transport.forceReply('ATFCSM1', 'OK\r${'Z' * 260}');
      final outcome = await client.applyFlowControl(_sm1());
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.commandLog, contains('ATFCSM1'));
      expect(transport.commandLog, isNot(contains('ATFCSM0')));
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'native flush error mid-apply restores defaults and does not claim custom',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      transport.failWriteAfterAcceptingWithNativeErrorFor = {'ATFCSM1'};
      final outcome = await client.applyFlowControl(_sm1());
      expect(outcome.result, ElmFlowControlResult.unconfirmedWrite);
      expect(outcome.producedMeasurement, isFalse);
      expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
      expect(_fcCommands(transport.commandLog), [
        'ATFCSH7E0',
        'ATFCSD3000000000',
        'ATFCSM1',
        'ATFCSM0',
      ]);
      expect(transport.flowControlMode, 0);
      expect(client.flowControlRestoreFailed, isFalse);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'native flush error on ATFCSM0 still fail-closes polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.failWriteAfterAcceptingWithNativeErrorFor = {'ATFCSM0'};
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(restored.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.isConnected, isTrue);
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      expect(transport.commandLog, isNot(contains('010C')));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('disconnect mid-apply is disconnected with no custom leak', () async {
    final transport = _can(
      faults: const AdapterFaults(dropAfterFlowControlHeader: true),
    );
    final client = await _connect(transport);
    final outcome = await client.applyFlowControl(_sm1());
    expect(outcome.result, ElmFlowControlResult.disconnected);
    expect(outcome.state, isNot(isA<ElmFlowControlCustom>()));
    expect(transport.flowControlMode, 0);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test(
    'restore write refused while connected still fail-closes polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.refuseWriteBeforeAcceptingFor = {'ATFCSM0'};
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(restored.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.isConnected, isTrue);
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      expect(transport.commandLog, isNot(contains('010C')));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'pre-wire restore refusal while automatic does not sticky-fail polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      transport.refuseWriteBeforeAcceptingFor = {'ATFCSM0'};
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreRejected);
      expect(restored.refusalIssue, isNull);
      expect(restored.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      transport.refuseWriteBeforeAcceptingFor = {};
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'restore failure refuses later send with flowControlRestoreFailed',
    () async {
      final transport = _can(
        faults: const AdapterFaults(refuseFlowControlRestore: true),
      );
      final client = await _connect(transport);
      final applied = await client.applyFlowControl(_sm1());
      expect(applied.result, ElmFlowControlResult.applied);
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(restored.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>()
              .having(
                (e) => e.issue,
                'issue',
                TransportIssue.flowControlRestoreFailed,
              )
              .having(
                (e) => e.message,
                'message',
                ElmFlowControlMessages.restoreFailed,
              )
              .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
        ),
      );
      expect(transport.commandLog, isNot(contains('010C')));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'rejected ATFCSM0 while already automatic does not sticky-fail polling',
    () async {
      final transport = _can(
        faults: const AdapterFaults(refuseFlowControlRestore: true),
      );
      final client = await _connect(transport);
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreRejected);
      expect(restored.refusalIssue, isNull);
      expect(restored.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(transport.commandLog, contains('ATFCSM0'));
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'rejected apply automatic while already automatic does not sticky-fail polling',
    () async {
      final transport = _can(
        faults: const AdapterFaults(refuseFlowControlRestore: true),
      );
      final client = await _connect(transport);
      final outcome = await client.applyFlowControl(
        ElmFlowControlConfig.automatic(),
      );
      expect(outcome.result, ElmFlowControlResult.restoreRejected);
      expect(outcome.refusalIssue, isNull);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(transport.commandLog.where((c) => c == 'ATFCSM0').length, 1);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'apply budget starts at enqueue so a slow preceding command refuses without writing ATFC',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(seconds: 2),
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 250);
      final rpm = client.send('010C');
      final apply = client.applyFlowControl(
        _sm1(),
        budget: const Duration(milliseconds: 40),
      );
      await rpm;
      final outcome = await apply;
      expect(outcome.result, ElmFlowControlResult.budgetExceeded);
      expect(outcome.producedMeasurement, isFalse);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(transport.commandLog, contains('010C'));
      expect(_fcCommands(transport.commandLog), isEmpty);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'queued apply automatic that expires while custom is restoreFailed not a silent poll',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(seconds: 2),
      );
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 250);
      final rpm = client.send('010C');
      final apply = client.applyFlowControl(
        ElmFlowControlConfig.automatic(),
        budget: const Duration(milliseconds: 40),
      );
      await rpm;
      final outcome = await apply;
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(outcome.state, isNot(isA<ElmFlowControlAutomatic>()));
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.commandLog.where((c) => c == 'ATFCSM0'), isEmpty);
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'preflight drain over budget while custom is restoreFailed not a silent automatic poll',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 400);
      transport.forceReply('010C', '41 0C 1A F8\r${'Z' * 260}');
      await expectLater(
        client.send('010C'),
        throwsA(isA<TimeoutException>()),
      );
      final outcome = await client.applyFlowControl(
        _sm1(),
        budget: const Duration(seconds: 4),
      );
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(outcome.state, isNot(isA<ElmFlowControlAutomatic>()));
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'ATPC rejected while custom does not sticky-fail polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATPC', '?');
      final refused = await client.send('ATPC');
      expect(refused.errorCode, Elm327ErrorCode.unknownCommand);
      expect(client.flowControlState, isA<ElmFlowControlCustom>());
      expect(client.flowControlRestoreFailed, isFalse);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'rejected ATD while custom does not claim automatic',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATD', '?');
      final refused = await client.send('ATD');
      expect(refused.errorCode, Elm327ErrorCode.unknownCommand);
      expect(client.flowControlState, isA<ElmFlowControlCustom>());
      expect(client.flowControlRestoreFailed, isFalse);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'unsent restore timeout while automatic is budgetExceeded not sticky',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 400);
      await expectLater(
        client.send('010C'),
        throwsA(isA<TimeoutException>()),
      );
      const budget = Duration(milliseconds: 40);
      final restore = client.restoreFlowControl(budget: budget);
      await Future<void>.delayed(budget);
      transport.emitBytes(const [0x4F, 0x4B, 0x0D, 0x3E]);
      final outcome = await restore;
      expect(outcome.result, ElmFlowControlResult.budgetExceeded);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(transport.commandLog, isNot(contains('ATFCSM0')));
      final coolant = await client.send('0105');
      expect(coolant.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'ATPC while custom fail-closes later polling',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATPC', 'OK');
      final closed = await client.send('ATPC');
      expect(closed.rawLines, contains('OK'));
      expect(client.flowControlState, isA<ElmFlowControlUnknown>());
      expect(client.flowControlRestoreFailed, isTrue);
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'pre-wire apply deadline in _sendNow keeps automatic and does not stick',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      var mayTransmitCalls = 0;
      client.mayTransmit = (_) {
        mayTransmitCalls++;
        // First call is the apply entry gate. Second is the loop's
        // recheck; sleeping here expires the budget after that check
        // and before `_sendNow` reaches `transport.write`.
        if (mayTransmitCalls == 2) {
          final until = DateTime.now().add(const Duration(milliseconds: 50));
          while (DateTime.now().isBefore(until)) {}
        }
        return true;
      };
      final outcome = await client.applyFlowControl(
        _sm1(),
        budget: const Duration(milliseconds: 30),
      );
      expect(outcome.result, ElmFlowControlResult.budgetExceeded);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(_fcCommands(transport.commandLog), isEmpty);
      client.mayTransmit = null;
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'apply resync that returns after the budget keeps automatic and does not stick',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 400);
      await expectLater(
        client.send('010C'),
        throwsA(isA<TimeoutException>()),
      );
      // Late 010C prompt is still ~320 ms out. Apply's preflight drain
      // is clamped to this 40 ms budget: either the prompt lands on the
      // last tick and `_resync` returns after the deadline, or the
      // drain times out. Neither path may write ATFC* or stick.
      const budget = Duration(milliseconds: 40);
      final apply = client.applyFlowControl(_sm1(), budget: budget);
      await Future<void>.delayed(budget);
      transport.emitBytes(const [0x4F, 0x4B, 0x0D, 0x3E]);
      final outcome = await apply;
      expect(outcome.result, ElmFlowControlResult.budgetExceeded);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(_fcCommands(transport.commandLog), isEmpty);
      final coolant = await client.send('0105');
      expect(coolant.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'restore resync that expires while automatic is budgetExceeded not sticky',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 80),
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 400);
      await expectLater(
        client.send('010C'),
        throwsA(isA<TimeoutException>()),
      );
      final restored = await client.restoreFlowControl(
        budget: const Duration(milliseconds: 40),
      );
      expect(restored.result, ElmFlowControlResult.budgetExceeded);
      expect(restored.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      final coolant = await client.send('0105');
      expect(coolant.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'queued restore that expires before writing keeps automatic and does not stick',
    () async {
      final transport = _can();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(seconds: 2),
      );
      transport.slowCommands['010C'] = const Duration(milliseconds: 250);
      final rpm = client.send('010C');
      final restore = client.restoreFlowControl(
        budget: const Duration(milliseconds: 40),
      );
      await rpm;
      final outcome = await restore;
      expect(outcome.result, ElmFlowControlResult.budgetExceeded);
      expect(outcome.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      expect(transport.commandLog, isNot(contains('ATFCSM0')));
      final coolant = await client.send('0105');
      expect(coolant.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'pre-wire WriteRefused on the first apply command does not restore or stick',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      transport.refuseWriteBeforeAcceptingFor = {'ATFCSH7E0'};
      await expectLater(
        client.applyFlowControl(_sm1()),
        throwsA(isA<WriteRefusedException>()),
      );
      expect(_fcCommands(transport.commandLog), isEmpty);
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      expect(transport.commandLog, contains('010C'));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'pre-wire refusal of apply automatic while custom is restoreFailed not automatic',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.refuseWriteBeforeAcceptingFor = {'ATFCSM0'};
      final outcome = await client.applyFlowControl(
        ElmFlowControlConfig.automatic(),
      );
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.state, isNot(isA<ElmFlowControlAutomatic>()));
      expect(client.flowControlRestoreFailed, isTrue);
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'verbose ATFCSM0 OK over the response-byte budget is restoreFailed not restored',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATFCSM0', 'OK\r${'Z' * 260}');
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(restored.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(restored.state, isNot(isA<ElmFlowControlAutomatic>()));
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.commandLog, contains('ATFCSM0'));
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'bytes after the ATFCSM0 prompt are not charged to the restore budget',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      // Fake appends `\r>` after the forced body, so one chunk is
      // `OK\r>` then 260 Z then another `\r>`.
      transport.forceReply('ATFCSM0', 'OK\r>${'Z' * 260}');
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restored);
      expect(restored.state, isA<ElmFlowControlAutomatic>());
      expect(client.flowControlRestoreFailed, isFalse);
      final rpm = await client.send('010C');
      expect(rpm.isSuccess, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'ATFCSM0 OK lines under the content budget still fail when delimiters overflow',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATFCSM0', List.filled(128, 'OK').join('\r'));
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(restored.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'NUL-padded ATFCSM0 OK still counts the raw frame against the byte budget',
    () async {
      final transport = _can(
        faults: const AdapterFaults(injectNulls: true),
      );
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      transport.forceReply('ATFCSM0', 'OK\r${'Z' * 140}');
      final restored = await client.restoreFlowControl();
      expect(restored.result, ElmFlowControlResult.restoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a retired lease throws before any flow-control byte is written',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      final audit = client.beginWriteAudit();
      client.mayTransmit = (_) => false;
      await expectLater(
        client.applyFlowControl(_sm1(), owner: 'retired-lease'),
        throwsA(isA<OperationRetiredException>()),
      );
      expect(client.wroteSinceAudit(audit, 'ATFCSH7E0'), isFalse);
      expect(_fcCommands(transport.commandLog), isEmpty);
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'retired automatic apply while custom is restoreFailed not a silent poll',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      expect(
        (await client.applyFlowControl(_sm1())).result,
        ElmFlowControlResult.applied,
      );
      client.mayTransmit = (_) => false;
      final outcome = await client.applyFlowControl(
        ElmFlowControlConfig.automatic(),
        owner: 'retired-lease',
      );
      expect(outcome.result, ElmFlowControlResult.restoreFailed);
      expect(outcome.refusalIssue, TransportIssue.flowControlRestoreFailed);
      expect(client.flowControlRestoreFailed, isTrue);
      expect(transport.commandLog.where((c) => c == 'ATFCSM0'), isEmpty);
      client.mayTransmit = (_) => true;
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.flowControlRestoreFailed,
          ),
        ),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a lease that dies after ATFCSH restores and never activates SM1',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      client.mayTransmit = (_) => !transport.commandLog.contains('ATFCSH7E0');
      await expectLater(
        client.applyFlowControl(_sm1(), owner: 'expired-lease'),
        throwsA(isA<OperationRetiredException>()),
      );
      expect(_fcCommands(transport.commandLog), ['ATFCSH7E0', 'ATFCSM0']);
      expect(transport.commandLog, isNot(contains('ATFCSM1')));
      expect(client.flowControlState, isNot(isA<ElmFlowControlCustom>()));
      expect(transport.flowControlMode, 0);
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a new client cannot inherit custom state from another instance',
    () async {
      final firstTransport = _can();
      final first = await _connect(firstTransport);
      expect(
        (await first.applyFlowControl(_sm1())).state,
        isA<ElmFlowControlCustom>(),
      );
      final second = Elm327Client(_can());
      expect(second.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(second.flowControlRestoreFailed, isFalse);
      await first.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'ordinary 010C/0105 polling without FC is the handshake plus those two',
    () async {
      final transport = _can();
      final client = await _connect(transport);
      await client.send('010C');
      await client.send('0105');
      expect(transport.commandLog, [
        'ATZ',
        'ATE0',
        'ATL0',
        'ATM0',
        'ATS0',
        'ATAT1',
        'ATST66',
        'ATSP0',
        'ATI',
        'AT@1',
        'ATRV',
        '0100',
        'ATDP',
        'ATDPN',
        'ATPPS',
        '010C',
        '0105',
      ]);
      expect(_fcCommands(transport.commandLog), isEmpty);
      expect(
        transport.commandLog,
        isNot(anyOf(contains('ATCAF0'), contains('ATCFC0'), contains('ATCRA'))),
      );
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'identifier to sentence table is pinned and English refusals stay English',
    () {
      final en = lookupAppLocalizations(englishLocale);
      final zh = lookupAppLocalizations(traditionalChineseLocale);
      const expected = <TransportIssue, (String, String)>{
        TransportIssue.customFlowControlRejected: (
          'The adapter refused a custom flow-control command, so the requested mode was not applied and no measurement was produced.',
          '轉接器拒絕了自訂 Flow Control 指令，因此未套用所要求的模式，也沒有產生任何量測值。',
        ),
        TransportIssue.flowControlRestoreFailed: (
          'The adapter refused to restore default flow control (ATFCSM0), so polling is stopped until you reconnect.',
          '轉接器拒絕還原預設 Flow Control（ATFCSM0），因此已停止輪詢，請重新連線後再試。',
        ),
        TransportIssue.extendedAddressingUnavailable: (
          'Extended addressing is not available on this ELM327 path.',
          '此 ELM327 路徑不提供延伸定址。',
        ),
        TransportIssue.rawIsoTpModeUnavailable: (
          'Host-visible ISO-TP reassembly is not available on this ELM327 path.',
          '此 ELM327 路徑不提供主機可見的 ISO-TP 重組。',
        ),
      };
      expected.forEach((issue, sentences) {
        expect(
          commandIssueText(en, issue),
          sentences.$1,
        );
        expect(
          commandIssueText(zh, issue),
          sentences.$2,
        );
        expect(chinese.hasMatch(sentences.$1), isFalse);
        expect(sentences.$2, contains(RegExp(r'[\u4e00-\u9fff]')));
      });
    },
  );
}
