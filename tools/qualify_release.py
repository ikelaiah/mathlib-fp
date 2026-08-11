#!/usr/bin/env python3
"""Run the release gates from an extracted, network-independent source tree."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
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
        self.context: dict[str, object] = {}

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
                    "qualification_context": self.context,
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


def verify_archive_checksum(archive: Path, checksum: Path) -> str:
    try:
        fields = checksum.read_text(encoding="ascii").strip().split()
    except OSError as exc:
        raise RuntimeError(f"cannot read archive checksum {checksum}: {exc}") from exc
    if len(fields) != 2 or not re.fullmatch(r"[0-9a-fA-F]{64}", fields[0]):
        raise RuntimeError(f"invalid SHA-256 checksum file {checksum}")
    if Path(fields[1].lstrip("*")).name != archive.name:
        raise RuntimeError(
            f"checksum names {fields[1]!r}, expected archive {archive.name!r}"
        )
    actual = hashlib.sha256(archive.read_bytes()).hexdigest()
    if actual.lower() != fields[0].lower():
        raise RuntimeError(
            f"archive checksum mismatch: expected {fields[0].lower()}, found {actual}"
        )
    return actual


def _safe_archive_files(archive: Path) -> set[str]:
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as bundle:
            names = [item.filename for item in bundle.infolist() if not item.is_dir()]
    elif tarfile.is_tarfile(archive):
        with tarfile.open(archive, "r:*") as bundle:
            names = [item.name for item in bundle.getmembers() if item.isfile()]
    else:
        raise RuntimeError(f"unsupported source archive format: {archive}")
    normalized: set[str] = set()
    for raw_name in names:
        name = raw_name.replace("\\", "/")
        parts = Path(name).parts
        if name.startswith("/") or ".." in parts or not name:
            raise RuntimeError(f"unsafe archive member {raw_name!r}")
        normalized.add(name)
    return normalized


def verify_clean_source_archive(
    root: Path, archive: Path, checksum: Path
) -> dict[str, object]:
    """Verify a source archive and its already-extracted clean tree."""
    digest = verify_archive_checksum(archive, checksum)
    archive_files = _safe_archive_files(archive)
    required_files = {"README.md", "LICENSE.md", "RELEASING.md"}
    missing_files = sorted(required_files - archive_files)
    required_prefixes = ("src/", "docs/", "examples/", "tests/", "tools/", "packages/")
    missing_prefixes = [
        prefix for prefix in required_prefixes
        if not any(name.startswith(prefix) for name in archive_files)
    ]
    if missing_files or missing_prefixes:
        raise RuntimeError(
            f"source archive is incomplete: files={missing_files}, prefixes={missing_prefixes}"
        )
    if (root / ".git").exists():
        raise RuntimeError("clean source tree contains repository-local .git state")
    forbidden_suffixes = {".o", ".ppu", ".exe", ".dll", ".so", ".dylib", ".compiled"}
    compiler_outputs = sorted(
        name for name in archive_files if Path(name).suffix.lower() in forbidden_suffixes
    )
    if compiler_outputs:
        raise RuntimeError(f"source archive contains compiler output: {compiler_outputs}")
    extracted_files = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file()
    }
    if extracted_files != archive_files:
        missing = sorted(archive_files - extracted_files)[:10]
        extra = sorted(extracted_files - archive_files)[:10]
        raise RuntimeError(
            f"extracted source tree differs from archive: missing={missing}, extra={extra}"
        )
    return {
        "archive": archive.name,
        "sha256": digest,
        "files": len(archive_files),
        "clean_tree": True,
    }


def verify_offline_documentation_archive(
    archive: Path, checksum: Path, extraction: Path, release: str
) -> Path:
    """Verify and extract the generated offline HTML archive safely."""
    verify_archive_checksum(archive, checksum)
    prefix = f"mathlib-fp-docs-{release}/"
    with zipfile.ZipFile(archive) as bundle:
        files = [item.filename for item in bundle.infolist() if not item.is_dir()]
        required = {
            prefix + "index.html",
            prefix + "release.json",
            prefix + "search-index.json",
        }
        if not required.issubset(files):
            raise RuntimeError(
                f"offline documentation archive is missing {sorted(required - set(files))}"
            )
        for name in files:
            normalized = name.replace("\\", "/")
            if not normalized.startswith(prefix) or ".." in Path(normalized).parts:
                raise RuntimeError(f"unsafe offline documentation member {name!r}")
        if extraction.exists():
            shutil.rmtree(extraction)
        extraction.mkdir(parents=True)
        bundle.extractall(extraction)
    return extraction / prefix.rstrip("/")


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
        "test_release_state.py",
        "test_numerical_evidence.py",
        "test_numerical_mutation.py",
        "test_performance_evidence.py",
        "test_portability_evidence.py",
        "check_docs.py",
        "check_api_decision.py",
        "check_numerical_evidence.py",
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
    qualification.run(
        "numerical-mutation",
        [
            sys.executable, str(ROOT / "tools" / "run_numerical_mutation.py"),
            "--compiler", compiler,
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
    extracted_site = verify_offline_documentation_archive(
        archive,
        archive.with_name(archive.name + ".sha256"),
        qualification.work / "offline-docs-extracted",
        release,
    )
    qualification.run(
        "documentation-offline-archive-links",
        [
            sys.executable, str(ROOT / "tools" / "check_built_docs.py"),
            "--site", str(extracted_site), "--release", release,
        ],
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
            f"-Fu{ROOT / 'benchmarks'}",
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
    qualification.run(
        "benchmark-validate",
        [
            sys.executable,
            str(ROOT / "tools" / "check_performance_evidence.py"),
            "--compiler", compiler,
            "--captured-output", str(qualification.logs / "benchmark-run.log"),
            "--work-dir", str(directory),
            "--result", str(qualification.work / "performance-results.json"),
        ],
    )


def portability_gate(
    qualification: Qualification, compiler: str,
) -> None:
    qualification.run(
        "portability-evidence",
        [
            sys.executable,
            str(ROOT / "tools" / "check_portability_evidence.py"),
            "--compiler", compiler,
            "--work-dir", str(qualification.work / "portability"),
            "--result", str(qualification.work / "portability-results.json"),
        ],
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
    parser.add_argument("--source-archive", type=Path)
    parser.add_argument("--source-checksum", type=Path)
    parser.add_argument("--network-isolated", action="store_true")
    args = parser.parse_args()

    work = (ROOT / args.work_dir).resolve()
    result = (ROOT / args.result).resolve()
    qualification = Qualification(work, result)
    compiler_version = "unknown"
    try:
        if bool(args.source_archive) != bool(args.source_checksum):
            raise RuntimeError(
                "--source-archive and --source-checksum must be supplied together"
            )
        if args.source_archive:
            if not args.network_isolated:
                raise RuntimeError(
                    "clean source archive qualification requires --network-isolated"
                )
            archive_evidence = verify_clean_source_archive(
                ROOT,
                args.source_archive.resolve(),
                args.source_checksum.resolve(),
            )
            qualification.context["source_archive"] = archive_evidence
        qualification.context["network_isolated"] = args.network_isolated
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
        portability_gate(qualification, args.compiler)
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
