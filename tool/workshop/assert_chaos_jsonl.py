#!/usr/bin/env python3
"""Require a chaos JSONL transcript to show the injected fault and command."""

from __future__ import annotations

import json
import sys


def records(path: str) -> list[dict[str, object]]:
    out: list[dict[str, object]] = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            out.append(json.loads(line))
    return out


def decode_command(data_hex: object) -> str:
    if not isinstance(data_hex, str):
        return ""
    try:
        return bytes.fromhex(data_hex).decode("ascii", "replace")
    except ValueError:
        return ""


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(
            "usage: assert_chaos_jsonl.py LOG.jsonl [FAULT PREFIX] [--require-chunks N]",
            file=sys.stderr,
        )
        return 2
    path = argv[1]
    fault = ""
    prefix = ""
    require_chunks = 0
    rest = argv[2:]
    i = 0
    positional: list[str] = []
    while i < len(rest):
        if rest[i] == "--require-chunks":
            require_chunks = int(rest[i + 1])
            i += 2
            continue
        positional.append(rest[i])
        i += 1
    if positional:
        fault = positional[0]
    if len(positional) > 1:
        prefix = positional[1]
    rows = records(path)
    if not rows:
        print("FAIL: chaos JSONL is empty", file=sys.stderr)
        return 1
    if fault:
        faults = [
            row
            for row in rows
            if row.get("direction") == "fault" and row.get("fault") == fault
        ]
        if not faults:
            print(
                f"FAIL: no JSONL fault={fault} record; injection did not happen",
                file=sys.stderr,
            )
            return 1
        consumed = faults[0].get("command")
        matching = [
            row
            for row in rows
            if row.get("direction") == "client_to_upstream"
            and row.get("command") == consumed
            and decode_command(row.get("data_hex")).upper().startswith(prefix.upper())
        ]
        if not matching:
            print(
                f"FAIL: fault {fault} consumed command {consumed} "
                f"but no client_to_upstream started with {prefix!r}",
                file=sys.stderr,
            )
            return 1
        print(
            f"OK: fault={fault} command={consumed} prefix={prefix} "
            f"run_id={rows[0].get('run_id')}"
        )
    if require_chunks:
        by_command: dict[object, set[object]] = {}
        for row in rows:
            if row.get("direction") != "upstream_to_client":
                continue
            by_command.setdefault(row.get("command"), set()).add(row.get("chunk"))
        if not any(len(chunks) >= require_chunks for chunks in by_command.values()):
            print(
                f"FAIL: JSONL has no reply split into {require_chunks}+ chunks",
                file=sys.stderr,
            )
            return 1
        print(f"OK: fragmentation observed (>= {require_chunks} chunks)")
    if not fault and not require_chunks:
        print("FAIL: nothing to assert", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
