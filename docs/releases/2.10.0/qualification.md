# v2.10.0 qualification record

Contract: [Validation specification](../../../tasks/spec-2.10.md).

## Local qualification

Full Windows x86-64 FPC 3.2.2 qualification passed all 140 gates on
2026-10-22 with `python tools/qualify_release.py --release 2.10.0
--compiler fpc`. The [machine-readable result](qualification-win64.json)
retains the gate list.

- All 1,062 tests passed in normal, `-O3`, and runtime-checked/heap builds;
  heap tracing reported no unfreed blocks. The four validation and eighteen
  PLS tests cover supplied splits, deterministic replay, grouped separation,
  per-split diagnostics, and overlapping scored rows. A separate optimized
  Win32 build passed all 1,062 tests.
- All 48 examples compiled and ran; 29 output contracts passed. Documentation
  checks covered 199 pages, 13 learning routes, 3,255 API declarations,
  25 compiled and executed fragments, and 24 fragment output contracts.
- The offline documentation ZIP passed its SHA-256 and extracted-link checks.
  Numerical fault injection, migration, convergence, three representative
  workflows, portability, and the Lazarus package passed. The
  [workflow result](workflow-qualification-win64.json) retains its checks.
- Performance evidence validated 32 rows and 18 comparisons; no speedup
  claim is made. API regeneration was byte-identical on a second generation.

## Hosted qualification and publication gates

Linux and Windows CI, checksummed clean-source-archive qualification, a
clean-profile Lazarus consumer, exact-main CI, and published artifact checks
remain required. Linux qualification must block new outbound connections from
the extracted archive; Windows qualifies a verified clean ZIP. The released
tag must identify the exact validated main commit.

Publication follows [RELEASING.md](../../../RELEASING.md). The GitHub release
body contains changelog content and begins with `### Added`; the release title
is set only in the title field.
