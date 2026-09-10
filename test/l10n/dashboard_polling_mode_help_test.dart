// The polling-mode pill: what it is allowed to say, and how a reader gets to
// the explanation behind it.
//
// The pill used to print the bare identifier `fastMode` on one side and a
// translated sentence on the other. Two separate problems lived in that:
//
//   * `fastMode` is the name of a field, not a description of anything. It is
//     addressed to whoever reads the log, and it was the only user-facing
//     account of what the app was doing to the bus;
//   * whatever replaces it must not say more than the state proves, and the
//     state has two halves. `PriorityScheduler.fastModeEnabled` starts `true`
//     before a single request has gone out, `PollingEngine.start` resets it to
//     `true` on every connection, and only `handleCorruptionEvent` withdraws
//     it. `PriorityScheduler.canBatch` is the other half: recomputed before
//     every command as "the addressing is CAN and a support block has
//     answered", so it is `false` for the whole of every non-CAN session and
//     `false` on CAN until discovery lands.
//
//     Reading the first half alone is how the pill came to read "Batching
//     enabled" on sessions where `popBatch` can never group anything — review
//     found it, and the truth-table test below is what stops it returning.
//     "Enabled" needs both, and even then it is permission: grouping also
//     wants the PID confirmed batchable and more than one queued, so "active",
//     "batched" and "verified" stay unsayable. The fallback label is the
//     provable one, and it covers two states rather than one: a bus that never
//     groups, and grouping withdrawn after a bad reply.
//
//     Neither half stops a powertrain profile response, whose PIDs share one
//     reply by construction and which `popBatch` drains as one batch before it
//     reads either flag. That is why the copy says "Mode 01" and not "each
//     PID".
//
// The expectations below are HAND-TYPED, in both languages, per this repo's
// rule: a test that reads its expectation back from `AppLocalizations` agrees
// with whatever the ARB says, including a transposition of two arms. Type the
// sentence, and a swap fails.
//
// What the widget tests here do NOT cover: they render `DashboardScreen` under
// a real `ProviderScope` and the app's own localization root, not through the
// router from `ConnectScreen`. Route-level wiring is
// `demo_connect_journey_test.dart`'s subject.
//
// The zero-traffic test is on its second instrument, because the first one
// could not fail in the way that mattered. It measured across zero-duration
// pumps, which froze the ENGINE along with the polling loop — every await in
// the engine is a real-zone timer the fake clock never advances. Review
// injected `engine.readVin()` into the help handler; every open of the dialog
// put `0902` on the bus and the file stayed green at the full control total.
// A raw `transport.write` was the only shape it could see, and no
// implementation of this feature would ever write that way.
//
// It now parks the polling loop with `PollingEngine.stop()`, keeping the
// connection, and measures across windows of REAL elapsed time. A command the
// tap routes through the engine has time to reach the transport and be
// counted. What that still cannot attribute is a write from something on a
// real timer longer than the window — the client's five-second stall watchdog,
// for one. The quiescence precondition is what bounds it: with the loop parked
// the same window adds nothing, and with the loop running it adds dozens, so
// the precondition is a measurement rather than a restatement.
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
import '../support/fake_elm327.dart';

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
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
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

/// A window of real elapsed time, long enough for a command the UI just routed
/// through the engine to reach the transport.
///
/// The engine's awaits are real-zone timers. Advancing the fake clock does not
/// move them, which is exactly how an injected `engine.readVin()` in the help
/// handler went unseen by an earlier version of this file. Anything the
/// measurement wants to be able to catch has to be given real milliseconds.
Future<void> _realWindow(WidgetTester tester) => tester.runAsync(
  () => Future<void>.delayed(const Duration(milliseconds: 300)),
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
  bool busAllowsGrouping = true,
  LocalePreference preference = LocalePreference.english,
  double textScale = 1,
  bool polled = true,
  TelemetrySnapshot? snapshot,
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
          snapshot ??
              (polled
                  ? _polled(batchingEnabled: batchingEnabled)
                  : const TelemetrySnapshot(pidsPerSecond: 12)),
        ),
      ),
      telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
      // The engine half of the permission. The real provider reads
      // `PriorityScheduler.canBatch` off the live engine, which a fake session
      // does not have; overriding it is how the non-CAN session below is
      // expressed without inventing a transport.
      busGroupsRequestsProvider.overrideWithValue(busAllowsGrouping),
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
  const enBatched = 'Batched polling';
  const enSingle = 'Single request mode';
  const enAction = 'About polling mode';
  const enTitle = 'Polling mode';
  const zhBatching = '已啟用批次';
  const zhBatched = '批次讀取';
  const zhSingle = '單筆模式';
  const zhAction = '關於讀取模式';
  const zhTitle = '讀取模式';

  group('the label says what the flag proves, in both languages', () {
    final en = lookupAppLocalizations(englishLocale);
    final zh = lookupAppLocalizations(traditionalChineseLocale);

    test('enabled is enabled, and never active, batched or verified', () {
      expect(en.dashboardBatchingEnabled, enBatching);
      expect(zh.dashboardBatchingEnabled, zhBatching);
      expect(en.dashboardBatchedPolling, enBatched);
      expect(zh.dashboardBatchedPolling, zhBatched);
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
      expect(
        en.dashboardBatchedPolling.toLowerCase(),
        contains('batched'),
        reason: 'the observed label is the one place "batched" is allowed',
      );
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
      expect(
        en.dashboardPollingModeHelpBatching,
        contains('group PID requests'),
      );
      expect(en.dashboardPollingModeHelpBatching, contains('round trips'));
      expect(en.dashboardPollingModeHelpBatching, contains('permission'));
      expect(zh.dashboardPollingModeHelpBatching, contains('併成一次交握'));
      expect(zh.dashboardPollingModeHelpBatching, contains('仍然是授權而不是量測'));
      expect(en.dashboardPollingModeHelpObserved, contains('last Mode 01'));
      expect(
        en.dashboardPollingModeHelpObserved,
        contains('more than one PID'),
      );
      expect(zh.dashboardPollingModeHelpObserved, contains('Mode 01'));
      expect(zh.dashboardPollingModeHelpObserved, contains('超過一個 PID'));
      // The fallback continues to update, and is not by itself a lost link.
      expect(en.dashboardPollingModeHelpSingle, contains('carry on updating'));
      expect(
        en.dashboardPollingModeHelpSingle,
        contains('not a connection failure'),
      );
      expect(zh.dashboardPollingModeHelpSingle, contains('讀數仍會持續更新'));
      expect(zh.dashboardPollingModeHelpSingle, contains('不等於連線失敗'));

      // All three ways into `handleCorruptionEvent`, because naming one of
      // them is how this sentence was wrong. A batch answered `NO DATA` is
      // silence, and telling a driver on a partial-map vehicle that their
      // adapter returned something garbled describes a cause nothing observed.
      for (final cause in ['truncated', 'buffer full', 'unanswered']) {
        expect(
          en.dashboardPollingModeHelpSingle,
          contains(cause),
          reason: 'the fallback sentence stopped covering "$cause"',
        );
      }
      for (final cause in ['被截斷', '緩衝區已滿', '沒有回應']) {
        expect(
          zh.dashboardPollingModeHelpSingle,
          contains(cause),
          reason: 'the Chinese fallback sentence stopped covering "$cause"',
        );
      }
      // And the wording that named only one of the three does not come back.
      expect(
        en.dashboardPollingModeHelpSingle,
        isNot(contains('short or garbled')),
      );
      expect(zh.dashboardPollingModeHelpSingle, isNot(contains('過短或錯亂')));

      // The fallback label covers three unrelated states and has to name all
      // of them. A bus that never groups is not a fallback from anything; a
      // CAN bus whose support blocks have not answered yet is grouping held
      // back on purpose, with nothing wrong and nothing failed; and only the
      // third is a fallback from a bad reply. The copy named the first and the
      // third, so a driver in the second was told either that their bus does
      // not group — it might — or that a grouped request had failed. None had
      // been sent.
      expect(
        en.dashboardPollingModeHelpSingle,
        contains('does not take grouped requests'),
      );
      expect(en.dashboardPollingModeHelpSingle, contains('non-CAN'));
      expect(zh.dashboardPollingModeHelpSingle, contains('根本不接受併批請求'));
      expect(zh.dashboardPollingModeHelpSingle, contains('非 CAN'));

      expect(
        en.dashboardPollingModeHelpSingle,
        contains('no support block has answered yet'),
      );
      expect(
        en.dashboardPollingModeHelpSingle,
        contains('grouping PIDs the vehicle has not confirmed'),
      );
      expect(zh.dashboardPollingModeHelpSingle, contains('還沒有任何支援區塊回應過'));
      expect(zh.dashboardPollingModeHelpSingle, contains('尚未確認的 PID'));

      // And the two-cause wording does not come back. Its connective is what
      // vanishes when the third state is written in, so that is what is
      // pinned: a sentence that reads "non-CAN vehicle, and drops back" has
      // gone back to naming two.
      expect(
        en.dashboardPollingModeHelpSingle,
        isNot(contains('non-CAN vehicle, and drops back')),
      );
      expect(
        zh.dashboardPollingModeHelpSingle,
        isNot(contains('Telltale 會一直待在這個模式；而當')),
      );

      // Mode 01, because a powertrain profile response is drained as one batch
      // in either mode: several logical PIDs, one command, one reply. Saying
      // "each PID" without the qualifier is false for anyone running an
      // installed battery profile.
      expect(
        en.dashboardPollingModeHelpSingle,
        contains('each Mode 01 PID is read on its own'),
      );
      expect(
        zh.dashboardPollingModeHelpSingle,
        contains('每個 Mode 01 PID 各自讀取'),
      );

      // canBatch is addressing.isCan && a nonempty verified-support map. That
      // is set after a support block answers and before any grouped request
      // has been sent, so the first snapshot that lights this pill can follow
      // a single-PID poll. "This bus takes grouped requests" is an observation
      // no exchange has supplied yet. Permission is what the flag proves.
      expect(
        en.dashboardPollingModeHelpBatching,
        contains('grouped attempts are permitted'),
      );
      expect(zh.dashboardPollingModeHelpBatching, contains('允許嘗試併批'));
      expect(
        en.dashboardPollingModeHelpBatching,
        isNot(contains('this bus takes grouped requests')),
      );
      expect(
        zh.dashboardPollingModeHelpBatching,
        isNot(contains('這條匯流排接受併批請求')),
      );

      // The rate is observed, and depends on six named things.
      expect(
        en.dashboardPollingModeHelpRate,
        contains('observed over the last second'),
      );
      expect(zh.dashboardPollingModeHelpRate, contains('過去一秒觀測到的速率'));
      for (final term in [
        'adapter',
        'bus',
        'ECU',
        'PIDs you selected',
        'reply',
        'errors',
      ]) {
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

  testWidgets('a heartbeat with no poll does not announce a polling mode', (
    tester,
  ) async {
    // `PollingEngine.current` stamps capturedAt on the idle spin when
    // `_active` is empty. That is not a poll: no Mode 01 PID was read, and
    // the fallback paragraph would claim otherwise.
    await _pumpDashboard(
      tester,
      batchingEnabled: true,
      snapshot: TelemetrySnapshot(capturedAt: DateTime.now()),
    );
    expect(find.byKey(PollingModePill.pillKey), findsNothing);
  });

  testWidgets('a first batch that withdrew grouping still shows the fallback', (
    tester,
  ) async {
    // BUFFER FULL / a throwing first `_pollBatch` leave no reading and no
    // PIDs/s, but they do set the scheduler flag false. That is the fallback
    // the help exists to explain; inferring a poll only from output hid it.
    await _pumpDashboard(
      tester,
      batchingEnabled: false,
      snapshot: TelemetrySnapshot(
        capturedAt: DateTime.now(),
        fastModeEnabled: false,
      ),
    );
    expect(find.byKey(PollingModePill.pillKey), findsOneWidget);
    expect(find.text(enSingle), findsOneWidget);
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

  testWidgets('a non-CAN session does not claim grouping it can never do', (
    tester,
  ) async {
    // The state that made this necessary. `fastModeEnabled` is true — nothing
    // has gone wrong, nothing has been withdrawn — but `canBatch` is false for
    // the whole session because the addressing is not CAN, so `popBatch`
    // returns a single Mode 01 request every time. The label read "Batching
    // enabled" on every one of those sessions until review caught it.
    await _pumpDashboard(
      tester,
      batchingEnabled: true,
      busAllowsGrouping: false,
    );
    expect(find.text(enSingle), findsOneWidget);
    expect(
      find.text(enBatching),
      findsNothing,
      reason:
          'the scheduler flag alone was allowed to claim grouping on a bus '
          'that cannot group',
    );

    // And the explanation names that state, not only the corruption fallback.
    await tester.tap(find.byKey(PollingModePill.pillKey));
    await _openHelpPump(tester);
    expect(
      find.textContaining('does not take grouped requests'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Batched polling is shown only when a Mode 01 command packed two PIDs',
    (tester) async {
      await _pumpDashboard(
        tester,
        batchingEnabled: true,
        snapshot: TelemetrySnapshot(
          pidsPerSecond: 12,
          fastModeEnabled: true,
          lastMode01PidCount: 2,
          capturedAt: DateTime.now(),
        ),
      );
      expect(find.text(enBatched), findsOneWidget);
      expect(
        find.text(enBatching),
        findsNothing,
        reason:
            'permission without the observed count stays Batching enabled; '
            'this snapshot has the count, so the enabled label must yield',
      );
    },
  );

  testWidgets('a single-PID Mode 01 command does not claim Batched polling', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      batchingEnabled: true,
      snapshot: TelemetrySnapshot(
        pidsPerSecond: 12,
        fastModeEnabled: true,
        lastMode01PidCount: 1,
        capturedAt: DateTime.now(),
      ),
    );
    expect(find.text(enBatching), findsOneWidget);
    expect(find.text(enBatched), findsNothing);
  });

  testWidgets('an observed batch does not outrank withdrawn grouping', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      batchingEnabled: false,
      snapshot: TelemetrySnapshot(
        capturedAt: DateTime.now(),
        fastModeEnabled: false,
        lastMode01PidCount: 6,
      ),
    );
    expect(find.text(enSingle), findsOneWidget);
    expect(find.text(enBatched), findsNothing);
  });

  testWidgets(
    'an observed batch on a bus that cannot group is still the fallback',
    (tester) async {
      await _pumpDashboard(
        tester,
        batchingEnabled: true,
        busAllowsGrouping: false,
        snapshot: TelemetrySnapshot(
          pidsPerSecond: 12,
          fastModeEnabled: true,
          lastMode01PidCount: 2,
          capturedAt: DateTime.now(),
        ),
      );
      expect(find.text(enSingle), findsOneWidget);
      expect(find.text(enBatched), findsNothing);
    },
  );

  testWidgets('the enabled label needs both halves of the permission', (
    tester,
  ) async {
    // The truth table, hand-typed rather than derived: only both.
    for (final row in const [
      (scheduler: true, bus: true, expected: enBatching),
      (scheduler: true, bus: false, expected: enSingle),
      (scheduler: false, bus: true, expected: enSingle),
      (scheduler: false, bus: false, expected: enSingle),
    ]) {
      await _pumpDashboard(
        tester,
        batchingEnabled: row.scheduler,
        busAllowsGrouping: row.bus,
      );
      expect(
        find.text(row.expected),
        findsOneWidget,
        reason:
            'scheduler=${row.scheduler}, bus=${row.bus} should read '
            '"${row.expected}"',
      );
    }
  });

  testWidgets(
    'the explanation activates from the keyboard once the pill has focus',
    (tester) async {
      await _pumpDashboard(tester, batchingEnabled: true);

      // Focus without touching the widget, then activate. A `tap` here would
      // make this a second copy of the tap test; the point is that the InkWell's
      // ActivateIntent handler exists, which a GestureDetector does not have.
      //
      // Named for what it does. It focuses the node directly rather than walking
      // there with Tab, so it proves activation, not reachability by traversal —
      // the earlier name claimed the second and tested the first.
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
    },
  );

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

  testWidgets('the padded part of the target is what opens the explanation', (
    tester,
  ) async {
    // The geometry group asserts a SIZE. Everything a driver does with that
    // size is an assumption on top of it: that `InkResponse` hit-tests its
    // whole box rather than deferring to the child it draws. It does, but the
    // assertion above cannot see the difference, and a later change of
    // behaviour would leave a 48dp box with a 26dp target and a green suite.
    //
    // So this taps a point that is inside the box and demonstrably not on
    // anything drawn.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDashboard(tester, batchingEnabled: true);

    final target = tester.getRect(find.byKey(PollingModePill.pillKey));
    final drawn = tester.getRect(
      find.descendant(
        of: find.byKey(PollingModePill.pillKey),
        matching: find.byType(StatusPill),
      ),
    );

    // One pixel inside the top edge of the target.
    final point = Offset(target.center.dx, target.top + 1);
    expect(
      drawn.top - point.dy,
      greaterThanOrEqualTo(10.0),
      reason:
          'the tap point has to be clear of the decoration, or this is the '
          'tap test again with extra arithmetic',
    );
    expect(target.contains(point), isTrue);

    expect(find.text(enTitle), findsNothing);
    await tester.tapAt(point);
    await _openHelpPump(tester);
    expect(
      find.text(enTitle),
      findsOneWidget,
      reason:
          'the padding is part of the box but not part of the target: the '
          'control is 48dp to a ruler and 26dp to a finger',
    );
  });

  group('the pill and its explanation survive the hard geometries', () {
    // 320dp is the narrowest width this project supports, landscape is the
    // windscreen-mount case, and 200% is the largest step Android's display
    // size and font size controls reach together.
    //
    // #130 fixed the toolbar overflow that used to make an absolute check
    // fail on a defect this slice did not introduce. Each geometry is
    // rendered three times — pill hidden, pill shown, help opened — and
    // every one of those frames must report zero render errors. Comparing
    // against a pre-#130 overflow baseline would stay green while the
    // dashboard still overflowed.
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
            reason: 'the poll gate let the pill through before a poll',
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
            baseline,
            isEmpty,
            reason: 'the dashboard complained at ${entry.key} before the pill',
          );
          expect(
            withPill,
            isEmpty,
            reason: 'the dashboard complained at ${entry.key} with the pill',
          );

          // Inside the viewport, not merely present in the tree.
          final rect = tester.getRect(find.byKey(PollingModePill.pillKey));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width + 0.5));

          // A finger, in a car, over a bump. The pill's own decoration is
          // shorter than the target, so the interactive region has to be
          // padded out rather than inherit it — asserted at every geometry
          // because the one that would lose it is the narrow one, where
          // something has to give.
          //
          // Height only. The width was asserted here too and could not fail:
          // the label is a multi-word localized string, so the pill is several
          // times the target wide wherever this suite renders it. Pushing the
          // widget's constant down fired this message at most geometries and
          // the width one at none, which is how an assertion that reads like
          // protection turns out to be decoration.
          //
          // 48 is typed here, not read from `PollingModePill.minTapTarget`.
          // Reading the widget's own constant would make this agree with
          // whatever the widget currently says: set that constant to 24 and
          // this would still pass while the target halved. That is the shape
          // this repo has been bitten by — a test compared against a copy of
          // the code that produced it.
          //
          // A size is not an activation. That they coincide is a property of
          // `InkResponse`, which hit-tests opaquely across its whole box; the
          // test below taps the padding to observe it rather than trust it.
          expect(
            rect.height,
            greaterThanOrEqualTo(48.0),
            reason: 'the tap target shrank below 48dp at ${entry.key}',
          );

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
          for (final paragraph
              in english
                  ? const [
                      'group PID requests',
                      'each Mode 01 PID is read on its own',
                      // Not the bare token: the throughput pill beside the
                      // explanation prints `PIDs/s` too, so a search for it finds
                      // two widgets and says nothing about this paragraph.
                      'observed over the last second',
                    ]
                  : const ['併成一次交握', '每個 Mode 01 PID 各自讀取', '過去一秒觀測到的速率']) {
            expect(
              find.textContaining(paragraph),
              findsOneWidget,
              reason: 'the explanation lost "$paragraph" at ${entry.key}',
            );
          }
          expect(
            opening,
            isEmpty,
            reason:
                'the dashboard complained at ${entry.key} with the '
                'explanation open',
          );
        });
      }
    }
  });

  /// A vehicle that answers, on a bus that cannot group.
  ///
  /// The blocks chain 0100 -> 0120 -> 0140 so discovery verifies them the way a
  /// real car does, which is the half of `canBatch` that is *not* the
  /// addressing — otherwise a false here would be false for the wrong reason.
  FakeElm327 legacyVehicle() => FakeElm327(
    protocol: BusProtocol.iso9141,
    ecus: [
      FakeEcu(
        name: 'ECM',
        requestId: '6810F1',
        responseId: '486BF1',
        responses: {
          '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
          '0120': [0x41, 0x20, 0x80, 0x00, 0x00, 0x01],
          '0140': [0x41, 0x40, 0x40, 0x00, 0x00, 0x00],
          '0104': [0x41, 0x04, 0x40],
          '0105': [0x41, 0x05, 0x5A],
          '010B': [0x41, 0x0B, 0x64],
          '010C': [0x41, 0x0C, 0x1A, 0xF8],
          '010D': [0x41, 0x0D, 0x3C],
          '010F': [0x41, 0x0F, 0x50],
          '0110': [0x41, 0x10, 0x0A, 0xF0],
          '0111': [0x41, 0x11, 0x30],
        },
      ),
    ],
  );

  testWidgets('a real non-CAN session renders the fallback label', (
    tester,
  ) async {
    // The one test that runs the real `busGroupsRequestsProvider` on the
    // branch that matters. Everything else overrides it, so inverting the
    // provider outright used to leave the file green with the over-claim
    // restored wholesale.
    //
    // It asserts through the rendered label rather than `container.read`.
    // Reading a `Provider` nobody is listening to returns whatever it computed
    // first — `false`, against `engine == null` — and goes on returning it; the
    // widget is the only place the value is watched, so the widget is where it
    // can be observed alive.
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _LocaleRoot(home: DashboardScreen()),
      ),
    );
    await tester.runAsync(() async {
      expect(
        await session.connectForTest(legacyVehicle(), TransportKind.wifi),
        isTrue,
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await session.engine!.stop();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // The state, from the engine rather than from the fixture's intent.
    final scheduler = session.engine!.scheduler;
    expect(
      session.engine!.client.addressing.isCan,
      isFalse,
      reason: 'the fixture stopped being a non-CAN bus, so this proves nothing',
    );
    expect(
      scheduler.fastModeEnabled,
      isTrue,
      reason:
          'nothing went wrong on this bus, so the scheduler flag is still set '
          '— which is exactly the state that used to read "Batching enabled"',
    );
    expect(scheduler.canBatch, isFalse);

    // And the screen says the provable thing.
    expect(find.text(enSingle), findsOneWidget);
    expect(
      find.text(enBatching),
      findsNothing,
      reason: 'a bus that cannot group was told the driver it was grouping',
    );

    await tester.runAsync(session.disconnect);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
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

    // Connect and poll for real, then park the polling loop while keeping the
    // connection. `stop()` ends the loop, not the session: the engine, the
    // client and the transport are all still live, so anything the UI routes
    // through them during a measured window below still reaches the wire and
    // is still counted. What stops is the one thing that would otherwise make
    // every count move on its own.
    await tester.runAsync(() async {
      expect(
        await session.connectForTest(transport, TransportKind.demo),
        isTrue,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await session.engine!.stop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(PollingModePill.pillKey),
      findsOneWidget,
      reason:
          'no snapshot was published, so the pill under test never rendered',
    );
    expect(
      transport.written,
      isNotEmpty,
      reason: 'nothing was ever written, so a count of zero proves nothing',
    );

    // The other branch of `busGroupsRequestsProvider`, on a real CAN session.
    // The dashboard above is watching it, so this read is the live value and
    // not the cold-read `false` the provider's own comment warns about.
    final scheduler = session.engine!.scheduler;
    expect(
      scheduler.canBatch,
      isTrue,
      reason:
          'the Demo bus is CAN and discovery has run, so if this is false the '
          'assertion below is true for the wrong reason',
    );
    expect(container.read(busGroupsRequestsProvider), scheduler.canBatch);
    expect(
      find.text(enBatching).evaluate().length +
          find.text(enBatched).evaluate().length,
      1,
      reason:
          'Demo on CAN may already have packed a Mode 01 command, so the '
          'pill reads Batched polling; permission without that record '
          'still reads Batching enabled. Either means the pill rendered.',
    );

    // Quiescence, and this one can fail. A window of real elapsed time with
    // nothing touched: parked, it adds nothing; running, the same window adds
    // dozens of commands, which is how the change's report proves this line is
    // a measurement and not a restatement of a stopped clock.
    final quiet = transport.written.length;
    await _realWindow(tester);
    expect(
      transport.written.length,
      quiet,
      reason:
          'the loop is still writing, so no later count could be attributed '
          'to a tap: ${transport.written.skip(quiet).toList()}',
    );

    final generation = session.connectionGeneration;
    final baseline = transport.written.length;

    await tester.tap(find.byKey(PollingModePill.pillKey));
    await _openHelpPump(tester);
    await _realWindow(tester);
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
    await _realWindow(tester);
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
      if (literals.contains('dashboardPollingModePill')) {
        sawAKnownLiteral = true;
      }
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
