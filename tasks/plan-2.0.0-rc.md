# Implementation plan: 2.0.0 release-candidate materialisation

## Overview

Promote the frozen 1.10.0 API candidate into a 2.0.0 release-candidate branch
without altering Pascal implementation or historical evidence. The branch
records 2.0.0 as the active target while retaining 1.10.0 as the latest
published stable release until final publication.

## Architecture decisions

- `VERSION` remains the canonical candidate target (`2.0.0`); published-stable
  documentation remains explicitly anchored to `1.10.0`.
- The 2.0 API snapshot is generated from the unchanged source and compared to
  the frozen 1.10.0 snapshot. Any diff other than release metadata is a block.
- The promotion gate is replaced with equivalent, stronger 2.0-candidate
  assertions; historical convergence evidence is left intact.
- Historical release directories, snapshots, and qualification evidence are
  not modified.

## Task list

1. [x] Materialise current candidate metadata and versioned API evidence.
2. [x] Evolve the promotion-state checker and its regression tests.
3. [x] Publish candidate migration guidance and 2.0 candidate release notes.
4. [x] Validate documentation, API consistency, builds, and release gates.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Candidate state accidentally claims publication | Separate candidate target from latest published stable in metadata and workflow guards. |
| Frozen public API drifts | Generate the 2.0 snapshot and compare it structurally with 1.10.0 evidence. |
| Historical records are altered | Restrict edits to new 2.0 files and active metadata/tooling. |
