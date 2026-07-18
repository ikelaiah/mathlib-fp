# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No changes yet.

## [1.2.2] - 2026-07-18

### Documentation

- Added newcomer-oriented MathBase and NumericsLib walkthroughs, giving every
  documented domain a runnable example, plus an indexed learning path for all
  14 examples.
- Reviewed all examples for concise purpose, input, interpretation, and method-
  selection guidance; corrected the statistics walkthrough to use a local,
  reproducible bootstrap seed and clarify p-value interpretation.
- Added 1.2.2 release notes and updated version and release references.

### Tooling

- Added shell and PowerShell entry points that compile every example into an
  ignored `example-bin/` directory, and made CI exercise both the scripts and
  the resulting programs on their native platforms.

## [1.2.1] - 2026-07-18

### Documentation

- Defined consistent terminology for the mathlib-fp project, domains, Pascal
  unit families, units, Kit classes, focused aliases, and the Lazarus package.
- Added a public API naming inventory and aligned guides, source headers, and
  contributor guidance with it without renaming existing public identifiers.

### Tests

- Added compile-time smoke coverage for every documented Kit class and focused
  alias, and registered the existing Engineering focused-alias tests in the
  main test runner, bringing the current suite to 789 tests.

## [1.2.0] - 2026-07-18

### Added

- `EngineeringLib.Common` with `EEngineeringError` and domain-specific
  exceptions for fluid dynamics, thermodynamics, signals, and unit conversion.
- Seeded `CreateRandom`, `BootstrapMean`, and
  `BootstrapConfidenceInterval` overloads that are reproducible without
  changing global random state.
- `PolynomialFeatures(..., IncludeBias)` overload so callers can omit the bias
  column when fitting models that already estimate an intercept.
- Edge, property, residual, deterministic-randomness, FinanceLib focused-unit,
  rounding, UTF-8, parallel-multiplication, and numerical reference coverage,
  bringing the suite to 788 tests.
- Representative performance benchmarks for statistics sorting, convex hulls,
  and dense matrix multiplication, with CI compilation coverage.
- Focused `EngineeringLib.Velocity` and `EngineeringLib.Pressure` entry units
  now expose directly nameable exception aliases and have direct compilation
  and runtime coverage.

### Changed

- Replaced hard-coded eigendecomposition and power-method cases with general
  real algorithms and residual-based convergence checks.
- Fractional matrix powers now use the symmetric eigendecomposition and require
  a symmetric positive-definite matrix; integer powers use exponentiation by
  squaring.
- Matrix multiplication uses an operation-count threshold, caps worker count,
  propagates worker failures, and falls back safely on Unix programs without a
  thread manager.
- ML entry points consistently reject empty, ragged, non-finite, mismatched,
  or out-of-range inputs with `EMLError`.
- Financial methods that expose `ADecimals` now apply it consistently. NPV
  rounds only its final result, and amortization schedules use the requested
  precision for payment amounts.
- Undefined financial ratios now raise `EFinanceError` when a required
  denominator is zero instead of returning a fabricated zero.
- `FinanceLib.Bonds` and `FinanceLib.NPV` remain lightweight focused entry
  units and now export directly nameable supporting aliases for their cash-flow
  and amortization types.
- Random-producing library functions no longer call `Randomize` internally.
- The test runner installs `cthreads` first on Unix and verbose algebra-test
  output is opt-in through `MATHLIB_TEST_VERBOSE`.
- The Lazarus package version is now 1.2.0 and includes the shared engineering
  exception unit.
- The Lazarus package and registration unit are now named `mathlib_fp` to match
  the mathlib-fp project name.
- Lazarus 4.8 is the minimum supported Lazarus version; CI validates the
  package against that baseline.
- `EngineeringLib.Signal.TDoubleArray` now aliases the shared
  `MathBase.SharedTypes.TDoubleArray` type.
- `TFluidDynamicsKit.PumpHead` now accepts explicit inlet and outlet velocities
  and implements the Bernoulli velocity-head term `(v2²-v1²)/(2g)`.
- General-purpose statistics and geometry sorts now use O(n log n) algorithms
  instead of quadratic insertion sorts.
- Root finders expose detailed convergence records, iterative matrix and scalar
  solvers report exhaustion explicitly, PCA records per-component iterations,
  and linear programming exposes a precise termination status.
- Linear regression now uses centered Householder QR instead of normal
  equations, improving behavior for high-offset and ill-scaled data.

### Fixed

- Fixed example 11's unsupported format specifier and duplicate polynomial
  intercept, which previously caused a singular regression system.
- Unknown unit names no longer silently default to length. Non-`Try` APIs raise
  `EUnitConversionError`; `Try...` APIs retain their `False` contract.
- Significant-digit formatting now uses stable round-half-to-even behavior on
  both Win32 extended-precision and Win64 targets.
- Fixed `InternalRateOfReturn`, which previously returned its initial 10% guess
  without iterating. It now brackets and bisects positive or negative rates and
  reports invalid or unbracketable cash-flow inputs with `EFinanceError`.
- Corrected FinanceLib signatures, result-type scope, numeric examples, and
  exception contracts in the API guide and source comments.
- Corrected odd-order high-pass and band-stop FIR centre indexing, added safe
  FFT/IFFT empty and mismatched-array handling, and documented the complete
  N-bin spectral outputs.
- Humidity-ratio and adiabatic calculations now reject invalid pressure and
  specific-heat-ratio domains with `EThermodynamicsError`.
- Engineering comments and API documentation now cover focused aliases,
  formula domains, signal shapes, every UnitConversion public API, exact unit
  names, fixed-duration time conventions, and locale-sensitive parsing.
- Removed all compiler warnings from clean normal and UTF-8 builds.
- Fixed broken source links, stale API names, version text, and random/bootstrap
  contracts across the documentation.
- Corrected matrix inverse permutation handling, LU row swaps, scale-relative
  rank/singularity decisions, exact triangular cleanup, and large-norm matrix
  exponentials, including architecture-independent overflow reporting.
- Corrected forward ray-circle semantics, polygon-boundary classification,
  non-negative radius validation, and zero-vector angle handling.
- Corrected exact small-sample Mann-Whitney p-values, K-S D/p-value semantics,
  Shapiro-Wilk normal scores, and pooled-variance Cohen's d.
- Corrected FFT period-bin mapping and ARIMA MA/integration forecasts.
- Added checked combinatorics overflow paths and overflow-safe modular
  exponentiation, a Win32-safe sieve index path, plus stable hyperbolic and
  hypotenuse calculations.
- Strengthened finite-value, dimension, domain, and callback validation across
  numerical, optimization, time-series, matrix, geometry, and ML entry points.

---

## [1.1.0] - 2026-04-16

### Added

#### NumericsLib — new library (`src/NumericsLib.Numerics.pas`, class `TNumericsKit`)

A complete numerical methods library with no external dependencies.

##### Root Finding

- `Bisection` — guaranteed bracketed convergence; raises `EInvalidArgument` when f(a)·f(b) ≥ 0
- `NewtonRaphson` — fast quadratic convergence using the function and its derivative
- `Brent` — hybrid method combining bisection, secant, and inverse-quadratic interpolation; the recommended general-purpose solver
- `Secant` — derivative-free quasi-Newton method requiring two initial guesses

##### Numerical Integration (Quadrature)

- `TrapezoidalRule` — composite trapezoidal rule; O(h²) accuracy
- `SimpsonRule` — composite Simpson's rule; O(h⁴) accuracy; auto-increments odd N to even
- `GaussLegendre5` — 5-point Gauss-Legendre quadrature; exact for polynomials up to degree 9

##### ODE Solvers (dy/dt = f(t, y))

- `EulerStep` / `EulerSolve` — 1st-order explicit Euler method
- `RK4Step` / `RK4Solve` — classic 4th-order Runge-Kutta; local error O(h⁵)
- Both solvers return a `TODESolution` record with aligned `T` and `Y` arrays

##### Interpolation

- `LinearInterp` — piecewise linear with binary-search interval lookup; clamps at endpoints
- `LagrangeInterp` — global Lagrange polynomial through all knots
- `CubicSplineBuild` / `CubicSplineEval` — natural cubic spline solved via the Thomas tridiagonal algorithm; exact at every knot

##### NumericsLib test coverage

39 new tests in `tests/TestNumericsLib.pas` verify analytically known results: `√2`, the Dottie number, `∫x³ dx = 0.25`, exponential ODE exact solution, harmonic oscillator, and spline exactness at knots.

#### EngineeringLib.Signal — FFT and FIR filter design (replacing stubs)

##### FFT (Cooley-Tukey radix-2 DIT)

- `FFT(var RealPart, ImagPart; Inverse)` — in-place FFT/IFFT; length must be a power of 2
- `CalculateFFT` — real input → complex spectrum; auto-pads to next power of 2
- `CalculateIFFT` — complex spectrum → real signal
- `CalculateFFTMagnitudePhase` — complete N-bin magnitude and phase spectra

##### FIR Filter Design (windowed-sinc)

- `DesignFIRLowPass(CutoffFreq, Order, WindowType)` — normalised cutoff in (0, 0.5)
- `DesignFIRHighPass(CutoffFreq, Order, WindowType)` — spectral inversion of low-pass
- `DesignFIRBandPass(LowCutoff, HighCutoff, Order, WindowType)` — difference of two low-pass filters
- `DesignFIRBandStop(LowCutoff, HighCutoff, Order, WindowType)` — notch/band-reject filter
- `ApplyFIRFilter(Signal, Coeffs)` — direct-form convolution; output length = N + M − 1

All FIR designs produce symmetric (linear-phase) coefficients. Low-pass is
normalised to unit DC gain; high-pass and band-stop use spectral inversion.

##### Signal test coverage

`tests/TestEngineeringLib_Signal.pas` expanded from 11 to 52 tests covering FFT linearity, Parseval's theorem, round-trip IFFT accuracy, DC/Nyquist correctness, FIR coefficient symmetry, and `ApplyFIRFilter` impulse response.

### Changed

- `EngineeringLib.Signal` — `CalculateFFT` and `CalculateFFTMagnitudePhase` were stubs that raised `Exception` unconditionally; both are now fully implemented.
- `tests/TestRunner.lpr` — `TestNumericsLib` registered alongside the existing test suites.

---

## [1.0.1] - 2026-04-16

### Fixed

- `AlgebraLib.Matrices` — `TMatrixKit.IsPositiveDefinite` previously used an insufficient check (determinant > 0 and positive diagonal elements). It now attempts a Cholesky factorisation; success is the definitive test for symmetric positive definite matrices.
- `AlgebraLib.Matrices` — `TMatrixKit.IsPositiveSemidefinite` had the same flaw. It now computes all eigenvalues via `EigenDecomposition` and checks that none are less than −1e-9.
- `AlgebraLib.Matrices` — `TMatrixKit.Cholesky` previously called `IsPositiveDefinite` as a pre-check, creating a circular dependency after the above fix. The guard is now an inline check: if the diagonal term under the square root is negative, `EMatrixError` is raised immediately.

### Performance

- `AlgebraLib.Matrices` — `TMatrixKit.Determinant` replaced recursive cofactor expansion (O(n!)) with LU-based calculation (O(n³)).
- `AlgebraLib.Matrices` — `BLOCK_SIZE` increased from 4 to 64 for better L1 cache utilisation.
- `AlgebraLib.Matrices` — `TMatrixKit.Multiply` now spawns parallel worker threads for matrices with 64 or more rows.

---

## [1.0.0] - 2026-04-14

### Changed

- The math modules (`TStatsKit`, `TFinanceKit`, `TMatrixKit`, `TTrigKit`, and supporting units) have been separated from [tidykit-fp](https://github.com/ikelaiah/tidykit-fp) into this standalone monorepo.
- Source reorganised into focused sub-libraries: `MathBase`, `AlgebraLib`, `FinanceLib`, `EngineeringLib`, and `StatsLib`, each with its own `README.md`.
- Unit namespaces updated to match the new library structure (e.g. `MathBase.SharedTypes`, `AlgebraLib.Matrices`, `StatsLib.Stats`).
- `EngineeringLib` expanded with `EngineeringLib.FluidDynamics`, `EngineeringLib.Thermodynamics`, `EngineeringLib.Signal`, and `EngineeringLib.UnitConversion`.
- `MathBase` expanded with `MathBase.Trigonometry`.

### Removed

- All non-math modules (Strings, FS, DateTime, JSON, Logger, Request, Crypto, Archive) are no longer part of this repository; they remain in tidykit-fp.

---

## [0.1.5] - 2025-04-21 (tidykit-fp era)

### Added

- Ubuntu 24.04.02 compatibility for DateTime and FS modules.
- Automatic test environment detection for the HTTP request module.
- HTTP fallback mechanism for testing HTTPS endpoints when OpenSSL is unavailable.
- Cross-platform SSL/TLS initialisation support for HTTP requests.

### Fixed

- File timestamp handling issues on Unix systems.
- Path normalisation for cross-platform compatibility.
- OpenSSL initialisation and error handling on Linux systems.

---

## [0.1.0] - 2025-03-13 (tidykit-fp era — initial release)

### Added

- `TStatsKit` — statistical calculations.
- `TFinanceKit` — financial mathematics.
- `TMatrixKit` — matrix operations with decompositions.
- `TTrigKit` — trigonometric functions.
- JSON operations, logging, cryptography (SHA3, SHA2, AES-256), archive, HTTP client.
