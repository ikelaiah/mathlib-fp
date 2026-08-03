# 1.9.3 review notes

## Review boundary

This change implements only the active 1.9.3 complete-API-decision milestone.
It classifies and documents the existing frozen 1.9 surface, resolves
conventions and compatibility choices, checks common programs, and records the
exact proposed 2.0 diff. It changes no `src/` interface, storage layout,
compiled default, numerical behavior, deprecation warning, or package content.

It does not implement numerical-validation, performance, portability,
migration-rehearsal, beta, or final-freeze work planned after this milestone.
The only newly requested capability—ergonomic 2-D and 3-D vector rotation—is
routed to a focused 1.10.0 design and receives no 1.9.x declaration or invented
public name.

## Reviewable changes

1. Upgrade the exact 1.9 declaration snapshot to a decision-aware schema and
   classify every owner/signature row as recommended, advanced, compatibility,
   experimental, or generic implementation support.
2. Publish a 13-domain common-path map backed by existing concise,
   output-checked complete programs; fail the gate if a common program uses
   generic implementation support.
3. Resolve naming, indexing, shape, units, ownership, mutation, aliasing,
   exceptions, defaults, tolerances, outcomes, RNG state, cancellation,
   progress, and thread-safety conventions globally and for every domain.
4. Give all 127 compatibility rows exactly one decision: typed replacement
   plus semantic difference for the matrix surfaces, or explicit retention for
   the focused finance alias units.
5. Publish a machine-readable and human-readable exact proposed diff. Source,
   behavior, warning, and packaging lists are explicitly empty; documentary
   defaults are named separately.
6. Add selector, overload, generic-owner, exact-coverage, common-example,
   convention, compatibility, and diff checks to release qualification.

## Implementation discipline evidence

- No public type or storage changes were made, so no ownership/layout change is
  being smuggled into a documentation release.
- Documentation, generated reference data, checker behavior, and regression
  tests are reviewed together.
- `tools/update_api_snapshot.py` remains the sole generator for the exact
  snapshot/reference and uses the reviewed decision manifest rather than
  hand-editing 2,880 generated rows.
- Existing declarations remain until behavioral and compatibility evidence
  justifies a separately reviewed change; this release removes none.
- Common-program review records an awkward missing operation as 1.10.0 design
  work instead of adding an unreviewed patch-release wrapper.

## Completion-gate mapping

| Gate | Mechanical evidence |
| --- | --- |
| No undecided stable declaration/default/ownership/classification/replacement | `api-decision-2.0.json` has an empty unresolved list; `check_api_decision.py` reconstructs every classification, resolves all domains/concerns, and requires exactly one decision for every compatibility row. |
| Every recommended common path has a concise checked example | The 13 manifest paths resolve to output-checked runnable fragments; documentation execution compiles/runs them and the decision checker rejects implementation-support names. |
| Exact source/behavior/warning/packaging consequences | `api-diff-1.9-to-2.0.json` contains all five required categories. The four compiled-impact categories are explicitly `no_change` with empty items; documentary changes are enumerated. |
| New capability routed to 1.10.0 | 2-D/3-D vector rotation is listed once in both decision and diff manifests with no proposed declaration; the checker requires matching 1.10.0 routes. |

## Before opening the PR

- Regenerate the snapshot/reference and confirm a second generation produces no
  diff.
- Run the decision/extractor unit tests, documentation structure checks, and
  compile/run every documentation fragment.
- Run `git diff --check`, inspect that `src/` has no diff, and review generated
  classification totals plus all compatibility mappings.
- Run the complete local 1.9.3 qualification, including normal/optimised/
  checked-heap tests, examples, docs/site/offline archive, Lazarus package, and
  benchmark.
- Push only after the candidate commit is clean; require the Linux and Windows
  checksummed clean-archive jobs to pass before tagging.

