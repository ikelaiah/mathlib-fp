# v2.10.0–v2.20.0 execution checklist

Versions 2.10.0–2.14.0 are published and verified. The
[2.15.0 release checklist](todo-2.15.md) tracks publication and artifact
verification for the qualified parallel dense multiplication release.
Version 2.16.0 implements Special Functions III. Later scopes require
activation evidence. See the [plan](plan-2.10-2.20.md) for dependencies
and the [roadmap](../docs/project/roadmap.md) for scope and acceptance gates.

## v2.10.0 — Validation splits

- [x] A: Demonstrate workflow, freeze explicit row-set/scoring contract and old seed fixtures.
- [x] B: Implement and verify explicit split validation.
- [x] Checkpoint: review contract and ownership before split builders.
- [x] C: Implement grouped splits with uneven-group and seed fixtures.
- [x] D: Implement stratified splits with an explicit small-class policy.
- [x] E: Integrate supplied splits into PLS with per-split diagnostics.
- [x] Checkpoint: old default results preserved; training-only preprocessing verified.
- [x] F: Demonstrate model comparison with an untouched outer test set.
- [x] G: Review, qualify, release, and verify published artifacts.

## Later release activation and delivery

Each row expands into the plan's contract, numerical, integration, and release
slices before work starts. The four checkboxes are milestones, not one task.

| Release | Need/spec | Numerical/reference gates | Workflow/compatibility | Release verified |
| --- | --- | --- | --- | --- |
| 2.11.0 Chronological validation | [x] | [x] | [x] | [x] |
| 2.12.0 GLM offsets/exposure | [x] | [x] | [x] | [x] |
| 2.13.0 GLM frequency weights | [x] | [x] | [x] | [x] |
| 2.14.0 Prediction persistence | [x] | [x] | [x] | [x] |
| 2.15.0 Parallel dense kernels | [x] | [x] | [x] | [ ] |
| 2.16.0 Special Functions III | [x] | [x] | [x] | [x] |
| 2.17.0 Exact integers and rationals | [x] | [x] | [x] | [ ] |
| 2.18.0 Wavelets and DCT | [ ] | [ ] | [ ] | [ ] |
| 2.19.0 SIMD dense multiplication (conditional) | [ ] | [ ] | [ ] | [ ] |
| 2.20.0 Truncated PCA | [ ] | [ ] | [ ] | [ ] |

## Horizon checkpoints

- [x] After 2.11: verify grouped/chronological workflows; reassess GLM demand.
- [x] After 2.14: verify a separate model consumer; reassess state-space need.
- [ ] After 2.16: review special-function budgets. Use early truncated-PCA
  feasibility and real sparse workload measurements to reassess priorities.
- [ ] At the 2.19 checkpoint: review the SIMD activation evidence and require
  measured PCA feasibility before activating or retaining the 2.20 scope.
- [ ] After 2.20: rerun integrated workflows and review actual compatibility debt.

No major version is triggered by checking the final box. Any incompatible
change requires its own approved migration and deprecation runway.

The 2.11 checkpoint was satisfied by grouped and chronological workflow
verification and the subsequent analytic offset/exposure and integer-frequency
GLM releases. The 2.14 checkpoint passed with a separately compiled consumer
using only artifacts and new observations. State-space and sample-rate
conversion work is tracked under the roadmap's deferred workflow scopes.
