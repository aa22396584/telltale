#!/usr/bin/env python3
"""Update the offline Taiwan MOEA Energy Administration vehicle identity catalog.

Dataset 11163 (車輛油耗指南) is pinned as the named annual guide. At retrieval
its FileUrl is a PDF, which is not a configuration table and is not parsed
into rows.

Configuration identity rows come from dataset 6032 (車型耗能證明核發資料),
the same agency's official monthly certification CSVs. Those columns keep
their source meanings: 參考車重 is not curb mass, 最大輸出馬力 is not wheel
horsepower, and a Taiwan make/model string is not an EPA configuration.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, Mapping, Sequence
from urllib.request import Request, urlopen


USER_AGENT = "TelltaleVehicleCatalogUpdater/1.0 (+https://github.com/aa22396584/telltale)"
DOWNLOAD_TIMEOUT_SECONDS = 120
DATASET_API_11163 = "https://data.gov.tw/api/v2/rest/dataset/11163"
DATASET_API_6032 = "https://data.gov.tw/api/v2/rest/dataset/6032"
LICENSE_URL = "https://data.gov.tw/license"
LANDING_11163 = "https://data.gov.tw/dataset/11163"
LANDING_6032 = "https://data.gov.tw/dataset/6032"

SCRIPT_DIR = Path(__file__).resolve().parent
APP_DIR = SCRIPT_DIR.parent
DEFAULT_OUTPUT_DIR = APP_DIR / "assets" / "vehicle_catalog"
CATALOG_FILENAME = "tw_moeaea_vehicles.csv"
MANIFEST_FILENAME = "tw_moeaea_vehicles.manifest.json"

INDEX_COLUMNS = (
    "所屬機關",
    "FileName(檔案名稱)",
    "FileUrl(檔案連結)",
    "CreateDate(建立日期)",
    "備註",
)

OUTPUT_COLUMNS = (
    "tw_id",
    "market",
    "origin",
    "vehicle_class",
    "powertrain",
    "issue_year_ce",
    "issue_date",
    "make",
    "model",
    "transmission",
    "doors",
    "displacement_cc",
    "reference_mass_kg",
    "applicant",
    "source_file",
)

DownloadFn = Callable[[str], tuple[bytes, Mapping[str, str]]]


class CatalogError(RuntimeError):
    """Raised when the official Taiwan source cannot be safely normalized."""


# ZIP general-purpose bit 11. Official dataset 6032 leaves it unset and stores
# member names as Big5/cp950; Python's zipfile then decodes those bytes as CP437.
_ZIP_UTF8_NAME_FLAG = 0x800

# Observed on the pinned 6032 archive (SHA-256 da6b72a1…, 896 members):
# empty passenger-car months are either named *(本月無車型資料)* or, when the
# filename is an ordinary 國產小客車 CSV, the body contains one of these cells.
# A recognised header with zero data rows and neither marker is not empty.
EMPTY_MONTH_FILENAME_MARKER = "無車型"
EMPTY_MONTH_BODY_MARKERS = ("本月份無資料", "無車型資料")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def download(url: str) -> tuple[bytes, Mapping[str, str]]:
    request = Request(
        url,
        headers={
            "Accept": "*/*",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urlopen(request, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
            payload = response.read()
            headers = {key.lower(): value for key, value in response.headers.items()}
    except OSError as error:
        raise CatalogError(f"download failed for {url}: {error}") from error
    if not payload:
        raise CatalogError(f"download returned empty bytes for {url}")
    return payload, headers


def _decode_text(data: bytes, label: str) -> str:
    for encoding in ("utf-8-sig", "utf-8"):
        try:
            text = data.decode(encoding)
        except UnicodeDecodeError:
            continue
        if "\x00" in text:
            raise CatalogError(f"{label} contains a NUL")
        return text
    raise CatalogError(f"{label} is not valid UTF-8")


def parse_index_csv(data: bytes, *, label: str) -> dict[str, str]:
    text = _decode_text(data, label)
    reader = csv.DictReader(io.StringIO(text, newline=""))
    if reader.fieldnames is None:
        raise CatalogError(f"{label} has no header")
    missing = [name for name in INDEX_COLUMNS if name not in reader.fieldnames]
    if missing:
        raise CatalogError(
            f"{label} is missing required columns: " + ", ".join(missing)
        )
    rows = list(reader)
    if len(rows) != 1:
        raise CatalogError(f"{label} must contain exactly one data row, found {len(rows)}")
    row = rows[0]
    if None in row:
        raise CatalogError(f"{label} has extra columns")
    file_url = (row["FileUrl(檔案連結)"] or "").strip()
    if not file_url:
        raise CatalogError(f"{label} has an empty FileUrl")
    if not file_url.startswith("https://"):
        raise CatalogError(f"{label} FileUrl is not https: {file_url!r}")
    return {
        "agency": (row["所屬機關"] or "").strip(),
        "file_name": (row["FileName(檔案名稱)"] or "").strip(),
        "file_url": file_url,
        "create_date": (row["CreateDate(建立日期)"] or "").strip(),
        "notes": (row["備註"] or "").strip(),
    }


def _compact(cell: str) -> str:
    return re.sub(r"\s+", "", cell or "")


def _is_blank(row: Sequence[str]) -> bool:
    return all(not (cell or "").strip() for cell in row)


def _looks_like_header(row: Sequence[str]) -> bool:
    if not row:
        return False
    compact = _compact(row[0])
    return compact.startswith("廠") and "牌" in compact


def _skip_non_data(row: Sequence[str]) -> bool:
    joined = "".join(row)
    if "本月份無資料" in joined or "無車型資料" in joined:
        return True
    if "能效單位" in joined or "油耗單位" in joined:
        return True
    if "插電式複合動力車型" in joined:
        return True
    first = (row[0] or "").strip()
    return first.endswith("核發資料") or (
        first.endswith("標示") and "廠" not in first
    )


def _column_map(header: Sequence[str], subheader: Sequence[str] | None) -> dict[str, int]:
    merged: list[str] = []
    width = max(len(header), len(subheader or ()))
    for index in range(width):
        top = header[index] if index < len(header) else ""
        bottom = subheader[index] if subheader is not None and index < len(subheader) else ""
        merged.append(_compact(top) + _compact(bottom))
    mapping: dict[str, int] = {}
    for index, name in enumerate(merged):
        if "廠牌" in name and "make" not in mapping:
            mapping["make"] = index
        elif name.startswith("車型") or name == "車型":
            mapping["model"] = index
        elif "排檔型式" in name or "傳動型式" in name or name in {"排檔", "傳動"}:
            mapping["transmission"] = index
        elif "門數" in name or name == "門":
            mapping["doors"] = index
        elif "排氣量" in name:
            mapping["displacement_cc"] = index
        elif "參考車重" in name or name == "參考車":
            mapping["reference_mass_kg"] = index
        elif "申請單位" in name or name == "申請":
            mapping["applicant"] = index
        elif "核發日期" in name:
            mapping["issue_date"] = index
        elif "製造別" in name or name == "製造":
            mapping["origin"] = index
    if "make" not in mapping or "model" not in mapping:
        raise CatalogError(
            "source table is missing 廠牌/車型 columns: " + ",".join(merged)
        )
    return mapping


def _cell(row: Sequence[str], index: int | None) -> str:
    if index is None or index >= len(row):
        return ""
    return (row[index] or "").strip()


def decode_zip_member_name(info: zipfile.ZipInfo) -> str:
    """Decode a 6032 zip member name.

    Entries with the UTF-8 name flag keep zipfile's UTF-8 filename. Entries
    without it were stored as cp950; zipfile exposes them as CP437, so the
    original bytes are recovered and decoded as cp950. Python 3.12+ may
    already have replaced the filename from extra field 0x7075; that name
    is not CP437 and is kept. Bytes that decode as CP437 but not cp950 are
    a hard error — the official archive is not silently skipped.
    """
    if info.flag_bits & _ZIP_UTF8_NAME_FLAG:
        return info.filename
    try:
        recovered = info.filename.encode("cp437")
    except UnicodeEncodeError:
        return info.filename
    try:
        return recovered.decode("cp950")
    except UnicodeDecodeError as error:
        raise CatalogError(
            f"undecodable zip member name {info.filename!r}: {error}"
        ) from error


def is_explicit_empty_month(*, name: str, data: bytes) -> bool:
    """True only for empty-month shapes observed in the official 6032 zip."""
    if EMPTY_MONTH_FILENAME_MARKER in Path(name).name:
        return True
    text = _decode_text(data, name)
    return any(marker in text for marker in EMPTY_MONTH_BODY_MARKERS)


def _classify_member(name: str) -> tuple[str, str, str] | None:
    filename = Path(name).name
    if EMPTY_MONTH_FILENAME_MARKER in filename:
        return None
    if "機車" in filename:
        return None
    if "小貨車" in filename or "2.5-3.5" in filename or "2,500" in filename:
        return None
    if "小客車" not in filename and "電動小客車" not in filename:
        return None
    origin = "import" if "進口" in filename else "domestic" if "國產" in filename else "unspecified"
    if "電動" in filename:
        return origin, "passenger", "bev"
    return origin, "passenger", "ice"


def _parse_issue_date(raw: str) -> tuple[str, int] | None:
    text = raw.strip()
    match = re.fullmatch(r"(\d{2,3})/(\d{1,2})/(\d{1,2})", text)
    if match is None:
        return None
    roc = int(match.group(1))
    month = int(match.group(2))
    day = int(match.group(3))
    if roc < 90 or month < 1 or month > 12 or day < 1 or day > 31:
        raise CatalogError(f"out-of-range ROC issue date {raw!r}")
    year_ce = roc + 1911
    return f"{year_ce:04d}-{month:02d}-{day:02d}", year_ce


def _folder_issue_year(name: str) -> int | None:
    match = re.search(r"(\d{2,3})年(\d{1,2})月", name)
    if match is None:
        return None
    roc = int(match.group(1))
    if roc < 90:
        return None
    return roc + 1911


def _identity_id(parts: Sequence[str]) -> str:
    payload = "\x1f".join(parts).encode("utf-8")
    return sha256_bytes(payload)[:16]


def parse_member_csv(
    *,
    name: str,
    data: bytes,
    origin: str,
    vehicle_class: str,
    powertrain: str,
    folder_year_ce: int | None,
) -> list[dict[str, str]]:
    text = _decode_text(data, name)
    reader = csv.reader(io.StringIO(text, newline=""))
    header: list[str] | None = None
    subheader: list[str] | None = None
    mapping: dict[str, int] | None = None
    current_powertrain = powertrain
    rows: list[dict[str, str]] = []

    for source_row_number, row in enumerate(reader, start=1):
        if _is_blank(row):
            continue
        joined = "".join(row)
        if "插電式複合動力車型" in joined:
            current_powertrain = "phev"
            header = None
            subheader = None
            mapping = None
            continue
        if _looks_like_header(row):
            header = list(row)
            subheader = None
            mapping = None
            continue
        if header is not None and subheader is None and _compact(row[0]) == "" and "型式" in "".join(row):
            subheader = list(row)
            mapping = _column_map(header, subheader)
            continue
        if _skip_non_data(row):
            continue
        if header is None:
            continue
        if mapping is None:
            mapping = _column_map(header, None)

        make = _cell(row, mapping.get("make"))
        model = _cell(row, mapping.get("model"))
        if not make and not model:
            continue
        section = make.rstrip(":：")
        if not model:
            has_vehicle_fields = any(
                _cell(row, mapping.get(field))
                for field in (
                    "transmission",
                    "doors",
                    "displacement_cc",
                    "reference_mass_kg",
                    "issue_date",
                )
            )
            if not has_vehicle_fields or section.endswith("車型") or "複合動力" in section:
                continue
            raise CatalogError(
                f"{name} row {source_row_number} is missing 廠牌 or 車型"
            )
        if not make:
            raise CatalogError(
                f"{name} row {source_row_number} is missing 廠牌 or 車型"
            )
        if "\x00" in make or "\x00" in model:
            raise CatalogError(f"{name} row {source_row_number} contains a NUL")

        issue_raw = _cell(row, mapping.get("issue_date"))
        parsed_date = _parse_issue_date(issue_raw) if issue_raw else None
        if parsed_date is None:
            if folder_year_ce is None:
                raise CatalogError(
                    f"{name} row {source_row_number} has no parseable issue date"
                )
            issue_date = ""
            issue_year_ce = folder_year_ce
        else:
            issue_date, issue_year_ce = parsed_date
        row_origin = _cell(row, mapping.get("origin")) or origin
        if row_origin in {"進口", "import"}:
            row_origin = "import"
        elif row_origin in {"國產", "domestic"}:
            row_origin = "domestic"

        rows.append(
            {
                "market": "TW",
                "origin": row_origin,
                "vehicle_class": vehicle_class,
                "powertrain": current_powertrain,
                "issue_year_ce": str(issue_year_ce),
                "issue_date": issue_date,
                "make": make,
                "model": model,
                "transmission": _cell(row, mapping.get("transmission")),
                "doors": _cell(row, mapping.get("doors")),
                "displacement_cc": _cell(row, mapping.get("displacement_cc")),
                "reference_mass_kg": _cell(row, mapping.get("reference_mass_kg")),
                "applicant": _cell(row, mapping.get("applicant")),
                "source_file": Path(name).name,
            }
        )
    return rows


def parse_6032_zip(archive: bytes) -> tuple[bytes, dict[str, int], list[str]]:
    try:
        bundle = zipfile.ZipFile(io.BytesIO(archive))
    except zipfile.BadZipFile as error:
        raise CatalogError(f"6032 artifact is not a zip: {error}") from error

    members = [info for info in bundle.infolist() if not info.is_dir()]
    if not members:
        raise CatalogError("6032 zip contains no files")

    collected: list[dict[str, str]] = []
    parsed_files = 0
    decoded_names: list[str] = []
    for info in members:
        name = decode_zip_member_name(info)
        decoded_names.append(name)
        classified = _classify_member(name)
        if classified is None:
            continue
        if info.file_size <= 0:
            raise CatalogError(f"{name} is empty")
        origin, vehicle_class, powertrain = classified
        parsed_files += 1
        data = bundle.read(info)
        rows = parse_member_csv(
            name=name,
            data=data,
            origin=origin,
            vehicle_class=vehicle_class,
            powertrain=powertrain,
            folder_year_ce=_folder_issue_year(name),
        )
        if not rows and not is_explicit_empty_month(name=name, data=data):
            raise CatalogError(
                f"{name} is a classified passenger-car table but "
                "produced no identity rows"
            )
        collected.extend(rows)

    if parsed_files == 0:
        raise CatalogError("6032 zip contains no passenger-car tables")
    if not collected:
        raise CatalogError("6032 passenger-car tables contained no identity rows")

    by_key: dict[tuple[str, ...], dict[str, str]] = {}
    for row in collected:
        key = (
            row["origin"],
            row["vehicle_class"],
            row["powertrain"],
            row["make"],
            row["model"],
            row["transmission"],
            row["doors"],
            row["displacement_cc"],
            row["reference_mass_kg"],
        )
        previous = by_key.get(key)
        if previous is None or row["issue_date"] >= previous["issue_date"]:
            by_key[key] = row

    ordered = sorted(
        by_key.values(),
        key=lambda row: (
            row["issue_year_ce"],
            row["make"],
            row["model"],
            row["transmission"],
            row["doors"],
            row["displacement_cc"],
            row["origin"],
            row["powertrain"],
        ),
    )
    output_rows: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    years: list[int] = []
    makes: set[str] = set()
    for row in ordered:
        tw_id = _identity_id(
            [
                row["origin"],
                row["vehicle_class"],
                row["powertrain"],
                row["make"],
                row["model"],
                row["transmission"],
                row["doors"],
                row["displacement_cc"],
                row["reference_mass_kg"],
            ]
        )
        if tw_id in seen_ids:
            raise CatalogError(f"duplicate tw_id {tw_id}")
        seen_ids.add(tw_id)
        row = dict(row)
        row["tw_id"] = tw_id
        output_rows.append(row)
        years.append(int(row["issue_year_ce"]))
        makes.add(row["make"])

    output = io.StringIO(newline="")
    writer = csv.DictWriter(
        output,
        fieldnames=OUTPUT_COLUMNS,
        lineterminator="\n",
        extrasaction="raise",
    )
    writer.writeheader()
    writer.writerows(output_rows)
    catalog = output.getvalue().encode("utf-8")
    statistics = {
        "row_count": len(output_rows),
        "unique_make_count": len(makes),
        "year_min": min(years),
        "year_max": max(years),
    }
    return catalog, statistics, decoded_names


def dataset_download_url(metadata: Mapping[str, object], dataset_id: int) -> str:
    result = metadata.get("result")
    if not isinstance(result, dict):
        raise CatalogError(f"dataset {dataset_id} metadata is not an object")
    distribution = result.get("distribution")
    if not isinstance(distribution, list) or not distribution:
        raise CatalogError(f"dataset {dataset_id} has no distribution")
    first = distribution[0]
    if not isinstance(first, dict):
        raise CatalogError(f"dataset {dataset_id} distribution is malformed")
    url = first.get("resourceDownloadUrl")
    if not isinstance(url, str) or not url.startswith("https://"):
        raise CatalogError(f"dataset {dataset_id} has no https resourceDownloadUrl")
    return url


def load_json(data: bytes, label: str) -> dict[str, object]:
    try:
        parsed = json.loads(_decode_text(data, label))
    except json.JSONDecodeError as error:
        raise CatalogError(f"{label} is not JSON: {error}") from error
    if not isinstance(parsed, dict) or parsed.get("success") is not True:
        raise CatalogError(f"{label} did not return success")
    return parsed


def build_manifest(
    *,
    catalog: bytes,
    statistics: Mapping[str, int],
    retrieved_at: str,
    pin_11163: Mapping[str, object],
    pin_6032: Mapping[str, object],
) -> dict[str, object]:
    return {
        "schema_version": 1,
        "dataset": "Taiwan MOEA Energy Administration vehicle identity",
        "license": {
            "name": "政府資料開放授權條款第1版",
            "url": LICENSE_URL,
        },
        "source": {
            "retrieved_at_utc": retrieved_at,
            "guide_11163": pin_11163,
            "identity_6032": pin_6032,
        },
        "coverage": {
            "market": "Taiwan",
            "vehicle_scope": (
                "Passenger-car energy-consumption certification rows from "
                "dataset 6032 monthly CSVs; 11163 is the annual guide PDF pin"
            ),
            "year_policy": (
                "issue_year_ce is the certification calendar year "
                "(ROC year + 1911), not a U.S. model year"
            ),
            "does_not_assert": [
                "global make/model completeness",
                "U.S. EPA namesake identity",
                "curb mass",
                "mass in running order",
                "test mass",
                "wheel horsepower",
                "drivetrain efficiency",
                "drag coefficient",
                "frontal area",
                "volumetric efficiency",
            ],
        },
        "output": {
            "file": CATALOG_FILENAME,
            "sha256": sha256_bytes(catalog),
            "size_bytes": len(catalog),
            "columns": list(OUTPUT_COLUMNS),
            **statistics,
        },
    }


def manifest_bytes(manifest: Mapping[str, object]) -> bytes:
    return (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode("utf-8")


def write_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as output:
            temporary_path = Path(output.name)
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary_path, 0o644)
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def comparable_manifest(manifest: Mapping[str, object]) -> dict[str, object]:
    comparable = json.loads(json.dumps(manifest))
    source = comparable.get("source")
    if isinstance(source, dict):
        source.pop("retrieved_at_utc", None)
    return comparable


def check_outputs(
    output_dir: Path,
    expected_catalog: bytes,
    expected_manifest: Mapping[str, object],
) -> bool:
    catalog_path = output_dir / CATALOG_FILENAME
    manifest_path = output_dir / MANIFEST_FILENAME
    errors: list[str] = []
    try:
        actual_catalog = catalog_path.read_bytes()
    except OSError as error:
        errors.append(f"cannot read {catalog_path}: {error}")
    else:
        if actual_catalog != expected_catalog:
            errors.append(f"{catalog_path} differs from the current official source")
    try:
        actual_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"cannot read {manifest_path}: {error}")
    else:
        if comparable_manifest(actual_manifest) != comparable_manifest(expected_manifest):
            errors.append(
                f"{manifest_path} differs from the current official source "
                "(retrieved_at_utc ignored)"
            )
    for error in errors:
        print(f"ERROR: {error}")
    return not errors


def pin_dataset(
    *,
    download_fn: DownloadFn,
    api_url: str,
    landing: str,
    dataset_id: int,
    expect_pdf: bool,
) -> dict[str, object]:
    metadata_bytes, _ = download_fn(api_url)
    metadata = load_json(metadata_bytes, f"dataset {dataset_id} api")
    index_url = dataset_download_url(metadata, dataset_id)
    index_bytes, _ = download_fn(index_url)
    index_row = parse_index_csv(index_bytes, label=f"dataset {dataset_id} index")
    artifact_bytes, artifact_headers = download_fn(index_row["file_url"])
    content_type = artifact_headers.get("content-type", "")
    if expect_pdf:
        if not artifact_bytes.startswith(b"%PDF"):
            raise CatalogError(
                f"dataset {dataset_id} FileUrl is not a PDF "
                f"(content-type={content_type!r})"
            )
    elif not zipfile.is_zipfile(io.BytesIO(artifact_bytes)):
        raise CatalogError(f"dataset {dataset_id} FileUrl is not a zip archive")
    return {
        "dataset_id": dataset_id,
        "landing_page": landing,
        "api_url": api_url,
        "index_url": index_url,
        "index_sha256": sha256_bytes(index_bytes),
        "index_size_bytes": len(index_bytes),
        "file_name": index_row["file_name"],
        "file_url": index_row["file_url"],
        "create_date": index_row["create_date"],
        "agency": index_row["agency"],
        "artifact_sha256": sha256_bytes(artifact_bytes),
        "artifact_size_bytes": len(artifact_bytes),
        "artifact_content_type": content_type,
        "artifact_bytes": artifact_bytes,
    }


def build_catalog(
    download_fn: DownloadFn,
    retrieved_at: str,
) -> tuple[bytes, dict[str, object]]:
    pin_11163 = pin_dataset(
        download_fn=download_fn,
        api_url=DATASET_API_11163,
        landing=LANDING_11163,
        dataset_id=11163,
        expect_pdf=True,
    )
    pin_6032 = pin_dataset(
        download_fn=download_fn,
        api_url=DATASET_API_6032,
        landing=LANDING_6032,
        dataset_id=6032,
        expect_pdf=False,
    )
    catalog, statistics, _members = parse_6032_zip(pin_6032["artifact_bytes"])  # type: ignore[arg-type]
    public_11163 = {key: value for key, value in pin_11163.items() if key != "artifact_bytes"}
    public_6032 = {key: value for key, value in pin_6032.items() if key != "artifact_bytes"}
    manifest = build_manifest(
        catalog=catalog,
        statistics=statistics,
        retrieved_at=retrieved_at,
        pin_11163=public_11163,
        pin_6032=public_6032,
    )
    return catalog, manifest


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    retrieved_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    try:
        catalog, manifest = build_catalog(download, retrieved_at)
    except CatalogError as error:
        print(f"ERROR: {error}")
        return 1

    output_dir = args.output_dir.resolve()
    if args.check:
        if not check_outputs(output_dir, catalog, manifest):
            return 1
        print("Catalog is reproducible and current (retrieved_at_utc ignored).")
    else:
        write_atomic(output_dir / CATALOG_FILENAME, catalog)
        write_atomic(output_dir / MANIFEST_FILENAME, manifest_bytes(manifest))
        print(f"Wrote {output_dir / CATALOG_FILENAME}")
        print(f"Wrote {output_dir / MANIFEST_FILENAME}")

    output = manifest["output"]
    assert isinstance(output, dict)
    print(
        "rows={rows} unique_makes={makes} years={year_min}-{year_max} "
        "catalog_bytes={catalog_bytes}".format(
            rows=output["row_count"],
            makes=output["unique_make_count"],
            year_min=output["year_min"],
            year_max=output["year_max"],
            catalog_bytes=output["size_bytes"],
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
