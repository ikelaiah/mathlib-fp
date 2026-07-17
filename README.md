<p align="center">
  <img src="docs/assets/mathlib-fp-logo.svg" alt="mathlib-fp — mathematics and engineering for Free Pascal" width="760">
</p>

# mathlib-fp

<p align="center">
  <strong>Practical mathematics for Free Pascal.</strong><br>
  Scientific, statistical, financial, engineering, and machine-learning tools—with no third-party runtime dependencies.
</p>

<p align="center">
  <a href="https://www.freepascal.org/"><img alt="Free Pascal 3.2.2+" src="https://img.shields.io/badge/Free%20Pascal-3.2.2+-blue.svg"></a>
  <a href="https://www.lazarus-ide.org/"><img alt="Lazarus 3.6+" src="https://img.shields.io/badge/Lazarus-3.6+-blue.svg"></a>
  <img alt="Version 1.2.0" src="https://img.shields.io/badge/version-1.2.0-orange.svg">
  <a href="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml"><img alt="CI status" src="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE.md"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-yellow.svg"></a>
</p>

## ✨ Why mathlib-fp?

- **Broad:** 12 focused libraries, from matrices and probability to geometry and ARIMA.
- **Native:** written for FPC 3.2.2+ in `objfpc` mode.
- **Lightweight:** use only the units you need; no third-party runtime dependencies.
- **Ready to explore:** reference docs, runnable examples, and 747 passing tests.

> [!NOTE]
> **1.2.0 is the first public release.** The library follows semantic versioning;
> read the [release notes](docs/RELEASE_NOTES_1.2.0.md) and
> [changelog](CHANGELOG.md) when upgrading.

## 🚀 Quick start

Download the source archive from the [latest GitHub release](https://github.com/ikelaiah/mathlib-fp/releases/latest), or clone the repository:

```bash
git clone https://github.com/ikelaiah/mathlib-fp.git
cd mathlib-fp
```

Save this as `my_program.lpr`:

```pascal
program hello_mathlib;

{$mode objfpc}{$H+}

uses
  ProbabilityLib.Distributions;

begin
  Writeln('P(Z <= 1.96) = ', TProbabilityKit.NormalCDF(1.96, 0, 1):0:6);
end.
```

Compile it with `src/` on the unit search path:

```bash
mkdir -p lib
fpc -Fusrc -FUlib my_program.lpr
./my_program
```

Using Lazarus? Add `src/` under **Project Options → Compiler Options → Paths → Other Unit Files**, or install the mathlib-fp package from [`packages/lazarus/mathlib_fp.lpk`](packages/lazarus/mathlib_fp.lpk).

## 🧰 What's included

| Library | Highlights |
| --- | --- |
| [MathBase](docs/MathBase.md) | Shared types, constants, precision, trigonometry |
| [AlgebraLib](docs/AlgebraLib.md) | Matrices, decompositions, linear solvers |
| [FinanceLib](docs/FinanceLib.md) | TVM, bonds, NPV/IRR, options, risk metrics |
| [StatsLib](docs/StatsLib.md) | Descriptive statistics, tests, correlation, bootstrap |
| [EngineeringLib](docs/EngineeringLib.md) | Fluids, thermodynamics, signals, unit conversion |
| [NumericsLib](docs/NumericsLib.md) | Root finding, integration, ODEs, interpolation |
| [ProbabilityLib](docs/ProbabilityLib.md) | Continuous and discrete distributions |
| [CombinatoricsLib](docs/CombinatoricsLib.md) | Counting, sequences, number theory, permutations |
| [OptimizationLib](docs/OptimizationLib.md) | Scalar, multivariate, constrained, linear optimization |
| [TimeSeriesLib](docs/TimeSeriesLib.md) | Smoothing, decomposition, ARIMA, anomaly detection |
| [MLLib](docs/MLLib.md) | Preprocessing, regression, classification, clustering, PCA |
| [GeometryLib](docs/GeometryLib.md) | 2-D and 3-D computational geometry |

All public units live in `src/`; the libraries can be used independently unless their documentation says otherwise.

## 🧪 Try an example

The [`examples/`](examples/) directory contains 12 small walkthroughs covering
the major library workflows. Compile one in seconds:

```bash
cd examples
mkdir -p lib
fpc -Fu../src -FUlib 05_unit_conversion.lpr
./05_unit_conversion
```

On Windows, run the generated `.exe` instead. Start with the [documentation index](docs/index.md) for the full API tour.

## 🤝 Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) to get started, or run the full test suite locally:

```bash
cd tests
mkdir -p lib
fpc -Fu../src -FUlib TestRunner.lpr
./TestRunner -a --format=plain
```

Maintainers preparing a distribution should follow the [release checklist](RELEASING.md).

## 📄 License

[MIT](LICENSE.md) © the mathlib-fp contributors.

<sub>Originally extracted from <a href="https://github.com/ikelaiah/tidykit-fp">tidykit-fp</a>.</sub>
