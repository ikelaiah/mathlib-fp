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

## Approved generalized real and complex eigenproblem slice

This slice adds dense generalized Schur reduction and right eigenpairs for
regular real-double and complex-double matrix pencils `A - λ B`. It preserves
generalized eigenvalues in homogeneous form so singular `B` and eigenvalues at
infinity do not require forming an unsafe quotient. It does not add left
eigenvectors, Schur reordering, condition estimates, or polynomial pencils.

### Public API and input contract

- Unit: `AlgebraLib.DenseSpectral`.
- Real entry points:
  `FactorRealGeneralizedSchur(const A, B: IDenseDoubleMatrix; const
  MaxIterations: SizeInt = 0)` and
  `FactorRealGeneralizedEigen(const A, B: IDenseDoubleMatrix; const
  MaxIterations: SizeInt = 0)`.
- Complex entry points:
  `FactorComplexGeneralizedSchur(const A, B: IDenseComplexMatrix; const
  MaxIterations: SizeInt = 0)` and
  `FactorComplexGeneralizedEigen(const A, B: IDenseComplexMatrix; const
  MaxIterations: SizeInt = 0)`.
- Both matrices must be non-nil, finite, square, and have matching dimensions.
  Inputs are not modified. Empty and 1x1 pairs are supported. Invalid inputs,
  non-finite/unrepresentable results, arithmetic breakdown, indeterminate
  generalized eigenvalues, or exhausted iteration budgets raise
  `EDenseMatrixError`; no partial result is returned.
- A nonzero `MaxIterations` is a positive limit on the Schur QR iterations of
  the transformed matrix; a negative value is invalid. Zero selects
  `100 * max(1,n)` iterations. `Iterations` reports iterations performed by
  the Schur stage. Deflation is scale-relative and dimension-aware.
- The supported mathematical input is a regular pencil: `det(A - λ B)` is not
  identically zero. The implementation does not promise an upfront numerical
  regularity test. If QZ yields a `(alpha,beta)=(0,0)` indeterminate value, it
  raises rather than labeling it as finite or infinite.

### Generalized Schur results

- `IDenseDoubleGeneralizedSchur` exposes `Size`, `Q`, `S`, `Z`, `T`,
  `Alpha`, `Beta`, and `Iterations`. `IDenseComplexGeneralizedSchur` exposes
  the same properties with complex matrices. Matrix and array accessors return
  defensive copies.
- Real factors satisfy `A = Q*S*Z^T` and `B = Q*T*Z^T`, with orthogonal `Q`
  and `Z`. `S` is upper quasi-triangular with isolated 1x1 and 2x2 diagonal
  blocks; `T` is upper triangular with nonnegative diagonal. Each 1x1 block
  represents one real generalized eigenvalue. Each 2x2 block pair represents
  an adjacent complex-conjugate pair.
- Complex factors satisfy `A = Q*S*Z^H` and `B = Q*T*Z^H`, with unitary `Q`
  and `Z`; `S` and `T` are upper triangular and the diagonal of `T` is real
  and nonnegative.
- Both real and complex results expose homogeneous eigenvalue pairs `(alpha,
  beta)`, where `A*v*beta = B*v*alpha`. The pair is scaled so
  `max(|alpha|, |beta|)=1`; `beta` is real and nonnegative. For real input,
  real eigenvalues have real `alpha`, conjugate values appear adjacently with
  positive imaginary part first, and paired `beta` values match. `beta=0`
  denotes an eigenvalue at infinity; finite `lambda` may be computed as
  `alpha/beta` when representable. Values remain in generalized Schur order;
  no sorting is performed.
- Empty pairs return empty eigenvalue arrays, identity `Q`/`Z`, and `S=A`,
  `T=B`. A 1x1 result follows the same factor relation and homogeneous-pair
  normalization.

### Generalized eigenpair results

- `IDenseDoubleGeneralizedEigen` and `IDenseComplexGeneralizedEigen` expose
  `Size`, `Alpha`, `Beta`, `RightEigenvectors`, `Residuals`, `Iterations`, and
  `Converged`. Eigenvectors are columns paired by index with `(alpha,beta)`;
  accessors return defensive copies. The real-input result uses complex
  eigenvectors for real and conjugate eigenvalues. The complex-input result
  uses complex eigenvectors.
- Each vector is normalized to unit 2-norm and satisfies the homogeneous
  equation `beta*A*v = alpha*B*v`. Its reported normalized backward residual
  is `||beta*A*v-alpha*B*v||_2 / ((|beta|*||A||_F + |alpha|*||B||_F)*||v||_2)`,
  evaluated with scaled arithmetic. If the denominator is zero, the residual
  is zero only when the numerator is zero; otherwise the operation fails.
- A successful result has `Converged=True`. Schur or vector-recovery failure
  raises `EDenseMatrixError`. Eigenvectors are not promised to be orthogonal
  or well-conditioned for defective or clustered spectra.

### Algorithm and validation

- Use a deterministic projective shift `γ` for which `C=A+γB` is numerically
  nonsingular, then solve `C*M=B` without forming an inverse. A regular
  `n x n` pencil has at most `n` singular shifts, so test the distinct real
  candidates `0..n`; raise `EDenseMatrixError` if finite precision makes every
  candidate unusable. Do not form `B^-1*A`; `B` may be singular.
- Reduce `M` with the existing real Schur factorization or an internal bounded
  complex shifted-QR Schur iteration. Write `M=Z*R_s*Z^H` and factor
  `C*Z=Q*R_c`; construct `S=R_c*(I-γR_s)` and `T=R_c*R_s`, rescaled by the
  common input scale. For real input, triangularize each 2x2 block of `T`
  with a right plane rotation; for complex input, use column phases to make
  the diagonal of `T` nonnegative real. This preserves both pencil
  reconstructions and the homogeneous eigenvalue pairs.
- Recover real-input right eigenvectors from the real Schur factor of `M`;
  recover complex-input vectors by scaled triangular back substitution in the
  complex Schur form. Keep real and complex implementations separately tested
  and keep single precision deferred.
- Validate reconstruction of both input matrices, orthogonality/unitarity of
  both vector factors, Schur structure, homogeneous eigenvalue/eigenvector
  equations, residuals, scale extremes, source/factor immutability, edge
  dimensions, invalid inputs, and iteration exhaustion. Include finite
  eigenvalues, zero eigenvalues, infinite eigenvalues from singular `B`, real
  conjugate pairs, complex matrices, and a deliberately indeterminate/singular
  pencil case.
- Run focused and full FPCUnit suites, normal/optimized/checked builds, docs
  and example checks, release qualification, and Linux/Windows CI before
  merge. No third-party runtime is added.

The generalized Schur forms and homogeneous `(alpha,beta)` representation
follow LAPACK [`DGGES`](https://www.netlib.org/lapack/explore-html/d7/d25/group__gges_ga556be4f39b39e5008c8eb36814aa7e20.html),
[`ZGGES`](https://www.netlib.org/lapack/explore-html/d7/d25/group__gges_ga4943e11fd632761e645ce1e5161f9f51.html),
and [`DGGEV`](https://www.netlib.org/lapack/explore-html/d9/d52/dggev_8f_source.html)
contracts. No LAPACK code or runtime is imported.
