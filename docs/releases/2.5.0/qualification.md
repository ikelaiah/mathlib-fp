# v2.5.0 qualification record

**Status:** Local Windows candidate qualification passed on 2026-10-12.
Cross-platform clean-archive CI, merge, stable tag, and publication remain
pending. No release has been published.

## Scope and source baseline

The release contract is [`../../../tasks/spec-2.5.md`](../../../tasks/spec-2.5.md).
The frozen v2.4.0 source commit is `17009ac` (`v2.4.0`). Its Windows x64 FFT
and legacy STFT timings are in
[`performance-baseline.md`](performance-baseline.md); candidate comparisons
are in [`performance-evidence.md`](performance-evidence.md).

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
plan reference, round-trip, failure, and resource budgets remain candidate
evidence until publication.

## Remaining release gates

| Gate | Status | Evidence |
| --- | --- | --- |
| Linux and Windows clean-archive qualification | Pending | Exact candidate commit required by `.github/workflows/release-qualification.yml` |
| Green default-branch CI | Pending | Must pass for the exact commit selected for `v2.5.0` |
| Stable tag and publication | Pending | Requires merged, qualified default-branch commit |
| Source/docs archives, checksums, versioned site | Pending | Must match the published commit and tag |

The candidate documentation manifest keeps 2.4.0 as the published stable
version. Stable promotion and its publication date occur only after the exact
commit gates pass.
