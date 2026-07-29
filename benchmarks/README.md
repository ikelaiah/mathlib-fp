# Representative benchmarks

`BenchmarkRunner.lpr` measures the general-purpose statistics sort, geometry
convex hull, dense matrix multiplication, complex arithmetic, vector kernels,
native complex FFT, typed QR factor reuse/allocating least squares, compact
SVD/minimum norm, a full symmetric eigensystem, portable/blocked/automatic
typed multiplication, radix-2 and arbitrary-length DSP transforms,
FFT-selected convolution, online statistics, typed PCA, and seeded k-means++
on deterministic inputs.
The vector benchmark uses a reusable destination array through `AxpyInto`, so
it measures the kernel rather than repeated dynamic-array allocation.

The dense-decomposition output reports checksums, rank/sweep information,
factor-build and result-allocation counts, and approximate peak scalar working
storage. The reuse and allocating forms use the same coefficient/RHS data.
The 1.8 output also reports selected execution paths and deterministic
checksums. Streaming statistics retain six numeric accumulators regardless of
the two-million-value benchmark length.

Compile and run from the repository root:

```sh
fpc -B -O3 -FcUTF8 -Fusrc -FEbuild-temp/benchmarks \
  -FUbuild-temp/benchmarks benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Timings depend on the CPU, compiler, power settings, and background load. CI
compiles the benchmark to prevent bit rot, but does not enforce timing
thresholds. Compare results only on the same machine and toolchain.
