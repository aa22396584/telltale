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
  });
}
