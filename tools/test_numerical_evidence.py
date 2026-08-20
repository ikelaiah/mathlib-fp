#!/usr/bin/env python3
"""Tests for the 1.9.4 numerical-evidence catalogue contract."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from check_numerical_evidence import catalogue_paths, validate_catalogue
from docs_layout import load_layout


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class NumericalEvidenceCatalogueTests(unittest.TestCase):
    def test_catalogue_paths_follow_the_layout_manifest(self) -> None:
        layout = load_layout(
            REPOSITORY_ROOT / "docs/layout.json", REPOSITORY_ROOT / "docs", "1.10.0"
        )
        self.assertEqual(
            REPOSITORY_ROOT / "docs/releases/1.9.4/numerical-evidence.json",
            catalogue_paths(layout)[0],
        )
        self.assertEqual(
            REPOSITORY_ROOT / "docs/reference/capabilities.json",
            catalogue_paths(layout)[1],
        )

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "docs").mkdir()
        (self.root / "src").mkdir()
        (self.root / "tests").mkdir()
        (self.root / "src" / "Example.pas").write_text(
            "unit Example;\n", encoding="utf-8"
        )
        (self.root / "tests" / "TestEvidence.pas").write_text(
            "unit TestEvidence;\n// published reference budget\n", encoding="utf-8"
        )
        (self.root / "docs" / "Evidence.md").write_text(
            "# Evidence\n", encoding="utf-8"
        )
        self.inventory_path = self.root / "docs" / "capabilities.json"
        self.catalogue_path = self.root / "docs" / "numerical-evidence-1.9.4.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_inventory(self, families: list[dict[str, object]]) -> None:
        self.inventory_path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "release": "1.9.4",
                    "capabilities": families,
                }
            ),
            encoding="utf-8",
        )

    def evidence(self, family: str, risk: str = "standard") -> dict[str, object]:
        result: dict[str, object] = {
            "family": family,
            "status": "qualified",
            "risk": risk,
            "input_domain": "finite double inputs in the documented range",
            "budget": {
                "kind": "absolute_error",
                "metric": "absolute error",
                "limit": 2.0e-13,
                "unit": "output units",
            },
            "reference": {
                "method": "closed-form reference",
                "source": "elementary identity",
                "precision": "IEEE-754 binary64",
                "parameters": "documented fixed fixture",
                "license": "mathematical fact; no data licence required",
                "regeneration": "evaluate the stated closed-form identity",
            },
            "tests": [
                {
                    "path": "tests/TestEvidence.pas",
                    "assertions": ["published reference budget"],
                    "kind": "reference comparison",
                }
            ],
            "edge_cases": ["non-finite input is rejected"],
            "documentation": "docs/Evidence.md",
        }
        if risk == "high":
            result["fault_injections"] = [
                {
                    "source": "src/Example.pas",
                    "needle": "Result := Good;",
                    "replacement": "Result := Bad;",
                    "test": "tests/TestEvidence.pas",
                }
            ]
        return result

    def write_catalogue(self, records: list[dict[str, object]]) -> None:
        self.catalogue_path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "release": "1.9.4",
                    "inventory": "docs/reference/capabilities.json",
                    "inventory_release": "1.9.4",
                    "families": records,
                }
            ),
            encoding="utf-8",
        )

    def test_missing_stable_family_is_rejected(self) -> None:
        self.write_inventory(
            [
                {"family": "scalar", "maturity": "stable"},
                {"family": "dense", "maturity": "stable"},
                {"family": "future", "maturity": "unsupported"},
            ]
        )
        self.write_catalogue([self.evidence("scalar")])

        errors = validate_catalogue(self.root, self.catalogue_path, self.inventory_path)

        self.assertIn("missing evidence record for stable family 'dense'", errors)
        self.assertFalse(any("future" in error for error in errors))

    def test_incomplete_provenance_budget_and_paths_are_rejected(self) -> None:
        self.write_inventory([{"family": "scalar", "maturity": "stable"}])
        record = self.evidence("scalar")
        record["budget"] = {"metric": "absolute error", "limit": 0, "unit": ""}
        record["reference"] = {"method": "", "source": ""}
        record["tests"] = [{"path": "tests/Missing.pas", "assertions": [], "kind": ""}]
        record["edge_cases"] = []
        record["documentation"] = "docs/Missing.md"
        self.write_catalogue([record])

        errors = validate_catalogue(self.root, self.catalogue_path, self.inventory_path)

        self.assertTrue(any("budget.limit" in error for error in errors))
        self.assertTrue(any("reference.precision" in error for error in errors))
        self.assertTrue(any("tests/Missing.pas" in error for error in errors))
        self.assertTrue(any("edge_cases" in error for error in errors))
        self.assertTrue(any("docs/Missing.md" in error for error in errors))

    def test_high_risk_family_requires_a_reproducible_fault_injection(self) -> None:
        self.write_inventory([{"family": "solver", "maturity": "stable"}])
        self.write_catalogue([self.evidence("solver", risk="high")])
        catalogue = json.loads(self.catalogue_path.read_text(encoding="utf-8"))
        del catalogue["families"][0]["fault_injections"]
        self.catalogue_path.write_text(json.dumps(catalogue), encoding="utf-8")

        errors = validate_catalogue(self.root, self.catalogue_path, self.inventory_path)

        self.assertIn("solver: high-risk family has no fault_injections", errors)

    def test_test_evidence_must_name_an_assertion_in_the_test_source(self) -> None:
        self.write_inventory([{"family": "scalar", "maturity": "stable"}])
        record = self.evidence("scalar")
        record["tests"][0]["assertions"] = ["missing assertion label"]
        self.write_catalogue([record])

        errors = validate_catalogue(self.root, self.catalogue_path, self.inventory_path)

        self.assertIn(
            "scalar.tests[0].assertions[0]: text is absent from tests/TestEvidence.pas",
            errors,
        )

    def test_exact_budget_requires_and_accepts_a_zero_limit(self) -> None:
        self.write_inventory([{"family": "state", "maturity": "stable"}])
        record = self.evidence("state")
        record["budget"] = {
            "kind": "exact",
            "metric": "exact state replay",
            "limit": 0,
            "unit": "identical state words",
        }
        self.write_catalogue([record])

        self.assertEqual(
            [], validate_catalogue(self.root, self.catalogue_path, self.inventory_path)
        )

    def test_catalogue_records_the_release_of_its_source_inventory(self) -> None:
        self.write_inventory([{"family": "scalar", "maturity": "stable"}])
        self.write_catalogue([self.evidence("scalar")])
        catalogue = json.loads(self.catalogue_path.read_text(encoding="utf-8"))
        catalogue["inventory_release"] = "1.9.3"
        self.catalogue_path.write_text(json.dumps(catalogue), encoding="utf-8")

        errors = validate_catalogue(self.root, self.catalogue_path, self.inventory_path)

        self.assertIn(
            "catalogue.inventory_release: expected the inventory release 1.9.4",
            errors,
        )

    def test_complete_catalogue_is_accepted(self) -> None:
        self.write_inventory(
            [
                {"family": "scalar", "maturity": "stable"},
                {"family": "solver", "maturity": "stable"},
                {"family": "future", "maturity": "unsupported"},
            ]
        )
        self.write_catalogue(
            [self.evidence("scalar"), self.evidence("solver", risk="high")]
        )

        self.assertEqual(
            [], validate_catalogue(self.root, self.catalogue_path, self.inventory_path)
        )


if __name__ == "__main__":
    unittest.main()
