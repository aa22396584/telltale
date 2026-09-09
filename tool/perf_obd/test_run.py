#!/usr/bin/env python3
"""Gate tests for tool/perf_obd/run.py. Do not invoke Flutter."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from run import (
    GateError,
    prepare_output,
    validate_report,
    validate_six_report,
    validate_twenty_report,
)


def _ok(**overrides):
    report = {
        "lane": "software",
        "transport": "FakeElm327",
        "engine": "PollingEngine",
        "quantile": "nearest-rank",
        "minimumObservations": 20,
        "observations": 20,
        "channels": 3,
        "scheduledModeAndPid": ["010C", "010D", "015E"],
        "firstObservationMs": 40,
        "interarrivalMs": {"n": 19, "p50": 50, "p95": 80, "p99": 90},
        "errors": 0,
    }
    report.update(overrides)
    return report


def _ok_six(**overrides):
    report = {
        "lane": "software",
        "transport": "FakeElm327",
        "engine": "PollingEngine",
        "quantile": "nearest-rank",
        "minimumObservations": 8,
        "observations": 8,
        "channels": 6,
        "scheduledModeAndPid": ["010C", "010D", "015E", "0105", "0104", "0111"],
        "perChannel": {
            "010C": 8,
            "010D": 8,
            "015E": 8,
            "0105": 8,
            "0104": 8,
            "0111": 8,
        },
        "firstObservationMs": 40,
        "interarrivalMs": {"n": 7, "p50": 50, "p95": 80, "p99": 90},
        "errors": 0,
    }
    report.update(overrides)
    return report


def _ok_twenty(**overrides):
    report = {
        "lane": "software",
        "transport": "FakeElm327",
        "engine": "PollingEngine",
        "quantile": "nearest-rank",
        "minimumObservations": 8,
        "observations": 8,
        "channels": 20,
        "scheduledModeAndPid": [
            "010C",
            "010D",
            "015E",
            "0105",
            "0104",
            "0111",
            "010F",
            "010B",
            "0110",
            "010E",
            "010A",
            "012F",
            "0133",
            "0142",
            "0146",
            "015C",
            "0106",
            "0107",
            "011F",
            "012C",
        ],
        "perChannel": {
            "010C": 8,
            "010D": 8,
            "015E": 8,
            "0105": 8,
            "0104": 8,
            "0111": 8,
            "010F": 8,
            "010B": 8,
            "0110": 8,
            "010E": 8,
            "010A": 8,
            "012F": 8,
            "0133": 8,
            "0142": 8,
            "0146": 8,
            "015C": 8,
            "0106": 8,
            "0107": 8,
            "011F": 8,
            "012C": 8,
        },
        "firstObservationMs": 40,
        "interarrivalMs": {"n": 7, "p50": 50, "p95": 80, "p99": 90},
        "errors": 0,
    }
    report.update(overrides)
    return report


class ValidateReportTest(unittest.TestCase):
    def test_a_complete_software_report_passes(self):
        self.assertEqual(validate_report(_ok())["observations"], 20)

    def test_zero_observations_fail(self):
        with self.assertRaises(GateError):
            validate_report(_ok(observations=0))

    def test_truncated_observations_fail(self):
        with self.assertRaises(GateError):
            validate_report(_ok(observations=3))

    def test_a_self_reported_minimum_cannot_lower_the_floor(self):
        with self.assertRaises(GateError):
            validate_report(_ok(observations=1, minimumObservations=1))

    def test_missing_interarrival_quantiles_fail(self):
        with self.assertRaises(GateError):
            validate_report(_ok(interarrivalMs={"n": 19}))

    def test_negative_interarrival_quantiles_fail(self):
        with self.assertRaises(GateError):
            validate_report(
                _ok(interarrivalMs={"n": 19, "p50": -1, "p95": 80, "p99": 90})
            )

    def test_decreasing_interarrival_quantiles_fail(self):
        with self.assertRaises(GateError):
            validate_report(
                _ok(interarrivalMs={"n": 19, "p50": 90, "p95": 80, "p99": 70})
            )

    def test_a_python_calculation_is_not_the_engine(self):
        with self.assertRaises(GateError):
            validate_report(_ok(engine="python-arithmetic"))

    def test_missing_quantile_method_fails(self):
        with self.assertRaises(GateError):
            validate_report(_ok(quantile="unspecified"))

    def test_a_one_channel_label_fails(self):
        with self.assertRaises(GateError):
            validate_report(_ok(channels=1, scheduledModeAndPid=["010C"]))

    def test_a_three_channel_report_is_not_the_six_channel_matrix(self):
        with self.assertRaises(GateError):
            validate_six_report(_ok())

    def test_a_complete_six_channel_report_passes(self):
        self.assertEqual(validate_six_report(_ok_six())["channels"], 6)

    def test_a_short_six_channel_pid_fails(self):
        with self.assertRaises(GateError):
            validate_six_report(
                _ok_six(perChannel={"010C": 8, "010D": 1, "015E": 8, "0105": 8, "0104": 8, "0111": 8})
            )

    def test_runner_invokes_the_six_channel_matrix(self):
        text = Path(__file__).with_name("run.py").read_text(encoding="utf-8")
        self.assertIn("software_six_channel_measure_test.dart", text)
        self.assertIn("software-six.json", text)
        self.assertIn("validate_six_report", text)

    def test_a_six_channel_report_is_not_the_twenty_channel_matrix(self):
        with self.assertRaises(GateError):
            validate_twenty_report(_ok_six())

    def test_a_complete_twenty_channel_report_passes(self):
        self.assertEqual(validate_twenty_report(_ok_twenty())["channels"], 20)

    def test_a_short_twenty_channel_pid_fails(self):
        per = dict(_ok_twenty()["perChannel"])
        per["012C"] = 1
        with self.assertRaises(GateError):
            validate_twenty_report(_ok_twenty(perChannel=per))

    def test_runner_invokes_the_twenty_channel_matrix(self):
        text = Path(__file__).with_name("run.py").read_text(encoding="utf-8")
        self.assertIn("software_twenty_channel_measure_test.dart", text)
        self.assertIn("software-twenty.json", text)
        self.assertIn("validate_twenty_report", text)

    def test_prepare_output_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "software.json"
            six = output / "software-six.json"
            twenty = output / "software-twenty.json"
            stale.write_text("{}", encoding="utf-8")
            six.write_text("{}", encoding="utf-8")
            twenty.write_text("{}", encoding="utf-8")
            report_path = prepare_output(output)
            self.assertEqual(report_path, stale)
            self.assertFalse(stale.exists())
            self.assertFalse(six.exists())
            self.assertFalse(twenty.exists())


if __name__ == "__main__":
    unittest.main()
