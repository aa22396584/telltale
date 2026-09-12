import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/uds_active_codec.dart';

void main() {
  group('UdsActiveCodec Service 0x2F (InputOutputControlByIdentifier)', () {
    test('encodes 0x2F requests accurately', () {
      // 0x00 returnControlToECU
      final reqReturn = UdsActiveCodec.encodeIoControlCommand(
        did: 0x0112,
        parameter: UdsIoControlParameter.returnControlToECU,
      );
      expect(reqReturn, '2F011200');

      // 0x03 shortTermAdjustment with control state [0x64] (100% duty cycle)
      final reqAdjust = UdsActiveCodec.encodeIoControlCommand(
        did: 0x0112,
        parameter: UdsIoControlParameter.shortTermAdjustment,
        controlState: const [0x64],
      );
      expect(reqAdjust, '2F01120364');

      // 0x03 shortTermAdjustment with control state and mask
      final reqWithMask = UdsActiveCodec.encodeIoControlCommand(
        did: 0x0112,
        parameter: UdsIoControlParameter.shortTermAdjustment,
        controlState: const [0x64],
        controlMask: const [0xFF],
      );
      expect(reqWithMask, '2F01120364FF');
    });

    test('rejects out of range DID, byte values, or mismatched mask when encoding', () {
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: 0x10000,
          parameter: UdsIoControlParameter.returnControlToECU,
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: -1,
          parameter: UdsIoControlParameter.returnControlToECU,
        ),
        throwsArgumentError,
      );
      // Byte > 255 in controlState
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: 0x0112,
          parameter: UdsIoControlParameter.shortTermAdjustment,
          controlState: const [256],
        ),
        throwsArgumentError,
      );
      // Byte < 0 in controlState
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: 0x0112,
          parameter: UdsIoControlParameter.shortTermAdjustment,
          controlState: const [-1],
        ),
        throwsArgumentError,
      );
      // Byte > 255 in controlMask
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: 0x0112,
          parameter: UdsIoControlParameter.shortTermAdjustment,
          controlState: const [0x64],
          controlMask: const [256],
        ),
        throwsArgumentError,
      );
      // Mask length mismatch (mask length 2 vs state length 1)
      expect(
        () => UdsActiveCodec.encodeIoControlRequest(
          did: 0x0112,
          parameter: UdsIoControlParameter.shortTermAdjustment,
          controlState: const [0x64],
          controlMask: const [0xFF, 0xFF],
        ),
        throwsArgumentError,
      );
    });

    test('parses positive 0x2F responses matching DID and parameter', () {
      final res = UdsActiveCodec.parseIoControlResponse(
        '6F 01 12 03 64',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(res, isA<UdsIoControlSuccess>());
      final success = res as UdsIoControlSuccess;
      expect(success.did, 0x0112);
      expect(success.controlParameter,
          UdsIoControlParameter.shortTermAdjustment);
      expect(success.controlStatusRecord, [0x64]);
    });

    test('parses negative 0x2F responses and distinguishes NRC 0x78 pending', () {
      final resNrc22 = UdsActiveCodec.parseIoControlResponse(
        '7F 2F 22',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(resNrc22, isA<UdsIoControlNegative>());
      final neg22 = resNrc22 as UdsIoControlNegative;
      expect(neg22.nrc, 0x22);
      expect(neg22.isResponsePending, isFalse);

      final resNrc78 = UdsActiveCodec.parseIoControlResponse(
        '7F 2F 78',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(resNrc78, isA<UdsIoControlNegative>());
      final neg78 = resNrc78 as UdsIoControlNegative;
      expect(neg78.nrc, 0x78);
      expect(neg78.isResponsePending, isTrue);
    });

    test('rejects wrong DID echo fail-closed (anti generic SID+0x40 rule)', () {
      // ECU responded with 6F for a DIFFERENT DID (0x0113 instead of 0x0112)
      final res = UdsActiveCodec.parseIoControlResponse(
        '6F 01 13 03 64',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(res, isA<UdsIoControlMalformed>());
      expect((res as UdsIoControlMalformed).reason,
          UdsMalformedReason.wrongDidEcho);
    });

    test('rejects wrong control parameter echo', () {
      final res = UdsActiveCodec.parseIoControlResponse(
        '6F 01 12 00', // Received 0x00 returnControlToECU when expecting 0x03 adjustment
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(res, isA<UdsIoControlMalformed>());
      expect((res as UdsIoControlMalformed).reason,
          UdsMalformedReason.wrongControlParameterEcho);
    });

    test('rejects truncated or malformed responses fail-closed', () {
      // Truncated positive response (< 4 bytes)
      final truncated = UdsActiveCodec.parseIoControlResponse(
        '6F 01 12',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(truncated, isA<UdsIoControlMalformed>());
      expect((truncated as UdsIoControlMalformed).reason,
          UdsMalformedReason.truncated);

      // Wrong SID
      final wrongSid = UdsActiveCodec.parseIoControlResponse(
        '71 01 12 03',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(wrongSid, isA<UdsIoControlMalformed>());
      expect((wrongSid as UdsIoControlMalformed).reason,
          UdsMalformedReason.invalidSid);

      // Truncated negative response (< 3 bytes)
      final truncatedNeg = UdsActiveCodec.parseIoControlResponse(
        '7F 2F',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(truncatedNeg, isA<UdsIoControlMalformed>());
      expect((truncatedNeg as UdsIoControlMalformed).reason,
          UdsMalformedReason.truncated);

      // Negative response with wrong original SID
      final wrongOrig = UdsActiveCodec.parseIoControlResponse(
        '7F 22 11',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(wrongOrig, isA<UdsIoControlMalformed>());
      expect((wrongOrig as UdsIoControlMalformed).reason,
          UdsMalformedReason.wrongOriginalSid);

      // Negative response with extra trailing bytes (> 3 bytes)
      final extraNeg = UdsActiveCodec.parseIoControlResponse(
        '7F 2F 11 22',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(extraNeg, isA<UdsIoControlMalformed>());
      expect((extraNeg as UdsIoControlMalformed).reason,
          UdsMalformedReason.invalidNrc);

      // Negative response with reserved NRC 0x00
      final zeroNrc = UdsActiveCodec.parseIoControlResponse(
        '7F 2F 00',
        expectedDid: 0x0112,
        expectedParameter: UdsIoControlParameter.shortTermAdjustment,
      );
      expect(zeroNrc, isA<UdsIoControlMalformed>());
      expect((zeroNrc as UdsIoControlMalformed).reason,
          UdsMalformedReason.invalidNrc);
    });
  });

  group('UdsActiveCodec Service 0x31 (RoutineControl)', () {
    test('encodes 0x31 requests accurately', () {
      final reqStart = UdsActiveCodec.encodeRoutineCommand(
        controlType: UdsRoutineControlType.startRoutine,
        routineIdentifier: 0x0201,
      );
      expect(reqStart, '31010201');

      final reqStop = UdsActiveCodec.encodeRoutineCommand(
        controlType: UdsRoutineControlType.stopRoutine,
        routineIdentifier: 0x0201,
      );
      expect(reqStop, '31020201');

      final reqResults = UdsActiveCodec.encodeRoutineCommand(
        controlType: UdsRoutineControlType.requestRoutineResults,
        routineIdentifier: 0x0201,
      );
      expect(reqResults, '31030201');

      final reqWithOptions = UdsActiveCodec.encodeRoutineCommand(
        controlType: UdsRoutineControlType.startRoutine,
        routineIdentifier: 0x0201,
        optionRecord: const [0x05, 0xAA],
      );
      expect(reqWithOptions, '3101020105AA');
    });

    test('rejects out of range RID when encoding', () {
      expect(
        () => UdsActiveCodec.encodeRoutineRequest(
          controlType: UdsRoutineControlType.startRoutine,
          routineIdentifier: 0x10000,
        ),
        throwsArgumentError,
      );
    });

    test('parses positive 0x31 responses matching subfunction and RID', () {
      final res = UdsActiveCodec.parseRoutineResponse(
        '71 01 02 01 00',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(res, isA<UdsRoutineSuccess>());
      final success = res as UdsRoutineSuccess;
      expect(success.controlType, UdsRoutineControlType.startRoutine);
      expect(success.routineIdentifier, 0x0201);
      expect(success.routineStatusRecord, [0x00]);
    });

    test('parses negative 0x31 responses and handles NRC 0x78 pending', () {
      final resNrc12 = UdsActiveCodec.parseRoutineResponse(
        '7F 31 12',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(resNrc12, isA<UdsRoutineNegative>());
      final neg12 = resNrc12 as UdsRoutineNegative;
      expect(neg12.nrc, 0x12);
      expect(neg12.isResponsePending, isFalse);

      final resNrc78 = UdsActiveCodec.parseRoutineResponse(
        '7F 31 78',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(resNrc78, isA<UdsRoutineNegative>());
      final neg78 = resNrc78 as UdsRoutineNegative;
      expect(neg78.nrc, 0x78);
      expect(neg78.isResponsePending, isTrue);
    });

    test('rejects wrong RID echo fail-closed (anti generic SID+0x40 rule)', () {
      // ECU returned 71 for a DIFFERENT RID (0x0202 instead of 0x0201)
      final res = UdsActiveCodec.parseRoutineResponse(
        '71 01 02 02',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(res, isA<UdsRoutineMalformed>());
      expect((res as UdsRoutineMalformed).reason,
          UdsMalformedReason.wrongRidEcho);
    });

    test('rejects wrong routine control subfunction echo', () {
      final res = UdsActiveCodec.parseRoutineResponse(
        '71 02 02 01', // Echoed 0x02 stopRoutine when expecting 0x01 startRoutine
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(res, isA<UdsRoutineMalformed>());
      expect((res as UdsRoutineMalformed).reason,
          UdsMalformedReason.wrongRoutineTypeEcho);
    });

    test('rejects truncated or malformed responses fail-closed', () {
      // Truncated positive response (< 4 bytes)
      final truncated = UdsActiveCodec.parseRoutineResponse(
        '71 01 02',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(truncated, isA<UdsRoutineMalformed>());
      expect((truncated as UdsRoutineMalformed).reason,
          UdsMalformedReason.truncated);

      // Wrong SID
      final wrongSid = UdsActiveCodec.parseRoutineResponse(
        '6F 01 02 01',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(wrongSid, isA<UdsRoutineMalformed>());
      expect((wrongSid as UdsRoutineMalformed).reason,
          UdsMalformedReason.invalidSid);

      // Negative response with wrong original SID
      final wrongOrig = UdsActiveCodec.parseRoutineResponse(
        '7F 22 12',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(wrongOrig, isA<UdsRoutineMalformed>());
      expect((wrongOrig as UdsRoutineMalformed).reason,
          UdsMalformedReason.wrongOriginalSid);

      // Negative response with extra trailing bytes (> 3 bytes)
      final extraNeg = UdsActiveCodec.parseRoutineResponse(
        '7F 31 12 22',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(extraNeg, isA<UdsRoutineMalformed>());
      expect((extraNeg as UdsRoutineMalformed).reason,
          UdsMalformedReason.invalidNrc);

      // Negative response with reserved NRC 0x00
      final zeroNrc = UdsActiveCodec.parseRoutineResponse(
        '7F 31 00',
        expectedType: UdsRoutineControlType.startRoutine,
        expectedRoutineIdentifier: 0x0201,
      );
      expect(zeroNrc, isA<UdsRoutineMalformed>());
      expect((zeroNrc as UdsRoutineMalformed).reason,
          UdsMalformedReason.invalidNrc);
    });

    test('rejects out of range optionRecord bytes when encoding', () {
      expect(
        () => UdsActiveCodec.encodeRoutineRequest(
          controlType: UdsRoutineControlType.startRoutine,
          routineIdentifier: 0x0201,
          optionRecord: const [256],
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsActiveCodec.encodeRoutineRequest(
          controlType: UdsRoutineControlType.startRoutine,
          routineIdentifier: 0x0201,
          optionRecord: const [-1],
        ),
        throwsArgumentError,
      );
    });
  });
}
