# Governance and maintenance policies

Version 1.9.9 completes the project policies that the 2.x line will be held
to. Each policy is normative for maintainers and public for users; the
convergence checker verifies that this page, `SECURITY.md`, `CONTRIBUTING.md`,
and `SUPPORT.md` agree.

## 2.x maintenance policy

- The 2.x line maintains every capability shipped as stable at the 2.0.0
  baseline, plus any capability promoted to stable by a later 2.x release.
- A maintained capability must have an owner-independent test path, an API
  contract, selection guidance, a runnable example, and a documented maturity
  level. Removing any of these is a regression, not a cleanup.
- Patch releases (2.x.y) correct defects, improve robustness, or clarify
  documentation without adding a planned family of public APIs. Minor
  releases (2.y.0) add backward-compatible capabilities through the new-domain
  gate below.
- A defect that produces a silent wrong answer, an unsafe ownership or
  concurrency contract, or a portability failure is a release-blocking
  correctness issue for every supported target and takes priority over new
  capability work.
- Every corrected defect ships with a deterministic regression fixture and
  updated accuracy evidence. Evidence documents dates, targets, and exact
  checks; it is never inferred across platforms.

## Support policy

- The supported platform matrix is [`SUPPORT.md`](SUPPORT.md). Support claims
  are evidence-backed: a configuration is claimed only when a repeatable
  probe, numerical, and clean-archive run has actually executed on it.
- Primary targets must pass complete qualification on the exact tagged
  release before publication. Secondary targets keep their documented bounded
  profile.
- A target loses qualification status when evidence can no longer be
  reproduced on current tooling; the matrix is updated in the same change.
- Users may report defects on any platform, but a fix for an unqualified
  target is promised only when it also keeps the qualified targets correct.

## Deprecation policy

- A maintained 1.x/2.x API is not deprecated merely because a major version
  is available, because it is old, or because a newer name exists.
- A declaration may be deprecated only when: a replacement is implemented and
  documented; a migration example exists; the deprecation is announced in a
  minor release; and at least one full minor-release runway passes before any
  removal is considered in a later major release.
- The 1.9.9 closed manifest applies this policy: 1.10.0 marks no declaration
  as deprecated, and the 1.9.7 rehearsal decisions remain closed.
- Removals are not a version-number goal. Without a completed deprecation
  runway, the API stays in place or moves into the tested compatibility
  package.

## Contribution gate for new domains

A new domain (a functional area such as finance, geometry, or DSP) or a new
algorithm family inside an existing domain is accepted only when:

1. a documented, demonstrated user need exists (an issue, a completed
   workflow that cannot finish, or a repeated support question);
2. a design record fixes the public types, ownership, mutation, indexing,
   shape, error, tolerance, and compatibility contracts before code lands;
3. at least one independent mathematical reference or published algorithm is
   named, and its licence is compatible with MIT redistribution;
4. tests, API documentation, selection guidance, and a runnable example land
   in the same change as the implementation; and
5. the capability inventory and the closed capability manifest are updated in
   the same change.

Proposals that do not meet the gate are deferred explicitly — recorded in the
capability manifest — rather than left open. See
[`CONTRIBUTING.md`](../CONTRIBUTING.md) for the contributor-facing process.

## Security support window

- Each minor release line is supported for security fixes from its release
  date until the earlier of: one year, or six months after the next minor
  release line is published. `SECURITY.md` names the exact currently
  supported line.
- The 1.9.x line is supported through the 2.0.0 publication plus six months,
  and at minimum one year from 1.9.9, so 1.x adopters have a tested
  migration runway to 2.0.
- Security fixes are published as patch releases for every supported line
  that is affected, with the regression evidence required by the maintenance
  policy.
- Vulnerability reports follow the private reporting route in
  [`SECURITY.md`](../SECURITY.md) and receive a first response within 48
  hours.

## Provenance and licence

- Every stable algorithm and every test fixture corpus has named provenance.
  The complete audit is
  [`provenance-audit-1.9.9.json`](provenance-audit-1.9.9.json) with the
  human-readable [`PROVENANCE_AUDIT_1.9.9.md`](PROVENANCE_AUDIT_1.9.9.md).
- The library is MIT licensed with no third-party runtime dependency.
  Algorithm provenance must remain compatible with MIT redistribution;
  otherwise the algorithm is replaced by an independently derived portable
  implementation before it can become stable.

## Changes to these policies

Policy changes are reviewable documentation changes made through the ordinary
pull-request process, keep the machine-readable artifacts in agreement, and
take effect in the next release unless they correct a security-support
statement, in which case they may be published as a patch release.
