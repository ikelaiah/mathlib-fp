#!/usr/bin/env python3
"""Tests for the 1.9.6 portability-evidence contract."""

from __future__ import annotations

import unittest

from check_portability_evidence import (
    EvidenceError,
    audit_source_texts,
    parse_probe_output,
    validate_evidence,
    validate_manifest,
)


def manifest() -> dict[str, object]:
    return {
        "schema_version": 1,
        "release": "1.9.6",
        "compiler": {"name": "Free Pascal", "version": "3.2.2"},
        "required_audits": [
            "filesystem",
            "locale",
            "endianness",
            "floating_point",
            "calling_convention",
            "address_space",
            "runtime_dependency",
        ],
        "cross_target_invariants": {
            "endian": "little",
            "locale_guard": "pass",
            "numerical_checksum": "3ff0000000000000",
            "binary_fixture_hex": "4d4c4650",
        },
        "targets": [
            {
                "id": "win64-x86_64",
                "tier": "primary",
                "target_os": "win64",
                "target_cpu": "x86_64",
                "pointer_bits": 64,
                "scalar_abi": {
                    "single_bytes": 4,
                    "double_bytes": 8,
                    "extended_bytes": 8,
                },
                "exact_checks": ["full-qualification", "lazarus-package"],
                "evidence": {
                    "last_successful_date": "2026-08-11",
                    "ref": "v1.9.5",
                    "status": "retained",
                },
                "limitations": ["v1.9.6 candidate CI is required before tag"],
            },
            {
                "id": "darwin-aarch64",
                "tier": "unqualified",
                "target_os": "darwin",
                "target_cpu": "aarch64",
                "reason": "No maintainable runner evidence exists.",
            },
        ],
    }


def probe(**overrides: str) -> str:
    fields = {
        "release": "1.9.6",
        "target_os": "win64",
        "target_cpu": "x86_64",
        "compiler_version": "3.2.2",
        "pointer_bits": "64",
        "sizeint_bits": "64",
        "single_bytes": "4",
        "double_bytes": "8",
        "extended_bytes": "8",
        "endian": "little",
        "locale_guard": "pass",
        "numerical_checksum": "3ff0000000000000",
        "binary_fixture_hex": "4d4c4650",
    }
    fields.update(overrides)
    return "PORT|" + "|".join(f"{key}={value}" for key, value in fields.items())


class PortabilityEvidenceTests(unittest.TestCase):
    def test_parses_one_canonical_probe_row(self) -> None:
        parsed = parse_probe_output("human heading\n" + probe() + "\n")

        self.assertEqual("x86_64", parsed["target_cpu"])
        self.assertEqual(64, parsed["pointer_bits"])
        self.assertEqual(8, parsed["double_bytes"])

    def test_rejects_duplicate_or_missing_probe_fields(self) -> None:
        with self.assertRaisesRegex(EvidenceError, "duplicate key pointer_bits"):
            parse_probe_output(probe() + "|pointer_bits=32")
        with self.assertRaisesRegex(EvidenceError, "missing keys"):
            parse_probe_output("PORT|release=1.9.6")

    def test_manifest_requires_dated_exact_evidence_for_supported_targets(self) -> None:
        invalid = manifest()
        target = invalid["targets"][0]
        assert isinstance(target, dict)
        target["exact_checks"] = []

        with self.assertRaisesRegex(EvidenceError, "exact_checks"):
            validate_manifest(invalid)

    def test_unqualified_target_requires_reason_not_inferred_abi(self) -> None:
        invalid = manifest()
        target = invalid["targets"][1]
        assert isinstance(target, dict)
        del target["reason"]

        with self.assertRaisesRegex(EvidenceError, "reason"):
            validate_manifest(invalid)

    def test_rejects_target_abi_and_binary_invariant_mismatch(self) -> None:
        with self.assertRaisesRegex(EvidenceError, "pointer_bits"):
            validate_evidence(manifest(), parse_probe_output(probe(pointer_bits="32")))
        with self.assertRaisesRegex(EvidenceError, "binary_fixture_hex"):
            validate_evidence(
                manifest(),
                parse_probe_output(probe(binary_fixture_hex="00000000")),
            )

    def test_accepts_exact_supported_target_observations(self) -> None:
        result = validate_evidence(manifest(), parse_probe_output(probe()))

        self.assertEqual("pass", result["status"])
        self.assertEqual("win64-x86_64", result["target_id"])
        self.assertEqual("primary", result["tier"])

    def test_source_audit_rejects_foreign_runtime_and_calling_convention(self) -> None:
        findings = audit_source_texts(
            {
                "src/Foreign.pas": (
                    "unit Foreign; interface uses Dynlibs; "
                    "function ForeignSolve: Integer; cdecl; external 'solver.dll';"
                )
            }
        )

        self.assertTrue(any("runtime_dependency" in item for item in findings))
        self.assertTrue(any("calling_convention" in item for item in findings))

    def test_source_audit_accepts_standard_portable_units(self) -> None:
        findings = audit_source_texts(
            {
                "src/Portable.pas": (
                    "unit Portable; { String parsing uses the process locale. } "
                    "interface uses SysUtils, Classes, Math; "
                    "type TWorker = class procedure Process; end; "
                    "implementation procedure TWorker.Process; begin "
                    "Writeln('external cdecl process'); end; end."
                )
            }
        )

        self.assertEqual([], findings)


if __name__ == "__main__":
    unittest.main()
