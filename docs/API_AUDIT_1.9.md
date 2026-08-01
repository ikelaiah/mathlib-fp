# 1.9 public API documentation audit

This audit reconciles the shipped 1.9 declarations, implementation, guide,
examples, capability data, and focused tests. `tools/check_docs.py` also
compares every source-unit interface hash with
[`public-api-1.9.json`](public-api-1.9.json). The schema records declaration
owner and normalized signature, so overloaded routines and same-named members
are audited independently rather than collapsed into a name set.
The generated [`API_REFERENCE_1.9.md`](API_REFERENCE_1.9.md) renders all 2,880
of those exact declaration identities for human review.

| Surface | Contract fields checked | Evidence | Result |
| --- | --- | --- | --- |
| `AlgebraLib.SparseMatrices` | signatures, four scalar aliases, `SizeInt` zero-based shapes, CSR/CSC ordering, zero policy, deep-copy ownership, immutability, destination aliasing, exceptions, complexity | `TestSparseMatrices.pas`; `SparseLinearAlgebra.md` | Verified |
| Structured storage | diagonal/tridiagonal/band layout, rectangular shape, copy/mutation, products/conversions | `TestSparseMatrices.pas`; `SparseLinearAlgebra.md` | Verified |
| `AlgebraLib.LinearOperators` | dimensions, scalar kind, four-scalar ordinary/adjoint shapes, ownership enum, reentrancy, delegated action failures | `TestIterativeSolvers.pas`; `SparseLinearAlgebra.md` | Verified |
| Preconditioners | four-scalar identity/diagonal/IC(0)/ILU(0), pivot default `1.0e-14`, eligible structure, immutable factor ownership, repeated/concurrent application, exact in-place support, partial-view rejection, and failure recovery | `TestIterativeSolvers.pas`; `SparseLinearAlgebra.md` | Verified |
| `AlgebraLib.IterativeSolvers` | every method through every scalar facade, all overloads and defaults, square true-residual stopping, LSQR `||A^H(b-Ax)||_2` stopping, explicit convergence confirmation, refresh counts, statuses, breakdowns, products, cancellation/progress, partial iterates, exact/partial alias behavior, and atomic workspace ownership/recovery | `TestIterativeSolvers.pas`; `SparseLinearAlgebra.md` | Verified |
| `AlgebraLib.StructuredSolvers` | every factor family through every scalar facade, pivot default `1.0e-14`, multiple RHS, tridiagonal/band pivot behavior, sparse natural ordering/fill, immutable snapshots, reuse, concurrency, exact in-place support, partial-view rejection, and atomic failures | `TestStructuredSolvers.pas`; `SparseLinearAlgebra.md` | Verified |
| `AlgebraLib.PartialEigensystems` | two methods, all four scalar facades including single-complex Lanczos, option defaults/seed, target, result fields, residual/status, shift/target and real-restart limits | `TestPartialEigensystems.pas`; `SparseLinearAlgebra.md` | Verified |
| Sparse interchange | real/complex coordinate subset, four-scalar binary overloads, version/checksum/canonical validation, independent nonzero and per-axis dimension caps before shape-sized allocation, and stream result atomicity | `TestSparseInterchange.pas`; `Interchange.md`; `SparseLinearAlgebra.md` | Verified |
| `TMatrixKitSparse` | compatibility status, unchanged behavior, explicit conversion | migration example; `SparseLinearAlgebra.md` | Verified compatibility |
| Migration workflows | run-checked dense and sparse solves, fitting, interpolation, optimisation, DSP, and streaming statistics with explicit semantic differences | `23_api_migration_preview.pas`; `MIGRATING_TO_2.0_PREVIEW.md` | Verified preview only |
| 2.0 candidate | classification, candidate conventions, owner/kind/signature-aware freeze, overload preservation, exact generated reference, no 1.9 removals/default changes | `API_CANDIDATE_2.0.md`; API snapshot/reference; extractor regressions | Verified preview only |
| Documentation execution | all Pascal fences inventoried; all self-contained programs compiled and run; every output-producing runnable fence has checked exact/ordered output; release-facing examples check statuses and final markers | `test_doc_examples.py`; `check_doc_examples.py`; `check_example_output.py`; `QUALIFICATION_1.9.1.md` | Verified |
| Repeated-solve allocation | warm-up plus 20 `Into` solves, sampled peak and retained heap deltas, fixed 65,536-byte failure ceiling | `BenchmarkRunner.lpr`; `QUALIFICATION_1.9.0.md` | Verified on qualified Win64 host |

The audit found no stable 1.9 documentation/declaration mismatch. Operations
that explicitly densify, create fill, deep-copy, or retain caller storage are
identified at their point of use. Unsupported targets and scalability limits
are named in the guide and capability inventory rather than presented as
implemented.

There are no formal 1.9 deprecations. Compatibility entries therefore have no
deprecation deadline; their preferred typed replacements are demonstrated, not
silently substituted.
