#!/usr/bin/env python3
"""Classify release tags for the version declared by a source tree."""

from __future__ import annotations

import argparse
import re
import sys


def classify_release_tag(tag: str, version: str) -> str | None:
    """Return ``stable`` or ``rc`` when *tag* belongs to *version*."""
    prefix = re.escape(f"v{version}")
    if re.fullmatch(prefix, tag):
        return "stable"
    if re.fullmatch(prefix + r"-rc\.[1-9][0-9]*", tag):
        return "rc"
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()

    classification = classify_release_tag(args.tag, args.version)
    if classification is None:
        print(
            f"release tag {args.tag!r} is not v{args.version} or "
            f"v{args.version}-rc.N (N >= 1)",
            file=sys.stderr,
        )
        return 1
    print(classification)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
