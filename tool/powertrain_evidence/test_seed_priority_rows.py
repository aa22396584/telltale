#!/usr/bin/env python3
"""Seed priority set (#332 slice 2): dated rows, no invented wire contracts."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

import validate_matrix

RESEARCH_PATH = Path(__file__).resolve().parent / "research" / "rows.json"

SEED_IDS = frozenset(
    {
        "tesla-model-3-pre-highland",
        "tesla-model-3-highland",
        "tesla-model-y",
        "byd-atto3-post-2024-10",
        "byd-seagull-dolphin-mini",
        "byd-dolphin",
        "byd-atto2-yuan-up",
        "byd-seal",
        "byd-seal-u-song",
        "byd-sealion",
        "geely-galaxy-xingyuan",
        "zeekr",
        "wuling-hongguang-mini-ev",
        "xiaomi-su7",
        "xiaomi-yu7",
        "xpeng",
        "volkswagen-id3-meb",
        "volkswagen-id4-meb",
        "renault-current-ev",
        "hyundai-kia-egmp-beyond-shipped-community",
        "nissan-leaf",
        "nissan-ariya",
        "bmw-electrified",
        "mg-zs-ev-mk2",
    }
)

GENERATION_SPLITS = (
    ("tesla-model-3-pre-highland", "tesla-model-3-highland"),
    ("tesla-model-y", "tesla-model-y-juniper"),
)


class SeedPriorityRowsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        payload = json.loads(RESEARCH_PATH.read_bytes().decode("utf-8"))
        cls.rows = {row["id"]: row for row in payload["rows"]}

    def test_seed_ids_are_present_and_dated(self) -> None:
        missing = SEED_IDS - set(self.rows)
        self.assertEqual(missing, set())
        for row_id in SEED_IDS:
            row = self.rows[row_id]
            self.assertNotEqual(
                row.get("disposition"),
                "unknown",
                msg=f"{row_id} is still unknown",
            )
            self.assertNotEqual(
                row.get("blocker"),
                "not yet researched",
                msg=f"{row_id} still has the unresearched blocker",
            )
            self.assertRegex(str(row.get("evidence_date") or ""), r"^\d{4}-\d{2}-\d{2}$")

    def test_unresearched_placeholder_outside_seed_set_is_allowed(self) -> None:
        """Lock the seed set only; unknown remains valid for later nameplates."""
        self.assertNotIn("fixture-unresearched-placeholder", SEED_IDS)
        self.assertNotIn("fixture-unresearched-placeholder", self.rows)

    def test_generation_splits_are_separate_rows(self) -> None:
        for left, right in GENERATION_SPLITS:
            self.assertIn(left, self.rows)
            self.assertIn(right, self.rows)
            self.assertNotEqual(self.rows[left].get("generation"), self.rows[right].get("generation"))

    def test_atto3_post_update_does_not_inherit_community(self) -> None:
        row = self.rows["byd-atto3-post-2024-10"]
        self.assertEqual(row["disposition"], "no-source")
        self.assertEqual(row["catalog_profile_ids"], [])
        self.assertNotIn("byd-atto3-2022-2024-community", row.get("catalog_profile_ids", []))
        self.assertEqual(row.get("source_families"), [])

    def test_no_invented_wire_contracts(self) -> None:
        for row_id, row in self.rows.items():
            self.assertFalse(row.get("commands"), msg=f"{row_id} has commands")
            self.assertEqual(row.get("signals"), [], msg=f"{row_id} has signals")
            self.assertFalse(
                validate_matrix._has_executable_claim(row),
                msg=f"{row_id} carries an executable claim",
            )

    def test_sales_stay_inside_priority(self) -> None:
        for row_id, row in self.rows.items():
            self.assertFalse(
                validate_matrix._sales_outside_priority(row),
                msg=f"{row_id} has sales/popularity outside priority",
            )

    def test_mg_mk2_does_not_list_mk1_community(self) -> None:
        row = self.rows["mg-zs-ev-mk2"]
        self.assertNotIn("mg-zs-ev-au-2021", row.get("catalog_profile_ids", []))
        self.assertEqual(row["disposition"], "single-family")

    def test_megane_aliases_are_megane_only(self) -> None:
        row = self.rows["renault-megane-e-tech"]
        aliases = row.get("aliases") or []
        self.assertIn("Renault Megane E-Tech", aliases)
        self.assertNotIn("Scenic E-Tech", aliases)
        self.assertNotIn("Renault 5 E-Tech", aliases)
        self.assertEqual(self.rows["renault-scenic-e-tech"]["disposition"], "no-source")
        self.assertEqual(self.rows["renault-5-e-tech"]["disposition"], "no-source")

    def test_ioniq5_facelift_does_not_list_community(self) -> None:
        row = self.rows["hyundai-kia-egmp-beyond-shipped-community"]
        ids = row.get("catalog_profile_ids", [])
        self.assertEqual(ids, ["hyundai-ioniq5-2025-2026"])
        self.assertNotIn("hyundai-ioniq5-egmp-2021-2024-community", ids)
        self.assertNotIn("kia-ev9-egmp-2024-2025-experimental", ids)


if __name__ == "__main__":
    unittest.main()
