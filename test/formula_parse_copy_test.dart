import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';

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

  test('leftover parse interpolations are Traditional Chinese', () {
    expect(
      thrownBy(() => engine.evaluateBytes(' ', const [])).message,
      '公式是空的',
    );
    expect(
      thrownBy(() => engine.evaluateBytes('2LOG(1)', const [])).message,
      contains('無法解析'),
    );
    expect(
      thrownBy(() => engine.evaluateBytes('(', const [])).message,
      '括號沒有配對',
    );
    expect(
      thrownBy(() => engine.evaluateBytes('A*', const [1])).message,
      '子運算式是空的',
    );
  });

  test('formula_engine.dart has no leftover English parse sentences', () {
    final code = File('lib/obd/pid/formula_engine.dart').readAsStringSync();
    expect(code.contains('Formula is empty'), isFalse);
    expect(code.contains('Cannot parse'), isFalse);
    expect(code.contains('Empty sub-expression'), isFalse);
    expect(code.contains('Unbalanced parentheses'), isFalse);
    expect(code.contains('Formula nests functions too deeply'), isFalse);
    expect(code.contains('Formula nests parentheses too deeply'), isFalse);
  });
}
