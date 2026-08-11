# 1.9.6 task list

## Task 1: Portability evidence contract

**Description:** Define target tiers, exact gate profiles, ABI expectations,
cross-target invariants, audit categories, and generated result semantics.

**Acceptance criteria:**

- [ ] Every claimed target names compiler, OS, CPU, pointer/scalar ABI, exact
  checks, evidence date/ref, and limitations.
- [ ] Unqualified targets are structurally distinct from supported targets.
- [ ] Binary/numerical invariants and source-audit rules are machine-readable.

**Verification:** `python tools/test_portability_evidence.py`.

**Dependencies:** None.

**Estimated scope:** Medium.

## Task 2: Native probe and offline validator

**Description:** Compile and run a Pascal probe, validate its observations and
the source/package audit, and write target-specific evidence JSON.

**Acceptance criteria:**

- [ ] ABI, endian, locale, binary, and numerical observations are deterministic
  and validated against the target contract.
- [ ] Foreign runtime/network/calling-convention dependencies fail the audit.
- [ ] The validator uses only standard-library Python and works offline.

**Verification:** Focused unit tests and
`python tools/check_portability_evidence.py --compiler fpc`.

**Dependencies:** Task 1.

**Estimated scope:** Medium.

## Task 3: Archive qualification enforcement

**Description:** Verify checksummed source archives, extracted clean trees,
network isolation, and extracted checksummed offline-documentation archives in
the release driver.

**Acceptance criteria:**

- [ ] Clean mode rejects `.git`, compiler outputs, missing release content, or
  archive/checksum mismatches.
- [ ] Offline HTML is extracted and revalidated after checksum creation.
- [ ] Qualification retains portability results alongside existing evidence.

**Verification:** `python tools/test_qualify_release.py` plus a focused clean
archive qualification run.

**Dependencies:** Tasks 1-2.

**Estimated scope:** Medium.

## Task 4: CI target and schedule coverage

**Description:** Align ordinary, secondary, weekly full, candidate, and release
workflows with the exact target profiles and publish their evidence.

**Acceptance criteria:**

- [ ] Windows/Linux x86-64 run primary checks on each change and complete
  archive qualification weekly and for candidates/releases.
- [ ] Windows i386 runs only its documented secondary checks.
- [ ] Archive qualification blocks outbound networking after dependencies are
  installed and restores it before evidence publication.

**Verification:** Workflow review plus documentation/release-state checks.

**Dependencies:** Task 3.

**Estimated scope:** Medium.

## Task 5: Support, release, and distribution documentation

**Description:** Publish the evidence-backed support matrix and consistently
advance release metadata and documentation to 1.9.6.

**Acceptance criteria:**

- [ ] Installation instructions link qualified and unqualified targets,
  offline paths, checksums, limitations, and exact evidence profiles.
- [ ] README, support/capability data, changelog, docs index, releasing guide,
  release/PR/qualification notes, package, workflows, and version manifest
  agree on 1.9.6.
- [ ] Roadmap records 1.9.6 as previous and 1.9.7 as next.

**Verification:** All documentation tests, site/offline build checks, API
snapshot checks, and release-state tests.

**Dependencies:** Tasks 1-4.

**Estimated scope:** Large; land as focused documentation/metadata increments.

## Task 6: Full qualification and review

**Description:** Run all supported local gates and review the complete diff for
correctness, simplicity, architecture, security, and performance.

**Acceptance criteria:**

- [ ] Normal, optimized, checked/heap, examples, documentation, package,
  benchmark, portability, and archive gates pass locally.
- [ ] No public-interface snapshot change or unsupported platform claim remains.
- [ ] All critical/required review findings are resolved.

**Verification:** `python tools/qualify_release.py --release 1.9.6 --compiler
fpc --lazbuild lazbuild` plus `git diff --check` and final diff review.

**Dependencies:** Tasks 1-5.

**Estimated scope:** Medium.
