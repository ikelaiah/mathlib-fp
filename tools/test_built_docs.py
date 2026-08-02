#!/usr/bin/env python3
"""Unit tests for generated-documentation link and identity checks."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from check_built_docs import validate_page


class BuiltDocumentationTests(unittest.TestCase):
    def test_checks_release_identity_target_and_anchor(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = root / "target.html"
            target.write_text(
                '<meta name="mathlib-release" content="1.9.1">'
                '<h2 id="answer">Answer</h2>',
                encoding="utf-8",
            )
            page = root / "index.html"
            page.write_text(
                '<meta name="mathlib-release" content="1.9.1">'
                '<a href="target.html#answer">answer</a>',
                encoding="utf-8",
            )
            self.assertEqual([], validate_page(page, root, "1.9.1"))
            page.write_text(
                '<meta name="mathlib-release" content="1.9.0">'
                '<a href="missing.html">missing</a>',
                encoding="utf-8",
            )
            errors = validate_page(page, root, "1.9.1")
            self.assertTrue(any("release metadata" in error for error in errors))
            self.assertTrue(any("missing built link" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
