/// Persisted UI language preference. Independent of vehicle / PID / adapter keys.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_resolution.dart';
import 'pid_registry.dart';

class LocalePreferenceController extends Notifier<LocalePreference> {
  @override
  LocalePreference build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return localePreferenceFromStored(prefs.getString(kLocalePreferenceKey));
  }

  /// Returns false when the store rejects the write. The previous preference
  /// is restored so a failed save is visible and retryable.
  Future<bool> set(LocalePreference preference) async {
    final previous = state;
    state = preference;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final ok = await prefs.setString(
        kLocalePreferenceKey,
        localePreferenceToStored(preference),
      );
      if (!ok) {
        state = previous;
        return false;
      }
      return true;
    } on Object {
      state = previous;
      return false;
    }
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceController, LocalePreference>(
      LocalePreferenceController.new,
    );
