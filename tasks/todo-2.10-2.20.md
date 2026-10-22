# v2.10.0–v2.20.0 execution checklist

v2.10.0 through v2.13.0 are published and verified. v2.14.0 is in final
qualification. Releases through v2.14.0 are authorized. See the [plan](plan-2.10-2.20.md) for task
dependencies and verification, and the [roadmap](../docs/project/roadmap.md) for
scope, exclusions, and acceptance gates. Later releases remain planned capability gates.

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
| 2.14.0 Prediction persistence | [x] | [x] | [x] | [ ] |
| 2.15.0 Missing-observation filtering | [ ] | [ ] | [ ] | [ ] |
| 2.16.0 RTS smoothing | [ ] | [ ] | [ ] | [ ] |
| 2.17.0 Low-pass FIR design | [ ] | [ ] | [ ] | [ ] |
| 2.18.0 Rational resampling | [ ] | [ ] | [ ] | [ ] |
| 2.19.0 Streaming DSP persistence | [ ] | [ ] | [ ] | [ ] |
| 2.20.0 Truncated PCA | [ ] | [ ] | [ ] | [ ] |

## Horizon checkpoints

- [ ] After 2.11: verify grouped/chronological workflows; reassess GLM demand.
- [ ] After 2.14: verify a separate model consumer; reassess state-space need.
- [ ] After 2.16: verify masked filtering/smoothing; reassess sample-rate workflow.
- [ ] After 2.19: verify process restart; require measured PCA feasibility evidence.
- [ ] After 2.20: rerun integrated workflows and review actual compatibility debt.

No major version is triggered by checking the final box. Any incompatible
change requires its own approved migration and deprecation runway.
