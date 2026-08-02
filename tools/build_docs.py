#!/usr/bin/env python3
"""Build dependency-free, release-identified searchable HTML documentation."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import shutil
import zipfile
from pathlib import Path
from urllib.parse import quote


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_VERSIONS = ROOT / "docs" / "versions.json"
OUTPUT_MARKER = ".mathlib-docs-output"


def slug(text: str) -> str:
    value = re.sub(r"[^\w\s-]", "", text.lower(), flags=re.UNICODE)
    return re.sub(r"\s+", "-", value).strip("-")


def inline(text: str, link_resolver=None) -> str:
    def render_link(match: re.Match[str]) -> str:
        target = html.unescape(match.group(2))
        if link_resolver is None:
            target = re.sub(r"\.md(?=#|$)", ".html", target)
        else:
            target = link_resolver(target)
        return (
            f'<a href="{html.escape(target, quote=True)}">'
            f"{match.group(1)}</a>"
        )

    escaped = html.escape(text)
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    escaped = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        render_link,
        escaped,
    )
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    return escaped


def markdown_to_html(source: str, link_resolver=None) -> tuple[str, str]:
    output: list[str] = []
    plain: list[str] = []
    paragraph: list[str] = []
    in_code = False
    in_list = False

    def flush_paragraph() -> None:
        if paragraph:
            text = " ".join(paragraph)
            output.append(f"<p>{inline(text, link_resolver)}</p>")
            plain.append(text)
            paragraph.clear()

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            output.append("</ul>")
            in_list = False

    for line in source.splitlines():
        if line.startswith("```"):
            flush_paragraph()
            close_list()
            if in_code:
                output.append("</code></pre>")
            else:
                language = line[3:].strip()
                output.append(
                    f'<pre><code class="language-{html.escape(language, quote=True)}">'
                )
            in_code = not in_code
            continue
        if in_code:
            output.append(html.escape(line) + "\n")
            plain.append(line)
            continue
        heading = re.match(r"^(#{1,6})\s+(.+)$", line)
        if heading:
            flush_paragraph()
            close_list()
            level = len(heading.group(1))
            title = heading.group(2)
            output.append(
                f'<h{level} id="{slug(title)}">'
                f"{inline(title, link_resolver)}</h{level}>"
            )
            plain.append(title)
        elif re.match(r"^[-*]\s+", line):
            flush_paragraph()
            if not in_list:
                output.append("<ul>")
                in_list = True
            item = re.sub(r"^[-*]\s+", "", line)
            output.append(f"<li>{inline(item, link_resolver)}</li>")
            plain.append(item)
        elif not line.strip():
            flush_paragraph()
            close_list()
        elif line.startswith("|"):
            # Preserve Markdown tables readably; source remains canonical.
            flush_paragraph()
            close_list()
            output.append(f'<pre class="table-source">{html.escape(line)}</pre>')
            plain.append(line)
        else:
            paragraph.append(line.strip())
    flush_paragraph()
    close_list()
    if in_code:
        raise ValueError("unclosed code fence")
    return "\n".join(output), "\n".join(plain)


def load_versions(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError(f"{path}: unsupported documentation-version schema")
    current = data.get("current")
    versions = data.get("versions")
    if not isinstance(current, str) or not isinstance(versions, list):
        raise ValueError(f"{path}: current and versions are required")
    releases: list[str] = []
    for entry in versions:
        if not isinstance(entry, dict) or not isinstance(entry.get("release"), str):
            raise ValueError(f"{path}: every version needs a release string")
        release = entry["release"]
        if not re.fullmatch(r"\d+\.\d+\.\d+", release):
            raise ValueError(f"{path}: invalid release {release!r}")
        releases.append(release)
    if len(set(releases)) != len(releases) or current not in releases:
        raise ValueError(f"{path}: versions must be unique and include current")
    if not isinstance(data.get("site_url"), str):
        raise ValueError(f"{path}: site_url is required")
    if not isinstance(data.get("repository_url"), str):
        raise ValueError(f"{path}: repository_url is required")
    return data


def release_entry(versions: dict[str, object], release: str) -> dict[str, object]:
    for entry in versions["versions"]:
        assert isinstance(entry, dict)
        if entry["release"] == release:
            if not isinstance(entry.get("source_ref"), str):
                raise ValueError(f"release {release} has no source_ref")
            return entry
    raise ValueError(f"release {release} is absent from version manifest")


def page_link_resolver(
    markdown_path: Path, html_target: Path, source: Path, output: Path,
    versions: dict[str, object], release: str,
):
    project_root = source.parent
    repository_url = str(versions["repository_url"]).rstrip("/")
    source_ref = str(release_entry(versions, release)["source_ref"])

    def resolve(target: str) -> str:
        if re.match(r"^(?:https?:|mailto:|javascript:)", target) or target.startswith("#"):
            return target
        file_part, separator, anchor = target.partition("#")
        candidate = (markdown_path.parent / file_part).resolve()
        try:
            relative_document = candidate.relative_to(source)
        except ValueError:
            try:
                relative_project = candidate.relative_to(project_root)
            except ValueError:
                return target
            if candidate.is_file():
                copied = output / "files" / relative_project
                copied.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(candidate, copied)
                href = relative_url(html_target.parent, copied)
            else:
                href = (
                    f"{repository_url}/blob/{quote(source_ref)}/"
                    f"{quote(relative_project.as_posix(), safe='/')}"
                )
        else:
            if candidate.suffix.lower() == ".md":
                linked = output / relative_document.with_suffix(".html")
            else:
                linked = output / relative_document
                if candidate.is_file():
                    linked.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(candidate, linked)
            href = relative_url(html_target.parent, linked)
        if separator:
            href += "#" + anchor
        return href

    return resolve


def prepare_output(output: Path, release: str) -> None:
    marker = output / OUTPUT_MARKER
    if output.exists() and any(output.iterdir()):
        if not marker.is_file():
            raise ValueError(
                f"refusing to replace unmarked non-empty documentation output: {output}"
            )
        shutil.rmtree(output)
    output.mkdir(parents=True, exist_ok=True)
    marker.write_text(release + "\n", encoding="utf-8")


def relative_url(source: Path, target: Path) -> str:
    return os.path.relpath(target, source).replace(os.sep, "/")


def version_navigation(
    versions: dict[str, object], release: str, page_directory: Path,
    site_root: Path | None,
) -> str:
    current = str(versions["current"])
    site_url = str(versions["site_url"]).rstrip("/")
    links: list[str] = []
    for entry in versions["versions"]:
        assert isinstance(entry, dict)
        item_release = str(entry["release"])
        if site_root is None:
            href = f"{site_url}/{item_release}/index.html"
        else:
            href = relative_url(
                page_directory, site_root / item_release / "index.html"
            )
        label = item_release + (" (current)" if item_release == current else "")
        if item_release == release:
            links.append(f"<strong>{html.escape(label)}</strong>")
        else:
            links.append(
                f'<a href="{html.escape(href, quote=True)}">'
                f"{html.escape(label)}</a>"
            )
    return "<nav aria-label=\"Documentation versions\">Versions: " + \
        " · ".join(links) + "</nav>"


def write_site_index(site_root: Path, versions: dict[str, object]) -> None:
    current = str(versions["current"])
    site_url = str(versions["site_url"]).rstrip("/")
    items: list[str] = []
    for entry in versions["versions"]:
        assert isinstance(entry, dict)
        release = str(entry["release"])
        local = site_root / release / "index.html"
        href = (
            f"{release}/index.html" if local.is_file()
            else f"{site_url}/{release}/index.html"
        )
        suffix = " — current release" if release == current else ""
        items.append(
            f'<li><a href="{html.escape(href, quote=True)}">mathlib-fp '
            f"{html.escape(release)}</a>{suffix}</li>"
        )
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="mathlib-release" content="{html.escape(current, quote=True)}">
<title>mathlib-fp documentation — current release {html.escape(current)}</title>
<style>body{{font:16px/1.55 system-ui;max-width:50rem;margin:auto;padding:2rem}}</style>
</head><body><main><h1>mathlib-fp documentation</h1>
<p><strong>Current release: {html.escape(current)}</strong></p>
<p>Choose a release below. Each version keeps the content generated from that
release's tagged documentation; publishing a newer release does not replace it.</p>
<ul>{''.join(items)}</ul></main></body></html>"""
    site_root.mkdir(parents=True, exist_ok=True)
    (site_root / "index.html").write_text(page, encoding="utf-8")
    (site_root / ".nojekyll").write_text("", encoding="utf-8")
    (site_root / "versions.json").write_text(
        json.dumps(versions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_offline_archive(source: Path, archive: Path, release: str) -> str:
    archive.parent.mkdir(parents=True, exist_ok=True)
    root_name = f"mathlib-fp-docs-{release}"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(item for item in source.rglob("*") if item.is_file()):
            if path.resolve() == archive.resolve() or path.name == OUTPUT_MARKER:
                continue
            relative = path.relative_to(source).as_posix()
            info = zipfile.ZipInfo(f"{root_name}/{relative}")
            info.date_time = (1980, 1, 1, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            bundle.writestr(info, path.read_bytes())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksum = archive.with_name(archive.name + ".sha256")
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    return digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("docs"))
    parser.add_argument("--output", type=Path, default=Path("build-temp/docs-site"))
    parser.add_argument("--release")
    parser.add_argument("--versions", type=Path, default=DEFAULT_VERSIONS)
    parser.add_argument(
        "--site-root", type=Path,
        help="write the default version index beside release directories",
    )
    parser.add_argument(
        "--offline-archive", type=Path,
        help="write a deterministic ZIP and adjacent SHA-256 file",
    )
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    versions = load_versions(args.versions.resolve())
    release = args.release or str(versions["current"])
    known = {str(item["release"]) for item in versions["versions"]}
    if release not in known:
        raise ValueError(f"release {release} is absent from {args.versions}")
    if not (source / f"RELEASE_NOTES_{release}.md").is_file():
        raise ValueError(
            f"{source}: release identity {release} has no matching release notes"
        )
    site_root = args.site_root.resolve() if args.site_root else None
    if site_root is not None and output.parent != site_root:
        raise ValueError("versioned output must be a direct child of --site-root")
    if site_root is not None and output.name != release:
        raise ValueError("versioned output directory must equal --release")

    prepare_output(output, release)
    entries = []
    for path in sorted(source.rglob("*.md")):
        relative = path.relative_to(source)
        target = output / relative.with_suffix(".html")
        target.parent.mkdir(parents=True, exist_ok=True)
        markdown = path.read_text(encoding="utf-8")
        resolver = page_link_resolver(
            path, target, source, output, versions, release
        )
        body, plain = markdown_to_html(markdown, resolver)
        title_match = re.search(r"^#\s+(.+)$", markdown, re.M)
        title = title_match.group(1) if title_match else relative.stem
        depth = len(relative.parts) - 1
        root_prefix = "../" * depth
        navigation = version_navigation(
            versions, release, target.parent, site_root
        )
        page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="mathlib-release" content="{html.escape(release, quote=True)}">
<title>{html.escape(title)} — mathlib-fp {html.escape(release)}</title>
<link rel="stylesheet" href="{root_prefix}assets/site.css"></head>
<body data-doc-root="{html.escape(root_prefix, quote=True)}"><header>
<a href="{root_prefix}index.html">mathlib-fp {html.escape(release)}</a>
<label>Search <input id="search" type="search"></label>{navigation}</header>
<div id="results"></div><main>{body}</main>
<script src="{root_prefix}assets/search.js"></script></body></html>"""
        target.write_text(page, encoding="utf-8")
        entries.append(
            {
                "title": title,
                "url": relative.with_suffix(".html").as_posix(),
                "text": plain,
            }
        )

    assets = output / "assets"
    assets.mkdir(exist_ok=True)
    (assets / "site.css").write_text(
        "body{font:16px/1.55 system-ui;max-width:72rem;margin:auto;padding:1rem}"
        "header{display:flex;gap:1.5rem;align-items:center;flex-wrap:wrap;"
        "border-bottom:1px solid #bbb}"
        "pre{overflow:auto;background:#f5f5f5;padding:.7rem}"
        "code{background:#f5f5f5}#results a{display:block}"
        ".table-source{margin:0;padding:.2rem .7rem}",
        encoding="utf-8",
    )
    (assets / "search.js").write_text(
        """const root=document.body.dataset.docRoot||'';
fetch(root+'search-index.json').then(r=>r.json()).then(items=>{
const q=document.querySelector('#search');const out=document.querySelector('#results');
q.addEventListener('input',()=>{const s=q.value.toLowerCase().trim();
out.innerHTML=s?items.filter(x=>(x.title+' '+x.text).toLowerCase().includes(s))
.slice(0,20).map(x=>'<a href="'+root+x.url+'">'+x.title+'</a>').join(''):'';});});
""",
        encoding="utf-8",
    )
    (output / "search-index.json").write_text(
        json.dumps(entries, ensure_ascii=False), encoding="utf-8"
    )
    source_ref = str(release_entry(versions, release)["source_ref"])
    (output / "release.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "release": release,
                "source_ref": source_ref,
                "page_count": len(entries),
            },
            indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    source_assets = source / "assets"
    if source_assets.exists():
        for asset in source_assets.iterdir():
            if asset.is_file():
                shutil.copy2(asset, assets / asset.name)

    if site_root is not None:
        write_site_index(site_root, versions)
    digest = None
    if args.offline_archive:
        archive_source = site_root or output
        digest = write_offline_archive(
            archive_source, args.offline_archive.resolve(), release
        )
    message = f"Built {len(entries)} searchable {release} pages in {output}"
    if digest is not None:
        message += f"; offline archive SHA-256 {digest}"
    print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
