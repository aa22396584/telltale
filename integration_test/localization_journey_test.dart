/// #47 first slice: language switch before connect, then Demo, on the
/// production app. Providers are not replaced with a pre-solved session.
///
/// Run with an Android device or emulator attached (set ANDROID_SERIAL when
/// more than one device is connected):
///
///     flutter test integration_test/localization_journey_test.dart -d <device-id> \
///       --flavor rig --dart-define=TELLTALE_TEST_RIG=true
///
/// Without `--flavor rig` and `TELLTALE_TEST_RIG=true` this fails closed
/// inside [requireIsolatedRigIdentity]. Missing hardware is a failure, not a
/// skip that looks like a pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'rig_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'language switch before connect, then Demo, uses production providers',
    (tester) async {
      await startCleanRigApp(tester);

      expect(find.text('選擇連線方式'), findsOneWidget);
      expect(find.text('Choose a connection'), findsNothing);

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('locale_english')));
      final englishHeadline = await pumpUntil(
        tester,
        () => find.text('Choose a connection').evaluate().isNotEmpty,
      );
      expect(
        englishHeadline,
        isTrue,
        reason: 'switching to English before connect did not retitle the screen',
      );
      expect(find.text('選擇連線方式'), findsNothing);

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      final chineseHeadline = await pumpUntil(
        tester,
        () => find.text('選擇連線方式').evaluate().isNotEmpty,
      );
      expect(
        chineseHeadline,
        isTrue,
        reason: 'switching back to Traditional Chinese did not retitle the screen',
      );
      expect(find.text('Choose a connection'), findsNothing);

      await connectDemoRig(tester);
    },
  );
}
