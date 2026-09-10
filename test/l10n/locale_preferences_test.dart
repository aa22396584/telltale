import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/pid_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('missing key is system and does not invent a stored locale', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);
    expect(container.read(localePreferenceProvider), LocalePreference.system);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(kLocalePreferenceKey), isNull);
  });

  test('corrupt stored preference falls back to system', () async {
    final container = await containerWith({
      kLocalePreferenceKey: 'not-a-locale',
    });
    addTearDown(container.dispose);
    expect(container.read(localePreferenceProvider), LocalePreference.system);
  });

  test('persisting English survives a new container', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);
    final ok = await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.english);
    expect(ok, isTrue);
    expect(container.read(localePreferenceProvider), LocalePreference.english);

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(kLocalePreferenceKey), 'en');

    final again = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(again.dispose);
    expect(again.read(localePreferenceProvider), LocalePreference.english);
  });

  test('persisting Traditional Chinese uses zh_Hant, not zh_Hans', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);
    await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.traditionalChinese);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
  });

  test('locale write does not clear vehicle, theme, or adapter keys', () async {
    const vehicle = '{"massKg":1400}';
    final container = await containerWith({
      'vehicle_profile_v1': vehicle,
      'theme_mode_v1': 'light',
      'last_adapter_v1': 'kept',
    });
    addTearDown(container.dispose);
    await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.english);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('vehicle_profile_v1'), vehicle);
    expect(prefs.getString('theme_mode_v1'), 'light');
    expect(prefs.getString('last_adapter_v1'), 'kept');
    expect(prefs.getString(kLocalePreferenceKey), 'en');
  });

  test('system stays stored as system, not the computed en', () async {
    final container = await containerWith({kLocalePreferenceKey: 'en'});
    addTearDown(container.dispose);
    await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.system);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(kLocalePreferenceKey), 'system');
    expect(container.read(localePreferenceProvider), LocalePreference.system);
  });

  test('an older failed persist does not overwrite a newer successful one',
      () async {
    // The picker lets the next tap start while the last write is still in
    // flight. Completing the first write with false used to restore the
    // pre-tap value on top of the second selection, even when the second
    // write then succeeded.
    final first = Completer<bool>();
    final second = Completer<bool>();
    var writes = 0;
    final inner = await _prefs({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          _ScriptedPrefs(inner, () {
            writes += 1;
            if (writes == 1) return first.future;
            if (writes == 2) return second.future;
            return Future<bool>.value(true);
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(localePreferenceProvider.notifier);

    final older = controller.set(LocalePreference.english);
    await Future<void>.value();
    expect(container.read(localePreferenceProvider), LocalePreference.english);

    final newer = controller.set(LocalePreference.traditionalChinese);
    await Future<void>.value();
    expect(
      container.read(localePreferenceProvider),
      LocalePreference.traditionalChinese,
    );

    first.complete(false);
    expect(await older, isFalse);
    expect(
      container.read(localePreferenceProvider),
      LocalePreference.traditionalChinese,
      reason: 'the failed English write restored system over Traditional Chinese',
    );

    second.complete(true);
    expect(await newer, isTrue);
    expect(
      container.read(localePreferenceProvider),
      LocalePreference.traditionalChinese,
    );
    expect(inner.getString(kLocalePreferenceKey), 'zh_Hant');
  });

  test('an older persist that throws does not wipe a newer successful persist',
      () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    var writes = 0;
    final inner = await _prefs({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          _ScriptedPrefs(inner, () {
            writes += 1;
            if (writes == 1) return first.future;
            if (writes == 2) return second.future;
            return Future<bool>.value(true);
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(localePreferenceProvider.notifier);

    final older = controller.set(LocalePreference.english);
    await Future<void>.value();
    final newer = controller.set(LocalePreference.traditionalChinese);
    await Future<void>.value();

    first.completeError(StateError('disk'));
    expect(await older, isFalse);
    expect(
      container.read(localePreferenceProvider),
      LocalePreference.traditionalChinese,
    );

    second.complete(true);
    expect(await newer, isTrue);
    expect(
      container.read(localePreferenceProvider),
      LocalePreference.traditionalChinese,
    );
    expect(inner.getString(kLocalePreferenceKey), 'zh_Hant');
  });

  test('two failed persists restore the preference from before the sequence',
      () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    var writes = 0;
    final inner = await _prefs({kLocalePreferenceKey: 'system'});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          _ScriptedPrefs(inner, () {
            writes += 1;
            if (writes == 1) return first.future;
            if (writes == 2) return second.future;
            return Future<bool>.value(true);
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(localePreferenceProvider.notifier);
    expect(container.read(localePreferenceProvider), LocalePreference.system);

    final older = controller.set(LocalePreference.english);
    await Future<void>.value();
    final newer = controller.set(LocalePreference.traditionalChinese);
    await Future<void>.value();

    first.complete(false);
    expect(await older, isFalse);
    second.complete(false);
    expect(await newer, isFalse);

    expect(container.read(localePreferenceProvider), LocalePreference.system);
    expect(inner.getString(kLocalePreferenceKey), 'system');
  });

  test('a second tap of the same language is not restored over by the first',
      () async {
    // `state == preference` treated two English taps as one request, so the
    // first failure restored System while the second write then stored
    // English and left the screen behind.
    final first = Completer<bool>();
    final second = Completer<bool>();
    final env = await _scripted([first, second]);
    addTearDown(env.container.dispose);

    final older = env.controller.set(LocalePreference.english);
    await Future<void>.value();
    final newer = env.controller.set(LocalePreference.english);
    await Future<void>.value();
    expect(env.container.read(localePreferenceProvider), LocalePreference.english);

    first.complete(false);
    expect(await older, isFalse);
    expect(
      env.container.read(localePreferenceProvider),
      LocalePreference.english,
      reason: 'the first English failure restored System over the second tap',
    );

    second.complete(true);
    expect(await newer, isTrue);
    expect(
      env.container.read(localePreferenceProvider),
      LocalePreference.english,
    );
    expect(env.inner.getString(kLocalePreferenceKey), 'en');
  });

  test('switching away and back keeps the latest tap after an older failure',
      () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    final third = Completer<bool>();
    final env = await _scripted([first, second, third]);
    addTearDown(env.container.dispose);

    final a = env.controller.set(LocalePreference.english);
    await Future<void>.value();
    final b = env.controller.set(LocalePreference.traditionalChinese);
    await Future<void>.value();
    final c = env.controller.set(LocalePreference.english);
    await Future<void>.value();
    expect(env.container.read(localePreferenceProvider), LocalePreference.english);

    first.complete(false);
    expect(await a, isFalse);
    expect(
      env.container.read(localePreferenceProvider),
      LocalePreference.english,
      reason: 'English==English let the first failure restore System',
    );

    second.completeError(StateError('disk'));
    expect(await b, isFalse);
    expect(env.container.read(localePreferenceProvider), LocalePreference.english);

    third.complete(true);
    expect(await c, isTrue);
    expect(env.container.read(localePreferenceProvider), LocalePreference.english);
    expect(env.inner.getString(kLocalePreferenceKey), 'en');
  });

  test('mixed false, throw and success still follow the last successful persist',
      () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    final third = Completer<bool>();
    final env = await _scripted([first, second, third]);
    addTearDown(env.container.dispose);

    final a = env.controller.set(LocalePreference.english);
    await Future<void>.value();
    final b = env.controller.set(LocalePreference.traditionalChinese);
    await Future<void>.value();
    final c = env.controller.set(LocalePreference.english);
    await Future<void>.value();

    first.complete(true);
    expect(await a, isTrue);
    second.completeError(StateError('disk'));
    expect(await b, isFalse);
    third.complete(false);
    expect(await c, isFalse);

    // Last successful persist is English (A). C failed while latest, so the
    // screen returns to that committed value, not System and not Chinese.
    expect(env.container.read(localePreferenceProvider), LocalePreference.english);
    expect(env.inner.getString(kLocalePreferenceKey), 'en');
  });

  test('live persist writes LocaleManager so resume cannot clobber it', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(kAppLocalesChannelName);
    List<Object?>? seen;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == kAppLocalesGetMethod) {
        return <String, Object?>{
          'apiSupported': true,
          'sdkInt': 36,
          'followsSystem': true,
          'overrideTags': <String>[],
          'configurationTags': <String>[],
        };
      }
      expect(call.method, kAppLocalesSetMethod);
      seen = (call.arguments as Map)['tags'] as List<Object?>?;
      return <String, Object?>{
        'apiSupported': true,
        'sdkInt': 36,
        'followsSystem': seen!.isEmpty,
        'overrideTags': seen!.cast<String>(),
        'configurationTags': <String>[],
      };
    });
    addTearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      AppLocalesPlatform.live = false;
    });

    AppLocalesPlatform.live = true;
    final container = await containerWith({kLocaleOsMigratedKey: true});
    addTearDown(container.dispose);

    final ok = await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.german);
    expect(ok, isTrue);
    expect(seen, ['de']);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(kLocalePreferenceKey), 'de');
    expect(prefs.getBool(kLocaleOsMigratedKey), isTrue);

    seen = null;
    await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.system);
    expect(seen, isEmpty);
  });

  test('live=false persist does not invoke LocaleManager', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(kAppLocalesChannelName);
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls += 1;
      return null;
    });
    addTearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      AppLocalesPlatform.live = false;
    });
    AppLocalesPlatform.live = false;
    final container = await containerWith({});
    addTearDown(container.dispose);
    final ok = await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.english);
    expect(ok, isTrue);
    expect(calls, 0);
  });
}

class _ScriptedEnv {
  _ScriptedEnv(this.container, this.inner, this.controller);
  final ProviderContainer container;
  final SharedPreferences inner;
  final LocalePreferenceController controller;
}

Future<_ScriptedEnv> _scripted(List<Completer<bool>> gates) async {
  var writes = 0;
  final inner = await _prefs({kLocalePreferenceKey: 'system'});
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        _ScriptedPrefs(inner, () {
          writes += 1;
          if (writes <= gates.length) return gates[writes - 1].future;
          return Future<bool>.value(true);
        }),
      ),
    ],
  );
  return _ScriptedEnv(
    container,
    inner,
    container.read(localePreferenceProvider.notifier),
  );
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Forwards every [SharedPreferences] call except [setString], which is gated
/// so two overlapping [LocalePreferenceController.set] calls can complete in
/// a chosen order with chosen outcomes.
class _ScriptedPrefs implements SharedPreferences {
  _ScriptedPrefs(this._inner, this._onWrite);

  final SharedPreferences _inner;
  final Future<bool> Function() _onWrite;

  @override
  Future<bool> setString(String key, String value) async {
    final ok = await _onWrite();
    if (!ok) return false;
    return _inner.setString(key, value);
  }

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
