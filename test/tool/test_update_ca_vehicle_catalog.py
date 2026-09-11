from __future__ import annotations

import csv
import importlib.util
import io
from pathlib import Path
import stat
import tempfile
import unittest
from unittest import mock


APP_DIR = Path(__file__).resolve().parents[2]
SCRIPT_PATH = APP_DIR / "tool" / "update_ca_vehicle_catalog.py"


def load_updater():
    spec = importlib.util.spec_from_file_location(
        "update_ca_vehicle_catalog", SCRIPT_PATH
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def csv_text(header: tuple[str, ...], rows: list[list[str]]) -> str:
    output = io.StringIO(newline="")
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(header)
    writer.writerows(rows)
    return output.getvalue()


class CaVehicleCatalogUpdaterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.updater = load_updater()

    def test_ice_and_bev_same_name_stay_separate_classes(self) -> None:
        ice = csv_text(
            self.updater.ICE_HEADER,
            [
                [
                    "2024",
                    "Tesla",
                    "Model S",
                    "Full-size",
                    "0.0",
                    "0",
                    "A1",
                    "X",
                    "10",
                    "9",
                    "9.5",
                    "30",
                    "200",
                    "5",
                    "5",
                ]
            ],
        )
        bev = csv_text(
            self.updater.BEV_HEADER,
            [
                [
                    "2024",
                    "Tesla",
                    "Model S",
                    "Full-size",
                    "250",
                    "A1",
                    "B",
                    "18",
                    "20",
                    "19",
                    "2",
                    "2.2",
                    "2.1",
                    "500",
                    "0",
                    "n/a",
                    "n/a",
                    "10",
                ]
            ],
        )
        ice_res = {
            "resource_class": "ice",
            "header": self.updater.ICE_HEADER,
            "file_name": "my2024-ice.csv",
        }
        bev_res = {
            "resource_class": "bev",
            "header": self.updater.BEV_HEADER,
            "file_name": "my2012-2026-battery-electric-vehicles.csv",
        }
        catalog, statistics = self.updater.normalized_catalog(
            [(ice_res, ice), (bev_res, bev)]
        )
        rows = list(csv.DictReader(io.StringIO(catalog.decode("utf-8"))))
        self.assertEqual(len(rows), 2)
        self.assertEqual({row["resource_class"] for row in rows}, {"ice", "bev"})
        self.assertEqual(len({row["ca_id"] for row in rows}), 2)
        self.assertEqual(statistics["ice_count"], 1)
        self.assertEqual(statistics["bev_count"], 1)
        self.assertEqual(statistics["phev_count"], 0)
        ice_row = next(row for row in rows if row["resource_class"] == "ice")
        bev_row = next(row for row in rows if row["resource_class"] == "bev")
        self.assertEqual(ice_row["engine_size_l"], "0.0")
        self.assertEqual(bev_row["engine_size_l"], "")
        self.assertEqual(bev_row["motor_kw"], "250")
        self.assertEqual(ice_row["motor_kw"], "")
        self.assertTrue(catalog.endswith(b"\n"))

    def test_changed_ice_header_fails_closed(self) -> None:
        header = list(self.updater.ICE_HEADER)
        header[0] = "Year"
        text = csv_text(tuple(header), [["2026", "Acura", "Integra", "Full-size", "1.5", "4", "M6", "Z", "8", "6", "7", "39", "171", "6", "6"]])
        resource = {
            "resource_class": "ice",
            "header": self.updater.ICE_HEADER,
            "file_name": "my2026-fuel-consumption-ratings.csv",
        }
        with self.assertRaises(self.updater.CatalogError) as raised:
            self.updater.normalized_catalog([(resource, text)])
        self.assertIn("header mismatch", str(raised.exception))

    def test_cp1252_official_bytes_decode_when_pinned(self) -> None:
        text = "Model year,Make,Model\n2025,Audi,A5 Coupé\n"
        payload = text.encode("cp1252")
        decoded = self.updater.decode_source(payload, "cp1252")
        self.assertIn("Coupé", decoded)
        with self.assertRaises(self.updater.CatalogError):
            self.updater.decode_source(payload, "utf-8-sig")

    def test_phev_keeps_both_fuel_type_cells(self) -> None:
        phev = csv_text(
            self.updater.PHEV_HEADER,
            [
                [
                    "2013",
                    "Ford",
                    "Fusion Energi",
                    "Mid-size",
                    "35",
                    "2.0",
                    "4",
                    "AV",
                    "B/X",
                    "2.7",
                    "32",
                    "2.5",
                    "X",
                    "5.8",
                    "6.5",
                    "6.1",
                    "856",
                    "80",
                    "n/a",
                    "n/a",
                ]
            ],
        )
        resource = {
            "resource_class": "phev",
            "header": self.updater.PHEV_HEADER,
            "file_name": "my2012-2026-plug-in-hybrid-electric-vehicles.csv",
        }
        catalog, statistics = self.updater.normalized_catalog([(resource, phev)])
        row = list(csv.DictReader(io.StringIO(catalog.decode("utf-8"))))[0]
        self.assertEqual(row["resource_class"], "phev")
        self.assertEqual(row["fuel_type"], "B/X|X")
        self.assertEqual(row["engine_size_l"], "2.0")
        self.assertEqual(statistics["phev_count"], 1)

    def test_duplicate_identity_fails_closed(self) -> None:
        ice = csv_text(
            self.updater.ICE_HEADER,
            [
                ["2026", "Acura", "Integra", "Full-size", "1.5", "4", "M6", "Z", "8", "6", "7", "39", "171", "6", "6"],
                ["2026", "Acura", "Integra", "Full-size", "1.5", "4", "M6", "Z", "9", "6", "7", "39", "171", "6", "6"],
            ],
        )
        resource = {
            "resource_class": "ice",
            "header": self.updater.ICE_HEADER,
            "file_name": "my2026-fuel-consumption-ratings.csv",
        }
        with self.assertRaises(self.updater.CatalogError) as raised:
            self.updater.normalized_catalog([(resource, ice)])
        self.assertIn("duplicate ca_id", str(raised.exception))

    def test_atomic_write_replaces_file_with_stable_permissions_and_no_temp_file(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "ca_nrcan_vehicles.csv"
            output.write_bytes(b"old")
            self.updater.write_atomic(output, b"new")
            self.assertEqual(output.read_bytes(), b"new")
            self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o644)
            self.assertEqual(list(Path(directory).glob(".*.tmp")), [])

    def test_atomic_write_preserves_old_file_and_cleans_temp_when_replace_fails(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "ca_nrcan_vehicles.csv"
            output.write_bytes(b"old")
            with mock.patch.object(
                self.updater.os, "replace", side_effect=OSError("replace failed")
            ):
                with self.assertRaisesRegex(OSError, "replace failed"):
                    self.updater.write_atomic(output, b"new")
            self.assertEqual(output.read_bytes(), b"old")
            self.assertEqual(list(Path(directory).glob(".*.tmp")), [])

    def test_write_outputs_replaces_catalog_and_manifest_atomically(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output_dir = Path(directory)
            catalog_path = output_dir / self.updater.CATALOG_FILENAME
            manifest_path = output_dir / self.updater.MANIFEST_FILENAME
            catalog_path.write_bytes(b"old-catalog")
            manifest_path.write_text("old-manifest\n", encoding="utf-8")
            self.updater.write_outputs(
                output_dir,
                b"new-catalog",
                {"schema_version": 1},
            )
            self.assertEqual(catalog_path.read_bytes(), b"new-catalog")
            self.assertIn('"schema_version": 1', manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(list(output_dir.glob(".*.tmp")), [])


if __name__ == "__main__":
    unittest.main()
