/// Bounded ISO-TP assembler: PCI, length, sequence, Flow Control.
///
/// Fixtures are hand-typed PCI bytes. This is not a copy of a vcan suite.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/iso_tp_assembler.dart';

void main() {
  test('frameObdRequest prefixes a Single Frame PCI', () {
    expect(IsoTpAssembler.frameObdRequest('010C'), '02010C');
    expect(IsoTpAssembler.frameObdRequest('0902'), '020902');
    expect(IsoTpAssembler.frameObdRequest('ATCAF0'), isNull);
    expect(IsoTpAssembler.frameObdRequest('010C0D050B0F1115'), isNull);
  });

  test('single-frame PCI 0x0 yields the declared payload', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x04, 0x41, 0x0C, 0x1A, 0xF8, 0x00, 0x00, 0x00],
      ]),
      [0x41, 0x0C, 0x1A, 0xF8],
    );
  });

  test('multi-frame VIN First/Consecutive frames reassemble the datasheet PDU', () {
    final pdu = IsoTpAssembler.reassemble([
      [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
      [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
      [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
    ]);
    expect(pdu, isNotNull);
    expect(pdu!.length, 20);
    expect(String.fromCharCodes(pdu.skip(3)), '1D4GP00R55B123456');
  });

  test('First Frame total at or below Single Frame capacity is refused', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x05, 0x41, 0x00, 0xBE, 0x3F, 0xB8],
      ]),
      isNull,
    );
  });

  test('declared total above the host bound is refused', () {
    expect(
      IsoTpAssembler.reassemble(
        [
          [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
          [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
          [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
        ],
        maxPduBytes: 16,
      ),
      isNull,
    );
  });

  test('twelve-bit maximum is the default cap', () {
    expect(IsoTpAssembler.maxPduBytes, 4095);
    expect(
      IsoTpAssembler.reassemble([
        [0x1F, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
      ]),
      isNull,
    );
  });

  test('sequence wrap 15 then 0 is accepted', () {
    final first = <int>[0x10, 0x70, ...List.filled(6, 0xAA)];
    final frames = <List<int>>[first];
    for (var seq = 1; seq <= 16; seq++) {
      frames.add([0x20 | (seq & 0x0F), ...List.filled(7, 0xBB)]);
    }
    final pdu = IsoTpAssembler.reassemble(frames);
    expect(pdu, isNotNull);
    expect(pdu!.length, 0x70);
  });

  test('missing Consecutive Frame is unavailable, not a short PDU', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
      ]),
      isNull,
    );
  });

  test('extra Consecutive Frame after the declared length is unavailable', () {
    // Declared 13 bytes: FF (6) + CF1 (7) completes the PDU; CF2 must not
    // be silently discarded.
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x0D, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
        [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
      ]),
      isNull,
    );
  });

  test('truncated classic-CAN First Frame is unavailable', () {
    // 12-byte PDU: a 7-byte FF would contribute 5 data bytes and let CF
    // padding satisfy total with a shifted payload.
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x0C, 0x49, 0x02, 0x01, 0x31, 0x44],
        [0x21, 0x34, 0x47, 0x50, 0x30, 0x30, 0x52, 0x00],
      ]),
      isNull,
    );
  });

  test('short non-final Consecutive Frame is unavailable', () {
    // 18-byte PDU: FF carries 6, CF1 must carry 7, CF2 the last 5.
    // A 6-byte CF1 would let CF2 padding become payload.
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x12, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35],
        [0x22, 0x35, 0x42, 0x31, 0x32, 0x33, 0x34, 0x00],
      ]),
      isNull,
    );
  });

  test('duplicate Consecutive Frame is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
        [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
      ]),
      isNull,
    );
  });

  test('out-of-order Consecutive Frame is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
      ]),
      isNull,
    );
  });

  test('wrong PCI high nibble is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x50, 0x41, 0x0C, 0x1A, 0xF8],
      ]),
      isNull,
    );
  });

  test('Flow Control WAIT is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x31, 0x00, 0x00],
      ]),
      isNull,
    );
  });

  test('Flow Control overflow is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x32, 0x00, 0x00],
      ]),
      isNull,
    );
  });

  test('Flow Control in the Consecutive stream is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34],
        [0x31, 0x01, 0x00],
        [0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35],
        [0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36],
      ]),
      isNull,
    );
  });

  test('a smashed First Frame longer than eight CAN bytes is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [
          0x10, 0x14, 0x49, 0x02, 0x01, 0x31, 0x44, 0x34, //
          0x21, 0x47, 0x50, 0x30, 0x30, 0x52, 0x35, 0x35,
          0x22, 0x42, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36,
        ],
      ]),
      isNull,
    );
  });

  test('Single Frame length over seven is unavailable', () {
    expect(
      IsoTpAssembler.reassemble([
        [0x08, 0x41, 0x00, 0xBE, 0x3F, 0xB8, 0x13, 0x00],
      ]),
      isNull,
    );
  });
}
