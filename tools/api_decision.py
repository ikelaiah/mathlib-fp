#!/usr/bin/env python3
"""Shared validation and classification helpers for the 2.0 API decision."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Iterable


CLASSIFICATIONS = {
    "recommended",
    "advanced",
    "compatibility",
    "experimental",
    "implementation",
}

PLAIN_ALIAS_RE = re.compile(
    r"^[A-Za-z_]\w*=((?:[A-Za-z_]\w*\.)*[A-Za-z_]\w*)$"
)


def load_decision(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def selector_matches(
    unit_name: str,
    declaration: dict[str, object],
    selector: dict[str, object],
) -> bool:
    """Return whether a review selector covers one exact snapshot row."""
    if selector.get("unit") != unit_name:
        return False
    if "surface" in selector:
        surface = selector["surface"]
        if declaration.get("name") != surface and declaration.get("owner") != surface:
            return False
    if "name" in selector and declaration.get("name") != selector["name"]:
        return False
    if "owner" in selector and declaration.get("owner") != selector["owner"]:
        return False
    if "kind" in selector and declaration.get("kind") != selector["kind"]:
        return False
    signature_contains = selector.get("signature_contains")
    if signature_contains and signature_contains not in str(declaration.get("signature")):
        return False
    return True


def generic_surfaces(declarations: Iterable[dict[str, object]]) -> set[str]:
    """Find public generic scaffolding whose members inherit that status."""
    return {
        str(item["name"])
        for item in declarations
        if item.get("owner") is None
        and str(item.get("signature", "")).startswith("generic ")
    }


def common_path_selectors(decision: dict[str, object]) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for path in decision["common_paths"]:
        result.extend(path["selectors"])
    return result


def matching_compatibility_decisions(
    unit_name: str,
    declaration: dict[str, object],
    decision: dict[str, object],
) -> list[dict[str, object]]:
    return [
        item
        for item in decision["compatibility_decisions"]
        if selector_matches(unit_name, declaration, item["selector"])
    ]


def plain_alias_target(declaration: dict[str, object]) -> str | None:
    """Return the exact right-hand target for a plain compiler type alias."""
    if declaration.get("kind") != "type":
        return None
    match = PLAIN_ALIAS_RE.fullmatch(str(declaration.get("signature", "")))
    if not match or match.group(1).casefold() in {
        "class",
        "interface",
        "object",
        "record",
    }:
        return None
    return match.group(1)


def matching_alias_reviews(
    unit_name: str,
    declaration: dict[str, object],
    decision: dict[str, object],
) -> list[dict[str, object]]:
    """Return exact alias-review records selecting one snapshot row."""
    return [
        item
        for item in decision.get("alias_reviews", [])
        if selector_matches(unit_name, declaration, item["selector"])
    ]


def classify_declaration(
    unit_name: str,
    declaration: dict[str, object],
    decision: dict[str, object],
    implementation_surfaces: set[str],
) -> str:
    compatibility = matching_compatibility_decisions(
        unit_name, declaration, decision
    )
    if compatibility:
        return "compatibility"
    for selector in decision["experimental_selectors"]:
        if selector_matches(unit_name, declaration, selector):
            return "experimental"
    if (
        declaration.get("name") in implementation_surfaces
        or declaration.get("owner") in implementation_surfaces
    ):
        return "implementation"
    for selector in common_path_selectors(decision):
        if selector_matches(unit_name, declaration, selector):
            return "recommended"
    return "advanced"


def apply_decisions(
    unit_name: str,
    declarations: list[dict[str, object]],
    decision: dict[str, object],
) -> None:
    implementation_surfaces = generic_surfaces(declarations)
    for declaration in declarations:
        classification = classify_declaration(
            unit_name, declaration, decision, implementation_surfaces
        )
        declaration["classification"] = classification
        if classification != "compatibility":
            continue
        matches = matching_compatibility_decisions(
            unit_name, declaration, decision
        )
        if len(matches) != 1:
            raise ValueError(
                f"{unit_name}.{declaration.get('owner')}."
                f"{declaration.get('name')}: expected one compatibility decision, "
                f"found {len(matches)}"
            )
        compatibility = matches[0]
        declaration["compatibility_decision"] = compatibility["decision"]
        declaration["compatibility_note"] = compatibility["note"]
        replacement = compatibility.get("replacement")
        if replacement:
            declaration["preferred_replacement"] = replacement
