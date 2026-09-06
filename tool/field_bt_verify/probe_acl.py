#!/usr/bin/env python3
"""Parse Android `dumpsys bluetooth_manager` into a fact-layer observation.

This is not a field pass. ACL down/unknown is not unpowered. BR/EDR up is not
LE, and the reverse. A second same-name adapter does not satisfy the request.
Malformed ACL tokens are unknown, not down.

Exit codes:
  0 — observation produced (including disconnected / not in bond inventory)
  1 — usage, ambiguous name, or unreadable input
"""

from __future__ import annotations

import argparse
import enum
import re
import sys
from dataclasses import dataclass


class LinkState(str, enum.Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    UNKNOWN = "unknown"


class BondState(str, enum.Enum):
    BONDED = "bonded"
    UNBONDED = "unbonded"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class BondObservation:
    name: str
    address: str | None
    line: str
    acl_bredr: LinkState
    acl_le: LinkState
    bond: BondState
    parseable: bool


@dataclass(frozen=True)
class ProbeResult:
    hits: tuple[BondObservation, ...]
    requested_names: tuple[str, ...]
    requested_address: str | None
    transport: str | None
    adapter_connection_state: str | None
    ambiguous: bool

    @property
    def not_in_bond_inventory(self) -> bool:
        return not self.hits and not self.ambiguous

    @property
    def transport_link_up(self) -> bool:
        if not self.hits or self.ambiguous:
            return False
        wanted = (self.transport or "").casefold()
        for hit in self.hits:
            if wanted in ("ble", "le"):
                if hit.acl_le is LinkState.CONNECTED:
                    return True
            elif wanted in ("classic", "bredr", "br/edr", "spp"):
                if hit.acl_bredr is LinkState.CONNECTED:
                    return True
            else:
                if (
                    hit.acl_le is LinkState.CONNECTED
                    or hit.acl_bredr is LinkState.CONNECTED
                ):
                    return True
        return False

    @property
    def exit_code(self) -> int:
        return 1 if self.ambiguous else 0

    @property
    def summary(self) -> str:
        state = self.adapter_connection_state or "ConnectionState: <missing>"
        names = ", ".join(self.requested_names)
        if self.ambiguous:
            addrs = ", ".join(
                sorted({h.address or "?" for h in self.hits}),
            )
            return (
                f"ambiguous name {names}; pass --address to select among {addrs}; "
                f"{state}"
            )
        if not self.hits:
            return f"{names} not in bond inventory; {state}"
        parts = []
        for hit in self.hits:
            addr = hit.address or "address-unknown"
            parts.append(
                f"{hit.name} {addr} BR/EDR={hit.acl_bredr.value} "
                f"LE={hit.acl_le.value} parseable={hit.parseable}"
            )
        prefix = "observation"
        if self.transport:
            prefix += (
                f" transport={self.transport} "
                f"link_up={str(self.transport_link_up).lower()}"
            )
        return f"{prefix} — {'; '.join(parts)}; {state}"


_ACL_RE = re.compile(
    r"ACL BR/EDR:(?P<br>[YN])\s+LE:(?P<le>[YN])",
    re.IGNORECASE,
)
# Samsung dumpsys may redact OUI octets as XX:XX:XX:XX:22:33.
_MAC_RE = re.compile(r"(?i)((?:[0-9a-fx]{2}:){5}[0-9a-fx]{2})")


def _link(token: str | None) -> LinkState:
    if token is None:
        return LinkState.UNKNOWN
    folded = token.upper()
    if folded == "Y":
        return LinkState.CONNECTED
    if folded == "N":
        return LinkState.DISCONNECTED
    return LinkState.UNKNOWN


def parse_bond_lines(text: str, names: tuple[str, ...]) -> list[BondObservation]:
    """Return dumpsys lines whose display name matches any of *names*."""
    wanted = {n.casefold() for n in names}
    observations: list[BondObservation] = []
    for raw in text.splitlines():
        line = raw.rstrip("\n")
        if "ACL BR/EDR:" not in line:
            continue
        name = line.rsplit("]", 1)[-1].strip()
        if not name or name.casefold() not in wanted:
            continue
        acl = _ACL_RE.search(line)
        parseable = acl is not None
        mac = _MAC_RE.search(line)
        observations.append(
            BondObservation(
                name=name,
                address=mac.group(1).upper() if mac else None,
                line=line.strip(),
                acl_bredr=_link(acl.group("br") if acl else None),
                acl_le=_link(acl.group("le") if acl else None),
                bond=BondState.BONDED,
                parseable=parseable,
            )
        )
    return observations


def connection_state(text: str) -> str | None:
    for line in text.splitlines():
        if "ConnectionState:" in line:
            return line.strip()
    return None


def evaluate(
    text: str,
    names: tuple[str, ...],
    *,
    address: str | None = None,
    transport: str | None = None,
) -> ProbeResult:
    """Return a fact-layer observation. Never infers unpowered/out-of-range."""
    hits = parse_bond_lines(text, names)
    if address:
        wanted = address.casefold()
        hits = [h for h in hits if (h.address or "").casefold() == wanted]
        ambiguous = False
    else:
        addrs = {(h.address or "").casefold() for h in hits}
        ambiguous = len(addrs) > 1
    return ProbeResult(
        hits=tuple(hits),
        requested_names=names,
        requested_address=address,
        transport=transport,
        adapter_connection_state=connection_state(text),
        ambiguous=ambiguous,
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "dumpsys_path",
        nargs="?",
        help="path to dumpsys bluetooth_manager output (stdin if omitted)",
    )
    parser.add_argument(
        "--name",
        action="append",
        dest="names",
        default=None,
        help="display name to match (repeatable; default OBDBLE only)",
    )
    parser.add_argument(
        "--address",
        default=None,
        help="required when two adapters share a display name",
    )
    parser.add_argument(
        "--transport",
        default=None,
        help="ble or classic — diagnostic only; not a field pass",
    )
    parser.add_argument(
        "--evidence",
        help="optional path to write the observation (never a field PASS)",
    )
    args = parser.parse_args(argv)
    names = tuple(args.names) if args.names else ("OBDBLE",)
    if args.dumpsys_path:
        with open(args.dumpsys_path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    else:
        text = sys.stdin.read()

    result = evaluate(
        text,
        names,
        address=args.address,
        transport=args.transport,
    )
    print(result.summary)
    if args.evidence:
        body = (
            f"field_bt_verify ACL probe\n"
            f"names: {', '.join(names)}\n"
            f"address: {args.address or ''}\n"
            f"transport: {args.transport or ''}\n"
            f"observation: {result.summary}\n"
            f"qualification: not a field pass\n"
            f"transport_link_up: {str(result.transport_link_up).lower()}\n"
            f"not_in_bond_inventory: {str(result.not_in_bond_inventory).lower()}\n"
            f"ambiguous: {str(result.ambiguous).lower()}\n"
            f"---\n"
        )
        for hit in result.hits:
            body += hit.line + "\n"
        with open(args.evidence, "w", encoding="utf-8") as fh:
            fh.write(body)
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
