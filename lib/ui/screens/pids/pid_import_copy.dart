/// Screen copy for what a CSV import could not do.
///
/// `lib/obd/pid/pid_csv.dart` parses files other tools wrote, and it has no
/// language: it hands out a [PidCsvDiagnostic] carrying a [PidCsvIssue] and the
/// values the sentence names — the line number, the column names, the bounds it
/// substituted, and for a refused row the [PidRejectionReason] the shared
/// definition rule produced.
///
/// A row number is data, not prose, so it arrives as an ARB placeholder rather
/// than as a prefix glued on in the engine. That also lets each language put it
/// where its own grammar wants it.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid_csv.dart';
import '../../../state/pid_mutation_lock.dart';
import '../../../state/pid_registry.dart';
import 'pid_formula_copy.dart';
import 'pid_rejection_copy.dart';

/// What [diagnostic] says, in the reader's language.
///
/// Not nullable: [PidCsvDiagnostic.issue] is not, so every value reaches a
/// sentence and a new one is a compile error in the switch below.
String pidCsvDiagnosticText(
  AppLocalizations l10n,
  PidCsvDiagnostic diagnostic,
) {
  String columns(List<String>? names) =>
      (names ?? const <String>[]).join(l10n.pidListSeparator);

  // Exhaustive, with no default arm.
  return switch (diagnostic.issue) {
    PidCsvIssue.malformedCsv => l10n.pidImportMalformedCsv(
      diagnostic.text ?? '',
    ),
    PidCsvIssue.noRows => l10n.pidImportNoRows,
    PidCsvIssue.duplicateHeaderColumns => l10n.pidImportDuplicateHeaderColumns(
      columns(diagnostic.columns),
    ),
    PidCsvIssue.missingRequiredColumns => l10n.pidImportMissingRequiredColumns(
      columns(diagnostic.columns),
      columns(diagnostic.requiredColumns),
    ),
    PidCsvIssue.rowTooFewColumns => l10n.pidImportRowTooFewColumns(
      diagnostic.lineNumber ?? 0,
    ),
    PidCsvIssue.rowInvalidModeAndPid => l10n.pidImportRowInvalidModeAndPid(
      diagnostic.lineNumber ?? 0,
      diagnostic.text ?? '',
    ),
    PidCsvIssue.rowEmptyEquation => l10n.pidImportRowEmptyEquation(
      diagnostic.lineNumber ?? 0,
    ),
    // Both halves translated. The row number belongs to the importer; the
    // reason belongs to the rule the editor applies to the same definition, so
    // it is rendered by the same function the editor renders it with.
    PidCsvIssue.rowDefinitionRejected => l10n.pidImportRowRejected(
      diagnostic.lineNumber ?? 0,
      diagnostic.rejection == null
          ? ''
          : pidRejectionText(l10n, diagnostic.rejection!),
    ),
    // **Counted in the snack, not quoted per row.** `rowRangeDefaulted` is
    // only ever a warning; the manager screen renders `errors.first` and
    // passes `warnings.length` into [pidImportOutcomeText], so the line
    // number and substituted bounds this arm formats still do not reach a
    // screen. The arm cannot be deleted: the switch is exhaustive and the
    // parser really produces the value.
    PidCsvIssue.rowRangeDefaulted => l10n.pidImportRowRangeDefaulted(
      diagnostic.lineNumber ?? 0,
      diagnostic.minValue ?? 0,
      diagnostic.maxValue ?? 0,
    ),
    PidCsvIssue.nothingImportable => l10n.pidImportNothingImportable,
    PidCsvIssue.rowFormulaRejected => l10n.pidImportRowFormulaRejected(
      diagnostic.lineNumber ?? 0,
      diagnostic.preflight == null
          ? l10n.pidFormulaUnidentified
          : formulaIssueText(l10n, diagnostic.preflight!) ??
                l10n.pidFormulaUnidentified,
    ),
  };
}

/// The snack after a CSV import, in the reader's language.
///
/// Counts are data on [PidImportOutcome]; the words used to live there too, in
/// Traditional Chinese joined with `、`, so an English import snackbar still
/// said 「已匯入 3 項自訂 PID。」 (ImL1s/telltale#45).
String pidImportOutcomeText(
  AppLocalizations l10n,
  PidImportOutcome outcome, {
  int skippedRows = 0,
  int defaultedRanges = 0,
}) {
  if (outcome.failure == PidMutationFailure.locked) {
    return l10n.telemetryBlockedByRecorder;
  }
  if (outcome.failure == PidMutationFailure.persistFailed) {
    return l10n.pidMutationPersistFailed;
  }
  final notes = [
    if (skippedRows > 0) l10n.pidImportNoteSkippedRows(skippedRows),
    if (defaultedRanges > 0) l10n.pidImportNoteDefaultedRanges(defaultedRanges),
    if (outcome.replaced > 0) l10n.pidImportNoteReplaced(outcome.replaced),
    if (outcome.duplicatesInFile.isNotEmpty)
      l10n.pidImportNoteDuplicatesInFile(outcome.duplicatesInFile.length),
  ];
  if (notes.isEmpty) {
    return l10n.pidImportLandedClean(outcome.landed);
  }
  return l10n.pidImportLandedWithNotes(
    outcome.landed,
    notes.join(l10n.pidListSeparator),
  );
}
