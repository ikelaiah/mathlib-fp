# PR: Add dependable typed dense linear algebra for 1.6.0

## Summary

This PR implements the mathlib-fp 1.6.0 milestone. It completes the first
high-trust typed dense linear-algebra workflow on the 1.5 contiguous matrix
foundation with reusable triangular, QR, column-pivoted QR, SVD, symmetric
eigen, and Hermitian eigen operations.

The release also requalifies the existing LU and Cholesky paths, adds
inspectable solve diagnostics, and supplies the documentation, tests,
examples, benchmarks, packaging, and CI coverage required by the 1.6
completion gate.

The change is additive. Existing compatibility and typed 1.5 APIs remain
source-compatible. The implementation is native Free Pascal and introduces no
third-party runtime, foreign binary, service, or network dependency.

## Motivation

Version 1.5 established typed contiguous storage, stable kernels, and reusable
square-system factors. General numerical applications also need dependable
least-squares, rank-revealing, minimum-norm, and structured eigenproblem
workflows without forming an inverse or converting through the compatibility
`Double` matrix representation.

This PR provides that shared dense foundation across single/double real and
complex scalar paths. It deliberately does not begin the higher-level fitting,
interpolation, optimisation, integration, equation, or ODE work planned for
1.7.0.

## Changes

### Dense decompositions (`AlgebraLib.DenseDecompositions`)

- Adds reusable lower/upper, unit/non-unit triangular solves for ordinary,
  transposed, and conjugate-transposed systems.
- Adds compact Householder QR factors for tall and square matrices, including
  full-rank least-squares solves and factor reuse.
- Adds column-pivoted Householder QR with the documented `A*P=Q*R`
  permutation convention, caller-controlled or scale-derived rank tolerance,
  numerical rank, and rank-revealing basic solutions.
- Adds compact one-sided Jacobi SVD for tall, square, and wide real/complex
  matrices, with descending singular values and minimum-norm solves.
- Adds cyclic-Jacobi full eigensystems for real symmetric and complex
  Hermitian matrices, returning ascending eigenvalues, normalized column
  eigenvectors, and convergence sweep counts.
- Shares generic scalar policies and portable kernels across `Single`,
  `Double`, `TSingleComplex`, and `TComplex` instead of maintaining four
  unrelated implementations.
- Uses scale-safe norms, convergence decisions, residuals, and backward-error
  calculations, including portable Win32/x87 handling for Jacobi rotations
  and rank-deficient wide SVD inputs.

### Solves and diagnostics

- Adds `TDenseSolveDiagnostics`, reporting method, numerical rank, rank
  deficiency, selected tolerance, condition indicator, residual norm, and
  normalized backward error.
- Adds `LeastSquares`, `RankRevealingLeastSquares`, and `MinimumNormSolve`
  convenience paths while retaining explicit reusable factors for repeated
  right-hand sides.
- Adds `ConditionIndicator` and `SolveWithInfo` to the existing typed LU and
  Cholesky factors.
- Adds diagnostic general-square and positive-definite convenience solves.
- Supports vector and multiple right-hand sides throughout every
  mathematically applicable solve family.
- Never forms an inverse to solve a system or produce diagnostics.

### Ownership and numerical contracts

- Factors own immutable snapshots; mutating a source matrix after
  factorisation cannot alter an existing factor.
- Coefficient matrices and right-hand sides are never overwritten.
- Factor matrices, singular/eigenvalue arrays, eigenvectors, and permutations
  are exposed as copies.
- Compact output shapes, transpose/conjugate conventions, permutation
  direction, ordering, phase/sign freedoms, tolerances, rank decisions,
  allocation behavior, thread safety, and errors are fixed in the 1.6 design
  record.
- Invalid shapes, invalid tolerances, non-finite inputs, singular triangular
  systems, nonsymmetric/non-Hermitian inputs, and non-positive-definite
  systems fail through the documented `EDenseMatrixError` path.

### Documentation, examples, benchmarks, and packaging

- Adds the 1.6 typed-dense design record before declaring the new APIs stable.
- Adds a “choose a dense solver” guide and compatibility migration recipes.
- Adds a realistic solver-selection example covering QR calibration, SVD
  redundant-actuator minimum norm, and symmetric covariance eigenanalysis.
- Extends the deterministic benchmark with QR factor reuse versus allocating
  convenience calls, compact SVD/minimum-norm work, and symmetric eigen work.
- Reports benchmark checksums, factor builds, result allocations, rank/sweep
  information, and estimated scalar working storage.
- Updates the human-readable and machine-readable capability inventories,
  support matrix, package metadata, changelog, release notes, qualification
  report, documentation index, and offline documentation checks.
- Retains full public-API CI coverage on Linux x86-64, Windows x86-64, and
  Windows i386.

## Public API and compatibility

- New unit: `AlgebraLib.DenseDecompositions`.
- New triangular options:
  - `TDenseTriangle`
  - `TDenseDiagonal`
  - `TDenseTranspose`
- New entry points:
  - `SolveTriangular`
  - `FactorQR` and `FactorPivotedQR`
  - `LeastSquares` and `RankRevealingLeastSquares`
  - `FactorSVD` and `MinimumNormSolve`
  - `FactorSymmetricEigen` and `FactorHermitianEigen`
- New reusable QR, SVD, symmetric-eigen, and Hermitian-eigen handles for the
  mathematically applicable real/complex single/double scalar paths.
- Existing `IMatrix`, `TMatrixKit`, `IVector`, and typed 1.5 entry points are
  not removed, renamed, deprecated, or silently rerouted.
- Compatibility-to-typed migration remains opt-in and uses explicit deep
  copies.

## Tests and verification

Focused 1.6 tests cover:

- triangular variants, unit and non-unit diagonals, transpose and conjugate
  transpose, multiple right-hand sides, and singularity;
- QR reconstruction, orthogonality/unitarity, least-squares references,
  immutable factor snapshots, and factor reuse;
- CPQR permutation identities, exact and near rank deficiency, caller
  tolerances, diagnostics, and multiple right-hand sides;
- compact SVD reconstruction, ordering, tall/wide/complex shapes,
  rank-deficient and underdetermined minimum-norm references, and factor reuse;
- symmetric/Hermitian eigenpair residuals, orthogonality/unitarity, ordering,
  empty and singleton inputs, repeated spectra, and tiny-scale convergence;
- real/complex single/double operation parity;
- LU and Cholesky diagnostic solves, positive-definite selection, residuals,
  backward errors, and multiple right-hand sides; and
- invalid shape/structure, non-finite input, source immutability, allocation
  overflow, aliasing, and unchanged caller storage on failure through the
  retained typed-dense test suite.

Local verification completed:

- [x] 852 tests pass on Win64 normal and `-O3` configurations.
- [x] 852 tests pass with runtime checks enabled.
- [x] 852 tests pass with heap tracing; zero unfreed blocks are reported.
- [x] 852 tests pass on optimized Win32.
- [x] The Lazarus package builds with clean configuration profiles for Win64
  and Win32.
- [x] All 17 runnable examples compile and execute.
- [x] Searchable documentation builds; checks cover 35 Markdown pages, 17
  indexed examples, and 81 public 1.6 symbols.
- [x] The deterministic 1.6 benchmark compiles and runs at `-O3`.
- [x] A checksummed clean source archive compiles and runs the typed square
  solve and solver-selection examples offline.
- [x] `git diff --check` passes.

Linux is not locally executable from the Windows qualification host. The
repository CI runs the registered public API suite on Linux x86-64, Win64, and
Win32; the exact PR commit's Linux result remains a post-push merge check.

## Performance evidence

The local Windows x86-64 FPC 3.2.2 `-O3` qualification run recorded:

- `96 x 32` QR factorisation plus 20 reused four-RHS solves: 15 ms;
- five allocating QR least-squares convenience calls: 63 ms;
- `48 x 16` compact SVD plus a two-RHS minimum-norm solve: below the 1 ms
  timer resolution, with 8 sweeps; and
- `24 x 24` symmetric eigensystem: below the 1 ms timer resolution, with 7
  sweeps.

The run reported QR checksum `2.786934`, SVD checksum `2.917959`, and eigen
checksum `4.230000`. These deterministic values are reproducibility evidence,
not cross-library performance claims.

## Risk and review notes

- Review compact QR/SVD/eigen output shapes and the `A*P=Q*R` permutation
  convention against the design record.
- Review tolerance derivation, numerical-rank decisions, and the distinction
  between condition indicators and reciprocal condition estimates.
- Review scale-safe norm, residual, backward-error, and Jacobi-rotation logic
  on both SSE2 and Win32/x87 targets.
- Review complex conjugation, phase freedom, and Hermitian validation across
  both complex precisions.
- Review immutable factor ownership and fresh-result allocation for repeated
  solves.
- Review compatibility boundaries: no legacy algorithm is rerouted unless its
  shape, ordering, tolerance, error, and ownership contracts are equivalent.

## Out of scope

- Any 1.7.0 interpolation, fitting, optimisation, integration, nonlinear
  equation, or ODE work.
- Sparse, packed, or other structured storage and sparse direct solves.
- LDLT and other structure-specific factor families not required by 1.6.
- CG, MINRES, GMRES, BiCGSTAB, LSQR, preconditioners, linear operators,
  matrix-free solves, or partial eigensolvers.
- Nonsymmetric, generalized, polynomial, partial, or Schur eigensystems.
- Mutable factor updates/downdates, destructive factorisation, or a general
  public workspace framework.
- Automatic algorithm dispatch, parallel/SIMD/GPU kernels, or external
  BLAS/LAPACK bindings.
- Merging, tagging, and publishing the 1.6.0 release; those remain separate
  release-management steps.
