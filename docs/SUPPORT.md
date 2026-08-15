# Supported platform matrix

Version 1.9.8 uses Free Pascal source and standard RTL/FCL units only. The
machine-readable source for this matrix is
[`portability-evidence-1.9.6.json`](portability-evidence-1.9.6.json); the
[evidence report](PORTABILITY_EVIDENCE_1.9.6.md) explains the unchanged target
contract and audit. The 1.9.7
[migration rehearsal](MIGRATION_REHEARSAL_1.9.7.md) adds source/package
consumer evidence, and the 1.9.8
[representative workflow qualification](WORKFLOW_QUALIFICATION_1.9.8.md) adds
multi-domain end-to-end workflow evidence without expanding the supported
target matrix.

## Support tiers and current evidence

| Tier | Compiler | OS / CPU | Pointer width | `Single` / `Double` / `Extended` storage | Last retained successful evidence | Exact profile |
| --- | --- | --- | --- | --- | --- | --- |
| Primary | FPC 3.2.2 | Windows x86-64 | 64-bit | 4 / 8 / 8 bytes | 2026-08-12 local 1.9.7 rehearsal; fresh 1.9.8 candidate CI required | P-Windows |
| Primary | FPC 3.2.2 | Linux x86-64 | 64-bit | 4 / 8 / 10 bytes | 1.9.6 retained evidence; fresh 1.9.8 candidate CI required | P-Linux |
| Secondary | FPC 3.2.2 | Windows i386 | 32-bit | 4 / 8 / 10 bytes | 1.9.6 retained evidence; reruns on each change | S-Win32 |

Evidence dates and refs describe configurations that actually ran. They are
not inferred across operating systems, CPUs, pointer widths, or Unix families.
The exact 1.9.8 candidate commit must produce new Linux and Windows primary
artifacts before tagging.

### Exact profiles

- **P-Windows:** normal, `-O3`, runtime-checked/heap-traced tests; all examples
  and output contracts; documentation, generated site, extracted offline HTML,
  numerical mutation, performance, and portability gates; Lazarus package;
  checksummed clean ZIP with new outbound connections blocked.
- **P-Linux:** the same full profile except the Lazarus package, which is not a
  Linux release claim; checksummed clean `tar.gz` with new outbound connections
  blocked.
- **S-Win32:** `-O2` full tests, the native ABI/binary portability probe and
  source/package audit, and the Lazarus package. This tier does not imply the
  primary documentation, benchmark, or heap-traced profile.

Primary normal checks run on every push and pull request. The complete primary
archive profiles run on demand, for the exact published release, and weekly to
detect drift before a release candidate.

## Explicitly unqualified targets

macOS/ARM64, Linux/ARM64, other Unix variants, and other compiler versions may
compile, but are not release-qualified. No ABI, numerical, archive, package, or
support claim is extrapolated for them. macOS/ARM64 will be added only when a
maintainable runner provides repeatable native probe, numerical, and clean-
archive evidence.

## ABI and portability limits

- `Single` and `Double` are IEEE binary32 and binary64 on the qualified
  targets. `Extended` is a `Double` alias on Win64 and the 80-bit x87 format on
  the qualified Linux x86-64 and Windows i386 targets. Typed dense and sparse
  storage deliberately excludes `Extended` in 1.9.
- Dimensions use `SizeInt`; allocation products are checked before allocation.
  Practical dimensions remain bounded by address space and available memory,
  especially on the Win32 secondary tier.
- Versioned binary interchange writes explicit little-endian fields and scalar
  payloads and never writes Pascal record layouts. The native probe checks the
  exact one-element fixture on every qualified target.
- Invariant interchange supplies its own decimal separator. Human-oriented
  unit-conversion string parsing follows the process numeric locale, as
  documented in `EngineeringLib.UnitConversion`; callers needing portable
  interchange should use the invariant APIs.
- Stable source units do not load DLLs/shared objects, import networking or
  process units, declare foreign calling conventions, or require generated
  source. The Lazarus package requires only FCL.

## Installing without network access

Download a source archive and its published SHA-256 while online, transfer both
files to the offline machine, verify the checksum, and extract the archive.
Adding `src/` to the FPC unit path is sufficient; no configure or generation
step is required. The release page also provides a separately checksummed
offline HTML ZIP generated from the same tagged documentation. Extract it and
open `mathlib-fp-docs-1.9.8/index.html` locally.

The release qualification workflows perform these same checksum, clean-
extraction, direct-source, representative-workflow, documentation, and package
checks after toolchain installation and with new outbound connections blocked.
The release driver actively challenges that policy and fails if a new outbound
connection succeeds.
