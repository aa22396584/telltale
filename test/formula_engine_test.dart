import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';
import 'package:torque_obd/obd/pid/pid.dart';

void main() {
  late FormulaEngine engine;

  setUp(() => engine = FormulaEngine());

  group('payload byte extraction', () {
    test('strips the Mode 01 positive-response prefix when asked', () {
      expect(
        FormulaEngine.parseUserTypedSampleBytes(
          '41 0C 1A F0',
          stripResponsePrefix: true,
        ),
        [0x1A, 0xF0],
      );
    });

    test('strips the wider Mode 22 prefix when asked', () {
      expect(
        FormulaEngine.parseUserTypedSampleBytes(
          '62 1E 1C 02 80',
          stripResponsePrefix: true,
        ),
        [0x02, 0x80],
      );
    });

    test('passes through a payload that carries no prefix', () {
      expect(FormulaEngine.parseUserTypedSampleBytes('1AF0'), [0x1A, 0xF0]);
    });

    test('refuses ELM prose instead of turning it into plausible bytes', () {
      FormulaException dataError() {
        try {
          FormulaEngine.parseUserTypedSampleBytes('DATA ERROR');
        } on FormulaException catch (e) {
          return e;
        }
        throw StateError('DATA ERROR must not parse');
      }

      expect(dataError().issue, FormulaIssue.unparsableTerm);
      expect(dataError().term, 'DATA ERROR');
      expect(
        () => FormulaEngine.parseUserTypedSampleBytes('CAN ERROR'),
        throwsA(isA<FormulaException>()),
      );
      expect(
        () => FormulaEngine.parseUserTypedSampleBytes('BUS INIT: ERROR'),
        throwsA(isA<FormulaException>()),
      );
    });

    test('a 0x41 data byte is kept unless prefix stripping is requested', () {
      expect(
        FormulaEngine.parseUserTypedSampleBytes('41 0C 1A F0'),
        [0x41, 0x0C, 0x1A, 0xF0],
      );
      expect(
        FormulaEngine.parseUserTypedSampleBytes(
          '41 0C 1A F0',
          stripResponsePrefix: true,
        ),
        [0x1A, 0xF0],
      );
    });

    test('nothing under lib/obd/ calls the string-taking evaluator', () {
      // The only route from a response line into the blacklist strip above.
      // Live polling calls `evaluateBytes` with bytes the whitelist in
      // `Elm327Client._hexLine` already accepted; the string overload exists
      // for the editor's authoring preview and must stay there.
      //
      // A source-level check rather than a behavioural one, because the defect
      // being guarded against is a future call site, not a wrong answer from an
      // existing one — and by the time it returns a wrong answer it looks like
      // a reading.
      final root = Directory('lib/obd');
      expect(root.existsSync(), isTrue,
          reason: 'run from the app/ directory, where lib/obd/ is');
      final offenders = <String>[];
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('.evaluate(')) {
            offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'a string reaching FormulaEngine.evaluate from the OBD layer '
              'is adapter output, and it would be stripped by blacklist');
    });
  });

  group('reference cases ported from examples/dart', () {
    test('coolant temperature: A-40', () {
      expect(engine.evaluate('A-40', '41 05 50'), closeTo(40.0, 1e-6));
    });

    test('engine RPM: ((A*256)+B)/4', () {
      expect(engine.evaluate('((A*256)+B)/4', '41 0C 1A F0'), closeTo(1724.0, 1e-6));
    });

    test('signed byte conversion', () {
      expect(engine.evaluate('SIGNED(A)*1.5', '41 00 FE'), closeTo(-3.0, 1e-6));
    });

    test('ABS()', () {
      expect(engine.evaluate('ABS(A-100)', '41 00 20'), closeTo(68.0, 1e-6));
    });

    test('LOG10()', () {
      expect(engine.evaluate('LOG10(A)', '41 00 64'), closeTo(2.0, 1e-6));
    });

    test('LOG() is a complete token, not a substring', () {
      FormulaException thrownBy(void Function() body) {
        try {
          body();
        } on FormulaException catch (e) {
          return e;
        }
        fail('expected a FormulaException');
      }

      // `2LOG(1)` must not become 20. That is a confident wrong number.
      expect(
        thrownBy(() => engine.evaluateBytes('2LOG(1)', const [])).issue,
        FormulaIssue.unparsableTerm,
      );
      expect(
        thrownBy(() => engine.evaluateBytes('BLOG(A)', const [1, 2])).issue,
        FormulaIssue.unparsableTerm,
      );
      expect(engine.evaluateBytes('2*LOG(1)', const []), closeTo(0.0, 1e-9));
      // `LOG(1)A` with A=5 must not become 0.05.
      expect(
        thrownBy(() => engine.evaluateBytes('LOG(1)A', const [5])).issue,
        FormulaIssue.unparsableTerm,
      );
      expect(engine.evaluateBytes('LOG(1)*A', const [5]), closeTo(0.0, 1e-9));
    });

    test('LOG() is natural log, not LOG10', () {
      expect(engine.evaluateBytes('LOG(1)', const []), closeTo(0.0, 1e-9));
      expect(engine.evaluateBytes('LOG(A)', const [10]), closeTo(math.log(10), 1e-9));
      expect(
        engine.evaluateBytes('ABS(LOG(A))', const [10]),
        closeTo(math.log(10), 1e-9),
      );
      expect(
        engine.evaluateBytes('LOG10(LOG(A))', const [100]),
        closeTo(math.log(math.log(100)) / math.ln10, 1e-9),
      );
      // ln(100) is not 2. Answering LOG10 here is a confident wrong number.
      expect(engine.evaluateBytes('LOG(A)', const [100]), isNot(closeTo(2.0, 0.1)));
      expect(engine.evaluateBytes('LOG10(A)', const [100]), closeTo(2.0, 1e-6));
    });

    test('SQRT()', () {
      expect(engine.evaluateBytes('SQRT(A)', const [16]), closeTo(4.0, 1e-9));
      expect(engine.evaluateBytes('SQRT(0)', const []), closeTo(0.0, 1e-9));
      expect(
        engine.evaluateBytes('ABS(SQRT(A))', const [9]),
        closeTo(3.0, 1e-9),
      );
    });

    test('SIN COS TAN are radians, not degrees', () {
      expect(engine.evaluateBytes('SIN(0)', const []), closeTo(0.0, 1e-9));
      expect(engine.evaluateBytes('COS(0)', const []), closeTo(1.0, 1e-9));
      expect(engine.evaluateBytes('TAN(0)', const []), closeTo(0.0, 1e-9));
      expect(
        engine.evaluateBytes('SIN(A)', const [0]),
        closeTo(0.0, 1e-9),
      );
      // 90 as degrees would be 1. Radians of 90 is not 1.
      expect(engine.evaluateBytes('SIN(90)', const []), isNot(closeTo(1.0, 0.1)));
      expect(
        engine.evaluateBytes('COS(SIN(0))', const []),
        closeTo(1.0, 1e-9),
      );
      FormulaException thrownBy(void Function() body) {
        try {
          body();
        } on FormulaException catch (e) {
          return e;
        }
        fail('expected a FormulaException');
      }

      expect(
        thrownBy(() => engine.evaluateBytes('2SIN(0)', const [])).issue,
        FormulaIssue.unparsableTerm,
      );
      expect(
        thrownBy(() => engine.evaluateBytes('SIN(0)A', const [5])).issue,
        FormulaIssue.unparsableTerm,
      );
    });

    test('BIT() returns the named bit, not a plausible 0', () {
      expect(engine.evaluateBytes('BIT(A:0)', const [5]), closeTo(1.0, 1e-9));
      expect(engine.evaluateBytes('BIT(A:1)', const [5]), closeTo(0.0, 1e-9));
      expect(engine.evaluateBytes('BIT(A:2)', const [5]), closeTo(1.0, 1e-9));
      expect(engine.evaluateBytes('BIT(A,0)', const [5]), closeTo(1.0, 1e-9));
      FormulaException thrownBy(void Function() body) {
        try {
          body();
        } on FormulaException catch (e) {
          return e;
        }
        fail('expected a FormulaException');
      }

      expect(
        thrownBy(() => engine.evaluateBytes('BIT(A:-1)', const [5])).issue,
        FormulaIssue.unparsableTerm,
      );
      expect(
        thrownBy(
          () => engine.evaluateBytes('BIT(A^B:0)', const [255, 255]),
        ).issue,
        FormulaIssue.resultNotFinite,
      );
    });

    test('MIN() and MAX() take the wiki colon form', () {
      expect(engine.evaluateBytes('MIN(A:B)', const [20, 5]), closeTo(5.0, 1e-9));
      expect(engine.evaluateBytes('MAX(A:B)', const [20, 5]), closeTo(20.0, 1e-9));
      expect(engine.evaluateBytes('MAX(A,B)', const [20, 5]), closeTo(20.0, 1e-9));
      expect(engine.evaluateBytes('min(A:B)', const [20, 5]), closeTo(5.0, 1e-9));
    });

    test('VAL{} external PID reference', () {
      // A VAL{} reference now resolves against the *asking* controller, so the
      // seed and the requester have to be on the same one. Keying by bare hex
      // let a formula on the ECM consume a value the TCM measured.
      final now = DateTime(2026, 8, 15);
      final requester = FormulaEngine.probePid('0000');
      engine.cachePidValue(FormulaEngine.probePid('010D'), 100.0, now);
      expect(
        engine.evaluate(
          'VAL{010D}*0.621371',
          '41 00',
          requester: requester,
          now: now,
        ),
        closeTo(62.1371, 1e-4),
      );
    });
  });

  group('operator handling', () {
    test('respects precedence without parentheses', () {
      // 2 + 3 * 4 must be 14, not 20.
      expect(engine.evaluateBytes('2+3*4', const []), closeTo(14.0, 1e-9));
    });

    test('subtraction associates left to right', () {
      // A regression guard: splitting on the first '-' instead of the last
      // would yield 10 - (5 - 2) = 7.
      expect(engine.evaluateBytes('10-5-2', const []), closeTo(3.0, 1e-9));
    });

    test('division associates left to right', () {
      expect(engine.evaluateBytes('100/5/2', const []), closeTo(10.0, 1e-9));
    });

    test('handles a leading unary minus', () {
      expect(engine.evaluateBytes('-5+8', const []), closeTo(3.0, 1e-9));
    });

    test('does not mistake a unary minus for subtraction', () {
      expect(engine.evaluateBytes('3*-2', const []), closeTo(-6.0, 1e-9));
    });

    test('exponentiation', () {
      expect(engine.evaluateBytes('2^10', const []), closeTo(1024.0, 1e-9));
    });

    test('bitwise and / or', () {
      expect(engine.evaluateBytes('12&10', const []), closeTo(8.0, 1e-9));
      expect(engine.evaluateBytes('12|3', const []), closeTo(15.0, 1e-9));
    });

    test('relational operators yield 1 or 0', () {
      expect(engine.evaluateBytes('5>3', const []), closeTo(1.0, 1e-9));
      expect(engine.evaluateBytes('5<3', const []), closeTo(0.0, 1e-9));
      expect(engine.evaluateBytes('5==5', const []), closeTo(1.0, 1e-9));
    });

    test('division by zero is an error, not zero', () {
      // Returning 0 would put a plausible number on a gauge for a calculation
      // that could not be performed.
      expect(
        () => engine.evaluateBytes('10/0', const []),
        throwsA(isA<FormulaException>()),
      );
      expect(
        () => engine.evaluateBytes('10%0', const []),
        throwsA(isA<FormulaException>()),
      );
    });

    test('exponentiation is right-associative', () {
      // 2^3^2 is 2^(3^2) = 512, not (2^3)^2 = 64.
      expect(engine.evaluateBytes('2^3^2', const []), closeTo(512.0, 1e-9));
    });

    test('modulo shares precedence with multiply and divide', () {
      // Treating % as its own tighter level makes this A/(B%C) = 100/2 = 50.
      expect(engine.evaluateBytes('A/B%C', const [100, 7, 5]), closeTo(4.285714, 1e-5));
    });

    test('multiply and modulo associate left to right', () {
      expect(engine.evaluateBytes('20%7*3', const []), closeTo(18.0, 1e-9));
    });

    test('a unary minus binds looser than exponentiation', () {
      // -A^2 is -(A^2). Splitting on ^ first would take -3 as the base and
      // give +9.
      expect(engine.evaluateBytes('-A^2', const [3]), closeTo(-9.0, 1e-9));
    });

    test('a negated power still combines correctly with addition', () {
      expect(engine.evaluateBytes('-A^2+1', const [3]), closeTo(-8.0, 1e-9));
    });

    test('exponentiation of an explicitly bracketed negative', () {
      expect(engine.evaluateBytes('(-A)^2', const [3]), closeTo(9.0, 1e-9));
    });

    test('two-character relational operators', () {
      expect(engine.evaluateBytes('5>=5', const []), 1.0);
      expect(engine.evaluateBytes('5<=4', const []), 0.0);
      expect(engine.evaluateBytes('5!=4', const []), 1.0);
      expect(engine.evaluateBytes('5!=5', const []), 0.0);
    });

    test('>= is not mis-split as > followed by =', () {
      expect(engine.evaluateBytes('A>=B', const [3, 9]), 0.0);
      expect(engine.evaluateBytes('A>=B', const [9, 3]), 1.0);
    });
  });

  group('variable binding', () {
    test('binds A..N positionally', () {
      expect(engine.evaluateBytes('A+B+C+D', const [1, 2, 3, 4]), closeTo(10.0, 1e-9));
    });

    test('a formula referencing a byte the ECU did not send is an error', () {
      // Substituting zero here would turn a truncated reply into a confident
      // wrong reading rather than a visible fault.
      expect(
        () => engine.evaluateBytes('A+B+C', const [5]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('a truncated RPM reply fails instead of reading low', () {
      // ((A*256)+B)/4 with B missing would silently report 1664 rpm when the
      // real value was 1724.
      expect(
        () => engine.evaluateBytes('((A*256)+B)/4', const [0x1A]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('function names survive variable substitution', () {
      // The 'A' in ABS and the letters in LOG10 must not be replaced by byte
      // values — the sentinel shielding exists for exactly this.
      expect(engine.evaluateBytes('ABS(A-10)', const [3]), closeTo(7.0, 1e-9));
      expect(engine.evaluateBytes('LOG10(A)', const [100]), closeTo(2.0, 1e-9));
    });

    test('nested functions reduce innermost first', () {
      expect(engine.evaluateBytes('ABS(ABS(A)-20)', const [5]), closeTo(15.0, 1e-9));
      expect(
        engine.evaluateBytes('ABS(MIN(A:B))', const [3, 9]),
        closeTo(3.0, 1e-9),
      );
      expect(
        engine.evaluateBytes('MIN(ABS(A-10):B)', const [3, 9]),
        closeTo(7.0, 1e-9),
      );
    });

    test('MIN and MAX names survive variable substitution', () {
      expect(engine.evaluateBytes('MIN(A:B)', const [1, 2]), closeTo(1.0, 1e-9));
      expect(engine.evaluateBytes('MAX(A:B)', const [1, 2]), closeTo(2.0, 1e-9));
    });

    test('MIN/MAX arguments may be grouped', () {
      // Codex P2: `[^()]+` could not see `MIN((A+1):B)` / `MAX(A:(B*2))`.
      expect(
        engine.evaluateBytes('MIN((A+1):B)', const [3, 9]),
        closeTo(4.0, 1e-9),
      );
      expect(
        engine.evaluateBytes('MAX(A:(B*2))', const [3, 9]),
        closeTo(18.0, 1e-9),
      );
      expect(
        engine.evaluateBytes('MIN((A-10):(B+1))', const [3, 9]),
        closeTo(-7.0, 1e-9),
      );
      expect(FormulaEngine.preflight('MIN((A+1):B)'), isNull);
      expect(FormulaEngine.preflight('MAX(A:(B*2))'), isNull);
    });

    test('MIN/MAX require a token boundary, not a substring', () {
      // `1MIN(2:3)` used to reduce to 12: the matcher ate MIN(2:3) and
      // concatenated the replacement onto the leading 1. A plausible number
      // from a malformed import.
      expect(
        () => engine.evaluateBytes('1MIN(2:3)', const []),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
      expect(
        () => engine.evaluateBytes('AMIN(B:C)', const [4, 5, 6]),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
      expect(FormulaEngine.preflight('1MIN(2:3)'), isNotNull);
      expect(
        () => engine.evaluateBytes('MIN(1:2)3', const []),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
      expect(
        () => engine.evaluateBytes('MIN(A:B)C', const [4, 5, 6]),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
    });

    test('MIN/MAX with the wrong arity is unparsable, not a number', () {
      expect(
        () => engine.evaluateBytes('MIN(A)', const [4]),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
      expect(
        () => engine.evaluateBytes('MIN(A:B:C)', const [1, 2, 3]),
        throwsA(
          isA<FormulaException>().having(
            (e) => e.issue,
            'issue',
            FormulaIssue.unparsableTerm,
          ),
        ),
      );
    });

    test('BARO injects the ambient pressure', () {
      // Scoped to a controller now, like every other dependency — the seeder
      // and the requester have to agree on which one.
      engine.baroPressure = 99.5;
      expect(
        engine.evaluateBytes(
          'A-BARO',
          const [120],
          requester: FormulaEngine.probePid('0000'),
        ),
        closeTo(20.5, 1e-6),
      );
    });

    test('BARO measured on one controller does not feed another', () {
      // A single shared value meant `7E0`'s reading fed a formula evaluated on
      // `7E1`, whichever wrote last — the collision the VAL{} work removed,
      // still open on the one input with no byte of its own.
      final now = DateTime(2026, 8, 15);
      const ecm = Pid(
        name: 'baro', shortName: 'baro', modeAndPid: '0133', equation: 'A',
        minValue: 0, maxValue: 255, units: 'kPa', header: '7E0',
      );
      const onTcm = Pid(
        name: 'boost', shortName: 'boost', modeAndPid: '010B',
        equation: 'A-BARO', minValue: -100, maxValue: 300, units: 'kPa',
        header: '7E1',
      );

      engine.setBaroPressure(ecm, 99.5, now);
      expect(
        () => engine.evaluateBytes('A-BARO', const [120],
            requester: onTcm, now: now),
        throwsA(isA<FormulaException>()),
        reason: 'the TCM has no barometric measurement of its own',
      );
    });

    test('BARO does not survive a break in continuity', () {
      // `clearCache()` runs on pause. Leaving the pressure behind let a value
      // measured before the pause feed a formula after one.
      final now = DateTime(2026, 8, 15);
      final probe = FormulaEngine.probePid('0000');
      engine.setBaroPressure(probe, 99.5, now);
      engine.clearCache();
      expect(
        () => engine.evaluateBytes('A-BARO', const [120],
            requester: probe, now: now),
        throwsA(isA<FormulaException>()),
      );
    });

    test('a nested divide-by-zero is a formula error, not a raw throw', () {
      // `ABS(A/B)` with B = 0 raised `_ArithmeticFailure` during
      // preprocessing, outside the boundary that converts it — so the poller,
      // which handles only `FormulaException`, lost the whole cycle through
      // its outer catch and left the previous reading on the gauge as current.
      expect(
        () => engine.evaluateBytes('ABS(A/B)', const [10, 0]),
        throwsA(isA<FormulaException>()),
      );
      expect(
        () => engine.evaluateBytes('LOG10(A/B)', const [10, 0]),
        throwsA(isA<FormulaException>()),
      );
      // And the same equation with a usable divisor still works.
      expect(engine.evaluateBytes('ABS(A/B)', const [10, 2]), closeTo(5, 1e-9));
    });

    test('an unresolved VAL{} reference is an error, not zero', () {
      // `A-VAL{0133}` (boost) would otherwise degrade into `A-0` and display
      // raw manifold pressure as though it were boost.
      expect(
        () => engine.evaluateBytes('VAL{9999}+7', const []),
        throwsA(isA<FormulaException>()),
      );
    });

    test('a resolved VAL{} reference still works', () {
      final now = DateTime(2026, 8, 15);
      engine.cachePidValue(FormulaEngine.probePid('0133'), 101.0, now);
      expect(
        engine.evaluateBytes(
          'A-VAL{0133}',
          const [150],
          requester: FormulaEngine.probePid('0000'),
          now: now,
        ),
        closeTo(49.0, 1e-9),
      );
    });

    test('an ambiguous VAL{} reference is refused, not guessed', () {
      // Two gauges can define the same hex on the same controller with
      // different maths — a raw manifold pressure beside a converted boost
      // figure. They share a cache key, because `VAL{010B}` names hex and
      // nothing else, so whichever polled last used to win and the number that
      // came out looked exactly as reasonable as the right one.
      final now = DateTime(2026, 8, 15);
      const raw = Pid(
        name: 'map', shortName: 'map', modeAndPid: '010B', equation: 'A',
        minValue: 0, maxValue: 255, units: 'kPa',
      );
      const converted = Pid(
        name: 'boost', shortName: 'boost', modeAndPid: '010B',
        equation: 'A*0.145', minValue: 0, maxValue: 255, units: 'psi',
        variant: 'psi',
      );

      engine.cachePidValue(raw, 100, now);
      expect(
        engine.cachedPidValue(FormulaEngine.probePid('0000'), '010B', now: now),
        equals(100),
        reason: 'one definition resolves normally',
      );

      engine.cachePidValue(converted, 14.5, now);
      expect(
        engine.cachedPidValue(FormulaEngine.probePid('0000'), '010B', now: now),
        isNull,
        reason: 'two definitions computing different things cannot be told '
            'apart by a reference that names only the hex',
      );
    });

    test('a VAL{} reference goes stale rather than standing forever', () {
      final measured = DateTime(2026, 8, 15);
      engine.cachePidValue(FormulaEngine.probePid('0133'), 101.0, measured);
      expect(
        () => engine.evaluateBytes(
          'A-VAL{0133}',
          const [150],
          requester: FormulaEngine.probePid('0000'),
          now: measured.add(
            FormulaEngine.maxCacheAge + const Duration(seconds: 1),
          ),
        ),
        throwsA(isA<FormulaException>()),
        reason: 'the poller drops a reading whose source stopped answering, '
            'but the formula cache kept quoting the number indefinitely',
      );
    });

    test('SIGNED() past the payload is an error', () {
      expect(
        () => engine.evaluateBytes('SIGNED(C)', const [1, 2]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('a non-finite result is rejected', () {
      expect(
        () => engine.evaluateBytes('LOG10(A)/0', const [100]),
        throwsA(isA<FormulaException>()),
      );
    });
  });

  // The link this branch created, and the one a hand-typed copy table cannot
  // reach. Before this slice the value was interpolated into `message` at the
  // throw site — one expression, with no second copy to diverge from. Now the
  // screen reads `exception.byteLetter`, `.byteCount`, `.argument`, `.term`
  // and `.pidKey` instead, and a copy table proves only that the sentence is
  // right *for a payload it handed itself*. Corrupting all of them at once —
  // `byteLetter: letter` to `'Z'`, `byteCount: bytes.length` to `0`,
  // `argument: v` to `0`, `pidKey: key` to `'XXXX'`, `term: s` to `'zzz'` —
  // left the whole suite green, and the reader was then told fluently, in
  // their own language, "The formula refers to byte Z, but the reply carried
  // only 0 bytes".
  //
  // So these drive the real engine and compare what it carried against what
  // the test itself put in. Every expected value below is a literal derived
  // from this test's own input, never read back off the exception.
  group('a refusal carries the values the engine actually saw', () {
    FormulaException thrownBy(void Function() body) {
      try {
        body();
      } on FormulaException catch (e) {
        return e;
      }
      fail('expected a FormulaException');
    }

    // Two throw sites, one identifier. `SIGNED(C)` and a bare `C` are the same
    // fact with the same remedy, so they share `byteBeyondResponse` — which is
    // exactly why each needs its own pin: one site could carry `'Z'`/`0` while
    // the other stayed correct and the identifier assertion would not notice.
    // Different letters and different payload lengths, so a value copied from
    // the wrong site is a failure rather than a coincidence.
    test('SIGNED() past the payload names the byte and the length it saw', () {
      final e = thrownBy(() => engine.evaluateBytes('SIGNED(C)', const [1, 2]));
      expect(e.issue, FormulaIssue.byteBeyondResponse);
      expect(e.byteLetter, 'C');
      expect(e.byteCount, 2);
    });

    test('a bare byte past the payload names its own byte and length', () {
      final e = thrownBy(() => engine.evaluateBytes('E+1', const [1, 2, 3]));
      expect(e.issue, FormulaIssue.byteBeyondResponse);
      expect(e.byteLetter, 'E');
      expect(e.byteCount, 3);
    });

    test('SQRT of a negative argument carries the argument', () {
      final e = thrownBy(() => engine.evaluateBytes('SQRT(A-128)', const [0]));
      expect(e.issue, FormulaIssue.sqrtNegativeArgument);
      expect(e.argument, -128.0);
    });

    test('LOG10 of a non-positive argument carries the argument', () {
      // `A = 0`, so the argument the function was handed is -128. Rendering a
      // 0 here would read as an ordinary boundary complaint about an
      // expression that is nowhere near the boundary.
      final e = thrownBy(() => engine.evaluateBytes('LOG10(A-128)', const [0]));
      expect(e.issue, FormulaIssue.log10NonPositiveArgument);
      expect(e.argument, -128.0);
    });

    test('LOG of a non-positive argument carries the argument', () {
      final e = thrownBy(() => engine.evaluateBytes('LOG(A-128)', const [0]));
      expect(e.issue, FormulaIssue.logNonPositiveArgument);
      expect(e.argument, -128.0);
    });

    test('an unparsable term carries the fragment, after substitution', () {
      // `1@2`, not `A@B`: the reader is shown what the reducer choked on, and
      // the bytes are already in it. Pinning the post-substitution form is
      // deliberate — it is what the sentence quotes.
      final e = thrownBy(() => engine.evaluateBytes('A@B', const [1, 2]));
      expect(e.issue, FormulaIssue.unparsableTerm);
      expect(e.term, '1@2');
    });

    test('an unresolvable VAL{} carries the key that could not be resolved',
        () {
      final e =
          thrownBy(() => engine.evaluateBytes('VAL{010C}+1', const []));
      expect(e.issue, FormulaIssue.dependencyControllerUnknown);
      expect(e.pidKey, '010C');
    });

    test('a dependency nobody has read yet carries its key', () {
      final e = thrownBy(
        () => engine.evaluateBytes(
          'VAL{0133}+1',
          const [],
          requester: FormulaEngine.probePid('0000'),
          now: DateTime(2026, 8, 15),
        ),
      );
      expect(e.issue, FormulaIssue.dependencyNotYetMeasured);
      expect(e.pidKey, '0133');
    });

    test('the two-definitions refusal carries the contested key', () {
      // The longest sentence in this feature, and the one that tells the
      // reader that taking a gauge off the dashboard will not stop 010B being
      // polled. A key substituted here sends them to edit a definition they do
      // not have.
      final now = DateTime(2026, 8, 15);
      const raw = Pid(
        name: 'map', shortName: 'map', modeAndPid: '010B', equation: 'A',
        minValue: 0, maxValue: 255, units: 'kPa',
      );
      const converted = Pid(
        name: 'boost', shortName: 'boost', modeAndPid: '010B',
        equation: 'A*0.145', minValue: 0, maxValue: 255, units: 'psi',
        variant: 'psi',
      );
      engine.cachePidValue(raw, 100, now);
      engine.cachePidValue(converted, 14.5, now);

      final e = thrownBy(
        () => engine.evaluateBytes(
          'VAL{010B}+1',
          const [],
          requester: FormulaEngine.probePid('0000'),
          now: now,
        ),
      );
      expect(e.issue, FormulaIssue.dependencyTwoDefinitions);
      expect(e.pidKey, '010B');
    });
  });

  // condition -> identifier, for every value the group above does not reach.
  //
  // The group above pins the *values* a refusal carries and, incidentally, the
  // seven identifiers those seven inputs happen to produce. The other twelve
  // had nothing driving them: the reviewer transposed
  // `divisionByZero`/`moduloByZero`, `baroNotYetMeasured`/`baroMeasurementStale`,
  // `emptyFormula`->`emptySubExpression` and
  // `functionNestingTooDeep`->`parenthesisNestingTooDeep` at the throw sites
  // and the whole suite stayed green at +2096 ~16. Each of those ships a
  // fluent, correct-looking English sentence about a formula the reader did
  // not write: `A/0` told to look for a `%`, an ambient pressure that was
  // never read called out of date — the enum's own doc calls that pair "a
  // different fact with a different remedy".
  //
  // A table, because the input is the whole assertion: each row drives the
  // real engine and names the identifier that condition must produce. Nothing
  // here reads the identifier back off the exception.
  group('a condition produces its own identifier', () {
    FormulaException thrownBy(void Function() body) {
      try {
        body();
      } on FormulaException catch (e) {
        return e;
      }
      fail('expected a FormulaException');
    }

    void expectIssue(
      String label,
      FormulaIssue issue,
      void Function() body,
    ) {
      test(label, () => expect(thrownBy(body).issue, issue));
    }

    expectIssue(
      'nothing typed at all is an empty formula, not an empty part of one',
      FormulaIssue.emptyFormula,
      () => engine.evaluateBytes('', const [1]),
    );

    expectIssue(
      'whitespace alone is still nothing typed',
      FormulaIssue.emptyFormula,
      () => engine.evaluateBytes('   ', const [1]),
    );

    expectIssue(
      'an operator with nothing after it is an empty part, not an empty '
      'formula',
      // The remedy is to finish the operator. Told "the formula is empty"
      // about a field with `A*` in it, the reader is looking at a
      // contradiction of what is in front of them.
      FormulaIssue.emptySubExpression,
      () => engine.evaluateBytes('A*', const [1]),
    );

    expectIssue(
      'a bracket that never closes is unbalanced',
      FormulaIssue.unbalancedParentheses,
      () => engine.evaluateBytes('(A+1', const [1]),
    );

    expectIssue(
      'a closing bracket before its opener is unbalanced too',
      FormulaIssue.unbalancedParentheses,
      () => engine.evaluateBytes('A)+(1', const [1]),
    );

    // Four throw sites, two identifiers, and every one of them separately
    // transposable. The pair differs only in which construct the sentence
    // tells the author to simplify, so naming the wrong one sends somebody
    // through a formula counting the thing that is not the problem. All four
    // are reachable — that was probed, not assumed — so all four are pinned.
    expectIssue(
      'the innermost-call pass names the functions',
      FormulaIssue.functionNestingTooDeep,
      () => engine.evaluateBytes(
        '${'ABS(' * 65}A${')' * 65}',
        const [1],
      ),
    );

    expectIssue(
      'the alternating outer pass names the functions too',
      // `ABS((A))` is the shape the ordinary pass cannot see, so it goes round
      // the outer ABS/LOG10 loop instead and trips that guard rather than the
      // one above.
      FormulaIssue.functionNestingTooDeep,
      () => engine.evaluateBytes(
        '${'ABS((' * 65}A${'))' * 65}',
        const [1],
      ),
    );

    expectIssue(
      'brackets nested past the limit name the brackets',
      FormulaIssue.parenthesisNestingTooDeep,
      () => engine.evaluateBytes(
        '${'(' * 257}A${')' * 257}',
        const [1],
      ),
    );

    expectIssue(
      'the parenthesised-argument unwrapper names the brackets',
      // Sixty-five `ABS((1))` side by side rather than nested: the unwrapper
      // takes one per turn, so it is the count and not the depth that trips
      // it. Still the bracket sentence, because brackets are what it is
      // undoing.
      FormulaIssue.parenthesisNestingTooDeep,
      () => engine.evaluateBytes(
        List.filled(65, 'ABS((1))').join('+'),
        const [1],
      ),
    );

    expectIssue(
      'dividing by zero names the division',
      // The character the author has to find is `/`, in a formula that has no
      // `%` anywhere in it.
      FormulaIssue.divisionByZero,
      () => engine.evaluateBytes('A/0', const [1]),
    );

    expectIssue(
      'a remainder modulo zero names the remainder',
      FormulaIssue.moduloByZero,
      () => engine.evaluateBytes('A%0', const [1]),
    );

    expectIssue(
      'a top-level NaN is a result that is not a number',
      // `(-1)^0.5` reduces to NaN and reaches the final check in
      // `evaluateBytes`.
      FormulaIssue.resultNotFinite,
      () => engine.evaluateBytes('(-1)^0.5', const [1]),
    );

    expectIssue(
      'a NaN part-way through is the same fact at a different throw site',
      // `_format` refuses to splice a non-finite intermediate back into the
      // string — which is why `((-1)^0.5)+90` cannot quietly collapse to 90.
      // Two sites, one identifier: pinning only the first would let this one
      // be renamed.
      FormulaIssue.resultNotFinite,
      () => engine.evaluateBytes('((-1)^0.5)+90', const [1]),
    );

    expectIssue(
      'BARO with nobody asking cannot say whose controller is meant',
      FormulaIssue.baroControllerUnknown,
      () => engine.evaluateBytes('A-BARO', const [120]),
    );

    expectIssue(
      'ambient pressure that was never read has not been read yet',
      // Not stale. The remedy is to wait; nothing is wrong with the formula,
      // and nothing has stopped answering.
      FormulaIssue.baroNotYetMeasured,
      () => engine.evaluateBytes(
        'A-BARO',
        const [120],
        requester: FormulaEngine.probePid('0000'),
        now: DateTime(2026, 8, 15),
      ),
    );

    test('ambient pressure older than the cache window is stale, not absent',
        () {
      // The other half of that pair, and the one whose remedy is the opposite:
      // a source that has stopped answering. `maxCacheAge` is 5s, so 6 is past
      // it and the reading exists.
      final measuredAt = DateTime(2026, 8, 15);
      final probe = FormulaEngine.probePid('0000');
      engine.setBaroPressure(probe, 99.5, measuredAt);
      final e = thrownBy(
        () => engine.evaluateBytes(
          'A-BARO',
          const [120],
          requester: probe,
          now: measuredAt.add(const Duration(seconds: 6)),
        ),
      );
      expect(e.issue, FormulaIssue.baroMeasurementStale);

      // And inside the window it is neither: the staleness rule is what
      // separates the two, so a test that never evaluates successfully would
      // pass with the window set to zero.
      expect(
        engine.evaluateBytes(
          'A-BARO',
          const [120],
          requester: probe,
          now: measuredAt.add(const Duration(seconds: 4)),
        ),
        closeTo(20.5, 0.001),
      );
    });

    test('two authors of one controller ambient pressure is ambiguity, not '
        'absence', () {
      // `_writersDisagree` needs a different equation *and* a different value,
      // which is what a second definition of the same measurement actually
      // looks like — a custom `0133` as `A*10` polled beside the built-in `A`.
      final now = DateTime(2026, 8, 15);
      const first = Pid(
        name: 'baro', shortName: 'baro', modeAndPid: '0133', equation: 'A',
        minValue: 0, maxValue: 255, units: 'kPa', header: '7E0',
      );
      const second = Pid(
        name: 'baro x10', shortName: 'baro10', modeAndPid: '0133',
        equation: 'A*10', minValue: 0, maxValue: 2550, units: 'kPa',
        header: '7E0', variant: 'x10',
      );
      const asking = Pid(
        name: 'boost', shortName: 'boost', modeAndPid: '010B',
        equation: 'A-BARO', minValue: -100, maxValue: 300, units: 'kPa',
        header: '7E0',
      );
      engine.setBaroPressure(first, 99.5, now);
      engine.setBaroPressure(second, 995, now);

      final e = thrownBy(
        () => engine.evaluateBytes(
          'A-BARO',
          const [120],
          requester: asking,
          now: now,
        ),
      );
      // Not `baroNotYetMeasured`: the value exists twice and the app is
      // declining to choose, so telling the author to wait sends them to look
      // for a fault in a vehicle that is answering perfectly.
      expect(e.issue, FormulaIssue.baroTwoDefinitions);
    });
  });

  group('failure handling', () {
    test('rejects an empty formula', () {
      expect(() => engine.evaluateBytes('', const [1]), throwsA(isA<FormulaException>()));
    });

    test('rejects unbalanced parentheses', () {
      expect(
        () => engine.evaluateBytes('(A+1', const [1]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('rejects a stray identifier', () {
      expect(
        () => engine.evaluateBytes('A+ZZZ', const [1]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('validate() accepts a sound formula', () {
      expect(FormulaEngine.validate('((A*256)+B)/4'), isNull);
    });

    test('validate() reports the problem with a broken formula', () {
      expect(FormulaEngine.validate('((A*256)+B'), isNotNull);
    });
  });

  group('numeric formatting round-trip', () {
    test('small magnitudes do not degrade into scientific notation', () {
      // toString() would render this as 1e-7 and the reducer would then split
      // on the '-', producing nonsense.
      final result = engine.evaluateBytes('A/10000000', const [1]);
      expect(result, closeTo(1e-7, 1e-12));
    });

    test('a tiny intermediate survives a following operation', () {
      final result = engine.evaluateBytes('(A/10000000)*10000000', const [3]);
      expect(result, closeTo(3.0, 1e-6));
    });

    test('sub-1e-10 intermediates are not rounded to zero', () {
      // Ten fractional digits made MAX(4e-11:0)*1e12 publish 0.
      expect(
        engine.evaluateBytes('MAX(0.00000000004:0)*1000000000000', const []),
        closeTo(40.0, 1e-9),
      );
      expect(
        engine.evaluateBytes('ABS(0.00000000004)*1000000000000', const []),
        closeTo(40.0, 1e-9),
      );
    });

    test('intermediates below 5e-17 are not rounded to zero', () {
      // toStringAsFixed(16) made MAX(4e-18:0)*1e19 publish 0.
      expect(
        engine.evaluateBytes(
          'MAX(0.000000000000000004:0)*10000000000000000000',
          const [],
        ),
        closeTo(40.0, 1e-6),
      );
      expect(
        engine.evaluateBytes(
          'ABS(0.000000000000000004)*10000000000000000000',
          const [],
        ),
        closeTo(40.0, 1e-6),
      );
      expect(
        engine.evaluateBytes(
          'MIN(-0.000000000000000004:0)*10000000000000000000',
          const [],
        ),
        closeTo(-40.0, 1e-6),
      );
    });
  });

  _editorValidation();
}

// Editor-facing validation. Runtime evaluation is strict about unresolved
// dependencies; authoring is not, because at authoring time there is no live
// data at all and blocking on that would make VAL{} unusable despite the
// editor advertising it.
void _editorValidation() {
  group('editor validation vs runtime evaluation', () {
    test('a formula with VAL{} validates even though nothing is polled yet', () {
      expect(FormulaEngine.validate('A-VAL{0133}'), isNull);
    });

    test('valReferences finds every dependency', () {
      expect(
        FormulaEngine.valReferences('VAL{010D}*0.6+VAL{0133}'),
        containsAll(['010D', '0133']),
      );
    });

    test('a malformed formula still fails validation', () {
      expect(FormulaEngine.validate('A-VAL{0133}*'), isNotNull);
      expect(FormulaEngine.validate('((A+1)'), isNotNull);
    });

    test('runtime evaluation stays strict about the same formula', () {
      expect(
        () => FormulaEngine().evaluateBytes('A-VAL{0133}', const [150]),
        throwsA(isA<FormulaException>()),
      );
    });

    test('R23-kimi F7: modulo takes the sign of the dividend, as Torque does',
        () {
      // These formulas are written for Torque, which is a Java app, and Java's
      // `%` is a truncated remainder — it takes the dividend's sign. Dart's is
      // Euclidean and never negative. `(A-128)%16` with `A = 0x64` is -12 in
      // Torque and was 12 here: two numbers, both plausible, both passing
      // every structural check, and the gauge showed the wrong one with no
      // fault raised.
      expect(FormulaEngine().evaluateBytes('(A-128)%16', const [0x64]), -12);
      // The ordinary direction is unchanged.
      expect(FormulaEngine().evaluateBytes('A%16', const [0x64]), 4);
    });

    test('R23-kimi F8: ABS and LOG10 nest in either order', () {
      // Both patterns exclude parentheses so each pass collapses an innermost
      // call, and the passes ran once each in a fixed order — so exactly one
      // nesting order worked. `LOG10(ABS(A))` reduced; `ABS(LOG10(A))` was
      // refused at authoring time with nothing wrong in it.
      expect(FormulaEngine().evaluateBytes('LOG10(ABS(A))', const [100]), 2);
      expect(FormulaEngine().evaluateBytes('ABS(LOG10(A))', const [100]), 2);
      // And an argument parenthesised for its own sake, which is how people
      // write.
      expect(FormulaEngine().evaluateBytes('ABS((A-200))', const [100]), 100);
      expect(FormulaEngine.validate('ABS(LOG10(A))'), isNull);
    });

    test('R23-kimi F9: a sample too short to hold a header keeps its bytes',
        () {
      // `62 1E` is two bytes and the Mode 22 header is three, so stripping it
      // threw a raw `RangeError` — outside this file's exception contract, and
      // the editor showed the user a Dart error object.
      expect(FormulaEngine.parseUserTypedSampleBytes('62 1E'), [0x62, 0x1E]);
      expect(
        FormulaEngine.parseUserTypedSampleBytes(
          '41 0C 1A F8',
          stripResponsePrefix: true,
        ),
        [0x1A, 0xF8],
      );
      expect(
        FormulaEngine.parseUserTypedSampleBytes(
          '62 F1 90 41',
          stripResponsePrefix: true,
        ),
        [0x41],
      );
      // Two bytes beginning 0x4X are kept: there is no header to remove.
      expect(FormulaEngine.parseUserTypedSampleBytes('4A 20'), [0x4A, 0x20]);
    });
  });
}
