#!/usr/bin/env python3
"""#11.A: plan.json validator, ready list, and handoff resume contract."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
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
        "audited_sha": "a" * 40,
        "tasks": tasks,
    }


def _official_stream(
    names: list[str],
    *,
    hidden: set[int] | None = None,
    skipped: set[int] | None = None,
    suite_ids: list[int] | None = None,
) -> str:
    """Build a Dart JSON-reporter stream with nested testStart.test objects."""
    hidden_ids = hidden or set()
    skipped_ids = skipped or set()
    events: list[dict] = [
        {"type": "start", "time": 0, "protocolVersion": "0.1.1", "pid": 1},
    ]
    for index, name in enumerate(names, start=1):
        suite_id = suite_ids[index - 1] if suite_ids is not None else 0
        events.append(
            {
                "type": "testStart",
                "time": 0,
                "test": {
                    "id": index,
                    "name": name,
                    "suiteID": suite_id,
                    "groupIDs": [],
                    "metadata": {
                        "skip": index in skipped_ids,
                        "skipReason": None,
                    },
                },
            }
        )
        events.append(
            {
                "type": "testDone",
                "time": 1,
                "testID": index,
                "result": "success",
                "hidden": index in hidden_ids,
                "skipped": index in skipped_ids,
            }
        )
    events.append({"type": "done", "time": 2, "success": True})
    return "\n".join(json.dumps(event) for event in events)


def _completed_flutter(stdout: str) -> dict:
    return {
        "status": "completed",
        "completed": True,
        "evidence": [
            {
                "argv": ["flutter", "test", "--reporter", "json", "test/foo_test.dart"],
                "exit": 0,
                "stdout": stdout,
            }
        ],
        "unrun": [],
        "head_sha": "a" * 40,
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


class AuditedShaTest(unittest.TestCase):
    def _errors(self, data: dict, **kwargs) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validate_plan.validate_plan(
                data,
                plan_path=plan_path,
                check_artifacts=kwargs.get("check_artifacts", False),
                git_shas=kwargs.get("git_shas"),
            )
            return errors

    def test_missing_audited_sha_fails(self) -> None:
        data = _plan([_minimal_task("WS-01", 9)])
        data.pop("audited_sha", None)
        errors = self._errors(data)
        self.assertTrue(
            any("audited_sha" in error for error in errors),
            msg=errors,
        )

    def test_audited_sha_must_be_40_lowercase_hex(self) -> None:
        data = _plan([_minimal_task("WS-01", 9)])
        data["audited_sha"] = "FDA1DBC9CBAB107FE4473643A244F5319D96BB9F"
        errors = self._errors(data)
        self.assertTrue(
            any("audited_sha" in error and "40 lowercase hex" in error for error in errors),
            msg=errors,
        )

    def test_unknown_audited_sha_fails_when_git_shas_supplied(self) -> None:
        data = _plan([_minimal_task("WS-01", 9)])
        data["audited_sha"] = "a" * 40
        errors = self._errors(data, git_shas={"b" * 40})
        self.assertTrue(
            any("stale SHA" in error and "audited_sha" in error for error in errors),
            msg=errors,
        )

    def test_shipped_plan_audited_sha_is_40_lowercase_hex(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        self.assertRegex(data["audited_sha"], r"^[0-9a-f]{40}$")


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
                data,
                plan_path=plan_path,
                check_artifacts=True,
                git_shas={data["audited_sha"]},
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

    def test_completed_handoff_exit_1_is_not_complete(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [{"exit": 1}],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("exit" in error and "cannot complete" in error for error in errors),
            msg=errors,
        )

    def test_completed_handoff_all_skipped_is_not_complete(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [{"exit": 0, "executed": 0, "skipped": 12}],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("executed" in error or "skipped" in error for error in errors),
            msg=errors,
        )

    def test_completed_handoff_string_evidence_is_not_a_report(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": ["not a test report"],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(any("not a test report" in error for error in errors), msg=errors)

    def test_completed_handoff_missing_head_sha_fails(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [{"exit": 0}],
                "unrun": [],
            }
        )
        self.assertTrue(any("head_sha" in error for error in errors), msg=errors)

    def test_completed_handoff_zero_exit_reports_pass(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [{"exit": 0, "argv": ["python3", "tool/workshop/probe.py"]}],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertEqual(errors, [])

    def test_flutter_skip_only_json_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps({"type": "testDone", "result": "skipped"}),
                json.dumps({"type": "testDone", "result": "skipped"}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("executed" in error or "unknown" in error for error in errors),
            msg=errors,
        )

    def test_flutter_unknown_counts_cannot_complete(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": "All tests passed!",
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(any("unknown" in error for error in errors), msg=errors)

    def test_flutter_json_success_counts_as_executed(self) -> None:
        stdout = _official_stream(["coolant temperature: A-40"])
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertEqual(errors, [])

    def test_flutter_json_without_case_ids_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps({"type": "testDone", "result": "success"}),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("case" in error for error in errors),
            msg=errors,
        )

    def test_flutter_json_hidden_test_is_not_a_case_id(self) -> None:
        stdout = _official_stream(
            ["loading /foo_test.dart", "coolant temperature: A-40"],
            hidden={1},
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertEqual(errors, [])
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            ["coolant temperature: A-40"],
        )

    def test_flutter_json_idless_test_and_done_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {"type": "test", "name": "coolant temperature: A-40"}
                ),
                json.dumps({"type": "testDone", "result": "success"}),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("case" in error for error in errors),
            msg=errors,
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))

    def test_flutter_json_skipped_flag_is_not_executed(self) -> None:
        stdout = _official_stream(
            ["coolant temperature: A-40"],
            skipped={1},
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("executed" in error or "skipped" in error for error in errors),
            msg=errors,
        )
        self.assertEqual(validate_plan.parse_flutter_counts(stdout), (0, 1))
        self.assertEqual(validate_plan.parse_flutter_case_ids(stdout), [])

    def test_flutter_json_without_done_cannot_complete(self) -> None:
        stdout = json.dumps({"type": "testDone", "result": "success"})
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("incomplete" in error or "truncated" in error for error in errors),
            msg=errors,
        )

    def test_flutter_json_reporter_argv_empty_stdout_cannot_complete(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": [
                            "flutter",
                            "test",
                            "--reporter",
                            "json",
                            "test/foo_test.dart",
                        ],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "stdout": "",
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("incomplete" in error for error in errors),
            msg=errors,
        )

    def test_flutter_json_done_then_test_done_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps({"type": "testDone", "result": "success"}),
                json.dumps({"type": "done", "success": True}),
                json.dumps({"type": "testDone", "result": "success"}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("incomplete" in error for error in errors),
            msg=errors,
        )

    def test_flutter_json_done_success_false_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps({"type": "testDone", "result": "success"}),
                json.dumps({"type": "done", "success": False}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("incomplete" in error for error in errors),
            msg=errors,
        )

    def test_flutter_json_done_then_error_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps({"type": "testDone", "result": "success"}),
                json.dumps({"type": "done", "success": True}),
                json.dumps({"type": "error", "error": "Exception"}),
            ]
        )
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("incomplete" in error for error in errors),
            msg=errors,
        )

    def test_completed_handoff_truncated_report_cannot_complete(self) -> None:
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["python3", "tool/workshop/probe.py"],
                        "exit": 0,
                        "executed": 4,
                        "truncated": True,
                        "stdout": "x" * 50,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("truncated" in error for error in errors),
            msg=errors,
        )

    def test_flutter_truncated_json_cannot_complete_even_with_counts(self) -> None:
        stdout = json.dumps({"type": "testDone", "result": "success"})
        errors = validate_plan.validate_handoff(
            {
                "status": "completed",
                "completed": True,
                "evidence": [
                    {
                        "argv": ["flutter", "test", "test/foo_test.dart"],
                        "exit": 0,
                        "executed": 1,
                        "skipped": 0,
                        "truncated": True,
                        "stdout": stdout,
                    }
                ],
                "unrun": [],
                "head_sha": "a" * 40,
            }
        )
        self.assertTrue(
            any("truncated" in error for error in errors),
            msg=errors,
        )

    def test_official_testStart_success_is_accepted(self) -> None:
        stdout = _official_stream(["coolant temperature: A-40"])
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            ["coolant temperature: A-40"],
        )
        self.assertEqual(validate_plan.parse_flutter_counts(stdout), (1, 0))

    def test_invented_top_level_test_event_cannot_stand_in_for_testStart(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "test",
                        "id": 1,
                        "name": "coolant temperature: A-40",
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 1, "result": "success"}
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(
            any("case" in error for error in errors),
            msg=errors,
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))

    def test_official_hidden_testStart_is_not_a_case_id(self) -> None:
        stdout = _official_stream(
            ["loading /foo_test.dart", "coolant temperature: A-40"],
            hidden={1},
        )
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            ["coolant temperature: A-40"],
        )

    def test_same_name_in_different_suites_keeps_both_executions(self) -> None:
        stdout = _official_stream(
            ["smoke", "smoke"],
            suite_ids=[0, 1],
        )
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            ["smoke", "smoke"],
        )
        self.assertEqual(validate_plan.parse_flutter_counts(stdout), (2, 0))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)

    def test_duplicate_terminal_id_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 1, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 1, "result": "success"}
                ),
                json.dumps(
                    {"type": "testDone", "testID": 1, "result": "success"}
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_testStart_without_matching_testDone_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 1, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 1, "result": "success"}
                ),
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 2, "name": "omitted", "suiteID": 0},
                    }
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        self.assertEqual(validate_plan.parse_flutter_counts(stdout), (1, 0))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_hidden_testStart_still_requires_a_terminal_event(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {
                            "id": 1,
                            "name": "loading /foo_test.dart",
                            "suiteID": 0,
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 2, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 2, "result": "success"}
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_unknown_terminal_id_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 1, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 99, "result": "success"}
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_boolean_test_id_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": True, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {
                        "type": "testDone",
                        "testID": True,
                        "result": "success",
                    }
                ),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_malformed_json_object_line_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 1, "name": "smoke", "suiteID": 0},
                    }
                ),
                '{"type":"testDone","testID":1',
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(
            any(
                "case" in error or "incomplete" in error or "unknown" in error
                for error in errors
            ),
            msg=errors,
        )

    def test_error_after_testDone_before_done_cannot_complete(self) -> None:
        stdout = "\n".join(
            [
                json.dumps(
                    {
                        "type": "testStart",
                        "test": {"id": 1, "name": "smoke", "suiteID": 0},
                    }
                ),
                json.dumps(
                    {"type": "testDone", "testID": 1, "result": "success"}
                ),
                json.dumps({"type": "error", "testID": 1, "error": "late"}),
                json.dumps({"type": "done", "success": True}),
            ]
        )
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertTrue(any("case" in error for error in errors), msg=errors)

    def test_captured_official_success_fixture_is_accepted(self) -> None:
        fixture = ROOT / "test" / "tool" / "fixtures" / "official-success.jsonl"
        stdout = fixture.read_text(encoding="utf-8")
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            ["independent reporter success"],
        )

    def test_captured_pinned_sdk_fnv1a64_reporter_is_accepted(self) -> None:
        fixture = (
            ROOT / "test" / "tool" / "fixtures" / "fnv1a64_reporter_capture.jsonl"
        )
        stdout = fixture.read_text(encoding="utf-8")
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            [
                "FNV-1a 64 preserves canonical vectors",
                "FNV-1a 64 is invariant across arbitrary stream chunks",
            ],
        )
        self.assertEqual(validate_plan.parse_flutter_counts(stdout), (2, 0))

    def test_captured_failing_reporter_cannot_complete_even_with_counts(self) -> None:
        fixture = ROOT / "test" / "tool" / "fixtures" / "reporter_fail_capture.jsonl"
        stdout = fixture.read_text(encoding="utf-8")
        payload = _completed_flutter(stdout)
        payload["evidence"][0]["executed"] = 1
        payload["evidence"][0]["skipped"] = 0
        payload["evidence"][0]["exit"] = 0
        errors = validate_plan.validate_handoff(payload)
        self.assertTrue(errors, msg=errors)
        self.assertIsNone(validate_plan.parse_flutter_case_ids(stdout))


def _pinned_flutter() -> Path | None:
    pinned = Path.home() / "fvm" / "versions" / "3.47.0" / "bin" / "flutter"
    if pinned.is_file() and os.access(pinned, os.X_OK):
        return pinned
    found = shutil.which("flutter")
    return Path(found) if found else None


class PinnedSdkReporterCaptureTest(unittest.TestCase):
    """Run the pinned SDK. Skip only when that binary is absent."""

    flutter: Path | None

    @classmethod
    def setUpClass(cls) -> None:
        cls.flutter = _pinned_flutter()

    def test_live_fnv1a64_json_reporter_completes_handoff(self) -> None:
        if self.flutter is None:
            self.skipTest("pinned Flutter SDK is not available")
        proc = subprocess.run(
            [
                str(self.flutter),
                "test",
                "--reporter",
                "json",
                "test/fnv1a64_test.dart",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, msg=proc.stderr[-2000:])
        stdout = proc.stdout
        self.assertEqual(
            validate_plan.parse_flutter_case_ids(stdout),
            [
                "FNV-1a 64 preserves canonical vectors",
                "FNV-1a 64 is invariant across arbitrary stream chunks",
            ],
        )
        errors = validate_plan.validate_handoff(_completed_flutter(stdout))
        self.assertEqual(errors, [], msg=errors)

    def test_live_failing_reporter_cannot_complete(self) -> None:
        if self.flutter is None:
            self.skipTest("pinned Flutter SDK is not available")
        proc = subprocess.run(
            [
                str(self.flutter),
                "test",
                "--reporter",
                "json",
                "tool/workshop/fixtures/reporter_fail_test.dart",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(proc.returncode, 0)
        payload = _completed_flutter(proc.stdout)
        payload["evidence"][0]["exit"] = proc.returncode
        payload["evidence"][0]["executed"] = 1
        payload["evidence"][0]["skipped"] = 0
        errors = validate_plan.validate_handoff(payload)
        self.assertTrue(errors, msg=errors)


class FlutterAllowlistTest(unittest.TestCase):
    def _errors(self, commands: list) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            plan_path = Path(tmp) / "tool" / "workshop" / "plan.json"
            plan_path.parent.mkdir(parents=True)
            data = _plan(
                [_minimal_task("WS-01", 9, commands=commands, writable=["test/"])]
            )
            plan_path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validate_plan.validate_plan(
                data, plan_path=plan_path, check_artifacts=False
            )
            return errors

    def test_arbitrary_flutter_option_is_still_rejected(self) -> None:
        errors = self._errors(
            [["flutter", "test", "--release", "test/foo_test.dart"]]
        )
        self.assertTrue(any("not allowlisted" in error for error in errors), msg=errors)

    def test_reporter_json_is_allowlisted(self) -> None:
        errors = self._errors(
            [["flutter", "test", "test/foo_test.dart", "--reporter", "json"]]
        )
        self.assertEqual(errors, [])

    def test_documented_rig_journey_command_is_allowlisted(self) -> None:
        errors = self._errors(
            [
                [
                    "flutter",
                    "test",
                    "integration_test/localization_journey_test.dart",
                    "--flavor",
                    "rig",
                    "--dart-define",
                    "TELLTALE_TEST_RIG=true",
                    "-d",
                    "emulator-5554",
                ]
            ]
        )
        self.assertEqual(errors, [])

    def test_field_flavor_is_rejected(self) -> None:
        errors = self._errors(
            [
                [
                    "flutter",
                    "test",
                    "integration_test/localization_journey_test.dart",
                    "--flavor",
                    "field",
                    "--dart-define",
                    "TELLTALE_TEST_RIG=true",
                    "-d",
                    "emulator-5554",
                ]
            ]
        )
        self.assertTrue(any("flavor" in error for error in errors), msg=errors)

    def test_rig_without_device_is_rejected(self) -> None:
        errors = self._errors(
            [
                [
                    "flutter",
                    "test",
                    "integration_test/localization_journey_test.dart",
                    "--flavor",
                    "rig",
                    "--dart-define",
                    "TELLTALE_TEST_RIG=true",
                ]
            ]
        )
        self.assertTrue(any("explicit-test-device" in error for error in errors), msg=errors)


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


class CampaignQueueTest(unittest.TestCase):
    def test_shipped_seed_validates_without_campaign(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        completed = subprocess.run(
            [sys.executable, str(ROOT / "tool" / "workshop" / "validate_plan.py"), str(path)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, msg=completed.stderr)

    def test_shipped_seed_cannot_be_a_campaign(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        errors, _ = validate_plan.validate_plan(
            data, plan_path=path, check_artifacts=False, campaign=True
        )
        self.assertTrue(
            any("required_evidence" in error for error in errors),
            msg=errors,
        )
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tool" / "workshop" / "validate_plan.py"),
                str(path),
                "--campaign",
                "--no-artifacts",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("required_evidence", completed.stderr)

    def test_software_empty_evidence_fails_campaign(self) -> None:
        errors, _ = validate_plan.validate_plan(
            _plan([_minimal_task("WS-01", 9)]),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertTrue(
            any("WS-01: campaign software task needs required_evidence" in error for error in errors),
            msg=errors,
        )

    def test_blocked_task_may_keep_empty_evidence_in_campaign(self) -> None:
        data = _plan(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[],
                    blockers=["needs a licensed adapter"],
                )
            ]
        )
        errors, _ = validate_plan.validate_plan(
            data,
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(
            data["tasks"][0]["hardware_or_license_blockers"],
            ["needs a licensed adapter"],
        )

    def test_campaign_evidence_needs_path_and_sha256(self) -> None:
        errors, _ = validate_plan.validate_plan(
            _plan(
                [
                    _minimal_task(
                        "WS-01",
                        9,
                        evidence=[{"path": "docs/workshop/capabilities.json"}],
                    )
                ]
            ),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertTrue(
            any("sha256" in error for error in errors),
            msg=errors,
        )

    def test_campaign_accepts_path_and_sha256_without_opening_artifacts(self) -> None:
        errors, ready = validate_plan.validate_plan(
            _plan(
                [
                    _minimal_task(
                        "WS-01",
                        9,
                        evidence=[
                            {
                                "path": "docs/workshop/capabilities.json",
                                "sha256": "a" * 64,
                            }
                        ],
                    )
                ]
            ),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(ready, ["WS-01"])

    def test_campaign_optional_only_evidence_is_not_enough(self) -> None:
        errors, _ = validate_plan.validate_plan(
            _plan(
                [
                    _minimal_task(
                        "WS-01",
                        9,
                        evidence=[
                            {
                                "path": "missing.json",
                                "sha256": "a" * 64,
                                "required": False,
                            }
                        ],
                    )
                ]
            ),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertTrue(
            any("required evidence" in error for error in errors),
            msg=errors,
        )

    def test_campaign_one_required_artifact_allows_optional_peers(self) -> None:
        errors, ready = validate_plan.validate_plan(
            _plan(
                [
                    _minimal_task(
                        "WS-01",
                        9,
                        evidence=[
                            {
                                "path": "docs/workshop/capabilities.json",
                                "sha256": "a" * 64,
                            },
                            {
                                "path": "missing.json",
                                "sha256": "b" * 64,
                                "required": False,
                            },
                        ],
                    )
                ]
            ),
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(ready, ["WS-01"])

    def test_campaign_completed_blocked_task_is_not_pass(self) -> None:
        data = _plan(
            [
                _minimal_task(
                    "WS-01",
                    9,
                    commands=[],
                    blockers=["needs a licensed adapter"],
                    status="completed",
                ),
                _minimal_task(
                    "WS-02",
                    10,
                    depends_on=[9],
                    evidence=[
                        {
                            "path": "docs/workshop/capabilities.json",
                            "sha256": "a" * 64,
                        }
                    ],
                ),
            ]
        )
        errors, ready = validate_plan.validate_plan(
            data,
            plan_path=ROOT / "tool" / "workshop" / "plan.json",
            check_artifacts=False,
            campaign=True,
        )
        self.assertTrue(
            any(
                "WS-01" in error and "cannot be completed" in error
                for error in errors
            ),
            msg=errors,
        )
        self.assertNotIn("WS-02", ready)


class CurrentCampaignTest(unittest.TestCase):
    def test_shipped_campaign_validates_with_real_fixture_hashes(self) -> None:
        path = ROOT / "tool" / "workshop" / "campaign.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        errors, ready = validate_plan.validate_plan(
            data, plan_path=path, check_artifacts=True, campaign=True
        )
        self.assertEqual(errors, [], msg=errors)
        self.assertEqual(ready, ["CURRENT-278"])
        self.assertRegex(str(data.get("audited_sha") or ""), r"^[0-9a-f]{40}$")
        self.assertNotIn("base_sha", data["tasks"][0])
        self.assertNotEqual(
            path.resolve(),
            (ROOT / "tool" / "workshop" / "plan.json").resolve(),
        )

    def test_seed_plan_is_still_not_a_campaign(self) -> None:
        path = ROOT / "tool" / "workshop" / "plan.json"
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tool" / "workshop" / "validate_plan.py"),
                str(path),
                "--campaign",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("required_evidence", completed.stderr)

    def test_assert_official_reporter_exits_zero(self) -> None:
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tool" / "workshop" / "assert_official_reporter.py"),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, msg=completed.stderr)
        self.assertIn("invented rejected", completed.stdout)


if __name__ == "__main__":
    unittest.main()

