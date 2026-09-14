/// Trip distance/fuel integration with independent coverage.
///
/// A missing interval is a gap, not a held previous sample. Consumption
/// (L/100 km) is computed only from time where speed and fuel are both
/// valid. Physical meter comparison is out of scope.
library;

import '../obd/physics/physics_engine.dart';

/// Where a trip fuel-rate sample came from.
enum TripFuelSource {
  measured,
  stoichiometricEstimate,
  unavailable,
}

/// Engine observation attached to a trip sample.
enum TripEngineState { running, notRunning, unknown }

final class TripSample {
  const TripSample({
    required this.id,
    required this.elapsed,
    required this.sourceId,
    this.speedKmh,
    this.fuelRateLPerHour,
    this.fuelSource = TripFuelSource.unavailable,
    this.engineState = TripEngineState.unknown,
  });

  final String id;
  final Duration elapsed;
  final String sourceId;
  final double? speedKmh;
  final double? fuelRateLPerHour;
  final TripFuelSource fuelSource;
  final TripEngineState engineState;
}

final class TripTotals {
  const TripTotals({
    this.distanceKm = 0,
    this.fuelL = 0,
    this.jointDistanceKm = 0,
    this.jointFuelL = 0,
    this.moving = Duration.zero,
    this.idle = Duration.zero,
    this.stoppedNotRunning = Duration.zero,
    this.stoppedUnknown = Duration.zero,
    this.unknownMotion = Duration.zero,
    this.gap = Duration.zero,
  });

  final double distanceKm;
  final double fuelL;
  final double jointDistanceKm;
  final double jointFuelL;
  final Duration moving;
  final Duration idle;
  final Duration stoppedNotRunning;
  final Duration stoppedUnknown;
  final Duration unknownMotion;
  final Duration gap;

  /// Null when joint distance is zero: idle fuel must not become L/100 km.
  double? get litersPer100Km =>
      jointDistanceKm > 0 ? jointFuelL / jointDistanceKm * 100 : null;
}

final class TripAccumulator {
  /// Longer than this, the interval is missing data rather than a slow poll.
  ///
  /// Ten seconds is the live-reading staleness ceiling. A hole of minutes
  /// must not integrate as if the last sample were still true.
  static const Duration maxGap = Duration(seconds: 10);

  /// Number of most-recent ignored IDs retained for diagnostics.
  static const int ignoredSampleIdCapacity = 32;

  /// Creates one in-memory logical trip with an exact ID budget.
  ///
  /// Once [maxSeenSampleIds] distinct structurally valid IDs are claimed, the
  /// accumulator latches [identityCapacityExceeded] and rejects every new ID
  /// without evicting old identities or changing trip totals. Construct a new
  /// accumulator only for a new logical trip. Identity state is not persisted
  /// and therefore is not restart-durable.
  TripAccumulator({required int maxSeenSampleIds})
    : _maxSeenSampleIds = maxSeenSampleIds {
    if (maxSeenSampleIds <= 0) {
      throw ArgumentError.value(
        maxSeenSampleIds,
        'maxSeenSampleIds',
        'must be greater than zero',
      );
    }
  }

  final int _maxSeenSampleIds;
  final _seenSampleIds = <String>{};
  TripSample? _last;
  var _distanceKm = 0.0;
  var _fuelL = 0.0;
  var _jointDistanceKm = 0.0;
  var _jointFuelL = 0.0;
  var _moving = Duration.zero;
  var _idle = Duration.zero;
  var _stoppedNotRunning = Duration.zero;
  var _stoppedUnknown = Duration.zero;
  var _unknownMotion = Duration.zero;
  var _gap = Duration.zero;
  final _ignored = <String>[];
  var _ignoredSampleCount = 0;
  var _identityCapacityExceeded = false;

  /// The newest [ignoredSampleIdCapacity] normalized ignored IDs.
  List<String> get ignoredSampleIds => List.unmodifiable(_ignored);

  /// Total ignored observations, including IDs no longer in the bounded list.
  int get ignoredSampleCount => _ignoredSampleCount;

  /// Whether the distinct-ID budget was exceeded for this logical trip.
  bool get identityCapacityExceeded => _identityCapacityExceeded;

  TripTotals get totals => TripTotals(
    distanceKm: _distanceKm,
    fuelL: _fuelL,
    jointDistanceKm: _jointDistanceKm,
    jointFuelL: _jointFuelL,
    moving: _moving,
    idle: _idle,
    stoppedNotRunning: _stoppedNotRunning,
    stoppedUnknown: _stoppedUnknown,
    unknownMotion: _unknownMotion,
    gap: _gap,
  );

  /// Adds a sample once per trimmed, case-sensitive ID in this accumulator.
  ///
  /// Identity is global to the logical trip, not scoped by [TripSample.sourceId].
  /// Structurally valid IDs are claimed before relative timestamp and source
  /// transition handling, so an out-of-order ID cannot later be amended and
  /// replayed.
  void add(TripSample sample) {
    final sampleId = sample.id.trim();
    if (!_structurallyUsable(sample, sampleId)) {
      _ignore(sampleId);
      return;
    }
    if (_seenSampleIds.contains(sampleId)) {
      _ignore(sampleId);
      return;
    }
    if (_identityCapacityExceeded ||
        _seenSampleIds.length >= _maxSeenSampleIds) {
      _identityCapacityExceeded = true;
      _ignore(sampleId);
      return;
    }
    _seenSampleIds.add(sampleId);

    sample = _sanitize(sample, sampleId);
    final previous = _last;
    if (previous == null) {
      _last = sample;
      return;
    }
    if (sample.sourceId != previous.sourceId) {
      _last = sample;
      return;
    }
    final dt = sample.elapsed - previous.elapsed;
    if (dt == Duration.zero) {
      _ignore(sampleId);
      return;
    }
    if (dt.isNegative) {
      _ignore(sampleId);
      return;
    }
    if (dt > maxGap) {
      _gap += dt;
      _last = sample;
      return;
    }

    final speed0 = _finiteNonNegative(previous.speedKmh);
    final speed1 = _finiteNonNegative(sample.speedKmh);
    final fuel0 = _finiteNonNegative(previous.fuelRateLPerHour);
    final fuel1 = _finiteNonNegative(sample.fuelRateLPerHour);
    final hours = dt.inMicroseconds / Duration.microsecondsPerHour;

    if (speed0 != null && speed1 != null) {
      final average = (speed0 + speed1) / 2;
      _distanceKm += average * hours;
      if (average >= PhysicsEngine.minSpeedForConsumption) {
        _moving += dt;
      } else if (previous.engineState == TripEngineState.running &&
          sample.engineState == TripEngineState.running) {
        _idle += dt;
      } else if (previous.engineState == TripEngineState.notRunning &&
          sample.engineState == TripEngineState.notRunning) {
        _stoppedNotRunning += dt;
      } else {
        _stoppedUnknown += dt;
      }
    } else {
      _unknownMotion += dt;
    }

    final sameFuelSource =
        previous.fuelSource == sample.fuelSource &&
        sample.fuelSource != TripFuelSource.unavailable;
    if (fuel0 != null && fuel1 != null && sameFuelSource) {
      _fuelL += (fuel0 + fuel1) / 2 * hours;
    }

    final jointSpeed = speed0 != null && speed1 != null;
    final jointFuel = fuel0 != null && fuel1 != null && sameFuelSource;
    if (jointSpeed &&
        jointFuel &&
        sample.fuelSource == TripFuelSource.measured &&
        previous.fuelSource == TripFuelSource.measured) {
      final average = (speed0 + speed1) / 2;
      _jointDistanceKm += average * hours;
      _jointFuelL += (fuel0 + fuel1) / 2 * hours;
    }

    _last = sample;
  }

  void _ignore(String sampleId) {
    _ignoredSampleCount++;
    if (_ignored.length == ignoredSampleIdCapacity) {
      _ignored.removeAt(0);
    }
    _ignored.add(sampleId);
  }

  static TripSample _sanitize(TripSample sample, String sampleId) {
    final speed = _fieldUsable(sample.speedKmh) ? sample.speedKmh : null;
    final fuel = _fieldUsable(sample.fuelRateLPerHour)
        ? sample.fuelRateLPerHour
        : null;
    return TripSample(
      id: sampleId,
      elapsed: sample.elapsed,
      sourceId: sample.sourceId,
      speedKmh: speed,
      fuelRateLPerHour: fuel,
      fuelSource: fuel == null ? TripFuelSource.unavailable : sample.fuelSource,
      engineState: sample.engineState,
    );
  }

  static bool _structurallyUsable(TripSample sample, String sampleId) =>
      sampleId.isNotEmpty &&
      sample.sourceId.trim().isNotEmpty &&
      !sample.elapsed.isNegative;

  static bool _fieldUsable(double? value) {
    if (value == null) return true;
    return value.isFinite && value >= 0;
  }

  static double? _finiteNonNegative(double? value) {
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }
}
