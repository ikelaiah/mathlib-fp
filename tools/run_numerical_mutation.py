#!/usr/bin/env python3
"""Prove selected numerical tests detect isolated source mutations offline."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class Mutation:
    family: str
    source: str
    needle: str
    replacement: str
    occurrence: int
    test: str


def mutations_from_catalogue(catalogue: dict[str, Any]) -> list[Mutation]:
    """Extract reproducible mutation cases from high-risk evidence records."""
    families = catalogue.get("families")
    if not isinstance(families, list):
        raise ValueError("catalogue.families must be a list")
    mutations: list[Mutation] = []
    for family_record in families:
        if not isinstance(family_record, dict) or family_record.get("risk") != "high":
            continue
        family = family_record.get("family")
        injections = family_record.get("fault_injections")
        if not isinstance(family, str) or not family:
            raise ValueError("high-risk family has no name")
        if not isinstance(injections, list) or not injections:
            raise ValueError(f"{family}: high-risk family has no fault_injections")
        for injection in injections:
            if not isinstance(injection, dict):
                raise ValueError(f"{family}: fault injection must be an object")
            values = {
                field: injection.get(field)
                for field in ("source", "needle", "replacement", "test")
            }
            if not all(isinstance(value, str) and value for value in values.values()):
                raise ValueError(f"{family}: fault injection has an empty field")
            occurrence = injection.get("occurrence", 1)
            if isinstance(occurrence, bool) or not isinstance(occurrence, int) or occurrence < 1:
                raise ValueError(f"{family}: occurrence must be a positive integer")
            mutations.append(
                Mutation(family=family, occurrence=occurrence, **values)
            )
    return mutations


def repository_file(root: Path, relative: str) -> Path:
    candidate = (root / relative).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError as exc:
        raise ValueError(f"path escapes repository: {relative}") from exc
    if not candidate.is_file():
        raise ValueError(f"missing file: {relative}")
    return candidate


def occurrence_offsets(source: str, needle: str) -> list[int]:
    offsets: list[int] = []
    start = 0
    while True:
        offset = source.find(needle, start)
        if offset < 0:
            return offsets
        offsets.append(offset)
        start = offset + len(needle)


def materialize_mutation(root: Path, destination: Path, mutation: Mutation) -> Path:
    """Copy only the mutated source file under destination, preserving root."""
    original = repository_file(root, mutation.source)
    source = original.read_text(encoding="utf-8-sig")
    offsets = occurrence_offsets(source, mutation.needle)
    if not offsets:
        raise ValueError(f"{mutation.family}: mutation needle does not occur")
    if len(offsets) < mutation.occurrence:
        raise ValueError(
            f"{mutation.family}: mutation needle only occurs {len(offsets)} times"
        )
    offset = offsets[mutation.occurrence - 1]
    changed = source[:offset] + mutation.replacement + source[offset + len(mutation.needle):]
    target = destination / mutation.source
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(changed, encoding="utf-8")
    return target


def executable_path(directory: Path, stem: str) -> Path:
    return directory / (stem + (".exe" if os.name == "nt" else ""))


def source_overlay_path(destination: Path) -> Path:
    """Return the unit-search directory containing a copied `src/` tree."""
    return destination / "src"


def run_command(command: list[str], cwd: Path, log_path: Path) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        cwd=cwd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    log_path.write_text(completed.stdout, encoding="utf-8")
    return completed


def fpcunit_failure_reported(output: str) -> bool:
    return bool(
        re.search(r"Number of (?:errors|failures):\s*[1-9][0-9]*", output)
    )


def run_mutation(
    root: Path, compiler: str, work_dir: Path, index: int, mutation: Mutation
) -> None:
    case_dir = work_dir / f"{index:02d}-{mutation.family}"
    source_dir = case_dir / "source"
    units = case_dir / "units"
    binaries = case_dir / "bin"
    for directory in (source_dir, units, binaries):
        directory.mkdir(parents=True, exist_ok=True)
    materialize_mutation(root, source_dir, mutation)

    compile_command = [
        compiler,
        "-B",
        "-FcUTF8",
        f"-Fu{source_overlay_path(source_dir).as_posix()}",
        f"-Fu{(root / 'src').as_posix()}",
        f"-FU{units.as_posix()}",
        f"-FE{binaries.as_posix()}",
        str(root / "tests" / "TestRunner.lpr"),
    ]
    compiled = run_command(compile_command, root, case_dir / "compile.log")
    if compiled.returncode != 0:
        raise RuntimeError(
            f"{mutation.family}: mutation did not compile; see {case_dir / 'compile.log'}"
        )
    tested = run_command(
        [str(executable_path(binaries, "TestRunner")), "-a", "--format=plain"],
        root,
        case_dir / "test.log",
    )
    if tested.returncode == 0:
        raise RuntimeError(
            f"{mutation.family}: mutation was not detected; see {case_dir / 'test.log'}"
        )
    if not fpcunit_failure_reported(tested.stdout):
        raise RuntimeError(
            f"{mutation.family}: test runner did not report a test failure; "
            f"see {case_dir / 'test.log'}"
        )


def load_catalogue(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise ValueError(f"invalid catalogue {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"invalid catalogue {path}: expected an object")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--catalogue",
        type=Path,
        default=ROOT / "docs" / "numerical-evidence-1.9.4.json",
    )
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument(
        "--work-dir", type=Path, default=Path("build-temp/numerical-mutation")
    )
    args = parser.parse_args()
    try:
        mutations = mutations_from_catalogue(load_catalogue(args.catalogue))
        if len(mutations) < 3:
            raise ValueError("at least three high-risk fault injections are required")
        work_dir = (ROOT / args.work_dir).resolve()
        for index, mutation in enumerate(mutations, start=1):
            repository_file(ROOT, mutation.test)
            run_mutation(ROOT, args.compiler, work_dir, index, mutation)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as exc:
        print(exc, file=sys.stderr)
        return 1
    print(f"Numerical mutation gate passed: {len(mutations)} faults detected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
