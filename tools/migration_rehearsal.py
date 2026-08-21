"""Shared validation for the 1.9.7 migration-rehearsal evidence."""

from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from docs_layout import DocumentationLayout, LayoutError, load_layout


REQUIRED_DOMAINS = (
    "MathBase",
    "AlgebraLib",
    "FinanceLib",
    "EngineeringLib",
    "StatsLib",
    "ProbabilityLib",
    "CombinatoricsLib",
    "NumericsLib",
    "OptimizationLib",
    "TimeSeriesLib",
    "MLLib",
    "InterchangeLib",
    "GeometryLib",
)

REQUIRED_CONCERNS = (
    "construction",
    "ordinary_success",
    "diagnostic_failure",
    "ownership",
    "copying",
    "indexing",
    "precision",
    "defaults",
    "result_interpretation",
)

REQUIRED_ALIASES = {
    "EPressureError",
    "TPressureKit",
    "EVelocityError",
    "TVelocityKit",
}


class MigrationContractError(ValueError):
    """Raised when checked migration evidence is incomplete or overstated."""


def _require_text(record: dict[str, Any], key: str, context: str) -> str:
    value = record.get(key)
    if not isinstance(value, str) or not value.strip():
        raise MigrationContractError(f"{context}: missing non-empty {key}")
    return value


def _require_text_list(record: dict[str, Any], key: str, context: str) -> list[str]:
    value = record.get(key)
    if (
        not isinstance(value, list)
        or not value
        or any(not isinstance(item, str) or not item.strip() for item in value)
    ):
        raise MigrationContractError(f"{context}: missing non-empty {key}")
    return value


def _require_string_list(
    record: dict[str, Any], key: str, context: str,
) -> list[str]:
    value = record.get(key)
    if not isinstance(value, list) or any(not isinstance(item, str) for item in value):
        raise MigrationContractError(f"{context}: {key} must be a string list")
    return value


def validate_manifest(manifest: dict[str, Any]) -> None:
    """Validate completeness without making host-specific compiler claims."""
    if manifest.get("schema_version") != 1:
        raise MigrationContractError("schema_version must be 1")
    if manifest.get("release") != "1.9.7":
        raise MigrationContractError("release must be 1.9.7")
    if manifest.get("candidate_release") != "2.0":
        raise MigrationContractError("candidate_release must be 2.0")

    consumers = manifest.get("consumers")
    if not isinstance(consumers, list) or len(consumers) != 2:
        raise MigrationContractError("exactly two side-by-side consumers are required")
    consumer_ids = set()
    for index, consumer in enumerate(consumers):
        if not isinstance(consumer, dict):
            raise MigrationContractError(f"consumer {index}: expected object")
        context = f"consumer {index}"
        consumer_ids.add(_require_text(consumer, "id", context))
        _require_text(consumer, "source", context)
        _require_text(consumer, "success_marker", context)
        _require_string_list(consumer, "expected_warnings", context)
        _require_text_list(consumer, "source_edits", context)
    if consumer_ids != {"one-x", "candidate-2.0"}:
        raise MigrationContractError("consumers must be one-x and candidate-2.0")

    tested_paths = manifest.get("tested_paths")
    if not isinstance(tested_paths, list):
        raise MigrationContractError("tested_paths must be a list")
    path_ids = set()
    for index, tested_path in enumerate(tested_paths):
        if not isinstance(tested_path, dict):
            raise MigrationContractError(f"tested path {index}: expected object")
        context = f"tested path {index}"
        path_ids.add(_require_text(tested_path, "id", context))
        _require_text(tested_path, "kind", context)
        _require_text(tested_path, "compiler", context)
    required_paths = {"fpc-direct", "lazarus-package"}
    if path_ids != required_paths:
        raise MigrationContractError(
            f"tested paths must be exactly {sorted(required_paths)}"
        )

    domains = manifest.get("domains")
    if not isinstance(domains, list):
        raise MigrationContractError("domains must be a list")
    domain_ids = set()
    for index, domain in enumerate(domains):
        if not isinstance(domain, dict):
            raise MigrationContractError(f"domain {index}: expected object")
        context = f"domain {index}"
        domain_id = _require_text(domain, "id", context)
        domain_ids.add(domain_id)
        _require_text(domain, "guide", context)
        for version_key in ("one_x", "candidate_2_0"):
            version = domain.get(version_key)
            if not isinstance(version, dict):
                raise MigrationContractError(
                    f"{domain_id} {version_key}: expected object"
                )
            for concern in REQUIRED_CONCERNS:
                _require_text(version, concern, f"{domain_id} {version_key}")
        _require_text_list(domain, "semantic_differences", domain_id)
        _require_text_list(domain, "assertions", domain_id)
    if domain_ids != set(REQUIRED_DOMAINS):
        missing = sorted(set(REQUIRED_DOMAINS) - domain_ids)
        extra = sorted(domain_ids - set(REQUIRED_DOMAINS))
        raise MigrationContractError(
            f"domain coverage differs: missing={missing}, extra={extra}"
        )

    mappings = manifest.get("external_mappings")
    if not isinstance(mappings, list) or not mappings:
        raise MigrationContractError("external_mappings must be non-empty")
    mapping_libraries = set()
    for index, mapping in enumerate(mappings):
        if not isinstance(mapping, dict):
            raise MigrationContractError(f"external mapping {index}: expected object")
        context = f"external mapping {index}"
        mapping_libraries.add(_require_text(mapping, "source_library", context))
        _require_text(mapping, "source_api", context)
        _require_text(mapping, "target", context)
        if mapping.get("equivalence") != "conceptual":
            raise MigrationContractError(f"{context}: equivalence must be conceptual")
        _require_text_list(mapping, "semantic_differences", context)
        _require_text_list(mapping, "unsupported", context)
        source = _require_text(mapping, "source", context)
        if not source.startswith("https://"):
            raise MigrationContractError(f"{context}: source must use https")
    if not {"NumLib", "LMath/DMath"}.issubset(mapping_libraries):
        raise MigrationContractError("NumLib and LMath/DMath mappings are required")

    decisions = manifest.get("alias_decisions")
    if not isinstance(decisions, list):
        raise MigrationContractError("alias_decisions must be a list")
    decision_names = set()
    for index, decision in enumerate(decisions):
        if not isinstance(decision, dict):
            raise MigrationContractError(f"alias decision {index}: expected object")
        context = f"alias decision {index}"
        decision_names.add(_require_text(decision, "name", context))
        for key in (
            "unit",
            "canonical",
            "replacement",
            "semantic_difference",
            "migration_example",
            "compatibility_period",
            "owner",
            "package_boundary",
        ):
            _require_text(decision, key, context)
        if decision.get("decision") not in {"retain", "deprecate"}:
            raise MigrationContractError(f"{context}: invalid decision")
        decision_paths = set(_require_text_list(decision, "tested_paths", context))
        missing_paths = sorted(required_paths - decision_paths)
        if missing_paths:
            raise MigrationContractError(
                f"{context}: missing tested paths {missing_paths}"
            )
    if decision_names != REQUIRED_ALIASES:
        raise MigrationContractError(
            "alias decisions must cover exactly " + ", ".join(sorted(REQUIRED_ALIASES))
        )


def _documentation_layout(root: Path) -> DocumentationLayout | None:
    docs = root / "docs"
    layout_path = docs / "layout.json"
    if not layout_path.is_file():
        return None
    try:
        return load_layout(layout_path, docs)
    except LayoutError as exc:
        raise MigrationContractError(f"invalid documentation layout: {exc}") from exc


def _repository_file(
    root: Path, raw_path: str, description: str,
    layout: DocumentationLayout | None,
) -> Path:
    repository = root.resolve()
    candidate = Path(raw_path)
    if candidate.is_absolute():
        raise MigrationContractError(
            f"{description} is outside repository root: {raw_path}"
        )
    resolved = (repository / candidate).resolve()
    try:
        resolved.relative_to(repository)
    except ValueError as exc:
        raise MigrationContractError(
            f"{description} is outside repository root: {raw_path}"
        ) from exc
    if (
        not resolved.is_file()
        and layout is not None
        and candidate.parts[:1] == ("docs",)
    ):
        canonical = layout.canonical_path(
            candidate.relative_to("docs").as_posix()
        )
        if canonical is not None:
            resolved = canonical.resolve()
    if not resolved.is_file():
        raise MigrationContractError(f"missing {description}: {resolved}")
    return resolved


def load_manifest(path: Path, root: Path) -> dict[str, Any]:
    """Read a manifest, validate it, and resolve repository-owned paths."""
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise MigrationContractError(f"cannot read migration manifest {path}: {exc}") from exc
    if not isinstance(manifest, dict):
        raise MigrationContractError("migration manifest root must be an object")
    validate_manifest(manifest)
    layout = _documentation_layout(root)
    for consumer in manifest["consumers"]:
        _repository_file(root, consumer["source"], "consumer source", layout)
    for domain in manifest["domains"]:
        _repository_file(root, domain["guide"], "domain guide", layout)
    for decision in manifest["alias_decisions"]:
        _repository_file(
            root, decision["migration_example"], "alias migration example", layout
        )
    return manifest


def validate_consumer_output(
    consumer_id: str, output: str, success_marker: str,
) -> None:
    """Require each domain assertion and the consumer's final marker."""
    missing = [
        f"{domain}: success"
        for domain in REQUIRED_DOMAINS
        if f"{domain}: success" not in output
    ]
    if success_marker not in output:
        missing.append(success_marker)
    if missing:
        raise MigrationContractError(
            f"{consumer_id}: output is missing assertions {missing}"
        )


def validate_package_boundary(package_path: Path) -> dict[str, object]:
    """Confirm aliases stay in the dependency-neutral main package."""
    try:
        root = ET.parse(package_path).getroot()
    except (OSError, ET.ParseError) as exc:
        raise MigrationContractError(
            f"cannot read Lazarus package {package_path}: {exc}"
        ) from exc
    units = {
        node.attrib.get("Value", "")
        for node in root.findall(".//Files/Item/UnitName")
    }
    required_units = {
        "EngineeringLib.Common",
        "EngineeringLib.FluidDynamics",
        "EngineeringLib.Pressure",
        "EngineeringLib.Velocity",
    }
    missing = sorted(required_units - units)
    if missing:
        raise MigrationContractError(
            f"Lazarus package omits alias-boundary units {missing}"
        )
    required_packages = sorted(
        node.attrib.get("Value", "")
        for node in root.findall(".//RequiredPkgs/Item/PackageName")
    )
    hidden = [name for name in required_packages if name != "FCL"]
    if hidden:
        raise MigrationContractError(
            f"alias package boundary introduces hidden dependencies {hidden}"
        )
    return {
        "choice": "in-place",
        "units": sorted(required_units),
        "required_packages": required_packages,
        "hidden_dependencies": [],
    }
