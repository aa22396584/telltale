#!/usr/bin/env bash
#
# Composes the GitHub release notes, and decides the pre-release flag from the
# same tag it writes the prose from.
#
# It is a script rather than a heredoc inside the workflow for one reason this
# week supplied twice: two copies of a rule drift, and the weaker copy is the
# one that stays green. The notes made a claim about the walk, the workflow
# decided the flag, and the docs described both -- three places, and they
# disagreed. Here the flag and the sentence come from one `is_prerelease`, so a
# release cannot say "walked" while the flag says otherwise, and
# `test/release_notes_contract_test.dart` executes *this file* rather than a
# reimplementation of it.
#
# Usage:
#   release_notes.sh notes   # the release body, on stdout
#   release_notes.sh flag    # "prerelease" or "full"
#
# Environment (notes mode): TAG APP_VERSION APK_SIZE APK_SHA256 APK_FINGERPRINT

set -euo pipefail

MODE=${1:-notes}
: "${TAG:?TAG is required}"

# Overridable so the contract test can run the real extraction against a
# fixture instead of the repository's own CHANGELOG -- a test that asserted
# something about the real file would go red at the next release for being
# right.
CHANGELOG_PATH=${CHANGELOG_PATH:-CHANGELOG.md}

# SemVer: everything after the first hyphen is a pre-release identifier.
# v1.0.1 is a release; v1.0.1-beta.1 is not.
is_prerelease() {
  case "$TAG" in
    *-*) return 0 ;;
    *)   return 1 ;;
  esac
}

# The version the CHANGELOG heading has to name: the tag without its `v` and
# without any pre-release identifier, so `v1.0.13-beta.1` looks for `1.0.13`.
version_from_tag() {
  local v=${TAG#v}
  printf '%s' "${v%%-*}"
}

# The `## <version>` section of the CHANGELOG, heading included, or nothing.
#
# Parsed rather than matched with a built regex: the heading is `## 1.0.12 —
# 2026-09-07` today and was `## 1.0.7+8 — 2026-08-31` before the versionCode
# came out of the name, so the first token has to lose an optional `+N` before
# it is compared. Building that comparison as a dynamic regex means escaping a
# `+` and a `.` through the shell into awk, differently on the two awks this
# runs under; comparing strings needs no escaping and reads the same on both.
#
# `## Unreleased` is a heading like any other and simply does not match, which
# is the behaviour that matters: an unreleased note must never ship as if it
# described the build.
changelog_section() {
  awk -v want="$1" '
    # Does this line leave an HTML comment OPEN at its end? Pair off every
    # complete `<!-- ... -->` from the left and answer about what is left.
    #
    # `$0 ~ /<!--/ && $0 !~ /-->/` was the first version and it is order
    # blind: any `-->` anywhere on the line, INCLUDING one that appears before
    # the `<!--`, said "this line opens nothing". A reviewer turned that into
    # a working defeat -- `<span>--></span> <!--` followed by a heading -- and
    # the gate published a hidden example as the release body. The correct
    # implementation was already in this repository, in `_proseOnly()` in
    # `test/release_notes_contract_test.dart`; the shell just had its own,
    # weaker one. Two parsers of the same file is the recurring defect here.
    function opens_comment(s,   i, j) {
      while (1) {
        i = index(s, "<!--")
        if (i == 0) return 0
        s = substr(s, i + 4)
        j = index(s, "-->")
        if (j == 0) return 1
        s = substr(s, j + 3)
      }
    }
    # A `## 1.0.13` inside a fenced block or an HTML comment is an EXAMPLE or
    # an invisible line, and a scan that cannot tell publishes it as the
    # release body -- and clears the gate for a version with no section. Not
    # hypothetical: the device-walk gate shipped with exactly this hole, where
    # the fenced example in the file it scanned was a live attestation. So a
    # heading only counts where a reader sees one.
    {
      is_heading = 0
      is_fence = 0
      if (!incomment) {
        # CommonMark allows at most three spaces of indent before a fence; at
        # four it is an indented code block and not a fence at all. `^[ \t]*`
        # accepted any indent, so an indented block suppressed the next REAL
        # heading and the gate refused a section that was there.
        ind = 0
        while (substr($0, ind + 1, 1) == " ") ind++
        if (ind <= 3 && match(substr($0, ind + 1), /^(```+|~~~+)/)) {
          m = substr($0, ind + 1, RLENGTH)
          c = substr(m, 1, 1)
          n = length(m)
          rest = substr($0, ind + 1 + RLENGTH)
          # The closer is the same character as the opener and at least as
          # long. Both halves are checked by their own fixture; weakening
          # either one left every test green until they were written.
          if (fence == "") {
            # A backtick opener may not carry a backtick in its info string.
            # Without this, prose like "``` this ` is not a fence" opened a
            # block that suppressed the next real heading, and the gate
            # refused a release that was there.
            if (c != "`" || index(rest, "`") == 0) { fence = c; flen = n; is_fence = 1 }
          } else if (c == fence && n >= flen && rest ~ /^[ \t]*$/) {
            # A CLOSING fence carries nothing but whitespace. Closing on the
            # marker alone let ```` ```not-a-closing-fence ```` end the block,
            # which makes the next `## <version>` inside the example live.
            fence = ""; flen = 0; is_fence = 1
          }
        }
      }
      # A fence delimiter line is a delimiter in both directions and nothing
      # else. The case that motivated the closing half no longer reaches it:
      # ``` followed by `<!--` used to close the block and then open a comment
      # that swallowed the rest of the file, and a closer carrying trailing
      # text is not a closer at all now, one branch above. Removing
      # `is_fence = 1` from the closing arm reddens nothing — measured, not
      # assumed — so it is symmetry rather than a guard, and saying otherwise
      # would be one more claim with no check under it.
      #
      # Known limit, in the safe direction: a literal `<!--` in prose or in
      # inline code, with no `-->`, opens comment mode here and the file is
      # then refused as having an unterminated comment. Telling that apart
      # from a real comment needs inline-code parsing, which this does not
      # do. It refuses with a message naming the reason; it does not publish.
      if (!is_fence && fence == "") {
        if (incomment) {
          j = index($0, "-->")
          if (j > 0) incomment = opens_comment(substr($0, j + 3))
        } else if (inraw) {
          # CommonMark HTML block type 1: `<pre>`, `<script>`, `<style>` and
          # `<textarea>` hold raw text to the matching close, so a line
          # beginning `## ` inside one renders as preformatted text and is not
          # a heading. Without this the gate accepted an HTML sample as a
          # section and published it.
          if (tolower($0) ~ /<\/(pre|script|style|textarea)>/) inraw = 0
        } else if (tolower($0) ~ /^[ ]{0,3}<(pre|script|style|textarea)[ \t>]/) {
          inraw = (tolower($0) ~ /<\/(pre|script|style|textarea)>/) ? 0 : 1
        } else {
          if ($0 ~ /^## /) is_heading = 1
          incomment = opens_comment($0)
        }
      }
    }
    # The fence lines themselves are still part of a section BODY, so all of
    # the above suppresses the heading interpretation and not the printing.
    is_heading {
      if (inside) inside = 0
      h = substr($0, 4)
      sub(/[[:space:]].*$/, "", h)
      sub(/\+[0-9]+$/, "", h)
      # `h == want`, not a prefix test: `## 1.0.1+2` sits below `## 1.0.12` in
      # the real file, and a prefix match hands back the wrong entry.
      if (h == want) { seen++; inside = 1; print }
      next
    }
    inside { print }
    # Scanning continues past the section rather than exiting, so these two
    # can be answered. Both used to be silent, and one of them was worse than
    # silent: an unterminated fence INSIDE the wanted section swept every
    # older entry below it into the release body, exit 0, and the workflow
    # will not overwrite a release once published.
    END {
      if (fence != "" || incomment || inraw) exit 3
      if (seen > 1) exit 4
    }
  ' "$CHANGELOG_PATH"
}

# Fail closed, and say which file and which heading. A release whose notes
# cannot say what changed is the thing this subcommand exists to stop, so it
# refuses rather than printing a placeholder -- and it prints NOTHING on
# stdout when it refuses, because the publish step redirects stdout into the
# release body.
require_changelog() {
  local want section rc visible
  want=$(version_from_tag)
  rc=0
  section=$(changelog_section "$want") || rc=$?
  case "$rc" in
    0) ;;
    3)
      echo "::error::$CHANGELOG_PATH has an unterminated fenced block or HTML" >&2
      echo "::error::comment. Everything after it is invisible to a reader and" >&2
      echo "::error::would be swept into the release body. Close it and re-tag." >&2
      return 1
      ;;
    4)
      echo "::error::$CHANGELOG_PATH has more than one '## $want' section." >&2
      echo "::error::Which one is the release? Merge them and re-tag." >&2
      return 1
      ;;
    *)
      echo "::error::could not read $CHANGELOG_PATH (exit $rc)" >&2
      return 1
      ;;
  esac

  if [ -z "$(printf '%s' "$section" | tr -d '[:space:]')" ]; then
    echo "::error::$CHANGELOG_PATH has no '## $want' section." >&2
    echo "::error::A release has to be able to say what changed. Add the" >&2
    echo "::error::section (an '## Unreleased' heading does not count, and" >&2
    echo "::error::neither does a heading inside a fenced block or an HTML" >&2
    echo "::error::comment) and re-tag." >&2
    return 1
  fi

  # The heading is not the answer. Matching prints the heading line, so the
  # emptiness test above can only ever mean "no section at all" -- while the
  # message under it, and `docs/maintainers/release.md`, both say a release
  # has to say what CHANGED. A bare `## 1.0.13 — 2026-09-08` with the next
  # heading straight after it satisfied the first and not the second, and
  # published one lonely heading as the release body.
  # Comments stripped first: a body of `<!-- TODO: describe this release -->`
  # has plenty of non-whitespace bytes and renders as nothing at all, which is
  # the heading-only failure this check was added to stop, wearing a hat.
  visible=$(printf '%s\n' "$section" | tail -n +2 | awk '
    function strip(line,   out, i, j) {
      out = ""
      while (length(line) > 0) {
        if (incomment) {
          j = index(line, "-->")
          if (j == 0) return out
          line = substr(line, j + 3); incomment = 0
        } else {
          i = index(line, "<!--")
          if (i == 0) return out line
          out = out substr(line, 1, i - 1)
          line = substr(line, i + 4); incomment = 1
        }
      }
      return out
    }
    { print strip($0) }
  ')
  if [ -z "$(printf '%s' "$visible" | tr -d '[:space:]')" ]; then
    echo "::error::$CHANGELOG_PATH has a '## $want' heading with nothing" >&2
    echo "::error::under it. A heading is not a description of what changed." >&2
    return 1
  fi

  printf '%s\n' "$section"
}

case "$MODE" in
  flag)
    if is_prerelease; then echo prerelease; else echo full; fi
    exit 0
    ;;
  changelog)
    # The same extraction the notes use, on its own, so the workflow can run it
    # BEFORE the forty-minute build instead of discovering the gap at publish.
    require_changelog
    exit $?
    ;;
  notes) ;;
  *)
    echo "usage: release_notes.sh notes|flag|changelog" >&2
    exit 2
    ;;
esac

: "${APP_VERSION:?APP_VERSION is required}"
: "${APK_SIZE:?APK_SIZE is required}"
: "${APK_SHA256:?APK_SHA256 is required}"
: "${APK_FINGERPRINT:?APK_FINGERPRINT is required}"

# What changed, first, because it is the first thing a reader wants and it was
# missing entirely from every release before v1.0.13. The three blocks below
# this one all answer "what is this build NOT" -- who signed it, how far the
# walk went, what has never been driven -- and they were written during the
# argument about the pre-release flag, when nobody asked what a reader opens a
# release page to find out. The answer was in `CHANGELOG.md` the whole time.
#
# English only, and said so, because `CHANGELOG.md` is the single source and
# translating it here would put a second wording of the same claims in a place
# no reviewer reads. The store listings carry the translated version.
#
# On its own line with an explicit `|| exit`, not inlined into `printf`: a
# failing command substitution inside an argument leaves the exit status of
# `printf`, so `set -e` would not fire and the release would publish with the
# refusal on stderr and an empty section in the body. That is the same
# fail-open shape the release flag had when it was inlined into an `if`.
changelog_body=$(require_changelog) || exit 1
printf '%s\n\n' "$changelog_body"
cat <<'CHANGELOG_NOTE'
The section above is this release's entry from `CHANGELOG.md`, in English.
繁體中文版本在 Google Play 的「最新動態」。

---

CHANGELOG_NOTE

# Exactly one of these two prints, and each states only what its own gate
# checks -- which took three passes to get right, each time because the prose
# claimed one notch more than the check.
#
# "This exact binary has not been walked on a phone" was the first: its
# opposite, the claim a full release then made, was false, because what gets
# walked is a locally signed build and what gets published is CI's. "A release
# build of this commit was walked" was the second: the gate reads an
# attestation naming a *version*, and nothing stops the code changing under an
# unchanged version. So the full-release paragraph now names both gaps rather
# than closing over them. A release note is the wrong place to be approximately
# right.
#
# The pre-release paragraph said "no walk of this version is recorded", which
# the pre-release path never checks -- it returns before reading the file, so
# re-cutting a beta after a walk printed a statement the record contradicted.
# It now says what is actually true of that path: it does not ask.
if is_prerelease; then
  cat <<'PRE'
> **Pre-release.** This tag neither requires nor attests a recorded device
> walk. A full release does: CI refuses a full-release tag whose version has no
> walk recorded in `docs/verification/device-verification.md`.
>
> **預發行版本。** 這個 tag 既不要求、也不宣稱有實機走查紀錄。正式版才有：CI 會
> 拒絕一個在 `docs/verification/device-verification.md` 裡找不到該版本走查紀錄的
> 正式版 tag。

PRE
else
  cat <<'FULL'
> **Full release.** `docs/verification/device-verification.md` records a device
> walk for this version — a release build installed on a phone and walked
> through — and CI refuses a full-release tag without that record.
>
> Two things it does not claim. It attests the **version**, not the commit:
> nothing checks that the code walked is byte-for-byte the code tagged. And the
> walked build is not this APK — that one is signed locally, while the APK below
> is CI's, signed with the community key.
>
> **正式版。** `docs/verification/device-verification.md` 裡有這個版本的實機走查
> 紀錄 —— 一份裝上手機、逐個畫面走過的 release build —— 沒有那筆紀錄，CI 會拒絕
> 正式版 tag。
>
> 兩件它沒有宣稱的事。它佐證的是**版本**，不是 commit：沒有任何檢查確認走查的
> 程式碼與打 tag 的程式碼逐位元組相同。而且走查的那一份不是下面這份 APK ——
> 那一份是本機簽的，下面這份是 CI 用社群金鑰簽的。

FULL
fi

# The evidence boundary is NOT tied to the pre-release flag, and this is the
# second thing that flag was silently doing. It used to carry both "not ready to
# use" and "never run against a real car", so the only way to publish a release
# people could find was to delete the honest paragraph. Every release since
# v1.0.6 was therefore marked pre-release, GitHub kept the Latest badge on a
# build from weeks earlier, and the same commit was already on Play production
# at 100%. The boundary is true of every build and now prints on every build.
cat <<'BOUNDARY'
> **What this build has been run against, and what it has not.**
>
> - The protocol layer passes the simulated ELM327 rigs, including
>   framing and fault-injection checks, and a third-party ELM327
>   implementation this project did not write.
> - A physical Samsung phone completed a real Bluetooth LE/GATT session
>   over the phone's and Mac's actual radios against the Mac-hosted rig.
> - **One** real-vehicle observation exists: a purchased CARLZS LAB
>   `CL-OBDII-M25B` over Bluetooth LE, connected to a Toyota GT86. One
>   adapter and one car is not adapter compatibility and not
>   vehicle-generation compatibility, and the protocol-level transcript
>   from that session has not been reviewed or published.
> - **Still unverified:** any second adapter, any other vehicle, and
>   every engine-running condition.
> - `docs/verification/test-evidence.md` and
>   `docs/verification/device-verification.md` record the exact
>   boundary, dated. They are the source; this list is a summary.
>
> If you have an adapter and a car, this is the build to try.
> Settings → Export transcript writes out a verbatim record of
> everything the adapter said; an issue with that file attached is the
> most useful thing you can send.
>
> **這份 build 跑過什麼，沒跑過什麼。**
> 模擬 ELM327、分段與故障注入測試已通過，也跑過一份本專案沒有寫的
> 第三方 ELM327 實作；Samsung 實體手機已用真實藍牙無線電與 Android
> GATT 連上 Mac 主機的 BLE rig。真車觀察只有**一次**：購買的 CARLZS LAB
> `CL-OBDII-M25B` 透過 BLE 連上一台 Toyota GT86。一個轉接器加一台車不等於
> 轉接器相容性，也不等於車型世代相容性，而那次連線的協定層逐字紀錄
> 尚未審閱、也尚未公開。**仍未驗證：**第二個轉接器、其他任何車輛，
> 以及所有引擎運轉中的情境。詳細證據界線見 `docs/verification/`，那裡才是
> 來源，這份清單只是摘要。有轉接器又有車的話，這就是該試的版本；出問題請到
> 「設定 → 匯出紀錄」把逐字紀錄存下來，附在 issue 裡送回來。

BOUNDARY

cat <<EOF
Telltale ${APP_VERSION}

**English** | 繁體中文 below

A ready-made APK for anyone who would rather not run a Flutter
toolchain. Same source, same features as the Google Play build —
nothing is held back.

| | |
|---|---|
| File | \`telltale-${TAG}.apk\` (${APK_SIZE}) |
| SHA-256 | \`${APK_SHA256}\` |
| Signing certificate | \`${APK_FINGERPRINT}\` |

**This build is signed with the community key, not the Google Play
key.** It therefore cannot update — and cannot be updated by — an
install that came from the Play Store; Android will refuse with a
signature mismatch. Export any diagnostic records you need before
switching: uninstalling removes Telltale's local app data. The two keys
are separate on purpose: sharing them would let anything that compromised
CI publish a replacement for a store install.

Verify before installing:

\`\`\`
sha256sum telltale-${TAG}.apk
\`\`\`

---

給不想自己架 Flutter 環境的人的現成 APK。原始碼相同、功能與 Google Play
版完全一致，沒有閹割。

**這份是社群簽章金鑰簽的，不是 Google Play 的上架金鑰。** 所以它無法用來更新
從 Play 商店安裝的版本，反之亦然 —— Android 會以簽章不符拒絕。要換過去請先解除
安裝；解除安裝會刪除 Telltale 本機資料，請先匯出要保留的診斷紀錄。兩把金鑰刻意
分開：共用的話，任何入侵 CI 的人就能發布一個能取代商店安裝的版本。

安裝前請先核對 SHA-256。
EOF
