#!/usr/bin/env python3
"""#47 landscape / 橫向 lane.

Without `--execute` this is fail-closed not-run. With `--execute --serial
emulator-5554` this locks user rotation to landscape, relaunches the rig
connect screen, and captures a host screencap. The field phone and
QuietInbox emulator-5556 are refused.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import phone_rig as rig

LANE = "landscape"
CASE_ID = "landscapeConnectScreenShown"
SHA256_RE = rig.SHA256_RE


class GateError(Exception):
    """Evidence is not an honest landscape pass."""


def validate_landscape_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("landscape report is not an object")
    if report.get("lane") != LANE:
        raise GateError("a software report is not a landscape lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("landscape without an identified device is not PASS")
    if device == rig.FIELD_SERIAL:
        raise GateError("landscape refuses the field phone")
    if device == rig.QUIETINBOX_SERIAL:
        raise GateError("landscape refuses emulator-5556")
    if device != rig.ALLOWED_SERIAL:
        raise GateError(
            f"landscape serial {device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("landscape without an AOSP emulator fingerprint is not PASS")
    if report.get("orientation") != "landscape":
        raise GateError("landscape without landscape orientation is not PASS")
    if report.get("connect_shown") is not True:
        raise GateError("landscape without connect-screen evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("landscape nonzero execute exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("landscape screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("landscape all-zero screenshot hash is not PASS")
    if report.get("case_ids") != [CASE_ID]:
        raise GateError("landscape missing required case IDs")
    if not isinstance(report.get("command"), list) or not report.get("command"):
        raise GateError("landscape missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("landscape missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("landscape missing installed versionName")
    if report.get("apk_matches_runner_head") is True:
        raise GateError("landscape must not claim the installed APK is this checkout")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "landscape.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def _not_run(output: Path, reason: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(output)
    print(reason, file=sys.stderr)
    return 2


def _rotation(serial: str) -> str:
    got = rig.run(serial, "shell", "wm", "user-rotation")
    return (got.stdout or "").strip()


def _lock_landscape(serial: str) -> None:
    locked = rig.run(serial, "shell", "wm", "user-rotation", "lock", "1")
    if locked.returncode != 0:
        raise GateError(
            f"landscape could not lock rotation: {locked.stdout}{locked.stderr}"
        )


def _restore_rotation(serial: str, previous: str) -> None:
    if previous.startswith("lock"):
        parts = previous.split()
        angle = parts[-1] if len(parts) > 1 else "0"
        rig.run(serial, "shell", "wm", "user-rotation", "lock", angle)
        return
    rig.run(serial, "shell", "wm", "user-rotation", "free")


def _orientation(serial: str) -> str:
    dumped = rig.run(serial, "shell", "dumpsys", "window", "displays")
    out = dumped.stdout or ""
    if "mCurrentRotation=ROTATION_90" in out or "mCurrentRotation=ROTATION_270" in out:
        return "landscape"
    match = re.search(r"cur=(\d+)x(\d+)", out)
    if match and int(match.group(1)) > int(match.group(2)):
        return "landscape"
    return "portrait"


def _wait_for_landscape(serial: str, timeout_s: float = 10.0) -> None:
    deadline = time.time() + timeout_s
    last = "portrait"
    while time.time() < deadline:
        last = _orientation(serial)
        if last == "landscape":
            return
        time.sleep(0.3)
    raise GateError(f"landscape rotation is {last}")


def _execute(serial: str, output: Path) -> dict:
    rig.require_package(serial, LANE)
    previous = _rotation(serial)
    command = [rig.adb(), "-s", serial, "shell", "wm", "user-rotation", "lock", "1"]
    try:
        _lock_landscape(serial)
        _wait_for_landscape(serial)
        rig.relaunch(serial, LANE)
        rig.wait_for_connect(serial, LANE)
        if _orientation(serial) != "landscape":
            raise GateError("landscape rotation reverted before capture")
        digest = rig.screencap(
            serial, output / "landscape-connect.png", LANE
        )
    finally:
        _restore_rotation(serial, previous)
    return {
        "lane": LANE,
        "device": serial,
        "package": rig.PACKAGE,
        "command": command,
        "exit": 0,
        "orientation": "landscape",
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
            "landscape lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "landscape --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = rig.identify(serial, LANE)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_landscape_report(report)
    except (GateError, rig.PhoneRigError) as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"landscape execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "landscape.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
