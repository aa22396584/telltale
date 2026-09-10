#!/usr/bin/env python3
"""#47 screenshot SHA-256 lane.

Fail closed without an identified device. A planted screenshot.json is
deleted and must not outlive a not-run. This leftover does not capture a
screen, invent a device id, walk a phone, or PASS a host-entry report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest screenshot pass."""


def validate_screenshot_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("screenshot report is not an object")
    if report.get("lane") != "screenshot":
        raise GateError("a software report is not a screenshot lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("screenshot without an identified device is not PASS")
    raise GateError("screenshot lane is not-run without an identified device")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "screenshot.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(
        "screenshot lane is not-run without an identified device",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
