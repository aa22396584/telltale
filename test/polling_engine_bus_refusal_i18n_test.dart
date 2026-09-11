/// A J1939 bus refusal must reach the panel as mapped copy, not generic error.
///
/// `_busRefusal` already writes an English transcript sentence. The scan
/// threw that as a bare [DtcReadException] with no [TransportIssue], so
/// [dtcCategoryFailureText] fell through to [AppLocalizations.dtcCategoryError]
/// in every locale while the only copy of "SAE J1939" lived in the transcript.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_copy.dart';

import 'support/cjk.dart';
import 'support/fake_elm327.dart';

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
  test(
    'a J1939 fault-code refusal maps ARB, not generic category error',
    () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can29,
        forceProtocolNumber: 'A',
        ecus: [
          FakeEcu(
            name: 'bridge',
            requestId: '18DA10F1',
            responseId: '18DAF110',
            responses: const {
              '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
            },
          ),
        ],
      );
      final engine = await _connect(transport);
      late DtcReadException failure;
      try {
        await engine.readDtcs(DtcKind.stored);
        fail('J1939 must refuse Mode 03 rather than decode it');
      } on DtcReadException catch (e) {
        failure = e;
      }
      expect(failure.message, contains('This bus is SAE J1939'));
      expect(failure.message.contains('Reconnect'), isFalse);
      expect(chinese.hasMatch(failure.message), isFalse);
      expect(failure.transportIssue, TransportIssue.busNotObd2);
      expect(failure.issueDetail, 'J1939');
      final en = AppLocalizationsEn();
      final panel = dtcCategoryFailureText(en, failure);
      expect(panel, en.commandFailureBusJ1939);
      expect(panel, isNot(en.dtcCategoryError));
      expect(chinese.hasMatch(panel), isFalse);
      await engine.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
