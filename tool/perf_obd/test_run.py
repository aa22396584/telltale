#!/usr/bin/env python3
"""Gate tests for tool/perf_obd/run.py. Do not invoke Flutter."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from run import GateError, prepare_output, validate_report


def _ok(**overrides):
    report = {
        "lane": "software",
        "transport": "FakeElm327",
        "engine": "PollingEngine",
        "quantile": "nearest-rank",
        "minimumObservations": 20,
        "observations": 20,
        "channels": 1,
        "firstObservationMs": 40,
        "interarrivalMs": {"n": 19, "p50": 50, "p95": 80, "p99": 90},
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

    def test_a_python_calculation_is_not_the_engine(self):
        with self.assertRaises(GateError):
            validate_report(_ok(engine="python-arithmetic"))

    def test_missing_quantile_method_fails(self):
        with self.assertRaises(GateError):
            validate_report(_ok(quantile="unspecified"))

    def test_prepare_output_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "software.json"
            stale.write_text("{}", encoding="utf-8")
            report_path = prepare_output(output)
            self.assertEqual(report_path, stale)
            self.assertFalse(stale.exists())


if __name__ == "__main__":
    unittest.main()
