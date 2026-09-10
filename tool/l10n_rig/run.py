#!/usr/bin/env python3
"""#47 l10n_rig lane runner.

`--native-dialog`, `--android-os-locale`, `--overflow`, `--wear` and
`--screenshot` fail closed without an identified device. Combined flags
are mutually exclusive: each requested planted report is deleted and none
of the lanes run. This leftover does not change the phone language,
restart a process, open an OS share chooser, resize a window, open a Wear
emulator, capture a screen, invent a device id, or PASS a host-entry
report.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

from android_os_locale import main as android_os_locale_main
from native_dialog import main as native_dialog_main
from overflow import main as overflow_main
from screenshot import main as screenshot_main
from wear import main as wear_main


_NOT_RUN_LANES = {
    "native-dialog": "native-dialog.json",
    "android-os-locale": "android-os-locale.json",
    "overflow": "overflow.json",
    "wear": "wear.json",
    "screenshot": "screenshot.json",
}


def _unlink_stale(output: Path, filename: str) -> None:
    stale = output / filename
    if stale.exists() or stale.is_symlink():
        stale.unlink()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-dialog", action="store_true")
    parser.add_argument("--android-os-locale", action="store_true")
    parser.add_argument("--overflow", action="store_true")
    parser.add_argument("--wear", action="store_true")
    parser.add_argument("--screenshot", action="store_true")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    chosen = [
        name
        for name, on in (
            ("native-dialog", args.native_dialog),
            ("android-os-locale", args.android_os_locale),
            ("overflow", args.overflow),
            ("wear", args.wear),
            ("screenshot", args.screenshot),
        )
        if on
    ]
    if len(chosen) > 1:
        args.output.mkdir(parents=True, exist_ok=True)
        for name in chosen:
            filename = _NOT_RUN_LANES.get(name)
            if filename is None:
                continue
            _unlink_stale(args.output, filename)
        print("lane flags are mutually exclusive", file=sys.stderr)
        return 2
    if args.native_dialog:
        return native_dialog_main(["--output", str(args.output)])
    if args.android_os_locale:
        return android_os_locale_main(["--output", str(args.output)])
    if args.overflow:
        return overflow_main(["--output", str(args.output)])
    if args.wear:
        return wear_main(["--output", str(args.output)])
    if args.screenshot:
        return screenshot_main(["--output", str(args.output)])
    print(
        "native-dialog, android-os-locale, overflow, wear and screenshot "
        "lanes are not-run without an identified device",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
