#!/usr/bin/env python3
"""#11.B: run one ready workshop task from plan.json.

Executes only the already-validated argv allowlist. Does not treat GitHub
issue or comment text as a shell. Does not reset existing git changes.
Worktree isolation is a later 11.B slice; this file owns command execution,
leases, timeouts, env allowlisting, and honest handoff.json.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

import validate_plan

ALLOWED_ENV_KEYS = {
    "PATH",
    "HOME",
    "LANG",
    "LC_ALL",
    "LC_CTYPE",
    "LC_MESSAGES",
    "TMPDIR",
    "TMP",
    "TEMP",
    "TERM",
    "TZ",
    "USER",
    "LOGNAME",
    "CI",
    "GITHUB_ACTIONS",
    "RUNNER_OS",
    "RUNNER_TEMP",
}
ALLOWED_ENV_PREFIXES = (
    "PYTHON",
    "PUB_",
    "FLUTTER",
    "DART_",
    "ANDROID_",
    "JAVA_",
    "HOMEBREW_",
)
FORBIDDEN_ENV_KEYS = {
    "GH_TOKEN",
    "GITHUB_TOKEN",
    "AWS_SECRET_ACCESS_KEY",
    "AWS_ACCESS_KEY_ID",
    "OP_SERVICE_ACCOUNT_TOKEN",
    "SSH_AUTH_SOCK",
}


class RunnerError(Exception):
    pass


def _allowed_env(source: dict[str, str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key, value in source.items():
        if key in FORBIDDEN_ENV_KEYS:
            continue
        if key in ALLOWED_ENV_KEYS or key.startswith(ALLOWED_ENV_PREFIXES):
            out[key] = value
    return out


def _task_by_id(data: dict[str, Any], task_id: str) -> dict[str, Any]:
    for raw in data.get("tasks") or []:
        if isinstance(raw, dict) and raw.get("id") == task_id:
            return raw
    raise RunnerError(f"unknown task {task_id}")


def _write_handoff(path: Path, payload: dict[str, Any]) -> None:
    errors = validate_plan.validate_handoff(payload)
    if errors:
        raise RunnerError("invalid handoff: " + "; ".join(errors))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _run_command(
    argv: list[str],
    *,
    cwd: Path,
    env: dict[str, str],
    timeout: float,
    output_limit: int,
) -> dict[str, Any]:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            argv,
            cwd=cwd,
            env=env,
            check=False,
            capture_output=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = (exc.stdout or b"")[:output_limit]
        stderr = (exc.stderr or b"")[:output_limit]
        return {
            "argv": argv,
            "exit": None,
            "timed_out": True,
            "duration_s": round(time.monotonic() - started, 3),
            "stdout": stdout.decode("utf-8", "replace"),
            "stderr": stderr.decode("utf-8", "replace"),
        }
    stdout = completed.stdout[:output_limit]
    stderr = completed.stderr[:output_limit]
    return {
        "argv": argv,
        "exit": completed.returncode,
        "timed_out": False,
        "duration_s": round(time.monotonic() - started, 3),
        "stdout": stdout.decode("utf-8", "replace"),
        "stderr": stderr.decode("utf-8", "replace"),
    }


def run_task(
    plan_path: Path,
    task_id: str,
    *,
    timeout: float = 300,
    output_limit: int = 1_000_000,
    handoff_path: Path | None = None,
    dry_run: bool = False,
    env: dict[str, str] | None = None,
) -> int:
    try:
        data = json.loads(plan_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"cannot read plan: {exc}") from exc
    if not isinstance(data, dict):
        raise RunnerError("plan must be a JSON object")
    errors, ready = validate_plan.validate_plan(
        data, plan_path=plan_path, check_artifacts=True
    )
    if errors:
        raise RunnerError("invalid plan: " + "; ".join(errors))
    task = _task_by_id(data, task_id)
    if task.get("status") != "pending":
        raise RunnerError(f"{task_id}: status {task.get('status')!r} is not pending")
    if task_id not in ready:
        raise RunnerError(
            f"{task_id}: not ready (lease or unfinished dependency)"
        )
    if task.get("hardware_or_license_blockers"):
        raise RunnerError(
            f"{task_id}: hardware/license blocker is visible, not PASS"
        )
    commands = task.get("run_commands") or []
    if not commands:
        raise RunnerError(f"{task_id}: no run_commands")
    cwd = validate_plan._repo_root_from_plan(plan_path)
    child_env = _allowed_env(env if env is not None else os.environ)
    results: list[dict[str, Any]] = []
    failed: list[str] = []
    unrun: list[str] = []
    if dry_run:
        unrun = [" ".join(cmd) for cmd in commands]
    else:
        for argv in commands:
            if not isinstance(argv, list) or not all(isinstance(item, str) for item in argv):
                raise RunnerError(f"{task_id}: run command must be argv")
            validate_plan._validate_command(argv, task_id)
            if failed:
                unrun.append(" ".join(argv))
                continue
            result = _run_command(
                argv,
                cwd=cwd,
                env=child_env,
                timeout=timeout,
                output_limit=output_limit,
            )
            results.append(result)
            if result["timed_out"] or result["exit"] != 0:
                failed.append(" ".join(argv))
    completed = not dry_run and not failed and not unrun
    payload = {
        "task": task_id,
        "issue": task.get("issue"),
        "status": "completed" if completed else ("in_progress" if dry_run else "failed"),
        "completed": completed,
        "failed": failed,
        "unrun": unrun,
        "results": results,
        "reviewer_role": task.get("reviewer_role"),
        "next": (
            "reviewer re-runs the same argv"
            if completed
            else "fix the failed command; do not mark completed"
        ),
    }
    if completed:
        payload["evidence"] = results
    dest = handoff_path or (cwd / "docs" / "workshop" / "ws" / task_id.lower() / "handoff.json")
    _write_handoff(dest, payload)
    return 0 if completed else 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan")
    parser.add_argument("--task", required=True)
    parser.add_argument("--handoff")
    parser.add_argument("--timeout", type=float, default=300)
    parser.add_argument("--output-limit", type=int, default=1_000_000)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv[1:])
    try:
        return run_task(
            Path(args.plan),
            args.task,
            timeout=args.timeout,
            output_limit=args.output_limit,
            handoff_path=Path(args.handoff) if args.handoff else None,
            dry_run=args.dry_run,
        )
    except RunnerError as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
