# Representative benchmarks

`BenchmarkRunner.lpr` retains the historical scalar, geometry, vector, dense
solve, decomposition, FFT/DSP, statistics, modelling, and data-analysis
measurements. Version 1.9.5 additionally emits 14 canonical `PERF|key=value`
rows for mechanically checked release evidence.

The canonical suite covers prepared portable and automatically dispatched
dense multiplication, a 100,000-by-100,000 diagonal CSR solve, a
200,000-dimensional matrix-free solve, small direct convolution, paired
65,536-value radix-2 FFT paths, adaptive integration, seeded quasi-Monte Carlo,
small and large streaming statistics, and small and large typed PCA.

Each row reports domain, scale, scalar kind, shape, cold time, warmed aggregate
time and iteration count, allocation metric, retained bytes, logical working
elements, dense-shape elements, checksum, tolerance, and setup. Sparse and
matrix-free warmed heap values are `GetHeapStatus.TotalAllocated` deltas sampled
at monitor/run boundaries; they catch retained or vector-scale growth but are
not counts of every temporary RTL allocation.

Run the release contract from the repository root:

```text
python tools/test_performance_evidence.py
python tools/check_performance_evidence.py --compiler fpc \
  --work-dir build-temp/performance
```

The validator compiles with `-B -O3 -FcUTF8`, records compiler and host details,
validates all exact ceilings and checksums, evaluates advisory same-run and
host-matched prior timing comparisons, and writes
`build-temp/performance/performance-results.json`.

To inspect the raw runner directly:

```text
fpc -B -O3 -FcUTF8 -Fusrc -Fubenchmarks \
  -FEbuild-temp/benchmarks -FUbuild-temp/benchmarks \
  benchmarks/BenchmarkRunner.lpr
./build-temp/benchmarks/BenchmarkRunner
```

Timings depend on CPU, OS, compiler, power settings, timer resolution, and
background load. Compare only matching scalar kinds, dimensions, algorithms,
tolerances, setup, and output checks. Exact correctness/storage gates fail CI;
wall-clock movements on variable runners produce an explicit review status.
The full policy and claim map are in
[`PERFORMANCE_EVIDENCE_1.9.5.md`](../docs/PERFORMANCE_EVIDENCE_1.9.5.md).
