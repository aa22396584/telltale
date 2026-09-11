/// Pins the experimental install-policy docs to the catalog and `canInstall`.
///
/// The runtime already installs pollable Mode 22 experimental profiles as
/// unverified PIDs. These files used to say every experimental map was
/// laboratory-only. This suite fails if the table, README, or notices drift
/// back to that claim, or if a hand-typed count stops matching the snapshot.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_catalog_validator.dart';

const _ev9Id = 'kia-ev9-egmp-2024-2025-experimental';
const _lexusId = 'lexus-rx450hl-2020-source-vehicle';
const _priusId = 'toyota-prius-tnga-2016-2026';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PowertrainBatteryCatalog catalog;
  late Map<String, Object?> ev9Json;
  late Map<String, Object?> priusJson;

  setUpAll(() async {
    final text = await rootBundle.loadString(
      PowertrainBatteryCatalogAsset.catalogAsset,
    );
    catalog = PowertrainBatteryCatalog.fromJsonString(text);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final profiles = (decoded['profiles'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    ev9Json = Map<String, Object?>.from(
      profiles.singleWhere((entry) => entry['id'] == _ev9Id),
    );
    priusJson = Map<String, Object?>.from(
      profiles.singleWhere((entry) => entry['id'] == _priusId),
    );
  });

  test('the snapshot table matches catalog status and canInstall counts', () {
    const validator = PowertrainBatteryProfileCatalogValidator();
    final byPowertrain = <String, _Row>{};
    for (final profile in catalog.profiles) {
      final row = byPowertrain.putIfAbsent(profile.powertrain, _Row.new);
      row.profiles += 1;
      switch (profile.status) {
        case PowertrainProfileStatus.researchOnly:
          row.research += 1;
        case PowertrainProfileStatus.experimental:
          row.experimental += 1;
        case PowertrainProfileStatus.community:
        case PowertrainProfileStatus.ready:
          break;
      }
      if (validator.validateProfile(profile).canInstall) {
        row.installable += 1;
      }
    }

    final doc = File('docs/powertrain-battery-profiles.md').readAsStringSync();
    expect(
      doc,
      isNot(contains('Installable (community)')),
      reason: 'that column name hid Mode 22 experimental installs',
    );
    expect(doc, contains('Installable'));
    expect(
      doc,
      contains(
        'The last column is `community` plus pollable (Mode 22) '
        '`experimental`.',
      ),
    );

    final table = _parseSnapshotTable(doc);
    expect(table.keys.toSet(), {...byPowertrain.keys, 'Total'});
    for (final powertrain in byPowertrain.keys) {
      expect(table[powertrain], byPowertrain[powertrain], reason: powertrain);
    }

    final total = _Row();
    for (final row in byPowertrain.values) {
      total.profiles += row.profiles;
      total.research += row.research;
      total.experimental += row.experimental;
      total.installable += row.installable;
    }
    expect(table['Total'], total);
    expect(total.profiles, 221);
    expect(total.research, 205);
    expect(total.experimental, 4);
    expect(total.installable, 15);
    expect(
      catalog.profiles.where(
        (profile) => profile.status == PowertrainProfileStatus.community,
      ),
      hasLength(12),
    );
    expect(
      catalog.profiles.where(
        (profile) => profile.status == PowertrainProfileStatus.ready,
      ),
      isEmpty,
    );
  });

  test('docs split Mode 22 install from Mode 21 laboratory', () {
    final profiles = File('docs/powertrain-battery-profiles.md')
        .readAsStringSync();
    expect(
      profiles,
      isNot(contains('Experimental commands cannot be installed')),
    );
    expect(
      profiles,
      isNot(
        contains(
          'eligible only for the opt-in one-shot laboratory. It cannot '
          'be installed',
        ),
      ),
    );
    expect(profiles, contains('so `canInstall` accepts them as runtime PIDs'));
    expect(profiles, contains('"Experimental · Unverified on this vehicle"'));
    expect(
      profiles,
      contains(
        '`PollableServices` refuses as a gauge service, so it stays '
        'probe-only',
      ),
    );
    expect(
      profiles,
      contains(
        'the driver picks a `community` profile or a pollable\n   '
        '(Mode 22) `experimental` profile',
      ),
    );
    expect(profiles, contains('stays experimental and probe-only'));

    final notices = File('THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md')
        .readAsStringSync();
    expect(notices, isNot(contains('four one-shot')));
    expect(
      notices,
      contains(
        'three pollable Mode 22 maps that may be installed as unverified',
      ),
    );
    expect(notices, contains('one Mode 21 map that remains laboratory-only'));
    expect(
      notices,
      contains(
        'so the subset is one-shot experimental only and cannot be installed.',
      ),
      reason: 'Lexus Mode 21 stays laboratory-only',
    );
    expect(
      notices,
      isNot(
        contains(
          'All licensed evidence is one organization, so the subset is '
          'one-shot\nexperimental only and cannot be installed.',
        ),
      ),
    );
    expect(
      notices,
      contains('Pollable (Mode 22) `experimental` entries may also install'),
    );

    final readme = File('README.md').readAsStringSync();
    expect(readme, isNot(contains('restricted to the one-shot laboratory')));
    expect(
      readme,
      contains('Three Mode 22 maps (Prius, EV9,\n  e-TNGA) may be installed'),
    );
    expect(readme, contains('labelled Experimental · Unverified on this'));
    expect(readme, contains('the one-shot laboratory'));

    final zh = File('README.zh-TW.md').readAsStringSync();
    expect(zh, isNot(contains('只能走單次實驗室的 `experimental`')));
    expect(zh, contains('其中三筆 Mode 22（Prius、EV9、e-TNGA）可安裝'));
    expect(zh, contains('實驗 · 本車未驗證'));
    expect(zh, contains('只能走單次實驗室'));

    final index = File('docs/README.md').readAsStringSync();
    expect(index, contains('schema-v3'));
    expect(index, isNot(contains('schema-v2')));
    expect(index, contains('pollable-experimental maps'));
    expect(index, contains('Mode 21 one-shot laboratory'));
  });

  test('EV9 notices pin the catalog source revision, licence, and hashes', () {
    final notices = File('THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md')
        .readAsStringSync();
    final source = Map<String, Object?>.from(ev9Json['source']! as Map);
    expect(notices, contains('### Kia EV9 (E-GMP) experimental subset'));
    expect(notices, contains(source['name'] as String));
    expect(notices, contains(source['revision'] as String));
    expect(notices, contains(source['license'] as String));
    expect(notices, contains(source['path'] as String));
    expect(notices, contains(source['artifact_sha256'] as String));
    for (final artifact in source['capture_artifacts']! as List<dynamic>) {
      final row = Map<String, Object?>.from(artifact as Map);
      expect(
        notices,
        contains(row['sha256'] as String),
        reason: '${row['path']}',
      );
    }
    expect(
      notices,
      contains(
        'it may be installed as unverified PIDs and is not '
        'community-corroborated.',
      ),
    );

    const validator = PowertrainBatteryProfileCatalogValidator();
    final ev9 = catalog.profiles.singleWhere((profile) => profile.id == _ev9Id);
    final lexus = catalog.profiles.singleWhere(
      (profile) => profile.id == _lexusId,
    );
    expect(validator.validateProfile(ev9).canInstall, isTrue);
    expect(validator.validateProfile(lexus).canInstall, isFalse);
  });

  test('Prius notices pin the catalog source revision, licence, and hashes', () {
    final notices = File('THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md')
        .readAsStringSync();
    final source = Map<String, Object?>.from(priusJson['source']! as Map);
    expect(notices, contains('### Toyota Prius TNGA experimental subset'));
    expect(notices, contains(source['name'] as String));
    expect(notices, contains(source['revision'] as String));
    expect(notices, contains(source['license'] as String));
    expect(notices, contains(source['path'] as String));
    expect(notices, contains(source['artifact_sha256'] as String));
    for (final artifact in source['capture_artifacts']! as List<dynamic>) {
      final row = Map<String, Object?>.from(artifact as Map);
      expect(
        notices,
        contains(row['sha256'] as String),
        reason: '${row['path']}',
      );
    }
    expect(
      notices,
      contains(
        'it may be installed as unverified PIDs and is not '
        'community-corroborated.',
      ),
    );

    const validator = PowertrainBatteryProfileCatalogValidator();
    final prius = catalog.profiles.singleWhere(
      (profile) => profile.id == _priusId,
    );
    expect(validator.validateProfile(prius).canInstall, isTrue);
  });
}

final class _Row {
  int profiles = 0;
  int research = 0;
  int experimental = 0;
  int installable = 0;

  @override
  bool operator ==(Object other) =>
      other is _Row &&
      profiles == other.profiles &&
      research == other.research &&
      experimental == other.experimental &&
      installable == other.installable;

  @override
  int get hashCode =>
      Object.hash(profiles, research, experimental, installable);

  @override
  String toString() =>
      'profiles=$profiles research=$research experimental=$experimental '
      'installable=$installable';
}

Map<String, _Row> _parseSnapshotTable(String doc) {
  final match = RegExp(
    r'\| Powertrain \| Profiles \| Research-only \| Experimental \| '
    r'Installable \|\n\| [^\n]+\n((?:\|[^\n]+\n)+)',
  ).firstMatch(doc);
  expect(match, isNotNull, reason: 'snapshot table missing or header drifted');
  final rows = <String, _Row>{};
  for (final line in match!.group(1)!.trimRight().split('\n')) {
    final cells = line
        .split('|')
        .map((cell) => cell.trim().replaceAll('*', ''))
        .where((cell) => cell.isNotEmpty)
        .toList();
    expect(cells, hasLength(5), reason: line);
    rows[cells[0]] = _Row()
      ..profiles = int.parse(cells[1])
      ..research = int.parse(cells[2])
      ..experimental = int.parse(cells[3])
      ..installable = int.parse(cells[4]);
  }
  return rows;
}
