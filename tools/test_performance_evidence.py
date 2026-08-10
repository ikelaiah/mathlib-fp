#!/usr/bin/env python3
"""Tests for the 1.9.5 performance-evidence contract."""

from __future__ import annotations

import unittest

from check_performance_evidence import (
    EvidenceError,
    parse_perf_output,
    validate_evidence,
)


def row(
    identifier: str,
    domain: str,
    scale: str,
    *,
    cold_ms: int = 10,
    warm_ms: int = 20,
    warm_iterations: int = 4,
    allocations: int = 0,
    retained_bytes: int = 0,
    working_elements: int = 16,
    dense_shape_elements: int = 0,
    checksum: float = 2.0,
) -> str:
    return (
        f"PERF|id={identifier}|domain={domain}|scale={scale}|scalar=double"
        f"|shape=4x4|cold_ms={cold_ms}|warm_ms={warm_ms}"
        f"|warm_iterations={warm_iterations}|allocations={allocations}"
        f"|retained_bytes={retained_bytes}|working_elements={working_elements}"
        f"|dense_shape_elements={dense_shape_elements}|checksum={checksum}"
        "|tolerance=1e-12|setup=prepared_inputs"
    )


def contract(
    identifier: str,
    domain: str,
    scale: str,
    *,
    checksum: float = 2.0,
    allocations_max: int = 0,
    retained_bytes_max: int = 0,
    working_elements_max: int = 16,
    dense_shape_elements_max: int = 0,
    comparison: dict[str, object] | None = None,
) -> dict[str, object]:
    result: dict[str, object] = {
        "id": identifier,
        "domain": domain,
        "scale": scale,
        "scalar": "double",
        "shape": "4x4",
        "setup": "prepared_inputs",
        "claim_id": f"claim-{identifier}",
        "timing_semantics": "first call and warmed repeated calls",
        "allocation_semantics": "logical result allocations",
        "retained_semantics": "sampled live heap delta after warm calls",
        "complexity_tripwire": {
            "metric": "working_elements",
            "policy": "exact_ceiling",
        },
        "checksum": {"value": checksum, "absolute_tolerance": 1e-12},
        "hard_limits": {
            "allocations_max": allocations_max,
            "retained_bytes_max": retained_bytes_max,
            "working_elements_max": working_elements_max,
            "dense_shape_elements_max": dense_shape_elements_max,
        },
    }
    if comparison is not None:
        result["same_run_comparison"] = comparison
    return result


class PerformanceEvidenceTests(unittest.TestCase):
    def test_parses_canonical_rows_and_ignores_human_output(self) -> None:
        parsed = parse_perf_output(
            "mathlib-fp performance evidence\n"
            + row("dense-small", "dense", "small")
            + "\n"
        )
        self.assertEqual("dense-small", parsed[0]["id"])
        self.assertEqual(10, parsed[0]["cold_ms"])
        self.assertEqual(2.0, parsed[0]["checksum"])

    def test_rejects_duplicate_row_keys(self) -> None:
        malformed = row("dense-small", "dense", "small") + "|cold_ms=11"
        with self.assertRaisesRegex(EvidenceError, "duplicate key cold_ms"):
            parse_perf_output(malformed)

    def test_requires_complete_domain_and_scale_coverage(self) -> None:
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {
                "dense": ["small", "large"],
                "dsp": ["small", "large"],
            },
            "benchmarks": [contract("dense-small", "dense", "small")],
        }
        rows = parse_perf_output(row("dense-small", "dense", "small"))
        with self.assertRaisesRegex(EvidenceError, "missing manifest coverage"):
            validate_evidence(manifest, rows, "test-host")

    def test_rejects_missing_runtime_rows(self) -> None:
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {"dense": ["small"]},
            "benchmarks": [contract("dense-small", "dense", "small")],
        }
        with self.assertRaisesRegex(EvidenceError, "missing benchmark rows"):
            validate_evidence(manifest, [], "test-host")

    def test_exact_allocation_and_dense_shape_limits_are_hard_gates(self) -> None:
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {"sparse": ["large"]},
            "benchmarks": [contract("sparse-large", "sparse", "large")],
        }
        rows = parse_perf_output(
            row(
                "sparse-large",
                "sparse",
                "large",
                allocations=1,
                dense_shape_elements=16,
            )
        )
        with self.assertRaisesRegex(EvidenceError, "allocations=1 exceeds 0"):
            validate_evidence(manifest, rows, "test-host")

    def test_checksum_failure_is_a_hard_gate(self) -> None:
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {"dense": ["small"]},
            "benchmarks": [contract("dense-small", "dense", "small")],
        }
        rows = parse_perf_output(
            row("dense-small", "dense", "small", checksum=2.5)
        )
        with self.assertRaisesRegex(EvidenceError, "checksum"):
            validate_evidence(manifest, rows, "test-host")

    def test_timing_movement_requests_review_instead_of_failing(self) -> None:
        comparison = {
            "baseline_id": "dense-baseline",
            "metric": "warm_ms_per_iteration",
            "review_ratio": 1.5,
            "enforcement": "advisory",
        }
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {"dense": ["small", "large"]},
            "benchmarks": [
                contract("dense-baseline", "dense", "small"),
                contract(
                    "dense-candidate",
                    "dense",
                    "large",
                    comparison=comparison,
                ),
            ],
        }
        rows = parse_perf_output(
            row(
                "dense-baseline",
                "dense",
                "small",
                warm_ms=10,
                warm_iterations=10,
            )
            + "\n"
            + row(
                "dense-candidate",
                "dense",
                "large",
                warm_ms=40,
                warm_iterations=10,
            )
        )
        result = validate_evidence(manifest, rows, "test-host")
        self.assertEqual("review", result["status"])
        self.assertEqual("review", result["comparisons"][0]["status"])

    def test_matching_prior_host_baseline_is_advisory(self) -> None:
        manifest = {
            "schema_version": 1,
            "release": "1.9.5",
            "required_coverage": {"statistics": ["large"]},
            "benchmarks": [
                {
                    **contract("stats-large", "statistics", "large"),
                    "prior_baselines": [
                        {
                            "release": "1.9.4",
                            "host_key": "test-host",
                            "warm_ms_per_iteration": 2.0,
                            "review_ratio": 1.5,
                        }
                    ],
                }
            ],
        }
        rows = parse_perf_output(
            row(
                "stats-large",
                "statistics",
                "large",
                warm_ms=40,
                warm_iterations=10,
            )
        )
        result = validate_evidence(manifest, rows, "test-host")
        self.assertEqual("review", result["status"])
        self.assertEqual("prior_release", result["comparisons"][0]["kind"])


if __name__ == "__main__":
    unittest.main()
