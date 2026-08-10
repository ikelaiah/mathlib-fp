#!/usr/bin/env python3
"""Tests for isolated, reproducible numerical fault injection."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from run_numerical_mutation import (
    Mutation,
    materialize_mutation,
    mutations_from_catalogue,
    source_overlay_path,
)


class NumericalMutationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "src").mkdir()
        (self.root / "tests").mkdir()
        (self.root / "src" / "Example.pas").write_text(
            "first := good;\nsecond := good;\n", encoding="utf-8"
        )
        (self.root / "tests" / "TestExample.pas").write_text(
            "unit TestExample;\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_materializes_only_the_selected_occurrence_in_a_temporary_tree(self) -> None:
        mutation = Mutation(
            family="example",
            source="src/Example.pas",
            needle="good",
            replacement="bad",
            occurrence=2,
            test="tests/TestExample.pas",
        )
        destination = self.root / "temporary-src"

        mutated = materialize_mutation(self.root, destination, mutation)

        self.assertEqual(
            "first := good;\nsecond := bad;\n",
            mutated.read_text(encoding="utf-8"),
        )
        self.assertEqual(
            "first := good;\nsecond := good;\n",
            (self.root / mutation.source).read_text(encoding="utf-8"),
        )
        self.assertEqual(destination / "src", source_overlay_path(destination))

    def test_rejects_a_missing_or_ambiguous_mutation_target(self) -> None:
        missing = Mutation(
            family="example",
            source="src/Example.pas",
            needle="missing",
            replacement="bad",
            occurrence=1,
            test="tests/TestExample.pas",
        )
        ambiguous = Mutation(
            family="example",
            source="src/Example.pas",
            needle="good",
            replacement="bad",
            occurrence=3,
            test="tests/TestExample.pas",
        )

        with self.assertRaisesRegex(ValueError, "does not occur"):
            materialize_mutation(self.root, self.root / "temporary-src", missing)
        with self.assertRaisesRegex(ValueError, "only occurs"):
            materialize_mutation(self.root, self.root / "temporary-src", ambiguous)

    def test_loads_only_high_risk_catalogue_mutations(self) -> None:
        catalogue = {
            "families": [
                {"family": "standard", "risk": "standard"},
                {
                    "family": "high",
                    "risk": "high",
                    "fault_injections": [
                        {
                            "source": "src/Example.pas",
                            "needle": "good",
                            "replacement": "bad",
                            "occurrence": 1,
                            "test": "tests/TestExample.pas",
                        }
                    ],
                },
            ]
        }

        mutations = mutations_from_catalogue(catalogue)

        self.assertEqual(1, len(mutations))
        self.assertEqual("high", mutations[0].family)
        self.assertEqual(1, mutations[0].occurrence)


if __name__ == "__main__":
    unittest.main()
