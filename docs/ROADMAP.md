# Roadmap

mathlib-fp aims to become a comprehensive, freely available numerical-
computing library implemented directly in Free Pascal.

The project is built on the following non-negotiable foundations:

- MIT-licensed source code that compiles with Free Pascal;
- native Object Pascal implementations rather than wrappers around
  implementations written in another language;
- no required DLLs, binary SDKs, or third-party runtime libraries;
- correct, portable implementations before architecture-specific optimisation;
- independently usable units rather than a mandatory monolithic import.


## Release candidate: 1.3.0

Version 1.3.0 establishes the complex-number and vector foundation required by
the next generation of algebra and signal-processing features. It preserves
the existing matrix-as-vector API: an `IMatrix` with one row or one column
remains an `IVector` and keeps its `DotProduct`, `CrossProduct`, and
`Normalize` methods.

The new foundation adds a complementary, allocation-light array API rather
than replacing matrices:

- `MathBase.Complex` supplies the scalar `TComplex` type, scale-safe division,
  signed-zero-aware principal functions (including inverse trigonometric and
  hyperbolic functions), and `TComplexArray`;
- `AlgebraLib.VectorKernels` supplies real and complex array-vector kernels
  (compensated reductions, elementwise operations, stable norms, scaling,
  AXPY-style combination, normalization, and reusable destination buffers);
- `AlgebraLib.Vectors` remains the compatibility-oriented entry unit and
  re-exports the new array-vector types and kernel facade;
- signal processing uses `TComplexArray` as the FFT core while retaining its
  existing split real/imaginary procedures as source-compatible adapters.

### Completed 1.3.0 scope

- Complex arithmetic has documented branch, zero, non-finite, and
  overflow-resistance behavior with reference and identity tests.
- Vector kernels validate dimensions and finite input, define empty-vector
  results, and use scale-safe norm accumulation.
- Every new public unit has API documentation, a runnable example, package
  registration, focused tests, and Linux/Win64/Win32 CI coverage configured.
- Complex arithmetic, vector kernels, and FFTs have representative benchmarks
  and public API smoke coverage.
- Existing `IMatrix` vector behavior remains source-compatible and covered by
  the existing algebra test suite.

The implementation is ready for the release checklist in
[`RELEASING.md`](../RELEASING.md): final cross-platform CI, clean-profile
package installation, and release-mode/runtime-checked test runs. Publication
then merges the release branch, finalizes release metadata on `main`, verifies
that exact commit, and tags it.

## Current published release: 1.2.3

Version 1.2.3 is a correctness and robustness release. It does not add a new
domain. It concentrates on the operations already exposed:

- improved special-function accuracy, convergence handling, and tail behavior;
- removed overflow, underflow, and cancellation from representable results;
- corrected formulas whose happy-path tests masked mathematical defects;
- expanded reference-value, identity, residual, property, and extreme-scale
  tests;
- kept public signatures source-compatible wherever correctness permits.

## Development order

The project grows in three layers. Each layer remains useful on its own.

1. **Reliable scalar kernel** — elementary and special functions, probability
   tails, numeric limits, stable reductions, and shared validation contracts.
2. **Matrix/vector engine** — contiguous dense storage, complex values,
   reusable workspaces, sparse formats, views, decompositions, solvers, and
   expression-friendly APIs implemented in Pascal.
3. **Algorithm breadth** — fitting, interpolation, FFT/convolution, statistics,
   optimization, differential equations, and data-analysis algorithms built on
   the same kernels.

This order is deliberate: adding many entry points before the scalar and
linear-algebra foundations are dependable would multiply numerical defects.

## Quality contract

An operation is not considered complete merely because it returns a value for
a typical example. Depending on the algorithm, it should also have:

- published reference values across small, ordinary, and extreme scales;
- algebraic/property checks and residual or reconstruction tests;
- explicit dimension, finite-value, and mathematical-domain validation;
- scale-aware stopping criteria and a visible non-convergence outcome;
- defined NaN, Infinity, empty-input, singular, and degenerate behavior;
- deterministic seeded behavior for randomized algorithms;
- Win32, Win64, and Unix compilation coverage where supported by CI;
- a benchmark that measures performance without weakening correctness tests.

## Capability direction

The long-term target is broad numerical coverage, including:

- dense and sparse real/complex matrix and vector arithmetic;
- BLAS-like kernels, LU/QR/LQ/Cholesky/SVD/eigen decompositions, condition
  estimates, and direct/iterative solvers;
- interpolation, approximation, linear and nonlinear fitting;
- FFT, convolution, correlation, filtering, and spectral analysis;
- descriptive/inferential statistics and probability distributions;
- scalar, linear, quadratic, constrained, nonlinear, and derivative-free
  optimization;
- numerical integration, root finding, ODE solvers, and special functions;
- clustering, regression, classification, time-series, and geometry tools.

These capabilities need not map one-to-one to new domains. New units and types
should follow useful API boundaries, and new domains should be introduced only
when the existing foundations and naming model cannot express the capability
cleanly.

## Performance direction

The baseline stays pure Pascal and portable. Performance work should proceed
from algorithm choice and data layout to cache blocking, allocation reduction,
threading, and finally optional compile-time CPU-specific kernels written as
part of this source tree. A fast path must preserve the portable path's tested
semantics, and callers must not need an external DLL to obtain a complete
library.
