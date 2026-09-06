// The telemetry screens, in both shipped languages.
//
// What these check is deliberately NOT "does this widget render its own ARB
// entry" — a finder that reads the same message the widget read agrees with
// itself, and agrees just as happily when the translation is wrong. They check
// the properties a wrong translation breaks:
//
//   * At `en`, nothing Chinese reaches the screen — neither a Han character
//     nor the fullwidth punctuation (。，（）) that a CJK regex alone walks
//     straight past. The strings this wave does not own are subtracted by
//     identity, from the constants themselves, so the filter stops hiding
//     anything the moment their owners localize them.
//   * At `zh-Hant`, the hedges survive. Every sentence listed below is one a
//     fluent rewrite would shorten and thereby falsify: "neither was chosen"
//     is not "we picked the good one", "left unchanged" is not "repaired",
//     "estimated" is not "measured", and "looks plausible and is wrong" is the
//     whole reason the confirmation dialog exists.
//   * The recorder phase title answers every phase in both languages, from a
//     plain function with no widget above it.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transcript_store.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/state/telemetry_trends.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';
import 'package:torque_obd/ui/widgets/powertrain_profile_confirm_banner.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_history_entry.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_recorder_panel.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_recorder_strip.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_startup_recovery_notice.dart';
import 'package:torque_obd/ui/widgets/transcript_export.dart';

import '../support/cjk.dart';
import '../support/localized_app.dart';
import '../support/powertrain_snapshot_fixture.dart';

// This file discovered the punctuation half first and defined it locally. It
// now comes from test/support/cjk.dart so there is one definition rather than
// nine, which is what let the same defect through elsewhere.
final _han = han;
final _cjkPunctuation = cjkPunctuation;

/// Chinese that belongs to another group's file, subtracted by identity.
///
/// Never by string literal. When the owners of these move them into the ARBs
/// they come back English, this set becomes a no-op, and the screens are then
/// checked whole — instead of a hard-coded allowlist quietly excusing copy that
/// has since been fixed.
Set<String> _notOwnedByThisWave() => {
  for (final access in TelemetryHistoryAccess.values)
    ?access.message(lookupAppLocalizations(englishLocale)),
};

List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = text.data ?? text.textSpan?.toPlainText() ?? '';
    if (value.trim().isNotEmpty) out.add(value);
  }
  // Walked from the app's own node rather than a binding-level owner: in this
  // Flutter the root PipelineOwner delegates to a per-view child, and reading
  // the root's `semanticsOwner` quietly yields nothing — a screen-reader check
  // that inspects an empty tree passes on every string it never looked at.
  void visit(SemanticsNode node) {
    if (node.label.trim().isNotEmpty) out.add(node.label);
    if (node.tooltip.trim().isNotEmpty) out.add(node.tooltip);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return out;
}

void _expectEnglishScreen(WidgetTester tester, String screen) {
  final foreign = _notOwnedByThisWave();
  final offenders = <String>[];
  for (final value in _renderedStrings(tester)) {
    var probe = value;
    for (final owned in foreign) {
      if (owned.isNotEmpty) probe = probe.replaceAll(owned, '');
    }
    if (_han.hasMatch(probe) || _cjkPunctuation.hasMatch(probe)) {
      offenders.add(value);
    }
  }
  expect(
    offenders,
    isEmpty,
    reason:
        '$screen renders Chinese to an English-speaking driver:\n'
        '${offenders.join("\n")}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  const english = Locale('en');

  group('the recorder phase title answers every phase in both languages', () {
    TelemetryRecorderProgress progressFor(
      TelemetryRecorderPhase phase,
      int valueCount,
    ) => TelemetryRecorderProgress(
      state: TelemetryRecorderState(phase: phase, valueCount: valueCount),
      elapsedUs: 0,
      bytesBeforeFooter: 0,
      effectiveSessionLimit: null,
      sessionId: null,
    );

    test('every phase, at zero values and at some', () {
      for (final phase in TelemetryRecorderPhase.values) {
        for (final valueCount in const [0, 5]) {
          final progress = progressFor(phase, valueCount);
          expect(
            telemetryRecorderPhaseTitle(en, progress).trim(),
            isNotEmpty,
            reason: '$phase/$valueCount en',
          );
          expect(
            telemetryRecorderPhaseTitle(zh, progress).trim(),
            isNotEmpty,
            reason: '$phase/$valueCount zh',
          );
          expect(
            telemetryRecorderPhaseTitle(en, progress),
            isNot(matches(_han)),
            reason: '$phase/$valueCount renders Chinese in English',
          );
          expect(
            telemetryRecorderPhaseTitle(en, progress),
            isNot(telemetryRecorderPhaseTitle(zh, progress)),
            reason: '$phase/$valueCount is untranslated (English fallback)',
          );
        }
      }
    });

    test('started-but-silent is not the same claim as preparing', () {
      // `recording` with no values means the recorder is running and nothing
      // has arrived. Rendering that as "preparing" says the recorder has not
      // begun, which is a different — and false — statement about the file on
      // disk, and about what stopping now would save.
      for (final l10n in [en, zh]) {
        final silent = telemetryRecorderPhaseTitle(
          l10n,
          progressFor(TelemetryRecorderPhase.recording, 0),
        );
        final flowing = telemetryRecorderPhaseTitle(
          l10n,
          progressFor(TelemetryRecorderPhase.recording, 5),
        );
        final preparing = telemetryRecorderPhaseTitle(
          l10n,
          progressFor(TelemetryRecorderPhase.preparing, 0),
        );
        final finalizing = telemetryRecorderPhaseTitle(
          l10n,
          progressFor(TelemetryRecorderPhase.finalizing, 5),
        );
        expect(silent, isNot(preparing));
        expect(silent, isNot(flowing));
        expect(preparing, isNot(finalizing));
      }
    });
  });

  group('counts stay distinguishable', () {
    test('values, statuses, gaps and signals are four different sentences', () {
      // A gap is missing data; a status is a controller's answer; a value is a
      // number that was actually recorded. Collapsing any pair turns an absence
      // into a reading.
      for (final l10n in [en, zh]) {
        final rendered = {
          l10n.telemetryValueCount(3),
          l10n.telemetryStatusCount(3),
          l10n.telemetryGapCount(3),
          l10n.telemetrySignalCount(3),
        };
        expect(rendered, hasLength(4));
      }
      expect(en.telemetryGapCount(3), isNot(matches(_han)));
      expect(en.telemetryGapCount(1), contains('1'));
    });
  });

  group('limits come from the constants, not from the prose', () {
    test('the library chips render TelemetryQuota', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.telemetryLibraryGroupCount(2, TelemetryQuota.groupLimit),
          contains('${TelemetryQuota.groupLimit}'),
        );
        expect(
          l10n.telemetryLibraryBytes(
            '0.0',
            TelemetryQuota.libraryByteLimit ~/ (1024 * 1024),
          ),
          contains('${TelemetryQuota.libraryByteLimit ~/ (1024 * 1024)}'),
        );
      }
    });

    test('the recorder disclosure renders the trend-lane limit', () {
      for (final l10n in [en, zh]) {
        expect(
          l10n.telemetryRecorderDisclosure(maximumTelemetryTrendLanes, 7),
          allOf(contains('$maximumTelemetryTrendLanes'), contains('7')),
        );
      }
    });
  });

  group('the transcript size label', () {
    test('is Chinese-free in English and never reads as empty', () {
      for (final bytes in [1, 40, 199, 511, 1023]) {
        final label = formatTranscriptSize(en, bytes);
        expect(label, isNot(matches(_han)));
        expect(label.startsWith('0'), isFalse);
        expect(label, contains('$bytes'));
      }
    });

    test('units do not change with language', () {
      // KB is a unit, not prose. Both languages say the same thing above a
      // kilobyte, and neither converts it to something else.
      for (final l10n in [en, zh]) {
        expect(formatTranscriptSize(l10n, 1024), '1 KB');
        expect(formatTranscriptSize(l10n, 140 * 1024), '140 KB');
      }
    });
  });

  // ---------------------------------------------------------------------
  // Screens
  // ---------------------------------------------------------------------

  Future<void> pumpSessions(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionLibraryProvider.overrideWith((ref) async => _library),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const TelemetrySessionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDetail(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionReplayProvider.overrideWith(
            (ref, id) async => _replay,
          ),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const TelemetrySessionDetailScreen(
            sessionId: '00000000000000000000000000000001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpStrip(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(
            () => _FixedProgress(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(
                  phase: TelemetryRecorderPhase.recording,
                  valueCount: 243,
                  statusCount: 7,
                  gapCount: 1,
                ),
                elapsedUs: 42 * Duration.microsecondsPerSecond,
                bytesBeforeFooter: 8192,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-1',
              ),
            ),
          ),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(body: TelemetryRecorderStrip()),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpRecorderPanel(WidgetTester tester, Locale locale) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc();
    final snapshot = TelemetrySnapshot(
      readings: {
        PidLibrary.vehicleSpeed.id: Reading(
          pid: PidLibrary.vehicleSpeed,
          value: 0,
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
          obdSessionProvider.overrideWith(_DisconnectedSession.new),
          activePidsProvider.overrideWith(
            () => _FixedActivePids([
              PidLibrary.engineRpm,
              PidLibrary.vehicleSpeed,
            ]),
          ),
          telemetryProvider.overrideWith((ref) => Stream.value(snapshot)),
          liveTelemetryStartEnvironmentProvider.overrideWithValue(environment),
          currentTelemetryConnectionEvidenceProvider.overrideWithValue(
            const TelemetryConnectionEvidence(
              source: TelemetrySource.demo,
              transport: TransportKind.demo,
              protocol: 'ISO 15765-4 CAN',
            ),
          ),
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetryRecorderProgressProvider.overrideWith(
            () => _FixedProgress(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(
                  phase: TelemetryRecorderPhase.recording,
                  valueCount: 243,
                  statusCount: 7,
                  gapCount: 1,
                ),
                elapsedUs: 42 * Duration.microsecondsPerSecond,
                bytesBeforeFooter: 8192,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-1',
              ),
            ),
          ),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(child: TelemetryRecorderPanel()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpHistoryEntry(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionLibraryProvider.overrideWith((ref) async => _library),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(body: TelemetryHistoryEntry()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpTranscript(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          obdSessionProvider.overrideWith(_DisconnectedSession.new),
          recoveredTranscriptProvider.overrideWith(
            (ref) async => StoredTranscript(
              header: 'Telltale transcript',
              // Under a kilobyte on purpose: a failed handshake is the most
              // diagnostic recording this app makes, and the one that used to
              // be offered as "0 KB".
              body: 'x' * 400,
              savedAt: DateTime(2026, 8, 30, 9, 5),
            ),
          ),
        ],
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  RecoveredTranscriptPanel(),
                  TranscriptExportButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpRecoveryNotice(
    WidgetTester tester,
    Locale locale,
  ) async {
    final root = Directory.systemTemp.createTempSync('l03-recovery-');
    addTearDown(() => root.deleteSync(recursive: true));
    final telemetry = Directory('${root.path}/telltale-telemetry')
      ..createSync();
    File('${telemetry.path}/${'1' * 32}.ndjson.part')
        .writeAsStringSync('not-json\n', flush: true);
    final container = ProviderContainer(
      overrides: [
        telemetrySessionStoreProvider.overrideWithValue(
          TelemetrySessionStore(documentsDirectory: () async => root),
        ),
        appSharePolicyProvider.overrideWithValue(const _AllowedPolicy()),
        artifactOperationGateProvider.overrideWithValue(
          ArtifactOperationGate(),
        ),
        telemetryRecorderProgressProvider.overrideWith(
          () => _FixedProgress(
            const TelemetryRecorderProgress(
              state: TelemetryRecorderState.idle(),
              elapsedUs: 0,
              bytesBeforeFooter: 0,
              effectiveSessionLimit: null,
              sessionId: null,
            ),
          ),
        ),
        telemetryHistoryAccessProvider.overrideWithValue(
          TelemetryHistoryAccess.permitted,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(telemetryStartupRecoveryProvider.notifier)
          .initialize(),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(body: TelemetryStartupRecoveryNotice()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<ProviderContainer> pumpPowertrainBanner(
    WidgetTester tester,
    Locale locale,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final snapshot = snapshotOfProfiles([_powertrainProfileJson]);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(_ConnectedObdSession.new),
        powertrainBatteryCatalogLoaderProvider.overrideWithValue(
          () async => snapshot,
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(pidRegistryProvider.notifier)
        .installPowertrainProfile(
          snapshot,
          _powertrainProfileId,
          vehicleYear: 2021,
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedMaterialApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const Scaffold(body: PowertrainProfileConfirmBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Semantics is turned on for the duration of the body and turned off
  /// inside it — the binding asserts every [SemanticsHandle] is disposed
  /// *before* tearDown callbacks run, so `addTearDown(handle.dispose)` fails
  /// the test it was meant to clean up after.
  Future<void> withSemantics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await body();
    } finally {
      handle.dispose();
    }
  }

  group('at English, no Chinese reaches the screen', () {
    testWidgets('the saved-recordings list', (tester) async {
      await withSemantics(tester, () async {
        await pumpSessions(tester, english);
        _expectEnglishScreen(tester, 'TelemetrySessionsScreen');
        await tester.scrollUntilVisible(
          find.byTooltip(en.telemetryDeleteDamagedTooltip),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        _expectEnglishScreen(
          tester,
          'TelemetrySessionsScreen (damaged section)',
        );
      });
    });

    testWidgets('the replay detail, including the delete dialog', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        await pumpDetail(tester, english);
        _expectEnglishScreen(tester, 'TelemetrySessionDetailScreen');
        await tester.scrollUntilVisible(
          find.text(en.telemetryDelete),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // `scrollUntilVisible` stops when the finder matches, which can leave
        // the widget flush against the viewport edge — the tap then lands at
        // exactly y=600 in this 800x600 harness and hit-tests nothing.
        //
        // It started failing when the sampling notice above it was keyed: the
        // English sentence is roughly three times the length of 「預覽已抽樣；
        // 匯出保留完整已記錄事件」 and pushes this button down by a line. Real
        // screens are 2340px tall and scroll, so this is the harness rather
        // than the product — but the underlying fact is real and is the reason
        // the runbook's device gate exists: English copy is longer, and longer
        // copy moves things.
        await tester.ensureVisible(find.text(en.telemetryDelete));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en.telemetryDelete));
        await tester.pumpAndSettle();
        _expectEnglishScreen(tester, 'delete confirmation dialog');
        await tester.tap(find.text(en.telemetryCancel));
        await tester.pumpAndSettle();
      });
    });

    testWidgets('the export sheet', (tester) async {
      await withSemantics(tester, () async {
        await tester.pumpWidget(
          localizedMaterialApp(
            locale: english,
            theme: AppTheme.dark(),
            home: const Scaffold(body: TelemetryExportSheet()),
          ),
        );
        await tester.pumpAndSettle();
        _expectEnglishScreen(tester, 'TelemetryExportSheet');
      });
    });

    testWidgets('the shell recording strip', (tester) async {
      await withSemantics(tester, () async {
        await pumpStrip(tester, english);
        _expectEnglishScreen(tester, 'TelemetryRecorderStrip');
      });
    });

    testWidgets('the recorder panel', (tester) async {
      await withSemantics(tester, () async {
        await pumpRecorderPanel(tester, english);
        _expectEnglishScreen(tester, 'TelemetryRecorderPanel');
      });
    });

    testWidgets('the connect-screen history entry', (tester) async {
      await withSemantics(tester, () async {
        await pumpHistoryEntry(tester, english);
        _expectEnglishScreen(tester, 'TelemetryHistoryEntry');
      });
    });

    testWidgets('the startup recovery notice', (tester) async {
      await withSemantics(tester, () async {
        await pumpRecoveryNotice(tester, english);
        _expectEnglishScreen(tester, 'TelemetryStartupRecoveryNotice');
      });
    });

    testWidgets('the transcript panels', (tester) async {
      await withSemantics(tester, () async {
        await pumpTranscript(tester, english);
        _expectEnglishScreen(tester, 'transcript export');
      });
    });

    testWidgets('the powertrain confirmation, banner and dialog', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        await pumpPowertrainBanner(tester, english);
        _expectEnglishScreen(tester, 'PowertrainProfileConfirmBanner');
        await tester.tap(
          find.byKey(
            const Key('powertrain_confirm_connection_$_powertrainProfileId'),
          ),
        );
        await tester.pumpAndSettle();
        _expectEnglishScreen(tester, 'powertrain confirmation dialog');
      });
    });
  });

  group('at Traditional Chinese, the hedges are still there', () {
    testWidgets('a damaged file says which failure it is, and refuses both', (
      tester,
    ) async {
      await pumpSessions(tester, testUiLocale);
      await tester.scrollUntilVisible(
        find.textContaining('未選擇任何一份'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // A collision is not corruption, and neither file was picked. "We chose
      // the finished one" would be a different — and unearned — claim.
      expect(find.textContaining('未選擇任何一份'), findsOneWidget);
      expect(zh.telemetryDamagedCorrupt, contains('無法安全讀取'));
    });

    testWidgets('the replay preview says it is sampled', (tester) async {
      await pumpDetail(tester, testUiLocale);
      // The export keeps every recorded event; this preview does not. Dropping
      // 抽樣 would let a thin line read as the whole recording.
      expect(find.text('離線抽樣回放'), findsOneWidget);
    });

    testWidgets('startup recovery reports, and does not claim repair', (
      tester,
    ) async {
      await pumpRecoveryNotice(tester, testUiLocale);
      expect(find.textContaining('未自動修改'), findsOneWidget);
      expect(find.textContaining('不會用於回放或匯出'), findsOneWidget);
    });

    testWidgets('the recorder disclosure keeps 估算, not 量測', (tester) async {
      await pumpRecorderPanel(tester, testUiLocale);
      expect(find.textContaining('估算馬力與估算油耗'), findsOneWidget);
      expect(find.textContaining('不含位置、VIN 或帳號資料'), findsOneWidget);
    });

    testWidgets('the powertrain dialog keeps the plausible-wrong warning', (
      tester,
    ) async {
      await pumpPowertrainBanner(tester, testUiLocale);
      await tester.tap(
        find.byKey(
          const Key('powertrain_confirm_connection_$_powertrainProfileId'),
        ),
      );
      await tester.pumpAndSettle();
      // This project's organising principle, as product copy.
      expect(find.textContaining('看似合理但錯誤'), findsOneWidget);
      expect(find.textContaining('本次連線'), findsWidgets);
    });
  });

  group('the English carries the same warnings, not a softer version', () {
    test('the powertrain dialog still says the numbers can be wrong', () {
      expect(
        en.powertrainConfirmDialogBody.toLowerCase(),
        allOf(contains('plausible'), contains('wrong')),
      );
      expect(
        en.powertrainConfirmBody.toLowerCase(),
        contains('this connection'),
      );
    });

    test('recovery left damaged files alone; it did not repair them', () {
      expect(
        en.telemetryRecoveryDamaged(2).toLowerCase(),
        contains('unchanged'),
      );
      expect(
        en.telemetryRecoveryDamaged(2).toLowerCase(),
        isNot(contains('repair')),
      );
      expect(en.telemetryRecoveryDamagedNote.toLowerCase(), contains('never'));
    });

    test('a collision names both files and picks neither', () {
      expect(en.telemetryDamagedCollision.toLowerCase(), contains('neither'));
    });

    test('the recorder disclosure says estimated, never measured', () {
      final copy = en.telemetryRecorderDisclosure(4, 7).toLowerCase();
      expect(copy, contains('estimated'));
      expect(copy, isNot(contains('measured')));
    });

    test('the replay preview says sampled, not complete', () {
      expect(
        en.telemetryOfflineSampledReplay.toLowerCase(),
        contains('sampled'),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _library = TelemetrySessionLibrary(
  sessions: [
    TelemetrySessionProjection(
      id: '00000000000000000000000000000001',
      startedAtUtc: DateTime.utc(2026, 8, 30, 1),
      endedAtUtc: DateTime.utc(2026, 8, 30, 1, 2),
      source: TelemetrySource.demo,
      transport: TransportKind.demo.name,
      protocol: 'ISO 15765-4 CAN',
      signalCount: 2,
      valueCount: 10,
      statusCount: 1,
      gapCount: 1,
      terminalReason: TelemetryTerminalReason.user,
      bytes: 1024,
      elapsedDurationUs: 2 * 60 * 1000000,
    ),
  ],
  damaged: [
    DamagedTelemetryProjection(
      id: '00000000000000000000000000000002',
      filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 2),
      kind: DamagedTelemetryKind.collision,
    ),
  ],
  groupCount: 2,
  recognizedBytes: 1024,
  omittedCount: 3,
  encodedProjectionBytes: 512,
  workerDebugName: 'l03-l10n-worker',
);

final _replay = TelemetryReplayResult.success(
  TelemetrySessionReplay(
    sessionId: '00000000000000000000000000000001',
    startedAtUtc: DateTime.utc(2026, 8, 30, 1),
    endedAtUtc: DateTime.utc(2026, 8, 30, 3),
    source: TelemetrySource.demo,
    transport: TransportKind.demo.name,
    protocol: 'ISO 15765-4 CAN',
    signalCount: 2,
    valueCount: 3,
    statusCount: 1,
    gapCount: 2,
    terminalReason: TelemetryTerminalReason.user,
    elapsedDurationUs: 60000000,
    workerDebugName: 'l03-l10n-worker',
    lanes: const [
      TelemetryReplayLane(
        pidId: '7E0:010C',
        name: 'Engine RPM',
        unit: 'rpm',
        primitives: [
          TelemetryReplayPrimitive(
            kind: TelemetryReplayPrimitiveKind.value,
            elapsedUs: 0,
            value: 1000,
          ),
          TelemetryReplayPrimitive(
            kind: TelemetryReplayPrimitiveKind.gap,
            elapsedUs: 30000000,
          ),
          TelemetryReplayPrimitive(
            kind: TelemetryReplayPrimitiveKind.value,
            elapsedUs: 60000000,
            value: 2000,
            breakBefore: true,
          ),
        ],
      ),
    ],
  ),
);

const _powertrainProfileId = 'l03-l10n-profile';

final Map<String, Object?> _powertrainProfileJson = {
  'id': _powertrainProfileId,
  'display_name': 'Banner profile',
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
    'name': 'primary',
    'url': 'https://example.invalid/source',
    'revision': 'a' * 40,
    'license': 'Apache-2.0',
    'path': 'profile.csv',
    'locator': '22B046',
    'artifact_sha256': 'b' * 64,
  },
  'secondary_sources': [
    {
      'name': 'independent',
      'url': 'https://example.invalid/other',
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
          'id': 'raw-soc',
          'name': 'SOC',
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

class _FixedProgress extends TelemetryRecorderProgressNotifier {
  _FixedProgress(this.value);

  final TelemetryRecorderProgress value;

  @override
  TelemetryRecorderProgress build() => value;
}

class _FixedActivePids extends ActivePids {
  _FixedActivePids(this.value);

  final List<Pid> value;

  @override
  List<Pid> build() => value;
}

class _DisconnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

final class _ConnectedObdSession extends ObdSession {
  int fakeGeneration = 0;

  @override
  int get connectionGeneration => fakeGeneration;

  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Test rig',
    protocol: 'ISO 15765-4 CAN 11/500',
  );
}

final class _AllowedPolicy implements AppSharePolicy {
  const _AllowedPolicy();

  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
    recorderEpoch: 1,
    foregroundEpoch: 1,
    connectionEpoch: 1,
    safetyEpoch: 1,
    connectionClass: ShareConnectionClass.disconnected,
  );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.valid();
}
