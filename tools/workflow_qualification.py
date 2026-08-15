"""Shared validation for the 1.9.8 representative-workflow evidence.

The validator and helpers here are intentionally free of any third-party
dependency and of any host-specific compiler claim. They check that the
machine-readable workflow manifest is complete, that every referenced path is
safe and repository-owned, and that a captured workflow run satisfies its
success, diagnostic, and numerical-bounds contracts.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


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

_FLOAT_PATTERN = re.compile(r"[+-]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?")


class WorkflowContractError(ValueError):
    """Raised when checked workflow evidence is incomplete or overstated."""


def _require_text(record: dict[str, Any], key: str, context: str) -> str:
    value = record.get(key)
    if not isinstance(value, str) or not value.strip():
        raise WorkflowContractError(f"{context}: missing non-empty {key}")
    return value


def _require_text_list(record: dict[str, Any], key: str, context: str) -> list[str]:
    value = record.get(key)
    if (
        not isinstance(value, list)
        or not value
        or any(not isinstance(item, str) or not item.strip() for item in value)
    ):
        raise WorkflowContractError(f"{context}: {key} must be a non-empty string list")
    return value


def _is_safe_relative_path(raw_path: str) -> bool:
    if not raw_path or Path(raw_path).is_absolute():
        return False
    parts = Path(raw_path).parts
    return ".." not in parts and not raw_path.replace("\\", "/").startswith("/")


def validate_manifest(manifest: dict[str, Any]) -> None:
    """Validate completeness and path safety without host-specific claims."""
    if manifest.get("schema_version") != 1:
        raise WorkflowContractError("schema_version must be 1")
    if manifest.get("release") != "1.9.8":
        raise WorkflowContractError("release must be 1.9.8")
    _require_text(manifest, "guide", "manifest")

    workflows = manifest.get("workflows")
    if not isinstance(workflows, list) or len(workflows) < 3:
        raise WorkflowContractError("at least three workflows are required")

    ids: set[str] = set()
    sources: set[str] = set()
    for index, workflow in enumerate(workflows):
        if not isinstance(workflow, dict):
            raise WorkflowContractError(f"workflow {index}: expected object")
        context = f"workflow {index}"
        workflow_id = _require_text(workflow, "id", context)
        if workflow_id in ids:
            raise WorkflowContractError(f"{context}: duplicate workflow id {workflow_id!r}")
        ids.add(workflow_id)

        source = _require_text(workflow, "source", context)
        if not source.startswith("examples/") or not source.endswith(".pas"):
            raise WorkflowContractError(
                f"{context}: source must be an examples/*.pas path"
            )
        if source in sources:
            raise WorkflowContractError(f"{context}: duplicate source {source!r}")
        sources.add(source)

        _require_text(workflow, "success_marker", context)
        _require_text(workflow, "description", context)

        domains = _require_text_list(workflow, "domains", context)
        if len(set(domains)) != len(domains):
            raise WorkflowContractError(f"{context}: duplicate domain in domains")
        if len(domains) < 2:
            raise WorkflowContractError(
                f"{context}: a workflow must exercise at least two domains"
            )
        for domain in domains:
            if domain not in REQUIRED_DOMAINS:
                raise WorkflowContractError(f"{context}: unknown domain {domain!r}")

        fixtures = workflow.get("fixtures")
        if not isinstance(fixtures, list) or any(
            not isinstance(item, str) for item in fixtures
        ):
            raise WorkflowContractError(f"{context}: fixtures must be a string list")
        for fixture in fixtures:
            if not _is_safe_relative_path(fixture):
                raise WorkflowContractError(
                    f"{context}: unsafe or absolute fixture path {fixture!r}"
                )

        max_bytes = workflow.get("max_fixture_bytes")
        if not isinstance(max_bytes, int) or isinstance(max_bytes, bool) or max_bytes <= 0:
            raise WorkflowContractError(
                f"{context}: max_fixture_bytes must be a positive integer"
            )

        diagnostics = _require_text_list(workflow, "diagnostics", context)

        expectations = workflow.get("numerical_expectations")
        if not isinstance(expectations, list) or not expectations:
            raise WorkflowContractError(
                f"{context}: numerical_expectations must be a non-empty list"
            )
        expectation_names: set[str] = set()
        for exp_index, expectation in enumerate(expectations):
            if not isinstance(expectation, dict):
                raise WorkflowContractError(
                    f"{context} numerical expectation {exp_index}: expected object"
                )
            exp_context = f"{context} numerical expectation {exp_index}"
            name = _require_text(expectation, "name", exp_context)
            if name in expectation_names:
                raise WorkflowContractError(
                    f"{exp_context}: duplicate name {name!r}"
                )
            expectation_names.add(name)
            _require_text(expectation, "line_prefix", exp_context)
            for key in ("minimum", "maximum"):
                value = expectation.get(key)
                if not isinstance(value, (int, float)) or isinstance(value, bool):
                    raise WorkflowContractError(f"{exp_context}: {key} must be numeric")
            if expectation["minimum"] > expectation["maximum"]:
                raise WorkflowContractError(
                    f"{exp_context}: minimum exceeds maximum"
                )

        exports = workflow.get("exports")
        if (
            not isinstance(exports, list)
            or not exports
            or any(
                not isinstance(item, str) or not _is_safe_relative_path(item)
                for item in exports
            )
        ):
            raise WorkflowContractError(
                f"{context}: exports must be a non-empty list of safe relative paths"
            )


def _repository_file(
    root: Path, raw_path: str, description: str, *, must_exist: bool = True
) -> Path:
    repository = root.resolve()
    candidate = Path(raw_path)
    if candidate.is_absolute():
        raise WorkflowContractError(
            f"{description} is outside repository root: {raw_path}"
        )
    resolved = (repository / candidate).resolve()
    try:
        resolved.relative_to(repository)
    except ValueError as exc:
        raise WorkflowContractError(
            f"{description} is outside repository root: {raw_path}"
        ) from exc
    if must_exist and not resolved.is_file():
        raise WorkflowContractError(f"missing {description}: {resolved}")
    return resolved


def load_manifest(path: Path, root: Path) -> dict[str, Any]:
    """Read a workflow manifest, validate it, and resolve repository paths."""
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkflowContractError(f"cannot read workflow manifest {path}: {exc}") from exc
    if not isinstance(manifest, dict):
        raise WorkflowContractError("workflow manifest root must be an object")
    validate_manifest(manifest)
    _repository_file(root, manifest["guide"], "workflow guide")
    for workflow in manifest["workflows"]:
        _repository_file(root, workflow["source"], "workflow source")
        for fixture in workflow["fixtures"]:
            resolved = _repository_file(root, fixture, "workflow fixture")
            if resolved.stat().st_size > workflow["max_fixture_bytes"]:
                raise WorkflowContractError(
                    f"fixture {fixture!r} exceeds max_fixture_bytes "
                    f"({resolved.stat().st_size} > {workflow['max_fixture_bytes']})"
                )
    return manifest


def parse_line_float(line: str, prefix: str) -> float | None:
    """Return the first float token following `prefix` on a line, if any."""
    stripped = line.strip()
    if not stripped.startswith(prefix):
        return None
    remainder = stripped[len(prefix):]
    match = _FLOAT_PATTERN.search(remainder)
    if match is None:
        return None
    return float(match.group(0))


def validate_workflow_output(
    workflow_id: str, output: str, workflow: dict[str, Any]
) -> list[str]:
    """Check a captured run against success, diagnostic, and numeric contracts."""
    errors: list[str] = []
    success_marker = workflow["success_marker"]
    if success_marker not in output:
        errors.append(f"{workflow_id}: output is missing success marker {success_marker!r}")

    for diagnostic in workflow["diagnostics"]:
        if diagnostic not in output:
            errors.append(f"{workflow_id}: output is missing diagnostic {diagnostic!r}")

    lines = output.splitlines()
    for expectation in workflow["numerical_expectations"]:
        name = expectation["name"]
        prefix = expectation["line_prefix"]
        matches = [
            parse_line_float(line, prefix)
            for line in lines
            if line.strip().startswith(prefix)
        ]
        if not matches or any(value is None for value in matches):
            errors.append(
                f"{workflow_id}: output is missing a parseable value for {name!r} "
                f"(line prefix {prefix!r})"
            )
            continue
        for value in matches:
            if value is not None and not (
                expectation["minimum"] <= value <= expectation["maximum"]
            ):
                errors.append(
                    f"{workflow_id}: {name} value {value} is outside "
                    f"[{expectation['minimum']}, {expectation['maximum']}]"
                )
    return errors
