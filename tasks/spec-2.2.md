# Spec: 2.2 Nonsymmetric and Generalised Spectral Algebra

## Objective

Build native dense tools for nonsymmetric spectral problems in ordered,
validated slices. The first slice reduces a real double-precision square
matrix to upper Hessenberg form. This is the foundation for a real Schur
solver and later real nonsymmetric eigenvalue workflows.

The 2.2 roadmap also identifies complex Schur methods, generalised
`A x = λ B x` problems, and ordering, scaling, convergence, residual, and
failure contracts. They are not part of this first slice. Polynomial
eigenvalue problems and large-scale shift-invert infrastructure remain out of
scope unless separately designed.

## First-slice public contract

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

## Architecture and style

- Keep nonsymmetric spectral work in `AlgebraLib.DenseSpectral`, separate
  from the existing symmetric/Hermitian routines in
  `AlgebraLib.DenseDecompositions`.
- Use the existing mutable dense matrix handles as inputs and return the
  immutable-factor pattern already used by QR, SVD, and Hermitian factors.
- Implement the double-real path first. Complex double support will be a
  separately tested slice using unitary similarity; single precision remains
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
- Public names and matrix relation for later real/complex Schur and generalized
  eigenproblem slices require their own focused design update before APIs are
  added.
- Do not claim this first slice solves eigenvalues or reduces a matrix pair.

## Success criteria

The first slice provides the specified real-double API, stable Householder
reduction, structural and residual tests, documented limitations, and a
runnable example; it passes the focused and full supported test matrix.

## Open design points for later slices

- Real Schur form uses 1x1 and 2x2 diagonal blocks; its eigenvalue ordering and
  convergence reporting need a separate contract.
- Complex Schur and generalized QZ reductions need explicit ordering, scaling,
  and failure semantics before implementation.
