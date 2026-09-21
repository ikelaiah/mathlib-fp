# Implementation plan: 2.0.0 stable publication

## Overview

Promote the soaked and qualified `v2.0.0-rc.2` candidate to the published
2.0.0 release without changing Pascal implementation or historical evidence.
The finalization commit records the stable release state, then the stable tag
and GitHub release run the repository's publication workflows.

## Decisions

- The source/API surface remains frozen at the qualified RC commit; only
  release-state tooling and active release documentation change.
- `v2.0.0` is created from the finalization commit, so published documents do
  not describe the stable release as a candidate.
- The successful RC qualification run is recorded as promotion evidence; the
  final tag's release workflows remain the authoritative publication evidence.

## Tasks

1. Update the promotion-state regression tests and checker for published
   2.0.0 metadata. Verify focused tests.
2. Update the active version navigation and release-owned records. Verify the
   documentation and promotion gates.
3. Run the full local release checks and review the final diff.
4. Commit and push the finalization, publish `v2.0.0`, and monitor the
   release-qualification and documentation workflows.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Stable tag exposes candidate wording | Validate stable state before tagging and publish only the finalization commit. |
| Finalization changes API behavior | Review the diff; it must contain no Pascal source or API snapshot change. |
| RC evidence is mistaken for final-tag evidence | Retain the RC run link and monitor the workflows triggered by the stable release. |
