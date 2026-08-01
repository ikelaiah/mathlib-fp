# Candidate 2.0 API contract

This document is the reviewable API candidate published by mathlib-fp 1.9.0.
It is a migration runway, not a 2.0 implementation. Version 1.9 does not remove
maintained 1.x APIs or change their defaults.

## Proposed primary conventions

| Concern | Candidate convention |
| --- | --- |
| Entry units | Domain-specific units such as `AlgebraLib.DenseMatrices`, `AlgebraLib.SparseMatrices`, `AlgebraLib.LinearOperators`, and solver units; no global registration unit |
| Naming | Named scalar facades (`TDenseDoubleMatrix`, `TSparseDoubleMatrix`, `TDoubleIterativeSolver`) over generic implementation types |
| Indices/shapes | Zero-based checked `SizeInt`; rows then columns; vectors are explicit `n x 1` typed dense matrices at operator boundaries |
| Ownership | Interface values state whether storage is owned, retained immutable, retained mutable, or delegated; factories say when they deep-copy |
| Mutation/aliasing | Immutable values by default; mutable dense storage and workspaces are explicit; `Into` procedures reject unsafe aliasing |
| Tolerances | Options records contain absolute/relative and algorithm-specific tolerances; formulas and defaults are public contracts |
| Outcomes | Expected convergence/nonconvergence is a result status plus diagnostics; invalid contracts raise domain-specific exceptions |
| Exceptions | Errors name the operation, bad parameter/shape, and required condition |
| RNG | Algorithms receive or own explicit reproducible local state/seed; no hidden global random stream |
| Cancellation/progress | Optional monitor/callback in options; cancellation returns a status and latest complete iterate |
| Thread safety | Immutable values are reentrant; mutable workspaces/state require separate instances or caller synchronization |

The candidate favours simple allocating overloads for first use and explicit
destination/workspace overloads for repeated work. An API must not hide a
dense conversion, factor rebuild, external runtime, or global mutable state.

## 1.x classification

The complete machine-readable inventory is
[`public-api-1.9.json`](public-api-1.9.json). Its unit-interface SHA-256 hashes
are checked by `tools/check_docs.py`. Schema 2 identifies each declaration by
unit, owner, declaration kind, name, and normalized signature. Overloads and
same-named members on different types are therefore separate contract entries;
compatibility and internal classifications propagate to their owned members.
The generated human-readable
[`API_REFERENCE_1.9.md`](API_REFERENCE_1.9.md) contains one row for every exact
snapshot declaration; the documentation checker rejects a missing or stale
row.
`tools/test_api_snapshot.py` regression-tests extraction, visibility, overload,
owner, and classification behavior.

- **Primary** is the recommended stable typed 1.9 surface.
- **Compatibility** remains maintained through 1.9.x but has a preferred typed
  path. This includes legacy `IMatrix`, `TMatrixKit`, `TMatrixKitSparse`, and
  the legacy finance entry units.
- **Deprecated** means source-compatible but scheduled for replacement. There
  are no formally deprecated public entries in 1.9.0, so the snapshot's
  deprecation/replacement list is empty.
- **Experimental** is outside the stable compatibility promise. No newly
  shipped 1.9 numerical entry point is classified experimental.
- **Internal** identifies generic implementation scaffolding exposed only for
  FPC specialization; applications should use a named scalar facade.

Compatibility is not deprecation. Any future deprecation requires a named
replacement, tests, migration notes, and the promised 1.9.x compatibility
period.

## Candidate entry points

The candidate typed linear-algebra path is:

- dense storage/kernels/decompositions/solvers in the existing
  `AlgebraLib.Dense*` units;
- CSR/CSC and compact structured storage in `AlgebraLib.SparseMatrices`;
- stored and matrix-free operations/preconditioners in
  `AlgebraLib.LinearOperators`;
- diagnostic Krylov methods in `AlgebraLib.IterativeSolvers`;
- reusable compact/sparse factors in `AlgebraLib.StructuredSolvers`;
- largest-magnitude partial eigensystems in
  `AlgebraLib.PartialEigensystems`.

Other domains retain their current stable 1.x typed or kit entry points while
the candidate is evaluated. The compile-checked
[`23_api_migration_preview.pas`](../examples/23_api_migration_preview.pas)
covers dense construction, interpolation/fitting, optimisation, DSP,
statistics, and sparse conversion.

## Freeze rule

`docs/public-api-1.9.json` is the 1.9 candidate freeze. A changed interface hash
must be accompanied by a regenerated snapshot and a documented compatibility
or correctness reason in release/PR notes. The snapshot does not authorize
breaking changes: actual removals, renamed defaults, or a new primary umbrella
belong to a separately reviewed 2.0 release.

Remaining numerical gaps are listed in
[`capabilities.json`](capabilities.json) and the
[1.9 qualification report](QUALIFICATION_1.9.0.md).
