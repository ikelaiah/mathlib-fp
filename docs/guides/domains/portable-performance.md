# Portable performance and benchmark policy

Version 1.9.5 keeps native Pascal code as the correctness baseline and makes
representative timing, allocation, retained state, and logical complexity
reviewable through a checked benchmark contract.

## Checked v1.9.5 evidence

The canonical runner emits 14 `PERF|key=value` rows across dense, sparse,
matrix-free iterative, DSP, numerical-modelling, statistics, and data-analysis
workflows. Small setup-sensitive rows and larger throughput/scale rows state
their scalar kind, dimensions, cold and warmed timing semantics, setup,
tolerance, allocation metric, retained bytes, working elements, dense-shape
elements, and deterministic checksum.

`docs/performance-evidence-1.9.5.json` is the release contract. Missing rows,
checksum drift, and exact allocation/storage/complexity ceilings fail.
Same-run and matching-host prior timing ratios are advisory: a movement beyond
its band requests review rather than pretending shared-runner wall time is
mathematically exact. The human claim map and limitations are in
[`PERFORMANCE_EVIDENCE_1.9.5.md`](../../releases/1.9.5/performance-evidence.md).

## Matrix multiplication paths

`MultiplyInto` remains the portable compensated oracle.
`MultiplyBlockedInto` traverses output tiles with a caller-selected positive
block size (default `DENSE_MULTIPLY_BLOCK_SIZE = 32`) while preserving each
dot product's increasing-`K` order and compensated accumulation.

`MultiplyAutoInto` calls `SelectedMultiplyPath`. Dispatch is deterministic:
workloads at or above `DENSE_MULTIPLY_AUTO_THRESHOLD = 131072` scalar
multiply-add positions select `dmpBlocked`; smaller workloads select
`dmpPortable`. CPU model, timing, thread count, and global settings do not
affect the choice.

All four typed scalar paths—single/double real and single/double complex—have
the same validation, exact destination shape, overlap-safe temporary, and
finite-input contracts. Cross-path tests use the portable result as oracle and
also check deterministic repeat results and unchanged destinations after
validation failure.

The blocked implementation is serial. No parallel or SIMD path is stable in
1.9.5, so every supported target retains the complete portable implementation.

Applied power-of-two DSP transforms reuse the tested native radix-2 FFT kernel
for supported array sizes. The explicit portable twiddle-recurrence fallback
remains available for larger `SizeInt` ranges, and public reference/round-trip
tests cover the dispatch without changing the API.

## Reproducing benchmarks

The [benchmark runner](../../../benchmarks/BenchmarkRunner.lpr) reports:

- small-call FFT and streaming overhead;
- arbitrary-length and power-of-two transform throughput;
- direct and FFT convolution;
- medium applied-analysis workloads;
- portable, blocked, and automatic typed matrix multiplication;
- allocation/state sizes and numerical checksums; and
- the retained 1.7 scalar, geometry, vector, dense solve, SVD, and eigen
  baselines.

Run the checked contract with:

```text
python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc \
  --work-dir build-temp/performance
```

Compare timing only on the same CPU, OS, compiler, flags, power policy,
background load, scalar kind, shape, tolerance, setup, and result-validation
conditions. Release qualification retains those settings, exact-gate outcomes,
same-run comparisons, and matching-host deltas from the previous stable
release in `performance-results.json`.

## Allocation and scale guidance

- Prefer `...Into` matrix kernels when destinations can be reused.
- Reuse `TStreamingFIR`, `TOnlineStatistics`, `TLocalRandom`, and
  `TScalarKalmanFilter` state instead of concatenating an unbounded history.
- Bluestein FFT workspace is the next power of two at least `2N-1`; check this
  cost before very large arbitrary-length transforms.
- Welch and STFT retain their output plus frame-sized work. PCA and k-means++
  are in-memory dense algorithms.
- Binary interchange validates checked `QWord` sizes, caller limits, and
  platform `SizeInt` limits before result construction.

Win32 remains part of release qualification because address-space and
dimension overflow can matter before numerical throughput does.
