/// The connect screen in both languages.
///
/// This screen is the app's front door and the one four separate people on
/// r/CarHacking asked about, so a wrong translation here is not a cosmetic
/// defect — it is the first and sometimes only thing a user reads.
///
/// What these check is deliberately NOT "does this string equal its ARB
/// entry": a finder that reads the same ARB the widget rendered agrees with
/// itself and passes on a translation that says the opposite of the English.
/// They check the properties a wrong translation breaks:
///
///   * the English render carries no Chinese;
///   * every branch of every context-free guidance function answers in both
///     languages, and the two answers are actually different copy;
///   * the transport advice stays technically true in both languages — BLE is
///     never paired, Classic always is;
///   * limits and counts come from the constants through placeholders, so the
///     sentence cannot quote a bound the code does not enforce.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import '../support/localized_app.dart';
import '../support/cjk.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

/// Every string the guidance functions can produce, labelled by the branch
/// that produced it, so a failure names the branch rather than the value.
Map<String, String> _allGuidance(AppLocalizations l10n) {
  final out = <String, String>{
    'bleUnavailableReason': bleUnavailableReason(l10n),
    // Platform-dependent, so only the branch this host takes is reachable.
    'classicUnavailableReason': classicUnavailableReason(l10n),
  };
  for (final phone in [true, false]) {
    out['wifiConnectInstructions(isPhone: $phone)'] = wifiConnectInstructions(
      l10n,
      isPhone: phone,
    );
  }
  for (final classic in [true, false]) {
    out['bleEmptyScanGuidance(classicAvailable: $classic)'] =
        bleEmptyScanGuidance(l10n, classicAvailable: classic);
  }
  for (final serial in [true, false]) {
    for (final linux in [true, false]) {
      final where = 'serialHost: $serial, linuxHost: $linux';
      out['classicDeviceListEmptyHint($where)'] = classicDeviceListEmptyHint(
        l10n,
        serialHost: serial,
        linuxHost: linux,
      );
      out['classicDeviceListHint($where)'] = classicDeviceListHint(
        l10n,
        serialHost: serial,
        linuxHost: linux,
      );
    }
  }
  for (final classic in [true, false]) {
    for (final ble in [true, false]) {
      for (final phone in [true, false]) {
        final where = 'classic: $classic, ble: $ble, phone: $phone';
        final rows = whichTransportGuidance(
          l10n,
          classicAvailable: classic,
          bleAvailable: ble,
          phoneCentricCopy: phone,
        );
        for (final row in rows) {
          out['whichTransportGuidance($where).${row.transport.name}.question'] =
              row.question;
          out['whichTransportGuidance($where).${row.transport.name}.answer'] =
              row.answer;
        }
      }
    }
  }
  return out;
}

({String ble, String classic}) _pairingAnswers(
  AppLocalizations l10n, {
  required bool classicAvailable,
}) {
  final rows = whichTransportGuidance(
    l10n,
    classicAvailable: classicAvailable,
  );
  return (
    ble: rows
        .firstWhere((r) => r.transport == TransportKind.bluetoothLe)
        .answer,
    classic: classicAvailable
        ? rows
              .firstWhere(
                (r) => r.transport == TransportKind.bluetoothClassic,
              )
              .answer
        : '',
  );
}

Future<void> _pumpConnect(WidgetTester tester, Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // The root share policy is fail-closed; production overrides it in
        // main(). Without this the denied panel pushes the transport list
        // below the fold and the sliver builder never reaches it.
        appSharePolicyProvider.overrideWith(
          (ref) => ref.watch(productionAppSharePolicyProvider),
        ),
      ],
      child: localizedMaterialApp(home: const ConnectScreen(), locale: locale),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = text.data ?? text.textSpan?.toPlainText() ?? '';
    if (value.isNotEmpty) out.add(value);
  }
  for (final semantics in tester.widgetList<Semantics>(find.byType(Semantics))) {
    final label = semantics.properties.label;
    if (label != null && label.isNotEmpty) out.add(label);
  }
  return out;
}

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('the English render carries no Chinese', () {
    testWidgets('connect screen at Locale(en)', (tester) async {
      await _pumpConnect(tester, englishLocale);

      // One source of Chinese on this screen is not this screen's to fix, and
      // is excluded by where it comes from rather than by its text:
      // `languageSectionTitle` is deliberately bilingual and byte-identical in
      // both ARBs — it is how a reader who cannot read the current language
      // finds the picker.
      //
      // `TransportKind.label` and `.description` used to be excluded here too.
      // They are not any more: the tile titles and subtitles now come from
      // `transportKindTitle` / `transportKindDescription`, so this assertion
      // covers them, and putting `kind.label` back into a `Text` widget turns
      // this test red — which is the point of dropping the exclusion rather
      // than leaving a hole that nothing fills.
      final foreign = <String>{en.languageSectionTitle};

      final offenders = _renderedStrings(
        tester,
      ).where((s) => !foreign.contains(s) && _cjk.hasMatch(s)).toSet();

      expect(
        offenders,
        isEmpty,
        reason:
            'these render Chinese to an English-speaking driver:\n'
            '${offenders.join("\n")}',
      );
    });

    test('and neither does any branch of the guidance functions', () {
      final offenders = <String>[];
      _allGuidance(en).forEach((where, value) {
        if (_cjk.hasMatch(value)) offenders.add('$where → "$value"');
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('every branch answers in both languages', () {
    test('nothing is empty', () {
      for (final entry in {'en': en, 'zh': zh}.entries) {
        _allGuidance(entry.value).forEach((where, value) {
          expect(
            value.trim(),
            isNotEmpty,
            reason: '${entry.key}: $where is empty',
          );
        });
      }
    });

    test('and the two languages are different copy, not one copied twice', () {
      // The failure gen-l10n does not report: a missing zh entry falls back to
      // the English template, so the screen looks translated and is not.
      final english = _allGuidance(en);
      final chinese = _allGuidance(zh);
      final same = <String>[];
      for (final where in english.keys) {
        if (english[where] == chinese[where]) same.add(where);
      }
      expect(
        same,
        isEmpty,
        reason: 'identical in both languages, so one of them is untranslated:\n'
            '${same.join("\n")}',
      );
    });
  });

  group('the transport advice stays technically true in both languages', () {
    // A GATT device is not bonded the way a Classic one is. Telling somebody
    // to pair a BLE adapter routes them into a dead end their own adapter
    // manual warns about, and it is the exact mistake this card was rewritten
    // to stop making.
    test('BLE is never paired, in either language', () {
      for (final classic in [true, false]) {
        expect(
          _pairingAnswers(en, classicAvailable: classic).ble,
          contains('do not pair'),
          reason: 'en, classicAvailable: $classic',
        );
        expect(
          _pairingAnswers(zh, classicAvailable: classic).ble,
          contains('不要去配對'),
          reason: 'zh, classicAvailable: $classic',
        );
      }
      expect(en.connectBleBody, contains('does not need to be paired'));
      expect(zh.connectBleBody, contains('不需事先配對'));
    });

    test('Classic always is, in either language', () {
      final english = _pairingAnswers(en, classicAvailable: true).classic;
      final chinese = _pairingAnswers(zh, classicAvailable: true).classic;
      expect(english, contains('Pair it in system settings first'));
      expect(english, isNot(contains('do not pair')));
      expect(chinese, contains('先在系統設定裡配對完成'));
      expect(chinese, isNot(contains('不要去配對')));
    });

    test('an empty BLE scan names power and range, not a verdict', () {
      // The commonest cause by a distance is an unpowered adapter on a
      // switched socket, and it is invisible from a blank panel. An empty scan
      // is not evidence that no adapter exists.
      for (final classic in [true, false]) {
        final english = bleEmptyScanGuidance(en, classicAvailable: classic);
        expect(english, contains('ignition'));
        expect(english, contains('range'));
        final chinese = bleEmptyScanGuidance(zh, classicAvailable: classic);
        expect(chinese, contains('電門'));
        expect(chinese, contains('距離'));
      }
    });

    test('an empty port list is a system state, not a broken app', () {
      for (final linux in [true, false]) {
        expect(
          classicDeviceListHint(en, serialHost: true, linuxHost: linux),
          contains('not that the app is broken'),
        );
        expect(
          classicDeviceListHint(zh, serialHost: true, linuxHost: linux),
          contains('不是 App 壞掉'),
        );
      }
    });

    test('the handshake panel says which attempt it describes', () {
      // A green step list above a red disconnected banner contradicts itself.
      // The past-tense title is the only thing that separates them.
      for (final entry in {'en': en, 'zh': zh}.entries) {
        final l10n = entry.value;
        expect(
          l10n.connectHandshakeTitleLastAttempt,
          isNot(l10n.connectHandshakeTitle),
          reason: entry.key,
        );
        expect(
          l10n.connectHandshakeTitleLastAttempt,
          contains(l10n.connectHandshakeTitle),
          reason: '${entry.key}: it is the same panel, qualified',
        );
      }
    });

    test('the Classic host list is hedged as current, not permanent', () {
      // The host list has changed twice already. iOS is the only permanent
      // limit on it, and it is a separate string.
      expect(en.connectClassicUnavailableHost, contains('currently'));
      expect(zh.connectClassicUnavailableHost, contains('目前'));
      expect(en.connectClassicUnavailableIos, isNot(contains('currently')));
      expect(zh.connectClassicUnavailableIos, isNot(contains('目前')));
    });
  });

  group('limits come from the constants, never from the prose', () {
    test('the Wi-Fi port range is a placeholder', () {
      for (final l10n in [en, zh]) {
        expect(l10n.connectWifiPortInvalid('x', 1, 65535), contains('65535'));
        // The proof: a different bound produces a different sentence. A
        // hard-coded 65535 in the copy would survive this.
        expect(
          l10n.connectWifiPortInvalid('x', 7, 9),
          isNot(contains('65535')),
        );
        expect(l10n.connectWifiPortInvalid('nope', 1, 65535), contains('nope'));
      }
    });

    test('the default port is a placeholder', () {
      for (final l10n in [en, zh]) {
        expect(l10n.connectWifiPortRequired(35000), contains('35000'));
        expect(l10n.connectWifiPortRequired(1234), isNot(contains('35000')));
      }
    });

    test('the signal meter quotes the bars it draws', () {
      for (final l10n in [en, zh]) {
        expect(l10n.connectSignalStrength(1, 4), contains('1/4'));
        expect(l10n.connectSignalStrength(3, 5), contains('3/5'));
      }
    });
  });

  testWidgets('the Chinese render keeps the load-bearing hedges', (
    tester,
  ) async {
    await _pumpConnect(tester, traditionalChineseLocale);

    // The disclosure accepts the user's uncertainty rather than demanding a
    // confident choice, which is the whole reason it exists.
    final title = find.text(zh.connectWhichTitle);
    expect(title, findsOneWidget);
    await tester.tap(title);
    await tester.pumpAndSettle();

    final rendered = _renderedStrings(tester);

    // Permission to fail. Without it the fear of picking wrong is what makes
    // somebody close the app instead of tapping something.
    expect(rendered, contains(zh.connectWhichNoteGuessing));
    expect(zh.connectWhichNoteGuessing, contains('猜錯不會怎麼樣'));

    // And the BLE row on screen still says not to pair it.
    final bleAnswer = _pairingAnswers(
      zh,
      classicAvailable: classicTransportAvailable,
    ).ble;
    expect(rendered, contains(bleAnswer));
    expect(bleAnswer, contains('不要去配對'));
  });
}
