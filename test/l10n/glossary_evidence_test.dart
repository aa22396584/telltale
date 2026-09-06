// Keeps docs/i18n/glossary.md honest.
//
// A glossary is only worth reviewing against if its claims are still true. Every row cites
// the file AND LINE where this project already established the pairing; this test opens
// those lines and checks the terms are still there. Rename a label without touching the
// glossary and this fails.
//
// The line numbers are load-bearing, and an earlier version of this file threw them away.
// Whole-file containment made the guard far weaker than the glossary claimed: changing one
// cited occurrence of 閘門 still passed because the word appeared elsewhere in the same
// file, and a fabricated row citing README.md ↔ README.zh-TW.md passed for any two words
// that happen to appear in those two large documents. Both were demonstrated, not
// theorised. Keeping a window of a few lines absorbs ordinary edits above the citation
// without absorbing a rename.
//
// It deliberately does NOT judge translation quality. It answers one question a machine can
// answer honestly: is the evidence still where the glossary says it is?
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// How far from the cited line a term may have drifted before this fails.
///
/// Edits above a citation shift it; a rename does not move it. Three lines is wide enough
/// for the first and far narrower than the documents, which is what makes the check bite.
const _window = 3;

class _Term {
  _Term({
    required this.zh,
    required this.en,
    required this.status,
    required this.evidence,
    required this.note,
    required this.line,
  });

  final String zh;
  final String en;

  /// Written by hand, never computed. `evidenced` claims both languages appear together at
  /// a cited place. `proposed` admits the English is a reviewer's invention with no source.
  /// `inferred` admits the two languages were never written down together — the pairing is
  /// this project's, but assembled from two files.
  final String status;
  final String evidence;
  final String note;
  final int line;

  bool get isProposed => status.toLowerCase().startsWith('proposed');
  bool get isInferred => status.toLowerCase().startsWith('inferred');

  @override
  String toString() => 'glossary.md:$line  $zh / $en';
}

/// A file path in an Evidence cell, with the line span it points at.
class _Citation {
  _Citation(this.path, this.from, this.to);
  final String path;
  final int? from;
  final int? to;
  bool get hasSpan => from != null;
  @override
  String toString() => hasSpan ? '$path:$from${to != from ? "-$to" : ""}' : path;
}

final _citation = RegExp(
  r'(?<![\w/.])'
  r'((?:lib|test|tool|docs|android|ios|integration_test|store)/[\w./-]+\.\w+'
  r'|README(?:\.zh-TW)?\.md|CONTRIBUTING\.md|PRIVACY\.md|SECURITY\.md|CHANGELOG\.md'
  r'|CODE_OF_CONDUCT\.md|THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY\.md'
  r'|pubspec\.yaml|l10n\.yaml)'
  r'(?::(\d+)(?:\s*[-–]\s*(\d+))?)?',
);

List<_Citation> _citations(String evidence) => _citation
    .allMatches(evidence)
    .map((m) => _Citation(
          m.group(1)!,
          m.group(2) == null ? null : int.parse(m.group(2)!),
          m.group(3) == null
              ? (m.group(2) == null ? null : int.parse(m.group(2)!))
              : int.parse(m.group(3)!),
        ))
    .toList();

/// Whitespace removed, so a term wrapped across a source line still matches. Chinese has no
/// word spaces, and Markdown hard-wraps prose — 連線世代 is written 連線\n世代 in
/// README.zh-TW.md.
String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), '');

/// Line wraps healed into single spaces.
///
/// English needs the spaces kept: they are what makes a word boundary. Markdown wraps
/// "OBD2 fault diagnosis" as "OBD2\nfault diagnosis", and removing whitespace outright —
/// correct for Chinese, which has no word spaces — glues the phrase to its neighbours and
/// destroys the very boundary the match depends on.
String _unwrap(String s) => s.replaceAll(RegExp(r'\s+'), ' ');

/// The cited window, or the whole file when the citation named no line.
String _excerpt(_Citation c) {
  final lines = File(c.path).readAsLinesSync();
  if (!c.hasSpan) return lines.join('\n');
  final from = (c.from! - 1 - _window).clamp(0, lines.length);
  final to = (c.to! + _window).clamp(0, lines.length);
  return lines.sublist(from, to).join('\n');
}

bool _containsChinese(String haystack, String needle) =>
    haystack.contains(needle) || _collapse(haystack).contains(_collapse(needle));



/// camelCase and PascalCase split into words, so `headerNotOnThisBus` reads as
/// "header not on this bus" and `displacementL` as "displacement l".
///
/// T3 evidence is a Dart identifier beside a Chinese label, and the English term is usually
/// a segment of that identifier rather than a standalone word. Splitting the haystack keeps
/// whole-word matching honest: `gated` has no case boundary, so it still does not evidence
/// `gate` — which was a real fabricated-row experiment against an earlier version of this
/// file.
String _decamelize(String s) => s
    .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAllMapped(RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAllMapped(RegExp(r'([a-zA-Z])([0-9])'), (m) => '${m[1]} ${m[2]}')
    .toLowerCase();

/// A whole-word match that tolerates ordinary English inflection.
///
/// The README says "freeze frames", "fault codes", "gauges" and "uninstalling" where the
/// glossary lists the base form; requiring an exact boundary rejected fifteen rows whose
/// evidence was perfectly good. The suffix list is closed, so it admits inflection and not
/// arbitrary longer words — and the pairing check below, not this one, is what stops a
/// fabricated row riding on a coincidental substring.
bool _matchesBounded(String body, String phrase) {
  final escaped = RegExp.escape(phrase);
  return RegExp('(?<![a-z0-9])$escaped(?:s|es|d|ed|ing)?(?![a-z0-9])').hasMatch(body);
}

/// English match with word boundaries, plus the identifier form.
///
/// Without boundaries `gate` was satisfied by `gated` and `hash` by `hashCode`, so a
/// fabricated row could ride on any longer word. T3 evidence is a Dart identifier beside a
/// Chinese label, so `oxygen sensor` is legitimately evidenced by `oxygenSensor`; that form
/// is matched separately rather than by loosening the phrase match.
bool _containsEnglish(String haystack, String needle) {
  final body =
      '${_unwrap(haystack.toLowerCase())}\n${_unwrap(_decamelize(haystack))}';
  var phrase = _unwrap(needle.toLowerCase());
  if (_matchesBounded(body, phrase)) return true;
  // A term written with a parenthetical gloss is also evidenced without it:
  // "gasoline particulate filter (GPF)" by "gasoline particulate filter".
  final withoutGloss = phrase.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  if (withoutGloss != phrase && _matchesBounded(body, withoutGloss)) return true;
  phrase = _unwrap(needle.toLowerCase());
  final identifier = phrase.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (identifier.length < 5) return false;
  return RegExp('(?<![a-z0-9])$identifier(?![a-z0-9])')
      .hasMatch(body.replaceAll(RegExp(r'[^a-z0-9]'), ' '));
}


/// Two files that are the same document in two languages.
///
/// `README.md` and `README.zh-TW.md` are translations of each other by construction — the
/// language switcher on line 1 of each says so. A citation naming a line in both therefore
/// IS a paired citation, not two unrelated documents. Any other combination of files is a
/// pairing this glossary assembled, and must say so with the `inferred` status.
bool _areTranslationPair(String a, String b) {
  if (a == b) return false;
  // The ARB files are one key set in two languages; an entry in app_en.arb and the same key
  // in app_zh_Hant.arb are as paired as two sides of the README.
  const arbs = {
    'lib/l10n/app_en.arb',
    'lib/l10n/app_zh.arb',
    'lib/l10n/app_zh_Hant.arb',
  };
  if (arbs.contains(a) && arbs.contains(b)) return true;
  String stem(String p) => p.replaceAll('.zh-TW.md', '.md');
  return stem(a) == stem(b);
}

({List<_Term> terms, int tableRows}) _parseGlossary(File file) {
  final terms = <_Term>[];
  final lines = file.readAsLinesSync();
  var tableRows = 0;
  // The Known-gaps table is the one three-column table in the file, and it is recognised by
  // its own header rather than by "everything after this heading". Skipping to end-of-file
  // was a hole: a row appended below that point was neither parsed nor counted, so it was
  // invisible to every check here — including the row-count parity test meant to catch
  // exactly that.
  var inKnownGapsTable = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('| Concept |')) {
      inKnownGapsTable = true;
      continue;
    }
    if (inKnownGapsTable) {
      if (!line.startsWith('|')) inKnownGapsTable = false;
      if (inKnownGapsTable) continue;
    }
    if (!line.startsWith('| ')) continue;
    if (line.startsWith('|---') || line.startsWith('| 繁體中文')) continue;
    tableRows++;
    final cells = line
        .split(RegExp(r'(?<!\\)\|'))
        .map((c) => c.replaceAll(r'\|', '|').trim())
        .toList();
    if (cells.length < 6) continue; // counted, not parsed — the test below catches it
    terms.add(_Term(
      zh: cells[1],
      en: cells[2],
      evidence: cells[3],
      status: cells[4],
      note: cells.length > 5 ? cells[5] : '',
      line: i + 1,
    ));
  }
  return (terms: terms, tableRows: tableRows);
}

void main() {
  final glossary = File('docs/i18n/glossary.md');
  final parsed = _parseGlossary(glossary);
  final terms = parsed.terms;

  test('every table row parses — none is silently dropped', () {
    expect(glossary.existsSync(), isTrue);
    // Not a lower bound. A threshold like ">= 100" let a whole 15-row section switch to a
    // three-column shape and disappear while the suite stayed green, taking safety terms
    // with it. Row count in, row count out.
    expect(
      terms.length,
      parsed.tableRows,
      reason:
          '${parsed.tableRows - terms.length} row(s) did not parse into five columns and '
          'would have been skipped without any test noticing',
    );
    expect(terms, isNotEmpty);
  });

  test('every row cites a file that exists, with a line number', () {
    final broken = <String>[];
    for (final term in terms) {
      final cited = _citations(term.evidence);
      if (cited.isEmpty) {
        broken.add('$term — evidence names no file: "${term.evidence}"');
        continue;
      }
      final live = cited.where((c) => File(c.path).existsSync()).toList();
      if (live.isEmpty) {
        broken.add('$term — none of ${cited.map((c) => c.path).toSet()} exist any more');
        continue;
      }
      if (!live.any((c) => c.hasSpan)) {
        broken.add(
          '$term — no line number anywhere in "${term.evidence}". Whole-file evidence is '
          'not evidence: it passes for any word that appears anywhere in the document.',
        );
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
  });

  test('the Chinese term is still at the cited line', () {
    final stale = <String>[];
    for (final term in terms) {
      final cited = _citations(term.evidence)
          .where((c) => File(c.path).existsSync() && c.hasSpan)
          .toList();
      if (cited.isEmpty) continue; // reported above
      if (!cited.any((c) => _containsChinese(_excerpt(c), term.zh))) {
        stale.add(
          '$term — "${term.zh}" is not within $_window lines of $cited. Either the label '
          'moved or was renamed without updating the glossary, or the citation is wrong.',
        );
      }
    }
    expect(stale, isEmpty, reason: stale.join('\n'));
  });

  test('the English term is still at the cited line', () {
    final stale = <String>[];
    for (final term in terms) {
      if (term.isProposed) continue; // declares it has no source in the tree
      final cited = _citations(term.evidence)
          .where((c) => File(c.path).existsSync() && c.hasSpan)
          .toList();
      if (cited.isEmpty) continue;
      if (!cited.any((c) => _containsEnglish(_excerpt(c), term.en))) {
        stale.add('$term — "${term.en}" is not within $_window lines of $cited');
      }
    }
    expect(stale, isEmpty, reason: stale.join('\n'));
  });

  test('an evidenced pairing was actually written down together', () {
    // The strongest of these checks, and the one the first version lacked entirely. Without
    // it, "zh appears in README.zh-TW.md and en appears in README.md" accepts any two words
    // from two large documents — a fabricated row passes.
    //
    // `inferred` rows opt out by admitting the pairing was assembled from two places. That
    // is an honest state for a real term; it is not a way to silence this check, because
    // the status is written by hand and shows up in review.
    final unpaired = <String>[];
    for (final term in terms) {
      if (term.isProposed || term.isInferred) continue;
      final cited = _citations(term.evidence)
          .where((c) => File(c.path).existsSync() && c.hasSpan)
          .toList();
      if (cited.isEmpty) continue;
      final zhAt = cited.where((c) => _containsChinese(_excerpt(c), term.zh)).toList();
      final enAt = cited.where((c) => _containsEnglish(_excerpt(c), term.en)).toList();
      final together = zhAt.any(
        (z) => enAt.any(
          (e) => z.path == e.path || _areTranslationPair(z.path, e.path),
        ),
      );
      if (!together) {
        unpaired.add(
          '$term — no cited window, and no pair of windows in one document\'s two language '
          'versions, holds both terms. The pairing may still be '
          'right, but it is this glossary\'s inference rather than something the project '
          'wrote down. Mark the row `inferred`, or cite the place that has both.',
        );
      }
    }
    expect(unpaired, isEmpty, reason: unpaired.join('\n'));
  });

  test('no term is listed twice with two different English forms', () {
    final byZh = <String, Set<String>>{};
    for (final term in terms) {
      byZh.putIfAbsent(term.zh, () => <String>{}).add(term.en);
    }
    final conflicts = byZh.entries
        .where((e) => e.value.length > 1)
        .map((e) => '${e.key} → ${e.value.join(" / ")}')
        .toList();
    expect(
      conflicts,
      isEmpty,
      reason:
          'one Chinese term with two English forms is how a screen ends up saying two '
          'things for one concept:\n${conflicts.join("\n")}',
    );
  });

  test('no English term is the translation of two different Chinese terms', () {
    // The mirror of the check above, and it was missing. 設定 and 設定頁 both mapped to
    // "Settings", so a translator working from English had no way to know which Chinese
    // term to use. Rows that disambiguate in their Note are the legitimate case.
    final byEn = <String, Set<String>>{};
    final disambiguated = <String>{};
    for (final term in terms) {
      byEn.putIfAbsent(term.en, () => <String>{}).add(term.zh);
      if (term.note.contains('context:')) disambiguated.add(term.en);
    }
    final collisions = byEn.entries
        .where((e) => e.value.length > 1 && !disambiguated.contains(e.key))
        .map((e) => '${e.key} ← ${e.value.join(" / ")}')
        .toList();
    expect(
      collisions,
      isEmpty,
      reason:
          'a translator going from English cannot tell these apart; give the narrower row '
          'a Note beginning "context:" or merge them:\n${collisions.join("\n")}',
    );
  });

  test('the glossary never translates a do-not-translate token', () {
    // The first version compared the do-not-translate list against the CHINESE column. The
    // list is almost entirely ASCII, so no input could ever make it red. The English column
    // is the side that can contradict it.
    final tokens = <String>{};
    for (final line in File('docs/i18n/do-not-translate.md').readAsLinesSync()) {
      if (!line.startsWith('- `')) continue;
      // Take only the backticked token, then drop any gloss inside it. An entry reads
      // `` - `Language / 語言 (bilingual section title …)` ``, and keeping the parenthetical
      // produced a key that matched nothing — which is how a real contradiction stayed
      // hidden: the glossary translated "Language / 語言" while this list said not to.
      final end = line.indexOf('`', 3);
      if (end < 0) continue;
      var token = line.substring(3, end).trim();
      final gloss = token.indexOf(' (');
      if (gloss > 0) token = token.substring(0, gloss).trim();
      tokens.add(token);
    }
    expect(tokens, isNotEmpty, reason: 'the do-not-translate list did not parse');

    final contradictions = <String>[];
    for (final term in terms) {
      if (term.zh == term.en) continue; // carried through untranslated, which is the point
      for (final side in [term.zh, term.en]) {
        if (tokens.contains(side)) {
          contradictions.add(
            '"$side" is on the do-not-translate list, but glossary.md:${term.line} pairs '
            '${term.zh} with ${term.en}',
          );
        }
      }
    }
    expect(contradictions, isEmpty, reason: contradictions.join('\n'));
  });
}
