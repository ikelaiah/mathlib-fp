#!/usr/bin/env python3
"""Unit tests for the 1.9.9 convergence-gate validation helpers."""

from __future__ import annotations

import unittest

from convergence import (
    EXPECTED_ROTATE_SIGNATURE,
    capability_inventory_errors,
    deferral_errors,
    deprecation_errors,
    manifest_structure_errors,
    provenance_errors,
    roadmap_convergence_errors,
    rotation_errors,
    snapshot_final_errors,
)


def minimal_manifest() -> dict:
    return {
        "schema_version": 1,
        "closed_by_release": "1.9.9",
        "target_release": "1.10.0",
        "status": "closed",
        "unresolved_api_questions": [],
        "declarations": [],
        "deferrals": [],
    }


def rotation_declaration() -> dict:
    return {
        "id": "vector2d-rotation",
        "kind": "addition",
        "unit": "GeometryLib.Geometry",
        "owner": "TVector2D",
        "name": "Rotate",
        "signature": EXPECTED_ROTATE_SIGNATURE,
        "status": "accepted-for-1.10.0",
        "behavior_contract": [
            "Angle is measured in radians.",
            "Positive angles rotate counter-clockwise about the origin.",
            "The source vector is not modified.",
            "The operation is allocation-free and O(1).",
            "Rotate(Pi / 2) is consistent with TVector2D.Perpendicular.",
            "The returned magnitude preserves the source magnitude.",
            "Rotating the zero vector returns the zero vector exactly.",
            "Non-finite input behavior follows the TVector2D contract.",
        ],
        "test_plan": ["orientation fixtures"],
        "documentation_plan": ["document the signature"],
        "compatibility_impact": ["pure additive method"],
    }


class ManifestStructureTests(unittest.TestCase):
    def test_accepts_closed_manifest(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [rotation_declaration()]

        self.assertEqual([], manifest_structure_errors(manifest))

    def test_rejects_open_manifest(self) -> None:
        manifest = minimal_manifest()
        manifest["status"] = "open"
        manifest["declarations"] = [rotation_declaration()]
        errors = manifest_structure_errors(manifest)

        self.assertIn("capability manifest: status must be closed", errors)

    def test_rejects_unresolved_questions(self) -> None:
        manifest = minimal_manifest()
        manifest["unresolved_api_questions"] = ["3-D rotation naming"]
        manifest["declarations"] = [rotation_declaration()]

        errors = manifest_structure_errors(manifest)

        self.assertTrue(
            any("unresolved" in error for error in errors)
        )


class RotationDeclarationTests(unittest.TestCase):
    def test_accepts_complete_rotation_declaration(self) -> None:
        self.assertEqual([], rotation_errors(rotation_declaration()))

    def test_rejects_changed_signature(self) -> None:
        declaration = rotation_declaration()
        declaration["signature"] = (
            "function Rotate(const Angle: Single): TVector2D"
        )

        errors = rotation_errors(declaration)

        self.assertTrue(any("signature" in error for error in errors))

    def test_rejects_contract_without_orientation(self) -> None:
        declaration = rotation_declaration()
        declaration["behavior_contract"] = [
            "Angle is measured in radians.",
            "The source vector is not modified.",
            "The operation is allocation-free and O(1).",
            "Rotate(Pi / 2) is consistent with TVector2D.Perpendicular.",
            "The returned magnitude preserves the source magnitude.",
            "Rotating the zero vector returns the zero vector exactly.",
            "Non-finite input behavior follows the TVector2D contract.",
        ]

        errors = rotation_errors(declaration)

        self.assertTrue(any("counter-clockwise" in error for error in errors))

    def test_rejects_empty_compatibility_impact(self) -> None:
        declaration = rotation_declaration()
        declaration["compatibility_impact"] = []

        errors = rotation_errors(declaration)

        self.assertTrue(
            any("compatibility_impact" in error for error in errors)
        )


class DeprecationDecisionTests(unittest.TestCase):
    def test_accepts_no_deprecation_decision(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [
            rotation_declaration(),
            {
                "id": "deprecation-marking",
                "kind": "deprecation",
                "decision": "no-deprecation",
                "status": "accepted-for-1.10.0",
                "behavior_contract": [
                    "1.10.0 marks no declaration as deprecated.",
                    "TPressureKit, EPressureError, TVelocityKit, and EVelocityError remain retained.",
                    "All 21 plain compiler aliases remain retained.",
                    "Full source compatibility is retained.",
                ],
                "test_plan": ["re-run the rehearsal consumers"],
                "documentation_plan": ["publish the decision list"],
                "compatibility_impact": ["none at compile time"],
            },
        ]
        decision = {
            "alias_reviews": [{"decision": "retain"} for _ in range(21)],
            "unresolved_decisions": [],
        }

        self.assertEqual([], deprecation_errors(manifest, decision))

    def test_rejects_deprecating_decision(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [
            rotation_declaration(),
            {
                "id": "deprecation-marking",
                "kind": "deprecation",
                "decision": "mark-pressure-velocity",
                "status": "accepted-for-1.10.0",
                "behavior_contract": ["TPressureKit is deprecated."],
                "test_plan": ["warnings expected"],
                "documentation_plan": ["document the warnings"],
                "compatibility_impact": ["compiler warnings"],
            },
        ]
        decision = {
            "alias_reviews": [{"decision": "retain"} for _ in range(21)],
            "unresolved_decisions": [],
        }

        errors = deprecation_errors(manifest, decision)

        self.assertTrue(any("no-deprecation" in error for error in errors))

    def test_rejects_incomplete_alias_review_count(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [
            rotation_declaration(),
            {
                "id": "deprecation-marking",
                "kind": "deprecation",
                "decision": "no-deprecation",
                "status": "accepted-for-1.10.0",
                "behavior_contract": [
                    "TPressureKit, EPressureError, TVelocityKit, and EVelocityError remain retained.",
                    "All 21 plain compiler aliases remain retained.",
                ],
                "test_plan": ["re-run the rehearsal consumers"],
                "documentation_plan": ["publish the decision list"],
                "compatibility_impact": ["none at compile time"],
            },
        ]
        decision = {
            "alias_reviews": [{"decision": "retain"}],
            "unresolved_decisions": [],
        }

        errors = deprecation_errors(manifest, decision)

        self.assertTrue(any("21 alias reviews" in error for error in errors))


class DeferralTests(unittest.TestCase):
    def test_requires_explicit_deferral_of_unsupported_families(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [rotation_declaration()]
        manifest["deferrals"] = [
            {
                "id": "new-domains",
                "proposal": "Additional domains",
                "routing": "deferred-beyond-2.0",
                "reason": "requires the contribution gate",
            }
        ]
        capabilities = {
            "capabilities": [
                {
                    "family": "advanced_iterative",
                    "maturity": "unsupported",
                },
                {"family": "typed_dense_storage", "maturity": "stable"},
            ]
        }

        errors = deferral_errors(manifest, capabilities)

        self.assertTrue(
            any("advanced_iterative" in error for error in errors)
        )

    def test_accepts_complete_deferrals(self) -> None:
        manifest = minimal_manifest()
        manifest["declarations"] = [rotation_declaration()]
        manifest["deferrals"] = [
            {
                "id": "advanced-iterative",
                "proposal": "block krylov, amg, and parallel dispatch",
                "capability_family": "advanced_iterative",
                "routing": "deferred-beyond-2.0",
                "reason": "no stable parallelism design",
            },
            {
                "id": "new-domains",
                "proposal": "additional domains or algorithm families",
                "routing": "deferred-beyond-2.0",
                "reason": "requires the contribution gate",
            },
        ]
        capabilities = {
            "capabilities": [
                {
                    "family": "advanced_iterative",
                    "maturity": "unsupported",
                },
                {"family": "typed_dense_storage", "maturity": "stable"},
            ]
        }

        self.assertEqual([], deferral_errors(manifest, capabilities))


class RoadmapConvergenceTests(unittest.TestCase):
    def test_requires_permanent_closure_record(self) -> None:
        roadmap = "## Next release: 2.0.0\n"

        errors = roadmap_convergence_errors(roadmap)

        self.assertTrue(any("1.9.9" in error for error in errors))
        self.assertTrue(any("1.10.0" in error for error in errors))
        self.assertTrue(any("TVector2D.Rotate" in error for error in errors))

    def test_accepts_advanced_roadmap(self) -> None:
        # After 1.10.0 ships the roadmap moves to a 2.0.0-next posture; the
        # historical convergence gate must still accept it as long as the
        # permanent closure record (1.9.9 handoff, 1.10.0, TVector2D.Rotate)
        # is kept.
        roadmap = (
            "## Previous release: 1.10.0 — Additive API completion and final 2.0 freeze\n"
            "## Next release: 2.0.0 — Stable native numerical platform\n"
            "1.9.9 closed the manifest for 1.10.0 including "
            "`TVector2D.Rotate`.\n"
        )

        self.assertEqual([], roadmap_convergence_errors(roadmap))


class SnapshotFinalTests(unittest.TestCase):
    def test_accepts_final_snapshot(self) -> None:
        snapshot = {
            "schema_version": 1,
            "release": "1.9.9",
            "status": "final",
            "baseline_release": "1.9.0",
            "open_questions": [],
            "compiled_diff_from_1_9_0": {
                "source": [],
                "behaviour": [],
                "warnings": [],
                "packaging": [],
            },
        }

        self.assertEqual([], snapshot_final_errors(snapshot))

    def test_rejects_nonempty_source_diff(self) -> None:
        snapshot = {
            "schema_version": 1,
            "release": "1.9.9",
            "status": "final",
            "baseline_release": "1.9.0",
            "open_questions": [],
            "compiled_diff_from_1_9_0": {
                "source": ["TVector2D.Rotate added in 1.9.9"],
                "behaviour": [],
                "warnings": [],
                "packaging": [],
            },
        }

        errors = snapshot_final_errors(snapshot)

        self.assertTrue(any("source" in error for error in errors))


class ProvenanceTests(unittest.TestCase):
    def test_requires_every_src_unit(self) -> None:
        audit = {
            "schema_version": 1,
            "release": "1.9.9",
            "licence": "MIT",
            "units": [
                {
                    "unit": "MathBase.Precision",
                    "algorithms": "special functions",
                    "provenance": "NIST DLMF",
                    "fixture_provenance": "closed-form identities",
                    "licence": "MIT",
                    "third_party_code": "none",
                    "runtime_dependency": "none",
                }
            ],
        }

        errors = provenance_errors(
            audit, {"MathBase.Precision", "StatsLib.Stats"}
        )

        self.assertTrue(
            any("StatsLib.Stats" in error for error in errors)
        )

    def test_rejects_third_party_code_claims(self) -> None:
        audit = {
            "schema_version": 1,
            "release": "1.9.9",
            "licence": "MIT",
            "units": [
                {
                    "unit": "MathBase.Precision",
                    "algorithms": "special functions",
                    "provenance": "NIST DLMF",
                    "fixture_provenance": "closed-form identities",
                    "licence": "MIT",
                    "third_party_code": "vendored",
                    "runtime_dependency": "none",
                }
            ],
        }

        errors = provenance_errors(audit, {"MathBase.Precision"})

        self.assertTrue(
            any("third-party code" in error for error in errors)
        )


class CapabilityInventoryTests(unittest.TestCase):
    def test_requires_convergence_references(self) -> None:
        errors = capability_inventory_errors(
            {"release": "1.9.8", "capabilities": []}
        )

        self.assertTrue(
            any("1.10.0" in error for error in errors)
        )
        self.assertTrue(
            any("convergence" in error for error in errors)
        )

    def test_accepts_complete_inventory(self) -> None:
        capabilities = {
            "release": "1.10.0",
            "convergence": "docs/releases/1.10.0/capability-manifest.json",
            "provenance_audit": "docs/releases/1.9.9/provenance-audit.json",
            "api_snapshot_final": "docs/releases/1.9.9/api-snapshot-final.json",
        }

        self.assertEqual([], capability_inventory_errors(capabilities))


if __name__ == "__main__":
    unittest.main()
