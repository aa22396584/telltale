import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

const String unknownPlatformMetadata = 'unknown';
const String androidFieldApplicationId = 'com.cbstudio.telltale';
const String androidRigApplicationId = 'com.cbstudio.telltale.rig';

typedef PlatformMetadataLoader = Future<Object?> Function();

/// What the engine running this process says about itself, read from Dart.
///
/// `ImageFilter.isShaderFilterSupported` is documented to be true only when
/// Impeller is the rendering engine, so it separates the backend the app
/// *asked* for — [PlatformMetadata.renderer], decided in Kotlin before the
/// engine started — from the one the engine *is*. Under `flutter test` this
/// reads `skia`, which is a fact about the test runner, not about the app.
String observedRendererFamily() =>
    ui.ImageFilter.isShaderFilterSupported ? 'impeller' : 'skia';

final class PlatformMetadata {
  const PlatformMetadata({
    this.applicationId = unknownPlatformMetadata,
    required this.appVersion,
    required this.appBuild,
    required this.platform,
    required this.osVersion,
    required this.manufacturer,
    required this.model,
    required this.sdkInt,
    this.renderer = unknownPlatformMetadata,
    this.rendererReason = unknownPlatformMetadata,
    this.rendererObserved = unknownPlatformMetadata,
  });

  factory PlatformMetadata.unknown() => const PlatformMetadata(
    applicationId: unknownPlatformMetadata,
    appVersion: unknownPlatformMetadata,
    appBuild: unknownPlatformMetadata,
    platform: unknownPlatformMetadata,
    osVersion: unknownPlatformMetadata,
    manufacturer: unknownPlatformMetadata,
    model: unknownPlatformMetadata,
    sdkInt: unknownPlatformMetadata,
  );

  factory PlatformMetadata.dartIoFallback({
    String Function() observedRenderer = observedRendererFamily,
  }) {
    try {
      return PlatformMetadata(
        applicationId: unknownPlatformMetadata,
        appVersion: unknownPlatformMetadata,
        appBuild: unknownPlatformMetadata,
        platform: _normalized(Platform.operatingSystem),
        osVersion: _normalized(Platform.operatingSystemVersion),
        manufacturer: unknownPlatformMetadata,
        model: unknownPlatformMetadata,
        sdkInt: unknownPlatformMetadata,
        rendererObserved: _normalized(observedRenderer()),
      );
    } on Object {
      return PlatformMetadata.unknown();
    }
  }

  factory PlatformMetadata.fromPlatformMap(Map<String, Object?> values) {
    return PlatformMetadata(
      applicationId: _normalizedApplicationId(values['applicationId']),
      appVersion: _normalized(values['appVersion']),
      appBuild: _normalized(values['appBuild']),
      platform: _normalized(values['platform']),
      osVersion: _normalized(values['osVersion']),
      manufacturer: _normalized(values['manufacturer']),
      model: _normalized(values['model']),
      sdkInt: _normalized(values['sdkInt']),
      renderer: _normalized(values['renderer']),
      rendererReason: _normalized(values['rendererReason']),
      rendererObserved: _normalized(values['rendererObserved']),
    );
  }

  final String applicationId;
  final String appVersion;
  final String appBuild;
  final String platform;
  final String osVersion;
  final String manufacturer;
  final String model;
  final String sdkInt;

  /// The rendering backend the Android host asked the engine for before it
  /// started — `impeller-default`, `skia-forced`, `skia-engine-default` — or
  /// `unknown` where the host did not decide (other platforms) or its decision
  /// was not the one applied. Decided by `RendererPolicy.kt`.
  final String renderer;

  /// Why: the property that matched the denylist, or the values that did not.
  final String rendererReason;

  /// What the engine reports about itself from Dart, `impeller` or `skia`,
  /// via [observedRendererFamily]. Independent of [renderer], so an evidence
  /// file shows both what was asked for and what ran.
  final String rendererObserved;

  bool get isObdTestRigApplication =>
      platform == 'android' && applicationId == androidRigApplicationId;

  /// Whether vehicle evidence must be treated as simulated.
  ///
  /// Android normally supplies the exact package ID over the platform
  /// channel. Only the production package is eligible for field evidence.
  /// Every other Android identity fails closed, including missing, partial,
  /// malformed, repackaged, and future flavor IDs: losing field evidence is
  /// safer than allowing an unrecognized build to forge a physical header or
  /// replace real-car evidence. Other platforms do not use Android package
  /// identity as their provenance boundary.
  bool get requiresSimulatedEvidence =>
      platform == 'android' && applicationId != androidFieldApplicationId;

  static String _normalized(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? unknownPlatformMetadata : text;
  }

  /// Package identity is a security boundary, not display text. Use trimming
  /// only to recognize an absent value; preserving every nonblank byte makes
  /// padding and control-character alterations non-exact and therefore
  /// simulated on Android.
  static String _normalizedApplicationId(Object? value) {
    final text = value?.toString() ?? '';
    return text.trim().isEmpty ? unknownPlatformMetadata : text;
  }
}

/// The capture-only share sink is a test capability, not a flavor hint.
///
/// All three facts must agree. In particular, a leaked dart-define in the
/// field application remains on the native sharing path and can never create
/// rig capture artifacts.
bool isRigShareCaptureEligible({
  required PlatformMetadata metadata,
  required bool buildFlag,
  required bool debugMode,
}) =>
    buildFlag &&
    debugMode &&
    metadata.platform == 'android' &&
    metadata.applicationId == androidRigApplicationId;

final class PlatformMetadataCache {
  PlatformMetadataCache({
    PlatformMetadata? initialValue,
    this.channel = const MethodChannel(
      'com.cbstudio.telltale/platform_metadata',
    ),
    this.timeout = const Duration(milliseconds: 500),
    this.observedRenderer = observedRendererFamily,
  }) : _value =
           initialValue ??
           PlatformMetadata.dartIoFallback(observedRenderer: observedRenderer);

  final MethodChannel channel;
  final Duration timeout;

  /// Injectable so tests do not pin what the test runner renders with.
  final String Function() observedRenderer;
  PlatformMetadata _value;

  PlatformMetadata get value => _value;

  Future<void> prefetch({PlatformMetadataLoader? loader}) async {
    try {
      final raw =
          await (loader?.call() ??
                  channel.invokeMethod<Object?>('getPlatformMetadata'))
              .timeout(timeout);
      if (raw case final Map<Object?, Object?> values) {
        final normalizedKeys = values.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        // dart:io already established that this process is Android. A
        // successful but empty, partial, or malformed channel reply must not
        // erase that safety-critical context and turn an unknown package into
        // apparently eligible field evidence. Do not carry the application ID
        // forward: the native reply itself must provide the exact field ID.
        if (_value.platform == 'android') {
          normalizedKeys['platform'] = 'android';
        }
        // Read here, not on the native side: the host knows what it asked
        // for, only the engine knows what it became.
        normalizedKeys['rendererObserved'] = observedRenderer();
        _value = PlatformMetadata.fromPlatformMap(normalizedKeys);
      }
    } on Object {
      // Field evidence must never prevent startup or a vehicle connection.
      // Preserve the synchronous dart:io fallback already held in the cache.
    }
  }
}

final PlatformMetadataCache platformMetadataCache = PlatformMetadataCache();

Future<void> prefetchPlatformMetadata() => platformMetadataCache.prefetch();
