#!/usr/bin/env python3
"""Unit tests for release-qualification output validation."""

from __future__ import annotations

import unittest

from qualify_release import output_tail, verify_heaptrc_output


class HeaptrcValidationTests(unittest.TestCase):
    def test_accepts_zero_blocks_with_platform_spacing(self) -> None:
        verify_heaptrc_output(
            "Heap dump by heaptrc unit\n"
            "  0   unfreed memory blocks   :   0  \n"
        )

    def test_rejects_nonzero_blocks_with_diagnostics(self) -> None:
        with self.assertRaisesRegex(
            RuntimeError, r"2 unfreed blocks \(48 bytes\)"
        ):
            verify_heaptrc_output(
                "Heap dump by heaptrc unit\n"
                "2 unfreed memory blocks : 48\n"
                "Call trace for block 1\n"
            )

    def test_rejects_missing_summary_and_preserves_output(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "heap tracing disabled"):
            verify_heaptrc_output("heap tracing disabled")

    def test_output_tail_is_bounded(self) -> None:
        self.assertEqual("short", output_tail("short", limit=10))
        self.assertTrue(output_tail("x" * 20, limit=10).endswith("x" * 10))


if __name__ == "__main__":
    unittest.main()
