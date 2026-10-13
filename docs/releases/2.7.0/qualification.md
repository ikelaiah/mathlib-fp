# v2.7.0 qualification record

The [release contract](../../../tasks/spec-2.7.md) adds canonical real-double
logistic and Poisson GLMs with explicit fit failures, final-information
standard errors, prediction and model diagnostics. Existing APIs remain
compatible. Release implementation and documentation are reviewed together.

## Current evidence

Full local Windows x86-64 qualification passed 133 gates on 2026-10-14,
using FPC 3.2.2 and Python 3.13.5. All 1,025 FPCUnit tests passed in normal,
`-O3`, and combined runtime-checked/heap-traced modes, with zero errors,
failures or unfreed memory blocks. The complete gate list is retained in
[`qualification-win64.json`](qualification-win64.json), and the heap summary
in [`heaptrc-win64.txt`](heaptrc-win64.txt). A separate FPC 3.2.2 Win32 `-O2`
build also passed all 1,025 tests; see
[`qualification-win32.json`](qualification-win32.json).

All 45 examples/output contracts, 24 executed documentation fragments,
13 numerical mutation cases (including three GLM mutations), current API,
capability/numerical, migration, workflow, convergence, portability, Lazarus
Win64 package and benchmark gates passed. The independent 90-digit Decimal
fixtures regenerate without external packages. Built and extracted offline
documentation checks passed 208 HTML pages. The local single-release offline
archive SHA-256 was
`3da7c1e77dc57c603aab20d3ba946f891662aab1df7217c0c21a5bde0030c109`;
the published multi-version archive is rebuilt from the final tag and has its
own adjacent checksum.

Current [CI](https://github.com/ikelaiah/mathlib-fp/actions/runs/38473814599)
passed Linux and Windows, including the hosted Win64/Win32 package and suite
checks. The [checksummed clean-archive run](https://github.com/ikelaiah/mathlib-fp/actions/runs/38473833286)
passed both Linux with network isolation and Windows from a verified ZIP. These runs
identify candidate `e5c20d9`, containing the final numerical code. Final
documentation changes are included before tagging. Tagging is gated on repeat
CI and clean-archive qualification of the final merged main commit. The
[release qualification workflow](https://github.com/ikelaiah/mathlib-fp/actions/workflows/release-qualification.yml)
retains complete hosted logs, archive checksums and target-specific artifacts.

## Performance and portability

The retained benchmark correctness, allocation and storage checks passed.
One existing allocating FFT N=65536 timing comparison is advisory `review`:
1.561x the matching-host 2.4.0 baseline, above the 1.5 review band. This is an
existing spectral benchmark, not a GLM speed claim. Measurements are in
[`performance-results.json`](performance-results.json); the target/ABI and
source/package audit are in
[`portability-results-win64.json`](portability-results-win64.json).

## Publication gates

All documentation, API/capability/numerical manifests, support policy,
package/version metadata, examples and output contracts must agree before
the tag is created. The annotated tag targets the qualified main commit.
The published release triggers immutable-tag qualification; the documentation
workflow attaches the offline HTML ZIP and SHA-256 sidecar and deploys the
versioned site. Downloaded source and documentation archives are verified
after publication. No GLM performance improvement is claimed.
