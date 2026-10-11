# v2.5.0 qualification record

**Result:** Local Windows and GitHub-hosted Linux/Windows clean-archive
qualification passed on 2026-10-12.

## Scope and source baseline

The release contract is [`../../../tasks/spec-2.5.md`](../../../tasks/spec-2.5.md).
The frozen v2.4.0 source commit is `17009ac` (`v2.4.0`). Its Windows x64 FFT
and legacy STFT timings are in
[`performance-baseline.md`](performance-baseline.md); 2.5.0 comparisons
are in [`performance-evidence.md`](performance-evidence.md).

## Cross-platform clean-archive results

The [release qualification workflow run 38182263994](https://github.com/ikelaiah/mathlib-fp/actions/runs/38182263994)
completed for source commit `ecfc68434e7040a5b1919eacbf144039eb65d457`.
Its Windows x86-64 job verified the checksummed clean source ZIP and passed
the full qualification profile. Its Linux x86-64 job verified the checksummed
clean source tar archive and passed the full qualification profile with new
outbound connections blocked. Both jobs uploaded target-specific qualification
artifacts; the retained checksums are in the workflow run's artifact metadata.

## Local Windows results

The local qualifier passed all 127 gates on Windows 11 x86-64 with Python
3.13.5 and Free Pascal 3.2.2. The 998-test FPCUnit suite passed in normal,
optimized, and checked-heap modes. Example builds and output contracts,
documentation/source checks, the versioned site and offline archive, numerical
mutation checks, migration/workflow/convergence/portability evidence, the
Win32 Lazarus package consumer, and the complete benchmark manifest passed.

Machine-readable local results are retained in
[`qualification-win64.json`](qualification-win64.json), SHA-256
`fa1b5df785b595e27391640a3a3b72acdca6433422527f811ef136347456c73f`. The three
representative workflows and their output digests are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).
The versioned offline documentation archive passed validation, with its
checksum retained alongside the local ZIP. The additional full-site build of
all 18 current and retained release paths also passed, with its checksum
retained alongside that ZIP.

All benchmark numerical, allocation, retained-storage, and complexity gates
passed. Timing status is advisory `review`: the full benchmark run measured
1.838× the v2.4.0 median for allocating FFT N=4096 and 1.766× for N=65536,
above the 1.5 review band. The warmed `ExecuteInto` rows still measured exactly
zero allocation calls. The measured tradeoff is recorded in the performance
report; no general FFT speedup claim is made. Machine-readable results are in
[`performance-results.json`](performance-results.json).

The three unchanged stable numerical-evidence families are carried forward
from 2.4.0 in [`numerical-evidence.json`](numerical-evidence.json). New spectral
plan reference, round-trip, failure, and resource budgets passed on the
checksummed Linux and Windows source archives.
