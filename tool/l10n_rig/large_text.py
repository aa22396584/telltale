#!/usr/bin/env python3
"""#47 large-text / 大字 lane.

Without `--execute` this is fail-closed not-run. With `--execute --serial
emulator-5554` this sets font_scale 1.3, relaunches the rig connect
screen, and captures a host screencap. The field phone and QuietInbox
emulator-5556 are refused.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import phone_rig as rig

LANE = "large-text"
CASE_ID = "largeTextConnectScreenShown"
FONT_SCALE = "1.3"
SHA256_RE = rig.SHA256_RE


class GateError(Exception):
    """Evidence is not an honest large-text / 大字 pass."""


def validate_large_text_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("large-text report is not an object")
    if report.get("lane") != LANE:
        raise GateError("a software report is not a large-text lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("large-text without an identified device is not PASS")
    if device == rig.FIELD_SERIAL:
        raise GateError("large-text refuses the field phone")
    if device == rig.QUIETINBOX_SERIAL:
        raise GateError("large-text refuses emulator-5556")
    if device != rig.ALLOWED_SERIAL:
        raise GateError(
            f"large-text serial {device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("large-text without an AOSP emulator fingerprint is not PASS")
    if report.get("font_scale") != FONT_SCALE:
        raise GateError("large-text without font_scale 1.3 is not PASS")
    if report.get("connect_shown") is not True:
        raise GateError("large-text without connect-screen evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("large-text nonzero execute exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("large-text screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("large-text all-zero screenshot hash is not PASS")
    if report.get("case_ids") != [CASE_ID]:
        raise GateError("large-text missing required case IDs")
    if not isinstance(report.get("command"), list) or not report.get("command"):
        raise GateError("large-text missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("large-text missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("large-text missing installed versionName")
    if report.get("apk_matches_runner_head") is True:
        raise GateError("large-text must not claim the installed APK is this checkout")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "large-text.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def _not_run(output: Path, reason: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(output)
    print(reason, file=sys.stderr)
    return 2


def _font_scale(serial: str) -> str:
    got = rig.run(serial, "shell", "settings", "get", "system", "font_scale")
    return (got.stdout or "").strip() or "1.0"


def _set_font_scale(serial: str, value: str) -> None:
    put = rig.run(serial, "shell", "settings", "put", "system", "font_scale", value)
    if put.returncode != 0:
        raise GateError(f"large-text could not set font_scale {value}")


def _execute(serial: str, output: Path) -> dict:
    rig.require_package(serial, LANE)
    previous = _font_scale(serial)
    command = [
        rig.adb(),
        "-s",
        serial,
        "shell",
        "settings",
        "put",
        "system",
        "font_scale",
        FONT_SCALE,
    ]
    try:
        _set_font_scale(serial, FONT_SCALE)
        rig.relaunch(serial, LANE)
        rig.wait_for_connect(serial, LANE)
        digest = rig.screencap(
            serial, output / "large-text-connect.png", LANE
        )
    finally:
        _set_font_scale(serial, previous if previous else "1.0")
    return {
        "lane": LANE,
        "device": serial,
        "package": rig.PACKAGE,
        "command": command,
        "exit": 0,
        "font_scale": FONT_SCALE,
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
            "large-text lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "large-text --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = rig.identify(serial, LANE)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_large_text_report(report)
    except (GateError, rig.PhoneRigError) as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"large-text execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "large-text.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
