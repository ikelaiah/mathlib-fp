# mathlib-fp 2.4.0

Version 2.4.0 adds a fill-reducing sparse direct workflow on top of the
existing sparse LU baseline. Symbolic analysis is reusable across matrices
with the same canonical sparsity pattern, while numeric factors remain
reusable across multiple right-hand sides.

## Sparse direct solving

- Added deterministic minimum-degree ordering over the symmetrized sparse
  pattern, with natural ordering retained for compatibility and comparison.
- Added reusable symbolic analysis and numeric factorization for general
  square CSR and CSC matrices across all four scalar families.
- Preserved sparse storage through ordering and factorization, and reports
  input, factor, and fill nonzero counts, pivot interchanges, and minimum pivot
  magnitude.
- Added pattern matching so changed values can reuse an analysis while changed
  coordinates are rejected explicitly.
- Kept the existing `FactorSparseLU` call source-compatible; it uses natural
  ordering.

Multifrontal and supernodal algorithms, distributed and out-of-core solvers,
parallel and GPU execution, and automatic iterative/direct selection remain
outside this release.

## Qualification

See the [v2.4.0 qualification record](qualification.md) for correctness,
storage, target, and performance evidence.
