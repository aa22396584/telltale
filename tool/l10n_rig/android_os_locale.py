#!/usr/bin/env python3
"""#47 Android OS-locale / process-restart lane.

Without `--execute` this is fail-closed not-run: planted
android-os-locale.json is deleted and the process exits 2.

With `--execute --serial emulator-5554` on the identified disposable AOSP
emulator this sets the rig package's per-app locales, relaunches
MainActivity, and checks connect-screen copy. The field phone is refused.
Force-stop is a process recreation; this leftover does not claim an
uninterrupted recording.
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


ROOT = Path(__file__).resolve().parents[2]
FIELD_SERIAL = "R5CX10VFFBA"
ALLOWED_SERIAL = "emulator-5554"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PACKAGE = "com.cbstudio.telltale.rig"
ACTIVITY = f"{PACKAGE}/com.cbstudio.telltale.MainActivity"
ENGLISH_MARKER = "built-in simulator"
CHINESE_MARKER = "內建模擬器"
CASE_IDS = [
    "osLocaleEnglishConnectCopy",
    "osLocaleTraditionalChineseConnectCopy",
]


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
    if device == FIELD_SERIAL:
        raise GateError("android-os-locale refuses the field phone")
    if device != ALLOWED_SERIAL:
        raise GateError(
            "android-os-locale serial "
            f"{device} is not the disposable AOSP emulator"
        )
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError(
            "android-os-locale without an AOSP emulator fingerprint is not PASS"
        )
    if report.get("english_seen") is not True:
        raise GateError("android-os-locale without English connect copy is not PASS")
    if report.get("chinese_seen") is not True:
        raise GateError(
            "android-os-locale without Traditional Chinese connect copy is not PASS"
        )
    if report.get("process_recreated") is not True:
        raise GateError(
            "android-os-locale without a documented process recreation is not PASS"
        )
    if report.get("exit") != 0:
        raise GateError("android-os-locale nonzero execute exit is not PASS")
    shots = report.get("screenshots")
    if not isinstance(shots, dict) or set(shots) != {"en-US", "zh-Hant-TW"}:
        raise GateError("android-os-locale screenshots must cover en-US and zh-Hant-TW")
    for tag, digest in shots.items():
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
            raise GateError(f"android-os-locale {tag} screenshot sha256 must be 64 hex")
        if digest == "0" * 64:
            raise GateError("android-os-locale all-zero screenshot hash is not PASS")
    case_ids = report.get("case_ids")
    if (
        not isinstance(case_ids, list)
        or case_ids != CASE_IDS
    ):
        raise GateError("android-os-locale missing required case IDs")
    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("android-os-locale missing executed command")
    runner = report.get("runner_head_sha")
    if not isinstance(runner, str) or len(runner) != 40:
        raise GateError("android-os-locale missing runner HEAD")
    version = report.get("installed_version_name")
    if not isinstance(version, str) or not version.strip():
        raise GateError("android-os-locale missing installed versionName")
    if report.get("localeconfig_via_shell") is not True:
        raise GateError(
            "android-os-locale must record that LocaleConfig was applied via shell"
        )
    if report.get("apk_matches_runner_head") is True:
        raise GateError(
            "android-os-locale must not claim the installed APK is this checkout"
        )
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "android-os-locale.json"
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
        raise GateError("android-os-locale refuses the field phone")
    if serial != ALLOWED_SERIAL:
        raise GateError(
            f"android-os-locale serial {serial} is not the disposable AOSP emulator"
        )
    completed = subprocess.run(
        [_adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("android-os-locale could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "sdk_gphone" not in fingerprint:
        raise GateError(
            f"android-os-locale fingerprint is not AOSP emulator: {fingerprint}"
        )
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


def _dismiss_leftovers(serial: str) -> None:
    _run(serial, "shell", "am", "force-stop", "com.android.intentresolver")
    _run(serial, "shell", "input", "keyevent", "KEYCODE_HOME")


def _set_app_locales(serial: str, locales: str) -> None:
    config = _run(
        serial,
        "shell",
        "cmd",
        "locale",
        "set-app-localeconfig",
        PACKAGE,
        "--locales",
        "en,zh-Hant,de",
    )
    if config.returncode != 0:
        raise GateError("android-os-locale could not set LocaleConfig")
    args = [
        "shell",
        "cmd",
        "locale",
        "set-app-locales",
        PACKAGE,
        "--locales",
        locales,
    ]
    set_locales = _run(serial, *args)
    if set_locales.returncode != 0:
        raise GateError(f"android-os-locale could not set app locales {locales}")
    listed = _run(serial, "shell", "cmd", "locale", "get-app-locales", PACKAGE)
    if locales not in (listed.stdout or ""):
        raise GateError(
            f"android-os-locale get-app-locales did not contain {locales}: "
            f"{listed.stdout!r}"
        )


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
    raise GateError("android-os-locale MainActivity did not resume")


def _relaunch(serial: str) -> None:
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
            "android-os-locale could not start MainActivity: "
            f"{started.stdout}{started.stderr}"
        )
    _wait_for_activity(serial)


def _ui_xml(serial: str) -> str:
    completed = subprocess.run(
        [_adb(), "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=False,
        capture_output=True,
    )
    return (completed.stdout or b"").decode("utf-8", "replace")


def _wait_for_marker(serial: str, marker: str, timeout_s: float = 45.0) -> str:
    deadline = time.time() + timeout_s
    last = ""
    while time.time() < deadline:
        last = _ui_xml(serial)
        if marker in last and PACKAGE in last:
            return last
        time.sleep(1.0)
    raise GateError(
        f"android-os-locale UI did not contain {marker!r} within {timeout_s:.0f}s"
    )


def _screencap(serial: str, dest: Path) -> str:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as handle:
        captured = subprocess.run(
            [_adb(), "-s", serial, "exec-out", "screencap", "-p"],
            check=False,
            stdout=handle,
        )
    if captured.returncode != 0 or not dest.is_file() or dest.stat().st_size == 0:
        raise GateError(f"android-os-locale could not capture {dest.name}")
    return hashlib.sha256(dest.read_bytes()).hexdigest()


def _clear_app_locales(serial: str) -> None:
    _run(serial, "shell", "cmd", "locale", "set-app-locales", PACKAGE)
    _run(serial, "shell", "am", "force-stop", PACKAGE)
    _run(serial, "shell", "input", "keyevent", "KEYCODE_HOME")


def _installed_version_name(serial: str) -> str:
    dumped = _run(serial, "shell", "dumpsys", "package", PACKAGE)
    for line in (dumped.stdout or "").splitlines():
        line = line.strip()
        if line.startswith("versionName="):
            return line.split("=", 1)[1].strip()
    raise GateError("android-os-locale could not read installed versionName")


def _git_head() -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("android-os-locale could not read HEAD")
    return completed.stdout.strip()


def _execute(serial: str, output: Path) -> dict:
    listed = _run(serial, "shell", "pm", "list", "packages", PACKAGE)
    if not _package_listed(listed.stdout or "", PACKAGE):
        raise GateError("android-os-locale rig package is not installed")
    _dismiss_leftovers(serial)
    command = [
        _adb(),
        "-s",
        serial,
        "shell",
        "cmd",
        "locale",
        "set-app-locales",
        PACKAGE,
        "--locales",
        "en-US",
    ]
    _set_app_locales(serial, "en-US")
    _relaunch(serial)
    _wait_for_marker(serial, ENGLISH_MARKER)
    en_digest = _screencap(serial, output / "os-locale-en.png")
    _set_app_locales(serial, "zh-Hant-TW")
    _relaunch(serial)
    _wait_for_marker(serial, CHINESE_MARKER)
    zh_digest = _screencap(serial, output / "os-locale-zh-Hant.png")
    _clear_app_locales(serial)
    return {
        "lane": "android-os-locale",
        "device": serial,
        "package": PACKAGE,
        "command": command,
        "exit": 0,
        "english_seen": True,
        "chinese_seen": True,
        "process_recreated": True,
        "case_ids": list(CASE_IDS),
        "screenshots": {
            "en-US": en_digest,
            "zh-Hant-TW": zh_digest,
        },
        "runner_head_sha": _git_head(),
        "installed_version_name": _installed_version_name(serial),
        "localeconfig_via_shell": True,
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
            "android-os-locale lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    args.output.mkdir(parents=True, exist_ok=True)
    _unlink_stale(args.output)
    if not serial:
        return _not_run(
            args.output,
            "android-os-locale --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = _identify(serial)
        report = _execute(serial, args.output)
        report["fingerprint"] = fingerprint
        validate_android_os_locale_report(report)
    except GateError as exc:
        return _not_run(args.output, str(exc))
    except Exception as exc:
        return _not_run(
            args.output,
            f"android-os-locale execute failed: {type(exc).__name__}: {exc}",
        )
    (args.output / "android-os-locale.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
