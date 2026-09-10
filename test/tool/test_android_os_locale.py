#!/usr/bin/env python3
"""#47 leftover: Android OS-locale / process-restart lane is fail-closed not-run.

Do not invoke Flutter, change the phone language, restart a process, or
invent a device id.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from android_os_locale import (  # noqa: E402
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


class AndroidOsLocaleLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_an_android_os_locale(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(_software())

    def test_android_os_locale_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_android_os_locale_report(
                {"lane": "android-os-locale", "device": ""}
            )

    def test_android_os_locale_with_a_device_is_still_not_run(self):
        with self.assertRaises(GateError) as raised:
            validate_android_os_locale_report(
                {"lane": "android-os-locale", "device": "R5CX10VFFBA"}
            )
        self.assertIn("not-run", str(raised.exception))

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


if __name__ == "__main__":
    unittest.main()
