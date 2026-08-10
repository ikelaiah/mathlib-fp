# Spec: 1.9.4 numerical trust closure

## Status

Implemented on `release/v1.9.4`. The user approved the work with “Proceed”;
the final local qualification passed, while clean-archive CI remains required
before the release tag is created.

## Objective

Release 1.9.4 makes the numerical claims for the existing stable surface
auditable. A maintainer and an offline user must be able to identify, for each
stable capability, its numerical budget, independent reference or oracle,
edge/failure coverage, fixture provenance, and the test that enforces the
claim. High-risk numerical kernels must also be checked by reproducible,
sampled fault injection.

This release adds validation evidence and documentation. It does not add a
public API, remove an API, change the frozen 1.9 source interfaces, or claim a
new platform or performance target.

### Assumptions

1. The 28 `stable` records in `docs/capabilities.json` define the complete
   1.9.4 audit population; the five `unsupported` records remain unsupported.
2. A capability may be downgraded only when the evidence catalogue gives the
   exact missing evidence and the public capability inventory records the same
   limitation. The intended outcome is to qualify every stable record.
3. Reference values will be closed-form identities, independently published
   data, or a separately implemented small oracle. Each fixture records its
   source or method, precision, parameters, licence compatibility, and local
   regeneration procedure; qualification never contacts a network.
4. The existing public API snapshot remains byte-for-byte interface-compatible
   with the 1.9.0 baseline. Any defect found is fixed only when it is a
   correctness issue within the existing contract, with a failing regression
   test first.
5. `v1.9.4` is the release-tag spelling. The prior uppercase `V1.9.3` tag is a
   separate release-publication repair, outside this branch unless explicitly
   requested.

## Tech stack

- Free Pascal 3.2.2, `objfpc` mode, and FPCUnit for numerical regression and
  metamorphic tests.
- Python 3 standard library for catalogue validation, fixture checks, sampled
  mutation runs, documentation checks, and release qualification.
- Checked-in Markdown and JSON for human-readable, offline evidence.

## Commands

Focused catalogue tests:

```text
python tools/test_numerical_evidence.py
python tools/check_numerical_evidence.py
```

Focused Pascal test build/run (the exact suite or test unit selected by the
increment):

```text
cd tests
fpc -B -FcUTF8 -Fu../src -FUlib/evidence TestRunner.lpr
./TestRunner -a --format=plain
```

Release qualification after all changes:

```text
python tools/qualify_release.py --release 1.9.4 --compiler fpc --lazbuild lazbuild
```

## Project structure

```text
docs/capabilities.json                 Current capability inventory and maturity.
docs/NUMERICAL_EVIDENCE_1.9.4.md       Human-readable evidence and limitations.
docs/numerical-evidence-1.9.4.json     Machine-checkable evidence catalogue.
tests/                                 FPCUnit numerical, property, and edge-case tests.
tools/check_numerical_evidence.py      Catalogue and provenance gate.
tools/test_numerical_evidence.py       Unit tests for the catalogue gate.
tools/run_numerical_mutation.py        Offline sampled mutation runner.
tools/qualify_release.py               Aggregates release gates.
```

## Code style

Use explicit, deterministic test data and name the numerical contract being
checked. Keep the assertion adjacent to the independently calculated oracle.

```pascal
Expected := 2.0;
Actual := TExampleKit.Evaluate(Input);
AssertEquals('published reference: relative-error budget', Expected, Actual,
  2.0e-13);
```

Python gates use the standard library, clear failures that name the family and
field, and never fetch data during a test or qualification run.

## Testing strategy

- Catalogue unit tests cover valid records and reject omitted stable families,
  unbounded numerical claims, missing provenance, invalid test paths, and
  missing mutation coverage for high-risk families.
- Each audited family has a named FPCUnit test or existing test reference for
  an independent fixture/oracle, a structural or metamorphic property, and
  non-finite, invalid, or degenerate input where applicable.
- At least three high-risk kernels are mutated in isolated temporary source
  trees. The documented test group must fail for each mutation.
- The existing normal, optimized, checked/heap, documentation, example,
  package, and benchmark release gates remain green.

## Boundaries

- Always: preserve the 1.9 public interfaces, keep fixtures and tools offline,
  state finite precision budgets rather than universal claims, and run the
  focused gate after every increment.
- Ask first: add a dependency, change CI runner/platform support, downgrade a
  capability that is currently stable, or modify a public API contract.
- Never: invent reference values without provenance, suppress a failing test,
  claim a budget outside its stated input domain, or use proprietary/networked
  software in qualification.

## Success criteria

1. All 28 stable inventory records have exactly one catalogue entry, each with
   a stated input domain, metric/budget, test evidence, edge behavior, and
   reproducible provenance; unsupported records are excluded with their
   existing limitations retained.
2. The catalogue gate rejects missing, stale, or contradictory evidence and is
   part of CI and `qualify_release.py`.
3. High-risk scalar, dense/sparse solver, modelling/optimization, and DSP/data
   paths have stronger oracle/property/edge tests. Sampled source mutations
   make their linked validation fail.
4. Public documentation distinguishes exact checks, reference comparisons,
   error estimates, and machine-specific observations, and records known
   limitations without upgrading unsupported features.
5. Release metadata consistently names 1.9.4, the Roadmap records it as the
   previous release and identifies 1.9.5 as next, and the complete release
   qualification passes offline.

## Resolved decisions

1. Evidence gaps block the release; all 28 stable families are qualified, so
   no maturity downgrade was made.
2. The separate `V1.9.3` versus `v1.9.3` tag repair remains outside this
   branch. Historical documentation checks out the existing uppercase tag.
