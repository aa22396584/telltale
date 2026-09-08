#!/usr/bin/env python3
"""#11.B: run_task.py executes allowlisted argv and writes an honest handoff."""
from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "workshop"))

import run_task  # noqa: E402
import validate_plan  # noqa: E402


def _ok_script() -> str:
    return "print('ok')\n"


def _fail_script() -> str:
    return "raise SystemExit(3)\n"


def _secret_script() -> str:
    return (
        "import os, sys\n"
        "sys.stdout.write('TOKEN=' + os.environ.get('GH_TOKEN', '') + '\\n')\n"
        "sys.stdout.write('AWS=' + os.environ.get('AWS_SECRET_ACCESS_KEY', '') + '\\n')\n"
    )


def _plan(tmp: Path, *, commands: list, status: str = "pending", extra: list | None = None) -> Path:
    workshop = tmp / "tool" / "workshop"
    workshop.mkdir(parents=True)
    script = workshop / "probe.py"
    script.write_text(_ok_script(), encoding="utf-8")
    tasks = [
        {
            "id": "WS-01",
            "issue": 1,
            "issue_url": "https://github.com/ImL1s/telltale/issues/1",
            "priority": "P0",
            "status": status,
            "depends_on": [],
            "writable_dirs": ["docs/workshop/ws/ws-01/"],
            "run_commands": commands,
            "required_evidence": [],
            "hardware_or_license_blockers": [],
            "reviewer_role": "implementation",
            "done_criteria": "named tests pass",
        }
    ]
    if extra:
        tasks.extend(extra)
    payload = {
        "schemaVersion": 1,
        "policy": "USABILITY-R2",
        "repository": "ImL1s/telltale",
        "tasks": tasks,
    }
    path = workshop / "plan.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class RunTaskTest(unittest.TestCase):
    def test_success_writes_completed_handoff(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(_ok_script(), encoding="utf-8")
            handoff = tmp / "handoff.json"
            code = run_task.run_task(plan, "WS-01", handoff_path=handoff, timeout=10)
            self.assertEqual(code, 0)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(validate_plan.validate_handoff(data), [])
            self.assertTrue(data["completed"])
            self.assertEqual(data["status"], "completed")
            self.assertEqual(data["unrun"], [])
            self.assertEqual(data["results"][0]["exit"], 0)

    def test_failed_command_cannot_claim_completed(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(_fail_script(), encoding="utf-8")
            handoff = tmp / "handoff.json"
            code = run_task.run_task(plan, "WS-01", handoff_path=handoff, timeout=10)
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(validate_plan.validate_handoff(data), [])
            self.assertIs(data["completed"], False)
            self.assertEqual(data["status"], "failed")
            self.assertTrue(data["failed"])

    def test_not_ready_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            extra = [
                {
                    "id": "WS-02",
                    "issue": 2,
                    "issue_url": "https://github.com/ImL1s/telltale/issues/2",
                    "priority": "P1",
                    "status": "pending",
                    "depends_on": [1],
                    "writable_dirs": ["docs/workshop/ws/ws-02/"],
                    "run_commands": [["python3", "tool/workshop/probe.py"]],
                    "required_evidence": [],
                    "hardware_or_license_blockers": [],
                    "reviewer_role": "implementation",
                    "done_criteria": "named tests pass",
                }
            ]
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
                extra=extra,
            )
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(plan, "WS-02", handoff_path=tmp / "h.json", timeout=5)
            self.assertIn("not ready", str(raised.exception))

    def test_lease_conflict_with_in_progress_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            extra = [
                {
                    "id": "WS-02",
                    "issue": 2,
                    "issue_url": "https://github.com/ImL1s/telltale/issues/2",
                    "priority": "P1",
                    "status": "in_progress",
                    "depends_on": [],
                    "writable_dirs": ["docs/workshop/ws/ws-01/"],
                    "run_commands": [["python3", "tool/workshop/probe.py"]],
                    "required_evidence": [],
                    "hardware_or_license_blockers": [],
                    "reviewer_role": "implementation",
                    "done_criteria": "named tests pass",
                }
            ]
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
                extra=extra,
            )
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(plan, "WS-01", handoff_path=tmp / "h.json", timeout=5)
            self.assertIn("not ready", str(raised.exception))

    def test_secret_env_is_not_forwarded(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(
                _secret_script(), encoding="utf-8"
            )
            handoff = tmp / "handoff.json"
            env = {
                "PATH": os.environ.get("PATH", "/usr/bin"),
                "HOME": os.environ.get("HOME", str(tmp)),
                "GH_TOKEN": "secret-token",
                "AWS_SECRET_ACCESS_KEY": "secret-aws",
            }
            code = run_task.run_task(
                plan, "WS-01", handoff_path=handoff, timeout=10, env=env
            )
            self.assertEqual(code, 0)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            stdout = data["results"][0]["stdout"]
            self.assertIn("TOKEN=\n", stdout)
            self.assertIn("AWS=\n", stdout)
            self.assertNotIn("secret-token", stdout)
            self.assertNotIn("secret-aws", stdout)

    def test_dry_run_does_not_mark_completed(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan, "WS-01", handoff_path=handoff, timeout=5, dry_run=True
            )
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertIs(data["completed"], False)
            self.assertEqual(data["status"], "in_progress")
            self.assertTrue(data["unrun"])


if __name__ == "__main__":
    unittest.main()
