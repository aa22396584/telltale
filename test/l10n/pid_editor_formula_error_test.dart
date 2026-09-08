/// The render site: what the PID editor actually puts under the formula field.
///
/// This is the defect the identifier migration exists to fix, and until this
/// file there was nothing standing on it. `pid_reason_copy_test.dart` proves
/// that `formulaIssueText` maps each identifier to the right sentence, and
/// `formula_engine_test.dart` proves that each condition produces the right
/// identifier — and a screen can still print the engine's Traditional Chinese
/// with both of those green, because neither one renders a screen.
///
/// The whole chain has to hold end to end:
///
///     condition -> identifier -> sentence -> the values in it -> the screen
///
/// The naive revert (`error: e.message`) is caught by `flutter analyze` as an
/// unused import, which is not a test. This variant is not caught by anything:
///
///     error: e.message.isEmpty ? formulaIssueText(l10n, e) : e.message
///
/// `flutter analyze` reports **No issues found!** and the whole suite passes.
/// `FormulaException.message` is never empty, so every formula error in the
/// editor renders 運算結果不是有效數值 / 除以零 on an English screen — the original
/// user-visible bug, restored, with every other test in this repository still
/// green. That variant was applied and this file went red; it is the reason
/// the file exists.
///
/// Both the sentences and the Chinese are hand-typed here rather than read
/// from `AppLocalizations`. A finder that asks the same ARB the widget
/// rendered agrees with itself.
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

/// The equation field. Nine `TextField`s in document order — name, short name,
/// units, mode+PID, header, **equation**, sample, min, max — addressed by
/// position because addressing them by label would mean matching a label
/// against the same ARB that produced it.
const int _equationField = 5;

/// The sample payload the editor opens with: `41 00 7B 2C`, whose Mode 01
/// prefix is stripped, leaving **two** data bytes. That count is quoted in one
/// of the sentences below, so it is stated here rather than left implicit.
const int _sampleDataBytes = 2;

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

/// The editor under a router, the way the app reaches it.
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

/// What the equation field is showing as its error, straight off the widget.
///
/// Read from the `TextField`'s own decoration rather than from a text finder:
/// this is the property `_previewFor` feeds, so a change that stopped feeding
/// it fails here rather than passing because the same words happen to appear
/// somewhere else on the screen.
String? _equationError(WidgetTester tester) => tester
    .widget<TextField>(find.byType(TextField).at(_equationField))
    .decoration!
    .errorText;

/// Everything a reader can see: `Text`, tooltips, and explicit semantics
/// labels. Same shape as `l03_pids_l10n_test.dart`, which is where the
/// tooltip/semantics halves were learned.
List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data ?? text.textSpan?.toPlainText();
    if (data != null) out.add(data);
  }
  for (final tooltip in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final message = tooltip.message;
    if (message != null) out.add(message);
  }
  for (final semantics in tester.widgetList<Semantics>(find.byType(Semantics))) {
    final label = semantics.properties.label;
    if (label != null) out.add(label);
  }
  return out;
}

Future<void> _typeFormula(WidgetTester tester, String formula) async {
  await tester.enterText(find.byType(TextField).at(_equationField), formula);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an English editor shows the English refusal, not the engine’s '
      'Chinese', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container();
    await tester.pumpWidget(_host(container, const Locale('en')));
    await tester.pumpAndSettle();

    // Sanity: the field this test indexes into is the formula one, and it is
    // not already in error. Without this, a reordering of the form would make
    // every assertion below vacuous in a way that still reads as a pass.
    expect(
      tester.widgetList<TextField>(find.byType(TextField)),
      hasLength(9),
      reason: 'the editor field order this test indexes into has changed',
    );
    expect(_equationError(tester), isNull);

    // A refusal whose sentence names nothing.
    await _typeFormula(tester, 'A/0');
    expect(
      _equationError(tester),
      'The formula divides by zero.',
      reason: 'the editor renders the engine’s identifier, not its message',
    );
    // And it reaches the reader, at both places the screen shows it — under
    // the field and in the preview panel.
    expect(find.text('The formula divides by zero.'), findsWidgets);

    // A refusal whose sentence names two values that travel as data. The
    // placeholders are the half a hand-typed copy table cannot check: the
    // table hands itself a payload, this one is whatever the editor's own
    // sample field held.
    await _typeFormula(tester, 'G+1');
    expect(
      _equationError(tester),
      'The formula refers to byte G, but the reply carried only '
      '$_sampleDataBytes bytes.',
    );

    // Nothing anywhere on the screen is Chinese — the check that catches the
    // engine's message arriving through any other route, including the
    // preview panel and the save gate.
    for (final rendered in _renderedStrings(tester)) {
      expect(
        chinese.hasMatch(rendered),
        isFalse,
        reason: 'English editor rendered ${chineseIn(rendered)} in "$rendered"',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('a Chinese editor shows the translated refusal, which is not '
      'the engine’s wording either', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container();
    // `testUiLocale` is zh-Hant, the locale the rest of the widget suite
    // pumps. `app_zh.arb` is kept in parity with it.
    await tester.pumpWidget(_host(container, testUiLocale));
    await tester.pumpAndSettle();

    await _typeFormula(tester, 'A/0');
    expect(
      _equationError(tester),
      '公式除以零。',
      reason: 'the Chinese screen reads the ARB, not FormulaException.message',
    );
    // Not the engine's own string, which is `除以零` with no full stop and is
    // written for a probe transcript rather than for a field label. The two
    // are close enough that a fallback would look plausible; that is exactly
    // why the distinction is asserted.
    expect(_equationError(tester), isNot('除以零'));

    await _typeFormula(tester, 'G+1');
    expect(
      _equationError(tester),
      '公式參照位元組 G，但回應只有 $_sampleDataBytes 個位元組。',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('an incomplete sample nibble does not throw during build',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container();
    await tester.pumpWidget(_host(container, const Locale('en')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(6), '4');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('is not a number'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('preview chips bind the data bytes, not the Mode 01 prefix',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container();
    await tester.pumpWidget(_host(container, const Locale('en')));
    await tester.pumpAndSettle();

    // Default sample is `41 00 7B 2C`. Evaluate strips 41 00, so A is 0x7B.
    expect(find.textContaining('A = 0x7B'), findsOneWidget);
    expect(find.textContaining('A = 0x41'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });
}
