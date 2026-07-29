#!/usr/bin/env python3
"""Build dependency-free searchable offline HTML from reviewed Markdown."""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
from pathlib import Path


def slug(text: str) -> str:
    value = re.sub(r"[^\w\s-]", "", text.lower(), flags=re.UNICODE)
    return re.sub(r"\s", "-", value).strip("-")


def inline(text: str) -> str:
    def render_link(match: re.Match[str]) -> str:
        target = re.sub(r"\.md(?=#|$)", ".html", match.group(2))
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


def markdown_to_html(source: str) -> tuple[str, str]:
    output: list[str] = []
    plain: list[str] = []
    paragraph: list[str] = []
    in_code = False
    in_list = False

    def flush_paragraph() -> None:
        if paragraph:
            text = " ".join(paragraph)
            output.append(f"<p>{inline(text)}</p>")
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
                    f'<pre><code class="language-{html.escape(language)}">'
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
                f'<h{level} id="{slug(title)}">{inline(title)}</h{level}>'
            )
            plain.append(title)
        elif re.match(r"^[-*]\s+", line):
            flush_paragraph()
            if not in_list:
                output.append("<ul>")
                in_list = True
            item = re.sub(r"^[-*]\s+", "", line)
            output.append(f"<li>{inline(item)}</li>")
            plain.append(item)
        elif not line.strip():
            flush_paragraph()
            close_list()
        elif line.startswith("|"):
            # Preserve Markdown tables readably; source remains the canonical view.
            flush_paragraph()
            close_list()
            output.append(f"<pre class=\"table-source\">{html.escape(line)}</pre>")
            plain.append(line)
        else:
            paragraph.append(line.strip())
    flush_paragraph()
    close_list()
    if in_code:
        raise ValueError("unclosed code fence")
    return "\n".join(output), "\n".join(plain)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("docs"))
    parser.add_argument("--output", type=Path, default=Path("build-temp/docs-site"))
    args = parser.parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    entries = []
    for path in sorted(source.rglob("*.md")):
        relative = path.relative_to(source)
        target = output / relative.with_suffix(".html")
        target.parent.mkdir(parents=True, exist_ok=True)
        body, plain = markdown_to_html(path.read_text(encoding="utf-8"))
        title_match = re.search(r"^#\s+(.+)$", path.read_text(encoding="utf-8"), re.M)
        title = title_match.group(1) if title_match else relative.stem
        depth = len(relative.parts) - 1
        root_prefix = "../" * depth
        page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(title)} — mathlib-fp 1.7.0</title>
<link rel="stylesheet" href="{root_prefix}assets/site.css"></head>
<body><header><a href="{root_prefix}index.html">mathlib-fp 1.7.0</a>
<label>Search <input id="search" type="search"></label></header>
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
        "header{display:flex;gap:2rem;align-items:center;border-bottom:1px solid #bbb}"
        "pre{overflow:auto;background:#f5f5f5;padding:.7rem}code{background:#f5f5f5}"
        "#results a{display:block}.table-source{margin:0;padding:.2rem .7rem}",
        encoding="utf-8",
    )
    (assets / "search.js").write_text(
        """fetch((location.pathname.match(/\\/design\\//)?'../':'')+'search-index.json')
.then(r=>r.json()).then(items=>{const q=document.querySelector('#search');
const out=document.querySelector('#results');q.addEventListener('input',()=>{
const s=q.value.toLowerCase().trim();out.innerHTML=s?items.filter(x=>
(x.title+' '+x.text).toLowerCase().includes(s)).slice(0,20).map(x=>
'<a href="'+(location.pathname.match(/\\/design\\//)?'../':'')+x.url+'">'+
x.title+'</a>').join(''):'';});});""",
        encoding="utf-8",
    )
    (output / "search-index.json").write_text(
        json.dumps(entries, ensure_ascii=False), encoding="utf-8"
    )
    source_assets = source / "assets"
    if source_assets.exists():
        for asset in source_assets.iterdir():
            if asset.is_file():
                shutil.copy2(asset, assets / asset.name)
    print(f"Built {len(entries)} searchable pages in {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
