# Complete 2.0 API decision

Version 1.9.3 completes the all-domain decision over the frozen 1.9 public API.
It is a compatibility and documentation decision, not a 2.0 implementation:
no maintained declaration, compiled default, warning, behavior, or package
membership changes in this patch release.

Choose an ordinary workflow from the
[`curated common-path map`](API_COMMON_PATHS_2.0.md). Use the generated
[`declaration reference`](API_REFERENCE_1.9.md) when an exact overload,
advanced control, compatibility entry, or specialization detail matters.

## Decision artifacts

| Artifact | Authority |
| --- | --- |
| [`public-api-1.9.json`](public-api-1.9.json) | Exact 2,880-row unit/owner/kind/name/signature baseline plus the classification and compatibility decision for every row |
| [`API_REFERENCE_1.9.md`](API_REFERENCE_1.9.md) | Generated human-readable rendering of every exact row |
| [`api-decision-2.0.json`](api-decision-2.0.json) | Normative common selectors, all-domain conventions, compatibility decisions, and separately routed capability |
| [`API_CONVENTIONS_2.0.md`](API_CONVENTIONS_2.0.md) | Reviewed explanation of shared and domain-specific decisions |
| [`api-diff-1.9-to-2.0.json`](api-diff-1.9-to-2.0.json) | Machine-readable source/behaviour/warning/packaging/documentary consequences |
| [`API_DIFF_1.9_TO_2.0.md`](API_DIFF_1.9_TO_2.0.md) | Human-readable exact proposed diff |

`tools/update_api_snapshot.py` regenerates the snapshot and reference from
every `src/*.pas` interface plus the reviewed decision selectors.
`tools/check_api_decision.py` independently verifies exact coverage, convention
closure, compatibility mappings, common examples, and diff categories.

## Five complete classifications

- **Recommended** declarations form the concise common paths. Each path has an
  output-checked, compile/run-checked complete program.
- **Advanced** declarations are stable application API for more scalar kinds,
  storage formats, diagnostics, reusable state, and specialist workflows.
- **Compatibility** declarations remain supported and carry exactly one named
  replacement plus semantic-difference note or an explicit retain decision.
- **Experimental** declarations are outside the stable promise. The current
  snapshot contains none.
- **Implementation** declarations are exposed only because Free Pascal generic
  specialization needs them. Their named specializations/facades are the
  application surface.

The classifier is owner- and signature-aware. It distinguishes overloads such
as double-real `Solve` from same-named scalar variants and propagates generic
implementation status to the members of each generic public owner.

## Primary conventions

The complete convention matrix is in
[`API_CONVENTIONS_2.0.md`](API_CONVENTIONS_2.0.md). Its resolved concerns are:
naming, indexing, shape, units, ownership, mutation, aliasing, exceptions,
compiled defaults, tolerances, outcomes, RNG state, cancellation, progress,
and thread safety. All 13 domains inherit the shared decisions and record their
specific application; every snapshot unit is assigned to exactly one domain.

The common teaching route remains double-real and allocating. Named
single/complex facades, sparse and structured containers, views, destinations,
workspaces, callbacks, and diagnostics remain stable one step deeper. No route
hides a scalar conversion, dense conversion, retained callback, factor rebuild,
external runtime, or global mutable registry.

## Compatibility decisions

`IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` stay source-compatible. New code
uses `IDenseDoubleMatrix`, `TDenseDoubleMatrix`, and `TSparseDoubleMatrix`
respectively, with explicit copying conversions and documented semantic
differences. This guidance is not a deprecation or removal schedule.

`FinanceLib.Bonds` and `FinanceLib.NPV` are explicitly retained. Their public
types are exact aliases into `FinanceLib.Interest`/shared arrays, so the focused
entry units add no conflicting numerical, ownership, or default behavior.

Every one of the 127 exact compatibility declaration rows carries its decision
and semantic-note identifier in the generated reference.

## Exact proposed diff

The compiled 1.9-to-2.0 proposal is empty:

- no source declaration change;
- no behavior or compiled-default change;
- no warning/deprecation change;
- no packaging change.

The documentary defaults change: common paths appear first, advanced stable
paths remain visible, compatibility differences are explicit, and generic
support is no longer presented as an application choice. See the
[`exact diff`](API_DIFF_1.9_TO_2.0.md).

## Complete-program review

The 13 selected programs cover MathBase, dense algebra, finance, statistics,
engineering, numerics, probability, combinatorics, optimisation, time series,
machine learning, interchange, and geometry. Documentation qualification
compiles and executes them, checks their expected output, and rejects generic
implementation declarations in those programs.

The review found no wrapper that must be added inside 1.9.x. Ergonomic 2-D and
3-D vector rotation is useful but is routed to a separate 1.10.0 design. That
review must decide 3-D representation plus orientation, units, normalization,
non-finite behavior, and public naming before any declaration is proposed.

## Freeze and compatibility rule

The snapshot remains the 1.9 interface freeze. A changed interface hash needs
a regenerated snapshot and a documented compatibility or correctness reason;
this decision does not authorize breaking changes. A maintained 1.x API is not
removed merely because a major version is available, and compatibility is not
deprecation.

There are no unresolved stable declarations, compiled defaults, ownership
rules, classifications, compatibility decisions, or replacement mappings in
this candidate.
