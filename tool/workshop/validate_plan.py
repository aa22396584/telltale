#!/usr/bin/env python3
"""Validate tool/workshop/plan.json (issue #11.A).

Fail closed on missing dependency, cycle, duplicate id, path escape,
stale SHA, missing artifact, hash mismatch, and skip-as-required-pass.

Prints a read-only ready list. Does not execute task commands.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ALLOWED_STATUS = {"pending", "in_progress", "completed", "blocked"}
ALLOWED_PRIORITY = {"P0", "P1", "P2", "P3"}
ALLOWED_REVIEWER = {"implementation", "review"}
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_COMMAND_NAMES = {"python3", "bash", "flutter"}
ALLOWED_SCRIPT_PREFIXES = (
    "tool/workshop/",
    "test/tool/",
    "tool/oracle_guard/",
)
ALLOWED_FLUTTER_TEST_PREFIXES = (
    "test/",
    "integration_test/",
)

# Issue #11: never treat GitHub issue/comment text as a shell command.
FORBIDDEN_COMMAND_SUBSTRINGS = ("http://", "https://", "`", "$(", "${")


class PlanError(Exception):
    pass


def _as_list(value: Any, name: str) -> list[Any]:
    if not isinstance(value, list):
        raise PlanError(f"{name} must be a list")
    return value


def _as_str(value: Any, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise PlanError(f"{name} must be a non-empty string")
    return value


def _repo_root_from_plan(plan_path: Path) -> Path:
    # plan.json lives at <app-root>/tool/workshop/plan.json
    return plan_path.resolve().parents[2]


def _normalize_rel(path: str) -> str:
    text = path.replace("\\", "/").strip()
    if not text:
        raise PlanError("empty path")
    if text.startswith("/") or re.match(r"^[a-zA-Z]:", text):
        raise PlanError(f"path escape (absolute): {path}")
    parts: list[str] = []
    for part in text.split("/"):
        if part in ("", "."):
            continue
        if part == "..":
            raise PlanError(f"path escape (..): {path}")
        parts.append(part)
    if not parts:
        raise PlanError(f"path escape (empty): {path}")
    return "/".join(parts)


def _is_execution_mode_flag(arg: str) -> bool:
    if arg in {"-c", "-m"}:
        return True
    if arg.startswith("-c") and not arg.startswith("--"):
        return True
    if arg.startswith("-m") and not arg.startswith("--"):
        return True
    return False


DEVICE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]*$")
ALLOWED_FLUTTER_REPORTERS = {"json"}
ALLOWED_FLUTTER_FLAVORS = {"rig"}
REQUIRED_RIG_DEFINE = "TELLTALE_TEST_RIG=true"


def _validate_flutter_command(argv: list[str], task_id: str) -> None:
    if len(argv) < 3 or argv[1] != "test":
        raise PlanError(f"{task_id}: flutter command must be 'flutter test <dart files>'")
    dart_files = 0
    has_integration = False
    flavor: str | None = None
    reporter: str | None = None
    dart_define: str | None = None
    device: str | None = None
    items = argv[2:]
    index = 0
    while index < len(items):
        item = items[index]
        if item == "--reporter" or item.startswith("--reporter="):
            value = item.split("=", 1)[1] if "=" in item else None
            if value is None:
                index += 1
                if index >= len(items):
                    raise PlanError(f"{task_id}: --reporter requires json")
                value = items[index]
            if value not in ALLOWED_FLUTTER_REPORTERS:
                raise PlanError(
                    f"{task_id}: flutter test reporter {value!r} is not allowlisted"
                )
            reporter = value
        elif item == "--flavor" or item.startswith("--flavor="):
            value = item.split("=", 1)[1] if "=" in item else None
            if value is None:
                index += 1
                if index >= len(items):
                    raise PlanError(f"{task_id}: --flavor requires rig")
                value = items[index]
            if value not in ALLOWED_FLUTTER_FLAVORS:
                raise PlanError(
                    f"{task_id}: flutter test flavor {value!r} is not allowlisted"
                )
            flavor = value
        elif item == "--dart-define" or item.startswith("--dart-define="):
            value = item.split("=", 1)[1] if "=" in item else None
            if value is None:
                index += 1
                if index >= len(items):
                    raise PlanError(
                        f"{task_id}: --dart-define requires {REQUIRED_RIG_DEFINE}"
                    )
                value = items[index]
            if value != REQUIRED_RIG_DEFINE:
                raise PlanError(
                    f"{task_id}: flutter test dart-define {value!r} is not allowlisted"
                )
            dart_define = value
        elif item == "-d":
            index += 1
            if index >= len(items):
                raise PlanError(f"{task_id}: -d requires an explicit test device")
            value = items[index]
            if not DEVICE_RE.fullmatch(value):
                raise PlanError(
                    f"{task_id}: flutter test device {value!r} is not allowlisted"
                )
            device = value
        elif item.startswith("-"):
            raise PlanError(
                f"{task_id}: flutter test option {item!r} is not allowlisted"
            )
        else:
            if not item.endswith(".dart"):
                raise PlanError(
                    f"{task_id}: flutter test argument must be a .dart file"
                )
            rel = _normalize_rel(item)
            if not rel.startswith(ALLOWED_FLUTTER_TEST_PREFIXES):
                raise PlanError(
                    f"{task_id}: script {rel} is outside the workshop allowlist"
                )
            if rel.startswith("integration_test/"):
                has_integration = True
            dart_files += 1
        index += 1
    if dart_files == 0:
        raise PlanError(f"{task_id}: command has no local script path")
    if has_integration or flavor == "rig":
        if flavor != "rig":
            raise PlanError(f"{task_id}: integration tests require --flavor rig")
        if dart_define != REQUIRED_RIG_DEFINE:
            raise PlanError(
                f"{task_id}: rig tests require --dart-define={REQUIRED_RIG_DEFINE}"
            )
        if not device:
            raise PlanError(f"{task_id}: rig tests require -d <explicit-test-device>")


def _validate_command(argv: list[Any], task_id: str) -> None:
    if not argv or not all(isinstance(item, str) for item in argv):
        raise PlanError(f"{task_id}: run command must be a list of strings")
    joined = " ".join(argv)
    for forbidden in FORBIDDEN_COMMAND_SUBSTRINGS:
        if forbidden in joined:
            raise PlanError(f"{task_id}: command looks like issue/comment text")
    executable = argv[0]
    if "/" in executable or "\\" in executable:
        raise PlanError(f"{task_id}: executable path is not allowlisted")
    name = executable
    if name not in ALLOWED_COMMAND_NAMES:
        raise PlanError(f"{task_id}: command {name!r} is not allowlisted")
    if name == "flutter":
        _validate_flutter_command(argv, task_id)
        return
    index = 1
    if index < len(argv) and argv[index] == "--":
        index += 1
    if index >= len(argv):
        raise PlanError(f"{task_id}: command has no local script path")
    lead = argv[index]
    if lead == "-":
        raise PlanError(f"{task_id}: interpreter reads stdin instead of a local script")
    if lead.startswith("-"):
        if _is_execution_mode_flag(lead):
            raise PlanError(
                f"{task_id}: interpreter execution flag {lead!r} is not allowlisted"
            )
        raise PlanError(
            f"{task_id}: interpreter option {lead!r} is not allowlisted"
        )
    script = lead
    if not (script.endswith(".py") or script.endswith(".sh")):
        raise PlanError(f"{task_id}: command has no local script path")
    rel = _normalize_rel(script)
    if not rel.startswith(ALLOWED_SCRIPT_PREFIXES):
        raise PlanError(f"{task_id}: script {rel} is outside the workshop allowlist")


def _commit_exists(plan_path: Path, sha: str) -> bool:
    try:
        completed = subprocess.run(
            [
                "git",
                "-C",
                str(plan_path.parent),
                "cat-file",
                "-e",
                f"{sha}^{{commit}}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except OSError:
        return False
    return completed.returncode == 0


def _dirs_overlap(left: str, right: str) -> bool:
    first = left.rstrip("/")
    second = right.rstrip("/")
    return (
        first == second
        or first.startswith(second + "/")
        or second.startswith(first + "/")
    )


def _dirs_conflict(left: list[str], right: list[str]) -> bool:
    return any(_dirs_overlap(item, other) for item in left for other in right)


def _cycles(ids: dict[str, list[str]]) -> list[list[str]]:
    visiting: set[str] = set()
    seen: set[str] = set()
    found: list[list[str]] = []
    stack: list[str] = []

    def walk(node: str) -> None:
        if node in seen:
            return
        visiting.add(node)
        stack.append(node)
        for nxt in ids.get(node, []):
            if nxt in visiting:
                cycle_start = stack.index(nxt)
                found.append(stack[cycle_start:] + [nxt])
                continue
            walk(nxt)
        stack.pop()
        visiting.remove(node)
        seen.add(node)

    for ident in ids:
        walk(ident)
    return found


def validate_plan(
    data: dict[str, Any],
    *,
    plan_path: Path,
    check_artifacts: bool = True,
    git_shas: set[str] | None = None,
) -> tuple[list[str], list[str]]:
    """Return (errors, ready_task_ids)."""
    errors: list[str] = []

    def catch(fn) -> None:
        try:
            fn()
        except PlanError as exc:
            errors.append(str(exc))

    if data.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if data.get("policy") != "USABILITY-R2":
        errors.append("policy must be USABILITY-R2")
    if data.get("repository") != "ImL1s/telltale":
        errors.append("repository must be ImL1s/telltale")

    tasks = data.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        return ["tasks must be a non-empty list"], []

    by_id: dict[str, dict[str, Any]] = {}
    issue_numbers: set[int] = set()
    id_to_issue: dict[str, int] = {}
    issue_to_id: dict[int, str] = {}

    for index, raw in enumerate(tasks):
        prefix = f"tasks[{index}]"
        if not isinstance(raw, dict):
            errors.append(f"{prefix} must be an object")
            continue
        try:
            ident = _as_str(raw.get("id"), f"{prefix}.id")
            if ident in by_id:
                raise PlanError(f"duplicate id: {ident}")
            issue = raw.get("issue")
            if not isinstance(issue, int) or issue <= 0:
                raise PlanError(f"{ident}: issue must be a positive int")
            if issue in issue_numbers:
                raise PlanError(f"duplicate issue number: {issue}")
            issue_numbers.add(issue)
            url = _as_str(raw.get("issue_url"), f"{ident}.issue_url")
            expected = f"https://github.com/ImL1s/telltale/issues/{issue}"
            if url != expected:
                raise PlanError(f"{ident}: issue_url must be {expected}")
            if raw.get("priority") not in ALLOWED_PRIORITY:
                raise PlanError(f"{ident}: priority invalid")
            status = raw.get("status", "pending")
            if status not in ALLOWED_STATUS:
                raise PlanError(f"{ident}: status invalid")
            depends = _as_list(raw.get("depends_on", []), f"{ident}.depends_on")
            if not all(isinstance(item, int) for item in depends):
                raise PlanError(f"{ident}: depends_on must be issue numbers")
            writable = [
                _normalize_rel(_as_str(item, f"{ident}.writable_dirs"))
                for item in _as_list(
                    raw.get("writable_dirs", []), f"{ident}.writable_dirs"
                )
            ]
            commands = _as_list(raw.get("run_commands", []), f"{ident}.run_commands")
            blockers = raw.get("hardware_or_license_blockers", [])
            if not isinstance(blockers, list):
                raise PlanError(f"{ident}: hardware_or_license_blockers must be a list")
            if commands:
                for command in commands:
                    if not isinstance(command, list):
                        raise PlanError(f"{ident}: each run_commands entry is argv")
                    _validate_command(command, ident)
            elif not blockers:
                raise PlanError(
                    f"{ident}: a software task needs run_commands; "
                    "a blocked task needs hardware_or_license_blockers"
                )
            evidence = _as_list(
                raw.get("required_evidence", []), f"{ident}.required_evidence"
            )
            reviewer = raw.get("reviewer_role")
            if reviewer not in ALLOWED_REVIEWER:
                raise PlanError(f"{ident}: reviewer_role must be implementation or review")
            _as_str(raw.get("done_criteria"), f"{ident}.done_criteria")
            done = raw.get("done_criteria", "")
            if re.search(
                r"skip.{0,80}(?:count as pass|counts as pass|"
                r"as a required pass|still pass)",
                done,
                re.I,
            ):
                raise PlanError(
                    f"{ident}: skip must not impersonate a required pass"
                )
            sha = raw.get("base_sha")
            if sha is not None:
                if not isinstance(sha, str) or not SHA_RE.fullmatch(sha):
                    raise PlanError(f"{ident}: base_sha must be 40 lowercase hex")
                if git_shas is not None:
                    if sha not in git_shas:
                        raise PlanError(f"{ident}: stale SHA {sha}")
                elif not _commit_exists(plan_path, sha):
                    raise PlanError(f"{ident}: stale SHA {sha}")
            if check_artifacts:
                root = _repo_root_from_plan(plan_path)
                for item in evidence:
                    if not isinstance(item, dict):
                        raise PlanError(f"{ident}: required_evidence entries are objects")
                    rel = _normalize_rel(_as_str(item.get("path"), f"{ident}.evidence.path"))
                    digest = item.get("sha256")
                    required = item.get("required", True)
                    target = root / rel
                    if required and not target.is_file():
                        raise PlanError(f"{ident}: missing artifact {rel}")
                    if digest is not None:
                        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                            raise PlanError(f"{ident}: evidence sha256 must be 64 hex")
                        if target.is_file():
                            actual = hashlib.sha256(target.read_bytes()).hexdigest()
                            if actual != digest:
                                raise PlanError(
                                    f"{ident}: hash mismatch {rel}"
                                )
            by_id[ident] = {
                **raw,
                "writable_dirs": writable,
                "status": status,
            }
            id_to_issue[ident] = issue
            issue_to_id[issue] = ident
        except PlanError as exc:
            errors.append(str(exc))

    # Dependency existence + graph
    adj: dict[str, list[str]] = {ident: [] for ident in by_id}
    for ident, task in by_id.items():
        for dep in task.get("depends_on", []):
            if dep not in issue_to_id:
                errors.append(f"{ident}: missing dependency issue {dep}")
                continue
            dep_id = issue_to_id[dep]
            if dep_id == ident:
                errors.append(f"{ident}: depends on itself")
            adj[ident].append(dep_id)

    for cycle in _cycles(adj):
        errors.append("cycle: " + " -> ".join(cycle))

    completed_issues = {
        id_to_issue[ident]
        for ident, task in by_id.items()
        if task.get("status") == "completed"
    }
    occupied_dirs: list[list[str]] = [
        task.get("writable_dirs", [])
        for task in by_id.values()
        if task.get("status") == "in_progress"
    ]
    candidates: list[str] = []
    for ident, task in by_id.items():
        if task.get("status") != "pending":
            continue
        deps = task.get("depends_on", [])
        if all(dep in completed_issues for dep in deps):
            candidates.append(ident)

    lease_blocked: set[str] = set()
    for ident in candidates:
        dirs = by_id[ident].get("writable_dirs", [])
        if any(_dirs_conflict(dirs, occupied) for occupied in occupied_dirs):
            lease_blocked.add(ident)
    remaining = [ident for ident in candidates if ident not in lease_blocked]

    kept: list[str] = []
    for ident in sorted(remaining):
        dirs = by_id[ident].get("writable_dirs", [])
        if any(
            _dirs_conflict(dirs, by_id[other].get("writable_dirs", []))
            for other in kept
        ):
            continue
        kept.append(ident)
    kept_set = set(kept)
    ready = [ident for ident in remaining if ident in kept_set]
    return errors, ready


def _is_flutter_test(argv: Any) -> bool:
    if not isinstance(argv, list) or len(argv) < 2:
        return False
    if not all(isinstance(item, str) for item in argv):
        return False
    return Path(argv[0]).name == "flutter" and argv[1] == "test"


def _flutter_json_reporter(argv: Any) -> bool:
    if not isinstance(argv, list):
        return False
    for index, item in enumerate(argv):
        if not isinstance(item, str):
            continue
        if item == "--reporter=json":
            return True
        if item == "--reporter" and index + 1 < len(argv) and argv[index + 1] == "json":
            return True
    return False


def _flutter_json_events(stdout: str) -> tuple[bool, bool]:
    """Return (saw_json_reporter, saw_successful_terminal_done)."""
    saw_json = False
    saw_done = False
    done_success = False
    for raw in stdout.splitlines():
        line = raw.strip()
        if not line.startswith("{"):
            continue
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict):
            continue
        if saw_done:
            return True, False
        kind = payload.get("type")
        if kind == "done":
            saw_json = True
            saw_done = True
            done_success = payload.get("success") is True
        elif kind == "testDone":
            saw_json = True
    return saw_json, saw_done and done_success


def _flutter_typed_id(value: object) -> object | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.strip():
        return value
    return None


def _flutter_skipped(payload: dict[str, Any]) -> bool:
    return payload.get("skipped") is True or payload.get("result") == "skipped"


def parse_flutter_counts(stdout: str) -> tuple[int | None, int | None]:
    """Read executed/skipped from flutter JSON or compact reporter text."""
    executed = 0
    skipped = 0
    saw_json = False
    for raw in stdout.splitlines():
        line = raw.strip()
        if not line.startswith("{"):
            continue
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict) or payload.get("type") != "testDone":
            continue
        if payload.get("hidden") is True:
            continue
        saw_json = True
        if _flutter_skipped(payload):
            skipped += 1
        else:
            executed += 1
    if saw_json:
        _, saw_done = _flutter_json_events(stdout)
        if not saw_done:
            return None, None
        return executed, skipped
    compact = None
    for raw in stdout.splitlines():
        match = re.search(r"\+(\d+)(?:\s+-\d+)?(?:\s+~(\d+))?", raw)
        if match:
            compact = match
    if compact is None:
        return None, None
    return int(compact.group(1)), int(compact.group(2) or 0)


def parse_flutter_case_ids(stdout: str) -> list[str] | None:
    """Executed Flutter JSON case names, or None when IDs are missing/untyped."""
    names: dict[object, str] = {}
    case_ids: list[str] = []
    saw_json = False
    missing = False
    for raw in stdout.splitlines():
        line = raw.strip()
        if not line.startswith("{"):
            continue
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict):
            continue
        kind = payload.get("type")
        if kind == "test":
            saw_json = True
            tid = _flutter_typed_id(payload.get("id"))
            name = payload.get("name")
            if tid is None:
                missing = True
            elif isinstance(name, str) and name.strip():
                names[tid] = name
        elif kind == "testDone":
            saw_json = True
            if payload.get("hidden") is True:
                continue
            if _flutter_skipped(payload):
                continue
            tid = _flutter_typed_id(payload.get("testID"))
            if tid is None:
                missing = True
                continue
            name = names.get(tid)
            if not isinstance(name, str) or not name.strip():
                missing = True
            else:
                case_ids.append(name)
    if not saw_json:
        return None
    _, saw_done = _flutter_json_events(stdout)
    if not saw_done or missing:
        return None
    return case_ids


def _validate_completed_evidence(evidence: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(evidence, list) or not evidence:
        errors.append("completed handoff evidence must be a non-empty list of reports")
        return errors
    for index, item in enumerate(evidence):
        prefix = f"evidence[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{prefix} is not a test report")
            continue
        exit_code = item.get("exit")
        if exit_code != 0:
            errors.append(f"{prefix} exit {exit_code!r} cannot complete")
        if item.get("timed_out") is True:
            errors.append(f"{prefix} timed out and cannot complete")
        if item.get("truncated") is True:
            errors.append(f"{prefix} truncated output cannot complete")
        executed = item.get("executed")
        skipped = item.get("skipped")
        if _is_flutter_test(item.get("argv")):
            stdout = item.get("stdout") or ""
            saw_json, saw_done = _flutter_json_events(stdout)
            json_mode = saw_json or _flutter_json_reporter(item.get("argv"))
            if json_mode and not saw_done:
                errors.append(
                    f"{prefix} flutter JSON reporter stream is incomplete"
                )
            if not isinstance(executed, int) or not isinstance(skipped, int):
                parsed_executed, parsed_skipped = parse_flutter_counts(stdout)
                if executed is None:
                    executed = parsed_executed
                if skipped is None:
                    skipped = parsed_skipped
            if not isinstance(executed, int):
                errors.append(
                    f"{prefix} flutter evidence execution count is unknown"
                )
            elif executed <= 0:
                errors.append(
                    f"{prefix} executed {executed!r} cannot stand in for required cases"
                )
            elif json_mode:
                case_ids = parse_flutter_case_ids(stdout)
                if (
                    not isinstance(case_ids, list)
                    or not case_ids
                    or not all(
                        isinstance(item_id, str) and item_id.strip()
                        for item_id in case_ids
                    )
                ):
                    errors.append(
                        f"{prefix} flutter JSON evidence is missing typed case IDs"
                    )
                elif len(case_ids) != executed:
                    errors.append(
                        f"{prefix} case ID count {len(case_ids)} "
                        f"does not match executed {executed}"
                    )
        elif executed is not None:
            if not isinstance(executed, int) or executed <= 0:
                errors.append(
                    f"{prefix} executed {executed!r} cannot stand in for required cases"
                )
        if isinstance(skipped, int) and skipped > 0 and not (
            isinstance(executed, int) and executed > 0
        ):
            errors.append(
                f"{prefix} skipped {skipped} with no executed cases cannot complete"
            )
    return errors


def validate_handoff(
    data: dict[str, Any],
    *,
    require_head_sha: bool = True,
) -> list[str]:
    errors: list[str] = []
    status = data.get("status")
    if status not in {"in_progress", "failed", "blocked", "completed"}:
        errors.append("handoff.status invalid")
    completed_flag = data.get("completed")
    if status == "completed":
        if completed_flag is not True:
            errors.append("completed handoff requires completed: true")
        errors.extend(_validate_completed_evidence(data.get("evidence")))
        unrun = data.get("unrun") or []
        if unrun:
            errors.append("completed handoff still has unrun steps")
        sha = data.get("head_sha")
        if require_head_sha and (
            not isinstance(sha, str) or not SHA_RE.fullmatch(sha)
        ):
            errors.append("completed handoff requires head_sha")
        elif sha is not None and (
            not isinstance(sha, str) or not SHA_RE.fullmatch(sha)
        ):
            errors.append("handoff.head_sha must be 40 lowercase hex")
    elif status in {"in_progress", "failed", "blocked"}:
        if completed_flag is True:
            errors.append("unfinished handoff must not be labelled completed")
        if completed_flag is not False:
            errors.append("unfinished handoff must set completed: false")
        sha = data.get("head_sha")
        if sha is not None and (not isinstance(sha, str) or not SHA_RE.fullmatch(sha)):
            errors.append("handoff.head_sha must be 40 lowercase hex")
    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan")
    parser.add_argument("--ready", action="store_true")
    parser.add_argument("--handoff")
    parser.add_argument("--no-artifacts", action="store_true")
    parser.add_argument(
        "--known-sha",
        action="append",
        default=[],
        help="SHA-1 values treated as existing (tests). Repeatable.",
    )
    args = parser.parse_args(argv[1:])
    path = Path(args.plan)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot read plan: {exc}", file=sys.stderr)
        return 2
    if not isinstance(data, dict):
        print("plan must be a JSON object", file=sys.stderr)
        return 1
    git_shas = set(args.known_sha) if args.known_sha else None
    errors, ready = validate_plan(
        data,
        plan_path=path,
        check_artifacts=not args.no_artifacts,
        git_shas=git_shas,
    )
    if args.handoff:
        try:
            handoff = json.loads(Path(args.handoff).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"cannot read handoff: {exc}", file=sys.stderr)
            return 2
        if not isinstance(handoff, dict):
            print("handoff must be a JSON object", file=sys.stderr)
            return 1
        errors.extend(validate_handoff(handoff))
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    if args.ready:
        print("READY " + " ".join(ready) if ready else "READY")
    else:
        print(f"OK {path} tasks={len(data.get('tasks', []))} ready={len(ready)}")
        if ready:
            print("ready: " + ", ".join(ready))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
