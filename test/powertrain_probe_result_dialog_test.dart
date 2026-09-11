/// Successful one-shot probe results must carry the unverified stamp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_probe.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_catalog_screen.dart';

import 'support/localized_app.dart';
import 'support/powertrain_snapshot_fixture.dart';

Map<String, Object?> _mode21Experimental() => {
  'id': 'experimental-hev',
  'display_name': 'Example Experimental HEV',
  'description': 'Single-source candidate decode.',
  'limitations': ['fixture'],
  'status': 'experimental',
  'evidence': 'sourceBacked',
  'market': 'Synthetic laboratory',
  'make': 'Example',
  'model': 'Experimental HEV',
  'year_from': 2020,
  'year_to': 2020,
  'variant': 'fixture-v1',
  'powertrain': 'HEV',
  'identity_evidence': {
    'market': 'exact',
    'year': 'exact',
    'model': 'sourcePartial',
    'variant': 'unknown',
  },
  'source': {
    'name': 'Capture archive',
    'url': 'https://example.invalid/capture',
    'revision': 'a' * 40,
    'license': 'Apache-2.0',
    'path': 'captures/example.txt',
    'locator': 'capture 2161',
    'artifact_sha256': 'c' * 64,
  },
  'commands': [
    {
      'request_header': '7E2',
      'expected_responder': '7EA',
      'mode': '21',
      'identifier': '61',
      'payload_length': 2,
      'signals': [
        {
          'id': 'raw-pack',
          'name': 'Raw pack',
          'offset': 0,
          'width': 2,
          'equation': '(A*256+B)/10',
          'unit': '%',
          'min_value': 0,
          'max_value': 100,
          'semantic_kind': 'traction_battery_soc',
          'recommended': true,
        },
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a successful experimental probe is stamped unverified on this vehicle',
    (tester) async {
      final snapshot = snapshotOfProfiles([_mode21Experimental()]);
      final profile = snapshot.catalog.profiles.single;
      final command = profile.commands.single;
      final result = PowertrainBatteryProbeResult.success(
        profileId: profile.id,
        catalogSha256: snapshot.catalogSha256,
        sourceRevision: profile.source.revision,
        command: command,
        responder: '7EA',
        rawResponseBytes: const [0x61, 0x61, 0x01, 0xF4],
        payloadBytes: const [0x01, 0xF4],
        readings: [
          PowertrainBatteryProbeSignalReading(
            signal: command.signals.single,
            value: 50,
            rawBytes: const [0x01, 0xF4],
          ),
        ],
        capturedAt: DateTime.utc(2026),
      );

      await tester.pumpWidget(
        localizedMaterialApp(
          theme: AppTheme.dark(),
          locale: englishLocale,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => PowertrainProbeResultDialog(
                      result: result,
                      profileStatus: PowertrainProfileStatus.experimental,
                    ),
                  );
                },
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.text('Raw pack: 50.0 % · bytes 01 F4'), findsOneWidget);
      expect(
        find.byKey(const Key('powertrain_probe_unverified_stamp')),
        findsOneWidget,
      );
      expect(find.textContaining('Experimental'), findsOneWidget);
      expect(
        find.textContaining('Unverified on this vehicle'),
        findsOneWidget,
      );
      expect(find.textContaining('Partial'), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('powertrain_probe_unverified_stamp')),
            )
            .data,
        isNot(contains('Partial')),
      );
    },
  );
}
