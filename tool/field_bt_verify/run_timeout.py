#!/usr/bin/env python3
"""Run a command with a wall-clock bound and fail closed on timeout.

Used by run.sh so a hung Flutter journey cannot sit in communicate() after
killpg misses a grandchild.
"""

from __future__ import annotations

import os
import signal
import subprocess
import sys


def reap(proc: subprocess.Popen[str], *, grace: float = 2.0) -> str:
    """Kill the process group, then communicate with a timeout."""
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
        try:
            proc.kill()
        except OSError:
            pass
    try:
        try:
            out, _ = proc.communicate(timeout=grace)
            return out or ""
        except subprocess.TimeoutExpired:
            try:
                proc.kill()
            except OSError:
                pass
            try:
                out, _ = proc.communicate(timeout=1)
                return out or ""
            except subprocess.TimeoutExpired:
                return ""
    finally:
        if proc.stdout is not None:
            proc.stdout.close()


def run_command(
    cmd: list[str],
    *,
    limit: float,
    log_path: str,
) -> int:
    with open(log_path, "w", encoding="utf-8") as log:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            start_new_session=True,
        )
        try:
            out, _ = proc.communicate(timeout=limit)
            log.write(out or "")
            sys.stdout.write(out or "")
            return proc.returncode or 0
        except subprocess.TimeoutExpired:
            out = reap(proc)
            log.write(out)
            sys.stdout.write(out)
            print("not-run: journey timed out", file=sys.stderr)
            return 124
        finally:
            if proc.stdout is not None and not proc.stdout.closed:
                proc.stdout.close()


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) < 3:
        print("usage: run_timeout.py LIMIT LOG_PATH CMD...", file=sys.stderr)
        return 1
    return run_command(args[2:], limit=float(args[0]), log_path=args[1])


if __name__ == "__main__":
    raise SystemExit(main())
