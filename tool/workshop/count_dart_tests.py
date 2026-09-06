#!/usr/bin/env python3
"""Count top-level `test(` calls in a Dart test file.

The CI expected-count is discovered from the file, not typed into the
workflow. Adding a case without updating a magic number is the point;
deleting a case drops the discovered count and still has to actually run.
"""

from __future__ import annotations

import pathlib
import re
import sys

_TEST = re.compile(r"^\s*test\(", re.MULTILINE)


def count_tests(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8")
    stripped_rows = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        stripped_rows.append(line)
    return len(_TEST.findall("\n".join(stripped_rows)))


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: count_dart_tests.py FILE.dart", file=sys.stderr)
        return 2
    path = pathlib.Path(argv[1])
    print(count_tests(path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
