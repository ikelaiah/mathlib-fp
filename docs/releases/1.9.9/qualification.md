# mathlib-fp 1.9.9 qualification

## Qualification statement

Version 1.9.9 is qualified only when the exact candidate source archive passes
the existing target-tier gates plus the convergence gate, and when the
archive-based qualification covers the complete target, numerical, memory,
performance, examples, migration, package, and documentation set. This
document distinguishes completed local evidence from mandatory CI evidence;
it does not infer Linux or Win32 results from a Windows x86-64 run.

## Convergence completion gate

| Gate | Evidence | Status |
| --- | --- | --- |
| Closed 1.10.0 manifest | Both declarations complete; every other proposal explicitly deferred; zero unresolved questions | Passed locally, 2026-08-17 |
| Final snapshot and diff | Empty compiled source/behaviour/warning/packaging diff from 1.9.0; final status | Passed locally |
| Provenance audit | All 50 `src/` units covered; MIT; no third-party code; no runtime dependency | Passed locally |
| Policies | 2.x maintenance, support, deprecation, new-domain gate, security window present and checked | Passed locally |
| Roadmap agreement | 1.9.9 previous, 1.10.0 next, 1.10.0 scope declares the rotation addition | Passed locally |
| Decision agreement | 21 retained alias reviews; no unresolved 1.9.3 decisions; 1.9.7 retention closed | Passed locally |

## Local environment

| Item | Value |
| --- | --- |
| Date | 2026-08-17 |
| OS / CPU | Windows x86-64 |
| FPC | 3.2.2 (CI verifies; local documentation gates are Python) |
| Python | 3.13 |
| Runtime dependencies added | None |

## Local evidence completed

- `python tools/test_convergence.py` — 20 focused unit tests pass.
- `python tools/check_convergence.py` — manifest, snapshot, provenance,
  policies, roadmap, and inventory agree.
- `python tools/check_docs.py` — documentation, links, inventory, snapshot,
  and release identity checks pass.
- `python tools/test_release_state.py` and `python tools/test_api_decision.py`
  pass; no `src/` interface digest changed.

## Required exact-candidate evidence

Before tagging, the exact commit must pass in CI:

- Linux x86-64 and Windows x86-64 checksummed, network-isolated clean-archive
  qualification, including the convergence gate and retained artifacts;
- Windows i386 secondary tests, native portability probe, source/package
  audit, and Lazarus package build;
- normal, optimized, checked/heap test modes, every top-level example and
  output contract, documentation/site/offline archive checks, numerical
  evidence and mutation gates, performance evidence, portability evidence,
  migration rehearsal, workflow qualification, convergence gate, package
  build, and final API snapshot check.

The 1.9.9 roadmap gate additionally requires the source and offline
documentation archives to be built from the release tag and the complete
qualification to run against those archives; the release-qualification
workflow performs this with new outbound connections blocked.

## Known limits

- 1.10.0 additions are declared, not implemented; their qualification belongs
  to 1.10.0.
- Candidate CI results are intentionally not pre-recorded as passed in the
  repository. They belong to the exact candidate commit's CI artifacts.
