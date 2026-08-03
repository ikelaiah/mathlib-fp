#!/usr/bin/env python3
"""Regression tests for exact API-decision selector semantics."""

from __future__ import annotations

import unittest

from api_decision import (
    apply_decisions,
    generic_surfaces,
    selector_matches,
)


class ApiDecisionTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
