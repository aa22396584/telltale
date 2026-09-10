#!/usr/bin/env python3
"""#47 leftover: l10n_rig runner lanes are fail-closed and mutually exclusive.

Do not invoke Flutter, change the phone language, open an OS chooser, or
invent a device id.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from run import main  # noqa: E402


class L10nRigRunnerTest(unittest.TestCase):
    def test_native_dialog_flag_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(["--native-dialog", "--output", str(output)]),
                2,
            )
            self.assertFalse((output / "native-dialog.json").exists())
            self.assertFalse((output / "android-os-locale.json").exists())

    def test_android_os_locale_flag_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(["--android-os-locale", "--output", str(output)]),
                2,
            )
            self.assertFalse((output / "android-os-locale.json").exists())
            self.assertFalse((output / "native-dialog.json").exists())

    def test_combined_lane_flags_clean_each_requested_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            (output / "native-dialog.json").write_text(
                '{"lane":"native-dialog","device":"planted"}',
                encoding="utf-8",
            )
            (output / "android-os-locale.json").write_text(
                '{"lane":"android-os-locale","device":"planted"}',
                encoding="utf-8",
            )
            leftover = output / "unrelated.json"
            leftover.write_text("{}", encoding="utf-8")
            self.assertEqual(
                main(
                    [
                        "--native-dialog",
                        "--android-os-locale",
                        "--output",
                        str(output),
                    ]
                ),
                2,
            )
            self.assertFalse((output / "native-dialog.json").exists())
            self.assertFalse((output / "android-os-locale.json").exists())
            self.assertTrue(
                leftover.exists(),
                msg="a lane that was not requested must not be swept as a side effect",
            )

    def test_combined_lane_flags_delete_dangling_symlinks(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            native = output / "native-dialog.json"
            locale = output / "android-os-locale.json"
            native.symlink_to(output / "missing-native.json")
            locale.symlink_to(output / "missing-locale.json")
            self.assertEqual(
                main(
                    [
                        "--native-dialog",
                        "--android-os-locale",
                        "--output",
                        str(output),
                    ]
                ),
                2,
            )
            self.assertFalse(native.exists())
            self.assertFalse(native.is_symlink())
            self.assertFalse(locale.exists())
            self.assertFalse(locale.is_symlink())

    def test_runner_names_the_lanes(self):
        text = (ROOT / "tool" / "l10n_rig" / "run.py").read_text(encoding="utf-8")
        self.assertIn("--native-dialog", text)
        self.assertIn("--android-os-locale", text)
        self.assertIn("mutually exclusive", text)


if __name__ == "__main__":
    unittest.main()
