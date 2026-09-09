/// Engine freeze-frame unread and VIN-conflict notes are transcript-only
/// English.
///
/// The screen maps freeze-frame failure through kind (and its own ARB hedge).
/// VIN conflict is [VinIdentityConflictException]. These sentences still land
/// in `e.message`. Chinese here leaked into English logs.
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

/// Datasheet p.43 CAN VIN, headers on, ISO-TP PCI in place of `N:` prefixes.
const _canVinLines = [
  '7E8 10 14 49 02 01 31 44 34',
  '7E8 21 47 50 30 30 52 35 35',
  '7E8 22 42 31 32 33 34 35 36',
];

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
  test('an unread freeze frame is English and not an absence claim', () async {
    final transport = _can(
      faults: const AdapterFaults(forcedReplies: {'020200': 'NO DATA'}),
    );
    final engine = await _connect(transport);
    await expectLater(
      engine.readFreezeFrames(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.noAnswer)
            .having(
              (e) => e.message,
              'message',
              contains('did not read a freeze frame'),
            )
            .having(
              (e) => e.message,
              'message',
              contains('does not mean the vehicle has none'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('two different CAN VINs is English identity conflict', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
          },
          literalResponses: {
            '0902': [
              ..._canVinLines,
              '7E9 10 14 49 02 01 31 44 34',
              '7E9 21 47 50 30 30 52 35 35',
              '7E9 22 42 31 32 33 34 35 37',
            ],
          },
        ),
      ],
    );
    final engine = await _connect(transport);
    await expectLater(
      engine.readVin(),
      throwsA(
        isA<VinIdentityConflictException>()
            .having(
              (e) => e.message,
              'message',
              contains('different vehicle identification numbers'),
            )
            .having(
              (e) => e.message,
              'message',
              contains('cannot be confirmed'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
