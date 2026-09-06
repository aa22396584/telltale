import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
