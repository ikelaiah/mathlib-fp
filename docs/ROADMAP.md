# Roadmap

mathlib-fp aims to become the comprehensive, freely available numerical-
computing library for Free Pascal: useful for a first numerical program,
dependable in production, and capable enough for large, real-world scientific
and engineering applications while remaining entirely native.

The project is built on the following non-negotiable foundations:

- MIT-licensed source code that compiles with Free Pascal;
- native Object Pascal implementations rather than wrappers around
  implementations written in another language;
- no required DLLs, binary SDKs, or third-party runtime libraries;
- correct, portable implementations before architecture-specific optimisation;
- independently usable units rather than a mandatory monolithic import;
- documentation and source comments treated as part of the public API;
- compatibility and migration paths that respect existing users.

## Product ambition

mathlib-fp is intended to meet four related needs in the Pascal ecosystem.

1. **A dependable standard numerical library for Free Pascal.** It should be
   a well-maintained foundation with accurate algorithms, explicit contracts,
   approachable documentation, and dependable releases.
2. **Comprehensive numerical breadth in native Pascal.** The long-term coverage
   target includes dense and sparse linear algebra, interpolation and fitting,
   optimisation, FFT/DSP, statistics, data analysis, integration, nonlinear
   equations, and ODEs.
3. **Productive, scalable numerical programming for Pascal developers.** The
   direction includes expression-friendly real and complex vector/matrix
   arithmetic, reusable memory, serious decompositions and solvers,
   DSP/statistical workflows, and portable performance from implementations
   maintained within this source tree.
4. **Documentation and source that teach as well as serve.** A newcomer should
   be able to choose and use an algorithm safely, while an expert should be
   able to audit its mathematics, numerical safeguards, complexity, ownership,
   and platform behavior from the documentation and code.

Success means broad, reliable coverage and the ability to complete common
scientific and engineering workflows. Each minor release should update the
project's capability inventory and state important remaining gaps honestly.

The distinguishing promise of mathlib-fp is that the portable implementation
remains readable Free Pascal source. Optional acceleration may improve it, but
must never become necessary to obtain correct and complete functionality.

## What “best” means for this project

The project should not call itself complete merely because it has many
functions. Its standard is the combination of:

- **mathematical trust** — published accuracy expectations, independent
  references, visible convergence outcomes, and regression tests for every
  corrected defect;
- **explainability** — clear selection guides, public contracts, algorithm
  references, and source comments that explain numerical decisions;
- **end-to-end usefulness** — compatible containers and result types that let
  callers complete realistic workflows without private conversions or solvers;
- **scalability** — algorithms and storage appropriate to both small interactive
  problems and large dense, sparse, batched, streaming, or parallel workloads;
- **stability** — deliberate versioning, migration paths, reproducible results,
  and a public maturity level for each capability;
- **independence** — complete portable Pascal paths with no mandatory service,
  binary component, proprietary tool, or network connection.

Claims about accuracy, performance, breadth, or readiness must be supported by
published evidence. Missing and experimental capabilities should be easier to
find than marketing language.

## How to read this roadmap

Versions below are **capability gates, not date promises**. A release ships when
its required algorithms, contracts, tests, documentation, and supported-
platform checks are ready. Proposed details may change after design work or
numerical evidence, but the dependency order should remain stable.

The project follows Semantic Versioning:

- patch releases correct defects, improve robustness, or clarify documentation
  without adding a planned family of public APIs;
- minor releases add backward-compatible capabilities;
- 1.x keeps established APIs working wherever correctness permits and provides
  adapters or deprecation notices for APIs that will change;
- 2.0.0 is the point at which the coherent replacement API becomes the default
  and previously announced breaking changes may be completed.

A 1.3.x maintenance release may therefore occur before 1.4.0, but GeometryLib
vector arithmetic is new public API and belongs to 1.4.0.

## Release sequence at a glance

| Release | Primary outcome |
|---------|-----------------|
| 1.3.0 | Complex scalars and allocation-light real/complex vector kernels |
| 1.4.0 | Ergonomic and consistent 2-D/3-D geometry vector arithmetic |
| 1.5.0 | Typed contiguous scalar, vector, and dense matrix foundation |
| 1.6.0 | Production-grade dense/sparse decompositions and linear solvers |
| 1.7.0 | Interpolation, fitting, advanced numerics, and optimisation |
| 1.8.0 | Applied numerics, interchange, tooling, and performance maturity |
| 2.0.0 | Unified stable API, complete migration, and documented capability baseline |

## Implementation discipline

This roadmap describes a sequence of release outcomes, not one implementation
task. Work should proceed one release and one reviewable change at a time.

- Only the release marked **Next release** is the active feature target.
  Later planned releases provide architectural direction and should not be
  implemented opportunistically.
- Before adding a public type or changing storage, document ownership, aliasing,
  mutation, indexing, shape, error, and compatibility decisions.
- Add or change tests and public documentation in the same change as the
  implementation. Do not leave them as end-of-release cleanup.
- Prefer shared kernels over private copies, but remove an existing
  implementation only after behavioral and numerical equivalence is tested.
- Do not invent final public names, layouts, or deprecations from roadmap prose
  alone. Resolve them in a focused design issue or reviewable implementation
  change.
- Keep each change small enough that its numerical assumptions, compatibility,
  and performance consequences can be reviewed independently.

## Current release: 1.3.0

Released on 2026-07-23, version 1.3.0 establishes the complex-number and vector
foundation required by the next generation of algebra and signal-processing
features. It preserves the existing matrix-as-vector API: an `IMatrix` with
one row or one column remains an `IVector` and keeps its `DotProduct`,
`CrossProduct`, and `Normalize` methods.

The new foundation adds a complementary, allocation-light array API rather
than replacing matrices:

- `MathBase.Complex` supplies the scalar `TComplex` type, scale-safe division,
  signed-zero-aware principal functions (including inverse trigonometric and
  hyperbolic functions), and `TComplexArray`;
- `AlgebraLib.VectorKernels` supplies real and complex array-vector kernels
  (compensated reductions, elementwise operations, stable norms, scaling,
  AXPY-style combination, normalization, and reusable destination buffers);
- `AlgebraLib.Vectors` remains the compatibility-oriented entry unit and
  re-exports the new array-vector types and kernel facade;
- signal processing uses `TComplexArray` as the FFT core while retaining its
  existing split real/imaginary procedures as source-compatible adapters.

### Completed 1.3.0 scope

- Complex arithmetic has documented branch, zero, non-finite, and
  overflow-resistance behavior with reference and identity tests.
- Vector kernels validate dimensions and finite input, define empty-vector
  results, and use scale-safe norm accumulation.
- Every new public unit has API documentation, a runnable example, package
  registration, focused tests, and Linux/Win64/Win32 CI coverage configured.
- Complex arithmetic, vector kernels, and FFTs have representative benchmarks
  and public API smoke coverage.
- Existing `IMatrix` vector behavior remains source-compatible and covered by
  the existing algebra test suite.

The release passed Linux and Windows CI, Win64 normal, optimized,
runtime-checked, and heap-traced test runs, and the optimized Win32 suite. See
the [1.3.0 release notes](RELEASE_NOTES_1.3.0.md) for the delivered API and
validation summary.

## Previous release: 1.2.3

Version 1.2.3 was a correctness and robustness release. It did not add a new
domain. It concentrated on the operations already exposed:

- improved special-function accuracy, convergence handling, and tail behavior;
- removed overflow, underflow, and cancellation from representable results;
- corrected formulas whose happy-path tests masked mathematical defects;
- expanded reference-value, identity, residual, property, and extreme-scale
  tests;
- kept public signatures source-compatible wherever correctness permitted.

## Next release: 1.4.0 — Geometry vector arithmetic

The focus of 1.4.0 is a small but complete improvement to GeometryLib's
fixed-size value types. It responds directly to the first external feature
request received by the project: make ordinary vector arithmetic expressible
without reconstructing a vector from its individual coordinates.

### Planned scope

- Add vector addition, subtraction, and unary negation for `TVector2D` and
  `TVector3D`.
- Add scalar multiplication in both operand orders and vector/scalar division.
- Prefer natural operators such as `V1 + V2` while adding named methods only
  when compiler compatibility or API clarity requires them.
- Keep the 2-D and 3-D APIs symmetrical unless a genuinely dimensional
  operation, such as the 2-D perpendicular, makes that impossible.
- Define and test zero-scalar division, signed zero, NaN, Infinity, overflow,
  and alias/value semantics rather than inheriting accidental target behavior.
- Update the GeometryLib reference and runnable geometry example. With the
  contributor's permission, include or link a compact Theodorus-spiral example
  that demonstrates the motivating workflow.
- Add public-API smoke checks and focused algebraic properties such as identity,
  inverse, distributivity, scaling, and agreement between 2-D and 3-D forms.
- Make the existing 2-D and 3-D magnitude and normalization methods scale-safe
  for finite tiny and large components, with explicit exact-zero and non-finite
  normalization behavior.
- Document that fixed-size vector arithmetic is O(1), allocation-free,
  reentrant, and thread-safe when callers do not concurrently mutate the same
  record storage.

Point/vector translation operators are not automatically part of this change.
They should be added only after the distinctions between points, displacement
vectors, and coordinate transforms have a documented, consistent design.

### 1.4.0 completion gate

- The complete operator set compiles on every supported Free Pascal target.
- 2-D and 3-D behavior is consistent and has edge-case and property tests.
- Magnitude and normalization avoid premature intermediate overflow and
  underflow; normalization also works when a finite vector's magnitude exceeds
  the representable `Double` range.
- The motivating example can use `V1 := V1 + V2` without coordinate-by-
  coordinate reconstruction.
- Reference documentation, code comments, example output, changelog, package
  metadata, and release notes describe the delivered API and behavior.
- Existing GeometryLib callers remain source-compatible.

## Planned 1.5.0 — Typed contiguous numerical foundation

Version 1.5.0 establishes the scalar, storage, and kernel layers on which the
later linear-algebra, fitting, signal, statistics, and machine-learning work
can share one implementation. The current `IMatrix` API and nested
`array of array of Double` storage remain available as compatibility paths;
they must not constrain the new engine's type support, layout, or performance.

### Precision and scalar policy

- Keep `Double` as the reference precision and make `Single` a deliberate,
  tested first-class option for storage and performance-sensitive kernels.
- Provide matching real/complex types and operations. Do not label a type
  supported when callers must repeatedly convert it through `Double`.
- Treat `Extended` as a platform-dependent type: document its actual precision
  on each target and never promise extra bits where the ABI aliases it to
  `Double`.
- Use `SizeInt`/`SizeUInt` or another overflow-checked native-size policy for
  dimensions, strides, and allocation arithmetic. Narrow public indices only
  where the supported limit is explicit.
- Define conversion and rounding behavior between integer, single, double,
  extended, and complex values. Reject implicit conversions that can silently
  discard an imaginary component or overflow.
- Expand scalar special functions according to demonstrated downstream need,
  including the error, gamma/beta, Bessel, elliptic, exponential-integral, and
  related families. Each function family needs a documented domain, branch,
  accuracy budget, and independent reference corpus.
- Report elementary-function error in ULPs where that measure is meaningful;
  use absolute, relative, log-domain, and tail-probability error measures for
  special functions where a single ULP claim would mislead.
- Apply scalar elementary and special functions efficiently to vectors and
  matrices through shared kernels instead of duplicating formula code.
- Publish behavior for subnormals, signed zero, NaN, Infinity, overflow,
  underflow, and FPU exception/rounding modes on supported targets.

### Data model and ownership

- Introduce aligned, contiguous row-major real and complex dense matrix storage
  with explicit dimensions and overflow-checked allocation.
- Specify the distinction between owned values, borrowed views, mutable views,
  and copies. Document lifetime, aliasing, copy, and thread-safety rules.
- Support rows, columns, diagonals, and rectangular submatrix views with
  explicit offsets and strides where they can be implemented safely.
- Provide checked element access for ordinary code and internal unchecked
  kernels only behind validated boundaries.
- Provide conversions to and from `TDoubleArray`, `TComplexArray`, the current
  nested `TMatrixArray`, and `IMatrix` without hiding unavoidable copies.
- Define empty shapes, zero-length dimensions, maximum supported dimensions,
  and real/complex conversion rules.
- Provide the integer/index containers needed for permutations, labels, sparse
  structure, and selection without pretending that every floating-point
  algorithm is meaningful for integer matrices.
- Design small fixed-size and batched operations so that tiny matrices do not
  pay heap allocation or general-kernel startup costs.
- Do not introduce implicit broadcasting. Shape-changing or elementwise
  behavior must be explicit and unambiguous.

### Real and complex kernels

- Generalise the 1.3.0 vector kernels into reusable Level-1/2/3-style
  operations: reductions, AXPY, dot products, matrix-vector products,
  matrix-matrix products, triangular operations, transposition, and copying.
- Supply allocating functions and allocation-avoiding `...Into` or workspace
  forms for repeated calculations.
- Treat ordinary multiplication, elementwise multiplication, transposition,
  conjugation, and conjugate transposition as distinct operations.
- Use compensated or scale-safe algorithms where straightforward summation or
  squaring loses representable results.
- Establish predictable alias rules so in-place operations either work by
  contract or fail before modifying the destination.
- Provide expression-friendly operators for common real and complex arithmetic
  without making allocation costs invisible in the documentation.

### Initial factorisation and solve path

- Add a public `Solve(A, B)` path for square systems; users should not have to
  form `A.Inverse` to solve `AX = B`.
- Support vector and multiple right-hand sides.
- Make LU with pivoting, triangular solves, and Cholesky the first consumers of
  the contiguous kernels.
- Return reusable factorisation objects so repeated solves do not repeat the
  decomposition.
- Report singularity, invalid shape, non-finite input, and ill-conditioning
  through documented results or exceptions rather than partial answers.

### Compatibility and migration

- Preserve the existing `IMatrix`, `TMatrixKit`, and `IVector` entry points in
  1.5.0 and route them through the new kernels where this does not change their
  documented behavior.
- Publish a migration guide that compares the compatibility API, the new value
  API, and allocation-avoiding kernels by use case.
- Mark an API deprecated only when its replacement is implemented, documented,
  and demonstrably usable.

### 1.5.0 completion gate

- Real and complex arithmetic share one coherent shape, ownership, and error
  model.
- Dense matrix multiplication has reference, aliasing, odd-shape, empty-shape,
  extreme-scale, and deterministic benchmark coverage.
- Direct solves use factorisation rather than explicit inversion and publish
  residual/backward-error tests.
- Common vector/matrix expressions are concise enough for interactive examples
  while reusable-buffer APIs remain available for performance-sensitive code.
- Single- and double-precision paths have the same documented operation set,
  and reference tests use precision-appropriate error budgets.
- Dimension and allocation arithmetic is proven not to wrap on 32- or 64-bit
  targets.
- The scalar/special-function inventory publishes supported domains and measured
  accuracy; unsupported families are visible in the capability inventory.
- No compatibility API is removed, and every migration or copy cost is
  documented.

## Planned 1.6.0 — Complete dense and sparse linear algebra

Version 1.6.0 turns the 1.5.0 engine into the dependable linear-algebra base
expected of a mature numerical-computing library. Existing algorithms are
audited and then retained, replaced, or narrowed according to numerical
evidence; an algorithm is not considered complete merely because a method with
its name already exists.

### Dense decompositions and solvers

- Provide LU, Cholesky, LDLT, Householder QR/LQ, column-pivoted QR, SVD, and
  reusable triangular solve APIs for real and complex matrices as applicable.
- Provide symmetric/Hermitian eigensystems and general real/complex
  eigensystems, including complex eigenvalues rather than silently excluding
  common nonsymmetric problems.
- Add generalised symmetric-definite and general real/complex eigenproblem
  APIs only with explicit balancing, ordering, conditioning, and eigenvector
  conventions.
- Add direct square solves, under- and overdetermined least-squares solves,
  minimum-norm solutions, multiple right-hand sides, and factor reuse.
- Define numerical rank and condition estimates with caller-selectable or
  scale-derived tolerances; avoid estimating condition by explicitly computing
  a full inverse when a stable estimator is available.
- Add Schur-based or otherwise stability-appropriate matrix functions where a
  complete contract can be supported.
- Expose convergence, rank, pivoting, residual, reciprocal-condition, and
  iteration information in result records instead of reducing all outcomes to
  a matrix or exception.

### Structured and large-scale problems

- Represent diagonal, triangular, symmetric/Hermitian, banded, tridiagonal, and
  packed matrices without silently expanding them to general dense storage.
- Provide structure-aware multiplication, factorisation, determinant, solve,
  and eigenvalue paths where they materially reduce work or memory.
- Support low-rank updates/downdates and repeated-solve workflows when a stable
  algorithm exists; invalidate factors explicitly when their source changes.
- Add partial dense and sparse eigensolvers for callers that need a selected
  part of the spectrum rather than every eigenpair.
- Accept linear-operator callbacks in Krylov algorithms so callers can solve
  matrix-free and out-of-core problems with documented workspace bounds.
- Ensure structured inputs can opt into a general algorithm explicitly when no
  specialised path exists; never make an expensive conversion invisible.

### Sparse matrices

- Replace linear-search sparse storage with documented compressed sparse row
  and/or column formats plus an efficient triplet/builder input path.
- Preserve sparsity for operations whose mathematical result remains sparse;
  conversion to dense must be explicit.
- Supply sparse matrix-vector/matrix products, transposition, scaling,
  triangular operations, and sparse norms.
- Add CG, MINRES, GMRES, BiCGSTAB, and LSQR as their matrix assumptions justify,
  with explicit convergence and breakdown results.
- Provide at least diagonal/Jacobi and incomplete-factorisation
  preconditioners, and accept operator callbacks for matrix-free problems.
- Add sparse symmetric eigensolvers and shift/selection controls with residual
  and convergence reporting.
- Add pure-Pascal sparse direct Cholesky/LU capability once ordering, fill-in,
  and singularity behavior meet the same correctness contract as dense solves.

### Validation and performance

- Test reconstruction, orthogonality/unitarity, residual, backward error,
  eigenpair residuals, rank-deficient cases, clustered spectra, and scaled
  ill-conditioned systems.
- Keep independent high-precision or trusted reference fixtures in the test
  suite without adding a runtime dependency.
- Benchmark dense and sparse operations by size, shape, density, real/complex
  type, allocation mode, and thread count.
- Document when a decomposition, direct solver, or iterative solver is the
  appropriate choice and give examples that solve systems rather than merely
  print factors.

### 1.6.0 completion gate

- The documented dense decomposition set works for rectangular, rank-deficient,
  real, and complex cases within its stated contracts.
- Common structured systems use structure-aware storage and algorithms, and
  partial eigensolvers do not compute an unnecessary full decomposition.
- Sparse storage has complexity appropriate to large sparse problems and does
  not densify silently.
- Direct and iterative solvers expose verifiable outcome information and never
  return an unconverged iterate as success.
- All higher-level libraries use shared algebra solve/decomposition APIs instead
  of maintaining avoidable private Gaussian-elimination copies.

## Planned 1.7.0 — Numerical modelling and optimisation

Version 1.7.0 builds higher-level numerical workflows on the 1.5/1.6 engine.
The aim is not a catalogue of disconnected routines, but end-to-end APIs that
help callers select an algorithm, configure it, inspect its outcome, and
understand its limitations.

### Interpolation and approximation

- Add stable barycentric polynomial interpolation and rational interpolation.
- Extend splines with configurable boundary conditions, monotone/PCHIP and
  Akima-style options, derivatives, antiderivatives, and definite integrals.
- Add bilinear and bicubic surfaces for gridded 2-D data.
- Add scattered-data methods such as inverse-distance weighting, radial basis
  functions, and thin-plate splines, with scalability and conditioning limits
  documented.
- Separate interpolation, smoothing, and regression contracts so callers do
  not accidentally treat a fitted curve as an exact interpolant.

### Linear and nonlinear fitting

- Provide polynomial, linear-basis, spline, and weighted least-squares fitting
  through the shared QR/SVD solvers.
- Add Levenberg-Marquardt/trust-region nonlinear least squares with analytic or
  numerical Jacobians, parameter scaling, bounds, and robust loss options.
- Return fitted parameters together with residuals, rank, degrees of freedom,
  covariance/uncertainty estimates where justified, iteration status, and
  goodness-of-fit diagnostics.
- Include worked examples for noisy, badly scaled, rank-deficient, and bounded
  fits rather than only exact synthetic data.

### Integration, equations, and ODEs

- Add adaptive Gauss-Kronrod integration with absolute/relative tolerances,
  interval subdivision limits, improper-integral transforms, and visible error
  estimates.
- Add multidimensional cubature, quasi-Monte-Carlo, and Monte-Carlo integration
  only with dimension-appropriate error estimates, reproducible sampling, and
  a guide explaining when deterministic quadrature stops scaling.
- Extend scalar roots with safeguarded methods and add polynomial and nonlinear
  system solvers with residual/Jacobian reporting. Polynomial solvers must
  return real or complex roots without silently discarding either.
- Add vector-system adaptive embedded Runge-Kutta ODE integration, dense
  output, event detection, mass-matrix support where justified, and documented
  methods for non-stiff and stiff systems.
- Make all callback-based APIs reentrant. Remove unit-global callback bridges
  that serialize otherwise independent calculations.

### Differentiation and derivative checking

- Provide scale-aware finite-difference gradients, Jacobians, and Hessian
  approximations with forward, central, and complex-step methods where their
  mathematical assumptions hold.
- Add a forward-mode automatic-differentiation foundation for scalar and
  small-to-medium parameter problems before considering a larger reverse-mode
  system.
- Let fitting, root, ODE, and optimisation APIs accept analytic, automatic, or
  numerical derivatives through one documented contract.
- Verify user-supplied derivatives against directional or finite-difference
  checks on request, reporting the variable and scale of a disagreement.
- Document differentiability requirements and do not apply automatic
  differentiation blindly through discontinuities, branches, or unsupported
  special functions.

### Optimisation

- Unify scalar and multivariable solvers around configuration and result
  records with termination reason, objective value, gradient/constraint norms,
  evaluation counts, and best-known iterate.
- Strengthen line search, nonlinear conjugate-gradient, L-BFGS, bounded
  L-BFGS, trust-region, Nelder-Mead, and derivative-free global/multistart
  methods.
- Add box, linear equality/inequality, and nonlinear constraint handling using
  algorithms with explicit feasibility measures rather than a penalty-only
  facade.
- Provide robust simplex and interior-point linear programming plus
  quadratic-programming APIs, including infeasible and unbounded certificates
  where the algorithm can support them.
- Add convex and non-convex quadratic constraints, second-order cone problems,
  and a documented conic model after the LP/QP sparse constraint and scaling
  foundations are proven.
- Add smooth constrained nonlinear methods, nonsmooth/derivative-free
  alternatives, multiobjective outcomes, and reproducible global/multistart
  strategies. Local and global claims must be distinguished explicitly.
- Support dense and sparse constraints, variable/objective scaling, warm
  starts, progress/cancellation callbacks, and reusable solver state.
- Develop integer and mixed-integer optimisation only after the continuous
  relaxations are reliable. Initial MILP/MINLP work remains experimental until
  branch-and-bound, bounds, termination, and reproducibility gates are met.

### 1.7.0 completion gate

- Representative interpolation, fitting, integration, root, ODE, LP/QP,
  cone-constrained, and nonlinear-optimisation workflows run end-to-end with
  diagnostic results.
- Every iterative algorithm distinguishes convergence, acceptable limits,
  stagnation, numerical breakdown, infeasibility, and iteration exhaustion as
  applicable.
- Analytic, automatic, and numerical derivative paths agree on smooth reference
  problems within their documented precision, and bad derivatives are
  discoverable before a long solve.
- Callback APIs are reentrant and have deterministic tests where randomness is
  involved.
- Selection guides explain which algorithms apply to smooth/nonsmooth,
  bounded/unbounded, dense/sparse, stiff/non-stiff, and exact/noisy problems.

## Planned 1.8.0 — Applied numerics, tooling, and performance maturity

Version 1.8.0 broadens the workflows most visible to scientists and engineers
and hardens the entire stack for larger data. It is the final additive release
before the 2.0 API and compatibility boundary is finalised.

### FFT and digital signal processing

- Support real and complex FFTs for power-of-two and arbitrary lengths, inverse
  transforms, and 2-D transforms with documented normalisation conventions.
- Provide direct and FFT-based convolution/correlation, overlap-add/save, and
  automatic method selection with reproducible thresholds.
- Add streaming filter state, resampling and multirate helpers, spectral
  estimation, periodograms/Welch methods, and common window metrics.
- Add short-time Fourier transforms, Hilbert/analytic-signal helpers, coherence
  and cross-spectral estimates, and a documented wavelet baseline where they
  can share the streaming/buffer model.
- Expand FIR design with equiripple/Remez methods and IIR design with documented
  Butterworth, Chebyshev, elliptic, and Bessel workflows where numerical quality
  can be validated.
- Support batched transforms and real/complex single- and double-precision
  signals without forcing format conversions between pipeline stages.
- Define phase, frequency, endpoint, padding, delay, stability, and initial-state
  conventions for every filter family.

### Probability and statistics

- Broaden continuous and discrete distribution coverage with paired density,
  CDF, survival, log-domain, quantile, and sampling APIs.
- Add parameter estimation by moments or maximum likelihood where the estimate,
  uncertainty, convergence, and identifiability can be reported honestly.
- Add high-quality reproducible random generators, explicit local RNG state,
  stream splitting where supported, and distribution samplers that do not
  mutate hidden global state.
- Add weighted, online, and mergeable descriptive statistics with an explicit
  missing/non-finite-data policy.
- Complete common one-, two-, paired-, and multi-sample tests, Welch methods,
  ANOVA, contingency tests, non-parametric tests with ties, confidence
  intervals, effect sizes, and multiple-testing corrections.
- Add linear and generalised linear regression diagnostics built on the shared
  fitting and decomposition layer.
- Add survival/reliability analysis and multivariate methods such as factor
  analysis and multidimensional scaling when their assumptions, missing-data
  policy, and diagnostics are fully documented.

### Data analysis and time series

- Strengthen PCA and add LDA through the shared eigensystem/SVD implementation.
- Expand clustering with k-means++, hierarchical methods, and documented
  distance/linkage choices; retain density-based methods where appropriate.
- Add nearest-neighbour infrastructure, including a k-d tree or another indexed
  search suitable for low-dimensional exact queries.
- Add a production-quality decision-forest baseline with reproducible training,
  regression/classification metrics, and feature-importance limitations stated.
- Add reusable train/validation splits, cross-validation, preprocessing
  pipelines, model-selection metrics, and explicit missing/categorical-data
  policies so examples do not leak test data into training.
- Extend time-series modelling with statistically sound estimation diagnostics,
  forecast intervals, state-space/Kalman foundations, multivariate models where
  justified, and spectral/SSA workflows integrated with the DSP layer.

### Interchange, inspection, and developer tooling

- Provide invariant, round-trippable `Parse`/`ToString` forms for public scalar,
  vector, matrix, sparse, and model types; locale-aware display must be separate
  from persistence.
- Support common open interchange paths such as delimited text and Matrix
  Market, plus a versioned, endian-defined binary format for large values.
- Serialise fitted models, decompositions where safe, spline/filter state, RNG
  state, and configuration with explicit format versions and compatibility
  tests.
- Provide concise and full matrix/vector summaries, shape/type metadata, and
  optional tabular inspection adapters without introducing a GUI dependency in
  the numerical units.
- Provide an opt-in, non-Turing-complete mathematical expression evaluator for
  scalar, vector, and matrix formulas with explicit symbol binding, resource
  limits, typed errors, and no implicit file or network access.
- Keep I/O, expression evaluation, and IDE/visualisation adapters in optional
  units so core numerical code remains independently usable.

### Portable performance

- Reuse caller buffers and explicit workspaces throughout hot algorithms;
  measure allocations as well as elapsed time.
- Add cache-aware blocked kernels and bounded, deterministic parallel execution
  with a serial fallback on every supported platform. Prevent nested algorithms
  from oversubscribing the machine.
- Add optional compile-time SIMD kernels written within this source tree after
  scalar reference implementations are stable, covering relevant x86 and ARM
  instruction sets. CPU dispatch must never change numerical contracts
  silently.
- Optimise small fixed-size, batched, and streaming workloads separately from
  large dense kernels; a fast large GEMM must not excuse high overhead for
  ordinary short vectors and matrices.
- Establish benchmark baselines for small-call overhead, medium interactive
  workloads, and large throughput workloads, and track material regressions in
  CI or release qualification.
- Audit integer overflow, address-space limits, and allocation failure on Win32
  as well as correctness and throughput on 64-bit platforms.
- Expand the support matrix toward x86-64 and ARM64 on Windows, Linux, and
  macOS, with additional Unix targets where maintainable CI or release testing
  is available.

### 1.8.0 completion gate

- DSP, statistics, fitting, and data-analysis examples share the same real and
  complex containers instead of repeatedly converting between private formats.
- Streaming and large-data APIs have bounded-memory tests and documented state
  behavior.
- Public persistence formats round-trip across supported platforms and reject
  corrupt, incompatible, or unreasonably large input before partial mutation.
- Portable kernels remain the correctness oracle for optional parallel/SIMD
  paths, with cross-path tolerance and determinism tests.
- Release qualification publishes accuracy and performance changes from the
  previous stable release and requires an explanation for material regressions.
- A published capability inventory identifies which common scientific and
  engineering workflows mathlib-fp can complete, their important scale or
  performance limits, and which roadmap items remain open.

## Planned 2.0.0 — Stable native numerical platform

Version 2.0.0 is a quality and API graduation, not an excuse for an arbitrary
rewrite. It ships only when the additive 1.5-1.8 foundations have been used by
the higher-level libraries and their migration path is proven.

### Public API and compatibility boundary

- Make the contiguous real/complex value types and shared result/configuration
  conventions the primary documented API.
- Remove or isolate 1.x APIs only after at least one minor-release deprecation
  period, a documented replacement, and migration examples.
- Keep a clearly named compatibility package when doing so is practical and
  does not compromise the new API's ownership or numerical semantics.
- Standardise naming, indexing, shape rules, exceptions, result statuses,
  tolerance controls, cancellation hooks, progress callbacks, RNG ownership,
  and thread-safety language across domains.
- Publish a complete 1.x-to-2.0 migration guide and machine-checkable public-API
  surface tests.

### 2.0 capability baseline

- Common dense, structured, and sparse real/complex linear-algebra workflows
  must run without an external DLL: construction, arithmetic, decompositions,
  direct and iterative solves, least squares, full/partial eigensystems, and
  condition/rank analysis.
- Single and double precision must be usable end-to-end in their documented
  capability set. Platform-dependent extended precision must never be presented
  as a portable substitute.
- Common numerical-analysis workflows must include stable interpolation and
  fitting, differentiation, integration, equations, ODEs, and
  unconstrained/constrained optimisation with inspectable outcomes.
- The stable optimisation baseline must cover linear, convex quadratic,
  quadratically/cone-constrained, smooth nonlinear, nonlinear least-squares,
  and derivative-free problems. Global, multiobjective, and mixed-integer
  capabilities count only if their bounds and termination claims pass their
  dedicated maturity gates.
- Common scientific workflows must include FFT/convolution/filtering,
  probability/statistics, regression, clustering/dimensionality reduction, and
  time-series foundations.
- Scalar special functions, random generation, parsing/formatting, interchange,
  and model/state persistence must support those workflows without undocumented
  private substitutes.
- Every supported capability must have a portable Pascal implementation. An
  optional faster kernel may supplement but never replace it.
- Remaining gaps against the documented 2.0 capability baseline must be listed
  explicitly by algorithm family, scale, platform, and performance impact. No
  vague completeness claim should replace that evidence.

### Explicit 2.0 non-goals

- mathlib-fp is a numerical library, not a symbolic algebra system, plotting
  framework, IDE, audio-driver stack, or distributed-computing platform.
- GPU, vendor-library, and platform-GUI integrations may be optional adapters;
  none is required for the complete portable capability set.
- No release promises the fastest implementation on every workload or bitwise
  identity across different floating-point precisions and instruction paths.
- A solver family that has not met its correctness, diagnostics, scalability,
  and termination gates remains experimental even if code for it exists.

### Documentation and release readiness

- Every public symbol is indexed and documented; every domain has a quick
  start, selection guide, API reference, error/convergence guide, and runnable
  examples.
- Publish searchable, versioned documentation as a static website and an
  offline archive generated from the same reviewed sources.
- Representative multi-domain applications demonstrate realistic data flow,
  not just isolated one-function calls.
- Documentation CI checks links, public-symbol coverage, code-block syntax, and
  compilation/execution of every runnable example.
- Supported platforms have clean install/build instructions, package metadata,
  CI, checksummed release archives, and a published support matrix. Where the
  ecosystem tooling is reliable, provide Lazarus and `fppkg`-compatible package
  metadata in addition to direct source use.
- Assign compiler/OS/CPU combinations to support tiers: primary targets run the
  full suite on each change; secondary targets receive scheduled compile/test
  qualification with their limitations and last successful run published.
- Numerical validation reports cover reference accuracy, residuals,
  reconstruction, difficult-scale cases, deterministic behavior, and known
  limitations.
- Performance reports include reproducible hardware/compiler settings and
  compare algorithms and allocation behavior fairly.
- An algorithm-provenance and licence review confirms that implementations,
  reference fixtures, examples, and documentation can be distributed under the
  project licence.
- The release includes a maintenance policy for 2.x, deprecation rules, and
  criteria for accepting new domains without weakening the core.

### 2.0.0 completion gate

- A new Free Pascal user can discover, install, learn, and successfully use the
  library from its documentation without reading implementation units first.
- A production user can determine numerical assumptions, complexity,
  allocation, thread-safety, failure, and compatibility behavior before calling
  an API.
- The complete suite passes normal, optimized, runtime-checked, and memory-
  checked configurations on the supported platform matrix.
- Accuracy budgets, performance-regression limits, public-symbol documentation,
  and capability maturity are evaluated mechanically where practical and
  published in the release qualification report.
- At least one release-candidate cycle validates clean installation, the
  migration guide, and representative workflows from release archives rather
  than a developer checkout.
- Compatibility removals have migration coverage, and no known correctness
  defect is being hidden to meet a version target.
- The capability inventory demonstrates that mathlib-fp is a credible native,
  free default for core numerical and scientific Free Pascal workflows.

## Development order

The project grows in three layers. Each layer remains useful on its own.

1. **Reliable scalar and storage kernel** — elementary and special functions,
   probability tails, numeric limits, stable reductions, contiguous data,
   ownership, and shared validation contracts.
2. **Matrix/vector engine** — real and complex dense/sparse arithmetic,
   reusable workspaces, views, decompositions, solvers, and expression-friendly
   APIs implemented in Pascal.
3. **Algorithm breadth** — fitting, interpolation, FFT/convolution, statistics,
   optimisation, differential equations, data analysis, and geometry built on
   the same kernels.

This order is deliberate: adding many entry points before the scalar,
storage, and linear-algebra foundations are dependable would multiply
numerical defects and duplicate private solvers.

## Capability inventory and maturity

The project should maintain a machine-readable capability inventory that also
drives a human-readable status page. Each public algorithm family records:

- unit and public entry points;
- maturity (`experimental`, `stable`, or `deprecated`);
- supported scalar types, shapes, storage formats, and platforms;
- mathematical assumptions and unsupported cases;
- complexity and important memory/workspace behavior;
- accuracy or residual targets and the reference datasets used;
- parallel/SIMD availability and deterministic behavior;
- documentation, example, benchmark, and test locations;
- known limitations, open correctness issues, and planned replacement where
  applicable.

`Experimental` APIs may change and must be visibly labelled in source and
documentation. `Stable` requires the full quality, documentation, portability,
and compatibility contracts. `Deprecated` requires a replacement and migration
path. Only stable capabilities count toward a release's completeness claims.

The inventory should prevent three recurring failure modes: a method name being
mistaken for a production-quality implementation, platform-specific support
being described as universal, and an example-only feature becoming a permanent
API accidentally.

## Quality contract

An operation is not considered complete merely because it returns a value for
a typical example. Depending on the algorithm, it should also have:

- published reference values across small, ordinary, and extreme scales;
- algebraic/property checks and residual or reconstruction tests;
- explicit dimension, finite-value, and mathematical-domain validation;
- scale-aware stopping criteria and a visible non-convergence outcome;
- a precision-appropriate accuracy, residual, or backward-error budget rather
  than one global decimal tolerance;
- defined NaN, Infinity, signed-zero, empty-input, singular, and degenerate
  behavior;
- deterministic seeded behavior for randomized algorithms;
- allocation, aliasing, ownership, reentrancy, and thread-safety contracts;
- cancellation/progress behavior for long-running operations and a guarantee
  that validation failure does not leave a partially modified destination;
- Win32, Win64, and Unix compilation coverage where supported by CI;
- a benchmark for performance-relevant code that does not weaken correctness
  tests.

Reference fixtures may be generated or checked with independent high-precision
tools during development, but the released library and normal test suite must
not require a proprietary product, external numerical DLL, or network service.

## Reliability and verification programme

Reliability is a continuous engineering programme, not a test-count milestone.
Every algorithm family should use the relevant parts of this verification
stack:

1. **Provenance and design review** — record the mathematical source,
   derivation or adaptation, licence compatibility, expected conditioning,
   invariants, and rejected alternatives before or alongside implementation.
2. **Independent references** — compare against published tables,
   high-precision calculations, exact cases, or independently generated
   fixtures across ordinary and adversarial scales.
3. **Structural tests** — check identities, symmetry, monotonicity,
   conservation, reconstruction, residuals, orthogonality, feasibility, and
   other properties that remain meaningful beyond a fixed example.
4. **Metamorphic and randomized tests** — use reproducible seeds to exercise
   transformations such as scaling, permutation, translation, conjugation, and
   equivalent problem formulations.
5. **Robustness tests** — cover invalid dimensions, ragged storage, aliasing,
   exhausted iterations, allocation limits, malformed persistence input,
   callback failures, cancellation, and non-finite values.
6. **Concurrency and memory tests** — run reentrant calls concurrently and use
   runtime checks, heap tracing, leak detection, and bounded-workspace tests.
7. **Cross-target tests** — compare supported compiler versions, optimisation
   levels, CPU widths, instruction paths, operating systems, and floating-point
   modes where they can alter results.
8. **Regression permanence** — every confirmed defect receives the smallest
   useful reproducer and keeps that test after the implementation changes.

Development-only differential tests may use external tools to create fixtures,
but checked-in expected data must record how it was produced and be reviewable
without that tool. Sampled mutation testing or deliberate fault injection
should be used to confirm that important test groups fail when core numerical
logic is corrupted.

Before each stable release, publish a qualification summary containing the
supported target matrix, test configurations, known failures, accuracy results,
benchmark deltas, capability maturity changes, and unresolved high-risk gaps.
No increase in function or test count compensates for a known silent-wrong-
answer defect.

## Documentation and source-comment contract

Documentation is a feature, not release polish. A public operation is complete
only when a caller can discover when and how to use it safely.

- Organise documentation into tutorials, task-oriented how-to guides,
  conceptual explanations/selection guides, and precise API reference. Do not
  force one page to serve all four purposes.
- API documentation states purpose, parameters, return values, mathematical
  definition, indexing/shape conventions, mutation/allocation behavior,
  errors/statuses, edge cases, complexity, workspace, and thread-safety.
- Selection guides compare related algorithms and explain assumptions,
  complexity, accuracy, convergence, and failure modes in plain language.
- Examples start small, remain runnable, and include interpretation of the
  result. Larger cookbook examples join multiple units in realistic workflows.
- Maintain a searchable symbol/algorithm index, glossary, notation guide, and
  “choose an algorithm” paths for readers who know the problem but not the API
  name.
- Source comments explain the algorithm, invariants, numerical safeguards,
  references, and non-obvious design decisions. They should explain *why*, not
  paraphrase each line of Pascal.
- Comment quality is judged by auditability, not comment count. Generated or
  repetitive narration must not obscure the invariant or formula that matters.
- Every important numerical algorithm cites an appropriate paper, textbook, or
  openly accessible technical reference where practical.
- Documentation names known limitations directly; an unsupported case is not
  hidden behind a generic error or omitted from the reference page.
- Error and convergence messages should identify the operation, violated
  condition, and relevant value/shape when safe, then point to the same
  terminology used by the reference documentation.
- Documentation CI checks internal/external links, duplicate/stale public
  symbols, code-block syntax, examples, and release-version references.
- Public documentation and code comments are reviewed alongside implementation
  and tests, and stale examples are treated as defects.

## Capability direction beyond individual releases

The long-term target remains broad numerical coverage, including:

- single/double real and complex scalar, vector, matrix, special-function, and
  random-generation foundations;
- dense, structured, sparse, and matrix-free vector/matrix arithmetic;
- BLAS-like kernels, LU/QR/LQ/Cholesky/LDLT/SVD/eigen decompositions, condition
  estimates, and direct/iterative solvers;
- interpolation, approximation, linear and nonlinear fitting;
- FFT, convolution, correlation, filtering, and spectral analysis;
- descriptive/inferential statistics and probability distributions;
- scalar, linear, quadratic, cone-constrained, nonlinear, derivative-free,
  multiobjective, global, and eventually mixed-integer optimisation;
- numerical and automatic differentiation;
- numerical integration, root finding, ODE solvers, and special functions;
- clustering, regression, classification, time-series, nearest-neighbour, and
  geometry tools;
- open data/model interchange, safe expression evaluation, inspection, and
  developer tooling kept separate from the numerical core.

These capabilities need not map one-to-one to new domains. New units and types
should follow useful API boundaries, and new domains should be introduced only
when the existing foundations and naming model cannot express the capability
cleanly.

## Performance direction

The baseline stays pure Pascal and portable. Performance work proceeds from
algorithm choice and data layout to cache blocking, allocation reduction,
threading, and finally optional compile-time CPU-specific kernels written as
part of this source tree.

A fast path must preserve the portable path's tested semantics. Benchmarks must
include setup and allocation rules, compiler flags, input shapes, tolerances,
and hardware information so that results are reproducible. Small inputs should
not pay avoidable threading or abstraction overhead, and large inputs should be
able to reuse storage and scale across cores where the algorithm permits it.

Performance claims must name the workload and reference point. Release
qualification should track throughput, latency, peak working memory,
allocations, scaling efficiency, and accuracy together; improving one by
silently weakening another is a regression. Parallel defaults must be bounded,
configurable, and safe when the caller also uses threads.

Callers must never need an external DLL to obtain a complete library.
