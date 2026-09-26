# Implementation plan: 2.2 Nonsymmetric Spectral Algebra

## Overview

Build dense nonsymmetric spectral capabilities from reusable reductions toward
Schur and eigenvalue workflows. The current increment implements the real and
complex double-precision Hessenberg reductions defined in
[spec-2.2.md](spec-2.2.md).

## Architecture decisions

- Put the API in `AlgebraLib.DenseSpectral`; symmetric/Hermitian methods stay
  in `AlgebraLib.DenseDecompositions`.
- Return a factor interface with defensive-copy accessors for `Q` and `H`.
- Use unblocked Householder reflectors for real-double orthogonal and
  complex-double unitary similarity transforms.
- Reject invalid/non-finite input and computed non-finite output with
  `EDenseMatrixError`.

## Task list

### Phase 1: Contract and tests

- [x] Freeze `ReduceHessenberg` names and `Q^T A Q = H` convention in the spec.
- [x] Add FPCUnit checks for structure, reconstruction, orthogonality,
  immutability, edge dimensions, and invalid input.
- [x] Run the focused test and confirm the new API test fails to compile before
  implementation.

### Phase 2: Implementation

- [x] Implement scaled-norm Householder generation and two-sided similarity
  updates for real `Double`.
- [x] Accumulate orthogonal `Q` and expose cloned `Q` / `H` matrices.
- [x] Verify finite outputs and retain source immutability.
- [x] Run focused tests and refactor only while the slice stays green.

### Phase 3: User-facing documentation

- [x] Add a guide section with the matrix relation, limits, and one use case.
- [x] Add a small runnable example and output contract.
- [x] Mark general nonsymmetric eigenproblems as in development in the
  capability inventory without implying an eigenvalue solver exists.

### Checkpoint: First slice

- [x] Focused and full FPC tests pass in normal, optimized, and checked modes.
- [x] Examples, docs, and inventory checks pass.
- [x] Final diff review finds no API-contract mismatch.
- [ ] Linux and Windows CI pass before merge.

### Phase 4: Complex-double increment

- [x] Specify `Q^H A Q = H` and complex input/error behavior.
- [x] Add red FPCUnit tests for structure, reconstruction, unitarity,
  immutability, scale, dimensions, and invalid input.
- [x] Implement scaled-norm complex Householder transformations.
- [x] Add the complex example and update the guide and capability inventory.
- [ ] Run full qualification and review the final diff before PR.
- [ ] Linux and Windows CI pass before merge.

### Phase 5: Real Schur factorization (contract approved)

- [x] Confirm the `A = Q*T*Q^T` factor API, real Schur block form, and block
  ordering behavior in `spec-2.2.md`.
- [x] Add focused tests for reconstruction, orthogonality, 1x1/2x2 block
  structure, edge inputs, immutability, scaling, and iteration-limit failure.
- [x] Implement Hessenberg-based implicit Francis double-shift iteration,
  deflation, and accumulated Schur vectors.
- [x] Document the block semantics and add a runnable real Schur example.
- [x] Run focused tests, all qualification gates, and the final diff review.
- [ ] Linux and Windows CI pass before merge.

### Phase 6: Real nonsymmetric eigenpairs (contract approved)

- [x] Add tests for real and conjugate eigenpairs, stable ordering, normalized
  residuals, defensive copies, empty/singleton matrices, invalid inputs, and
  Schur iteration-limit failure.
- [x] Expose the complex eigenvalue/right-eigenvector result interface and
  ordering enum from `AlgebraLib.DenseSpectral`.
- [x] Recover eigenvectors from the real Schur form and accumulate through
  Schur vectors, with scaled arithmetic and finite-result validation.
- [x] Add a runnable example and update the dense linear algebra guide,
  capability summary, changelog, and 2.2 task status; keep the published 2.0
  API snapshot frozen.
- [x] Run focused and full qualification checks; review the final diff.
- [ ] Linux and Windows CI pass before merge.

### Phase 7: Generalized real and complex eigenproblems (contract approved)

- [x] Approve the generalized Schur and eigenpair contract in `spec-2.2.md`.
- [x] Add tests for real and complex generalized Schur reconstruction,
  orthogonality/unitarity, Schur structure, homogeneous `(alpha,beta)` values,
  finite/zero/infinite eigenvalues, conjugate pairs, and singular-pencil
  behavior.
- [x] Implement a bounded projective-shift/Schur reduction for real and
  complex double precision, accumulating both vector factors without forming
  `B^-1*A`.
- [x] Recover normalized right generalized eigenvectors and scaled residuals;
  verify finite, infinite, and conjugate-pair cases.
- [x] Add examples and guide/capability/changelog updates without changing the
  frozen 2.0 API snapshot.
- [x] Run focused/full qualification and review the final diff.
- [x] Pass Linux and Windows CI before merge.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Unstable reflector norms at very large or tiny scales | Use a scaled sum-of-squares norm; test difficult scales and finite-output behavior. |
| Complex Householder conventions differ from the real path | State the conjugate-transpose relation explicitly and test reconstruction and unitarity. |
| Dense transformations violate the similarity relation through indexing errors | Test both reconstruction and orthogonality on independent nonsymmetric inputs. |
| Schur iteration stalls on clustered or badly scaled spectra | Use scale-relative deflation, a bounded iteration count, and raise a clear domain error when the budget is exhausted. |
| Repeated or clustered eigenvalues make back substitution ill-conditioned | Scale each solve step, regularize near-zero pivots relative to Schur scale, and report per-vector backward residuals; do not promise an orthogonal or well-conditioned eigenbasis. |
| Singular `B` makes direct `B^-1*A` reduction invalid and eigenvalue quotients overflow | Use a projective shift `A+γB` and expose normalized homogeneous `(alpha,beta)` pairs, including `beta=0` infinite eigenvalues. |
| A shifted coefficient matrix is ill-conditioned | Try deterministic shifts, rely on pivoted LU checks, and raise `EDenseMatrixError` if no candidate is numerically usable. |
| Irregular pencils produce indeterminate eigenvalues | State regular-pencil input semantics and raise if QZ returns an indeterminate `(0,0)` pair; do not silently emit a quotient. |

## Dependencies

Both reductions depend only on typed dense matrices and standard FPC math.
Schur iteration depends on these results; generalized reductions need a
separate approved contract, now drafted in `spec-2.2.md`.
