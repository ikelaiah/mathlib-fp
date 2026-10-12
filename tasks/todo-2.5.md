# v2.5.0 reusable spectral processing checklist

**Status:** v2.5.0 was published on 12 October 2026 after implementation,
cross-platform clean-archive qualification, exact-commit CI, and archive/site
verification. Evidence is recorded in the
[qualification record](../docs/releases/2.5.0/qualification.md).
Contract: [spec](spec-2.5.md). Sequence: [plan](plan-2.5.md).

## 1. Independent fixtures and baseline

- [x] Commit FFT/STFT fixtures, generator and provenance, focused tests/runner.
- [x] Include normalization, windows, overlap coverage and reconstructed signals.
- [x] Capture unmodified v2.4 FFT/STFT timings, commit, host, flags and setup.

**Acceptance:** Independent expected values; exact workload and baseline
conditions. **Verify:** Reproducible fixture generation, injected corrupt-value
rejection and focused failures. **Dependencies:** Spec.
**Files:** focused unit/runner, fixture include, reference generator.

## 2. Radix-2 FFT plan

- [x] Implement fixed-length lifetime, cached tables/scratch, Execute/ExecuteInto.
- [x] Support four normalizations, exact in-place arrays and input preservation.
- [x] Add invalid-call/busy-plan recovery tests and public workflow docs.

**Acceptance:** Reference budgets pass; pre-sized warm execution allocates
nothing; invalid dimensions/values/arithmetic preserve destination.
**Verify:** Focused normal/checked runs and allocation instrumentation.
**Dependencies:** 1. **Files:** DSP unit, focused tests, applied guide.

## 3. Arbitrary-length FFT preparation

- [x] Cache Bluestein chirps, transformed kernel and convolution scratch.
- [x] Guard element/byte overflow; report exact numeric workspace/retained bytes.
- [x] Qualify odd/composite/prime lengths and independent plan ownership.

**Acceptance:** Same API, error and normalization rules with zero warm
allocations. **Verify:** References, round trips, conjugation/scaling, existing
transform comparisons, checked/heap runs. **Dependencies:** 2.
**Files:** DSP unit, focused tests, fixtures, guide.

## 4. Reusable STFT analysis

- [x] Fix geometry/window at construction and prepare complete scratch storage.
- [x] Implement Analyze/AnalyzeInto with full bins and specified zero padding.
- [x] Document the existing STFT's complete-frame convention and new plan policy.

**Acceptance:** Independent frame DFTs, exact shape/padding/tail coverage,
input immutability and strided matrix destinations meet the contract.
**Verify:** Focused numerical/dimension/finiteness/coverage tests.
**Dependencies:** 3. **Files:** DSP unit, focused tests, applied guide.

## 5. Synthesis and failure handling

- [x] Implement Synthesize/SynthesizeInto with weighted overlap-add and trimming.
- [x] Check coverage, finite spectra, Hermitian symmetry, DC and Nyquist.
- [x] Qualify destination atomicity, busy guards, recovery, leaks and independence.

**Acceptance:** Every sample round-trips within budget; symmetric spectral
edits match independent reconstruction; invalid calls preserve destinations.
**Verify:** Focused runner, full normal/optimized/checked/heap suite.
**Dependencies:** 4. **Files:** DSP unit, focused tests, applied guide.

## 6. Complete runnable workflow

- [x] Add a deterministic signal, repeated analysis, conjugate-bin editing,
  synthesis, residual reporting and final success marker.
- [x] Register the example, check output bounds and repeat-run identity.
- [x] Link the user task and describe interpretation/limits.

**Acceptance:** Public-API-only program demonstrates reconstruction and reuse.
**Verify:** Example build and output contract commands in the spec.
**Dependencies:** 5. **Files:** example, example index, checker, task guide.

## 7. Performance evidence

- [x] Add cold/prepared FFT and STFT/synthesis cases at the spec's sizes.
- [x] Count allocation/reallocation calls and exact retained workspace.
- [x] Separate construction/output-allocation/execution time; retain numerical
  gates; review matching-host comparisons and all material regressions.

**Acceptance:** Zero valid warm allocations and bounded storage are exact
gates; timing claims identify repeatable matching conditions.
**Verify:** Performance validator tests/checker; meaningful fault injection.
**Dependencies:** 5. **Files:** runner, manifest, validator, validator tests,
performance guide.

## 8. API, capability and release documentation

- [x] Register focused tests in TestRunner and generate current API evidence;
  require a clean second generation.
- [x] Update implemented capability inventory, selection and limits.
- [x] Create 2.5 release notes, numerical/performance evidence, review notes and
  qualification records identifying actual targets/results.

**Acceptance:** All artifacts agree on the additive surface and scope.
**Verify:** API generation, docs/link/example checks in the spec.
**Dependencies:** 6, 7. **Files:** separate API/inventory, release-evidence and
discovery batches, at most five files per batch.

## 9. Candidate metadata and local qualification

- [x] Reconcile version, package, README, changelog and candidate docs.
- [x] Run applicable local qualification without package/benchmark skips.
- [x] Build current/historical versioned sites and validate the offline ZIP.

**Acceptance:** Consistent candidate artifacts and retained local results,
with unexecuted targets identified. **Verify:** Qualifier and RELEASING.md.
**Dependencies:** 8. **Files:** version, package, README, changelog, qualification
record, split into small batches as necessary.

## 10. Publish and verify the exact release

- [x] Pass required Linux/Windows archive qualification and supported-target CI.
- [x] Apply real publication date/support policy, merge validated branch and
  require green exact default-branch CI before v2.5.0 tag/publication.
- [x] Verify source/docs archives, checksums/assets, current site/history and
  retain exact-commit target-specific evidence.

**Acceptance:** Published artifacts match the qualified default-branch commit
`1193b90fc3e127e7ff6b4884df48df867eb63ddc`. **Verify:** PR #65 was merged to
`main`; CI run [38184788877](https://github.com/ikelaiah/mathlib-fp/actions/runs/38184788877)
passed before tagging, and tag qualification run
[38213375071](https://github.com/ikelaiah/mathlib-fp/actions/runs/38213375071)
passed 126 Linux and 127 Windows gates with no failures. Release
[v2.5.0](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.5.0), source
and offline documentation checksums, and deployed site/history are recorded in
the [qualification record](../docs/releases/2.5.0/qualification.md).
**Dependencies:** 9.
