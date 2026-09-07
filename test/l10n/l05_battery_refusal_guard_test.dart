// The experimental battery laboratory's refusals, in both languages.
//
// `PowertrainExperimentalProbeConsents.authorize` used to answer with a
// Traditional Chinese sentence, which the screen wrapped in a localized frame.
// An English driver who tapped "read once" and was refused got
// `Not authorized: 目錄完整性雜湊無效` — the frame translated, the reason not.
//
// What this file asserts is deliberately NOT "the switch returns what the ARB
// holds". A test that reads its expectation back out of `AppLocalizations` — or
// out of the function under test — agrees with itself: transposing two arms of
// the switch preserves uniqueness, non-emptiness, both-language presence and
// the absence of Chinese in English, so every property that shape can measure
// survives the defect. The table below is typed out by hand, and swapping two
// arms turns it red. That was run, not assumed.
//
// A copy table pins one link of a four-link chain:
//
//     condition  ->  identifier  ->  sentence  ->  the values in the sentence
//
// Pinning the identifier->sentence link moves the hole rather than closing it.
// The condition->identifier link is the one this slice *created a boundary
// across*: before it, the trigger and its words sat on adjacent lines, so a
// diff reader saw the pair; now the trigger is in `lib/state/` and the words
// are in `lib/ui/`. A reviewer replaced five arms of `authorize()` with
// `labClosed` and the whole suite stayed green — a driver refused because
// their profile is not in the verified catalog was told the laboratory had
// been switched off. `the engine picks the right identifier` below drives
// `authorize()` through each condition and names the identifier it must
// return, so that mutation is red.
//
// The two scans are the other half. One holds the engine to identifiers: no
// refusal may be constructed from a sentence. The other holds
// `lib/state/powertrain_battery_profiles.dart` to having no Chinese in any
// string literal — through the shared comment- and string-aware reader in
// `test/support/dart_source_reader.dart`, because this repository's Chinese
// *comments* are normal and a naive scan would flag them.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_catalog_validator.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_wire_contract.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/powertrain_battery_experiments.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_copy.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';

/// Every file the catalog screen's refusal paths pass through, whose string
/// literals must therefore hold no Chinese.
///
/// It read `_profiles` alone, and that is exactly how a bare
/// `const kPidMutationLockedMessage = '請先停止並儲存'` in
/// `lib/state/pid_mutation_lock.dart` — snacked by this very screen, four
/// lines above the install-failure path this slice was tracing — survived a
/// slice whose thesis is "no localized frame around unlocalized Chinese".
/// A guard scoped to one file is honest about its scope and still shaped like
/// the defect it exists to remove.
///
/// Three things on this path are deliberately outside the list, because a
/// guard that fails on work nobody has done yet gets an exception list rather
/// than a fix:
///
///   * `lib/state/pid_registry.dart` — `PidImportOutcome.describe` composes
///     the CSV-import snackbar out of Chinese sentence fragments joined with
///     `、`. That is a real defect of the same family, on the PID import path
///     rather than this screen's refusal path, and it is a slice of its own.
///   * `powertrain_battery_catalog_screen.dart:197`'s
///     `l10n.powertrainInstallFailed(error.message)`, where `error.message` is
///     English developer prose from `profile_pid_installer.dart` and
///     `pid_registry.dart`. Mirror image of the same defect — a Chinese reader
///     gets English — and excluded by this slice's brief. It is not a Chinese
///     literal, so this scan would not see it either way; it is named here so
///     the exclusion is a decision rather than an oversight.
///   * `powertrain_battery_catalog_screen.dart:530`'s
///     `Text('${result.failure?.name}: ${result.detail}')` in the probe-result
///     dialog. Same class as the entry above, same screen, same probe path,
///     three lines from code this slice rewrote: `failure.name` is an English
///     enum identifier and `detail` is English developer prose from
///     `powertrain_battery_probe.dart` (`'decoder invariant failed; this
///     profile is quarantined'`), both shown verbatim to a Chinese driver.
///     Also invisible to this scan — the Chinese reader's half of the defect
///     leaves no Chinese literal behind — so it too is listed rather than
///     left to be discovered as an omission. It needs a refusal identifier
///     per `PowertrainBatteryProbeFailure` before it can be localized,
///     which is a slice of its own and not this one.
const _refusalPath = <String>[
  'lib/state/powertrain_battery_profiles.dart',
  'lib/state/pid_mutation_lock.dart',
  'lib/ui/screens/pids/powertrain_battery_catalog_screen.dart',
  'lib/ui/screens/pids/powertrain_battery_copy.dart',
  'lib/ui/screens/pids/pid_mutation_copy.dart',
];

/// How many `PowertrainExperimentalConsentDecision.refused(` constructions the
/// scan below must still find: the constructor's own declaration, plus the six
/// `return`s in `authorize()`.
const _refusalConstructionSites = 7;

/// The attempt cap the hand-typed table below was written against.
///
/// Not `maxAttemptsPerCommand`: reading the constant would let the table agree
/// with whatever the policy currently says, and the placeholder test below
/// exists precisely to prove the number is rendered rather than spelled into
/// the copy.
const _cap = 3;

/// Every refusal, with the sentence it must produce, typed out here by hand.
///
/// Nothing in this map is read back from the ARB, from `AppLocalizations` or
/// from `powertrainProbeRefusalText`. That is the whole point: it is the only
/// assertion in the file that a transposed switch arm cannot survive.
const Map<PowertrainProbeRefusal, (String, String)> _expected = {
  PowertrainProbeRefusal.labClosed: (
    'The experimental battery laboratory was switched off before this read '
        'could be authorized.',
    '在這次讀取取得授權之前，大電池證據實驗室已被關閉。',
  ),
  PowertrainProbeRefusal.catalogHashInvalid: (
    "Not authorized: the catalog's integrity hash is not valid, so nothing in "
        'it can be read.',
    '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。',
  ),
  PowertrainProbeRefusal.profileNotInCatalog: (
    'Not authorized: this profile is not in the verified catalog.',
    '未授權：這個設定檔不在已驗證的目錄中。',
  ),
  PowertrainProbeRefusal.profileNotProbeable: (
    'Not authorized: this profile is not one that can be read once '
        'experimentally.',
    '未授權：這個設定檔不是可以單次實驗讀取的設定檔。',
  ),
  PowertrainProbeRefusal.profileFailedValidation: (
    'Not authorized: this profile did not pass catalog validation with the '
        'model year you chose.',
    '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。',
  ),
  PowertrainProbeRefusal.commandNotInProfile: (
    'Not authorized: that command is not one of this verified profile\'s own '
        'commands.',
    '未授權：這個指令不屬於這份已驗證設定檔本身的指令。',
  ),
  PowertrainProbeRefusal.quarantinedAtAttemptCap: (
    'Quarantined for this connection: the same command has already been tried '
        '3 times. Reconnect before trying again.',
    '本次連線已隔離：同一個指令已經嘗試 3 次。請重新連線後再試。',
  ),
  PowertrainProbeRefusal.quarantinedAfterRejectedRead: (
    'Quarantined for this connection: an earlier one-shot read did not pass '
        'its structural checks. Reconnect before trying again.',
    '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  String text(
    AppLocalizations l10n,
    PowertrainProbeRefusal refusal, {
    int cap = _cap,
  }) => powertrainProbeRefusalText(l10n, refusal, attemptCap: cap);

  group('refusal copy', () {
    test('every refusal is in the hand-typed table', () {
      // A refusal added later cannot pass by being merely non-empty and
      // unique: somebody has to type its sentence out here, in both languages.
      expect(
        _expected.keys.toSet(),
        PowertrainProbeRefusal.values.toSet(),
        reason:
            'a refusal identifier was added or removed without a '
            'hand-typed expectation',
      );
    });

    test('each refusal renders exactly the sentence written above', () {
      for (final entry in _expected.entries) {
        expect(
          text(en, entry.key),
          equals(entry.value.$1),
          reason: 'en copy for ${entry.key}',
        );
        expect(
          text(zh, entry.key),
          equals(entry.value.$2),
          reason: 'zh-Hant copy for ${entry.key}',
        );
      }
    });

    test('the attempt cap is rendered, not spelled into the copy', () {
      // The table above uses the real cap, so a hard-coded "3" in all three
      // ARB files would pass every assertion in it.
      for (final l10n in [en, zh]) {
        final five = text(
          l10n,
          PowertrainProbeRefusal.quarantinedAtAttemptCap,
          cap: 5,
        );
        expect(five, contains('5'));
        expect(five, isNot(contains('3')));
      }
    });

    test('the English build renders no Chinese', () {
      for (final refusal in PowertrainProbeRefusal.values) {
        final rendered = text(en, refusal);
        expect(
          chinese.hasMatch(rendered),
          isFalse,
          reason:
              '$refusal still shows ${chineseIn(rendered)} to an English '
              'reader',
        );
      }
    });

    test('no two refusals claim the same cause', () {
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final seen = <String, PowertrainProbeRefusal>{};
        for (final refusal in PowertrainProbeRefusal.values) {
          final rendered = text(l10n, refusal);
          final clash = seen[rendered];
          expect(
            clash,
            isNull,
            reason:
                '$name: $refusal and $clash render the same sentence:\n'
                '$rendered',
          );
          seen[rendered] = refusal;
        }
      }
    });

    test('the two languages actually differ for every refusal', () {
      // Catches a key added to app_en.arb and copied verbatim into the two
      // Chinese files, which passes every other check here.
      for (final refusal in PowertrainProbeRefusal.values) {
        expect(
          text(en, refusal),
          isNot(equals(text(zh, refusal))),
          reason: '$refusal reads identically in both languages',
        );
      }
    });

    test('only the two quarantine arms may be recorded as a quarantine', () {
      // The roster the notifier asserts against. A quarantine outlives the tap
      // that caused it; one saying `labClosed` would survive turning the
      // laboratory back on.
      expect(kPowertrainQuarantineRefusals, {
        PowertrainProbeRefusal.quarantinedAtAttemptCap,
        PowertrainProbeRefusal.quarantinedAfterRejectedRead,
      });
    });
  });

  group('the engine picks the right identifier for each condition', () {
    // The link the copy table above cannot reach. Every case here drives the
    // real `authorize()` and asserts `.refusal`, never `.accepted` alone:
    // `accepted == false` is preserved by every transposition, which is how
    // five arms collapsed into one and stayed green.
    late ProviderContainer container;
    late PowertrainBatteryCatalogSnapshot snapshot;

    Future<PowertrainExperimentalProbeConsents> consents({
      bool laboratoryOn = true,
    }) async {
      if (laboratoryOn) {
        await container
            .read(powertrainBatteryExperimentalAccessProvider.notifier)
            .setEnabled(true);
      }
      return container.read(
        powertrainExperimentalProbeConsentsProvider.notifier,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      snapshot = await PowertrainBatteryCatalogAsset.load();
    });

    /// A community profile the one-shot laboratory may actually read.
    PowertrainBatteryProfile probeable() => snapshot.catalog.profiles
        .singleWhere((profile) => profile.id == 'mg-zs-ev-au-2021');

    /// A catalog entry that is structurally clean and still not probeable:
    /// `researchOnly` carries no commands, so `canProbe` is false with an
    /// empty issue list. That empty list is the whole distinction between
    /// `profileNotProbeable` and `profileFailedValidation`.
    PowertrainBatteryProfile notProbeable() => snapshot.catalog.profiles
        .singleWhere((profile) => profile.id == 'bmw-i3-bev-2013-2016');

    test('the laboratory being off is labClosed', () async {
      final probe = await consents(laboratoryOn: false);
      final profile = probeable();
      expect(
        probe
            .authorize(
              snapshot: snapshot,
              profileId: profile.id,
              commandKey: profile.commands.first.wireKey,
              vehicleYear: 2021,
              connectionGeneration: 1,
            )
            .refusal,
        PowertrainProbeRefusal.labClosed,
      );
    });

    test('an id no verified profile has is profileNotInCatalog', () async {
      final probe = await consents();
      expect(
        probe
            .authorize(
              snapshot: snapshot,
              profileId: 'no-such-profile-in-any-catalog',
              commandKey: '22B046',
              vehicleYear: 2021,
              connectionGeneration: 1,
            )
            .refusal,
        PowertrainProbeRefusal.profileNotInCatalog,
      );
    });

    test('a clean profile of a tier that cannot be read once is '
        'profileNotProbeable', () async {
      final probe = await consents();
      final profile = notProbeable();
      // The precondition the identifier is about, asserted rather than
      // assumed: no issues, and still not probeable.
      final validation = const PowertrainBatteryProfileCatalogValidator()
          .validateProfile(profile, vehicleYear: 2015);
      expect(validation.issues, isEmpty);
      expect(validation.canProbe, isFalse);
      expect(
        probe
            .authorize(
              snapshot: snapshot,
              profileId: profile.id,
              commandKey: '22B046',
              vehicleYear: 2015,
              connectionGeneration: 1,
            )
            .refusal,
        PowertrainProbeRefusal.profileNotProbeable,
      );
    });

    test(
      'a model year outside the profile is profileFailedValidation',
      () async {
        final probe = await consents();
        final profile = probeable();
        final validation = const PowertrainBatteryProfileCatalogValidator()
            .validateProfile(profile, vehicleYear: 2035);
        expect(validation.issues, isNotEmpty);
        expect(
          probe
              .authorize(
                snapshot: snapshot,
                profileId: profile.id,
                commandKey: profile.commands.first.wireKey,
                vehicleYear: 2035,
                connectionGeneration: 1,
              )
              .refusal,
          PowertrainProbeRefusal.profileFailedValidation,
        );
      },
    );

    test('a command the profile does not own is commandNotInProfile', () async {
      final probe = await consents();
      final profile = probeable();
      expect(
        profile.commands.any((command) => command.wireKey == '22FFFF'),
        isFalse,
        reason: 'the fixture command must genuinely not be in this profile',
      );
      expect(
        probe
            .authorize(
              snapshot: snapshot,
              profileId: profile.id,
              commandKey: '22FFFF',
              vehicleYear: 2021,
              connectionGeneration: 1,
            )
            .refusal,
        PowertrainProbeRefusal.commandNotInProfile,
      );
    });

    test('a standing quarantine is reported as the cause that recorded it', () async {
      // Both quarantine arms come back through one `return`, so the identifier
      // has to be the one that was stored. A tap that reports the wrong one
      // sends the driver to reconnect for a reason that did not happen.
      for (final cause in kPowertrainQuarantineRefusals) {
        final probe = await consents();
        final profile = probeable();
        probe.quarantine(profile.id, cause);
        expect(
          probe
              .authorize(
                snapshot: snapshot,
                profileId: profile.id,
                commandKey: profile.commands.first.wireKey,
                vehicleYear: 2021,
                connectionGeneration: 1,
              )
              .refusal,
          cause,
        );
        probe.invalidateForVehicleBoundary();
      }
    });

    test('the accepted path still accepts, and names no refusal', () async {
      // Vacuity: every assertion above is about a refusal, so an `authorize`
      // that refused everything would satisfy all of them.
      final probe = await consents();
      final profile = probeable();
      final decision = probe.authorize(
        snapshot: snapshot,
        profileId: profile.id,
        commandKey: profile.commands.first.wireKey,
        vehicleYear: 2021,
        connectionGeneration: 1,
      );
      expect(decision.accepted, isTrue);
      expect(decision.refusal, isNull);
    });

    test('catalogHashInvalid is a backstop no snapshot can reach', () async {
      // The one arm the cases above cannot drive, said plainly rather than
      // left looking covered. `PowertrainBatteryCatalogSnapshot` is a final
      // class with a private constructor, and the only way in --
      // `fromStrings` -- refuses a manifest whose `sha256` is not a lowercase
      // 64-hex digest before a snapshot exists. So `authorize`'s hash check
      // cannot fail for anything this app can construct.
      //
      // This test is what makes that claim checkable. If the manifest gate is
      // ever loosened, the arm becomes reachable and nothing else in this file
      // is watching it -- so this goes red first and says to write the case.
      expect(isPowertrainCatalogSha256(snapshot.catalogSha256), isTrue);
      expect(
        () => PowertrainBatteryCatalogAsset.fromStrings(
          manifestJson:
              '{"schema_version":3,'
              '"catalog_file":"powertrain_battery_catalog.json",'
              '"sha256":"not-a-digest","size_bytes":0,"profile_count":0,'
              '"signal_count":0,"counts_by_powertrain":{}}',
          catalogJson: '{"schema_version":3,"profiles":[]}',
        ),
        throwsA(isA<PowertrainBatteryCatalogAssetException>()),
        reason:
            'if a snapshot can be built with a hash that is not a '
            'lowercase 64-hex digest, PowertrainProbeRefusal.catalogHashInvalid '
            'is reachable and needs a case of its own above',
      );
    });
  });

  group('the engine names refusals, it does not word them', () {
    test('every refusal is constructed from an identifier', () {
      // Not redundant with the compiler. `refused` takes a
      // `PowertrainProbeRefusal` today; what the type system cannot refuse is
      // somebody widening it back to `String` and passing a sentence, which is
      // exactly the state this slice found the file in.
      final offenders = <String>[];
      var calls = 0;
      for (final file in _libSources()) {
        final src = file.readAsStringSync();
        final code = codeOnly(src);
        final mask = codeMask(src);
        final regions = sourceRegions(src);
        final pattern = RegExp(
          r'PowertrainExperimentalConsentDecision\.refused\(',
        );
        // Matched against `code`, so a mention in a comment or a string is not
        // a call.
        for (final match in pattern.allMatches(code)) {
          calls++;
          final where = '${file.path}:${_lineAt(src, match.start)}';
          final spans = topLevelArgSpans(src, mask, match.end - 1);
          if (spans == null || spans.isEmpty) {
            // Reported rather than skipped: an unreadable call dropped in
            // silence turns any future desync into a green run.
            offenders.add('$where — could not be read');
            continue;
          }
          final (start, end) = spans.first;
          if (code.substring(start, end).trim().isEmpty) {
            offenders.add('$where — first argument is not code');
            continue;
          }
          for (var i = start; i < end; i++) {
            if (regions[i] == SourceRegion.string) {
              offenders.add(
                '$where — first argument contains a string literal: '
                '${src.substring(start, end).trim()}',
              );
              break;
            }
          }
        }
      }
      // Not `greaterThan(0)`: presence is not coverage. Deleting six of the
      // seven construction sites left that green, so the scan would have gone
      // on reporting success while watching one line. The number is the
      // constructor declaration plus the six `return`s in `authorize`; raise
      // it deliberately when a seventh refusal path is written.
      expect(
        calls,
        greaterThanOrEqualTo(_refusalConstructionSites),
        reason:
            'the scan found $calls of the $_refusalConstructionSites '
            'refusal constructions it expects. Either a refusal path was '
            'deleted, or the scan has stopped seeing them',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'a refusal reaches the screen carrying a sentence instead of '
            'an identifier the screen can translate:\n${offenders.join('\n')}',
      );
    });

    test('every file on the refusal path still exists', () {
      // A guard aimed at a renamed path passes by reading nothing, which is
      // this project's most familiar failure.
      for (final path in _refusalPath) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason:
              '$path was moved or deleted. Point this guard at wherever '
              'the refusal path lives now; do not delete the entry.',
        );
      }
    });

    test('no string literal anywhere on the refusal path is Chinese', () {
      final offenders = <String>[];
      for (final path in _refusalPath) {
        final src = File(path).readAsStringSync();
        offenders.addAll(
          _chineseStringLiterals(src)
              .map((hit) => '$path:${_lineAt(src, hit.$1)} — ${hit.$2}'),
        );
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'these are words a screen renders on the refusal path with no '
            'identifier behind them; give the screen an identifier and put '
            'the sentence in all three ARB files instead:\n'
            '${offenders.join('\n')}',
      );
    });
  });

  group('the reader itself: a comment is not a string', () {
    // The scan above is only worth what this is worth. This repository is
    // written with Chinese comments throughout, and a guard that flagged them
    // would be turned off within the week.
    String found(String src) =>
        _chineseStringLiterals(src).map((hit) => hit.$2).join();

    test('Chinese in a line comment is not flagged', () {
      expect(found('// 目錄完整性雜湊無效\nconst a = 1;'), isEmpty);
    });

    test('Chinese in a block comment is not flagged', () {
      expect(found('/* 本次連線已隔離 */\nconst a = 1;'), isEmpty);
    });

    test('Chinese in a doc comment beside a clean string is not flagged', () {
      expect(found("/// 這個設定檔不在已驗證目錄中\nconst a = 'ok';"), isEmpty);
    });

    test('Chinese in a string literal is flagged', () {
      expect(found("const a = '目錄完整性雜湊無效';"), contains('目'));
    });

    test('Chinese in a string nested inside an interpolation is flagged', () {
      expect(found("final a = '\${f('隔離')}';"), contains('隔'));
    });

    test('CJK punctuation alone is flagged', () {
      // The half eight of nine wave test files missed: every word translated
      // and only the separator left behind.
      expect(found("const a = 'Battery 1、Battery 2';"), contains('、'));
      expect(found("const a = 'Not authorized：x';"), contains('：'));
    });
  });

  test('every render site for these two families is one this suite knows '
      'about', () {
    // Slice F, this branch's sibling, pinned its render sites BY NAME: round 3
    // wrote "the render site", singular, and there were four. Mutating the
    // three it missed left 2157 tests green while the screen printed
    // `serviceNotReadOnly` at a reader.
    //
    // This branch happens to be complete — all seven sites below are driven by
    // a test, confirmed by mutating each family and watching the tests that
    // NAME the behaviour go red. But "happens to be" is not a property. What
    // was missing is the mechanism that says so when an eighth appears.
    //
    // The rule is the same as the throw-site guards use: a render site is a
    // call, in code, to a function declared in one of this feature's
    // `*_copy.dart` files, from a file that is not that copy file. Counted per
    // call site rather than per (file, function), because two of these files
    // call the same function twice and a pair-keyed roster hides one of them.
    const copyFiles = [
      'lib/ui/screens/pids/powertrain_battery_copy.dart',
      'lib/ui/screens/pids/pid_mutation_copy.dart',
    ];

    final exported = <String>{};
    for (final path in copyFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is the census input');
      for (final m in RegExp(r'^String\??\s+(\w+)\s*\(', multiLine: true)
          .allMatches(codeOnly(file.readAsStringSync()))) {
        exported.add(m.group(1)!);
      }
    }
    expect(exported, {'powertrainProbeRefusalText', 'pidMutationFailureText'},
        reason: 'a copy function was added or renamed');

    final sites = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (copyFiles.contains(entity.path)) continue;
      final code = codeOnly(entity.readAsStringSync());
      for (final name in exported) {
        final n = RegExp('\\b$name\\s*\\(').allMatches(code).length;
        if (n > 0) sites.add('${entity.path} -> $name x$n');
      }
    }

    const known = {
      // the quarantine refusal before the tap, and the one recorded while the
      // consent dialog sat open — both rendered in
      // powertrain_battery_catalog_ui_test.dart, both locales
      'lib/ui/screens/pids/powertrain_battery_catalog_screen.dart '
          '-> powertrainProbeRefusalText x2',
      // the recording lock refusing a catalog install — same file, both locales
      'lib/ui/screens/pids/powertrain_battery_catalog_screen.dart '
          '-> pidMutationFailureText x2',
      // the recording lock on save and on confirmed delete —
      // pid_editor_test.dart
      'lib/ui/screens/pids/pid_editor_screen.dart -> pidMutationFailureText x1',
      // the recording lock on the dashboard toggle, and on the manager's own
      // mutation path — pid_manager_lock_test.dart
      'lib/ui/screens/pids/pid_manager_screen.dart -> pidMutationFailureText x2',
    };
    expect(sites, equals(known),
        reason: 'a render site appeared or moved. Each one turns an identifier '
            'into a sentence somebody reads. Drive it from a test, watch the '
            'test that names the behaviour go red under a mutation, then add '
            'the line here.');
  });
}

/// Every `(offset, character)` where a string literal in [src] holds CJK.
List<(int, String)> _chineseStringLiterals(String src) {
  final regions = sourceRegions(src);
  final hits = <(int, String)>[];
  for (var i = 0; i < src.length; i++) {
    if (regions[i] != SourceRegion.string) continue;
    if (!chinese.hasMatch(src[i])) continue;
    hits.add((i, src[i]));
  }
  return hits;

}

int _lineAt(String src, int offset) =>
    '\n'.allMatches(src.substring(0, offset)).length + 1;

List<File> _libSources() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
