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

# Two things are checked, and both have bitten a version-matching guard before.
#
# The heading must be *dated*. This file also carries undated section headings
# ("## The three links exercised", "## Round 9, with the wire visible") that
# describe rig work rather than a walk of a shipped version. Accepting any
# heading would let a prose section satisfy a release gate.
#
# The version must be a whole token. A substring match reads 1.0.12 as present
# in "1.0.121", and reads 1.0.1 as present in every 1.0.1x entry the file has
# -- which is the exact shape of a guard that passes on the release where it
# matters. The character classes on both sides are what make it a token; the
# escaped dots are what stop "1.0.12" from matching "1a0b12".
escaped=$(printf '%s' "$version" | sed 's/\./\\./g')
dated='^## [0-9]{4}-[0-9]{2}-[0-9]{2}'
token="(^|[^0-9.])${escaped}([^0-9.]|$)"

if grep -E "$dated" "$EVIDENCE" | grep -qE "$token"; then
  echo "device walk recorded for $version in $EVIDENCE"
  exit 0
fi

echo "::error::Full release $TAG claims a device walk, but $EVIDENCE has no"
echo "::error::dated heading naming $version. Either walk a release build of"
echo "::error::this commit and record it there, or cut the tag with a"
echo "::error::pre-release suffix (${TAG}-beta.1), which claims no walk."
exit 1
