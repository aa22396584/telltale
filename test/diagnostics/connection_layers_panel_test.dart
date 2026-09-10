/// The four connection-layer rows stay four facts on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/connection_layers.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/connect/connection_layers_panel.dart';

import '../support/cjk.dart';
import '../support/localized_app.dart';

void main() {
  testWidgets('Demo evidence is software, never a field claim', (tester) async {
    final report = ConnectionLayerReport.fromConnection(
      kind: TransportKind.demo,
      protocol: 'AUTO, ISO 15765-4 (CAN 11/500)',
      responders: const {'7E8'},
    );
    await tester.pumpWidget(
      localizedMaterialApp(
        locale: const Locale('en'),
        home: Scaffold(body: ConnectionLayersPanel(report: report)),
      ),
    );

    expect(
      find.byKey(const Key('connection-layer-transport-demo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('connection-layer-protocol-observed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('connection-layer-ecu-answered')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('connection-layer-evidence-software')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('connection-layer-evidence-field')),
      findsNothing,
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    for (final data in texts) {
      if (data == null) continue;
      expect(chinese.hasMatch(data), isFalse, reason: data);
    }
  });

  testWidgets('English and Traditional Chinese keep four distinct titles', (
    tester,
  ) async {
    final report = ConnectionLayerReport.fromConnection(
      kind: TransportKind.wifi,
    );
    Future<Set<String>> titles(Locale locale) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: locale,
          home: Scaffold(body: ConnectionLayersPanel(report: report)),
        ),
      );
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toSet();
    }

    final en = await titles(const Locale('en'));
    final zh = await titles(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(
      en,
      containsAll(['Transport', 'Protocol', 'ECU replies', 'Evidence']),
    );
    expect(zh, containsAll(['連線方式', '協定', '控制器回應', '證據']));
    expect(en.intersection(zh), isEmpty);
  });
}
