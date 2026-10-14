# Implementation plan: v2.8.0 Data Analysis II

Contract: [spec-2.8.md](spec-2.8.md). Acceptance: [todo-2.8.md](todo-2.8.md).

1. Lock the PLS1 API/numerical contract and add RED tests plus an independent
   high-precision fixture corpus.
2. Implement predictor validation, centering/scaling, rank measurement, and
   one-component NIPALS extraction; verify analytic component identities.
3. Add multi-component rotation reconstruction, full fit results, prediction,
   and adversarial tests for constant, collinear, and numerical-boundary data.
4. Add seeded leakage-free cross-validation and component selection, then
   verify fold reproducibility and the independent RMSECV reference.
5. Add the correlated-predictor example and update every current guide,
   example index/contract, API/capability snapshot, package and release doc.
6. Review the complete diff and run focused and full test/example/doc/release
   qualification. Merge the docs-complete PR, qualify its exact merge commit,
   then tag and publish only after all checks pass.

Each code increment is followed by focused compilation/tests. Final
qualification includes every example, package consumers, versioned/offline
documentation, supported platform CI, and clean source archive checks. The
release description is changelog content only; the title stays in the title
field.
