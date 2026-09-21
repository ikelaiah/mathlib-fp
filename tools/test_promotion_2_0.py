"""Regression tests for the 2.0.0 stable-release promotion gate."""

from __future__ import annotations

import unittest

from check_promotion_2_0 import stable_state_errors


class StableStateTests(unittest.TestCase):
    def test_accepts_a_published_stable_target(self) -> None:
        versions = {
            "current": "2.0.0",
            "release_state": "stable",
            "published_stable": "2.0.0",
            "versions": [
                {"release": "2.0.0", "source_ref": "v2.0.0"},
                {"release": "1.10.0", "source_ref": "v1.10.0"},
            ],
        }
        roadmap = (
            "## Previous release: 2.0.0\n\n"
            "## Next release: 2.1\n"
        )

        self.assertEqual([], stable_state_errors("2.0.0", versions, roadmap))

    def test_rejects_candidate_metadata_after_publication(self) -> None:
        versions = {
            "current": "2.0.0",
            "release_state": "candidate",
            "published_stable": "1.10.0",
            "versions": [{"release": "2.0.0", "source_ref": "release/v2.0.0"}],
        }
        roadmap = "## Release candidate target: 2.0.0\n"

        errors = stable_state_errors("2.0.0", versions, roadmap)

        self.assertTrue(any("release_state" in error for error in errors))
        self.assertTrue(any("published stable" in error for error in errors))
        self.assertTrue(any("previous release" in error for error in errors))
        self.assertTrue(any("next release" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
