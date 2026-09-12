import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_codec.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';

void main() {
  group('Mode08DiscoveryCodec non-actuating capability discovery', () {
    test('createSupportedTidCommand only accepts standard base TIDs', () {
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0x00), '0800');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0x20), '0820');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0x40), '0840');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0x60), '0860');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0x80), '0880');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0xA0), '08A0');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0xC0), '08C0');
      expect(Mode08DiscoveryCodec.createSupportedTidCommand(0xE0), '08E0');
    });

    test('probing runnable TIDs throws ProhibitedActiveProbeException', () {
      // Actuation TIDs must never be probed to discover support
      expect(
        () => Mode08DiscoveryCodec.createSupportedTidCommand(0x01),
        throwsA(isA<ProhibitedActiveProbeException>()),
      );
      expect(
        () => Mode08DiscoveryCodec.createSupportedTidCommand(0x02),
        throwsA(isA<ProhibitedActiveProbeException>()),
      );
      expect(
        () => Mode08DiscoveryCodec.createSupportedTidCommand(0x10),
        throwsA(isA<ProhibitedActiveProbeException>()),
      );
    });

    test('parses positive supported TID bitmask response', () {
      // 48 00 80 00 00 00 -> Bit 31 set: TID 0x01 is supported
      final result1 = Mode08DiscoveryCodec.parseResponse(
        '48 00 80 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(result1, isA<Mode08SupportSuccess>());
      final success1 = result1 as Mode08SupportSuccess;
      expect(success1.baseTid, 0x00);
      expect(success1.supportedTids, {0x01});
      expect(success1.isTidSupported(0x01), isTrue);
      expect(success1.isTidSupported(0x02), isFalse);
      expect(success1.hasNextBlock, isFalse);

      // 48 00 80 00 00 01 -> TID 0x01 and TID 0x20 supported, hasNextBlock is true
      final result2 = Mode08DiscoveryCodec.parseResponse(
        '48 00 80 00 00 01',
        expectedBaseTid: 0x00,
      );
      expect(result2, isA<Mode08SupportSuccess>());
      final success2 = result2 as Mode08SupportSuccess;
      expect(success2.supportedTids, {0x01, 0x20});
      expect(success2.hasNextBlock, isTrue);

      // 48 20 C0 00 00 00 -> base TID 0x20, bits 31 and 30 set: TIDs 0x21 and 0x22
      final result3 = Mode08DiscoveryCodec.parseResponse(
        '48 20 C0 00 00 00',
        expectedBaseTid: 0x20,
      );
      expect(result3, isA<Mode08SupportSuccess>());
      final success3 = result3 as Mode08SupportSuccess;
      expect(success3.baseTid, 0x20);
      expect(success3.supportedTids, {0x21, 0x22});
    });

    test('parses negative responses and classifies NRCs with sound fallback', () {
      // 0x11 serviceNotSupported -> unsupported
      final res11 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 11',
        expectedBaseTid: 0x00,
      );
      expect(res11, isA<Mode08NegativeResponse>());
      final neg11 = res11 as Mode08NegativeResponse;
      expect(neg11.originalSid, 0x08);
      expect(neg11.nrc, 0x11);
      expect(neg11.isUnsupported, isTrue);
      expect(neg11.supportStatus, EcuSupportStatus.unsupported);

      // 0x12 subFunctionNotSupported -> unsupported
      final res12 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 12',
        expectedBaseTid: 0x00,
      );
      expect(res12, isA<Mode08NegativeResponse>());
      final neg12 = res12 as Mode08NegativeResponse;
      expect(neg12.nrc, 0x12);
      expect(neg12.isUnsupported, isTrue);
      expect(neg12.supportStatus, EcuSupportStatus.unsupported);

      // 0x31 requestOutOfRange -> unsupported
      final res31 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 31',
        expectedBaseTid: 0x00,
      );
      expect(res31, isA<Mode08NegativeResponse>());
      final neg31 = res31 as Mode08NegativeResponse;
      expect(neg31.nrc, 0x31);
      expect(neg31.isUnsupported, isTrue);
      expect(neg31.supportStatus, EcuSupportStatus.unsupported);

      // 0x22 conditionsNotCorrect -> fallback to unknown (service may exist!)
      final res22 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 22',
        expectedBaseTid: 0x00,
      );
      expect(res22, isA<Mode08NegativeResponse>());
      final neg22 = res22 as Mode08NegativeResponse;
      expect(neg22.nrc, 0x22);
      expect(neg22.isConditionsNotCorrect, isTrue);
      expect(neg22.isUnsupported, isFalse);
      expect(neg22.supportStatus, EcuSupportStatus.unknown);

      // 0x21 busyRepeatRequest -> unknown
      final res21 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 21',
        expectedBaseTid: 0x00,
      );
      expect(res21, isA<Mode08NegativeResponse>());
      final neg21 = res21 as Mode08NegativeResponse;
      expect(neg21.isBusy, isTrue);
      expect(neg21.supportStatus, EcuSupportStatus.unknown);

      // 0x33 securityAccessDenied -> unknown
      final res33 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 33',
        expectedBaseTid: 0x00,
      );
      expect(res33, isA<Mode08NegativeResponse>());
      final neg33 = res33 as Mode08NegativeResponse;
      expect(neg33.isSecurityAccessDenied, isTrue);
      expect(neg33.supportStatus, EcuSupportStatus.unknown);

      // 0x78 responsePending -> unknown
      final res78 = Mode08DiscoveryCodec.parseResponse(
        '7F 08 78',
        expectedBaseTid: 0x00,
      );
      expect(res78, isA<Mode08NegativeResponse>());
      final neg78 = res78 as Mode08NegativeResponse;
      expect(neg78.isResponsePending, isTrue);
      expect(neg78.supportStatus, EcuSupportStatus.unknown);
    });

    test('parses silence / NO DATA / timeout as unknown, never unsupported', () {
      final noData = Mode08DiscoveryCodec.parseResponse(
        'NO DATA',
        expectedBaseTid: 0x00,
      );
      expect(noData, isA<Mode08NoResponse>());
      expect((noData as Mode08NoResponse).supportStatus, EcuSupportStatus.unknown);

      final empty = Mode08DiscoveryCodec.parseResponse(
        '',
        expectedBaseTid: 0x00,
      );
      expect(empty, isA<Mode08NoResponse>());
      expect((empty as Mode08NoResponse).supportStatus, EcuSupportStatus.unknown);

      final busError = Mode08DiscoveryCodec.parseResponse(
        'BUS ERROR',
        expectedBaseTid: 0x00,
      );
      expect(busError, isA<Mode08NoResponse>());
      expect((busError as Mode08NoResponse).supportStatus, EcuSupportStatus.unknown);
    });

    test('detects malformed responses fail-closed', () {
      // Truncated positive response
      final truncated = Mode08DiscoveryCodec.parseResponse(
        '48 00 80',
        expectedBaseTid: 0x00,
      );
      expect(truncated, isA<Mode08MalformedResponse>());
      expect((truncated as Mode08MalformedResponse).reason,
          Mode08MalformedReason.truncated);

      // Wrong SID (e.g. Mode 01 PID 00 response 41 00 ...)
      final wrongSid = Mode08DiscoveryCodec.parseResponse(
        '41 00 80 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(wrongSid, isA<Mode08MalformedResponse>());
      expect((wrongSid as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidSid);

      // Wrong base TID echo (got 0x20 when expecting 0x00)
      final wrongEcho = Mode08DiscoveryCodec.parseResponse(
        '48 20 80 00 00 00',
        expectedBaseTid: 0x00,
      );
      expect(wrongEcho, isA<Mode08MalformedResponse>());
      expect((wrongEcho as Mode08MalformedResponse).reason,
          Mode08MalformedReason.wrongBaseTidEcho);

      // Truncated negative response
      final truncatedNeg = Mode08DiscoveryCodec.parseResponse(
        '7F 08',
        expectedBaseTid: 0x00,
      );
      expect(truncatedNeg, isA<Mode08MalformedResponse>());
      expect((truncatedNeg as Mode08MalformedResponse).reason,
          Mode08MalformedReason.truncated);

      // Negative response with wrong original SID (0x01 instead of 0x08)
      final wrongOrigSid = Mode08DiscoveryCodec.parseResponse(
        '7F 01 11',
        expectedBaseTid: 0x00,
      );
      expect(wrongOrigSid, isA<Mode08MalformedResponse>());
      expect((wrongOrigSid as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidNegativeResponse);

      // Positive response with extra trailing bytes (> 6 bytes)
      final extraBytes = Mode08DiscoveryCodec.parseResponse(
        '48 00 80 00 00 00 FF FF',
        expectedBaseTid: 0x00,
      );
      expect(extraBytes, isA<Mode08MalformedResponse>());
      expect((extraBytes as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidBitmaskLength);

      // Positive response with non-hex characters
      final nonHex = Mode08DiscoveryCodec.parseResponse(
        '4800800000ZZ',
        expectedBaseTid: 0x00,
      );
      expect(nonHex, isA<Mode08MalformedResponse>());
      expect((nonHex as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidHex);

      // Positive response with odd-length characters
      final oddLength = Mode08DiscoveryCodec.parseResponse(
        '480080000000A',
        expectedBaseTid: 0x00,
      );
      expect(oddLength, isA<Mode08MalformedResponse>());
      expect((oddLength as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidBitmaskLength);

      // Negative response with extra trailing bytes (> 3 bytes)
      final extraNeg = Mode08DiscoveryCodec.parseResponse(
        '7F 08 11 99',
        expectedBaseTid: 0x00,
      );
      expect(extraNeg, isA<Mode08MalformedResponse>());
      expect((extraNeg as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidNegativeResponse);

      // Negative response with reserved NRC 0x00
      final zeroNrc = Mode08DiscoveryCodec.parseResponse(
        '7F 08 00',
        expectedBaseTid: 0x00,
      );
      expect(zeroNrc, isA<Mode08MalformedResponse>());
      expect((zeroNrc as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidNegativeResponse);

      // Negative response with reserved NRC 0x05
      final nonStandardNrc = Mode08DiscoveryCodec.parseResponse(
        '7F 08 05',
        expectedBaseTid: 0x00,
      );
      expect(nonStandardNrc, isA<Mode08MalformedResponse>());
      expect((nonStandardNrc as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidNegativeResponse);

      // Negative response with reserved NRC 0xFF
      final ffNrc = Mode08DiscoveryCodec.parseResponse(
        '7F 08 FF',
        expectedBaseTid: 0x00,
      );
      expect(ffNrc, isA<Mode08MalformedResponse>());
      expect((ffNrc as Mode08MalformedResponse).reason,
          Mode08MalformedReason.invalidNegativeResponse);
    });
  });

  group('Mode08 execution response parsing and contract validation', () {
    test('parses positive execution response matching test ID and length contract', () {
      final desc = Mode08Descriptor(
        testId: 0x01,
        expectedResponseBytes: 2,
      );

      // Literal vector: matching 2 data bytes (48 01 AA BB)
      final res = Mode08DiscoveryCodec.parseExecutionResponse(
        '48 01 AA BB',
        expectedTestId: 0x01,
        descriptor: desc,
      );
      expect(res, isA<Mode08ExecutionSuccess>());
      final success = res as Mode08ExecutionSuccess;
      expect(success.testId, 0x01);
      expect(success.dataBytes, [0xAA, 0xBB]);
      expect(() => (success.dataBytes as dynamic).add(0x99), throwsUnsupportedError);
    });

    test('rejects wrong test ID echo fail-closed', () {
      final res = Mode08DiscoveryCodec.parseExecutionResponse(
        '48 02 AA BB', // Echoed 0x02 instead of expected 0x01
        expectedTestId: 0x01,
        expectedResponseBytes: 2,
      );
      expect(res, isA<Mode08MalformedResponse>());
      expect((res as Mode08MalformedResponse).reason,
          Mode08MalformedReason.wrongTestIdEcho);
    });

    test('enforces response length contract (rejects under and over length)', () {
      // Expected 2 bytes, got 1 byte
      final underRes = Mode08DiscoveryCodec.parseExecutionResponse(
        '48 01 AA',
        expectedTestId: 0x01,
        expectedResponseBytes: 2,
      );
      expect(underRes, isA<Mode08MalformedResponse>());
      expect((underRes as Mode08MalformedResponse).reason,
          Mode08MalformedReason.wrongResponseLength);

      // Expected 2 bytes, got 3 bytes
      final overRes = Mode08DiscoveryCodec.parseExecutionResponse(
        '48 01 AA BB CC',
        expectedTestId: 0x01,
        expectedResponseBytes: 2,
      );
      expect(overRes, isA<Mode08MalformedResponse>());
      expect((overRes as Mode08MalformedResponse).reason,
          Mode08MalformedReason.wrongResponseLength);
    });

    test('classifies NRCs during execution with sound fallback', () {
      final res22 = Mode08DiscoveryCodec.parseExecutionResponse(
        '7F 08 22',
        expectedTestId: 0x01,
        expectedResponseBytes: 1,
      );
      expect(res22, isA<Mode08NegativeResponse>());
      final neg22 = res22 as Mode08NegativeResponse;
      expect(neg22.isConditionsNotCorrect, isTrue);
      expect(neg22.supportStatus, EcuSupportStatus.unknown);

      final res11 = Mode08DiscoveryCodec.parseExecutionResponse(
        '7F 08 11',
        expectedTestId: 0x01,
        expectedResponseBytes: 1,
      );
      expect(res11, isA<Mode08NegativeResponse>());
      expect((res11 as Mode08NegativeResponse).supportStatus,
          EcuSupportStatus.unsupported);
    });
  });
}
