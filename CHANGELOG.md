# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.9.2] - 2026-08-02

### Documentation

- Added a double-real beginner guide, task-oriented recipe index, and explicit
  beginner-to-advanced routes for every stable domain without changing the
  frozen 1.9 public API.
- Added searchable routes for dense and sparse solves, descriptive and
  streaming statistics, probability, interpolation and fitting,
  optimisation, FFT and filtering, time series, finance, geometry, and unit
  conversion.

### Validation

- Made each beginner recipe's code and claimed output part of the clean-
  archive documentation checks, and added release-only validation for the
  three independent clean-room walkthrough records required by the 1.9.2
  completion gate.

## [1.9.1] - 2026-08-02

### Fixed

- Replaced seeded bootstrap's private low-bit LCG/modulo sampling with the
  shared explicit-state generator's unbiased bounded-index path. Eight-element
  samples no longer collapse every resample to the same mean; a permanent
  regression covers varying resamples, non-degenerate confidence bounds,
  deterministic replay, and unchanged global random state.

### Documentation

- Added release-identified versioned static documentation, preservation of the
  tagged 1.9.0 site, and a deterministic offline HTML ZIP plus SHA-256 file.
- Made every output-producing runnable documentation program verify its
  claimed output, and added checked statuses/final markers for the release-
  facing dense, sparse, and migration examples.
- Added a focused feedback route for installation time, type choice,
  conversions, unexpected errors/statuses, selection guidance, and migration.

### Validation

- Added clean-archive qualification automation for normal, optimised,
  checked/heap-traced, examples, documentation, Lazarus package, quick-start,
  and benchmark gates, while preserving the exact 1.9 public API snapshot.
- Recorded the release evidence and unchanged limitations in
  `docs/QUALIFICATION_1.9.1.md`.

## [1.9.0] - 2026-08-01

### Added

- Immutable validated CSR/CSC and diagonal/tridiagonal/band storage for
  single/double real and complex values, deterministic triplet construction,
  sparse arithmetic/products, and explicit dense conversions.
- Typed retained/delegated linear operators and identity, diagonal, IC(0), and
  ILU(0) preconditioners with documented ownership and reentrancy.
- CG, MINRES, restarted GMRES, BiCGSTAB, and LSQR with shared options,
  true-residual diagnostics, cancellation/progress, breakdown reasons, and
  reusable scalar-specific workspaces.
- Reusable pivoted tridiagonal/no-pivot band factors and an explicit
  natural-order sparse LU baseline with multiple RHS and fill diagnostics.
- Deterministic restarted largest-magnitude Lanczos and Arnoldi with
  independently checked residuals.
- Matrix Market coordinate double-real/double-complex sparse exchange and
  versioned checksummed four-scalar sparse binary interchange.
- End-to-end sparse and candidate-2.0 migration examples, a classified
  machine-readable public-API snapshot, declaration/default documentation
  checks, capability records, and large no-densification benchmarks.

### Validation

- Added dense-oracle, canonical/malformed interchange, status/breakdown,
  factor/preconditioner/workspace reuse, in-place alias, concurrent immutable
  reuse, and 20,000-dimensional no-densification fixtures.
- Corrected matrix-free shape validation to bound vector axes independently,
  preserving large linear-storage workloads on Win32 without weakening
  invalid-dimension or address-space checks.
- Recorded 100,000-nonzero sparse and 200,000-dimensional matrix-free `-O3`
  qualification cases with nonzero/allocation/storage/product/iteration/
  residual/timing evidence.
- The complete platform, package, example, documentation, and archive matrix is
  recorded in `docs/QUALIFICATION_1.9.0.md`.

### Compatibility

- Existing public signatures, defaults, and `TMatrixKitSparse` behavior remain
  available. Legacy-to-typed sparse conversion is explicit.
- The 2.0 contract and migration example are preview evidence only. No 2.0
  removal, default change, or later-roadmap implementation is included.

## [1.8.0] - 2026-07-30

### Added

- Explicit local xoshiro256** random state and constant-memory mergeable
  online statistics, with replay, split-stream, and bounded-state tests.
- Arbitrary-length/single/batched/2-D FFTs, direct/FFT/overlap convolution,
  correlation, rational resampling, spectra, analytic signals, Haar transform,
  and bounded block/FIR/biquad processing.
- Paired distribution APIs, parameter estimates, common inference/effect/
  correction results, SVD OLS diagnostics, and separation-aware binary
  logistic regression.
- Typed-dense PCA, seeded k-means++, hierarchy, fitted standardization,
  deterministic splits, binary LDA, seeded classification/regression forests,
  an exact low-dimensional KD tree, and scalar/multivariate Kalman filtering.
- Invariant text, delimited text, a dense Matrix Market subset, and
  versioned checksummed little-endian numerical and random-state persistence.
- Versioned selected-model adapters, typed metadata/complex summaries, and a
  resource-bounded scalar/vector/matrix expression evaluator.
- Audited 1.7 gap closure: classical spline boundaries, explicit complex-step
  and vector AD, cubature/local-RNG Monte Carlo, scaled/covariance-aware
  fitting, complex polynomial roots, component ODE tolerances, detailed
  optimization/workspaces, two-phase simplex, and QP outcome certificates.
- Deterministic serial blocked and automatic typed dense multiplication using
  the portable kernels as cross-path correctness oracles.
- Cross-domain and interchange/replay examples, capability records, release
  notes, benchmark comparison, and qualification evidence.

### Fixed

- Made simultaneous complex polynomial-root initialization
  non-conjugate-symmetric, removing a platform-rounding-dependent Win32
  convergence failure.

### Validation

- Release-qualified on 2026-07-30 with 899 passing tests under Win64 normal,
  `-O3`, and checked-heap builds, plus 899 passing tests under Win32 `-O2`.
- Built and ran all 22 examples, built both Lazarus packages for Win64 and
  Win32, and passed documentation checks covering 50 pages, 22 examples, and
  248 public symbols.
- Rebuilt and verified the checksummed clean source archive, then reran its
  899-test suite, all 22 examples, and documentation checks.
- Passed the required Linux and Windows GitHub Actions pull-request and push
  workflows on the qualified release branch.

### Compatibility

- Existing 1.7 and earlier public signatures remain available. The 1.8 APIs
  are additive; the legacy `EngineeringLib.Signal` FFT remains unchanged.
- No parallel/SIMD ABI, advanced filter-design/broader-wavelet surface,
  survival/factor/robust-covariance family, implicit stiff ODE, or general
  model/decomposition persistence is claimed stable.

## [1.7.0] - 2026-07-30

### Added

- Reusable barycentric, rational, PCHIP, Akima, bilinear/bicubic, IDW, RBF,
  and thin-plate interpolation with explicit ownership and scale limitations.
- Scale-aware finite gradients/Jacobians/Hessians, forward dual-number
  automatic differentiation, and pre-solve derivative checking.
- Adaptive Gauss-Kronrod finite/improper integration, deterministic
  quasi-Monte-Carlo integration, typed-QR linear fitting, damped robust
  nonlinear least squares, vector Newton equations, and adaptive
  Dormand-Prince ODEs with dense output and event detection.
- A shared `TIterationStatus` diagnostic vocabulary and dense convex QP/SOCP
  workflows with objective, feasibility, optimality, iteration, and evaluation
  results.
- End-to-end modelling and convex-optimisation examples, selection guides,
  tests, capability records, release notes, and qualification evidence.

### Changed

- `PenaltyMethod` and `Maximize` no longer serialize through unit-global
  callback bridges; their callback paths are reentrant.
- The Lazarus package and distribution metadata now identify version 1.7.0 and
  include every new unit.

### Compatibility

- Existing 1.6 and earlier public signatures remain available. The 1.7 APIs
  are additive.

## [1.6.0] - 2026-07-27

### Added

- Added reusable single/double real/complex Householder QR and
  column-pivoted QR factors, full-rank and rank-revealing least-squares solves,
  copied compact factors/permutations, numerical-rank decisions, and
  inspectable residual/backward-error diagnostics.
- Added reusable compact one-sided Jacobi SVD factors for tall, square, and
  wide matrices plus vector/multiple-RHS rank-deficient and underdetermined
  minimum-norm solves.
- Added full ascending symmetric real and Hermitian complex eigensystems with
  normalized eigenvectors, deterministic cyclic-Jacobi convergence outcomes,
  and single/double scalar parity.
- Added lower/upper, unit/non-unit triangular solves for ordinary, transposed,
  and conjugate-transposed systems.
- Extended LU and Cholesky factors additively with `ConditionIndicator` and
  `SolveWithInfo`, and added diagnostic square and positive-definite
  convenience entry points without changing the 1.5 solve contract.
- Added the 1.6 design record, solver-selection and migration guides, realistic
  calibration/minimum-norm/eigen example, capability metadata, focused
  public/numerical tests, deterministic factor-reuse benchmarks, release
  notes, and qualification report.

### Compatibility

- Preserved every `IMatrix`, `TMatrixKit`, `IVector`, and typed 1.5 entry
  point. No API was removed or deprecated, and compatibility decompositions
  are not silently rerouted where their contracts differ.

## [1.5.0] - 2026-07-26

### Added

- Added 32-byte-aligned contiguous row-major single/double real/complex dense
  matrices with checked native-size shapes, retained-owner mutable views,
  explicit clones, and explicit compatibility conversions.
- Added matching allocating and `Into` dense kernels for elementwise
  arithmetic, AXPY, scalar-function application, reductions,
  transpose/conjugation, compensated products, and dot products.
- Added allocation-free operator-friendly 2x2 real/complex value matrices,
  batch types, and explicit flat/nested, precision, real/complex, and
  compatibility conversions.
- Added pivoted-LU `Solve(A, B)`, reusable LU factors, and real/complex
  Cholesky factors for vector and multiple right-hand sides.
- Added `TSingleComplex`, the typed dense migration/design guides, capability
  inventory, support matrix, solve example, benchmark, and completion-gate
  tests.

### Compatibility

- Preserved `IMatrix`, `TMatrixKit`, `IVector`, and all existing unit entry
  points. No API was removed or deprecated.

## [1.4.0] - 2026-07-25

### Added

- Added componentwise `+`, binary and unary `-`, scalar `*` in both operand
  orders, and vector/scalar `/` operators for `GeometryLib.Geometry`
  `TVector2D` and `TVector3D`. The fixed-size value records retain IEEE-754
  `Double` results for signed zero, NaN, infinity, overflow, and zero-scalar
  division without mutating either operand.
- Added focused GeometryLib operator, edge-case, algebraic-property, and
  public-API smoke coverage, plus a runnable Theodorus-spiral demonstration in
  the geometry example.

### Fixed

- Made `TVector2D` and `TVector3D` magnitude and normalization scale-safe for
  finite tiny and large components. Normalization now accepts every finite
  non-zero vector and rejects exact-zero or non-finite vectors explicitly.

## [1.3.0] - 2026-07-23

### Added

- Added the 1.3.0 complex and vector foundation with `MathBase.Complex`:
  the double-precision `TComplex` record, stable arithmetic and magnitude,
  principal elementary functions, and `TComplexArray`.
- Added `AlgebraLib.VectorKernels` and its `TVectorKit` facade for finite,
  contiguous real and complex array-vector arithmetic, including scale-safe
  norms and conjugating complex dot products. `AlgebraLib.Vectors` continues
  to preserve the existing matrix-as-vector aliases while re-exporting the new
  array-vector API.
- Added `TComplexArray` FFT/IFFT overloads that preserve the existing
  split-real/imaginary signal API, documentation, a runnable complex-vector
  example, and focused tests.
- Hardened complex division and principal branch behavior, added inverse
  complex trigonometric and hyperbolic functions, and made `TComplexArray` the
  native FFT representation.
- Expanded vector kernels with stable reductions, elementwise arithmetic, and
  allocation-avoiding `...Into` destination-buffer procedures.
- Added representative complex, vector, and FFT benchmarks plus public API
  smoke coverage.

### Fixed

- Preserved tiny `CAsinh`/`CAtanh` inputs and replaced target-sensitive
  `z*z` cancellation with scaled component formulas for large inverse complex
  functions.
- Defined infinity/NaN behavior for complex magnitude, exponential, and square
  root calculations, and retained signed-zero branch sides for inverse
  hyperbolic functions.
- Updated CI to compile and execute the standalone `.pas` examples after their
  rename from `.lpr`.

## [1.2.3] - 2026-07-21

### Changed

- Reworked `MathBase.Precision` around a higher-accuracy Lanczos log-gamma,
  cancellation-resistant beta evaluation, convergence-checked incomplete-beta
  fractions, and direct incomplete-gamma normal tails.
- Normal, lognormal, beta, Student-t, and F survival functions now evaluate
  upper tails directly instead of subtracting a rounded CDF; F-distribution
  arguments avoid overflowing `d1*x`. Normal-tail approximations in statistics
  use the same direct-tail path.
- Hyperbolic and inverse-hyperbolic helpers preserve tiny arguments and avoid
  unstable exponential/logarithmic cancellation. Two-dimensional vector
  magnitude now uses the scaled hypotenuse kernel.

### Fixed

- Corrected `MathBase.Precision.StudentT` to use the required `df/2`
  incomplete-beta shape parameter instead of `(df+1)/2`, fixing t-test
  p-values built on the shared helper.
- Invalid low-level special-function shape parameters now return NaN
  predictably, and iterative special functions no longer return an
  unconverged partial result.
- Rebased the K-S normality reference on the full-precision normal CDF instead
  of the previous low-accuracy error-function approximation, and made its
  empirical CDF fractions explicitly double precision across FPC targets.

### Tests

- Added special-function reference, symmetry, invalid-input, small-argument,
  large-vector, and representable extreme-tail regressions, bringing the suite
  to 798 tests. Cross-platform cases now pin complement inputs and empirical
  fractions to `Double` before comparing extreme-tail and K-S references.

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
