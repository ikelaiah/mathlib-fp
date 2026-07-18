# mathlib-fp

A collection of focused Free Pascal mathematics domains organised as a single
source tree and distribution.

## Releases

- [mathlib-fp 1.2.1 release notes](RELEASE_NOTES_1.2.1.md) — terminology and
  public API naming consistency.
- [mathlib-fp 1.2.0 release notes](RELEASE_NOTES_1.2.0.md) — first public
  release.

## Terminology

mathlib-fp uses the following terms consistently:

| Term | Meaning | Example |
|------|---------|---------|
| Project or distribution | The complete versioned source release | mathlib-fp 1.2.1 |
| Domain | A functional area within mathlib-fp | Finance, algebra, geometry |
| Unit family | The shared prefix of related Pascal units | `FinanceLib`, `AlgebraLib` |
| Unit | A Pascal compilation unit named in a `uses` clause | `FinanceLib.Interest` |
| Kit class | A public calculation facade, usually exposing class-static methods | `TFinanceKit` |
| Focused alias unit | A narrow import path that aliases a Kit class or supporting types | `FinanceLib.Bonds` |
| Lazarus package | The optional IDE package containing the project units | `mathlib_fp.lpk` |

“Kit” describes an API class, not a domain or unit. Supporting units containing
constants, types, low-level functions, or exception declarations do not need an
artificial Kit class.

## Domains

| Unit family | Domain | Depends on |
|---------|-------------|------------|
| [MathBase](MathBase.md) | Shared types, constants, precision functions, and trigonometry | RTL |
| [AlgebraLib](AlgebraLib.md) | Dense matrix ops, decompositions, iterative solvers, vectors | MathBase |
| [FinanceLib](FinanceLib.md) | Time value of money, bonds, NPV/IRR, options, ratios, risk metrics | MathBase |
| [StatsLib](StatsLib.md) | Descriptive stats, hypothesis testing, correlation, bootstrap | MathBase |
| [EngineeringLib](EngineeringLib.md) | Fluid dynamics, thermodynamics, signal processing, unit conversion | MathBase |
| [NumericsLib](NumericsLib.md) | Root finding, numerical integration, ODE solvers, interpolation | MathBase |
| [ProbabilityLib](ProbabilityLib.md) | Continuous and discrete probability distributions | MathBase |
| [CombinatoricsLib](CombinatoricsLib.md) | Counting, sequences, number theory, permutations, combinations | MathBase |
| [OptimizationLib](OptimizationLib.md) | Scalar, vector, constrained, and linear optimization | MathBase |
| [TimeSeriesLib](TimeSeriesLib.md) | Smoothing, decomposition, ARIMA, anomaly detection | MathBase |
| [MLLib](MLLib.md) | Preprocessing, regression, classifiers, clustering, PCA, metrics | MathBase |
| [GeometryLib](GeometryLib.md) | 2-D and 3-D computational geometry | MathBase |

## Public API naming inventory

| Domain | Primary units | Public Kit classes |
|--------|---------------|--------------------|
| Math foundation | `MathBase.SharedTypes`, `MathBase.MathConstants`, `MathBase.Precision`, `MathBase.Trigonometry` | `TTrigKit` |
| Algebra | `AlgebraLib.Matrices`, `AlgebraLib.Vectors`, `AlgebraLib.Determinants` | `TMatrixKit` |
| Finance | `FinanceLib.Interest`, `FinanceLib.Bonds`, `FinanceLib.NPV` | `TFinanceKit`; aliases `TBondKit`, `TNPVKit` |
| Statistics | `StatsLib.Stats` | `TStatsKit` |
| Engineering | `EngineeringLib.FluidDynamics`, `EngineeringLib.Thermodynamics`, `EngineeringLib.Signal`, `EngineeringLib.UnitConversion` | `TFluidDynamicsKit`, `TThermodynamicsKit`, `TSignalKit`, `TUnitConversionKit`; aliases `TVelocityKit`, `TPressureKit` |
| Numerics | `NumericsLib.Numerics` | `TNumericsKit` |
| Probability | `ProbabilityLib.Distributions` | `TProbabilityKit` |
| Combinatorics | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit` |
| Optimization | `OptimizationLib.Optimization` | `TOptimizationKit` |
| Time series | `TimeSeriesLib.TimeSeries` | `TTimeSeriesKit` |
| Machine learning | `MLLib.MachineLearning` | `TMLKit` |
| Geometry | `GeometryLib.Geometry` | `TGeometryKit` |

## Dependency Graph

```text
MathBase
├── AlgebraLib
├── FinanceLib
├── StatsLib
├── EngineeringLib
├── NumericsLib
├── ProbabilityLib
├── CombinatoricsLib
├── OptimizationLib
├── TimeSeriesLib
├── MLLib
└── GeometryLib
```

## Common Base Types

All domains share the types defined in `MathBase.SharedTypes`:

```pascal
TIntegerArray  = array of Integer;
TDoubleArray   = array of Double;
TSingleArray   = array of Single;
TExtendedArray = array of Extended;
TDoublePair    = record Lower, Upper: Double; end;
```

## Design Principles

- Kit classes normally use static class methods for stateless calculations.
- `TMatrixKit` also implements `IMatrix`; it is the established matrix factory
  and concrete implementation as well as the algebra Kit class.
- Collection APIs use `TDoubleArray`, `TIntegerArray`, or documented matrix aliases.
- Optional `ADecimals` parameters round scalar results where documented.
- Invalid inputs raise typed exceptions such as `EFinanceError`, `EStatsError`,
  `EMatrixError`, `EProbabilityError`, or the domain-specific equivalent.
