/// Visible copy for [ConnectionLayerReport] rows.
///
/// Identifiers stay in [ConnectionLayerValue]. This file only answers in the
/// driver's language. Do not put [TransportKind.label] on the screen.
library;

import '../../../diagnostics/connection_layers.dart';
import '../../../l10n/generated/app_localizations.dart';

String connectionLayerTitle(AppLocalizations l10n, ConnectionLayerKind kind) =>
    switch (kind) {
      ConnectionLayerKind.transport => l10n.connectionLayerTransport,
      ConnectionLayerKind.protocol => l10n.connectionLayerProtocol,
      ConnectionLayerKind.ecu => l10n.connectionLayerEcu,
      ConnectionLayerKind.evidence => l10n.connectionLayerEvidence,
    };

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
