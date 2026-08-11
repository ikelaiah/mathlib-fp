# mathlib-fp v1.9.6

## Portability and distribution

Version 1.9.6 makes support and offline-installation claims mechanically
reviewable. A machine-readable target manifest now records tier, compiler,
OS/CPU, pointer and scalar ABI, evidence date/ref, exact checks, and limitations
without inferring support across platforms.

A native Pascal probe checks ABI facts, byte order, locale-independent
interchange, a numerical checksum, and the exact endian-defined binary fixture.
The offline validator also audits stable units and Lazarus metadata for foreign
runtime, process, network, generated-source, and calling-convention
dependencies.

## Clean archives and offline documentation

Release qualification verifies the source archive and SHA-256, rejects
repository state and compiler output, compares the archive with its extracted
tree, and records the digest. The documentation ZIP is separately checksummed,
extracted, and checked for links and release identity. Exact Linux and Windows
archive workflows install toolchains first and then block new outbound
connections while qualification runs. The driver actively verifies that a new
outbound connection cannot be opened before accepting offline evidence.

Primary checks continue on each change; complete archive qualification also
runs weekly, manually, and for the exact release. Windows i386 has an explicit
secondary profile rather than inheriting primary claims.

See the [support matrix](SUPPORT.md), [portability evidence report](PORTABILITY_EVIDENCE_1.9.6.md),
and [machine-readable contract](portability-evidence-1.9.6.json).

## Compatibility

The 1.9 public API is unchanged. Stable capabilities remain native Free Pascal
source with no third-party runtime, service, foreign numerical library, or
network requirement. macOS/ARM64, Linux/ARM64, and other untested targets remain
visibly unqualified.

## Qualification

The local full suite and exact candidate Linux/Windows clean-archive workflows
are required before tagging. Published workflow artifacts contain
`results.json`, `portability-results.json`, logs, and the source checksum.
