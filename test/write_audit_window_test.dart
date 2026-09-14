/// Write-audit windows are per operation, not a shared cleared set.
///
/// Dashboard polling and Mode 04 both ask "did these bytes leave?". Clearing
/// one shared set from each poll batch would let a later `beginWriteAudit`
/// hide a Mode 04 that had already reached the adapter, and the screen would
/// offer an unsafe retry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

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
      final pending = client.sendGlobal('04', writeAudit: clearAudit);
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

  test('a queued send cannot be borrowed by a later audit', () async {
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
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);
    addTearDown(client.disconnect);
    final first = client.beginWriteAudit();
    final pending = client.sendGlobal('04', writeAudit: first);
    final unrelated = client.beginWriteAudit();
    await pending;
    expect(client.wroteSinceAudit(first, '04'), isTrue);
    expect(
      client.wroteSinceAudit(unrelated, '04'),
      isFalse,
      reason: 'the later operation did not enqueue or write this command',
    );
  });

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
    await client.sendGlobal('04', writeAudit: first);
    expect(client.wroteSinceAudit(first, '04'), isTrue);
    final second = client.beginWriteAudit();
    expect(
      client.wroteSinceAudit(second, '04'),
      isFalse,
      reason: 'the second attempt must not lock a retry on the first write',
    );
  });
  for (final protocol in BusProtocol.values) {
    test(
      'receipts follow global and default sends on ${protocol.name}',
      () async {
        final transport = FakeElm327(
          protocol: protocol,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: protocol.engineHeader,
              responseId: protocol.isCan
                  ? (protocol.is29Bit ? '18DAF110' : '7E8')
                  : '486B10',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '04': [0x44],
              },
            ),
          ],
        );
        final client = Elm327Client(transport);
        expect(await client.connect(), isTrue);
        addTearDown(client.disconnect);
        final global = client.beginWriteAudit();
        final defaultSend = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: global);
        await client.sendAddressed('7E0', '0100', writeAudit: defaultSend);
        expect(client.wroteSinceAudit(global, '04'), isTrue);
        expect(client.wroteSinceAudit(global, '0100'), isFalse);
        expect(client.wroteSinceAudit(defaultSend, '0100'), isTrue);
        expect(client.wroteSinceAudit(defaultSend, '04'), isFalse);
      },
    );
  }

  test('a synchronously refused addressed send consumes its receipt', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.j1850vpw,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '6C10F1',
          responseId: '486B10',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);
    addTearDown(client.disconnect);
    await client.sendOnHeader('6C10F1', '0100');
    final refused = client.beginWriteAudit();
    final before = List<String>.of(transport.commandLog);
    expect(
      () => client.sendAddressed('7E0', '0100', writeAudit: refused),
      throwsA(isA<UnaddressableRequestException>()),
    );
    expect(client.wroteSinceAudit(refused, '0100'), isFalse);
    await expectLater(
      Future.sync(() => client.send('0100', writeAudit: refused)),
      throwsArgumentError,
    );
    expect(transport.commandLog, before);
    expect(client.wroteSinceAudit(refused, '0100'), isFalse);
  });

  group('explicit operation receipts', () {
    late FakeElm327 transport;
    late Elm327Client client;
    setUp(() async {
      transport = FakeElm327(
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
      client = Elm327Client(transport);
      expect(await client.connect(), isTrue);
    });
    tearDown(() => client.disconnect());

    test('unassociated commands never populate an open receipt', () async {
      final audit = client.beginWriteAudit();
      await client.sendGlobal('04');
      expect(client.wroteSinceAudit(audit, '04'), isFalse);
    });

    test(
      'receipt belongs to its send, not audit creation or queue order',
      () async {
        final first = client.beginWriteAudit();
        final second = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: second);
        transport.refuseWriteBeforeAcceptingFor = const {'04'};
        await expectLater(
          client.sendGlobal('04', writeAudit: first),
          throwsA(anything),
        );
        expect(client.wroteSinceAudit(first, '04'), isFalse);
        expect(client.wroteSinceAudit(second, ' 04 '), isTrue);
      },
    );

    test('direct and addressed sends record only their own receipt', () async {
      final direct = client.beginWriteAudit();
      final addressed = client.beginWriteAudit();
      await client.send('0100', writeAudit: direct);
      expect(client.wroteSinceAudit(direct, '0100'), isTrue);
      expect(client.wroteSinceAudit(addressed, '0100'), isFalse);
      await client.sendAddressed('7E0', '0100', writeAudit: addressed);
      expect(client.wroteSinceAudit(addressed, '0100'), isTrue);
      expect(client.wroteSinceAudit(addressed, 'ATSH7E0'), isTrue);
    });

    test(
      'reusing a receipt is refused before another wire operation',
      () async {
        final audit = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: audit);
        // Wait until the global exchange has restored headers.
        await client.send('ATRV');
        final before = List<String>.of(transport.commandLog);
        expect(
          () => client.sendGlobal('04', writeAudit: audit),
          throwsArgumentError,
        );
        expect(transport.commandLog, before);
        expect(client.wroteSinceAudit(audit, '04'), isTrue);
        expect(client.wroteSinceAudit(audit, 'ATH0'), isTrue);
      },
    );

    test('a receipt cannot be used or read through a different client', () {
      final other = Elm327Client(
        FakeElm327(protocol: BusProtocol.can11, ecus: []),
      );
      final foreign = other.beginWriteAudit();
      final before = List<String>.of(transport.commandLog);
      expect(() => client.send('04', writeAudit: foreign), throwsArgumentError);
      expect(() => client.wroteSinceAudit(foreign, '04'), throwsArgumentError);
      expect(transport.commandLog, before);
    });
  });
}
