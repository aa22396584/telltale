// Both languages for the powertrain-battery catalog.
//
// What these assert is deliberately NOT "the widget shows the ARB entry" — a
// finder that reads the same ARB the widget rendered agrees with itself and
// passes on a wrong translation. They assert the properties a wrong
// translation breaks:
//
//   * the English build renders no Chinese anywhere on the screen or in its
//     two consent dialogs;
//   * the Traditional Chinese build still carries the hedges that make this
//     screen safe to ship;
//   * the four provenance/installability enums are answered in both
//     languages, with the arms that must stay distinguishable staying so.
//
// The catalog fixture is English-only on purpose. The shipped catalog carries
// Chinese `description` and `limitations` strings, which are DATA, not copy
// this screen owns; pumping it at `en` would fail the no-Chinese sweep for a
// reason no translation could fix and would hide the failures that matter.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_catalog_screen.dart';
import 'package:torque_obd/ui/widgets/panel.dart';

import '../support/localized_app.dart';

final _cjk = RegExp(r'[㐀-鿿豈-﫿]');

const _primarySha =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _secondarySha =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _experimentalSha =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, Object?> _source({
  required String name,
  required String path,
  required String sha,
  required String locator,
  String license = 'Apache-2.0',
}) => {
  'name': name,
  'url': 'https://github.com/example/$path',
  'revision': _revision,
  'license': license,
  'path': path,
  'locator': locator,
  'artifact_sha256': sha,
};

Map<String, Object?> _signal(String id, String name) => {
  'id': id,
  'name': name,
  'offset': 0,
  'width': 2,
  'equation': '(A*256+B)/10',
  'unit': '%',
  'min_value': 0,
  'max_value': 100,
  'semantic_kind': 'traction_battery_soc',
  'recommended': true,
};

/// Three tiers, all with English data, so the only Chinese a pump at `en` can
/// produce is copy this screen owns.
final _catalogJson = jsonEncode({
  'schema_version': 3,
  'profiles': [
    {
      'id': 'community-bev',
      'display_name': 'Example Community BEV',
      'description': 'Cross-corroborated read-only battery mapping.',
      'limitations': ['Never driven on a real vehicle by this project.'],
      'status': 'community',
      'evidence': 'sourceBacked',
      'market': 'Synthetic laboratory',
      'make': 'Example',
      'model': 'Community BEV',
      'year_from': 2021,
      'year_to': 2023,
      'variant': 'fixture-v1',
      'powertrain': 'BEV',
      'identity_evidence': {
        'market': 'exact',
        'year': 'exact',
        'model': 'exact',
        'variant': 'exact',
      },
      'source': _source(
        name: 'Pinned source',
        path: 'profiles/example.json',
        sha: _primarySha,
        locator: 'vehicle/example',
      ),
      'secondary_sources': [
        _source(
          name: 'Independent poller',
          path: 'src/poller.cpp',
          sha: _secondarySha,
          locator: 'poll table 22B046',
          license: 'MIT',
        ),
      ],
      'commands': [
        {
          'request_header': '781',
          'expected_responder': '789',
          'mode': '22',
          'identifier': 'B046',
          'payload_length': 2,
          'signals': [_signal('raw-soc', 'Raw SOC')],
        },
      ],
    },
    {
      // Mode 21 is probe-only, so this row exercises the "experimental,
      // one-shot read-only, cannot be installed" branch of the status pill.
      'id': 'experimental-hev',
      'display_name': 'Example Experimental HEV',
      'description': 'Single-source candidate decode.',
      'limitations': ['One licensed source only; no independent agreement.'],
      'status': 'experimental',
      'evidence': 'sourceBacked',
      'market': 'Synthetic laboratory',
      'make': 'Example',
      'model': 'Experimental HEV',
      'year_from': 2020,
      'year_to': 2020,
      'variant': 'fixture-v1',
      'powertrain': 'HEV',
      // Deliberately mixed, so the consent dialog has to render all three
      // evidence levels and name a field the source never established.
      'identity_evidence': {
        'market': 'exact',
        'year': 'exact',
        'model': 'sourcePartial',
        'variant': 'unknown',
      },
      'source': _source(
        name: 'Capture archive',
        path: 'captures/example.txt',
        sha: _experimentalSha,
        locator: 'capture 2161',
      ),
      'commands': [
        {
          'request_header': '7E2',
          'expected_responder': '7EA',
          'mode': '21',
          'identifier': '61',
          'payload_length': 2,
          'signals': [_signal('raw-pack', 'Raw pack')],
        },
      ],
    },
    {
      'id': 'research-phev',
      'display_name': 'Example Research PHEV',
      'description': 'Identity index with no executable command.',
      'limitations': ['Metadata only; this entry cannot query a vehicle.'],
      'status': 'researchOnly',
      'evidence': 'sourceBacked',
      'market': 'Source-unspecified',
      'make': 'Example',
      'model': 'Research PHEV',
      'year_from': 2021,
      'year_to': 2023,
      'variant': 'source-unspecified',
      'powertrain': 'PHEV',
      'source': _source(
        name: 'Pinned source',
        path: 'profiles/example.json',
        sha: '',
        locator: 'vehicle/example',
      ),
      'commands': <Object?>[],
    },
  ],
});

/// Built from the catalog bytes rather than pinned, so editing the fixture
/// above cannot leave a stale hash that fails for the wrong reason.
String get _manifestJson => jsonEncode({
  'schema_version': 3,
  'catalog_file': 'powertrain_battery_catalog.json',
  'sha256': PowertrainBatteryCatalogAsset.sha256Hex(utf8.encode(_catalogJson)),
  'size_bytes': utf8.encode(_catalogJson).length,
  'profile_count': 3,
  'signal_count': 2,
  'counts_by_powertrain': {'BEV': 1, 'HEV': 1, 'PHEV': 1},
});

PowertrainBatteryCatalogSnapshot get _snapshot =>
    PowertrainBatteryCatalogAsset.fromStrings(
      manifestJson: _manifestJson,
      catalogJson: _catalogJson,
    );

final class _ConnectedObdSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Test rig',
    protocol: 'ISO 15765-4 CAN 11/500',
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required Locale locale,
  bool experimentalAccess = false,
  bool connected = false,
  bool loadError = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (experimentalAccess) 'powertrain_battery_experiments_enabled_v1': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      powertrainBatteryCatalogLoaderProvider.overrideWithValue(
        loadError
            ? () async => throw const PowertrainBatteryCatalogAssetException(
                'fixture integrity failure',
              )
            : () async => _snapshot,
      ),
      if (connected) obdSessionProvider.overrideWith(_ConnectedObdSession.new),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        home: const PowertrainBatteryCatalogScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Everything a driver can read: `Text`, the plain text of a `TextSpan`, and
/// every `Semantics` label — the accessibility copy is shipped copy too.
Iterable<String> _renderedStrings(WidgetTester tester) sync* {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null) yield data;
    final span = text.textSpan;
    if (span != null) yield span.toPlainText();
  }
  for (final semantics in tester.widgetList<Semantics>(find.byType(Semantics))) {
    final label = semantics.properties.label;
    if (label != null) yield label;
  }
}

/// Narrows the list to one card. `ListView` virtualizes, so a card that never
/// scrolls into view is never built and never swept.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(
    find.byKey(const Key('powertrain_profile_search')),
    query,
  );
  await tester.pumpAndSettle();
}

void _expectNoChinese(WidgetTester tester, String where) {
  final offenders = [
    for (final value in _renderedStrings(tester))
      if (_cjk.hasMatch(value)) value,
  ];
  expect(
    offenders,
    isEmpty,
    reason:
        'an English-speaking driver reads Chinese in $where:\n'
        '${offenders.join("\n")}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('English fits a phone-width card', () {
    testWidgets('the whole screen lays out at 360dp', (tester) async {
      // English is longer than Chinese, and 800x600 is not a phone: copy that
      // fits the default test surface can still overflow the narrowest
      // shipping width.
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final container = await _pump(
        tester,
        locale: englishLocale,
        experimentalAccess: true,
        connected: true,
      );
      addTearDown(container.dispose);
      expect(tester.takeException(), isNull, reason: 'the catalog list');
      for (final tier in ['Research', 'Experimental', 'Community']) {
        await _search(tester, tier);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the $tier card overflows at 360dp in English',
        );
      }
    });

    testWidgets('no status pill overflows the card header', (tester) async {
      // Measured one pill at a time against a fresh render tree. `RenderFlex`
      // reports an overflow only when the overflowing amount CHANGES, so
      // reusing one tree lets a second too-wide pill hide behind the first —
      // which is exactly how the second of these two was nearly missed.
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final pills = <String>[
        for (final status in PowertrainProfileStatus.values)
          for (final installable in [true, false])
            powertrainProfileStatusLabel(en, status, installable: installable),
        for (final evidence in PowertrainProfileEvidence.values)
          powertrainProfileEvidenceLabel(en, evidence),
        en.powertrainQuarantinedPill,
      ];
      for (final label in pills) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.takeException();
        await tester.pumpWidget(
          localizedMaterialApp(
            locale: englishLocale,
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: Text('Example Experimental HEV')),
                      StatusPill(label: label, dense: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'the "$label" pill overflows the card header at 360dp',
        );
      }
    });
  });

  group('the English build renders no Chinese', () {
    testWidgets('catalog list, install dialog and probe consent', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        locale: englishLocale,
        experimentalAccess: true,
        connected: true,
      );
      addTearDown(container.dispose);

      // The list, then each tier on its own: the list virtualizes, so a card
      // that never scrolls into view is never swept.
      expect(find.text('Example Community BEV'), findsOneWidget);
      _expectNoChinese(tester, 'the catalog list');
      for (final tier in ['Research', 'Experimental', 'Community']) {
        await _search(tester, tier);
        _expectNoChinese(tester, 'the $tier card');
      }

      // The install disclosure — the densest hedge on this screen.
      await tester.ensureVisible(
        find.byKey(const Key('powertrain_install_community-bev')),
      );
      await tester.tap(
        find.byKey(const Key('powertrain_install_community-bev')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('powertrain_install_disclosure')),
        findsOneWidget,
      );
      _expectNoChinese(tester, 'the install dialog');
      await tester.tap(find.text(en.powertrainCancel));
      await tester.pumpAndSettle();

      // The one-shot laboratory: command chooser, then the consent dialog.
      await _search(tester, 'Experimental');
      final probe = find.byKey(const Key('powertrain_probe_experimental-hev'));
      await tester.ensureVisible(probe);
      await tester.tap(probe);
      await tester.pumpAndSettle();
      _expectNoChinese(tester, 'the command chooser');

      await tester.tap(
        find.byKey(const Key('powertrain_probe_command_experimental-hev_2161')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('powertrain_experimental_data_disclosure')),
        findsOneWidget,
      );
      _expectNoChinese(tester, 'the one-shot consent dialog');
      await tester.tap(find.text(en.powertrainCancel));
      await tester.pumpAndSettle();
    });

    testWidgets('the fail-closed load error', (tester) async {
      final container = await _pump(
        tester,
        locale: englishLocale,
        loadError: true,
      );
      addTearDown(container.dispose);
      expect(find.text(en.powertrainCatalogLoadFailedTitle), findsOneWidget);
      _expectNoChinese(tester, 'the catalog load failure');
    });

    testWidgets('the empty search result', (tester) async {
      final container = await _pump(tester, locale: englishLocale);
      addTearDown(container.dispose);
      await tester.enterText(
        find.byKey(const Key('powertrain_profile_search')),
        'no such vehicle',
      );
      await tester.pumpAndSettle();
      expect(find.text(en.powertrainNoMatchTitle), findsOneWidget);
      _expectNoChinese(tester, 'the empty search result');
    });
  });

  group('the Traditional Chinese build keeps its hedges', () {
    testWidgets('the catalog separates "found" from "supported"', (
      tester,
    ) async {
      final container = await _pump(tester, locale: traditionalChineseLocale);
      addTearDown(container.dispose);

      // "we found data" is not "your car is supported".
      expect(find.textContaining('不等於「已支援」'), findsOneWidget);
      // researchOnly says both what it is and that it will never query.
      await _search(tester, 'Research');
      final research = find.byKey(const Key('powertrain_profile_research-phev'));
      await tester.ensureVisible(research);
      expect(
        find.descendant(of: research, matching: find.text('僅研究')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: research, matching: find.text('僅研究，不會查詢')),
        findsOneWidget,
      );
      // The experimental row is labelled one-shot read-only, not installable.
      await _search(tester, 'Experimental');
      final experimental = find.byKey(
        const Key('powertrain_profile_experimental-hev'),
      );
      await tester.ensureVisible(experimental);
      expect(
        find.descendant(of: experimental, matching: find.text('實驗單次唯讀')),
        findsOneWidget,
      );
    });

    testWidgets('the install disclosure keeps its per-connection demand', (
      tester,
    ) async {
      final container = await _pump(tester, locale: traditionalChineseLocale);
      addTearDown(container.dispose);
      await _search(tester, 'Community');
      await tester.ensureVisible(
        find.byKey(const Key('powertrain_install_community-bev')),
      );
      await tester.tap(
        find.byKey(const Key('powertrain_install_community-bev')),
      );
      await tester.pumpAndSettle();
      final disclosure = tester
          .widget<Text>(find.byKey(const Key('powertrain_install_disclosure')))
          .data!;
      expect(disclosure, contains('每次連線'));
      expect(disclosure, contains('仍非原廠保證'));
      await tester.tap(find.text(zh.powertrainCancel));
      await tester.pumpAndSettle();
    });

    testWidgets('the one-shot consent keeps all four of its claims', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        locale: traditionalChineseLocale,
        experimentalAccess: true,
        connected: true,
      );
      addTearDown(container.dispose);
      await _search(tester, 'Experimental');
      final probe = find.byKey(const Key('powertrain_probe_experimental-hev'));
      await tester.ensureVisible(probe);
      await tester.tap(probe);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('powertrain_probe_command_experimental-hev_2161')),
      );
      await tester.pumpAndSettle();

      final disclosure = tester
          .widget<Text>(
            find.byKey(const Key('powertrain_experimental_data_disclosure')),
          )
          .data!;
      expect(disclosure, contains('ELM327'));
      expect(disclosure, contains('本機診斷紀錄'));
      expect(disclosure, contains('不會由此功能自動上傳'));
      expect(disclosure, contains('取消不影響一般 OBD 功能'));

      // The identity summary must still name the fields the source left open.
      final evidence = tester
          .widget<Text>(
            find.byKey(const Key('powertrain_experimental_identity_evidence')),
          )
          .data!;
      expect(evidence, contains('未證實欄位'));
      expect(evidence, contains('未知'));
      await tester.tap(find.text(zh.powertrainCancel));
      await tester.pumpAndSettle();
    });
  });

  group('every enum arm is answered in both languages', () {
    test('PowertrainProfileStatus → install disclosure', () {
      for (final l10n in [en, zh]) {
        final seen = <String>{};
        for (final status in PowertrainProfileStatus.values) {
          final copy = powertrainInstallDisclosure(l10n, status);
          expect(copy.trim(), isNotEmpty, reason: '$status');
          expect(
            seen.add(copy),
            isTrue,
            reason: '$status repeats another status\'s disclosure',
          );
        }
      }
      for (final status in PowertrainProfileStatus.values) {
        expect(
          powertrainInstallDisclosure(en, status),
          isNot(matches(_cjk)),
          reason: '$status renders Chinese in English',
        );
        expect(
          powertrainInstallDisclosure(en, status),
          isNot(powertrainInstallDisclosure(zh, status)),
          reason: '$status is untranslated (English fallback)',
        );
      }
    });

    test('PowertrainProfileStatus → pill label', () {
      for (final l10n in [en, zh]) {
        for (final installable in [true, false]) {
          final seen = <String>{};
          for (final status in PowertrainProfileStatus.values) {
            final label = powertrainProfileStatusLabel(
              l10n,
              status,
              installable: installable,
            );
            expect(label.trim(), isNotEmpty, reason: '$status/$installable');
            expect(seen.add(label), isTrue, reason: '$status/$installable');
          }
        }
      }
      for (final status in PowertrainProfileStatus.values) {
        expect(
          powertrainProfileStatusLabel(en, status, installable: false),
          isNot(matches(_cjk)),
        );
        expect(
          powertrainProfileStatusLabel(en, status, installable: false),
          isNot(powertrainProfileStatusLabel(zh, status, installable: false)),
          reason: '$status is untranslated (English fallback)',
        );
      }
    });

    test('PowertrainProfileEvidence', () {
      for (final l10n in [en, zh]) {
        final seen = <String>{};
        for (final evidence in PowertrainProfileEvidence.values) {
          final label = powertrainProfileEvidenceLabel(l10n, evidence);
          expect(label.trim(), isNotEmpty, reason: '$evidence');
          expect(seen.add(label), isTrue, reason: '$evidence');
        }
      }
      for (final evidence in PowertrainProfileEvidence.values) {
        expect(
          powertrainProfileEvidenceLabel(en, evidence),
          isNot(matches(_cjk)),
        );
        expect(
          powertrainProfileEvidenceLabel(en, evidence),
          isNot(powertrainProfileEvidenceLabel(zh, evidence)),
          reason: '$evidence is untranslated (English fallback)',
        );
      }
    });

    test('PowertrainIdentityEvidenceLevel', () {
      for (final l10n in [en, zh]) {
        final seen = <String>{};
        for (final level in PowertrainIdentityEvidenceLevel.values) {
          final label = powertrainIdentityEvidenceLabel(l10n, level);
          expect(label.trim(), isNotEmpty, reason: '$level');
          expect(seen.add(label), isTrue, reason: '$level');
        }
      }
      for (final level in PowertrainIdentityEvidenceLevel.values) {
        expect(powertrainIdentityEvidenceLabel(en, level), isNot(matches(_cjk)));
        expect(
          powertrainIdentityEvidenceLabel(en, level),
          isNot(powertrainIdentityEvidenceLabel(zh, level)),
          reason: '$level is untranslated (English fallback)',
        );
      }
    });
  });

  group('the distinctions this screen refuses to blur', () {
    test('research-only never reads as installable or supported', () {
      // The tier that must never be mistaken for something that works.
      expect(
        powertrainInstallDisclosure(
          en,
          PowertrainProfileStatus.researchOnly,
        ).toLowerCase(),
        contains('should not be installed'),
      );
      expect(
        powertrainInstallDisclosure(zh, PowertrainProfileStatus.researchOnly),
        contains('不應安裝'),
      );
      // Its button states a refusal, not a temporary unavailability.
      expect(en.powertrainResearchOnlyNeverQueries.toLowerCase(), contains('research only'));
      expect(zh.powertrainResearchOnlyNeverQueries, contains('不會查詢'));
    });

    test('the installable tiers all keep the "not a guarantee" clause', () {
      for (final status in [
        PowertrainProfileStatus.ready,
        PowertrainProfileStatus.community,
        PowertrainProfileStatus.experimental,
      ]) {
        expect(
          powertrainInstallDisclosure(en, status).toLowerCase(),
          contains('not a manufacturer guarantee'),
          reason: '$status dropped the guarantee hedge in English',
        );
        expect(
          powertrainInstallDisclosure(zh, status),
          contains('仍非原廠保證'),
          reason: '$status dropped the guarantee hedge in Chinese',
        );
      }
    });

    test('an experimental row that cannot be installed says so', () {
      for (final l10n in [en, zh]) {
        expect(
          powertrainProfileStatusLabel(
            l10n,
            PowertrainProfileStatus.experimental,
            installable: true,
          ),
          isNot(
            powertrainProfileStatusLabel(
              l10n,
              PowertrainProfileStatus.experimental,
              installable: false,
            ),
          ),
          reason:
              'a probe-only row and an installable-but-unverified row would '
              'read the same',
        );
      }
    });

    test('an unknown field is not an empty list of unknown fields', () {
      // "unknown" describes one field the source never established;
      // "none" says the list of such fields is empty. Merging them would tell
      // a driver a fully unconfirmed profile has nothing left to confirm.
      for (final l10n in [en, zh]) {
        expect(
          l10n.powertrainIdentityEvidenceUnknown,
          isNot(l10n.powertrainIdentityEvidenceNone),
        );
      }
    });

    test('absent identity evidence reads exactly like all-unknown evidence', () {
      const allUnknown = PowertrainBatteryIdentityEvidence(
        market: PowertrainIdentityEvidenceLevel.unknown,
        year: PowertrainIdentityEvidenceLevel.unknown,
        model: PowertrainIdentityEvidenceLevel.unknown,
        variant: PowertrainIdentityEvidenceLevel.unknown,
      );
      for (final l10n in [en, zh]) {
        expect(
          powertrainIdentityEvidenceSummary(l10n, null),
          powertrainIdentityEvidenceSummary(l10n, allUnknown),
        );
        // All four names appear, and all four are listed as unconfirmed.
        for (final field in [
          l10n.powertrainFieldMarket,
          l10n.powertrainFieldModelYear,
          l10n.powertrainFieldModel,
          l10n.powertrainFieldVariant,
        ]) {
          expect(
            powertrainIdentityEvidenceSummary(l10n, null),
            contains(field),
          );
        }
      }
      expect(
        powertrainIdentityEvidenceSummary(en, null),
        isNot(matches(_cjk)),
      );
    });

    test('fully evidenced identity lists no unconfirmed field', () {
      const exact = PowertrainBatteryIdentityEvidence(
        market: PowertrainIdentityEvidenceLevel.exact,
        year: PowertrainIdentityEvidenceLevel.exact,
        model: PowertrainIdentityEvidenceLevel.exact,
        variant: PowertrainIdentityEvidenceLevel.exact,
      );
      for (final l10n in [en, zh]) {
        final summary = powertrainIdentityEvidenceSummary(l10n, exact);
        expect(summary, contains(l10n.powertrainIdentityEvidenceNone));
        expect(summary, isNot(contains(l10n.powertrainIdentityEvidenceUnknown)));
      }
    });

    test('a quarantined probe and an unconnected probe give different reasons', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.powertrainProbeReconnectFirst,
          isNot(l10n.powertrainProbeConnectForOneShot),
        );
        expect(
          l10n.powertrainProbeReconnectFirst,
          isNot(l10n.powertrainProbeEnableLabFirst),
        );
      }
    });

    test('a catalog that failed verification is not a retryable storage error', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.powertrainCatalogNotVerified,
          isNot(l10n.powertrainRestoreStorageErrorRetry),
        );
      }
    });

    test('counts come from the catalog, never spelled into the copy', () {
      for (final l10n in [en, zh]) {
        expect(l10n.powertrainCatalogCounts(221, 16), contains('221'));
        expect(l10n.powertrainCatalogCounts(221, 16), contains('16'));
        expect(l10n.powertrainSignalCount(157), contains('157'));
        expect(l10n.powertrainInstalledSignalsSnack(9), contains('9'));
        expect(l10n.powertrainVehicleYearFixed(2021), contains('2021'));
      }
      // No thousands separator: a model year is an identifier, not a quantity.
      expect(en.powertrainVehicleYearFixed(2021), isNot(contains('2,021')));
    });
  });
}
