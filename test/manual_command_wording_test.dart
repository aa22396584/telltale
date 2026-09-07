/// What the manual command box actually puts on the screen.
///
/// `manual_command_test.dart` pins which commands are refused and which
/// identifier each refusal carries. `test/l10n/manual_command_copy_test.dart`
/// pins the sentence each identifier renders. This file pins the join: what
/// comes out of the function the panel actually calls, for an exception built
/// the way the session builds it.
///
/// The defect it was written for: the handler stringified the exception, so
/// every refusal arrived as `TransportException: 清除故障碼請用…` — a Dart class
/// name in English in front of a Chinese sentence, on the one screen somebody
/// opens when they are already unsure whether the app is working. The app had
/// fixed exactly this once before, for handshake failures, where the note in
/// `elm327_client.dart` says: "The sentence, not the identifier." The manual
/// box was the copy that got missed, and nothing could see it because no test
/// looked at the rendered string. Found by typing `04` into the box on a
/// Galaxy S24 Ultra and reading the screen.
///
/// The second defect, which this file could not see until the refusals became
/// identifiers: the sentence it asserted on was Traditional Chinese in every
/// language the app ships. Asserting that the screen shows the engine's own
/// string is exactly the property that has to stop being true, so the
/// assertions here are now about the reader's language rather than about the
/// engine's.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/manual_command_refusal.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

import 'support/cjk.dart';

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  String shown(AppLocalizations l10n, Object error) =>
      SettingsScreen.describeManualFailure(l10n, error);

  test('every refusal shows a sentence, not its Dart type', () {
    // Each refusal this box can produce, thrown the way `sendManualCommand`
    // throws it and rendered the way the screen renders it. Mode 04 is the one
    // somebody is likeliest to try from here.
    for (final command in ['04', 'ATZ', 'ZZ', '03\r04', '08', '']) {
      final why = manualCommandRefusal(command);
      expect(why, isNotNull, reason: command);
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final text = shown(l10n, ManualCommandRefusedException(why!));
        expect(text.trim(), isNotEmpty, reason: '$name: $command');
        expect(text, isNot(contains('Exception')), reason: '$name: $command');
        expect(
          text,
          isNot(contains('ManualCommandRefused')),
          reason: '$name: $command',
        );
      }
    }
  });

  test('and in an English build the sentence is English', () {
    // The half the old version of this file could not have: it asserted that
    // the screen showed the engine's Traditional Chinese, which is the
    // behaviour being removed.
    for (final command in ['04', 'ATZ', 'ZZ', '03\r04', '08', '']) {
      final why = manualCommandRefusal(command)!;
      final text = shown(en, ManualCommandRefusedException(why));
      expect(
        containsChinese(text),
        isFalse,
        reason: '$command still shows ${chineseIn(text)} to an English reader',
      );
    }
  });

  test('the not-connected refusal is answered by its identifier too', () {
    // The path the box takes when nothing is connected, which is how somebody
    // first meets it. It is the one refusal here that is a transport fact, so
    // it carries a `TransportIssue` rather than a `ManualCommandRefusal`, and
    // the engine's own `尚未連線` must not be what a reader sees.
    const thrown = TransportException(
      '尚未連線',
      issue: TransportIssue.notConnected,
    );
    expect(shown(en, thrown), isNot(contains('尚未連線')));
    expect(containsChinese(shown(en, thrown)), isFalse);
    expect(shown(zh, thrown), isNot(equals('尚未連線')));
    expect(shown(zh, thrown).trim(), isNotEmpty);
  });

  test('an unexpected type keeps its identifier, which is the useful part', () {
    // The over-correction guard. Stripping every type name would hide the one
    // case where the class *is* the diagnosis: something the app never
    // anticipated reaching this screen, on the screen that exists for when
    // things have already gone wrong.
    final text = shown(en, StateError('boom'));
    expect(text, contains('boom'));
    expect(
      text,
      contains('Bad state'),
      reason: 'an unrecognised failure is exactly when the identifier helps',
    );
  });

  test('a fault-code failure was already safe, for a different reason', () {
    // `DtcReadException` does not reach this box today, and if it ever does it
    // reads correctly anyway — its own `toString` is the message, with no type
    // name in front. That is worth pinning rather than assuming: it is the
    // reason the defect showed up on `TransportException` alone, and the
    // reason a future exception type here would need checking rather than
    // trusting.
    const e = DtcReadException('掃描時有回應無法判斷是哪個控制器送出的');
    expect(shown(en, e), isNot(contains('Exception')));
    expect(
      '$e',
      e.message,
      reason:
          'if this ever stops being true, this box needs the same '
          'treatment TransportException got',
    );
  });

  test('no refusal carries a type name of its own', () {
    // Whatever the widget does with it, the exception itself has to be
    // readable in a crash report without pretending to be prose. It names the
    // identifier, in English, and nothing else.
    for (final command in ['04', 'ATZ', 'ZZ', '03\r04', '08']) {
      final why = manualCommandRefusal(command);
      expect(why, isNotNull, reason: command);
      final text = '${ManualCommandRefusedException(why!)}';
      expect(text, contains(why.issue.name), reason: command);
      expect(
        containsChinese(text),
        isFalse,
        reason: 'a crash report is read by developers: $text',
      );
    }
  });
}
