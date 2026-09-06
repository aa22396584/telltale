/// What to say about a code the app has never heard of.
///
/// The old answer was 動力系統相關故障 — true of every code on that screen, and
/// therefore worth nothing to somebody standing in front of a car. SAE J2012
/// assigns the third digit of a `P0` code to a subsystem, so `P0455` is an
/// auxiliary-emissions fault whether or not this app has a description for it.
/// That is read off the standard rather than guessed, which is the only kind of
/// claim this table is allowed to make about a code it does not know.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';

Dtc _dtc(String code) => Dtc(
      code: code,
      category: DtcCategory.powertrain,
      kind: DtcKind.stored,
      isManufacturerSpecific: code[1] == '1' || code[1] == '3',
    );

void main() {
  group('the third digit names the subsystem', () {
    // The subsystem is an identifier now, not a label: the words moved to the
    // ARBs when `lib/obd/` stopped carrying screen copy. What each identifier
    // says in each language is asserted in `test/l10n/l04_dtc_l10n_test.dart`,
    // including the block 9 wording this test was written to pin.
    test('each block maps to what J2012 assigns it', () {
      expect(_dtc('P0087').subsystem,
          PowertrainSubsystem.fuelAirMeteringAndAuxiliaryEmissions);
      expect(_dtc('P0171').subsystem, PowertrainSubsystem.fuelAirMetering);
      expect(_dtc('P0201').subsystem,
          PowertrainSubsystem.fuelAirMeteringInjectorCircuit);
      expect(_dtc('P0301').subsystem, PowertrainSubsystem.ignitionOrMisfire);
      expect(_dtc('P0455').subsystem,
          PowertrainSubsystem.auxiliaryEmissionControls);
      expect(_dtc('P0505').subsystem, PowertrainSubsystem.speedAndIdleControl);
      expect(_dtc('P0627').subsystem,
          PowertrainSubsystem.computerOutputCircuit);
      expect(_dtc('P0731').subsystem, PowertrainSubsystem.transmission);
      expect(_dtc('P0868').subsystem, PowertrainSubsystem.transmission);
      expect(_dtc('P0966').subsystem,
          PowertrainSubsystem.controlModuleSignals,
          reason: 'block 9 was the one entry with no test, and its wording had '
              'drifted into something no published block table says');
    });

    test('every block in the map is reachable and named', () {
      // The map and the tests above must not diverge: an entry nobody asserts
      // is an entry whose wording nobody checks, which is how block 9 acquired
      // a suffix that appears in no published table.
      for (final block in DtcDecoder.powertrainSubsystems.keys) {
        final code = 'P0${block.toRadixString(16).toUpperCase()}11';
        expect(DtcDecoder.subsystemOf(code),
            DtcDecoder.powertrainSubsystems[block],
            reason: 'block $block via $code');
      }
    });

    test('a described code keeps its description', () {
      // The subsystem is a fallback, not a replacement. Nothing about adding it
      // should make a known code less specific. That the description says
      // "misfire" in both languages is asserted in
      // `test/l10n/l04_dtc_l10n_test.dart`, where both locales are reachable.
      expect(_dtc('P0301').hasGenericDescription, isTrue);
      expect(DtcDecoder.describedCodes, contains('P0301'));
    });
  });

  group('and refuses to guess where the layout does not hold', () {
    test('manufacturer ranges get nothing', () {
      // In `P1` and `P3` the third digit means whatever the manufacturer
      // decided, so reading it as a subsystem would be inventing one.
      expect(_dtc('P1128').subsystem, isNull);
      expect(_dtc('P3400').subsystem, isNull);
    });

    test('P2 gets nothing, because its numbering is not the same layout', () {
      // The trap this rule exists to avoid: `P2004` is intake manifold runner
      // control stuck open. Read as a third-digit block it would come out as a
      // fuel-metering fault, which is a confident wrong answer — the failure
      // this file's neighbours are all arranged against.
      expect(_dtc('P2004').subsystem, isNull);
      expect(_dtc('P2135').subsystem, isNull);
    });

    test('chassis, body and network codes get nothing', () {
      expect(_dtc('C0561').subsystem, isNull);
      expect(_dtc('B0001').subsystem, isNull);
      expect(_dtc('U0100').subsystem, isNull);
    });

    test('malformed input does not throw', () {
      expect(DtcDecoder.subsystemOf(''), isNull);
      expect(DtcDecoder.subsystemOf('P0'), isNull);
      expect(DtcDecoder.subsystemOf('P0ZZZ'), isNull);
      expect(DtcDecoder.subsystemOf('POO11'), isNull);
    });
  });

  group('the description table itself', () {
    test('every key is a code the decoder can produce', () {
      // Catches a typo in a key — `P0O11` with a letter O, say — which would
      // otherwise sit in the table forever as a description that can never be
      // looked up, and read as coverage the app does not have.
      for (final code in DtcDecoder.describedCodes) {
        final pair = DtcDecoder.encode(code);
        expect(pair, isNotNull, reason: '$code is not a well-formed DTC');
        final round = DtcDecoder.decodePair(pair!.$1, pair.$2, DtcKind.stored);
        expect(round?.code, code, reason: '$code did not round-trip');
      }
    });

    test('no key is in a manufacturer range', () {
      // `hasGenericDescription` is false for those regardless, so such an entry
      // would be unreachable data claiming to be coverage.
      for (final code in DtcDecoder.describedCodes) {
        expect(code[1], isNot(anyOf('1', '3')),
            reason: '$code is manufacturer-specific and can never be shown');
      }
    });

    test('every described code is reachable through Dtc', () {
      // A code can be well-formed, non-manufacturer and still never surface if
      // `hasGenericDescription` disagrees about what counts as generic.
      //
      // That no description is empty, and that none is a bare restatement of
      // its own code, moved to `test/l10n/l04_dtc_l10n_test.dart` with the
      // descriptions themselves — it is now checked in both languages rather
      // than one.
      for (final code in DtcDecoder.describedCodes) {
        expect(_dtc(code).hasGenericDescription, isTrue,
            reason: '$code is in the set but nothing can ever show it');
      }
    });
  });
}
