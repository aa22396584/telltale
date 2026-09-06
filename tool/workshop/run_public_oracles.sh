#!/usr/bin/env bash
# Run the public, token-free oracle matrix from a clean telltale checkout.
#
# Starts Ircama, the chaos proxy (fresh process per scenario), and the
# project-owned freeze-frame reference. Binds loopback only. Owns PIDs in a
# private directory and kills them on EXIT.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

FLUTTER="${FLUTTER:-$HOME/fvm/versions/3.47.0/bin/flutter}"
PYTHON="${PYTHON:-python3}"
ELM_PORT="${ELM_ORACLE_PORT:-35000}"
PROXY_PORT="${CHAOS_ORACLE_PORT:-35001}"
CONTROL_PORT="${CHAOS_CONTROL_PORT:-35002}"
VENV="${ELM_VENV:-${TMPDIR:-/tmp}/telltale-public-oracles-venv}"
BIND="127.0.0.1"

if [[ ! -x "$FLUTTER" ]]; then
  echo "Refusing: Flutter not executable at $FLUTTER" >&2
  exit 1
fi

listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -qE ":${port}([^0-9]|$)"
  else
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  fi
}

if listening "$ELM_PORT"; then
  echo "Refusing: something already listens on ${BIND}:${ELM_PORT}" >&2
  exit 1
fi
if listening "$PROXY_PORT"; then
  echo "Refusing: something already listens on ${BIND}:${PROXY_PORT}" >&2
  exit 1
fi

CLEAN_STATE=1
if [[ -n "${PUBLIC_ORACLE_STATE:-}" ]]; then
  STATE="$PUBLIC_ORACLE_STATE"
  mkdir -p "$STATE"
  CLEAN_STATE=0
else
  STATE="$(mktemp -d "${TMPDIR:-/tmp}/telltale-public-oracles.XXXXXX")"
fi
chmod 700 "$STATE"
ELM_PID=""
PROXY_PID=""
REF_PID=""

reap() {
  local pid="$1"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
}

cleanup() {
  rc=$?
  trap - EXIT
  reap "$PROXY_PID"
  reap "$REF_PID"
  if [[ -n "${ELM_PID_DIR:-}" && -f "$ELM_PID_DIR/ircama.pid" ]]; then
    reap "$(tr -d '[:space:]' < "$ELM_PID_DIR/ircama.pid")"
  fi
  reap "$ELM_PID"
  if [[ "$CLEAN_STATE" -eq 1 ]]; then
    rm -rf -- "${STATE:?}"
  fi
  exit "$rc"
}
trap cleanup EXIT

if [[ -z "${ELM_PYTHON:-}" && ! -x "$VENV/bin/python" ]]; then
  "$PYTHON" -m venv "$VENV"
  "$VENV/bin/pip" install -q setuptools==80.10.2 wheel==0.45.1
  env -u GITHUB_RUN_NUMBER "$VENV/bin/pip" install -q --no-build-isolation \
    --no-cache-dir ELM327-emulator==3.0.5
  "$VENV/bin/pip" check
fi

wait_listen() {
  local port="$1"
  local _i
  for _i in $(seq 1 50); do
    listening "$port" && return 0
    sleep 0.1
  done
  echo "Refusing: nothing listened on ${BIND}:${port}" >&2
  return 1
}

ELM_BIN="${ELM_PYTHON:-$VENV/bin/python}"

start_elm() {
  if [[ ! -x "$ELM_BIN" ]]; then
    echo "Refusing: ELM python is not executable at $ELM_BIN" >&2
    exit 1
  fi
  ELM_PID_DIR="$STATE/elm"
  mkdir -m 700 "$ELM_PID_DIR"
  daemon=()
  if [[ "$(uname -s)" == Darwin ]]; then
    daemon=(-d)
  fi
  "$ELM_BIN" tool/ble_test_rig/emulator_entrypoint.py \
    --pid-directory "$ELM_PID_DIR" \
    -n "$ELM_PORT" -s car "${daemon[@]}" \
    -b "$ELM_PID_DIR/batch.log" >"$ELM_PID_DIR/elm.log" 2>&1 &
  ELM_PID=$!
  wait_listen "$ELM_PORT"
}

stop_elm() {
  if [[ -n "${ELM_PID_DIR:-}" && -f "$ELM_PID_DIR/ircama.pid" ]]; then
    reap "$(tr -d '[:space:]' < "$ELM_PID_DIR/ircama.pid")"
  fi
  reap "$ELM_PID"
  ELM_PID=""
}

start_proxy() {
  local extra=("$@")
  local log="$STATE/chaos-$RANDOM.jsonl"
  : >"$log"
  "$PYTHON" tool/obd_test_rig/chaos_proxy.py \
    --listen-host "$BIND" --listen-port "$PROXY_PORT" \
    --upstream-host "$BIND" --upstream-port "$ELM_PORT" \
    --chunk-sizes 1,2,5,3 --delay-ms 1 \
    --log "$log" \
    "${extra[@]}" >"$STATE/proxy.stdout" 2>"$STATE/proxy.stderr" &
  PROXY_PID=$!
  wait_listen "$PROXY_PORT"
  echo "$log"
}

stop_proxy() {
  reap "$PROXY_PID"
  PROXY_PID=""
}

count_tests() {
  "$PYTHON" tool/workshop/count_dart_tests.py "$1"
}

assert_report() {
  local json="$1"
  local expected="$2"
  local runner_rc="$3"
  "$PYTHON" tool/oracle_guard/assert_no_skips.py \
    "$json" "$expected" \
    --runner-exit "$runner_rc" \
    --evidence-dir "$STATE/evidence-$(basename "$json" .json)"
}

echo "== skip manifest =="
"$PYTHON" tool/workshop/assert_skip_manifest.py

echo "== Ircama required =="
start_elm
IRCAMA_JSON="$STATE/ircama.json"
set +e
"$FLUTTER" test test/emulator_integration_test.dart --reporter json \
  --dart-define=ELM_ORACLE_REQUIRED=true \
  --dart-define=ELM_ORACLE_PORT="$ELM_PORT" \
  >"$IRCAMA_JSON"
ircama_rc=$?
set -e
assert_report "$IRCAMA_JSON" "$(count_tests test/emulator_integration_test.dart)" "$ircama_rc"

echo "== chaos fragment-only =="
FRAG_LOG="$(start_proxy)"
FRAG_JSON="$STATE/frag.json"
set +e
"$FLUTTER" test test/emulator_integration_test.dart --reporter json \
  --dart-define=ELM_ORACLE_REQUIRED=true \
  --dart-define=ELM_ORACLE_PORT="$PROXY_PORT" \
  >"$FRAG_JSON"
frag_rc=$?
set -e
assert_report "$FRAG_JSON" "$(count_tests test/emulator_integration_test.dart)" "$frag_rc"
stop_proxy

run_fault() {
  local fault="$1"
  local flag="$2"
  local prefix="$3"
  echo "== chaos $fault =="
  local log
  log="$(start_proxy "$flag")"
  local json="$STATE/chaos-$fault.json"
  set +e
  "$FLUTTER" test test/chaos_oracle_test.dart --reporter json \
    --dart-define=CHAOS_ORACLE=true \
    --dart-define=CHAOS_ORACLE_PORT="$PROXY_PORT" \
    --dart-define=CHAOS_FAULT="$fault" \
    >"$json"
  local rc=$?
  set -e
  assert_report "$json" "$(count_tests test/chaos_oracle_test.dart)" "$rc"
  "$PYTHON" tool/workshop/assert_chaos_jsonl.py "$log" "$fault" "$prefix"
  stop_proxy
}

run_fault close --close-on-command=2 ATE0
run_fault no_prompt --no-prompt-on-command=2 ATE0
run_fault corrupt --corrupt-on-command=8 ATSP0

echo "== chaos poll reconnect =="
TOKEN="public-oracle-$(date +%s)"
POLL_LOG="$(start_proxy \
  --arm-next-command close \
  --control-host "$BIND" \
  --control-port "$CONTROL_PORT" \
  --control-token "$TOKEN" \
  --disconnect-after-armed-fault)"
POLL_JSON="$STATE/chaos-poll.json"
set +e
"$FLUTTER" test test/chaos_poll_oracle_test.dart --reporter json \
  --dart-define=CHAOS_ORACLE=true \
  --dart-define=CHAOS_ORACLE_PORT="$PROXY_PORT" \
  --dart-define=CHAOS_CONTROL_PORT="$CONTROL_PORT" \
  --dart-define=CHAOS_CONTROL_TOKEN="$TOKEN" \
  >"$POLL_JSON"
poll_rc=$?
set -e
assert_report "$POLL_JSON" "$(count_tests test/chaos_poll_oracle_test.dart)" "$poll_rc"
"$PYTHON" tool/workshop/assert_chaos_jsonl.py "$POLL_LOG" close AT
stop_proxy
stop_elm

echo "== freeze-frame reference =="
if listening "$ELM_PORT"; then
  echo "Refusing: port $ELM_PORT still occupied after stopping Ircama" >&2
  exit 1
fi
"$PYTHON" tool/obd_test_rig/freeze_frame_reference.py \
  --bind "$BIND" --port "$ELM_PORT" \
  --log "$STATE/freeze.jsonl" >"$STATE/freeze.stdout" 2>"$STATE/freeze.stderr" &
REF_PID=$!
wait_listen "$ELM_PORT"
FREEZE_JSON="$STATE/freeze.json"
set +e
"$FLUTTER" test test/freeze_frame_oracle_test.dart --reporter json \
  --dart-define=FREEZE_FRAME_ORACLE_REQUIRED=true \
  --dart-define=FREEZE_FRAME_ORACLE_PORT="$ELM_PORT" \
  >"$FREEZE_JSON"
freeze_rc=$?
set -e
assert_report "$FREEZE_JSON" "$(count_tests test/freeze_frame_oracle_test.dart)" "$freeze_rc"

echo "public oracles: PASS"
echo "state: $STATE"
