#!/usr/bin/env python3
"""Tests for the journey timeout reaper — shipped run_timeout.reap."""

from __future__ import annotations

import subprocess
import sys
import time
import unittest
from pathlib import Path

from run_timeout import reap, run_command


class RunTimeoutTest(unittest.TestCase):
    def test_timeout_is_not_run_and_returns_quickly(self) -> None:
        log = Path(self._tmp("log.txt"))
        start = time.monotonic()
        rc = run_command(
            [sys.executable, "-c", "import time; time.sleep(30)"],
            limit=0.4,
            log_path=log,
        )
        elapsed = time.monotonic() - start
        self.assertEqual(rc, 124)
        self.assertLess(elapsed, 8)

    def test_reap_communicate_is_bounded_if_killpg_misses(self) -> None:
        # Child exits immediately after spawning a new-session grandchild
        # that would otherwise make communicate() hang.
        proc = subprocess.Popen(
            [
                sys.executable,
                "-c",
                "import os, time, sys\n"
                "if os.fork() == 0:\n"
                "    os.setsid()\n"
                "    time.sleep(20)\n"
                "sys.exit(0)\n",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            start_new_session=True,
        )
        time.sleep(0.2)
        start = time.monotonic()
        reap(proc, grace=0.5)
        elapsed = time.monotonic() - start
        self.assertLess(elapsed, 4)

    def _tmp(self, name: str) -> str:
        import tempfile

        d = tempfile.mkdtemp(prefix="field-bt-timeout-")
        return str(Path(d) / name)


if __name__ == "__main__":
    unittest.main()
