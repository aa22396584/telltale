/// #79.B leftover: one formula preflight for editor and CSV import.
///
/// A Torque wiki function this dialect does not implement is not a typo, and
/// a syntactically valid `VAL{}` / `BARO` formula is not unsupported just
/// because there is no live reading yet.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';
import 'package:torque_obd/obd/pid/pid_csv.dart';

void main() {
  test('ABS, VAL and BARO without parentheses still preflight', () {
    expect(FormulaEngine.preflight('ABS(A)'), isNull);
    expect(FormulaEngine.preflight('A-VAL{010C}'), isNull);
    expect(FormulaEngine.preflight('A-BARO'), isNull);
    expect(FormulaEngine.preflight('((A*256)+B)/4'), isNull);
    expect(FormulaEngine.preflight('MIN(A:B)'), isNull);
    expect(FormulaEngine.preflight('MAX(A,B)'), isNull);
    expect(FormulaEngine.preflight('MIN((A+1):B)'), isNull);
    expect(FormulaEngine.preflight('MAX(A:(B*2))'), isNull);
    expect(FormulaEngine.preflight('SQRT(A)'), isNull);
    expect(FormulaEngine.preflight('LOG(A)'), isNull);
    expect(FormulaEngine.preflight('BIT(A:0)'), isNull);
    expect(FormulaEngine.preflight('SIN(A)'), isNull);
    expect(FormulaEngine.preflight('COS(A)'), isNull);
    expect(FormulaEngine.preflight('TAN(A)'), isNull);
    expect(FormulaEngine.preflight('LOG1P(A)'), isNull);
    expect(FormulaEngine.preflight('LOG1P((A-1))'), isNull);
    expect(FormulaEngine.preflight('SIGNED16(A)'), isNull);
    expect(FormulaEngine.preflight('SIGNED16((A*256)+B)'), isNull);
    expect(FormulaEngine.preflight('SIGNED8(A)'), isNull);
    expect(FormulaEngine.preflight('SIGNED8((A-1))'), isNull);
    expect(FormulaEngine.preflight('SIGNED24(A)'), isNull);
    expect(FormulaEngine.preflight('SIGNED24((A-1))'), isNull);
    expect(FormulaEngine.preflight('SIGNED32(A)'), isNull);
    expect(FormulaEngine.preflight('SIGNED32((A-1))'), isNull);
    expect(FormulaEngine.preflight('FLOAT32(A:B:C:D)'), isNull);
    expect(FormulaEngine.preflight('FLOAT32((A-1):B:C:D)'), isNull);
    expect(FormulaEngine.preflight('INT(A)'), isNull);
    expect(FormulaEngine.preflight('INT((A-1))'), isNull);
    expect(FormulaEngine.preflight('FLOAT64(A:B:C:D:E:F:G:H)'), isNull);
    expect(FormulaEngine.preflight('FLOAT64((A-1):B:C:D:E:F:G:H)'), isNull);
    expect(FormulaEngine.preflight('INT24(A:B:C)'), isNull);
    expect(FormulaEngine.preflight('INT24((A-1):B:C)'), isNull);
    expect(FormulaEngine.preflight('INT32(A:B:C:D)'), isNull);
    expect(FormulaEngine.preflight('INT32((A-1):B:C:D)'), isNull);
    expect(FormulaEngine.preflight('RANDOM()'), isNull);
    expect(FormulaEngine.preflight('LOOKUP(A:0:1=100)'), isNull);
    expect(FormulaEngine.preflight('LOOKUP(A::0~3=4)'), isNull);
    expect(FormulaEngine.preflight('LOOKUP((A-1):0:0=50)'), isNull);
  });

  test('named Torque wiki functions are unsupportedConstruct, not a typo', () {
    for (final equation in [
      'INT16(A:B)',
      'CLOSEST(A:A:1=0)',
      'BARO()',
    ]) {
      final failure = FormulaEngine.preflight(equation);
      expect(failure, isNotNull, reason: equation);
      expect(
        failure!.issue,
        FormulaIssue.unsupportedConstruct,
        reason: equation,
      );
      expect(failure.term, isNotEmpty, reason: equation);
      expect(failure.term, isNot('ABS'), reason: equation);
      expect(failure.term, isNot('LOG10'), reason: equation);
    }
  });

  test('LOG10 is not classified as LOG', () {
    expect(FormulaEngine.preflight('LOG10(A)'), isNull);
  });

  test('RANDOM() authoring uses a stand-in, not live entropy', () {
    expect(FormulaEngine.preflight('RANDOM()'), isNull);
    for (var i = 0; i < 20; i++) {
      expect(
        FormulaEngine.preflight('LOG10(RANDOM()-0.99)'),
        isNotNull,
        reason: 'a domain that fails at the 0.5 stand-in is not saveable',
      );
    }
  });

  test('SIGNED is not classified as SIGNED8', () {
    expect(FormulaEngine.preflight('SIGNED(A)'), isNull);
  });

  test('an unknown fragment is unparsableTerm, not unsupportedConstruct', () {
    final failure = FormulaEngine.preflight('FOOZ(A)');
    expect(failure, isNotNull);
    expect(failure!.issue, FormulaIssue.unparsableTerm);
  });

  test('CSV import refuses an unsupported formula and keeps a sound one', () {
    const wire =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
        'Boost,BST,010B,A-BARO,0,300,kPa,7E0\r\n'
        'Clip,CLP,010C,MIN(A:B),0,255,,7E0\r\n'
        'Closest,CLS,010D,CLOSEST(A:A:1=0),0,8000,rpm,7E0\r\n';
    final result = PidCsv.parse(wire);
    expect(result.pids, hasLength(2));
    expect(result.pids.map((p) => p.equation), ['A-BARO', 'MIN(A:B)']);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.issue, PidCsvIssue.rowFormulaRejected);
    expect(result.errors.single.lineNumber, 4);
    expect(
      result.errors.single.preflight!.issue,
      FormulaIssue.unsupportedConstruct,
    );
    expect(result.errors.single.preflight!.term, 'CLOSEST');
  });

  test('a missing live VAL reading is not an import syntax error', () {
    const wire =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
        'Boost,BST,010B,A-VAL{0133},0,300,kPa,7E0\r\n';
    final result = PidCsv.parse(wire);
    expect(result.errors, isEmpty, reason: '${result.errors}');
    expect(result.pids, hasLength(1));
  });

  test('a formula that is always out of domain is still rejected', () {
    expect(FormulaEngine.preflight('A/0')?.issue, FormulaIssue.divisionByZero);
    expect(FormulaEngine.preflight('A%0')?.issue, FormulaIssue.moduloByZero);
    expect(
      FormulaEngine.preflight('LOG10(-1)')?.issue,
      FormulaIssue.log10NonPositiveArgument,
    );
    expect(
      FormulaEngine.preflight('LOG(-1)')?.issue,
      FormulaIssue.logNonPositiveArgument,
    );
    expect(
      FormulaEngine.preflight('SQRT(-1)')?.issue,
      FormulaIssue.sqrtNegativeArgument,
    );
  });

  test('a probe-value domain error is not an import syntax error', () {
    // Probe bytes are all 1. `1/(A-1)` is defined for every other A.
    expect(FormulaEngine.preflight('1/(A-1)'), isNull);
    expect(FormulaEngine.preflight('LOG10(A-1)'), isNull);
    expect(FormulaEngine.preflight('1/(A-B)'), isNull);
    expect(FormulaEngine.preflight('LOG10(A-B)'), isNull);
    expect(FormulaEngine.preflight('LOG(A-2)'), isNull);
    expect(FormulaEngine.preflight('SQRT(A-2)'), isNull);
    expect(FormulaEngine.preflight('1/(VAL{010C}-1)'), isNull);
    // Probe bytes are 1, 2, 1..14 and 14..1. `LOG10(A-20)` is negative at
    // every one of those. That is a runtime domain, not import syntax.
    // Do not "fix" it by adding A=21 as another stand-in.
    expect(FormulaEngine.preflight('LOG10(A-20)'), isNull);
    expect(FormulaEngine.preflight('SQRT(A-20)'), isNull);
    // A reply-byte token elsewhere does not save a constant-invalid term.
    expect(
      FormulaEngine.preflight('LOG10(-1)+A')?.issue,
      FormulaIssue.log10NonPositiveArgument,
    );
    expect(
      FormulaEngine.preflight('SQRT(-1)+A')?.issue,
      FormulaIssue.sqrtNegativeArgument,
    );
    const wire =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
        'Inv,INV,010C,1/(A-1),0,100,,7E0\r\n';
    final result = PidCsv.parse(wire);
    expect(result.errors, isEmpty, reason: '${result.errors}');
    expect(result.pids, hasLength(1));
    expect(result.pids.single.equation, '1/(A-1)');
    const logWire =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
        'Shift,SH,010C,LOG10(A-20),0,3,,7E0\r\n';
    final logResult = PidCsv.parse(logWire);
    expect(logResult.errors, isEmpty, reason: '${logResult.errors}');
    expect(logResult.pids.single.equation, 'LOG10(A-20)');
  });

  test('an unexpected evaluator Error is contained, not thrown', () {
    expect(() => FormulaEngine.preflight('~1e999'), returnsNormally);
    final failure = FormulaEngine.preflight('~1e999');
    expect(failure, isNotNull);
    expect(failure!.issue, isNot(FormulaIssue.unsupportedConstruct));
    const wire =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
        'Boom,B,010C,~1e999,0,1,,7E0\r\n';
    expect(() => PidCsv.parse(wire), returnsNormally);
    final result = PidCsv.parse(wire);
    expect(result.pids, isEmpty);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.issue, PidCsvIssue.rowFormulaRejected);
  });
}
