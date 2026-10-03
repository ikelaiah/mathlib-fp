#!/usr/bin/env python3
"""Keep every retained release in the documentation publishing matrix."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = ROOT / ".github" / "workflows" / "documentation.yml"
VERSIONS = ROOT / "docs" / "versions.json"


def historical_checkouts(workflow: str) -> dict[str, str]:
    pairs = re.findall(
        r"(?m)^\s+ref:\s*([^\s]+)\s*\n\s+path:\s*historical-([0-9.]+)\s*$",
        workflow,
    )
    return {release: source_ref for source_ref, release in pairs}


def historical_builds(workflow: str) -> set[str]:
    flattened = re.sub(r"\\\r?\n\s*", " ", workflow)
    return set(
        re.findall(
            r"--source historical-([0-9.]+)/docs\s+"
            r"--versions current/docs/versions\.json\s+"
            r"--release ([0-9.]+)\s+--output site/([0-9.]+)",
            flattened,
        )
    )


class DocumentationWorkflowTests(unittest.TestCase):
    def test_every_archived_release_has_a_checkout_and_site_build(self) -> None:
        manifest = json.loads(VERSIONS.read_text(encoding="utf-8"))
        workflow = WORKFLOW.read_text(encoding="utf-8")
        archived = {
            item["release"]: item["source_ref"]
            for item in manifest["versions"]
            if item["release"] != manifest["current"]
        }
        checkouts = historical_checkouts(workflow)
        builds = historical_builds(workflow)

        self.assertEqual(archived, checkouts)
        expected_builds = {(release, release, release) for release in archived}
        self.assertEqual(expected_builds, builds)


if __name__ == "__main__":
    unittest.main()
