#!/usr/bin/env bash
# Field Bluetooth verification against a physical adapter.
#
# Preflight checks tools, device state, and radio. ACL down / not-in-bond is
# an observation, not “unpowered”, and does not block a bounded scan/connect
# journey. --probe-only never prints a field PASS.
#
# Usage (from app/):
#   tool/field_bt_verify/run.sh
#   ANDROID_SERIAL=R5CX10VFFBA tool/field_bt_verify/run.sh
#   tool/field_bt_verify/run.sh --probe-only
#   FIELD_BT_TRANSPORT=classic tool/field_bt_verify/run.sh
#   FIELD_BT_SKIP_INSTALL=1 tool/field_bt_verify/run.sh
#
# Exit codes:
#   0 — journey PASS (fresh GATT/RFCOMM→ELM→PID→record), or probe-only
#       observation success (not a field pass)
#   1 — tooling / install / journey failure / timeout / ambiguous target
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.47.0/bin/flutter}"
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
SERIAL="${ANDROID_SERIAL:-R5CX10VFFBA}"
ADAPTER_NAME="${FIELD_BT_ADAPTER_NAME:-OBDBLE}"
ADAPTER_ADDRESS="${FIELD_BT_ADAPTER_ADDRESS:-}"
TRANSPORT="${FIELD_BT_TRANSPORT:-ble}"
PACKAGE="${FIELD_BT_PACKAGE:-com.cbstudio.telltale}"
EVIDENCE_DIR="${FIELD_BT_EVIDENCE_DIR:-$ROOT/docs/verification}"
JOURNEY_TIMEOUT="${FIELD_BT_JOURNEY_TIMEOUT:-}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
PROBE_ONLY=0
FORCE_JOURNEY=0
SKIP_INSTALL="${FIELD_BT_SKIP_INSTALL:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe-only) PROBE_ONLY=1; shift ;;
    --force-journey) FORCE_JOURNEY=1; shift ;;
    --skip-install) SKIP_INSTALL=1; shift ;;
    --serial) SERIAL="${2:?}"; shift 2 ;;
    --transport) TRANSPORT="${2:?}"; shift 2 ;;
    --name) ADAPTER_NAME="${2:?}"; shift 2 ;;
    --address) ADAPTER_ADDRESS="${2:?}"; shift 2 ;;
    -h|--help)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

cd "$ROOT"

if [[ ! -x "$FLUTTER" ]]; then
  echo "Refusing: Flutter not executable at $FLUTTER" >&2
  exit 1
fi
if [[ ! -x "$ADB" ]]; then
  echo "Refusing: adb not executable at $ADB" >&2
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"
DUMP_DIR="${TMPDIR:-/tmp}/telltale-field-bt-verify"
mkdir -p "$DUMP_DIR"
chmod 700 "$DUMP_DIR" 2>/dev/null || true
DUMP="$DUMP_DIR/dumpsys-$STAMP.txt"
EVIDENCE="$EVIDENCE_DIR/field-bt-probe-$STAMP.txt"
JOURNEY_LOG="$EVIDENCE_DIR/field-bt-journey-$STAMP.log"

echo "field_bt_verify: serial=$SERIAL adapter=$ADAPTER_NAME transport=$TRANSPORT"

if ! "$ADB" -s "$SERIAL" get-state 2>/dev/null | grep -qx device; then
  echo "Refusing: device $SERIAL is not in 'device' state" >&2
  "$ADB" devices -l >&2 || true
  exit 1
fi

"$ADB" -s "$SERIAL" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
"$ADB" -s "$SERIAL" shell cmd bluetooth_manager enable >/dev/null 2>&1 || true
"$ADB" -s "$SERIAL" shell am start -a android.settings.BLUETOOTH_SETTINGS >/dev/null 2>&1 || true
sleep 2

"$ADB" -s "$SERIAL" shell dumpsys bluetooth_manager >"$DUMP" 2>/dev/null || {
  echo "Refusing: dumpsys bluetooth_manager failed" >&2
  exit 1
}

PROBE_ARGS=(tool/field_bt_verify/probe_acl.py "$DUMP" --name "$ADAPTER_NAME" --transport "$TRANSPORT" --evidence "$EVIDENCE")
if [[ -n "$ADAPTER_ADDRESS" ]]; then
  PROBE_ARGS+=(--address "$ADAPTER_ADDRESS")
fi

set +e
python3 "${PROBE_ARGS[@]}"
PROBE_RC=$?
set -e

{
  echo "timestamp_utc: $STAMP"
  echo "device: $SERIAL"
  echo "dumpsys_host_path: $DUMP"
  echo "qualification: not a field pass (probe is observation only)"
  echo "--- bond excerpt ---"
  strings "$DUMP" | rg -i "$ADAPTER_NAME|ConnectionState:" | head -20 || true
} >>"$EVIDENCE"

echo "ACL probe exit=$PROBE_RC evidence=$EVIDENCE"

if [[ "$PROBE_ONLY" -eq 1 ]]; then
  if [[ "$PROBE_RC" -ne 0 ]]; then
    echo "probe-only: observation failed (rc=$PROBE_RC) — not a field pass" >&2
    exit "$PROBE_RC"
  fi
  echo "probe-only: observation only — not a field pass"
  exit 0
fi

if [[ "$PROBE_RC" -ne 0 && "$FORCE_JOURNEY" -ne 1 ]]; then
  echo >&2
  echo "Refusing journey: probe observation failed (rc=$PROBE_RC)." >&2
  echo "If two adapters share this name, pass --address <MAC>." >&2
  echo "Evidence: $EVIDENCE" >&2
  exit "$PROBE_RC"
fi

grant_bt_permissions() {
  local pkg="$1"
  "$ADB" -s "$SERIAL" shell pm grant "$pkg" android.permission.BLUETOOTH_SCAN 2>/dev/null || true
  "$ADB" -s "$SERIAL" shell pm grant "$pkg" android.permission.BLUETOOTH_CONNECT 2>/dev/null || true
  "$ADB" -s "$SERIAL" shell pm grant "$pkg" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
  "$ADB" -s "$SERIAL" shell pm grant "$pkg" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
}

if [[ "$SKIP_INSTALL" != "1" ]]; then
  echo "Building + installing field debug APK (overwrites $PACKAGE on device)…"
  echo "Set FIELD_BT_SKIP_INSTALL=1 to reuse an already-installed field debug build."
  "$FLUTTER" build apk --debug --flavor field
  APK="$ROOT/build/app/outputs/flutter-apk/app-field-debug.apk"
  if [[ ! -f "$APK" ]]; then
    echo "Refusing: missing $APK" >&2
    exit 1
  fi
  "$ADB" -s "$SERIAL" install -r -g "$APK"
fi

grant_bt_permissions "$PACKAGE"

echo "Driving field BT journey → $JOURNEY_LOG"
export ANDROID_SERIAL="$SERIAL"
JOURNEY_CMD=(
  "$FLUTTER" test
  integration_test/field_bt_journey_test.dart
  -d "$SERIAL"
  --flavor field
  --dart-define=FIELD_BT_REQUIRED=true
  --dart-define=FIELD_BT_ADAPTER_NAME="$ADAPTER_NAME"
  --dart-define=FIELD_BT_TRANSPORT="$TRANSPORT"
)
if [[ -n "$ADAPTER_ADDRESS" ]]; then
  JOURNEY_CMD+=(--dart-define=FIELD_BT_ADAPTER_ADDRESS="$ADAPTER_ADDRESS")
fi
set +e
if [[ -n "$JOURNEY_TIMEOUT" ]]; then
  python3 - "$JOURNEY_TIMEOUT" "$JOURNEY_LOG" "${JOURNEY_CMD[@]}" <<'PY'
import subprocess
import sys

limit = float(sys.argv[1])
log_path = sys.argv[2]
cmd = sys.argv[3:]
with open(log_path, "w", encoding="utf-8") as log:
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    assert proc.stdout is not None
    try:
        out, _ = proc.communicate(timeout=limit)
        log.write(out or "")
        sys.stdout.write(out or "")
        sys.exit(proc.returncode or 0)
    except subprocess.TimeoutExpired:
        proc.kill()
        out, _ = proc.communicate()
        log.write(out or "")
        sys.stdout.write(out or "")
        print("not-run: journey timed out", file=sys.stderr)
        sys.exit(124)
PY
  JOURNEY_RC=$?
else
  "${JOURNEY_CMD[@]}" 2>&1 | tee "$JOURNEY_LOG"
  JOURNEY_RC=${PIPESTATUS[0]}
fi
set -e

{
  echo "--- journey ---"
  echo "timestamp_utc: $STAMP"
  echo "journey_rc: $JOURNEY_RC"
  echo "log: $JOURNEY_LOG"
  if [[ "$JOURNEY_RC" -eq 0 ]]; then
    echo "qualification: PASS — connect → live PIDs → record"
  elif [[ "$JOURNEY_RC" -eq 124 ]]; then
    echo "qualification: not-run — journey timed out"
  else
    echo "qualification: FAIL — journey did not complete (no fake pass)"
  fi
} >>"$EVIDENCE"

if [[ "$JOURNEY_RC" -eq 0 ]]; then
  echo "field_bt_verify: PASS"
  echo "evidence: $EVIDENCE"
  exit 0
fi

if [[ "$JOURNEY_RC" -eq 124 ]]; then
  echo "field_bt_verify: not-run (timeout)" >&2
else
  echo "field_bt_verify: FAIL (journey_rc=$JOURNEY_RC)" >&2
fi
echo "evidence: $EVIDENCE" >&2
exit 1
