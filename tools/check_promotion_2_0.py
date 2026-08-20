#!/usr/bin/env python3
"""Post-1.10.0 2.0 promotion / release-state check.

Validates that the repository has fully advanced to a 2.0.0-next posture after
1.10.0 shipped: the current release is 1.10.0, the roadmap records 1.10.0 as
the previous/completed release and 2.0.0 as the next active release, and the
closed 1.10.0 manifest is implemented in the current API snapshot. This is kept
deliberately small and separate from the historical 1.9.9 convergence gate
(tools/check_convergence.py), which is not turned into a generic 2.0 rewrite.
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
NEXT_RELEASE = "2.0.0"


def main() -> int:
    errors: list[str] = []

    roadmap = LAYOUT.artifact("roadmap").read_text(encoding="utf-8")
    if f"## Previous release: {CURRENT_RELEASE}" not in roadmap:
        errors.append(
            f"Roadmap does not record {CURRENT_RELEASE} as the previous release"
        )
    if f"## Next release: {NEXT_RELEASE}" not in roadmap:
        errors.append(f"Roadmap does not name {NEXT_RELEASE} as the next release")

    snapshot_path = LAYOUT.artifact("public_api")
    try:
        snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
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
        versions = json.loads((DOCS / "versions.json").read_text(encoding="utf-8"))
        if versions.get("current") != CURRENT_RELEASE:
            errors.append(
                f"docs/versions.json current is not {CURRENT_RELEASE}"
            )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"docs/versions.json: invalid version manifest: {exc}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        "2.0 promotion state checks passed: "
        f"{CURRENT_RELEASE} current, {NEXT_RELEASE} next, manifest implemented"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
