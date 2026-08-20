# mathlib-fp cheatsheet

> Refreshed for each stable release. See [TOP_TASKS.md](../guides/tasks.md) for the
> broader problem-oriented index.

One canonical beginner task per domain, plus a few tasks almost every program
needs. Compile with `src/` on the Free Pascal unit path.

| Task | Unit | Entry point | Example |
| ---- | ---- | ----------- | ------- |
| Convert angles and basic trigonometry | `MathBase.Trigonometry` | `TTrigKit.DegToRad`, `TTrigKit.Hypotenuse` | [`00_getting_started.pas`](../../examples/00_getting_started.pas) |
| Solve a square dense system | `AlgebraLib.DenseSolvers` | `Solve(A, B)` | [`15_typed_dense_solve.pas`](../../examples/15_typed_dense_solve.pas) |
| Compute NPV and IRR of cash flows | `FinanceLib.NPV` | `TNPVKit.NetPresentValue`, `InternalRateOfReturn` | [`04_finance_npv_irr.pas`](../../examples/04_finance_npv_irr.pas) |
| Summarise a numeric sample | `StatsLib.Stats` | `TStatsKit.Describe(Data)` | [`01_stats_basics.pas`](../../examples/01_stats_basics.pas) |
| Convert a physical quantity | `EngineeringLib.UnitConversion` | `TUnitConversionKit.ConvertLength` | [`05_unit_conversion.pas`](../../examples/05_unit_conversion.pas) |
| Find a bracketed scalar root | `NumericsLib.Numerics` | `TNumericsKit.Brent(F, A, B)` | [`13_numerical_methods.pas`](../../examples/13_numerical_methods.pas) |
| Upper-tail normal probability | `ProbabilityLib.Distributions` | `TProbabilityKit.NormalSurvival(X, Mu, Sigma)` | [`07_probability.pas`](../../examples/07_probability.pas) |
| Count combinations `C(n, k)` | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit.Combination(N, K)` | [`08_combinatorics.pas`](../../examples/08_combinatorics.pas) |
| Minimise a single-variable function | `OptimizationLib.Optimization` | `TOptimizationKit.GoldenSection(F, A, B)` | [`09_optimization.pas`](../../examples/09_optimization.pas) |
| Smooth a time series | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit.SimpleMovingAverage(Y, Window)` | [`10_timeseries.pas`](../../examples/10_timeseries.pas) |
| Fit a linear regression | `MLLib.MachineLearning` | `TMLKit.LinearRegression(X, Y)` | [`11_machinelearning.pas`](../../examples/11_machinelearning.pas) |
| Read a 2-D vector's length | `GeometryLib.Geometry` | `TVector2D.Create`, `Magnitude` | [`12_geometry.pas`](../../examples/12_geometry.pas) |
| Round-trip a dense matrix exactly | `MathBase.Interchange` | `SaveBinary(Stream, A)`, `LoadDoubleMatrixBinary(Stream)` | [`20_interchange_replay.pas`](../../examples/20_interchange_replay.pas) |
| Multiply two typed matrices | `AlgebraLib.DenseMatrices`, `AlgebraLib.DenseKernels` | `TDenseDoubleMatrix.FromArray`, `Multiply(A, B)` | [README quick start](../../README.md#1-multiply-two-matrices) |
| Least-squares fit with diagnostics | `AlgebraLib.DenseDecompositions` | `LeastSquares(A, B, Info)` | [`16_dense_solver_selection.pas`](../../examples/16_dense_solver_selection.pas) |
| Reproducible seeded random numbers | `MathBase.Random` | `TLocalRandom.Seeded(Seed)`, `NextUInt64` | [`20_interchange_replay.pas`](../../examples/20_interchange_replay.pas) |
