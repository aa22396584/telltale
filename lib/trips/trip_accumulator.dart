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

final class TripSample {
  const TripSample({
    required this.id,
    required this.elapsed,
    required this.sourceId,
    this.speedKmh,
    this.fuelRateLPerHour,
    this.fuelSource = TripFuelSource.unavailable,
  });

  final String id;
  final Duration elapsed;
  final String sourceId;
  final double? speedKmh;
  final double? fuelRateLPerHour;
  final TripFuelSource fuelSource;
}

final class TripTotals {
  const TripTotals({
    this.distanceKm = 0,
    this.fuelL = 0,
    this.jointDistanceKm = 0,
    this.jointFuelL = 0,
    this.moving = Duration.zero,
    this.idle = Duration.zero,
    this.unknownMotion = Duration.zero,
    this.gap = Duration.zero,
  });

  final double distanceKm;
  final double fuelL;
  final double jointDistanceKm;
  final double jointFuelL;
  final Duration moving;
  final Duration idle;
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

  TripSample? _last;
  var _distanceKm = 0.0;
  var _fuelL = 0.0;
  var _jointDistanceKm = 0.0;
  var _jointFuelL = 0.0;
  var _moving = Duration.zero;
  var _idle = Duration.zero;
  var _unknownMotion = Duration.zero;
  var _gap = Duration.zero;
  final _ignored = <String>[];

  List<String> get ignoredSampleIds => List.unmodifiable(_ignored);

  TripTotals get totals => TripTotals(
    distanceKm: _distanceKm,
    fuelL: _fuelL,
    jointDistanceKm: _jointDistanceKm,
    jointFuelL: _jointFuelL,
    moving: _moving,
    idle: _idle,
    unknownMotion: _unknownMotion,
    gap: _gap,
  );

  void add(TripSample sample) {
    if (!_usable(sample)) {
      _ignored.add(sample.id);
      _last = null;
      return;
    }
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
      _ignored.add(sample.id);
      return;
    }
    if (dt.isNegative) {
      _ignored.add(sample.id);
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
      } else {
        _idle += dt;
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
    if (jointSpeed && jointFuel) {
      final average = (speed0 + speed1) / 2;
      _jointDistanceKm += average * hours;
      _jointFuelL += (fuel0 + fuel1) / 2 * hours;
    }

    _last = sample;
  }

  static bool _usable(TripSample sample) {
    if (sample.id.trim().isEmpty || sample.sourceId.trim().isEmpty) {
      return false;
    }
    if (sample.elapsed.isNegative) return false;
    if (!_fieldUsable(sample.speedKmh)) return false;
    if (!_fieldUsable(sample.fuelRateLPerHour)) return false;
    return true;
  }

  static bool _fieldUsable(double? value) {
    if (value == null) return true;
    return value.isFinite && value >= 0;
  }

  static double? _finiteNonNegative(double? value) {
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }
}
