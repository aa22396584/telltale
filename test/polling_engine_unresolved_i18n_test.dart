/// Engine unresolved-identity notes are transcript-only English.
///
/// The screen maps [DtcReadException] through kind and structured fields, so
/// these sentences never interpolate onto the panel. They still land in the
/// exported session transcript. Chinese here leaked into English logs the same
/// way the scan-layer notes in `dtc_scan.dart` did.
///
/// Both cases drive the real engine: a hand-built exception would stay green
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

/// A headered legacy line with its checksum, which is what `ATH1` prints.
String _withChecksum(String line, {bool j1850 = false}) {
  final hex = line.replaceAll(' ', '');
  final bytes = [
    for (var i = 0; i + 1 < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
  int crc;
  if (j1850) {
    crc = 0xFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 0x80) != 0
            ? ((crc << 1) ^ 0x1D) & 0xFF
            : (crc << 1) & 0xFF;
      }
    }
    crc = (~crc) & 0xFF;
  } else {
    crc = bytes.fold<int>(0, (a, b) => (a + b) & 0xFF);
  }
  return '$line ${crc.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}

void main() {
  test('a bare-header identity refuses a clear in English', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.j1850vpw,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '686AF1',
          responseId: '486B10',
          responses: {
            ..._physicsReplies(),
            '07': [0x47, 0x00],
          },
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    transport.forceReplySequence('03', [
      '486B18\r${_withChecksum('486B10 43 00 00 00 00 00 00', j1850: true)}',
    ]);
    await engine
        .readDtcs(DtcKind.stored)
        .then<void>((_) {})
        .catchError((Object _) {});

    expect(engine.openIdentityQuestions, contains('18'));
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having(
              (e) => e.message,
              'message',
              contains('unrecognised addresses: 18'),
            )
            .having((e) => e.message, 'message', isNot(contains('未能辨識')))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a clear with a bare identifier and no completion is English', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      faults: const AdapterFaults(
        forcedReplies: {'04': '7E8 03 7F 04 22\r7E9\r<RX ERROR'},
      ),
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            ..._physicsReplies(),
            '03': [0x43, 0x00],
          },
        ),
      ],
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having(
              (e) => e.message,
              'message',
              contains('No controller reported the clear finished'),
            )
            .having(
              (e) => e.message,
              'message',
              contains('unrecognised addresses:'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse)
            .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isTrue),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
