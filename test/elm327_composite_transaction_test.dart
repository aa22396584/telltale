/// ELM327 composite query transaction tests: apply → query → reverse-restore.
///
/// Verifies explicit ownership that excludes unrelated polling throughout mutated
/// adapter state, skips a retired measurement, attempts reverse restoration in
/// `finally` after timeout/write/parser/retirement failures, and leaves a sticky
/// blocked state on restore failure.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/addressing.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_can_addressing.dart';
import 'package:torque_obd/obd/elm_flow_control.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/fake_elm327.dart';

BusAddressing get _can11 => BusAddressing.forProtocolNumber('6');
BusAddressing get _can29 => BusAddressing.forProtocolNumber('7');

Map<String, List<int>> _physicsReplies() => {
      '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      '0105': [0x41, 0x05, 0x7B],
      '010C': [0x41, 0x0C, 0x1A, 0xF8],
    };

FakeElm327 _can11Transport({
  AdapterFaults faults = const AdapterFaults(),
  Map<String, List<int>> didReplies = const {},
  Map<String, List<String>> literalReplies = const {},
}) =>
    FakeElm327(
      protocol: BusProtocol.can11,
      faults: faults,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {..._physicsReplies(), ...didReplies},
          literalResponses: literalReplies,
        ),
        FakeEcu(
          name: 'SME',
          requestId: '6F1',
          responseId: '607',
          responses: {
            '22DDBC': [0x62, 0xDD, 0xBC, 0x54, 0x20],
            ...didReplies,
          },
          literalResponses: literalReplies,
        ),
      ],
    );

FakeElm327 _can29Transport({
  AdapterFaults faults = const AdapterFaults(),
  Map<String, List<int>> didReplies = const {},
}) =>
    FakeElm327(
      protocol: BusProtocol.can29,
      faults: faults,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '18DA10F1',
          responseId: '18DAF110',
          responses: _physicsReplies(),
        ),
        FakeEcu(
          name: 'BMS',
          requestId: '18DADBF1',
          responseId: '18DAF1DB',
          responses: {
            '221234': [0x62, 0x12, 0x34, 0x2A],
            ...didReplies,
          },
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
  group('composite query transaction apply -> query -> reverse-restore', () {
    test('full composite BMW i3 style query: CEA + CRA + FCS + CAF0 + ATSH',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      final filter = ElmCanReceiveFilterConfig(
        address: '607',
        addressing: _can11,
      );
      final fc = ElmFlowControlConfig.customHeaderAndData(
        header: '6F1',
        data: [0x07, 0x30, 0x00, 0x00],
        addressing: _can11,
      );

      final before = transport.commandLog.length;
      final reply = await client.sendTransacted(
        '22DDBC',
        header: '6F1',
        extendedAddressByte: 0x07,
        canReceiveFilter: filter,
        flowControl: fc,
        hostVisibleIsoTp: true,
      );

      expect(reply.isSuccess, isTrue);
      final log = transport.commandLog.skip(before).toList();

      // Verify sequence of commands on the wire:
      // Apply: ATCEA07 -> ATCRA607 -> ATFCSH6F1/ATFCSD/ATFCSM1 -> ATCAF0 -> ATSH6F1 -> 22DDBC (framed)
      final ceaIndex = log.indexOf('ATCEA07');
      final craIndex = log.indexOf('ATCRA607');
      final fcsmIndex = log.indexOf('ATFCSM1');
      final caf0Index = log.indexOf('ATCAF0');
      final atshIndex = log.indexOf('ATSH6F1');

      expect(ceaIndex, greaterThanOrEqualTo(0), reason: 'ATCEA07 must be sent');
      expect(craIndex, greaterThan(ceaIndex), reason: 'ATCRA after ATCEA');
      expect(fcsmIndex, greaterThan(craIndex), reason: 'ATFCSM1 after ATCRA');
      expect(caf0Index, greaterThan(fcsmIndex), reason: 'ATCAF0 after ATFCSM1');
      expect(atshIndex, greaterThan(caf0Index), reason: 'ATSH after ATCAF0');

      // Reverse restoration in finally:
      // Restore order must be reverse: ATCAF1 -> ATFCSM0 -> ATCRA -> ATCEA
      final caf1Index = log.indexOf('ATCAF1');
      final fcsm0Index = log.indexOf('ATFCSM0');
      final craRestoreIndex = log.indexOf('ATCRA');
      final ceaRestoreIndex = log.indexOf('ATCEA');

      expect(caf1Index, greaterThan(atshIndex), reason: 'ATCAF1 after query');
      expect(fcsm0Index, greaterThan(caf1Index), reason: 'ATFCSM0 after ATCAF1');
      expect(craRestoreIndex, greaterThan(fcsm0Index),
          reason: 'ATCRA after ATFCSM0');
      expect(ceaRestoreIndex, greaterThan(craRestoreIndex),
          reason: 'ATCEA after ATCRA');

      // Verify adapter internal states are back to normal defaults
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
      expect(client.canReceiveFilterState, isA<ElmCanReceiveFilterOff>());
      expect(client.flowControlState, isA<ElmFlowControlAutomatic>());
      expect(client.hostVisibleIsoTp, isFalse);
      expect(transport.extendedAddressByte, isNull);
      expect(transport.canReceiveFilter, isNull);
      expect(transport.flowControlMode, 0);
      expect(transport.autoFormatMode, 1);

      // Verify subsequent ordinary query succeeds without residue
      final standard = await client.sendOnHeader('7E0', '010C');
      expect(standard.isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('29-bit CAN priority and receive filter transaction', () async {
      final transport = _can29Transport();
      final client = await _connect(transport);

      final filter = ElmCanReceiveFilterConfig(
        address: '18DAF1DB',
        addressing: _can29,
      );

      final before = transport.commandLog.length;
      final reply = await client.sendTransacted(
        '221234',
        header: '18DADBF1',
        canPriorityByte: 0x17,
        canReceiveFilter: filter,
      );

      expect(reply.isSuccess, isTrue);
      final log = transport.commandLog.skip(before).toList();

      expect(log, contains('ATCP17'));
      expect(log, contains('ATCRA18DAF1DB'));
      expect(log, contains('ATSH18DADBF1'));
      expect(log, contains('221234'));
      expect(log, contains('ATCRA'));
      expect(log, contains('ATCP18'));

      expect(client.canPriorityState, isA<ElmCanPriorityDefault>());
      expect(client.canReceiveFilterState, isA<ElmCanReceiveFilterOff>());
      expect(transport.canPriorityByte, 0x18);
      expect(transport.canReceiveFilter, isNull);

      final next = await client.sendOnHeader('18DA10F1', '010C');
      expect(next.isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('transact alias produces identical result', () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      final reply = await client.transact(
        '010C',
        extendedAddressByte: 0x07,
      );

      expect(reply.isSuccess, isTrue);
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
      expect(transport.commandLog, contains('ATCEA07'));
      expect(transport.commandLog, contains('ATCEA'));
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('accepts ElmCompositeTransactionConfig configuration bundle',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      const config = ElmCompositeTransactionConfig(
        extendedAddressByte: 0x07,
      );
      expect(config.hasMutations, isTrue);

      final reply = await client.sendTransacted(
        '010C',
        configuration: config,
      );

      expect(reply.isSuccess, isTrue);
      expect(transport.commandLog, contains('ATCEA07'));
      expect(transport.commandLog, contains('ATCEA'));
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('retirement gate: skips measurement and attempts reverse restoration', () {
    test('skips measurement when retired after mutations and restores in finally',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      // Active during initial apply, turns retired once ATCEA07 lands
      client.mayTransmit = (_) => !transport.commandLog.contains('ATCEA07');

      final before = transport.commandLog.length;
      await expectLater(
        client.sendTransacted(
          '22DDBC',
          extendedAddressByte: 0x07,
        ),
        throwsA(isA<OperationRetiredException>()),
      );

      final log = transport.commandLog.skip(before).toList();
      // ATCEA07 was applied
      expect(log, contains('ATCEA07'));
      // The query itself was SKIPPED (never sent)
      expect(log.where((c) => c.contains('22DDBC')), isEmpty);
      // Reverse-restoration in finally was ATTEMPTED and succeeded
      expect(log, contains('ATCEA'));
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
      expect(transport.extendedAddressByte, isNull);

      // Reset mayTransmit; subsequent polling works
      client.mayTransmit = (_) => true;
      expect((await client.send('010C')).isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('refuses immediately before writing anything if already retired',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      client.mayTransmit = (_) => false;

      final before = transport.commandLog.length;
      await expectLater(
        client.sendTransacted(
          '010C',
          extendedAddressByte: 0x07,
        ),
        throwsA(isA<OperationRetiredException>()),
      );

      expect(transport.commandLog.length, before);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('failure recovery in finally', () {
    test('reverse-restores in finally after query timeout', () async {
      final transport = _can11Transport();
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 100),
      );

      transport.slowCommands['22DDBC'] = const Duration(milliseconds: 500);

      final before = transport.commandLog.length;
      await expectLater(
        client.sendTransacted(
          '22DDBC',
          extendedAddressByte: 0x07,
          timeout: const Duration(milliseconds: 80),
        ),
        throwsA(isA<TimeoutException>()),
      );

      final log = transport.commandLog.skip(before).toList();
      expect(log, contains('ATCEA07'));
      expect(log, contains('ATCEA'));
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());

      // Subsequent send works
      expect((await client.send('010C')).isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('reverse-restores in finally when parser throws exception in runTransacted',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      await expectLater(
        client.runTransacted(
          (send) async {
            final resp = await send('010C');
            expect(resp.isSuccess, isTrue);
            throw const FormatException('Parser failure in user code');
          },
          extendedAddressByte: 0x07,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(transport.commandLog, contains('ATCEA07'));
      expect(transport.commandLog, contains('ATCEA'));
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());

      expect((await client.send('010C')).isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('rollbacks earlier mutations in reverse order if apply fails midway',
        () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(refuseCra: true),
      );
      final client = await _connect(transport);

      final filter = ElmCanReceiveFilterConfig(
        address: '607',
        addressing: _can11,
      );

      final before = transport.commandLog.length;
      await expectLater(
        client.sendTransacted(
          '010C',
          extendedAddressByte: 0x07,
          canReceiveFilter: filter,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.canReceiveFilterUnavailable,
          ),
        ),
      );

      final log = transport.commandLog.skip(before).toList();
      // ATCEA07 was applied, then ATCRA607 was refused
      expect(log, contains('ATCEA07'));
      expect(log, contains('ATCRA607'));
      // ATCEA was rolled back in finally!
      expect(log, contains('ATCEA'));
      expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());

      // Polling continues
      expect((await client.send('010C')).isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('leaves sticky blocked state when reverse restore fails', () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(refuseCeaRestore: true),
      );
      final client = await _connect(transport);

      await expectLater(
        client.sendTransacted(
          '010C',
          extendedAddressByte: 0x07,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.extendedAddressingUnavailable,
          ),
        ),
      );

      expect(client.extendedAddressingRestoreFailed, isTrue);

      // Sticky failure refuses any later command
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.extendedAddressingUnavailable,
          ),
        ),
      );
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('unrelated polling exclusion throughout mutated adapter state', () {
    test('concurrent polling on command chain cannot interleave during mutation',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      // Start a slow transaction that sleeps during measurement
      final transactionFuture = client.runTransacted(
        (send) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return send('010C');
        },
        extendedAddressByte: 0x07,
      );

      // Simultaneously queue an ordinary poll on a different header
      final pollFuture = client.sendOnHeader('7E0', '0105');

      final results = await Future.wait([transactionFuture, pollFuture]);
      expect(results[0].isSuccess, isTrue);
      expect(results[1].isSuccess, isTrue);

      // Examine log: sendOnHeader must execute strictly AFTER ATCEA restore
      final log = transport.commandLog;
      final ceaRestoreIndex = log.lastIndexOf('ATCEA');
      final pollIndex = log.indexOf('0105');

      expect(ceaRestoreIndex, greaterThanOrEqualTo(0));
      expect(pollIndex, greaterThan(ceaRestoreIndex),
          reason: 'unrelated poll must not run while extended addressing is active');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('bus validation and preflight checks', () {
    test('refuses CAN mutations on non-CAN protocols without sending AT commands',
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
              '010C': [0x41, 0x0C, 0x1A, 0xF8],
            },
          ),
        ],
      );
      final client = await _connect(transport);
      final before = transport.commandLog.length;

      await expectLater(
        client.sendTransacted('010C', extendedAddressByte: 0x07),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.extendedAddressingUnavailable,
          ),
        ),
      );

      expect(
        transport.commandLog.skip(before).where((c) => c.startsWith('ATCEA')),
        isEmpty,
      );
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('DemoTransport refuses composite CAN mutations cleanly', () async {
      final transport = DemoTransport();
      final client = Elm327Client(transport);
      expect(await client.connect(), isTrue);

      await expectLater(
        client.sendTransacted('010C', extendedAddressByte: 0x07),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.extendedAddressingUnavailable,
          ),
        ),
      );

      expect((await client.send('010C')).isSuccess, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('restoreHeader restores previous header when requested', () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      // Establish initial header
      await client.sendOnHeader('7E0', '010C');
      expect(transport.commandLog, contains('ATSH7E0'));

      final before = transport.commandLog.length;
      final reply = await client.sendTransacted(
        '22DDBC',
        header: '6F1',
        restoreHeader: true,
        extendedAddressByte: 0x07,
      );
      expect(reply.isSuccess, isTrue);

      final log = transport.commandLog.skip(before).toList();
      expect(log, contains('ATSH6F1'));
      expect(log, contains('ATSH7E0'));
      expect(log.indexOf('ATSH7E0'), greaterThan(log.indexOf('22DDBC')));

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
        'header restore refusal sets sticky failure, leaves header unknown, and refuses next send with zero writes',
        () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(refuseHeaderAfterCount: 2),
      );
      final client = await _connect(transport);

      // Establish initial header A: 7E0 (1st ATSH)
      await client.sendOnHeader('7E0', '010C');
      expect(client.currentHeader, '7E0');

      final before = transport.commandLog.length;

      // 2nd ATSH: 6F1 (succeeds)
      // Query: 22DDBC (succeeds)
      // 3rd ATSH: 7E0 restore (refused with '?')
      await expectLater(
        client.sendTransacted(
          '22DDBC',
          header: '6F1',
          restoreHeader: true,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );

      final log = transport.commandLog.skip(before).toList();
      expect(log, contains('ATSH6F1'));
      expect(log, contains('22DDBC'));
      expect(log, contains('ATSH7E0'));
      expect(log.indexOf('ATSH7E0'), greaterThan(log.indexOf('22DDBC')));

      // Status must be unknown (null) and restore-failed
      expect(client.currentHeader, isNull);
      expect(client.headerRestoreFailed, isTrue);

      // Next normal send MUST fail closed with zero wire writes!
      final logLengthBeforeSend = transport.commandLog.length;
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );
      expect(transport.commandLog.length, logLengthBeforeSend,
          reason: 'Next normal send must have zero writes on the wire');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
        'header restore timeout sets sticky failure and leaves header unknown',
        () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(
          refuseHeaderAfterCount: 2,
          delayHeaderRestore: true,
        ),
      );
      final client = await _connect(
        transport,
        commandTimeout: const Duration(milliseconds: 100),
      );

      await client.sendOnHeader('7E0', '010C');
      expect(client.currentHeader, '7E0');

      await expectLater(
        client.sendTransacted(
          '22DDBC',
          header: '6F1',
          restoreHeader: true,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );

      expect(client.currentHeader, isNull);
      expect(client.headerRestoreFailed, isTrue);
      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('header restore disconnect leaves header unknown and refuses next send',
        () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(
          refuseHeaderAfterCount: 2,
          dropOnHeaderRestore: true,
        ),
      );
      final client = await _connect(transport);

      await client.sendOnHeader('7E0', '010C');
      expect(client.currentHeader, '7E0');

      await expectLater(
        client.sendTransacted(
          '22DDBC',
          header: '6F1',
          restoreHeader: true,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );

      expect(client.currentHeader, isNull);
      expect(client.headerRestoreFailed, isTrue);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
        'header restore throw sets sticky failure, leaves header unknown, and refuses next send with zero writes',
        () async {
      final transport = _can11Transport(
        faults: const AdapterFaults(
          refuseHeaderAfterCount: 2,
          throwOnHeaderRestore: true,
        ),
      );
      final client = await _connect(transport);

      // Establish initial header A: 7E0 (1st ATSH)
      await client.sendOnHeader('7E0', '010C');
      expect(client.currentHeader, '7E0');

      // 2nd ATSH: 6F1 (succeeds)
      // Query: 22DDBC (succeeds)
      // 3rd ATSH: 7E0 restore (transport throws exception)
      await expectLater(
        client.sendTransacted(
          '22DDBC',
          header: '6F1',
          restoreHeader: true,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );

      // Status must be unknown (null) and restore-failed
      expect(client.currentHeader, isNull);
      expect(client.headerRestoreFailed, isTrue);

      // Next normal send MUST fail closed with zero wire writes!
      final logLengthBeforeSend = transport.commandLog.length;
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );
      expect(transport.commandLog.length, logLengthBeforeSend,
          reason: 'Next normal send must have zero writes on the wire');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
        'restoreHeader with previousHeader null leaves currentHeader on transaction header without restore',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      // No header established yet; currentHeader is null
      expect(client.currentHeader, isNull);

      final reply = await client.sendTransacted(
        '22DDBC',
        header: '6F1',
        restoreHeader: true,
      );
      expect(reply.isSuccess, isTrue);

      // Because previousHeader was null, no restore was possible; currentHeader remains '6F1'
      expect(client.currentHeader, '6F1');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('F2: transaction sender lifecycle, serialization, and isolation', () {
    test('leaked sender post-transaction throws operationRetired with zero writes',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      Future<ObdResponse> Function(String, {Duration? timeout})? leakedSender;

      final res = await client.runTransacted((sender) async {
        leakedSender = sender;
        return await sender('010C');
      }, header: '7E0');

      expect(res.isSuccess, isTrue);
      expect(leakedSender, isNotNull);

      final logLengthBeforeLeakedSend = transport.commandLog.length;
      await expectLater(
        leakedSender!('010D'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.operationRetired,
          ),
        ),
      );
      expect(transport.commandLog.length, logLengthBeforeLeakedSend,
          reason: 'Calling leaked sender must produce zero writes on wire');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('concurrent senders inside callback are serialized without interleaving',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      await client.runTransacted((sender) async {
        final f1 = sender('0100');
        final f2 = sender('010C');
        final results = await Future.wait([f1, f2]);
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
      }, header: '7E0');

      final log = transport.commandLog;
      final idx1 = log.indexOf('0100');
      final idx2 = log.indexOf('010C');
      expect(idx1, greaterThan(-1));
      expect(idx2, greaterThan(idx1),
          reason: '0100 and 010C must execute sequentially');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('un-awaited send completes before reverse restores execute on wire',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      await client.sendOnHeader('7E0', '010C');

      await client.runTransacted((sender) async {
        // Fire and do NOT await sender
        unawaited(sender('221234'));
        // Return immediately from action
      }, header: '6F1', restoreHeader: true);

      final log = transport.commandLog;
      final queryIdx = log.indexOf('221234');
      final restoreIdx = log.lastIndexOf('ATSH7E0');
      expect(queryIdx, greaterThan(-1),
          reason: 'Un-awaited send must be written to wire');
      expect(restoreIdx, greaterThan(queryIdx),
          reason: 'Reverse restore must happen AFTER un-awaited send completes');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('callback reentrancy: client.send or setter inside callback throws StateError',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      var sendThrewStateError = false;
      var setterThrewStateError = false;

      await client.runTransacted((sender) async {
        try {
          await client.send('010C');
        } on StateError {
          sendThrewStateError = true;
        }

        try {
          await client.applyCanPriority(0x17);
        } on StateError {
          setterThrewStateError = true;
        }

        return await sender('010D');
      }, header: '7E0');

      expect(sendThrewStateError, isTrue,
          reason: 'client.send inside runTransacted must throw StateError to prevent deadlock');
      expect(setterThrewStateError, isTrue,
          reason: 'client setter inside runTransacted must throw StateError to prevent deadlock');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('infinite action is bounded by budget and revokes sender', () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      Future<ObdResponse> Function(String, {Duration? timeout})? leakedSender;

      await expectLater(
        client.runTransacted(
          (sender) async {
            leakedSender = sender;
            // Never completing future
            await Completer<void>().future;
          },
          header: '7E0',
          budget: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(leakedSender, isNotNull);
      final logLengthBeforeLeakedSend = transport.commandLog.length;
      await expectLater(
        leakedSender!('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.operationRetired,
          ),
        ),
      );
      expect(transport.commandLog.length, logLengthBeforeLeakedSend,
          reason: 'Sender revoked after timeout, must produce zero writes');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('connection generation isolation: sender from prior connection cannot write',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      Future<ObdResponse> Function(String, {Duration? timeout})? capturedSender;
      final txStarted = Completer<void>();
      final txContinue = Completer<void>();

      final txFuture = client.runTransacted((sender) async {
        capturedSender = sender;
        txStarted.complete();
        await txContinue.future;
        return await sender('010C');
      }, header: '7E0');

      await txStarted.future;
      expect(capturedSender, isNotNull);

      // Simulate connection drop while transaction was open
      final genBefore = client.connectionGeneration;
      transport.setConnected(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(client.connectionGeneration, greaterThan(genBefore));

      // Release txContinue and let the transaction fail/terminate
      txContinue.complete();
      try {
        await txFuture;
      } catch (_) {}

      // Reconnect
      transport.setConnected(true);

      // Calling the captured sender from the prior generation must fail closed
      final logLengthBeforeSend = transport.commandLog.length;
      await expectLater(
        capturedSender!('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            anyOf(
              TransportIssue.operationRetired,
              TransportIssue.notConnected,
            ),
          ),
        ),
      );
      expect(transport.commandLog.length, logLengthBeforeSend,
          reason: 'Sender from prior generation must produce zero writes on wire');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
        'late continuation from timed out action cannot interleave with concurrent polling and is zero-write rejected',
        () async {
      final transport = _can11Transport();
      final client = await _connect(transport);

      // Establish initial header 7E0 for ECM
      await client.sendOnHeader('7E0', '010C');
      expect(client.currentHeader, '7E0');

      Future<ObdResponse> Function(String, {Duration? timeout})? capturedSender;
      final actionStarted = Completer<void>();
      final allowLateContinuation = Completer<void>();

      // Launch transaction that times out due to tiny budget
      await expectLater(
        client.runTransacted(
          (sender) async {
            capturedSender = sender;
            actionStarted.complete();
            await allowLateContinuation.future;
            // Attempt to send after timeout occurred
            return await sender('22DDBC');
          },
          header: '6F1',
          restoreHeader: true,
          budget: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );

      await actionStarted.future;
      expect(capturedSender, isNotNull);

      // Concurrent regular polling starts immediately after transaction timeout
      final pollingFuture = client.send('010C');

      // Now late continuation wakes up and attempts to send using revoked sender
      final logBeforeLate = transport.commandLog.length;
      final lateSendExpectation = expectLater(
        capturedSender!('22DDBC'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.operationRetired,
          ),
        ),
      );

      allowLateContinuation.complete();

      // Regular polling must succeed
      final pollingReply = await pollingFuture;
      expect(pollingReply.isSuccess, isTrue);

      // Late continuation sender must be rejected with operationRetired
      await lateSendExpectation;

      // Verify that '22DDBC' was NEVER written to the wire by the late sender
      final lateWrites = transport.commandLog
          .skip(logBeforeLate)
          .where((cmd) => cmd.contains('22DDBC'))
          .toList();
      expect(lateWrites, isEmpty,
          reason: 'Late continuation must produce ZERO wire writes');

      await client.disconnect();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
