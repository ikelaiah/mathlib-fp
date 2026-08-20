#!/usr/bin/env python3
"""Unit tests for generated-documentation link and identity checks."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from check_built_docs import check_redirects, check_search_index, validate_page


class BuiltDocumentationTests(unittest.TestCase):
    def test_redirect_checks_target_and_search_exclusion(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "start").mkdir()
            (root / "start" / "beginner-guide.html").write_text(
                "canonical", encoding="utf-8"
            )
            (root / "BEGINNER_GUIDE.html").write_text(
                '<a href="start/beginner-guide.html">Moved</a>', encoding="utf-8"
            )
            (root / "search-index.json").write_text(
                '[{"url":"start/beginner-guide.html"}]', encoding="utf-8"
            )
            self.assertEqual([], check_redirects(root, {
                "BEGINNER_GUIDE.md": "start/beginner-guide.md",
            }))
    def test_checks_release_identity_target_and_anchor(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = root / "target.html"
            target.write_text(
                '<meta name="mathlib-release" content="1.9.3">'
                '<h2 id="answer">Answer</h2>',
                encoding="utf-8",
            )
            page = root / "index.html"
            page.write_text(
                '<meta name="mathlib-release" content="1.9.3">'
                '<a href="target.html#answer">answer</a>',
                encoding="utf-8",
            )
            self.assertEqual([], validate_page(page, root, "1.9.3"))
            page.write_text(
                '<meta name="mathlib-release" content="1.9.0">'
                '<a href="missing.html">missing</a>',
                encoding="utf-8",
            )
            errors = validate_page(page, root, "1.9.3")
            self.assertTrue(any("release metadata" in error for error in errors))
            self.assertTrue(any("missing built link" in error for error in errors))

    def test_search_checks_problem_words_without_identifiers(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "recipes.html").write_text("recipes", encoding="utf-8")
            (root / "search-index.json").write_text(
                '[{"title":"Recipes","url":"recipes.html",'
                '"text":"Choose a dense least squares method"}]',
                encoding="utf-8",
            )
            self.assertEqual([], check_search_index(root, ("least squares",)))
            errors = check_search_index(root, ("normal probability",))
            self.assertTrue(any("normal probability" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
