/// Import and export of PID definitions in Torque's CSV schema.
///
/// The column order matches the on-disk format the original app uses, so a
/// definition list exported from Torque can be dropped straight in, and one
/// exported here can be taken back out.
library;

import 'dart:convert';

import 'package:csv/csv.dart';

import '../addressing.dart';
import 'pid.dart';
import 'priority_tier.dart';

/// Why a row, or a whole file, could not be imported as written.
///
/// Identifiers rather than sentences. The importer runs in `lib/obd/`, which
/// carries no language; the words live in
/// `lib/ui/screens/pids/pid_import_copy.dart`. Line numbers, column names and
/// substituted bounds travel as data on [PidCsvDiagnostic] and reach the ARB
/// as placeholders — a row number is not prose.
enum PidCsvIssue {
  /// The file is not CSV at all. Carries the decoder's own complaint.
  malformedCsv,

  /// The file parsed, and has no rows in it.
  noRows,

  /// Two columns in the header row claim the same name. Carries them.
  duplicateHeaderColumns,

  /// The header row does not name every column the importer needs. Carries
  /// which are missing and which are required.
  missingRequiredColumns,

  /// A row has fewer cells than the four that are always needed.
  rowTooFewColumns,

  /// A row's mode+PID is not hex byte pairs. Carries the cell as written.
  ///
  /// Distinct from a [PidRejection.malformedModeAndPid] arriving through
  /// [rowDefinitionRejected]: this one quotes the offending cell back, which
  /// is what somebody needs to find it in a spreadsheet of 200 rows.
  rowInvalidModeAndPid,

  /// A row's equation cell is empty.
  rowEmptyEquation,

  /// A row was refused by the rule the editor also applies. Carries the
  /// [PidRejectionReason], which is where the actual fact is; the two call
  /// sites in this file differ only in which validator reached it first, and
  /// would otherwise render the same sentence twice under two names.
  rowDefinitionRejected,

  /// A row imported with bounds the file did not supply. A warning: the row is
  /// in, drawn against a scale nobody chose. Carries the substituted pair.
  rowRangeDefaulted,

  /// Rows were read, none of them yielded a definition, and no row said why.
  /// Not [noRows]: there was content, and it produced nothing.
  nothingImportable,
}

/// One [PidCsvIssue] with whatever the sentence for it names.
class PidCsvDiagnostic {
  const PidCsvDiagnostic(
    this.issue, {
    this.lineNumber,
    this.text,
    this.columns,
    this.requiredColumns,
    this.rejection,
    this.minValue,
    this.maxValue,
  });

  final PidCsvIssue issue;

  /// The 1-based line in the file, as a spreadsheet numbers it.
  final int? lineNumber;

  /// A cell, or a decoder message, quoted back as written.
  final String? text;

  /// Column names, spelled as this app spells them.
  final List<String>? columns;

  /// The columns the importer cannot do without.
  final List<String>? requiredColumns;

  /// The shared definition rule's own answer, for
  /// [PidCsvIssue.rowDefinitionRejected].
  final PidRejectionReason? rejection;

  /// The bounds that were substituted, for [PidCsvIssue.rowRangeDefaulted].
  final double? minValue;
  final double? maxValue;
}

class PidCsvResult {
  final List<Pid> pids;

  /// One entry per row that could not be parsed, with the reason. Surfaced to
  /// the user rather than swallowed: a silently-skipped row looks identical to
  /// a successful import that happened to be short.
  ///
  /// The screen renders `errors.first`, and only when nothing imported at all;
  /// otherwise it shows how many rows were skipped.
  final List<PidCsvDiagnostic> errors;

  /// Rows that were imported, but not exactly as written.
  ///
  /// Distinct from [errors], which reject a row. A warning means the app made
  /// a choice on the author's behalf — and the one that matters is a
  /// substituted scale, because a needle reads as authoritative against
  /// whatever bounds it is drawn on, whoever picked them.
  ///
  /// **Counted, not quoted.** `pid_manager_screen.dart` passes
  /// `warnings.length` into `PidImportOutcome.describe(defaultedRanges:)` and
  /// nothing else reads them, so the line number and the substituted bounds
  /// each entry carries do not currently reach a reader. This comment used to
  /// say they were "surfaced to the user", which is how a reviewer comes to
  /// believe a diagnostic is doing work it is not.
  ///
  /// The per-row sentence (`pidImportRowRangeDefaulted`) is built and pinned
  /// anyway, because [PidCsvIssue] is switched over exhaustively and the arm
  /// has to exist. It is deliberately not wired into the snackbar in this
  /// slice: `PidImportOutcome.describe` is still Traditional Chinese, so
  /// appending a translated clause to it would produce a half-English
  /// snackbar — a regression that is real, traded for one that is only
  /// unrealised copy.
  final List<PidCsvDiagnostic> warnings;

  const PidCsvResult({
    required this.pids,
    required this.errors,
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;

  bool get hasWarnings => warnings.isNotEmpty;
}

abstract final class PidCsv {
  /// The column names this importer must be able to find.
  ///
  /// The rest are optional: a file without `Units` or `Priority` is still a
  /// usable set of PIDs, and Torque's own community files vary in how many
  /// trailing columns they carry.
  static final Set<String> _required = {'name', 'modeandpid', 'equation'};

  /// Column names compared without spaces or case, because the same column is
  /// written `Min Value`, `min value` and `MinValue` in files that are all
  /// otherwise fine.
  static String _key(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'[\s_]'), '');

  /// A normalised column key, spelled the way [header] spells it.
  ///
  /// Falls back to the key itself for a name that is not one of ours, which
  /// cannot happen for [_required] and is not worth a separate failure mode.
  static String _canonical(String key) =>
      header.firstWhere((h) => _key(h) == key, orElse: () => key);

  /// The same column under another tool's name.
  ///
  /// Nearly every PID file in circulation was written for Torque Pro, whose
  /// documented columns are `Name`, `ShortName`, `ModeAndPID`, `Equation`,
  /// `Min Value`, `Max Value`, `Units`, `OBD Header`. The first seven are this
  /// app's names exactly. The eighth is not, and the mismatch was silent: the
  /// file imported with no errors and every PID in it was quietly addressed to
  /// the default `7E0`.
  ///
  /// A community set for a transmission (`7E1`) or a body module (`7E2`) then
  /// asks the *engine* the transmission's question. Best case there is no
  /// answer. Worst case `7E0` answers something at that address and the gauge
  /// shows a number that looks exactly like the right one, which is the
  /// failure this whole file is arranged around.
  ///
  /// Aliases resolve *to* this app's spelling, so a column that is already
  /// named `Header` keeps precedence — a round trip through this app must not
  /// be degraded by accepting somebody else's name for the same thing.
  static const Map<String, String> _aliases = {'obdheader': 'header'};

  static const List<String> header = [
    'Name',
    'ShortName',
    'ModeAndPID',
    'Equation',
    'Min Value',
    'Max Value',
    'Units',
    'Header',
    'Priority',
    'Redline',
    'Variant',
  ];

  /// `\r\n` line endings and a BOM: this file is most often opened in Excel,
  /// which needs both to read the UTF-8 unit labels (°C, g/s) correctly.
  static final Csv _codec = Csv(lineDelimiter: '\r\n', addBom: true);

  /// A wire command: whole hex bytes, nothing else.
  static final RegExp _hexCommand = RegExp(r'^(?:[0-9A-F]{2})+$');

  /// A transmit header, at one of the three widths a bus can take: 3 hex
  /// digits for 11-bit CAN, 6 for a legacy three-byte header, 8 for 29-bit CAN.

  static String export(List<Pid> pids) {
    return _codec.encode(<List<dynamic>>[
      header,
      for (final pid in pids) pid.toCsvRow(),
    ]);
  }

  /// Emits the canonical export incrementally without a whole-file String.
  static Stream<List<int>> stream(
    Iterable<Pid> pids, {
    int maxChunkBytes = 64 * 1024,
  }) async* {
    if (maxChunkBytes <= 0) throw ArgumentError.value(maxChunkBytes);
    final rowCodec = Csv(lineDelimiter: '\r\n');
    var first = true;
    Iterable<List<dynamic>> rows() sync* {
      yield header;
      for (final pid in pids) {
        yield pid.toCsvRow();
      }
    }

    for (final row in rows()) {
      final bytes = utf8.encode(
        '${first ? '\ufeff' : '\r\n'}${rowCodec.encode([row])}',
      );
      first = false;
      for (var offset = 0; offset < bytes.length; offset += maxChunkBytes) {
        final end = (offset + maxChunkBytes).clamp(0, bytes.length);
        yield bytes.sublist(offset, end);
      }
    }
  }

  /// Parses [contents]. Tolerant by design — files in the wild come from other
  /// tools and often carry extra columns, missing headers, or a stray BOM.
  static PidCsvResult parse(String contents) {
    final pids = <Pid>[];
    final errors = <PidCsvDiagnostic>[];
    final warnings = <PidCsvDiagnostic>[];

    // Strip a UTF-8 BOM: Excel writes one, and it would otherwise become part
    // of the first column's name.
    final cleaned = contents.startsWith('﻿') ? contents.substring(1) : contents;

    final List<List<dynamic>> rows;
    try {
      rows = Csv().decode(cleaned);
    } on FormatException catch (e) {
      return PidCsvResult(
        pids: const [],
        errors: [PidCsvDiagnostic(PidCsvIssue.malformedCsv, text: e.message)],
      );
    }
    if (rows.isEmpty) {
      return const PidCsvResult(
        pids: [],
        errors: [PidCsvDiagnostic(PidCsvIssue.noRows)],
      );
    }

    var startIndex = 0;
    final first = rows.first
        .map((c) => c.toString().trim().toLowerCase())
        .toList();
    // Where each field lives. Positional by default, because a file with no
    // header row has nothing else to go on — and by *name* when there is a
    // header, which is the case this used to get wrong.
    //
    // The header row was read only to decide whether to skip it; every field
    // was then taken by index. So a file carrying exactly the right column
    // names in a different order — a spreadsheet somebody re-sorted, an export
    // from a tool that orders them differently — was misread without a word.
    // The worst arrangement is not the one that fails: it is `Units` and
    // `Header` landing where `Min Value` and `Max Value` are expected, which
    // produces a PID that polls the wrong controller and renders against wrong
    // bounds. Both of those are numbers on a gauge that look exactly like the
    // right ones.
    var columns = <String, int>{
      for (var i = 0; i < header.length; i++) _key(header[i]): i,
    };
    if (first.isNotEmpty &&
        (first.first == 'name' || first.contains('modeandpid'))) {
      startIndex = 1;
      final named = <String, int>{};
      final duplicated = <String>{};
      for (var i = 0; i < first.length; i++) {
        final key = _key(first[i]);
        if (key.isEmpty) continue;
        if (named.containsKey(key)) {
          // Reported as the file spells it, not as the comparison normalises
          // it — somebody has to find the column in a spreadsheet.
          duplicated.add(rows.first[i].toString().trim());
          continue;
        }
        named[key] = i;
      }
      // Another tool's name for a column this file did not otherwise supply.
      //
      // A second pass, and only for names still unclaimed, so this can never
      // collide with the real spelling or turn one into a duplicate of the
      // other. A file carrying both `Header` and `OBD Header` keeps `Header`,
      // because that is the one this app writes and a round trip through it
      // must not be degraded by accepting somebody else's word for the same
      // thing.
      for (final entry in _aliases.entries) {
        if (named.containsKey(entry.value)) continue;
        final at = named[entry.key];
        if (at != null) named[entry.value] = at;
      }
      // Refused, not resolved by position.
      //
      // Taking the first occurrence is a silent choice between two columns
      // that both claim to be the equation, or the header. Whichever one is
      // wrong produces a PID that computes with the wrong formula or asks the
      // wrong controller — a number on a gauge that looks exactly like the
      // right one, from a file the author believed was fine.
      if (duplicated.isNotEmpty) {
        return PidCsvResult(
          pids: const [],
          errors: [
            PidCsvDiagnostic(
              PidCsvIssue.duplicateHeaderColumns,
              columns: duplicated.toList(),
            ),
          ],
        );
      }
      final missing = _required.where((r) => !named.containsKey(r)).toList();
      if (missing.isNotEmpty) {
        return PidCsvResult(
          pids: const [],
          errors: [
            PidCsvDiagnostic(
              PidCsvIssue.missingRequiredColumns,
              // Spelled as this app spells them, not as `_key` normalises
              // them. `modeandpid` is not a column name anybody can search a
              // spreadsheet for.
              columns: missing.map(_canonical).toList(),
              requiredColumns: _required.map(_canonical).toList(),
            ),
          ],
        );
      }
      columns = named;
    }

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      final lineNumber = i + 1;
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      // Positional files have no names to look up: a short row is missing
      // cells, not empty ones. Named imports validate the mapped required
      // values instead — a three-column Name/ModeAndPID/Equation file is a
      // complete contract even though it is shorter than the legacy layout.
      if (startIndex == 0 && row.length < 4) {
        errors.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowTooFewColumns,
            lineNumber: lineNumber,
          ),
        );
        continue;
      }

      String at(int index) =>
          index >= 0 && index < row.length ? row[index].toString().trim() : '';
      String cell(int index) => at(columns[_key(header[index])] ?? -1);

      // Reject, do not repair.
      //
      // Deleting every character that is not hex turns a typo into a different,
      // perfectly valid request: `22-11O1` (letter O for zero) became `22111`,
      // and an odd length was accepted too. The row then polls an identifier
      // the author never wrote and the number is displayed with whatever bounds
      // happened to parse. Spaces are a legitimate separator; nothing else is.
      final modeAndPid = PollableServices.normalise(cell(2));
      if (!_hexCommand.hasMatch(modeAndPid) || modeAndPid.length < 4) {
        errors.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowInvalidModeAndPid,
            lineNumber: lineNumber,
            text: cell(2),
          ),
        );
        continue;
      }
      // A CSV is the easiest way to get an arbitrary command onto a car's bus,
      // and the scheduler would send it repeatedly for as long as the gauge is
      // on screen.
      final unsafe = PollableServices.rejectionReason(modeAndPid);
      if (unsafe != null) {
        errors.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowDefinitionRejected,
            lineNumber: lineNumber,
            rejection: unsafe,
          ),
        );
        continue;
      }

      final equation = cell(3);
      if (equation.isEmpty) {
        errors.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowEmptyEquation,
            lineNumber: lineNumber,
          ),
        );
        continue;
      }

      final minCell = cell(4);
      final maxCell = cell(5);
      final min = double.tryParse(minCell);
      final max = double.tryParse(maxCell);
      final headerValue = BusAddressing.normaliseHeader(cell(7));

      // The same rule the editor applies. They used to disagree: a definition
      // this importer refused could be typed in by hand and accepted, with
      // unparseable bounds quietly replaced by 0/100 — a gauge given a scale
      // nobody chose, whose needle then reads as authoritative against it.
      final rejection = PidDefinition.rejectionReason(
        name: cell(0),
        modeAndPid: PollableServices.normalise(cell(2)),
        header: headerValue,
        minText: minCell,
        maxText: maxCell,
        redlineText: cell(9),
      );
      if (rejection != null) {
        errors.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowDefinitionRejected,
            lineNumber: lineNumber,
            rejection: rejection,
          ),
        );
        continue;
      }

      // A blank bound is accepted here and refused by the editor, which is a
      // deliberate asymmetry — a spreadsheet column can legitimately be empty
      // — but the substituted 0/100 is still a scale nobody chose, and a
      // needle reads as authoritative against whatever it is drawn on. The
      // importer says so rather than letting the difference be invisible.
      if (min == null || max == null) {
        warnings.add(
          PidCsvDiagnostic(
            PidCsvIssue.rowRangeDefaulted,
            lineNumber: lineNumber,
            minValue: min ?? 0,
            maxValue: max ?? (min ?? 0) + 100,
          ),
        );
      }
      pids.add(
        Pid(
          name: cell(0).isEmpty ? modeAndPid : cell(0),
          shortName: cell(1).isEmpty ? cell(0) : cell(1),
          modeAndPid: modeAndPid,
          equation: equation,
          minValue: min ?? 0,
          maxValue: max ?? (min ?? 0) + 100,
          units: cell(6),
          header: BusAddressing.resolveHeader(headerValue),
          priority: PriorityTier.fromName(cell(8).isEmpty ? null : cell(8)),
          redlineFrom: double.tryParse(cell(9)),
          variant: cell(10).isEmpty ? null : cell(10),
          isCustom: true,
        ),
      );
    }

    if (pids.isEmpty && errors.isEmpty) {
      errors.add(const PidCsvDiagnostic(PidCsvIssue.nothingImportable));
    }
    return PidCsvResult(pids: pids, errors: errors, warnings: warnings);
  }
}
