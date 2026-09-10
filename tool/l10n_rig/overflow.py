#!/usr/bin/env python3
"""#47 overflow / large-text lane.

Without `--execute` this is fail-closed not-run: planted overflow.json is
deleted and the process exits 2.

With `--execute --serial emulator-5554` on the identified disposable AOSP
emulator this sets font_scale 1.3, relaunches the rig connect screen, and
fails if Flutter logs a RenderFlex overflow. The field phone is refused.
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
ALLOWED_SERIAL = "emulator-5554"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PACKAGE = "com.cbstudio.telltale.rig"
ACTIVITY = f"{PACKAGE}/com.cbstudio.telltale.MainActivity"
FONT_SCALE = "1.3"
CONNECT_MARKERS = ("built-in simulator", "內建模擬器", "integrierten Simulator")
OVERFLOW_RE = re.compile(r"RenderFlex overflowed|A RenderFlex overflowed", re.I)
CASE_ID = "largeTextConnectScreenHasNoRenderFlexOverflow"


class GateError(Exception):
    """Evidence is not an honest overflow pass."""


def validate_overflow_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("overflow report is not an object")
    if report.get("lane") != "overflow":
        raise GateError("a software report is not an overflow lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("overflow without an identified device is not PASS")
    if device == FIELD_SERIAL:
        raise GateError("overflow refuses the field phone")
    if device != ALLOWED_SERIAL:
        raise GateError(
            f"overflow serial {device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("overflow without an AOSP emulator fingerprint is not PASS")
    if report.get("font_scale") != FONT_SCALE:
        raise GateError("overflow without font_scale 1.3 is not PASS")
    if report.get("connect_shown") is not True:
        raise GateError("overflow without connect-screen evidence is not PASS")
    if report.get("overflow_detected") is not False:
        raise GateError("overflow RenderFlex evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("overflow nonzero execute exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("overflow screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("overflow all-zero screenshot hash is not PASS")
    case_ids = report.get("case_ids")
    if not isinstance(case_ids, list) or case_ids != [CASE_ID]:
        raise GateError("overflow missing required case IDs")
    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("overflow missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("overflow missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("overflow missing installed versionName")
    if report.get("apk_matches_runner_head") is True:
        raise GateError("overflow must not claim the installed APK is this checkout")
    if report.get("installed_debuggable") is not True:
        raise GateError("overflow RenderFlex logs require a debuggable APK")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "overflow.json"
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
        raise GateError("overflow refuses the field phone")
    if serial != ALLOWED_SERIAL:
        raise GateError(
            f"overflow serial {serial} is not the disposable AOSP emulator"
        )
    completed = subprocess.run(
        [_adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("overflow could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "sdk_gphone" not in fingerprint:
        raise GateError(f"overflow fingerprint is not AOSP emulator: {fingerprint}")
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


def _font_scale(serial: str) -> str:
    got = _run(serial, "shell", "settings", "get", "system", "font_scale")
    return (got.stdout or "").strip() or "1.0"


def _set_font_scale(serial: str, value: str) -> None:
    put = _run(serial, "shell", "settings", "put", "system", "font_scale", value)
    if put.returncode != 0:
        raise GateError(f"overflow could not set font_scale {value}")


def _wait_for_activity(serial: str, timeout_s: float = 20.0) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        dumped = _run(serial, "shell", "dumpsys", "activity", "activities")
        out = dumped.stdout or ""
        for line in out.splitlines():
            if "topResumedActivity" not in line and "mFocusedApp=" not in line:
                continue
            if PACKAGE in line and "MainActivity" in line:
                return
        time.sleep(0.5)
    raise GateError("overflow MainActivity did not resume")


def _relaunch(serial: str) -> None:
    _run(serial, "shell", "am", "force-stop", "com.android.intentresolver")
    _run(serial, "shell", "am", "force-stop", PACKAGE)
    time.sleep(1.0)
    started = _run(
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
        raise GateError(
            f"overflow could not start MainActivity: {started.stdout}{started.stderr}"
        )
    _wait_for_activity(serial)


def _ui_xml(serial: str) -> str:
    completed = subprocess.run(
        [_adb(), "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=False,
        capture_output=True,
    )
    return (completed.stdout or b"").decode("utf-8", "replace")


def _wait_for_connect(serial: str, timeout_s: float = 45.0) -> str:
    deadline = time.time() + timeout_s
    last = ""
    while time.time() < deadline:
        last = _ui_xml(serial)
        if PACKAGE in last and any(marker in last for marker in CONNECT_MARKERS):
            return last
        time.sleep(1.0)
    raise GateError("overflow connect screen did not appear")


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
        raise GateError("overflow could not capture the large-text screenshot")
    payload = dest.read_bytes()
    assert_png_has_visible_content(payload)
    return hashlib.sha256(payload).hexdigest()


def overflow_lines_from_logcat(
    log: subprocess.CompletedProcess[str],
) -> list[str]:
    if log.returncode != 0:
        raise GateError("overflow could not read logcat")
    return [
        line
        for line in (log.stdout or "").splitlines()
        if OVERFLOW_RE.search(line)
    ]


def _overflow_lines(serial: str) -> list[str]:
    return overflow_lines_from_logcat(_run(serial, "logcat", "-d"))


def package_is_debuggable(dumpsys_stdout: str) -> bool:
    for line in dumpsys_stdout.splitlines():
        stripped = line.strip()
        if "DEBUGGABLE" not in stripped:
            continue
        if "flags=[" in stripped or "pkgFlags=[" in stripped:
            return True
    return False


def _installed_version_name(serial: str) -> str:
    dumped = _run(serial, "shell", "dumpsys", "package", PACKAGE)
    for line in (dumped.stdout or "").splitlines():
        line = line.strip()
        if line.startswith("versionName="):
            return line.split("=", 1)[1].strip()
    raise GateError("overflow could not read installed versionName")


def _git_head() -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("overflow could not read HEAD")
    return completed.stdout.strip()


def _execute(serial: str, output: Path) -> dict:
    listed = _run(serial, "shell", "pm", "list", "packages", PACKAGE)
    if not _package_listed(listed.stdout or "", PACKAGE):
        raise GateError("overflow rig package is not installed")
    dumpsys = _run(serial, "shell", "dumpsys", "package", PACKAGE)
    if not package_is_debuggable(dumpsys.stdout or ""):
        raise GateError("overflow RenderFlex logs require a debuggable APK")
    previous = _font_scale(serial)
    command = [
        _adb(),
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
        _run(serial, "logcat", "-c")
        _relaunch(serial)
        _wait_for_connect(serial)
        hits = _overflow_lines(serial)
        if hits:
            raise GateError(
                "overflow RenderFlex on the large-text connect screen: "
                + hits[0][:300]
            )
        digest = _screencap(serial, output / "overflow-large-text.png")
    finally:
        _set_font_scale(serial, previous if previous else "1.0")
    return {
        "lane": "overflow",
        "device": serial,
        "package": PACKAGE,
        "command": command,
        "exit": 0,
        "font_scale": FONT_SCALE,
        "connect_shown": True,
        "overflow_detected": False,
        "case_ids": [CASE_ID],
        "screenshot_sha256": digest,
        "runner_head_sha": _git_head(),
        "installed_version_name": _installed_version_name(serial),
        "apk_matches_runner_head": False,
        "installed_debuggable": True,
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
            "overflow lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "overflow --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = _identify(serial)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_overflow_report(report)
    except GateError as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"overflow execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "overflow.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
