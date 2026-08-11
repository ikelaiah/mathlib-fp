# Implementation plan: 1.9.6 portability and distribution

## Overview

Add a release-owned portability evidence contract around the existing clean
archive and qualification machinery. The contract will be validated by an
offline Python tool and a native Pascal probe, then produced from ordinary CI,
scheduled complete qualification, and exact release-candidate archives.

## Architecture decisions

- Keep target facts and required gates in
  `docs/portability-evidence-1.9.6.json`; generated per-run observations remain
  CI/local artifacts rather than universal source-controlled claims.
- Use a small native Pascal probe for ABI, endianness, numerical, locale, and
  binary-format observations. Use Python only to compile/run it, validate the
  contract, audit source/package assumptions, and serialize evidence.
- Reuse `tools/qualify_release.py` for full workflows. Add explicit verified
  source-archive inputs and clean-tree/network-isolation assertions rather than
  creating a second qualification path.
- Preserve the frozen 1.9 public API and add no runtime dependency.

## Dependency graph

```text
target/evidence contract ──> validator tests ──> Pascal portability probe
           │                        │                       │
           └──────────────> source/package audit <─────────┘
                                    │
                                    v
                       clean archive qualification
                                    │
                                    v
                  CI schedule, support matrix, release docs
```

## Task list

1. Define the v1.9.6 target, ABI, invariant, audit, and evidence-result
   contracts.
2. Add failing tests for malformed target manifests, mismatched ABI/binary
   observations, forbidden dependencies/calling conventions, and incomplete
   evidence.
3. Add the native Pascal probe and offline validator; make focused tests green
   and validate the current Windows x86-64 host.
4. Extend release qualification to verify source archive/checksum inputs,
   clean-tree contents, network-isolation acknowledgement, extracted offline
   documentation, and retained portability results.
5. Update primary/secondary CI profiles, add weekly complete qualification,
   enforce network isolation during archive qualification, and publish
   target-specific evidence artifacts.
6. Update the support matrix, portability evidence report, installation and
   releasing guidance, capability inventory, changelog, release/PR/
   qualification notes, package/workflow/version metadata, and roadmap.
7. Run focused checks and complete local qualification, review all five quality
   axes, resolve required findings, and record the final local evidence.

## Checkpoints

### After tasks 1-3

- Contract tests reject unqualified claims and mismatched native observations.
- The current host produces a complete target evidence artifact offline.
- Source and package audits cover the roadmap assumption categories without
  changing a public declaration.

### After tasks 4-5

- Qualification rejects an unverified or dirty archive context when clean
  archive mode is required.
- Source and offline-documentation archives are both checksummed, extracted,
  and exercised.
- Ordinary primary CI, secondary tier checks, weekly full qualification, and
  candidate/release qualification have explicit non-overstated scopes.

### After tasks 6-7

- All current-release identity and documentation checks agree on 1.9.6.
- Local normal, optimized, checked/heap, examples, docs, package, benchmark,
  historical evidence, portability, and archive gates pass.
- The final diff has no unresolved correctness, architecture, security,
  performance, or documentation finding.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A support table overstates CI coverage | High | Validate every cell against a manifest target and exact named gate profile. |
| Hosted jobs cannot prove offline use | High | Install tools first, then apply OS outbound-network blocking around extracted-archive qualification and record the isolation policy. |
| ABI probing accidentally treats `Extended` as uniform | High | Record `SizeOf(Extended)` per target and document target-specific precision. |
| Static dependency audit creates noisy false positives | Medium | Limit hard failures to explicit foreign/runtime/network mechanisms and retain reviewed findings for broader assumptions. |
| Archive checks only exercise a maintainer tree | High | Require archive/checksum paths, verify the digest and extracted-root shape, and reject `.git` or compiler artifacts in clean mode. |

## Scope decision

The milestone qualifies existing portable behavior and distribution paths. It
does not add macOS/ARM64 claims, change numerical algorithms, or expand the
public API.
