#!/usr/bin/env python3
"""#79 external Torque qualification lane.

Fail closed without a named Torque Pro version/method. A planted
external-torque.json is deleted and must not outlive a not-run. This leftover
does not run Torque Pro, invent a version, or PASS a software report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


class GateError(Exception):
    """Evidence is not an honest external-Torque pass."""


def validate_external_torque_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("external-torque report is not an object")
    if report.get("lane") != "external-torque":
        raise GateError("a software report is not an external-torque lane")
    version = report.get("torque_version")
    if not isinstance(version, str) or not version.strip():
        raise GateError(
            "external-torque without a named Torque Pro version is not PASS"
        )
    raise GateError(
        "external-torque lane is not-run without executing a named Torque Pro build"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    args.output.mkdir(parents=True, exist_ok=True)
    stale = args.output / "external-torque.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(
        "external-torque lane is not-run without a named Torque Pro version",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
