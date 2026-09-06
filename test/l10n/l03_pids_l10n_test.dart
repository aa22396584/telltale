/// The PID manager and the custom-PID editor, in both shipped languages.
///
/// None of these assert that a widget shows a particular ARB entry. A finder
/// that reads the same ARB the widget rendered agrees with itself, and passes
/// while the translation is wrong. What is checked instead are the properties a
/// wrong translation breaks:
///
///   * an English pump renders no Chinese anywhere — Text, tooltips, semantics;
///   * a Chinese pump still carries the qualifiers that make the copy honest;
///   * every arm of every enum still says something different from its
///     neighbours, so no two states can be merged into one sentence;
///   * user-authored PID names pass through byte-for-byte in both languages,
///     because they are data, not copy;
///   * nothing renders `Closure:`, which is what a getter-turned-method looks
///     like once it is interpolated by mistake. `flutter analyze` reports
///     nothing for that, and no other test in this suite would catch it.
///
/// The file name uses underscores rather than the `l03-pids` group slug because
/// `file_names` is on in `analysis_options.yaml`, and a hyphen there is not a
/// valid Dart library name.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/pids/pid_editor_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';

import '../support/localized_app.dart';

final _cjk = RegExp(r'[㐀-鿿豈-﫿]');

/// A custom definition whose every field is ASCII, so it cannot itself account
/// for a Chinese character found during the English pump.
const _asciiCustom =
    '{"name":"Boost","shortName":"BST","modeAndPid":"010B",'
    '"equation":"A","minValue":0,"maxValue":300,"units":"kPa",'
    '"header":"7E0","isCustom":true,"variant":"boost"}';

/// A custom definition named the way a Traditional Chinese speaker would name
/// one. It is user data: it must survive both languages unchanged, and it must
/// never be treated as a lookup key.
const _authoredInChinese =
    '{"name":"渦輪增壓 Boost","shortName":"增壓","modeAndPid":"010B",'
    '"equation":"A","minValue":0,"maxValue":300,"units":"kPa",'
    '"header":"7E0","isCustom":true,"variant":"authored"}';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

Widget _host(ProviderContainer container, Widget home, Locale locale) =>
    UncontrolledProviderScope(
      container: container,
      child: localizedMaterialApp(home: home, locale: locale),
    );

/// The editor under a router, the way the app reaches it. A back gesture has
/// somewhere to go, which is what makes the discard dialog reachable at all.
Widget _editorHost(ProviderContainer container, String? pidId, Locale locale) {
  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, _) => PidEditorScreen(pidId: pidId),
          ),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: localizedMaterialAppRouter(routerConfig: router, locale: locale),
  );
}

/// Everything the user can read: `Text`, tooltip messages, and the labels of
/// explicit `Semantics` nodes.
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

void _expectNoChinese(WidgetTester tester, String where) {
  for (final rendered in _renderedStrings(tester)) {
    expect(
      _cjk.hasMatch(rendered),
      isFalse,
      reason: '$where rendered Chinese at the English locale: "$rendered"',
    );
  }
}

/// A method that used to be a getter renders as `Closure: …` when it is
/// interpolated instead of called, and analyze says nothing about it.
void _expectNoTearOff(WidgetTester tester, String where) {
  for (final rendered in _renderedStrings(tester)) {
    expect(
      rendered,
      isNot(contains('Closure')),
      reason: '$where interpolated a tear-off instead of calling it: '
          '"$rendered"',
    );
  }
}

void _expectSomethingContains(
  WidgetTester tester,
  Pattern needle,
  String reason,
) {
  expect(
    _renderedStrings(tester).any((s) => s.contains(needle)),
    isTrue,
    reason: '$reason — rendered: ${_renderedStrings(tester)}',
  );
}

/// A screen that rendered nothing passes "no Chinese here" for the wrong
/// reason. This is the guard against that.
void _expectSomethingRendered(WidgetTester tester, int atLeast, String where) {
  expect(
    _renderedStrings(tester).where((s) => s.trim().isNotEmpty).length,
    greaterThanOrEqualTo(atLeast),
    reason: '$where rendered almost nothing, so the checks above are vacuous',
  );
}

ObdCapabilitySummary _summary({
  ObdCapabilityDiscoveryPhase phase =
      ObdCapabilityDiscoveryPhase.attemptFinished,
  Set<String> verified = const {'0100'},
  Set<String> supported = const {'010C'},
}) => ObdCapabilitySummary(
  phase: phase,
  verifiedBlockIds: verified,
  supportedMode01Requests: supported,
  directlyAnsweredDefinitionIds: const <String>{},
);

SupportedPidBulkPresentation _presentation(SupportedPidBulkUiState state) =>
    SupportedPidBulkPresentation(state: state, confirmedCount: 4, addCount: 3);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('context-free copy answers every enum arm in both languages', () {
    test('ObdCapabilityDiscoveryPhase', () {
      for (final locale in {'en': en, 'zh-Hant': zh}.entries) {
        final seen = <String>{};
        for (final phase in ObdCapabilityDiscoveryPhase.values) {
          final label = obdCapabilityPhaseLabel(locale.value, phase);
          expect(label.trim(), isNotEmpty, reason: '$phase ${locale.key}');
          expect(
            seen.add(label),
            isTrue,
            reason:
                '${locale.key} gives $phase the same words as an earlier '
                'phase; "not started", "running", "finished" and "interrupted" '
                'are four different claims about what was asked',
          );
        }
      }
      for (final phase in ObdCapabilityDiscoveryPhase.values) {
        expect(
          _cjk.hasMatch(obdCapabilityPhaseLabel(en, phase)),
          isFalse,
          reason: '$phase carries Chinese in English',
        );
      }
      // Interrupted is the app giving up, not the vehicle answering. It must
      // not read as a finished scan.
      expect(
        obdCapabilityPhaseLabel(en, ObdCapabilityDiscoveryPhase.interrupted),
        isNot(obdCapabilityPhaseLabel(
          en,
          ObdCapabilityDiscoveryPhase.attemptFinished,
        )),
      );
    });

    test('SupportedPidBulkUiState', () {
      for (final locale in {'en': en, 'zh-Hant': zh}.entries) {
        final seen = <String>{};
        for (final state in SupportedPidBulkUiState.values) {
          final label = supportedPidBulkActionLabel(
            locale.value,
            _presentation(state),
          );
          expect(label.trim(), isNotEmpty, reason: '$state ${locale.key}');
          expect(
            seen.add(label),
            isTrue,
            reason:
                '${locale.key} gives $state a label another state already '
                'uses; the button is the only thing that says why it is '
                'disabled',
          );
        }
      }
      for (final state in SupportedPidBulkUiState.values) {
        expect(
          _cjk.hasMatch(supportedPidBulkActionLabel(en, _presentation(state))),
          isFalse,
          reason: '$state carries Chinese in English',
        );
      }
      // "Nothing was confirmed" and "everything confirmed is already on" are
      // opposite outcomes that both leave the button doing nothing.
      expect(
        supportedPidBulkActionLabel(zh, _presentation(
          SupportedPidBulkUiState.zero,
        )),
        isNot(supportedPidBulkActionLabel(zh, _presentation(
          SupportedPidBulkUiState.allActive,
        ))),
      );
    });

    test('PriorityTier', () {
      for (final locale in {'en': en, 'zh-Hant': zh}.entries) {
        final seen = <String>{};
        for (final tier in PriorityTier.values) {
          final label = priorityTierLabel(locale.value, tier);
          expect(label.trim(), isNotEmpty, reason: '$tier ${locale.key}');
          expect(
            seen.add(label),
            isTrue,
            reason:
                '${locale.key} gives $tier a label another tier already uses; '
                'the segmented button would then offer two identical choices',
          );
        }
      }
      for (final tier in PriorityTier.values) {
        expect(
          _cjk.hasMatch(priorityTierLabel(en, tier)),
          isFalse,
          reason: '$tier carries Chinese in English',
        );
      }
    });
  });

  group('the bulk-add confirmation keeps both of its halves', () {
    test('the unconfirmed-blocks warning appears only when there are some', () {
      for (final locale in {'en': en, 'zh-Hant': zh}.entries) {
        final withUnknown = supportedPidConfirmationMessage(
          l10n: locale.value,
          summary: _summary(supported: const {'010C', '0120'}),
          addCount: 3,
        );
        final withoutUnknown = supportedPidConfirmationMessage(
          l10n: locale.value,
          summary: _summary(),
          addCount: 3,
        );
        expect(
          withUnknown.split('\n\n'),
          hasLength(2),
          reason:
              '${locale.key} lost the "still unconfirmed, only positively '
              'evidenced items are added" half',
        );
        expect(
          withoutUnknown.split('\n\n'),
          hasLength(1),
          reason:
              '${locale.key} warns about unconfirmed blocks when there are '
              'none',
        );
        expect(
          withUnknown,
          endsWith(withoutUnknown),
          reason:
              '${locale.key} changes the second half depending on the first',
        );
        expect(withUnknown, contains('3'), reason: '${locale.key} count');
      }
      expect(
        _cjk.hasMatch(
          supportedPidConfirmationMessage(
            l10n: en,
            summary: _summary(supported: const {'010C', '0120'}),
            addCount: 3,
          ),
        ),
        isFalse,
      );
    });

    test('the count comes from the argument, not from the prose', () {
      for (final count in [1, 7, 42]) {
        for (final locale in [en, zh]) {
          expect(
            supportedPidConfirmationMessage(
              l10n: locale,
              summary: _summary(),
              addCount: count,
            ),
            contains('$count'),
          );
        }
      }
    });
  });

  testWidgets('the PID manager renders no Chinese in English', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container({
      'custom_pids_v1': <String>[_asciiCustom],
    });

    await tester.pumpWidget(
      _host(container, const PidManagerScreen(), const Locale('en')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // The capability panel, the row pills, the readings and the filter chip
    // are all on screen, so what follows covers them rather than assuming so.
    _expectSomethingRendered(tester, 20, 'PID manager');
    _expectNoTearOff(tester, 'PID manager');
    _expectNoChinese(tester, 'PID manager');

    // The empty state, which only the search box can reach.
    await tester.enterText(find.byType(TextField).first, 'zzz-no-such-pid');
    await tester.pump();
    _expectNoTearOff(tester, 'PID manager empty state');
    _expectNoChinese(tester, 'PID manager empty state');

    // The overflow menu: three destinations that are otherwise never built.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    _expectNoTearOff(tester, 'PID manager menu');
    _expectNoChinese(tester, 'PID manager menu');

    // Selecting "arrange" opens the reorder sheet, which has copy of its own.
    await tester.tap(find.byIcon(Icons.reorder));
    await tester.pumpAndSettle();
    _expectNoTearOff(tester, 'arrange sheet');
    _expectNoChinese(tester, 'arrange sheet');

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('the PID editor renders no Chinese in English', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container({
      'custom_pids_v1': <String>[_asciiCustom],
    });

    await tester.pumpWidget(_editorHost(container, null, const Locale('en')));
    await tester.pumpAndSettle();

    _expectSomethingRendered(tester, 20, 'PID editor');
    _expectNoTearOff(tester, 'PID editor');
    _expectNoChinese(tester, 'PID editor');

    // The dependency-substitution notice only exists once the formula refers to
    // another PID. Fields are addressed by position because addressing them by
    // label would mean asserting a label against the ARB that produced it.
    final fields = find.byType(TextField);
    expect(
      tester.widgetList<TextField>(fields),
      hasLength(9),
      reason: 'the editor field order this test indexes into has changed',
    );
    await tester.enterText(fields.at(5), 'A-VAL{0133}');
    await tester.pumpAndSettle();

    _expectNoTearOff(tester, 'PID editor preview');
    _expectNoChinese(tester, 'PID editor preview');
    _expectSomethingContains(
      tester,
      'VAL{0133}',
      'the substitution notice dropped the VAL token it is about',
    );
    _expectSomethingContains(
      tester,
      '100',
      'the substitution notice dropped the stand-in value it announces',
    );

    // The discard dialog, reached only from a dirty form.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'sanity: dirty');
    _expectNoTearOff(tester, 'discard dialog');
    _expectNoChinese(tester, 'discard dialog');

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('Traditional Chinese keeps the qualifiers that carry the claim', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _container({
      'custom_pids_v1': <String>[_asciiCustom],
    });

    await tester.pumpWidget(
      _host(container, const PidManagerScreen(), testUiLocale),
    );
    await tester.pump(const Duration(milliseconds: 300));

    _expectNoTearOff(tester, 'PID manager, zh-Hant');
    // 未知 is the hedge: those blocks were never read. Rendering them as
    // 不支援 would turn silence into the vehicle disclaiming a PID.
    _expectSomethingContains(
      tester,
      '未知區塊',
      'the capability panel stopped calling unread blocks unknown',
    );
    // 尚未開始 scopes the phase to this attempt rather than to the vehicle.
    _expectSomethingContains(
      tester,
      '掃描',
      'the capability panel stopped naming the scan',
    );
    // 自訂 marks a definition the user wrote, which the app never claims the
    // vehicle confirmed. Searched for rather than scrolled to: the custom row
    // sorts below twenty-five built-ins.
    await tester.enterText(find.byType(TextField).first, 'Boost');
    await tester.pump();
    _expectSomethingContains(
      tester,
      '自訂',
      'the custom pill disappeared from a custom definition',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  testWidgets('a PID the user named in Chinese is data in both languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final locale in [const Locale('en'), testUiLocale]) {
      final container = await _container({
        'custom_pids_v1': <String>[_authoredInChinese],
      });
      final stored = container
          .read(pidRegistryProvider)
          .firstWhere((p) => p.isCustom);
      expect(stored.name, '渦輪增壓 Boost', reason: 'sanity: it was stored');

      await tester.pumpWidget(_editorHost(container, stored.id, locale));
      await tester.pumpAndSettle();

      // The name field carries it verbatim: an editor that "translated" a
      // user's own label would rewrite their data on open.
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).first.controller?.text,
        '渦輪增壓 Boost',
        reason: '$locale rewrote a user-authored name',
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      _expectNoTearOff(tester, 'delete dialog $locale');
      _expectSomethingContains(
        tester,
        '渦輪增壓 Boost',
        '$locale dropped the PID name from the delete confirmation, leaving '
            'the user to guess which definition they are destroying',
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
    }
  });
}
