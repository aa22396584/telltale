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
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';
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

/// Which sentence each identifier must produce, typed out by hand.
///
/// This is the assertion the file was missing, and the omission was not
/// cosmetic. Every other test here is invariant under a *transposition*:
/// uniqueness still holds, non-Chinese-ness still holds, both languages still
/// differ, the roster is still covered. A reviewer swapped the `notConnected`
/// and `linkDroppedMidSession` arms of the real switch and got an identical
/// green run -- while the app told somebody whose adapter had just been yanked
/// out of the socket mid-command that "Nothing is connected, so the command was
/// not sent", a claim the ARB metadata for that key explicitly forbids because
/// the bytes may already have left.
///
/// Typed out, not looked up. Deriving the expectation from the ARB by the same
/// key the production switch uses would compare the switch against itself, and
/// deriving it from `commandFailureText` would compare a value against a copy
/// of the code that produced it. This repo has made that mistake twice --
/// `transport_issue_guard_test.dart`'s own header records the Wi-Fi one -- and
/// both times the test validated nothing. So these are distinguishing
/// fragments of the shipped sentences, written out here, and
/// `the expected fragments actually discriminate` below proves each one picks
/// out exactly one of the nine.
///
/// `7E1` is the address `_shown` passes as `issueDetail`. The three
/// interpolating identifiers must print it: a placeholder declared in the ARB
/// and never substituted is invisible to every other check in this directory.
const _expected = <TransportIssue, (String, String)>{
  TransportIssue.notConnected: (
    'Nothing is connected, so the command was not sent.',
    '目前沒有連線，這條指令沒有送出。',
  ),
  TransportIssue.linkDroppedMidSession: (
    'The connection to the adapter dropped while this command was in flight',
    '與轉接器的連線中斷了',
  ),
  TransportIssue.disconnectedByApp: (
    'The app closed the connection while this command was in flight',
    'App 主動關閉了連線',
  ),
  TransportIssue.adapterSilentOnResync: (
    "had fallen out of step with the commands sent to it",
    '已經和送出的指令對不上',
  ),
  TransportIssue.linkStoppedResponding: (
    'Nothing arrived from the adapter for long enough',
    '轉接器安靜得夠久',
  ),
  TransportIssue.writeFailed: (
    "could not be handed to the adapter's connection",
    '無法交給轉接器的連線',
  ),
  TransportIssue.queryHeaderRefused: (
    'refused to aim this request at controller 7E1',
    '拒絕將這條要求對準到控制器 7E1',
  ),
  TransportIssue.wholeVehicleHeaderRefused: (
    'refused to switch to address 7E1',
    '拒絕切換到 7E1 這個位址',
  ),
  TransportIssue.legacyScanWouldBePartial: (
    'older bus with no standard address that reaches every controller',
    '沒有能觸及每個控制器的標準位址',
  ),
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  test('no identifier the panel can name renders the engine sentence', () {
    final leaked = <String>[];
    for (final issue in TransportIssue.values) {
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

  test('each identifier renders the sentence written for it, in both languages',
      () {
    // Driven through the real `describeManualFailure`, which is what the panel
    // calls, against expectations nothing in `lib/` produced.
    final wrong = <String>[];
    for (final entry in _expected.entries) {
      for (final (name, l10n, want) in [
        ('en', en, entry.value.$1),
        ('zh-Hant', zh, entry.value.$2),
      ]) {
        final shown = _shown(l10n, entry.key);
        if (!shown.contains(want)) {
          wrong.add('$name: ${entry.key} should say "$want" and says:\n$shown');
        }
      }
    }
    expect(
      wrong,
      isEmpty,
      reason: 'an identifier is being answered with another one\'s sentence, '
          'which reads as a complete and confident diagnosis of something that '
          'did not happen:\n${wrong.join('\n\n')}',
    );
  });

  test('the table names every command-path identifier, so none goes unchecked',
      () {
    // Written from the other side. A new command-path identifier with a switch
    // arm and no row here would be transposable again, and the test above
    // cannot notice a key it was never given.
    final unlisted = <TransportIssue>[];
    for (final issue in TransportIssue.values) {
      // A connect identifier is delegated verbatim to the connect table and is
      // pinned there, in `l03_connect_l10n_test.dart`. Only the ones this file
      // owns need a row.
      if (transportIssueText(en, issue) != null) continue;
      if (!_expected.containsKey(issue)) unlisted.add(issue);
    }
    expect(
      unlisted,
      isEmpty,
      reason: 'these are answered by this file and nothing says what they must '
          'say: ${unlisted.join(', ')}',
    );
  });

  test('the expected fragments actually discriminate', () {
    // The table is worth exactly as much as this. A fragment shared by two
    // sentences -- "while this command was in flight" is in two of them --
    // would let the swap it exists to catch pass, and it would look like a
    // thorough test while doing it.
    final rendered = {
      for (final issue in _expected.keys)
        issue: (_shown(en, issue), _shown(zh, issue)),
    };
    final ambiguous = <String>[];
    for (final entry in _expected.entries) {
      for (final (name, want, pick) in [
        ('en', entry.value.$1, (((String, String) r) => r.$1)),
        ('zh-Hant', entry.value.$2, (((String, String) r) => r.$2)),
      ]) {
        final matched = rendered.entries
            .where((r) => pick(r.value).contains(want))
            .map((r) => r.key)
            .toList();
        if (matched.length != 1 || matched.single != entry.key) {
          ambiguous.add('$name: "$want" matches $matched');
        }
      }
    }
    expect(
      ambiguous,
      isEmpty,
      reason: 'a fragment that does not pick out one sentence cannot detect a '
          'transposition:\n${ambiguous.join('\n')}',
    );
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
