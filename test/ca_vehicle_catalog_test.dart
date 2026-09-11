import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/obd/physics/vehicle_evidence.dart';
import 'package:torque_obd/obd/vehicle_catalog/ca_vehicle_catalog.dart';
import 'package:torque_obd/obd/vehicle_catalog/ca_vehicle_profile.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';

const _csv =
    'ca_id,market,resource_class,model_year,make,model,vehicle_class,engine_size_l,cylinders,transmission,fuel_type,motor_kw,source_file\n'
    'aaaaaaaaaaaaaaaa,CA,ice,2024,Tesla,Model S,Full-size,0.0,0,A1,X,,my2024-ice.csv\n'
    'bbbbbbbbbbbbbbbb,CA,bev,2024,Tesla,Model S,Full-size,,,A1,B,250,my2012-2026-battery-electric-vehicles.csv\n'
    'cccccccccccccccc,CA,phev,2013,Ford,Fusion Energi,Mid-size,2.0,4,AV,B/X|X,35,my2012-2026-plug-in-hybrid-electric-vehicles.csv\n';

const _sha256 =
    '41991fe365dd8f8a061dbf201a68e08c6d2c36eb4b91a9c82fc12579378e25d4';

String _manifest({
  String sha256 = _sha256,
  int? sizeBytes,
  int rowCount = 3,
  int uniqueMakeCount = 2,
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
    'sha256': sha256,
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
    expect(catalog.length, 3);
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
  });
}
