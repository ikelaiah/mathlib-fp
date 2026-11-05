# v2.15.0 opt-in parallel dense multiplication

Activation evidence: on Windows x86-64, FPC 3.2.2 `-O3`, 16 logical
processors, the serial `MultiplyBlockedInto` kernel took 95–99.7% of a
fill-and-multiply workload for 256³, 512³, 768³ and 1024×256×1024 double
products (0.6 s to 23 s per product). The canonical `PERF` pipeline gains
`dense-gemm-parallel-serial` and `dense-gemm-parallel-workers4` rows on the
same prepared 192×160×176 operands.

Add `MultiplyParallelInto(A, B, Destination, WorkerCount, BlockSize)` to
`AlgebraLib.DenseKernels` for single, double, single-complex and complex dense
matrices, plus `EffectiveMultiplyWorkers`, `DenseThreadingAvailable`,
`DENSE_PARALLEL_MAX_WORKERS = 64` and
`DENSE_PARALLEL_MIN_WORK_PER_WORKER = 131072`. Existing multiply, blocked and
automatic calls, their dispatch and their results are unchanged; no call
starts threads unless the caller invokes the parallel procedure.

Contract:

- `WorkerCount` must be 1..64 and `BlockSize` positive; operands are assigned,
  finite and conformable and the destination has the exact shape. All checks
  precede the first destination write. Aliased destinations use a temporary.
- Effective workers are 1 for one requested worker, fewer than two rows, empty
  work, or no installed thread manager (Unix without `cthreads`); otherwise at
  most one per row and per 131,072 multiply-adds. Requests above the processor
  count are honoured: the caller owns oversubscription.
- Output rows are split into contiguous, near-equal partitions. The calling
  thread computes the first; each other partition runs on a short-lived RTL
  thread. Every element is produced by the serial blocked row kernel, so the
  result is bitwise equal to `MultiplyBlockedInto` with the same block size
  for all four scalar kinds.
- On x86, workers load the caller's x87 control word (and MXCSR on x86-64)
  directly, so rounding and exception masks match. The RTL `Set8087CW` and
  `SetMXCSR` helpers are avoided because they also overwrite process-wide
  defaults that the RTL restores after floating-point exceptions.
- A worker that cannot start leaves its partition to the calling thread. A
  worker exception is re-raised in the caller, after every worker has joined,
  as the original exception object; the lowest-row failure wins. Arithmetic
  faults are `EMathError` on both paths, with the same class on Windows; FPC's
  Linux SIGFPE handler classifies from sticky x87/MXCSR status flags, so the
  subclass can differ between a fresh worker and the calling thread.
- There is no pool, global setting or shared mutable state, so concurrent
  calls from caller threads are independent.

Scope controls: LU, Cholesky and batched FFT are not parallelised. This
release measures only the multiplication kernel, so it has no evidence of a
gain for those paths. No SIMD, GPU, distributed or out-of-core execution, and
no automatic parallel dispatch.

Acceptance: bitwise tests for all scalar kinds across serial-only,
two-worker, row-limited and multi-worker shapes, block sizes 1 to
`High(SizeInt)`, and worker counts up to 64. Strided views, aliased
destinations, validation-before-write, effective-worker rules, concurrent
callers, inherited rounding, and worker exception propagation after a
differently masked caller thread are all tested. `tools/check_parallel_multiply.py` runs named
square, rectangular and complex shapes at 1, 2, 4 and 8 workers in separate
processes. It records speedup, scaling efficiency, peak resident memory and
oracle accuracy, and checks the no-thread-manager fallback build. Release
qualification runs this gate for 2.15.0 and later.
