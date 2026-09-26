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

**Status:** Implemented and merged as PR #50; CI passed.

**Acceptance:** `ReduceHessenberg` returns defensive-copy complex `Q` and `H`
factors with `Q^H A Q = H`; `Q` is unitary and `H` is upper Hessenberg.
Finite square inputs are supported, edge dimensions are defined, and invalid
inputs or unrepresentable reflector norms raise `EDenseMatrixError`.

**Verify:** FPCUnit structure, similarity, unitarity, scale, immutability, and
validation cases; full `TestRunner`; guide, example, and docs checks.

## 3. Real double Schur factorization

**Status:** Implemented and merged as PR #51; focused tests, Windows release
qualification (112 gates), and PR CI passed.

**Acceptance:** `FactorRealSchur` returns copied `Q` and `T` factors satisfying
`A = Q T Q^T`, with orthogonal `Q` and standardized real Schur blocks in `T`.
Blocks are not sorted. The bounded Francis iteration reports its step count and
raises `EDenseMatrixError` on invalid input, overflow, or non-convergence.

**Verify:** FPCUnit similarity, orthogonality, block form, scaling,
immutability, edge cases, and iteration-limit behavior; full test runner,
example and documentation checks, release qualification, and CI.

## Later slices

- [x] Nonsymmetric eigenvalues and eigenvectors, ordering, residuals, and
  convergence/failure diagnostics. Contract approved and implemented on
  `feat/2.2-real-nonsymmetric-eigen`; release qualification and PR CI are
  complete locally; PR CI is pending.
  - **Acceptance:** real-double input returns complex values and normalized
    right eigenvectors with stable order options, paired normalized backward
    residuals, and bounded Schur convergence diagnostics.
  - **Verify:** 977 FPCUnit tests, all 38 examples, 19 output contracts,
    documentation/API checks, and 114 Windows release-qualification gates
    passed. Linux/Windows PR CI is pending.
- [ ] Generalized real/complex `A x = λ B x` reduction and solve contract.
