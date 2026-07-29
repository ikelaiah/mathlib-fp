# mathlib-fp

A collection of focused Free Pascal mathematics domains organised as a single
source tree and distribution.

See the [roadmap](ROADMAP.md) for the quality-first path toward a comprehensive
native Free Pascal numerical package.

## Releases

- [mathlib-fp 1.7.0 release notes](RELEASE_NOTES_1.7.0.md) — interpolation,
  fitting, adaptive integration/ODEs, differentiation, and convex optimisation.
- [1.7.0 PR notes](PR_NOTES_1.7.0.md) — review scope, compatibility, local
  verification, risks, and explicitly deferred work.
- [1.7.0 qualification report](QUALIFICATION_1.7.0.md) — modelling accuracy,
  diagnostics, reentrancy, examples, and target checks.
- [mathlib-fp 1.6.0 release notes](RELEASE_NOTES_1.6.0.md) — typed dense
  QR/CPQR, SVD, eigensystems, and inspectable direct-solve diagnostics.
- [1.6.0 qualification report](QUALIFICATION_1.6.0.md) — algorithm-specific
  residual, reconstruction, target, example, and benchmark evidence.
- [mathlib-fp 1.5.0 release notes](RELEASE_NOTES_1.5.0.md) — typed contiguous
  single/double real/complex matrices, kernels, and direct solve.
- [1.5.0 qualification report](QUALIFICATION_1.5.0.md) — target
  configurations, numerical evidence, benchmarks, dependencies, and gaps.
- [mathlib-fp 1.4.0 release notes](RELEASE_NOTES_1.4.0.md) — GeometryLib vector
  arithmetic and scale-safe normalization.
- [mathlib-fp 1.3.0 release notes](RELEASE_NOTES_1.3.0.md) — complex and
  vector foundation.
- [mathlib-fp 1.2.3 release notes](RELEASE_NOTES_1.2.3.md) — numerical
  correctness, special-function accuracy, and robust probability tails.
- [mathlib-fp 1.2.2 release notes](RELEASE_NOTES_1.2.2.md) — complete
  newcomer example coverage and cross-platform example builds.
- [mathlib-fp 1.2.1 release notes](RELEASE_NOTES_1.2.1.md) — terminology and
  public API naming consistency.
- [mathlib-fp 1.2.0 release notes](RELEASE_NOTES_1.2.0.md) — first public
  release.

## Terminology

mathlib-fp uses the following terms consistently:

| Term | Meaning | Example |
|------|---------|---------|
| Project or distribution | The complete versioned source release | mathlib-fp 1.3.0 |
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
| [AlgebraLib](AlgebraLib.md) | Compatibility matrices plus [typed dense storage/kernels](TypedDenseMatrices.md) and [decompositions/direct solvers](DenseLinearAlgebra.md) | MathBase |
| [FinanceLib](FinanceLib.md) | Time value of money, bonds, NPV/IRR, options, ratios, risk metrics | MathBase |
| [StatsLib](StatsLib.md) | Descriptive stats, hypothesis testing, correlation, bootstrap | MathBase |
| [EngineeringLib](EngineeringLib.md) | Fluid dynamics, thermodynamics, signal processing, unit conversion | MathBase |
| [NumericsLib](NumericsLib.md) | Root finding and introductory numerical methods; [advanced modelling](NumericalModelling.md) | MathBase / AlgebraLib |
| [ProbabilityLib](ProbabilityLib.md) | Continuous and discrete probability distributions | MathBase |
| [CombinatoricsLib](CombinatoricsLib.md) | Counting, sequences, number theory, permutations, combinations | MathBase |
| [OptimizationLib](OptimizationLib.md) | Scalar/vector optimisation and LP; [dense convex QP/SOCP](ConvexOptimization.md) | MathBase / AlgebraLib |
| [TimeSeriesLib](TimeSeriesLib.md) | Smoothing, decomposition, ARIMA, anomaly detection | MathBase |
| [MLLib](MLLib.md) | Preprocessing, regression, classifiers, clustering, PCA, metrics | MathBase |
| [GeometryLib](GeometryLib.md) | 2-D and 3-D computational geometry | MathBase |

## Public API naming inventory

| Domain | Primary units | Public Kit classes |
|--------|---------------|--------------------|
| Math foundation | `MathBase.SharedTypes`, `MathBase.Complex`, `MathBase.MathConstants`, `MathBase.Precision`, `MathBase.Trigonometry` | `TTrigKit` |
| Algebra | `AlgebraLib.Matrices`, `AlgebraLib.VectorKernels`, `AlgebraLib.Vectors`, `AlgebraLib.Determinants`, `AlgebraLib.DenseMatrices`, `AlgebraLib.DenseKernels`, `AlgebraLib.DenseSolvers`, `AlgebraLib.DenseDecompositions` | `TMatrixKit`, `TVectorKit`, typed dense factories and factors |
| Finance | `FinanceLib.Interest`, `FinanceLib.Bonds`, `FinanceLib.NPV` | `TFinanceKit`; aliases `TBondKit`, `TNPVKit` |
| Statistics | `StatsLib.Stats` | `TStatsKit` |
| Engineering | `EngineeringLib.FluidDynamics`, `EngineeringLib.Thermodynamics`, `EngineeringLib.Signal`, `EngineeringLib.UnitConversion` | `TFluidDynamicsKit`, `TThermodynamicsKit`, `TSignalKit`, `TUnitConversionKit`; aliases `TVelocityKit`, `TPressureKit` |
| Numerics | `NumericsLib.Numerics`, `NumericsLib.Differentiation`, `NumericsLib.Interpolation`, `NumericsLib.Modelling` | `TNumericsKit`, `TDifferentiationKit`, `TInterpolationKit`, `TModellingKit` |
| Probability | `ProbabilityLib.Distributions` | `TProbabilityKit` |
| Combinatorics | `CombinatoricsLib.Combinatorics` | `TCombinatoricsKit` |
| Optimization | `OptimizationLib.Optimization`, `OptimizationLib.Convex` | `TOptimizationKit`, `TConvexOptimizationKit` |
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
TComplexArray  = array of TComplex;  // MathBase.Complex
TSingleComplexArray = array of TSingleComplex;
```

## Design Principles

- Kit classes normally use static class methods for stateless calculations.
- `TMatrixKit` also implements `IMatrix`; it is the established matrix factory
  and concrete implementation as well as the algebra Kit class.
- The [typed dense API](TypedDenseMatrices.md) is the contiguous single/double
  real/complex path. Its [migration guide](MIGRATING_TO_TYPED_DENSE.md) names
  copy and allocation costs.
- Collection APIs use `TDoubleArray`, `TIntegerArray`, or documented matrix aliases.
- Optional `ADecimals` parameters round scalar results where documented.
- Invalid inputs raise typed exceptions such as `EFinanceError`, `EStatsError`,
  `EMatrixError`, `EProbabilityError`, or the domain-specific equivalent.

## Find an algorithm

| Problem | Recommended starting point |
| --- | --- |
| Solve a square dense system | [`Solve(A, B)`](TypedDenseMatrices.md#60-second-solve) |
| Repeated dense solves | [`FactorLU`](TypedDenseMatrices.md#factorisation-outcomes) |
| Positive-definite dense solve | [`FactorCholesky`](TypedDenseMatrices.md#choose-an-entry-point) |
| Typed matrix multiplication | [`Multiply` / `MultiplyInto`](TypedDenseMatrices.md#choose-an-entry-point) |
| Compatibility `IMatrix` operations | [AlgebraLib compatibility reference](AlgebraLib.md) |
| Interpolation, fitting, adaptive integration, vector roots, or ODEs | [Numerical modelling selection guide](NumericalModelling.md#choose-an-algorithm) |
| Dense convex QP or second-order cones | [Convex optimisation selection guide](ConvexOptimization.md#choose-a-solver) |
| Supported and missing families | [Capability inventory](CAPABILITIES.md) |

See the [supported platform matrix](SUPPORT.md) for compiler, target, and
precision qualifications.
