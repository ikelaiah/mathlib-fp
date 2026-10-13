# Implementation plan: v2.7.0 Statistics II

Contract: [spec-2.7.md](spec-2.7.md). Acceptance: [todo-2.7.md](todo-2.7.md).

1. Commit the public contract and reproducible independent fixtures; write
   failing analytic and reference tests for the new unit.
2. Implement validated logistic and Poisson IRLS on the existing pivoted QR,
   stable objective/backtracking, final information and copied outputs.
3. Extend adversarial tests for separation, rank, conditioning, iteration,
   scale, ownership and numerical boundaries; add prediction and workflow.
4. Update all current API, capability, numerical and user documentation,
   package/version and release metadata; keep historical releases immutable.
5. Review and run focused/full local qualification, then PR CI and clean
   archive Linux/Windows qualification. Record measured results in docs.
6. Merge documentation before tagging; qualify exact main, tag and publish,
   and verify source, offline docs, checksums and deployed versioned site.

Each feature increment includes behavior tests and a focused verification.
The existing build and release gates remain authoritative. No GLM speed claim
is planned. Predictor normalization and QR avoid squaring conditioning;
separation certificates and finite-iterate failure results prevent reporting
an infinite estimate as a converged model.
