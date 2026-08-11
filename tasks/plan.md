# Implementation plan: 1.9.7 migration and compatibility rehearsal

## Overview

Prove the proposed 2.0 migration path without changing the frozen 1.9 public
surface. Add a machine-readable rehearsal contract, runnable side-by-side
consumer projects for every documented domain, explicit package-boundary tests,
responsible NumLib and LMath/DMath mappings, and release-owned evidence and
documentation. Migration claims must be executable from a clean source archive.

## Architecture decisions

- Keep `EngineeringLib.Pressure` and `EngineeringLib.Velocity` in the main
  package. Rehearse canonical imports beside their exact 1.x aliases and retain
  all four aliases unless the evidence proves a safe deprecation runway.
- Record migration coverage and decisions in
  `docs/migration-rehearsal-1.9.7.json`; generate run-specific compiler and
  result evidence rather than checking host-specific observations into source.
- Use two independent consumer projects: one intentionally follows supported
  1.x paths and one follows candidate-2.0 conventions available in 1.9.7.
- Treat NumLib and LMath/DMath as conceptual source-migration guides, never as
  drop-in compatibility promises. Every mapping names indexing, ownership,
  precision, diagnostics, and unsupported differences.
- Add no dependency and no new runtime API. Integrate the rehearsal checker
  into ordinary CI and the existing clean-archive qualification driver.

## Dependency graph

```text
rehearsal schema/tests ──> side-by-side consumer projects
          │                          │
          ├──> alias boundary tests ─┤
          │                          v
          └──> external mappings --> executable rehearsal evidence
                                             │
                                             v
                             CI, qualification, release docs
```

## Task list

1. [x] Define the v1.9.7 migration-rehearsal data contract and failing tests.
2. [x] Add 1.x and candidate-2.0 consumer projects covering every domain and
   required semantic concern; compile and run both through the checker.
3. [x] Compile-test every 1.9.3 duplicate-alias candidate through direct-source
   and Lazarus-package boundaries and finalize retain/deprecate decisions.
4. [x] Publish verified NumLib and LMath/DMath conceptual mappings, semantic
   differences, unsupported cases, and source-edit guidance.
5. [x] Integrate migration evidence into CI, clean-archive qualification,
   release metadata, changelog, indexes, roadmap, and release documentation.
6. [x] Run focused and full qualification, review all five quality axes, and
   resolve every critical or required finding.

## Checkpoints

### After tasks 1-3

- Invalid, incomplete, or unowned migration records fail validation.
- Both consumer projects compile and assert their documented behavior.
- All four duplicate aliases and their canonical paths compile with identical
  type, exception, default, ownership, and numerical behavior.

### After tasks 4-5

- Every domain has side-by-side source and semantic-difference guidance.
- NumLib and LMath/DMath mappings state non-equivalence and unsupported cases.
- CI, qualification, package metadata, docs, and release identity agree on
  1.9.7, with 1.9.8 named as next.

### After task 6

- Focused tests, normal/optimized/checked test builds, examples, docs,
  migration rehearsal, package build, and applicable release gates pass.
- The frozen public-interface snapshot is unchanged.
- The final diff has no unresolved correctness, readability, architecture,
  security, performance, or documentation finding.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A documentation-only example drifts from compilable Pascal | High | Compile and run both complete consumer projects in CI and qualification. |
| “Mapping” is read as drop-in compatibility | High | Require semantic differences and unsupported cases for every external-library row. |
| Moving aliases creates hidden transitive dependencies | High | Keep aliases in place and compile every old/canonical import combination through source and package paths. |
| Candidate examples accidentally require an unshipped 2.0 API | High | Use only declarations shipped in 1.9.7 and label the examples as conventions, not a separate binary API. |
| Release evidence overstates unsupported targets | High | Reuse the 1.9.6 target tiers and distinguish local results from CI-required cross-target evidence. |

## Scope decision

The milestone rehearses migration and package boundaries. It does not remove or
deprecate maintained 1.x declarations, add a compatibility package without
evidence, import third-party numerical code, or introduce a new algorithm.
