/// Literal coverage arithmetic for [TripAccumulator].
///
/// 60 km/h for 60 s is 1 km; 6 L/h for the same interval is 0.1 L; matched
/// coverage is 10 L/100 km. A gap is a missing interval, not a held sample.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/trips/trip_accumulator.dart';

TripSample _sample({
  required String id,
  required int seconds,
  double? speedKmh,
  double? fuelRateLPerHour,
  String sourceId = 'ecu-a/gen-1',
  TripFuelSource fuelSource = TripFuelSource.measured,
}) => TripSample(
  id: id,
  elapsed: Duration(seconds: seconds),
  sourceId: sourceId,
  speedKmh: speedKmh,
  fuelRateLPerHour: fuelRateLPerHour,
  fuelSource: fuelSource,
);

void _addEverySecond(
  TripAccumulator trip, {
  required String prefix,
  required int from,
  required int to,
  double? speedKmh,
  double Function(int seconds)? speedAt,
  double? fuelRateLPerHour,
  String sourceId = 'ecu-a/gen-1',
  TripFuelSource fuelSource = TripFuelSource.measured,
}) {
  for (var seconds = from; seconds <= to; seconds++) {
    trip.add(
      _sample(
        id: '$prefix-$seconds',
        seconds: seconds,
        speedKmh: speedAt?.call(seconds) ?? speedKmh,
        fuelRateLPerHour: fuelRateLPerHour,
        sourceId: sourceId,
        fuelSource: fuelSource,
      ),
    );
  }
}

void main() {
  test('matched constant speed and fuel produce 10 L/100 km', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'run',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.jointDistanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.jointFuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.litersPer100Km, closeTo(10.0, 1e-9));
    expect(trip.totals.moving, const Duration(seconds: 60));
    expect(trip.totals.idle, Duration.zero);
    expect(trip.totals.gap, Duration.zero);
  });

  test('idle fuel does not invent a distance-based consumption', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'idle',
      from: 0,
      to: 60,
      speedKmh: 0,
      fuelRateLPerHour: 1.2,
    );

    expect(trip.totals.distanceKm, 0);
    expect(trip.totals.fuelL, closeTo(0.02, 1e-9));
    expect(trip.totals.litersPer100Km, isNull);
    expect(trip.totals.idle, const Duration(seconds: 60));
    expect(trip.totals.moving, Duration.zero);
  });

  test('a gap does not hold the previous sample across the missing interval', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'run',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );
    trip.add(_sample(id: 'after-gap', seconds: 180, speedKmh: 60, fuelRateLPerHour: 6));

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.gap, const Duration(seconds: 120));
    expect(trip.totals.litersPer100Km, closeTo(10.0, 1e-9));
  });

  test('disjoint fuel then speed streams do not yield a trip-wide average', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'fuel',
      from: 0,
      to: 60,
      fuelRateLPerHour: 6,
    );
    _addEverySecond(
      trip,
      prefix: 'spd',
      from: 61,
      to: 121,
      speedKmh: 60,
    );

    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.jointDistanceKm, 0);
    expect(trip.totals.jointFuelL, 0);
    expect(trip.totals.litersPer100Km, isNull);
  });

  test('duplicate elapsed ticks do not double-count', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'run',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );
    trip.add(_sample(id: 'dup', seconds: 60, speedKmh: 120, fuelRateLPerHour: 20));

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.ignoredSampleIds, contains('dup'));
  });

  test('out-of-order elapsed ticks are retained as diagnostics only', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'run',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );
    trip.add(_sample(id: 'late', seconds: 30, speedKmh: 200, fuelRateLPerHour: 40));

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.ignoredSampleIds, contains('late'));
  });

  test('a monotonic clock reset is a discontinuity, not a negative interval', () {
    final trip = TripAccumulator();
    trip.add(_sample(id: 'before', seconds: 10, speedKmh: 60, fuelRateLPerHour: 6));
    _addEverySecond(
      trip,
      prefix: 'after',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
      sourceId: 'ecu-a/gen-2',
    );

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
  });

  test('non-finite speed or fuel is a gap in that stream, not a number', () {
    final trip = TripAccumulator();
    trip.add(_sample(id: 'a', seconds: 0, speedKmh: 60, fuelRateLPerHour: 6));
    trip.add(
      _sample(
        id: 'nan',
        seconds: 1,
        speedKmh: double.nan,
        fuelRateLPerHour: double.infinity,
      ),
    );
    _addEverySecond(
      trip,
      prefix: 'after',
      from: 2,
      to: 62,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.ignoredSampleIds, isEmpty);
  });

  test('a malformed fuel sample does not drop a valid speed stream', () {
    final trip = TripAccumulator();
    trip.add(_sample(id: 'a', seconds: 0, speedKmh: 60, fuelRateLPerHour: 6));
    trip.add(
      _sample(
        id: 'nan-fuel',
        seconds: 1,
        speedKmh: 60,
        fuelRateLPerHour: double.nan,
      ),
    );
    trip.add(_sample(id: 'b', seconds: 2, speedKmh: 60, fuelRateLPerHour: 6));

    expect(trip.totals.distanceKm, closeTo(2 * 60 / 3600, 1e-9));
    expect(trip.totals.fuelL, 0);
    expect(trip.totals.litersPer100Km, isNull);
    expect(trip.ignoredSampleIds, isEmpty);
  });

  test('a source or generation change starts a new interval without filling it', () {
    final trip = TripAccumulator();
    trip.add(
      _sample(
        id: 'a',
        seconds: 0,
        speedKmh: 60,
        fuelRateLPerHour: 6,
        sourceId: 'ecu-a/gen-1',
      ),
    );
    _addEverySecond(
      trip,
      prefix: 'b',
      from: 1,
      to: 61,
      speedKmh: 60,
      fuelRateLPerHour: 6,
      sourceId: 'ecu-b/gen-2',
    );

    expect(trip.totals.distanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.gap, Duration.zero);
  });

  test('measured and estimated fuel are not mixed into one consumption ratio', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'measured',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );
    trip.add(
      _sample(
        id: 'estimated',
        seconds: 61,
        speedKmh: 60,
        fuelRateLPerHour: 6,
        fuelSource: TripFuelSource.stoichiometricEstimate,
      ),
    );

    expect(trip.totals.distanceKm, closeTo(1.0 + 60 / 3600, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.litersPer100Km, closeTo(10.0, 1e-9));
  });

  test('measured then estimated runs do not blend into one L/100 km', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'measured',
      from: 0,
      to: 60,
      speedKmh: 60,
      fuelRateLPerHour: 6,
    );
    _addEverySecond(
      trip,
      prefix: 'estimated',
      from: 61,
      to: 121,
      speedKmh: 60,
      fuelRateLPerHour: 12,
      fuelSource: TripFuelSource.stoichiometricEstimate,
    );

    expect(trip.totals.distanceKm, closeTo(2.0 + 60 / 3600, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.1 + 0.2, 1e-9));
    expect(trip.totals.jointDistanceKm, closeTo(1.0, 1e-9));
    expect(trip.totals.jointFuelL, closeTo(0.1, 1e-9));
    expect(trip.totals.litersPer100Km, closeTo(10.0, 1e-9));
  });

  test('acceleration still uses trapezoidal distance, not a held start speed', () {
    final trip = TripAccumulator();
    _addEverySecond(
      trip,
      prefix: 'accel',
      from: 0,
      to: 60,
      speedAt: (seconds) => seconds.toDouble(),
      fuelRateLPerHour: 3,
    );

    expect(trip.totals.distanceKm, closeTo(0.5, 1e-9));
    expect(trip.totals.fuelL, closeTo(0.05, 1e-9));
    expect(trip.totals.litersPer100Km, closeTo(10.0, 1e-9));
  });
}
