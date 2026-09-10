#!/usr/bin/env python3
"""Shared AOSP phone execute helpers for #47 geometry lanes.

Refuses the field phone and QuietInbox emulator-5556. The disposable
Pixel_9 emulator-5554 is the only allowed serial.
"""

from __future__ import annotations

import hashlib
import os
import re
import subprocess
import time
from pathlib import Path

from png_gate import png_reject_reason

FIELD_SERIAL = "R5CX10VFFBA"
ALLOWED_SERIAL = "emulator-5554"
QUIETINBOX_SERIAL = "emulator-5556"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PACKAGE = "com.cbstudio.telltale.rig"
ACTIVITY = f"{PACKAGE}/com.cbstudio.telltale.MainActivity"
CONNECT_MARKERS = ("built-in simulator", "內建模擬器", "integrierten Simulator")
ROOT = Path(__file__).resolve().parents[2]


class PhoneRigError(Exception):
    """Identified-device evidence is not honest."""


def adb() -> str:
    explicit = os.environ.get("ADB")
    if explicit:
        return explicit
    home = Path.home() / "Library" / "Android" / "sdk" / "platform-tools" / "adb"
    if home.is_file():
        return str(home)
    return "adb"


def run(serial: str, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [adb(), "-s", serial, *args],
        check=False,
        capture_output=True,
        text=True,
    )


def identify(serial: str, lane: str) -> str:
    if serial == FIELD_SERIAL:
        raise PhoneRigError(f"{lane} refuses the field phone")
    if serial == QUIETINBOX_SERIAL:
        raise PhoneRigError(f"{lane} refuses emulator-5556")
    if serial != ALLOWED_SERIAL:
        raise PhoneRigError(
            f"{lane} serial {serial} is not the disposable AOSP emulator"
        )
    completed = subprocess.run(
        [adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise PhoneRigError(f"{lane} could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "sdk_gphone" not in fingerprint:
        raise PhoneRigError(f"{lane} fingerprint is not AOSP emulator: {fingerprint}")
    return fingerprint


def package_listed(listed_stdout: str, package: str) -> bool:
    needle = f"package:{package}"
    return any(line.strip() == needle for line in listed_stdout.splitlines())


def require_package(serial: str, lane: str) -> None:
    listed = run(serial, "shell", "pm", "list", "packages", PACKAGE)
    if not package_listed(listed.stdout or "", PACKAGE):
        raise PhoneRigError(f"{lane} rig package is not installed")


def wait_for_activity(serial: str, lane: str, timeout_s: float = 20.0) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        dumped = run(serial, "shell", "dumpsys", "activity", "activities")
        out = dumped.stdout or ""
        for line in out.splitlines():
            if "topResumedActivity" not in line and "mFocusedApp=" not in line:
                continue
            if PACKAGE in line and "MainActivity" in line:
                return
        time.sleep(0.5)
    raise PhoneRigError(f"{lane} MainActivity did not resume")


def relaunch(serial: str, lane: str) -> None:
    run(serial, "shell", "am", "force-stop", "com.android.intentresolver")
    run(serial, "shell", "am", "force-stop", PACKAGE)
    time.sleep(1.0)
    started = run(
        serial,
        "shell",
        "am",
        "start",
        "-n",
        ACTIVITY,
        "-f",
        "0x10000000",
    )
    if started.returncode != 0:
        raise PhoneRigError(
            f"{lane} could not start MainActivity: {started.stdout}{started.stderr}"
        )
    wait_for_activity(serial, lane)


def ui_xml(serial: str) -> str:
    completed = subprocess.run(
        [adb(), "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=False,
        capture_output=True,
    )
    return (completed.stdout or b"").decode("utf-8", "replace")


def wait_for_connect(serial: str, lane: str, timeout_s: float = 45.0) -> str:
    deadline = time.time() + timeout_s
    last = ""
    while time.time() < deadline:
        last = ui_xml(serial)
        if PACKAGE in last and any(marker in last for marker in CONNECT_MARKERS):
            return last
        time.sleep(1.0)
    raise PhoneRigError(f"{lane} connect screen did not appear")


def screencap(serial: str, dest: Path, lane: str) -> str:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as handle:
        captured = subprocess.run(
            [adb(), "-s", serial, "exec-out", "screencap", "-p"],
            check=False,
            stdout=handle,
        )
    if captured.returncode != 0 or not dest.is_file() or dest.stat().st_size == 0:
        raise PhoneRigError(f"{lane} could not capture the connect screen")
    payload = dest.read_bytes()
    reason = png_reject_reason(payload)
    if reason:
        raise PhoneRigError(reason)
    return hashlib.sha256(payload).hexdigest()


def installed_version_name(serial: str, lane: str) -> str:
    dumped = run(serial, "shell", "dumpsys", "package", PACKAGE)
    for line in (dumped.stdout or "").splitlines():
        line = line.strip()
        if line.startswith("versionName="):
            return line.split("=", 1)[1].strip()
    raise PhoneRigError(f"{lane} could not read installed versionName")


def git_head(lane: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise PhoneRigError(f"{lane} could not read HEAD")
    return completed.stdout.strip()
