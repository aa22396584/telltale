/// The freshness channel names elapsedRealtime, not uptimeMillis.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/elapsed_realtime.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.cbstudio.telltale/elapsed_realtime');

  void mock(Future<Object?> Function(MethodCall call)? handler) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => mock(null));

  test('a native elapsedRealtime millisecond count is returned', () async {
    mock((call) async {
      expect(call.method, 'elapsedRealtimeMs');
      return 12_345;
    });
    expect(await ElapsedRealtimePlatform.elapsedRealtimeMs(), 12345);
  });

  test('a missing channel is null, not a Stopwatch substitute', () async {
    expect(await ElapsedRealtimePlatform.elapsedRealtimeMs(), isNull);
  });

  test('a platform exception is null, never a crash', () async {
    mock((call) async => throw PlatformException(code: 'absent'));
    expect(await ElapsedRealtimePlatform.elapsedRealtimeMs(), isNull);
  });
}
