# Field Bluetooth verification (physical adapter)

One command to run when a matching adapter can be reached from the phone.
Proves **Connect → live PIDs → short record** on the shipped Android `field`
flavor. The dumpsys probe is an **observation**, not a field pass: ACL down is
not “unpowered”, BR/EDR up is not LE, and a second same-name adapter is not
the requested target.

This is **not** the macOS `ble_test_rig` (synthetic `TelltaleELM` peripheral).

## Requirements

- Attached Android phone (default serial `R5CX10VFFBA`)
- Bluetooth radio ON
- Pinned Flutter: `~/fvm/versions/3.47.0/bin/flutter`
- For a field PASS: a fresh GATT (BLE) or RFCOMM (Classic) connect → ELM
  handshake → ECU response → live PID → durable record in **this** run.
  An ACL `Y` left over from another app is diagnostic only.

## Usage

From the Flutter app root (`app/` in the private repo, repo root on telltale):

```bash
tool/field_bt_verify/run.sh
```

Useful variants:

```bash
# Observation only — never a field PASS
tool/field_bt_verify/run.sh --probe-only

# Classic SPP instead of BLE
FIELD_BT_TRANSPORT=classic tool/field_bt_verify/run.sh

# Two adapters share a display name — address is the Connect tile device.id
tool/field_bt_verify/run.sh --address AA:BB:CC:00:00:01

# Bound a hung Flutter journey (default 300s)
FIELD_BT_JOURNEY_TIMEOUT=120 tool/field_bt_verify/run.sh

# Reuse an already-installed field debug build
FIELD_BT_SKIP_INSTALL=1 tool/field_bt_verify/run.sh
```

`--force-journey` remains for probe *errors* (ambiguous name without
`--address`). ACL disconnected and “not in bond inventory” no longer block a
bounded scan/connect.

## What it writes

Under `docs/verification/`:

| File | Contents |
|---|---|
| `field-bt-probe-<utc>.txt` | Observation + qualification column |
| `field-bt-journey-<utc>.log` | Flutter integration-test output (journey runs only) |

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Journey PASS, or `--probe-only` observation success (not a field pass) |
| 1 | Tooling, install, journey failure, timeout (`not-run`), or ambiguous target |

## Install warning

A full journey builds and installs **`app-field-debug.apk`** over
`com.cbstudio.telltale`. That replaces a Play-signed build on the phone until
you reinstall from the store. Use `FIELD_BT_SKIP_INSTALL=1` when a field debug
build is already present, or `--probe-only` when you only want the observation.

## Harness checks (no phone)

```bash
python3 -m unittest discover -s tool/field_bt_verify -p 'test_*.py' -v
bash -n tool/field_bt_verify/run.sh
```
