// The manual command box's refusals, held to identifiers rather than sentences.
//
// `ObdSession.manualCommandRefusal` used to answer with a Traditional Chinese
// sentence. The session wrapped it in a `TransportException` carrying
// `issue: null`, and the settings panel rendered `error.message` — so an
// English driver who typed `04` was refused with
// `清除故障碼請用故障碼畫面的「清除」按鈕。…` on the one screen somebody opens
// when they are already unsure whether the app works.
//
// What this file asserts is deliberately not "the switch returns what the ARB
// holds". `manual_command_copy_test.dart` owns identifier→sentence, with a
// hand-typed table, because a test that reads its expectation back out of
// `AppLocalizations` agrees with itself. This file owns the two links either
// side of it:
//
//     condition -> identifier -> sentence -> the values -> the render site
//     ^^^^^^^^^^^^^^^^^^^^^^^                             ^^^^^^^^^^^^^^^^
//
// The condition→identifier link is the one this slice created a boundary
// across. Before it, the trigger and its words were on adjacent lines and a
// diff reader saw the pair; now the trigger is in `lib/state/` and the words
// are in `lib/ui/`. Collapsing two conditions onto one identifier compiles,
// renders, and is invisible until somebody is refused for a reason that did
// not happen.
//
// The scan is the other half, and it is shaped like the defect rather than
// like the fix: no string literal in the refusal engine may be Chinese. A
// sentence composed there is one no localization can reach, whatever the enum
// beside it says.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/state/manual_command_refusal.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';

/// The engine half of the refusal path: files whose string literals must hold
/// no Chinese.
///
/// `settings_screen.dart` is deliberately not here. It is a whole screen with
/// Traditional Chinese in it for other reasons, so a scan aimed at it would
/// need an exception list — and an exception list in a guard is what this
/// repository's guards fail on. What it does own, the routing from an
/// exception to a copy function, is held by the render-site census below and
/// driven by `manual_command_wording_test.dart`.
const _refusalEngine = <String>[
  'lib/state/manual_command_refusal.dart',
  'lib/ui/screens/settings/manual_command_copy.dart',
];

/// Every command that must be refused, with the identifier it must produce.
///
/// Typed out by hand. Nothing here is read back from `manualCommandRefusal`,
/// and `every identifier is reachable` below is what says the table reaches
/// every value of the enum — a case removed from this map would otherwise take
/// its identifier out of the suite silently. Said that way rather than with a
/// number, because the number is the thing that would drift.
const _conditions = <String, ManualCommandRefusalReason>{
  '': ManualCommandRefusalReason.emptyCommand,
  '   ': ManualCommandRefusalReason.emptyCommand,
  '03\r04': ManualCommandRefusalReason.moreThanOneCommand,
  '0100\r\n04': ManualCommandRefusalReason.moreThanOneCommand,
  'ATI\t04': ManualCommandRefusalReason.moreThanOneCommand,
  'ATZ': ManualCommandRefusalReason.adapterStateWouldChange,
  'ATSH 7E1': ManualCommandRefusalReason.adapterStateWouldChange,
  'ATCFC0': ManualCommandRefusalReason.adapterStateWouldChange,
  'AT@3': ManualCommandRefusalReason.adapterStateWouldChange,
  'ATCV': ManualCommandRefusalReason.adapterStateWouldChange,
  '04': ManualCommandRefusalReason.clearHasItsOwnButton,
  '04 00': ManualCommandRefusalReason.clearHasItsOwnButton,
  'ZZ': ManualCommandRefusalReason.charactersNoObdCommandHas,
  '03;04': ManualCommandRefusalReason.charactersNoObdCommandHas,
  'FF': ManualCommandRefusalReason.notAReadOnlyQuery,
  '08': ManualCommandRefusalReason.notAReadOnlyQuery,
  '2101': ManualCommandRefusalReason.notAReadOnlyQuery,
};

void main() {
  group('the engine picks the right identifier for each condition', () {
    test('every command in the table produces the identifier written for it',
        () {
      // The identifier, never `isNotNull` alone: "was refused" is preserved by
      // every collapse of one identifier onto another, which is how five
      // refusal arms in this repo's battery laboratory became one and stayed
      // green through the whole suite.
      final wrong = <String>[];
      for (final entry in _conditions.entries) {
        final refusal = manualCommandRefusal(entry.key);
        if (refusal == null) {
          wrong.add('${entry.key.codeUnits}: was not refused at all');
          continue;
        }
        if (refusal.issue != entry.value) {
          wrong.add(
            '${entry.key.codeUnits}: expected ${entry.value}, '
            'got ${refusal.issue}',
          );
        }
      }
      expect(wrong, isEmpty, reason: wrong.join('\n'));
    });

    test('every identifier is reachable from some command', () {
      // Written from the enum. A value nothing produces is either dead or the
      // table stopped covering it, and both are worth a red run: the copy
      // tests would go on rendering a sentence nobody can be shown.
      expect(
        _conditions.values.toSet(),
        ManualCommandRefusalReason.values.toSet(),
        reason: 'no command in the table produces these identifiers',
      );
    });

    test('the ordinary commands are still not refused', () {
      // Vacuity. Every case above is a refusal, so an engine that refused
      // everything satisfies all of them.
      for (final ok in ['ATI', 'AT@1', 'ATRV', 'ATDPN', '03', '0100', '2211A6',
        '0a', '01 0C', '05', '0902']) {
        expect(manualCommandRefusal(ok), isNull, reason: ok);
      }
    });

    test('the values a sentence names are carried, and only by the arms that '
        'name them', () {
      // `issueDetail` next door needed a source scan to hold this up, because
      // `issueDetail: null` analyses clean. Here the constructors take the
      // values as required arguments, so the compiler holds it — and this is
      // what says the constructors still do, rather than having gained a
      // default somebody could forget.
      expect(
        manualCommandRefusal('ATSH 7E1')!.command,
        'ATSH 7E1',
        reason: 'the sentence quotes what was typed',
      );
      expect(
        manualCommandRefusal('ATSH 7E1')!.allowed,
        isNotEmpty,
        reason: 'and lists what it would have accepted',
      );
      expect(manualCommandRefusal('ZZ')!.command, 'ZZ');
      expect(manualCommandRefusal('FF')!.allowed, isNotEmpty);
      // And the arms whose sentence names nothing carry nothing, so a copy
      // edit that started printing them would print an empty string rather
      // than somebody else's command.
      expect(manualCommandRefusal('04')!.command, isEmpty);
      expect(manualCommandRefusal('04')!.allowed, isEmpty);
      expect(manualCommandRefusal('03\r04')!.command, isEmpty);
    });

    test('what a reader is shown is the acceptance set, not a copy of it', () {
      // The drift this repository has already paid for once, on the other
      // list: Mode 05 was admitted and the sentence that tells somebody what
      // they *can* send still omitted it, so the person whose command had just
      // been refused was told 05 was not allowed by the sentence meant to tell
      // them what is. The AT list had the same shape — it named seven while
      // the code accepted more — and now it cannot: what is shown is the
      // acceptance set itself, so there is no second list to drift.
      expect(
        manualCommandRefusal('FF')!.allowed.toSet(),
        kManualCommandReadOnlyServices,
      );
      expect(
        manualCommandRefusal('ATZ')!.allowed.toSet(),
        kManualCommandReadOnlyAtQueries.map((q) => 'AT$q').toSet(),
      );
      // Every advertised query really is accepted. The census above says the
      // two sets match; this says the set is the one the engine consults, so a
      // constant that was renamed and left behind cannot satisfy both.
      for (final query in manualCommandAdvertisedAtQueries) {
        expect(manualCommandRefusal(query), isNull, reason: query);
      }
      for (final service in manualCommandAdvertisedServices) {
        expect(manualCommandRefusal(service), isNull, reason: service);
      }
    });
  });

  group('no sentence is composed in the engine', () {
    test('every file on the refusal path still exists', () {
      // A guard aimed at a renamed path passes by reading nothing, which is
      // this project's most familiar failure.
      for (final path in _refusalEngine) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path was moved or deleted. Point this guard at wherever '
              'the refusal engine lives now; do not delete the entry.',
        );
      }
    });

    test('no string literal on it is Chinese', () {
      final offenders = <String>[];
      for (final path in _refusalEngine) {
        final src = File(path).readAsStringSync();
        offenders.addAll(
          _chineseStringLiterals(src)
              .map((hit) => '$path:${_lineAt(src, hit.$1)} — ${hit.$2}'),
        );
      }
      expect(
        offenders,
        isEmpty,
        reason: 'these are words a screen renders with no identifier behind '
            'them; give the refusal an identifier and put the sentence in all '
            'three ARB files instead:\n${offenders.join('\n')}',
      );
    });
  });

  group('the reader itself: a comment is not a string', () {
    // The scan above is only worth what this is worth. Both files are written
    // with Chinese comments throughout — the engine's explain why a command is
    // refused, and they are the most valuable prose in the file — so a guard
    // that flagged them would be turned off within the week.
    String found(String src) =>
        _chineseStringLiterals(src).map((hit) => hit.$2).join();

    test('Chinese in a line comment is not flagged', () {
      expect(found('// 清除故障碼請用按鈕\nconst a = 1;'), isEmpty);
    });

    test('Chinese in a doc comment beside a clean string is not flagged', () {
      expect(found("/// 不認得的指令\nconst a = 'ok';"), isEmpty);
    });

    test('Chinese in a string literal is flagged', () {
      expect(found("const a = '沒有輸入指令';"), contains('沒'));
    });

    test('Chinese nested inside an interpolation is flagged', () {
      expect(found("final a = '\${f('清除')}';"), contains('清'));
    });

    test('CJK punctuation alone is flagged', () {
      // The half eight of nine earlier waves in this repo missed: every word
      // translated and only the separator left behind. This is exactly the
      // shape the AT-query list would have taken had it been joined in the
      // engine.
      expect(found("const a = 'ATI、ATRV';"), contains('、'));
      expect(found("const a = 'Queries：ATI';"), contains('：'));
    });
  });

  test('every render site for the refusal copy is one this suite knows about',
      () {
    // Pinned by census, not by name. A sibling slice wrote "the render site",
    // singular, and there were four; mutating the three it missed left the
    // suite green while the screen printed an enum identifier at a reader.
    //
    // A render site is a call, in code, to a function declared in the copy
    // file, from a file that is not the copy file. Counted per call rather
    // than per (file, function): a pair-keyed roster hides the second of two
    // calls in one file.
    const copyFile = 'lib/ui/screens/settings/manual_command_copy.dart';
    final file = File(copyFile);
    expect(file.existsSync(), isTrue, reason: '$copyFile is the census input');

    final exported = <String>{
      for (final m in RegExp(r'^String\??\s+(\w+)\s*\(', multiLine: true)
          .allMatches(codeOnly(file.readAsStringSync())))
        m.group(1)!,
    };
    expect(
      exported,
      {'commandFailureText', 'commandIssueText', 'manualCommandRefusalText'},
      reason: 'a copy function was added or renamed',
    );

    final sites = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == copyFile) continue;
      final code = codeOnly(entity.readAsStringSync());
      for (final name in exported) {
        final n = RegExp('\\b$name\\s*\\(').allMatches(code).length;
        if (n > 0) sites.add('${entity.path} -> $name x$n');
      }
    }

    const known = {
      // The manual command panel, both arms of `describeManualFailure`. Driven
      // in `manual_command_wording_test.dart` and `manual_command_copy_test.dart`,
      // both locales, through the real function the panel calls.
      'lib/ui/screens/settings/settings_screen.dart -> commandFailureText x1',
      'lib/ui/screens/settings/settings_screen.dart '
          '-> manualCommandRefusalText x1',
      // The fault-code screen's detail line, reached by identifier rather than
      // by exception. Driven in `transport_issue_guard_test.dart`, which walks
      // a refused header from a fake adapter to the rendered sentence.
      'lib/ui/screens/dtc/dtc_screen.dart -> commandIssueText x1',
    };
    expect(
      sites,
      equals(known),
      reason: 'a render site appeared or moved. Each one turns an identifier '
          'into a sentence somebody reads. Drive it from a test, watch the '
          'test that names the behaviour go red under a mutation, then add '
          'the line here.',
    );
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
