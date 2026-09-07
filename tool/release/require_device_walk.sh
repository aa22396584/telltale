#!/usr/bin/env bash
#
# The gate that makes "full release" mean something a reader can check.
#
# A release tag with no SemVer pre-release suffix claims, in its notes, that a
# release build of this commit was walked on a phone. Before this script that
# claim was derived from the tag string alone: the flag validated nothing, so
# the sentence was true only when the person cutting the tag happened to have
# done the walk. A claim that cannot be wrong is not a claim.
#
# So the flag now consumes an attestation. The walk is recorded in
# docs/verification/device-verification.md as a dated heading naming the
# version, and a full-release tag is refused unless that heading exists. The
# maintainer clears it by committing the evidence entry before tagging -- which
# the project's release checklist already requires -- and nobody else has to be
# available for it. That distinction is the whole point: the previous rule
# ("never run against a real car") needed a second adapter and another vehicle,
# so it could never be cleared, so every release for nine days was a
# pre-release and GitHub's Latest badge sat on a build from weeks earlier.
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
if grep -qE "$attestation" "$EVIDENCE"; then
  echo "device walk attested for $version in $EVIDENCE"
  exit 0
fi

echo "::error::Full release $TAG claims a device walk, but $EVIDENCE has no"
echo "::error::line reading exactly:"
echo "::error::"
echo "::error::    Device walk attested: $version"
echo "::error::"
echo "::error::Walk a release build, record what you saw, add that line, or cut"
echo "::error::the tag with a pre-release suffix (${TAG}-beta.1), which claims"
echo "::error::no walk."
exit 1
