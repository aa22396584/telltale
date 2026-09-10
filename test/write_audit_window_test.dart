/// Write-audit windows are per operation, not a shared cleared set.
///
/// Dashboard polling and Mode 04 both ask "did these bytes leave?". Clearing
/// one shared set from each poll batch would let a later `beginWriteAudit`
/// hide a Mode 04 that had already reached the adapter, and the screen would
/// offer an unsafe retry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';

import 'support/fake_elm327.dart';

void main() {
  test(
    'a later poll write-audit does not hide a Mode 04 that already left',
    () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        faults: const AdapterFaults(swallowPromptFor: {'04'}),
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '04': [0x44],
            },
          ),
        ],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      expect(await client.connect(), isTrue);

      final clearAudit = client.beginWriteAudit();
      final pending = client.sendGlobal('04');
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!transport.commandLog.contains('04')) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            '04 never reached the adapter. Commands: ${transport.commandLog}',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // A dashboard poll batch starts its own window while 04 is in flight.
      client.beginWriteAudit();
      expect(
        client.wroteSinceAudit(clearAudit, '04'),
        isTrue,
        reason:
            'Mode 04 already left; a later poll audit must not permit a retry. '
            'Commands: ${transport.commandLog}',
      );
      await expectLater(pending, throwsA(anything));
    },
  );

  test('a new window does not inherit a previous Mode 04 write', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            '04': [0x44],
          },
        ),
      ],
    );
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 400),
    );
    expect(await client.connect(), isTrue);
    final first = client.beginWriteAudit();
    await client.sendGlobal('04');
    expect(client.wroteSinceAudit(first, '04'), isTrue);
    final second = client.beginWriteAudit();
    expect(
      client.wroteSinceAudit(second, '04'),
      isFalse,
      reason: 'the second attempt must not lock a retry on the first write',
    );
  });
}
