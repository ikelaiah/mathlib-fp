# PR: Establish the 1.3.0 complex, vector, and FFT foundation

## Summary

This release-candidate PR establishes the native complex-number and
contiguous-array vector foundation for mathlib-fp 1.3.0. It adds a portable,
double-precision `TComplex` value type; real and complex vector kernels; and a
native `TComplexArray` FFT path. It retains the project’s existing
matrix-as-vector API and split real/imaginary FFT API as source-compatible
interfaces.

The work is implemented entirely in Free Pascal. It adds no wrappers, DLLs,
binary SDKs, or third-party runtime dependencies.

## Motivation

The project’s roadmap targets a freely available, native Free Pascal numerical
library with broad capability. Complex numbers, allocation-conscious vector
kernels, and a composable complex FFT representation are prerequisites for
later linear algebra, signal-processing, and numerical-method work.

Before this change, callers could use matrix-oriented vectors and split
real/imaginary FFT arrays, but there was no project-wide complex scalar type,
no contiguous real/complex array-vector facade, and no direct complex FFT
core. This PR supplies that foundation without replacing established APIs.

## Changes

### Complex arithmetic (`MathBase.Complex`)

- Adds the `TComplex` advanced record and `TComplexArray` dynamic-array type.
- Provides complex/complex and complex/real arithmetic operators, equality,
  conjugation, polar construction, magnitude, argument, and finite-value
  detection.
- Adds principal elementary functions: `CExp`, `CLog`, `CSqrt`, `CPow`,
  `CSin`, `CCos`, `CTan`, `CSinh`, `CCosh`, and `CTanh`.
- Adds inverse principal functions: `CAsin`, `CAcos`, `CAtan`, `CAsinh`,
  `CAcosh`, and `CAtanh`.
- Uses scale-normalised complex division and magnitude calculations to avoid
  avoidable intermediate overflow and underflow for finite representable
  results.
- Preserves tiny inverse-function inputs and uses scaled component,
  large-input asymptotic, or product-free forms to avoid target-sensitive
  cancellation and intermediate overflow.
- Preserves signed-zero distinction on the negative real axis for `Argument`,
  `CLog`, and `CSqrt`, so the upper and lower principal branches remain
  distinguishable.
- Defines explicit non-finite behavior for the tested cases: infinity dominates
  magnitude, indeterminate inputs propagate a NaN complex result, square roots
  preserve limiting signs, and a finite numerator divided by an infinite
  complex value produces zero.

### Array-vector kernels (`AlgebraLib.VectorKernels`)

- Adds `TVectorKit`, `TRealVector`, `TComplexVector`, and `EVectorError`.
- Adds real-vector `Add`, `Subtract`, `ElementWiseMultiply`,
  `ElementWiseDivide`, `Scale`, `Axpy`, `Dot`, `Sum`, `Mean`, `Min`, `Max`,
  `Norm2`, and `Normalize` operations.
- Adds complex-vector `Add`, `Subtract`, `Scale`, `Axpy`, `Dot`,
  `DotConjugate`, `Norm2`, and `Normalize` operations.
- Adds `...Into` variants for transformations so a caller can reuse a
  correctly sized destination array in repeated calculations. The procedures
  resize a differently sized destination and support the covered input/output
  aliasing cases.
- Uses compensated accumulation for real `Sum` and `Dot` and for the real and
  imaginary components of complex dot products.
- Uses scaled sum-of-squares accumulation for stable real and complex norms.
- Rejects paired-vector length mismatches and non-finite vector/scalar inputs.
  Empty sums, dots, and norms evaluate to zero; `Mean`, `Min`, `Max`, and
  normalization of a zero vector raise `EVectorError`.
- Keeps the established `AlgebraLib.Vectors` matrix-as-vector aliases intact
  and re-exports the new array-vector API.

### Complex FFT core (`EngineeringLib.Signal`)

- Makes the in-place radix-2 Cooley–Tukey implementation operate directly on
  `TComplexArray`.
- Retains `FFT(var RealPart, ImagPart)` as a source-compatible adapter for
  callers with split arrays.
- Adds complex-array `CalculateFFT` and `CalculateIFFT` overloads while
  retaining existing split-array convenience methods.
- Preserves existing power-of-two, zero-padding, empty-input, and inverse
  scaling contracts.

### Packaging, examples, benchmarks, and documentation

- Registers `MathBase.Complex` and `AlgebraLib.VectorKernels` in the Lazarus
  package and sets package metadata to version 1.3.0.
- Adds `examples/14_complex_vectors.pas` with inverse-function, elementwise,
  destination-reuse, Hermitian-dot, and FFT/IFFT demonstrations, and lists it
  in the examples guide.
- Extends the benchmark runner with deterministic complex arithmetic, vector
  AXPY-plus-dot, and native complex FFT cases.
- Updates the public API smoke test for `TVectorKit` and `CAsin`.
- Updates the README, changelog, API reference pages, roadmap, documentation
  index, benchmark guide, and 1.3.0 release notes.

## Public API and compatibility

- New public units: `MathBase.Complex` and `AlgebraLib.VectorKernels`.
- New public complex FFT overloads in `EngineeringLib.Signal`.
- Existing unit names, `IMatrix`/`IVector` behavior, and split real/imaginary
  FFT procedures are retained.
- `IVector = IMatrix` remains unchanged; existing matrix-backed vector callers
  do not need to migrate to the new array-vector types.
- The new APIs are additive. Callers adopting complex functions should account
  for their documented principal-value branch behavior.

## Tests added and refined

The suite grows from 798 tests in 1.2.3 to 819 tests in this release candidate.
The complex/vector foundation has 16 focused tests rather than a small number
of catch-all methods. Coverage includes:

- complex arithmetic, conjugation, polar form, and stable magnitude;
- extreme-scale division;
- signed-zero branch cuts and NaN/infinity behavior;
- ordinary, tiny, and extreme-scale values for inverse complex functions;
- real and complex vector arithmetic, compensated reductions, stable norms,
  conjugate dot products, validation, empty vectors, and destination-buffer
  resizing/aliasing;
- native complex FFT round trips, known spectra, Parseval energy preservation,
  and equivalence with the split-array adapter;
- compile-time public API smoke coverage.

## Verification performed locally

- [x] Compiled and ran the complete 819-test FPC suite on Win64 in normal,
  `-O2`, runtime-checked (`-Cr -Co -Ct -Sa`), and heap-traced (`-gh -gl`)
  modes: zero errors, zero failures, and zero unfreed blocks.
- [x] Compiled and ran the complete 819-test suite on Win32 with `-O2`: zero
  errors and zero failures.
- [x] Built the Lazarus `mathlib_fp` package successfully for Win64 and Win32.
- [x] Compiled and executed all 15 examples with `build-examples.ps1`.
- [x] Compiled with `-O3` and ran `benchmarks/BenchmarkRunner.lpr`.
- [x] Checked all local Markdown link targets.
- [x] Ran `git diff --check` without whitespace errors.

## Release gates still required

This PR prepares `release/v1.3.0`; it does not publish the release. Before
publication, follow [`RELEASING.md`](../RELEASING.md), including:

- [ ] Green Linux and Windows CI on the exact default-branch release commit.
- [ ] Clean-profile Lazarus package installation and a consumer build.
- [ ] Merge the validated release branch into the default branch.
- [ ] On `main`, finalize the README version/current-release text, changelog
  heading/date, release-note status, documentation index/roadmap, and supported
  version policy; verify CI on that exact commit, then tag it as `v1.3.0`.

## Risk and review notes

The principal risks are numerical semantics and API expectations rather than
binary compatibility:

- Complex inverse functions are principal-value functions; reviewers should
  inspect branch-cut behavior instead of assuming a globally invertible
  mapping.
- Complex division and non-finite values have deliberately specified behavior;
  review extreme scales, signed zeros, NaNs, and infinities.
- `...Into` procedures are intended for hot paths. Review destination sizing
  and aliasing behavior along with numerical results.
- The FFT core changed representation internally, so review the complex/split
  equivalence and inverse-scaling tests carefully.

The full suite, package build, and examples are more valuable than isolated
unit checks because the new types cross MathBase, AlgebraLib, and
EngineeringLib boundaries.

## Out of scope

- BLAS/LAPACK bindings, DLL-backed acceleration, or third-party dependencies.
- Dense/sparse matrix storage redesign, views, or workspace objects.
- Matrix decompositions and solvers beyond the existing API.
- Arbitrary precision, interval arithmetic, or a general tensor API.
- FFT algorithms beyond the existing radix-2 power-of-two contract.
- Tagging or publishing v1.3.0 from the release branch.

Future releases can build higher-level matrix, solver, and signal-processing
features on this compatible complex/vector foundation.
