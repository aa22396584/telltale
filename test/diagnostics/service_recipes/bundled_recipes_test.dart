import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';

void main() {
  group('Bundled active test service recipes in assets/service_recipes/', () {
    test('all bundled recipe JSON files exist, parse, and validate canonical hashes', () {
      final loadedProfiles = <ActiveTestProfile>[];

      for (final path in BundledServiceRecipes.bundledAssetPaths) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Missing bundled asset file: $path');

        final jsonString = file.readAsStringSync();
        final profile = BundledServiceRecipes.parseProfileJson(jsonString);

        expect(profile.isValid, isTrue,
            reason: 'Profile ${profile.profileId} failed validation');
        expect(profile.verifyCanonicalHash(), isTrue,
            reason: 'Profile ${profile.profileId} canonical hash mismatch');
        expect(profile.provenanceKind, ProvenanceKind.syntheticFixture,
            reason: 'Bundled recipe must be marked as synthetic fixture');

        loadedProfiles.add(profile);
      }

      expect(loadedProfiles.length, 3);

      // Verify the candidate matrix over all bundled recipes
      final matrix = CandidateMatrix.fromProfiles(loadedProfiles);

      // CRITICAL ACCEPTANCE CRITERION: Explicit NO LIVE CANDIDATE result
      expect(matrix.liveCandidateCount, 0);
      expect(matrix.hasLiveCandidates, isFalse);
      expect(matrix.simulationReadyEntries.length, 3);
      expect(matrix.qualifiedEntries, isEmpty);
    });

    test('tampering with any bundled asset JSON fails closed with FormatException', () {
      for (final path in BundledServiceRecipes.bundledAssetPaths) {
        final originalJson = File(path).readAsStringSync();

        // Attack 1: Modify a single bit in the version string
        final tamperedVersion = originalJson.replaceAll('"version": "1.0.0"', '"version": "1.0.1"');
        expect(
          () => BundledServiceRecipes.parseProfileJson(tamperedVersion),
          throwsFormatException,
          reason: 'Tampered version in $path must fail hash verification',
        );

        // Attack 2: Modify canonical hash
        final tamperedHash = originalJson.replaceAllMapped(
          RegExp(r'"canonical_hash":\s*"([^"]+)"'),
          (match) {
            final old = match.group(1)!;
            final modified = old.endsWith('a') ? '${old.substring(0, old.length - 1)}b' : '${old.substring(0, old.length - 1)}a';
            return '"canonical_hash": "$modified"';
          },
        );
        expect(
          () => BundledServiceRecipes.parseProfileJson(tamperedHash),
          throwsFormatException,
          reason: 'Tampered hash in $path must fail hash verification',
        );

        // Attack 3: Replace target ECU header with broadcast header 7DF
        final tamperedBroadcast = originalJson.replaceAll('"target_ecu_header": "7E0"', '"target_ecu_header": "7DF"');
        expect(
          () => BundledServiceRecipes.parseProfileJson(tamperedBroadcast),
          throwsFormatException,
          reason: 'Broadcast addressing in $path must be rejected',
        );
      }
    });
  });
}
