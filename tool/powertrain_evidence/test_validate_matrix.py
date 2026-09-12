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

    def test_percent_encoded_hostname_cannot_create_an_independent_family(self) -> None:
        """URL consumers resolve ``%65xample.net`` as the same publisher."""
        row = _valid_executable_row(disposition="community-qualified")
        row["source_families"] = copy.deepcopy(row["source_families"])
        primary, corroborating = row["source_families"]
        primary.update(
            {
                "family": "example.net",
                "name": "publisher export",
                "path": "a",
                "url": "https://example.net/a",
            }
        )
        corroborating.update(
            {
                "family": "%65xample.net",
                "name": "%65xample.net",
                "path": "b",
                "url": "https://%65xample.net/b",
            }
        )

        issues = _issues_for(row)

        self.assertEqual(schema.derive_source_family(corroborating), "")
        self.assertEqual(schema.source_url_key(corroborating), "")
        self.assertIn(
            "research row fixture-valid-executable: source corroborating has no "
            "derivable family identity",
            issues,
        )
        self.assertIn(
            "research row fixture-valid-executable: community-qualified requires "
            "agreeing observations from at least two distinct source families "
            "per shipped signal",
            issues,
        )

    def test_percent_or_malformed_escape_in_any_hostname_fails_closed(self) -> None:
        for url in (
            "https://%65xample.net/a",
            "https://exa%6dple.net/a",
            "https://example%zz.net/a",
            "https://%67ithub.com/org/repo",
            "https://%67itlab.com/org/repo/-/blob/main/a",
        ):
            with self.subTest(url=url):
                source = {"name": "fallback/name", "url": url}
                self.assertEqual(schema.derive_source_family(source), "")
                self.assertEqual(schema.source_url_key(source), "")

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

    def test_dot_segment_urls_are_one_family(self) -> None:
        """``/x/../a`` and ``/a`` are the same non-GitHub family and URL key.

        RFC 3986 remove_dot_segments runs before ``derive_source_family`` and
        ``source_url_key``, so two revision pins of the same resource cannot
        corroborate as independent families.
        """
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/a"}),
            schema.derive_source_family({"url": "https://example.net/x/../a"}),
        )
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/./a"}),
            "example.net/a",
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/a"}),
            schema.source_url_key({"url": "https://example.net/x/../a"}),
        )
        self.assertNotEqual(
            schema.derive_source_family({"url": "https://example.net/a"}),
            schema.derive_source_family({"url": "https://example.net/b"}),
        )
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, url in (
            (row["source_families"][0], "https://example.net/a"),
            (row["source_families"][1], "https://example.net/x/../a"),
        ):
            source["url"] = url
            source["name"] = "example.net/a"
            source["family"] = "example.net/a"
            source["path"] = "a"
        issues = _issues_for(row)
        _only(
            issues,
            "corroborating source family example.net/a equals primary family",
        )

    def test_default_https_port_is_same_non_github_family(self) -> None:
        self.assertEqual(
            schema.derive_source_family({"url": "https://example.net/pack.csv"}),
            schema.derive_source_family({"url": "https://example.net:443/pack.csv"}),
        )
        self.assertEqual(
            schema.source_url_key({"url": "https://example.net/pack.csv"}),
            schema.source_url_key({"url": "https://example.net:443/pack.csv"}),
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
            source["family"] = "example.net/pack.csv"
            source["path"] = f"{name}.csv"
        issues = _issues_for(row)
        _only(
            issues,
            "corroborating source family example.net/pack.csv equals primary family",
        )

    def test_same_non_github_url_is_one_family(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        for source, name in zip(row["source_families"], ("alpha", "beta"), strict=True):
            source["url"] = "https://example.net/pack.csv"
            source["name"] = name
            source["family"] = "example.net/pack.csv"
            source["path"] = f"{name}.csv"
        issues = _issues_for(row)
        _only(issues, "corroborating source family example.net/pack.csv equals primary family")

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

    def test_research_row_generic_brand_alias_fails(self) -> None:
        for brand in ["byd", "tesla", "toyota", "meb", "blade", "e-gmp"]:
            row = _valid_executable_row(aliases=[f"fixture {brand}", brand])
            issues = _issues_for(row)
            _only(issues, "extrapolates entire brand/platform without model specificity")

    def test_research_row_source_missing_locator_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["locator"] = ""
        issues = _issues_for(row)
        _only(issues, "missing row-specific evidence locator")

    def test_research_row_source_prohibited_locator_fails(self) -> None:
        row = _valid_executable_row()
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["locator"] = "row:other-row"
        issues = _issues_for(row)
        self.assertTrue(
            any("locator uses prohibited inheritance reference" in i for i in issues),
            issues,
        )

    def test_research_row_cross_model_source_path_fails(self) -> None:
        row = _valid_executable_row(id="byd-atto-3")
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/nissan/leaf.json"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than byd-atto-3")

    def test_research_row_cross_model_source_path_unlisted_brand_fails(self) -> None:
        """Universal cross-model check: brands not in the old 5-brand list also fail."""
        row = _valid_executable_row(id="bmw-i3")
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model3.json"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than bmw-i3")

    def test_research_row_cross_row_wrong_source_locator_fails(self) -> None:
        """Source locator referencing a foreign vehicle model is rejected as cross-model wrong source."""
        row = _valid_executable_row(id="nissan-leaf")
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["locator"] = "Ioniq 5 polls"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than nissan-leaf")

    def test_research_row_cross_model_tesla_model_y_source_for_model_3_fails(self) -> None:
        """Model 3 referencing Model Y source is rejected as cross-model without reviewed binding."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model 3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model_y.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than tesla-model-3")

    def test_research_row_cross_model_ioniq_6_source_for_ioniq_5_fails(self) -> None:
        """Ioniq 5 referencing Ioniq 6 source is rejected as cross-model."""
        row = _valid_executable_row(id="hyundai-ioniq-5", aliases=["Hyundai Ioniq 5"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/hyundai/ioniq6.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than hyundai-ioniq-5")

    def test_research_row_cross_model_egmp_alias_does_not_override_foreign_source_fails(self) -> None:
        """E-GMP platform text in alias and locator cannot authorize a Tesla source for Kia EV6."""
        row = _valid_executable_row(id="kia-ev6", aliases=["Kia EV6 E-GMP"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model_y.json"
        row["source_families"][0]["locator"] = "E-GMP note"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than kia-ev6")

    def test_research_row_cross_model_meb_alias_does_not_override_foreign_source_fails(self) -> None:
        """MEB platform text in alias and locator cannot authorize a BYD source for VW ID.4."""
        row = _valid_executable_row(id="volkswagen-id4", aliases=["ID4 MEB"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/byd/atto3.json"
        row["source_families"][0]["locator"] = "MEB note"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than volkswagen-id4")

    def test_research_row_cross_model_synthetic_unlisted_brand_fails(self) -> None:
        """Synthetic unlisted brand and model are protected by universal cross-model rules."""
        row = _valid_executable_row(id="acme-roadster-1", aliases=["ACME Roadster 1"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/zenith/cruiser2.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than acme-roadster-1")

    def test_research_row_cross_model_bmw_ix_source_for_ix3_fails(self) -> None:
        """BMW iX3 referencing BMW iX source is rejected as cross-model."""
        row = _valid_executable_row(id="bmw-ix3", aliases=["BMW iX3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/bmw/ix.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than bmw-ix3")

    def test_research_row_cross_model_ford_mustang_source_for_mustang_mach_e_fails(self) -> None:
        """Ford Mustang Mach-E referencing base Ford Mustang source is rejected as cross-model."""
        row = _valid_executable_row(id="ford-mustang-mach-e", aliases=["Ford Mustang Mach-E"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/ford/mustang.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than ford-mustang-mach-e")

    def test_research_row_cross_model_toyota_prius_c_source_for_prius_fails(self) -> None:
        """Toyota Prius referencing Prius C source is rejected as cross-model."""
        row = _valid_executable_row(id="toyota-prius", aliases=["Toyota Prius"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/toyota/prius_c.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than toyota-prius")

    def test_research_row_cross_model_synthetic_same_brand_different_model_fails(self) -> None:
        """Synthetic model referencing another model of same brand without binding is rejected."""
        row = _valid_executable_row(id="acme-roadster-1", aliases=["ACME Roadster 1"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/acme/roadster_2.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than acme-roadster-1")

    def test_research_row_synthetic_unlisted_brand_passes_with_matching_model(self) -> None:
        """Synthetic unlisted brand with exact matching model passes."""
        row = _valid_executable_row(id="acme-roadster-1", aliases=["ACME Roadster 1"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/acme/roadster1.json"
        row["source_families"][0]["locator"] = "record 1"
        self.assertEqual(_issues_for(row), [])

    def test_research_row_same_model_source_passes(self) -> None:
        """Same model source within same make passes validation."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model 3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model3.json"
        row["source_families"][0]["locator"] = "record 1"
        self.assertEqual(_issues_for(row), [])

    def test_research_row_cross_model_locator_text_cannot_authorize_foreign_model(self) -> None:
        """Model 3 referencing Model Y with locator prose 'Model 3 applicability entry' fails."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model 3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model_y.json"
        row["source_families"][0]["locator"] = "Model 3 applicability entry"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than tesla-model-3")

    def test_research_row_cross_model_negation_locator_fails(self) -> None:
        """Ioniq 5 referencing Ioniq 6 with locator 'NOT APPLICABLE TO Ioniq 5' fails."""
        row = _valid_executable_row(id="hyundai-ioniq-5", aliases=["Hyundai Ioniq 5"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/hyundai/ioniq6.json"
        row["source_families"][0]["locator"] = "NOT APPLICABLE TO Ioniq 5"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than hyundai-ioniq-5")

    def test_research_row_cross_model_update_filename_does_not_bypass_model_check(self) -> None:
        """Model 3 referencing Model Y with 'update' in filename is rejected."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model 3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model_y_update.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than tesla-model-3")

    def test_research_row_cross_model_alias_cannot_authorize_foreign_model(self) -> None:
        """Model 3 with alias 'Tesla Model Y' cannot reference Model Y profile."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model Y"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/tesla/model_y.json"
        row["source_families"][0]["locator"] = "record 1"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than tesla-model-3")

    def test_research_row_cross_model_wildcard_locator_cannot_authorize_unreviewed_source(self) -> None:
        """VW ID.4 referencing unreviewed meb.json with wildcard 'Volkswagen ID* applicability' is rejected."""
        row = _valid_executable_row(id="volkswagen-id4", aliases=["Volkswagen ID.4"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "vehicle_profiles/volkswagen/meb.json"
        row["source_families"][0]["locator"] = "Volkswagen ID* applicability"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than volkswagen-id4")

    def test_research_row_reviewed_shared_source_binding_passes(self) -> None:
        """VW ID.4 referencing explicitly reviewed shared MEB source passes validation."""
        row = _valid_executable_row(id="volkswagen-id4-meb", aliases=["Volkswagen ID.4"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "volkswagen/MEB.json"
        row["source_families"][0]["locator"] = "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"
        row["source_families"][0]["family"] = "iternio/ev-obd-pids"
        row["source_families"][0]["name"] = "iternio/ev-obd-pids"
        row["source_families"][0]["url"] = "https://github.com/iternio/ev-obd-pids"
        row["source_families"][0]["revision"] = "c45a018b60b3341d2d8bfb22cf0491c4e878165a"
        row["source_families"][0]["artifact_sha256"] = "434936a9b4571b63b013a159c1b38fcffdd70651f4a3966ae6d3026d9f42b03d"
        row["independence_rationale"] = "primary iternio/ev-obd-pids and corroborating other/src are different GitHub orgs"
        self.assertEqual(_issues_for(row), [])

    def test_research_row_reviewed_shared_source_binding_with_relative_prefix_passes(self) -> None:
        """VW ID.4 referencing shared MEB source with leading './' passes normalization."""
        row = _valid_executable_row(id="volkswagen-id4-meb", aliases=["Volkswagen ID.4"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "./volkswagen/MEB.json"
        row["source_families"][0]["locator"] = "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"
        row["source_families"][0]["family"] = "iternio/ev-obd-pids"
        row["source_families"][0]["name"] = "iternio/ev-obd-pids"
        row["source_families"][0]["url"] = "https://github.com/iternio/ev-obd-pids"
        row["source_families"][0]["revision"] = "c45a018b60b3341d2d8bfb22cf0491c4e878165a"
        row["source_families"][0]["artifact_sha256"] = "434936a9b4571b63b013a159c1b38fcffdd70651f4a3966ae6d3026d9f42b03d"
        row["independence_rationale"] = "primary iternio/ev-obd-pids and corroborating other/src are different GitHub orgs"
        self.assertEqual(_issues_for(row), [])

    def test_research_row_unreviewed_target_on_shared_source_fails(self) -> None:
        """Tesla Model 3 referencing MEB shared source fails because it is not in the reviewed binding."""
        row = _valid_executable_row(id="tesla-model-3", aliases=["Tesla Model 3"])
        row["source_families"] = copy.deepcopy(row["source_families"])
        row["source_families"][0]["path"] = "volkswagen/MEB.json"
        row["source_families"][0]["locator"] = "volkswagen:id* alias; ATSP7 ATCP17 ATSH FC007B"
        row["source_families"][0]["family"] = "iternio/ev-obd-pids"
        row["source_families"][0]["name"] = "iternio/ev-obd-pids"
        row["source_families"][0]["url"] = "https://github.com/iternio/ev-obd-pids"
        row["source_families"][0]["revision"] = "c45a018b60b3341d2d8bfb22cf0491c4e878165a"
        row["source_families"][0]["artifact_sha256"] = "434936a9b4571b63b013a159c1b38fcffdd70651f4a3966ae6d3026d9f42b03d"
        row["independence_rationale"] = "primary iternio/ev-obd-pids and corroborating other/src are different GitHub orgs"
        issues = _issues_for(row)
        _only(issues, "belongs to a different vehicle model than tesla-model-3")

    def test_research_row_reviewed_shared_source_binding_exact_scope_required(self) -> None:
        """Explicit ReviewedEvidenceBinding enforces exact equality across all fields and rejects caller wildcards."""
        from validate_matrix import (
            REVIEWED_EVIDENCE_BINDINGS,
            ReviewedEvidenceBinding,
            _find_reviewed_evidence_binding,
        )

        test_binding = ReviewedEvidenceBinding(
            target_scope="synthetic-model-a",
            path="vehicle_profiles/synthetic/multi.json",
            signal="battery_profile",
            source_repository="synthetic/repo",
            revision=SHA40_A,
            source_hash=SHA64_A,
            locator="Model A exact locator",
        )
        REVIEWED_EVIDENCE_BINDINGS.append(test_binding)
        try:
            # 1. Matching exact scope, locator, repo, revision, hash, and signal passes
            row_ok = _valid_executable_row(
                id="synthetic-model-a",
                aliases=["Synthetic Model A"],
            )
            row_ok["source_families"] = copy.deepcopy(row_ok["source_families"])
            row_ok["source_families"][0]["path"] = "vehicle_profiles/synthetic/multi.json"
            row_ok["source_families"][0]["locator"] = "Model A exact locator"
            row_ok["source_families"][0]["family"] = "synthetic/repo"
            row_ok["source_families"][0]["name"] = "synthetic/repo"
            row_ok["source_families"][0]["url"] = "https://github.com/synthetic/repo"
            row_ok["source_families"][0]["revision"] = SHA40_A
            row_ok["source_families"][0]["artifact_sha256"] = SHA64_A
            row_ok["independence_rationale"] = "primary synthetic/repo and corroborating other/src are different GitHub orgs"
            row_ok["signals"] = copy.deepcopy(row_ok["signals"])
            row_ok["signals"][0]["id"] = "battery_profile"
            self.assertEqual(_issues_for(row_ok), [])

            # 2. Scope mismatch fails (synthetic-model-b is not authorized)
            row_mismatch_model = copy.deepcopy(row_ok)
            row_mismatch_model["id"] = "synthetic-model-b"
            row_mismatch_model["aliases"] = ["Synthetic Model B"]
            issues_scope = _issues_for(row_mismatch_model)
            _only(issues_scope, "belongs to a different vehicle model than synthetic-model-b")

            # 3. Signal mismatch fails
            row_bad_signal = copy.deepcopy(row_ok)
            row_bad_signal["signals"] = copy.deepcopy(row_ok["signals"])
            row_bad_signal["signals"][0]["id"] = "soh"
            issues_sig = _issues_for(row_bad_signal)
            _only(issues_sig, "belongs to a different vehicle model than synthetic-model-a")

            # 4a. Repository mismatch fails (different repository)
            row_bad_repo = copy.deepcopy(row_ok)
            row_bad_repo["source_families"][0]["family"] = "other/repo"
            row_bad_repo["source_families"][0]["name"] = "other/repo"
            row_bad_repo["source_families"][0]["url"] = "https://github.com/other/repo"
            row_bad_repo["independence_rationale"] = "primary other/repo and corroborating other/src are different GitHub orgs"
            issues_repo = _issues_for(row_bad_repo)
            _only(issues_repo, "belongs to a different vehicle model than synthetic-model-a")

            # 4b. Repository substring mismatch fails (substring of repository must NOT match)
            row_sub_repo = copy.deepcopy(row_ok)
            row_sub_repo["source_families"][0]["family"] = "synthetic/rep"
            row_sub_repo["source_families"][0]["name"] = "synthetic/rep"
            row_sub_repo["source_families"][0]["url"] = "https://github.com/synthetic/rep"
            row_sub_repo["independence_rationale"] = "primary synthetic/rep and corroborating other/src are different GitHub orgs"
            issues_sub_repo = _issues_for(row_sub_repo)
            _only(issues_sub_repo, "belongs to a different vehicle model than synthetic-model-a")

            # 5. Revision mismatch fails
            row_bad_rev = copy.deepcopy(row_ok)
            row_bad_rev["source_families"][0]["revision"] = SHA40_B
            issues_rev = _issues_for(row_bad_rev)
            _only(issues_rev, "belongs to a different vehicle model than synthetic-model-a")

            # 6. Artifact hash mismatch fails
            row_bad_hash = copy.deepcopy(row_ok)
            row_bad_hash["source_families"][0]["artifact_sha256"] = "c" * 64
            issues_hash = _issues_for(row_bad_hash)
            _only(issues_hash, "belongs to a different vehicle model than synthetic-model-a")

            # 7a. Locator mismatch fails (different locator)
            row_bad_locator = copy.deepcopy(row_ok)
            row_bad_locator["source_families"][0]["locator"] = "Model B different locator"
            issues_loc = _issues_for(row_bad_locator)
            _only(issues_loc, "belongs to a different vehicle model than synthetic-model-a")

            # 7b. Locator substring mismatch fails (substring of locator must NOT match)
            row_sub_loc = copy.deepcopy(row_ok)
            row_sub_loc["source_families"][0]["locator"] = "Model A exact"
            issues_sub_loc = _issues_for(row_sub_loc)
            _only(issues_sub_loc, "belongs to a different vehicle model than synthetic-model-a")

            # 8. Negative target variations: unreviewed market, year, or combinations return None and fail row validation
            for unreviewed_target in (
                "synthetic-model-a-us",
                "synthetic-model-a-2030",
                "synthetic-model-a-us-2026-community",
                "synthetic-model-a-eu-2030-community",
            ):
                row_unreviewed = copy.deepcopy(row_ok)
                row_unreviewed["id"] = unreviewed_target
                row_unreviewed["aliases"] = [unreviewed_target.replace("-", " ").title()]
                issues_unreviewed = _issues_for(row_unreviewed)
                _only(
                    issues_unreviewed,
                    f"belongs to a different vehicle model than {unreviewed_target}",
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id=unreviewed_target,
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    ),
                    f"Target {unreviewed_target!r} must not match binding for 'synthetic-model-a'",
                )

            # 9. Direct matcher call rejects caller wildcards '*' and '?'
            for wildcard in ("*", "?"):
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path="vehicle_profiles/synthetic/multi.json",
                        signal=wildcard,
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository=wildcard,
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=wildcard,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=wildcard,
                        locator="Model A exact locator",
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator=wildcard,
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id=wildcard,
                        path="vehicle_profiles/synthetic/multi.json",
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    )
                )
                self.assertIsNone(
                    _find_reviewed_evidence_binding(
                        target_id="synthetic-model-a",
                        path=wildcard,
                        signal="battery_profile",
                        repository="synthetic/repo",
                        revision=SHA40_A,
                        source_hash=SHA64_A,
                        locator="Model A exact locator",
                    )
                )
        finally:
            REVIEWED_EVIDENCE_BINDINGS.remove(test_binding)

    def test_reviewed_evidence_binding_exact_target_scope_negative_probe(self) -> None:
        """Fixing all source fields and changing only target_id: unreviewed years/markets return None."""
        from validate_matrix import (
            REVIEWED_EVIDENCE_BINDINGS,
            _find_reviewed_evidence_binding,
            _target_scope_matches,
        )

        # 0. Direct token matching edge cases: empty/punctuation must never match
        self.assertFalse(_target_scope_matches("---", "___"))
        self.assertFalse(_target_scope_matches("", ""))
        self.assertFalse(_target_scope_matches("   ", "   "))
        self.assertTrue(_target_scope_matches("byd-atto3", "byd-atto3"))
        self.assertTrue(_target_scope_matches("byd-atto-3", "byd-atto3"))
        self.assertFalse(_target_scope_matches("byd-atto3-us", "byd-atto3"))
        self.assertFalse(_target_scope_matches("byd-atto3-2030", "byd-atto3"))

        byd_record = next(
            (
                item
                for item in REVIEWED_EVIDENCE_BINDINGS
                if item.target_scope == "byd-atto3"
                and "byd_202410_update.json" in item.path
                and item.signal == "battery_profile"
            ),
            None,
        )
        self.assertIsNotNone(byd_record)
        assert byd_record is not None

        byd_source_args = {
            "path": byd_record.path,
            "locator": byd_record.locator,
            "signal": byd_record.signal,
            "repository": byd_record.source_repository,
            "revision": byd_record.revision,
            "source_hash": byd_record.source_hash,
        }

        # 1. Registered exact target and approved aliases match
        for authorized in ("byd-atto3", "byd-atto-3", "byd-atto3-2022-2024-community"):
            matched = _find_reviewed_evidence_binding(
                target_id=authorized, **byd_source_args
            )
            self.assertIsNotNone(matched, f"Expected {authorized!r} to match")
            assert matched is not None
            self.assertIn(matched.target_scope, ("byd-atto3", "byd-atto-3", "byd-atto3-2022-2024-community"))

        # 2. Unreviewed target variations (market, year, combo) must return None
        unreviewed_byd_targets = (
            "byd-atto3-us",
            "byd-atto3-eu",
            "byd-atto3-au",
            "byd-atto3-cn",
            "byd-atto3-2030",
            "byd-atto3-2025",
            "byd-atto3-2024",
            "byd-atto3-us-2026-community",
            "byd-atto3-eu-2030-community",
            "byd-atto3?",
            "---",
            "",
        )
        for unreviewed in unreviewed_byd_targets:
            matched = _find_reviewed_evidence_binding(
                target_id=unreviewed, **byd_source_args
            )
            self.assertIsNone(
                matched,
                f"Unreviewed target {unreviewed!r} must return None instead of inheriting reviewed status",
            )

        # 3. Kona binding checks
        kona_record = next(
            (
                item
                for item in REVIEWED_EVIDENCE_BINDINGS
                if item.target_scope == "hyundai-kona"
                and item.signal == "battery_profile"
            ),
            None,
        )
        self.assertIsNotNone(kona_record)
        assert kona_record is not None
        kona_source_args = {
            "path": kona_record.path,
            "locator": kona_record.locator,
            "signal": kona_record.signal,
            "repository": kona_record.source_repository,
            "revision": kona_record.revision,
            "source_hash": kona_record.source_hash,
        }
        for authorized in ("hyundai-kona", "hyundai-kona-electric", "hyundai-kona-electric-os-2019-2023-community"):
            self.assertIsNotNone(
                _find_reviewed_evidence_binding(target_id=authorized, **kona_source_args),
                f"Expected {authorized!r} to match",
            )
        for unreviewed in ("hyundai-kona-us", "hyundai-kona-2030", "hyundai-kona-us-2025-community", "hyundai-kona?"):
            self.assertIsNone(
                _find_reviewed_evidence_binding(target_id=unreviewed, **kona_source_args),
                f"Unreviewed target {unreviewed!r} must return None",
            )

        # 4. Kia Soul binding checks
        soul_record = next(
            (
                item
                for item in REVIEWED_EVIDENCE_BINDINGS
                if item.target_scope == "kia-soul"
                and item.signal == "battery_profile"
            ),
            None,
        )
        self.assertIsNotNone(soul_record)
        assert soul_record is not None
        soul_source_args = {
            "path": soul_record.path,
            "locator": soul_record.locator,
            "signal": soul_record.signal,
            "repository": soul_record.source_repository,
            "revision": soul_record.revision,
            "source_hash": soul_record.source_hash,
        }
        for authorized in ("kia-soul", "kia-soul-ev", "kia-soul-ev-sk3-2020-community"):
            self.assertIsNotNone(
                _find_reviewed_evidence_binding(target_id=authorized, **soul_source_args),
                f"Expected {authorized!r} to match",
            )
        for unreviewed in ("kia-soul-us", "kia-soul-2030", "kia-soul-us-2025-community", "kia-soul?"):
            self.assertIsNone(
                _find_reviewed_evidence_binding(target_id=unreviewed, **soul_source_args),
                f"Unreviewed target {unreviewed!r} must return None",
            )

        # 5. Hyundai Ioniq 6 binding checks
        ioniq6_record = next(
            (
                item
                for item in REVIEWED_EVIDENCE_BINDINGS
                if item.target_scope == "hyundai-ioniq6"
                and item.signal == "battery_profile"
            ),
            None,
        )
        self.assertIsNotNone(ioniq6_record)
        assert ioniq6_record is not None
        ioniq6_source_args = {
            "path": ioniq6_record.path,
            "locator": ioniq6_record.locator,
            "signal": ioniq6_record.signal,
            "repository": ioniq6_record.source_repository,
            "revision": ioniq6_record.revision,
            "source_hash": ioniq6_record.source_hash,
        }
        for authorized in ("hyundai-ioniq6", "hyundai-ioniq-6", "hyundai-ioniq6-egmp-2022-2024-community"):
            self.assertIsNotNone(
                _find_reviewed_evidence_binding(target_id=authorized, **ioniq6_source_args),
                f"Expected {authorized!r} to match",
            )
        for unreviewed in ("hyundai-ioniq6-us", "hyundai-ioniq6-2030", "hyundai-ioniq6-us-2025-community", "hyundai-ioniq6?"):
            self.assertIsNone(
                _find_reviewed_evidence_binding(target_id=unreviewed, **ioniq6_source_args),
                f"Unreviewed target {unreviewed!r} must return None",
            )

    def test_reviewed_evidence_binding_construction_validation(self) -> None:
        """ReviewedEvidenceBinding.__post_init__ rejects empty strings, whitespace, and wildcards."""
        from validate_matrix import ReviewedEvidenceBinding

        valid_kwargs = {
            "target_scope": "test-scope",
            "path": "test/path.json",
            "signal": "battery_profile",
            "source_repository": "test/repo",
            "revision": SHA40_A,
            "source_hash": SHA64_A,
            "locator": "test locator",
        }

        # Valid binding instantiates cleanly
        b = ReviewedEvidenceBinding(**valid_kwargs)
        self.assertEqual(b.target_scope, "test-scope")

        # Each field rejects empty string and whitespace
        for field in valid_kwargs:
            for bad_val in ("", "   "):
                kw = dict(valid_kwargs, **{field: bad_val})
                with self.assertRaises(ValueError, msg=f"{field}={bad_val!r}"):
                    ReviewedEvidenceBinding(**kw)

        # Each field rejects wildcard '*' and '?'
        for field in valid_kwargs:
            for wildcard in ("*", "?"):
                kw = dict(valid_kwargs, **{field: wildcard})
                with self.assertRaises(ValueError, msg=f"{field}={wildcard!r}"):
                    ReviewedEvidenceBinding(**kw)

        # Non-locator fields reject wildcards in string
        for field in ("target_scope", "path", "signal", "source_repository", "revision", "source_hash"):
            for bad_str in ("foo*bar", "foo?bar"):
                kw = dict(valid_kwargs, **{field: bad_str})
                with self.assertRaises(ValueError, msg=f"{field}={bad_str!r}"):
                    ReviewedEvidenceBinding(**kw)

    def test_reviewed_evidence_identity_normalization(self) -> None:
        """_normalize_repo_identity and _normalize_locator_identity normalize formats cleanly."""
        from validate_matrix import _normalize_repo_identity, _normalize_locator_identity

        # Repository URL normalization
        expected_repo = "meatpihq/wican-fw"
        for candidate in (
            "meatpihq/wican-fw",
            "meatpiHQ/wican-fw",
            "meatpiHQ/wican-fw/",
            "meatpiHQ/wican-fw.git",
            "meatpiHQ/wican-fw.git/",
            "https://github.com/meatpiHQ/wican-fw",
            "https://github.com/meatpiHQ/wican-fw/",
            "https://github.com/meatpiHQ/wican-fw.git",
            "https://github.com/meatpiHQ/wican-fw.git/",
            "http://github.com/meatpiHQ/wican-fw.git",
            "git@github.com:meatpiHQ/wican-fw.git",
            "ssh://git@github.com/meatpiHQ/wican-fw.git",
            "ssh://git@github.com/meatpiHQ/wican-fw.git/",
            "github.com/meatpiHQ/wican-fw.git",
        ):
            self.assertEqual(
                _normalize_repo_identity(candidate),
                expected_repo,
                msg=f"Failed to normalize repo: {candidate}",
            )

        # Locator whitespace and case normalization
        self.assertEqual(
            _normalize_locator_identity("  ATSH7E7;   220005  SOC_D=B4  \n\t "),
            "atsh7e7; 220005 soc_d=b4",
        )

    def test_shared_source_with_matching_locators_passes(self) -> None:
        """Multiple vehicles sharing a multi-model repository pass when their locators match their own scope."""
        leaf_row = _valid_executable_row(
            id="nissan-leaf",
            aliases=["Nissan Leaf"],
        )
        leaf_row["source_families"] = [
            {
                "artifact_sha256": SHA64_A,
                "family": "shared/obd",
                "id": "primary",
                "license": "MIT",
                "locator": "Leaf polls",
                "name": "shared/obd",
                "path": "shared/obd.json",
                "revision": SHA40_A,
                "role": "primary",
                "url": "https://github.com/shared/obd",
            },
            {
                "artifact_sha256": SHA64_B,
                "family": "other/src",
                "id": "corroborating",
                "license": "MIT",
                "locator": "Leaf polls",
                "name": "other/src",
                "path": "leaf.json",
                "revision": SHA40_B,
                "role": "corroborating",
                "url": "https://github.com/other/src",
            },
        ]
        self.assertEqual(_issues_for(leaf_row), [])

        ioniq_row = _valid_executable_row(
            id="hyundai-ioniq5",
            aliases=["Hyundai Ioniq 5"],
        )
        ioniq_row["source_families"] = [
            {
                "artifact_sha256": SHA64_A,
                "family": "shared/obd",
                "id": "primary",
                "license": "MIT",
                "locator": "Ioniq 5 polls",
                "name": "shared/obd",
                "path": "shared/obd.json",
                "revision": SHA40_A,
                "role": "primary",
                "url": "https://github.com/shared/obd",
            },
            {
                "artifact_sha256": SHA64_B,
                "family": "other/src",
                "id": "corroborating",
                "license": "MIT",
                "locator": "Ioniq 5 polls",
                "name": "other/src",
                "path": "ioniq5.json",
                "revision": SHA40_B,
                "role": "corroborating",
                "url": "https://github.com/other/src",
            },
        ]
        self.assertEqual(_issues_for(ioniq_row), [])


def _valid_community_catalog_profile(**overrides: object) -> dict:
    profile = {
        "commands": [_concrete_command()],
        "evidence": "sourceBacked",
        "id": "byd-atto3-2022-2024-community",
        "make": "BYD",
        "market": "Global",
        "model": "Atto 3",
        "powertrain": "BEV",
        "secondary_sources": [
            {
                "artifact_sha256": SHA64_B,
                "license": "GPL-3.0",
                "locator": "ATSH7E7 220005",
                "name": "meatpiHQ/wican-fw",
                "path": "vehicle_profiles/byd/atto3.json",
                "revision": SHA40_B,
                "url": f"https://github.com/meatpiHQ/wican-fw/tree/{SHA40_B}",
            }
        ],
        "source": {
            "artifact_sha256": SHA64_A,
            "license": "MIT",
            "locator": "vehicle_atto3_polls[] ISOTP_STD",
            "name": "openvehicles/Open-Vehicle-Monitoring-System-3",
            "path": "vehicle/OVMS.V3/components/vehicle_byd_atto3/src/vehicle_byd_atto3.cpp",
            "revision": SHA40_A,
            "url": f"https://github.com/openvehicles/Open-Vehicle-Monitoring-System-3/tree/{SHA40_A}",
        },
        "status": "community",
        "variant": "e-Platform 3.0 Blade",
        "year_from": 2022,
        "year_to": 2024,
    }
    profile.update(overrides)
    return profile


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

    def test_community_catalog_profile_evidence_valid_passes(self) -> None:
        prof = _valid_community_catalog_profile()
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        self.assertEqual(issues, [])

    def test_community_catalog_profile_missing_primary_source_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        del prof["source"]
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile missing primary source object")

    def test_community_catalog_profile_primary_source_missing_license_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["license"] = ""
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source missing licence")

    def test_community_catalog_profile_primary_source_non_immutable_revision_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["revision"] = "main"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source missing immutable revision pin")

    def test_community_catalog_profile_primary_source_invalid_artifact_sha_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["artifact_sha256"] = "badsha"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source missing valid artifact sha256")

    def test_community_catalog_profile_primary_source_missing_locator_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["locator"] = ""
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source missing row-specific evidence locator")

    def test_community_catalog_profile_primary_source_prohibited_locator_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["locator"] = "row:byd-atto-3"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source locator uses prohibited inheritance reference")

    def test_community_catalog_profile_primary_source_non_derivable_family_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["url"] = "not_a_url"
        prof["source"]["name"] = ""
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "primary source has no derivable family identity")

    def test_community_catalog_profile_missing_secondary_sources_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"] = []
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile requires at least one secondary source")

    def test_community_catalog_profile_secondary_source_non_dict_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"] = ["invalid"]
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] must be an object")

    def test_community_catalog_profile_secondary_source_missing_license_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["license"] = ""
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] missing licence")

    def test_community_catalog_profile_secondary_source_non_immutable_revision_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["revision"] = "dev"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] missing immutable revision pin")

    def test_community_catalog_profile_secondary_source_invalid_artifact_sha_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["artifact_sha256"] = "12345"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] missing valid artifact sha256")

    def test_community_catalog_profile_secondary_source_missing_locator_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["locator"] = ""
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] missing row-specific evidence locator")

    def test_community_catalog_profile_secondary_source_prohibited_locator_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["locator"] = "sibling:other-profile"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "secondary source [0] locator uses prohibited inheritance reference")

    def test_community_catalog_profile_secondary_source_same_family_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["secondary_sources"][0]["url"] = prof["source"]["url"]
        prof["secondary_sources"][0]["name"] = prof["source"]["name"]
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile requires independent corroborating source family")

    def test_community_catalog_profile_blank_market_scope_fails(self) -> None:
        for market in ["", "  ", "TBD", "UNKNOWN"]:
            prof = _valid_community_catalog_profile(market=market)
            issues = validate_matrix.validate_catalog_object(
                {"profiles": [prof]}, validate_evidence=True
            )
            _only(issues, "community profile missing exact market scope")

    def test_community_catalog_profile_missing_make_fails(self) -> None:
        prof = _valid_community_catalog_profile(make="")
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile missing make scope")

    def test_community_catalog_profile_missing_model_fails(self) -> None:
        prof = _valid_community_catalog_profile(model="")
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile missing model scope")

    def test_community_catalog_profile_non_integer_year_fails(self) -> None:
        prof = _valid_community_catalog_profile(year_from="2022")
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile year_from and year_to must be integer years")

    def test_community_catalog_profile_reversed_years_fails(self) -> None:
        prof = _valid_community_catalog_profile(year_from=2025, year_to=2022)
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile reversed year range: 2025 > 2022")

    def test_community_catalog_profile_out_of_bounds_years_fails(self) -> None:
        prof = _valid_community_catalog_profile(year_from=1850)
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "community profile year range 1850-2024 outside plausible bounds")

    def test_community_catalog_profile_cross_model_source_fails(self) -> None:
        prof = _valid_community_catalog_profile()
        prof["source"]["path"] = "vehicle_profiles/nissan/leaf.json"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than BYD Atto 3")

    def test_community_catalog_profile_cross_model_tesla_model_y_for_model_3_fails(self) -> None:
        """Catalog: Model 3 referencing Model Y source is rejected as cross-model."""
        prof = _valid_community_catalog_profile(
            id="tesla-model-3-community",
            make="Tesla",
            model="Model 3",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/tesla/model_y.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Tesla Model 3")

    def test_community_catalog_profile_cross_model_ioniq_6_for_ioniq_5_fails(self) -> None:
        """Catalog: Ioniq 5 referencing Ioniq 6 source is rejected as cross-model."""
        prof = _valid_community_catalog_profile(
            id="hyundai-ioniq-5-community",
            make="Hyundai",
            model="Ioniq 5",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/hyundai/ioniq6.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Hyundai Ioniq 5")

    def test_community_catalog_profile_cross_model_egmp_alias_does_not_override_foreign_source_fails(self) -> None:
        """Catalog: E-GMP note cannot authorize Tesla source for Kia EV6."""
        prof = _valid_community_catalog_profile(
            id="kia-ev6-community",
            make="Kia",
            model="EV6",
            variant="Kia EV6 E-GMP",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/tesla/model_y.json"
        prof["source"]["locator"] = "E-GMP note"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Kia EV6")

    def test_community_catalog_profile_cross_model_meb_alias_does_not_override_foreign_source_fails(self) -> None:
        """Catalog: MEB note cannot authorize BYD source for VW ID.4."""
        prof = _valid_community_catalog_profile(
            id="volkswagen-id4-community",
            make="Volkswagen",
            model="ID.4",
            variant="ID4 MEB",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/byd/atto3.json"
        prof["source"]["locator"] = "MEB note"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Volkswagen ID.4")

    def test_community_catalog_profile_cross_model_bmw_ix_for_ix3_fails(self) -> None:
        """Catalog: BMW iX3 referencing BMW iX source is rejected as cross-model."""
        prof = _valid_community_catalog_profile(
            id="bmw-ix3-community",
            make="BMW",
            model="iX3",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/bmw/ix.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than BMW iX3")

    def test_community_catalog_profile_cross_model_ford_mustang_for_mustang_mach_e_fails(self) -> None:
        """Catalog: Ford Mustang Mach-E referencing Ford Mustang source is rejected as cross-model."""
        prof = _valid_community_catalog_profile(
            id="ford-mustang-mach-e-community",
            make="Ford",
            model="Mustang Mach-E",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/ford/mustang.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Ford Mustang Mach-E")

    def test_community_catalog_profile_cross_model_locator_prose_cannot_authorize(self) -> None:
        """Catalog: Model 3 referencing Model Y with locator 'Model 3 applicability entry' fails."""
        prof = _valid_community_catalog_profile(
            id="tesla-model3-community",
            make="Tesla",
            model="Model 3",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/tesla/model_y.json"
        prof["source"]["locator"] = "Model 3 applicability entry"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Tesla Model 3")

    def test_community_catalog_profile_cross_model_negation_locator_fails(self) -> None:
        """Catalog: Ioniq 5 referencing Ioniq 6 with locator 'NOT APPLICABLE TO Ioniq 5' fails."""
        prof = _valid_community_catalog_profile(
            id="hyundai-ioniq-5-community",
            make="Hyundai",
            model="Ioniq 5",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/hyundai/ioniq6.json"
        prof["source"]["locator"] = "NOT APPLICABLE TO Ioniq 5"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Hyundai Ioniq 5")

    def test_community_catalog_profile_cross_model_update_filename_fails(self) -> None:
        """Catalog: Model 3 referencing Model Y with 'update' in filename fails."""
        prof = _valid_community_catalog_profile(
            id="tesla-model3-community",
            make="Tesla",
            model="Model 3",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/tesla/model_y_update.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Tesla Model 3")

    def test_community_catalog_profile_cross_model_alias_fails(self) -> None:
        """Catalog: Model 3 with variant 'Tesla Model Y' cannot reference Model Y profile."""
        prof = _valid_community_catalog_profile(
            id="tesla-model3-community",
            make="Tesla",
            model="Model 3",
            variant="Tesla Model Y",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/tesla/model_y.json"
        prof["source"]["locator"] = "record 1"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Tesla Model 3")

    def test_community_catalog_profile_cross_model_wildcard_locator_fails(self) -> None:
        """Catalog: VW ID.4 referencing unreviewed meb.json with 'Volkswagen ID* applicability' fails."""
        prof = _valid_community_catalog_profile(
            id="volkswagen-id4-community",
            make="Volkswagen",
            model="ID.4",
        )
        prof["secondary_sources"] = [
            {
                "artifact_sha256": SHA64_B,
                "license": "MIT",
                "locator": "signals",
                "name": "comm/sig",
                "path": "signalsets/v3/default.json",
                "revision": SHA40_B,
                "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
            }
        ]
        prof["source"]["path"] = "vehicle_profiles/volkswagen/meb.json"
        prof["source"]["locator"] = "Volkswagen ID* applicability"
        issues = validate_matrix.validate_catalog_object(
            {"profiles": [prof]}, validate_evidence=True
        )
        _only(issues, "belongs to a different vehicle model than Volkswagen ID.4")


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

    def test_research_row_disposition_conflicts_with_catalog_status(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(id="byd-atto3-2022-2024-community")
            row = _unknown_row(
                id="byd-atto-3",
                disposition="transport-blocked",
                catalog_presence="present",
                catalog_profile_ids=["byd-atto3-2022-2024-community"],
                firmware_scope="firmware-1",
                market="Global",
                year_from=2022,
                year_to=2024,
            )
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[row],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "research row byd-atto-3: disposition=transport-blocked conflicts with catalog profile byd-atto3-2022-2024-community status=community",
            )

    def test_research_row_brand_mismatch_join_fails(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(id="byd-atto3-2022-2024-community")
            row = _unknown_row(
                id="tesla-model-3",
                disposition="single-family",
                catalog_presence="present",
                catalog_profile_ids=["byd-atto3-2022-2024-community"],
                firmware_scope="firmware-1",
                market="Global",
                year_from=2022,
                year_to=2024,
            )
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[row],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "research row tesla-model-3: incorrect join with catalog profile byd-atto3-2022-2024-community (brand mismatch tesla != byd)",
            )

    def test_unlisted_brand_mismatch_join_fails(self) -> None:
        """Brands not in any legacy list (e.g. BMW vs Tesla) still fail brand mismatch join."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(
                id="tesla-model3-2023-2026-community",
                make="Tesla",
                model="Model 3",
                source={
                    "artifact_sha256": SHA64_A,
                    "license": "MIT",
                    "locator": "Model 3 polls",
                    "name": "openvehicles/OVMS",
                    "path": "components/vehicle_teslamodel3/src/vehicle_teslamodel3.cpp",
                    "revision": SHA40_A,
                    "url": f"https://github.com/openvehicles/OVMS/tree/{SHA40_A}",
                },
                secondary_sources=[
                    {
                        "artifact_sha256": SHA64_B,
                        "license": "GPL-3.0",
                        "locator": "220005",
                        "name": "meatpiHQ/wican-fw",
                        "path": "vehicle_profiles/tesla/model3.json",
                        "revision": SHA40_B,
                        "url": f"https://github.com/meatpiHQ/wican-fw/tree/{SHA40_B}",
                    }
                ],
            )
            row = _unknown_row(
                id="bmw-i3",
                disposition="single-family",
                catalog_presence="present",
                catalog_profile_ids=["tesla-model3-2023-2026-community"],
                firmware_scope="firmware-1",
                market="Global",
                year_from=2022,
                year_to=2024,
            )
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[row],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "research row bmw-i3: incorrect join with catalog profile tesla-model3-2023-2026-community (brand mismatch bmw != tesla)",
            )

    def test_research_row_same_brand_different_model_join_fails(self) -> None:
        """Same brand with different model (e.g. Nissan Leaf vs Nissan Ariya) fails model check."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(
                id="nissan-ariya-2025-2026-community",
                make="Nissan",
                model="Ariya",
                source={
                    "artifact_sha256": SHA64_A,
                    "license": "MIT",
                    "locator": "Ariya polls",
                    "name": "openvehicles/OVMS",
                    "path": "components/vehicle_nissan_ariya/src/vehicle_nissan_ariya.cpp",
                    "revision": SHA40_A,
                    "url": f"https://github.com/openvehicles/OVMS/tree/{SHA40_A}",
                },
                secondary_sources=[
                    {
                        "artifact_sha256": SHA64_B,
                        "license": "GPL-3.0",
                        "locator": "220005",
                        "name": "meatpiHQ/wican-fw",
                        "path": "vehicle_profiles/nissan/ariya.json",
                        "revision": SHA40_B,
                        "url": f"https://github.com/meatpiHQ/wican-fw/tree/{SHA40_B}",
                    }
                ],
            )
            row = _unknown_row(
                id="nissan-leaf",
                aliases=["Nissan Leaf"],
                disposition="single-family",
                catalog_presence="present",
                catalog_profile_ids=["nissan-ariya-2025-2026-community"],
                firmware_scope="firmware-1",
                market="Global",
                year_from=2022,
                year_to=2024,
            )
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[row],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "research row nissan-leaf: incorrect join with catalog profile nissan-ariya-2025-2026-community (model mismatch nissan-leaf does not match model Ariya)",
            )

    def test_research_row_non_overlapping_years_join_fails(self) -> None:
        """Same model with non-overlapping year ranges fails year overlap check."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(
                id="nissan-leaf-ze1-2018-2026-community",
                make="Nissan",
                model="Leaf",
                year_from=2018,
                year_to=2026,
                source={
                    "artifact_sha256": SHA64_A,
                    "license": "MIT",
                    "locator": "Leaf polls",
                    "name": "openvehicles/OVMS",
                    "path": "components/vehicle_nissanleaf/src/vehicle_nissanleaf.cpp",
                    "revision": SHA40_A,
                    "url": f"https://github.com/openvehicles/OVMS/tree/{SHA40_A}",
                },
                secondary_sources=[
                    {
                        "artifact_sha256": SHA64_B,
                        "license": "GPL-3.0",
                        "locator": "220005",
                        "name": "meatpiHQ/wican-fw",
                        "path": "vehicle_profiles/nissan/leaf.json",
                        "revision": SHA40_B,
                        "url": f"https://github.com/meatpiHQ/wican-fw/tree/{SHA40_B}",
                    }
                ],
            )
            row = _unknown_row(
                id="nissan-leaf-ze0",
                aliases=["Nissan Leaf First Generation"],
                disposition="single-family",
                catalog_presence="present",
                catalog_profile_ids=["nissan-leaf-ze1-2018-2026-community"],
                firmware_scope="firmware-1",
                market="Global",
                year_from=2010,
                year_to=2017,
            )
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[row],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "research row nissan-leaf-ze0: incorrect join with catalog profile nissan-leaf-ze1-2018-2026-community (year range 2010-2017 does not overlap with profile 2018-2026)",
            )

    def test_repo_validation_cross_model_catalog_source_fails(self) -> None:
        """Full repo validation rejects cross-model profile source."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            cat_profile = _valid_community_catalog_profile(
                id="tesla-model-3-community",
                make="Tesla",
                model="Model 3",
            )
            cat_profile["secondary_sources"] = [
                {
                    "artifact_sha256": SHA64_B,
                    "license": "MIT",
                    "locator": "signals",
                    "name": "comm/sig",
                    "path": "signalsets/v3/default.json",
                    "revision": SHA40_B,
                    "url": f"https://github.com/comm/sig/tree/{SHA40_B}",
                }
            ]
            cat_profile["source"]["path"] = "vehicle_profiles/tesla/model_y.json"
            cat_profile["source"]["locator"] = "record 1"
            _write_mini_repo(
                tmp,
                catalog={"profiles": [cat_profile], "schema_version": 3},
                research_rows=[],
            )
            issues = validate_matrix.validate_repo(tmp)
            _only(
                issues,
                "belongs to a different vehicle model than Tesla Model 3",
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
            "example.net/pack.csv",
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
