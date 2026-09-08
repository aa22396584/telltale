#!/usr/bin/env python3
"""The Renderer JVM CI snippet must fail when a required suite skipped all cases.

Drives the Python extracted from `.github/workflows/ci.yml`, not a rewrite.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[2]
CI_PATH = REPO / ".github" / "workflows" / "ci.yml"
REQUIRED = (
    "com.cbstudio.telltale.RendererPolicyTest",
    "com.cbstudio.telltale.DevicePropertiesTest",
)


def extract_guard(workflow: str) -> str:
    marker = "Renderer policy unit tests (JVM)"
    start = workflow.index(marker)
    block = workflow[start:]
    begin = block.index("python3 - <<'EOF'")
    body = block[begin:].split("\n", 1)[1]
    end = body.index("\n          EOF")
    return textwrap.dedent(body[:end])


def write_xml(path: Path, name: str, *, tests: int, skipped: int, failures: int = 0) -> None:
    root = ET.Element(
        "testsuite",
        name=name,
        tests=str(tests),
        skipped=str(skipped),
        failures=str(failures),
        errors="0",
    )
    path.write_bytes(
        b'<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="utf-8")
    )


def write_sources(root: Path) -> None:
    src = root / "android/app/src/test/kotlin/com/cbstudio/telltale"
    src.mkdir(parents=True)
    (src / "RendererPolicyTest.kt").write_text(
        "package com.cbstudio.telltale\n"
        "class RendererPolicyTest\n"
        "class DevicePropertiesTest\n",
        encoding="utf-8",
    )


def run_guard(root: Path, script: str) -> subprocess.CompletedProcess:
    py = root / "guard.py"
    py.write_text(script, encoding="utf-8")
    return subprocess.run(
        [sys.executable, str(py)],
        cwd=root,
        capture_output=True,
        text=True,
    )


class RendererJvmCiGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.script = extract_guard(CI_PATH.read_text(encoding="utf-8"))
        if "executed <= 0" not in cls.script:
            raise AssertionError("ci.yml guard no longer checks executed > 0 per suite")
        if "skipped != 0" not in cls.script:
            raise AssertionError("ci.yml guard no longer checks skipped == 0 per suite")

    def _tree(self, suites: dict[str, tuple[int, int, int]]) -> Path:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        write_sources(root)
        reports = root / "build/app/test-results/testFieldDebugUnitTest"
        reports.mkdir(parents=True)
        for name, (tests, skipped, failures) in suites.items():
            write_xml(
                reports / f"TEST-{name}.xml",
                name,
                tests=tests,
                skipped=skipped,
                failures=failures,
            )
        return root

    def test_both_suites_executed_passes(self) -> None:
        root = self._tree(
            {
                REQUIRED[0]: (5, 0, 0),
                REQUIRED[1]: (3, 0, 0),
            }
        )
        result = run_guard(root, self.script)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_required_suite_all_skipped_while_other_ran_fails(self) -> None:
        root = self._tree(
            {
                REQUIRED[0]: (5, 5, 0),
                REQUIRED[1]: (3, 0, 0),
            }
        )
        result = run_guard(root, self.script)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(REQUIRED[0], result.stdout + result.stderr)

    def test_both_suites_all_skipped_fails(self) -> None:
        root = self._tree(
            {
                REQUIRED[0]: (5, 5, 0),
                REQUIRED[1]: (3, 3, 0),
            }
        )
        result = run_guard(root, self.script)
        self.assertNotEqual(result.returncode, 0)

    def test_missing_required_suite_fails(self) -> None:
        root = self._tree({REQUIRED[1]: (3, 0, 0)})
        result = run_guard(root, self.script)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected suites did not run", result.stdout + result.stderr)

    def test_failure_in_a_suite_fails(self) -> None:
        root = self._tree(
            {
                REQUIRED[0]: (5, 0, 1),
                REQUIRED[1]: (3, 0, 0),
            }
        )
        result = run_guard(root, self.script)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
