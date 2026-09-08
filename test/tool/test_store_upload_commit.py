#!/usr/bin/env python3
"""Drive store/upload.sh commit outcomes through a fake gplay CLI."""

from __future__ import annotations

import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "store" / "upload.sh"
FAKE_GPLAY = r'''#!/usr/bin/env python3
import json, os, sys, time
from pathlib import Path

log = Path(os.environ["FAKE_GPLAY_LOG"])
mode = os.environ["FAKE_GPLAY_MODE"]
argv = sys.argv[1:]
log.write_text(log.read_text() + " ".join(argv) + "\n") if log.exists() else log.write_text(" ".join(argv) + "\n")

def is_cmd(*parts):
    return argv[: len(parts)] == list(parts)

if is_cmd("edits", "create"):
    print(json.dumps({"id": "edit-test-1"}))
    sys.exit(0)

if is_cmd("sync", "import-listings") or is_cmd("sync", "import-images"):
    if mode == "importfail" and is_cmd("sync", "import-listings"):
        print("import refused", file=sys.stderr)
        sys.exit(1)
    sys.exit(0)

if is_cmd("edits", "commit"):
    accepted = Path(os.environ["FAKE_GPLAY_ACCEPTED"])
    if mode == "success":
        accepted.write_text("accepted\n")
        print(json.dumps({"id": "edit-test-1", "status": "COMMITTED"}))
        sys.exit(0)
    if mode == "reject":
        # A refuse is not an accepted commit. Writing this marker first made
        # the reject test look like a lost success.
        msg = os.environ.get("FAKE_GPLAY_COMMIT_OUT", "")
        if msg:
            print(msg, file=sys.stderr)
        else:
            print(json.dumps({
                "error": {
                    "code": 403,
                    "status": "PERMISSION_DENIED",
                    "message": "The caller does not have permission",
                }
            }), file=sys.stderr)
        sys.exit(1)
    if mode.startswith("timeout"):
        accepted.write_text("accepted\n")
        time.sleep(0.05)
        msg = os.environ.get("FAKE_GPLAY_COMMIT_OUT", "")
        if msg:
            print(msg, file=sys.stderr)
        sys.exit(28)
    sys.exit(1)

if is_cmd("edits", "delete"):
    accepted = Path(os.environ["FAKE_GPLAY_ACCEPTED"])
    if accepted.exists():
        print("404 Not Found: edit already committed or gone", file=sys.stderr)
        sys.exit(1)
    sys.exit(0)

print("unhandled", argv, file=sys.stderr)
sys.exit(2)
'''


class StoreUploadCommitTest(unittest.TestCase):
    def _run(
        self,
        mode: str,
        apply: bool = True,
        commit_out: str = "",
    ) -> subprocess.CompletedProcess:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        gplay = bin_dir / "gplay"
        gplay.write_text(FAKE_GPLAY, encoding="utf-8")
        gplay.chmod(gplay.stat().st_mode | stat.S_IEXEC)
        log = root / "gplay.log"
        accepted = root / "accepted"
        env = os.environ.copy()
        env["PATH"] = f"{bin_dir}{os.pathsep}{env.get('PATH', '')}"
        env["FAKE_GPLAY_MODE"] = mode
        env["FAKE_GPLAY_LOG"] = str(log)
        env["FAKE_GPLAY_ACCEPTED"] = str(accepted)
        if commit_out:
            env["FAKE_GPLAY_COMMIT_OUT"] = commit_out
        args = [str(SCRIPT)]
        if apply:
            args.append("--apply")
        result = subprocess.run(
            args,
            cwd=REPO,
            env=env,
            capture_output=True,
            text=True,
        )
        result.log = log.read_text() if log.exists() else ""  # type: ignore[attr-defined]
        result.accepted = accepted.exists()  # type: ignore[attr-defined]
        return result

    def test_success_commits(self) -> None:
        result = self._run("success")
        combined = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, combined)
        self.assertIn("committed", result.stdout)
        self.assertNotIn("nothing reached the store", combined)
        self.assertNotIn("edits delete", result.log)

    def test_explicit_reject_does_not_look_like_unknown(self) -> None:
        result = self._run("reject")
        combined = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refused", combined)
        self.assertNotIn("nothing reached the store", combined)
        self.assertNotIn("result is unknown", combined)
        self.assertFalse(result.accepted)
        self.assertIn("edits delete", result.log)

    def test_timeout_after_accept_is_unknown_and_keeps_edit(self) -> None:
        result = self._run("timeout")
        combined = result.stdout + result.stderr
        self.assertEqual(result.returncode, 28, combined)
        self.assertTrue(result.accepted)
        self.assertIn("result is unknown", combined)
        self.assertIn("edit-test-1", combined)
        self.assertNotIn("nothing reached the store", combined)
        self.assertNotIn("edits delete", result.log)
        self.assertIn("Not discarding", combined)

    def test_timeout_digits_are_not_a_documented_refusal(self) -> None:
        cases = (
            "timeout after 4000 ms while waiting for commit response",
            "timeout while committing edit 123403999",
            "connection reset by peer proxy.local:4090",
            # Same googleapi prefix, but 4000 is not a documented refuse code.
            "googleapi: Error 4000: timeout while waiting for commit response",
        )
        for msg in cases:
            with self.subTest(msg=msg):
                result = self._run("timeout", commit_out=msg)
                combined = result.stdout + result.stderr
                self.assertEqual(result.returncode, 28, combined)
                self.assertTrue(result.accepted)
                self.assertIn("result is unknown", combined)
                self.assertNotIn("did not become the store listing", combined)
                self.assertNotIn("nothing reached the store", combined)
                self.assertNotIn("edits delete", result.log)

    def test_documented_googleapi_error_line_is_a_refusal(self) -> None:
        # gplay 1.0.0 embeds `googleapi: Error %d: %s`; the maintainer log
        # prefixes it with `Error: `. Either form is a refuse. Digits in
        # free text are covered by test_timeout_digits_are_not_a_documented_refusal.
        cases = (
            "Error: googleapi: Error 403: The caller does not have permission",
            "Error: googleapi: Error 400: This Edit has been deleted., failedPrecondition",
        )
        for msg in cases:
            with self.subTest(msg=msg):
                result = self._run("reject", commit_out=msg)
                combined = result.stdout + result.stderr
                self.assertNotEqual(result.returncode, 0, combined)
                self.assertIn("did not become the store listing", combined)
                self.assertNotIn("result is unknown", combined)
                self.assertFalse(result.accepted)
                self.assertIn("edits delete", result.log)

    def test_string_error_code_is_not_a_documented_refusal(self) -> None:
        result = self._run(
            "timeout",
            commit_out='{"error":{"code":"403","message":"timeout after 4000 ms"}}',
        )
        combined = result.stdout + result.stderr
        self.assertEqual(result.returncode, 28, combined)
        self.assertTrue(result.accepted)
        self.assertIn("result is unknown", combined)
        self.assertNotIn("did not become the store listing", combined)
        self.assertNotIn("edits delete", result.log)

    def test_import_failure_discards_before_commit(self) -> None:
        result = self._run("importfail")
        combined = result.stdout + result.stderr
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("edits commit", result.log)
        self.assertIn("edits delete", result.log)
        self.assertNotIn("nothing reached the store", combined)

    def test_dry_run_does_not_commit(self) -> None:
        result = self._run("success", apply=False)
        combined = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, combined)
        self.assertIn("dry run", combined)
        self.assertNotIn("edits commit", result.log)
        self.assertIn("edits delete", result.log)


if __name__ == "__main__":
    unittest.main()
