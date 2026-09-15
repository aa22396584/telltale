#!/usr/bin/env python3
"""Unit tests for Mode 08 replay reference server."""

from __future__ import annotations

import asyncio
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

from mode08_replay_reference import (
    IDENTITY,
    VERSION,
    AdapterState,
    ReplayServer,
    compute_file_hash,
)

FIXTURES_PATH = os.path.join(os.path.dirname(__file__), "mode08_replay_fixtures.json")


class Mode08ReplayReferenceTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        self.fixtures_path = FIXTURES_PATH
        self.server = ReplayServer(self.fixtures_path)

    def test_fixture_hash_is_computed_correctly(self) -> None:
        hash_val = compute_file_hash(self.fixtures_path)
        self.assertEqual(len(hash_val), 64)
        self.assertEqual(self.server.file_hash, hash_val)

    def test_identity_banner(self) -> None:
        self.assertEqual(IDENTITY, "Telltale Mode 08 Replay Reference")

    async def test_scenario_switching_and_steps(self) -> None:
        state = AdapterState()
        state.headers = True

        class DummyWriter:
            def __init__(self) -> None:
                self.output = []
                self.closed = False

            def write(self, data: bytes) -> None:
                self.output.append(data)

            async def drain(self) -> None:
                pass

            def close(self) -> None:
                self.closed = True

            async def wait_closed(self) -> None:
                pass

        writer = DummyWriter()

        # 1. AT@1
        await self.server.process_command("AT@1", state, writer)
        self.assertTrue(any(IDENTITY.encode("ascii") in b for b in writer.output))
        writer.output.clear()

        # 2. AT#HASH
        await self.server.process_command("AT#HASH", state, writer)
        self.assertTrue(any(self.server.file_hash.encode("ascii") in b for b in writer.output))
        writer.output.clear()

        # 3. Switch scenario to normal_headered_multi_block
        await self.server.process_command("AT#SCENARIO normal_headered_multi_block", state, writer)
        self.assertEqual(state.active_scenario_id, "normal_headered_multi_block")
        self.assertEqual(state.step_index, 0)
        writer.output.clear()

        # 4. First step: 0800
        await self.server.process_command("0800", state, writer)
        self.assertEqual(state.step_index, 1)
        self.assertTrue(any(b"7E8 06 48 00 80 00 00 01" in b for b in writer.output))
        writer.output.clear()

        # 5. Second step: 0820
        await self.server.process_command("0820", state, writer)
        self.assertEqual(state.step_index, 2)
        self.assertTrue(any(b"7E8 06 48 20 40 00 00 00" in b for b in writer.output))
        writer.output.clear()

    async def test_drop_connection_step(self) -> None:
        state = AdapterState()
        state.active_scenario_id = "lifecycle_disconnect_in_flight"

        class DummyWriter:
            def __init__(self) -> None:
                self.output = []
                self.closed = False

            def write(self, data: bytes) -> None:
                self.output.append(data)

            async def drain(self) -> None:
                pass

            def close(self) -> None:
                self.closed = True

            async def wait_closed(self) -> None:
                pass

        writer = DummyWriter()

        # Step 1: 0800
        should_close = await self.server.process_command("0800", state, writer)
        self.assertFalse(should_close)
        self.assertFalse(writer.closed)

        # Step 2: 0820 should drop connection
        should_close = await self.server.process_command("0820", state, writer)
        self.assertTrue(should_close)
        self.assertTrue(writer.closed)

    def test_unsupported_version_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["version"] = "999.0.0"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("Unsupported fixture schema version", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_missing_required_top_level_field_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        del data["provenance"]
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("Missing required top-level fixture field", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_duplicate_scenario_id_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["scenarios"].append(dict(data["scenarios"][0]))
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("Duplicate scenario ID", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_invalid_chunk_sizes_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["scenarios"][0]["steps"][0]["chunk_sizes"] = [0, -1]
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("invalid chunk size", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_missing_expected_outcome_per_ecu_block_results_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        del data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"]
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("missing required field: perEcuBlockResults", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_invalid_per_ecu_block_structure_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"] = "not_a_dict"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("perEcuBlockResults must be an object", str(ctx.exception))
        finally:
            os.unlink(tmp_path)


    def test_missing_block_supported_tids_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        del data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"]["7E8"]["0"]["supportedTids"]
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("missing 'supportedTids'", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_missing_block_support_status_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        del data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"]["7E8"]["0"]["supportStatus"]
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("missing 'supportStatus'", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_invalid_block_support_status_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"]["7E8"]["0"]["supportStatus"] = "invalid_status"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("invalid 'supportStatus'", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_invalid_block_supported_tids_type_is_rejected(self) -> None:
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["scenarios"][0]["expected_outcome"]["perEcuBlockResults"]["7E8"]["0"]["supportedTids"] = "not_a_list"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("'supportedTids' must be a list", str(ctx.exception))
        finally:
            os.unlink(tmp_path)

    def test_subprocess_unsupported_version_specific_error(self) -> None:
        import json
        import subprocess
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["version"] = "999.0.0"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            res = subprocess.run(
                [sys.executable, "tool/obd_test_rig/mode08_replay_reference.py", "--fixtures", tmp_path],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.exitCode if hasattr(res, 'exitCode') else res.returncode, 2)
            self.assertIn("Unsupported fixture schema version: '999.0.0'", res.stderr)
        finally:
            os.unlink(tmp_path)

    def test_subprocess_positive_control_starts_cleanly(self) -> None:
        import subprocess
        proc = subprocess.Popen(
            [sys.executable, "tool/obd_test_rig/mode08_replay_reference.py", "--fixtures", self.fixtures_path, "--port", "0"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        try:
            line = proc.stdout.readline() if proc.stdout else ""
            self.assertIn("Mode 08 replay reference listening on", line)
            self.assertIn("hash:", line)
        finally:
            if proc.stdout:
                proc.stdout.close()
            if proc.stderr:
                proc.stderr.close()
            proc.terminate()
            proc.wait(timeout=5)

    def test_version_guard_causal_isolation(self) -> None:
        """Confirms that if the version guard is bypassed, an otherwise-valid fixture passes validation."""
        import json
        with open(self.fixtures_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["version"] = "999.0.0"
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            json.dump(data, tmp)
            tmp_path = tmp.name
        try:
            # 1. With normal version guard: fails with Unsupported fixture schema version
            with self.assertRaises(ValueError) as ctx:
                ReplayServer(tmp_path)
            self.assertIn("Unsupported fixture schema version", str(ctx.exception))

            # 2. When version guard is bypassed (e.g. 999.0.0 temporarily added to supported versions):
            from mode08_replay_reference import SUPPORTED_SCHEMA_VERSIONS
            SUPPORTED_SCHEMA_VERSIONS.add("999.0.0")
            try:
                # Must initialize cleanly without any schema error, proving no missing fields masked the check
                bypassed_server = ReplayServer(tmp_path)
                self.assertEqual(len(bypassed_server.scenarios), 10)
            finally:
                SUPPORTED_SCHEMA_VERSIONS.discard("999.0.0")
        finally:
            os.unlink(tmp_path)


if __name__ == "__main__":
    unittest.main()

