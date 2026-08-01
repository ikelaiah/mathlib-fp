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
    Path("docs/Interchange.md"),
    Path("docs/MIGRATING_TO_2.0_PREVIEW.md"),
    Path("docs/SparseLinearAlgebra.md"),
}


@dataclass(frozen=True)
class Fragment:
    path: Path
    line: int
    source: str


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


def program_source(fragment: Fragment, number: int) -> str:
    if re.search(r"(?mi)^\s*program\s+[A-Za-z_]\w*\s*;", fragment.source):
        return fragment.source
    return (
        f"program doc_fragment_{number:03d};\n\n"
        "{$mode objfpc}{$H+}{$J-}\n\n"
        + fragment.source
    )


def run_checked(command: list[str], description: str, timeout: int) -> None:
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
        run_checked(
            [str(executable)],
            f"{fragment.path}:{fragment.line} run",
            args.run_timeout,
        )

    print(
        f"Documentation example checks passed: {len(runnable)} compiled and "
        f"executed Pascal fragments ({len(fragments)} Pascal fences inventoried)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
