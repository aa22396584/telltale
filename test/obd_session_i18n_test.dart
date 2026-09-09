/// ObdSession disconnect and in-flight-clear notes are transcript-only English.
///
/// The screen maps [DtcReadException] through kind. These sentences still
/// land in `e.message`. Chinese here leaked into English logs.
///
/// Every case drives the real session: `readDtcs` / `readVin` /
/// `readFreezeFrames` with no connection, and a second `clearDtcs` while
/// one is already on the wire. A hand-built exception would stay green if
/// production kept composing Chinese.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import 'support/cjk.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('readDtcs with no connection is English disconnected', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    await expectLater(
      session.readDtcs(DtcKind.stored),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.disconnected)
            .having(
              (e) => e.message,
              'message',
              contains('The connection is down'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
  });

  test('readVin with no connection is English disconnected', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    await expectLater(
      session.readVin(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.disconnected)
            .having(
              (e) => e.message,
              'message',
              contains('The connection is down'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
  });

  test('readFreezeFrames with no connection is English disconnected', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    await expectLater(
      session.readFreezeFrames(),
      throwsA(
        isA<DtcReadException>()
            .having((e) => e.kind, 'kind', DtcReadFailure.disconnected)
            .having(
              (e) => e.message,
              'message',
              contains('dropped before freeze frames were read'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
  });

  test('a second clear while one is in flight is English', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    expect(await session.connectDemo(), isTrue);
    final first = session.clearDtcs();
    await expectLater(
      session.clearDtcs(),
      throwsA(
        isA<DtcReadException>()
            .having(
              (e) => e.message,
              'message',
              contains('A clear is already in progress'),
            )
            .having((e) => chinese.hasMatch(e.message), 'chinese', isFalse),
      ),
    );
    await first;
    await session.disconnect();
  }, timeout: const Timeout(Duration(seconds: 20)));
}
