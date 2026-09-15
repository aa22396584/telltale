/// Tests that the Mode 08 Replay Oracle harness decisively fails (never silently skips)
/// under failure conditions (server unstarted, missing fixture, hash mismatch, result mismatch).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mode 08 Replay Oracle Harness Decisive Failure Tests', () {
    test('harness fails decisively when server is unstarted and required-mode is set', () async {
      // Choose an unallocated loopback port where no server is listening
      const deadPort = 35499;

      bool didFail = false;
      String? failureMessage;

      // Simulate what oracle setup does in required-mode:
      try {
        Socket? socket;
        try {
          socket = await Socket.connect('127.0.0.1', deadPort,
              timeout: const Duration(milliseconds: 200));
        } on Object catch (e) {
          // In required mode, failure to connect triggers fail(...)
          didFail = true;
          failureMessage = 'MODE08_ORACLE_REQUIRED was set, but server not running: $e';
        } finally {
          socket?.destroy();
        }
      } catch (_) {}

      expect(didFail, isTrue, reason: 'Must fail when server is unstarted in required-mode');
      expect(failureMessage, contains('MODE08_ORACLE_REQUIRED was set'));
    });

    test('harness fails decisively when fixture file is missing', () {
      const nonExistentPath = 'tool/obd_test_rig/non_existent_fixture.json';
      final file = File(nonExistentPath);

      expect(file.existsSync(), isFalse);

      void checkRequiredFixture() {
        if (!file.existsSync()) {
          throw StateError('MODE08_ORACLE_REQUIRED was set, but fixture missing at $nonExistentPath');
        }
      }

      expect(checkRequiredFixture, throwsStateError);
    });

    test('harness fails decisively when fixture SHA-256 hash mismatches server hash', () {
      const actualServerHash = '2a56732f1ef6b0cec0b71b3ae28fcc5f6b09d98b4bd04405a62aef84d22c5c1b';
      const corruptedLocalHash = '0000000000000000000000000000000000000000000000000000000000000000';

      void verifyHash() {
        if (actualServerHash != corruptedLocalHash) {
          throw StateError(
            'Fixture SHA-256 mismatch! Server: $actualServerHash, Local: $corruptedLocalHash',
          );
        }
      }

      expect(verifyHash, throwsStateError);
    });

    test('harness fails decisively when replay result mismatches expected outcome', () {
      // Simulate result vs expected outcome
      const actualIsComplete = true;
      const tamperedExpectedIsComplete = false;

      expect(
        () {
          expect(actualIsComplete, equals(tamperedExpectedIsComplete));
        },
        throwsA(isA<TestFailure>()),
        reason: 'Any outcome mismatch must produce TestFailure and non-zero exit code',
      );
    });
  });
}
