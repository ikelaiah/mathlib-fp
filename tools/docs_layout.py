"""Shared validation and lookup for flat and nested documentation layouts."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path


class LayoutError(ValueError):
    """The documentation layout manifest is unsafe or incomplete."""


def _relative(value: object, label: str) -> Path:
    if not isinstance(value, str) or not value or "\\" in value:
        raise LayoutError(f"{label}: expected a non-empty slash-separated path")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or path.suffix not in {".md", ".json"}:
        raise LayoutError(f"{label}: path must stay within docs and name Markdown or JSON")
    return path


@dataclass(frozen=True)
class DocumentationLayout:
    root: Path
    release: str
    artifacts: dict[str, Path]
    aliases: dict[str, str]
    legacy_paths: dict[str, str] = None  # type: ignore[assignment]
    legacy: bool = False

    def artifact(self, name: str) -> Path:
        try:
            return self.root / self.artifacts[name]
        except KeyError as exc:
            raise LayoutError(f"layout has no {name!r} artifact") from exc

    def release_notes(self) -> Path:
        return self.artifact("release_notes")

    def canonical_path(self, relative: str) -> Path | None:
        """Map a former flat evidence path to its canonical source path."""
        name = Path(relative).name
        target = (
            self.aliases.get(relative) or self.aliases.get(name)
            or (self.legacy_paths or {}).get(relative)
            or (self.legacy_paths or {}).get(name)
        )
        if target:
            return self.root / target
        match = re.fullmatch(r"(RELEASE_NOTES|PR_NOTES|QUALIFICATION|WORKFLOW_QUALIFICATION)_(\d+\.\d+\.\d+)\.md", name)
        if match:
            slug = {"RELEASE_NOTES": "release-notes", "PR_NOTES": "pr-notes", "QUALIFICATION": "qualification", "WORKFLOW_QUALIFICATION": "workflow-qualification"}[match.group(1)]
            candidate = self.root / "releases" / match.group(2) / f"{slug}.md"
            return candidate if candidate.is_file() else None
        return None


def legacy_layout(root: Path, release: str) -> DocumentationLayout:
    return DocumentationLayout(
        root=root,
        release=release,
        artifacts={
            "release_notes": Path(f"RELEASE_NOTES_{release}.md"),
            "pr_notes": Path(f"PR_NOTES_{release}.md"),
            "qualification": Path(f"QUALIFICATION_{release}.md"),
            "workflow_qualification": Path(f"WORKFLOW_QUALIFICATION_{release}.md"),
        },
        aliases={}, legacy_paths={},
        legacy=True,
    )


def load_layout(path: Path, root: Path, release: str | None = None) -> DocumentationLayout:
    """Load a nested layout, or recognise the flat layout used by old tags."""
    root = root.resolve()
    if not path.is_file():
        if not release:
            raise LayoutError(f"{path}: missing documentation layout manifest")
        layout = legacy_layout(root, release)
        if not layout.release_notes().is_file():
            raise LayoutError(f"{root}: release {release} has no release notes")
        return layout
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise LayoutError(f"{path}: invalid JSON: {exc}") from exc
    if not isinstance(data, dict) or data.get("schema_version") != 1:
        raise LayoutError(f"{path}: unsupported documentation-layout schema")
    declared_release = data.get("current_release")
    if not isinstance(declared_release, str) or not re.fullmatch(r"\d+\.\d+\.\d+", declared_release):
        raise LayoutError(f"{path}: current_release must be a release number")
    if release and release != declared_release:
        raise LayoutError(f"{path}: is for {declared_release}, not {release}")
    raw_artifacts = data.get("artifacts")
    if not isinstance(raw_artifacts, dict) or not raw_artifacts:
        raise LayoutError(f"{path}: artifacts must be a non-empty object")
    artifacts = {name: _relative(value, f"artifacts.{name}") for name, value in raw_artifacts.items() if isinstance(name, str)}
    if len(artifacts) != len(raw_artifacts) or "release_notes" not in artifacts:
        raise LayoutError(f"{path}: named artifacts must include release_notes")
    if len(set(artifacts.values())) != len(artifacts):
        raise LayoutError(f"{path}: duplicate artifact target")
    raw_aliases = data.get("aliases", {})
    if not isinstance(raw_aliases, dict):
        raise LayoutError(f"{path}: aliases must be an object")
    aliases: dict[str, str] = {}
    for old, new in raw_aliases.items():
        old_path = _relative(old, "aliases source")
        new_path = _relative(new, "aliases target")
        if new_path.as_posix() in raw_aliases:
            raise LayoutError(f"{path}: aliases must target canonical documents directly")
        if not (root / new_path).is_file():
            raise LayoutError(f"{path}: alias target does not exist: {new_path}")
        aliases[old_path.as_posix()] = new_path.as_posix()
    if len(aliases) != len(raw_aliases):
        raise LayoutError(f"{path}: duplicate alias source")
    raw_legacy = data.get("legacy_paths", {})
    if not isinstance(raw_legacy, dict):
        raise LayoutError(f"{path}: legacy_paths must be an object")
    legacy_paths = {}
    for old, new in raw_legacy.items():
        old_path = _relative(old, "legacy path source")
        new_path = _relative(new, "legacy path target")
        if not (root / new_path).is_file():
            raise LayoutError(f"{path}: legacy path target does not exist: {new_path}")
        legacy_paths[old_path.as_posix()] = new_path.as_posix()
    return DocumentationLayout(root, declared_release, artifacts, aliases, legacy_paths)
