# 2.2 Nonsymmetric and Generalised Spectral Algebra

## 1. Real double Hessenberg reduction

**Status:** Implemented, PR #49 merged, and locally verified on Windows with
FPC 3.2.2. The aggregate preflight passed 108 gates with the benchmark skipped.

**Acceptance:** `ReduceHessenberg` returns defensive-copy `Q` and `H` factors
with `Q^T A Q = H`; `Q` is orthogonal and `H` is upper Hessenberg. Finite
square inputs are supported, edge dimensions are defined, and invalid inputs
raise `EDenseMatrixError`.

**Verify:** FPCUnit structure, similarity, orthogonality, scale, immutability,
and validation cases; full `TestRunner`; guide, example, and docs checks.

## 2. Complex double Hessenberg reduction

**Status:** Implemented locally on Windows with FPC 3.2.2. Focused dense
decomposition tests pass; full qualification and PR CI are pending.

**Acceptance:** `ReduceHessenberg` returns defensive-copy complex `Q` and `H`
factors with `Q^H A Q = H`; `Q` is unitary and `H` is upper Hessenberg.
Finite square inputs are supported, edge dimensions are defined, and invalid
inputs or unrepresentable reflector norms raise `EDenseMatrixError`.

**Verify:** FPCUnit structure, similarity, unitarity, scale, immutability, and
validation cases; full `TestRunner`; guide, example, and docs checks.

## 3. Real double Schur factorization

**Status:** Implemented locally; focused dense decomposition tests pass.
Windows release qualification passed 112 gates; PR CI is pending.

**Acceptance:** `FactorRealSchur` returns copied `Q` and `T` factors satisfying
`A = Q T Q^T`, with orthogonal `Q` and standardized real Schur blocks in `T`.
Blocks are not sorted. The bounded Francis iteration reports its step count and
raises `EDenseMatrixError` on invalid input, overflow, or non-convergence.

**Verify:** FPCUnit similarity, orthogonality, block form, scaling,
immutability, edge cases, and iteration-limit behavior; full test runner,
example and documentation checks, release qualification, and CI.

## Later slices

- [ ] Nonsymmetric eigenvalues and eigenvectors, ordering, residuals, and
  convergence/failure diagnostics.
- [ ] Generalized real/complex `A x = λ B x` reduction and solve contract.
