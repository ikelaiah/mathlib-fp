# mathlib-fp 1.2.0 release notes

**Release date:** 2026-07-18
**Release status:** First public release

mathlib-fp 1.2.0 is the first public release of the standalone mathlib-fp
project. It provides native Free Pascal libraries for scientific, statistical,
financial, engineering, numerical, optimization, time-series,
machine-learning, and geometry work without third-party runtime dependencies.

## What is included

The release contains 12 focused library areas:

| Library | Highlights |
| --- | --- |
| MathBase | Shared types, constants, precision helpers, and trigonometry |
| AlgebraLib | Dense matrices, decompositions, vectors, and linear solvers |
| FinanceLib | TVM, bonds, NPV/IRR, options, ratios, and risk metrics |
| StatsLib | Descriptive statistics, hypothesis tests, correlation, and bootstrap |
| EngineeringLib | Fluid dynamics, thermodynamics, signals, and unit conversion |
| NumericsLib | Root finding, integration, ODE solvers, and interpolation |
| ProbabilityLib | Continuous and discrete probability distributions |
| CombinatoricsLib | Counting, sequences, number theory, and permutations |
| OptimizationLib | Scalar, multivariate, constrained, and linear optimization |
| TimeSeriesLib | Smoothing, decomposition, ARIMA, and anomaly detection |
| MLLib | Preprocessing, regression, classification, clustering, and PCA |
| GeometryLib | 2-D and 3-D computational geometry |

See the [documentation index](index.md) for the API guides and the
[examples](../examples/) for runnable programs.

## Highlights

- Real symmetric eigendecomposition and supported real 2×2 nonsymmetric cases
  use residual-based convergence checks; unsupported nonsymmetric or complex
  spectra raise `EMatrixError`.
- Fractional matrix powers use symmetric eigendecomposition and require a
  symmetric positive-definite matrix; integer powers use exponentiation by
  squaring.
- Matrix multiplication uses a bounded worker count, propagates worker errors,
  and falls back safely when a Unix program has no thread manager installed.
- Seeded random and bootstrap overloads provide reproducible results without
  changing global random state.
- Machine-learning entry points consistently reject empty, ragged, non-finite,
  mismatched, and out-of-range inputs with `EMLError`.
- Financial APIs apply documented decimal rounding consistently, reject
  undefined ratios, and calculate positive or negative IRRs with bracketed
  bisection instead of returning a fixed initial guess.
- `FinanceLib.Bonds` and `FinanceLib.NPV` provide focused import paths with
  directly nameable bond schedule and NPV cash-flow aliases; their formulas
  remain centralized in `FinanceLib.Interest`.
- Engineering APIs have shared, domain-specific exception types through
  `EngineeringLib.Common`; the focused Velocity and Pressure units also expose
  directly nameable aliases for their calculation class and exception type.
- Signal processing includes complete-spectrum FFT/IFFT, symmetric windowed-
  sinc FIR designs for even or automatically adjusted odd orders, and the
  shared `MathBase` numeric-array type.
- Fluid and thermodynamic APIs validate solver, pressure, temperature, and
  specific-heat-ratio domains with deterministic Engineering exceptions.
- Pump head uses the Bernoulli relation with explicit inlet and outlet
  velocities, avoiding an ambiguous pre-public API.
- Unit conversion no longer silently treats unknown units as lengths: non-`Try`
  APIs raise `EUnitConversionError`, while `Try...` APIs return `False`. Its
  formatting, parsing, enumeration, base-unit, and shortcut APIs are fully
  documented, including exact symbols and fixed month/year durations.
- Matrix inverse, LU, rank, and exponential paths have scale-aware correctness
  fixes backed by reference, reconstruction, and algebraic property tests.
- Statistics sorting and convex-hull point ordering use O(n log n) algorithms;
  a representative benchmark runner covers both paths and dense multiplication.
- Statistical inference now returns exact small untied Mann-Whitney p-values,
  calibrated approximate K-S and Shapiro-Wilk p-values, and pooled-variance
  Cohen's d, with published/reference-value regression tests.
- Time-series frequency bins and ARIMA MA/integration forecasts have corrected
  mappings and reconstruction, including non-power-of-two and differenced
  polynomial reference cases.
- Linear regression uses centered Householder QR, while PCA reports iteration
  counts, enforces convergence, re-orthogonalises components, and handles
  rank-deficient covariance deterministically.
- Numerical root finders offer detailed convergence records; scalar root and
  optimization solvers raise on iteration exhaustion instead of silently
  returning an unconverged estimate. Linear programming reports a termination
  status in addition to its compatibility `Feasible` flag.
- Geometry, combinatorics, trigonometry, interpolation, distributions, and
  optimizer validation received focused correctness and domain regression tests.
- Win32-specific release validation corrected sieve index portability,
  significant-digit tie rounding, LU triangular cleanup, and deferred
  floating-point overflow reporting.

For the complete list of additions and fixes, see the
[changelog](../CHANGELOG.md#120---2026-07-18).

## Requirements and installation

- Free Pascal 3.2.2 or later.
- Lazarus 4.8 or later when using the optional Lazarus package.
- No third-party runtime dependencies.

Download a source archive from the GitHub release, or clone the repository.
Add `src/` to the compiler unit search path and keep compiler output in a
separate directory:

```bash
mkdir -p lib
fpc -Fusrc -FUlib my_program.lpr
```

Lazarus users can install
[`packages/lazarus/mathlib_fp.lpk`](../packages/lazarus/mathlib_fp.lpk), or add
`src/` under **Project Options → Compiler Options → Paths → Other Unit Files**.

## Compatibility and migration notes

- This is the first supported public release. Versions 1.1.x and older were
  pre-public development versions and are not supported.
- The Lazarus package and registration unit are named `mathlib_fp`. Remove any
  pre-release package installation from Lazarus before installing this release.
- The user-facing project and release name remains **mathlib-fp**; the
  underscore is used only where Pascal identifiers cannot contain a hyphen.
- On Unix, include `cthreads` before other units in applications that require
  threaded matrix multiplication. The library falls back to non-threaded
  execution when a thread manager is unavailable.

## Validation

The release candidate was validated with Free Pascal 3.2.2 on Linux and
Windows:

- 788 automated tests pass with zero failures on both Win64 and Win32.
- Normal, optimized, checked, and heap-traced test builds pass.
- All 12 example programs compile and run.
- The README quick-start builds and runs successfully.
- Windows CI builds the `mathlib_fp` package and runs all 788 tests with native
  Win64 and Win32 Lazarus 4.8 toolchains.
- The package and all 788 tests also pass in a manual Windows 11 installation
  of Lazarus 4.8 with its bundled Free Pascal compiler.
- The benchmark runner compiles and completes representative workloads.
- A clean source-archive installation repeats the tests, examples, quick-start,
  benchmark compilation, and Lazarus-package build.
- Clean normal and UTF-8 builds complete without compiler warnings.

## Support, security, and license

Bug reports and contributions are welcome through the GitHub repository. Do
not disclose vulnerability details in a public issue; follow the
[security policy](../SECURITY.md) to submit a private report.

mathlib-fp is distributed under the [MIT License](../LICENSE.md).
