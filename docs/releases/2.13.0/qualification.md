# v2.13.0 qualification record

Contract: [specification](../../../tasks/spec-2.13.md).

## Local qualification

Windows x86-64 FPC 3.2.2 passed all 146 release-qualification
gates on 2026-10-22. The [machine-readable result](qualification-win64.json)
retains the gate list; [workflow evidence](workflow-qualification-win64.json)
retains the representative consumer checks.

- All 1,077 tests passed in normal, optimized and runtime-checked/heap
  profiles, with no unfreed heap blocks. A separate optimized Win32 suite passed all tests.
- All 51 examples ran and 32 output contracts passed. Documentation
  checks covered 217 pages, 3,273 API declarations and 13 beginner
  routes; 25 fragments compiled and executed with 24 output contracts.
- Offline HTML identity, SHA-256 and extracted links, numerical fault injection,
  migration, convergence, three representative workflows, portability and the
  Lazarus package passed. Performance evidence reviewed 32 rows and 18
  comparisons; this release makes no new speedup claim.
- Five-axis review covered the specification, numerical/reference and failure
  contracts, ownership, compatibility, bounded arithmetic and resource use.

## Hosted and publication gates

Linux and Windows CI passed in [PR #78](https://github.com/ikelaiah/mathlib-fp/pull/78)
and [CI run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39682482067).
The [clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39682433781)
passed 145 Linux and 146 Windows gates.
Linux blocked new outbound connections after checksum verification and
extraction; Windows qualified its verified ZIP. Separate platform artifacts
retain the complete evidence.

Local archive preflight verified SHA-256, matching ZIP/tar contents, the README
quick start, the release example, a fresh-profile Lazarus package consumer,
and offline documentation identity and links.

The finalized branch must retain green CI and clean-archive qualification, and
the resulting exact main commit must pass CI before tagging. Publication and
downloaded artifact verification follow [RELEASING.md](../../../RELEASING.md).
Release bodies contain changelog content; the title stays in the title field.

## Published artifact verification

[v2.13.0](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.13.0) names
main commit `37905e1e8e4c824967e92c6ddfb068b285617ad8`, whose
[Linux/Windows CI](https://github.com/ikelaiah/mathlib-fp/actions/runs/39736123792)
passed. The [documentation publication](https://github.com/ikelaiah/mathlib-fp/actions/runs/39736884577)
deployed the versioned site and attached the offline ZIP and SHA-256.
Downloaded checksums, matching source ZIP/tar contents, the automatic GitHub
archive, README quick starts, the release workflow, a fresh Lazarus consumer,
offline/current links, live retained release identities, six assets and the
title-free body passed on 2026-10-22. The
[verification record](publication-verification.json) retains these checks.
