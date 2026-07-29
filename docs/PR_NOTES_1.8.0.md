# PR: Add the bounded applied-numerics surface for 1.8.0

## Summary

This change implements only the mathlib-fp 1.8.0 applied-numerics, tooling, and
portable-performance milestone. It adds a cohesive stable subset that meets
the milestone completion gate without treating every aspirational bullet as a
finished production API.

The implementation is native Free Pascal and additive. It introduces no
third-party runtime, foreign binary, service, network dependency, unit-global
random state, parallel runtime, or SIMD ABI.

## Design discipline

The reviewed [1.8 design record](design/applied-numerics-1.8.md) was written
before the new public storage and state types. It fixes:

- unit ownership and dependency direction;
- borrowed inputs, owned outputs, record/class snapshots, and stream
  ownership;
- zero-based indexing and rows-as-observations data-analysis shapes;
- FFT normalization, frequency, padding, state, and deterministic dispatch
  conventions;
- validation, failure atomicity, resource caps, platform byte order, and
  thread-safety;
- additive compatibility with every 1.7 public entry point; and
- the explicit boundary between stable 1.8 work and still-open roadmap items.

The implementation reuses typed SVD/solve kernels for PCA/LDA, shared arrays
and complex records for DSP, and the portable dense multiply as the blocked
path oracle.

## Public API

New units:

- `MathBase.Random`
- `MathBase.Interchange`
- `StatsLib.Streaming`
- `EngineeringLib.DSP`
- `MLLib.Analysis`
- `TimeSeriesLib.StateSpace`

The existing `AlgebraLib.DenseKernels` unit adds deterministic serial blocked
and automatic multiply entry points for all four typed scalar families.

Primary public types include `TRandomState`, `TLocalRandom`,
`TOnlineStatistics`, `TNonFinitePolicy`, `TDSPKit`, `TFFTNormalization`,
`TStreamingFIR`, `TStreamingBiquad`, `TSpectralEstimate`, `TAnalysisKit`,
`TPCAResult`, `TKMeansPlusPlusResult`, `TKDTree`,
`TScalarKalmanConfiguration`, `TScalarKalmanFilter`, and
`TDenseMultiplyPath`.

## Completion-gate mapping

| Gate | Evidence in this change |
| --- | --- |
| Shared DSP/statistics/fitting/analysis containers | `examples/19_applied_data_pipeline.pas` passes the same `TDoubleArray` and typed dense matrix data across those domains |
| Bounded streaming/large-data state | Online statistics retain constant accumulators, FIR retains taps minus one, biquad retains two values, and scalar Kalman retains estimate/covariance |
| Safe portable persistence | Round-trip text/open/binary tests plus corrupt CRC, incompatible version, truncated payload, and oversized-declaration rejection |
| Portable performance oracle | Exact portable/blocked/automatic tests for real and complex typed matrices; serial dispatch is deterministic |
| Published accuracy/performance comparison | `QUALIFICATION_1.8.0.md` records fixture budgets and compares the `-O3` benchmark with 1.7 |
| Workflow inventory and open items | `capabilities.json` and `CAPABILITIES.md` identify stable workflows, complexity/scale limits, tests/examples/benchmarks, and unsupported roadmap families |

## Reviewable implementation slices

1. Explicit RNG state and mergeable streaming statistics.
2. Shared-container DSP and bounded filter records.
3. Typed analysis and scalar state space through existing dense kernels.
4. Optional interchange with checked, endian-defined persistence.
5. Portable-oracle blocked multiplication and qualification benchmarks.
6. Package, public-API, examples, documentation, inventory, CI metadata, and
   release evidence.

## Compatibility and risk

- No public identifier was removed or renamed.
- New random workflows do not affect legacy APIs that intentionally retain
  their existing seeded behavior.
- The new DSP API does not silently change the legacy signal FFT convention.
- Stateful value records are not internally synchronized; callers must not
  mutate one instance concurrently.
- Text and binary loaders allocate only after validating declared dimensions
  against overflow and caller limits. Returned values are independent.
- Exact blocked/portable agreement relies on preserving increasing inner-index
  accumulation. A future parallel or SIMD path must retain the portable oracle
  and add precision-specific cross-path tolerances before becoming stable.

## Explicitly excluded

No advanced filter-design/wavelet family, broad distribution/inference/GLM
layer, survival/factor analysis, decision forest, hierarchical clustering,
multivariate state-space API, model/decomposition persistence, expression
language, parallel runtime, SIMD dispatch, sparse milestone, or later-release
work is implemented.

Merging, tagging, creating the GitHub release, and publishing archives remain
separate release-management steps.
