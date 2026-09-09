import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/state/pid_mutation_lock.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'support/localized_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PID manager scrolls without overflow in 200% landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(832, 384);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedMaterialApp(
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: PidManagerScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomScrollView), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsWidgets);

    await tester.enterText(find.byType(TextField), 'definitely-no-such-pid');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('沒有符合的 PID'));
    await tester.pump();
    expect(find.text('換個關鍵字，或建立一個自訂 PID。'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('recording lock refuses dashboard toggle with visible feedback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final before = List.of(container.read(activePidsProvider));
    final token = container
        .read(pidMutationLockProvider)
        .tryAcquire('recording')!;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedMaterialApp(home: const PidManagerScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(container.read(activePidsProvider), before);
    expect(find.text('請先停止並儲存'), findsOneWidget);

    container.read(pidMutationLockProvider).release(token);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('recording lock refuses a reorder, and says so', (tester) async {
    // The seventh render site, and the one nothing drove. A reviewer mutated
    // each of the seven in turn: six died naming the test that guards them,
    // and this one survived with zero failures — the mutant compiled clean, so
    // the survival was real and not a build artifact.
    //
    // The census in l05_battery_refusal_guard_test.dart notices if the CALL
    // disappears. It cannot notice that nothing ever exercised the path, which
    // is a different question and this is its answer. The only test that
    // touched reorder-under-lock was at the notifier layer
    // (telemetry_configuration_lock_test.dart), which never pumps this sheet.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final before = List.of(container.read(activePidsProvider));
    expect(before.length, greaterThan(1),
        reason: 'a reorder needs two rows to move between');
    final token =
        container.read(pidMutationLockProvider).tryAcquire('recording')!;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedMaterialApp(home: const PidManagerScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open the arrange sheet through the menu, the way a person reaches it.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.reorder).last);
    await tester.pumpAndSettle();
    expect(find.byType(ReorderableListView), findsOneWidget,
        reason: 'the arrange sheet did not open, so nothing below is a test');

    // Drag the first handle down past the second row.
    // Moved in steps rather than one jump, and with no long-press pump:
    // `ReorderableDragStartListener` starts on pointer down, and a single
    // large `moveBy` did not reorder at all. Verified against the unlocked
    // path first — without the lock this same gesture moves the first row
    // past the next two, so a green result here cannot mean "the drag did
    // nothing".
    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // Refused, and the order is unchanged — a message with the reorder applied
    // anyway would be worse than either.
    expect(container.read(activePidsProvider), before);
    expect(find.text('請先停止並儲存'), findsOneWidget,
        reason: 'the refusal must be shown, not only enforced');

    // Same teardown as the toggle test above: the telemetry provider holds a
    // periodic timer, and the binding's invariant check fails on it otherwise.
    container.read(pidMutationLockProvider).release(token);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets(
    'overflow menu offers Telltale export and Torque subset separately',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localizedMaterialApp(home: const PidManagerScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();

      expect(find.text('匯出自訂 PID'), findsOneWidget);
      expect(find.text('匯出 Torque 相容 CSV'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
    },
  );
}
