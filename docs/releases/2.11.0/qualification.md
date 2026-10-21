# v2.11.0 qualification record

Contract: [Chronological validation specification](../../../tasks/spec-2.11.md).

## Local qualification

Windows x86-64 FPC 3.2.2 passed all 142 release-qualification gates on
2026-10-22. The [machine-readable result](qualification-win64.json) retains
the gate list; [workflow evidence](workflow-qualification-win64.json) retains
the representative consumer checks.

- All 1,065 tests passed in normal, optimized and runtime-checked/heap profiles,
  with no unfreed heap blocks. A separate optimized Win32 suite passed all tests.
- All 49 examples ran and 30 output contracts passed. Documentation checks
  covered 205 pages, 3,257 API declarations and 13 beginner routes; 25 fragments
  compiled and executed with 24 checked output contracts.
- Offline HTML identity, SHA-256 and extracted links, numerical fault injection,
  migration, convergence, three representative workflows, portability and the
  Lazarus package passed. Performance evidence reviewed 32 rows and 18
  comparisons; this release makes no new speedup claim.
- Five-axis review covered arithmetic bounds, complete-horizon construction,
  row ownership, replay, gap/overlap semantics and PLS integration. Existing
  seeded paths are unchanged.

## Hosted and publication gates

Linux and Windows CI passed in [PR #76](https://github.com/ikelaiah/mathlib-fp/pull/76)
and [CI run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39675665037).
The [clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39675637936)
passed 141 Linux and 142 Windows gates. Linux blocked new outbound connections
after checksum verification and extraction; Windows qualified its verified ZIP.
Separate platform evidence artifacts were retained.

Local archive preflight verified SHA-256, matching ZIP/tar contents, the README
quick start, chronological-validation workflow, a fresh-profile Lazarus package
consumer, and offline documentation identity and links.

The finalized branch must retain green CI and clean-archive qualification, and
the resulting exact main commit must pass CI before tagging. Publication and
downloaded artifact verification follow [RELEASING.md](../../../RELEASING.md).
Release bodies contain changelog content; the title stays in the title field.

## Published artifact verification

[v2.11.0](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.11.0) names
main commit `3bc5be2ec81dbcd6cbd5a79e6af223ed9b388380`, whose
[Linux/Windows CI](https://github.com/ikelaiah/mathlib-fp/actions/runs/39679027271)
passed. The [documentation publication](https://github.com/ikelaiah/mathlib-fp/actions/runs/39680145824)
deployed the versioned site and attached the offline ZIP and SHA-256.
Downloaded checksums, matching source ZIP/tar contents, the automatic GitHub
archive, README quick starts, the release workflow, a fresh Lazarus consumer,
offline/current links, live retained release identities, six assets and the
title-free body passed on 2026-10-22. The
[verification record](publication-verification.json) retains these checks.
