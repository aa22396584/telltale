#!/usr/bin/env python3
"""Unit tests for the extracted Flutter oracle JSON guard.

These tests drive `tool/oracle_guard/assert_no_skips.py`, not a reimplementation.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


APP_DIR = Path(__file__).resolve().parents[2]
SCRIPT_PATH = APP_DIR / "tool" / "oracle_guard" / "assert_no_skips.py"
CI_PATH = APP_DIR / ".github" / "workflows" / "ci.yml"


def load_guard():
    spec = importlib.util.spec_from_file_location("assert_no_skips", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def jsonl(events: list[dict]) -> str:
    return "".join(json.dumps(event, separators=(",", ":")) + "\n" for event in events)


def visible_successes(count: int, *, start_id: int = 1) -> list[dict]:
    events: list[dict] = [{"type": "start", "protocolVersion": "0.1.1", "pid": 1}]
    for i in range(count):
        tid = start_id + i
        events.append(
            {
                "type": "testStart",
                "test": {
                    "id": tid,
                    "name": f"oracle case {tid}",
                    "suiteID": 0,
                    "groupIDs": [],
                    "metadata": {"skip": False, "skipReason": None},
                },
            }
        )
        events.append(
            {
                "type": "testDone",
                "testID": tid,
                "result": "success",
                "hidden": False,
                "skipped": False,
            }
        )
    events.append({"type": "done", "success": True})
    return events


class OracleGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.guard = load_guard()

    def _eval(self, text: str, expected: int = 6, runner_exit: int = 0):
        with tempfile.TemporaryDirectory() as raw:
            report = Path(raw) / "report.jsonl"
            report.write_text(text, encoding="utf-8")
            return self.guard.assert_oracle_report(
                report, expected=expected, runner_exit=runner_exit
            )

    def _run_cli(self, text: str, extra: list[str] | None = None) -> subprocess.CompletedProcess:
        with tempfile.TemporaryDirectory() as raw:
            report = Path(raw) / "report.jsonl"
            report.write_text(text, encoding="utf-8")
            cmd = [sys.executable, str(SCRIPT_PATH), str(report), "6"]
            if extra:
                cmd.extend(extra)
            return subprocess.run(cmd, capture_output=True, text=True)

    def test_original_repro_done_success_false_is_nonzero(self) -> None:
        events = [
            {
                "type": "testDone",
                "testID": i,
                "hidden": False,
                "skipped": False,
                "result": "success",
            }
            for i in range(6)
        ]
        events.append({"type": "done", "success": False})
        result = self._run_cli(jsonl(events))
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("done.success", result.stderr)

    def test_missing_final_done_is_rejected(self) -> None:
        events = visible_successes(6)[:-1]
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("terminal done", str(raised.exception).lower())

    def test_global_error_without_testid_is_rejected(self) -> None:
        events = visible_successes(6)
        events.insert(-1, {"type": "error", "error": "unhandled exception"})
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("global error", str(raised.exception).lower())

    def test_duplicate_testdone_six_times_is_rejected(self) -> None:
        events = [
            {
                "type": "testDone",
                "testID": 1,
                "hidden": False,
                "skipped": False,
                "result": "success",
            }
            for _ in range(6)
        ]
        events.append({"type": "done", "success": True})
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("duplicate", str(raised.exception).lower())

    def test_malformed_json_tail_is_rejected(self) -> None:
        text = jsonl(visible_successes(6)) + '{"type": nope}\n'
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        self.assertIn("malformed", str(raised.exception).lower())

    def test_truncated_json_is_rejected(self) -> None:
        text = jsonl(visible_successes(6)[:-1]) + '{"type":"done","succes'
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        self.assertIn("truncated", str(raised.exception).lower())

    def test_runner_nonzero_rejects_even_if_json_looks_complete(self) -> None:
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(visible_successes(6)), runner_exit=1)
        self.assertIn("runner exit", str(raised.exception).lower())
        result = self._run_cli(jsonl(visible_successes(6)), extra=["--runner-exit", "1"])
        self.assertNotEqual(result.returncode, 0)

    def test_visible_skip_is_rejected(self) -> None:
        events = visible_successes(5)
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 99,
                "result": "success",
                "hidden": False,
                "skipped": True,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("skip", str(raised.exception).lower())

    def test_hidden_failure_is_rejected(self) -> None:
        events = visible_successes(6)
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 50,
                "result": "error",
                "hidden": True,
                "skipped": False,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("hidden", str(raised.exception).lower())

    def test_missing_identity_is_rejected(self) -> None:
        events = visible_successes(5)
        events.insert(
            -1,
            {
                "type": "testDone",
                "result": "success",
                "hidden": False,
                "skipped": False,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("identity", str(raised.exception).lower())

    def test_count_mismatch_is_rejected(self) -> None:
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(visible_successes(5)), expected=6)
        self.assertIn("expected 6", str(raised.exception).lower())

    def test_duplicate_done_is_rejected(self) -> None:
        events = visible_successes(6)
        events.append({"type": "done", "success": True})
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("duplicate done", str(raised.exception).lower())

    def test_event_after_terminal_done_is_rejected(self) -> None:
        events = visible_successes(6)
        events.append(
            {
                "type": "testDone",
                "testID": 7,
                "result": "success",
                "hidden": False,
                "skipped": False,
            }
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("after terminal", str(raised.exception).lower())

    def test_empty_report_is_rejected(self) -> None:
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval("")
        self.assertIn("no tests", str(raised.exception).lower())

    def test_missing_result_field_is_rejected(self) -> None:
        events = visible_successes(5)
        events.insert(
            -1,
            {"type": "testDone", "testID": 9, "hidden": False, "skipped": False},
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("result", str(raised.exception).lower())

    def test_flutter_startup_noise_before_json_is_ignored(self) -> None:
        text = (
            "Waiting for another flutter command to release the startup lock...\n"
            + jsonl(visible_successes(6))
        )
        passed, message = self._eval(text)
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_normal_lifecycle_fixture_passes(self) -> None:
        events = [
            {"type": "start", "protocolVersion": "0.1.1", "pid": 9},
            {"type": "allSuites", "count": 1},
            {"type": "suite", "suite": {"id": 0, "platform": "vm", "path": "test/emulator_integration_test.dart"}},
            {
                "type": "testStart",
                "test": {
                    "id": 1,
                    "name": "loading test/emulator_integration_test.dart",
                    "suiteID": 0,
                    "groupIDs": [],
                    "metadata": {"skip": False},
                },
            },
            {
                "type": "testDone",
                "testID": 1,
                "result": "success",
                "hidden": True,
                "skipped": False,
            },
        ]
        events.extend(visible_successes(6, start_id=2)[1:])
        passed, message = self._eval(jsonl(events))
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_print_and_error_bodies_are_not_leaked(self) -> None:
        vin = "JTDBH38K000000001"
        events = visible_successes(6)
        events.insert(
            -1,
            {
                "type": "error",
                "error": f"raw transcript VIN {vin} 41 00 deadbeef",
                "stackTrace": "secret-frame",
            },
        )
        result = self._run_cli(jsonl(events))
        self.assertNotEqual(result.returncode, 0)
        combined = result.stdout + result.stderr
        self.assertNotIn(vin, combined)
        self.assertNotIn("deadbeef", combined)
        self.assertNotIn("secret-frame", combined)

    def test_evidence_dir_records_hash_and_runner_exit_not_raw_error(self) -> None:
        text = jsonl(visible_successes(6))
        with tempfile.TemporaryDirectory() as raw:
            report = Path(raw) / "report.jsonl"
            evidence = Path(raw) / "evidence"
            report.write_text(text, encoding="utf-8")
            subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    str(report),
                    "6",
                    "--runner-exit",
                    "0",
                    "--evidence-dir",
                    str(evidence),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            copied = (evidence / "report.jsonl").read_bytes()
            digest = hashlib.sha256(copied).hexdigest()
            self.assertEqual(copied, text.encode("utf-8"))
            self.assertEqual((evidence / "report.sha256").read_text(encoding="utf-8").strip(), digest)
            self.assertEqual((evidence / "runner_exit.txt").read_text(encoding="utf-8").strip(), "0")
            attempt = json.loads((evidence / "attempt.json").read_text(encoding="utf-8"))
            self.assertEqual(attempt["runner_exit"], 0)
            self.assertEqual(attempt["expected"], 6)
            self.assertEqual(attempt["passed"], 6)
            self.assertEqual(attempt["report_sha256"], digest)

    def test_evidence_hash_matches_copied_bytes_for_crlf_and_bom(self) -> None:
        body = jsonl(visible_successes(6))
        cases = {
            "crlf": body.replace("\n", "\r\n").encode("utf-8"),
            "bom": b"\xef\xbb\xbf" + body.encode("utf-8"),
        }
        for name, raw in cases.items():
            with self.subTest(name), tempfile.TemporaryDirectory() as tmp:
                report = Path(tmp) / "report.jsonl"
                evidence = Path(tmp) / "evidence"
                report.write_bytes(raw)
                result = subprocess.run(
                    [
                        sys.executable,
                        str(SCRIPT_PATH),
                        str(report),
                        "6",
                        "--evidence-dir",
                        str(evidence),
                    ],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                copied = (evidence / "report.jsonl").read_bytes()
                self.assertEqual(copied, raw)
                digest = hashlib.sha256(raw).hexdigest()
                self.assertEqual(
                    (evidence / "report.sha256").read_text(encoding="utf-8").strip(),
                    digest,
                )
                attempt = json.loads((evidence / "attempt.json").read_text(encoding="utf-8"))
                self.assertEqual(attempt["report_sha256"], digest)
                self.assertTrue(attempt["ok"])

    def test_ci_oracle_job_keeps_flutter_exit_and_extracted_guard(self) -> None:
        if not CI_PATH.is_file():
            self.skipTest(
                "ci.yml lives in the public repo only; private app/ has no .github/"
            )
        workflow = CI_PATH.read_text(encoding="utf-8")
        self.assertIn("tool/workshop/run_public_oracles.sh", workflow)
        self.assertIn("tool/oracle_guard/assert_no_skips.py", workflow)
        script = (APP_DIR / "tool" / "workshop" / "run_public_oracles.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("tool/oracle_guard/assert_no_skips.py", script)
        self.assertIn("--runner-exit", script)
        self.assertIn("count_dart_tests.py", script)
        self.assertIn("chaos_proxy.py", script)
        self.assertIn("freeze_frame_reference.py", script)
        flutter_lines = [
            line
            for line in script.splitlines()
            if "test " in line and "FLUTTER" in line
        ]
        self.assertGreater(len(flutter_lines), 0)
        for line in flutter_lines:
            self.assertNotIn("|| true", line)


if __name__ == "__main__":
    unittest.main()
