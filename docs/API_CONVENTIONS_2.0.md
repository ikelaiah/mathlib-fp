# Complete 2.0 API conventions

Version 1.9.3 resolves the candidate conventions for every public domain. They
are documentary decisions over the frozen 1.9 declarations: compiled defaults,
source compatibility, numerical behavior, and package membership do not change.
The normative machine-readable record is
[`api-decision-2.0.json`](api-decision-2.0.json).

## Shared decisions

| Concern | 2.0 decision |
| --- | --- |
| Naming | Use focused domain units and descriptive `T`/`I`/`E` names. Show double-real allocating calls first and named scalar facades next. Generic specialization scaffolding is implementation support. |
| Indexing | Arrays and typed containers are zero-based. Typed dimensions use `SizeInt`; retained `Integer` signatures are compatibility contracts. |
| Shape | State rows before columns. Never hide reshape, transpose, densification, scalar conversion, or broadcasting. |
| Units | State physical, angular, financial, temporal, and statistical units at the entry point. Angles use radians unless a name says otherwise. |
| Ownership | Allocating calls return owned values or reference-counted handles. Caller streams, callbacks, and explicit state remain caller-owned. Retention is documented. |
| Mutation | Simple allocating calls leave inputs unchanged. Mutable matrices, views, workspaces, filters, accumulators, and model state are named explicitly. |
| Aliasing | Destination overloads state exact alias support and reject unsafe partial overlap before mutation. Validation failure cannot publish a partial result. |
| Exceptions | Invalid contracts raise the domain-specific exception naming the operation and violated condition. |
| Defaults | The compiled 1.9 defaults remain authoritative and documented in declarations or options. Documentation order changes no runtime default. |
| Tolerances | Use absolute, relative, and algorithm-specific scale-aware tests. Automatic sentinels are valid only where their formula is documented. |
| Outcomes | Expected non-convergence, infeasibility, cancellation, or breakdown uses a status/result with diagnostics; invalid input uses an exception. |
| RNG state | Recommended randomized paths accept an explicit seed or local reproducible state and do not consume hidden global state. |
| Cancellation | Long operations use their documented monitor/options and return the latest complete result with cancellation status. APIs without cancellation say so. |
| Progress | Callbacks are optional, synchronous, caller-owned, and observe only complete iterates. Callback exceptions do not publish partial destinations. |
| Thread safety | Pure/stateless calls are reentrant. Mutable state, streams, workspaces, views, filters, and RNG objects require separate instances or caller synchronization. |

## Domain application

Every domain inherits every shared decision. This table records the points
where a domain makes those rules concrete; the JSON record contains the full
unit assignment and review text. Every snapshot unit belongs to exactly one
row.

| Domain | Primary naming and shape choice | Ownership, outcomes, and domain detail |
| --- | --- | --- |
| MathBase | Focused scalar functions, `TComplex`, shared arrays, and stateless kits; no umbrella unit. | Scalars are values, returned arrays are owned, RNG state is explicit, and radians are the base angular unit. |
| AlgebraLib | Double-real named dense facade first; scalar variants, sparse/structured storage, operators, factors, diagnostics, and workspaces remain advanced stable paths. Matrices are rows × columns; operator vectors are explicit n × 1 matrices. | Typed handles retain reference-counted storage, factories copy arrays, and views are mutable aliases. Direct contract failures raise; iterative outcomes carry status/residual diagnostics. |
| FinanceLib | `TFinanceKit` is primary; focused bond/NPV alias units are retained compatibility entries. | Rates are decimal and time is periods/years. Results own schedules; undefined ratios and unresolved roots raise `EFinanceError`. |
| StatsLib | `TStatsKit` + `TDoubleArray` first; inference and streaming types are advanced. Model matrices are observations × variables. | Batch results own arrays, online statistics is explicit mutable state, and randomized methods use local seeds/state. |
| EngineeringLib | Choose the kit named for the calculation; DSP streaming/filter types are advanced. | Each routine states physical units. Static calculations are reentrant; mutable processors require separate instances. |
| NumericsLib | `TNumericsKit` first; interpolation, differentiation, fitting, integration, roots, and ODE controls stay in focused units. | Constructed interpolators/fits own coefficients, callbacks are caller-owned, and adaptive algorithms use algorithm-specific statuses and tolerances. |
| ProbabilityLib | `TProbabilityKit` is the double-real stateless facade. | Probabilities are dimensionless; inputs share the variate's unit. Invalid parameters raise `EProbabilityError`. |
| CombinatoricsLib | `TCombinatoricsKit` first; result arrays retain descriptive mathematical names. | Arrays are zero-based while n/k keep their mathematical meaning. Invalid domains and overflow raise rather than wrap. |
| OptimizationLib | Scalar `GoldenSection` first; multivariate, constrained, convex, workspace, and Pareto APIs are advanced stable routes. | Decision/constraint dimensions are explicit. Expected termination uses result status; malformed models raise. Progress sees complete iterates. |
| TimeSeriesLib | `TTimeSeriesKit` first; state-space configuration/filter/result types are advanced. Samples run earliest to latest. | Batch results own arrays; filters are mutable caller state. Sample spacing, seasonal period, and state units remain caller-consistent. |
| MLLib | `TMLKit.LinearRegression` first; typed analysis, preprocessing, forests, clustering, PCA, and neighbours are advanced. Matrices are observations × features. | Fitted values are owned and input datasets are not retained. Randomized training requires replayable seeds/state. |
| InterchangeLib | Use format-specific write/read or save/load pairs; typed load names state the scalar result. | Streams stay caller-owned, loads are atomic independent values, and dimensions/limits are checked before allocation. |
| GeometryLib | Keep points, vectors, shapes, and transforms distinct; `TVector2D` is the compact arithmetic route. | Fixed records are values, caller units must be consistent, and value operations do not mutate operands. |

## Compatibility decisions

Compatibility is not deprecation. No warning or removal is proposed.

| Compatibility entry | Decision | Replacement / semantic difference |
| --- | --- | --- |
| `IMatrix` | Replace in new code | Use `IDenseDoubleMatrix`; conversion is an explicit deep copy and typed algorithms use separate kernels, factors, results, and `SizeInt` shapes. |
| `TMatrixKit` | Replace in new code | Use `TDenseDoubleMatrix`; it is a named factory, not a cast or subclass replacement. |
| `TMatrixKitSparse` | Replace in new code | Use `TSparseDoubleMatrix`, which creates canonical CSR/CSC `ISparseDoubleMatrix` values. Conversion enumerates/copies; it is never a zero-copy reinterpretation. |
| `FinanceLib.Bonds` | Retain | Its four public names are exact focused aliases of `TFinanceKit`, `EFinanceError`, and amortization types. |
| `FinanceLib.NPV` | Retain | Its three public names are exact focused aliases of `TFinanceKit`, `EFinanceError`, and `TDoubleArray`. |

The generated declaration reference repeats the decision, replacement, and
semantic-note identifier on every exact compatibility row. There are no formal
deprecations and no undecided stable declarations, compiled defaults, ownership
rules, classifications, or replacement mappings.
