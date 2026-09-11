from __future__ import annotations

import csv
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import unittest
import zipfile


APP_DIR = Path(__file__).resolve().parents[2]
SCRIPT_PATH = APP_DIR / "tool" / "update_tw_vehicle_catalog.py"


def load_updater():
    spec = importlib.util.spec_from_file_location(
        "update_tw_vehicle_catalog", SCRIPT_PATH
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def zip_bytes(members: dict[str, bytes]) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, mode="w", compression=zipfile.ZIP_STORED) as bundle:
        for name, data in members.items():
            bundle.writestr(name, data)
    return output.getvalue()


INDEX_11163 = (
    "所屬機關,FileName(檔案名稱),FileUrl(檔案連結),CreateDate(建立日期),備註\n"
    "經濟部能源署,車輛油耗指南,https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=26,20251120,\n"
).encode("utf-8")

INDEX_6032 = (
    "所屬機關,FileName(檔案名稱),FileUrl(檔案連結),CreateDate(建立日期),備註\n"
    "經濟部能源署,車型耗能證明核發資料,https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=7,20250909,\n"
).encode("utf-8")

API_11163 = json.dumps(
    {
        "success": True,
        "result": {
            "distribution": [
                {
                    "resourceDownloadUrl": "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=331"
                }
            ]
        },
    }
).encode("utf-8")

API_6032 = json.dumps(
    {
        "success": True,
        "result": {
            "distribution": [
                {
                    "resourceDownloadUrl": "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=305"
                }
            ]
        },
    }
).encode("utf-8")

PASSENGER_CSV = """國產小客車車型耗能證明115年7月核發資料,,,,,,,,,,,,
,,,,,,,,,,,,能效單位：公里/公升
廠    牌,車        型,排檔,門,排氣量,參考車,能效,市區,非市區,能效,申請,耗能證明,能源效率
,,型式,數,(c.c.),重(kg),標準,能效,能效,測試值,單位,核發日期,等    級
汽油車型:,,,,,,,,,,,,
本田,FIT A522H1502,A1,5D,1498.0,1320.0,11.3,20.0,30.0,26.9,台灣本田,115/07/02,1級
本田,FIT A522H1502,A1,5D,1498.0,1320.0,11.3,20.0,30.0,26.9,台灣本田,115/07/20,1級
TOYOTA,CAMRY HYBRID,CVT,4D,2487.0,1678.0,8.7,18.0,28.0,25.3,和泰汽車,115/07/03,1級
""".encode("utf-8-sig")

EMPTY_MONTH_CSV = """國產小客車車型耗能證明115年6月核發資料(本月無車型資料),,,,,,,,,,,,
廠    牌,車        型,排檔,門,排氣量,參考車,能效,市區,非市區,能效,申請,耗能證明,能源效率
,,型式,數,(c.c.),重(kg),標準,能效,能效,測試值,單位,核發日期,等    級
本月份無資料,,,,,,,,,,,,
""".encode("utf-8-sig")

EV_CSV = """小客車電動車能效標示115年7月核發資料,,,,,,,,,,
廠    牌,車     型,製造,排檔,門,最大輸出,參考車,純電行程,能效,申請,核發日期
,,別,型式,數,馬力(hp),重(kg),(公里),測試值,單位,
MINI,MINI COUNTRYMAN E,進口,A1,5D,204.0,2032.0,532,7.3,汎德公司,115/07/02
""".encode("utf-8-sig")

MALFORMED_ROW_CSV = """國產小客車車型耗能證明115年7月核發資料,,,,,,,,,,,,
廠    牌,車        型,排檔,門,排氣量,參考車,能效,市區,非市區,能效,申請,耗能證明,能源效率
,,型式,數,(c.c.),重(kg),標準,能效,能效,測試值,單位,核發日期,等    級
本田,,A1,5D,1498.0,1320.0,11.3,20.0,30.0,26.9,台灣本田,115/07/02,1級
""".encode("utf-8-sig")

CHANGED_SCHEMA_CSV = """國產小客車車型耗能證明115年7月核發資料
not_make,not_model
x,y
""".encode("utf-8-sig")


class TwVehicleCatalogUpdaterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.u = load_updater()

    def test_valid_source_normalizes_latest_duplicate_and_skips_empty_month(self) -> None:
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": PASSENGER_CSV,
                "耗能證明115年6月核發資料/國產小客車車型耗能證明115年6月核發資料(本月無車型資料).csv": EMPTY_MONTH_CSV,
                "耗能證明115年7月核發資料/小客車電動車能效標示115年7月核發資料.csv": EV_CSV,
            }
        )
        catalog, stats, _ = self.u.parse_6032_zip(archive)
        rows = list(csv.DictReader(io.StringIO(catalog.decode("utf-8"))))
        self.assertEqual(stats["row_count"], 3)
        self.assertEqual(stats["unique_make_count"], 3)
        self.assertEqual(stats["year_min"], 2026)
        self.assertEqual(stats["year_max"], 2026)
        fit = next(row for row in rows if row["model"] == "FIT A522H1502")
        self.assertEqual(fit["market"], "TW")
        self.assertEqual(fit["origin"], "domestic")
        self.assertEqual(fit["issue_date"], "2026-07-20")
        self.assertEqual(fit["displacement_cc"], "1498.0")
        self.assertEqual(fit["reference_mass_kg"], "1320.0")
        mini = next(row for row in rows if row["make"] == "MINI")
        self.assertEqual(mini["powertrain"], "bev")
        self.assertEqual(mini["origin"], "import")
        self.assertTrue(catalog.endswith(b"\n"))
        self.assertEqual(catalog, self.u.parse_6032_zip(archive)[0])

    def test_changed_schema_fails_closed(self) -> None:
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": CHANGED_SCHEMA_CSV,
            }
        )
        with self.assertRaises(self.u.CatalogError):
            self.u.parse_6032_zip(archive)

    def test_malformed_row_missing_model_fails_closed(self) -> None:
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": MALFORMED_ROW_CSV,
            }
        )
        with self.assertRaises(self.u.CatalogError) as raised:
            self.u.parse_6032_zip(archive)
        self.assertIn("廠牌 or 車型", str(raised.exception))

    def test_empty_source_field_stays_empty(self) -> None:
        csv_bytes = """國產小客車車型耗能證明115年7月核發資料,,,,,,,,,,,,
廠    牌,車        型,排檔,門,排氣量,參考車,能效,市區,非市區,能效,申請,耗能證明,能源效率
,,型式,數,(c.c.),重(kg),標準,能效,能效,測試值,單位,核發日期,等    級
本田,FIT EMPTY MASS,A1,5D,1498.0,,11.3,20.0,30.0,26.9,台灣本田,115/07/02,1級
""".encode("utf-8-sig")
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": csv_bytes,
            }
        )
        catalog, _, _ = self.u.parse_6032_zip(archive)
        row = list(csv.DictReader(io.StringIO(catalog.decode("utf-8"))))[0]
        self.assertEqual(row["reference_mass_kg"], "")
        self.assertEqual(row["displacement_cc"], "1498.0")

    def test_index_empty_fileurl_fails_closed(self) -> None:
        empty = (
            "所屬機關,FileName(檔案名稱),FileUrl(檔案連結),CreateDate(建立日期),備註\n"
            "經濟部能源署,車輛油耗指南,,20251120,\n"
        ).encode("utf-8")
        with self.assertRaises(self.u.CatalogError) as raised:
            self.u.parse_index_csv(empty, label="index")
        self.assertIn("empty FileUrl", str(raised.exception))

    def test_index_changed_schema_fails_closed(self) -> None:
        with self.assertRaises(self.u.CatalogError):
            self.u.parse_index_csv(b"foo,bar\n1,2\n", label="index")

    def test_row_count_and_hash_are_in_manifest(self) -> None:
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": PASSENGER_CSV,
            }
        )
        catalog, stats, _ = self.u.parse_6032_zip(archive)
        manifest = self.u.build_manifest(
            catalog=catalog,
            statistics=stats,
            retrieved_at="2026-09-11T00:00:00+00:00",
            pin_11163={"dataset_id": 11163, "artifact_sha256": "a" * 64},
            pin_6032={"dataset_id": 6032, "artifact_sha256": "b" * 64},
        )
        self.assertEqual(manifest["coverage"]["market"], "Taiwan")
        self.assertEqual(manifest["output"]["row_count"], 2)
        self.assertEqual(manifest["output"]["sha256"], sha256(catalog))
        self.assertEqual(manifest["output"]["size_bytes"], len(catalog))
        self.assertIn("curb mass", manifest["coverage"]["does_not_assert"])
        self.assertIn("U.S. EPA namesake identity", manifest["coverage"]["does_not_assert"])

    def test_build_catalog_pins_pdf_guide_and_zip_identity(self) -> None:
        archive = zip_bytes(
            {
                "耗能證明115年7月核發資料/國產小客車車型耗能證明115年7月核發資料.csv": PASSENGER_CSV,
            }
        )
        pdf = b"%PDF-1.6 fake guide"
        urls = {
            self.u.DATASET_API_11163: (API_11163, {}),
            "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=331": (
                INDEX_11163,
                {},
            ),
            "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=26": (
                pdf,
                {"content-type": "application/pdf"},
            ),
            self.u.DATASET_API_6032: (API_6032, {}),
            "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=305": (
                INDEX_6032,
                {},
            ),
            "https://www.moeaea.gov.tw/ECW/populace/opendata/wHandOpenData_File.ashx?set_id=7": (
                archive,
                {"content-type": "application/zip"},
            ),
        }

        def fake_download(url: str) -> tuple[bytes, dict[str, str]]:
            return urls[url]

        catalog, manifest = self.u.build_catalog(
            fake_download, "2026-09-11T00:00:00+00:00"
        )
        self.assertEqual(manifest["source"]["guide_11163"]["artifact_sha256"], sha256(pdf))
        self.assertEqual(
            manifest["source"]["identity_6032"]["artifact_sha256"], sha256(archive)
        )
        rows = list(csv.DictReader(io.StringIO(catalog.decode("utf-8"))))
        self.assertEqual(len(rows), 2)
        self.assertTrue(all(row["market"] == "TW" for row in rows))


if __name__ == "__main__":
    unittest.main()
