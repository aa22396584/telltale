#!/usr/bin/env python3
"""#47 leftover: Wear OS lane is fail-closed not-run.

Do not invoke Flutter, open a Wear emulator, invent a device id, or walk
a watch. Host-entry wear_shell tests do not substitute for this lane.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from wear import GateError, main, validate_wear_report  # noqa: E402


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "host-entry",
        "observations": 20,
        "device": "",
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

    def test_wear_with_a_device_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_wear_report({"lane": "wear", "device": "wear-emulator-api35"})
        self.assertIn("not-run", str(raised.exception))

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
