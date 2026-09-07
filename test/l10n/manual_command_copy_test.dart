// What the settings manual-command panel puts on an English screen.
//
// `TransportException.message` is authored in Traditional Chinese and goes to
// the attempt transcript verbatim, on purpose: a record whose language follows
// a phone setting is one nobody can compare with anybody else's. The manual
// command panel was reading that same string and rendering it, so an English
// build answered `04` with 清除故障碼請用「清除故障碼」按鈕, and answered a
// dropped adapter with 連線已中斷。 — the same shape as the export-label defect
// `export_labels_stay_off_screen_test.dart` was written for, arriving on a
// different screen.
//
// That test reads source, because a reference is visible without running
// anything. This one cannot: the defect here is not which symbol is named but
// what the function returns for each identifier, and the fallback that still
// has to exist for the six unmigrated throws in `lib/state/obd_session.dart`
// means "does it ever return the message" is answered by the input, not by the
// text. So it drives the real function over every identifier there is.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/ui/screens/settings/manual_command_copy.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

import '../support/cjk.dart';

/// A sentence no ARB entry contains, so finding it in the output means the
/// engine's Chinese was passed through rather than translated.
const _sentinel = '轉接器把這句原封不動印在畫面上了';

String _shown(AppLocalizations l10n, TransportIssue? issue) =>
    SettingsScreen.describeManualFailure(
      l10n,
      TransportException(_sentinel, issue: issue, issueDetail: '7E1'),
    );

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  test('no identifier the panel can name renders the engine sentence', () {
    final leaked = <String>[];
    for (final issue in TransportIssue.values) {
      if (commandFailureNotRenderedYet.contains(issue)) continue;
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final shown = _shown(l10n, issue);
        if (shown.contains(_sentinel)) leaked.add('$name: $issue');
      }
    }
    expect(
      leaked,
      isEmpty,
      reason:
          'these put the exception\'s own Traditional Chinese on the screen '
          'instead of the copy written for the reader:\n${leaked.join('\n')}',
    );
  });

  test('and what it shows instead is not Chinese in an English build', () {
    // The assertion above passes for a panel that renders the *wrong* English
    // as easily as the right one, but it also passes for a panel that renders
    // an untranslated ARB entry -- which is the failure that actually ships,
    // because gen-l10n falls back to the template rather than failing. Matching
    // Han characters and CJK punctuation both, per `support/cjk.dart`: eight
    // earlier waves matched only the first and the ninth shipped `、`.
    final chinese = <String>[];
    for (final issue in TransportIssue.values) {
      if (commandFailureNotRenderedYet.contains(issue)) continue;
      final shown = _shown(en, issue);
      if (containsChinese(shown)) {
        chinese.add('$issue — ${chineseIn(shown)} in "$shown"');
      }
    }
    expect(chinese, isEmpty, reason: chinese.join('\n'));
  });

  test('an exception with no identifier still says something', () {
    // The remainder, and the reason it is not a bug. Six throws in
    // `lib/state/obd_session.dart` -- every command this box refuses to send --
    // still pass `issue: null`; they are a separate change (ImL1s/telltale#45).
    // Until then their Chinese sentence is what a reader gets, and removing the
    // fallback would replace it with an empty panel, which is worse than a
    // sentence in the wrong language on the one screen that exists for when
    // things have already gone wrong.
    expect(_shown(en, null), _sentinel);
    expect(_shown(zh, null), _sentinel);
  });

  test('the identifiers no screen renders yet are only those on the roster', () {
    // Pins the roster from the other side. Anything on it falls back to the
    // Chinese sentence, exactly as a null identifier does, so a roster that
    // quietly grew would take copy off the screen while every assertion above
    // went on passing -- it skips them.
    for (final issue in commandFailureNotRenderedYet) {
      expect(
        commandFailureText(
          en,
          TransportException(_sentinel, issue: issue, issueDetail: '7E1'),
        ),
        isNull,
        reason: '$issue has copy now; take it off the roster',
      );
      expect(_shown(en, issue), _sentinel);
    }
  });

  test('an unexpected type is still rendered by its own toString', () {
    // The over-correction guard, kept from `manual_command_wording_test.dart`
    // now that the routing changed underneath it: stripping every type name
    // would hide the one case where the class *is* the diagnosis.
    final shown = SettingsScreen.describeManualFailure(en, StateError('boom'));
    expect(shown, contains('boom'));
    expect(shown, contains('Bad state'));
  });
}
