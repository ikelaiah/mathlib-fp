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

### Deliberate design boundaries

These boundaries are positive, reviewable constraints on the project's own
design choices, not criticism of other projects:

- **No mandatory foreign-language numerical core.** Every stable capability
  has a readable Object Pascal implementation in this repository; an optional
  adapter may supplement but never replace it.
- **No proprietary or paid algorithm tier in the stable library.** The MIT
  licensed library contains no licence-key or paid algorithm layer.
- **No external BLAS/LAPACK runtime as the sole implementation.** An external
  library may be an optional acceleration path only where a complete portable
  Pascal implementation also exists.
- **No hidden global mutable numerical state in ordinary stable APIs.** Stable
  numerical entry points must not depend on hidden mutable singleton state.
- **No terse historical naming where a clearer stable Pascal API can be
  offered.** Where a legacy name survives, it does so as an explicitly labelled
  compatibility path with a documented replacement.
- **Portable Pascal remains sufficient for complete functionality.** No
  capability may require an architecture-specific kernel, service, or foreign
  runtime to work at all.

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
meet the goal. Each stable release must update the capability inventory and
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
- 2.0.0 is the point at which the coherent replacement API becomes the default.
  A previously announced breaking change may be completed only after its
  documented minor-release runway; a breaking change is not required merely to
  justify the major version.

A 1.3.x maintenance release may therefore occur before 1.4.0, but GeometryLib
vector arithmetic is new public API and belongs to 1.4.0.

## Release sequence at a glance

| Release | Numerical outcome | User-facing outcome |
| --- | --- | --- |
| 1.3.0 | Complex scalars and allocation-light real/complex vector kernels | Documented native complex/vector workflows with compatible FFT paths |
| 1.4.0 | Ergonomic and consistent 2-D/3-D geometry vector arithmetic | Natural operators, runnable examples, and explicit edge-case behaviour |
| 1.5.0 | Typed contiguous scalar, vector, and dense matrix foundation | Five-minute install path, searchable documentation baseline, and concise solve examples |
| 1.6.0 | Dependable typed dense decompositions and direct solvers | “Choose a dense solver” guidance, reusable factors, and inspectable diagnostics |
| 1.7.0 | Interpolation, fitting, advanced numerics, and optimisation | End-to-end modelling recipes with convergence and diagnostic guidance |
| 1.8.0 | Applied numerics, interchange, tooling, and performance maturity | Portable data workflows, reproducible benchmarks, and mature package/distribution paths |
| 1.9.0 | Typed structured/sparse linear algebra and matrix-free iterative solvers | Large-problem workflows with bounded storage, verified contracts, and a 2.0 migration preview |
| 1.9.1 | Stabilisation and documentation delivery | A dependable 1.9 release, versioned web/offline documentation, and verified first-use paths |
| 1.9.2 | Beginner learning path | Short task-oriented recipes and a clear double-real path before advanced controls |
| 1.9.3 | Complete 2.0 API decision | A curated all-domain primary surface with every compatibility decision resolved |
| 1.9.4 | Numerical trust closure | Independent references, adversarial cases, and published accuracy/failure budgets |
| 1.9.5 | Predictable performance | Reproducible time/allocation baselines and evidence-led internal optimisation |
| 1.9.6 | Portability and distribution | Clean archives, offline use, and a current evidence-backed support matrix |
| 1.9.7 | Migration and compatibility rehearsal | Complete 1.x mappings and a tested compatibility-package plan |
| 1.9.8 | Representative workflow qualification | Multi-domain applications with reproducible clean-archive workflow evidence |
| 1.9.9 | Final 1.9.x convergence handoff | Closed 1.10.0 capability manifest, complete evidence, and no unresolved API decisions |
| 1.10.0 | Additive API completion and final 2.0 freeze | Approved missing conveniences, including 2-D vector rotation, followed by release-candidate qualification and soak |
| 2.0.0 | Unified stable API, complete migration, and documented capability baseline | A proven free, native, dependency-free default for core Free Pascal numerical work |
| 2.1 | Special Functions II | Bessel, elliptic, exponential-integral, and a bounded hypergeometric baseline with cited budgets |
| 2.2 | Nonsymmetric and generalised spectral algebra | Hessenberg/Schur foundation with ordering, convergence, residual, and failure contracts |
| 2.3 | Stiff and implicit ODEs | A documented stiff-solver baseline with Jacobian, tolerance, and convergence diagnostics |
| 2.4 | Sparse Direct II | Fill-reducing ordering, symbolic/numeric separation, and a documented fill/memory model |

Versions 2.1 through 2.4 are the committed near-term capability gates; see the
candidate capability lanes in the post-2.0 capability programme for longer-term
possible directions that are not version promises.

## Implementation discipline

This roadmap describes a sequence of release outcomes, not one implementation
task. Work should proceed one release and one reviewable change at a time.

- Only the release marked **Next release** is the active release target.
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
- Propose a future `Coming from ALGLIB-Pascal` migration note alongside the
  existing NumLib and LMath/DMath mappings. It must explain conceptual
  mappings, state ownership/type/default differences, and never promise
  drop-in compatibility unless equivalence is actually proven.

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

## Completed releases

Releases from 1.2.0 through 1.9.9 are shipped and remain source-compatible
through the current line. The table records the primary numerical and
user-facing outcome of each release; the detailed scope, completion gate, and
qualification evidence for each release lives in its own release-specific
documents rather than in this roadmap.

| Version | Release date | Outcome | Release notes |
| ------- | ------------ | ------- | ------------- |
| 1.2.0 | 2026-07-18 | Initial shared-type release: numeric types, real symmetric eigendecomposition, matrix powers, and seeded random/bootstrap paths | [notes](RELEASE_NOTES_1.2.0.md) |
| 1.2.1 | 2026-07-18 | Canonical terminology guide, public API naming inventory, and aligned README/FAQ/guides | [notes](RELEASE_NOTES_1.2.1.md) |
| 1.2.2 | 2026-07-18 | MathBase and NumericsLib walkthroughs; a runnable program and index for every documented domain | [notes](RELEASE_NOTES_1.2.2.md) |
| 1.2.3 | 2026-07-21 | Correctness and robustness release: special-function accuracy, convergence and tail behaviour, and overflow/underflow/cancellation removal | [notes](RELEASE_NOTES_1.2.3.md) |
| 1.3.0 | 2026-07-23 | Complex-number and vector foundation (`TComplex`, real/complex vector kernels) for later algebra and signal processing | [notes](RELEASE_NOTES_1.3.0.md) |
| 1.4.0 | 2026-07-25 | GeometryLib fixed-size vector arithmetic through natural operators | [notes](RELEASE_NOTES_1.4.0.md) |
| 1.5.0 | 2026-07-26 | Typed contiguous real/complex scalar, vector, and dense-matrix foundation with a direct `Solve` path | [notes](RELEASE_NOTES_1.5.0.md) |
| 1.6.0 | 2026-07-27 | Dependable typed dense linear algebra: LU/QR/CPQR/SVD and symmetric/Hermitian eigensystems with direct solves | [notes](RELEASE_NOTES_1.6.0.md) |
| 1.7.0 | 2026-07-30 | Numerical modelling and optimisation: interpolation, fitting, integration, equations, ODEs, differentiation, and optimisation | [notes](RELEASE_NOTES_1.7.0.md) |
| 1.8.0 | 2026-07-30 | Applied numerics, tooling, and performance maturity: FFT/DSP, probability/statistics, data analysis/time series, and interchange | [notes](RELEASE_NOTES_1.8.0.md) |
| 1.9.0 | 2026-08-01 | Scalable linear algebra and API convergence: typed structured/sparse storage, operators, iterative solvers, preconditioning, and 2.0 conventions | [notes](RELEASE_NOTES_1.9.0.md) |
| 1.9.1 | 2026-08-02 | Stabilisation and documentation delivery: 1.9.0 triage and versioned web/offline documentation | [notes](RELEASE_NOTES_1.9.1.md) |
| 1.9.2 | 2026-08-02 | Beginner learning path: runnable examples, common tasks, and choose-an-algorithm guidance for every domain | [notes](RELEASE_NOTES_1.9.2.md) |
| 1.9.3 | 2026-08-04 | Complete 2.0 API decision: all-domain classification and resolved compatibility decisions | [notes](RELEASE_NOTES_1.9.3.md) |
| 1.9.4 | 2026-08-10 | Numerical trust closure: independent references, adversarial cases, and published accuracy/failure budgets | [notes](RELEASE_NOTES_1.9.4.md) |
| 1.9.5 | 2026-08-11 | Predictable performance: reproducible time/allocation baselines and evidence-led optimisation | [notes](RELEASE_NOTES_1.9.5.md) |
| 1.9.6 | 2026-08-11 | Portability and distribution: clean archives, offline use, and an evidence-backed support matrix | [notes](RELEASE_NOTES_1.9.6.md) |
| 1.9.7 | 2026-08-12 | Migration and compatibility rehearsal: complete 1.x mappings and a tested compatibility plan | [notes](RELEASE_NOTES_1.9.7.md) |
| 1.9.8 | 2026-08-16 | Representative workflow qualification: multi-domain applications with clean-archive workflow evidence | [notes](RELEASE_NOTES_1.9.8.md) |
| 1.9.9 | 2026-08-17 | Final 1.9.x convergence handoff: closed 1.10.0 capability manifest and complete evidence | [notes](RELEASE_NOTES_1.9.9.md) |
| 1.10.0 | 2026-08-19 | Additive API completion and final 2.0 freeze: `TVector2D.Rotate`, no-deprecation closure, and frozen 2.0 candidate | [notes](RELEASE_NOTES_1.10.0.md) |

Detailed historical evidence for each release remains in the corresponding
`RELEASE_NOTES_<version>.md`, `PR_NOTES_<version>.md`, `QUALIFICATION_<version>.md`,
and release-evidence documents. These remain normative release-handoff inputs
and may be physically archived only after the 2.0 handoff; they are not moved
or archived during normal maintenance.

## 1.9.x convergence contract

The 1.9.x line is the adoption, compatibility, and trust runway between the
large additive 1.9.0 milestone and the 2.0 stability commitment. Its purpose is
to prove and curate the capabilities already shipped, not to consume patch
numbers with unrelated algorithm families.

- A 1.9.x release may correct defects, strengthen validation and numerical
  safeguards, improve a non-public implementation, add tests/fixtures,
  publish documentation and examples, improve tooling, or qualify an existing
  path on another target without changing its public contract.
- A new public algorithm family, type, or convenience surface that applications
  are expected to depend on is a minor-version capability and belongs in
  1.10.0 rather than being hidden inside a 1.9.x patch.
- The 1.9 API snapshot remains the compatibility baseline. Any interface change
  requires a documented correctness or compatibility reason, an exact snapshot
  diff, migration impact, and the same declaration/documentation checks as a
  minor release.
- Later entries below are planning gates. Only the release marked **Next
  release** is active; work is not pulled forward merely because it is
  convenient to bundle with another fix.
- Passing a gate requires evidence from a clean release archive. A count of
  functions, tests, pages, or examples does not substitute for the stated user
  and numerical outcome.

## Previous release: 1.10.0

Version 1.10.0 is the backward-compatible minor release that implemented the
closed 1.9.9 convergence manifest and froze the code, API, documentation,
support claims, migration material, qualification procedure, and distribution
artifacts promoted to 2.0. It added exactly one public declaration,
`TVector2D.Rotate(const Angle: Double): TVector2D` in `GeometryLib.Geometry`
— an allocation-free value rotation by radians (counter-clockwise for positive
angles) that leaves the source unmodified, returns the exact zero vector for
the zero vector, and conserves magnitude within a stated tolerance. The
deprecation decision closed as **no-deprecation**: 1.10.0 marked no alias or
compatibility declaration as deprecated, removed, or moved, and retained full
1.x source compatibility. The historical 1.9 public-API baseline
([`public-api-1.9.json`](public-api-1.9.json)) was kept immutable, and the
addition was captured in a new current snapshot
([`public-api-1.10.0.json`](public-api-1.10.0.json)) with an explicit
1.9.9-to-1.10.0 diff rather than a mutated historical baseline. Version 1.9.9,
the final 1.9.x convergence handoff, had closed that manifest in advance. See
the completed-releases table above and the
[1.10.0 release notes](RELEASE_NOTES_1.10.0.md) and
[qualification record](QUALIFICATION_1.10.0.md).

## Next release: 2.0.0 — Stable native numerical platform

Version 2.0.0 is the next active capability gate and the current release
target. It is a quality and API graduation, not an excuse for an arbitrary
rewrite: it ships only when the additive 1.x foundations have been used by the
higher-level libraries, the migration path is proven, and the 1.x convergence
gates through 1.10.0 are complete. Because 1.10.0 froze the promoted 2.0
candidate, the only remaining work for 2.0.0 is version and release metadata
and promotion of the qualified candidate, not a new algorithm or public API
design. The detailed 2.0 plan — public-API and compatibility boundary,
capability baseline, non-goals, documentation readiness, and completion gate —
is documented in the `2.0.0` section below.

## 2.0.0 — Stable native numerical platform

Version 2.0.0 is a quality and API graduation, not an excuse for an arbitrary
rewrite. It ships only when the additive 1.x foundations have been used by
the higher-level libraries, their migration path is proven, and the 1.x
convergence gates through 1.10.0 are complete. Version 2.0.0 does not need a
breaking change to justify its number: the major-version promise is that the
curated native API is coherent, documented, qualified, and stable enough for
long-term use.

### Public API and compatibility boundary

- Make the contiguous real/complex value types and shared result/configuration
  conventions the primary documented API.
- Do not remove a maintained 1.x API merely because the major version permits
  it. In the absence of a prior 1.x minor-release deprecation period, retain it
  in place or through the tested compatibility surface for the 2.x line.
- Remove or isolate a 1.x API only after a documented replacement, complete
  migration examples, representative consumer testing, and at least one prior
  minor-release deprecation period. Formal removals are not a 2.0 requirement.
- For duplicate aliases that completed that deprecation runway, either remove
  them from the primary 2.0 API or move them into the tested compatibility
  package; retain them when the migration or packaging evidence is incomplete.
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
- Post-2.0 capability gates exist precisely so that 2.0 does not absorb
  unfinished future families; any future numerical family is planned and
  qualified in its own gate rather than pulled into the 2.0 baseline.

### Documentation accuracy and release readiness

- This section completes and verifies the continuous adoption track; it does
  not defer documentation, packaging, or first-use work until 2.0.
- Documentation completeness is not sufficient. An incorrect signature,
  default, formula, unit, shape, ownership rule, convergence claim, complexity,
  limitation, or migration instruction is a release-blocking product defect.
- Every public symbol is indexed and documented; every domain has a quick
  start, selection guide, API reference, error/convergence guide, and runnable
  examples.
- Audit every stable API contract against the compiled public declaration,
  implementation, and tests. Mechanically compare symbols, overloads, defaults,
  types, deprecations, and supported scalar/shape combinations wherever
  practical, and record the remaining human-reviewed semantic fields.
- Verify that algorithm descriptions and selection guides state the
  implementation actually shipped: assumptions, formulas, units, indexing,
  ownership, mutation, aliasing, tolerances, stopping tests, error/status
  behavior, workspace and complexity bounds, thread safety, and unsupported
  cases.
- Require every numerical-accuracy, convergence, determinism, memory, and
  performance claim to identify reproducible evidence and its precision,
  dataset, tolerance, compiler, platform, and comparison conditions. Remove or
  qualify claims that the release evidence does not support.
- Check consistency among API references, task and selection guides,
  source comments, examples, migration material, capability data, support
  matrices, release notes, and qualification reports. The least mature or most
  restrictive truthful statement governs until the discrepancy is resolved.
- Publish searchable, versioned documentation as a static website and an
  offline archive generated from the same reviewed sources and tagged release
  tree. A versioned documentation site must not silently describe another
  release's API.
- Representative multi-domain applications demonstrate realistic data flow,
  not just isolated one-function calls.
- Documentation CI checks links, public-symbol coverage, code-block syntax, and
  compilation/execution of every runnable example and command from a clean
  release archive.
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
- The final documentation audit has no unresolved mismatch that could cause an
  incorrect result, unsafe ownership or concurrency use, an invalid algorithm
  choice, or a failed 1.x migration. Lesser known documentation defects are
  listed with scope and workarounds rather than hidden.
- API references, guides, examples, source comments, capability data, release
  notes, and qualification evidence agree on the stable surface, maturity,
  supported platforms, limitations, and measured claims.
- At least two release-candidate cycles and a 30–60 day exercised soak validate
  clean installation, the complete documentation set, migration guide, and
  representative workflows from release archives rather than a developer
  checkout.
- Any compatibility removal has the required prior minor-release runway and
  complete migration coverage; no removal is required for 2.0, and no known
  correctness defect is being hidden to meet a version target.
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

## 2.x surface-area discipline

New stable public API is a permanent maintenance cost and must justify itself
through shared foundations, fit with the naming and type model, a clear user
workflow, numerical evidence, documentation, examples, testing,
migration/compatibility consequences, and realistic maintainer comprehension.

- A new algorithm is not automatically a new public type.
- A competitor having a feature is not sufficient justification.
- One coherent family is preferable to many thin wrappers.
- New stable surface should grow more slowly than internal implementation
  capability where possible.

There is no numerical quota for deprecations or removals. Existing stable API
is removed only when justified by correctness, safety, unsustainable design,
or an established deprecation/migration process; no API needs to die merely
because a new major version exists.

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

Every `Unsupported` capability family must eventually identify one of: a
committed post-2.0 capability gate, a candidate capability lane, or
`no current plan` with a concise reason. Readers can then distinguish
unsupported but planned, unsupported and under consideration, and unsupported
with no current plan. CI enforcement of this routing is future work.

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
- Every stable algorithm family, where applicable, has a documented
  `Background and references` section covering what mathematical problem the
  algorithm solves, the important mathematical idea, numerical safeguards and
  why they exist, assumptions and limitations, further reading, and open or
  otherwise appropriate references where practical. AMath/DAMath's documented
  implementation-note and reference approach is a model for this material;
  mathlib-fp does not claim an identical structure or copy its text.
- Documentation names known limitations directly; an unsupported case is not
  hidden behind a generic error or omitted from the reference page.
- Error and convergence messages should identify the operation, violated
  condition, and relevant value/shape when safe, then point to the same
  terminology used by the reference documentation.
- Documentation CI checks internal/external links, duplicate/stale public
  symbols, code-block syntax, examples, and release-version references.
- Public documentation and code comments are reviewed alongside implementation
  and tests, and stale examples are treated as defects.

## Post-2.0 capability programme

Post-2.0 milestones are **capability gates, not dates**. A gate ships when its
algorithms, contracts, tests, documentation, and maintenance review are ready;
it is not scheduled by the calendar. Dependency order matters more than
version-number aesthetics: each gate builds on foundations that earlier gates
and the 2.0 baseline make dependable.

Only the near-term gates below are committed roadmap directions. The candidate
lanes that follow are possibilities to be activated, split, reordered, or
rejected after a design and maintenance review; listing a lane is not a promise
to ship it. A capability is not complete merely because an implementation
exists — it must also meet the numerical, documentation, portability, and
maintenance contracts this roadmap applies to every stable family.

### 2.1 — Special Functions II

Scope:

- Bessel families (`J`, `Y`, `I`, `K` and related) with defined domains and
  accuracy budgets;
- elliptic integrals and elliptic functions;
- exponential integrals;
- a carefully bounded hypergeometric baseline rather than an open-ended family;
- per-family accuracy and domain budgets with a stated behaviour for
  out-of-domain input;
- an independent reference corpus, algorithm provenance, and cited references.

Non-goals:

- arbitrary or multiprecision arithmetic;
- attempting every specialist special function in one release.

Completion gate: each shipped special-function family has a documented domain,
accuracy budget, independent reference corpus, and cited algorithm source, and
matches the capability inventory's declared limits. AMath/DAMath demonstrates
the value of detailed implementation notes and cited numerical sources for such
families; this project does not copy its code or claim equivalent coverage.

The [capability inventory](CAPABILITIES.md) records which of these families are
unsupported today.

### 2.2 — Nonsymmetric and generalised spectral algebra

Scope:

- Hessenberg reduction;
- a real and complex Schur foundation as appropriate to the chosen design;
- nonsymmetric eigenvalue and eigenvector workflows;
- generalised `A x = λ B x` problems;
- ordering, scaling, convergence, residual, and failure contracts.

Non-goals:

- polynomial eigenvalue problems;
- large-scale shift-invert infrastructure unless separately designed.

Final public names are not invented from this roadmap; they are resolved in a
focused design record before any public API is added. Completion gate: the
chosen design is fixed and qualified against the dense and sparse references,
with ordering, scaling, convergence, residual, and failure behaviour documented
and tested. See the [dense solver guide](DenseLinearAlgebra.md#choose-a-dense-solver)
and [partial eigensystems](SparseLinearAlgebra.md#partial-eigensystems) for the
current supported boundary.

### 2.3 — Stiff and implicit ODEs

Scope:

- a documented stiff-solver baseline such as BDF and/or Radau-family methods,
  subject to design review;
- a Jacobian policy covering analytic, automatic, and numerical derivatives;
- tolerances and convergence diagnostics;
- dense output where supported;
- integration with the existing derivative contracts.

Non-goals:

- a full DAE index-reduction framework;
- PDE solving.

Listing a method here is not a promise of it; the design record must select the
final stable method and justify the choice. Completion gate: the selected stiff
method meets the accuracy, diagnostics, reentrancy, and dense-output contracts
used by the existing explicit path and is covered by reference and
stiff/non-stiff comparison tests. See the [modelling guide](NumericalModelling.md#choose-an-algorithm)
for the current explicit ODE scope.

### 2.4 — Sparse Direct II

Scope:

- fill-reducing ordering;
- symbolic/numeric separation;
- a reusable factor workflow;
- a documented fill and memory model;
- robust sparse direct solving for selected matrix structures.

Non-goals:

- distributed solvers;
- out-of-core solvers;
- GPU-only paths.

Multifrontal or supernodal architecture is not promised unless later design
evidence justifies it. Completion gate: the fill and memory model is measured
and documented, factors are reusable, and results agree with the typed-dense
oracle and residual checks on supported structures. See the
[reusable direct factors](SparseLinearAlgebra.md#reusable-direct-factors) for
the current baseline.

### Performance acceleration track

Optional parallel and SIMD work is evidence-driven and is not tied to a
promised minor version:

- the complete portable Pascal implementation remains the reference and oracle;
- optimise only benchmarked bottlenecks;
- optional in-tree x86/ARM-specific paths may be considered;
- accelerated paths require cross-path correctness tests;
- determinism differences must be explicit;
- small workloads must not pay unnecessary dispatch or thread overhead;
- no vendor BLAS/LAPACK library may become the only implementation;
- GPU support remains outside the current committed roadmap.

SIMD is not promised merely to compete on benchmark numbers; it earns its place
through measured, reproducible benefit over the portable baseline.

### Candidate capability lanes

The following lanes are **not release promises**. Each states likely direction
and the conditions under which it could be activated for design and maintenance
review; lanes may be reordered or rejected.

#### Signal Processing II

- FIR/IIR design with practical Butterworth and Chebyshev families;
- DCT/DST;
- STFT and spectral-estimation workflows;
- resampling and polyphase methods;
- broader practical wavelet support.

Activation requires clear API boundaries, reference evidence, and demonstrated
workflow value.

#### Statistics II

- generalised linear models;
- robust regression and covariance;
- survival and reliability analysis;
- stronger state-space/time-series diagnostics where foundations permit.

Causal-inference tooling is not implied.

#### Data Analysis II

- NMF;
- ICA;
- PLS/CCA;
- incremental or truncated PCA;
- additional dimensionality-reduction techniques only where numerical and
  maintenance gates are clear.

Fashionable algorithms are not roadmapped merely to match another library's
list.

#### Global and discrete optimisation

- a reproducible global-optimisation baseline;
- better bound-constrained finishing and polishing;
- stronger diagnostic and scaling infrastructure.

MILP is conditional research work, not a promised public capability. Before
MILP can enter a committed milestone it requires a dedicated design covering
branch-and-bound, bounds, termination, tolerances, reproducibility, incumbent
handling, test and reference strategy, and maintenance cost. MINLP remains
outside the committed roadmap unless it later receives its own dedicated
maturity gates.

#### Persistence and interchange II

- additional stable fitted-model persistence where actual workflows need it;
- decomposition and state persistence only when ownership and versioning
  semantics are clear;
- compatibility and corruption-handling contracts.

Arbitrary object-graph serialisation is not promised.

#### Beginner convenience units

After 2.0, evaluate whether optional per-domain beginner convenience units
would materially reduce first-use friction. They are **not currently approved
public API**. A convenience unit may enter a future minor release only if:

- a complete-program usability review shows a genuine improvement;
- it does not create another competing naming layer;
- dependencies remain bounded;
- the unit has a design record;
- examples demonstrate reduced complexity.

#### Console demo browser

A future console application that walks through the domains from a simple
menu and points the user toward the corresponding documentation and runnable
examples. It must remain an educational example, not another API framework.

#### Optional TAChart visualisation demo

A future, separately packaged, demo-only visualisation project that shows
selected numerical outputs graphically, for example through Lazarus TAChart.
It must remain optional, add no dependency to the numerical core, impose no
GUI requirement on normal mathlib-fp use, and carry no implication that
charting becomes a numerical-library domain.

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
