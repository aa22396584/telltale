/// Dated #333 disposition for `kia-ev9-egmp-2024-2025-experimental`.
///
/// Reads the bundled catalog JSON through the schema parser, not the
/// hash-checked loader, so a header/DID mutation fails these assertions
/// rather than the SHA-256 gate first.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_catalog_validator.dart';

const _ev9Id = 'kia-ev9-egmp-2024-2025-experimental';
const _obdbArtifactSha256 =
    'dd9e4c5c5009f96bfcc9711ea49aab7e0a7fa3aaf7f693b37f2cdcd8c7bfb975';
const _obdbRevision = '85d8cff25e849a6e421cda20cbadfd4630fe85e7';

const _capturePins = <String, String>{
  'tests/test_cases/2024/commands/7E4.7EC.220101|fc=1.yaml':
      '4f9f9dc234749313a119630219cb1208a62b86792c03b6bb364172ba7f273538',
  'tests/test_cases/2024/commands/7E4.7EC.220105|fc=1.yaml':
      '1ca0d53a21c12613033b8dc0f535dbefd75799e89395c766ef4f916d44a026b1',
  'tests/test_cases/2025/commands/7E4.7EC.220101|fc=1.yaml':
      '0c3679bd49a3caf5e0c1d20472244970e301aabf0948042c3b8eb3a623528df7',
  'tests/test_cases/2025/commands/7E4.7EC.220105|fc=1.yaml':
      '0ebd4ee425214f5e3a45190d7c2c8b6eeec42d3cdf329f77729cac18241d6aff',
  'generations.yaml':
      '4ac04ffbd255d96181b0899a848352c2212c558669a78e5fafd46f3611a2c209',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PowertrainBatteryProfile profile;
  late Map<String, Object?> rawProfile;

  setUpAll(() async {
    final text = await rootBundle.loadString(
      PowertrainBatteryCatalogAsset.catalogAsset,
    );
    final catalog = PowertrainBatteryCatalog.fromJsonString(text);
    profile = catalog.profiles.singleWhere((entry) => entry.id == _ev9Id);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    rawProfile = Map<String, Object?>.from(
      (decoded['profiles'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['id'] == _ev9Id),
    );
  });

  test('EV9 status stays experimental', () {
    expect(profile.status, PowertrainProfileStatus.experimental);
    expect(rawProfile['status'], 'experimental');
  });

  test('EV9 Mode 22 may be installed as unverified PIDs', () {
    const validator = PowertrainBatteryProfileCatalogValidator();
    expect(validator.validateProfile(profile).canInstall, isTrue);
  });

  test('EV9 commands are exactly 7E4/7EC 22 0101 (59) and 0105 (43)', () {
    expect(
      [
        for (final command in profile.commands)
          (
            command.requestHeader,
            command.expectedResponder,
            command.mode,
            command.identifier,
            command.payloadLength,
          ),
      ],
      const [
        ('7E4', '7EC', '22', '0101', 59),
        ('7E4', '7EC', '22', '0105', 43),
      ],
    );
  });

  test('EV9 pack current stays the signed repair of OBDb unsigned current', () {
    final current = profile.commands
        .singleWhere((command) => command.identifier == '0101')
        .signals
        .singleWhere((signal) => signal.id == 'pack_current');
    expect(current.equation, '(SIGNED(A)*256+B)/10');
  });

  test('EV9 secondary_sources stays empty', () {
    expect(profile.secondarySources, isEmpty);
    final rawSecondary = rawProfile['secondary_sources'];
    expect(rawSecondary == null || (rawSecondary as List).isEmpty, isTrue);
  });

  test('EV9 primary artifact SHA-256 stays the OBDb pin', () {
    expect(profile.source.artifactSha256, _obdbArtifactSha256);
    expect(profile.source.revision, _obdbRevision);
    expect(
      (rawProfile['source'] as Map)['artifact_sha256'],
      _obdbArtifactSha256,
    );
  });

  test('EV9 capture artifacts stay the pinned MY2024/MY2025 hashes', () {
    final artifacts =
        ((rawProfile['source'] as Map)['capture_artifacts'] as List<dynamic>)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList();
    expect({
      for (final row in artifacts) row['path'] as String: row['sha256'] as String,
    }, _capturePins);
  });

  test('EV9 year window stays 2024–2025', () {
    expect(profile.yearFrom, 2024);
    expect(profile.yearTo, 2025);
    expect(rawProfile['year_from'], 2024);
    expect(rawProfile['year_to'], 2025);
  });

  test('EV9 dated disposition records the missing second family and signed current', () {
    final limitations = (rawProfile['limitations'] as List<dynamic>)
        .cast<String>()
        .join('\n');
    expect(limitations, contains('2026-09-11 re-evaluation'));
    expect(limitations, contains('RETAIN EXPERIMENTAL'));
    expect(limitations, contains('no EV9'));
    expect(limitations, contains('6540.2 A'));
    expect(limitations, contains('-13.4 A'));
  });
}
