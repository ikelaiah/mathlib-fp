#!/usr/bin/env python3
"""Validate the frozen 2.0.0 release-candidate promotion posture.

The 1.10.0 release remains the latest published stable release until 2.0.0 is
published. This gate validates the candidate target and its generated API
evidence without rewriting the historical 1.9 convergence checks.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from docs_layout import load_layout

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LAYOUT = load_layout(DOCS / "layout.json", DOCS)

CURRENT_RELEASE = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
TARGET_RELEASE = "2.0.0"
PUBLISHED_STABLE = "1.10.0"


def candidate_state_errors(
    target_release: str, versions: object, roadmap: str,
) -> list[str]:
    """Return candidate/stable-state disagreements in release metadata."""
    errors: list[str] = []
    if not isinstance(versions, dict):
        return ["docs/versions.json: version manifest must be an object"]
    if versions.get("current") != target_release:
        errors.append(f"docs/versions.json current is not {target_release}")
    if versions.get("release_state") != "candidate":
        errors.append("docs/versions.json release_state is not candidate")
    if versions.get("published_stable") != PUBLISHED_STABLE:
        errors.append(
            f"docs/versions.json published stable is not {PUBLISHED_STABLE}"
        )
    entries = versions.get("versions")
    candidate_entry = next(
        (
            item for item in entries
            if isinstance(item, dict) and item.get("release") == target_release
        ),
        None,
    ) if isinstance(entries, list) else None
    if candidate_entry is None:
        errors.append(f"docs/versions.json has no {target_release} candidate entry")
    elif candidate_entry.get("source_ref") != f"release/v{target_release}":
        errors.append(
            f"docs/versions.json candidate source_ref is not release/v{target_release}"
        )
    if f"## Previous published stable release: {PUBLISHED_STABLE}" not in roadmap:
        errors.append(
            f"Roadmap does not record {PUBLISHED_STABLE} as the previous "
            "published stable release"
        )
    if f"## Release candidate target: {target_release}" not in roadmap:
        errors.append(
            f"Roadmap does not name {target_release} as the release candidate target"
        )
    return errors


def main() -> int:
    errors: list[str] = []
    if CURRENT_RELEASE != TARGET_RELEASE:
        errors.append(f"VERSION is {CURRENT_RELEASE}, not {TARGET_RELEASE}")

    roadmap = LAYOUT.artifact("roadmap").read_text(encoding="utf-8")
    try:
        versions = json.loads((DOCS / "versions.json").read_text(encoding="utf-8"))
        errors.extend(candidate_state_errors(CURRENT_RELEASE, versions, roadmap))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"docs/versions.json: invalid version manifest: {exc}")

    for name in ("public_api", "api_reference"):
        if TARGET_RELEASE not in LAYOUT.artifact(name).name:
            errors.append(
                f"docs/layout.json {name} is not a {TARGET_RELEASE} artifact"
            )

    snapshot_path = LAYOUT.artifact("public_api")
    try:
        snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
        if snapshot.get("release") != CURRENT_RELEASE:
            errors.append(f"{snapshot_path.relative_to(ROOT)} has the wrong release")
        if snapshot.get("unresolved_decisions") != []:
            errors.append(f"{snapshot_path.relative_to(ROOT)} has unresolved API decisions")
        rotate = any(
            item.get("owner") == "TVector2D" and item.get("name") == "Rotate"
            for unit in snapshot.get("units", [])
            for item in unit.get("declarations", [])
        )
        if not rotate:
            errors.append(
                f"{snapshot_path.relative_to(ROOT)} does not implement "
                "TVector2D.Rotate; the closed 1.10.0 manifest is not shipped"
            )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{snapshot_path.relative_to(ROOT)} cannot be read: {exc}")

    try:
        frozen_snapshot = json.loads(
            (DOCS / "reference" / "api" / "public-api-1.10.0.json").read_text(
                encoding="utf-8"
            )
        )
        candidate_snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
        for item in (frozen_snapshot, candidate_snapshot):
            item.pop("release", None)
            item.pop("generated_by", None)
        if frozen_snapshot != candidate_snapshot:
            errors.append(
                "2.0.0 API evidence differs from the frozen 1.10.0 API evidence"
            )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"frozen/current API evidence cannot be compared: {exc}")

    decision_path = DOCS / "reference" / "api" / "decision-2.0.json"
    migration_path = DOCS / "guides" / "migration" / "to-2.0.md"
    try:
        decision = json.loads(decision_path.read_text(encoding="utf-8"))
        if decision.get("unresolved_decisions") != []:
            errors.append("2.0 API decision has unresolved entries")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{decision_path.relative_to(ROOT)} cannot be read: {exc}")
    if not migration_path.is_file():
        errors.append(
            f"missing required migration guide: {migration_path.relative_to(ROOT)}"
        )

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        "2.0 candidate promotion checks passed: "
        f"{CURRENT_RELEASE} target, {PUBLISHED_STABLE} published stable, API frozen"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
