# Implementation plan: v2.5.0 reusable spectral processing

**Status:** Implementation and local Windows candidate qualification passed
on 12 October 2026. Exact-commit cross-platform CI and publication remain.

## Objective and scope

Deliver reusable FFT and STFT plans plus inverse STFT for real-double signal
processing. The complete contract is [spec-2.5.md](spec-2.5.md); acceptance tasks
are in [todo-2.5.md](todo-2.5.md).

FFT, STFT, periodogram, Welch, rational resampling helpers, and a second-order
Butterworth low-pass biquad already exist. v2.5.0 adds preparation and workspace
reuse for repeated transforms and a reversible framed-signal workflow.

The motivating scenario is a maintainer-selected extension of the sensor
pipeline: repeatedly analyze a finite signal, edit conjugate bin pairs, and
reconstruct all original samples. The current public STFT has no inverse;
its complete-frame policy drops the remainder and its frame loop calls an
allocating transform. These are observed API/workspace boundaries, not a
measured timing defect or an external user request.

Performance work begins with reproducible baselines. Preparation cost,
steady-state time, allocations, retained memory, and numerical error are
reported separately. SIMD, threading, GPUs, broad algorithm expansion, and
unrelated dense/sparse optimizations are deferred to later evidence-led work.

## Decisions

- Add `TFFTPlan` and `TSTFTPlan` to `EngineeringLib.DSP`, using existing
  arrays, complex values, dense matrix interfaces, and window enums.
- Qualify double real/complex paths, portable serial Pascal, radix-2 and
  Bluestein algorithms. Preserve existing signatures and conventions.
- Fix STFT signal/frame/hop/window geometry at construction and prepare all
  scratch storage there; valid pre-sized `Into` calls allocate nothing.
- Use full spectra, explicit zero padding, and weighted overlap-add synthesis.
  Validate coverage and Hermitian symmetry.
- Classes own private mutable workspace and have explicit lifetime. Reject
  simultaneous use of one plan; separate plans are independent.
- Correctness, ownership, failure and allocation criteria are release gates.
  Timing comparisons require matching conditions and review; no speedup
  percentage is assumed before measurements exist.

## Dependency order

```text
Contract, independent fixtures and baseline
  -> radix-2 plan -> cached Bluestein plan
  -> STFT analysis -> synthesis and failure handling
  -> complete example and performance evidence
  -> candidate metadata -> exact-commit qualification -> publication
```

## Implementation tasks

| Task | Deliverable | Depends on | Likely files |
| --- | --- | --- | --- |
| 1 | Independent fixtures, focused runner, unmodified 2.4 baseline | Spec | Fixture include, generator, focused unit/runner |
| 2 | Radix-2 plan, normalization and prepared destinations | 1 | DSP unit, focused tests, applied guide |
| 3 | Cached Bluestein and exact resource diagnostics | 2 | DSP unit, focused tests, fixtures, guide |
| 4 | STFT geometry, padding, analysis and matrix destinations | 3 | DSP unit, focused tests, guide |
| 5 | Synthesis, symmetry/coverage checks, failure recovery | 4 | DSP unit, focused tests, guide |
| 6 | Deterministic signal-edit-reconstruction example | 5 | Example, example index, output checker, task guide |
| 7 | Benchmark rows, exact allocation/storage gates | 5 | Runner, manifest, validator, validator tests, performance guide |
| 8 | API/capability integration and release records | 6, 7 | Separate documentation batches, at most five files each |
| 9 | Candidate metadata and local qualification | 8 | Version, package, README, changelog, qualification record |
| 10 | CI qualification, merge, tag, release and archive checks | 9 | Workflow artifacts and release evidence |

Every behavioral slice includes focused tests and user documentation. Task 8
splits into API/inventory, release evidence, and discovery/support batches.
The checklist supplies acceptance criteria; the spec supplies exact commands.

## Checkpoints

1. After Task 3: independent DFT fixtures and existing transforms agree across
   all four normalizations; valid warm calls meet zero-allocation and resource
   bounds; invalid calls preserve destinations and plans recover.
2. After Task 5: original first/last samples and tails reconstruct; bad
   coverage, symmetry, dimensions, non-finite input and overlapping use fail
   as specified; independent plans and matrix views behave correctly.
3. After Task 7: the complete workflow is repeatable, deliberate faults are
   detected, and construction/allocation costs are separated from execution.
4. Before publication: all test modes, examples, API/docs, supported-target
   package/consumer checks and Linux/Windows archive gates pass for required
   exact commits under `RELEASING.md`.

## Release completion

During implementation, published metadata identifies 2.4.0 and the roadmap
identifies 2.5.0 as the next gate. Record implemented additions in Unreleased.
At candidate preparation reconcile version/package, API artifacts, capability
inventory, README, changelog, release evidence and versioned documentation.
Publication uses the real publication date and maintained-line policy.

Merge the validated release branch into the default branch; require green CI
on that exact commit before tag `v2.5.0`. Verify source and offline archives,
checksums, the current landing page and preserved historical sites.

## Risks and controls

| Risk | Control |
| --- | --- |
| Existing features mistaken for additions | Source inventory and explicitly additive spec |
| Hann endpoints or dropped tail lose samples | Fixed padding/coverage rules and boundary fixtures |
| Cached state aliases or becomes stale | Fixed geometry, copied window, owned scratch, busy guard |
| An `Into` call still allocates | Memory-manager allocation/reallocation counts |
| Bluestein setup outweighs reuse benefit | Separate cold/warm timings and exact retained-byte evidence |
| Accuracy weakens for speed | Independent/property fixtures and every required build mode |
| Timing noise produces false claims | Matching host/compiler/workload, repeated measurements and review |

## Scope control

Scope and numerical conventions are fixed in the spec. Implementation findings
that require changes must update the spec and plan before expanding code.
There are no remaining scope-selection tasks; later features and accelerators
require their own workflow and design evidence.
