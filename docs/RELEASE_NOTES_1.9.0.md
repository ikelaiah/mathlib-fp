# mathlib-fp 1.9.0

Released 2026-08-01.

Version 1.9.0 adds a complete portable typed path for matrices that are sparse,
compactly structured, or available only through a product. It is an additive
release: maintained 1.x APIs and defaults remain available.

## User-visible additions

- `AlgebraLib.SparseMatrices`: immutable validated CSR/CSC for single/double
  real and complex scalars, deterministic triplet construction, explicit
  stored-zero policy, sparse arithmetic/products/conversions, and compact
  diagonal/tridiagonal/band storage.
- `AlgebraLib.LinearOperators`: one typed ordinary/adjoint product contract for
  sparse, structured, dense, and user-supplied matrix-free problems; explicit
  ownership and reentrancy; identity, diagonal, IC(0), and ILU(0)
  preconditioners.
- `AlgebraLib.IterativeSolvers`: CG, MINRES, restarted GMRES, BiCGSTAB, and
  LSQR for all four scalar paths, with shared options/results, true-residual
  reporting, LSQR normal-residual convergence, explicit confirmation,
  cancellation/progress, refresh counts, breakdown reasons, and reusable
  workspaces.
- `AlgebraLib.StructuredSolvers`: reusable pivoted tridiagonal factors,
  compact band factors, and an explicitly selected natural-order sparse LU
  baseline with pivot/fill diagnostics and multiple-RHS solves.
- `AlgebraLib.PartialEigensystems`: deterministic restarted Lanczos and
  Arnoldi for largest-magnitude selected eigenpairs, including independently
  recomputed residuals.
- `MathBase.Interchange`: Matrix Market coordinate double-real/double-complex
  sparse exchange and checksummed versioned CSR/CSC binary interchange for all
  four scalar kinds, with independent stored-nonzero and per-axis dimension
  limits checked before shape-sized allocation.
- An end-to-end sparse Matrix Market/preconditioned-CG example and a
  run-checked candidate-2.0 migration preview covering dense/sparse solves,
  fitting, interpolation, optimization, DSP, and streaming statistics.
- A complete classified 1.9 public-API snapshot and generated declaration
  reference keyed by unit, owner, kind, name, and normalized signature, with
  per-unit interface SHA-256 enforcement.
- Compiler-backed execution of every self-contained published Pascal example;
  all 1.9 release-facing Pascal fences are required to remain self-contained.

The [sparse linear-algebra guide](SparseLinearAlgebra.md) documents every
representation, solver-selection rule, residual formula, default, status,
ownership/aliasing contract, operation cost, reuse path, and stable limit.

## Compatibility and migration

`TMatrixKitSparse` is unchanged and remains a compatibility path. Its legacy
storage is not silently replaced by CSR/CSC; the migration example performs an
explicit value copy and chooses a zero policy. No maintained public identifier
is removed or renamed.

The [candidate 2.0 contract](API_CANDIDATE_2.0.md) and
[migration preview](MIGRATING_TO_2.0_PREVIEW.md) are documentation and
compile-checked 1.9 runway only. They do not activate breaking 2.0 behavior.
There are no formal deprecations in 1.9.0.

## Numerical and scalability evidence

The focused suites compare all four scalar storage/operator paths with typed
dense oracles, execute every iterative method for every scalar, and cover
success, iteration limit, cancellation, invalid structure, singularity, and
numerical breakdown. Matrix Market and binary tests cover round trips plus
malformed coordinates, duplicates, explicit zeros, version/kind mismatches,
checksum corruption, truncation, nonzero limits, and dimension limits.

A 20,000-dimensional matrix-free test is a regression tripwire against an
accidental full dense allocation (which would require 3.2 GB of binary64
values). Matrix-free construction validates each vector axis independently,
so this linear-storage path is not rejected on Win32 because the hypothetical
dense product exceeds its address space. The Win64 FPC 3.2.2 `-O3`
qualification benchmark additionally ran:

- a 100,000-by-100,000 CSR system with 100,000 nonzeros in 125 ms initially,
  then 20 warmed solves in 2,109 ms, one CG iteration/three products per solve,
  zero final true residual, approximately 3,300,041 retained scalar/index
  slots, and zero sampled repeated-solve peak/retained heap growth;
- a 200,000-dimensional matrix-free system in 172 ms initially, then 20 warmed
  solves in 3,484 ms, one CG iteration/three products per solve, zero retained
  operator values, zero final true residual, approximately 5,800,041 retained
  scalar slots, and zero sampled repeated-solve peak/retained heap growth.

Both used prepared `Into` workspaces and allocated zero elements proportional
to a full dense matrix. Repeated-solve heap measurements use a fixed 65,536-byte
regression ceiling.
Timing and heap figures are workload-, compiler-, platform-, and
machine-specific observations, not universal speed or memory guarantees. Full
commands and conditions are in the
[1.9 qualification report](QUALIFICATION_1.9.0.md).

## Important limits

- Sparse kernels are portable serial paths. Distributed, out-of-core, GPU,
  vendor-library, parallel, and SIMD sparse execution are not included.
- The general band factor does not pivot. Sparse LU uses natural ordering with
  row pivoting; it has no fill-reducing symbolic ordering and fill can be large.
- Solvers validate types and shapes, not the caller's symmetry, definiteness,
  or conditioning model. LSQR is unpreconditioned in 1.9.
- Partial eigensystems target largest magnitude only. There is no shift-invert,
  interior target, generalized, full nonsymmetric, Schur, or polynomial path.
- Matrix Market sparse text is coordinate `real general`/`complex general` in
  double precision and forbids duplicate and explicit-zero entries.
- Advanced DSP, survival/state-space, implicit ODE, and mixed-integer/global
  optimisation families remain outside this focused release.

Every remaining baseline gap is recorded in
[`capabilities.json`](capabilities.json).
