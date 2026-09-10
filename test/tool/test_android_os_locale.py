#!/usr/bin/env python3
"""#47 leftover: Android OS-locale lane is fail-closed not-run by default.

Do not invoke Flutter, change the phone language, or invent a device id
unless --execute --serial emulator-5554 is under test as a refused serial.
"""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from android_os_locale import (  # noqa: E402
    CASE_IDS,
    GateError,
    main,
    validate_android_os_locale_report,
)


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "host-entry",
        "observations": 20,
        "device": "",
    }
    report.update(overrides)
    return report


def _pass(**overrides):
    report = {
        "lane": "android-os-locale",
        "device": "emulator-5554",
        "fingerprint": "google/sdk_gphone64_arm64/emu64a:16/BE2A.250530.026.D1/13818094:user/release-keys",
        "package": "com.cbstudio.telltale.rig",
        "command": ["adb", "-s", "emulator-5554", "shell", "cmd", "locale"],
        "exit": 0,
        "english_seen": True,
        "chinese_seen": True,
        "process_recreated": True,
        "case_ids": list(CASE_IDS),
        "screenshots": {"en-US": "a" * 64, "zh-Hant-TW": "b" * 64},
        "runner_head_sha": "c" * 40,
        "installed_version_name": "1.0.12-rig",
        "localeconfig_via_shell": True,
        "apk_matches_runner_head": False,
    }
    report.update(overrides)
    return report


class AndroidOsLocaleLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_an_android_os_locale(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(_software())

    def test_android_os_locale_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(
                {"lane": "android-os-locale", "device": ""}
            )

    def test_android_os_locale_refuses_the_field_phone(self):
        with self.assertRaises(GateError) as raised:
            validate_android_os_locale_report(
                {"lane": "android-os-locale", "device": "R5CX10VFFBA"}
            )
        self.assertIn("field phone", str(raised.exception))

    def test_quietinbox_report_is_not_pass(self):
        with self.assertRaises(GateError) as raised:
            validate_android_os_locale_report(_pass(device="emulator-5556"))
        self.assertIn("emulator-5556", str(raised.exception))

    def test_executed_en_and_zh_report_passes(self):
        self.assertEqual(
            validate_android_os_locale_report(_pass())["device"],
            "emulator-5554",
        )

    def test_missing_chinese_copy_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(_pass(chinese_seen=False))

    def test_claiming_the_apk_is_this_checkout_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(_pass(apk_matches_runner_head=True))

    def test_android_os_locale_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "android-os-locale.json").exists())
            self.assertFalse((output / "software.json").exists())
            self.assertFalse((output / "native-dialog.json").exists())

    def test_android_os_locale_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "android-os-locale.json"
            stale.write_text(
                '{"lane":"android-os-locale","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_android_os_locale_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "android-os-locale.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())

    def test_execute_without_serial_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output), "--execute"]), 2)
            self.assertFalse((output / "android-os-locale.json").exists())

    def test_execute_field_phone_is_refused(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(
                    [
                        "--output",
                        str(output),
                        "--execute",
                        "--serial",
                        "R5CX10VFFBA",
                    ]
                ),
                2,
            )
            self.assertFalse((output / "android-os-locale.json").exists())

    def test_execute_quietinbox_emulator_is_refused(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(
                    [
                        "--output",
                        str(output),
                        "--execute",
                        "--serial",
                        "emulator-5556",
                    ]
                ),
                2,
            )
            self.assertFalse((output / "android-os-locale.json").exists())

    def test_missing_adb_unlinks_a_stale_pass_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "android-os-locale.json"
            stale.write_text(
                '{"lane":"android-os-locale","device":"planted"}',
                encoding="utf-8",
            )
            previous = os.environ.get("ADB")
            os.environ["ADB"] = str(output / "missing-adb")
            try:
                self.assertEqual(
                    main(
                        [
                            "--output",
                            str(output),
                            "--execute",
                            "--serial",
                            "emulator-5554",
                        ]
                    ),
                    2,
                )
            finally:
                if previous is None:
                    os.environ.pop("ADB", None)
                else:
                    os.environ["ADB"] = previous
            self.assertFalse(stale.exists())

    def test_locales_config_lists_dart_resolved_system_languages(self):
        xml = (
            ROOT / "android" / "app" / "src" / "main" / "res" / "xml" / "locales_config.xml"
        ).read_text(encoding="utf-8")
        self.assertIn('android:name="en"', xml)
        self.assertIn('android:name="zh-Hant"', xml)
        self.assertIn('android:name="de"', xml)
        self.assertNotIn("zh-Hans", xml)
        self.assertNotIn("zh-CN", xml)
        manifest = (
            ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
        ).read_text(encoding="utf-8")
        self.assertIn('android:localeConfig="@xml/locales_config"', manifest)
        ios = (ROOT / "ios" / "Runner" / "Info.plist").read_text(encoding="utf-8")
        self.assertIn("CFBundleLocalizations", ios)
        self.assertIn("zh-Hant", ios)
        macos = (ROOT / "macos" / "Runner" / "Info.plist").read_text(encoding="utf-8")
        self.assertIn("CFBundleLocalizations", macos)


if __name__ == "__main__":
    unittest.main()
