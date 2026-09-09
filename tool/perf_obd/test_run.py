#!/usr/bin/env python3
"""Gate tests for tool/perf_obd/run.py. Do not invoke Flutter."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from run import (
    GateError,
    main,
    prepare_output,
    validate_competitor_report,
    validate_physical_adapter_report,
    validate_report,
    validate_six_report,
    validate_twenty_report,
    validate_ui_profile_report,
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

    def test_a_software_report_is_not_a_ui_profile(self):
        with self.assertRaises(GateError):
            validate_ui_profile_report(_ok())

    def test_ui_profile_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_ui_profile_report({"lane": "ui-profile", "device": ""})

    def test_ui_profile_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--ui-profile", "--output", str(output)]), 2)
            self.assertFalse((output / "ui-profile.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_ui_profile_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "ui-profile.json"
            stale.write_text('{"lane":"ui-profile","device":"planted"}', encoding="utf-8")
            self.assertEqual(main(["--ui-profile", "--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_runner_names_the_ui_profile_lane(self):
        text = Path(__file__).with_name("run.py").read_text(encoding="utf-8")
        self.assertIn("--ui-profile", text)
        self.assertIn("validate_ui_profile_report", text)

    def test_a_software_report_is_not_a_competitor_lane(self):
        with self.assertRaises(GateError):
            validate_competitor_report(_ok())

    def test_competitor_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_competitor_report({"lane": "competitor", "device": ""})

    def test_competitor_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--competitor", "--output", str(output)]), 2)
            self.assertFalse((output / "competitor.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_competitor_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "competitor.json"
            stale.write_text(
                '{"lane":"competitor","device":"planted"}', encoding="utf-8"
            )
            self.assertEqual(main(["--competitor", "--output", str(output)]), 2)
            self.assertFalse(stale.exists())

    def test_a_software_report_is_not_a_physical_adapter_lane(self):
        with self.assertRaises(GateError):
            validate_physical_adapter_report(_ok())

    def test_physical_adapter_without_a_device_is_not_pass(self):
        with self.assertRaises(GateError):
            validate_physical_adapter_report(
                {"lane": "physical-adapter", "device": ""}
            )

    def test_physical_adapter_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(
                main(["--physical-adapter", "--output", str(output)]), 2
            )
            self.assertFalse((output / "physical-adapter.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_physical_adapter_deletes_a_stale_report(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "physical-adapter.json"
            stale.write_text(
                '{"lane":"physical-adapter","device":"planted"}', encoding="utf-8"
            )
            self.assertEqual(
                main(["--physical-adapter", "--output", str(output)]), 2
            )
            self.assertFalse(stale.exists())

    def test_runner_names_the_competitor_and_physical_adapter_lanes(self):
        text = Path(__file__).with_name("run.py").read_text(encoding="utf-8")
        self.assertIn("--competitor", text)
        self.assertIn("validate_competitor_report", text)
        self.assertIn("--physical-adapter", text)
        self.assertIn("validate_physical_adapter_report", text)

    def test_combined_lane_flags_are_rejected_and_clean_each_requested_report(
        self,
    ):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            planted = {
                "competitor.json": '{"lane":"competitor","device":"planted"}',
                "physical-adapter.json": (
                    '{"lane":"physical-adapter","device":"planted"}'
                ),
                "ui-profile.json": '{"lane":"ui-profile","device":"planted"}',
            }
            for name, body in planted.items():
                (output / name).write_text(body, encoding="utf-8")
            self.assertEqual(
                main(
                    [
                        "--competitor",
                        "--physical-adapter",
                        "--output",
                        str(output),
                    ]
                ),
                2,
            )
            self.assertFalse((output / "competitor.json").exists())
            self.assertFalse((output / "physical-adapter.json").exists())
            self.assertTrue(
                (output / "ui-profile.json").exists(),
                msg="a lane that was not requested must not be swept as a side effect",
            )

    def test_sleep_walk_lane_is_not_run(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            self.assertEqual(main(["--sleep-walk", "--output", str(output)]), 2)
            self.assertFalse((output / "sleep-walk.json").exists())
            self.assertFalse((output / "software.json").exists())

    def test_sleep_walk_deletes_a_dangling_symlink(self):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            stale = output / "sleep-walk.json"
            stale.symlink_to(output / "missing-target.json")
            self.assertEqual(main(["--sleep-walk", "--output", str(output)]), 2)
            self.assertFalse(stale.exists())
            self.assertFalse(stale.is_symlink())

    def test_runner_names_the_sleep_walk_lane(self):
        text = Path(__file__).with_name("run.py").read_text(encoding="utf-8")
        self.assertIn("--sleep-walk", text)

    def test_combined_sleep_walk_and_competitor_clean_each_requested_report(
        self,
    ):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            (output / "sleep-walk.json").write_text(
                '{"lane":"sleep-walk","device":"planted"}', encoding="utf-8"
            )
            (output / "competitor.json").write_text(
                '{"lane":"competitor","device":"planted"}', encoding="utf-8"
            )
            self.assertEqual(
                main(
                    [
                        "--sleep-walk",
                        "--competitor",
                        "--output",
                        str(output),
                    ]
                ),
                2,
            )
            self.assertFalse((output / "sleep-walk.json").exists())
            self.assertFalse((output / "competitor.json").exists())

    def test_combined_sleep_walk_and_software_deletes_the_software_report(
        self,
    ):
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw)
            (output / "software.json").write_text(
                '{"lane":"software","device":"planted"}', encoding="utf-8"
            )
            (output / "sleep-walk.json").write_text(
                '{"lane":"sleep-walk","device":"planted"}', encoding="utf-8"
            )
            self.assertEqual(
                main(
                    [
                        "--sleep-walk",
                        "--software",
                        "--output",
                        str(output),
                    ]
                ),
                2,
            )
            self.assertFalse((output / "software.json").exists())
            self.assertFalse((output / "sleep-walk.json").exists())


if __name__ == "__main__":
    unittest.main()
