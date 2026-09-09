/// Engine Mode 04 NRC notes are transcript-only English.
///
/// The screen maps [DtcReadException] through `negativeResponseCode` and
/// `repeatWouldHarm`. These sentences still land in `e.message`. Chinese here
/// leaked into English logs.
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
  test('NRC 0x22 alone is English and safe to retry', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 22'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.negativeResponseCode, 'nrc', 0x22)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
            .having(
              (e) => e.message,
              'message',
              contains('vehicle state does not allow it'),
            )
            .having(
              (e) => e.message,
              'message',
              isNot(contains('do not send another whole-vehicle clear')),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('NRC 0x22 beside a 44 is English and locks retry', () async {
    final transport = _can(
      faults: const AdapterFaults(
        forcedReplies: {'04': '7E8 01 44\r7E9 03 7F 04 22'},
      ),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isTrue)
            .having(
              (e) => e.message,
              'message',
              contains('At least one other controller has finished'),
            )
            .having(
              (e) => e.message,
              'message',
              contains('do not send another whole-vehicle clear'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('NRC 0x11 alone is English and names Mode 04', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 11'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.negativeResponseCode, 'nrc', 0x11)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
            .having(
              (e) => e.message,
              'message',
              contains('does not support the clear service (Mode 04)'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('NRC 0x33 alone is English and names the security unlock', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 33'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.negativeResponseCode, 'nrc', 0x33)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
            .having(
              (e) => e.message,
              'message',
              contains('requires a security unlock'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('NRC 0x21 alone is English and says the controller is busy', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 21'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.negativeResponseCode, 'nrc', 0x21)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
            .having((e) => e.message, 'message', contains('is busy'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('unnamed NRC 0x10 is English and quotes the reason code', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 10'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.negativeResponseCode, 'nrc', 0x10)
            .having((e) => e.message, 'message', contains('reason code 0x10'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('Mode 04 response-pending is English and locks retry', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'04': '7E8 03 7F 04 78'}),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.pending)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isTrue)
            .having(
              (e) => e.message,
              'message',
              contains('accepted the clear but has not reported it finished'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
