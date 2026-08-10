# 1.9.4 task list

## Task 1: Evidence contract and catalogue checker

**Description:** Define the checked JSON format and a Python gate that maps
each stable capability to bounded, reproducible numerical evidence.

**Acceptance criteria:**

- [x] A test first demonstrates that a missing stable-family record fails.
- [x] The checker rejects invalid paths, provenance, budgets, and high-risk
  mutation coverage.
- [x] The empty/incomplete catalogue cannot pass.

**Verification:** `python tools/test_numerical_evidence.py` and
`python tools/check_numerical_evidence.py`.

**Dependencies:** None.

**Files likely touched:** `docs/numerical-evidence-1.9.4.json`,
`tools/check_numerical_evidence.py`, `tools/test_numerical_evidence.py`.

**Estimated scope:** Medium.

## Task 2: Core, dense, and sparse evidence

**Description:** Supply independent oracle/property/edge evidence for scalar,
dense, structured, sparse, iterative, and partial-spectrum stable families.

**Acceptance criteria:**

- [x] All corresponding stable families have catalogue records and budgets.
- [x] Linked FPCUnit tests cover the recorded adversarial scales and degenerate
  behavior; the audit found no extra test unit necessary.
- [x] Existing API interfaces remain unchanged.

**Verification:** Focused FPCUnit build/run plus the evidence checker.

**Dependencies:** Task 1.

**Files likely touched:** One evidence catalogue, up to three focused test
units, and the TestRunner only when a new unit is necessary.

**Estimated scope:** Medium, split by test unit if it exceeds five files.

## Task 3: Modelling and optimization evidence

**Description:** Audit interpolation, differentiation, integration, fitting,
ODE/system solving, nonlinear/linear optimization, and convex optimization.

**Acceptance criteria:**

- [x] Each family has a finite, input-scoped metric/budget and provenance.
- [x] Tests distinguish residual/feasibility/estimated error from exact
  reference comparison.
- [x] Invalid, non-finite, and degenerate behavior is recorded and tested.

**Verification:** Focused FPCUnit build/run plus the evidence checker.

**Dependencies:** Task 1.

**Files likely touched:** Evidence catalogue and up to three modelling or
optimization test units.

**Estimated scope:** Medium.

## Task 4: Applied numerical evidence

**Description:** Audit random state, streaming statistics, DSP, ML,
time-series, interchange, inference, persistence, and expressions.

**Acceptance criteria:**

- [x] Deterministic fixtures record source/method and regeneration steps.
- [x] Each family has property/reference and edge/failure evidence.
- [x] Unsupported features remain outside the qualified population.

**Verification:** Focused FPCUnit build/run plus the evidence checker.

**Dependencies:** Task 1.

**Files likely touched:** Evidence catalogue and up to three focused applied
test units.

**Estimated scope:** Medium.

## Task 5: Sampled numerical fault injection

**Description:** Run documented, deterministic mutations against temporary
source copies and prove the linked tests detect them.

**Acceptance criteria:**

- [x] At least three high-risk-family mutations compile and make the linked
  validation fail.
- [x] Mutations never modify the checkout and never contact the network.
- [x] The mutation tool has isolated Python tests.

**Verification:** `python tools/test_numerical_mutation.py` and the mutation
runner against the completed catalogue.

**Dependencies:** Tasks 1-4.

**Files likely touched:** Mutation runner, its test, evidence catalogue, and
qualification wiring.

**Estimated scope:** Medium.

## Task 6: Qualification, documentation, and metadata

**Description:** Gate the release on the catalogue and mutation checks, publish
the evidence report, and consistently advance release identity to 1.9.4.

**Acceptance criteria:**

- [x] CI and `qualify_release.py` execute the evidence gates.
- [x] Public documentation names budgets, evidence categories, provenance, and
  known limitations without overclaiming.
- [x] Roadmap, changelog, package, version manifest, docs, and workflows agree
  on 1.9.4.

**Verification:** Documentation/tool tests, built-site checks, and full release
qualification.

**Dependencies:** Tasks 1-5.

**Files likely touched:** Split release metadata and workflow updates into
reviewable commits of no more than five files.

**Estimated scope:** Large; must be divided into small increments.
