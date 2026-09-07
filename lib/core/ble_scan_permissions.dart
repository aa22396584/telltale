/// The one version-aware Bluetooth permission rule, shared by every shell.
///
/// Extracted from the connect screen so the wear shell cannot grow a weaker
/// copy. The trap this encodes: `permission_handler` reports a request for a
/// permission the OS does not define as **granted**, so on Android 11 and
/// below the modern `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` requests succeed
/// vacuously while BLE scanning is actually gated behind location — skipping
/// the location request makes the scan return an empty list with no error,
/// which looks exactly like "no adapters nearby".
library;

import 'dart:io';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart'
    show FlutterClassicBluetooth;
import 'package:permission_handler/permission_handler.dart';

enum BlePermissionOutcome { granted, denied, permanentlyDenied }

/// Which permission was refused, as an identifier rather than a word.
///
/// This module is engine code: it decides what to ask the OS for, and it has no
/// `AppLocalizations` and no idea what language the reader has chosen. It used
/// to hand the screen a Traditional Chinese noun and the wear shell compared it
/// with `==` — an enum the compiler could not check, and a translation that
/// leaked into the English build. The screen names it now
/// (`lib/ui/wear/wear_permission_copy.dart`); this only says which one.
enum BlePermissionKind { bluetooth, location }

final class BlePermissionResult {
  /// Nothing was refused, so there is no permission to name.
  const BlePermissionResult.granted()
    : outcome = BlePermissionOutcome.granted,
      deniedKind = null;

  /// A refusal, and the permission it was. Both constructors are named because
  /// the pairing is the whole invariant: a grant that carried a [deniedKind]
  /// would let a screen say a permission was refused when it was not, and a
  /// refusal without one is what the old `?? '藍牙'` fallback papered over on
  /// the path where the answer was actually location.
  const BlePermissionResult.refused(this.outcome, BlePermissionKind kind)
    : deniedKind = kind,
      assert(
        outcome != BlePermissionOutcome.granted,
        'a granted result refuses nothing',
      );

  final BlePermissionOutcome outcome;

  /// Non-null exactly when [granted] is false. The field is nullable because
  /// a grant has nothing to put in it; [BlePermissionResult.refused] takes a
  /// non-nullable parameter rather than `this.deniedKind`, so `refused(…, null)`
  /// does not compile and there is no third way to build a result.
  final BlePermissionKind? deniedKind;

  bool get granted => outcome == BlePermissionOutcome.granted;
}

/// The first Android release with `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`.
const int _androidS = 31;

/// Acquires exactly the permissions the next action needs, and no others.
Future<BlePermissionResult> ensureBluetoothPermissions({
  required bool forScanning,
}) async {
  if (!Platform.isAndroid) {
    return const BlePermissionResult.granted();
  }

  final sdk = await FlutterClassicBluetooth().androidSdkInt();
  // Unknown means an Android where the plugin could not answer; assume the
  // modern behaviour rather than asking for location on a device that
  // declares `neverForLocation`.
  final modern = sdk == null || sdk >= _androidS;

  if (modern) {
    final results = await <Permission>[
      Permission.bluetoothConnect,
      if (forScanning) Permission.bluetoothScan,
    ].request();
    if (results.values.every((status) => status.isGranted)) {
      return const BlePermissionResult.granted();
    }
    // The user said no. Location is a different permission for a different
    // purpose and cannot substitute for this one.
    return BlePermissionResult.refused(
      results.values.any((status) => status.isPermanentlyDenied)
          ? BlePermissionOutcome.permanentlyDenied
          : BlePermissionOutcome.denied,
      BlePermissionKind.bluetooth,
    );
  }

  // Android 11 or below: `BLUETOOTH` and `BLUETOOTH_ADMIN` are install-time,
  // so a bonded adapter needs nothing further.
  if (!forScanning) {
    return const BlePermissionResult.granted();
  }

  // Only discovery is gated on location here, and declaring it in the
  // manifest is not enough — it is a runtime permission like any other.
  final location = await Permission.locationWhenInUse.request();
  if (location.isGranted || location.isLimited) {
    return const BlePermissionResult.granted();
  }
  return BlePermissionResult.refused(
    location.isPermanentlyDenied
        ? BlePermissionOutcome.permanentlyDenied
        : BlePermissionOutcome.denied,
    BlePermissionKind.location,
  );
}
