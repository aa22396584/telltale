/// Active-test candidate matrix categorizing profiles by qualification status.
///
/// Ref: Issue #131 ([ACTIVE-01]), Parent: #25.
///
/// SAFETY CONTRACT:
/// - Categorizes active-test recipes into:
///   `simulationReady / needsSource / needsBench / externalOnly / qualified`.
/// - Explicitly delivers a **no-live-candidate** result when evidence is absent.
/// - Never invents vehicle profiles from generic unverified sources.
library;

import 'dart:convert';

import 'active_test_profile.dart';

/// Qualification category in the active-test candidate matrix.
enum CandidateCategory {
  /// Synthetic fixtures for simulation, test harness, and CI.
  simulationReady,

  /// Lacks reviewed authoritative source document or redistribution rights.
  needsSource,

  /// Source reviewed, but requires physical bench qualification.
  needsBench,

  /// Restricted to external/dealer offboard equipment; not eligible in-app.
  externalOnly,

  /// Independently qualified on physical bench and vehicle with verified artifacts.
  qualified,
}

/// An entry in the active-test candidate matrix.
final class CandidateMatrixEntry {
  const CandidateMatrixEntry({
    required this.profile,
    required this.category,
    required this.notes,
  });

  final ActiveTestProfile profile;
  final CandidateCategory category;
  final String notes;

  /// Whether this profile is a live production candidate.
  bool get isLiveCandidate =>
      category == CandidateCategory.qualified &&
      !profile.isRevoked &&
      profile.isValid &&
      profile.provenanceKind != ProvenanceKind.syntheticFixture &&
      profile.evidenceTier != EvidenceQualificationTier.syntheticFixture &&
      profile.redistributionRights !=
          RedistributionRights.syntheticFixtureOnly;
}

/// The active-test candidate matrix report.
final class CandidateMatrix {
  const CandidateMatrix({
    required this.entries,
  });

  factory CandidateMatrix.fromProfiles(List<ActiveTestProfile> profiles) {
    final entries = <CandidateMatrixEntry>[];

    for (final profile in profiles) {
      if (profile.provenanceKind == ProvenanceKind.syntheticFixture ||
          profile.evidenceTier == EvidenceQualificationTier.syntheticFixture ||
          profile.redistributionRights ==
              RedistributionRights.syntheticFixtureOnly) {
        entries.add(
          CandidateMatrixEntry(
            profile: profile,
            category: CandidateCategory.simulationReady,
            notes: 'Synthetic fixture for simulation and CI harness only.',
          ),
        );
      } else if (profile.redistributionRights ==
              RedistributionRights.unreviewed ||
          profile.sourceUrl.isEmpty ||
          profile.evidenceTier == EvidenceQualificationTier.needsSource) {
        entries.add(
          CandidateMatrixEntry(
            profile: profile,
            category: CandidateCategory.needsSource,
            notes: 'Lacks reviewed authoritative source or redistribution review.',
          ),
        );
      } else if (profile.evidenceTier ==
          EvidenceQualificationTier.needsBench) {
        entries.add(
          CandidateMatrixEntry(
            profile: profile,
            category: CandidateCategory.needsBench,
            notes: 'Authoritative source reviewed; requires physical bench qualification.',
          ),
        );
      } else if (profile.evidenceTier ==
              EvidenceQualificationTier.benchQualified ||
          profile.evidenceTier ==
              EvidenceQualificationTier.vehicleQualified) {
        entries.add(
          CandidateMatrixEntry(
            profile: profile,
            category: CandidateCategory.qualified,
            notes: 'Hardware qualified with recorded test evidence.',
          ),
        );
      } else {
        entries.add(
          CandidateMatrixEntry(
            profile: profile,
            category: CandidateCategory.needsSource,
            notes: 'Uncategorized profile; blocked by default.',
          ),
        );
      }
    }

    return CandidateMatrix(entries: entries);
  }

  final List<CandidateMatrixEntry> entries;

  /// Number of live production candidates qualified for execution.
  int get liveCandidateCount =>
      entries.where((e) => e.isLiveCandidate).length;

  /// Whether any profile in the matrix is eligible for live vehicle execution.
  ///
  /// In the baseline release, this is explicitly FALSE (no live candidate).
  bool get hasLiveCandidates => liveCandidateCount > 0;

  List<CandidateMatrixEntry> get simulationReadyEntries => entries
      .where((e) => e.category == CandidateCategory.simulationReady)
      .toList(growable: false);

  List<CandidateMatrixEntry> get needsSourceEntries => entries
      .where((e) => e.category == CandidateCategory.needsSource)
      .toList(growable: false);

  List<CandidateMatrixEntry> get needsBenchEntries => entries
      .where((e) => e.category == CandidateCategory.needsBench)
      .toList(growable: false);

  List<CandidateMatrixEntry> get externalOnlyEntries => entries
      .where((e) => e.category == CandidateCategory.externalOnly)
      .toList(growable: false);

  List<CandidateMatrixEntry> get qualifiedEntries => entries
      .where((e) => e.category == CandidateCategory.qualified)
      .toList(growable: false);
}

/// Helper for loading and validating bundled active-test service recipes.
final class BundledServiceRecipes {
  const BundledServiceRecipes._();

  static const List<String> bundledAssetPaths = [
    'assets/service_recipes/synthetic_mode08_evap_fixture.json',
    'assets/service_recipes/synthetic_uds_2f_io_control_fixture.json',
    'assets/service_recipes/synthetic_uds_31_routine_fixture.json',
  ];

  /// Parses and strictly validates a JSON active-test profile.
  static ActiveTestProfile parseProfileJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = ActiveTestProfile.fromJson(map);
    final errors = profile.validate();
    if (errors.isNotEmpty) {
      throw FormatException(
        'Profile ${profile.profileId} failed validation: $errors',
      );
    }
    return profile;
  }
}
