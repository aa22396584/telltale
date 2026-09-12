#!/usr/bin/env python3
"""Validator rules: one hand-typed fixture per fail-closed rule."""

from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import generate_matrix
import schema
import validate_matrix

SHA40_A = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
SHA40_B = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
SHA64_A = "11" * 32
SHA64_B = "22" * 32

# Hand-typed from the schema-v3 catalog snapshot, not from generator output.
EXPECTED_PROFILE_COUNT = 221
EXPECTED_COMMAND_COUNTS = {
    "byd-atto3-2022-2024-community": 4,
    "mg-zs-ev-au-2021": 9,
    "mg-mg4-2022-2026": 6,
    "lexus-rx450hl-2020-source-vehicle": 4,
    "kia-ev9-egmp-2024-2025-experimental": 2,
}


def _unknown_row(**overrides: object) -> dict:
    row = {
        "aliases": ["fixture unknown"],
        "blocker": "not yet researched",
        "catalog_presence": "absent",
        "catalog_profile_ids": [],
        "disposition": "unknown",
        "evidence_date": "2026-09-11",
        "id": "fixture-unknown",
        "signals": [],
        "source_families": [],
    }
    row.update(overrides)
    return row


def _complete_wire_contract(**overrides: object) -> dict:
    contract = {
        "byte_window": {"offset": 0, "width": 1},
        "did": "0005",
        "expected_responder": "7EF",
        "formula": "A",
        "payload_length": 1,
        "request_header": "7E7",
        "service": "22",
        "signedness": "unsigned",
        "unit": "%",
    }
    contract.update(overrides)
    return contract


def _bounded_catalog_signal(**overrides: object) -> dict:
    signal = {
        "equation": "A",
        "id": "soc",
        "max_value": 100,
        "min_value": 0,
        "name": "Battery state of charge",
        "offset": 0,
        "unit": "%",
        "width": 1,
    }
    signal.update(overrides)
    return signal


def _concrete_command(**overrides: object) -> dict:
    command = {
        "expected_responder": "7EF",
        "identifier": "0005",
        "mode": "22",
        "payload_length": 1,
        "request_header": "7E7",
        "signals": [_bounded_catalog_signal()],
    }
    command.update(overrides)
    return command


def _observation(source_id: str, **overrides: object) -> dict:
    obs = {
        "byte_window": {"offset": 0, "width": 1},
        "did": "0005",
        "expected_responder": "7EF",
        "formula": "A",
        "payload_length": 1,
        "request_header": "7E7",
        "service": "22",
        "signedness": "unsigned",
        "source_id": source_id,
        "unit": "%",
    }
    obs.update(overrides)
    return obs


def _valid_executable_row(**overrides: object) -> dict:
    row = {
        "aliases": ["fixture valid executable"],
        "catalog_presence": "absent",
        "catalog_profile_ids": [],
        "disposition": "experimental-candidate",
        "evidence": "sourceBacked",
        "evidence_date": "2026-09-11",
        "firmware_scope": "fixture-firmware-1",
        "generation": "fixture-gen",
        "id": "fixture-valid-executable",
        "independence_rationale": (
            "primary example/src and corroborating other/src are different GitHub orgs"
        ),
        "licence_redistribution": {"decision": "compatible"},
        "market": "Global",
        "signals": [
            {
                "agreement": "confirmed",
                "id": "soc",
                "observations": [
                    _observation("primary"),
                    _observation("corroborating"),
                ],
            }
        ],
        "source_families": [
            {
                "artifact_sha256": SHA64_A,
                "family": "example/src",
                "id": "primary",
                "license": "MIT",
                "locator": "file:a.json",
                "name": "example/src",
                "path": "a.json",
                "revision": SHA40_A,
                "role": "primary",
                "url": "https://github.com/example/src",
            },
            {
                "artifact_sha256": SHA64_B,
                "family": "other/src",
                "id": "corroborating",
                "license": "MIT",
                "locator": "file:b.json",
                "name": "other/src",
                "path": "b.json",
                "revision": SHA40_B,
                "role": "corroborating",
                "url": "https://github.com/other/src",
            },
        ],
        "year_from": 2022,
        "year_to": 2024,
    }
    row.update(overrides)
    return row


def _single_family_executable_row(**overrides: object) -> dict:
    row = _valid_executable_row()
    row["disposition"] = "single-family"
    del row["independence_rationale"]
    row["signals"] = [
        {
            "agreement": "confirmed",
            "id": "soc",
            "observations": [_observation("primary")],
        }
    ]
    row["source_families"] = [copy.deepcopy(row["source_families"][0])]
    row.update(overrides)
    return row


def _issues_for(row: dict) -> list[str]:
    row_id = str(row.get("id") or "")
    return validate_matrix.validate_research_row(
        row,
        catalog_ids=set(),
        research_ids={row_id} if row_id else set(),
    )


def _only(issues: list[str], fragment: str) -> None:
    matching = [item for item in issues if fragment in item]
    if not matching:
        raise AssertionError(f"expected {fragment!r} in {issues!r}")
    if len(issues) != 1:
        raise AssertionError(f"expected exactly one issue containing {fragment!r}; got {issues!r}")


class ResearchRuleTest(unittest.TestCase):
    def test_valid_handwritten_executable_fixture_passes(self) -> None:
        self.assertEqual(_issues_for(_valid_executable_row()), [])

    def test_unknown_row_with_empty_sources_passes(self) -> None:
        self.assertEqual(_issues_for(_unknown_row()), [])

    def test_observations_object_is_not_a_list(self) -> None:
        """A non-list ``observations`` container is rejected, not coerced to [].

        Same fail-open as a non-list ``signals`` value: an ``unknown`` row with
        ``observations: <complete wire>`` hid the executable claim.
        """
        issues = _issues_for(
            _unknown_row(
                signals=[
                    {
                        "id": "soc",
                        "observations": _observation("primary"),
                    }
                ]
            )
        )
        _only(issues, "observations must be a list")

    def test_source_families_object_is_not_a_list(self) -> None:
        """A non-list ``source_families`` container is rejected, not coerced."""
        issues = _issues_for(
            _unknown_row(source_families={"family": "example/src", "url": "x"})
        )
        _only(issues, "source_families must be a list")

    def test_commands_object_is_not_a_list(self) -> None:
        """A non-list ``commands`` container is rejected, not coerced to []."""
        issues = _issues_for(_unknown_row(commands=_concrete_command()))
        _only(issues, "commands must be a list")

    def test_signals_object_is_not_a_list(self) -> None:
        """A non-list ``signals`` container is rejected, not coerced to [].

        ``_as_list`` used to discard an object, so an ``unknown`` row with
        ``signals: {"contract": <complete wire>}`` hid the executable claim
        and passed. The container type is validated instead.
        """
        issues = _issues_for(
            _unknown_row(signals={"contract": _complete_wire_contract()})
        )
        _only(issues, "signals must be a list")

    def test_community_status_with_zero_commands_fails(self) -> None:
        issues = _issues_for(_unknown_row(status="community"))
        _only(issues, "status=community has 0 executable commands")

    def test_ready_status_with_zero_commands_fails(self) -> None:
        issues = _issues_for(_unknown_row(status="ready"))
        _only(issues, "status=ready has 0 executable commands")

    def test_same_family_corroborating_source_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["family"] = "example/src"
        row["source_families"][1]["name"] = "example/src"
        row["source_families"][1]["url"] = "https://github.com/example/src"
        issues = _issues_for(row)
        _only(issues, "corroborating source family example/src equals primary family")

    def test_missing_independence_rationale_fails(self) -> None:
        row = _valid_executable_row()
        del row["independence_rationale"]
        issues = _issues_for(row)
        _only(issues, "corroborating source is missing independence_rationale")

    def test_executable_claim_without_licence_decision_fails(self) -> None:
        row = _valid_executable_row()
        del row["licence_redistribution"]
        issues = _issues_for(row)
        _only(issues, "executable claim has no licence/redistribution decision")

    def test_executable_claim_without_revision_or_artifact_hash_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source in row["source_families"]:
            source["revision"] = ""
            source["artifact_sha256"] = ""
        issues = _issues_for(row)
        _only(issues, "executable claim has no immutable revision or artifact hash")

    def test_missing_market_year_firmware_scope_fails(self) -> None:
        issues = _issues_for(
            _unknown_row(
                id="fixture-identity-only",
                disposition="identity-only",
            )
        )
        _only(issues, "missing market/year/firmware scope")

    def test_inherits_from_sibling_fails(self) -> None:
        issues = _issues_for(
            _unknown_row(inherits_from="byd-atto3-2022-2024-community")
        )
        _only(issues, "inherits evidence from another row")

    def test_confirmed_signal_with_disagreement_fails(self) -> None:
        row = _valid_executable_row()
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"][0]["observations"][1]["did"] = "0006"
        issues = _issues_for(row)
        _only(issues, "signal soc is marked confirmed but sources disagree")

    def test_sales_evidence_tier_outside_priority_fails(self) -> None:
        issues = _issues_for(_unknown_row(evidence_tier="sales"))
        _only(issues, "sales/popularity data present outside priority")

    def test_priority_block_may_hold_sales_metadata(self) -> None:
        issues = _issues_for(
            _unknown_row(
                priority={
                    "as_of": "2026-09-11",
                    "method": "issue seed list; not an evidence tier",
                    "scope": "seed",
                    "source": "ImL1s/telltale#332",
                    "units_sold": 1000000,
                }
            )
        )
        self.assertEqual(issues, [])

    def test_physical_vehicle_without_locator_fails(self) -> None:
        issues = _issues_for(_unknown_row(evidence="physicalVehicle"))
        _only(
            issues,
            "physicalVehicle evidence has no retained vehicle-evidence locator",
        )

    def test_unknown_row_with_executable_claim_fails(self) -> None:
        row = _valid_executable_row(disposition="unknown")
        issues = _issues_for(row)
        _only(issues, "disposition unknown but carries an executable claim")

    def test_same_family_rule_depends_on_family_field(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["family"] = "example/src"
        row["source_families"][1]["name"] = "example/src"
        row["source_families"][1]["url"] = "https://github.com/example/src"
        self.assertTrue(_issues_for(row))
        row["source_families"][1]["family"] = "other/src"
        row["source_families"][1]["name"] = "other/src"
        row["source_families"][1]["url"] = "https://github.com/other/src"
        self.assertEqual(_issues_for(row), [])

    def test_community_qualified_single_observation_fails(self) -> None:
        issues = _issues_for(
            _single_family_executable_row(disposition="community-qualified")
        )
        _only(
            issues,
            "community-qualified requires agreeing observations "
            "from at least two distinct source families per shipped signal",
        )

    def test_community_qualified_two_families_agreeing_passes(self) -> None:
        self.assertEqual(
            _issues_for(_valid_executable_row(disposition="community-qualified")),
            [],
        )

    def test_experimental_candidate_requires_executable_claim(self) -> None:
        issues = _issues_for(
            _unknown_row(
                disposition="experimental-candidate",
                firmware_scope="fixture-firmware-1",
                market="Global",
                year_from=2022,
                year_to=2024,
            )
        )
        _only(
            issues,
            "experimental-candidate requires at least one executable claim",
        )

    def test_experimental_candidate_does_not_require_corroboration(self) -> None:
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(disposition="experimental-candidate")
            ),
            [],
        )

    def test_single_family_cannot_be_community_qualified_but_can_be_single_family(
        self,
    ) -> None:
        single = _single_family_executable_row()
        self.assertEqual(_issues_for(single), [])
        qualified = _single_family_executable_row(disposition="community-qualified")
        _only(
            _issues_for(qualified),
            "community-qualified requires agreeing observations "
            "from at least two distinct source families per shipped signal",
        )

    def test_source_without_derivable_family_fails(self) -> None:
        row = _single_family_executable_row(disposition="experimental-candidate")
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["url"] = ""
        row["source_families"][0]["name"] = ""
        issues = _issues_for(row)
        _only(issues, "has no derivable family identity")

    def test_declared_family_mismatch_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["family"] = "wrong/label"
        issues = _issues_for(row)
        _only(
            issues,
            "declared family 'wrong/label' does not match derived family 'example/src'",
        )

    def test_same_repo_path_declared_as_different_families_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["url"] = "https://github.com/example/src"
        row["source_families"][1]["name"] = "example/src"
        row["source_families"][1]["path"] = "a.json"
        row["source_families"][1]["role"] = "primary"
        issues = _issues_for(row)
        _only(issues, "share repo+path but declare different families")

    def test_same_artifact_hash_declared_as_different_families_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["artifact_sha256"] = SHA64_A
        issues = _issues_for(row)
        _only(issues, "share artifact hash but declare different families")

    def test_derived_from_or_fork_of_fails(self) -> None:
        issues = _issues_for(_unknown_row(fork_of="example/src"))
        _only(issues, "declares a derived-family relationship")
        issues = _issues_for(_unknown_row(derived_from="example/src"))
        _only(issues, "declares a derived-family relationship")

    def test_partial_wire_observations_are_not_executable(self) -> None:
        row = _valid_executable_row(disposition="community-qualified")
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"][0]["observations"] = [
            {"source_id": "primary", "unit": "%"},
            {"source_id": "corroborating", "unit": "%"},
        ]
        issues = _issues_for(row)
        _only(issues, "observation is missing a complete wire contract")

    def test_contract_bearing_signal_requires_corroboration(self) -> None:
        row = _valid_executable_row(disposition="community-qualified")
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"].append(
            {
                "contract": {
                    "byte_window": {"offset": 1, "width": 1},
                    "did": "0006",
                    "expected_responder": "7EF",
                    "formula": "A",
                    "payload_length": 2,
                    "request_header": "7E7",
                    "service": "22",
                    "signedness": "unsigned",
                    "unit": "%",
                },
                "id": "soh",
                "observations": [],
            }
        )
        issues = _issues_for(row)
        _only(
            issues,
            "community-qualified requires agreeing observations "
            "from at least two distinct source families per shipped signal",
        )

    def test_community_qualified_two_primaries_need_independence_rationale(
        self,
    ) -> None:
        row = _valid_executable_row(disposition="community-qualified")
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["role"] = "primary"
        del row["independence_rationale"]
        issues = _issues_for(row)
        _only(
            issues,
            "qualification across multiple source families "
            "is missing independence_rationale",
        )

    def test_experimental_candidate_two_primaries_without_rationale_passes(
        self,
    ) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][1]["role"] = "primary"
        del row["independence_rationale"]
        self.assertEqual(_issues_for(row), [])

    def test_incomplete_contract_is_not_executable(self) -> None:
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": {"unit": "%"},
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "contract is missing a complete wire contract")

    def test_byte_window_must_fit_payload_length(self) -> None:
        """Align with PowertrainBatteryProfileCatalogValidator.

        lib/obd/powertrain_battery/profile_catalog_validator.dart rejects a
        signal when ``offset < 0 || width <= 0 || offset + width > payloadLength``.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(
                            payload_length=1,
                            byte_window={"offset": 10, "width": 8},
                        ),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "byte window does not fit payload_length")

    def test_byte_window_on_payload_boundary_passes(self) -> None:
        """offset + width == payload_length is accepted by the Dart catalog rule."""
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(
                                payload_length=18,
                                byte_window={"offset": 10, "width": 8},
                            ),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_invalid_typed_wire_values_fail(self) -> None:
        """Wire fields must be syntax-valid, not merely present.

        Mirrors ``isExactPowertrainCanId`` in
        ``lib/obd/powertrain_battery/profile_wire_contract.dart`` (used at
        ``profile_catalog_validator.dart`` ~433): ``request_header`` and
        ``expected_responder`` must be exact 11-bit or 29-bit CAN ids.
        ``service`` is 2 hex (or ``mode``); ``did`` is 2-4 hex (or
        ``identifier``); ``formula`` and ``unit`` are nonempty strings;
        ``signedness`` is ``unsigned`` or ``signed``.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(
                            request_header=False,
                            did=[],
                            expected_responder={},
                        ),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")

    def test_constant_zero_divisor_formula_is_not_executable(self) -> None:
        """Constant /0 and %0 fail the catalog's fixed all-1s probe.

        ``formula_engine.dart`` ~2190-2235 rejects ``A/0``, ``A%0``, and
        ``1/(A-A)`` on every probe, including ``List.filled(width, 1)``.
        """
        for formula in ("A/0", "A%0", "1/(A-A)"):
            with self.subTest(formula=formula):
                issues = _issues_for(
                    _single_family_executable_row(
                        disposition="experimental-candidate",
                        signals=[
                            {
                                "contract": _complete_wire_contract(formula=formula),
                                "id": "soc",
                                "observations": [],
                            }
                        ],
                    )
                )
                _only(issues, "invalid wire contract values")

    def test_catalog_fixed_probe_rejects_one_over_a_minus_one(self) -> None:
        """Align with profile_catalog_validator.dart ~277-280.

        ``FormulaEngine.validate`` is called with
        ``sampleBytes: List<int>.filled(signal.width, 1)``, which disables
        preflight fallback probes. ``1/(A-1)`` is therefore rejected on the
        catalog path. ``A-1`` is defined at that same probe and stays
        executable.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(formula="1/(A-1)"),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(formula="A-1"),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_fractional_bit_index_is_not_executable(self) -> None:
        """Mirror formula_engine.dart ~1869-1875.

        A BIT index must be finite, integral, and nonnegative
        (``bit == bit.truncateToDouble() && bit >= 0``). ``BIT(A,1.5)`` is
        truncated by Python ``int`` but rejected at runtime. ``BIT(A,0)``
        stays executable.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(formula="BIT(A,1.5)"),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(formula="BIT(A,0)"),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_int_truncates_toward_zero_on_catalog_probe(self) -> None:
        """Mirror formula_engine.dart ~1119-1132.

        ``INT`` truncates toward zero. With the catalog all-1s probe,
        ``1/INT(A/2)`` is ``1/0`` and is not executable. ``INT(A)`` stays
        executable.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(formula="1/INT(A/2)"),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(formula="INT(A)"),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_runtime_formula_functions_are_executable(self) -> None:
        """ABS/LOG/SQRT/SIGNED16 are FormulaEngine dialect, not unknown calls."""
        for formula in ("ABS(A)", "LOG(A)", "SQRT(A)", "SIGNED16(A)"):
            with self.subTest(formula=formula):
                self.assertEqual(
                    _issues_for(
                        _single_family_executable_row(
                            disposition="experimental-candidate",
                            signals=[
                                {
                                    "contract": _complete_wire_contract(
                                        formula=formula
                                    ),
                                    "id": "soc",
                                    "observations": [],
                                }
                            ],
                        )
                    ),
                    [],
                )

    def test_signed_composite_formula_is_not_executable(self) -> None:
        """Mirror formula_engine.dart ~367 ``_signedPattern``.

        Runtime only recognizes ``SIGNED([A-N])``. ``SIGNED(A+1)`` and
        ``SIGNED((A))`` are unparsable there. Bare ``SIGNED(A)`` stays
        executable.
        """
        for formula in ("SIGNED(A+1)", "SIGNED((A))"):
            with self.subTest(formula=formula):
                issues = _issues_for(
                    _single_family_executable_row(
                        disposition="experimental-candidate",
                        signals=[
                            {
                                "contract": _complete_wire_contract(formula=formula),
                                "id": "soc",
                                "observations": [],
                            }
                        ],
                    )
                )
                _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(formula="SIGNED(A)"),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_command_inherits_from_sibling_fails(self) -> None:
        """Commands are scanned for inheritance keys and locators."""
        issues = _issues_for(
            _single_family_executable_row(
                commands=[_concrete_command(inherits_from="sibling-row")],
                command_count=1,
                disposition="experimental-candidate",
                signals=[],
            )
        )
        _only(issues, "inherits evidence from another row")
        issues = _issues_for(
            _single_family_executable_row(
                commands=[_concrete_command(locator="sibling:foo")],
                command_count=1,
                disposition="experimental-candidate",
                signals=[],
            )
        )
        _only(issues, "inherits evidence from another row")

    def test_non_finite_formula_result_is_not_executable(self) -> None:
        """Mirror formula_engine.dart ~609-616.

        ``evaluateBytes`` rejects NaN / infinity. A 400-digit literal becomes
        Python ``inf``; ``1`` stays finite and executable.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(formula="1" + "0" * 400),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(formula="1"),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_non_finite_float32_formula_is_not_executable(self) -> None:
        """FLOAT32/FLOAT64 decode IEEE-754; non-finite bit patterns fail.

        ``FLOAT32(127:128:0:0)`` is +Inf (``formula_engine.dart`` ~1094-1116).
        ``FLOAT32(64:0:0:0)`` is 2.0 and stays executable.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(
                            formula="FLOAT32(127:128:0:0)"
                        ),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(
                                formula="FLOAT32(64:0:0:0)"
                            ),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_lookup_comma_form_is_not_executable(self) -> None:
        """LOOKUP/CLOSEST use the wiki colon grammar, not generic arity.

        ``formula_engine.dart`` ~1375-1652: colon is the only separator and a
        mapping needs ``value:default:key=val`` (≥3 parts). Comma forms
        ``LOOKUP(A,0)`` / ``CLOSEST(A,0)`` are not LOOKUP calls; two-part
        ``LOOKUP(A:0)`` is rejected at ``test/formula_engine_test.dart:1034-1037``.
        """
        for formula in ("LOOKUP(A,0)", "CLOSEST(A,0)", "LOOKUP(A:0)"):
            with self.subTest(formula=formula):
                issues = _issues_for(
                    _single_family_executable_row(
                        disposition="experimental-candidate",
                        signals=[
                            {
                                "contract": _complete_wire_contract(formula=formula),
                                "id": "soc",
                                "observations": [],
                            }
                        ],
                    )
                )
                _only(issues, "invalid wire contract values")

    def test_lookup_colon_mapping_formula_is_executable(self) -> None:
        for formula in ("LOOKUP(A:0:1=100)", "CLOSEST(A:0:1=100)", "LOOKUP(A::1=100)"):
            with self.subTest(formula=formula):
                self.assertEqual(
                    _issues_for(
                        _single_family_executable_row(
                            disposition="experimental-candidate",
                            signals=[
                                {
                                    "contract": _complete_wire_contract(formula=formula),
                                    "id": "soc",
                                    "observations": [],
                                }
                            ],
                        )
                    ),
                    [],
                )

    def test_formula_function_arity_is_enforced(self) -> None:
        for formula in ("RANDOM(A)", "FLOAT32(A)", "SIGNED()", "LOOKUP(A)"):
            with self.subTest(formula=formula):
                issues = _issues_for(
                    _single_family_executable_row(
                        disposition="experimental-candidate",
                        signals=[
                            {
                                "contract": _complete_wire_contract(formula=formula),
                                "id": "soc",
                                "observations": [],
                            }
                        ],
                    )
                )
                _only(issues, "invalid wire contract values")

    def test_invalid_formula_is_not_executable(self) -> None:
        """Mirror FormulaEngine.validate at profile_catalog_validator.dart ~277."""
        for formula in ("A*", "A**2", ")A(", "FOO(A)"):
            with self.subTest(formula=formula):
                issues = _issues_for(
                    _single_family_executable_row(
                        disposition="experimental-candidate",
                        signals=[
                            {
                                "contract": _complete_wire_contract(formula=formula),
                                "id": "soc",
                                "observations": [],
                            }
                        ],
                    )
                )
                _only(issues, "invalid wire contract values")

    def test_signal_width_above_fourteen_fails(self) -> None:
        """Mirror profile_catalog_validator.dart 270-275: width may not exceed A..N."""
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(
                            payload_length=16,
                            byte_window={"offset": 0, "width": 15},
                        ),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "signal width exceeds the A..N formula byte window")

    def test_formula_byte_beyond_window_is_not_executable(self) -> None:
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(formula="B"),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")

    def test_denied_service_contract_is_not_executable(self) -> None:
        """Contracts may use only catalog read-only services 21 and 22."""
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(service="2E", did="0005"),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")

    def test_boolean_payload_length_is_not_a_wire_int(self) -> None:
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": _complete_wire_contract(payload_length=True),
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "invalid wire contract values")

    def test_complete_typed_wire_contract_still_passes(self) -> None:
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    signals=[
                        {
                            "contract": _complete_wire_contract(),
                            "id": "soc",
                            "observations": [],
                        }
                    ],
                )
            ),
            [],
        )

    def test_command_count_without_commands_is_not_executable(self) -> None:
        issues = _issues_for(_unknown_row(command_count=1))
        _only(issues, "command_count disagrees with len(commands)")

    def test_malformed_concrete_command_is_not_executable(self) -> None:
        """Commands must match profile_catalog_validator.dart ~433-468.

        ``request_header`` / ``expected_responder``: ``isExactPowertrainCanId``.
        Service is read-only ``21`` or ``22``; identifier width is 2 or 4 hex;
        ``payload_length`` is a positive non-bool int.
        """
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                commands=[
                    {
                        "did": "x",
                        "expected_responder": "x",
                        "payload_length": 1,
                        "request_header": "x",
                        "service": "x",
                    }
                ],
                command_count=1,
                signals=[],
            )
        )
        _only(issues, "malformed concrete command")

    def test_command_payload_string_is_not_payload_length(self) -> None:
        command = _concrete_command()
        del command["payload_length"]
        command["payload"] = "nonsense"
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                commands=[command],
                command_count=1,
                signals=[],
            )
        )
        _only(issues, "malformed concrete command")

    def test_concrete_command_is_executable(self) -> None:
        self.assertEqual(
            _issues_for(
                _single_family_executable_row(
                    disposition="experimental-candidate",
                    commands=[_concrete_command()],
                    command_count=1,
                    signals=[],
                )
            ),
            [],
        )

    def test_alias_fields_are_canonicalized_in_wire_signature(self) -> None:
        row = _valid_executable_row(disposition="community-qualified")
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"][0]["agreement"] = "unconfirmed"
        aliases = (("22", "0005"), ("21", "05"))
        for obs, (mode, ident) in zip(
            row["signals"][0]["observations"], aliases, strict=True
        ):
            obs["service"] = ""
            obs["did"] = ""
            obs["mode"] = mode
            obs["identifier"] = ident
        issues = _issues_for(row)
        _only(
            issues,
            "community-qualified requires agreeing observations",
        )

    def test_shipped_contract_must_match_corroborated_observations(self) -> None:
        row = _valid_executable_row(disposition="community-qualified")
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"][0]["contract"] = _complete_wire_contract(did="FFFF")
        issues = _issues_for(row)
        _only(
            issues,
            "shipped contract does not match corroborated observation signature",
        )

    def test_observation_source_id_must_resolve(self) -> None:
        row = _single_family_executable_row(disposition="experimental-candidate")
        row["signals"] = copy.deepcopy(row["signals"])
        row["signals"][0]["observations"][0]["source_id"] = "ghost"
        issues = _issues_for(row)
        _only(issues, "observation source_id does not resolve to a declared source")

    def test_same_non_github_url_declared_as_different_families_fails(self) -> None:
        row = _single_family_executable_row(disposition="experimental-candidate")
        row["source_families"] = [
            {
                "artifact_sha256": SHA64_A,
                "family": "alpha",
                "id": "primary",
                "license": "MIT",
                "locator": "file:pack.csv",
                "name": "alpha",
                "path": "pack.csv",
                "revision": SHA40_A,
                "role": "primary",
                "url": "https://example.net/pack.csv",
            },
            {
                "artifact_sha256": SHA64_B,
                "family": "beta",
                "id": "other",
                "license": "MIT",
                "locator": "file:other.csv",
                "name": "beta",
                "path": "other.csv",
                "revision": SHA40_B,
                "role": "primary",
                "url": "https://example.net/pack.csv",
            },
        ]
        issues = _issues_for(row)
        _only(issues, "share source URL but declare different families")

    def test_trailing_dns_dot_is_same_github_family(self) -> None:
        """``github.com.`` is the same host as ``github.com`` (trailing DNS dot)."""
        self.assertEqual(
            schema.derive_source_family({"url": "https://github.com/org/repo"}),
            schema.derive_source_family({"url": "https://github.com./org/repo"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://github.com./org/repo"}),
            "org/repo",
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/pack.csv"}),
            schema.source_url_key({"url": "https://example.net./pack.csv"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://www.example.net./a"}),
            schema.derive_source_family({"url": "https://example.net/b"}),
        )

    def test_github_percent_encoded_org_is_one_family(self) -> None:
        """Unreserved escapes in GitHub/forge path segments are decoded.

        ``github.com/org/repo`` and ``github.com/%6frg/repo`` are one family
        (``%6f`` → ``o``). Same for gitlab. Path/revision still ignored.
        """
        self.assertEqual(
            schema.derive_source_family({"url": "https://github.com/org/repo"}),
            schema.derive_source_family({"url": "https://github.com/%6frg/repo"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://github.com/org/repo"}),
            "org/repo",
        )
        self.assertEqual(
            schema.derive_source_family(
                {"url": "https://gitlab.com/org/repo/-/blob/main/a.csv"}
            ),
            schema.derive_source_family(
                {"url": "https://gitlab.com/%6frg/repo/-/blob/main/b.csv"}
            ),
        )
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["url"] = "https://github.com/org/repo"
        row["source_families"][0]["name"] = "org/repo"
        row["source_families"][0]["family"] = "org/repo"
        row["source_families"][1]["url"] = "https://github.com/%6frg/repo"
        row["source_families"][1]["name"] = "org/repo"
        row["source_families"][1]["family"] = "org/repo"
        issues = _issues_for(row)
        _only(issues, "corroborating source family org/repo equals primary family")

    def test_percent_encoded_unreserved_path_is_one_family(self) -> None:
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/a"}),
            schema.derive_source_family({"url": "https://example.net/%61"}),
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/a"}),
            schema.source_url_key({"url": "https://example.net/%61"}),
        )

    def test_idna_hosts_are_one_family(self) -> None:
        """Unicode and punycode hosts are one family and one URL key."""
        unicode_url = "https://bücher.example/a"
        punycode_url = "https://xn--bcher-kva.example/a"
        self.assertEqual(
            schema.derive_source_family({"url": unicode_url}),
            schema.derive_source_family({"url": punycode_url}),
        )
        self.assertEqual(
            schema.source_url_key({"url": unicode_url}),
            schema.source_url_key({"url": punycode_url}),
        )
        self.assertNotEqual(
            schema.derive_source_family({"url": unicode_url}),
            schema.derive_source_family({"url": "https://books.example/a"}),
        )

    def test_non_forge_paths_share_publisher_family_but_keep_url_identity(self) -> None:
        """Non-forge resources share a publisher family, not a URL key.

        RFC 3986 remove_dot_segments still canonicalizes the separate URL key.
        """
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/a"}),
            schema.derive_source_family({"url": "https://example.net/x/../a"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/./a"}),
            "example.net",
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/a"}),
            schema.source_url_key({"url": "https://example.net/x/../a"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/a"}),
            schema.derive_source_family({"url": "https://example.net/b"}),
        )
        self.assertNotEqual(
            schema.source_url_key({"url": "https://example.net/a"}),
            schema.source_url_key({"url": "https://example.net/b"}),
        )
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, url in (
            (row["source_families"][0], "https://example.net/a"),
            (row["source_families"][1], "https://example.net/x/../a"),
        ):
            source["url"] = url
            source["name"] = "example.net/a"
            source["family"] = "example.net"
            source["path"] = "a"
        issues = _issues_for(row)
        _only(
            issues,
            "corroborating source family example.net equals primary family",
        )

    def test_non_forge_paths_do_not_corroborate_as_independent_publishers(self) -> None:
        """Two resources on one publisher cannot qualify a community row."""
        row = _valid_executable_row(disposition="community-qualified")
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, name, url, path in zip(
            row["source_families"],
            ("publisher export", "publisher appendix"),
            ("https://example.net/a", "https://example.net/b"),
            ("a", "b"),
            strict=True,
        ):
            source["url"] = url
            source["name"] = name
            source["family"] = "example.net"
            source["path"] = path

        issues = _issues_for(row)

        self.assertIn(
            "research row fixture-valid-executable: corroborating source family "
            "example.net equals primary family",
            issues,
        )
        self.assertIn(
            "research row fixture-valid-executable: community-qualified requires "
            "agreeing observations from at least two distinct source families "
            "per shipped signal",
            issues,
        )

    def test_non_forge_ports_do_not_corroborate_as_independent_publishers(self) -> None:
        """Different services on one hostname are still one publisher family."""
        row = _valid_executable_row(disposition="community-qualified")
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, url, path in zip(
            row["source_families"],
            ("https://example.net:8443/a", "https://example.net:9443/b"),
            ("a", "b"),
            strict=True,
        ):
            source["url"] = url
            source["name"] = f"publisher service {path}"
            source["family"] = "example.net"
            source["path"] = path

        self.assertEqual(
            schema.derive_source_family(row["source_families"][0]),
            schema.derive_source_family(row["source_families"][1]),
        )
        self.assertNotEqual(
            schema.source_url_key(row["source_families"][0]),
            schema.source_url_key(row["source_families"][1]),
        )
        issues = _issues_for(row)
        self.assertIn(
            "research row fixture-valid-executable: corroborating source family "
            "example.net equals primary family",
            issues,
        )
        self.assertIn(
            "research row fixture-valid-executable: community-qualified requires "
            "agreeing observations from at least two distinct source families "
            "per shipped signal",
            issues,
        )

    def test_malformed_source_url_port_fails_closed(self) -> None:
        row = _single_family_executable_row(disposition="experimental-candidate")
        source = row["source_families"][0]
        source["url"] = "https://example.net:not-a-port/a"
        source["family"] = "example/src"

        issues = _issues_for(row)

        _only(issues, "source primary has no derivable family identity")

    def test_default_https_port_is_same_non_github_family(self) -> None:
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/pack.csv"}),
            schema.derive_source_family({"url": "https://example.net:443/pack.csv"}),
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/pack.csv"}),
            schema.source_url_key({"url": "https://example.net:443/pack.csv"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "http://example.net:80/a"}),
            schema.derive_source_family({"url": "http://example.net/b"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net:8443/a"}),
            schema.derive_source_family({"url": "https://example.net/b"}),
        )
        self.assertNotEqual(
            schema.source_url_key({"url": "https://example.net:8443/a"}),
            schema.source_url_key({"url": "https://example.net/b"}),
        )
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, name, url in zip(
            row["source_families"],
            ("alpha", "beta"),
            (
                "https://example.net/pack.csv",
                "https://example.net:443/pack.csv",
            ),
            strict=True,
        ):
            source["url"] = url
            source["name"] = name
            source["family"] = "example.net"
            source["path"] = f"{name}.csv"
        issues = _issues_for(row)
        _only(
            issues,
            "corroborating source family example.net equals primary family",
        )

    def test_same_non_github_url_is_one_family(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, name in zip(row["source_families"], ("alpha", "beta"), strict=True):
            source["url"] = "https://example.net/pack.csv"
            source["name"] = name
            source["family"] = "example.net"
            source["path"] = f"{name}.csv"
        issues = _issues_for(row)
        _only(issues, "corroborating source family example.net equals primary family")

    def test_source_missing_valid_role_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["role"] = ""
        issues = _issues_for(row)
        _only(issues, "source primary has no valid role")

    def test_physical_vehicle_research_row_with_locator_passes(self) -> None:
        self.assertEqual(
            _issues_for(
                _unknown_row(
                    evidence="physicalVehicle",
                    vehicle_evidence={"locator": "capture:fixture-2026-09-11"},
                )
            ),
            [],
        )

    def test_contract_inherit_locator_fails(self) -> None:
        issues = _issues_for(
            _single_family_executable_row(
                disposition="experimental-candidate",
                signals=[
                    {
                        "contract": {
                            **_complete_wire_contract(),
                            "locator": "sibling:foo",
                        },
                        "id": "soc",
                        "observations": [],
                    }
                ],
            )
        )
        _only(issues, "inherits evidence from another row")

    def test_nested_inherits_from_fails(self) -> None:
        issues = _issues_for(
            _unknown_row(signals=[{"id": "soc", "inherits_from": "other-row"}])
        )
        _only(issues, "inherits evidence from another row")

    def test_physical_vehicle_inherit_locator_fails(self) -> None:
        issues = _issues_for(
            _unknown_row(
                evidence="physicalVehicle",
                vehicle_evidence={"locator": "sibling:foo"},
            )
        )
        _only(issues, "inherits evidence from another row")

    def test_boolean_year_is_not_a_scope(self) -> None:
        """Mirror profile_catalog_validator.dart 142-148: 1886..2100, ordered."""
        issues = _issues_for(
            _unknown_row(
                id="fixture-identity-only",
                disposition="identity-only",
                firmware_scope="fixture-firmware-1",
                market="Global",
                year=True,
            )
        )
        _only(issues, "missing market/year/firmware scope")

    def test_reversed_year_range_is_not_a_scope(self) -> None:
        issues = _issues_for(
            _unknown_row(
                id="fixture-identity-only",
                disposition="identity-only",
                firmware_scope="fixture-firmware-1",
                market="Global",
                year_from=2024,
                year_to=2020,
            )
        )
        _only(issues, "missing market/year/firmware scope")

    def test_non_scalar_market_scope_fails(self) -> None:
        issues = _issues_for(
            _unknown_row(
                id="fixture-identity-only",
                disposition="identity-only",
                firmware_scope="fixture-firmware-1",
                market={},
                year=2022,
            )
        )
        _only(issues, "missing market/year/firmware scope")


class CatalogObjectRuleTest(unittest.TestCase):
    def test_community_catalog_profile_with_zero_commands_fails(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [],
                        "id": "fixture-community-empty",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_empty_command_object_fails(self) -> None:
        """Catalog community/ready must have a concrete command, not a nonempty list.

        Mirrors ``_command_is_concrete`` / ``profile_catalog_validator.dart``
        ~433-468. ``commands: [{}]`` is not executable.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [{}],
                        "id": "fixture-community-empty-object",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_empty_signals_fails(self) -> None:
        """Catalog commands need a bounded signal, not only a concrete read.

        ``profile_catalog_validator.dart`` ~471-476 rejects
        ``command.signals.isEmpty`` as ``missing_signals``.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [_concrete_command(signals=[])],
                        "id": "fixture-community-empty-signals",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_invalid_signal_equation_fails(
        self,
    ) -> None:
        """Catalog signals must pass the same formula checks as the runtime.

        ``profile_catalog_validator.dart`` ~264-282 rejects ``A*``.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [
                            _concrete_command(
                                signals=[_bounded_catalog_signal(equation="A*")]
                            )
                        ],
                        "id": "fixture-community-bad-equation",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_service_did_aliases_fails(self) -> None:
        """Catalog commands must use native ``mode`` / ``identifier``.

        ``PowertrainBatteryCommand.fromJson`` requires those keys
        (``powertrain_battery_profile.dart`` ~214-215). Research aliases
        ``service`` / ``did`` are not enough to load the catalog.
        """
        command = _concrete_command()
        del command["mode"]
        del command["identifier"]
        command["service"] = "22"
        command["did"] = "0005"
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [command],
                        "id": "fixture-community-aliases",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_mode_21_fails(self) -> None:
        """Installable catalog profiles may only carry Mode 22.

        ``profile_catalog_validator.dart`` ~215-225 rejects Mode 21 on
        reviewed/community/ready statuses as ``unpollable_service``.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [
                            _concrete_command(identifier="01", mode="21")
                        ],
                        "id": "fixture-community-mode21",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_mixed_signal_quality_fails(self) -> None:
        """Every catalog signal must pass; one valid sibling is not enough.

        ``profile_catalog_validator.dart`` ~243-303 checks each signal.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [
                            _concrete_command(
                                signals=[
                                    _bounded_catalog_signal(),
                                    _bounded_catalog_signal(
                                        equation="A*", id="bad"
                                    ),
                                ]
                            )
                        ],
                        "id": "fixture-community-mixed-signals",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_invalid_sibling_command_fails(
        self,
    ) -> None:
        """Every reviewed command is validated, not only the surviving subset.

        ``profile_catalog_validator.dart`` ~207-241 loops all commands.
        """
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [
                            _concrete_command(),
                            _concrete_command(identifier="01", mode="21"),
                        ],
                        "id": "fixture-community-sibling-mode21",
                        "status": "community",
                    }
                ]
            }
        )
        _only(issues, "status=community has 0 executable commands")

    def test_community_catalog_profile_with_concrete_command_passes(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [_concrete_command()],
                        "id": "fixture-community-concrete",
                        "status": "community",
                    }
                ]
            }
        )
        self.assertEqual(issues, [])

    def test_ready_catalog_profile_with_zero_commands_fails(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [],
                        "evidence": "physicalVehicle",
                        "id": "fixture-ready-empty",
                        "status": "ready",
                        "vehicle_evidence": {
                            "locator": "capture:fixture-2026-09-11"
                        },
                    }
                ]
            }
        )
        _only(issues, "status=ready has 0 executable commands")

    def test_ready_catalog_profile_without_physical_evidence_fails(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [_concrete_command()],
                        "evidence": "sourceBacked",
                        "id": "fixture-ready-source",
                        "status": "ready",
                    }
                ]
            }
        )
        _only(issues, "ready profile requires retained physical-vehicle evidence")

    def test_physical_vehicle_catalog_profile_without_locator_fails(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [],
                        "evidence": "physicalVehicle",
                        "id": "fixture-physical",
                        "status": "researchOnly",
                    }
                ]
            }
        )
        _only(
            issues,
            "physicalVehicle evidence has no retained vehicle-evidence locator",
        )

    def test_physical_vehicle_catalog_profile_with_locator_passes(self) -> None:
        issues = validate_matrix.validate_catalog_object(
            {
                "profiles": [
                    {
                        "commands": [_concrete_command()],
                        "evidence": "physicalVehicle",
                        "id": "fixture-physical-ready",
                        "status": "ready",
                        "vehicle_evidence": {
                            "locator": "capture:fixture-2026-09-11"
                        },
                    }
                ]
            }
        )
        self.assertEqual(issues, [])


def _research_profile(**overrides: object) -> dict:
    profile = {
        "commands": [],
        "evidence": "sourceBacked",
        "id": "fixture-research-only",
        "market": "Global",
        "source": {
            "license": "MIT",
            "locator": "a",
            "name": "example/src",
            "path": "a.json",
            "revision": SHA40_A,
            "url": f"https://github.com/example/src/tree/{SHA40_A}",
        },
        "status": "researchOnly",
        "variant": "fixture",
        "year_from": 2020,
        "year_to": 2024,
    }
    profile.update(overrides)
    return profile


def _write_mini_repo(
    tmp: Path,
    *,
    catalog: dict | None = None,
    research_rows: list | None = None,
    mutate_matrix=None,
    manifest_overlay: dict | None = None,
) -> Path:
    catalog = catalog or {"profiles": [_research_profile()], "schema_version": 3}
    research_rows = research_rows if research_rows is not None else []
    assets = tmp / "assets" / "powertrain_battery"
    tool = tmp / "tool" / "powertrain_evidence"
    research_dir = tool / "research"
    assets.mkdir(parents=True)
    research_dir.mkdir(parents=True)
    catalog_bytes = schema.dump_canonical(catalog).encode("utf-8")
    (assets / "powertrain_battery_catalog.json").write_bytes(catalog_bytes)
    manifest = {
        "catalog_file": "powertrain_battery_catalog.json",
        "profile_count": len(catalog["profiles"]),
        "schema_version": 3,
        "sha256": schema.sha256_hex(catalog_bytes),
        "size_bytes": len(catalog_bytes),
    }
    if manifest_overlay:
        manifest.update(manifest_overlay)
    (assets / "powertrain_battery_catalog.manifest.json").write_bytes(
        schema.dump_canonical(manifest).encode("utf-8")
    )
    schema.write_canonical_json(
        research_dir / "rows.json",
        {"rows": research_rows, "schema_version": 1},
    )
    matrix = schema.build_matrix(catalog_bytes, manifest, research_rows)
    if mutate_matrix is not None:
        mutate_matrix(matrix)
    schema.write_canonical_json(tool / "matrix.json", matrix)
    return tmp


class MatrixDocumentTest(unittest.TestCase):
    def test_stale_catalog_derived_section_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write_mini_repo(
                tmp,
                mutate_matrix=lambda matrix: matrix["catalog"]["profiles"][0].__setitem__(
                    "command_count", 99
                ),
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(issues, "catalog-derived section is stale versus the catalog")

    def test_manifest_sha_size_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write_mini_repo(
                tmp,
                manifest_overlay={"sha256": "00" * 32, "size_bytes": 1},
            )
            issues = validate_matrix.validate_repo(tmp)
            matching = [
                item
                for item in issues
                if "catalog manifest sha256/size_bytes do not match catalog bytes"
                in item
            ]
            self.assertEqual(len(matching), 1, issues)
            stale = [item for item in issues if "stale versus the catalog" in item]
            self.assertEqual(stale, [], issues)

    def test_valid_mini_repo_passes(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write_mini_repo(tmp, research_rows=[_unknown_row()])
            self.assertEqual(validate_matrix.validate_repo(tmp), [])

    def test_committed_matrix_is_valid(self) -> None:
        self.assertEqual(validate_matrix.validate_repo(schema.REPO_ROOT), [])

    def test_cli_validate_committed_matrix_exits_zero(self) -> None:
        self.assertEqual(validate_matrix.main([]), 0)

    def test_committed_catalog_profile_count_and_command_counts(self) -> None:
        matrix = json.loads(schema.MATRIX_PATH.read_bytes().decode("utf-8"))
        profiles = {row["profile_id"]: row for row in matrix["catalog"]["profiles"]}
        self.assertEqual(matrix["catalog"]["profile_count"], EXPECTED_PROFILE_COUNT)
        self.assertEqual(len(profiles), EXPECTED_PROFILE_COUNT)
        for profile_id, command_count in EXPECTED_COMMAND_COUNTS.items():
            self.assertEqual(
                profiles[profile_id]["command_count"],
                command_count,
                profile_id,
            )


class GenerateMatrixTest(unittest.TestCase):
    def test_two_generations_are_byte_identical(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write_mini_repo(tmp, research_rows=[_unknown_row()])
            first = (tmp / "tool" / "powertrain_evidence" / "matrix.json").read_bytes()
            rc = generate_matrix.main(["--repo-root", str(tmp)])
            self.assertEqual(rc, 0)
            second = (tmp / "tool" / "powertrain_evidence" / "matrix.json").read_bytes()
            rc_check = generate_matrix.main(["--repo-root", str(tmp), "--check"])
            self.assertEqual(rc_check, 0)
            self.assertEqual(first, second)

    def test_check_fails_when_matrix_is_stale(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write_mini_repo(tmp)
            matrix_path = tmp / "tool" / "powertrain_evidence" / "matrix.json"
            payload = json.loads(matrix_path.read_bytes().decode("utf-8"))
            payload["catalog"]["profiles"][0]["market"] = "tampered"
            schema.write_canonical_json(matrix_path, payload)
            rc = generate_matrix.main(["--repo-root", str(tmp), "--check"])
            self.assertEqual(rc, 1)

    def test_derive_family_from_github_url(self) -> None:
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "openvehicles/Open-Vehicle-Monitoring-System-3",
                    "url": (
                        "https://github.com/openvehicles/Open-Vehicle-Monitoring-System-3"
                        "/tree/587a91d7b46bd7ce6d092e5acb7c2d3b7c5d7740"
                    ),
                }
            ),
            "openvehicles/open-vehicle-monitoring-system-3",
        )
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "meatpiHQ/wican-fw",
                    "url": "https://github.com/meatpiHQ/wican-fw/tree/bc3ae6d4ad09f32b96ca101b31950e4fbf56b825",
                }
            ),
            "meatpihq/wican-fw",
        )
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "alpha",
                    "url": "https://Example.NET/pack.csv?rev=1#section",
                }
            ),
            "example.net",
        )

    def test_github_raw_blob_api_collapse_to_repo_family(self) -> None:
        repo = "example/src"
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "other",
                    "url": "https://raw.githubusercontent.com/Example/Src/abc123/pids/a.json",
                }
            ),
            repo,
        )
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "other",
                    "url": "https://github.com/example/src/blob/def456/other/b.json",
                }
            ),
            repo,
        )
        self.assertEqual(
            schema.derive_source_family(
                {
                    "name": "other",
                    "url": "https://api.github.com/repos/example/src/contents/pids/a.json",
                }
            ),
            repo,
        )
        self.assertEqual(
            schema.derive_source_family(
                {"name": "other", "url": "https://github.com/example/src/tree/abc123"}
            ),
            schema.derive_source_family(
                {
                    "name": "other",
                    "url": "https://raw.githubusercontent.com/example/src/def456/z.csv",
                }
            ),
        )
        self.assertNotEqual(
            schema.derive_source_family(
                {"url": "https://github.com/example/src"}
            ),
            schema.derive_source_family(
                {"url": "https://github.com/example/other"}
            ),
        )

    def test_gitlab_blob_paths_collapse_to_repo_family(self) -> None:
        repo = "gitlab.com/org/repo"
        self.assertEqual(
            schema.derive_source_family(
                {"url": "https://gitlab.com/org/repo/-/blob/a/a.csv"}
            ),
            repo,
        )
        self.assertEqual(
            schema.derive_source_family(
                {"url": "https://gitlab.com/org/repo/-/blob/b/b.csv"}
            ),
            repo,
        )
        self.assertNotEqual(
            schema.derive_source_family(
                {"url": "https://gitlab.com/org/repo/-/blob/a/a.csv"}
            ),
            schema.derive_source_family(
                {"url": "https://gitlab.com/org/other/-/blob/a/a.csv"}
            ),
        )

    def test_gitlab_nested_group_keeps_full_project_path(self) -> None:
        """GitLab family is the path up to ``/-/``, including nested groups."""
        left = schema.derive_source_family(
            {"url": "https://gitlab.com/org/subgroup/repo-a/-/blob/main/a.csv"}
        )
        right = schema.derive_source_family(
            {"url": "https://gitlab.com/org/subgroup/repo-b/-/blob/main/b.csv"}
        )
        self.assertEqual(left, "gitlab.com/org/subgroup/repo-a")
        self.assertEqual(right, "gitlab.com/org/subgroup/repo-b")
        self.assertNotEqual(left, right)

    def test_github_default_port_collapses_to_repo_family(self) -> None:
        self.assertEqual(
            schema.derive_source_family(
                {"url": "https://github.com/example/src/blob/abc/a.json"}
            ),
            schema.derive_source_family(
                {"url": "https://github.com:443/example/src/blob/def/b.json"}
            ),
        )
        self.assertEqual(
            schema.derive_source_family(
                {
                    "url": "https://raw.githubusercontent.com:443/Example/Src/rev/a.json"
                }
            ),
            "example/src",
        )
        self.assertEqual(
            schema.derive_source_family(
                {"url": "https://api.github.com:443/repos/example/src/contents/a.json"}
            ),
            "example/src",
        )

    def test_extract_profile_preserves_vehicle_evidence_locator(self) -> None:
        extracted = schema.extract_profile(
            _research_profile(
                evidence="physicalVehicle",
                vehicle_evidence={"locator": "capture:fixture-2026-09-11"},
            )
        )
        self.assertEqual(
            extracted["vehicle_evidence_locator"],
            "capture:fixture-2026-09-11",
        )
        self.assertIsNone(
            schema.extract_profile(_research_profile())["vehicle_evidence_locator"]
        )


def _asset_covers_matrix(asset: str, matrix_ref: str) -> bool:
    text = asset.replace("\\", "/").strip()
    if text == matrix_ref:
        return True
    if not text:
        return False
    directory = text if text.endswith("/") else f"{text}/"
    return matrix_ref.startswith(directory)


class IsolationTest(unittest.TestCase):
    def test_matrix_path_is_not_a_pubspec_asset(self) -> None:
        matrix_ref = "tool/powertrain_evidence/matrix.json"
        pubspec = (schema.REPO_ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        self.assertNotIn(matrix_ref, pubspec)
        asset_paths = []
        in_assets = False
        for line in pubspec.splitlines():
            if line.startswith("  assets:"):
                in_assets = True
                continue
            if in_assets:
                stripped = line.strip()
                if stripped.startswith("- "):
                    asset_paths.append(stripped[2:].strip())
                elif line.startswith("  ") and not line.startswith("    "):
                    break
        for asset in asset_paths:
            self.assertFalse(
                _asset_covers_matrix(asset, matrix_ref),
                f"pubspec asset {asset!r} would bundle {matrix_ref}",
            )
        self.assertTrue(_asset_covers_matrix("tool/powertrain_evidence/", matrix_ref))
        self.assertTrue(_asset_covers_matrix("tool/powertrain_evidence", matrix_ref))
        self.assertTrue(_asset_covers_matrix("tool/", matrix_ref))
        self.assertNotIn("assets/powertrain_battery/", asset_paths)
        self.assertIn(
            "assets/powertrain_battery/powertrain_battery_catalog.json",
            asset_paths,
        )

    def test_matrix_path_is_not_referenced_from_lib(self) -> None:
        hits = []
        lib = schema.REPO_ROOT / "lib"
        for path in lib.rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            if "tool/powertrain_evidence" in text or "powertrain_evidence/matrix.json" in text:
                hits.append(str(path))
        self.assertEqual(hits, [])


class CiGuardTest(unittest.TestCase):
    def test_ci_discovers_powertrain_evidence_unittests(self) -> None:
        workflow = (
            schema.REPO_ROOT / ".github" / "workflows" / "ci.yml"
        ).read_text(encoding="utf-8")
        self.assertIn("-s tool/powertrain_evidence", workflow)
        self.assertIn("python3 -m unittest discover", workflow)
        self.assertIn("tool/powertrain_evidence/validate_matrix.py", workflow)
        self.assertIn("tool/powertrain_evidence/generate_matrix.py", workflow)


if __name__ == "__main__":
    unittest.main()
