#!/usr/bin/env python3
"""#47: compare ARB locales without relying on English fallback.

Fails closed on missing keys, empty values, placeholder name/type drift,
duplicate JSON keys, and malformed JSON. Does not execute Flutter or
rewrite the real ARB files.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

_IDENT_START = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_")
_IDENT = _IDENT_START | set("0123456789")
_PLURAL_TYPES = {"plural", "select", "selectordinal"}


class ArbError(Exception):
    pass


def _message_keys(data: dict[str, Any]) -> set[str]:
    return {key for key in data if not key.startswith("@")}


def _skip_ws(text: str, i: int) -> int:
    n = len(text)
    while i < n and text[i].isspace():
        i += 1
    return i


def _read_ident(text: str, i: int) -> tuple[str, int]:
    n = len(text)
    if i >= n or text[i] not in _IDENT_START:
        return "", i
    j = i + 1
    while j < n and text[j] in _IDENT:
        j += 1
    return text[i:j], j


def _skip_balanced(text: str, i: int) -> int:
    """Skip until the `}` that closes the current argument, not including it."""
    n = len(text)
    depth = 0
    while i < n:
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            if depth == 0:
                return i
            depth -= 1
        i += 1
    return i


def _parse_message(text: str, i: int, names: set[str], *, stop_on_close: bool) -> int:
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "}" and stop_on_close:
            return i
        if ch == "{":
            i = _parse_argument(text, i, names)
        else:
            i += 1
    return i


def _parse_plural_style(text: str, i: int, names: set[str]) -> int:
    n = len(text)
    i = _skip_ws(text, i)
    if text.startswith("offset:", i):
        i = _skip_ws(text, i + 7)
        while i < n and (text[i].isdigit() or text[i] in "+-"):
            i += 1
        i = _skip_ws(text, i)
    while i < n and text[i] != "}":
        i = _skip_ws(text, i)
        if i >= n or text[i] == "}":
            break
        if text[i] == "=":
            i += 1
            while i < n and (text[i].isdigit() or text[i] in "+-"):
                i += 1
        else:
            _, nxt = _read_ident(text, i)
            if nxt == i:
                break
            i = nxt
        i = _skip_ws(text, i)
        if i < n and text[i] == "{":
            i = _parse_message(text, i + 1, names, stop_on_close=True)
            if i < n and text[i] == "}":
                i += 1
        else:
            break
    return i


def _parse_argument(text: str, i: int, names: set[str]) -> int:
    n = len(text)
    if i >= n or text[i] != "{":
        return i + 1
    start = i
    i = _skip_ws(text, i + 1)
    name, i = _read_ident(text, i)
    if not name:
        return start + 1
    i = _skip_ws(text, i)
    if i < n and text[i] == "}":
        names.add(name)
        return i + 1
    if i >= n or text[i] != ",":
        return start + 1
    names.add(name)
    i = _skip_ws(text, i + 1)
    arg_type, i = _read_ident(text, i)
    i = _skip_ws(text, i)
    if i < n and text[i] == ",":
        i = _skip_ws(text, i + 1)
        if arg_type.lower() in _PLURAL_TYPES:
            i = _parse_plural_style(text, i, names)
        else:
            i = _skip_balanced(text, i)
    if i < n and text[i] == "}":
        return i + 1
    return i if i > start else start + 1


def _icu_names(text: str) -> set[str]:
    names: set[str] = set()
    _parse_message(text, 0, names, stop_on_close=False)
    return names


def _placeholders(data: dict[str, Any], key: str) -> dict[str, str]:
    meta = data.get(f"@{key}")
    if not isinstance(meta, dict):
        return {}
    raw = meta.get("placeholders")
    if not isinstance(raw, dict):
        return {}
    types: dict[str, str] = {}
    for name, spec in raw.items():
        if isinstance(spec, dict) and isinstance(spec.get("type"), str):
            types[str(name)] = spec["type"]
        else:
            types[str(name)] = ""
    return types


def _load(path: Path) -> tuple[dict[str, Any] | None, list[str]]:
    errors: list[str] = []

    def hook(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        seen: set[str] = set()
        duplicates: list[str] = []
        out: dict[str, Any] = {}
        for key, value in pairs:
            if key in seen:
                duplicates.append(key)
            seen.add(key)
            out[key] = value
        if duplicates:
            raise ArbError(
                f"{path.name}: duplicate JSON key {duplicates[0]}"
            )
        return out

    try:
        text = path.read_text(encoding="utf-8")
        data = json.loads(text, object_pairs_hook=hook)
    except ArbError as exc:
        return None, [str(exc)]
    except json.JSONDecodeError as exc:
        return None, [f"{path.name}: malformed JSON: {exc.msg}"]
    except OSError as exc:
        return None, [f"{path.name}: cannot read: {exc}"]
    if not isinstance(data, dict):
        return None, [f"{path.name}: ARB must be a JSON object"]
    return data, errors


def check_files(paths: list[Path]) -> list[str]:
    errors: list[str] = []
    loaded: list[tuple[Path, dict[str, Any]]] = []
    for path in paths:
        data, load_errors = _load(path)
        errors.extend(load_errors)
        if data is not None:
            loaded.append((path, data))
    if len(loaded) < 2:
        if not errors:
            errors.append("need at least two ARB files")
        return errors
    key_sets = [(path, _message_keys(data)) for path, data in loaded]
    reference_path, reference_keys = key_sets[0]
    for path, keys in key_sets[1:]:
        missing = sorted(reference_keys - keys)
        extra = sorted(keys - reference_keys)
        for key in missing:
            errors.append(f"{path.name}: missing key {key} (present in {reference_path.name})")
        for key in extra:
            errors.append(f"{reference_path.name}: missing key {key} (present in {path.name})")
    for path, data in loaded:
        for key in sorted(_message_keys(data)):
            value = data.get(key)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path.name}: empty value for {key}")
    template = loaded[0][1]
    for key in sorted(reference_keys):
        expected_meta = _placeholders(template, key)
        template_text = (
            template.get(key) if isinstance(template.get(key), str) else ""
        )
        template_icu = _icu_names(template_text)
        meta_names = set(expected_meta)
        has_meta = f"@{key}" in template
        if has_meta and meta_names != template_icu:
            errors.append(
                f"{loaded[0][0].name}: placeholder names for {key} "
                f"text {sorted(template_icu)} != metadata {sorted(meta_names)}"
            )
        expected_names = meta_names if has_meta else template_icu
        for path, data in loaded[1:]:
            value = data.get(key)
            if not isinstance(value, str):
                continue
            actual_names = _icu_names(value)
            if actual_names != expected_names:
                errors.append(
                    f"{path.name}: placeholder names for {key} "
                    f"{sorted(actual_names)} != {sorted(expected_names)}"
                )
            if f"@{key}" not in data:
                continue
            actual_meta = _placeholders(data, key)
            if set(expected_meta) != set(actual_meta):
                errors.append(
                    f"{path.name}: placeholder metadata for {key} "
                    f"{sorted(actual_meta)} != {sorted(expected_meta)}"
                )
                continue
            for name, expected_type in expected_meta.items():
                got = actual_meta.get(name, "")
                if got != expected_type:
                    errors.append(
                        f"{path.name}: placeholder type {key}.{name} "
                        f"{got!r} != {expected_type!r}"
                    )
    return errors


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: check_arb.py <arb> <arb>...", file=sys.stderr)
        return 2
    errors = check_files([Path(item) for item in argv])
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
