# mathlib-fp 1.9.7 qualification

## Qualification statement

Version 1.9.7 is qualified only when the exact candidate source archive passes
the existing target-tier gates plus the executable migration rehearsal. This
document distinguishes completed local evidence from mandatory CI evidence;
it does not infer Linux or Win32 results from a Windows x86-64 run.

## Migration completion gate

| Gate | Evidence | Status |
| --- | --- | --- |
| All-domain side-by-side consumers | 13 domain markers and final markers from both projects | Passed locally, 2026-08-12 |
| Expected behavior, not prose only | Reference values, diagnostic exception, copy/clone, indexing, defaults, status, and replay assertions | Passed locally |
| Alias decision evidence | Type/exception identity and equal pressure/Mach results | Passed locally |
| Package boundary | Four units present in `mathlib_fp.lpk`; required packages exactly `FCL`; Lazarus 4.8/FPC 3.2.2 build | Passed locally |
| Deprecation requirements | Replacement, semantic note, example, compatibility period, owner, and tested paths recorded; all four decisions are retain | Passed |
| External mappings | NumLib and LMath/DMath rows require conceptual equivalence, differences, unsupported cases, and primary source | Passed |
| Public interface | Generated owner/signature snapshot and decision checker | No source-interface change |

## Local environment

| Item | Value |
| --- | --- |
| Date | 2026-08-12 |
| OS / CPU | Windows x86-64 |
| FPC | 3.2.2 |
| Lazarus | 4.8 package toolchain |
| Runtime dependencies added | None |
| Compiler warnings from migration consumers | None |

## Full local release qualification

`python tools/qualify_release.py --release 1.9.7 --compiler fpc --lazbuild
lazbuild` passed 83 gates on 2026-08-12. The retained result is
`build-temp/release-qualification-1.9.7/results.json`; it covers compiler
identity, normal/optimized/checked-heap test modes, all examples and output
contracts, documentation tests/fragments/site/offline archive, API decisions,
numerical mutation/evidence, migration rehearsal, portability, Lazarus package,
and benchmark/performance evidence. Build artifacts remain local/CI evidence
and are not part of the source archive.

## Required exact-candidate evidence

Before tagging, the exact commit must still pass in CI:

- Linux x86-64 and Windows x86-64 checksummed, network-isolated clean-archive
  qualification, including migration results as retained artifacts;
- Windows i386 secondary tests, native portability probe, source/package audit,
  and Lazarus package build;
- normal, optimized, checked/heap test modes, every top-level example and output
  contract, documentation/site/offline archive checks, numerical evidence and
  mutation gates, performance evidence, portability evidence, package build,
  and final API snapshot check.

Candidate workflow results are intentionally not pre-recorded as passed in the
repository. They belong to the exact candidate commit's CI artifacts.

## Known limits

- The candidate project demonstrates preferred conventions available in 1.9.7;
  it is not a separately compiled 2.0 library.
- External-library mappings do not promise symbol, ABI, mutation, precision,
  random-sequence, convergence, exception, or licensing equivalence.
- Local evidence covers Windows x86-64 only. Supported target claims remain
  bounded by [SUPPORT.md](SUPPORT.md) and exact candidate CI.
- All four duplicate aliases are retained. No deprecation or removal clock has
  started.
