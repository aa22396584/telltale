/// Applies [planSync] against SharedPreferences and an injectable OS getter.
///
/// The real LocaleManager channel is only used when the caller passes it.
/// Widget tests that change language without a mock must not go through this.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_locales_platform.dart';
import '../l10n/app_locales_sync.dart';
import '../l10n/locale_resolution.dart';

typedef AppLocalesGetter = Future<AppLocalesSnapshot> Function();
typedef AppLocalesSetter = Future<AppLocalesSnapshot?> Function(
  List<String> tags,
);

final class AppLocalesSynchronizer {
  AppLocalesSynchronizer({
    required this.prefs,
    required this.getOs,
    this.setOs,
  });

  final SharedPreferences prefs;
  final AppLocalesGetter getOs;
  final AppLocalesSetter? setOs;

  int osWriteCount = 0;
  int storedWriteCount = 0;

  Future<AppLocalesSyncPlan> sync() async {
    final os = await getOs();
    final storedId = prefs.getString(kLocalePreferenceKey) ?? 'system';
    final alreadyMigrated = prefs.getBool(kLocaleOsMigratedKey) == true;
    final plan = planSync(
      apiSupported: os.apiSupported,
      alreadyMigrated: alreadyMigrated,
      followsSystem: os.followsSystem,
      osOverrideTags: os.overrideTags,
      storedId: storedId,
    );
    if (plan.writeStored) {
      storedWriteCount += 1;
      await prefs.setString(kLocalePreferenceKey, plan.storedIdToKeep);
    }
    if (plan.writeOs) {
      final setter = setOs;
      if (setter == null) {
        return plan;
      }
      osWriteCount += 1;
      final written = await setter(plan.osTagsToWrite);
      // A timeout, refusal, or unchanged OS snapshot is not a handoff. Keep
      // the stored preference retryable instead of letting the next resume
      // replace it with the OS's still-empty (follow-system) override.
      if (written == null ||
          !written.apiSupported ||
          written.followsSystem ||
          storedIdFromOsTags(written.overrideTags) != plan.storedIdToKeep) {
        return plan;
      }
    }
    if (plan.markMigrated) {
      await prefs.setBool(kLocaleOsMigratedKey, true);
    }
    return plan;
  }

  LocalePreference storedPreference() =>
      localePreferenceFromStored(prefs.getString(kLocalePreferenceKey));
}
