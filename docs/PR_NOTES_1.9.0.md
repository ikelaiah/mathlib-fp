# PR: Scalable linear algebra and API convergence for 1.9.0

## Summary

This change implements only the active 1.9.0 milestone: typed structured/sparse
storage, stored/matrix-free operators, iterative solvers and preconditioners,
reusable structured/sparse direct factors, partial eigensystems, sparse
interchange, and the candidate-2.0 migration runway. It does not implement any
2.0 breaking change or later numerical family.

The implementation is native Free Pascal and adds no third-party runtime,
foreign binary, service, network dependency, global registry, GPU/vendor
requirement, or parallel/SIMD ABI.

## Design discipline

The [1.9 design record](design/sparse-iterative-1.9.md) was written before the
new public storage/operator types. It fixes indexing, checked shape arithmetic,
ownership, mutation, aliasing, failure atomicity, scalar support, operator
reentrancy, stopping formulas, diagnostics, compatibility, and explicit
non-goals.

The existing `TMatrixKitSparse` surface is preserved. The typed path is
additive and any conversion is explicit.

## Reviewable implementation slices

1. LSQR now converges inconsistent least-squares systems on explicitly
   confirmed `||A^H(b-Ax)||_2`, while still reporting the nonzero true residual.
2. Sparse text/binary loads independently bound nonzeros and each shape axis
   before builder or outer-pointer allocation.
3. The API snapshot is owner/kind/signature-aware, preserves overloads, and
   generates an exact declaration reference with extractor regressions.
4. The migration preview executes and checks dense/sparse solves, fitting,
   interpolation, optimization, DSP, and statistics.
5. Compiler-backed documentation checks inventory Pascal fences and compile/run
   every self-contained program; release-facing 1.9 fences must be runnable.
6. Factor, preconditioner, and workspace contracts have explicit reuse,
   exact-in-place, partial-alias, mutation, concurrency, and failure tests.
7. Sparse adjoints, all five solvers, all preconditioner/direct-factor
   families, and partial spectra execute through the four scalar facades.
8. Warming plus 20 repeated `Into` solves now measure peak and retained heap
   deltas and enforce a fixed 65,536-byte regression ceiling.
9. Guides, capability data, release notes, the declaration audit, examples,
   and qualification evidence use the same limits and claims.
10. Local normal/optimized/checked, docs, examples, package, benchmark, and
    clean-archive gates are recorded separately from remote Win32/Linux jobs.

## Completion-gate mapping

| Gate | Evidence |
| --- | --- |
| End-to-end sparse workflow | `examples/22_sparse_end_to_end.pas` assembles, Matrix Market round-trips, constructs IC(0), solves without densification, and interprets diagnostics |
| Scalar/operator coverage | all five iterative methods and all sparse adjoint/preconditioner/direct-factor families execute for real/complex single/double; stored structured/dense/matrix-free adapters share the same contracts |
| Termination/failure outcomes | Iterative, preconditioner, factor, interchange, and spectral tests cover success, limit, cancellation, invalid structure, singularity, and numerical breakdown |
| Bounded scale | 20,000-dimensional no-dense regression plus 100,000-nonzero sparse and 200,000-dimensional matrix-free measured benchmarks; each large path measures 20 warmed solves |
| Reuse and mutation | factor/preconditioner/workspace reuse, exact in-place paths, partial-alias rejection, immutable snapshots, actual concurrent calls, and validation/construction atomicity |
| Sparse interchange | text/binary round trips and malformed, duplicate, explicit-zero, version, checksum, truncation, nonzero-limit, and per-axis dimension-limit rejection |
| 2.0 runway | run-checked example 23, owner/signature-aware classified snapshot/reference, empty formal-deprecation list, and hash/default enforcement |
| Documentation traceability | all 2,880 exact declaration rows, exact residual/default guide, compiler-run fragments, capability inventory, release notes, and qualification links |

## Compatibility and risks

- No maintained identifier or default is removed or changed.
- Compressed and structured interfaces are immutable; builders/workspaces are
  mutable and require separate instances or caller synchronization.
- Iterative assumptions are model obligations. A breakdown helps diagnose a
  violation but is not a symmetry/definiteness proof.
- Sparse multiplication and LU can create mathematical fill.
- Matrix-free correctness and reentrancy are delegated to the supplied action.
- General band LU deliberately reports `PivotingUsed=False`.

The complete review evidence is in
[QUALIFICATION_1.9.0.md](QUALIFICATION_1.9.0.md) and
[API_AUDIT_1.9.md](API_AUDIT_1.9.md).

## Explicitly excluded

No 2.0 removals/default changes, distributed/out-of-core/GPU/vendor sparse
path, parallel/SIMD sparse dispatch, fill-reducing sparse solver, advanced
spectral target, block/flexible Krylov method, or unrelated deferred roadmap
family is included.
