#!/usr/bin/env python3
"""#47 leftover: 320dp / narrow lane.

Default is fail-closed. --execute on emulator-5554 sets width to 320dp.
The field phone and emulator-5556 are refused.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from narrow import CASE_ID, GateError, main, validate_narrow_report  # noqa: E402


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
        "lane": "narrow",
        "device": "emulator-5554",
        "fingerprint": "google/sdk_gphone64_arm64/emu64a",
        "command": ["adb", "shell", "wm", "size", "320dpx891dp"],
        "exit": 0,
        "width_dp": 320,
        "connect_shown": True,
        "case_ids": [CASE_ID],
        "screenshot_sha256": "a" * 64,
        "runner_head_sha": "b" * 40,
        "installed_version_name": "1.0.12-rig",
        "apk_matches_runner_head": False,
    }
    report.update(overrides)
    return report


class NarrowLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_a_narrow_lane(self):
        with self.assertRaises(GateError):
            validate_narrow_report(_software())

    def test_narrow_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_narrow_report({"lane": "narrow", "device": ""})

    def test_narrow_refuses_the_field_phone(self):
        with self.assertRaises(GateError) as raised:
            validate_narrow_report({"lane": "narrow", "device": "R5CX10VFFBA"})
        self.assertIn("field phone", str(raised.exception))

    def test_executed_narrow_report_passes(self):
        self.assertEqual(
            validate_narrow_report(_executed())["device"],
            "emulator-5554",
        )

    def test_full_width_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_narrow_report(_executed(width_dp=411))

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
            self.assertFalse((output / "narrow.json").exists())

    def test_narrow_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "narrow.json").exists())
            self.assertFalse((output / "landscape.json").exists())
            self.assertFalse((output / "overflow.json").exists())

    def test_narrow_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "narrow.json"
            stale.write_text(
                '{"lane":"narrow","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_narrow_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "narrow.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
