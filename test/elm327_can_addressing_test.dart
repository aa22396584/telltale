/// Typed ELM327 `ATCEA` / `ATCP` / `ATCRA`: apply, restore, named refusals.
///
/// Every expectation is hand-typed. The fake is the wire oracle. Init must
/// still never send `ATCRA` — that landmine is pinned here and in protocol
/// deviations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/addressing.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_can_addressing.dart';
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
        ),
      ],
    );

FakeElm327 _can29Transport({
  AdapterFaults faults = const AdapterFaults(),
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
  test('compact spellings and restore forms are datasheet-pinned', () {
    expect(ElmExtendedAddressingConfig.applyCommand(0x07), 'ATCEA07');
    expect(ElmExtendedAddressingConfig.restoreCommand, 'ATCEA');
    expect(ElmCanPriorityConfig.applyCommand(0x17), 'ATCP17');
    expect(ElmCanPriorityConfig.restoreCommand, 'ATCP18');
    expect(
      ElmCanReceiveFilterConfig(address: '607', addressing: _can11)
          .toAtCommand(),
      'ATCRA607',
    );
    expect(
      ElmCanReceiveFilterConfig(
        address: '18DAF110',
        addressing: _can29,
      ).toAtCommand(),
      'ATCRA18DAF110',
    );
    expect(ElmCanReceiveFilterConfig.restoreCommand, 'ATCRA');
  });

  test('invalid widths and bytes throw', () {
    expect(
      () => ElmExtendedAddressingConfig.applyCommand(256),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmCanPriorityConfig.applyCommand(-1),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmCanReceiveFilterConfig(address: '6070', addressing: _can11),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmCanReceiveFilterConfig(address: '607', addressing: _can29),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmCanReceiveFilterConfig(
        address: '18DAF110',
        addressing: _can11,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => ElmCanReceiveFilterConfig(
        address: 'GGG',
        addressing: _can11,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('fresh client claims typed CAN addressing capabilities', () {
    final client = Elm327Client(_can11Transport());
    expect(client.supportsExtendedAddressing, isTrue);
    expect(client.supportsCanPriority, isTrue);
    expect(client.supportsCanReceiveFilter, isTrue);
    expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
    expect(client.canPriorityState, isA<ElmCanPriorityDefault>());
    expect(client.canReceiveFilterState, isA<ElmCanReceiveFilterOff>());
  });

  test('init and ordinary polling never send ATCRA / ATCEA / ATCP', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    final beforePoll = List<String>.from(transport.commandLog);
    expect(beforePoll.where((c) => c.startsWith('ATCRA')), isEmpty);
    expect(beforePoll.where((c) => c.startsWith('ATCEA')), isEmpty);
    expect(beforePoll.where((c) => c.startsWith('ATCP')), isEmpty);
    expect((await client.send('010C')).isSuccess, isTrue);
    expect(
      transport.commandLog.where((c) => c.startsWith('ATCRA')),
      isEmpty,
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCEA07 apply then ATCEA restore', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    final applied = await client.applyExtendedAddressing(0x07);
    expect(applied.result, ElmExtendedAddressingResult.applied);
    expect(applied.producedMeasurement, isTrue);
    expect(applied.state, isA<ElmExtendedAddressingOn>());
    expect((applied.state as ElmExtendedAddressingOn).addressByte, 0x07);
    expect(transport.commandLog, contains('ATCEA07'));
    expect(transport.extendedAddressByte, 0x07);

    final restored = await client.restoreExtendedAddressing();
    expect(restored.result, ElmExtendedAddressingResult.restored);
    expect(restored.state, isA<ElmExtendedAddressingOff>());
    expect(transport.commandLog, contains('ATCEA'));
    expect(transport.extendedAddressByte, isNull);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('rejected ATCEA is extendedAddressingUnavailable', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCea: true),
    );
    final client = await _connect(transport);
    final outcome = await client.applyExtendedAddressing(0x07);
    expect(outcome.result, ElmExtendedAddressingResult.rejectedUnknownCommand);
    expect(outcome.producedMeasurement, isFalse);
    expect(
      outcome.refusalIssue,
      TransportIssue.extendedAddressingUnavailable,
    );
    expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCEA on ISO 9141 refuses without writing', () async {
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
    final before = transport.commandLog.length;
    final outcome = await client.applyExtendedAddressing(0x07);
    expect(outcome.result, ElmExtendedAddressingResult.rejectedUnknownCommand);
    expect(
      transport.commandLog.skip(before).where((c) => c.startsWith('ATCEA')),
      isEmpty,
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('sticky CEA restore failure refuses ordinary polling', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCeaRestore: true),
    );
    final client = await _connect(transport);
    expect(
      (await client.applyExtendedAddressing(0x07)).result,
      ElmExtendedAddressingResult.applied,
    );
    final restored = await client.restoreExtendedAddressing();
    expect(restored.result, ElmExtendedAddressingResult.restoreFailed);
    expect(client.extendedAddressingRestoreFailed, isTrue);
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

  test('redundant CEA restore while off is restoreRejected', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCeaRestore: true),
    );
    final client = await _connect(transport);
    final restored = await client.restoreExtendedAddressing();
    expect(restored.result, ElmExtendedAddressingResult.restoreRejected);
    expect(client.extendedAddressingRestoreFailed, isFalse);
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCEA timeout after write is timedOut with cleanup', () async {
    final transport = _can11Transport();
    final client = await _connect(
      transport,
      commandTimeout: const Duration(milliseconds: 80),
    );
    // Shorter than [Elm327Client.resyncTimeout] so cleanup can drain the
    // late prompt and still report timedOut (not sticky restoreFailed).
    transport.slowCommands['ATCEA07'] = const Duration(milliseconds: 400);
    final outcome = await client.applyExtendedAddressing(0x07);
    expect(outcome.result, ElmExtendedAddressingResult.timedOut);
    expect(outcome.producedMeasurement, isFalse);
    expect(client.extendedAddressingRestoreFailed, isFalse);
    expect(transport.commandLog, contains('ATCEA'));
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('unconfirmed CEA write still attempts restore', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    transport.failWriteAfterAcceptingWithNativeErrorFor = {'ATCEA07'};
    final outcome = await client.applyExtendedAddressing(0x07);
    expect(
      outcome.result,
      anyOf(
        ElmExtendedAddressingResult.unconfirmedWrite,
        ElmExtendedAddressingResult.restoreFailed,
      ),
    );
    expect(transport.commandLog, contains('ATCEA'));
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCP17 on 29-bit then ATCP18 restore', () async {
    final transport = _can29Transport();
    final client = await _connect(transport);
    final applied = await client.applyCanPriority(0x17);
    expect(applied.result, ElmCanPriorityResult.applied);
    expect(applied.state, isA<ElmCanPriorityCustom>());
    expect(transport.commandLog, contains('ATCP17'));
    expect(transport.canPriorityByte, 0x17);

    final restored = await client.restoreCanPriority();
    expect(restored.result, ElmCanPriorityResult.restored);
    expect(restored.state, isA<ElmCanPriorityDefault>());
    expect(transport.commandLog, contains('ATCP18'));
    expect(transport.canPriorityByte, 0x18);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCP on 11-bit CAN is refused without writing', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    final before = transport.commandLog.length;
    final outcome = await client.applyCanPriority(0x17);
    expect(outcome.result, ElmCanPriorityResult.rejectedUnknownCommand);
    expect(
      outcome.refusalIssue,
      TransportIssue.canPriorityUnavailable,
    );
    expect(
      transport.commandLog.skip(before).where((c) => c.startsWith('ATCP')),
      isEmpty,
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('rejected ATCP is canPriorityUnavailable', () async {
    final transport = _can29Transport(
      faults: const AdapterFaults(refuseCp: true),
    );
    final client = await _connect(transport);
    final outcome = await client.applyCanPriority(0x17);
    expect(outcome.result, ElmCanPriorityResult.rejectedUnknownCommand);
    expect(outcome.refusalIssue, TransportIssue.canPriorityUnavailable);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('sticky CP restore failure refuses ordinary polling', () async {
    final transport = _can29Transport(
      faults: const AdapterFaults(refuseCpRestore: true),
    );
    final client = await _connect(transport);
    expect(
      (await client.applyCanPriority(0x17)).result,
      ElmCanPriorityResult.applied,
    );
    final restored = await client.restoreCanPriority();
    expect(restored.result, ElmCanPriorityResult.restoreFailed);
    expect(client.canPriorityRestoreFailed, isTrue);
    await expectLater(
      client.send('010C'),
      throwsA(
        isA<TransportException>().having(
          (e) => e.issue,
          'issue',
          TransportIssue.canPriorityUnavailable,
        ),
      ),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('redundant CP restore while default is restoreRejected', () async {
    final transport = _can29Transport(
      faults: const AdapterFaults(refuseCpRestore: true),
    );
    final client = await _connect(transport);
    final restored = await client.restoreCanPriority();
    expect(restored.result, ElmCanPriorityResult.restoreRejected);
    expect(client.canPriorityRestoreFailed, isFalse);
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCRA607 apply then bare ATCRA restore', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    final config = ElmCanReceiveFilterConfig(
      address: '607',
      addressing: _can11,
    );
    final applied = await client.applyCanReceiveFilter(config);
    expect(applied.result, ElmCanReceiveFilterResult.applied);
    expect(applied.state, isA<ElmCanReceiveFilterOn>());
    expect(transport.commandLog, contains('ATCRA607'));
    expect(transport.canReceiveFilter, '607');

    final restored = await client.restoreCanReceiveFilter();
    expect(restored.result, ElmCanReceiveFilterResult.restored);
    expect(restored.state, isA<ElmCanReceiveFilterOff>());
    expect(
      transport.commandLog.where((c) => c == 'ATCRA').length,
      greaterThanOrEqualTo(1),
    );
    expect(transport.canReceiveFilter, isNull);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('rejected ATCRA is canReceiveFilterUnavailable', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCra: true),
    );
    final client = await _connect(transport);
    final outcome = await client.applyCanReceiveFilter(
      ElmCanReceiveFilterConfig(address: '607', addressing: _can11),
    );
    expect(outcome.result, ElmCanReceiveFilterResult.rejectedUnknownCommand);
    expect(outcome.refusalIssue, TransportIssue.canReceiveFilterUnavailable);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('sticky CRA restore failure refuses ordinary polling', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCraRestore: true),
    );
    final client = await _connect(transport);
    expect(
      (await client.applyCanReceiveFilter(
        ElmCanReceiveFilterConfig(address: '607', addressing: _can11),
      ))
          .result,
      ElmCanReceiveFilterResult.applied,
    );
    final restored = await client.restoreCanReceiveFilter();
    expect(restored.result, ElmCanReceiveFilterResult.restoreFailed);
    expect(client.canReceiveFilterRestoreFailed, isTrue);
    await expectLater(
      client.send('010C'),
      throwsA(
        isA<TransportException>().having(
          (e) => e.issue,
          'issue',
          TransportIssue.canReceiveFilterUnavailable,
        ),
      ),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('redundant CRA restore while clear is restoreRejected', () async {
    final transport = _can11Transport(
      faults: const AdapterFaults(refuseCraRestore: true),
    );
    final client = await _connect(transport);
    final restored = await client.restoreCanReceiveFilter();
    expect(restored.result, ElmCanReceiveFilterResult.restoreRejected);
    expect(client.canReceiveFilterRestoreFailed, isFalse);
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCP clears the confirmed header so the next ATSH is resent', () async {
    final transport = _can29Transport();
    final client = await _connect(transport);
    expect((await client.sendOnHeader('18DA10F1', '010C')).isSuccess, isTrue);
    expect(transport.commandLog, contains('ATSH18DA10F1'));
    final before = transport.commandLog.length;
    expect(
      (await client.applyCanPriority(0x17)).result,
      ElmCanPriorityResult.applied,
    );
    expect((await client.sendOnHeader('18DA10F1', '0105')).isSuccess, isTrue);
    expect(
      transport.commandLog.skip(before),
      contains('ATSH18DA10F1'),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATCRA filter that misses the ECU yields NO DATA', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    expect(
      (await client.applyCanReceiveFilter(
        ElmCanReceiveFilterConfig(address: '7E9', addressing: _can11),
      ))
          .result,
      ElmCanReceiveFilterResult.applied,
    );
    final rpm = await client.send('010C');
    expect(rpm.errorCode, Elm327ErrorCode.noData);
    expect(rpm.bytes, isEmpty);
    expect(
      (await client.restoreCanReceiveFilter()).result,
      ElmCanReceiveFilterResult.restored,
    );
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('DemoTransport refuses ATCEA and ATCP apply', () async {
    final transport = DemoTransport();
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);
    final cea = await client.applyExtendedAddressing(0x07);
    expect(cea.result, ElmExtendedAddressingResult.rejectedUnknownCommand);
    expect(cea.producedMeasurement, isFalse);
    // Demo stays on 11-bit after handshake; CP is refused before write.
    final cp = await client.applyCanPriority(0x17);
    expect(cp.result, ElmCanPriorityResult.rejectedUnknownCommand);
    expect((await client.send('010C')).isSuccess, isTrue);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('ATZ after CEA clears extended addressing on a live client', () async {
    final transport = _can11Transport();
    final client = await _connect(transport);
    expect(
      (await client.applyExtendedAddressing(0x07)).result,
      ElmExtendedAddressingResult.applied,
    );
    await client.send('ATZ');
    expect(client.extendedAddressingState, isA<ElmExtendedAddressingOff>());
    expect(transport.extendedAddressByte, isNull);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
