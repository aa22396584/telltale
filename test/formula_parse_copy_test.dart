import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';

import 'support/cjk.dart';

void main() {
  late FormulaEngine engine;

  setUp(() => engine = FormulaEngine());

  FormulaException thrownBy(void Function() body) {
    try {
      body();
    } on FormulaException catch (e) {
      return e;
    }
    fail('expected a FormulaException');
  }

  test('leftover parse interpolations are English transcript', () {
    // The screen maps FormulaIssue; these sentences are the transcript.
    // They used to be Traditional Chinese, so an English editor that fell
    // through to FormulaException.message showed 公式是空的.
    final empty = thrownBy(() => engine.evaluateBytes(' ', const []));
    expect(empty.message, 'Formula is empty');
    expect(empty.issue, FormulaIssue.emptyFormula);
    expect(chinese.hasMatch(empty.message), isFalse);

    final unparsable = thrownBy(() => engine.evaluateBytes('2LOG(1)', const []));
    expect(unparsable.message, contains('Cannot parse'));
    expect(unparsable.issue, FormulaIssue.unparsableTerm);
    expect(chinese.hasMatch(unparsable.message), isFalse);

    final parens = thrownBy(() => engine.evaluateBytes('(', const []));
    expect(parens.message, 'Unbalanced parentheses');
    expect(parens.issue, FormulaIssue.unbalancedParentheses);
    expect(chinese.hasMatch(parens.message), isFalse);

    final emptySub = thrownBy(() => engine.evaluateBytes('A*', const [1]));
    expect(emptySub.message, 'Empty sub-expression');
    expect(emptySub.issue, FormulaIssue.emptySubExpression);
    expect(chinese.hasMatch(emptySub.message), isFalse);
  });

  test('formula_engine.dart has no leftover Chinese parse sentences', () {
    final code = File('lib/obd/pid/formula_engine.dart').readAsStringSync();
    expect(code.contains('公式是空的'), isFalse);
    expect(code.contains('無法解析'), isFalse);
    expect(code.contains('括號沒有配對'), isFalse);
    expect(code.contains('子運算式是空的'), isFalse);
  });
}
