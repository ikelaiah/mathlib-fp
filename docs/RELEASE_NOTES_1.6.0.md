# mathlib-fp 1.6.0

Released: 2026-07-26

Version 1.6.0 completes the first typed dense decomposition workflow on the
1.5 contiguous matrix foundation. It is a native Object Pascal release with
no third-party runtime dependency.

## Highlights

- Reusable Householder QR and column-pivoted QR factors support full-rank and
  rank-revealing least-squares solves for tall and square matrices.
- Reusable compact one-sided Jacobi SVD factors support tall, square, and wide
  matrices plus rank-deficient and underdetermined minimum-norm solves.
- Full real symmetric and complex Hermitian eigensystems return ascending
  eigenvalues, normalized column eigenvectors, and inspectable convergence
  sweep counts.
- Reusable triangular solves cover lower/upper, unit/non-unit, ordinary,
  transposed, and conjugate-transposed systems.
- LU and Cholesky keep their 1.5 behavior and gain additive condition
  indicators and residual/backward-error diagnostic solves.
- Every applicable operation has matching single/double real/complex entry
  points, supports vector or multiple right-hand sides, and never forms an
  inverse to solve or diagnose a system.

Start with the [dense solver-selection guide](DenseLinearAlgebra.md) and run
[`16_dense_solver_selection.pas`](../examples/16_dense_solver_selection.pas).

## Public API

`AlgebraLib.DenseDecompositions` adds:

- `SolveTriangular` with `TDenseTriangle`, `TDenseDiagonal`, and
  `TDenseTranspose`;
- `FactorQR`, `FactorPivotedQR`, `LeastSquares`, and
  `RankRevealingLeastSquares`;
- `FactorSVD` and `MinimumNormSolve`;
- `FactorSymmetricEigen` and `FactorHermitianEigen`;
- reusable `IDenseSingleQR`, `IDenseDoubleQR`,
  `IDenseSingleComplexQR`, `IDenseComplexQR`, matching four SVD handles, and
  the real-symmetric/complex-Hermitian eigen handles; and
- `TDenseSolveDiagnostics`, reporting numerical rank, rank deficiency,
  selected tolerance, condition indicator, residual norm, and normalized
  backward error.

`AlgebraLib.DenseSolvers` adds `ConditionIndicator` and `SolveWithInfo` to
existing LU/Cholesky handles, plus `SolveWithInfo(A,B,Info)` and
`SolvePositiveDefinite(A,B,Info)` convenience paths.

Factors own immutable snapshots. Coefficients and right-hand sides are never
overwritten; factor outputs and permutation/eigen/singular arrays are copies.
Compact conventions, phase/sign freedoms, tolerances, ordering, allocation,
thread safety, and error behavior are specified in the
[1.6 design record](design/typed-dense-1.6.md).

## Solver guidance

- General square: pivoted LU.
- Positive-definite symmetric/Hermitian: Cholesky.
- Tall and full rank: Householder QR.
- Tall with uncertain rank: column-pivoted QR.
- Rank deficient or underdetermined when minimum norm matters: SVD.
- Full real symmetric or complex Hermitian spectrum: the matching Jacobi
  eigensystem.

SVD is deliberately explicit rather than an automatic expensive fallback.
CPQR's rank-deficient solve is a basic solution; use SVD for a minimum-norm
guarantee.

## Numerical and maintenance evidence

The focused tests cover reconstruction, orthogonality/unitarity,
permutations, multiple right-hand sides, residuals/backward errors, numerical
rank, singular-value ordering, real and complex eigenpair residuals, factor
reuse, immutable source snapshots, empty and singleton-compatible shapes,
repeated spectra, tiny scale, near rank deficiency, non-finite input, invalid
shape/structure, and single/double scalar parity.

Independent exact fixtures include a published two-parameter least-squares
fit, a known underdetermined Moore-Penrose solution, analytic 2-by-2 real and
complex spectra, diagonal singular values, and triangular systems. Acceptance
budgets are precision and algorithm specific; the
[qualification report](QUALIFICATION_1.6.0.md) records the configurations and
normalized measures.

The deterministic benchmark reports QR factor reuse against allocating
convenience calls, compact SVD/minimum-norm work, symmetric eigen work,
checksums, factor-build/result-allocation counts, and estimated peak scalar
working storage. These are reproducibility measurements, not cross-library
speed claims.

## Compatibility

No `IMatrix`, `TMatrixKit`, `IVector`, or typed 1.5 symbol is removed or
deprecated. Legacy LU, QR, SVD, Cholesky, pseudoinverse, and eigen methods
remain the compatibility API. They are not silently rerouted where shape,
ordering, tolerance, error, or ownership contracts differ. Migration remains
an explicit copy into typed storage and is documented in
[the migration guide](MIGRATING_TO_TYPED_DENSE.md).

## Known limitations and deferred families

The following are explicitly unsupported in the typed 1.6 API:

- sparse, packed, and other structured storage/factors;
- LDLT and specialized structure-only factor families;
- CG, MINRES, GMRES, BiCGSTAB, LSQR, preconditioners, callbacks, and
  matrix-free solves;
- nonsymmetric, generalized, polynomial, partial, and Schur eigensystems;
- mutable update/downdate factors, destructive factorisation, and a general
  public workspace API;
- automatic dispatch, parallel/SIMD/GPU decomposition kernels, and external
  BLAS/LAPACK bindings; and
- wholesale migration of fitting, statistics, machine-learning, or other
  higher-level domains.

The pure Pascal portable paths are the complete stable implementation, not a
fallback for a foreign binary.
