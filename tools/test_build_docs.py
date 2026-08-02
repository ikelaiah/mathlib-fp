#!/usr/bin/env python3
"""Unit tests for release identity, version navigation, and offline docs."""

from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_docs import load_versions, write_offline_archive, write_site_index


class DocumentationBuildTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.manifest = self.root / "versions.json"
        self.manifest.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "current": "1.9.2",
                    "site_url": "https://docs.example.invalid/mathlib-fp",
                    "repository_url": "https://github.example.invalid/mathlib-fp",
                    "versions": [
                        {"release": "1.9.2", "source_ref": "v1.9.2"},
                        {"release": "1.9.1", "source_ref": "v1.9.1"},
                        {"release": "1.9.0", "source_ref": "v1.9.0"},
                    ],
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_landing_page_identifies_current_and_links_older_release(self) -> None:
        versions = load_versions(self.manifest)
        site = self.root / "site"
        (site / "1.9.2").mkdir(parents=True)
        (site / "1.9.2" / "index.html").write_text("current", encoding="utf-8")
        (site / "1.9.1").mkdir()
        (site / "1.9.1" / "index.html").write_text("old", encoding="utf-8")
        (site / "1.9.0").mkdir()
        (site / "1.9.0" / "index.html").write_text("old", encoding="utf-8")
        write_site_index(site, versions)
        page = (site / "index.html").read_text(encoding="utf-8")
        self.assertIn("Current release: 1.9.2", page)
        self.assertIn('href="1.9.0/index.html"', page)

    def test_offline_archive_is_deterministic_and_self_identifying(self) -> None:
        site = self.root / "site"
        site.mkdir()
        (site / "index.html").write_text("release 1.9.2", encoding="utf-8")
        (site / "release.json").write_text(
            '{"release":"1.9.2"}\n', encoding="utf-8"
        )
        first = self.root / "first.zip"
        second = self.root / "second.zip"
        first_digest = write_offline_archive(site, first, "1.9.2")
        second_digest = write_offline_archive(site, second, "1.9.2")
        self.assertEqual(first_digest, second_digest)
        self.assertEqual(hashlib.sha256(first.read_bytes()).hexdigest(), first_digest)
        with zipfile.ZipFile(first) as archive:
            self.assertIn(
                "mathlib-fp-docs-1.9.2/release.json", archive.namelist()
            )


if __name__ == "__main__":
    unittest.main()
