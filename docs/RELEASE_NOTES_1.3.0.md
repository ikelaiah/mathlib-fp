# mathlib-fp 1.3.0 release notes

**Release date:** 2026-07-23

## Highlights

- `MathBase.Complex` introduces the value-record `TComplex`, `TComplexArray`,
  stable arithmetic, principal elementary functions, and inverse complex
  trigonometric and hyperbolic functions.
- `AlgebraLib.VectorKernels` introduces real and complex contiguous-array
  kernels through `TVectorKit`. The existing matrix-as-vector API remains
  source-compatible.
- `EngineeringLib.Signal` now uses `TComplexArray` as its FFT core while
  retaining split real/imaginary overloads for existing callers.

## Vector kernels

Real vectors now provide elementwise multiplication/division, compensated
`Sum` and `Dot`, `Mean`, `Min`, `Max`, stable `Norm2`, and normalization.
Complex vectors provide non-conjugating and Hermitian dot products. Allocating
transformations have `...Into` variants so callers can reuse destination
buffers in repeated computation. Inputs must be finite and paired vectors must
have equal lengths. Empty sums, dots, and norms are zero; `Mean`, `Min`,
`Max`, and normalization of a zero vector raise `EVectorError`.

## Numerical behavior

Complex division is scale-safe for finite extreme-scale operands whenever the
result is representable. Complex magnitude, exponential, and square root
functions handle tested infinity and NaN limits without avoidable invalid
operations. Principal `CLog`, `CSqrt`, and inverse functions distinguish branch
sides through signed zero. Inverse functions preserve tiny first-order values
and use scaled component or asymptotic large-input forms that avoid
target-sensitive `z*z` cancellation. Tests cover reference values, extreme
scales, branches, NaN/infinity behavior, array kernels, and complex FFT round
trips.

For a full complex inverse transform, call `FFT(Data, True)` on a
`TComplexArray`. The `CalculateIFFT` convenience overloads continue to return
real-valued output arrays by design.

## Compatibility

No existing public identifier was removed or renamed. `IVector = IMatrix` and
the split real/imaginary FFT procedures remain supported. The new complex and
array-vector APIs are additive.

See [MathBase](MathBase.md), [AlgebraLib](AlgebraLib.md), and
[EngineeringLib](EngineeringLib.md) for API details, or run
[`examples/14_complex_vectors.pas`](../examples/14_complex_vectors.pas) for a
compact end-to-end example.

The example shows inverse complex functions, elementwise real-vector
arithmetic, `AxpyInto` destination reuse, a Hermitian dot product, and an
in-place complex FFT/IFFT round trip.

## Validation

The release contains 819 passing tests in Win64 normal, optimized,
runtime-checked, and heap-traced local builds, with zero unfreed blocks; the
optimized Win32 suite also passes. The Lazarus package builds for Win64 and
Win32, all 15 examples compile and run, and representative benchmarks cover
complex arithmetic, vector kernels, and the native complex FFT. Linux and
Windows CI both pass. The reusable release process is documented in
[`RELEASING.md`](../RELEASING.md).

See the [1.3.0 changelog](../CHANGELOG.md#130---2026-07-23) for the complete
release entry.
