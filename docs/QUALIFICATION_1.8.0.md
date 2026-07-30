# mathlib-fp 1.8.0 qualification

## Completion-gate evidence

| Gate | Evidence |
| --- | --- |
| Shared numerical containers | Example 19 reuses `TDoubleArray`, `TComplexArray`, and `IDenseDoubleMatrix` across DSP, online statistics, polynomial fitting, PCA, clustering, and Kalman filtering |
| Audited 1.7 completion | Example 17 and direct tests cover spline boundaries/regression, weighted/rank/scaled/bounded fitting, complex/vector AD, cubature/Monte Carlo, polynomial roots, component ODE tolerances, detailed optimisation/workspaces, two-phase LP, and QP outcomes |
| Bounded streaming state | `TOnlineStatistics` is O(1); overlap/FIR retain taps-minus-one state; biquad retains two delays; scalar and multivariate Kalman filters retain current state/covariance only |
| Persistence/expression safety | Numerical and selected-model round trips; CRC, version, kind, partial-read/truncation, resource, immutable-symbol, and evaluator-limit failures are rejected before a result/state is returned or advanced |
| Portable oracle | Direct DFT checks Bluestein; portable dense multiply checks blocked/automatic real and complex paths with deterministic dispatch |
| Accuracy/performance publication | Numerical budgets and the comparison with the recorded 1.7 benchmark follow below |
| Capability inventory | `capabilities.json` and `CAPABILITIES.md` publish stable workflows, scalar/shape/complexity limits, evidence locations, and open roadmap families |
| Cross-domain first use | Example 21 runs block DSP, paired distribution APIs, fitted standardization, a seeded forest, multivariate Kalman, model persistence, and a bounded expression without private container conversions |

## Numerical and deterministic budgets

| Workflow | Published check |
| --- | --- |
| Online statistics | mean and merge agreement `<= 1e-15`; population/sample variance against analytic fixture |
| Arbitrary double FFT | Bluestein/direct DFT and forward/inverse round trip `<= 2e-12` |
| 2-D double FFT | forward/inverse round trip `<= 2e-11` |
| Arbitrary single FFT | forward/inverse round trip `<= 2e-5` |
| Convolution | FFT/direct linear convolution agreement `<= 1e-12` |
| Block/batch DSP | overlap-add/save agree with the direct oracle across irregular blocks and restored state; batch results equal independent transforms; Haar round trip/energy use precision-specific budgets |
| Welch/analytic/coherence | exact fixture frequency within `1e-12`; analytic real part `<= 2e-12`; coherent-bin coherence `> 0.99` |
| FIR/biquad | chunked FIR agrees with direct causal prefix; Butterworth unit-step output finite and converges to unit DC gain |
| Interchange | binary double/complex values and four-word random state reproduce exactly; text round trips use invariant formatting |
| Typed analysis | PCA explained ratios sum within `1e-12`; seeded clustering/splits reproduce; LDA and KD tree match fixture labels/neighbours |
| Inference/regression | distribution CDF/quantile identities and seeded samples reproduce; reference t/ANOVA/contingency/rank tests agree; OLS reports SVD rank and logistic separation is non-identifiable |
| Hierarchy/forests/preprocessing | linkage/cut fixtures are deterministic; validation rows cannot affect fitted scales; seeded classification/regression forests reproduce predictions, OOB scores, and normalized importance |
| Scalar/multivariate Kalman | finite likelihood, symmetric non-negative covariance, innovation covariance/forecast references, and failure-atomic invalid blocks |
| Model persistence/expressions | adapter behavior survives round trip; corruption/caps fail atomically; scalar/vector/matrix expression oracles and every resource limit are exercised |
| Polynomial roots on Win32/Win64 | all real/complex roots and residuals converge; unequal deterministic starting radii avoid platform-rounding dependence for several distinct real roots |
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
| Stats merge sort, 250k | 63 ms | 62 ms | unchanged |
| Geometry hull, 150k | 46 ms | 47 ms | unchanged within clock resolution |
| Legacy dense multiply, 192² | 32 ms | 31 ms | unchanged implementation/checksum |
| Typed odd-shape portable multiply | 31 ms | 32 ms | unchanged checksum |
| QR convenience, five calls | 62 ms | 63 ms | unchanged checksum |
| Complex arithmetic, 2m | 31 ms | 31–46 ms | one run slower; unchanged implementation/checksum |
| Vector AXPY+dot, 1m | 32 ms | 31–47 ms | one run slower; unchanged implementation/checksum |
| Legacy complex FFT, 262144 | 15 ms | 31–32 ms | material timing signal; unchanged implementation/checksum |

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
| Small direct convolution, 8x3, 5000 calls | below one timer tick | 5000 result allocations / 50000 result elements; `20000.000000` |
| Batch FFT, 32x4096 | 125 ms | 32 result arrays / 131072 elements; `636.097157` |
| Streaming overlap-save, 128x1024, 129 taps | 672 ms | 128 output allocations / 128 retained elements; `-106.002862` |
| Online statistics, 2m | 125 ms | six retained accumulators, checksum `0.510795` |
| Typed PCA, 1024x8 | 16–47 ms | first explained ratio `0.145503` |
| Seeded k-means++, 1024x8, k=6 | 78–110 ms | 37 iterations; inertia `1986.568088` |

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

Observed local results after all rows passed:

| Path | Result |
| --- | --- |
| Win64 normal | 899 tests, 0 errors, 0 failures |
| Win64 release (`-O3`) | 899 tests, 0 errors, 0 failures |
| Win64 debug checked/heap-traced (`-Ci -Cr -Co -Ct -gl -gh`) | 899 tests, 0 errors, 0 failures, 0 unfreed blocks |
| Win32 optimized (`-O2`) | 899 tests, 0 errors, 0 failures |
| Examples | all 22 compile and execute; examples 17, 19, 20, and 21 reproduce their documented results |
| Lazarus package | version 1.8 builds on Win64 and Win32 |
| Documentation check/build | 50 searchable pages, 22 indexed examples, 248 covered public symbols |
| Representative benchmark | compiled and ran twice at `-O3`; results above |
| Working source archive | SHA-256 generated and verified; clean extraction builds/runs all 22 examples and passes all 899 tests |
| Linux CI | retained in the workflow; remote CI is not claimed by this local change |

## Dependency and scope audit

The new stable units use only Free Pascal RTL/FCL streams and repository units.
They do not load a DLL, invoke a program, access a service or network, require
a licence key, or hide a vendor-specific kernel.

The capability inventory explicitly leaves advanced DSP design/broader
wavelets, survival/factor/robust-covariance families, controlled/smoothed state
space, implicit stiff/mass-matrix ODEs, interior-point/general-cone work,
general model/decomposition persistence, and parallel/SIMD dispatch
unsupported. Their required validation/platform prerequisites are not
available in this release. No 1.9-or-later implementation is included.
