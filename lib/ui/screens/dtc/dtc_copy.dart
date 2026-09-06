/// Screen copy for the fault-code vocabulary.
///
/// `lib/obd/dtc/dtc.dart` is pure Dart with no Flutter in it, and it decodes
/// codes rather than describing them: it hands out a [DtcKind], a
/// [DtcCategory], a [PowertrainSubsystem] and a five-character code, all of
/// them stable identifiers that mean the same thing on every phone. The words
/// are here, one ARB entry per identifier.
///
/// These take an [AppLocalizations] rather than a [BuildContext], for the same
/// reason `telemetry_status_copy.dart` does: the fault-code screen is not the
/// only caller, a pure-Dart test can then walk every arm in both locales with
/// no widget pump, and nothing is tempted to reach for a global context.
///
/// The one rule that is not a lookup: **a code with no description shows the
/// raw code**. [dtcCodeDescription] returns null rather than a category name
/// dressed up as a description, and the screen says the description is
/// missing. An invented description for a fault somebody is about to spend
/// money on is the worst thing this file could produce.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/dtc/dtc.dart';

/// Stored / pending / permanent. Three classes that must stay three things.
String dtcKindLabel(AppLocalizations l10n, DtcKind kind) => switch (kind) {
  DtcKind.stored => l10n.dtcKindStored,
  DtcKind.pending => l10n.dtcKindPending,
  DtcKind.permanent => l10n.dtcKindPermanent,
};

/// What the class means to a driver, shown under the group header.
///
/// The permanent arm is the load-bearing one: a Mode 0A code is not something
/// the Clear button removes, and somebody who reads it as clearable will press
/// Clear, watch the other two classes disappear, and take the car to an
/// inspection it cannot pass.
String dtcKindExplanation(AppLocalizations l10n, DtcKind kind) =>
    switch (kind) {
      DtcKind.stored => l10n.dtcKindStoredExplanation,
      DtcKind.pending => l10n.dtcKindPendingExplanation,
      DtcKind.permanent => l10n.dtcKindPermanentExplanation,
    };

/// The system named by the code's letter. The letter itself is not translated.
String dtcSystemLabel(AppLocalizations l10n, DtcCategory category) =>
    switch (category) {
      DtcCategory.powertrain => l10n.dtcSystemPowertrain,
      DtcCategory.chassis => l10n.dtcSystemChassis,
      DtcCategory.body => l10n.dtcSystemBody,
      DtcCategory.network => l10n.dtcSystemNetwork,
    };

/// The SAE J2012 subsystem a `P0` code's third digit names.
String dtcSubsystemLabel(
  AppLocalizations l10n,
  PowertrainSubsystem subsystem,
) => switch (subsystem) {
  PowertrainSubsystem.fuelAirMeteringAndAuxiliaryEmissions =>
    l10n.dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions,
  PowertrainSubsystem.fuelAirMetering => l10n.dtcSubsystemFuelAirMetering,
  PowertrainSubsystem.fuelAirMeteringInjectorCircuit =>
    l10n.dtcSubsystemFuelAirMeteringInjectorCircuit,
  PowertrainSubsystem.ignitionOrMisfire => l10n.dtcSubsystemIgnitionOrMisfire,
  PowertrainSubsystem.auxiliaryEmissionControls =>
    l10n.dtcSubsystemAuxiliaryEmissionControls,
  PowertrainSubsystem.speedAndIdleControl =>
    l10n.dtcSubsystemSpeedAndIdleControl,
  PowertrainSubsystem.computerOutputCircuit =>
    l10n.dtcSubsystemComputerOutputCircuit,
  PowertrainSubsystem.transmission => l10n.dtcSubsystemTransmission,
  PowertrainSubsystem.controlModuleSignals =>
    l10n.dtcSubsystemControlModuleSignals,
};

/// The generic description for [dtc], or null when this app has none.
///
/// Null is a real answer and the caller must render it as one. The gate is
/// [Dtc.hasGenericDescription], which is false for every manufacturer range
/// whatever this table holds — a `P1xxx` means whatever the manufacturer says
/// it means.
///
/// The arms below must cover exactly [DtcDecoder.describedCodes];
/// `test/l10n/l04_dtc_l10n_test.dart` walks that set in both locales and fails
/// on the first code this switch cannot answer.
String? dtcCodeDescription(AppLocalizations l10n, Dtc dtc) {
  if (!dtc.hasGenericDescription) return null;
  return switch (dtc.code) {
    'B0001' => l10n.dtcDescriptionB0001,
    'P0011' => l10n.dtcDescriptionP0011,
    'P0014' => l10n.dtcDescriptionP0014,
    'P0016' => l10n.dtcDescriptionP0016,
    'P0087' => l10n.dtcDescriptionP0087,
    'P0088' => l10n.dtcDescriptionP0088,
    'P0100' => l10n.dtcDescriptionP0100,
    'P0101' => l10n.dtcDescriptionP0101,
    'P0102' => l10n.dtcDescriptionP0102,
    'P0103' => l10n.dtcDescriptionP0103,
    'P0105' => l10n.dtcDescriptionP0105,
    'P0106' => l10n.dtcDescriptionP0106,
    'P0107' => l10n.dtcDescriptionP0107,
    'P0108' => l10n.dtcDescriptionP0108,
    'P0110' => l10n.dtcDescriptionP0110,
    'P0111' => l10n.dtcDescriptionP0111,
    'P0112' => l10n.dtcDescriptionP0112,
    'P0113' => l10n.dtcDescriptionP0113,
    'P0115' => l10n.dtcDescriptionP0115,
    'P0116' => l10n.dtcDescriptionP0116,
    'P0117' => l10n.dtcDescriptionP0117,
    'P0118' => l10n.dtcDescriptionP0118,
    'P0120' => l10n.dtcDescriptionP0120,
    'P0121' => l10n.dtcDescriptionP0121,
    'P0122' => l10n.dtcDescriptionP0122,
    'P0123' => l10n.dtcDescriptionP0123,
    'P0125' => l10n.dtcDescriptionP0125,
    'P0128' => l10n.dtcDescriptionP0128,
    'P0130' => l10n.dtcDescriptionP0130,
    'P0131' => l10n.dtcDescriptionP0131,
    'P0132' => l10n.dtcDescriptionP0132,
    'P0133' => l10n.dtcDescriptionP0133,
    'P0134' => l10n.dtcDescriptionP0134,
    'P0135' => l10n.dtcDescriptionP0135,
    'P0136' => l10n.dtcDescriptionP0136,
    'P0137' => l10n.dtcDescriptionP0137,
    'P0138' => l10n.dtcDescriptionP0138,
    'P0140' => l10n.dtcDescriptionP0140,
    'P0141' => l10n.dtcDescriptionP0141,
    'P0150' => l10n.dtcDescriptionP0150,
    'P0155' => l10n.dtcDescriptionP0155,
    'P0156' => l10n.dtcDescriptionP0156,
    'P0161' => l10n.dtcDescriptionP0161,
    'P0170' => l10n.dtcDescriptionP0170,
    'P0171' => l10n.dtcDescriptionP0171,
    'P0172' => l10n.dtcDescriptionP0172,
    'P0173' => l10n.dtcDescriptionP0173,
    'P0174' => l10n.dtcDescriptionP0174,
    'P0175' => l10n.dtcDescriptionP0175,
    'P0190' => l10n.dtcDescriptionP0190,
    'P0201' => l10n.dtcDescriptionP0201,
    'P0202' => l10n.dtcDescriptionP0202,
    'P0203' => l10n.dtcDescriptionP0203,
    'P0204' => l10n.dtcDescriptionP0204,
    'P0217' => l10n.dtcDescriptionP0217,
    'P0221' => l10n.dtcDescriptionP0221,
    'P0222' => l10n.dtcDescriptionP0222,
    'P0223' => l10n.dtcDescriptionP0223,
    'P0234' => l10n.dtcDescriptionP0234,
    'P0299' => l10n.dtcDescriptionP0299,
    'P0300' => l10n.dtcDescriptionP0300,
    'P0301' => l10n.dtcDescriptionP0301,
    'P0302' => l10n.dtcDescriptionP0302,
    'P0303' => l10n.dtcDescriptionP0303,
    'P0304' => l10n.dtcDescriptionP0304,
    'P0305' => l10n.dtcDescriptionP0305,
    'P0306' => l10n.dtcDescriptionP0306,
    'P0307' => l10n.dtcDescriptionP0307,
    'P0308' => l10n.dtcDescriptionP0308,
    'P0316' => l10n.dtcDescriptionP0316,
    'P0325' => l10n.dtcDescriptionP0325,
    'P0326' => l10n.dtcDescriptionP0326,
    'P0327' => l10n.dtcDescriptionP0327,
    'P0328' => l10n.dtcDescriptionP0328,
    'P0330' => l10n.dtcDescriptionP0330,
    'P0335' => l10n.dtcDescriptionP0335,
    'P0336' => l10n.dtcDescriptionP0336,
    'P0340' => l10n.dtcDescriptionP0340,
    'P0341' => l10n.dtcDescriptionP0341,
    'P0351' => l10n.dtcDescriptionP0351,
    'P0352' => l10n.dtcDescriptionP0352,
    'P0353' => l10n.dtcDescriptionP0353,
    'P0354' => l10n.dtcDescriptionP0354,
    'P0355' => l10n.dtcDescriptionP0355,
    'P0356' => l10n.dtcDescriptionP0356,
    'P0400' => l10n.dtcDescriptionP0400,
    'P0401' => l10n.dtcDescriptionP0401,
    'P0402' => l10n.dtcDescriptionP0402,
    'P0403' => l10n.dtcDescriptionP0403,
    'P0404' => l10n.dtcDescriptionP0404,
    'P0410' => l10n.dtcDescriptionP0410,
    'P0411' => l10n.dtcDescriptionP0411,
    'P0412' => l10n.dtcDescriptionP0412,
    'P0420' => l10n.dtcDescriptionP0420,
    'P0430' => l10n.dtcDescriptionP0430,
    'P0440' => l10n.dtcDescriptionP0440,
    'P0441' => l10n.dtcDescriptionP0441,
    'P0442' => l10n.dtcDescriptionP0442,
    'P0443' => l10n.dtcDescriptionP0443,
    'P0446' => l10n.dtcDescriptionP0446,
    'P0447' => l10n.dtcDescriptionP0447,
    'P0449' => l10n.dtcDescriptionP0449,
    'P0451' => l10n.dtcDescriptionP0451,
    'P0452' => l10n.dtcDescriptionP0452,
    'P0453' => l10n.dtcDescriptionP0453,
    'P0455' => l10n.dtcDescriptionP0455,
    'P0456' => l10n.dtcDescriptionP0456,
    'P0480' => l10n.dtcDescriptionP0480,
    'P0500' => l10n.dtcDescriptionP0500,
    'P0505' => l10n.dtcDescriptionP0505,
    'P0506' => l10n.dtcDescriptionP0506,
    'P0507' => l10n.dtcDescriptionP0507,
    'P0508' => l10n.dtcDescriptionP0508,
    'P0509' => l10n.dtcDescriptionP0509,
    'P0560' => l10n.dtcDescriptionP0560,
    'P0562' => l10n.dtcDescriptionP0562,
    'P0563' => l10n.dtcDescriptionP0563,
    'P0603' => l10n.dtcDescriptionP0603,
    'P0605' => l10n.dtcDescriptionP0605,
    'P0606' => l10n.dtcDescriptionP0606,
    'P0700' => l10n.dtcDescriptionP0700,
    'P0701' => l10n.dtcDescriptionP0701,
    'P0702' => l10n.dtcDescriptionP0702,
    'P0705' => l10n.dtcDescriptionP0705,
    'P0715' => l10n.dtcDescriptionP0715,
    'P0720' => l10n.dtcDescriptionP0720,
    'P0730' => l10n.dtcDescriptionP0730,
    'P0740' => l10n.dtcDescriptionP0740,
    'P0741' => l10n.dtcDescriptionP0741,
    'P0750' => l10n.dtcDescriptionP0750,
    'P0755' => l10n.dtcDescriptionP0755,
    'P2135' => l10n.dtcDescriptionP2135,
    'U0100' => l10n.dtcDescriptionU0100,
    'U0101' => l10n.dtcDescriptionU0101,
    'U0121' => l10n.dtcDescriptionU0121,
    'U0140' => l10n.dtcDescriptionU0140,
    'U0155' => l10n.dtcDescriptionU0155,
    // Unreachable while the switch covers `describedCodes`, and the test above
    // is what keeps that true. Null rather than a guess if it ever is not.
    _ => null,
  };
}
