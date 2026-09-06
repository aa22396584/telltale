// Some strings in this app are written for a file, not for a person on a
// phone, and they are frozen in Traditional Chinese so that two people holding
// the same evidence file can compare it line by line. `DatumStatus.reason`,
// `.formula` and `.assumptions`, `FuelType.exportLabel`,
// `Drivetrain.exportLabel`.
//
// Every one of those was, at some point, rendered straight onto a screen. That
// is how the English build came to show 「車重 1500 kg（通用預設）；Cd 0.30…」 in
// its estimate details dialog, and 汽油 in its fuel picker. The argument for
// freezing the wording is about storage; it was silently taken as licence to
// display it.
//
// The fix in each case was the same shape — an identifier for the screen, the
// string for the file — and nothing stopped the next one from happening again.
// This does. It reads the source of `lib/ui` rather than pumping a widget,
// because the failure is a reference, and a reference is visible without
// running anything.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Symbols that exist to be written into an export and must not be read by the
/// interface, with what to use instead.
const _exportOnly = <String, String>{
  'exportLabel':
      'fuelTypeLabel / drivetrainLabel in '
          'lib/ui/screens/settings/vehicle_profile_copy.dart',
  '.assumptions':
      'assumptionsText(l10n, status, profile) in '
          'lib/ui/widgets/status/datum_status_copy.dart',
  '.formula':
      'datumFormulaText(l10n, status) in '
          'lib/ui/widgets/status/datum_status_copy.dart',
};

/// Where an export-only symbol is legitimately named.
///
/// Listed as exact `path:line-content` pairs rather than whole files, so a file
/// that gains a real violation is not excused by an unrelated mention it
/// already had.
const _allowed = <String>{
  // datum_status_copy is the boundary itself: it reads the frozen strings so
  // that nothing else has to.
  'lib/ui/widgets/status/datum_status_copy.dart',
};

void main() {
  test('lib/ui never reads a string that was written for an export file', () {
    final offences = <String>[];

    for (final entity in Directory('lib/ui').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_allowed.contains(entity.path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.trimLeft().startsWith('//')
            ? ''
            : line.split('//').first;
        for (final entry in _exportOnly.entries) {
          if (!code.contains(entry.key)) continue;
          // `.formula` and `.assumptions` also appear inside longer names —
          // `TelemetryStatus.formulaError` is an enum value, not a read off a
          // DatumStatus — so the member has to end where the word ends. That
          // trailing boundary is the whole difference between this guard and
          // one that cries wolf on its first run, which is how allowances get
          // widened until they excuse the real thing.
          if (entry.key.startsWith('.') &&
              !RegExp(
                r'(status|items\[[^\]]+\]|\w+Status)\' +
                    entry.key +
                    r'(?![A-Za-z0-9_])',
              ).hasMatch(code)) {
            continue;
          }
          offences.add(
            '${entity.path}:${i + 1}  ${line.trim()}\n'
            '    use ${entry.value}',
          );
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'These read a string that is frozen in Traditional Chinese because a '
          'telemetry export needs it to be. Showing it puts that language on '
          'the screen regardless of what the reader chose.\n\n'
          '${offences.join('\n')}',
    );
  });

  test('the allowance still names a file that exists', () {
    // An allowance that outlives its file is an allowance nobody notices is
    // excusing nothing — and the next person widens it rather than deleting it.
    for (final path in _allowed) {
      expect(File(path).existsSync(), isTrue, reason: '$path is gone');
    }
  });
}
