#!/usr/bin/env python3
"""Update the offline Canada NRCan vehicle identity catalog.

Official Fuel Consumption Ratings resources keep ICE, BEV, and PHEV in
separate files. This updater copies identity descriptors only and never
collapses those classes because display names match. Consumption, range,
CO2, and motor power are not VehicleProfile physics.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Mapping, Sequence
import urllib.request


USER_AGENT = "TelltaleVehicleCatalogUpdater/1.0 (+https://github.com/ImL1s/telltale)"
DOWNLOAD_TIMEOUT_SECONDS = 120
DATASET_PAGE = (
    "https://open.canada.ca/data/en/dataset/98f1a129-f628-4ce4-b24d-6f16bf24dd64"
)
LICENCE_URL = "https://open.canada.ca/en/open-government-licence-canada"
LICENCE_NAME = "Open Government Licence - Canada"

SCRIPT_DIR = Path(__file__).resolve().parent
APP_DIR = SCRIPT_DIR.parent
DEFAULT_OUTPUT_DIR = APP_DIR / "assets" / "vehicle_catalog"
CATALOG_FILENAME = "ca_nrcan_vehicles.csv"
MANIFEST_FILENAME = "ca_nrcan_vehicles.manifest.json"

ICE_HEADER = (
    "Model year",
    "Make",
    "Model",
    "Vehicle class",
    "Engine size (L)",
    "Cylinders",
    "Transmission",
    "Fuel type",
    "City (L/100 km)",
    "Highway (L/100 km)",
    "Combined (L/100 km)",
    "Combined (mpg)",
    "CO2 emissions (g/km)",
    "CO2 rating",
    "Smog rating",
)
BEV_HEADER = (
    "Model year",
    "Make",
    "Model",
    "Vehicle class",
    "Motor (kW)",
    "Transmission",
    "Fuel type",
    "City (kWh/100 km)",
    "Highway (kWh/100 km)",
    "Combined (kWh/100 km)",
    "City (Le/100 km)",
    "Highway (Le/100 km)",
    "Combined (Le/100 km)",
    "Range (km)",
    "CO2 emissions (g/km)",
    "CO2 rating ",
    "Smog rating",
    "Recharge time (h)",
)
PHEV_HEADER = (
    "Model year",
    "Make",
    "Model",
    "Vehicle class",
    "Motor (kW)",
    "Engine size (L)",
    "Cylinders",
    "Transmission",
    "Fuel type 1",
    "Combined Le/100 km",
    "Range 1 (km)",
    "Recharge time (h)",
    "Fuel type 2",
    "City (L/100 km)",
    "Highway (L/100 km)",
    "Combined (L/100 km)",
    "Range 2 (km)",
    "CO2 emissions (g/km)",
    "CO2 rating",
    "Smog rating",
)

OUTPUT_COLUMNS = (
    "ca_id",
    "market",
    "resource_class",
    "model_year",
    "make",
    "model",
    "vehicle_class",
    "engine_size_l",
    "cylinders",
    "transmission",
    "fuel_type",
    "motor_kw",
    "source_file",
)

# 1995–2014 5-cycle files are NRCan-generated approximations, not vehicle
# tests. They are not a Stage B identity source.
RESOURCES = (
    {
        "id": "ice_2026",
        "resource_class": "ice",
        "encoding": "utf-8-sig",
        "header": ICE_HEADER,
        "url": (
            "https://open.canada.ca/data/dataset/"
            "98f1a129-f628-4ce4-b24d-6f16bf24dd64/resource/"
            "9df1b18d-d036-4783-a61c-99f1f75b3ac5/download/"
            "my2026-fuel-consumption-ratings.csv"
        ),
        "file_name": "my2026-fuel-consumption-ratings.csv",
    },
    {
        "id": "ice_2025",
        "resource_class": "ice",
        "encoding": "cp1252",
        "header": ICE_HEADER,
        "url": (
            "https://open.canada.ca/data/dataset/"
            "98f1a129-f628-4ce4-b24d-6f16bf24dd64/resource/"
            "d589f2bc-9a85-4f65-be2f-20f17debfcb1/download/"
            "my2025-fuel-consumption-ratings.csv"
        ),
        "file_name": "my2025-fuel-consumption-ratings.csv",
    },
    {
        "id": "ice_2015_2024",
        "resource_class": "ice",
        "encoding": "utf-8-sig",
        "header": ICE_HEADER,
        "url": (
            "https://open.canada.ca/data/dataset/"
            "98f1a129-f628-4ce4-b24d-6f16bf24dd64/resource/"
            "c98b9dc8-b23f-4cd8-8b19-e892da1e4688/download/"
            "my2015-2024-fuel-consumption-ratings.csv"
        ),
        "file_name": "my2015-2024-fuel-consumption-ratings.csv",
    },
    {
        "id": "bev",
        "resource_class": "bev",
        "encoding": "utf-8-sig",
        "header": BEV_HEADER,
        "url": (
            "https://open.canada.ca/data/dataset/"
            "98f1a129-f628-4ce4-b24d-6f16bf24dd64/resource/"
            "026e45b4-eb63-451f-b34f-d9308ea3a3d9/download/"
            "my2012-2026-battery-electric-vehicles.csv"
        ),
        "file_name": "my2012-2026-battery-electric-vehicles.csv",
    },
    {
        "id": "phev",
        "resource_class": "phev",
        "encoding": "utf-8-sig",
        "header": PHEV_HEADER,
        "url": (
            "https://open.canada.ca/data/dataset/"
            "98f1a129-f628-4ce4-b24d-6f16bf24dd64/resource/"
            "8812228b-a6aa-4303-b3d0-66489225120d/download/"
            "my2012-2026-plug-in-hybrid-electric-vehicles.csv"
        ),
        "file_name": "my2012-2026-plug-in-hybrid-electric-vehicles.csv",
    },
)


class CatalogError(RuntimeError):
    """Raised when an official resource cannot be safely normalized."""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def download(url: str) -> tuple[bytes, Mapping[str, str]]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "text/csv, text/plain;q=0.9, */*;q=0.1",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(
            request,
            timeout=DOWNLOAD_TIMEOUT_SECONDS,
        ) as response:
            payload = response.read()
            headers = {key.lower(): value for key, value in response.headers.items()}
    except OSError as error:
        raise CatalogError(f"download failed for {url}: {error}") from error
    if not payload:
        raise CatalogError(f"download returned empty body for {url}")
    return payload, headers


def decode_source(payload: bytes, encoding: str) -> str:
    try:
        return payload.decode(encoding)
    except UnicodeDecodeError as error:
        raise CatalogError(
            f"official file is not {encoding}: {error}"
        ) from error


def parse_rows(text: str, expected_header: Sequence[str], source_file: str) -> list[dict[str, str]]:
    reader = csv.reader(io.StringIO(text))
    try:
        header = next(reader)
    except StopIteration as error:
        raise CatalogError(f"{source_file} is empty") from error
    if tuple(header) != tuple(expected_header):
        raise CatalogError(
            f"{source_file} header mismatch: {header!r} != {list(expected_header)!r}"
        )
    rows = []
    for index, cells in enumerate(reader, start=2):
        if not cells or all(not cell.strip() for cell in cells):
            continue
        if len(cells) != len(expected_header):
            raise CatalogError(
                f"{source_file} line {index} has {len(cells)} columns; "
                f"expected {len(expected_header)}"
            )
        rows.append({name: cells[i].strip() for i, name in enumerate(expected_header)})
    if not rows:
        raise CatalogError(f"{source_file} has a header and no data rows")
    return rows


def _identity_id(parts: Sequence[str]) -> str:
    payload = "\0".join(parts).encode("utf-8")
    return sha256_bytes(payload)[:16]


def _require_identity(row: Mapping[str, str], source_file: str, field: str) -> str:
    value = row[field]
    if not value:
        raise CatalogError(f"{source_file} has an empty {field}")
    return value


def _year(row: Mapping[str, str], source_file: str) -> str:
    raw = _require_identity(row, source_file, "Model year")
    try:
        year = int(raw)
    except ValueError as error:
        raise CatalogError(f"{source_file} has a non-integer model year {raw!r}") from error
    if year < 2012 or year > 2100:
        raise CatalogError(f"{source_file} has an out-of-range model year {year}")
    return str(year)


def identity_row(
    source_row: Mapping[str, str],
    *,
    resource_class: str,
    source_file: str,
) -> dict[str, str]:
    year = _year(source_row, source_file)
    make = _require_identity(source_row, source_file, "Make")
    model = _require_identity(source_row, source_file, "Model")
    vehicle_class = _require_identity(source_row, source_file, "Vehicle class")
    transmission = _require_identity(source_row, source_file, "Transmission")
    if resource_class == "ice":
        engine = source_row["Engine size (L)"]
        cylinders = source_row["Cylinders"]
        fuel = _require_identity(source_row, source_file, "Fuel type")
        motor = ""
    elif resource_class == "bev":
        engine = ""
        cylinders = ""
        fuel = _require_identity(source_row, source_file, "Fuel type")
        motor = source_row["Motor (kW)"]
    elif resource_class == "phev":
        engine = source_row["Engine size (L)"]
        cylinders = source_row["Cylinders"]
        fuel_one = _require_identity(source_row, source_file, "Fuel type 1")
        fuel_two = source_row["Fuel type 2"]
        fuel = fuel_one if not fuel_two else f"{fuel_one}|{fuel_two}"
        motor = source_row["Motor (kW)"]
    else:
        raise CatalogError(f"unknown resource_class {resource_class}")

    ca_id = _identity_id(
        (
            resource_class,
            year,
            make,
            model,
            vehicle_class,
            engine,
            cylinders,
            transmission,
            fuel,
            motor,
        )
    )
    return {
        "ca_id": ca_id,
        "market": "CA",
        "resource_class": resource_class,
        "model_year": year,
        "make": make,
        "model": model,
        "vehicle_class": vehicle_class,
        "engine_size_l": engine,
        "cylinders": cylinders,
        "transmission": transmission,
        "fuel_type": fuel,
        "motor_kw": motor,
        "source_file": source_file,
    }


def normalized_catalog(
    sources: Sequence[tuple[Mapping[str, object], str]],
) -> tuple[bytes, dict[str, int]]:
    identities: list[dict[str, str]] = []
    seen: set[str] = set()
    for resource, text in sources:
        rows = parse_rows(
            text,
            resource["header"],  # type: ignore[arg-type]
            resource["file_name"],  # type: ignore[arg-type]
        )
        for source_row in rows:
            row = identity_row(
                source_row,
                resource_class=str(resource["resource_class"]),
                source_file=str(resource["file_name"]),
            )
            if row["ca_id"] in seen:
                raise CatalogError(f"duplicate ca_id {row['ca_id']}")
            seen.add(row["ca_id"])
            identities.append(row)
    identities.sort(
        key=lambda row: (
            int(row["model_year"]),
            row["make"],
            row["model"],
            row["resource_class"],
            row["transmission"],
            row["engine_size_l"],
            row["ca_id"],
        )
    )
    output = io.StringIO(newline="")
    writer = csv.DictWriter(
        output,
        fieldnames=OUTPUT_COLUMNS,
        lineterminator="\n",
        extrasaction="raise",
    )
    writer.writeheader()
    writer.writerows(identities)
    catalog = output.getvalue().encode("utf-8")
    if not catalog.endswith(b"\n"):
        catalog += b"\n"
    years = [int(row["model_year"]) for row in identities]
    makes = {row["make"] for row in identities}
    return catalog, {
        "row_count": len(identities),
        "unique_make_count": len(makes),
        "year_min": min(years),
        "year_max": max(years),
        "ice_count": sum(1 for row in identities if row["resource_class"] == "ice"),
        "bev_count": sum(1 for row in identities if row["resource_class"] == "bev"),
        "phev_count": sum(1 for row in identities if row["resource_class"] == "phev"),
    }


def build_manifest(
    *,
    sources: Sequence[Mapping[str, object]],
    catalog: bytes,
    statistics: Mapping[str, int],
    retrieved_at_utc: str,
) -> dict[str, object]:
    return {
        "schema_version": 1,
        "dataset": "Canada NRCan Fuel Consumption Ratings vehicle identity",
        "license": {
            "name": LICENCE_NAME,
            "url": LICENCE_URL,
        },
        "coverage": {
            "market": "Canada",
            "vehicle_scope": (
                "Light-duty vehicles for retail sale in Canada from the official "
                "English Fuel Consumption Ratings CSVs. ICE, BEV, and PHEV stay "
                "separate resource classes. 1995–2014 5-cycle approximations are "
                "excluded because NRCan states they were not vehicle-tested."
            ),
            "does_not_assert": [
                "global make/model completeness",
                "U.S. EPA namesake identity",
                "Taiwan MOEA certification identity",
                "curb mass",
                "wheel horsepower",
                "motor kW as wheel horsepower",
                "fuel consumption as a VehicleProfile field",
                "range",
                "CO2",
                "drivetrain efficiency",
            ],
            "year_policy": (
                "model_year is the NRCan model year in the official CSV, not a "
                "U.S. EPA configuration and not a Taiwan certification year"
            ),
        },
        "source": {
            "landing_page": DATASET_PAGE,
            "retrieved_at_utc": retrieved_at_utc,
            "resources": [
                {
                    "id": item["id"],
                    "resource_class": item["resource_class"],
                    "file_name": item["file_name"],
                    "url": item["url"],
                    "encoding": item["encoding"],
                    "sha256": item["sha256"],
                    "size_bytes": item["size_bytes"],
                }
                for item in sources
            ],
        },
        "output": {
            "file": CATALOG_FILENAME,
            "columns": list(OUTPUT_COLUMNS),
            "row_count": statistics["row_count"],
            "sha256": sha256_bytes(catalog),
            "size_bytes": len(catalog),
            "unique_make_count": statistics["unique_make_count"],
            "year_min": statistics["year_min"],
            "year_max": statistics["year_max"],
            "ice_count": statistics["ice_count"],
            "bev_count": statistics["bev_count"],
            "phev_count": statistics["phev_count"],
        },
    }


def _manifest_for_compare(manifest: Mapping[str, object]) -> dict[str, object]:
    cloned = json.loads(json.dumps(manifest))
    cloned["source"]["retrieved_at_utc"] = ""
    return cloned


def write_outputs(
    output_dir: Path,
    catalog: bytes,
    manifest: Mapping[str, object],
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / CATALOG_FILENAME).write_bytes(catalog)
    (output_dir / MANIFEST_FILENAME).write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def fetch_and_build(
    resources: Sequence[Mapping[str, object]] | None = None,
) -> tuple[bytes, dict[str, object], dict[str, int]]:
    selected = list(resources or RESOURCES)
    decoded: list[tuple[Mapping[str, object], str]] = []
    recorded: list[dict[str, object]] = []
    for resource in selected:
        payload, _headers = download(str(resource["url"]))
        text = decode_source(payload, str(resource["encoding"]))
        recorded.append(
            {
                **resource,
                "sha256": sha256_bytes(payload),
                "size_bytes": len(payload),
            }
        )
        decoded.append((resource, text))
    catalog, statistics = normalized_catalog(decoded)
    retrieved = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    manifest = build_manifest(
        sources=recorded,
        catalog=catalog,
        statistics=statistics,
        retrieved_at_utc=retrieved,
    )
    return catalog, manifest, statistics


def check_existing(output_dir: Path) -> None:
    catalog_path = output_dir / CATALOG_FILENAME
    manifest_path = output_dir / MANIFEST_FILENAME
    if not catalog_path.is_file() or not manifest_path.is_file():
        raise CatalogError("bundled Canada catalog or manifest is missing")
    existing_catalog = catalog_path.read_bytes()
    existing_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    catalog, manifest, statistics = fetch_and_build()
    if catalog != existing_catalog:
        raise CatalogError(
            "Canada catalog is not reproducible from the official English CSVs"
        )
    if _manifest_for_compare(manifest) != _manifest_for_compare(existing_manifest):
        raise CatalogError(
            "Canada catalog manifest is not current (retrieved_at_utc ignored)"
        )
    print(
        "Catalog is reproducible and current (retrieved_at_utc ignored)."
    )
    print(
        "rows={row_count} unique_makes={unique_make_count} "
        "years={year_min}-{year_max} catalog_bytes={size} "
        "ice={ice_count} bev={bev_count} phev={phev_count}".format(
            size=len(existing_catalog),
            **statistics,
        )
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="directory for ca_nrcan_vehicles.csv and its manifest",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="re-download official English CSVs and compare to the bundled snapshot",
    )
    args = parser.parse_args(argv)
    try:
        if args.check:
            check_existing(args.output_dir)
            return 0
        catalog, manifest, statistics = fetch_and_build()
        write_outputs(args.output_dir, catalog, manifest)
        print(
            "Wrote {file} rows={row_count} unique_makes={unique_make_count} "
            "years={year_min}-{year_max} ice={ice_count} bev={bev_count} "
            "phev={phev_count}".format(
                file=CATALOG_FILENAME,
                **statistics,
            )
        )
        return 0
    except CatalogError as error:
        print(f"CatalogError: {error}", flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
