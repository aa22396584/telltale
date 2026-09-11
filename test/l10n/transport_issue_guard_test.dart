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
// `TransportException` anywhere in `lib/obd/` or `lib/state/` settles for
// `issue: null`, that
// each identifier is answered by exactly one of the two copy tables, that every
// identifier a screen can reach has copy in both languages, and that no two of
// them say the same thing.
//
// The scan used to read `lib/obd/transport/` alone, which was the whole story
// only while `elm327_client.dart`'s eight throws had no identifier to carry.
// They have one now, and so do `lib/state/obd_session.dart`'s, so the two
// directories that have to stay clean are `lib/obd/` and `lib/state/`.
//
// `lib/state/` was deliberately outside it while its six throws still passed
// `issue: null`, because a guard that fails on work nobody has done yet gets an
// exception list rather than a fix. They went four different ways, and a reader
// checking one of them has to be sent to the right file:
//
//   * one is genuinely `TransportIssue.notConnected` and is held here;
//   * one was a second rule for a case the first already answered, and is gone;
//   * one became `ManualCommandRefusedException` -- declining to send a command
//     involves no link and no bytes, so it is not a transport failure -- and
//     fans out into one refusal identifier per reason, held by
//     `l05_manual_refusal_guard_test.dart`;
//   * three became `PowertrainProbeRefusedException`, held by
//     `l05_battery_refusal_guard_test.dart` beside the rest of that enum.
//
// This paragraph said "five of the six" became the first of those. It was one.
// A header that sends somebody to the wrong guard is the failure the roster
// below warns about, arriving in the prose instead of the code.
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
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';
import 'package:torque_obd/ui/screens/settings/manual_command_copy.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';
import '../support/fake_elm327.dart';

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
  TransportIssue.operationRetired,
  TransportIssue.requestUnaddressable,
  TransportIssue.customFlowControlRejected,
  TransportIssue.flowControlRestoreFailed,
  TransportIssue.extendedAddressingUnavailable,
  TransportIssue.rawIsoTpModeUnavailable,
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
    // wrong anywhere under `lib/obd/` or `lib/state/`. The only constructions
    // left carrying one are the subclasses that bake it into their own
    // constructors, and the roster below is what holds those.
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
    for (final file in _identifierSources()) {
      naked.addAll(_nakedIssues(file.path, file.readAsStringSync()));
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

  test('the subclasses that bake in a null identifier are the written roster', () {
    // `WriteRefusedException('...')` never matches `TransportException(`, so
    // the scan above cannot see that it passes `super(issue: null)`. All three
    // are correct today -- every throw of them is inside a `write(...)`, so none
    // reaches the connect screen -- but "correct today" is what a roster is for.
    // A fourth subclass doing the same has to be written here, where somebody
    // reads it and says why.
    const known = <String, String>{};

    // Every file in the directory, not just the one the three happen to live
    // in: review declared a fourth in `serial_transport.dart` and threw it from
    // `connect()`, and the roster never saw it.
    // Code only. Reading raw source made this cry wolf: a string containing
    // `class Imaginary extends TransportException {` -- a doc comment, an error
    // message, a test fixture pasted into a constant -- reported a subclass that
    // does not exist. A guard that names something imaginary is one people learn
    // to disbelieve, which is the same failure as the detector this file used to
    // carry. Found by trying it.
    // The same tree the scan walks. A subclass declared in `lib/state/` would
    // be as invisible to the scan as one in `lib/obd/`, and the roster is the
    // only thing that can see either.
    final sources = {
      for (final f in _identifierSources())
        f.path: codeOnly(f.readAsStringSync()),
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
    const identified = {
      'WriteRefusedException',
      'OperationRetiredException',
      'UnaddressableRequestException',
    };
    expect(
      declared,
      known.keys.toSet().union(identified),
      reason: 'a TransportException subclass was added or removed. If it bakes '
          'in `issue: null`, put it on the roster with why it can never reach '
          'the connect screen; if it carries an identifier, add it to '
          '`identified` instead.',
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

  test('the scan itself: a planted offender is reported, by line', () {
    // The scan above is a loop over files that are supposed to be clean, so a
    // green run is what it gives whether it is working or broken. Every other
    // check in this file has a fixture proving what it sees; this one had
    // none, and it is the check the slice exists for.
    const planted =
        "class X {\n"
        "  void f() {\n"
        "    throw const TransportException('尚未連線', issue: null);\n"
        "  }\n"
        "}\n";
    expect(
      _nakedIssues('lib/state/planted.dart', planted),
      ['lib/state/planted.dart:3 — issue: null'],
      reason: 'a throw with no identifier must be named, with its line',
    );
  });

  test('the scan itself: an identifier satisfies it, and its absence does not',
      () {
    // A clean fixture proves nothing on its own -- a scan that reads nothing
    // is also clean. So the same text is asserted twice: once with the
    // identifier, where it must be silent, and once with `null` in its place,
    // where it must speak. Only the pair says the fixture was reachable.
    const clean =
        "throw const TransportException('尚未連線', "
        "issue: TransportIssue.notConnected);";
    expect(_nakedIssues('lib/state/x.dart', clean), isEmpty);
    expect(
      _nakedIssues('lib/state/x.dart', clean.replaceAll(
        'TransportIssue.notConnected',
        'null',
      )),
      isNotEmpty,
      reason: 'the control: the same fixture, one identifier short',
    );
  });

  test('the scan itself: a construction inside a comment is not an offender',
      () {
    // The failure mode a substring search has, and the reason this repo
    // parses. Its sentinel is the same offender text as the positive fixture,
    // so a reader that stopped honouring comments would report this line and
    // the expectation names exactly what it would say.
    const commented =
        "// throw const TransportException('尚未連線', issue: null);\n"
        "throw const TransportException('x', issue: TransportIssue.cancelled);";
    expect(_nakedIssues('lib/state/x.dart', commented), isEmpty);
  });

  test('the reader itself: what counts as code', () {
    // The scan above is only as good as this, and this is the part that was
    // wrong twice. Fixtures rather than the real sources, because the real
    // sources are supposed to be clean -- a reader that has never seen the
    // shapes it exists to survive has not been tested on them.
    int callsFound(String src) {
      final mask = codeMask(src);
      return RegExp(r'\bTransportException\(')
          .allMatches(src)
          .where((m) => mask[m.start])
          .length;
    }

    expect(callsFound("// TransportException('x', issue: null);"), 0,
        reason: 'a line comment is not code');
    expect(callsFound("/* TransportException('x', issue: null); */"), 0,
        reason: 'a block comment is not code');
    // And a NESTED one, because that is a shape a block comment may take.
    // The comment here is the one from the compiled premise in
    // `test/support/dart_source_reader_test.dart`; what follows it is this
    // guard's own construction rather than that file's `const`, so the fixture
    // is a fragment and not a program — nothing here claims it runs. What is
    // measured is whether the reader still calls the throw code. Ended at the
    // FIRST `*/`, the apostrophe in `don't` opens a phantom literal which
    // swallows that line, and this guard stops seeing a construction it exists
    // to find — ImL1s/telltale#109.
    expect(
      callsFound("/* /* */ don't\n*/\nthrow TransportException('y', issue: null);"),
      1,
      reason: 'a nested block comment ends at its matching close, not the '
          'first one',
    );
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
    // Raw strings, same trap -- and the same reason the case above needed an
    // UNBALANCED quote. `r'${x}'` resynchronises whether or not the reader
    // knows raw strings have no interpolation, so the fixture written for this
    // bug stayed green under the very mutation it was added to catch. Found by
    // review, not by running it; the PR that added it claimed otherwise.
    //
    // Each of these puts an unbalanced quote where an interpolation would be.
    // Read as interpolation, that quote opens a literal which swallows the
    // rest of the source, and the call on the next line stops being code. Read
    // as content -- which is what Dart does -- the call is found.
    //
    // All four raw forms plus one nesting, because two wrong implementations
    // pass when only the first is here: one that gates on `'` alone, and one
    // that asks the OUTERMOST frame whether it is raw instead of the innermost.
    const rawForms = <String, String>{
      'single-quoted': "final d = r'\${don\"t}';\n",
      'double-quoted': 'final d = r"\${don\'t}";\n',
      'triple single-quoted': 'final d = r\'\'\'\${don"t}\'\'\';\n',
      'triple double-quoted': 'final d = r"""\${don\'t}""";\n',
    };
    // Nesting -- a raw literal inside an interpolation inside a non-raw one --
    // is NOT here, and that is the second thing this fixture had to learn.
    // Three attempts sat in this map, and all three passed with the raw gate
    // removed entirely. `codeMask` cannot see a nesting mistake through a
    // desync: whatever quote is injected, the enclosing literal brings its own
    // closing quote of the same type to pair with it, and the source
    // resynchronises before the call on the next line. Adding a second
    // injected quote does not help; that was tried too.
    //
    // The nesting case is pinned in l05_string_identifiers_test.dart instead,
    // by asserting the classification directly rather than a consequence of
    // it: `found("const a = '\${ r\"\${測試}\" }';")`. Consulting the
    // outermost frame instead of the innermost reddens that and nothing here.
    rawForms.forEach((label, prefix) {
      expect(
        callsFound('${prefix}throw TransportException(\'y\', issue: null);'),
        1,
        reason: 'a raw string has no interpolation, so the quote inside the '
            '$label form is content and must not open a literal',
      );
    });

    // The nesting-DEPTH axis, which every case above misses: they all put the
    // raw literal at depth 0 or 1, so nothing required that a `${` two
    // literals deep still opens an interpolation at all.
    //
    // `!(frames.last.raw || frames.length > 1)` over-suppresses exactly there,
    // passes all six reader tests, and makes a real `TransportException(`
    // stop being code:
    //
    //   fix codeOnly: "final s =    a(   TransportException(   , ...)  )  ;"
    //   bug codeOnly: "final s =    a(                       y        )  ;"
    //
    // A silent false negative in the guard, found by review after the four
    // raw forms were already in place.
    expect(
      callsFound(
        "final s = '\${a('\${TransportException('y', issue: null)}')}';",
      ),
      1,
      reason: 'a `\${` two literals deep still opens an interpolation',
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
      // null for them, so on that side the discriminator is not "answers" but
      // "answers at all". Nothing may be silent. There used to be a roster of
      // three identifiers excused from this -- an exception list living in
      // shipped `lib/` code that these tests then skipped on -- and it is gone:
      // the identifiers travel through `DtcReadException` now and the
      // fault-code screen renders them.
      if (command == null) {
        wrong.add(
          '$issue: the command table does not answer it, so a reader gets the '
          'exception\'s own Traditional Chinese back',
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

  test('a refused whole-vehicle header reaches the fault-code screen translated',
      () async {
    // What used to stand here was a 400-character regular expression pinning
    // the *source text* of `polling_engine.dart` -- `on TransportException
    // catch (e)` followed within 400 characters by `throw
    // DtcReadException(e.message)`. It existed to assert that the identifier
    // was still being discarded, so that fixing the discard would fail it. It
    // was also breakable by adding a comment between those two lines, which is
    // not a defect anybody should be told about, and it said nothing at all
    // about what a reader ends up seeing.
    //
    // This drives the whole path instead: an adapter that refuses `ATSH`, the
    // real client, the real engine, the real `DtcReadException`, and the real
    // function the fault-code screen renders its detail line with. It fails if
    // the identifier is dropped anywhere along it -- including inside the
    // retry loop, which rebuilds `DtcReadException`s of its own.
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: const {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
            '03': [0x43, 0x01, 0x43],
          },
        ),
      ],
      faults: const AdapterFaults(refuseHeaderSwitch: true),
    );
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);

    Object? thrown;
    try {
      await PollingEngine(client).readDtcs(DtcKind.stored);
    } on Object catch (e) {
      thrown = e;
    }
    expect(
      thrown,
      isA<DtcReadException>(),
      reason: 'the scan has to fail: nothing may present a one-controller '
          'answer as a whole-vehicle result',
    );
    final failure = thrown! as DtcReadException;
    expect(
      failure.transportIssue,
      TransportIssue.wholeVehicleHeaderRefused,
      reason: 'the identifier was dropped between sendGlobal and the screen, '
          'which is what left an English reader reading '
          '轉接器拒絕切換為功能定址 7DF',
    );
    expect(
      failure.issueDetail,
      '7DF',
      reason: 'the address the adapter refused; a sentence that cannot name it '
          'is one nobody can act on',
    );

    // And the screen's own function, in the reader's language.
    final wording = unansweredCategoryWording(
      l10n: en,
      kind: DtcKind.stored,
      result: DtcCategoryResult.failed(failure),
      storedAnswered: false,
    );
    expect(wording.detail, contains('7DF'));
    expect(
      containsChinese(wording.detail),
      isFalse,
      reason: 'the English build still renders the engine sentence: '
          '${wording.detail}',
    );
  });

  test('every issue a screen can reach has copy in both languages', () {
    for (final issue in TransportIssue.values) {
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
      expect(
        _text(en, issue),
        isNot(equals(_text(zh, issue))),
        reason: '$issue reads identically in both languages',
      );
    }
  });
}

/// Every `TransportException` construction in [src] that carries no usable
/// identifier, reported as `path:line — why`.
///
/// A function rather than a loop body so the fixtures below can drive the same
/// code the real scan runs. The scan used to be inline, which meant nothing
/// proved it reports anything: a version that silently found nothing would
/// have produced the same green run as a clean tree. `the scan itself: a
/// planted offender is reported` is what separates those two.
List<String> _nakedIssues(String path, String src) {
  final naked = <String>[];
  final mask = codeMask(src);

  for (final match in RegExp(r'\bTransportException\(').allMatches(src)) {
    final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
    if (!mask[match.start]) continue; // named inside a string or a comment
    final args = topLevelArgs(src, mask, match.end - 1);
    if (args == null) {
      // Not `continue`. An unreadable call used to be dropped in silence,
      // which turns ANY future desync -- whatever the vector -- into a green
      // run. Reporting it means the reader can still be wrong, but it cannot
      // be quiet about it.
      naked.add('$path:$line — could not be read');
      continue;
    }
    // The declaration itself, and only it. `args.any(contains)` also
    // matched a throw that passed a field named `message` -- review wrote
    // one: a transport with `final String message` and
    // `TransportException(this.message, issue: null)` passed the guard.
    if (path.endsWith('obd_transport.dart') &&
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
      naked.add('$path:$line — ${issue.isEmpty ? "no issue: argument" : issue}');
      continue;
    }
    final named = _interpolating.where(issue.contains);
    if (named.isNotEmpty) {
      // Present *and* not null, exactly as the `issue:` arm above. The
      // first version asked only whether the argument was written, and
      // review showed what that is worth: `issueDetail: null` at
      // `elm327_client.dart:1501` left this green while the sentence it
      // guards rendered with a hole where the header address goes. An
      // argument that is spelled but says nothing is the same defect as one
      // that was never spelled, and it looks more finished.
      final detail = trimmed.firstWhere(
        (a) => a.startsWith('issueDetail:'),
        orElse: () => '',
      );
      if (detail.isEmpty || detail.contains('null')) {
        naked.add(
          '$path:$line — ${named.first} '
          '${detail.isEmpty ? "without issueDetail:" : detail}',
        );
      }
    }
  }
  return naked;
}

/// Every Dart file a `TransportException` may be constructed in.
///
/// `lib/obd/` is the engine. `lib/state/` is here because `obd_session.dart`
/// constructs one too, and while it did not have to name an identifier this
/// scan could not see it. Recursive, and shared by the scan and the roster so
/// they cannot disagree about what "the source" means -- the roster used to
/// read one file while the scan walked the tree, and the narrower of the two
/// was the one that stayed green.
List<File> _identifierSources() => [
  ..._dartFilesUnder('lib/obd'),
  ..._dartFilesUnder('lib/state'),
];

List<File> _dartFilesUnder(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();
