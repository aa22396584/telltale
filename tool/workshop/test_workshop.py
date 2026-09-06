#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import count_dart_tests


ROOT = Path(__file__).resolve().parents[2]


def load_skip_manifest():
    path = Path(__file__).with_name("assert_skip_manifest.py")
    spec = importlib.util.spec_from_file_location("assert_skip_manifest", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class CountDartTestsTest(unittest.TestCase):
    def test_discovered_counts_match_the_oracle_files(self) -> None:
        self.assertEqual(
            count_dart_tests.count_tests(ROOT / "test/emulator_integration_test.dart"),
            6,
        )
        self.assertEqual(
            count_dart_tests.count_tests(ROOT / "test/freeze_frame_oracle_test.dart"),
            7,
        )
        self.assertEqual(
            count_dart_tests.count_tests(ROOT / "test/chaos_oracle_test.dart"),
            1,
        )
        self.assertEqual(
            count_dart_tests.count_tests(ROOT / "test/chaos_poll_oracle_test.dart"),
            1,
        )


class SkipManifestUnittestOutputTest(unittest.TestCase):
    """CI failed because unittest's summary line contains the word skipped."""

    CATALOGUED_SKIP = (
        "test_controller_lock_serializes_distinct_private_tmp_roots "
        "(test_run_controller.RunControllerTest."
        "test_controller_lock_serializes_distinct_private_tmp_roots) "
        "... skipped 'the BLE rig controller is macOS-only'"
    )

    def _check(self, body: str) -> tuple[int, str]:
        module = load_skip_manifest()
        handle = tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            suffix=".txt",
            delete=False,
        )
        try:
            handle.write(body)
            handle.close()
            stderr = io.StringIO()
            with (
                patch.object(module.sys, "platform", "linux"),
                patch.object(module.sys, "stderr", stderr),
            ):
                code = module.main(
                    ["assert_skip_manifest.py", "--unittest-output", handle.name],
                )
            return code, stderr.getvalue()
        finally:
            Path(handle.name).unlink(missing_ok=True)

    def test_summary_ok_skipped_is_not_an_unlisted_skip(self) -> None:
        code, err = self._check(
            f"{self.CATALOGUED_SKIP}\n"
            "----------------------------------------------------------------------\n"
            "Ran 19 tests in 0.012s\n"
            "\n"
            "OK (skipped=19)\n"
        )
        self.assertEqual(err, "", msg=err)
        self.assertEqual(code, 0)

    def test_summary_failed_skipped_is_not_an_unlisted_skip(self) -> None:
        code, err = self._check(
            f"{self.CATALOGUED_SKIP}\n"
            "FAILED (failures=1, skipped=19)\n"
        )
        self.assertEqual(err, "", msg=err)
        self.assertEqual(code, 0)

    def test_unlisted_per_test_skip_still_fails(self) -> None:
        code, err = self._check(
            "test_invented (test_invented.Invented.test_invented) "
            "... skipped 'not in the manifest'\n"
            "OK (skipped=1)\n"
        )
        self.assertEqual(code, 1)
        self.assertIn("FAIL: unlisted skip:", err)
        self.assertIn("test_invented", err)
        self.assertNotIn("OK (skipped=1)", err)


if __name__ == "__main__":
    unittest.main()
