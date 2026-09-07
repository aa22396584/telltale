import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/field_evidence/platform_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformMetadata', () {
    test('normalizes absent and blank values to literal unknown', () {
      final metadata = PlatformMetadata.fromPlatformMap(<String, Object?>{
        'applicationId': 'com.cbstudio.telltale.rig',
        'appVersion': '  ',
        'appBuild': null,
        'platform': 'android',
        'osVersion': '',
        'manufacturer': 'Google',
        'model': null,
        'sdkInt': 35,
      });

      expect(metadata.applicationId, 'com.cbstudio.telltale.rig');
      expect(metadata.isObdTestRigApplication, isTrue);
      expect(metadata.appVersion, 'unknown');
      expect(metadata.appBuild, 'unknown');
      expect(metadata.platform, 'android');
      expect(metadata.osVersion, 'unknown');
      expect(metadata.manufacturer, 'Google');
      expect(metadata.model, 'unknown');
      expect(metadata.sdkInt, '35');
    });

    test('only the exact Android field package is field eligible', () {
      const identities = <String, bool>{
        androidFieldApplicationId: false,
        'com.cbstudio.telltale.rig': true,
        unknownPlatformMetadata: true,
        '': true,
        'com.cbstudio.telltale.': true,
        'com.cbstudio.telltale.debug': true,
        'com.cbstudio.telltale.evil': true,
        'COM.CBSTUDIO.TELLTALE': true,
        'com.cbstudio.telltale\nforged': true,
        ' com.cbstudio.telltale': true,
        'com.cbstudio.telltale ': true,
        'com.cbstudio.telltale\n': true,
        'com.cbstudio.telltale\t': true,
      };

      for (final MapEntry(key: applicationId, value: expected)
          in identities.entries) {
        final metadata = PlatformMetadata(
          applicationId: applicationId,
          appVersion: 'unknown',
          appBuild: 'unknown',
          platform: 'android',
          osVersion: 'Android 16',
          manufacturer: 'unknown',
          model: 'unknown',
          sdkInt: 'unknown',
        );

        expect(
          metadata.requiresSimulatedEvidence,
          expected,
          reason: 'classification for applicationId=$applicationId',
        );
      }
    });

    test('unknown non-Android package provenance is not called a rig', () {
      const metadata = PlatformMetadata(
        appVersion: 'unknown',
        appBuild: 'unknown',
        platform: 'macos',
        osVersion: 'unknown',
        manufacturer: 'unknown',
        model: 'unknown',
        sdkInt: 'unknown',
      );

      expect(metadata.requiresSimulatedEvidence, isFalse);
    });

    test('rig share capture requires define, debug, Android, and exact id', () {
      PlatformMetadata metadata(String platform, String applicationId) =>
          PlatformMetadata(
            applicationId: applicationId,
            appVersion: '1',
            appBuild: '1',
            platform: platform,
            osVersion: 'unknown',
            manufacturer: 'unknown',
            model: 'unknown',
            sdkInt: 'unknown',
          );

      expect(
        isRigShareCaptureEligible(
          metadata: metadata('android', androidRigApplicationId),
          buildFlag: true,
          debugMode: true,
        ),
        isTrue,
      );
      for (final candidate
          in <({PlatformMetadata metadata, bool flag, bool debug})>[
            (
              metadata: metadata('android', androidFieldApplicationId),
              flag: true,
              debug: true,
            ),
            (
              metadata: metadata('android', androidRigApplicationId),
              flag: false,
              debug: true,
            ),
            (
              metadata: metadata('android', androidRigApplicationId),
              flag: true,
              debug: false,
            ),
            (
              metadata: metadata('macos', androidRigApplicationId),
              flag: true,
              debug: true,
            ),
            (
              metadata: metadata('android', '$androidRigApplicationId '),
              flag: true,
              debug: true,
            ),
          ]) {
        expect(
          isRigShareCaptureEligible(
            metadata: candidate.metadata,
            buildFlag: candidate.flag,
            debugMode: candidate.debug,
          ),
          isFalse,
        );
      }
    });

    test('cache exposes a synchronous value before prefetch completes', () {
      const initial = PlatformMetadata(
        appVersion: 'unknown',
        appBuild: 'unknown',
        platform: 'android',
        osVersion: 'unknown',
        manufacturer: 'unknown',
        model: 'unknown',
        sdkInt: 'unknown',
      );
      final cache = PlatformMetadataCache(initialValue: initial);

      expect(cache.value, same(initial));
    });

    test(
      'prefetch replaces the cached value from the platform channel',
      () async {
        final cache = PlatformMetadataCache(
          initialValue: PlatformMetadata.unknown(),
          channel: const MethodChannel('test/platform_metadata'),
          timeout: const Duration(milliseconds: 500),
        );

        await cache.prefetch(
          loader: () async => <String, Object?>{
            'applicationId': 'com.cbstudio.telltale',
            'appVersion': '1.2.3',
            'appBuild': '42',
            'platform': 'android',
            'osVersion': '15',
            'manufacturer': 'Google',
            'model': 'Pixel 9',
            'sdkInt': 35,
          },
        );

        expect(cache.value.applicationId, 'com.cbstudio.telltale');
        expect(cache.value.isObdTestRigApplication, isFalse);
        expect(cache.value.requiresSimulatedEvidence, isFalse);
        expect(cache.value.appVersion, '1.2.3');
        expect(cache.value.appBuild, '42');
        expect(cache.value.platform, 'android');
        expect(cache.value.osVersion, '15');
        expect(cache.value.manufacturer, 'Google');
        expect(cache.value.model, 'Pixel 9');
        expect(cache.value.sdkInt, '35');
      },
    );

    test('the renderer the host asked for travels with its reason', () {
      final metadata = PlatformMetadata.fromPlatformMap(<String, Object?>{
        'platform': 'android',
        'renderer': 'skia-forced',
        'rendererReason': 'ro.board.platform=msm8974',
        'rendererObserved': 'skia',
      });

      expect(metadata.renderer, 'skia-forced');
      expect(metadata.rendererReason, 'ro.board.platform=msm8974');
      expect(metadata.rendererObserved, 'skia');
    });

    test('a host that did not decide leaves the renderer unknown', () {
      final metadata = PlatformMetadata.fromPlatformMap(<String, Object?>{
        'platform': 'android',
        'renderer': '',
        'rendererReason': null,
      });

      expect(metadata.renderer, unknownPlatformMetadata);
      expect(metadata.rendererReason, unknownPlatformMetadata);
      expect(metadata.rendererObserved, unknownPlatformMetadata);
      expect(PlatformMetadata.unknown().renderer, unknownPlatformMetadata);
      expect(
        PlatformMetadata.unknown().rendererObserved,
        unknownPlatformMetadata,
      );
    });

    test(
      'the observed renderer is read from the engine on prefetch, not from the host',
      () async {
        // The host cannot know what the engine became; the native reply
        // carries what was asked for, and the value the engine reports is
        // read in Dart. A native `rendererObserved` must not survive.
        final cache = PlatformMetadataCache(
          initialValue: _androidFallback(),
          timeout: const Duration(milliseconds: 500),
          observedRenderer: () => 'impeller',
        );

        await cache.prefetch(
          loader: () async => <String, Object?>{
            'applicationId': 'com.cbstudio.telltale',
            'renderer': 'impeller-default',
            'rendererReason': 'ro.board.platform=pineapple ro.hardware.vulkan=adreno',
            'rendererObserved': 'from-the-host',
          },
        );

        expect(cache.value.renderer, 'impeller-default');
        expect(
          cache.value.rendererReason,
          'ro.board.platform=pineapple ro.hardware.vulkan=adreno',
        );
        expect(cache.value.rendererObserved, 'impeller');
      },
    );

    test('the dart:io fallback carries the observed renderer too', () {
      final fallback = PlatformMetadata.dartIoFallback(
        observedRenderer: () => 'skia',
      );

      expect(fallback.renderer, unknownPlatformMetadata);
      expect(fallback.rendererObserved, 'skia');
      final cache = PlatformMetadataCache(observedRenderer: () => 'skia');
      expect(cache.value.rendererObserved, 'skia');
    });

    test('the engine probe answers one of the two families it can be', () {
      // Which one is a fact about the process running this test, not about
      // the app, so it is not pinned; that the probe answers at all, and
      // only in the vocabulary the header prints, is.
      expect(observedRendererFamily(), isIn(<String>['impeller', 'skia']));
    });

    test('empty native metadata preserves known Android provenance', () async {
      final cache = PlatformMetadataCache(
        initialValue: _androidFallback(),
        timeout: const Duration(milliseconds: 500),
      );

      await cache.prefetch(loader: () async => <String, Object?>{});

      expect(cache.value.platform, 'android');
      expect(cache.value.applicationId, unknownPlatformMetadata);
      expect(cache.value.requiresSimulatedEvidence, isTrue);
    });

    test(
      'applicationId-only malformed or unexpected replies fail closed',
      () async {
        for (final applicationId in <Object?>[
          null,
          '  ',
          'com.cbstudio.telltale.',
          'com.example.repackaged',
          ' $androidFieldApplicationId',
          '$androidFieldApplicationId ',
          '$androidFieldApplicationId\n',
          '$androidFieldApplicationId\t',
        ]) {
          final cache = PlatformMetadataCache(
            initialValue: _androidFallback(),
            timeout: const Duration(milliseconds: 500),
          );

          await cache.prefetch(
            loader: () async => <String, Object?>{
              'applicationId': applicationId,
            },
          );

          expect(cache.value.platform, 'android');
          expect(
            cache.value.requiresSimulatedEvidence,
            isTrue,
            reason: 'classification for applicationId=$applicationId',
          );
        }
      },
    );

    test(
      'partial native metadata preserves known Android provenance',
      () async {
        final cache = PlatformMetadataCache(
          initialValue: _androidFallback(),
          timeout: const Duration(milliseconds: 500),
        );

        await cache.prefetch(
          loader: () async => <String, Object?>{
            'appVersion': '1.2.3',
            'model': 'Pixel 9',
          },
        );

        expect(cache.value.platform, 'android');
        expect(cache.value.applicationId, unknownPlatformMetadata);
        expect(cache.value.appVersion, '1.2.3');
        expect(cache.value.model, 'Pixel 9');
        expect(cache.value.requiresSimulatedEvidence, isTrue);
      },
    );

    test(
      'empty metadata does not classify a non-Android fallback as rig',
      () async {
        const fallback = PlatformMetadata(
          appVersion: 'unknown',
          appBuild: 'unknown',
          platform: 'macos',
          osVersion: 'macOS',
          manufacturer: 'Apple',
          model: 'Mac',
          sdkInt: 'unknown',
        );
        final cache = PlatformMetadataCache(
          initialValue: fallback,
          timeout: const Duration(milliseconds: 500),
        );

        await cache.prefetch(loader: () async => <String, Object?>{});

        expect(cache.value.platform, unknownPlatformMetadata);
        expect(cache.value.requiresSimulatedEvidence, isFalse);
      },
    );

    test('prefetch retains fallback on channel failure', () async {
      const fallback = PlatformMetadata(
        appVersion: 'unknown',
        appBuild: 'unknown',
        platform: 'android',
        osVersion: 'Android 15',
        manufacturer: 'unknown',
        model: 'unknown',
        sdkInt: 'unknown',
      );
      final cache = PlatformMetadataCache(
        initialValue: fallback,
        timeout: const Duration(milliseconds: 500),
      );

      await cache.prefetch(loader: () async => throw MissingPluginException());

      expect(cache.value, same(fallback));
      expect(cache.value.requiresSimulatedEvidence, isTrue);
    });

    test('prefetch times out and retains fallback', () async {
      const fallback = PlatformMetadata(
        appVersion: 'unknown',
        appBuild: 'unknown',
        platform: 'android',
        osVersion: 'unknown',
        manufacturer: 'unknown',
        model: 'unknown',
        sdkInt: 'unknown',
      );
      final cache = PlatformMetadataCache(
        initialValue: fallback,
        timeout: const Duration(milliseconds: 1),
      );

      await cache.prefetch(
        loader: () => Future<Object?>.delayed(
          const Duration(milliseconds: 50),
          () => <String, Object?>{'appVersion': 'late'},
        ),
      );

      expect(cache.value, same(fallback));
      expect(cache.value.requiresSimulatedEvidence, isTrue);
    });
  });
}

PlatformMetadata _androidFallback() => const PlatformMetadata(
  appVersion: unknownPlatformMetadata,
  appBuild: unknownPlatformMetadata,
  platform: 'android',
  osVersion: 'Android 16',
  manufacturer: unknownPlatformMetadata,
  model: unknownPlatformMetadata,
  sdkInt: unknownPlatformMetadata,
);
