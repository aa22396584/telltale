/// Engine headers-off and anonymous-adapter notes are transcript-only English.
///
/// The screen maps [DtcReadException] through kind and `repeatWouldHarm`.
/// These sentences still land in `e.message`. Chinese here leaked into
/// English logs.
///
/// All four cases drive the real engine: a headers-off stored read, a
/// headers-off Mode 04 `44`, a lying-ATH1 stored read, and a lying-ATH1
/// Mode 04 `44`. A hand-built exception would stay green if production
/// kept composing Chinese.
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

FakeElm327 _canEcm({required AdapterFaults faults}) => FakeElm327(
  protocol: BusProtocol.can11,
  faults: faults,
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: {
        ..._physicsReplies(),
        '03': [0x43, 0x00],
        '04': [0x44],
      },
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
  test('a headers-off stored read is English and unattributed', () async {
    final transport = _canEcm(faults: const AdapterFaults(refuseHeaders: true));
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.unattributed)
            .having(
              (e) => e.message,
              'message',
              contains('cannot display reply headers'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a headers-off Mode 04 44 is English and locks retry', () async {
    final transport = _canEcm(
      faults: const AdapterFaults(
        refuseHeaders: true,
        forcedReplies: {'04': '44'},
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
              contains('do not send another clear'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a lying-ATH1 stored read is English and anonymous', () async {
    final transport = _canEcm(
      faults: const AdapterFaults(lieAboutHeaders: true),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having(
              (e) => e.message,
              'message',
              contains('no identifiable source'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a lying-ATH1 Mode 04 44 is English and locks retry', () async {
    final transport = _canEcm(
      faults: const AdapterFaults(
        lieAboutHeaders: true,
        forcedReplies: {'04': '44'},
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
              contains('do not send another clear'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
