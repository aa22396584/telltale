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
//
// What the file does NOT reach, stated so a reader can weigh it.
//
//  - An entry whose English lives in README or docs prose rather than in an
//    ARB is held by nothing here.
//  - An entry carrying `**Status** — proposed` is exempt from the declaration
//    rule by design, so a proposed *unkeyed* entry whose Chinese starts
//    shipping stays invisible. It may not also name a key: the field and a
//    `**Shipped as**` line contradict each other and that is now a fault.
//  - An ARB key named in an entry's prose, rather than on its `**Shipped as**`
//    line, raises no demand — several such keys are pinned literally by
//    `locale_roots_test.dart` instead.
//  - The declaration census matches recorded text against shipped text
//    verbatim, so an entry that paraphrases a shipped string by one character
//    is not seen by it. It answers 'is this the shipped sentence', not 'is
//    this about the shipped sentence'.
//  - Comparison is exact after whitespace folding, not byte for byte:
//    `_plain` folds U+00A0 to a space and collapses runs on both sides.
//    Whitespace-only drift in an ARB is therefore not seen, and Flutter's
//    `Text` does not collapse runs the way Markdown does, so it would be
//    visible on screen.
//  - A span on a `**Shipped as**` line is taken for a file path only when it
//    contains a `/` under a known top-level directory. A bare `pubspec.yaml`
//    would be reported as a key that did not parse, which is the safe
//    direction; no entry writes one.
//  - The line parsers are not fence-aware. A `### 5.` or a `60 entries.` line
//    inside a fenced block would be read as real, so a separate check requires
//    the register to carry no fences at all, in either fence character. An
//    indented code block is allowed and is not a hole: it renders as code and
//    is invisible to every reader in `_rawLineReaders`, because all of them
//    are anchored at column 0. Raw HTML is neither — a `<pre>` or a `<div>`
//    renders its contents as markup while leaving them at column 0, exactly as
//    a fence does. No check looks for it, and no entry uses it.
//  - The Chinese side is read from `app_zh_Hant.arb`; `app_zh.arb` is not read
//    here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _registerPath = 'docs/i18n/hedge-register.md';

final _entry = RegExp(r'^### (\d+)\. (.*)$');

/// `**English** — text`.
///
/// The dash and the spaces around it are deliberately loose. A reviewer changed
/// one em dash to an en dash — the substitution any editor or autocorrect makes
/// without being asked — and the entry vanished from the guard silently, taking
/// `dtcRescanFirst` with it. Punctuation drift in a Markdown file must not be
/// able to disarm a test.
final _english = RegExp(r'^\*\*English\*\*[\s ]*[—–-][\s ]*(.*)$');

/// Any `**English…**` label, whatever it carries between the word and the
/// closing asterisks.
///
/// The register used to offer `**English (clause)**`, which opted an entry into
/// a substring comparison bounded by 'the shipped string may not have grown by
/// more than one sentence'. That bound counts sentence terminators, so any
/// punctuation that does not terminate carried unlimited reversing text for
/// free: the clause 'that does not mean the vehicle has none' inside 'This scan
/// did not read a freeze frame — that does not mean the vehicle has none, but
/// on most vehicles clearing now is safe.' satisfied both halves at once. No
/// entry used the form, so it is gone rather than repaired — an unused feature
/// with a known hole is worse than no feature. This is what makes bringing it
/// back fail by name instead of dropping the entry silently, which is all a
/// stricter `_english` would have done.
final _englishLabel = RegExp(r'^\*\*English([^*]*)\*\*');

/// The Chinese half, held to the same standard where the entry names an ARB
/// key. It used not to be checked at all, on the reasoning that the register
/// quotes zh from source files all over the tree rather than only the ARBs —
/// true for the unkeyed entries, and it let an entry written an hour earlier
/// record 「故障燈已亮」 for a key that ships 「故障燈亮著」. The unchecked half
/// rots immediately, which is the whole argument of this file applied to
/// itself.
final _chinese = RegExp(r'^\*\*繁體中文\*\*[\s ]*[—–-][\s ]*(.*)$');
final _shipped = RegExp(r'^\*\*Shipped as\*\* (.*)$');

/// A backticked ARB key, optionally qualified by a class: `AppLocalizations.foo`
/// names the same key as `foo`, and someone will write it that way.
///
/// The qualifier must be UpperCamel, which is what keeps this from reading
/// `hedge_register_guard_test.dart` as a key called `dart`. Anchored at both
/// ends so a filename, a path or a snippet cannot match part of itself — the
/// looser first version did exactly that on its first run.
final _key = RegExp(r'`(?:[A-Z][A-Za-z0-9_]*\.)?([a-z][A-Za-z0-9_]*)`');

/// One backticked span, whatever is inside it.
final _span = RegExp(r'`([^`]*)`');

/// The shape `_key` accepts, anchored to a whole span rather than searched for
/// inside a line, so a span can be asked whether it *is* a key.
final _wholeKey = RegExp(r'^(?:[A-Z][A-Za-z0-9_]*\.)?[a-z][A-Za-z0-9_]*$');

/// A key written the way the code writes it, outside backticks.
///
/// `l10n.powertrainConnectFirst` in prose reads to a person as a key this
/// entry guards. It is not one: the lowercase qualifier fails `_key`, so the
/// parser never sees it, and the count control cannot tell — the line still
/// parses and still yields its first key.
final _bareQualified = RegExp(r'\b(?:l10n|AppLocalizations)\.[A-Za-z_][A-Za-z0-9_]*');

/// Any identifier-shaped word, for asking whether it happens to be an ARB key.
///
/// `_bareQualified` only recognises a key by its qualifier, so a reviewer found
/// the half it cannot see: `The same rule governs powertrainConnectFirst.` has
/// no qualifier and no backticks, so neither that pattern nor `_key` nor either
/// control moves — while the register header, two commits ago, started promising
/// in as many words that a key written without backticks fails. A promise a
/// check does not keep is the shape this file exists to remove. The membership
/// test against the shipped ARB keys is what makes this precise: an ordinary
/// camelCase word in prose is not a key, and `powertrainConnectFirst` is.
final _token = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

/// The one exemption from the declaration census, and therefore the one
/// construct in this file that must not be writable by accident.
///
/// It was a mention: `**proposed**` searched for anywhere in the entry, plus an
/// English line opening with the three words `NO PROJECT ENGLISH`. The doc
/// comment claimed neither could occur inside a sentence meaning something
/// else. A reviewer wrote one that does — *A reviewer once **proposed**
/// softening this.* — dropped it into a Why paragraph of an entry whose
/// `Shipped as` line had been deleted, and the census went green where its
/// control went red. This register's paragraphs narrate what reviewers did on
/// almost every page, so that sentence is ordinary prose here, not a contrivance.
/// The looser half was as bad: `NO PROJECT ENGLISH yet, see the picker.`
/// exempted an entry whose 繁體中文 was verbatim shipped.
///
/// `CONTRIBUTING.md` has the rule by name — an attestation is a field, not a
/// sentence, and what a machine reads must be a line that takes a deliberate
/// keystroke and cannot occur inside a sentence meaning something else. So it is
/// a field now, anchored at the start of its own line, shaped like the
/// `**Shipped as**` line beside it. Prose about a proposal stays prose.
final _status = RegExp(r'^\*\*Status\*\*[\s ]*[—–-][\s ]*(.*)$');

/// Markdown still renders 1–3 leading spaces as a paragraph. Four or more
/// is an indented code block, which the register header uses so the example
/// is not a field. Strip only the paragraph case.
String _statusLine(String line) {
  var n = 0;
  while (n < line.length && n < 4 && _isParagraphSpace(line.codeUnitAt(n))) {
    n++;
  }
  if (n >= 4) return line;
  return line.substring(n);
}

/// ASCII space or NBSP. Editors paste the second; Markdown still renders
/// 1–3 of either as a paragraph, not a code block.
bool _isParagraphSpace(int codeUnit) => codeUnit == 0x20 || codeUnit == 0xA0;

/// The only value `**Status**` may carry.
const _proposedStatus = 'proposed';

/// A fenced block, in either of the two characters Markdown accepts.
///
/// The first version of this check read backticks only, and a reviewer wrapped
/// an entry in `~~~`: every line stays at column 0, so `_parse` and all the
/// controls read it as a real entry, while the rendered register shows it as a
/// code example. That is the disagreement the check exists to prevent, arriving
/// through the door the check did not look at.
///
/// An indented code block is deliberately not treated as a fence. It renders as
/// code and it is invisible to every parser here, because all of them are
/// anchored at column 0 with no tolerance for leading whitespace — so the two
/// readings agree, and the register header uses one to show the `**Status**`
/// line without that line becoming a marker.
final _fence = RegExp(r'^ {0,3}(?:`{3,}|~{3,})');

/// The human-readable half of the same claim, which must agree with the field.
///
/// An English line opening with these words says 'not established yet' to a
/// person. If the field does not say it to the machine, the two readings
/// disagree and one of them is wrong — and the failure is silent in the
/// direction that matters, because the entry stays in the census while looking
/// exempt. Checked one way only: entry 27 is proposed and its English is
/// ordinary prose.
final _noProjectEnglish = RegExp(r'^NO PROJECT ENGLISH\b');

/// Every pattern here that is matched against a raw register line.
///
/// Three separate sentences used to count these — 'four regexes', 'six
/// regexes', and a fault message naming six by name — and all three were wrong
/// in the same direction, omitting `_englishLabel`. A reviewer's tilde-fence
/// probe then made `_englishLabel` the pattern that actually fired, so the one
/// reader nobody had counted was the one doing the work.
///
/// This repository's rule for that is to pin by census rather than by name: a
/// hand-written list of what to guard is correct exactly once. So the count is
/// never written down — every message derives it from here — and a test below
/// reads this file's own source and requires every `^`-anchored `RegExp` in it
/// to be classified, either here or as a reader of an already-parsed string.
/// Adding one and forgetting to say which fails.
///
/// 'Every' is load-bearing and was not true when first written: the scan read
/// one quoting style, so a pattern written the other way was outside it. Two
/// things make the word honest now. The scan reads both quote characters, and
/// a second assertion counts constructions against declarations found — so a
/// pattern in any shape the scan cannot read is a failure rather than a
/// silence.
final _rawLineReaders = <String, RegExp>{
  '_entry': _entry,
  '_english': _english,
  '_englishLabel': _englishLabel,
  '_chinese': _chinese,
  '_shipped': _shipped,
  '_status': _status,
  '_headerCount': _headerCount,
  '_fence': _fence,
};

/// Anchored patterns that read a string this file has already parsed out of a
/// line, never a raw line, so a fence cannot reach them.
const _derivedStringReaders = <String>{'_wholeKey', '_noProjectEnglish'};

/// The raw-line readers a fence would fool, which is all of them but the one
/// whose job is to find fences. Derived, so it cannot disagree with the roster.
Iterable<String> get _fenceBlindReaders =>
    _rawLineReaders.keys.where((name) => name != '_fence');

/// A `RegExp` bound to a private name in this file's own source.
///
/// It recognised single-quoted raw strings only, and it was itself written
/// with double quotes — so the file contained a declaration form its own
/// self-scan could not see, and a reviewer proved it by writing an anchored
/// pattern as `r"…"` and watching the census stay green. A scan that cannot
/// see part of the file it scans is the shape this whole file exists to
/// remove, arriving one level up.
///
/// Both quote characters now, with the closing one held to the opening one by
/// a backreference. The single quote is written `\x27` so this pattern is
/// itself a single-quoted raw string, which is the form the scan reads: the
/// file no longer contains a declaration shape invisible to it, and a check
/// below pins that by counting call sites against declarations found.
final _regExpDeclaration =
    RegExp(r'final (_\w+) =\s*RegExp\(\s*r([\x27"])((?:(?!\2)[\s\S])*)\2');

/// The literal that opens every `RegExp` in this file, for counting call sites.
///
/// `RegExp\(` inside a pattern is not this text — the backslash is there — so
/// this counts constructions and not mentions of the word.
final _regExpCall = RegExp(r'RegExp\(');

/// A run of whitespace, folded to one space on both sides of the comparison.
final _whitespaceRun = RegExp(r'\s+');

/// An internal capital: what makes an ARB key not an ordinary English word.
final _humpedKey = RegExp(r'[a-z0-9][A-Z]');

/// The register's statement of its own size, which no check used to read.
///
/// A number in prose that nothing verifies drifts, and this repository has
/// watched it happen: the same count went stale four times in files that were
/// otherwise correct. Either a machine reads it or it should not be written.
final _headerCount = RegExp(r'^(\d+) entries\.');

/// Whitespace normalisation, applied to both sides.
///
/// A Markdown file picks up non-breaking spaces and doubled spaces from editors
/// without anybody deciding to, and holding the register to them would make
/// this guard fail for reasons nobody can see. The cost is stated rather than
/// hidden: this is why the comparison is exact *after whitespace folding* and
/// not byte for byte, and why whitespace-only drift in an ARB is invisible to
/// it. That drift is not invisible to a reader — Flutter's `Text` does not
/// collapse runs the way Markdown does, and a U+00A0 changes where a line
/// breaks — so it is a real, small gap and not a free one.
String _plain(String value) => value
    .replaceAll(' ', ' ')
    .replaceAll(_whitespaceRun, ' ')
    .trim();

/// The register's own Markdown emphasis, stripped from the REGISTER side only.
///
/// It used to be stripped from both, and that hid a real defect: a shipped
/// string containing a literal `**not**` compared equal to a register entry
/// saying `not`, so the guard passed while the screen rendered the asterisks.
/// Emphasis is a property of the Markdown file. Whatever the ARB holds is what
/// a reader sees, and this comparison says so — up to the whitespace folding
/// `_plain` does to both sides.
String _fromRegister(String value) => _plain(value.replaceAll('**', ''));

/// Directories a repository path can start with.
const _repoRoots = <String>{
  'lib', 'test', 'tool', 'docs', 'android', 'ios', 'integration_test', 'store',
  'assets',
};

/// A span that names a file rather than a key.
///
/// It used to accept anything containing a `/` or ending in a source
/// extension, and a reviewer listed what that waves through beside a real key:
/// `dtcMilOff/dtcMilUnknown`, `dtcMilOff.arb`, `dtcMilOff.dart`. Each is two
/// keys or one key wearing a costume, and each was dropped silently. A path
/// now has to look like a path in this repository — a `/` under a known
/// top-level directory — so the costumes fall through to the key branch and
/// are reported.
bool _looksLikePath(String span) =>
    span.contains('/') && _repoRoots.contains(span.split('/').first);

class _Entry {
  _Entry(this.number, this.title);
  final int number;
  final String title;
  String? english;
  String? chinese;
  final List<String> keys = <String>[];
  final List<String> shippedLines = <String>[];
  final List<String> statuses = <String>[];
  final List<String> body = <String>[];

  bool get hasShipped => shippedLines.isNotEmpty;

  /// One field, anchored, on a line of its own. Not a word in a sentence.
  bool get isProposed => statuses.contains(_proposedStatus);

  /// What the entry says to a person, as opposed to what it says to this file.
  bool get readsAsProposed => _noProjectEnglish.hasMatch(english ?? '');
}

List<_Entry> _parse(List<String> lines) {
  final entries = <_Entry>[];
  _Entry? current;

  for (final line in lines) {
    final head = _entry.firstMatch(line);
    if (head != null) {
      current = _Entry(int.parse(head.group(1)!), head.group(2)!);
      entries.add(current);
      continue;
    }
    final entry = current;
    if (entry == null) continue;
    entry.body.add(line);

    final en = _english.firstMatch(line);
    if (en != null) {
      entry.english = _fromRegister(en.group(1)!);
      continue;
    }
    final zh = _chinese.firstMatch(line);
    if (zh != null) {
      entry.chinese = _fromRegister(zh.group(1)!);
      continue;
    }
    final status = _status.firstMatch(_statusLine(line));
    if (status != null) {
      entry.statuses.add(_plain(status.group(1)!));
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
      entry.shippedLines.add(shipped.group(1)!);
      entry.keys.addAll(
        _key.allMatches(shipped.group(1)!).map((m) => m.group(1)!),
      );
    }
  }
  return entries;
}

/// The entries this file can actually check: those that record an English
/// sentence and name at least one shipped key.
List<_Entry> _keyed(List<_Entry> entries) =>
    entries.where((e) => e.english != null && e.keys.isNotEmpty).toList();

/// Case (a): an `**English…**` label carrying anything but nothing.
List<String> _qualifiedEnglishLabels(List<_Entry> entries) {
  final faults = <String>[];
  for (final entry in entries) {
    for (final line in entry.body) {
      final match = _englishLabel.firstMatch(line);
      if (match == null) continue;
      final qualifier = match.group(1)!;
      if (qualifier.isEmpty) continue;
      faults.add(
        '#${entry.number} ${entry.title}: the label is "${match.group(0)}". '
        'The only accepted label is **English**; the clause form was removed '
        'because its sentence bound counted terminators and let '
        'non-terminating punctuation carry unlimited reversing text.',
      );
    }
  }
  return faults;
}

/// Cases (b) and (c): what a `**Shipped as**` line claims versus what the
/// parser took from it.
///
/// The count control asks whether the number of hedges equals the number of
/// `Shipped as` lines. That is blind to a key lost inside a line that still
/// parses, because the line still contributes its first key and still counts
/// once. This reads the spans instead: anything on the line shaped like a key
/// must be one the parser took, and anything that is neither a key nor a file
/// path is a claim nothing checks.
List<String> _shippedLineFaults(List<_Entry> entries, Set<String> knownKeys) {
  final faults = <String>[];
  for (final entry in entries) {
    for (final line in entry.shippedLines) {
      final keys = <String>[];
      for (final match in _span.allMatches(line)) {
        final span = match.group(1)!;
        if (_wholeKey.hasMatch(span)) {
          keys.add(span);
          continue;
        }
        if (_looksLikePath(span)) continue;
        faults.add(
          '#${entry.number} `$span` is neither an ARB key nor a file path, so '
          'it reads as a key the parser never took.',
        );
      }
      if (keys.length != 1) {
        faults.add(
          '#${entry.number} names ${keys.length} keys on one "Shipped as" '
          'line. Exactly one is the invariant the count control rests on; a '
          'second key belongs in its own entry.',
        );
      }
      // Spans become a space rather than nothing, so removing one cannot join
      // the words on either side of it into a token that was never written.
      var outside = line.replaceAll(_span, ' ');
      for (final match in _bareQualified.allMatches(outside)) {
        faults.add(
          '#${entry.number} ${match.group(0)} is written without backticks, so '
          'the parser never sees it while a reader reads it as guarded.',
        );
      }
      // Subtracted before the unqualified pass, so a qualified key is reported
      // once as itself rather than twice as two overlapping findings.
      outside = outside.replaceAll(_bareQualified, ' ');
      for (final match in _token.allMatches(outside)) {
        final word = match.group(0)!;
        if (!knownKeys.contains(word)) continue;
        faults.add(
          '#${entry.number} $word is an ARB key written without backticks, so '
          'the parser never sees it while a reader reads it as guarded.',
        );
      }
    }
  }
  return faults;
}

/// Case (d): an entry that records shipped copy and does not say which key.
///
/// The stated version of this rule was 'every non-proposed entry has a
/// **Shipped as** line'. Measured against the file, that is false for thirteen
/// entries, ten of which quote README or docs prose and have no ARB key to
/// name. This is the version that holds: if the sentence the entry recorded is
/// verbatim a string this app ships, the guard could have checked it and did
/// not, and the entry reads to a translator as though something were watching.
List<String> _unregisteredShippedCopy(
  List<_Entry> entries,
  Map<String, String> enArb,
  Map<String, String> zhArb,
) {
  Map<String, List<String>> byValue(Map<String, String> arb) {
    final out = <String, List<String>>{};
    arb.forEach(
      (key, value) => out.putIfAbsent(_plain(value), () => <String>[]).add(key),
    );
    return out;
  }

  final english = byValue(enArb);
  final chinese = byValue(zhArb);
  final faults = <String>[];

  for (final entry in entries) {
    if (entry.hasShipped || entry.isProposed) continue;
    final en = entry.english;
    if (en != null && english.containsKey(en)) {
      faults.add(
        '#${entry.number} records the shipped English of '
        '${english[en]!.join(', ')} and names no key, so nothing checks it.',
      );
    }
    final zh = entry.chinese;
    if (zh != null && chinese.containsKey(zh)) {
      faults.add(
        '#${entry.number} records the shipped 繁體中文 of '
        '${chinese[zh]!.join(', ')} and names no key, so nothing checks it.',
      );
    }
  }
  return faults;
}

/// The `**Status**` field: its vocabulary, and whether it agrees with the
/// sentence a person reads.
List<String> _statusFaults(List<_Entry> entries) {
  final faults = <String>[];
  for (final entry in entries) {
    for (final line in entry.body) {
      // `startsWith` is the whole rule: an indented example of the field in
      // the register header is not a field, and must not become one. A line
      // that renders as a Status and does not match `_status` is the
      // disagreement — `**Status**: proposed` still looks proposed to a
      // person and exempts nothing.
      final field = _statusLine(line);
      if (field.startsWith('**Status**') && !_status.hasMatch(field)) {
        faults.add(
          '#${entry.number} has a **Status** line this file cannot read: '
          '"$line". The field is **Status** — proposed, with an em dash, en '
          'dash or hyphen. A colon, or anything else, still renders as a '
          'status and exempts nothing.',
        );
      }
    }
    for (final status in entry.statuses) {
      if (status == _proposedStatus) continue;
      faults.add(
        '#${entry.number} **Status** — $status is not a status this file '
        'knows. The only value is "$_proposedStatus"; anything else exempts '
        'nothing and reads as though it did.',
      );
    }
    if (entry.statuses.length > 1) {
      faults.add(
        '#${entry.number} carries ${entry.statuses.length} **Status** lines.',
      );
    }
    if (entry.isProposed && entry.hasShipped) {
      faults.add(
        '#${entry.number} carries **Status** — $_proposedStatus and a '
        '**Shipped as** line naming ${entry.keys.join(', ')}. Those contradict: '
        'the field says this English is not established, and the key says the '
        'app ships it — the exact comparison above is passing against it right '
        'now. One of the two is wrong, and while both stand the entry is exempt '
        'from the declaration census for copy that demonstrably ships.',
      );
    }
    if (entry.readsAsProposed && !entry.isProposed) {
      faults.add(
        '#${entry.number} opens its **English** line with NO PROJECT ENGLISH, '
        'which tells a person the English is not established, and carries no '
        '**Status** — $_proposedStatus line, which is what this file reads. '
        'The two readings have to agree; a sentence is not a field.',
      );
    }
  }
  return faults;
}

/// The register's own count of itself, checked rather than trusted.
List<String> _selfCountFaults(List<String> lines) {
  final headings = lines.where(_entry.hasMatch).length;
  final declared = lines
      .map(_headerCount.firstMatch)
      .whereType<RegExpMatch>()
      .toList();
  if (declared.length != 1) {
    return <String>[
      'the register must state its own size exactly once, as "<n> entries." at '
          'the start of a line; found ${declared.length} such lines.',
    ];
  }
  final stated = int.parse(declared.single.group(1)!);
  final faults = <String>[];
  if (stated != headings) {
    faults.add(
      'the register says $stated entries and carries $headings "### n." '
      'headings.',
    );
  }

  // The numbers, not only how many of them there are.
  //
  // Every fault message in this file identifies an entry as `#n`, and the
  // register's own prose cross-references by number — 'entries 42, 43 and 44
  // exist because of three that were', 'the dialog entries 11 and 27 are both
  // about'. A duplicate number makes both of those ambiguous, and inserting an
  // entry and mis-numbering it is the ordinary slip. A reviewer renamed
  // `### 59.` to a second `### 58.` and nothing moved.
  final numbers = lines
      .map(_entry.firstMatch)
      .whereType<RegExpMatch>()
      .map((m) => int.parse(m.group(1)!))
      .toList();
  final expected = <int>[for (var i = 1; i <= numbers.length; i++) i];
  final numbered = numbers.length == expected.length &&
      List<int>.generate(numbers.length, (i) => i)
          .every((i) => numbers[i] == expected[i]);
  if (!numbered) {
    final duplicates = <int>{
      for (final n in numbers)
        if (numbers.where((other) => other == n).length > 1) n,
    };
    faults.add(
      'the headings are numbered ${numbers.join(', ')} and must be exactly '
      '1..${numbers.length} in order'
      '${duplicates.isEmpty ? '' : '; repeated: ${duplicates.join(', ')}'}.',
    );
  }

  // The readers in `_rawLineReaders` are line-anchored and know nothing about
  // fenced blocks, so a `### 5.` or a `60 entries.` inside one would be read as
  // real. Three checks in this repository were once satisfied at a stroke by a
  // worked example inside a fence. The register has no fences and does not need
  // any; requiring that is cheaper than teaching all of them to skip one, and
  // it fails at the moment somebody adds the first fence rather than later.
  final fences = lines.where(_fence.hasMatch).length;
  if (fences != 0) {
    faults.add(
      'the register carries $fences fenced-block delimiters (``` or ~~~). '
      '`_fence` is the only reader here that knows what one is. These read raw '
      'lines anchored at column 0 and do not: '
      '${_fenceBlindReaders.join(', ')}, plus the "**Shipped as**" prefix test '
      'in the parser control, which is deliberately broader than `_shipped` so '
      'a malformed line still counts. A heading or a count inside a fence is '
      'read as real while rendering as an example. Give them fence awareness '
      'before adding a fence. An indented code block is fine: it renders as '
      'code and every one of them rejects the indentation.',
    );
  }
  return faults;
}

Map<String, String> _arb([String file = 'app_en.arb']) {
  final raw = jsonDecode(File('lib/l10n/$file').readAsStringSync());
  return <String, String>{
    for (final e in (raw as Map<String, dynamic>).entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

/// An entry every check is known to accept, prepended to each planted fixture.
///
/// A negative fixture that stops reaching the parser passes vacuously — the
/// hole is not found because nothing was read. Each fixture test asserts the
/// sentinel parsed *with its key* before asserting anything about the hole, so
/// a fixture that has come adrift fails rather than agreeing with itself.
const _sentinel = '''
# Fixture register

2 entries.

### 1. 感測器沒有回應

**繁體中文** — 感測器沒有回應

**English** — The sensor did not answer.

**Shipped as** `sentinelKey` (lib/l10n/app_en.arb).

**Why it is load-bearing.** The sentinel for this file's own fixtures.
''';

List<String> _fixture(String planted) => '$_sentinel\n$planted'.split('\n');

void main() {
  final register = File(_registerPath).readAsLinesSync();
  final entries = _parse(register);
  final hedges = _keyed(entries);
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
    // Exact, with no escape hatch. The register used to offer one — record the
    // load-bearing clause, and let the shipped string grow by up to one
    // sentence around it — and the bound counted sentence terminators, so a
    // comma or an em dash carried as much reversing text as a translator
    // wanted: 'This scan did not read a freeze frame — that does not mean the
    // vehicle has none, but on most vehicles clearing now is safe.' passed.
    // Softening by addition instead of subtraction is the ordinary shape of
    // translation drift, and it was free.
    final broken = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        final shipped = arb[key];
        if (shipped == null) continue;
        final actual = _plain(shipped);
        if (actual == hedge.english) continue;
        broken.add(
          '#${hedge.number} $key\n'
          '  register: ${hedge.english}\n'
          '  shipped:  $actual',
        );
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

  test('every entry has both language lines, whether or not it names a key', () {
    // The keyed-entry version of this sits above, and stops at the keyed
    // entries because that was where the guard could act. The blind spot is the
    // other side of the same door: an entry with no `Shipped as` line whose
    // **English** line stops parsing leaves `english` null, and all three of
    // the checks that could have noticed look away. The count control counts
    // `Shipped as` lines, and this entry has none. The shipped-copy census
    // needs a recorded sentence to compare, and there now is none. The keyed
    // Chinese check only reads keyed entries. So the entry keeps its heading,
    // reads as registered, and is held to nothing — which is how the fullwidth
    // dash got in the first time.
    final unparsed = <String>[];
    for (final entry in entries) {
      if (entry.english == null) {
        unparsed.add('#${entry.number} ${entry.title}: no **English** line parsed');
      }
      if (entry.chinese == null) {
        unparsed.add('#${entry.number} ${entry.title}: no **繁體中文** line parsed');
      }
    }
    expect(unparsed, isEmpty, reason: unparsed.join('\n'));
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

  // `reason:` is eager, so `expect(f(x), isEmpty, reason: f(x).join(...))`
  // runs the check twice on every pass. Hoisted.
  test('no entry uses a qualified English label', () {
    final faults = _qualifiedEnglishLabels(entries);
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('every Shipped as line declares exactly the keys it appears to', () {
    final faults = _shippedLineFaults(entries, arb.keys.toSet());
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('an entry that records shipped copy names its key', () {
    final faults = _unregisteredShippedCopy(entries, arb, zhArb);
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('the proposed marker is a field, and agrees with the English line', () {
    final faults = _statusFaults(entries);
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('every anchored pattern in this file is classified', () {
    // The census behind `_rawLineReaders`. Three sentences once counted these
    // by hand and all three omitted the same one, so nothing here counts them
    // by hand any more: this reads the file's own source and requires each
    // `^`-anchored `RegExp` to be named in one of the two rosters. Adding a
    // pattern and forgetting to classify it fails; the choice of bucket is a
    // decision a person makes, and it is visible.
    final source = File(
      'test/l10n/hedge_register_guard_test.dart',
    ).readAsStringSync();
    final matches = _regExpDeclaration.allMatches(source).toList();

    // Every `RegExp` here is built at a declaration the scan can read, and
    // this is what keeps that true. The scan understands one shape; a pattern
    // written any other way — double-quoted before this commit, triple-quoted,
    // non-raw, or constructed inline inside an expression — is invisible to
    // it, and an invisible pattern cannot be classified. Counting call sites
    // against declarations found is how the narrowness of the scan stops being
    // a hole and becomes a rule.
    final calls = _regExpCall.allMatches(source).length;
    expect(
      matches.length,
      calls,
      reason:
          'the file constructs $calls RegExps and the self-scan recognises '
          '${matches.length} of them. Declare each one at the top level as '
          '`final _name =` followed by the constructor and a raw string in '
          'either quote character; an inline one, a triple-quoted one or a '
          'non-raw one cannot be classified, and this scan would not know it '
          'exists. (This message deliberately does not spell the constructor '
          'call, because it is counted by its literal text and would count '
          'itself.)',
    );

    final declared = <String>{
      for (final m in matches)
        if (m.group(3)!.startsWith('^')) m.group(1)!,
    };
    // The scan has to find something, or this passes by reading nothing.
    expect(declared, contains('_entry'));
    expect(declared.length, greaterThan(_derivedStringReaders.length));

    final classified = <String>{
      ..._rawLineReaders.keys,
      ..._derivedStringReaders,
    };
    expect(
      declared.difference(classified),
      isEmpty,
      reason: 'anchored at the start of a string and in neither roster. Say '
          'whether each reads a raw register line — in which case a fence '
          'reaches it — or a string this file already parsed out of one.',
    );
    expect(
      classified.difference(declared),
      isEmpty,
      reason: 'named in a roster and not declared as an anchored RegExp here.',
    );
  });

  test('no ARB key is an ordinary English word', () {
    // What makes the unbackticked-key scan precise rather than hopeful.
    //
    // That scan compares every identifier-shaped word outside backticks on a
    // `Shipped as` line against the shipped key set, and the prose on those
    // lines contains `clear`, `panel`, `frame`, `button`, `dialog`, `screen`.
    // It is quiet only because no key is spelled like any of them. A reviewer
    // measured the contingency by adding `clear` and `panel` to the ARB and
    // got four faults accusing entries 11 and 45 of hiding keys they do not
    // hide.
    //
    // The invariant underneath is this project's `<domain>CamelCase` naming,
    // which nothing pinned. This pins it, so the day a bare-word key is added
    // the failure names the cause instead of the symptom.
    final unhumped = arb.keys
        .where((key) => !_humpedKey.hasMatch(key))
        .toList();
    expect(
      unhumped,
      isEmpty,
      reason:
          'These keys have no internal capital, so an ordinary English word in '
          'a **Shipped as** line\'s prose can now collide with one and be '
          'reported as a key written without backticks:\n${unhumped.join('\n')}',
    );
  });

  test('the register describes itself correctly', () {
    final faults = _selfCountFaults(register);
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  test('the parser reads every entry the file actually contains', () {
    // The control, and it counts against the file rather than against a floor.
    //
    // A floor cannot see a key lost inside a line that still parses, nor an
    // entry that stops parsing: 21 keyed entries becoming 20 satisfied
    // `>= 20` while `dtcRescanFirst` sat unguarded behind one substituted
    // dash. A control that counts is not a control that reads.
    final shippedLines = register
        .where((l) => l.startsWith('**Shipped as**'))
        .length;
    final headings = register.where(_entry.hasMatch).length;

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

  group('planted holes', () {
    // Every fixture carries the sentinel entry first. The assertion that the
    // sentinel parsed with its key is what separates 'the check found the
    // hole' from 'the fixture never reached the parser'.

    test('a clause-form English label is named, not silently dropped', () {
      final planted = _parse(_fixture('''
### 2. 這次沒有讀到凍結幀

**繁體中文** — 這次沒有讀到凍結幀

**English (clause)** — that does not mean the vehicle has none

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).
'''));
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(_qualifiedEnglishLabels(<_Entry>[planted.first]), isEmpty);

      final faults = _qualifiedEnglishLabels(planted);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('(clause)'));

      // And the second, independent consequence: the label no longer parses,
      // so the entry carries no English and the count control fires too.
      expect(planted[1].english, isNull);
      expect(_keyed(planted), hasLength(1));
    });

    test('a backticked span that is neither a key nor a path is named', () {
      // Renamed. It used to be called 'a second key in backticks…', and a
      // reviewer pointed out that its own assertions say otherwise: a span
      // spelled `l10n.foo` fails `_wholeKey`, so it lands on the
      // span-is-not-a-key branch, and the fixture then asserts one key was
      // taken. The `keys.length != 1` branch — the register header's first
      // shape rule, the one entries 42, 43 and 44 exist because of — had no
      // committed fixture at all, behind a fixture named for it. The next test
      // is that fixture.
      final planted = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb). The same rule governs `l10n.powertrainConnectFirst`.
'''));
      const keys = <String>{'sentinelKey', 'plantedKey', 'powertrainConnectFirst'};
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(_shippedLineFaults(<_Entry>[planted.first], keys), isEmpty);

      final faults = _shippedLineFaults(planted, keys);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('l10n.powertrainConnectFirst'));

      // The shape the count control cannot see: the line still parses, still
      // yields one key, and still counts once.
      expect(planted[1].keys, <String>['plantedKey']);
      expect(_keyed(planted), hasLength(2));
    });

    test('a second key without backticks on a Shipped as line is named', () {
      final planted = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb). The same rule governs l10n.powertrainConnectFirst.
'''));
      const keys = <String>{'sentinelKey', 'plantedKey', 'powertrainConnectFirst'};
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(_shippedLineFaults(<_Entry>[planted.first], keys), isEmpty);

      // Reported once, as the qualified form, not twice as two overlapping
      // findings — the qualified match is subtracted before the key scan.
      final faults = _shippedLineFaults(planted, keys);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('without backticks'));
    });

    test('two genuine backticked keys on one Shipped as line are named', () {
      // The branch the fixture above was named for and did not reach. This is
      // the historical shape verbatim: one Shipped-as line, two real keys, both
      // parsed, so the count control sees one entry and one line and agrees
      // with itself while only the first key is ever compared.
      final planted = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb), against `otherPlantedKey` — one binary readout.
'''));
      const keys = <String>{'sentinelKey', 'plantedKey', 'otherPlantedKey'};
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(_shippedLineFaults(<_Entry>[planted.first], keys), isEmpty);

      // Both spans parse, so this is not the not-a-key branch.
      expect(planted[1].keys, <String>['plantedKey', 'otherPlantedKey']);

      final faults = _shippedLineFaults(planted, keys);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('names 2 keys'));

      // And the control that cannot see it: one heading, one Shipped-as line,
      // one hedge built.
      expect(_keyed(planted), hasLength(2));
    });

    test('a backticked repository path beside a key is not a fault', () {
      // `_looksLikePath`'s accept branch had no coverage of any kind: no live
      // Shipped-as line carries a backticked path, no fixture planted one, and
      // a reviewer mutated the body to `false` with the whole suite still
      // green. The failure it guards against is a spurious fault on a
      // legitimate citation, which is milder than a silent pass and is still a
      // branch nothing exercised.
      final planted = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (`lib/l10n/app_en.arb`), beside `docs/i18n/hedge-register.md`.
'''));
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].keys, <String>['plantedKey']);
      expect(_shippedLineFaults(planted, const {'sentinelKey', 'plantedKey'}),
          isEmpty);

      // And the tightening still bites: the same line with a costume span.
      final costume = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb), also `plantedKey.arb`.
'''));
      final faults =
          _shippedLineFaults(costume, const {'sentinelKey', 'plantedKey'});
      expect(faults, hasLength(1));
      expect(faults.single, contains('plantedKey.arb'));
    });

    test('an unqualified key on a Shipped as line is named', () {
      // The half `_bareQualified` cannot see. No qualifier, no backticks: the
      // line parses, yields one key, counts once, and reads as though it
      // guarded two. `someOtherThing` in the same line is the negative control
      // — an ordinary camelCase word is not a key and must not fire.
      final planted = _parse(_fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb). The same rule governs powertrainConnectFirst, and someOtherThing is not a key at all.
'''));
      const keys = <String>{'sentinelKey', 'plantedKey', 'powertrainConnectFirst'};
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(_shippedLineFaults(<_Entry>[planted.first], keys), isEmpty);

      final faults = _shippedLineFaults(planted, keys);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('powertrainConnectFirst'));
      expect(faults.single, isNot(contains('someOtherThing')));

      // Both controls stay quiet, which is why this needed its own check.
      expect(planted[1].keys, <String>['plantedKey']);
      expect(_keyed(planted), hasLength(2));
    });

    test('an entry recording shipped copy with no Shipped as line is named', () {
      final planted = _parse(_fixture('''
### 2. 無法儲存語言設定，請再試一次。

**繁體中文** — 無法儲存語言設定，請再試一次。

**English** — Could not save the language. Try again.

**Why it is load-bearing.** The picker never silently claims success.
'''));
      const en = <String, String>{
        'plantedKey': 'Could not save the language. Try again.',
      };
      const zh = <String, String>{'plantedKey': '無法儲存語言設定，請再試一次。'};

      expect(planted.first.keys, <String>['sentinelKey']);
      expect(en.values, isNot(contains(planted.first.english)));

      final faults = _unregisteredShippedCopy(planted, en, zh);
      expect(faults, hasLength(2));
      expect(faults.every((f) => f.contains('#2')), isTrue);
      expect(faults.every((f) => f.contains('plantedKey')), isTrue);
    });

    test('a proposed entry recording shipped copy is exempt', () {
      // The other side of the same check. Without this, an exemption that had
      // stopped working would look exactly like a clean register.
      final planted = _parse(_fixture('''
### 2. 無法儲存語言設定，請再試一次。

**繁體中文** — 無法儲存語言設定，請再試一次。

**English** — NO PROJECT ENGLISH — proposed: Could not save the language. Try again.

**Status** — proposed

**Why it is load-bearing.** The picker never silently claims success.
'''));
      const en = <String, String>{'plantedKey': 'Could not save the language.'};
      const zh = <String, String>{'plantedKey': '無法儲存語言設定，請再試一次。'};

      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].isProposed, isTrue);
      expect(_statusFaults(planted), isEmpty);
      expect(_unregisteredShippedCopy(planted, en, zh), isEmpty);
    });

    test('a proposed mention in prose exempts nothing', () {
      // The finding. `**proposed**` used to be searched for anywhere in the
      // entry, so one bold pair inside an ordinary sentence took the entry out
      // of the census — and this register narrates what reviewers did on almost
      // every page, so the sentence below is house style, not a contrivance.
      final planted = _parse(_fixture('''
### 2. 無法儲存語言設定，請再試一次。

**繁體中文** — 無法儲存語言設定，請再試一次。

**English** — Could not save the language. Try again.

**Why it is load-bearing.** A reviewer once **proposed** softening this.
'''));
      const en = <String, String>{
        'plantedKey': 'Could not save the language. Try again.',
      };
      const zh = <String, String>{'plantedKey': '無法儲存語言設定，請再試一次。'};

      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].isProposed, isFalse);
      expect(planted[1].statuses, isEmpty);

      final faults = _unregisteredShippedCopy(planted, en, zh);
      expect(faults, hasLength(2));
      expect(faults.every((f) => f.contains('#2')), isTrue);
    });

    test('an English line that reads as proposed without the field is named', () {
      // The looser half of the same finding: `NO PROJECT ENGLISH yet, see the
      // picker.` exempted an entry whose 繁體中文 was verbatim shipped. Now the
      // English line exempts nothing at all — only the field does — and the two
      // readings are required to agree, so writing the sentence and forgetting
      // the field fails by name rather than quietly leaving the entry in.
      final planted = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — NO PROJECT ENGLISH — proposed: No reading yet

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      const en = <String, String>{'plantedKey': 'No reading yet.'};
      const zh = <String, String>{'plantedKey': '尚無讀值'};

      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].readsAsProposed, isTrue);
      expect(planted[1].isProposed, isFalse);

      final disagreement = _statusFaults(planted);
      expect(disagreement, hasLength(1));
      expect(disagreement.single, contains('#2'));
      expect(disagreement.single, contains('a sentence is not a field'));

      // Not exempt either, so its shipped Chinese is caught as well.
      final faults = _unregisteredShippedCopy(planted, en, zh);
      expect(faults, hasLength(1));
      expect(faults.single, contains('plantedKey'));
      expect(faults.single, contains('繁體中文'));

      // Add the field and both go quiet — the fixture tells them apart rather
      // than rejecting everything.
      final withField = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — NO PROJECT ENGLISH — proposed: No reading yet

**Status** — proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      expect(withField.first.keys, <String>['sentinelKey']);
      expect(withField[1].isProposed, isTrue);
      expect(_statusFaults(withField), isEmpty);
      expect(_unregisteredShippedCopy(withField, en, zh), isEmpty);
    });

    test('an unknown Status value exempts nothing and is named', () {
      final planted = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet

**Status** — probably proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      const en = <String, String>{'plantedKey': 'No reading yet.'};
      const zh = <String, String>{'plantedKey': '尚無讀值'};

      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].statuses, <String>['probably proposed']);
      expect(planted[1].isProposed, isFalse);

      final faults = _statusFaults(planted);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('is not a status this file knows'));
      expect(_unregisteredShippedCopy(planted, en, zh), isNotEmpty);
    });

    test('a Status line the parser cannot read is named', () {
      // The colon form still renders as a status in Markdown. `_status`
      // requires an em dash, en dash or hyphen, so the field is invisible to
      // every other guard: the entry is unkeyed, its English is ordinary
      // prose, and `_statusFaults` used to see no status at all.
      final planted = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet

**Status**: proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].isProposed, isFalse);
      expect(planted[1].statuses, isEmpty);

      final faults = _statusFaults(planted);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('cannot read'));
      expect(faults.single, contains('**Status**: proposed'));
    });

    test('a Status field indented by fewer than four spaces is still a field',
        () {
      // 1–3 spaces render as a paragraph, so the line still looks proposed.
      // Four spaces is an indented code block and must stay invisible — that
      // case is the header example, pinned below.
      final planted = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet

 **Status** — proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      expect(planted[1].isProposed, isTrue);
      expect(planted[1].statuses, <String>['proposed']);
      expect(_statusFaults(planted), isEmpty);

      final colon = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet

  **Status**: proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      expect(colon[1].isProposed, isFalse);
      final faults = _statusFaults(colon);
      expect(faults, hasLength(1));
      expect(faults.single, contains('cannot read'));
    });

    test('a Status field prefixed with NBSP is still a field', () {
      final planted = _parse(_fixture('''
### 2. 尚無讀值

**繁體中文** — 尚無讀值

**English** — No reading yet

\u00a0**Status** — proposed

**Why it is load-bearing.** Explicitly not zero and not unsupported.
'''));
      expect(planted[1].isProposed, isTrue);
      expect(_statusFaults(planted), isEmpty);
    });

    test('a duplicate or out-of-order heading number is named', () {
      // Every fault this file emits identifies an entry as `#n`, and the
      // register cross-references by number in prose. A reviewer renamed
      // `### 59.` to a second `### 58.` and nothing in the file moved: the
      // count was still right, because a duplicate is still a heading.
      final planted = _fixture('''
### 3. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).
''');
      // The un-mutated control. This fixture plants `### 3.` beside the
      // sentinel's `### 1.`, which is itself out of order, so without this the
      // assertions below could be passing on the fixture's own defect rather
      // than on the mutation.
      expect(_parse(planted).first.keys, <String>['sentinelKey']);
      expect(_selfCountFaults(planted).single, contains('numbered 1, 3'));

      final renumbered = planted
          .map((l) => l.startsWith('### 3.') ? l.replaceFirst('3.', '2.') : l)
          .toList();
      expect(renumbered, isNot(planted));
      expect(_parse(renumbered).first.keys, <String>['sentinelKey']);
      // Numbered 1, 2 and counted as two: the shape the check must accept, so
      // the duplicate below fails for being a duplicate and nothing else.
      expect(_selfCountFaults(renumbered), isEmpty);

      final duplicated = renumbered
          .map((l) => l.startsWith('### 2.') ? l.replaceFirst('2.', '1.') : l)
          .toList();
      expect(duplicated, isNot(renumbered));
      expect(_parse(duplicated).first.keys, <String>['sentinelKey']);

      // The count is untouched: two headings, and the header says two.
      final faults = _selfCountFaults(duplicated);
      expect(faults, hasLength(1));
      expect(faults.single, contains('numbered 1, 1'));
      expect(faults.single, contains('repeated: 1'));

      // Out of order, without a duplicate, is the same fault.
      final swapped = renumbered
          .map((l) => l.startsWith('### 2.') ? l.replaceFirst('2.', '5.') : l)
          .toList();
      expect(swapped, isNot(renumbered));
      expect(_parse(swapped).first.keys, <String>['sentinelKey']);
      expect(_selfCountFaults(swapped).single, contains('numbered 1, 5'));
    });

    test('a proposed entry that also names a shipped key is named', () {
      // The reverse contradiction. The field says this English is not
      // established; the key says the app ships it, and the exact comparison
      // is passing against it on the same run. While both stand the entry is
      // exempt from the declaration census for copy that demonstrably ships.
      final planted = _parse(_fixture('''
### 2. 清除故障碼？

**繁體中文** — 清除故障碼？

**English** — Clear fault codes?

**Status** — proposed

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).

**Why it is load-bearing.** It must not gain scope.
'''));
      expect(planted.first.keys, <String>['sentinelKey']);
      expect(planted[1].isProposed, isTrue);
      expect(planted[1].hasShipped, isTrue);

      final faults = _statusFaults(planted);
      expect(faults, hasLength(1));
      expect(faults.single, contains('#2'));
      expect(faults.single, contains('plantedKey'));
      expect(faults.single, contains('Those contradict'));

      // Neither half alone is a fault, so this is the pair and not either one.
      final unkeyed = _parse(_fixture('''
### 2. 清除故障碼？

**繁體中文** — 清除故障碼？

**English** — Clear fault codes?

**Status** — proposed

**Why it is load-bearing.** It must not gain scope.
'''));
      expect(_statusFaults(unkeyed), isEmpty);
      final keyed = _parse(_fixture('''
### 2. 清除故障碼？

**繁體中文** — 清除故障碼？

**English** — Clear fault codes?

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).

**Why it is load-bearing.** It must not gain scope.
'''));
      expect(_statusFaults(keyed), isEmpty);
    });

    test('a tilde-fenced block in the register is named', () {
      // Markdown accepts two fence characters and the check read one. Wrapped
      // in `~~~` every line stays at column 0, so the parser and all the
      // controls see a real entry while the rendered page shows an example.
      final planted = _fixture('''
~~~
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).
~~~
''');
      expect(_parse(planted).first.keys, <String>['sentinelKey']);

      // The point: the wrapped entry is fully visible to the parser, which is
      // why rendering it as an example is a disagreement rather than a hiding.
      expect(_keyed(_parse(planted)), hasLength(2));

      final faults = _selfCountFaults(planted);
      expect(faults.any((f) => f.contains('fenced-block delimiters')), isTrue);
      expect(faults.any((f) => f.contains('~~~')), isTrue);

      // An indented block is not a fence and must not be reported as one.
      final indented = _fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).

**Why it is load-bearing.** For example:

    **Status** — proposed
''');
      expect(
        _selfCountFaults(indented)
            .any((f) => f.contains('fenced-block delimiters')),
        isFalse,
      );
      // And the indented line did not become a marker.
      expect(_parse(indented)[1].statuses, isEmpty);
    });

    test('a fenced block in the register is named', () {
      // The parsers are line-anchored and fence-blind, and this repository has
      // already had one fenced worked example satisfy three checks at once.
      // Rather than teach every line-anchored reader about fences, the
      // register is required to have none, so the day somebody adds one is the
      // day this says so.
      final planted = _fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).

**Why it is load-bearing.** For example:

```
### 3. an entry that does not exist
```
''');
      expect(_parse(planted).first.keys, <String>['sentinelKey']);

      final faults = _selfCountFaults(planted);
      // The fenced heading is counted as real, which is the point, so the
      // count fault fires alongside the fence fault.
      expect(faults.any((f) => f.contains('fenced-block delimiters')), isTrue);
      expect(
        _selfCountFaults(planted.where((l) => !l.startsWith('```')).toList())
            .any((f) => f.contains('fenced-block delimiters')),
        isFalse,
      );
    });

    test('a register that miscounts itself is named', () {
      final planted = _fixture('''
### 2. 故障燈沒有亮

**繁體中文** — 故障燈沒有亮

**English** — The fault lamp is not lit

**Shipped as** `plantedKey` (lib/l10n/app_en.arb).
''');
      expect(_parse(planted).first.keys, <String>['sentinelKey']);
      expect(_selfCountFaults(planted), isEmpty);

      final miscounted = planted
          .map((l) => l == '2 entries.' ? '3 entries.' : l)
          .toList();
      expect(miscounted, isNot(planted));
      final faults = _selfCountFaults(miscounted);
      expect(faults, hasLength(1));
      expect(faults.single, contains('says 3 entries'));
      expect(faults.single, contains('carries 2'));

      final unstated = planted.where((l) => l != '2 entries.').toList();
      expect(_selfCountFaults(unstated).single, contains('found 0 such lines'));
    });
  });
}
