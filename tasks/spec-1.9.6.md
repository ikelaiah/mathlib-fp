# Spec: 1.9.6 portability and distribution

## Status

In progress on `milestone/v1.9.6`. Local qualification and exact-candidate
Linux/Windows clean-archive CI are required before tagging.

## Objective

Version 1.9.6 turns platform, archive, and offline-use claims into checked
evidence. A user must be able to identify exactly which compiler/OS/CPU/ABI
combination ran which gates, install from a checksummed source archive, use
repository or offline HTML documentation without a network, and distinguish
qualified targets from merely plausible targets.

This release preserves the frozen 1.9 public API and the complete portable
Pascal implementation.

## Required coverage

1. A versioned machine-readable target manifest records support tier,
   compiler, OS, CPU, pointer width, scalar ABI, exact checks, evidence date,
   evidence ref, and limitations for every claimed target.
2. A native Pascal probe records target identity, pointer/scalar sizes,
   endianness, locale independence, deterministic numerical invariants, and
   an exact endian-defined binary-format fixture.
3. An offline Python validator checks the target contract, native probe, source
   assumptions, dependency boundary, and package dependency metadata, then
   writes a target-specific evidence artifact.
4. Release qualification verifies the checksummed source archive and extracted
   tree, rebuilds and extracts the checksummed offline-documentation archive,
   and runs without network access in Linux and Windows workflows.
5. Primary targets run ordinary CI on each change. Complete clean-archive
   qualification runs for release candidates, manual requests, and weekly
   drift detection. Secondary targets run only the checks explicitly assigned
   to their tier.

## Evidence semantics

- A matrix cell describes only checks named in the manifest; it does not infer
  coverage from another CPU, OS, pointer width, or Unix family.
- `last_successful_evidence` and `evidence_ref` describe retained evidence.
  Candidate CI is still required when the current release ref has not run.
- `primary` means the complete release-qualification profile is required.
  `secondary` means the explicitly listed compile/test/package profile is
  required. `unqualified` targets are not support claims.
- Binary fixtures are endian-defined and ABI-independent. `Extended` precision
  is recorded rather than assumed and remains outside typed dense/sparse
  storage in the 1.9 line.

## Constraints

- Use only Free Pascal, Lazarus, and Python standard-library tooling already in
  the release environment.
- Do not add network, foreign-binary, generated-source, package-manager, or
  proprietary-runtime requirements.
- Do not claim macOS/ARM64 or another target without repeatable evidence from a
  maintainable runner.
- Preserve `docs/public-api-1.9.json` exactly.

## Success criteria

1. Every supported target has dated, ref-specific, tier-appropriate evidence
   and exact checks; unqualified targets are visibly separate.
2. Clean source and documentation archives are checksummed, extracted, and
   validated without repository-local state or network access.
3. ABI facts, numerical invariants, and binary-format invariants are checked by
   the native probe on every qualified target.
4. Filesystem, locale, endianness, floating-point, calling-convention,
   dependency, and address-space assumptions have checked outcomes or explicit
   limitations.
5. Full local qualification passes and emits portability evidence; exact
   candidate Linux/Windows archive workflows remain the final release gate.
