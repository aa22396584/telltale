// Some strings in this app are written for a file, not for a person on a
// phone, and they are frozen in Traditional Chinese so that two people holding
// the same evidence file can compare it line by line. `DatumStatus.reason`,
// `.formula` and `.assumptions`, `FuelType.exportLabel`,
// `Drivetrain.exportLabel`.
//
// Every one of those was, at some point, rendered straight onto a screen. That
// is how the English build came to show 「車重 1500 kg（通用預設）；Cd 0.30…」 in
// its estimate details dialog, and 汽油 in its fuel picker. The argument for
// freezing the wording is about storage; it was silently taken as licence to
// display it.
//
// The fix in each case was the same shape — an identifier for the screen, the
// string for the file — and nothing stopped the next one from happening again.
// This does. It reads the source of `lib/ui` rather than pumping a widget,
// because the failure is a reference, and a reference is visible without
// running anything — where it is spelled in a way this file knows to look for.
// That qualification is not decoration: [_readsMember] lists the spellings it
// cannot see, and this sentence is the one a reader meets first, so it was
// promising more than the guard below it delivers.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_source_reader.dart';

/// Symbols that exist to be written into an export and must not be read by the
/// interface, with what to use instead.
const _exportOnly = <String, String>{
  'exportLabel':
      'fuelTypeLabel / drivetrainLabel in '
          'lib/ui/screens/settings/vehicle_profile_copy.dart',
  '.assumptions':
      'assumptionsText(l10n, status, profile) in '
          'lib/ui/widgets/status/datum_status_copy.dart',
  '.formula':
      'datumFormulaText(l10n, status) in '
          'lib/ui/widgets/status/datum_status_copy.dart',
  '.reason':
      'DatumStatus.reasonCode, .statusReason or .gaps, which '
          'datumReasonText(l10n, status) already reads in that order',
  'exportSummary':
      'adapterConcernSummary(l10n, concern) in '
          'lib/ui/screens/settings/adapter_concern_copy.dart',
};

/// Where an export-only symbol is legitimately named, and *which* one.
///
/// Per symbol, not per file. It was per file, and the file it excused is the
/// one place in `lib/ui` that reads any of these — so a single entry silently
/// covered every symbol in [_exportOnly], including ones added later. That is
/// how `.reason` could have been added to the map above and changed nothing:
/// the only file that read it was already excused wholesale.
///
/// `datum_status_copy` is the boundary itself, so it does read two of the
/// frozen strings — but only the two below, and only where there is no
/// identifier to render instead. `.reason` is deliberately not among them:
/// every `DatumStatus` that carries one also carries a `reasonCode`, a
/// `statusReason` or `gaps`, which is what `datum_reason_guard_test.dart`
/// enforces.
const _allowed = <String, Set<String>>{
  'lib/ui/widgets/status/datum_status_copy.dart': {'.formula', '.assumptions'},
};

/// The allowance for [path], with Windows separators folded to `/`.
///
/// [_allowed] is written with forward slashes and `Directory.listSync` hands
/// back backslashes on Windows, so without this the allowance matches nothing
/// there and the guard reports the two legitimate reads in the boundary file.
/// Loud rather than silent, but wrong — and unnoticed, because CI's Windows job
/// runs twelve named test files and this is not one of them. The whole suite
/// runs on Linux only.
Set<String> allowanceFor(String path) =>
    _allowed[path.replaceAll(r'\', '/')] ?? const <String>{};

/// [source] with comments and string content replaced by a character that is
/// neither whitespace nor part of an identifier, and line breaks kept.
///
/// Not [codeOnly], which blanks with spaces. `{'code': code, 'why': reason}`
/// becomes `{      : code,      : reason}`, and that is precisely the shape of
/// an object pattern — so a bare local called `reason`, which is a common name
/// in `lib/ui`, was reported as a read of the frozen sentence. Two changes that
/// were each right on their own produced it: the pattern arm was written
/// against source text, where a comma is followed by a quote, and the narrower
/// view then removed the quote and left the space.
///
/// A NUL cannot appear in Dart source, so nothing legitimate matches through
/// one. The tight colon in [_readsMember] covers the same line for a different
/// reason, and neither subsumes the other: a map written `{'a': 1, 'k':reason}`
/// needs this view, and a conditional the formatter wrapped onto `: reason`
/// needs that colon. There is a fixture for each, because two mechanisms with
/// one fixture between them is one mechanism and a spare.
String _scannable(String source) {
  final mask = codeMask(source);
  final out = StringBuffer();
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    out.write(mask[i] ? c : (c == '\n' ? '\n' : '\u0000'));
  }
  return out.toString();
}

/// Matches a read of [member] however it is spelled.
///
/// Several spellings, because a guard that only knows one of them is a guard
/// about spelling rather than about the read. The count is left out on purpose:
/// this sentence said "two" while the regex held three alternatives, which is
/// the failure `dart_source_reader.dart` warns about for its own list, one
/// import away.
///
///   * `x.member` — the receiver is deliberately unconstrained. It used to be
///     `(status|items[...]|\w+Status)`, so `final datum = status;
///     Text(datum.reason)` was invisible to a guard whose whole subject is that
///     read. A name is not a type, and pinning by name is right exactly once.
///   * `Type(:final member)` and `Type(member: final x)` — a Dart object
///     pattern reads the getter with no dot at all. `lib/ui` already
///     destructures this way in four places, three of them in the boundary
///     file itself, so this is a spelling somebody here reaches for rather
///     than a hypothetical.
///
/// Both ends are bounded. `TelemetryStatus.formulaError` is an enum value, not
/// a read, so the member has to end where the word ends — and `$` continues a
/// Dart identifier, so `datum.reason$detail` is a different member and not
/// this one. That boundary is the whole difference between this guard and one
/// that cries wolf on its first run, which is how allowances get widened until
/// they excuse the real thing.
///
/// What it still cannot see, listed because a guard that names only its false
/// positives reads as though the false negatives were handled. No count here
/// either: this list said "three" with four bullets under it, which is the
/// exact failure the reader it imports warns about.
///
///   * a selector split from its receiver — `status. /* note */ reason`
///   * a pattern that binds through a type rather than `final` or `var` —
///     `DatumStatus(reason: String r)`. `reason: something` is also how a
///     named argument is spelled, and an argument is not a read, so this stops
///     where the two stop being distinguishable by text.
///   * an implicit `this` — inside `extension X on DatumStatus`, a bare
///     `reason` is the getter. Nothing textual separates it from a local.
///   * a space after the colon of a shorthand field — `DatumStatus(: final r)`.
///     `dart format` does not write one, and the tight colon is what keeps a
///     map entry from reading as a pattern, so this is the price of that.
///
/// The one false positive known of, found by review attacking the third arm
/// with eleven shapes: a label on a local declaration, `reason: final x = 1;`,
/// is legal Dart and matches. Arms one and two have had no sweep of the same
/// kind, so this is what has been looked for and not a census of what exists.
///
/// It cannot reach a tree this project accepts. `flutter analyze --help` says
/// `--[no-]fatal-warnings  Treat warning level issues as fatal. (defaults to
/// on)`, the analyzer calls this `unused_label`, and `.github/workflows/ci.yml`
/// runs `flutter analyze`. Measured too, on a tree holding that warning and no
/// info: exit 1. The flag default is the fact worth citing, because an exit
/// number differs between `dart analyze` and `flutter analyze` and a reader
/// checking it could reach for either.
///
/// And it reads names, not types. `PollingEngine.formula` is a `FormulaEngine`
/// and no frozen string, so `engine.formula` in `lib/ui` would be reported.
/// The answer then is an entry in [_allowed] — the receiver anchor coming back
/// would take the alias with it.
RegExp _readsMember(String member) {
  // `RegExp.escape` is belt and braces, and honestly it is not load-bearing:
  // every member in [_exportOnly] is plain letters, so escaping one changes
  // nothing and no mutation of this call can be made to fail. The dot is
  // escaped separately below, and THAT is what the competing-word fixture
  // pins — an unescaped `.` matches any character, and `treason` is a word.
  final m = RegExp.escape(member);
  const end = r'(?![A-Za-z0-9_$])';
  const start = r'(?<![A-Za-z0-9_$])';
  // The colon binds tight. `:final reason` and `:reason` are how the shorthand
  // is written; `'why': reason` and a wrapped ternary's `: reason` both put a
  // space there. That one character is what separates a pattern from a map
  // entry once string content has been taken out of the line.
  const bind = r':(?:final\s+|var\s+)?';
  return RegExp(
    r'\.' '$m$end'
    r'|(?:[(,]\s*|^\s*)' '$bind$m$end'
    '|$start$m' r'\s*:\s*(?:final|var)\s',
  );
}

/// Every read of an export-only symbol in [source], one offence line each.
///
/// Separate from the directory walk so the rule can be shown a file that does
/// not exist. While the only input was `lib/ui` itself, the miss this replaced
/// could not be written down as a test: there was nowhere to put the line that
/// defeated it.
List<String> offencesIn(String path, String source, Set<String> allowedHere) {
  final offences = <String>[];

  // Read through the shared reader rather than `split('//').first`, which cut
  // the line at the `//` of any URL and hid every symbol after it.
  //
  // Comments and string content both go, because the export-only doc comments
  // name these symbols on purpose and so can a string — `const key =
  // 'engine.formula'` reads no member. What makes the narrower view safe is
  // that the reader counts the inside of `${...}` as code, so
  // `Text('\${status.reason}')` still arrives here whole.
  final lines = source.split('\n');
  final stripped = _scannable(source).split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final code = stripped[i];
    for (final entry in _exportOnly.entries) {
      if (allowedHere.contains(entry.key)) continue;
      // For a member, the prefilter drops the dot: an object pattern reads the
      // getter without one.
      final member = entry.key.startsWith('.') ? entry.key.substring(1) : null;
      if (!code.contains(member ?? entry.key)) continue;
      if (member != null && !_readsMember(member).hasMatch(code)) continue;
      offences.add('$path:${i + 1}  ${line.trim()}\n    use ${entry.value}');
    }
  }
  return offences;
}

void main() {
  test('lib/ui never reads a string that was written for an export file', () {
    final offences = <String>[];

    for (final entity in Directory('lib/ui').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      offences.addAll(
        offencesIn(
          entity.path,
          entity.readAsStringSync(),
          allowanceFor(entity.path),
        ),
      );
    }

    expect(
      offences,
      isEmpty,
      reason:
          'These read a string that is frozen in Traditional Chinese because a '
          'telemetry export needs it to be. Showing it puts that language on '
          'the screen regardless of what the reader chose.\n\n'
          '${offences.join('\n')}',
    );
  });

  test('the allowance survives a Windows path separator', () {
    const posixPath = 'lib/ui/widgets/status/datum_status_copy.dart';
    final posix = allowanceFor(posixPath);
    // Without this the two sides could agree by both being empty, which is
    // what the bug looks like.
    expect(posix, isNotEmpty);
    expect(allowanceFor(posixPath.replaceAll('/', r'\')), posix);
  });

  test('the allowance still names a file that exists', () {
    // An allowance that outlives its file is an allowance nobody notices is
    // excusing nothing — and the next person widens it rather than deleting it.
    for (final entry in _allowed.entries) {
      expect(File(entry.key).existsSync(), isTrue, reason: '${entry.key} is gone');
      // And still names symbols the scan actually looks for. An allowance for
      // a symbol that left `_exportOnly` excuses nothing and reads as though it
      // does.
      for (final symbol in entry.value) {
        expect(
          _exportOnly.keys,
          contains(symbol),
          reason: '${entry.key} is excused for $symbol, which is not scanned',
        );
      }
    }
  });

  // The fixtures below are Dart source as text, not code that runs. Every
  // negative case carries one line the guard is known to report, so a fixture
  // that stopped reaching the scan — a typo, a reader that lost the file —
  // fails instead of reading as a clean pass.
  const sentinel = '  return status.reason ?? "";';

  List<String> scan(String source, [Set<String> allowed = const {}]) =>
      offencesIn('fixture.dart', source, allowed);

  test('a frozen string read through a local name is still a read', () {
    // The case this guard exists for and could not see. While the match began
    // `(status|items[...]|\w+Status)`, renaming the receiver on one line was
    // enough to put the export sentence back on an English screen.
    //
    // Over all three members, not just `.reason`. With one fixture, putting
    // the anchor back for the other two left every assertion in this file
    // green while `datum.formula` and `datum.assumptions` went invisible — a
    // fixture that covers one member is a claim about one member.
    for (final member in const ['reason', 'formula', 'assumptions']) {
      final offences = scan('''
String render(DatumStatus status) {
  final datum = status;
  return describe(datum.$member);
}
''');
      expect(offences, hasLength(1), reason: member);
      expect(offences.single, contains('fixture.dart:3'), reason: member);
      expect(offences.single, contains('datum.$member'), reason: member);
    }
  });

  test('an object pattern reads the getter with no dot at all', () {
    // `lib/ui` destructures this way already. A guard that only knows the
    // dotted spelling is a guard about spelling, not about the read.
    final offences = scan('''
String render(DatumStatus status) {
  final DatumStatus(:final reason) = status;
  return reason ?? "";
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('fixture.dart:2'));
  });

  test('a pattern that renames the field is a read too', () {
    final offences = scan('''
String render(Object o) {
  if (o case DatumStatus(reason: final r)) return r ?? "";
  return "";
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('fixture.dart:2'));
  });

  test('a named argument is not a read', () {
    // `reason: x` passes a value in; `reason: final x` binds one out. The
    // first is how every `DatumStatus` is built and must stay silent, which is
    // what keeps the pattern arm above from being a wolf-crier.
    final offences = scan('''
DatumStatus make(String? text) {
  final built = DatumStatus(reason: text, formula: text);
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a map with string keys is not a pattern', () {
    // Review found this by breaking the guard rather than by reading it. Take
    // the string content out of `{'code': code, 'why': reason}` by replacing
    // it with spaces and the line reads `{      : code,      : reason}` — the
    // shape of an object pattern, matched against a bare local. `reason` is
    // one of the more common local names in `lib/ui`, so this was a false
    // report waiting for the first map somebody wrote.
    final offences = scan('''
Map<String, String> row(String reason, String formula) {
  final m = {'code': reason, 'why': reason, 'how': formula};
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a pattern the formatter split across lines is still a read', () {
    // `dart format` writes this by itself once the field list is long enough.
    // Only the first line then carries the `(`, and the scan is line by line,
    // so anchoring the shorthand on a preceding bracket saw none of it.
    final offences = scan('''
String render(DatumStatus status) {
  final DatumStatus(
    :final reason,
    :final formula,
  ) = status;
  return describe(reason, formula);
}
''');
    expect(offences, hasLength(2));
    expect(offences.first, contains('fixture.dart:3'));
    expect(offences.last, contains('fixture.dart:4'));
  });

  test('a map key written without a space is still not a pattern', () {
    // What the NUL view carries on its own. Blank the string with spaces
    // instead and `, 'k':reason` becomes `,      :reason` — a comma, then
    // whitespace, then a colon that binds tight. The formatted-map fixture
    // above cannot see that, because a space after the colon is enough to
    // stop it there.
    final offences = scan('''
Map<String, Object> row(String reason) {
  final m = {'a': 1, 'why':reason};
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a conditional the formatter wrapped is not a pattern', () {
    // What the tight colon carries on its own. There is no string on the
    // colon's line, so the NUL view has nothing to do; only the space after
    // the colon separates `: reason` from a shorthand field, and the wrapped
    // shorthand fixture needs that line to be matched.
    final offences = scan('''
String render(DatumStatus status, bool short) {
  final reason = describe(status);
  return short
      ? "short"
      : reason;
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a member named inside a string literal is not a read', () {
    final offences = scan('''
String render(DatumStatus status) {
  const key = "engine.formula";
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a read inside an interpolation is still a read', () {
    // Why the view is the reader's `codeOnly` and not a blunt strip of every
    // literal: the inside of an interpolation is code, and this is a read.
    final offences = scan(r'''
String render(DatumStatus status) {
  return "reason: ${status.reason}";
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('fixture.dart:2'));
  });

  test('a longer member is not the member, even beside a competing word', () {
    // `treason` holds `reason` after a character that is not a dot. Let the
    // leading `.` lose its backslash and it becomes "any character", which
    // matches that `t`. The plain boundary fixture below has no such word, so
    // it stayed green through exactly that regression — a negative fixture
    // only discriminates against the mutations its own text can reach.
    final offences = scan('''
String render(DatumStatus status) {
  final code = status.reasonCode; final treason = code;
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('a dollar continues an identifier, so that is a different member', () {
    final offences = scan(r'''
String render(DatumStatus status) {
  final other = status.reason$detail;
  return status.reason ?? "";
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('fixture.dart:3'));
  });

  test('a longer member is not the member', () {
    // `reasonCode` is the identifier the screen is supposed to read. Reporting
    // it would make this guard cry wolf on the fix it is asking for.
    final offences = scan('''
String render(DatumStatus status) {
  final code = status.reasonCode;
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('an enum value that ends in a member name is not a read', () {
    final offences = scan('''
String render(DatumStatus status) {
  final kind = TelemetryStatus.formulaError;
$sentinel
}
''');
    expect(offences, hasLength(1));
    expect(offences.single, contains('return status.reason'));
  });

  test('the rule may be written down in a comment without breaking it', () {
    final offences = scan('''
String render(DatumStatus status) {
  // Never `status.reason` here — see the header of this file.
$sentinel
}
''');
    expect(offences, hasLength(1));
    // Line 3, not 4: a `'''` literal drops the newline that opens it, so the
    // first line of every fixture here is the one after the quotes.
    expect(offences.single, contains('fixture.dart:3'));
  });

  test('an allowance covers the symbol it names and no other', () {
    const source = '''
String render(DatumStatus status) {
  final a = status.formula;
  final b = status.assumptions;
  return "";
}
''';
    expect(scan(source), hasLength(2));
    expect(scan(source, {'.formula'}), hasLength(1));
    expect(scan(source, {'.formula'}).single, contains('.assumptions'));
    expect(scan(source, {'.formula', '.assumptions'}), isEmpty);
  });
}
