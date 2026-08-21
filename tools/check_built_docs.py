#!/usr/bin/env python3
"""Check generated HTML release identity, search entries, and local links."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from functools import lru_cache
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


REQUIRED_PROBLEM_QUERIES = (
    "least squares",
    "normal probability",
    "FFT convolution",
)


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


@lru_cache(maxsize=None)
def _parse_page(path: Path, source: str) -> PageParser:
    parser = PageParser()
    parser.feed(source)
    return parser


def parse_page(path: Path) -> PageParser:
    """Reuse parsed pages without trusting filesystem timestamp precision."""
    return _parse_page(path, path.read_text(encoding="utf-8"))


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


def check_search_index(
    directory: Path, required_queries: tuple[str, ...] = (),
) -> list[str]:
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
        corpus = [
            f"{entry.get('title', '')} {entry.get('text', '')}".casefold()
            for entry in entries
            if isinstance(entry, dict)
        ]
        for query in required_queries:
            if not any(query.casefold() in item for item in corpus):
                errors.append(f"{path}: search cannot find problem {query!r}")
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        errors.append(f"{path}: invalid search index: {exc}")
    return errors


def check_redirects(directory: Path, aliases: dict[str, str]) -> list[str]:
    """Ensure legacy aliases remain local redirects and never become search hits."""
    errors: list[str] = []
    try:
        entries = json.loads((directory / "search-index.json").read_text(encoding="utf-8"))
        indexed = {entry["url"] for entry in entries}
    except (OSError, KeyError, TypeError, json.JSONDecodeError) as exc:
        return [f"{directory}: cannot validate redirects without search index: {exc}"]
    for legacy, canonical in aliases.items():
        redirect = directory / Path(legacy).with_suffix(".html")
        target = directory / Path(canonical).with_suffix(".html")
        if not redirect.is_file():
            errors.append(f"{redirect}: missing alias redirect")
            continue
        if not target.is_file():
            errors.append(f"{redirect}: canonical target is missing: {canonical}")
        href = os.path.relpath(target, redirect.parent).replace(os.sep, "/")
        if href not in redirect.read_text(encoding="utf-8"):
            errors.append(f"{redirect}: does not link to {canonical}")
        if redirect.relative_to(directory).as_posix() in indexed:
            errors.append(f"{redirect}: alias must not be indexed")
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
                aliases = identity.get("aliases", {})
                if not isinstance(aliases, dict):
                    raise ValueError("invalid redirect aliases")
            except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
                errors.append(f"{release_path}: invalid release identity: {exc}")
            required_queries = (
                REQUIRED_PROBLEM_QUERIES
                if args.release or release == current
                else ()
            )
            errors.extend(check_search_index(directory, required_queries))
            errors.extend(check_redirects(directory, aliases))
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
