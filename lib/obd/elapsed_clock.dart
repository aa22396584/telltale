/// Monotonic elapsed time for freshness, with an explicit sleep policy.
///
/// Android `SystemClock.elapsedRealtime` includes time spent in deep sleep.
/// Dart `Stopwatch` on this VM follows uptime and does not. After a 60s
/// sleep, a Stopwatch-backed sample still looks one second old. This cache
/// names which clock it is using. A failed native mapping does not silently
/// fall back to Stopwatch as if it were elapsedRealtime — continuity is
/// retired and [elapsed] jumps far enough that every stamped sample is stale.
library;

/// Cached native (or fallback) elapsed time used to stamp and age readings.
class NativeElapsedCache {
  NativeElapsedCache({this.readMs});

  /// Native `elapsedRealtime` milliseconds. Null means this host has no
  /// mapping and [elapsed] follows a process Stopwatch, which does **not**
  /// include deep sleep.
  final Future<int?> Function()? readMs;

  final Stopwatch _fallback = Stopwatch()..start();
  int? _ms;
  bool unknown = false;

  /// True only while a native reader is bound and has not been retired.
  bool get includesDeepSleep => readMs != null && !unknown && _ms != null;

  static const Duration _retired = Duration(days: 365);

  Duration get elapsed {
    if (unknown) return _retired;
    if (readMs == null) return _fallback.elapsed;
    if (_ms == null) return _retired;
    return Duration(milliseconds: _ms!);
  }

  Future<void> sync() async {
    final read = readMs;
    if (read == null) return;
    final ms = await read();
    if (ms == null || ms < 0) {
      unknown = true;
      return;
    }
    if (_ms != null && ms < _ms!) {
      unknown = true;
      return;
    }
    _ms = ms;
  }
}
