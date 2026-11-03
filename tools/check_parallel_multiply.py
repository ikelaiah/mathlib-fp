#!/usr/bin/env python3
"""Qualify v2.15.0 opt-in parallel dense multiplication on named shapes.

Each shape and worker count runs in its own process so peak memory is not
shared. Exact gates: the parallel result equals the serial blocked result
bitwise, matches the portable oracle within a scaled tolerance, and uses the
documented effective worker count. A second build without a thread manager
(no cthreads on Unix) must fall back to one worker and still agree. Timings
are reported as speedup and scaling efficiency; a parallel run slower than
serial on a host with enough processors is flagged for review, not failed.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "benchmarks" / "ParallelMultiplyEvidence.lpr"
RELEASE = "2.15.0"
FLAGS = ["-B", "-O3", "-FcUTF8"]
MAX_WORKERS = 64
MIN_WORK_PER_WORKER = 131072
SHAPES = [
    ("square-256", "double", 256, 256, 256),
    ("rectangular-384x128x320", "double", 384, 128, 320),
    ("complex-160", "complex", 160, 160, 160),
]
WORKER_COUNTS = [1, 2, 4, 8]
REPEATS = 2
FALLBACK = ("fallback-128x96x112", "double", 128, 96, 112, 4)
ORACLE_RELATIVE_TOLERANCE = 1.0e-13
INTEGER_FIELDS = {
    "requested_workers", "effective_workers", "cpu_count", "repeats",
    "logical_bytes", "peak_resident_bytes",
}
FLOAT_FIELDS = {
    "serial_ms", "parallel_ms", "max_abs_difference_vs_portable",
    "max_abs_portable_value",
}
BOOLEAN_FIELDS = {"threading_available", "bitwise_equal"}


class EvidenceError(RuntimeError):
    """Raised when parallel multiplication evidence violates its contract."""


def expected_workers(rows: int, inner: int, cols: int, requested: int,
                     threading: bool) -> int:
    """Mirror EffectiveMultiplyWorkers for valid inputs."""
    if not 1 <= requested <= MAX_WORKERS:
        raise ValueError("requested workers out of range")
    if requested == 1 or rows < 2 or inner == 0 or cols == 0 or not threading:
        return 1
    workers = min(requested, rows, (rows * inner * cols) // MIN_WORK_PER_WORKER)
    return workers if workers >= 2 else 1


def parse_line(output: str) -> dict[str, object]:
    rows = [line for line in output.splitlines() if line.startswith("PARALLEL|")]
    if len(rows) != 1:
        raise EvidenceError(f"expected one PARALLEL row, got {len(rows)}")
    record: dict[str, object] = {}
    for field in rows[0].split("|")[1:]:
        key, separator, value = field.partition("=")
        if not separator or key in record:
            raise EvidenceError(f"malformed field {field!r}")
        if key in INTEGER_FIELDS:
            record[key] = int(value)
        elif key in FLOAT_FIELDS:
            record[key] = float(value)
        elif key in BOOLEAN_FIELDS:
            if value not in {"true", "false"}:
                raise EvidenceError(f"invalid boolean {key}={value}")
            record[key] = value == "true"
        else:
            record[key] = value
    missing = (INTEGER_FIELDS | FLOAT_FIELDS | BOOLEAN_FIELDS |
               {"scalar", "shape"}) - record.keys()
    if missing:
        raise EvidenceError(f"missing fields {sorted(missing)}")
    return record


def check_record(record: dict[str, object], rows: int, inner: int, cols: int,
                 requested: int, threading: bool) -> None:
    if record["shape"] != f"{rows}x{inner}x{cols}":
        raise EvidenceError(f"unexpected shape {record['shape']}")
    if record["requested_workers"] != requested:
        raise EvidenceError("requested worker count was not recorded")
    if record["threading_available"] != threading:
        raise EvidenceError(
            f"threading_available={record['threading_available']}, "
            f"expected {threading}")
    expected = expected_workers(rows, inner, cols, requested, threading)
    if record["effective_workers"] != expected:
        raise EvidenceError(
            f"{record['shape']} workers={requested}: effective "
            f"{record['effective_workers']}, expected {expected}")
    if not record["bitwise_equal"]:
        raise EvidenceError(
            f"{record['shape']} workers={requested}: parallel result is not "
            "bitwise equal to the serial blocked result")
    scale = max(1.0, float(record["max_abs_portable_value"]))
    limit = ORACLE_RELATIVE_TOLERANCE * scale
    if float(record["max_abs_difference_vs_portable"]) > limit:
        raise EvidenceError(
            f"{record['shape']} workers={requested}: difference from portable "
            f"oracle {record['max_abs_difference_vs_portable']} exceeds {limit}")
    if float(record["serial_ms"]) <= 0.0 or float(record["parallel_ms"]) <= 0.0:
        raise EvidenceError("timings must be positive")


def derive(records: list[dict[str, object]]) -> list[str]:
    """Add speedup, efficiency and memory deltas; return review notes."""
    reviews: list[str] = []
    baseline: dict[str, dict[str, object]] = {}
    for record in records:
        if record["requested_workers"] == 1:
            baseline[str(record["case"])] = record
    for record in records:
        speedup = float(record["serial_ms"]) / float(record["parallel_ms"])
        record["speedup"] = round(speedup, 3)
        record["scaling_efficiency"] = round(
            speedup / int(record["effective_workers"]), 3)
        base = baseline.get(str(record["case"]))
        if base is not None:
            record["peak_resident_delta_vs_one_worker_bytes"] = (
                int(record["peak_resident_bytes"]) -
                int(base["peak_resident_bytes"]))
        effective = int(record["effective_workers"])
        if 2 <= effective <= int(record["cpu_count"]) and speedup < 1.0:
            reviews.append(
                f"{record['case']} workers={effective}: speedup {speedup:.2f} "
                "below 1.0 on a host with enough processors")
    return reviews


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument("--work-dir", type=Path,
                        default=ROOT / "build-temp" / "parallel-multiply")
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()
    work = args.work_dir.resolve()
    work.mkdir(parents=True, exist_ok=True)
    result_path = (args.result or work / "results.json").resolve()

    def run(name: str, command: list[str], timeout: int = 900) -> str:
        completed = subprocess.run(
            [str(part) for part in command], cwd=work,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, encoding="utf-8", errors="replace",
            timeout=timeout, check=False)
        (work / f"{name}.log").write_text(completed.stdout, encoding="utf-8")
        if completed.returncode:
            raise EvidenceError(f"{name} failed:\n{completed.stdout[-6000:]}")
        return completed.stdout

    def build(label: str, defines: list[str]) -> Path:
        directory = work / label
        units = directory / "units"
        units.mkdir(parents=True, exist_ok=True)
        run(f"{label}-compile", [
            args.compiler, *FLAGS, *defines, f"-Fu{ROOT / 'src'}",
            f"-FU{units}", f"-FE{directory}", str(SOURCE)])
        return directory / ("ParallelMultiplyEvidence" +
                            (".exe" if os.name == "nt" else ""))

    evidence: dict[str, object] = {
        "schema_version": 1, "release": RELEASE, "status": "failed",
    }
    try:
        compiler_version = run("compiler-version",
                               [args.compiler, "-iV"], timeout=60).strip()
        threaded = build("threaded", [])
        fallback = build("no-thread-manager", ["-dMFP_NO_THREAD_MANAGER"])
        records: list[dict[str, object]] = []
        for case, scalar, rows, inner, cols in SHAPES:
            for workers in WORKER_COUNTS:
                output = run(f"{case}-w{workers}", [
                    threaded, scalar, rows, inner, cols, workers, REPEATS])
                record = parse_line(output)
                check_record(record, rows, inner, cols, workers, True)
                record["case"] = case
                records.append(record)
        reviews = derive(records)

        case, scalar, rows, inner, cols, workers = FALLBACK
        fallback_threading = os.name == "nt"
        output = run(case, [fallback, scalar, rows, inner, cols, workers, 1])
        fallback_record = parse_line(output)
        check_record(fallback_record, rows, inner, cols, workers,
                     fallback_threading)
        fallback_record["case"] = case
        fallback_record["build"] = (
            "-dMFP_NO_THREAD_MANAGER: Unix omits cthreads; Windows always "
            "has a thread manager, so this build still runs in parallel there")

        evidence.update({
            "status": "passed",
            "host": {
                "system": platform.system(),
                "release": platform.release(),
                "machine": platform.machine(),
                "processor": platform.processor(),
                "logical_processors": os.cpu_count(),
                "compiler_version": compiler_version,
                "compiler_flags": FLAGS,
            },
            "contract": {
                "oracle": "MultiplyBlockedInto with the same block size; "
                          "parallel results must be bitwise equal",
                "portable_oracle_relative_tolerance": ORACLE_RELATIVE_TOLERANCE,
                "timing": "best of REPEATS wall-clock runs per process; "
                          "speedup = serial_ms / parallel_ms; "
                          "scaling_efficiency = speedup / effective_workers",
                "memory": "process peak resident set (Windows "
                          "PeakWorkingSetSize, Linux VmHWM), one process per row",
                "review": "advisory when speedup < 1 with effective workers "
                          "not above logical processors",
                "repeats": REPEATS,
            },
            "runs": records,
            "fallback": fallback_record,
            "reviews": reviews,
        })
    except (OSError, EvidenceError, ValueError,
            subprocess.TimeoutExpired) as error:
        evidence["error"] = str(error)
        print(error, file=sys.stderr)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(evidence, indent=2) + "\n",
                           encoding="utf-8")
    if evidence["status"] != "passed":
        return 1
    for record in evidence["runs"]:  # type: ignore[union-attr]
        print(f"{record['case']:>26} workers={record['effective_workers']:>2} "
              f"serial={record['serial_ms']:9.1f} ms "
              f"parallel={record['parallel_ms']:9.1f} ms "
              f"speedup={record['speedup']:5.2f} "
              f"efficiency={record['scaling_efficiency']:4.2f}")
    for note in evidence["reviews"]:  # type: ignore[union-attr]
        print("review:", note)
    print("Parallel multiplication evidence passed; results written to",
          result_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
