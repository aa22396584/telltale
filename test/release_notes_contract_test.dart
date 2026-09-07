// The release workflow's two decisions, executed rather than described.
//
// Both of them were wrong last week in the same way: the claim was derived from
// the tag string and validated nothing. The notes said "this exact binary has
// not been walked on a phone", whose negation -- what a full release then
// asserted -- nothing checked and nobody could have checked, because the walked
// build is signed locally and the published one is signed by CI. A flag that
// cannot be wrong is not a flag.
//
// These tests run `tool/release/*.sh` as the workflow runs them. That is the
// point: this file is not a second implementation of the rule that can drift
// from the first, it is the first one under a harness. The prose assertions are
// hand-typed rather than derived from the script's own output, because a test
// that reads the implementation to build its expectation agrees with any
// implementation, including a broken one.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notesScript = 'tool/release/release_notes.sh';
const _gateScript = 'tool/release/require_device_walk.sh';

/// Enough to fill the table; the values themselves are opaque to the script.
const _sha = 'b1946ac92492d2347c6235b4d2611184b1946ac92492d2347c6235b4d2611184';
const _fingerprint =
    '7e97b3dd0b3f11a9a593cf8d182d49032490022938cecaafde90b53d5825414d';

ProcessResult _notes(String mode, {required String tag, Map<String, String>? env}) {
  return Process.runSync(
    'bash',
    [_notesScript, mode],
    environment: {
      'TAG': tag,
      'APP_VERSION': '1.0.12+13',
      'APK_SIZE': '31M',
      'APK_SHA256': _sha,
      'APK_FINGERPRINT': _fingerprint,
      ...?env,
    },
  );
}

String _body(String tag) {
  final r = _notes('notes', tag: tag);
  expect(r.exitCode, 0, reason: 'stderr: ${r.stderr}');
  return r.stdout as String;
}

void main() {
  setUpAll(() {
    // A test that silently skips because it cannot find what it tests is the
    // failure mode this whole file exists to prevent.
    expect(File(_notesScript).existsSync(), isTrue,
        reason: '$_notesScript must be run from the package root');
    expect(File(_gateScript).existsSync(), isTrue);
  });

  group('the flag and the prose come from one reading of the tag', () {
    test('a SemVer pre-release suffix is the only thing that sets the flag', () {
      for (final tag in ['v1.0.12', 'v2.0.0', 'v10.20.30']) {
        expect((_notes('flag', tag: tag).stdout as String).trim(), 'full',
            reason: '$tag has no pre-release identifier');
      }
      for (final tag in ['v1.0.12-beta.1', 'v1.0.12-rc1', 'v1.0.12-0']) {
        expect((_notes('flag', tag: tag).stdout as String).trim(), 'prerelease',
            reason: '$tag has a pre-release identifier');
      }
    });

    test('the flag and the paragraph never disagree', () {
      // The pairing is the invariant. Asserting each half separately would let
      // a change move both to the same wrong side and stay green.
      for (final tag in ['v1.0.12', 'v1.0.12-beta.1']) {
        final flag = (_notes('flag', tag: tag).stdout as String).trim();
        final body = _body(tag);
        final saysWalked =
            body.contains('A release build of this commit was installed');
        final saysUnwalked = body.contains('No walk of this version is recorded');
        expect(saysWalked, flag == 'full', reason: 'tag $tag flag $flag');
        expect(saysUnwalked, flag == 'prerelease', reason: 'tag $tag flag $flag');
      }
    });

    test('a full release names the gap its own gate does not close', () {
      // The honest half of the claim. Dropping this sentence would leave a
      // release asserting that the published APK is the walked one.
      final body = _body('v1.0.12');
      // Matched within one line each: the script wraps these sentences, so an
      // expectation spanning a line break would fail on correct output.
      expect(body, contains('the walked build is not this APK'));
      expect(body, contains('signed with a different key'));
      expect(body, contains('走查的那一份不是下面這份 APK'));
    });
  });

  group('the evidence boundary is not tied to the flag', () {
    // This is the coupling that kept GitHub's Latest badge nine days stale: the
    // boundary printed only when --prerelease was set, so publishing a findable
    // release meant deleting the honest paragraph. Re-couple them -- move the
    // boundary heredoc inside the `if is_prerelease` branch -- and the second
    // expectation below goes red.
    for (final entry in {
      'a pre-release': 'v1.0.12-beta.1',
      'a full release': 'v1.0.12',
    }.entries) {
      test('${entry.key} states what has and has not been run against', () {
        final body = _body(entry.value);
        expect(body, contains(
            '**What this build has been run against, and what it has not.**'));
        expect(body, contains('**這份 build 跑過什麼，沒跑過什麼。**'));
        expect(body, contains('**One** real-vehicle observation exists'));
        expect(body, contains('**Still unverified:** any second adapter'));
        expect(body, contains('真車觀察只有**一次**'));
      });
    }
  });

  group('the notes carry the artifact facts they were handed', () {
    test('both languages, and every value from the build step', () {
      final body = _body('v1.0.12');
      expect(body, contains('`telltale-v1.0.12.apk` (31M)'));
      expect(body, contains(_sha));
      expect(body, contains(_fingerprint));
      expect(body, contains('Telltale 1.0.12+13'));
      // Two languages, each stating the signature consequence in its own right
      // rather than one being a stub pointing at the other.
      expect(body, contains('signed with the community key, not the Google Play'));
      expect(body, contains('這份是社群簽章金鑰簽的，不是 Google Play 的上架金鑰'));
    });

    test('a missing fact is a failure, not an empty table cell', () {
      // `set -u` plus `${VAR:?}` -- the alternative is a release note with a
      // blank SHA-256 that still publishes.
      for (final missing in [
        'APP_VERSION',
        'APK_SIZE',
        'APK_SHA256',
        'APK_FINGERPRINT',
      ]) {
        final r = Process.runSync(
          'bash',
          [_notesScript, 'notes'],
          environment: {
            'TAG': 'v1.0.12',
            'APP_VERSION': '1.0.12+13',
            'APK_SIZE': '31M',
            'APK_SHA256': _sha,
            'APK_FINGERPRINT': _fingerprint,
          }..remove(missing),
          includeParentEnvironment: false,
        );
        expect(r.exitCode, isNot(0), reason: 'omitting $missing must fail');
      }
    });
  });

  group('a full-release tag must consume a device-walk attestation', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('walkgate'));
    tearDown(() => tmp.deleteSync(recursive: true));

    String fixture(String contents) {
      final f = File('${tmp.path}/device-verification.md')
        ..writeAsStringSync(contents);
      return f.path;
    }

    ProcessResult gate(String tag, [String? evidence]) => Process.runSync(
          'bash',
          [_gateScript, tag, ?evidence],
        );

    test('a dated heading naming the version clears the gate', () {
      final f = fixture('# Device verification\n\n'
          '## 2026-09-07 — 1.0.12 release APK, English walk-through\n\nbody\n');
      expect(gate('v1.0.12', f).exitCode, 0);
    });

    test('no entry for this version refuses the tag', () {
      final f = fixture('## 2026-09-06 — 1.0.8 release APK\n');
      final r = gate('v1.0.12', f);
      expect(r.exitCode, 1);
      expect(r.stdout, contains('::error::'));
      // The refusal has to name the way out, or it is a stall again.
      expect(r.stdout, contains('v1.0.12-beta.1'));
    });

    test('a pre-release tag needs no entry, and says so', () {
      final f = fixture('# nothing here\n');
      final r = gate('v1.0.13-beta.1', f);
      expect(r.exitCode, 0);
      expect(r.stdout, contains('no device-walk entry required'));
    });

    test('a longer version is not this version', () {
      // The substring trap. `grep -q 1.0.12` reads 1.0.121 as a match, and
      // reads 1.0.1 as present in every 1.0.1x heading the real file has.
      final f = fixture('## 2026-09-07 — 1.0.121 release APK\n');
      expect(gate('v1.0.12', f).exitCode, 1);

      final g = fixture('## 2026-09-07 — 1.0.12 release APK\n');
      expect(gate('v1.0.1', g).exitCode, 1,
          reason: '1.0.1 is not attested by a 1.0.12 entry');
      expect(gate('v1.0.12', g).exitCode, 0);
    });

    test('dots are literal, not any-character', () {
      final f = fixture('## 2026-09-07 — 1a0b12 release APK\n');
      expect(gate('v1.0.12', f).exitCode, 1);
    });

    test('an undated heading is prose, not an attestation', () {
      // The real file carries section headings like "## The three links
      // exercised" alongside dated walk entries. Accepting any heading would
      // let a paragraph about rig work satisfy a release gate.
      final f = fixture('## 1.0.12 walked, trust me\n');
      expect(gate('v1.0.12', f).exitCode, 1);
    });

    test('a version named outside a heading does not count', () {
      final f = fixture('Some prose mentioning 1.0.12 in passing.\n');
      expect(gate('v1.0.12', f).exitCode, 1);
    });

    test('a missing evidence file is a failure, not an empty pass', () {
      final r = gate('v1.0.12', '${tmp.path}/nope.md');
      expect(r.exitCode, 1);
      expect(r.stdout, contains('does not exist'));
    });

    test('the real evidence file attests the version being released', () {
      // Not a fixture: the file the workflow will actually read, at the version
      // pubspec.yaml actually carries. This is the test that fails when someone
      // bumps the version and forgets the walk.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+\d+$',
              multiLine: true)
          .firstMatch(pubspec)
          ?.group(1);
      expect(version, isNotNull, reason: 'pubspec.yaml must carry X.Y.Z+N');
      final r = gate('v$version');
      expect(r.exitCode, 0,
          reason: 'pubspec is at $version; ${r.stdout}${r.stderr}');
    });
  });
}
