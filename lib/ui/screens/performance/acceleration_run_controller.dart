/// Standing-start acceleration timing from OBD road-speed observations.
///
/// Elapsed time is the monotonic [Reading.receivedElapsed] interval, not
/// `DateTime.now()`. Wall UTC stays metadata. A clock step must not change a
/// run whose observation ticks did not change.
///
/// Launch is the first sample at or above [_launchKmh] after a standstill
/// sample. That is a threshold start, not a physically measured 0–100.
library;

import 'package:fl_chart/fl_chart.dart';

enum AccelerationRunState {
  idle,
  awaitingStandstill,
  staged,
  running,
  finished,
  aborted,
}

/// Closed observation window for one event, in seconds on the run clock.
///
/// The run clock is zero at the last standstill sample. This is an
/// observation bracket, not a physical confidence interval.
final class ObservationBracket {
  const ObservationBracket(this.lowerSeconds, this.upperSeconds);

  final double lowerSeconds;
  final double upperSeconds;
}

final class AccelerationRunController {
  AccelerationRunController({int targetKmh = 100}) : _target = targetKmh;

  static const List<int> splitTargetsKmh = [50, 60, 80, 100];

  /// OBD road speed is a whole number; under 2 km/h is standstill.
  static const double standstillKmh = 1;
  static const double launchKmh = 2;
  static const Duration speedAbsenceGrace = Duration(milliseconds: 1500);
  static const int maxTracePoints = 1200;

  AccelerationRunState _state = AccelerationRunState.idle;
  int _target;
  Duration? _launchElapsed;
  Duration? _standstillElapsed;
  Duration? _lastBelowTargetElapsed;
  Duration? _targetElapsed;
  Duration? _lastConsumedElapsed;
  Duration? _elapsed;
  double _peakSpeed = 0;
  final Map<int, Duration> _splits = {};
  final List<FlSpot> _trace = [];

  AccelerationRunState get state => _state;
  int get targetKmh => _target;
  Duration? get elapsed => _elapsed;
  double get peakSpeed => _peakSpeed;
  Map<int, Duration> get splits => Map.unmodifiable(_splits);
  List<FlSpot> get trace => List.unmodifiable(_trace);

  /// Last standstill → first moving, on the run clock.
  ObservationBracket? get startBracket {
    final standstill = _standstillElapsed;
    final launch = _launchElapsed;
    if (standstill == null || launch == null) return null;
    final gap = (launch - standstill).inMicroseconds / 1e6;
    return ObservationBracket(0, gap < 0 ? 0 : gap);
  }

  /// Last sample below target → first sample at or above, on the run clock.
  ObservationBracket? get targetBracket {
    final standstill = _standstillElapsed;
    final below = _lastBelowTargetElapsed;
    final at = _targetElapsed;
    if (standstill == null || at == null) return null;
    final lower = ((below ?? standstill) - standstill).inMicroseconds / 1e6;
    final upper = (at - standstill).inMicroseconds / 1e6;
    return ObservationBracket(lower < 0 ? 0 : lower, upper < 0 ? 0 : upper);
  }

  /// [targetLower − startUpper, targetUpper − startLower].
  ObservationBracket? get durationBracket {
    final start = startBracket;
    final target = targetBracket;
    if (start == null || target == null) return null;
    final lower = target.lowerSeconds - start.upperSeconds;
    final upper = target.upperSeconds - start.lowerSeconds;
    return ObservationBracket(lower < 0 ? 0 : lower, upper < 0 ? 0 : upper);
  }

  set targetKmh(int value) {
    if (_state == AccelerationRunState.running) return;
    _target = value;
  }

  void arm() {
    _state = AccelerationRunState.awaitingStandstill;
    _clearRun();
  }

  void reset() {
    _state = AccelerationRunState.idle;
    _clearRun();
  }

  void _clearRun() {
    _launchElapsed = null;
    _standstillElapsed = null;
    _lastBelowTargetElapsed = null;
    _targetElapsed = null;
    _lastConsumedElapsed = null;
    _elapsed = null;
    _peakSpeed = 0;
    _splits.clear();
    _trace.clear();
  }

  /// Heartbeat with no speed reading. [nowElapsed] is the connection tick.
  void ingestAbsence({required Duration nowElapsed}) {
    if (_state != AccelerationRunState.running &&
        _state != AccelerationRunState.staged) {
      return;
    }
    final last = _lastConsumedElapsed;
    if (last == null || nowElapsed - last > speedAbsenceGrace) {
      _abort();
    }
  }

  void ingestStale() {
    if (_state == AccelerationRunState.running ||
        _state == AccelerationRunState.staged) {
      _abort();
    }
  }

  void ingestSpeed({
    required double kmh,
    required Duration receivedElapsed,
  }) {
    switch (_state) {
      case AccelerationRunState.idle:
      case AccelerationRunState.finished:
      case AccelerationRunState.aborted:
        return;
      case AccelerationRunState.awaitingStandstill:
      case AccelerationRunState.staged:
      case AccelerationRunState.running:
        break;
    }
    if (_lastConsumedElapsed == receivedElapsed) return;
    _lastConsumedElapsed = receivedElapsed;

    switch (_state) {
      case AccelerationRunState.idle:
      case AccelerationRunState.finished:
      case AccelerationRunState.aborted:
        return;
      case AccelerationRunState.awaitingStandstill:
        if (kmh <= standstillKmh) {
          _standstillElapsed = receivedElapsed;
          _state = AccelerationRunState.staged;
        }
      case AccelerationRunState.staged:
        if (kmh <= standstillKmh) {
          _standstillElapsed = receivedElapsed;
        } else if (kmh >= launchKmh) {
          _launchElapsed = receivedElapsed;
          _standstillElapsed ??= receivedElapsed;
          _state = AccelerationRunState.running;
          _recordRunningSample(kmh, receivedElapsed);
        }
      case AccelerationRunState.running:
        _recordRunningSample(kmh, receivedElapsed);
    }
  }

  void _recordRunningSample(double kmh, Duration receivedElapsed) {
    final launch = _launchElapsed;
    if (launch == null) return;
    final elapsed = receivedElapsed - launch;
    if (elapsed.isNegative) return;

    _peakSpeed = kmh > _peakSpeed ? kmh : _peakSpeed;
    _elapsed = elapsed;
    _trace.add(FlSpot(elapsed.inMicroseconds / 1e6, kmh));
    if (_trace.length > maxTracePoints) _trace.removeAt(0);

    if (kmh < _target) {
      _lastBelowTargetElapsed = receivedElapsed;
    }

    for (final split in splitTargetsKmh) {
      if (kmh >= split && !_splits.containsKey(split)) {
        _splits[split] = elapsed;
      }
    }

    if (kmh >= _target) {
      _targetElapsed ??= receivedElapsed;
      _state = AccelerationRunState.finished;
    }
  }

  void _abort() {
    _state = AccelerationRunState.aborted;
  }
}
