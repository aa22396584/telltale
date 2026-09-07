// The polling-mode pill: what it is allowed to say, and how a reader gets to
// the explanation behind it.
//
// The pill used to print the bare identifier `fastMode` on one side and a
// translated sentence on the other. Two separate problems lived in that:
//
//   * `fastMode` is the name of a field, not a description of anything. It is
//     addressed to whoever reads the log, and it was the only user-facing
//     account of what the app was doing to the bus;
//   * whatever replaces it must not say more than the flag proves.
//     `PriorityScheduler.fastModeEnabled` starts `true` before a single
//     request has gone out, `PollingEngine.start` resets it to `true` on every
//     connection, and even while it is set a request is only grouped when the
//     member PID is confirmed batchable and more than one is queued. So the
//     enabled side may say "enabled" and may not say "active", "batched" or
//     "verified". The disabled side is the stronger of the two: it is only set
//     by `handleCorruptionEvent`, and while it is down `nextBatch` returns
//     exactly one request, so single-request polling is observed.
//
// The expectations below are HAND-TYPED, in both languages, per this repo's
// rule: a test that reads its expectation back from `AppLocalizations` agrees
// with whatever the ARB says, including a transposition of two arms. Type the
// sentence, and a swap fails.
//
// What the widget tests here do NOT cover: they render `DashboardScreen` under
// a real `ProviderScope` and the app's own localization root, not through the
// router from `ConnectScreen`. Route-level wiring is `demo_connect_journey_test
// .dart`'s subject. And the zero-traffic test measures writes across
// zero-duration pumps only — a timer-driven write across elapsed time is not
// attributable to a tap, so it is deliberately outside what that test claims.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/widgets/panel.dart';

import '../support/dart_source_reader.dart';

/// Every command the app put on the wire, in order.
///
/// `DemoTransport` rather than a stub, so the session runs its real handshake
/// and its real polling loop against something that answers the way the
/// hardware does. A stub that accepted writes and never replied would leave
/// the connection half-open, and a count taken there proves nothing.
class _CountingDemoTransport extends DemoTransport {
  final List<String> written = <String>[];

  @override
  Future<void> write(List<int> data) {
    written.add(ascii.decode(data, allowInvalid: true).trim());
    return super.write(data);
  }
}

/// The locale root the app itself builds, minus the startup gate.
///
/// `TorqueApp` resolves its locale from [localePreferenceProvider] through
/// `resolveAppLocale` and hands it to a `MaterialApp` carrying the generated
/// delegates. Changing the language in a test therefore has to go through the
/// same provider, not through a different `locale:` argument — otherwise the
/// zero-traffic claim is about an argument nobody in production changes.
class _LocaleRoot extends ConsumerWidget {
  const _LocaleRoot({required this.home, this.textScale = 1});

  final Widget home;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = resolveAppLocale(
      preference: ref.watch(localePreferenceProvider),
      deviceLocales: const [Locale('en', 'US')],
    );
    return MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );
  }
}

/// The recorder panel's own progress, held still.
///
/// Its real notifier arms a one-second periodic timer that outlives the test,
/// and a pending timer fails the test for a reason that has nothing to do with
/// the pill. `dashboard_l10n_test.dart` pins it the same way.
class _FixedProgress extends TelemetryRecorderProgressNotifier {
  @override
  TelemetryRecorderProgress build() => const TelemetryRecorderProgress(
    state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
    elapsedUs: 0,
    bytesBeforeFooter: 0,
    effectiveSessionLimit: null,
    sessionId: null,
  );
}

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Demo ECU',
  );
}

/// A snapshot that has been through at least one poll.
///
/// `capturedAt` is the gate the pill sits behind, and it is the whole reason
/// the pill is absent on a fresh connection: the default snapshot carries
/// `fastModeEnabled: true` and would otherwise announce a polling mode before
/// anything had been polled.
TelemetrySnapshot _polled({required bool batchingEnabled}) => TelemetrySnapshot(
  pidsPerSecond: 12,
  fastModeEnabled: batchingEnabled,
  capturedAt: DateTime.now(),
);

/// Every render-time error raised while [body] runs, not just the first.
///
/// `tester.takeException()` holds one exception at a time and a `RenderFlex`
/// reports its overflow **once per render object, ever** — so a second
/// `pumpWidget` into the same element tree reports nothing, and a comparison
/// built on `takeException` would read "no error" where the layout is
/// identical. Collecting from `FlutterError.onError` over a freshly mounted
/// tree is what makes two renders comparable.
Future<List<String>> _renderErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  // A fresh tree, so every render object is new and reports for the first
  // time.
  await tester.pumpWidget(const SizedBox.shrink());
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.exceptionAsString());
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// Two pumps rather than `pumpAndSettle`.
///
/// The status strip's live dot repeats forever while the session is connected,
/// so `pumpAndSettle` can only ever time out on this screen. The dialog route
/// builds on the first frame and its transition is done well inside 400 ms.
Future<void> _openHelpPump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<ProviderContainer> _pumpDashboard(
  WidgetTester tester, {
  required bool batchingEnabled,
  LocalePreference preference = LocalePreference.english,
  double textScale = 1,
  bool polled = true,
}) async {
  SharedPreferences.setMockInitialValues({
    kLocalePreferenceKey: localePreferenceToStored(preference),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      obdSessionProvider.overrideWith(_ConnectedSession.new),
      telemetryProvider.overrideWith(
        (ref) => Stream.value(
          polled
              ? _polled(batchingEnabled: batchingEnabled)
              : const TelemetrySnapshot(pidsPerSecond: 12),
        ),
      ),
      telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _LocaleRoot(textScale: textScale, home: const DashboardScreen()),
    ),
  );
  // The tiles fade in at 28 ms each; an unsettled animation hides text from
  // the finders.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Hand-typed. Not read back from the ARB, from `AppLocalizations`, or from
  // the widget under test.
  const enBatching = 'Batching enabled';
  const enSingle = 'Single request mode';
  const enAction = 'About polling mode';
  const enTitle = 'Polling mode';
  const zhBatching = '已啟用批次';
  const zhSingle = '單筆模式';
  const zhAction = '關於讀取模式';
  const zhTitle = '讀取模式';

  group('the label says what the flag proves, in both languages', () {
    final en = lookupAppLocalizations(englishLocale);
    final zh = lookupAppLocalizations(traditionalChineseLocale);

    test('enabled is enabled, and never active, batched or verified', () {
      expect(en.dashboardBatchingEnabled, enBatching);
      expect(zh.dashboardBatchingEnabled, zhBatching);
      // The three words the state cannot support. `enabled` is permission;
      // these would each be a claim that an exchange was observed.
      for (final forbidden in ['active', 'batched', 'verified']) {
        expect(
          en.dashboardBatchingEnabled.toLowerCase(),
          isNot(contains(forbidden)),
          reason:
              'the enabled side may not claim "$forbidden": '
              'PriorityScheduler.fastModeEnabled is permission, not a record',
        );
      }
    });

    test('the fallback side is unchanged and still translated', () {
      expect(en.dashboardSingleRequestMode, enSingle);
      expect(zh.dashboardSingleRequestMode, zhSingle);
    });

    test('the help action and title are named in both languages', () {
      expect(en.dashboardPollingModeHelpAction, enAction);
      expect(zh.dashboardPollingModeHelpAction, zhAction);
      expect(en.dashboardPollingModeHelpTitle, enTitle);
      expect(zh.dashboardPollingModeHelpTitle, zhTitle);
    });

    test('the explanation states the mechanism, the fallback and the limit', () {
      // Grouping to cut round trips, and the hedge that it is permission.
      expect(en.dashboardPollingModeHelpBatching, contains('group PID requests'));
      expect(en.dashboardPollingModeHelpBatching, contains('round trips'));
      expect(en.dashboardPollingModeHelpBatching, contains('permission'));
      expect(zh.dashboardPollingModeHelpBatching, contains('併成一次交握'));
      expect(zh.dashboardPollingModeHelpBatching, contains('這是授權，不是量測'));

      // The fallback continues to update, and is not by itself a lost link.
      expect(en.dashboardPollingModeHelpSingle, contains('each PID is read on its own'));
      expect(en.dashboardPollingModeHelpSingle, contains('carry on updating'));
      expect(
        en.dashboardPollingModeHelpSingle,
        contains('not a connection failure'),
      );
      expect(zh.dashboardPollingModeHelpSingle, contains('每個 PID 各自讀取'));
      expect(zh.dashboardPollingModeHelpSingle, contains('讀數仍會持續更新'));
      expect(zh.dashboardPollingModeHelpSingle, contains('不等於連線失敗'));

      // The rate is observed, and depends on six named things.
      expect(en.dashboardPollingModeHelpRate, contains('observed over the last second'));
      expect(zh.dashboardPollingModeHelpRate, contains('過去一秒觀測到的速率'));
      for (final term in ['adapter', 'bus', 'ECU', 'PIDs you selected', 'reply', 'errors']) {
        expect(
          en.dashboardPollingModeHelpRate,
          contains(term),
          reason: 'the rate paragraph dropped "$term"',
        );
      }
      for (final term in ['轉接器', '匯流排', 'ECU', '你選的 PID', '回覆的大小', '錯誤']) {
        expect(
          zh.dashboardPollingModeHelpRate,
          contains(term),
          reason: 'the Chinese rate paragraph dropped "$term"',
        );
      }
      // `PIDs/s` is on docs/i18n/do-not-translate.md: the pill beside this
      // paragraph prints that exact token, and a translated copy in the
      // explanation would stop naming the thing it explains.
      for (final value in [
        en.dashboardPollingModeHelpRate,
        zh.dashboardPollingModeHelpRate,
      ]) {
        expect(value, contains('PIDs/s'));
      }
    });
  });

  testWidgets('a tap on the pill opens the explanation', (tester) async {
    await _pumpDashboard(tester, batchingEnabled: true);
    expect(find.text(enBatching), findsOneWidget);
    expect(find.text(enTitle), findsNothing);

    await tester.tap(find.byKey(PollingModePill.pillKey));
    await _openHelpPump(tester);

    expect(find.text(enTitle), findsOneWidget);
    expect(
      find.textContaining('group PID requests'),
      findsOneWidget,
      reason: 'the dialog did not render the batching paragraph',
    );
  });

  testWidgets('the fallback side renders its own label', (tester) async {
    await _pumpDashboard(tester, batchingEnabled: false);
    expect(find.text(enSingle), findsOneWidget);
    expect(find.text(enBatching), findsNothing);
  });

  testWidgets('the explanation is reachable from the keyboard alone', (
    tester,
  ) async {
    await _pumpDashboard(tester, batchingEnabled: true);

    // Focus without touching the widget, then activate. A `tap` here would
    // make this a second copy of the tap test; the point is that the InkWell's
    // ActivateIntent handler exists, which a GestureDetector does not have.
    final inkWell = tester.widget<InkWell>(
      find.byKey(PollingModePill.pillKey),
    );
    expect(
      inkWell.canRequestFocus,
      isTrue,
      reason: 'a control a keyboard cannot reach is not keyboard-accessible',
    );
    // From inside the InkWell, so `Focus.of` finds the node the InkResponse
    // built rather than an ancestor scope.
    final focusNode = Focus.of(
      tester.element(
        find.descendant(
          of: find.byKey(PollingModePill.pillKey),
          matching: find.byType(StatusPill),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _openHelpPump(tester);

    expect(find.text(enTitle), findsOneWidget);
  });

  testWidgets('the semantics tree exposes a button with the localized name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpDashboard(tester, batchingEnabled: true);

    final node = tester.getSemantics(find.byKey(PollingModePill.pillKey));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    // Both halves: what the control is for, and what state it is reporting.
    expect(node.label, contains(enAction));
    expect(node.label, contains(enBatching));
    // No raw identifier reaches a screen reader.
    expect(node.label, isNot(contains('fastMode')));
    handle.dispose();
  });

  testWidgets('the Traditional Chinese build speaks Chinese throughout', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpDashboard(
      tester,
      batchingEnabled: true,
      preference: LocalePreference.traditionalChinese,
    );

    expect(find.text(zhBatching), findsOneWidget);
    final node = tester.getSemantics(find.byKey(PollingModePill.pillKey));
    expect(node.label, contains(zhAction));
    expect(node.label, contains(zhBatching));
    handle.dispose();

    await tester.tap(find.byKey(PollingModePill.pillKey));
    await _openHelpPump(tester);
    expect(find.text(zhTitle), findsOneWidget);
    expect(find.textContaining('併成一次交握'), findsOneWidget);
  });

  group('the pill and its explanation survive the hard geometries', () {
    // 320dp is the narrowest width this project supports, landscape is the
    // windscreen-mount case, and 200% is the largest step Android's display
    // size and font size controls reach together.
    //
    // The assertion is a COMPARISON, not `takeException() == null`. This
    // dashboard already overflows a `RenderFlex` by 126 px at 640x320 in both
    // languages, with the polling-mode pill present and with it absent — it
    // predates this change and is not in this slice. An absolute assertion
    // here would either fail on a defect it did not introduce or, once
    // softened, stop being able to fail at all. So each geometry is rendered
    // twice: once with the snapshot unpolled, where the pill is hidden by the
    // `capturedAt` gate, and once with it shown. What the pill adds must be
    // nothing.
    const geometries = <String, (Size, double)>{
      '320dp portrait': (Size(320, 640), 1),
      'landscape': (Size(640, 320), 1),
      '320dp at 200% text': (Size(320, 640), 2),
      'landscape at 200% text': (Size(640, 320), 2),
    };

    for (final entry in geometries.entries) {
      for (final locale in <String, LocalePreference>{
        'en': LocalePreference.english,
        'zh_Hant': LocalePreference.traditionalChinese,
      }.entries) {
        testWidgets('${entry.key}, ${locale.key}', (tester) async {
          final (size, scale) = entry.value;
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final baseline = await _renderErrors(tester, () async {
            await _pumpDashboard(
              tester,
              batchingEnabled: true,
              preference: locale.value,
              textScale: scale,
              polled: false,
            );
          });
          expect(
            find.byKey(PollingModePill.pillKey),
            findsNothing,
            reason: 'the capturedAt gate let the pill through before a poll',
          );

          final withPill = await _renderErrors(tester, () async {
            await _pumpDashboard(
              tester,
              batchingEnabled: true,
              preference: locale.value,
              textScale: scale,
            );
          });
          expect(find.byKey(PollingModePill.pillKey), findsOneWidget);
          expect(
            withPill,
            baseline,
            reason: 'the pill changed what this screen reports at ${entry.key}',
          );

          // Inside the viewport, not merely present in the tree.
          final rect = tester.getRect(find.byKey(PollingModePill.pillKey));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width + 0.5));

          final opening = await _renderErrors(tester, () async {
            await _pumpDashboard(
              tester,
              batchingEnabled: true,
              preference: locale.value,
              textScale: scale,
            );
            await tester.tap(find.byKey(PollingModePill.pillKey));
            await _openHelpPump(tester);
          });

          final english = locale.value == LocalePreference.english;
          expect(find.text(english ? enTitle : zhTitle), findsOneWidget);
          // All three paragraphs, not just the first. The dialog scrolls, so a
          // paragraph pushed past the bottom is still built and still
          // findable; one that could not be laid out at all is not.
          for (final paragraph in english
              ? const [
                  'group PID requests',
                  'each PID is read on its own',
                  // Not the bare token: the throughput pill beside the
                  // explanation prints `PIDs/s` too, so a search for it finds
                  // two widgets and says nothing about this paragraph.
                  'observed over the last second',
                ]
              : const [
                  '併成一次交握',
                  '每個 PID 各自讀取',
                  '過去一秒觀測到的速率',
                ]) {
            expect(
              find.textContaining(paragraph),
              findsOneWidget,
              reason: 'the explanation lost "$paragraph" at ${entry.key}',
            );
          }
          expect(
            opening,
            baseline,
            reason:
                'the explanation changed what this screen reports at '
                '${entry.key}',
          );
        });
      }
    }
  });

  testWidgets('opening the help and changing language put nothing on the wire', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      kLocalePreferenceKey: localePreferenceToStored(LocalePreference.english),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
      ],
    );

    final session = container.read(obdSessionProvider.notifier);
    final transport = _CountingDemoTransport();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _LocaleRoot(home: DashboardScreen()),
      ),
    );

    // The handshake and the first polls need real elapsed time. Everything
    // after this runs on the fake clock, where a `Future.delayed` scheduled in
    // the real zone cannot fire — which is what makes the counts below
    // attributable to the taps rather than to the loop.
    await tester.runAsync(() async {
      expect(
        await session.connectForTest(transport, TransportKind.demo),
        isTrue,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(PollingModePill.pillKey),
      findsOneWidget,
      reason: 'no snapshot was published, so the pill under test never rendered',
    );
    expect(
      transport.written,
      isNotEmpty,
      reason: 'nothing was ever written, so a count of zero proves nothing',
    );

    // Quiescence, established rather than assumed: two consecutive
    // zero-duration pumps that add no command.
    await tester.pump();
    final settled = transport.written.length;
    await tester.pump();
    expect(
      transport.written.length,
      settled,
      reason: 'the loop was still writing; the baseline would be meaningless',
    );

    final generation = session.connectionGeneration;
    final baseline = transport.written.length;

    await tester.tap(find.byKey(PollingModePill.pillKey));
    await tester.pump();
    await tester.pump();
    expect(find.text(enTitle), findsOneWidget);
    expect(
      transport.written.length,
      baseline,
      reason:
          'opening the explanation wrote to the adapter: '
          '${transport.written.skip(baseline).toList()}',
    );

    await container
        .read(localePreferenceProvider.notifier)
        .set(LocalePreference.traditionalChinese);
    await tester.pump();
    await tester.pump();
    expect(find.text(zhTitle), findsOneWidget);
    expect(
      transport.written.length,
      baseline,
      reason:
          'changing the language wrote to the adapter: '
          '${transport.written.skip(baseline).toList()}',
    );

    // The connection is the same one, not a new one that happens to look alike.
    expect(container.read(obdSessionProvider).phase, ConnectionPhase.connected);
    expect(session.connectionGeneration, generation);

    // Disposed here rather than in a tear-down: `telemetryProvider` arms a
    // one-second periodic timer in the fake-async zone, the binding checks for
    // pending timers when the body returns, and tear-downs run after that.
    await tester.runAsync(session.disconnect);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  test('no screen under lib/ui renders the raw identifier as a label', () {
    // By census, not by name: every Dart file under lib/ui, every string
    // literal in it. A hand-written list of the files that matter is correct
    // once.
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(
      files.length,
      greaterThan(20),
      reason: 'the sweep found almost nothing; the path is probably wrong',
    );

    // A positive control for the reader itself. If `stringLiteralsOnly` came
    // back empty for every file — a resynchronisation bug, a changed API — the
    // guard below would pass while seeing nothing.
    var sawAKnownLiteral = false;
    final offenders = <String>[];
    for (final file in files) {
      final literals = stringLiteralsOnly(file.readAsStringSync());
      if (literals.contains('dashboardPollingModePill')) sawAKnownLiteral = true;
      if (literals.contains('fastMode')) offenders.add(file.path);
    }
    expect(
      sawAKnownLiteral,
      isTrue,
      reason:
          'the reader returned no known literal, so an empty result below '
          'would mean nothing',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'a raw `fastMode` string literal is back in lib/ui. The identifier '
          'stays in lib/obd, in logs and in code; what a driver reads comes '
          'from the ARB',
    );
  });
}
