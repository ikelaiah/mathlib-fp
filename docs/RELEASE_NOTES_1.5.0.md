# mathlib-fp 1.5.0

Version 1.5.0 adds the typed contiguous numerical foundation while preserving
the complete 1.4 compatibility API.

## User-visible additions

- 32-byte-aligned row-major matrices for single/double real and complex
  scalars, with checked `SizeInt` dimensions and allocation arithmetic.
- Retained-owner mutable row, column, diagonal, and rectangular views, plus
  explicit deep `Clone`.
- Matching allocating and reusable-destination kernels for addition,
  subtraction, scaling, AXPY, typed scalar-function application, reductions,
  elementwise multiplication, transpose, and ordinary matrix multiplication.
  Complex paths distinguish conjugation and conjugate transpose.
- Allocation-free operator-friendly 2x2 value records and matching batch array
  types for every supported scalar path.
- Direct `Solve(A, B)` for one or many right-hand sides using pivoted LU, plus
  reusable LU and real/complex Cholesky factor objects.
- `TSingleComplex`, explicit single/double complex conversions, compatibility
  bridges for flat/nested arrays and `IMatrix`, explicit real/complex matrix
  conversions, a migration guide, capability inventory, support matrix, and
  runnable solve example.

## Migration and compatibility

No public symbol was removed or deprecated. `IMatrix`, `TMatrixKit`,
`IVector`, and nested `TMatrixArray` storage remain available. Migration to the
new API is opt-in.

Conversions from nested arrays, flat vectors, and `IMatrix` copy data into
aligned storage. Conversions back also copy. Views do not copy and are mutable
aliases; `Clone` is the deep-copy operation. See
[`MIGRATING_TO_TYPED_DENSE.md`](MIGRATING_TO_TYPED_DENSE.md).

## Maturity and known limitations

The typed storage, kernels, LU solve, and Cholesky solve are stable within
their documented finite-input contracts. The 1.5 scope is dense, square direct
solves. It does not add sparse typed storage, least squares, QR/SVD/eigen
workflows, condition estimators, SIMD, or parallel dispatch.

Bessel, elliptic, and exponential-integral families remain unsupported rather
than being represented as complete. The complete supported/unsupported
inventory is in [`CAPABILITIES.md`](CAPABILITIES.md).

## Validation evidence

The 1.5 tests cover:

- reference real/complex products, odd and empty shapes, mutable view aliases,
  deep copies, aligned storage, explicit compatibility copies, and overlapping
  `MultiplyInto`;
- mixed `1e200`/`1e-200` matrix products with representable results;
- single/double real and complex operation parity with precision-appropriate
  tolerances;
- native-size shape and byte-count overflow before allocation;
- LU vector and multiple-RHS solutions, factor reuse, singularity errors,
  positive-definite real and Hermitian complex Cholesky, and normalized
  residual/backward-error checks;
- validation failure without destination mutation.

`benchmarks/BenchmarkRunner.lpr` includes a deterministic `127 x 129` by
`129 x 65` typed product alongside the existing compatibility benchmark. No
throughput improvement is claimed from this first portable kernel.

The repository CI builds and runs the complete tests and examples on Linux
x86-64 and Windows x86-64, builds the Lazarus package on Windows x86-64 and
i386, and runs an optimised i386 suite. The publication CI completed
successfully for [PR #9](https://github.com/ikelaiah/mathlib-fp/pull/9) in
[CI run #92](https://github.com/ikelaiah/mathlib-fp/actions/runs/30156655764).

## Installation

Download the
[source archive](https://github.com/ikelaiah/mathlib-fp/releases/download/v1.5.0/mathlib-fp-1.5.0.tar.gz)
and its
[SHA-256 checksum](https://github.com/ikelaiah/mathlib-fp/releases/download/v1.5.0/mathlib-fp-1.5.0.sha256),
extract it, and put `src/` on the FPC unit path. No configure step, network
connection, DLL, licence key, or third-party runtime is needed.
