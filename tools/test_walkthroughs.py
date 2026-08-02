#!/usr/bin/env python3
"""Unit tests for the 1.9.2 clean-room evidence gate."""

from __future__ import annotations

import unittest

from check_walkthroughs import validation_errors


def record(number: int) -> dict[str, object]:
    return {
        "participant_id": f"participant-{number}",
        "reviewer_id": f"reviewer-{number}",
        "date": "2026-08-03",
        "route": "dense-square-solve",
        "search_query": "solve linear equations",
        "environment": "Windows 11 x86-64, FPC 3.2.2",
        "elapsed_minutes": 4.5,
        "observed_result": "solution 2, 3; residual checked",
        "confusion_or_failure": "none",
        "correct_result": True,
        "read_implementation_units": False,
        "implemented_exercised_feature": False,
        "evidence": f"https://example.invalid/walkthrough/{number}",
    }


class WalkthroughValidationTests(unittest.TestCase):
    def test_requires_three_real_independent_records(self) -> None:
        pending = {
            "schema_version": 1,
            "release": "1.9.2",
            "walkthroughs": [],
        }
        self.assertTrue(any("at least 3" in item for item in validation_errors(pending)))

        complete = {
            "schema_version": 1,
            "release": "1.9.2",
            "walkthroughs": [record(1), record(2), record(3)],
        }
        self.assertEqual([], validation_errors(complete))

    def test_rejects_implementer_source_read_and_duplicate_evidence(self) -> None:
        records = [record(1), record(2), record(3)]
        records[1]["read_implementation_units"] = True
        records[1]["implemented_exercised_feature"] = True
        records[2]["evidence"] = records[0]["evidence"]
        errors = validation_errors(
            {
                "schema_version": 1,
                "release": "1.9.2",
                "walkthroughs": records,
            }
        )
        self.assertTrue(any("read_implementation_units" in item for item in errors))
        self.assertTrue(any("implemented_exercised_feature" in item for item in errors))
        self.assertTrue(any("evidence link must be distinct" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
