# Applied numerics, interchange, and performance design record (1.8)

## Release boundary and compatibility

Version 1.8 adds a small, coherent applied-numerics layer beside the existing
1.7 APIs. Existing public signatures and storage contracts remain
source-compatible. The new units are separated by responsibility:

- `MathBase.Random` owns explicit, reproducible local random-generator state;
- `StatsLib.Streaming` owns bounded-memory online and mergeable statistics;
- `EngineeringLib.DSP` owns arbitrary-length and two-dimensional transforms,
  convolution, streaming FIR state, resampling, and spectral workflows;
- `MLLib.Analysis` owns typed-dense PCA, k-means++, deterministic validation
  splits, and low-dimensional exact nearest-neighbour search;
- `TimeSeriesLib.StateSpace` owns a documented scalar linear Kalman baseline;
- `MathBase.Interchange` owns invariant text, delimited text, Matrix Market,
  and a versioned endian-defined binary persistence format; and
- `AlgebraLib.DenseKernels` retains the portable compensated matrix kernel as
  the numerical oracle and adds an explicitly selectable blocked path.

These units use `TDoubleArray`, `TSingleArray`, `TComplexArray`,
`TSingleComplexArray`, and typed dense matrices directly. They do not introduce
a second public signal, vector, or matrix container. Legacy nested ML matrices
remain supported by `MLLib.MachineLearning`; migration is additive.

The stable 1.8 boundary deliberately does not claim equiripple FIR design,
Chebyshev/elliptic/Bessel IIR design, wavelets, decision forests, generalized
linear models, survival/factor analysis, multivariate state-space models,
model/decomposition persistence, a general expression language, parallel
execution, or SIMD dispatch. Those items remain visible in the capability
inventory. No 2.0 API removal, unification, or deprecation is part of this
release.

## Ownership, aliasing, mutation, and lifetime

Dynamic arrays and dense-matrix handles passed to functions are borrowed only
for the call and are not retained unless a constructor explicitly documents a
snapshot. Allocating functions return independent arrays or matrix storage.
`...Into` operations validate dimensions, limits, and values before the first
destination write and use temporary storage when source and destination may
overlap.

`TStreamingFIR`, `TOnlineStatistics`, `TLocalRandom`, `TKDTree`, and
`TScalarKalmanFilter` own their state. Constructors copy coefficient, point, or
configuration data. Assignment of records containing dynamic arrays follows
Free Pascal managed-array sharing; mutating methods detach their private array
state before writing so a copied state value evolves independently.

No public object retains a borrowed stream. Interchange functions read or
write synchronously. Loading returns a new value; it never modifies an existing
destination. A failed load therefore cannot leave caller-owned numerical data
partially updated.

## Indexing, shapes, and scalar behavior

All vectors, signal samples, matrix rows/columns, labels, and neighbour indices
are zero-based. Typed dense matrices remain row-major and retain the 1.5
view/ownership contract.

One-dimensional transforms preserve input length. The forward transform uses
the negative exponential sign and the inverse uses the positive sign.
`fnBackward` (the default) scales only the inverse by `1/N`; `fnForward` scales
only the forward; `fnUnitary` scales both directions by `1/sqrt(N)`; and
`fnNone` scales neither. Empty transforms return empty results. Two-dimensional
transforms apply the same convention once over the complete transform, not
once per axis.

Power-of-two transforms use the portable radix-2 kernel. Other lengths use a
portable Bluestein transform with checked work-size arithmetic. The direct DFT
is public only as a small reference oracle used by cross-path tests. Single
precision keeps single-precision public input/output storage while twiddle
generation and accumulation use `Double`.

Linear convolution has length `Length(A) + Length(B) - 1`; correlation uses
`sum A[i+k] * conjugate(B[i])` and reports lags from
`-(Length(B)-1)` through `Length(A)-1`. Automatic convolution dispatch uses a
documented deterministic operation-count threshold. It never depends on the
host CPU or timing.

Rows are observations and columns are features in `MLLib.Analysis`. PCA returns
components as rows. K-means labels are in `0..K-1`. Exact nearest-neighbour
ties are ordered by increasing squared distance and then original row index.

## Errors, limits, and non-finite data

Programmer errors use the relevant unit exception and identify the operation,
parameter/shape, and expected condition. Stable numerical algorithms reject
NaN and Infinity before computing. Streaming statistics have an explicit
`nfpReject` or `nfpIgnore` policy; ignored samples do not change count, weight,
or moments.

Dimensions and byte counts use `SizeInt`, `SizeUInt`, or `QWord` with explicit
overflow checks before allocation. Binary and text loaders accept a caller
supplied maximum element count; the default is conservative. Declared sizes,
format versions, scalar kinds, payload lengths, and checksums are validated
before a result is returned. Truncated, corrupt, incompatible, or oversized
input raises `EInterchangeError`.

Delimited text is RFC-4180-style numeric data with one invariant floating-point
number per field. Locale-aware display is separate. Matrix Market support is
the real/complex dense `array` subset; unsupported coordinate/sparse variants
are rejected rather than guessed.

## Streaming and bounded-memory behavior

`TOnlineStatistics` stores a fixed number of scalar accumulators independent of
sample count and merges using the parallel central-moment formula.
`TStreamingFIR` stores exactly `Length(Coefficients)-1` prior input samples and
returns one output sample per input sample. Processing an empty block changes
nothing. `Reset` restores the documented zero initial state.

Welch estimation and short-time transforms allocate one output frame matrix
plus one window-sized work buffer. They do not retain the input. The scalar
Kalman filter stores only the current estimate/covariance and configuration.
The k-d tree stores a snapshot proportional to the training matrix and query
workspace proportional to requested neighbours plus tree depth.

## Randomness and reproducibility

`TLocalRandom` is a native-Pascal xoshiro256** generator seeded through
SplitMix64. Its four-word state is explicit, serializable, and never aliases or
mutates the RTL global random generator. `Split` deterministically advances the
parent and creates a non-overlapping practical child stream; it is not a proof
of cryptographic separation. The generator is for simulation and sampling, not
cryptography.

Seeded k-means++ and validation splits own a local generator. Equal inputs,
seed, scalar precision, and platform contract produce the same sequence and
labels. Algorithms do not use wall-clock time or global `RandSeed`.

## Portable performance path

The existing compensated `MultiplyInto` implementation remains the correctness
oracle. `MultiplyBlockedInto` is an opt-in cache-blocked scalar implementation
with a caller-controlled positive block size and deterministic traversal.
`MultiplyAutoInto` chooses the blocked path only from matrix dimensions and a
published fixed threshold. The blocked result must meet the documented
cross-path tolerance; dispatch never weakens validation or alias behavior.

No parallel or SIMD path is labelled stable in 1.8. This keeps every supported
platform on the same native Pascal implementation while establishing the
reference/fast-path testing and benchmark structure required before later
compile-time CPU kernels are considered.

## Thread safety and compatibility

There is no unit-global RNG, stream, callback, workspace, dispatch setting, or
mutable cache. Independent instances and pure allocating functions are
reentrant. A single mutable state value is not safe for concurrent mutation;
callers must give each thread its own RNG, filter, online statistic, k-d tree
query, or Kalman state (or synchronize access).

All additions are optional units. Numerical core units do not acquire file,
network, GUI, service, foreign-binary, or package-manager dependencies.

## Provenance

- Cooley and Tukey, *An Algorithm for the Machine Calculation of Complex
  Fourier Series*, Mathematics of Computation 19, 1965.
- Bluestein, *A Linear Filtering Approach to the Computation of Discrete
  Fourier Transform*, IEEE Transactions on Audio and Electroacoustics 18,
  1970.
- Welch, *The Use of Fast Fourier Transform for the Estimation of Power
  Spectra*, IEEE Transactions on Audio and Electroacoustics 15, 1967.
- Welford, *Note on a Method for Calculating Corrected Sums of Squares and
  Products*, Technometrics 4, 1962.
- Pébay, *Formulas for Robust, One-Pass Parallel Computation of Covariances and
  Arbitrary-Order Statistical Moments*, Sandia report SAND2008-6212, 2008.
- Blackman and Vigna, *Scrambled Linear Pseudorandom Number Generators*, ACM
  Transactions on Mathematical Software 47, 2021.
- Lloyd, *Least Squares Quantization in PCM*, IEEE Transactions on Information
  Theory 28, 1982; Arthur and Vassilvitskii, *k-means++*, SODA 2007.
- Bentley, *Multidimensional Binary Search Trees Used for Associative
  Searching*, Communications of the ACM 18, 1975.
- Kalman, *A New Approach to Linear Filtering and Prediction Problems*,
  Journal of Basic Engineering 82, 1960.

All released implementations are native Object Pascal source in this
repository.
