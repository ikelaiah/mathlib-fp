#!/usr/bin/env python3
"""Run the release gates from an extracted, network-independent source tree."""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import subprocess
import sys
import time
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def executable_path(directory: Path, stem: str) -> Path:
    return directory / (stem + (".exe" if os.name == "nt" else ""))


class Qualification:
    def __init__(self, work: Path, result_path: Path) -> None:
        self.work = work
        self.result_path = result_path
        self.logs = work / "logs"
        self.logs.mkdir(parents=True, exist_ok=True)
        self.results: list[dict[str, object]] = []

    def write_results(self, release: str, compiler: str) -> None:
        self.result_path.parent.mkdir(parents=True, exist_ok=True)
        self.result_path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "release": release,
                    "platform": platform.platform(),
                    "python": platform.python_version(),
                    "compiler": compiler,
                    "gates": self.results,
                },
                indent=2,
            ) + "\n",
            encoding="utf-8",
        )

    def run(
        self, name: str, command: list[str], timeout: int = 600,
        cwd: Path = ROOT, env: dict[str, str] | None = None,
    ) -> str:
        started = time.monotonic()
        environment = os.environ.copy()
        if env:
            environment.update(env)
        completed = subprocess.run(
            command,
            cwd=cwd,
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
        elapsed = round(time.monotonic() - started, 3)
        log_name = name.replace("/", "-").replace(" ", "-") + ".log"
        log_path = self.logs / log_name
        log_path.write_text(completed.stdout, encoding="utf-8")
        self.results.append(
            {
                "name": name,
                "status": "passed" if completed.returncode == 0 else "failed",
                "seconds": elapsed,
                "log": log_path.relative_to(self.work).as_posix(),
            }
        )
        if completed.returncode != 0:
            raise RuntimeError(
                f"{name} failed with exit code {completed.returncode}\n"
                f"{completed.stdout}"
            )
        return completed.stdout


def verify_test_output(name: str, output: str) -> None:
    required = ("Number of run tests:", "Number of errors:    0", "Number of failures:  0")
    missing = [item for item in required if item not in output]
    if missing:
        raise RuntimeError(f"{name}: test summary is missing {missing}")


def output_tail(output: str, limit: int = 12000) -> str:
    if len(output) <= limit:
        return output
    return "[... earlier output omitted ...]\n" + output[-limit:]


def verify_heaptrc_output(output: str) -> None:
    summaries = re.findall(
        r"(?im)^\s*(\d+)\s+unfreed\s+memory\s+blocks\s*:\s*(\d+)\s*$",
        output,
    )
    if not summaries:
        raise RuntimeError(
            "checked-heap: heaptrc produced no unfreed-block summary\n"
            f"Captured heaptrc output:\n{output_tail(output)}"
        )
    nonzero = [
        (int(blocks), int(size))
        for blocks, size in summaries
        if int(blocks) != 0 or int(size) != 0
    ]
    if nonzero:
        blocks, size = nonzero[-1]
        raise RuntimeError(
            f"checked-heap: heaptrc reported {blocks} unfreed blocks "
            f"({size} bytes)\nCaptured heaptrc output:\n{output_tail(output)}"
        )


def compile_and_run_tests(
    qualification: Qualification, compiler: str, label: str, flags: list[str],
) -> None:
    directory = qualification.work / "tests" / label
    units = directory / "units"
    binaries = directory / "bin"
    units.mkdir(parents=True, exist_ok=True)
    binaries.mkdir(parents=True, exist_ok=True)
    qualification.run(
        f"tests-{label}-compile",
        [
            compiler, "-B", *flags, "-FcUTF8", f"-Fu{ROOT / 'src'}",
            f"-FU{units}", f"-FE{binaries}", str(ROOT / "tests" / "TestRunner.lpr"),
        ],
    )
    run_name = f"tests-{label}-run"
    heap_log = directory / "heaptrc.log"
    run_env = None
    if label == "checked-heap":
        heap_log.unlink(missing_ok=True)
        run_env = {"HEAPTRC": f"log={heap_log}"}
    output = qualification.run(
        run_name,
        [str(executable_path(binaries, "TestRunner")), "-a", "--format=plain"],
        env=run_env,
    )
    try:
        verify_test_output(label, output)
        if label == "checked-heap":
            try:
                heap_output = heap_log.read_text(
                    encoding="utf-8", errors="replace"
                )
            except OSError as exc:
                raise RuntimeError(
                    f"checked-heap: cannot read heaptrc log {heap_log}: {exc}\n"
                    f"Captured test output:\n{output_tail(output)}"
                ) from exc
            verify_heaptrc_output(heap_output)
    except RuntimeError:
        qualification.results[-1]["status"] = "failed"
        raise


def build_and_run_examples(
    qualification: Qualification, compiler: str,
) -> None:
    directory = qualification.work / "examples"
    units = directory / "units"
    binaries = directory / "bin"
    units.mkdir(parents=True, exist_ok=True)
    binaries.mkdir(parents=True, exist_ok=True)
    for source in sorted((ROOT / "examples").glob("*.pas")):
        qualification.run(
            f"example-{source.stem}-compile",
            [
                compiler, "-B", "-FcUTF8", f"-Fu{ROOT / 'src'}",
                f"-FU{units}", f"-FE{binaries}", str(source),
            ],
        )
        qualification.run(
            f"example-{source.stem}-run",
            [str(executable_path(binaries, source.stem))],
            timeout=120,
        )
    qualification.run(
        "example-output-contracts",
        [
            sys.executable, str(ROOT / "tools" / "check_example_output.py"),
            "--bin-dir", str(binaries),
        ],
    )


def documentation_gates(
    qualification: Qualification, compiler: str, release: str,
) -> None:
    for script in (
        "test_api_decision.py",
        "test_api_snapshot.py",
        "test_doc_examples.py",
        "test_example_output.py",
        "test_build_docs.py",
        "test_built_docs.py",
        "check_docs.py",
        "check_api_decision.py",
    ):
        qualification.run(
            script.removesuffix(".py"),
            [sys.executable, str(ROOT / "tools" / script)],
        )
    qualification.run(
        "documentation-execution",
        [
            sys.executable, str(ROOT / "tools" / "check_doc_examples.py"),
            "--compiler", compiler,
            "--work-dir", str(qualification.work / "doc-examples"),
        ],
    )
    site = qualification.work / "docs-site" / release
    archive = qualification.work / f"mathlib-fp-docs-{release}.zip"
    qualification.run(
        "documentation-build",
        [
            sys.executable, str(ROOT / "tools" / "build_docs.py"),
            "--release", release,
            "--output", str(site),
            "--offline-archive", str(archive),
        ],
    )
    qualification.run(
        "documentation-built-links",
        [
            sys.executable, str(ROOT / "tools" / "check_built_docs.py"),
            "--site", str(site), "--release", release,
        ],
    )
    with zipfile.ZipFile(archive) as bundle:
        names = set(bundle.namelist())
        prefix = f"mathlib-fp-docs-{release}/"
        required = {
            prefix + "index.html",
            prefix + "release.json",
            prefix + "search-index.json",
        }
        if not required.issubset(names):
            qualification.results[-1]["status"] = "failed"
            raise RuntimeError(
                f"offline documentation archive is missing {sorted(required - names)}"
            )


def package_gate(
    qualification: Qualification, lazbuild: str,
) -> None:
    profile = qualification.work / "lazarus-profile"
    profile.mkdir(parents=True, exist_ok=True)
    qualification.run(
        "lazarus-package",
        [
            lazbuild, f"--pcp={profile}", "--build-all",
            str(ROOT / "packages" / "lazarus" / "mathlib_fp.lpk"),
        ],
        timeout=900,
    )


def benchmark_gate(
    qualification: Qualification, compiler: str,
) -> None:
    directory = qualification.work / "benchmark"
    directory.mkdir(parents=True, exist_ok=True)
    qualification.run(
        "benchmark-compile",
        [
            compiler, "-B", "-O3", "-FcUTF8", f"-Fu{ROOT / 'src'}",
            f"-FU{directory}", f"-FE{directory}",
            str(ROOT / "benchmarks" / "BenchmarkRunner.lpr"),
        ],
        timeout=900,
    )
    qualification.run(
        "benchmark-run",
        [str(executable_path(directory, "BenchmarkRunner"))],
        timeout=1800,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--release", required=True)
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument("--lazbuild", default="lazbuild")
    parser.add_argument(
        "--work-dir", type=Path, default=Path("build-temp/release-qualification")
    )
    parser.add_argument(
        "--result", type=Path,
        default=Path("build-temp/release-qualification/results.json"),
    )
    parser.add_argument("--skip-package", action="store_true")
    parser.add_argument("--skip-benchmark", action="store_true")
    args = parser.parse_args()

    work = (ROOT / args.work_dir).resolve()
    result = (ROOT / args.result).resolve()
    qualification = Qualification(work, result)
    compiler_version = "unknown"
    try:
        compiler_version = qualification.run(
            "compiler-version", [args.compiler, "-iV"], timeout=30
        ).strip()
        if compiler_version != "3.2.2":
            qualification.results[-1]["status"] = "failed"
            raise RuntimeError(
                f"release qualification requires FPC 3.2.2, found {compiler_version}"
            )
        qualification.run(
            "test-qualify-release",
            [sys.executable, str(ROOT / "tools" / "test_qualify_release.py")],
        )
        compile_and_run_tests(qualification, args.compiler, "normal", [])
        compile_and_run_tests(
            qualification, args.compiler, "optimized", ["-O3"]
        )
        compile_and_run_tests(
            qualification, args.compiler, "checked-heap",
            ["-Ci", "-Cr", "-Co", "-Ct", "-Sa", "-gl", "-gh"],
        )
        build_and_run_examples(qualification, args.compiler)
        documentation_gates(qualification, args.compiler, args.release)
        if not args.skip_package:
            package_gate(qualification, args.lazbuild)
        if not args.skip_benchmark:
            benchmark_gate(qualification, args.compiler)
    except (OSError, RuntimeError, subprocess.TimeoutExpired, ValueError) as exc:
        qualification.write_results(args.release, compiler_version)
        print(exc, file=sys.stderr)
        return 1
    qualification.write_results(args.release, compiler_version)
    print(
        f"Release qualification passed: {len(qualification.results)} gates; "
        f"results written to {result}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
