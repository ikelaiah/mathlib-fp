"""Unit tests for release-state checks in the documentation gate."""

from __future__ import annotations

import unittest

from check_docs import roadmap_release_state_errors


class RoadmapReleaseStateTests(unittest.TestCase):
    def test_rejects_current_release_left_as_next(self) -> None:
        roadmap = "## Next release: 1.9.4 — Numerical trust closure\n"

        errors = roadmap_release_state_errors(roadmap, "1.9.4", "1.9.5")

        self.assertIn("Roadmap does not record 1.9.4 as the previous release", errors)
        self.assertIn("Roadmap does not name 1.9.5 as the next release", errors)

    def test_accepts_previous_current_and_next_release(self) -> None:
        roadmap = (
            "## Previous release: 1.9.4 — Numerical trust closure\n\n"
            "## Next release: 1.9.5 — Predictable performance\n"
        )

        self.assertEqual(
            [], roadmap_release_state_errors(roadmap, "1.9.4", "1.9.5")
        )


if __name__ == "__main__":
    unittest.main()
