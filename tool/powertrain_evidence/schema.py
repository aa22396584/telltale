#!/usr/bin/env python3
"""Shared schema, canonical JSON, and catalog-derived extract for the matrix.

This module is research tooling. App runtime must not import or bundle it.

Catalog-derived objects are regenerated from
``assets/powertrain_battery/powertrain_battery_catalog.json`` and must not be
hand-edited. Research rows are hand-authored claims in
``research/rows.json``.

Finite research ``disposition`` values:

* ``unknown`` — not yet researched; empty sources are allowed
* ``no-source``
* ``identity-only``
* ``single-family``
* ``transport-blocked``
* ``experimental-candidate``
* ``community-qualified``
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any
from urllib.parse import SplitResult, urlsplit

SCHEMA_VERSION = 1
KIND = "telltale.powertrain_evidence_matrix"

DISPOSITIONS = frozenset(
    {
        "unknown",
        "no-source",
        "identity-only",
        "single-family",
        "transport-blocked",
        "experimental-candidate",
        "community-qualified",
    }
)

CATALOG_STATUSES = frozenset(
    {"ready", "community", "experimental", "researchOnly"}
)

LICENCE_DECISIONS = frozenset(
    {"compatible", "incompatible", "restricted", "not-evaluated"}
)

CATALOG_PRESENCE = frozenset({"present", "absent"})

AGREEING_MARKS = frozenset({"confirmed", "agreeing"})

WIRE_FIELDS = (
    "request_header",
    "expected_responder",
    "service",
    "did",
    "payload_length",
    "formula",
    "signedness",
    "unit",
)

IMMUTABLE_REVISION = re.compile(
    r"^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64}|sha256:[0-9a-fA-F]{64})$"
)
SHA256_HEX = re.compile(r"^[0-9a-f]{64}$")
GITHUB_REPO = re.compile(
    r"^https://(?:www\.)?github\.com/([^/]+)/([^/]+?)(?:\.git)?(?:/|$)",
    re.IGNORECASE,
)
GITHUB_RAW = re.compile(
    r"^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)(?:/|$)",
    re.IGNORECASE,
)
GITHUB_API = re.compile(
    r"^https://api\.github\.com/repos/([^/]+)/([^/]+)(?:/|$)",
    re.IGNORECASE,
)

TOOL_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOL_DIR.parents[1]
CATALOG_PATH = (
    REPO_ROOT / "assets" / "powertrain_battery" / "powertrain_battery_catalog.json"
)
MANIFEST_PATH = CATALOG_PATH.with_name("powertrain_battery_catalog.manifest.json")
MATRIX_PATH = TOOL_DIR / "matrix.json"
RESEARCH_PATH = TOOL_DIR / "research" / "rows.json"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def dump_canonical(value: Any) -> str:
    """UTF-8 JSON, sorted keys, 2-space indent, LF, trailing newline."""
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def write_canonical_json(path: Path, value: Any) -> bytes:
    data = dump_canonical(value).encode("utf-8")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return data


def is_immutable_revision(value: str) -> bool:
    return bool(IMMUTABLE_REVISION.fullmatch(value.strip()))


def is_sha256_hex(value: str) -> bool:
    return bool(SHA256_HEX.fullmatch(value.strip()))


_UNRESERVED_PCT = re.compile(r"%([0-9A-Fa-f]{2})")


def _collapse_dot_segments(path: str) -> str:
    """RFC 3986 remove_dot_segments so ``/x/../a`` and ``/a`` are one path."""
    if not path:
        return path
    leading = path.startswith("/")
    output: list[str] = []
    for segment in path.split("/"):
        if segment in ("", "."):
            continue
        if segment == "..":
            if output:
                output.pop()
            continue
        output.append(segment)
    collapsed = "/".join(output)
    if leading:
        return "/" + collapsed if collapsed else "/"
    return collapsed


def _decode_unreserved_path(path: str) -> str:
    """Decode percent-encoded unreserved characters (RFC 3986)."""

    def _replace(match: re.Match[str]) -> str:
        raw = bytes.fromhex(match.group(1))
        try:
            char = raw.decode("ascii")
        except UnicodeDecodeError:
            return match.group(0)
        if char.isalnum() or char in "-._~":
            return char.lower()
        return match.group(0)

    return _UNRESERVED_PCT.sub(_replace, path)


def _idna_host(host: str) -> str:
    """One IDNA/ASCII form so ``bücher.example`` and ``xn--bcher-kva.example`` match."""
    if not host:
        return host
    try:
        return host.encode("idna").decode("ascii")
    except UnicodeError:
        return host


def _canonical_host(host: str) -> str:
    """Lowercase host, drop ``www.`` and a trailing DNS dot (``github.com.``)."""
    host = _idna_host(host.lower().rstrip("."))
    if host.startswith("www."):
        host = host[4:]
    return host


def _safe_source_url_parts(url: str) -> SplitResult | None:
    """Parse a source URL, rejecting malformed ports and percent-bearing hosts."""
    try:
        parts = urlsplit(url.strip())
        # Access validates malformed and out-of-range ports.
        parts.port
    except ValueError:
        return None
    # Percent escapes belong in paths, not publisher identity. Reject a host
    # containing any percent sign instead of decoding the escape or allowing
    # source.name to become a fallback family.
    if "%" in (parts.hostname or ""):
        return None
    return parts


def normalize_source_url(url: str) -> str:
    """Host + path identity, ignoring revision query, fragment, trailing slash, and default ports."""
    parts = _safe_source_url_parts(url)
    if parts is None:
        return ""
    port = parts.port
    host = _idna_host((parts.hostname or "").lower().rstrip("."))
    if not host:
        host = _idna_host((parts.netloc or "").lower().rstrip("."))
        if not host:
            return ""
    else:
        port = parts.port
        scheme = (parts.scheme or "").lower()
        if port is not None and not (
            (scheme == "https" and port == 443) or (scheme == "http" and port == 80)
        ):
            host = f"{host}:{port}"
    path = _collapse_dot_segments(
        _decode_unreserved_path((parts.path or "").lower())
    ).rstrip("/")
    return f"{host}{path}"


def github_org_repo(url: str) -> str | None:
    """Collapse github.com / raw / blob / tree / api URLs to ``org/repo``.

    Authority is parsed first so default ports (``github.com:443``) and
    ``www.`` do not create a distinct family. Revision and path are ignored
    so two files or two revisions in the same repository are one family.
    """
    parts = urlsplit(url.strip())
    host = _canonical_host(parts.hostname or "")
    path = _collapse_dot_segments(_decode_unreserved_path(parts.path or ""))
    segments = [seg for seg in path.split("/") if seg]
    if host == "github.com" and len(segments) >= 2:
        org, repo = segments[0], segments[1]
        if repo.lower().endswith(".git"):
            repo = repo[:-4]
        return f"{org.lower()}/{repo.lower()}"
    if host == "raw.githubusercontent.com" and len(segments) >= 2:
        return f"{segments[0].lower()}/{segments[1].lower()}"
    if host == "api.github.com" and len(segments) >= 3 and segments[0].lower() == "repos":
        return f"{segments[1].lower()}/{segments[2].lower()}"
    text = url.strip()
    for pattern in (GITHUB_REPO, GITHUB_RAW, GITHUB_API):
        match = pattern.match(text)
        if match:
            org = _decode_unreserved_path(match.group(1))
            repo = _decode_unreserved_path(match.group(2))
            return f"{org.lower()}/{repo.lower()}"
    return None


FORGE_HOSTS = frozenset(
    {"gitlab.com", "bitbucket.org", "codeberg.org", "gitea.com", "git.sr.ht"}
)


def forge_org_repo(url: str) -> str | None:
    """Collapse common non-GitHub forge URLs to ``host/org/repo``.

    Path after the repository (blob/tree/src, revision, file) is ignored so
    two files or revisions in the same repository are one family.
    """
    parts = urlsplit(url.strip())
    host = _canonical_host(parts.hostname or "")
    if host not in FORGE_HOSTS:
        return None
    path = _collapse_dot_segments(_decode_unreserved_path(parts.path or ""))
    if host == "gitlab.com":
        head = path.split("/-/")[0]
        segments = [seg.lower() for seg in head.split("/") if seg]
        if segments and segments[-1].endswith(".git"):
            segments[-1] = segments[-1][:-4]
        if len(segments) < 2:
            return None
        return f"{host}/{'/'.join(segments)}"
    segments = [seg for seg in path.split("/") if seg]
    if len(segments) < 2:
        return None
    org, repo = segments[0], segments[1]
    if repo.lower().endswith(".git"):
        repo = repo[:-4]
    return f"{host}/{org.lower()}/{repo.lower()}"


def derive_source_family(source: dict[str, Any]) -> str:
    """Stable family id from source identity, not a free-form label.

    GitHub ``github.com``, ``raw.githubusercontent.com``, and
    ``api.github.com/repos`` URLs become lowercase ``org/repo`` (path and
    revision ignored). Common forges become lowercase ``host/org/repo``.
    Other http(s) URLs become lowercase ``host`` plus path
    (query/fragment/default port ignored). Otherwise ``name`` is used
    (``org/repo`` if it contains a slash). Forks, copies, wrappers, derived
    CSVs, and the same capture are one family when they share that identity.
    """
    url = str(source.get("url") or "").strip()
    if url and _safe_source_url_parts(url) is None:
        return ""
    github = github_org_repo(url)
    if github:
        return github
    forge = forge_org_repo(url)
    if forge:
        return forge
    normalized = normalize_source_url(url)
    if normalized:
        return normalized
    name = str(source.get("name") or "").strip()
    if "/" in name:
        org, repo = name.split("/", 1)
        return f"{org.lower()}/{repo.lower()}"
    return name.lower()


def source_repo_path_key(source: dict[str, Any]) -> str:
    """``family + path`` identity, ignoring revision. Empty if path is missing."""
    family = derive_source_family(source)
    path = str(source.get("path") or "").strip().lower().replace("\\", "/")
    if not family or not path:
        return ""
    return f"{family}\0{path}"


def source_url_key(source: dict[str, Any]) -> str:
    """Normalized URL identity. Empty when the source has no usable URL."""
    return normalize_source_url(str(source.get("url") or ""))


def extract_vehicle_evidence_locator(profile: dict[str, Any]) -> str | None:
    """Retained physical-vehicle locator, if the catalog JSON carries one.

    Schema v3 profiles have no dedicated field today (see
    ``powertrain_battery_profile.dart``). A future ``vehicle_evidence.locator``
    or ``vehicle_evidence_locator`` is preserved so a physically validated
    ``ready`` profile can pass.
    """
    block = profile.get("vehicle_evidence")
    if isinstance(block, dict):
        locator = str(block.get("locator") or "").strip()
        if locator:
            return locator
    locator = str(profile.get("vehicle_evidence_locator") or "").strip()
    return locator or None


def extract_source_family(source: dict[str, Any], role: str) -> dict[str, Any]:
    return {
        "artifact_sha256": str(source.get("artifact_sha256") or ""),
        "family": derive_source_family(source),
        "license": str(source.get("license") or ""),
        "locator": str(source.get("locator") or ""),
        "name": str(source.get("name") or ""),
        "path": str(source.get("path") or ""),
        "revision": str(source.get("revision") or ""),
        "role": role,
        "url": str(source.get("url") or ""),
    }


def extract_profile(profile: dict[str, Any]) -> dict[str, Any]:
    commands = profile.get("commands") or []
    if not isinstance(commands, list):
        commands = []
    families = [extract_source_family(profile.get("source") or {}, "primary")]
    secondaries = profile.get("secondary_sources") or []
    if isinstance(secondaries, list):
        for secondary in secondaries:
            if isinstance(secondary, dict):
                families.append(extract_source_family(secondary, "secondary"))
    families.sort(key=lambda item: (item["role"], item["family"], item["path"]))
    identity = profile.get("identity_evidence")
    identity_out: Any = None
    if isinstance(identity, dict):
        identity_out = {
            "market": identity.get("market"),
            "model": identity.get("model"),
            "variant": identity.get("variant"),
            "year": identity.get("year"),
        }
    return {
        "command_count": len(commands),
        "evidence": str(profile.get("evidence") or ""),
        "identity_evidence": identity_out,
        "market": str(profile.get("market") or ""),
        "profile_id": str(profile.get("id") or ""),
        "source_families": families,
        "status": str(profile.get("status") or ""),
        "variant": str(profile.get("variant") or ""),
        "vehicle_evidence_locator": extract_vehicle_evidence_locator(profile),
        "year_from": profile.get("year_from"),
        "year_to": profile.get("year_to"),
    }


def extract_catalog_section(
    catalog_bytes: bytes, manifest: dict[str, Any]
) -> dict[str, Any]:
    if not isinstance(manifest, dict):
        raise ValueError("manifest JSON must be an object")
    catalog = json.loads(catalog_bytes.decode("utf-8"))
    if not isinstance(catalog, dict):
        raise ValueError("catalog JSON must be an object")
    raw_profiles = catalog.get("profiles")
    if not isinstance(raw_profiles, list):
        raise ValueError("catalog.profiles must be a list")
    profiles = [
        extract_profile(profile)
        for profile in raw_profiles
        if isinstance(profile, dict)
    ]
    profiles.sort(key=lambda item: item["profile_id"])
    return {
        "catalog_file": "powertrain_battery_catalog.json",
        "catalog_sha256": sha256_hex(catalog_bytes),
        "catalog_size_bytes": len(catalog_bytes),
        "manifest_file": "powertrain_battery_catalog.manifest.json",
        "profile_count": len(profiles),
        "profiles": profiles,
        "schema_version": catalog.get("schema_version"),
    }


def load_research_rows(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_bytes().decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("research file must be an object")
    rows = payload.get("rows")
    if not isinstance(rows, list):
        raise ValueError("research.rows must be a list")
    out: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("research.rows entries must be objects")
        out.append(row)
    out.sort(key=lambda row: str(row.get("id") or ""))
    return out


def build_matrix(
    catalog_bytes: bytes,
    manifest: dict[str, Any],
    research_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    rows = sorted(research_rows, key=lambda row: str(row.get("id") or ""))
    return {
        "catalog": extract_catalog_section(catalog_bytes, manifest),
        "kind": KIND,
        "research": rows,
        "schema_version": SCHEMA_VERSION,
    }


def load_manifest(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_bytes().decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("manifest JSON must be an object")
    return payload
