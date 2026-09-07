// The custom-PID engine's refusals, held to carrying an identifier and its
// data.
//
// Three constructions in `lib/obd/pid/` decide what an author is told when a
// formula, a request or a CSV row is refused: `FormulaException`,
// `PidRejectionReason` and `PidCsvDiagnostic`. Each carries a reason code the
// screen translates. Two things can silently undo that, and neither is
// something `flutter analyze` can see:
//
//   * a new `FormulaException` throw settling for `issue: null`. The
//     constructor makes the argument required, so the compiler refuses a throw
//     that omits it; what it cannot refuse is a deliberate null, which would
//     put the engine's Traditional Chinese back on an English screen through
//     the editor's fallback.
//   * a throw that names a reason whose sentence quotes a value — the byte
//     letter, the referenced PID, the row number — and does not pass that
//     value. The copy helper then renders `“” is not a number…` or
//     `Row 0: …`, which is worse than the Chinese it replaced: it is fluent,
//     English, and wrong about the file in front of the reader.
//
// Both are read out of the source rather than exercised, because both are
// properties of a call that may never run in a test.
//
// The reader is `test/support/dart_source_reader.dart` — the shared one on
// `main`, not a copy. `transport_issue_guard_test.dart` imports the same file
// and its "the reader itself: what counts as code" fixtures drive it, so the
// two bugs it has already had (an escape check comparing a one-character value
// against a two-character string, and raw strings like `r'C:\'` whose
// backslash is content) are pinned there and none of it is re-tested here.
//
// This branch first landed a second copy of that reader, a bool-mask rewrite,
// with a header claiming it was taken verbatim and that the extraction had not
// happened yet. All of that was false against `main`, which had already
// extracted a wider `SourceRegion` model that six test files import. Worse than
// the duplication was the header: it argued whoever resolved the add/add
// conflict into keeping the weaker copy — and nothing exercised that copy, so
// reintroducing the escape bug into it left the suite green. The copy is gone;
// what stays is the note that a header telling a resolver which side to keep
// has to be true, because it will be believed.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_source_reader.dart';

/// Every Dart file under `lib/`, because a throw is not confined to the file
/// that declares the exception. `polling_engine.dart` already catches
/// `FormulaException`; nothing stops it throwing one.
List<File> _librarySources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// The declaring constructor of each class, which `\bName\(` also matches.
///
/// Held as a file plus the exact first parameter rather than by skipping the
/// file, so a real call in the same file is still read. `args.any(contains)`
/// would be the loose version of this, and the transport guard records what
/// that cost: a transport with a field named `message` passed straight through
/// it.
const _declarations = <String, ({String file, String firstParameter})>{
  'FormulaException': (
    file: 'lib/obd/pid/formula_engine.dart',
    firstParameter: 'this.message',
  ),
  'PidRejectionReason': (
    file: 'lib/obd/pid/pid.dart',
    firstParameter: 'this.issue',
  ),
  'PidCsvDiagnostic': (
    file: 'lib/obd/pid/pid_csv.dart',
    firstParameter: 'this.issue',
  ),
};

/// Reason codes whose sentence names a value, and the arguments that carry it.
///
/// Written out by hand from the ARB entries. An arm added to a copy switch that
/// reads a field nothing sets has to be added here too, which is the point:
/// this table is the written statement of what "carried as data" means for each
/// reason.
const _dataCarried = <String, List<String>>{
  'FormulaIssue.unparsableTerm': ['term:'],
  'FormulaIssue.log10NonPositiveArgument': ['argument:'],
  'FormulaIssue.byteBeyondResponse': ['byteLetter:', 'byteCount:'],
  'FormulaIssue.dependencyControllerUnknown': ['pidKey:'],
  'FormulaIssue.dependencyTwoDefinitions': ['pidKey:'],
  'FormulaIssue.dependencyNotYetMeasured': ['pidKey:'],
  'PidRejection.serviceNotReadOnly': ['service:', 'allowedServices:'],
  'PidRejection.identifierWrongLength': ['service:', 'expectedBytes:'],
  'PidRejection.invalidHeader': ['text:'],
  'PidRejection.minNotANumber': ['text:'],
  'PidRejection.maxNotANumber': ['text:'],
  'PidRejection.redlineNotANumber': ['text:'],
  'PidCsvIssue.malformedCsv': ['text:'],
  'PidCsvIssue.duplicateHeaderColumns': ['columns:'],
  'PidCsvIssue.missingRequiredColumns': ['columns:', 'requiredColumns:'],
  'PidCsvIssue.rowTooFewColumns': ['lineNumber:'],
  'PidCsvIssue.rowInvalidModeAndPid': ['lineNumber:', 'text:'],
  'PidCsvIssue.rowEmptyEquation': ['lineNumber:'],
  'PidCsvIssue.rowDefinitionRejected': ['lineNumber:', 'rejection:'],
  'PidCsvIssue.rowRangeDefaulted': ['lineNumber:', 'minValue:', 'maxValue:'],
};

/// One construction found in the source: where it is, and its top-level
/// arguments, or null when the call could not be read.
typedef _Call = ({String where, List<String>? args});

/// One argument with its comments and string contents blanked out.
///
/// Not decoration. This file's calls put the reasoning for a reason code in a
/// comment immediately before the argument that carries it, so the raw argument
/// text begins `// One identifier for both throw sites...` and no
/// `startsWith` on it can see the name that follows. The first version of this
/// guard reported three correct throws and two correct constructions for
/// exactly that, which is a guard that cries wolf.
///
/// Blanking strings as well as comments is the other half: a Chinese message
/// containing the word `null`, or a doc string naming `FormulaIssue.x`, is not
/// this call saying either thing.
String _argument(String raw) => codeOnly(raw).trim();

Iterable<_Call> _callsTo(String className) sync* {
  final declaration = _declarations[className]!;
  final pattern = RegExp('\\b$className\\(');
  for (final file in _librarySources()) {
    final src = file.readAsStringSync();
    if (!src.contains(className)) continue;
    final mask = codeMask(src);
    for (final match in pattern.allMatches(src)) {
      // Named inside a string or a comment: not a construction.
      if (!mask[match.start]) continue;
      final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
      final args = topLevelArgs(src, mask, match.end - 1);
      if (args != null &&
          file.path.endsWith(declaration.file.split('/').last) &&
          args.isNotEmpty &&
          args.first.trim() == declaration.firstParameter) {
        continue; // the declaring constructor itself
      }
      yield (where: '${file.path}:$line', args: args);
    }
  }
}

void main() {
  _pointerTests();

  test('no FormulaException settles for a null identifier', () {
    final naked = <String>[];
    for (final call in _callsTo('FormulaException')) {
      final args = call.args;
      if (args == null) {
        // Not skipped. An unreadable call dropped in silence turns any future
        // desync into a green run; reporting it means the reader can still be
        // wrong but cannot be quiet about it.
        naked.add('${call.where} — could not be read');
        continue;
      }
      final issue = args
          .map(_argument)
          .firstWhere((a) => a.startsWith('issue:'), orElse: () => '');
      if (issue.isNotEmpty && !issue.contains('null')) continue;
      naked.add(
        '${call.where} — ${issue.isEmpty ? "no issue: argument" : issue}',
      );
    }
    expect(
      naked,
      isEmpty,
      reason:
          'these reach the PID editor with a Traditional Chinese sentence and '
          'nothing the screen can translate:\n${naked.join('\n')}',
    );
  });

  test('a reason whose sentence quotes a value is given that value', () {
    final missing = <String>[];
    for (final className in _declarations.keys) {
      for (final call in _callsTo(className)) {
        final args = call.args;
        if (args == null) {
          missing.add('${call.where} — could not be read');
          continue;
        }
        final stripped = args.map(_argument).toList();
        final joined = stripped.join(',');
        for (final entry in _dataCarried.entries) {
          if (!joined.contains(entry.key)) continue;
          for (final argument in entry.value) {
            // Top-level arguments only. A nested construction's `text:` is not
            // this call's, which is the whole reason the reader returns the
            // arguments rather than the source text.
            final given = stripped.any((a) => a.startsWith(argument));
            if (given) continue;
            missing.add('${call.where} — ${entry.key} without $argument');
          }
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'the ARB entry for each of these names a value, so the copy helper '
          'renders an empty quotation or a row 0 without it:\n'
          '${missing.join('\n')}',
    );
  });

  test('every reason code this guard names still exists', () {
    // A table of strings goes stale in silence: rename `FormulaIssue.term` and
    // every entry above stops matching anything, which reads as success. The
    // enums are declared in `lib/obd/pid/`, so the names can be checked against
    // the source that declares them.
    final declared = <String>{};
    for (final path in [
      'lib/obd/pid/formula_engine.dart',
      'lib/obd/pid/pid.dart',
      'lib/obd/pid/pid_csv.dart',
    ]) {
      final code = codeOnly(File(path).readAsStringSync());
      for (final enumName in ['FormulaIssue', 'PidRejection', 'PidCsvIssue']) {
        final body = RegExp('enum $enumName \\{([^}]*)\\}').firstMatch(code);
        if (body == null) continue;
        for (final value in RegExp(r'\b([a-z]\w*)\b')
            .allMatches(body.group(1)!)
            .map((m) => m.group(1)!)) {
          declared.add('$enumName.$value');
        }
      }
    }
    expect(declared, isNotEmpty, reason: 'no enum values were found at all');
    for (final named in _dataCarried.keys) {
      expect(
        declared,
        contains(named),
        reason: '$named is named by this guard and no longer exists',
      );
    }
  });
}

/// Every `lib/…` or `test/…` Dart path a comment under `lib/` points at.
///
/// Backticked, because that is how this repo writes a path and it is what
/// separates a real pointer from prose that happens to contain a slash.
final RegExp _pointer = RegExp(r'`((?:lib|test)/[A-Za-z0-9_/.]+\.dart)`');

void _pointerTests() {
  test('a comment that names a guard names one that exists', () {
    // Five pointers on this branch led nowhere: three to
    // `test/l10n/formula_issue_guard_test.dart`, which was renamed to
    // `pid_reason_guard_test.dart` before it landed, one to
    // `lib/ui/screens/pids/formula_copy.dart`, whose file is
    // `pid_formula_copy.dart`, and one to a file that was deleted.
    //
    // The cost is not the broken link. Every one of those comments was
    // explaining why some rule is safe to rely on — "the guard lives here" —
    // and a reader who takes the sentence at its word inherits a belief that a
    // check exists when none does. That is the same failure as a green test
    // that asserts nothing, arriving by a different route.
    //
    // Repo-wide rather than scoped to this slice, because the failure is: all
    // 26 such pointers under `lib/` resolve today, so there is nothing to
    // grandfather and no reason to make the next one wait for its own guard.
    final broken = <String>[];
    for (final file in _librarySources()) {
      final src = file.readAsStringSync();
      final regions = sourceRegions(src);
      for (final match in _pointer.allMatches(src)) {
        // Only in a comment. A path inside a string literal is an import or a
        // runtime path, which is the compiler's business, not this guard's.
        if (regions[match.start] != SourceRegion.comment) continue;
        final path = match.group(1)!;
        if (File(path).existsSync()) continue;
        final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
        broken.add('${file.path}:$line -> $path');
      }
    }
    expect(
      broken,
      isEmpty,
      reason: 'these comments name a file that does not exist:\n'
          '${broken.join('\n')}',
    );
  });
}
