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
# A DRY RUN IS NOT INERT. It opens a real Play edit to rehearse against, and
# opening an edit invalidates any edit that was already open -- so running this,
# dry run included, while a release upload is in flight kills that upload and
# takes its uploaded bundle with it. That is not a hypothetical: it happened on
# 2026-09-07 and versionCode 12 had to be re-uploaded whole.
# See docs/maintainers/release.md section 4.7(a).
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
command -v python3 >/dev/null || { echo "python3 is not on PATH" >&2; exit 2; }

# Said before the staging loop, not next to the create it warns about: by then
# the edit is already opening and the warning is a record rather than a chance
# to stop.
echo "This opens a real Play edit, dry run included. Do not run it beside a"
echo "release upload -- see the note at the top of this file."

STAGE=$(mktemp -d)

# The edit is discarded on EVERY exit that did not commit it, not just on a
# failed commit. `import-listings` and `import-images` run before the commit
# under `set -e`, so one rejected PNG or one network error used to leave the
# edit open, and leaked edits accumulate unseen.
#
# Note the direction: a leaked edit does NOT poison later ones. It is the other
# way round -- the next `edits create` invalidates it. Cleaning up here is
# hygiene, and it does not make this script safe to run beside a release upload;
# nothing can, because the create above is what does the damage.
EDIT=""
COMMITTED=0
cleanup() {
  rm -rf "$STAGE"
  if [ -n "$EDIT" ] && [ "$COMMITTED" = 0 ]; then
    # `--confirm` is required, and without it this exits 1 having done nothing.
    # The previous version piped that into `|| true`, so every dry run since
    # this script was written leaked its edit and said nothing. A cleanup that
    # cannot report its own failure is how the thing it cleans up accumulates.
    if ! why=$(gplay edits delete --package "$PACKAGE" --edit "$EDIT" --confirm 2>&1); then
      echo "warning: could not discard edit $EDIT. gplay said:" >&2
      printf '%s\n' "$why" >&2
      echo "It is orphaned, not dangerous -- the next edits create invalidates" >&2
      echo "it. Clean it up with:" >&2
      echo "  gplay edits delete --package $PACKAGE --edit $EDIT --confirm" >&2
    fi
  fi
}
trap cleanup EXIT

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

# stderr goes to a file rather than into `created`: folding it in would let a
# harmless warning break the parse of a response that was perfectly good.
if ! created=$(gplay edits create --package "$PACKAGE" 2>"$STAGE/create.err"); then
  echo "error: could not open a Play edit. gplay said:" >&2
  cat "$STAGE/create.err" >&2
  echo "If Play accepted the insert before this failed, an edit may be open" >&2
  echo "and this script never learned its id. Check Play Console before the" >&2
  echo "next upload." >&2
  exit 1
fi
# The edit now exists in Play whatever happens next. If the id cannot be read
# out of the response -- a gplay upgrade changing its shape, or auth answering
# with an HTML error page -- then it exists and cannot be named, so the trap
# cannot discard it. Splitting the pipeline does not fix that by itself: EDIT is
# still assigned from the parse, so a parse failure still leaves it empty. What
# the split buys is the raw response, which is the only thing that lets a person
# go and find the edit. So say so and stop, loudly.
# `["id"]` is not enough. On `{"id": null}` it does not raise -- Python prints
# the string `None` and exits 0, so the script would run on with EDIT=None,
# print a line indistinguishable from a real edit id, and then hand the operator
# a delete command that cannot work against an edit that really is open. A
# plausible wrong id is worse than none, which is this repository's whole point.
# So the id must be a non-empty string; null, a number and a missing key all
# fail closed together.
if ! EDIT=$(printf '%s' "$created" | python3 -c \
    'import sys,json;i=json.load(sys.stdin).get("id");print(i) if isinstance(i,str) and i else sys.exit(1)' \
    2>/dev/null) || [ -z "$EDIT" ]; then
  echo "error: opened a Play edit but could not read its id from:" >&2
  printf '%s\n' "$created" >&2
  echo "That edit is open and unnamed. Find it in Play Console and delete it" >&2
  echo "before the next upload." >&2
  exit 1
fi
echo "edit $EDIT"

# shellcheck disable=SC2086
gplay sync import-listings --package "$PACKAGE" --edit "$EDIT" --dir "$STAGE" $DRY
# shellcheck disable=SC2086
gplay sync import-images --package "$PACKAGE" --edit "$EDIT" --dir "$STAGE" $DRY

if [ "$APPLY" = 1 ]; then
  # Cleanup lives in the EXIT trap above, which covers the import steps too.
  # Not `if ! cmd; then status=$?` -- inside that branch $? is the *negated*
  # status, i.e. 0, and the script would exit successfully after failing.
  set +e
  commit_out=$(gplay edits commit --package "$PACKAGE" --edit "$EDIT" 2>&1)
  status=$?
  set -e
  printf '%s\n' "$commit_out"
  if [ "$status" -ne 0 ]; then
    echo >&2
    echo "The commit failed; nothing reached the store. Discarding the edit." >&2
    # Only when the error really is the permission one. An expired edit answers
    # 400 and a dropped connection answers nothing; printing a store-presence
    # diagnosis for those states a cause that was never established, and it is
    # the day this permission is granted that the paragraph starts lying to
    # everyone who hits an unrelated failure.
    case "$commit_out" in
      *403*|*"does not have permission"*)
        cat >&2 <<'DIAG'

The pictures and text were accepted into the edit and only the commit was
refused -- the service account can publish releases but cannot write the store
listing. That is a Play Console setting, not something this script can fix:

  Play Console -> Users and permissions -> the service account
  -> grant this app's store-presence permission

Bisected on 2026-09-07: an empty edit commits, a bundle+track edit commits, and
BOTH a new-locale text-only edit and an existing-locale images-only edit are
refused. So it is store presence as a whole, not adding a language.
See docs/maintainers/release.md section 4.7(c).
DIAG
        ;;
    esac
    exit "$status"
  fi
  COMMITTED=1
  echo "committed. Check the listing in Play Console before it reaches anyone."
else
  echo "dry run only. Nothing was written. Re-run with --apply."
fi
