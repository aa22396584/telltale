#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path

import count_dart_tests


ROOT = Path(__file__).resolve().parents[2]


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


if __name__ == "__main__":
    unittest.main()
