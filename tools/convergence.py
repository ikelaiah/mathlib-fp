#!/usr/bin/env python3
"""Shared validation helpers for the 1.9.9 convergence gate."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

MANIFEST_PATH = DOCS / "capability-manifest-1.10.0.json"
SNAPSHOT_FINAL_PATH = DOCS / "api-snapshot-final-1.9.9.json"
PROVENANCE_PATH = DOCS / "provenance-audit-1.9.9.json"
DECISION_PATH = DOCS / "api-decision-2.0.json"

EXPECTED_ROTATE_SIGNATURE = "function Rotate(const Angle: Double): TVector2D"

REQUIRED_POLICY_SECTIONS = (
    "## 2.x maintenance policy",
    "## Support policy",
    "## Deprecation policy",
    "## Contribution gate for new domains",
    "## Security support window",
    "## Provenance and licence",
)

REQUIRED_HUMAN_DOCUMENTS = (
    "CAPABILITY_MANIFEST_1.10.0.md",
    "API_SNAPSHOT_FINAL_1.9.9.md",
    "GOVERNANCE.md",
    "PROVENANCE_AUDIT_1.9.9.md",
)

REQUIRED_ALIAS_RETENTIONS = (
    "TPressureKit",
    "EPressureError",
    "TVelocityKit",
    "EVelocityError",
)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def source_unit_names() -> set[str]:
    return {path.stem for path in (ROOT / "src").glob("*.pas")}


def manifest_structure_errors(manifest: dict) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema_version") != 1:
        errors.append("capability manifest: schema_version must be 1")
    if manifest.get("closed_by_release") != "1.9.9":
        errors.append("capability manifest: closed_by_release must be 1.9.9")
    if manifest.get("target_release") != "1.10.0":
        errors.append("capability manifest: target_release must be 1.10.0")
    if manifest.get("status") != "closed":
        errors.append("capability manifest: status must be closed")
    if manifest.get("unresolved_api_questions") != []:
        errors.append("capability manifest: unresolved API questions remain")
    declarations = manifest.get("declarations")
    if not isinstance(declarations, list) or not declarations:
        errors.append("capability manifest: declarations must be non-empty")
    return errors


def declaration_completeness_errors(declaration: dict, identifier: str) -> list[str]:
    errors: list[str] = []
    if declaration.get("status") != "accepted-for-1.10.0":
        errors.append(f"declaration {identifier}: status must be accepted-for-1.10.0")
    for field in (
        "behavior_contract",
        "test_plan",
        "documentation_plan",
        "compatibility_impact",
    ):
        value = declaration.get(field)
        if not isinstance(value, list) or not value or not all(
            isinstance(item, str) and item.strip() for item in value
        ):
            errors.append(f"declaration {identifier}: {field} must be a non-empty list")
    return errors


def rotation_errors(declaration: dict) -> list[str]:
    errors = declaration_completeness_errors(declaration, "vector2d-rotation")
    if declaration.get("unit") != "GeometryLib.Geometry":
        errors.append("rotation declaration: unit must be GeometryLib.Geometry")
    if declaration.get("owner") != "TVector2D":
        errors.append("rotation declaration: owner must be TVector2D")
    if declaration.get("name") != "Rotate":
        errors.append("rotation declaration: name must be Rotate")
    if declaration.get("signature") != EXPECTED_ROTATE_SIGNATURE:
        errors.append(
            "rotation declaration: signature must be "
            f"{EXPECTED_ROTATE_SIGNATURE!r}"
        )
    contract = " ".join(declaration.get("behavior_contract", [])).casefold()
    for keyword in (
        "radians",
        "counter-clockwise",
        "not modified",
        "allocation-free",
        "perpendicular",
        "magnitude",
        "zero vector",
        "non-finite",
    ):
        if keyword not in contract:
            errors.append(
                f"rotation declaration: behavior contract must state {keyword!r}"
            )
    return errors


def deprecation_errors(manifest: dict, decision: dict) -> list[str]:
    declaration = next(
        (
            item
            for item in manifest.get("declarations", [])
            if item.get("id") == "deprecation-marking"
        ),
        None,
    )
    if declaration is None:
        return ["capability manifest: missing deprecation-marking declaration"]
    errors = declaration_completeness_errors(declaration, "deprecation-marking")
    if declaration.get("decision") != "no-deprecation":
        errors.append(
            "deprecation declaration: the closed 1.10.0 decision is no-deprecation"
        )
    contract = " ".join(declaration.get("behavior_contract", [])).casefold()
    for alias in REQUIRED_ALIAS_RETENTIONS:
        if alias.casefold() not in contract:
            errors.append(
                f"deprecation declaration: contract must retain {alias}"
            )
    if "21" not in contract:
        errors.append(
            "deprecation declaration: contract must cover all 21 retained aliases"
        )
    reviews = decision.get("alias_reviews", [])
    if len(reviews) != 21:
        errors.append(
            f"api decision: expected 21 alias reviews, found {len(reviews)}"
        )
    if any(review.get("decision") != "retain" for review in reviews):
        errors.append("api decision: every alias review must remain retain")
    if decision.get("unresolved_decisions") != []:
        errors.append("api decision: unresolved decisions remain")
    source_deprecations = [
        path.name
        for path in (ROOT / "src").glob("*.pas")
        if "deprecated" in path.read_text(encoding="utf-8-sig").casefold()
    ]
    if source_deprecations:
        errors.append(
            "src contains deprecated declarations before 1.10.0: "
            f"{sorted(source_deprecations)}"
        )
    return errors


def deferral_errors(manifest: dict, capabilities: dict) -> list[str]:
    errors: list[str] = []
    deferrals = manifest.get("deferrals")
    if not isinstance(deferrals, list) or not deferrals:
        return ["capability manifest: deferrals must be a non-empty list"]
    for deferral in deferrals:
        for field in ("id", "proposal", "routing", "reason"):
            if not isinstance(deferral.get(field), str) or not deferral[field].strip():
                errors.append(f"deferral {deferral.get('id')}: missing {field}")
        if deferral.get("routing") != "deferred-beyond-2.0":
            errors.append(
                f"deferral {deferral.get('id')}: routing must be deferred-beyond-2.0"
            )
    unsupported = [
        str(item.get("family"))
        for item in capabilities.get("capabilities", [])
        if item.get("maturity") == "unsupported"
    ]
    routed_families = {
        str(deferral.get("capability_family"))
        for deferral in deferrals
        if deferral.get("capability_family")
    }
    for family in unsupported:
        if family not in routed_families:
            errors.append(
                f"unsupported capability family {family!r} is not explicitly deferred"
            )
    if not any(deferral.get("id") == "new-domains" for deferral in deferrals):
        errors.append("capability manifest: missing new-domains deferral")
    return errors


def roadmap_convergence_errors(roadmap: str) -> list[str]:
    """Return errors when the roadmap omits the permanent 1.10.0 closure record."""
    errors: list[str] = []
    # The 1.9.9 convergence gate is historical. Once 1.10.0 ships the roadmap
    # advances to a 2.0.0-next posture, so this deliberately does not depend on
    # the live "Previous release"/"Next release" headings. It only requires the
    # roadmap to keep permanently recording the 1.9.9 handoff and the closed
    # 1.10.0 accepted scope.
    if "1.9.9" not in roadmap:
        errors.append("Roadmap does not record the 1.9.9 convergence handoff")
    if "1.10.0" not in roadmap:
        errors.append("Roadmap does not record 1.10.0")
    if "TVector2D.Rotate" not in roadmap:
        errors.append(
            "Roadmap does not record the closed 1.10.0 TVector2D.Rotate scope"
        )
    return errors


def snapshot_final_errors(snapshot: dict) -> list[str]:
    errors: list[str] = []
    if snapshot.get("schema_version") != 1:
        errors.append("final snapshot: schema_version must be 1")
    if snapshot.get("release") != "1.9.9":
        errors.append("final snapshot: release must be 1.9.9")
    if snapshot.get("status") != "final":
        errors.append("final snapshot: status must be final")
    if snapshot.get("baseline_release") != "1.9.0":
        errors.append("final snapshot: baseline_release must be 1.9.0")
    if snapshot.get("open_questions") != []:
        errors.append("final snapshot: open questions remain")
    compiled = snapshot.get("compiled_diff_from_1_9_0", {})
    for category in ("source", "behaviour", "warnings", "packaging"):
        if compiled.get(category) != []:
            errors.append(
                f"final snapshot: compiled diff category {category} must be empty"
            )
    return errors


def policy_errors() -> list[str]:
    errors: list[str] = []
    for name in REQUIRED_HUMAN_DOCUMENTS:
        if not (DOCS / name).is_file():
            errors.append(f"missing 1.9.9 convergence document: docs/{name}")
    governance = (DOCS / "GOVERNANCE.md").read_text(encoding="utf-8")
    for section in REQUIRED_POLICY_SECTIONS:
        if section not in governance:
            errors.append(f"docs/GOVERNANCE.md: missing section {section}")
    security = (ROOT / "SECURITY.md").read_text(encoding="utf-8")
    if "## Security Support Window" not in security:
        errors.append("SECURITY.md: missing Security Support Window section")
    contributing = (ROOT / "CONTRIBUTING.md").read_text(encoding="utf-8")
    if "Contribution gate for new domains" not in contributing:
        errors.append("CONTRIBUTING.md: missing new-domain contribution gate")
    return errors


def provenance_errors(audit: dict, unit_names: set[str]) -> list[str]:
    errors: list[str] = []
    if audit.get("schema_version") != 1:
        errors.append("provenance audit: schema_version must be 1")
    if audit.get("release") != "1.9.9":
        errors.append("provenance audit: release must be 1.9.9")
    if audit.get("licence") != "MIT":
        errors.append("provenance audit: licence must be MIT")
    records = audit.get("units", [])
    covered = {str(record.get("unit")) for record in records}
    missing = sorted(unit_names - covered)
    if missing:
        errors.append(f"provenance audit is missing src units: {missing}")
    extra = sorted(covered - unit_names)
    if extra:
        errors.append(f"provenance audit covers unknown units: {extra}")
    for record in records:
        unit = record.get("unit")
        for field in ("algorithms", "provenance", "fixture_provenance"):
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"provenance audit: {unit} has empty {field}")
        if record.get("licence") != "MIT":
            errors.append(f"provenance audit: {unit} licence must be MIT")
        if record.get("third_party_code") != "none":
            errors.append(f"provenance audit: {unit} claims third-party code")
        if record.get("runtime_dependency") != "none":
            errors.append(f"provenance audit: {unit} claims a runtime dependency")
    return errors


def capability_inventory_errors(capabilities: dict) -> list[str]:
    errors: list[str] = []
    if capabilities.get("release") != "1.10.0":
        errors.append("capabilities.json: release must be 1.10.0")
    if capabilities.get("convergence") != "docs/capability-manifest-1.10.0.json":
        errors.append("capabilities.json: missing convergence manifest reference")
    if capabilities.get("provenance_audit") != "docs/provenance-audit-1.9.9.json":
        errors.append("capabilities.json: missing provenance audit reference")
    if capabilities.get("api_snapshot_final") != "docs/api-snapshot-final-1.9.9.json":
        errors.append("capabilities.json: missing final snapshot reference")
    return errors
