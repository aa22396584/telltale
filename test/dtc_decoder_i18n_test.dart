/// Fault-code decoder refusals are transcript-only English.
///
/// [DtcDecoder.decodeResponse] used to throw Traditional Chinese [StateError]
/// text. Polling swallows that type so one damaged controller cannot hide the
/// next, but the sentence is still `e.message` if anything wraps it, and it is
/// the diagnosis itself. #45 leftover: keep elm327/serial/polling
/// [DtcReadException] English; these decoder refusals are the same layer.
///
/// Every case drives [DtcDecoder.decodeResponse] or [PollingEngine.readDtcs].
/// A hand-built exception would stay green if production kept composing
/// Chinese. Intentional transcript Chinese (`DtcKind.transcriptLabel`) is
/// not in these sentences.
library;

import 'dart:io';

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
  expect(await client.connect(), isTrue);
  return PollingEngine(client);
}

void _expectEnglishRefusal(
  List<int> bytes, {
  bool hasCountByte = true,
  required String fragment,
}) {
  try {
    DtcDecoder.decodeResponse(
      bytes,
      DtcKind.stored,
      hasCountByte: hasCountByte,
    );
    fail('expected a StateError for $bytes');
  } on StateError catch (e) {
    expect(chinese.hasMatch(e.message), isFalse, reason: e.message);
    expect(e.message, contains(fragment), reason: e.message);
  }
}

void main() {
  test('a CAN reply that is only the service byte is English', () {
    _expectEnglishRefusal(
      [0x43],
      fragment: 'service byte',
    );
  });

  test('a CAN reply shorter than its declared count is English', () {
    _expectEnglishRefusal(
      [0x43, 0x02, 0x03],
      fragment: 'declared 2',
    );
  });

  test('data past the declared window is English', () {
    _expectEnglishRefusal(
      [0x43, 0x00, 0xFF],
      fragment: 'past that window',
    );
  });

  test('an odd remainder on a legacy reply is English', () {
    _expectEnglishRefusal(
      [0x43, 0xFF],
      hasCountByte: false,
      fragment: 'odd',
    );
  });

  test('a declared count the decoder cannot honour is English', () {
    _expectEnglishRefusal(
      [0x43, 0x01, 0x00, 0x00],
      fragment: 'decoded 0',
    );
  });

  test('a damaged CAN frame still yields an English DtcReadException', () async {
    final transport = _can(
      faults: const AdapterFaults(
        forcedReplies: {'03': '7E8 03 43 01 03'},
      ),
    );
    final engine = await _connect(transport);
    await engine.discoverResponders();
    await expectLater(
      engine.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>().having(
          (e) => chinese.hasMatch(e.message),
          'chinese in DtcReadException.message',
          isFalse,
        ),
      ),
    );
    await engine.dispose();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('elm327/serial/polling DtcReadException literals stay English', () {
    const paths = [
      'lib/obd/polling_engine.dart',
      'lib/obd/elm327_client.dart',
      'lib/obd/transport/serial_transport.dart',
      'lib/obd/dtc/dtc.dart',
    ];
    final quoted = RegExp(r'''(?:throw\s+(?:const\s+)?(?:DtcReadException|StateError)\s*\(\s*)((?:'[^']*'|"[^"]*"|''' r"""'''[\s\S]*?'''""" r'''|"""[\s\S]*?"""|\s|\+|r'[^']*'|r"[^"]*")+)''');
    for (final path in paths) {
      final src = File(path).readAsStringSync();
      for (final match in quoted.allMatches(src)) {
        final blob = match.group(1)!;
        expect(
          chinese.hasMatch(blob),
          isFalse,
          reason: '$path still composes Chinese in $blob',
        );
      }
    }
  });
}
