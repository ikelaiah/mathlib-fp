# Typed dense foundation design decisions (1.5.0)

This note fixes the public names and contracts used by the 1.5.0
implementation. It is intentionally narrower than the later 1.6.0
decomposition and sparse-algebra plan.

## Public surface

The additive API lives in three units:

- `AlgebraLib.DenseMatrices` — scalar-specific matrix handles, factories,
  checked access, views, copies, and compatibility conversions;
- `AlgebraLib.DenseKernels` — real/complex arithmetic, explicit matrix and
  elementwise multiplication, transpose/conjugation, reductions, and `Into`
  procedures;
- `AlgebraLib.DenseSolvers` — pivoted LU, Cholesky, reusable factors, and
  direct `Solve`.

The four supported scalar paths are named `Single`, `Double`,
`TSingleComplex`, and `TComplex`. Their matrix handles are
`IDenseSingleMatrix`, `IDenseDoubleMatrix`,
`IDenseSingleComplexMatrix`, and `IDenseComplexMatrix`. Factory class names
have the same spelling without the leading `I`.

Allocation-free 2x2 value records use the `TSmall*Matrix2` family. Their
matching `...Batch` dynamic arrays provide contiguous collections without
changing the fixed record layout. Operators on these records are ordinary
matrix expressions, while general-size handles use the named allocating and
`Into` kernels so allocation remains visible.

## Ownership, aliasing, and mutation

- Factory results own a 32-byte-aligned allocation and release it when the last
  matrix or view handle goes out of scope.
- Assigning an interface handle aliases the same matrix object.
- `View`, `RowView`, `ColumnView`, and `DiagonalView` are mutable aliases.
  They retain their backing storage owner; no public view borrows an
  untracked pointer. A write through a view is visible through every alias.
- `Clone` is the explicit deep-copy operation. Compatibility conversions are
  also deep copies.
- `DataPointer` is available only for a non-empty contiguous handle and is
  valid while a handle retaining that storage remains alive. Strided views
  return `nil`.
- `StorageIdentity` is an opaque comparison token shared by every view of one
  backing allocation. It exists so kernels can conservatively detect overlap;
  callers must not dereference it or treat it as a data address.
- `Into` procedures accept exact-size destinations. They never resize a
  handle. Validation finishes before the first write. Non-overlapping kernels
  write directly into the caller's destination; a temporary is used when a
  source and destination share storage so even shifted overlapping views have
  deterministic results. `ApplyInto` also uses a temporary so callback
  failure leaves its destination unchanged.
- Distinct matrices and views may be used concurrently. Concurrent reads of
  shared storage are safe. Callers must synchronise concurrent writes to
  overlapping storage.

## Indexing, shapes, and storage

- Indices are zero based and use `SizeInt`.
- Dimensions and strides use native-size types. Products and byte counts are
  checked before allocation on both 32- and 64-bit targets.
- Storage is contiguous row-major for factory-created matrices. Views carry
  explicit offsets and row/column strides.
- Both dimensions may be zero. A `0 x n` shape preserves `n`; multiplication
  follows the ordinary shape rule, so `(0 x k)(k x n)` is `0 x n`.
- Checked public access raises `EDenseMatrixError` with the operation, index or
  shape, and expected condition.
- There is no implicit broadcasting. Addition and elementwise multiplication
  require equal shapes; matrix multiplication requires matching inner
  dimensions.

## Scalar and conversion policy

- `Double` is the reference path. `Single` performs the same documented
  operation set and uses `Double` accumulators for dot products and matrix
  multiplication before rounding once to `Single`.
- `TComplex` and `TSingleComplex` keep real and imaginary components at their
  declared precision. Complex-to-real conversion is not implicit.
- `ToComplex` widens `TSingleComplex`. `ToSingleComplex` is explicit and
  rejects a finite component outside the finite `Single` range.
- `Extended` is not a matrix storage promise. Its size and precision are
  platform ABI properties documented in the support matrix.
- Integer arrays remain index/label/permutation containers. The dense engine
  does not pretend that all floating-point kernels are meaningful for integer
  matrices.
- Flat-vector, nested-array, precision, real/complex, and compatibility
  conversions are explicitly named and allocate a copy. Narrowing rejects
  finite overflow, and complex-to-real conversion rejects any non-zero
  imaginary component.

## Error and compatibility policy

Stable kernels reject non-finite operands. Shape, allocation, singularity,
positive-definiteness, and finite-value errors raise `EDenseMatrixError`
without partially changing a caller destination. Reusable LU factors expose a
pivot ratio and `IsIllConditioned` diagnostic; a pivot at the
precision-relative singularity threshold is rejected.

`IMatrix`, `TMatrixKit`, `IVector`, `TMatrixArray`, `TDoubleArray`, and
`TComplexArray` remain source-compatible. `FromIMatrix`/`ToIMatrix`,
`FromArray`/`ToArray`, and `FromVector` name every unavoidable copy. No
existing API is deprecated in 1.5.0.
