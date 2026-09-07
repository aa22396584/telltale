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

# SemVer: everything after the first hyphen is a pre-release identifier.
# v1.0.1 is a release; v1.0.1-beta.1 is not.
is_prerelease() {
  case "$TAG" in
    *-*) return 0 ;;
    *)   return 1 ;;
  esac
}

case "$MODE" in
  flag)
    if is_prerelease; then echo prerelease; else echo full; fi
    exit 0
    ;;
  notes) ;;
  *)
    echo "usage: release_notes.sh notes|flag" >&2
    exit 2
    ;;
esac

: "${APP_VERSION:?APP_VERSION is required}"
: "${APK_SIZE:?APK_SIZE is required}"
: "${APK_SHA256:?APK_SHA256 is required}"
: "${APK_FINGERPRINT:?APK_FINGERPRINT is required}"

# Exactly one of these two prints, and each states only what its own gate
# checks. The pre-release sentence used to say "this exact binary has not been
# walked on a phone", whose opposite -- the claim a full release then made --
# was false: what gets walked is a locally signed release build, and what gets
# published is CI's build of the same commit under the community key. A release
# note is the wrong place to be approximately right, so the full-release
# paragraph names that gap itself instead of glossing it.
if is_prerelease; then
  cat <<'PRE'
> **Pre-release.** No walk of this version is recorded in
> `docs/verification/device-verification.md`. A full release has one.
>
> **預發行版本。** `docs/verification/device-verification.md` 裡沒有這個版本的
> 實機走查紀錄。正式版有。

PRE
else
  cat <<'FULL'
> **Full release.** A release build of this commit was installed on a phone and
> walked through, and `docs/verification/device-verification.md` records that
> walk under this version — CI refuses a full-release tag without that entry.
>
> One thing that sentence does not cover: the walked build is not this APK. It
> is a release build of the same commit, signed with a different key; the APK
> below is CI's, signed with the community key. Same source, same commit,
> different signature.
>
> **正式版。** 這個 commit 的 release build 已裝上實機走過一遍，走查紀錄記在
> `docs/verification/device-verification.md` 這個版本底下 —— 沒有那筆紀錄，CI 會
> 拒絕正式版 tag。這句話沒有涵蓋的一件事：走查的那一份不是下面這份 APK —— 它是同一個
> commit 的 release build，但用另一把金鑰簽；下面這份是 CI 用社群金鑰簽的。
> 原始碼相同、commit 相同、簽章不同。

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
