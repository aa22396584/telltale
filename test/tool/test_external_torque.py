#!/usr/bin/env python3
"""#79 leftover: external Torque qualification is fail-closed not-run.

Do not invoke Flutter, Torque Pro, or invent a version/method.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "pid_compat"))

from external_torque import GateError, main, validate_external_torque_report  # noqa: E402


def _software(**overrides):
    report = {
        "lane": "software",
        "engine": "FormulaEngine",
        "observations": 20,
        "torque_version": "",
    }
    report.update(overrides)
    return report


class ExternalTorqueLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_external_torque(self):
        with self.assertRaises(GateError):
            validate_external_torque_report(_software())

    def test_external_torque_without_a_named_version_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_external_torque_report(
                {"lane": "external-torque", "torque_version": ""}
            )

    def test_external_torque_with_a_named_version_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_external_torque_report(
                {
                    "lane": "external-torque",
                    "torque_version": "Torque Pro 1.12.123",
                    "method": "planted",
                }
            )
        self.assertIn("not-run", str(raised.exception))

    def test_external_torque_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "external-torque.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_external_torque_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "external-torque.json"
            stale.write_text(
                '{"lane":"external-torque","torque_version":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_external_torque_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "external-torque.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())


if __name__ == "__main__":
    unittest.main()
