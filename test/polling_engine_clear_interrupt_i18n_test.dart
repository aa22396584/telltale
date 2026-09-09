/// Clear-interrupt notes are transcript-only English.
///
/// The screen maps [DtcReadException] through kind and `repeatWouldHarm`.
/// These sentences still land in `e.message`. Chinese here leaked into
/// English logs.
///
/// All three cases drive the real engine: a write that fails after `04` left,
/// a failure before `04` left, and an owner-epoch change while waiting.
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

FakeElm327 _canEcm({AdapterFaults faults = const AdapterFaults()}) =>
    FakeElm327(
      protocol: BusProtocol.can11,
      faults: faults,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            ..._physicsReplies(),
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
  test('a clear lost after the write is English and locks retry', () async {
    final transport = _canEcm();
    final engine = await _connect(transport);
    await engine.discoverResponders();
    transport.failWriteAfterAcceptingFor = const {'04'};
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isTrue)
            .having(
              (e) => e.message,
              'message',
              contains('The clear was sent, then the connection dropped'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a clear that never went out is English and safe to retry', () async {
    final transport = _canEcm(
      faults: const AdapterFaults(swallowPromptFor: {'ATH1'}),
    );
    final engine = await _connect(transport);
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
            .having(
              (e) => e.message,
              'message',
              contains('The clear failed before it was sent'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test(
    'an interruption after the clear went out is English and locks retry',
    () async {
      final transport = _canEcm();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 800),
      );
      expect(await client.connect(), isTrue);
      var epoch = 0;
      client.mayTransmit = (owner) => owner == null || owner == epoch;
      final engine = PollingEngine(client)..lifecycleEpoch = () => epoch;
      await engine.discoverResponders();
      transport.slowCommands['04'] = const Duration(milliseconds: 150);
      final clear = engine.clearDtcs();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      epoch++;
      await expectLater(
        clear,
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
      expect(transport.commandLog, contains('04'));
      await engine.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
