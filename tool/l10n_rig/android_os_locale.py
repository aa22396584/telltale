#!/usr/bin/env python3
"""#47 Android OS-locale / process-restart lane.

Fail closed without an identified device. A planted android-os-locale.json
is deleted and must not outlive a not-run. This leftover does not change
the phone language, restart an app process, invent a device id, or PASS a
host-entry report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest android-os-locale pass."""


def validate_android_os_locale_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("android-os-locale report is not an object")
    if report.get("lane") != "android-os-locale":
        raise GateError("a software report is not an android-os-locale lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError(
            "android-os-locale without an identified device is not PASS"
        )
    raise GateError(
        "android-os-locale lane is not-run without an identified device"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "android-os-locale.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(
        "android-os-locale lane is not-run without an identified device",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
