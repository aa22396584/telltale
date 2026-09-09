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
// what the function returns for each identifier, so it drives the real
// function over every identifier there is.
//
// Two families of identifier reach this panel and they are not the same kind
// of thing. A `TransportIssue` is a failure of a command that was sent; a
// `ManualCommandRefusalReason` is this app declining to send one, which
// involves no link and no bytes. Both are rendered by
// `SettingsScreen.describeManualFailure`, so both are driven here, through the
// exceptions the session really throws.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/manual_command_refusal.dart';
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
  TransportIssue.operationRetired: (
    'This session has ended or gone to the background, so the command was not sent.',
    '這個工作階段已經結束或退到背景，指令沒有送出。',
  ),
  TransportIssue.requestUnaddressable: (
    'This request cannot be addressed on the bus this vehicle is using, so it was not sent.',
    '這條要求在這輛車使用的匯流排上無法定址，因此沒有送出。',
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

  test('a TimeoutException is mapped, not stringified onto the panel', () {
    // sendManualCommand awaits Elm327Client.send, which times out as a
    // TimeoutException. describeManualFailure used to return '$error', so an
    // English engine fallback leaked onto a Traditional Chinese panel as
    // "TimeoutException after 0:00:00.080000: Timed out waiting for a reply".
    final error = TimeoutException(
      'Timed out waiting for a reply',
      const Duration(milliseconds: 80),
    );
    expect(
      SettingsScreen.describeManualFailure(en, error),
      'No reply arrived before the time limit. Confirm the adapter is '
      'connected and the ignition is on.',
    );
    expect(
      SettingsScreen.describeManualFailure(zh, error),
      '在時限內沒有收到回應。請確認轉接器已連線，且車輛電門已開啟。',
    );
    expect(
      SettingsScreen.describeManualFailure(en, error),
      isNot(contains('TimeoutException')),
    );
    expect(
      SettingsScreen.describeManualFailure(zh, error),
      isNot(contains('Timed out waiting')),
    );
  });

  test('the two subclasses that reach this panel use their identifiers', () {
    // Constructed as the transports and `_sendNow` throw them, not as a
    // bare `TransportException` with the identifier already filled in.
    expect(
      SettingsScreen.describeManualFailure(
        en,
        const WriteRefusedException(_sentinel),
      ),
      'Nothing is connected, so the command was not sent.',
    );
    expect(
      SettingsScreen.describeManualFailure(
        zh,
        const WriteRefusedException(_sentinel),
      ),
      '目前沒有連線，這條指令沒有送出。',
    );
    expect(
      SettingsScreen.describeManualFailure(
        en,
        const OperationRetiredException(_sentinel),
      ),
      'This session has ended or gone to the background, so the command was not sent.',
    );
    expect(
      SettingsScreen.describeManualFailure(
        zh,
        const OperationRetiredException(_sentinel),
      ),
      '這個工作階段已經結束或退到背景，指令沒有送出。',
    );
    expect(
      SettingsScreen.describeManualFailure(
        en,
        const WriteRefusedException(_sentinel),
      ),
      isNot(contains(_sentinel)),
    );
    expect(
      SettingsScreen.describeManualFailure(
        en,
        const OperationRetiredException(_sentinel),
      ),
      isNot(contains(_sentinel)),
    );
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

  group('the refusals: commands this app declines to send', () {
    // One fixture per identifier, so the loops below cannot skip one by never
    // being given it. The test named `every identifier has a fixture and an
    // expectation` is what says the map is complete.
    //
    // The two arms that print carried values get values here that are not the
    // real ones. A fixture holding the production list would let a copy that
    // spelled the list into the sentence pass every assertion in this group.
    const fixtures = <ManualCommandRefusalReason, ManualCommandRefusal>{
      ManualCommandRefusalReason.emptyCommand:
          ManualCommandRefusal.emptyCommand(),
      ManualCommandRefusalReason.moreThanOneCommand:
          ManualCommandRefusal.moreThanOneCommand(),
      ManualCommandRefusalReason.adapterStateWouldChange:
          ManualCommandRefusal.adapterStateWouldChange(
            command: 'ATZ',
            allowed: ['ATI', 'ATRV'],
          ),
      ManualCommandRefusalReason.clearHasItsOwnButton:
          ManualCommandRefusal.clearHasItsOwnButton(),
      ManualCommandRefusalReason.charactersNoObdCommandHas:
          ManualCommandRefusal.charactersNoObdCommandHas(command: 'ZZ'),
      ManualCommandRefusalReason.notAReadOnlyQuery:
          ManualCommandRefusal.notAReadOnlyQuery(
            command: 'FF',
            allowed: ['01', '22'],
          ),
    };

    /// A distinguishing fragment of each shipped sentence, typed out here.
    ///
    /// Not read back from the ARB, from `AppLocalizations` or from
    /// `manualCommandRefusalText`. Every other assertion in this group --
    /// non-emptiness, uniqueness, absence of Chinese in English, the two
    /// languages differing -- survives swapping two arms of the switch. This
    /// map is the only one that does not, and
    /// `the fragments actually discriminate` proves each fragment picks out
    /// exactly one of the six.
    const expected = <ManualCommandRefusalReason, (String, String)>{
      ManualCommandRefusalReason.emptyCommand: (
        'Nothing was typed',
        '沒有輸入指令',
      ),
      ManualCommandRefusalReason.moreThanOneCommand: (
        'line break or another control character',
        '換行或控制字元',
      ),
      ManualCommandRefusalReason.adapterStateWouldChange: (
        'Queries you can send',
        '可用的查詢',
      ),
      ManualCommandRefusalReason.clearHasItsOwnButton: (
        'use the Clear button on the fault-code screen',
        '故障碼畫面的「清除」按鈕',
      ),
      ManualCommandRefusalReason.charactersNoObdCommandHas: (
        'contains characters an OBD command never has',
        '含有 OBD 指令不會出現的字元',
      ),
      ManualCommandRefusalReason.notAReadOnlyQuery: (
        'is not a command this box knows',
        '不認得的指令',
      ),
    };

    String render(AppLocalizations l10n, ManualCommandRefusalReason reason) =>
        SettingsScreen.describeManualFailure(
          l10n,
          ManualCommandRefusedException(fixtures[reason]!),
        );

    test('every identifier has a fixture and an expectation', () {
      // Written from the enum rather than from the maps, so a value added
      // later cannot pass by being absent from both.
      expect(
        fixtures.keys.toSet(),
        ManualCommandRefusalReason.values.toSet(),
        reason: 'a refusal identifier has no fixture, so no loop here sees it',
      );
      expect(
        expected.keys.toSet(),
        ManualCommandRefusalReason.values.toSet(),
        reason: 'a refusal identifier has no hand-typed sentence',
      );
    });

    test('each identifier says the sentence written for it, in both languages',
        () {
      final wrong = <String>[];
      for (final entry in expected.entries) {
        for (final (name, l10n, want) in [
          ('en', en, entry.value.$1),
          ('zh-Hant', zh, entry.value.$2),
        ]) {
          final text = render(l10n, entry.key);
          if (!text.contains(want)) {
            wrong.add('$name: ${entry.key} should say "$want" and says:\n$text');
          }
        }
      }
      expect(wrong, isEmpty, reason: wrong.join('\n\n'));
    });

    test('the two that steer somebody elsewhere say it exactly', () {
      // Whole sentences rather than fragments, for the two refusals whose job
      // is to send a person to a different screen or a different command. A
      // fragment can survive a rewrite that drops the part naming where to go,
      // and where to go is the only reason these two exist.
      expect(
        render(en, ManualCommandRefusalReason.clearHasItsOwnButton),
        'To clear fault codes, use the Clear button on the fault-code screen. '
            'Sent from here it would skip the confirmation, the coverage check '
            'and the response validation, and it would reach only the one '
            'controller currently selected.',
      );
      expect(
        render(zh, ManualCommandRefusalReason.clearHasItsOwnButton),
        '清除故障碼請用故障碼畫面的「清除」按鈕。從這裡送出會跳過確認、覆蓋率檢查'
            '與回應驗證，而且只會清到目前選中的那一個控制器。',
      );
      expect(
        render(en, ManualCommandRefusalReason.adapterStateWouldChange),
        'This box accepts questions, not commands that change what the adapter '
            'is. “ATZ” would change the adapter'
            "'s state while the app's model of it stayed as it was — "
            'the readings '
            'after it could come from a different controller, with nothing on '
            'screen to say so.\nQueries you can send: ATI, ATRV.',
      );
      expect(
        render(zh, ManualCommandRefusalReason.adapterStateWouldChange),
        '手動指令只接受查詢，不接受會改變轉接器設定的指令。「ATZ」會改動轉接器狀態，'
            '而 App 對轉接器的認知不會跟著更新 —— 接下來的讀數可能來自另一個控制器，'
            '而畫面上看不出來。\n可用的查詢：ATI、ATRV。',
      );
    });

    test('the carried values are rendered, not spelled into the copy', () {
      // The link a copy table cannot reach on its own. The fixtures hold
      // values the production code never produces, so copy that named the real
      // list would fail here and pass everything else.
      for (final l10n in [en, zh]) {
        final at = render(l10n, ManualCommandRefusalReason.adapterStateWouldChange);
        expect(at, contains('ATZ'));
        expect(at, contains('ATI'));
        expect(at, contains('ATRV'));
        expect(
          at,
          isNot(contains('ATDPN')),
          reason: 'the production list must not be spelled into the sentence',
        );

        final service = render(l10n, ManualCommandRefusalReason.notAReadOnlyQuery);
        expect(service, contains('FF'));
        expect(service, contains('01'));
        expect(service, contains('22'));
        expect(
          service,
          isNot(contains('0A')),
          reason: 'likewise on the service side',
        );

        expect(
          render(l10n, ManualCommandRefusalReason.charactersNoObdCommandHas),
          contains('ZZ'),
        );
      }
    });

    test('the list separator follows the reader, not the engine', () {
      // The half eight of nine earlier waves in this repo missed: every word
      // translated and only the separator left behind. Joining in `lib/state/`
      // would have put a CJK comma in front of an English reader.
      expect(
        render(en, ManualCommandRefusalReason.adapterStateWouldChange),
        contains('ATI, ATRV'),
      );
      expect(
        render(zh, ManualCommandRefusalReason.adapterStateWouldChange),
        contains('ATI、ATRV'),
      );
    });

    test('the English build renders no Chinese', () {
      for (final reason in ManualCommandRefusalReason.values) {
        final text = render(en, reason);
        expect(
          containsChinese(text),
          isFalse,
          reason: '$reason still shows ${chineseIn(text)} to an English reader',
        );
      }
    });

    test('every identifier says something, in both languages', () {
      for (final reason in ManualCommandRefusalReason.values) {
        for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
          expect(render(l10n, reason).trim(), isNotEmpty, reason: '$name $reason');
        }
      }
    });

    test('no two refusals claim the same cause', () {
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final seen = <String, ManualCommandRefusalReason>{};
        for (final reason in ManualCommandRefusalReason.values) {
          final text = render(l10n, reason);
          final clash = seen[text];
          expect(
            clash,
            isNull,
            reason: '$name: $reason and $clash render the same sentence:\n$text',
          );
          seen[text] = reason;
        }
      }
    });

    test('the two languages actually differ for every refusal', () {
      // Catches a key added to app_en.arb and copied verbatim into the Chinese
      // files, which passes every other check in this group.
      for (final reason in ManualCommandRefusalReason.values) {
        expect(
          render(en, reason),
          isNot(equals(render(zh, reason))),
          reason: '$reason reads identically in both languages',
        );
      }
    });

    test('the fragments actually discriminate', () {
      // The hand-typed table is worth exactly as much as this. A fragment
      // shared by two sentences would let the transposition it exists to catch
      // pass, while looking like a thorough test.
      final rendered = {
        for (final reason in ManualCommandRefusalReason.values)
          reason: (render(en, reason), render(zh, reason)),
      };
      final ambiguous = <String>[];
      for (final entry in expected.entries) {
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
      expect(ambiguous, isEmpty, reason: ambiguous.join('\n'));
    });
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
