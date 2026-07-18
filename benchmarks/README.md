# Representative benchmarks

`BenchmarkRunner.lpr` measures the general-purpose statistics sort, geometry
convex hull, and dense matrix multiplication on deterministic inputs. The first
two cases guard the release's replacement of quadratic sorting paths with
O(n log n) algorithms.

Compile and run from the repository root:

```sh
fpc -B -O3 -FcUTF8 -Fusrc -FEbuild-temp/benchmarks \
  -FUbuild-temp/benchmarks benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Timings depend on the CPU, compiler, power settings, and background load. CI
compiles the benchmark to prevent bit rot, but does not enforce timing
thresholds. Compare results only on the same machine and toolchain.
