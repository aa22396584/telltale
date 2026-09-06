#!/usr/bin/env python3
"""Unit tests for the project-owned freeze-frame reference."""

from __future__ import annotations

import asyncio
import random
import unittest

from freeze_frame_reference import (
    IDENTITY,
    VIN,
    AdapterState,
    FreezeFrameReference,
    JsonlLog,
    can_lines,
    handle_command,
    parse_args,
)


def _exchange(state: AdapterState, command: str) -> str:
    reply = handle_command(state, command)
    assert reply is not None
    return reply.decode("ascii")


class FramingTest(unittest.TestCase):
    def test_single_frame_headers_match_datasheet_padding(self) -> None:
        lines = can_lines(
            "7E8",
            [0x41, 0x00, 0xBE, 0x3F, 0xB8, 0x13],
            headers=True,
            spaces=True,
        )
        self.assertEqual(lines, ["7E8 06 41 00 BE 3F B8 13 00"])

    def test_iso_tp_first_frame_declares_length(self) -> None:
        payload = [0x43, 0x03, 0x01, 0x33, 0x03, 0x00, 0x04, 0x20]
        lines = can_lines("7E8", payload, headers=True, spaces=True)
        self.assertTrue(lines[0].startswith("7E8 10 08 43 03 01 33 03 00"))
        self.assertTrue(lines[1].startswith("7E8 21 04 20"))

    def test_identity_is_project_owned_not_private_research_banner(self) -> None:
        self.assertEqual(IDENTITY, "Telltale Freeze-Frame Reference")
        self.assertNotIn("Virtual OBD Diagnostic Server", IDENTITY)
        self.assertNotIn("OBDII to RS232 Interpreter", IDENTITY)


class ProtocolTest(unittest.TestCase):
    def setUp(self) -> None:
        self.state = AdapterState(random.Random(0))
        _exchange(self.state, "ATE0")
        _exchange(self.state, "ATL0")
        _exchange(self.state, "ATS0")
        _exchange(self.state, "ATH1")
        _exchange(self.state, "ATSP0")

    def test_at_at1_identity_and_protocol(self) -> None:
        self.assertIn(IDENTITY, _exchange(self.state, "AT@1"))
        self.assertIn("A6", _exchange(self.state, "ATDPN"))
        self.assertIn("ISO 15765-4", _exchange(self.state, "ATDP"))

    def test_mode_02_has_no_support_mask(self) -> None:
        reply = _exchange(self.state, "020000")
        self.assertIn("NO DATA", reply)

    def test_cause_code_is_p0133_on_7e8_only(self) -> None:
        reply = _exchange(self.state, "020200")
        self.assertIn("4202000133", reply.replace(" ", "").upper())
        self.assertIn("7E8", reply)

    def test_missing_cause_on_7e9_is_zeros(self) -> None:
        _exchange(self.state, "ATSH 7E1")
        reply = _exchange(self.state, "020200")
        compact = reply.replace(" ", "").upper()
        self.assertIn("4202000000", compact)
        self.assertNotIn("0133", compact)

    def test_negative_response_on_7ea(self) -> None:
        _exchange(self.state, "ATSH 7E2")
        reply = _exchange(self.state, "020200")
        compact = reply.replace(" ", "").upper()
        self.assertIn("7F0211", compact)

    def test_freeze_rpm_coolant_speed_load_bytes(self) -> None:
        rpm = _exchange(self.state, "020C00")
        self.assertIn("2648", rpm.replace(" ", "").upper())
        coolant = _exchange(self.state, "020500")
        self.assertIn("80", coolant.replace(" ", "").upper())
        speed = _exchange(self.state, "020D00")
        self.assertIn("48", speed.replace(" ", "").upper())
        load = _exchange(self.state, "020400")
        self.assertIn("A7", load.replace(" ", "").upper())

    def test_broadcast_mode_03_includes_every_controller_with_headers(self) -> None:
        _exchange(self.state, "ATSH 7DF")
        reply = _exchange(self.state, "03")
        compact = reply.replace(" ", "").upper()
        self.assertIn("0133", compact)
        self.assertIn("0700", compact)
        self.assertIn("4200", compact)
        self.assertIn("7E8", reply)
        self.assertIn("7E9", reply)
        self.assertIn("7EA", reply)

    def test_physical_mode_03_reaches_other_controllers(self) -> None:
        _exchange(self.state, "ATSH 7E1")
        tcm = _exchange(self.state, "03")
        self.assertIn("0700", tcm.replace(" ", "").upper())
        _exchange(self.state, "ATSH 7E2")
        chassis = _exchange(self.state, "03")
        self.assertIn("4200", chassis.replace(" ", "").upper())

    def test_pending_and_permanent(self) -> None:
        pending = _exchange(self.state, "07")
        self.assertIn("0171", pending.replace(" ", "").upper())
        self.assertIn("NO DATA", _exchange(self.state, "0A"))

    def test_vin_reassembly_bytes(self) -> None:
        from freeze_frame_reference import vin_payload

        payload = vin_payload(VIN)
        self.assertEqual(bytes(payload[3:]).decode("ascii"), VIN)
        self.assertEqual(payload[:3], [0x49, 0x02, 0x01])
        reply = _exchange(self.state, "0902")
        self.assertIn("490201", reply.replace(" ", "").upper())
        self.assertEqual(len(VIN), 17)

    def test_census_three_controllers_when_headers_on(self) -> None:
        reply = _exchange(self.state, "0100")
        self.assertIn("7E8", reply)
        self.assertIn("7E9", reply)
        self.assertIn("7EA", reply)

    def test_same_pid_differs_per_ecu(self) -> None:
        reply = _exchange(self.state, "010C")
        compact = reply.replace(" ", "").upper()
        self.assertIn("2648", compact)
        self.assertIn("1234", compact)

    def test_mil_readiness_bytes(self) -> None:
        reply = _exchange(self.state, "0101")
        self.assertIn("8307E500", reply.replace(" ", "").upper())

    def test_drop_control_uses_spaces_and_is_not_stripped(self) -> None:
        self.assertIn("OK", _exchange(self.state, "AT#DROP RATE 0.85"))
        self.assertEqual(self.state.drop_rate, 0.85)
        self.assertIn("OK", _exchange(self.state, "AT#DROP NONE"))
        self.assertEqual(self.state.drop_rate, 0.0)
        self.assertIn("?", _exchange(self.state, "AT#DROPRATE0.85"))

    def test_atz_clears_drop_rate(self) -> None:
        _exchange(self.state, "AT#DROP RATE 0.85")
        _exchange(self.state, "ATZ")
        self.assertEqual(self.state.drop_rate, 0.0)


class SocketTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.logger = JsonlLog(None)
        self.server = FreezeFrameReference("127.0.0.1", 0, self.logger, random.Random(1))
        await self.server.start()

    async def asyncTearDown(self) -> None:
        await self.server.close()

    async def _session(self) -> tuple[asyncio.StreamReader, asyncio.StreamWriter]:
        return await asyncio.open_connection(*self.server.address)

    async def test_parallel_control_socket_does_not_steal_data_client(self) -> None:
        reader, writer = await self._session()
        writer.write(b"ATE0\r")
        await writer.drain()
        await asyncio.wait_for(reader.readuntil(b">"), 1)
        control_r, control_w = await self._session()
        control_w.write(b"AT#DROP RATE 0.85\r")
        await control_w.drain()
        reply = await asyncio.wait_for(control_r.readuntil(b">"), 1)
        self.assertIn(b"OK", reply)
        control_w.close()
        await control_w.wait_closed()
        writer.write(b"AT@1\r")
        await writer.drain()
        identity = await asyncio.wait_for(reader.readuntil(b">"), 1)
        self.assertIn(IDENTITY.encode(), identity)
        writer.close()
        await writer.wait_closed()

    async def test_bind_refuses_non_loopback(self) -> None:
        with self.assertRaises(SystemExit):
            parse_args(["--bind", "0.0.0.0", "--port", "35000"])


class LoopbackBindTest(unittest.TestCase):
    def test_cli_default_is_loopback(self) -> None:
        args = parse_args([])
        self.assertEqual(args.bind, "127.0.0.1")
        self.assertEqual(args.port, 35000)


if __name__ == "__main__":
    unittest.main()
