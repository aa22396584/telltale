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
  resolved="$(command -v "$FLUTTER" 2>/dev/null || true)"
  if [[ -n "$resolved" && -x "$resolved" ]]; then
    FLUTTER="$resolved"
  else
    echo "Refusing: Flutter not executable at $FLUTTER" >&2
    exit 1
  fi
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
if listening "$CONTROL_PORT"; then
  echo "Refusing: something already listens on ${BIND}:${CONTROL_PORT}" >&2
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
  if [[ -n "${PROXY_PID_FILE:-}" && -f "$PROXY_PID_FILE" ]]; then
    reap "$(tr -d '[:space:]' <"$PROXY_PID_FILE")"
  fi
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

PROXY_PID_FILE="$STATE/proxy.pid"

# Every caller reads the log path out of this with `log="$(start_proxy …)"`, which runs the
# whole function in a subshell — so `PROXY_PID=$!` was assigned in a child and lost. The
# parent's `stop_proxy` then reaped an empty variable and killed nothing.
#
# That is not a leak, it is a wrong answer. The scenario proxy stayed on the port; the next
# scenario's proxy failed to bind and exited; `wait_listen` saw the OLD one still listening
# and returned success; and the next test ran against a proxy armed with the PREVIOUS
# scenario's fault. A close-on-command run against a fragment-only proxy never sees its
# fault and fails, having reported nothing about why.
#
# The pid crosses the subshell boundary in a file, and each scenario refuses to start until
# the port is genuinely free.
start_proxy() {
  # `${extra[@]+…}` rather than a bare `"${extra[@]}"`: macOS ships bash 3.2, where an
  # EMPTY array expanded under `set -u` is an unbound-variable error. The fragment-only
  # scenario is the one caller that passes no extra flags, so on any maintainer's Mac this
  # script died there before the proxy was ever launched — which is why the stale-proxy bug
  # below reached CI without anyone being able to reproduce it locally.
  local extra=("$@")
  local log="$STATE/chaos-$RANDOM.jsonl"
  : >"$log"
  if listening "$PROXY_PORT"; then
    echo "Refusing: ${BIND}:${PROXY_PORT} is still occupied — a previous scenario's proxy" \
         "was not stopped, so this scenario would test the wrong fault" >&2
    return 1
  fi
  "$PYTHON" tool/obd_test_rig/chaos_proxy.py \
    --listen-host "$BIND" --listen-port "$PROXY_PORT" \
    --upstream-host "$BIND" --upstream-port "$ELM_PORT" \
    --chunk-sizes 1,2,5,3 --delay-ms 1 \
    --log "$log" \
    ${extra[@]+"${extra[@]}"} >"$STATE/proxy.stdout" 2>"$STATE/proxy.stderr" &
  local pid=$!
  printf '%s' "$pid" >"$PROXY_PID_FILE"
  if ! wait_listen "$PROXY_PORT"; then
    echo "--- chaos proxy stderr ---" >&2
    cat "$STATE/proxy.stderr" >&2 || true
    return 1
  fi
  # The port being open is not proof that OUR process opened it.
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "Refusing: the chaos proxy exited during startup while ${BIND}:${PROXY_PORT}" \
         "is listening — something else owns that port" >&2
    cat "$STATE/proxy.stderr" >&2 || true
    return 1
  fi
  echo "$log"
}

stop_proxy() {
  if [[ -f "$PROXY_PID_FILE" ]]; then
    reap "$(tr -d '[:space:]' <"$PROXY_PID_FILE")"
    rm -f "$PROXY_PID_FILE"
  fi
  reap "$PROXY_PID"
  PROXY_PID=""
  # Killing the owner is not the same as the port being free again.
  local i
  for i in $(seq 1 50); do
    listening "$PROXY_PORT" || return 0
    sleep 0.1
  done
  echo "Refusing: ${BIND}:${PROXY_PORT} is still listening after the proxy was stopped" >&2
  return 1
}

count_tests() {
  "$PYTHON" tool/workshop/count_dart_tests.py "$1"
}

FLUTTER_TIMEOUT="${FLUTTER_TIMEOUT:-180}"

with_timeout() {
  local seconds="$1"
  shift
  "$PYTHON" -c '
import subprocess, sys
timeout = int(sys.argv[1])
command = sys.argv[2:]
try:
    raise SystemExit(subprocess.run(command, timeout=timeout).returncode)
except subprocess.TimeoutExpired:
    print("FAIL: command exceeded timeout", file=sys.stderr)
    raise SystemExit(124)
' "$seconds" "$@"
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
SKIP_OUT="$STATE/python-skips.txt"
{
  PYTHONWARNINGS="${PYTHONWARNINGS:-error::ResourceWarning}" \
    "$PYTHON" -m unittest discover -s tool/ble_test_rig -p 'test_*.py' -v
  PYTHONWARNINGS="${PYTHONWARNINGS:-error::ResourceWarning}" \
    "$PYTHON" -m unittest discover -s tool/obd_test_rig -p 'test_*.py' -v
} 2>&1 | tee "$SKIP_OUT"
"$PYTHON" tool/workshop/assert_skip_manifest.py --unittest-output "$SKIP_OUT"

echo "== Ircama required =="
start_elm
IRCAMA_JSON="$STATE/ircama.json"
set +e
with_timeout "$FLUTTER_TIMEOUT" "$FLUTTER" test test/emulator_integration_test.dart --reporter json \
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
with_timeout "$FLUTTER_TIMEOUT" "$FLUTTER" test test/emulator_integration_test.dart --reporter json \
  --dart-define=ELM_ORACLE_REQUIRED=true \
  --dart-define=ELM_ORACLE_PORT="$PROXY_PORT" \
  >"$FRAG_JSON"
frag_rc=$?
set -e
assert_report "$FRAG_JSON" "$(count_tests test/emulator_integration_test.dart)" "$frag_rc"
"$PYTHON" tool/workshop/assert_chaos_jsonl.py "$FRAG_LOG" --require-chunks 2
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
  with_timeout "$FLUTTER_TIMEOUT" "$FLUTTER" test test/chaos_oracle_test.dart --reporter json \
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
with_timeout "$FLUTTER_TIMEOUT" "$FLUTTER" test test/chaos_poll_oracle_test.dart --reporter json \
  --dart-define=CHAOS_ORACLE=true \
  --dart-define=CHAOS_ORACLE_PORT="$PROXY_PORT" \
  --dart-define=CHAOS_CONTROL_PORT="$CONTROL_PORT" \
  --dart-define=CHAOS_CONTROL_TOKEN="$TOKEN" \
  >"$POLL_JSON"
poll_rc=$?
set -e
assert_report "$POLL_JSON" "$(count_tests test/chaos_poll_oracle_test.dart)" "$poll_rc"
"$PYTHON" tool/workshop/assert_chaos_jsonl.py "$POLL_LOG" close 01
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
with_timeout 240 "$FLUTTER" test test/freeze_frame_oracle_test.dart --reporter json \
  --dart-define=FREEZE_FRAME_ORACLE_REQUIRED=true \
  --dart-define=FREEZE_FRAME_ORACLE_PORT="$ELM_PORT" \
  >"$FREEZE_JSON"
freeze_rc=$?
set -e
assert_report "$FREEZE_JSON" "$(count_tests test/freeze_frame_oracle_test.dart)" "$freeze_rc"

echo "public oracles: PASS"
echo "state: $STATE"
