#!/usr/bin/env bash
# Sync Play store/ assets into fastlane/metadata/android/ for F-Droid.
# store/ remains the source of truth for Play tooling.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STORE="$ROOT/store"
FASTLANE="$ROOT/fastlane/metadata/android"

sync_locale() {
  local loc="$1"
  local dest="$FASTLANE/$loc"
  mkdir -p "$dest/changelogs" "$dest/images/phoneScreenshots"

  cp "$STORE/metadata/$loc/title.txt" "$dest/title.txt"
  cp "$STORE/metadata/$loc/short_description.txt" "$dest/short_description.txt"
  cp "$STORE/metadata/$loc/full_description.txt" "$dest/full_description.txt"
  if [[ -f "$STORE/metadata/$loc/video.txt" ]]; then
    cp "$STORE/metadata/$loc/video.txt" "$dest/video.txt"
  fi

  if [[ -d "$STORE/metadata/$loc/changelogs" ]]; then
    cp "$STORE/metadata/$loc/changelogs/"*.txt "$dest/changelogs/"
  fi

  cp "$STORE/icon-512.png" "$dest/images/icon.png"
  cp "$STORE/$loc/feature-1024x500.png" "$dest/images/featureGraphic.png"

  # store uses 01,02,03,05,06 (04 missing); Fastlane wants 1.png … N.png
  local n=1
  for shot in 01-connect.png 02-dashboard.png 03-dtc-freeze.png \
              05-performance.png 06-skins.png; do
    cp "$STORE/$loc/$shot" "$dest/images/phoneScreenshots/${n}.png"
    n=$((n + 1))
  done
}

sync_locale en-US
sync_locale zh-TW

echo "Synced store/ → fastlane/metadata/android/{en-US,zh-TW}"
