# Beginner recipes

These are short routes to an existing, tested double-real entry point. Follow
the linked copy/run program first; use the advanced link only after the result
and failure contract are clear. All commands assume a clean extracted release
with Free Pascal 3.2.2 or later and no network access.

For a documentation program, copy its Pascal fence to `recipe.pas`, then run:

```bash
mkdir lib
fpc -Fusrc -FUlib recipe.pas
./recipe
```

On Windows, run `recipe.exe`. For a file in `examples/`, follow the
[example build instructions](../../examples/README.md#build-and-run).

Read the [newcomer guide](beginner-guide.md) if dynamic arrays, interfaces,
callbacks, options, or result statuses are unfamiliar.

## Choose a recipe

| Task | Beginner code and checked output | Advanced route |
| --- | --- | --- |
| Dense square solve | [Typed dense solve](../guides/domains/typed-dense-matrices.md#60-second-solve) | [Dense solver choice](../guides/domains/dense-linear-algebra.md#choose-a-dense-solver) |
| Dense least squares | [Least-squares program](../guides/domains/dense-linear-algebra.md#60-second-least-squares-solve) | [QR, CPQR, and SVD contracts](../guides/domains/dense-linear-algebra.md#choose-a-dense-solver) |
| Sparse solve | [Sparse CG program](../guides/domains/sparse-linear-algebra.md#sixty-second-sparse-solve) | [Iterative solver choice](../guides/domains/sparse-linear-algebra.md#choose-an-iterative-solver) |
| Descriptive statistics | [Statistics quick start](../guides/domains/statistics.md#quick-start) | [Inference and regression choice](../guides/domains/statistics.md#inference-distributions-and-regression-in-18) |
| Streaming statistics | [Online spectral summary](../guides/domains/applied-numerics.md#60-second-workflow) | [Mergeable statistics contract](../guides/domains/applied-numerics.md#online-and-mergeable-statistics) |
| Normal probability | [Normal CDF quick start](../guides/domains/probability.md#quick-start) | [Distribution reference](../guides/domains/probability.md#continuous-distributions) |
| Interpolation and fitting | [Nonlinear fit program](../guides/domains/numerical-modelling.md#60-second-example) | [Modelling algorithm choice](../guides/domains/numerical-modelling.md#choose-an-algorithm) |
| Optimisation | [Scalar optimisation quick start](../guides/domains/optimization.md#quick-start) | [Diagnostic solver choice](../guides/domains/optimization.md#solver-selection-guide) |
| FFT convolution and filtering | [DSP workflow](../guides/domains/applied-numerics.md#60-second-workflow) | [Transform/convolution choice](../guides/domains/applied-numerics.md#choose-a-transform-or-convolution) |
| Time series | [Moving-average quick start](../guides/domains/time-series.md#quick-start) | [ARIMA and state-space choice](../guides/domains/time-series.md#state-space-selection-in-18) |
| Finance | [Loan schedule quick start](../guides/domains/finance.md#quick-start) | [Financial method reference](../guides/domains/finance.md#tfinancekit-static-methods) |
| Geometry | [Vector quick start](../guides/domains/geometry.md#quick-start) | [Geometry contract](../guides/domains/geometry.md#types) |
| Unit conversion | [Engineering quick start](../guides/domains/engineering.md#quick-start) | [Conversion contract](../guides/domains/engineering.md#engineeringlibunitconversion-tunitconversionkit) |

## Dense square solve

Use `Solve(A, B)` for an ordinary square double-real system. It allocates the
solution and a private LU factorisation; it does not overwrite `A` or `B`.
Choose `SolveWithInfo` when residual and conditioning diagnostics matter, and
`FactorLU` when the same coefficient matrix has many right-hand sides.

The checked program prints `solution = 2.0000, 3.0000`. Singular or non-finite
input raises `EDenseMatrixError`; see the [common dense contracts](../guides/domains/dense-linear-algebra.md#common-contracts).

## Dense least squares

For a tall full-rank problem, start with `LeastSquares`, which uses Householder
QR rather than normal equations. The checked program prints
`intercept=3.500 slope=1.400` and its residual. Use CPQR when rank is uncertain
and SVD when a minimum-norm result is required. Each call returns a newly
allocated double-real result; reusable factors retain a copied factorisation.

## Sparse solve

Build canonical CSR storage, adapt it to `ILinearDoubleOperator`, and start
with the simple `ConjugateGradient` overload only when the matrix is symmetric
positive definite. The checked program prints `status: converged` and three
unit solution entries. The sparse matrix is immutable; the simple solve
allocates its initial guess, solution, and workspace without densifying.

An invalid shape or option raises. A valid solve that exhausts its iteration
budget returns a non-converged status. See the [exact stopping contract](../guides/domains/sparse-linear-algebra.md#exact-stopping-contract).

## Descriptive and streaming statistics

Use `TStatsKit.Describe` when all observations are already in a
`TDoubleArray`. Use `TOnlineStatistics` when observations arrive incrementally
or partial summaries must be merged. The checked examples report a descriptive
mean/interval and `mean spectral power = 0.083333` respectively.

`Describe` allocates its result fields and may need work proportional to the
input operation. `TOnlineStatistics` retains O(1) state. Both paths calculate
in `Double`; choose the documented non-finite policy before a stream begins.
See [statistics design notes](../guides/domains/statistics.md#design-notes) and the
[streaming failure contract](../guides/domains/applied-numerics.md#online-and-mergeable-statistics).

## Normal probability

Use `TProbabilityKit.NormalCDF(X, Mean, StandardDeviation)` for
`P(Z <= X)`. The checked standard-normal program prints
`P(Z <= 1.96) = 0.975002`. This scalar double-real call does not allocate.
Invalid or non-finite distribution parameters raise `EProbabilityError`; an
out-of-support observation follows the documented CDF clamping rule. See
[probability error handling](../guides/domains/probability.md#error-handling).

## Interpolation and fitting

Interpolation passes through supplied knots; fitting estimates parameters
from noisy or overdetermined data. Start with a cubic/PCHIP interpolator for a
curve between knots and `FitPolynomial`/`FitNonlinear` when residual and
termination diagnostics matter. The checked nonlinear program prints
`converged 1.0000 2.0000`.

The simple calls allocate coefficient/result arrays in double precision.
Non-convergence is returned in the fit status; invalid knot order, dimensions,
or options raise before a result is returned. See the
[interpolation and fitting contracts](../guides/domains/numerical-modelling.md#interpolation-contracts).

## Optimisation

For a bounded scalar unimodal objective, begin with `GoldenSection`; for a
smooth scalar objective, `BrentMinimize` usually needs fewer evaluations. The
quick start's complete callback program prints `x = 3.000000`. These scalar
calls allocate no workspace visible to the caller.

For multivariate work, choose from the [solver selection guide](../guides/domains/optimization.md#solver-selection-guide)
and inspect `TOptResult.Status` instead of relying only on the best iterate.
A valid problem may stop without convergence; an invalid interval, callback,
shape, or tolerance raises `EOptimizationError`.

## FFT convolution and filtering

Use `TDSPKit.Convolve(..., cmDirect)` for a short one-off signal,
`cmFFT` for a larger finite FFT convolution, and `cmAutomatic` for the
documented deterministic threshold. Use `TStreamingFIR` or the overlap
convolvers for repeated blocks. The checked DSP program reports
`mean spectral power = 0.083333`.

Batch transforms and convolution allocate result arrays. Streaming filters
retain bounded state and return new blocks unless their contract names a
destination. Double real is the beginner input path; transforms expose complex
spectra where the mathematics requires them. Invalid lengths, cutoffs,
non-finite samples, or zero-energy windows raise before filter state advances.

## Time series

Start with `SimpleMovingAverage` when the task is only smoothing. Move to Holt-
Winters for level/trend/seasonality, ARIMA for a diagnosed stationary model,
and state-space filtering when uncertainty evolves explicitly. The checked
quick start prints `last moving average = 4.50`.

Array-returning calls allocate a double-real result. Stateful Kalman filters
retain their current state/covariance and require caller synchronisation for
shared mutation. See [time-series error handling](../guides/domains/time-series.md#error-handling).

## Finance

Rates are decimal values (`0.05` means five percent) and periods are explicit.
The checked amortisation program prints the first and final scheduled payments.
It allocates the schedule array; scalar NPV, rate, ratio, and pricing calls
normally return a `Double` without a caller-managed workspace.

Invalid cash flows, rates, periods, or undefined ratios raise `EFinanceError`.
An iterative IRR can fail to bracket or converge and then raises as documented;
read the [finance design notes](../guides/domains/finance.md#design-notes) before interpreting
ambiguous multi-root cash flows.

## Geometry

Use fixed-size `TPoint2D`/`TVector2D` values for ordinary planar work. The
checked quick start prints `length = 5.0000` for a 3-4-5 vector. Fixed-size
vector arithmetic is allocation-free double-real value arithmetic; polygon
and hull calls allocate dynamic result arrays.

Degenerate intersections return their documented Boolean/count outcome, while
invalid polygon shapes or non-finite inputs raise the exception named in
[geometry error handling](../guides/domains/geometry.md#error-handling).

## Unit conversion

Prefer the typed conversion methods such as `ConvertLength` when the physical
quantity is known. The checked quick start prints `1 m = 3.2808 ft`. Scalar
conversion uses `Double` and does not allocate; parsing/formatting a unit name
allocates strings in the normal Pascal way.

Unknown or incompatible unit kinds raise `EUnitConversionError`; `Try...`
forms return `False` where documented. See the
[unit-conversion compatibility contract](../guides/domains/engineering.md#compatibility-enumeration-and-base-units).
