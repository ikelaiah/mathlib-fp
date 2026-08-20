# mathlib-fp 1.8.0

Released 2026-07-30.

Version 1.8.0 delivers a deliberately bounded applied-numerics layer on the
typed dense and modelling foundations from 1.5–1.7. This release also closes
the implementation/documentation gaps found by an exhaustive audit of the
published 1.7 and active 1.8 roadmap requirements. DSP, inference, fitting,
typed data analysis, and scalar/multivariate state-space examples reuse the same
`TDoubleArray`, `TComplexArray`, and typed dense matrices. The release also
adds reproducible local random state, portable numerical interchange, and a
deterministic serial blocked matrix path.

## User-visible additions

- `MathBase.Random`: `TLocalRandom` and explicit four-word `TRandomState`, with
  deterministic replay and split streams and no mutation of RTL `RandSeed`.
- `StatsLib.Streaming`: weighted, online, mergeable `TOnlineStatistics` with
  a documented `TNonFinitePolicy` and constant retained state.
- `EngineeringLib.DSP`: `TDSPKit`, `TFFTNormalization`, arbitrary-length and
  batched/2-D real/complex transforms, direct/FFT and overlap-add/save
  convolution, correlation, resampling, window metrics,
  periodogram/Welch/STFT, analytic/cross spectra, Haar transform, plus bounded
  block/FIR/biquad state.
- `StatsLib.Inference`: paired normal/exponential/binomial operations,
  parameter estimates, t/ANOVA/contingency/rank tests, multiplicity
  corrections, SVD OLS diagnostics, and separation-aware binary logistic
  regression.
- `MLLib.Analysis`: typed-dense PCA (`TPCAResult`), seeded k-means++
  (`TKMeansPlusPlusResult`), fitted standardization, deterministic
  validation/k-fold splits, binary LDA, hierarchical clustering, seeded
  classification/regression forests with OOB/importance diagnostics, and exact
  low-dimensional `TKDTree` queries.
- `TimeSeriesLib.StateSpace`: explicit scalar and dense multivariate
  linear-Gaussian Kalman configuration, block processing, likelihood,
  innovations, covariances, and forecasts.
- `MathBase.Interchange`: invariant scalar/vector/matrix text, delimited
  matrices, a dense Matrix Market subset, typed metadata/complex summaries,
  and a versioned,
  checksummed little-endian binary format for double/complex vectors,
  typed-dense matrices, and RNG state.
- `InterchangeLib.Models`: versioned, capped, checksummed cubic-spline,
  streaming-FIR, fitted-standardization, and scalar-Kalman adapters.
- `MathBase.Expressions`: bounded arithmetic over immutable scalar, vector,
  and dense-matrix bindings with no scripting or I/O primitives.
- `AlgebraLib.DenseKernels`: `TDenseMultiplyPath`,
  `MultiplyBlockedInto`, `MultiplyAutoInto`, and `SelectedMultiplyPath`.
- The 1.7 modelling/optimisation surface now includes natural/clamped/
  not-a-knot splines, explicit complex-step callbacks, vector forward AD and
  derivative checks, cubature/local-RNG Monte Carlo, scaled/covariance-aware
  fitting, all-complex polynomial roots, component ODE tolerances, detailed
  bounded/trust/constrained/multistart/Pareto solvers, warm-start workspaces,
  two-phase simplex, and QP failure/certificate diagnostics.

The [applied numerics guide](../../guides/domains/applied-numerics.md), [interchange
guide](../../guides/domains/interchange.md), and [portable-performance guide](../../guides/domains/portable-performance.md)
document selection, units, ownership, mutation, indexing, shapes, resource
bounds, error behavior, and compatibility.

## Compatibility

The release is additive. Existing 1.7 and earlier public signatures remain
available, and the established `EngineeringLib.Signal` FFT is unchanged.
Every new API uses zero-based arrays and row/column typed-matrix indexing.
Input arrays and streams are borrowed for a call; returned arrays and matrices
own their values. Stateful records copy their state on assignment.

Binary interchange and model adapters have explicit format versions and byte order. Callers can
set an element cap. Loaders verify magic, version, kind, shape, payload size,
complete input, finite numeric values, and CRC-32 before returning a value.

## Accuracy and performance evidence

The portable DFT and portable dense multiply are correctness oracles.
Arbitrary-length transforms agree with the direct DFT within `2e-12` on the
published double fixture, 2-D double round trips within `2e-11`, single
round trips within `2e-5`, and FFT/direct/block convolution within `1e-12`.
Portable, blocked, and automatic matrix multiplication agree exactly on the
tested deterministic traversal.

The [1.8 qualification report](qualification.md) publishes the complete
gate, bounded-state and corrupt-input evidence, and performance changes from
1.7.0. Timing statements are workload- and machine-specific, not universal
speed claims.

Release qualification completed on 2026-07-30 with 899 passing tests across
the documented Win64 and Win32 configurations, all 22 examples, both Lazarus
package targets, documentation and clean-archive checks, and the required
Linux and Windows GitHub Actions pull-request and push workflows.

## Known limitations and open roadmap work

- FIR/overlap state is bounded by tap count; biquad state has two delay values.
  Equiripple and Chebyshev/elliptic/Bessel design, broader wavelets/wavelet
  packets, and broader multirate workflows remain conditional and unqualified.
- Streaming statistics expose moments through variance. The inference layer
  is a portable double baseline; survival/factor analysis, robust covariance,
  multinomial/count GLMs, and certified exact tables remain open.
- Data analysis is dense, serial, and in-memory. Impurity importance has its
  documented bias and the small-data hierarchy baseline is cubic.
- State-space support is time-invariant and linear-Gaussian. Controls,
  missing-observation handling, smoothing, and parameter estimation remain
  open.
- Matrix Market support is the dense array real/complex general subset.
  Selected models have adapters; decompositions, forests, arbitrary model
  graphs, and multivariate state are not persisted.
- ODEs remain explicit/non-stiff with no mass-matrix path. Interior-point LP,
  general quadratic/conic certificates, sparse, and integer optimisation are
  not claimed.
- The optimized matrix path is serial and deterministic. No parallel,
  thread-pool, SIMD, ARM64, or vendor-library dispatch is claimed.

These gaps are marked unsupported in
[`capabilities.json`](../../capabilities.json); no later-roadmap API is included.
