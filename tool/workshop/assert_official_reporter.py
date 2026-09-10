#!/usr/bin/env python3
"""Current #11 campaign: official Dart JSON reporter → parser → required cases.

Reads the pinned-SDK captures already in the tree. Invented top-level
``type=test`` identities must not pass. A failing reporter stream must not
yield case IDs.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import validate_plan

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "test" / "tool" / "fixtures"


def _load(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


def main() -> int:
    success = validate_plan.parse_flutter_case_ids(_load("official-success.jsonl"))
    if success != ["independent reporter success"]:
        print(
            f"official-success rejected or mismatched: {success!r}",
            file=sys.stderr,
        )
        return 2
    captured = validate_plan.parse_flutter_case_ids(
        _load("fnv1a64_reporter_capture.jsonl")
    )
    expected = [
        "FNV-1a 64 preserves canonical vectors",
        "FNV-1a 64 is invariant across arbitrary stream chunks",
    ]
    if captured != expected:
        print(f"pinned-sdk capture mismatched: {captured!r}", file=sys.stderr)
        return 2
    failing = validate_plan.parse_flutter_case_ids(
        _load("reporter_fail_capture.jsonl")
    )
    if failing is not None:
        print(
            f"failing reporter must not yield case ids: {failing!r}",
            file=sys.stderr,
        )
        return 2
    invented = "\n".join(
        [
            json.dumps({"type": "test", "id": 1, "name": "smoke"}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success"}),
            json.dumps({"type": "done", "success": True}),
        ]
    )
    if validate_plan.parse_flutter_case_ids(invented) is not None:
        print(
            "invented type=test stream must not supply identities",
            file=sys.stderr,
        )
        return 2
    print(
        "official reporter parser: success, captured, fail-closed, invented rejected"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
