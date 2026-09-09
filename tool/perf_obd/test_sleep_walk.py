#!/usr/bin/env python3
"""Gate tests for tool/perf_obd/sleep_walk.py. Do not invoke Flutter or a device."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from sleep_walk import GateError, main, validate_sleep_walk_report


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "PollingEngine",
        "observations": 20,
        "device": "",
    }
    report.update(overrides)
    return report


class SleepWalkLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_a_sleep_walk(self):
        with self.assertRaises(GateError):
            validate_sleep_walk_report(_software())

    def test_sleep_walk_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_sleep_walk_report({"lane": "sleep-walk", "device": ""})

    def test_sleep_walk_with_a_device_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_sleep_walk_report(
                {"lane": "sleep-walk", "device": "R5CX10VFFBA"}
            )
        self.assertIn("not-run", str(raised.exception))

    def test_sleep_walk_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "sleep-walk.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_sleep_walk_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "sleep-walk.json"
            stale.write_text(
                '{"lane":"sleep-walk","device":"planted"}', encoding="utf-8"
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_sleep_walk_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "sleep-walk.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
