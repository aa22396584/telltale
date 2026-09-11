/// Dated #333 disposition for `toyota-prius-tnga-2016-2026`.
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

const _priusId = 'toyota-prius-tnga-2016-2026';
const _etngaId = 'toyota-etnga-bev-2022-2024';
const _obdbArtifactSha256 =
    'e037a50ab2f256e5f2668aefc63c1ddb30b7686c372be199b3421972b933bd4b';
const _obdbRevision = '0a8c4ec72be860861548a3aeb2be007eecd83941';

const _capturePins = <String, String>{
  'tests/test_cases/2022/commands/7D2.7DA.221F5B|fc=1.yaml':
      'af5e20e780de2301cc9ea36573693f3a741f076c28660fd2b54fb0803dfa724a',
  'tests/test_cases/2022/commands/7D2.7DA.221F9A.yaml':
      '1f8580d24165148d7bd3381c186f5930963f6ebf690cf60a1e9315cf5196a1d9',
  'tests/test_cases/2022/commands/7D2.22106C|fc=1.yaml':
      'c38d484fdfe129320d0761953aa1307deedd1d6480ca0350a32903b3402fb319',
  'tests/test_cases/2024/commands/7D2.7DA.221F5B|fc=1.yaml':
      '0adf705a837eaa9e3a35c8d1f29b32fbb0c5771ec1cc17a75fdcf73d8db996c6',
  'tests/test_cases/2024/commands/7D2.7DA.221F9A.yaml':
      'd875fc777502c62f680822e4d74b8c45f29010c8afc0b8112d6bb637c3df2f2e',
  'tests/test_cases/2024/commands/7D2.22106C|fc=1.yaml':
      '31301ac259f9ec5451fc7a58aa5e1a88ca1e50a21159f9c6f924f441b9155f24',
  'tests/test_cases/2025/commands/7D2.7DA.221F5B|fc=1.yaml':
      '5d428ca89c6b88c62c82806eb9ee8d03c3ebb5dc9fd8421a0d29ffe9cd1ff2a5',
  'tests/test_cases/2025/commands/7D2.7DA.221F9A.yaml':
      '87f8f9538679e15b4ed89da4c0f869c4ac5643fc94e34b0744a5d3d1710663e3',
  'tests/test_cases/2025/commands/7D2.22106C|fc=1.yaml':
      '7107565c0881ece40cabef721054882689e619b8127bc45cfaea0230acc552af',
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
    profile = catalog.profiles.singleWhere((entry) => entry.id == _priusId);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    rawProfile = Map<String, Object?>.from(
      (decoded['profiles'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['id'] == _priusId),
    );
  });

  test('Prius TNGA status stays experimental', () {
    expect(profile.status, PowertrainProfileStatus.experimental);
    expect(rawProfile['status'], 'experimental');
  });

  test('Prius TNGA Mode 22 may be installed as unverified PIDs', () {
    const validator = PowertrainBatteryProfileCatalogValidator();
    expect(validator.validateProfile(profile).canInstall, isTrue);
  });

  test('Prius TNGA commands are exactly 7D2/7DA 22 1F5B, 1F9A and 106C', () {
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
        ('7D2', '7DA', '22', '1F5B', 1),
        ('7D2', '7DA', '22', '1F9A', 6),
        ('7D2', '7DA', '22', '106C', 3),
      ],
    );
  });

  test('Prius TNGA commands do not use header 747, responder 74F, or Mode 21', () {
    expect(profile.commands, isNotEmpty);
    for (final command in profile.commands) {
      expect(command.requestHeader, isNot('747'), reason: command.wireKey);
      expect(command.expectedResponder, isNot('74F'), reason: command.wireKey);
      expect(command.requestHeader, isNot('7E2'), reason: command.wireKey);
      expect(command.mode, isNot('21'), reason: command.wireKey);
    }
  });

  test('Prius TNGA secondary_sources stays empty', () {
    expect(profile.secondarySources, isEmpty);
    final rawSecondary = rawProfile['secondary_sources'];
    expect(rawSecondary == null || (rawSecondary as List).isEmpty, isTrue);
  });

  test('Prius TNGA primary artifact SHA-256 stays the OBDb pin', () {
    expect(profile.source.artifactSha256, _obdbArtifactSha256);
    expect(profile.source.revision, _obdbRevision);
    expect(
      (rawProfile['source'] as Map)['artifact_sha256'],
      _obdbArtifactSha256,
    );
    expect((rawProfile['source'] as Map)['revision'], _obdbRevision);
  });

  test('Prius TNGA pins MY2022/2024/2025 capture artifacts', () {
    final artifacts =
        ((rawProfile['source'] as Map)['capture_artifacts'] as List<dynamic>)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList();
    expect({
      for (final row in artifacts) row['path'] as String: row['sha256'] as String,
    }, _capturePins);
  });

  test('Prius TNGA year window stays 2016–2026', () {
    expect(profile.yearFrom, 2016);
    expect(profile.yearTo, 2026);
    expect(rawProfile['year_from'], 2016);
    expect(rawProfile['year_to'], 2026);
  });

  test('Prius TNGA does not cite the e-TNGA profile as a source', () {
    expect(profile.source.name, isNot(contains(_etngaId)));
    expect(profile.source.url, isNot(contains(_etngaId)));
    expect(profile.source.path, isNot(contains(_etngaId)));
    expect(profile.source.locator, isNot(contains(_etngaId)));
    expect(profile.source.revision, isNot(contains(_etngaId)));
    for (final secondary in profile.secondarySources) {
      expect(secondary.name, isNot(contains(_etngaId)));
      expect(secondary.url, isNot(contains(_etngaId)));
      expect(secondary.path, isNot(contains(_etngaId)));
      expect(secondary.locator, isNot(contains(_etngaId)));
    }
  });

  test('Prius TNGA dated disposition records the missing second family', () {
    final limitations = (rawProfile['limitations'] as List<dynamic>)
        .cast<String>()
        .join('\n');
    expect(limitations, contains('2026-09-11 re-evaluation'));
    expect(limitations, contains('RETAIN EXPERIMENTAL'));
    expect(limitations, contains('no Prius module'));
    expect(limitations, contains('same organization, not a second family'));
  });
}
