/// Software path for #43: OS vs stored migration and language-switch guard.
///
/// These tests drive [planSync] and [AppLocalesSynchronizer] with a fake OS.
/// They are not an Android process recreation.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/l10n/generated/app_localizations_zh.dart';
import 'package:torque_obd/state/app_locales_synchronizer.dart';
import 'package:torque_obd/state/language_switch_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('planSync first run', () {
    test('API 32 does not write the OS or clobber a stored id', () {
      final plan = planSync(
        apiSupported: false,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.apiUnsupported);
      expect(plan.writeOs, isFalse);
      expect(plan.markMigrated, isFalse);
      expect(plan.writeStored, isFalse);
      expect(plan.storedIdToKeep, 'en');
    });

    test('an explicit OS override wins and is not overwritten by stored', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: false,
        osOverrideTags: const ['de-DE'],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.useOsOverride);
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'de');
      expect(plan.writeStored, isTrue);
      expect(plan.markMigrated, isTrue);
    });

    test('an empty OS list hands off a stored explicit preference once', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'zh_Hant',
      );
      expect(plan.action, AppLocalesSyncAction.handoffStoredOnce);
      expect(plan.writeOs, isTrue);
      expect(plan.osTagsToWrite, ['zh-Hant']);
      expect(plan.writeStored, isFalse);
      expect(plan.markMigrated, isTrue);
    });

    test('empty stored does not overwrite follow-system', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'system',
      );
      expect(plan.action, AppLocalesSyncAction.followSystem);
      expect(plan.writeOs, isFalse);
      expect(plan.markMigrated, isTrue);
    });

    test('an OS override we do not ship still wins', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: false,
        osOverrideTags: const ['ja'],
        storedId: 'en',
      );
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'system');
    });
  });

  group('planSync after the one-time marker', () {
    test('a later resume never writes stored back onto the OS', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: true,
        followsSystem: false,
        osOverrideTags: const ['de'],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.alreadyMigratedFollowOs);
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'de');
    });

    test('OS follow-system after migrate clears a leftover stored id', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: true,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'en',
      );
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'system');
      expect(plan.writeStored, isTrue);
    });
  });

  group('AppLocalesSynchronizer', () {
    test('handoff writes OS once; a second resume does not', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      var osTags = <String>[];
      var followsSystem = true;
      final writes = <List<String>>[];
      final sync = AppLocalesSynchronizer(
        prefs: prefs,
        getOs: () async => AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: followsSystem,
          overrideTags: osTags,
          configurationTags: const ['en-US'],
        ),
        setOs: (tags) async {
          writes.add(List<String>.from(tags));
          osTags = List<String>.from(tags);
          followsSystem = tags.isEmpty;
          return AppLocalesSnapshot(
            apiSupported: true,
            sdkInt: 36,
            followsSystem: followsSystem,
            overrideTags: osTags,
            configurationTags: osTags,
          );
        },
      );

      final first = await sync.sync();
      expect(first.action, AppLocalesSyncAction.handoffStoredOnce);
      expect(sync.osWriteCount, 1);
      expect(writes, [
        ['en'],
      ]);
      expect(prefs.getBool(kLocaleOsMigratedKey), isTrue);

      final second = await sync.sync();
      expect(second.action, AppLocalesSyncAction.alreadyMigratedFollowOs);
      expect(sync.osWriteCount, 1);
      expect(writes, hasLength(1));
    });

    test('after migrate, an OS change updates stored and does not write OS',
        () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final sync = AppLocalesSynchronizer(
        prefs: prefs,
        getOs: () async => const AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: false,
          overrideTags: ['de'],
          configurationTags: ['de-DE'],
        ),
        setOs: (tags) async {
          fail('must not write OS after migrate: $tags');
        },
      );
      final plan = await sync.sync();
      expect(plan.writeOs, isFalse);
      expect(prefs.getString(kLocalePreferenceKey), 'de');
      expect(sync.osWriteCount, 0);
    });
  });

  group('languageSwitchBlock', () {
    test('recording blocks before a dirty editor', () {
      expect(
        languageSwitchBlock(
          recording: true,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: true,
        ),
        LanguageSwitchBlock.recording,
      );
    });

    test('a dirty PID editor blocks when nothing else is in flight', () {
      expect(
        languageSwitchBlock(
          recording: false,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: true,
        ),
        LanguageSwitchBlock.pidEditorDirty,
      );
    });

    test('clear path is none', () {
      expect(
        languageSwitchBlock(
          recording: false,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: false,
        ),
        LanguageSwitchBlock.none,
      );
    });

    test('TorqueApp and the picker are wired to sync and the guard', () {
      final app = File('lib/app.dart').readAsStringSync();
      expect(app, contains('_syncAppLocales'));
      expect(app, contains('onResume: _onResume'));
      expect(app, contains('didChangeLocales'));
      final picker = File(
        'lib/ui/widgets/language_picker.dart',
      ).readAsStringSync();
      expect(picker, contains('languageSwitchBlockProvider'));
      expect(picker, isNot(contains('force-stop')));
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('AppLocalesPlatform.live = true'));
    });

    test('copy is localized, not a raw identifier', () {
      final en = AppLocalizationsEn();
      final zh = AppLocalizationsZhHant();
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.recording),
        en.telemetryBlockedByRecorder,
      );
      expect(
        languageSwitchBlockText(zh, LanguageSwitchBlock.recording),
        zh.telemetryBlockedByRecorder,
      );
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.pidEditorDirty),
        en.pidEditorDiscardBody,
      );
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.recording),
        isNot('LanguageSwitchBlock.recording'),
      );
    });
  });
}
