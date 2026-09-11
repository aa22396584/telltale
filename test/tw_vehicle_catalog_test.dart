import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/obd/vehicle_catalog/tw_vehicle_catalog.dart';
import 'package:torque_obd/obd/vehicle_catalog/tw_vehicle_profile.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';
import 'package:torque_obd/obd/physics/vehicle_evidence.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';

const _csv =
    'tw_id,market,origin,vehicle_class,powertrain,issue_year_ce,issue_date,make,model,transmission,doors,displacement_cc,reference_mass_kg,applicant,source_file\n'
    'aaaaaaaaaaaaaaaa,TW,domestic,passenger,ice,2026,2026-07-02,本田,FIT A522H1502,A1,5D,1498.0,1320.0,台灣本田,國產小客車.csv\n'
    'bbbbbbbbbbbbbbbb,TW,import,passenger,ice,2026,2026-07-03,TOYOTA,CAMRY HYBRID,CVT,4D,2487.0,1678.0,和泰汽車,進口小客車.csv\n';

const _sha256 =
    '4f4e91946eddb20f85e6c64a981e2a3d927030fc8ace91ca429ca1bba81a5ceb';

String _manifest({
  String sha256 = _sha256,
  int? sizeBytes,
  int rowCount = 2,
  int uniqueMakeCount = 2,
  int yearMin = 2026,
  int yearMax = 2026,
  String market = 'Taiwan',
}) => jsonEncode({
  'schema_version': 1,
  'dataset': 'Taiwan MOEA Energy Administration vehicle identity',
  'coverage': {'market': market},
  'source': {'retrieved_at_utc': '2026-09-11T02:09:14+00:00'},
  'output': {
    'file': 'tw_moeaea_vehicles.csv',
    'columns': TwVehicleCatalog.requiredColumns,
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

  test('parses a verified Taiwan snapshot', () {
    final catalog = TwVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    expect(catalog.length, 2);
    expect(catalog.years, [2026]);
    expect(catalog.makes(year: 2026), ['TOYOTA', '本田']);
    final fit = catalog.byTwId('aaaaaaaaaaaaaaaa')!;
    expect(TwVehicleConfiguration.market, 'TW');
    expect(fit.make, '本田');
    expect(fit.displacementL, closeTo(1.498, 0.0001));
    expect(fit.referenceMassKg, '1320.0');
  });

  test('hash mismatch fails closed', () {
    expect(
      () => TwVehicleCatalog.fromStrings(
        manifestJson: _manifest(sha256: 'a' * 64),
        csv: _csv,
      ),
      throwsA(
        isA<TwVehicleCatalogException>().having(
          (error) => error.message,
          'message',
          contains('SHA-256'),
        ),
      ),
    );
  });

  test('row-count mismatch fails closed', () {
    expect(
      () => TwVehicleCatalog.fromStrings(
        manifestJson: _manifest(rowCount: 9),
        csv: _csv,
      ),
      throwsA(
        isA<TwVehicleCatalogException>().having(
          (error) => error.message,
          'message',
          contains('row count'),
        ),
      ),
    );
  });

  test('loads the bundled official snapshot', () async {
    final catalog = await TwVehicleCatalog.load(rootBundle);
    expect(catalog.length, 2343);
    expect(catalog.years.first, 2017);
    expect(catalog.years.last, 2026);
    expect(catalog.makes(), isNotEmpty);
    expect(
      catalog.makes().where((name) => name.toUpperCase() == 'TOYOTA'),
      isNotEmpty,
    );
  });

  test('a Taiwan TOYOTA row is not an EPA configuration', () async {
    final tw = await TwVehicleCatalog.load(rootBundle);
    final us = await UsVehicleCatalog.load(rootBundle);
    final twToyota = tw.makes().where((name) => name == 'TOYOTA').toList();
    final usToyota = us.makes().where((name) => name == 'Toyota').toList();
    expect(twToyota, isNotEmpty);
    expect(usToyota, isNotEmpty);
    final twYear = tw.years.last;
    final twModels = tw.models(year: twYear, make: 'TOYOTA');
    expect(twModels, isNotEmpty);
    final twRow = tw
        .configurations(year: twYear, make: 'TOYOTA', model: twModels.first)
        .first;
    expect(us.byEpaId(int.tryParse(twRow.twId) ?? -1), isNull);
    final applied = applyTwConfiguration(tw, twId: twRow.twId);
    expect(applied.profile.massField.isVerifiedExact, isFalse);
    expect(
      applied.profile.massField.origin,
      isNot(VehicleFieldOrigin.officialRegistry),
    );
    if (applied.verifiedFieldKeys.contains('displacementL')) {
      expect(applied.profile.displacementField.evidence?.market, 'Taiwan');
      expect(
        applied.profile.displacementField.evidence?.sourceId,
        'tw-moeaea-6032',
      );
    }
  });

  test('reference mass is not applied as curb mass', () {
    final catalog = TwVehicleCatalog.fromStrings(
      manifestJson: _manifest(),
      csv: _csv,
    );
    final applied = applyTwConfiguration(
      catalog,
      twId: 'aaaaaaaaaaaaaaaa',
      baseProfile: const VehicleProfile().copyWith(massKg: 1280),
    );
    expect(applied.verifiedFieldKeys, {'displacementL'});
    expect(applied.profile.displacementL, closeTo(1.498, 0.0001));
    expect(applied.profile.massKg, 1280);
    expect(applied.profile.massField.isVerifiedExact, isFalse);
  });
}
