#!/usr/bin/env python3
"""#70 software-lane evidence gate.

Runs the production PollingEngine measurement (Dart) and refuses a missing,
skipped, or zero-observation report. `--ui-profile`, `--competitor`,
`--physical-adapter` and `--sleep-walk` fail closed without an identified
device and must not be reported as PASS.
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
SIX_REQUIRED_MINIMUM = 8
SIX_SCHEDULED = ["010C", "010D", "015E", "0105", "0104", "0111"]
TWENTY_REQUIRED_MINIMUM = 8
TWENTY_SCHEDULED = [
    "010C",
    "010D",
    "015E",
    "0105",
    "0104",
    "0111",
    "010F",
    "010B",
    "0110",
    "010E",
    "010A",
    "012F",
    "0133",
    "0142",
    "0146",
    "015C",
    "0106",
    "0107",
    "011F",
    "012C",
]


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
    p50 = interarrival["p50"]
    p95 = interarrival["p95"]
    p99 = interarrival["p99"]
    if p50 < 0 or p95 < 0 or p99 < 0:
        raise GateError("interarrival quantiles must be nonnegative")
    if p50 > p95 or p95 > p99:
        raise GateError("interarrival quantiles must be nondecreasing")
    if report.get("errors") not in (0, 0.0):
        raise GateError("errors are not zero")
    if report.get("channels") != 3:
        raise GateError("channels must be 3 (RPM plus implicit speed and fuel rate)")
    scheduled = report.get("scheduledModeAndPid")
    if scheduled != ["010C", "010D", "015E"]:
        raise GateError("scheduledModeAndPid must be 010C/010D/015E")
    return report


def validate_six_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("six-channel report is not an object")
    if report.get("lane") != "software":
        raise GateError("six-channel lane is not software")
    if report.get("engine") != "PollingEngine":
        raise GateError("six-channel engine is not PollingEngine")
    if report.get("quantile") != "nearest-rank":
        raise GateError("six-channel quantile method is missing or not nearest-rank")
    if report.get("channels") != 6:
        raise GateError("a 3-channel report is not a 6-channel matrix")
    scheduled = report.get("scheduledModeAndPid")
    if scheduled != SIX_SCHEDULED:
        raise GateError("six-channel scheduledModeAndPid must be 010C/010D/015E/0105/0104/0111")
    per_channel = report.get("perChannel")
    if not isinstance(per_channel, dict):
        raise GateError("six-channel perChannel is missing")
    for pid in SIX_SCHEDULED:
        count = per_channel.get(pid)
        if not isinstance(count, int) or count < SIX_REQUIRED_MINIMUM:
            raise GateError(f"{pid} produced inadequate six-channel observations")
    observations = report.get("observations")
    if not isinstance(observations, int) or observations < SIX_REQUIRED_MINIMUM:
        raise GateError("six-channel observations are inadequate")
    if report.get("errors") not in (0, 0.0):
        raise GateError("six-channel errors are not zero")
    return report


def validate_twenty_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("twenty-channel report is not an object")
    if report.get("lane") != "software":
        raise GateError("twenty-channel lane is not software")
    if report.get("engine") != "PollingEngine":
        raise GateError("twenty-channel engine is not PollingEngine")
    if report.get("quantile") != "nearest-rank":
        raise GateError("twenty-channel quantile method is missing or not nearest-rank")
    if report.get("channels") != 20:
        raise GateError("a 6-channel report is not a 20-channel matrix")
    scheduled = report.get("scheduledModeAndPid")
    if scheduled != TWENTY_SCHEDULED:
        raise GateError("twenty-channel scheduledModeAndPid must be the 20 Mode 01 channels")
    per_channel = report.get("perChannel")
    if not isinstance(per_channel, dict):
        raise GateError("twenty-channel perChannel is missing")
    for pid in TWENTY_SCHEDULED:
        count = per_channel.get(pid)
        if not isinstance(count, int) or count < TWENTY_REQUIRED_MINIMUM:
            raise GateError(f"{pid} produced inadequate twenty-channel observations")
    observations = report.get("observations")
    if not isinstance(observations, int) or observations < TWENTY_REQUIRED_MINIMUM:
        raise GateError("twenty-channel observations are inadequate")
    if report.get("errors") not in (0, 0.0):
        raise GateError("twenty-channel errors are not zero")
    return report


def _flutter() -> str:
    pinned = Path.home() / "fvm/versions/3.47.0/bin/flutter"
    return os.environ.get("FLUTTER", str(pinned))


def prepare_output(output: Path) -> Path:
    output.mkdir(parents=True, exist_ok=True)
    report_path = output / "software.json"
    six_path = output / "software-six.json"
    twenty_path = output / "software-twenty.json"
    if report_path.exists():
        report_path.unlink()
    if six_path.exists():
        six_path.unlink()
    if twenty_path.exists():
        twenty_path.unlink()
    return report_path


def run_software(output: Path) -> dict:
    report_path = prepare_output(output)
    six_path = output / "software-six.json"
    twenty_path = output / "software-twenty.json"
    env = os.environ.copy()
    env["PERF_OBD_OUTPUT"] = str(output.resolve())
    app = Path(__file__).resolve().parents[2]
    cmd = [
        _flutter(),
        "test",
        "test/telemetry_demand/software_acquisition_measure_test.dart",
        "test/telemetry_demand/software_six_channel_measure_test.dart",
        "test/telemetry_demand/software_twenty_channel_measure_test.dart",
    ]
    completed = subprocess.run(cmd, cwd=app, env=env, check=False)
    if completed.returncode != 0:
        raise GateError("flutter test failed")
    if not report_path.is_file():
        raise GateError("software.json was not written")
    if not six_path.is_file():
        raise GateError("software-six.json was not written")
    if not twenty_path.is_file():
        raise GateError("software-twenty.json was not written")
    try:
        payload = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise GateError("software.json is not JSON") from exc
    try:
        six_payload = json.loads(six_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise GateError("software-six.json is not JSON") from exc
    try:
        twenty_payload = json.loads(twenty_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise GateError("software-twenty.json is not JSON") from exc
    validate_six_report(six_payload)
    validate_twenty_report(twenty_payload)
    return validate_report(payload)


def validate_ui_profile_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("ui-profile report is not an object")
    if report.get("lane") != "ui-profile":
        raise GateError("a software report is not a device UI profile")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("ui-profile without an identified device is not PASS")
    raise GateError("ui-profile lane is not-run without an identified device")


def validate_competitor_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("competitor report is not an object")
    if report.get("lane") != "competitor":
        raise GateError("a software report is not a competitor lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("competitor without an identified device is not PASS")
    raise GateError("competitor lane is not-run without an identified device")


def validate_physical_adapter_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("physical-adapter report is not an object")
    if report.get("lane") != "physical-adapter":
        raise GateError("a software report is not a physical-adapter lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("physical-adapter without an identified device is not PASS")
    raise GateError("physical-adapter lane is not-run without an identified device")


def _not_run_lane(output: Path, *, filename: str, message: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    stale = output / filename
    if stale.exists() or stale.is_symlink():
        stale.unlink()
    print(message, file=sys.stderr)
    return 2


_NOT_RUN_LANES = {
    "ui-profile": "ui-profile.json",
    "competitor": "competitor.json",
    "physical-adapter": "physical-adapter.json",
    "sleep-walk": "sleep-walk.json",
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--software", action="store_true")
    parser.add_argument("--ui-profile", action="store_true")
    parser.add_argument("--competitor", action="store_true")
    parser.add_argument("--physical-adapter", action="store_true")
    parser.add_argument("--sleep-walk", action="store_true")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    chosen = [
        name
        for name, on in (
            ("software", args.software),
            ("ui-profile", args.ui_profile),
            ("competitor", args.competitor),
            ("physical-adapter", args.physical_adapter),
            ("sleep-walk", args.sleep_walk),
        )
        if on
    ]
    if len(chosen) > 1:
        args.output.mkdir(parents=True, exist_ok=True)
        for name in chosen:
            filename = _NOT_RUN_LANES.get(name)
            if filename is None:
                continue
            stale = args.output / filename
            if stale.exists() or stale.is_symlink():
                stale.unlink()
        print("lane flags are mutually exclusive", file=sys.stderr)
        return 2
    if args.ui_profile:
        return _not_run_lane(
            args.output,
            filename="ui-profile.json",
            message="ui-profile lane is not-run without an identified device",
        )
    if args.competitor:
        return _not_run_lane(
            args.output,
            filename="competitor.json",
            message="competitor lane is not-run without an identified device",
        )
    if args.physical_adapter:
        return _not_run_lane(
            args.output,
            filename="physical-adapter.json",
            message="physical-adapter lane is not-run without an identified device",
        )
    if args.sleep_walk:
        return _not_run_lane(
            args.output,
            filename="sleep-walk.json",
            message="sleep-walk lane is not-run without an identified device",
        )
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
