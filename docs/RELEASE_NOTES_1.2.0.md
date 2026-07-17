# mathlib-fp 1.2.0 release notes

**Release date:** 2027-07-18  
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

- General real eigendecomposition and residual-based convergence checks replace
  hard-coded matrix cases.
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

For the complete list of additions and fixes, see the
[changelog](../CHANGELOG.md#120---2027-07-18).

## Requirements and installation

- Free Pascal 3.2.2 or later.
- Lazarus 3.6 or later when using the optional Lazarus package.
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

- 747 automated tests pass with zero failures.
- All 12 example programs compile and run.
- The README quick-start builds and runs successfully.
- The `mathlib_fp` Lazarus package builds successfully.
- Clean normal and UTF-8 builds complete without compiler warnings.

## Support, security, and license

Bug reports and contributions are welcome through the GitHub repository. Do
not disclose vulnerability details in a public issue; follow the
[security policy](../SECURITY.md) to submit a private report.

mathlib-fp is distributed under the [MIT License](../LICENSE.md).
