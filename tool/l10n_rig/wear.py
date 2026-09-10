#!/usr/bin/env python3
"""#47 Wear OS lane.

Without `--execute` this is fail-closed not-run: planted wear.json is
deleted and the process exits 2.

With `--execute --serial` on an identified Wear emulator this launches
the rig Wear connect page and captures a host screencap. The field phone,
Pixel_9 `emulator-5554`, and QuietInbox `emulator-5556` are refused. A
host-entry wear_shell test is not this lane.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from png_gate import png_reject_reason


ROOT = Path(__file__).resolve().parents[2]
FIELD_SERIAL = "R5CX10VFFBA"
PHONE_SERIAL = "emulator-5554"
QUIETINBOX_SERIAL = "emulator-5556"
REFUSED_SERIALS = {FIELD_SERIAL, PHONE_SERIAL, QUIETINBOX_SERIAL}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
RIG_PACKAGE = "com.cbstudio.telltale.rig"
FIELD_PACKAGE = "com.cbstudio.telltale"
PACKAGES = (RIG_PACKAGE, FIELD_PACKAGE)
CONNECT_MARKERS = (
    "Demo simulator",
    "Demo 模擬器",
    "Demo-Simulator",
    "BLE adapters",
)
CASE_ID = "identifiedWearConnectScreen"


class GateError(Exception):
    """Evidence is not an honest Wear pass."""


def validate_wear_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("wear report is not an object")
    if report.get("lane") != "wear":
        raise GateError("a software report is not a wear lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("wear without an identified device is not PASS")
    if device == FIELD_SERIAL:
        raise GateError("wear refuses the field phone")
    if device == PHONE_SERIAL:
        raise GateError("wear refuses emulator-5554 (phone)")
    if device == QUIETINBOX_SERIAL:
        raise GateError("wear refuses emulator-5556")
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "gwear" not in fingerprint.lower():
        raise GateError("wear without a Wear emulator fingerprint is not PASS")
    if report.get("connect_shown") is not True:
        raise GateError("wear without connect-screen evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("wear nonzero execute exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("wear screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("wear all-zero screenshot hash is not PASS")
    case_ids = report.get("case_ids")
    if not isinstance(case_ids, list) or case_ids != [CASE_ID]:
        raise GateError("wear missing required case IDs")
    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("wear missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("wear missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("wear missing installed versionName")
    if report.get("apk_matches_runner_head") is True:
        raise GateError("wear must not claim the installed APK is this checkout")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "wear.json"
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def _not_run(output: Path, reason: str) -> int:
    output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(output)
    print(reason, file=sys.stderr)
    return 2


def _adb() -> str:
    explicit = os.environ.get("ADB")
    if explicit:
        return explicit
    home = Path.home() / "Library" / "Android" / "sdk" / "platform-tools" / "adb"
    if home.is_file():
        return str(home)
    return "adb"


def _identify(serial: str) -> str:
    if serial == FIELD_SERIAL:
        raise GateError("wear refuses the field phone")
    if serial == PHONE_SERIAL:
        raise GateError("wear refuses emulator-5554 (phone)")
    if serial == QUIETINBOX_SERIAL:
        raise GateError("wear refuses emulator-5556")
    completed = subprocess.run(
        [_adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("wear could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "gwear" not in fingerprint.lower():
        raise GateError(f"wear fingerprint is not a Wear emulator: {fingerprint}")
    return fingerprint


def _package_listed(listed_stdout: str, package: str) -> bool:
    needle = f"package:{package}"
    return any(line.strip() == needle for line in listed_stdout.splitlines())


def _run(serial: str, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [_adb(), "-s", serial, *args],
        check=False,
        capture_output=True,
        text=True,
    )


def _wait_for_activity(serial: str, package: str, timeout_s: float = 30.0) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        dumped = _run(serial, "shell", "dumpsys", "activity", "activities")
        out = dumped.stdout or ""
        for line in out.splitlines():
            if "topResumedActivity" not in line and "mFocusedApp=" not in line:
                continue
            if package in line and "MainActivity" in line:
                return
        time.sleep(0.5)
    raise GateError("wear MainActivity did not resume")


def _relaunch(serial: str, package: str) -> None:
    activity = f"{package}/com.cbstudio.telltale.MainActivity"
    _run(serial, "shell", "am", "force-stop", package)
    time.sleep(1.0)
    started = _run(
        serial,
        "shell",
        "am",
        "start",
        "-n",
        activity,
        "-f",
        "0x10000000",
    )
    if started.returncode != 0:
        raise GateError(
            f"wear could not start MainActivity: {started.stdout}{started.stderr}"
        )
    _wait_for_activity(serial, package)


def _ui_xml(serial: str) -> str:
    completed = subprocess.run(
        [_adb(), "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=False,
        capture_output=True,
    )
    return (completed.stdout or b"").decode("utf-8", "replace")


def _wait_for_connect(serial: str, package: str, timeout_s: float = 60.0) -> str:
    deadline = time.time() + timeout_s
    last = ""
    while time.time() < deadline:
        last = _ui_xml(serial)
        if any(marker in last for marker in CONNECT_MARKERS):
            return last
        time.sleep(1.0)
    raise GateError("wear connect screen did not appear")


def assert_png_has_visible_content(data: bytes) -> None:
    reason = png_reject_reason(data)
    if reason:
        raise GateError(reason)


def _screencap(serial: str, dest: Path) -> str:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as handle:
        captured = subprocess.run(
            [_adb(), "-s", serial, "exec-out", "screencap", "-p"],
            check=False,
            stdout=handle,
        )
    if captured.returncode != 0 or not dest.is_file() or dest.stat().st_size == 0:
        raise GateError("wear could not capture the connect screen")
    payload = dest.read_bytes()
    assert_png_has_visible_content(payload)
    return hashlib.sha256(payload).hexdigest()


def _installed_version_name(serial: str, package: str) -> str:
    dumped = _run(serial, "shell", "dumpsys", "package", package)
    for line in (dumped.stdout or "").splitlines():
        line = line.strip()
        if line.startswith("versionName="):
            return line.split("=", 1)[1].strip()
    raise GateError("wear could not read installed versionName")


def _installed_package(serial: str) -> str:
    listed = _run(serial, "shell", "pm", "list", "packages")
    out = listed.stdout or ""
    for package in PACKAGES:
        if _package_listed(out, package):
            return package
    raise GateError("wear telltale package is not installed")


def _git_head() -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("wear could not read HEAD")
    return completed.stdout.strip()


def _execute(serial: str, output: Path) -> dict:
    package = _installed_package(serial)
    command = [
        _adb(),
        "-s",
        serial,
        "exec-out",
        "screencap",
        "-p",
    ]
    _relaunch(serial, package)
    _wait_for_connect(serial, package)
    digest = _screencap(serial, output / "identified-wear-connect.png")
    return {
        "lane": "wear",
        "device": serial,
        "package": package,
        "command": command,
        "exit": 0,
        "connect_shown": True,
        "case_ids": [CASE_ID],
        "screenshot_sha256": digest,
        "runner_head_sha": _git_head(),
        "installed_version_name": _installed_version_name(serial, package),
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
            "wear lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "wear --execute requires --serial of a Wear emulator",
        )
    try:
        fingerprint = _identify(serial)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_wear_report(report)
    except GateError as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"wear execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "wear.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
