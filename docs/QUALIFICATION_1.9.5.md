# mathlib-fp 1.9.5 qualification

Status on 2026-08-11: **all 78 local release-qualification gates passed** on
Windows 11 x86-64 with FPC 3.2.2, Lazarus 4.8, and Python 3.13.5. The release
cannot be tagged until Linux and Windows clean-archive workflows pass for the
exact candidate commit.

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Representative coverage | The manifest requires and the runner emits 14 checked rows across dense, sparse, iterative, DSP, modelling, statistics, and data analysis, including small and large cases where applicable. |
| Reproducible claims | Every published claim maps to a row with dimensions, scalar kind, setup, compiler flags, checksum, and tolerance. The result artifact records host and compiler metadata. |
| Exact tripwires | Allocation, retained bytes, logical working elements, dense-shape elements, and checksums are hard gates. Sparse and matrix-free dense-shape counts must be exactly zero. |
| Honest timing | Same-run and host-matched prior comparisons are recorded as advisory pass/review outcomes; timing review never masks an exact-gate failure. |
| Profile-led optimization | The applied radix-2 regression was reproduced before the internal change, then covered by a reference/round-trip test and the full portable suite. |
| Compatibility | The 1.9.0 public-interface snapshot remains unchanged and the historical 1.9.4 numerical-evidence catalogue remains valid. |

## Required local command

Run from the exact clean 1.9.5 source archive selected for release:

```text
python tools/qualify_release.py --release 1.9.5 --compiler fpc \
  --lazbuild lazbuild
```

The driver runs normal, optimised, checked/heap-traced tests, examples and
output contracts, documentation and API checks, historical numerical evidence
and mutation gates, the versioned documentation build, the Lazarus package,
the benchmark, and the v1.9.5 performance validator. The checked result is
retained as `performance-results.json` alongside the qualification logs.

## Local result

The command passed all 78 gates. It recorded zero failed gates across normal,
optimised, and checked/heap-traced test suites; all 932 FPCUnit tests passed in
each applicable run and the heap trace reported no unfreed blocks. Examples,
output contracts, documentation/API checks, the retained 1.9.4 numerical
catalogue and mutation gate, the 1.9.5 site/offline archive, Lazarus package,
raw benchmark, and performance validation also passed.

The final qualification performance artifact contains all 14 required rows and
13 advisory comparisons, with a `pass` status, a matched prior-baseline host,
and no timing review. The manifest is retained locally at
`build-temp/release-qualification/results.json` and the checked performance
artifact at `build-temp/release-qualification/performance-results.json`.

## Required clean-archive evidence

The exact candidate commit must pass Linux and Windows clean-archive
qualification. Those workflows are authoritative for portability and archive
claims; a maintainer checkout cannot replace them.

## Limits

Performance observations are bounded to their recorded host, compiler, flags,
fixtures, and setup. Sampled live-heap deltas do not count every short-lived
RTL allocation, and no checked row is a universal throughput guarantee.
