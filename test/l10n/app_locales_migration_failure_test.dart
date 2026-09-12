import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/app_locales_synchronizer.dart';

const _system = AppLocalesSnapshot(
  apiSupported: true,
  sdkInt: 36,
  followsSystem: true,
  overrideTags: [],
  configurationTags: ['de-DE'],
);

const _english = AppLocalesSnapshot(
  apiSupported: true,
  sdkInt: 36,
  followsSystem: false,
  overrideTags: ['en'],
  configurationTags: ['en-US'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({kLocalePreferenceKey: 'en'});
  });

  for (final failure in <String, AppLocalesSnapshot?>{
    'rejected': null,
    'unsupported': AppLocalesSnapshot.unsupported(),
    'unchanged': _system,
    'different override': const AppLocalesSnapshot(
      apiSupported: true,
      sdkInt: 36,
      followsSystem: false,
      overrideTags: ['de'],
      configurationTags: ['de-DE'],
    ),
  }.entries) {
    test(
      '${failure.key} handoff remains retryable without losing stored locale',
      () async {
        final prefs = await SharedPreferences.getInstance();
        var os = _system;
        var attempts = 0;
        final sync = AppLocalesSynchronizer(
          prefs: prefs,
          getOs: () async => os,
          setOs: (_) async {
            attempts += 1;
            if (attempts == 1) return failure.value;
            os = _english;
            return os;
          },
        );

        await sync.sync();
        expect(prefs.getBool(kLocaleOsMigratedKey), isNot(true));
        expect(prefs.getString(kLocalePreferenceKey), 'en');
        await sync.sync();
        expect(attempts, 2);
        expect(prefs.getBool(kLocaleOsMigratedKey), isTrue);
        expect(prefs.getString(kLocalePreferenceKey), 'en');
        await sync.sync();
        expect(attempts, 2);
      },
    );
  }

  test('missing setter cannot commit migration', () async {
    final prefs = await SharedPreferences.getInstance();
    final sync = AppLocalesSynchronizer(
      prefs: prefs,
      getOs: () async => _system,
    );
    await sync.sync();
    await sync.sync();
    expect(prefs.getBool(kLocaleOsMigratedKey), isNot(true));
    expect(prefs.getString(kLocalePreferenceKey), 'en');
  });

  test('throwing setter cannot commit migration', () async {
    final prefs = await SharedPreferences.getInstance();
    final sync = AppLocalesSynchronizer(
      prefs: prefs,
      getOs: () async => _system,
      setOs: (_) async => throw StateError('OS write failed'),
    );
    await expectLater(sync.sync(), throwsStateError);
    expect(prefs.getBool(kLocaleOsMigratedKey), isNot(true));
    expect(prefs.getString(kLocalePreferenceKey), 'en');
  });

  test('migration marker waits for successful OS readback', () async {
    final prefs = await SharedPreferences.getInstance();
    final started = Completer<void>();
    final reply = Completer<AppLocalesSnapshot?>();
    final sync = AppLocalesSynchronizer(
      prefs: prefs,
      getOs: () async => _system,
      setOs: (_) {
        started.complete();
        return reply.future;
      },
    );
    final pending = sync.sync();
    await started.future;
    final markerWhilePending = prefs.getBool(kLocaleOsMigratedKey);
    reply.complete(_english);
    await pending;
    expect(markerWhilePending, isNot(true));
    expect(prefs.getBool(kLocaleOsMigratedKey), isTrue);
  });
}
