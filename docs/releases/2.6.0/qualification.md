# v2.6.0 qualification record

**Result:** The full local Windows qualification passed 130 gates, exact-main
CI passed, and GitHub-hosted checksummed Linux/Windows clean-archive
qualification passed on 2026-10-13. The [release qualification workflow]
(https://github.com/ikelaiah/mathlib-fp/actions/workflows/release-qualification.yml)
retains the hosted run artifacts and runs again for the published tag.

## Scope and source baseline

The release contract is [`../../../tasks/spec-2.6.md`](../../../tasks/spec-2.6.md).
The 2.6.0 implementation adds real-double stable SOS IIR design, frequency
response and stability diagnostics, and atomic streaming state. Existing
biquad behavior remains compatible. The retained 2.5.1 release contains no
Pascal source changes and carries 2.5.0 technical evidence.

## Local qualification

The local Windows 11 x86-64 run used Python 3.13.5 and Free Pascal 3.2.2. The
1,012-test FPCUnit suite passed in normal, `-O3`, and combined runtime-checked /
heap-traced modes with zero errors and failures; the heap-traced run reported
zero unfreed blocks. All 44 examples and output contracts passed, as did API,
documentation, mutation, migration, workflow, convergence, portability,
Lazarus Win64 package, and benchmark gates. The complete machine-readable gate
list is in [`qualification-win64.json`](qualification-win64.json), and the
three representative workflow digests are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json).
The portability probe record is
[`portability-results-win64.json`](portability-results-win64.json).

The carried-forward performance contract passed its correctness, allocation,
and storage gates. Two existing allocating FFT comparisons are advisory
`review` results: N=4096 measured 1.958x and N=65536 measured 2.066x the 2.4.0
baseline, above the 1.5 review band. These spectral-plan timings are unrelated
to the new SOS API; no SOS performance claim is made. See
[`performance-results.json`](performance-results.json).

## Publication workflow

The exact-main Linux and Windows CI jobs and both checksummed clean-archive
qualification jobs passed before tagging. The release event reruns qualification
from the immutable tag; the documentation workflow deploys the versioned site
and attaches the offline HTML archive with its SHA-256 file. These hosted
results are separate from the local Windows run above.
