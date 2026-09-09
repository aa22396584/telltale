/// ELM327 client notes and pre-wire refusals are transcript-only English.
///
/// The screen maps `TransportIssue.operationRetired` through ARB. These
/// sentences still land in `e.message` and in the transcript. Chinese here
/// leaked into English logs.
///
/// Every case drives the real client: connect, a retired lease, a deadline
/// that already passed, and `queryPid` before handshake. A hand-built
/// exception would stay green if production kept composing Chinese.
///
/// `TransportKind.demo` keeps `Demo 模擬器` on purpose (evidence comparability).
/// The connect-note test therefore pins the prefix, not "no CJK anywhere".
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/cjk.dart';
import 'support/fake_elm327.dart';

Map<String, List<int>> _physicsReplies() => {
  '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
  '0120': [0x41, 0x20, 0x80, 0x00, 0x00, 0x01],
  '0140': [0x41, 0x40, 0x40, 0x00, 0x00, 0x00],
  '010C': [0x41, 0x0C, 0x1A, 0xF8],
};

FakeElm327 _can() => FakeElm327(
  protocol: BusProtocol.can11,
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: _physicsReplies(),
    ),
  ],
);

void main() {
  test('connect records an English established-connection note', () async {
    final transport = _can();
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 200),
    );
    expect(await client.connect(), isTrue);
    final notes = client.transcript.entries
        .where((e) => e.direction == TranscriptDirection.note)
        .map((e) => e.note ?? '')
        .toList();
    expect(
      notes.any((n) => n.contains('Connection established')),
      isTrue,
      reason: notes.join(' | '),
    );
    expect(notes.any((n) => n.contains('連線建立')), isFalse);
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a retired lease is English and never reaches the wire', () async {
    final transport = _can();
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 200),
    );
    expect(await client.connect(), isTrue);
    client.mayTransmit = (_) => false;
    await expectLater(
      client.send('010C'),
      throwsA(
        isA<OperationRetiredException>()
            .having(
              (e) => e.message,
              'message',
              contains('ended or gone to the background'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    expect(transport.commandLog, isNot(contains('010C')));
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test(
    'a deadline already passed is English and never reaches the wire',
    () async {
      final transport = _can();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
      );
      expect(await client.connect(), isTrue);
      await expectLater(
        client.sendGlobal(
          '03',
          deadline: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        throwsA(
          isA<TimeoutException>()
              .having((e) => e.message, 'message', contains('03 was not sent'))
              .having(
                (e) => chinese.hasMatch(e.message ?? ''),
                'chinese',
                isFalse,
              ),
        ),
      );
      expect(transport.commandLog, isNot(contains('03')));
      await client.disconnect();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('queryPid before handshake is an English StateError', () async {
    final transport = _can();
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 200),
    );
    expect(
      () => client.queryPid('010C'),
      throwsA(
        isA<StateError>()
            .having((e) => e.message, 'message', contains('not initialized'))
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    expect(transport.commandLog, isEmpty);
  });
}
