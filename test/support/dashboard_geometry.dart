/// Renders `DashboardScreen` at a chosen viewport and reports what layout
/// complained.
///
/// Separate from `dashboard_harness.dart` because that harness pins one locale
/// and one text scale on purpose, and a geometry check has to vary both.
///
/// Two harness facts this file exists to encode, both of which cost an hour to
/// rediscover:
///
///   * `pumpAndSettle` cannot be used on this screen. The status strip's live
///     dot repeats for as long as the session is connected, so settling can
///     only ever time out.
///   * a `RenderFlex` reports its overflow **once per render object, ever**.
///     `tester.takeException()` holds one exception at a time, so a second
///     `pumpWidget` into the same element tree reports nothing and a check
///     built on it reads "no error" where the layout is unchanged. Collecting
///     from `FlutterError.onError` is what makes the answer complete, and
///     rendering once per test is what makes the render objects new.
///
/// The keys are typed here rather than read from the widgets that carry them.
/// A test that imports the identifier it is checking agrees with whatever the
/// widget currently says.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';

import 'dashboard_harness.dart' show liveReading;
import 'localized_app.dart';

const englishLocale = Locale('en');
const chineseLocale = testUiLocale;

/// The workspace switcher, the recordings button, and the sentence that
/// explains why the button is disabled.
const workspaceSwitchKey = ValueKey('dashboard-workspace-switch');
const historyButtonKey = ValueKey('telemetry-history');
const historyBlockedCopyKey = ValueKey('telemetry-history-blocked-copy');

/// One gauge on the wall, and the readings the derived figures need.
///
/// With no active PIDs the gauge area is an empty state and the derived strip
/// refuses to compute, so a geometry rendered that way never lays out a dial,
/// a tile footnote or a derived cell. Acceleration is supplied because the
/// strip gates every derived number behind it.
final gaugePids = <Pid>[PidLibrary.engineRpm, PidLibrary.vehicleSpeed];

TelemetrySnapshot gaugeSnapshot() => TelemetrySnapshot(
  readings: {
    PidLibrary.engineRpm.id: liveReading(PidLibrary.engineRpm, 2000),
    PidLibrary.vehicleSpeed.id: liveReading(PidLibrary.vehicleSpeed, 60),
    PidLibrary.mafRate.id: liveReading(PidLibrary.mafRate, 12.5),
  },
  accelerationMs2: 1.2,
  pidsPerSecond: 12,
  capturedAt: DateTime.now(),
);

class _FixedActivePids extends ActivePids {
  _FixedActivePids(this._pids);
  final List<Pid> _pids;

  @override
  List<Pid> build() => _pids;
}

class _FixedProfile extends VehicleProfileController {
  @override
  VehicleProfile build() => const VehicleProfile();
}

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Demo ECU',
  );
}

/// Every render-time error raised while the dashboard is mounted, in order.
///
/// Call once per test. The tree is left mounted so the caller can measure it.
Future<List<String>> renderDashboardErrors(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required Locale locale,
  List<Pid> activePids = const [],
  TelemetrySnapshot? snapshot,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.exceptionAsString());
  try {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          obdSessionProvider.overrideWith(_ConnectedSession.new),
          activePidsProvider.overrideWith(() => _FixedActivePids(activePids)),
          vehicleProfileProvider.overrideWith(_FixedProfile.new),
          // A snapshot that has been through a poll, so the strip renders the
          // pills a live session shows rather than its first-frame state.
          telemetryProvider.overrideWith(
            (ref) => Stream.value(
              snapshot ??
                  TelemetrySnapshot(
                    pidsPerSecond: 12,
                    capturedAt: DateTime.now(),
                  ),
            ),
          ),
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
    // Long enough for the tiles' staggered entrance, which is what an
    // unsettled frame would otherwise hide from the finders.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// The state the screen has to be in for the toolbar defect to be reachable.
///
/// The overflow was the refusal sentence claiming unbounded width inside a
/// `Row`. If a future harness change let the recordings button through
/// unblocked, that sentence would not render and every geometry below would
/// pass without laying out the shape that broke. Asserted per case rather than
/// once, because the sentence is gated by a provider each case rebuilds.
void expectOverflowShapeRendered(WidgetTester tester, {required String at}) {
  expect(
    find.byType(DashboardScreen),
    findsOneWidget,
    reason: 'the dashboard did not mount at $at',
  );
  expect(
    find.byKey(historyBlockedCopyKey),
    findsOneWidget,
    reason:
        'the refusal sentence is absent at $at, so this case no longer '
        'renders the shape that overflowed',
  );
}

/// Asserts the toolbar took its side-by-side branch.
///
/// The branch matters because it is the one that overflowed: stacked, the
/// switcher and the recordings column each get the full width and nothing can
/// claim more than there is. Without this, widening the toolbar's stacking
/// threshold would send every case below down the stacked path and leave a
/// green suite that never lays out a `Row`.
void expectSideBySide(WidgetTester tester, {required String at}) {
  final switcher = tester.getRect(find.byKey(workspaceSwitchKey));
  final button = tester.getRect(find.byKey(historyButtonKey));
  expect(
    switcher.right,
    lessThanOrEqualTo(button.left),
    reason: 'the toolbar stacked at $at, so no Row was laid out here',
  );
}
