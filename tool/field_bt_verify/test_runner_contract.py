#!/usr/bin/env python3
"""Shell-contract tests for field_bt_verify/run.sh with fake adb/Flutter.

Drives the shipped runner, not a reimplementation of probe_acl.evaluate.
"""

from __future__ import annotations

import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "tool" / "field_bt_verify" / "run.sh"

_ACL_DOWN = """
BluetoothAdapterProperties
  ConnectionState: STATE_DISCONNECTED
  Bonded devices: 1
    AA:BB:CC:00:00:01(Public ) => AA:BB:CC:00:00:01(Public ) [ DUAL ] [0x010000] [ACL BR/EDR:N LE:N] [ Encryption status(BR/EDR): null LE: null] OBDBLE
"""


def _write_exec(path: Path, body: str) -> None:
    path.write_text(body)
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


class RunnerContractTest(unittest.TestCase):
    def _harness(self, dumpsys: str = _ACL_DOWN) -> dict[str, Path]:
        tmp = Path(tempfile.mkdtemp(prefix="field-bt-runner-"))
        bin_dir = tmp / "bin"
        evidence = tmp / "evidence"
        dumpsys_path = tmp / "dumpsys.txt"
        flutter_log = tmp / "flutter.log"
        bin_dir.mkdir()
        evidence.mkdir()
        dumpsys_path.write_text(dumpsys)
        _write_exec(
            bin_dir / "adb",
            f"""#!/usr/bin/env bash
set -euo pipefail
while [[ "${{1:-}}" == -s ]]; do shift 2; done
case "${{1:-}}" in
  get-state) echo device; exit 0 ;;
  devices) echo "List of devices attached"; echo "fake    device"; exit 0 ;;
  shell)
    shift
    if [[ "$*" == *dumpsys*bluetooth_manager* ]]; then
      cat {dumpsys_path}
      exit 0
    fi
    exit 0
    ;;
  *) exit 0 ;;
esac
""",
        )
        _write_exec(
            bin_dir / "flutter",
            f"""#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "$@" >> {flutter_log}
if [[ " $* " == *" test "* ]]; then
  echo connect-entry-reached >> {flutter_log}
  exit "${{FAKE_FLUTTER_TEST_RC:-0}}"
fi
exit 0
""",
        )
        return {
            "tmp": tmp,
            "bin": bin_dir,
            "evidence": evidence,
            "flutter_log": flutter_log,
        }

    def _run(
        self,
        harness: dict[str, Path],
        extra: list[str],
        *,
        flutter_rc: str = "0",
        timeout: str | None = None,
        flutter_bin: Path | None = None,
        adb_bin: Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["PATH"] = f"{harness['bin']}:{env.get('PATH', '')}"
        env["ADB"] = str(adb_bin or harness["bin"] / "adb")
        env["FLUTTER"] = str(flutter_bin or harness["bin"] / "flutter")
        env["ANDROID_SERIAL"] = "fake"
        env["FIELD_BT_SKIP_INSTALL"] = "1"
        env["FIELD_BT_EVIDENCE_DIR"] = str(harness["evidence"])
        env["FIELD_BT_PACKAGE"] = "com.cbstudio.telltale"
        env["FAKE_FLUTTER_TEST_RC"] = flutter_rc
        env["TMPDIR"] = str(harness["tmp"])
        if timeout is not None:
            env["FIELD_BT_JOURNEY_TIMEOUT"] = timeout
        return subprocess.run(
            ["bash", str(RUNNER), *extra],
            cwd=str(ROOT),
            env=env,
            text=True,
            capture_output=True,
            timeout=20,
        )

    def test_probe_only_acl_down_is_observation_not_field_pass(self) -> None:
        harness = self._harness()
        proc = self._run(harness, ["--probe-only"])
        combined = proc.stdout + proc.stderr
        self.assertEqual(proc.returncode, 0, combined)
        self.assertNotIn("field_bt_verify: PASS", combined)
        self.assertNotIn("PASS — ACL up", combined)
        self.assertNotIn("unpowered", combined.lower())
        self.assertFalse(harness["flutter_log"].exists())

    def test_acl_down_still_reaches_connect_entry(self) -> None:
        harness = self._harness()
        proc = self._run(harness, ["--skip-install"])
        combined = proc.stdout + proc.stderr
        self.assertIn(
            "connect-entry-reached",
            harness["flutter_log"].read_text(),
            combined,
        )
        log = harness["flutter_log"].read_text()
        self.assertIn("field_bt_journey_test.dart", log)
        self.assertNotIn("--name OBDII", log)
        self.assertNotIn("OBDII", log.split("FIELD_BT_ADAPTER_NAME", 1)[-1][:200])

    def test_missing_flutter_fails_closed(self) -> None:
        harness = self._harness()
        proc = self._run(
            harness,
            ["--probe-only"],
            flutter_bin=harness["tmp"] / "missing-flutter",
        )
        self.assertNotEqual(proc.returncode, 0)
        self.assertNotIn("field_bt_verify: PASS", proc.stdout + proc.stderr)

    def test_journey_nonzero_is_not_green(self) -> None:
        harness = self._harness()
        proc = self._run(harness, ["--skip-install"], flutter_rc="7")
        combined = proc.stdout + proc.stderr
        self.assertIn("connect-entry-reached", harness["flutter_log"].read_text(), combined)
        self.assertNotEqual(proc.returncode, 0, combined)
        self.assertNotIn("field_bt_verify: PASS", combined)

    def test_journey_timeout_is_not_run_not_pass(self) -> None:
        harness = self._harness()
        _write_exec(
            harness["bin"] / "flutter",
            f"""#!/usr/bin/env bash
printf '%s\\n' "$@" >> {harness['flutter_log']}
if [[ " $* " == *" test "* ]]; then
  echo connect-entry-reached >> {harness['flutter_log']}
  sleep 8
  exit 0
fi
exit 0
""",
        )
        proc = self._run(harness, ["--skip-install"], timeout="1")
        combined = proc.stdout + proc.stderr
        self.assertNotEqual(proc.returncode, 0, combined)
        self.assertNotIn("field_bt_verify: PASS", combined)
        self.assertRegex(combined.lower(), r"not-run|timeout|timed out")


if __name__ == "__main__":
    unittest.main()
