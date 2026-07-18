# mathlib-fp

A collection of focused Free Pascal mathematics libraries organised as a
single source tree.

## Releases

- [mathlib-fp 1.2.0 release notes](RELEASE_NOTES_1.2.0.md) — first public
  release.

## Libraries

| Library | Description | Depends on |
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

All libraries share the types defined in `MathBase.SharedTypes`:

```pascal
TIntegerArray  = array of Integer;
TDoubleArray   = array of Double;
TSingleArray   = array of Single;
TExtendedArray = array of Extended;
TDoublePair    = record Lower, Upper: Double; end;
```

## Design Principles

- Kit classes use static class methods for stateless calculations.
- Collection APIs use `TDoubleArray`, `TIntegerArray`, or documented matrix aliases.
- Optional `ADecimals` parameters round scalar results where documented.
- Invalid inputs raise typed exceptions such as `EFinanceError`, `EStatsError`,
  `EMatrixError`, `EProbabilityError`, or the library-specific equivalent.
