#!/usr/bin/env bash
#
# The gate that makes "full release" mean something a reader can check.
#
# A release tag with no SemVer pre-release suffix claims, in its notes, that a
# release build of this VERSION was walked on a phone. Before this script that
# claim was derived from the tag string alone: the flag validated nothing, so
# the sentence was true only when the person cutting the tag happened to have
# done the walk. A claim that cannot be wrong is not a claim.
#
# So the flag now consumes an attestation: one line, in one shape, anywhere in
# docs/verification/device-verification.md.
#
#     Device walk attested: 1.0.12
#
# A full-release tag is refused unless that line is there. The maintainer
# clears it by committing the evidence entry before tagging -- which
# docs/maintainers/release.md step 3 requires and names -- and nobody else has
# to be available for it. That distinction is the whole point: the previous
# rule ("never run against a real car") needed a second adapter and another
# vehicle, so it could never be cleared, so every release for nine days was a
# pre-release and GitHub's Latest badge sat on a build from weeks earlier.
#
# This header said "a dated heading naming the version" until 2026-09-07,
# describing the design this replaced while the body described the one that
# shipped. Two contradictory accounts in one file, and the header is the one a
# reader hits first.
#
# Usage:
#   require_device_walk.sh <tag> [evidence-file]
#
# Exit 0 when the tag is a pre-release (nothing to attest) or the entry exists.
# Exit 1 with a GitHub Actions ::error:: annotation otherwise.

set -euo pipefail

TAG=${1:?usage: require_device_walk.sh <tag> [evidence-file]}
EVIDENCE=${2:-docs/verification/device-verification.md}

# SemVer: everything after the first hyphen is a pre-release identifier.
# v1.0.1 claims the walk; v1.0.1-beta.1 explicitly does not.
case "$TAG" in
  *-*)
    echo "pre-release tag $TAG: no device-walk entry required"
    exit 0
    ;;
esac

tag_re='^v([0-9]+\.[0-9]+\.[0-9]+)$'
if [[ ! "$TAG" =~ $tag_re ]]; then
  echo "::error::Not a release tag: $TAG"
  exit 1
fi
version=${BASH_REMATCH[1]}

if [ ! -f "$EVIDENCE" ]; then
  echo "::error::$EVIDENCE does not exist, so no walk can be recorded in it"
  exit 1
fi
# Checked separately from existence because the `|| true` below cannot tell a
# grep that found nothing (exit 1) from a grep that could not read (exit 2).
# Both refuse -- the gate fails closed either way -- but a maintainer told
# "there is no entry for 1.0.12" when the entry is right there and the file is
# merely unreadable will go and write a second one.
if [ ! -r "$EVIDENCE" ]; then
  echo "::error::$EVIDENCE exists but cannot be read"
  exit 1
fi

# The attestation is one line, in one shape, and the version is the whole of
# what follows the colon:
#
#     Device walk attested: 1.0.12
#
# Searching a dated heading for the version anywhere in it was the first
# attempt, and a reviewer defeated it with inputs nobody has to be dishonest to
# write. All three of these cleared the gate for 1.0.12:
#
#     ## 2026-09-07 — 1.0.11 walk; 1.0.12 not installed
#     ## 2026-09-07 — x1.0.12oops
#     ## 2026-09-07 — 1.0.12-rc.1 planned, no walk
#
# A sentence that mentions a version is not a sentence that attests it, and the
# first of those actively denies the thing the gate read it as confirming. A
# prose heading cannot carry a claim a machine reads; a field can. This line
# takes a deliberate keystroke and cannot appear inside a sentence that means
# something else.
#
# The version must still be a whole token even here: anchored at both ends, so
# "1.0.121" is not 1.0.12 and a trailing "(partial)" does not count. The escaped
# dots are what stop "1.0.12" from matching "1a0b12".
escaped=$(printf '%s' "$version" | sed 's/\./\\./g')
attestation="^Device walk attested: ${escaped}[[:space:]]*$"

# Matched with grep -q against the file directly -- no pipeline. Piping into
# `grep -q` is a size-dependent false refusal: it exits on its first match, the
# upstream process takes SIGPIPE, and `set -o pipefail` then reports the whole
# pipeline as failed, so a line that IS present is read as absent. Reproduced
# with a 20,000-line file; today's fits the pipe buffer and passes, and this
# file gains an entry every release.
#
# `[ -r ]` is not enough on every host. Git-for-Windows bash reports an NTFS
# file as readable after an ACL deny that Dart and awk both honour, then
# grep's "cannot open" (exit 2) used to fall through as "has no line" — an
# unreadable attestation file named as a missing walk. Capture the status
# rather than treating every non-zero as absence.
set +e
grep -qE "$attestation" "$EVIDENCE"
grep_status=$?
set -e
if [ "$grep_status" -eq 0 ]; then
  echo "device walk attested for $version in $EVIDENCE"
  exit 0
fi
if [ "$grep_status" -ge 2 ]; then
  echo "::error::$EVIDENCE exists but cannot be read"
  exit 1
fi

echo "::error::Full release $TAG claims a device walk, but $EVIDENCE has no"
echo "::error::line reading exactly:"
echo "::error::"
echo "::error::    Device walk attested: $version"
echo "::error::"
echo "::error::Walk a release build, record what you saw, add that line, or cut"
echo "::error::the tag with a pre-release suffix (${TAG}-beta.1), which claims"
echo "::error::no walk."

# A near miss is worth naming. The shape is exact, and this file is bilingual:
# a CJK input method produces a full-width colon (U+FF1A) that looks identical
# next to the required line, and so do a leading "- ", surrounding "**", a
# no-break space, a "v" before the number and a trailing period. Every one of
# those refuses -- correctly, the gate fails closed -- but a refusal that
# prints the line you believe you already wrote is a confusing half hour. Say
# which of the two situations this is.
if grep -qi 'device walk attested' "$EVIDENCE"; then
  echo "::error::"
  echo "::error::A line mentioning \"Device walk attested\" IS present and does not"
  echo "::error::match. The shape is exact: nothing before it on the line, an"
  echo "::error::ASCII colon, one ASCII space, then the version and nothing else."
  echo "::error::Full-width colons, list bullets, bold markers, a leading v and a"
  echo "::error::trailing period all read as different lines. Present:"
  grep -in 'device walk attested' "$EVIDENCE" | sed 's/^/::error::    /'
fi
exit 1
