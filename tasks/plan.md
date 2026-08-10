# Implementation plan: 1.9.4 numerical trust closure

## Overview

Completed: the existing capability inventory and broad FPCUnit coverage now
form an
offline, release-gated evidence system. Build the evidence contract first;
then audit capability groups in small, testable slices; finally update release
metadata and run the full qualification.

## Architecture decisions

- `docs/capabilities.json` remains the single list of stable capabilities;
  `docs/numerical-evidence-1.9.4.json` adds release-specific evidence rather
  than duplicating the inventory or encoding free-form claims in Python.
- The checker is schema- and cross-reference-driven: it validates every stable
  capability, documentation/test paths, numerical budgets, provenance, and
  selected fault-injection cases without parsing numerical results from prose.
- Mutations are applied only to a temporary source copy and must cause the
  linked FPCUnit suite to fail; no production source has a test-only fault
  switch.
- Any discovered functional defect follows test-first repair in a separate
  focused increment. No public API expansion is part of this plan.

## Dependency graph

```text
capabilities.json ──> evidence schema/checker ──> qualification + CI
                                  │
                                  ├── core/dense/sparse audit tests
                                  ├── modelling/optimisation audit tests
                                  └── applied/statistics/ML/time-series audit tests
                                               │
                                               v
                                   evidence documentation and 1.9.4 metadata
```

## Task list

1. Establish the evidence catalogue contract and its failing validation tests.
2. Audit core scalar, dense, and sparse/iterative families; add targeted
   oracle/property/edge tests and catalogue records.
3. Audit modelling and optimisation families; add budgeted reference and
   adversarial tests and catalogue records.
4. Audit applied DSP, statistics, ML, time-series, random, and interchange
   families; add deterministic reference and failure tests and records.
5. Add and prove sampled temporary-tree mutations for high-risk kernels.
6. Integrate the evidence gate with qualification/CI and publish the
   human-readable evidence report.
7. Advance all release metadata to 1.9.4, mark it previous in the Roadmap, and
   promote 1.9.5 as the next release; run full local qualification and record
   the result.

## Checkpoints

### After tasks 1-2 — complete

- Catalogue test is red before the checker and green afterwards.
- Core and sparse evidence records cover their stable inventory entries.
- Normal FPCUnit suite and documentation check pass.

### After tasks 3-5 — complete

- Every stable capability has exactly one evidence record.
- Mutation runner proves every selected fault is detected.
- Optimized and checked/heap test gates pass.

### After tasks 6-7 — complete

- CI and qualification invoke the evidence gate.
- Documentation/site builds for 1.9.4 and all identity checks pass.
- Full release qualification passed from the release branch: 76 gates, zero
  failures on Windows 11 x86-64 with FPC 3.2.2, Lazarus 4.8, and Python 3.13.5.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Existing tests lack independent or adversarial evidence | High | Add a small separately implemented oracle or downgrade only with explicit approval and documented scope. |
| Mutation cases are brittle across FPC versions | Medium | Use deterministic textual mutations of arithmetic expressions and assert a test-suite failure, not an exact output. |
| The audit becomes a prose-only catalogue | High | Cross-check every claim with checked paths, named test evidence, budgets, and a release gate. |
| Full qualification is slow | Medium | Run focused Python/FPCUnit gates per increment; reserve all-gate runs for checkpoints. |

## Resolved scope

Evidence gaps block this release, and all stable families have qualifying
records. The pre-existing `V1.9.3`/`v1.9.3` tag discrepancy is recorded but is
not changed by this branch.
