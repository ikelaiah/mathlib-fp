# mathlib-fp 1.9.1 qualification

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Defect triage | Read-only issue triage on 2026-08-02 found no open repository reports against 1.9.0. Output-aware guide execution exposed one confirmed seeded-bootstrap defect; the correction and permanent regression are described below. |
| Five-minute first use | The README links the exact release page and direct `.tar.gz`/`.zip` downloads. Its one-screen program is extracted, compiled with only `-Fusrc`, executed, and required to print `P(Z <= 1.96) = 0.975002` in clean-archive CI. |
| Versioned web/offline/repository agreement | `docs/versions.json` identifies 1.9.1 as current and 1.9.0 as preserved. `documentation.yml` rebuilds 1.9.0 from tag `v1.9.0`, builds 1.9.1 from the release tag, deploys both, and produces the deterministic offline ZIP/checksum from that same site tree. Every HTML page and `release.json` carries its release identity. |
| Published qualification | `release-qualification.yml` creates a checksummed archive with `git archive`, extracts it into an isolated directory on Linux and Windows, runs the configurations below without network access, and publishes JSON plus per-gate logs. The Windows archive job also builds the Lazarus package. |
| API freeze | `test_api_snapshot.py` and `check_docs.py` compare all source `interface` sections with the unchanged schema-2 1.9.0 baseline: 2,880 exact owner/signature-aware declarations and 281 required public names. |

## Confirmed correction and regression

The seeded bootstrap overload used the low bits of a 32-bit LCG followed by
`mod Length(Data)`. For a length-eight input, those low bits cycle through all
eight indices, so each nominal resample was a permutation and every mean was
identical. The 95% percentile interval in the Stats guide therefore printed
`[3.2375, 3.2375]` instead of expressing sampling uncertainty.

The private implementation now uses `TLocalRandom.NextInteger`, the shared
xoshiro256** explicit-state generator and rejection-sampled bounded-integer
kernel. `TestSeededBootstrapPowerOfTwoSampleVaries` verifies that 64 resample
means vary and that the seeded 2,000-iteration interval brackets the sample
mean. Existing tests retain exact same-seed replay and verify that `RandSeed`
is unchanged. The checked guide result is `[2.7747, 3.7375]` for seed 2026.
No public declaration, seed parameter, ownership rule, or global-state contract
changed.

## Output-aware documentation evidence

`check_doc_examples.py` inventories all 225 Pascal fences, compiles and runs
the 15 self-contained programs, and verifies 13 adjacent output contracts.
Every runnable program that calls `Write`/`WriteLn` must declare either exact
output or ordered required fragments; a zero exit code alone does not pass.

`examples/output-contracts.json` additionally checks numerical values and
statuses for examples 15, 16, 22, and 23, then requires their exact final
success marker. This prevents a guide from passing after printing a limit or
failure status on an otherwise successful process exit.
`check_built_docs.py` then verifies every generated page's release metadata,
search-index target, local file link, and HTML anchor. The publishing rehearsal
checked 123 landing/release pages across the two version paths.

## Reproducible release commands

The cross-platform driver is intended to run inside an extracted source
archive:

```text
python tools/qualify_release.py --release 1.9.1 --compiler fpc \
  --lazbuild lazbuild
```

It records one JSON entry and a complete log for each gate:

- normal `-B` tests;
- optimised `-B -O3` tests;
- checked/heap-traced `-Ci -Cr -Co -Ct -Sa -gl -gh` tests, including the
  `0 unfreed memory blocks` marker;
- all 24 examples plus the four output/status/final-marker contracts;
- API snapshot, documentation unit/static/execution checks, searchable HTML,
  and offline ZIP/checksum generation;
- the Lazarus package where `lazbuild` is available;
- the representative `-O3` benchmark and its bounded-allocation failures.

## Observed release matrix

| Path | Result |
| --- | --- |
| Win64 normal | 931 tests, 0 errors, 0 failures |
| Win64 `-O3` | 931 tests, 0 errors, 0 failures |
| Win64 checked/heap-traced | 931 tests, 0 errors, 0 failures; 295,621 blocks allocated/freed and 0 unfreed |
| Examples and checked output contracts | All 24 compile and run; all four release-facing output/status/final-marker contracts pass |
| Documentation/API snapshot | 63 pages; 15 runnable programs and 13 output contracts pass; all 2,880 declarations remain unchanged |
| Offline documentation | 63 searchable pages; deterministic ZIP and SHA-256 generated locally |
| Lazarus package | Version 1.9.1 package builds with Lazarus 4.8/FPC 3.2.2 on Win64 |
| Representative benchmark | Compiles/runs at `-O3`; 100,000-entry sparse and 200,000-dimensional matrix-free cases retain linear storage, allocate no dense-shape elements, and keep warmed heap growth at zero below the 65,536-byte failure ceiling |
| Clean source archive | A disposable prospective-tree commit was archived and SHA-256 verified, extracted in isolation, and passed all 68 Win64 gates; `release-qualification.yml` repeats this on the exact release tag for Linux and Windows and publishes its authoritative checksum, JSON, and logs |

The local Win64 driver completed all 68 recorded gates on 2026-08-02 using
FPC 3.2.2, Lazarus 4.8, and Python 3.13.5 on Windows 11 x86-64. Local timing is
not a performance threshold. The exact tagged Linux/Windows archive jobs, not
this configured checkout, are the final portability and packaging evidence.
An independent publishing rehearsal extracted `docs/` from tag `v1.9.0`, built
its 59 historical pages beside the 63 current pages, verified both
`release.json` identities and the root's current/older links, and generated the
combined offline archive plus checksum. The built-site checker verified all 123
HTML pages and their local links/anchors. The disposable rehearsal tree was
then removed.

The clean candidate archive included only Git-tracked and prospective release
files, not ignored compiler output or maintainer configuration. Its temporary
repository, archive, extraction, and generated results were removed after the
68-gate run. The tag-generated checksums published by CI, rather than a mutable
pre-commit candidate digest, identify the release artifacts.

## Dependencies, compatibility, and known limitations

The normal library, tests, examples, generated documentation, and offline
archive need only FPC 3.2.2 and standard RTL/FCL units. Documentation generation
uses Python's standard library. The release paths do not download numerical
packages, load a foreign numerical DLL, contact a service, or require a licence
key.

The stable capability boundary and limitations remain those published for
1.9.0 in [CAPABILITIES.md](CAPABILITIES.md): no new algorithm family or public
convenience surface is included. In particular, none of the planned 1.9.2
beginner-learning-path or later 1.9.x/2.0 convergence work is part of this
release.
