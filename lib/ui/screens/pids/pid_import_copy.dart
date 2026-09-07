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
    // **Reaches no reader today, and that is a deliberate hold rather than an
    // oversight.** `rowRangeDefaulted` is only ever a warning;
    // `lib/ui/screens/pids/pid_manager_screen.dart` renders `errors.first` and
    // passes `warnings.length` into `PidImportOutcome.describe`, so the line
    // number and the substituted bounds this arm formats never reach a screen.
    //
    // The arm cannot simply be deleted: the switch is exhaustive with no
    // default, and `PidCsvIssue.rowRangeDefaulted` is a value the parser
    // really produces (`test/pid_csv_test.dart` drives it). Wiring it in is
    // the other option and is worse *in this slice*: `PidImportOutcome.describe`
    // is still Traditional Chinese, so appending a translated per-row clause
    // to it ships a half-English snackbar — a regression that is real, traded
    // for one that is only unrealised copy. Both halves move together, in the
    // slice that translates `describe`.
    PidCsvIssue.rowRangeDefaulted => l10n.pidImportRowRangeDefaulted(
      diagnostic.lineNumber ?? 0,
      diagnostic.minValue ?? 0,
      diagnostic.maxValue ?? 0,
    ),
    PidCsvIssue.nothingImportable => l10n.pidImportNothingImportable,
  };
}
