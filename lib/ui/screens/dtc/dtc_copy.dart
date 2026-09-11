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
import '../../../state/dtc_scan.dart';
import '../settings/manual_command_copy.dart';

/// Why a scan that produced no results is showing, in the reader's language.
String? dtcScanBannerText(AppLocalizations l10n, DtcScanBanner? banner) =>
    switch (banner) {
      null => null,
      DtcScanBanner.interrupted => l10n.dtcScanInterrupted,
      DtcScanBanner.disconnectedMidScan => l10n.dtcScanDisconnectedMidScan,
    };

/// What the last clear did, in the reader's language.
///
/// [DtcReadException.message] is Traditional Chinese and stays that way for
/// the transcript. This function must not render it.
String? dtcClearNoticeText(AppLocalizations l10n, DtcClearNotice? notice) {
  if (notice == null) return null;
  return switch (notice.kind) {
    DtcClearNoticeKind.confirmed => l10n.dtcClearConfirmed,
    DtcClearNoticeKind.partiallyConfirmed => l10n.dtcClearPartiallyConfirmed,
    DtcClearNoticeKind.sentUnconfirmed => l10n.dtcClearSentUnconfirmed,
    DtcClearNoticeKind.notAccepted => l10n.dtcClearNotAccepted,
    DtcClearNoticeKind.timeout => l10n.dtcClearTimeout,
    DtcClearNoticeKind.cancelledBeforeSend => l10n.dtcClearCancelledBeforeSend,
    DtcClearNoticeKind.unexpected => l10n.dtcClearUnexpected,
    DtcClearNoticeKind.previousConnectionUnconfirmed =>
      l10n.dtcClearPreviousConnectionUnconfirmed,
    DtcClearNoticeKind.rescanSettled => l10n.dtcClearRescanSettled,
    DtcClearNoticeKind.engineFailure => _clearEngineFailureText(l10n, notice),
  };
}

/// Category-panel failure copy. [DtcReadException.message] stays on the
/// transcript; the screen maps transport identifiers, structured counts, or
/// [DtcReadException.kind] and never interpolates the engine sentence.
String dtcCategoryFailureText(AppLocalizations l10n, DtcReadException failure) {
  final issue = failure.transportIssue;
  if (issue != null) {
    return commandIssueText(l10n, issue, detail: failure.issueDetail) ??
        l10n.dtcCategoryError;
  }
  // Same priority the engine uses when it composes the transcript sentence:
  // a named silence, an unresolvable identity, a refusal, a pending wait,
  // then an unreadable reply. Kind is the fallback when none of those
  // counts were carried.
  final silent = _namedSources(failure.silentSources);
  if (silent.isNotEmpty) {
    return l10n.dtcCategorySilentControllers(
      silent.length,
      _controllerList(silent),
    );
  }
  final unresolved = _namedSources(failure.unresolvedSources);
  if (unresolved.isNotEmpty) {
    return l10n.dtcCategoryUnresolvedSources(
      unresolved.length,
      _controllerList(unresolved),
    );
  }
  if (failure.refusedCount > 0) {
    return l10n.dtcCategoryRefusedControllers(
      failure.refusedCount,
      failure.answeredCount,
    );
  }
  final pending = _namedSources(failure.pendingSources);
  if (pending.isNotEmpty) {
    return l10n.dtcCategoryPendingControllers(
      pending.length,
      failure.answeredCount,
    );
  }
  if (failure.pendingSources.isNotEmpty) {
    // Headerless `7F xx 78` is stored as `''`. That is not one named
    // controller, and counting it as 1 invented a coverage number.
    return l10n.dtcCategoryPending;
  }
  if (failure.unrecognisedCount > 0) {
    return l10n.dtcCategoryUnrecognisedResponses(
      failure.unrecognisedCount,
      failure.answeredCount,
    );
  }
  final mil = _namedSources(failure.milDisagreementSources);
  if (mil.isNotEmpty) {
    if (mil.length == 1 &&
        failure.milClaimedCount > failure.milObservedCount) {
      return l10n.dtcCategoryMilCountMismatch(
        _controllerList(mil),
        failure.milClaimedCount,
        failure.milObservedCount,
      );
    }
    if (mil.length == 1 && failure.milObservedCount == 0) {
      return l10n.dtcCategoryMilLitNoCodes(_controllerList(mil));
    }
    return l10n.dtcCategoryMilDisagreement(_controllerList(mil));
  }
  return switch (failure.kind) {
    DtcReadFailure.noAnswer => l10n.dtcCategoryNoAnswer,
    DtcReadFailure.error => l10n.dtcCategoryError,
    DtcReadFailure.disconnected => l10n.dtcCategoryDisconnected,
    DtcReadFailure.pending => l10n.dtcCategoryPending,
    DtcReadFailure.unattributed => l10n.dtcCategoryUnattributed,
  };
}

String _clearEngineFailureText(AppLocalizations l10n, DtcClearNotice notice) {
  final failure = notice.failure;
  if (failure == null) return l10n.dtcClearFailureGeneric;
  final issue = failure.transportIssue;
  if (issue != null) {
    return commandIssueText(l10n, issue, detail: failure.issueDetail) ??
        (failure.repeatWouldHarm
            ? l10n.dtcClearFailureDoNotRepeat
            : l10n.dtcClearFailureGeneric);
  }
  final nrc = failure.negativeResponseCode;
  if (nrc != null) {
    final controller = failure.issueDetail ?? '';
    final harm = failure.repeatWouldHarm;
    final code = '0x${nrc.toRadixString(16).toUpperCase().padLeft(2, '0')}';
    return switch (nrc) {
      0x22 =>
        harm
            ? l10n.dtcClearNrcConditionsDoNotRepeat(controller)
            : l10n.dtcClearNrcConditions(controller),
      0x11 || 0x12 =>
        harm
            ? l10n.dtcClearNrcUnsupportedDoNotRepeat(controller)
            : l10n.dtcClearNrcUnsupported(controller),
      0x21 =>
        harm
            ? l10n.dtcClearNrcBusyDoNotRepeat(controller)
            : l10n.dtcClearNrcBusy(controller),
      0x33 =>
        harm
            ? l10n.dtcClearNrcSecurityDoNotRepeat(controller)
            : l10n.dtcClearNrcSecurity(controller),
      _ =>
        harm
            ? l10n.dtcClearNrcOtherDoNotRepeat(controller, code)
            : l10n.dtcClearNrcOther(controller, code),
    };
  }
  if (failure.silentSources.isNotEmpty) {
    return l10n.dtcClearSilentControllers(
      failure.silentSources.length,
      _controllerList(failure.silentSources),
    );
  }
  if (failure.unresolvedSources.isNotEmpty) {
    return failure.repeatWouldHarm
        ? l10n.dtcClearUnresolvedSourcesDoNotRepeat(
            failure.unresolvedSources.length,
            _controllerList(failure.unresolvedSources),
          )
        : l10n.dtcClearUnresolvedSources(
            failure.unresolvedSources.length,
            _controllerList(failure.unresolvedSources),
          );
  }
  return failure.repeatWouldHarm
      ? l10n.dtcClearFailureDoNotRepeat
      : l10n.dtcClearFailureGeneric;
}

/// Source ids in a stable, screen-safe list. Empty tokens are dropped: a
/// headerless pending frame is stored as `''` and must not punch a hole in
/// the sentence.
String _controllerList(Set<String> ids) {
  final names = _namedSources(ids).toList()..sort();
  return names.join(', ');
}

Set<String> _namedSources(Set<String> ids) => {
      for (final id in ids)
        if (id.isNotEmpty) id,
    };

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
