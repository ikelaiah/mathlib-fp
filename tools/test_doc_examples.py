#!/usr/bin/env python3
"""Unit tests for documentation-fragment discovery and wrapping."""

from __future__ import annotations

import unittest
from pathlib import Path

from check_doc_examples import Fragment, is_runnable, program_source


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


if __name__ == "__main__":
    unittest.main()
