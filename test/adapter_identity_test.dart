/// What the adapter says about itself.
///
/// The rule these tests exist to hold is a boundary, not a feature: this check
/// answers "is this device what it claims to be" and must never be read as
/// "are these readings true". A check that overreaches here is worse than no
/// check, because a driver who trusts a green tick stops looking.
///
/// The false-positive direction matters more than the false-negative one.
/// `v1.5` is printed on a very large share of the adapters actually sold, and
/// most of them work — so a concern is information, never an alarm, and
/// anything that fires on a *good* adapter is a defect.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/adapter_identity.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';

AdapterIdentity _id(String version,
        {String identity = 'OBDII to RS232 Interpreter',
        PpsProbe pps = PpsProbe.read,
        IdentityProbe identityProbe = IdentityProbe.read}) =>
    AdapterIdentity(
      version: version,
      identity: identity,
      pps: pps,
      identityProbe: identityProbe,
    );

void main() {
  group('a version that was never released', () {
    test('v1.5 is named, because Elm Electronics never shipped one', () {
      final concerns = _id('ELM327 v1.5').concerns;
      expect(concerns, hasLength(1));
      expect(concerns.single.kind, AdapterConcernKind.firmwareNeverReleased);
      expect(concerns.single.version, '1.5');
      // The evidence header keeps its Chinese; the screen's words are asserted
      // in both languages in test/l10n/adapter_concern_l10n_test.dart.
      expect(concerns.single.exportSummary, contains('v1.5'));
      expect(concerns.single.exportSummary, contains('從未發行'),
          reason: 'the summary states it as a fact, because it is one');
    });

    test('and v1.4a, which is the same trick one digit over', () {
      expect(_id('ELM327 v1.4a').concerns, hasLength(1));
    });

    test('but v1.4b is a real release and passes', () {
      // What OBDLink's STN chips report. Flagging this would fire on the best
      // hardware a person can buy, which is the failure mode that makes a
      // check worthless.
      expect(_id('ELM327 v1.4b').concerns, isEmpty);
      expect(_id('ELM327 v1.4b').isSelfConsistent, isTrue);
    });

    test('and so do v1.0, v1.1, v1.2, v1.3, v1.4 and v2.x', () {
      for (final v in [
        'ELM327 v1.0',
        'ELM327 v1.1',
        'ELM327 v1.2',
        'ELM327 v1.3',
        'ELM327 v1.4',
        'ELM327 v2.0',
        'ELM327 v2.1',
        'ELM327 v2.2',
        'ELM327 v2.3',
      ]) {
        expect(_id(v).concerns, isEmpty, reason: '$v is a real release');
      }
    });
  });

  group('a version that contradicts the commands it implements', () {
    test('claiming v2.1 while refusing ATPPS is a contradiction', () {
      // `ATPPS` shipped in v1.1 and OBDLink supports it, so an explicit `?`
      // from something claiming v2.1 is the device disagreeing with itself.
      final concerns = _id('ELM327 v2.1', pps: PpsProbe.refused).concerns;
      expect(concerns, hasLength(1));
      expect(concerns.single.kind,
          AdapterConcernKind.ppsRefusedDespiteVersion);
    });

    test('claiming v1.0 and refusing ATPPS is not', () {
      // v1.0 predates the command. Refusing it is correct behaviour, and
      // calling that a fault would punish the one adapter telling the truth.
      expect(_id('ELM327 v1.0', pps: PpsProbe.refused).concerns, isEmpty);
    });

    test('and ATPPS merely not answering is never a concern', () {
      // The rule this whole enum exists for. A timeout, an unreadable reply or
      // a thrown exception says something about the moment, not the device —
      // and `ProgrammableParameters.wasRead` cannot tell those from a refusal,
      // which is why it is not what this reads.
      for (final v in ['ELM327 v1.1', 'ELM327 v2.1', 'ELM327 v1.4b']) {
        expect(_id(v, pps: PpsProbe.unavailable).concerns, isEmpty,
            reason: 'a dropped packet must not accuse $v of being a clone');
      }
    });
  });

  test('an adapter that REFUSES AT@1 is below every real release', () {
    final concerns = _id(
      'ELM327 v2.1',
      identity: '',
      identityProbe: IdentityProbe.refused,
    ).concerns;
    expect(concerns, hasLength(1));
    expect(concerns.single.kind, AdapterConcernKind.noIdentityResponse);
  });

  test('but silence on AT@1 accuses nobody', () {
    // The reason this exists: `identity.isEmpty` could not tell a refusal from
    // a timeout, a DATA ERROR or a dropped Bluetooth packet, so one unlucky
    // handshake put a permanent ⚠ and "this chip implements a smaller command
    // set than any official firmware" against an honest adapter — on the
    // screen whose entire job is to be right about the adapter, and which the
    // store listing points at with "when it is unsure, it says so".
    //
    // `PpsProbe` had solved this sixty lines away in the same file and the
    // rule was never carried across. It is the same rule: only a refusal is
    // evidence about the device; an absence is evidence about the moment.
    for (final probe in [IdentityProbe.unavailable, IdentityProbe.read]) {
      expect(
        _id('ELM327 v2.1', identity: '', identityProbe: probe).concerns,
        isEmpty,
        reason: '$probe is not the adapter saying anything about itself',
      );
    }
  });

  test('concerns accumulate rather than shadowing each other', () {
    final concerns = _id(
      'ELM327 v1.5',
      identity: '',
      pps: PpsProbe.refused,
      identityProbe: IdentityProbe.refused,
    ).concerns;
    expect(concerns, hasLength(3),
        reason: 'each is a separate observation and the export should carry '
            'all of them');
    // All three now require a refusal rather than an absence. An adapter that
    // simply went quiet raises none of them, which is the point: three ⚠ from
    // one dropped connection would read as a damning verdict assembled
    // entirely out of silence.
    expect(
      _id(
        'ELM327 v1.5',
        identity: '',
        pps: PpsProbe.unavailable,
        identityProbe: IdentityProbe.unavailable,
      ).concerns,
      hasLength(1),
      reason: 'only the firmware version survives, because it is the one '
          'thing the adapter actually said',
    );
  });

  group('the export line', () {
    test('is printable when the adapter answered nothing at all', () {
      final line = _id('', identity: '', pps: PpsProbe.unavailable).summaryLine;
      expect(line, contains('未回報'));
      expect(line, contains('未回應 AT@1'));
      expect(line, isNot(contains('null')));
    });

    test('names the probe outcome, so the log says which of the three it was',
        () {
      expect(_id('ELM327 v1.4b').summaryLine, contains('已讀取'));
      expect(_id('ELM327 v1.4b', pps: PpsProbe.refused).summaryLine,
          contains('遭拒'));
      expect(_id('ELM327 v1.4b', pps: PpsProbe.unavailable).summaryLine,
          contains('無回應'));
    });
  });

  group('banners that are not the expected shape', () {
    test('a banner with no version number raises nothing about versions', () {
      // Some clones answer `ATI` with a product name. There is nothing to
      // check against, and inventing a complaint from an absence is how a
      // check starts crying wolf.
      final concerns = _id('OBDII Bluetooth v3.0 Super').concerns;
      expect(
        concerns.where(
          (c) => c.kind == AdapterConcernKind.firmwareNeverReleased,
        ),
        isEmpty,
      );
    });

    test('and the version parser is not fooled by a number elsewhere', () {
      expect(_id('STN2232 v5.10.3').versionNumber, isNull,
          reason: 'that is an STI reply, not an ELM327 banner');
    });

    test('a real ELM327 banner parses to its number', () {
      expect(_id('ELM327 v2.1').versionNumber, '2.1');
      expect(_id('ELM327 v1.4b').versionNumber, '1.4b');
      expect(_id('ELM327 v1.4b').versionValue, 1.4);
    });
  });

  test('the demo simulator does not contradict itself', () async {
    // Found by shipping this check and looking at the first screen it drew:
    // the built-in demo announced `ELM327 v2.1` and answered `?` to `ATPPS`,
    // which is precisely the contradiction above. The check was right and the
    // simulator was wrong — it was being more forgiving than the hardware it
    // stands in for, which this project treats as a defect in its own right,
    // because a bug that the simulator cannot produce is a bug nothing catches
    // until a car does.
    //
    // Driven through the real transport rather than asserted against a string,
    // so it stays true if the demo's banner or its AT handling moves.
    final transport = DemoTransport();
    await transport.connect();
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);

    final identity = client.adapterIdentity;
    expect(identity.versionNumber, isNotNull,
        reason: 'the demo announces a version, so it is held to it');
    expect(identity.concerns, isEmpty,
        reason: identity.concerns.map((c) => c.exportSummary).join('; '));

    await client.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
