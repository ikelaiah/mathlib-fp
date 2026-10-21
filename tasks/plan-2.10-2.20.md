# Release plan: v2.10.0–v2.20.0

Planning baseline: v2.9.0, reviewed 2026-10-22. Status: proposed release sequence;
v2.10.0 is the next design target. This document authorizes no claim that the
features are implemented. The [roadmap](../docs/project/roadmap.md) defines
release scopes, exclusions, and numerical gates; the
[checklist](todo-2.10-2.20.md) tracks future execution.

## Rationale and dependencies

Complete workflows using current capabilities first. Existing holdout and
K-fold APIs, PLS training-only preprocessing, selected model persistence, FIR
execution, SOS design, and dense PCA are the starting points. Avoid competing
frameworks or changes to existing seeded results.

| Release | Outcome | Technical prerequisites | Relative risk |
| --- | --- | --- | --- |
| 2.10.0 | Explicit row sets, grouped/stratified validation, PLS integration | Existing Analysis and PLS | Medium: scoring and seed compatibility |
| 2.11.0 | Rolling/expanding chronological validation | 2.10 row-set contract | Medium: leakage and overlapping windows |
| 2.12.0 | GLM offsets and Poisson exposure | Existing GLM | Medium: diagnostics and prediction semantics |
| 2.13.0 | Integer frequency-weighted GLMs | 2.12 fit/prediction contract | Medium: effective rank and information |
| 2.14.0 | GLM/PLS prediction persistence | 2.12–2.13 contracts, existing interchange | Medium: artifact validity and preprocessing |
| 2.15.0 | Missing-observation Kalman updates | Existing dense state-space filter | Medium: partial covariance and likelihood |
| 2.16.0 | Fixed-interval RTS smoothing | 2.15 history/mask semantics | High: covariance conditioning and memory |
| 2.17.0 | Windowed low-pass FIR design | Existing FIR execution | Medium: spectral and delay contracts |
| 2.18.0 | Streaming rational resampling | 2.17 anti-alias filter | High: phase, delay, flush and output counts |
| 2.19.0 | SOS/resampler state persistence | 2.18 state contract, existing interchange | Medium: continuation and format limits |
| 2.20.0 | Truncated PCA | Existing dense algebra/PCA; early feasibility evidence | High: convergence and actual resource savings |

The sequence is a product priority, not an assertion that every release
technically depends on its predecessor. Reassess after 2.11, 2.14, 2.16, and
2.19 using completed workflows, feedback, and qualification cost. Later scopes
may move or be replaced. There are no calendar estimates or promised 3.0 date.

## Design decisions to resolve before implementation

- Use explicit training/validation index sets, not fold IDs alone: chronological
  windows need training subsets that exclude both validation and future rows.
  Establish caller ownership, index base, repeated scoring, empty-set behavior,
  and limits. Preserve old entry points and their random sequences.
- Keep PLS component selection inside the training data used for final model
  evaluation. Distinguish component-selection CV from an unbiased outer test.
- Treat offsets, exposure, and frequency weights as distinct mathematical
  inputs. Define inference and degrees-of-freedom semantics before adding them
  to a serialized prediction contract.
- Persist selected inference/state artifacts with versioning and allocation
  limits. A prediction artifact is not a training report or executable graph.
- Define DSP batch and streaming boundary/phase conventions together. Align
  reference outputs explicitly; an offline zero-phase result is not a live
  causal filter with zero latency.
- Choose truncated-PCA numerics only after residual, conditioning, memory, and
  timing experiments. A full decomposition followed by slicing does not meet
  the proposed scalability outcome.

These are design constraints, not frozen Pascal names or record layouts.
Write focused per-release specs and ADRs only where the decision warrants one.

## Execution slices for each release

Each release is a milestone, not a single coding task. Expand it into these
reviewable slices, ordinarily touching at most five files per slice. Separate
metadata/package/documentation updates if they would exceed that bound.

1. **Demonstrate the need and freeze a bounded contract.** Record one runnable
   blocked workflow, existing behavior, exact scope/exclusions, ownership,
   resource/error policy, independent references, and acceptance tolerances.
   Verification: review against the current source and roadmap. Files: a
   versioned spec and its fixture manifest. Dependency: prerequisite release
   contracts. Scope: small, documentation/reference design.
2. **Deliver the first numerical path.** Add one supported case with offline
   reference fixtures, failure tests, and an API contract. Verification: focused
   numerical tests including an independently expected result. Files: one
   source unit, focused tests/fixtures, one guide. Dependency: slice 1. Scope:
   medium; split multiple families or distinct algorithms into separate slices.
3. **Deliver edge and integration behavior.** Add the remaining bounded cases
   and one end-to-end consumer. Verification: milestone gates in the roadmap,
   compatibility tests, deterministic replay or continuation where applicable.
   Files: relevant source/test units and example/output contract. Dependency:
   slice 2. Scope: medium per case; repeat as necessary.
4. **Qualify and release.** Update package/API inventory/versioned docs/release
   evidence in separate focused changes; review before merging. Verification:
   normal, optimized, checked/heap suites; existing platform matrix; clean
   archives, Lazarus consumer, offline/live docs and published checksums under
   the established release process. Dependency: all acceptance gates. This is
   a checklist of several changes, not permission to combine them in one task.

Checkpoint after slices 1–2: reject or narrow unsupported numerical promises.
Checkpoint after integration: demonstrate the workflow and close acceptance
failures before preparing a release. A release is complete only after its
published artifacts and documentation are verified.

## v2.10.0 first execution backlog

| Task | Acceptance and verification | Dependencies | Likely files / scope |
| --- | --- | --- | --- |
| A: Specify row-set/scoring contract | Hand-enumerated fixtures establish indices, overlap, grouping, small classes, aggregation and limits; capture old seed outputs | None | New spec/reference manifest; small |
| B: Explicit split validation | Invalid/duplicate/out-of-range/overlapping rows fail; valid caller sets are independent of later caller mutation as specified | A | Analysis or focused validation unit, tests, guide; medium |
| C: Grouped splitter | No group crosses a train/validation boundary; uneven groups and too few groups have deterministic behavior | B | Validation implementation, tests/fixtures, guide; medium |
| D: Stratified splitter | Class balancing and small-class policy match enumerated cases; seed replay and global-RNG isolation hold | B | Validation implementation, tests/fixtures, guide; medium |
| E: PLS supplied-split overload | Training-only preprocessing; per-split errors/counts; rank/component policy across folds; old overload output unchanged | B, C | PLS, focused tests/fixtures, guide; medium |
| F: Grouped evaluation workflow | Identical outer rows for model comparison; PLS tuning inside outer training data; untouched outer test; example asserts its output | C, E | Example, index/output contract, guide; medium |
| G: Release qualification | All gates pass and exact released artifacts verified; use existing process | A–F | Several small metadata/evidence changes |

Review the A–B contract checkpoint before C–E. Review C–E numerical evidence
before F–G. D supports classification workflows; it is not required to apply
class labels to continuous-response PLS. The implementation is tracked in the
release checklist.

## Risks and scope controls

| Risk | Control |
| --- | --- |
| Eleven versions become a feature quota | Activate each with a demonstrated workflow; allow deferral/reordering |
| Generic validation framework grows beyond need | Index sets and small model-specific integrations; no estimator hierarchy |
| New defaults break reproducibility | Keep old calls and shuffles; expose new behavior through additive APIs |
| Weight semantics produce misleading inference | Start with integer replication weights and replicated-data oracles |
| Persistent files freeze immature contracts | Finalize prediction/state contracts first; version explicit bounded payloads |
| Numerical corner cases delay smoothing/PCA | Probe singular/ill-conditioned systems early; report unsupported cases truthfully |
| Filter response or scalability claims exceed evidence | Measure the documented workload and publish limits; no universal speedup claims |

MILP/MINLP, GPU, broad survival analysis, NMF/ICA/CCA, arbitrary object graphs,
and a new general pipeline framework are outside this horizon. SIMD/parallel
work remains separately benchmark-driven. Existing capabilities keep their
maintenance priority throughout.

## Primary references for contract design

These establish methodological precedents, not proof of user demand or a
requirement to clone another library's API. Record pinned versions and fixture
provenance when a release is activated.

- [Scikit-learn cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html):
  grouped and chronological splits protect against particular dependence-related
  evaluation errors.
- [Statsmodels GLM](https://www.statsmodels.org/stable/generated/statsmodels.genmod.generalized_linear_model.GLM.html):
  distinguish offset, exposure, frequency weights, and variance weights.
- [Statsmodels state-space methods](https://www.statsmodels.org/stable/statespace.html):
  filtering and smoothing are distinct operations with different information sets.
- [SciPy polyphase resampling](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.resample_poly.html):
  filtering and boundary conventions are part of the resampling contract.
- [SciPy partial SVD](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.linalg.svds.html):
  partial decomposition has explicit rank, tolerance, and iteration controls.

## Verification of this planning change

Run `python tools/check_docs.py` and
`python -m unittest discover -s tools -p test_release_state.py`.
Inspect the diff for current/next-release consistency, working local links,
unchanged historical plans/releases, and exactly eleven planned minor versions.
Numerical qualification belongs to implementation. The plan itself makes no
capability or support claim beyond the separately qualified release records.
