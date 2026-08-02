# Numerical modelling

`NumericsLib.Differentiation`, `NumericsLib.Interpolation`, and
`NumericsLib.Modelling` provide the 1.7 modelling workflow. They build on the
typed dense QR/SVD and direct solvers and do not require a foreign numerical
runtime.

## 60-second example

```pascal
uses MathBase.SharedTypes, MathBase.Iteration,
  NumericsLib.Modelling;

function Residual(const P:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(P[0]+P[1]-3, P[0]+2*P[1]-5);
end;

var Options:TNonlinearFitOptions; Fit:TFitResult;
begin
  Options:=TNonlinearFitOptions.Defaults;
  Fit:=TModellingKit.FitNonlinear(@Residual,nil,
    TDoubleArray.Create(0,0),Options);
  WriteLn(IterationStatusName(Fit.Status),' ',
    Fit.Parameters[0]:0:4,' ',Fit.Parameters[1]:0:4);
end.
```

Expected output:

```text
converged 1.0000 2.0000
```

The complete runnable workflow is
[`17_numerical_modelling.pas`](../examples/17_numerical_modelling.pas).

## Choose an algorithm

| Problem | Start with | Use another method when |
| --- | --- | --- |
| Small/medium global polynomial interpolation | `TBarycentricInterpolator` | Data are noisy or many knots make a global polynomial unsuitable |
| Shape-preserving monotone curve | `TCubicInterpolator.BuildPchip` | Local visual smoothness matters more than monotonicity: use `BuildAkima` |
| Classical cubic spline | `TCubicSplineInterpolator.Build` | Choose natural, clamped, or not-a-knot endpoint conditions explicitly |
| Small rational data | `TInterpolationKit.Rational` | A near pole causes `isNumericalBreakdown` |
| Rectangular grid | `TGridSurface.Bilinear` | Use `Bicubic` for smoother tensor-product PCHIP output |
| Scattered points | `InverseDistance` | Use `BuildRBF` or `BuildThinPlate` for a globally smooth small data set |
| Smooth finite integral | `IntegrateAdaptive` | Use `IntegrateImproper` for infinite endpoints |
| Low-dimensional box integral | `IntegrateCubature` | Tensor order would exceed the evaluation cap: use quasi/Monte Carlo |
| Moderate-dimensional deterministic sample | `IntegrateQuasiMonteCarlo` | An explicit independent random stream is required: use `IntegrateMonteCarlo` |
| Linear/polynomial regression | `FitLinearBasis` / `FitPolynomial` | Parameters enter nonlinearly: use `FitNonlinear` |
| Nonlinear least squares | `FitNonlinear` | Use `FitNonlinearAuto` for a dual-number residual/Jacobian |
| Small nonlinear equation system | `SolveSystem` | Use `SolveSystemAuto` for dual-number equations |
| Polynomial roots | `SolvePolynomial` | Returns every real/complex root and residual; not a symbolic factorization |
| Non-stiff vector initial-value ODE | `SolveODE` | Stiff or mass-matrix problems are not supported by the stable API |

Interpolation is exact at supplied points; fitting estimates a model from
possibly noisy observations. Do not use an interpolation API when residual,
rank, uncertainty, or robust-loss diagnostics are required.

## Termination results

`MathBase.Iteration` defines `TIterationStatus` and
`IterationStatusName`. Iterative results can report `isConverged`,
`isAcceptableLimit`, `isStagnation`, `isNumericalBreakdown`,
`isInfeasible`, `isUnbounded`, `isIterationLimit`, or `isCancelled`.
Callers should inspect the status before consuming an iterative estimate.

`TIntegrationResult` returns `Value`, `ErrorEstimate`, `Evaluations`,
`Intervals`, and `Status`. `TVectorRootResult`, `TFitResult`, and
`TAdaptiveODESolution` similarly retain the best finite result and their
diagnostics.

## Differentiation

`TDifferentiationKit.Gradient`, `Jacobian`, and `Hessian` use coordinate-scaled
finite differences. `TDifferenceMethod` selects `dmForward` or `dmCentral`.
The `dmComplexStep` enum is accepted only through the explicit
`ComplexStepGradient` overload and `TComplexScalarVectorFunction`; it is never
silently applied to a real callback. The other callback types are
`TScalarVectorFunction`, `TVectorFunction`, and `TGradientFunction`; matrix
results use `TDoubleMatrix`, and analytic Jacobian check callbacks use
`TJacobianMatrixFunction`.

`TDual` and `TDualArray` implement forward automatic differentiation.
`AutoGradient` seeds each coordinate through a `TDualFunction`;
`AutoJacobian` does the same for a `TDualVectorFunction`. Supported helpers are
`DualSin`, `DualCos`, `DualTan`, `DualSinh`, `DualCosh`, `DualTanh`,
`DualExp`, `DualLn`, `DualSqrt`, and `DualPower`.

`CheckGradient` returns `TDerivativeCheckResult`, including `Passed`,
`WorstIndex`, analytic/reference values, and absolute/relative error. A
nonlinear fit can set `TNonlinearFitOptions.CheckDerivative` to reject a bad
analytic Jacobian before iterating. `CheckJacobian` provides the corresponding
worst-row/worst-column diagnostic for vector functions.

Complex-step differentiation is valid only when the callback is implemented
with complex arithmetic and is analytic along the perturbed coordinates.
Absolute value, comparisons, clipping, piecewise branches, conjugation, and
discarding the imaginary component invalidate the method. Forward AD follows
the executed branch; it does not differentiate a discontinuity.

All differentiation inputs are borrowed and immutable. Returned arrays own
their storage. Time is O(n) objective calls for a gradient, O(n) vector calls
for a Jacobian, O(n²) scalar calls for a Hessian or full forward-mode gradient.

## Interpolation contracts

`TBarycentricInterpolator.Build`, `TCubicInterpolator.BuildPchip`, and
`BuildAkima` copy finite, strictly increasing knots and values. Their
`Evaluate`, `Derivative`, `Antiderivative`, and `Integrate` methods are
read-only and reentrant. Evaluation clamps outside the knot range.

`TCubicSplineInterpolator.Build` adds `sbNatural`, `sbClamped`, and
`sbNotAKnot` endpoint conditions. Clamped construction requires finite left
and right endpoint slopes. `Evaluate`, `Derivative`, `SecondDerivative`,
`Antiderivative`, and `Integrate` use the stored piecewise cubic
coefficients. Like the other curve interpolators, out-of-range evaluation
uses the endpoint interval convention.

Spline regression is represented by `TSplineFitResult` and constructed with
`FitSplineBasis`; it owns both the interior knots and ordinary `TFitResult`.

`TRationalInterpolationResult` exposes `Value`, `ErrorEstimate`, and `Status`.
`TGridSurface.Build` copies a rectangular `TInterpolationMatrix` whose shape is
`Values[YIndex][XIndex]`. `Bilinear` is piecewise bilinear; `Bicubic` is a
tensor-product monotone cubic construction.

`TInterpolationKit.InverseDistance`, `TScatteredInterpolator.BuildRBF`, and
`BuildThinPlate` cover small scattered data. RBF/thin-plate construction solves
a dense system and needs O(n²) storage/O(n³) time. Coincident points and
singular kernel systems are rejected; these are not large-data methods.

## Fitting contracts

`FitLinearBasis` accepts a `TLinearBasisFunction` and strictly positive optional
weights. `FitPolynomial` uses powers from zero through `Degree`. Both delegate
to `RankRevealingLeastSquares`.

`TFitResult` owns `Parameters`, `Residuals`, and justified `Covariance`, and
reports `Rank`, `DegreesOfFreedom`, `ResidualSumSquares`, `RSquared`,
`Iterations`, `Evaluations`, `GradientNorm`, and `Status`. Covariance is empty
for rank deficiency or non-positive degrees of freedom.

`FitNonlinear` accepts a `TResidualFunction`, optional `TJacobianFunction`,
initial parameters, and `TNonlinearFitOptions`. Options cover absolute,
relative, and gradient tolerances, damping, bounds, maximum iterations,
per-parameter positive `ParameterScales`,
`TRobustLoss` (`rlSquared`, `rlHuber`, `rlSoftL1`), loss scale, derivative
checking, and a `TProgressFunction` cancellation callback. The implementation
is scaled damped Levenberg-Marquardt. It is a local solver and makes no global
minimum claim. Covariance is returned only for a converged, full-rank,
ordinary squared-loss fit with positive residual degrees of freedom; robust,
rank-deficient, cancelled, or unconverged fits leave it empty.

`FitNonlinearAuto` and `SolveSystemAuto` use `TDualVectorFunction` callbacks
and the same bounded solvers. `SolvePolynomial` uses a scaled simultaneous
complex iteration, returns all roots in deterministic order, and reports a
residual for every root.

## Integration, equations, and ODE contracts

`IntegrateAdaptive` uses an embedded Gauss-Kronrod 7/15 pair. It combines
absolute/relative tolerances and bounds interval subdivision. Its error estimate
is not a proof for a discontinuous or highly oscillatory integrand.
`IntegrateImproper` transforms one or two infinite endpoints.
`IntegrateQuasiMonteCarlo` uses deterministic seeded Halton points and returns a
sample-variance scale estimate.
`IntegrateCubature` evaluates a tensor Gauss-Legendre rule after checking the
requested order/dimension product against `MaxEvaluations`.
`IntegrateMonteCarlo` consumes a caller-owned `TLocalRandom` and reports a
standard-error estimate; identical random states reproduce identical samples.

`SolveSystem` accepts analytic or numerical Jacobians through
`TVectorEquationFunction` and `TVectorJacobianFunction`. It uses damped Newton
steps and reports residual and step norms.

`SolveODE` accepts `TODEVectorFunction`, `TAdaptiveODEOptions`, and an initial
state. It uses adaptive Dormand-Prince 5(4), stores accepted points and
derivatives, and supplies cubic-Hermite dense output through
`TAdaptiveODESolution.Evaluate`. `TODEEventFunction` detects directional
zero-crossings and localises an event against dense output.
`AbsoluteTolerances` may provide one positive absolute tolerance per state
component; leave it empty to use scalar `AbsoluteTolerance`.

Callbacks are synchronous and reentrant. There is no unit-global callback,
workspace, or random state. Inputs are never mutated. Dense output and fit
arrays own independent storage. These APIs are thread-safe when caller-owned
callback state is not concurrently mutated.

## Errors and limitations

`EDifferentiationError`, `EInterpolationError`, and `EModellingError` identify
nil callbacks, dimensions, indexes, bounds, controls, or non-finite values.
Validation failure does not mutate inputs.

The stable 1.8 boundary does not claim stiff/implicit ODE integration, mass
matrices, sparse/large scattered interpolation, reverse-mode AD, or
high-dimensional deterministic cubature. Those conditional roadmap families
remain explicit rather than being silently routed to an unsuitable algorithm.

