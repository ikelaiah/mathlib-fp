# Supported platform matrix

The 2.0.0 release candidate uses Free Pascal source and standard RTL/FCL units
only; 1.10.0 remains the latest published stable release. The
machine-readable source for this matrix is
[`portability-evidence-1.9.6.json`](../portability-evidence-1.9.6.json); the
[evidence report](../releases/1.9.6/portability-evidence.md) explains the unchanged target
contract and audit. The 1.9.7
[migration rehearsal](../releases/1.9.7/migration-rehearsal.md) adds source/package
consumer evidence, and the 1.9.8
[representative workflow qualification](../releases/1.9.8/workflow-qualification.md) adds
multi-domain end-to-end workflow evidence without expanding the supported
target matrix. The 1.9.9
[convergence gate](../releases/1.10.0/capability-manifest.md) closed the 1.10.0 handoff,
and the frozen 1.10.0 baseline adds no target-matrix change.

## Support tiers and current evidence

| Tier | Compiler | OS / CPU | Pointer width | `Single` / `Double` / `Extended` storage | Last retained successful evidence | Exact profile |
| --- | --- | --- | --- | --- | --- | --- |
| Primary | FPC 3.2.2 | Windows x86-64 | 64-bit | 4 / 8 / 8 bytes | 1.10.0 retained evidence; full 2.0 RC qualification pending | P-Windows |
| Primary | FPC 3.2.2 | Linux x86-64 | 64-bit | 4 / 8 / 10 bytes | 1.9.6 retained evidence; full 2.0 RC qualification pending | P-Linux |
| Secondary | FPC 3.2.2 | Windows i386 | 32-bit | 4 / 8 / 10 bytes | 1.9.6 retained evidence; reruns on each change | S-Win32 |

Evidence dates and refs describe configurations that actually ran. They are
not inferred across operating systems, CPUs, pointer widths, or Unix families.
Each 2.0 release-candidate tag must produce new Linux and Windows primary
artifacts before promotion.

### Exact profiles

- **P-Windows:** normal, `-O3`, runtime-checked/heap-traced tests; all examples
  and output contracts; documentation, generated site, extracted offline HTML,
  numerical mutation, performance, and portability gates; Lazarus package;
  checksummed clean ZIP verified by the qualification driver from the extracted
  archive (no machine-level outbound block: the GitHub hosted runner
  disconnects when outbound is blocked).
- **P-Linux:** the same full profile except the Lazarus package, which is not a
  Linux release claim; checksummed clean `tar.gz` with new outbound connections
  blocked and the driver's network-isolated challenge.
- **S-Win32:** `-O2` full tests, the native ABI/binary portability probe and
  source/package audit, and the Lazarus package. This tier does not imply the
  primary documentation, benchmark, or heap-traced profile.

Primary normal checks run on pushes to `main` and pull requests targeting
`main`. The complete primary archive profiles run on demand, for each
qualifying published release tag, and weekly to detect drift before a release
candidate.

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
open the latest published archive, `mathlib-fp-docs-1.10.0/index.html`,
locally. A 2.0.0 RC archive may be evaluated separately but does not replace
the published stable documentation.

The release qualification workflows perform these same checksum, clean-
extraction, direct-source, representative-workflow, documentation, and package
checks after toolchain installation. Linux runs them with new outbound
connections blocked, and the release driver actively challenges that policy,
failing if a new outbound connection succeeds. Windows runs the same full gate
battery from the extracted clean ZIP and verifies its checksum, but it cannot
machine-block outbound traffic without disconnecting the hosted runner, so it
does not attempt that block.
