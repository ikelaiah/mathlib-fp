#!/usr/bin/env python3
"""Validate the offline numerical-evidence catalogue for release 1.9.4."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
RELEASE = "1.9.4"
REFERENCE_FIELDS = (
    "method",
    "source",
    "precision",
    "parameters",
    "license",
    "regeneration",
)
FAULT_INJECTION_FIELDS = ("source", "needle", "replacement", "test")
BUDGET_KINDS = {
    "absolute_error",
    "relative_error",
    "residual",
    "backward_error",
    "reconstruction_error",
    "feasibility",
    "exact",
}


def load_object(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        errors.append(f"{path}: invalid JSON: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{path}: expected a JSON object")
        return {}
    return value


def existing_relative_path(
    root: Path, value: object, description: str, errors: list[str]
) -> bool:
    if not isinstance(value, str) or not value:
        errors.append(f"{description}: expected a non-empty relative path")
        return False
    candidate = (root / value).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        errors.append(f"{description}: path escapes the repository: {value}")
        return False
    if not candidate.is_file():
        errors.append(f"{description}: missing file {value}")
        return False
    return True


def require_string(
    record: dict[str, Any], field: str, prefix: str, errors: list[str]
) -> None:
    if not isinstance(record.get(field), str) or not record[field].strip():
        errors.append(f"{prefix}.{field}: expected a non-empty string")


def validate_budget(record: dict[str, Any], prefix: str, errors: list[str]) -> None:
    budget = record.get("budget")
    if not isinstance(budget, dict):
        errors.append(f"{prefix}.budget: expected an object")
        return
    for field in ("metric", "unit"):
        require_string(budget, field, f"{prefix}.budget", errors)
    kind = budget.get("kind")
    if kind not in BUDGET_KINDS:
        errors.append(
            f"{prefix}.budget.kind: expected one of {sorted(BUDGET_KINDS)}"
        )
    limit = budget.get("limit")
    if isinstance(limit, bool) or not isinstance(limit, (int, float)) or limit < 0:
        errors.append(f"{prefix}.budget.limit: expected a non-negative number")
    elif kind == "exact" and limit != 0:
        errors.append(f"{prefix}.budget.limit: exact checks require a zero limit")
    elif kind != "exact" and limit == 0:
        errors.append(f"{prefix}.budget.limit: non-exact checks require a positive limit")


def validate_reference(record: dict[str, Any], prefix: str, errors: list[str]) -> None:
    reference = record.get("reference")
    if not isinstance(reference, dict):
        errors.append(f"{prefix}.reference: expected an object")
        return
    for field in REFERENCE_FIELDS:
        require_string(reference, field, f"{prefix}.reference", errors)


def validate_tests(
    root: Path, record: dict[str, Any], prefix: str, errors: list[str]
) -> None:
    tests = record.get("tests")
    if not isinstance(tests, list) or not tests:
        errors.append(f"{prefix}.tests: expected a non-empty list")
        return
    for index, test in enumerate(tests):
        test_prefix = f"{prefix}.tests[{index}]"
        if not isinstance(test, dict):
            errors.append(f"{test_prefix}: expected an object")
            continue
        path_value = test.get("path")
        path_exists = existing_relative_path(root, path_value, test_prefix, errors)
        assertions = test.get("assertions")
        if (
            not isinstance(assertions, list)
            or not assertions
            or not all(isinstance(value, str) and value.strip() for value in assertions)
        ):
            errors.append(f"{test_prefix}.assertions: expected non-empty strings")
        elif path_exists:
            source = (root / path_value).read_text(encoding="utf-8")
            for assertion_index, assertion in enumerate(assertions):
                if assertion not in source:
                    errors.append(
                        f"{test_prefix}.assertions[{assertion_index}]: text is absent "
                        f"from {path_value}"
                    )
        require_string(test, "kind", test_prefix, errors)


def validate_fault_injections(
    root: Path, record: dict[str, Any], prefix: str, errors: list[str]
) -> None:
    injections = record.get("fault_injections")
    if not isinstance(injections, list) or not injections:
        errors.append(f"{record.get('family', prefix)}: high-risk family has no fault_injections")
        return
    for index, injection in enumerate(injections):
        injection_prefix = f"{prefix}.fault_injections[{index}]"
        if not isinstance(injection, dict):
            errors.append(f"{injection_prefix}: expected an object")
            continue
        for field in ("needle", "replacement"):
            require_string(injection, field, injection_prefix, errors)
        existing_relative_path(root, injection.get("source"), injection_prefix, errors)
        existing_relative_path(root, injection.get("test"), injection_prefix, errors)


def validate_record(root: Path, record: object, errors: list[str]) -> str | None:
    if not isinstance(record, dict):
        errors.append("family record: expected an object")
        return None
    family = record.get("family")
    if not isinstance(family, str) or not family:
        errors.append("family record: family must be a non-empty string")
        return None
    prefix = f"{family}"
    status = record.get("status")
    if status not in {"qualified", "downgraded"}:
        errors.append(f"{prefix}.status: expected qualified or downgraded")
    risk = record.get("risk")
    if risk not in {"standard", "high"}:
        errors.append(f"{prefix}.risk: expected standard or high")
    require_string(record, "input_domain", prefix, errors)
    validate_budget(record, prefix, errors)
    validate_reference(record, prefix, errors)
    validate_tests(root, record, prefix, errors)
    edge_cases = record.get("edge_cases")
    if (
        not isinstance(edge_cases, list)
        or not edge_cases
        or not all(isinstance(value, str) and value.strip() for value in edge_cases)
    ):
        errors.append(f"{prefix}.edge_cases: expected non-empty strings")
    existing_relative_path(root, record.get("documentation"), f"{prefix}.documentation", errors)
    if risk == "high":
        validate_fault_injections(root, record, prefix, errors)
    if status == "downgraded":
        missing = record.get("missing_evidence")
        if (
            not isinstance(missing, list)
            or not missing
            or not all(isinstance(value, str) and value.strip() for value in missing)
        ):
            errors.append(f"{prefix}.missing_evidence: required for a downgraded family")
    return family


def validate_catalogue(
    root: Path, catalogue_path: Path, inventory_path: Path
) -> list[str]:
    """Return every evidence-contract violation without modifying the checkout."""
    errors: list[str] = []
    catalogue = load_object(catalogue_path, errors)
    inventory = load_object(inventory_path, errors)
    if catalogue.get("schema_version") != 1:
        errors.append("catalogue.schema_version: expected 1")
    if catalogue.get("release") != RELEASE:
        errors.append(f"catalogue.release: expected {RELEASE}")
    if catalogue.get("inventory") != "docs/capabilities.json":
        errors.append("catalogue.inventory: expected docs/capabilities.json")
    if inventory.get("schema_version") != 1:
        errors.append("inventory.schema_version: expected 1")
    if inventory.get("release") != RELEASE:
        errors.append(f"inventory.release: expected {RELEASE}")

    capabilities = inventory.get("capabilities")
    if not isinstance(capabilities, list):
        errors.append("inventory.capabilities: expected a list")
        capabilities = []
    stable_families = {
        item.get("family")
        for item in capabilities
        if isinstance(item, dict) and item.get("maturity") == "stable"
        and isinstance(item.get("family"), str) and item["family"]
    }
    if not stable_families:
        errors.append("inventory: no stable capability families")

    records = catalogue.get("families")
    if not isinstance(records, list):
        errors.append("catalogue.families: expected a list")
        records = []
    seen: set[str] = set()
    for record in records:
        family = validate_record(root, record, errors)
        if family is None:
            continue
        if family in seen:
            errors.append(f"duplicate evidence record for family '{family}'")
        seen.add(family)
        if family not in stable_families:
            errors.append(f"evidence record targets non-stable family '{family}'")
    for family in sorted(stable_families - seen):
        errors.append(f"missing evidence record for stable family '{family}'")
    return errors


def main() -> int:
    catalogue_path = ROOT / "docs" / "numerical-evidence-1.9.4.json"
    inventory_path = ROOT / "docs" / "capabilities.json"
    errors = validate_catalogue(ROOT, catalogue_path, inventory_path)
    if errors:
        print("Numerical-evidence validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Numerical-evidence validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
