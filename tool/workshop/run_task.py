#!/usr/bin/env python3
"""#11.B: run one ready workshop task from plan.json.

Executes only the already-validated argv allowlist. Does not treat GitHub
issue or comment text as a shell. Does not reset existing git changes.
`--isolate` adds a detached worktree at a fixed SHA and runs there; the
caller's checkout is left untouched. If the isolate path already exists,
the runner refuses rather than resetting it.
"""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

import validate_plan

ALLOWED_ENV_KEYS = {
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


class RunnerError(Exception):
    pass


def _allowed_env(source: dict[str, str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key in ALLOWED_ENV_KEYS:
        if key in source:
            out[key] = source[key]
    path_dirs = [
        str(Path(sys.executable).resolve().parent),
        "/usr/bin",
        "/bin",
        "/usr/local/bin",
        str(Path.home() / "fvm" / "versions" / "3.47.0" / "bin"),
    ]
    out["PATH"] = os.pathsep.join(
        directory for directory in path_dirs if Path(directory).is_dir()
    )
    return out


def _resolve_executable(name: str) -> str:
    if "/" in name or "\\" in name:
        raise RunnerError(f"executable path is not allowlisted: {name}")
    if name == "python3":
        return sys.executable
    if name == "bash":
        for candidate in ("/bin/bash", "/usr/bin/bash"):
            if Path(candidate).is_file() and os.access(candidate, os.X_OK):
                return candidate
        raise RunnerError("trusted bash not found")
    if name == "flutter":
        candidate = Path.home() / "fvm" / "versions" / "3.47.0" / "bin" / "flutter"
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
        raise RunnerError("trusted flutter 3.47.0 not found")
    raise RunnerError(f"command {name!r} is not allowlisted")


def _acquire_lease(path: Path, task_id: str) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(str(path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        os.close(fd)
        raise RunnerError(f"{task_id}: lease held") from exc
    os.lseek(fd, 0, os.SEEK_SET)
    os.ftruncate(fd, 0)
    os.write(fd, json.dumps({"task": task_id, "pid": os.getpid()}).encode("utf-8"))
    return fd


def _release_lease(fd: int | None, path: Path) -> None:
    del path
    if fd is None:
        return
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
    except OSError:
        pass
    os.close(fd)


def _kill_group(pid: int, sig: int) -> None:
    try:
        os.killpg(pid, sig)
    except ProcessLookupError:
        return
    except PermissionError:
        return


def _task_by_id(data: dict[str, Any], task_id: str) -> dict[str, Any]:
    for raw in data.get("tasks") or []:
        if isinstance(raw, dict) and raw.get("id") == task_id:
            return raw
    raise RunnerError(f"unknown task {task_id}")


def _git_toplevel(start: Path) -> Path:
    completed = subprocess.run(
        ["git", "-C", str(start), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RunnerError("not a git checkout; cannot isolate")
    return Path(completed.stdout.strip())


def _git_sha(git_root: Path, rev: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(git_root), "rev-parse", "--verify", f"{rev}^{{commit}}"],
        capture_output=True,
        text=True,
        check=False,
    )
    sha = (completed.stdout or "").strip()
    if completed.returncode != 0 or not validate_plan.SHA_RE.fullmatch(sha):
        raise RunnerError(f"stale or missing SHA {rev}")
    return sha


def _add_worktree(git_root: Path, dest: Path, sha: str) -> None:
    if dest.exists():
        raise RunnerError(f"worktree path exists, refusing to reset: {dest}")
    if dest.resolve() == git_root.resolve():
        raise RunnerError("isolate dir is the current checkout")
    dest.parent.mkdir(parents=True, exist_ok=True)
    completed = subprocess.run(
        ["git", "-C", str(git_root), "worktree", "add", "--detach", str(dest), sha],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RunnerError(
            "git worktree add failed: "
            + (completed.stderr or completed.stdout or "").strip()
        )


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
        resolved = [_resolve_executable(argv[0]), *argv[1:]]
    except RunnerError as exc:
        return {
            "argv": argv,
            "exit": 127,
            "timed_out": False,
            "duration_s": round(time.monotonic() - started, 3),
            "stdout": "",
            "stderr": str(exc),
        }
    try:
        proc = subprocess.Popen(
            resolved,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
    except OSError as exc:
        return {
            "argv": argv,
            "exit": 127,
            "timed_out": False,
            "duration_s": round(time.monotonic() - started, 3),
            "stdout": "",
            "stderr": str(exc),
        }
    timed_out = False
    try:
        stdout_b, stderr_b = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        _kill_group(proc.pid, signal.SIGTERM)
        try:
            stdout_b, stderr_b = proc.communicate(timeout=1)
        except subprocess.TimeoutExpired:
            _kill_group(proc.pid, signal.SIGKILL)
            stdout_b, stderr_b = proc.communicate()
    stdout = (stdout_b or b"")[:output_limit].decode("utf-8", "replace")
    stderr = (stderr_b or b"")[:output_limit].decode("utf-8", "replace")
    return {
        "argv": argv,
        "exit": None if timed_out else proc.returncode,
        "timed_out": timed_out,
        "duration_s": round(time.monotonic() - started, 3),
        "stdout": stdout,
        "stderr": stderr,
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
    isolate: bool = False,
    isolate_dir: Path | None = None,
    base_sha: str | None = None,
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
    original_root = validate_plan._repo_root_from_plan(plan_path)
    cwd = original_root
    worktree_path: str | None = None
    head_sha: str | None = None
    handoff_dest = handoff_path or (
        original_root / "docs" / "workshop" / "ws" / task_id.lower() / "handoff.json"
    )
    lease_path = (
        original_root / "docs" / "workshop" / "ws" / task_id.lower() / "lease.json"
    )
    lease_fd: int | None = None
    if not dry_run:
        lease_fd = _acquire_lease(lease_path, task_id)
    try:
        if isolate:
            git_root = _git_toplevel(cwd)
            requested = base_sha or task.get("base_sha")
            head_sha = (
                _git_sha(git_root, requested) if requested else _git_sha(git_root, "HEAD")
            )
            worktree_dest = (
                isolate_dir.expanduser().resolve()
                if isolate_dir is not None
                else git_root / ".worktrees" / f"ws-{task_id.lower()}"
            )
            _add_worktree(git_root, worktree_dest, head_sha)
            worktree_path = str(worktree_dest)
            try:
                rel = cwd.resolve().relative_to(git_root.resolve())
            except ValueError as exc:
                raise RunnerError("plan root is outside the git checkout") from exc
            cwd = worktree_dest if rel == Path(".") else worktree_dest / rel
        child_env = _allowed_env(env if env is not None else os.environ)
        results: list[dict[str, Any]] = []
        failed: list[str] = []
        unrun: list[str] = []
        if dry_run:
            unrun = [" ".join(cmd) for cmd in commands]
        else:
            for argv in commands:
                if not isinstance(argv, list) or not all(
                    isinstance(item, str) for item in argv
                ):
                    raise RunnerError(f"{task_id}: run command must be argv")
                try:
                    validate_plan._validate_command(argv, task_id)
                except validate_plan.PlanError as exc:
                    raise RunnerError(str(exc)) from exc
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
        if worktree_path is not None:
            payload["worktree"] = worktree_path
        if head_sha is not None:
            payload["head_sha"] = head_sha
        if completed:
            payload["evidence"] = results
        _write_handoff(handoff_dest, payload)
        return 0 if completed else 1
    finally:
        _release_lease(lease_fd, lease_path)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan")
    parser.add_argument("--task", required=True)
    parser.add_argument("--handoff")
    parser.add_argument("--timeout", type=float, default=300)
    parser.add_argument("--output-limit", type=int, default=1_000_000)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--isolate", action="store_true")
    parser.add_argument("--isolate-dir")
    parser.add_argument("--base-sha")
    args = parser.parse_args(argv[1:])
    try:
        return run_task(
            Path(args.plan),
            args.task,
            timeout=args.timeout,
            output_limit=args.output_limit,
            handoff_path=Path(args.handoff) if args.handoff else None,
            dry_run=args.dry_run,
            isolate=args.isolate,
            isolate_dir=Path(args.isolate_dir) if args.isolate_dir else None,
            base_sha=args.base_sha,
        )
    except RunnerError as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
