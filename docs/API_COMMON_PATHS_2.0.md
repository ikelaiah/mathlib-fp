# Curated 2.0 common API paths

This is the small choice map for ordinary applications. The exhaustive
declaration contract remains the generated
[`API_REFERENCE_1.9.md`](API_REFERENCE_1.9.md); classification is a
documentation decision and does not hide or remove advanced declarations.

Every example below is a complete, output-checked Pascal program. Release
qualification compiles and runs the selected program from each document and
rejects any common example that names a declaration classified as generic
implementation support.

| Domain | Recommended common path | Checked example | Full contract / advanced route |
| --- | --- | --- | --- |
| MathBase | `TTrigKit` and double-real `MathBase.Precision` functions | [MathBase quick start](MathBase.md) | [MathBase guide](MathBase.md) |
| AlgebraLib | `TDenseDoubleMatrix` + double-real `Solve` | [60-second dense solve](TypedDenseMatrices.md) | [Dense solver selection](DenseLinearAlgebra.md) and [sparse guide](SparseLinearAlgebra.md) |
| FinanceLib | `TFinanceKit` | [Finance quick start](FinanceLib.md) | [Finance guide](FinanceLib.md) |
| StatsLib | `TStatsKit` with `TDoubleArray` | [Statistics quick start](StatsLib.md) | [Statistics guide](StatsLib.md) |
| EngineeringLib | calculation-specific static kits | [Engineering quick start](EngineeringLib.md) | [Engineering guide](EngineeringLib.md) |
| NumericsLib | `TNumericsKit` | [Numerics quick start](NumericsLib.md) | [Numerics guide](NumericsLib.md) and [modelling guide](NumericalModelling.md) |
| ProbabilityLib | `TProbabilityKit` | [Probability quick start](ProbabilityLib.md) | [Probability guide](ProbabilityLib.md) |
| CombinatoricsLib | `TCombinatoricsKit` | [Combinatorics quick start](CombinatoricsLib.md) | [Combinatorics guide](CombinatoricsLib.md) |
| OptimizationLib | `TOptimizationKit.GoldenSection` | [Optimisation quick start](OptimizationLib.md) | [Optimisation guide](OptimizationLib.md) and [convex guide](ConvexOptimization.md) |
| TimeSeriesLib | `TTimeSeriesKit` with `TDoubleArray` | [Time-series quick start](TimeSeriesLib.md) | [Time-series guide](TimeSeriesLib.md) |
| MLLib | `TMLKit.LinearRegression` | [Machine-learning quick start](MLLib.md) | [Machine-learning guide](MLLib.md) |
| InterchangeLib | double-real `SaveBinary` / `LoadDoubleMatrixBinary` | [60-second round trip](Interchange.md) | [Interchange guide](Interchange.md) |
| GeometryLib | `TVector2D` value arithmetic | [Geometry quick start](GeometryLib.md) | [Geometry guide](GeometryLib.md) |

## What the five classifications mean

- `recommended` is part of one or more common paths above.
- `advanced` is stable application API for callers who need more precision,
  scalar kinds, diagnostics, workspaces, storage formats, or specialist
  algorithms.
- `compatibility` remains supported and has either a named replacement with a
  semantic-difference note or an explicit retain decision.
- `experimental` is outside the stable compatibility promise. The current
  snapshot has no declarations in this class.
- `implementation` is public only because Free Pascal specialization needs it.
  Applications use the corresponding named scalar facade.

The exact selectors behind this map are in
[`api-decision-2.0.json`](api-decision-2.0.json). The generator expands those
selectors to all 2,880 owner/signature-aware declaration rows, so overloads are
not collapsed by name.

## Review outcome

The short programs confirm that ordinary double-real work does not need a new
wrapper in 1.9.x. Geometry rotation is the one common convenience routed to
1.10.0: the 1.9.9 convergence gate closed 2-D `TVector2D.Rotate` as a 1.10.0
declaration with a complete contract, and explicitly deferred 3-D rotation
beyond 2.0 until axis-angle, quaternion, or matrix semantics and orientation,
units, normalization, and error behavior are designed. No public name or
declaration is introduced by this decision release; see the
[closed manifest](CAPABILITY_MANIFEST_1.10.0.md).
