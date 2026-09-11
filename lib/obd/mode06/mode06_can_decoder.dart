/// CAN (ISO 15765-4) Mode 06 monitor records.
///
/// Legacy (ISO 9141-2 / KWP / J1850) Mode 06 is a different layout and is
/// refused here. Unknown UAS IDs stay raw. Leftover bytes fail closed —
/// python-OBD `a378bdd81d58c67d08050e4244173a9a7dbda73d` truncates them;
/// that is a comparison aid, not the production rule.
library;

enum Mode06Completion { passed, failed, unknown }

final class Mode06DecodeException implements Exception {
  const Mode06DecodeException(this.message);

  final String message;

  @override
  String toString() => 'Mode06DecodeException: $message';
}

final class Mode06TestResult {
  const Mode06TestResult({
    required this.responder,
    required this.mid,
    required this.tid,
    required this.uasId,
    required this.rawValueBytes,
    required this.rawMinBytes,
    required this.rawMaxBytes,
    required this.value,
    required this.min,
    required this.max,
    required this.unitId,
    required this.completion,
  });

  final String responder;
  final int mid;
  final int tid;
  final int uasId;
  final List<int> rawValueBytes;
  final List<int> rawMinBytes;
  final List<int> rawMaxBytes;
  final double? value;
  final double? min;
  final double? max;
  final String? unitId;
  final Mode06Completion completion;
}

final class Mode06CanResponse {
  const Mode06CanResponse({
    required this.tests,
    required this.supportedMids,
  });

  final List<Mode06TestResult> tests;
  final Set<int> supportedMids;
}

final class _Uas {
  const _Uas({
    required this.signed,
    required this.scale,
    this.offset = 0,
    required this.unitId,
  });

  final bool signed;
  final double scale;
  final double offset;
  final String unitId;
}

/// Documented SAE J1979-DA subset used by the fixtures. Unknown IDs stay raw.
const _uas = <int, _Uas>{
  0x01: _Uas(signed: false, scale: 1, unitId: 'count'),
  0x0A: _Uas(signed: false, scale: 0.122, unitId: 'millivolt'),
  0x16: _Uas(signed: false, scale: 0.1, offset: -40, unitId: 'celsius'),
  0x81: _Uas(signed: true, scale: 1, unitId: 'count'),
};

const _supportMids = {0x00, 0x20, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0xE0};

abstract final class Mode06CanDecoder {
  static const _sid = 0x46;
  static const _testBlock = 9;

  static Mode06CanResponse decode({
    required List<int> payload,
    required String responder,
  }) {
    if (responder.trim().isEmpty) {
      throw const Mode06DecodeException('Mode 06 reply has no responder');
    }
    if (payload.isEmpty) {
      throw const Mode06DecodeException('Mode 06 payload is empty');
    }
    if (payload[0] != _sid) {
      throw Mode06DecodeException(
        'Mode 06 expected SID 0x46, got 0x${payload[0].toRadixString(16)}',
      );
    }
    if (payload.length < 2) {
      throw const Mode06DecodeException('Mode 06 payload has no monitor id');
    }
    final mid = payload[1];
    if (_supportMids.contains(mid)) {
      return _decodeSupport(payload, mid);
    }
    return _decodeTests(payload, responder);
  }

  static Mode06CanResponse _decodeSupport(List<int> payload, int mid) {
    if (payload.length != 6) {
      throw const Mode06DecodeException(
        'Mode 06 support mask must be SID, MID and four mask bytes',
      );
    }
    final maskBytes = payload.sublist(2, 6);
    final mask =
        (maskBytes[0] << 24) |
        (maskBytes[1] << 16) |
        (maskBytes[2] << 8) |
        maskBytes[3];
    final supported = <int>{};
    for (var bit = 0; bit < 32; bit++) {
      if ((mask & (1 << (31 - bit))) != 0) {
        supported.add(mid + bit + 1);
      }
    }
    return Mode06CanResponse(
      tests: const [],
      supportedMids: Set.unmodifiable(supported),
    );
  }

  static Mode06CanResponse _decodeTests(List<int> payload, String responder) {
    final body = payload.sublist(1);
    if (body.isEmpty || body.length % _testBlock != 0) {
      throw const Mode06DecodeException(
        'Mode 06 test payload is not a whole number of 9-byte records',
      );
    }
    final tests = <Mode06TestResult>[];
    for (var offset = 0; offset < body.length; offset += _testBlock) {
      tests.add(_decodeTest(body.sublist(offset, offset + _testBlock), responder));
    }
    return Mode06CanResponse(
      tests: List.unmodifiable(tests),
      supportedMids: const {},
    );
  }

  static Mode06TestResult _decodeTest(List<int> block, String responder) {
    final mid = block[0];
    final tid = block[1];
    final uasId = block[2];
    final rawValue = [block[3], block[4]];
    final rawMin = [block[5], block[6]];
    final rawMax = [block[7], block[8]];
    final uas = _uas[uasId];
    final value = uas == null ? null : _apply(uas, rawValue);
    final min = uas == null ? null : _apply(uas, rawMin);
    final max = uas == null ? null : _apply(uas, rawMax);
    return Mode06TestResult(
      responder: responder,
      mid: mid,
      tid: tid,
      uasId: uasId,
      rawValueBytes: rawValue,
      rawMinBytes: rawMin,
      rawMaxBytes: rawMax,
      value: value,
      min: min,
      max: max,
      unitId: uas?.unitId,
      completion: _completion(value, min, max),
    );
  }

  static double _apply(_Uas uas, List<int> bytes) {
    final unsigned = (bytes[0] << 8) | bytes[1];
    final raw = uas.signed && unsigned >= 0x8000
        ? unsigned - 0x10000
        : unsigned;
    return raw * uas.scale + uas.offset;
  }

  static Mode06Completion _completion(double? value, double? min, double? max) {
    if (value == null || min == null || max == null) {
      return Mode06Completion.unknown;
    }
    if (min > max) return Mode06Completion.unknown;
    if (value >= min && value <= max) return Mode06Completion.passed;
    return Mode06Completion.failed;
  }
}
