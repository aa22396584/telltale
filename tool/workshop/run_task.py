#!/usr/bin/env python3
"""#11.B: run one ready workshop task from plan.json.

Executes only the already-validated argv allowlist. Does not treat GitHub
issue or comment text as a shell. Does not reset existing git changes.
`--isolate` adds a detached worktree at a fixed SHA and runs there; the
caller's checkout is left untouched. If the isolate path already exists,
the runner refuses rather than resetting it. Combined with `--dry-run` it
does not create a worktree; required evidence is read from git blobs at
that SHA instead of the caller's dirty tree. `--review` re-runs a completed
author handoff and writes `review.json` beside it, or `reviewer.json` when
the author path is already named `review.json`; it cannot be dry-run.
"""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import signal
import subprocess
import sys
import threading
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


def _dir_lease_path(root: Path, rel: str) -> Path:
    digest = hashlib.sha256(rel.encode("utf-8")).hexdigest()[:16]
    return root / "docs" / "workshop" / "ws" / ".dir-leases" / f"{digest}.lock"


def _dir_lease_targets(dirs: list[str]) -> list[tuple[str, bool]]:
    """Map declared dirs to (path, exclusive) locks.

    The leaf is exclusive; every ancestor is shared. Parent ``foo`` and child
    ``foo/bar`` therefore contend on ``foo``, while sibling ``foo/bar`` and
    ``foo/baz`` only share the ancestor and can run together.
    """
    mode: dict[str, bool] = {}
    for rel in dirs:
        parts = [part for part in rel.split("/") if part]
        if not parts:
            continue
        chain = ["/".join(parts[: index + 1]) for index in range(len(parts))]
        for prefix in chain[:-1]:
            mode.setdefault(prefix, False)
        mode[chain[-1]] = True
    return sorted(mode.items(), key=lambda item: item[0])


def _acquire_lease(path: Path, task_id: str, *, exclusive: bool = True) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(str(path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        flag = fcntl.LOCK_EX if exclusive else fcntl.LOCK_SH
        fcntl.flock(fd, flag | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        os.close(fd)
        raise RunnerError(f"{task_id}: lease held") from exc
    if exclusive:
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


def _git_path_from_app(git_root: Path, app_root: Path, evidence_rel: str) -> str:
    try:
        nested = app_root.resolve().relative_to(git_root.resolve())
    except ValueError as exc:
        raise RunnerError("plan root is outside the git checkout") from exc
    posix = evidence_rel.replace("\\", "/")
    if nested == Path("."):
        return posix
    return f"{nested.as_posix()}/{posix}"


def _git_tree_entry(git_root: Path, sha: str, rel: str) -> tuple[str, str] | None:
    completed = subprocess.run(
        ["git", "-C", str(git_root), "ls-tree", "--full-tree", sha, "--", rel],
        capture_output=True,
        text=True,
        check=False,
    )
    line = (completed.stdout or "").splitlines()
    if completed.returncode != 0 or not line:
        return None
    meta, _tab, _path = line[0].partition("\t")
    parts = meta.split()
    if len(parts) < 2:
        return None
    return parts[0], parts[1]


def _resolve_link_rel(link_rel: str, target: str) -> str | None:
    text = target.replace("\\", "/")
    if not text or text.startswith("/") or (len(text) >= 2 and text[1] == ":"):
        return None
    parent = Path(link_rel.replace("\\", "/")).parent
    combined = text if parent == Path(".") else f"{parent.as_posix()}/{text}"
    parts: list[str] = []
    for part in combined.replace("\\", "/").split("/"):
        if part in ("", "."):
            continue
        if part == "..":
            if not parts:
                return None
            parts.pop()
            continue
        parts.append(part)
    if not parts:
        return None
    return "/".join(parts)


def _git_cat_blob(
    git_root: Path, sha: str, rel: str, *, filters: bool = False
) -> bytes | None:
    command = ["git", "-C", str(git_root), "cat-file"]
    if filters:
        command.extend(["--filters", f"{sha}:{rel}"])
    else:
        command.extend(["blob", f"{sha}:{rel}"])
    completed = subprocess.run(command, capture_output=True, check=False)
    if completed.returncode != 0:
        return None
    return completed.stdout


def _git_blob(
    git_root: Path, sha: str, rel: str, *, depth: int = 0
) -> bytes | None:
    if depth > 8:
        return None
    parts = [part for part in rel.replace("\\", "/").split("/") if part not in ("", ".")]
    if not parts:
        return None
    prefix = ""
    for index, part in enumerate(parts):
        current = part if not prefix else f"{prefix}/{part}"
        entry = _git_tree_entry(git_root, sha, current)
        if entry is None:
            return None
        mode, kind = entry
        last = index == len(parts) - 1
        if mode == "120000":
            raw = _git_cat_blob(git_root, sha, current, filters=False)
            if raw is None:
                return None
            try:
                target = raw.decode("utf-8")
            except UnicodeDecodeError:
                return None
            resolved = _resolve_link_rel(current, target)
            if resolved is None:
                return None
            remainder = "/".join(parts[index + 1 :])
            nxt = resolved if not remainder else f"{resolved}/{remainder}"
            return _git_blob(git_root, sha, nxt, depth=depth + 1)
        if last:
            if kind != "blob" or mode not in {"100644", "100755", "100664"}:
                return None
            return _git_cat_blob(git_root, sha, current, filters=True)
        if kind != "tree":
            return None
        prefix = current
    return None


def _check_sha_evidence(
    data: dict[str, Any],
    git_root: Path,
    sha: str,
    app_root: Path,
) -> None:
    errors: list[str] = []
    for raw in data.get("tasks") or []:
        if not isinstance(raw, dict):
            continue
        ident = raw.get("id") if isinstance(raw.get("id"), str) else "?"
        evidence = raw.get("required_evidence") or []
        if not isinstance(evidence, list):
            errors.append(f"{ident}: required_evidence must be a list")
            continue
        for item in evidence:
            if not isinstance(item, dict):
                errors.append(f"{ident}: required_evidence entries are objects")
                continue
            try:
                rel = validate_plan._normalize_rel(
                    validate_plan._as_str(item.get("path"), f"{ident}.evidence.path")
                )
            except validate_plan.PlanError as exc:
                errors.append(str(exc))
                continue
            digest = item.get("sha256")
            required = item.get("required", True)
            if digest is not None and (
                not isinstance(digest, str)
                or not validate_plan.SHA256_RE.fullmatch(digest)
            ):
                errors.append(f"{ident}: evidence sha256 must be 64 hex")
                continue
            blob = _git_blob(git_root, sha, _git_path_from_app(git_root, app_root, rel))
            if blob is None:
                if required:
                    errors.append(f"{ident}: missing artifact {rel}")
                continue
            if digest is not None and hashlib.sha256(blob).hexdigest() != digest:
                errors.append(f"{ident}: hash mismatch {rel}")
    if errors:
        raise RunnerError(
            "isolated checkout evidence failed: " + "; ".join(errors)
        )


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


def _task_writable_dirs(task: dict[str, Any]) -> list[str]:
    raw = task.get("writable_dirs") or []
    out: list[str] = []
    for item in raw:
        if isinstance(item, str):
            out.append(validate_plan._normalize_rel(item))
    return out


def _unfinished_dependencies(data: dict[str, Any], task: dict[str, Any]) -> bool:
    tasks = [item for item in (data.get("tasks") or []) if isinstance(item, dict)]
    completed_issues = {
        item.get("issue")
        for item in tasks
        if item.get("status") == "completed"
    }
    deps = task.get("depends_on") or []
    return any(
        isinstance(dep, int) and dep not in completed_issues for dep in deps
    )


def _peer_eligible_for_lease(
    data: dict[str, Any], other: dict[str, Any], ready: list[str]
) -> bool:
    status = other.get("status")
    if status == "in_progress":
        return True
    if status == "pending":
        return other.get("id") in ready
    return False


def _in_progress_lease_conflict(
    data: dict[str, Any], task_id: str, ready: list[str]
) -> bool:
    tasks = [item for item in (data.get("tasks") or []) if isinstance(item, dict)]
    target = next((item for item in tasks if item.get("id") == task_id), None)
    if target is None:
        return False
    dirs = _task_writable_dirs(target)
    for other in tasks:
        if other.get("id") == task_id:
            continue
        if not _peer_eligible_for_lease(data, other, ready):
            continue
        if validate_plan._dirs_conflict(dirs, _task_writable_dirs(other)):
            return True
    return False


def _read_author_handoff(
    path: Path, task_id: str, task: dict[str, Any]
) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"cannot read author handoff: {exc}") from exc
    if not isinstance(raw, dict):
        raise RunnerError("author handoff must be a JSON object")
    errors = validate_plan.validate_handoff(raw)
    if errors:
        raise RunnerError("invalid author handoff: " + "; ".join(errors))
    if raw.get("completed") is not True or raw.get("status") != "completed":
        raise RunnerError("review requires a completed author handoff")
    if raw.get("task") != task_id:
        raise RunnerError(
            f"author handoff task {raw.get('task')!r} does not match {task_id}"
        )
    if raw.get("issue") != task.get("issue"):
        raise RunnerError(
            f"author handoff issue {raw.get('issue')!r} does not match "
            f"{task.get('issue')}"
        )
    planned = task.get("run_commands") or []
    results = raw.get("results") or raw.get("evidence") or []
    if not isinstance(results, list) or len(results) != len(planned):
        raise RunnerError(
            "author handoff commands do not match the selected task"
        )
    for item, argv in zip(results, planned, strict=True):
        if not isinstance(item, dict) or item.get("argv") != argv:
            raise RunnerError(
                "author handoff commands do not match the selected task"
            )
    return raw


def _write_handoff(path: Path, payload: dict[str, Any]) -> None:
    errors = validate_plan.validate_handoff(payload)
    if errors:
        raise RunnerError("invalid handoff: " + "; ".join(errors))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _drain_pipe(pipe, limit: int) -> tuple[bytes, bool]:
    chunks: list[bytes] = []
    kept = 0
    truncated = False
    try:
        while True:
            block = pipe.read(65536)
            if not block:
                break
            if truncated:
                continue
            if kept < limit:
                take = min(len(block), limit - kept)
                chunks.append(block[:take])
                kept += take
                if take < len(block):
                    truncated = True
            else:
                truncated = True
    except (ValueError, OSError):
        pass
    return b"".join(chunks), truncated


def _remaining(deadline: float) -> float:
    return max(0.0, deadline - time.monotonic())


def _join_threads(threads: list[threading.Thread], timeout: float) -> bool:
    end = time.monotonic() + timeout
    for thread in threads:
        thread.join(timeout=_remaining(end))
    return all(not thread.is_alive() for thread in threads)


def _close_pipe(pipe) -> None:
    if pipe is None:
        return
    try:
        pipe.close()
    except OSError:
        pass


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
    stdout_holder: list[tuple[bytes, bool]] = []
    stderr_holder: list[tuple[bytes, bool]] = []
    deadline = started + timeout

    def collect(pipe, dest: list[tuple[bytes, bool]]) -> None:
        dest.append(_drain_pipe(pipe, output_limit))

    reader_out = threading.Thread(
        target=collect, args=(proc.stdout, stdout_holder), daemon=True
    )
    reader_err = threading.Thread(
        target=collect, args=(proc.stderr, stderr_holder), daemon=True
    )
    reader_out.start()
    reader_err.start()
    readers = [reader_out, reader_err]
    wait_for = _remaining(deadline)
    try:
        if wait_for <= 0:
            raise subprocess.TimeoutExpired(resolved, timeout)
        proc.wait(timeout=wait_for)
    except subprocess.TimeoutExpired:
        timed_out = True
        _kill_group(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=min(1.0, _remaining(deadline) or 0.05))
        except subprocess.TimeoutExpired:
            _kill_group(proc.pid, signal.SIGKILL)
            try:
                proc.wait(timeout=1)
            except subprocess.TimeoutExpired:
                pass
    if not _join_threads(readers, _remaining(deadline)):
        timed_out = True
        _kill_group(proc.pid, signal.SIGKILL)
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            pass
        _close_pipe(proc.stdout)
        _close_pipe(proc.stderr)
        _join_threads(readers, 2.0)
    else:
        _close_pipe(proc.stdout)
        _close_pipe(proc.stderr)
    stdout_b, stdout_trunc = stdout_holder[0] if stdout_holder else (b"", False)
    stderr_b, stderr_trunc = stderr_holder[0] if stderr_holder else (b"", False)
    stdout = stdout_b.decode("utf-8", "replace")
    stderr = stderr_b.decode("utf-8", "replace")
    result: dict[str, Any] = {
        "argv": argv,
        "exit": None if timed_out else proc.returncode,
        "timed_out": timed_out,
        "duration_s": round(time.monotonic() - started, 3),
        "stdout": stdout,
        "stderr": stderr,
    }
    if stdout_trunc or stderr_trunc:
        result["truncated"] = True
    if validate_plan._is_flutter_test(argv):
        executed, skipped = validate_plan.parse_flutter_counts(stdout)
        if executed is not None:
            result["executed"] = executed
        if skipped is not None:
            result["skipped"] = skipped
    return result


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
    review: bool = False,
) -> int:
    try:
        data = json.loads(plan_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RunnerError(f"cannot read plan: {exc}") from exc
    if not isinstance(data, dict):
        raise RunnerError("plan must be a JSON object")
    errors, ready = validate_plan.validate_plan(
        data,
        plan_path=plan_path,
        check_artifacts=not isolate,
    )
    if errors:
        raise RunnerError("invalid plan: " + "; ".join(errors))
    task = _task_by_id(data, task_id)
    if review and dry_run:
        raise RunnerError(
            "review cannot be dry-run: that would accept the author handoff "
            "without re-running"
        )
    if not review:
        if task.get("status") != "pending":
            raise RunnerError(f"{task_id}: status {task.get('status')!r} is not pending")
        if task_id not in ready:
            raise RunnerError(
                f"{task_id}: not ready (lease or unfinished dependency)"
            )
    elif (
        task.get("status") not in {"pending", "completed"}
        or _unfinished_dependencies(data, task)
        or _in_progress_lease_conflict(data, task_id, ready)
    ):
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
    author_handoff: dict[str, Any] | None = None
    if review:
        author_path = handoff_dest
        review_path = author_path.with_name("review.json")
        if review_path.resolve() == author_path.resolve():
            review_path = author_path.with_name("reviewer.json")
        handoff_dest = review_path
        author_handoff = _read_author_handoff(author_path, task_id, task)
        author_sha = author_handoff.get("head_sha")
        if isinstance(author_sha, str) and author_sha:
            if not isolate and author_handoff.get("worktree"):
                raise RunnerError(
                    f"{task_id}: review must isolate at the author SHA"
                )
            requested = base_sha or task.get("base_sha")
            if requested and requested != author_sha:
                raise RunnerError(
                    f"{task_id}: review SHA {requested} does not match "
                    f"author SHA {author_sha}"
                )
            base_sha = author_sha
        elif isolate:
            raise RunnerError(
                f"{task_id}: review isolate requires an author head_sha"
            )
    lease_path = (
        original_root / "docs" / "workshop" / "ws" / task_id.lower() / "lease.json"
    )
    lease_fd: int | None = None
    dir_leases: list[tuple[int, Path]] = []
    try:
        if not dry_run:
            lease_fd = _acquire_lease(lease_path, task_id)
            for rel, exclusive in _dir_lease_targets(_task_writable_dirs(task)):
                path = _dir_lease_path(original_root, rel)
                dir_leases.append(
                    (_acquire_lease(path, task_id, exclusive=exclusive), path)
                )
        if isolate:
            git_root = _git_toplevel(cwd)
            requested = base_sha or task.get("base_sha")
            head_sha = (
                _git_sha(git_root, requested) if requested else _git_sha(git_root, "HEAD")
            )
            if dry_run:
                _check_sha_evidence(data, git_root, head_sha, original_root)
            else:
                worktree_dest = (
                    isolate_dir.expanduser().resolve()
                    if isolate_dir is not None
                    else git_root
                    / ".worktrees"
                    / (
                        f"ws-{task_id.lower()}-review"
                        if review
                        else f"ws-{task_id.lower()}"
                    )
                )
                _add_worktree(git_root, worktree_dest, head_sha)
                worktree_path = str(worktree_dest)
                try:
                    rel = cwd.resolve().relative_to(git_root.resolve())
                except ValueError as exc:
                    raise RunnerError("plan root is outside the git checkout") from exc
                cwd = worktree_dest if rel == Path(".") else worktree_dest / rel
                isolated_anchor = cwd / "tool" / "workshop" / "plan.json"
                artifact_errors, _ = validate_plan.validate_plan(
                    data,
                    plan_path=isolated_anchor,
                    check_artifacts=True,
                )
                if artifact_errors:
                    raise RunnerError(
                        "isolated checkout evidence failed: "
                        + "; ".join(artifact_errors)
                    )
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
                if (
                    result["timed_out"]
                    or result["exit"] != 0
                    or result.get("truncated") is True
                ):
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
            "reviewer_role": "review" if review else task.get("reviewer_role"),
            "next": (
                "review re-ran the same argv"
                if review and completed
                else "reviewer re-runs the same argv"
                if completed
                else "fix the failed command; do not mark completed"
            ),
        }
        if worktree_path is not None:
            payload["worktree"] = worktree_path
        if completed and head_sha is None:
            head_sha = _git_sha(_git_toplevel(original_root), "HEAD")
        if head_sha is not None:
            payload["head_sha"] = head_sha
        if completed:
            payload["evidence"] = results
        _write_handoff(handoff_dest, payload)
        return 0 if completed else 1
    finally:
        for fd, path in reversed(dir_leases):
            _release_lease(fd, path)
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
    parser.add_argument(
        "--review",
        action="store_true",
        help=(
            "re-run a completed author handoff; writes review.json, or "
            "reviewer.json if the author path is already named review.json"
        ),
    )
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
            review=args.review,
        )
    except RunnerError as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
