/// Dated #333 disposition for `toyota-etnga-bev-2022-2024`.
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

const _etngaId = 'toyota-etnga-bev-2022-2024';
const _priusId = 'toyota-prius-tnga-2016-2026';
const _obdbArtifactSha256 =
    '11e8b5957fe6ec9643f6d9afb62494e135aebb9a8c6e737c0ccd873d34b2cfdb';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PowertrainBatteryProfile profile;
  late Map<String, Object?> rawProfile;

  setUpAll(() async {
    final text = await rootBundle.loadString(
      PowertrainBatteryCatalogAsset.catalogAsset,
    );
    final catalog = PowertrainBatteryCatalog.fromJsonString(text);
    profile = catalog.profiles.singleWhere((entry) => entry.id == _etngaId);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    rawProfile = Map<String, Object?>.from(
      (decoded['profiles'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['id'] == _etngaId),
    );
  });

  test('e-TNGA status stays experimental', () {
    expect(profile.status, PowertrainProfileStatus.experimental);
    expect(rawProfile['status'], 'experimental');
  });

  test('e-TNGA commands are exactly 7D2/7DA 22 1F5B and 106C', () {
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
      const [('7D2', '7DA', '22', '1F5B', 1), ('7D2', '7DA', '22', '106C', 3)],
    );
  });

  test('e-TNGA commands do not use header 747 or responder 74F', () {
    expect(profile.commands, isNotEmpty);
    for (final command in profile.commands) {
      expect(command.requestHeader, isNot('747'), reason: command.wireKey);
      expect(command.expectedResponder, isNot('74F'), reason: command.wireKey);
    }
  });

  test('e-TNGA ships no 1F9A command', () {
    expect([
      for (final command in profile.commands) command.identifier,
    ], isNot(contains('1F9A')));
  });

  test('e-TNGA secondary_sources stays empty', () {
    expect(profile.secondarySources, isEmpty);
    final rawSecondary = rawProfile['secondary_sources'];
    expect(rawSecondary == null || (rawSecondary as List).isEmpty, isTrue);
  });

  test('e-TNGA primary artifact SHA-256 stays the OBDb pin', () {
    expect(profile.source.artifactSha256, _obdbArtifactSha256);
    expect(
      (rawProfile['source'] as Map)['artifact_sha256'],
      _obdbArtifactSha256,
    );
  });

  test('e-TNGA year_to stays 2024', () {
    expect(profile.yearTo, 2024);
    expect(rawProfile['year_to'], 2024);
  });

  test('e-TNGA does not cite the Prius profile as a source', () {
    expect(profile.source.name, isNot(contains(_priusId)));
    expect(profile.source.url, isNot(contains(_priusId)));
    expect(profile.source.path, isNot(contains(_priusId)));
    expect(profile.source.locator, isNot(contains(_priusId)));
    expect(profile.source.revision, isNot(contains(_priusId)));
    for (final secondary in profile.secondarySources) {
      expect(secondary.name, isNot(contains(_priusId)));
      expect(secondary.url, isNot(contains(_priusId)));
      expect(secondary.path, isNot(contains(_priusId)));
      expect(secondary.locator, isNot(contains(_priusId)));
    }
  });
}
