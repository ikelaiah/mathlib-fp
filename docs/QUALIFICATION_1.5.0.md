# 1.5.0 release qualification

This report records evidence for the typed contiguous foundation. It does not
expand the release into any 1.6.0 decomposition or sparse work.

## Supported target and configuration results

| Target/configuration | Result | Evidence |
| --- | --- | --- |
| Windows x86-64, FPC 3.2.2, normal | 841/841 tests passed | Full `TestRunner` |
| Windows x86-64, FPC 3.2.2, `-O3` | 841/841 tests passed | Optimised full `TestRunner` |
| Windows x86-64, FPC 3.2.2, `-O2 -Criot -gh -gl` | 841/841 tests; 0 unfreed blocks | Runtime and heap-checked full `TestRunner` |
| Windows i386, FPC 3.2.2, `-O2` | 841/841 tests passed | Optimised full `TestRunner` |
| Lazarus package 1.5 | Passed | Clean-config x86-64 and i386 builds |
| Published examples | Passed | All 16 compiled and ran |
| Searchable documentation | Passed | 30 pages, 16 indexed examples, 54 new-symbol checks |
| Clean extracted archive | Passed | Checksum generated; typed solve compiled and ran offline |

The repository CI repeats normal Linux x86-64 and Windows x86-64 suites,
examples, documentation checks, benchmark compilation, clean-archive quick
starts, both Lazarus package builds, and the optimised i386 suite. A release
operator must attach the successful workflow URL before publishing; a
configured job is not represented here as an already successful remote run.

## Numerical evidence

- Reference matrix products cover real and complex values, single and double
  precision, `3 x 5` by `5 x 1` odd shapes, `(0 x 3)(3 x 2)` empty shapes,
  overlapping destination aliases, and mixed `1e200`/`1e-200` factors with a
  representable result.
- LU solve tests cover a published 3-by-3 reference solution, multiple
  right-hand sides, factor reuse, pivot diagnostics, singularity, finite-input
  validation, and a normalized residual below `1e-14` for the double fixture.
- Cholesky tests cover real SPD, tiny-scale SPD, and complex Hermitian
  positive-definite systems.
- Single tests use tolerances on the order of `2e-6`; double tests use
  `1e-12` to `1e-14` according to operation and residual scale.
- The scalar special-function budgets and fixtures remain published in
  `MathBase.md` and `TestMathBase.pas`; unsupported families remain visible in
  the capability inventory.

## Performance evidence

On the local Windows x86-64 qualification host (Intel64 family 6 model 141,
Windows NT 10.0.26200), an FPC 3.2.2 `-O3` benchmark run recorded:

| Workload | Elapsed |
| --- | --- |
| Compatibility `192 x 192` dense product | 15 ms |
| Typed `(127 x 129)(129 x 65)` product | 32 ms |

These are reproducibility data, not a cross-library speed claim. The typed
benchmark uses deterministic trigonometric inputs and reports a checksum.

## Dependency and licence audit

The new stable units import only `SysUtils`, `Math`, existing mathlib-fp units,
and the Free Pascal RTL/FCL. A source scan found no external declarations,
dynamic-library loading, process execution, sockets, or HTTP access in the new
matrix, kernel, solver, or single-complex implementation. All new source,
tests, examples, scripts, and documentation are covered by the repository MIT
licence.

## Maturity changes and known gaps

Typed dense storage, arithmetic, LU solve, and Cholesky solve graduate as
stable for their documented finite-input contracts. No existing API changes
maturity and no API is deprecated.

Known gaps are explicit: single-complex elementary functions beyond the kernel
arithmetic subset; Bessel, elliptic, and exponential-integral scalar families;
least squares and broader decompositions; typed sparse storage/solvers;
parallel/SIMD typed kernels; and published Linux results for the candidate
commit until CI completes. These do not become 1.5 features implicitly.
