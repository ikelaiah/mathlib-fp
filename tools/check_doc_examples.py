#!/usr/bin/env python3
"""Compile and run every self-contained Pascal fragment published in the docs."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent

# These release-facing documents must never regress to an illustrative,
# compiler-opaque Pascal fence. Files without Pascal fences are harmless.
REQUIRED_RUNNABLE_DOCUMENTS = {
    Path("README.md"),
    Path("docs/API_CANDIDATE_2.0.md"),
    Path("docs/guides/domains/interchange.md"),
    Path("docs/guides/migration/to-2.0-preview.md"),
    Path("docs/guides/domains/sparse-linear-algebra.md"),
}

# One output-checked program is the mechanical beginner route for each stable
# domain. Algebra deliberately points to the primary typed-double guide rather
# than the compatibility landing-page example.
BEGINNER_ROUTE_DOCUMENTS = {
    "MathBase": Path("docs/guides/domains/math-base.md"),
    "AlgebraLib": Path("docs/guides/domains/typed-dense-matrices.md"),
    "FinanceLib": Path("docs/guides/domains/finance.md"),
    "StatsLib": Path("docs/guides/domains/statistics.md"),
    "EngineeringLib": Path("docs/guides/domains/engineering.md"),
    "NumericsLib": Path("docs/guides/domains/numerics.md"),
    "ProbabilityLib": Path("docs/guides/domains/probability.md"),
    "CombinatoricsLib": Path("docs/guides/domains/combinatorics.md"),
    "OptimizationLib": Path("docs/guides/domains/optimization.md"),
    "TimeSeriesLib": Path("docs/guides/domains/time-series.md"),
    "MLLib": Path("docs/guides/domains/machine-learning.md"),
    "InterchangeLib": Path("docs/guides/domains/interchange.md"),
    "GeometryLib": Path("docs/guides/domains/geometry.md"),
}


@dataclass(frozen=True)
class Fragment:
    path: Path
    line: int
    source: str
    expectation: "OutputExpectation | None" = None


@dataclass(frozen=True)
class OutputExpectation:
    mode: str
    line: int
    text: str


def output_expectation(text: str, offset: int, path: Path) -> OutputExpectation | None:
    tail = text[offset:]
    match = re.match(
        r"(?ms)\A\s*Expected output(?P<contains> contains)?:\s*\n"
        r"```(?:text|console)[ \t]*\n(?P<output>.*?)^```[ \t]*$",
        tail,
    )
    if match is None:
        return None
    return OutputExpectation(
        mode="contains" if match.group("contains") else "exact",
        line=text.count("\n", 0, offset + match.start()) + 1,
        text=match.group("output").rstrip() + "\n",
    )


def pascal_fragments(root: Path) -> list[Fragment]:
    documents = [root / "README.md", *sorted((root / "docs").rglob("*.md"))]
    result: list[Fragment] = []
    pattern = re.compile(
        r"(?ms)^```pascal[ \t]*\n(?P<source>.*?)^```[ \t]*$"
    )
    for path in documents:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            result.append(
                Fragment(
                    path=path.relative_to(root),
                    line=text.count("\n", 0, match.start()) + 1,
                    source=match.group("source").rstrip() + "\n",
                    expectation=output_expectation(
                        text, match.end(), path.relative_to(root)
                    ),
                )
            )
    return result


def is_runnable(fragment: Fragment) -> bool:
    source = fragment.source
    return bool(
        re.search(r"(?mi)^\s*program\s+[A-Za-z_]\w*\s*;", source)
        or (
            re.search(r"(?mi)^\s*uses\b", source)
            and re.search(r"(?mi)^\s*begin\s*$", source)
            and re.search(r"(?is)\bend\s*\.\s*$", source)
        )
    )


def missing_beginner_routes(fragments: list[Fragment]) -> list[str]:
    runnable_with_output = {
        fragment.path
        for fragment in fragments
        if is_runnable(fragment) and fragment.expectation is not None
    }
    return [
        f"{domain}: {path} has no output-checked runnable program"
        for domain, path in BEGINNER_ROUTE_DOCUMENTS.items()
        if path not in runnable_with_output
    ]


def program_source(fragment: Fragment, number: int) -> str:
    if re.search(r"(?mi)^\s*program\s+[A-Za-z_]\w*\s*;", fragment.source):
        return fragment.source
    return (
        f"program doc_fragment_{number:03d};\n\n"
        "{$mode objfpc}{$H+}{$J-}\n\n"
        + fragment.source
    )


def run_checked(command: list[str], description: str, timeout: int) -> str:
    completed = subprocess.run(
        command,
        cwd=ROOT,
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
        raise RuntimeError(
            f"{description} failed with exit code {completed.returncode}\n"
            f"{completed.stdout}"
        )
    return completed.stdout


def normalized_output(value: str) -> str:
    return "\n".join(line.rstrip() for line in value.splitlines()).strip()


def expectation_error(expectation: OutputExpectation, observed: str) -> str | None:
    expected = normalized_output(expectation.text)
    actual = normalized_output(observed)
    if expectation.mode == "exact":
        if actual != expected:
            return f"expected exact output:\n{expected}\nobserved:\n{actual}"
        return None
    if expectation.mode != "contains":
        return f"unknown output expectation mode {expectation.mode!r}"
    cursor = 0
    for required in expected.splitlines():
        position = actual.find(required, cursor)
        if position < 0:
            return (
                f"expected output fragment not found in order: {required!r}\n"
                f"observed:\n{actual}"
            )
        cursor = position + len(required)
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument(
        "--work-dir", type=Path, default=Path("build-temp/doc-examples")
    )
    parser.add_argument("--compile-timeout", type=int, default=120)
    parser.add_argument("--run-timeout", type=int, default=30)
    args = parser.parse_args()

    fragments = pascal_fragments(ROOT)
    runnable = [fragment for fragment in fragments if is_runnable(fragment)]
    missing_routes = missing_beginner_routes(fragments)
    if missing_routes:
        print("\n".join(missing_routes), file=sys.stderr)
        return 1
    opaque_required = sorted(
        (
            fragment
            for fragment in fragments
            if fragment.path in REQUIRED_RUNNABLE_DOCUMENTS
            and not is_runnable(fragment)
        ),
        key=lambda fragment: (str(fragment.path), fragment.line),
    )
    if opaque_required:
        for fragment in opaque_required:
            print(
                f"{fragment.path}:{fragment.line}: release-facing Pascal fence "
                "is not self-contained",
                file=sys.stderr,
            )
        return 1

    missing_output_contracts = [
        fragment for fragment in runnable
        if re.search(r"(?i)\bWrite(?:Ln)?\s*\(", fragment.source)
        and fragment.expectation is None
    ]
    if missing_output_contracts:
        for fragment in missing_output_contracts:
            print(
                f"{fragment.path}:{fragment.line}: runnable output-producing "
                "Pascal fence needs an adjacent 'Expected output:' or "
                "'Expected output contains:' text fence",
                file=sys.stderr,
            )
        return 1

    work = (ROOT / args.work_dir).resolve()
    sources = work / "sources"
    units = work / "units"
    binaries = work / "bin"
    for directory in (sources, units, binaries):
        directory.mkdir(parents=True, exist_ok=True)

    for number, fragment in enumerate(runnable, start=1):
        stem = f"doc_fragment_{number:03d}"
        source_path = sources / f"{stem}.pas"
        source_path.write_text(program_source(fragment, number), encoding="utf-8")
        executable = binaries / (stem + (".exe" if sys.platform == "win32" else ""))
        run_checked(
            [
                args.compiler,
                "-Mobjfpc",
                "-Sh",
                f"-Fu{ROOT / 'src'}",
                f"-FU{units}",
                f"-o{executable}",
                str(source_path),
            ],
            f"{fragment.path}:{fragment.line} compile",
            args.compile_timeout,
        )
        observed = run_checked(
            [str(executable)],
            f"{fragment.path}:{fragment.line} run",
            args.run_timeout,
        )
        if fragment.expectation is not None:
            mismatch = expectation_error(fragment.expectation, observed)
            if mismatch is not None:
                print(
                    f"{fragment.path}:{fragment.expectation.line}: {mismatch}",
                    file=sys.stderr,
                )
                return 1

    expectation_count = sum(
        fragment.expectation is not None for fragment in runnable
    )
    print(
        f"Documentation example checks passed: {len(runnable)} compiled and "
        f"executed Pascal fragments, {expectation_count} output contracts "
        f"verified, {len(BEGINNER_ROUTE_DOCUMENTS)} beginner routes covered "
        f"({len(fragments)} Pascal fences inventoried)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
