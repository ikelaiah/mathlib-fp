# 1.9.7 migration and compatibility rehearsal

Version 1.9.7 proves source migration paths before 2.0 changes any
documentation default. It does not ship a separate 2.0 binary API, remove a
1.x declaration, or claim drop-in compatibility with another numerical
library. The candidate examples use conventions already available in 1.9.7.

## Run the evidence

From a source archive with FPC 3.2.2:

```bash
python tools/test_migration_rehearsal.py
python tools/check_migration_rehearsal.py --compiler fpc
lazbuild --build-all packages/lazarus/mathlib_fp.lpk
```

The checker compiles and runs the supported-1.x consumer, the candidate-2.0
consumer, and the pressure/velocity package-boundary consumer. It validates
[`migration-rehearsal-1.9.7.json`](migration-rehearsal-1.9.7.json), checks that
the four focused aliases and their canonical units stay in the main Lazarus
package without a new dependency, and writes host-specific evidence under
`build-temp/migration-rehearsal/`.

## Side-by-side consumers

| Concern | Supported 1.x | Candidate 2.0 convention |
| --- | --- | --- |
| Project | [`consumer_1_9.lpr`](../examples/migration/one_x/consumer_1_9.lpr) | [`consumer_2_0.lpr`](../examples/migration/candidate_2_0/consumer_2_0.lpr) |
| Matrix storage | `IMatrix`/`TMatrixKit` remains supported | Prefer scalar-explicit `IDenseDoubleMatrix` and `TDenseDoubleMatrix` |
| Fluid dynamics | `TPressureKit`, `TVelocityKit` and focused errors remain supported | Prefer `TFluidDynamicsKit` and `EFluidDynamicsError` for new code |
| Ownership | Interfaces retain storage; streams are caller-owned | Same; use `Clone` when independent mutable dense storage is required |
| Indexing | Zero-based | Zero-based; shapes and views remain explicit |
| Precision | Existing API-specific `Double` contracts | Prefer type-named dense/sparse entry points; no silent scalar conversion |
| Diagnostics | Existing exceptions and result records | Prefer explicit result/status records where offered |
| Compiler warnings | None expected | None expected; 1.9.7 emits no deprecation warnings |

Both projects assert construction, ordinary results, diagnostic failures,
ownership/copy behavior, zero-based indexing, precision, defaults, and result
interpretation across every documented domain:

| Domain | Executed migration point | Important interpretation |
| --- | --- | --- |
| MathBase | `GammaLn` at `Double` precision | Scalar precision and tolerance stay explicit. |
| AlgebraLib | Legacy independent arithmetic result vs typed `Clone` | Interface assignment shares storage; cloning/copy-producing operations do not. |
| FinanceLib | `PresentValue` with its default decimal count | Default rounding remains part of the result contract. |
| EngineeringLib | Focused aliases vs common fluid facade | The aliases are exact types, not narrower pressure/velocity implementations. |
| StatsLib | `Mean` over `TDoubleArray` | Dynamic arrays are zero-based and caller-owned. |
| ProbabilityLib | Standard normal CDF | Parameters are explicit; no global distribution state is introduced. |
| CombinatoricsLib | Exact small factorial | Integer results must not be interpreted as floating approximations. |
| NumericsLib | `BrentResult` | Read convergence and residual diagnostics with the root. |
| OptimizationLib | `GoldenSection` defaults | Default tolerance/iteration behavior is unchanged in 1.9.7. |
| TimeSeriesLib | Centred moving average | Output length matches input and edge windows use available values. |
| MLLib | Row-major normalization | `X[row][column]`; returned arrays own their copied result storage. |
| InterchangeLib | Matrix and local-RNG state round trips | Streams are caller-owned; loaded matrices and states are explicit values. |
| GeometryLib | `TPoint2D` distance | Geometry records have value semantics and `Double` coordinates. |

## Source-edit rehearsal

Existing 1.x code needs no edit. To adopt the proposed common paths early:

```pascal
// Supported focused path
uses EngineeringLib.Pressure, EngineeringLib.Velocity;
Pressure := TPressureKit.DynamicPressure(Density, Velocity);
Mach := TVelocityKit.MachNumber(Velocity, SpeedOfSound);
```

becomes:

```pascal
// Candidate common path, already shipped in 1.9.7
uses EngineeringLib.Common, EngineeringLib.FluidDynamics;
Pressure := TFluidDynamicsKit.DynamicPressure(Density, Velocity);
Mach := TFluidDynamicsKit.MachNumber(Velocity, SpeedOfSound);
```

`EPressureError` and `EVelocityError` can likewise be named
`EFluidDynamicsError`. The executable
[`alias_boundary.lpr`](../examples/migration/package_boundary/alias_boundary.lpr)
proves facade type identity, exception identity, and equal numerical results.

## Packaging decision

All four candidates remain in place in the main `mathlib_fp` package:

| Entry | Canonical path for new code | 1.9.7 decision | Reason |
| --- | --- | --- | --- |
| `EngineeringLib.Pressure.EPressureError` | `EngineeringLib.Common.EFluidDynamicsError` | Retain; do not deprecate | Exact exception alias; moving it would break the focused-unit import without improving runtime behavior. |
| `EngineeringLib.Pressure.TPressureKit` | `EngineeringLib.FluidDynamics.TFluidDynamicsKit` | Retain; do not deprecate | Exact facade alias; it preserves discoverable pressure imports and adds no dependency. |
| `EngineeringLib.Velocity.EVelocityError` | `EngineeringLib.Common.EFluidDynamicsError` | Retain; do not deprecate | Exact exception alias; no tested benefit justifies a warning. |
| `EngineeringLib.Velocity.TVelocityKit` | `EngineeringLib.FluidDynamics.TFluidDynamicsKit` | Retain; do not deprecate | Exact facade alias; it preserves source compatibility without duplicate implementation. |

Compatibility period: all four declarations remain supported throughout the
1.x line. Because 1.9.7 rejects deprecation, no removal runway begins. A future
proposal would need a later minor release with a shipped replacement, warning,
owner, migration guide, and exercised compatibility period before removal could
be considered.

## NumLib conceptual mappings

These are source-migration directions, not declaration-by-declaration wrappers.
The upstream [NumLib unit reference](https://www.freepascal.org/daily/packages/numlib/numlib/index.html)
shows its dependency on `typ`; the FPC project has also documented the
historical fixed-bound `ArbFloat`/matrix storage model. mathlib-fp does not
accept an untyped first element plus implicit bounds.

| NumLib concept | mathlib-fp destination | Required source/semantic changes |
| --- | --- | --- |
| `typ` `ArbFloat` vectors and matrices | `TDoubleArray`, `IDenseDoubleMatrix`, or typed sparse interfaces | Allocate explicit shapes, copy values deliberately, and convert NumLib bounds to zero-based indices. |
| Scalar roots and quadrature | `TNumericsKit.*Result`, `BrentResult`, Simpson/Gauss helpers | Adapt callback signatures; inspect convergence/residual fields; verify tolerance and endpoint assumptions. |
| Dense linear systems | `SolveWithInfo` and typed decompositions | Build a row-major typed matrix; choose a solver by structure; interpret residual/rank diagnostics. |
| Statistics/probability | `TStatsKit`, `TProbabilityKit` | Separate sample statistics from parameterized distributions; retain explicit parameters and tail meaning. |

Unsupported: pointer-plus-bounds call compatibility, NumLib routine-name
aliases, one-based or caller-selected lower bounds, implicit matrix leading
dimensions, and a promise that stopping rules or exceptional cases match.

## LMath/DMath conceptual mappings

The upstream [LMath 0.6.1 project notes](https://sourceforge.net/projects/lmath-library/files/LMath/)
describe `TVector`/`TMatrix`, historical `Lb`/`Ub` slice arguments, a mix of
mutating and value-style overloads, multiple Lazarus packages, and a GPL DSP
unit within an otherwise differently licensed distribution. The original
[DMath/TPMath page](https://www.unilim.fr/pages_perso/jean.debord/tpmath/tpmath.htm)
identifies DMath as a separate Delphi/FPC/Lazarus distribution. None of those
package, symbol, mutation, or licensing boundaries are reproduced here.

| LMath/DMath concept | mathlib-fp destination | Required source/semantic changes |
| --- | --- | --- |
| `TVector`/`TMatrix`, `Lb`/`Ub` slices | Shared arrays and typed dense/sparse matrices/views | Convert explicit bounds to zero-based values or views; choose shared vs cloned storage deliberately. |
| `uMeanSD`/`uMathStat` | `TStatsKit`, `TOnlineStatistics`, inference APIs | Confirm sample/population denominator, missing-value policy, tail definition, and returned diagnostics. |
| `uNonLinEq`/integral units | `TNumericsKit` and `TModellingKit` | Adapt callbacks; select an algorithm explicitly; inspect non-convergence status instead of assuming a scalar result. |
| `uOptimum` | `TOptimizationKit`/`TConvexOptimizationKit` | Rebuild bounds/constraints in the target model and compare feasibility plus termination status. |
| `uRegression` | `TModellingKit` and `TMLKit` | Rebuild row-major design data; verify weighting, intercept, rank, scaling, and prediction ownership. |
| `uFFT`/`uConvolutions` | `TDSPKit` | Convert real/complex storage explicitly and verify normalization, padding, output length, and licensing obligations of the source being replaced. |

Unsupported: LMath/DMath unit or package aliases, ABI compatibility, plotting
components, `Float` compile-time precision switches, automatic `Lb`/`Ub`
translation, in-place mutation equivalence, identical random sequences, and
identical convergence or exception behavior.

## What the rehearsal does not prove

- It does not make every third-party algorithm mathematically interchangeable.
- It does not qualify a platform beyond the target tiers in [SUPPORT.md](SUPPORT.md).
- It does not start a deprecation or removal clock.
- It does not replace application-specific numerical validation. Re-run domain
  reference cases, residual checks, and edge cases after migrating real code.
