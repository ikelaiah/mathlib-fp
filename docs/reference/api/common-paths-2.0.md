# Curated 2.0 common API paths

This is the small choice map for ordinary applications. The exhaustive
declaration contract remains the generated
[`API_REFERENCE_1.9.md`](../../releases/1.9.0/api-reference.md); classification is a
documentation decision and does not hide or remove advanced declarations.

Every example below is a complete, output-checked Pascal program. Release
qualification compiles and runs the selected program from each document and
rejects any common example that names a declaration classified as generic
implementation support.

| Domain | Recommended common path | Checked example | Full contract / advanced route |
| --- | --- | --- | --- |
| MathBase | `TTrigKit` and double-real `MathBase.Precision` functions | [MathBase quick start](../../guides/domains/math-base.md) | [MathBase guide](../../guides/domains/math-base.md) |
| AlgebraLib | `TDenseDoubleMatrix` + double-real `Solve` | [60-second dense solve](../../guides/domains/typed-dense-matrices.md) | [Dense solver selection](../../guides/domains/dense-linear-algebra.md) and [sparse guide](../../guides/domains/sparse-linear-algebra.md) |
| FinanceLib | `TFinanceKit` | [Finance quick start](../../guides/domains/finance.md) | [Finance guide](../../guides/domains/finance.md) |
| StatsLib | `TStatsKit` with `TDoubleArray` | [Statistics quick start](../../guides/domains/statistics.md) | [Statistics guide](../../guides/domains/statistics.md) |
| EngineeringLib | calculation-specific static kits | [Engineering quick start](../../guides/domains/engineering.md) | [Engineering guide](../../guides/domains/engineering.md) |
| NumericsLib | `TNumericsKit` | [Numerics quick start](../../guides/domains/numerics.md) | [Numerics guide](../../guides/domains/numerics.md) and [modelling guide](../../guides/domains/numerical-modelling.md) |
| ProbabilityLib | `TProbabilityKit` | [Probability quick start](../../guides/domains/probability.md) | [Probability guide](../../guides/domains/probability.md) |
| CombinatoricsLib | `TCombinatoricsKit` | [Combinatorics quick start](../../guides/domains/combinatorics.md) | [Combinatorics guide](../../guides/domains/combinatorics.md) |
| OptimizationLib | `TOptimizationKit.GoldenSection` | [Optimisation quick start](../../guides/domains/optimization.md) | [Optimisation guide](../../guides/domains/optimization.md) and [convex guide](../../guides/domains/convex-optimization.md) |
| TimeSeriesLib | `TTimeSeriesKit` with `TDoubleArray` | [Time-series quick start](../../guides/domains/time-series.md) | [Time-series guide](../../guides/domains/time-series.md) |
| MLLib | `TMLKit.LinearRegression` | [Machine-learning quick start](../../guides/domains/machine-learning.md) | [Machine-learning guide](../../guides/domains/machine-learning.md) |
| InterchangeLib | double-real `SaveBinary` / `LoadDoubleMatrixBinary` | [60-second round trip](../../guides/domains/interchange.md) | [Interchange guide](../../guides/domains/interchange.md) |
| GeometryLib | `TVector2D` value arithmetic | [Geometry quick start](../../guides/domains/geometry.md) | [Geometry guide](../../guides/domains/geometry.md) |

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
[`api-decision-2.0.json`](../../api-decision-2.0.json). The generator expands those
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
[closed manifest](../../releases/1.10.0/capability-manifest.md).
