# Typed dense matrices

Status: **stable since 1.5.0**. The implementation is native Object Pascal and has
no third-party runtime dependency.

Typed QR/CPQR, SVD, symmetric/Hermitian eigen, triangular, least-squares, and
minimum-norm workflows added in 1.6 are documented in
[Typed dense decompositions and solvers](DenseLinearAlgebra.md).

Version 1.8 adds `MultiplyBlockedInto` and `MultiplyAutoInto` for all four
scalar families. The serial blocked traversal preserves the portable kernel's
increasing-inner-index accumulation order; the portable path remains the
correctness oracle. See [Portable performance](PortablePerformance.md).

## 60-second solve

```pascal
uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSolvers;

var
  A, B, X: IDenseDoubleMatrix;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [4.0, 1.0, 2.0, 3.0]);
  B := TDenseDoubleMatrix.FromValues(2, 1, [9.0, 8.0]);
  X := Solve(A, B);  // LU factorisation followed by triangular solves
  WriteLn(X[0, 0]:0:6, ' ', X[1, 0]:0:6);
end.
```

The result is approximately `[1.9, 1.4]`. `Solve` supports a vector or several
right-hand-side columns and does not compute an inverse. The complete runnable
version is
[`examples/15_typed_dense_solve.pas`](../examples/15_typed_dense_solve.pas).

## Choose an entry point

| Task | Entry point | Allocation |
| --- | --- | --- |
| Construct an owned matrix | `TDense*Matrix.Zeros`, `FromValues`, `FromArray`, `FromVector` | One aligned allocation |
| Tiny 2x2 or batch | `TSmall*Matrix2.Create`; `+`, `-`, `*` | Allocation-free value record |
| Read or write an element | `A[Row, Col]` | None |
| Work on a region | `View`, `RowView`, `ColumnView`, `DiagonalView` | Small handle; storage is shared |
| Make independent storage | `Clone` | Deep copy |
| Copy into existing storage | `CopyInto` | None; temporary on overlapping views |
| Ordinary matrix product | `Multiply` / `MultiplyInto` | Result / none for non-overlapping `Into`; temporary on overlap |
| Elementwise product | `ElementWiseMultiply` / `ElementWiseMultiplyInto` | Result / none for non-overlapping `Into`; temporary on overlap |
| Linear combination | `Axpy(Alpha, X, Y)` / `AxpyInto` | Result / none for non-overlapping `Into`; temporary on overlap |
| Reduction or stable magnitude | `Sum`, `Dot`, `DotConjugate`, `Norm2` | None |
| Apply a scalar function | `Apply(A, Callback)` / `ApplyInto` | Result / alias-safe temporary |
| Solve once | `Solve(A, B)` | LU factor plus result |
| Solve repeatedly | `FactorLU(A).Solve(B)` | Factor once, result per solve |
| Symmetric/Hermitian positive-definite solve | `FactorCholesky(A).Solve(B)` | Factor once, result per solve |
| Least squares, minimum norm, or full symmetric/Hermitian eigen | See the [dense solver-selection guide](DenseLinearAlgebra.md#choose-a-dense-solver) | Reusable typed factors |
| Use the old API | `FromIMatrix`, `ToIMatrix` | Explicit deep copy |

Use LU for a general square system. Use Cholesky only when the matrix is real
symmetric or complex Hermitian positive definite; it is cheaper and preserves
that structure. Use the [1.6 selection table](DenseLinearAlgebra.md#choose-a-dense-solver)
for triangular, QR, CPQR, SVD, and symmetric/Hermitian eigen workflows.
Sparse and iterative solvers remain outside the stable typed API.

## Types and matching operation sets

| Precision | Real handle / factory | Complex handle / factory |
| --- | --- | --- |
| Single | `IDenseSingleMatrix` / `TDenseSingleMatrix` | `IDenseSingleComplexMatrix` / `TDenseSingleComplexMatrix` |
| Double | `IDenseDoubleMatrix` / `TDenseDoubleMatrix` | `IDenseComplexMatrix` / `TDenseComplexMatrix` |

All four paths provide checked storage, views, clones, add, subtract,
elementwise multiply, scale, AXPY, transpose, matrix multiply, compensated
sums/dot products, scale-safe norms, LU, and direct solve. Complex paths
additionally provide conjugation, conjugate
transpose, and a conjugating dot product. All four paths provide Cholesky;
complex Cholesky uses the Hermitian `A = L Lᴴ` convention.

`Single` kernels accumulate dot products and products in `Double` before
rounding to `Single`. This reduces avoidable summation loss but does not change
the result type or promise double-precision accuracy.

`Apply` and `ApplyInto` run a typed unary scalar callback through the shared
matrix traversal. This is the path for applying an existing elementary or
special scalar function without duplicating its formula in a matrix unit.
Inputs are validated first; callback failure is propagated and leaves an
`ApplyInto` destination unchanged.

`TSmallSingleMatrix2`, `TSmallDoubleMatrix2`,
`TSmallSingleComplexMatrix2`, and `TSmallComplexMatrix2` are fixed-size value
records for tiny expressions. Addition, subtraction, ordinary multiplication,
and scalar multiplication use natural operators without heap allocation or
general-kernel startup. Their matching `...Batch` arrays keep many such values
contiguous; batch iteration remains explicit and deterministic.

## Complete storage contract

Matrices use zero-based `SizeInt` indices and aligned contiguous row-major
owned storage. Dimensions, element counts, offsets, strides, and byte counts
are checked for native-size overflow. Empty dimensions are valid. Checked
access and all public operations raise `EDenseMatrixError` for an invalid
index, shape, finite-value condition, allocation size, or factorisation.

Views are retained-owner mutable aliases. `Clone` is a deep copy. A view stays
valid after its original handle goes out of scope. Concurrent reads are safe;
overlapping writes require caller synchronisation. See the
[design decision record](design/typed-dense-1.5.md) for the full ownership,
copy, alias, mutation, and thread-safety rules.

There is no broadcasting. `Multiply` is ordinary matrix multiplication;
`ElementWiseMultiply` is the Hadamard product; `Transpose`, `Conjugate`, and
`ConjugateTranspose` are distinct.

## API reference

`AlgebraLib.DenseMatrices` publishes:

```pascal
const DENSE_ALIGNMENT = 32;

type
  EDenseMatrixError = class(Exception);
  TSingleMatrixArray = array of array of Single;
  TComplexMatrixArray = array of array of TComplex;
  TSingleComplexMatrixArray = array of array of TSingleComplex;
  TSizeIntArray = array of SizeInt;
  TDenseShape = record Rows, Cols: SizeInt; end;
```

Each `IDense*Matrix` handle has `Rows`, `Cols`, checked `Values[Row, Col]`,
`IsContiguous`, `DataPointer`, opaque `StorageIdentity`, `Clone`, `View`,
`RowView`, `ColumnView`, and `DiagonalView`. `StorageIdentity` is only an
alias-comparison token; callers must not dereference it or infer layout from
it. Each matching `TDense*Matrix` factory has `Zeros`,
`FromValues`, `FromArray`, and `FromVector`;
`TDenseDoubleMatrix` additionally has `FromIMatrix`.

```pascal
function ToArray(Matrix): matching nested array;
function ToVector(Matrix): matching flat array;
function ToIMatrix(const Matrix: IDenseDoubleMatrix): IMatrix;
function ConvertToDouble(const Matrix: IDenseSingleMatrix): IDenseDoubleMatrix;
function ConvertToSingle(const Matrix: IDenseDoubleMatrix): IDenseSingleMatrix;
function ConvertToComplex(real matrix): matching complex matrix;
function ConvertToReal(complex matrix): matching real matrix;
function ConvertToDoubleComplex(...): IDenseComplexMatrix;
function ConvertToSingleComplex(...): IDenseSingleComplexMatrix;
```

`TSmallSingleMatrix2`, `TSmallDoubleMatrix2`,
`TSmallSingleComplexMatrix2`, and `TSmallComplexMatrix2` have `Create`,
read-only checked `Values`, and `+`, `-`, matrix `*`, and scalar `*`.
`TSmallSingleMatrix2Batch`, `TSmallDoubleMatrix2Batch`,
`TSmallSingleComplexMatrix2Batch`, and `TSmallComplexMatrix2Batch` are their
dynamic batch containers.

`AlgebraLib.DenseKernels` overloads these names across every matching scalar
path:

```pascal
CopyInto
Add / AddInto
Subtract / SubtractInto
ElementWiseMultiply / ElementWiseMultiplyInto
Scale / ScaleInto
Axpy / AxpyInto
Apply / ApplyInto
Transpose / TransposeInto
Conjugate / ConjugateInto            // complex only
ConjugateTranspose / ConjugateTransposeInto // complex only
Multiply / MultiplyInto
Sum / Dot / DotConjugate / Norm2     // conjugating dot is complex only
```

`Apply` callbacks are `TSingleUnaryKernel`, `TDoubleUnaryKernel`,
`TSingleComplexUnaryKernel`, and `TComplexUnaryKernel`. They receive one value
and return the same scalar type.

`AlgebraLib.DenseSolvers` overloads `Solve`, `SolveWithInfo`,
`SolvePositiveDefinite`, `FactorLU`, and `FactorCholesky`. Reusable factor handles are `IDenseSingleLU`,
`IDenseDoubleLU`, `IDenseSingleComplexLU`, and `IDenseComplexLU`. Cholesky
handles are `IDenseSingleCholesky`, `IDenseDoubleCholesky`,
`IDenseSingleComplexCholesky`, and `IDenseComplexCholesky`. LU exposes
`Size`, `PivotRatio`, `ConditionIndicator`,
`IsIllConditioned`, copied `L`/`U`/`Permutation`, `Solve`, and
`SolveWithInfo`; Cholesky exposes `Size`, `ConditionIndicator`, copied `L`,
`Solve`, and `SolveWithInfo`.

All creation and conversion functions allocate a result unless their name is
`View` or they return a fixed 2x2 value. Every `Into` procedure requires the
exact output shape. Validation errors include the operation and expected
shape/condition.

## Factorisation outcomes

`FactorLU` uses partial pivoting. Exact and precision-relative numerical
singularity raise `EDenseMatrixError`. A successful factor exposes:

- `L`, `U`, and `Permutation` as copies;
- `PivotRatio`, the smallest accepted pivot magnitude divided by the largest
  input magnitude;
- `IsIllConditioned`, set when that ratio is below the square root of the
  scalar precision epsilon;
- `Solve(B)` for one or many right-hand sides.

`FactorCholesky` rejects a non-Hermitian or non-positive-definite matrix.
Validation and factorisation never mutate `A` or `B`.

The concise `Solve(A, B)` raises when the reusable factor's
`IsIllConditioned` diagnostic is true, so it cannot return an unlabelled
sensitive answer. Expert callers can use `FactorLU`, inspect `PivotRatio` and
`IsIllConditioned`, and then deliberately call the factor's `Solve`.

## Complexity and numerical behavior

| Operation | Time | Additional storage |
| --- | --- | --- |
| Elementwise kernel | O(rows × cols) | result, or none for non-overlapping `Into` |
| Transpose | O(rows × cols) | result, or temporary only for overlapping `Into` |
| Matrix multiply | O(mkn) | result, or temporary only for overlapping `Into` |
| LU or Cholesky factor | O(n³) | O(n²) |
| Factor solve with `r` RHS | O(n²r) | O(nr) result |

Real and complex products use compensated component sums; the single paths use
double accumulators. Inputs must be finite. Overflow or underflow in an
individual scalar product follows the target IEEE-754 behavior; the API does
not silently rescale the mathematical problem.

## Compatibility and copy costs

Read the [1.5 migration guide](MIGRATING_TO_TYPED_DENSE.md) before moving a hot
loop. Nested arrays and `IMatrix` are copied because they are not compatible
with aligned contiguous storage. `TDoubleArray`, `TComplexArray`, and their
single equivalents are likewise copied by `FromVector`; a future view must not
be inferred from the name.

`ToVector` copies a row or column back to the matching flat array.
`ConvertToDouble`/`ConvertToSingle`,
`ConvertToDoubleComplex`/`ConvertToSingleComplex`, and the real/complex
`ConvertToComplex`/`ConvertToReal` pairs also copy. Narrowing rejects finite
overflow. Complex-to-real conversion requires an exactly zero imaginary
component, so it cannot silently discard information. NaN and infinity retain
their IEEE category during a same-kind precision conversion.
