#!/usr/bin/env python3
"""#47 320dp / narrow lane.

Without `--execute` this is fail-closed not-run. With `--execute --serial
emulator-5554` this overrides display width to 320dp, relaunches the rig
connect screen, and captures a host screencap. The field phone and
QuietInbox emulator-5556 are refused.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

import phone_rig as rig

LANE = "narrow"
CASE_ID = "narrow320dpConnectScreenShown"
WIDTH_DP = 320
SHA256_RE = rig.SHA256_RE
SIZE_RE = re.compile(r"Override size:\s*(\d+)x(\d+)", re.I)
DENSITY_RE = re.compile(r"Physical density:\s*(\d+)", re.I)


class GateError(Exception):
    """Evidence is not an honest 320dp / narrow pass."""


def validate_narrow_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("narrow report is not an object")
    if report.get("lane") != LANE:
        raise GateError("a software report is not a narrow lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("narrow without an identified device is not PASS")
    if device == rig.FIELD_SERIAL:
        raise GateError("narrow refuses the field phone")
    if device == rig.QUIETINBOX_SERIAL:
        raise GateError("narrow refuses emulator-5556")
    if device != rig.ALLOWED_SERIAL:
        raise GateError(
            f"narrow serial {device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("narrow without an AOSP emulator fingerprint is not PASS")
    if report.get("width_dp") != WIDTH_DP:
        raise GateError("narrow without width_dp 320 is not PASS")
    if report.get("connect_shown") is not True:
        raise GateError("narrow without connect-screen evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("narrow nonzero execute exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("narrow screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("narrow all-zero screenshot hash is not PASS")
    if report.get("case_ids") != [CASE_ID]:
        raise GateError("narrow missing required case IDs")
    if not isinstance(report.get("command"), list) or not report.get("command"):
        raise GateError("narrow missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("narrow missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("narrow missing installed versionName")
    if report.get("apk_matches_runner_head") is True:
        raise GateError("narrow must not claim the installed APK is this checkout")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "narrow.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def _not_run(output: Path, reason: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(output)
    print(reason, file=sys.stderr)
    return 2


def _wm_size(serial: str) -> str:
    got = rig.run(serial, "shell", "wm", "size")
    return got.stdout or ""


def _wm_density(serial: str) -> int:
    got = rig.run(serial, "shell", "wm", "density")
    match = DENSITY_RE.search(got.stdout or "")
    if not match:
        raise GateError("narrow could not read wm density")
    return int(match.group(1))


def _height_dp(serial: str, density: int) -> int:
    size = _wm_size(serial)
    match = SIZE_RE.search(size)
    if match:
        height_px = int(match.group(2))
    else:
        physical = re.search(r"Physical size:\s*\d+x(\d+)", size)
        if not physical:
            raise GateError("narrow could not read wm size")
        height_px = int(physical.group(1))
    return max(1, round(height_px * 160 / density))


def _width_dp_now(serial: str, density: int) -> int:
    size = _wm_size(serial)
    match = SIZE_RE.search(size)
    if match:
        width_px = int(match.group(1))
    else:
        physical = re.search(r"Physical size:\s*(\d+)x", size)
        if not physical:
            raise GateError("narrow could not read wm size")
        width_px = int(physical.group(1))
    return round(width_px * 160 / density)


def _execute(serial: str, output: Path) -> dict:
    rig.require_package(serial, LANE)
    density = _wm_density(serial)
    height_dp = _height_dp(serial, density)
    size_arg = f"{WIDTH_DP}dpx{height_dp}dp"
    command = [rig.adb(), "-s", serial, "shell", "wm", "size", size_arg]
    try:
        set_size = rig.run(serial, "shell", "wm", "size", size_arg)
        if set_size.returncode != 0:
            raise GateError(
                f"narrow could not set wm size: {set_size.stdout}{set_size.stderr}"
            )
        width = _width_dp_now(serial, density)
        if width != WIDTH_DP:
            raise GateError(f"narrow width_dp is {width}, not 320")
        rig.relaunch(serial, LANE)
        rig.wait_for_connect(serial, LANE)
        digest = rig.screencap(serial, output / "narrow-connect.png", LANE)
    finally:
        rig.run(serial, "shell", "wm", "size", "reset")
    return {
        "lane": LANE,
        "device": serial,
        "package": rig.PACKAGE,
        "command": command,
        "exit": 0,
        "width_dp": WIDTH_DP,
        "connect_shown": True,
        "case_ids": [CASE_ID],
        "screenshot_sha256": digest,
        "runner_head_sha": rig.git_head(LANE),
        "installed_version_name": rig.installed_version_name(serial, LANE),
        "apk_matches_runner_head": False,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--serial")
    args = parser.parse_args(argv)
    if not args.execute:
        return _not_run(
            args.output,
            "narrow lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "narrow --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = rig.identify(serial, LANE)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_narrow_report(report)
    except (GateError, rig.PhoneRigError) as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"narrow execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "narrow.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
