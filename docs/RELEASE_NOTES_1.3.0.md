# mathlib-fp 1.3.0 release notes

> Status: development branch `release/v1.3.0`; this document will be finalised
> when the release is tagged.

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
buffers in repeated computation.

## Numerical behavior

Complex division is scale-safe for finite extreme-scale operands whenever the
result is representable. Principal `CLog` and `CSqrt` distinguish the upper and
lower negative-real-axis branches through signed zero. Tests cover extreme
scales, branches, NaN/infinity behavior, inverse functions, array kernels, and
complex FFT round trips.

## Compatibility

No existing public identifier was removed or renamed. `IVector = IMatrix` and
the split real/imaginary FFT procedures remain supported. The new complex and
array-vector APIs are additive.

## Validation

The development branch contains 815 passing tests, a Lazarus package build,
15 compiling examples, and representative benchmarks for complex arithmetic,
vector kernels, and the native complex FFT.
