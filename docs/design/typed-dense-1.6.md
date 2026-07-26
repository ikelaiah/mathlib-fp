# Typed dense decompositions and direct solvers: 1.6 design record

Status: accepted for the 1.6.0 implementation. This record extends, and does
not replace, the [1.5 typed-dense contract](typed-dense-1.5.md).

## Boundary

The stable 1.6 surface contains reusable triangular, LU, Cholesky, QR,
column-pivoted QR (CPQR), compact SVD, and full symmetric/Hermitian
eigensystem operations. It contains the square, positive-definite,
least-squares, rank-revealing, and minimum-norm solves enabled by those
factors.

Sparse and structured storage, LDLT, iterative and matrix-free solvers,
partial or nonsymmetric eigensystems, mutable factor updates, destructive
factorisation, public workspaces, automatic dispatch, parallel/SIMD kernels,
GPU support, and external BLAS/LAPACK bindings are not part of 1.6.

## Ownership, mutation, and thread safety

- A factor clones its input before decomposition and owns all factor storage.
  Later source mutation cannot affect it.
- Accessors return fresh matrices or arrays. They do not expose mutable factor
  storage.
- Factorisation and solve calls never overwrite the coefficient matrix or
  right-hand side. Validation completes before a result matrix is allocated or
  any caller-visible destination is changed.
- A factor contains no last-result or shared workspace state. Concurrent reads
  and solves through one factor are safe provided callers do not concurrently
  mutate the same input matrix object.
- Public allocating calls allocate the factor snapshot, compact factor data,
  and result. Repeated solves reuse the O(mn) or O(n²) factor data but allocate
  a fresh result and private O(mr) solve workspace for `r` right-hand sides.
  No public workspace or destructive expert form is added in 1.6.

## Scalar parity

`Single`, `Double`, `TSingleComplex`, and `TComplex` have matching triangular,
LU, Cholesky, QR, CPQR, and SVD operation sets. Real symmetric eigensystems
apply to `Single` and `Double`; Hermitian eigensystems apply to the two complex
types. Real arithmetic treats transpose and conjugate transpose identically.
No typed factor converts through `IMatrix`, nested `Double` arrays, or another
public scalar type.

Intermediate real magnitudes use `Double` so scale and diagnostic arithmetic
does not lose the range of a `Single` input. Matrix entries and all factor
arithmetic remain in the factor's declared scalar type.

## Shapes and compact forms

Indices are zero based and use `SizeInt`, as in 1.5.

- Triangular and LU/Cholesky coefficient matrices are `n x n`. A right-hand
  side is `n x r`; the result is `n x r`. `r = 0` and `n = 0` are supported.
- Unpivoted and column-pivoted QR accept `m x n` with `m >= n`. Compact
  `Q` is `m x n`, `R` is `n x n`, and `A*P = Q*R` for CPQR.
- Compact SVD accepts every `m x n` shape. With `p = min(m,n)`, `U` is
  `m x p`, singular values have length `p`, and `V` is `n x p`.
  Reconstruction is `A = U*diag(S)*V^H`.
- A least-squares right-hand side is `m x r` and its solution is `n x r`.
  Unpivoted QR requires numerical full rank. CPQR returns a basic
  rank-revealing solution and reports rank deficiency; it does not promise the
  minimum-norm solution.
- SVD minimum-norm solves accept `m x r` and return the unique Moore-Penrose
  minimum-norm solution of shape `n x r` at the selected numerical rank.
- A symmetric/Hermitian input is `n x n`; eigenvalues have length `n` and
  eigenvectors form `n x n` columns.

Empty factors and empty right-hand-side columns are valid. Allocation-size
checks remain those of `AlgebraLib.DenseMatrices`; factor implementations do
not perform unchecked dimension products.

## Triangles, pivots, and permutations

Triangular solves explicitly select lower or upper storage, unit or non-unit
diagonal, and ordinary, transposed, or conjugate-transposed operation. Entries
outside the selected triangle are ignored. A non-unit zero/numerically-zero
diagonal is an error before a result is returned.

LU keeps the 1.5 row permutation: `P*A = L*U`; `Permutation[i]` is the source
row now occupying factor row `i`.

CPQR uses `A*P = Q*R`; `Permutation[j]` is the source column occupying factor
column `j`. The returned array is a copy.

## Orthogonal/unitary and spectral conventions

Householder reflectors use a scale-safe Euclidean norm and choose the leading
factor entry opposite the input phase. `Q` is an explicit compact
orthogonal/unitary matrix. Individual column signs/phases are not stable API
data; reconstruction and orthogonality are.

Singular values are finite, nonnegative, and descending. Zero-singular-value
vectors may use any deterministic orthonormal completion. Singular-vector
signs/phases and bases inside repeated singular subspaces are unspecified.

Eigenvalues are ascending. Eigenvectors are normalized columns. Their
individual signs/phases and the basis chosen inside a repeated or clustered
eigenspace are unspecified. Correctness is defined by orthogonality/unitarity,
the eigenpair residual, and invariant-subspace behavior rather than elementwise
comparison of vectors.

## Tolerances, rank, conditioning, and convergence

A tolerance argument is either negative, selecting the default, or finite and
nonnegative. The default rank threshold is

`epsilon * max(m,n) * leading_scale`,

where `leading_scale` is the largest pivoted `R` diagonal magnitude or singular
value. An exact zero scale has rank zero. User tolerances have the same
absolute units as the relevant diagonal or singular value. Definiteness keeps
the separate scale-aware Cholesky test from 1.5. LU pivot singularity, QR/SVD
rank, and eigensystem convergence do not share an unexplained epsilon.

`ConditionIndicator` is an inexpensive factor-appropriate lower-is-worse
ratio: smallest accepted to largest relevant LU pivot, Cholesky diagonal, QR
diagonal, or singular value. It is not a reciprocal condition estimate with a
formal error bound and never forms an inverse.

Solve diagnostics report method, numerical rank, rank deficiency, tolerance,
condition indicator, residual norm, and normalized backward error

`||B-A*X||F / (||A||F*||X||F + ||B||F)`.

Norm accumulation is scale safe. A zero numerator and denominator reports zero.

The portable symmetric/Hermitian eigensolver uses deterministic cyclic Jacobi
sweeps. Convergence means the largest off-diagonal magnitude is at most
`epsilon * max(1,n) * max(abs(diagonal))` (or is exactly zero when that scale
is zero). Failure to converge within
the documented sweep limit raises `EDenseMatrixError`; no partial eigensystem
is returned. `Converged` is consequently true for every returned stable factor,
while `Sweeps` remains inspectable.

## Errors and finite-input policy

Nil matrices, invalid shapes/options/tolerances, non-finite entries,
non-Hermitian input, singular triangular/LU factors, non-positive-definite
Cholesky input, full-rank QR solve requests on rank-deficient factors, and
eigensystem non-convergence raise `EDenseMatrixError`. Messages name the
operation, violated condition, and relevant shape/index/value. Inputs remain
unchanged after every failure.

## Compatibility

`IMatrix`, `IVector`, `TMatrixKit`, and their existing decomposition entry
points remain source compatible and are still the compatibility API. The typed
implementation is additive. A compatibility algorithm is routed through typed
code only after its shape, ordering, tolerance, error, ownership, and numerical
behavior have dedicated equivalence tests; 1.6 performs no release-wide legacy
rewrite. Conversion to the typed API remains explicit and retains the copy and
precision rules documented by the 1.5 migration guide.

## Algorithm provenance

- QR and CPQR: Householder reflectors with greedy largest remaining column-norm
  pivoting, following Golub and Van Loan, *Matrix Computations*, 4th ed.,
  sections 5.2 and 5.4.
- Compact SVD: deterministic one-sided Jacobi orthogonalisation, following
  Drmač and Veselić, “New fast and accurate Jacobi SVD algorithm. I,”
  *SIAM Journal on Matrix Analysis and Applications* 29(4), 2008. The
  implementation operates directly in each public scalar type.
- Symmetric/Hermitian eigen: cyclic two-sided Jacobi rotations, following
  Demmel, *Applied Numerical Linear Algebra*, section 5.3.

These portable Pascal paths are the reference implementations. No runtime
library, generated binary, service, or network access is involved.
