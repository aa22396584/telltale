# Remaining human-only steps (2026-09-06)

Play production **1.0.9 / versionCode 10 is PUBLISHED**. GitHub community
pre-release is **`v1.0.9-beta.1` / `1.0.9+10`** (separate signing lineage).
**iOS App Store is deferred until 2027** — do not TestFlight or submit this
year (Personal Team `ABHJVZBWQN`; paid team `ZAZT4JZ625` Distribution cert
REVOKED; ASC API 401).

Public CI oracle remains `ImL1s/telltale`. Next Play Android `+N` must be **> 10**.
Do not treat the GitHub community APK as a Play upload.

Attached hardware at check time:

- Phone: Galaxy S24 Ultra `R5CX10VFFBA` (`SM-S9280`)
- Wear: Android emulator `emulator-5554` (`sdk_gwear_arm64`) only
- No physical Wear OS watch; bonded **OBDBLE** exists but was unpowered on 2026-09-06

## Wear BLE Gate 0

`docs/wearos.md` still requires a real watch plus a BLE ELM327 before
claiming Wear BLE works. The emulator has no BLE. Demo-on-emulator is
already recorded there; this check did not add BLE evidence.

Until a maintainer:

1. Builds `flutter build apk --debug --flavor wear`
2. Installs it on a physical Wear OS watch
3. Scans and connects a known BLE adapter (see `docs/hardware-compatibility.md`)
4. Confirms live gauges (not Demo)

Gate 0 stays **unverified**. The Wear battery page also stays unreachable
on a real watch until a provisioning / Data Layer path exists.

## Google Play / store

Preflight that does **not** need a Console click (current `origin/master`):

- `pubspec.yaml` `version: 1.0.9+10` (Play production is 10; next Play upload must be > 10)
- `applicationId` = `com.cbstudio.telltale`
- BLE dependency is `universal_ble`; `flutter_blue_plus` is comment-only
- Privacy policy URL in `docs/maintainers/release.md` is
  `https://iml1s.github.io/telltale/privacy.html` and that page loads
  (last updated 2026-09-06; in-app Shopee affiliate is tap-to-open only)

Phone Play **1.0.9 is done** (production completed / published, versionCode 10). Remaining:

1. Re-read Play Console for the highest consumed versionCode before the *next* bump (do not guess; currently 10)
2. Wear OS Play track (API 35+, 384×384 screenshots, Wear signing) is still unshipped
3. Store listing copy change (USABILITY-R2) was submitted 2026-09-06 and may still be in Play review
4. Powered OBDBLE / vehicle field walk when the dongle is actually on

Do not treat green `flutter test` / `flutter analyze` as Play-ready.

## GitHub Actions billing (private `torque` CI)

Private-repo CI for `feat/multiplatform-windows-linux` at `974a0ce`
(run https://github.com/ImL1s/torque/actions/runs/33507389391 )
and the follow-up at `e75600f` did **not** execute any job steps.
Every check-run annotation is:

> The job was not started because recent account payments have failed
> or your spending limit needs to be increased.

That is not a Flutter failure. Local evidence on `974a0ce`:
`flutter analyze` clean, `flutter test` `+1523 ~15`.

Public `telltale` CI on the same app tree (`b323dbe`, run
https://github.com/ImL1s/telltale/actions/runs/33508166605 )
was **8/8 green**, including Windows and Linux debug builds plus
Demo functional smoke. torque PR #3 and telltale PR #2 were merged
on that proxy. Restore Actions billing / spending limit on the
GitHub account that owns `ImL1s/torque` before expecting private CI
to start again. Do not treat a billing skip as a green private run.

## Dirty main worktree

Resolved 2026-09-06: the unpublished local telemetry tree was snapshotted to
`wip/local-telemetry-snapshot-20260906` (pushed) and `master` was
fast-forwarded to `origin/master`. Do not treat that wip branch as product
source — shipping code is `origin/master`.
