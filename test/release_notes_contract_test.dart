// The release workflow's two decisions, executed rather than described.
//
// Both were wrong in the same way to begin with: the claim was derived from the
// tag string and validated nothing. The notes said "this exact binary has not
// been walked on a phone", whose negation -- what a full release then asserted
// -- nothing checked and nobody could have checked, because the walked build is
// signed locally and the published one by CI. A flag that cannot be wrong is
// not a flag.
//
// These tests run `tool/release/*.sh` as the workflow runs them. That is the
// point: this file is not a second implementation of the rule that can drift
// from the first, it is the first one under a harness. Expectations are
// hand-typed rather than derived from the script's own output, because a test
// that reads the implementation to build its expectation agrees with any
// implementation, including a broken one.
//
// Every negative case below is an input a reviewer actually used to defeat an
// earlier version of this gate. They are kept verbatim.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notesScript = 'tool/release/release_notes.sh';
const _gateScript = 'tool/release/require_device_walk.sh';
const _workflow = '.github/workflows/release.yml';
const _evidence = 'docs/verification/device-verification.md';
const _changelog = 'CHANGELOG.md';

/// `version: X.Y.Z+N` from pubspec.yaml — the one place the version is
/// declared, so every check below derives from it rather than restating it.
({String name, String code}) _pubspecVersion() {
  final m = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)$', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync());
  expect(m, isNotNull, reason: 'pubspec.yaml must carry version: X.Y.Z+N');
  return (name: m!.group(1)!, code: m.group(2)!);
}

/// Enough to fill the table; the values themselves are opaque to the script.
const _sha = 'b1946ac92492d2347c6235b4d2611184b1946ac92492d2347c6235b4d2611184';
const _fingerprint =
    '7e97b3dd0b3f11a9a593cf8d182d49032490022938cecaafde90b53d5825414d';

ProcessResult _notes(String mode, {required String tag}) => Process.runSync(
      'bash',
      [_notesScript, mode],
      environment: {
        'TAG': tag,
        'APP_VERSION': '1.0.12+13',
        'APK_SIZE': '31M',
        'APK_SHA256': _sha,
        'APK_FINGERPRINT': _fingerprint,
      },
    );

/// The flag, with its exit status checked. Reading stdout alone accepts a
/// script that prints the right word and then dies: the workflow would abort,
/// and the suite would call that green.
String _flag(String tag) {
  final r = _notes('flag', tag: tag);
  expect(r.exitCode, 0, reason: 'flag mode must succeed; stderr: ${r.stderr}');
  return (r.stdout as String).trim();
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
        expect(_flag(tag), 'full', reason: '$tag has no pre-release identifier');
      }
      // Not only `-beta.N`. SemVer allows any identifier after the first
      // hyphen, and narrowing the match to beta would block a legitimate
      // `-rc1` or `-0` while reading as correct.
      for (final tag in [
        'v1.0.12-beta.1',
        'v1.0.12-rc1',
        'v1.0.12-rc.1',
        'v1.0.12-0',
        'v1.0.12-alpha',
      ]) {
        expect(_flag(tag), 'prerelease',
            reason: '$tag has a pre-release identifier');
      }
    });

    test('the flag and the paragraph never disagree', () {
      // The pairing is the invariant. Asserting each half separately would let
      // a change move both to the same wrong side and stay green.
      for (final tag in ['v1.0.12', 'v1.0.12-beta.1', 'v1.0.12-rc1']) {
        final flag = _flag(tag);
        final body = _body(tag);
        // Within one line: the script wraps this sentence, so a substring
        // spanning its line break would fail on correct output.
        final saysWalked = body.contains('walk for this version');
        final saysNothing =
            body.contains('neither requires nor attests a recorded device');
        expect(saysWalked, flag == 'full', reason: 'tag $tag flag $flag');
        expect(saysNothing, flag == 'prerelease', reason: 'tag $tag flag $flag');
      }
    });

    test('a full release names both gaps its gate does not close', () {
      // Two claims the gate cannot make, each of which the notes made once.
      // Matched within one line each: the script wraps these sentences, so an
      // expectation spanning a line break would fail on correct output.
      final body = _body('v1.0.12');
      expect(body, contains('It attests the **version**, not the commit'));
      expect(body, contains('is byte-for-byte the code tagged'));
      expect(body, contains('walked build is not this APK'));
      expect(body, contains('它佐證的是**版本**，不是 commit'));
      expect(body, contains('走查的那一份不是下面這份 APK'));
    });

    test('a pre-release does not claim the record is absent', () {
      // It cannot know: the gate returns before reading the file on this path.
      // Re-cutting a beta after a walk used to print a sentence the record
      // contradicted.
      final body = _body('v1.0.12-beta.1');
      expect(body, isNot(contains('No walk of this version is recorded')));
      expect(body, isNot(contains('裡沒有這個版本的')));
      expect(body, contains('neither requires nor attests a recorded device'));
      expect(body, contains('既不要求、也不宣稱有實機走查紀錄'));
    });
  });

  group('the evidence boundary is not tied to the flag', () {
    // This is the coupling that kept GitHub's Latest badge nine days stale: the
    // boundary printed only when --prerelease was set, so publishing a findable
    // release meant deleting the honest paragraph. Re-couple them -- move the
    // boundary heredoc inside the `if is_prerelease` branch -- and the second
    // case below goes red.
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
        expect(body, contains('真車觀察只有**一次**'));

        // The qualifications, not just the headline. Deleting these leaves a
        // paragraph that still looks like a disclosure and no longer is: one
        // adapter reads as adapter support, and an unreviewed transcript reads
        // as a verified session.
        expect(body, contains('One\n>   adapter and one car is not adapter '
            'compatibility'));
        expect(body, contains('has not been reviewed or published'));
        expect(body, contains('**Still unverified:** any second adapter, any '
            'other vehicle, and'));
        expect(body, contains('every engine-running condition'));
        expect(body, contains('一個轉接器加一台車不等於'));
        expect(body, contains('尚未審閱、也尚未公開'));
        expect(body, contains('以及所有引擎運轉中的情境'));
      });
    }
  });

  group('the notes carry the artifact facts they were handed', () {
    test('each value is in the row that names it', () {
      // Asserting only that both values appear somewhere accepts a table with
      // the SHA-256 and the certificate fingerprint swapped -- two 64-character
      // hex strings that nobody eyeballing the page would catch, and the
      // sha256sum line beneath tells the reader to check one of them.
      final body = _body('v1.0.12');
      expect(body, contains('| File | `telltale-v1.0.12.apk` (31M) |'));
      expect(body, contains('| SHA-256 | `$_sha` |'));
      expect(body, contains('| Signing certificate | `$_fingerprint` |'));
      expect(body, contains('Telltale 1.0.12+13'));
      expect(body, contains('sha256sum telltale-v1.0.12.apk'));
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

    test('an unknown mode is refused rather than guessed', () {
      final r = Process.runSync('bash', [_notesScript, 'flagg'],
          environment: {'TAG': 'v1.0.12'});
      expect(r.exitCode, 2);
      expect(r.stderr, contains('usage:'));
    });
  });

  group('the workflow hands the script the values it thinks it does', () {
    // The scripts are exercised above with an environment the test supplies,
    // so nothing there notices two workflow env keys swapped. This reads the
    // workflow's own text. The table is hand-typed; transposing two rows in
    // release.yml turns it red.
    // This file is mirrored into the private repository, where `.github/` and
    // `store/` are publish-only and the release workflow genuinely is not
    // there. That could have been a skip; skips are how a check comes to run
    // nowhere. Instead each checkout asserts the thing that is true of it, and
    // both assertions can fail.
    //
    // The private-side one is not a formality. `docs/*.html` was once excluded
    // from the mirror file by file, so a newly added `index.en.html` fell
    // outside the list and `rsync --delete` removed it while `privacy.html`
    // survived: a privacy policy that still returned 200 and whose language
    // switch pointed at a 404. Wholesale absence is the mirror; a partial set
    // is that bug.
    const publishOnly = [
      '.github/workflows/release.yml',
      '.github/workflows/ci.yml',
      'store/upload.sh',
      'docs/privacy.html',
      'docs/.nojekyll',
    ];
    late final List<String> present =
        publishOnly.where((p) => File(p).existsSync()).toList();
    late final bool isPublicCheckout = present.length == publishOnly.length;

    setUpAll(() {
      expect(present.length, anyOf(0, publishOnly.length),
          reason: 'publish-only files are all present (the public repo) or all '
              'absent (the private mirror). Present here: $present');
    });

    String publishStepOrSkipReason() {
      final yaml = File(_workflow).readAsStringSync();
      final start = yaml.indexOf('- name: Publish the release');
      final end = yaml.indexOf('- name: Shred the signing material');
      expect(start, greaterThan(0));
      expect(end, greaterThan(start));
      return yaml.substring(start, end);
    }

    test('every value the notes print comes from the step that measured it', () {
      if (!isPublicCheckout) return;
      final publishStep = publishStepOrSkipReason();
      const expected = {
        'TAG': r'${{ steps.release_tag.outputs.tag }}',
        'APP_VERSION': r'${{ steps.describe.outputs.version }}',
        'APK_SIZE': r'${{ steps.describe.outputs.size }}',
        'APK_SHA256': r'${{ steps.describe.outputs.sha256 }}',
        'APK_FINGERPRINT': r'${{ steps.describe.outputs.fingerprint }}',
      };
      expected.forEach((key, value) {
        expect(publishStep, contains('$key: $value'),
            reason: '$key must be fed from $value');
      });
    });

    test('the workflow calls the scripts rather than restating them', () {
      if (!isPublicCheckout) return;
      final publishStep = publishStepOrSkipReason();
      expect(publishStep, contains('bash $_notesScript notes > notes.md'));
      expect(publishStep, contains(r'release_flag=$(bash ' '$_notesScript'
          ' flag)'));
      // Read into a variable, then matched exhaustively. Inlined into an `if`
      // the flag fails OPEN: a condition is exempt from set -e and `[`
      // discards the substitution's status, so a crashed script publishes a
      // full release.
      expect(publishStep, contains('prerelease) release_args+=(--prerelease)'));
      expect(publishStep, contains('Unexpected release flag'));
      // Still immutable, still tag-verified.
      expect(publishStep, contains('published assets are immutable by policy'));
      expect(publishStep, contains('--verify-tag'));

      final yaml = File(_workflow).readAsStringSync();
      expect(yaml, contains('bash $_gateScript "\$TAG"'));
      // Before the build, not after it: a 40-minute wait for a refusal that
      // could have been issued in a second is its own kind of stall.
      expect(yaml.indexOf('bash $_gateScript'),
          lessThan(yaml.indexOf('- name: Restore the community signing key')));
    });
  });

  group('the version is declared once and agrees everywhere', () {
    test('CHANGELOG.md has a section for the version being shipped', () {
      // Nothing checked this, so it drifted: at the 1.0.12 bump the changelog's
      // newest released section was still 1.0.11, while README.md links to that
      // file as the version history. A reader following the link would have
      // been told the latest release was the previous one.
      final version = _pubspecVersion().name;
      final sections = RegExp(r'^## (\d+\.\d+\.\d+)', multiLine: true)
          .allMatches(File(_changelog).readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
      expect(sections, isNotEmpty, reason: '$_changelog has no released '
          'sections at all, so this test asserts nothing');
      expect(sections.first, version,
          reason: 'pubspec is at $version; $_changelog leads with '
              '${sections.first}. The newest section is what a reader takes '
              'as the current release.');
    });

    test('the store changelog exists for this versionCode, within Play\'s '
        'limit', () {
      // store/ is publish-only, so it is absent in the private mirror. Absence
      // is checked wholesale by the group above; here, if the directory is
      // present it must be complete.
      if (!Directory('store/metadata').existsSync()) return;
      final code = _pubspecVersion().code;
      for (final locale in ['en-US', 'zh-TW']) {
        final f = File('store/metadata/$locale/changelogs/$code.txt');
        expect(f.existsSync(), isTrue,
            reason: 'versionCode $code needs ${f.path}; Play shows the last '
                'one it has, so a missing file ships the previous release\'s '
                'notes rather than nothing');
        final bytes = f.readAsBytesSync().length;
        expect(bytes, lessThanOrEqualTo(500),
            reason: '${f.path} is $bytes bytes; Play rejects over 500');
        expect(f.readAsStringSync().trim(), isNotEmpty);
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

    test('the attestation line clears the gate', () {
      final f = fixture('# Device verification\n\n'
          '## 2026-09-07 — 1.0.12 release APK, English walk-through\n\n'
          'Device walk attested: 1.0.12\n\nbody\n');
      final r = gate('v1.0.12', f);
      expect(r.exitCode, 0, reason: r.stdout as String);
      expect(r.stdout, contains('device walk attested for 1.0.12'));
    });

    test('no attestation for this version refuses the tag', () {
      final f = fixture('Device walk attested: 1.0.8\n');
      final r = gate('v1.0.12', f);
      expect(r.exitCode, 1);
      expect(r.stdout, contains('::error::'));
      // The refusal must name the line to add and the way out, or it is a
      // stall again.
      expect(r.stdout, contains('Device walk attested: 1.0.12'));
      expect(r.stdout, contains('v1.0.12-beta.1'));
    });

    test('any pre-release suffix needs no attestation, and says so', () {
      for (final tag in ['v1.0.13-beta.1', 'v1.0.13-rc1', 'v1.0.13-0']) {
        final f = fixture('# nothing here\n');
        final r = gate(tag, f);
        expect(r.exitCode, 0, reason: '$tag: ${r.stdout}');
        expect(r.stdout, contains('no device-walk entry required'));
      }
    });

    group('a sentence that mentions a version does not attest it', () {
      // Every one of these cleared an earlier version of this gate, which
      // searched a dated heading for the version anywhere inside it. The first
      // one says the opposite of what it was read as saying.
      const mentions = [
        '## 2026-09-07 — 1.0.11 walk; 1.0.12 not installed',
        '## 2026-09-07 — x1.0.12oops',
        '## 2026-09-07 — 1.0.12-rc.1 planned, no walk',
        '## 2026-09-07 — 1.0.12 release APK, English walk-through',
        '## 2026-09-07 — 1.0.12 release APK\n\nWalk status: NOT RUN',
        'We plan to walk 1.0.12 next week.',
        'Device walk attested 1.0.12',
        'device walk attested: 1.0.12',
        '  Device walk attested: 1.0.12',
      ];
      for (final line in mentions) {
        test(line.split('\n').first, () {
          expect(gate('v1.0.12', fixture('$line\n')).exitCode, 1);
        });
      }
    });

    test('the attested version is the whole of what follows the colon', () {
      // The substring trap, at the only place it can still reach: `1.0.12` is
      // a prefix of `1.0.121`, and a trailing qualifier is not the version.
      expect(gate('v1.0.12', fixture('Device walk attested: 1.0.121\n')).exitCode,
          1);
      expect(
          gate('v1.0.12', fixture('Device walk attested: 1.0.12 (partial)\n'))
              .exitCode,
          1);
      expect(gate('v1.0.1', fixture('Device walk attested: 1.0.12\n')).exitCode,
          1);
      // Dots are literal, not any-character.
      expect(gate('v1.0.12', fixture('Device walk attested: 1a0b12\n')).exitCode,
          1);
      // Trailing whitespace is a typo, not a different claim.
      expect(gate('v1.0.12', fixture('Device walk attested: 1.0.12  \n')).exitCode,
          0);
    });

    test('the verdict does not depend on how long the file is', () {
      // A `grep ... | grep -q` pipeline is a size-dependent false refusal:
      // `grep -q` exits on its first match, the upstream process takes
      // SIGPIPE, and `set -o pipefail` reports the whole pipeline as failed --
      // so a line that IS present is read as absent. Today's file fits the
      // pipe buffer and passes; it gains an entry every release.
      //
      // The attestation is deliberately the FIRST line, so a refusal here
      // cannot be read as "not found" -- it was found and then discarded.
      final buffer = StringBuffer('Device walk attested: 1.0.12\n');
      for (var i = 0; i < 20000; i++) {
        buffer.writeln('## 2026-01-01 — 9.9.${i % 1000} filler heading with '
            'padding to fill the pipe buffer');
      }
      final f = fixture(buffer.toString());
      expect(gate('v1.0.12', f).exitCode, 0,
          reason: 'the attestation is on line 1 of a 1.5MB file');
      // The same file must still refuse a version it does not attest, or the
      // assertion above would pass against a gate that says yes to everything.
      expect(gate('v1.0.13', f).exitCode, 1);
    });

    test('an unreadable file is named as unreadable, not as empty', () {
      final f = fixture('Device walk attested: 1.0.12\n');
      Process.runSync('chmod', ['000', f]);
      var readable = true;
      try {
        File(f).readAsStringSync();
      } on FileSystemException {
        readable = false;
      }
      final r = gate('v1.0.12', f);
      // Asserted in both directions rather than skipped: running as root
      // leaves the file readable, and a test that quietly does nothing there
      // is the failure this suite exists to prevent.
      if (readable) {
        expect(r.exitCode, 0, reason: 'still readable, so the entry counts');
      } else {
        expect(r.exitCode, 1);
        expect(r.stdout, contains('cannot be read'));
        expect(r.stdout, isNot(contains('has no\n')),
            reason: 'an unreadable file is not a missing entry');
      }
      Process.runSync('chmod', ['644', f]);
    });

    test('a missing evidence file is a failure, not an empty pass', () {
      final r = gate('v1.0.12', '${tmp.path}/nope.md');
      expect(r.exitCode, 1);
      expect(r.stdout, contains('does not exist'));
    });

    test('a malformed tag is refused rather than parsed loosely', () {
      for (final tag in ['1.0.12', 'v1.0', 'vX.Y.Z', 'v1.0.12.1', '']) {
        expect(gate(tag, fixture('Device walk attested: 1.0.12\n')).exitCode,
            isNot(0),
            reason: '$tag is not a release tag');
      }
    });

    test('the gate reaches a decision on the real evidence file', () {
      // Not a fixture: the file the workflow will actually read, at the
      // version pubspec.yaml actually carries.
      //
      // What is NOT asserted is that the walk exists. A version bump
      // legitimately precedes its walk, and a pre-release tag never claims
      // one -- so demanding an entry would turn the unit suite red for exactly
      // the window in which cutting a beta is the correct move. That is the
      // stall this rule was written to remove; reintroducing it one layer
      // down, where nobody looks, is the same mistake.
      final version = _pubspecVersion().name;
      final r = gate('v$version');
      expect(r.stderr, isEmpty, reason: 'the real file must parse cleanly');
      expect(r.exitCode, anyOf(0, 1), reason: 'a decision, not a crash');
      expect(
        r.stdout,
        r.exitCode == 0
            ? contains('device walk attested for $version')
            : contains('::error::'),
      );
    });

    test('nothing else in the real file can stand in for the attestation', () {
      // The gate's own documentation lives inside the file the gate scans, and
      // the example in it was written as a real version. With
      // `Device walk attested: 1.0.12` in that code block, deleting the actual
      // entry still cleared a full release of 1.0.12: the explanation of the
      // check satisfied the check. A reviewer found it; nothing here would
      // have.
      //
      // What this pins is narrower than it first looks, and the narrowing
      // was found by mutating: restoring the concrete example leaves TWO
      // matching lines, both get stripped, and this still passes. So it does
      // not catch a duplicate -- the test below it does. What it does catch is
      // a stand-in of a DIFFERENT shape: if the gate ever accepted `Walked:
      // 1.0.12`, or a dated heading again, stripping the attestation lines
      // would leave that alternative behind and the gate would still say yes.
      final real = File(_evidence).readAsStringSync();
      final attested = RegExp(r'^Device walk attested: (\d+\.\d+\.\d+)\s*$',
              multiLine: true)
          .allMatches(real)
          .map((m) => m.group(1)!)
          .toSet();
      expect(attested, isNotEmpty);
      for (final v in attested) {
        final stripped = real
            .split('\n')
            .where((l) => l.trimRight() != 'Device walk attested: $v')
            .join('\n');
        expect(stripped, isNot(contains('Device walk attested: $v\n')),
            reason: 'the strip must actually remove it, or this asserts '
                'nothing');
        final r = gate('v$v', fixture(stripped));
        expect(r.exitCode, 1,
            reason: 'with every "Device walk attested: $v" removed, the file '
                'must no longer attest $v; got ${r.stdout}');
      }
    });

    test('one version, one attestation', () {
      // A second line attesting the same version is not a second walk; it is
      // something that is not an entry. That is how the gate's own
      // documentation came to satisfy the gate: the example under "The one
      // line a machine reads" was written as `Device walk attested: 1.0.12`,
      // so deleting the real entry still cleared a full release. A reviewer
      // found it, and the obvious regression test did not -- it stripped both
      // copies and watched the gate refuse, which proves nothing.
      //
      // Counting is what distinguishes them. Walking one version twice is a
      // real thing to do; recording it twice leaves a reader to pick, so amend
      // the entry rather than adding a line.
      final counts = <String, int>{};
      for (final m in RegExp(r'^Device walk attested: (\d+\.\d+\.\d+)\s*$',
              multiLine: true)
          .allMatches(File(_evidence).readAsStringSync())) {
        counts.update(m.group(1)!, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts, isNotEmpty);
      counts.forEach((version, n) {
        expect(n, 1,
            reason: '$_evidence attests $version $n times; one of them is not '
                'a walk entry');
      });
    });

    test('every attestation the real file already carries is one the gate '
        'accepts', () {
      // The false-refusal direction, and the one that actually costs
      // something: the maintainer does the walk, writes it down, and the tag
      // is refused anyway. Nothing here demands new work -- it reads the
      // versions the file already attests.
      // Well-formed versions only. The file's own explanation of the gate
      // carries `Device walk attested: <version>` as a placeholder -- which
      // the gate can never match, because it substitutes a literal X.Y.Z --
      // and the test above is what proves that placeholder attests nothing.
      final attested = RegExp(r'^Device walk attested: (\d+\.\d+\.\d+)\s*$',
              multiLine: true)
          .allMatches(File(_evidence).readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      expect(attested, isNotEmpty,
          reason: 'the real file must carry at least one attestation, or this '
              'test asserts nothing');
      for (final v in attested) {
        final r = gate('v$v');
        expect(r.exitCode, 0,
            reason: '$_evidence attests $v, so the gate must clear it; '
                'got ${r.stdout}${r.stderr}');
      }
    });
  });
}
