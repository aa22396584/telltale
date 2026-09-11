/// Dated #333 disposition for `lexus-rx450hl-2020-source-vehicle`.
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

const _lexusId = 'lexus-rx450hl-2020-source-vehicle';
const _artifactSha256 =
    '8109db2ef0164a199d08afb2c6cfc2c419801d0a508cbfcaa52e657e0e46d29c';
const _revision = 'f93d7a0afb1cfb8aff9681a7db33db46d55804a2';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PowertrainBatteryProfile profile;
  late Map<String, Object?> rawProfile;

  setUpAll(() async {
    final text = await rootBundle.loadString(
      PowertrainBatteryCatalogAsset.catalogAsset,
    );
    final catalog = PowertrainBatteryCatalog.fromJsonString(text);
    profile = catalog.profiles.singleWhere((entry) => entry.id == _lexusId);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    rawProfile = Map<String, Object?>.from(
      (decoded['profiles'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['id'] == _lexusId),
    );
  });

  test('RX450hL status stays experimental', () {
    expect(profile.status, PowertrainProfileStatus.experimental);
    expect(rawProfile['status'], 'experimental');
  });

  test('RX450hL Mode 21 cannot be installed', () {
    const validator = PowertrainBatteryProfileCatalogValidator();
    expect(validator.validateProfile(profile).canInstall, isFalse);
  });

  test('RX450hL commands are exactly 7E2/7EA Mode 21 61/62/63/95', () {
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
        ('7E2', '7EA', '21', '61', 5),
        ('7E2', '7EA', '21', '62', 5),
        ('7E2', '7EA', '21', '63', 5),
        ('7E2', '7EA', '21', '95', 4),
      ],
    );
    expect([
      for (final command in profile.commands) command.identifier,
    ], isNot(contains('98')));
  });

  test('RX450hL 61/62/63 stay torque windows, not Ircama MG temperatures', () {
    for (final identifier in ['61', '62', '63']) {
      final command = profile.commands.singleWhere(
        (entry) => entry.identifier == identifier,
      );
      expect(command.signals, hasLength(1));
      expect(command.signals.single.equation, '((A*256+B)-32768)/8');
      expect(command.signals.single.unit, 'Nm');
      expect(command.signals.single.offset, 3);
      expect(command.signals.single.equation, isNot('A-40'));
    }
  });

  test('RX450hL 95 stays battery temperatures, not Ircama internal resistance', () {
    final command = profile.commands.singleWhere(
      (entry) => entry.identifier == '95',
    );
    expect(command.signals, hasLength(4));
    for (final signal in command.signals) {
      expect(signal.equation, 'A');
      expect(signal.unit, 'C');
      expect(signal.equation, isNot('A / 1000'));
    }
  });

  test('RX450hL secondary_sources stays empty', () {
    expect(profile.secondarySources, isEmpty);
    final rawSecondary = rawProfile['secondary_sources'];
    expect(rawSecondary == null || (rawSecondary as List).isEmpty, isTrue);
  });

  test('RX450hL primary artifact SHA-256 stays the NathanNam pin', () {
    expect(profile.source.artifactSha256, _artifactSha256);
    expect(profile.source.revision, _revision);
    expect(profile.source.license, 'Apache-2.0');
  });

  test('RX450hL year window stays 2020 only', () {
    expect(profile.yearFrom, 2020);
    expect(profile.yearTo, 2020);
    expect(rawProfile['year_from'], 2020);
    expect(rawProfile['year_to'], 2020);
  });

  test('RX450hL dated disposition records Ircama as disagreement not corroboration', () {
    final limitations = (rawProfile['limitations'] as List<dynamic>)
        .cast<String>()
        .join('\n');
    expect(limitations, contains('2026-09-11 re-evaluation'));
    expect(limitations, contains('RETAIN EXPERIMENTAL'));
    expect(limitations, contains('disagreeing family'));
    expect(limitations, contains('2161/2162'));
    expect(limitations, contains('lab-only'));
  });
}
