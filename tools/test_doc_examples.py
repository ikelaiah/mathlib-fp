#!/usr/bin/env python3
"""Unit tests for documentation-fragment discovery and wrapping."""

from __future__ import annotations

import unittest
from pathlib import Path

from check_doc_examples import (
    Fragment,
    OutputExpectation,
    expectation_error,
    is_runnable,
    missing_beginner_routes,
    output_expectation,
    program_source,
)


class DocumentationFragmentTests(unittest.TestCase):
    def test_wraps_self_contained_body_and_rejects_opaque_fragment(self) -> None:
        runnable = Fragment(
            Path("docs/Guide.md"),
            10,
            "uses SysUtils;\nvar X: Integer;\nbegin\n  X := 1;\nend.\n",
        )
        opaque = Fragment(Path("docs/Guide.md"), 20, "X := X + 1;\n")
        self.assertTrue(is_runnable(runnable))
        self.assertFalse(is_runnable(opaque))
        wrapped = program_source(runnable, 7)
        self.assertIn("program doc_fragment_007;", wrapped)
        self.assertIn("uses SysUtils;", wrapped)

    def test_discovers_and_checks_exact_and_ordered_output(self) -> None:
        document = (
            "```pascal\nuses SysUtils;\nbegin\n  WriteLn('ok');\nend.\n```\n\n"
            "Expected output contains:\n\n```text\nstatus: converged\nsuccess\n```\n"
        )
        offset = document.index("```\n\n") + len("```")
        expectation = output_expectation(document, offset, Path("docs/Guide.md"))
        self.assertIsNotNone(expectation)
        assert expectation is not None
        self.assertEqual("contains", expectation.mode)
        self.assertIsNone(
            expectation_error(
                expectation, "heading\nstatus: converged\nvalue=2\nsuccess\n"
            )
        )
        self.assertIn(
            "not found",
            expectation_error(expectation, "status: converged\nfailed\n") or "",
        )
        exact = OutputExpectation("exact", 1, "answer=2\n")
        self.assertIsNone(expectation_error(exact, "answer=2\r\n"))

    def test_beginner_routes_require_runnable_checked_output(self) -> None:
        missing = missing_beginner_routes([])
        self.assertTrue(any(item.startswith("MathBase:") for item in missing))


if __name__ == "__main__":
    unittest.main()
