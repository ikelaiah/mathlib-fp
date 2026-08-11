#!/usr/bin/env python3
"""Unit tests for release-qualification output validation."""

from __future__ import annotations

import hashlib
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import MagicMock, patch

from qualify_release import (
    output_tail,
    verify_clean_source_archive,
    verify_heaptrc_output,
    verify_network_isolated,
    verify_offline_documentation_archive,
)


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


class ArchiveValidationTests(unittest.TestCase):
    def make_source_archive(self, root: Path, *, dirty: bool = False) -> tuple[Path, Path, Path]:
        source = root / "source"
        for directory in ("src", "docs", "examples", "tests", "tools", "packages/lazarus"):
            (source / directory).mkdir(parents=True, exist_ok=True)
            (source / directory / "fixture.txt").write_text(
                directory, encoding="utf-8"
            )
        for filename in ("README.md", "LICENSE.md", "RELEASING.md"):
            (source / filename).write_text(filename, encoding="utf-8")
        (source / "src" / "Unit.pas").write_text("unit Unit;", encoding="utf-8")
        (source / "packages" / "lazarus" / "mathlib_fp.lpk").write_text(
            "<CONFIG/>", encoding="utf-8"
        )
        if dirty:
            (source / ".git").mkdir()
        archive = root / "mathlib-fp-1.9.6.zip"
        with zipfile.ZipFile(archive, "w") as bundle:
            for path in sorted(source.rglob("*")):
                if path.is_file():
                    bundle.write(path, path.relative_to(source).as_posix())
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        checksum = archive.with_name(archive.name + ".sha256")
        checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
        return source, archive, checksum

    def test_accepts_matching_clean_source_archive(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source, archive, checksum = self.make_source_archive(Path(directory))

            evidence = verify_clean_source_archive(source, archive, checksum)

            self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), evidence["sha256"])
            self.assertGreater(evidence["files"], 3)

    def test_rejects_checksum_mismatch_and_repository_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source, archive, checksum = self.make_source_archive(Path(directory))
            checksum.write_text("0" * 64 + f"  {archive.name}\n", encoding="ascii")
            with self.assertRaisesRegex(RuntimeError, "checksum mismatch"):
                verify_clean_source_archive(source, archive, checksum)

        with tempfile.TemporaryDirectory() as directory:
            source, archive, checksum = self.make_source_archive(Path(directory), dirty=True)
            with self.assertRaisesRegex(RuntimeError, "repository-local .git"):
                verify_clean_source_archive(source, archive, checksum)

    def test_rejects_compiler_output_in_source_archive(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source, _, _ = self.make_source_archive(Path(directory))
            (source / "src" / "Unit.ppu").write_bytes(b"compiled")
            archive = Path(directory) / "dirty.zip"
            with zipfile.ZipFile(archive, "w") as bundle:
                for path in sorted(source.rglob("*")):
                    if path.is_file():
                        bundle.write(path, path.relative_to(source).as_posix())
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            checksum = archive.with_name(archive.name + ".sha256")
            checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")

            with self.assertRaisesRegex(RuntimeError, "compiler output"):
                verify_clean_source_archive(source, archive, checksum)

    def test_extracts_checked_offline_documentation_archive(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "mathlib-fp-docs-1.9.6.zip"
            prefix = "mathlib-fp-docs-1.9.6/"
            with zipfile.ZipFile(archive, "w") as bundle:
                bundle.writestr(prefix + "index.html", "index")
                bundle.writestr(prefix + "release.json", "{}")
                bundle.writestr(prefix + "search-index.json", "[]")
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            checksum = archive.with_name(archive.name + ".sha256")
            checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")

            extracted = verify_offline_documentation_archive(
                archive, checksum, root / "extracted", "1.9.6"
            )

            self.assertTrue((extracted / "index.html").is_file())


class NetworkIsolationTests(unittest.TestCase):
    @patch("qualify_release.socket.create_connection", side_effect=OSError("blocked"))
    def test_accepts_blocked_outbound_connection(
        self, create_connection: MagicMock
    ) -> None:
        verify_network_isolated()
        create_connection.assert_called_once()

    @patch("qualify_release.socket.create_connection")
    def test_rejects_reachable_outbound_connection(
        self, create_connection: MagicMock
    ) -> None:
        connection = MagicMock()
        create_connection.return_value = connection

        with self.assertRaisesRegex(RuntimeError, "outbound network is reachable"):
            verify_network_isolated()

        connection.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
