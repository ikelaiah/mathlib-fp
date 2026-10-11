# v2.4.0 spectral baseline

Captured 12 October 2026 from the immutable `v2.4.0` tag at commit
`17009ac` before changing the DSP implementation. The archive compiled with
Free Pascal 3.2.2 (`Win64` / `x86_64`) using `-B -FcUTF8` and no optimization
flag. The host reported Microsoft Windows 10.0.26300, Intel64 Family 6 Model
141 Stepping 1, GenuineIntel, and 16 logical processors.

The Pascal harness in ignored `build-temp/BaselineSpectral.pas` warmed each
operation once, then used `QueryPerformanceCounter` around the complete batch.
Each iteration used the allocating `TDSPKit.Transform` or legacy
`ShortTimeFourierTransform` API, so timings include their output allocations.
Input construction and plan preparation were outside the timed interval. The
checksums confirm each workload completed; this is a timing baseline, not an
allocation count or a claim of a universal performance advantage.

| Workload | Calls | Total ms | Checksum |
| --- | ---: | ---: | ---: |
| FFT N=64 | 500 | 4.443 | 116.15430649132 |
| FFT N=4096 | 20 | 13.849 | 874.329714401641 |
| FFT N=65536 | 5 | 75.058 | 732.427335907379 |
| FFT N=1009 | 50 | 53.727 | 1018.35451516377 |
| FFT N=10007 | 10 | 201.492 | 1142.28559199462 |
| STFT S=65536, N/H=256/128 | 10 | 250.177 | -19.0480388454264 |
| STFT S=65536, N/H=255/85 | 10 | 1948.994 | -2.28353740016121 |

These Windows timings are suitable only for later same-host review with the
same compiler, flags, workload, power policy, and background conditions. Linux
and other hosts still need their own candidate evidence.

## Matching optimized v2.4.0 reference

For the v2.5.0 comparison, the frozen `v2.4.0` source at `17009ac` was rebuilt
with FPC 3.2.2, Win64, `-B -O3 -FcUTF8`. Three independent runs used the
tracked [`LegacySpectralBaseline.lpr`](../../../benchmarks/LegacySpectralBaseline.lpr)
with the same FFT inputs and warm iteration counts as the candidate allocating
FFT calls. The table reports the median total time divided by the iteration
count. Timed sections exclude input preparation and the final checksum read.

| Workload | Calls per run | Median ms/call | Checksum |
| --- | ---: | ---: | ---: |
| FFT N=64 | 5000 | 0.005949 | -5.238336303429 |
| FFT N=4096 | 20 | 0.342890 | 30.542151194092 |
| FFT N=65536 | 5 | 7.153020 | 54.585501663111 |
| FFT N=1009 | 50 | 0.607036 | -42.094009167335 |
| FFT N=10007 | 10 | 9.749640 | 23.723690491754 |
| Legacy STFT S=65536, N/H=256/128 | 3 | 13.971499 | -0.092397057425 |
| Legacy STFT S=65536, N/H=255/85 | 3 | 118.349935 | -0.092669746594 |

The legacy STFT returned 511×256 and 769×255 matrices. The new plan pads both
ends and returned 515×256 and 775×255 matrices, respectively, so the STFT
timings are retained as context and are not treated as equivalent-work ratios.
Machine details match the host description above. Raw repeated samples and
the candidate comparison are summarized in
[`performance-evidence.md`](performance-evidence.md).
