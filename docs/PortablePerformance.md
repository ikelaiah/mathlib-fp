# Portable performance and benchmark policy

Version 1.8 keeps native Pascal scalar code as the correctness baseline while
adding a reviewable cache-blocked dense multiplication path.

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
1.8, so every supported target retains the complete portable implementation.

## Reproducing benchmarks

The [benchmark runner](../benchmarks/BenchmarkRunner.lpr) reports:

- small-call FFT and streaming overhead;
- arbitrary-length and power-of-two transform throughput;
- direct and FFT convolution;
- medium applied-analysis workloads;
- portable, blocked, and automatic typed matrix multiplication;
- allocation/state sizes and numerical checksums; and
- the retained 1.7 scalar, geometry, vector, dense solve, SVD, and eigen
  baselines.

Compile with:

```sh
fpc -B -O3 -FcUTF8 -Fusrc -FEbuild-temp/benchmarks \
  -FUbuild-temp/benchmarks benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Compare timing only on the same CPU, compiler, flags, power policy, and
background-load conditions. Release qualification publishes those settings,
checksums, working-storage rules, and deltas from the previous stable release.
A material regression needs an explanation; CI compiles benchmarks but does
not use noisy wall-clock thresholds as a correctness test.

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
