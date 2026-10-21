# v2.9.0 qualification record

Contract: [Optimization II specification](../../../tasks/spec-2.9.md).

## Local qualification

Full Windows x86-64 FPC 3.2.2 qualification passed all 138 gates on 2026-10-21:
`python tools/qualify_release.py --release 2.9.0 --compiler fpc`.
The [machine-readable result](qualification-win64.json) retains the gate list.

- All 1,056 tests passed in normal, `-O3`, and runtime-checked/heap builds;
  heap tracing reported zero unfreed blocks. Fifteen new tests cover independent
  analytic minima, bounds, budgets, replay, nonfinite behavior and ownership.
- All 47 examples compiled and ran; 28 output contracts passed. Documentation
  checks covered 193 pages, 13 learning routes and 3,245 API declarations.
  Compiler-backed documentation passed 25 fragments and 24 output contracts.
- The offline documentation ZIP passed its SHA-256 and extracted-link checks.
  Thirteen numerical fault injections were detected. Migration, convergence,
  the three representative workflows, portability and Lazarus package passed.
  The [workflow result](workflow-qualification-win64.json) retains its checks.
- Performance evidence validated 32 rows and 18 comparisons; no new speedup
  claim is made. API regeneration was byte-identical on a second generation.
- A separate optimized Win32 build passed all 1,056 tests. Fresh archive
  preflight passed matching ZIP/tar contents, README quick start, the new
  workflow, a clean-profile Lazarus package consumer and offline HTML checks.
  The immutable v2.8.0 documentation also rebuilt with the new version manifest.

## Hosted qualification and publication gates

Linux and Windows CI passed in [PR #74](https://github.com/ikelaiah/mathlib-fp/pull/74)
and [CI run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39550709023),
including Win64/Win32 Lazarus package builds and the complete Win32 suite.
The [clean-source-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/39550704977)
passed 137 Linux gates and 138 Windows gates. Linux ran with new outbound
connections blocked after checksum verification and extraction; Windows ran
from the verified clean ZIP. Separate platform evidence artifacts were retained.

These candidate gates passed before tagging. The finalized branch must retain
green CI and clean-archive qualification, and the exact resulting main commit
must have green Linux and Windows CI before the v2.9.0 tag is created.
Publication follows [RELEASING.md](../../../RELEASING.md); the release body
contains changelog content and the release title stays in the title field.
