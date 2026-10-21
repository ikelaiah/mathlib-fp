# v2.9.0 implementation plan

Contract: [spec-2.9.md](spec-2.9.md).

1. Add failing FPCUnit contracts, implement validated bounded differential
   evolution with explicit RNG overloads, and verify focused tests.
2. Extend tests for local polishing, extreme arithmetic and adversarial
   callbacks; implement polishing and verify the full checked suite.
3. Add runnable example, algorithm/selection guidance, independent numerical
   evidence and provenance. Verify the example and documented contracts.
4. Advance version/package/API/capability/evidence/site and release metadata,
   preserving all historical release artifacts. Run release qualification.
5. Review correctness, architecture, security, resource bounds and tests;
   fix findings. Push release branch, open PR, obtain hosted CI and exact
   clean-archive evidence, merge, and validate the exact main commit.
6. Publish v2.9.0 from qualified main and verify source/docs downloads,
   checksums, extracted quick start and Lazarus consumer, and hosted site.

Risks: objective callbacks may be expensive/nonfinite; budgets count calls,
not wall time. Normalized coordinates avoid bound-width overflow. Population
collapse is a heuristic stop, not a certificate. Explicit state avoids global
RNG interference. Hosted checks cover Linux extended arithmetic and Windows
profiles. Keep review and evidence tied to the commit actually released.
