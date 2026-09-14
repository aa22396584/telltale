#!/usr/bin/env python3
"""Fail-closed validator for the powertrain evidence/disposition matrix.

Exit 0 only when the committed matrix's catalog-derived section matches the
catalog bytes, the catalog manifest sha256/size match those bytes, and every
research row satisfies the rules in this file.

Not imported by app runtime.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from schema import (
    AGREEING_MARKS,
    CATALOG_PRESENCE,
    DISPOSITIONS,
    KIND,
    LICENCE_DECISIONS,
    REPO_ROOT,
    SCHEMA_VERSION,
    WIRE_FIELDS,
    GITHUB_REPO,
    derive_source_family,
    dump_canonical,
    extract_catalog_section,
    extract_vehicle_evidence_locator,
    is_immutable_revision,
    is_sha256_hex,
    load_manifest,
    load_research_rows,
    sha256_hex,
    source_repo_path_key,
    source_url_key,
)

SALES_KEYS = frozenset(
    {"sales", "sales_rank", "popularity", "units_sold", "market_share"}
)
SALES_KIND_VALUES = frozenset({"sales", "popularity"})
INHERIT_KEYS = frozenset({"inherits_from", "inherit_from", "inherited_from"})
DERIVED_FAMILY_KEYS = frozenset({"derived_from", "fork_of"})
SOURCE_ROLES = frozenset({"primary", "corroborating", "secondary"})
INHERIT_LOCATOR_PREFIXES = ("row:", "research:", "research_row:", "sibling:")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
BLANK_SCOPE = frozenset({"", "unknown", "unspecified", "n/a", "na", "tbd"})
GENERIC_BRAND_PLATFORM_ALIASES = frozenset(
    {
        "byd",
        "tesla",
        "toyota",
        "nissan",
        "volkswagen",
        "vw",
        "hyundai",
        "kia",
        "renault",
        "bmw",
        "mg",
        "meb",
        "e-gmp",
        "egmp",
        "blade",
        "e-platform",
    }
)
BRAND_ALIASES: dict[str, str] = {
    "vw": "volkswagen",
    "chevy": "chevrolet",
}
GENERIC_MODEL_PREFIXES = frozenset({"model", "ioniq", "id", "ev", "atto"})
NON_MODEL_WORDS = frozenset(
    {
        "actively",
        "default",
        "periodic",
        "cyclic",
        "continuous",
        "regular",
        "standard",
        "normal",
        "fast",
        "slow",
        "can",
        "bms",
        "ecu",
        "pid",
        "pids",
        "obd",
    }
)


def normalize_brand(brand: str) -> str:
    b = brand.lower().strip().replace("-", "_")
    return BRAND_ALIASES.get(b, b)


def _norm_token(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


GENERATION_TRIM_SUFFIXES = frozenset(
    {
        "ze0",
        "ze1",
        "i01",
        "mk1",
        "mk2",
        "ph1",
        "ph2",
        "gen1",
        "gen2",
        "facelift",
    }
)

NON_MODEL_SUFFIXES = frozenset(
    {
        "meb",
        "egmp",
        "ev",
        "bev",
        "phev",
        "fcev",
        "electric",
        "electrified",
        "hybrid",
        "current",
        "gen",
        "generation",
        "facelift",
        "highland",
        "juniper",
        "pre",
        "post",
        "source",
        "vehicle",
        "community",
        "experimental",
        "research",
        "beyond",
        "shipped",
        "de",
        "os",
        "sk3",
        "ze0",
        "ze1",
        "i01",
        "au",
        "us",
        "uk",
        "eu",
        "global",
        "tnga",
        "ph1",
        "ph2",
        "mk1",
        "mk2",
        "update",
    }
)


def _normalize_repo_identity(repo: str) -> str:
    norm = repo.strip().lower()
    for prefix in (
        "https://github.com/",
        "http://github.com/",
        "ssh://git@github.com/",
        "git@github.com:",
        "github.com/",
    ):
        if norm.startswith(prefix):
            norm = norm[len(prefix):]
    norm = norm.rstrip("/")
    if norm.endswith(".git"):
        norm = norm[:-4]
    norm = norm.rstrip("/")
    return norm


def _normalize_locator_identity(locator: str) -> str:
    return " ".join(locator.strip().lower().split())


@dataclass(frozen=True)
class ReviewedEvidenceBinding:
    """Explicit, per-target reviewed evidence record.

    Target scope, signal, source repository, revision, hash, path, and locator
    must belong to the exact same reviewed record. Formal records that elevate
    evidence qualification must not use wildcards; missing or wildcard fields
    are rejected immediately.
    """

    target_scope: str
    path: str
    signal: str
    source_repository: str
    revision: str
    source_hash: str
    locator: str

    def __post_init__(self) -> None:
        for field_name in (
            "target_scope",
            "path",
            "signal",
            "source_repository",
            "revision",
            "source_hash",
            "locator",
        ):
            val = getattr(self, field_name, None)
            if not isinstance(val, str) or not val.strip():
                raise ValueError(
                    f"ReviewedEvidenceBinding {field_name} must be a non-empty string; got {val!r}"
                )
            if val.strip() == "*":
                raise ValueError(
                    f"ReviewedEvidenceBinding {field_name} must not be wildcard '*'; got {val!r}"
                )
            if field_name != "locator" and "*" in val:
                raise ValueError(
                    f"ReviewedEvidenceBinding {field_name} must not contain wildcards; got {val!r}"
                )


REVIEWED_EVIDENCE_BINDINGS: list[ReviewedEvidenceBinding] = [
    # BYD Atto 3
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle_profiles/byd/byd_202410_update.json",
            signal=signal,
            source_repository="meatpiHQ/wican-fw",
            revision="bc3ae6d4ad09f32b96ca101b31950e4fbf56b825",
            source_hash="884a967ddcde195b953fe9070119561c6defde0f22866834260b3a65746c1116",
            locator="EU version, only before 2024.10 update; ATSH7E7; 220005 SOC_D=B4; 220008 HV_V=((B5*256)+B4); 220009 HV_A=(raw-5000)/10",
        )
        for target in ("byd-atto3", "byd-atto-3", "byd-atto3-2022-2024-community")
        for signal in ("battery_profile", "soc", "pack_voltage", "pack_current", "pack_temp")
    ),
    # MEB architecture profiles
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="volkswagen/meb.json",
            signal=signal,
            source_repository="iternio/ev-obd-pids",
            revision="c45a018b60b3341d2d8bfb22cf0491c4e878165a",
            source_hash="434936a9b4571b63b013a159c1b38fcffdd70651f4a3966ae6d3026d9f42b03d",
            locator=loc,
        )
        for target, loc in (
            ("cupra-born", "catalog locator cupra:born* alias"),
            ("cupra-born-meb", "catalog locator cupra:born* alias"),
            ("skoda-enyaq", "catalog locator skoda:enyaq* alias"),
            ("skoda-enyaq-meb", "catalog locator skoda:enyaq* alias"),
            ("volkswagen-id-buzz", "catalog locator volkswagen:id* alias for ID. Buzz"),
            ("volkswagen-id-buzz-meb", "catalog locator volkswagen:id* alias for ID. Buzz"),
            ("volkswagen-id3", "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"),
            ("volkswagen-id3-meb", "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"),
            ("volkswagen-id4", "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"),
            ("volkswagen-id4-meb", "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"),
            ("volkswagen-id5", "catalog locator volkswagen:id* alias for ID.5"),
            ("volkswagen-id5-meb", "catalog locator volkswagen:id* alias for ID.5"),
        )
        for signal in ("battery_profile", "soc")
    ),
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle_profiles/vw/ev_meb.json",
            signal="battery_profile",
            source_repository="meatpiHQ/wican-fw",
            revision="bc3ae6d4ad09f32b96ca101b31950e4fbf56b825",
            source_hash="7355c159c20afca957ee486dc7585e7323a57f98124bcecf5a5bc45379985108",
            locator=loc,
        )
        for target, loc in (
            ("volkswagen-id3", "car_model lists ID.3 among MEB aliases; pid_init ATSP7 ATCP17 17FC007B"),
            ("volkswagen-id3-meb", "car_model lists ID.3 among MEB aliases; pid_init ATSP7 ATCP17 17FC007B"),
            ("volkswagen-id4", "car_model lists ID.4 among MEB aliases; pid_init ATSP7 ATCP17 17FC007B"),
            ("volkswagen-id4-meb", "car_model lists ID.4 among MEB aliases; pid_init ATSP7 ATCP17 17FC007B"),
        )
    ),
    # E-GMP platform OVMS polling source (Kia EV6)
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path=path,
            signal=signal,
            source_repository="openvehicles/Open-Vehicle-Monitoring-System-3",
            revision="587a91d7b46bd7ce6d092e5acb7c2d3b7c5d7740",
            source_hash="e5ffbdadd1725cbc672249fd6c2ca4d475e8d68661abdcb0a4551d95289d89b2",
            locator="E-GMP BMS poll table and decode for 220101/220105 on 7E4/7EC",
        )
        for target in ("kia-ev6", "kia-ev6-egmp-2022-2024-community", "genesis-gv60")
        for path in (
            "vehicle/ovms.v3/components/vehicle_hyundai_ioniq5/src/hif_can_poll.cpp",
            "components/vehicle_hkmc/hif_can_poll.cpp",
        )
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "batt_temp_max",
            "batt_temp_min",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "soh",
            "soc_display",
        )
    ),
    # HKMC Niro/Soul/Kona platform OVMS polling source (Hyundai Kona)
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path=path,
            signal=signal,
            source_repository="openvehicles/Open-Vehicle-Monitoring-System-3",
            revision="587a91d7b46bd7ce6d092e5acb7c2d3b7c5d7740",
            source_hash="537242c15478e1fbd4b11d50877e28677229e7564c611a59bcf14cb64666cffb",
            locator="Kona/e-Niro BMS poll table and decode for 220101/220105 on 7E4/7EC",
        )
        for target in ("hyundai-kona", "hyundai-kona-electric-os-2019-2023-community")
        for path in (
            "vehicle/ovms.v3/components/vehicle_kianiroev/src/kn_can_poll.cpp",
            "components/vehicle_hkmc/kn_can_poll.cpp",
        )
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "batt_temp_max",
            "batt_temp_min",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "battery_inlet_temp",
            "soh",
            "soc_display",
            "cell_deterioration_min",
        )
    ),
    # Multi-model profiles (Hyundai Ioniq 6)
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle_profiles/hyundai/ioniq5-6.json",
            signal=signal,
            source_repository="meatpiHQ/wican-fw",
            revision="bc3ae6d4ad09f32b96ca101b31950e4fbf56b825",
            source_hash="7ca3dadb99590a9377c688d73b6291440d1eea942b18b3dcc3a9ab538775c507",
            locator="car_model 'Hyundai: Ioniq5/Ioniq6 (2021-2024)'; 220101/220105 windows and scales incl. signed current S17",
        )
        for target in ("hyundai-ioniq6", "hyundai-ioniq6-egmp-2022-2024-community")
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "batt_temp_max",
            "batt_temp_min",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "soh",
            "soc_display",
        )
    ),
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle/ovms.v3/components/vehicle_hyundai_ioniq5/src/hif_can_poll.cpp",
            signal=signal,
            source_repository="openvehicles/Open-Vehicle-Monitoring-System-3",
            revision="587a91d7b46bd7ce6d092e5acb7c2d3b7c5d7740",
            source_hash="e5ffbdadd1725cbc672249fd6c2ca4d475e8d68661abdcb0a4551d95289d89b2",
            locator="E-GMP BMS poll table and decode for 220101/220105 on 7E4/7EC (map corroboration; component lists Ioniq 5/EV6, not Ioniq 6)",
        )
        for target in ("hyundai-ioniq6", "hyundai-ioniq6-egmp-2022-2024-community")
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "batt_temp_max",
            "batt_temp_min",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "soh",
            "soc_display",
        )
    ),
    # Multi-model profiles (Kia Soul EV)
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle_profiles/kia/nirosoulkona-ev.json",
            signal=signal,
            source_repository="meatpiHQ/wican-fw",
            revision="bc3ae6d4ad09f32b96ca101b31950e4fbf56b825",
            source_hash="fcb59badaf765eb1eb1522c356bc31b378510d1797c3ff23c62e5b1570ea4f9e",
            locator="car_model 'Kia: Niro/Soul'; 2201019/2201057 (9/7-frame) windows and scales",
        )
        for target in ("kia-soul", "kia-soul-ev-sk3-2020-community")
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "soh",
            "soc_display",
            "cell_deterioration_min",
        )
    ),
    *(
        ReviewedEvidenceBinding(
            target_scope=target,
            path="vehicle/ovms.v3/components/vehicle_kianiroev/src/kn_can_poll.cpp",
            signal=signal,
            source_repository="openvehicles/Open-Vehicle-Monitoring-System-3",
            revision="587a91d7b46bd7ce6d092e5acb7c2d3b7c5d7740",
            source_hash="537242c15478e1fbd4b11d50877e28677229e7564c611a59bcf14cb64666cffb",
            locator="byte-identical Kona/e-Niro OS map corroboration (component docs list e-Niro/Kona/Ioniq FL, not e-Soul; map-level evidence only)",
        )
        for target in ("kia-soul", "kia-soul-ev-sk3-2020-community")
        for signal in (
            "battery_profile",
            "soc_bms",
            "pack_current",
            "pack_voltage",
            "cell_volt_max",
            "cell_volt_max_no",
            "cell_volt_min",
            "cell_volt_min_no",
            "aux_batt_voltage",
            "cum_charge_ah",
            "cum_discharge_ah",
            "cum_energy_charged",
            "cum_energy_discharged",
            "soh",
            "soc_display",
            "cell_deterioration_min",
        )
    ),
]


def _normalize_binding_path(path: str) -> str:
    norm = path.replace("\\", "/").strip().lstrip("/")
    while norm.startswith("./"):
        norm = norm[2:].lstrip("/")
    return norm.lower()


def _target_scope_matches(target_id: str, binding_scope: str) -> bool:
    clean_target = _norm_token(target_id)
    clean_scope = _norm_token(binding_scope)
    if clean_target == clean_scope:
        return True
    parts = [p for p in re.split(r"[^a-z0-9]+", target_id.lower()) if p]
    model_parts = [
        p
        for p in parts
        if p not in NON_MODEL_SUFFIXES and not (p.isdigit() and len(p) == 4)
    ]
    if _norm_token("".join(model_parts)) == clean_scope:
        return True
    return False


def _find_reviewed_evidence_binding(
    target_id: str,
    path: str,
    *,
    locator: str,
    signal: str,
    repository: str,
    revision: str,
    source_hash: str,
) -> ReviewedEvidenceBinding | None:
    if (
        not target_id
        or not target_id.strip()
        or "*" in target_id
        or not path
        or not path.strip()
        or "*" in path
        or not signal
        or not signal.strip()
        or "*" in signal
        or not repository
        or not repository.strip()
        or "*" in repository
        or not revision
        or not revision.strip()
        or "*" in revision
        or not source_hash
        or not source_hash.strip()
        or "*" in source_hash
        or not locator
        or not locator.strip()
        or locator.strip() == "*"
    ):
        return None

    norm_path = _normalize_binding_path(path)
    norm_repo = _normalize_repo_identity(repository)
    norm_loc = _normalize_locator_identity(locator)
    clean_signal = signal.strip().lower()
    clean_rev = revision.strip().lower()
    clean_hash = source_hash.strip().lower()

    for binding in REVIEWED_EVIDENCE_BINDINGS:
        if _normalize_binding_path(binding.path) != norm_path:
            continue
        if not _target_scope_matches(target_id, binding.target_scope):
            continue
        if binding.signal.strip().lower() != clean_signal:
            continue
        if _normalize_repo_identity(binding.source_repository) != norm_repo:
            continue
        if binding.revision.strip().lower() != clean_rev:
            continue
        if binding.source_hash.strip().lower() != clean_hash:
            continue
        if _normalize_locator_identity(binding.locator) != norm_loc:
            continue
        return binding
    return None


def _has_reviewed_shared_binding(
    target_id: str,
    path_clean: str,
    *,
    locator: str,
    signal: str,
    repository: str,
    revision: str,
    source_hash: str,
) -> bool:
    return (
        _find_reviewed_evidence_binding(
            target_id=target_id,
            path=path_clean,
            locator=locator,
            signal=signal,
            repository=repository,
            revision=revision,
            source_hash=source_hash,
        )
        is not None
    )


def _resolve_target_models(
    target_id: str,
    target_make: str,
    aliases: list[str] | None = None,
) -> set[str]:
    target_parts = [p for p in re.split(r"[^a-z0-9]+", target_id.lower()) if p]
    model_parts = [
        p
        for p in target_parts[1:]
        if p not in NON_MODEL_SUFFIXES and (not p.isdigit() or len(p) <= 2)
    ]
    models = set()
    if model_parts:
        clean = _norm_token("".join(model_parts))
        if clean:
            models.add(clean)

    # Aliases are search/display metadata and MUST NOT override or add conflicting models
    # when the target_id already resolves a distinct model.
    # Only if target_id has no model parts (e.g. generic nameplates like 'renault-current-ev'),
    # aliases can provide the base model.
    if not models and aliases:
        for alias in aliases:
            if not isinstance(alias, str):
                continue
            a_parts = [p for p in re.split(r"[^a-z0-9]+", alias.lower()) if p]
            a_model_parts = [
                p
                for p in a_parts
                if p != target_make
                and p not in NON_MODEL_SUFFIXES
                and (not p.isdigit() or len(p) <= 2)
            ]
            if a_model_parts:
                clean = _norm_token("".join(a_model_parts))
                if clean:
                    models.add(clean)
            has_gen2 = any(
                g in alias.lower()
                for g in ("ph2", "gen2", "gen 2", "ph 2", "ze50")
            )
            if has_gen2:
                for base in list(models):
                    models.add(f"{base}2")
    return models


def _is_cross_model_source(
    target_id: str,
    locator: str,
    path: str,
    url: str,
    *,
    aliases: list[str] | None = None,
    signal: str = "",
    signals: Sequence[str] | None = None,
    repository: str = "",
    revision: str = "",
    source_hash: str = "",
) -> bool:
    target_parts = [p for p in re.split(r"[^a-z0-9]+", target_id.lower()) if p]
    if not target_parts:
        return False

    target_make = normalize_brand(target_parts[0])
    target_models = _resolve_target_models(target_id, target_make, aliases)
    path_clean = path.lower().replace("\\", "/")

    # 1. Check foreign locator specification (e.g. '<Model> polls')
    m_poll = re.search(r"\b([a-z0-9_-]+(?:\s+[a-z0-9_-]+)?)\s+polls\b", locator.lower())
    if m_poll:
        poll_veh = _norm_token(m_poll.group(1))
        if poll_veh not in NON_MODEL_WORDS:
            if target_models and not any(
                poll_veh == m or poll_veh in m or m in poll_veh for m in target_models
            ):
                return True

    # 2. Check structured reviewed shared-source binding
    candidate_signals: list[str] = []
    if signals:
        candidate_signals.extend(s for s in signals if isinstance(s, str) and s.strip())
    if signal and signal.strip() and signal not in candidate_signals:
        candidate_signals.append(signal.strip())
    if not candidate_signals:
        candidate_signals.append("battery_profile")

    for sig in candidate_signals:
        if _has_reviewed_shared_binding(
            target_id,
            path_clean,
            locator=locator,
            signal=sig,
            repository=repository,
            revision=revision,
            source_hash=source_hash,
        ):
            return False

    # 3. OVMS component paths
    m_ovms = re.search(r"components/vehicle_([a-z0-9_]+)(?:/|$)", path_clean)
    if m_ovms:
        comp_raw = m_ovms.group(1)
        # Check C++ source file if vehicle-specific: vehicle_<name>.cpp
        m_cpp = re.search(r"vehicle_([a-z0-9_]+)\.cpp", path_clean)
        if m_cpp:
            cpp_raw = m_cpp.group(1)
            cpp_clean = _norm_token(cpp_raw)
            cpp_cmp = cpp_clean
            if cpp_cmp.startswith(target_make):
                cpp_cmp = cpp_cmp[len(target_make):]

            if cpp_cmp:
                matches_cpp = (
                    cpp_cmp in target_models
                    or any(
                        cpp_cmp.startswith(m) or m.startswith(cpp_cmp)
                        for m in target_models
                    )
                    or any(cpp_clean.startswith(m) for m in target_models)
                )
                if not matches_cpp:
                    return True

        # Check component brand / sharing
        if comp_raw.startswith("vw"):
            comp_make = "volkswagen"
        elif "_" in comp_raw:
            parts = comp_raw.split("_", 1)
            comp_make = normalize_brand(parts[0])
        elif comp_raw.startswith(target_make):
            comp_make = target_make
        else:
            comp_make = comp_raw

        if comp_make != target_make:
            return True

    # 4. Dedicated vehicle JSON file path
    m = re.search(
        r"(?:vehicle_profiles/|^)([a-z0-9_-]+)/([a-z0-9_.-]+)\.json$", path_clean
    )
    if m:
        dir_name = m.group(1)
        generic_dirs = {
            "shared",
            "common",
            "signalsets",
            "app",
            "components",
            "src",
            "docs",
            "tests",
            "data",
            "fixtures",
            "builtin",
        }
        if dir_name not in generic_dirs and not any(g in path_clean for g in generic_dirs):
            src_make = normalize_brand(dir_name)
            src_file_raw = m.group(2)
            src_file_clean = _norm_token(src_file_raw)

            # Rule A: Make must match
            if src_make != target_make:
                return True

            # Rule B: Model must match
            # Check multi-model files (e.g. ioniq5-6, mg5-marvel-zs)
            is_multi_model = (
                "5-6" in src_file_raw
                or "5_6" in src_file_raw
                or "marvel" in src_file_raw
            )
            if is_multi_model:
                sub_tokens = [
                    _norm_token(t)
                    for t in re.split(r"[-_]+", src_file_raw)
                    if t and t != src_make and t not in NON_MODEL_SUFFIXES
                ]
                if any(
                    m in sub_tokens
                    or any(t.startswith(m) or m.startswith(t) for t in sub_tokens)
                    for m in target_models
                ):
                    return False

            # Single-model file matching
            src_model_cmp = src_file_clean
            if src_model_cmp.startswith(src_make):
                src_model_cmp = src_model_cmp[len(src_make):]

            # Stripped of non-model suffixes (e.g. niro-ev -> niro)
            src_tokens_clean = "".join(
                _norm_token(t)
                for t in re.split(r"[-_]+", src_file_raw)
                if t and t != src_make and t not in NON_MODEL_SUFFIXES
            )

            # Exact match with any target model candidate
            if any(
                src_model_cmp == m
                or src_file_clean == m
                or src_tokens_clean == m
                for m in target_models
            ):
                return False

            # Check generation / trim suffix
            matched_gen = False
            for m in target_models:
                if src_model_cmp.startswith(m):
                    suffix = src_model_cmp[len(m):]
                    if suffix in GENERATION_TRIM_SUFFIXES or suffix in NON_MODEL_SUFFIXES:
                        matched_gen = True
                        break
                if m.startswith(src_model_cmp):
                    suffix = m[len(src_model_cmp):]
                    if suffix in GENERATION_TRIM_SUFFIXES or suffix in NON_MODEL_SUFFIXES:
                        matched_gen = True
                        break
            if matched_gen:
                return False

            return True

    return False
SIGNEDNESS = frozenset({"unsigned", "signed"})
HEX_SERVICE = re.compile(r"^[0-9A-Fa-f]{2}$")
HEX_DID = re.compile(r"^[0-9A-Fa-f]{2,4}$")
CAN_ID_11 = re.compile(r"^[0-7][0-9A-F]{2}$")
CAN_ID_29 = re.compile(r"^[0-9A-F]{8}$")
FORMULA_NUMBER = re.compile(r"^\d+(?:\.\d+)?$")
FORMULA_LETTER = re.compile(r"^[A-N]$")
FORMULA_FUNCS = frozenset(
    {
        "ABS",
        "BIT",
        "CLOSEST",
        "COS",
        "FLOAT32",
        "FLOAT64",
        "INT",
        "INT24",
        "INT32",
        "LOG",
        "LOG10",
        "LOG1P",
        "LOOKUP",
        "MAX",
        "MIN",
        "RANDOM",
        "SIGNED",
        "SIGNED8",
        "SIGNED16",
        "SIGNED24",
        "SIGNED32",
        "SIN",
        "SQRT",
        "TAN",
    }
)
FORMULA_ARITY = {
    "ABS": (1, 1),
    "BIT": (2, 2),
    "COS": (1, 1),
    "FLOAT32": (4, 4),
    "FLOAT64": (8, 8),
    "INT": (1, 1),
    "INT24": (3, 3),
    "INT32": (4, 4),
    "LOG": (1, 1),
    "LOG10": (1, 1),
    "LOG1P": (1, 1),
    "MAX": (2, 2),
    "MIN": (2, 2),
    "RANDOM": (0, 0),
    "SIGNED": (1, 1),
    "SIGNED8": (1, 1),
    "SIGNED16": (1, 1),
    "SIGNED24": (1, 1),
    "SIGNED32": (1, 1),
    "SIN": (1, 1),
    "SQRT": (1, 1),
    "TAN": (1, 1),
}
READ_ONLY_SERVICES = frozenset({"21", "22"})
IDENTIFIER_WIDTH = {"21": 2, "22": 4}
YEAR_MIN = 1886
YEAR_MAX = 2100


def _as_dict(value: Any) -> dict[str, Any] | None:
    return value if isinstance(value, dict) else None


def _as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _text(value: Any) -> str:
    return value.strip() if isinstance(value, str) else ""


def _is_int(value: Any) -> bool:
    return type(value) is int


def _scope_missing(value: Any) -> bool:
    if not isinstance(value, str):
        return True
    return value.strip().lower() in BLANK_SCOPE


def _year_in_catalog_range(value: Any) -> bool:
    """Mirror profile_catalog_validator.dart: inclusive 1886..2100."""
    return _is_int(value) and YEAR_MIN <= value <= YEAR_MAX


def _year_missing(row: dict[str, Any]) -> bool:
    if _year_in_catalog_range(row.get("year")):
        return False
    year_from = row.get("year_from")
    year_to = row.get("year_to")
    return not (
        _year_in_catalog_range(year_from)
        and _year_in_catalog_range(year_to)
        and year_from <= year_to
    )


def _licence_decision(row: dict[str, Any]) -> str:
    block = _as_dict(row.get("licence_redistribution"))
    if block is None:
        return ""
    return _text(block.get("decision"))


def _independence_rationale(row: dict[str, Any]) -> str:
    direct = _text(row.get("independence_rationale"))
    if direct:
        return direct
    block = _as_dict(row.get("independence"))
    if block is None:
        return ""
    return _text(block.get("rationale"))


def _is_exact_can_id(value: Any) -> bool:
    """Mirror ``isExactPowertrainCanId`` in profile_wire_contract.dart."""
    if not isinstance(value, str):
        return False
    text = value.strip().upper()
    if CAN_ID_11.fullmatch(text):
        return True
    if not CAN_ID_29.fullmatch(text):
        return False
    return int(text, 16) <= 0x1FFFFFFF


def _is_hex_service(value: Any) -> bool:
    return isinstance(value, str) and bool(HEX_SERVICE.fullmatch(value.strip()))


def _is_hex_did(value: Any) -> bool:
    return isinstance(value, str) and bool(HEX_DID.fullmatch(value.strip()))


class _FormulaParseError(Exception):
    """Internal: formula text is not a complete FormulaEngine expression."""


def _formula_tokens(text: str) -> list[str]:
    tokens: list[str] = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char.isspace():
            index += 1
            continue
        if char in "+-*/%(),:~=":
            tokens.append(char)
            index += 1
            continue
        if char.isdigit() or char == ".":
            start = index
            while index < length and (text[index].isdigit() or text[index] == "."):
                index += 1
            tokens.append(text[start:index])
            continue
        if char.isalpha() or char == "_":
            start = index
            while index < length and (text[index].isalnum() or text[index] == "_"):
                index += 1
            tokens.append(text[start:index])
            continue
        raise _FormulaParseError(char)
    return tokens


def _formula_factor(tokens: list[str], pos: int, width: int) -> int:
    if pos >= len(tokens):
        raise _FormulaParseError("eof")
    token = tokens[pos]
    if token == "(":
        pos = _formula_expr(tokens, pos + 1, width)
        if pos >= len(tokens) or tokens[pos] != ")":
            raise _FormulaParseError("paren")
        return pos + 1
    if token == ")":
        raise _FormulaParseError("bare )")
    if FORMULA_LETTER.fullmatch(token.upper()):
        if ord(token.upper()) > ord("A") + width - 1:
            raise _FormulaParseError("letter")
        return pos + 1
    if FORMULA_NUMBER.fullmatch(token):
        return pos + 1
    name = token.upper()
    if name in {"LOOKUP", "CLOSEST"}:
        return _formula_lookup_call(tokens, pos, width)
    if name == "SIGNED":
        # formula_engine.dart ~367: only SIGNED([A-N]), not SIGNED(A+1) or SIGNED((A)).
        if (
            pos + 3 >= len(tokens)
            or tokens[pos + 1] != "("
            or tokens[pos + 3] != ")"
            or not FORMULA_LETTER.fullmatch(tokens[pos + 2].upper())
        ):
            raise _FormulaParseError("signed")
        if ord(tokens[pos + 2].upper()) > ord("A") + width - 1:
            raise _FormulaParseError("letter")
        return pos + 4
    if name in FORMULA_FUNCS:
        if pos + 1 >= len(tokens) or tokens[pos + 1] != "(":
            raise _FormulaParseError("call")
        pos += 2
        argc = 0
        if pos < len(tokens) and tokens[pos] != ")":
            pos = _formula_expr(tokens, pos, width)
            argc = 1
            while pos < len(tokens) and tokens[pos] in ",:":
                pos = _formula_expr(tokens, pos + 1, width)
                argc += 1
        if pos >= len(tokens) or tokens[pos] != ")":
            raise _FormulaParseError("call")
        low, high = FORMULA_ARITY[name]
        if not low <= argc <= high:
            raise _FormulaParseError("arity")
        return pos + 1
    raise _FormulaParseError(token)


def _top_level_index(tokens: list[str], symbol: str) -> int:
    depth = 0
    for index, token in enumerate(tokens):
        if token == "(":
            depth += 1
        elif token == ")":
            depth -= 1
        elif depth == 0 and token == symbol:
            return index
    return -1


def _require_complete_expr(tokens: list[str], width: int) -> None:
    if not tokens:
        raise _FormulaParseError("empty")
    end = _formula_expr(tokens, 0, width)
    if end != len(tokens):
        raise _FormulaParseError("trail")


def _formula_lookup_call(tokens: list[str], pos: int, width: int) -> int:
    """Mirror FormulaEngine LOOKUP/CLOSEST grammar (formula_engine.dart ~1375-1652).

    Wiki form is ``LOOKUP(value:default:key=val:…)`` / ``CLOSEST(...)``.
    Colon is the only argument separator; a comma form is not a LOOKUP call
    (``test/formula_engine_test.dart:1034-1037`` rejects ``LOOKUP(A:0)``;
    comma ``LOOKUP(A,0)`` is likewise not a mapping). At least three parts;
    value and every mapping pair are nonempty; default may be empty.
    """
    if pos + 1 >= len(tokens) or tokens[pos + 1] != "(":
        raise _FormulaParseError("call")
    pos += 2
    parts: list[list[str]] = []
    current: list[str] = []
    depth = 0
    while pos < len(tokens):
        token = tokens[pos]
        if token == "," and depth == 0:
            raise _FormulaParseError("lookup-comma")
        if token == "(":
            depth += 1
            current.append(token)
            pos += 1
            continue
        if token == ")":
            if depth == 0:
                parts.append(current)
                pos += 1
                break
            depth -= 1
            current.append(token)
            pos += 1
            continue
        if token == ":" and depth == 0:
            parts.append(current)
            current = []
            pos += 1
            continue
        current.append(token)
        pos += 1
    else:
        raise _FormulaParseError("call")
    if len(parts) < 3:
        raise _FormulaParseError("lookup-arity")
    if not parts[0]:
        raise _FormulaParseError("lookup-value")
    _require_complete_expr(parts[0], width)
    if parts[1]:
        _require_complete_expr(parts[1], width)
    for pair in parts[2:]:
        if not pair:
            raise _FormulaParseError("lookup-pair")
        equals = _top_level_index(pair, "=")
        if equals < 0:
            raise _FormulaParseError("lookup-pair")
        key, mapped = pair[:equals], pair[equals + 1 :]
        if not key or not mapped:
            raise _FormulaParseError("lookup-pair")
        tilde = _top_level_index(key, "~")
        if tilde < 0:
            _require_complete_expr(key, width)
        else:
            _require_complete_expr(key[:tilde], width)
            _require_complete_expr(key[tilde + 1 :], width)
        _require_complete_expr(mapped, width)
    return pos


def _formula_term(tokens: list[str], pos: int, width: int) -> int:
    pos = _formula_factor(tokens, pos, width)
    while pos < len(tokens) and tokens[pos] in "*/%":
        pos = _formula_factor(tokens, pos + 1, width)
    return pos


def _formula_expr(tokens: list[str], pos: int, width: int) -> int:
    pos = _formula_term(tokens, pos, width)
    while pos < len(tokens) and tokens[pos] in "+-":
        pos = _formula_term(tokens, pos + 1, width)
    return pos


class _FormulaEvalError(Exception):
    """Internal: formula evaluates to a constant domain error (e.g. /0)."""


def _eval_tokens(tokens: list[str], width: int, env: list[float]) -> float:
    pos, value = _eval_expr(tokens, 0, width, env)
    if pos != len(tokens):
        raise _FormulaParseError("trail")
    return value


def _eval_expr(
    tokens: list[str], pos: int, width: int, env: list[float]
) -> tuple[int, float]:
    pos, value = _eval_term(tokens, pos, width, env)
    while pos < len(tokens) and tokens[pos] in "+-":
        op = tokens[pos]
        pos, right = _eval_term(tokens, pos + 1, width, env)
        value = value + right if op == "+" else value - right
    return pos, value


def _eval_term(
    tokens: list[str], pos: int, width: int, env: list[float]
) -> tuple[int, float]:
    pos, value = _eval_factor(tokens, pos, width, env)
    while pos < len(tokens) and tokens[pos] in "*/%":
        op = tokens[pos]
        pos, right = _eval_factor(tokens, pos + 1, width, env)
        if op in "/%" and right == 0:
            raise _FormulaEvalError(op)
        if op == "*":
            value *= right
        elif op == "/":
            value /= right
        else:
            value %= right
    return pos, value


def _eval_factor(
    tokens: list[str], pos: int, width: int, env: list[float]
) -> tuple[int, float]:
    if pos >= len(tokens):
        raise _FormulaParseError("eof")
    token = tokens[pos]
    if token == "(":
        pos, value = _eval_expr(tokens, pos + 1, width, env)
        return pos + 1, value
    if FORMULA_LETTER.fullmatch(token.upper()):
        return pos + 1, env[ord(token.upper()) - ord("A")]
    if FORMULA_NUMBER.fullmatch(token):
        return pos + 1, float(token)
    name = token.upper()
    if name in {"LOOKUP", "CLOSEST"}:
        return _eval_lookup_call(tokens, pos, width, env, name)
    if name in FORMULA_FUNCS:
        if pos + 1 >= len(tokens) or tokens[pos + 1] != "(":
            raise _FormulaParseError("call")
        pos += 2
        args: list[float] = []
        if pos < len(tokens) and tokens[pos] != ")":
            pos, value = _eval_expr(tokens, pos, width, env)
            args.append(value)
            while pos < len(tokens) and tokens[pos] in ",:":
                pos, value = _eval_expr(tokens, pos + 1, width, env)
                args.append(value)
        return pos + 1, _apply_formula_func(name, args)
    raise _FormulaParseError(token)


def _eval_signed_bits(value: float, bits: int) -> float:
    if not math.isfinite(value):
        raise _FormulaEvalError("signed")
    mask = (1 << bits) - 1
    sign = 1 << (bits - 1)
    raw = int(value) & mask
    return float(raw - (1 << bits) if raw >= sign else raw)


def _apply_formula_func(name: str, args: list[float]) -> float:
    if name == "RANDOM":
        return 0.5
    if name == "ABS":
        return abs(args[0])
    if name == "LOG":
        if not math.isfinite(args[0]) or args[0] <= 0:
            raise _FormulaEvalError("log")
        return math.log(args[0])
    if name == "LOG10":
        if not math.isfinite(args[0]) or args[0] <= 0:
            raise _FormulaEvalError("log")
        return math.log10(args[0])
    if name == "LOG1P":
        if not math.isfinite(args[0]) or args[0] <= -1:
            raise _FormulaEvalError("log")
        return math.log1p(args[0])
    if name == "SQRT":
        if not math.isfinite(args[0]) or args[0] < 0:
            raise _FormulaEvalError("sqrt")
        return math.sqrt(args[0])
    if name == "SIN":
        return math.sin(args[0])
    if name == "COS":
        return math.cos(args[0])
    if name == "TAN":
        return math.tan(args[0])
    if name == "SIGNED8":
        return _eval_signed_bits(args[0], 8)
    if name == "SIGNED16":
        return _eval_signed_bits(args[0], 16)
    if name == "SIGNED24":
        return _eval_signed_bits(args[0], 24)
    if name == "SIGNED32":
        return _eval_signed_bits(args[0], 32)
    if name == "INT":
        if not math.isfinite(args[0]):
            raise _FormulaEvalError("int")
        return float(math.trunc(args[0]))
    if name == "SIGNED":
        return args[0]
    if name == "MIN":
        return min(args)
    if name == "MAX":
        return max(args)
    if name == "BIT":
        value, bit = args[0], args[1]
        # formula_engine.dart ~1869-1875: index must equal its truncation.
        if not math.isfinite(value):
            raise _FormulaEvalError("bit")
        if not math.isfinite(bit) or bit != math.trunc(bit) or bit < 0:
            raise _FormulaEvalError("bit")
        return float((int(value) >> int(bit)) & 1)
    if name == "FLOAT32":
        return _eval_ieee_float(args, ">f")
    if name == "FLOAT64":
        return _eval_ieee_float(args, ">d")
    if args:
        return args[0]
    return 0.0


def _eval_ieee_float(args: list[float], fmt: str) -> float:
    """Mirror FormulaEngine._float32/_float64 (formula_engine.dart ~1094-1162)."""
    size = struct.calcsize(fmt)
    if len(args) != size:
        raise _FormulaParseError("arity")
    raw = bytes(int(arg) & 0xFF for arg in args)
    value = struct.unpack(fmt, raw)[0]
    if not math.isfinite(value):
        raise _FormulaEvalError("ieee")
    return float(value)


def _eval_lookup_call(
    tokens: list[str],
    pos: int,
    width: int,
    env: list[float],
    name: str,
) -> tuple[int, float]:
    end = _formula_lookup_call(tokens, pos, width)
    inner_pos = pos + 2
    parts: list[list[str]] = []
    current: list[str] = []
    depth = 0
    cursor = inner_pos
    while cursor < end:
        token = tokens[cursor]
        if token == "(":
            depth += 1
            current.append(token)
        elif token == ")":
            if depth == 0:
                parts.append(current)
                break
            depth -= 1
            current.append(token)
        elif token == ":" and depth == 0:
            parts.append(current)
            current = []
        else:
            current.append(token)
        cursor += 1
    value = _eval_tokens(parts[0], width, env)
    default = _eval_tokens(parts[1], width, env) if parts[1] else 0.0
    if name == "CLOSEST":
        best: tuple[float, float] | None = None
        for pair in parts[2:]:
            equals = _top_level_index(pair, "=")
            key = _eval_tokens(pair[:equals], width, env)
            mapped = _eval_tokens(pair[equals + 1 :], width, env)
            distance = abs(value - key)
            if best is None or distance < best[0]:
                best = (distance, mapped)
        return end, best[1] if best is not None else default
    for pair in parts[2:]:
        equals = _top_level_index(pair, "=")
        key_tokens, mapped_tokens = pair[:equals], pair[equals + 1 :]
        tilde = _top_level_index(key_tokens, "~")
        mapped = _eval_tokens(mapped_tokens, width, env)
        if tilde < 0:
            if _eval_tokens(key_tokens, width, env) == value:
                return end, mapped
        else:
            low = _eval_tokens(key_tokens[:tilde], width, env)
            high = _eval_tokens(key_tokens[tilde + 1 :], width, env)
            if low <= value <= high:
                return end, mapped
    return end, default


def _formula_catalog_probe(width: int) -> list[float]:
    """Same sample as profile_catalog_validator.dart ~277-280.

    ``FormulaEngine.validate(..., sampleBytes: List.filled(width, 1))`` disables
    preflight fallback probes, so ``1/(A-1)`` is rejected on the catalog path.
    """
    return [1.0] * width


def _formula_is_sound(formula: Any, width: Any) -> bool:
    """Parse/evaluate the formula the way FormulaEngine.validate does.

    See ``profile_catalog_validator.dart`` ~277-282. Rejects ``A*``, ``A**2``,
    ``)A(``, unknown calls such as ``FOO(A)``, letters outside the window, and
    LOOKUP/CLOSEST that are not ``value:default:key=val`` (comma forms and
    two-part ``LOOKUP(A:0)`` fail, matching ``formula_engine.dart`` ~1375-1652).
    After a complete parse, evaluate the catalog's fixed all-1s probe so
    constant ``A/0``, ``A%0``, ``1/(A-A)``, and catalog-undefined ``1/(A-1)``
    fail (``formula_engine.dart`` ~2187-2242 when ``sampleBytes`` is supplied).
    """
    if not isinstance(formula, str) or not formula.strip():
        return False
    if not _is_int(width) or width < 1 or width > 14:
        return False
    try:
        tokens = _formula_tokens(formula.strip())
        end = _formula_expr(tokens, 0, width)
        if end != len(tokens):
            return False
        value = _eval_tokens(tokens, width, _formula_catalog_probe(width))
        # formula_engine.dart ~609-616 rejects NaN / infinity results.
        return math.isfinite(value)
    except (_FormulaParseError, _FormulaEvalError):
        return False


def _observation_looks_complete(obs: dict[str, Any]) -> bool:
    return all(field in obs for field in WIRE_FIELDS) and _as_dict(
        obs.get("byte_window")
    ) is not None


def _observation_has_complete_wire(obs: dict[str, Any]) -> bool:
    for field in WIRE_FIELDS:
        if field not in obs:
            return False
    if not _is_exact_can_id(obs.get("request_header")):
        return False
    if not _is_exact_can_id(obs.get("expected_responder")):
        return False
    service = (_text(obs.get("service")) or _text(obs.get("mode"))).upper()
    if service not in READ_ONLY_SERVICES:
        return False
    did = (_text(obs.get("did")) or _text(obs.get("identifier"))).upper()
    if not HEX_DID.fullmatch(did) or len(did) != IDENTIFIER_WIDTH[service]:
        return False
    payload_length = obs.get("payload_length")
    if not _is_int(payload_length) or payload_length < 1:
        return False
    formula = obs.get("formula")
    if not isinstance(formula, str) or not formula.strip():
        return False
    signedness = obs.get("signedness")
    if not isinstance(signedness, str) or signedness.strip().lower() not in SIGNEDNESS:
        return False
    unit = obs.get("unit")
    if not isinstance(unit, str) or not unit.strip():
        return False
    window = _as_dict(obs.get("byte_window"))
    if window is None:
        return False
    offset = window.get("offset")
    width = window.get("width")
    if not _is_int(offset) or offset < 0:
        return False
    if not _is_int(width) or width < 1:
        return False
    if width > 14:
        return False
    # Mirror PowertrainBatteryProfileCatalogValidator: offset < 0 || width <= 0
    # || offset + width > payload_length.
    if offset + width > payload_length:
        return False
    if not _formula_is_sound(formula, width):
        return False
    return True


def _observation_has_invalid_wire_values(obs: dict[str, Any]) -> bool:
    if not _observation_looks_complete(obs):
        return False
    if _byte_window_out_of_bounds(obs) or _byte_window_too_wide(obs):
        return False
    return not _observation_has_complete_wire(obs)


def _byte_window_out_of_bounds(obs: dict[str, Any]) -> bool:
    window = _as_dict(obs.get("byte_window"))
    if window is None:
        return False
    offset = window.get("offset")
    width = window.get("width")
    payload_length = obs.get("payload_length")
    if not _is_int(offset) or not _is_int(width):
        return False
    if not _is_int(payload_length) or payload_length < 1:
        return False
    if offset < 0 or width < 1:
        return False
    return offset + width > payload_length


def _byte_window_too_wide(obs: dict[str, Any]) -> bool:
    window = _as_dict(obs.get("byte_window"))
    if window is None:
        return False
    width = window.get("width")
    return _is_int(width) and width > 14


def _observation_has_wire(obs: dict[str, Any]) -> bool:
    return _observation_has_complete_wire(obs)


def _signal_has_contract(signal: dict[str, Any]) -> bool:
    return bool(_as_dict(signal.get("contract")))


def _signal_has_complete_contract(signal: dict[str, Any]) -> bool:
    contract = _as_dict(signal.get("contract"))
    return contract is not None and _observation_has_complete_wire(contract)


def _signal_is_shipped(signal: dict[str, Any]) -> bool:
    return bool(_signal_wire_observations(signal)) or _signal_has_complete_contract(
        signal
    )


def _row_incomplete_observations(row: dict[str, Any]) -> bool:
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        for obs in _as_list(signal.get("observations")):
            if (
                isinstance(obs, dict)
                and not _observation_has_complete_wire(obs)
                and not _byte_window_out_of_bounds(obs)
                and not _byte_window_too_wide(obs)
                and not _observation_has_invalid_wire_values(obs)
            ):
                return True
    return False


def _row_incomplete_contracts(row: dict[str, Any]) -> bool:
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        contract = _as_dict(signal.get("contract"))
        if contract is None:
            continue
        if (
            not _observation_has_complete_wire(contract)
            and not _byte_window_out_of_bounds(contract)
            and not _byte_window_too_wide(contract)
            and not _observation_has_invalid_wire_values(contract)
        ):
            return True
    return False


def _row_invalid_wire_values(row: dict[str, Any]) -> bool:
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        contract = _as_dict(signal.get("contract"))
        if contract is not None and _observation_has_invalid_wire_values(contract):
            return True
        for obs in _as_list(signal.get("observations")):
            if isinstance(obs, dict) and _observation_has_invalid_wire_values(obs):
                return True
    return False


def _row_byte_window_too_wide(row: dict[str, Any]) -> bool:
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        contract = _as_dict(signal.get("contract"))
        if contract is not None and _byte_window_too_wide(contract):
            return True
        for obs in _as_list(signal.get("observations")):
            if isinstance(obs, dict) and _byte_window_too_wide(obs):
                return True
    return False


def _row_byte_window_out_of_bounds(row: dict[str, Any]) -> bool:
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        contract = _as_dict(signal.get("contract"))
        if contract is not None and _byte_window_out_of_bounds(contract):
            return True
        for obs in _as_list(signal.get("observations")):
            if isinstance(obs, dict) and _byte_window_out_of_bounds(obs):
                return True
    return False


def _command_is_concrete(command: dict[str, Any]) -> bool:
    """Mirror profile_catalog_validator.dart command checks (~433-468)."""
    if not _is_exact_can_id(command.get("request_header")):
        return False
    if not _is_exact_can_id(command.get("expected_responder")):
        return False
    service = (_text(command.get("service")) or _text(command.get("mode"))).upper()
    if service not in READ_ONLY_SERVICES:
        return False
    did = (_text(command.get("did")) or _text(command.get("identifier"))).upper()
    expected_width = IDENTIFIER_WIDTH[service]
    if not HEX_DID.fullmatch(did) or len(did) != expected_width:
        return False
    payload_length = command.get("payload_length")
    return _is_int(payload_length) and payload_length >= 1


def _catalog_signal_is_bounded(
    command: dict[str, Any], signal: dict[str, Any]
) -> bool:
    """Mirror profile_catalog_validator.dart ~294-296."""
    payload_length = command.get("payload_length")
    offset = signal.get("offset")
    width = signal.get("width")
    if not _is_int(payload_length) or payload_length < 1:
        return False
    if not _is_int(offset) or offset < 0:
        return False
    if not _is_int(width) or width < 1 or width > 14:
        return False
    if offset + width > payload_length:
        return False
    if not _text(signal.get("id")) or not _text(signal.get("name")):
        return False
    if not _formula_is_sound(signal.get("equation"), width):
        return False
    min_value = signal.get("min_value")
    max_value = signal.get("max_value")
    if isinstance(min_value, bool) or isinstance(max_value, bool):
        return False
    if not isinstance(min_value, (int, float)) or not isinstance(
        max_value, (int, float)
    ):
        return False
    if not math.isfinite(float(min_value)) or not math.isfinite(float(max_value)):
        return False
    return min_value < max_value


def _catalog_command_is_executable(command: dict[str, Any]) -> bool:
    """Mirror profile_catalog_validator.dart ~433-476.

    A concrete read-only command still needs a nonempty bounded ``signals``
    list; empty ``signals`` is ``missing_signals`` at runtime.
    """
    if not _command_is_concrete(command):
        return False
    # Catalog JSON uses native keys; fromJson requires mode + identifier
    # (powertrain_battery_profile.dart ~214-215), not research aliases.
    mode = _text(command.get("mode")).upper()
    identifier = _text(command.get("identifier")).upper()
    if mode not in READ_ONLY_SERVICES:
        return False
    # profile_catalog_validator.dart ~215-225: installable tiers are Mode 22 only.
    if mode != "22":
        return False
    if (
        not HEX_DID.fullmatch(identifier)
        or len(identifier) != IDENTIFIER_WIDTH[mode]
    ):
        return False
    signals = command.get("signals")
    if not isinstance(signals, list) or not signals:
        return False
    return all(
        isinstance(item, dict) and _catalog_signal_is_bounded(command, item)
        for item in signals
    )


def _has_executable_claim(row: dict[str, Any]) -> bool:
    for command in _as_list(row.get("commands")):
        if isinstance(command, dict) and _command_is_concrete(command):
            return True
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        if _signal_has_complete_contract(signal):
            return True
        for obs in _as_list(signal.get("observations")):
            if isinstance(obs, dict) and _observation_has_wire(obs):
                return True
    return False


def _resolved_service(obs: dict[str, Any]) -> str:
    return (_text(obs.get("service")) or _text(obs.get("mode"))).upper()


def _resolved_did(obs: dict[str, Any]) -> str:
    return (_text(obs.get("did")) or _text(obs.get("identifier"))).upper()


def _wire_signature(obs: dict[str, Any]) -> tuple[Any, ...]:
    window = _as_dict(obs.get("byte_window")) or {}
    return (
        _text(obs.get("request_header")).upper(),
        _text(obs.get("expected_responder")).upper(),
        _resolved_service(obs),
        _resolved_did(obs),
        obs.get("payload_length"),
        window.get("offset"),
        window.get("width"),
        _text(obs.get("formula")),
        _text(obs.get("signedness")).lower(),
        _text(obs.get("unit")),
    )


def _physical_locator(row: dict[str, Any]) -> str:
    block = _as_dict(row.get("vehicle_evidence"))
    if block is not None:
        return _text(block.get("locator"))
    return _text(row.get("vehicle_evidence_locator"))


def _sales_outside_priority(value: Any, *, in_priority: bool = False) -> bool:
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "priority":
                if _sales_outside_priority(child, in_priority=True):
                    return True
                continue
            if in_priority:
                if _sales_outside_priority(child, in_priority=True):
                    return True
                continue
            if key in SALES_KEYS:
                return True
            if key in {"evidence_tier", "kind", "source_kind"} and _text(
                child
            ).lower() in SALES_KIND_VALUES:
                return True
            if _sales_outside_priority(child, in_priority=False):
                return True
        return False
    if isinstance(value, list):
        return any(
            _sales_outside_priority(item, in_priority=in_priority) for item in value
        )
    return False


def _locator_points_at_row(locator: str, row_ids: set[str], self_id: str) -> bool:
    text = locator.strip()
    if not text:
        return False
    for prefix in INHERIT_LOCATOR_PREFIXES:
        if text.lower().startswith(prefix):
            return True
    return text in row_ids and text != self_id


def _has_inherit_key(value: dict[str, Any]) -> bool:
    return any(key in value and value[key] not in (None, "") for key in INHERIT_KEYS)


def _row_inherits(row: dict[str, Any], row_ids: set[str]) -> bool:
    if _has_inherit_key(row):
        return True
    vehicle_evidence = _as_dict(row.get("vehicle_evidence"))
    if vehicle_evidence is not None and _has_inherit_key(vehicle_evidence):
        return True
    for source in _as_list(row.get("source_families")):
        if isinstance(source, dict) and _has_inherit_key(source):
            return True
    for command in _as_list(row.get("commands")):
        if isinstance(command, dict) and _has_inherit_key(command):
            return True
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        if _has_inherit_key(signal):
            return True
        contract = _as_dict(signal.get("contract"))
        if contract is not None and _has_inherit_key(contract):
            return True
        for obs in _as_list(signal.get("observations")):
            if isinstance(obs, dict) and _has_inherit_key(obs):
                return True
    self_id = _text(row.get("id"))
    candidates: list[Any] = [
        row.get("evidence_locator"),
        row.get("locator"),
        row.get("vehicle_evidence_locator"),
    ]
    vehicle_evidence = _as_dict(row.get("vehicle_evidence"))
    if vehicle_evidence is not None:
        candidates.append(vehicle_evidence.get("locator"))
        candidates.append(vehicle_evidence.get("evidence_locator"))
    for source in _as_list(row.get("source_families")):
        if isinstance(source, dict):
            candidates.append(source.get("locator"))
            candidates.append(source.get("evidence_locator"))
    for command in _as_list(row.get("commands")):
        if isinstance(command, dict):
            candidates.append(command.get("locator"))
            candidates.append(command.get("evidence_locator"))
    for signal in _as_list(row.get("signals")):
        if isinstance(signal, dict):
            candidates.append(signal.get("locator"))
            contract = _as_dict(signal.get("contract"))
            if contract is not None:
                candidates.append(contract.get("locator"))
                candidates.append(contract.get("evidence_locator"))
            for obs in _as_list(signal.get("observations")):
                if isinstance(obs, dict):
                    candidates.append(obs.get("locator"))
                    candidates.append(obs.get("evidence_locator"))
    for value in candidates:
        if isinstance(value, str) and _locator_points_at_row(value, row_ids, self_id):
            return True
    return False


def _source_has_pin(source: dict[str, Any]) -> bool:
    revision = _text(source.get("revision"))
    artifact = _text(source.get("artifact_sha256"))
    return is_immutable_revision(revision) or is_sha256_hex(artifact)


def _source_id(source: dict[str, Any], index: int) -> str:
    return _text(source.get("id")) or f"source-{index}"


def _effective_family(source: dict[str, Any]) -> str:
    return derive_source_family(source)


def _source_declares_derived_relationship(value: dict[str, Any]) -> bool:
    return any(key in value and value[key] not in (None, "") for key in DERIVED_FAMILY_KEYS)


def _signal_wire_observations(signal: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        obs
        for obs in _as_list(signal.get("observations"))
        if isinstance(obs, dict) and _observation_has_wire(obs)
    ]


def _signal_family_set(
    observations: list[dict[str, Any]], family_by_source_id: dict[str, str]
) -> set[str]:
    families: set[str] = set()
    for obs in observations:
        source_id = _text(obs.get("source_id"))
        family = family_by_source_id.get(source_id)
        if family:
            families.add(family)
    return families


def _community_signal_corroborated(
    signal: dict[str, Any], family_by_source_id: dict[str, str]
) -> bool:
    observations = _signal_wire_observations(signal)
    if len(observations) < 2:
        return False
    if len({_wire_signature(obs) for obs in observations}) != 1:
        return False
    return len(_signal_family_set(observations, family_by_source_id)) >= 2


def _community_contract_mismatches_observations(signal: dict[str, Any]) -> bool:
    if not _signal_has_complete_contract(signal):
        return False
    observations = _signal_wire_observations(signal)
    if len(observations) < 2:
        return False
    signatures = {_wire_signature(obs) for obs in observations}
    if len(signatures) != 1:
        return False
    contract = _as_dict(signal.get("contract")) or {}
    return _wire_signature(contract) != next(iter(signatures))


def validate_research_row(
    row: dict[str, Any],
    *,
    catalog_ids: set[str],
    research_ids: set[str],
) -> list[str]:
    issues: list[str] = []
    row_id = _text(row.get("id")) or "<missing-id>"
    prefix = f"research row {row_id}"

    disposition = _text(row.get("disposition"))
    if disposition not in DISPOSITIONS:
        issues.append(f"{prefix}: disposition is not a finite validated state")

    aliases = row.get("aliases")
    if aliases is None:
        issues.append(f"{prefix}: aliases must be a list")
    elif not isinstance(aliases, list) or any(
        not isinstance(item, str) for item in aliases
    ):
        issues.append(f"{prefix}: aliases must be a list of strings")
    else:
        for alias in aliases:
            if alias.strip().lower() in GENERIC_BRAND_PLATFORM_ALIASES:
                issues.append(
                    f"{prefix}: alias {alias!r} extrapolates entire brand/platform without model specificity"
                )

    commands = row.get("commands")
    if commands is not None and not isinstance(commands, list):
        issues.append(f"{prefix}: commands must be a list")

    signals = row.get("signals")
    if signals is not None and not isinstance(signals, list):
        issues.append(f"{prefix}: signals must be a list")
    elif isinstance(signals, list):
        for signal in signals:
            if not isinstance(signal, dict):
                continue
            observations = signal.get("observations")
            if observations is not None and not isinstance(observations, list):
                issues.append(f"{prefix}: observations must be a list")
                break

    evidence_date = _text(row.get("evidence_date"))
    if not DATE.fullmatch(evidence_date):
        issues.append(f"{prefix}: evidence_date must be YYYY-MM-DD")

    presence = _text(row.get("catalog_presence"))
    if presence and presence not in CATALOG_PRESENCE:
        issues.append(f"{prefix}: catalog_presence must be present or absent")
    profile_ids = row.get("catalog_profile_ids")
    if profile_ids is None:
        profile_ids = []
    if not isinstance(profile_ids, list) or any(
        not isinstance(item, str) for item in profile_ids
    ):
        issues.append(f"{prefix}: catalog_profile_ids must be a list of strings")
        profile_ids = []
    if presence == "absent" and profile_ids:
        issues.append(
            f"{prefix}: catalog_presence absent but catalog_profile_ids is not empty"
        )
    for profile_id in profile_ids:
        if profile_id not in catalog_ids:
            issues.append(f"{prefix}: lists unknown catalog profile id {profile_id}")

    raw_sources = row.get("source_families")
    if raw_sources is not None and not isinstance(raw_sources, list):
        issues.append(f"{prefix}: source_families must be a list")
        sources = []
    else:
        sources = _as_list(raw_sources)
        if any(not isinstance(item, dict) for item in sources):
            issues.append(f"{prefix}: source_families must be a list of objects")
            sources = [item for item in sources if isinstance(item, dict)]

    if _source_declares_derived_relationship(row):
        issues.append(
            f"{prefix}: declares a derived-family relationship "
            f"({sorted(key for key in DERIVED_FAMILY_KEYS if key in row)})"
        )

    families: dict[str, str] = {}
    repo_path_owners: dict[str, tuple[str, str]] = {}
    hash_owners: dict[str, tuple[str, str]] = {}
    url_owners: dict[str, tuple[str, str]] = {}
    seen_source_ids: dict[str, int] = {}
    identity_collision_ids: set[str] = set()
    for index, source in enumerate(sources):
        source_id = _source_id(source, index)
        derived_family = _effective_family(source)
        declared_family = _text(source.get("family"))
        if not declared_family:
            issues.append(f"{prefix}: source is missing family")
        if not derived_family:
            issues.append(
                f"{prefix}: source {source_id} has no derivable family identity"
            )
        elif derived_family:
            families[source_id] = derived_family
        repo_path = source_repo_path_key(source)
        if repo_path:
            previous = repo_path_owners.get(repo_path)
            if previous is not None and previous[1] != declared_family:
                identity_collision_ids.add(previous[0])
                identity_collision_ids.add(source_id)
                issues.append(
                    f"{prefix}: sources {previous[0]} and {source_id} share repo+path "
                    "but declare different families"
                )
            else:
                repo_path_owners[repo_path] = (source_id, declared_family)
        artifact = _text(source.get("artifact_sha256")).lower()
        if artifact:
            previous = hash_owners.get(artifact)
            if previous is not None and previous[1] != declared_family:
                identity_collision_ids.add(previous[0])
                identity_collision_ids.add(source_id)
                issues.append(
                    f"{prefix}: sources {previous[0]} and {source_id} share artifact hash "
                    "but declare different families"
                )
            else:
                hash_owners[artifact] = (source_id, declared_family)
        url_key = source_url_key(source)
        if url_key and not GITHUB_REPO.match(_text(source.get("url"))):
            previous = url_owners.get(url_key)
            if previous is not None and previous[1] != declared_family:
                identity_collision_ids.add(previous[0])
                identity_collision_ids.add(source_id)
                issues.append(
                    f"{prefix}: sources {previous[0]} and {source_id} share source URL "
                    "but declare different families"
                )
            else:
                url_owners[url_key] = (source_id, declared_family)
        seen_source_ids[source_id] = seen_source_ids.get(source_id, 0) + 1
        if _text(source.get("role")) not in SOURCE_ROLES:
            issues.append(f"{prefix}: source {source_id} has no valid role")
        if _source_declares_derived_relationship(source):
            issues.append(
                f"{prefix}: source {source_id} declares a derived-family relationship "
                f"({sorted(key for key in DERIVED_FAMILY_KEYS if key in source)})"
            )

    for index, source in enumerate(sources):
        source_id = _source_id(source, index)
        if source_id in identity_collision_ids:
            continue
        derived_family = _effective_family(source)
        declared_family = _text(source.get("family"))
        if declared_family and derived_family and declared_family != derived_family:
            issues.append(
                f"{prefix}: source {source_id} declared family {declared_family!r} "
                f"does not match derived family {derived_family!r}"
            )
        loc = _text(source.get("locator"))
        if not loc:
            issues.append(
                f"{prefix}: source {source_id} missing row-specific evidence locator"
            )
        elif any(loc.lower().startswith(p) for p in INHERIT_LOCATOR_PREFIXES):
            issues.append(
                f"{prefix}: source {source_id} locator uses prohibited inheritance reference: {loc}"
            )
        src_path = _text(source.get("path")).lower()
        src_url = _text(source.get("url")).lower()
        src_repo = _text(source.get("family") or source.get("name") or source.get("repository"))
        src_rev = _text(source.get("revision"))
        src_hash = _text(source.get("artifact_sha256") or source.get("hash"))
        row_aliases = [str(a) for a in _as_list(row.get("aliases")) if isinstance(a, str)]
        generation = _text(row.get("generation"))
        if generation:
            row_aliases.append(generation)
        row_signals: list[str] = []
        for s in _as_list(row.get("signals")):
            if isinstance(s, str) and s.strip():
                row_signals.append(s.strip())
            elif isinstance(s, dict) and _text(s.get("id")):
                row_signals.append(_text(s.get("id")))
        if _text(row.get("signal")):
            row_signals.append(_text(row.get("signal")))
        if not row_signals:
            row_signals = ["battery_profile"]
        if _is_cross_model_source(
            row_id,
            loc,
            src_path,
            src_url,
            aliases=row_aliases,
            signals=row_signals,
            repository=src_repo,
            revision=src_rev,
            source_hash=src_hash,
        ):
            issues.append(
                f"{prefix}: source {source_id} path {source.get('path')!r} belongs to a different vehicle model than {row_id}"
            )

    primaries = [s for s in sources if _text(s.get("role")) == "primary"]
    corroborating = [
        s
        for s in sources
        if _text(s.get("role")) in {"corroborating", "secondary"}
    ]
    primary_families = {_effective_family(s) for s in primaries if _effective_family(s)}
    for source in corroborating:
        family = _effective_family(source)
        if family and family in primary_families:
            issues.append(
                f"{prefix}: corroborating source family {family} equals primary family"
            )
    shipped = [
        signal
        for signal in _as_list(row.get("signals"))
        if isinstance(signal, dict) and _signal_is_shipped(signal)
    ]
    qualifying_families: set[str] = set()
    for signal in shipped:
        qualifying_families.update(
            _signal_family_set(_signal_wire_observations(signal), families)
        )
    if not qualifying_families:
        qualifying_families = {family for family in families.values() if family}
    needs_qualification_rationale = (
        disposition == "community-qualified" and len(qualifying_families) >= 2
    )
    if (corroborating or needs_qualification_rationale) and not _independence_rationale(
        row
    ):
        if corroborating:
            issues.append(
                f"{prefix}: corroborating source is missing independence_rationale"
            )
        else:
            issues.append(
                f"{prefix}: qualification across multiple source families "
                "is missing independence_rationale"
            )

    incomplete_observations = _row_incomplete_observations(row)
    if incomplete_observations:
        issues.append(f"{prefix}: observation is missing a complete wire contract")
    incomplete_contracts = _row_incomplete_contracts(row)
    if incomplete_contracts:
        issues.append(f"{prefix}: contract is missing a complete wire contract")
    window_out_of_bounds = _row_byte_window_out_of_bounds(row)
    if window_out_of_bounds:
        issues.append(f"{prefix}: byte window does not fit payload_length")
    window_too_wide = _row_byte_window_too_wide(row)
    if window_too_wide:
        issues.append(
            f"{prefix}: signal width exceeds the A..N formula byte window"
        )
    invalid_wire_values = _row_invalid_wire_values(row)
    if invalid_wire_values:
        issues.append(f"{prefix}: invalid wire contract values")
    incomplete_claims = (
        incomplete_observations
        or incomplete_contracts
        or window_out_of_bounds
        or window_too_wide
        or invalid_wire_values
    )

    source_ids = {
        _source_id(source, index)
        for index, source in enumerate(sources)
        if seen_source_ids.get(_source_id(source, index), 0) == 1
    }
    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        for obs in _signal_wire_observations(signal):
            source_id = _text(obs.get("source_id"))
            if source_id not in source_ids:
                issues.append(
                    f"{prefix}: observation source_id does not resolve to a declared source"
                )
                break
        else:
            continue
        break

    contract_mismatch = any(
        isinstance(signal, dict) and _community_contract_mismatches_observations(signal)
        for signal in _as_list(row.get("signals"))
    )
    if contract_mismatch:
        issues.append(
            f"{prefix}: shipped contract does not match corroborated observation signature"
        )

    commands = [item for item in _as_list(row.get("commands")) if isinstance(item, dict)]
    if "command_count" in row:
        claimed_count = row.get("command_count")
        if not _is_int(claimed_count) or claimed_count != len(commands):
            issues.append(
                f"{prefix}: command_count disagrees with len(commands)"
            )
    malformed_commands = any(
        not _command_is_concrete(command) for command in commands
    )
    if malformed_commands:
        issues.append(f"{prefix}: malformed concrete command")
        incomplete_claims = True

    executable = _has_executable_claim(row)
    status = _text(row.get("status"))
    if not incomplete_claims and not contract_mismatch:
        if status in {"community", "ready"} and not executable:
            issues.append(f"{prefix}: status={status} has 0 executable commands")
        if disposition == "experimental-candidate" and not executable:
            issues.append(
                f"{prefix}: experimental-candidate requires at least one executable claim"
            )
        if disposition == "community-qualified":
            if not executable:
                issues.append(f"{prefix}: status=community has 0 executable commands")
            elif not shipped or not all(
                _community_signal_corroborated(signal, families) for signal in shipped
            ):
                issues.append(
                    f"{prefix}: community-qualified requires agreeing observations "
                    "from at least two distinct source families per shipped signal"
                )

    if executable:
        decision = _licence_decision(row)
        if not decision:
            issues.append(
                f"{prefix}: executable claim has no licence/redistribution decision"
            )
        elif decision not in LICENCE_DECISIONS:
            issues.append(
                f"{prefix}: licence/redistribution decision is not a finite state"
            )
        if not sources:
            issues.append(
                f"{prefix}: executable claim has no immutable revision or artifact hash"
            )
        else:
            for source in sources:
                if not _source_has_pin(source):
                    issues.append(
                        f"{prefix}: executable claim has no immutable revision or artifact hash"
                    )
                    break
        if disposition == "unknown":
            issues.append(
                f"{prefix}: disposition unknown but carries an executable claim"
            )

    if disposition != "unknown" and (
        _scope_missing(row.get("market"))
        or _year_missing(row)
        or _scope_missing(row.get("firmware_scope"))
    ):
        issues.append(f"{prefix}: missing market/year/firmware scope")

    if _row_inherits(row, research_ids | catalog_ids):
        issues.append(f"{prefix}: inherits evidence from another row")

    for signal in _as_list(row.get("signals")):
        if not isinstance(signal, dict):
            continue
        agreement = _text(signal.get("agreement")).lower()
        if agreement not in AGREEING_MARKS:
            continue
        observations = [
            obs
            for obs in _as_list(signal.get("observations"))
            if isinstance(obs, dict) and _observation_has_wire(obs)
        ]
        signatures = {_wire_signature(obs) for obs in observations}
        if len(observations) >= 2 and len(signatures) > 1:
            signal_id = _text(signal.get("id")) or "<missing-signal-id>"
            issues.append(
                f"{prefix}: signal {signal_id} is marked {agreement} but sources disagree"
            )

    if _sales_outside_priority(row):
        issues.append(f"{prefix}: sales/popularity data present outside priority")

    if _text(row.get("evidence")) == "physicalVehicle" and not _physical_locator(row):
        issues.append(
            f"{prefix}: physicalVehicle evidence has no retained vehicle-evidence locator"
        )

    return issues


def validate_catalog_community_profile(profile: dict[str, Any]) -> list[str]:
    issues: list[str] = []
    profile_id = _text(profile.get("id")) or "<missing-id>"
    prefix = f"catalog profile {profile_id}"

    source = profile.get("source")
    primary_family = ""
    if not isinstance(source, dict):
        issues.append(f"{prefix}: community profile missing primary source object")
    else:
        primary_family = derive_source_family(source)
        if not primary_family:
            issues.append(f"{prefix}: primary source has no derivable family identity")
        if not _text(source.get("license")):
            issues.append(f"{prefix}: primary source missing licence")
        if not is_immutable_revision(_text(source.get("revision"))):
            issues.append(f"{prefix}: primary source missing immutable revision pin")
        if not is_sha256_hex(_text(source.get("artifact_sha256"))):
            issues.append(f"{prefix}: primary source missing valid artifact sha256")
        loc = _text(source.get("locator"))
        if not loc:
            issues.append(f"{prefix}: primary source missing row-specific evidence locator")
        elif any(loc.lower().startswith(p) for p in INHERIT_LOCATOR_PREFIXES):
            issues.append(f"{prefix}: primary source locator uses prohibited inheritance reference: {loc}")

    secondaries = profile.get("secondary_sources")
    if not isinstance(secondaries, list) or not secondaries:
        issues.append(f"{prefix}: community profile requires at least one secondary source")
    else:
        sec_families: list[str] = []
        for idx, sec in enumerate(secondaries):
            if not isinstance(sec, dict):
                issues.append(f"{prefix}: secondary source [{idx}] must be an object")
                continue
            sec_fam = derive_source_family(sec)
            if not sec_fam:
                issues.append(f"{prefix}: secondary source [{idx}] has no derivable family identity")
            else:
                sec_families.append(sec_fam)
            if not _text(sec.get("license")):
                issues.append(f"{prefix}: secondary source [{idx}] missing licence")
            if not is_immutable_revision(_text(sec.get("revision"))):
                issues.append(f"{prefix}: secondary source [{idx}] missing immutable revision pin")
            if not is_sha256_hex(_text(sec.get("artifact_sha256"))):
                issues.append(f"{prefix}: secondary source [{idx}] missing valid artifact sha256")
            sec_loc = _text(sec.get("locator"))
            if not sec_loc:
                issues.append(f"{prefix}: secondary source [{idx}] missing row-specific evidence locator")
            elif any(sec_loc.lower().startswith(p) for p in INHERIT_LOCATOR_PREFIXES):
                issues.append(f"{prefix}: secondary source [{idx}] locator uses prohibited inheritance reference: {sec_loc}")

        if primary_family and sec_families:
            independent = [f for f in sec_families if f != primary_family]
            if not independent:
                issues.append(
                    f"{prefix}: community profile requires independent corroborating source family, "
                    f"found only same family as primary: {primary_family}"
                )

    market = _text(profile.get("market"))
    if not market or market.lower() in BLANK_SCOPE:
        issues.append(f"{prefix}: community profile missing exact market scope")
    make = _text(profile.get("make"))
    if not make:
        issues.append(f"{prefix}: community profile missing make scope")
    model = _text(profile.get("model"))
    if not model:
        issues.append(f"{prefix}: community profile missing model scope")

    year_from = profile.get("year_from")
    year_to = profile.get("year_to")
    if not isinstance(year_from, int) or not isinstance(year_to, int):
        issues.append(f"{prefix}: community profile year_from and year_to must be integer years")
    elif year_from > year_to:
        issues.append(f"{prefix}: community profile reversed year range: {year_from} > {year_to}")
    elif year_from < 1900 or year_to > 2100:
        issues.append(f"{prefix}: community profile year range {year_from}-{year_to} outside plausible bounds")

    all_sources = [source] if isinstance(source, dict) else []
    if isinstance(secondaries, list):
        all_sources.extend(s for s in secondaries if isinstance(s, dict))
    for src_item in all_sources:
        src_path = _text(src_item.get("path")).lower()
        src_url = _text(src_item.get("url")).lower()
        src_loc = _text(src_item.get("locator"))
        src_repo = _text(src_item.get("name") or src_item.get("repository") or src_item.get("family"))
        src_rev = _text(src_item.get("revision"))
        src_hash = _text(src_item.get("artifact_sha256") or src_item.get("hash") or src_item.get("sha256"))
        target_id = f"{make}-{model}".lower()
        profile_aliases = [
            _text(profile.get("id")),
            _text(profile.get("variant")),
            _text(profile.get("display_name")),
        ]
        profile_signals = ["battery_profile"]
        for cmd in _as_list(profile.get("commands")):
            if isinstance(cmd, dict):
                for sig in _as_list(cmd.get("signals")):
                    if isinstance(sig, dict) and _text(sig.get("id")):
                        profile_signals.append(_text(sig.get("id")))
        if make and model and _is_cross_model_source(
            target_id,
            src_loc,
            src_path,
            src_url,
            aliases=profile_aliases,
            signals=profile_signals,
            repository=src_repo,
            revision=src_rev,
            source_hash=src_hash,
        ):
            issues.append(
                f"{prefix}: source path {src_item.get('path')!r} belongs to a different vehicle model than {make} {model}"
            )
    return issues


def validate_catalog_object(
    catalog: dict[str, Any],
    *,
    validate_evidence: bool = False,
) -> list[str]:
    issues: list[str] = []
    for profile in _as_list(catalog.get("profiles")):
        if not isinstance(profile, dict):
            continue
        profile_id = _text(profile.get("id")) or "<missing-id>"
        prefix = f"catalog profile {profile_id}"
        status = _text(profile.get("status"))
        raw_commands = profile.get("commands")
        command_items = raw_commands if isinstance(raw_commands, list) else []
        if status in {"community", "ready"} and (
            not command_items
            or any(
                not isinstance(item, dict)
                or not _catalog_command_is_executable(item)
                for item in command_items
            )
        ):
            issues.append(
                f"{prefix}: status={status} has 0 executable commands"
            )
        locator = extract_vehicle_evidence_locator(profile) or _physical_locator(profile)
        evidence = _text(profile.get("evidence"))
        if status == "ready" and (evidence != "physicalVehicle" or not locator):
            issues.append(
                f"{prefix}: ready profile requires retained physical-vehicle evidence"
            )
        elif evidence == "physicalVehicle" and not locator:
            issues.append(
                f"{prefix}: physicalVehicle evidence has no retained vehicle-evidence locator"
            )

        if validate_evidence and status == "community":
            issues.extend(validate_catalog_community_profile(profile))
    return issues


def validate_manifest(catalog_bytes: bytes, manifest: dict[str, Any]) -> list[str]:
    claimed_sha = _text(manifest.get("sha256"))
    claimed_size = manifest.get("size_bytes")
    actual_sha = sha256_hex(catalog_bytes)
    actual_size = len(catalog_bytes)
    if claimed_sha != actual_sha or claimed_size != actual_size:
        return ["catalog manifest sha256/size_bytes do not match catalog bytes"]
    return []


def validate_matrix_document(
    matrix: dict[str, Any],
    catalog_bytes: bytes,
    manifest: dict[str, Any],
    research_rows: list[dict[str, Any]],
) -> list[str]:
    issues: list[str] = []
    if _text(matrix.get("kind")) != KIND:
        issues.append("matrix kind is not telltale.powertrain_evidence_matrix")
    if matrix.get("schema_version") != SCHEMA_VERSION:
        issues.append("matrix schema_version is not 1")

    issues.extend(validate_manifest(catalog_bytes, manifest))
    try:
        catalog_obj = json.loads(catalog_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        issues.append(f"catalog is not valid JSON: {error}")
        return issues
    if not isinstance(catalog_obj, dict):
        issues.append("catalog JSON must be an object")
        return issues
    issues.extend(validate_catalog_object(catalog_obj, validate_evidence=True))

    expected_catalog = extract_catalog_section(catalog_bytes, manifest)
    actual_catalog = matrix.get("catalog")
    if dump_canonical(actual_catalog) != dump_canonical(expected_catalog):
        issues.append("catalog-derived section is stale versus the catalog")

    expected_research = sorted(
        research_rows, key=lambda row: str(row.get("id") or "")
    )
    actual_research = matrix.get("research")
    if dump_canonical(actual_research) != dump_canonical(expected_research):
        issues.append("research section is stale versus research/rows.json")

    catalog_profiles_list = _as_list(catalog_obj.get("profiles"))
    catalog_profiles_by_id = {
        _text(p.get("id")): p
        for p in catalog_profiles_list
        if isinstance(p, dict) and _text(p.get("id"))
    }

    catalog_ids = set(catalog_profiles_by_id.keys())
    rows = _as_list(actual_research)
    research_ids = {
        _text(row.get("id"))
        for row in rows
        if isinstance(row, dict) and _text(row.get("id"))
    }
    seen_ids: set[str] = set()
    for row in rows:
        if not isinstance(row, dict):
            issues.append("research rows must be objects")
            continue
        row_id = _text(row.get("id"))
        if not row_id:
            issues.append("research row is missing id")
            continue
        if row_id in seen_ids:
            issues.append(f"research row {row_id}: duplicate id")
        seen_ids.add(row_id)
        issues.extend(
            validate_research_row(
                row, catalog_ids=catalog_ids, research_ids=research_ids
            )
        )

        cat_ids_for_row = row.get("catalog_profile_ids")
        if isinstance(cat_ids_for_row, list):
            disposition = _text(row.get("disposition"))
            row_yf = row.get("year_from")
            row_yt = row.get("year_to")
            row_aliases = [str(a) for a in _as_list(row.get("aliases")) if isinstance(a, str)]
            for pid in cat_ids_for_row:
                if pid in catalog_profiles_by_id:
                    cat_prof = catalog_profiles_by_id[pid]
                    cat_status = _text(cat_prof.get("status"))
                    if disposition in {"transport-blocked", "identity-only", "no-source"} and cat_status in {"community", "ready"}:
                        issues.append(
                            f"research row {row_id}: disposition={disposition} conflicts with catalog profile {pid} status={cat_status}"
                        )
                    row_make = row_id.split("-")[0]
                    cat_make = _text(cat_prof.get("make")) or pid.split("-")[0]
                    norm_row_make = normalize_brand(row_make)
                    norm_cat_make = normalize_brand(cat_make)
                    row_makes = {norm_row_make}
                    if "hyundai-kia" in row_id:
                        row_makes.update({"hyundai", "kia"})
                    if norm_cat_make not in row_makes:
                        issues.append(
                            f"research row {row_id}: incorrect join with catalog profile {pid} (brand mismatch {row_make} != {cat_make.lower()})"
                        )
                        continue

                    # Model check
                    cat_model = _text(cat_prof.get("model")) or (pid.split("-")[1] if len(pid.split("-")) > 1 else "")
                    clean_cat_model = _norm_token(cat_model)
                    clean_row_id = _norm_token(row_id)
                    clean_aliases = [_norm_token(a) for a in row_aliases]
                    all_targets = [clean_row_id] + clean_aliases

                    model_words = [
                        w for w in re.split(r"[^a-z0-9]", cat_model.lower())
                        if len(w) >= 2 and w not in {"fwd", "awd", "rwd", "bev", "phev", "ev", "gen1", "gen2", "long", "range", "us", "eu", "uk", "60", "63kwh", "kwh", "ah"}
                    ]
                    model_matches = any(clean_cat_model in tgt for tgt in all_targets) or \
                                    any(w in tgt for w in model_words for tgt in all_targets)
                    if not model_matches:
                        issues.append(
                            f"research row {row_id}: incorrect join with catalog profile {pid} (model mismatch {row_id} does not match model {cat_model})"
                        )

                    # Year range overlap check
                    cat_yf = cat_prof.get("year_from")
                    cat_yt = cat_prof.get("year_to")
                    if (
                        isinstance(row_yf, int)
                        and isinstance(row_yt, int)
                        and isinstance(cat_yf, int)
                        and isinstance(cat_yt, int)
                    ):
                        if row_yf > cat_yt or cat_yf > row_yt:
                            issues.append(
                                f"research row {row_id}: incorrect join with catalog profile {pid} (year range {row_yf}-{row_yt} does not overlap with profile {cat_yf}-{cat_yt})"
                            )
    return issues


def validate_repo(repo_root: Path | None = None) -> list[str]:
    root = repo_root if repo_root is not None else REPO_ROOT
    catalog_path = (
        root / "assets" / "powertrain_battery" / "powertrain_battery_catalog.json"
    )
    manifest_path = catalog_path.with_name(
        "powertrain_battery_catalog.manifest.json"
    )
    matrix_path = root / "tool" / "powertrain_evidence" / "matrix.json"
    research_path = root / "tool" / "powertrain_evidence" / "research" / "rows.json"
    catalog_bytes = catalog_path.read_bytes()
    manifest = load_manifest(manifest_path)
    matrix = json.loads(matrix_path.read_bytes().decode("utf-8"))
    if not isinstance(matrix, dict):
        return ["matrix JSON must be an object"]
    research_rows = load_research_rows(research_path)
    return validate_matrix_document(matrix, catalog_bytes, manifest, research_rows)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=None)
    args = parser.parse_args(argv)
    issues = validate_repo(args.repo_root)
    if issues:
        for issue in issues:
            sys.stderr.write(f"{issue}\n")
        return 1
    print("powertrain evidence matrix is valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
