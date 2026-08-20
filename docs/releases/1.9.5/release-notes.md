# mathlib-fp v1.9.5

## Predictable performance

Version 1.9.5 adds checked performance evidence for representative dense,
sparse, matrix-free iterative, DSP, numerical-modelling, statistics, and
data-analysis workflows. Fourteen canonical rows state cold and warmed timing
semantics, dimensions, scalar kinds, setup, tolerances, allocation and retained
memory metrics, logical working storage, and checksums.

Exact correctness and storage ceilings fail mechanically. Same-run and
host-matched prior timing movements are advisory and request review when they
leave their bands, avoiding false wall-clock precision on shared runners.

Profiling found a material applied radix-2 FFT regression caused by repeated
trigonometric evaluation inside the butterfly loop. The implementation now
reuses the tested native Pascal radix-2 kernel while retaining a readable
portable fallback and cross-path tests. See the
[performance evidence report](performance-evidence.md) and
[machine-readable contract](../../performance-evidence-1.9.5.json).

## Compatibility

The public API remains frozen at the 1.9 baseline. The release adds no
third-party runtime, foreign numerical library, service, or network
requirement. All stable paths retain complete Free Pascal source.

## Qualification

Offline release qualification now validates the canonical benchmark output and
retains `performance-results.json` with the compiler command, host metadata,
checked rows, comparisons, and overall pass/review status. Exact Linux and
Windows clean-archive results remain required before tagging.
