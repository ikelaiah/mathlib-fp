#!/usr/bin/env python3
"""Compile, run, and record the 1.9.7 migration rehearsal."""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import subprocess
import sys
from pathlib import Path

from migration_rehearsal import (
    MigrationContractError,
    load_manifest,
    validate_consumer_output,
    validate_package_boundary,
)


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = ROOT / "docs" / "migration-rehearsal-1.9.7.json"
PACKAGE = ROOT / "packages" / "lazarus" / "mathlib_fp.lpk"
ALIAS_CONSUMER = (
    ROOT / "examples" / "migration" / "package_boundary" / "alias_boundary.lpr"
)


def executable_path(directory: Path, stem: str) -> Path:
    return directory / (stem + (".exe" if os.name == "nt" else ""))


def run(command: list[str], *, cwd: Path = ROOT, timeout: int = 300) -> str:
    completed = subprocess.run(
        command,
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
        raise MigrationContractError(
            f"command failed ({completed.returncode}): {' '.join(command)}\n"
            f"{completed.stdout}"
        )
    return completed.stdout


def compile_consumer(
    compiler: str, source: Path, work: Path,
) -> tuple[Path, list[str], str]:
    units = work / "units"
    binaries = work / "bin"
    units.mkdir(parents=True, exist_ok=True)
    binaries.mkdir(parents=True, exist_ok=True)
    output = run(
        [
            compiler,
            "-B",
            "-FcUTF8",
            f"-Fu{ROOT / 'src'}",
            f"-FU{units}",
            f"-FE{binaries}",
            str(source),
        ]
    )
    warnings = [
        line.strip()
        for line in output.splitlines()
        if re.search(r"\bWarning:\s", line, re.IGNORECASE)
    ]
    return executable_path(binaries, source.stem), warnings, output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--work-dir", type=Path, default=Path("build-temp/migration-rehearsal")
    )
    parser.add_argument(
        "--result",
        type=Path,
        default=Path("build-temp/migration-rehearsal/results.json"),
    )
    args = parser.parse_args()

    work = (ROOT / args.work_dir).resolve()
    result_path = (ROOT / args.result).resolve()
    try:
        compiler_version = run([args.compiler, "-iV"], timeout=30).strip()
        if compiler_version != "3.2.2":
            raise MigrationContractError(
                f"migration rehearsal requires FPC 3.2.2, found {compiler_version}"
            )
        manifest = load_manifest(args.manifest.resolve(), ROOT)
        package_evidence = validate_package_boundary(PACKAGE)
        consumer_results = []
        for consumer in manifest["consumers"]:
            consumer_work = work / str(consumer["id"]).replace(".", "-")
            source = ROOT / consumer["source"]
            executable, warnings, compile_output = compile_consumer(
                args.compiler, source, consumer_work
            )
            if warnings != consumer["expected_warnings"]:
                raise MigrationContractError(
                    f"{consumer['id']}: compiler warnings differ; "
                    f"expected={consumer['expected_warnings']}, actual={warnings}"
                )
            output = run([str(executable)], timeout=120)
            validate_consumer_output(
                str(consumer["id"]), output, str(consumer["success_marker"])
            )
            consumer_results.append(
                {
                    "id": consumer["id"],
                    "source": consumer["source"],
                    "warnings": warnings,
                    "asserted_domains": len(manifest["domains"]),
                    "success_marker": consumer["success_marker"],
                    "compile_lines": len(compile_output.splitlines()),
                }
            )

        alias_executable, alias_warnings, _ = compile_consumer(
            args.compiler, ALIAS_CONSUMER, work / "alias-package-boundary"
        )
        if alias_warnings:
            raise MigrationContractError(
                f"alias package-boundary consumer emitted warnings: {alias_warnings}"
            )
        alias_output = run([str(alias_executable)], timeout=120)
        if "alias package boundary: success" not in alias_output:
            raise MigrationContractError(
                "alias package-boundary consumer omitted its success marker"
            )

        result = {
            "schema_version": 1,
            "release": "1.9.7",
            "platform": platform.platform(),
            "compiler": args.compiler,
            "compiler_version": compiler_version,
            "consumers": consumer_results,
            "package_boundary": package_evidence,
            "alias_decisions": [
                {
                    "name": decision["name"],
                    "decision": decision["decision"],
                    "tested_paths": decision["tested_paths"],
                }
                for decision in manifest["alias_decisions"]
            ],
        }
        result_path.parent.mkdir(parents=True, exist_ok=True)
        result_path.write_text(
            json.dumps(result, indent=2) + "\n", encoding="utf-8"
        )
    except (
        MigrationContractError,
        OSError,
        subprocess.TimeoutExpired,
        ValueError,
    ) as exc:
        print(exc, file=sys.stderr)
        return 1
    print(
        "Migration rehearsal passed: "
        f"{len(manifest['domains'])} domains, {len(manifest['alias_decisions'])} "
        f"alias decisions; results written to {result_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
