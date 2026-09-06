#!/usr/bin/env python3
"""Fail-closed guard for `flutter test --reporter json` oracle reports.

The Flutter JSON reporter prints one object per line. A skipped suite still
exits 0, so CI must parse the report *and* keep the process exit code. This
program refuses truncated JSON, missing identity, duplicate terminal events,
global errors, skips, and a runner that already failed.

Messages name event kinds and identifiers only. They must not echo raw
transcript, VIN, stack traces, or error bodies from the report.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys


class GuardError(Exception):
    """Oracle report is not an honest pass."""


def _parse_events(text: str) -> list[dict]:
    if not text.strip():
        raise GuardError("no tests: empty report")

    events: list[dict] = []
    for line_no, raw_line in enumerate(text.splitlines(), start=1):
        raw = raw_line.strip()
        if not raw:
            continue
        # `flutter test --reporter json` can print a lock/startup line before
        # the first event. Ignore non-objects. A line that starts with '{' is
        # claiming to be an event and must parse.
        if not raw.startswith("{"):
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError as exc:
            if not raw.endswith("}"):
                raise GuardError(f"truncated JSON at line {line_no}") from exc
            raise GuardError(f"malformed JSON at line {line_no}") from exc
        if not isinstance(event, dict):
            raise GuardError(f"non-object JSON at line {line_no}")
        events.append(event)
    if not events:
        raise GuardError("no tests: no JSON events")
    return events


def _require_testid(event: dict, kind: str) -> object:
    if "testID" not in event or event.get("testID") is None:
        raise GuardError(f"missing identity on {kind}")
    return event["testID"]


def assert_oracle_report(
    report: Path,
    *,
    expected: int,
    runner_exit: int = 0,
    evidence_dir: Path | None = None,
) -> tuple[int, str]:
    """Return (visible_passed, ok_message) or raise GuardError."""
    text = report.read_text(encoding="utf-8", errors="replace").lstrip("\ufeff")
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    passed = 0
    message = ""
    error: GuardError | None = None
    try:
        passed, message = _evaluate(text, expected=expected, runner_exit=runner_exit)
    except GuardError as exc:
        error = exc
        message = str(exc)
    if evidence_dir is not None:
        _write_evidence(
            evidence_dir,
            report=report,
            digest=digest,
            runner_exit=runner_exit,
            expected=expected,
            passed=passed,
            ok=error is None,
            message=message,
        )
    if error is not None:
        raise error
    return passed, message


def _evaluate(text: str, *, expected: int, runner_exit: int) -> tuple[int, str]:
    if runner_exit != 0:
        raise GuardError(f"runner exit {runner_exit} is not 0")

    events = _parse_events(text)
    seen_ids: set[object] = set()
    passed = 0
    done_index: int | None = None

    for index, event in enumerate(events):
        etype = event.get("type")
        if done_index is not None:
            if etype == "done":
                raise GuardError("duplicate done")
            raise GuardError(f"event after terminal done ({etype})")

        if etype == "done":
            if "success" not in event:
                raise GuardError("terminal done missing success")
            if event.get("success") is not True:
                raise GuardError("done.success is not true")
            done_index = index
            continue

        if etype == "error":
            if event.get("testID") is None:
                raise GuardError("global error")
            raise GuardError(f"error event testID={event.get('testID')}")

        if etype != "testDone":
            continue

        test_id = _require_testid(event, "testDone")
        if "result" not in event:
            raise GuardError(f"testDone testID={test_id} missing result")
        hidden = bool(event.get("hidden"))
        skipped = bool(event.get("skipped"))
        result = event.get("result")

        if hidden:
            if skipped:
                continue
            if result != "success":
                raise GuardError(f"hidden failure testID={test_id}")
            continue

        if test_id in seen_ids:
            raise GuardError(f"duplicate testID {test_id}")
        seen_ids.add(test_id)

        if skipped:
            raise GuardError(f"skip testID={test_id}")
        if result != "success":
            raise GuardError(f"failed testID={test_id} result={result}")
        passed += 1

    if done_index is None:
        raise GuardError("missing terminal done")
    if done_index != len(events) - 1:
        raise GuardError("terminal done is not last")
    if passed == 0:
        raise GuardError("no tests")
    if passed != expected:
        raise GuardError(f"expected {expected} oracle tests, {passed} ran")
    return passed, f"OK: every oracle test really ran. passed={passed}"


def _write_evidence(
    evidence_dir: Path,
    *,
    report: Path,
    digest: str,
    runner_exit: int,
    expected: int,
    passed: int,
    ok: bool,
    message: str,
) -> None:
    evidence_dir.mkdir(parents=True, exist_ok=True)
    copied = evidence_dir / "report.jsonl"
    if report.resolve() != copied.resolve():
        shutil.copyfile(report, copied)
    (evidence_dir / "report.sha256").write_text(digest + "\n", encoding="utf-8")
    (evidence_dir / "runner_exit.txt").write_text(f"{runner_exit}\n", encoding="utf-8")
    attempt = {
        "ok": ok,
        "expected": expected,
        "passed": passed,
        "runner_exit": runner_exit,
        "report_sha256": digest,
        "message": message,
    }
    (evidence_dir / "attempt.json").write_text(
        json.dumps(attempt, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("expected", type=int)
    parser.add_argument("--runner-exit", type=int, default=0)
    parser.add_argument("--evidence-dir", type=Path, default=None)
    args = parser.parse_args(argv)
    try:
        _passed, message = assert_oracle_report(
            args.report,
            expected=args.expected,
            runner_exit=args.runner_exit,
            evidence_dir=args.evidence_dir,
        )
    except GuardError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(message)
    return 0


if __name__ == "__main__":
    sys.exit(main())
