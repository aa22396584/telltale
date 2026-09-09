/// Persist-first custom PID commits: SharedPreferences reports `false`,
/// not an exception. Applying memory first then ignoring that bool is how a
/// definition can look saved until the next launch.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/state/pid_mutation_lock.dart';
import 'package:torque_obd/state/pid_registry.dart';

const _existing = Pid(
  name: 'Keep me',
  shortName: 'Keep',
  modeAndPid: '010C',
  equation: '((A*256)+B)/4',
  minValue: 0,
  maxValue: 8000,
  units: 'rpm',
  header: kDefaultHeader,
  isCustom: true,
);

const _incoming = Pid(
  name: 'New rpm',
  shortName: 'RPM',
  modeAndPid: '010D',
  equation: 'A',
  minValue: 0,
  maxValue: 240,
  units: 'km/h',
  header: kDefaultHeader,
  isCustom: true,
);

Future<ProviderContainer> _rejectingContainer({Pid? seed}) async {
  SharedPreferences.setMockInitialValues({
    if (seed != null) 'custom_pids_v1': [jsonEncode(seed.toJson())],
  });
  final seeded = await SharedPreferencesStorePlatform.instance.getAll();
  SharedPreferencesStorePlatform.instance = _RejectingWritesStore.withData(
    seeded,
  );
  SharedPreferences.resetStatic();
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'upsertAllCustom does not keep a PID when persist reports false',
    () async {
      final container = await _rejectingContainer();
      addTearDown(container.dispose);
      final registry = container.read(pidRegistryProvider.notifier);

      final outcome = await registry.upsertAllCustom([_incoming]);

      expect(outcome.failure, PidMutationFailure.persistFailed);
      expect(outcome.inserted, 0);
      expect(outcome.replaced, 0);
      expect(
        container.read(pidRegistryProvider).where((pid) => pid.isCustom),
        isEmpty,
      );
    },
  );

  test(
    'replaceCustom leaves the original definition when persist reports false',
    () async {
      final container = await _rejectingContainer(seed: _existing);
      addTearDown(container.dispose);
      final registry = container.read(pidRegistryProvider.notifier);

      final outcome = await registry.replaceCustom(
        _existing,
        _existing.copyWith(equation: 'A'),
      );

      expect(outcome.failure, PidMutationFailure.persistFailed);
      expect(outcome.applied, isFalse);
      final stored = container
          .read(pidRegistryProvider)
          .where((pid) => pid.isCustom)
          .toList();
      expect(stored, hasLength(1));
      expect(stored.single.equation, '((A*256)+B)/4');
    },
  );

  test(
    'removeCustom keeps the definition when persist reports false',
    () async {
      final container = await _rejectingContainer(seed: _existing);
      addTearDown(container.dispose);
      final registry = container.read(pidRegistryProvider.notifier);

      final outcome = await registry.removeCustom(_existing);

      expect(outcome.failure, PidMutationFailure.persistFailed);
      expect(outcome.applied, isFalse);
      expect(
        container
            .read(pidRegistryProvider)
            .where((pid) => pid.isCustom)
            .map((pid) => pid.id),
        [_existing.id],
      );
    },
  );
}

/// Reads succeed from the seeded map; every write reports false and is dropped.
final class _RejectingWritesStore extends InMemorySharedPreferencesStore {
  _RejectingWritesStore.withData(super.data) : super.withData();

  @override
  bool get isMock => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
