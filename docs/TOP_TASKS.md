# Common tasks by domain

This index is for someone who knows the problem they want to solve but does
not yet know the Pascal identifier. Every entry point below is documented in
the linked guide and, where one exists, demonstrated by a runnable example in
[`examples/`](../examples/README.md). The beginner recipes
([`RECIPES.md`](RECIPES.md)) provide the same route in a shorter task-first
form.

If a task is not supported by a documented entry point, it is marked
`gap — roadmap candidate`; the capability inventory
([`CAPABILITIES.md`](CAPABILITIES.md)) and the post-2.0 capability programme in
[`ROADMAP.md`](ROADMAP.md#post-20-capability-programme) track those families.

## MathBase

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Share numeric samples across units | `MathBase.SharedTypes` | `TDoubleArray`; `ToDoubleArray(Data)` | [`00_getting_started.pas`](../examples/00_getting_started.pas) |
| Convert angles and compute trigonometry | `MathBase.Trigonometry` | `TTrigKit.DegToRad`, `TTrigKit.Hypotenuse` | [`00_getting_started.pas`](../examples/00_getting_started.pas) |
| Evaluate low-level special functions | `MathBase.Precision` | `NormalCDF(X)`, `Erf(X)`, `GammaLn(X)` | [`00_getting_started.pas`](../examples/00_getting_started.pas) |
| Portable complex scalar arithmetic | `MathBase.Complex` | `TComplex.Create`, `CSqrt` | [`14_complex_vectors.pas`](../examples/14_complex_vectors.pas) |
| Reproducible seeded random numbers | `MathBase.Random` | `TLocalRandom.Seeded`, `TLocalRandom.GetState` | [`20_interchange_replay.pas`](../examples/20_interchange_replay.pas) |

## AlgebraLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Solve a square dense system `A*X = B` | `AlgebraLib.DenseSolvers` | `Solve(A, B)` | [`15_typed_dense_solve.pas`](../examples/15_typed_dense_solve.pas) |
| Fit a tall model by least squares | `AlgebraLib.DenseDecompositions` | `LeastSquares(A, B, Info)` | [`16_dense_solver_selection.pas`](../examples/16_dense_solver_selection.pas) |
| Compute all eigenpairs of a symmetric matrix | `AlgebraLib.DenseDecompositions` | `FactorSymmetricEigen(A)` | [`16_dense_solver_selection.pas`](../examples/16_dense_solver_selection.pas) |
| Solve a sparse positive-definite system with CG | `AlgebraLib.IterativeSolvers` | `TDoubleIterativeSolver.ConjugateGradient(Op, B, Options)` | [`22_sparse_end_to_end.pas`](../examples/22_sparse_end_to_end.pas) |
| Compatibility `IMatrix` arithmetic and LU | `AlgebraLib.Matrices` | `TMatrixKit.CreateFromArray`, `Multiply`, `LU`, `Determinant` | [`03_matrix_operations.pas`](../examples/03_matrix_operations.pas) |

## FinanceLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Net present value of a cash-flow series | `FinanceLib.NPV` | `TNPVKit.NetPresentValue(Investment, CashFlows, Rate)` | [`04_finance_npv_irr.pas`](../examples/04_finance_npv_irr.pas) |
| Internal rate of return | `FinanceLib.NPV` | `TNPVKit.InternalRateOfReturn(Investment, CashFlows)` | [`04_finance_npv_irr.pas`](../examples/04_finance_npv_irr.pas) |
| Periodic payment on a loan | `FinanceLib.Interest` | `TFinanceKit.Payment(PV, Rate, Periods)` | [`04_finance_npv_irr.pas`](../examples/04_finance_npv_irr.pas) |
| Full loan amortisation schedule | `FinanceLib.Bonds` | `TBondKit.AmortizationSchedule(Loan, Rate, Periods)` | [`04_finance_npv_irr.pas`](../examples/04_finance_npv_irr.pas) |
| European call or put price | `FinanceLib.Interest` | `TFinanceKit.BlackScholes(Spot, Strike, Rate, Vol, T, OptionType)` | [option pricing section](FinanceLib.md#option-pricing-black-scholes) |

## StatsLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Summarise a numeric sample in one call | `StatsLib.Stats` | `TStatsKit.Describe(Data)` | [`01_stats_basics.pas`](../examples/01_stats_basics.pas) |
| Two-sample pooled t-test with p-value | `StatsLib.Stats` | `TStatsKit.TTest(X, Y, TPValue)` | [`02_hypothesis_test.pas`](../examples/02_hypothesis_test.pas) |
| Seeded bootstrap confidence interval | `StatsLib.Stats` | `TStatsKit.BootstrapConfidenceInterval(Data, Alpha, Iterations, Seed)` | [`01_stats_basics.pas`](../examples/01_stats_basics.pas) |
| Streaming mean/variance in constant memory | `StatsLib.Streaming` | `TOnlineStatistics.Create`; `Add`; `Merge` | [`19_applied_data_pipeline.pas`](../examples/19_applied_data_pipeline.pas) |
| OLS regression with diagnostics | `StatsLib.Inference` | `TInferenceKit.FitOLS(Design, Response)` | [`26_probability_finance.pas`](../examples/26_probability_finance.pas) |

## EngineeringLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Convert a physical quantity between units | `EngineeringLib.UnitConversion` | `TUnitConversionKit.ConvertLength(Value, From, To)` | [`05_unit_conversion.pas`](../examples/05_unit_conversion.pas) |
| Classify pipe flow with Reynolds number | `EngineeringLib.FluidDynamics` | `TFluidDynamicsKit.ReynoldsNumber(...)` | [`06_fluid_dynamics.pas`](../examples/06_fluid_dynamics.pas) |
| Carnot efficiency of an ideal heat engine | `EngineeringLib.Thermodynamics` | `TThermodynamicsKit.CarnotEfficiency(HotK, ColdK)` | [quick-start program](EngineeringLib.md#engineeringlibthermodynamics-tthermodynamicskit) |
| Windowed-sinc FIR low-pass filter | `EngineeringLib.Signal` | `TSignalKit.DesignFIRLowPass(Cutoff, Order, Window)`; `ApplyFIRFilter` | [`24_sensor_pipeline.pas`](../examples/24_sensor_pipeline.pas) |
| Block convolution with a finite impulse response | `EngineeringLib.DSP` | `TOverlapAddConvolver.ProcessBlock` then `Flush` | [`21_release_1_8_workflows.pas`](../examples/21_release_1_8_workflows.pas) |

## NumericsLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Find a bracketed scalar root | `NumericsLib.Numerics` | `TNumericsKit.Brent(F, A, B)` or `BrentResult` | [`13_numerical_methods.pas`](../examples/13_numerical_methods.pas) |
| Approximate a definite integral | `NumericsLib.Numerics` | `TNumericsKit.SimpsonRule(F, A, B)` | [`13_numerical_methods.pas`](../examples/13_numerical_methods.pas) |
| Integrate an initial-value scalar ODE | `NumericsLib.Numerics` | `TNumericsKit.RK4Solve(F, T0, Y0, T1, N)` | [`13_numerical_methods.pas`](../examples/13_numerical_methods.pas) |
| Interpolate knots with a cubic spline | `NumericsLib.Numerics` | `TNumericsKit.CubicSplineBuild`; `CubicSplineEval` | [`13_numerical_methods.pas`](../examples/13_numerical_methods.pas) |
| Fit a nonlinear model with diagnostics | `NumericsLib.Modelling` | `TModellingKit.FitNonlinear(@Residual, nil, Initial, Options)` | [`17_numerical_modelling.pas`](../examples/17_numerical_modelling.pas) |

## ProbabilityLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Upper-tail normal probability `P(X > x)` | `ProbabilityLib.Distributions` | `TProbabilityKit.NormalSurvival(X, Mu, Sigma)` | [`07_probability.pas`](../examples/07_probability.pas) |
| Two-tailed t-test p-value | `ProbabilityLib.Distributions` | `TProbabilityKit.StudentTTwoTail(X, DF)` | [`07_probability.pas`](../examples/07_probability.pas) |
| P-value from a chi-squared statistic | `ProbabilityLib.Distributions` | `TProbabilityKit.ChiSquaredSurvival(X, DF)` | [`07_probability.pas`](../examples/07_probability.pas) |
| Binomial probability `P(X <= K)` | `ProbabilityLib.Distributions` | `TProbabilityKit.BinomialCDF(K, N, P)` | [`07_probability.pas`](../examples/07_probability.pas) |
| Weibull reliability (survival) | `ProbabilityLib.Distributions` | `TProbabilityKit.WeibullSurvival(X, K, Lambda)` | [`07_probability.pas`](../examples/07_probability.pas) |

## CombinatoricsLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Count unordered selections `C(n, k)` | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.Combination(N, K)` | [`08_combinatorics.pas`](../examples/08_combinatorics.pas) |
| Count ordered arrangements `P(n, k)` | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.Permutation(N, K)` | [`08_combinatorics.pas`](../examples/08_combinatorics.pas) |
| Overflow-safe large counts in log space | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.LogFactorial(N)`, `LogCombination(N, K)` | [`08_combinatorics.pas`](../examples/08_combinatorics.pas) |
| Enumerate permutations and combinations | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.Permutations(Items)`, `Combinations(N, K)`, `NextPermutation` | [`08_combinatorics.pas`](../examples/08_combinatorics.pas) |
| Modular arithmetic and primality | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.ModPow(A, B, M)`, `ModInverse`, `IsPrime` | [`08_combinatorics.pas`](../examples/08_combinatorics.pas) |

## OptimizationLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Minimise a bounded single-variable function | `OptimizationLib.Optimization` | `TOptimizationKit.GoldenSection(F, A, B)` | [`09_optimization.pas`](../examples/09_optimization.pas) |
| Minimise a smooth multivariate function | `OptimizationLib.Optimization` | `TOptimizationKit.LBFGS(F, Grad, X0)` | [`09_optimization.pas`](../examples/09_optimization.pas) |
| Minimise a derivative-free function | `OptimizationLib.Optimization` | `TOptimizationKit.NelderMead(F, X0)` | [`09_optimization.pas`](../examples/09_optimization.pas) |
| Solve a small linear program | `OptimizationLib.Optimization` | `TOptimizationKit.SimplexLP(C, A, B)` | [`09_optimization.pas`](../examples/09_optimization.pas) |
| Solve a dense convex quadratic program | `OptimizationLib.Convex` | `TConvexOptimizationKit.SolveQuadraticProgram(Model, Options)` | [`18_convex_optimization.pas`](../examples/18_convex_optimization.pas) |

## TimeSeriesLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Smooth a series with a centred moving average | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit.SimpleMovingAverage(Y, Window)` | [`10_timeseries.pas`](../examples/10_timeseries.pas) |
| Decompose trend/seasonal/residual | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit.Decompose(Y, Period)` | [`10_timeseries.pas`](../examples/10_timeseries.pas) |
| Fit ARIMA and forecast on the original scale | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit.ARIMAFit(Y, P, D, Q)`; `ARIMAForecast` | [`10_timeseries.pas`](../examples/10_timeseries.pas) |
| Detect z-score anomalies | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit.ZScoreAnomalies(Y, Threshold)` | [`10_timeseries.pas`](../examples/10_timeseries.pas) |
| Scalar Kalman filtering | `TimeSeriesLib.StateSpace` | `TScalarKalmanFilter.Create(Config, InitialState, InitialCov)`; `Process` | [`19_applied_data_pipeline.pas`](../examples/19_applied_data_pipeline.pas) |

## MLLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Fit a linear regression model | `MLLib.MachineLearning` | `TMLKit.LinearRegression(X, Y)` | [`11_machinelearning.pas`](../examples/11_machinelearning.pas) |
| Fit a logistic-regression classifier | `MLLib.MachineLearning` | `TMLKit.LogisticRegression(TrainX, TrainY)`; `LogisticPredict` | [`11_machinelearning.pas`](../examples/11_machinelearning.pas) |
| Reproducible train/test split | `MLLib.MachineLearning` | `TMLKit.TrainTestSplit(X, Y, Fraction, Seed, TrainX, ...)` | [`11_machinelearning.pas`](../examples/11_machinelearning.pas) |
| Cluster data with k-means | `MLLib.MachineLearning` | `TMLKit.KMeans(X, K)` | [`11_machinelearning.pas`](../examples/11_machinelearning.pas) |
| Reduce dimensionality with PCA | `MLLib.MachineLearning` | `TMLKit.PCA(X, NComponents)`; `PCATransform` | [`11_machinelearning.pas`](../examples/11_machinelearning.pas) |

## GeometryLib

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Construct a 2-D vector and read its length | `GeometryLib.Geometry` | `TVector2D.Create(AX, AY)`; `Magnitude` | [`12_geometry.pas`](../examples/12_geometry.pas) |
| Distance from a point to a segment or line | `GeometryLib.Geometry` | `TGeometryKit.PointToSegment2D(P, A, B, T)`; `PointToLine2D` | [`12_geometry.pas`](../examples/12_geometry.pas) |
| Test whether two segments intersect | `GeometryLib.Geometry` | `TGeometryKit.SegmentIntersect2D(A1, A2, B1, B2, Pt, T)` | [`12_geometry.pas`](../examples/12_geometry.pas) |
| Polygon area, perimeter, centroid, containment | `GeometryLib.Geometry` | `TGeometryKit.PolygonArea(Poly)`, `PolygonCentroid`, `PointInPolygon` | [`12_geometry.pas`](../examples/12_geometry.pas) |
| Translate, scale, or rotate a polygon | `GeometryLib.Geometry` | `TGeometryKit.Translate2D(Poly, DX, DY)`, `Scale2D`, `Rotate2D` | [`12_geometry.pas`](../examples/12_geometry.pas) |

## Interchange

| Task | Unit | Entry point | Runnable example |
| ---- | ---- | ----------- | ---------------- |
| Exact binary round trip of a dense matrix | `MathBase.Interchange` | `SaveBinary(Stream, A)`; `LoadDoubleMatrixBinary(Stream)` | [`20_interchange_replay.pas`](../examples/20_interchange_replay.pas) |
| Save and replay local RNG state | `MathBase.Interchange` | `SaveRandomStateBinary(Stream, State)`; `LoadRandomStateBinary` | [`20_interchange_replay.pas`](../examples/20_interchange_replay.pas) |
| Sparse Matrix Market exchange | `MathBase.Interchange` | `WriteSparseMatrixMarket`; `ReadSparseMatrixMarketDouble` | [`22_sparse_end_to_end.pas`](../examples/22_sparse_end_to_end.pas) |
| Persist a selected fitted/stateful model | `InterchangeLib.Models` | `SaveCubicSpline`/`LoadCubicSpline` and sibling adapters | [`21_release_1_8_workflows.pas`](../examples/21_release_1_8_workflows.pas) |
| Evaluate a bounded mathematical expression | `MathBase.Expressions` | `TExpressionEvaluator.Evaluate(Text, Symbols, Limits)` | [`21_release_1_8_workflows.pas`](../examples/21_release_1_8_workflows.pas) |
