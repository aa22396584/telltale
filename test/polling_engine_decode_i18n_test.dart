/// Engine DTC decode / pending / mixed-scan notes are transcript-only English.
///
/// The screen maps [DtcReadException] through kind, `pendingSources`,
/// `refusedCount`, and `unrecognisedCount`. These sentences still land in
/// `e.message`. Chinese here leaked into English logs.
///
/// Every case drives the real engine: a hand-built exception would stay green
/// if production kept composing Chinese.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/polling_engine.dart';

import 'support/cjk.dart';
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

FakeElm327 _can({required AdapterFaults faults}) => FakeElm327(
  protocol: BusProtocol.can11,
  faults: faults,
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: {..._physicsReplies()},
    ),
  ],
);

Future<PollingEngine> _connect(FakeElm327 transport) async {
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 200),
    responsePendingTimeout: const Duration(milliseconds: 280),
  );
  expect(
    await client.connect(),
    isTrue,
    reason:
        'the fake must complete the handshake, or this test fails before '
        'reaching what it is about',
  );
  return PollingEngine(client);
}

void main() {
  test('pending-only stored read is English', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'03': '7E8 03 7F 03 78'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.pending)
            .having((e) => e.message, 'message', contains('response pending'))
            .having((e) => e.message, 'message', contains('has not finished'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('refuse-only stored read is English', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'03': '7E8 03 7F 03 11'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.error)
            .having((e) => e.refusedCount, 'refusedCount', 1)
            .having(
              (e) => e.message,
              'message',
              contains('refused the fault-code query'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('wrong service byte is English', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'03': '7E8 03 41 00 00'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.error)
            .having((e) => e.message, 'message', contains('wrong service byte'))
            .having((e) => e.message, 'message', contains('0x43'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('mixed refuse and answered is English', () async {
    final transport = _can(
      faults: const AdapterFaults(
        forcedReplies: {'03': '7E8 06 43 01 07 00 00 00\r7E9 03 7F 03 11'},
      ),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.error)
            .having((e) => e.refusedCount, 'refusedCount', 1)
            .having((e) => e.answeredCount, 'answeredCount', 1)
            .having((e) => e.message, 'message', contains('refused'))
            .having(
              (e) => e.message,
              'message',
              contains('cannot cover the whole vehicle'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('mixed pending and answered is English', () async {
    final transport = _can(
      faults: const AdapterFaults(
        forcedReplies: {'03': '7E8 06 43 01 07 00 00 00\r7E9 03 7F 03 78'},
      ),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.pending)
            .having((e) => e.message, 'message', contains('still working'))
            .having((e) => e.message, 'message', contains('response pending'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('decoder-rejected payload is English', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'03': '7E8 04 43 02 07 00'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.error)
            .having(
              (e) => e.message,
              'message',
              contains('could not be decoded'),
            )
            .having(
              (e) => e.message,
              'message',
              contains('the decoder rejected this reply'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('owed later-reply after a mixed pending is English', () async {
    final transport = _can(faults: const AdapterFaults());
    final engine = await _connect(transport);
    await engine.discoverResponders();
    transport.forceReplySequence('03', [
      '7E8 06 43 01 07 00 00 00\r7E9 03 7F 03 78',
      '7E8 06 43 01 07 00 00 00',
    ]);
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.pending)
            .having(
              (e) => e.message,
              'message',
              contains('promised a later reply'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
