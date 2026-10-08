# v2.4 Sparse Direct II checklist

- [x] Add failing tests for minimum-degree symbolic ordering and deterministic
  tie handling.
  - Acceptance: graph fixtures assert the expected stable permutation and
    fill-sensitive factor nonzero counts.
  - Verify: focused `TestStructuredSolvers` executable fails on the baseline.
  - Files: `tests/TestStructuredSolvers.pas`.
- [x] Implement sparse minimum-degree analysis and pattern ownership.
  - Acceptance: CSR/CSC same-pattern inputs analyze identically without dense
    allocation; malformed and invalid inputs fail atomically.
  - Verify: focused tests pass for four scalar facades.
  - Files: structured solver unit and focused tests.
- [x] Implement reusable numeric factorization and permutation-aware solves.
  - Acceptance: changed values reuse an analysis; changed patterns are rejected;
    repeated multi-RHS solves match dense references and residual limits.
  - Verify: focused tests cover pivoting, alias rules, zero-size and singular
    cases.
  - Files: structured solver unit and focused tests.
- [ ] Add scalability and numerical evidence.
  - Acceptance: sparse fixtures report input/factor/fill counts and avoid dense
    conversion; measured conditions and correctness references are recorded.
  - Verify: performance evidence checker and release qualification.
  - Files: tests, benchmarks, tools, release evidence.
- [ ] Update user documentation and release metadata.
  - Acceptance: API snapshot, reference, guide, examples, capability inventory,
    changelog, support policy, README, docs index, offline site and archive all
    identify 2.4.0 consistently; release body contains no duplicate title.
  - Verify: full release checklist and green Linux/Windows CI.
  - Files: release and documentation artifacts.
