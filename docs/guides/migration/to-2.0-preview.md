# 2.0 migration preview

This 1.9 guide lets applications try the candidate conventions without
changing their 1.x compatibility surface. It does not promise drop-in
equivalence and does not require a 2.0 unit.

The complete compile-checked program is
[`23_api_migration_preview.pas`](../../../examples/23_api_migration_preview.pas).
It is compiled and executed with every other example by
`build-examples.ps1` on Windows or `sh ./build-examples.sh` on Unix. A
successful run prints one checked result for each workflow and ends with
`Migration preview checks passed.`

## Dense construction and solves

Prefer `IDenseDoubleMatrix` and `TDenseDoubleMatrix` to legacy nested
`IMatrix`. Typed matrices use zero-based `SizeInt`, contiguous owned storage,
and explicit views. Call `SolveWithInfo`, `FactorLU`, or `FactorCholesky` when
diagnostics or reuse matter. The migration example executes `SolveWithInfo`
and verifies both solution values and the reported residual. A legacy
`TMatrixKit` object is not silently reinterpreted; copy values explicitly so
ownership and precision are visible.

## Interpolation and fitting

Keep knot/model ownership explicit. Construct `TCubicSplineInterpolator` or
use `TModellingKit` typed options/results, then retain the returned model rather
than depending on hidden global configuration. The migration example fits and
checks `y = 1 + 2x` through `FitPolynomial` in addition to evaluating the
spline. Extrapolation and clamping semantics remain those documented in
[Numerical modelling](../domains/numerical-modelling.md).

## Optimisation

Start from `TOptimizationOptions.Defaults`, modify named fields, and inspect
`TOptResult.Status`, diagnostics, and best iterate. The example actually runs
nonlinear conjugate gradient and checks its reported minimum. Reaching a limit
or being cancelled is an outcome, not an exception and not proof of optimality.

## DSP

Use `TDSPKit` with an explicit normalization/convolution method where scaling
or allocation matters. Stateful FIR/biquad/overlap objects are mutable and
must not be shared concurrently. A returned spectrum is owned output, not a
view of the input.

## Statistics and RNG

Use `TOnlineStatistics` for bounded streaming state and `TLocalRandom` for an
explicit reproducible stream. Copying a mutable record or sharing a generator
has semantic consequences; synchronize or keep independent instances.

## Sparse workflows

Do not treat `TMatrixKitSparse` as CSR. Enumerate or otherwise explicitly copy
legacy values into `TSparseDoubleTripletBuilder`, choose `szDrop`/`szKeep`, and
finalize to CSR or CSC. The typed result is immutable, zero-based, canonical,
and has checked native-size shapes. The example builds an
`ILinearDoubleOperator`, applies a sparse diagonal preconditioner, runs
conjugate gradient, and checks its explicitly confirmed result. Solver choice
remains a statement about the caller's matrix model; no adapter verifies
symmetry or positive definiteness.

See [Sparse, structured, and matrix-free linear algebra](../domains/sparse-linear-algebra.md)
for the exact storage, residual, aliasing, and solver contracts.

## What 1.9 deliberately does not do

Version 1.9 does not remove `IMatrix`, `TMatrixKit`, `TMatrixKitSparse`, or
other maintained entry points. It does not alter old defaults and does not add
implicit legacy-to-typed conversions. The candidate contract and
[`public-api-1.9.json`](../../public-api-1.9.json) provide review evidence for a
future release; they are not a breaking release themselves.
