#!/usr/bin/env python3
"""#47 native OS-dialog lane.

Fail closed without an identified device. A planted native-dialog.json is
deleted and must not outlive a not-run. This leftover does not open an OS
share chooser, walk a phone, invent a device id, or PASS a host-entry report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest native-dialog pass."""


def validate_native_dialog_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("native-dialog report is not an object")
    if report.get("lane") != "native-dialog":
        raise GateError("a software report is not a native-dialog lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("native-dialog without an identified device is not PASS")
    raise GateError("native-dialog lane is not-run without an identified device")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "native-dialog.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(
        "native-dialog lane is not-run without an identified device",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
