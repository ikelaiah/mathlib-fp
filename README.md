<p align="center">
  <img src="docs/assets/mathlib-fp-banner-v2.svg" alt="mathlib-fp — numerical computing for Free Pascal" width="760">
</p>

# mathlib-fp

<p align="center">
  <strong>Practical mathematics for Free Pascal.</strong><br>
  Scientific, statistical, financial, engineering, and machine-learning tools—with no third-party runtime dependencies.
</p>

<p align="center">
  <a href="https://www.freepascal.org/"><img alt="Free Pascal 3.2.2+" src="https://img.shields.io/badge/Free%20Pascal-3.2.2+-blue.svg"></a>
  <a href="https://www.lazarus-ide.org/"><img alt="Lazarus 4.8+" src="https://img.shields.io/badge/Lazarus-4.8+-blue.svg"></a>
  <img alt="Version 1.9.2" src="https://img.shields.io/badge/version-1.9.2-brightgreen.svg">
  <a href="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml"><img alt="CI status" src="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE.md"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-yellow.svg"></a>
</p>

## ✨ Why mathlib-fp?

- **Broad:** 12 focused domains, from matrices and probability to geometry and ARIMA.
- **Native:** written for FPC 3.2.2+ in `objfpc` mode.
- **Lightweight:** use only the units you need; no third-party runtime dependencies.
- **Ready to explore:** searchable reference docs, runnable examples, and a
  release-qualified automated suite.

> [!NOTE]
> **1.9.2 is the current release; 1.2.0 was the first public release.** The
> project follows semantic versioning; read the
> [release notes](docs/RELEASE_NOTES_1.9.2.md) and
> [changelog](CHANGELOG.md) when upgrading.

## 🚀 Quick start

Open the [1.9.2 release page](https://github.com/ikelaiah/mathlib-fp/releases/tag/v1.9.2)
or download the source directly as
[`.tar.gz`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.2.tar.gz)
or [`.zip`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.2.zip).
You can also clone the repository:

```bash
git clone https://github.com/ikelaiah/mathlib-fp.git
cd mathlib-fp
```

Save this as `my_program.pas`:

```pascal
program hello_mathlib;

{$mode objfpc}{$H+}

uses
  ProbabilityLib.Distributions;

begin
  Writeln('P(Z <= 1.96) = ', TProbabilityKit.NormalCDF(1.96, 0, 1):0:6);
end.
```

Expected output:

```text
P(Z <= 1.96) = 0.975002
```

Compile it with `src/` on the unit search path:

```bash
mkdir -p lib
fpc -Fusrc -FUlib my_program.pas
./my_program
```

Using Lazarus? Add `src/` under **Project Options → Compiler Options → Paths → Other Unit Files**, or install the mathlib-fp package from [`packages/lazarus/mathlib_fp.lpk`](packages/lazarus/mathlib_fp.lpk).

## 🧰 What's included

| Domain (unit family) | Highlights |
| --- | --- |
| [MathBase](docs/MathBase.md) | Shared types, constants, precision, local RNG state, bounded expressions, and numerical interchange |
| [AlgebraLib](docs/AlgebraLib.md) | Compatibility matrices, [typed dense storage/solvers](docs/DenseLinearAlgebra.md), and [structured/sparse/matrix-free solvers](docs/SparseLinearAlgebra.md) |
| [FinanceLib](docs/FinanceLib.md) | TVM, bonds, NPV/IRR, options, risk metrics |
| [StatsLib](docs/StatsLib.md) | Descriptive/streaming statistics, paired distributions, inference, regression diagnostics, and bootstrap |
| [EngineeringLib](docs/EngineeringLib.md) | Fluids, thermodynamics, batch/block DSP, and unit conversion |
| [NumericsLib](docs/NumericsLib.md) | Roots, interpolation, fitting, differentiation, adaptive integration and ODEs |
| [ProbabilityLib](docs/ProbabilityLib.md) | Continuous and discrete distributions |
| [CombinatoricsLib](docs/CombinatoricsLib.md) | Counting, sequences, number theory, permutations |
| [OptimizationLib](docs/OptimizationLib.md) | Diagnostic scalar/multivariate/constrained optimisation, two-phase LP, dense convex QP and SOCP |
| [TimeSeriesLib](docs/TimeSeriesLib.md) | Smoothing, decomposition, ARIMA, anomaly detection, and scalar/multivariate Kalman filtering |
| [MLLib](docs/MLLib.md) | Leakage-safe preprocessing, regression/classification, typed clustering/PCA/LDA/forests, and exact neighbours |
| [GeometryLib](docs/GeometryLib.md) | 2-D/3-D geometry, vector arithmetic, and scale-safe norms |

All public units live in `src/`; the domains can be used independently unless
their documentation says otherwise. See the
[terminology and API naming inventory](docs/index.md#terminology) for the
difference between domains, units, and Kit classes.

## 🧪 Try an example

The [`examples/`](examples/) directory contains 24 commented walkthroughs with
at least one runnable program for every domain. Newcomers can follow the
[beginner guide](docs/BEGINNER_GUIDE.md), choose a short task from the
[beginner recipes](docs/RECIPES.md), or follow the
[example index and suggested learning path](examples/README.md). Compile one in
seconds:

```bash
cd examples
mkdir -p lib
fpc -Fu../src -FUlib 00_getting_started.pas
./00_getting_started
```

On Windows, run the generated `.exe` instead. Start with the
[versioned web documentation](https://ikelaiah.github.io/mathlib-fp/) or the
[repository documentation index](docs/index.md) for offline use. The release
page also provides the generated offline HTML archive and its SHA-256 checksum.

To compile all examples into `example-bin/` from the repository root, run
`sh ./build-examples.sh` or `.\build-examples.ps1`. See the
[example guide](examples/README.md#compile-every-example) for compiler-path
options.

## 🤝 Contributing

Bug reports and pull requests are welcome. For first-use friction, use the
[focused 1.9 feedback route](docs/FEEDBACK.md). See
[CONTRIBUTING.md](CONTRIBUTING.md) to get started, or run the full test suite locally:

```bash
cd tests
mkdir -p lib
fpc -Fu../src -FUlib TestRunner.lpr
./TestRunner -a --format=plain
```

Maintainers preparing a distribution should follow the [release checklist](RELEASING.md).
The [project roadmap](docs/ROADMAP.md) describes the quality-first path toward
a comprehensive native Free Pascal numerical package.

## 📄 License

[MIT](LICENSE.md) © the mathlib-fp contributors.

<sub>Originally extracted from <a href="https://github.com/ikelaiah/tidykit-fp">tidykit-fp</a>.</sub>
