# v2.15.0 review notes

It adds opt-in parallel dense matrix multiplication with caller-chosen workers
and results bitwise identical to the serial kernel.

The serial blocked kernels now delegate to row-range routines that the
parallel path reuses. Existing multiply, blocked and automatic calls are
otherwise unchanged and never start threads.

Five-axis review covered:

- Correctness: each element keeps the increasing-`K` compensated sum, so row
  partitions reproduce the serial bits for all scalar kinds. Tile ends avoid
  `Start + BlockSize` overflow. Workers load the caller's x87 control word and
  MXCSR directly. The RTL setters were avoided because they overwrite process
  FPU defaults, which a regression test now covers.
- Compatibility: the API change is additive (eight declarations). Serial
  checksums and dispatch are unchanged. There is no global configuration, pool
  or automatic parallel path.
- Failure handling: all validation precedes the first destination write. A
  worker that cannot start leaves its rows to the calling thread. Worker
  exceptions are re-raised in the caller after every worker has been joined.
  A Unix program without `cthreads` falls back to one worker before any thread
  call.
- Resource use: workers are bounded to 64, one per row, and one per 131,072
  multiply-adds. There is no extra matrix-sized storage beyond the existing
  alias temporary. Heap-traced tests report zero unfreed blocks.
- Maintainability and evidence: one row kernel per scalar kind is shared by
  the serial and parallel paths. The evidence gate runs one process per
  measurement and fails only on exact contracts; slow timings are flagged for
  review.

Supported-platform and release evidence is retained in
[qualification.md](qualification.md). Speedups are reported for named shapes
on the qualification host only.
