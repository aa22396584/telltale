import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/core/affiliate/recommended_purchases.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/widgets/recommended_purchase_panel.dart';

class _IdleSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog currently has the Shopee listing used in hardware docs', () {
    expect(RecommendedPurchases.entries, hasLength(1));
    final purchase = RecommendedPurchases.entries.single;
    expect(purchase.storeLabel, '蝦皮');
    expect(purchase.model, 'CL-OBDII-M25B');
    expect(purchase.radioApproval, 'CCAH22LP5300T8');
    expect(purchase.url, 'https://s.shopee.tw/3LQPiOY7uv');
    expect(purchase.uri.host, 's.shopee.tw');
    expect(RecommendedPurchases.disclosure, contains('推廣分潤'));
    expect(RecommendedPurchases.disclosure, contains('不是轉接器認證'));
    expect(RecommendedPurchases.shortDisclosure, contains('推廣分潤'));
    expect(RecommendedPurchases.shortDisclosure, contains('完整說明在設定'));
  });

  testWidgets('panel opens the Shopee URI and shows the disclosure', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RecommendedPurchasePanel(
            onOpen: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('推廣分潤'), findsOneWidget);
    expect(find.textContaining('CL-OBDII-M25B'), findsWidgets);
    expect(find.text('在蝦皮查看'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('recommended_purchase_shopee-cl-obdii-m25b')),
    );
    await tester.pump();

    expect(opened, RecommendedPurchases.entries.single.uri);
  });

  testWidgets('failed open shows a snackbar instead of pretending success', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RecommendedPurchasePanel(onOpen: (_) async => false),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('recommended_purchase_shopee-cl-obdii-m25b')),
    );
    await tester.pump();
    expect(find.text('無法開啟蝦皮連結'), findsOneWidget);
  });

  testWidgets('a throwing opener still shows the snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RecommendedPurchasePanel(
            onOpen: (_) async => throw Exception('no handler'),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('recommended_purchase_shopee-cl-obdii-m25b')),
    );
    await tester.pump();
    expect(find.text('無法開啟蝦皮連結'), findsOneWidget);
  });

  testWidgets(
    'connect keeps the Shopee entry as a secondary link below transports',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'last_adapter_v1': const LastAdapter(
          id: '192.168.1.135',
          name: 'Wi-Fi 192.168.1.135',
          kind: TransportKind.wifi,
          port: 35000,
        ).encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? opened;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appSharePolicyProvider.overrideWith(
              (ref) => ref.watch(productionAppSharePolicyProvider),
            ),
            obdSessionProvider.overrideWith(_IdleSession.new),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: ConnectScreen(
              onOpenRecommendedPurchase: (uri) async {
                opened = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, '在蝦皮查看'), findsNothing);
      expect(find.text('推薦轉接器'), findsNothing);
      expect(find.textContaining('CL-OBDII-M25B'), findsNothing);
      expect(find.textContaining('不是轉接器認證或購買保證'), findsNothing);

      final demoCard = find.text(TransportKind.demo.label);
      expect(demoCard, findsOneWidget);

      final cta = find.text('還沒有轉接器？在蝦皮看推薦款');
      await tester.scrollUntilVisible(
        cta,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(cta, findsOneWidget);
      expect(find.textContaining('完整說明在設定'), findsOneWidget);

      final reconnect = find.text('直接連線');
      expect(reconnect, findsOneWidget);
      expect(
        tester.getTopLeft(cta).dy,
        greaterThan(tester.getTopLeft(demoCard).dy),
      );
      expect(
        tester.getTopLeft(cta).dy,
        greaterThan(tester.getTopLeft(reconnect).dy),
      );

      await tester.tap(
        find.byKey(const Key('recommended_purchase_link_shopee-cl-obdii-m25b')),
      );
      await tester.pump();
      expect(opened, RecommendedPurchases.entries.single.uri);
    },
  );

  testWidgets(
    'settings still shows the full catalog card and opens the Shopee URI',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? opened;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            obdSessionProvider.overrideWith(_IdleSession.new),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: SettingsScreen(
              onOpenRecommendedPurchase: (uri) async {
                opened = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heading = find.text('推薦轉接器');
      await tester.scrollUntilVisible(
        heading,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(heading, findsOneWidget);
      expect(find.textContaining('推廣分潤'), findsWidgets);
      expect(find.textContaining('CL-OBDII-M25B'), findsWidgets);
      expect(find.textContaining('CCAH22LP5300T8'), findsOneWidget);
      expect(find.text('還沒有轉接器？在蝦皮看推薦款'), findsNothing);

      final storeButton = find.widgetWithText(FilledButton, '在蝦皮查看');
      await tester.scrollUntilVisible(
        storeButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(storeButton);
      await tester.pumpAndSettle();
      await tester.tap(storeButton);
      await tester.pump();
      expect(opened, RecommendedPurchases.entries.single.uri);
    },
  );

  testWidgets('connect failed open shows a snackbar on the shipped screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appSharePolicyProvider.overrideWith(
            (ref) => ref.watch(productionAppSharePolicyProvider),
          ),
          obdSessionProvider.overrideWith(_IdleSession.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: ConnectScreen(onOpenRecommendedPurchase: (_) async => false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.byKey(
      const Key('recommended_purchase_link_shopee-cl-obdii-m25b'),
    );
    await tester.scrollUntilVisible(
      cta,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pump();
    expect(find.text('無法開啟蝦皮連結'), findsOneWidget);
  });

  testWidgets('settings failed open shows a snackbar on the shipped screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          obdSessionProvider.overrideWith(_IdleSession.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SettingsScreen(onOpenRecommendedPurchase: (_) async => false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final storeButton = find.widgetWithText(FilledButton, '在蝦皮查看');
    await tester.scrollUntilVisible(
      storeButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(storeButton);
    await tester.pumpAndSettle();
    await tester.tap(storeButton);
    await tester.pump();
    expect(find.text('無法開啟蝦皮連結'), findsOneWidget);
  });

  testWidgets('connect disclosure opens Settings instead of sitting inert', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var openedSettings = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appSharePolicyProvider.overrideWith(
            (ref) => ref.watch(productionAppSharePolicyProvider),
          ),
          obdSessionProvider.overrideWith(_IdleSession.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: ConnectScreen(
            onOpenRecommendedPurchaseDisclosure: () => openedSettings = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final disclosure = find.byKey(
      const Key('recommended_purchase_open_settings'),
    );
    await tester.scrollUntilVisible(
      disclosure,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(disclosure);
    await tester.pumpAndSettle();
    await tester.tap(disclosure);
    await tester.pump();
    expect(openedSettings, isTrue);
  });
}
