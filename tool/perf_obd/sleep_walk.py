#!/usr/bin/env python3
"""#70 sleep-walk lane.

Fail closed without an identified device. A planted sleep-walk.json is
deleted and must not outlive a not-run. This leftover does not walk a
phone, invent a device id, or PASS a software report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest sleep-walk pass."""


def validate_sleep_walk_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("sleep-walk report is not an object")
    if report.get("lane") != "sleep-walk":
        raise GateError("a software report is not a sleep-walk lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("sleep-walk without an identified device is not PASS")
    raise GateError("sleep-walk lane is not-run without an identified device")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "sleep-walk.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print("sleep-walk lane is not-run without an identified device", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
