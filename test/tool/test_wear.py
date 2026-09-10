#!/usr/bin/env python3
"""#47 leftover: Wear OS lane is fail-closed without an identified watch.

Do not invent a device id or walk a phone. Host-entry wear_shell tests
do not substitute for this lane. emulator-5554 and emulator-5556 are
phones and must not pass.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from wear import CASE_ID, GateError, main, validate_wear_report  # noqa: E402


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "host-entry",
        "observations": 20,
        "device": "",
    }
    report.update(overrides)
    return report


def _executed(**overrides):
    report = {
        "lane": "wear",
        "device": "emulator-5558",
        "fingerprint": "google/sdk_gwear64_arm64/emu64a",
        "command": ["adb", "-s", "emulator-5558", "exec-out", "screencap", "-p"],
        "exit": 0,
        "connect_shown": True,
        "case_ids": [CASE_ID],
        "screenshot_sha256": "a" * 64,
        "runner_head_sha": "b" * 40,
        "installed_version_name": "1.0.12-rig",
        "apk_matches_runner_head": False,
    }
    report.update(overrides)
    return report


class WearLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_a_wear_lane(self):
        with self.assertRaises(GateError):
            validate_wear_report(_software())

    def test_wear_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_wear_report({"lane": "wear", "device": ""})

    def test_wear_refuses_the_field_phone(self):
        with self.assertRaises(GateError) as raised:
            validate_wear_report({"lane": "wear", "device": "R5CX10VFFBA"})
        self.assertIn("field phone", str(raised.exception))

    def test_wear_refuses_the_phone_emulator(self):
        with self.assertRaises(GateError) as raised:
            validate_wear_report(_executed(device="emulator-5554"))
        self.assertIn("5554", str(raised.exception))

    def test_wear_refuses_quietinbox(self):
        with self.assertRaises(GateError) as raised:
            validate_wear_report(_executed(device="emulator-5556"))
        self.assertIn("5556", str(raised.exception))

    def test_phone_fingerprint_is_not_wear(self):
        with self.assertRaises(GateError) as raised:
            validate_wear_report(
                _executed(fingerprint="google/sdk_gphone64_arm64/emu64a")
            )
        self.assertIn("Wear", str(raised.exception))

    def test_executed_wear_report_passes(self):
        self.assertEqual(
            validate_wear_report(_executed())["device"],
            "emulator-5558",
        )

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
            self.assertFalse((output / "wear.json").exists())

    def test_execute_phone_emulator_is_refused(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
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
            self.assertFalse((output / "wear.json").exists())

    def test_execute_quietinbox_is_refused(self):
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
            self.assertFalse((output / "wear.json").exists())

    def test_wear_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "wear.json").exists())
            self.assertFalse((output / "overflow.json").exists())
            self.assertFalse((output / "screenshot.json").exists())

    def test_wear_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "wear.json"
            stale.write_text(
                '{"lane":"wear","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_wear_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "wear.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
