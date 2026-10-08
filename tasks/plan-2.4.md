# Implementation plan: v2.4 Sparse Direct II

The design contract is in [sparse-direct-2.4.md](../docs/design/sparse-direct-2.4.md).

1. Add failing fixtures for orderings, analysis reuse/mismatch, dense-oracle
   solves, and sparse scaling; preserve the existing natural-order behavior.
2. Implement canonical sparse pattern capture and deterministic minimum-degree
   symbolic analysis with sparse adjacency.
3. Implement reusable symbolic-to-numeric factorization and permutation-aware
   sparse LU solve; keep compatibility factories delegating through analysis.
4. Add scalar-family, malformed-input, multi-RHS, aliasing, pivot, and fill
   diagnostics coverage; qualify storage and numerical behavior.
5. Publish API and workflow documentation, runnable examples, capability
   inventory and benchmark/qualification evidence.
6. Update release metadata and versioned docs; run the full release gates,
   create the v2.4.0 tag and GitHub release with a body that does not repeat its
   title.

## Checkpoints

- After each behavioral slice: focused FPC test executable.
- Before release candidate: complete normal/optimized/checked/heap-traced
  suite, all examples and package builds, API/link checks, and performance and
  portability qualification.
- Before publication: clean-archive/offline documentation verification and
  green Linux/Windows CI for the exact tagged commit.
