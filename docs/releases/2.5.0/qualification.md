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

The [release qualification workflow run 38183814730](https://github.com/ikelaiah/mathlib-fp/actions/runs/38183814730)
completed for stable-promotion source commit
`f81a89652b2e5a7553af324c00d78b845f813e28`.
Its Windows x86-64 job verified the checksummed clean source ZIP and passed
the full qualification profile. Its Linux x86-64 job verified the checksummed
clean source tar archive and passed the full qualification profile with new
outbound connections blocked. Both jobs uploaded target-specific qualification
artifacts; the retained checksums are in the workflow run's artifact metadata.
The profile detected all seven declared numerical faults, including the four
2.5.0 spectral mutations for normalization, padded-boundary coverage, Hermitian
validation, and zero-allocation execution.

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
plan reference, round-trip, failure, resource, and mutation budgets passed on
the checksummed Linux and Windows source archives.

## Published tag results

The published `v2.5.0` tag resolves to exact default-branch commit
`1193b90fc3e127e7ff6b4884df48df867eb63ddc`. The [default-branch CI run
38184788877](https://github.com/ikelaiah/mathlib-fp/actions/runs/38184788877)
passed its Linux and Windows jobs on that commit before tagging. The [release
qualification run 38213375071](https://github.com/ikelaiah/mathlib-fp/actions/runs/38213375071)
then passed on the tag: Linux x86-64 passed all 126 gates and Windows x86-64
passed all 127 gates, with zero failures on either target. The jobs used FPC
3.2.2; the Windows job also used Lazarus 4.8 and passed the Lazarus package
consumer gate. The checked source archive SHA-256 values were:

- Linux tar.gz: `91ec96fbb82064e4422b0ed5085ded0d2f91ff0c658e45daac968cdefb06c9a7`
- Windows ZIP: `572439c4a5e29487de18c84d174f1a26d6f8d4a0eac73447942bce389b49cb49`

The [published release](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.5.0)
is titled `mathlib-fp 2.5.0`; its body starts with `### Added` and contains
the changelog entries without repeating the release title. The [documentation
workflow run 38213375072](https://github.com/ikelaiah/mathlib-fp/actions/runs/38213375072)
passed, including deployment. Its offline documentation asset
`mathlib-fp-docs-2.5.0.zip` is attached with a matching SHA-256 sidecar; the
archive SHA-256 is
`06905d75f52ec883b8b18fde23e41f8f2fc1a01a3f393fdfe7a4e340548d3bfc`.
The deployed [versioned documentation](https://ikelaiah.github.io/mathlib-fp/2.5.0/)
and [release index](https://ikelaiah.github.io/mathlib-fp/) both returned HTTP
200; the index identifies 2.5.0 as current and retains the 2.4.0 history link.

The GitHub source ZIP was also extracted independently. It contained `src/`,
`docs/`, `examples/`, `packages/lazarus/mathlib_fp.lpk`, `tests/`, and the
license, with no compiler outputs. The README matrix quick-start compiled
from that extracted tree with FPC 3.2.2 and ran with the documented result.
A clean Lazarus profile registered the runtime package link and successfully
compiled and ran a consumer project.
