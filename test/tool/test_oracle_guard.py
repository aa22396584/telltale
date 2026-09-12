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


def _test_start(tid: int, name: str | None = None) -> dict:
    """Build a testStart event with proper structure."""
    return {
        "type": "testStart",
        "test": {
            "id": tid,
            "name": name or f"oracle case {tid}",
            "suiteID": 0,
            "groupIDs": [],
            "metadata": {"skip": False, "skipReason": None},
        },
    }


def _test_done(
    tid: int,
    *,
    result: str = "success",
    hidden: bool = False,
    skipped: bool = False,
) -> dict:
    return {
        "type": "testDone",
        "testID": tid,
        "result": result,
        "hidden": hidden,
        "skipped": skipped,
    }


def visible_successes(count: int, *, start_id: int = 1) -> list[dict]:
    events: list[dict] = [{"type": "start", "protocolVersion": "0.1.1", "pid": 1}]
    for i in range(count):
        tid = start_id + i
        events.append(_test_start(tid))
        events.append(_test_done(tid))
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

    # ── Existing rejection tests (fixtures adjusted for testStart) ──

    def test_original_repro_done_success_false_is_nonzero(self) -> None:
        """Old repro: 6 testDone + done.success=false must exit nonzero."""
        events: list[dict] = []
        for i in range(6):
            events.append(_test_start(i))
            events.append(_test_done(i))
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
        """Six identical visible testDone for id=1 (with one testStart) → duplicate."""
        events: list[dict] = [_test_start(1)]
        events.extend([_test_done(1) for _ in range(6)])
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
        events.insert(-1, _test_start(99))
        events.insert(-1, _test_done(99, skipped=True))
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("skip", str(raised.exception).lower())

    def test_hidden_failure_is_rejected(self) -> None:
        events = visible_successes(6)
        events.insert(-1, _test_start(50))
        events.insert(
            -1,
            _test_done(50, result="error", hidden=True),
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
        events.insert(-1, _test_start(9))
        events.insert(
            -1,
            {"type": "testDone", "testID": 9, "hidden": False, "skipped": False},
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        self.assertIn("result", str(raised.exception).lower())

    # ── New negative test cases (G1 execution card §A items 1–8) ──

    def test_terminal_without_teststart_is_rejected(self) -> None:
        """Execution card item 1: testDone without any preceding testStart."""
        events = [
            _test_done(1),
            {"type": "done", "success": True},
        ]
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events), expected=1)
        msg = str(raised.exception).lower()
        self.assertIn("without teststart", msg)

    def test_unfinished_teststart_at_done_is_rejected(self) -> None:
        """Execution card item 2: testStart exists but no testDone, yet done.success=true."""
        events = visible_successes(6)
        # Insert an extra testStart with no matching testDone before done.
        events.insert(-1, _test_start(100))
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("still running", msg)

    def test_hidden_terminal_duplicate_is_rejected(self) -> None:
        """Execution card item 3: two hidden testDone events with same ID."""
        events = visible_successes(6)
        events.insert(-1, _test_start(50))
        events.insert(-1, _test_done(50, hidden=True))
        # Duplicate hidden terminal for same ID:
        events.insert(-1, _test_done(50, hidden=True))
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("duplicate", msg)
        self.assertIn("hidden", msg)

    def test_boolean_testid_disguised_as_integer_is_rejected(self) -> None:
        """Execution card item 4: testID is boolean (true/false), not integer."""
        # Use raw JSON string to produce {"testID": true}
        events = visible_successes(5)
        raw_line = '{"type":"testDone","testID":true,"result":"success","hidden":false,"skipped":false}'
        text = jsonl(events[:-1]) + raw_line + "\n" + jsonl([events[-1]])
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("boolean", msg)

    def test_hidden_missing_field_is_rejected(self) -> None:
        """Execution card item 5a: testDone missing 'hidden' field."""
        events = visible_successes(5)
        events.insert(-1, _test_start(20))
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 20,
                "result": "success",
                # "hidden" deliberately omitted
                "skipped": False,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("hidden", msg)
        self.assertIn("null", msg)

    def test_skipped_missing_field_is_rejected(self) -> None:
        """Execution card item 5b: testDone missing 'skipped' field."""
        events = visible_successes(5)
        events.insert(-1, _test_start(21))
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 21,
                "result": "success",
                "hidden": False,
                # "skipped" deliberately omitted
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("skipped", msg)
        self.assertIn("null", msg)

    def test_hidden_skipped_masking_failure_is_rejected(self) -> None:
        """Execution card item 6: hidden=true skipped=true but result=failure must still fail."""
        events = visible_successes(6)
        events.insert(-1, _test_start(77))
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 77,
                "result": "failure",
                "hidden": True,
                "skipped": True,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("hidden failure", msg)

    def test_hidden_skipped_masking_error_result_is_rejected(self) -> None:
        """Execution card item 6b: hidden=true skipped=true but result=error must still fail."""
        events = visible_successes(6)
        events.insert(-1, _test_start(78))
        events.insert(
            -1,
            {
                "type": "testDone",
                "testID": 78,
                "result": "error",
                "hidden": True,
                "skipped": True,
            },
        )
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(jsonl(events))
        msg = str(raised.exception).lower()
        self.assertIn("hidden failure", msg)

    def test_json_duplicate_key_success_true_then_false_is_rejected(self) -> None:
        """Execution card item 7a: duplicate 'success' key, true then false."""
        events = visible_successes(6)
        # Replace the last done event with raw JSON containing duplicate key.
        text = jsonl(events[:-1]) + '{"type":"done","success":true,"success":false}\n'
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("duplicate json key", msg)

    def test_json_duplicate_key_success_false_then_true_is_rejected(self) -> None:
        """Execution card item 7b: duplicate 'success' key, false then true."""
        events = visible_successes(6)
        text = jsonl(events[:-1]) + '{"type":"done","success":false,"success":true}\n'
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("duplicate json key", msg)

    def test_skipped_null_is_rejected(self) -> None:
        """Execution card item 8a: skipped=null must be rejected, not treated as false."""
        raw_line = '{"type":"testDone","testID":30,"result":"success","hidden":false,"skipped":null}'
        events = visible_successes(5)
        events.insert(-1, _test_start(30))
        text = jsonl(events[:-1]) + raw_line + "\n" + jsonl([events[-1]])
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("skipped", msg)
        self.assertIn("null", msg)

    def test_hidden_null_is_rejected(self) -> None:
        """Execution card item 8b: hidden=null must be rejected."""
        raw_line = '{"type":"testDone","testID":31,"result":"success","hidden":null,"skipped":false}'
        events = visible_successes(5)
        events.insert(-1, _test_start(31))
        text = jsonl(events[:-1]) + raw_line + "\n" + jsonl([events[-1]])
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("hidden", msg)
        self.assertIn("null", msg)

    def test_hidden_as_integer_is_rejected(self) -> None:
        """Execution card item 8c: hidden=1 (integer) must be rejected."""
        raw_line = '{"type":"testDone","testID":32,"result":"success","hidden":1,"skipped":false}'
        events = visible_successes(5)
        events.insert(-1, _test_start(32))
        text = jsonl(events[:-1]) + raw_line + "\n" + jsonl([events[-1]])
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("hidden", msg)
        self.assertIn("not boolean", msg)

    def test_skipped_as_string_is_rejected(self) -> None:
        """Execution card item 8d: skipped="true" (string) must be rejected."""
        raw_line = '{"type":"testDone","testID":33,"result":"success","hidden":false,"skipped":"true"}'
        events = visible_successes(5)
        events.insert(-1, _test_start(33))
        text = jsonl(events[:-1]) + raw_line + "\n" + jsonl([events[-1]])
        with self.assertRaises(self.guard.GuardError) as raised:
            self._eval(text)
        msg = str(raised.exception).lower()
        self.assertIn("skipped", msg)
        self.assertIn("not boolean", msg)

    # ── Positive tests (existing + new) ──

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

    def test_hidden_success_lifecycle_does_not_count_as_visible(self) -> None:
        """A hidden test that succeeds should not increase the visible pass count."""
        events = visible_successes(6)
        events.insert(-1, _test_start(50))
        events.insert(-1, _test_done(50, hidden=True))
        passed, message = self._eval(jsonl(events))
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_multiple_tests_interleaved_completion_passes(self) -> None:
        """Tests can start interleaved and complete in any order."""
        events = [
            {"type": "start", "protocolVersion": "0.1.1", "pid": 1},
            _test_start(1, "test A"),
            _test_start(2, "test B"),
            _test_start(3, "test C"),
            _test_done(2),  # B finishes first
            _test_start(4, "test D"),
            _test_done(1),  # A finishes second
            _test_done(3),
            _test_start(5, "test E"),
            _test_done(4),
            _test_start(6, "test F"),
            _test_done(5),
            _test_done(6),
            {"type": "done", "success": True},
        ]
        passed, message = self._eval(jsonl(events))
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_extension_fields_on_events_are_allowed(self) -> None:
        """Non-critical extension fields should not cause rejection."""
        events = visible_successes(6)
        # Add an extension field to a testDone event.
        for ev in events:
            if ev.get("type") == "testDone" and not ev.get("hidden"):
                ev["time"] = 42
                ev["_custom"] = "ok"
                break
        passed, message = self._eval(jsonl(events))
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_crlf_line_endings_pass(self) -> None:
        """CRLF line endings from Windows-style output should still pass."""
        text = jsonl(visible_successes(6)).replace("\n", "\r\n")
        passed, message = self._eval(text)
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    def test_hidden_skipped_success_continues_without_counting(self) -> None:
        """Hidden+skipped with result=success is allowed and doesn't count visible."""
        events = visible_successes(6)
        events.insert(-1, _test_start(60))
        events.insert(-1, _test_done(60, hidden=True, skipped=True))
        passed, message = self._eval(jsonl(events))
        self.assertEqual(passed, 6)
        self.assertIn("OK", message)

    # ── Existing positive tests (evidence, leak check, CI) ──

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
