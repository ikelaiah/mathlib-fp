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
  <img alt="Version 2.0.0 release candidate" src="https://img.shields.io/badge/version-2.0.0--rc-blue.svg">
  <a href="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml"><img alt="CI status" src="https://github.com/ikelaiah/mathlib-fp/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE.md"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-yellow.svg"></a>
</p>

## ✨ Why mathlib-fp?

- **Broad:** 13 focused domains, from matrices and probability to geometry and interchange.
- **Native:** written for FPC 3.2.2+ in `objfpc` mode.
- **Lightweight:** use only the units you need; no third-party runtime dependencies.
- **Ready to explore:** searchable reference docs, runnable examples, and a
  release-qualified automated suite.

> [!NOTE]
> **2.0.0 is a release candidate; 1.10.0 remains the latest published stable
> release.** The candidate promotes the frozen 1.10.0 API without a new
> numerical redesign. Read the [candidate notes](docs/releases/2.0.0/release-notes.md),
> the checked [freeze handoff](docs/releases/1.10.0/capability-manifest.md), and the
> [changelog](CHANGELOG.md) when evaluating an upgrade.

## 🚀 Quick start

See the [cheatsheet](docs/start/cheatsheet.md) for one canonical entry point per
domain, or the [task index](docs/guides/tasks.md) for five common tasks per
domain.

Get the source directly with git:

```bash
git clone --depth 1 --branch release/v2.0.0 \
  https://github.com/ikelaiah/mathlib-fp.git
```

or as a source archive with `wget`:

```bash
wget \
  https://github.com/ikelaiah/mathlib-fp/archive/refs/heads/release/v2.0.0.tar.gz
```

or with `curl`:

```bash
curl -L -o mathlib-fp.tar.gz \
  https://github.com/ikelaiah/mathlib-fp/archive/refs/heads/release/v2.0.0.tar.gz
```

> No package manager or install step is required for direct source use; add
> `src/` to the Free Pascal unit path, for example `fpc -Fusrc ...`.

Direct source use is canonical. The
The [1.10.0 release page](https://github.com/ikelaiah/mathlib-fp/releases/tag/v1.10.0)
remains the source of published stable `.zip`, `.tar.gz`, offline documentation,
and checksum artifacts until 2.0.0 publication.

### 1. Multiply two matrices

Save this as `multiply_matrices.pas`:

```pascal
program multiply_matrices;

{$mode objfpc}{$H+}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels;

var
  A, B, ProductMatrix: IDenseDoubleMatrix;

begin
  A := TDenseDoubleMatrix.FromArray([
    [1.0, 2.0],
    [3.0, 4.0]
  ]);
  B := TDenseDoubleMatrix.FromArray([
    [5.0, 6.0],
    [7.0, 8.0]
  ]);
  ProductMatrix := Multiply(A, B);

  Writeln('A * B =');
  Writeln(ProductMatrix[0, 0]:0:0, ' ', ProductMatrix[0, 1]:0:0);
  Writeln(ProductMatrix[1, 0]:0:0, ' ', ProductMatrix[1, 1]:0:0);
end.
```

Expected output:

```text
A * B =
19 22
43 50
```

Compile it with `src/` on the unit search path:

```bash
mkdir -p lib
fpc -Fusrc -FUlib multiply_matrices.pas
./multiply_matrices
```

### 2. Solve a system of equations

Suppose three receipts contain different quantities of coffee, sandwiches,
and juice, but only their totals remain. Solve the three simultaneous
equations to recover the price of each item. Save this as `solve_prices.pas`:

```pascal
program solve_prices;

{$mode objfpc}{$H+}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSolvers;

var
  ItemsPerReceipt, ReceiptTotals, UnitPrices: IDenseDoubleMatrix;

begin
  ItemsPerReceipt := TDenseDoubleMatrix.FromArray([
    [2.0, 1.0, 1.0],
    [1.0, 2.0, 3.0],
    [3.0, 2.0, 1.0]
  ]);
  ReceiptTotals := TDenseDoubleMatrix.FromArray([
    [18.50],
    [28.00],
    [30.00]
  ]);

  UnitPrices := Solve(ItemsPerReceipt, ReceiptTotals);

  Writeln('Coffee:  $', UnitPrices[0, 0]:0:2);
  Writeln('Sandwich: $', UnitPrices[1, 0]:0:2);
  Writeln('Juice:   $', UnitPrices[2, 0]:0:2);
end.
```

Expected output:

```text
Coffee:  $4.00
Sandwich: $7.50
Juice:   $3.00
```

Compile and run it in the same way:

```bash
fpc -Fusrc -FUlib solve_prices.pas
./solve_prices
```

Using Lazarus? Add `src/` under **Project Options → Compiler Options → Paths → Other Unit Files**, or install the mathlib-fp package from [`packages/lazarus/mathlib_fp.lpk`](packages/lazarus/mathlib_fp.lpk).

## 🧰 What's included

Each domain has a short, runnable walkthrough so you can start from a concrete
calculation and expand from there.

| Domain (unit family) | Highlights | Runnable example |
| --- | --- | --- |
| [MathBase](docs/guides/domains/math-base.md) | Shared types, constants, precision, local RNG state, bounded expressions, and numerical interchange | [Constants, precision, and trigonometry](examples/00_getting_started.pas) |
| [AlgebraLib](docs/guides/domains/algebra.md) | Compatibility matrices, [typed dense storage/solvers](docs/guides/domains/dense-linear-algebra.md), and [structured/sparse/matrix-free solvers](docs/guides/domains/sparse-linear-algebra.md) | [Matrix arithmetic and decompositions](examples/03_matrix_operations.pas) |
| [FinanceLib](docs/guides/domains/finance.md) | TVM, bonds, NPV/IRR, options, risk metrics | [NPV and IRR](examples/04_finance_npv_irr.pas) |
| [StatsLib](docs/guides/domains/statistics.md) | Descriptive/streaming statistics, paired distributions, inference, regression diagnostics, and bootstrap | [Descriptive statistics](examples/01_stats_basics.pas) |
| [EngineeringLib](docs/guides/domains/engineering.md) | Fluids, thermodynamics, batch/block DSP, and unit conversion | [Type-safe unit conversion](examples/05_unit_conversion.pas) |
| [NumericsLib](docs/guides/domains/numerics.md) | Roots, interpolation, fitting, differentiation, adaptive integration and ODEs | [Roots, integration, and ODEs](examples/13_numerical_methods.pas) |
| [ProbabilityLib](docs/guides/domains/probability.md) | Continuous and discrete distributions | [Common distributions](examples/07_probability.pas) |
| [CombinatoricsLib](docs/guides/domains/combinatorics.md) | Counting, sequences, number theory, permutations | [Counting and permutations](examples/08_combinatorics.pas) |
| [OptimizationLib](docs/guides/domains/optimization.md) | Diagnostic scalar/multivariate/constrained optimisation, two-phase LP, dense convex QP and SOCP | [Optimisation and linear programming](examples/09_optimization.pas) |
| [TimeSeriesLib](docs/guides/domains/time-series.md) | Smoothing, decomposition, ARIMA, anomaly detection, and scalar/multivariate Kalman filtering | [Smoothing and forecasting](examples/10_timeseries.pas) |
| [MLLib](docs/guides/domains/machine-learning.md) | Leakage-safe preprocessing, regression/classification, typed clustering/PCA/LDA/forests, and exact neighbours | [Models, clustering, and metrics](examples/11_machinelearning.pas) |
| [InterchangeLib](docs/guides/domains/interchange.md) | Versioned persistence for selected fitted models and numerical state | [Save, load, and replay](examples/20_interchange_replay.pas) |
| [GeometryLib](docs/guides/domains/geometry.md) | 2-D/3-D geometry, vector arithmetic, and scale-safe norms | [Intersections, hulls, and transforms](examples/12_geometry.pas) |

All public units live in `src/`; the domains can be used independently unless
their documentation says otherwise. See the
[API conventions and reference material](docs/reference/index.md) for the
difference between domains, units, and Kit classes.

## 🧪 Try an example

The [`examples/`](examples/) directory contains 27 commented walkthroughs with
at least one runnable program for every domain. Newcomers can follow the
[beginner guide](docs/start/beginner-guide.md), choose a short task from the
[beginner recipes](docs/start/recipes.md), or follow the
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
See the [support matrix](docs/project/support.md) for exact qualified targets, evidence
dates, offline installation, ABI differences, and explicitly unqualified
platforms.

To compile all examples into `example-bin/` from the repository root, run
`sh ./build-examples.sh` or `.\build-examples.ps1`. See the
[example guide](examples/README.md#compile-every-example) for compiler-path
options.

## 🤝 Contributing

Bug reports and pull requests are welcome. For first-use friction, use the
[focused 1.9 feedback route](docs/project/feedback.md). See
[CONTRIBUTING.md](CONTRIBUTING.md) to get started, or run the full test suite locally:

```bash
cd tests
mkdir -p lib
fpc -Fu../src -FUlib TestRunner.lpr
./TestRunner -a --format=plain
```

Maintainers preparing a distribution should follow the [release checklist](RELEASING.md).
The [project roadmap](docs/project/roadmap.md) describes the quality-first path toward
a comprehensive native Free Pascal numerical package.

## 📄 License

[MIT](LICENSE.md) © the mathlib-fp contributors.

## 🙏 Acknowledgments

- [Free Pascal Dev Team](https://www.freepascal.org/) for the Free Pascal compiler
- [Lazarus IDE Team](https://www.lazarus-ide.org/) for such an amazing IDE
- [Inkscape developers and contributors](https://inkscape.org/) for creating and maintaining an excellent open-source graphics editor, which helped me edit and refine the project logos and banner
- The helpful folks in various online communities:
  - [Unofficial Free Pascal Discord server](https://discord.com/channels/570025060312547359/570091337173696513)
  - [Free Pascal & Lazarus forum](https://forum.lazarus.freepascal.org/index.php)
  - [Tweaking4All Delphi, Lazarus, Free Pascal forum](https://www.tweaking4all.com/forum/delphi-lazarus-free-pascal/)
  - [Laz Planet - Blogspot](https://lazplanet.blogspot.com/) / [Laz Planet - GitLab](https://lazplanet.gitlab.io/)
  - [Delphi Basics](https://www.delphibasics.co.uk/index.html)
- [rchastain2](https://github.com/rchastain2) for proposing
  `TVector2D.Rotate` and providing the original working example in
  [issue #18](https://github.com/ikelaiah/mathlib-fp/issues/18)
- Everyone who has helped make this project better

<sub>Originally extracted from <a href="https://github.com/ikelaiah/tidykit-fp">tidykit-fp</a>.</sub>
