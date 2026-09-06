// The dashboard group, in both shipped languages.
//
// What this checks is deliberately NOT "does the widget render its own ARB
// entry" — a finder that reads the same ARB the widget read agrees with itself
// no matter how wrong the translation is. It checks the properties a wrong
// translation breaks:
//
//   * the English build renders no Chinese anywhere, including in the
//     composed semantics labels a screen reader speaks;
//   * the Chinese build still carries the qualifiers that make the derived
//     panel honest;
//   * every enum the group turned into a context-free table is answered in
//     both languages;
//   * every number in the copy is a placeholder fed from the constant the
//     code enforces, not a digit typed into a sentence.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_trends.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/timeline_downsampler.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/telemetry_workspace.dart';
import 'package:torque_obd/ui/widgets/telemetry/live_trend_card.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_lane_selector.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_recorder_panel.dart';

import '../support/cjk.dart';
import '../support/localized_app.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

/// Badge fragments that reach these screens from a file this change does not
/// own, listed whole rather than as substrings.
///
/// The dashboard composes a tile's footnote as `'$badge · $ownCopy'`, so the
/// scan below splits on that separator and compares each part in full. Matching
/// on substrings instead would let a Chinese fragment of this group's own copy
/// hide behind a two-character badge word.
///
/// Each entry names where it lives, so the list shrinks as those groups land
/// rather than quietly outliving them.
const _foreignChinese = <String, String>{
  '推算值': 'lib/diagnostics/availability.dart',
};

/// True when [element] sits under a widget of type [T].
///
/// Used to keep the English scan off `TelemetryRecorderPanel`, which another
/// group owns and which is still Chinese-only. Excluding it by subtree rather
/// than by copying its sentences into a literal here means this test does not
/// go stale the moment that group edits its wording.
bool _under<T extends Widget>(Element element) {
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is T) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Every string this build would show or speak.
///
/// Semantics labels are read off the widgets rather than through
/// `find.bySemanticsLabel`, which needs an enabled semantics handle; the
/// composed label on a trend card is exactly where a stray fullwidth comma or
/// an untranslated fragment would hide.
List<String> _rendered(WidgetTester tester, {bool skipRecorderPanel = false}) {
  final out = <String>[];
  void add(String? value) {
    if (value != null && value.isNotEmpty) out.add(value);
  }

  bool excluded(Element element) =>
      skipRecorderPanel && _under<TelemetryRecorderPanel>(element);

  for (final element in find.byType(Text).evaluate()) {
    if (excluded(element)) continue;
    final text = element.widget as Text;
    add(text.data ?? text.textSpan?.toPlainText());
  }
  for (final element in find.byType(Semantics).evaluate()) {
    if (excluded(element)) continue;
    add((element.widget as Semantics).properties.label);
  }
  for (final element in find.byType(Tooltip).evaluate()) {
    if (excluded(element)) continue;
    add((element.widget as Tooltip).message);
  }
  for (final element in find.byType(InputChip).evaluate()) {
    if (excluded(element)) continue;
    add((element.widget as InputChip).deleteButtonTooltipMessage);
  }
  return out;
}

/// The Chinese fragments an English build rendered, minus the ones that come
/// from files another group owns.
Set<String> _unexpectedChinese(WidgetTester tester) {
  final offenders = <String>{};
  for (final value in _rendered(tester, skipRecorderPanel: true)) {
    for (final part in value.split(' · ')) {
      final fragment = part.trim();
      if (!_cjk.hasMatch(fragment)) continue;
      if (_foreignChinese.containsKey(fragment)) continue;
      offenders.add(fragment);
    }
  }
  return offenders;
}

/// Loads the font the app actually ships.
///
/// Without this every assertion about width here would be fiction.
/// `flutter_test`'s default font draws every glyph as a square of the font
/// size, so a Latin string measures roughly twice its real width and lines up
/// exactly with a Chinese one of the same character count. Measured under that
/// font, "Not supported by this vehicle" overflowed the unsupported tile by 19
/// pixels and three of the four derived cell labels were reported as
/// truncated; measured under SpaceGrotesk, none of that happens. A layout test
/// that compares English against Chinese is worthless without the real
/// metrics, and worse than worthless with the fake ones, because it argues for
/// shortening copy that fits.
Future<void> _loadShippedFont() async {
  final loader = FontLoader('SpaceGrotesk')
    ..addFont(
      File('assets/fonts/SpaceGrotesk[wght].ttf').readAsBytes().then(
        (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
      ),
    );
  await loader.load();
}

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Demo ECU',
  );
}

class _FixedActivePids extends ActivePids {
  _FixedActivePids(this._pids);
  final List<Pid> _pids;

  @override
  List<Pid> build() => _pids;
}

class _FixedProfile extends VehicleProfileController {
  _FixedProfile(this._profile);
  final VehicleProfile _profile;

  @override
  VehicleProfile build() => _profile;
}

class _FixedProgress extends TelemetryRecorderProgressNotifier {
  _FixedProgress(this._progress);
  final TelemetryRecorderProgress _progress;

  @override
  TelemetryRecorderProgress build() => _progress;
}

/// The dashboard, at a chosen locale.
///
/// A local copy of `test/support/dashboard_harness.dart`'s overrides rather
/// than an edit to it: that harness is shared with the rest of the suite and
/// pins the Traditional Chinese locale on purpose.
Future<void> _pumpDashboard(
  WidgetTester tester, {
  required Locale locale,
  required TelemetrySnapshot snapshot,
  List<Pid> activePids = const [],
  VehicleProfile profile = const VehicleProfile(),
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        obdSessionProvider.overrideWith(_ConnectedSession.new),
        activePidsProvider.overrideWith(() => _FixedActivePids(activePids)),
        vehicleProfileProvider.overrideWith(() => _FixedProfile(profile)),
        telemetryProvider.overrideWith((ref) => Stream.value(snapshot)),
      ],
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required Locale locale,
  required List<Pid> activePids,
  TelemetryConnectionEvidence? evidence,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final now = DateTime.now().toUtc();
  final snapshot = TelemetrySnapshot(
    readings: {
      for (final pid in activePids)
        pid.id: Reading(
          pid: pid,
          value: 12,
          rawBytes: const [0],
          timestamp: now,
        ),
    },
    capturedAt: now,
  );
  final environment = LiveTelemetryStartEnvironment(
    readConnection: () => const TelemetryConnectionSnapshot(
      connected: true,
      foreground: true,
      connectionGeneration: 1,
      foregroundEpoch: 1,
    ),
    utcNow: () => now,
    elapsedUs: () => 1000000,
  )..observeTelemetry(snapshot);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        activePidsProvider.overrideWith(() => _FixedActivePids(activePids)),
        telemetryProvider.overrideWith((ref) => Stream.value(snapshot)),
        liveTelemetryStartEnvironmentProvider.overrideWithValue(environment),
        currentTelemetryConnectionEvidenceProvider.overrideWithValue(evidence),
        telemetryRecorderProgressProvider.overrideWith(
          () => _FixedProgress(
            const TelemetryRecorderProgress(
              state: TelemetryRecorderState(
                phase: TelemetryRecorderPhase.recording,
                valueCount: 12,
              ),
              elapsedUs: 0,
              bytesBeforeFooter: 0,
              effectiveSessionLimit: null,
              sessionId: null,
            ),
          ),
        ),
      ],
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        home: const Scaffold(
          body: SafeArea(child: SingleChildScrollView(child: TelemetryWorkspace())),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadShippedFont);

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  const english = Locale('en');

  group('every enum this group made context-free is answered twice', () {
    test('TelemetryRecorderPhase', () {
      for (final phase in TelemetryRecorderPhase.values) {
        for (final entry in {'en': en, 'zh': zh}.entries) {
          expect(
            telemetryRecorderPhaseLabel(entry.value, phase).trim(),
            isNotEmpty,
            reason: '$phase ${entry.key}',
          );
        }
        expect(
          telemetryRecorderPhaseLabel(en, phase),
          isNot(telemetryRecorderPhaseLabel(zh, phase)),
          reason: '$phase fell back to the English template',
        );
        expect(
          _cjk.hasMatch(telemetryRecorderPhaseLabel(en, phase)),
          isFalse,
          reason: '$phase en carries Chinese',
        );
      }
    });

    test('TelemetryTrendSelectionOutcome', () {
      for (final outcome in TelemetryTrendSelectionOutcome.values) {
        final english = telemetryTrendSelectionOutcomeLabel(en, outcome);
        final chinese = telemetryTrendSelectionOutcomeLabel(zh, outcome);
        // Silence and speech must agree across languages: an outcome that is
        // worth reporting in one language is worth reporting in both.
        expect(
          english == null,
          chinese == null,
          reason: '$outcome is reported in one language only',
        );
        if (english == null) continue;
        expect(english.trim(), isNotEmpty, reason: '$outcome en');
        expect(chinese!.trim(), isNotEmpty, reason: '$outcome zh');
        expect(english, isNot(chinese), reason: '$outcome untranslated');
        expect(_cjk.hasMatch(english), isFalse, reason: '$outcome en');
      }
    });

    test('applied and no-change stay silent', () {
      for (final l10n in [en, zh]) {
        expect(
          telemetryTrendSelectionOutcomeLabel(
            l10n,
            TelemetryTrendSelectionOutcome.applied,
          ),
          isNull,
        );
        expect(
          telemetryTrendSelectionOutcomeLabel(
            l10n,
            TelemetryTrendSelectionOutcome.noChange,
          ),
          isNull,
        );
      }
    });
  });

  group('numbers come from the constants, not from the sentence', () {
    test('the trend window is the constant the projection enforces', () {
      expect(
        zh.trendWindowSemantics(telemetryTrendWindow.inSeconds),
        contains('${telemetryTrendWindow.inSeconds}'),
      );
      // Proves it is a placeholder rather than a digit that happens to agree:
      // a hard-coded 60 would still say 60 here.
      for (final l10n in [en, zh]) {
        expect(l10n.trendWindowSemantics(7), contains('7'));
        expect(l10n.trendWindowSemantics(7), isNot(contains('60')));
      }
    });

    test('the lane limit is maximumTelemetryTrendLanes', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.trendTooManySelected(maximumTelemetryTrendLanes),
          contains('$maximumTelemetryTrendLanes'),
        );
        expect(l10n.trendTooManySelected(9), contains('9'));
        expect(l10n.trendSheetBody(9), contains('9'));
        expect(l10n.trendPickSignalsBody(9), contains('9'));
        expect(l10n.trendSheetDone(2, 9), contains('2'));
        expect(l10n.trendSheetDone(2, 9), contains('9'));
      }
    });
  });

  group('the distinctions the dashboard refuses to blur', () {
    test('the derived panel says estimated, never measured', () {
      for (final title in [
        en.derivedEstimatesTitle,
        en.derivedEstimatedFuelTitle,
        en.derivedUnavailableMessage,
      ]) {
        expect(
          title.toLowerCase(),
          contains('estimat'),
          reason: 'the panel exists to mark these figures as estimates',
        );
        expect(title.toLowerCase(), isNot(contains('measur')));
        expect(title.toLowerCase(), isNot(contains('sensor')));
      }
      for (final title in [
        zh.derivedEstimatesTitle,
        zh.derivedEstimatedFuelTitle,
        zh.derivedUnavailableMessage,
      ]) {
        expect(
          RegExp('推算|估算').hasMatch(title),
          isTrue,
          reason: '$title dropped the estimate qualifier',
        );
        expect(RegExp('實測|量測|感測器讀值').hasMatch(title), isFalse);
      }
    });

    test('an ECU-reported fuel rate never reads as an estimate', () {
      expect(en.derivedEcuFuelTitle.toLowerCase(), isNot(contains('estimat')));
      expect(en.derivedEcuReported.toLowerCase(), isNot(contains('estimat')));
      expect(RegExp('推算|估算').hasMatch(zh.derivedEcuFuelTitle), isFalse);
      expect(RegExp('推算|估算').hasMatch(zh.derivedEcuReported), isFalse);
      for (final l10n in [en, zh]) {
        expect(l10n.derivedEcuFuelTitle, isNot(l10n.derivedEstimatedFuelTitle));
      }
    });

    test('unavailable inputs are not a zero reading', () {
      for (final l10n in [en, zh]) {
        expect(l10n.derivedUnavailableMessage, isNot(contains('0')));
      }
      expect(
        en.derivedUnavailableMessage.toLowerCase(),
        isNot(contains('no power')),
        reason:
            '"we cannot work this out yet" must not read as "your engine is '
            'producing no power"',
      );
    });

    test('a controller that answered unsupported is not silence', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.gaugeUnsupportedByVehicle,
          isNot(l10n.telemetryStatusNoAnswer),
        );
      }
      expect(
        en.gaugeUnsupportedByVehicle.toLowerCase(),
        isNot(anyOf(contains('no answer'), contains('no response'))),
        reason: 'the controller replied; it did not stay silent',
      );
      expect(
        en.telemetryStatusNoAnswer.toLowerCase(),
        isNot(contains('not supported')),
      );
    });

    test('a live lane is not a stale one, and simulated data says so', () {
      for (final l10n in [en, zh]) {
        expect(l10n.trendLiveData, isNot(l10n.telemetryStatusStale));
        expect(l10n.telemetryDemoData, isNot(l10n.telemetryRigData));
        expect(l10n.telemetryNotConnected.trim(), isNotEmpty);
      }
      for (final label in [en.telemetryDemoData, en.telemetryRigData]) {
        expect(
          label.toLowerCase(),
          anyOf(contains('simulator'), contains('rig')),
          reason: 'figures that did not come from a vehicle must say so',
        );
      }
    });

    test('the English semantics separator carries no Chinese punctuation', () {
      // The CJK ranges above do not cover U+FF0C, so this needs its own check:
      // the label was joined with a fullwidth comma in every language before
      // the separator became a message of its own.
      expect(en.semanticsFieldSeparator, isNot(contains('，')));
      expect(en.semanticsFieldSeparator, isNot(contains('、')));
      expect(zh.semanticsFieldSeparator, contains('，'));
    });
  });

  group('the English build renders no Chinese', () {
    testWidgets('empty dashboard', (tester) async {
      await _pumpDashboard(
        tester,
        locale: english,
        snapshot: TelemetrySnapshot(capturedAt: DateTime.now()),
      );
      expect(_unexpectedChinese(tester), isEmpty);
      expect(find.text('The dashboard is empty'), findsOneWidget);
    });

    testWidgets('gauges, unsupported tile and the derived strip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      await _pumpDashboard(
        tester,
        locale: english,
        activePids: const [
          PidLibrary.engineRpm,
          PidLibrary.vehicleSpeed,
          PidLibrary.coolantTemp,
        ],
        snapshot: TelemetrySnapshot(
          readings: {
            PidLibrary.vehicleSpeed.id: Reading(
              pid: PidLibrary.vehicleSpeed,
              value: 60,
              rawBytes: const [0],
              timestamp: now,
            ),
          },
          faults: {PidLibrary.coolantTemp.id: PidFault.unsupported},
          capturedAt: now,
        ),
      );
      expect(_unexpectedChinese(tester), isEmpty);
      expect(find.textContaining('Not supported by this vehicle'), findsWidgets);
    });

    testWidgets('the derived strip, with every cell filled', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      Reading reading(Pid pid, double value) =>
          Reading(pid: pid, value: value, rawBytes: const [0], timestamp: now);
      await _pumpDashboard(
        tester,
        locale: english,
        profile: const VehicleProfile(isConfirmed: true),
        activePids: const [PidLibrary.engineRpm],
        snapshot: TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: reading(PidLibrary.engineRpm, 2000),
            PidLibrary.vehicleSpeed.id: reading(PidLibrary.vehicleSpeed, 60),
            PidLibrary.mafRate.id: reading(PidLibrary.mafRate, 12.5),
          },
          accelerationMs2: 0.4,
          capturedAt: now,
        ),
      );
      expect(_unexpectedChinese(tester), isEmpty);
      expect(find.text('Estimated values'), findsOneWidget);

      // The provenance pill, as a rendered literal.
      //
      // This fixture has a MAF reading and no ECU fuel rate, so it takes the
      // two-source branch of `dashboard_screen.dart` — the one that builds
      // 'A · B' by concatenating three interpolations across three source
      // lines. `flutter analyze` has nothing to say about a broken adjacent-
      // string concatenation, and the scan above only asks whether the result
      // contains Chinese: 'MAF sensorStoichiometric estimate' would pass it.
      //
      // Earlier in this branch, changing a getter to a method left five sites
      // interpolating a closure and rendering `Closure: (AppLocalizations) =>
      // String` on screen, with analyze silent throughout. A rendered literal
      // is the only thing that catches that class.
      expect(
        find.text('MAF sensor · Stoichiometric estimate'),
        findsOneWidget,
        reason: 'the two-source pill lost its separator, a label, or a space',
      );

      // No cell label may be ellipsised. These sit in a fixed-width column and
      // are the place where a longer English phrase turns into an ellipsis
      // that hides which quantity the number belongs to; `flutter analyze`
      // reports nothing when that happens, and neither does an overflow error.
      // Only meaningful because the shipped font is loaded above.
      for (final label in [
        en.derivedAirflow,
        en.derivedFuelUse,
        en.derivedEngineHorsepower,
        en.derivedTorque,
      ]) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: '$label is missing');
        expect(
          tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
          isFalse,
          reason: '"$label" is truncated; use a shorter true phrase',
        );
      }
    });

    testWidgets('trend workspace, cards and lane selector', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpWorkspace(
        tester,
        locale: english,
        activePids: const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
        evidence: const TelemetryConnectionEvidence(
          source: TelemetrySource.demo,
          transport: TransportKind.demo,
          protocol: 'ISO 15765-4 CAN',
        ),
      );
      expect(_unexpectedChinese(tester), isEmpty);
      expect(find.text('Built-in simulator data'), findsOneWidget);
      // SectionHeading upper-cases its text, which is a no-op in Chinese
      // and not one in English.
      expect(find.text('TREND SIGNALS'), findsOneWidget);
    });

    testWidgets('the lane sheet and its chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: localizedMaterialApp(
            theme: AppTheme.dark(),
            locale: english,
            home: Scaffold(
              body: TelemetryLaneSelector(
                activePids: const [PidLibrary.engineRpm],
                selectedIds: [PidLibrary.engineRpm.id],
                enabled: true,
                disabledReason: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_unexpectedChinese(tester), isEmpty);
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      expect(chip.deleteButtonTooltipMessage, isNotNull);
      expect(_cjk.hasMatch(chip.deleteButtonTooltipMessage!), isFalse);
      expect(chip.deleteButtonTooltipMessage, startsWith('Remove '));
    });

    testWidgets('a trend card semantics label', (tester) async {
      final lane = TelemetryTrendLane(
        pid: PidLibrary.engineRpm,
        primitives: const [TimelineValue(elapsedUs: 0, value: 1200, segmentId: 'a')],
        currentValue: 1200,
        currentStatus: null,
      );
      await tester.pumpWidget(
        localizedMaterialApp(
          theme: AppTheme.dark(),
          locale: english,
          home: Scaffold(
            body: LiveTrendCard(
              lane: lane,
              windowEndElapsedUs: 0,
              recordingLabel: telemetryRecorderPhaseLabel(
                en,
                TelemetryRecorderPhase.recording,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_unexpectedChinese(tester), isEmpty);
      final label = tester.getSemantics(find.byType(LiveTrendCard)).label;
      expect(label, isNot(contains('，')));
      expect(
        label,
        contains(en.trendWindowSemantics(telemetryTrendWindow.inSeconds)),
      );
    });
  });

  // English is the longer language here, and the dashboard is full of fixed
  // boxes: square gauge tiles, a divided cell row, headers that put a title
  // and a badge on one line.
  //
  // Everything must lay out in both languages, at every width and text scale
  // below. The set is empty and the machinery stays: an exemption has to prove
  // it is still earned, so a case listed here MUST still overflow or this test
  // fails and tells you to delete the entry.
  //
  // It held one entry — the estimated panel's airflow pill at 320dp with 2x
  // text. That was a real overflow in BOTH languages, predating any
  // translation: StatusPill (lib/ui/widgets/panel.dart) put its label in a
  // MainAxisSize.min Row where it could not give way. Exempting it was the
  // wrong call twice over. It hid an accessibility defect that a driver using
  // large text on a small phone actually meets, and the staleness check then
  // asserted a 22-pixel overflow that only reproduces with one platform's font
  // metrics — green on macOS, red on Linux CI, for reasons having nothing to do
  // with the copy. The label is Flexible now, so it wraps, and there is nothing
  // left to exempt.
  //
  // One test per configuration on purpose: RenderFlex reports an overflow once
  // per render object, so pumping a second locale into the same tester reports
  // nothing, and a version of this that looped inside one test passed against a
  // deliberately broken layout.
  // Empty, and kept rather than deleted along with the branch that reads it.
  //
  // It held one entry: a 22-pixel StatusPill overflow at 320dp with 2x text,
  // exempted because it was believed unavoidable. It was not — the label needed
  // a `Flexible` — so the pill was fixed and the exemption became unearned.
  //
  // The scaffolding stays because the next genuinely-unavoidable overflow
  // should be recorded here with a reason rather than discovered by someone
  // deleting an assertion, and because an empty allowance is a smaller thing to
  // read than a re-added mechanism. If it is still empty a year from now,
  // delete it and this comment together.
  const knownNarrowOverflow = <String>{};

  group('English lays out wherever Chinese does', () {
    final now = DateTime.now();
    Reading r(Pid pid, double value) =>
        Reading(pid: pid, value: value, rawBytes: const [0], timestamp: now);

    final states = <String, (List<Pid>, TelemetrySnapshot)>{
      'estimated values': (
        const [PidLibrary.engineRpm],
        TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: r(PidLibrary.engineRpm, 2000),
            PidLibrary.vehicleSpeed.id: r(PidLibrary.vehicleSpeed, 60),
            PidLibrary.mafRate.id: r(PidLibrary.mafRate, 12.5),
          },
          accelerationMs2: 0.4,
          capturedAt: now,
        ),
      ),
      'ECU fuel rate': (
        const [PidLibrary.engineRpm],
        TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: r(PidLibrary.engineRpm, 2000),
            PidLibrary.vehicleSpeed.id: r(PidLibrary.vehicleSpeed, 60),
            PidLibrary.engineFuelRate.id: r(PidLibrary.engineFuelRate, 6),
          },
          capturedAt: now,
        ),
      ),
      'estimated fuel only': (
        const [PidLibrary.engineRpm],
        TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: r(PidLibrary.engineRpm, 2000),
            PidLibrary.vehicleSpeed.id: r(PidLibrary.vehicleSpeed, 60),
            PidLibrary.mafRate.id: r(PidLibrary.mafRate, 12.5),
          },
          capturedAt: now,
        ),
      ),
      'inputs withheld': (
        const [PidLibrary.engineRpm],
        TelemetrySnapshot(
          readings: {PidLibrary.engineRpm.id: r(PidLibrary.engineRpm, 2000)},
          capturedAt: now,
        ),
      ),
      'unsupported tile': (
        const [PidLibrary.coolantTemp],
        TelemetrySnapshot(
          faults: {PidLibrary.coolantTemp.id: PidFault.unsupported},
          capturedAt: now,
        ),
      ),
      'empty': (const <Pid>[], TelemetrySnapshot(capturedAt: now)),
    };

    for (final state in states.entries) {
      for (final width in const [320.0, 360.0, 412.0]) {
        for (final scale in const [1.0, 2.0]) {
          final key = '${state.key}|$width|$scale';
          final exempt = knownNarrowOverflow.contains(key);
          for (final locale in {'zh': testUiLocale, 'en': english}.entries) {
            testWidgets('$key ${locale.key}', (tester) async {
              tester.view.physicalSize = Size(width, 1800);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await _pumpDashboard(
                tester,
                locale: locale.value,
                profile: const VehicleProfile(isConfirmed: true),
                activePids: state.value.$1,
                snapshot: state.value.$2,
                textScale: scale,
              );
              final complaint = tester.takeException();
              if (exempt) {
                expect(
                  complaint,
                  isNotNull,
                  reason:
                      '$key no longer overflows in ${locale.key}; delete it '
                      'from knownNarrowOverflow rather than leaving an '
                      'exemption nothing earns',
                );
              } else {
                expect(complaint, isNull, reason: '$key in ${locale.key}');
              }
            });
          }
        }
      }
    }
  });

  group('the Chinese build keeps the qualifiers it shipped with', () {
    // These compare against the sentences the app shipped with, written out
    // here rather than read back from the ARB. A finder built from the same
    // entry the widget rendered agrees with itself; a literal does not, so
    // rewording the Chinese turns this red on purpose.
    testWidgets('the derived panel still says 推算數值', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      Reading reading(Pid pid, double value) =>
          Reading(pid: pid, value: value, rawBytes: const [0], timestamp: now);
      await _pumpDashboard(
        tester,
        locale: testUiLocale,
        profile: const VehicleProfile(isConfirmed: true),
        activePids: const [PidLibrary.engineRpm],
        snapshot: TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: reading(PidLibrary.engineRpm, 2000),
            PidLibrary.vehicleSpeed.id: reading(PidLibrary.vehicleSpeed, 60),
            PidLibrary.mafRate.id: reading(PidLibrary.mafRate, 12.5),
          },
          accelerationMs2: 0.4,
          capturedAt: now,
        ),
      );
      expect(find.text('推算數值'), findsOneWidget);
      expect(find.text('引擎馬力'), findsOneWidget);
      expect(find.text('扭力'), findsOneWidget);
    });

    testWidgets('withheld inputs still name the estimate, not a zero', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pumpDashboard(
        tester,
        locale: testUiLocale,
        activePids: const [PidLibrary.engineRpm],
        snapshot: TelemetrySnapshot(
          readings: {
            PidLibrary.engineRpm.id: Reading(
              pid: PidLibrary.engineRpm,
              value: 2000,
              rawBytes: const [0],
              timestamp: now,
            ),
          },
          capturedAt: now,
        ),
      );
      expect(find.text('等待車速與加速度資料後才能推算馬力'), findsOneWidget);
    });

    testWidgets('a disconnected workspace still says 目前未連線', (tester) async {
      await _pumpWorkspace(
        tester,
        locale: testUiLocale,
        activePids: const [PidLibrary.engineRpm],
      );
      expect(find.text('目前未連線'), findsWidgets);
      expect(find.text('趨勢訊號'), findsOneWidget);
    });
  });
}
