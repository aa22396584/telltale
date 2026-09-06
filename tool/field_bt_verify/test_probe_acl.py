#!/usr/bin/env python3
"""Unit tests for field_bt_verify/probe_acl.py — no phone required.

These cases encode the #52 contract. They must fail on the unfixed probe
(ACL-down labeled unpowered, BR-up accepted as any transport, silent OBDII
fallback, malformed ACL treated as down/unpowered).
"""

from __future__ import annotations

import unittest

from probe_acl import LinkState, evaluate, parse_bond_lines


def bond_line(
    name: str = "OBDBLE",
    *,
    addr: str = "AA:BB:CC:00:00:01",
    br: str = "N",
    le: str = "N",
) -> str:
    return (
        f"    {addr}(Public ) => {addr}(Public ) [ DUAL ] [0x010000] "
        f"[ACL BR/EDR:{br} LE:{le}] [ Encryption status(BR/EDR): null LE: null] "
        f"{name}\n"
    )


_SAMPLE_DOWN = """
BluetoothAdapterProperties
  ConnectionState: STATE_DISCONNECTED
  Bonded devices: 2
    XX:XX:XX:XX:22:33(Public ) => XX:XX:XX:XX:22:33(Public ) [ DUAL ] [0x010000] [ACL BR/EDR:N LE:N] [ Encryption status(BR/EDR): null LE: null] OBDBLE
        [BR/EDR UUIDs]: SPP
    XX:XX:XX:XX:22:33 | OBDII | 2 | 3 | 65536 | 576 | null | SPP | 41 | 0 | 0 | null | 0 | 0 | 0
"""

_SAMPLE_LE_UP = """
  ConnectionState: STATE_CONNECTED
  Bonded devices: 1
    AA:BB:CC:11:22:33(Public ) => AA:BB:CC:11:22:33(Public ) [ DUAL ] [0x010000] [ACL BR/EDR:N LE:Y] [ Encryption status(BR/EDR): null LE: null] OBDBLE
"""

_SAMPLE_MISSING = """
  ConnectionState: STATE_DISCONNECTED
  Bonded devices: 1
    AA:BB:CC:00:00:01(Public ) => AA:BB:CC:00:00:01(Public ) [ DUAL ] [0x240404] [ACL BR/EDR:N LE:N] [ Encryption status(BR/EDR): null LE: null] Galaxy Buds
"""


class ProbeAclTest(unittest.TestCase):
    def test_acl_down_is_disconnected_not_unpowered(self) -> None:
        result = evaluate(_SAMPLE_DOWN, ("OBDBLE",))
        self.assertEqual(result.exit_code, 0)
        summary = result.summary.lower()
        self.assertNotIn("unpowered", summary)
        self.assertNotIn("out of range", summary)
        hits = parse_bond_lines(_SAMPLE_DOWN, ("OBDBLE",))
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0].name, "OBDBLE")
        self.assertEqual(hits[0].acl_bredr, LinkState.DISCONNECTED)
        self.assertEqual(hits[0].acl_le, LinkState.DISCONNECTED)

    def test_issue_repro_line_acl_down_is_not_code_2(self) -> None:
        text = bond_line()
        result = evaluate(text, ("OBDBLE",))
        self.assertEqual(result.exit_code, 0)
        self.assertNotIn("unpowered", result.summary.lower())
        self.assertEqual(result.hits[0].acl_le, LinkState.DISCONNECTED)
        self.assertFalse(result.transport_link_up)

    def test_br_edr_up_is_not_le_available(self) -> None:
        text = bond_line(br="Y", le="N")
        result = evaluate(text, ("OBDBLE",), transport="ble")
        self.assertEqual(result.hits[0].acl_bredr, LinkState.CONNECTED)
        self.assertEqual(result.hits[0].acl_le, LinkState.DISCONNECTED)
        self.assertFalse(result.transport_link_up)
        self.assertNotIn("ACL up", result.summary)

    def test_le_up_is_not_classic_available(self) -> None:
        result = evaluate(_SAMPLE_LE_UP, ("OBDBLE",), transport="classic")
        self.assertEqual(result.hits[0].acl_le, LinkState.CONNECTED)
        self.assertEqual(result.hits[0].acl_bredr, LinkState.DISCONNECTED)
        self.assertFalse(result.transport_link_up)

    def test_le_up_counts_for_ble_transport(self) -> None:
        result = evaluate(_SAMPLE_LE_UP, ("OBDBLE",), transport="ble")
        self.assertTrue(result.transport_link_up)
        self.assertEqual(result.hits[0].address, "AA:BB:CC:11:22:33")

    def test_obdii_does_not_satisfy_requested_obdble(self) -> None:
        text = bond_line(name="OBDBLE") + bond_line(
            name="OBDII",
            addr="AA:BB:CC:00:00:02",
            br="Y",
        )
        result = evaluate(text, ("OBDBLE",))
        names = {h.name for h in result.hits}
        self.assertEqual(names, {"OBDBLE"})
        self.assertFalse(result.transport_link_up)

    def test_malformed_acl_is_unknown_not_unpowered(self) -> None:
        text = (
            "    AA:BB:CC:00:00:01(Public ) => AA:BB:CC:00:00:01(Public ) "
            "[ DUAL ] [ACL BR/EDR: LE:] OBDBLE\n"
        )
        result = evaluate(text, ("OBDBLE",))
        self.assertEqual(result.exit_code, 0)
        self.assertEqual(len(result.hits), 1)
        self.assertEqual(result.hits[0].acl_bredr, LinkState.UNKNOWN)
        self.assertEqual(result.hits[0].acl_le, LinkState.UNKNOWN)
        self.assertFalse(result.hits[0].parseable)
        self.assertNotIn("unpowered", result.summary.lower())

    def test_missing_from_bond_inventory_is_not_absence_or_unpowered(self) -> None:
        result = evaluate(_SAMPLE_MISSING, ("OBDBLE", "OBDII"))
        self.assertEqual(result.hits, ())
        self.assertTrue(result.not_in_bond_inventory)
        summary = result.summary.lower()
        self.assertNotIn("unpowered", summary)
        self.assertNotIn("no bonded adapter", summary)
        self.assertIn("not in bond inventory", summary)

    def test_duplicate_name_is_ambiguous_without_address(self) -> None:
        text = bond_line(addr="AA:BB:CC:00:00:01") + bond_line(
            addr="AA:BB:CC:00:00:02",
        )
        result = evaluate(text, ("OBDBLE",))
        self.assertTrue(result.ambiguous)
        self.assertNotEqual(result.exit_code, 0)

    def test_samsung_redacted_mac_is_still_an_address(self) -> None:
        text = (
            "    XX:XX:XX:XX:22:33(Public ) => XX:XX:XX:XX:22:33(Public ) "
            "[ DUAL ] [0x010000] [ACL BR/EDR:N LE:N] "
            "[ Encryption status(BR/EDR): null LE: null] OBDBLE\n"
        )
        result = evaluate(text, ("OBDBLE",))
        self.assertEqual(result.hits[0].address, "XX:XX:XX:XX:22:33")
        self.assertEqual(result.hits[0].acl_le, LinkState.DISCONNECTED)
        self.assertNotIn("unpowered", result.summary.lower())

    def test_duplicate_name_selects_requested_address(self) -> None:
        text = bond_line(addr="AA:BB:CC:00:00:01") + bond_line(
            addr="AA:BB:CC:00:00:02",
            br="Y",
        )
        result = evaluate(
            text,
            ("OBDBLE",),
            address="AA:BB:CC:00:00:02",
            transport="classic",
        )
        self.assertFalse(result.ambiguous)
        self.assertEqual(len(result.hits), 1)
        self.assertEqual(result.hits[0].address, "AA:BB:CC:00:00:02")
        self.assertTrue(result.transport_link_up)


if __name__ == "__main__":
    unittest.main()
