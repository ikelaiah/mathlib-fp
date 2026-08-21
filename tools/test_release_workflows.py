"""Regression checks for release qualification and documentation workflows."""

from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class ReleaseQualificationWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workflow = (ROOT / ".github/workflows/release-qualification.yml").read_text(
            encoding="utf-8"
        )

    def test_resolves_release_version_from_selected_source_ref(self) -> None:
        self.assertIn("source_ref: ${{ steps.source.outputs.ref }}", self.workflow)
        self.assertIn("ref: ${{ steps.source.outputs.ref }}", self.workflow)
        self.assertIn("python3 tools/release_tags.py", self.workflow)
        self.assertIn("ref: ${{ needs.resolve.outputs.source_ref }}", self.workflow)

    def test_keeps_platform_specific_archive_gates(self) -> None:
        linux = self.workflow.split("  windows-clean-archive:", 1)[0]
        windows = self.workflow.split("  windows-clean-archive:", 1)[1]
        self.assertIn("--network-isolated", linux)
        self.assertIn("--source-archive", linux)
        self.assertIn("--source-archive", windows)
        self.assertNotIn("--network-isolated", windows)


class DocumentationWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workflow = (ROOT / ".github/workflows/documentation.yml").read_text(
            encoding="utf-8"
        )

    def test_resolves_version_from_the_documentation_source_ref(self) -> None:
        self.assertIn("INPUT_RELEASE_REF: ${{ inputs.release_ref }}", self.workflow)
        self.assertIn("source_ref=\"$INPUT_RELEASE_REF\"", self.workflow)
        self.assertIn("source_ref=\"$RELEASE_TAG\"", self.workflow)
        self.assertIn("source_ref: ${{ steps.source.outputs.ref }}", self.workflow)
        self.assertIn("ref: ${{ steps.source.outputs.ref }}", self.workflow)
        self.assertIn("release=$(cat current/VERSION)", self.workflow)
        self.assertIn("ref: ${{ needs.resolve.outputs.source_ref }}", self.workflow)

    def test_keeps_release_candidates_off_stable_pages(self) -> None:
        self.assertIn("needs.resolve.outputs.tag_kind != 'rc'", self.workflow)
        self.assertIn(
            "needs.resolve.outputs.tag_kind == 'stable'", self.workflow
        )
        self.assertIn("python3 current/tools/release_tags.py", self.workflow)

    def test_builds_the_published_stable_documentation_path(self) -> None:
        self.assertIn("ref: v1.10.0", self.workflow)
        self.assertIn("path: historical-1.10.0", self.workflow)
        self.assertIn("--source historical-1.10.0/docs", self.workflow)
        self.assertIn("--release 1.10.0 --output site/1.10.0", self.workflow)
        self.assertIn('site/1.10.0/release.json', self.workflow)
        self.assertIn("'1.10.0/index.html'", self.workflow)


if __name__ == "__main__":
    unittest.main()
