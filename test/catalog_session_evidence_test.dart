/// #335 leftover: a real bundled EPA row must reach session evidence.
///
/// Adapter tests already pin [applyUsEpaConfiguration]. Session-evidence tests
/// already pin a hand-built [VehicleProfile.sourced]. Neither is the production
/// path: Settings calls the adapter, then a later connection freezes that
/// profile into [SessionEvidenceMetadata]. A plausible-looking header with a
/// made-up locator is the failure this file exists to catch.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/field_evidence/platform_metadata.dart';
import 'package:torque_obd/obd/physics/vehicle_evidence.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/session_evidence.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UsVehicleCatalog catalog;

  setUpAll(() async {
    catalog = await UsVehicleCatalog.load(rootBundle);
  });

  test('a bundled EPA row keeps its EvidenceRef through session evidence', () {
    const epaId = 24752;
    final applied = applyUsEpaConfiguration(catalog, epaId: epaId);
    expect(applied.verifiedFieldKeys, contains('displacementL'));
    expect(applied.profile.displacementField.isVerifiedExact, isTrue);
    expect(
      applied.profile.displacementField.origin,
      VehicleFieldOrigin.officialRegistry,
    );
    expect(
      applied.profile.displacementField.evidence?.locator,
      'epa_id=$epaId',
    );
    expect(
      applied.profile.displacementField.evidence?.sha256,
      catalog.snapshotSha256,
    );
    expect(applied.profile.massField.isVerifiedExact, isFalse);

    final header = SessionEvidenceMetadata(
      sessionId: 'catalog-evidence-1',
      startedAt: DateTime.utc(2026, 9, 12),
      platform: PlatformMetadata.unknown(),
      vehicleProfile: applied.profile,
      transportKind: 'Wi-Fi',
      deviceName: 'OBD-II',
    ).renderHeader();

    expect(header, contains('epa_id=$epaId'));
    expect(header, contains(catalog.snapshotSha256));
    expect(header, contains('證據.排氣量'));
    expect(header, isNot(contains('證據.車重')));
    expect(header, isNot(contains('epa_id=12345')));
  });
}
