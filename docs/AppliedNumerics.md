# Applied numerics and data workflows

Version 1.8 adds applied DSP, streaming statistics, typed data analysis, local
random state, and a scalar state-space baseline without introducing new vector
or matrix containers. The reviewed ownership and numerical decisions are in
the [1.8 design record](design/applied-numerics-1.8.md).

Maturity: **stable for the APIs documented on this page**. The capability
inventory lists the broader roadmap families that remain unsupported.

## 60-second workflow

```pascal
uses
  MathBase.SharedTypes, EngineeringLib.DSP, StatsLib.Streaming;

var
  Signal: TDoubleArray;
  Spectrum: TSpectralEstimate;
  Summary: TOnlineStatistics;
  I: Integer;
begin
  Signal := TDoubleArray.Create(0, 1, 0, -1, 0, 1, 0, -1);
  Spectrum := TDSPKit.Welch(Signal, 4, 2, 8);
  Summary := TOnlineStatistics.Create;
  for I := 0 to High(Spectrum.Power) do
    Summary.Add(Spectrum.Power[I]);
  Writeln('mean spectral power = ', Summary.Mean:0:6);
end.
```

The complete [applied pipeline example](../examples/19_applied_data_pipeline.pas)
joins DSP, streaming statistics, polynomial fitting, typed PCA/k-means++, and
Kalman filtering without private array conversions.

## Choose a transform or convolution

| Task | API | Selection guidance |
| --- | --- | --- |
| General complex DFT | `TDSPKit.Transform` | Radix-2 for power-of-two lengths; portable Bluestein otherwise |
| Real input spectrum | `TDSPKit.RealTransform` | Returns the same shared complex array used by other complex kernels |
| Image/grid transform | `TDSPKit.Transform2D` | Uses `IDenseComplexMatrix`; rows then columns |
| Small convolution | `TDSPKit.Convolve(..., cmDirect)` | Lowest setup cost; exact documented output length |
| Larger convolution | `TDSPKit.Convolve(..., cmFFT)` | Lower asymptotic cost; small rounding differences are expected |
| Default convolution | `cmAutomatic` | Fixed `Length(A)*Length(B)` threshold, independent of timing and CPU |
| Repeated causal FIR blocks | `TStreamingFIR` | State is exactly `tap count - 1` prior samples |

Forward transforms use `exp(-2*pi*i*k*n/N)`. `fnBackward`, the default, leaves
the forward transform unscaled and divides the inverse by `N`. `fnForward`
does the reverse, `fnUnitary` applies `1/sqrt(N)` in both directions, and
`fnNone` does not scale either direction. `DFTReference` is the small
correctness oracle, not the throughput path.

`Convolve` returns `Length(A)+Length(B)-1` samples. `Correlate` reports lags
from `-(Length(B)-1)` to `Length(A)-1`. Empty convolution input produces an
empty result. Inputs must be finite.

## Spectral analysis and filters

- `Periodogram` produces a one-sided PSD with frequencies in caller-supplied
  sample-rate units.
- `Welch` averages overlapping, windowed segment periodograms.
- `ShortTimeFourierTransform` returns a typed dense complex matrix whose rows
  are frames and columns are complete transform bins.
- `CrossSpectrum` returns complex cross power and magnitude-squared coherence.
- `AnalyticSignal` uses the standard doubled-positive-frequency convention.
- `GetWindowMetrics` reports coherent gain, equivalent noise bandwidth in bins,
  and RMS gain.
- `ResampleLinear` and `ResampleRational` provide deterministic interpolation
  helpers. They are not anti-alias filters; low-pass first when downsampling
  content above the new Nyquist frequency.
- `DesignButterworthLowPass` creates a second-order normalized low-pass
  biquad. `TStreamingBiquad` uses transposed direct form II and zero initial
  state.

Normalized cutoff is cycles/sample in `(0, 0.5)`. FIR and biquad processing
assume zero state after construction or `Reset`. A complete invalid block is
rejected before state advances, including arithmetic overflow; spectral
estimators reject a zero-energy window. Independent state records are
reentrant; concurrent mutation of the same state is not safe.

## Online and mergeable statistics

`TOnlineStatistics` uses weighted Welford/Pébay updates. Storage is O(1)
regardless of sample count.

```pascal
var
  Left, Right: TOnlineStatistics;
begin
  Left := TOnlineStatistics.Create(nfpReject);
  Right := TOnlineStatistics.Create(nfpReject);
  Left.AddWeighted(10, 2);
  Right.Add(20);
  Left.Merge(Right);
end;
```

`nfpReject` raises `EStreamingStatsError` on NaN or Infinity. `nfpIgnore`
leaves count, weight, mean, and moments unchanged. Weights must always be
finite and positive. `PopulationVariance` divides by total weight.
`SampleVariance` uses the reliability-weight denominator
`sum(w)-sum(w^2)/sum(w)` and requires effective sample size above one.

## Reproducible local random state

`TLocalRandom.Seeded` creates a xoshiro256** generator with four explicit
64-bit state words. `NextUInt64`, `NextUInt32`, `NextDouble`, `NextSingle`,
`NextInteger`, and `NextNormal` never use the RTL `RandSeed`. `Split` returns
the current stream as a child and jumps the parent by `2^128` states.

`GetState` and `SetState` support exact replay. The all-zero state is invalid.
This generator is suitable for simulation and deterministic sampling, not
cryptography. Give each thread its own state.

## Typed data analysis

`MLLib.Analysis` uses `IDenseDoubleMatrix` directly, with observations in rows
and features in columns:

- `TAnalysisKit.PCA` centers data and delegates to the shared typed SVD.
  Components are rows, scores are observation rows, singular values descend,
  and explained ratios use total centered variance.
- `KMeansPlusPlus` uses seeded k-means++ initialization, deterministic
  tie-breaking, a finite iteration limit, and an inspectable `Converged`
  result.
- `CreateValidationSplit` and `KFoldAssignments` return reproducible row-index
  partitions. Preprocessing must be fitted on training rows only.
- `FitBinaryLDA` uses the shared dense solve for the within-class scatter
  system. The optional non-negative ridge handles singular or nearly singular
  scatter.
- `TKDTree` owns an immutable typed-matrix snapshot. `Query` returns exact
  neighbours ordered by squared distance and then original row index.

All feature values must be finite. PCA needs at least two rows and non-zero
centered variance. K-means++ targets in-memory dense data. The k-d tree is most
useful for exact low-dimensional queries; high dimensions weaken pruning.

## Scalar state-space baseline

`TScalarKalmanConfiguration` defines transition, observation, process
variance, and measurement variance for a scalar linear-Gaussian system.
`TScalarKalmanFilter` owns only the current estimate and covariance.

`Process` returns estimates, posterior variances, innovations, innovation
variances, and log likelihood. It validates the complete measurement block and
updates a private working copy, so validation or numerical failure does not
partially advance the caller state. `Forecast` does not mutate the filter.
Covariance uses the Joseph update.

The stable baseline is scalar and time-invariant. Multivariate, controlled,
missing-observation, smoothing, and parameter-estimation models remain open.

## Complexity, ownership, and errors

Allocating operations return independent arrays or typed matrices and do not
retain borrowed inputs. Stateful constructors snapshot coefficients or data.
Arrays are zero-indexed.

| Operation | Time | Additional working storage |
| --- | --- | --- |
| FFT | O(N log N) | O(N), or next power of two above `2N-1` for Bluestein |
| Direct / FFT convolution | O(NM) / O(L log L) | output / padded spectra |
| Streaming FIR | O(block*taps) | O(taps) state plus output |
| Online statistics update/merge | O(1) | O(1) |
| PCA | typed compact SVD cost | centered matrix, factors, scores |
| k-means++ | O(iterations*rows*features*clusters) | labels, centroids, distances |
| k-d query | average sublinear; O(rows) worst case | O(k + tree depth) |
| Scalar Kalman sample | O(1) | O(1) state |

`EDSPError`, `EStreamingStatsError`, `ERandomStateError`, `EAnalysisError`, and
`EStateSpaceError` identify invalid parameters or numerical failures. No API
on this page uses a service, foreign binary, network, GUI, or hidden global
state.

## Important open items

The 1.8 stable boundary does not claim overlap-add/save convolution,
equiripple filters, Chebyshev/elliptic/Bessel IIR design, wavelets, decision
forests, generalized linear models, survival/factor analysis, multivariate
state-space models, or parallel/SIMD execution. See the
[capability inventory](CAPABILITIES.md) rather than inferring support from the
roadmap.
