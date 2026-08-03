#!/usr/bin/env python3
"""Verify the complete, exact, all-domain 2.0 API decision."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

from api_decision import (
    CLASSIFICATIONS,
    classify_declaration,
    common_path_selectors,
    generic_surfaces,
    matching_alias_reviews,
    matching_compatibility_decisions,
    plain_alias_target,
    selector_matches,
)
from check_doc_examples import is_runnable, pascal_fragments


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
DECISION_RELEASE = "1.9.3"
API_BASELINE_RELEASE = "1.9.0"
REQUIRED_DIFF_CATEGORIES = {
    "source",
    "behaviour",
    "warnings",
    "packaging",
    "documentary_defaults",
}
ALIAS_EQUIVALENCE_FIELDS = {
    "behavior",
    "defaults",
    "ownership",
    "exception_identity",
    "numerical_results",
}


def load_json(path: Path, errors: list[str]) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(value, dict):
            raise ValueError("top level is not an object")
        return value
    except (OSError, ValueError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        return {}


def check_alias_reviews(
    decision: dict[str, object],
    declarations: list[tuple[str, dict[str, object]]],
    symbols: set[str],
    errors: list[str],
) -> None:
    """Require one review-only decision for every exact compiler type alias."""
    profiles = decision.get("alias_equivalence_profiles", {})
    if not isinstance(profiles, dict) or not profiles:
        errors.append("alias equivalence profiles are missing")
        profiles = {}
    for profile_id, profile in profiles.items():
        if not isinstance(profile, dict):
            errors.append(f"alias profile {profile_id}: expected an object")
            continue
        fields = set(profile) - {"basis"}
        if fields != ALIAS_EQUIVALENCE_FIELDS:
            errors.append(
                f"alias profile {profile_id}: equivalence fields are "
                f"{sorted(fields)}, expected {sorted(ALIAS_EQUIVALENCE_FIELDS)}"
            )
        for field in ALIAS_EQUIVALENCE_FIELDS:
            if profile.get(field) != "identical":
                errors.append(
                    f"alias profile {profile_id}.{field}: exact aliases must be "
                    "recorded as identical"
                )
        if not isinstance(profile.get("basis"), str) or not profile["basis"].strip():
            errors.append(f"alias profile {profile_id}: equivalence basis is missing")

    reviews = decision.get("alias_reviews", [])
    if not isinstance(reviews, list):
        errors.append("alias_reviews must be a list")
        return
    review_ids = [item.get("id") for item in reviews if isinstance(item, dict)]
    if len(review_ids) != len(reviews) or len(review_ids) != len(set(review_ids)):
        errors.append("alias review ids are missing or duplicated")

    alias_rows = [
        (unit_name, declaration, plain_alias_target(declaration))
        for unit_name, declaration in declarations
        if plain_alias_target(declaration) is not None
    ]
    for unit_name, declaration, target in alias_rows:
        matches = matching_alias_reviews(unit_name, declaration, decision)
        identity = f"{unit_name}.{declaration['name']}"
        if len(matches) != 1:
            errors.append(f"{identity}: alias review count is {len(matches)}")
            continue
        review = matches[0]
        if review.get("target") != target:
            errors.append(
                f"{review['id']}: target {review.get('target')!r} does not match "
                f"the exact alias target {target!r}"
            )
        profile_id = review.get("equivalence_profile")
        if profile_id not in profiles:
            errors.append(f"{review['id']}: unknown equivalence profile {profile_id!r}")
        if review.get("status") != "review-only":
            errors.append(f"{review['id']}: 1.9.3 alias status must be review-only")
        if any(key in review for key in ("deprecated", "remove", "package_move")):
            errors.append(f"{review['id']}: 1.9.3 must not deprecate/remove/move aliases")
        if not isinstance(review.get("reason"), str) or not review["reason"].strip():
            errors.append(f"{review['id']}: review reason is missing")

        review_decision = review.get("decision")
        compatibility = matching_compatibility_decisions(
            unit_name, declaration, decision
        )
        if review_decision == "canonicalize":
            canonical = review.get("canonical")
            canonical_name = None
            if not isinstance(canonical, str) or not canonical.strip():
                errors.append(f"{review['id']}: prospective canonical path is missing")
            else:
                canonical_name = canonical.rsplit(".", 1)[-1]
                if canonical_name not in symbols:
                    errors.append(f"{review['id']}: canonical symbol {canonical} is absent")
            if review.get("follow_up_release") != "1.9.7":
                errors.append(f"{review['id']}: canonicalization must route to 1.9.7")
            if len(compatibility) != 1 or compatibility[0].get("decision") != "replace":
                errors.append(
                    f"{review['id']}: canonicalization needs one matching "
                    "compatibility replacement"
                )
            elif canonical_name and compatibility[0].get("replacement") != canonical_name:
                errors.append(
                    f"{review['id']}: compatibility replacement disagrees with "
                    "the prospective canonical path"
                )
        elif review_decision == "retain":
            if review.get("canonical") or review.get("follow_up_release"):
                errors.append(f"{review['id']}: retained alias has future-removal metadata")
            if compatibility and any(
                item.get("decision") != "retain" for item in compatibility
            ):
                errors.append(f"{review['id']}: retain review conflicts with compatibility")
        else:
            errors.append(f"{review['id']}: invalid alias decision {review_decision!r}")

    for review in reviews:
        if not isinstance(review, dict) or "selector" not in review:
            continue
        matches = [
            (unit_name, declaration)
            for unit_name, declaration in declarations
            if selector_matches(unit_name, declaration, review["selector"])
        ]
        if len(matches) != 1:
            errors.append(f"{review.get('id')}: selector match count is {len(matches)}")
        elif plain_alias_target(matches[0][1]) is None:
            errors.append(f"{review.get('id')}: selector does not identify a plain alias")


def check_decision(
    decision: dict[str, object],
    snapshot: dict[str, object],
    errors: list[str],
) -> None:
    try:
        assert decision["schema_version"] == 2
        assert decision["decision_release"] == DECISION_RELEASE
        assert decision["api_baseline_release"] == API_BASELINE_RELEASE
        assert decision["unresolved_decisions"] == []
        required_concerns = decision["required_concerns"]
        assert len(required_concerns) == len(set(required_concerns))
        assert set(decision["global_conventions"]) == set(required_concerns)
    except (AssertionError, KeyError, TypeError) as exc:
        errors.append(f"docs/api-decision-2.0.json: invalid decision header: {exc}")
        return

    unresolved_words = re.compile(r"(?i)^\s*(?:tbd|todo|undecided|unknown)\s*$")
    for concern, text in decision["global_conventions"].items():
        if not isinstance(text, str) or not text.strip() or unresolved_words.match(text):
            errors.append(f"global convention {concern!r} is unresolved")

    units = snapshot.get("units", [])
    snapshot_units = {unit["unit"] for unit in units}
    assigned_units: list[str] = []
    domains = decision.get("domains", [])
    domain_names = {domain["name"] for domain in domains}
    paths = decision.get("common_paths", [])
    path_ids = [path["id"] for path in paths]
    if len(path_ids) != len(set(path_ids)):
        errors.append("docs/api-decision-2.0.json: duplicate common-path id")
    for domain in domains:
        assigned_units.extend(domain["units"])
        if domain.get("inherits_global") is not True:
            errors.append(f"{domain['name']}: global conventions are not resolved")
        if not domain.get("specific_decisions"):
            errors.append(f"{domain['name']}: no domain-specific decisions")
        unknown = set(domain.get("specific_decisions", {})) - set(
            decision["required_concerns"]
        )
        if unknown:
            errors.append(f"{domain['name']}: unknown convention concerns {sorted(unknown)}")
        for concern, text in domain.get("specific_decisions", {}).items():
            if not isinstance(text, str) or not text.strip() or unresolved_words.match(text):
                errors.append(f"{domain['name']}.{concern}: unresolved decision")
        for path_id in domain.get("common_path_ids", []):
            matching = [path for path in paths if path["id"] == path_id]
            if len(matching) != 1 or matching[0]["domain"] != domain["name"]:
                errors.append(f"{domain['name']}: invalid common path {path_id}")
    unit_counts = Counter(assigned_units)
    if set(unit_counts) != snapshot_units:
        errors.append(
            "domain unit coverage differs from the exact snapshot: missing "
            f"{sorted(snapshot_units - set(unit_counts))}, extra "
            f"{sorted(set(unit_counts) - snapshot_units)}"
        )
    duplicates = sorted(unit for unit, count in unit_counts.items() if count != 1)
    if duplicates:
        errors.append(f"snapshot units assigned to multiple domains: {duplicates}")
    if {path["domain"] for path in paths} != domain_names:
        errors.append("not every domain has exactly represented common-path coverage")

    compatibility_notes = decision.get("compatibility_notes", {})
    compatibility_ids = [item["id"] for item in decision["compatibility_decisions"]]
    if len(compatibility_ids) != len(set(compatibility_ids)):
        errors.append("duplicate compatibility decision id")
    for item in decision["compatibility_decisions"]:
        if item.get("decision") not in {"replace", "retain"}:
            errors.append(f"{item['id']}: invalid compatibility decision")
        if item.get("note") not in compatibility_notes:
            errors.append(f"{item['id']}: missing semantic-difference note")
        if item.get("decision") == "replace" and not item.get("replacement"):
            errors.append(f"{item['id']}: replacement is not named")
        if item.get("decision") == "retain" and item.get("replacement"):
            errors.append(f"{item['id']}: retained entry unexpectedly has replacement")

    all_declarations: list[tuple[str, dict[str, object]]] = []
    symbols: set[str] = set()
    selectors = common_path_selectors(decision)
    selector_match_counts = [0 for _ in selectors]
    for unit in units:
        declarations = unit["declarations"]
        generics = generic_surfaces(declarations)
        summary = Counter()
        for declaration in declarations:
            all_declarations.append((unit["unit"], declaration))
            symbols.add(declaration["name"])
            classification = declaration.get("classification")
            if classification not in CLASSIFICATIONS:
                errors.append(
                    f"{unit['unit']}.{declaration.get('owner')}."
                    f"{declaration['name']}: invalid classification {classification!r}"
                )
                continue
            summary[classification] += 1
            expected = classify_declaration(
                unit["unit"], declaration, decision, generics
            )
            if classification != expected:
                errors.append(
                    f"{unit['unit']}.{declaration.get('owner')}."
                    f"{declaration['name']}: classified {classification}, expected {expected}"
                )
            matching_paths = [
                selector
                for selector in selectors
                if selector_matches(unit["unit"], declaration, selector)
            ]
            if classification == "recommended" and not matching_paths:
                errors.append(
                    f"{unit['unit']}.{declaration.get('owner')}."
                    f"{declaration['name']}: recommended without a common path"
                )
            compatibility = matching_compatibility_decisions(
                unit["unit"], declaration, decision
            )
            if classification == "compatibility":
                if len(compatibility) != 1:
                    errors.append(
                        f"{unit['unit']}.{declaration.get('owner')}."
                        f"{declaration['name']}: compatibility decision count "
                        f"is {len(compatibility)}"
                    )
                else:
                    item = compatibility[0]
                    if declaration.get("compatibility_decision") != item["decision"]:
                        errors.append(f"{item['id']}: snapshot decision mismatch")
                    if declaration.get("compatibility_note") != item["note"]:
                        errors.append(f"{item['id']}: snapshot semantic note mismatch")
                    if declaration.get("preferred_replacement") != item.get("replacement"):
                        errors.append(f"{item['id']}: snapshot replacement mismatch")
            elif any(
                key in declaration
                for key in (
                    "compatibility_decision",
                    "compatibility_note",
                    "preferred_replacement",
                )
            ):
                errors.append(
                    f"{unit['unit']}.{declaration.get('owner')}."
                    f"{declaration['name']}: non-compatibility metadata present"
                )
        expected_summary = {
            classification: summary[classification]
            for classification in sorted(CLASSIFICATIONS)
        }
        if unit.get("classification_summary") != expected_summary:
            errors.append(f"{unit['unit']}: classification summary is stale")

    for index, selector in enumerate(selectors):
        selector_match_counts[index] = sum(
            selector_matches(unit_name, declaration, selector)
            for unit_name, declaration in all_declarations
        )
        if selector_match_counts[index] == 0:
            errors.append(f"recommended selector matches no declaration: {selector}")
    for item in decision["compatibility_decisions"]:
        count = sum(
            selector_matches(unit_name, declaration, item["selector"])
            for unit_name, declaration in all_declarations
        )
        if count == 0:
            errors.append(f"{item['id']}: compatibility selector matches nothing")
        replacement = item.get("replacement")
        if replacement and replacement not in symbols:
            errors.append(f"{item['id']}: replacement {replacement} is absent")

    check_alias_reviews(decision, all_declarations, symbols, errors)

    fragments = pascal_fragments(ROOT)
    implementation_names = {
        declaration["name"]
        for _, declaration in all_declarations
        if declaration["classification"] == "implementation"
        and declaration["owner"] is None
    }
    for path in paths:
        document = Path(path["example_document"])
        candidates = [
            fragment
            for fragment in fragments
            if fragment.path == document
            and is_runnable(fragment)
            and fragment.expectation is not None
        ]
        if not candidates:
            errors.append(f"{path['id']}: no output-checked runnable example")
            continue
        source = candidates[0].source
        identifiers = set(re.findall(r"\b[A-Za-z_]\w*\b", source))
        selector_names = {
            selector.get("surface", selector.get("name"))
            for selector in path["selectors"]
        }
        if not identifiers.intersection(selector_names):
            errors.append(f"{path['id']}: example does not use its recommended entry")
        internal_use = sorted(identifiers.intersection(implementation_names))
        if internal_use:
            errors.append(
                f"{path['id']}: common example uses implementation declarations "
                f"{internal_use}"
            )


def check_diff(diff: dict[str, object], decision: dict[str, object], errors: list[str]) -> None:
    try:
        assert diff["schema_version"] == 1
        assert diff["decision_release"] == DECISION_RELEASE
        assert diff["baseline"] == "docs/public-api-1.9.json"
        assert diff["candidate"] == "2.0"
        assert diff["unresolved"] == []
        consequences = diff["consequences"]
        assert set(consequences) == REQUIRED_DIFF_CATEGORIES
        for category in ("source", "behaviour", "warnings", "packaging"):
            assert consequences[category] == {"decision": "no_change", "items": []}
        assert consequences["documentary_defaults"]["decision"] == "change"
        documentary = consequences["documentary_defaults"]["items"]
        assert documentary
        assert all(item["id"] and item["consequence"] for item in documentary)
        future = {(item["release"], item["capability"]) for item in diff["future_minor_routes"]}
        expected = {
            (item["release"], item["capability"])
            for item in decision["future_minor_capabilities"]
        }
        assert future == expected
        assert all(item[0] == "1.10.0" for item in future)
    except (AssertionError, KeyError, TypeError) as exc:
        errors.append(f"docs/api-diff-1.9-to-2.0.json: incomplete exact diff: {exc}")


def main() -> int:
    errors: list[str] = []
    decision = load_json(DOCS / "api-decision-2.0.json", errors)
    snapshot = load_json(DOCS / "public-api-1.9.json", errors)
    diff = load_json(DOCS / "api-diff-1.9-to-2.0.json", errors)
    if not errors:
        try:
            assert snapshot["schema_version"] == 3
            assert snapshot["release"] == API_BASELINE_RELEASE
            assert snapshot["decision_release"] == DECISION_RELEASE
            assert snapshot["unresolved_decisions"] == []
        except (AssertionError, KeyError, TypeError) as exc:
            errors.append(f"docs/public-api-1.9.json: invalid decision snapshot: {exc}")
    if not errors:
        check_decision(decision, snapshot, errors)
        check_diff(diff, decision, errors)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    declaration_count = sum(len(unit["declarations"]) for unit in snapshot["units"])
    print(
        f"API decision checks passed: {declaration_count} declarations, "
        f"{len(decision['domains'])} domains, "
        f"{len(decision['common_paths'])} checked common paths, "
        f"{len(decision['compatibility_decisions'])} compatibility decisions, "
        f"{len(decision['alias_reviews'])} exact alias reviews, "
        "0 unresolved decisions"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
