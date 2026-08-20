# PR: Add numerical modelling and optimisation workflows for 1.7.0

## Summary

This PR implements the mathlib-fp 1.7.0 numerical-modelling and optimisation
milestone on the typed dense foundation delivered in 1.5 and 1.6.

It adds end-to-end interpolation, differentiation, integration, fitting,
nonlinear-equation, adaptive ODE, convex QP, and second-order-cone workflows.
Iterative APIs return inspectable diagnostics, callback-based paths are
reentrant, and deterministic fixtures cover randomized sampling.

The change is additive. Existing 1.6 and earlier public APIs remain available,
including the scalar convenience wrappers and their documented exception
behavior. The implementation is native Free Pascal and introduces no
third-party runtime, foreign binary, service, or network dependency.

The release date is 2026-07-30. Merging, tagging, creating the GitHub
release, and publishing release artifacts remain separate release-management
steps.

## Motivation

The existing library provides scalar numerical helpers, nonlinear optimizers,
linear programming, and dependable typed dense decompositions. Callers still
had to assemble higher-level modelling workflows themselves and could not
consistently inspect convergence, feasibility, residuals, derivative quality,
or event outcomes.

Version 1.7 provides a coherent portable layer for small-to-medium dense
numerical models. It deliberately publishes algorithm-selection guidance and
explicit limitations alongside the APIs so callers can distinguish exact
interpolation from fitting, smooth from nonsmooth methods, and non-stiff from
stiff ODE requirements.

## Changes

### Shared iteration diagnostics (`MathBase.Iteration`)

- Adds `TIterationStatus` and `IterationStatusName`.
- Distinguishes convergence, acceptable limits, stagnation, numerical
  breakdown, infeasibility, unboundedness, iteration exhaustion, and
  cancellation as applicable to each algorithm.
- Extends existing scalar root and nonlinear-optimisation result records while
  preserving their established fields and convenience wrappers.

### Differentiation (`NumericsLib.Differentiation`)

- Adds scale-aware forward and central finite-difference gradients and
  Jacobians.
- Adds central finite-difference Hessians with symmetry restoration.
- Adds forward dual-number automatic differentiation for scalar objectives,
  including explicit elementary-function support.
- Adds analytic-gradient checking that reports the worst variable and absolute
  and relative disagreement.
- Rejects empty, non-finite, dimension-changing, or otherwise invalid callback
  results through the documented error path.

### Interpolation and approximation (`NumericsLib.Interpolation`)

- Adds reusable barycentric polynomial interpolation.
- Adds rational interpolation with an error estimate and iteration status.
- Adds monotonicity-preserving PCHIP and Akima cubic interpolation, including
  derivatives, antiderivatives, and definite integrals.
- Adds bilinear and bicubic interpolation for rectangular grids.
- Adds inverse-distance weighting plus dense Gaussian RBF and thin-plate
  interpolation for small scattered two-dimensional data sets.
- Copies constructor inputs so interpolants do not alias caller storage.
- Documents clamping, conditioning, and dense scalability limits.

### Integration, fitting, equations, and ODEs (`NumericsLib.Modelling`)

- Adds adaptive Gauss-Kronrod finite-interval integration with absolute and
  relative tolerances, visible error estimates, and interval limits.
- Adds transformed improper integration for one-sided and two-sided infinite
  intervals.
- Adds deterministic Halton quasi-Monte-Carlo integration for bounded
  multidimensional domains.
- Adds weighted linear-basis and polynomial least-squares fitting through the
  shared typed rank-revealing QR implementation.
- Returns parameters, residuals, rank, degrees of freedom, justified
  covariance, RSS, R-squared, and diagnostics.
- Adds bounded robust Levenberg-Marquardt nonlinear least squares with
  analytic or numerical Jacobians, derivative checking, damping, Huber and
  soft-L1 loss options, progress, and cancellation.
- Adds diagnostic Newton solves for square nonlinear systems with analytic or
  numerical Jacobians and safeguarded steps.
- Adds adaptive vector Dormand-Prince 5(4) integration for non-stiff initial
  value problems, including dense Hermite output and localized scalar events.

### Optimisation

- Adds dense positive-semidefinite quadratic programming with box, linear
  equality, and linear inequality constraints in
  `OptimizationLib.Convex`.
- Adds feasible-start affine second-order-cone optimization with objective,
  optimality, feasibility, iteration, evaluation, and status diagnostics.
- Extends existing nonlinear optimizer results with shared statuses,
  gradient norms, and constraint violations where applicable.
- Removes the former unit-global `PenaltyMethod` and `Maximize` callback
  bridges and critical sections.
- Routes penalty and maximization work through call-local Nelder-Mead state,
  allowing nested and independent callback use.

### Documentation, examples, packaging, and CI

- Adds the 1.7 ownership, aliasing, mutation, indexing, shape, error,
  compatibility, reentrancy, and provenance design record.
- Adds numerical-modelling and convex-optimisation selection guides.
- Adds runnable examples 17 and 18 for fitting/ODE and QP/SOCP workflows.
- Updates the human-readable and machine-readable capability inventories,
  support matrix, changelog, release notes, qualification report, README, and
  documentation index.
- Adds every new unit to the Lazarus package and public-API compile test.
- Updates searchable-documentation and clean-archive CI paths for 1.7.0.

## Public API and compatibility

New public units:

- `MathBase.Iteration`
- `NumericsLib.Differentiation`
- `NumericsLib.Interpolation`
- `NumericsLib.Modelling`
- `OptimizationLib.Convex`

Primary new entry points:

- `TDifferentiationKit.Gradient`, `Jacobian`, `Hessian`, `AutoGradient`, and
  `CheckGradient`
- `TBarycentricInterpolator`, `TCubicInterpolator`, `TGridSurface`,
  `TScatteredInterpolator`, and `TInterpolationKit`
- `TModellingKit.IntegrateAdaptive`, `IntegrateImproper`,
  `IntegrateQuasiMonteCarlo`, `FitLinearBasis`, `FitPolynomial`,
  `FitNonlinear`, `SolveSystem`, and `SolveODE`
- `TConvexOptimizationKit.SolveQuadraticProgram` and
  `SolveSecondOrderConeProgram`

Compatibility notes:

- No existing public unit, class, method, or result field is removed or
  renamed.
- Existing scalar root convenience APIs retain their established exceptions;
  diagnostic result APIs additionally expose termination statuses.
- Existing `PenaltyMethod` and `Maximize` signatures and objective conventions
  are unchanged.
- Public input arrays are borrowed for a call. Reusable interpolants copy their
  inputs, and returned arrays own their storage.
- All indexing remains zero-based and all dense matrices use
  `Matrix[Row][Column]`.

## Tests and verification

Focused 1.7 tests cover:

- agreement between analytic, central-difference, and forward-AD derivatives,
  plus deliberate bad-derivative detection;
- barycentric and rational interpolation, PCHIP/Akima behavior, grid
  interpolation, IDW, RBF, and thin-plate exact-node references;
- adaptive finite and improper integration plus deterministic
  quasi-Monte-Carlo sampling;
- weighted rank-revealing linear fitting and bounded robust nonlinear fitting;
- vector nonlinear equations with residual diagnostics;
- adaptive vector ODE accuracy, dense output, and event localization;
- constrained convex QP and feasible-start SOCP references;
- iteration status names, termination distinctions, deterministic sampling,
  and nested callback reentrancy; and
- legacy scalar-root exception compatibility.

Local verification completed:

- [x] 864 tests pass on Win64 release (`-O3`).
- [x] 864 tests pass on Win64 with runtime, range, overflow, stack, and I/O
  checks enabled.
- [x] 864 tests pass with heap tracing; zero unfreed blocks are reported.
- [x] 864 tests pass on optimized Win32.
- [x] The Lazarus package builds on Win64.
- [x] The package umbrella, including all new units, compiles on Win32.
- [x] All 19 runnable examples compile.
- [x] Examples 17 and 18 execute end to end with converged fitting, ODE, QP,
  and SOCP outcomes.
- [x] Searchable documentation builds; checks cover 42 Markdown pages, 19
  indexed examples, and 104 public symbols.
- [x] The representative benchmark compiles and runs at `-O3`.
- [x] `git diff --check` passes.

Linux is not locally executable from the Windows qualification host. The exact
PR commit passed the repository's Linux and Windows CI jobs, including tests,
examples, documentation, benchmarks, source-archive checks, and the Lazarus
package paths.

## Performance evidence

The local Windows x86-64 FPC 3.2.2 `-O3` release-day run recorded:

- merge sort of 250,000 values: 63 ms;
- convex hull of 150,000 points: 46 ms;
- `192 x 192` dense matrix multiplication: 32 ms;
- typed `127 x 129` by `129 x 65` multiplication: 31 ms;
- one `96 x 32` QR factorization plus 20 reused four-RHS solves: 16 ms,
  compared with 62 ms for five allocating convenience calls;
- `48 x 16` compact SVD plus a two-RHS minimum-norm solve: below the 1 ms
  timer resolution, with 8 sweeps;
- `24 x 24` symmetric eigensystem: below the 1 ms timer resolution, with 7
  sweeps;
- two million complex arithmetic operations: 31 ms;
- one million-element vector AXPY plus dot product: 32 ms; and
- a 262,144-point complex FFT: 15 ms.

The deterministic QR, SVD, and eigen checksums were `2.786934`, `2.917959`,
and `4.230000`. These figures are reproducibility and regression evidence from
one host, not cross-library or cross-platform performance claims.

## Risk and review notes

- Review adaptive quadrature transforms, error accumulation, interval limits,
  and non-finite callback handling.
- Review weighted/rank-deficient QR fitting and the conditions under which
  covariance is returned.
- Review nonlinear-fit damping, robust weights, bounds, derivative checking,
  and best-iterate/status behavior.
- Review ODE error scaling, rejected-step handling, dense Hermite output, and
  event bracketing/localization.
- Review QP positive-semidefinite validation, equality projection, feasibility
  measures, and termination distinctions.
- Review the SOCP strict-feasibility requirement, barrier termination, and the
  absence of a general infeasibility certificate.
- Review the removal of mutable callback bridges and the nested reentrancy
  regression test.
- Review compatibility boundaries, especially scalar-root exceptions and
  existing optimizer objective conventions.

## Out of scope

- Stiff ODE methods, mass matrices, differential-algebraic equations, and
  boundary-value solvers.
- Reverse-mode AD and automatic differentiation through unsupported branches
  or special functions.
- Sparse interpolation, sparse optimization, semidefinite programming, and
  general conic certificates.
- Integer and mixed-integer optimization.
- Large-data streaming, parallel/SIMD/GPU work, or external BLAS/LAPACK
  bindings.
- Persistence/interchange, expression evaluation, data-analysis tooling, or
  any other 1.8.0 feature.
- Merging, tagging, publishing artifacts, and creating the GitHub release.
