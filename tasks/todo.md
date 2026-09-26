# 2.1 Special Functions II task list

## 1. Freeze the first contract

**Status:** Complete for J/Y.

**Acceptance:** Exact Bessel names/order coverage, real domains, NaN/Infinity,
zero/pole behavior, and per-region error budgets are recorded in
`tasks/spec-2.1.md`; algorithm sources and compatibility are reviewed.

**Verify:** Review against `docs/project/roadmap.md`, `MathBase.Precision`, and
the capability inventory. **Dependencies:** None. **Scope:** Small, docs only.

## 2. Build the independent reference corpus

**Status:** Complete for J/Y.

**Acceptance:** Bessel fixtures cover domain boundaries, roots, transition
regions, large inputs, and overflow/underflow; each value records its source,
precision, and generator version; ordinary tests use committed values only.

**Verify:** Focused corpus validation and a deliberate bad-value rejection.
**Dependencies:** 1. **Scope:** Medium, reference data and tests.

## 3. Ship the first J/Y slice

**Status:** Complete; merged as PR #41 after Linux and Windows CI passed.

**Acceptance:** The agreed J/Y functions match the corpus within documented
budgets, handle invalid inputs as specified, and include API docs and a
runnable example.

**Verify:** Focused FPC tests, full `TestRunner`, example build/output, docs
checks, and Windows/Linux CI. **Dependencies:** 1-2. **Scope:** Medium; split
J and Y into separate changes if either exceeds one focused review.

## 4. Ship the first I/K slice

**Status:** Implemented and locally verified; awaiting platform CI.

**Acceptance:** `ModifiedBesselI0`, `ModifiedBesselI1`, `ModifiedBesselK0`,
and `ModifiedBesselK1` meet the range and error budget in `tasks/spec-2.1.md`,
define pole and nonfinite behavior, and include documentation and tests.

**Verify:** Focused independent reference, Wronskian, and edge tests; full
`TestRunner`.
**Dependencies:** 1-2. **Scope:** Medium; split I and K if necessary.

## 5. Add elliptic integral/function slices

**Status:** First Legendre K/E/F slice implemented and locally qualified; PR #43 targets main.

The first slice uses parameter `m=k^2` in `[0,1]`, complete K/E, and
incomplete F/E for amplitudes in `[-Pi/2, Pi/2]`. Third-kind and Jacobi
functions remain for a later contract decision.

**Acceptance:** Each approved slice states its parameter convention, singular
limits, real domain, accuracy budget, and independent reference cases.

**Verify:** Focused FPC tests and full `TestRunner` per slice.
**Dependencies:** 1. **Scope:** Multiple small/medium changes.

## 6. Add exponential integrals

**Acceptance:** Approved real `Ei`/`E1` behavior at zero, sign boundaries,
small/large arguments, and nonfinite input is documented and tested.

**Verify:** Independent reference and edge tests; full `TestRunner`.
**Dependencies:** 1. **Scope:** Medium.

## 7. Add bounded hypergeometric support

**Acceptance:** Parameter and argument limits are explicit; convergence or
nonconvergence is visible; accepted inputs meet a stated numerical budget.

**Verify:** Reference values, identities, and failure tests; full `TestRunner`.
**Dependencies:** 1. **Scope:** Multiple small/medium changes.

## 8. Qualify 2.1

**Acceptance:** Capability inventory, guides, examples, API docs, changelog,
release records, and evidence agree with the implementation; all applicable
release gates pass; no unresolved critical review finding remains.

**Verify:** Normal CI plus applicable `tools/qualify_release.py` checks,
`python tools/check_docs.py`, example builds, and final diff review.
**Dependencies:** 3-7. **Scope:** Multiple reviewable documentation and gate changes.
