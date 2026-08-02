#!/usr/bin/env python3
"""Unit tests for release-facing example output contracts."""

from __future__ import annotations

import unittest

from check_example_output import contract_error


class ExampleOutputContractTests(unittest.TestCase):
    def test_requires_ordered_fragments_and_exact_final_line(self) -> None:
        contract = {
            "contains": ["status: converged", "value: 2"],
            "final_line": "workflow: success",
        }
        self.assertIsNone(
            contract_error(
                contract,
                "status: converged\nvalue: 2\nworkflow: success\r\n",
            )
        )
        self.assertIn(
            "missing ordered",
            contract_error(contract, "value: 2\nstatus: converged\nworkflow: success")
            or "",
        )
        self.assertIn(
            "final line",
            contract_error(contract, "status: converged\nvalue: 2\nfailed") or "",
        )


if __name__ == "__main__":
    unittest.main()
