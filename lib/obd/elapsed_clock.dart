/// Monotonic elapsed time for freshness, with an explicit sleep policy.
///
/// Android `SystemClock.elapsedRealtime` includes time spent in deep sleep.
/// Dart `Stopwatch` on this VM follows uptime and does not. After a 60s
/// sleep, a Stopwatch-backed sample still looks one second old. This cache
/// names which clock it is using. A failed native mapping does not silently
/// fall back to Stopwatch as if it were elapsedRealtime — continuity is
/// retired, [elapsed] keeps advancing, and [agingElapsed] is far enough ahead
/// of any stamp that every reading is stale.
library;

/// Cached native (or fallback) elapsed time used to stamp and age readings.
class NativeElapsedCache {
  NativeElapsedCache({this.readMs, Duration Function()? tick})
    : _tick = tick ?? _StopwatchTick().call;

  /// Native `elapsedRealtime` milliseconds. Null means this host has no
  /// mapping and [elapsed] follows process uptime, which does **not**
  /// include deep sleep.
  final Future<int?> Function()? readMs;

  final Duration Function() _tick;
  Duration _anchorTick = Duration.zero;
  int? _ms;
  bool unknown = false;

  /// True only while a native reader is bound, has synced, and has not been
  /// retired.
  bool get includesDeepSleep => readMs != null && !unknown && _ms != null;

  static const Duration _retired = Duration(days: 365);
  static const Duration _unknownLead = Duration(days: 1);

  Duration get _extra {
    final extra = _tick() - _anchorTick;
    return extra.isNegative ? Duration.zero : extra;
  }

  /// Time to stamp on a new observation.
  Duration get elapsed {
    if (unknown) return _retired + _extra;
    if (readMs == null) return _tick();
    if (_ms == null) return _retired + _extra;
    return Duration(milliseconds: _ms!) + _extra;
  }

  /// Time to age existing observations.
  ///
  /// When continuity is unknown or not yet synced, this is a day ahead of
  /// [elapsed] so a reading stamped in the same moment is already stale.
  Duration get agingElapsed {
    if (unknown || (readMs != null && _ms == null)) {
      return elapsed + _unknownLead;
    }
    return elapsed;
  }

  Future<void> sync() async {
    final read = readMs;
    if (read == null) return;
    final ms = await read();
    if (ms == null || ms < 0) {
      _markUnknown();
      return;
    }
    if (_ms != null && ms < _ms!) {
      _markUnknown();
      return;
    }
    _ms = ms;
    _anchorTick = _tick();
  }

  void _markUnknown() {
    if (!unknown) _anchorTick = _tick();
    unknown = true;
  }
}

class _StopwatchTick {
  final Stopwatch _sw = Stopwatch()..start();
  Duration call() => _sw.elapsed;
}
