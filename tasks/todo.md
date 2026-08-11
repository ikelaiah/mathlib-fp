# 1.9.7 task list

## Task 1: Migration-rehearsal contract

**Description:** Define required domains, semantic concerns, consumer projects,
external mappings, duplicate-alias decisions, package paths, and result data.

**Acceptance criteria:**

- [x] Every documented domain has 1.x and candidate-2.0 coverage for
  construction, success, failure, ownership, copying, indexing, precision,
  defaults, and result interpretation.
- [x] Every alias decision has a replacement, difference note, compatibility
  period, owner, migration example, and tested package paths.
- [x] Invalid or incomplete records are rejected by focused unit tests.

**Verification:** `python tools/test_migration_rehearsal.py`.

**Dependencies:** None.

**Estimated scope:** Medium.

## Task 2: Side-by-side consumer projects

**Description:** Add independent supported-1.x and candidate-convention
projects that exercise every domain and assert expected behavior changes.

**Acceptance criteria:**

- [x] Both projects compile with FPC 3.2.2 from the source/package layout.
- [x] Both projects run to a deterministic success marker and assert failure
  paths rather than documenting them only in prose.
- [x] The candidate project uses only replacements already shipped in 1.9.7.

**Verification:** `python tools/check_migration_rehearsal.py --compiler fpc`.

**Dependencies:** Task 1.

**Estimated scope:** Medium.

## Task 3: Alias package boundary and decisions

**Description:** Test pressure/velocity facade and error aliases alongside the
canonical fluid-dynamics paths, then finalize the decision list.

**Acceptance criteria:**

- [x] Direct-source and Lazarus-package paths expose all old and canonical
  declarations with no hidden dependency.
- [x] Type identity, exception identity, defaults, ownership, and numerical
  results are asserted.
- [x] Each candidate is explicitly retained or deprecated with evidence; no
  removal entitlement is implied.

**Verification:** Focused FPC consumer builds plus Lazarus package build.

**Dependencies:** Tasks 1-2.

**Estimated scope:** Medium.

## Task 4: External migration mappings

**Description:** Publish conservative NumLib and LMath/DMath mapping guidance.

**Acceptance criteria:**

- [x] Common numerical tasks map to exact mathlib-fp units and entry points.
- [x] Indexing, storage, ownership, scalar precision, diagnostics, defaults,
  and unsupported differences are explicit.
- [x] Primary upstream references and “not drop-in compatible” language are
  present.

**Verification:** Rehearsal schema tests and documentation checks.

**Dependencies:** Task 1.

**Estimated scope:** Small.

## Task 5: Release and qualification integration

**Description:** Make migration rehearsal a release-owned gate and advance all
relevant documentation and metadata to 1.9.7.

**Acceptance criteria:**

- [x] Linux/Windows CI and clean-archive qualification run the rehearsal.
- [x] README, package, capabilities, versions, changelog, support, releasing,
  docs index, release/PR/qualification notes, and roadmap agree on 1.9.7.
- [x] Roadmap records 1.9.7 as previous and 1.9.8 as next.

**Verification:** Documentation, release-state, build-site, and qualification
tests.

**Dependencies:** Tasks 1-4.

**Estimated scope:** Large; land as focused metadata and documentation edits.

## Task 6: Full verification and review

**Description:** Run applicable release gates and review the complete change.

**Acceptance criteria:**

- [ ] Test builds, examples, docs, migration rehearsal, package, portability,
  and applicable evidence gates pass locally.
- [ ] No public-interface snapshot change or unsupported migration claim remains.
- [ ] All critical and required review findings are resolved.

**Verification:** `python tools/qualify_release.py --release 1.9.7 --compiler
fpc --lazbuild lazbuild`, plus `git diff --check` and final diff review.

**Dependencies:** Tasks 1-5.

**Estimated scope:** Medium.
