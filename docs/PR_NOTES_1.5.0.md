# PR: Add the 1.5.0 typed contiguous numerical foundation

## Summary

This release-candidate PR implements the active mathlib-fp 1.5.0 milestone. It
adds typed, aligned contiguous dense matrices; matching real and complex
kernels; direct square-system solves; reusable LU and Cholesky factors; and the
documentation, examples, benchmarks, tests, and packaging needed to qualify
that foundation.

The change is additive. `IMatrix`, `TMatrixKit`, `IVector`, `TMatrixArray`, and
their established entry points remain available and are not deprecated. The
implementation is native Free Pascal and adds no third-party runtime, foreign
binary, service, or network dependency.

## Motivation

The compatibility matrix API is useful but is based on `Double`, nested-array
storage, and allocating method calls. Later numerical work needs one explicit
storage and scalar model that supports single/double real and complex values,
checked native-size dimensions, retained-owner views, reusable destinations,
and factor reuse.

This PR supplies that foundation without starting the planned 1.6.0
decomposition, sparse, least-squares, or iterative-solver work.

## Changes

### Typed dense storage (`AlgebraLib.DenseMatrices`)

- Adds 32-byte-aligned contiguous row-major storage for `Single`, `Double`,
  `TSingleComplex`, and `TComplex`.
- Uses zero-based `SizeInt` dimensions and checked native-size element,
  stride, padding, and byte-count arithmetic.
- Adds checked element access, explicit empty-shape behavior, and opaque
  storage identity for conservative alias detection.
- Adds retained-owner mutable rectangular, row, column, and diagonal views.
  `Clone` is the explicit deep-copy operation.
- Adds explicit flat-array, nested-array, precision, real/complex, and
  `IMatrix` conversion paths. Narrowing overflow and silent imaginary-part
  loss are rejected.
- Adds allocation-free operator-friendly 2x2 value records and matching batch
  arrays for all four scalar paths.

### Dense kernels (`AlgebraLib.DenseKernels`)

- Adds matching overloads for copy, add, subtract, Hadamard multiplication,
  scale, AXPY, scalar callback application, transpose, conjugation,
  conjugate transpose, matrix multiplication, sums, dots, conjugating dots,
  and scale-safe norms.
- Provides allocating functions and exact-shape `...Into` procedures for
  reusable caller-owned destinations.
- Writes directly to non-overlapping destinations and uses a temporary when
  backing storage overlaps, including shifted mutable views.
- Uses compensated reductions and products; single-precision paths accumulate
  products and reductions in `Double` before rounding.
- Keeps ordinary multiplication, Hadamard multiplication, transpose,
  conjugation, and conjugate transpose explicit and distinct.

### Complex scalar support (`MathBase.Complex`)

- Adds `TSingleComplex` and `TSingleComplexArray`.
- Adds arithmetic, conjugation, finite checks, scale-safe magnitude and
  division, and explicit conversions to and from `TComplex`.

### Factorization and solve (`AlgebraLib.DenseSolvers`)

- Adds `Solve(A, B)` for square systems with one or many right-hand sides.
- Adds reusable partial-pivoted LU factor objects for all four scalar paths.
- Adds reusable real symmetric and complex Hermitian Cholesky factors.
- Exposes LU factors, permutations, pivot-ratio diagnostics, and an
  `IsIllConditioned` diagnostic.
- Reports invalid shape, non-finite input, singularity,
  non-positive-definiteness, and concise-API ill-conditioning through
  `EDenseMatrixError`; caller inputs are not mutated.

### Documentation, packaging, and release preparation

- Registers the three typed dense units and advances the Lazarus package
  metadata to 1.5.
- Adds a runnable typed solve and factor-reuse example.
- Adds a deterministic odd-shape typed matrix benchmark.
- Adds the typed API guide, ownership design record, migration guide, support
  matrix, machine-readable and human-readable capability inventories, release
  notes, and qualification report.
- Adds dependency-free searchable HTML generation and documentation checks to
  Linux and Windows CI.
- Adds a checksummed clean-archive typed-solve quick start to CI.

## Public API and compatibility

- New units:
  - `AlgebraLib.DenseMatrices`
  - `AlgebraLib.DenseKernels`
  - `AlgebraLib.DenseSolvers`
- New single-precision complex scalar: `TSingleComplex`.
- Existing `IMatrix`, `TMatrixKit`, `IVector`, and compatibility algorithms
  remain source-compatible.
- Migration is opt-in. `FromIMatrix` and `ToIMatrix` are explicit deep copies;
  assigning typed handles and creating views aliases retained storage.
- No existing public symbol is removed, renamed, or deprecated.

## Tests and verification

Focused typed-dense tests cover:

- alignment, checked access, empty shapes, native-size overflow, views, clones,
  explicit conversions, and narrowing rejection;
- single/double real and complex operation parity;
- allocating and reusable-destination kernels, exact and shifted aliases,
  callback failure without partial mutation, and allocation-free 2x2
  expressions;
- reference, odd-shape, empty-shape, overlapping, and mixed-extreme-scale
  matrix products;
- LU reference solutions, multiple right-hand sides, factor reuse, pivot
  diagnostics, singularity, and normalized residuals; and
- real SPD, tiny-scale SPD, and complex Hermitian positive-definite Cholesky
  solves.

Local verification completed:

- [x] 841 tests pass on Win64 normal and `-O3` configurations.
- [x] 841 tests pass with `-O2 -Criot -gh -gl`; heap tracing reports zero
  unfreed blocks.
- [x] 841 tests pass on optimized Win32.
- [x] The Lazarus package builds with clean configuration profiles for Win64
  and Win32.
- [x] All 16 runnable examples compile and execute.
- [x] Searchable documentation builds, with 31 Markdown pages, 16 indexed
  examples, and 54 new-symbol checks.
- [x] The clean extracted source archive passes its checksum, typed-solve quick
  start, and documentation checks.
- [x] The deterministic typed benchmark compiles and runs at `-O3`.
- [x] `git diff --check` passes.

Linux and Windows CI on the exact PR commit remain required publication checks;
these notes do not represent a configured workflow as already successful.

## Performance evidence

The local Windows x86-64 FPC 3.2.2 `-O3` qualification run recorded:

- compatibility `192 x 192` dense product: 15 ms;
- typed `(127 x 129)(129 x 65)` product: 32 ms.

The benchmark is deterministic and reports checksums. These values are
reproducibility evidence, not a cross-library speed claim.

## Risk and review notes

- Review native-size allocation checks on both 32- and 64-bit targets.
- Review retained-owner view lifetime and the conservative alias behavior of
  `...Into` procedures.
- Review single/double and real/complex overload parity, compensated
  accumulation, and finite-input contracts.
- Review LU pivot thresholds, ill-conditioning behavior, Cholesky
  symmetry/Hermitian checks, and residual budgets.
- Review every compatibility conversion as a documented copy boundary.

## Out of scope

- Typed sparse storage or sparse direct/iterative solvers.
- Least squares, QR/LQ, LDLT, SVD, eigenvalue, Schur, or generalized
  decomposition APIs.
- Condition estimators beyond the documented LU pivot diagnostic.
- SIMD, parallel dispatch, GPU support, or external BLAS/LAPACK bindings.
- Bessel, elliptic, and exponential-integral scalar families.
- Merging into `main`, tagging `v1.5.0`, publishing release assets, or changing
  candidate documentation to “current release”; those steps follow
  `RELEASING.md` after the exact release commit passes CI.
