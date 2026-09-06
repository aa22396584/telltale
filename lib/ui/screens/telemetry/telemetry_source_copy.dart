/// Shipped copy for [TelemetrySource].
///
/// A recorded session's source is the first thing the history list says about
/// it, and it is the one line that decides whether the rest of the row is
/// evidence about a vehicle or about a simulation. Getting it wrong is the
/// project's defining failure: a reading that looks plausible and is not real.
///
/// It lived as `telemetrySourceLabel(TelemetrySource)` in `lib/state`, written
/// in Traditional Chinese, so the English build's session list read 「內建模擬」.
/// It is display copy, it reaches no export — `TelemetrySessionExporter` writes
/// the enum name, not this — so it belongs here, keyed, taking an
/// [AppLocalizations] rather than a [BuildContext] so a pure-Dart test can
/// assert both languages.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../telemetry/session/telemetry_session.dart';

String telemetrySourceLabel(AppLocalizations l10n, TelemetrySource source) =>
    switch (source) {
      TelemetrySource.demo => l10n.telemetrySourceDemo,
      TelemetrySource.simulatedRig => l10n.telemetrySourceRig,
      TelemetrySource.fieldAppConnection => l10n.telemetrySourceFieldApp,
    };
