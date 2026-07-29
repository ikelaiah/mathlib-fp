# mathlib-fp 1.7.0

Target release: 2026-07-30.

Version 1.7.0 completes the numerical-modelling and optimisation milestone on
the 1.5/1.6 typed dense engine. It provides end-to-end interpolation, fitting,
integration, nonlinear-equation, adaptive ODE, derivative, LP/QP,
cone-constrained, and nonlinear-optimisation workflows with inspectable
outcomes.

## User-visible additions

- `NumericsLib.Interpolation`: barycentric/rational interpolation,
  monotonicity-preserving PCHIP, Akima curves, derivatives/antiderivatives,
  bilinear/bicubic grids, and small scattered IDW/RBF/thin-plate methods.
- `NumericsLib.Differentiation`: scale-aware gradients, Jacobians, Hessians,
  dual-number forward AD, and analytic-gradient checks.
- `NumericsLib.Modelling`: adaptive Gauss-Kronrod finite/improper integration,
  deterministic Halton integration, weighted QR polynomial/linear-basis
  fitting, bounded robust Levenberg-Marquardt, vector Newton equations, and
  adaptive vector Dormand-Prince ODEs with dense output and events.
- `MathBase.Iteration`: a common status vocabulary distinguishing convergence,
  acceptable limits, stagnation, breakdown, infeasibility, unboundedness,
  iteration exhaustion, and cancellation.
- `OptimizationLib.Convex`: dense positive-semidefinite QP with explicit
  projection and feasible-start affine second-order-cone optimisation.

The [numerical modelling guide](NumericalModelling.md) and
[convex optimisation guide](ConvexOptimization.md) contain 60-second examples,
selection advice, API contracts, diagnostics, and limitations. Runnable
cross-domain examples are
[`17_numerical_modelling.pas`](../examples/17_numerical_modelling.pas) and
[`18_convex_optimization.pas`](../examples/18_convex_optimization.pas).

## Diagnostics and derivative paths

Iterative 1.7 results retain the best finite iterate and a
`TIterationStatus`. Analytic, central-difference, and forward-AD derivatives
are compared on smooth reference problems. `CheckGradient` and nonlinear fit
Jacobian checking identify the mismatching variable or matrix element before a
long solve.

Adaptive integration reports an embedded-pair error estimate. Fits report
parameters, residuals, rank, degrees of freedom, justified covariance, RSS,
R-squared, iterations, evaluations, and gradient scale. Vector roots report
residual/step norms. ODE results report accepted/rejected steps, dense output,
and event state. Convex results report objective, optimality scale, feasibility,
iterations, evaluations, and status.

## Compatibility and migration

This release is additive. `TNumericsKit`, `TOptimizationKit`, existing result
fields, and all 1.6 typed dense APIs remain source compatible. Callers can
migrate one workflow at a time.

The old `PenaltyMethod` and `Maximize` implementations no longer use
unit-global callback adapters or locks. Their signatures and numerical intent
are unchanged, while independent calls are now reentrant.

## Accuracy evidence

Checked reference workflows include polynomial knot reproduction, monotone
PCHIP bounds, planar grid interpolation, exact RBF nodes, the sine and Gaussian
integrals, exact linear fits, bounded nonlinear residual fits, a two-equation
system, exponential ODE dense output and event time, a constrained convex
quadratic, and the scalar unit-cone optimum.

The [1.7 qualification report](QUALIFICATION_1.7.0.md) lists configurations
and exact gates. Accuracy statements are workload-specific; they are not
universal worst-case proofs.

## Known limitations

- Adaptive ODE integration is non-stiff; stiff methods and mass matrices are
  not claimed.
- RBF/thin-plate construction is dense and intended for small data sets.
- Forward AD targets scalar and small-to-medium parameter problems; reverse
  mode is absent.
- The convex APIs are dense continuous QP/SOCP solvers. Sparse, semidefinite,
  integer/mixed-integer, and general non-convex models are not claimed.
- The SOCP solver requires a strictly feasible initial point and does not
  provide a general infeasibility certificate.

No persistence/interchange, expression-evaluation, parallel/SIMD, large-data,
or other 1.8.0 feature was added.
