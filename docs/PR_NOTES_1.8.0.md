# PR: Complete the audited numerical workflows for 1.8.0

## Summary

This change implements only the mathlib-fp 1.8.0 milestone and folds in the
missing completion-gate work found by auditing the already-tagged 1.7.0
milestone. Version 1.7.0 is not rewritten; the corrections ship additively in
1.8.0. No 1.9-or-later roadmap work is included.

The implementation is native Free Pascal and additive. It introduces no
third-party runtime, foreign binary, service, network dependency, unit-global
random state, parallel runtime, or SIMD ABI.

## Release readiness — 2026-07-30

Version 1.8.0 completed local qualification and the required Linux and Windows
GitHub Actions checks for release on 2026-07-30. Full command transcripts and
benchmark results are recorded in
[QUALIFICATION_1.8.0.md](QUALIFICATION_1.8.0.md).

| Check | Result |
| --- | --- |
| Win64 normal and `-O3` suites | 899 passed, 0 failed, 0 errors |
| Win64 checked-heap suite | 899 passed; 0 unfreed memory blocks |
| Win32 `-O2` suite | 899 passed, 0 failed, 0 errors |
| Examples | All 22 built and ran |
| Lazarus packages | Both packages built for Win64 and Win32 |
| Documentation | 50 pages, 22 examples, and 248 public symbols checked |
| Clean source archive | SHA-256 verified; 899 tests, 22 examples, and documentation checks passed after extraction |
| Benchmarks | Two Win64 `-O3` runs recorded against the 1.7 comparison |
| Remote CI | Linux and Windows pull-request and push workflows passed |

All required remote CI checks have passed and the PR is ready to merge. The
remaining operations are merge, tag, GitHub release, and archive publication.

## Design discipline

The reviewed [1.8 design record](design/applied-numerics-1.8.md) and exhaustive
[1.7/1.8 gap-closure record](design/release-1.8-gap-closure.md) fix:

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
- `MathBase.Expressions`
- `StatsLib.Streaming`
- `StatsLib.Inference`
- `EngineeringLib.DSP`
- `MLLib.Analysis`
- `TimeSeriesLib.StateSpace`
- `InterchangeLib.Models`

The existing `AlgebraLib.DenseKernels` unit adds deterministic serial blocked
and automatic multiply entry points for all four typed scalar families.

Primary public types include `TRandomState`, `TLocalRandom`,
`TOnlineStatistics`, `TNonFinitePolicy`, `TDSPKit`, `TFFTNormalization`,
`TOverlapAddConvolver`, `TOverlapSaveConvolver`, `TStreamingFIR`,
`TStreamingBiquad`, `TInferenceKit`, `TAnalysisKit`,
`TStandardizationModel`, `TDecisionForest`, `TKDTree`,
`TScalarKalmanFilter`, `TMultivariateKalmanFilter`, `TValueMetadata`,
`TExpressionEvaluator`, `TOptimizationOptions`, `TOptimizationWorkspace`, and
`TDenseMultiplyPath`.

## Completion-gate mapping

| Gate | Evidence in this change |
| --- | --- |
| Shared DSP/statistics/fitting/analysis containers | `examples/19_applied_data_pipeline.pas` passes the same `TDoubleArray` and typed dense matrix data across those domains |
| 1.7 modelling/optimisation audit | Spline boundary families, complex-step/vector AD, scaled/rank/covariance-aware fits, cubature/Monte Carlo, polynomial roots, component ODE tolerances, detailed solvers/workspaces, two-phase LP, and QP status/certificate tests |
| Bounded streaming/large-data state | Online statistics retain constant accumulators, overlap/FIR retain tap-bounded state, biquad retains two values, and Kalman filters retain only current state/covariance |
| Safe portable persistence/expressions | Numerical and selected-model round trips plus CRC/version/truncation/resource rejection; expression bindings are immutable and all parser/execution resources are capped |
| Reproducible data science | Local-RNG sampling, seeded forests/splits/clustering, fitted training-only standardization, OOB/importance and multivariate innovation diagnostics |
| Portable performance oracle | Exact portable/blocked/automatic tests for real and complex typed matrices; serial dispatch is deterministic |
| Published accuracy/performance comparison | `QUALIFICATION_1.8.0.md` records fixture budgets and compares the `-O3` benchmark with 1.7 |
| Workflow inventory and open items | `capabilities.json` and `CAPABILITIES.md` identify stable workflows, complexity/scale limits, tests/examples/benchmarks, and unsupported roadmap families |

## Reviewable implementation slices

1. Exhaustive 1.7/1.8 traceability and explicit conditional deferrals.
2. Missing modelling, differentiation, optimisation, and adversarial coverage.
3. Block/batch DSP, inference/regression, typed hierarchy/forests, and
   multivariate state space through existing dense kernels.
4. Optional numerical/model interchange and bounded expressions.
5. Portable-oracle blocked multiplication and small/batch/stream/large
   qualification benchmarks with allocation/state counters.
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

Conditional roadmap families remain excluded where their prerequisite
numerical validation was not available: equiripple and advanced IIR design,
broader wavelets/packets, survival/factor analysis, robust covariance,
multinomial/count GLMs, controlled/smoothed state space, implicit stiff or
mass-matrix ODEs, interior-point LP, general conic/quadratic certificates,
decomposition/general-graph persistence, and parallel/SIMD/vendor dispatch.
Sparse, integer, and every 1.9-or-later milestone remain out of scope.
