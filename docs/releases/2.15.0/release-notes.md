### Added

- Added opt-in `MultiplyParallelInto` for single, double, single-complex and complex dense matrices. Callers choose 1–64 workers, the calling thread computes one row partition, and results are bitwise identical to `MultiplyBlockedInto` with the same block size.
- Added `EffectiveMultiplyWorkers` and `DenseThreadingAvailable`. Small, single-row and empty products, and Unix programs without `cthreads`, run on one worker without starting threads.
- Added a large-product evidence gate that reports speedup, scaling efficiency, peak memory and accuracy on named shapes. Also added canonical serial and four-worker benchmark rows, a parallel multiplication example, and tests for views, aliasing, concurrent callers, rounding inheritance and worker exception propagation.

### Compatibility

- Existing multiply, blocked and automatic calls keep their dispatch and results; no ordinary call starts threads. Workers copy the caller's x87/MXCSR control state without changing RTL process defaults, and worker exceptions are re-raised in the caller as `EMathError` arithmetic faults (the same subclass on Windows; on Linux FPC may classify an overflow differently on the calling thread). LU, Cholesky and FFT remain serial.
