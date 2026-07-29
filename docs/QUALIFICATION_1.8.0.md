# mathlib-fp 1.8.0 qualification

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Shared numerical containers | Example 19 reuses `TDoubleArray`, `TComplexArray`, and `IDenseDoubleMatrix` across DSP, online statistics, polynomial fitting, PCA, clustering, and Kalman filtering |
| Bounded streaming state | `TOnlineStatistics` is O(1); `TStreamingFIR.StateSize = taps - 1`; `TStreamingBiquad` retains two delays; scalar Kalman retains configuration, estimate, and covariance |
| Persistence safety | Invariant/delimited/Matrix Market/binary round trips; CRC corruption, version mismatch, truncation, and oversized shape are rejected before a result is returned |
| Portable oracle | Direct DFT checks Bluestein; portable dense multiply checks blocked/automatic real and complex paths with deterministic dispatch |
| Accuracy/performance publication | Numerical budgets and the comparison with the recorded 1.7 benchmark follow below |
| Capability inventory | `capabilities.json` and `CAPABILITIES.md` publish stable workflows, scalar/shape/complexity limits, evidence locations, and open roadmap families |

## Numerical and deterministic budgets

| Workflow | Published check |
| --- | --- |
| Online statistics | mean and merge agreement `<= 1e-15`; population/sample variance against analytic fixture |
| Arbitrary double FFT | Bluestein/direct DFT and forward/inverse round trip `<= 2e-12` |
| 2-D double FFT | forward/inverse round trip `<= 2e-11` |
| Arbitrary single FFT | forward/inverse round trip `<= 2e-5` |
| Convolution | FFT/direct linear convolution agreement `<= 1e-12` |
| Welch/analytic/coherence | exact fixture frequency within `1e-12`; analytic real part `<= 2e-12`; coherent-bin coherence `> 0.99` |
| FIR/biquad | chunked FIR agrees with direct causal prefix; Butterworth unit-step output finite and converges to unit DC gain |
| Interchange | binary double/complex values and four-word random state reproduce exactly; text round trips use invariant formatting |
| Typed analysis | PCA explained ratios sum within `1e-12`; seeded clustering/splits reproduce; LDA and KD tree match fixture labels/neighbours |
| Scalar Kalman | finite likelihood, non-negative covariance, nondecreasing no-measurement forecast uncertainty, and failure-atomic invalid block |
| Blocked dense multiply | portable/blocked/automatic double and complex fixtures agree exactly; invalid block size leaves destination unchanged |

The budgets are regression contracts for the named fixtures, not universal
worst-case guarantees.

## Performance changes from 1.7.0

The following is the Win64 FPC 3.2.2 `-O3` local run. The 1.7 column is the
published prior stable run on the same target class. Windows
`GetTickCount64` resolution makes short one-shot measurements visibly
quantized; values below roughly two clock ticks are directional only.

| Workload | 1.7.0 | 1.8.0 observed | Interpretation |
| --- | ---: | ---: | --- |
| Stats merge sort, 250k | 63 ms | 47 ms | faster observation; no implementation change |
| Geometry hull, 150k | 46 ms | 32–47 ms | overlaps the baseline; no implementation change |
| Legacy dense multiply, 192² | 32 ms | 16 ms | faster observation; unchanged implementation |
| Typed odd-shape portable multiply | 31 ms | 16–31 ms | overlaps the baseline; checksum unchanged |
| QR convenience, five calls | 62 ms | 47 ms | faster observation; checksum unchanged |
| Complex arithmetic, 2m | 31 ms | 31–32 ms | unchanged within clock resolution |
| Vector AXPY+dot, 1m | 32 ms | 16–31 ms | overlaps the baseline; checksum unchanged |
| Legacy complex FFT, 262144 | 15 ms | 32 ms | apparent material regression; implementation and checksum are unchanged |

The slower legacy FFT observation is published rather than hidden. Its
implementation and deterministic checksum are unchanged, and the measurement
spans only one versus two coarse Windows clock ticks; the result is therefore
treated as a timing signal to monitor, not explained away as a code change.
Likewise, the faster rows are not used to make speedup claims.

New 1.8 representative workloads observed:

| Workload | Observed range | Deterministic checksum/result |
| --- | ---: | --- |
| Serial blocked typed multiply, 127x129x65 | 31 ms | `36.000720`, exact portable agreement |
| Applied radix-2 FFT, 262144 | 328 ms | `81.911480` |
| Applied Bluestein FFT, 100003 | 891–922 ms | `265.160385` |
| FFT-selected convolution, 65536x129 | 422–453 ms | `0.606193` |
| Online statistics, 2m | 125 ms | six retained accumulators, checksum `0.510795` |
| Typed PCA, 1024x8 | 16–47 ms | first explained ratio `0.145503` |
| Seeded k-means++, 1024x8, k=6 | 62–93 ms | 37 iterations; inertia `1986.568088` |

The new `TDSPKit` prioritizes an auditable arbitrary-length normalization and
DFT oracle; it does not replace or claim to outperform the established
power-of-two `TSignalKit.FFT`.

## Release verification

The gate commands are:

```text
lazbuild --build-mode=Release tests/TestRunner.lpi
tests/TestRunner.exe -a --format=plain
lazbuild --build-mode=Debug tests/TestRunner.lpi
tests/TestRunner.exe -a --format=plain
build-examples.ps1
lazbuild --build-all packages/lazarus/mathlib_fp.lpk
python tools/check_docs.py
python tools/build_docs.py
fpc -B -O3 -FcUTF8 -Fusrc ... benchmarks/BenchmarkRunner.lpr
```

Observed local results are finalized only after all rows pass:

| Path | Result |
| --- | --- |
| Win64 release (`-O3`) | 881 tests, 0 errors, 0 failures |
| Win64 debug checked/heap-traced | 881 tests, 0 errors, 0 failures, 0 unfreed blocks |
| Win32 optimized (`-O2`) | 881 tests, 0 errors, 0 failures |
| Examples | all 21 compile and execute; examples 19 and 20 reproduce their documented deterministic results |
| Lazarus package | version 1.8 builds on Win64 and Win32 |
| Documentation check/build | 49 searchable pages, 21 indexed examples, 126 covered public symbols |
| Representative benchmark | compiled and ran twice at `-O3`; results above |
| Working source archive | SHA-256 generated; clean extraction builds/runs all 21 examples and passes all 881 tests |
| Linux CI | retained in the workflow; remote CI is not claimed by this local change |

## Dependency and scope audit

The new stable units use only Free Pascal RTL/FCL streams and repository units.
They do not load a DLL, invoke a program, access a service or network, require
a licence key, or hide a vendor-specific kernel.

The capability inventory explicitly leaves advanced DSP design/wavelets,
expanded inference/regression/survival, forests and multivariate state space,
model/expression persistence, and parallel/SIMD dispatch unsupported. No
later-roadmap implementation is part of this release.
