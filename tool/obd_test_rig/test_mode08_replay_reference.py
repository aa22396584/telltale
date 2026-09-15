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


if __name__ == "__main__":
    unittest.main()
