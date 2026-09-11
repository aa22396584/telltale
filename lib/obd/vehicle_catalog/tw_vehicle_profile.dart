/// Applies only semantically compatible fields from one Taiwan certification row.
///
/// Displacement in cubic centimetres is the same quantity as litres after
/// dividing by 1000. 參考車重 is not curb mass and is never copied.
/// Maximum net power / 最大輸出馬力 is not wheel horsepower.
library;

import '../physics/vehicle_evidence.dart';
import '../physics/vehicle_profile.dart';
import 'tw_vehicle_catalog.dart';

final class TwProfileApplication {
  const TwProfileApplication({
    required this.configuration,
    required this.profile,
    required this.verifiedFieldKeys,
  });

  final TwVehicleConfiguration configuration;
  final VehicleProfile profile;
  final Set<String> verifiedFieldKeys;
}

TwProfileApplication applyTwConfiguration(
  TwVehicleCatalog catalog, {
  required String twId,
  VehicleProfile? baseProfile,
}) {
  final configuration = catalog.byTwId(twId);
  if (configuration == null) {
    throw TwVehicleCatalogException('unknown Taiwan vehicle id $twId');
  }
  final evidence = _evidenceFor(catalog, configuration);
  final litres = configuration.displacementL;
  final exactDisplacement =
      litres != null &&
          litres >= VehicleProfile.minDisplacementL &&
          litres <= VehicleProfile.maxDisplacementL
      ? SourcedField<double>(
          value: litres,
          origin: VehicleFieldOrigin.officialRegistry,
          resolution: EvidenceResolution.verifiedExact,
          evidence: evidence,
        )
      : null;
  final keys = <String>{if (exactDisplacement != null) 'displacementL'};
  const defaults = VehicleProfile();
  final previous = (baseProfile ?? defaults).unconfirmed();
  final base = VehicleProfile.sourced(
    displacementL: _reusableAssumption(
      previous.displacementField,
      defaults.displacementField,
    ),
    massKg: _reusableAssumption(previous.massField, defaults.massField),
    volumetricEfficiency: _reusableAssumption(
      previous.volumetricEfficiencyField,
      defaults.volumetricEfficiencyField,
    ),
    fuelType: _reusableAssumption(
      previous.fuelTypeField,
      defaults.fuelTypeField,
    ),
    drivetrain: _reusableAssumption(
      previous.drivetrainField,
      defaults.drivetrainField,
    ),
    dragCoefficient: _reusableAssumption(
      previous.dragCoefficientField,
      defaults.dragCoefficientField,
    ),
    frontalAreaM2: _reusableAssumption(
      previous.frontalAreaField,
      defaults.frontalAreaField,
    ),
    rollingResistance: _reusableAssumption(
      previous.rollingResistanceField,
      defaults.rollingResistanceField,
    ),
  );
  return TwProfileApplication(
    configuration: configuration,
    profile: VehicleProfile.sourced(
      displacementL: exactDisplacement ?? base.displacementField,
      massKg: base.massField,
      volumetricEfficiency: base.volumetricEfficiencyField,
      fuelType: base.fuelTypeField,
      drivetrain: base.drivetrainField,
      dragCoefficient: base.dragCoefficientField,
      frontalAreaM2: base.frontalAreaField,
      rollingResistance: base.rollingResistanceField,
    ),
    verifiedFieldKeys: Set.unmodifiable(keys),
  );
}

SourcedField<T> _reusableAssumption<T>(
  SourcedField<T> current,
  SourcedField<T> fallback,
) {
  final isEditableAssumption =
      current.origin == VehicleFieldOrigin.genericDefault ||
      current.origin == VehicleFieldOrigin.userEntered;
  return isEditableAssumption &&
          current.resolution == EvidenceResolution.unknown &&
          current.evidence == null
      ? current
      : fallback;
}

EvidenceRef _evidenceFor(
  TwVehicleCatalog catalog,
  TwVehicleConfiguration configuration,
) {
  final trim = [
    configuration.transmission,
    configuration.doors,
    configuration.origin,
    configuration.powertrain,
  ].where((value) => value.trim().isNotEmpty).join(' · ');
  return EvidenceRef(
    sourceId: 'tw-moeaea-6032',
    publisher: 'MOEA Energy Administration',
    sourceUrl: 'https://data.gov.tw/dataset/6032',
    revision: configuration.issueDate.isNotEmpty
        ? configuration.issueDate
        : catalog.retrievedAtUtc.toIso8601String(),
    retrievedAt: catalog.retrievedAtUtc.toIso8601String(),
    sha256: catalog.snapshotSha256,
    market: 'Taiwan',
    locator: 'tw_id=${configuration.twId}',
    year: configuration.issueYearCe,
    make: configuration.make,
    model: configuration.model,
    trim: trim.isEmpty ? 'unspecified' : trim,
  );
}
