/// Screen copy for the formula evaluator's refusals.
///
/// `lib/obd/pid/formula_engine.dart` is pure Dart with no Flutter in it, and it
/// evaluates arithmetic rather than describing it: what it hands out is a
/// [FormulaIssue] plus the values the sentence names — the byte letter, the
/// referenced PID, the argument that was out of domain. The words are here, one
/// ARB entry per identifier, with those values as placeholders.
///
/// It takes an [AppLocalizations] rather than a [BuildContext], for the same
/// reason `dtc_copy.dart` and `datum_status_copy.dart` do: a pure-Dart test can
/// then walk every arm in both locales with no widget pump, and nothing is
/// tempted to reach for a global context.
///
/// What deliberately does NOT live here is [FormulaException.message]. That
/// string is still Traditional Chinese and stays that way on purpose: it is
/// what `FormulaEngine.validate` returns into the powertrain-battery catalogue
/// validator, and what `powertrain_battery_probe.dart` stringifies into a probe
/// transcript. Both are diagnostics written for a file, not sentences for a
/// person on a phone.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/formula_engine.dart';

/// Why [exception] could not be evaluated, in the reader's language.
///
/// Null when the exception carries no identifier. That cannot happen from
/// anything in this tree — `test/l10n/pid_reason_guard_test.dart` reads the
/// source and refuses a throw that settles for `issue: null` — and the type
/// still allows it, so the caller has to decide. The editor maps null to
/// [AppLocalizations.pidFormulaUnidentified] rather than the engine's
/// Traditional Chinese sentence.
String? formulaIssueText(AppLocalizations l10n, FormulaException exception) {
  final issue = exception.issue;
  if (issue == null) return null;
  // Exhaustive with no default arm, so a new FormulaIssue is a compile error
  // here rather than a silent gap on the screen.
  return switch (issue) {
    FormulaIssue.emptyFormula => l10n.pidFormulaEmpty,
    FormulaIssue.emptySubExpression => l10n.pidFormulaEmptySubExpression,
    FormulaIssue.unbalancedParentheses => l10n.pidFormulaUnbalancedParentheses,
    FormulaIssue.unparsableTerm => l10n.pidFormulaUnparsableTerm(
      exception.term ?? exception.source,
    ),
    FormulaIssue.functionNestingTooDeep =>
      l10n.pidFormulaFunctionNestingTooDeep,
    FormulaIssue.parenthesisNestingTooDeep =>
      l10n.pidFormulaParenthesisNestingTooDeep,
    FormulaIssue.divisionByZero => l10n.pidFormulaDivisionByZero,
    FormulaIssue.moduloByZero => l10n.pidFormulaModuloByZero,
    FormulaIssue.log10NonPositiveArgument =>
      l10n.pidFormulaLog10NonPositiveArgument(exception.argument ?? 0),
    FormulaIssue.logNonPositiveArgument =>
      l10n.pidFormulaLogNonPositiveArgument(exception.argument ?? 0),
    FormulaIssue.sqrtNegativeArgument => l10n.pidFormulaSqrtNegativeArgument(
      exception.argument ?? 0,
    ),
    FormulaIssue.resultNotFinite => l10n.pidFormulaResultNotFinite,
    FormulaIssue.byteBeyondResponse => l10n.pidFormulaByteBeyondResponse(
      exception.byteLetter ?? '',
      exception.byteCount ?? 0,
    ),
    FormulaIssue.baroControllerUnknown => l10n.pidFormulaBaroControllerUnknown,
    FormulaIssue.baroTwoDefinitions => l10n.pidFormulaBaroTwoDefinitions,
    FormulaIssue.baroNotYetMeasured => l10n.pidFormulaBaroNotYetMeasured,
    FormulaIssue.baroMeasurementStale => l10n.pidFormulaBaroMeasurementStale,
    FormulaIssue.baroParenFormUnsupported =>
      l10n.pidFormulaBaroParenFormUnsupported,
    FormulaIssue.int16Unclaimed => l10n.pidFormulaInt16Unclaimed,
    // The whole `VAL{...}` token, composed here rather than in the ARB: braces
    // are placeholder syntax there, and this is formula syntax that has to stay
    // byte-identical in both languages. Same reason `pidEditorEquationHelper`
    // is handed its `VAL{PID}` from the screen.
    FormulaIssue.dependencyControllerUnknown =>
      l10n.pidFormulaDependencyControllerUnknown(
        'VAL{${exception.pidKey ?? ''}}',
      ),
    FormulaIssue.dependencyTwoDefinitions =>
      l10n.pidFormulaDependencyTwoDefinitions(exception.pidKey ?? ''),
    FormulaIssue.dependencyNotYetMeasured =>
      l10n.pidFormulaDependencyNotYetMeasured(exception.pidKey ?? ''),
    FormulaIssue.unsupportedConstruct => l10n.pidFormulaUnsupportedConstruct(
      exception.term ?? exception.source,
    ),
  };
}
