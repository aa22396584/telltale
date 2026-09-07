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

/// One list, two consumers. `release_notes.sh` and `require_device_walk.sh`
/// each answer "is this a pre-release" from their own `case "$TAG" in *-*)`,
/// and the suite used to feed them different tags -- five forms to the notes,
/// three to the gate. Narrowing the gate's arm to `*-beta*|*-rc*|*-0*` then
/// passed everything while refusing a legitimate `-alpha` tag with a message
/// naming the wrong reason.
const _prereleaseTags = [
  'v1.0.12-beta.1',
  'v1.0.12-rc1',
  'v1.0.12-rc.1',
  'v1.0.12-0',
  'v1.0.12-alpha',
  'v1.0.12-alpha.2+build.7',
];
const _fullTags = ['v1.0.12', 'v2.0.0', 'v10.20.30'];

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

ProcessResult _notes(String mode, {required String tag, String? changelog}) =>
    Process.runSync(
      'bash',
      [_notesScript, mode],
      environment: {
        'TAG': tag,
        'APP_VERSION': '1.0.12+13',
        'APK_SIZE': '31M',
        'APK_SHA256': _sha,
        'APK_FINGERPRINT': _fingerprint,
        'CHANGELOG_PATH': ?changelog,
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

/// A CHANGELOG the notes tests own, written once for the whole file.
///
/// Without it every test that calls [_body] depends on the live
/// `CHANGELOG.md` having a section for whatever tag it passes. Renaming the
/// real `## 1.0.12` heading reddened SEVEN tests, six of them about the
/// pre-release flag, the evidence boundary and the artifact table — subjects
/// with no connection to the changelog at all. A reviewer measured that. The
/// coupling is the thing this file's own comments warn about two hundred
/// lines down, and it arrived the moment the notes started reading a second
/// file.
///
/// The 1.0.12 entry here is deliberately not the real one: a test that wants
/// the real file's content should say so by reading the real file.
final String _fixtureChangelog = () {
  final dir = Directory.systemTemp.createTempSync('notes_changelog');
  final f = File('${dir.path}/CHANGELOG.md')
    ..writeAsStringSync('# Changelog\n'
        '\n'
        '## Unreleased\n'
        '\n'
        '- UNSHIPPED: this line must never reach a release body.\n'
        '\n'
        '## 1.0.12 — 2026-09-07\n'
        '\n'
        '- FIXTURE: not the real entry, and not meant to be.\n');
  return f.path;
}();

String _body(String tag) {
  final r = _notes('notes', tag: tag, changelog: _fixtureChangelog);
  expect(r.exitCode, 0, reason: 'stderr: ${r.stderr}');
  return r.stdout as String;
}

/// [md] with fenced code blocks and HTML comments blanked, line for line.
///
/// The gate is deliberately Markdown-blind: `grep -qE '^Device walk attested:
/// X$'` on a file, no state machine in bash. The cost is that an attestation
/// inside a fence or an HTML comment satisfies it while being, to a reader,
/// an example or an invisible line.
///
/// Two test-side guards were meant to cover that and did not, for a reason
/// worth writing down: they were written with the same line-anchored regexes
/// as the gate. **Two Markdown-blind checkers do not compose into a
/// Markdown-aware one.** A fenced worked entry — the most natural doc edit
/// there is, "here is what a finished entry looks like" — carries its own
/// dated heading, so `every attestation belongs to a dated entry` was
/// satisfied by the example's own corroboration, and `one version, one
/// attestation` saw exactly one. Gate exit 0, suite green, no walk.
///
/// So the parsing lives here instead: four lines of Dart that only have to be
/// right about the file that is committed, rather than a state machine in a
/// shell script that runs during a release.
String _proseOnly(String md) {
  final out = <String>[];
  var fence = '';
  var inComment = false;
  for (final line in md.split('\n')) {
    var keep = line;

    if (inComment) {
      final end = keep.indexOf('-->');
      if (end < 0) {
        out.add('');
        continue;
      }
      keep = keep.substring(end + 3);
      inComment = false;
    }
    while (true) {
      final start = keep.indexOf('<!--');
      if (start < 0) break;
      final end = keep.indexOf('-->', start + 4);
      if (end < 0) {
        keep = keep.substring(0, start);
        inComment = true;
        break;
      }
      keep = keep.substring(0, start) + keep.substring(end + 3);
    }

    final trimmed = keep.trimLeft();
    final run = RegExp(r'^(`{3,}|~{3,})').firstMatch(trimmed)?.group(1);
    if (fence.isNotEmpty) {
      // CommonMark: the closing fence is the same character and at least as
      // long. Matching on "starts with ```" instead lets a three-backtick
      // line close a four-backtick block, which is exactly how a nested
      // example survives being stripped.
      if (run != null && run[0] == fence[0] && run.length >= fence.length) {
        fence = '';
      }
      out.add('');
      continue;
    }
    if (run != null) {
      fence = run;
      out.add('');
      continue;
    }
    out.add(keep);
  }
  // Joined rather than written line by line: `split('\n')` yields a trailing
  // empty element for a file ending in a newline, and `writeln` on it added a
  // line the original did not have. Caught by the line-count assertion below,
  // which is the only reason it is safe to report line numbers against this.
  return out.join('\n');
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
      for (final tag in _fullTags) {
        expect(_flag(tag), 'full', reason: '$tag has no pre-release identifier');
      }
      // Not only `-beta.N`. SemVer allows any identifier after the first
      // hyphen, and narrowing the match to beta would block a legitimate
      // `-rc1` or `-0` while reading as correct.
      for (final tag in _prereleaseTags) {
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
    // Absence needs a second, independent witness, or "all of them vanished"
    // is indistinguishable from "we are the mirror" and the coupling checks
    // below quietly stop running. A reviewer proved that: deleting the whole
    // publish-only set from the PUBLIC checkout left all 38 tests green.
    //
    // The private mirror keeps the app under `app/`, beside the reverse
    // engineering spec that is the reason that repository is private. The
    // public repository's root IS the app root, so nothing sits above it.
    // That is a structural fact about the two layouts, not a marker file
    // somebody has to remember to maintain.
    const privateMirrorWitness = '../torque_architecture_spec.md';

    late final List<String> present =
        publishOnly.where((p) => File(p).existsSync()).toList();
    late final bool isPublicCheckout = present.length == publishOnly.length;

    setUpAll(() {
      expect(present.length, anyOf(0, publishOnly.length),
          reason: 'publish-only files are all present (the public repo) or all '
              'absent (the private mirror). Present here: $present');
      if (present.isEmpty) {
        expect(File(privateMirrorWitness).existsSync(), isTrue,
            reason: 'every publish-only file is missing, which is normal in the '
                'private mirror and a catastrophe in the public repository. '
                '$privateMirrorWitness is what says which one this is, and it '
                'is not here.');
      } else {
        // The other direction, so the witness cannot rot unnoticed: if the
        // spec ever appeared above a checkout that also has the publish-only
        // set, the discriminator would be meaningless and this says so.
        expect(File(privateMirrorWitness).existsSync(), isFalse,
            reason: 'the publish-only set is present, so this is the public '
                'repository, and $privateMirrorWitness must not be above it');
      }
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
      // The gate step read as a WHOLE BLOCK, not as a substring anywhere in
      // the file. Three mutations passed when this only grepped for the run
      // line, and all three leave a workflow that never refuses anything:
      //
      //   continue-on-error: true      the gate becomes advisory
      //   ... "$TAG" || true           same, one line lower
      //   TAG: ${{ ... }}-skip         the gate sees a hyphen and takes the
      //                                pre-release exit, so it is never asked
      //
      // The third is the one worth staring at: the script is untouched and
      // correct, and it publishes a full release with no attestation, because
      // the question it was handed was a different question.
      final gateStart = yaml.indexOf('- name: Require a recorded device walk');
      expect(gateStart, greaterThan(0));
      final gateEnd = yaml.indexOf('      - name: ', gateStart + 10);
      expect(gateEnd, greaterThan(gateStart));
      final gateStep = yaml.substring(gateStart, gateEnd);
      expect(
        gateStep.trimRight(),
        '- name: Require a recorded device walk for a full release\n'
            '        env:\n'
            '          TAG: \${{ steps.release_tag.outputs.tag }}\n'
            '        run: bash $_gateScript "\$TAG"',
        reason: 'the gate step must be exactly this: the tag it is handed is '
            'the tag being published, and nothing may make its failure '
            'non-fatal',
      );
      // Before the build, not after it: a 40-minute wait for a refusal that
      // could have been issued in a second is its own kind of stall.
      expect(yaml.indexOf('bash $_gateScript'),
          lessThan(yaml.indexOf('- name: Restore the community signing key')));
    });

    test('the changelog gate step is fatal, and runs before the build', () {
      if (!isPublicCheckout) return;
      final yaml = File(_workflow).readAsStringSync();
      // The same whole-block comparison, for the same three defeats: a
      // `continue-on-error: true`, a `|| true`, or a doctored TAG all leave a
      // step that looks like a gate and refuses nothing. Grepping for the run
      // line survives all three.
      final start = yaml.indexOf('- name: Require a CHANGELOG section');
      expect(start, greaterThan(0));
      final end = yaml.indexOf('      - name: ', start + 10);
      expect(end, greaterThan(start));
      expect(
        yaml.substring(start, end).trimRight(),
        '- name: Require a CHANGELOG section for this version\n'
            '        env:\n'
            '          TAG: \${{ steps.release_tag.outputs.tag }}\n'
            '        run: bash $_notesScript changelog > /dev/null',
        reason: 'the changelog gate must be exactly this: the tag it is handed '
            'is the tag being published, and nothing may make its failure '
            'non-fatal',
      );
      // `> /dev/null` on purpose: this step is asked whether the section
      // exists, not to produce the body. The body is composed at publish time
      // from the same function, so the two cannot disagree about what a
      // section is.
      expect(yaml.indexOf('$_notesScript changelog'),
          lessThan(yaml.indexOf('- name: Restore the community signing key')),
          reason: 'refusing a tag for a missing changelog after a 40-minute '
              'build is the stall this gate exists to avoid');
    });
  });

  group('the release notes say what changed', () {
    // Every block the notes printed before v1.0.13 answered "what is this
    // build NOT" -- who signed it, how far the walk went, what has never been
    // driven -- and none of them answered "what changed". `CHANGELOG.md` had
    // the answer the whole time and no path carried it to the release page.
    // The user reading the release said so; nothing here would have.
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('changelog_notes'));
    tearDown(() => tmp.deleteSync(recursive: true));

    // A fixture rather than the repository's own CHANGELOG. A test asserting
    // that the real file has a section for the real current version goes red
    // at the next version bump for being right, and the next person deletes
    // it. The gate below does that job on the real file, in the workflow,
    // where being red is the point.
    /// A CHANGELOG with arbitrary content, for the cases the shared fixture
    /// would make unreadable.
    String rawFixture(String contents) {
      final f = File('${tmp.path}/raw-${contents.hashCode}.md')
        ..writeAsStringSync(contents);
      return f.path;
    }

    String fixture() {
      final f = File('${tmp.path}/CHANGELOG.md')
        ..writeAsStringSync('# Changelog\n'
            '\n'
            '## Unreleased\n'
            '\n'
            '- UNSHIPPED: this line must never reach a release body.\n'
            '\n'
            'An example of what a finished entry looks like:\n'
            '\n'
            '```markdown\n'
            '## 9.9.7 — 2025-01-01\n'
            '\n'
            '- FENCED: an example, not a release.\n'
            '```\n'
            '\n'
            '<!--\n'
            '## 9.9.6 — 2024-01-01\n'
            '\n'
            '- COMMENTED: not a release either.\n'
            '-->\n'
            '\n'
            '## 9.9.9 — 2026-01-01\n'
            '\n'
            '### Fixed\n'
            '\n'
            '- The fixture entry for nine.\n'
            '\n'
            '## 9.9.8+42 — 2025-12-31\n'
            '\n'
            '- OLDER: the previous section, which must not be swept in.\n');
      return f.path;
    }

    test('the body leads with this version\'s section, verbatim', () {
      final r = _notes('notes', tag: 'v9.9.9', changelog: fixture());
      expect(r.exitCode, 0, reason: r.stderr as String);
      final body = r.stdout as String;
      // Hand-typed, including the heading and its date: the section is
      // reproduced, not summarised, and the heading is what tells a reader
      // which version they are looking at.
      expect(
        body,
        startsWith('## 9.9.9 — 2026-01-01\n'
            '\n'
            '### Fixed\n'
            '\n'
            '- The fixture entry for nine.\n'),
        reason: 'the changelog section must come first -- it is the first '
            'thing a reader opens a release page for',
      );
      // And it is still the notes: the other three blocks did not move out.
      expect(body, contains('What this build has been run against'));
      expect(body, contains('signed with the community key'));
    });

    test('a version with no section is refused, and stdout stays empty', () {
      // Both halves. A script that prints the refusal and exits 0 publishes a
      // release with an error message in its body; one that exits 1 after
      // writing a partial body leaves the workflow's `> notes.md` holding it.
      final r = _notes('notes', tag: 'v7.7.7', changelog: fixture());
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty,
          reason: 'the publish step redirects stdout into the release body, '
              'so a refusal must write nothing there');
      expect(r.stderr, contains("has no '## 7.7.7' section"));
    });

    test('the section stops at the next heading, and starts at the right one',
        () {
      // Two boundaries, one on each side, and the tokens are hand-matched to
      // the fixture's own case. The first version of this test asserted
      // `isNot(contains('the old heading shape'))` against a fixture that says
      // `The old heading shape` — case-sensitive, so the check could not fail,
      // and removing awk's stop condition reddened nothing at all. Found by
      // mutating, in the pull request about claims outrunning checks.
      final r = _notes('notes', tag: 'v9.9.9', changelog: fixture());
      expect(r.exitCode, 0, reason: r.stderr as String);
      final body = r.stdout as String;

      // Below: the next section must not be swept in.
      expect(body, isNot(contains('OLDER')),
          reason: 'the scan must stop at the next `## ` heading');
      expect(body, isNot(contains('9.9.8')));

      // Above: `## Unreleased` is a heading like any other to a naive scan,
      // and the one heading whose contents are by definition not in the build.
      expect(body, isNot(contains('UNSHIPPED')),
          reason: 'an implementation that starts at the FIRST heading rather '
              'than the matching one ships the unreleased notes');

      // And the assertions above are only worth anything if the fixture puts
      // those tokens where they can be found. Proven, not assumed.
      final source = File(fixture()).readAsStringSync();
      expect(source, contains('OLDER'));
      expect(source, contains('UNSHIPPED'));
    });

    test('the old `+N` heading shape still matches', () {
      // `## 1.0.7+8 — 2026-08-31` is what the headings looked like before the
      // versionCode came out of the name, and half the file still reads that
      // way. A version comparison that did not drop `+N` would refuse every
      // one of them.
      final r = _notes('changelog', tag: 'v9.9.8', changelog: fixture());
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, startsWith('## 9.9.8+42 — 2025-12-31'));
    });

    test('a fenced example is not a section', () {
      // The failure this project has already had once, in the other gate:
      // `require_device_walk.sh` scanned a file whose own documentation
      // contained a worked example, written with a real version, and the
      // example cleared the gate for a release with no walk. A reviewer found
      // it; the fixtures did not. The same shape is available here — a
      // CHANGELOG that shows what an entry looks like — and it would both
      // clear the tag and publish the example, closing fence and all, as the
      // release body.
      final r = _notes('changelog', tag: 'v9.9.7', changelog: fixture());
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      // Pinned, because "it refused" and "it refused for THIS reason" are
      // different claims and only the second is the one in the test's name.
      // Its sibling below lacked this line, and replacing the refusal message
      // wholesale left that sibling green. (`isNot(contains('FENCED'))` used
      // to sit here too; after `isEmpty` it cannot fail on its own, so it read
      // as a second check and was not one.)
      expect(r.stderr, contains("has no '## 9.9.7' section"));
    });

    test('a commented-out heading is not a section', () {
      // The other half of what a reader does not see. An HTML comment is how a
      // draft entry gets parked in a Markdown file.
      final r = _notes('changelog', tag: 'v9.9.6', changelog: fixture());
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains("has no '## 9.9.6' section"),
          reason: 'without this the test cannot tell "refused because the '
              'heading is inside a comment" from "refused for any reason at '
              'all, including the script falling over" — proven: replacing '
              'the refusal message wholesale left this test green');
    });

    test('a comment that opens after a stray closer is still a comment', () {
      // A working defeat, found by review, of the shape `28d6cfe` was written
      // to close — moved from fences to comments. The detector asked
      // `$0 ~ /<!--/ && $0 !~ /-->/`, which is order blind: a `-->` anywhere
      // on the line, including BEFORE the `<!--`, said the line opened
      // nothing. The heading below is genuinely inside the comment, a reader
      // sees none of it, and the gate published it as the release body.
      //
      // `_proseOnly` in this same file already paired the delimiters off from
      // the left. The shell had its own weaker copy, which is this project's
      // most repeated defect.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '<span>--></span> <!--\n'
          '## 9.9.9 — 2026-01-01\n'
          '\n'
          '- HIDDEN: a reader sees none of this.\n'
          '-->\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- The real one.\n');
      final fake = _notes('changelog', tag: 'v9.9.9', changelog: f);
      expect(fake.exitCode, isNot(0));
      expect(fake.stdout, isEmpty);
      expect(fake.stderr, contains("has no '## 9.9.9' section"));
      final real = _notes('changelog', tag: 'v4.4.4', changelog: f);
      expect(real.exitCode, 0, reason: real.stderr as String);
      expect(real.stdout, startsWith('## 4.4.4 — 2026-04-04'));
    });

    test('an indented block is not a fence', () {
      // The error in the other direction, and the one a gate must not make
      // quietly: CommonMark allows at most three spaces before a fence, and
      // at four it is an indented code block. Accepting any indent let such a
      // block suppress the next REAL heading, so the gate refused a section
      // that was there and said it did not exist.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '    ```\n'
          '    an indented block, not a fence\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- The real one.\n');
      final r = _notes('changelog', tag: 'v4.4.4', changelog: f);
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, startsWith('## 4.4.4 — 2026-04-04'));
    });

    test('a fence line with trailing text does not close, and is refused',
        () {
      // This fixture used to assert the opposite, and it was right at the
      // time: closing on the marker alone, ``` <!-- ended the block and then
      // opened a comment that swallowed the rest of the file, so the test
      // pinned "the section below is still found". The Codex review then
      // showed the closing rule itself was wrong — a CommonMark closer
      // carries nothing but whitespace — and with that fixed the line is not
      // a closer at all. The fence runs to the end of the file, which is
      // exactly what a reader sees, and an unterminated fence is refused.
      //
      // The expectation moved because the rule underneath it moved. Kept
      // rather than deleted, because the input is the one that found the
      // original asymmetry and it should stay in the file.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 5.0.0 — 2026-05-05\n'
          '\n'
          '```\n'
          'a block\n'
          '``` <!--\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- Not reachable: the fence above never closes.\n');
      final r = _notes('changelog', tag: 'v4.4.4', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains('unterminated fenced block'));
    });

    test('a heading with nothing under it is not a section', () {
      // The message under the emptiness test says a release has to be able to
      // say what CHANGED, and the test could only ever mean "there is no
      // heading" — matching prints the heading, so a section with a heading
      // and nothing else was indistinguishable from a good one. It published
      // one lonely heading as the release body. Review found it by reading
      // what the check could return, not by reading the code.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 9.9.9 — 2026-01-01\n'
          '\n'
          '## 9.9.8 — 2025-12-31\n'
          '\n'
          '- The older one, which does have content.\n');
      final r = _notes('changelog', tag: 'v9.9.9', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains("has a '## 9.9.9' heading with nothing"));
    });

    test('an unterminated fence is refused rather than swept up', () {
      // The worst of the silent cases: an unterminated fence INSIDE the
      // wanted section swallowed every older entry below it into the release
      // body and exited 0. The workflow will not overwrite a release once
      // published, so that body would have been permanent.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 9.9.9 — 2026-01-01\n'
          '\n'
          '```\n'
          'a block nobody closed\n'
          '\n'
          '## 9.9.8 — 2025-12-31\n'
          '\n'
          '- SWEPT: an older entry that must not appear.\n');
      final r = _notes('changelog', tag: 'v9.9.9', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains('unterminated fenced block'));
    });

    test('two sections for one version are refused, not silently the first',
        () {
      // `require_device_walk.sh` has "one version, one attestation" for the
      // same reason: with two, the file does not say which one is the
      // release, and picking the first is a guess presented as an answer.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 9.9.9 — 2026-01-01\n'
          '\n'
          '- The first one.\n'
          '\n'
          '## 9.9.9 — 2025-06-06\n'
          '\n'
          '- The second one.\n');
      final r = _notes('changelog', tag: 'v9.9.9', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains("more than one '## 9.9.9' section"));
    });

    test('the version is matched exactly, not by prefix', () {
      // The real file has `## 1.0.1+2` below `## 1.0.12`, so a prefix match
      // hands back the wrong entry — and nothing pinned the difference:
      // changing `h == want` to `index(h, want) == 1` left every test green
      // until this one.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 1.0.12 — 2026-09-07\n'
          '\n'
          '- TWELVE: the newer entry.\n'
          '\n'
          '## 1.0.1+2 — 2026-01-01\n'
          '\n'
          '- ONE: the older entry, whose version is a prefix of the newer.\n');
      final r = _notes('changelog', tag: 'v1.0.1', changelog: f);
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, startsWith('## 1.0.1+2 — 2026-01-01'));
      expect(r.stdout, contains('ONE:'));
      expect(r.stdout, isNot(contains('TWELVE:')));
    });

    test('a CRLF file matches like any other', () {
      // `[[:space:]]` covers the `\r`, so the first token of a CRLF heading is
      // still the version. Nothing pinned it, and the first fixture written
      // for this did not either: with a date after the version there is a
      // plain space to cut at, so narrowing the class to a space changed
      // nothing and the mutation killed no test. The heading has to end at
      // the version for the `\r` to be the thing being stripped.
      final f = rawFixture('# Changelog\r\n'
          '\r\n'
          '## 9.9.9\r\n'
          '\r\n'
          '- CRLF: the entry.\r\n');
      final r = _notes('changelog', tag: 'v9.9.9', changelog: f);
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, contains('CRLF: the entry.'));
    });

    test('an extraction that fails refuses; one that succeeds is complete',
        () {
      // Codex found the shape, on the commit before the exit codes existed:
      // one byte awk could not decode made it die mid-file, and `notes`
      // exited 0 having printed a PARTIAL section followed by the rest of the
      // boilerplate. The publish step redirects stdout into the release body
      // and the workflow will not overwrite a published release, so that half
      // section would have been permanent.
      //
      // The invariant is "a failed extraction produces no body", NOT "an
      // invalid byte fails". Those are different claims and the first
      // version of this test asserted the second: it passed on macOS, where
      // BWK awk dies on `\xff`, and failed on CI, where gawk reads it
      // happily and the extraction simply succeeds. A test that pins one
      // platform's error behaviour is a test that goes red for being right.

      // Deterministic on both: awk cannot read the file at all.
      final unreadable = File('${tmp.path}/unreadable.md')
        ..writeAsStringSync('## 9.9.9\n\n- REAL\n');
      Process.runSync('chmod', ['000', unreadable.path]);
      addTearDown(() => Process.runSync('chmod', ['644', unreadable.path]));
      for (final mode in ['changelog', 'notes']) {
        final r = _notes(mode, tag: 'v9.9.9', changelog: unreadable.path);
        expect(r.exitCode, isNot(0), reason: '$mode must refuse');
        expect(r.stdout, isEmpty,
            reason: '$mode must not put a partial section in the body');
      }

      // And Codex's byte, asserted the way it is true on both awks: whichever
      // branch this awk takes, the body is never half a section.
      final bad = File('${tmp.path}/badbyte.md')
        ..writeAsBytesSync([
          ...'## 9.9.9\n\n- REAL\n'.codeUnits,
          0xFF,
          0x0A,
        ]);
      for (final mode in ['changelog', 'notes']) {
        // Byte encodings: the script may echo the offending byte on stderr
        // and Dart's own decoder throws on it, which would fail this test for
        // a reason that has nothing to do with the script.
        final r = Process.runSync(
          'bash',
          [_notesScript, mode],
          environment: {
            'TAG': 'v9.9.9',
            'APP_VERSION': '9.9.9+1',
            'APK_SIZE': '1M',
            'APK_SHA256': _sha,
            'APK_FINGERPRINT': _fingerprint,
            'CHANGELOG_PATH': bad.path,
          },
          stdoutEncoding: null,
          stderrEncoding: null,
        );
        final out = r.stdout as List<int>;
        if (r.exitCode != 0) {
          expect(out, isEmpty, reason: '$mode refused, so it must print nothing');
        } else {
          expect(String.fromCharCodes(out), contains('- REAL'),
              reason: '$mode accepted the file, so the section must be whole');
        }
      }
    });

    test('a closing fence carries nothing but whitespace', () {
      // CommonMark: a closer has no info string. Closing on the marker alone
      // let a line like ```` ```not-a-closing-fence ```` end the block, and
      // the `## <version>` inside the example became live. Found by the Codex
      // GitHub review, on top of the two closer-rule halves the Opus review
      // had already found unchecked.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '```markdown\n'
          '```not-a-closing-fence\n'
          '\n'
          '## 7.7.7 — 2026-07-07\n'
          '\n'
          '- FAKE: still inside the example.\n');
      final r = _notes('changelog', tag: 'v7.7.7', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
    });

    test('a backtick fence opener may not carry a backtick', () {
      // The other direction of the same rule, and a false REFUSAL rather than
      // a false accept: prose containing "``` this ` is not a fence" opened a
      // block that suppressed the next real heading, so the gate rejected a
      // release whose section was right there.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '``` this ` is not a fence\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- The real one.\n');
      final r = _notes('changelog', tag: 'v4.4.4', changelog: f);
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, startsWith('## 4.4.4 — 2026-04-04'));
    });

    test('a heading inside a raw HTML block is not a heading', () {
      // CommonMark HTML block type 1: `<pre>`, `<script>`, `<style>` and
      // `<textarea>` hold raw text to their close, so a `## ` line inside one
      // renders as preformatted text. Without this the gate accepted an HTML
      // sample as a section and published it — the fenced-example hole again,
      // in a third disguise.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '<pre>\n'
          '## 7.7.7 — 2026-07-07\n'
          '\n'
          '- FAKE: preformatted sample text.\n'
          '</pre>\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- The real one.\n');
      final fake = _notes('changelog', tag: 'v7.7.7', changelog: f);
      expect(fake.exitCode, isNot(0));
      expect(fake.stdout, isEmpty);
      final real = _notes('changelog', tag: 'v4.4.4', changelog: f);
      expect(real.exitCode, 0, reason: real.stderr as String);
      expect(real.stdout, startsWith('## 4.4.4 — 2026-04-04'));
    });

    test('a body of nothing but an HTML comment is not a body', () {
      // The heading-only rejection, wearing a hat: `<!-- TODO: describe this
      // release -->` has plenty of non-whitespace bytes and renders as
      // nothing at all, so the body check passed it. The check reads what a
      // reader sees now.
      final f = rawFixture('# Changelog\n'
          '\n'
          '## 7.7.7 — 2026-07-07\n'
          '\n'
          '<!-- TODO: describe this release -->\n'
          '\n'
          '## 4.4.4 — 2026-04-04\n'
          '\n'
          '- The real one.\n');
      final r = _notes('changelog', tag: 'v7.7.7', changelog: f);
      expect(r.exitCode, isNot(0));
      expect(r.stdout, isEmpty);
      expect(r.stderr, contains("has a '## 7.7.7' heading with nothing"));
    });

    test('a pre-release needs the section too, under its base version', () {
      // Deliberately unlike the device-walk gate, which exempts pre-releases.
      // The difference is what each one demands, not how many people it takes:
      // that gate wants a phone, a car and a walk through every changed
      // screen, which is exactly what a pre-release exists to go without.
      // Writing down what changed demands none of that, and a beta with no
      // notes is exactly as opaque to a reader as a full release with none.
      final r = _notes('changelog', tag: 'v9.9.9-beta.1', changelog: fixture());
      expect(r.exitCode, 0, reason: r.stderr as String);
      expect(r.stdout, startsWith('## 9.9.9 — 2026-01-01'));
    });
  });

  group('the version is declared once and agrees everywhere', () {
    test('CHANGELOG.md has a section for the version being shipped', () {
      // Nothing checked this, so it drifted: at the 1.0.12 bump the changelog's
      // newest released section was still 1.0.11, while README.md links to that
      // file as the version history. A reader following the link would have
      // been told the latest release was the previous one.
      final version = _pubspecVersion().name;
      // Through `_proseOnly`, because `release_notes.sh` now reads this file
      // as a reader does — a `## 2.0.0` inside a fenced example is not a
      // section to it. Left blind, this test would call that example the
      // newest section and report "the changelog leads with 2.0.0" while the
      // shell was behaving correctly: a true refusal with the wrong reason
      // printed, which is how a check teaches people to ignore it. One aware
      // reader and one blind one is the same defect as two blind ones.
      final sections = RegExp(r'^## (\d+\.\d+\.\d+)', multiLine: true)
          .allMatches(_proseOnly(File(_changelog).readAsStringSync()))
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
      // The SAME list the flag test uses. Two lists is how the gate came to
      // accept three forms while the notes accepted five.
      for (final tag in _prereleaseTags) {
        final f = fixture('# nothing here\n');
        final r = gate(tag, f);
        expect(r.exitCode, 0, reason: '$tag: ${r.stdout}');
        expect(r.stdout, contains('no device-walk entry required'));
      }
    });

    test('a full tag is a full tag to both scripts', () {
      // The other direction of the same disagreement: a tag the notes call
      // full must be one the gate actually interrogates.
      for (final tag in _fullTags) {
        expect(_flag(tag), 'full');
        final r = gate(tag, fixture('# nothing here\n'));
        expect(r.exitCode, 1,
            reason: '$tag claims a walk, so an empty file must refuse it');
        expect(r.stdout, isNot(contains('no device-walk entry required')));
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

    test('a near miss is named as a near miss', () {
      // Every one of these refuses, correctly. The problem is the message: it
      // prints the line to add, and the maintainer is looking at a line that
      // appears identical. The full-width colon is the realistic one — this
      // file is bilingual and a CJK input method produces U+FF1A.
      const nearMisses = {
        'full-width colon': 'Device walk attested： 1.0.12',
        'list bullet': '- Device walk attested: 1.0.12',
        'bold markers': '**Device walk attested:** 1.0.12',
        'leading v': 'Device walk attested: v1.0.12',
        'trailing period': 'Device walk attested: 1.0.12.',
        'two spaces': 'Device walk attested:  1.0.12',
      };
      nearMisses.forEach((label, line) {
        final r = gate('v1.0.12',
            fixture('## 2026-09-07 — 1.0.12 walk\n\n$line\n'));
        expect(r.exitCode, 1, reason: '$label must not count as an attestation');
        expect(r.stdout, contains('IS present and does not'),
            reason: '$label must be reported as a near miss, not as absence');
        expect(r.stdout, contains(line),
            reason: 'the offending line must be quoted back');
      });
    });

    test('absence is not reported as a near miss', () {
      final r = gate('v1.0.12', fixture('# nothing here at all\n'));
      expect(r.exitCode, 1);
      expect(r.stdout, isNot(contains('IS present')),
          reason: 'a file with no mention must not be described as having one');
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

    test('the gate and a Markdown-aware reading of the file agree', () {
      // The one that closes concealment, and the shape that makes it work: the
      // gate reads the file raw, this reads it as a person does, and the two
      // must name the same versions. Anything that is an attestation to grep
      // and an example to a reader shows up here as a disagreement.
      //
      // Reproduced before it was written. A fenced "here is what a finished
      // entry looks like" block naming 1.0.13 gave `require_device_walk.sh
      // v1.0.13` exit 0 and left all 38 tests green, because the two guards
      // meant to stop it used the same line-anchored regexes the gate does.
      final raw = File(_evidence).readAsStringSync();
      final attestation = RegExp(
          r'^Device walk attested: (\d+\.\d+\.\d+)\s*$',
          multiLine: true);
      Set<String> versionsIn(String text) =>
          attestation.allMatches(text).map((m) => m.group(1)!).toSet();

      final asGrepSeesIt = versionsIn(raw);
      final asAReaderSeesIt = versionsIn(_proseOnly(raw));
      expect(asAReaderSeesIt, equals(asGrepSeesIt),
          reason: 'these versions are attested to the gate but not to a '
              'reader: ${asGrepSeesIt.difference(asAReaderSeesIt)}. An '
              'attestation inside a fenced block or an HTML comment is an '
              'example or an invisible line, and the gate cannot tell.');
    });

    test('the prose reader actually removes what it claims to', () {
      // Without this, the test above passes by both sides being blind in the
      // same way -- which is exactly the failure it exists to fix.
      const fenced = 'intro\n\n```markdown\nDevice walk attested: 9.9.9\n```\n';
      const nested = 'intro\n\n````\n```\nDevice walk attested: 9.9.8\n```\n````\n';
      const commented = 'intro\n\n<!--\nDevice walk attested: 9.9.7\n-->\n';
      const inline = 'a <!-- Device walk attested: 9.9.6 --> b\n';
      const kept = '## 2026-09-07 — 1.0.0 walk\n\nDevice walk attested: 1.0.0\n';
      for (final concealed in [fenced, nested, commented, inline]) {
        expect(_proseOnly(concealed), isNot(contains('Device walk attested')),
            reason: 'concealed: ${concealed.replaceAll('\n', '\\n')}');
      }
      expect(_proseOnly(kept), contains('Device walk attested: 1.0.0'));
      // Line count preserved, so a line number reported against the stripped
      // text still points at the right line of the original.
      for (final s in [fenced, nested, commented, inline, kept]) {
        expect(_proseOnly(s).split('\n').length, s.split('\n').length);
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
          .allMatches(_proseOnly(File(_evidence).readAsStringSync()))) {
        counts.update(m.group(1)!, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts, isNotEmpty);
      counts.forEach((version, n) {
        expect(n, 1,
            reason: '$_evidence attests $version $n times; one of them is not '
                'a walk entry');
      });
    });

    test('every attestation belongs to a dated entry', () {
      // The gate reads one anchored line and nothing else, deliberately: a
      // shell script that parses Markdown is a state machine that can be wrong
      // in its own right. The consequence is that the line counts wherever it
      // appears, including inside a fenced code block or an HTML comment.
      //
      // That is how the gate's own documentation came to satisfy it. Counting
      // catches the duplicate case; this catches the other one -- an example
      // written for a version that has no entry at all, which is a single
      // occurrence and passes the count.
      //
      // The dated heading is corroboration here, NOT the attestation. Reading
      // the version out of a heading is exactly what let
      // `1.0.11 walk; 1.0.12 not installed` clear a full release, so the
      // heading is only ever asked "does an entry for this version exist",
      // never "was it walked".
      // Prose only, both sides: a dated heading inside a fenced example is
      // the example's own corroboration, not evidence a walk happened.
      final text = _proseOnly(File(_evidence).readAsStringSync());
      final headings = RegExp(r'^## \d{4}-\d{2}-\d{2}.*$', multiLine: true)
          .allMatches(text)
          .map((m) => m.group(0)!)
          .toList();
      expect(headings, isNotEmpty);
      final attested = RegExp(r'^Device walk attested: (\d+\.\d+\.\d+)\s*$',
              multiLine: true)
          .allMatches(text)
          .map((m) => m.group(1)!)
          .toSet();
      expect(attested, isNotEmpty);
      for (final v in attested) {
        final token = RegExp('(^|[^0-9.])${RegExp.escape(v)}([^0-9.]|\$)');
        expect(headings.any(token.hasMatch), isTrue,
            reason: '$_evidence attests $v but has no dated heading naming it, '
                'so the line is not attached to an entry someone can read');
      }
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
