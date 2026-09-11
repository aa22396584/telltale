import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/obd/physics/vehicle_evidence.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/vehicle_catalog/ca_vehicle_catalog.dart';
import 'package:torque_obd/obd/vehicle_catalog/ca_vehicle_profile.dart';
import 'package:torque_obd/obd/vehicle_catalog/catalog_digest.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';

const _csv =
    'ca_id,market,resource_class,model_year,make,model,vehicle_class,engine_size_l,cylinders,transmission,fuel_type,motor_kw,source_file\n'
    'aaaaaaaaaaaaaaaa,CA,ice,2024,Tesla,Model S,Full-size,0.0,0,A1,X,,my2024-ice.csv\n'
    'bbbbbbbbbbbbbbbb,CA,bev,2024,Tesla,Model S,Full-size,,,A1,B,250,my2012-2026-battery-electric-vehicles.csv\n'
    'cccccccccccccccc,CA,phev,2013,Ford,Fusion Energi,Mid-size,2.0,4,AV,B/X|X,35,my2012-2026-plug-in-hybrid-electric-vehicles.csv\n'
    'dddddddddddddddd,CA,ice,2024,Ford,F-150,Pickup,5.0,8,A10,D,,my2024-ice.csv\n'
    'eeeeeeeeeeeeeeee,CA,ice,2024,Chevrolet,Impala,Full-size,3.6,6,A6,E,,my2024-ice.csv\n'
    'nnnnnnnnnnnnnnnn,CA,ice,2014,Honda,Civic,Compact,1.8,4,M5,N,,my2012-2024-ice.csv\n'
    'hhhhhhhhhhhhhhhh,CA,ice,2015,Acura,ILX Hybrid,Compact,1.5,4,AV7,Z,,my2015-2024-fuel-consumption-ratings.csv\n';

String _manifest({
  String? sha256,
  int? sizeBytes,
  int rowCount = 7,
  int uniqueMakeCount = 5,
  int yearMin = 2013,
  int yearMax = 2024,
}) => jsonEncode({
  'schema_version': 1,
  'dataset': 'Canada NRCan Fuel Consumption Ratings vehicle identity',
  'coverage': {'market': 'Canada'},
  'source': {'retrieved_at_utc': '2026-09-11T07:33:23+00:00'},
  'output': {
    'file': 'ca_nrcan_vehicles.csv',
    'columns': CaVehicleCatalog.requiredColumns,
    'row_count': rowCount,
    'sha256': sha256 ?? sha256Hex(utf8.encode(_csv)),
    'size_bytes': sizeBytes ?? utf8.encode(_csv).length,
    'unique_make_count': uniqueMakeCount,
    'year_min': yearMin,
    'year_max': yearMax,
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ICE and BEV Tesla Model S rows stay separate classes', () {
    final catalog = CaVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    expect(catalog.length, 7);
    expect(CaVehicleConfiguration.market, 'CA');
    final ice = catalog.byCaId('aaaaaaaaaaaaaaaa')!;
    final bev = catalog.byCaId('bbbbbbbbbbbbbbbb')!;
    expect(ice.resourceClass, 'ice');
    expect(bev.resourceClass, 'bev');
    expect(ice.caId, isNot(bev.caId));
    expect(ice.displacementL, isNull);
    expect(bev.displacementL, isNull);
    expect(bev.motorKw, '250');
    final phev = catalog.byCaId('cccccccccccccccc')!;
    expect(phev.displacementL, closeTo(2.0, 0.0001));
    final applied = applyCaConfiguration(catalog, caId: phev.caId);
    expect(applied.verifiedFieldKeys, {'displacementL'});
    expect(applied.profile.fuelTypeField.isVerifiedExact, isFalse);
    expect(applied.profile.massField.isVerifiedExact, isFalse);
    expect(
      applied.profile.massField.origin,
      isNot(VehicleFieldOrigin.officialRegistry),
    );
  });

  test('hash mismatch fails closed', () {
    expect(
      () => CaVehicleCatalog.fromStrings(
        manifestJson: _manifest(sha256: 'a' * 64),
        csv: _csv,
      ),
      throwsA(
        isA<CaVehicleCatalogException>().having(
          (error) => error.message,
          'message',
          contains('SHA-256'),
        ),
      ),
    );
  });

  test('loads the bundled official snapshot', () async {
    final catalog = await CaVehicleCatalog.load(rootBundle);
    expect(catalog.length, 12971);
    expect(catalog.years.first, 2012);
    expect(catalog.years.last, 2026);
    expect(catalog.makes(), isNotEmpty);
  });

  test('Canada and US Tesla Model S Plaid rows stay in separate markets', () async {
    final ca = await CaVehicleCatalog.load(rootBundle);
    final us = await UsVehicleCatalog.load(rootBundle);
    const caId = '76ac2b4141f30dfd';
    const usEpaId = 49742;
    final caRow = ca.byCaId(caId);
    final usRow = us.byEpaId(usEpaId);
    expect(caRow, isNotNull);
    expect(usRow, isNotNull);
    expect(caRow!.make, 'Tesla');
    expect(caRow.model, contains('Model S Plaid'));
    expect(caRow.resourceClass, 'bev');
    expect(usRow!.make, 'Tesla');
    expect(usRow.model, 'Model S Plaid');
    expect(ca.byCaId('$usEpaId'), isNull);
    expect(
      () => applyCaConfiguration(ca, caId: '$usEpaId'),
      throwsA(isA<CaVehicleCatalogException>()),
    );
    final applied = applyCaConfiguration(ca, caId: caId);
    expect(applied.verifiedFieldKeys, isEmpty);
    expect(applied.profile.massField.isVerifiedExact, isFalse);
    expect(applied.profile.fuelTypeField.isVerifiedExact, isFalse);
  });

  test('single-letter NRCan fuel codes that match FuelType are sourced', () {
    final catalog = CaVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    final gasoline = applyCaConfiguration(catalog, caId: 'aaaaaaaaaaaaaaaa');
    expect(gasoline.verifiedFieldKeys, {'fuelType'});
    expect(gasoline.profile.fuelType, FuelType.gasoline);
    expect(gasoline.profile.fuelTypeField.isVerifiedExact, isTrue);

    final diesel = applyCaConfiguration(catalog, caId: 'dddddddddddddddd');
    expect(diesel.verifiedFieldKeys, {'displacementL', 'fuelType'});
    expect(diesel.profile.fuelType, FuelType.diesel);
    expect(diesel.profile.displacementL, closeTo(5.0, 0.0001));

    final ethanol = applyCaConfiguration(catalog, caId: 'eeeeeeeeeeeeeeee');
    expect(ethanol.profile.fuelType, FuelType.ethanolE85);
    expect(ethanol.profile.fuelTypeField.isVerifiedExact, isTrue);
  });

  test('electricity, natural gas, and dual NRCan fuel codes stay unresolved', () {
    final catalog = CaVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    final bev = applyCaConfiguration(catalog, caId: 'bbbbbbbbbbbbbbbb');
    expect(bev.verifiedFieldKeys.contains('fuelType'), isFalse);
    expect(bev.profile.fuelTypeField.isVerifiedExact, isFalse);

    final cng = applyCaConfiguration(catalog, caId: 'nnnnnnnnnnnnnnnn');
    expect(cng.verifiedFieldKeys.contains('fuelType'), isFalse);
    expect(cng.profile.fuelTypeField.isVerifiedExact, isFalse);
    expect(
      cng.profile.fuelTypeField.origin,
      isNot(VehicleFieldOrigin.officialRegistry),
    );

    final dual = applyCaConfiguration(catalog, caId: 'cccccccccccccccc');
    expect(dual.verifiedFieldKeys.contains('fuelType'), isFalse);
  });

  test('ICE conventional hybrid rows do not verify combustion-only fuel', () {
    final catalog = CaVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    final hybrid = applyCaConfiguration(catalog, caId: 'hhhhhhhhhhhhhhhh');
    expect(hybrid.configuration.resourceClass, 'ice');
    expect(hybrid.configuration.fuelType, 'Z');
    expect(hybrid.verifiedFieldKeys.contains('fuelType'), isFalse);
    expect(hybrid.profile.fuelTypeField.isVerifiedExact, isFalse);
    expect(
      hybrid.profile.fuelTypeField.origin,
      isNot(VehicleFieldOrigin.officialRegistry),
    );
  });
}
