#!/usr/bin/env python3
"""Compile, run, and record the 1.9.8 representative-workflow qualification.

Each workflow is compiled with the repository's `src/` on the unit path and
executed from an isolated work directory that holds only a copy of its bundled
fixtures. Two runs of each workflow must produce byte-identical output and
export artifacts, proving deterministic behavior. The recorded evidence names
the exact compiler and platform that actually ran; it makes no claim about any
other platform.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

from workflow_qualification import (
    WorkflowContractError,
    load_manifest,
    validate_workflow_output,
)
from docs_layout import load_layout


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LAYOUT = load_layout(DOCS / "layout.json", DOCS)
DEFAULT_MANIFEST = LAYOUT.canonical_path("workflow-qualification-1.9.8.json")
assert DEFAULT_MANIFEST is not None


def executable_path(directory: Path, stem: str) -> Path:
    return directory / (stem + (".exe" if os.name == "nt" else ""))


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def run(
    command: list[str], *, cwd: Path, timeout: int = 300,
) -> str:
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
        raise WorkflowContractError(
            f"command failed ({completed.returncode}): {' '.join(command)}\n"
            f"{completed.stdout}"
        )
    return completed.stdout


def compile_workflow(compiler: str, source: Path, work: Path) -> Path:
    units = work / "units"
    binaries = work / "bin"
    units.mkdir(parents=True, exist_ok=True)
    binaries.mkdir(parents=True, exist_ok=True)
    run(
        [
            compiler, "-B", "-FcUTF8", f"-Fu{ROOT / 'src'}",
            f"-FU{units}", f"-FE{binaries}", str(source),
        ],
        cwd=work,
    )
    return executable_path(binaries, source.stem)


def copy_fixtures(workflow: dict[str, object], work: Path) -> None:
    for fixture in workflow["fixtures"]:
        source = ROOT / str(fixture)
        destination = work / str(fixture)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def export_digests(workflow: dict[str, object], work: Path) -> dict[str, object]:
    artifacts: dict[str, object] = {}
    for export in workflow["exports"]:
        artifact = work / str(export)
        if not artifact.is_file():
            raise WorkflowContractError(f"missing exported artifact: {artifact}")
        data = artifact.read_bytes()
        if not data:
            raise WorkflowContractError(f"exported artifact is empty: {artifact}")
        artifacts[str(export)] = {"bytes": len(data), "sha256": sha256_bytes(data)}
    return artifacts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", default="fpc")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--work-dir", type=Path, default=Path("build-temp/workflow-qualification")
    )
    parser.add_argument(
        "--result",
        type=Path,
        default=Path("build-temp/workflow-qualification/results.json"),
    )
    args = parser.parse_args()

    work = (ROOT / args.work_dir).resolve()
    result_path = (ROOT / args.result).resolve()
    try:
        compiler_version = run([args.compiler, "-iV"], cwd=ROOT, timeout=30).strip()
        if compiler_version != "3.2.2":
            raise WorkflowContractError(
                f"workflow qualification requires FPC 3.2.2, found {compiler_version}"
            )
        manifest = load_manifest(args.manifest.resolve(), ROOT)
        workflow_results: list[dict[str, object]] = []
        for workflow in manifest["workflows"]:
            workflow_work = work / str(workflow["id"])
            source = ROOT / str(workflow["source"])
            executable = compile_workflow(args.compiler, source, workflow_work)
            copy_fixtures(workflow, workflow_work)

            first_run = run([str(executable)], cwd=workflow_work, timeout=120)
            first_errors = validate_workflow_output(
                str(workflow["id"]), first_run, workflow
            )
            if first_errors:
                raise WorkflowContractError("\n".join(first_errors))
            first_exports = export_digests(workflow, workflow_work)

            second_run = run([str(executable)], cwd=workflow_work, timeout=120)
            second_errors = validate_workflow_output(
                str(workflow["id"]), second_run, workflow
            )
            if second_errors:
                raise WorkflowContractError("\n".join(second_errors))
            second_exports = export_digests(workflow, workflow_work)

            if first_run != second_run:
                raise WorkflowContractError(
                    f"{workflow['id']}: output is not reproducible across runs"
                )
            if first_exports != second_exports:
                raise WorkflowContractError(
                    f"{workflow['id']}: exported artifacts differ across runs"
                )

            workflow_results.append(
                {
                    "id": workflow["id"],
                    "source": workflow["source"],
                    "domains": workflow["domains"],
                    "success_marker": workflow["success_marker"],
                    "output_sha256": sha256_bytes(first_run.encode("utf-8")),
                    "exported_artifacts": first_exports,
                }
            )

        result = {
            "schema_version": 1,
            "release": "1.9.8",
            "platform": platform.platform(),
            "python": platform.python_version(),
            "compiler": args.compiler,
            "compiler_version": compiler_version,
            "workflows": workflow_results,
        }
        result_path.parent.mkdir(parents=True, exist_ok=True)
        result_path.write_text(
            json.dumps(result, indent=2) + "\n", encoding="utf-8"
        )
    except (
        WorkflowContractError,
        OSError,
        subprocess.TimeoutExpired,
        ValueError,
    ) as exc:
        print(exc, file=sys.stderr)
        return 1
    print(
        "Workflow qualification passed: "
        f"{len(manifest['workflows'])} workflows; results written to {result_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
