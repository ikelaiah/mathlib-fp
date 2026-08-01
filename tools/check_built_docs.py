#!/usr/bin/env python3
"""Check generated HTML release identity, search entries, and local links."""

from __future__ import annotations

import argparse
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []
        self.identifiers: set[str] = set()
        self.releases: list[str] = []

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        values = dict(attrs)
        identifier = values.get("id")
        if identifier:
            self.identifiers.add(identifier)
        if tag in {"a", "link"} and values.get("href"):
            self.links.append(str(values["href"]))
        if tag in {"img", "script"} and values.get("src"):
            self.links.append(str(values["src"]))
        if (
            tag == "meta"
            and values.get("name") == "mathlib-release"
            and values.get("content")
        ):
            self.releases.append(str(values["content"]))


def parse_page(path: Path) -> PageParser:
    parser = PageParser()
    parser.feed(path.read_text(encoding="utf-8"))
    return parser


def validate_page(page: Path, root: Path, expected_release: str) -> list[str]:
    errors: list[str] = []
    parsed = parse_page(page)
    if parsed.releases != [expected_release]:
        errors.append(
            f"{page}: release metadata {parsed.releases!r}, "
            f"expected [{expected_release!r}]"
        )
    for link in parsed.links:
        split = urlsplit(link)
        if split.scheme or split.netloc or link.startswith(("mailto:", "javascript:")):
            continue
        if not split.path:
            target = page
        else:
            target = (page.parent / unquote(split.path)).resolve()
        try:
            target.relative_to(root.resolve())
        except ValueError:
            errors.append(f"{page}: local link escapes built site: {link}")
            continue
        if target.is_dir():
            target = target / "index.html"
        if not target.is_file():
            errors.append(f"{page}: missing built link target: {link}")
            continue
        if split.fragment and target.suffix.lower() == ".html":
            if unquote(split.fragment) not in parse_page(target).identifiers:
                errors.append(f"{page}: missing built link anchor: {link}")
    return errors


def check_search_index(directory: Path) -> list[str]:
    errors: list[str] = []
    path = directory / "search-index.json"
    if not path.is_file():
        return [f"{path}: missing search index"]
    try:
        entries = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(entries, list) or not entries:
            raise ValueError("search index must be a non-empty list")
        for entry in entries:
            target = directory / entry["url"]
            if not target.is_file():
                errors.append(f"{path}: missing indexed page {entry['url']}")
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        errors.append(f"{path}: invalid search index: {exc}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, required=True)
    parser.add_argument(
        "--release", help="treat --site as one standalone release directory"
    )
    args = parser.parse_args()
    site = args.site.resolve()
    errors: list[str] = []

    expected: dict[Path, str] = {}
    if args.release:
        expected[site] = args.release
    else:
        manifest_path = site / "versions.json"
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            current = manifest["current"]
            expected[site] = current
            for entry in manifest["versions"]:
                directory = site / entry["release"]
                if not directory.is_dir():
                    errors.append(f"{directory}: version directory is missing")
                else:
                    expected[directory] = entry["release"]
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
            errors.append(f"{manifest_path}: invalid site manifest: {exc}")

    page_count = 0
    for directory, release in expected.items():
        release_path = directory / "release.json"
        if directory != site or args.release:
            try:
                identity = json.loads(release_path.read_text(encoding="utf-8"))
                if identity["release"] != release or not identity.get("source_ref"):
                    raise ValueError("release/source_ref identity mismatch")
            except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
                errors.append(f"{release_path}: invalid release identity: {exc}")
            errors.extend(check_search_index(directory))
        pages = [directory / "index.html"] if directory == site and not args.release else sorted(directory.rglob("*.html"))
        for page in pages:
            if not page.is_file():
                errors.append(f"{page}: landing page is missing")
                continue
            errors.extend(validate_page(page, site, release))
            page_count += 1

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"Built documentation checks passed: {page_count} HTML pages across "
        f"{len(expected) - (0 if args.release else 1)} release path(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
