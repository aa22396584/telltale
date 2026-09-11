/// Community/experimental bounded-read profiles are usable; Mode 21 is not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_catalog_validator.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_pid_installer.dart';
import 'package:torque_obd/ui/widgets/status/datum_status_copy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Mode 22 experimental catalog entries install as unverified reads',
    () async {
      final snapshot = await PowertrainBatteryCatalogAsset.load();
      const validator = PowertrainBatteryProfileCatalogValidator();
      final experimental = snapshot.catalog.profiles.where(
        (profile) => profile.status.name == 'experimental',
      );
      expect(experimental, isNotEmpty);

      final mode22 = experimental.where(
        (profile) =>
            profile.commands.isNotEmpty &&
            profile.commands.every(
              (command) =>
                  PollableServices.isPollable(command.modeAndIdentifier),
            ),
      );
      expect(
        mode22,
        isNotEmpty,
        reason: 'catalog ships Mode 22 experimental maps',
      );
      for (final profile in mode22) {
        final validation = validator.validateProfile(profile);
        expect(validation.canInstall, isTrue, reason: profile.id);
        final pids = PowertrainProfilePidInstaller.build(profile);
        expect(pids, isNotEmpty, reason: profile.id);
        expect(pids.first.evidenceKind, 'experimental', reason: profile.id);
        final status = AvailabilityPolicy.forPid(pid: pids.first);
        expect(status.evidence, EvidenceKind.experimental);
        expect(status.badges, contains(DatumBadge.experimental));
        expect(
          status.badges,
          contains(DatumBadge.unverifiedOnThisVehicle),
        );
        final en = lookupAppLocalizations(englishLocale);
        final badge = datumBadgeText(en, status);
        expect(badge, contains('Experimental'));
        expect(badge, contains('Unverified on this vehicle'));
      }
    },
  );

  test('Mode 21 experimental stays probe-only', () async {
    final snapshot = await PowertrainBatteryCatalogAsset.load();
    const validator = PowertrainBatteryProfileCatalogValidator();
    final lexus = snapshot.catalog.profiles.singleWhere(
      (profile) => profile.id == 'lexus-rx450hl-2020-source-vehicle',
    );
    final validation = validator.validateProfile(lexus);
    expect(validation.canInstall, isFalse);
    expect(validation.canProbe, isTrue);
    expect(
      lexus.commands.every(
        (command) => !PollableServices.isPollable(command.modeAndIdentifier),
      ),
      isTrue,
    );
  });

  test('research-only empty commands stay metadata', () async {
    final snapshot = await PowertrainBatteryCatalogAsset.load();
    const validator = PowertrainBatteryProfileCatalogValidator();
    final research = snapshot.catalog.profiles.where(
      (profile) => profile.status.name == 'researchOnly',
    );
    expect(research, isNotEmpty);
    for (final profile in research.take(8)) {
      expect(validator.validateProfile(profile).canInstall, isFalse);
      expect(profile.commands, isEmpty);
    }
  });
}
