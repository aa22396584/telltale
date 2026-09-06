/// What each emissions readiness monitor is called on its chip.
///
/// [ReadinessMonitor] is engine code: lib/obd is pure Dart with no Flutter and
/// no `AppLocalizations`, so it decodes bytes B, C and D of `41 01` and holds
/// which monitor each bit is. The words come from here.
///
/// An [AppLocalizations] parameter rather than a [BuildContext], following
/// lib/ui/widgets/telemetry/telemetry_status_copy.dart, so a pure-Dart test can
/// walk all sixteen values in both languages with no widget pump.
///
/// The monitor's **state** is not localized and is not meant to be. A chip
/// draws `✓` complete, `…` unfinished and `—` this vehicle does not have this
/// monitor, and docs/field-guide.zh-TW.md:239 is the published legend for those
/// three marks. The distinction that must never blur is between the last two:
/// unsupported says the car has no such monitor, unfinished says it has one and
/// has not finished it, and rendering the first as the second makes a ready
/// vehicle look unready.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/readiness.dart';

/// The chip label for one monitor.
///
/// The names are the SAE J1979 ones. [ReadinessMonitor.gasolineParticulateFilter]
/// is the one to be careful with: many OBD reference tables name that bit an
/// air-conditioning refrigerant monitor, which is wrong, and the label keeps GPF
/// spelled out in both languages so nobody reconciles an inspection report
/// against a system their car does not have
/// (docs/field-guide.zh-TW.md:247-250).
String readinessMonitorLabel(AppLocalizations l10n, ReadinessMonitor monitor) =>
    switch (monitor) {
      ReadinessMonitor.misfire => l10n.dtcMonitorMisfire,
      ReadinessMonitor.fuelSystem => l10n.dtcMonitorFuelSystem,
      ReadinessMonitor.components => l10n.dtcMonitorComponents,
      ReadinessMonitor.catalyst => l10n.dtcMonitorCatalyst,
      ReadinessMonitor.heatedCatalyst => l10n.dtcMonitorHeatedCatalyst,
      ReadinessMonitor.evaporative => l10n.dtcMonitorEvaporative,
      ReadinessMonitor.secondaryAir => l10n.dtcMonitorSecondaryAir,
      ReadinessMonitor.gasolineParticulateFilter =>
        l10n.dtcMonitorGasolineParticulateFilter,
      ReadinessMonitor.oxygenSensor => l10n.dtcMonitorOxygenSensor,
      ReadinessMonitor.oxygenSensorHeater => l10n.dtcMonitorOxygenSensorHeater,
      ReadinessMonitor.egr => l10n.dtcMonitorEgr,
      ReadinessMonitor.nmhcCatalyst => l10n.dtcMonitorNmhcCatalyst,
      ReadinessMonitor.noxAftertreatment => l10n.dtcMonitorNoxAftertreatment,
      ReadinessMonitor.boostPressure => l10n.dtcMonitorBoostPressure,
      ReadinessMonitor.exhaustSensor => l10n.dtcMonitorExhaustSensor,
      ReadinessMonitor.particulateFilter => l10n.dtcMonitorParticulateFilter,
    };
