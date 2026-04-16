# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- `CalculateFFTMagnitudePhase` — one-sided magnitude and phase spectra

##### FIR Filter Design (windowed-sinc)

- `DesignFIRLowPass(CutoffFreq, Order, WindowType)` — normalised cutoff in (0, 0.5)
- `DesignFIRHighPass(CutoffFreq, Order, WindowType)` — spectral inversion of low-pass
- `DesignFIRBandPass(LowCutoff, HighCutoff, Order, WindowType)` — difference of two low-pass filters
- `DesignFIRBandStop(LowCutoff, HighCutoff, Order, WindowType)` — notch/band-reject filter
- `ApplyFIRFilter(Signal, Coeffs)` — direct-form convolution; output length = N + M − 1

All FIR designs produce symmetric (linear-phase) coefficients normalised to unit DC gain (low-pass/band-stop) or unit Nyquist gain (high-pass).

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
