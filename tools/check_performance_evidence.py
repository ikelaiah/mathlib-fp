#!/usr/bin/env python3
"""Compile, run, and validate the offline 1.9.5 performance evidence."""

from __future__ import annotations

import argparse
import json
import math
import os
import platform
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = ROOT / "docs" / "performance-evidence-1.9.5.json"
DEFAULT_WORK = ROOT / "build-temp" / "performance-evidence"
INTEGER_FIELDS = {
    "cold_ms",
    "warm_ms",
    "warm_iterations",
    "allocations",
    "retained_bytes",
    "working_elements",
    "dense_shape_elements",
}
FLOAT_FIELDS = {"checksum", "tolerance"}
TEXT_FIELDS = {"id", "domain", "scale", "scalar", "shape", "setup"}
ROW_FIELDS = TEXT_FIELDS | INTEGER_FIELDS | FLOAT_FIELDS
HARD_LIMIT_FIELDS = {
    "allocations_max": "allocations",
    "retained_bytes_max": "retained_bytes",
    "working_elements_max": "working_elements",
    "dense_shape_elements_max": "dense_shape_elements",
}


class EvidenceError(RuntimeError):
    """Raised when benchmark evidence violates the release contract."""


def _command(
    arguments: list[str], *, cwd: Path = ROOT, timeout: int = 1800
) -> str:
    completed = subprocess.run(
        arguments,
        cwd=cwd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )
    if completed.returncode != 0:
        raise EvidenceError(
            f"command failed with exit code {completed.returncode}: "
            f"{' '.join(arguments)}\n{completed.stdout}"
        )
    return completed.stdout


def _parse_value(key: str, value: str, line_number: int) -> object:
    try:
        if key in INTEGER_FIELDS:
            parsed = int(value)
            if parsed < 0:
                raise ValueError("must be non-negative")
            return parsed
        if key in FLOAT_FIELDS:
            parsed = float(value)
            if not math.isfinite(parsed):
                raise ValueError("must be finite")
            if key == "tolerance" and parsed < 0.0:
                raise ValueError("must be non-negative")
            return parsed
    except ValueError as exc:
        raise EvidenceError(
            f"line {line_number}: invalid {key}={value!r}: {exc}"
        ) from exc
    if not value:
        raise EvidenceError(f"line {line_number}: {key} must not be empty")
    if "|" in value or "=" in value:
        raise EvidenceError(f"line {line_number}: invalid delimiter in {key}")
    return value


def parse_perf_output(output: str) -> list[dict[str, object]]:
    """Parse canonical PERF rows while allowing human-readable runner output."""
    rows: list[dict[str, object]] = []
    identifiers: set[str] = set()
    for line_number, raw_line in enumerate(output.splitlines(), start=1):
        if not raw_line.startswith("PERF|"):
            continue
        row: dict[str, object] = {}
        for field in raw_line.split("|")[1:]:
            if "=" not in field:
                raise EvidenceError(
                    f"line {line_number}: malformed field {field!r}"
                )
            key, value = field.split("=", 1)
            if key in row:
                raise EvidenceError(f"line {line_number}: duplicate key {key}")
            if key not in ROW_FIELDS:
                raise EvidenceError(f"line {line_number}: unknown key {key}")
            row[key] = _parse_value(key, value, line_number)
        missing = sorted(ROW_FIELDS - row.keys())
        if missing:
            raise EvidenceError(f"line {line_number}: missing keys {missing}")
        identifier = str(row["id"])
        if identifier in identifiers:
            raise EvidenceError(f"duplicate benchmark row id {identifier}")
        identifiers.add(identifier)
        if int(row["warm_iterations"]) <= 0:
            raise EvidenceError(
                f"line {line_number}: warm_iterations must be positive"
            )
        rows.append(row)
    return rows


def _require_mapping(value: object, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise EvidenceError(f"{label} must be an object")
    return value


def _require_list(value: object, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise EvidenceError(f"{label} must be an array")
    return value


def _validate_manifest(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    if manifest.get("schema_version") != 1:
        raise EvidenceError("manifest.schema_version must be 1")
    if manifest.get("release") != "1.9.5":
        raise EvidenceError("manifest.release must be 1.9.5")
    coverage = _require_mapping(
        manifest.get("required_coverage"), "manifest.required_coverage"
    )
    benchmarks = _require_list(manifest.get("benchmarks"), "manifest.benchmarks")
    contracts: dict[str, dict[str, Any]] = {}
    actual_coverage: set[tuple[str, str]] = set()
    for index, raw_contract in enumerate(benchmarks):
        item = _require_mapping(raw_contract, f"manifest.benchmarks[{index}]")
        identifier = item.get("id")
        if not isinstance(identifier, str) or not identifier:
            raise EvidenceError(f"manifest.benchmarks[{index}].id is required")
        if identifier in contracts:
            raise EvidenceError(f"duplicate manifest benchmark id {identifier}")
        for field in ("domain", "scale", "scalar", "shape", "setup"):
            if not isinstance(item.get(field), str) or not item[field]:
                raise EvidenceError(f"benchmark {identifier}: {field} is required")
        for field in (
            "claim_id",
            "timing_semantics",
            "allocation_semantics",
            "retained_semantics",
        ):
            if not isinstance(item.get(field), str) or not item[field]:
                raise EvidenceError(f"benchmark {identifier}: {field} is required")
        complexity = _require_mapping(
            item.get("complexity_tripwire"),
            f"benchmark {identifier}.complexity_tripwire",
        )
        if complexity.get("metric") != "working_elements" or complexity.get(
            "policy"
        ) != "exact_ceiling":
            raise EvidenceError(
                f"benchmark {identifier}: complexity tripwire must use the "
                "working_elements exact ceiling"
            )
        checksum = _require_mapping(
            item.get("checksum"), f"benchmark {identifier}.checksum"
        )
        for field in ("value", "absolute_tolerance"):
            value = checksum.get(field)
            if not isinstance(value, (int, float)) or not math.isfinite(value):
                raise EvidenceError(
                    f"benchmark {identifier}.checksum.{field} must be finite"
                )
        if checksum["absolute_tolerance"] < 0:
            raise EvidenceError(
                f"benchmark {identifier}.checksum.absolute_tolerance must be non-negative"
            )
        limits = _require_mapping(
            item.get("hard_limits"), f"benchmark {identifier}.hard_limits"
        )
        missing_limits = sorted(HARD_LIMIT_FIELDS.keys() - limits.keys())
        if missing_limits:
            raise EvidenceError(
                f"benchmark {identifier}: missing hard limits {missing_limits}"
            )
        for field in HARD_LIMIT_FIELDS:
            if not isinstance(limits[field], int) or limits[field] < 0:
                raise EvidenceError(
                    f"benchmark {identifier}.{field} must be a non-negative integer"
                )
        contracts[identifier] = item
        actual_coverage.add((item["domain"], item["scale"]))

    required_coverage: set[tuple[str, str]] = set()
    for domain, scales_value in coverage.items():
        if not isinstance(domain, str) or not domain:
            raise EvidenceError("coverage domain names must be non-empty strings")
        scales = _require_list(scales_value, f"coverage.{domain}")
        for scale in scales:
            if not isinstance(scale, str) or not scale:
                raise EvidenceError(f"coverage.{domain} contains an invalid scale")
            required_coverage.add((domain, scale))
    missing_coverage = sorted(required_coverage - actual_coverage)
    if missing_coverage:
        raise EvidenceError(f"missing manifest coverage {missing_coverage}")
    return contracts


def _metric(row: dict[str, object], metric: str) -> float:
    if metric == "warm_ms_per_iteration":
        return float(row["warm_ms"]) / int(row["warm_iterations"])
    if metric in INTEGER_FIELDS or metric in FLOAT_FIELDS:
        return float(row[metric])
    raise EvidenceError(f"unsupported comparison metric {metric}")


def _comparison_result(
    *,
    kind: str,
    identifier: str,
    baseline: str,
    candidate_value: float,
    baseline_value: float,
    review_ratio: float,
    enforcement: str,
) -> dict[str, object]:
    ratio = math.inf if baseline_value == 0.0 else candidate_value / baseline_value
    status = "pass" if ratio <= review_ratio else "review"
    if status == "review" and enforcement == "hard":
        raise EvidenceError(
            f"benchmark {identifier}: {kind} ratio {ratio:.6g} exceeds "
            f"hard limit {review_ratio:.6g}"
        )
    return {
        "kind": kind,
        "benchmark": identifier,
        "baseline": baseline,
        "candidate_value": candidate_value,
        "baseline_value": baseline_value,
        "ratio": ratio,
        "review_ratio": review_ratio,
        "status": status,
        "enforcement": enforcement,
    }


def validate_evidence(
    manifest: dict[str, Any],
    rows: list[dict[str, object]],
    host_key: str,
) -> dict[str, object]:
    """Validate parsed rows and return serializable comparison results."""
    contracts = _validate_manifest(manifest)
    row_map = {str(row["id"]): row for row in rows}
    missing_rows = sorted(contracts.keys() - row_map.keys())
    unexpected_rows = sorted(row_map.keys() - contracts.keys())
    if missing_rows:
        raise EvidenceError(f"missing benchmark rows {missing_rows}")
    if unexpected_rows:
        raise EvidenceError(f"unexpected benchmark rows {unexpected_rows}")

    comparisons: list[dict[str, object]] = []
    for identifier, contract_item in contracts.items():
        runtime = row_map[identifier]
        for field in ("domain", "scale", "scalar", "shape", "setup"):
            if runtime[field] != contract_item[field]:
                raise EvidenceError(
                    f"benchmark {identifier}: {field}={runtime[field]!r}; "
                    f"expected {contract_item[field]!r}"
                )
        expected_checksum = contract_item["checksum"]
        if not math.isclose(
            float(runtime["checksum"]),
            float(expected_checksum["value"]),
            rel_tol=0.0,
            abs_tol=float(expected_checksum["absolute_tolerance"]),
        ):
            raise EvidenceError(
                f"benchmark {identifier}: checksum={runtime['checksum']} is outside "
                f"{expected_checksum['value']} +/- "
                f"{expected_checksum['absolute_tolerance']}"
            )
        if not math.isclose(
            float(runtime["tolerance"]),
            float(expected_checksum["absolute_tolerance"]),
            rel_tol=0.0,
            abs_tol=0.0,
        ):
            raise EvidenceError(
                f"benchmark {identifier}: runtime tolerance does not match manifest"
            )
        for limit_name, runtime_name in HARD_LIMIT_FIELDS.items():
            maximum = int(contract_item["hard_limits"][limit_name])
            actual = int(runtime[runtime_name])
            if actual > maximum:
                raise EvidenceError(
                    f"benchmark {identifier}: {runtime_name}={actual} exceeds {maximum}"
                )

        comparison = contract_item.get("same_run_comparison")
        if comparison is not None:
            comparison = _require_mapping(
                comparison, f"benchmark {identifier}.same_run_comparison"
            )
            baseline_id = comparison.get("baseline_id")
            if baseline_id not in row_map:
                raise EvidenceError(
                    f"benchmark {identifier}: unknown baseline {baseline_id}"
                )
            metric = str(comparison.get("metric"))
            review_ratio = comparison.get("review_ratio")
            enforcement = comparison.get("enforcement")
            if (
                not isinstance(review_ratio, (int, float))
                or review_ratio <= 0
                or not math.isfinite(review_ratio)
            ):
                raise EvidenceError(
                    f"benchmark {identifier}: invalid same-run review_ratio"
                )
            if enforcement not in ("advisory", "hard"):
                raise EvidenceError(
                    f"benchmark {identifier}: invalid comparison enforcement"
                )
            comparisons.append(
                _comparison_result(
                    kind="same_run",
                    identifier=identifier,
                    baseline=str(baseline_id),
                    candidate_value=_metric(runtime, metric),
                    baseline_value=_metric(row_map[str(baseline_id)], metric),
                    review_ratio=float(review_ratio),
                    enforcement=str(enforcement),
                )
            )

        for prior in contract_item.get("prior_baselines", []):
            prior = _require_mapping(prior, f"benchmark {identifier}.prior_baseline")
            if prior.get("host_key") != host_key:
                continue
            baseline_value = prior.get("warm_ms_per_iteration")
            review_ratio = prior.get("review_ratio")
            if (
                not isinstance(baseline_value, (int, float))
                or baseline_value < 0
                or not math.isfinite(baseline_value)
                or not isinstance(review_ratio, (int, float))
                or review_ratio <= 0
                or not math.isfinite(review_ratio)
            ):
                raise EvidenceError(
                    f"benchmark {identifier}: invalid prior baseline values"
                )
            comparisons.append(
                _comparison_result(
                    kind="prior_release",
                    identifier=identifier,
                    baseline=f"{prior.get('release')}@{host_key}",
                    candidate_value=_metric(runtime, "warm_ms_per_iteration"),
                    baseline_value=float(baseline_value),
                    review_ratio=float(review_ratio),
                    enforcement="advisory",
                )
            )

    status = "review" if any(c["status"] == "review" for c in comparisons) else "pass"
    return {
        "status": status,
        "rows": rows,
        "comparisons": comparisons,
        "prior_baseline_host_matched": any(
            c["kind"] == "prior_release" for c in comparisons
        ),
    }


def _safe_host_part(value: str) -> str:
    value = value.strip().lower()
    return re.sub(r"[^a-z0-9._-]+", "-", value).strip("-") or "unknown"


def host_metadata(compiler: str) -> dict[str, object]:
    compiler_version = _command([compiler, "-iV"], timeout=30).strip()
    target_cpu = _command([compiler, "-iTP"], timeout=30).strip()
    target_os = _command([compiler, "-iTO"], timeout=30).strip()
    processor = platform.processor() or os.environ.get("PROCESSOR_IDENTIFIER", "unknown")
    key = "-".join(
        _safe_host_part(value)
        for value in (platform.system(), platform.machine(), processor, compiler_version)
    )
    return {
        "host_key": key,
        "system": platform.system(),
        "release": platform.release(),
        "machine": platform.machine(),
        "processor": processor,
        "logical_cpus": os.cpu_count(),
        "python": platform.python_version(),
        "compiler": compiler,
        "compiler_version": compiler_version,
        "compiler_target_cpu": target_cpu,
        "compiler_target_os": target_os,
    }


def compile_and_run(
    compiler: str, work: Path, flags: list[str]
) -> tuple[str, list[str]]:
    work.mkdir(parents=True, exist_ok=True)
    executable = work / ("BenchmarkRunner.exe" if os.name == "nt" else "BenchmarkRunner")
    command = [
        compiler,
        "-B",
        *flags,
        "-FcUTF8",
        f"-Fu{ROOT / 'src'}",
        f"-Fu{ROOT / 'benchmarks'}",
        f"-FU{work}",
        f"-FE{work}",
        str(ROOT / "benchmarks" / "BenchmarkRunner.lpr"),
    ]
    _command(command, timeout=900)
    return _command([str(executable)], timeout=1800), command


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument("--work-dir", type=Path, default=DEFAULT_WORK)
    parser.add_argument("--captured-output", type=Path)
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()

    manifest_path = args.manifest.resolve()
    work = args.work_dir.resolve()
    result_path = (args.result or (work / "performance-results.json")).resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(manifest, dict):
            raise EvidenceError("manifest root must be an object")
        metadata = host_metadata(args.compiler)
        flags = manifest.get("compiler_flags")
        if not isinstance(flags, list) or not all(isinstance(x, str) for x in flags):
            raise EvidenceError("manifest.compiler_flags must be an array of strings")
        compile_command: list[str] | None = None
        if args.captured_output:
            output = args.captured_output.read_text(encoding="utf-8")
        else:
            output, compile_command = compile_and_run(args.compiler, work, flags)
            work.mkdir(parents=True, exist_ok=True)
            (work / "benchmark-output.log").write_text(output, encoding="utf-8")
        rows = parse_perf_output(output)
        validated = validate_evidence(manifest, rows, str(metadata["host_key"]))
        result = {
            "schema_version": 1,
            "release": "1.9.5",
            "manifest": manifest_path.relative_to(ROOT).as_posix()
            if manifest_path.is_relative_to(ROOT)
            else str(manifest_path),
            "compiler_flags": flags,
            "compile_command": compile_command,
            "host": metadata,
            **validated,
        }
        result_path.parent.mkdir(parents=True, exist_ok=True)
        result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(
            f"Performance evidence {result['status']}: {len(rows)} rows, "
            f"{len(result['comparisons'])} comparisons; results written to {result_path}"
        )
        return 0
    except (OSError, ValueError, EvidenceError, subprocess.TimeoutExpired) as exc:
        print(exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
