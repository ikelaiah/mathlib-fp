#!/usr/bin/env python3
"""Regression tests for the 1.9.8 representative-workflow contract."""

from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from workflow_qualification import (
    WorkflowContractError,
    load_manifest,
    parse_line_float,
    validate_manifest,
    validate_workflow_output,
)


def complete_manifest() -> dict[str, object]:
    return {
        "schema_version": 1,
        "release": "1.9.8",
        "guide": "docs/WORKFLOW_QUALIFICATION_1.9.8.md",
        "workflows": [
            {
                "id": "sensor-pipeline",
                "source": "examples/24_sensor_pipeline.pas",
                "success_marker": "sensor pipeline: success",
                "description": "sensor workflow",
                "domains": ["MathBase", "EngineeringLib", "StatsLib", "TimeSeriesLib"],
                "fixtures": ["examples/data/sensor_readings.csv"],
                "max_fixture_bytes": 65536,
                "diagnostics": ["diagnostic: rejected 1 non-finite reading"],
                "numerical_expectations": [
                    {
                        "name": "raw-mean",
                        "line_prefix": "raw mean:",
                        "minimum": 19.5,
                        "maximum": 20.5,
                    }
                ],
                "exports": ["workflow-exports/sensor_report.txt"],
            },
            {
                "id": "numerical-modelling-optimisation",
                "source": "examples/25_numerical_modelling_optimisation.pas",
                "success_marker": "modelling workflow: success",
                "description": "modelling workflow",
                "domains": ["MathBase", "NumericsLib", "OptimizationLib"],
                "fixtures": [],
                "max_fixture_bytes": 65536,
                "diagnostics": ["diagnostic: invalid fit rejected by EModellingError"],
                "numerical_expectations": [
                    {
                        "name": "fit-slope",
                        "line_prefix": "fit slope:",
                        "minimum": 1.9,
                        "maximum": 2.1,
                    }
                ],
                "exports": ["workflow-exports/model_report.txt"],
            },
            {
                "id": "probability-finance",
                "source": "examples/26_probability_finance.pas",
                "success_marker": "probability finance workflow: success",
                "description": "finance workflow",
                "domains": ["MathBase", "ProbabilityLib", "StatsLib", "FinanceLib"],
                "fixtures": [],
                "max_fixture_bytes": 65536,
                "diagnostics": ["diagnostic: invalid sigma rejected by EProbabilityError"],
                "numerical_expectations": [
                    {
                        "name": "npv",
                        "line_prefix": "net present value:",
                        "minimum": 5000.0,
                        "maximum": 15000.0,
                    }
                ],
                "exports": ["workflow-exports/finance_report.txt"],
            },
        ],
    }


class WorkflowManifestContractTests(unittest.TestCase):
    def test_accepts_complete_manifest(self) -> None:
        validate_manifest(complete_manifest())

    def test_rejects_fewer_than_three_workflows(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"] = manifest["workflows"][:2]
        with self.assertRaisesRegex(WorkflowContractError, "three workflows"):
            validate_manifest(manifest)

    def test_rejects_single_domain_workflow(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][1]["domains"] = ["NumericsLib"]
        with self.assertRaisesRegex(WorkflowContractError, "at least two domains"):
            validate_manifest(manifest)

    def test_rejects_duplicate_workflow_id(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][1]["id"] = manifest["workflows"][0]["id"]
        with self.assertRaisesRegex(WorkflowContractError, "duplicate workflow id"):
            validate_manifest(manifest)

    def test_rejects_source_outside_examples(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["source"] = "src/Unit.pas"
        with self.assertRaisesRegex(WorkflowContractError, "examples"):
            validate_manifest(manifest)

    def test_rejects_absolute_fixture_path(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["fixtures"] = ["/tmp/readings.csv"]
        with self.assertRaisesRegex(WorkflowContractError, "absolute"):
            validate_manifest(manifest)

    def test_rejects_parent_traversal_fixture_path(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["fixtures"] = ["../readings.csv"]
        with self.assertRaisesRegex(WorkflowContractError, "unsafe"):
            validate_manifest(manifest)

    def test_rejects_inverted_numerical_bounds(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["numerical_expectations"][0]["minimum"] = 30.0
        manifest["workflows"][0]["numerical_expectations"][0]["maximum"] = 20.0
        with self.assertRaisesRegex(WorkflowContractError, "minimum exceeds maximum"):
            validate_manifest(manifest)

    def test_rejects_missing_diagnostic_path(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["diagnostics"] = []
        with self.assertRaisesRegex(WorkflowContractError, "diagnostics"):
            validate_manifest(manifest)

    def test_rejects_non_integer_max_fixture_bytes(self) -> None:
        manifest = complete_manifest()
        manifest["workflows"][0]["max_fixture_bytes"] = "65536"
        with self.assertRaisesRegex(WorkflowContractError, "max_fixture_bytes"):
            validate_manifest(manifest)


class WorkflowManifestLoadTests(unittest.TestCase):
    def test_load_manifest_rejects_missing_fixture(self) -> None:
        manifest = complete_manifest()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "examples").mkdir()
            (root / "docs").mkdir()
            (root / "docs" / "WORKFLOW_QUALIFICATION_1.9.8.md").write_text(
                "guide", encoding="utf-8"
            )
            (root / "examples" / "24_sensor_pipeline.pas").write_text(
                "program p; begin end.", encoding="utf-8"
            )
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(WorkflowContractError, "missing workflow fixture"):
                load_manifest(path, root)

    def test_load_manifest_rejects_oversized_fixture(self) -> None:
        manifest = complete_manifest()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "examples" / "data").mkdir(parents=True)
            (root / "docs").mkdir()
            (root / "docs" / "WORKFLOW_QUALIFICATION_1.9.8.md").write_text(
                "guide", encoding="utf-8"
            )
            (root / "examples" / "24_sensor_pipeline.pas").write_text(
                "program p; begin end.", encoding="utf-8"
            )
            (root / "examples" / "data" / "sensor_readings.csv").write_text(
                "1.0\n" * 1000, encoding="utf-8"
            )
            manifest["workflows"][0]["max_fixture_bytes"] = 16
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(WorkflowContractError, "max_fixture_bytes"):
                load_manifest(path, root)

    def test_load_manifest_rejects_path_outside_repository(self) -> None:
        manifest = complete_manifest()
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            root = parent / "repository"
            root.mkdir()
            (root / "docs").mkdir()
            (root / "docs" / "WORKFLOW_QUALIFICATION_1.9.8.md").write_text(
                "guide", encoding="utf-8"
            )
            outside = parent / "outside.pas"
            outside.write_text("program p; begin end.", encoding="utf-8")
            manifest["workflows"][0]["source"] = "examples/../../outside.pas"
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(WorkflowContractError, "outside repository"):
                load_manifest(path, root)


class WorkflowOutputContractTests(unittest.TestCase):
    def test_parse_line_float_extracts_first_number(self) -> None:
        self.assertEqual(3.000000, parse_line_float("fit slope: 3.000000", "fit slope:"))
        self.assertEqual(-1.0, parse_line_float("optimizer x1: -1.000000", "optimizer x1:"))
        self.assertIsNone(parse_line_float("other line", "fit slope:"))
        self.assertIsNone(parse_line_float("fit slope: not-a-number", "fit slope:"))

    def test_validate_workflow_output_accepts_valid_run(self) -> None:
        output = (
            "fit slope: 2.000000\n"
            "diagnostic: invalid fit rejected by EModellingError\n"
            "modelling workflow: success\n"
        )
        errors = validate_workflow_output(
            "numerical-modelling-optimisation",
            output,
            complete_manifest()["workflows"][1],
        )
        self.assertEqual([], errors)

    def test_validate_workflow_output_reports_missing_marker_and_bounds(self) -> None:
        output = "fit slope: 9.000000\n"
        errors = validate_workflow_output(
            "numerical-modelling-optimisation",
            output,
            complete_manifest()["workflows"][1],
        )
        self.assertTrue(any("success marker" in e for e in errors))
        self.assertTrue(any("outside" in e for e in errors))
        self.assertTrue(any("diagnostic" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
