/// Shipped copy for the vehicle-profile vocabulary in `lib/obd/physics`.
///
/// [FuelType] and [Drivetrain] each carried a `label` in Traditional Chinese,
/// which the settings screen rendered directly — so an English reader picking a
/// fuel chose between 汽油, 柴油, 液化石油氣 (LPG) and E85 酒精汽油.
///
/// The enums kept a Chinese word because the telemetry export needs one and
/// must go on needing one: an evidence file whose wording follows a phone
/// setting is one that two people cannot compare. That word is now called
/// `exportLabel` and is documented as export-only; these are the words for a
/// screen. `test/l10n/export_labels_stay_off_screen_test.dart` fails if
/// `exportLabel` is ever referenced from `lib/ui` again.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/physics/vehicle_profile.dart';

String fuelTypeLabel(AppLocalizations l10n, FuelType fuel) => switch (fuel) {
  FuelType.gasoline => l10n.fuelTypeGasoline,
  FuelType.diesel => l10n.fuelTypeDiesel,
  FuelType.lpg => l10n.fuelTypeLpg,
  FuelType.ethanolE85 => l10n.fuelTypeEthanolE85,
};

String drivetrainLabel(AppLocalizations l10n, Drivetrain drivetrain) =>
    switch (drivetrain) {
      Drivetrain.fwd => l10n.drivetrainFwd,
      Drivetrain.rwd => l10n.drivetrainRwd,
      Drivetrain.awd => l10n.drivetrainAwd,
    };
