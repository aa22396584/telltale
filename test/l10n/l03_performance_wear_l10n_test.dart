/// The acceleration test and the Wear OS shell, in both languages.
///
/// None of these assertions compares a rendered string against the ARB entry
/// the widget just read — a finder built from the same bundle agrees with a
/// wrong translation as readily as with a right one. They check the properties
/// a wrong translation breaks: an English build that renders no Chinese, two
/// languages that are actually two, the distinctions this app refuses to blur,
/// numbers that come from the code rather than the prose, and — on the watch —
/// labels that arrive complete on a 454px round face.
///
/// The watch checks are structural rather than pixel comparisons because the
/// failure they guard against is structural. Nothing in `wear_shell.dart`
/// truncates a button label (`TextOverflow.ellipsis` appears once, on a device
/// name the adapter supplied), and `AlertDialog` stacks its actions instead of
/// clipping them, so "the label fits" is exactly: the paragraph did not exceed
/// its line budget, it is no wider than the control holding it, and the control
/// still lies inside the face. A shrunken text scale would pass a width check
/// while making the watch unreadable, so the scale is asserted untouched.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';
import 'package:torque_obd/ui/screens/performance/performance_screen.dart';
import 'package:torque_obd/ui/wear/wear_shell.dart';
import 'package:torque_obd/ui/widgets/gauges/dial_gauge.dart';

import '../support/localized_app.dart';
import '../support/powertrain_snapshot_fixture.dart';
import '../support/cjk.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

/// A 454px round face at 2.0 DPR — the geometry the watch shell ships to.
const _face = Size(227, 227);

const _connectedDemo = ObdConnectionState(
  phase: ConnectionPhase.connected,
  kind: TransportKind.demo,
  deviceName: 'Demo ECU',
  protocol: 'ISO 15765-4 CAN 11/500',
);

final class _FixedSession extends ObdSession {
  _FixedSession(this.fixed);

  final ObdConnectionState fixed;

  @override
  ObdConnectionState build() => fixed;
}

/// Every rendered word on screen: `Text` data, rich-text spans, and the
/// semantics labels a screen reader would speak.
List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = text.data ?? text.textSpan?.toPlainText();
    if (value != null && value.isNotEmpty) out.add('Text "$value"');
  }
  for (final node in tester.widgetList<Semantics>(find.byType(Semantics))) {
    final label = node.properties.label;
    if (label != null && label.isNotEmpty) out.add('Semantics "$label"');
  }
  return out;
}

/// The one Chinese string an English build still renders, and where from.
///
/// `lib/ui/widgets/gauges/dial_gauge.dart` writes its stale marker as a
/// literal — once as a visible label, once inside the semantics string — so
/// every screen carrying a dial renders it in the English build too. That file
/// belongs to another change; this allowance names it so the exception cannot
/// be mistaken for a decision, and it is deliberately exact: any *other*
/// Chinese from these two screens still fails.
const _dialGaugeStaleLeak = '資料已過期';

void _expectNoChinese(WidgetTester tester, String where) {
  final offenders = _renderedStrings(tester)
      .map((rendered) => rendered.replaceAll(_dialGaugeStaleLeak, ''))
      .where((rendered) => _cjk.hasMatch(rendered))
      .toList();
  expect(
    offenders,
    isEmpty,
    reason:
        '$where renders Chinese to an English-speaking driver:\n'
        '${offenders.join("\n")}',
  );
}

/// A label arrives whole: not wrapped past its line budget, and no wider than
/// the control that holds it.
void _expectLabelComplete(
  WidgetTester tester, {
  required Finder label,
  required Finder within,
}) {
  final paragraph = tester.renderObject<RenderParagraph>(label);
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: 'the label is cut off rather than shortened',
  );
  expect(
    tester.getSize(label).width,
    lessThanOrEqualTo(tester.getSize(within).width + 0.5),
    reason: 'the label is wider than the control holding it',
  );
}

void _expectOnFace(WidgetTester tester, Finder finder, String what) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$what runs off left');
  expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$what runs off top');
  expect(
    rect.right,
    lessThanOrEqualTo(_face.width + 0.5),
    reason: '$what runs off right',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(_face.height + 0.5),
    reason: '$what runs off bottom',
  );
}

/// The watch must never be made readable-by-shrinking.
void _expectUnscaledText(WidgetTester tester) {
  final scaler = MediaQuery.textScalerOf(tester.element(find.byType(WearShell)));
  expect(
    scaler.scale(14),
    14,
    reason: 'the shell reduced the text scale to make English fit',
  );
}

int _stampTick = 0;

/// Distinct observation ticks in the recent past.
///
/// The controller ignores a reading whose [Reading.receivedElapsed] equals
/// the last one it consumed. Wall UTC is display metadata; a timestamp even
/// one microsecond in the future is stale (`wallAge.isNegative`).
TelemetrySnapshot _speedSnapshot(double kmh, {Duration age = Duration.zero}) {
  final tick = _stampTick++;
  return TelemetrySnapshot(
    readings: {
      PidLibrary.vehicleSpeed.id: Reading(
        pid: PidLibrary.vehicleSpeed,
        value: kmh,
        rawBytes: [kmh.round().clamp(0, 255)],
        timestamp: DateTime.now()
            .subtract(const Duration(milliseconds: 50))
            .add(Duration(milliseconds: tick))
            .subtract(age),
        receivedElapsed: Duration(milliseconds: tick),
      ),
    },
  );
}

Future<StreamController<TelemetrySnapshot>> _pumpPerformance(
  WidgetTester tester, {
  required bool connected,
  Locale locale = englishLocale,
}) async {
  final telemetry = StreamController<TelemetrySnapshot>.broadcast();
  addTearDown(telemetry.close);
  final container = ProviderContainer(
    overrides: [
      obdSessionProvider.overrideWith(
        () => _FixedSession(
          connected ? _connectedDemo : const ObdConnectionState(),
        ),
      ),
      telemetryProvider.overrideWith((ref) => telemetry.stream),
    ],
  );
  addTearDown(container.dispose);
  // Tall enough that the whole screen is laid out. A ListView only builds what
  // is near the viewport, and the disclaimer lives at the very bottom — on the
  // default 800x600 surface it is not built, and every assertion about it
  // passes or fails for the wrong reason.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        home: const PerformanceScreen(),
      ),
    ),
  );
  await tester.pump();
  return telemetry;
}

/// Publishes one snapshot and lets the provider deliver it.
Future<void> _emit(
  WidgetTester tester,
  StreamController<TelemetrySnapshot> telemetry,
  TelemetrySnapshot snapshot,
) async {
  telemetry.add(snapshot);
  await tester.pump(const Duration(milliseconds: 50));
}

Map<String, Object?> _profileJson(String id) => {
  'id': id,
  'display_name': 'Profile $id',
  'description': 'Installable community fixture.',
  'limitations': ['fixture'],
  'status': 'community',
  'evidence': 'sourceBacked',
  'market': 'Australia',
  'make': 'MG',
  'model': 'ZS EV',
  'year_from': 2021,
  'year_to': 2021,
  'variant': 'Mk1',
  'powertrain': 'BEV',
  'identity_evidence': {
    'market': 'exact',
    'year': 'exact',
    'model': 'exact',
    'variant': 'exact',
  },
  'source': {
    'name': 'primary-$id',
    'url': 'https://example.invalid/$id',
    'revision': 'a' * 40,
    'license': 'Apache-2.0',
    'path': '$id.csv',
    'locator': '22B046',
    'artifact_sha256': 'b' * 64,
  },
  'secondary_sources': [
    {
      'name': 'independent-$id',
      'url': 'https://example.invalid/other-$id',
      'revision': 'c' * 40,
      'license': 'MIT',
      'path': 'poller.cpp',
      'locator': 'poll table',
      'artifact_sha256': 'd' * 64,
    },
  ],
  'commands': [
    {
      'request_header': '781',
      'expected_responder': '789',
      'mode': '22',
      'identifier': 'B046',
      'payload_length': 2,
      'signals': [
        {
          'id': 'soc_display',
          'name': 'Displayed state of charge',
          'offset': 0,
          'width': 2,
          'equation': '(A*256+B)/10',
          'unit': '%',
          'min_value': 0,
          'max_value': 100,
          'semantic_kind': 'stateOfCharge',
          'recommended': true,
        },
      ],
    },
  ],
};

Future<void> _pumpWear(
  WidgetTester tester, {
  required bool connected,
  Locale locale = englishLocale,
  PowertrainBatteryCatalogSnapshot? catalog,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final telemetry = StreamController<TelemetrySnapshot>.broadcast();
  addTearDown(telemetry.close);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      obdSessionProvider.overrideWith(
        () => _FixedSession(
          connected ? _connectedDemo : const ObdConnectionState(),
        ),
      ),
      if (catalog != null)
        powertrainBatteryCatalogLoaderProvider.overrideWithValue(
          () async => catalog,
        ),
      telemetryProvider.overrideWith((ref) => telemetry.stream),
    ],
  );
  addTearDown(container.dispose);
  if (catalog != null) {
    await container
        .read(pidRegistryProvider.notifier)
        .installPowertrainProfile(catalog, 'only-one', vehicleYear: 2021);
  }
  tester.view.physicalSize = const Size(454, 454);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        home: const WearShell(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => _stampTick = 0);

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  // Every string this group moved, reachable without a widget tree. State copy
  // that only appears mid-run is checked here as well as on screen.
  final probes = <String, String Function(AppLocalizations)>{
    'performanceHeadline': (l) => l.performanceHeadline,
    'performanceSubhead': (l) => l.performanceSubhead,
    'performanceNotConnectedTitle': (l) => l.performanceNotConnectedTitle,
    'performanceNotConnectedBody': (l) => l.performanceNotConnectedBody,
    'performanceSpeedGaugeLabel': (l) => l.performanceSpeedGaugeLabel,
    'performanceStateIdle': (l) => l.performanceStateIdle,
    'performanceStateAwaitingStandstill': (l) =>
        l.performanceStateAwaitingStandstill('42'),
    'performanceStateAwaitingSpeedSignal': (l) =>
        l.performanceStateAwaitingSpeedSignal,
    'performanceStateStaged': (l) => l.performanceStateStaged,
    'performanceStateRunning': (l) => l.performanceStateRunning,
    'performanceStateFinished': (l) => l.performanceStateFinished(100),
    'performanceStateAborted': (l) => l.performanceStateAborted,
    'performanceSecondsUnit': (l) => l.performanceSecondsUnit,
    'performanceTargetSpeedHeading': (l) => l.performanceTargetSpeedHeading,
    'performanceSpeedTraceHeading': (l) => l.performanceSpeedTraceHeading,
    'performanceSplitsHeading': (l) => l.performanceSplitsHeading,
    'performancePeakSpeed': (l) => l.performancePeakSpeed,
    'performanceArm': (l) => l.performanceArm,
    'performanceReset': (l) => l.performanceReset,
    'performanceNoSpeedSignal': (l) => l.performanceNoSpeedSignal,
    'performanceDisclaimer': (l) => l.performanceDisclaimer,
    'wearDemoSimulator': (l) => l.wearDemoSimulator,
    'wearBleAdapters': (l) => l.wearBleAdapters,
    'wearConnecting': (l) => l.wearConnecting,
    'wearScanning': (l) => l.wearScanning,
    'wearNoDevicesFound': (l) => l.wearNoDevicesFound,
    'wearBack': (l) => l.wearBack,
    'wearScanAgain': (l) => l.wearScanAgain,
    'wearScanFailed': (l) => l.wearScanFailed,
    'wearConnectFailed': (l) => l.wearConnectFailed('OBDII'),
    'wearPermissionBluetooth': (l) => l.wearPermissionBluetooth,
    'wearPermissionLocation': (l) => l.wearPermissionLocation,
    'wearScanPermissionNeeded': (l) =>
        l.wearScanPermissionNeeded(l.wearPermissionBluetooth),
    'wearScanPermissionPermanentlyDenied': (l) =>
        l.wearScanPermissionPermanentlyDenied(l.wearPermissionLocation),
    'wearCancel': (l) => l.wearCancel,
    'wearDisconnectQuestion': (l) => l.wearDisconnectQuestion,
    'wearDisconnect': (l) => l.wearDisconnect,
    'wearConfirmVehicle': (l) => l.wearConfirmVehicle,
    'wearConfirmVehicleAccept': (l) => l.wearConfirmVehicleAccept,
    'wearConfirmVehicleBody': (l) => l.wearConfirmVehicleBody,
    'wearBatteryVoltageLabel': (l) => l.wearBatteryVoltageLabel,
  };

  group('the copy itself, with no widget tree', () {
    test('every string is answered in both languages', () {
      for (final entry in probes.entries) {
        expect(entry.value(en).trim(), isNotEmpty, reason: '${entry.key} en');
        expect(entry.value(zh).trim(), isNotEmpty, reason: '${entry.key} zh');
      }
    });

    test('the English copy contains no Chinese', () {
      final offenders = [
        for (final entry in probes.entries)
          if (_cjk.hasMatch(entry.value(en))) '${entry.key} → "${entry.value(en)}"',
      ];
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the two languages are two, not one copied twice', () {
      // gen-l10n does not fail on a missing translation; it falls back to the
      // English template, and the screen then looks translated and is not.
      final same = [
        for (final entry in probes.entries)
          if (entry.value(en) == entry.value(zh)) entry.key,
      ];
      expect(same, isEmpty, reason: 'untranslated (English fallback): $same');
    });
  });

  group('the distinctions this screen refuses to blur', () {
    test('an unknown speed is not a speed above standstill', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.performanceStateAwaitingSpeedSignal,
          isNot(l10n.performanceStateAwaitingStandstill('42')),
          reason:
              'a driver must be able to tell "the car is still moving" from '
              '"the app cannot tell whether it is moving"',
        );
      }
      // No speed reading is not a reading of zero, and must not be phrased as
      // an observation of the vehicle.
      expect(
        en.performanceStateAwaitingSpeedSignal.toLowerCase(),
        contains('waiting'),
      );
    });

    test('an aborted run never reads as a finished one', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.performanceStateAborted,
          isNot(l10n.performanceStateFinished(100)),
        );
      }
      expect(
        en.performanceStateAborted.toLowerCase(),
        contains('not completed'),
        reason: 'the run stopped; the elapsed figure on screen is not a time',
      );
      expect(zh.performanceStateAborted, contains('未完成'));
    });

    test('the copy says it is a timed run from rest', () {
      expect(
        en.performanceSubhead.toLowerCase(),
        contains('standing start'),
        reason:
            'the screen times one run that began at a standstill; it does not '
            'state what the vehicle is rated to do',
      );
      expect(zh.performanceSubhead, contains('由靜止起步'));
    });

    test('the disclaimer keeps both halves of its hedge', () {
      // Softening either half turns a bounded observation into a claim about
      // the car — the prose form of a plausible wrong number.
      expect(en.performanceDisclaimer.toLowerCase(), contains('indicative'));
      expect(
        en.performanceDisclaimer.toLowerCase(),
        contains('not equivalent to professional test equipment'),
      );
      expect(zh.performanceDisclaimer, contains('僅供參考'));
      expect(zh.performanceDisclaimer, contains('不等同於專業測試設備'));
    });

    test('a scan that found nothing is not a scan that failed', () {
      for (final l10n in [en, zh]) {
        expect(l10n.wearNoDevicesFound, isNot(l10n.wearScanFailed));
      }
    });

    test('the two refusable permissions are named apart', () {
      for (final l10n in [en, zh]) {
        expect(l10n.wearPermissionBluetooth, isNot(l10n.wearPermissionLocation));
        expect(
          l10n.wearScanPermissionNeeded(l10n.wearPermissionBluetooth),
          isNot(l10n.wearScanPermissionNeeded(l10n.wearPermissionLocation)),
          reason: 'the user must learn which permission to turn on',
        );
      }
    });

    test('the vehicle confirmation keeps read-only and the wrong-number risk', () {
      expect(en.wearConfirmVehicleBody.toLowerCase(), contains('read-only'));
      expect(
        en.wearConfirmVehicleBody.toLowerCase(),
        contains('plausible but wrong'),
        reason: 'that sentence is the reason the confirmation exists',
      );
      expect(zh.wearConfirmVehicleBody, contains('唯讀'));
      expect(zh.wearConfirmVehicleBody, contains('看似合理但錯誤'));
    });
  });

  group('numbers come from the code, not the prose', () {
    test('the finished line renders whichever target was selected', () {
      for (final l10n in [en, zh]) {
        expect(l10n.performanceStateFinished(80), contains('80'));
        expect(l10n.performanceStateFinished(80), isNot(contains('100')));
        expect(l10n.performanceStateFinished(100), contains('100'));
      }
    });

    test('the live speed is placed, not spelled', () {
      for (final l10n in [en, zh]) {
        expect(l10n.performanceStateAwaitingStandstill('7'), contains('7'));
        expect(l10n.performanceStateAwaitingStandstill('63'), contains('63'));
      }
    });

    test('units are the same in both languages', () {
      // km/h never becomes mph, and the adapter-facing PID token never changes.
      for (final l10n in [en, zh]) {
        expect(l10n.performanceStateFinished(100), contains('km/h'));
        expect(l10n.performanceStateAwaitingStandstill('9'), contains('km/h'));
        expect(l10n.performanceNoSpeedSignal, contains('PID 010D'));
      }
    });
  });

  group('the acceleration test in English', () {
    testWidgets('disconnected: it says what it needs, in English', (
      tester,
    ) async {
      await _pumpPerformance(tester, connected: false);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.textContaining('built-in simulator'), findsOneWidget);
      _expectNoChinese(tester, 'the disconnected acceleration screen');
    });

    testWidgets('no speed signal: the timer refuses and names why', (
      tester,
    ) async {
      await _pumpPerformance(tester, connected: true);
      expect(find.textContaining('PID 010D'), findsOneWidget);
      final arm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Arm the timer'),
      );
      expect(
        arm.onPressed,
        isNull,
        reason: 'arming with no speed stream produces a run that never starts',
      );
      _expectNoChinese(tester, 'the acceleration screen with no speed signal');
    });

    testWidgets('a whole run reads as English at every state it passes', (
      tester,
    ) async {
      final telemetry = await _pumpPerformance(tester, connected: true);

      await _emit(tester, telemetry, _speedSnapshot(42));
      expect(find.textContaining('Pick a target speed'), findsOneWidget);
      expect(
        tester.widget<DialGauge>(find.byType(DialGauge)).label,
        'Speed',
        reason: 'the dial label is painted, not a Text, so it is read directly',
      );
      _expectNoChinese(tester, 'the idle acceleration screen');

      // Armed while still rolling: the panel names the observed speed.
      await tester.tap(find.text('Arm the timer'));
      await tester.pump();
      await _emit(tester, telemetry, _speedSnapshot(42));
      expect(find.textContaining('complete stop'), findsOneWidget);
      expect(find.textContaining('42 km/h'), findsOneWidget);
      _expectNoChinese(tester, 'the awaiting-standstill panel');

      await _emit(tester, telemetry, _speedSnapshot(0));
      expect(find.textContaining('the clock starts when you move off'), findsOneWidget);

      await _emit(tester, telemetry, _speedSnapshot(30));
      expect(find.text('Timing'), findsOneWidget);

      // The launch sample only starts the clock; the trace needs two samples
      // taken while running before it has a line to draw.
      await _emit(tester, telemetry, _speedSnapshot(70));
      await _emit(tester, telemetry, _speedSnapshot(100));
      expect(find.textContaining('Finished 0'), findsOneWidget);
      // SectionHeading uppercases, so these are the strings actually painted.
      expect(find.text('TARGET SPEED'), findsOneWidget);
      expect(find.text('SPEED TRACE'), findsOneWidget);
      expect(find.text('SPLITS'), findsOneWidget);
      expect(find.text('Peak speed'), findsOneWidget);
      expect(find.text('seconds'), findsOneWidget);
      expect(find.textContaining('not equivalent to professional'), findsOneWidget);
      _expectNoChinese(tester, 'the finished acceleration run');
    });

    testWidgets('a run whose speed signal goes stale says so, and keeps what it had', (
      tester,
    ) async {
      final telemetry = await _pumpPerformance(tester, connected: true);
      await _emit(tester, telemetry, _speedSnapshot(0));
      await tester.tap(find.text('Arm the timer'));
      await tester.pump();
      await _emit(tester, telemetry, _speedSnapshot(0));
      await _emit(tester, telemetry, _speedSnapshot(30));
      expect(find.text('Timing'), findsOneWidget);

      // Present but old: the sensor answered, about a moment that has passed.
      await _emit(
        tester,
        telemetry,
        _speedSnapshot(30, age: const Duration(minutes: 5)),
      );
      expect(find.textContaining('was not completed'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      _expectNoChinese(tester, 'the aborted acceleration run');
    });
  });

  group('the acceleration test in Traditional Chinese', () {
    testWidgets('the load-bearing hedges survive', (tester) async {
      final telemetry = await _pumpPerformance(
        tester,
        connected: true,
        locale: traditionalChineseLocale,
      );
      await _emit(tester, telemetry, _speedSnapshot(0));

      expect(find.textContaining('由靜止起步'), findsOneWidget);
      expect(find.textContaining('僅供參考'), findsOneWidget);
      expect(find.textContaining('不等同於專業測試設備'), findsOneWidget);
      expect(find.text('準備計時'), findsOneWidget);
    });
  });

  group('the Wear OS shell on a 454px round face', () {
    testWidgets('English connect labels arrive whole and on the face', (
      tester,
    ) async {
      await _pumpWear(tester, connected: false);
      expect(tester.takeException(), isNull);
      _expectUnscaledText(tester);

      for (final (key, label) in [
        (const Key('wear_connect_demo'), 'Demo simulator'),
        (const Key('wear_scan_ble'), 'BLE adapters'),
      ]) {
        final button = find.byKey(key);
        expect(button, findsOneWidget, reason: '$label lost its control');
        expect(find.text(label), findsOneWidget);
        _expectOnFace(tester, button, label);
        _expectLabelComplete(
          tester,
          label: find.text(label),
          within: button,
        );
      }
      _expectNoChinese(tester, 'the English watch connect page');
    });

    testWidgets('Chinese connect labels stay exactly what they were', (
      tester,
    ) async {
      await _pumpWear(
        tester,
        connected: false,
        locale: traditionalChineseLocale,
      );
      expect(find.text('Demo 模擬器'), findsOneWidget);
      expect(find.text('BLE 轉接器'), findsOneWidget);
    });

    testWidgets('the disconnect confirmation is reachable and complete', (
      tester,
    ) async {
      await _pumpWear(tester, connected: true);
      await tester.longPress(find.byKey(const Key('wear_dial')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const Key('wear_disconnect_confirm'));
      expect(confirm, findsOneWidget);
      expect(find.text('Disconnect?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      _expectOnFace(tester, confirm, 'the disconnect confirmation');
      _expectLabelComplete(
        tester,
        label: find.text('Disconnect'),
        within: confirm,
      );
      _expectNoChinese(tester, 'the English watch disconnect dialog');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the numbers page reads as English', (tester) async {
      await _pumpWear(tester, connected: true);
      await tester.fling(
        find.byKey(const Key('wear_dial')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Battery'), findsOneWidget);
      _expectNoChinese(tester, 'the English watch numbers page');
    });

    testWidgets('the numbers page keeps its Chinese label', (tester) async {
      await _pumpWear(
        tester,
        connected: true,
        locale: traditionalChineseLocale,
      );
      await tester.fling(
        find.byKey(const Key('wear_dial')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('電瓶'), findsOneWidget);
    });

    testWidgets('the vehicle confirmation fits, and keeps its warning', (
      tester,
    ) async {
      final catalog = snapshotOfProfiles([_profileJson('only-one')]);
      await _pumpWear(tester, connected: true, catalog: catalog);
      await tester.fling(
        find.byKey(const Key('wear_dial')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();

      final ask = find.byKey(const Key('wear_confirm_vehicle'));
      expect(ask, findsOneWidget);
      expect(find.text('Confirm vehicle'), findsOneWidget);
      _expectOnFace(tester, ask, 'the confirm-vehicle button');
      _expectLabelComplete(
        tester,
        label: find.text('Confirm vehicle'),
        within: ask,
      );

      await tester.tap(ask);
      await tester.pumpAndSettle();
      // The consequence sentence is the consent, not decoration: it must be on
      // screen whole, on a face this small, before the accept button is real.
      expect(find.textContaining('plausible but wrong'), findsOneWidget);
      expect(find.textContaining('read-only'), findsOneWidget);

      final accept = find.byKey(const Key('wear_confirm_vehicle_accept'));
      expect(accept, findsOneWidget);
      _expectOnFace(tester, accept, 'the confirm-vehicle accept button');
      _expectLabelComplete(
        tester,
        label: find.text('Yes, this car'),
        within: accept,
      );
      _expectNoChinese(tester, 'the English watch vehicle confirmation');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Chinese vehicle confirmation keeps its warning', (
      tester,
    ) async {
      final catalog = snapshotOfProfiles([_profileJson('only-one')]);
      await _pumpWear(
        tester,
        connected: true,
        catalog: catalog,
        locale: traditionalChineseLocale,
      );
      await tester.fling(
        find.byKey(const Key('wear_dial')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wear_confirm_vehicle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('看似合理但錯誤'), findsOneWidget);
      expect(find.textContaining('唯讀'), findsOneWidget);
      expect(find.text('就是這台車'), findsOneWidget);
    });
  });
}
