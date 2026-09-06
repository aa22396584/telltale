#!/usr/bin/env python3
"""Project-owned ELM327 TCP reference for freeze-frame, multi-ECU, and readiness.

This is not a third-party oracle. AT@1 answers
``Telltale Freeze-Frame Reference``. It must not be confused with Ircama
(``OBDII to RS232 Interpreter``) or with any private research server.

The vehicle fixture is original to this repository and is sized to the public
``test/freeze_frame_oracle_test.dart`` contract: Mode 02 data PIDs without a
support mask, P0133 as the causing code, three controllers on 11-bit CAN, and
an ``AT#`` control plane on a parallel socket.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import random
import signal
import sys
import time
from dataclasses import dataclass, field
from typing import Iterable


IDENTITY = "Telltale Freeze-Frame Reference"
VERSION = "ELM327 v1.5"
VIN = "TELLTALE0TEST0001"

# Live Mode 01 PID 0C bytes. 7E8 matches the freeze-frame RPM (2450);
# 7E9 answers a different value so a concatenated read cannot be mistaken
# for a single controller.
RPM_7E8 = (0x26, 0x48)  # 2450 rpm
RPM_7E9 = (0x12, 0x34)  # 1165 rpm


def _hex_byte(value: int) -> str:
    return f"{value:02X}"


def join_hex(parts: Iterable[str], spaces: bool) -> str:
    return " ".join(parts) if spaces else "".join(parts)


def can_lines(
    ecu_id: str,
    payload: list[int],
    *,
    headers: bool,
    spaces: bool,
) -> list[str]:
    """Render one ECU payload the way an ELM327 prints ISO 15765-4 CAN."""
    if not payload:
        return []
    hex_payload = [_hex_byte(b) for b in payload]
    if not headers:
        if len(payload) <= 7:
            return [join_hex(hex_payload, spaces)]
        lines = [f"{len(payload):03X}"]
        index = 0
        seq = 0
        while index < len(hex_payload):
            take = 6 if seq == 0 else 7
            chunk = hex_payload[index : index + take]
            padded = chunk + ["00"] * (take - len(chunk))
            prefix = f"{seq:X}:"
            body = join_hex(padded, spaces)
            lines.append(f"{prefix} {body}" if spaces else f"{prefix}{body}")
            index += take
            seq += 1
        return lines

    if len(payload) <= 7:
        pci = _hex_byte(len(payload) & 0x0F)
        padded = hex_payload + ["00"] * (7 - len(payload))
        return [join_hex([ecu_id, pci, *padded], spaces)]

    lines: list[str] = []
    length = len(payload)
    first = hex_payload[:6]
    first += ["00"] * (6 - len(first))
    pci0 = _hex_byte(0x10 | ((length >> 8) & 0x0F))
    pci1 = _hex_byte(length & 0xFF)
    lines.append(join_hex([ecu_id, pci0, pci1, *first], spaces))
    seq = 1
    index = 6
    while index < len(hex_payload):
        chunk = hex_payload[index : index + 7]
        padded = chunk + ["00"] * (7 - len(chunk))
        pci = _hex_byte(0x20 | (seq & 0x0F))
        lines.append(join_hex([ecu_id, pci, *padded], spaces))
        index += 7
        seq += 1
    return lines


def dtc_payload(mode: int, pairs: list[tuple[int, int]]) -> list[int]:
    body = [mode + 0x40, len(pairs)]
    for high, low in pairs:
        body.extend((high, low))
    return body


def vin_payload(vin: str) -> list[int]:
    return [0x49, 0x02, 0x01, *[ord(ch) for ch in vin]]


@dataclass
class Ecu:
    response_id: str
    physical_header: str
    support_mask: tuple[int, int, int, int]
    stored: list[tuple[int, int]] = field(default_factory=list)
    pending: list[tuple[int, int]] | None = None
    freeze_cause: tuple[int, int] | None = None
    freeze_nrc: int | None = None
    freeze: dict[int, list[int]] = field(default_factory=dict)
    mil: tuple[int, int, int, int] | None = None
    vin: str | None = None
    rpm: tuple[int, int] | None = None


def default_vehicle() -> dict[str, Ecu]:
    return {
        "7E8": Ecu(
            response_id="7E8",
            physical_header="7E0",
            support_mask=(0xBE, 0x3F, 0xB8, 0x13),
            stored=[(0x01, 0x33), (0x03, 0x00), (0x04, 0x20)],
            pending=[(0x01, 0x71), (0x01, 0x74)],
            freeze_cause=(0x01, 0x33),
            freeze={
                0x04: [0xA7],
                0x05: [0x80],
                0x0C: [0x26, 0x48],
                0x0D: [0x48],
            },
            mil=(0x83, 0x07, 0xE5, 0x00),
            vin=VIN,
            rpm=RPM_7E8,
        ),
        "7E9": Ecu(
            response_id="7E9",
            physical_header="7E1",
            support_mask=(0x80, 0x00, 0x00, 0x00),
            stored=[(0x07, 0x00), (0x07, 0x30)],
            freeze_cause=(0x00, 0x00),
            rpm=RPM_7E9,
        ),
        "7EA": Ecu(
            response_id="7EA",
            physical_header="7E2",
            support_mask=(0x80, 0x00, 0x00, 0x00),
            stored=[(0x42, 0x00)],  # C0200
            freeze_nrc=0x11,
        ),
    }


class AdapterState:
    def __init__(self, rng: random.Random | None = None) -> None:
        self.echo = True
        self.linefeeds = True
        self.spaces = True
        self.headers = False
        self.header = "7DF"
        self.protocol_auto = False
        self.searched = False
        self.drop_rate = 0.0
        self.delay_s = 0.0
        self.rng = rng or random.Random()
        self.ecus = default_vehicle()

    def reset(self) -> None:
        drop_rate = self.drop_rate
        delay_s = self.delay_s
        rng = self.rng
        self.__init__(rng)
        self.drop_rate = drop_rate
        self.delay_s = delay_s


def _eol(state: AdapterState) -> str:
    return "\r\n" if state.linefeeds else "\r"


def format_reply(state: AdapterState, body: str, *, echo: str | None = None) -> bytes:
    parts: list[str] = []
    if state.echo and echo is not None:
        parts.append(echo)
    if body:
        parts.append(body)
    parts.append(">")
    return _eol(state).join(parts).encode("ascii")


def _targets(state: AdapterState) -> list[Ecu]:
    header = state.header.upper()
    if header in {"7DF", "7DF0", ""}:
        return list(state.ecus.values())
    for ecu in state.ecus.values():
        if ecu.physical_header == header:
            return [ecu]
    return []


def _broadcast(state: AdapterState) -> bool:
    return state.header.upper() in {"7DF", "7DF0", ""}


def handle_at(state: AdapterState, raw: str) -> str | None:
    compact = raw.upper().replace(" ", "")
    if compact == "ATZ":
        state.reset()
        return VERSION
    if compact == "ATE0":
        state.echo = False
        return "OK"
    if compact == "ATE1":
        state.echo = True
        return "OK"
    if compact == "ATL0":
        state.linefeeds = False
        return "OK"
    if compact == "ATL1":
        state.linefeeds = True
        return "OK"
    if compact == "ATS0":
        state.spaces = False
        return "OK"
    if compact == "ATS1":
        state.spaces = True
        return "OK"
    if compact == "ATH0":
        state.headers = False
        return "OK"
    if compact == "ATH1":
        state.headers = True
        return "OK"
    if compact in {"ATM0", "ATM1", "ATAT1", "ATAT2"}:
        return "OK"
    if compact.startswith("ATST") and len(compact) >= 6:
        return "OK"
    if compact == "ATSP0":
        state.protocol_auto = True
        state.searched = False
        return "OK"
    if compact.startswith("ATSP") and len(compact) == 5:
        return "OK"
    if compact == "ATI":
        return VERSION
    if compact == "AT@1":
        return IDENTITY
    if compact == "ATRV":
        return "12.6V"
    if compact == "ATDP":
        return "ISO 15765-4 (CAN 11/500)"
    if compact == "ATDPN":
        return "A6"
    if compact.startswith("ATSH") and len(compact) > 4:
        state.header = compact[4:]
        return "OK"
    if compact.startswith("AT#"):
        return handle_control(state, raw)
    return "?"


def handle_control(state: AdapterState, raw: str) -> str:
    text = raw.strip().upper()
    if text == "AT#DROP NONE":
        state.drop_rate = 0.0
        return "OK"
    if text.startswith("AT#DROP RATE "):
        try:
            rate = float(raw.strip().split()[-1])
        except ValueError:
            return "?"
        if not 0.0 <= rate <= 1.0:
            return "?"
        state.drop_rate = rate
        return "OK"
    if text.startswith("AT#DELAY "):
        try:
            delay_s = float(raw.strip().split()[-1])
        except ValueError:
            return "?"
        if delay_s < 0:
            return "?"
        state.delay_s = delay_s
        return "OK"
    return "?"


def handle_obd(state: AdapterState, compact: str) -> str | None:
    if len(compact) < 2 or any(ch not in "0123456789ABCDEF" for ch in compact):
        return "?"
    first_probe = not state.searched
    state.searched = True
    mode = compact[:2]
    rest = compact[2:]
    lines: list[str] = []

    def add(ecu: Ecu, payload: list[int]) -> None:
        lines.extend(
            can_lines(
                ecu.response_id,
                payload,
                headers=state.headers,
                spaces=state.spaces,
            )
        )

    targets = _targets(state)
    if not targets:
        return "NO DATA"

    if mode == "01":
        pid = rest[:2] if rest else "00"
        for ecu in targets:
            if pid == "00":
                if not state.headers and ecu.response_id != "7E8":
                    continue
                add(ecu, [0x41, 0x00, *ecu.support_mask])
            elif pid == "01":
                if ecu.mil is None:
                    continue
                add(ecu, [0x41, 0x01, *ecu.mil])
            elif pid == "0C":
                if ecu.rpm is None:
                    continue
                add(ecu, [0x41, 0x0C, *ecu.rpm])
            elif ecu.response_id == "7E8" and pid in {"04", "05", "0D"}:
                freeze = ecu.freeze.get(int(pid, 16))
                if freeze is None:
                    continue
                add(ecu, [0x41, int(pid, 16), *freeze])
        if not lines:
            return "NO DATA"
        body = _eol(state).join(lines)
        if state.protocol_auto and first_probe and compact.startswith("0100"):
            return f"SEARCHING...{_eol(state)}{body}"
        return body

    if mode == "02":
        pid = rest[:2] if len(rest) >= 2 else "00"
        frame = rest[2:4] if len(rest) >= 4 else "00"
        if pid == "00":
            return "NO DATA"
        for ecu in targets:
            if ecu.freeze_nrc is not None and pid == "02":
                add(ecu, [0x7F, 0x02, ecu.freeze_nrc])
                continue
            if pid == "02":
                cause = ecu.freeze_cause
                if cause is None:
                    continue
                add(ecu, [0x42, 0x02, int(frame, 16), cause[0], cause[1]])
                continue
            data = ecu.freeze.get(int(pid, 16))
            if data is None:
                continue
            add(ecu, [0x42, int(pid, 16), int(frame, 16), *data])
        return _eol(state).join(lines) if lines else "NO DATA"

    if mode == "03":
        for ecu in targets:
            if not ecu.stored:
                continue
            if not state.headers and ecu.response_id != "7E8":
                continue
            add(ecu, dtc_payload(0x03, ecu.stored))
        return _eol(state).join(lines) if lines else "NO DATA"

    if mode == "07":
        for ecu in targets:
            if not ecu.pending:
                continue
            if _broadcast(state) and ecu.response_id != "7E8":
                continue
            add(ecu, dtc_payload(0x07, ecu.pending))
        return _eol(state).join(lines) if lines else "NO DATA"

    if mode == "0A":
        return "NO DATA"

    if mode == "09":
        pid = rest[:2] if rest else "00"
        if pid != "02":
            return "NO DATA"
        for ecu in targets:
            if not ecu.vin:
                continue
            add(ecu, vin_payload(ecu.vin))
        return _eol(state).join(lines) if lines else "NO DATA"

    return "NO DATA"


def handle_command(state: AdapterState, raw: str) -> bytes | None:
    stripped = raw.strip("\r\n ")
    if not stripped:
        return format_reply(state, "")
    compact = stripped.upper().replace(" ", "")
    echo = stripped if state.echo else None
    if compact.startswith("AT"):
        body = handle_at(state, stripped)
        if compact == "ATZ":
            return format_reply(state, VERSION, echo=None)
        return format_reply(state, body or "", echo=echo)
    if state.drop_rate > 0.0 and state.rng.random() < state.drop_rate:
        return None
    body = handle_obd(state, compact)
    return format_reply(state, body or "NO DATA", echo=echo)


class JsonlLog:
    def __init__(self, path: str | None) -> None:
        self._path = path
        self._stream = None
        if path and path != "-":
            flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND
            flags |= getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
            fd = os.open(path, flags, 0o600)
            os.fchmod(fd, 0o600)
            self._stream = os.fdopen(fd, "a", encoding="utf-8")
        elif path == "-":
            self._stream = sys.stdout

    def emit(self, **fields: object) -> None:
        if self._stream is None:
            return
        record = {"monotonic": time.monotonic(), **fields}
        self._stream.write(json.dumps(record, separators=(",", ":")) + "\n")
        self._stream.flush()

    def close(self) -> None:
        if self._stream is not None and self._path not in {None, "-"}:
            self._stream.close()


class FreezeFrameReference:
    def __init__(
        self,
        host: str,
        port: int,
        logger: JsonlLog,
        rng: random.Random | None = None,
    ) -> None:
        self.host = host
        self.port = port
        self.logger = logger
        self.rng = rng or random.Random()
        self.server: asyncio.Server | None = None
        self._state = AdapterState(self.rng)
        self._data_task: asyncio.Task[None] | None = None
        self._clients: set[asyncio.Task[None]] = set()

    @property
    def address(self) -> tuple[str, int]:
        if self.server is None or not self.server.sockets:
            raise RuntimeError("reference is not listening")
        host, port = self.server.sockets[0].getsockname()[:2]
        return str(host), int(port)

    async def start(self) -> None:
        self.server = await asyncio.start_server(self._accept, self.host, self.port)
        host, port = self.address
        self.logger.emit(event="ready", listen_host=host, listen_port=port)

    async def close(self) -> None:
        if self.server is not None:
            self.server.close()
        tasks = list(self._clients)
        for task in tasks:
            task.cancel()
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
        if self.server is not None:
            await self.server.wait_closed()
            self.server = None
        self.logger.emit(event="stopped")

    def _accept(
        self,
        reader: asyncio.StreamReader,
        writer: asyncio.StreamWriter,
    ) -> None:
        task = asyncio.create_task(self._serve(reader, writer))
        self._clients.add(task)
        task.add_done_callback(self._clients.discard)

    async def _serve(
        self,
        reader: asyncio.StreamReader,
        writer: asyncio.StreamWriter,
    ) -> None:
        peer = writer.get_extra_info("peername")
        role = "unknown"
        is_control = False
        self.logger.emit(event="client_connected", peer=str(peer))
        try:
            raw = await reader.readuntil(b"\r")
            text = raw.decode("ascii", "replace")
            stripped = text.strip("\r\n ")
            compact = stripped.upper().replace(" ", "")
            is_control = compact.startswith("AT#")
            role = "control" if is_control else "data"
            if not is_control:
                previous = self._data_task
                self._data_task = asyncio.current_task()
                if (
                    previous is not None
                    and previous is not asyncio.current_task()
                    and not previous.done()
                ):
                    previous.cancel()
            await self._handle_one(writer, stripped, role, is_control)
            if is_control:
                return
            while True:
                raw = await reader.readuntil(b"\r")
                text = raw.decode("ascii", "replace")
                stripped = text.strip("\r\n ")
                await self._handle_one(writer, stripped, role, False)
        except (asyncio.IncompleteReadError, ConnectionResetError, OSError, asyncio.CancelledError):
            pass
        finally:
            writer.close()
            try:
                await writer.wait_closed()
            except OSError:
                pass
            if not is_control and self._data_task is asyncio.current_task():
                self._data_task = None
            self.logger.emit(event="client_disconnected", role=role)

    async def _handle_one(
        self,
        writer: asyncio.StreamWriter,
        stripped: str,
        role: str,
        is_control: bool,
    ) -> None:
        if self._state.delay_s:
            await asyncio.sleep(self._state.delay_s)
        reply = handle_command(self._state, stripped)
        self.logger.emit(
            event="command",
            role=role,
            command=stripped,
            dropped=reply is None,
        )
        if reply is None:
            return
        writer.write(reply)
        await writer.drain()


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="freeze_frame_reference.py",
        description=__doc__,
    )
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=35000)
    parser.add_argument("--log", default="")
    args = parser.parse_args(argv)
    if args.bind.strip() not in {"127.0.0.1", "::1"} and args.bind.strip() != "localhost":
        # Loopback only. A public bind would expose a synthetic VIN and bus.
        parser.error("--bind must be a loopback address")
    if not 1 <= args.port <= 65535:
        parser.error("--port must be in 1..65535")
    return args


async def _run(args: argparse.Namespace) -> None:
    logger = JsonlLog(args.log or None)
    server = FreezeFrameReference(args.bind, args.port, logger)
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for signum in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(signum, stop.set)
        except NotImplementedError:
            pass
    try:
        await server.start()
        await stop.wait()
    finally:
        await server.close()
        logger.close()


def main(argv: list[str] | None = None) -> None:
    os.umask(0o077)
    try:
        asyncio.run(_run(parse_args(argv)))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
