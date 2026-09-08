/// #45 leftover: ATZ dying with InitNote.unexpected is not "adapter silent".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';

import '../support/cjk.dart';

final _en = lookupAppLocalizations(englishLocale);

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

/// Connects, then throws a non-transport, non-timeout error on the first write.
///
/// That is the ATZ path that becomes [InitNote.unexpected]. Calling it
/// "adapter silent on reset" tells the driver the device is not an ELM327.
class _UnexpectedOnReset extends BaseObdTransport {
  @override
  TransportKind get kind => TransportKind.wifi;

  @override
  String get displayName => 'unexpected-reset';

  @override
  Future<void> connect() async {
    setConnected(true);
  }

  @override
  Future<void> disconnect() async {
    setConnected(false);
  }

  @override
  Future<void> write(List<int> data) async {
    throw StateError('連線已中斷。');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an unexpected exception on ATZ is not diagnosed as a silent adapter',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);

      final ok = await session.connectForTest(
        _UnexpectedOnReset(),
        TransportKind.wifi,
      );
      expect(ok, isFalse);

      final state = container.read(obdSessionProvider);
      expect(state.phase, ConnectionPhase.failed);
      expect(
        state.issue,
        ObdConnectionIssue.handshakeStepFailed,
        reason:
            'issueStep note=${state.issueStep?.note} '
            'detail=${state.issueStep?.detail} '
            'steps=${state.initSteps.map((s) => '${s.index}:${s.status}:${s.note}').toList()}',
      );
      expect(state.issue, isNot(ObdConnectionIssue.adapterSilentOnReset));
      expect(state.issueStep?.note, InitNote.unexpected);
      expect(state.issueStep?.index, 0);

      final banner = connectionIssueText(_en, state)!;
      expect(banner, contains(_en.handshakeNoteUnexpected));
      expect(
        banner,
        isNot(contains(_en.connectIssueAdapterSilentOnReset('ATZ'))),
      );
      expect(banner, isNot(contains('StateError')));
      expect(banner, isNot(contains('連線已中斷')));
      expect(chinese.hasMatch(banner), isFalse);
    },
  );
}
