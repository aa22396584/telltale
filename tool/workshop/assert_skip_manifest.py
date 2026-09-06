#!/usr/bin/env python3
"""Compare unittest skips against a committed legitimate-nonapplicable manifest.

Required tests (not listed as nonapplicable on this platform) may not skip.
A skip listed for another platform that fires here is a failure.
The committed JSON must match what the test files actually declare; adding a
``skipUnless`` without updating the manifest fails closed.
"""

from __future__ import annotations

import ast
import json
import pathlib
import sys
import unittest


ROOT_MARKERS = ("tool/", "test/")


def _repo_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[2]


def _skip_reason(decorator: ast.AST) -> str | None:
    if not isinstance(decorator, ast.Call):
        return None
    func = decorator.func
    name = ""
    if isinstance(func, ast.Attribute) and func.attr == "skipUnless":
        name = "skipUnless"
    elif isinstance(func, ast.Attribute) and func.attr == "skipIf":
        name = "skipIf"
    elif isinstance(func, ast.Name) and func.id in {"skipUnless", "skipIf"}:
        name = func.id
    if name != "skipUnless":
        return None
    if len(decorator.args) < 2:
        return None
    reason_node = decorator.args[1]
    if isinstance(reason_node, ast.Constant) and isinstance(reason_node.value, str):
        return reason_node.value
    return None


def _platform_from_compare(test: ast.AST) -> str | None:
    """Best-effort: skipUnless(sys.platform == 'darwin', ...)."""
    if isinstance(test, ast.BoolOp):
        for value in test.values:
            found = _platform_from_compare(value)
            if found:
                return found
        return None
    if not isinstance(test, ast.Compare) or len(test.ops) != 1:
        return None
    if not isinstance(test.ops[0], ast.Eq):
        return None
    left, right = test.left, test.comparators[0]
    names = []
    for node in (left, right):
        if isinstance(node, ast.Attribute) and node.attr == "platform":
            names.append("platform")
        elif isinstance(node, ast.Constant) and isinstance(node.value, str):
            names.append(node.value)
    if "platform" in names and len(names) == 2:
        return names[0] if names[1] == "platform" else names[1]
    return None


def discover(root: pathlib.Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for path in sorted(root.glob("tool/**/test_*.py")):
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        rel = path.relative_to(root).as_posix()
        for node in ast.walk(tree):
            if not isinstance(node, ast.FunctionDef) or not node.name.startswith("test_"):
                continue
            class_name = ""
            # filled below via parent walk — use enclosing ClassDef
        for class_node in ast.walk(tree):
            if not isinstance(class_node, ast.ClassDef):
                continue
            for func in class_node.body:
                if not isinstance(func, ast.FunctionDef) or not func.name.startswith("test_"):
                    continue
                decorators = list(func.decorator_list) + list(class_node.decorator_list)
                platform = None
                reason = None
                for dec in decorators:
                    if not isinstance(dec, ast.Call):
                        continue
                    maybe_reason = _skip_reason(dec)
                    if maybe_reason is None:
                        continue
                    reason = maybe_reason
                    if dec.args:
                        platform = _platform_from_compare(dec.args[0])
                if reason is None:
                    continue
                test_id = f"{path.stem}.{class_node.name}.{func.name}"
                entries.append(
                    {
                        "id": test_id,
                        "file": rel,
                        "reason": reason,
                        "applicable_platforms": [platform] if platform else [],
                    }
                )
    entries.sort(key=lambda row: str(row["id"]))
    return entries


def load_manifest(path: pathlib.Path) -> list[dict[str, object]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    entries = payload["entries"]
    if not isinstance(entries, list):
        raise SystemExit("manifest entries must be a list")
    return entries


def main(argv: list[str]) -> int:
    root = _repo_root()
    manifest_path = root / "tool/workshop/skip_manifest.json"
    discovered = discover(root)
    if argv[1:] == ["--dump"]:
        json.dump({"version": 1, "entries": discovered}, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0
    committed = load_manifest(manifest_path)
    disc_ids = [row["id"] for row in discovered]
    man_ids = [row["id"] for row in committed]
    if disc_ids != man_ids:
        print("FAIL: skip manifest does not match skipUnless declarations.", file=sys.stderr)
        missing = [i for i in disc_ids if i not in man_ids]
        extra = [i for i in man_ids if i not in disc_ids]
        if missing:
            print("  undeclared in JSON:", *missing, sep="\n    ", file=sys.stderr)
        if extra:
            print("  extra in JSON:", *extra, sep="\n    ", file=sys.stderr)
        return 1
    host = sys.platform
    required_skipped: list[str] = []
    # Optional: a unittest stream on stdin is not used here. Host check is
    # applied when --unittest-output FILE is passed.
    if len(argv) >= 3 and argv[1] == "--unittest-output":
        output = pathlib.Path(argv[2]).read_text(encoding="utf-8", errors="replace")
        allowed = {
            str(row["id"])
            for row in committed
            if row.get("applicable_platforms")
            and host not in row["applicable_platforms"]
        }
        # unittest -v prints "test_foo (module.Class.test_foo) ... skipped"
        for line in output.splitlines():
            if "skipped" not in line.lower():
                continue
            matched = None
            for row in committed:
                ident = str(row["id"])
                if ident in line or ident.split(".")[-1] in line:
                    matched = ident
                    break
            if matched is None:
                # also match class-less ids
                print(f"FAIL: unlisted skip: {line}", file=sys.stderr)
                return 1
            if matched not in allowed:
                required_skipped.append(matched)
        if required_skipped:
            print(
                "FAIL: required tests skipped on "
                f"{host}: {required_skipped}",
                file=sys.stderr,
            )
            return 1
    print(f"OK: {len(committed)} legitimate-nonapplicable skip(s) catalogued.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
