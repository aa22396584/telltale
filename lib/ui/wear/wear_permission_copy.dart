/// What the two Bluetooth-scan permissions are called on screen.
///
/// [BlePermissionKind] is engine code: `lib/core/ble_scan_permissions.dart`
/// decides what to ask Android for, and it holds the identity of a permission
/// and nothing a driver reads. It used to hold the word itself — a Traditional
/// Chinese noun that the wear shell compared with `==` to choose between two
/// ARB entries. That is an enum the compiler cannot check, and interpolating it
/// straight into a sentence had already put 「藍牙」 inside the English build.
///
/// An `AppLocalizations` parameter rather than a `BuildContext`, following
/// lib/ui/screens/connect/transport_kind_copy.dart: a pure function, so a test
/// can walk both values in both languages with `lookupAppLocalizations(...)`
/// and no widget pump.
library;

import '../../core/ble_scan_permissions.dart';
import '../../l10n/generated/app_localizations.dart';

/// The permission's name, for the sentence that says which one was refused.
///
/// The switch is exhaustive on purpose: a third permission cannot be added to
/// [BlePermissionKind] without the compiler asking what it is called here,
/// which is the part the old string comparison got to skip.
String blePermissionName(AppLocalizations l10n, BlePermissionKind kind) =>
    switch (kind) {
      BlePermissionKind.bluetooth => l10n.wearPermissionBluetooth,
      BlePermissionKind.location => l10n.wearPermissionLocation,
    };
