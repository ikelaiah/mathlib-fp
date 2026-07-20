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


## Current release: 1.2.3

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
