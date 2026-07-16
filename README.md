<p align="center">
  <img src="docs/assets/mathlib-fp-logo.svg" alt="mathlib-fp — mathematics and engineering for Free Pascal" width="760">
</p>

# mathlib-fp

[![FPC](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.6+-blue.svg)](https://www.lazarus-ide.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Tests](https://img.shields.io/badge/Tests-720%20passing-brightgreen.svg)](tests/)
![Status](https://img.shields.io/badge/Status-Development-yellow.svg)

A focused Free Pascal math library collection for scientific, engineering,
statistical, financial, optimization, time-series, machine-learning, and
geometry work. The source has no third-party runtime dependencies.

> [!NOTE]
> This project was previously part of [tidykit-fp](https://github.com/ikelaiah/tidykit-fp). The math modules were separated into this standalone repository on 2026-04-14.
> This library is under active development and APIs may change before the next stable release.

---

## Libraries

| Library | Description | Main Class |
| ------- | ----------- | ---------- |
| [MathBase](docs/MathBase.md) | Shared types, constants, precision helpers, and trigonometry | `TTrigKit` |
| [AlgebraLib](docs/AlgebraLib.md) | Dense matrix operations, decompositions, and linear solvers | `TMatrixKit` / `IMatrix` |
| [FinanceLib](docs/FinanceLib.md) | Time value of money, bonds, NPV/IRR, option pricing, ratios, risk metrics | `TFinanceKit` |
| [StatsLib](docs/StatsLib.md) | Descriptive stats, hypothesis tests, correlation, bootstrap, non-parametric tests | `TStatsKit` |
| [EngineeringLib](docs/EngineeringLib.md) | Fluid dynamics, thermodynamics, signal processing, unit conversion | `TFluidDynamicsKit`, `TThermodynamicsKit`, `TSignalKit`, `TUnitConversionKit` |
| [NumericsLib](docs/NumericsLib.md) | Root finding, numerical integration, ODE solvers, interpolation | `TNumericsKit` |
| [ProbabilityLib](docs/ProbabilityLib.md) | Continuous and discrete probability distributions | `TProbabilityKit` |
| [CombinatoricsLib](docs/CombinatoricsLib.md) | Counting, sequences, number theory, permutations, combinations | `TCombinatoricsKit` |
| [OptimizationLib](docs/OptimizationLib.md) | Univariate, multivariate, constrained, and linear optimization | `TOptimizationKit` |
| [TimeSeriesLib](docs/TimeSeriesLib.md) | Smoothing, decomposition, ACF/PACF, ARIMA, anomaly detection | `TTimeSeriesKit` |
| [MLLib](docs/MLLib.md) | Preprocessing, regression, classifiers, clustering, PCA, metrics | `TMLKit` |
| [GeometryLib](docs/GeometryLib.md) | 2-D and 3-D computational geometry | `TGeometryKit` |

---

## Repository Layout

```text
mathlib-fp/
├── fpmake.pp              # FPMake/FPPKG package definition
├── src/                    # all library units; add this folder to -Fu
├── docs/                   # per-library reference documentation
├── examples/               # runnable example programs
├── packages/lazarus/       # Lazarus package metadata
└── tests/                  # FPCUnit test runner and suites
```

All public units live in `src/`. Add that one folder to your compiler unit
search path and include only the units your program uses.

---

## Getting Started

### Clone

```bash
git clone https://github.com/ikelaiah/mathlib-fp
cd mathlib-fp
```

### Add the Source Path

#### Lazarus IDE

Open `Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files`
and add:

```text
../src
```

You can also open/install the Lazarus package at
`packages/lazarus/pascal_mathlibs.lpk`.

#### FPC Command Line

Use `-Fu` for the library sources and `-FU` for compiler output:

```bash
mkdir -p lib
fpc -Fusrc -FUlib my_program.lpr
```

#### FPMake / FPPKG

The repository includes `fpmake.pp` for command-line package workflows. A
configured FPPKG installation can build or install the package from the
repository root:

```bash
fppkg build
fppkg install
```

FPPKG configuration is compiler-installation specific; direct `-Fusrc` builds
remain the simplest option when FPPKG has not been configured.

### Source Mode

All units use `objfpc` mode. Put this before the `program` or `unit` keyword:

```pascal
{$mode objfpc}{$H+}
```

---

## Examples

The [examples/](examples/) folder contains one walkthrough per library area:

| File | What it shows |
|------|---------------|
| [examples/01_stats_basics.lpr](examples/01_stats_basics.lpr) | Descriptive stats, percentiles, correlation, bootstrap CI |
| [examples/02_hypothesis_test.lpr](examples/02_hypothesis_test.lpr) | t-test, Mann-Whitney U, Wilcoxon signed-rank, effect size |
| [examples/03_matrix_operations.lpr](examples/03_matrix_operations.lpr) | Matrix arithmetic, inverse, LU/QR decomposition |
| [examples/04_finance_npv_irr.lpr](examples/04_finance_npv_irr.lpr) | PV/FV, NPV/IRR, loan payment, amortization schedule |
| [examples/05_unit_conversion.lpr](examples/05_unit_conversion.lpr) | Length, mass, temperature, velocity, pressure, energy |
| [examples/06_fluid_dynamics.lpr](examples/06_fluid_dynamics.lpr) | Reynolds number, Bernoulli, head loss, aerodynamics |
| [examples/07_probability.lpr](examples/07_probability.lpr) | Probability distributions, CDFs, survival functions |
| [examples/08_combinatorics.lpr](examples/08_combinatorics.lpr) | Factorials, combinations, primes, permutations |
| [examples/09_optimization.lpr](examples/09_optimization.lpr) | Scalar, vector, constrained, and linear optimization |
| [examples/10_timeseries.lpr](examples/10_timeseries.lpr) | Smoothing, decomposition, ARIMA, anomaly detection |
| [examples/11_machinelearning.lpr](examples/11_machinelearning.lpr) | Preprocessing, regression, classifiers, clustering, PCA |
| [examples/12_geometry.lpr](examples/12_geometry.lpr) | 2-D/3-D geometry, intersections, polygons, convex hulls |

Compile one example:

```bash
cd examples
mkdir -p lib
fpc -Fu../src -FUlib 05_unit_conversion.lpr
./05_unit_conversion
```

On Windows, run the generated `.exe`.

---

## Quick Start

```pascal
uses
  MathBase.SharedTypes,
  AlgebraLib.Matrices,
  FinanceLib.Interest,
  StatsLib.Stats,
  EngineeringLib.UnitConversion,
  NumericsLib.Numerics,
  ProbabilityLib.Distributions,
  CombinatoricsLib.Combinatorics,
  OptimizationLib.Optimization,
  TimeSeriesLib.TimeSeries,
  MLLib.MachineLearning,
  GeometryLib.Geometry;
```

### Statistics

```pascal
uses MathBase.SharedTypes, StatsLib.Stats;

var
  Data: TDoubleArray;
  Stats: TDescriptiveStats;
begin
  Data := TDoubleArray.Create(4.5, 3.0, 5.0, 4.0, 4.8);
  Stats := TStatsKit.Describe(Data);
  Writeln(Stats.ToString);
end.
```

### Matrix Operations

```pascal
uses AlgebraLib.Matrices;

var
  A: IMatrix;
begin
  A := TMatrixKit.CreateFromArray([[3.0, 1.0], [1.0, 3.0]]);
  Writeln('Det  = ', A.Determinant:0:4);
  Writeln('Rank = ', A.Rank);
end.
```

### Probability

```pascal
uses ProbabilityLib.Distributions;

begin
  Writeln('P(Z <= 1.96) = ', TProbabilityKit.NormalCDF(1.96, 0, 1):0:6);
end.
```

---

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

Peer libraries are designed to be used independently unless a specific unit
documents otherwise.

---

## System Requirements

- Free Pascal Compiler (FPC) 3.2.2+
- Lazarus 3.6+ (optional, for IDE/package workflows)
- Tested locally on Windows 11 and Ubuntu 24.04

---

## Testing

Compile and run the test runner:

```bash
cd tests
mkdir -p lib
fpc -Fu../src -FUlib TestRunner.lpr
./TestRunner -a --format=plain
```

On Windows:

```powershell
cd tests
New-Item -ItemType Directory -Path lib -Force
fpc "-Fu..\src" "-FUlib" TestRunner.lpr
.\TestRunner.exe -a --format=plain
```

Current local result: **720 tests, 0 errors, 0 failures**. A clean rebuild with
`-FcUTF8` also completes with zero compiler warnings. Set
`MATHLIB_TEST_VERBOSE=1` to enable the algebra suite's diagnostic matrices and
timings.

---

## License

MIT — see [LICENSE.md](LICENSE.md).

---

## Acknowledgments

- FPC Team for Free Pascal
- Original tidykit-fp contributors
