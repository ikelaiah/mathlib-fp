"""Unit tests for release-state checks in the documentation gate."""

from __future__ import annotations

import unittest

from check_docs import roadmap_release_state_errors


class RoadmapReleaseStateTests(unittest.TestCase):
    def test_rejects_current_release_left_as_next(self) -> None:
        roadmap = "## Next release: 1.9.6 — Portability and distribution\n"

        errors = roadmap_release_state_errors(roadmap, "1.9.6", "1.9.7")

        self.assertIn("Roadmap does not record 1.9.6 as the previous release", errors)
        self.assertIn("Roadmap does not name 1.9.7 as the next release", errors)

    def test_accepts_previous_current_and_next_release(self) -> None:
        roadmap = (
            "## Previous release: 1.9.6 — Portability and distribution\n\n"
            "## Next release: 1.9.7 — Migration rehearsal\n"
        )

        self.assertEqual(
            [], roadmap_release_state_errors(roadmap, "1.9.6", "1.9.7")
        )


if __name__ == "__main__":
    unittest.main()
