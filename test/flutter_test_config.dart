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
/// **Locale.** `flutter_test` starts with an *empty* platform locale list, and
/// `basicLocaleListResolution` answers an empty list with
/// `supportedLocales.first` — which `l10n.yaml`'s `preferred-supported-locales:
/// en` makes English. This sets the platform list instead of leaving it empty.
///
/// Be precise about what that does and does not cover, because the obvious
/// reading is wrong. It does **not** decide the language of most widget tests:
/// those pump through `test/support/localized_app.dart`, which passes an
/// explicit `locale: testUiLocale`, and an explicit locale wins. Deleting this
/// pin would leave those tests reading Traditional Chinese exactly as before.
///
/// What it decides is the language of anything that resolves *through* the
/// platform — `resolveSystemLocale`, and the production app root under
/// `LocalePreference.system`. Without the pin that path answers English on a
/// bare test binding and Traditional Chinese on a zh-TW developer's machine,
/// which is a test whose result depends on who ran it.
///
/// `test/l10n/system_locale_resolution_test.dart` asserts that path, so this
/// pin is load-bearing rather than decorative: remove it and that file fails.
///
/// The pin is **not** a claim that English is untested. An untested language
/// must be tested by asserting its own literal strings, which `test/l10n/` does
/// against an explicitly pinned [englishLocale]. A test that asserted
/// `find.text(l10n.someKey)` would read the same ARB entry the widget rendered
/// and pass even when the translation is wrong.
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
