/// #79 leftover: the dialect document has to match the engine.
///
/// A wiki name we do not implement must stay `unsupportedConstruct`, not a
/// number. MIN/MAX are the arity-2 extension the document claims.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';

const _unsupportedWikiNames = <String>[
  'EWMAF',
  'TAVG',
  'RAVG',
  'AVG',
  'TDLY',
  'RDLY',
  'TOT',
  'INT32',
  'INT24',
  'INT16',
  'INT',
  'FLOAT64',
  'LOOKUP',
  'CLOSEST',
  'RANDOM',
];

void main() {
  final doc = File('docs/compatibility/torque-pid-dialect.md')
      .readAsStringSync();

  test(
    'the dialect document names the wiki revision it was checked against',
    () {
      expect(doc, contains('oldid=603'));
      expect(doc, contains('(A*255)+B'));
      expect(doc, contains('(A*256)+B'));
      expect(doc, contains('BARO()'));
      expect(doc, contains('not-run'));
    },
  );

  test('each documented unsupported wiki name is unsupportedConstruct', () {
    for (final name in _unsupportedWikiNames) {
      expect(doc, contains(name), reason: name);
      final failure = FormulaEngine.preflight('$name(A)');
      expect(failure, isNotNull, reason: name);
      expect(failure!.issue, FormulaIssue.unsupportedConstruct, reason: name);
      expect(failure.term, name, reason: name);
    }
    final baroCall = FormulaEngine.preflight('BARO()');
    expect(baroCall, isNotNull);
    expect(baroCall!.issue, FormulaIssue.unsupportedConstruct);
    expect(baroCall.term, 'BARO');
  });

  test('supported wiki-shaped functions are not unsupportedConstruct', () {
    expect(FormulaEngine.preflight('ABS(A)'), isNull);
    expect(FormulaEngine.preflight('LOG10(A)'), isNull);
    expect(FormulaEngine.preflight('LOG(A)'), isNull);
    expect(FormulaEngine.preflight('SQRT(A)'), isNull);
    expect(FormulaEngine.preflight('SIGNED(A)'), isNull);
    expect(FormulaEngine.preflight('MIN(A:B)'), isNull);
    expect(FormulaEngine.preflight('MAX(A:B)'), isNull);
    expect(FormulaEngine.preflight('BIT(A:0)'), isNull);
    expect(FormulaEngine.preflight('SIN(A)'), isNull);
    expect(FormulaEngine.preflight('COS(A)'), isNull);
    expect(FormulaEngine.preflight('TAN(A)'), isNull);
    expect(FormulaEngine.preflight('LOG1P(A)'), isNull);
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
    expect(FormulaEngine.preflight('MIN((A+1):B)'), isNull);
    expect(FormulaEngine.preflight('A-BARO'), isNull);
  });

  test('INT16 is refused rather than evaluated as (A*255)+B or (A*256)+B', () {
    final failure = FormulaEngine.preflight('INT16(A:B)');
    expect(failure!.issue, FormulaIssue.unsupportedConstruct);
    expect(failure.term, 'INT16');
    expect(FormulaEngine().evaluateBytes('(A*256)+B', const [1, 2]), 258);
    expect(FormulaEngine().evaluateBytes('(A*255)+B', const [1, 2]), 257);
  });
}
