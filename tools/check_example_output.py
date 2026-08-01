#!/usr/bin/env python3
"""Run release-facing examples and verify documented output contracts."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def normalize(value: str) -> str:
    return "\n".join(line.rstrip() for line in value.splitlines()).strip()


def contract_error(contract: dict[str, object], observed: str) -> str | None:
    actual = normalize(observed)
    cursor = 0
    for required_value in contract["contains"]:
        required = str(required_value)
        position = actual.find(required, cursor)
        if position < 0:
            return f"missing ordered output fragment {required!r}"
        cursor = position + len(required)
    lines = actual.splitlines()
    final_line = str(contract["final_line"])
    if not lines or lines[-1] != final_line:
        observed_final = lines[-1] if lines else "<no output>"
        return f"final line is {observed_final!r}, expected {final_line!r}"
    return None


def load_contracts(path: Path) -> list[dict[str, object]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1 or not isinstance(data.get("examples"), list):
        raise ValueError(f"{path}: unsupported output-contract schema")
    contracts = data["examples"]
    seen: set[str] = set()
    for contract in contracts:
        if not isinstance(contract, dict):
            raise ValueError(f"{path}: every contract must be an object")
        example = contract.get("path")
        contains = contract.get("contains")
        final_line = contract.get("final_line")
        if (
            not isinstance(example, str)
            or not example.startswith("examples/")
            or not example.endswith(".pas")
            or not isinstance(contains, list)
            or not contains
            or not all(isinstance(item, str) and item for item in contains)
            or not isinstance(final_line, str)
            or not final_line
        ):
            raise ValueError(f"{path}: invalid contract {contract!r}")
        if example in seen or not (ROOT / example).is_file():
            raise ValueError(f"{path}: duplicate or missing example {example}")
        seen.add(example)
    return contracts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bin-dir", type=Path, default=Path("example-bin"))
    parser.add_argument(
        "--contracts", type=Path, default=Path("examples/output-contracts.json")
    )
    parser.add_argument("--run-timeout", type=int, default=30)
    args = parser.parse_args()

    try:
        contracts = load_contracts((ROOT / args.contracts).resolve())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(exc, file=sys.stderr)
        return 1
    binary_dir = (ROOT / args.bin_dir).resolve()
    suffix = ".exe" if sys.platform == "win32" else ""
    for contract in contracts:
        source = Path(str(contract["path"]))
        executable = binary_dir / (source.stem + suffix)
        if not executable.is_file():
            print(f"missing compiled example: {executable}", file=sys.stderr)
            return 1
        completed = subprocess.run(
            [str(executable)],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=args.run_timeout,
            check=False,
        )
        if completed.returncode != 0:
            print(
                f"{source}: exited with {completed.returncode}\n{completed.stdout}",
                file=sys.stderr,
            )
            return 1
        mismatch = contract_error(contract, completed.stdout)
        if mismatch is not None:
            print(
                f"{source}: {mismatch}\nObserved output:\n{completed.stdout}",
                file=sys.stderr,
            )
            return 1
    print(f"Example output checks passed: {len(contracts)} contracts verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
