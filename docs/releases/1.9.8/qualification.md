# mathlib-fp 1.9.8 qualification

## Qualification statement

Version 1.9.8 is qualified only when the exact candidate source archive passes
the existing target-tier gates plus the representative workflow qualification.
This document distinguishes completed local evidence from mandatory CI
evidence; it does not infer Linux or Win32 results from a Windows x86-64 run.

## Workflow completion gate

| Gate | Evidence | Status |
| --- | --- | --- |
| At least three workflows | Sensor, modelling, and probability/finance programs | Passed locally, 2026-08-16 |
| Multi-domain and realistic | 4 / 3 / 4 domains per workflow; load, validate, transform, fit/solve, diagnostic, export | Passed locally |
| Diagnostic paths | Non-finite rejection, iteration-limit root, invalid-fit exception, invalid-probability exception | Passed locally |
| Deterministic bounded output | Two runs byte-identical; numerical bounds verified | Passed locally |
| No private API / network / runtime | Public APIs only; local fixture and seeded data; no new dependency | Passed |
| Clean-archive journey | Checker runs from an isolated work directory with copied fixtures | Passed locally |

## Local environment

| Item | Value |
| --- | --- |
| Date | 2026-08-16 |
| OS / CPU | Windows x86-64 |
| FPC | 3.2.2 |
| Python | 3.13.5 |
| Runtime dependencies added | None |

## Full local release qualification

Local workflow qualification passed for all three workflows; the retained
result is `build-temp/workflow-qualification/results.json`. The complete release
gate (`python tools/qualify_release.py --release 1.9.8 --compiler fpc
--lazbuild lazbuild`) covers compiler identity, normal/optimized/checked-heap
test modes, all examples and output contracts, documentation tests/fragments/
site/offline archive, API decisions, numerical mutation/evidence, migration
rehearsal, workflow qualification, portability, Lazarus package, and
benchmark/performance evidence.

## Required exact-candidate evidence

Before tagging, the exact commit must still pass in CI:

- Linux x86-64 and Windows x86-64 checksummed, network-isolated clean-archive
  qualification, including workflow results as retained artifacts;
- Windows i386 secondary tests, native portability probe, source/package audit,
  and Lazarus package build;
- normal, optimized, checked/heap test modes, every top-level example and output
  contract, documentation/site/offline archive checks, numerical evidence and
  mutation gates, performance evidence, portability evidence, migration
  rehearsal, workflow qualification, package build, and final API snapshot
  check.

Candidate workflow results are intentionally not pre-recorded as passed in the
repository. They belong to the exact candidate commit's CI artifacts.

## Known limits

- Local evidence covers Windows x86-64 only. Supported target claims remain
  bounded by [SUPPORT.md](../../project/support.md) and exact candidate CI.
- The sensor workflow reads a bundled CSV relative to the working directory;
  the documented run instruction is to execute from the repository or extracted
  archive root, and the checker enforces an isolated copy of the fixture.
- Seeded workflows are reproducible within a single build and platform; the
  checker verifies same-platform repeatability rather than cross-platform
  bitwise equality of floating-point results.
