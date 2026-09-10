#!/usr/bin/env python3
"""#47 leftover: screenshot lane is fail-closed not-run.

Do not invoke Flutter, capture a screen, invent a device id, or walk a phone.
Host-entry screenshot journey tests do not substitute for this lane.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

import binascii
import struct
import zlib

from screenshot import (  # noqa: E402
    CASE_ID,
    GateError,
    assert_png_has_visible_content,
    main,
    validate_screenshot_report,
)


def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = binascii.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def _png(width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> bytes:
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    raw = b""
    index = 0
    for _ in range(height):
        raw += b"\x00"
        for _ in range(width):
            raw += bytes(pixels[index])
            index += 1
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(raw, 9))
        + _chunk(b"IEND", b"")
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


class ScreenshotLaneTest(unittest.TestCase):
    def test_a_software_report_is_not_a_screenshot_lane(self):
        with self.assertRaises(GateError):
            validate_screenshot_report(_software())

    def test_screenshot_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_screenshot_report({"lane": "screenshot", "device": ""})

    def test_screenshot_refuses_the_field_phone(self):
        with self.assertRaises(GateError) as raised:
            validate_screenshot_report(
                {"lane": "screenshot", "device": "R5CX10VFFBA"}
            )
        self.assertIn("field phone", str(raised.exception))

    def test_executed_connect_screenshot_passes(self):
        report = {
            "lane": "screenshot",
            "device": "emulator-5554",
            "fingerprint": "google/sdk_gphone64_arm64/emu64a",
            "command": ["adb", "exec-out", "screencap", "-p"],
            "exit": 0,
            "connect_shown": True,
            "case_ids": [CASE_ID],
            "screenshot_sha256": "a" * 64,
            "runner_head_sha": "b" * 40,
            "installed_version_name": "1.0.12-rig",
            "apk_matches_runner_head": False,
        }
        self.assertEqual(validate_screenshot_report(report)["device"], "emulator-5554")

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
            self.assertFalse((output / "screenshot.json").exists())

    def test_screenshot_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse((output / "screenshot.json").exists())
            self.assertFalse((output / "overflow.json").exists())
            self.assertFalse((output / "native-dialog.json").exists())

    def test_screenshot_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "screenshot.json"
            stale.write_text(
                '{"lane":"screenshot","device":"planted"}',
                encoding="utf-8",
            )
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_screenshot_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "screenshot.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertTrue(stale.is_symlink())
            self.assertFalse(stale.exists())
            self.assertEqual(main(["--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())

    def test_uniform_transparent_black_png_is_not_pass(self):
        blank = _png(2, 2, [(0, 0, 0, 0)] * 4)
        with self.assertRaises(GateError) as raised:
            assert_png_has_visible_content(blank)
        self.assertIn("blank", str(raised.exception).lower())

    def test_varied_connect_png_is_accepted(self):
        varied = _png(
            2,
            2,
            [(10, 20, 30, 255), (40, 50, 60, 255), (70, 80, 90, 255), (1, 2, 3, 255)],
        )
        assert_png_has_visible_content(varied)


if __name__ == "__main__":
    unittest.main()
