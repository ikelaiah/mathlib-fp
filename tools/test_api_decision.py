#!/usr/bin/env python3
"""Regression tests for exact API-decision selector semantics."""

from __future__ import annotations

import unittest
from pathlib import Path

from api_decision import (
    apply_decisions,
    generic_surfaces,
    matching_alias_reviews,
    plain_alias_target,
    selector_matches,
)
from check_api_decision import canonical_example_document
from docs_layout import load_layout


ROOT = Path(__file__).resolve().parent.parent


class ApiDecisionTests(unittest.TestCase):
    def test_example_document_canonicalizes_a_legacy_flat_path(self) -> None:
        layout = load_layout(ROOT / "docs/layout.json", ROOT / "docs", "1.10.0")
        self.assertEqual(
            Path("docs/guides/domains/math-base.md"),
            canonical_example_document(Path("docs/MathBase.md"), layout),
        )

    def test_surface_selector_covers_type_and_owned_members(self) -> None:
        selector = {"unit": "Example.Unit", "surface": "TFacade"}
        facade = {"owner": None, "name": "TFacade", "kind": "class", "signature": "TFacade=class"}
        method = {"owner": "TFacade", "name": "Run", "kind": "function", "signature": "function Run:Double"}
        unrelated = {"owner": "TOther", "name": "Run", "kind": "function", "signature": "function Run:Double"}
        self.assertTrue(selector_matches("Example.Unit", facade, selector))
        self.assertTrue(selector_matches("Example.Unit", method, selector))
        self.assertFalse(selector_matches("Example.Unit", unrelated, selector))

    def test_signature_selector_distinguishes_overloads(self) -> None:
        selector = {
            "unit": "Example.Unit",
            "name": "Solve",
            "owner": None,
            "signature_contains": "IDoubleMatrix",
        }
        double = {"owner": None, "name": "Solve", "kind": "function", "signature": "function Solve(const A:IDoubleMatrix):IDoubleMatrix"}
        single = {"owner": None, "name": "Solve", "kind": "function", "signature": "function Solve(const A:ISingleMatrix):ISingleMatrix"}
        self.assertTrue(selector_matches("Example.Unit", double, selector))
        self.assertFalse(selector_matches("Example.Unit", single, selector))

    def test_generic_surface_and_compatibility_decisions_take_precedence(self) -> None:
        declarations = [
            {"owner": None, "name": "TGeneric", "kind": "class", "signature": "generic TGeneric<T>=class"},
            {"owner": "TGeneric", "name": "Run", "kind": "procedure", "signature": "procedure Run"},
            {"owner": None, "name": "TLegacy", "kind": "class", "signature": "TLegacy=class"},
        ]
        decision = {
            "common_paths": [
                {"selectors": [{"unit": "Example.Unit", "surface": "TGeneric"}]}
            ],
            "compatibility_decisions": [
                {
                    "selector": {"unit": "Example.Unit", "surface": "TLegacy"},
                    "decision": "retain",
                    "note": "legacy",
                }
            ],
            "experimental_selectors": [],
        }
        self.assertEqual({"TGeneric"}, generic_surfaces(declarations))
        apply_decisions("Example.Unit", declarations, decision)
        self.assertEqual("implementation", declarations[0]["classification"])
        self.assertEqual("implementation", declarations[1]["classification"])
        self.assertEqual("compatibility", declarations[2]["classification"])
        self.assertEqual("retain", declarations[2]["compatibility_decision"])

    def test_plain_alias_detection_excludes_composite_declarations(self) -> None:
        alias = {
            "kind": "type",
            "signature": "TPressureKit=TFluidDynamicsKit",
        }
        qualified = {
            "kind": "type",
            "signature": "EPressureError=EngineeringLib.Common.EFluidDynamicsError",
        }
        composite = {"kind": "type", "signature": "TFacade=class"}
        interface = {"kind": "type", "signature": "IMatrix=interface"}
        self.assertEqual("TFluidDynamicsKit", plain_alias_target(alias))
        self.assertEqual(
            "EngineeringLib.Common.EFluidDynamicsError",
            plain_alias_target(qualified),
        )
        self.assertIsNone(plain_alias_target(composite))
        self.assertIsNone(plain_alias_target(interface))

    def test_alias_review_selector_is_owner_and_unit_exact(self) -> None:
        decision = {
            "alias_reviews": [
                {
                    "id": "pressure-kit",
                    "selector": {
                        "unit": "EngineeringLib.Pressure",
                        "name": "TPressureKit",
                        "owner": None,
                        "kind": "type",
                    },
                }
            ]
        }
        alias = {
            "owner": None,
            "name": "TPressureKit",
            "kind": "type",
            "signature": "TPressureKit=TFluidDynamicsKit",
        }
        self.assertEqual(
            ["pressure-kit"],
            [
                item["id"]
                for item in matching_alias_reviews(
                    "EngineeringLib.Pressure", alias, decision
                )
            ],
        )
        self.assertEqual(
            [], matching_alias_reviews("EngineeringLib.Velocity", alias, decision)
        )


if __name__ == "__main__":
    unittest.main()
