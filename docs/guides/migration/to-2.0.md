# Migrating to mathlib-fp 2.0

This guide covers the 2.0.0 release candidate. It promotes the frozen 1.10.0
API; it is not a rewrite and does not make 2.0.0 a published stable release.

## No-change paths

Supported 1.x source continues to compile unchanged. Existing units, compiled
defaults, tolerances, numerical results, ownership rules, indexing, shape
contracts, diagnostics, and the Lazarus package surface remain unchanged.
No compatibility package or source edit is required for ordinary upgrades.

## Preferred 2.0 paths

For new code, use the established typed/common paths documented during the 1.x
runway: `IDenseDoubleMatrix` and `TDenseDoubleMatrix` for dense algebra,
explicit typed sparse builders for sparse data, named options/results for
optimisation, and `TLocalRandom` for reproducible local RNG state. These are
documentation preferences, not new 2.0 declarations. They retain zero-based
`SizeInt` indexing, explicit shape, owned/reference-counted results, and the
existing diagnostic/status contracts.

## Compatibility paths

`IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` remain supported. Typed paths
are preferred when their explicit copying, storage, scalar, and shape semantics
fit the application; no implicit conversion is introduced. `TPressureKit`,
`EPressureError`, `TVelocityKit`, and `EVelocityError` remain intentionally
retained with their existing identity and import paths. The 21 reviewed plain
aliases likewise remain supported; no warning, deprecation, removal, or
package move begins in 2.0.

## Actual breaking changes

There are none. The frozen decision
[`decision-2.0.json`](../../reference/api/decision-2.0.json) records empty
source, behaviour, warning, and packaging consequence lists. Therefore no
source edit, ownership/copying change, indexing/shape change, diagnostic
change, default/tolerance change, or numerical-result change is required to
migrate supported 1.x code.

For detailed typed-dense guidance, see [moving to typed dense matrices](to-typed-dense.md).
