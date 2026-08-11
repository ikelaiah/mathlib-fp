# PR notes: v1.9.6 portability and distribution

## Review boundary

This change adds evidence and qualification infrastructure; it does not change
the public API or numerical algorithms.

- Add a versioned target/support contract, native Pascal ABI/binary probe, and
  offline Python validator/source-package audit.
- Require verified clean source archives and extracted checked offline HTML in
  release qualification.
- Run primary checks on changes, secondary Win32 checks at their documented
  scope, and complete Linux/Windows archive qualification weekly and for exact
  candidates/releases.
- Publish support, audit, limitation, installation, release, and qualification
  documentation for 1.9.6.

## Required review checks

1. Tests reject missing target evidence, inferred unqualified ABIs, mismatched
   native observations, unsafe archives, compiler outputs, and checksum errors.
2. The native fixture remains byte-identical and locale-independent on each
   qualified target while ABI-dependent `Extended` storage is explicit.
3. Network blocking is applied only after toolchain installation and restored
   before artifact publication.
4. The frozen 1.9 public snapshot remains exact and no stable source adds a
   foreign runtime dependency.

## Explicit exclusions

- No macOS/ARM64 or Linux/ARM64 support claim without maintained runner
  evidence.
- No new package manager, generated source, public declaration, CPU-specific
  numerical kernel, or mandatory external tool.
- No claim that retained `v1.9.5` evidence replaces exact 1.9.6 candidate CI.
