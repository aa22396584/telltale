#!/usr/bin/env python3
"""#47 leftover: overflow / large-text lane is fail-closed not-run.

Do not invoke Flutter, resize a window, invent a device id, or walk a phone.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from overflow import GateError, main, validate_overflow_report  # noqa: E402


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "host-entry",
        "observations": 20,
        "device": "",
    }
    report.update(overrides)
    return report


class OverflowLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_an_overflow_lane(self):
        with self.assertRaises(GateError):
            validate_overflow_report(_software())

    def test_overflow_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_overflow_report({"lane": "overflow", "device": ""})

    def test_overflow_with_a_device_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_overflow_report({"lane": "overflow", "device": "R5CX10VFFBA"})
        self.assertIn("not-run", str(raised.exception))

    def test_overflow_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "overflow.json").exists())
            self.assertFalse((output / "native-dialog.json").exists())
            self.assertFalse((output / "android-os-locale.json").exists())

    def test_overflow_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "overflow.json"
            stale.write_text(
                '{"lane":"overflow","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_overflow_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "overflow.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
