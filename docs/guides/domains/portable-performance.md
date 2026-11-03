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

## v2.5.0 spectral-plan evidence

v2.5.0 adds 18 `spectral_plans` rows for reusable and allocating FFT/STFT
calls. These rows use `QueryPerformanceCounter` on Windows and
`gettimeofday` on Unix, and report fractional milliseconds; existing rows
retain the established whole-millisecond timer. The focused
[`SpectralPlanBenchmarkRunner.lpr`](../../../benchmarks/SpectralPlanBenchmarkRunner.lpr)
repeats spectral-only samples without running unrelated workloads.
[`LegacySpectralBaseline.lpr`](../../../benchmarks/LegacySpectralBaseline.lpr)
compiles against frozen v2.4.0 source with FPC 3.2.2 and `-O3`. FFT allocating
timings use matching inputs, sizes, and iteration counts. Legacy and padded
STFT timings are reported separately because they process different frame
coverage.

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

The blocked implementation is serial, and `MultiplyAutoInto` never starts
threads. Every supported target retains the complete portable implementation.

## Opt-in parallel multiplication

Version 2.15.0 adds `MultiplyParallelInto(A, B, Destination, WorkerCount,
BlockSize)` for single, double, single-complex and complex matrices:

```pascal
uses
  {$IFDEF UNIX}cthreads,{$ENDIF} // first, so Unix programs can start threads
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels;

MultiplyParallelInto(A, B, Destination, 4);  // same bits as MultiplyBlockedInto
```

- **Caller-chosen workers.** `WorkerCount` must be in
  1..`DENSE_PARALLEL_MAX_WORKERS` (64). Counts above the processor count are
  honoured, so choose a count no larger than your available processors.
  There is no global setting or thread pool. Concurrent calls from your own
  threads are independent.
- **Bitwise determinism.** Output rows are split into contiguous partitions,
  and each element uses the serial blocked kernel's increasing-`K`
  compensated sum. The result therefore equals `MultiplyBlockedInto` with the
  same block size, bit for bit, for every scalar kind and worker count.
- **Serial fallback.** `EffectiveMultiplyWorkers(Rows, Inner, Columns,
  Requested)` reports the workers a call will use. It returns 1 for one
  requested worker, a product with fewer than two rows or no work, and a
  program without a thread manager. Otherwise it allows at most one worker
  per row and per `DENSE_PARALLEL_MIN_WORK_PER_WORKER` (131,072)
  multiply-adds, so small products never pay thread start-up costs. A Unix
  program without `cthreads` therefore runs serially;
  `DenseThreadingAvailable` reports this.
- **Calling thread participates.** The calling thread computes the first
  partition and each other partition runs on a short-lived worker. If a worker
  cannot start, the calling thread computes its rows.
- **Floating-point state.** On x86, workers load the caller's x87 control word
  (and MXCSR on x86-64), so rounding and exception masks match. A worker
  exception is re-raised in the caller after all workers finish; when several
  partitions fail, the lowest-row failure is raised. An arithmetic fault such
  as overflow raises an `EMathError` on both paths. On Windows the class
  matches the serial kernel. On Linux, FPC chooses the class from sticky
  status flags, so the same overflow may surface as `EOverflow` in a worker
  and `EInvalidOp` on the calling thread. Catch `EMathError` rather than a
  specific subclass.
- **Validation and memory.** Validation matches `MultiplyBlockedInto` and
  happens before any destination write. Aliased destinations use one
  temporary. The parallel path adds only per-worker bookkeeping and thread
  stacks, with no extra matrix-sized storage.

Only multiplication is parallel in 2.15.0. Dense LU, Cholesky and batched FFT
remain serial because no benchmark evidence yet shows a gain for them.

### Measured scaling

`tools/check_parallel_multiply.py` runs named shapes at 1, 2, 4 and 8 workers,
one process per row. It records speedup, scaling efficiency, peak resident
memory and accuracy. On the 2.15.0 Windows x86-64 qualification host (16
logical processors, FPC 3.2.2 `-O3`), speedups were about 1.8–2.0× with 2
workers, 3.2–4.0× with 4 and 4.1–5.1× with 8. Those figures come from a
256³ double product, a 384×128×320 double product and a 160³ complex
product. Every run was bitwise identical to the serial kernel. See the
[release evidence](../../releases/2.15.0/parallel-multiply-win64.json).
These figures describe that host only; they are not a universal speedup claim.
Run the gate on your own hardware:

```text
python tools/check_parallel_multiply.py --compiler fpc
```

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
