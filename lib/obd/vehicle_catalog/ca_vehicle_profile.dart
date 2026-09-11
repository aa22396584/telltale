/// Applies only semantically compatible fields from one Canada NRCan row.
///
/// Engine size in litres is the same quantity as [VehicleProfile.displacementL]
/// when it is a positive finite number in range. Motor kW is not wheel
/// horsepower. Consumption, range, and CO2 are never copied.
///
/// NRCan fuel codes
/// (https://natural-resources.canada.ca/energy-efficiency/transportation-energy-efficiency/personal-vehicles/understanding-tables):
/// `X` regular gasoline, `Z` premium gasoline, `D` diesel, `E` E85, `B`
/// electricity, `N` natural gas. Only a single exact letter that matches a
/// [FuelType] is copied, and only for ICE rows whose official model string
/// does not contain `Hybrid`. Dual codes (`B/X|X`), `B`/`N`, BEV/PHEV rows,
/// and conventional hybrids in the ICE file stay unresolved: [VehicleProfile]
/// cannot express electric assistance.
library;

import '../physics/vehicle_evidence.dart';
import '../physics/vehicle_profile.dart';
import 'ca_vehicle_catalog.dart';

final class CaProfileApplication {
  const CaProfileApplication({
    required this.configuration,
    required this.profile,
    required this.verifiedFieldKeys,
  });

  final CaVehicleConfiguration configuration;
  final VehicleProfile profile;
  final Set<String> verifiedFieldKeys;
}

CaProfileApplication applyCaConfiguration(
  CaVehicleCatalog catalog, {
  required String caId,
  VehicleProfile? baseProfile,
}) {
  final configuration = catalog.byCaId(caId);
  if (configuration == null) {
    throw CaVehicleCatalogException('unknown Canada vehicle id $caId');
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
  final mappedFuel = _exactFuelType(configuration);
  final exactFuel = mappedFuel == null
      ? null
      : SourcedField<FuelType>(
          value: mappedFuel,
          origin: VehicleFieldOrigin.officialRegistry,
          resolution: EvidenceResolution.verifiedExact,
          evidence: evidence,
        );
  final keys = <String>{
    if (exactDisplacement != null) 'displacementL',
    if (exactFuel != null) 'fuelType',
  };
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
  return CaProfileApplication(
    configuration: configuration,
    profile: VehicleProfile.sourced(
      displacementL: exactDisplacement ?? base.displacementField,
      massKg: base.massField,
      volumetricEfficiency: base.volumetricEfficiencyField,
      fuelType: exactFuel ?? base.fuelTypeField,
      drivetrain: base.drivetrainField,
      dragCoefficient: base.dragCoefficientField,
      frontalAreaM2: base.frontalAreaField,
      rollingResistance: base.rollingResistanceField,
    ),
    verifiedFieldKeys: Set.unmodifiable(keys),
  );
}

FuelType? _exactFuelType(CaVehicleConfiguration configuration) {
  // Conventional hybrids are filed as ICE with a single X/Z. The current
  // physics model cannot express electric assistance, matching the US adapter
  // which leaves hybrid fuel unresolved. NRCan ICE files have no atvType
  // column; the official model string is the marker that is present.
  if (configuration.resourceClass != 'ice') return null;
  if (configuration.model.toLowerCase().contains('hybrid')) return null;
  return switch (configuration.fuelType.trim()) {
    'X' || 'Z' => FuelType.gasoline,
    'D' => FuelType.diesel,
    'E' => FuelType.ethanolE85,
    _ => null,
  };
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
  CaVehicleCatalog catalog,
  CaVehicleConfiguration configuration,
) {
  final trim = [
    configuration.resourceClass,
    configuration.transmission,
    configuration.vehicleClass,
  ].where((value) => value.trim().isNotEmpty).join(' · ');
  return EvidenceRef(
    sourceId: 'ca-nrcan-fcr',
    publisher: 'Natural Resources Canada',
    sourceUrl:
        'https://open.canada.ca/data/en/dataset/98f1a129-f628-4ce4-b24d-6f16bf24dd64',
    revision: catalog.retrievedAtUtc.toIso8601String(),
    retrievedAt: catalog.retrievedAtUtc.toIso8601String(),
    sha256: catalog.snapshotSha256,
    market: 'Canada',
    locator: 'ca_id=${configuration.caId}',
    year: configuration.modelYear,
    make: configuration.make,
    model: configuration.model,
    trim: trim.isEmpty ? 'unspecified' : trim,
  );
}
