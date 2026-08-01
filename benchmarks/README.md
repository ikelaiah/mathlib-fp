# Representative benchmarks

`BenchmarkRunner.lpr` measures the general-purpose statistics sort, geometry
convex hull, dense matrix multiplication, complex arithmetic, vector kernels,
native complex FFT, typed QR factor reuse/allocating least squares, compact
SVD/minimum norm, a full symmetric eigensystem, portable/blocked/automatic
typed multiplication, radix-2 and arbitrary-length DSP transforms,
FFT-selected convolution, online statistics, typed PCA, and seeded k-means++
on deterministic inputs.
The runner separately measures small repeated direct convolution,
independent FFT batches, bounded streaming overlap-save, and larger whole-array
DSP workloads.
The 1.9 cases add a 100,000-by-100,000 diagonal CSR solve and a
200,000-dimensional matrix-free solve. They report nonzeros, operator products,
iterations, confirmed true residuals, logical retained scalar/index slots,
sampled heap high-water increase, and the explicit zero count for full
dense-shape elements. Both warm a prepared `Into` workspace, then time 20
additional solves and measure their sampled peak heap increase and retained
heap delta from the post-warm-up baseline. The runner fails when either
repeated-solve measurement exceeds the fixed 65,536-byte regression allowance.
The vector benchmark uses a reusable destination array through `AxpyInto`, so
it measures the kernel rather than repeated dynamic-array allocation.

The dense-decomposition output reports checksums, rank/sweep information,
factor-build and result-allocation counts, and approximate peak scalar working
storage. The reuse and allocating forms use the same coefficient/RHS data.
The output also reports selected execution paths and deterministic
checksums. Streaming statistics retain six numeric accumulators regardless of
the two-million-value benchmark length.
Representative allocating paths report a deterministic result/output
allocation count or retained-state element count. The sparse repeated-solve
rows instead report `GetHeapStatus.TotalAllocated` byte deltas sampled at
solver monitor boundaries and after each warmed run. These are genuine live
heap measurements and catch retained or vector-scale transient growth; they
are not a count of every short-lived RTL allocation between sample points.

Compile and run from the repository root:

```sh
fpc -B -O3 -FcUTF8 -Fusrc -FEbuild-temp/benchmarks \
  -FUbuild-temp/benchmarks benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Timings depend on the CPU, compiler, power settings, and background load. CI
compiles the benchmark to prevent bit rot, but does not enforce timing
thresholds. Compare results only on the same machine and toolchain.
