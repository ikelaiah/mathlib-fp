# Implementation plan: 2.2 Nonsymmetric Spectral Algebra

## Overview

Build dense nonsymmetric spectral capabilities from reusable reductions toward
Schur and eigenvalue workflows. This branch implements only the first real
double-precision Hessenberg reduction slice defined in
[spec-2.2.md](spec-2.2.md).

## Architecture decisions

- Put the API in `AlgebraLib.DenseSpectral`; symmetric/Hermitian methods stay
  in `AlgebraLib.DenseDecompositions`.
- Return a factor interface with defensive-copy accessors for `Q` and `H`.
- Use unblocked Householder reflectors and explicit real-double operations for
  this first slice. Add complex precision in a later independently validated
  increment.
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

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Unstable reflector norms at very large or tiny scales | Use a scaled sum-of-squares norm; test difficult scales and finite-output behavior. |
| Complex Householder conventions differ from the real path | Keep complex implementation out of this increment and specify it separately. |
| Dense transformations violate the similarity relation through indexing errors | Test both reconstruction and orthogonality on independent nonsymmetric inputs. |

## Dependencies

The real reduction depends only on typed dense matrices and standard FPC math.
Real Schur iteration depends on this result; later complex and generalized
reductions depend on a separate contract.
