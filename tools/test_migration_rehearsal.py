#!/usr/bin/env python3
"""Regression tests for the 1.9.7 migration-rehearsal contract."""

from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from migration_rehearsal import (
    REQUIRED_CONCERNS,
    REQUIRED_DOMAINS,
    MigrationContractError,
    load_manifest,
    validate_manifest,
)


def complete_manifest() -> dict[str, object]:
    concerns = {name: f"verified {name}" for name in REQUIRED_CONCERNS}
    domains = [
        {
            "id": domain,
            "guide": "docs/example.md",
            "one_x": copy.deepcopy(concerns),
            "candidate_2_0": copy.deepcopy(concerns),
            "semantic_differences": ["No silent behavior change."],
            "assertions": [f"{domain}: success"],
        }
        for domain in REQUIRED_DOMAINS
    ]
    aliases = []
    for alias in (
        "EPressureError",
        "TPressureKit",
        "EVelocityError",
        "TVelocityKit",
    ):
        aliases.append(
            {
                "name": alias,
                "unit": "EngineeringLib.Pressure",
                "canonical": "EngineeringLib.FluidDynamics.TFluidDynamicsKit",
                "decision": "retain",
                "replacement": "TFluidDynamicsKit",
                "semantic_difference": "Exact compiler alias; no difference.",
                "migration_example": "examples/migration/candidate_2_0/consumer_2_0.lpr",
                "compatibility_period": "Supported throughout 1.x.",
                "owner": "EngineeringLib",
                "package_boundary": "in-place",
                "tested_paths": ["fpc-direct", "lazarus-package"],
            }
        )
    return {
        "schema_version": 1,
        "release": "1.9.7",
        "candidate_release": "2.0",
        "consumers": [
            {
                "id": "one-x",
                "source": "examples/migration/one_x/consumer_1_9.lpr",
                "success_marker": "1.x migration consumer: success",
            },
            {
                "id": "candidate-2.0",
                "source": "examples/migration/candidate_2_0/consumer_2_0.lpr",
                "success_marker": "candidate 2.0 migration consumer: success",
            },
        ],
        "tested_paths": [
            {"id": "fpc-direct", "kind": "source", "compiler": "FPC 3.2.2"},
            {
                "id": "lazarus-package",
                "kind": "package",
                "compiler": "Lazarus 4.8 / FPC 3.2.2",
            },
        ],
        "domains": domains,
        "external_mappings": [
            {
                "source_library": "NumLib",
                "source_api": "typ.ArbFloat",
                "target": "MathBase.SharedTypes.TDoubleArray",
                "equivalence": "conceptual",
                "semantic_differences": ["Explicit zero-based dynamic array."],
                "unsupported": ["No pointer-plus-bounds compatibility wrapper."],
                "source": "https://www.freepascal.org/daily/packages/numlib/numlib/index.html",
            },
            {
                "source_library": "LMath/DMath",
                "source_api": "TVector",
                "target": "MathBase.SharedTypes.TDoubleArray",
                "equivalence": "conceptual",
                "semantic_differences": ["No Lb/Ub slice parameters."],
                "unsupported": ["No package-name compatibility layer."],
                "source": "https://sourceforge.net/projects/lmath-library/files/LMath/",
            },
        ],
        "alias_decisions": aliases,
    }


class MigrationRehearsalContractTests(unittest.TestCase):
    def test_accepts_complete_contract(self) -> None:
        validate_manifest(complete_manifest())

    def test_rejects_missing_domain_semantic_concern(self) -> None:
        manifest = complete_manifest()
        del manifest["domains"][0]["candidate_2_0"]["ownership"]
        with self.assertRaisesRegex(MigrationContractError, "ownership"):
            validate_manifest(manifest)

    def test_rejects_drop_in_external_mapping(self) -> None:
        manifest = complete_manifest()
        manifest["external_mappings"][0]["equivalence"] = "drop-in"
        with self.assertRaisesRegex(MigrationContractError, "conceptual"):
            validate_manifest(manifest)

    def test_rejects_alias_decision_without_all_package_paths(self) -> None:
        manifest = complete_manifest()
        manifest["alias_decisions"][0]["tested_paths"] = ["fpc-direct"]
        with self.assertRaisesRegex(MigrationContractError, "lazarus-package"):
            validate_manifest(manifest)

    def test_load_manifest_rejects_missing_consumer_source(self) -> None:
        manifest = complete_manifest()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(MigrationContractError, "consumer source"):
                load_manifest(path, root)


if __name__ == "__main__":
    unittest.main()
