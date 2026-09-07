// The transports' connection failures, as identifiers a screen can translate.
//
// Not the last Chinese on this path, and the first version of this header said
// it was. `_runInitSequence` catches per step and puts `'$e'` into
// `InitProgress.detail`, which `_failureReason` renders raw -- so an adapter
// unplugged mid-handshake still reaches an English reader as
// `Initialisation failed at ATZ (TransportException: 連線已中斷。)`. That is
// pre-existing, outside this change, and inventoried in ImL1s/telltale#45.
//
// `ObdConnectionIssue` already carried the handshake's diagnoses as identifiers
// the screen translates. The transports did not: `obd_session` caught a
// `TransportException` and passed `e.message` straight through, and those
// sentences are authored in Traditional Chinese inside `lib/obd/transport/`.
// So a first-run English user who could not reach the adapter — the most likely
// thing to go wrong, and the first thing that does — got a paragraph they could
// not read.
//
// Two failures were worse than untranslated. Every Wi-Fi route failure told the
// reader to connect to the adapter's hotspot, which is the right remedy for
// exactly one of the four: on `ambiguous` the phone is already on Wi-Fi and the
// problem is that it is on two, and on `refused` it is on the right one and was
// not allowed to use it. A remedy that cannot work reads exactly like one that
// can.
//
// This file holds four things that would otherwise drift apart: that no direct
// `TransportException` anywhere in `lib/obd/` settles for `issue: null`, that
// each identifier is answered by exactly one of the two copy tables, that every
// identifier a screen can reach has copy in both languages, and that no two of
// them say the same thing.
//
// The scan used to read `lib/obd/transport/` alone, which was the whole story
// only while `elm327_client.dart`'s eight throws had no identifier to carry.
// They have one now, so the directory that has to stay clean is `lib/obd/`.
// `lib/state/obd_session.dart` is deliberately still outside it: its six are a
// separate change (ImL1s/telltale#45), and widening this far now would fail on
// work nobody has done yet, which is how a guard gets an exception list.
//
// "Direct" is doing work in that sentence. Three subclasses bake `issue: null`
// into their own constructors, so the scan never sees them; they are held by a
// written roster instead, below.
//
// The mapping from a Wi-Fi route failure to its identifier is NOT held here.
// It was, against a second copy of the switch written in this file, and that
// test could not fail: swapping two arms in the real one left it green while
// telling a phone on no Wi-Fi that it was on too many. It now lives in
// `test/wifi_transport_test.dart`, where it drives the real transport and
// compares against a table written out by hand.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';
import 'package:torque_obd/ui/screens/settings/manual_command_copy.dart';

/// Which of the two copy tables owns each identifier, written by hand.
///
/// Everything not listed here is a connect failure and is said by
/// `handshake_copy.dart`. Everything listed is a failure of a command on a link
/// that already came up, and is said by `manual_command_copy.dart`.
///
/// `writeFailed` used to be excused from having any copy at all, on the
/// reasoning that it "reaches the user by a different path". The different path
/// turned out to be a screen: `SerialTransport.write` throws it, `_sendNow`
/// does not catch it, and `ObdSession.sendManualCommand` hands it to the
/// settings panel. So it is on the command path with the rest, and the
/// exemption it used to have is gone rather than widened.
const _commandPath = <TransportIssue>{
  TransportIssue.writeFailed,
  TransportIssue.linkDroppedMidSession,
  TransportIssue.disconnectedByApp,
  TransportIssue.notConnected,
  TransportIssue.adapterSilentOnResync,
  TransportIssue.queryHeaderRefused,
  TransportIssue.wholeVehicleHeaderRefused,
  TransportIssue.legacyScanWouldBePartial,
  TransportIssue.linkStoppedResponding,
};

/// The identifiers whose throw must also carry the address its sentence names.
///
/// Written as source text because that is what the scan reads. An identifier
/// per header would be an unbounded enum and interpolating the address into
/// `message` would put it only in the Chinese sentence, so it travels beside
/// the identifier -- and "travels beside it" is worth nothing unless a throw
/// that forgets it fails.
const _interpolating = <String>{
  'TransportIssue.queryHeaderRefused',
  'TransportIssue.wholeVehicleHeaderRefused',
  'TransportIssue.legacyScanWouldBePartial',
};

/// What a reader is shown for [issue], from whichever table owns it.
///
/// Both are asked, in the order a screen would ask them, so the invariants
/// below cover the command path as well as the connect one. A `??` rather than
/// a roster lookup on purpose: if both tables ever answer, the connect one wins
/// here and `the two tables do not overlap` is what fails, by name.
String? _text(AppLocalizations l10n, TransportIssue issue) =>
    _connectText(l10n, issue) ??
    commandFailureText(
      l10n,
      TransportException(
        'the transcript keeps this one',
        issue: issue,
        issueDetail: '7E1',
      ),
    );

/// The connect screen's answer, reached the way the screen reaches it.
String? _connectText(AppLocalizations l10n, TransportIssue issue) =>
    connectionIssueText(
      l10n,
      ObdConnectionState(
        phase: ConnectionPhase.failed,
        error: 'the transcript keeps this one',
        transportIssue: issue,
      ),
    );

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  test('every transport failure names a real issue, not null', () {
    // The constructor makes `issue:` required, so the compiler already refuses
    // a throw that omits it. What it cannot refuse is `issue: null`, which is
    // correct in `lib/state/obd_session.dart` -- for now, and for six throws --
    // and wrong anywhere under `lib/obd/`.
    //
    // It also cannot refuse an identifier whose sentence names an address,
    // thrown without the address. That reads as a complete failure, analyses
    // clean, and renders a sentence with a hole in it, so the same pass checks
    // for it.
    //
    // Parsed rather than grepped. Two things fooled the first version: a
    // `TransportIssue.` written inside a comment satisfied a substring search,
    // and a nested construction let the outer call borrow the inner one's
    // argument. Reading the top-level named arguments of each call is immune to
    // both, because a nested `issue:` is not a top-level argument of the call
    // that encloses it.
    final naked = <String>[];
    for (final file in _transportSources()) {
      final src = file.readAsStringSync();
      final mask = _codeMask(src);

      for (final match in RegExp(r'\bTransportException\(').allMatches(src)) {
        final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
        if (!mask[match.start]) continue; // named inside a string or a comment
        final args = _topLevelArgs(src, mask, match.end - 1);
        if (args == null) {
          // Not `continue`. An unreadable call used to be dropped in silence,
          // which turns ANY future desync -- whatever the vector -- into a green
          // run. Reporting it means the reader can still be wrong, but it cannot
          // be quiet about it.
          naked.add('${file.path}:$line — could not be read');
          continue;
        }
        // The declaration itself, and only it. `args.any(contains)` also
        // matched a throw that passed a field named `message` -- review wrote
        // one: a transport with `final String message` and
        // `TransportException(this.message, issue: null)` passed the guard.
        if (file.path.endsWith('obd_transport.dart') &&
            args.isNotEmpty &&
            args.first.trim() == 'this.message') {
          continue;
        }
        final trimmed = args.map((a) => a.trim()).toList(growable: false);
        final issue = trimmed.firstWhere(
          (a) => a.startsWith('issue:'),
          orElse: () => '',
        );
        if (issue.isEmpty || issue.contains('null')) {
          naked.add(
            '${file.path}:$line — '
            '${issue.isEmpty ? "no issue: argument" : issue}',
          );
          continue;
        }
        final named = _interpolating.where(issue.contains);
        if (named.isNotEmpty &&
            !trimmed.any((a) => a.startsWith('issueDetail:'))) {
          naked.add(
            '${file.path}:$line — ${named.first} without issueDetail:',
          );
        }
      }
    }
    expect(
      naked,
      isEmpty,
      reason:
          'these reach a screen with a Traditional Chinese sentence and '
          'nothing the screen can translate, or name an address their copy '
          'cannot print:\n${naked.join('\n')}',
    );
  });

  test('the subclasses that bake in a null identifier are the written three', () {
    // `WriteRefusedException('...')` never matches `TransportException(`, so
    // the scan above cannot see that it passes `super(issue: null)`. All three
    // are correct today -- every throw of them is inside a `write(...)`, so none
    // reaches the connect screen -- but "correct today" is what a roster is for.
    // A fourth subclass doing the same has to be written here, where somebody
    // reads it and says why.
    const known = {
      'WriteRefusedException': 'thrown only from write(); read by the clear-DTC '
          'audit, which cares that nothing was transmitted',
      'OperationRetiredException': 'the app stopped asking; not a failure to '
          'report',
      'UnaddressableRequestException': 'handled structurally by the polling '
          'loop and surfaced by the gauge',
    };

    // Every file in the directory, not just the one the three happen to live
    // in: review declared a fourth in `serial_transport.dart` and threw it from
    // `connect()`, and the roster never saw it.
    // Code only. Reading raw source made this cry wolf: a string containing
    // `class Imaginary extends TransportException {` -- a doc comment, an error
    // message, a test fixture pasted into a constant -- reported a subclass that
    // does not exist. A guard that names something imaginary is one people learn
    // to disbelieve, which is the same failure as the detector this file used to
    // carry. Found by trying it.
    final sources = {
      for (final f in _transportSources())
        f.path: _codeOnly(f.readAsStringSync()),
    };

    // Closed to a fixed point, because `extends TransportException` only finds
    // direct subclasses. Review declared `SilentRefusal extends
    // WriteRefusedException`, which inherits `issue: null` without writing it
    // and was invisible one level down.
    final declared = <String>{};
    var frontier = {'TransportException'};
    while (frontier.isNotEmpty) {
      final found = <String>{};
      for (final base in frontier) {
        for (final src in sources.values) {
          // `extends`, `implements`, and the mixin-application form
          // `class X = Base with M`. The last two are the honest answer to
          // "can this regex be satisfied another way": `implements` still
          // satisfies `on TransportException catch`, and the `=` form inherits
          // the forwarding constructor. Neither is written by accident and
          // neither is in the tree.
          final pattern = RegExp(
            'class (\\w+) (?:extends|implements) $base\\b'
            '|class (\\w+) = $base\\b',
          );
          for (final m in pattern.allMatches(src)) {
            final name = m.group(1) ?? m.group(2)!;
            if (declared.add(name)) found.add(name);
          }
        }
      }
      frontier = found;
    }
    expect(
      declared,
      known.keys.toSet(),
      reason: 'a TransportException subclass was added or removed. If it bakes '
          'in `issue: null`, say here why it can never reach the connect '
          'screen; the scan cannot see it.',
    );

    // And each of them really does bake it in, rather than taking one.
    for (final name in known.keys) {
      final decl = sources.values
          .map((src) => RegExp('const $name\\(super\\.message\\)[^;]*;')
              .firstMatch(src))
          .firstWhere((m) => m != null, orElse: () => null);
      expect(decl, isNotNull, reason: '$name changed shape');
      expect(
        decl!.group(0),
        contains('super(issue: null)'),
        reason: '$name no longer bakes in a null identifier, so it should be '
            'held by the scan rather than by this roster',
      );
    }
  });

  test('the reader itself: what counts as code', () {
    // The scan above is only as good as this, and this is the part that was
    // wrong twice. Fixtures rather than the real sources, because the real
    // sources are supposed to be clean -- a reader that has never seen the
    // shapes it exists to survive has not been tested on them.
    int callsFound(String src) {
      final mask = _codeMask(src);
      return RegExp(r'\bTransportException\(')
          .allMatches(src)
          .where((m) => mask[m.start])
          .length;
    }

    expect(callsFound("// TransportException('x', issue: null);"), 0,
        reason: 'a line comment is not code');
    expect(callsFound("/* TransportException('x', issue: null); */"), 0,
        reason: 'a block comment is not code');
    expect(callsFound("final s = 'TransportException(';"), 0,
        reason: 'a string literal is not code');
    expect(callsFound(r"""final s = 'TransportException(';"""), 0,
        reason: 'nor when the literal is the whole argument');

    // classic_transport.dart:256 is exactly this shape. Tracking quotes alone
    // reads the inner quote as closing the outer literal; here the nested pair
    // happens to resynchronise, so this case passed by luck before.
    expect(
      callsFound(
        "final d = '\${notes.join('；')}';\n"
        "throw TransportException('y', issue: null);",
      ),
      1,
      reason: 'a quote inside an interpolation must not swallow what follows',
    );

    // Balanced nesting resynchronises even without interpolation handling, so
    // the case above proves nothing on its own -- removing that handling left
    // it green, which is how this fixture came to exist. What luck does not
    // survive is an UNBALANCED quote: an apostrophe inside a double-quoted
    // string inside an interpolation. Naively, the apostrophe closes the outer
    // literal and every quote after it in the file is inverted.
    expect(
      callsFound(
        'final d = \'\${x("it\'s")}\';\n'
        'throw TransportException(\'y\', issue: null);',
      ),
      1,
      reason: 'an unbalanced quote inside an interpolation must not invert the '
          'rest of the file',
    );

    // A comment marker inside a string is not a comment.
    expect(
      callsFound(
        "final u = 'https://example.test';\n"
        "throw TransportException('y', issue: null);",
      ),
      1,
      reason: "'//' inside a string does not start a comment",
    );

    // Triple-quoted, with a lone apostrophe inside. Read as three toggles this
    // inverts everything after it; two such strings then cancel, so the file
    // ends balanced and the region between them is invisible to any end-state
    // check. This is where that would have been caught.
    expect(
      callsFound(
        "const hint = '''don't reopen''';\n"
        "throw TransportException('y', issue: null);",
      ),
      1,
      reason: 'a triple-quoted string must close on its own three quotes',
    );
    expect(
      callsFound(
        "const a = '''don't''';\n"
        "throw TransportException('y', issue: null);\n"
        "const b = '''don't''';",
      ),
      1,
      reason: 'two inversions cancel; the call between them must still be seen',
    );
    expect(callsFound('const s = \'\'\'TransportException(\'\'\';'), 0,
        reason: 'and its contents are still not code');

    // Escapes, in a SINGLE-quoted frame. The triple fixture below reads as
    // escape coverage and cannot fail on this: inside a triple frame a lone
    // quote never closes the literal, so it passes with the escape branch dead
    // or alive. Review checked both states; this is the line that separates
    // them, and `'don\\'t'` is the most ordinary construct in the file.
    expect(
      callsFound(
        "const q = 'it\\'s';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'an escaped quote does not close a single-quoted literal',
    );
    expect(
      callsFound(
        "const p = r'C:\\';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'a raw string has no escapes, so its backslash is content',
    );

    // The triple form, in each shape it actually takes.
    expect(
      callsFound(
        "const r = r'''a // b''';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'a raw triple ends at its own three quotes',
    );
    expect(
      callsFound(
        "const q = '''it\\'s''';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'an escaped quote inside a triple does not close it',
    );
    expect(
      callsFound(
        "const i = '\${f('''z''')}';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'a triple opened inside an interpolation',
    );
    expect(
      callsFound(
        'const d = """say hi""";\nthrow TransportException(\'y\', issue: null);',
      ),
      1,
      reason: 'the double-quoted triple form',
    );

    // And a brace inside a string must not move the interpolation stack.
    expect(
      callsFound(
        "final b = '} { }';\nthrow TransportException('y', issue: null);",
      ),
      1,
      reason: 'braces inside a string are not syntax',
    );
  });

  test('the two tables do not overlap, and between them cover everything', () {
    // The split is the point of the change this file guards, and it is the one
    // part no compiler checks: both switches are exhaustive, so an identifier
    // answered by both -- or by neither -- compiles. Answered by both, a
    // reader gets whichever screen they happen to be on to explain a failure
    // that only happens on the other; answered by neither, they get the
    // Chinese sentence back.
    final wrong = <String>[];
    for (final issue in TransportIssue.values) {
      final connect = _connectText(en, issue);
      final command = commandFailureText(
        en,
        TransportException('sentinel', issue: issue, issueDetail: '7E1'),
      );
      final onCommandPath = _commandPath.contains(issue);

      if ((connect != null) == onCommandPath) {
        wrong.add(
          '$issue: the connect table ${connect == null ? "does not answer" : "answers"} '
          'it, and the roster says it is ${onCommandPath ? "" : "not "}a '
          'command-path failure',
        );
      }
      // The command table delegates connect identifiers rather than returning
      // null for them, so "answers" is not the discriminator on that side. Only
      // the roster of identifiers nothing renders yet may leave it silent.
      final expectedSilent =
          onCommandPath && commandFailureNotRenderedYet.contains(issue);
      if ((command == null) != expectedSilent) {
        wrong.add(
          '$issue: the command table ${command == null ? "does not answer" : "answers"} '
          'it, against a roster that says it should '
          '${expectedSilent ? "not" : ""}',
        );
      }
      if (!onCommandPath && command != connect) {
        wrong.add(
          '$issue: a connect identifier reaching the settings panel must be '
          'delegated verbatim, not re-worded',
        );
      }
    }
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('the not-rendered-yet roster is exactly the command path with no copy', () {
    // Membership of that roster is a claim about the tree, not a preference.
    // Every one of them has to be a command-path identifier -- a connect one
    // would simply be missing copy -- and the file that holds it has to say
    // which line drops it.
    expect(
      commandFailureNotRenderedYet.difference(_commandPath),
      isEmpty,
      reason: 'only a command-path identifier can be on that roster',
    );
    expect(
      commandFailureNotRenderedYet,
      isNotEmpty,
      reason: 'if it is empty, delete it rather than leaving an empty '
          'allowance for the next person to add to',
    );
    // And the condition the roster exists for is still in the tree.
    //
    // Checking that the roster's own doc comment names a line number would pass
    // for as long as nobody edits the doc, and would go on passing after the
    // discard is fixed -- which is the direction it has to fail in. So this
    // reads the code instead. When `polling_engine` stops throwing away the
    // identifier, two of these three get a screen and this test says so.
    final engine = _codeOnly(
      File('lib/obd/polling_engine.dart').readAsStringSync(),
    );
    expect(
      RegExp(
        r'on TransportException catch \(e\)'
        r'[\s\S]{0,400}?throw DtcReadException\(e\.message\)',
      ).hasMatch(engine),
      isTrue,
      reason:
          'polling_engine no longer rethrows a TransportException as '
          'DtcReadException(e.message), so the identifier is not discarded any '
          'more. Take wholeVehicleHeaderRefused and legacyScanWouldBePartial '
          'off commandFailureNotRenderedYet, give them ARB copy, and render it '
          'on the fault-code screen.',
    );
  });

  test('every issue a screen can reach has copy in both languages', () {
    for (final issue in TransportIssue.values) {
      if (commandFailureNotRenderedYet.contains(issue)) {
        expect(
          _text(en, issue),
          isNull,
          reason: '$issue is on the roster of identifiers no screen renders '
              'yet; if a screen now renders it, take it off that roster '
              'rather than adding copy nothing reaches',
        );
        continue;
      }
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        final text = _text(l10n, issue);
        expect(text, isNotNull, reason: '$issue has no $name copy');
        expect(text!.trim(), isNotEmpty, reason: '$issue has empty $name copy');
      }
    }
  });

  test('no two issues are given the same sentence', () {
    // A switch arm pointing at the neighbouring key compiles, renders, and is
    // invisible until somebody reads two failures that claim the same cause.
    for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
      final seen = <String, TransportIssue>{};
      for (final issue in TransportIssue.values) {
        if (commandFailureNotRenderedYet.contains(issue)) continue;
        final text = _text(l10n, issue)!;
        final clash = seen[text];
        expect(
          clash,
          isNull,
          reason: '$name: $issue and $clash render the same sentence:\n$text',
        );
        seen[text] = issue;
      }
    }
  });

  test('the two languages actually differ for every issue', () {
    // Catches a key added to app_en.arb and copied verbatim into the Chinese
    // ones, which is how an untranslated string passes every other check here.
    for (final issue in TransportIssue.values) {
      if (commandFailureNotRenderedYet.contains(issue)) continue;
      expect(
        _text(en, issue),
        isNot(equals(_text(zh, issue))),
        reason: '$issue reads identically in both languages',
      );
    }
  });
}

/// [src] with every string and comment character replaced by a space.
///
/// Offsets and line breaks are preserved, so anything matched against this can
/// still be located in the original.
String _codeOnly(String src) {
  final mask = _codeMask(src);
  final out = StringBuffer();
  for (var i = 0; i < src.length; i++) {
    out.write(mask[i] ? src[i] : (src[i] == '\n' ? '\n' : ' '));
  }
  return out.toString();
}

/// Every Dart file the transports live in.
///
/// Recursive, and shared by the scan and the roster so they cannot disagree
/// about what "the transport directory" means -- the roster used to read one
/// file while the scan walked the tree.
List<File> _transportSources() => Directory('lib/obd')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// True at every index that is real code -- not inside a string literal and not
/// inside a comment.
///
/// One pass, shared by both readers below, because they have to agree. Two
/// things made the naive version wrong:
///
///   * `// TODO: pick a TransportIssue. for this one` satisfied a substring
///     search, so a throw with no identifier passed. Precedent for stripping
///     first: `test/l10n/l04_status_l10n_test.dart` does the same, for the same
///     reason -- comments may name the rule; code may not.
///   * `'${tierNotes.join('；')}'` in `classic_transport.dart` puts a quote
///     inside an interpolation. Tracking quotes alone reads the inner `'` as
///     closing the outer literal. It happens to resynchronise there because the
///     nested quotes pair up, which is luck, not correctness -- an odd number
///     desynchronises everything after it in the file, and a guard that stops
///     seeing constructions is one that reports success.
///
/// So interpolation is a stack: `${` inside a string re-enters code, and the
/// matching `}` returns to the string that opened it.
class _Frame {
  const _Frame.string(this.quote, {this.raw = false}) : braceDepth = -1;
  const _Frame.interpolation(this.braceDepth) : quote = '', raw = false;

  final String quote;
  final int braceDepth;

  /// Raw strings do not process escapes, so a backslash in one is content.
  final bool raw;

  bool get isString => braceDepth < 0;
}

List<bool> _codeMask(String src) {
  final mask = List<bool>.filled(src.length, false);
  final frames = <_Frame>[];
  var braces = 0;
  var i = 0;
  while (i < src.length) {
    final inString = frames.isNotEmpty && frames.last.isString;
    final c = src[i];

    if (inString) {
      // Was `c == r'\\'`, comparing one character against a two-character
      // string -- always false, so no escape was ever honoured and
      // `'don\\'t reopen'` closed the literal at the apostrophe, inverting the
      // mask for the rest of the file. Everyday Dart, and far likelier than any
      // triple-quote shape. The `raw` test is not decoration: fixing the
      // comparison alone breaks `r'C:\\'`, which has no escapes to honour.
      if (c == '\\' && !frames.last.raw) {
        i += 2;
        continue;
      }
      if (c == r'$' && i + 1 < src.length && src[i + 1] == '{') {
        braces++;
        frames.add(_Frame.interpolation(braces));
        i += 2;
        continue;
      }
      if (src.startsWith(frames.last.quote, i)) {
        i += frames.last.quote.length;
        frames.removeLast();
        continue;
      }
      i++;
      continue;
    }

    if (c == '/' && i + 1 < src.length && src[i + 1] == '/') {
      while (i < src.length && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < src.length && src[i + 1] == '*') {
      final close = src.indexOf('*/', i + 2);
      i = close == -1 ? src.length : close + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      // Dart has exactly four string forms, and that is why this is finite
      // work rather than a heuristic. A triple quote read as three toggles
      // inverts the rest of the file; two such strings then cancel, so the file
      // ends balanced while the region between them is invisible. No end-state
      // check can see that -- inversions pair up -- so the mask has to be right.
      final triple = c * 3;
      final quote = src.startsWith(triple, i) ? triple : c;
      frames.add(
        _Frame.string(quote, raw: i > 0 && src[i - 1] == 'r'),
      );
      i += quote.length;
      continue;
    }
    if (c == '{') braces++;
    if (c == '}') {
      if (frames.isNotEmpty &&
          !frames.last.isString &&
          frames.last.braceDepth == braces) {
        frames.removeLast(); // back into the string that opened this
        braces--;
        i++;
        continue;
      }
      braces--;
    }
    mask[i] = true;
    i++;
  }
  return mask;
}

/// The top-level arguments of the call whose `(` is at [open], read through
/// [mask] so string and comment content cannot look like syntax.
List<String>? _topLevelArgs(String src, List<bool> mask, int open) {
  final args = <String>[];
  final cur = StringBuffer();
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (mask[i]) {
      if (c == '(' || c == '[' || c == '{') {
        depth++;
        if (depth == 1) continue;
      } else if (c == ')' || c == ']' || c == '}') {
        depth--;
        if (depth == 0) {
          if (cur.toString().trim().isNotEmpty) args.add(cur.toString());
          return args;
        }
      } else if (c == ',' && depth == 1) {
        args.add(cur.toString());
        cur.clear();
        continue;
      }
    }
    cur.write(c);
  }
  return null;
}
