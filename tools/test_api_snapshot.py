#!/usr/bin/env python3
"""Regression tests for the owner/signature-aware API extractor."""

from __future__ import annotations

import unittest
import tempfile
from pathlib import Path

from update_api_snapshot import extract_declarations, write_reference


FIXTURE = """
unit Fixture;
interface
type
  TFirst = class
  private
    procedure Hidden;
  public
    procedure Open(const Value: Integer); overload;
    procedure Open(const Value: Double); overload;
  end;
  TSecond = record
    Value: Double;
    procedure Open(const Value: Integer);
  end;
  IMatrix = interface
    procedure Legacy;
  end;
const
  PublicLimit = 42;
function Open(const Value: String): Boolean;
implementation
end.
"""


class SnapshotExtractorTests(unittest.TestCase):
    def test_reference_links_sources_from_the_nested_api_directory(self) -> None:
        snapshot = {
            "units": [{
                "unit": "Fixture",
                "source": "src/Fixture.pas",
                "interface_sha256": "fixture",
                "declarations": [],
            }]
        }
        decision = {
            "alias_equivalence_profiles": {
                "compiler-type-identity": {"basis": "fixture"}
            },
            "alias_reviews": [],
        }
        with tempfile.TemporaryDirectory() as temporary:
            reference = Path(temporary) / "reference.md"
            write_reference(snapshot, decision, reference, "2.0.0")
            self.assertIn(
                "[`src/Fixture.pas`](../../../src/Fixture.pas)",
                reference.read_text(encoding="utf-8"),
            )

    def test_owner_overload_visibility_and_exact_identity(self) -> None:
        declarations = extract_declarations("Fixture", FIXTURE.split("implementation")[0])
        open_declarations = [
            item for item in declarations if item["name"].casefold() == "open"
        ]
        self.assertEqual(4, len(open_declarations))
        self.assertEqual(
            {None, "TFirst", "TSecond"},
            {item["owner"] for item in open_declarations},
        )
        first_overloads = [
            item for item in open_declarations if item["owner"] == "TFirst"
        ]
        self.assertEqual(2, len(first_overloads))
        self.assertEqual(2, len({item["signature"] for item in first_overloads}))
        self.assertFalse(any(item["name"] == "Hidden" for item in declarations))
        legacy = next(item for item in declarations if item["name"] == "Legacy")
        self.assertEqual("IMatrix", legacy["owner"])
        self.assertEqual("procedure Legacy", legacy["signature"])
        self.assertNotIn("classification", legacy)
        self.assertTrue(any(item["name"] == "PublicLimit" for item in declarations))


if __name__ == "__main__":
    unittest.main()
