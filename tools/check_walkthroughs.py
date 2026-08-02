#!/usr/bin/env python3
"""Validate the independent 1.9.2 clean-room walkthrough evidence."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent.parent
REQUIRED_RELEASE = "1.9.2"
REQUIRED_COUNT = 3
ALLOWED_ROUTES = {
    "dense-square-solve",
    "dense-least-squares",
    "sparse-solve",
    "descriptive-statistics",
    "streaming-statistics",
    "normal-probability",
    "interpolation-or-fitting",
    "optimisation",
    "fft-convolution-or-filtering",
    "time-series",
    "finance",
    "geometry",
    "unit-conversion",
}
REQUIRED_FIELDS = {
    "participant_id",
    "reviewer_id",
    "date",
    "route",
    "search_query",
    "environment",
    "elapsed_minutes",
    "observed_result",
    "confusion_or_failure",
    "correct_result",
    "read_implementation_units",
    "implemented_exercised_feature",
    "evidence",
}


def nonempty_string(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validation_errors(data: object) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["manifest root must be an object"]
    if data.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    if data.get("release") != REQUIRED_RELEASE:
        errors.append(f"release must be {REQUIRED_RELEASE}")
    records = data.get("walkthroughs")
    if not isinstance(records, list):
        return [*errors, "walkthroughs must be an array"]
    if len(records) < REQUIRED_COUNT:
        errors.append(
            f"need at least {REQUIRED_COUNT} reviewed walkthroughs; "
            f"found {len(records)}"
        )

    participants: set[str] = set()
    evidence_links: set[str] = set()
    for number, record in enumerate(records, start=1):
        prefix = f"walkthrough {number}"
        if not isinstance(record, dict):
            errors.append(f"{prefix}: record must be an object")
            continue
        missing = sorted(REQUIRED_FIELDS - set(record))
        if missing:
            errors.append(f"{prefix}: missing fields {missing}")
            continue
        for field in (
            "participant_id",
            "reviewer_id",
            "date",
            "route",
            "search_query",
            "environment",
            "observed_result",
            "confusion_or_failure",
            "evidence",
        ):
            if not nonempty_string(record[field]):
                errors.append(f"{prefix}: {field} must be a non-empty string")

        participant = str(record["participant_id"]).strip()
        reviewer = str(record["reviewer_id"]).strip()
        route = str(record["route"]).strip()
        if participant in participants:
            errors.append(f"{prefix}: participant_id must be distinct")
        participants.add(participant)
        if participant == reviewer:
            errors.append(f"{prefix}: reviewer must differ from participant")
        if route not in ALLOWED_ROUTES:
            errors.append(
                f"{prefix}: route must identify a published beginner recipe"
            )

        try:
            date.fromisoformat(str(record["date"]))
        except ValueError:
            errors.append(f"{prefix}: date must use YYYY-MM-DD")
        elapsed = record["elapsed_minutes"]
        if (
            isinstance(elapsed, bool)
            or not isinstance(elapsed, (int, float))
            or elapsed <= 0
        ):
            errors.append(f"{prefix}: elapsed_minutes must be positive")

        for field, expected in (
            ("correct_result", True),
            ("read_implementation_units", False),
            ("implemented_exercised_feature", False),
        ):
            if record[field] is not expected:
                errors.append(f"{prefix}: {field} must be {expected}")

        evidence = str(record["evidence"]).strip()
        parsed = urlsplit(evidence)
        if parsed.scheme != "https" or not parsed.netloc:
            errors.append(f"{prefix}: evidence must be an HTTPS link")
        if evidence in evidence_links:
            errors.append(f"{prefix}: evidence link must be distinct")
        evidence_links.add(evidence)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("docs/walkthroughs-1.9.2.json"),
    )
    args = parser.parse_args()
    path = (ROOT / args.manifest).resolve()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"{path}: {exc}", file=sys.stderr)
        return 1
    errors = validation_errors(data)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        "Clean-room walkthrough checks passed: "
        f"{len(data['walkthroughs'])} reviewed independent records"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
