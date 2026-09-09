/// Android `SystemClock.elapsedRealtime` for freshness.
///
/// Dart `Stopwatch` does not include deep sleep. This channel is the mapping
/// that does. An unregistered channel (iOS, desktop, tests without a mock)
/// returns null so the caller can retire continuity instead of pretending
/// Stopwatch is elapsedRealtime.
library;

import 'package:flutter/services.dart';

abstract final class ElapsedRealtimePlatform {
  static const MethodChannel channel = MethodChannel(
    'com.cbstudio.telltale/elapsed_realtime',
  );

  static const String method = 'elapsedRealtimeMs';

  /// Milliseconds since boot, including deep sleep, or null if this host
  /// does not provide the mapping.
  static Future<int?> elapsedRealtimeMs() async {
    try {
      final raw = await channel.invokeMethod<Object?>(method);
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return null;
    } on Object {
      return null;
    }
  }
}
