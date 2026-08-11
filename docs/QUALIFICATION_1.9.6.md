# mathlib-fp 1.9.6 qualification

Status on 2026-08-11: **all 81 local release-qualification gates passed** on
Windows 11 x86-64 with FPC 3.2.2, Lazarus 4.8, and Python 3.13.5. The release
cannot be tagged until Linux and Windows
checksummed clean-archive workflows pass for the exact candidate commit.

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Exact target claims | The JSON manifest requires compiler, OS/CPU, pointer/scalar ABI, evidence date/ref, limitations, and named checks for each supported target; unqualified targets cannot carry inferred ABI or checks. |
| Cross-target invariants | The native probe checks endian, locale, binary64, and exact versioned binary fixture values while recording ABI-dependent scalar sizes. |
| Assumption audit | Filesystem, locale, endian, floating-point, calling-convention, address-space, and runtime-dependency outcomes are published and mechanically checked where applicable. |
| Clean source archive | The driver verifies SHA-256, safe members, required content, exact extraction, absence of `.git`, and absence of compiler/runtime artifacts before building. |
| Offline documentation | The generated ZIP checksum is verified; the archive is extracted and its links, search data, and release identity are checked again. |
| Offline execution | Linux/Windows workflows install FPC/Lazarus before applying an outbound-default-block policy during extracted-tree qualification. |
| Honest limitations | Win32 has a named secondary profile; macOS/ARM64, Linux/ARM64, other Unix variants, and other compiler versions remain visibly unqualified. |

## Required local command

```text
python tools/qualify_release.py --release 1.9.6 --compiler fpc \
  --lazbuild lazbuild
```

The exact CI archive jobs additionally pass `--source-archive`,
`--source-checksum`, and `--network-isolated` after applying their OS network
policy.

## Local result

Normal, optimized, and runtime-checked/heap-traced configurations each ran all
932 FPCUnit tests with zero errors or failures; heaptrc reported zero unfreed
blocks. All 24 examples compiled and ran, output contracts passed, executable
documentation and mutation checks passed, and the generated 1.9.6 HTML ZIP was
checksummed, extracted, and link/release-identity checked.

The native Win64 probe recorded 64-bit pointers/`SizeInt`, 4/8/8-byte
`Single`/`Double`/`Extended`, little endian, a passing comma-locale guard, and
the exact binary fixture. The audit found no issue across 50 stable source
units and confirmed that the Lazarus package requires only FCL. The package
build passed. Performance validation retained all 14 rows and 13 advisory
comparisons with `pass` status and no timing review.

Local artifacts are under `build-temp/release-qualification/`, including
`results.json`, `portability-results.json`, `performance-results.json`, the
offline documentation ZIP/checksum, and per-gate logs.

## Required clean-archive evidence

The exact candidate commit must pass both primary archive jobs. Their retained
checksums, `results.json`, `portability-results.json`, performance evidence,
and per-gate logs are authoritative. The Windows per-change job also supplies
the explicitly bounded Win32 secondary evidence.

## Limits

Retained evidence is target- and ref-specific. It does not establish support
for an unlisted compiler/OS/CPU/ABI combination, and a local configured checkout
cannot replace the exact candidate archive jobs.
