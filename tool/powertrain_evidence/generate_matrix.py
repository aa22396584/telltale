#!/usr/bin/env python3
"""Regenerate the catalog-derived section of the powertrain evidence matrix.

Reads the bundled catalog + manifest and hand-authored ``research/rows.json``,
then writes ``matrix.json`` with sorted keys, LF, UTF-8, and a trailing newline.

The catalog-derived section is never hand-edited. Research rows are copied
from ``research/rows.json`` (sorted by id).

Usage (PowerShell and POSIX):

    python tool/powertrain_evidence/generate_matrix.py
    python tool/powertrain_evidence/generate_matrix.py --check
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from schema import (
    REPO_ROOT,
    build_matrix,
    dump_canonical,
    load_manifest,
    load_research_rows,
)


def resolve_paths(repo_root: Path | None) -> tuple[Path, Path, Path, Path]:
    root = repo_root if repo_root is not None else REPO_ROOT
    catalog = root / "assets" / "powertrain_battery" / "powertrain_battery_catalog.json"
    manifest = catalog.with_name("powertrain_battery_catalog.manifest.json")
    tool = root / "tool" / "powertrain_evidence"
    return catalog, manifest, tool / "matrix.json", tool / "research" / "rows.json"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="repository root (defaults to the checkout that contains this tool)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if matrix.json would change; do not write",
    )
    args = parser.parse_args(argv)

    catalog_path, manifest_path, matrix_path, research_path = resolve_paths(
        args.repo_root
    )
    catalog_bytes = catalog_path.read_bytes()
    manifest = load_manifest(manifest_path)
    research_rows = load_research_rows(research_path)
    matrix = build_matrix(catalog_bytes, manifest, research_rows)
    rendered_bytes = dump_canonical(matrix).encode("utf-8")

    if args.check:
        current = matrix_path.read_bytes() if matrix_path.exists() else b""
        if current != rendered_bytes:
            sys.stderr.write(
                "matrix.json is stale; run "
                "python tool/powertrain_evidence/generate_matrix.py\n"
            )
            return 1
        print("matrix.json matches catalog + research/rows.json")
        return 0

    matrix_path.parent.mkdir(parents=True, exist_ok=True)
    matrix_path.write_bytes(rendered_bytes)
    print(
        f"wrote {matrix_path.as_posix()}: "
        f"{matrix['catalog']['profile_count']} catalog profiles, "
        f"{len(matrix['research'])} research rows, "
        f"catalog sha256 {matrix['catalog']['catalog_sha256'][:12]}…"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
