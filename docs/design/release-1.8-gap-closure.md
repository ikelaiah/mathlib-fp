# 1.7/1.8 gap-closure design and traceability record

Status: implementation and local release qualification complete on the
`release/v1.8.0` branch; publication remains intentionally paused.

## Purpose

Version 1.7.0 is already tagged and must not be rewritten. Version 1.8.0 will
therefore close material 1.7 contract and qualification gaps, complete the
enforceable 1.8 scope, and publish an accurate account of conditional work that
cannot pass the required numerical or platform gates.

This record is the focused design decision required by the roadmap before new
public types or storage contracts are introduced. It also prevents a capability
from being declared complete merely because a nearby example succeeds.

## Interpretation rules

Each roadmap item received one of four opening dispositions before the
gap-closing implementation:

- **complete** — implementation, public documentation, and direct tests exist;
- **must close** — unconditional roadmap work or completion-gate evidence is
  missing or materially overstated;
- **strengthen** — a baseline exists but needs an additional path, diagnostic,
  adversarial test, or example to support the published claim;
- **conditional defer** — the roadmap explicitly says “where justified”,
  “where quality can be validated”, “only after”, or “toward”. Deferral is
  permitted only when the prerequisite or supported-platform evidence is
  recorded in the capability inventory. It must not be described as stable.

All **must close** and **strengthen** rows are release blockers. A conditional
row becomes a release blocker if its prerequisite is established during this
release and a portable implementation can be qualified on the supported
matrix.

## Common public contract

The additions below retain the established contracts:

- arrays and matrices are zero-indexed;
- dense two-dimensional values use `[Row, Column]`;
- inputs are borrowed only for the duration of a call and are never mutated or
  retained unless a constructor explicitly documents that it copies them;
- result records, models, factors, interpolants, filters, and trees own their
  arrays independently;
- failure is atomic for caller-visible state and destination buffers;
- shape, finite-value, bounds, resource-limit, and callback errors use the
  owning domain exception;
- expected iterative outcomes use `TIterationStatus`; programmer errors raise;
- existing signatures remain source compatible and new detailed entry points
  are additive;
- every randomized API accepts caller-owned `TLocalRandom` state or an explicit
  seed and never changes RTL `RandSeed`;
- new persistence formats are versioned, endian-defined, size-limited, and
  completely validated before constructing or replacing a result.

## Focused names and layouts

The following names are approved for the gap-closing implementation. They are
additive; no existing record field is reordered or removed.

### Modelling and differentiation

- `dmComplexStep`, `TComplexScalarVectorFunction`, and
  `TDifferentiationKit.ComplexStepGradient` provide an explicitly analytic
  complex callback path. A real callback is never silently treated as
  complex-analytic.
- `TDualVectorFunction` and `AutoJacobian` provide the forward-AD vector path.
- `TJacobianCheckResult` and `CheckJacobian` report the worst output row and
  input column as well as analytic/reference values and absolute/relative
  errors.
- `TSplineBoundaryKind`, `TCubicSplineInterpolator`, `TSplineFitResult`, and
  `TModellingKit.FitSplineBasis`
  cover natural, clamped, and not-a-knot cubic splines and spline regression.
  The interpolator exposes read-only `Evaluate`, `Derivative`,
  `SecondDerivative`, `Antiderivative`, and `Integrate` operations and clamps
  evaluation to the documented knot interval like the existing cubic types.
  Spline regression uses the cubic truncated-power basis
  `[1,x,x²,x³,max(0,x-k[0])³,...]`; the result owns the interior knots and fit
  diagnostics and exposes `Evaluate`.
- `TPolynomialRootResult` owns complex roots and per-root residuals and reports
  a `TIterationStatus`, iterations, and evaluations.
  `TModellingKit.SolvePolynomial` accepts finite coefficients in ascending
  power order with a non-zero highest coefficient. It returns every complex
  root sorted lexicographically by real then imaginary part; no real-only
  filtering is permitted.
- `TModellingKit.IntegrateCubature` uses a tensor-product Gauss-Legendre rule
  of order 3 or 5 with an explicit evaluation cap. It targets low-dimensional
  smooth boxes only.
- `TModellingKit.IntegrateMonteCarlo` accepts caller-owned `TLocalRandom`
  state, returns a sample-standard-error estimate, and commits the advanced RNG
  state only after every callback result has been validated.
- Existing `TOptResult` gains appended `Evaluations`, `BestX`, and `BestFVal`
  fields. Existing fields and objective conventions are unchanged.
- Existing `TConvexResult` gains appended `BestX`, `BestObjective`, and
  `Certificate` fields. The first two own the best finite feasible iterate
  observed. `Certificate` is empty for ordinary outcomes and owns a
  unit-length recession direction when the QP solver can prove an
  unconstrained positive-semidefinite model unbounded. Constrained QP
  infeasibility is reported by status and feasibility residual; no unsupported
  dual-certificate claim is made.
- New detailed optimizers use `TOptimizationOptions` and return `TOptResult`.
  Bounds are optional copied arrays; progress callbacks are synchronous.
  The approved entry points are `NonlinearConjugateGradient`,
  `BoundedLBFGS`, `TrustRegion`, `LBFGSAuto`, and `MultiStart`.
  `TOptimizationOptions` owns no caller arrays; each call copies bounds and
  initial points into local state. It carries absolute, relative and gradient
  tolerances, iteration/evaluation limits, initial step/trust radius, L-BFGS
  history, deterministic seed, start count, and a cancellation callback.
- `TOptimizationWorkspace` owns an optional warm-start point plus cumulative
  run/evaluation counters. `BoundedLBFGSWithWorkspace` uses a matching stored
  point on subsequent calls and commits the new best point only after the solve
  returns; `Clear` drops reusable state. Quasi-Newton curvature history is not
  reused across distinct objectives.
- `TSmoothConstraint` stores a borrowed value callback, optional analytic
  gradient, equality/inequality kind, and feasibility tolerance.
  `SolveConstrained` returns the best finite iterate and explicit maximum
  feasibility rather than representing feasibility only through a penalty
  objective.
- `TMultiObjectiveResult` owns a deterministic collection of nondominated
  `TOptResult` points and their objective vectors. `ExplorePareto` accepts an
  explicit weight grid and makes no claim to find a complete non-convex front.
- `TModellingKit.FitNonlinearAuto`, `SolveSystemAuto`, and
  `TOptimizationKit.LBFGSAuto` are the explicit forward-AD solver paths.
  Existing entry points continue to select analytic callbacks when supplied
  and central numerical derivatives when they are absent.
- `TNonlinearFitOptions.ParameterScales` is an optional copied positive vector.
  Internally the LM step is solved in scaled coordinates while public
  parameters, bounds, residuals, and covariance remain in original units.
  Nonlinear covariance is returned only for squared loss, positive residual
  degrees of freedom, and a full-column-rank final Jacobian.
- `TAdaptiveODEOptions.AbsoluteTolerances` is an optional copied
  per-component vector. When present it replaces the scalar absolute tolerance
  in each component's embedded-error scale; relative tolerance remains shared.

### Applied numerics

- DSP additions remain on `TDSPKit`; batch results are arrays of the existing
  shared complex arrays. Overlap-add/save plans copy their impulse response and
  retain at most one documented block of state.
- `TOverlapAddConvolver` and `TOverlapSaveConvolver` copy the impulse response,
  return one causal output sample for each input sample, and expose copied
  tail/history state for failure-atomic restoration. `Flush` is specific to
  overlap-add and returns the remaining convolution tail while clearing it.
  `TComplexBatch` and `TSingleComplexBatch` contain independently owned shared
  complex arrays; `TransformBatch` preserves batch boundaries and precision.
  `HaarTransform` is the orthonormal power-of-two wavelet baseline and uses the
  same entry point with `Inverse=True` for reconstruction.
- Statistical additions live in `StatsLib.Inference`. Distribution models,
  estimates, test results, and regression diagnostics are value records owning
  their arrays.
- `TNormalDistribution`, `TExponentialDistribution`, and
  `TBinomialDistribution` provide paired density/mass, CDF, survival,
  log-density/mass, quantile, and caller-owned-RNG sampling operations.
  `TDistributionEstimate` reports owned parameters and standard errors,
  log-likelihood, iteration status, and identifiability for
  `EstimateNormal`, `EstimateExponential`, `EstimateGamma`, and
  `EstimateBinomial`.
- `TInferenceTestResult`, `TANOVAResult`, and `TContingencyResult` are the
  result contracts for one-sample/paired/Welch t tests, one-way ANOVA,
  chi-square contingency analysis, and Mann-Whitney analysis with average
  ranks and tie correction. `AdjustBonferroni` and
  `AdjustBenjaminiHochberg` return owned arrays and preserve input ordering.
- `TRegressionDiagnostics` and `TLogisticRegressionResult` own coefficients,
  standard errors, fitted values, and residuals/probabilities.
  `FitOLS` uses the shared SVD least-squares foundation and explicitly reports
  rank and degrees of freedom. `FitLogistic` uses bounded IRLS, reports
  convergence, and marks complete/quasi separation as non-identifiable rather
  than returning an unqualified fit.
- Higher-level analysis additions remain in `MLLib.Analysis`. Hierarchical
  clustering and decision forests own training-derived state and never retain
  the input matrix handle.
- `THierarchicalLinkage`, `THierarchicalClustering`, `HierarchicalCluster`,
  and `CutHierarchy` define a deterministic Euclidean agglomerative baseline
  with single, complete, and average linkage. Merge indices follow the usual
  leaf-first convention (`0..N-1` observations, then `N..2N-2` merges).
- `TStandardizationModel`, `FitStandardization`, and
  `TransformStandardized` separate fitting from transformation so validation
  rows cannot influence training means/scales. Non-finite and categorical
  values remain rejected; callers must impute/encode them explicitly.
- `TDecisionForest` owns portable CART trees, task metadata, normalized
  impurity-decrease feature importances, and an out-of-bag score.
  `FitClassificationForest` and `FitRegressionForest` use seeded bootstrap
  samples and feature subsampling; `PredictForestClasses` and
  `PredictForestValues` reject task mismatches. Importance is explicitly an
  impurity heuristic, not a causal or permutation claim.
- Multivariate linear-Gaussian filtering lives in
  `TimeSeriesLib.StateSpace` and uses typed dense matrices throughout.
- `TMultivariateKalmanConfiguration`, `TMultivariateKalmanFilter`,
  `TMultivariateKalmanStep`, `TMultivariateKalmanSeriesResult`, and
  `TMultivariateKalmanForecast` define the multivariate contract.
  Configuration and filter constructors clone all matrices/state; observations
  are rows in a typed dense matrix. Updates use the innovation-covariance solve
  and Joseph covariance form, return innovations and likelihood diagnostics,
  and replace filter state only after a complete finite update.
- Cross-domain persistence adapters live in `InterchangeLib.Models`, keeping
  `MathBase.Interchange` independent of modelling, DSP, and ML units.
- `SaveCubicSpline`/`LoadCubicSpline`, `SaveStreamingFIR`/
  `LoadStreamingFIR`, `SaveStandardization`/`LoadStandardization`, and
  `SaveScalarKalman`/`LoadScalarKalman` use one adapter envelope with magic,
  version, kind, little-endian payload length, and CRC-32. Loads enforce an
  explicit element cap and fully validate payloads before constructing a
  returned value. The existing `MathBase.Interchange` RNG format remains the
  RNG-state contract.
- `TValueMetadata` plus `Describe` overloads report scalar type, rank/shape,
  and element count for real/complex vectors and matrices.
  `MathBase.Interchange.Summarize` gains a complex-vector overload;
  `InterchangeLib.Models` supplies concise `Summarize*` functions for each
  persisted model family.
- The optional, non-Turing-complete evaluator lives in
  `MathBase.Expressions`. It has no assignment, loops, recursion, file,
  process, environment, or network primitives. Callers provide an immutable
  symbol table and explicit operation/element limits.
- `TExpressionValue`, `TExpressionSymbol`, `TExpressionLimits`, and
  `TExpressionEvaluator.Evaluate` are the bounded evaluator surface.
  Values own vectors and clone matrices. Expressions support finite scalar
  literals, bound symbols, parentheses, arithmetic, elementwise elementary
  functions, `dot`, `matmul`, and `transpose`; there is deliberately no
  assignment or user-defined function mechanism. Shape/type errors and text,
  depth, element, or operation limit exhaustion raise
  `EExpressionError` before a result is returned.

## 1.7.0 traceability

### Interpolation and approximation

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Stable barycentric and rational interpolation | complete | Existing direct/reference tests |
| Configurable spline boundaries, PCHIP/Akima, derivatives and integrals | must close | Add natural/clamped/not-a-knot spline tests; retain PCHIP/Akima tests |
| Bilinear and bicubic gridded surfaces | complete | Existing planar-grid tests |
| IDW, RBF, and thin-plate scattered interpolation | strengthen | Add thin-plate, duplicate-node, conditioning, and documented scale tests |
| Separate interpolation, smoothing, and regression contracts | strengthen | Add spline-regression API and selection example |

### Linear and nonlinear fitting

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Polynomial, linear-basis, spline, and weighted least squares through QR/SVD | must close | Add spline basis fit and weighted/rank-deficient references |
| Scaled bounded robust nonlinear least squares with analytic/numerical Jacobians | strengthen | Add badly-scaled, bounded, robust-loss, and numerical-Jacobian references |
| Parameters, residuals, rank, DoF, covariance, status, and fit diagnostics | strengthen | Verify covariance eligibility and failure outcomes |
| Noisy, badly-scaled, rank-deficient, and bounded worked examples | must close | Expand example 17 without synthetic exact-only claims |

### Integration, equations, and ODEs

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Adaptive Gauss-Kronrod and improper integration | strengthen | Add discontinuous/limit/error-estimate tests |
| Dimension-aware cubature/QMC/Monte Carlo | must close | Add deterministic cubature and local-RNG Monte Carlo with uncertainty |
| Safeguarded scalar, polynomial, and nonlinear-system roots | must close | Add all-complex polynomial roots and residual diagnostics |
| Adaptive vector ODE, dense output, and events | strengthen | Add reverse-time, vector-tolerance, cancellation, and failure tests |
| Stiff ODE and mass-matrix support where justified | conditional defer | Requires a separately qualified implicit linear-solve/Jacobian design |
| Reentrant callback APIs | strengthen | Add nested integration/root/ODE/optimisation tests |

### Differentiation

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Forward, central, and complex-step differentiation | must close | Add explicit complex callback path and non-analytic limitation tests |
| Forward-mode AD foundation | strengthen | Add vector Jacobian and elementary-function tests |
| Analytic, automatic, and numerical solver derivative paths | must close | Add AD overloads/adapters for fitting, roots, and smooth optimisation |
| Pre-solve derivative checking | strengthen | Add Jacobian checks with variable/row diagnostics |
| Differentiability guidance | strengthen | Document branches and unsupported dual/complex functions |

### Optimisation

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Unified configurations/results and full diagnostics | must close | Append counts/best iterate; add detailed entry points and tests |
| Line search, nonlinear CG, L-BFGS, bounded L-BFGS, trust region, Nelder-Mead, multistart | must close | Add missing algorithms and adversarial status tests |
| Box/linear/nonlinear constraints with explicit feasibility | must close | Add constrained smooth solver; penalty-only is compatibility-only |
| Robust LP and QP with infeasible/unbounded outcomes | must close | Add phase-I feasibility/unbounded references and detailed QP outcomes |
| Interior-point LP | conditional defer | Activate only after phase-I simplex/QP scaling evidence is green |
| Convex/non-convex quadratic constraints and general cones | conditional defer | Existing feasible-start affine SOCP remains bounded stable surface |
| Smooth/nonsmooth constrained, multiobjective, reproducible global strategies | must close | Add representative APIs/results and selection tests |
| Scaling, warm starts, cancellation, reusable state | must close | Add options/workspace paths for new detailed solvers |
| Sparse constraints | conditional defer | Separate sparse-storage milestone prerequisite is absent |
| Integer/mixed-integer optimisation | conditional defer | Continuous-relaxation and certificate prerequisite is not yet met |

### 1.7 completion gate

| Gate | Disposition |
| --- | --- |
| Representative end-to-end workflows | strengthen — broaden fitting and failure examples |
| Complete applicable termination distinctions | must close — legacy and QP outcomes are incomplete |
| Analytic/AD/numerical agreement and bad-derivative discovery | strengthen — extend beyond one scalar fixture |
| Reentrant deterministic callbacks | strengthen — current evidence is too narrow |
| Complete selection guidance | strengthen — add new detailed solver choices and explicit deferrals |

## 1.8.0 traceability

### FFT and DSP

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Real/complex arbitrary, inverse, 2-D, single/double FFT | complete | Existing DFT oracle and round-trip tests |
| Direct/FFT convolution plus overlap-add/save and deterministic selection | must close | Add both block paths, threshold/state tests, and direct oracle |
| Streaming filters, resampling, spectra, windows | strengthen | Add state restoration and long-block equivalence tests |
| STFT, analytic signal, coherence/cross spectrum, wavelet baseline | must close | Add Haar/DWT baseline and reconstruction/energy tests |
| FIR Remez and Butterworth/Chebyshev/elliptic/Bessel IIR where validated | conditional defer | Butterworth remains stable; activate families only with published response references |
| Batched transforms without format conversion | must close | Add shared-array batch APIs and parity tests |
| Filter phase/frequency/padding/delay/stability/state conventions | strengthen | Complete public table and validation tests |

### Probability and statistics

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Broader paired PDF/CDF/SF/log/quantile/sampling distributions | must close | Add a coherent representative continuous/discrete family set |
| Parameter estimation with uncertainty/convergence/identifiability | must close | Add normal/exponential/gamma/binomial estimation baselines |
| Local reproducible RNG and splitting | complete | Existing fixed-sequence and global-state tests |
| Weighted online mergeable statistics | complete | Existing bounded-state/merge/failure-atomic tests |
| Common tests, ANOVA, contingency, ties, intervals, effects, corrections | must close | Add result records and published reference fixtures |
| Linear/GLM diagnostics on shared fitting layer | must close | Add OLS/logistic diagnostics and rank/separation handling |
| Survival/reliability and multivariate factor/MDS when documented | conditional defer | Activate representative Kaplan-Meier/Weibull/MDS only with assumption tests |

### Data analysis and time series

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| PCA and LDA through shared decompositions | strengthen | Add rank-deficient and multiclass limitations/tests |
| K-means++, hierarchical clustering, distances/linkages | must close | Add deterministic agglomerative clustering and linkage tests |
| Exact low-dimensional nearest-neighbour index | complete | Existing immutable KD-tree tests |
| Reproducible decision-forest baseline | must close | Add classification/regression, metrics, OOB/importance limitations |
| Splits, preprocessing pipelines, model selection, missing/categorical policy | must close | Add fitted-transform pipeline and leakage tests |
| Forecast intervals, Kalman foundations, multivariate/spectral integration | must close | Add multivariate Kalman and interval/innovation diagnostics |

### Interchange, inspection, and tooling

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Invariant scalar/vector/matrix/model forms | must close | Add selected stable model/filter/spline forms |
| Delimited, Matrix Market, versioned binary | complete | Existing corruption/size/round-trip tests |
| Model/decomposition/spline/filter/RNG/config persistence | must close | Add optional adapter unit and compatibility/failure-atomic tests |
| Concise/full summaries plus shape/type metadata | must close | Add metadata records and complex/model summaries |
| Safe bounded expression evaluator | must close | Add parser/evaluator/resource/adversarial tests |
| Optional I/O/evaluator/adapters | complete | Preserve independent core-unit builds |

### Portable performance

| Roadmap outcome | Disposition | Release evidence required |
| --- | --- | --- |
| Caller buffers/workspaces and allocation measurement | strengthen | Add allocation counters for representative hot paths |
| Blocked kernels and bounded deterministic parallel execution | conditional defer | Serial blocked oracle is stable; activate threads only with Win32/Linux/Windows determinism evidence |
| Compile-time SIMD for x86/ARM after scalar stability | conditional defer | Cross-architecture compiler/CI evidence is not currently available |
| Separate small, batched, streaming, and large workloads | strengthen | Expand benchmark classes and allocation reporting |
| Published baseline/regression tracking | complete | Existing qualification comparison; retain on final code |
| Win32 overflow/address/allocation audit | strengthen | Re-run all new shape/resource cases under i386 |
| Broader OS/architecture support toward ARM64/macOS | conditional defer | Requires maintainable hosted runners; do not claim unexecuted targets |

### 1.8 completion gate

| Gate | Disposition |
| --- | --- |
| Shared DSP/statistics/fitting/analysis containers | complete |
| Bounded-memory streaming and documented state | strengthen — add restored/long-block paths |
| Portable failure-atomic persistence | strengthen — extend to selected models |
| Portable oracle for optional accelerated paths | complete for shipped serial paths; conditional paths remain unsupported |
| Published accuracy/performance comparison | strengthen — rerun after gap closure |
| Published workflow/limit/open-item inventory | strengthen — regenerate from this final matrix |

## Completion rule

The branch is not ready to tag while any **must close** or **strengthen** row
lacks implementation, direct tests, and public documentation. Conditional
deferrals must remain visible in the roadmap, capability inventory, release
notes, and qualification report, with the missing prerequisite stated.

## Final closure audit

The disposition columns above preserve the pre-implementation audit, not the
current completion status. Every **must close** and **strengthen** row now has
implementation, direct tests, and public documentation:

| Area | Closure evidence |
| --- | --- |
| Interpolation/fitting | `TCubicSplineInterpolator`, spline/weighted/rank-deficient fitting, scaled bounded robust nonlinear fitting, covariance eligibility tests, expanded example 17, and `NumericalModelling.md` |
| Integration/roots/ODE | cubature, caller-RNG Monte Carlo, all-complex polynomial roots, discontinuity/limit/reentrant tests, component ODE tolerances, reverse/cancel/failure tests, and `NumericalModelling.md` |
| Differentiation | explicit complex callback, vector AD/Jacobian checking, AD fitting/root/optimisation adapters, non-analytic guidance, and direct tests |
| Optimisation | detailed options/results, NCG/bounded L-BFGS/trust/AD/multistart/constrained/Pareto paths, warm-start workspace, two-phase LP, QP outcome/certificate evidence, and both optimisation guides |
| DSP | batch transforms, overlap-add/save, state restoration/long blocks, Haar energy/reconstruction, threshold/oracle tests, conventions table, and expanded benchmarks |
| Inference | paired distributions, estimates, tests/effects/corrections, SVD OLS, logistic identifiability, reference/adversarial tests, and `StatsLib.md` |
| Data/time series | hierarchy/linkages, fitted-transform leakage boundary, seeded classification/regression forests with OOB/importance, multivariate Kalman innovations/likelihood/forecast/failure atomicity, and public guides |
| Interchange/tooling | typed metadata, complex/model summaries, versioned selected-model adapters with corruption/resource tests, bounded expressions with adversarial limits, and `Interchange.md` |
| Performance/evidence | small, batch, stream, and large deterministic benchmarks with public allocation/state counters; the final platform/archive results are recorded in `QUALIFICATION_1.8.0.md` |

Conditional rows remain deferred for the prerequisite stated in their original
row and are repeated in the capability inventory, release notes, and
qualification report. They are not represented as stable APIs.
