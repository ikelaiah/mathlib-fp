#!/usr/bin/env python3
"""Tests for the current documentation layout manifest."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from docs_layout import LayoutError, load_layout


class DocumentationLayoutTests(unittest.TestCase):
    def write_layout(self, root: Path, data: object) -> Path:
        path = root / "layout.json"
        path.write_text(json.dumps(data), encoding="utf-8")
        return path

    def test_current_release_records_and_aliases_are_resolved(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "start").mkdir()
            (root / "start" / "beginner-guide.md").write_text(
                "# Beginner\n", encoding="utf-8"
            )
            layout = self.write_layout(root, {
                "schema_version": 1,
                "current_release": "1.10.0",
                "artifacts": {
                    "release_notes": "releases/1.10.0/release-notes.md",
                    "qualification": "releases/1.10.0/qualification.md",
                },
                "aliases": {
                    "BEGINNER_GUIDE.md": "start/beginner-guide.md",
                },
            })
            manifest = load_layout(layout, root)
            self.assertEqual(
                root / "releases/1.10.0/release-notes.md",
                manifest.artifact("release_notes"),
            )
            self.assertEqual(
                "start/beginner-guide.md", manifest.aliases["BEGINNER_GUIDE.md"],
            )

    def test_legacy_layout_uses_root_release_notes_without_a_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "RELEASE_NOTES_1.9.9.md").write_text("# Notes\n", encoding="utf-8")
            manifest = load_layout(root / "layout.json", root, "1.9.9")
            self.assertTrue(manifest.legacy)
            self.assertEqual(
                root / "RELEASE_NOTES_1.9.9.md", manifest.release_notes(),
            )

    def test_rejects_duplicate_missing_escaping_and_cyclic_aliases(self) -> None:
        cases = (
            {"aliases": {"a.md": "missing.md"}},
            {"aliases": {"../a.md": "start/a.md"}},
            {"aliases": {"a.md": "b.md", "b.md": "a.md"}},
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "start").mkdir()
            (root / "start" / "a.md").write_text("# A\n", encoding="utf-8")
            for case in cases:
                with self.subTest(case=case):
                    data = {
                        "schema_version": 1,
                        "current_release": "1.10.0",
                        "artifacts": {"release_notes": "start/a.md"},
                        **case,
                    }
                    with self.assertRaises(LayoutError):
                        load_layout(self.write_layout(root, data), root)


if __name__ == "__main__":
    unittest.main()
