# Roadmap

> **North star:** mathlib-fp will earn its place as the default mathematics and
> numerical-computing library for Free Pascal: the first library newcomers can
> understand, the library experienced Pascal developers can trust, and the one
> library both groups can keep using as their problems grow.

Being the default is not a slogan or a function-count contest. It means that a
Free Pascal user can find mathlib-fp, download it directly, compile a useful
example within minutes, choose the right algorithm from approachable
documentation, and deploy the result without purchasing a licence, installing
a binary dependency, or calling through a foreign-language wrapper.

The following user promises are permanent release constraints:

1. **Free without qualification.** The complete library is MIT licensed for
   personal, academic, open-source, and commercial use. There are no licence
   keys, paid algorithm tiers, or field-of-use restrictions; modification and
   redistribution are permitted under the MIT terms.
2. **Free Pascal source, not a wrapper.** Every stable capability has a
   readable implementation compiled from Object Pascal source in this
   repository. Generated tables and optional adapters are permitted; a
   precompiled C/C++ core or foreign numerical runtime is never the only
   implementation.
3. **No third-party runtime dependencies.** A normal build needs only a
   supported Free Pascal installation and the standard units shipped with it.
   No DLL, SDK, service, package download, registration step, or network
   connection is required at build time or runtime.
4. **Documentation people can actually use.** Reviewed documentation is
   browsable on the web and usable offline as ordinary text/HTML. PDF may be an
   additional format, but never the only practical route. Tutorials, task
   guides, selection guides, API reference, runnable examples, and source
   comments are part of the product.
5. **Easy before clever.** Common tasks have short, idiomatic APIs, helpful
   validation errors, sensible defaults, and examples that compile unchanged.
   Advanced controls, workspaces, and allocation-free paths remain available
   without burdening a first program.
6. **Useful end to end.** Domains share compatible types, conventions, and
   results so users can complete real scientific, statistical, financial, and
   engineering workflows without writing glue code between mathlib-fp units.

Correct, portable implementations come before architecture-specific
optimisation. Units remain independently usable rather than requiring one
monolithic import, but together they must feel like one coherent library.
Compatibility and documented migration paths protect existing users.

## Product ambition

mathlib-fp is intended to meet four related needs in the Pascal ecosystem.

1. **The dependable standard numerical toolbox for Free Pascal.** It should
   combine accurate algorithms, explicit contracts, predictable releases, easy
   installation, and approachable learning material in one maintained project.
2. **Comprehensive numerical breadth in native Pascal.** The long-term coverage
   target includes dense and sparse linear algebra, interpolation and fitting,
   optimisation, FFT/DSP, statistics, data analysis, integration, nonlinear
   equations, ODEs, finance, geometry, and common engineering calculations.
3. **Productive, scalable numerical programming.** Expression-friendly real
   and complex vector/matrix arithmetic, reusable memory, serious
   decompositions and solvers, and portable performance should support both a
   short teaching program and a large production workload.
4. **Documentation and source that teach as well as serve.** A newcomer should
   be able to choose and use an algorithm safely, while an expert should be
   able to audit its mathematics, safeguards, complexity, ownership, and
   platform behavior from the documentation and code.

Success means completing common workflows, not merely accumulating entry
points. A broad library whose domains do not interoperate, a fast library that
needs an opaque binary, or a correct library that users cannot learn does not
meet the goal. Each minor release must update the capability inventory and
state important remaining gaps honestly.

“One library” does not mean that mathlib-fp must become a symbolic algebra
system, plotting framework, GUI toolkit, or clone of every specialist package.
It means Free Pascal users should not need a second general-purpose numerical
library to compensate for missing foundations, inaccessible documentation,
licensing restrictions, or incompatible data types.

## What “preferred” means for this project

The project should not call itself complete merely because it has many
functions. It must earn preference through the combination of:

- **time to first correct result** — a clean source archive, a one-screen
  program, and platform-specific instructions that work without guesswork;
- **mathematical trust** — published accuracy expectations, independent
  references, visible convergence outcomes, and regression tests for every
  corrected defect;
- **explainability** — clear selection guides, public contracts, algorithm
  references, and source comments that explain numerical decisions;
- **end-to-end usefulness** — compatible containers and result types that let
  callers finish realistic workflows without private conversions or solvers;
- **API coherence** — consistent naming, indexing, shape, ownership, error,
  tolerance, and result conventions across domains;
- **scalability** — algorithms and storage appropriate to small interactive
  problems and large dense, sparse, batched, streaming, or parallel workloads;
- **stability** — deliberate versioning, migration paths, reproducible results,
  and a public maturity level for each capability;
- **independence** — complete portable Pascal paths with no mandatory service,
  binary component, proprietary tool, package manager, or network connection.

Claims about accuracy, performance, breadth, ease of use, or readiness must be
supported by published evidence. Missing and experimental capabilities should
be easier to find than marketing language.

When priorities compete, use this order:

1. correct a silent wrong answer, unsafe contract, or portability defect;
2. remove a blocker from a documented end-to-end user workflow;
3. make an existing stable capability easier to find, learn, or use;
4. complete shared scalar, container, solver, and result foundations;
5. improve measured performance without weakening portability or clarity;
6. add isolated specialist functions.

This order keeps “more useful” tied to user outcomes rather than raw API size.

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

| Release | Numerical outcome | User-facing outcome |
| --- | --- | --- |
| 1.3.0 | Complex scalars and allocation-light real/complex vector kernels | Documented native complex/vector workflows with compatible FFT paths |
| 1.4.0 | Ergonomic and consistent 2-D/3-D geometry vector arithmetic | Natural operators, runnable examples, and explicit edge-case behavior |
| 1.5.0 | Typed contiguous scalar, vector, and dense matrix foundation | Five-minute install path, searchable documentation baseline, and concise solve examples |
| 1.6.0 | Dependable typed dense decompositions and direct solvers | “Choose a dense solver” guidance, reusable factors, and inspectable diagnostics |
| 1.7.0 | Interpolation, fitting, advanced numerics, and optimisation | End-to-end modelling recipes with convergence and diagnostic guidance |
| 1.8.0 | Applied numerics, interchange, tooling, and performance maturity | Portable data workflows, reproducible benchmarks, and mature package/distribution paths |
| 2.0.0 | Unified stable API, complete migration, and documented capability baseline | A proven free, native, dependency-free default for core Free Pascal numerical work |

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

## Continuous adoption track

Installation, documentation, and usability are release work, not a 2.0 cleanup
phase. The following track starts now and applies to every future stable
release alongside its numerical scope.

### Distribution and installation

- Publish source archives and checksums on GitHub with direct links from the
  README. Downloading a release must not require an account, custom downloader,
  package manager, or JavaScript-only file browser.
- Keep direct source use first-class: adding `src/` to the unit path is enough
  to compile a basic program, with no configure step or generated source.
- Keep the Lazarus package tested and versioned with the library. Direct source
  use remains canonical. Package-manager metadata is out of scope unless a
  future tool demonstrates active maintenance, meaningful adoption, and a
  reproducible installation workflow.
- Test release archives after clean extraction on supported Windows and Unix
  targets, using only a supported FPC installation and with network access
  unavailable.
- Run a dependency audit before release. Stable numerical units must not load
  third-party DLLs, invoke external programs, contact services, or require
  optional packages transitively.
- Document supported compiler, OS, CPU, and precision combinations in one
  obvious support matrix rather than scattering qualifications across guides.

### Documentation and discoverability

- Establish searchable, versioned, static web documentation during the 1.5
  cycle and preserve the same reviewed content in the repository for offline
  use. HTML and PDF builds may be generated from it.
- Give every domain a landing page with a 60-second example, common tasks,
  “choose an algorithm” guidance, links to complete API contracts, and clearly
  labelled maturity and limitations.
- Maintain both a symbol index and a problem-oriented algorithm index. A user
  who knows “least-squares fit” but not the Pascal identifier should still find
  the right entry point.
- Compile and run every published example in CI. Code copied from the current
  documentation must work with the corresponding release archive.
- Add realistic cookbook workflows that cross domain boundaries and interpret
  their results. Examples should demonstrate safe choices and failure handling,
  not only happy-path syntax.
- Publish focused migration notes for widely used Pascal numerical APIs when
  users request them and a responsible semantic mapping exists. State
  differences instead of promising drop-in compatibility.

### API and first-use experience

- Common tasks should require only the relevant `uses` entry, data, and
  operation. Stable numerical code must not require global registration,
  framework startup, a GUI component, or hidden mutable singleton state.
- Provide task-level entry points with consistent names and defaults while
  preserving lower-level configuration and reusable-workspace APIs for expert
  use.
- Use shared scalar, vector, matrix, status, and option types across domains.
  Public examples must not contain glue conversions that the library itself
  should provide.
- Make errors actionable: identify the operation, invalid parameter or shape,
  expected condition, and terminology used by the relevant guide.
- Document allocation and copying without forcing beginners to manage
  workspaces. Show the simple API first and the repeated/high-performance form
  beside it where the distinction matters.
- Review naming and overloads through small runnable programs. If an ordinary
  workflow reads awkwardly in Pascal, API design is not complete.

### Adoption gate for every stable release

- A new user can go from the release page to a correctly running documented
  example in no more than five minutes on a primary supported platform.
- The quick start is validated from the packaged release, not a maintainer's
  configured checkout.
- Every new stable public symbol has an API contract, and every new algorithm
  family has selection guidance plus at least one runnable example.
- Representative workflows build and run with no network, foreign binary,
  licence key, or third-party runtime package.
- Documentation search, links, code blocks, public-symbol coverage, and example
  execution pass automated checks.
- Release notes state user-visible additions, migration concerns, maturity
  changes, known limitations, and the exact evidence behind accuracy or
  performance claims.

## Previous release: 1.4.0 — Geometry vector arithmetic

Released on 2026-07-25, version 1.4.0 delivers a small but complete improvement
to GeometryLib's fixed-size value types. It responds directly to the first
external feature request received by the project: make ordinary vector
arithmetic expressible without reconstructing a vector from its individual
coordinates.

### Completed 1.4.0 scope

- `TVector2D` and `TVector3D` provide vector addition, subtraction, unary
  negation, scalar multiplication in both operand orders, and vector/scalar
  division.
- Natural operators such as `V1 + V2` keep the 2-D and 3-D APIs symmetrical
  while genuinely dimensional operations remain distinct.
- Zero-scalar division, signed zero, NaN, Infinity, overflow, and alias/value
  semantics have explicit documentation and tests.
- The GeometryLib reference and runnable geometry example cover the complete
  operator set, a compact Theodorus spiral, symmetric 3-D arithmetic, and
  extreme-scale normalization.
- Public-API smoke checks and focused properties cover identity, inverse,
  distributivity, scaling, dot linearity, and agreement between 2-D and 3-D
  forms.
- The existing 2-D and 3-D magnitude and normalization methods are scale-safe
  for finite tiny and large components, with explicit exact-zero and
  non-finite normalization behavior.
- Fixed-size vector arithmetic is documented as O(1), allocation-free,
  reentrant, and thread-safe when callers do not concurrently mutate the same
  record storage.

Point/vector translation operators are not part of this release. They should
be added only after the distinctions between points, displacement vectors, and
coordinate transforms have a documented, consistent design.

### 1.4.0 completion evidence

- The complete operator set compiles on every supported Free Pascal target.
- 2-D and 3-D behavior is consistent and has edge-case and property tests.
- Magnitude and normalization avoid premature intermediate overflow and
  underflow; normalization also works when a finite vector's magnitude exceeds
  the representable `Double` range.
- The motivating example uses `Radius := Radius + Step` without
  coordinate-by-coordinate reconstruction.
- Reference documentation, code comments, example output, changelog, package
  metadata, and release notes describe the delivered API and behavior.
- Existing GeometryLib callers remain source-compatible.

See the [1.4.0 release notes](RELEASE_NOTES_1.4.0.md) for the delivered API and
validation summary.

## Previous release: 1.3.0

Released on 2026-07-23, version 1.3.0 established the complex-number and vector
foundation required by the next generation of algebra and signal-processing
features. It preserves the existing matrix-as-vector API: an `IMatrix` with
one row or one column remains an `IVector` and keeps its `DotProduct`,
`CrossProduct`, and `Normalize` methods.

The foundation adds a complementary, allocation-light array API rather than
replacing matrices:

- `MathBase.Complex` supplies the scalar `TComplex` type, scale-safe division,
  signed-zero-aware principal functions (including inverse trigonometric and
  hyperbolic functions), and `TComplexArray`;
- `AlgebraLib.VectorKernels` supplies real and complex array-vector kernels
  (compensated reductions, elementwise operations, stable norms, scaling,
  AXPY-style combination, normalization, and reusable destination buffers);
- `AlgebraLib.Vectors` remains the compatibility-oriented entry unit and
  re-exports the array-vector types and kernel facade;
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

## Earlier release: 1.2.3

Version 1.2.3 was a correctness and robustness release. It did not add a new
domain. It concentrated on the operations already exposed:

- improved special-function accuracy, convergence handling, and tail behavior;
- removed overflow, underflow, and cancellation from representable results;
- corrected formulas whose happy-path tests masked mathematical defects;
- expanded reference-value, identity, residual, property, and extreme-scale
  tests;
- kept public signatures source-compatible wherever correctness permitted.

## Current release: 1.5.0 — Typed contiguous numerical foundation

Released on 2026-07-26, version 1.5.0 establishes the scalar, storage, and kernel layers on which the
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

### 1.5.0 qualification evidence

- Real and complex arithmetic share the shape, retained-owner view, explicit
  clone, finite-input, and `EDenseMatrixError` model documented in the
  [typed dense design note](design/typed-dense-1.5.md).
- Dense multiplication has reference, overlapping-alias, odd-shape,
  empty-shape, mixed-extreme-scale, and deterministic odd-shape benchmark
  coverage in `TestDenseMatrices` and `BenchmarkRunner`.
- `Solve(A, B)` always uses reusable pivoted-LU factorisation and triangular
  solves. Real and complex LU/Cholesky residual tests cover vectors and
  multiple right-hand sides.
- Allocating functions keep examples concise; every common kernel has an
  exact-shape `Into` form and factor objects support repeated solves.
- Single- and double-precision real/complex paths have the documented matching
  operation set and precision-appropriate test budgets.
- Shape, element-count, alignment-padding, and byte-count arithmetic is checked
  before allocation with native-size types and has overflow tests. CI retains
  both 32- and 64-bit qualification.
- The [capability inventory](CAPABILITIES.md) publishes stable scalar/kernel
  coverage and identifies Bessel, elliptic, exponential-integral, and typed
  sparse families as unsupported rather than implying support.
- No compatibility API was removed or deprecated. The
  [migration guide](MIGRATING_TO_TYPED_DENSE.md) names every array, vector,
  `IMatrix`, view, and clone copy/alias cost.

## Next release: 1.6.0 — Dependable typed dense linear algebra

Version 1.6.0 completes the first high-trust dense workflow on the 1.5.0
storage and kernel foundation. A Free Pascal user should be able to solve
ordinary square, least-squares, minimum-norm, and symmetric/Hermitian
eigenproblems through one documented native API without forming an inverse,
converting through the compatibility matrix type, or installing an external
binary.

The release deliberately values a small maintainable surface over a catalogue
of algorithm names. Every stable decomposition becomes a permanent
real/complex, single/double, documentation, test, and support commitment.
Sparse storage, matrix-free iteration, and advanced spectral families are
therefore deferred rather than being attached to 1.6 as optional scope.

### Release boundary and implementation order

- Publish a focused 1.6 design record before adding public types. It fixes
  factor ownership, source mutation, output shapes, compact forms,
  pivots/permutations, sign/phase conventions, tolerances, rank decisions,
  diagnostics, allocation, errors, and compatibility with the 1.5 contracts.
- Deliver reviewable vertical slices in this order: shared triangular and
  Householder kernels; QR and least squares; column-pivoted QR and rank
  diagnostics; SVD and minimum-norm solves; symmetric/Hermitian eigensystems;
  compatibility audit, examples, and qualification.
- Keep public additions limited to decomposition factors, result information,
  and solve options that are needed by those workflows. Reuse internal generic
  kernels and thin scalar-specific aliases instead of maintaining four
  unrelated implementations.
- Keep `Single`, `Double`, single-complex, and double-complex operation sets
  symmetrical wherever the mathematics is the same. A restriction is allowed
  only when it is mathematically inherent and is visible in the capability
  inventory and selection guide.
- Prefer one well-understood portable algorithm per promised operation.
  Additional variants, destructive expert paths, public workspaces, automatic
  dispatch, and tuning controls require measured user need and must not be
  added merely because another library exposes them.
- Land tests, documentation, migration notes, and a realistic example with
  each slice. Do not defer numerical contracts or qualification to the end of
  the release.

### Ownership, result, and error contracts

- A factor owns an immutable snapshot or retained private factor storage.
  Mutating the source matrix after factorisation cannot change an existing
  factor, and 1.6 does not add mutable factor update/downdate behavior.
- Caller matrices and right-hand sides are not overwritten. Internal workspace
  allocation and copies are documented; an allocation-avoiding public form is
  added only when repeated-use benchmarks justify its maintenance cost.
- Every decomposition documents accepted shapes and exposed output shapes,
  transpose/conjugate conventions, pivot or permutation meaning,
  normalization, sign/phase freedoms, ordering, finite-input policy,
  additional storage, and thread safety. Compact/economy outputs are the
  baseline; full orthogonal or unitary completions require demonstrated need.
- Tolerances are caller supplied or derived from dimension, scale, and scalar
  precision. Singularity, definiteness, numerical rank, and
  ill-conditioning do not share one unexplained epsilon.
- Invalid shapes, non-finite input, allocation overflow, and invalid options
  fail before caller-owned output is modified. Rank-deficient problems return
  useful factors or solve diagnostics where the chosen method supports them;
  they are not disguised as full-rank success.
- Convenience solves may allocate and factor once. Repeated solves use an
  explicit reusable factor so the API never hides repeated O(n³) work.

### Required decompositions

- Requalify the 1.5 pivoted LU and Cholesky factors without breaking their
  established solve and ownership behavior.
- Provide reusable lower/upper, unit/non-unit triangular solves for ordinary,
  transposed, and conjugate-transposed systems with one or many right-hand
  sides.
- Provide Householder QR for tall and square matrices and a
  column-pivoted Householder QR path for rank revelation. Classical
  Gram-Schmidt is not the stable typed implementation.
- Provide SVD for tall, square, and wide real/complex matrices with explicitly
  documented compact shapes and singular-value ordering.
- Provide full symmetric real and Hermitian complex eigensystems with
  documented eigenvalue ordering, eigenvector phase/sign freedom, convergence,
  and repeated/clustered-eigenvalue behavior.

### Required solves and diagnostics

- Preserve the concise square `Solve(A, B)` behavior from 1.5 and expose
  deliberate factor selection for general and positive-definite systems.
- Provide overdetermined least-squares solves through Householder QR,
  rank-revealing solves through column-pivoted QR, and rank-deficient or
  underdetermined minimum-norm solves through SVD.
- Support vector and multiple right-hand sides and factor reuse in every solve
  path where factor reuse is mathematically meaningful.
- Report numerical rank, scale-aware residual or backward error, pivot/rank
  decisions, and a decomposition-appropriate condition indicator. Do not form
  an inverse merely to estimate condition or solve a system.
- Publish a concise method-selection table. Defaults favor predictable
  numerical behavior; callers choose a more expensive SVD path explicitly
  when rank deficiency or minimum norm matters.

### Compatibility and adoption

- Keep `IMatrix`, `TMatrixKit`, and their existing LU, QR, SVD, Cholesky, and
  eigen entry points source-compatible and clearly labelled as the
  compatibility API.
- Audit compatibility results against the typed implementations, but route an
  old method through new code only when shape, ordering, tolerance, error, and
  ownership equivalence is tested. Avoid a release-wide rewrite of legacy
  algorithms merely to remove duplication.
- Keep migration opt-in. Every conversion names its copy, precision, and
  real/complex behavior; no dense typed factor silently converts through
  nested `Double` storage.
- Provide the stable shared QR/SVD/eigensystem foundation that 1.7 fitting and
  data-analysis work can adopt. Migration of higher-level algorithms belongs
  with those later feature changes and their domain-specific equivalence tests.
- Publish a “choose a dense solver” guide and focused migration recipes from
  compatibility inverse/QR/SVD/eigen workflows. Examples solve and interpret
  realistic systems rather than printing factors without a decision context.

### Validation and maintenance evidence

- Test factor reconstruction, orthogonality/unitarity, pivot/permutation
  identities, residual and backward error, rank decisions, singular-value
  ordering, and eigenpair residuals across square, tall, wide, empty,
  singleton, and multiple-right-hand-side shapes.
- Include rank-deficient, nearly rank-deficient, clustered/repeated-spectrum,
  badly scaled, singular, indefinite, and mixed-extreme-scale fixtures.
  Non-finite input, allocation overflow, aliasing, and unchanged caller input
  after failure remain explicit tests.
- Keep independent high-precision or trusted reference fixtures in the
  repository without adding a runtime dependency. Randomized or metamorphic
  tests use fixed seeds and preserve discovered failures as deterministic
  fixtures.
- Define algorithm- and precision-specific acceptance budgets before claiming
  support. Qualification reports normalized reconstruction, residual, and
  orthogonality measures rather than one decimal tolerance for every problem.
- Benchmark representative shapes and scalar paths, allocating convenience
  calls, and factor reuse. Track checksums, accuracy, allocations, and peak
  working storage; 1.6 does not require parallel, SIMD, or external BLAS speed.
- Retain Linux, Win64, and Win32 CI coverage. Every stable decomposition and
  solve family is exercised through public API tests on each supported target,
  with longer difficult-matrix suites run in release qualification where
  necessary.

### Explicit 1.6.0 non-goals

The following capabilities are valuable, but combining them with the first
typed dense decomposition release would multiply public types, algorithm
variants, convergence states, and platform tests. They require separately
reviewed future milestones:

- typed sparse or packed/structured storage families and sparse direct solves;
- pivoted LDLT and other structure-specific factor families that do not unlock
  the required least-squares, minimum-norm, or eigensystem workflows;
- CG, MINRES, GMRES, BiCGSTAB, LSQR, preconditioners, linear-operator
  callbacks, matrix-free solves, and partial eigensolvers;
- general nonsymmetric, generalized, or polynomial eigensystems, public Schur
  forms/reordering, and matrix logarithm or square-root functions;
- low-rank factor updates/downdates, mutable factors, destructive
  factorisation, and a general public workspace framework;
- automatic algorithm selection based on undocumented thresholds, parallel or
  SIMD decomposition kernels, GPU support, and external BLAS/LAPACK bindings;
  and
- removal of compatibility APIs or wholesale migration of unrelated
  higher-level domains.

Deferral means unsupported in the typed 1.6 API, not silently approximated by a
weaker algorithm. The capability inventory must say so. Sparse and iterative
linear algebra should receive its own milestone after the dense API has been
used by real fitting and data-analysis workflows. Its version number is
deliberately not fixed here; it should be planned from demonstrated needs
rather than inserted into an already full release.

### 1.6.0 completion gate

- The 1.6 design record fixes factor ownership, output shapes, scalar parity,
  pivots, conventions, tolerances, rank/error behavior, allocation, and
  compatibility before the associated APIs are declared stable.
- LU, Cholesky, triangular solves, Householder QR, column-pivoted QR, SVD,
  and symmetric/Hermitian eigensystems pass their documented single/double
  real/complex contracts as mathematically applicable.
- Square, least-squares, rank-revealing, minimum-norm, and
  positive-definite solves support multiple right-hand sides, reusable factors,
  and inspectable diagnostics without forming an inverse.
- Algorithm-specific qualification includes independent references,
  precision-appropriate budgets, adversarial fixtures, deterministic
  allocation/performance evidence, and Linux/Win64/Win32 public-API CI.
- The solver-selection guide, realistic examples, capability inventories,
  migration guidance, package metadata, release notes, and qualification
  report match the shipped API and explicitly list the deferred families.
- No compatibility API is removed, no existing typed 1.5 contract changes
  silently, and the maintained public surface remains small enough that every
  stable algorithm has an owner-independent test and documentation path.

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
  and a documented conic model only after the LP/QP scaling and solver
  foundations are proven.
- Add smooth constrained nonlinear methods, nonsmooth/derivative-free
  alternatives, multiobjective outcomes, and reproducible global/multistart
  strategies. Local and global claims must be distinguished explicitly.
- Support dense constraints, variable/objective scaling, warm starts,
  progress/cancellation callbacks, and reusable solver state. Sparse
  constraints follow only after a separate sparse-storage and solver
  milestone.
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
  bounded/unbounded, small/large, stiff/non-stiff, and exact/noisy problems.

## Planned 1.8.0 — Applied numerics, tooling, and performance maturity

Version 1.8.0 broadens the workflows most visible to scientists and engineers
and hardens the existing stack for larger data. A focused sparse/iterative
milestone may be scheduled separately rather than being folded into this
already broad applied-numerics release.

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
  vector, matrix, and model types; include sparse types only if their separate
  milestone has already established a stable storage contract. Locale-aware
  display must be separate from persistence.
- Support common open interchange paths such as delimited text and Matrix
  Market, plus a versioned, endian-defined binary format for large values.
- Serialise fitted models, decompositions where safe, spline/filter state, RNG
  state, and configuration with explicit format versions and compatibility
  tests.
- Provide concise and full matrix/vector summaries plus shape/type metadata
  without introducing a GUI dependency in the numerical units.
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
rewrite. It ships only when the additive 1.x foundations have been used by
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

- This section completes and verifies the continuous adoption track; it does
  not defer documentation, packaging, or first-use work until 2.0.
- Every public symbol is indexed and documented; every domain has a quick
  start, selection guide, API reference, error/convergence guide, and runnable
  examples.
- Publish searchable, versioned documentation as a static website and an
  offline archive generated from the same reviewed sources.
- Representative multi-domain applications demonstrate realistic data flow,
  not just isolated one-function calls.
- Documentation CI checks links, public-symbol coverage, code-block syntax, and
  compilation/execution of every runnable example.
- Supported platforms have clean install/build instructions, CI, checksummed
  release archives, and a published support matrix. Provide a tested Lazarus
  package in addition to direct source use. Package-manager integration is not
  a release requirement and may be considered only for demonstrably maintained
  tooling.
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
