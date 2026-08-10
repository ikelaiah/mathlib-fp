#!/usr/bin/env python3
"""Unit tests for release identity, version navigation, and offline docs."""

from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_docs import (
    heading_outline,
    load_versions,
    markdown_to_html,
    outline_navigation,
    render_document_page,
    write_offline_archive,
    write_site_index,
)


class DocumentationBuildTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.manifest = self.root / "versions.json"
        self.manifest.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "current": "1.9.3",
                    "site_url": "https://docs.example.invalid/mathlib-fp",
                    "repository_url": "https://github.example.invalid/mathlib-fp",
                    "versions": [
                        {"release": "1.9.3", "source_ref": "v1.9.3"},
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
        (site / "1.9.3").mkdir(parents=True)
        (site / "1.9.3" / "index.html").write_text("current", encoding="utf-8")
        (site / "1.9.2").mkdir()
        (site / "1.9.2" / "index.html").write_text("old", encoding="utf-8")
        (site / "1.9.1").mkdir()
        (site / "1.9.1" / "index.html").write_text("old", encoding="utf-8")
        (site / "1.9.0").mkdir()
        (site / "1.9.0" / "index.html").write_text("old", encoding="utf-8")
        write_site_index(site, versions)
        page = (site / "index.html").read_text(encoding="utf-8")
        self.assertIn("Current release: 1.9.3", page)
        self.assertIn('href="1.9.0/index.html"', page)
        self.assertIn('class="release-list"', page)

    def test_offline_archive_is_deterministic_and_self_identifying(self) -> None:
        site = self.root / "site"
        site.mkdir()
        (site / "index.html").write_text("release 1.9.3", encoding="utf-8")
        (site / "release.json").write_text(
            '{"release":"1.9.3"}\n', encoding="utf-8"
        )
        first = self.root / "first.zip"
        second = self.root / "second.zip"
        first_digest = write_offline_archive(site, first, "1.9.3")
        second_digest = write_offline_archive(site, second, "1.9.3")
        self.assertEqual(first_digest, second_digest)
        self.assertEqual(hashlib.sha256(first.read_bytes()).hexdigest(), first_digest)
        with zipfile.ZipFile(first) as archive:
            self.assertIn(
                "mathlib-fp-docs-1.9.3/release.json", archive.namelist()
            )

    def test_markdown_table_renders_as_a_semantic_html_table(self) -> None:
        source = (
            "| Unit family | Domain |\n"
            "| --- | --- |\n"
            "| [MathBase](MathBase.md) | Shared numerics |\n"
        )

        body, plain = markdown_to_html(source)

        self.assertIn("<table>", body)
        self.assertIn("<thead>", body)
        self.assertIn('<th scope="col">Unit family</th>', body)
        self.assertIn('<a href="MathBase.html">MathBase</a>', body)
        self.assertIn("<td>Shared numerics</td>", body)
        self.assertNotIn("table-source", body)
        self.assertIn("Shared numerics", plain)

    def test_wrapped_markdown_list_item_stays_inside_list_item(self) -> None:
        source = (
            "- Release notes — stable-family\n"
            "  numerical evidence and offline validation.\n"
            "- Qualification report — release gate.\n"
        )

        body, plain = markdown_to_html(source)

        self.assertIn(
            "<li>Release notes — stable-family numerical evidence and offline "
            "validation.</li>",
            body,
        )
        self.assertNotIn("<p>numerical evidence", body)
        self.assertIn("Release notes — stable-family numerical evidence", plain)

    def test_heading_outline_ignores_title_and_code_fences(self) -> None:
        source = (
            "# Guide\n\n"
            "## Start here\n\n"
            "### Choose an API\n\n"
            "```text\n"
            "## Not a section\n"
            "```\n"
        )

        self.assertEqual(
            heading_outline(source),
            [
                (2, "Start here", "start-here"),
                (3, "Choose an API", "choose-an-api"),
            ],
        )

    def test_outline_navigation_is_accessible_and_links_sections(self) -> None:
        navigation = outline_navigation(
            "# Guide\n\n## Start here\n\n### Choose an API\n"
        )

        self.assertIn('aria-label="On this page"', navigation)
        self.assertIn('href="#start-here"', navigation)
        self.assertIn('class="toc-level-3"', navigation)

    def test_document_page_has_accessible_responsive_shell(self) -> None:
        page = render_document_page(
            title="Guide",
            release="1.9.4",
            root_prefix="",
            navigation='<nav aria-label="Documentation versions">Versions</nav>',
            outline='<nav class="toc" aria-label="On this page">Outline</nav>',
            body='<h1 id="guide">Guide</h1>',
        )

        self.assertIn('class="skip-link" href="#content"', page)
        self.assertIn('<aside class="doc-sidebar">', page)
        self.assertIn('<main id="content"', page)
        self.assertIn('id="search" type="search"', page)
        self.assertIn('id="theme-toggle" type="button"', page)
        self.assertIn('aria-live="polite"', page)
        self.assertIn('<details class="mobile-toc">', page)


if __name__ == "__main__":
    unittest.main()
