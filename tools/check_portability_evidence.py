#!/usr/bin/env python3
"""Compile, run, and validate the offline 1.9.6 portability evidence."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Mapping


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = ROOT / "docs" / "portability-evidence-1.9.6.json"
DEFAULT_WORK = ROOT / "build-temp" / "portability-evidence"
INTEGER_FIELDS = {
    "pointer_bits",
    "sizeint_bits",
    "single_bytes",
    "double_bytes",
    "extended_bytes",
}
TEXT_FIELDS = {
    "release",
    "target_os",
    "target_cpu",
    "compiler_version",
    "endian",
    "locale_guard",
    "numerical_checksum",
    "binary_fixture_hex",
}
PROBE_FIELDS = INTEGER_FIELDS | TEXT_FIELDS
AUDIT_CATEGORIES = {
    "filesystem",
    "locale",
    "endianness",
    "floating_point",
    "calling_convention",
    "address_space",
    "runtime_dependency",
}
SUPPORTED_TIERS = {"primary", "secondary"}


class EvidenceError(RuntimeError):
    """Raised when portability evidence violates the release contract."""


def _command(arguments: list[str], *, timeout: int = 900) -> str:
    completed = subprocess.run(
        arguments,
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
        raise EvidenceError(
            f"command failed with exit code {completed.returncode}: "
            f"{' '.join(arguments)}\n{completed.stdout}"
        )
    return completed.stdout


def parse_probe_output(output: str) -> dict[str, object]:
    """Parse the single canonical PORT row from a native probe."""
    rows = [line for line in output.splitlines() if line.startswith("PORT|")]
    if len(rows) != 1:
        raise EvidenceError(f"expected exactly one PORT row, found {len(rows)}")
    parsed: dict[str, object] = {}
    for field in rows[0].split("|")[1:]:
        if "=" not in field:
            raise EvidenceError(f"malformed probe field {field!r}")
        key, value = field.split("=", 1)
        if key in parsed:
            raise EvidenceError(f"duplicate key {key}")
        if key not in PROBE_FIELDS:
            raise EvidenceError(f"unknown probe key {key}")
        if not value:
            raise EvidenceError(f"probe field {key} must not be empty")
        if key in INTEGER_FIELDS:
            try:
                number = int(value)
            except ValueError as exc:
                raise EvidenceError(f"invalid integer {key}={value!r}") from exc
            if number <= 0:
                raise EvidenceError(f"probe field {key} must be positive")
            parsed[key] = number
        else:
            parsed[key] = value
    missing = sorted(PROBE_FIELDS - parsed.keys())
    if missing:
        raise EvidenceError(f"probe row missing keys {missing}")
    if not re.fullmatch(r"[0-9a-f]+", str(parsed["binary_fixture_hex"])):
        raise EvidenceError("binary_fixture_hex must be lowercase hexadecimal")
    if len(str(parsed["binary_fixture_hex"])) % 2:
        raise EvidenceError("binary_fixture_hex must contain complete bytes")
    return parsed


def _mapping(value: object, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise EvidenceError(f"{label} must be an object")
    return value


def _list(value: object, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise EvidenceError(f"{label} must be an array")
    return value


def _nonempty_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise EvidenceError(f"{label} is required")
    return value


def validate_manifest(manifest: dict[str, object]) -> dict[str, dict[str, Any]]:
    """Validate the target matrix without inferring missing coverage."""
    if manifest.get("schema_version") != 1:
        raise EvidenceError("manifest.schema_version must be 1")
    if manifest.get("release") != "1.9.6":
        raise EvidenceError("manifest.release must be 1.9.6")
    compiler = _mapping(manifest.get("compiler"), "manifest.compiler")
    _nonempty_string(compiler.get("name"), "manifest.compiler.name")
    _nonempty_string(compiler.get("version"), "manifest.compiler.version")
    audits = _list(manifest.get("required_audits"), "manifest.required_audits")
    if set(audits) != AUDIT_CATEGORIES or len(audits) != len(AUDIT_CATEGORIES):
        raise EvidenceError(
            "manifest.required_audits must name each portability audit exactly once"
        )
    invariants = _mapping(
        manifest.get("cross_target_invariants"),
        "manifest.cross_target_invariants",
    )
    for field in (
        "endian",
        "locale_guard",
        "numerical_checksum",
        "binary_fixture_hex",
    ):
        _nonempty_string(invariants.get(field), f"invariants.{field}")

    targets: dict[str, dict[str, Any]] = {}
    for index, raw_target in enumerate(_list(manifest.get("targets"), "targets")):
        target = _mapping(raw_target, f"targets[{index}]")
        identifier = _nonempty_string(target.get("id"), f"targets[{index}].id")
        if identifier in targets:
            raise EvidenceError(f"duplicate target id {identifier}")
        tier = target.get("tier")
        if tier not in SUPPORTED_TIERS | {"unqualified"}:
            raise EvidenceError(f"target {identifier}: invalid tier {tier!r}")
        target_os = _nonempty_string(target.get("target_os"), f"target {identifier}.target_os")
        target_cpu = _nonempty_string(target.get("target_cpu"), f"target {identifier}.target_cpu")
        if identifier != f"{target_os}-{target_cpu}":
            raise EvidenceError(
                f"target {identifier}: id must be {target_os}-{target_cpu}"
            )
        if tier == "unqualified":
            _nonempty_string(target.get("reason"), f"target {identifier}.reason")
            for forbidden in ("pointer_bits", "scalar_abi", "exact_checks", "evidence"):
                if forbidden in target:
                    raise EvidenceError(
                        f"target {identifier}: unqualified target must not infer {forbidden}"
                    )
        else:
            pointer_bits = target.get("pointer_bits")
            if pointer_bits not in (32, 64):
                raise EvidenceError(f"target {identifier}.pointer_bits must be 32 or 64")
            abi = _mapping(target.get("scalar_abi"), f"target {identifier}.scalar_abi")
            for scalar, allowed in (
                ("single_bytes", {4}),
                ("double_bytes", {8}),
                ("extended_bytes", {8, 10, 12, 16}),
            ):
                if abi.get(scalar) not in allowed:
                    raise EvidenceError(f"target {identifier}.{scalar} is invalid")
            checks = _list(target.get("exact_checks"), f"target {identifier}.exact_checks")
            if not checks or not all(isinstance(item, str) and item for item in checks):
                raise EvidenceError(f"target {identifier}.exact_checks must not be empty")
            if len(checks) != len(set(checks)):
                raise EvidenceError(f"target {identifier}.exact_checks contains duplicates")
            evidence = _mapping(target.get("evidence"), f"target {identifier}.evidence")
            date_text = _nonempty_string(
                evidence.get("last_successful_date"),
                f"target {identifier}.evidence.last_successful_date",
            )
            try:
                evidence_date = dt.date.fromisoformat(date_text)
            except ValueError as exc:
                raise EvidenceError(
                    f"target {identifier}: invalid evidence date {date_text!r}"
                ) from exc
            if evidence_date > dt.date.today():
                raise EvidenceError(f"target {identifier}: evidence date is in the future")
            _nonempty_string(evidence.get("ref"), f"target {identifier}.evidence.ref")
            if evidence.get("status") not in {"retained", "candidate"}:
                raise EvidenceError(f"target {identifier}: invalid evidence status")
            limitations = _list(target.get("limitations"), f"target {identifier}.limitations")
            if not all(isinstance(item, str) and item for item in limitations):
                raise EvidenceError(f"target {identifier}.limitations is invalid")
        targets[identifier] = target
    if not any(target["tier"] == "primary" for target in targets.values()):
        raise EvidenceError("manifest must define at least one primary target")
    if not any(target["tier"] == "unqualified" for target in targets.values()):
        raise EvidenceError("manifest must make at least one unqualified target explicit")
    return targets


def validate_evidence(
    manifest: dict[str, object], observations: dict[str, object]
) -> dict[str, object]:
    """Match native observations to exactly one supported target."""
    targets = validate_manifest(manifest)
    identifier = f"{observations['target_os']}-{observations['target_cpu']}"
    target = targets.get(identifier)
    if target is None:
        raise EvidenceError(f"native probe target {identifier} is absent from manifest")
    if target["tier"] == "unqualified":
        raise EvidenceError(f"native probe target {identifier} is unqualified")
    compiler = _mapping(manifest["compiler"], "manifest.compiler")
    expected: dict[str, object] = {
        "release": manifest["release"],
        "compiler_version": compiler["version"],
        "pointer_bits": target["pointer_bits"],
        "sizeint_bits": target["pointer_bits"],
        **_mapping(target["scalar_abi"], f"target {identifier}.scalar_abi"),
        **_mapping(
            manifest["cross_target_invariants"],
            "manifest.cross_target_invariants",
        ),
    }
    for field, value in expected.items():
        if observations.get(field) != value:
            raise EvidenceError(
                f"target {identifier}: {field}={observations.get(field)!r}; "
                f"expected {value!r}"
            )
    return {
        "status": "pass",
        "target_id": identifier,
        "tier": target["tier"],
        "required_profile": target["exact_checks"],
        "executed_checks": ["portability-probe-and-audit"],
        "observations": observations,
    }


def audit_source_texts(source_texts: Mapping[str, str]) -> list[str]:
    """Return hard dependency/calling-convention findings in stable sources."""
    findings: list[str] = []
    disallowed_units = (
        "dynlibs",
        "process",
        "fphttpclient",
        "httpsend",
        "winsock",
        "sockets",
    )
    uses_pattern = re.compile(r"\buses\b(?P<body>.*?);", re.IGNORECASE | re.DOTALL)
    for name, text in sorted(source_texts.items()):
        if re.search(
            r"(?:\{\$|\(\*\$)\s*(?:linklib|link|l|dynamiclib)\b",
            text,
            re.IGNORECASE,
        ):
            findings.append(f"runtime_dependency:{name}: link directive")
        if re.search(
            r"(?:\{\$|\(\*\$)\s*(?:i|include)\b", text, re.IGNORECASE
        ):
            findings.append(f"filesystem:{name}: include directive")
        code = _pascal_code_only(text)
        for match in uses_pattern.finditer(code):
            body = match.group("body")
            for unit in disallowed_units:
                if re.search(rf"\b{unit}\b", body, re.IGNORECASE):
                    findings.append(f"runtime_dependency:{name}: uses {unit}")
        if re.search(r"\bexternal\s*(?:;|name\b)", code, re.IGNORECASE):
            findings.append(f"runtime_dependency:{name}: external declaration")
        if re.search(
            r";\s*(?:cdecl|stdcall|safecall|winapi)\s*;", code, re.IGNORECASE
        ):
            findings.append(f"calling_convention:{name}: foreign convention")
    return findings


def _pascal_code_only(text: str) -> str:
    """Replace Pascal comments and strings with spaces while retaining layout."""
    output: list[str] = []
    index = 0
    state = "code"
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if state == "code":
            if char == "'":
                output.append(" ")
                state = "string"
            elif char == "{":
                output.append(" ")
                state = "brace"
            elif char == "(" and following == "*":
                output.extend((" ", " "))
                index += 1
                state = "paren"
            elif char == "/" and following == "/":
                output.extend((" ", " "))
                index += 1
                state = "line"
            else:
                output.append(char)
        elif state == "string":
            output.append("\n" if char == "\n" else " ")
            if char == "'":
                if following == "'":
                    output.append(" ")
                    index += 1
                else:
                    state = "code"
        elif state == "brace":
            output.append("\n" if char == "\n" else " ")
            if char == "}":
                state = "code"
        elif state == "paren":
            output.append("\n" if char == "\n" else " ")
            if char == "*" and following == ")":
                output.append(" ")
                index += 1
                state = "code"
        else:
            output.append("\n" if char == "\n" else " ")
            if char == "\n":
                state = "code"
        index += 1
    return "".join(output)


def audit_repository() -> dict[str, object]:
    source_texts = {
        path.relative_to(ROOT).as_posix(): path.read_text(
            encoding="utf-8-sig", errors="replace"
        )
        for path in sorted((ROOT / "src").glob("*.pas"))
    }
    findings = audit_source_texts(source_texts)
    package_path = ROOT / "packages" / "lazarus" / "mathlib_fp.lpk"
    package = ET.parse(package_path).getroot()
    package_dependencies = [
        element.attrib.get("Value", "")
        for element in package.findall(".//RequiredPkgs/Item/PackageName")
    ]
    if package_dependencies != ["FCL"]:
        findings.append(
            "runtime_dependency:packages/lazarus/mathlib_fp.lpk: "
            f"expected only FCL, found {package_dependencies}"
        )
    return {
        "status": "pass" if not findings else "fail",
        "source_units": len(source_texts),
        "package_dependencies": package_dependencies,
        "findings": findings,
        "categories": {
            "filesystem": "No stable source opens repository-relative or absolute files implicitly; stream APIs are caller-owned.",
            "locale": "Invariant interchange supplies explicit decimal settings; the native probe changes the process decimal separator.",
            "endianness": "Binary persistence writes and reads explicit little-endian fields instead of record layouts.",
            "floating_point": "The native probe records scalar sizes; the full numerical suite supplies tolerance and edge-case checks.",
            "calling_convention": "No stable source declaration uses a foreign calling convention or external symbol.",
            "address_space": "Typed storage uses SizeInt/SizeUInt and checked products; 32-bit tests exercise the secondary tier.",
            "runtime_dependency": "Stable sources do not load libraries, spawn processes, or import network units; the package requires only FCL.",
        },
    }


def compile_and_run(
    compiler: str, work: Path, flags: list[str]
) -> tuple[str, list[str]]:
    work.mkdir(parents=True, exist_ok=True)
    executable = work / ("PortabilityProbe.exe" if os.name == "nt" else "PortabilityProbe")
    command = [
        compiler,
        "-B",
        *flags,
        "-FcUTF8",
        f"-Fu{ROOT / 'src'}",
        f"-FU{work}",
        f"-FE{work}",
        str(ROOT / "tools" / "PortabilityProbe.lpr"),
    ]
    _command(command)
    return _command([str(executable)], timeout=120), command


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
    result_path = (args.result or work / "portability-results.json").resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(manifest, dict):
            raise EvidenceError("manifest root must be an object")
        validate_manifest(manifest)
        compiler_version = _command([args.compiler, "-iV"], timeout=30).strip()
        target_cpu = _command([args.compiler, "-iTP"], timeout=30).strip()
        target_os = _command([args.compiler, "-iTO"], timeout=30).strip()
        flags = manifest.get("compiler_flags")
        if not isinstance(flags, list) or not all(isinstance(item, str) for item in flags):
            raise EvidenceError("manifest.compiler_flags must be an array of strings")
        compile_command: list[str] | None = None
        if args.captured_output:
            output = args.captured_output.read_text(encoding="utf-8")
        else:
            output, compile_command = compile_and_run(args.compiler, work, flags)
            work.mkdir(parents=True, exist_ok=True)
            (work / "portability-output.log").write_text(output, encoding="utf-8")
        observations = parse_probe_output(output)
        if observations["compiler_version"] != compiler_version:
            raise EvidenceError("probe/compiler command version mismatch")
        if observations["target_cpu"] != target_cpu or observations["target_os"] != target_os:
            raise EvidenceError("probe/compiler command target mismatch")
        validated = validate_evidence(manifest, observations)
        audit = audit_repository()
        if audit["status"] != "pass":
            raise EvidenceError(f"source portability audit failed: {audit['findings']}")
        result = {
            "schema_version": 1,
            "release": "1.9.6",
            "evidence_date": dt.date.today().isoformat(),
            "manifest": manifest_path.relative_to(ROOT).as_posix()
            if manifest_path.is_relative_to(ROOT)
            else str(manifest_path),
            "compiler_flags": flags,
            "compile_command": compile_command,
            "compiler": {
                "command": args.compiler,
                "version": compiler_version,
                "target_os": target_os,
                "target_cpu": target_cpu,
            },
            "audit": audit,
            **validated,
        }
        result_path.parent.mkdir(parents=True, exist_ok=True)
        result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(
            f"Portability evidence passed for {result['target_id']} "
            f"({result['tier']}); results written to {result_path}"
        )
        return 0
    except (
        EvidenceError,
        OSError,
        ValueError,
        ET.ParseError,
        subprocess.TimeoutExpired,
    ) as exc:
        print(exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
