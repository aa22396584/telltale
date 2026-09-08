#!/usr/bin/env python3
"""#47: CI must run the ARB locale checker, not only ship the files.

Drives the text of `.github/workflows/ci.yml`, not a rewrite of the checker.
"""

from __future__ import annotations

import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CI_PATH = REPO / ".github" / "workflows" / "ci.yml"


class I18nVerifyCiGuardTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = CI_PATH.read_text(encoding="utf-8")

    def test_ci_discovers_the_i18n_verify_unittests(self) -> None:
        self.assertIn("-s tool/i18n_verify", self.workflow)
        self.assertIn("python3 -m unittest discover", self.workflow)
        self.assertIn("tool/i18n_verify/check_arb.py", self.workflow)

    def test_ci_runs_check_arb_on_shipped_locales(self) -> None:
        self.assertIn("lib/l10n/app_en.arb", self.workflow)
        self.assertIn("lib/l10n/app_zh.arb", self.workflow)
        self.assertIn("lib/l10n/app_zh_Hant.arb", self.workflow)
        arb_step = self.workflow.index("ARB locales have matching keys")
        shipped = self.workflow.index("lib/l10n/app_en.arb")
        self.assertGreater(shipped, arb_step)

    def test_ci_compiles_the_checker_before_running_it(self) -> None:
        compile_at = self.workflow.index(
            "python3 -m py_compile tool/i18n_verify/check_arb.py"
        )
        discover_at = self.workflow.index("-s tool/i18n_verify")
        self.assertGreater(discover_at, compile_at)


if __name__ == "__main__":
    unittest.main()
