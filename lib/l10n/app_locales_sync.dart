/// First-run OS vs stored locale migration. Pure: no Flutter, no channel.
///
/// API 33+ [LocaleManager.applicationLocales] is the authority after the one
/// stored-to-OS handoff. An empty OS list is follow-system, not English.
/// Subsequent resumes never write the old stored id onto the OS.
library;

import 'locale_resolution.dart';

const kLocaleOsMigratedKey = 'locale_os_migrated_v1';

enum AppLocalesSyncAction {
  apiUnsupported,
  useOsOverride,
  handoffStoredOnce,
  followSystem,
  alreadyMigratedFollowOs,
}

final class AppLocalesSyncPlan {
  const AppLocalesSyncPlan({
    required this.action,
    required this.storedIdToKeep,
    required this.writeOs,
    required this.writeStored,
    required this.markMigrated,
    this.osTagsToWrite = const [],
  });

  final AppLocalesSyncAction action;
  final String storedIdToKeep;
  final bool writeOs;
  final bool writeStored;
  final bool markMigrated;
  final List<String> osTagsToWrite;
}

List<String> tagsForStoredId(String storedId) {
  return switch (storedId) {
    'en' => const ['en'],
    'zh_Hant' => const ['zh-Hant'],
    'de' => const ['de'],
    _ => const [],
  };
}

List<String> tagsForPreference(LocalePreference preference) {
  return tagsForStoredId(localePreferenceToStored(preference));
}

String storedIdFromSupportedTag(String tag) {
  return switch (tag) {
    'en' => 'en',
    'zh-Hant' => 'zh_Hant',
    'de' => 'de',
    _ => 'system',
  };
}

/// Map a BCP-47 tag onto a shipped UI locale, or null.
String? mapTagToSupported(String raw) {
  final tag = raw.trim().replaceAll('_', '-');
  if (tag.isEmpty) return null;
  final parts = tag.split('-').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final language = parts.first.toLowerCase();
  if (language == 'en') return 'en';
  if (language == 'de') return 'de';
  if (language != 'zh') return null;
  final subtags = parts.skip(1).toList();
  String? script;
  String? region;
  for (final part in subtags) {
    if (part.length == 4) script ??= part.toLowerCase();
    if (part.length == 2) region ??= part.toUpperCase();
  }
  if (script == 'hans') return null;
  if (script == 'hant') return 'zh-Hant';
  if (region == 'TW' || region == 'HK' || region == 'MO') return 'zh-Hant';
  if (subtags.isEmpty) return 'zh-Hant';
  return null;
}

String storedIdFromOsTags(List<String> osOverrideTags) {
  final mapped = <String>{
    for (final tag in osOverrideTags)
      if (mapTagToSupported(tag) != null) mapTagToSupported(tag)!,
  };
  if (mapped.length == 1) return storedIdFromSupportedTag(mapped.single);
  return 'system';
}

/// Decide the writes for one resume. Callers must apply [writeOs] at most
/// once per process for the first-run handoff.
AppLocalesSyncPlan planSync({
  required bool apiSupported,
  required bool alreadyMigrated,
  required bool followsSystem,
  required List<String> osOverrideTags,
  required String storedId,
}) {
  if (!apiSupported) {
    final keep = tagsForStoredId(storedId).isEmpty ? 'system' : storedId;
    return AppLocalesSyncPlan(
      action: AppLocalesSyncAction.apiUnsupported,
      storedIdToKeep: keep,
      writeOs: false,
      writeStored: false,
      markMigrated: false,
    );
  }

  if (!alreadyMigrated) {
    if (!followsSystem && osOverrideTags.any((t) => t.trim().isNotEmpty)) {
      final stored = storedIdFromOsTags(osOverrideTags);
      return AppLocalesSyncPlan(
        action: AppLocalesSyncAction.useOsOverride,
        storedIdToKeep: stored,
        writeOs: false,
        writeStored: storedId != stored,
        markMigrated: true,
      );
    }
    final handoff = tagsForStoredId(storedId);
    if (handoff.isNotEmpty) {
      return AppLocalesSyncPlan(
        action: AppLocalesSyncAction.handoffStoredOnce,
        storedIdToKeep: storedId,
        writeOs: true,
        writeStored: false,
        markMigrated: true,
        osTagsToWrite: handoff,
      );
    }
    return const AppLocalesSyncPlan(
      action: AppLocalesSyncAction.followSystem,
      storedIdToKeep: 'system',
      writeOs: false,
      writeStored: false,
      markMigrated: true,
    );
  }

  if (!followsSystem && osOverrideTags.any((t) => t.trim().isNotEmpty)) {
    final stored = storedIdFromOsTags(osOverrideTags);
    return AppLocalesSyncPlan(
      action: AppLocalesSyncAction.alreadyMigratedFollowOs,
      storedIdToKeep: stored,
      writeOs: false,
      writeStored: storedId != stored,
      markMigrated: false,
    );
  }
  return AppLocalesSyncPlan(
    action: AppLocalesSyncAction.alreadyMigratedFollowOs,
    storedIdToKeep: 'system',
    writeOs: false,
    writeStored: storedId != 'system',
    markMigrated: false,
  );
}
