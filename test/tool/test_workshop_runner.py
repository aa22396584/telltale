#!/usr/bin/env python3
"""#11.B: run_task.py executes allowlisted argv and writes an honest handoff."""
from __future__ import annotations

import fcntl
import hashlib
import json
import os
import subprocess
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


def _plan(
    tmp: Path,
    *,
    commands: list,
    status: str = "pending",
    extra: list | None = None,
    evidence: list | None = None,
) -> Path:
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
            "required_evidence": evidence or [],
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

    def test_review_reruns_argv_instead_of_copying_author_completed(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            code = run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5)
            self.assertEqual(code, 0)
            self.assertTrue(json.loads(author.read_text(encoding="utf-8"))["completed"])
            (tmp / "tool" / "workshop" / "probe.py").write_text(
                _fail_script(), encoding="utf-8"
            )
            code = run_task.run_task(
                plan, "WS-01", handoff_path=author, timeout=5, review=True
            )
            self.assertEqual(code, 1)
            review = author.with_name("review.json")
            data = json.loads(review.read_text(encoding="utf-8"))
            self.assertEqual(validate_plan.validate_handoff(data), [])
            self.assertIs(data["completed"], False)
            self.assertEqual(data["status"], "failed")
            self.assertEqual(data["reviewer_role"], "review")
            self.assertTrue(json.loads(author.read_text(encoding="utf-8"))["completed"])

    def test_review_dry_run_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=author,
                    timeout=5,
                    review=True,
                    dry_run=True,
                )
            self.assertIn("dry-run", str(ctx.exception))

    def test_review_without_author_handoff_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "handoff.json",
                    timeout=5,
                    review=True,
                )
            self.assertIn("handoff", str(ctx.exception).lower())

    def test_review_rejects_handoff_from_another_task(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            extra = [
                {
                    "id": "WS-02",
                    "issue": 2,
                    "issue_url": "https://github.com/ImL1s/telltale/issues/2",
                    "priority": "P1",
                    "status": "pending",
                    "depends_on": [],
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
            author = tmp / "ws01.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-02", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("does not match", str(ctx.exception))

    def test_review_refuses_overlapping_writable_dir_lease(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            data = json.loads(plan.read_text(encoding="utf-8"))
            data["tasks"].append(
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
            )
            plan.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-01", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("not ready", str(ctx.exception))

    def test_review_refuses_pending_overlapping_writable_dir(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            data = json.loads(plan.read_text(encoding="utf-8"))
            data["tasks"][0]["status"] = "completed"
            data["tasks"].append(
                {
                    "id": "WS-02",
                    "issue": 2,
                    "issue_url": "https://github.com/ImL1s/telltale/issues/2",
                    "priority": "P1",
                    "status": "pending",
                    "depends_on": [],
                    "writable_dirs": ["docs/workshop/ws/ws-01/"],
                    "run_commands": [["python3", "tool/workshop/probe.py"]],
                    "required_evidence": [],
                    "hardware_or_license_blockers": [],
                    "reviewer_role": "implementation",
                    "done_criteria": "named tests pass",
                }
            )
            plan.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-01", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("not ready", str(ctx.exception))

    def test_review_accepts_a_completed_plan_task(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            data = json.loads(plan.read_text(encoding="utf-8"))
            data["tasks"][0]["status"] = "completed"
            plan.write_text(json.dumps(data), encoding="utf-8")
            code = run_task.run_task(
                plan, "WS-01", handoff_path=author, timeout=5, review=True
            )
            self.assertEqual(code, 0)
            review = json.loads(
                author.with_name("review.json").read_text(encoding="utf-8")
            )
            self.assertEqual(validate_plan.validate_handoff(review), [])
            self.assertTrue(review["completed"])
            self.assertEqual(review["reviewer_role"], "review")

    def test_review_refuses_unfinished_dependency(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            extra = [
                {
                    "id": "WS-02",
                    "issue": 2,
                    "issue_url": "https://github.com/ImL1s/telltale/issues/2",
                    "priority": "P1",
                    "status": "completed",
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
            result = {
                "argv": ["python3", "tool/workshop/probe.py"],
                "exit": 0,
                "timed_out": False,
                "duration_s": 0.1,
                "stdout": "ok\n",
                "stderr": "",
            }
            author = tmp / "ws02.json"
            author.write_text(
                json.dumps(
                    {
                        "task": "WS-02",
                        "issue": 2,
                        "status": "completed",
                        "completed": True,
                        "failed": [],
                        "unrun": [],
                        "results": [result],
                        "evidence": [result],
                        "reviewer_role": "implementation",
                        "next": "reviewer re-runs the same argv",
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-02", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("not ready", str(ctx.exception))

    def test_review_refuses_in_progress_target(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            data = json.loads(plan.read_text(encoding="utf-8"))
            data["tasks"][0]["status"] = "in_progress"
            plan.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-01", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("not ready", str(ctx.exception))

    def test_review_refuses_blocked_target(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            author = tmp / "handoff.json"
            self.assertEqual(
                run_task.run_task(plan, "WS-01", handoff_path=author, timeout=5),
                0,
            )
            data = json.loads(plan.read_text(encoding="utf-8"))
            data["tasks"][0]["status"] = "blocked"
            plan.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(run_task.RunnerError) as ctx:
                run_task.run_task(
                    plan, "WS-01", handoff_path=author, timeout=5, review=True
                )
            self.assertIn("not ready", str(ctx.exception))

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

    def test_prefixed_credential_env_is_not_forwarded(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(
                "import os, sys\n"
                "sys.stdout.write('PY=' + os.environ.get('PYTHON_API_TOKEN', '') + '\\n')\n"
                "sys.stdout.write('AND=' + os.environ.get('ANDROID_KEYSTORE_PASSWORD', '') + '\\n')\n",
                encoding="utf-8",
            )
            handoff = tmp / "handoff.json"
            env = {
                "PATH": os.environ.get("PATH", "/usr/bin"),
                "HOME": os.environ.get("HOME", str(tmp)),
                "PYTHON_API_TOKEN": "secret-python",
                "ANDROID_KEYSTORE_PASSWORD": "secret-android",
            }
            code = run_task.run_task(
                plan, "WS-01", handoff_path=handoff, timeout=10, env=env
            )
            self.assertEqual(code, 0)
            stdout = json.loads(handoff.read_text(encoding="utf-8"))["results"][0]["stdout"]
            self.assertIn("PY=\n", stdout)
            self.assertIn("AND=\n", stdout)
            self.assertNotIn("secret-python", stdout)
            self.assertNotIn("secret-android", stdout)

    def test_live_lease_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            handoff = tmp / "other" / "handoff.json"
            lease = tmp / "docs" / "workshop" / "ws" / "ws-01" / "lease.json"
            lease.parent.mkdir(parents=True)
            fd = os.open(str(lease), os.O_CREAT | os.O_RDWR, 0o644)
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            try:
                with self.assertRaises(run_task.RunnerError) as raised:
                    run_task.run_task(plan, "WS-01", handoff_path=handoff, timeout=5)
                self.assertIn("lease held", str(raised.exception))
            finally:
                fcntl.flock(fd, fcntl.LOCK_UN)
                os.close(fd)

    def test_missing_executable_writes_failed_handoff(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            handoff = tmp / "handoff.json"
            original = run_task._resolve_executable
            run_task._resolve_executable = lambda name: "/no/such/workshop-python3"
            try:
                code = run_task.run_task(plan, "WS-01", handoff_path=handoff, timeout=5)
            finally:
                run_task._resolve_executable = original
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertIs(data["completed"], False)
            self.assertEqual(data["results"][0]["exit"], 127)

    def test_output_is_bounded_while_the_command_is_still_writing(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(
                "import sys\nsys.stdout.write('x' * 200000)\n",
                encoding="utf-8",
            )
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan, "WS-01", handoff_path=handoff, timeout=5, output_limit=50
            )
            self.assertEqual(code, 0)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(len(data["results"][0]["stdout"]), 50)
            self.assertEqual(data["results"][0]["stdout"], "x" * 50)

    def test_timeout_covers_a_descendant_that_keeps_stdout_open(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            plan = _plan(
                tmp,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (tmp / "tool" / "workshop" / "probe.py").write_text(
                "import os, sys, time\n"
                "if os.fork() == 0:\n"
                "    while True:\n"
                "        sys.stdout.write('y' * 1024)\n"
                "        sys.stdout.flush()\n"
                "        time.sleep(0.05)\n"
                "os._exit(0)\n",
                encoding="utf-8",
            )
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan, "WS-01", handoff_path=handoff, timeout=1, output_limit=50
            )
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            result = data["results"][0]
            self.assertTrue(result["timed_out"])
            self.assertLessEqual(len(result["stdout"]), 50)
            self.assertLess(result["duration_s"], 4)

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

    def test_isolate_runs_at_fixed_sha_and_does_not_reset_caller(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            (repo / "tool" / "workshop" / "probe.py").write_text(
                "print('committed')\n", encoding="utf-8"
            )
            sha = _init_git(repo)
            (repo / "tool" / "workshop" / "probe.py").write_text(
                "print('dirty')\n", encoding="utf-8"
            )
            handoff = tmp / "handoff.json"
            try:
                code = run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=handoff,
                    timeout=10,
                    isolate=True,
                    isolate_dir=worktree,
                    base_sha=sha,
                )
            finally:
                _remove_worktree(repo, worktree)
            self.assertEqual(code, 0)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(data["head_sha"], sha)
            self.assertEqual(Path(data["worktree"]).resolve(), worktree.resolve())
            self.assertIn("committed", data["results"][0]["stdout"])
            self.assertNotIn("dirty", data["results"][0]["stdout"])
            self.assertEqual(
                (repo / "tool" / "workshop" / "probe.py").read_text(encoding="utf-8"),
                "print('dirty')\n",
            )

    def test_isolate_refuses_an_existing_path(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            worktree.mkdir()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            _init_git(repo)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                )
            self.assertIn("refusing to reset", str(raised.exception))

    def test_dry_run_isolate_does_not_create_a_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            _init_git(repo)
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
            )
            self.assertEqual(code, 1)
            self.assertFalse(worktree.exists())
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertNotIn("worktree", data)
            self.assertIs(data["completed"], False)
            self.assertEqual(len(data.get("head_sha") or ""), 40)

    def test_dry_run_isolate_rejects_a_missing_base_sha(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            _init_git(repo)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                    dry_run=True,
                    base_sha="0" * 40,
                )
            self.assertFalse(worktree.exists())
            self.assertIn("stale or missing SHA", str(raised.exception))

    def test_isolate_rejects_evidence_missing_from_the_fixed_sha(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            payload = b"caller-only\n"
            digest = hashlib.sha256(payload).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_bytes(payload)
            try:
                with self.assertRaises(run_task.RunnerError) as raised:
                    run_task.run_task(
                        plan,
                        "WS-01",
                        handoff_path=tmp / "h.json",
                        timeout=5,
                        isolate=True,
                        isolate_dir=worktree,
                        base_sha=sha,
                    )
            finally:
                _remove_worktree(repo, worktree)
            self.assertIn("isolated checkout evidence failed", str(raised.exception))

    def test_isolate_accepts_evidence_present_only_on_the_fixed_sha(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_text("committed-proof\n", encoding="utf-8")
            digest = hashlib.sha256(proof.read_bytes()).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            proof.unlink()
            handoff = tmp / "handoff.json"
            try:
                code = run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=handoff,
                    timeout=10,
                    isolate=True,
                    isolate_dir=worktree,
                    base_sha=sha,
                )
            finally:
                _remove_worktree(repo, worktree)
            self.assertEqual(code, 0)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertTrue(data["completed"])

    def test_isolate_uses_the_caller_evidence_spec(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            sha = _init_git(repo)
            digest = hashlib.sha256(b"required-later\n").hexdigest()
            payload = json.loads(plan.read_text(encoding="utf-8"))
            payload["tasks"][0]["required_evidence"] = [
                {"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest},
            ]
            plan.write_text(json.dumps(payload), encoding="utf-8")
            try:
                with self.assertRaises(run_task.RunnerError) as raised:
                    run_task.run_task(
                        plan,
                        "WS-01",
                        handoff_path=tmp / "h.json",
                        timeout=5,
                        isolate=True,
                        isolate_dir=worktree,
                        base_sha=sha,
                    )
            finally:
                _remove_worktree(repo, worktree)
            self.assertIn("isolated checkout evidence failed", str(raised.exception))

    def test_dry_run_isolate_rejects_caller_evidence_missing_from_sha(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            payload = b"caller-only\n"
            digest = hashlib.sha256(payload).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_bytes(payload)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                    dry_run=True,
                    base_sha=sha,
                )
            self.assertFalse(worktree.exists())
            self.assertIn("isolated checkout evidence failed", str(raised.exception))

    def test_dry_run_isolate_accepts_sha_evidence_missing_from_caller(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_text("committed-proof\n", encoding="utf-8")
            digest = hashlib.sha256(proof.read_bytes()).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            proof.unlink()
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
                base_sha=sha,
            )
            self.assertFalse(worktree.exists())
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(data["head_sha"], sha)
            self.assertNotIn("worktree", data)
            self.assertIs(data["completed"], False)

    def test_dry_run_isolate_rejects_tree_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_text("committed-proof\n", encoding="utf-8")
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01"}],
            )
            sha = _init_git(repo)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                    dry_run=True,
                    base_sha=sha,
                )
            self.assertFalse(worktree.exists())
            self.assertIn("isolated checkout evidence failed", str(raised.exception))
            self.assertIn("missing artifact", str(raised.exception))

    def test_dry_run_isolate_rejects_malformed_optional_digest(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[
                    {
                        "path": "docs/workshop/ws/ws-01/proof.txt",
                        "sha256": "bad",
                        "required": False,
                    }
                ],
            )
            sha = _init_git(repo)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                    dry_run=True,
                    base_sha=sha,
                )
            self.assertFalse(worktree.exists())
            self.assertIn("isolated checkout evidence failed", str(raised.exception))
            self.assertIn("evidence sha256 must be 64 hex", str(raised.exception))

    def test_dry_run_isolate_follows_symlink_blob_to_file_contents(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof_dir = repo / "docs" / "workshop" / "ws" / "ws-01"
            proof_dir.mkdir(parents=True)
            actual = proof_dir / "actual.txt"
            actual.write_text("committed-proof\n", encoding="utf-8")
            (proof_dir / "proof.txt").symlink_to("actual.txt")
            digest = hashlib.sha256(actual.read_bytes()).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
                base_sha=sha,
            )
            self.assertFalse(worktree.exists())
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(data["head_sha"], sha)

    def test_dry_run_isolate_rejects_dangling_symlink_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof_dir = repo / "docs" / "workshop" / "ws" / "ws-01"
            proof_dir.mkdir(parents=True)
            (proof_dir / "proof.txt").symlink_to("missing.txt")
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt"}],
            )
            sha = _init_git(repo)
            with self.assertRaises(run_task.RunnerError) as raised:
                run_task.run_task(
                    plan,
                    "WS-01",
                    handoff_path=tmp / "h.json",
                    timeout=5,
                    isolate=True,
                    isolate_dir=worktree,
                    dry_run=True,
                    base_sha=sha,
                )
            self.assertFalse(worktree.exists())
            self.assertIn("isolated checkout evidence failed", str(raised.exception))
            self.assertIn("missing artifact", str(raised.exception))

    def test_dry_run_isolate_follows_symlinked_directory_components(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            actual = repo / "docs" / "workshop" / "ws" / "actual"
            actual.mkdir(parents=True)
            proof = actual / "proof.txt"
            proof.write_text("committed-proof\n", encoding="utf-8")
            (repo / "docs" / "workshop" / "ws" / "ws-01").symlink_to("actual")
            digest = hashlib.sha256(proof.read_bytes()).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
                base_sha=sha,
            )
            self.assertFalse(worktree.exists())
            self.assertEqual(code, 1)
            data = json.loads(handoff.read_text(encoding="utf-8"))
            self.assertEqual(data["head_sha"], sha)

    def test_dry_run_isolate_follows_symlink_target_with_trailing_space(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof_dir = repo / "docs" / "workshop" / "ws" / "ws-01"
            proof_dir.mkdir(parents=True)
            actual = proof_dir / "actual.txt "
            actual.write_text("committed-proof\n", encoding="utf-8")
            (proof_dir / "proof.txt").symlink_to("actual.txt ")
            digest = hashlib.sha256(actual.read_bytes()).hexdigest()
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
                evidence=[{"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}],
            )
            sha = _init_git(repo)
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
                base_sha=sha,
            )
            self.assertFalse(worktree.exists())
            self.assertEqual(code, 1)

    def test_dry_run_isolate_hashes_ident_filtered_checkout_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            repo = tmp / "repo"
            worktree = tmp / "wt"
            proof = repo / "docs" / "workshop" / "ws" / "ws-01" / "proof.txt"
            proof.parent.mkdir(parents=True)
            proof.write_text("$Id$\n", encoding="utf-8")
            (repo / ".gitattributes").write_text(
                "docs/workshop/ws/ws-01/proof.txt ident\n", encoding="utf-8"
            )
            plan = _plan(
                repo,
                commands=[["python3", "tool/workshop/probe.py"]],
            )
            sha = _init_git(repo)
            expanded = subprocess.check_output(
                [
                    "git",
                    "-C",
                    str(repo),
                    "cat-file",
                    "--filters",
                    f"{sha}:docs/workshop/ws/ws-01/proof.txt",
                ]
            )
            self.assertNotEqual(expanded, b"$Id$\n")
            digest = hashlib.sha256(expanded).hexdigest()
            payload = json.loads(plan.read_text(encoding="utf-8"))
            payload["tasks"][0]["required_evidence"] = [
                {"path": "docs/workshop/ws/ws-01/proof.txt", "sha256": digest}
            ]
            plan.write_text(json.dumps(payload), encoding="utf-8")
            handoff = tmp / "handoff.json"
            code = run_task.run_task(
                plan,
                "WS-01",
                handoff_path=handoff,
                timeout=5,
                isolate=True,
                isolate_dir=worktree,
                dry_run=True,
                base_sha=sha,
            )
            self.assertFalse(worktree.exists())
            self.assertEqual(code, 1)


def _init_git(root: Path) -> str:
    subprocess.run(["git", "init"], cwd=root, check=True, capture_output=True)
    subprocess.run(
        ["git", "-C", str(root), "config", "user.email", "workshop@example.test"],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        ["git", "-C", str(root), "config", "user.name", "workshop"],
        check=True,
        capture_output=True,
    )
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True, capture_output=True)
    subprocess.run(
        ["git", "-C", str(root), "commit", "-m", "init"],
        check=True,
        capture_output=True,
    )
    return subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        text=True,
    ).strip()


def _remove_worktree(repo: Path, dest: Path) -> None:
    if not dest.exists():
        return
    subprocess.run(
        ["git", "-C", str(repo), "worktree", "remove", "--force", str(dest)],
        capture_output=True,
        check=False,
    )


if __name__ == "__main__":
    unittest.main()
