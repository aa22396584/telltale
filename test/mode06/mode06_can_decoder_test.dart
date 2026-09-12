/// Literal CAN Mode 06 fixtures. Production must not generate these bytes.
///
/// Independently: UAS 0x0A is 0.122 mV/count, so 0x0064 → 12.2 mV.
/// Comparison aid (not a fixture source): python-OBD
/// `a378bdd81d58c67d08050e4244173a9a7dbda73d`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/mode06/mode06_can_decoder.dart';

void main() {
  test('constructor inputs cannot mutate retained Mode 06 evidence', () {
    final rawValueBytes = <int>[0x00, 0x64];
    final rawMinBytes = <int>[0x00, 0x00];
    final rawMaxBytes = <int>[0x00, 0xC8];
    final testResult = Mode06TestResult(
      responder: '7E8',
      mid: 0x01,
      tid: 0x80,
      uasId: 0x0A,
      rawValueBytes: rawValueBytes,
      rawMinBytes: rawMinBytes,
      rawMaxBytes: rawMaxBytes,
      value: 12.2,
      min: 0,
      max: 24.4,
      unitId: 'millivolt',
      completion: Mode06Completion.passed,
    );
    final tests = <Mode06TestResult>[testResult];
    final supportedMids = <int>{0x01};
    final response = Mode06CanResponse(
      responder: '7E8',
      tests: tests,
      supportedMids: supportedMids,
    );

    rawValueBytes[1] = 0x65;
    rawMinBytes[1] = 0x01;
    rawMaxBytes[1] = 0xC7;
    tests.clear();
    supportedMids.add(0x02);

    expect(testResult.rawValueBytes, [0x00, 0x64]);
    expect(testResult.rawMinBytes, [0x00, 0x00]);
    expect(testResult.rawMaxBytes, [0x00, 0xC8]);
    expect(response.tests, [testResult]);
    expect(response.supportedMids, {0x01});
  });

  test('Mode 06 collection getters reject mutation', () {
    final decodedTests = Mode06CanDecoder.decode(
      payload: const [
        0x46, 0x01, 0x80, 0x0A, 0x00, 0x64, 0x00, 0x00, 0x00, 0xC8,
      ],
      responder: '7E8',
    );
    final decodedSupport = Mode06CanDecoder.decode(
      payload: const [0x46, 0x00, 0x80, 0x00, 0x00, 0x00],
      responder: '7E8',
    );
    final testResult = decodedTests.tests.single;

    expect(() => testResult.rawValueBytes[1] = 0x65, throwsUnsupportedError);
    expect(() => testResult.rawMinBytes[1] = 0x01, throwsUnsupportedError);
    expect(() => testResult.rawMaxBytes[1] = 0xC7, throwsUnsupportedError);
    expect(() => decodedTests.tests.clear(), throwsUnsupportedError);
    expect(() => decodedSupport.supportedMids.add(0x02), throwsUnsupportedError);
  });

  test('a millivolt monitor test decodes value and limits', () {
    // 46 01 80 0A 00 64 00 00 00 C8
    const payload = <int>[
      0x46, 0x01, 0x80, 0x0A, 0x00, 0x64, 0x00, 0x00, 0x00, 0xC8,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests, hasLength(1));
    final test = decoded.tests.single;
    expect(test.responder, '7E8');
    expect(test.mid, 0x01);
    expect(test.tid, 0x80);
    expect(test.uasId, 0x0A);
    expect(test.value, closeTo(12.2, 1e-9));
    expect(test.min, closeTo(0.0, 1e-9));
    expect(test.max, closeTo(24.4, 1e-9));
    expect(test.unitId, 'millivolt');
    expect(test.completion, Mode06Completion.passed);
  });

  test('mutating the value byte fails the independently derived 12.2 mV', () {
    const payload = <int>[
      0x46, 0x01, 0x80, 0x0A, 0x00, 0x65, 0x00, 0x00, 0x00, 0xC8,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests.single.value, isNot(closeTo(12.2, 1e-9)));
    expect(decoded.tests.single.value, closeTo(12.322, 1e-9));
  });

  test('value outside min/max is failed, not passed', () {
    const payload = <int>[
      0x46, 0x01, 0x80, 0x0A, 0x00, 0xC9, 0x00, 0x00, 0x00, 0xC8,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests.single.completion, Mode06Completion.failed);
  });

  test('unknown UAS stays raw and does not invent a number', () {
    const payload = <int>[
      0x46, 0x01, 0x80, 0x7F, 0x00, 0x64, 0x00, 0x00, 0x00, 0xC8,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    final test = decoded.tests.single;
    expect(test.value, isNull);
    expect(test.min, isNull);
    expect(test.max, isNull);
    expect(test.rawValueBytes, [0x00, 0x64]);
    expect(test.completion, Mode06Completion.unknown);
  });

  test('signed UAS 0x81 keeps a negative extrema', () {
    const payload = <int>[
      0x46, 0x21, 0x01, 0x81, 0x80, 0x00, 0x80, 0x00, 0x00, 0x10,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    final test = decoded.tests.single;
    expect(test.value, -32768);
    expect(test.min, -32768);
    expect(test.max, 16);
    expect(test.completion, Mode06Completion.passed);
  });

  test('a wrong service byte is refused, not decoded as a monitor', () {
    expect(
      () => Mode06CanDecoder.decode(
        payload: const [0x43, 0x00],
        responder: '7E8',
      ),
      throwsA(isA<Mode06DecodeException>()),
    );
  });

  test('a truncated test record fails closed', () {
    expect(
      () => Mode06CanDecoder.decode(
        payload: const [0x46, 0x01, 0x80, 0x0A, 0x00, 0x64, 0x00, 0x00, 0x00],
        responder: '7E8',
      ),
      throwsA(isA<Mode06DecodeException>()),
    );
  });

  test('leftover bytes are refused rather than truncated', () {
    expect(
      () => Mode06CanDecoder.decode(
        payload: const [
          0x46, 0x01, 0x80, 0x0A, 0x00, 0x64, 0x00, 0x00, 0x00, 0xC8, 0xFF,
        ],
        responder: '7E8',
      ),
      throwsA(isA<Mode06DecodeException>()),
    );
  });

  test('an empty payload is not a clean monitor set', () {
    expect(
      () => Mode06CanDecoder.decode(payload: const [], responder: '7E8'),
      throwsA(isA<Mode06DecodeException>()),
    );
  });

  test('MID 00 support mask names the next twenty monitors', () {
    const payload = <int>[0x46, 0x00, 0x80, 0x00, 0x00, 0x00];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests, isEmpty);
    expect(decoded.responder, '7E8');
    expect(decoded.supportedMids, {0x01});
  });

  test('a second controller support mask keeps its own responder', () {
    const payload = <int>[0x46, 0x00, 0x80, 0x00, 0x00, 0x00];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E9',
    );
    expect(decoded.responder, '7E9');
    expect(decoded.supportedMids, {0x01});
  });

  test('MID C0 support mask can advertise terminal test MID E0', () {
    const payload = <int>[0x46, 0xC0, 0x00, 0x00, 0x00, 0x01];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests, isEmpty);
    expect(decoded.responder, '7E8');
    expect(decoded.supportedMids, {0xE0});
  });

  test('MID E0 is a test record, not a support page', () {
    const payload = <int>[
      0x46, 0xE0, 0x01, 0x0A, 0x00, 0x64, 0x00, 0x00, 0x00, 0xC8,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.supportedMids, isEmpty);
    expect(decoded.tests, hasLength(1));
    expect(decoded.tests.single.mid, 0xE0);
    expect(decoded.tests.single.value, closeTo(12.2, 1e-9));
  });

  test('inconsistent min > max is unknown, not a pass', () {
    const payload = <int>[
      0x46, 0x01, 0x80, 0x0A, 0x00, 0x10, 0x00, 0x20, 0x00, 0x10,
    ];
    final decoded = Mode06CanDecoder.decode(
      payload: payload,
      responder: '7E8',
    );
    expect(decoded.tests.single.completion, Mode06Completion.unknown);
  });
}
