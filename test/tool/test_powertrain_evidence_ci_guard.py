#!/usr/bin/env python3
"""CI must run the powertrain evidence matrix unittests and validator."""

from __future__ import annotations

import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CI_PATH = REPO / ".github" / "workflows" / "ci.yml"


class PowertrainEvidenceCiGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = CI_PATH.read_text(encoding="utf-8")

    def test_ci_discovers_the_powertrain_evidence_unittests(self) -> None:
        self.assertIn("-s tool/powertrain_evidence", self.workflow)
        self.assertIn("python3 -m unittest discover", self.workflow)

    def test_ci_runs_generate_check_and_validate(self) -> None:
        self.assertIn("tool/powertrain_evidence/generate_matrix.py --check", self.workflow)
        self.assertIn("tool/powertrain_evidence/validate_matrix.py", self.workflow)

    def test_ci_compiles_the_matrix_tools_before_running_them(self) -> None:
        compile_at = self.workflow.index("tool/powertrain_evidence/generate_matrix.py")
        discover_at = self.workflow.index("-s tool/powertrain_evidence")
        self.assertGreater(discover_at, compile_at)
        self.assertIn("python3 -m py_compile", self.workflow)
