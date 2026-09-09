#!/usr/bin/env python3
"""#70 software-lane evidence gate.

Runs the production PollingEngine measurement (Dart) and refuses a missing,
skipped, or zero-observation report. Physical-adapter and competitor lanes
are not implemented here and must not be reported as PASS.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


class GateError(Exception):
    """Evidence is not an honest software-lane pass."""


REQUIRED_MINIMUM = 20


def validate_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("report is not an object")
    if report.get("lane") != "software":
        raise GateError("lane is not software")
    if report.get("engine") != "PollingEngine":
        raise GateError("engine is not PollingEngine")
    if report.get("quantile") != "nearest-rank":
        raise GateError("quantile method is missing or not nearest-rank")
    observations = report.get("observations")
    if not isinstance(observations, int) or observations <= 0:
        raise GateError("zero observations are not PASS")
    if observations < REQUIRED_MINIMUM:
        raise GateError("inadequate observations are not PASS")
    interarrival = report.get("interarrivalMs")
    if not isinstance(interarrival, dict):
        raise GateError("interarrivalMs is missing")
    for key in ("n", "p50", "p95", "p99"):
        value = interarrival.get(key)
        if not isinstance(value, int):
            raise GateError(f"interarrivalMs.{key} is missing")
    if interarrival["n"] < REQUIRED_MINIMUM - 1:
        raise GateError("interarrival sample count is inadequate")
    if report.get("errors") not in (0, 0.0):
        raise GateError("errors are not zero")
    return report


def _flutter() -> str:
    pinned = Path.home() / "fvm/versions/3.47.0/bin/flutter"
    return os.environ.get("FLUTTER", str(pinned))


def prepare_output(output: Path) -> Path:
    output.mkdir(parents=True, exist_ok=True)
    report_path = output / "software.json"
    if report_path.exists():
        report_path.unlink()
    return report_path


def run_software(output: Path) -> dict:
    report_path = prepare_output(output)
    env = os.environ.copy()
    env["PERF_OBD_OUTPUT"] = str(output.resolve())
    app = Path(__file__).resolve().parents[2]
    cmd = [
        _flutter(),
        "test",
        "test/telemetry_demand/software_acquisition_measure_test.dart",
    ]
    completed = subprocess.run(cmd, cwd=app, env=env, check=False)
    if completed.returncode != 0:
        raise GateError("flutter test failed")
    if not report_path.is_file():
        raise GateError("software.json was not written")
    try:
        payload = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise GateError("software.json is not JSON") from exc
    return validate_report(payload)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--software", action="store_true")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    if not args.software:
        print("physical/competitor lanes are not-run in this leftover", file=sys.stderr)
        return 2
    try:
        report = run_software(args.output)
    except GateError as exc:
        print(f"perf_obd: {exc}", file=sys.stderr)
        return 1
    print(json.dumps({"ok": True, "observations": report["observations"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
