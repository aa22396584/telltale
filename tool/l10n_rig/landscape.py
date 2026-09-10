#!/usr/bin/env python3
"""#47 landscape / 橫向 lane.

Fail closed without an identified device. A planted landscape.json is
deleted and must not outlive a not-run. This leftover does not rotate a
window, invent a device id, walk a phone, or PASS a host-entry report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest landscape pass."""


def validate_landscape_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("landscape report is not an object")
    if report.get("lane") != "landscape":
        raise GateError("a software report is not a landscape lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("landscape without an identified device is not PASS")
    raise GateError("landscape lane is not-run without an identified device")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "landscape.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(
        "landscape lane is not-run without an identified device",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
