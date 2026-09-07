// `DatumStatus.reason` is an exported sentence, frozen in Traditional Chinese
// so that two people holding the same telemetry file can compare it line by
// line. `DatumStatus.reasonCode` is the same fact as an identifier, and it is
// what a screen renders.
//
// `datumReasonText` used to end in `return status.reason;`. A producer that set
// the sentence and forgot the code cost nothing at the call site and put Chinese
// on an English phone — the exact failure `export_labels_stay_off_screen_test`
// exists to stop, reached through the one file that test excused wholesale.
//
// That fallback is gone. Two things now hold the gap it used to paper over:
//
//   * `reasonCode` is a required named argument, so `null` has to be written
//     out. The compiler asks every new producer the question.
//   * this file, because the compiler cannot tell `reasonCode: null` at a site
//     whose reason travels by `statusReason` or `gaps` — correct, and the two
//     places it happens today — from `reasonCode: null` at a site where nothing
//     else carries the reason, which is silent data loss on the screen.
//
// So the rule is not "always pass a code". It is: if you export a sentence, the
// screen must have SOMETHING to render instead of it. There is no exception
// list; a producer that cannot satisfy the rule has found a real gap in the
// vocabulary and should add an identifier.
//
// Reading source rather than constructing statuses, on the same reasoning as
// `transport_issue_guard_test.dart`: the failure is an omission at a call site,
// and no runtime test can enumerate call sites that do not exist yet. The Dart
// reader is that file's, extracted to `test/support/dart_source_reader.dart`
// rather than written a third time — a comment naming `reasonCode:` or a string
// containing `DatumStatus(` must not be mistaken for code, and the escaped
// apostrophe and raw-string cases that reader survives are ordinary Dart.
//
// This file imports nothing from `package:torque_obd`, which is deliberate: a
// mutation that removes a required argument does not compile, and a guard that
// cannot run when the code is broken cannot be shown to work.
//
// That is also why the *agreement* between a code and the sentence beside it is
// not checked here. This file can only see that both are present; whether they
// say the same thing needs the real enum, the real producers and the shipped
// ARB, and that is `test/l10n/datum_reason_agreement_test.dart`. Presence
// without agreement is how `reasonCode: DatumReason.busError` could sit beside
// `reason: '此服務不是唯讀查詢，已停止發送'` with the whole suite green.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_source_reader.dart';

/// What a screen can render instead of the exported sentence, when merely
/// being set is enough.
///
/// `statusReason` is a recorded telemetry status with its own copy table, and
/// `reasonCode` is the general case. Either one, present and not `null`, means
/// the screen has an identifier.
///
/// `gaps:` is deliberately NOT in this list. It is screen-readable only when
/// there is something in it — see [_gapsCarryTheReason].
const _screenReadable = ['reasonCode:', 'statusReason:'];

/// `gaps:` counts as the sentence's replacement only when the sentence is
/// itself gated on that same list being non-empty.
///
/// `datumReasonText` renders gaps under `if (status.gaps.isNotEmpty)`, so
/// `DatumStatus(reason: 'x', reasonCode: null, gaps: const [])` exports a
/// sentence and then falls through all three sources and returns `null` — the
/// blank line this guard exists to prevent, waved through by the guard,
/// because "is `gaps:` set and not the literal `null`" was the whole test.
///
/// The real site (`genericObdSession`) writes
/// `reason: gaps.isEmpty ? null : …, gaps: gaps`, and that pairing is what
/// makes it correct: the export exists exactly when the screen has items to
/// name. So that is what is checked, rather than the presence of an argument.
/// A gap list that arrives some other way is not rejected as wrong — it is
/// reported as unproven, which is the same answer this guard gives every other
/// shape it cannot follow.
bool _gapsCarryTheReason(List<String> args, String reason) {
  final at = args.indexWhere((a) => a.startsWith('gaps:'));
  if (at < 0) return false;
  final list = _value(args[at]);
  // Not a plain name: a literal, a call, a conditional. There is no identifier
  // for the sentence to be gated on, so there is nothing to check. The
  // `gaps: const []` probe lands here.
  if (!RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(list)) return false;
  final name = RegExp.escape(list);
  // The two orders of the same gate. Read on the blanked text, where string
  // contents are already spaces, so `join(' · ')` cannot look like syntax.
  return RegExp('^$name' r'\.isEmpty\s*\?\s*null\s*:').hasMatch(reason) ||
      (RegExp('^$name' r'\.isNotEmpty\s*\?').hasMatch(reason) &&
          RegExp(r':\s*null$').hasMatch(reason));
}

void main() {
  test('no DatumStatus exports a sentence the screen cannot replace', () {
    final scan = _Scan();
    for (final file in _sources()) {
      scan.read(file.readAsStringSync(), file.path);
    }

    expect(
      scan.offences,
      isEmpty,
      reason:
          'These write a Traditional Chinese sentence into the telemetry export '
          'and leave the details dialog nothing else to show. `datumReasonText` '
          'no longer falls back to the exported string, so this renders as a '
          'blank line — or, if the fallback is ever restored, as Chinese on an '
          'English phone.\n\n${scan.offences.join('\n')}',
    );

    // The scan seeing nothing must not read as success. Both counters guard a
    // different way of going blind: the first if `DatumStatus(` stops matching
    // at all, the second if `reason:` does. Neither is pinned to a number —
    // this repo has been wrong four times by pinning one that moves.
    expect(
      scan.constructions,
      greaterThan(0),
      reason: 'the scan found no DatumStatus construction at all',
    );
    expect(
      scan.exportedReasons,
      greaterThan(0),
      reason: 'the scan found no exported reason, so the rule never ran',
    );
  });

  test('the rule itself, on sources that are supposed to be wrong', () {
    // The scan above runs on a tree that is supposed to be clean, so a green
    // run proves nothing about whether it can go red. These are the shapes it
    // exists to separate.
    _Scan scan(String src) => _Scan()..read(src, 'fixture.dart');
    List<String> check(String src) => scan(src).offences;

    expect(
      check("DatumStatus(reason: '壞封包', reasonCode: DatumReason.x);"),
      isEmpty,
      reason: 'a sentence with a code is the ordinary correct case',
    );
    expect(
      check("DatumStatus(reason: '壞封包', reasonCode: null);"),
      hasLength(1),
      reason: 'an explicit null code with nothing else is the whole point',
    );
    expect(
      check("DatumStatus(reason: '壞封包');"),
      hasLength(1),
      reason: 'and so is omitting it, for the day the argument stops being '
          'required',
    );
    expect(
      check('DatumStatus(reason: null, reasonCode: null);'),
      isEmpty,
      reason: 'exporting nothing needs no replacement',
    );
    expect(
      check("DatumStatus(reason: x ? 'a' : null, reasonCode: x ? y : null);"),
      isEmpty,
      reason: 'a conditional pair is correct; searching for the substring '
          '"null" would reject it',
    );
    expect(
      check("DatumStatus(reason: event.status?.wireName, "
          'statusReason: event.status);'),
      isEmpty,
      reason: 'a recorded status is screen-readable',
    );
    expect(
      check("DatumStatus(reason: gaps.isEmpty ? null : gaps.join(' · '), "
          'reasonCode: null, gaps: gaps);'),
      isEmpty,
      reason: 'so is a gap list, when the sentence is gated on that same list '
          'being non-empty — the shape genericObdSession actually writes',
    );
    expect(
      check("DatumStatus(reason: gaps.isNotEmpty ? gaps.join(' · ') : null, "
          'reasonCode: null, gaps: gaps);'),
      isEmpty,
      reason: 'and the same gate written the other way round',
    );
    expect(
      check("DatumStatus(reason: gaps.join(' · '), reasonCode: null, "
          'gaps: gaps);'),
      hasLength(1),
      reason: 'an ungated sentence beside a list that may be empty is not '
          'proven to have anything to render',
    );
    expect(
      check("DatumStatus(reason: 'x', reasonCode: null, gaps: const []);"),
      hasLength(1),
      reason: 'the shape the presence test waved through: datumReasonText '
          'gates on gaps.isNotEmpty, so this falls through all three sources '
          'and renders the blank line this guard exists to prevent',
    );
    expect(
      check("DatumStatus(reason: 'x', reasonCode: null, gaps: gaps);"),
      hasLength(1),
      reason: 'a constant sentence cannot be gated on the list at all',
    );
    expect(
      check("// DatumStatus(reason: '壞封包', reasonCode: null);"),
      isEmpty,
      reason: 'a commented-out call is not a call',
    );
    expect(
      check("const s = \"DatumStatus(reason: 'x', reasonCode: null)\";"),
      isEmpty,
      reason: 'nor is one inside a string',
    );
    // Not `isEmpty`: the declaration has no `reason:` argument, so it passes
    // that way whether the branch that is supposed to skip it runs or not —
    // which is how the branch spent this slice never running. What is asserted
    // is the count, because only the branch can make it zero.
    expect(
      scan("const DatumStatus({required this.availability, this.reason, "
              'required this.reasonCode});')
          .constructions,
      0,
      reason: 'the declaration is skipped as a declaration, not by accident',
    );
    expect(
      check("const DatumStatus({required this.availability, this.reason, "
          'required this.reasonCode});'),
      isEmpty,
      reason: 'the declaration is not a construction',
    );
    expect(
      scan("const DatumStatus({required this.availability, super.reason});")
          .constructions,
      0,
      reason: 'a super parameter is a declaration too',
    );
    expect(
      scan("DatumStatus(reason: '壞封包', reasonCode: DatumReason.x);")
          .constructions,
      1,
      reason: 'and a real call still counts, so the skip is not swallowing '
          'everything',
    );
    expect(
      check("DatumStatus(reason: '假設尚未確認', reasonCode: DatumReason.x, "
          "nested: Other(reasonCode: null));"),
      isEmpty,
      reason: "a nested call's arguments are not the outer call's",
    );
    expect(
      check("DatumStatus(reason: '壞封包', "
          'nested: Other(reasonCode: DatumReason.x));'),
      hasLength(1),
      reason: 'and the outer call may not borrow the inner one',
    );
    // The escaped-apostrophe case the shared reader documents. Read as a
    // closing quote it inverts the mask for the rest of the file, which would
    // hide the offence on the next line.
    expect(
      check("const q = 'it\\'s';\nDatumStatus(reason: 'x', reasonCode: null);"),
      hasLength(1),
      reason: 'an escaped quote does not close a single-quoted literal',
    );
    expect(
      check("const p = r'C:\\';\nDatumStatus(reason: 'x', reasonCode: null);"),
      hasLength(1),
      reason: 'a raw string has no escapes, so its backslash is content',
    );
  });
}

/// Every Dart file under `lib/`.
///
/// The whole tree rather than `lib/diagnostics/`, where all twelve
/// constructions live today (thirteen `DatumStatus(` matches, one of which is
/// the declaration). A producer added in `lib/state/` would be exactly
/// as wrong and exactly as invisible, and narrowing the scan to where the
/// problem happens to be now is how a guard quietly stops covering it.
List<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// The text after `name:` in a named argument, trimmed.
String _value(String arg) => arg.substring(arg.indexOf(':') + 1).trim();

/// A field-initialising formal — `this.x` or `super.x`, optionally `required`,
/// optionally the first entry inside the `{…}` of an optional-named block.
///
/// Only a declaration has these, so an argument list containing one is a
/// declaration.
final _declaration = RegExp(r'^\{?\s*(required\s+)?(this|super)\.');

/// The rule, in one place.
///
/// The fixtures and the tree walk drive this same object rather than two copies
/// of the same loop. `transport_issue_guard_test.dart` learned that the hard
/// way: a test written against a second copy of the real switch stayed green
/// while the real one was wrong.
class _Scan {
  final offences = <String>[];

  /// How many constructions were read, and how many of those exported a
  /// sentence. Zero for either means the reader went blind, not that the tree
  /// is clean.
  var constructions = 0;
  var exportedReasons = 0;

  void read(String src, String path) {
    final mask = codeMask(src);
    // Two readings of the same call, split identically because they share one
    // mask. `blanked` has every string and comment character replaced by a
    // space, and it is the one the rule reads: an argument in this file is
    // routinely preceded by the comment explaining it, so
    // `reasonCode: switch (fault) {…}` arrives as
    // `// Silence is not a controller saying…\n reasonCode: …` and no prefix
    // test can see it. That is not hypothetical — it is what the first version
    // of this guard did, and it reported `forPid` as an offence when `forPid`
    // is correct. `src` is kept only to quote the offending argument back.
    final blanked = codeOnly(src);
    for (final match in RegExp(r'\bDatumStatus\(').allMatches(src)) {
      if (!mask[match.start]) continue; // named in a string or a comment
      final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
      final args = topLevelArgs(blanked, mask, match.end - 1);
      final quoted = topLevelArgs(src, mask, match.end - 1);
      if (args == null || quoted == null) {
        // Reported, not skipped. An unreadable call dropped in silence turns
        // any future desync into a green run; this way the reader can still be
        // wrong but cannot be quiet about it.
        offences.add('$path:$line — could not be read');
        continue;
      }
      final trimmed = args.map((a) => a.trim()).toList();

      // The declaration, not a call. `const DatumStatus({required this.x, ...})`
      // matches the same pattern and has no `reason:` argument, so it would pass
      // by accident rather than by rule — and an accident is what a guard is
      // for. Named explicitly instead.
      //
      // The previous form tested `a.startsWith('this.')` and never once ran:
      // `topLevelArgs` counts `{` as depth, so the whole named-parameter block
      // arrives as ONE argument beginning `{required this.…`. It passed only
      // because `indexWhere('reason:')` returned −1 on that blob — by accident,
      // exactly what the comment above claims it avoids — while the declaration
      // was still counted in [constructions], giving `constructions > 0` a floor
      // of 1 that the declaration alone satisfied. The optional-parameter brace
      // is part of the pattern now, and `scan(...).constructions` is asserted in
      // the fixtures below so the branch cannot go quiet again.
      if (trimmed.any(_declaration.hasMatch)) continue;
      constructions++;

      final at = trimmed.indexWhere((a) => a.startsWith('reason:'));
      if (at < 0) continue; // exports no sentence; nothing to replace
      // `reason: null` exports nothing, so there is nothing to fall back from.
      // Compared as an exact literal rather than searched for: every conditional
      // here — `reason: outOfRange ? '…' : null` — contains `null` and is a real
      // export on the other branch.
      if (_value(trimmed[at]) == 'null') continue;
      exportedReasons++;

      final companion =
          _screenReadable.any(
            (name) =>
                trimmed.any((a) => a.startsWith(name) && _value(a) != 'null'),
          ) ||
          _gapsCarryTheReason(trimmed, _value(trimmed[at]));
      if (companion) continue;
      offences.add(
        '$path:$line — ${_firstLine(quoted[at])} is exported with no '
        'reasonCode, statusReason or gaps for the screen to render instead',
      );
    }
  }
}

/// The head of an argument, for quoting one back without printing a whole
/// multi-line `switch`.
String _firstLine(String arg) {
  final head = arg.trim().split('\n').first.trim();
  return head.length <= 72 ? head : '${head.substring(0, 72)}…';
}
