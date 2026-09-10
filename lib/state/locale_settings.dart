/// Persisted UI language preference. Independent of vehicle / PID / adapter keys.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_locales_platform.dart';
import '../l10n/app_locales_sync.dart';
import '../l10n/locale_resolution.dart';
import 'pid_registry.dart';

class LocalePreferenceController extends Notifier<LocalePreference> {
  /// Last value known to be in the store. Failures restore to this, not to
  /// the preference that happened to be on screen when this call started —
  /// a slower older write must not wipe a newer selection.
  LocalePreference _committed = LocalePreference.system;

  /// Persist calls run one at a time so two in-flight writes cannot complete
  /// out of order and commit the older one last.
  Future<void> _persistQueue = Future<void>.value();

  /// Each [set] call, including two taps of the same value. Equality of
  /// [state] and [preference] is not identity of the request.
  int _attempt = 0;

  @override
  LocalePreference build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final loaded = localePreferenceFromStored(
      prefs.getString(kLocalePreferenceKey),
    );
    _committed = loaded;
    return loaded;
  }

  /// Returns false when the store rejects the write.
  ///
  /// The screen updates immediately. If this write fails, the screen goes
  /// back to [_committed] only when this call is still the latest [set].
  /// Equal values are not the same request: a second tap of English while
  /// the first save is in flight must not restore System over it.
  Future<bool> set(LocalePreference preference) {
    final attempt = ++_attempt;
    state = preference;
    final done = Completer<bool>();
    _persistQueue = _persistQueue.then((_) async {
      try {
        done.complete(await _persist(preference, attempt));
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }

  Future<bool> _persist(LocalePreference preference, int attempt) async {
    try {
      // After the first-run marker, resume treats LocaleManager as authority.
      // An in-app picker that only wrote SharedPreferences would be clobbered
      // on the next resume. Tests keep [AppLocalesPlatform.live] false so this
      // never waits on an unanswered MethodChannel.
      var wroteOs = false;
      if (AppLocalesPlatform.live) {
        final current = await AppLocalesPlatform.get();
        if (current.apiSupported) {
          final written = await AppLocalesPlatform.setOverrideTags(
            tagsForPreference(preference),
          );
          if (written == null || !written.apiSupported) {
            if (attempt == _attempt) state = _committed;
            return false;
          }
          wroteOs = true;
        }
      }
      final prefs = ref.read(sharedPreferencesProvider);
      final ok = await prefs.setString(
        kLocalePreferenceKey,
        localePreferenceToStored(preference),
      );
      if (!ok) {
        if (attempt == _attempt) state = _committed;
        return false;
      }
      if (wroteOs) {
        await prefs.setBool(kLocaleOsMigratedKey, true);
      }
      _committed = preference;
      return true;
    } on Object {
      if (attempt == _attempt) state = _committed;
      return false;
    }
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceController, LocalePreference>(
      LocalePreferenceController.new,
    );
