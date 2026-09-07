/// The two render sites round 3 did not pin, and what they printed instead.
///
/// `pid_editor_formula_error_test.dart` pins the equation field. It was
/// written as "the render site". There are four, and mutating the other three
/// to print `reason.issue.name` left the entire suite green at 2157 passing
/// while the screen showed a reader:
///
///     MODEPID errorText = serviceNotReadOnly
///     SAVE-GATE Text    = nameRequired
///
/// Two of those three are here. The third — the CSV import snackbar in
/// `pid_manager_screen.dart` — is behind a file picker; see
/// `pid_manager_snackbar_test.dart` for how it is reached instead.
///
/// The census in `pid_reason_guard_test.dart` is what stops a fifth from
/// appearing unpinned. This file is why that census names two tests rather
/// than one: the sites were enumerated by hand, from whatever was in front of
/// the author, and a hand-written list is correct exactly once.
///
/// Every expected sentence below is TYPED OUT, including the values
/// interpolated into it. Reading it back from the ARB, from
/// `AppLocalizations`, or from `pidRejectionText` would agree with any
/// implementation, including one that hands every rejection the same string.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/pids/pid_editor_screen.dart';

import '../support/cjk.dart';
import '../support/localized_app.dart';

/// Field order, probed rather than counted off the source: name, short name,
/// units, **mode+PID**, CAN header, expression, test bytes, minimum, maximum.
const int _nameField = 0;
const int _modeAndPidField = 3;
const int _minField = 7;
const int _maxField = 8;

/// `2F` is a write service — it actuates outputs — so the editor refuses to
/// let a gauge poll it. `2F01` is the shortest input that reaches that
/// refusal, because the check needs four characters before it runs.
const String _writeService = '2F01';

/// Hand-typed, values and all. `2F` is the service; `01, 02, 09, 22` is
/// `PollableServices.allowed` joined with the locale's list separator, and
/// both halves are what makes this an assertion about the VALUES rather than
/// only about which sentence was picked.
const String _serviceRefusalEn =
    'Service 2F is not a read-only query and must not be sent to the vehicle '
    'over and over. Only 01, 02, 09, 22 are allowed — current data, freeze '
    'frame, vehicle information and ReadDataByIdentifier.';
const String _serviceRefusalZh =
    '服務 2F 不是唯讀查詢，不能週期性發送到車上。只允許 01、02、09、22'
    '（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。';

const String _nameRequiredEn = 'Enter a name.';
const String _nameRequiredZh = '請輸入名稱。';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

Widget _host(ProviderContainer container, Locale locale) {
  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(),
        routes: [
          GoRoute(path: 'edit', builder: (_, _) => const PidEditorScreen()),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: localizedMaterialAppRouter(routerConfig: router, locale: locale),
  );
}

TextField _field(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index));

/// The index is asserted against the field's own label before it is used.
/// A field inserted above this one would otherwise move every test in this
/// file onto a different input and keep them green — the same shape of
/// silence the file exists to close.
void _assertFieldIs(WidgetTester tester, int index, String englishLabel) {
  expect(_field(tester, index).decoration!.labelText, englishLabel,
      reason: 'field $index is no longer $englishLabel; the indices moved');
}

List<String> _visibleText(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data ?? text.textSpan?.toPlainText();
    if (data != null) out.add(data);
  }
  return out;
}

void main() {
  group('the mode+PID field refuses a write service in the reader\'s language',
      () {
    testWidgets('English', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final container = await _container();
      await tester.pumpWidget(_host(container, const Locale('en')));
      await tester.pumpAndSettle();

      _assertFieldIs(tester, _modeAndPidField, 'Mode + PID');
      await tester.enterText(
          find.byType(TextField).at(_modeAndPidField), _writeService);
      await tester.pumpAndSettle();

      // Read off the widget's own decoration: this is the property
      // `_serviceRejection` feeds, so a change that stops feeding it fails
      // here rather than passing because the words appear somewhere else.
      expect(_field(tester, _modeAndPidField).decoration!.errorText,
          _serviceRefusalEn);
      for (final s in _visibleText(tester)) {
        expect(containsChinese(s), isFalse, reason: 'English screen showed: $s');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('Traditional Chinese', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final container = await _container();
      await tester.pumpWidget(_host(container, testUiLocale));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).at(_modeAndPidField), _writeService);
      await tester.pumpAndSettle();

      final shown = _field(tester, _modeAndPidField).decoration!.errorText;
      expect(shown, _serviceRefusalZh);
      // Not the identifier, which is what the unpinned site printed.
      expect(shown, isNot('serviceNotReadOnly'));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  });

  group('the save gate says why it is closed', () {
    /// A definition that is valid apart from the missing name, so the refusal
    /// is `nameRequired` and not something else that happens to also apply.
    Future<void> fillValidExceptName(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(_modeAndPidField), '0105');
      await tester.enterText(find.byType(TextField).at(_minField), '0');
      await tester.enterText(find.byType(TextField).at(_maxField), '100');
      await tester.enterText(find.byType(TextField).at(_nameField), '');
      await tester.pumpAndSettle();
    }

    testWidgets('English', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final container = await _container();
      await tester.pumpWidget(_host(container, const Locale('en')));
      await tester.pumpAndSettle();
      _assertFieldIs(tester, _nameField, 'Name');
      _assertFieldIs(tester, _minField, 'Minimum');
      await fillValidExceptName(tester);

      expect(_visibleText(tester), contains(_nameRequiredEn));
      for (final s in _visibleText(tester)) {
        expect(containsChinese(s), isFalse, reason: 'English screen showed: $s');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('Traditional Chinese', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final container = await _container();
      await tester.pumpWidget(_host(container, testUiLocale));
      await tester.pumpAndSettle();
      await fillValidExceptName(tester);

      final visible = _visibleText(tester);
      expect(visible, contains(_nameRequiredZh));
      expect(visible, isNot(contains('nameRequired')));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  });
}
