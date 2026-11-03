#!/usr/bin/env python3
"""Tests for the v2.15.0 parallel multiplication evidence contract."""

from __future__ import annotations

import unittest

from check_parallel_multiply import (
    EvidenceError, check_record, derive, expected_workers, parse_line,
)

LINE = ("PARALLEL|scalar=double|shape=64x64x64|requested_workers=4"
        "|effective_workers=2|threading_available=true|cpu_count=4|repeats=2"
        "|serial_ms=10.0|parallel_ms=5.0|bitwise_equal=true"
        "|max_abs_difference_vs_portable=0.0|max_abs_portable_value=10.0"
        "|logical_bytes=1|peak_resident_bytes=100")


class ParallelEvidenceTest(unittest.TestCase):
    def test_expected_workers_matches_pascal_contract(self) -> None:
        self.assertEqual(expected_workers(1000, 1000, 1000, 1, True), 1)
        self.assertEqual(expected_workers(1, 4000, 4000, 8, True), 1)
        self.assertEqual(expected_workers(128, 32, 32, 8, True), 1)
        self.assertEqual(expected_workers(64, 64, 64, 8, True), 2)
        self.assertEqual(expected_workers(3, 400, 400, 8, True), 3)
        self.assertEqual(expected_workers(512, 512, 512, 4, True), 4)
        self.assertEqual(expected_workers(512, 512, 512, 4, False), 1)
        with self.assertRaises(ValueError):
            expected_workers(10, 10, 10, 65, True)

    def test_parses_and_accepts_valid_record(self) -> None:
        record = parse_line("noise\n" + LINE + "\n")
        check_record(record, 64, 64, 64, 4, True)
        record["case"] = "c"
        self.assertEqual(derive([record]), [])
        self.assertEqual(record["speedup"], 2.0)
        self.assertEqual(record["scaling_efficiency"], 1.0)

    def test_rejects_bitwise_mismatch_and_wrong_workers(self) -> None:
        record = parse_line(LINE.replace("bitwise_equal=true",
                                         "bitwise_equal=false"))
        with self.assertRaisesRegex(EvidenceError, "bitwise"):
            check_record(record, 64, 64, 64, 4, True)
        record = parse_line(LINE.replace("effective_workers=2",
                                         "effective_workers=4"))
        with self.assertRaisesRegex(EvidenceError, "effective"):
            check_record(record, 64, 64, 64, 4, True)

    def test_rejects_missing_fallback_and_oracle_drift(self) -> None:
        record = parse_line(LINE)
        with self.assertRaisesRegex(EvidenceError, "threading_available"):
            check_record(record, 64, 64, 64, 4, False)
        record = parse_line(LINE.replace(
            "max_abs_difference_vs_portable=0.0",
            "max_abs_difference_vs_portable=1e-9"))
        with self.assertRaisesRegex(EvidenceError, "portable"):
            check_record(record, 64, 64, 64, 4, True)

    def test_flags_slow_parallel_run_for_review(self) -> None:
        record = parse_line(LINE.replace("parallel_ms=5.0", "parallel_ms=20.0"))
        record["case"] = "c"
        self.assertEqual(len(derive([record])), 1)

    def test_rejects_malformed_output(self) -> None:
        with self.assertRaisesRegex(EvidenceError, "one PARALLEL row"):
            parse_line("")
        with self.assertRaisesRegex(EvidenceError, "missing"):
            parse_line("PARALLEL|scalar=double")


if __name__ == "__main__":
    unittest.main()
