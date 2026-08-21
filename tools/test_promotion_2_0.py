"""Regression tests for the 2.0.0 release-candidate promotion gate."""

from __future__ import annotations

import unittest

from check_promotion_2_0 import candidate_state_errors


class CandidateStateTests(unittest.TestCase):
    def test_accepts_a_candidate_target_with_a_published_predecessor(self) -> None:
        versions = {
            "current": "2.0.0",
            "release_state": "candidate",
            "published_stable": "1.10.0",
            "versions": [
                {"release": "2.0.0", "source_ref": "release/v2.0.0"},
                {"release": "1.10.0", "source_ref": "v1.10.0"},
            ],
        }
        roadmap = (
            "## Previous published stable release: 1.10.0\n\n"
            "## Release candidate target: 2.0.0\n"
        )

        self.assertEqual([], candidate_state_errors("2.0.0", versions, roadmap))

    def test_rejects_promoting_a_candidate_to_published_stable(self) -> None:
        versions = {
            "current": "2.0.0",
            "release_state": "candidate",
            "published_stable": "2.0.0",
            "versions": [{"release": "2.0.0", "source_ref": "release/v2.0.0"}],
        }
        roadmap = "## Release candidate target: 2.0.0\n"

        errors = candidate_state_errors("2.0.0", versions, roadmap)

        self.assertTrue(any("published stable" in error for error in errors))
        self.assertTrue(any("previous published stable" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
