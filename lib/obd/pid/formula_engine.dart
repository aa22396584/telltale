/// Evaluates the arithmetic a PID definition carries.
///
/// The dialect is the one OBD2 apps have converged on and users already write
/// by hand: `A`..`N` bind to the reply's data bytes, with `SIGNED()`, `SIGNED8()`, `SIGNED16()`, `SIGNED24()`, `SIGNED32()`, `FLOAT32()`, `FLOAT64()`, `INT()`, `INT24()`, `INT32()`, `RANDOM()`, `VAL{}`,
/// `BARO`, `ABS()`, `LOG10()`, `LOG()`, `LOG1P()`, `SQRT()`, `SIN()`, `COS()`, `TAN()`, `MIN()`, `MAX()` and `BIT()` on top. Accepting it means
/// somebody's existing formula for their car works here without being retyped.
///
/// Evaluation is two-phase:
///   1. [_preprocess] binds `A`..`N` to response bytes and resolves the
///      non-arithmetic constructs — `SIGNED()`, `SIGNED8()`, `SIGNED16()`, `SIGNED24()`, `SIGNED32()`, `FLOAT32()`, `FLOAT64()`, `INT()`, `INT24()`, `INT32()`, `RANDOM()`, `VAL{}`, `BARO`, `ABS()`,
///      `LOG10()`, `LOG()`, `LOG1P()`, `SQRT()`, `SIN()`, `COS()`, `TAN()`, `MIN()`, `MAX()`, `BIT()` — leaving a pure arithmetic string.
///   2. [_reduce] collapses that string by repeatedly splitting on the
///      lowest-binding operator, recursing into each side.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'pid.dart';

/// Why a formula could not be evaluated, as an identifier a screen translates.
///
/// The engine is pure Dart and has no business holding a language. Every value
/// here is a distinct *fact about the formula* with its own remedy; where a
/// sentence names a value — the byte letter, the referenced PID, the argument
/// that was out of domain — that value travels on [FormulaException] as data
/// and reaches the ARB as a placeholder, so no identifier has a number baked
/// into it.
enum FormulaIssue {
  /// Nothing was typed at all.
  emptyFormula,

  /// Something was typed, but a sub-expression came out empty — `A*`, `(1+)`.
  /// Not [emptyFormula]: the remedy is to finish an operator, not to write a
  /// formula.
  emptySubExpression,

  /// A `(` with no `)`, or the other way round.
  unbalancedParentheses,

  /// A fragment that is neither a number, an operator, nor a name this dialect
  /// knows. Carries the fragment.
  unparsableTerm,

  /// `ABS(`/`LOG10(`/`LOG(`/`SQRT(`/`SIN(`/`COS(`/`TAN(` nested past the evaluator's limit. Distinct from
  /// [parenthesisNestingTooDeep] because it names a different construct to
  /// simplify.
  functionNestingTooDeep,

  /// Plain `(` groups nested past the evaluator's limit.
  parenthesisNestingTooDeep,

  /// `/` by zero. Separate from [moduloByZero] because the operator the author
  /// has to find is a different character in a different place.
  divisionByZero,

  /// `%` by zero.
  moduloByZero,

  /// `LOG10` of zero or a negative number, which has no value. Carries the
  /// argument.
  log10NonPositiveArgument,

  /// `LOG` of zero or a negative number, which has no value. Carries the
  /// argument. Not [log10NonPositiveArgument]: the function the author has to
  /// find is a different name, even though the domain is the same.
  logNonPositiveArgument,

  /// `SQRT` of a negative number, which has no real value. Carries the
  /// argument. Zero is allowed.
  sqrtNegativeArgument,

  /// The arithmetic produced NaN or an infinity, at the end or part-way
  /// through. Either way there is no reading, and the remedy is the same.
  resultNotFinite,

  /// The formula refers to a byte the reply does not contain. Carries the
  /// letter and how many bytes did arrive.
  byteBeyondResponse,

  /// `BARO` was used with no requesting PID, so which controller's ambient
  /// pressure is meant cannot be decided.
  baroControllerUnknown,

  /// Two definitions on this controller both supply ambient pressure, so the
  /// value could be either. Not [baroControllerUnknown]: the controller is
  /// known and it is the definitions that are ambiguous.
  baroTwoDefinitions,

  /// Ambient pressure has never been measured on this controller. The remedy
  /// is to wait for a reading; nothing is wrong with the formula.
  baroNotYetMeasured,

  /// Ambient pressure was measured and is now older than the cache window. A
  /// different fact from [baroNotYetMeasured] with a different remedy: the
  /// source has stopped answering rather than not yet started.
  baroMeasurementStale,

  /// `VAL{...}` was used with no requesting PID. Carries the referenced key.
  dependencyControllerUnknown,

  /// Two definitions on this controller both decode the referenced key.
  /// Carries the key.
  dependencyTwoDefinitions,

  /// The referenced PID has no usable value — never read, or gone stale.
  /// Carries the key.
  dependencyNotYetMeasured,

  /// A named Torque wiki function this dialect does not implement. Carries
  /// the function name. Distinct from [unparsableTerm]: a typo is not a
  /// documented construct we have chosen not to evaluate.
  unsupportedConstruct,
}

/// Thrown when a formula cannot be evaluated. Carries the offending source so
/// the PID editor can show the user what it choked on.
///
/// [message] is deliberately unchanged and still Traditional Chinese. It is
/// what `FormulaEngine.validate` returns into the powertrain-battery catalogue
/// validator, and what `powertrain_battery_probe.dart` stringifies into a
/// probe transcript; both are diagnostics rather than screen copy. What a
/// screen renders is [issue], through
/// `lib/ui/screens/pids/pid_formula_copy.dart`.
///
/// [issue] is **required and nullable**, the same shape `TransportException`
/// uses: the compiler refuses a throw that forgets it, and a deliberate `null`
/// has to be typed out where somebody reviewing the diff can see it.
/// `test/l10n/pid_reason_guard_test.dart` then refuses even that.
class FormulaException implements Exception {
  final String message;
  final String source;

  /// What went wrong, for the screen to translate.
  final FormulaIssue? issue;

  /// The `VAL{...}` key the sentence names, for the dependency issues.
  final String? pidKey;

  /// The byte letter (`A`..`N`) the formula referenced.
  final String? byteLetter;

  /// How many data bytes the reply actually carried.
  final int? byteCount;

  /// The out-of-domain argument, for log/sqrt domain refusals.
  final double? argument;

  /// The fragment that could not be parsed.
  final String? term;

  const FormulaException(
    this.message,
    this.source, {
    required this.issue,
    this.pidKey,
    this.byteLetter,
    this.byteCount,
    this.argument,
    this.term,
  });

  @override
  String toString() => 'FormulaException: $message (in "$source")';
}

/// A cached dependency value, with the two things a bare `double` cannot say:
/// when it was measured, and which controller measured it (via its cache key).
class _CachedValue {
  const _CachedValue(
    this.value,
    this.at,
    this.writtenBy, {
    this.receivedElapsed = Duration.zero,
  });
  final double value;
  final DateTime at;

  /// Connection-stopwatch tick at acquisition. Wall UTC is display
  /// metadata; a small-positive clock correction after a real pause
  /// must not make this entry look younger than it is.
  final Duration receivedElapsed;

  /// The equation that produced it.
  ///
  /// Two gauges can define the same hex on the same controller with different
  /// maths — a raw variant beside a converted one. They share a cache key,
  /// because `VAL{010B}` names hex and nothing else, and whichever polled last
  /// used to win. Recording the author lets an ambiguous reference be refused
  /// instead of answered arbitrarily.
  final String writtenBy;
}

class FormulaEngine {
  FormulaEngine({double Function()? random})
      : _random = random ?? math.Random().nextDouble;

  /// Wiki `RANDOM()` source. Defaults to Dart `Random.nextDouble` (`[0, 1)`).
  final double Function() _random;

  /// Cached values of other PIDs for `VAL{...}` lookups.
  ///
  /// Keyed by controller **and** hex, never hex alone. `7E0:221101` and
  /// `7E1:221101` are different sensors on different controllers that happen
  /// to share an identifier; collapsing them let a formula on one ECU consume
  /// the other's measurement, whichever polled last.
  final Map<String, _CachedValue> _pidCache = {};

  /// How long a cached dependency stays usable.
  ///
  /// Without an age, a source that stopped answering left its last value in
  /// the cache forever: the poller removed the visible reading and marked the
  /// fault, while every formula depending on it went on quoting the number.
  static const Duration maxCacheAge = Duration(seconds: 5);

  /// Ambient pressure per controller, on the same terms as every other
  /// dependency.
  ///
  /// A single shared value meant `7E0`'s barometric reading fed a formula
  /// evaluated on `7E1`, whichever wrote last — the very collision the `VAL{}`
  /// work removed, still open on the one input that had no byte of its own.
  /// It also survived `clearCache()`, so a pressure measured before a pause
  /// was consumed after continuity had been explicitly broken.
  final Map<String, _CachedValue> _baro = {};

  /// Records a measured ambient pressure (kPa) taken at [at].
  ///
  /// There is no default. It used to be 101.3 — sea level — which is a
  /// measurement the app never took. At 2000 m ambient is about 79.5 kPa, so
  /// `A-BARO` on a 100 kPa manifold reported -1.3 kPa instead of +20.5 kPa:
  /// plausible, labelled as derived from measurement, and wrong by the whole
  /// altitude.
  void setBaroPressure(
    Pid source,
    double kPa,
    DateTime at, {
    Duration receivedElapsed = Duration.zero,
  }) {
    final key = _controllerKey(source.header);
    final existing = _baro[key];
    // The same conflict rule `VAL{}` uses, and it was missing here — the
    // author of each write was recorded and then consulted by nobody. A custom
    // `0133` defined as `A*10` polled beside the built-in `A` had `BARO`
    // silently alternating between two values at the polling cadence, on one
    // controller, for one measurement. `VAL{0133}` refuses that exact
    // collision, so the app was applying two opposite policies to the same
    // ambiguity depending on which spelling a formula happened to use.
    if (existing != null && _writersDisagree(existing, source.equation, kPa)) {
      _baroAmbiguous.add(key);
    }
    _baro[key] = _CachedValue(
      kPa,
      at,
      source.equation,
      receivedElapsed: receivedElapsed,
    );
  }

  /// Controllers whose ambient pressure has more than one author.
  final Set<String> _baroAmbiguous = {};

  static String _controllerKey(String header) => header.toUpperCase().trim();

  /// Seeds a stand-in ambient pressure for authoring previews, where there is
  /// no live data and the only question is whether the formula is well-formed.
  ///
  /// Deliberately not usable as a runtime measurement: evaluation with a
  /// timestamp applies the same staleness rule to it as to any dependency.
  set baroPressure(double? kPa) {
    final key = _controllerKey(kDefaultHeader);
    if (kPa == null) {
      _baro.remove(key);
    } else {
      _baro[key] = _CachedValue(kPa, DateTime.now(), 'authoring');
    }
  }

  static String _cacheKey(String header, String modeAndPid) =>
      '${header.toUpperCase().trim()}:${modeAndPid.toUpperCase().trim()}';

  /// Elapsed cache age. A backwards clock step is expiry, not freshness:
  /// `.abs()` used to make an hour-old sample look one hour in the future.
  /// When [elapsed] is supplied, the monotonic tick is the TTL; wall time
  /// still flags a backwards step.
  static bool _expired(
    DateTime now,
    DateTime at,
    Duration maxAge, {
    Duration? elapsed,
    Duration receivedElapsed = Duration.zero,
  }) {
    final wallAge = now.difference(at);
    if (wallAge.isNegative) return true;
    if (elapsed != null) {
      final monoAge = elapsed - receivedElapsed;
      if (monoAge.isNegative) return true;
      return monoAge > maxAge;
    }
    return wallAge > maxAge;
  }

  /// Operators grouped into precedence levels, loosest first.
  ///
  /// Grouping matters. Scanning a flat list and splitting on the first symbol
  /// found makes every operator a distinct precedence level in list order, so
  /// `A/B%C` would split on `/` and evaluate as `A/(B%C)`. `*`, `/` and `%`
  /// are one level in every language that has them, and within a level the
  /// split takes the *right-most* occurrence so repeated operators associate
  /// left to right.
  static final List<List<_Operator>> _levels = [
    [
      _Operator('==', (a, b) => a == b ? 1.0 : 0.0),
      _Operator('!=', (a, b) => a != b ? 1.0 : 0.0),
      _Operator('>=', (a, b) => a >= b ? 1.0 : 0.0),
      _Operator('<=', (a, b) => a <= b ? 1.0 : 0.0),
      _Operator('>', (a, b) => a > b ? 1.0 : 0.0),
      _Operator('<', (a, b) => a < b ? 1.0 : 0.0),
    ],
    [_Operator('|', (a, b) => (a.toInt() | b.toInt()).toDouble())],
    [_Operator('&', (a, b) => (a.toInt() & b.toInt()).toDouble())],
    [
      _Operator('+', (a, b) => a + b),
      _Operator('-', (a, b) => a - b),
    ],
    [
      _Operator('*', (a, b) => a * b),
      // Returning 0 here turns a divide-by-zero into a plausible reading. A
      // boost formula dividing by a baro value that has not arrived yet would
      // show 0 kPa rather than admitting it cannot be computed.
      _Operator('/', (a, b) {
        if (b == 0) throw const _ArithmeticFailure('除以零', FormulaIssue.divisionByZero);
        return a / b;
      }),
      _Operator('%', (a, b) {
        if (b == 0) throw const _ArithmeticFailure('模除以零', FormulaIssue.moduloByZero);
        // Truncated remainder, not Dart's Euclidean `%`.
        //
        // These formulas come from Torque, which is a Java app, and Java's `%`
        // takes the sign of the dividend. Dart's does not: `(A-128)%16` with
        // `A = 0x64` is `-12` in Torque and `12` here. Both are numbers, both
        // pass every structural check the editor makes, and the gauge shows
        // the wrong one with no fault — which is the failure this project
        // exists to prevent. A user's imported formula has to mean what it
        // meant where it was written.
        return a.remainder(b);
      }),
    ],
  ];

  /// Binds tighter than a unary minus, so `-A^2` is `-(A^2)`.
  static final _Operator _power = _Operator('^', (a, b) => math.pow(a, b).toDouble());

  static final RegExp _valPattern = RegExp(r'VAL\{([A-F0-9]+)\}');
  static final RegExp _signedPattern = RegExp(r'SIGNED\(([A-N])\)');
  static final RegExp _absPattern = RegExp(r'ABS\(([^()]+)\)');
  static final RegExp _log10Pattern = RegExp(r'LOG10\(([^()]+)\)');
  static final RegExp _logPattern =
      RegExp(r'(^|[^A-Za-z0-9_])LOG\(([^()]+)\)(?![A-Za-z0-9_])');
  static final RegExp _log1pPattern =
      RegExp(r'(^|[^A-Za-z0-9_])LOG1P\(([^()]+)\)(?![A-Za-z0-9_])');
  static final RegExp _sqrtPattern = RegExp(r'SQRT\(([^()]+)\)');
  // Same token boundaries as LOG: `2SIN(0)` is not 20, `SIN(0)A` is not 0.05.
  static final RegExp _sinPattern =
      RegExp(r'(^|[^A-Za-z0-9_])SIN\(([^()]+)\)(?![A-Za-z0-9_])');
  static final RegExp _cosPattern =
      RegExp(r'(^|[^A-Za-z0-9_])COS\(([^()]+)\)(?![A-Za-z0-9_])');
  static final RegExp _tanPattern =
      RegExp(r'(^|[^A-Za-z0-9_])TAN\(([^()]+)\)(?![A-Za-z0-9_])');

  /// Sentinels that stand in for function names while `A`..`N` are substituted.
  /// They must contain no A-N letters of their own, hence control characters.
  static const String _absSentinel = '\u0001(';
  static const String _log10Sentinel = '\u0002(';
  static const String _minSentinel = '\u0003(';
  static const String _maxSentinel = '\u0004(';
  static const String _sqrtSentinel = '\u0005(';
  static const String _logSentinel = '\u0006(';
  static const String _log1pSentinel = '\u0010(';
  static const String _signed16Sentinel = '\u0011(';
  static const String _signed8Sentinel = '\u0012(';
  static const String _signed24Sentinel = '\u0013(';
  static const String _signed32Sentinel = '\u0014(';
  static const String _float32Sentinel = '\u0015(';
  static const String _intSentinel = '\u0016(';
  static const String _float64Sentinel = '\u0017(';
  static const String _int24Sentinel = '\u0018(';
  static const String _int32Sentinel = '\u0019(';
  static const String _randomSentinel = '\u001a(';
  static const String _bitSentinel = '\u0007(';
  static const String _sinSentinel = '\u0008(';
  static const String _cosSentinel = '\u000e(';
  static const String _tanSentinel = '\u000f(';

  /// Characters that, when they precede a `-`, mark it as unary rather than
  /// a binary subtraction.
  static const String _unaryContext = '+-*/%^&|<>(=';

  /// Keys whose value cannot be attributed to one definition.
  final Set<String> _ambiguous = {};

  /// Whether two writers to one key actually disagree.
  ///
  /// Equation *text* is not the question. `A` and `(A)` compute the same
  /// number from the same bytes, and comparing the strings marked the key
  /// permanently ambiguous — so a boost gauge went unavailable because two
  /// definitions of ambient pressure were spelled differently while producing
  /// exactly the same measurement.
  ///
  /// The honest test is whether the values disagree at the moment a reader
  /// would use them. Two definitions that agree today may diverge tomorrow —
  /// `A` and `A*2` agree only while A is zero — and this catches that when it
  /// happens rather than pre-emptively refusing every difference in spelling.
  static bool _writersDisagree(_CachedValue existing, String by, double value) {
    if (existing.writtenBy == by) return false;
    if (existing.value == value) return false;
    // NaN never equals itself; two NaNs are not a disagreement about anything.
    if (existing.value.isNaN && value.isNaN) return false;
    return true;
  }

  void cachePidValue(
    Pid pid,
    double value,
    DateTime at, {
    Duration receivedElapsed = Duration.zero,
  }) {
    final key = _cacheKey(pid.header, pid.modeAndPid);
    final existing = _pidCache[key];
    if (existing != null && _writersDisagree(existing, pid.equation, value)) {
      // Two definitions of the same hex on the same controller, computing
      // different things. `VAL{}` names hex, so it cannot say which was meant.
      _ambiguous.add(key);
    }
    _pidCache[key] = _CachedValue(
      value,
      at,
      pid.equation,
      receivedElapsed: receivedElapsed,
    );
  }

  /// The value [requester] should see for `VAL{[modeAndPid]}`, if any.
  ///
  /// Resolution is scoped to the requester's own controller. A formula on the
  /// ECM asking for a PID only the TCM answers gets null — which is the truth,
  /// and which the caller renders as unavailable rather than as a number.
  double? cachedPidValue(
    Pid requester,
    String modeAndPid, {
    required DateTime? now,
    Duration? elapsed,
  }) {
    final key = _cacheKey(requester.header, modeAndPid);
    // Refused rather than resolved. Picking either answer would be picking one
    // at random, and the number that comes out looks exactly as reasonable as
    // the right one.
    if (_ambiguous.contains(key)) return null;
    // (see `isAmbiguous` — callers need to tell this refusal apart from a
    //  value that has simply not arrived)
    final entry = _pidCache[key];
    if (entry == null) return null;
    // A null `now` means the caller has no clock to judge staleness against —
    // the authoring preview. Runtime always passes one.
    if (now != null &&
        _expired(
          now,
          entry.at,
          maxCacheAge,
          elapsed: elapsed,
          receivedElapsed: entry.receivedElapsed,
        )) {
      return null;
    }
    return entry.value;
  }

  /// Whether two definitions of this hex are both writing to the cache.
  ///
  /// `pidValue` returns null for three different reasons — nobody has answered
  /// yet, the answer has aged out, or two definitions disagree about what the
  /// hex means — and the caller reported all three as "no value obtained yet".
  /// For the third that is a lie about the cause: the value exists, twice, and
  /// the app is declining to choose. Telling the user to wait sends them to
  /// look for a fault in a vehicle that is answering perfectly, when what they
  /// need to do is remove one of two gauges.
  ///
  /// It is easy to reach without doing anything unusual: the shipped library
  /// defines `010B` twice — manifold pressure and turbo boost — and `010D`
  /// twice, as km/h and mph. The physics inputs are force-merged, so putting
  /// either derived gauge on the dashboard makes that hex ambiguous for as
  /// long as it is there.
  bool isAmbiguous(String header, String modeAndPid) =>
      _ambiguous.contains(_cacheKey(header, modeAndPid));

  void clearCache() {
    _pidCache.clear();
    _ambiguous.clear();
    // Cleared with everything else. It is a measurement like any other, and
    // leaving it behind let a pressure from before a pause feed a formula
    // after one.
    _baro.clear();
    _baroAmbiguous.clear();
  }

  /// Evaluates [equation] against a raw ECU hex [payload].
  ///
  /// [payload] may be spaced or contiguous, and may or may not carry the
  /// positive-response prefix. Mode 01 answers (`0x41`) drop 2 leading bytes,
  /// Mode 22 answers (`0x62`) drop 3, so that `A` binds to the first *data*
  /// byte in both cases.
  double evaluate(
    String equation,
    String payload, {
    Pid? requester,
    DateTime? now,
    Duration? elapsed,
  }) {
    return evaluateBytes(
      equation,
      parseUserTypedSampleBytes(payload, stripResponsePrefix: true),
      requester: requester,
      now: now,
      elapsed: elapsed,
    );
  }

  /// Same as [evaluate] but takes already-extracted data bytes, skipping the
  /// response-prefix heuristic. Used by the polling loop, which has already
  /// split a batched multi-PID frame into per-PID slices.
  double evaluateBytes(
    String equation,
    List<int> dataBytes, {
    Pid? requester,
    DateTime? now,
    Duration? elapsed,
  }) {
    if (equation.trim().isEmpty) {
      throw FormulaException(
        'Formula is empty',
        equation,
        issue: FormulaIssue.emptyFormula,
      );
    }
    final unsupported = _unsupportedTorqueFunction(equation);
    if (unsupported != null) {
      throw FormulaException(
        '此方言不支援 $unsupported',
        equation,
        issue: FormulaIssue.unsupportedConstruct,
        term: unsupported,
      );
    }
    final double result;
    try {
      // Preprocessing has to be inside this boundary, not before it.
      // `_applyFunction` reduces its own argument, so `ABS(A/B)` with `B = 0`
      // raises `_ArithmeticFailure` during preprocessing — outside the catch
      // that turns it into a `FormulaException`. The poller only handles
      // `FormulaException`, so the raw failure took out the whole polling
      // cycle through the loop's outer catch, without invalidating the reading
      // or recording a fault: the previous value stayed on the gauge,
      // presented as current.
      final prepared = _preprocess(
        equation,
        dataBytes,
        requester,
        now,
        elapsed,
      );
      result = _reduce(prepared, equation);
    } on _ArithmeticFailure catch (e) {
      throw FormulaException(e.message, equation, issue: e.issue);
    }
    // NaN and infinity render as "--" at best and as a garbage gauge position
    // at worst; neither is a reading.
    if (result.isNaN || result.isInfinite) {
      throw FormulaException(
        '運算結果不是有效數值',
        equation,
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return result;
  }

  /// Strips the positive-response header off a **user-typed** hex sample and
  /// returns the data bytes that `A`..`N` bind to.
  ///
  /// Named for its only legitimate input. The first line below deletes every
  /// non-hex character and concatenates what is left — the blacklist strip that
  /// this project's hard rules forbid on anything that came off the wire.
  /// `DATA ERROR` survives it as `DA AE`: two bytes, plausible magnitudes, no
  /// way downstream to tell them from a sensor reading. A pinned test in
  /// `test/formula_engine_test.dart` asserts exactly that byte pair, so the
  /// hazard is recorded rather than assumed.
  ///
  /// It is deliberately kept anyway, because the two call sites take text a
  /// person typed into the PID editor's 測試用回應位元組 field: someone pasting
  /// `41 0C 1A F0` from a forum post, with whatever punctuation came along.
  /// There is no adapter on that path and no reading is published from it — the
  /// worst case is a wrong number in a preview the author is actively looking
  /// at.
  ///
  /// **No adapter-sourced string may reach here.** Wire data goes through the
  /// whitelist in `Elm327Client._hexLine`, which accepts only lines that are
  /// entirely hex byte pairs, and then arrives as `List<int>` at
  /// [evaluateBytes]. A companion test asserts that nothing under `lib/obd/`
  /// calls the string-taking overload above, which is the only route from a
  /// response line into this function.
  static List<int> parseUserTypedSampleBytes(
    String payload, {
    bool stripResponsePrefix = false,
  }) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return const [];
    final upper = trimmed.toUpperCase();
    const refused = <String>[
      'DATA ERROR',
      'CAN ERROR',
      'BUS ERROR',
      'NO DATA',
      'STOPPED',
      'UNABLE TO CONNECT',
      'SEARCHING',
      'BUS INIT',
    ];
    for (final token in refused) {
      if (upper.contains(token)) {
        throw FormulaException(
          '測試用回應不是十六進位位元組',
          payload,
          issue: FormulaIssue.unparsableTerm,
          term: token,
        );
      }
    }
    if (RegExp(r'[^0-9A-Fa-f\s,:\-]').hasMatch(trimmed)) {
      throw FormulaException(
        '測試用回應含有不是十六進位的字元',
        payload,
        issue: FormulaIssue.unparsableTerm,
        term: trimmed,
      );
    }
    final hex = trimmed.replaceAll(RegExp(r'[\s,:\-]'), '');
    if (hex.length.isOdd) {
      throw FormulaException(
        '測試用回應的十六進位長度是奇數',
        payload,
        issue: FormulaIssue.unparsableTerm,
        term: trimmed,
      );
    }
    final all = <int>[];
    for (var i = 0; i + 1 < hex.length; i += 2) {
      final b = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (b == null) {
        throw FormulaException(
          '測試用回應不是十六進位位元組',
          payload,
          issue: FormulaIssue.unparsableTerm,
          term: trimmed,
        );
      }
      all.add(b);
    }
    if (!stripResponsePrefix || all.length < 2) return all;

    // Prefix stripping is opt-in. A data byte that happens to be 0x41 or
    // 0x62 must not disappear just because it looks like a positive response.
    if (all[0] == 0x62 && all.length >= 4) return all.sublist(3);
    if ((all[0] & 0xF0) == 0x40 && all.length >= 3) return all.sublist(2);
    return all;
  }

  String _preprocess(
    String equation,
    List<int> bytes,
    Pid? requester,
    DateTime? now, [
    Duration? elapsed,
  ]) {
    var s = equation.replaceAll(' ', '').toUpperCase();
    // Normalise the Unicode minus that sneaks in from copy-pasted formulas.
    s = s.replaceAll('−', '-');

    if (s.contains('BARO')) {
      if (requester == null) {
        throw FormulaException(
          '無法判斷 BARO 所屬的控制器，拒絕求值',
          equation,
          issue: FormulaIssue.baroControllerUnknown,
        );
      }
      final controller = _controllerKey(requester.header);
      if (_baroAmbiguous.contains(controller)) {
        throw FormulaException(
          '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。'
          '請移除其中一個測量大氣壓力的錶。',
          equation,
          issue: FormulaIssue.baroTwoDefinitions,
        );
      }
      final baro = _baro[controller];
      // Absent ambient pressure is not sea level. Refusing here is what turns
      // "wrong by the altitude" into "unavailable", which the gauge can show.
      if (baro == null) {
        throw FormulaException(
          '尚未取得大氣壓力量測值，無法計算',
          equation,
          issue: FormulaIssue.baroNotYetMeasured,
        );
      }
      // `now == null` is the authoring path, which has no measurements to age.
      if (now != null &&
          _expired(
            now,
            baro.at,
            maxCacheAge,
            elapsed: elapsed,
            receivedElapsed: baro.receivedElapsed,
          )) {
        throw FormulaException(
          '大氣壓力量測值已過期，無法計算',
          equation,
          issue: FormulaIssue.baroMeasurementStale,
        );
      }
      s = s.replaceAll('BARO', _format(baro.value));
    }

    s = s.replaceAllMapped(_valPattern, (m) {
      final key = m.group(1)!;
      // `VAL{}` names a PID on *some* controller. Without knowing which one is
      // asking, the reference cannot be resolved to a specific sensor — and
      // resolving it to whichever controller wrote the key last is the defect.
      if (requester == null) {
        throw FormulaException(
          '無法判斷 VAL{$key} 所屬的控制器，拒絕求值',
          equation,
          issue: FormulaIssue.dependencyControllerUnknown,
          pidKey: key,
        );
      }
      // `now == null` is the authoring path, which has no measurements to age
      // — the same exemption BARO gets a few lines above, for the same reason.
      final cached = cachedPidValue(
        requester,
        key,
        now: now ?? _pidCache[_cacheKey(requester.header, key)]?.at,
        elapsed: elapsed,
      );
      // Substituting zero for a PID that has not been read yet is how a boost
      // gauge ends up displaying raw manifold pressure: `A-VAL{0133}` quietly
      // becomes `A-0`. Refuse until the dependency actually exists — and until
      // it is fresh, because a dependency that stopped answering leaves a
      // number that looks exactly like one that is still arriving.
      if (cached == null) {
        final ambiguous = isAmbiguous(requester.header, key);
        throw FormulaException(
          ambiguous
              // Not "remove one of the gauges", which is advice that can be
              // followed exactly and change nothing. `PollingEngine` merges
              // `PidLibrary.physicsInputs` into the active set on every
              // update, so `010B`, `010C` and `010D` are read whether or not a
              // gauge for them is on the dashboard — take the MAP gauge off
              // and the ambiguity is still there, with nothing on screen left
              // to remove. The action that works is changing the *definition*.
              ? '有兩個定義同時解讀 $key，數值可能是其中任何一個，因此無法採用。'
                  '請讓其中一個改用不同的模式+PID。'
                  '注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，'
                  '把面板上的錶移掉不會停止讀取它們。'
              : '尚未取得相依 PID $key 的有效數值',
          equation,
          // Two facts, not one identifier with a flag. "Nobody has read this
          // yet" is waited out; "two definitions decode it" is only fixed by
          // editing one of them, and the copy for the second says so at
          // length.
          issue: ambiguous
              ? FormulaIssue.dependencyTwoDefinitions
              : FormulaIssue.dependencyNotYetMeasured,
          pidKey: key,
        );
      }
      return _format(cached);
    });

    s = s.replaceAllMapped(_signedPattern, (m) {
      final letter = m.group(1)!;
      final index = letter.codeUnitAt(0) - 0x41; // 'A'
      if (index >= bytes.length) {
        throw FormulaException(
          '公式參照位元組 $letter，但回應只有 ${bytes.length} 個位元組',
          equation,
          // One identifier for both throw sites, deliberately. `SIGNED(C)` and
          // a bare `C` are two spellings of one fact — the formula named a
          // byte the reply does not contain — with one remedy, and which
          // spelling was used is not something the reader has to be told: the
          // letter is carried as data and the sentence names it.
          issue: FormulaIssue.byteBeyondResponse,
          byteLetter: letter,
          byteCount: bytes.length,
        );
      }
      final raw = bytes[index];
      return _format((raw >= 128 ? raw - 256 : raw).toDouble());
    });

    // Shield function names before single-letter substitution, otherwise the
    // `A` in `ABS`/`MAX` and the `M`/`I`/`N` in `MIN` would be replaced by
    // byte values. `min(` / `max(` are restored as `MIN(` / `MAX(` so a
    // Torque CSV that used wiki case still evaluates.
    s = s
        .replaceAll('ABS(', _absSentinel)
        .replaceAll('LOG10(', _log10Sentinel)
        .replaceAllMapped(
          _namedCallPattern('LOG1P'),
          (m) => '${m.group(1)}$_log1pSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('SIGNED16'),
          (m) => '${m.group(1)}$_signed16Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('SIGNED8'),
          (m) => '${m.group(1)}$_signed8Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('SIGNED24'),
          (m) => '${m.group(1)}$_signed24Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('SIGNED32'),
          (m) => '${m.group(1)}$_signed32Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('FLOAT32'),
          (m) => '${m.group(1)}$_float32Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('INT32'),
          (m) => '${m.group(1)}$_int32Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('RANDOM'),
          (m) => '${m.group(1)}$_randomSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('INT24'),
          (m) => '${m.group(1)}$_int24Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('INT'),
          (m) => '${m.group(1)}$_intSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('FLOAT64'),
          (m) => '${m.group(1)}$_float64Sentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('LOG'),
          (m) => '${m.group(1)}$_logSentinel',
        )
        .replaceAll('SQRT(', _sqrtSentinel)
        .replaceAllMapped(
          _namedCallPattern('MIN'),
          (m) => '${m.group(1)}$_minSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('MAX'),
          (m) => '${m.group(1)}$_maxSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('BIT'),
          (m) => '${m.group(1)}$_bitSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('SIN'),
          (m) => '${m.group(1)}$_sinSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('COS'),
          (m) => '${m.group(1)}$_cosSentinel',
        )
        .replaceAllMapped(
          _namedCallPattern('TAN'),
          (m) => '${m.group(1)}$_tanSentinel',
        );

    for (var i = 0; i < 14; i++) {
      final letter = String.fromCharCode(0x41 + i);
      final pattern = RegExp('\\b$letter\\b');
      if (!pattern.hasMatch(s)) continue;

      // Substituting 0 for a byte the ECU did not send produces a confident
      // wrong number rather than an error — a truncated RPM reply would read
      // 1664 instead of 1724 and nothing would look amiss. Refuse instead.
      if (i >= bytes.length) {
        throw FormulaException(
          '公式參照位元組 $letter，但回應只有 ${bytes.length} 個位元組',
          equation,
          // One identifier for both throw sites, deliberately. `SIGNED(C)` and
          // a bare `C` are two spellings of one fact — the formula named a
          // byte the reply does not contain — with one remedy, and which
          // spelling was used is not something the reader has to be told: the
          // letter is carried as data and the sentence names it.
          issue: FormulaIssue.byteBeyondResponse,
          byteLetter: letter,
          byteCount: bytes.length,
        );
      }
      s = s.replaceAll(pattern, bytes[i].toString());
    }

    s = s
        .replaceAll(_absSentinel, 'ABS(')
        .replaceAll(_log10Sentinel, 'LOG10(')
        .replaceAll(_log1pSentinel, 'LOG1P(')
        .replaceAll(_signed16Sentinel, 'SIGNED16(')
        .replaceAll(_signed8Sentinel, 'SIGNED8(')
        .replaceAll(_signed24Sentinel, 'SIGNED24(')
        .replaceAll(_signed32Sentinel, 'SIGNED32(')
        .replaceAll(_float32Sentinel, 'FLOAT32(')
        .replaceAll(_int32Sentinel, 'INT32(')
        .replaceAll(_randomSentinel, 'RANDOM(')
        .replaceAll(_int24Sentinel, 'INT24(')
        .replaceAll(_intSentinel, 'INT(')
        .replaceAll(_float64Sentinel, 'FLOAT64(')
        .replaceAll(_logSentinel, 'LOG(')
        .replaceAll(_sqrtSentinel, 'SQRT(')
        .replaceAll(_minSentinel, 'MIN(')
        .replaceAll(_maxSentinel, 'MAX(')
        .replaceAll(_bitSentinel, 'BIT(')
        .replaceAll(_sinSentinel, 'SIN(')
        .replaceAll(_cosSentinel, 'COS(')
        .replaceAll(_tanSentinel, 'TAN(');

    // Alternating, not one pass each in a fixed order.
    //
    // Both patterns exclude parentheses so that each pass necessarily collapses
    // an *innermost* call. Running ABS once and then LOG10 once therefore made
    // exactly one nesting order work: `LOG10(ABS(A))` reduced, `ABS(LOG10(A))`
    // did not — ABS could not see past the inner parentheses on its pass, and
    // by the time LOG10 had removed them ABS was over. The formula was refused
    // at authoring time with nothing wrong in it.
    //
    // `_unwrapFunctionParens` handles the other shape a user writes by habit,
    // `ABS((A-1))`, where the argument is parenthesised for its own sake.
    //
    // Each pass either shrinks the string or leaves it alone, so the loop ends.
    var previous = '';
    var guard = 0;
    while (previous != s) {
      if (++guard > 64) {
        throw FormulaException(
          '公式的函式巢狀太深',
          equation,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      previous = s;
      s = _applyFunction(s, _absPattern, equation, (v) => v.abs());
      // `LOG10` of zero or a negative number is undefined, and answering 0
      // makes an impossible input look like an ordinary reading:
      // `LOG10(A-128)` with `A = 0` displayed a confident 0 rather than
      // admitting the expression has no value there.
      s = _applyFunction(s, _log10Pattern, equation, (v) {
        if (v <= 0) {
          throw FormulaException(
            'LOG10 的引數必須大於 0（收到 $v）',
            equation,
            issue: FormulaIssue.log10NonPositiveArgument,
            argument: v,
          );
        }
        return math.log(v) / math.ln10;
      });
      // Wiki `LOG` is ln, not LOG10. Answering LOG10's value here would be a
      // confident wrong number for every argument except 1.
      s = _applyPrefixedFunction(s, _logPattern, equation, (v) {
        if (v <= 0) {
          throw FormulaException(
            'LOG 的引數必須大於 0（收到 $v）',
            equation,
            issue: FormulaIssue.logNonPositiveArgument,
            argument: v,
          );
        }
        return math.log(v);
      });
      // Wiki LOG1P is ln(1+x), matching Java Math.log1p. Dart 3.13 has no
      // math.log1p. `log(1+v)` rounds 1+1e-16 to 1 and answers 0 — a
      // confident wrong number the formatter was built not to invent.
      s = _applyPrefixedFunction(s, _log1pPattern, equation, (v) {
        if (!v.isFinite || v <= -1) {
          throw FormulaException(
            '運算結果不是有效數值',
            equation,
            issue: FormulaIssue.resultNotFinite,
          );
        }
        return _log1p(v);
      });
      // Wiki SIGNED16(value) is 16-bit two's complement of that number, not
      // 8-bit SIGNED(A) and not INT16(A:B). Java `(short)` of the toward-zero
      // integer; non-finite is refused rather than becoming 0.
      s = _applyUnaryNamedFunction(s, 'SIGNED16', equation, _signed16);
      // Wiki SIGNED8(value) is the same 8-bit conversion as SIGNED(letter).
      s = _applyUnaryNamedFunction(s, 'SIGNED8', equation, _signed8);
      // Wiki SIGNED24(value) is 24-bit two's complement, not SIGNED8/16.
      s = _applyUnaryNamedFunction(s, 'SIGNED24', equation, _signed24);
      // Wiki SIGNED32(value) is 32-bit two's complement, not SIGNED8/16/24.
      s = _applyUnaryNamedFunction(s, 'SIGNED32', equation, _signed32);
      // Wiki FLOAT32(A:B:C:D) is IEEE754 binary32. A is the most significant
      // byte. Inf/NaN is refused rather than becoming 0.
      s = _applyNaryFunction(s, 'FLOAT32', equation, 4, _float32);
      // Wiki INT(value) converts to an integer toward zero, not floor and
      // not INT16(A:B). Non-finite is refused rather than becoming 0.
      s = _applyUnaryNamedFunction(s, 'INT', equation, _int);
      // Wiki FLOAT64(A:B:C:D:E:F:G:H) is IEEE754 binary64. A is the most
      // significant byte. Inf/NaN is refused rather than becoming 0.
      s = _applyNaryFunction(s, 'FLOAT64', equation, 8, _float64);
      // Wiki INT24(A:B:C) is an unsigned 24-bit int. A is the most
      // significant byte. Not SIGNED24 and not INT16.
      s = _applyNaryFunction(s, 'INT24', equation, 3, _int24);
      // Wiki INT32(A:B:C:D) is an unsigned 32-bit int. A is the most
      // significant byte. Not SIGNED32 and not INT16.
      s = _applyNaryFunction(s, 'INT32', equation, 4, _int32);
      // Wiki RANDOM() is a number between 0 and 1. Dart Random.nextDouble
      // matches Java Math.random: [0, 1). Arguments are not a call.
      s = _applyNaryFunction(s, 'RANDOM', equation, 0, _randomCall);
      s = _applyFunction(s, _sqrtPattern, equation, (v) {
        if (v < 0) {
          throw FormulaException(
            'SQRT 的引數必須大於或等於 0（收到 $v）',
            equation,
            issue: FormulaIssue.sqrtNegativeArgument,
            argument: v,
          );
        }
        return math.sqrt(v);
      });
      // Wiki does not name the unit. Dart/Java `sin` is radians; answering
      // degrees here would be a confident wrong number for every nonzero
      // argument.
      s = _applyPrefixedFunction(s, _sinPattern, equation, math.sin);
      s = _applyPrefixedFunction(s, _cosPattern, equation, math.cos);
      s = _applyPrefixedFunction(s, _tanPattern, equation, math.tan);
      s = _applyBinaryFunction(
        s,
        'MIN',
        equation,
        (a, b) => math.min(a, b),
      );
      s = _applyBinaryFunction(
        s,
        'MAX',
        equation,
        (a, b) => math.max(a, b),
      );
      s = _applyBinaryFunction(
        s,
        'BIT',
        equation,
        (value, bit) {
          // toInt() on NaN/infinity throws UnsupportedError, which the
          // poller does not catch — the previous reading stays on the
          // gauge. Preflight uses small sample bytes, so BIT(A^B:0) can
          // look well-formed and still overflow on live data.
          if (!value.isFinite) {
            throw FormulaException(
              '運算結果不是有效數值',
              equation,
              issue: FormulaIssue.resultNotFinite,
            );
          }
          if (!bit.isFinite || bit != bit.truncateToDouble() || bit < 0) {
            throw FormulaException(
              'Cannot parse "$bit"',
              equation,
              issue: FormulaIssue.unparsableTerm,
              term: bit.toString(),
            );
          }
          return ((value.toInt() >> bit.toInt()) & 1).toDouble();
        },
      );
      s = _unwrapFunctionParens(s, equation);
    }

    return s;
  }

  /// A function whose argument is itself parenthesised: `ABS((A-1))`.
  ///
  /// The function patterns exclude parentheses so each pass targets an
  /// innermost call, which means they cannot see this shape at all — and it is
  /// how people write. Reducing the inner group turns it back into something
  /// the ordinary pass matches on the next turn.
  static final RegExp _functionWrappedParens =
      RegExp(r'(ABS|LOG10|LOG1P|LOG|SQRT|SIN|COS|TAN|SIGNED16|SIGNED8|SIGNED24|SIGNED32|INT)\(\s*(\([^()]*\))\s*\)');

  String _unwrapFunctionParens(String input, String source) {
    var s = input;
    var guard = 0;
    while (true) {
      final match = _functionWrappedParens.firstMatch(s);
      if (match == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          '公式的括號巢狀太深',
          source,
          issue: FormulaIssue.parenthesisNestingTooDeep,
        );
      }
      final inner = _reduce(match.group(2)!, source);
      s = s.replaceRange(
          match.start, match.end, '${match.group(1)}(${_format(inner)})');
    }
  }

  /// ln(1+x) without cancelling tiny x the way `log(1+x)` does.
  ///
  /// When `1+x` rounds to 1, `log(1+x)` is 0. Java `Math.log1p` returns x.
  /// Dart 3.13 has no `math.log1p`; this is the fdlibm identity.
  static double _log1p(double x) {
    final y = 1.0 + x;
    if (y == 1.0) return x;
    return math.log(y) * x / (y - 1.0);
  }

  /// Two's complement of the low 16 bits of the toward-zero integer.
  ///
  /// Wiki: "Treats the incoming value as 16bit signed". Java `(short)` does
  /// the same bit truncation. `NaN`/`Infinity` must not become 0.
  static double _signed16(double x) {
    if (!x.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    final bits = x.toInt() & 0xFFFF;
    return (bits >= 32768 ? bits - 65536 : bits).toDouble();
  }

  /// Two's complement of the low 8 bits of the toward-zero integer.
  ///
  /// Wiki: "same as the 'SIGNED' function". `NaN`/`Infinity` must not become 0.
  static double _signed8(double x) {
    if (!x.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    final bits = x.toInt() & 0xFF;
    return (bits >= 128 ? bits - 256 : bits).toDouble();
  }

  /// Two's complement of the low 24 bits of the toward-zero integer.
  ///
  /// Wiki: "Treats the incoming value as 24bit signed". `NaN`/`Infinity`
  /// must not become 0.
  static double _signed24(double x) {
    if (!x.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    final bits = x.toInt() & 0xFFFFFF;
    return (bits >= 0x800000 ? bits - 0x1000000 : bits).toDouble();
  }

  /// Two's complement of the low 32 bits of the toward-zero integer.
  ///
  /// Wiki: "Treats the incoming value as 32bit signed". `NaN`/`Infinity`
  /// must not become 0.
  static double _signed32(double x) {
    if (!x.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    final bits = x.toInt() & 0xFFFFFFFF;
    return (bits >= 0x80000000 ? bits - 0x100000000 : bits).toDouble();
  }

  /// IEEE754 binary32 from four inputs. A is the most significant byte.
  ///
  /// Wiki: "Returns an IEEE754 float based on the supplied 4 inputs".
  /// Each input uses the toward-zero integer's low 8 bits. Inf/NaN must
  /// not become 0. Little-endian payloads are written `FLOAT32(D:C:B:A)`.
  static double _float32(List<double> parts) {
    for (final x in parts) {
      if (!x.isFinite) {
        throw const FormulaException(
          '運算結果不是有效數值',
          '',
          issue: FormulaIssue.resultNotFinite,
        );
      }
    }
    final bytes = Uint8List(4);
    for (var i = 0; i < 4; i++) {
      bytes[i] = parts[i].toInt() & 0xFF;
    }
    final value = ByteData.sublistView(bytes).getFloat32(0, Endian.big);
    if (!value.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return value;
  }

  /// Toward-zero integer of a finite value.
  ///
  /// Wiki: "Converts the incoming number to an integer". Dart `toInt()` and
  /// Java `(int)` of a value in range both truncate toward zero; floor would
  /// turn `INT(-1.9)` into -2. Non-finite must not become 0. Not `INT16`.
  static double _int(double x) {
    if (!x.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return x.toInt().toDouble();
  }

  /// IEEE754 binary64 from eight inputs. A is the most significant byte.
  ///
  /// Wiki: "Returns an IEEE754 float based on the supplied 8 (value:0-255)
  /// inputs". Each input uses the toward-zero integer's low 8 bits. Inf/NaN
  /// must not become 0. Not `FLOAT32`.
  static double _float64(List<double> parts) {
    for (final x in parts) {
      if (!x.isFinite) {
        throw const FormulaException(
          '運算結果不是有效數值',
          '',
          issue: FormulaIssue.resultNotFinite,
        );
      }
    }
    final bytes = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      bytes[i] = parts[i].toInt() & 0xFF;
    }
    final value = ByteData.sublistView(bytes).getFloat64(0, Endian.big);
    if (!value.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return value;
  }

  /// Unsigned 24-bit integer from three inputs. A is the most significant byte.
  ///
  /// Wiki: "Returns a 24bit int from the input values". Each input uses the
  /// toward-zero integer's low 8 bits. `INT24(128:0:0)` is 8388608, not
  /// `SIGNED24`'s -8388608. Not `INT16`.
  static double _int24(List<double> parts) {
    for (final x in parts) {
      if (!x.isFinite) {
        throw const FormulaException(
          '運算結果不是有效數值',
          '',
          issue: FormulaIssue.resultNotFinite,
        );
      }
    }
    final a = parts[0].toInt() & 0xFF;
    final b = parts[1].toInt() & 0xFF;
    final c = parts[2].toInt() & 0xFF;
    return ((a << 16) | (b << 8) | c).toDouble();
  }

  /// Unsigned 32-bit integer from four inputs. A is the most significant byte.
  ///
  /// Wiki: "Returns a 32bit int from the input values". Each input uses the
  /// toward-zero integer's low 8 bits. `INT32(128:0:0:0)` is 2147483648, not
  /// `SIGNED32`'s -2147483648. Not `INT16`.
  static double _int32(List<double> parts) {
    for (final x in parts) {
      if (!x.isFinite) {
        throw const FormulaException(
          '運算結果不是有效數值',
          '',
          issue: FormulaIssue.resultNotFinite,
        );
      }
    }
    final a = parts[0].toInt() & 0xFF;
    final b = parts[1].toInt() & 0xFF;
    final c = parts[2].toInt() & 0xFF;
    final d = parts[3].toInt() & 0xFF;
    return ((a << 24) | (b << 16) | (c << 8) | d).toDouble();
  }

  /// Wiki `RANDOM()`: a number between 0 and 1.
  ///
  /// Dart `Random.nextDouble` and Java `Math.random` are `[0, 1)`.
  /// Non-finite must not become 0. Not `BARO()`.
  double _randomCall(List<double> parts) {
    final value = _random();
    if (!value.isFinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return value;
  }

  /// Repeatedly collapses the innermost `NAME(...)` call until none remain.
  /// The pattern excludes nested parens, so each pass necessarily targets an
  /// innermost call and the string strictly shrinks.
  String _applyFunction(
    String input,
    RegExp pattern,
    String source,
    double Function(double) fn,
  ) {
    var s = input;
    var guard = 0;
    while (true) {
      final match = pattern.firstMatch(s);
      if (match == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          'Formula nests functions too deeply',
          source,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      final inner = _reduce(match.group(1)!, source);
      s = s.replaceRange(match.start, match.end, _format(fn(inner)));
    }
  }

  /// Like [_applyFunction], but group 1 is a preceding non-identifier kept
  /// in place so `2*LOG(1)` reduces and `2LOG(1)` does not become `20`.
  String _applyPrefixedFunction(
    String input,
    RegExp pattern,
    String source,
    double Function(double) fn,
  ) {
    var s = input;
    var guard = 0;
    while (true) {
      final match = pattern.firstMatch(s);
      if (match == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          'Formula nests functions too deeply',
          source,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      final inner = _reduce(match.group(2)!, source);
      s = s.replaceRange(
        match.start,
        match.end,
        '${match.group(1)}${_format(fn(inner))}',
      );
    }
  }

  /// Unary wiki `SIGNED16(value)`. Grouping is allowed (`SIGNED16((A*256)+B)`);
  /// `2SIGNED16(0)` is not a call, matching LOG1P token boundaries.
  String _applyUnaryNamedFunction(
    String input,
    String name,
    String source,
    double Function(double) fn,
  ) {
    var s = input;
    var guard = 0;
    while (true) {
      final call = _innermostBinaryCall(s, name);
      if (call == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          'Formula nests functions too deeply',
          source,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      final value = fn(_reduce(call.inner, source));
      s = s.replaceRange(call.start, call.end, _format(value));
    }
  }

  /// Torque wiki `MIN(A:B)` / `MAX(A:B)`. A single comma is accepted too
  /// (`MAX(A,B)`); two separators or an empty side is not a two-argument call.
  /// Arguments may be grouped: `MIN((A+1):B)` is not `unparsableTerm`.
  String _applyBinaryFunction(
    String input,
    String name,
    String source,
    double Function(double, double) fn,
  ) {
    var s = input;
    var guard = 0;
    while (true) {
      final call = _innermostBinaryCall(s, name);
      if (call == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          'Formula nests functions too deeply',
          source,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      final parts = _splitBinaryArgs(call.inner);
      if (parts == null) {
        throw FormulaException(
          'Cannot parse "${call.inner}"',
          source,
          issue: FormulaIssue.unparsableTerm,
          term: call.inner,
        );
      }
      final value = fn(_reduce(parts[0], source), _reduce(parts[1], source));
      s = s.replaceRange(call.start, call.end, _format(value));
    }
  }

  /// Wiki `FLOAT32(A:B:C:D)`. A single comma form is accepted too
  /// (`FLOAT32(A,B,C,D)`); the wrong number of sides is not a four-argument
  /// call. Arguments may be grouped: `FLOAT32((A-1):B:C:D)`.
  String _applyNaryFunction(
    String input,
    String name,
    String source,
    int arity,
    double Function(List<double>) fn,
  ) {
    var s = input;
    var guard = 0;
    while (true) {
      final call = _innermostBinaryCall(s, name);
      if (call == null) return s;
      if (++guard > 64) {
        throw FormulaException(
          'Formula nests functions too deeply',
          source,
          issue: FormulaIssue.functionNestingTooDeep,
        );
      }
      final parts = _splitNaryArgs(call.inner, arity);
      if (parts == null) {
        throw FormulaException(
          'Cannot parse "${call.inner}"',
          source,
          issue: FormulaIssue.unparsableTerm,
          term: call.inner,
        );
      }
      final values = [for (final part in parts) _reduce(part, source)];
      s = s.replaceRange(call.start, call.end, _format(fn(values)));
    }
  }

  /// Leftmost `NAME(...)` whose argument list does not still contain `ABS(`,
  /// `LOG10(`, `LOG(`, `MIN(` or `MAX(`. Grouping parentheses are allowed.
  static ({int start, int end, String inner})? _innermostBinaryCall(
    String input,
    String name,
  ) {
    final needle = '$name(';
    var from = 0;
    while (true) {
      final start = input.indexOf(needle, from);
      if (start < 0) return null;
      if (start > 0 && _isIdentChar(input.codeUnitAt(start - 1))) {
        from = start + 1;
        continue;
      }
      var depth = 0;
      var end = -1;
      for (var i = start + name.length; i < input.length; i++) {
        final c = input[i];
        if (c == '(') {
          depth++;
        } else if (c == ')') {
          depth--;
          if (depth == 0) {
            end = i + 1;
            break;
          }
        }
      }
      if (end < 0) return null;
      if (end < input.length && _isIdentChar(input.codeUnitAt(end))) {
        from = start + 1;
        continue;
      }
      final inner = input.substring(start + needle.length, end - 1);
      if (!_innerStillHasFunction(inner)) {
        return (start: start, end: end, inner: inner);
      }
      from = start + 1;
    }
  }

  static bool _innerStillHasFunction(String inner) =>
      inner.contains('ABS(') ||
      inner.contains('LOG10(') ||
      inner.contains('LOG1P(') ||
      inner.contains('LOG(') ||
      inner.contains('SQRT(') ||
      inner.contains('SIN(') ||
      inner.contains('COS(') ||
      inner.contains('TAN(') ||
      inner.contains('SIGNED16(') ||
      inner.contains('SIGNED8(') ||
      inner.contains('SIGNED24(') ||
      inner.contains('SIGNED32(') ||
      inner.contains('FLOAT32(') ||
      inner.contains('INT(') ||
      inner.contains('INT24(') ||
      inner.contains('INT32(') ||
      inner.contains('RANDOM(') ||
      inner.contains('FLOAT64(') ||
      inner.contains('MIN(') ||
      inner.contains('MAX(') ||
      inner.contains('BIT(');

  static bool _isIdentChar(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x5F;

  static RegExp _namedCallPattern(String name) =>
      RegExp('(^|[^A-Za-z0-9_])${RegExp.escape(name)}\\(', caseSensitive: false);

  /// Splits `A:B` or `A,B` into exactly two nonempty sides.
  /// A colon or comma inside grouping parentheses is not a separator.
  static List<String>? _splitBinaryArgs(String inner) {
    var sep = -1;
    var depth = 0;
    for (var i = 0; i < inner.length; i++) {
      final c = inner[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
      } else if (depth == 0 && (c == ':' || c == ',')) {
        if (sep != -1) return null;
        sep = i;
      }
    }
    if (sep < 0 || depth != 0) return null;
    final left = inner.substring(0, sep).trim();
    final right = inner.substring(sep + 1).trim();
    if (left.isEmpty || right.isEmpty) return null;
    return [left, right];
  }

  /// Splits `A:B:C:D` or `A,B,C,D` into exactly [arity] nonempty sides.
  /// A colon or comma inside grouping parentheses is not a separator.
  /// Arity 0 is `NAME()` with an empty argument list.
  static List<String>? _splitNaryArgs(String inner, int arity) {
    if (arity == 0) {
      return inner.trim().isEmpty ? <String>[] : null;
    }
    final parts = <String>[];
    var start = 0;
    var depth = 0;
    for (var i = 0; i < inner.length; i++) {
      final c = inner[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
      } else if (depth == 0 && (c == ':' || c == ',')) {
        final part = inner.substring(start, i).trim();
        if (part.isEmpty) return null;
        parts.add(part);
        start = i + 1;
      }
    }
    if (depth != 0) return null;
    final last = inner.substring(start).trim();
    if (last.isEmpty) return null;
    parts.add(last);
    if (parts.length != arity) return null;
    return parts;
  }

  double _reduce(String expression, String source) {
    var s = expression.trim();
    if (s.isEmpty) {
      throw FormulaException(
        'Empty sub-expression',
        source,
        issue: FormulaIssue.emptySubExpression,
      );
    }

    // Collapse parentheses innermost-first.
    var guard = 0;
    while (s.contains('(')) {
      if (++guard > 256) {
        throw FormulaException(
          'Formula nests parentheses too deeply',
          source,
          issue: FormulaIssue.parenthesisNestingTooDeep,
        );
      }
      final close = s.indexOf(')');
      if (close == -1) {
        throw FormulaException(
          'Unbalanced parentheses',
          source,
          issue: FormulaIssue.unbalancedParentheses,
        );
      }
      final open = s.lastIndexOf('(', close);
      if (open == -1) {
        throw FormulaException(
          'Unbalanced parentheses',
          source,
          issue: FormulaIssue.unbalancedParentheses,
        );
      }
      final value = _reduce(s.substring(open + 1, close), source);
      s = s.replaceRange(open, close + 1, _format(value));
    }

    final literal = double.tryParse(s);
    if (literal != null) return literal;

    for (final level in _levels) {
      // Right-most match across the whole level, so equal-precedence operators
      // associate left to right: 10-5-2 is (10-5)-2, not 10-(5-2).
      var bestIndex = -1;
      _Operator? bestOp;
      for (final op in level) {
        final index = _findBinaryOperator(s, op.symbol);
        if (index > bestIndex) {
          bestIndex = index;
          bestOp = op;
        }
      }
      if (bestIndex > 0 && bestOp != null) {
        final left = _reduce(s.substring(0, bestIndex), source);
        final right = _reduce(s.substring(bestIndex + bestOp.symbol.length), source);
        return bestOp.apply(left, right);
      }
    }

    // Unary sign is resolved before exponentiation but after every binary
    // level above, which is what makes `-A^2` evaluate to `-(A^2)`.
    if (s.startsWith('-')) return -_reduce(s.substring(1), source);
    if (s.startsWith('+')) return _reduce(s.substring(1), source);

    // Exponentiation is right-associative: 2^3^2 is 2^(3^2) = 512. Splitting on
    // the right-most `^` (as every other level does) would give (2^3)^2 = 64,
    // so this level takes the *left-most* occurrence instead.
    final powerIndex = s.indexOf(_power.symbol);
    if (powerIndex > 0) {
      return _power.apply(
        _reduce(s.substring(0, powerIndex), source),
        _reduce(s.substring(powerIndex + 1), source),
      );
    }

    // Tighter than `^`: this is a negative value, not a negated expression.
    if (s.startsWith(_negative)) return -_reduce(s.substring(1), source);

    if (s.startsWith('~')) return (~_reduce(s.substring(1), source).toInt()).toDouble();
    if (s.startsWith('!')) return _reduce(s.substring(1), source) == 0.0 ? 1.0 : 0.0;

    throw FormulaException(
      'Cannot parse "$s"',
      source,
      issue: FormulaIssue.unparsableTerm,
      term: s,
    );
  }

  /// Finds the right-most occurrence of [op] that is acting as a binary
  /// operator. Scanning right-to-left and recursing left makes repeated
  /// same-precedence operators associate left-to-right.
  int _findBinaryOperator(String s, String op) {
    for (var i = s.length - 1; i >= 0; i--) {
      if (!s.startsWith(op, i)) continue;
      if (op == '-' && (i == 0 || _unaryContext.contains(s[i - 1]))) {
        continue; // unary sign, not a subtraction
      }
      return i;
    }
    return -1;
  }

  /// Marks a value that is negative *in itself*, as opposed to an expression
  /// with a leading minus sign.
  ///
  /// The distinction is load-bearing. Reducing `(-A)^2` collapses the bracket
  /// first, and splicing the result back as a plain `-3.0` throws away the
  /// author's grouping: the reducer then sees `-3.0^2.0` and correctly applies
  /// the usual rule that a unary minus binds looser than exponentiation,
  /// yielding −9 where the brackets asked for 9. A marked negative binds
  /// tighter than `^`, so both spellings mean what they say.
  static const String _negative = '\u0003';

  /// Renders a double back into the expression string. Plain `toString()` emits
  /// `1e-7` style output for small magnitudes, which the reducer would then
  /// mis-split on the `-`; fixed notation avoids that entirely.
  static String _format(double value) {
    // A non-finite intermediate used to be rendered as `0.0` and the reduction
    // carried on, so `((-1)^0.5)+90` quietly collapsed to 90 — an invalid
    // expression producing a plausible temperature. An evaluation that cannot
    // continue has to say so.
    if (value.isNaN || value.isInfinite) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    final magnitude = value.abs();
    final rendered = magnitude == magnitude.roundToDouble() && magnitude < 1e15
        ? magnitude.toStringAsFixed(1)
        : _fixedWithoutScientific(magnitude);
    // `isNegative`, not `< 0`: IEEE754 -0.0 compares equal to +0 and is not
    // `< 0`, so a FLOAT32 payload of 0x80000000 would otherwise come back as
    // +0 and flip the sign of later arithmetic (`1/x` of -0 is -Inf).
    return value.isNegative ? '$_negative$rendered' : rendered;
  }

  /// Fixed-point so the reducer never sees `1e-7` (it would split on `-`).
  ///
  /// `toStringAsFixed` stops at 20 fractional digits, so a 16-place cutoff
  /// still rounded `4e-18` to zero and `MAX(...)*1e19` published 0. Expand
  /// the shortest round-trip form instead of imposing a place count.
  static String _fixedWithoutScientific(double magnitude) {
    if (magnitude == 0) return '0.0';
    final shortest = magnitude.toString();
    final decimal = _scientificToDecimal(shortest) ?? shortest;
    return _trimFixedZeros(_withoutScientific(decimal, magnitude));
  }

  /// `1.25e-18` / `4e+20` → a decimal with no `e`/`E`/`+`/`-`.
  static String? _scientificToDecimal(String text) {
    final match =
        RegExp(r'^(\d+)(?:\.(\d+))?[eE]([+-]?)(\d+)$').firstMatch(text);
    if (match == null) return null;
    final fracPart = match.group(2) ?? '';
    final exp = int.parse(match.group(4)!);
    final shift = match.group(3) == '-' ? -exp : exp;
    final digits = '${match.group(1)!}$fracPart';
    final k = shift - fracPart.length;
    if (k >= 0) return '$digits${'0' * k}.0';
    final pad = -k - digits.length;
    if (pad >= 0) return '0.${'0' * pad}$digits';
    final split = digits.length + k;
    return '${digits.substring(0, split)}.${digits.substring(split)}';
  }

  static String _withoutScientific(String decimal, double magnitude) {
    if (!_scientificToken.hasMatch(decimal)) return decimal;
    final retry = _scientificToDecimal(magnitude.toStringAsExponential());
    if (retry == null || _scientificToken.hasMatch(retry)) {
      throw const FormulaException(
        '運算結果不是有效數值',
        '',
        issue: FormulaIssue.resultNotFinite,
      );
    }
    return retry;
  }

  static final RegExp _scientificToken = RegExp(r'[eE+-]');

  static String _trimFixedZeros(String rendered) {
    if (!rendered.contains('.')) return rendered;
    rendered = rendered.replaceFirst(RegExp(r'0+$'), '');
    if (rendered.endsWith('.')) return '${rendered}0';
    return rendered;
  }

  /// The PIDs an equation references through `VAL{...}`.
  ///
  /// Exposed so the editor can tell "this formula is malformed" apart from
  /// "this formula depends on a PID that has not been polled yet" — the second
  /// is not an authoring error and must not block saving.
  static Iterable<String> valReferences(String equation) =>
      _valPattern.allMatches(equation.toUpperCase()).map((m) => m.group(1)!);

  /// A stand-in PID used when validating or previewing a formula with no live
  /// data.
  ///
  /// Seeding and resolving both go through it, so an authoring preview can
  /// resolve `VAL{}` without giving the runtime any way to resolve a reference
  /// whose controller is unknown — the two paths share no state.
  static Pid probePid(String modeAndPid) => Pid(
        name: 'probe',
        shortName: 'probe',
        modeAndPid: modeAndPid,
        equation: 'A',
        minValue: 0,
        maxValue: 1,
        units: '',
      );

  /// Seeds stand-in values for every external reference in [equation].
  ///
  /// Authoring is about whether a formula is well-formed. Applying the runtime
  /// rule — refuse until the dependency has actually been measured — would
  /// make every `VAL{}` and `BARO` formula permanently unsaveable, including
  /// the ones the help text recommends.
  void seedForAuthoring(String equation, {double sample = 1}) {
    final at = DateTime.now();
    for (final dependency in valReferences(equation)) {
      cachePidValue(probePid(dependency), sample, at);
    }
    if (equation.toUpperCase().contains('BARO')) {
      setBaroPressure(probePid('0000'), 101.3, at);
    }
  }

  /// Authoring check: well-formedness with stand-in dependencies.
  ///
  /// Runtime-only facts — a live value not yet measured, a stale cache —
  /// do not fail this. CSV import and the editor save gate both call this
  /// rather than each inventing a parser. Returns null when the formula
  /// may be saved.
  static bool _isProbeDomain(FormulaIssue? issue) =>
      issue == FormulaIssue.divisionByZero ||
      issue == FormulaIssue.moduloByZero ||
      issue == FormulaIssue.log10NonPositiveArgument ||
      issue == FormulaIssue.logNonPositiveArgument ||
      issue == FormulaIssue.sqrtNegativeArgument ||
      issue == FormulaIssue.resultNotFinite;

  static bool _isByteDependentRuntimeDomain(FormulaIssue? issue) =>
      issue == FormulaIssue.log10NonPositiveArgument ||
      issue == FormulaIssue.logNonPositiveArgument ||
      issue == FormulaIssue.sqrtNegativeArgument ||
      issue == FormulaIssue.resultNotFinite;

  /// True when [equation] names a Torque reply byte `A`..`N` as its own
  /// token. `ABS(1)` does not: the `A` sits inside the function name.
  static bool _referencesReplyByte(String equation) {
    final s = equation.toUpperCase();
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c < 65 || c > 78) continue;
      final prev = i == 0 ? 0 : s.codeUnitAt(i - 1);
      final next = i + 1 >= s.length ? 0 : s.codeUnitAt(i + 1);
      if (_isIdentChar(prev) || _isIdentChar(next)) continue;
      return true;
    }
    return false;
  }

  static FormulaException? _evaluateAuthoring(
    String equation,
    List<int> sampleBytes, {
    double valStandIn = 1,
  }) {
    try {
      final engine = FormulaEngine()
        ..seedForAuthoring(equation, sample: valStandIn);
      engine.evaluateBytes(
        equation,
        sampleBytes,
        requester: probePid('0000'),
      );
      return null;
    } on FormulaException catch (e) {
      return e;
    } on Error catch (e) {
      // `~1e999` hits `Infinity.toInt()` inside the evaluator. Import must
      // not throw; the row is refused as unparsable.
      return FormulaException(
        '公式求值發生未預期的錯誤',
        equation,
        issue: FormulaIssue.unparsableTerm,
        term: e.runtimeType.toString(),
      );
    }
  }

  static FormulaException? preflight(
    String equation, {
    List<int>? sampleBytes,
  }) {
    final primary = sampleBytes ?? List<int>.filled(14, 1);
    final first = _evaluateAuthoring(equation, primary);
    if (first == null) return null;
    // A formula undefined only at a uniform stand-in (`1/(A-1)`, `1/(A-B)`)
    // is still well-formed. `A/0` fails every probe and stays rejected.
    if (sampleBytes != null || !_isProbeDomain(first.issue)) return first;
    // Constant 1 is also the VAL{} stand-in. `1/(VAL{010C}-1)` is defined at
    // 2 and at the editor's preview stand-in of 100. `A/0` fails every pair.
    const standIns = <double>[1, 2, 100];
    final probes = <List<int>>[
      primary,
      List<int>.filled(14, 2),
      List<int>.generate(14, (i) => i + 1),
      List<int>.generate(14, (i) => 14 - i),
    ];
    var sawArgument = first.argument != null;
    var argumentVaried = false;
    double? seenArgument = first.argument;
    for (final probe in probes) {
      for (final standIn in standIns) {
        if (identical(probe, primary) && standIn == 1) continue;
        final retry = _evaluateAuthoring(
          equation,
          probe,
          valStandIn: standIn,
        );
        if (retry == null) return null;
        if (!_isProbeDomain(retry.issue)) return retry;
        if (retry.argument != null) {
          if (sawArgument && retry.argument != seenArgument) {
            argumentVaried = true;
          }
          seenArgument = retry.argument;
          sawArgument = true;
        }
      }
    }
    // Every finite probe can miss a well-formed domain (`LOG10(A-20)` is
    // negative for 1..14). Adding A=21 would miss `LOG10(A-200)` the same
    // way. A log/sqrt failure whose argument moves with the reply byte is
    // a runtime requirement. The same issue with a constant argument
    // (`LOG10(-1)+A`) stays rejected: the `A` did not produce the failure.
    // `A/0` stays rejected as `divisionByZero`.
    if (_isByteDependentRuntimeDomain(first.issue) &&
        _referencesReplyByte(equation) &&
        (!sawArgument || argumentVaried)) {
      return null;
    }
    return first;
  }

  /// Validates [equation] without live data by evaluating it against a probe
  /// payload. Returns null when the formula is sound, else the error message.
  static String? validate(String equation, {List<int>? sampleBytes}) {
    try {
      return preflight(equation, sampleBytes: sampleBytes)?.message;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Internal signal for an arithmetic domain error, converted to a
/// [FormulaException] at the public boundary.
class _ArithmeticFailure implements Exception {
  final String message;

  /// Not nullable. This one never crosses a package boundary and every throw
  /// of it is in this file, so there is no reason to allow a failure that
  /// cannot say what it was — and `evaluateBytes` can forward it without a
  /// fallback.
  final FormulaIssue issue;

  const _ArithmeticFailure(this.message, this.issue);
}

class _Operator {
  final String symbol;
  final double Function(double, double) apply;

  _Operator(this.symbol, this.apply);
}

/// Torque wiki names this dialect does not implement, detected as `NAME(`.
///
/// `LOG10`/`LOG1P` are not `LOG`, `INT16` is not `INT`, `SIGNED16` is not
/// `SIGNED` or `SIGNED8`, `BARO` without a parenthesis is the ECU cache
/// identifier we do implement. `MIN`/`MAX` are implemented as arity-2 colon
/// or comma. `FLOAT32` is IEEE754 binary32 from four inputs. `INT` is
/// toward-zero truncation. `FLOAT64` is IEEE754 binary64 from eight inputs.
/// `INT24` is an unsigned 24-bit int from three inputs. `INT32` is an
/// unsigned 32-bit int from four inputs. `RANDOM()` is `[0, 1)`. INT16
/// compatibility is still unclaimed (#79).
final _unsupportedTorqueFunctionPattern = RegExp(
  r'\b(EWMAF|TAVG|RAVG|AVG|TDLY|RDLY|TOT|'
  r'INT16|'
  r'LOOKUP|CLOSEST|BARO)\s*\(',
  caseSensitive: false,
);

String? _unsupportedTorqueFunction(String equation) {
  final match = _unsupportedTorqueFunctionPattern.firstMatch(equation);
  return match?.group(1)?.toUpperCase();
}
