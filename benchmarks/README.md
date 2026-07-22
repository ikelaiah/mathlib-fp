# Representative benchmarks

`BenchmarkRunner.lpr` measures the general-purpose statistics sort, geometry
convex hull, dense matrix multiplication, complex arithmetic, vector kernels,
and a native complex FFT on deterministic inputs. The vector benchmark uses a
reusable destination array through `AxpyInto`, so it measures the kernel rather
than repeated dynamic-array allocation.

Compile and run from the repository root:

```sh
fpc -B -O3 -FcUTF8 -Fusrc -FEbuild-temp/benchmarks \
  -FUbuild-temp/benchmarks benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Timings depend on the CPU, compiler, power settings, and background load. CI
compiles the benchmark to prevent bit rot, but does not enforce timing
thresholds. Compare results only on the same machine and toolchain.
