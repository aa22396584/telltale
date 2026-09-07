# Platform support

Telltale is a Flutter app. The Dart package name stays `torque_obd`; the product
identity users see is **Telltale** / `com.cbstudio.telltale`.

## Verification backbone

Private `ImL1s/torque` Actions may be unavailable (billing). **Public
`ImL1s/telltale` CI is the authoritative remote matrix** for multiplatform
enablement. Compile gates are necessary but **not sufficient**: functional
smoke (Demo journey, Wi‑Fi TCP unit path, export, host gates) must also pass
on free runners. Product code still originates in private `app/` and is
archive-synced; telltale `.github/` is publish-only. The harness map is
[`docs/verification/harness-catalog.json`](verification/harness-catalog.json),
checked by `test/harness_catalog_test.dart`.

## Functional matrix (honest)

Legend: **pass** = exercised by automated test and/or local run evidence on
this branch · **wired** = code path present, field/device evidence still thin ·
**OS-blocked** = host cannot provide the capability · **deferred** = not yet
proven to the full smoothness bar.

| Feature | Android | iOS | macOS | Windows | Linux |
|---|---|---|---|---|---|
| Demo connect → live telemetry UI | **pass** (device + `demo_connect_journey_test`) | **pass** (`integration_test/ios_field_demo_journey_test` on iPhone 17 Pro sim, field flavor) | **pass** (journey + local `Telltale.app` / macOS field share journey) | **pass** (journey test; device thin) | **pass** (journey test; device thin) |
| Session telemetry record / replay / export | **pass** (unit + rigs; field thin) | **pass** (iOS sim Demo record → durable `.ndjson`; export UI thin) | **pass** (`telemetry_demo_journey` + macOS field share journey staged CSV) | **pass** (automated path; sheet soft-fail OK) | **pass** (automated path; sheet soft-fail OK) |
| `app_share*` prepare → platform handoff | **pass** (native + unit) | **wired** (`share_plus` + iPad `sharePositionOrigin` on all export entry points) | **pass** (native capacity + staged immutable file + `app_share` channel; picker target still human) | **wired** (capacity + staging; `shareHandoffFailed` when sheet unavailable — not silent success) | **wired** (capacity + staging; `shareHandoffFailed` when sheet unavailable — not silent success) |
| Wi‑Fi TCP to adapter | **pass** (+ Android route binder) | **pass** (`tool/ios_wifi_oracle/run.sh`: Simulator → host `en0` Ircama on `:35000`, live PIDs, `TransportKind.wifi`) | **pass** (`WifiTransport` → Ircama on `127.0.0.1:35000` via `emulator_integration_test` / `tool/desktop_wifi_oracle/run.sh`) | **pass** (same Dart `WifiTransport` oracle path; Windows-host oracle thin) | **pass** (telltale CI Ircama oracle + same suite) |
| BLE scan/connect | **pass** (field) | **wired** CoreBluetooth | **wired** entitlements | **wired** WinRT plugin | **wired** Dart BlueZ/D-Bus (needs BlueZ at runtime) |
| Classic SPP | **pass** | **OS-blocked** (no third-party SPP) | **wired** (IOBluetooth RFCOMM via plugin) | **wired** (Bluetooth SPP COM serial) | **wired** (BlueZ `/dev/rfcomm*` serial) |
| Transcript export / share | **pass** (via `app_share*`) | **wired** (popover origin threaded) | **pass** (native macOS path through staging; failed handoff is explicit) | **wired** (staged file + explicit handoff failure copy) | **wired** (staged file + explicit handoff failure copy) |
| PID CSV pick/share | **pass** | **wired** (popover origin threaded) | **wired** sandbox | **wired** | **wired** |
| SharedPreferences boot | **pass** | **pass** | **pass** | **pass** | **pass** |
| Wakelock while connected | **pass** | **pass** | **pass** | **wired** | no-op (no plugin; intentional) |
| CI beyond `flutter build` | analyze + full `flutter test` + APKs | build + functional smoke suite | build + functional smoke + unsigned `.app` zip artifact | build + functional smoke + unsigned Debug zip artifact | build + functional smoke + unsigned bundle tarball artifact |

## Bluetooth Classic (SPP)

UI predicate: `classicTransportAvailable` → **Android, macOS, Windows, or
Linux**. Guidance, transport cards, and remembered-adapter reconnect all fail
closed together. Automated coverage: `which_transport_test`,
`remembered_adapter_navigation_test`, `serial_transport_test`,
`macos_classic_iobluetooth_contract_test`, and reconnect host-gate tests.
**Classic-on-iOS is not a bug** — the card stays grey with an explicit OS
reason. **Classic-on-macOS is wired** through IOBluetooth RFCOMM (not a POSIX
TTY). BLE empty-scan / “which transport” copy never points at Classic when the
host gate is closed.

| Host | Status | Why |
|---|---|---|
| Android | Supported | Verified ELM327 RFCOMM/SPP (three-tier cascade incl. `connect(channel:)`) |
| iOS | **Permanent OS/API host gate** | No generic third-party SPP |
| Windows | **Wired — Bluetooth SPP COM** | Pairing creates `Standard Serial over Bluetooth link (COMx)`. App enumerates Bluetooth-associated COM ports via SetupAPI (`BTHENUM` / friendly “Bluetooth”) and opens them at 38400 8N1 through `SerialTransport` + `com.cbstudio.telltale/spp_serial`. Partial `WriteFile` loops until every byte is accepted. Winsock `AF_BTH` with `port=0` still needs SDP and does **not** replace `connect(channel:)`. Field connect→PID still needs a powered adapter on a Windows box |
| Linux | **Wired — RFCOMM TTY** | Same Dart channel + `SerialTransport` as Windows. Native runner enumerates `/dev/rfcomm*` and Bluetooth-backed tty nodes (sysfs path contains `bluetooth`/`rfcomm`/`hci`), opens at 38400 8N1 (`termios`), and streams inbound bytes on the EventChannel. Empty enumeration is honest — the Classic card is available but the wizard reports no ports until BlueZ has bound an RFCOMM node. With `VMIN=0`/`VTIME=2`, a zero-length `read()` is an idle timeout, not hangup. Field connect→PID still needs a powered adapter + bound TTY on a Linux box |
| macOS | **Wired — IOBluetooth RFCOMM** | Product path is `ClassicTransport` → `flutter_classic_bluetooth` → `IOBluetoothDevice.openRFCOMMChannelAsync` (SDP UUID → channel, else channel 1). Entitlement `com.apple.security.device.bluetooth` is present. macOS does **not** create per-paired-SPP POSIX TTYs comparable to Windows COM / Linux rfcomm — `/dev/cu.Bluetooth-Incoming-Port` is the host **incoming** serial profile, and incidental `cu.<device>` nodes (earbuds etc.) are not a general SPP enumeration surface — so `SerialTransport` / `spp_serial` stays Windows/Linux-only. Empty bonded list / radio-off fails closed in the wizard. Field connect→PID still needs a powered ELM327 paired on this Mac |

Linux CI still needs `libbluetooth-dev` because `flutter_classic_bluetooth`'s
Linux CMake requires BlueZ headers at configure time (plugin link), even though
the product Classic path on Linux is the RFCOMM serial channel above.

## Bluetooth LE

`bleTransportAvailable` → **true** on every shipping host.

- Android / iOS / macOS / Windows: `universal_ble` native plugins.
- Linux: Dart BlueZ backend (`package:bluez` over D-Bus). **No** Flutter
  plugin registrant is expected. Runtime needs BlueZ; compile CI does not need
  an adapter. Field evidence with a real ELM327 BLE dongle on Linux is still
  required before calling Linux BLE “mature”.

Scan preflight checks `getBluetoothAvailabilityState()` and maps powered-off /
unauthorized / BlueZ-D-Bus failures to actionable Chinese copy
(`BleRadioUnavailableException` / `BleTransport.userFacingScanFailure`).
Automated coverage: `test/ble_transport_test.dart` (poweredOff, unauthorized,
BlueZ string mapping) plus empty-scan guidance tests. Do not treat green CI as
a field BLE pass.

### When an adapter arrives (field verify)

Power the dongle (ignition ON), then from the Flutter app root:

```bash
# One command: ACL preflight → field debug install → BLE/Classic journey
tool/field_bt_verify/run.sh
# ACL / bonded inventory only:
tool/field_bt_verify/run.sh --probe-only
```

Manual inventory still useful:

```bash
# macOS inventory
system_profiler SPBluetoothDataType | rg -i 'OBD|ELM|V-?LINK|Vgate'

# Android bonded + ACL flags
ADB=~/Library/Android/sdk/platform-tools/adb
$ADB -s R5CX10VFFBA shell dumpsys bluetooth_manager | strings | rg -i 'OBD|ELM|ACL BR/EDR'
```

The harness writes observation vs qualification under
`docs/verification/field-bt-probe-*.txt`. ACL-down is **disconnected**, not a
field PASS and not “unpowered / out of range”. A field PASS still requires a
fresh connect → PID → record in that run; `--probe-only` never prints it.
Details: [`tool/field_bt_verify/README.md`](../tool/field_bt_verify/README.md).

Historical Android field transcript on this workstation (adapter presently
unpowered): `/sdcard/Download/torque-obd-20260827-133618-recovered.txt` —
`OBDBLE` over BLE (`FFF0`/`FFF1`), `ELM327 v1.5`, ISO 15765-4 CAN 11/500.

## Desktop / Apple runnable notes

- **macOS:** network client + Bluetooth entitlements; Demo smoke-launched
  locally as `Telltale.app`. SystemChrome orientation skipped on desktop.
  Share uses the native `com.cbstudio.telltale/app_share` channel after
  `app_storage_capacity`. Field debug share journey
  (`integration_test/macos_field_share_journey_test.dart`) proves capacity →
  Demo record → immutable staged CSV handoff; the OS picker itself is still a
  human step. Failed/unavailable handoffs return `shareHandoffFailed` with
  clear copy (file staged, sheet did not open) — never a silent success.
  Desktop Wi‑Fi functional evidence: `tool/desktop_wifi_oracle/run.sh` starts
  Ircama with `-d` (required on macOS background shells) and runs
  `emulator_integration_test.dart` (`ELM_ORACLE_REQUIRED`) proving handshake,
  VIN, live RPM/speed polling, record, and export over `WifiTransport`.
  Unsigned packaging: `tool/packaging/macos_dmg.sh` (notarization called out,
  not automated). `default-flavor: field` requires matching Xcode scheme +
  configs (`field.xcscheme`, `Debug-field`/`Release-field`/`Profile-field`);
  Android-only `rig` stays out of Apple schemes.
- **Windows / Linux:** runners now register
  `com.cbstudio.telltale/app_storage_capacity` (`GetDiskFreeSpaceExW` /
  `statvfs`) so share preflight is no longer a permanent `shareSpaceUnknown`
  dead-end. When the interactive sheet cannot open, UX reports staged-but-
  handoff-failed instead of pretending the picker confirmed. Packaging:
  `tool/packaging/windows_zip.sh` / `linux_tarball.sh` (MSIX / AppImage /
  Flatpak stubs documented beside them). Single-instance: Windows named mutex
  `Local\\com.cbstudio.telltale.single_instance`; Linux uses
  `G_APPLICATION_DEFAULT_FLAGS` (unique GTK application id) so a second
  process cannot corrupt live `.ndjson.part` / share leases via startup
  recovery.
- **Windows:** `Telltale` / `telltale.exe`; MSVC coroutine silence for
  `permission_handler_windows` (plural `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`,
  matching MSVC STL1011’s own suppress token).
- **Linux:** wakelock no-op; Demo / Wi‑Fi / BLE (BlueZ) do not depend on it.
  Public telltale CI runs the Ircama Wi‑Fi oracle on Linux runners.
- **iOS:** Classic permanently unavailable; Demo / Wi‑Fi / BLE are the core
  path. Field Simulator evidence:
  `integration_test/ios_field_demo_journey_test.dart` (Demo → live PIDs →
  record → durable session file) and
  `tool/ios_wifi_oracle/run.sh` / `ios_field_wifi_oracle_test.dart` (Simulator
  → host LAN `en0` Ircama → handshake → live PIDs on `TransportKind.wifi`).
  The BLE entrypoint stays loopback-only by default; the iOS Wi‑Fi harness
  sets `ELM_BIND_INTERFACE=0.0.0.0` for that run only. Same `field` scheme
  requirement as macOS for `default-flavor`. All share entry points
  (telemetry, raw/recovered transcript, PID CSV) accept `sharePositionOrigin`
  for iPad popovers.

## Hardware inventory (this workstation, 2026-09-01)

- Android attached: `R5CX10VFFBA` (S24 Ultra), `RFCNC0WNT9H`, `emulator-5554`.
- S24 Ultra bonded list includes **`OBDBLE` / `OBDII` (SPP)** — dual-mode
  adapter historically proven over BLE on 2026-08-27 (see recovered transcript
  above). Re-check `field-bt-probe-20260831T235526Z` via
  `tool/field_bt_verify/run.sh --probe-only`: phone BT **ON**, ACL BR/EDR and
  LE both still **N** (`ConnectionState` disconnected). Treat as **observation:
  disconnected** — not unpowered, and not a field PASS. No fresh
  connect→PID→record that session. Prior
  same-day checks `20260831T232922Z` / `20260831T223755Z` /
  `20260831T222101Z` / `20260831T212448Z` reached the same verdict.
- macOS paired set is phones/keyboards/earbuds/gamepads only (no ELM327).
  Classic UI is enabled via IOBluetooth RFCOMM; field proof still needs a
  powered adapter paired to this Mac.
- iOS Simulator Demo + LAN Wi‑Fi oracle already evidenced on this branch
  (host `en0` = `192.168.1.135` at time of proof).

## Still deferred (does **not** meet the full functional bar alone)

- Store packaging (signed MSIX / Flathub Flatpak / notarized DMG) — unsigned
  zip/tarball/DMG recipes exist under `tool/packaging/` and CI uploads debug
  archives
- Windows / Linux / macOS Classic **field** proof (powered ELM327 → connect →
  PID → record → export on a real host). Software paths are wired; evidence is
  not.
- Linux / desktop BLE field verification against a **powered** adapter
- Human confirmation of every desktop share-sheet target (macOS staging +
  channel handoff is proven; picker selection is not automated)
- Keyboard/mouse shell density polish
- Notarized / store-signed packages (unsigned archives only)

## Rendering backend on Android

Flutter 3.47 selects Impeller on every API 29+ device except one with a
Vivante GPU (`ro.hardware.egl`), and, in the engine paths read at
`4cf2416426` (`flutter_main.cc`, `platform_view_android.cc`, the dynamic/GL/VK
Impeller contexts and five GLES backend files), has no route back to Skia once
the engine is up: without a Vulkan driver it uses Impeller's own OpenGL ES
backend, and those files carry no GPU denylist for that backend. The
historical fix for Adreno 3xx silicon was the API < 29 gate
(flutter/flutter#165075, for the Nexus 5). A custom ROM that reports API 30 on
the same silicon walks past it — that is #121: a Samsung Note 3 on DivestOS
18.1, `SIGSEGV` in `libsc-a3xx.so` under `libflutter.so`, before the first
frame.

So the app decides, before the engine exists (`MainActivity.onCreate`, ahead of
`super.onCreate()`), from two system properties:

| `ro.board.platform` or `ro.hardware.vulkan` | API | decision | the engine then |
|---|---|---|---|
| in `RendererPolicy.impellerGlesCrashes` (today `msm8974`) | ≥ 29 | `skia-forced` — `--enable-impeller=false` | Skia OpenGL ES |
| anything else, or unreadable | ≥ 29 | `impeller-default` — nothing passed | its own choice: Impeller (Vulkan, or its GLES backend without Vulkan), or Skia on a Vivante GPU |
| any | < 29 | `skia-engine-default` — nothing passed | Skia, by its own gate |

The rule is `android/app/src/main/kotlin/com/cbstudio/telltale/RendererPolicy.kt`,
a pure function tested on the JVM (`android/app/src/test/…/RendererPolicyTest.kt`,
run by CI). Matching is exact after trim and lower-case. "No Vulkan" is not a
criterion: a healthy GLES-only phone and this crash look identical by that
measure. An unreadable property is unknown and keeps the default, so the worst a
broken read can do is leave a phone on the engine's default. In release the
shell arguments are the app's alone; launch-Intent extras are not consulted,
so an Intent can no longer move a phone onto Skia (flutter/flutter#190461 is
the engine's own plan to do the same). "Nothing passed" means the engine
chooses: Impeller on API 29+, except its own Vivante exception; Skia below.

What it costs at start-up, on the main thread, before the engine: the two
property reads share one 250 ms budget; the budget bounds the poll that waits
for a `getprop` child, not the spawn or the `destroy()` after it, which nothing
here can interrupt. Reflection normally answers in microseconds and the child
is only spawned when reflection is refused. The decision is made once per
process; a warm relaunch reuses it and reports it as still applied.

The reason always carries both property values and, on a match, which one
matched (`… matched=ro.board.platform`), so an evidence file shows the two
properties disagreeing rather than only the one that decided. A second line
per property says which path answered: `reflection`, `getprop`, or
`deadline-expired` — the budget was already spent before a child could be
started, which is the line to look for when a slow start-up is being chased.

What is recorded: one logcat line `Telltale: renderer: <decision> (<reason>)`,
one from Dart `renderer: <decision> (<reason>); engine reports <impeller|skia>`,
and the same two facts in every evidence file header as `# 渲染：…`. The engine
side is read from `ImageFilter.isShaderFilterSupported`, which is true only
under Impeller — so the header shows what was asked for and what ran, and they
can disagree.

Verified with Flutter 3.47.0 release builds. The first rows below are from the
final code of the change (`7e89fb5`), each read from logcat; the forced row is
from an earlier build of the same branch with `pineapple` placed in the
denylist for one build and removed after, because the S24 is the only phone
here and its own platform string is the only way to reach the Skia branch.

| device | build (SHA-256) | `Telltale:` lines | engine line | Dart `engine reports` |
|---|---|---|---|---|
| Galaxy S24 Ultra, API 36, `pineapple` / `adreno`, cold start | `rig` flavor, Torque-signed, `685aa309…1391a4` | `property … via reflection` ×2; `renderer: impeller-default (ro.board.platform=pineapple ro.hardware.vulkan=adreno)` | `Using the Impeller rendering backend (Vulkan).` | `impeller` |
| same phone, back out and tap the icon again (process kept) | same | `renderer: impeller-default (…), applied earlier in this process` | the same Vulkan line, from the new engine | `impeller` |
| same phone, `pineapple` in the denylist for one throwaway build | `rig`, earlier commit | `renderer: skia-forced (ro.board.platform=pineapple)` | no Impeller line; `skia: [SkFontMgr Android Parser]` | `skia`; the connect screen rendered |
| emulator `sdk_gphone64_arm64`, API 36, `ranchu`, cold start | `field` flavor, community-signed, `2912d81c…60c8ee`, installed **over** the published `v1.0.12` and then over the previous candidate — same-signature upgrades | `property … via reflection` ×2; `renderer: impeller-default (ro.board.platform=(empty) ro.hardware.vulkan=ranchu)` | `Using the Impeller rendering backend (OpenGLES).` | `impeller` |
| same emulator, back out and tap again | same | `renderer: impeller-default (…), applied earlier in this process` | the same OpenGLES line | `impeller` |

Two things those rows say beyond the switch. On API 36, both on the phone and
on the emulator, `ro.*` is read **by reflection** — the hidden-API policy did
not refuse `SystemProperties.get` there; whether it does on Android 11 is
still only knowable from the reporter's phone, and the `getprop` path is what
answers if it does. And on the emulator the Dart line read
`renderer: unknown (unknown)` on three of four launches while the Kotlin line
above it carried the decision: the platform-metadata prefetch has a 500 ms
budget so that field evidence can never hold up a start, and the emulator
missed it. `unknown` is honest there; the logcat line from Kotlin is the one
that always carries the decision, and the header's engine-reported half comes
from Dart itself and is not affected.

The published `v1.0.12` on that emulator, before the first upgrade, printed the
same OpenGLES line and no `renderer:` line at all — the pre-fix shape.

Not verified: the reporter's `hlte`. No Adreno 3xx device is on hand, and an
emulator cannot fake `ro.board.platform`. #121 stays open for that row; the
rows above show the switch's two sides, not the crash going away on the phone
that had it.
