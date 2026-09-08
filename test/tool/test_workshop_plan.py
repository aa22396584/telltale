#!/usr/bin/env python3
"""#11.A: plan.json validator, ready list, and handoff resume contract."""
from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "workshop"))

import validate_plan  # noqa: E402


def _minimal_task(
    ident: str,
    issue: int,
    *,
    depends_on: list[int] | None = None,
    writable: list[str] | None = None,
    commands: list | None = None,
    blockers: list | None = None,
    status: str = "pending",
    evidence: list | None = None,
    sha: str | None = None,
    done: str = "named tests pass",
    reviewer: str = "implementation",
) -> dict:
    task = {
        "id": ident,
        "issue": issue,
        "issue_url": f"https://github.com/ImL1s/telltale/issues/{issue}",
        "priority": "P1",
        "status": status,
        "depends_on": depends_on or [],
        "writable_dirs": writable or [f"docs/workshop/{ident.lower()}/"],
        "run_commands": commands
        if commands is not None
        else [
            [
                "python3",
                "tool/workshop/validate_capabilities.py",
                "docs/workshop/capabilities.json",
            ]
        ],
        "required_evidence": evidence or [],
        "hardware_or_license_blockers": blockers or [],
        "reviewer_role": reviewer,
        "done_criteria": done,
    }
    if sha is not None:
        task["base_sha"] = sha
    return task


def _plan(tasks: list[dict]) -> dict:
    return {
        "schemaVersion": 1,
        "policy": "USABILITY-R2",
        "repository": "ImL1s/telltale",
        "tasks": tasks,
    }


class BundledPlanTest(unittest.TestCase):
    def test_shipped_plan_validates_and_ready_is_ws01_ws02(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        errors, ready = validate_plan.validate_plan(
            data, plan_path=path, check_artifacts=True
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(ready, ["WS-01", "WS-02"])
        issues = [task["issue"] for task in data["tasks"]]
        self.assertEqual(len(issues), len(set(issues)))
        self.assertEqual(len(data["tasks"]), 29)
        self.assertEqual(data["policy"], "USABILITY-R2")
        ws08 = next(task for task in data["tasks"] if task["id"] == "WS-08")
        self.assertEqual(ws08["depends_on"], [9])
        ws20 = next(task for task in data["tasks"] if task["id"] == "WS-20")
        self.assertTrue(ws20["hardware_or_license_blockers"])
        self.assertEqual(ws20["run_commands"], [])
        ws27 = next(task for task in data["tasks"] if task["id"] == "WS-27")
        writable = [item.rstrip("/") for item in ws27["writable_dirs"]]
        self.assertIn("lib/ui", writable)
        self.assertIn("test", writable)
        flutter = ws27["run_commands"][0]
        self.assertEqual(Path(flutter[0]).name, "flutter")
        self.assertEqual(flutter[1], "test")
        self.assertIn("test/workshop/ui/datum_status_badge_test.dart", flutter)
        self.assertIn("test/derived_strip_test.dart", flutter)

    def test_cli_ok_on_shipped_plan(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        code = validate_plan.main(["validate_plan.py", str(path)])
        self.assertEqual(code, 0)


class GraphAndSchemaTest(unittest.TestCase):
    def _errors(self, tasks, **kwargs) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(tasks)
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validate_plan.validate_plan(
                data,
                plan_path=plan_path,
                check_artifacts=kwargs.get("check_artifacts", False),
                git_shas=kwargs.get("git_shas"),
            )
            return errors

    def test_duplicate_id_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task("WS-01", 9),
                _minimal_task("WS-01", 10),
            ]
        )
        self.assertTrue(any("duplicate id" in error for error in errors))

    def test_duplicate_issue_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task("WS-01", 9),
                _minimal_task("WS-02", 9),
            ]
        )
        self.assertTrue(any("duplicate issue" in error for error in errors))

    def test_missing_dependency_fails(self) -> None:
        errors = self._errors([_minimal_task("WS-03", 11, depends_on=[9])])
        self.assertTrue(any("missing dependency" in error for error in errors))

    def test_self_cycle_fails(self) -> None:
        errors = self._errors([_minimal_task("WS-01", 9, depends_on=[9])])
        self.assertTrue(any("itself" in error or "cycle" in error for error in errors))

    def test_long_cycle_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task("WS-01", 9, depends_on=[10]),
                _minimal_task("WS-02", 10, depends_on=[11]),
                _minimal_task("WS-03", 11, depends_on=[9]),
            ]
        )
        self.assertTrue(any(error.startswith("cycle:") for error in errors))

    def test_path_escape_fails(self) -> None:
        errors = self._errors(
            [_minimal_task("WS-01", 9, writable=["../../etc/passwd"])]
        )
        self.assertTrue(any("path escape" in error for error in errors))

    def test_absolute_path_fails(self) -> None:
        errors = self._errors(
            [_minimal_task("WS-01", 9, writable=["/tmp/x"])]
        )
        self.assertTrue(any("path escape" in error for error in errors))

    def test_stale_sha_fails_when_known_set_is_given(self) -> None:
        sha = "a" * 40
        errors = self._errors(
            [_minimal_task("WS-01", 9, sha=sha)],
            git_shas={"b" * 40},
        )
        self.assertTrue(any("stale SHA" in error for error in errors))

    def test_known_sha_is_accepted(self) -> None:
        sha = "a" * 40
        errors = self._errors(
            [_minimal_task("WS-01", 9, sha=sha)],
            git_shas={sha},
        )
        self.assertEqual(errors, [])

    def test_skip_as_required_pass_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    done="required tests may skip and still count as pass",
                )
            ]
        )
        self.assertTrue(any("skip" in error for error in errors))

    def test_comment_text_as_command_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[["python3", "https://github.com/ImL1s/telltale/issues/11"]],
                )
            ]
        )
        self.assertTrue(any("issue/comment" in error for error in errors))

    def test_unauthorized_script_path_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[["python3", "lib/hack.py"]],
                )
            ]
        )
        self.assertTrue(any("allowlist" in error for error in errors))

    def test_absolute_interpreter_path_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[
                        [
                            "/tmp/python3",
                            "tool/workshop/validate_plan.py",
                        ]
                    ],
                )
            ]
        )
        self.assertTrue(
            any("executable path" in error for error in errors),
            msg=errors,
        )

    def test_python_c_decoy_script_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[
                        [
                            "python3",
                            "-c",
                            "raise SystemExit('pwned')",
                            "tool/workshop/validate_plan.py",
                        ]
                    ],
                )
            ]
        )
        self.assertTrue(
            any("execution flag" in error or "-c" in error for error in errors),
            msg=errors,
        )

    def test_python_warning_option_operand_cannot_hide_c(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[
                        [
                            "python3",
                            "-W",
                            "tool/workshop/validate_plan.py",
                            "-c",
                            "raise SystemExit('pwned')",
                        ]
                    ],
                )
            ]
        )
        self.assertTrue(
            any("option" in error or "execution flag" in error for error in errors),
            msg=errors,
        )

    def test_python_m_module_fails(self) -> None:
        errors = self._errors(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[
                        [
                            "python3",
                            "-m",
                            "http.server",
                            "tool/workshop/validate_plan.py",
                        ]
                    ],
                )
            ]
        )
        self.assertTrue(
            any("execution flag" in error or "-m" in error for error in errors),
            msg=errors,
        )


class ArtifactAndHandoffTest(unittest.TestCase):
    def test_missing_artifact_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            plan_path = root / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            task = _minimal_task(
                "WS-01",
                9,
                evidence=[{"path": "docs/missing.txt", "required": True}],
            )
            data = _plan([task])
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=True
            )
            self.assertTrue(any("missing artifact" in error for error in errors))

    def test_hash_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            plan_path = root / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            artifact = root / "docs" / "note.txt"
            artifact.parent.mkdir(parents=True)
            artifact.write_text("hello\n", encoding="utf-8")
            task = _minimal_task(
                "WS-01",
                9,
                evidence=[
                    {
                        "path": "docs/note.txt",
                        "sha256": "0" * 64,
                        "required": True,
                    }
                ],
            )
            data = _plan([task])
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=True
            )
            self.assertTrue(any("hash mismatch" in error for error in errors))

    def test_matching_hash_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            plan_path = root / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            artifact = root / "docs" / "note.txt"
            artifact.parent.mkdir(parents=True)
            body = b"hello\n"
            artifact.write_bytes(body)
            digest = hashlib.sha256(body).hexdigest()
            task = _minimal_task(
                "WS-01",
                9,
                evidence=[
                    {"path": "docs/note.txt", "sha256": digest, "required": True}
                ],
            )
            data = _plan([task])
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=True
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-01"])

    def test_unfinished_handoff_cannot_claim_completed(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "in_progress",
                "completed": True,
                "unrun": ["tests"],
            }
        )
        self.assertTrue(
            any("must not be labelled completed" in error for error in errors)
        )

    def test_completed_handoff_with_unrun_fails(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": "log",
                "unrun": ["analyze"],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(any("unrun" in error for error in errors))

    def test_resume_handoff_in_progress_is_ok(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "in_progress",
                "completed": False,
                "unrun": ["analyze"],
                "next": "re-run analyze",
                "head_sha": "a" * 40,
            }
        )
        self.assertEqual(errors, [])

    def test_completed_handoff_with_false_flag_fails(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": False,
                "evidence": "log",
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("completed" in error and "true" in error.lower() for error in errors),
            msg=errors,
        )

    def test_unfinished_handoff_missing_false_flag_fails(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "in_progress",
                "unrun": ["analyze"],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("completed" in error and "false" in error.lower() for error in errors),
            msg=errors,
        )


class ReadyAndLeaseTest(unittest.TestCase):
    def test_two_disjoint_tasks_are_both_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task("WS-01", 9, writable=["docs/a/"]),
                    _minimal_task("WS-02", 10, writable=["docs/b/"]),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-01", "WS-02"])

    def test_shared_writable_dir_lease_keeps_one_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task("WS-01", 9, writable=["docs/shared/"]),
                    _minimal_task("WS-02", 10, writable=["docs/shared/"]),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-01"])

    def test_completed_dependency_unlocks_successor(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task("WS-01", 9, status="completed"),
                    _minimal_task("WS-02", 10, depends_on=[9]),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-02"])

    def test_implementation_and_review_are_distinct_roles(self) -> None:
        task_i = _minimal_task("WS-01", 9, reviewer="implementation")
        task_r = _minimal_task("WS-03", 11, reviewer="review", depends_on=[9])
        self.assertNotEqual(task_i["reviewer_role"], task_r["reviewer_role"])

    def test_in_progress_is_not_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task("WS-01", 9, status="in_progress"),
                    _minimal_task("WS-02", 10, writable=["docs/b/"]),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-02"])

    def test_in_progress_lease_blocks_lower_id_pending(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task(
                        "WS-01", 9, writable=["docs/shared/"]
                    ),
                    _minimal_task(
                        "WS-02",
                        10,
                        status="in_progress",
                        writable=["docs/shared/"],
                    ),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, [])

    def test_ancestor_writable_dirs_conflict(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [
                    _minimal_task("WS-01", 9, writable=["tool/workshop/"]),
                    _minimal_task(
                        "WS-02", 10, writable=["tool/workshop/generated/"]
                    ),
                ]
            )
            errors, ready = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            self.assertEqual(errors, [])
            self.assertEqual(ready, ["WS-01"])

    def test_stale_sha_fails_without_known_set(self) -> None:
        errors, _ = validate_plan.validate_plan(
            _plan([_minimal_task("WS-01", 9, sha="0" * 40)]),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
        )
        self.assertTrue(any("stale SHA" in error for error in errors), msg=errors)

    def test_real_head_sha_is_accepted_without_known_set(self) -> None:
        sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=ROOT,
            text=True,
        ).strip()
        errors, ready = validate_plan.validate_plan(
            _plan([_minimal_task("WS-01", 9, sha=sha)]),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(ready, ["WS-01"])


if __name__ == "__main__":
    unittest.main()
