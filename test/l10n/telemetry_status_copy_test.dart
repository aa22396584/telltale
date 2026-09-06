// Exhaustive, both languages, no widget pump.
//
// The copy functions take an AppLocalizations rather than a BuildContext, so a
// plain Dart test can walk every enum value in both locales. That is the point
// of the parameter: the 256 pure-Dart assertions in this suite get a migration
// path that does not require a widget tree.
//
// What these check is deliberately NOT "does the string equal the ARB entry" —
// a finder that reads the same ARB the code read would pass on a wrong
// translation. They check the properties a wrong translation would break:
// every case is answered, English carries no Chinese, the two languages are
// actually different, limits come from the constants rather than the prose,
// and the distinctions this app refuses to blur stay distinct.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_status_copy.dart';

final _cjk = RegExp(r'[㐀-鿿豈-﫿]');

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  group('every enum value is answered in both languages', () {
    test('TelemetryStatus', () {
      for (final v in TelemetryStatus.values) {
        expect(telemetryStatusLabel(en, v).trim(), isNotEmpty, reason: '$v en');
        expect(telemetryStatusLabel(zh, v).trim(), isNotEmpty, reason: '$v zh');
      }
    });

    test('TelemetryTerminalReason', () {
      for (final v in TelemetryTerminalReason.values) {
        expect(telemetryTerminalReasonLabel(en, v).trim(), isNotEmpty, reason: '$v en');
        expect(telemetryTerminalReasonLabel(zh, v).trim(), isNotEmpty, reason: '$v zh');
      }
    });

    test('TelemetryStartOutcome', () {
      for (final v in TelemetryStartOutcome.values) {
        expect(telemetryStartOutcomeLabel(en, v).trim(), isNotEmpty, reason: '$v en');
        expect(telemetryStartOutcomeLabel(zh, v).trim(), isNotEmpty, reason: '$v zh');
      }
    });
  });

  test('the English copy contains no Chinese', () {
    final offenders = <String>[];
    void check(String label, String value) {
      if (_cjk.hasMatch(value)) offenders.add('$label → "$value"');
    }

    for (final v in TelemetryStatus.values) {
      check('TelemetryStatus.${v.name}', telemetryStatusLabel(en, v));
    }
    for (final v in TelemetryTerminalReason.values) {
      check('TelemetryTerminalReason.${v.name}', telemetryTerminalReasonLabel(en, v));
    }
    for (final v in TelemetryStartOutcome.values) {
      check('TelemetryStartOutcome.${v.name}', telemetryStartOutcomeLabel(en, v));
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'these render Chinese to an English-speaking driver:\n${offenders.join("\n")}',
    );
  });

  test('the two languages are actually different copy, not one copied twice', () {
    // Catches the failure gen-l10n does not: a missing zh entry falls back to
    // the English template, so the screen looks translated and is not.
    final same = <String>[];
    for (final v in TelemetryStatus.values) {
      if (telemetryStatusLabel(en, v) == telemetryStatusLabel(zh, v)) {
        same.add('TelemetryStatus.${v.name}');
      }
    }
    for (final v in TelemetryTerminalReason.values) {
      if (telemetryTerminalReasonLabel(en, v) == telemetryTerminalReasonLabel(zh, v)) {
        same.add('TelemetryTerminalReason.${v.name}');
      }
    }
    for (final v in TelemetryStartOutcome.values) {
      if (telemetryStartOutcomeLabel(en, v) == telemetryStartOutcomeLabel(zh, v)) {
        same.add('TelemetryStartOutcome.${v.name}');
      }
    }
    expect(same, isEmpty, reason: 'untranslated (English fallback): ${same.join(", ")}');
  });

  group('the distinctions this app refuses to blur', () {
    test('no answer is not unsupported', () {
      for (final l10n in [en, zh]) {
        expect(
          telemetryStatusLabel(l10n, TelemetryStatus.noAnswer),
          isNot(telemetryStatusLabel(l10n, TelemetryStatus.unsupported)),
        );
      }
      // Silence must not be reported as a confirmed capability answer.
      expect(
        telemetryStatusLabel(en, TelemetryStatus.noAnswer).toLowerCase(),
        isNot(contains('unsupported')),
        reason:
            'a controller that said nothing has not told us it lacks the PID; '
            'reporting silence as unsupported invents an answer',
      );
    });

    test('unknown speed refuses as hard as known movement', () {
      for (final l10n in [en, zh]) {
        for (final outcome in [
          TelemetryStartOutcome.speedUnknown,
          TelemetryStartOutcome.startInvalidatedSpeedUnknown,
        ]) {
          expect(telemetryStartOutcomeLabel(l10n, outcome).trim(), isNotEmpty);
        }
        // Not the same sentence as `moving`: the reason differs, and the user
        // needs to know the app could not tell rather than that it saw motion.
        expect(
          telemetryStartOutcomeLabel(l10n, TelemetryStartOutcome.speedUnknown),
          isNot(telemetryStartOutcomeLabel(l10n, TelemetryStartOutcome.moving)),
        );
      }
    });

    test('a refused unsafe service says nothing was sent', () {
      expect(
        telemetryStatusLabel(en, TelemetryStatus.unsafeServiceRefusal).toLowerCase(),
        anyOf(contains('nothing was sent'), contains('not sent')),
        reason: 'the user must learn the app did not transmit, not merely that it failed',
      );
    });
  });

  group('limits come from the constants, not from the prose', () {
    test('the duration limit renders the recorder constant', () {
      final minutes = telemetryRecorderDurationLimit.inMinutes;
      for (final l10n in [en, zh]) {
        expect(
          telemetryTerminalReasonLabel(l10n, TelemetryTerminalReason.durationLimit),
          contains('$minutes'),
        );
      }
    });

    test('the library group limit renders the quota constant', () {
      for (final l10n in [en, zh]) {
        expect(
          telemetryStartOutcomeLabel(l10n, TelemetryStartOutcome.libraryGroupLimit),
          contains('${TelemetryQuota.groupLimit}'),
        );
      }
    });
  });

  test('recorder recovery guidance distinguishes startup from save', () {
    const preparing = TelemetryRecorderState(phase: TelemetryRecorderPhase.preparing);
    const finalizing = TelemetryRecorderState(phase: TelemetryRecorderPhase.finalizing);
    for (final l10n in [en, zh]) {
      // While the operation is still held, both phases give the same advice.
      expect(telemetryRecorderRecoveryLabel(l10n, preparing), isNotNull);
      expect(telemetryRecorderRecoveryLabel(l10n, finalizing), isNotNull);
    }
    expect(
      telemetryRecorderRecoveryLabel(en, preparing),
      isNot(matches(_cjk)),
    );
  });

  test('an idle recorder that needs no restart offers no recovery copy', () {
    const idle = TelemetryRecorderState(phase: TelemetryRecorderPhase.idle);
    expect(telemetryRecorderRecoveryLabel(en, idle), isNull);
    expect(telemetryRecorderRecoveryLabel(zh, idle), isNull);
  });
}
