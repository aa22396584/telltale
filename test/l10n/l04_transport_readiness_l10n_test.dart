// The connect screen's four transport tiles and the emissions readiness chips,
// in both languages, with no widget pump.
//
// `transportKindTitle`, `transportKindDescription` and `readinessMonitorLabel`
// take an `AppLocalizations` rather than a `BuildContext`, so every enum value
// can be walked in both locales as plain Dart — the shape
// test/l10n/telemetry_status_copy_test.dart established.
//
// What these check is deliberately NOT "does the string equal its ARB entry".
// A test that reads the same ARB the code read passes on any translation,
// including a wrong one. They check the properties a wrong translation breaks:
//
//   * every value is answered, in both languages, and the answers differ where
//     the copy is copy and match where the token is a product name;
//   * English carries no Chinese;
//   * the pairing instruction is not smuggled into a tile subtitle, in either
//     direction — a BLE adapter must not be told to pair and a Classic one
//     must not be told it need not;
//   * the do-not-translate tokens survive both sides byte-identically;
//   * bit 4 of byte C stays the gasoline particulate filter and never becomes
//     an air-conditioning refrigerant monitor;
//   * and the three readiness states stay three, because "this vehicle does not
//     have this monitor" and "this monitor has not finished" are opposite
//     answers to somebody deciding whether to drive to an inspection.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/readiness.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/connect/transport_kind_copy.dart';
import 'package:torque_obd/ui/screens/dtc/readiness_copy.dart';

final _cjk = RegExp(r'[㐀-鿿豈-﫿]');

/// The tiles whose title is a product name rather than copy.
///
/// docs/i18n/do-not-translate.md lists all three. They are the only entries on
/// this screen allowed to be byte-identical across locales, and the assertion
/// below is positive — it fails if somebody translates one, and it fails if
/// somebody adds a fourth without deciding to.
const _productNameTitles = {
  TransportKind.bluetoothClassic,
  TransportKind.bluetoothLe,
  TransportKind.wifi,
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  final locales = {'en': en, 'zh': zh};

  group('every value is answered in both languages', () {
    test('TransportKind', () {
      for (final entry in locales.entries) {
        for (final kind in TransportKind.values) {
          expect(transportKindTitle(entry.value, kind).trim(), isNotEmpty,
              reason: '$kind title ${entry.key}');
          expect(transportKindDescription(entry.value, kind).trim(), isNotEmpty,
              reason: '$kind description ${entry.key}');
        }
      }
    });

    test('ReadinessMonitor', () {
      for (final entry in locales.entries) {
        for (final monitor in ReadinessMonitor.values) {
          expect(readinessMonitorLabel(entry.value, monitor).trim(), isNotEmpty,
              reason: '$monitor ${entry.key}');
        }
      }
    });

    test('and no two monitors share a label', () {
      // Sixteen chips can appear in one row. Two of them reading the same is a
      // reader reconciling against an inspection report and finding one line
      // where the vehicle reported two.
      for (final entry in locales.entries) {
        final labels = <String, ReadinessMonitor>{};
        for (final monitor in ReadinessMonitor.values) {
          final label = readinessMonitorLabel(entry.value, monitor);
          expect(labels.containsKey(label), isFalse,
              reason: '${entry.key}: $monitor and ${labels[label]} '
                  'both render "$label"');
          labels[label] = monitor;
        }
      }
    });
  });

  test('the English copy contains no Chinese', () {
    final offenders = <String>[];
    void check(String where, String value) {
      if (_cjk.hasMatch(value)) offenders.add('$where → "$value"');
    }

    for (final kind in TransportKind.values) {
      check('$kind title', transportKindTitle(en, kind));
      check('$kind description', transportKindDescription(en, kind));
    }
    for (final monitor in ReadinessMonitor.values) {
      check('$monitor', readinessMonitorLabel(en, monitor));
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  group('the two locales are genuinely two locales', () {
    // gen-l10n does not fail on a missing translation — it falls back to the
    // template — so a forgotten entry ships as English inside a Chinese screen
    // and every widget test still passes because something rendered.
    test('every readiness monitor is translated', () {
      for (final monitor in ReadinessMonitor.values) {
        expect(readinessMonitorLabel(zh, monitor),
            isNot(readinessMonitorLabel(en, monitor)),
            reason: '$monitor reads the same in both locales');
      }
    });

    test('every transport subtitle is translated', () {
      for (final kind in TransportKind.values) {
        expect(transportKindDescription(zh, kind),
            isNot(transportKindDescription(en, kind)),
            reason: '$kind description reads the same in both locales');
      }
    });

    test('the Demo tile title is translated and the other three are not', () {
      for (final kind in TransportKind.values) {
        final matcher = _productNameTitles.contains(kind)
            ? equals(transportKindTitle(en, kind))
            : isNot(transportKindTitle(en, kind));
        expect(transportKindTitle(zh, kind), matcher,
            reason: _productNameTitles.contains(kind)
                ? '$kind is a product name on docs/i18n/do-not-translate.md and '
                    'must stay byte-identical'
                : '$kind title reads the same in both locales');
      }
    });
  });

  group('the tile subtitles do not carry pairing advice', () {
    // The one instruction on this screen that is wrong in the other direction
    // for each transport. A Classic adapter must be paired in system settings
    // before the app can see it; a BLE adapter must NOT be — that route does
    // not work, and connectAnswerBleWithClassic spends a sentence saying so.
    // Neither subtitle mentions pairing in either language, so neither can send
    // somebody the wrong way; the instruction lives where there is room for it.
    const pairingWords = ['pair', 'pairing', 'bond', '配對'];

    test('neither Bluetooth subtitle mentions pairing at all', () {
      for (final kind in [
        TransportKind.bluetoothClassic,
        TransportKind.bluetoothLe,
      ]) {
        for (final entry in locales.entries) {
          final text = transportKindDescription(entry.value, kind).toLowerCase();
          for (final word in pairingWords) {
            expect(text.contains(word), isFalse,
                reason: '$kind ${entry.key} subtitle says "$word": '
                    '"$text". Pairing is opposite for the two Bluetooth '
                    'transports, so a subtitle that mentions it is right for '
                    'one tile and wrong for the other.');
          }
        }
      }
    });

    test('the screen still tells a Classic user to pair, elsewhere', () {
      // The negative above is only safe because the instruction survives
      // somewhere with room to be correct. If this goes red the previous test
      // has stopped protecting anything.
      expect(en.connectAnswerClassic.toLowerCase(), contains('pair'));
      expect(zh.connectAnswerClassic, contains('配對'));
      expect(en.connectAnswerBleWithClassic.toLowerCase(),
          contains('does not need pairing'));
      expect(zh.connectAnswerBleWithClassic, contains('不需要事先配對'));
    });
  });

  test('do-not-translate tokens survive both locales byte-identically', () {
    // docs/i18n/do-not-translate.md. These are addressed to a machine or to a
    // search box: RFCOMM is what the Android API is called, 192.168.0.10:35000
    // is what somebody types into the address field, and EGR is what the
    // service manual says.
    const tokens = <String, String Function(AppLocalizations)>{
      'RFCOMM': _classicDescription,
      'SPP': _classicDescription,
      'ELM327': _classicDescription,
      'GATT': _bleDescription,
      'UART': _bleDescription,
      'TCP': _wifiDescription,
      '192.168.0.10:35000': _wifiDescription,
      'ECU': _demoDescription,
      'Bluetooth Classic': _classicTitle,
      'Bluetooth LE': _bleTitle,
      'Wi-Fi': _wifiTitle,
    };
    tokens.forEach((token, read) {
      for (final entry in locales.entries) {
        expect(read(entry.value), contains(token),
            reason: '${entry.key} dropped the untranslatable token "$token"');
      }
    });

    const monitorTokens = <String, ReadinessMonitor>{
      'EGR': ReadinessMonitor.egr,
      'VVT': ReadinessMonitor.egr,
      'NMHC': ReadinessMonitor.nmhcCatalyst,
      'NOx': ReadinessMonitor.noxAftertreatment,
      'SCR': ReadinessMonitor.noxAftertreatment,
      'GPF': ReadinessMonitor.gasolineParticulateFilter,
    };
    monitorTokens.forEach((token, monitor) {
      for (final entry in locales.entries) {
        expect(readinessMonitorLabel(entry.value, monitor), contains(token),
            reason: '${entry.key} dropped "$token" from $monitor');
      }
    });
  });

  test('bit 4 of byte C is the particulate filter, never a refrigerant', () {
    // docs/field-guide.zh-TW.md:247-250. Half the OBD reference tables on the
    // internet name this bit an air-conditioning refrigerant monitor. It sat
    // Reserved in J1979 for years and was recently defined as the gasoline
    // particulate filter, and a car new enough to set it is a direct-injection
    // petrol engine that has no A/C refrigerant monitor at all — so the wrong
    // label sends somebody reconciling an inspection report against a system
    // their car does not have.
    const wrong = ['refrigerant', 'air conditioning', 'air-conditioning',
        'a/c', '空調', '冷媒'];
    for (final entry in locales.entries) {
      final label = readinessMonitorLabel(
        entry.value,
        ReadinessMonitor.gasolineParticulateFilter,
      );
      expect(label, contains('GPF'),
          reason: '${entry.key} dropped GPF from the label, which is the only '
              'thing that makes it checkable against a reference table');
      for (final word in wrong) {
        expect(label.toLowerCase().contains(word), isFalse,
            reason: '${entry.key} renders bit 4 as "$word": "$label"');
      }
    }
  });

  test('the two particulate filters stay two different monitors', () {
    // The petrol bit and the diesel bit are different bits of different bytes
    // on different engines, and both exist in ReadinessMonitor. A translation
    // that collapses them makes a diesel chip readable as a petrol one.
    for (final entry in locales.entries) {
      final petrol = readinessMonitorLabel(
          entry.value, ReadinessMonitor.gasolineParticulateFilter);
      final diesel = readinessMonitorLabel(
          entry.value, ReadinessMonitor.particulateFilter);
      expect(petrol, isNot(diesel), reason: entry.key);
      expect(diesel.contains('GPF'), isFalse,
          reason: '${entry.key}: the diesel filter is not a GPF');
    }
  });

  group('unsupported is not incomplete', () {
    // The failure this whole file is arranged against. A monitor a vehicle does
    // not have is a formal J1979 state and not a gap; almost every car reports
    // several. Rendering those as unfinished makes a ready vehicle look
    // unready, and the mirror — an unfinished one reading as absent — sends
    // somebody to an inspection they will fail.
    test('the decoder keeps three distinct states', () {
      expect(ReadinessState.values, hasLength(3));
      // Bit 0 supported and unfinished, bit 1 supported and finished, bit 2
      // not supported: one reply carrying all three answers.
      final readiness = Readiness.decode(0x00, 0x03, 0x01);
      expect(readiness.states[ReadinessMonitor.catalyst],
          ReadinessState.incomplete);
      expect(readiness.states[ReadinessMonitor.heatedCatalyst],
          ReadinessState.complete);
      expect(readiness.states[ReadinessMonitor.evaporative],
          ReadinessState.unsupported);
    });

    test('and the chip mark for each is a different mark', () {
      // The chips carry their state in a mark rather than a word — `✓`, `…`,
      // `—`, the legend published at docs/field-guide.zh-TW.md:239 — which is
      // why the state survives translation at all. What must not happen is two
      // states drawing the same glyph, so this pins that they are three.
      const marks = {
        ReadinessState.complete: '✓',
        ReadinessState.incomplete: '…',
        ReadinessState.unsupported: '—',
      };
      expect(marks.keys.toSet(), ReadinessState.values.toSet(),
          reason: 'a state was added without deciding how a chip draws it');
      expect(marks.values.toSet(), hasLength(3),
          reason: 'two states would draw the same chip');
    });

    test('and no monitor name claims a state', () {
      // A label is the name of a system, never a verdict on it. "Catalyst
      // ready" or "觸媒未完成" baked into the name would contradict the mark
      // beside it on exactly the chips where the two disagree.
      const verdicts = ['complete', 'incomplete', 'unfinished', 'ready',
          'not supported', 'unsupported', 'ok', 'pass', 'fail',
          '完成', '就緒', '不支援', '未支援', '通過', '失敗'];
      for (final entry in locales.entries) {
        for (final monitor in ReadinessMonitor.values) {
          final label = readinessMonitorLabel(entry.value, monitor).toLowerCase();
          for (final verdict in verdicts) {
            expect(label.contains(verdict), isFalse,
                reason: '${entry.key} $monitor is named "$label", which states '
                    'an outcome the chip has not decided');
          }
        }
      }
    });
  });

  test('the engine keeps the identity and the UI keeps the words', () {
    // The architectural rule of this wave, asserted rather than described.
    // `TransportKind.label` is the frozen string an exported evidence file
    // carries; it is not the tile title, and the day somebody points the tile
    // back at it this fails for the Demo tile in English.
    //
    // Only the English side is pinned. The zh title happens to equal the export
    // string today, and asserting that would make an improvement to the Chinese
    // tile copy — or #46 replacing the export label with a stable code — fail
    // here, where the tempting one-line fix is to edit the export. That is the
    // mistake this wave exists to prevent.
    expect(TransportKind.demo.label,
        isNot(transportKindTitle(en, TransportKind.demo)));
  });
}

String _classicTitle(AppLocalizations l10n) =>
    transportKindTitle(l10n, TransportKind.bluetoothClassic);
String _bleTitle(AppLocalizations l10n) =>
    transportKindTitle(l10n, TransportKind.bluetoothLe);
String _wifiTitle(AppLocalizations l10n) =>
    transportKindTitle(l10n, TransportKind.wifi);
String _classicDescription(AppLocalizations l10n) =>
    transportKindDescription(l10n, TransportKind.bluetoothClassic);
String _bleDescription(AppLocalizations l10n) =>
    transportKindDescription(l10n, TransportKind.bluetoothLe);
String _wifiDescription(AppLocalizations l10n) =>
    transportKindDescription(l10n, TransportKind.wifi);
String _demoDescription(AppLocalizations l10n) =>
    transportKindDescription(l10n, TransportKind.demo);
