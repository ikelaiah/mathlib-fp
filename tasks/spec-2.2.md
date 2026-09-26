# Spec: 2.2 Nonsymmetric and Generalised Spectral Algebra

## Objective

Build native dense tools for nonsymmetric spectral problems in ordered,
validated slices. The first slice reduces real and complex double-precision
square matrices to upper Hessenberg form. These reductions are foundations
for real Schur factorization and later nonsymmetric eigenvalue workflows.

The 2.2 roadmap also identifies complex Schur methods, generalised
`A x = λ B x` problems, and ordering, scaling, convergence, residual, and
failure contracts. They are not part of this first slice. Polynomial
eigenvalue problems and large-scale shift-invert infrastructure remain out of
scope unless separately designed.

## Real-double public contract

- Unit: `AlgebraLib.DenseSpectral`.
- Entry point: `ReduceHessenberg(const A: IDenseDoubleMatrix)`.
- Result interface: `IDenseDoubleHessenberg`, with `Q` and `H` accessors.
- `A` must be a finite, square `IDenseDoubleMatrix`. Nil, rectangular, or
  non-finite inputs raise `EDenseMatrixError`. The input is not modified.
- The factor satisfies `Q^T * A * Q = H`; `Q` is orthogonal and `H` is upper
  Hessenberg (entries below the first subdiagonal are zero).
- `Q` and `H` are full `n x n` matrices. Accessors return deep copies, so
  callers cannot mutate the stored factor. Empty and 1x1 inputs return identity
  `Q` and `H=A`.
- The implementation is deterministic and uses Householder similarity
  transformations. It has no convergence limit: each reflector is applied in
  a fixed finite sequence. If a computed factor becomes non-finite, raise
  `EDenseMatrixError` instead of returning a corrupted factor.
- Complexity target: `O(n^3)` arithmetic and `O(n^2)` storage.

The numerical design follows LAPACK's documented Hessenberg reduction
contract and Householder similarity method; no LAPACK code is imported. See
[`DGEHRD`](https://www.netlib.org/lapack/explore-html/d2/d28/group__gehrd_ga74cea8f05a014cca243674999f71c238.html).

## Complex-double public contract

- Overload `ReduceHessenberg(const A: IDenseComplexMatrix)` in
  `AlgebraLib.DenseSpectral`.
- Return `IDenseComplexHessenberg`, exposing full-size complex `Q` and `H`.
- Require a finite square input, leave it unchanged, and raise
  `EDenseMatrixError` for nil, rectangular, non-finite, or unrepresentable
  reflector norms.
- The factor satisfies `Q^H * A * Q = H`; `Q` is unitary and `H` is upper
  Hessenberg. Accessors return deep copies. Empty and 1x1 matrices preserve the
  same identity-factor behavior as the real path.
- Use deterministic complex Householder similarity transforms. Scale the
  norm computation to support representable values across the double range;
  reject non-finite factors.

This follows the documented complex Hessenberg reduction contract in
[`ZGEHRD`](https://www.netlib.org/lapack/explore-html/d2/d28/group__gehrd_ga4de4b424a4c7b0a78f7138a94ec54671.html).

## Real Schur factorization contract

- Unit: `AlgebraLib.DenseSpectral`.
- Entry point: `FactorRealSchur(const A: IDenseDoubleMatrix; const
  MaxIterations: SizeInt = 0)`; `MaxIterations=0` selects the documented
  default of `100 * max(1, A.Rows)` Francis double-shift steps. A negative
  limit is invalid.
- Result interface: `IDenseDoubleRealSchur`, exposing `Size`, `Q`, `T`, and
  `Iterations`. `Q` and `T` accessors return defensive copies.
- Require finite square input, leave it unchanged, and raise
  `EDenseMatrixError` for invalid input, arithmetic outside the finite range,
  or failure to converge within the iteration limit. Do not return a partial
  Schur factor after failure.
- The factor satisfies `A = Q * T * Q^T`; `Q` is orthogonal. `T` is upper
  quasi-triangular: entries below the first subdiagonal are zero, and every
  nonzero subdiagonal entry belongs to an isolated 2x2 diagonal block.
- A 1x1 diagonal block represents a real eigenvalue. A 2x2 diagonal block
  represents a complex-conjugate pair and is standardized with equal diagonal
  entries and opposite-sign off-diagonal entries. Blocks are not sorted.
- Empty and 1x1 inputs return identity `Q` and `T=A`, with zero iterations.
  The implementation first calls real Hessenberg reduction, then applies
  deterministic implicit Francis double-shift QR steps while accumulating
  Schur vectors.
- Deflation uses a documented scale-relative floating-point threshold.
  `Iterations` counts performed double-shift steps. Every successful result is
  converged; exhausting the limit raises rather than exposing a partial factor.
- Complexity target is `O(n^3)` arithmetic and `O(n^2)` storage.

The matrix relation, real 1x1/2x2 block structure, standard form for complex
pairs, and accumulated Schur vectors follow LAPACK's `DHSEQR` contract. This
API uses a bounded iteration budget and exception-on-failure behavior for the
native library. [`DHSEQR`](https://www.netlib.org/lapack/explore-html/d9/dc6/group__hseqr_ga62c3f96d2f67f96d6dc10334e118e451.html).

## Architecture and style

- Keep nonsymmetric spectral work in `AlgebraLib.DenseSpectral`, separate
  from the existing symmetric/Hermitian routines in
  `AlgebraLib.DenseDecompositions`.
- Use the existing mutable dense matrix handles as inputs and return the
  immutable-factor pattern already used by QR, SVD, and Hermitian factors.
- Implement real and complex double paths as separately tested slices using
  orthogonal and unitary similarity respectively; single precision remains
  deferred until the double paths are qualified.
- Add no runtime dependency. Use the existing FPCUnit `TestRunner` and dense
  matrix factories. The test suite will not require a numerical library.

## Validation and numerical evidence

- Verify exact Hessenberg structure on a nontrivial dense matrix.
- Verify the similarity reconstruction `Q^T A Q = H` and orthogonality
  `Q^T Q = I` with scale-aware residual checks.
- Verify empty, 1x1, and already-Hessenberg inputs.
- Verify source and factor immutability, and rejection of nil, nonsquare, and
  non-finite input.
- Run the focused dense-decomposition tests, then the full normal,
  optimized, and checked FPC test suites. Run docs and example checks after
  adding the public guide/example slice.
- CI must pass on supported Linux and Windows runners before merge.

## Boundaries

- Always retain current dense solver APIs and avoid mandatory third-party
  runtimes.
- Complex Schur and generalized eigenproblem slices still require their own
  focused design update before APIs are added.
- Do not claim this first slice solves eigenvalues or reduces a matrix pair.

## Success criteria

The first slice provides the specified real-double API, stable Householder
reduction, structural and residual tests, documented limitations, and a
runnable example; it passes the focused and full supported test matrix.

## Open design points for later slices

- Complex Schur and generalized QZ reductions need explicit ordering, scaling,
  and failure semantics before implementation.

## Approved real nonsymmetric eigensystem slice

This proposal scopes the next feature to a real-double input matrix and
complex-double right eigenvectors. It builds on `FactorRealSchur`; it does not
add complex Schur or left eigenvectors.

- Unit: `AlgebraLib.DenseSpectral`.
- Entry point: `FactorRealEigen(const A: IDenseDoubleMatrix; const
  Ordering: TRealEigenvalueOrdering = reoSchurOrder; const MaxIterations:
  SizeInt = 0)`.
- Return `IDenseDoubleRealEigen`, exposing `Size`, `Eigenvalues:
  TComplexArray`, `RightEigenvectors: IDenseComplexMatrix`, `Residuals:
  TDoubleArray`, `Iterations`, and `Converged`. Matrices and arrays returned
  from accessors are defensive copies. Eigenvectors are normalized columns
  paired by index with eigenvalues.
- Require finite square input; leave it unchanged. Empty and 1x1 inputs are
  supported. Nil, nonsquare, non-finite input, non-finite computed output, and
  exhausted Schur iteration budget raise `EDenseMatrixError`; no partial
  eigensystem is returned. `MaxIterations` follows `FactorRealSchur` semantics.
- Every real eigenvalue is represented with zero imaginary part. A conjugate
  pair is returned in adjacent columns with the positive-imaginary member
  first. `reoSchurOrder` preserves the real Schur block order. `reoRealPart`
  orders by increasing real part; `reoMagnitude` orders by increasing complex
  magnitude. Equal keys retain Schur order, and all corresponding vectors are
  permuted with their values.
- Right eigenvectors satisfy `A*v = lambda*v`. `Residuals[i]` reports the
  normalized backward residual
  `||A*v-lambda*v||_2 / ((||A||_F + |lambda|) * ||v||_2)` using scaled norm
  evaluation; define it as zero when the denominator is zero (then the exact
  residual is also zero). Each eigenvector is normalized to unit 2-norm. No
  orthogonality or well-conditioned eigenbasis is promised.
- `Iterations` reports the Francis double-shift steps performed by the Schur
  stage. A successful result has `Converged=True`; non-convergence is an
  exception, consistent with the Schur API. Arithmetic breakdown while
  recovering an eigenvector also raises `EDenseMatrixError`.
- Derive eigenvalues from the standardized 1x1/2x2 real Schur blocks, recover
  right eigenvectors by backward substitution in Schur form, and transform
  them by `Q`. Complexity target is `O(n^3)` arithmetic and `O(n^2)` storage.

The real eigenvalue/eigenvector conventions and conjugate-pair representation
follow LAPACK's `DGEEV` contract. The library adds stable ordering options,
residual diagnostics, and exception-on-failure semantics. See
[`DGEEV`](https://www.netlib.org/lapack/explore-html/d4/d68/group__geev_ga7d8afe93d23c5862e238626905ee145e.html).

Implementation tasks and tests are tracked in `plan-2.2.md` and
`todo-2.2.md`. Generalized eigenproblems, left eigenvectors, complex input, and
Schur reordering remain out of scope for this slice.
