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
//
// Its holes were structural rather than accidental. Only the Evidence column was
// parsed, so a citation written in the Note column was never opened at all; and
// `cited.any(...)` passed a row as soon as ONE of its citations held, so a second
// citation on the same row could drift with nothing going red. Both columns are parsed
// now, and every citation is judged on its own.
//
// The rule is per-citation and language-aware. A citation into an English source must
// still hold the English term, one into a Chinese source the Chinese term, and one into
// a Dart source either of them, because T3 evidence is an English identifier sitting
// beside a Chinese label. `_sourceLanguage` is where a file is classified, and a cited
// file it does not classify fails rather than defaulting to a language.
//
// A citation is not always made for the row's own term. A Note names the place a
// DIFFERENT word is used, and an Evidence cell cites a document's own heading in order
// to say it differs from the table label. Cells like those quote what they claim is
// there, so a quoted or backticked string from the same cell also satisfies that cell's
// citations. What that does not do is bind a quote to one citation: a cell with several
// quotes accepts any of them at any of its own citations, so a citation that has drifted
// can still be excused by a sibling's quote. The rule without the quotes was measured
// against this glossary before it was written, and it failed rows whose citations are
// honest — which would have meant rewriting the glossary to suit the checker.
//
// A citation does not have to be a full path. Cells write `; :86` for another line of
// the file just named, `README.md:99,212` for a second line after a comma, and
// `README.md:21/README.zh-TW.md:20` for two citations joined by a slash. Each of those
// is read and held to the same rule as a full path, and the fixtures below say which
// shapes those are. A bare line number resolves to the file its cell named most
// recently, and fails if the cell named none.
//
// The shape that is still not read is a SHORT file name, written like `field-guide:211`
// or `app_zh_Hant.arb:9`. Those are held to nothing, and resolving them against the last
// full path in the cell is exactly the wrong repair — `app_zh_Hant.arb:9` would be
// checked against README.zh-TW.md. Write the full
// path to have one checked.
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

/// A cited file, with the line span it points at and the shape it was written in.
///
/// [form] is carried so a failure can say which shape it read. A bare line number that
/// resolved to the wrong file and a full path that drifted look identical otherwise.
class _Citation {
  _Citation(this.path, this.from, this.to, this.form);
  final String path;
  final int? from;
  final int? to;
  final String form;
  bool get hasSpan => from != null;
  @override
  String toString() => hasSpan ? '$path:$from${to != from ? "-$to" : ""}' : path;
}

/// What a bare line number resolves to when its cell named no file before it.
///
/// A path no file system can answer, so the citation is reported by the test below
/// rather than silently skipped as a file that does not exist.
const _noFileNamedYet = '<no file named earlier in this cell>';

/// A full path, optionally with a line, a span, and a comma-separated tail.
///
/// The leading guard admits a path after a `/` only when a digit precedes that `/`.
/// `README.md:21/README.zh-TW.md:20` joins two citations with no space between them,
/// and the second was invisible; `docs/README.md` is one path whose tail must not be
/// read as a second citation, and there the character before the `/` is a letter.
final _citation = RegExp(
  r'(?:(?<![\w/.])|(?<=\d/))'
  r'((?:lib|test|tool|docs|android|ios|integration_test|store)/[\w./-]+\.\w+'
  r'|README(?:\.zh-TW)?\.md|CONTRIBUTING\.md|PRIVACY\.md|SECURITY\.md|CHANGELOG\.md'
  r'|CODE_OF_CONDUCT\.md|THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY\.md'
  r'|pubspec\.yaml|l10n\.yaml)'
  r'(?::(\d+)(?:\s*[-–]\s*(\d+))?((?:\s*,\s*\d+(?:\s*[-–]\s*\d+)?)*))?',
);

/// `:86` standing alone, meaning another line of the file the cell last named.
///
/// The required space in front is the whole rule, and it is what keeps this from
/// attributing a line to the wrong file. Cells write `; :86 busBusy` for a second line
/// of the file just cited, and `app_zh_Hant.arb:9` or `field-guide:211` for a file named
/// in short. Resolving the second shape against the last full path would turn
/// `app_zh_Hant.arb:9` into `README.zh-TW.md:9` — a citation checked against a file its
/// author never named. Short file names are therefore still not citations at all; they
/// are named in the header as a shape this does not read.
final _sameFileLine = RegExp(r'(?<=\s):(\d+)(?:\s*[-–]\s*(\d+))?');

/// The `,212` in `README.md:99,212`: further lines of the path just matched.
final _sameFileExtra = RegExp(r'(\d+)(?:\s*[-–]\s*(\d+))?');

/// Where a cell's quoted and backticked claims sit, as character ranges.
///
/// A bare line number inside one of them belongs to the quotation:
/// `README.md:56 'the error is 錯誤 :404 here'` would otherwise invent README.md:404
/// and check a window nobody cited. That can only ADD a citation, so it invents
/// failures rather than hiding them — except through the pairing test, where an
/// invented window can supply a term the row does not really have evidence for.
/// Nothing in the glossary trips it today, and excluding it keeps that true by
/// construction rather than by luck.
///
/// Full paths are deliberately NOT excluded this way. A path written inside quotes is
/// still a file somebody named, and the census tests should see it. A path with no
/// line is still parsed — otherwise the census could not name it — and then named,
/// because a whole file is not a window this file can judge.
List<({int from, int to})> _claimSpans(String cell) => [
      ..._quotedClaim.allMatches(cell),
      ..._backtickedClaim.allMatches(cell),
    ].map((m) => (from: m.start, to: m.end)).toList();

List<_Citation> _citations(String cell) {
  final cited = <_Citation>[];
  final namedAt = <int, String>{};
  for (final m in _citation.allMatches(cell)) {
    final path = m.group(1)!;
    namedAt[m.start] = path;
    final from = m.group(2) == null ? null : int.parse(m.group(2)!);
    final to = m.group(3) == null ? from : int.parse(m.group(3)!);
    cited.add(_Citation(path, from, to, 'a path'));
    final more = m.group(4);
    if (more == null || more.isEmpty) continue;
    for (final extra in _sameFileExtra.allMatches(more)) {
      final line = int.parse(extra.group(1)!);
      cited.add(_Citation(
        path,
        line,
        extra.group(2) == null ? line : int.parse(extra.group(2)!),
        'a further line after a comma',
      ));
    }
  }
  final quoted = _claimSpans(cell);
  for (final m in _sameFileLine.allMatches(cell)) {
    // Inside a quotation, `:404` is part of what is being quoted, not a citation.
    if (quoted.any((span) => m.start >= span.from && m.start < span.to)) continue;
    var path = _noFileNamedYet;
    var nearest = -1;
    namedAt.forEach((start, named) {
      if (start < m.start && start > nearest) {
        nearest = start;
        path = named;
      }
    });
    final line = int.parse(m.group(1)!);
    cited.add(_Citation(
      path,
      line,
      m.group(2) == null ? line : int.parse(m.group(2)!),
      'a bare line number',
    ));
  }
  return cited;
}

/// Directories that exist only in the public repository.
///
/// `ImL1s/torque` is the source of truth and this repository is derived from it,
/// but a few paths travel the other way and live only here: the store listing
/// material, the public CI, and the GitHub Pages shell. torque's CLAUDE.md calls
/// them publish-only and its mirror excludes them in both directions.
///
/// The glossary itself IS mirrored, and five of its rows are store vocabulary
/// whose only written source is `store/README.md`. In the private checkout that
/// file is absent, so the source of truth could not run its own test suite --
/// found on 2026-09-07, the first time the l10n work was mirrored back.
/// Matched in the shape the mirror actually excludes: `store/`, and the Pages
/// HTML as `docs/<name>.html`.
///
/// Not a `startsWith` list. `'docs/index'` as a prefix also matches
/// `docs/index_notes.md`, which IS mirrored -- so a citation into it would have
/// been exempted here while being a perfectly ordinary path over there.
///
/// `.github/` is publish-only too and is deliberately absent: the citation
/// pattern above admits only lib|test|tool|docs|android|ios|integration_test|
/// store, so no citation can name a path under it, and an entry nothing can
/// reach reads like coverage that does not exist.
final _pagesHtml = RegExp(r'^docs/[^/]+\.html$');

bool _isPublishOnly(String path) =>
    path.startsWith('store/') || _pagesHtml.hasMatch(path);

/// The publish-only artefacts, as a set rather than as one directory.
///
/// torque's CLAUDE.md names four of these -- `store/`, `.github/`,
/// `docs/.nojekyll` and `docs/*.html` -- and the private checkout has none of
/// them. Asserting on `store/` alone left the marker check with a hole: a public
/// checkout with `store/` moved away still has the other three, so it read as
/// private and switched the exemption on with nothing going red.
///
/// An OR over the set, so removing any one of them locally does not make a
/// public tree look private, and the list does not have to be exhaustive to
/// work -- `docs/index.en.html` is publish-only too and is not named here.
/// `store/` and `.github/` are the durable two; the HTML filenames could be
/// renamed.
const _publishOnlyArtefacts = [
  'store',
  '.github',
  'docs/.nojekyll',
  'docs/index.html',
  'docs/privacy.html',
];

/// The rows whose evidence lives only in the public repository, written down.
///
/// A roster, not a rule. `cited.every(_isPublishOnly)` on its own would exempt
/// any future row that happens to cite only `store/`, silently and with no
/// review signal -- and it would exempt a typo like `store/READM.md` on exactly
/// the same terms. Holding the computed set equal to this one means a sixth row
/// joining it has to be written here, where somebody reads it.
/// Every publish-only PATH the glossary cites, written down.
///
/// `_isPublishOnly` is a shape — `store/`, and the Pages HTML — and a shape cannot tell
/// `store/README.md` from `store/READM.md`. In the private checkout neither is present,
/// so an exemption keyed on the shape skips both, and the typo is invisible there: the
/// citation is skipped as publish-only and then skipped again as a file that cannot be
/// opened. It only surfaces once somebody mirrors the row here.
///
/// The roster below this one pins ROWS, which is what the Evidence column needs. This
/// pins paths, which is what a Note needs: a Note may cite a publish-only file on a row
/// whose evidence is not publish-only at all, so no row-level roster can see it.
/// Computed in both checkouts, so the typo fails in the one where the file is absent.
const _publishOnlyCited = {'store/README.md'};

const _exemptedInPrivate = {
  '主打圖片（feature graphic）',
  '性能量測',
  '應用程式圖示',
  '手機截圖',
  '面盤外觀',
};

/// True in the private source-of-truth checkout, where this package sits under
/// `app/` beside the reverse-engineering spec that may never be published.
///
/// The exemption below keys on *which repository this is*, deliberately not on
/// whether `store/` happens to be present. Keying it on the absence of the very
/// thing being checked would make it circular: delete `store/README.md` here and
/// five rows would quietly stop being verified. As written, that deletion still
/// fails in this repository, and the rows are only unverifiable in the checkout
/// that by design does not carry the file.
final _isPrivateCheckout =
    File('../torque_architecture_spec.md').existsSync();

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
/// a segment of that identifier rather than a standalone word. Splitting the haystack is
/// what lets `oxygenSensor` evidence "oxygen sensor" without loosening the phrase match,
/// and it creates no boundary inside `gated`.
///
/// It does not follow that `gated` fails to evidence the TERM `gate`: `_matchesBounded`
/// below admits `-d` as an inflection, so it does. An earlier version of this comment said
/// otherwise, which was a claim about a guard the code did not make. Inflection is allowed
/// for a term, which the glossary lists in its base form; it is refused for a quoted claim,
/// which is a quotation and is checked as written. `_holdsClaim` is where that split
/// lives, and the fixtures beside it pin both halves.
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

/// The language a cited file is written in, or null when nothing has classified it.
///
/// The rule below asks an English source for the English term and a Chinese source for
/// the Chinese one, so it has to know which a file is. Returning null rather than a
/// default is the point: a file nobody has classified would otherwise be asked for
/// whichever term the default names, and the failure would read as a stale citation
/// rather than as the unanswered question it is. The test below turns null into that
/// question.
///
/// Dart sources are [_either] because T3 evidence is an English identifier beside a
/// Chinese label; this rule does not decide which of the two a given line carries.
const _english = 'English';
const _chinese = 'Chinese';
const _either = 'bilingual';

String? _sourceLanguage(String path) {
  if (path.endsWith('.dart')) return _either;
  if (path.endsWith('.zh-TW.md')) return _chinese;
  if (path.startsWith('lib/l10n/app_zh')) return _chinese;
  if (path == 'lib/l10n/app_en.arb') return _english;
  if (path == 'README.md') return _english;
  // Chinese prose whose tables carry English filenames. The listing copy itself lives
  // under store/en-US and store/zh-TW, which nothing in the glossary cites.
  if (path == 'store/README.md') return _chinese;
  if (path == 'docs/verification/review-log.md') return _chinese;
  return null;
}

/// The strings a cell puts in quotes or backticks: its own account of what it will find
/// at the lines it cites.
///
/// The opening quote may not follow a letter or a digit, so the apostrophe in "the zh
/// doc's own H1" does not open one. Pairing from it would swallow the real quote that
/// follows and lose the claim entirely.
final _quotedClaim = RegExp(r"(?<![A-Za-z0-9])'([^']+)'(?![A-Za-z0-9])");
final _backtickedClaim = RegExp(r'`([^`]+)`');

List<String> _claims(String cell) => [
      ..._quotedClaim.allMatches(cell).map((m) => m.group(1)!),
      ..._backtickedClaim.allMatches(cell).map((m) => m.group(1)!),
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

/// Any Han character, which is what routes a claim to the Chinese rule.
final _hasHan = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');

/// A quoted claim, held to the rules of the language it is written in.
///
/// Both halves matter and the first was wrong. `_containsChinese` is plain containment,
/// which is right for Chinese — no word spaces, no inflection — and asked of an English
/// claim it is the substring rule this file exists to refuse: `gate` was "present" in
/// `aggregate`, and `match` in `mismatched`. An English claim now needs word boundaries.
///
/// It needs them WITHOUT the inflection the terms get. A term is the glossary's base form
/// and the prose around it is inflected, so `_matchesBounded` allows `-s`, `-ed` and the
/// rest. A claim is a quotation of the cited line, so it is checked as quoted: `'gate'`
/// does not read `gated`. That is stricter than the term rule on purpose.
///
/// A claim carrying any Han character keeps containment and is matched whole, so its
/// English half cannot drift on its own.
///
/// Claims are read from single quotes and backticks. One written in double quotes is not
/// read at all, which can make a citation harder to satisfy and never easier.
bool _holdsClaim(String excerpt, String claim) {
  if (_hasHan.hasMatch(claim)) return _containsChinese(excerpt, claim);
  final body =
      '${_unwrap(excerpt.toLowerCase())}\n${_unwrap(_decamelize(excerpt))}';
  final phrase = RegExp.escape(_unwrap(claim.toLowerCase()));
  return RegExp('(?<![a-z0-9])$phrase(?![a-z0-9])').hasMatch(body);
}

/// Every line-numbered citation into a source of [language], each judged alone.
///
/// There is no `proposed` exemption here: a `proposed` row's citations are held to the
/// same rule as every other row's.
///
/// That is not a detector for an invented English term, and an earlier version of this
/// comment said it was. This fires when a term is ABSENT from a cited window. The
/// anomaly `proposed` describes — an English form nobody confirmed that turns out to be
/// sitting at the cited line — makes nothing here go red.
List<String> _driftedCitations(List<_Term> terms, String language) {
  final drifted = <String>[];
  for (final term in terms) {
    for (final (column, cell) in [
      ('Evidence', term.evidence),
      ('Note', term.note),
    ]) {
      final claims = _claims(cell);
      for (final citation in _citations(cell)) {
        if (!citation.hasSpan) {
          drifted.add(
            '$term — the $column cell cites $citation (${citation.form}) with no '
            'line number, so nothing is held to it. A path without a line is '
            'not a citation this file can judge.',
          );
          continue;
        }
        if (!File(citation.path).existsSync()) continue;
        if (_sourceLanguage(citation.path) != language) continue;
        final excerpt = _excerpt(citation);
        final held = switch (language) {
          _chinese => _containsChinese(excerpt, term.zh),
          _english => _containsEnglish(excerpt, term.en),
          _ => _containsChinese(excerpt, term.zh) ||
              _containsEnglish(excerpt, term.en),
        };
        if (held) continue;
        if (claims.any((claim) => _holdsClaim(excerpt, claim))) continue;
        final wanted = switch (language) {
          _chinese => '"${term.zh}"',
          _english => '"${term.en}"',
          _ => '"${term.zh}" or "${term.en}"',
        };
        drifted.add(
          '$term — the $column cell cites $citation ($language source, written as '
          '${citation.form}), but $wanted is '
          'not within $_window lines of it, and neither is anything that cell quotes '
          '($claims). Either the text moved, or the citation names the wrong place.',
        );
      }
    }
  }
  return drifted;
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
        if (_isPrivateCheckout && cited.every((c) => _isPublishOnly(c.path))) {
          continue; // this checkout does not carry those files; see _publishOnly
        }
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

  test('every parsed citation carries a line, including the notes column', () {
    // The row-level check above only looks at Evidence and is satisfied by one
    // spanned citation on the row. A path-only mention in the same cell, or in
    // Note, was then skipped by every content check — judged by nothing, while
    // still looking like a citation. Each parsed citation is held to a window
    // or named here.
    final broken = <String>[];
    for (final term in terms) {
      for (final (column, cell) in [
        ('Evidence', term.evidence),
        ('Note', term.note),
      ]) {
        for (final citation in _citations(cell)) {
          if (citation.path == _noFileNamedYet) continue;
          if (citation.hasSpan) continue;
          broken.add(
            '$term — the $column cell cites $citation with no line number',
          );
        }
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
  });

  test('a path without a line is a content-check fault, not a skip', () {
    // The two live cases were Note `lib/l10n/app_zh_Hant.arb` and Evidence
    // `lib/obd/addressing.dart`. Restoring `if (!citation.hasSpan) continue`
    // makes this green on a cell the census would still see as a citation.
    final term = _Term(
      zh: '定址',
      en: 'addressing',
      status: 'evidenced',
      evidence: 'lib/obd/addressing.dart',
      note: '',
      line: 0,
    );
    final drifted = _driftedCitations([term], _either);
    expect(drifted, hasLength(1));
    expect(drifted.single, contains('no line number'));
    expect(drifted.single, contains('lib/obd/addressing.dart'));
  });

  test('every publish-only path the glossary cites is on the written roster', () {
    // Paths, not rows, and computed in both checkouts. The row roster below cannot see a
    // publish-only citation that sits in a Note on an otherwise ordinary row, and the
    // shape test cannot see a typo inside `store/`.
    final cited = <String>{};
    for (final term in terms) {
      for (final cell in [term.evidence, term.note]) {
        for (final citation in _citations(cell)) {
          if (_isPublishOnly(citation.path)) cited.add(citation.path);
        }
      }
    }
    expect(
      cited,
      _publishOnlyCited,
      reason: 'a publish-only path was added, removed or mistyped. In the private '
          'checkout none of these files exist, so a citation naming one is skipped '
          'twice over and a typo like store/READM.md reports nothing there. Update '
          '_publishOnlyCited, and say in review why the new path has no evidence '
          'inside app/.',
    );
  });

  test('the publish-only exemption matches its written roster', () {
    // Computed the same way the exemption is, and in both repositories -- so a
    // sixth row, or a typo like `store/READM.md`, fails here even in the
    // checkout where the exemption is what would have let it through.
    final exemptedRows = terms.where((t) {
      final cited = _citations(t.evidence);
      return cited.isNotEmpty && cited.every((c) => _isPublishOnly(c.path));
    }).toList();
    expect(exemptedRows.map((t) => t.zh).toSet(), _exemptedInPrivate,
        reason: 'a row was added to or removed from the set that only the '
            'public repository can verify. Update _exemptedInPrivate, and say '
            'in review why the new row has no evidence inside app/.');
    // Rows, not terms. A Set keyed on the Chinese term cannot see a second row
    // that reuses one: `| 面盤外觀 | skins | store/READM.md:1 |` leaves the
    // computed set identical and would ride in on the roster's coat-tails.
    // Nothing forbids two rows sharing a term -- the duplicate check below only
    // fires when the English differs.
    expect(exemptedRows.length, _exemptedInPrivate.length,
        reason: 'two exempted rows share one Chinese term, so the roster cannot '
            'see the second one');

    // The marker must agree with the tree. Read as: "if I believe I am the
    // private checkout, store/ must really be absent." A stray
    // torque_architecture_spec.md beside a public checkout -- telltale cloned
    // into torque/, say -- would otherwise switch the exemption on with nothing
    // anywhere going red.
    final present = _publishOnlyArtefacts
        .where((p) =>
            FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound)
        .toList();
    expect(present.isEmpty, _isPrivateCheckout,
        reason: _isPrivateCheckout
            ? 'this looks like the private checkout, but publish-only files are '
                'here: $present. The marker is lying, and the exemption is now '
                'hiding rows that could be checked.'
            : 'the public checkout must carry the publish-only files; without '
                'them the store-vocabulary rows stop being verified anywhere.');
  });

  test('every citation names a file that exists', () {
    // Every one, in both columns — not "at least one of this row's", which is all the
    // test above asks and all this one used to ask of a Note. An earlier version of this
    // comment claimed the Evidence column had been held to per-citation existence since
    // the first version; it had not, and the gap that left is the reason this covers both
    // columns now.
    //
    // A second Evidence citation whose path is a typo survives the row-level test on the
    // strength of the first, is still classified by `_sourceLanguage` — a nonexistent
    // `*.dart` is bilingual all the same — and is then SKIPPED by `_driftedCitations`,
    // which continues on a file it cannot open. On an `inferred` or `proposed` row the
    // pairing test does not look either, so nothing at all checks that citation while the
    // suite stays green.
    final missing = <String>[];
    for (final term in terms) {
      for (final (column, cell) in [
        ('Evidence', term.evidence),
        ('Note', term.note),
      ]) {
        for (final citation in _citations(cell)) {
          // Reported by the resolution test, which says what actually went wrong.
          if (citation.path == _noFileNamedYet) continue;
          if (File(citation.path).existsSync()) continue;
          // The written roster, not the publish-only SHAPE, so a mistyped `store/` path
          // is not skipped here; the roster test names it.
          if (_isPrivateCheckout && _publishOnlyCited.contains(citation.path)) continue;
          missing.add(
            '$term — the $column cell cites ${citation.path} (written as '
            '${citation.form}), which is not in this checkout. Each citation is judged '
            'on its own, so one that cannot be opened is judged by nothing.',
          );
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('every bare line number resolves to a file named earlier in its cell', () {
    // A bare `:86` is only a citation because something before it named a file. If
    // nothing did, it resolves to a path no file system answers, and the language checks
    // below would SKIP it the way they skip a file that is not in this checkout — a
    // citation that reads as checked and is not.
    final unresolved = <String>[];
    for (final term in terms) {
      for (final (column, cell) in [
        ('Evidence', term.evidence),
        ('Note', term.note),
      ]) {
        for (final citation in _citations(cell)) {
          if (citation.path != _noFileNamedYet) continue;
          unresolved.add(
            '$term — the $column cell writes a bare line number :${citation.from} with '
            'no file named before it. Write the path, or move the citation after one.',
          );
        }
      }
    }
    expect(unresolved, isEmpty, reason: unresolved.join('\n'));
  });

  test('the citation shapes the cells actually use all parse', () {
    // Hand-typed expectations against hand-typed cells, so this fails if the parser
    // stops reading a shape or starts inventing one.
    String read(String cell) => _citations(cell).map((c) => '$c').join(' ');

    // A path with no line still parses. The census above names it; if the
    // parser dropped it, that census would have nothing to say.
    expect(read('docs/i18n/glossary.md'), 'docs/i18n/glossary.md');

    // A slash joins two citations when a digit precedes it...
    expect(read('README.md:21/README.zh-TW.md:20'),
        'README.md:21 README.zh-TW.md:20');
    // ...and is part of one path when a letter does. The same path must not
    // also read as a second citation `i18n/glossary.md`.
    expect(read('docs/i18n/glossary.md'), 'docs/i18n/glossary.md');

    // A bare line number takes the file the cell named last.
    expect(read('lib/obd/elm327_client.dart:82 canError; :86 busBusy'),
        'lib/obd/elm327_client.dart:82 lib/obd/elm327_client.dart:86');
    // A comma tail takes it too, however many follow.
    expect(read('docs/field-guide.zh-TW.md:59,145,146'),
        'docs/field-guide.zh-TW.md:59 docs/field-guide.zh-TW.md:145 '
        'docs/field-guide.zh-TW.md:146');
    // Spans survive both shapes.
    expect(read('docs/field-guide.zh-TW.md:240,243-245'),
        'docs/field-guide.zh-TW.md:240 docs/field-guide.zh-TW.md:243-245');
    // A comma tail ends at its digits, whether prose follows it or a bracket closes it.
    // Both of these are written in the glossary as they appear here.
    expect(read('docs/field-guide.zh-TW.md:122,289 UI path 設定 → 診斷紀錄'),
        'docs/field-guide.zh-TW.md:122 docs/field-guide.zh-TW.md:289');
    expect(read('(README.zh-TW.md:126,150).'),
        'README.zh-TW.md:126 README.zh-TW.md:150');

    // A SHORT file name is not a citation, and its line number must not attach to the
    // full path before it. Reading `:9` here as README.zh-TW.md:9 would check a line
    // against a file the author never named.
    expect(read('README.zh-TW.md:103 and app_zh_Hant.arb:9'), 'README.zh-TW.md:103');

    // A bare line number inside a quotation is part of the quotation. Without this the
    // cell below would invent README.md:404 and check a window nobody cited.
    expect(read("README.md:56 'the error is 錯誤 :404 here'"), 'README.md:56');

    // A bare line number with nothing before it resolves to a path nothing answers,
    // which the test above reports rather than skipping.
    expect(read('see :86 for the rest'), '$_noFileNamedYet:86');
  });

  test('a quoted claim is matched in the language it is written in', () {
    // Fixtures, hand-typed, not read back from the glossary. The defect this pins is that
    // a claim used to go through plain containment whatever language it was in, so an
    // English claim was satisfied by any longer word holding it.
    // The live case a reviewer built out of this glossary, and the first thing checked
    // here so that it is the assertion that speaks when this test goes red: `rig` hides
    // inside `triggered`, so plain containment accepted README.md:57 — a line about
    // transcript export — as evidence for 隔離 / quarantine, with every test green.
    expect(
      _holdsClaim('  user-triggered diagnostic transcript export', 'rig'),
      isFalse,
      reason: 'the claim `rig` was found inside `triggered`, which is the fabricated '
          'stale citation this split exists to refuse',
    );
    expect(
      _holdsClaim(
          'is the real-use application; the isolated `rig` flavor is test '
          'infrastructure.',
          'rig'),
      isTrue,
      reason: 'a standalone `rig` is the live rescue at README.md:148 and must survive',
    );

    expect(_holdsClaim('the aggregate total', 'gate'), isFalse);
    expect(_holdsClaim('a gatekeeper stands here', 'gate'), isFalse);
    expect(_holdsClaim('a mismatched header', 'match'), isFalse);
    expect(_holdsClaim('the gate is closed', 'gate'), isTrue);

    // A quotation is checked as quoted, so the inflection a TERM is allowed is refused
    // here. `_containsEnglish('the gated branch', 'gate')` is true and this is not.
    expect(_holdsClaim('the gated branch', 'gate'), isFalse);
    expect(_containsEnglish('the gated branch', 'gate'), isTrue);

    // An identifier claim still reads, because the haystack is split as well as matched.
    expect(_holdsClaim("'volumetricEfficiency' => '容積效率',", 'volumetricEfficiency'),
        isTrue);

    // Chinese keeps containment: 閘門 has no boundary to look for, and 閘門判斷 is not a
    // longer word in the sense that aggregate is.
    expect(_holdsClaim('這是閘門判斷', '閘門'), isTrue);
    expect(_holdsClaim('這是判斷', '閘門'), isFalse);

    // A claim carrying Han text is matched whole, so its English half cannot drift alone.
    expect(_holdsClaim('# Telltale 實車證據 v2', '# Telltale 實車證據 v1'), isFalse);
  });

  test('every cited file has a declared language', () {
    final undeclared = <String>{};
    for (final term in terms) {
      for (final cell in [term.evidence, term.note]) {
        for (final citation in _citations(cell)) {
          // Reported by the resolution test above; it is not a file anybody named.
          if (citation.path == _noFileNamedYet) continue;
          if (_sourceLanguage(citation.path) == null) undeclared.add(citation.path);
        }
      }
    }
    expect(
      undeclared,
      isEmpty,
      reason:
          'the language checks below ask an English source for the English term and a '
          'Chinese source for the Chinese one, and can ask nothing at all of a file '
          'whose language nobody has written down. Classify it in _sourceLanguage: '
          '$undeclared',
    );
  });

  test('every citation into an English source still holds the English term or what its '
      'cell quotes', () {
    final drifted = _driftedCitations(terms, _english);
    expect(drifted, isEmpty, reason: drifted.join('\n'));
  });

  test('every citation into a Chinese source still holds the Chinese term or what its '
      'cell quotes', () {
    final drifted = _driftedCitations(terms, _chinese);
    expect(drifted, isEmpty, reason: drifted.join('\n'));
  });

  test('every citation into a bilingual source still holds one of the two terms or what '
      'its cell quotes', () {
    final drifted = _driftedCitations(terms, _either);
    expect(drifted, isEmpty, reason: drifted.join('\n'));
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
