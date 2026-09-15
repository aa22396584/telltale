#!/usr/bin/env python3
"""Project-owned Mode 08 replay reference server for Acceptance Gate 1.

Speaks ELM327 TCP protocol and replays pre-recorded / synthetic Mode 08 transcripts
without calculating or coupling to production codec logic.
"""

from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
import signal
import sys
import time
from typing import Any, Dict, List, Optional

IDENTITY = "Telltale Mode 08 Replay Reference"
VERSION = "ELM327 v1.5"
SUPPORTED_SCHEMA_VERSIONS = {"1.0.0"}


def compute_file_hash(path: str) -> str:
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def validate_fixtures_data(data: Any) -> None:
    if not isinstance(data, dict):
        raise ValueError("Fixtures JSON root must be an object")
    version = data.get("version")
    if version not in SUPPORTED_SCHEMA_VERSIONS:
        raise ValueError(
            f"Unsupported fixture schema version: {version!r} (supported: {sorted(SUPPORTED_SCHEMA_VERSIONS)})"
        )
    for req_field in ["version", "name", "provenance", "description", "scenarios"]:
        if req_field not in data:
            raise ValueError(f"Missing required top-level fixture field: {req_field}")
    scenarios = data.get("scenarios")
    if not isinstance(scenarios, list) or not scenarios:
        raise ValueError("Fixture must contain a non-empty 'scenarios' list")
    seen_ids = set()
    for idx, s in enumerate(scenarios):
        if not isinstance(s, dict):
            raise ValueError(f"Scenario at index {idx} must be an object")
        sid = s.get("id")
        if not sid or not isinstance(sid, str):
            raise ValueError(f"Scenario at index {idx} missing valid 'id'")
        if sid in seen_ids:
            raise ValueError(f"Duplicate scenario ID found: {sid}")
        seen_ids.add(sid)
        for req_scen_field in ["id", "dimension", "description", "steps", "expected_outcome"]:
            if req_scen_field not in s:
                raise ValueError(f"Scenario {sid} missing required field: {req_scen_field}")
        steps = s.get("steps")
        if not isinstance(steps, list) or not steps:
            raise ValueError(f"Scenario {sid} steps must be a non-empty list")
        for s_idx, step in enumerate(steps):
            if not isinstance(step, dict):
                raise ValueError(f"Scenario {sid} step {s_idx} must be an object")
            if "command" not in step:
                raise ValueError(f"Scenario {sid} step {s_idx} missing 'command'")
            if not step.get("drop_connection") and "lines" not in step:
                raise ValueError(f"Scenario {sid} step {s_idx} must have 'lines' or 'drop_connection'")
            chunk_sizes = step.get("chunk_sizes")
            if chunk_sizes is not None:
                if not isinstance(chunk_sizes, list) or not chunk_sizes:
                    raise ValueError(f"Scenario {sid} step {s_idx} chunk_sizes must be non-empty list")
                for c in chunk_sizes:
                    if not isinstance(c, int) or c <= 0:
                        raise ValueError(f"Scenario {sid} step {s_idx} has invalid chunk size: {c}")
        exp = s.get("expected_outcome")
        if not isinstance(exp, dict):
            raise ValueError(f"Scenario {sid} expected_outcome must be an object")
        for req_exp_field in [
            "isSupported",
            "supportStatus",
            "supportedTids",
            "isComplete",
            "unqueriedBlocks",
            "trustedEcus",
            "hasAnonymous",
            "perEcuBlockResults",
        ]:
            if req_exp_field not in exp:
                raise ValueError(f"Scenario {sid} expected_outcome missing required field: {req_exp_field}")
        if not isinstance(exp["perEcuBlockResults"], dict):
            raise ValueError(f"Scenario {sid} perEcuBlockResults must be an object")
        for ecu_id, blocks in exp["perEcuBlockResults"].items():
            if not isinstance(blocks, dict):
                raise ValueError(f"Scenario {sid} perEcuBlockResults for ECU {ecu_id} must be an object")
            for block_id, bdata in blocks.items():
                if not isinstance(bdata, dict):
                    raise ValueError(f"Scenario {sid} perEcuBlockResults for ECU {ecu_id} block {block_id} must be an object")
                if "supportStatus" not in bdata:
                    raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} missing 'supportStatus'")
                if bdata["supportStatus"] not in ["supported", "unsupported", "partiallySupported", "unknown"]:
                    raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} invalid 'supportStatus': {bdata['supportStatus']!r}")
                if "supportedTids" not in bdata:
                    raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} missing 'supportedTids'")
                if not isinstance(bdata["supportedTids"], list):
                    raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} 'supportedTids' must be a list")
                for tid in bdata["supportedTids"]:
                    if not isinstance(tid, int) or tid < 0:
                        raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} invalid TID in 'supportedTids': {tid!r}")
                if "nrc" in bdata and bdata["nrc"] is not None:
                    if not isinstance(bdata["nrc"], int) or bdata["nrc"] < 0:
                        raise ValueError(f"Scenario {sid} ECU {ecu_id} block {block_id} invalid NRC: {bdata['nrc']!r}")



class AdapterState:
    def __init__(self) -> None:
        self.echo = True
        self.linefeeds = True
        self.spaces = True
        self.headers = False
        self.header = "7DF"
        self.active_scenario_id = "normal_headered_single_block"
        self.step_index = 0

    def reset(self) -> None:
        scenario = self.active_scenario_id
        self.__init__()
        self.active_scenario_id = scenario


class ReplayServer:
    def __init__(self, fixtures_path: str, default_scenario: Optional[str] = None, log_file: Optional[str] = None) -> None:
        self.fixtures_path = fixtures_path
        self.file_hash = compute_file_hash(fixtures_path)
        with open(fixtures_path, "r", encoding="utf-8") as f:
            self.fixtures_data = json.load(f)
        validate_fixtures_data(self.fixtures_data)
        self.scenarios: Dict[str, Any] = {
            s["id"]: s for s in self.fixtures_data.get("scenarios", [])
        }
        self.default_scenario = default_scenario or (
            self.fixtures_data.get("scenarios", [{}])[0].get("id", "normal_headered_single_block")
        )
        self.log_file = log_file

    def log_event(self, event_type: str, details: Dict[str, Any]) -> None:
        if not self.log_file:
            return
        payload = {
            "ts": time.time(),
            "event": event_type,
            **details,
        }
        try:
            with open(self.log_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(payload) + "\n")
        except Exception:
            pass

    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        state = AdapterState()
        state.active_scenario_id = self.default_scenario
        addr = writer.get_extra_info("peername")
        self.log_event("connect", {"client": str(addr)})

        buffer = ""
        try:
            while True:
                data = await reader.read(4096)
                if not data:
                    break
                buffer += data.decode("latin1", errors="replace")
                while "\r" in buffer:
                    line, buffer = buffer.split("\r", 1)
                    if buffer.startswith("\n"):
                        buffer = buffer[1:]
                    line = line.strip()
                    if not line:
                        continue
                    should_close = await self.process_command(line, state, writer)
                    if should_close:
                        return
        except asyncio.CancelledError:
            pass
        except Exception as e:
            self.log_event("error", {"error": str(e)})
        finally:
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:
                pass
            self.log_event("disconnect", {"client": str(addr)})

    async def process_command(self, raw_cmd: str, state: AdapterState, writer: asyncio.StreamWriter) -> bool:
        cmd_clean = raw_cmd.strip().upper()
        self.log_event("command", {"command": cmd_clean, "scenario": state.active_scenario_id})

        # Check special control commands
        if raw_cmd.strip().upper().startswith("AT#SCENARIO"):
            parts = raw_cmd.strip().split(None, 1)
            target_id = parts[1].strip() if len(parts) > 1 else ""
            target_id_lower = target_id.lower()
            matching_key = next((k for k in self.scenarios if k.lower() == target_id_lower), None)
            if matching_key:
                state.active_scenario_id = matching_key
                state.step_index = 0
                await self._send_reply(writer, state, "OK", echo=raw_cmd)
            else:
                await self._send_reply(writer, state, "?", echo=raw_cmd)
            return False

        if cmd_clean == "AT#HASH":
            await self._send_reply(writer, state, self.file_hash, echo=raw_cmd)
            return False

        if cmd_clean == "AT#RESET":
            state.step_index = 0
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False

        # Standard AT commands
        compact = cmd_clean.replace(" ", "")
        if compact == "ATZ":
            state.reset()
            await self._send_reply(writer, state, VERSION, echo=raw_cmd)
            return False
        if compact == "ATE0":
            state.echo = False
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATE1":
            state.echo = True
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATL0":
            state.linefeeds = False
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATL1":
            state.linefeeds = True
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATS0":
            state.spaces = False
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATS1":
            state.spaces = True
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATH0":
            state.headers = False
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATH1":
            state.headers = True
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact == "ATI":
            await self._send_reply(writer, state, VERSION, echo=raw_cmd)
            return False
        if compact == "AT@1":
            await self._send_reply(writer, state, IDENTITY, echo=raw_cmd)
            return False
        if compact == "ATRV":
            await self._send_reply(writer, state, "12.6V", echo=raw_cmd)
            return False
        if compact == "ATDP":
            await self._send_reply(writer, state, "ISO 15765-4 (CAN 11/500)", echo=raw_cmd)
            return False
        if compact == "ATDPN":
            await self._send_reply(writer, state, "A6", echo=raw_cmd)
            return False
        if compact.startswith("ATSH"):
            state.header = compact[4:]
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False
        if compact.startswith("AT"):
            await self._send_reply(writer, state, "OK", echo=raw_cmd)
            return False

        # Mode 01 Support Probe (0100) default response if not part of scenario step
        if compact.startswith("0100"):
            scenario = self.scenarios.get(state.active_scenario_id)
            steps = scenario.get("steps", []) if scenario else []
            step_cmd = (
                steps[state.step_index].get("command", "").replace(" ", "").upper()
                if state.step_index < len(steps)
                else ""
            )
            if step_cmd != compact:
                mask_line = "7E8 06 41 00 BE 3F B8 13" if state.headers else "41 00 BE 3F B8 13"
                await self._send_reply(writer, state, mask_line, echo=raw_cmd)
                return False

        # Diagnostic commands (e.g. 0800, 0820, 0100)
        scenario = self.scenarios.get(state.active_scenario_id)
        if not scenario:
            await self._send_reply(writer, state, "NO DATA", echo=raw_cmd)
            return False

        steps = scenario.get("steps", [])
        if state.step_index < len(steps):
            step = steps[state.step_index]
            expected_cmd = step.get("command", "").replace(" ", "").upper()
            if compact == expected_cmd:
                state.step_index += 1
                if step.get("drop_connection"):
                    self.log_event("drop", {"scenario": state.active_scenario_id, "step": state.step_index})
                    writer.close()
                    await writer.wait_closed()
                    return True

                lines = step.get("lines", ["NO DATA"])
                formatted_lines = []
                for line in lines:
                    formatted_line = line
                    if not state.headers:
                        tokens = line.split()
                        if len(tokens) >= 3 and len(tokens[0]) in (3, 8):
                            # Strip header and length tokens if present
                            if len(tokens[1]) in (1, 2):
                                formatted_line = " ".join(tokens[2:])
                            else:
                                formatted_line = " ".join(tokens[1:])
                    if not state.spaces:
                        formatted_line = formatted_line.replace(" ", "")
                    formatted_lines.append(formatted_line)

                body = "\r\n".join(formatted_lines) if state.linefeeds else "\r".join(formatted_lines)
                chunk_sizes = step.get("chunk_sizes")
                delay_ms = step.get("delay_ms", 0)
                await self._send_reply(writer, state, body, echo=raw_cmd, chunk_sizes=chunk_sizes, delay_ms=delay_ms)
                return False

        # Default fallback
        await self._send_reply(writer, state, "NO DATA", echo=raw_cmd)
        return False

    async def _send_reply(
        self,
        writer: asyncio.StreamWriter,
        state: AdapterState,
        body: str,
        *,
        echo: Optional[str] = None,
        chunk_sizes: Optional[List[int]] = None,
        delay_ms: int = 0,
    ) -> None:
        eol = "\r\n" if state.linefeeds else "\r"
        parts = []
        if state.echo and echo is not None:
            parts.append(echo)
        if body:
            parts.append(body)
        parts.append(">")
        full_text = eol.join(parts)
        payload = full_text.encode("ascii", errors="replace")

        if chunk_sizes:
            offset = 0
            chunk_idx = 0
            while offset < len(payload):
                size = chunk_sizes[chunk_idx % len(chunk_sizes)]
                chunk = payload[offset : offset + size]
                writer.write(chunk)
                await writer.drain()
                offset += len(chunk)
                chunk_idx += 1
                if delay_ms > 0 and offset < len(payload):
                    await asyncio.sleep(delay_ms / 1000.0)
        else:
            writer.write(payload)
            await writer.drain()


async def main() -> None:
    parser = argparse.ArgumentParser(description="Mode 08 Replay Reference Server")
    parser.add_argument("--bind", default="127.0.0.1", help="Bind IP (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=35008, help="Listen port (default: 35008)")
    parser.add_argument("--fixtures", default="tool/obd_test_rig/mode08_replay_fixtures.json", help="Path to fixtures JSON")
    parser.add_argument("--log", default=None, help="Path to JSONL log file")
    parser.add_argument("--scenario", default=None, help="Initial active scenario ID")
    args = parser.parse_args()

    if not os.path.isfile(args.fixtures):
        sys.stderr.write(f"Refusing: fixtures file not found at {args.fixtures}\n")
        sys.exit(2)

    try:
        server = ReplayServer(args.fixtures, default_scenario=args.scenario, log_file=args.log)
    except Exception as e:
        sys.stderr.write(f"Refusing: invalid fixtures file ({e})\n")
        sys.exit(2)
    server.log_event("ready", {"hash": server.file_hash, "port": args.port, "scenarios": list(server.scenarios.keys())})

    loop = asyncio.get_running_loop()
    stop_event = asyncio.Event()

    def _sig_handler() -> None:
        stop_event.set()

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _sig_handler)
        except NotImplementedError:
            pass

    async_server = await asyncio.start_server(server.handle_client, args.bind, args.port)
    actual_port = async_server.sockets[0].getsockname()[1] if async_server.sockets else args.port
    server.log_event("ready", {"hash": server.file_hash, "port": actual_port, "scenarios": list(server.scenarios.keys())})
    sys.stdout.write(f"Mode 08 replay reference listening on {args.bind}:{actual_port} (hash: {server.file_hash[:12]})\n")
    sys.stdout.flush()

    try:
        await stop_event.wait()
    finally:
        async_server.close()
        await async_server.wait_closed()


if __name__ == "__main__":
    asyncio.run(main())
