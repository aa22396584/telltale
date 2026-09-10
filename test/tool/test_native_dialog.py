#!/usr/bin/env python3
"""#47 leftover: native OS-dialog lane is fail-closed not-run.

Do not invoke Flutter, an OS share chooser, or invent a device id.
"""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from native_dialog import (  # noqa: E402
    GateError,
    PACKAGE,
    _package_listed,
    main,
    validate_native_dialog_report,
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


class NativeDialogLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_a_native_dialog(self):
        with self.assertRaises(GateError):
            validate_native_dialog_report(_software())

    def test_native_dialog_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_native_dialog_report({"lane": "native-dialog", "device": ""})

    def test_native_dialog_with_a_device_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_native_dialog_report(
                {"lane": "native-dialog", "device": "R5CX10VFFBA"}
            )
        self.assertIn("field phone", str(raised.exception))

    def test_native_dialog_device_without_chooser_is_not_pass(self):
        with self.assertRaises(GateError) as raised:
            validate_native_dialog_report(
                {
                    "lane": "native-dialog",
                    "device": "emulator-5554",
                    "fingerprint": "google/sdk_gphone64_arm64/emu64a",
                }
            )
        self.assertIn("chooser", str(raised.exception))

    def test_quietinbox_report_is_not_pass_even_with_aosp_fields(self):
        with self.assertRaises(GateError) as raised:
            validate_native_dialog_report(
                {
                    "lane": "native-dialog",
                    "device": "emulator-5556",
                    "fingerprint": "google/sdk_gphone64_arm64/emu64a:16/BE2A.250530.026.D1/13818094:user/release-keys",
                    "package": "com.cbstudio.telltale.rig",
                    "command": ["adb", "shell", "am", "instrument"],
                    "exit": 0,
                    "chooser_shown": True,
                    "case_ids": ["productionShareIntentOpensOsChooser"],
                    "screenshot_sha256": "a" * 64,
                    "head_sha": "b" * 40,
                }
            )
        self.assertIn("emulator-5556", str(raised.exception))

    def test_executed_aosp_chooser_report_passes(self):
        report = {
            "lane": "native-dialog",
            "device": "emulator-5554",
            "fingerprint": "google/sdk_gphone64_arm64/emu64a:16/BE2A.250530.026.D1/13818094:user/release-keys",
            "package": "com.cbstudio.telltale.rig",
            "command": ["./gradlew", ":app:connectedRigDebugAndroidTest"],
            "exit": 0,
            "chooser_shown": True,
            "case_ids": ["productionShareIntentOpensOsChooser"],
            "screenshot_sha256": "a" * 64,
            "head_sha": "b" * 40,
        }
        self.assertEqual(validate_native_dialog_report(report)["device"], "emulator-5554")

    def test_all_zero_screenshot_hash_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_native_dialog_report(
                {
                    "lane": "native-dialog",
                    "device": "emulator-5554",
                    "fingerprint": "google/sdk_gphone64_arm64/emu64a",
                    "command": ["./gradlew"],
                    "exit": 0,
                    "chooser_shown": True,
                    "case_ids": ["productionShareIntentOpensOsChooser"],
                    "screenshot_sha256": "0" * 64,
                }
            )

    def test_execute_without_serial_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(["--output", str(output), "--execute"]),
                2,
            )
            self.assertFalse((output / "native-dialog.json").exists())

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
            self.assertFalse((output / "native-dialog.json").exists())

    def test_missing_adb_unlinks_a_stale_pass_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "native-dialog.json"
            stale.write_text(
                '{"lane":"native-dialog","device":"planted"}',
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

    def test_test_package_listing_is_not_the_app(self):
        self.assertTrue(
            _package_listed("package:com.cbstudio.telltale.rig\n", PACKAGE)
        )
        self.assertFalse(
            _package_listed("package:com.cbstudio.telltale.rig.test\n", PACKAGE)
        )
        self.assertTrue(
            _package_listed(
                "package:com.cbstudio.telltale.rig.test\n"
                "package:com.cbstudio.telltale.rig\n",
                PACKAGE,
            )
        )

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
            self.assertFalse((output / "native-dialog.json").exists())

    def test_instrumentation_source_is_fail_closed_to_the_rig_package(self):
        source = (
            ROOT
            / "android"
            / "app"
            / "src"
            / "androidTest"
            / "kotlin"
            / "com"
            / "cbstudio"
            / "telltale"
            / "ShareChooserInstrumentedTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("com.cbstudio.telltale.rig", source)
        self.assertIn("sdk_gphone", source)
        self.assertIn("ACTION_SEND", source)
        self.assertIn("pid_value", source)
        self.assertIn("resolver_list", source)
        self.assertIn("ChooserActivity", source)
        self.assertIn("intentresolver", source)
        self.assertNotIn("Telltale human", source)
        self.assertNotIn("pressBack", source)
        self.assertNotIn("markTestSkipped", source)

    def test_runner_requires_ok_banner_not_just_a_case_id(self):
        source = (ROOT / "tool" / "l10n_rig" / "native_dialog.py").read_text(
            encoding="utf-8"
        )
        self.assertIn('OK (1 test)', source)
        self.assertIn("FAILURES!!!", source)
        self.assertIn("am instrument -w", source)
        self.assertIn("exec-out", source)
        self.assertIn("screencap", source)
        self.assertIn("chooser was not focused at screenshot time", source)

    def test_native_dialog_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "native-dialog.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_native_dialog_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "native-dialog.json"
            stale.write_text(
                '{"lane":"native-dialog","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_native_dialog_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "native-dialog.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
