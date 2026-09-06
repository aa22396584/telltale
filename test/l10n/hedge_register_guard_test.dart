// The hedge register, made executable.
//
// `docs/i18n/hedge-register.md` lists the sentences whose job is to stop a
// reader believing something the evidence does not support, and says for each
// one what a translator may not do to it. It was a document. A reviewer showed
// what that is worth: 31 meaning-inverting edits to shipped English left the
// whole suite green, and three of the register's own entries were among them.
//
// Writing a separate assertion per sentence would have closed those and left
// the next hedge open. This closes the class: an entry that names an ARB key
// is checked against that key's shipped value, so adding a hedge to the
// register *is* adding a guard, and softening one breaks a test rather than
// merely disagreeing with a Markdown file nobody runs.
//
// It cannot check the Chinese the same way — the register's zh text is quoted
// from source files all over the tree, not only from the ARBs, and
// `glossary_evidence_test.dart` already holds those citations to their line
// numbers. What this adds is the half that ships to an English reader.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _entry = RegExp(r'^### (\d+)\. (.*)$');

/// `**English** — text`, or `**English (clause)** — text` for the few entries
/// that record only the load-bearing clause of a longer shipped sentence.
///
/// The dash and the spaces around it are deliberately loose. A reviewer changed
/// one em dash to an en dash — the substitution any editor or autocorrect makes
/// without being asked — and the entry vanished from the guard silently, taking
/// `dtcRescanFirst` with it. Punctuation drift in a Markdown file must not be
/// able to disarm a test.
final _english = RegExp(r'^\*\*English( \(clause\))?\*\*[\s\u00a0]*[—–-][\s\u00a0]*(.*)$');

/// The Chinese half, held to the same standard where the entry names an ARB
/// key. It used not to be checked at all, on the reasoning that the register
/// quotes zh from source files all over the tree rather than only the ARBs —
/// true for the unkeyed entries, and it let an entry written an hour earlier
/// record 「故障燈已亮」 for a key that ships 「故障燈亮著」. The unchecked half
/// rots immediately, which is the whole argument of this file applied to
/// itself.
final _chinese = RegExp(r'^\*\*繁體中文\*\*[\s\u00a0]*[—–-][\s\u00a0]*(.*)$');
final _shipped = RegExp(r'^\*\*Shipped as\*\* (.*)$');

/// A backticked ARB key, optionally qualified by a class: `AppLocalizations.foo`
/// names the same key as `foo`, and someone will write it that way.
///
/// The qualifier must be UpperCamel, which is what keeps this from reading
/// `hedge_register_guard_test.dart` as a key called `dart`. Anchored at both
/// ends so a filename, a path or a snippet cannot match part of itself — the
/// looser first version did exactly that on its first run.
final _key = RegExp(r'`(?:[A-Z][A-Za-z0-9_]*\.)?([a-z][A-Za-z0-9_]*)`');

/// Whitespace normalisation, applied to both sides.
///
/// A non-breaking space and a run of spaces render the same, and a Markdown
/// file picks them up from editors without anybody deciding to.
String _plain(String value) => value
    .replaceAll(' ', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The register's own Markdown emphasis, stripped from the REGISTER side only.
///
/// It used to be stripped from both, and that hid a real defect: a shipped
/// string containing a literal `**not**` compared equal to a register entry
/// saying `not`, so the guard passed while the screen rendered the asterisks.
/// Emphasis is a property of the Markdown file. Whatever the ARB holds is what
/// a reader sees, character for character, and this comparison says so.
String _fromRegister(String value) => _plain(value.replaceAll('**', ''));

/// How many sentences a string is, roughly: a terminator followed by a space.
///
/// Blunt on purpose. It exists to make 'append a paragraph' fail while leaving
/// 'wrap the clause in a sentence' alone, and a real sentence splitter would be
/// a second thing to get wrong for no gain.
int _sentences(String value) =>
    RegExp(r'[.!?](\s|$)').allMatches(value).length.clamp(1, 1 << 30);

class _Hedge {
  _Hedge(this.number, this.title, this.english, this.chinese, this.keys,
      this.clauseOnly);
  final int number;
  final String title;
  final String english;
  final String? chinese;
  final List<String> keys;

  /// True when the register records a fragment of a longer shipped sentence
  /// rather than the whole of it, so the comparison has to be `contains`.
  final bool clauseOnly;
}

List<_Hedge> _readRegister() {
  final lines = File(
    'docs/i18n/hedge-register.md',
  ).readAsLinesSync();
  final hedges = <_Hedge>[];
  int? number;
  var title = '';
  String? english;
  String? chinese;
  var clauseOnly = false;
  var keys = <String>[];

  void flush() {
    final n = number;
    final e = english;
    if (n != null && e != null && keys.isNotEmpty) {
      hedges.add(_Hedge(n, title, e, chinese, keys, clauseOnly));
    }
  }

  for (final line in lines) {
    final entry = _entry.firstMatch(line);
    if (entry != null) {
      flush();
      number = int.parse(entry.group(1)!);
      title = entry.group(2)!;
      english = null;
      chinese = null;
      clauseOnly = false;
      keys = <String>[];
      continue;
    }
    final en = _english.firstMatch(line);
    if (en != null) {
      clauseOnly = en.group(1) != null;
      english = _fromRegister(en.group(2)!);
      continue;
    }
    final zhLine = _chinese.firstMatch(line);
    if (zhLine != null) {
      chinese = _fromRegister(zhLine.group(1)!);
      continue;
    }
    final shipped = _shipped.firstMatch(line);
    if (shipped != null) {
      // Every backticked identifier on the line, not just those before the
      // first `)`.
      //
      // It used to stop at `split(')').first`, to avoid reading the prose after
      // the `(lib/l10n/app_en.arb)` parenthetical. That parenthetical contains
      // no backticks, so there was nothing to avoid — and three entries named a
      // second key after it, which the guard therefore never saw. `dtcMilOn`,
      // `derivedFuelSourceUnavailable` and
      // `powertrainNotInstallableInThisRelease` all read as guarded and were
      // not, one of them a key this file was written for. Each of those now has
      // its own entry, which is the deeper fix; this is the one that stops the
      // shape recurring.
      keys = _key.allMatches(shipped.group(1)!).map((m) => m.group(1)!).toList();
    }
  }
  flush();
  return hedges;
}

Map<String, String> _arb([String file = 'app_en.arb']) {
  final raw = jsonDecode(File('lib/l10n/$file').readAsStringSync());
  return <String, String>{
    for (final e in (raw as Map<String, dynamic>).entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

void main() {
  final hedges = _readRegister();
  final arb = _arb();
  final zhArb = _arb('app_zh_Hant.arb');

  test('the register names keys that exist', () {
    final missing = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        if (!arb.containsKey(key)) missing.add('#${hedge.number} $key');
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'A hedge that points at a key which no longer exists guards nothing '
          'and reads as though it does:\n${missing.join('\n')}',
    );
  });

  test('every shipped hedge still says what the register says it says', () {
    // Substring, not equality: several entries record the load-bearing clause
    // rather than the whole shipped sentence, and the ARB entry may add a
    // second sentence around it. What may not happen is the clause going away.
    final broken = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        final shipped = arb[key];
        if (shipped == null) continue;
        final actual = _plain(shipped);
        // `==` by default. `contains` is opt-in, per entry, and visible in the
        // register as `**English (clause)**` — because a substring check passes
        // a translation that keeps the hedge and appends a sentence reversing
        // it. A reviewer proved that: adding 'On most vehicles this is safe, so
        // clearing now is fine.' after entry 11's clause satisfied every
        // positive-presence check in the suite. Softening by addition instead
        // of subtraction is the ordinary shape of translation drift, and with
        // `contains` everywhere it was invisible everywhere.
        // A clause entry is checked twice: the fragment must survive, and the
        // shipped string must not have grown by more than one sentence around
        // it. Without the second half the escape hatch is free — a hedge is
        // just as dead when a translation keeps it and appends '…but this is
        // usually fine' as when it deletes it.
        final ok = hedge.clauseOnly
            ? actual.contains(hedge.english) &&
                  _sentences(actual) <= _sentences(hedge.english) + 1
            : actual == hedge.english;
        if (!ok) {
          broken.add(
            '#${hedge.number} $key  (${hedge.clauseOnly ? 'clause' : 'exact'})\n'
            '  register: ${hedge.english}\n'
            '  shipped:  $actual',
          );
        }
      }
    }
    expect(
      broken,
      isEmpty,
      reason:
          'Shipped copy no longer contains the hedge the register holds it to. '
          'Either the translation was softened — which is the defect this file '
          'exists to catch — or the register is stale and should be updated in '
          'the same change that moved the copy.\n\n${broken.join('\n\n')}',
    );
  });

  test('the Chinese half is held to what ships too', () {
    // Only where the entry names an ARB key — the unkeyed entries quote zh from
    // source files across the tree, and `glossary_evidence_test.dart` holds
    // those to their line numbers instead.
    //
    // A reviewer defeated a structural guard on the English by swapping 「已」
    // for 「未」, which moved no index it was checking. Pinning the sentence
    // verbatim is what makes any edit fail, and the Chinese needs that as much
    // as the English does — more so, because the Chinese is what most of this
    // app's users read.
    final broken = <String>[];
    for (final hedge in hedges) {
      final recorded = hedge.chinese;
      if (recorded == null) continue;
      for (final key in hedge.keys) {
        final shipped = zhArb[key];
        if (shipped == null) continue;
        if (_plain(shipped) != recorded) {
          broken.add(
            '#${hedge.number} $key\n'
            '  register: $recorded\n'
            '  shipped:  ${_plain(shipped)}',
          );
        }
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n\n'));
  });

  test('every keyed entry has a Chinese line that parsed', () {
    // `hedges` only ever holds keyed entries, so this is exact rather than a
    // floor — and it is the asymmetry that made the last hole invisible.
    //
    // A broken `**English**` line stops the hedge being built at all, so the
    // count disagrees with the number of `Shipped as` lines and the control
    // fires. A broken `**繁體中文**` line just leaves `chinese` null, which is
    // legitimate for the unkeyed entries, so nothing could tell "there is no
    // Chinese here" from "the Chinese line stopped parsing".
    //
    // A reviewer found the way in: `_chinese` accepts —, – and -, but not
    // U+FF0D `－`, which is what a CJK IME produces in fullwidth mode — on the
    // one line that is by definition typed with a CJK IME. Swapping that
    // character on entry 11 dropped it from the guard, and gutting its Chinese
    // to 「這次沒有讀到凍結幀。可以直接清除。」 then passed. That entry is the
    // one whose own note says the mistake it prevents is irreversible: clearing
    // destroys an unread freeze frame permanently.
    //
    // Adding U+FF0D to the character class would be the arms race again. The
    // assertion is the fix.
    final unparsed = hedges
        .where((h) => h.chinese == null)
        .map((h) => '#${h.number} ${h.title}')
        .toList();
    expect(
      unparsed,
      isEmpty,
      reason: 'A keyed entry whose 繁體中文 line stopped parsing is silently '
          'unguarded, and the count-based control cannot see it:\n'
          '${unparsed.join('\n')}',
    );
  });

  test('no shipped string carries Markdown emphasis', () {
    // `_fromRegister` strips `**` from the register side only, so a shipped
    // string carrying it now fails the comparison — but it fails saying the
    // sentences differ, which sends the next reader looking for a wording
    // change that is not there. This says what actually happened.
    final withEmphasis = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        for (final entry in {'en': arb[key], 'zh': zhArb[key]}.entries) {
          if (entry.value?.contains('**') ?? false) {
            withEmphasis.add('#${hedge.number} $key (${entry.key})');
          }
        }
      }
    }
    expect(
      withEmphasis,
      isEmpty,
      reason: 'These would render literal asterisks to a reader:\n'
          '${withEmphasis.join('\n')}',
    );
  });

  test('the parser reads every entry the file actually contains', () {
    // The control, and it counts against the file rather than against a floor.
    //
    // A floor cannot see a key lost inside a line that still parses, nor an
    // entry that stops parsing: 21 keyed entries becoming 20 satisfied
    // `>= 20` while `dtcRescanFirst` sat unguarded behind one substituted
    // dash. A control that counts is not a control that reads.
    final lines = File('docs/i18n/hedge-register.md').readAsLinesSync();
    final shippedLines =
        lines.where((l) => l.startsWith('**Shipped as**')).length;
    final headings = lines.where((l) => _entry.hasMatch(l)).length;

    expect(
      hedges.length,
      shippedLines,
      reason:
          'the file has $shippedLines "Shipped as" lines and the parser built '
          '${hedges.length} hedges. Every one of them names at least one key, '
          'so a shortfall means an entry stopped parsing — most likely its '
          '**English** line, whose dash and spacing are the fragile part.',
    );

    // Every entry must reach a shipped key eventually; the ones that have not
    // are `proposed` and are named, so the number is a fact rather than a
    // budget.
    final unkeyed = headings - hedges.length;
    expect(
      unkeyed,
      greaterThanOrEqualTo(0),
      reason: 'more hedges than headings — the parser is inventing entries',
    );
    expect(hedges, isNotEmpty);
  });
}
