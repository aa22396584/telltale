/// Visible copy for [ConnectionLayerReport] rows.
///
/// Identifiers stay in [ConnectionLayerValue]. This file only answers in the
/// driver's language. Do not put [TransportKind.label] on the screen.
library;

import '../../../diagnostics/connection_layers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/addressing.dart';

String connectionLayerTitle(AppLocalizations l10n, ConnectionLayerKind kind) =>
    switch (kind) {
      ConnectionLayerKind.transport => l10n.connectionLayerTransport,
      ConnectionLayerKind.protocol => l10n.connectionLayerProtocol,
      ConnectionLayerKind.ecu => l10n.connectionLayerEcu,
      ConnectionLayerKind.evidence => l10n.connectionLayerEvidence,
    };

String? connectionLayerProtocolDetail(
  AppLocalizations l10n,
  ConnectionLayerReport report,
) {
  if (report.kwpInit == KwpInit.unknown) {
    return l10n.connectionLayerKwpSubtypeUnknown;
  }
  if (report.requestedProtocol.isEmpty || report.observedProtocol.isEmpty) {
    return null;
  }
  if (report.requestedProtocol == report.observedProtocol) return null;
  return l10n.connectionLayerRequestedObserved(
    report.requestedProtocol,
    report.observedProtocol,
  );
}

String connectionLayerValueText(
  AppLocalizations l10n,
  ConnectionLayerValue value,
) => switch (value) {
  ConnectionLayerValue.unknown => l10n.connectionLayerUnknown,
  ConnectionLayerValue.notObserved => l10n.connectionLayerNotObserved,
  ConnectionLayerValue.observed => l10n.connectionLayerObserved,
  ConnectionLayerValue.answered => l10n.connectionLayerAnswered,
  ConnectionLayerValue.demo => l10n.connectionLayerDemo,
  ConnectionLayerValue.ble => l10n.connectionLayerBle,
  ConnectionLayerValue.classic => l10n.connectionLayerClassic,
  ConnectionLayerValue.wifi => l10n.connectionLayerWifi,
  ConnectionLayerValue.software => l10n.connectionLayerSoftware,
  ConnectionLayerValue.unsupported ||
  ConnectionLayerValue.connected ||
  ConnectionLayerValue.field => l10n.connectionLayerUnknown,
};

/// Four rows, one line each, for a pasteable diagnostic summary.
///
/// Titles and values are the same strings the panel shows. Requested vs
/// observed stays on the protocol line when the two differ.
String connectionLayerSummary(
  AppLocalizations l10n,
  ConnectionLayerReport report,
) {
  String line(
    ConnectionLayerKind kind,
    ConnectionLayerValue value, {
    String? detail,
  }) =>
      '${connectionLayerTitle(l10n, kind)}\t'
      '${detail ?? connectionLayerValueText(l10n, value)}';
  return [
    line(ConnectionLayerKind.transport, report.transport),
    line(
      ConnectionLayerKind.protocol,
      report.protocol,
      detail: connectionLayerProtocolDetail(l10n, report),
    ),
    line(ConnectionLayerKind.ecu, report.ecu),
    line(ConnectionLayerKind.evidence, report.evidence),
  ].join('\n');
}
