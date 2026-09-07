// The app chrome, in both languages: navigation, dials, status details, field
// markers, the affiliate panel and the language picker.
//
// None of these assert that a string equals its own ARB entry. A finder that
// reads the same ARB the widget rendered agrees with itself, and would pass on
// a translation that says the opposite of the English. What is asserted here
// is the set of properties a wrong translation actually breaks:
//
//  * English screens carry no Chinese, and Chinese screens keep the qualifiers
//    that make their claims true;
//  * a navigation label fits the width it is given, in both languages, because
//    the framework's answer to a label that does not fit is to hide the half
//    that says which screen it is;
//  * the distinctions this app refuses to blur — no data vs. a reason, saved
//    vs. held in memory, "nothing was flagged" vs. "this value is valid" —
//    survive the move into the ARBs;
//  * the affiliate disclosure keeps every regulated qualifier. That copy used
//    to be a `const` in `RecommendedPurchases` guarded by
//    `recommended_purchases_test.dart`; the panel now renders the ARB entry,
//    so the guard has to live where the shipped sentence does.
//
// The language picker is the deliberate exception to the first property: its
// options are self-names, and English is supposed to see 繁體中文. It is
// asserted the other way round — both names present in both locales.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/core/affiliate/recommended_purchases.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart'
    show sharedPreferencesProvider;
import 'package:torque_obd/ui/shell.dart';
import 'package:torque_obd/ui/widgets/field_event_markers.dart';
import 'package:torque_obd/ui/widgets/gauges/dial_gauge.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';
import 'package:torque_obd/ui/widgets/recommended_purchase_panel.dart';
import 'package:torque_obd/ui/widgets/status/datum_status_badge.dart';

import '../support/localized_app.dart';
import '../support/cjk.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

class _IdleSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

/// Every string this subtree actually put on screen, `Text` and `Semantics`.
List<String> _renderedText(WidgetTester tester, Finder scope) {
  final out = <String>[];
  for (final widget in tester.widgetList<Text>(
    find.descendant(of: scope, matching: find.byType(Text)),
  )) {
    final data = widget.data ?? widget.textSpan?.toPlainText();
    if (data != null && data.isNotEmpty) out.add(data);
  }
  for (final widget in tester.widgetList<Semantics>(
    find.descendant(of: scope, matching: find.byType(Semantics)),
  )) {
    for (final value in [
      widget.properties.label,
      widget.properties.value,
      widget.properties.hint,
    ]) {
      if (value != null && value.isNotEmpty) out.add(value);
    }
  }
  return out;
}

void _expectNoChinese(List<String> strings, {required String where}) {
  final offenders = strings.where(_cjk.hasMatch).toList();
  expect(
    offenders,
    isEmpty,
    reason:
        'these render Chinese to an English-speaking driver in $where:\n'
        '${offenders.join("\n")}',
  );
}

/// Loads the font the navigation labels are actually drawn in.
///
/// Without this the whole width check is theatre. `flutter_test` substitutes a
/// font whose every glyph is one em wide, under which "Dashboard" measures
/// 111.6dp — nearly twice its real width — and the only labels that would pass
/// are ones too short to say anything. Measuring the test font and reporting
/// it as a layout result is the prose form of a plausible wrong number.
///
/// `AppTypography.display` is a bundled asset, so the real thing can be read
/// off disk and registered under the family name the theme asks for.
Future<void> _loadDisplayFont() async {
  final bytes = File('assets/fonts/SpaceGrotesk[wght].ttf').readAsBytesSync();
  final loader = FontLoader('SpaceGrotesk')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// Whether every label in [scope] got the width it asked for.
///
/// `didExceedMaxLines` only catches the bottom bar, which clips to one line
/// and ellipsises. The rail is passed a bare `Text`, so a label too long for
/// its cell wraps instead: nothing throws, no exception is recorded, and the
/// destination silently becomes two lines high. Comparing the paragraph's
/// unwrapped width against the width it was laid out at catches both, because
/// a paragraph that fits is sized to exactly what it wanted.
List<String> _overflowingLabels(WidgetTester tester, Finder scope) {
  final overflowing = <String>[];
  final paragraphs = find.descendant(of: scope, matching: find.byType(Text));
  for (var i = 0; i < tester.widgetList(paragraphs).length; i++) {
    final element = paragraphs.evaluate().elementAt(i);
    final box = element.renderObject;
    if (box is! RenderParagraph) continue;
    final wanted = box.getMaxIntrinsicWidth(double.infinity);
    if (wanted > box.size.width + 0.5) {
      overflowing.add(
        '"${box.text.toPlainText()}" wants '
        '${wanted.toStringAsFixed(1)} and got '
        '${box.size.width.toStringAsFixed(1)}',
      );
    }
  }
  return overflowing;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Locale locale,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/pids',
    routes: [
      GoRoute(
        path: '/pids',
        // Deliberately inert: the PID screen belongs to another group, and its
        // copy is not what this file is measuring.
        builder: (context, state) =>
            const AppShell(child: Scaffold(body: SizedBox.shrink())),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [obdSessionProvider.overrideWith(_IdleSession.new)],
      child: localizedMaterialAppRouter(
        theme: AppTheme.dark(),
        locale: locale,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadDisplayFont);

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  // 360dp is the narrowest phone this app is used on, and the width at which a
  // five-tab bar gives each label the least room. 900dp crosses the shell's
  // own 720dp threshold into the rail.
  const phone = Size(360, 800);
  const tablet = Size(900, 800);

  group('navigation destinations', () {
    testWidgets('the English bottom bar carries no Chinese', (tester) async {
      await _pumpShell(tester, locale: englishLocale, size: phone);
      expect(find.byType(NavigationBar), findsOneWidget);
      _expectNoChinese(
        _renderedText(tester, find.byType(NavigationBar)),
        where: 'the bottom navigation bar',
      );
    });

    testWidgets('the English rail carries no Chinese', (tester) async {
      await _pumpShell(tester, locale: englishLocale, size: tablet);
      expect(find.byType(NavigationRail), findsOneWidget);
      _expectNoChinese(
        _renderedText(tester, find.byType(NavigationRail)),
        where: 'the navigation rail',
      );
    });

    testWidgets('the Chinese bar is translated, except the PID token', (
      tester,
    ) async {
      await _pumpShell(tester, locale: traditionalChineseLocale, size: phone);
      final labels = _renderedText(tester, find.byType(NavigationBar));
      expect(labels, contains('PID'), reason: 'PID is an SAE J1979 term');
      // Every other destination is Chinese. A missing zh entry falls back to
      // the English template, which gen-l10n does not report and which looks
      // translated from a screenshot.
      final untranslated = labels
          .where((l) => l != 'PID' && !_cjk.hasMatch(l))
          .toList();
      expect(
        untranslated,
        isEmpty,
        reason: 'still English inside a Chinese bar: $untranslated',
      );
    });

    for (final entry in {
      'English': englishLocale,
      'Chinese': traditionalChineseLocale,
    }.entries) {
      testWidgets('no ${entry.key} bar label is cut off at 360dp', (
        tester,
      ) async {
        await _pumpShell(tester, locale: entry.value, size: phone);
        expect(
          _overflowingLabels(tester, find.byType(NavigationBar)),
          isEmpty,
          reason:
              'an ellipsised tab hides which screen it goes to; use a shorter '
              'true word rather than a truncated long one',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('no ${entry.key} rail label wraps', (tester) async {
        await _pumpShell(tester, locale: entry.value, size: tablet);
        expect(
          _overflowingLabels(tester, find.byType(NavigationRail)),
          isEmpty,
          reason: 'the rail wraps silently rather than ellipsising',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('a dial says why it has no number', () {
    testWidgets('English announces the reason, not only the absence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: englishLocale,
          home: const Scaffold(
            body: SizedBox.square(
              dimension: 300,
              child: DialGauge(
                value: null,
                minValue: 0,
                maxValue: 8000,
                label: 'RPM',
                units: 'rpm',
                // Supplied by the caller in the caller's language; this test
                // uses an ASCII one so only the gauge's own copy is measured.
                footnote: 'Formula error',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By label, not by type: the gauge's `Semantics` node is inside
      // DialGauge's subtree, and asking for the widget's own element walks up
      // to a merged ancestor that carries no value.
      final spoken = tester.getSemantics(find.bySemanticsLabel('RPM')).value;
      expect(spoken, contains('Formula error'));
      _expectNoChinese([spoken], where: 'the dial semantics value');
      handle.dispose();
    });

    testWidgets('Chinese keeps the number and qualifies its age', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: traditionalChineseLocale,
          home: const Scaffold(
            body: SizedBox.square(
              dimension: 300,
              child: DialGauge(
                value: 2450,
                minValue: 0,
                maxValue: 8000,
                label: 'RPM',
                units: 'rpm',
                isStale: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final spoken = tester.getSemantics(find.bySemanticsLabel('RPM')).value;
      expect(
        spoken,
        contains('2450'),
        reason: 'the reading is real; its age is the qualification',
      );
      expect(spoken, contains('資料已過期'));
      // Drawn as well as spoken: colour and opacity alone exclude anyone who
      // cannot perceive the difference.
      expect(find.text('資料已過期'), findsOneWidget);
      handle.dispose();
    });

    test('a reason is never collapsed into a bare "no data"', () {
      for (final entry in {'en': en, 'zh': zh}.entries) {
        final l10n = entry.value;
        expect(
          l10n.gaugeNoDataBecause('X'),
          isNot(l10n.gaugeNoData),
          reason:
              '${entry.key}: a formula error the user can fix, a bus fault '
              'they cannot and a sensor that will be retried must not all be '
              'announced identically',
        );
        expect(l10n.gaugeNoDataBecause('X'), contains('X'));
        expect(l10n.gaugeReadingStale('42 rpm'), contains('42 rpm'));
        expect(l10n.gaugeReadingStale('42 rpm'), isNot('42 rpm'));
      }
    });
  });

  group('per-value status details', () {
    // The caller-supplied prose is injected as ASCII, so anything Chinese the
    // dialog renders is its own. `badgeText` no longer needs excluding: the
    // badge words moved into the ARBs with the rest of the data-status
    // vocabulary, so the dialog is now checked whole.
    const status = DatumStatus(
      availability: FeatureAvailability.usable,
      origin: DatumOrigin.ecuReported,
      evidence: EvidenceKind.fieldVerified,
      compatibility: Compatibility.exact,
      quality: DatumQuality.valid,
      operationRisk: OperationRisk.display,
      // The exported sentence with no code beside it: exactly the shape
      // `datumReasonText` used to render verbatim. Kept ASCII so the
      // no-Chinese assertion below cannot be what catches it — the dialog is
      // asserted not to contain it at all.
      reason: 'ASCII reason',
      reasonCode: null,
      formula: '(A*256+B)/4',
      assumptions: 'ASCII assumption',
      nextStep: DatumNextStep.otherReadingsUnaffected,
    );

    testWidgets('the English dialog chrome carries no Chinese', (tester) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: englishLocale,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDatumStatusDetails(
                  context,
                  title: 'Coolant temperature',
                  status: status,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final rendered = _renderedText(tester, find.byType(AlertDialog));
      expect(rendered, isNotEmpty);
      _expectNoChinese(rendered, where: 'the datum status dialog');
      // The exported sentence is not shown, whatever language it happens to be
      // written in. `datumReasonText` used to return it when no identifier was
      // set; an ASCII one would have slipped past the check above, which is why
      // this fixture's reason is ASCII and this line exists.
      expect(
        rendered,
        isNot(contains('ASCII reason')),
        reason: 'DatumStatus.reason is export-only and must not be rendered',
      );
    });

    test('the no-badge line never claims the value is good', () {
      // It says only that nothing was flagged. `DatumStatus` does not check a
      // value; reading this as "valid" or "OK" would turn the absence of a
      // warning into a positive claim about a car.
      expect(en.datumStatusFollowsData.toLowerCase(), isNot(contains('valid')));
      expect(en.datumStatusFollowsData.toLowerCase(), isNot(contains('ok')));
      expect(
        en.datumStatusFollowsData.toLowerCase(),
        isNot(contains('normal')),
      );
      for (final claim in ['有效', '正常', '無誤', '已驗證']) {
        expect(zh.datumStatusFollowsData, isNot(contains(claim)));
      }
    });
  });

  group('field event markers', () {
    test('every marker is answered in both languages', () {
      for (final marker in FieldEventMarker.values) {
        final english = fieldEventMarkerLabel(en, marker);
        final chinese = fieldEventMarkerLabel(zh, marker);
        expect(english.trim(), isNotEmpty, reason: '$marker en');
        expect(chinese.trim(), isNotEmpty, reason: '$marker zh');
        expect(
          _cjk.hasMatch(english),
          isFalse,
          reason: '$marker renders Chinese in English: "$english"',
        );
        expect(
          english,
          isNot(chinese),
          reason:
              '$marker is the same string twice — a missing zh entry falls '
              'back to the English template',
        );
      }
    });

    test('a memory-only record is never reported as saved', () {
      expect(en.fieldEventMemoryOnly, isNot(en.fieldEventRecorded('X')));
      expect(zh.fieldEventMemoryOnly, isNot(zh.fieldEventRecorded('X')));
      // The remedy is part of the sentence: the event exists only in RAM, so
      // exporting it now is the whole point of telling the user at all.
      expect(en.fieldEventMemoryOnly.toLowerCase(), contains('failed'));
      expect(en.fieldEventMemoryOnly.toLowerCase(), contains('export'));
      expect(zh.fieldEventMemoryOnly, contains('失敗'));
      expect(zh.fieldEventMemoryOnly, contains('匯出'));
      // "No connection to record against" is a third state, not a synonym for
      // either of the other two.
      expect(en.fieldEventUnavailable, isNot(en.fieldEventMemoryOnly));
      expect(zh.fieldEventUnavailable, isNot(zh.fieldEventMemoryOnly));
    });

    test('the instruction stays conditional in both languages', () {
      // "an immediate save is attempted" — not "is saved". The panel's own
      // failure path exists because it can fail.
      expect(en.fieldEventBody.toLowerCase(), contains('attempted'));
      expect(zh.fieldEventBody, contains('嘗試'));
      // And it stays a stopped-vehicle instruction.
      expect(en.fieldEventBody.toLowerCase(), contains('stopped'));
      expect(zh.fieldEventBody, contains('停妥'));
    });

    testWidgets('the English panel carries no Chinese', (tester) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: englishLocale,
          home: Scaffold(
            body: FieldEventMarkerPanel(
              enabled: true,
              onRecord: (_) async => FieldEventRecordResult.persisted,
            ),
          ),
        ),
      );
      _expectNoChinese(
        _renderedText(tester, find.byType(FieldEventMarkerPanel)),
        where: 'the field event marker panel',
      );

      await tester.tap(
        find.text(fieldEventMarkerLabel(en, FieldEventMarker.engineStarted)),
      );
      await tester.pumpAndSettle();
      _expectNoChinese(
        _renderedText(tester, find.byType(SnackBar)),
        where: 'the field event snackbar',
      );
    });
  });

  group('affiliate disclosure', () {
    // This is regulated copy, and it is the reason this group exists at all:
    // a disclosure translated weaker than it is written is a compliance
    // problem, not a style one. `recommended_purchases_test.dart` still pins
    // the Chinese constants, but the panel no longer renders them — these pin
    // the sentences the user is actually shown.
    test('English keeps every qualifier', () {
      final text = en.recommendedPurchaseDisclosure.toLowerCase();
      expect(text, contains('affiliate'));
      expect(text, contains('may pay'), reason: 'never "will pay"');
      expect(text, isNot(contains('will pay')));
      expect(text, contains('not an adapter certification'));
      expect(text, contains('purchase guarantee'));
      expect(text, contains('ncc'), reason: 'the approval number to check');
      expect(text, contains('model'));
      expect(
        en.recommendedPurchaseShortDisclosureLead.toLowerCase(),
        contains('not an adapter certification'),
      );
    });

    test('Chinese keeps every qualifier', () {
      final text = zh.recommendedPurchaseDisclosure;
      expect(text, contains('推廣分潤'), reason: 'not 推薦連結');
      expect(text, contains('可能'), reason: 'never 一定 / 會');
      expect(text, contains('不是轉接器認證'));
      expect(text, contains('購買保證'));
      expect(text, contains('NCC'));
      expect(text, contains('型號'));
      expect(zh.recommendedPurchaseShortDisclosureLead, contains('不是轉接器認證'));
    });

    testWidgets('the English panel carries no Chinese, store name included', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: englishLocale,
          home: const Scaffold(body: RecommendedPurchasePanel()),
        ),
      );
      _expectNoChinese(
        _renderedText(tester, find.byType(RecommendedPurchasePanel)),
        where: 'the recommended purchase panel',
      );
      // The catalog's own label is 蝦皮; the panel resolves it to the name the
      // same storefront publishes in English rather than passing it through.
      expect(find.textContaining('Shopee'), findsWidgets);
    });

    testWidgets('the English connect footer carries no Chinese', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: englishLocale,
          home: const Scaffold(body: RecommendedPurchaseLink()),
        ),
      );
      _expectNoChinese(
        _renderedText(tester, find.byType(RecommendedPurchaseLink)),
        where: 'the recommended purchase link footer',
      );
    });

    testWidgets('the Chinese panel keeps the store its readers know', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          locale: traditionalChineseLocale,
          home: const Scaffold(body: RecommendedPurchasePanel()),
        ),
      );
      expect(find.textContaining('蝦皮'), findsWidgets);
      expect(find.textContaining('推廣分潤'), findsOneWidget);
    });

    test('every storefront in the enum has a name in both languages', () {
      // This replaced 'an unlocalized storefront keeps its own name rather
      // than a guess', which built a `RecommendedPurchase` with
      // `storeLabel: 'Example Store'` and checked that the panel echoed it
      // back. That fallback was protecting against one thing — a store
      // rendered under another store's name — and it cannot happen any more:
      // `RecommendedStore` is an enum and `recommendedStoreLabel` switches on
      // it exhaustively, so a second storefront does not compile until the
      // switch names it. What the compiler still cannot see is a name that is
      // empty, or two stores pointed at the same ARB entry, so that is what is
      // asserted here.
      //
      // One enum value is enough for the switch to be exhaustive and for this
      // loop to run zero times, so the emptiness check is not ceremony: with a
      // hypothetical empty enum every assertion below is satisfied by nothing
      // existing, and a green run would mean the catalog had lost its stores
      // rather than that their names are sound.
      expect(
        RecommendedStore.values,
        isNotEmpty,
        reason: 'with no storefronts the loop below asserts nothing, and this '
            'test would report success for an app that can no longer name a '
            'shop at all',
      );
      // Per language, not English only. An earlier version kept one map keyed
      // on the English name and justified it with "the two languages are
      // allowed to agree on a store that publishes one name worldwide" — which
      // is about one store's `en` matching its own `zh`, and says nothing about
      // whether two *different* stores collide. They can collide in one
      // language and not the other: 蝦皮 and momo are separate shops in Taiwan
      // whose ARB entries are separate strings, and a Chinese-only clash sends
      // a Chinese reader to the wrong shop while the English build looks fine.
      final seen = <String, Map<String, RecommendedStore>>{
        'English': {},
        'Chinese': {},
      };
      for (final store in RecommendedStore.values) {
        final purchase = RecommendedPurchase(
          id: 'probe',
          store: store,
          productLabel: 'Example',
          url: 'https://example.test/',
          model: 'X',
          radioApproval: 'Y',
        );
        for (final (language, l10n) in [('English', en), ('Chinese', zh)]) {
          final name = recommendedStoreLabel(l10n, purchase);
          expect(
            name.trim(),
            isNotEmpty,
            reason: '$store has no $language name, so the store CTA reads '
                '"View on " with nothing after it',
          );
          final clash = seen[language]![name];
          expect(
            clash,
            isNull,
            reason: '$store and $clash both render as "$name" in $language, so '
                'that reader is told to buy from a shop that is not the one '
                'the link opens',
          );
          seen[language]![name] = store;
        }
      }
    });
  });

  group('language picker', () {
    // The one screen where a hard-coded language name is correct. Somebody
    // opening it usually cannot read the language currently on screen, so each
    // option names itself: translating them would hide the row they came for.
    for (final entry in {
      'English': englishLocale,
      'Chinese': traditionalChineseLocale,
    }.entries) {
      testWidgets('both self-names are readable under ${entry.key}', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: localizedMaterialApp(
              locale: entry.value,
              home: const Scaffold(body: LanguagePicker()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('English'), findsOneWidget);
        expect(find.text('繁體中文'), findsOneWidget);
        expect(find.text('System default / 跟隨系統'), findsOneWidget);
      });
    }
  });
}
