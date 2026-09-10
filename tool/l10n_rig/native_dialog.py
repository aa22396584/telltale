#!/usr/bin/env python3
"""#47 native OS-dialog lane.

Without `--execute` this is fail-closed not-run: planted native-dialog.json
is deleted and the process exits 2. A device id in a report is not PASS.

With `--execute --serial emulator-5554` on the identified disposable AOSP
emulator this runs the rig instrumentation test that opens the OS share
chooser and writes an evidence report. The field phone is refused.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FIELD_SERIAL = "R5CX10VFFBA"
ALLOWED_SERIAL = "emulator-5554"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PACKAGE = "com.cbstudio.telltale.rig"
CASE_ID = "productionShareIntentOpensOsChooser"


class GateError(Exception):
    """Evidence is not an honest native-dialog pass."""


def validate_native_dialog_report(report: object) -> dict:
    if not isinstance(report, dict):
        raise GateError("native-dialog report is not an object")
    if report.get("lane") != "native-dialog":
        raise GateError("a software report is not a native-dialog lane")
    device = report.get("device")
    if not isinstance(device, str) or not device.strip():
        raise GateError("native-dialog without an identified device is not PASS")
    if device == FIELD_SERIAL:
        raise GateError("native-dialog refuses the field phone")
    fingerprint = report.get("fingerprint")
    if not isinstance(fingerprint, str) or "sdk_gphone" not in fingerprint:
        raise GateError("native-dialog without an AOSP emulator fingerprint is not PASS")
    if report.get("chooser_shown") is not True:
        raise GateError("native-dialog without chooser evidence is not PASS")
    if report.get("exit") != 0:
        raise GateError("native-dialog nonzero instrumentation exit is not PASS")
    digest = report.get("screenshot_sha256")
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
        raise GateError("native-dialog screenshot sha256 must be 64 hex")
    if digest == "0" * 64:
        raise GateError("native-dialog all-zero screenshot hash is not PASS")
    case_ids = report.get("case_ids")
    if (
        not isinstance(case_ids, list)
        or not case_ids
        or not all(isinstance(item, str) and item.strip() for item in case_ids)
    ):
        raise GateError("native-dialog missing case IDs")
    command = report.get("command")
    if not isinstance(command, list) or not command:
        raise GateError("native-dialog missing executed command")
    return report


def _unlink_stale(output: Path) -> None:
    stale = output / "native-dialog.json"
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
        raise GateError("native-dialog refuses the field phone")
    if serial != ALLOWED_SERIAL:
        raise GateError(
            f"native-dialog serial {serial} is not the disposable AOSP emulator"
        )
    completed = subprocess.run(
        [_adb(), "-s", serial, "shell", "getprop", "ro.build.fingerprint"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("native-dialog could not read the emulator fingerprint")
    fingerprint = completed.stdout.strip()
    if "sdk_gphone" not in fingerprint:
        raise GateError(
            f"native-dialog fingerprint is not AOSP emulator: {fingerprint}"
        )
    return fingerprint


def _ensure_gradlew() -> Path:
    wrapper = ROOT / "android" / "gradlew"
    if wrapper.is_file():
        return wrapper
    flutter = Path.home() / "fvm" / "versions" / "3.47.0" / "bin" / "flutter"
    built = subprocess.run(
        [str(flutter), "build", "apk", "--debug", "--flavor", "rig"],
        cwd=ROOT,
        check=False,
    )
    if built.returncode != 0 or not wrapper.is_file():
        raise GateError("native-dialog could not materialise android/gradlew")
    return wrapper


def _gradle_env() -> dict[str, str]:
    env = os.environ.copy()
    android_home = Path.home() / "Library" / "Android" / "sdk"
    env.setdefault("ANDROID_HOME", str(android_home))
    env.setdefault("ANDROID_SDK_ROOT", str(android_home))
    # Host default `/usr/libexec/java_home` is currently 21; AGP 9 / this
    # module compile against 17. Prefer an already-installed Corretto 17
    # without requiring callers to export JAVA_HOME.
    if not env.get("JAVA_HOME"):
        corretto = (
            Path.home()
            / "Library"
            / "Java"
            / "JavaVirtualMachines"
            / "corretto-17.0.15"
            / "Contents"
            / "Home"
        )
        if corretto.is_dir():
            env["JAVA_HOME"] = str(corretto)
    return env


def _run_instrumentation(serial: str) -> tuple[list[str], int, str]:
    wrapper = _ensure_gradlew()
    env = _gradle_env()
    adb = _adb()
    listed = subprocess.run(
        [adb, "-s", serial, "shell", "pm", "list", "packages", PACKAGE],
        check=False,
        capture_output=True,
        text=True,
    )
    app_present = f"package:{PACKAGE}" in (listed.stdout or "")
    assemble = [str(wrapper), ":app:assembleRigDebugAndroidTest"]
    if not app_present:
        assemble.insert(1, ":app:assembleRigDebug")
    built = subprocess.run(
        assemble,
        cwd=ROOT / "android",
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )
    if built.returncode != 0:
        log = (built.stdout or "") + (built.stderr or "")
        return assemble, built.returncode, log
    app_apk = ROOT / "build" / "app" / "outputs" / "apk" / "rig" / "debug" / "app-rig-debug.apk"
    test_apk = (
        ROOT
        / "build"
        / "app"
        / "outputs"
        / "apk"
        / "androidTest"
        / "rig"
        / "debug"
        / "app-rig-debug-androidTest.apk"
    )
    if not test_apk.is_file() or (not app_present and not app_apk.is_file()):
        raise GateError("native-dialog missing rig debug or androidTest APK")
    apks = [test_apk]
    if not app_present:
        apks.insert(0, app_apk)
    for apk in apks:
        installed = subprocess.run(
            [adb, "-s", serial, "install", "-r", "-t", "-g", str(apk)],
            check=False,
            capture_output=True,
            text=True,
        )
        if installed.returncode != 0:
            log = (installed.stdout or "") + (installed.stderr or "")
            return [adb, "install", str(apk)], installed.returncode, log
    command = [
        adb,
        "-s",
        serial,
        "shell",
        "am",
        "instrument",
        "-w",
        "-e",
        "class",
        "com.cbstudio.telltale.ShareChooserInstrumentedTest",
        f"{PACKAGE}.test/androidx.test.runner.AndroidJUnitRunner",
    ]
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    log = (completed.stdout or "") + (completed.stderr or "")
    return command, completed.returncode, log


def _chooser_is_focused(serial: str) -> bool:
    dumped = subprocess.run(
        [_adb(), "-s", serial, "shell", "dumpsys", "activity", "activities"],
        check=False,
        capture_output=True,
        text=True,
    )
    if dumped.returncode != 0:
        return False
    for line in (dumped.stdout or "").splitlines():
        if "topResumedActivity" not in line and "mFocusedApp=" not in line:
            continue
        if (
            "ChooserActivity" in line
            or "ResolverActivity" in line
            or "intentresolver" in line
        ):
            return True
    return False


def _pull_screenshot(serial: str, dest: Path) -> str:
    if not _chooser_is_focused(serial):
        raise GateError("native-dialog chooser was not focused at screenshot time")
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as handle:
        captured = subprocess.run(
            [_adb(), "-s", serial, "exec-out", "screencap", "-p"],
            check=False,
            stdout=handle,
        )
    subprocess.run(
        [_adb(), "-s", serial, "shell", "input", "keyevent", "KEYCODE_BACK"],
        check=False,
        capture_output=True,
        text=True,
    )
    if captured.returncode != 0 or not dest.is_file() or dest.stat().st_size == 0:
        raise GateError("native-dialog could not capture the chooser screenshot")
    return hashlib.sha256(dest.read_bytes()).hexdigest()


def _git_head() -> str:
    completed = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise GateError("native-dialog could not read HEAD")
    return completed.stdout.strip()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--serial")
    args = parser.parse_args(argv)
    if not args.execute:
        return _not_run(
            args.output,
            "native-dialog lane is not-run without an identified device",
        )
    serial = (args.serial or os.environ.get("ANDROID_SERIAL") or "").strip()
    if not serial:
        return _not_run(
            args.output,
            "native-dialog --execute requires --serial emulator-5554",
        )
    try:
        fingerprint = _identify(serial)
        command, exit_code, log = _run_instrumentation(serial)
        if exit_code != 0:
            print(log[-4000:], file=sys.stderr)
            raise GateError(
                f"native-dialog instrumentation exited {exit_code}"
            )
        # `am instrument -w` returns 0 on JUnit failures. CASE_ID is also in
        # the failure log, so only a literal OK banner is evidence.
        if "FAILURES!!!" in log or f"Error in {CASE_ID}" in log:
            print(log[-4000:], file=sys.stderr)
            raise GateError("native-dialog instrumentation reported a failure")
        if "OK (1 test)" not in log:
            print(log[-4000:], file=sys.stderr)
            raise GateError("native-dialog instrumentation did not finish clean")
        screenshot = args.output / "native-share-chooser.png"
        digest = _pull_screenshot(serial, screenshot)
        report = {
            "lane": "native-dialog",
            "device": serial,
            "fingerprint": fingerprint,
            "package": PACKAGE,
            "command": command,
            "exit": 0,
            "chooser_shown": True,
            "case_ids": [CASE_ID],
            "screenshot_sha256": digest,
            "head_sha": _git_head(),
        }
        validate_native_dialog_report(report)
    except GateError as exc:
        return _not_run(args.output, str(exc))
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "native-dialog.json").write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
