# v2.6.0 stable SOS IIR filtering checklist

Contract: [spec](spec-2.6.md). Sequence: [plan](plan-2.6.md).

## 1. Stability and response foundations

- [x] Add the public SOS response and stability diagnostic records and API.
- [x] Test denominator Jury conditions, pole radius, margins, and invalid
  coefficients using analytic first- and second-order fixtures.
- [x] Test complex SOS response at DC, interior frequencies, and Nyquist.

**Acceptance:** Stable, boundary, and unstable cases are distinguished;
frequency response agrees with independent section formulas. **Dependencies:**
Spec. **Likely files:** DSP unit, applied-numerics tests, independent fixture.

## 2. Butterworth design

- [x] Add low/high-pass and band-pass/band-stop SOS designers up to prototype
  order 12.
- [x] Add root transformation, deterministic real SOS pairing, prewarping,
  passband normalization, and strict design validation.
- [x] Check all returned sections with the stability diagnostic.

**Acceptance:** Independent coefficient and edge-response values pass for
odd/even orders and all four responses. **Dependencies:** 1. **Likely files:**
DSP unit, tests, reference fixtures/generator.

## 3. Chebyshev Type I design

- [x] Add bounded passband-ripple validation and first-kind analog poles.
- [x] Reuse verified transforms and SOS construction for all four responses.
- [x] Verify passband peak, specified ripple edges, and stopband attenuation.

**Acceptance:** Independent values confirm ripple and edge behavior, including
even-order endpoint ripple. **Dependencies:** 2. **Likely files:** DSP unit,
tests, fixtures/generator.

## 4. Streaming SOS filter

- [x] Add coefficient snapshotting, transposed direct-form-II state,
  `ProcessBlock`, `Reset`, `State`, and `RestoreState`.
- [x] Test block continuation, copied state, empty input, invalid block
  atomicity, and overflow recovery.

**Acceptance:** Chunked and one-shot results agree; rejected blocks preserve
state exactly. **Dependencies:** 1. **Likely files:** DSP unit and tests.

## 5. User workflow and documentation

- [x] Add a deterministic filter workflow example with state reuse, response,
  stability report, tolerances, and final success marker.
- [x] Register example/output contract and update applied-numerics and task
  guides.
- [x] Generate and review the new API reference and capability inventory.

**Acceptance:** The example compiles through public API paths and its output is
repeatable. **Dependencies:** 2–4. **Likely files:** example, tests/checker,
domain guide, task index.

## 6. Numerical evidence and release metadata

- [x] Add independent design/response corpus, provenance, catalogue entry, and
  tests for every claimed budget.
- [x] Reconcile Unreleased, version, package, README, release index, SECURITY,
  and versioned API/docs.
- [x] Record local qualification accurately, including any unrun CI targets.

**Acceptance:** All release-facing artifacts identify 2.6.0 and describe the
same numerical limits. **Dependencies:** 5. **Likely files:** release evidence,
changelog, VERSION, package, README, API/capability records, support policy.

## 7. Review and publication

- [x] Run focused RED/GREEN coverage and full normal, optimized, runtime-
  checked, and heap-traced Windows qualification; run the Lazarus Win64
  package build and consumer gates.
- [x] Review the implementation and complete the documentation, API, numerical,
  performance, portability, migration, workflow, and convergence gates.
- [ ] Run the Win32 package consumer and Linux/Windows checksummed clean-archive
  qualification on the release tree.
- [ ] Obtain green Linux/Windows exact-commit CI and full hosted release
  qualification before tagging.
- [ ] Create and merge the PR under repository release policy; tag exact main
  commit `v2.6.0`, publish title `mathlib-fp 2.6.0`, and use only changelog
  entries in the release body (do not repeat the title there).
- [ ] Verify checksummed source/offline-doc archives, attachment, and deployed
  versioned site; finish qualification evidence.

**Acceptance:** Published release artifacts resolve to the qualified exact
default-branch commit and match the release docs. **Dependencies:** 6.
