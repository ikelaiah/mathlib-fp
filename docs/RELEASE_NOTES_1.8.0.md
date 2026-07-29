# mathlib-fp 1.8.0

Released 2026-07-30.

Version 1.8.0 delivers a deliberately bounded applied-numerics layer on the
typed dense and modelling foundations from 1.5–1.7. DSP, streaming statistics,
fitting, typed data analysis, and scalar state-space examples reuse the same
`TDoubleArray`, `TComplexArray`, and typed dense matrices. The release also
adds reproducible local random state, portable numerical interchange, and a
deterministic serial blocked matrix path.

## User-visible additions

- `MathBase.Random`: `TLocalRandom` and explicit four-word `TRandomState`, with
  deterministic replay and split streams and no mutation of RTL `RandSeed`.
- `StatsLib.Streaming`: weighted, online, mergeable `TOnlineStatistics` with
  a documented `TNonFinitePolicy` and constant retained state.
- `EngineeringLib.DSP`: `TDSPKit`, `TFFTNormalization`, arbitrary-length and
  2-D real/complex transforms, convolution/correlation, resampling, window
  metrics, periodogram/Welch/STFT, analytic and cross spectra, plus bounded
  `TStreamingFIR` and `TStreamingBiquad` state.
- `MLLib.Analysis`: typed-dense PCA (`TPCAResult`), seeded k-means++
  (`TKMeansPlusPlusResult`), deterministic validation/k-fold splits, binary
  LDA, and exact low-dimensional `TKDTree` queries.
- `TimeSeriesLib.StateSpace`: explicit scalar linear-Gaussian Kalman
  configuration, block processing, and forecasts.
- `MathBase.Interchange`: invariant scalar/vector/matrix text, delimited
  matrices, a dense Matrix Market subset, concise summaries, and a versioned,
  checksummed little-endian binary format for double/complex vectors,
  typed-dense matrices, and RNG state.
- `AlgebraLib.DenseKernels`: `TDenseMultiplyPath`,
  `MultiplyBlockedInto`, `MultiplyAutoInto`, and `SelectedMultiplyPath`.

The [applied numerics guide](AppliedNumerics.md), [interchange
guide](Interchange.md), and [portable-performance guide](PortablePerformance.md)
document selection, units, ownership, mutation, indexing, shapes, resource
bounds, error behavior, and compatibility.

## Compatibility

The release is additive. Existing 1.7 and earlier public signatures remain
available, and the established `EngineeringLib.Signal` FFT is unchanged.
Every new API uses zero-based arrays and row/column typed-matrix indexing.
Input arrays and streams are borrowed for a call; returned arrays and matrices
own their values. Stateful records copy their state on assignment.

Binary interchange has an explicit format version and byte order. Callers can
set an element cap. Loaders verify magic, version, kind, shape, payload size,
complete input, finite numeric values, and CRC-32 before returning a value.

## Accuracy and performance evidence

The portable DFT and portable dense multiply are correctness oracles.
Arbitrary-length transforms agree with the direct DFT within `2e-12` on the
published double fixture, 2-D double round trips within `2e-11`, single
round trips within `2e-5`, and FFT/direct convolution within `1e-12`.
Portable, blocked, and automatic matrix multiplication agree exactly on the
tested deterministic traversal.

The [1.8 qualification report](QUALIFICATION_1.8.0.md) publishes the complete
gate, bounded-state and corrupt-input evidence, and performance changes from
1.7.0. Timing statements are workload- and machine-specific, not universal
speed claims.

## Known limitations and open roadmap work

- FIR state is bounded to `tap count - 1`; biquad state has two delay values.
  Overlap-add/save, advanced FIR/IIR design, wavelets, batched transforms, and
  broader multirate workflows are not stable in 1.8.
- Streaming statistics expose moments through variance. Broader
  distributions/sampling, inference, GLMs, survival, and multivariate methods
  remain open.
- Data analysis is dense in-memory double precision. Hierarchical clustering,
  decision forests, preprocessing pipelines, broader model selection, and
  multivariate state-space models remain open.
- Matrix Market support is the dense array real/complex general subset.
  Models, decompositions, spline/filter state, and expression evaluation are
  not persisted.
- The optimized matrix path is serial and deterministic. No parallel,
  thread-pool, SIMD, ARM64, or vendor-library dispatch is claimed.

These gaps are marked unsupported in
[`capabilities.json`](capabilities.json); no later-roadmap API is included.
