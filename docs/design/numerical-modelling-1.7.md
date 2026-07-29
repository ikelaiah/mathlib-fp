# Numerical modelling and optimisation design record (1.7)

## Scope and compatibility

Version 1.7 adds modelling APIs beside the existing `TNumericsKit` and
`TOptimizationKit` entry points. Existing signatures remain source compatible.
The new APIs are split by responsibility:

- `NumericsLib.Differentiation` owns derivative approximation, forward-mode
  automatic differentiation, and derivative checks;
- `NumericsLib.Interpolation` owns reusable one- and two-dimensional
  interpolants;
- `NumericsLib.Modelling` owns adaptive quadrature, vector root/ODE solvers,
  linear and nonlinear least-squares fitting;
- `OptimizationLib.Convex` owns convex QP and second-order-cone workflows;
- `MathBase.Iteration` owns the termination vocabulary shared by the numerical
  and optimisation domains.

This split is additive. The existing simple APIs remain the first choice for
fixed-step teaching examples and small compatibility programs.

The 1.7 release does not add persistence, data-frame/interchange types,
parallel/SIMD execution, expression evaluation, sparse storage, or benchmark
infrastructure. Those are 1.8-or-later concerns.

## Ownership, aliasing, mutation, and allocation

All dynamic arrays passed to public functions are borrowed for the duration of
the call and are never retained. Result records own independent arrays. Reusable
interpolants copy knots, values, and coefficients during construction, so later
caller mutation cannot alter the interpolant.

Public solvers do not mutate caller arrays, bounds, matrices, or initial
guesses. A validation or callback failure occurs before a caller-owned
destination can be partially modified. Simple entry points allocate their
working arrays internally. No global workspace or callback state is used.

## Indexing, shapes, and interpolation behavior

Arrays and dense row arrays are zero-indexed. A vector callback must return the
documented dimension on every call. Rectangular matrices must not be ragged.
Gridded surface values use `Values[YIndex][XIndex]`, matching row-major matrix
notation.

Interpolation knots must be finite and strictly increasing. Exact
interpolants reproduce knots. Evaluation outside the knot interval is clamped
for compatibility with the existing `TNumericsKit` interpolation functions.
Derivatives use the end interval at a clamped endpoint. Definite integrals
reverse sign when their limits are reversed.

`TBarycentricInterpolator` uses scaled first-form weights and is intended for
small-to-medium polynomial interpolation. `TPchipInterpolator` uses
Fritsch-Carlson monotonicity-preserving slopes. `TAkimaInterpolator` uses local
Akima slopes and requires at least five knots. Rational interpolation reports a
numerical breakdown instead of silently accepting a near-zero denominator.
Bilinear and bicubic surfaces require a complete rectangular grid; bicubic
uses tensor-product monotone cubic interpolation.

## Errors, statuses, and tolerances

Programmer errors (nil callbacks, invalid dimensions, non-finite inputs,
invalid bounds, or non-positive controls) raise the domain exception and name
the operation and bad condition.

Expected iterative outcomes are returned with `TIterationStatus`:

- `isConverged` — requested residual/error/optimality tolerance met;
- `isAcceptableLimit` — a usable estimate met a documented relaxed limit;
- `isStagnation` — finite iterates stopped making scale-aware progress;
- `isNumericalBreakdown` — a finite algorithmic step could not be formed;
- `isInfeasible` / `isUnbounded` — the model has the corresponding certificate
  or detected outcome;
- `isIterationLimit` — the configured work limit was exhausted;
- `isCancelled` — a progress callback requested termination.

Compatibility `Converged` fields remain and are true only for
`isConverged`. Scalar wrappers continue to raise their established convergence
exceptions when a detailed result is not converged.

Absolute and relative tolerances are combined as
`AbsTol + RelTol * scale`. Scale is derived from the current value, state, or
residual as documented by each method. Iteration and subdivision limits are
hard bounds. Returned results include evaluation counts, residual/error or
feasibility measures, and the best finite iterate seen.

## Derivative contract

Scalar/vector derivative callbacks are ordinary Free Pascal procedure
variables and are invoked synchronously. Numerical derivatives use
coordinate-scaled forward or central differences. Complex-step is exposed only
through a complex callback, so it cannot be applied accidentally to a real
callback containing non-analytic branches.

Forward automatic differentiation uses `TDual` value/derivative pairs.
Operators and the documented elementary functions propagate one directional
derivative. A full gradient is obtained by seeding each coordinate in turn.
This is intended for scalar and small-to-medium parameter problems.

Derivative checking compares directional derivatives against a central
difference reference and reports the worst variable, absolute error, relative
error, and pass/fail result before a long solve.

## Solver contracts and limitations

Adaptive integration uses an embedded Gauss-Kronrod 7/15 pair and a bounded
largest-error interval subdivision queue. Improper limits use explicit variable
transforms. The error estimate is local-pair based and is not a proof for
discontinuous or highly oscillatory integrands.

Vector ODE integration uses the Dormand-Prince 5(4) pair with accepted-step
dense output by cubic Hermite interpolation and sign-change event localisation.
It is a non-stiff method. Stiffness-like repeated step rejection is reported as
stagnation; mass matrices and stiff integration are not claimed by this API.

Linear fitting builds a weighted design matrix and delegates rank-revealing
least squares to the typed QR/SVD engine. Fit results include residuals, rank,
degrees of freedom, residual sum of squares, R-squared, and covariance only
when rank and degrees of freedom justify it. Nonlinear least squares uses
scaled, damped Levenberg-Marquardt steps, optional bounds and robust loss, and
analytic or numerical Jacobians.

The LP compatibility API remains available. The 1.7 convex API provides a
dense convex QP active-set/projected solver and feasible-start second-order-cone
barrier solver. It reports objective, stationarity, feasibility, evaluations,
and termination status. Convexity (`Q` positive semidefinite) and cone
feasibility are validated numerically. Sparse models, integer variables,
non-convex QP certificates, and general semidefinite programming are not
claimed.

## Reentrancy and thread safety

There is no unit-global callback, RNG, active-model, or workspace state in any
1.7 API. Calls are reentrant and thread-safe provided callers do not
concurrently mutate the same input arrays or state captured by their own
callbacks. Randomized multistart and Monte-Carlo helpers use a solver-local
deterministic generator seeded through options.

The old penalty method is implemented with a solver-local objective evaluation
path; its former unit-global callback adapter and lock are removed.

## Provenance

- Berrut and Trefethen, *Barycentric Lagrange Interpolation*, SIAM Review 46(3),
  2004.
- Fritsch and Carlson, *Monotone Piecewise Cubic Interpolation*, SIAM Journal
  on Numerical Analysis 17(2), 1980.
- Akima, *A New Method of Interpolation and Smooth Curve Fitting*, Journal of
  the ACM 17(4), 1970.
- Piessens et al., *QUADPACK*, Springer, 1983 (Gauss-Kronrod adaptive design).
- Dormand and Prince, *A Family of Embedded Runge-Kutta Formulae*, Journal of
  Computational and Applied Mathematics 6(1), 1980.
- Moré, *The Levenberg-Marquardt Algorithm: Implementation and Theory*,
  Lecture Notes in Mathematics 630, 1978.
- Nocedal and Wright, *Numerical Optimization*, second edition, 2006.
- Boyd and Vandenberghe, *Convex Optimization*, 2004.

These references describe algorithms and safeguards; all released
implementations are native Object Pascal source in this repository.
