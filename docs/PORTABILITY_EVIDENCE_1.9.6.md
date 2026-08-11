# Portability evidence for mathlib-fp 1.9.6

This report describes what the 1.9.6 support matrix proves and, equally
importantly, what it does not claim. The executable contract is
[`portability-evidence-1.9.6.json`](portability-evidence-1.9.6.json).

## Native cross-target probe

`tools/PortabilityProbe.lpr` is compiled by the target compiler and emits one
canonical row. `tools/check_portability_evidence.py` checks:

- compiler target OS/CPU and version;
- pointer and `SizeInt` width;
- `Single`, `Double`, and `Extended` storage size;
- runtime byte order;
- invariant decimal output after changing the process decimal separator;
- an exact binary64 checksum; and
- the complete bytes of a versioned one-element binary interchange fixture.

The binary fixture is identical across the qualified little-endian targets
because `MathBase.Interchange` writes explicit little-endian fields and scalar
bits rather than host records. Full FPCUnit, numerical-evidence, and mutation
gates provide the broader target-specific numerical checks; the small probe is
not presented as a substitute for them.

## Target evidence

| Target | Tier | Retained evidence entering 1.9.6 | Required 1.9.6 evidence |
| --- | --- | --- | --- |
| Windows x86-64, FPC 3.2.2 | Primary | `v1.9.5`, 2026-08-11 | Full clean-ZIP profile, package, probe/audit, offline network policy |
| Linux x86-64, FPC 3.2.2 | Primary | `v1.9.5`, 2026-08-11 | Full clean-`tar.gz` profile, probe/audit, offline network policy |
| Windows i386, FPC 3.2.2 | Secondary | `v1.9.5`, 2026-08-11 | `-O2` suite, package, and native probe/audit on each change |

The exact candidate artifacts produced by
`.github/workflows/release-qualification.yml` are authoritative for the 1.9.6
tag. A configured maintainer checkout cannot replace them.

## Platform-assumption audit

| Category | Checked outcome and limit |
| --- | --- |
| Filesystem | Stable numerical units do not implicitly open project or absolute paths. Persistence accepts caller-owned streams. Examples/tools use platform path APIs. |
| Locale | Invariant interchange fixes `.` independently of the process locale and is probed under a comma decimal separator. Human unit-conversion parsing intentionally follows the current numeric locale and is documented as such. |
| Endianness | Versioned dense, sparse, random-state, and selected-model binary formats encode explicit little-endian fields; no Pascal record layout is persisted. Qualified targets are little endian; big endian is unqualified. |
| Floating point | The probe records scalar storage per ABI. Accuracy budgets remain precision- and algorithm-specific; `Extended` is not used by typed dense/sparse storage. |
| Calling convention | The stable-source scan rejects foreign calling-convention and external-symbol declarations. Public callbacks use native Pascal contracts. |
| Address space | Containers use `SizeInt`/`SizeUInt` and checked byte products. Win32 is a secondary 32-bit tier with lower practical limits, not evidence for 64-bit scale claims. |
| Runtime dependency | Stable source imports no dynamic-loader, process, or network units; the Lazarus package requires only FCL. No generated source is needed. |

The audit deliberately treats unqualified targets as unknown rather than
assuming that another Unix or 64-bit result applies.

## Archive and offline evidence

Clean qualification now requires both the source archive and adjacent SHA-256,
compares archive members with the extracted tree, rejects `.git` state and
compiler output, and records the digest/file count. It then compiles normal,
optimized, and checked/heap configurations, examples, documentation programs,
benchmarks, and the native probe directly from that tree.

The generated offline HTML ZIP and checksum are independently verified,
extracted, and passed through the built-link/release-identity checker. Linux
and Windows workflows install FPC/Lazarus first, then block new outbound
connections for qualification, require an active connection attempt to fail,
and restore runner networking before artifact publication.

## Unqualified targets

macOS/ARM64 and Linux/ARM64 have no maintainable release runner in this
repository and remain explicitly unqualified. Compilation reports are welcome,
but a report alone does not establish the complete numerical, ABI, archive, and
offline evidence required for a support tier.
