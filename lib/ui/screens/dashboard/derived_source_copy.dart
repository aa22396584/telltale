/// Shipped copy for the provenance vocabulary in `lib/obd/physics`.
///
/// [AirflowSource] and [FuelSource] are the engine's answer to "where did this
/// number come from", and the answer is the point: a measured air mass and a
/// speed-density estimate are the same `double` and are not the same claim.
/// The engine keeps the distinction; this file keeps the words.
///
/// The labels used to be `String get label` on the enums themselves, written in
/// Traditional Chinese. That put shipped copy inside `lib/obd/`, which is meant
/// to hold no Flutter and no locale, and the consequence was visible: the
/// English build's estimated-values panel read 「MAF 感測器」 in the middle of an
/// otherwise English screen, and it read that way in the store screenshot too.
///
/// Both functions take an [AppLocalizations] rather than a [BuildContext],
/// matching `datum_status_copy.dart`: a pure-Dart test can then assert both
/// languages with `lookupAppLocalizations(...)` and no widget pump.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/physics/physics_engine.dart';

/// Where an air-mass figure came from.
String airflowSourceLabel(AppLocalizations l10n, AirflowSource source) =>
    switch (source) {
      AirflowSource.measured => l10n.derivedAirflowSourceMaf,
      AirflowSource.speedDensity => l10n.derivedAirflowSourceSpeedDensity,
      AirflowSource.unavailable => l10n.derivedAirflowSourceUnavailable,
    };

/// Where a fuel figure came from.
///
/// [FuelSource.measured] is the only one of the three that is a measurement.
/// The other two are an estimate and an absence, and neither may be worded so
/// that a reader takes it for a reading off the vehicle.
String fuelSourceLabel(AppLocalizations l10n, FuelSource source) =>
    switch (source) {
      // Shares `derivedEcuReported` with the measured-fuel strip 160 lines
      // away on the same screen. Two keys held the identical sentence in
      // both languages; editing one would have left the other behind.
      FuelSource.measured => l10n.derivedEcuReported,
      FuelSource.stoichiometricEstimate =>
        l10n.derivedFuelSourceStoichiometric,
      FuelSource.unavailable => l10n.derivedFuelSourceUnavailable,
    };
