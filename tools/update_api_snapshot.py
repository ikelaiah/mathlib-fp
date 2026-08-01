#!/usr/bin/env python3
"""Generate the owner- and signature-aware mathlib-fp 1.9 API contract."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "src"
OUTPUT = ROOT / "docs" / "public-api-1.9.json"
REFERENCE_OUTPUT = ROOT / "docs" / "API_REFERENCE_1.9.md"

CLASSIFICATIONS = {
    "primary",
    "compatibility",
    "deprecated",
    "experimental",
    "internal",
}

COMPATIBILITY_UNITS = {
    "FinanceLib.Bonds",
    "FinanceLib.NPV",
}

COMPATIBILITY_SYMBOLS = {
    "IMatrix",
    "TMatrixKit",
    "TMatrixKitSparse",
}

COMPATIBILITY_REPLACEMENTS = {
    "IMatrix": "IDenseDoubleMatrix",
    "TMatrixKit": "TDenseDoubleMatrix",
    "TMatrixKitSparse": "TSparseDoubleMatrix",
}

INTERNAL_SYMBOLS = {
    # Public only because FPC generic specializations need the declarations.
    # Applications should use the named scalar aliases and factory facades.
    "TBandFactor",
    "TDenseLinearOperator",
    "TDiagonalPreconditioner",
    "DenseInterfaceCast",
    "TIdentityPreconditioner",
    "ILinearOperator",
    "IMatrixFreeAction",
    "IPreconditioner",
    "ISparseLUFactor",
    "ISparseMatrix",
    "IStructuredDirectFactor",
    "IStructuredMatrix",
    "TILU0Preconditioner",
    "TIC0Preconditioner",
    "TIterativeSolver",
    "TIterativeWorkspace",
    "TIterativeVector",
    "TIterativeVectorList",
    "TLinearOperatorFactory",
    "TLinearScalar",
    "TLinearSolveResult",
    "TMatrixFreeLinearOperator",
    "TPartialEigenSolver",
    "TPreconditionerFactory",
    "TSparseFactorRow",
    "TSparseFactorRows",
    "TSparseLinearOperator",
    "TSparseLUFactor",
    "TSparseMatrixFactory",
    "TSparseMatrixStorage",
    "TSparseTriplet",
    "TSparseTripletArray",
    "TSparseTripletBuilder",
    "TSparseValueArray",
    "TSpectralVector",
    "TSpectralVectors",
    "TStructuredLinearOperator",
    "TStructuredMatrixFactory",
    "TStructuredMatrixStorage",
    "TStructuredSolverFactory",
    "TTridiagonalFactor",
}


@dataclass(frozen=True)
class Composite:
    name: str
    form: str
    start: int
    body_start: int
    end: int
    header: str


def interface_text(source: str) -> str:
    match = re.search(r"(?mi)^implementation\s*$", source)
    if not match:
        raise ValueError("unit has no implementation delimiter")
    text = source[: match.start()].replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(line.rstrip() for line in text.splitlines()) + "\n"


def strip_comments(source: str) -> str:
    """Remove Pascal comments without changing character offsets or newlines."""
    result = list(source)
    index = 0
    state = "code"
    while index < len(source):
        pair = source[index : index + 2]
        char = source[index]
        if state == "code":
            if char == "'":
                state = "string"
            elif pair == "//":
                result[index] = result[index + 1] = " "
                index += 1
                state = "line"
            elif pair == "(*":
                result[index] = result[index + 1] = " "
                index += 1
                state = "paren"
            elif char == "{":
                result[index] = " "
                state = "brace"
        elif state == "string":
            if char == "'":
                if index + 1 < len(source) and source[index + 1] == "'":
                    index += 1
                else:
                    state = "code"
        elif state == "line":
            if char == "\n":
                state = "code"
            else:
                result[index] = " "
        elif state == "paren":
            if pair == "*)":
                result[index] = result[index + 1] = " "
                index += 1
                state = "code"
            elif char != "\n":
                result[index] = " "
        elif state == "brace":
            if char == "}":
                result[index] = " "
                state = "code"
            elif char != "\n":
                result[index] = " "
        index += 1
    return "".join(result)


def normalize_signature(value: str) -> str:
    value = re.sub(r"\s+", " ", value.strip().rstrip(";"))
    value = re.sub(r"\s*([(),:;=\[\]])\s*", r"\1", value)
    return value


def find_composites(source: str) -> list[Composite]:
    header_pattern = re.compile(
        r"(?mi)^[ \t]*(?:generic\s+)?(?P<name>[A-Za-z_]\w*)"
        r"(?:\s*<[^;=\r\n]+>)?\s*=\s*"
        r"(?:(?:packed|bitpacked)\s+)?"
        r"(?P<form>class|record|interface|object)\b(?!\s+of\b)[^\r\n]*"
    )
    structural = re.compile(
        r"(?i)(?:=|:)\s*(?:(?:packed|bitpacked)\s+)?"
        r"(?:class|record|interface|object)\b(?!\s+of\b)|\bend\s*;"
    )
    composites: list[Composite] = []
    occupied_until = -1
    for match in header_pattern.finditer(source):
        if match.start() < occupied_until:
            continue
        if ";" in match.group():
            # Forward declarations and empty descendants are complete aliases,
            # not owner bodies with a matching `end`.
            continue
        depth = 1
        end = None
        for token in structural.finditer(source, match.end()):
            if re.match(r"(?i)\bend", token.group()):
                depth -= 1
                if depth == 0:
                    end = token.end()
                    break
            else:
                depth += 1
        if end is None:
            raise ValueError(f"unterminated public type {match.group('name')}")
        body_start = source.find("\n", match.end())
        if body_start < 0 or body_start > end:
            body_start = match.end()
        else:
            body_start += 1
        composites.append(
            Composite(
                name=match.group("name"),
                form=match.group("form").lower(),
                start=match.start(),
                body_start=body_start,
                end=end,
                header=normalize_signature(match.group()),
            )
        )
        occupied_until = end
    return composites


def classify(unit_name: str, name: str, owner: str | None) -> str:
    effective = owner or name
    if effective in INTERNAL_SYMBOLS or name in INTERNAL_SYMBOLS:
        return "internal"
    if (
        unit_name in COMPATIBILITY_UNITS
        or effective in COMPATIBILITY_SYMBOLS
        or name in COMPATIBILITY_SYMBOLS
    ):
        return "compatibility"
    return "primary"


def declaration(
    unit_name: str,
    owner: str | None,
    name: str,
    kind: str,
    signature: str,
) -> dict[str, str | None]:
    result: dict[str, str | None] = {
        "owner": owner,
        "name": name,
        "kind": kind,
        "signature": normalize_signature(signature),
        "classification": classify(unit_name, name, owner),
    }
    replacement = COMPATIBILITY_REPLACEMENTS.get(owner or name)
    if replacement:
        result["preferred_replacement"] = replacement
    return result


def split_statements(source: str) -> list[str]:
    statements: list[str] = []
    start = 0
    paren_depth = 0
    bracket_depth = 0
    in_string = False
    index = 0
    while index < len(source):
        char = source[index]
        if char == "'":
            if in_string and index + 1 < len(source) and source[index + 1] == "'":
                index += 2
                continue
            in_string = not in_string
        elif not in_string:
            if char == "(":
                paren_depth += 1
            elif char == ")":
                paren_depth = max(0, paren_depth - 1)
            elif char == "[":
                bracket_depth += 1
            elif char == "]":
                bracket_depth = max(0, bracket_depth - 1)
            elif char == ";" and paren_depth == 0 and bracket_depth == 0:
                statements.append(source[start:index])
                start = index + 1
        index += 1
    if source[start:].strip():
        statements.append(source[start:])
    return statements


CALLABLE_PATTERN = re.compile(
    r"(?is)^(?:(?:class|static)\s+)?(?:generic\s+)?"
    r"(?P<kind>constructor|destructor|procedure|function|operator)\s+"
    r"(?P<name>[A-Za-z_]\w*|:=|[+\-*/=<>]+)(?!\w)"
)


def member_declarations(
    unit_name: str, composite: Composite, source: str
) -> list[dict[str, str | None]]:
    body = source[composite.body_start : composite.end]
    visible = composite.form in {"record", "interface", "object"}
    visibility = visible
    filtered_lines: list[str] = []
    for line in body.splitlines():
        marker = re.match(
            r"^\s*(strict\s+private|strict\s+protected|private|protected|"
            r"public|published)\s*$",
            line,
            re.I,
        )
        if marker:
            visibility = marker.group(1).lower() in {"public", "published"}
            filtered_lines.append("")
        elif visibility:
            filtered_lines.append(line)
        else:
            filtered_lines.append("")

    result: list[dict[str, str | None]] = []
    subsection = "field"
    for raw_statement in split_statements("\n".join(filtered_lines)):
        statement = raw_statement.strip()
        if not statement:
            continue
        section = re.match(r"^(const|type|var|class\s+var)\b", statement, re.I)
        if section:
            subsection = section.group(1).lower()
            statement = statement[section.end() :].strip()
            if not statement:
                continue

        call = CALLABLE_PATTERN.match(statement)
        if call:
            result.append(
                declaration(
                    unit_name,
                    composite.name,
                    call.group("name"),
                    call.group("kind").lower(),
                    statement,
                )
            )
            continue

        prop = re.match(r"(?is)^property\s+([A-Za-z_]\w*)", statement)
        if prop:
            result.append(
                declaration(
                    unit_name,
                    composite.name,
                    prop.group(1),
                    "property",
                    statement,
                )
            )
            continue

        if subsection in {"const", "type"}:
            named = re.match(
                r"(?is)^(?:generic\s+)?([A-Za-z_]\w*)"
                r"(?:\s*<[^;=]+>)?\s*(?::[^=]+)?=",
                statement,
            )
            if named:
                result.append(
                    declaration(
                        unit_name,
                        composite.name,
                        named.group(1),
                        "nested-" + subsection,
                        statement,
                    )
                )
            continue

        field = re.match(
            r"(?is)^(?:class\s+var\s+)?"
            r"([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*(.+)$",
            statement,
        )
        if field:
            field_type = normalize_signature(field.group(2))
            for field_name in field.group(1).split(","):
                name = field_name.strip()
                result.append(
                    declaration(
                        unit_name,
                        composite.name,
                        name,
                        "field",
                        f"{name}: {field_type}",
                    )
                )
    return result


def top_level_declarations(
    unit_name: str, source: str, composites: list[Composite]
) -> list[dict[str, str | None]]:
    masked = list(source)
    for composite in composites:
        for index in range(composite.start, composite.end):
            if masked[index] not in {"\n", ";"}:
                masked[index] = " "

    result: list[dict[str, str | None]] = []
    section: str | None = None
    for raw_statement in split_statements("".join(masked)):
        statement = raw_statement.strip()
        if not statement:
            continue
        section_match = re.search(
            r"(?im)^[ \t]*(type|const|resourcestring|var|threadvar)"
            r"[ \t]*(?:\n|$)",
            statement,
        )
        if section_match:
            section = section_match.group(1).lower()
            statement = statement[section_match.end() :].strip()
        call = CALLABLE_PATTERN.match(statement)
        if call:
            section = None
            result.append(
                declaration(
                    unit_name,
                    None,
                    call.group("name"),
                    call.group("kind").lower(),
                    statement,
                )
            )
            continue
        if section == "type":
            named = re.match(
                r"(?is)^(?:generic\s+)?([A-Za-z_]\w*)"
                r"(?:\s*<[^;=]+>)?\s*=",
                statement,
            )
            if named:
                name = named.group(1)
                result.append(declaration(unit_name, None, name, "type", statement))
                rhs = statement[statement.find("=") + 1 :].strip()
                if rhs.startswith("(") and rhs.endswith(")"):
                    for item in split_statements(rhs[1:-1].replace(",", ";")):
                        enum_name = re.match(r"\s*([A-Za-z_]\w*)", item)
                        if enum_name:
                            value_name = enum_name.group(1)
                            result.append(
                                declaration(
                                    unit_name,
                                    name,
                                    value_name,
                                    "enum-value",
                                    item,
                                )
                            )
            continue
        if section in {"const", "resourcestring"}:
            named = re.match(
                r"(?is)^([A-Za-z_]\w*)\s*(?::[^=]+)?=", statement
            )
            if named:
                result.append(
                    declaration(
                        unit_name, None, named.group(1), "constant", statement
                    )
                )
            continue
        if section in {"var", "threadvar"}:
            fields = re.match(
                r"(?is)^([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:\s*(.+)$",
                statement,
            )
            if fields:
                value_type = normalize_signature(fields.group(2))
                for item in fields.group(1).split(","):
                    name = item.strip()
                    result.append(
                        declaration(
                            unit_name,
                            None,
                            name,
                            "variable",
                            f"{name}: {value_type}",
                        )
                    )
    return result


def extract_declarations(
    unit_name: str, public_source: str
) -> list[dict[str, str | None]]:
    source = strip_comments(public_source)
    composites = find_composites(source)
    result = top_level_declarations(unit_name, source, composites)
    for composite in composites:
        result.append(
            declaration(
                unit_name,
                None,
                composite.name,
                composite.form,
                composite.header,
            )
        )
        result.extend(member_declarations(unit_name, composite, source))

    unique: dict[tuple[str, str, str, str], dict[str, str | None]] = {}
    for item in result:
        key = (
            str(item["owner"] or "").casefold(),
            str(item["name"]).casefold(),
            str(item["kind"]).casefold(),
            str(item["signature"]).casefold(),
        )
        unique[key] = item
    return sorted(
        unique.values(),
        key=lambda item: (
            str(item["owner"] or "").casefold(),
            str(item["name"]).casefold(),
            str(item["kind"]).casefold(),
            str(item["signature"]).casefold(),
        ),
    )


def markdown_code(value: object) -> str:
    return "`" + str(value).replace("|", r"\|").replace("`", r"\`") + "`"


def write_reference(snapshot: dict[str, object]) -> None:
    units = snapshot["units"]
    assert isinstance(units, list)
    counts = {classification: 0 for classification in CLASSIFICATIONS}
    for unit in units:
        for item in unit["declarations"]:
            counts[item["classification"]] += 1

    lines = [
        "# 1.9 public API declaration reference",
        "",
        "This file is generated by `tools/update_api_snapshot.py` from every",
        "unit interface in `src/`. Do not edit it by hand. The canonical",
        "machine-readable contract is",
        "[`public-api-1.9.json`](public-api-1.9.json).",
        "",
        "A declaration is identified by unit, owner, kind, name, and normalized",
        "signature. Private/protected members are excluded; declarations marked",
        "`internal` remain listed because their interface presence affects",
        "generic specialization and the unit-interface hash.",
        "",
        "## Classification totals",
        "",
        "| Classification | Declarations |",
        "| --- | ---: |",
    ]
    for classification in sorted(CLASSIFICATIONS):
        lines.append(f"| `{classification}` | {counts[classification]} |")

    for unit in units:
        unit_name = unit["unit"]
        source = unit["source"]
        lines.extend(
            [
                "",
                f"## {unit_name}",
                "",
                f"Source: [`{source}`](../{source})  ",
                f"Interface SHA-256: `{unit['interface_sha256']}`",
                "",
                "| Owner | Kind | Name | Normalized signature | Classification | Preferred replacement |",
                "| --- | --- | --- | --- | --- | --- |",
            ]
        )
        for item in unit["declarations"]:
            owner = item["owner"] if item["owner"] is not None else "(unit)"
            replacement = item.get("preferred_replacement", "—")
            lines.append(
                "| "
                + " | ".join(
                    [
                        markdown_code(owner),
                        markdown_code(item["kind"]),
                        markdown_code(item["name"]),
                        markdown_code(item["signature"]),
                        markdown_code(item["classification"]),
                        markdown_code(replacement),
                    ]
                )
                + " |"
            )
    REFERENCE_OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    units = []
    declaration_count = 0
    for path in sorted(SOURCE.glob("*.pas"), key=lambda p: p.name.casefold()):
        raw = path.read_text(encoding="utf-8-sig")
        unit_match = re.search(r"(?mi)^\s*unit\s+([^;]+);", raw)
        if not unit_match:
            continue
        unit_name = unit_match.group(1).strip()
        public = interface_text(raw)
        unit_declarations = extract_declarations(unit_name, public)
        declaration_count += len(unit_declarations)
        units.append(
            {
                "unit": unit_name,
                "source": path.relative_to(ROOT).as_posix(),
                "classification": (
                    "compatibility"
                    if unit_name in COMPATIBILITY_UNITS
                    else "primary"
                ),
                "interface_sha256": hashlib.sha256(
                    public.encode("utf-8")
                ).hexdigest(),
                "declarations": unit_declarations,
            }
        )

    snapshot = {
        "schema_version": 2,
        "release": "1.9.0",
        "generated_by": "tools/update_api_snapshot.py",
        "identity": ["unit", "owner", "kind", "name", "signature"],
        "classification_notes": {
            "primary": "recommended stable 1.9 entry point",
            "compatibility": "maintained 1.x surface with a preferred typed replacement where applicable",
            "deprecated": "source-compatible but scheduled for replacement",
            "experimental": "not covered by the stable compatibility promise",
            "internal": "generic implementation support; use a named scalar facade",
        },
        "deprecations": [],
        "units": units,
    }
    OUTPUT.write_text(
        json.dumps(snapshot, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_reference(snapshot)
    print(
        f"Wrote {OUTPUT.relative_to(ROOT)} and "
        f"{REFERENCE_OUTPUT.relative_to(ROOT)} with {len(units)} units and "
        f"{declaration_count} owner/signature-aware declarations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
