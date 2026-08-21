"""Unit tests for release-tag classification."""

from __future__ import annotations

import unittest

from release_tags import classify_release_tag


class ReleaseTagClassificationTests(unittest.TestCase):
    def test_accepts_exact_stable_tag(self) -> None:
        self.assertEqual("stable", classify_release_tag("v2.0.0", "2.0.0"))

    def test_accepts_numbered_release_candidates(self) -> None:
        self.assertEqual("rc", classify_release_tag("v2.0.0-rc.1", "2.0.0"))
        self.assertEqual("rc", classify_release_tag("v2.0.0-rc.12", "2.0.0"))

    def test_rejects_malformed_release_candidates(self) -> None:
        for tag in ("v2.0.0-rc", "v2.0.0-rc.0", "v2.0.0-rc.x"):
            with self.subTest(tag=tag):
                self.assertIsNone(classify_release_tag(tag, "2.0.0"))

    def test_rejects_unrelated_versions(self) -> None:
        for tag in ("v1.10.1", "v2.1.0", "v2.0.1", "v2.0.1-rc.1"):
            with self.subTest(tag=tag):
                self.assertIsNone(classify_release_tag(tag, "2.0.0"))

    def test_rejects_unrelated_prerelease_forms(self) -> None:
        for tag in ("v2.0.0-beta.1", "v2.0.0-alpha.1", "v2.0.0-preview.1"):
            with self.subTest(tag=tag):
                self.assertIsNone(classify_release_tag(tag, "2.0.0"))


if __name__ == "__main__":
    unittest.main()
