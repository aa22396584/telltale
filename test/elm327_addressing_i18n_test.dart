/// Addressing refusals are English on the exception itself.
///
/// The screen maps [TransportIssue] through ARB. These sentences still land in
/// `TransportException.message` and in English logs. Chinese here leaked the
/// same way handshake wrappers did.
///
/// Both cases drive the real client: `refuseHeaderSwitch` is the adapter
/// behaviour, not a hand-built exception.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/cjk.dart';
import 'support/fake_elm327.dart';

Future<Elm327Client> _connect(FakeElm327 transport) async {
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
  return client;
}

FakeElm327 _canThatRefusesHeaderSwitch() => FakeElm327(
  protocol: BusProtocol.can11,
  faults: const AdapterFaults(refuseHeaderSwitch: true),
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: const {
        '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
      },
    ),
  ],
);

void main() {
  test('a refused physical header is English', () async {
    final client = await _connect(_canThatRefusesHeaderSwitch());
    await expectLater(
      client.sendOnHeader('7E1', '010C'),
      throwsA(
        isA<TransportException>()
            .having((e) => e.issue, 'issue', TransportIssue.queryHeaderRefused)
            .having((e) => e.issueDetail, 'issueDetail', '7E1')
            .having(
              (e) => e.message,
              'message',
              contains('refused to switch header 7E1'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('a refused functional header is English', () async {
    final client = await _connect(_canThatRefusesHeaderSwitch());
    await expectLater(
      client.sendGlobal('03'),
      throwsA(
        isA<TransportException>()
            .having(
              (e) => e.issue,
              'issue',
              TransportIssue.wholeVehicleHeaderRefused,
            )
            .having((e) => e.issueDetail, 'issueDetail', '7DF')
            .having(
              (e) => e.message,
              'message',
              contains('functional addressing 7DF'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await client.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
