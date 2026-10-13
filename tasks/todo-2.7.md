# v2.7.0 generalized linear models checklist

Contract: [spec-2.7.md](spec-2.7.md). Sequence: [plan-2.7.md](plan-2.7.md).

- [x] Define public contracts, numerical boundaries and provenance.
- [x] Commit independent high-precision reference fixtures and RED tests.
- [x] Implement logistic/Poisson fitting, diagnostics and prediction.
- [x] Cover analytic, reference, failure, scale and ownership behavior.
- [x] Add runnable example and documentation/output contracts.
- [x] Update current API, capabilities and numerical evidence.
- [x] Update all release, support, security and package/version documentation.
- [x] Complete code review and full local release qualification.
- [x] Obtain green Linux/Windows candidate CI and clean-archive qualification.
- [x] Finalize all current documentation and retained qualification records
      before creating a tag or release.

## Publication execution

External publication actions are recorded by
[PR #72](https://github.com/ikelaiah/mathlib-fp/pull/72), the
[GitHub release](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.7.0),
and its [release qualification](https://github.com/ikelaiah/mathlib-fp/actions/workflows/release-qualification.yml)
and [documentation](https://github.com/ikelaiah/mathlib-fp/actions/workflows/documentation.yml)
workflow artifacts, rather than post-tag edits to this source checklist.

1. Merge code and all docs after final PR CI passes.
2. Qualify the exact merged main commit with CI and clean-archive checks.
3. Create annotated `v2.7.0` from that commit and publish title
   `mathlib-fp 2.7.0`, with only changelog entries in the release body.
4. Verify downloaded source/docs archives, SHA-256 sidecars, README quick start,
   package consumer, versioned deployment and immutable-tag qualification.
