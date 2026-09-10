/// Four independent connection facts on the connect screen.
///
/// Transport, protocol, ECU replies and evidence must not collapse into one
/// "connected" line. Demo is software evidence, never field.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../diagnostics/connection_layers.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'connection_layer_copy.dart';

class ConnectionLayersPanel extends StatelessWidget {
  const ConnectionLayersPanel({required this.report, super.key});

  final ConnectionLayerReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          context,
          kind: ConnectionLayerKind.transport,
          value: report.transport,
          l10n: l10n,
        ),
        _row(
          context,
          kind: ConnectionLayerKind.protocol,
          value: report.protocol,
          l10n: l10n,
          detail: connectionLayerProtocolDetail(l10n, report),
        ),
        _row(
          context,
          kind: ConnectionLayerKind.ecu,
          value: report.ecu,
          l10n: l10n,
        ),
        _row(
          context,
          kind: ConnectionLayerKind.evidence,
          value: report.evidence,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required ConnectionLayerKind kind,
    required ConnectionLayerValue value,
    required AppLocalizations l10n,
    String? detail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Semantics(
        identifier: 'connection-layer-${kind.name}-${value.name}',
        key: Key('connection-layer-${kind.name}-${value.name}'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                connectionLayerTitle(l10n, kind),
                style: context.texts.bodySmall,
              ),
            ),
            Text(
              detail ?? connectionLayerValueText(l10n, value),
              style: context.texts.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
