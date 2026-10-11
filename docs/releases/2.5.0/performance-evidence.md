# mathlib-fp 2.5.0 performance evidence

The checked contract is [`performance-evidence.json`](performance-evidence.json).
The checker validates all 14 existing benchmark rows and 18 spectral-plan rows
for deterministic checksums, measured allocation calls, retained numeric
storage, and logical working elements. The captured Win64 result is
[`performance-results.json`](performance-results.json); the v2.4.0 reference
method and timings are in [`performance-baseline.md`](performance-baseline.md).
Three-run raw samples and per-call medians are preserved in
[`performance-samples.json`](performance-samples.json).

## Host and method

The candidate was compiled with Free Pascal 3.2.2 for Win64 using
`-B -O3 -FcUTF8`. The host was Windows 11 build 26300, x86-64, Intel64 Family
6 Model 141 Stepping 1, GenuineIntel, with 16 logical processors. Spectral
timings use `QueryPerformanceCounter`, report fractional milliseconds, and
exclude deterministic input preparation and result-checksum reads. The
canonical benchmark runner's pre-existing rows retain their documented
whole-millisecond timer.

Each spectral case has a measured plan construction/destruction batch and a
warmed batch. Three focused runs were captured for repeatability; the tables
below show median milliseconds per warmed call. The FFT baseline uses three
matching runs compiled against frozen v2.4.0 source, with identical inputs,
iteration counts, and flags. The STFT baseline is not directly compared because
the legacy API drops partial edges while the new plan pads and reconstructs the
complete requested sample range.

## FFT results

| N | `ExecuteInto` ms/call | Allocating `Execute` ms/call | v2.4 allocating ms/call | Allocating ratio |
| ---: | ---: | ---: | ---: | ---: |
| 64 | 0.005263 | 0.005408 | 0.005949 | 0.909 |
| 4096 | 0.523615 | 0.523870 | 0.342890 | 1.528 |
| 65536 | 10.825440 | 11.285280 | 7.153020 | 1.578 |
| 1009 | 0.458180 | 0.457322 | 0.607036 | 0.753 |
| 10007 | 9.578060 | 9.776370 | 9.749640 | 1.003 |

The candidate's allocating FFT path is close to v2.4 for N=64 and 10007,
faster in these samples for N=1009, and slower for N=4096 and 65536. The full
qualification run measured ratios of 1.838 and 1.766 for those last two cases;
the 1.5 review band marks them for review. Timing is advisory and does not fail
the exact resource gates. This release
sets a fixed-geometry reuse and zero-allocation contract for valid prepared
`Into` calls. It makes no general FFT speedup claim. Users should select an
API based on repeated-call behavior and their own workload.

The five FFT `ExecuteInto` rows measured exactly zero allocator GetMem,
AllocMem, or ReAllocMem calls in their warmed batches. Allocating calls
measured one returned-array allocation per call. Reported exact owned payload
bytes were 2,048 (N=64), 131,072 (4096), 2,097,152 (65536), 114,448 (1009),
and 1,732,976 (10007). Bluestein workspace counts were 2,048 for N=1009 and
32,768 for N=10007.

## STFT results

| S / N / H | Operation | `Into` ms/call | Allocating ms/call | Allocations per three-call batch (`Into` / allocating) |
| --- | --- | ---: | ---: | ---: |
| 65536 / 256 / 128 | Analyze | 19.821932 | 20.170099 | 0 / 9 |
| 65536 / 256 / 128 | Synthesize | 28.380035 | 28.787900 | 0 / 3 |
| 65536 / 255 / 85 | Analyze | 90.463125 | 89.845072 | 0 / 9 |
| 65536 / 255 / 85 | Synthesize | 100.509033 | 101.292399 | 0 / 3 |

All four valid `Into` paths measured zero allocator calls. The exact retained
payload was 3,700,736 bytes for 256/128 and 4,773,712 bytes for 255/85; dense
output sizes were 131,840 and 197,625 complex elements. Three allocating
analysis calls made nine measured allocator calls, while three allocating
synthesis calls made three. Independent reconstruction and numerical budgets
are covered by the focused test suite and the public example.

## Reproduction and limitations

Run the baseline against the frozen source tree with:

```powershell
fpc -B -O3 -FcUTF8 -Fubuild-temp/v240/src -Fubuild-temp/v240/benchmarks `
  -FUbuild-temp/legacybaseline -FEbuild-temp/legacybaseline `
  benchmarks/LegacySpectralBaseline.lpr
```

Run three spectral candidate samples with:

```powershell
fpc -B -O3 -FcUTF8 -Fusrc -Fubenchmarks `
  -FUbuild-temp/spectralbench -FEbuild-temp/spectralbench `
  benchmarks/SpectralPlanBenchmarkRunner.lpr
```

Full manifest validation is performed by `tools/check_performance_evidence.py`
using `docs/releases/2.5.0/performance-evidence.json`. These measurements are
specific to this Windows host and compiler. Linux and other supported target
performance evidence remains pending exact-commit CI; no cross-platform timing
claim is made.
