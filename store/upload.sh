#!/usr/bin/env bash
# Upload the store listing — text from store/metadata/, pictures from store/<locale>/.
#
# Play's own CLI wants one FastLane-shaped tree with the images copied inside it.
# This repo keeps the pictures in store/<locale>/ instead, because they are also
# what the two READMEs hotlink, and a second copy of five 1 MB PNGs per locale is
# two copies that drift. So the tree is assembled in a temp directory at upload
# time and thrown away afterwards. Nothing generated is committed.
#
# Run it from the repository root. Default is a dry run; pass --apply to write.
#
#   store/upload.sh                  # show what would change
#   store/upload.sh --apply          # do it
#   store/upload.sh --apply en-US    # one locale
#
# It never touches a release track. Listings and images only — the APK/AAB goes
# up through its own path, and keeping the two apart means a copy fix cannot
# accidentally promote a build.

set -euo pipefail

PACKAGE=com.cbstudio.telltale
APPLY=0
ONLY_LOCALE=""

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) ONLY_LOCALE="$arg" ;;
  esac
done

test -d store/metadata || { echo "run this from the repository root" >&2; exit 2; }
command -v gplay >/dev/null || { echo "gplay is not on PATH" >&2; exit 2; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

LOCALES=(en-US zh-TW)
[ -n "$ONLY_LOCALE" ] && LOCALES=("$ONLY_LOCALE")

for locale in "${LOCALES[@]}"; do
  src="store/metadata/$locale"
  test -d "$src" || { echo "no metadata for $locale" >&2; exit 1; }
  dst="$STAGE/$locale"
  mkdir -p "$dst/images/phoneScreenshots"
  cp "$src"/*.txt "$dst/"
  [ -d "$src/changelogs" ] && cp -R "$src/changelogs" "$dst/"

  # Screenshots, in the order Play shows them. Numbered filenames sort correctly
  # and the numbering deliberately skips 04 — see store/README.md.
  for shot in store/"$locale"/0*.png; do
    cp "$shot" "$dst/images/phoneScreenshots/$(basename "$shot")"
  done
  cp "store/$locale/feature-1024x500.png" "$dst/images/featureGraphic.png"

  # Shared, wordless, and the same file for every locale.
  cp store/icon-512.png "$dst/images/icon.png"

  texts=$(find "$dst" -maxdepth 1 -name '*.txt' | wc -l | tr -d ' ')
  shots=$(find "$dst/images/phoneScreenshots" -name '*.png' | wc -l | tr -d ' ')
  echo "staged $locale: $texts text files, $shots screenshots"
done

DRY=--dry-run
[ "$APPLY" = 1 ] && DRY=""

EDIT=$(gplay edits create --package "$PACKAGE" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
echo "edit $EDIT"

# shellcheck disable=SC2086
gplay sync import-listings --package "$PACKAGE" --edit "$EDIT" --dir "$STAGE" $DRY
# shellcheck disable=SC2086
gplay sync import-images --package "$PACKAGE" --edit "$EDIT" --dir "$STAGE" $DRY

if [ "$APPLY" = 1 ]; then
  gplay edits commit --package "$PACKAGE" --edit "$EDIT"
  echo "committed. Check the listing in Play Console before it reaches anyone."
else
  gplay edits delete --package "$PACKAGE" --edit "$EDIT" >/dev/null 2>&1 || true
  echo "dry run only. Nothing was written. Re-run with --apply."
fi
