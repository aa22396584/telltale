import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

/// Gives host-side tests the foreground lifecycle edge that a real Flutter
/// engine sends before a user can interact with the app, and pins the platform
/// locale so widget copy is deterministic.
///
/// **Lifecycle.** [TestWidgetsFlutterBinding] otherwise starts with a null
/// lifecycle state. Production deliberately treats that absence as
/// unknown/background, but the existing notifier and transport tests model an
/// already interactive app. Resetting before every test preserves that model
/// without weakening the production fail-closed lifecycle gate or allowing one
/// lifecycle test to leak a paused state into the next test.
///
/// **Locale.** `flutter_test` starts with an *empty* locale list, and
/// `basicLocaleListResolution` answers an empty list with
/// `supportedLocales.first`, which `l10n.yaml`'s `preferred-supported-locales:
/// en` makes English. Every assertion in this suite that was written against
/// the shipped Traditional Chinese copy would therefore start reading English
/// the moment a screen becomes localized — not because the copy regressed, but
/// because nobody ever chose a locale. Choosing one here makes the existing
/// assertions mean what they were written to mean.
///
/// This pin is **not** a claim that English is untested. It is the opposite: an
/// untested language must be tested by asserting its own literal strings, which
/// `test/l10n/` does against an explicitly pinned [englishLocale]. A test that
/// asserted `find.text(l10n.someKey)` would read the same ARB entry the widget
/// rendered and pass even when the translation is wrong.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  void resume() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  void pinLocale() {
    binding.platformDispatcher.localesTestValue = const <Locale>[
      traditionalChineseLocale,
    ];
  }

  resume();
  pinLocale();
  setUp(resume);
  setUp(pinLocale);
  await testMain();
}
