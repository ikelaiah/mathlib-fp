#!/usr/bin/env python3
"""Check the closed 1.9.9 convergence gate: manifest, policies, provenance,
final snapshot, and roadmap agreement."""

from __future__ import annotations

import sys

from convergence import (
    CAPABILITIES_PATH,
    DECISION_PATH,
    DOCS,
    MANIFEST_PATH,
    PROVENANCE_PATH,
    ROOT,
    SNAPSHOT_FINAL_PATH,
    capability_inventory_errors,
    declaration_completeness_errors,
    deferral_errors,
    deprecation_errors,
    load_json,
    manifest_structure_errors,
    policy_errors,
    provenance_errors,
    roadmap_convergence_errors,
    rotation_errors,
    snapshot_final_errors,
    source_unit_names,
)


def main() -> int:
    errors: list[str] = []

    try:
        manifest = load_json(MANIFEST_PATH)
        errors.extend(manifest_structure_errors(manifest))
        declarations = {
            str(item.get("id")): item for item in manifest.get("declarations", [])
        }
        expected_ids = {"vector2d-rotation", "deprecation-marking"}
        if set(declarations) != expected_ids:
            errors.append(
                f"capability manifest: declarations must be exactly {sorted(expected_ids)}"
            )
        for identifier in sorted(expected_ids & set(declarations)):
            errors.extend(
                declaration_completeness_errors(declarations[identifier], identifier)
            )
        rotation = declarations.get("vector2d-rotation")
        if rotation is not None:
            errors.extend(rotation_errors(rotation))
        decision = load_json(DECISION_PATH)
        errors.extend(deprecation_errors(manifest, decision))
        capabilities = load_json(CAPABILITIES_PATH)
        errors.extend(deferral_errors(manifest, capabilities))
        errors.extend(capability_inventory_errors(capabilities))
    except (ValueError, KeyError, OSError) as exc:
        errors.append(f"convergence artifacts cannot be read: {exc}")

    try:
        snapshot = load_json(SNAPSHOT_FINAL_PATH)
        errors.extend(snapshot_final_errors(snapshot))
    except (ValueError, KeyError, OSError) as exc:
        errors.append(f"final snapshot cannot be read: {exc}")

    try:
        audit = load_json(PROVENANCE_PATH)
        errors.extend(provenance_errors(audit, source_unit_names()))
    except (ValueError, KeyError, OSError) as exc:
        errors.append(f"provenance audit cannot be read: {exc}")

    errors.extend(policy_errors())
    roadmap = (DOCS / "project/roadmap.md").read_text(encoding="utf-8")
    errors.extend(roadmap_convergence_errors(roadmap))

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"Convergence gate passed: manifest closed for 1.10.0, "
        f"{len(source_unit_names())} provenance units, policies, final snapshot, "
        "and roadmap agree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
